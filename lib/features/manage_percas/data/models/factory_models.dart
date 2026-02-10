// Model untuk data Factory (untuk dropdown)
class Factory {
  final String id;
  final String factoryName;
  final String addressFactory = '';

  Factory({required this.id, required this.factoryName});

  factory Factory.fromJson(Map<String, dynamic> json) {
    return Factory(
      id: json['id'],
      factoryName: json['FactoryName'],
    );
  }
}