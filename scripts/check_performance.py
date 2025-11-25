#!/usr/bin/env python3
"""
Performance History Checker

Compares current performance test results against historical data
and helps track optimization progress.

Usage:
    python3 scripts/check_performance.py [latest_run.txt]
"""

import json
import sys
import re
from pathlib import Path
from datetime import datetime

def parse_test_output(output_text):
    """Extract performance metrics from test output"""
    metrics = {}
    
    # Parse parsing performance
    parsing_match = re.search(r'PySwiftAST Parsing.*?Median:\s+(\d+\.\d+)\s+ms', output_text, re.DOTALL)
    if parsing_match:
        metrics['parsing_median_ms'] = float(parsing_match.group(1))
    
    # Parse round-trip performance
    roundtrip_match = re.search(r'PySwiftAST Round-trip.*?Median:\s+(\d+\.\d+)\s+ms', output_text, re.DOTALL)
    if roundtrip_match:
        metrics['roundtrip_median_ms'] = float(roundtrip_match.group(1))
    
    # Parse tokenization performance
    tokenization_match = re.search(r'Tokenization.*?Median:\s+(\d+\.\d+)\s+ms', output_text, re.DOTALL)
    if tokenization_match:
        metrics['tokenization_median_ms'] = float(tokenization_match.group(1))
    
    # Parse code generation performance
    codegen_match = re.search(r'Code Generation.*?Median:\s+(\d+\.\d+)\s+ms', output_text, re.DOTALL)
    if codegen_match:
        metrics['codegen_median_ms'] = float(codegen_match.group(1))
    
    # Parse speedup vs Python
    speedup_parsing = re.search(r'Current speedup:\s+(\d+\.\d+)x.*?Python ast\.parse', output_text)
    if speedup_parsing:
        metrics['speedup_vs_python_parsing'] = float(speedup_parsing.group(1))
    
    speedup_roundtrip = re.search(r'Current speedup:\s+(\d+\.\d+)x.*?Python.*unparse', output_text)
    if speedup_roundtrip:
        metrics['speedup_vs_python_roundtrip'] = float(speedup_roundtrip.group(1))
    
    return metrics

def load_history():
    """Load performance history from JSON"""
    history_file = Path(__file__).parent.parent / "performance_history.json"
    
    if not history_file.exists():
        print(f"❌ Performance history file not found: {history_file}")
        sys.exit(1)
    
    with open(history_file) as f:
        return json.load(f)

def calculate_delta(current, previous):
    """Calculate percentage change"""
    if previous == 0:
        return 0
    return ((current - previous) / previous) * 100

def compare_performance(current_metrics, history_data):
    """Compare current metrics against baseline and history"""
    baseline = history_data['baseline']
    goals = history_data['goals']
    
    print("\n" + "=" * 70)
    print("PERFORMANCE COMPARISON")
    print("=" * 70)
    
    # Compare against baseline
    print("\n📊 Current vs Baseline:")
    print(f"   Baseline: {baseline['date']} (commit {baseline['commit'][:7]})")
    print()
    
    if 'parsing_median_ms' in current_metrics:
        baseline_parsing = baseline['parsing_median_ms']
        current_parsing = current_metrics['parsing_median_ms']
        delta = calculate_delta(current_parsing, baseline_parsing)
        
        status = "✅ IMPROVED" if delta < 0 else "⚠️ REGRESSED" if delta > 2 else "➡️ NEUTRAL"
        print(f"   Parsing:    {baseline_parsing:6.3f}ms → {current_parsing:6.3f}ms ({delta:+.1f}%) {status}")
    
    if 'roundtrip_median_ms' in current_metrics:
        baseline_roundtrip = baseline['roundtrip_median_ms']
        current_roundtrip = current_metrics['roundtrip_median_ms']
        delta = calculate_delta(current_roundtrip, baseline_roundtrip)
        
        status = "✅ IMPROVED" if delta < 0 else "⚠️ REGRESSED" if delta > 2 else "➡️ NEUTRAL"
        print(f"   Round-trip: {baseline_roundtrip:6.3f}ms → {current_roundtrip:6.3f}ms ({delta:+.1f}%) {status}")
    
    if 'tokenization_median_ms' in current_metrics:
        baseline_token = baseline['tokenization_median_ms']
        current_token = current_metrics['tokenization_median_ms']
        delta = calculate_delta(current_token, baseline_token)
        
        status = "✅ IMPROVED" if delta < 0 else "⚠️ REGRESSED" if delta > 2 else "➡️ NEUTRAL"
        print(f"   Tokenize:   {baseline_token:6.3f}ms → {current_token:6.3f}ms ({delta:+.1f}%) {status}")
    
    if 'codegen_median_ms' in current_metrics:
        baseline_codegen = baseline['codegen_median_ms']
        current_codegen = current_metrics['codegen_median_ms']
        delta = calculate_delta(current_codegen, baseline_codegen)
        
        status = "✅ IMPROVED" if delta < 0 else "⚠️ REGRESSED" if delta > 2 else "➡️ NEUTRAL"
        print(f"   Code Gen:   {baseline_codegen:6.3f}ms → {current_codegen:6.3f}ms ({delta:+.1f}%) {status}")
    
    # Progress toward goals
    print("\n🎯 Progress Toward Goals:")
    
    if 'speedup_vs_python_parsing' in current_metrics:
        current_speedup = current_metrics['speedup_vs_python_parsing']
        target_speedup = goals['parsing_speedup_target']
        progress = (current_speedup / target_speedup) * 100
        
        status = "✅" if current_speedup >= target_speedup else "🎯"
        print(f"   Parsing:    {current_speedup:.2f}x / {target_speedup:.1f}x ({progress:.0f}% of goal) {status}")
    
    if 'speedup_vs_python_roundtrip' in current_metrics:
        current_speedup = current_metrics['speedup_vs_python_roundtrip']
        target_speedup = goals['roundtrip_speedup_target']
        progress = (current_speedup / target_speedup) * 100
        
        status = "✅" if current_speedup >= target_speedup else "🎯"
        print(f"   Round-trip: {current_speedup:.2f}x / {target_speedup:.1f}x ({progress:.0f}% of goal) {status}")
    
    # Recent history
    if history_data['history']:
        print("\n📈 Recent History (last 5 optimizations):")
        for entry in history_data['history'][-5:]:
            date = entry['date'][:10]
            commit = entry['commit'][:7]
            opt = entry['optimization'][:50]
            delta_parsing = entry.get('delta_parsing_percent', 0)
            status = entry['status']
            
            status_icon = "✅" if status == "improved" else "⚠️" if status == "regressed" else "➡️"
            print(f"   {status_icon} {date} ({commit}) {delta_parsing:+.1f}% - {opt}")
    
    print("\n" + "=" * 70)
    
    # Recommendations
    print("\n💡 Recommendations:")
    
    if 'parsing_median_ms' in current_metrics:
        delta = calculate_delta(current_metrics['parsing_median_ms'], baseline['parsing_median_ms'])
        if delta > 2:
            print("   ⚠️  Parsing regressed - consider reverting recent changes")
        elif 'speedup_vs_python_parsing' in current_metrics and current_metrics['speedup_vs_python_parsing'] >= goals['parsing_speedup_target']:
            print("   ✅ Parsing goal achieved! Consider raising the target.")
        elif current_metrics['parsing_median_ms'] <= goals['parsing_target_ms']:
            print("   ✅ Parsing time goal achieved!")
        else:
            remaining = current_metrics['parsing_median_ms'] - goals['parsing_target_ms']
            print(f"   🎯 Need to reduce parsing time by {remaining:.2f}ms to hit goal")
    
    if 'roundtrip_median_ms' in current_metrics:
        delta = calculate_delta(current_metrics['roundtrip_median_ms'], baseline['roundtrip_median_ms'])
        if delta > 2:
            print("   ⚠️  Round-trip regressed - consider reverting recent changes")
        elif 'speedup_vs_python_roundtrip' in current_metrics and current_metrics['speedup_vs_python_roundtrip'] >= goals['roundtrip_speedup_target']:
            print("   ✅ Round-trip goal achieved! Consider raising the target.")
        elif current_metrics['roundtrip_median_ms'] <= goals['roundtrip_target_ms']:
            print("   ✅ Round-trip time goal achieved!")
        else:
            remaining = current_metrics['roundtrip_median_ms'] - goals['roundtrip_target_ms']
            print(f"   🎯 Need to reduce round-trip time by {remaining:.2f}ms to hit goal")
    
    print()

def main():
    if len(sys.argv) > 1:
        # Read from file
        test_output_file = Path(sys.argv[1])
        if not test_output_file.exists():
            print(f"❌ File not found: {test_output_file}")
            sys.exit(1)
        
        output_text = test_output_file.read_text()
    else:
        # Read from stdin
        print("📝 Reading test output from stdin (or provide filename as argument)...")
        print("   Run: swift test -c release --filter PerformanceTests 2>&1 | python3 scripts/check_performance.py")
        print()
        output_text = sys.stdin.read()
    
    # Parse metrics
    current_metrics = parse_test_output(output_text)
    
    if not current_metrics:
        print("❌ Could not parse performance metrics from output")
        print("   Make sure you ran: swift test -c release --filter PerformanceTests")
        sys.exit(1)
    
    # Load history
    history_data = load_history()
    
    # Compare
    compare_performance(current_metrics, history_data)

if __name__ == "__main__":
    main()
