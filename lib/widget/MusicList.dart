import '../model/MusicInfo.dart';
import '../model/PlayListInfo.dart';
import 'package:flutter/material.dart';
import '../common/utils.dart';
import '../model/down.dart';
import '../src/getSong.dart';
import 'MusicItem.dart';
import '../common/global.dart';
import '../utils/utils.dart';
class MusicList extends StatefulWidget {
  MusicList(this.myPlayListInfo);

  PlayListInfo myPlayListInfo;


  @override
  State<MusicList> createState() => _MusicList(myPlayListInfo);
}

class _MusicList extends State<MusicList> {
   PlayListInfo myPlayListInfo;


  _MusicList(this.myPlayListInfo);

  
  @override
  Widget build(BuildContext context) {
    return
        FutureBuilder<Map<String, dynamic>>(
          future: getSong().getAllSong(myPlayListInfo),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            // 请求已结束
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                // 请求失败，显示错误
                return Text("Error: ${snapshot.error}");
              } else {
                // 请求成功，显示数据
                var value = snapshot.data;
                var items =
                List<ListItem>.from(List.from(value['songs']).map((e) {
                  //此处name为filename
                    String singer = Utils.getName(List.from(e["ar"]).map((r) => r['name']).toList());

                    allMusic[e["id"].toString()]=MusicInfo(
                        album: e['al']['name'],
                        donwUrl: "donwUrl", 
                        fileType: 'fileType',
                    id: e["id"].toString(),
                  name: e['name'],
                  picUrl: e['al']['picUrl'],
                  singer: singer
                  );


                  return MessageItem("${e["name"]}", 'Artist: ${List.from(e["ar"])
                      .map((r) => r['name'])
                      .toList()}',e['id'].toString());
                }));
                WidgetUtils.showToast("共计${allMusic.length}首", Colors.blue);




                return Column(
                  children: [
                    StreamBuilder<int>(
                      stream: downloadCount.stream,
                      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                        if (snapshot.hasError) return Text('Error: ${snapshot.error}');

                        switch (snapshot.connectionState) {
                          case ConnectionState.none:
                            return Text(myPlayListInfo.name,style: const TextStyle(color: Colors.blue));
                          case ConnectionState.waiting:
                            return Text('${myPlayListInfo.name}, Count: 0/${items.length}',style: const TextStyle(color: Colors.blue));
                          case ConnectionState.active:
                            return Text(
                                '${myPlayListInfo.name}, Count: ${snapshot.data}/${items.length}   下载in~~~~ng!',style: const TextStyle(color: Colors.blue));
                          case ConnectionState.done:
                            return Text('${myPlayListInfo.name}~',style: const TextStyle(color: Colors.blue),);
                        }
                      },
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        // shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          int itemNumber = index + 1;
                          return ListTile(
                            title: item.buildTitle(context),
                            leading: Text('$itemNumber'),
                            subtitle: item.buildSubtitle(context),
                            trailing: const Icon(
                              Icons.check, color: Colors.green,),
                          );
                        },
                      ),
                    ),
            ]
                );

              }
            } else {
              // 请求未结束，显示loading
              return const CircularProgressIndicator();
            }
          },
        );


  }

}
