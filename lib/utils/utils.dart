 class Utils{
  static getName(List<dynamic> artists){
    String artist;
    if(artists.length<=3){
      artist=artists.join(' ');
    }else{
      artist=artists.sublist(0,3).join(' ');
    }
    return artist;
  }
  static String  specialStrRe(String str){
    //* /：<>？\ | +，。; = []
    var special =[
      ["<", "＜"],
      [">", "＞"],
      ["\\", "＼"],
      ["/", "／"],
      [":", "："],
      ["?", "？"],
      ["*", "＊"],
      ["\"", "＂"],
      ["|", "｜"],
      [',','，'],
      [';','；'],
      ['=','＝'],
      ["...", " "]];


    return special.fold(str, (acc, e) => acc.replaceAll(e[0],e[1]));
  }

}