// Model untuk data pabrik (untuk dropdown)
class Pabrik {
  final String id;
  final String namaPabrik;

  Pabrik({required this.id, required this.namaPabrik});

  factory Pabrik.fromJson(Map<String, dynamic> json) {
    return Pabrik(
      id: json['id'],
      namaPabrik: json['nama_pabrik'],
    );
  }
}