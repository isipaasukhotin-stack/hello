class Ship {
  final int size;
  final String name;
  int _hits = 0;

  Ship(this.size, this.name);

  void hit() {
    _hits++;
  }

  bool get isSunk => _hits >= size;

  int get hits => _hits;
}
