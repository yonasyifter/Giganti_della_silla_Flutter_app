class UserModel {
  final String uid;        // Firebase UID
  final String email;
  final String displayName;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Hiker',
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
      };
}
