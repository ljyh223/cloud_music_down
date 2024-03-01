import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:metadata_god/metadata_god.dart';
import 'package:mime/mime.dart';
import '../model/PlayListInfo.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as dev;
import '../common/metadataWrite.dart';
import '../common/utils.dart';
import '../model/MusicInfo.dart';
import '../model/down.dart';
import '../utils/Lyric.dart';


Future<void> DownloadFiles(List<downFile> files, Map<String, MusicInfo> ids,
    PlayListInfo myPlayListInfo) async {
  // MetadataGod.initialize();

  Permission permission = Permission.manageExternalStorage;
  PermissionStatus status = await permission.status;
  // var ids=allMusic;

  if (status.isGranted) {
    dev.log("ok");
  }
  else if (status.isDenied) {
    dev.log('被拒');
    WidgetUtils.showToast("请手动同意外部文件访问权限", Colors.red);
    return;
  } else if (status.isPermanentlyDenied) {
    dev.log('永拒');
    WidgetUtils.showToast("请同意外部文件访问权限", Colors.red);
    return;
  }


  var count = 0;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var saveFilepath = prefs.getString("path") ?? "/storage/emulated/0/Music/";
  var path = "$saveFilepath${myPlayListInfo.id}.json";
  var iFile = File(path);
  Dio dio = Dio();
  for (var i = 0; i < files.length; i++) {
    if (files[i].filename == "") return;
    //部分音乐无法下载
    if (files[i].url == "null") {
      continue;
    }


    File f = File(files[i].filename);

    if (await f.exists()) {
      dev.log('file exists true');
      f.delete();
    }
    //接受音频文件
    await dio.download(files[i].url, files[i].filename,);
    count += 1;
    dev.log('${files[i].filename}---${files[i].id}');


    var enLyric = prefs.getBool('lyric') ?? true;
    var enTlyric = prefs.getBool('tlyric') ?? true;
    var lyric = '';
    if (enLyric) {
      lyric = await Lyric().mergedLyric(files[i].id, enTlyric);
    }
    var data = {
      'url':files[i].url,
      'file_path': files[i].filename,
      'type': files[i].type,
      //对于空字符，kotlin那边会处理
      'lyric': lyric,
      'artist': prefs.getBool('artist') ?? true ? ids[files[i].id]!.singer : "",
      'title': prefs.getBool('title') ?? true ? ids[files[i].id]!.name : "",
      'album': prefs.getBool('album') ?? true ? ids[files[i].id]!.album : "",
      'pic_url': prefs.getBool('picture') ?? true ? ids[files[i].id]!.picUrl : "https://p2.music.126.net/rsL8HuJiFgXDmCv7U9-32Q==/109951164659404322.jpg"
    };

    var content = await iFile.readAsString();
    var jsonData = <String, dynamic>{
      'total': 0,
      'name': myPlayListInfo.name,
      'id': myPlayListInfo.id,
      "picUrl": myPlayListInfo.picUrl
    };
    var list = [];
    if (content != "") {
      jsonData = jsonDecode(content);
      list = List.from(jsonData['data']);
    }

    list.add(ids[files[i].id]);
    jsonData['data'] = list;
    jsonData['total'] += 1;
    iFile.writeAsString(jsonEncode(jsonData));
    //MetadataGod 暂时不支持歌词数据写入
    // var pic_url = prefs.getBool('picture') ?? true
    //     ? ids[files[i].id]!.picUrl
    //     : "https://p2.music.126.net/rsL8HuJiFgXDmCv7U9-32Q==/109951164659404322.jpg";
    // MetadataGod.writeMetadata(
    //     file: files[i].filename,
    //     metadata: Metadata(
    //       title: prefs.getBool('title') ?? true ? ids[files[i].id]!.name : "",
    //       artist: prefs.getBool('artist') ?? true
    //           ? ids[files[i].id]!.singer
    //           : "",
    //       album: prefs.getBool('album') ?? true ? ids[files[i].id]!.album : "",
    //       albumArtist: prefs.getBool('artist') ?? true
    //           ? ids[files[i].id]!.singer
    //           : "",
    //       picture: Picture(
    //         data: (await NetworkAssetBundle(Uri.parse(pic_url)).load(pic_url))
    //             .buffer
    //             .asUint8List(),
    //         mimeType: "image/jpg",
    //       ),
    //     )
    // );
    // dev.log("${files[i].filename}---${files[i].id} ==> OK");
    dev.log("${files[i].filename}---${files[i].id}>${(await WriteMetadata().writemetadata(data)).toString()}");
    downloadCount.sink.add(count);

  }

  WidgetUtils.showToast("下载完成,共计$count", Colors.green);
  downloadCount.close();
}