import numpy as np
from typing import List, Union

# Equivalent to Swift's Double.leastNonzeroMagnitude
LEAST_NONZERO_MAGNITUDE = np.finfo(np.float64).smallest_normal


def create_matrix(matrix_data: Union[List[List[float]], np.ndarray]) -> np.ndarray:
    """Create matrix from 2D array data (equivalent to Swift init(matrix:))."""
    matrix = np.array(matrix_data, dtype=np.float64)
    if matrix.size == 0 or matrix.shape[0] != matrix.shape[1]:
        raise ValueError("Matrix must be non-empty and square")
    return matrix


def create_matrix_with_value(size: int, value: float = 0.0) -> np.ndarray:
    """Create square matrix with default value (equivalent to Swift init(size:value:))."""
    if size <= 0:
        raise ValueError("Matrix size must be positive")
    return np.full((size, size), value, dtype=np.float64)


def empty_matrix() -> np.ndarray:
    """Create empty matrix (equivalent to Swift Matrix.empty())."""
    return create_matrix_with_value(1, 0.0)


def copy_matrix(matrix: np.ndarray) -> np.ndarray:
    """Create copy of matrix (equivalent to Swift copy())."""
    return matrix.copy()


def is_empty(matrix: np.ndarray) -> bool:
    """Check if matrix is effectively empty (equivalent to Swift isEmpty)."""
    return matrix.shape[0] == 1 and matrix[0, 0] == 0.0


def soft_max(matrix: np.ndarray) -> np.ndarray:
    """Apply softmax normalization row-wise while maintaining symmetry."""
    if is_empty(matrix):
        return matrix.copy()

    result = matrix.copy()
    size = matrix.shape[0]

    # For each row, apply softmax while maintaining symmetry
    for i in range(size):
        # Get max value in row for numerical stability
        row_max = np.max(result[i, :])

        # Compute exp values for the row
        row_exp_values = np.exp(result[i, :] - row_max)

        # Sum exp values in row
        row_sum = np.sum(row_exp_values)

        # Normalize row if sum is valid
        if row_sum > LEAST_NONZERO_MAGNITUDE:
            normalized_values = row_exp_values / row_sum
            result[i, :] = normalized_values
            # Maintain symmetry
            result[:, i] = normalized_values

    return result


def matrix_or(matrix1: np.ndarray, matrix2: np.ndarray) -> np.ndarray:
    """Element-wise addition followed by softmax (equivalent to Swift matrixOr)."""
    if matrix1.shape != matrix2.shape:
        raise ValueError("Matrix dimensions must match")

    result = matrix1 + matrix2
    return soft_max(result)


def calc_entropy(matrix: np.ndarray) -> float:
    """Calculate binary entropy for upper triangular elements."""
    if is_empty(matrix):
        return 0.0

    entropy = 0.0
    size = matrix.shape[0]

    # Only iterate over upper triangular part (including diagonal)
    for i in range(size):
        for j in range(i, size):
            p = np.clip(
                matrix[i, j], LEAST_NONZERO_MAGNITUDE, 1.0 - LEAST_NONZERO_MAGNITUDE
            )
            h = -(p * np.log2(p) + (1.0 - p) * np.log2(1.0 - p))
            entropy += h

    return entropy


def count_non_zero(matrix: np.ndarray) -> int:
    """Count non-zero elements in matrix."""
    # return np.sum(matrix > LEAST_NONZERO_MAGNITUDE)
    # that was wrong as it returns bool
    return np.count_nonzero(matrix).item()


def is_valid(matrix: np.ndarray) -> bool:
    """Check if matrix has no all-zero rows or columns."""
    if is_empty(matrix):
        return False

    size = matrix.shape[0]

    # Check if any row is all zeros
    for i in range(size):
        if not np.any(matrix[i, :] > LEAST_NONZERO_MAGNITUDE):
            return False

    # Check if any column is all zeros
    for j in range(size):
        if not np.any(matrix[:, j] > LEAST_NONZERO_MAGNITUDE):
            return False

    return True


def print_matrix(matrix: np.ndarray) -> None:
    """Print matrix with formatted output."""
    if is_empty(matrix):
        print("Empty matrix")
        return

    size = matrix.shape[0]
    for i in range(size):
        row = []
        for j in range(size):
            value = matrix[i, j]
            if value <= LEAST_NONZERO_MAGNITUDE:
                row.append("....")
            else:
                row.append(f"{value:.2f}")
        print(" ".join(row))


if __name__ == "__main__":
    # 2x2 matrix test
    m1 = create_matrix([[0.1, 0.9], [0.9, 0.1]])
    print(count_non_zero(m1))
