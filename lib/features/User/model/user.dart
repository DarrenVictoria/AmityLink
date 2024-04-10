class User {
  final String name;
  final String email;
  final int? feelingStatus;
  final String? profilePictureUrl;

  User({
    required this.name,
    required this.email,
    this.feelingStatus,
    this.profilePictureUrl,
  });

  User copyWith({
    String? name,
    String? email,
    int? feelingStatus,
    String? profilePictureUrl,
  }) {
    return User(
      name: name ?? this.name,
      email: email ?? this.email,
      feelingStatus: feelingStatus ?? this.feelingStatus,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }
}