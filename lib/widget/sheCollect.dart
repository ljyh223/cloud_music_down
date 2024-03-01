import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../common/utils.dart';
import '../model/MusicInfo.dart';
import '../utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as dev;
import 'MusicItem.dart';

class sheCollect extends StatefulWidget {
  String url;

  sheCollect({super.key, required this.url});

  @override
  State<StatefulWidget> createState() => _sheCollect(url: url);
}

class _sheCollect extends State<sheCollect> {
  String url;

  _sheCollect({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("这是ta的歌单"),
      ),
      body: Center(
        child: FutureBuilder<List<MessageItem>>(
          future: _getSheCollect(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                // 请求失败，显示错误
                return Text("Error: ${snapshot.error}");
              } else {
                //完成
                List<MessageItem> items = snapshot.data;
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var item = items[index];
                    int itemNumber = index + 1;
                    return GestureDetector(
                      onTap: () {
                        _downloadSheMusic(item.id);
                      },
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

  Future<List<String>> _getMyCollect(String saveFilepath) async {
    var list = <String>[];
    await for (FileSystemEntity fileSystemEntity
        in Directory(saveFilepath).list()) {
      var filename = fileSystemEntity.toString();
      var ext = filename.substring(filename.length - 5, filename.length - 1);
      if (ext == "json") {
        list.add(filename.split('/').last.split('.')[0]);
      }
    }
    return list;
  }

  Future<List<MessageItem>> _getSheCollect() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var saveFilepath = prefs.getString("path") ?? "/storage/emulated/0/Music/";
    dev.log(url);
    var myCollect = await _getMyCollect(saveFilepath);
    var host = url.substring(0, url.length - 4);
    var result = await http.get(Uri.parse('${host}temp'));
    var resp = jsonDecode(result.body);
    var ids = List.from(resp['data']);
    var list = <MessageItem>[];
    for (var i in ids) {
      dev.log('id ==> $i');
      list.add(await _getMessageItem(myCollect,host,i,saveFilepath));
    }
    return list;
  }
  Future<MessageItem> _getMessageItem(List<String> myCollect,String host,String i,String saveFilepath) async{

    var alreadyMusicCount = 0;
    //playlist info
    var result = await http.get(Uri.parse('$host$i.json'));
    if(result.body==""){
      dev.log("result.body ==> is null");
    }
    var jsonData = jsonDecode(result.body);
    dev.log("jsonData ==> ok");
    //local presence
    if (myCollect.contains(i)) {
      var filename = '${saveFilepath + i}.json';
      dev.log('filename ==> $filename');
      var f = File(filename);
      var fileData = f.readAsStringSync();
      //is empty
      if (fileData != "") {
        var myData = jsonDecode(fileData);
        //change already count
        alreadyMusicCount = List.from(myData['data']).toList().length;
        dev.log("alreadyMusicCount ==> ${alreadyMusicCount.toString()}");
      }

    }

    return MessageItem(
        jsonData['name'],
        "${alreadyMusicCount.toString()}/${List.from(jsonData['data']).toList().length.toString()}",
        jsonData['id']);

  }

  _downloadSheMusic(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var saveFilepath = prefs.getString("path") ?? "/storage/emulated/0/Music/";
    var host = url.substring(0, url.length - 4);
    dev.log('host == >$host');

    var result = await http.get(Uri.parse('$host$id.json'));
    var jsonData = jsonDecode(result.body);

    var dir = Directory('$saveFilepath${jsonData['name']}');
    if (!dir.existsSync()) {
      await dir.create();
    }
    var f = File('$saveFilepath$id.json');
    var alreadyId = <String>[];
    var requireId = <String>[];
    var allId =
        List.from(jsonData['data']).map((e) => e['id'].toString()).toList();
    var myJsonData = <String, dynamic>{
      'name': jsonData['name'],
      'id': jsonData['id'],
      'picUrl': jsonData['picUrl'],
      'total': 0,
      'data': []
    };
    if (f.existsSync() && f.readAsStringSync() != "") {
      dev.log("文件存在");
      myJsonData = jsonDecode(f.readAsStringSync());
      alreadyId =
          List.from(myJsonData['data']).map((e) => e['id'].toString()).toList();
      requireId =
          allId.where((element) => !alreadyId.contains(element)).toList();
    } else {
      f.createSync();
      requireId = allId;
    }

    var requireMusic = List.from(jsonData['data'])
        .where((e) => requireId.contains(e['id']))
        .toList();

    if(requireMusic.isEmpty){
      return WidgetUtils.showToast("不用下载哦", Colors.blue);
    }
    Dio dio = Dio();
    var list = List.from(myJsonData['data']);
    WidgetUtils.showToast("一开始下载,共计${requireMusic.length}首", Colors.green);
    for (var e in requireMusic) {
      var name = Utils.specialStrRe('${e['name']}.${e['file_type']}');
      var musicUrl = '${host}file?name=${_base64EncodeUrlEncode('${jsonData['name']}/$name')}';
      dev.log(musicUrl);
      await dio.download(musicUrl, '$saveFilepath${jsonData['name']}/$name');
      list.add(MusicInfo(
          album: e['album'],
          donwUrl: '',
          fileType: e['file_type'],
          id: e['id'],
          name: e['name'],
          picUrl: e['pic_url'],
          singer: e['singer']));
      myJsonData['data'] = list;
      myJsonData['total'] += 1;
      f.writeAsString(jsonEncode(myJsonData));
    }

    WidgetUtils.showToast("成功下载${list.length}首", Colors.green);
  }
  _base64EncodeUrlEncode(String s)=>Uri.encodeComponent(base64Encode(utf8.encode(s)));
}
