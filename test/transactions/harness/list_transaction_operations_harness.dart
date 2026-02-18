class TestItem {
  const TestItem({required this.id, required this.name});

  final int id;
  final String name;

  TestItem copyWith({int? id, String? name}) {
    return TestItem(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestItem && other.id == id && other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'TestItem(id: $id, name: $name)';
}
