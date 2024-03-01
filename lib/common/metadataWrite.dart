import 'package:flutter/services.dart';
class WriteMetadata{
  Future<String> writemetadata(Map<String, String> data) async {
    MethodChannel platformChannel = const MethodChannel('Kotlin');
    return await platformChannel.invokeMethod('metadataWrite', data);
  }


}