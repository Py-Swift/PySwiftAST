"""
Machine Learning Pipeline Example
Features: NumPy-style operations, scikit-learn patterns, complex class hierarchies
"""
from typing import (
    List, Dict, Tuple, Optional, Union, Any, Callable,
    TypeVar, Generic, Protocol, ClassVar
)
from dataclasses import dataclass, field
from abc import ABC, abstractmethod
from enum import Enum, auto
import math
from functools import reduce
from operator import add, mul


# Type variables
T = TypeVar('T')
Number = Union[int, float]
Array = List[List[Number]]
Vector = List[Number]


class ModelType(Enum):
    """Types of machine learning models"""
    CLASSIFIER = auto()
    REGRESSOR = auto()
    CLUSTERER = auto()
    TRANSFORMER = auto()


@dataclass
class ModelMetrics:
    """Metrics for model evaluation"""
    accuracy: Optional[float] = None
    precision: Optional[float] = None
    recall: Optional[float] = None
    f1_score: Optional[float] = None
    mse: Optional[float] = None
    rmse: Optional[float] = None
    r2_score: Optional[float] = None
    
    def __str__(self) -> str:
        metrics = []
        if self.accuracy is not None:
            metrics.append(f"Accuracy: {self.accuracy:.4f}")
        if self.precision is not None:
            metrics.append(f"Precision: {self.precision:.4f}")
        if self.recall is not None:
            metrics.append(f"Recall: {self.recall:.4f}")
        if self.f1_score is not None:
            metrics.append(f"F1: {self.f1_score:.4f}")
        if self.mse is not None:
            metrics.append(f"MSE: {self.mse:.4f}")
        return ", ".join(metrics)


class Estimator(ABC, Generic[T]):
    """Base class for all estimators (sklearn-style)"""
    
    model_type: ClassVar[ModelType]
    
    def __init__(self, random_state: Optional[int] = None):
        self.random_state = random_state
        self.is_fitted_ = False
        self.n_features_in_: Optional[int] = None
    
    @abstractmethod
    def fit(self, X: Array, y: Optional[Vector] = None) -> 'Estimator':
        """Fit the model to training data"""
        pass
    
    @abstractmethod
    def predict(self, X: Array) -> Vector:
        """Make predictions on new data"""
        pass
    
    def _check_is_fitted(self):
        """Check if model is fitted"""
        if not self.is_fitted_:
            raise RuntimeError(f"{self.__class__.__name__} is not fitted yet")
    
    def _validate_data(self, X: Array, y: Optional[Vector] = None):
        """Validate input data"""
        if not X:
            raise ValueError("X cannot be empty")
        
        n_samples = len(X)
        n_features = len(X[0]) if X else 0
        
        if self.n_features_in_ is None:
            self.n_features_in_ = n_features
        elif self.n_features_in_ != n_features:
            raise ValueError(
                f"Expected {self.n_features_in_} features, got {n_features}"
            )
        
        if y is not None and len(y) != n_samples:
            raise ValueError(
                f"X has {n_samples} samples but y has {len(y)} samples"
            )


class LinearRegression(Estimator[float]):
    """Simple linear regression model"""
    
    model_type = ModelType.REGRESSOR
    
    def __init__(
        self,
        fit_intercept: bool = True,
        normalize: bool = False,
        random_state: Optional[int] = None
    ):
        super().__init__(random_state)
        self.fit_intercept = fit_intercept
        self.normalize = normalize
        self.coef_: Optional[Vector] = None
        self.intercept_: float = 0.0
    
    def fit(self, X: Array, y: Vector) -> 'LinearRegression':
        """Fit linear regression model"""
        self._validate_data(X, y)
        
        n_samples = len(X)
        n_features = len(X[0])
        
        # Simple normal equation: β = (X^T X)^-1 X^T y
        # This is a simplified version for demonstration
        
        # Calculate means
        X_mean = [sum(col) / n_samples for col in zip(*X)]
        y_mean = sum(y) / n_samples
        
        # Center the data
        X_centered = [
            [X[i][j] - X_mean[j] for j in range(n_features)]
            for i in range(n_samples)
        ]
        y_centered = [y[i] - y_mean for i in range(n_samples)]
        
        # Calculate coefficients (simplified)
        self.coef_ = [0.0] * n_features
        for j in range(n_features):
            numerator = sum(
                X_centered[i][j] * y_centered[i]
                for i in range(n_samples)
            )
            denominator = sum(
                X_centered[i][j] ** 2
                for i in range(n_samples)
            )
            
            if denominator != 0:
                self.coef_[j] = numerator / denominator
        
        # Calculate intercept
        if self.fit_intercept:
            self.intercept_ = y_mean - sum(
                self.coef_[j] * X_mean[j]
                for j in range(n_features)
            )
        
        self.is_fitted_ = True
        return self
    
    def predict(self, X: Array) -> Vector:
        """Predict using linear regression"""
        self._check_is_fitted()
        self._validate_data(X)
        
        predictions = []
        for x in X:
            pred = sum(
                self.coef_[i] * x[i]
                for i in range(len(x))
            ) + self.intercept_
            predictions.append(pred)
        
        return predictions
    
    def score(self, X: Array, y: Vector) -> float:
        """Calculate R² score"""
        predictions = self.predict(X)
        
        # Calculate R²
        y_mean = sum(y) / len(y)
        ss_tot = sum((yi - y_mean) ** 2 for yi in y)
        ss_res = sum((y[i] - predictions[i]) ** 2 for i in range(len(y)))
        
        r2 = 1 - (ss_res / ss_tot) if ss_tot != 0 else 0.0
        return r2


class KMeans(Estimator[int]):
    """K-Means clustering algorithm"""
    
    model_type = ModelType.CLUSTERER
    
    def __init__(
        self,
        n_clusters: int = 8,
        max_iter: int = 300,
        tol: float = 1e-4,
        random_state: Optional[int] = None
    ):
        super().__init__(random_state)
        self.n_clusters = n_clusters
        self.max_iter = max_iter
        self.tol = tol
        self.cluster_centers_: Optional[Array] = None
        self.labels_: Optional[List[int]] = None
        self.inertia_: float = 0.0
    
    def fit(self, X: Array, y: Optional[Vector] = None) -> 'KMeans':
        """Fit K-Means clustering"""
        self._validate_data(X)
        
        n_samples = len(X)
        n_features = len(X[0])
        
        # Initialize centroids randomly (simplified)
        import random
        if self.random_state is not None:
            random.seed(self.random_state)
        
        indices = random.sample(range(n_samples), self.n_clusters)
        self.cluster_centers_ = [X[i][:] for i in indices]
        
        # K-Means iteration
        for iteration in range(self.max_iter):
            # Assign points to nearest centroid
            labels = []
            for x in X:
                distances = [
                    self._euclidean_distance(x, center)
                    for center in self.cluster_centers_
                ]
                labels.append(distances.index(min(distances)))
            
            # Update centroids
            new_centers = []
            for k in range(self.n_clusters):
                cluster_points = [
                    X[i] for i in range(n_samples) if labels[i] == k
                ]
                
                if cluster_points:
                    new_center = [
                        sum(point[j] for point in cluster_points) / len(cluster_points)
                        for j in range(n_features)
                    ]
                    new_centers.append(new_center)
                else:
                    new_centers.append(self.cluster_centers_[k])
            
            # Check convergence
            max_shift = max(
                self._euclidean_distance(
                    self.cluster_centers_[k],
                    new_centers[k]
                )
                for k in range(self.n_clusters)
            )
            
            self.cluster_centers_ = new_centers
            
            if max_shift < self.tol:
                break
        
        self.labels_ = labels
        self.is_fitted_ = True
        
        # Calculate inertia
        self.inertia_ = sum(
            self._euclidean_distance(X[i], self.cluster_centers_[labels[i]]) ** 2
            for i in range(n_samples)
        )
        
        return self
    
    def predict(self, X: Array) -> List[int]:
        """Predict cluster labels"""
        self._check_is_fitted()
        self._validate_data(X)
        
        labels = []
        for x in X:
            distances = [
                self._euclidean_distance(x, center)
                for center in self.cluster_centers_
            ]
            labels.append(distances.index(min(distances)))
        
        return labels
    
    @staticmethod
    def _euclidean_distance(a: Vector, b: Vector) -> float:
        """Calculate Euclidean distance between two vectors"""
        return math.sqrt(sum((a[i] - b[i]) ** 2 for i in range(len(a))))


class Pipeline:
    """ML Pipeline for chaining estimators"""
    
    def __init__(self, steps: List[Tuple[str, Estimator]]):
        self.steps = steps
        self.named_steps = dict(steps)
    
    def fit(self, X: Array, y: Optional[Vector] = None) -> 'Pipeline':
        """Fit all estimators in the pipeline"""
        X_transformed = X
        
        for name, estimator in self.steps[:-1]:
            X_transformed = estimator.fit(X_transformed, y).predict(X_transformed)
        
        # Fit final estimator
        self.steps[-1][1].fit(X_transformed, y)
        
        return self
    
    def predict(self, X: Array) -> Vector:
        """Apply transforms and predict"""
        X_transformed = X
        
        for name, estimator in self.steps[:-1]:
            X_transformed = estimator.predict(X_transformed)
        
        return self.steps[-1][1].predict(X_transformed)
    
    def __getitem__(self, name: str) -> Estimator:
        """Access estimator by name"""
        return self.named_steps[name]


class CrossValidator:
    """K-Fold cross-validation"""
    
    def __init__(self, n_splits: int = 5, shuffle: bool = True):
        self.n_splits = n_splits
        self.shuffle = shuffle
    
    def split(self, X: Array, y: Optional[Vector] = None) -> List[Tuple[List[int], List[int]]]:
        """Generate train/test splits"""
        n_samples = len(X)
        indices = list(range(n_samples))
        
        if self.shuffle:
            import random
            random.shuffle(indices)
        
        fold_size = n_samples // self.n_splits
        splits = []
        
        for i in range(self.n_splits):
            test_start = i * fold_size
            test_end = test_start + fold_size if i < self.n_splits - 1 else n_samples
            
            test_indices = indices[test_start:test_end]
            train_indices = indices[:test_start] + indices[test_end:]
            
            splits.append((train_indices, test_indices))
        
        return splits
    
    def cross_validate(
        self,
        estimator: Estimator,
        X: Array,
        y: Vector,
        scoring: Callable[[Estimator, Array, Vector], float]
    ) -> List[float]:
        """Perform cross-validation"""
        scores = []
        
        for train_idx, test_idx in self.split(X, y):
            X_train = [X[i] for i in train_idx]
            y_train = [y[i] for i in train_idx]
            X_test = [X[i] for i in test_idx]
            y_test = [y[i] for i in test_idx]
            
            estimator.fit(X_train, y_train)
            score = scoring(estimator, X_test, y_test)
            scores.append(score)
        
        return scores


# Utility functions
def train_test_split(
    X: Array,
    y: Vector,
    test_size: float = 0.2,
    random_state: Optional[int] = None
) -> Tuple[Array, Array, Vector, Vector]:
    """Split data into training and testing sets"""
    import random
    
    if random_state is not None:
        random.seed(random_state)
    
    n_samples = len(X)
    n_test = int(n_samples * test_size)
    
    indices = list(range(n_samples))
    random.shuffle(indices)
    
    test_indices = indices[:n_test]
    train_indices = indices[n_test:]
    
    X_train = [X[i] for i in train_indices]
    X_test = [X[i] for i in test_indices]
    y_train = [y[i] for i in train_indices]
    y_test = [y[i] for i in test_indices]
    
    return X_train, X_test, y_train, y_test


def mean_squared_error(y_true: Vector, y_pred: Vector) -> float:
    """Calculate mean squared error"""
    return sum((y_true[i] - y_pred[i]) ** 2 for i in range(len(y_true))) / len(y_true)


def accuracy_score(y_true: Vector, y_pred: Vector) -> float:
    """Calculate accuracy"""
    correct = sum(1 for i in range(len(y_true)) if y_true[i] == y_pred[i])
    return correct / len(y_true)


# Example usage
def main():
    """Demonstration of the ML framework"""
    
    # Generate synthetic data
    X = [[i, i ** 2] for i in range(100)]
    y = [2 * i + 3 * (i ** 2) + 5 for i in range(100)]
    
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )
    
    # Train linear regression
    model = LinearRegression(fit_intercept=True)
    model.fit(X_train, y_train)
    
    # Make predictions
    predictions = model.predict(X_test)
    
    # Evaluate
    r2 = model.score(X_test, y_test)
    mse = mean_squared_error(y_test, predictions)
    
    print(f"R² Score: {r2:.4f}")
    print(f"MSE: {mse:.4f}")
    print(f"Coefficients: {model.coef_}")
    print(f"Intercept: {model.intercept_:.4f}")
    
    # Cross-validation
    cv = CrossValidator(n_splits=5)
    scores = cv.cross_validate(
        LinearRegression(),
        X_train,
        y_train,
        scoring=lambda est, X, y: est.score(X, y)
    )
    
    print(f"Cross-validation scores: {scores}")
    print(f"Mean CV score: {sum(scores) / len(scores):.4f}")
    
    # Clustering example
    kmeans = KMeans(n_clusters=3, random_state=42)
    kmeans.fit(X)
    clusters = kmeans.predict(X_test)
    
    print(f"Cluster centers: {kmeans.cluster_centers_}")
    print(f"Inertia: {kmeans.inertia_:.2f}")


if __name__ == '__main__':
    main()
