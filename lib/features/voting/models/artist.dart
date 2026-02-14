class Artist {
  final String name;
  final String song;
  final String? guest;
  final String? coverSong;

  const Artist(
    this.name,
    this.song, {
    this.guest,
    this.coverSong,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Artist &&
        other.name == name &&
        other.song == song &&
        other.guest == guest &&
        other.coverSong == coverSong;
  }

  @override
  int get hashCode => Object.hash(name, song, guest, coverSong);
}
