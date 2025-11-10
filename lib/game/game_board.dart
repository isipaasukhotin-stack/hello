import 'dart:io';
import 'dart:math';
import '../enums/game_enums.dart';
import '../models/ship.dart';

class GameBoard {
  final int size;
  late List<List<CellState>> grid;
  late List<List<Ship?>> ships;
  final List<Ship> placedShips = [];
  final Random random = Random();

  GameBoard(this.size) {
    grid = List.generate(size, (_) => List.filled(size, CellState.empty));
    ships = List.generate(size, (_) => List.filled(size, null));
  }

  bool placeShipsAutomatically(List<int> shipSizes) {
    grid = List.generate(size, (_) => List.filled(size, CellState.empty));
    ships = List.generate(size, (_) => List.filled(size, null));
    placedShips.clear();

    for (var shipSize in shipSizes) {
      if (!placeSingleShipAutomatically(shipSize)) {
        return false;
      }
    }
    return true;
  }

  bool placeSingleShipAutomatically(int shipSize) {
    int attempts = 0;
    while (attempts < 100) {
      int x = random.nextInt(size);
      int y = random.nextInt(size);
      bool isHorizontal = random.nextBool();

      if (canPlaceShip(x, y, shipSize, isHorizontal)) {
        _placeShip(
          x,
          y,
          shipSize,
          isHorizontal,
          Ship(shipSize, '$shipSize-палубный'),
        );
        return true;
      }
      attempts++;
    }
    return false;
  }

  bool placeShip(int x, int y, int shipSize, bool isHorizontal) {
    if (!canPlaceShip(x, y, shipSize, isHorizontal)) {
      return false;
    }

    _placeShip(
      x,
      y,
      shipSize,
      isHorizontal,
      Ship(shipSize, '$shipSize-палубный'),
    );
    return true;
  }

  bool canPlaceShip(int x, int y, int shipSize, bool isHorizontal) {
    if (isHorizontal) {
      if (x + shipSize > size) return false;
    } else {
      if (y + shipSize > size) return false;
    }

    for (int i = -1; i <= shipSize; i++) {
      for (int j = -1; j <= 1; j++) {
        int checkX, checkY;
        if (isHorizontal) {
          checkX = x + i;
          checkY = y + j;
        } else {
          checkX = x + j;
          checkY = y + i;
        }

        if (checkX >= 0 && checkX < size && checkY >= 0 && checkY < size) {
          if (ships[checkY][checkX] != null) {
            return false;
          }
        }
      }
    }
    return true;
  }

  void _placeShip(int x, int y, int shipSize, bool isHorizontal, Ship ship) {
    for (int i = 0; i < shipSize; i++) {
      int shipX = isHorizontal ? x + i : x;
      int shipY = isHorizontal ? y : y + i;
      grid[shipY][shipX] = CellState.ship;
      ships[shipY][shipX] = ship;
    }
    placedShips.add(ship);
  }

  ShotResult shoot(int x, int y) {
    if (x < 0 || x >= size || y < 0 || y >= size) {
      return ShotResult.miss;
    }

    if (grid[y][x] == CellState.hit || grid[y][x] == CellState.miss) {
      return ShotResult.alreadyShot;
    }

    if (grid[y][x] == CellState.ship) {
      grid[y][x] = CellState.hit;
      ships[y][x]?.hit();
      return ShotResult.hit;
    } else {
      grid[y][x] = CellState.miss;
      return ShotResult.miss;
    }
  }

  bool isShipSunk(int x, int y) {
    var ship = ships[y][x];
    return ship?.isSunk ?? false;
  }

  int getShipSizeAt(int x, int y) {
    return ships[y][x]?.size ?? 0;
  }

  bool allShipsSunk() {
    return placedShips.every((ship) => ship.isSunk);
  }

  void display({bool showShips = false}) {
    stdout.write('  ');
    for (int i = 0; i < size; i++) {
      stdout.write('$i ');
    }
    print('');

    for (int y = 0; y < size; y++) {
      stdout.write('$y ');
      for (int x = 0; x < size; x++) {
        var cell = grid[y][x];
        switch (cell) {
          case CellState.empty:
            stdout.write(showShips ? '~ ' : '~ ');
            break;
          case CellState.ship:
            stdout.write(showShips ? 'O ' : '~ ');
            break;
          case CellState.hit:
            stdout.write('X ');
            break;
          case CellState.miss:
            stdout.write('• ');
            break;
        }
      }
      print('');
    }
    print('\nЛегенда: ~ - вода, O - корабль, X - попадание, • - промах');
  }

  // Новый метод для получения количества оставшихся клеток кораблей
  int getTotalRemainingShipCells() {
    int count = 0;
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        if (grid[y][x] == CellState.ship) {
          count++;
        }
      }
    }
    return count;
  }

  // Новый метод для получения исходного количества клеток кораблей
  int getTotalInitialShipCells() {
    int count = 0;
    for (var ship in placedShips) {
      count += ship.size;
    }
    return count;
  }
}
