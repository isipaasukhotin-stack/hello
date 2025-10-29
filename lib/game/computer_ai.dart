import 'dart:math';
import '../models/point.dart';
import '../enums/game_enums.dart';

class ComputerAI {
  final int boardSize;
  final Random random;
  final List<Point> _availableShots = [];
  final List<Point> _hitShots = [];
  final List<Point> _nextTargets = [];

  ComputerAI(this.boardSize) : random = Random() {
    for (int x = 0; x < boardSize; x++) {
      for (int y = 0; y < boardSize; y++) {
        _availableShots.add(Point(x, y));
      }
    }
    _availableShots.shuffle(random);
  }

  Point getNextShot() {
    if (_nextTargets.isNotEmpty) {
      return _nextTargets.removeLast();
    }

    return _availableShots.removeLast();
  }

  void updateLastShot(Point shot, ShotResult result) {
    if (result == ShotResult.hit) {
      _hitShots.add(shot);
      _addAdjacentTargets(shot);
    }

    _availableShots.remove(shot);
  }

  void _addAdjacentTargets(Point hit) {
    final neighbors = [
      Point(hit.x - 1, hit.y),
      Point(hit.x + 1, hit.y),
      Point(hit.x, hit.y - 1),
      Point(hit.x, hit.y + 1),
    ];

    for (var target in neighbors) {
      if (_isValidTarget(target)) {
        _nextTargets.add(target);
      }
    }

    _nextTargets.shuffle(random);
  }

  bool _isValidTarget(Point point) {
    return point.x >= 0 &&
        point.x < boardSize &&
        point.y >= 0 &&
        point.y < boardSize &&
        _availableShots.contains(point);
  }

  void resetTargeting() {
    _nextTargets.clear();
  }
}
