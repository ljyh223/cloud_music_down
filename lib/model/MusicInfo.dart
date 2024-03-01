
class MusicInfo {
    String album;
    String donwUrl;
    String fileType;
    String id;
    String name;
    String picUrl;
    String singer;

    MusicInfo({
        required this.album,
        required this.donwUrl,
        required this.fileType,
        required this.id,
        required this.name,
        required this.picUrl,
        required this.singer,
    });

    factory MusicInfo.fromJson(Map<String, dynamic> json) => MusicInfo(
        album: json["album"],
        donwUrl: json["donw_url"],
        fileType: json["file_type"],
        id: json["id"],
        name: json["name"],
        picUrl: json["pic_url"],
        singer: json["singer"],
    );

    Map<String, dynamic> toJson() => {
        "album": album,
        "donw_url": donwUrl,
        "file_type": fileType,
        "id": id,
        "name": name,
        "pic_url": picUrl,
        "singer": singer,
    };
}
