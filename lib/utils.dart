class Vec2 {
  final double x;
  final double y;

  const Vec2(this.x, this.y);

  // properties
  double get w => x;
  double get h => y;

  // factories
  factory Vec2.all(double value) => Vec2(value, value);
}
