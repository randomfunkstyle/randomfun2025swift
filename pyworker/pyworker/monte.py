from copy import deepcopy
from mcts import mcts
from functools import reduce
import operator
from matrix import calc_entropy, create_matrix_with_value, is_empty, soft_max, is_valid
import numpy as np
from dataclasses import dataclass

DOORS = 6
LABEL_COUNT = 4


@dataclass
class Outcome:
    current_room: int
    entropy: float
    matrix: np.ndarray


@dataclass
class State:
    current_room: int
    matrix: np.ndarray
    steps: list[int]
    outcomes: list[Outcome] = []

    def is_possible(self) -> bool:
        return is_valid(self.matrix)

    # MCTS implementation
    def getPlayer(self):
        return 1

    def getPossibleActions(self):
        return [i for i in range(DOORS)]

    def takeAction(self, action: int):
        pass
