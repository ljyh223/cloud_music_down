import 'dart:convert';
import 'dart:core';
import '../model/PlayListInfo.dart';
import '../encrypt/crypto.dart';
import 'dart:developer' as dev;

class getSong {
  // 获取歌单所有的id
  getPlaylist(String id, {bool ids = false}) async {
    var params = {
      "id": id,
      "n": "100000",
      "s": "8",
      'csrf_token': '2bc2e67d3d490fdd844ffa112b5ea73d'
    };

    Map<String, dynamic> resp =
        jsonDecode(await src().wePost("/api/v6/playlist/detail", params));

    // List<dynamic> ids = ;
    if (ids) {
      return List.from(resp["playlist"]["trackIds"]).map((e) {
        return e['id'].toString();
      }).toList();
    }

    return resp;
  }

  //返回歌单所有歌曲的详细信息
  Future<Map<String, dynamic>> getAllSong(PlayListInfo playListInfo,
      {int offset = 0, int limit = 0}) async {
    var resp = await getPlaylist(playListInfo.id);
    playListInfo.name = resp['playlist']['name'];
    playListInfo.picUrl = resp['playlist']['coverImgUrl'];
    var trackIds = List.from(resp["playlist"]["trackIds"])
        .map((e) => e['id'].toString())
        .toList();
    String ids;
    if (limit - offset == 0) {
      ids = trackIds.map((e) => jsonEncode({'id': e})).toList().join(',');
    } else {
      ids = trackIds
          .sublist(offset, offset + limit)
          .map((item) => jsonEncode({"id": item}))
          .toList()
          .join(",");
    }
    var data = {"c": "[$ids]"};
    dev.log(data.toString());
    return jsonDecode(
        await src().wePost_encypto("/weapi/v3/song/detail", data));
  }

  Future<Map<String, dynamic>> getSongs(List<String> trackIds) async {
    String ids = trackIds.map((e) => jsonEncode({'id': e})).toList().join(',');
    var data = {"c": "[$ids]"};
    return jsonDecode(
        await src().wePost_encypto("/weapi/v3/song/detail", data));
  }
}
