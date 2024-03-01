import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../encrypt/crypto.dart';
import '../model/PlayListInfo.dart';
import '../utils/utils.dart';
import '../widget/MusicItem.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as dev;
import '../model/Collect.dart';
import '../model/MusicInfo.dart';
import '../model/down.dart';
import '../src/download.dart';
import '../src/getSong.dart';
import 'util.dart';

class collect extends StatefulWidget {
  const collect({super.key});

  @override
  State<StatefulWidget> createState() => _collect();
}

class _collect extends State<collect> {
  List<String> myId = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("收藏"),
      ),
      body: Center(
        child: FutureBuilder(
          future: _getCollectPlayList(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                // 请求失败，显示错误
                return Text("Error: ${snapshot.error}");
              } else {
                //完成
                var items = snapshot.data;
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    int itemNumber = index + 1;
                    return GestureDetector(
                      onTap: () => _downloadMusic(index),
                      child: ListTile(
                        title: item.buildTitle(context),
                        leading: Text('$itemNumber'),
                        subtitle: item.buildSubtitle(context),
                        trailing: const Icon(
                          Icons.check,
                          color: Colors.green,
                        ),
                      ),
                    );
                  },
                );
              }
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }

  Future<List<ListItem>> _getCollectPlayList() async {
    await _getPermission();
    await _getPermission1();
    var list = <ListItem>[];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var saveFilepath = prefs.getString("path") ?? "/storage/emulated/0/Music/";
    await for (FileSystemEntity fileSystemEntity
        in Directory('/storage/emulated/0/Music').list()) {
      if (FileSystemEntity.isFileSync(fileSystemEntity.path) &&
          fileSystemEntity.path.substring(fileSystemEntity.path.length - 5,
                  fileSystemEntity.path.length - 1) ==
              "json") {
        var data = await File(fileSystemEntity.path).readAsString();
        var jsonData = jsonDecode(data);
        myId.add(jsonData['id']);
        var allMusicCount =
            (await getSong().getPlaylist(jsonData['id'], ids: true)).length;
        List<dynamic> t = jsonData['data'];
        var alreadyMusicCount = t.length;
        var playList = Collect(
            id: jsonData['id'],
            name: jsonData['name'],
            picUrl: jsonData['picUrl'],
            allMusicCount: allMusicCount,
            alreadyMusicCount: alreadyMusicCount);
        list.add(MessageItem(
            playList.name,
            "${playList.alreadyMusicCount}/${playList.allMusicCount}",
            playList.id));
      }
    }
    return list;
  }

  _downloadMusic(int i) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = myId[i];
    var cookie = prefs.getString("cookie") ?? "";

    var saveFilepath = prefs.getString("path") ?? "/storage/emulated/0/Music/";
    var jsonPath = '$saveFilepath/$id.json';

    var resp = await getSong().getPlaylist(id);
    var allMusicId = List.from(resp["playlist"]["trackIds"])
        .map((e) => e['id'].toString())
        .toList();
    dev.log('allMusicId ==> ${allMusicId.toString()}');
    var picUrl = resp['playlist']['coverImgUrl'];
    File f = File(jsonPath);
    var jsonData = jsonDecode(f.readAsStringSync());
    var alreadyMusicId =
        List.from(jsonData['data']).map((e) => e['id']).toList();
    var playListName = jsonData['name'];
    var musicSavePath = '${saveFilepath + playListName}/';
    List<String> requireMusicId = allMusicId
        .where((element) => !alreadyMusicId.contains(element))
        .toList();
    if (requireMusicId.isEmpty) {
      WidgetUtils.showToast("还不用更新哦", Colors.red);
      return;
    }

    dev.log('requireMusicId ==> ${requireMusicId.toString()}');
    var requireMusicData = await getSong().getSongs(requireMusicId);
    dev.log('requireMusicData ==> ${requireMusicData.toString()}');
    var requireMusic = <String, MusicInfo>{};
    for (var e in List.from(requireMusicData['songs'])) {
      //此处name为filename
      String singer =
          Utils.getName(List.from(e["ar"]).map((r) => r['name']).toList());
      dev.log('singer ==> $singer');
      requireMusic[e['id'].toString()] = MusicInfo(
          album: e['al']['name'],
          donwUrl: "downUrl",
          fileType: 'fileType',
          id: e["id"].toString(),
          name: e['name'],
          picUrl: e['al']['picUrl'],
          singer: singer);
    }

    dev.log('requireMusic ==> ${requireMusic.toString()}');

    var args = {
      'cookie': cookie,
      'ids': requireMusic.keys.toList(),
      'level': 'lossless',
      'url': '/api/song/enhance/player/url/v1'
    };
    var resp1 = jsonDecode(await src().ePost_encrypto(
        'https://interface.music.163.com/eapi/song/enhance/player/url/v1',
        args));

    dev.log(resp1.toString());

    List<downFile> downList = [];
    for (var e in List.from(resp1['data'])) {
      var tempFilename =
          '$musicSavePath${Utils.specialStrRe(requireMusic[e['id'].toString()]?.name ?? "")}.${e['type'].toString().toLowerCase()}';
      dev.log(tempFilename);
      downList.add(downFile(e['id'].toString(), e['url'] ?? "null",
          tempFilename, e['type'].toString().toLowerCase()));
    }
    WidgetUtils.showToast("已经开始下载,共计${requireMusicId.length}", Colors.green);
    dev.log(downList.toString());
    await DownloadFiles(
        downList,
        requireMusic,
        PlayListInfo(
            name: playListName, id: id, path: musicSavePath, picUrl: picUrl));
  }

  _getPermission() async {
    Permission permission = Permission.storage;
    PermissionStatus status = await permission.status;
    var audioPermission=Permission.audio;
    var audioStatus=audioPermission.status;
    if(await audioStatus.isGranted){
      dev.log("audio have");
    }
    else if (await audioStatus.isDenied) {

      dev.log('audio no');
      await Permission.audio.request();
      dev.log("audio request inggg");
      WidgetUtils.showToast("audio no", Colors.red);
    } else if (await audioStatus.isPermanentlyDenied) {
      dev.log('audio one no');
      WidgetUtils.showToast("audio one no", Colors.red);
    }

    if(status.isGranted){
      dev.log("storage have");
    }
    else if (status.isDenied) {
      dev.log('storage no');
      await Permission.storage.request();
      dev.log('storage request ~');
      WidgetUtils.showToast("storage no", Colors.red);
    } else if (status.isPermanentlyDenied) {
      dev.log('storage one no');
      WidgetUtils.showToast("storage one no", Colors.red);
    }
  }

  _getPermission1() async {
    Permission permission = Permission.manageExternalStorage;
    PermissionStatus status = await permission.status;

    if(status.isGranted){
      dev.log("manageExternalStorage have");
    }
    else if (status.isDenied) {
      dev.log('manageExternalStorage no');
      await Permission.manageExternalStorage.request();
      dev.log('manageExternalStorage request ~');
      WidgetUtils.showToast("manageExternalStorage no", Colors.red);
    } else if (status.isPermanentlyDenied) {
      dev.log('manageExternalStorage one no');
      WidgetUtils.showToast("manageExternalStorage one no", Colors.red);
    }
  }

}
