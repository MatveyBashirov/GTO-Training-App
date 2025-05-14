class Profile {
  final String? firstName;
  final String? lastName;

  Profile({this.firstName, this.lastName});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
    );
  }
}