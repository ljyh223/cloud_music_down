class PlayListInfo {
    String name;
    String id;
    String path;
    String picUrl;

    PlayListInfo({
        required this.name,
        required this.id,
        required this.path,
        required this.picUrl,
    });

    factory PlayListInfo.fromJson(Map<String, dynamic> json) => PlayListInfo(
        name: json["name"],
        id: json["id"],
        path: json["path"],
        picUrl: json["picUrl"],
    );

    Map<String, dynamic> toJson() => {
        "name": name,
        "id": id,
        "path": path,
        "pic_url": picUrl,
        "picUrl": picUrl,
    };

}
