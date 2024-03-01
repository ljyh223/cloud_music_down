import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../common/utils.dart';
import '../widget/qrScan.dart';
import '../widget/sheCollect.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class share extends StatefulWidget {
  const share({super.key});

  @override
  State<StatefulWidget> createState() => _share();
}

class _share extends State<share> {
  late HttpServer server;
  var c = Colors.green;
  var flag=false;
  var url = 'https://music.163.com/song?id=33367332';
  var sheUrl = '';
  var title = '来听听歌吧';
  var ids = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("分享"),
        actions: [
          IconButton(
              onPressed: () {
                _navigateGetQr(context);
              },
              icon: const Icon(Icons.qr_code_scanner_rounded))
        ],
      ),
      body: Center(
        child: Column(
          children: [
            QrImageView(
              data: url,
              version: QrVersions.auto,
              size: 200.0,
            ),
            GestureDetector(
              child: Text(
                title,
                style: TextStyle(color: c),
              ),
              onTap: () {
                Clipboard.setData(ClipboardData(text: title));
                WidgetUtils.showToast("已复制", Colors.green);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                textStyle: TextStyle(color: (flag)? Colors.red: Colors.green),
              ),
              child: const Text("开启HTTP服务"),
              onPressed: () async {

                final interfaces = await NetworkInterface.list(
                  type: InternetAddressType.IPv4,
                  includeLinkLocal: true,
                );
                ;
                var myInterface =
                    interfaces.where((element) => element.name == "wlan0").toList();
                if(myInterface.isEmpty) myInterface=interfaces.where((element) => element.name=="wlan2").toList();
                if(myInterface.isEmpty) return WidgetUtils.showToast("你丫的是不是没联网or没开热点", Colors.red);
                final ipAddress = myInterface.first.addresses.first.address;

                for(var e in interfaces){
                  dev.log(e.name);
                  dev.log(e.addresses.first.address);
                }


                setState(() {
                  url = 'http://$ipAddress:4210/temp';
                  title = url;
                });
                setState(() {
                  flag=true;
                });
                dev.log(ipAddress);

                final prefs = await SharedPreferences.getInstance();
                final saveFilepath =
                    prefs.getString("path") ?? "/storage/emulated/0/Music/";
                dev.log(saveFilepath);

                server = await HttpServer.bind(InternetAddress.anyIPv4, 4210);
                WidgetUtils.showToast("HTTP服务开启成功", Colors.green);

                // 请求处理器
                await for (final request in server) {
                  if (request.method == 'GET') {
                    dev.log(request.uri.path);
                    if (request.uri.path == '/temp') {
                      final list = await getJsonFilesInDirectory(saveFilepath);
                      request.response.statusCode = HttpStatus.ok;
                      request.response.headers.contentType = ContentType.text;
                      request.response.write(jsonEncode({'data': list}));
                      await request.response.close();
                      continue;
                    }
                    if (request.uri.path == '/file' &&
                        request.uri.queryParameters['name'] != '') {
                      final filePath =
                          '$saveFilepath${_UrlDecodeBase64Decode(request.uri.queryParameters['name']!)}';
                      if (await handleFileRequest(filePath, request)) {
                        await request.response.close();
                        continue;
                      }
                    } else {
                      final filePath = '$saveFilepath${request.uri.path}';
                      if (await handleFileRequest(filePath, request)) {
                        await request.response.close();
                        continue;
                      }
                      request.response.statusCode = HttpStatus.notFound;
                      request.response.write('File not found');
                    }
                  } else {
                    request.response.statusCode = HttpStatus.methodNotAllowed;
                    request.response.write('Method Not Allowed');
                  }

                  await request.response.close();
                }
              },
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: TextStyle(color: (flag)? Colors.green: Colors.red),
                ),
                onPressed: () {
                  server.close();
                  WidgetUtils.showToast("HTTP服务关闭成功", Colors.green);
                  setState(() {
                    url = 'https://music.163.com/song?id=33367332';
                    title = '来听听歌吧';
                    flag=false;
                  });
                },
                child: const Text('关闭HTTP服务')),

            ElevatedButton(
                onPressed: () {
                  if (sheUrl != '') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => sheCollect(url: sheUrl)),
                    );
                  } else {
                    WidgetUtils.showToast("你好像还没扫二维码?", Colors.red);
                  }
                },
                child: const Text("去看看它的歌单?"))
          ],
        ),
      ),
    );
  }

  _navigateGetQr(context) async {
    String url = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const qrScan()),
    );
    var x = url.split('/');
    if (x.first != 'http:' && x.last != 'temp') {
      WidgetUtils.showToast("不是我想要的链接", Colors.red);
      return;
    }
    setState(() {
      sheUrl = url;
      title = url;
      c = Colors.blue;
    });
  }

  Future<List<String>> getJsonFilesInDirectory(String directoryPath) async {
    final jsonFiles = <String>[];
    await for (final fileSystemEntity in Directory(directoryPath).list()) {
      final filename = fileSystemEntity.toString();
      final ext = filename.substring(filename.length - 5, filename.length - 1);
      if (ext == 'json') {
        jsonFiles.add(filename.split('/').last.split('.')[0]);
      }
    }
    return jsonFiles;
  }

  Future<bool> handleFileRequest(String filePath, HttpRequest request) async {
    final file = File(filePath);
    if (await file.exists()) {
      final contentType = _getContentTypeFromFileExtension(file.path);
      request.response.headers.contentType = contentType;
      await request.response.addStream(file.openRead());
      return true;
    }
    return false;
  }

  ContentType _getContentTypeFromFileExtension(String filePath) {
    switch (filePath.split('.').last) {
      case 'json':
        return ContentType.json;
      case 'mp3':
      case 'flac':
        return ContentType.binary;
      default:
        throw Exception('Unsupported file type');
    }
  }

  _UrlDecodeBase64Decode(String s) =>
      utf8.decode(base64Decode(Uri.decodeComponent(s)));
}
