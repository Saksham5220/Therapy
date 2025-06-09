class Playlist {
  final String title;
  final String mood;
  final String description;
  final String spotifyUrl;
  final String appleMusicUrl;

  Playlist({
    required this.title,
    required this.mood,
    required this.description,
    required this.spotifyUrl,
    required this.appleMusicUrl,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      title: json['title'] ?? '',
      mood: json['mood'] ?? '',
      description: json['description'] ?? '',
      spotifyUrl: json['spotifyUrl'] ?? '',
      appleMusicUrl: json['appleMusicUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'mood': mood,
      'description': description,
      'spotifyUrl': spotifyUrl,
      'appleMusicUrl': appleMusicUrl,
    };
  }
}
