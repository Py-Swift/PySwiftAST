"""
Complex Python code example: Data Processing Pipeline
Features: Classes, decorators, type hints, context managers, async, comprehensions
"""
from typing import List, Dict, Optional, Union, Callable, TypeVar, Generic
from dataclasses import dataclass, field
from contextlib import contextmanager
from functools import wraps, lru_cache
import asyncio
from enum import Enum, auto
from abc import ABC, abstractmethod

T = TypeVar('T')
K = TypeVar('K')
V = TypeVar('V')


class Status(Enum):
    """Processing status enumeration"""
    PENDING = auto()
    PROCESSING = auto()
    COMPLETED = auto()
    FAILED = auto()


@dataclass
class DataPoint:
    """Represents a single data point in the pipeline"""
    id: int
    value: float
    metadata: Dict[str, Union[str, int, float]] = field(default_factory=dict)
    tags: List[str] = field(default_factory=list)
    status: Status = Status.PENDING
    
    def __post_init__(self):
        if self.value < 0:
            raise ValueError(f"Value must be non-negative, got {self.value}")
    
    @property
    def is_valid(self) -> bool:
        return self.status != Status.FAILED and self.value is not None
    
    def to_dict(self) -> Dict[str, any]:
        return {
            'id': self.id,
            'value': self.value,
            'metadata': self.metadata,
            'tags': self.tags,
            'status': self.status.name
        }


class Processor(ABC, Generic[T]):
    """Abstract base class for data processors"""
    
    def __init__(self, name: str, config: Optional[Dict[str, any]] = None):
        self.name = name
        self.config = config or {}
        self._processed_count = 0
    
    @abstractmethod
    def process(self, data: T) -> T:
        """Process a single data item"""
        pass
    
    @abstractmethod
    async def process_async(self, data: T) -> T:
        """Process a single data item asynchronously"""
        pass
    
    def __repr__(self) -> str:
        return f"{self.__class__.__name__}(name={self.name}, processed={self._processed_count})"


def validate_input(func: Callable) -> Callable:
    """Decorator to validate function inputs"""
    @wraps(func)
    def wrapper(*args, **kwargs):
        if not args and not kwargs:
            raise ValueError("No input provided")
        return func(*args, **kwargs)
    return wrapper


def retry(max_attempts: int = 3, delay: float = 1.0):
    """Decorator to retry failed operations"""
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def wrapper(*args, **kwargs):
            for attempt in range(max_attempts):
                try:
                    return await func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_attempts - 1:
                        raise
                    await asyncio.sleep(delay)
            return None
        return wrapper
    return decorator


class DataProcessor(Processor[DataPoint]):
    """Concrete implementation of data processor"""
    
    def __init__(self, name: str, threshold: float = 100.0):
        super().__init__(name)
        self.threshold = threshold
        self._cache: Dict[int, DataPoint] = {}
    
    @validate_input
    def process(self, data: DataPoint) -> DataPoint:
        """Process a data point synchronously"""
        self._processed_count += 1
        
        # Complex processing logic
        if data.value > self.threshold:
            data.status = Status.COMPLETED
            data.tags.append('high_value')
        else:
            data.status = Status.PROCESSING
            data.tags.append('normal_value')
        
        # Update metadata
        data.metadata['processor'] = self.name
        data.metadata['threshold'] = self.threshold
        
        # Cache result
        self._cache[data.id] = data
        
        return data
    
    @retry(max_attempts=3, delay=0.5)
    async def process_async(self, data: DataPoint) -> DataPoint:
        """Process a data point asynchronously with retry logic"""
        await asyncio.sleep(0.1)  # Simulate async work
        return self.process(data)
    
    @lru_cache(maxsize=128)
    def compute_stats(self, data_id: int) -> Optional[Dict[str, float]]:
        """Compute statistics for cached data"""
        if data_id not in self._cache:
            return None
        
        data = self._cache[data_id]
        return {
            'mean': data.value,
            'normalized': data.value / self.threshold if self.threshold > 0 else 0,
            'score': data.value * 1.5 if 'high_value' in data.tags else data.value
        }


class Pipeline:
    """Data processing pipeline with multiple stages"""
    
    def __init__(self, name: str):
        self.name = name
        self.processors: List[Processor] = []
        self.results: Dict[int, DataPoint] = {}
    
    def add_processor(self, processor: Processor) -> 'Pipeline':
        """Add a processor to the pipeline (builder pattern)"""
        self.processors.append(processor)
        return self
    
    @contextmanager
    def batch_processing(self):
        """Context manager for batch processing"""
        print(f"Starting batch processing in pipeline: {self.name}")
        try:
            yield self
        finally:
            print(f"Completed batch processing: {len(self.results)} items processed")
    
    def process_batch(self, data_points: List[DataPoint]) -> List[DataPoint]:
        """Process a batch of data points through all processors"""
        results = []
        
        for data in data_points:
            processed = data
            for processor in self.processors:
                try:
                    processed = processor.process(processed)
                except Exception as e:
                    processed.status = Status.FAILED
                    processed.metadata['error'] = str(e)
            
            self.results[processed.id] = processed
            results.append(processed)
        
        return results
    
    async def process_batch_async(self, data_points: List[DataPoint]) -> List[DataPoint]:
        """Process a batch asynchronously"""
        tasks = [
            self._process_single_async(data)
            for data in data_points
        ]
        return await asyncio.gather(*tasks)
    
    async def _process_single_async(self, data: DataPoint) -> DataPoint:
        """Process a single data point through async processors"""
        processed = data
        for processor in self.processors:
            processed = await processor.process_async(processed)
        self.results[processed.id] = processed
        return processed
    
    def get_statistics(self) -> Dict[str, any]:
        """Get pipeline statistics"""
        completed = [d for d in self.results.values() if d.status == Status.COMPLETED]
        failed = [d for d in self.results.values() if d.status == Status.FAILED]
        
        return {
            'total': len(self.results),
            'completed': len(completed),
            'failed': len(failed),
            'success_rate': len(completed) / len(self.results) if self.results else 0,
            'avg_value': sum(d.value for d in completed) / len(completed) if completed else 0
        }


# Complex comprehensions and lambda usage
def analyze_results(pipeline: Pipeline) -> Dict[str, any]:
    """Analyze pipeline results using comprehensions"""
    
    # Nested list comprehension
    high_value_tags = [
        tag
        for data in pipeline.results.values()
        for tag in data.tags
        if 'high' in tag
    ]
    
    # Dictionary comprehension with filtering
    metadata_summary = {
        key: [d.metadata.get(key) for d in pipeline.results.values() if key in d.metadata]
        for key in {'processor', 'threshold', 'error'}
        if any(key in d.metadata for d in pipeline.results.values())
    }
    
    # Set comprehension
    unique_statuses = {d.status for d in pipeline.results.values()}
    
    # Generator expression with lambda
    sorted_values = sorted(
        pipeline.results.values(),
        key=lambda x: (x.status.value, -x.value)
    )
    
    return {
        'high_value_tags': high_value_tags,
        'metadata_summary': metadata_summary,
        'unique_statuses': [s.name for s in unique_statuses],
        'top_values': [d.value for d in sorted_values[:5]]
    }


# Pattern matching (Python 3.10+)
def handle_status(data: DataPoint) -> str:
    """Handle different statuses using match/case"""
    match data.status:
        case Status.PENDING:
            return "Waiting for processing"
        case Status.PROCESSING:
            return f"Currently processing: {data.value}"
        case Status.COMPLETED:
            return f"Completed successfully: {data.id}"
        case Status.FAILED:
            error = data.metadata.get('error', 'Unknown error')
            return f"Failed with error: {error}"
        case _:
            return "Unknown status"


# Main execution example
async def main():
    """Main execution function demonstrating the pipeline"""
    
    # Create sample data
    data_points = [
        DataPoint(id=i, value=float(i * 10), tags=['test'])
        for i in range(1, 11)
    ]
    
    # Build pipeline
    pipeline = Pipeline("data_analysis")
    pipeline.add_processor(DataProcessor("primary", threshold=50.0))
    pipeline.add_processor(DataProcessor("secondary", threshold=75.0))
    
    # Process with context manager
    with pipeline.batch_processing():
        results = await pipeline.process_batch_async(data_points)
    
    # Analyze results
    stats = pipeline.get_statistics()
    analysis = analyze_results(pipeline)
    
    # Print summary
    print(f"Pipeline: {pipeline.name}")
    print(f"Statistics: {stats}")
    print(f"Analysis: {analysis}")
    
    # Handle each result
    for data in results:
        status_message = handle_status(data)
        print(f"Data {data.id}: {status_message}")


if __name__ == "__main__":
    asyncio.run(main())
