import 'dart:io';
import 'game_board.dart';
import 'computer_ai.dart';
import '../enums/game_enums.dart';

class SeaBattleGame {
  static const int boardSize = 6;
  static const List<int> shipSizes = [3, 2, 2, 1, 1, 1];

  late GameBoard playerBoard;
  late GameBoard computerBoard;
  late ComputerAI computerAI;

  // Основная статистика
  int playerShots = 0;
  int playerHits = 0;
  int computerShots = 0;
  int computerHits = 0;

  // Новая расширенная статистика
  int playerSunkShips = 0;
  int computerSunkShips = 0;
  DateTime gameStartTime = DateTime.now();
  DateTime? gameEndTime;

  void startGame() {
    gameStartTime = DateTime.now();
    print('🎯 ЗАПУСК МОРСКОГО БОЯ!');
    print('=' * 40);

    // Инициализация досок
    playerBoard = GameBoard(boardSize);
    computerBoard = GameBoard(boardSize);
    computerAI = ComputerAI(boardSize);

    // Расстановка кораблей
    setupPlayerShips();
    computerBoard.placeShipsAutomatically(shipSizes);
    print('\n✅ Все корабли расставлены! Начинаем игру!\n');

    gameLoop();
  }

  void setupPlayerShips() {
    print('\n⚓ РАССТАНОВКА ВАШИХ КОРАБЛЕЙ');
    print('=' * 30);

    while (true) {
      print('\nВыберите способ расстановки:');
      print('1 - Автоматическая расстановка');
      print('2 - Ручная расстановка');
      stdout.write('Ваш выбор (1/2): ');

      var choice = stdin.readLineSync();
      if (choice == '1') {
        if (playerBoard.placeShipsAutomatically(shipSizes)) {
          break;
        } else {
          print(
              '❌ Не удалось автоматически расставить корабли. Попробуйте еще раз.');
        }
      } else if (choice == '2') {
        if (manualShipPlacement()) {
          break;
        }
      } else {
        print('❌ Неверный выбор! Введите 1 или 2.');
      }
    }

    print('\n✅ Ваши корабли расставлены!');
    print('Ваше поле:');
    playerBoard.display(showShips: true);
  }

  bool manualShipPlacement() {
    print('\n📋 РУЧНАЯ РАССТАНОВКА КОРАБЛЕЙ');
    print('Размер поля: $boardSize x $boardSize');
    print('Доступные корабли: ${shipSizes.join(', ')} палуб');
    print('Формат ввода: x y направление(h/v)');
    print('Пример: 0 0 h - корабль от (0,0) горизонтально вправо');
    print('Пример: 2 3 v - корабль от (2,3) вертикально вниз');

    // Создаем временную доску для расстановки
    var tempBoard = GameBoard(boardSize);

    for (var i = 0; i < shipSizes.length; i++) {
      var shipSize = shipSizes[i];
      var shipNumber = i + 1;

      while (true) {
        print('\n' + '=' * 40);
        print('Корабль $shipNumber/${shipSizes.length} ($shipSize-палубный)');
        tempBoard.display(showShips: true);

        stdout.write('Введите координаты и направление (x y h/v): ');
        var input = stdin.readLineSync()?.toLowerCase().split(' ');

        if (input == null || input.length != 3) {
          print('❌ Неверный формат! Используйте: x y h/v');
          continue;
        }

        var x = int.tryParse(input[0]);
        var y = int.tryParse(input[1]);
        var direction = input[2];

        if (x == null || y == null) {
          print('❌ Координаты должны быть числами!');
          continue;
        }

        if (direction != 'h' && direction != 'v') {
          print(
              '❌ Направление должно быть h (горизонтально) или v (вертикально)!');
          continue;
        }

        bool isHorizontal = direction == 'h';

        if (tempBoard.placeShip(x, y, shipSize, isHorizontal)) {
          print('✅ Корабль успешно размещен!');
          break;
        } else {
          print('❌ Нельзя разместить корабль здесь!');
          print(
              'Причины: выходит за границы или пересекается с другим кораблем');
        }
      }
    }

    // Копируем расстановку на основную доску
    playerBoard = tempBoard;
    return true;
  }

  void gameLoop() {
    bool playerTurn = true;

    while (true) {
      if (playerTurn) {
        playerTurnAction();
        if (checkGameOver()) break;
        playerTurn = false;
      } else {
        computerTurnAction();
        if (checkGameOver()) break;
        playerTurn = true;
      }
    }
  }

  void playerTurnAction() {
    print('\n🎯 ВАШ ХОД');
    print('=' * 20);
    print('Поле противника:');
    computerBoard.display(showShips: false);
    print('\nВаше поле:');
    playerBoard.display(showShips: true);

    while (true) {
      stdout.write('\nВведите координаты для выстрела (x y): ');
      var input = stdin.readLineSync()?.split(' ');

      if (input == null || input.length != 2) {
        print('❌ Введите два числа через пробел!');
        continue;
      }

      var x = int.tryParse(input[0]);
      var y = int.tryParse(input[1]);

      if (x == null || y == null) {
        print('❌ Координаты должны быть числами!');
        continue;
      }

      if (x < 0 || x >= boardSize || y < 0 || y >= boardSize) {
        print('❌ Координаты должны быть от 0 до ${boardSize - 1}!');
        continue;
      }

      playerShots++;
      var result = computerBoard.shoot(x, y);

      if (result == ShotResult.alreadyShot) {
        print('❌ Вы уже стреляли в эту клетку!');
        playerShots--;
        continue;
      } else if (result == ShotResult.hit) {
        playerHits++;
        print('🎯 Попадание!');
        if (computerBoard.isShipSunk(x, y)) {
          var shipSize = computerBoard.getShipSizeAt(x, y);
          print('💥 Потоплен ${shipSize}-палубный корабль!');
          playerSunkShips++;
        }
      } else {
        print('💦 Промах!');
      }
      break;
    }
  }

  void computerTurnAction() {
    print('\n🤖 ХОД КОМПЬЮТЕРА');
    print('=' * 20);

    var shot = computerAI.getNextShot();
    computerShots++;
    print('Компьютер стреляет в координаты: ${shot.x} ${shot.y}');

    var result = playerBoard.shoot(shot.x, shot.y);
    computerAI.updateLastShot(shot, result);

    if (result == ShotResult.hit) {
      computerHits++;
      print('🎯 Компьютер попал!');
      if (playerBoard.isShipSunk(shot.x, shot.y)) {
        var shipSize = playerBoard.getShipSizeAt(shot.x, shot.y);
        print('💥 Компьютер потопил ваш ${shipSize}-палубный корабль!');
        computerSunkShips++;
        computerAI.resetTargeting();
      }
    } else {
      print('💦 Компьютер промахнулся!');
    }

    print('\nВаше поле после выстрела компьютера:');
    playerBoard.display(showShips: true);

    stdout.write('\nНажмите Enter для продолжения...');
    stdin.readLineSync();
  }

  bool checkGameOver() {
    if (computerBoard.allShipsSunk()) {
      gameEndTime = DateTime.now();
      showGameResult(true);
      return true;
    } else if (playerBoard.allShipsSunk()) {
      gameEndTime = DateTime.now();
      showGameResult(false);
      return true;
    }
    return false;
  }

  void showGameResult(bool playerWon) {
    print('\n' + '=' * 50);
    print('        ИГРА ОКОНЧЕНА!');
    print('=' * 50);

    if (playerWon) {
      print('🎉 ПОЗДРАВЛЯЕМ! ВЫ ВЫИГРАЛИ! 🎉');
    } else {
      print('💻 КОМПЬЮТЕР ВЫИГРАЛ! 💻');
    }

    // Расчет дополнительной статистики
    int playerMisses = playerShots - playerHits;
    int computerMisses = computerShots - computerHits;
    int playerRemainingShips = shipSizes.length - playerSunkShips;
    int computerRemainingShips = shipSizes.length - computerSunkShips;
    int totalPlayerShipCells = playerBoard.getTotalInitialShipCells();
    int totalComputerShipCells = computerBoard.getTotalInitialShipCells();
    int playerRemainingCells = computerBoard.getTotalRemainingShipCells();
    int computerRemainingCells = playerBoard.getTotalRemainingShipCells();

    Duration gameDuration = gameEndTime!.difference(gameStartTime);
    String durationStr =
        '${gameDuration.inMinutes}м ${gameDuration.inSeconds % 60}с';

    print('\n📊 ПОДРОБНАЯ СТАТИСТИКА ИГРЫ:');
    print('─' * 40);

    // Статистика игрока
    print('\n👤 ИГРОК:');
    print('  Потоплено кораблей: $playerSunkShips/${shipSizes.length}');
    print(
        '  Осталось кораблей противника: $computerRemainingShips/${shipSizes.length}');
    print(
        '  Уничтожено клеток: ${totalComputerShipCells - playerRemainingCells}/$totalComputerShipCells');
    print(
        '  Осталось клеток противника: $playerRemainingCells/$totalComputerShipCells');
    print('  Всего выстрелов: $playerShots');
    print('  Попадания: $playerHits');
    print('  Промахи: $playerMisses');
    if (playerShots > 0) {
      double accuracy = (playerHits / playerShots) * 100;
      print('  Точность стрельбы: ${accuracy.toStringAsFixed(1)}%');
    }

    // Статистика компьютера
    print('\n🤖 КОМПЬЮТЕР:');
    print('  Потоплено кораблей: $computerSunkShips/${shipSizes.length}');
    print(
        '  Осталось ваших кораблей: $playerRemainingShips/${shipSizes.length}');
    print(
        '  Уничтожено клеток: ${totalPlayerShipCells - computerRemainingCells}/$totalPlayerShipCells');
    print(
        '  Осталось ваших клеток: $computerRemainingCells/$totalPlayerShipCells');
    print('  Всего выстрелов: $computerShots');
    print('  Попадания: $computerHits');
    print('  Промахи: $computerMisses');

    // Общая статистика
    print('\n📈 ОБЩАЯ СТАТИСТИКА:');
    print('  Время игры: $durationStr');
    print('  Всего выстрелов в игре: ${playerShots + computerShots}');
    print('  Общее количество попаданий: ${playerHits + computerHits}');

    // Сохраняем статистику в файл
    _saveGameStatisticsToFile(
      playerWon: playerWon,
      playerStats: _PlayerStats(
        sunkShips: playerSunkShips,
        remainingEnemyShips: computerRemainingShips,
        destroyedCells: totalComputerShipCells - playerRemainingCells,
        totalEnemyCells: totalComputerShipCells,
        shots: playerShots,
        hits: playerHits,
        misses: playerMisses,
      ),
      computerStats: _PlayerStats(
        sunkShips: computerSunkShips,
        remainingEnemyShips: playerRemainingShips,
        destroyedCells: totalPlayerShipCells - computerRemainingCells,
        totalEnemyCells: totalPlayerShipCells,
        shots: computerShots,
        hits: computerHits,
        misses: computerMisses,
      ),
      duration: durationStr,
    );
  }

  void _saveGameStatisticsToFile({
    required bool playerWon,
    required _PlayerStats playerStats,
    required _PlayerStats computerStats,
    required String duration,
  }) async {
    try {
      // Создаем каталог для статистики
      final Directory statsDir = Directory('game_statistics');
      if (!await statsDir.exists()) {
        await statsDir.create(recursive: true);
      }

      // Создаем файл с уникальным именем на основе времени
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final File statsFile = File('game_statistics/game_stats_$timestamp.txt');

      // Формируем содержимое файла
      final String content = '''
МОРСКОЙ БОЙ - ДЕТАЛЬНАЯ СТАТИСТИКА ИГРЫ
=======================================

Дата игры: ${DateTime.now()}
Длительность игры: $duration
Победитель: ${playerWon ? "ИГРОК" : "КОМПЬЮТЕР"}

СТАТИСТИКА ИГРОКА:
------------------
Потоплено кораблей противника: ${playerStats.sunkShips}/${shipSizes.length}
Осталось кораблей противника: ${playerStats.remainingEnemyShips}/${shipSizes.length}
Уничтожено клеток противника: ${playerStats.destroyedCells}/${playerStats.totalEnemyCells}
Осталось клеток противника: ${playerStats.totalEnemyCells - playerStats.destroyedCells}/${playerStats.totalEnemyCells}
Всего выполнено выстрелов: ${playerStats.shots}
Количество попаданий: ${playerStats.hits}
Количество промахов: ${playerStats.misses}
Точность стрельбы: ${playerStats.shots > 0 ? ((playerStats.hits / playerStats.shots) * 100).toStringAsFixed(1) : 0}%

СТАТИСТИКА КОМПЬЮТЕРА:
----------------------
Потоплено кораблей игрока: ${computerStats.sunkShips}/${shipSizes.length}
Осталось кораблей игрока: ${computerStats.remainingEnemyShips}/${shipSizes.length}
Уничтожено клеток игрока: ${computerStats.destroyedCells}/${computerStats.totalEnemyCells}
Осталось клеток игрока: ${computerStats.totalEnemyCells - computerStats.destroyedCells}/${computerStats.totalEnemyCells}
Всего выполнено выстрелов: ${computerStats.shots}
Количество попаданий: ${computerStats.hits}
Количество промахов: ${computerStats.misses}

ОБЩАЯ СТАТИСТИКА ИГРЫ:
----------------------
Общее количество выстрелов: ${playerStats.shots + computerStats.shots}
Общее количество попаданий: ${playerStats.hits + computerStats.hits}
Общее количество промахов: ${playerStats.misses + computerStats.misses}
Соотношение попаданий к промахам: ${((playerStats.hits + computerStats.hits) / (playerStats.misses + computerStats.misses)).toStringAsFixed(2)}:1

Игра завершена: ${DateTime.now()}
''';

      // Записываем статистику в файл
      await statsFile.writeAsString(content);
      print('\n💾 Статистика игры сохранена в файл: ${statsFile.path}');
    } catch (e) {
      print('\n❌ Ошибка при сохранении статистики: $e');
    }
  }
}

// Вспомогательный класс для хранения статистики
class _PlayerStats {
  final int sunkShips;
  final int remainingEnemyShips;
  final int destroyedCells;
  final int totalEnemyCells;
  final int shots;
  final int hits;
  final int misses;

  _PlayerStats({
    required this.sunkShips,
    required this.remainingEnemyShips,
    required this.destroyedCells,
    required this.totalEnemyCells,
    required this.shots,
    required this.hits,
    required this.misses,
  });
}
