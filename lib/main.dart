import 'dart:convert';

import '../utils/getPermissions.dart';
import 'package:permission_handler/permission_handler.dart';

import '../src/download.dart';
import '../utils/utils.dart';
import '../widget/share.dart';

import 'common/global.dart';
import 'model/PlayListInfo.dart';
import 'model/down.dart';
import 'widget/MusicItem.dart';
import 'widget/MusicList.dart';
import 'widget/setting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widget/InputDialog.dart';
import 'encrypt/crypto.dart';
import 'common/utils.dart';
import 'dart:developer' as dev;
import 'dart:io';
import 'widget/collect.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    getPermissions();
    return MaterialApp(
      title: 'cmdown',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'down M'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool welcome = true;
  late String id;
  PlayListInfo myPlayListInfo=PlayListInfo(id: '',path: '', name: '', picUrl: '');
  Widget _dynamicWidgets = const Text("welcome to");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: _dynamicWidgets,
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.5,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              // drawer的头部控件
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: UnconstrainedBox(
                // 解除父级的大小限制
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.transparent,
                  backgroundImage: NetworkImage(
                    'https://p2.music.126.net/rsL8HuJiFgXDmCv7U9-32Q==/109951164659404322.jpg',
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("设置"),
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const setting()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_rounded),
              title: const Text("收藏"),
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const collect()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text("分享"),
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const share()));
              },
            ),
          ],
        ),
      ),

      // 悬浮按钮
      floatingActionButton: SpeedDial(children: [
        //获取歌单
        SpeedDialChild(
            child: const Icon(Icons.play_arrow),
            backgroundColor: Colors.green,
            // get
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: getPlayList),
        //下载按钮
        SpeedDialChild(
          child: const Icon(Icons.download),
          backgroundColor: Colors.blueAccent,
          labelStyle: const TextStyle(fontSize: 18.0),
          onTap: downloadOnClick,
        ),
      ], child: const Icon(Icons.add)),
    );
  }

  getPlayList() async {
    String inputText = await showDialog(
          context: context,
          builder: (BuildContext context) =>
              const InputDialog(title: Text("give me your id"), hintText: "id"),
        ) ??
        "";
    if (inputText != "") {
      welcome = false;
      id = inputText;
      // PlayListInfo.id = inputText;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var saveFilepath = prefs.getString("path") ?? "/storage/emulated/0/Music/";
      if (saveFilepath[saveFilepath.length - 1] != "/") {
        saveFilepath = "$saveFilepath/";
        prefs.setString('path', saveFilepath);
      }

      myPlayListInfo .id=inputText;
      myPlayListInfo.path=saveFilepath;
      allMusic = {};
      creatStream();
      //参数引用，向下直到getSong 方法中
      setState(() {
        _dynamicWidgets = MusicList(myPlayListInfo);
      });


    }
  }

  downloadOnClick() async {

    final hasStorageAccess = Platform.isAndroid ? await Permission.storage.isGranted : true;
    if(!hasStorageAccess){
      //
      await Permission.storage.request();
      if(!await Permission.storage.isGranted){
        WidgetUtils.showToast("请给予权限", Colors.red);
        return;
      }
    }

    List<String> allId = allMusic.keys.toList();
    //打开文件
    File file = File("${myPlayListInfo.path}${myPlayListInfo.id}.json");
    if(!(await file.exists())){
      await file.create();
    }
    String data = await file.readAsString(encoding: utf8);
    Map<String, dynamic> jsonData={};
    List<String> alreadyId=[];
    if(data!="") {
      jsonData = jsonDecode(data);
      alreadyId =
          List.from(jsonData['data']).map((e) => e['id'].toString()).toList();
    }

    List<String> requireId =
        allId.where((element) => !alreadyId.contains(element)).toList();


    if (requireId.isEmpty) {
      WidgetUtils.showToast("无需下载更新", Colors.orange);
      return;
    }

    // return;
    if (myPlayListInfo.path == "") {
      WidgetUtils.showToast("请在设置中填写好保存路径", Colors.red);
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String cookie = prefs.getString("cookie") ?? "";
    if (cookie == "") {
      WidgetUtils.showToast("请在设置中填写好cookie", Colors.red);
      return;
    }
    WidgetUtils.showToast("下载已开始，共计${requireId.length}", Colors.blue);

    var args = {
      'cookie': cookie,
      'ids': requireId.map((e) => int.parse(e)).toList(),
      'level': 'lossless',
      'url': '/api/song/enhance/player/url/v1'
    };
    var resp = jsonDecode(await src().ePost_encrypto(
        'https://interface.music.163.com/eapi/song/enhance/player/url/v1',
        args));

    myPlayListInfo.path+="${myPlayListInfo.name}/";

    List<downFile> respJson = [];
    for (var e in List.from(resp['data'])) {
      var tempFilename =
          '${myPlayListInfo.path}${Utils.specialStrRe(allMusic[e['id'].toString()]?.name ?? "")}.${e['type'].toString().toLowerCase()}';
      dev.log(e.toString());
      //准备为下载需要的对象
      allMusic[e['id'].toString()]?.fileType=e['type'].toString().toLowerCase();
      respJson.add(downFile(e['id'].toString(), e['url'] ?? "null",
          tempFilename, e['type'].toString().toLowerCase()));
    }

    List<ListItem> downIds = [];
    allMusic.forEach((key, value) {
      downIds.add(MessageItem(value.name, 'Artist: ${value.singer}', key));
    });

    for (var element in respJson) {
      dev.log(element.toString());
    }
    await DownloadFiles(respJson,allMusic,myPlayListInfo);
  }

  getName(List<dynamic> artists) {
    String artist;
    if (artists.length <= 3) {
      artist = artists.join(' ');
    } else {
      artist = artists.sublist(0, 3).join(' ');
    }
    return artist;
  }
}
