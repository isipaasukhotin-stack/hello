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

  int playerShots = 0;
  int playerHits = 0;
  int computerShots = 0;
  int computerHits = 0;

  void startGame() {
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
      showGameResult(true);
      return true;
    } else if (playerBoard.allShipsSunk()) {
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

    print('\n📊 СТАТИСТИКА ИГРЫ:');
    print('─' * 25);
    print('Ваши выстрелы: $playerShots');
    print('Ваши попадания: $playerHits');

    if (playerShots > 0) {
      double accuracy = (playerHits / playerShots) * 100;
      print('Ваша точность: ${accuracy.toStringAsFixed(1)}%');
    }

    print('Выстрелы компьютера: $computerShots');
    print('Попадания компьютера: $computerHits');
  }
}
