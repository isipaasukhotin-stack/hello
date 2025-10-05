import 'dart:io';
import 'dart:math';

// Класс для представления игрока
class Player {
  final String symbol;
  final String name;

  Player(this.symbol, this.name);

  void makeMove(List<List<String>> board) {
    // Базовый метод - будет переопределен в подклассах
  }
}

// Класс для человеческого игрока
class HumanPlayer extends Player {
  HumanPlayer(String symbol, String name) : super(symbol, name);

  @override
  void makeMove(List<List<String>> board) {
    while (true) {
      print('$name ($symbol), введите номер строки и столбца (например: 1 2):');
      try {
        String input = stdin.readLineSync()!;
        List<String> coordinates = input.split(' ');

        if (coordinates.length != 2) {
          print('Введите два числа через пробел!');
          continue;
        }

        int row = int.parse(coordinates[0]) - 1;
        int col = int.parse(coordinates[1]) - 1;

        if (row >= 0 &&
            row < board.length &&
            col >= 0 &&
            col < board.length &&
            board[row][col] == ' ') {
          board[row][col] = symbol;
          break;
        } else {
          print('Неверные координаты или ячейка занята!');
        }
      } catch (e) {
        print('Ошибка ввода! Введите числа.');
      }
    }
  }
}

// Класс для компьютерного игрока
class RobotPlayer extends Player {
  RobotPlayer(String symbol) : super(symbol, 'Робот');

  @override
  void makeMove(List<List<String>> board) {
    print('$name ($symbol) делает ход...');

    // Простая AI логика
    // 1. Попробовать выиграть
    dynamic move = _findWinningMove(board, symbol);
    if (move != null) {
      board[move[0]][move[1]] = symbol;
      return;
    }

    // 2. Попробовать заблокировать противника
    String opponentSymbol = symbol == 'X' ? 'O' : 'X';
    move = _findWinningMove(board, opponentSymbol);
    if (move != null) {
      board[move[0]][move[1]] = symbol;
      return;
    }

    // 3. Случайный ход
    _makeRandomMove(board);
  }

  // Используем dynamic для возврата разных типов
  dynamic _findWinningMove(List<List<String>> board, String playerSymbol) {
    int size = board.length;

    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        if (board[i][j] == ' ') {
          // Проверяем, будет ли это выигрышный ход
          board[i][j] = playerSymbol;
          if (_checkWinner(board) == playerSymbol) {
            board[i][j] = ' '; // Возвращаем обратно
            return [i, j]; // Возвращаем List<int>
          }
          board[i][j] = ' ';
        }
      }
    }
    return null; // Возвращаем null
  }

  void _makeRandomMove(List<List<String>> board) {
    Random random = Random();
    List<List<int>> emptyCells = [];
    int size = board.length;

    // Находим все пустые ячейки
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        if (board[i][j] == ' ') {
          emptyCells.add([i, j]);
        }
      }
    }

    if (emptyCells.isNotEmpty) {
      List<int> randomCell = emptyCells[random.nextInt(emptyCells.length)];
      board[randomCell[0]][randomCell[1]] = symbol;
    }
  }

  String? _checkWinner(List<List<String>> board) {
    int size = board.length;

    // Проверка строк
    for (int i = 0; i < size; i++) {
      bool rowWin = true;
      for (int j = 1; j < size; j++) {
        if (board[i][j] != board[i][0] || board[i][0] == ' ') {
          rowWin = false;
          break;
        }
      }
      if (rowWin) return board[i][0];
    }

    // Проверка столбцов
    for (int i = 0; i < size; i++) {
      bool colWin = true;
      for (int j = 1; j < size; j++) {
        if (board[j][i] != board[0][i] || board[0][i] == ' ') {
          colWin = false;
          break;
        }
      }
      if (colWin) return board[0][i];
    }

    // Проверка диагоналей
    bool diag1Win = true;
    bool diag2Win = true;
    for (int i = 1; i < size; i++) {
      if (board[i][i] != board[0][0] || board[0][0] == ' ') {
        diag1Win = false;
      }
      if (board[i][size - 1 - i] != board[0][size - 1] ||
          board[0][size - 1] == ' ') {
        diag2Win = false;
      }
    }
    if (diag1Win) return board[0][0];
    if (diag2Win) return board[0][size - 1];

    return null;
  }
}

// Основной класс игры
class TicTacToeGame {
  late List<List<String>> board;
  late Player player1;
  late Player player2;
  Player? currentPlayer;
  Random random = Random();

  // Используем Object? для хранения различных объектов
  Object? gameState;

  void initializeGame() {
    print('=== КРЕСТИКИ-НОЛИКИ ===');

    // Выбор размера поля
    int size = _getBoardSize();
    board = List.generate(size, (_) => List.filled(size, ' '));

    // Выбор режима игры
    int mode = _getGameMode();

    // Создание игроков с использованием разных типов
    dynamic players = _createPlayers(mode);
    player1 = players[0];
    player2 = players[1];

    // Случайный выбор первого игрока
    currentPlayer = random.nextBool() ? player1 : player2;
    print('\nПервым ходит: ${currentPlayer!.name}');

    gameState = 'IN_PROGRESS';
  }

  int _getBoardSize() {
    while (true) {
      print('Введите размер игрового поля (3-5):');
      try {
        String input = stdin.readLineSync()!;
        Object? sizeObj = int.tryParse(input);

        if (sizeObj != null && sizeObj is int) {
          int size = sizeObj;
          if (size >= 3 && size <= 5) {
            return size;
          }
        }
        print('Введите число от 3 до 5!');
      } catch (e) {
        print('Ошибка ввода!');
      }
    }
  }

  int _getGameMode() {
    while (true) {
      print('Выберите режим игры:');
      print('1 - Игра против друга');
      print('2 - Игра против робота');

      try {
        String input = stdin.readLineSync()!;
        Object? mode = int.tryParse(input);

        if (mode != null && mode is int && (mode == 1 || mode == 2)) {
          return mode;
        }
        print('Введите 1 или 2!');
      } catch (e) {
        print('Ошибка ввода!');
      }
    }
  }

  // Возвращаем dynamic, так как можем вернуть разные комбинации игроков
  dynamic _createPlayers(int mode) {
    if (mode == 1) {
      return [HumanPlayer('X', 'Игрок 1'), HumanPlayer('O', 'Игрок 2')];
    } else {
      return [HumanPlayer('X', 'Игрок'), RobotPlayer('O')];
    }
  }

  void playGame() {
    while (gameState == 'IN_PROGRESS') {
      _printBoard();
      currentPlayer!.makeMove(board);

      String? winner = _checkWinner(board);
      if (winner != null) {
        _printBoard();
        if (winner == 'draw') {
          print('НИЧЬЯ!');
          gameState = 'DRAW';
        } else {
          print('ПОБЕДИЛ: ${currentPlayer!.name} ($winner)');
          gameState = 'WIN';
        }
        break;
      }

      // Смена игрока
      currentPlayer = (currentPlayer == player1) ? player2 : player1;
    }
  }

  String? _checkWinner(List<List<String>> board) {
    int size = board.length;

    // Проверка строк
    for (int i = 0; i < size; i++) {
      bool rowWin = true;
      for (int j = 1; j < size; j++) {
        if (board[i][j] != board[i][0] || board[i][0] == ' ') {
          rowWin = false;
          break;
        }
      }
      if (rowWin) return board[i][0];
    }

    // Проверка столбцов
    for (int i = 0; i < size; i++) {
      bool colWin = true;
      for (int j = 1; j < size; j++) {
        if (board[j][i] != board[0][i] || board[0][i] == ' ') {
          colWin = false;
          break;
        }
      }
      if (colWin) return board[0][i];
    }

    // Проверка диагоналей
    bool diag1Win = true;
    bool diag2Win = true;
    for (int i = 1; i < size; i++) {
      if (board[i][i] != board[0][0] || board[0][0] == ' ') {
        diag1Win = false;
      }
      if (board[i][size - 1 - i] != board[0][size - 1] ||
          board[0][size - 1] == ' ') {
        diag2Win = false;
      }
    }
    if (diag1Win) return board[0][0];
    if (diag2Win) return board[0][size - 1];

    // Проверка на ничью
    bool isDraw = true;
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        if (board[i][j] == ' ') {
          isDraw = false;
          break;
        }
      }
      if (!isDraw) break;
    }
    if (isDraw) return 'draw';

    return null;
  }

  void _printBoard() {
    print('');
    int size = board.length;

    // Печать заголовка столбцов
    stdout.write('   ');
    for (int i = 1; i <= size; i++) {
      stdout.write(' $i ');
    }
    print('');

    // Печать строк
    for (int i = 0; i < size; i++) {
      stdout.write('${i + 1}  ');
      for (int j = 0; j < size; j++) {
        stdout.write('${board[i][j]} ');
        if (j < size - 1) stdout.write('|');
      }
      print('');

      if (i < size - 1) {
        stdout.write('   ');
        for (int j = 0; j < size; j++) {
          stdout.write('---');
          if (j < size - 1) stdout.write('+');
        }
        print('');
      }
    }
    print('');
  }

  bool askForNewGame() {
    while (true) {
      print('Хотите сыграть еще раз? (y/n):');
      String input = stdin.readLineSync()!.toLowerCase();

      if (input == 'y' || input == 'н') {
        return true;
      } else if (input == 'n' || input == 'т') {
        return false;
      } else {
        print('Введите y (да) или n (нет)!');
      }
    }
  }
}

void main() {
  print('Добро пожаловать в игру Крестики-Нолики!');

  do {
    TicTacToeGame game = TicTacToeGame();
    game.initializeGame();
    game.playGame();
  } while (TicTacToeGame().askForNewGame());

  print('Спасибо за игру! До свидания!');
}
