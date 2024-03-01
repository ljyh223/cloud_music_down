
class Collect {
  String id;
  String name;
  String picUrl;
  int allMusicCount;
  int alreadyMusicCount;
  Collect({
    required this.id,
    required this.name,
    required this.picUrl,
    required this.allMusicCount,
    required this.alreadyMusicCount
  });

  factory Collect.fromJson(Map<String, dynamic> json) => Collect(
    id: json['id'],
    name: json["name"],
    picUrl: json["picUrl"],
    allMusicCount: json['allMusicCount'],
    alreadyMusicCount: json['alreadyMusicCount']
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "picUrl": picUrl,
    "allMusicCount": allMusicCount,
    "alreadyMusicCount": alreadyMusicCount
  };
}
