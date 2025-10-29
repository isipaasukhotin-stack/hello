class Ship {
  final int size;
  final String name;
  int hits = 0;

  Ship(this.size, this.name);

  bool get isSunk => hits >= size;

  void hit() {
    hits++;
  }
}
