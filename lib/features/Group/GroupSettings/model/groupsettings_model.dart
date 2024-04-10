class Group {
  final String id;
  String name;
  String description;
  String? profilePictureUrl;
  List<String> members;
  String adminId;

  Group({
    required this.id,
    required this.name,
    required this.description,
    this.profilePictureUrl,
    required this.members,
    required this.adminId,
  });
}