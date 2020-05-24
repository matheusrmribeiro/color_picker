import 'dart:convert';

void yourGet(){
  //Your request code [...]

  String json;// = response.body;

  Map<String, dynamic> jsonMap = jsonDecode(json);
  List<Map<String, dynamic>> items = (jsonMap["response"]["items"] as List).cast<Map<String, dynamic>>();
  List<Map<String, dynamic>> photoItems = [];

  for (var item in items) {
    List<Map<String, dynamic>> attachments = [];

    for (var attachment in item["attachments"]){
      if (attachment["type"] == "photo"){
        attachments.add(
          {
              "album_id": attachment["photo"]["album_id"],
              "date": attachment["photo"]["date"],
              "id": attachment["photo"]["id"],
              "owner_id": attachment["photo"]["owner"],
              "has_tags": attachment["photo"]["has_tags"],
              "access_key": attachment["photo"]["access_key"],
              "post_id": attachment["photo"]["post_id"],
              "sizes": attachment["photo"]["sizes"]
          }
        );
      }
    }

    photoItems.add({
      "info": {
        "from": item["from_id"],
        "date": item["date"],
        "text": item["text"]
      },
      "attachments": attachments
    });
  }

  String yourNewJson = jsonEncode(photoItems);

}