#!/usr/bin/env python3
"""
Tool for compiling iOS toolchain
================================

This tool intend to replace all the previous tools/ in shell script.
"""

import argparse
import platform
import sys
from sys import stdout
from os.path import join, dirname, realpath, exists, isdir, basename
from os import listdir, unlink, makedirs, environ, chdir, getcwd, walk
import sh
import zipfile
import tarfile
import importlib
import json
import shutil
import fnmatch
import tempfile
import time
from contextlib import suppress
from datetime import datetime
from pprint import pformat
import logging
import urllib.request
from pbxproj import XcodeProject
from pbxproj.pbxextensions.ProjectFiles import FileOptions

url_opener = urllib.request.build_opener()
url_orig_headers = url_opener.addheaders
urllib.request.install_opener(url_opener)

curdir = dirname(__file__)

initial_working_directory = getcwd()

# For more detailed logging, use something like
# format='%(asctime)s,%(msecs)d %(levelname)-8s [%(filename)s:%(funcName)s():%(lineno)d] %(message)s'
logging.basicConfig(format='[%(levelname)-8s] %(message)s',
                    datefmt='%Y-%m-%d:%H:%M:%S',
                    level=logging.DEBUG)

# Quiet the loggers we don't care about
sh_logging = logging.getLogger('sh')
sh_logging.setLevel(logging.WARNING)

logger = logging.getLogger(__name__)


def shprint(command, *args, **kwargs):
    kwargs["_iter"] = True
    kwargs["_out_bufsize"] = 1
    kwargs["_err_to_out"] = True
    logger.info("Running Shell: {} {} {}".format(str(command), args, kwargs))
    cmd = command(*args, **kwargs)
    for line in cmd:
        # strip only last CR:
        line_str = "\n".join(line.encode("ascii", "replace").decode().splitlines())
        logger.debug(line_str)


def cache_execution(f):
    def _cache_execution(self, *args, **kwargs):
        state = self.ctx.state
        key = "{}.{}".format(self.name, f.__name__)
        force = kwargs.pop("force", False)
        if args:
            for arg in args:
                key += ".{}".format(arg)
        if key in state and not force:
            logger.debug("Cached result: {} {}. Ignoring".format(f.__name__.capitalize(), self.name))
            return
        logger.info("{} {}".format(f.__name__.capitalize(), self.name))
        f(self, *args, **kwargs)
        self.update_state(key, True)
    return _cache_execution


def remove_junk(d):
    """ Remove unused build artifacts. """
    exts = (".so.lib", ".so.o", ".sh")
    for root, dirnames, filenames in walk(d):
        for fn in filenames:
            if fn.endswith(exts):
                print('Found junk {}/{}, removing'.format(root, fn))
                unlink(join(root, fn))


class JsonStore:
    """Replacement of shelve using json, needed for support python 2 and 3.
    """

    def __init__(self, filename):
        self.filename = filename
        self.data = {}
        if exists(filename):
            try:
                with open(filename, encoding='utf-8') as fd:
                    self.data = json.load(fd)
            except ValueError:
                logger.warning("Unable to read the state.db, content will be replaced.")

    def __getitem__(self, key):
        return self.data[key]

    def __setitem__(self, key, value):
        self.data[key] = value
        self.sync()

    def __delitem__(self, key):
        del self.data[key]
        self.sync()

    def __contains__(self, item):
        return item in self.data

    def get(self, item, default=None):
        return self.data.get(item, default)

    def keys(self):
        return self.data.keys()

    def remove_all(self, prefix):
        for key in tuple(self.data.keys()):
            if not key.startswith(prefix):
                continue
            del self.data[key]
        self.sync()

    def sync(self):
        with open(self.filename, 'w') as fd:
            json.dump(self.data, fd, ensure_ascii=False)


class GenericPlatform:
    sdk = "unspecified"
    arch = "unspecified"
    version_min = "unspecified"

    def __init__(self, ctx):
        self.ctx = ctx
        self._ccsh = None

    @property
    def name(self):
        return f"{self.sdk}-{self.arch}"

    def __str__(self):
        return self.name

    @property
    def sysroot(self):
        return sh.xcrun("--sdk", self.sdk, "--show-sdk-path").strip()

    @property
    def include_dirs(self):
        return [
            "{}/{}".format(
                self.ctx.include_dir,
                d.format(plat=self))
            for d in self.ctx.include_dirs]

    @property
    def lib_dirs(self):
        return [join(self.ctx.dist_dir, "lib", self.sdk)]

    def get_env(self):
        include_dirs = [
            "-I{}/{}".format(
                self.ctx.include_dir,
                d.format(plat=self))
            for d in self.ctx.include_dirs]
        include_dirs += ["-I{}".format(
            join(self.ctx.dist_dir, "include", self.name))]

        # Add Python include directories
        include_dirs += [
            "-I{}".format(
                join(
                    self.ctx.dist_dir,
                    "root",
                    "python3",
                    "include",
                    f"python{self.ctx.hostpython_ver}",
                )
            )
        ]

        env = {}
        cc = sh.xcrun("-find", "-sdk", self.sdk, "clang").strip()
        cxx = sh.xcrun("-find", "-sdk", self.sdk, "clang++").strip()

        # we put the flags in CC / CXX as sometimes the ./configure test
        # with the preprocessor (aka CC -E) without CFLAGS, which fails for
        # cross compiled projects
        flags = " ".join([
            "--sysroot", self.sysroot,
            "-arch", self.arch,
            "-pipe", "-no-cpp-precomp",
        ])
        cc += " " + flags
        cxx += " " + flags

        use_ccache = environ.get("USE_CCACHE", "1")
        ccache = None
        if use_ccache == "1":
            ccache = shutil.which('ccache')
            if ccache:
                ccache = ccache.strip()
                env["USE_CCACHE"] = "1"
                env["CCACHE"] = ccache
                env.update({k: v for k, v in environ.items() if k.startswith('CCACHE_')})
                env.setdefault('CCACHE_MAXSIZE', '10G')
                env.setdefault('CCACHE_HARDLINK', 'true')
                env.setdefault(
                    'CCACHE_SLOPPINESS',
                    ('file_macro,time_macros,'
                     'include_file_mtime,include_file_ctime,file_stat_matches'))

        if not self._ccsh:
            def noicctempfile():
                '''
                reported issue where C Python has issues with 'icc' in the compiler path
                https://github.com/python/cpython/issues/96398
                https://github.com/python/cpython/pull/96399
                '''
                while 'icc' in (x := tempfile.NamedTemporaryFile()).name:
                    pass
                return x

            self._ccsh = noicctempfile()
            self._cxxsh = noicctempfile()
            sh.chmod("+x", self._ccsh.name)
            sh.chmod("+x", self._cxxsh.name)
            self._ccsh.write(b'#!/bin/sh\n')
            self._cxxsh.write(b'#!/bin/sh\n')
            if ccache:
                logger.info("CC and CXX will use ccache")
                self._ccsh.write(
                    (ccache + ' ' + cc + ' "$@"\n').encode("utf8"))
                self._cxxsh.write(
                    (ccache + ' ' + cxx + ' "$@"\n').encode("utf8"))
            else:
                logger.info("CC and CXX will not use ccache")
                self._ccsh.write(
                    (cc + ' "$@"\n').encode("utf8"))
                self._cxxsh.write(
                    (cxx + ' "$@"\n').encode("utf8"))
            self._ccsh.flush()
            self._cxxsh.flush()

        env["CC"] = self._ccsh.name
        env["CXX"] = self._cxxsh.name
        env["AR"] = sh.xcrun("-find", "-sdk", self.sdk, "ar").strip()
        env["LD"] = sh.xcrun("-find", "-sdk", self.sdk, "ld").strip()
        env["OTHER_CFLAGS"] = " ".join(include_dirs)
        env["OTHER_LDFLAGS"] = " ".join([f"-L{d}" for d in self.lib_dirs])
        env["CFLAGS"] = " ".join([
            "-O3",
            self.version_min,
        ] + include_dirs)
        env["CXXFLAGS"] = env["CFLAGS"]
        env["LDFLAGS"] = " ".join([
            "-arch", self.arch,
            # "--sysroot", self.sysroot,
            *[f"-L{d}" for d in self.lib_dirs],
            "-L{}/usr/lib".format(self.sysroot),
            self.version_min
        ])
        return env


class iPhoneSimulatorPlatform(GenericPlatform):
    sdk = "iphonesimulator"
    version_min = "-miphonesimulator-version-min=9.0"


class iPhoneOSPlatform(GenericPlatform):
    sdk = "iphoneos"
    version_min = "-miphoneos-version-min=9.0"


class macOSPlatform(GenericPlatform):
    sdk = "macosx"
    version_min = "-mmacosx-version-min=10.9"


class iPhoneSimulatorARM64Platform(iPhoneSimulatorPlatform):
    arch = "arm64"
    triple = "aarch64-apple-darwin13"


class iPhoneSimulatorx86_64Platform(iPhoneSimulatorPlatform):
    arch = "x86_64"
    triple = "x86_64-apple-darwin13"


class iPhoneOSARM64Platform(iPhoneOSPlatform):
    arch = "arm64"
    triple = "aarch64-apple-darwin13"


class macOSx86_64Platform(macOSPlatform):
    arch = "x86_64"
    triple = "x86_64-apple-darwin13"


class macOSARM64Platform(macOSPlatform):
    arch = "arm64"
    triple = "aarch64-apple-darwin13"


class Graph:
    # Taken from python-for-android/depsort
    def __init__(self):
        # `graph`: dict that maps each package to a set of its dependencies.
        self.graph = {}

    def add(self, dependent, dependency):
        """Add a dependency relationship to the graph"""
        self.graph.setdefault(dependent, set())
        self.graph.setdefault(dependency, set())
        if dependent != dependency:
            self.graph[dependent].add(dependency)

    def add_optional(self, dependent, dependency):
        """Add an optional (ordering only) dependency relationship to the graph

        Only call this after all mandatory requirements are added
        """
        if dependent in self.graph and dependency in self.graph:
            self.add(dependent, dependency)

    def find_order(self):
        """Do a topological sort on a dependency graph

        :Parameters:
            :Returns:
                iterator, sorted items form first to last
        """
        graph = dict((k, set(v)) for k, v in self.graph.items())
        while graph:
            # Find all items without a parent
            leftmost = [name for name, dep in graph.items() if not dep]
            if not leftmost:
                raise ValueError('Dependency cycle detected! %s' % graph)
            # If there is more than one, sort them for predictable order
            leftmost.sort()
            for result in leftmost:
                # Yield and remove them from the graph
                yield result
                graph.pop(result)
                for bset in graph.values():
                    bset.discard(result)


class Context:
    env = environ.copy()
    root_dir = None
    cache_dir = None
    build_dir = None
    dist_dir = None
    install_dir = None
    ccache = None
    cython = None
    sdkver = None
    sdksimver = None
    so_suffix = None  # set by one of the hostpython

    def __init__(self):
        self.include_dirs = []

        ok = True

        sdks = sh.xcodebuild("-showsdks").splitlines()

        # get the latest iphoneos
        iphoneos = [x for x in sdks if "iphoneos" in x]
        if not iphoneos:
            logger.error("No iphone SDK installed")
            ok = False
        else:
            iphoneos = iphoneos[0].split()[-1].replace("iphoneos", "")
            self.sdkver = iphoneos

        # get the latest iphonesimulator version
        iphonesim = [x for x in sdks if "iphonesimulator" in x]
        if not iphonesim:
            ok = False
            logger.error("Error: No iphonesimulator SDK installed")
        else:
            iphonesim = iphonesim[0].split()[-1].replace("iphonesimulator", "")
            self.sdksimver = iphonesim

        # get the path for Developer
        self.devroot = "{}/Platforms/iPhoneOS.platform/Developer".format(
            sh.xcode_select("-print-path").strip())

        # path to the iOS SDK
        self.iossdkroot = "{}/SDKs/iPhoneOS{}.sdk".format(
            self.devroot, self.sdkver)

        # root of the toolchain
        self.root_dir = realpath(dirname(__file__))
        self.build_dir = "{}/build".format(initial_working_directory)
        self.cache_dir = "{}/.cache".format(initial_working_directory)
        self.dist_dir = "{}/dist".format(initial_working_directory)
        self.install_dir = "{}/dist/root".format(initial_working_directory)
        self.include_dir = "{}/dist/include".format(initial_working_directory)

        # Supported platforms may differ from default ones,
        # and the user may select to build only a subset of them via
        # --platforms command line argument.
        self.supported_platforms = [
            iPhoneOSARM64Platform(self),
            iPhoneSimulatorARM64Platform(self),
            iPhoneSimulatorx86_64Platform(self),
        ]
        # By default build the following platforms:
        # - iPhoneOSARM64Platform* (arm64)
        # - iPhoneOSSimulator*Platform (arm64 or x86_64), depending on the host
        self.default_platforms = [iPhoneOSARM64Platform(self)]
        if platform.machine() == "x86_64":
            # Intel Mac, build for iPhoneOSSimulatorx86_64Platform
            self.default_platforms.append(iPhoneSimulatorx86_64Platform(self))
        elif platform.machine() == "arm64":
            # Apple Silicon Mac, build for iPhoneOSSimulatorARM64Platform
            self.default_platforms.append(iPhoneSimulatorARM64Platform(self))

        # If the user didn't specify a platform, use the default ones.
        self.selected_platforms = self.default_platforms

        # path to some tools
        self.ccache = shutil.which("ccache")
        for cython_fn in ("cython-2.7", "cython"):
            cython = shutil.which(cython_fn)
            if cython:
                self.cython = cython
                break
        if not self.cython:
            ok = False
            logger.error("Missing requirement: cython is not installed")

        # check the basic tools
        for tool in ("pkg-config", "autoconf", "automake", "libtool"):
            if not shutil.which(tool):
                logger.error("Missing requirement: {} is not installed".format(
                    tool))

        if not ok:
            sys.exit(1)

        self.use_pigz = shutil.which('pigz')
        self.use_pbzip2 = shutil.which('pbzip2')

        try:
            num_cores = int(sh.sysctl('-n', 'hw.ncpu'))
        except Exception:
            num_cores = None
        self.num_cores = num_cores if num_cores else 4  # default to 4 if we can't detect

        self.custom_recipes_paths = []
        ensure_dir(self.root_dir)
        ensure_dir(self.build_dir)
        ensure_dir(self.cache_dir)
        ensure_dir(self.dist_dir)
        ensure_dir(join(self.dist_dir, "frameworks"))
        ensure_dir(self.install_dir)
        ensure_dir(self.include_dir)
        ensure_dir(join(self.include_dir, "common"))

        # remove the most obvious flags that can break the compilation
        self.env.pop("MACOSX_DEPLOYMENT_TARGET", None)
        self.env.pop("PYTHONDONTWRITEBYTECODE", None)
        self.env.pop("ARCHFLAGS", None)
        self.env.pop("CFLAGS", None)
        self.env.pop("LDFLAGS", None)

        # set the state
        self.state = JsonStore(join(self.dist_dir, "state.db"))

    @property
    def concurrent_make(self):
        return "-j{}".format(self.num_cores)

    @property
    def concurrent_xcodebuild(self):
        return "IDEBuildOperationMaxNumberOfConcurrentCompileTasks={}".format(self.num_cores)


if __name__ == "__main__":
    main()
