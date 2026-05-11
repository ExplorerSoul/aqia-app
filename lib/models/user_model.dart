class UserModel {
  final String uid;
  final String email;
  final String? name;
  final String? institution;
  final String? profileImageUrl;
  final DateTime createdAt;
  
  UserModel({
    required this.uid,
    required this.email,
    this.name,
    this.institution,
    this.profileImageUrl,
    required this.createdAt,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'institution': institution,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'],
      institution: map['institution'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

