class SignatureModel {
  final String id;
  final String name;
  final String imagePath;
  final DateTime createdAt;

  const SignatureModel({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imagePath': imagePath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SignatureModel.fromJson(Map<String, dynamic> json) => SignatureModel(
        id: json['id'] as String,
        name: json['name'] as String,
        imagePath: json['imagePath'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
