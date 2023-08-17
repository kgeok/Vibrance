// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:vibrance/main.dart';
import 'package:vibrance/data_management.dart';

//For making decisions, lets use a quick buffer to store the data, this will be cleared when a decsion has been made
var buffer = [];

Future makeDecisions(BuildContext context) async {
  final db = await VibranceDatabase.instance.database;

  var counterBuffer = await db.query("Content", columns: ["MAX(id)"]);
  var counter = int.tryParse(counterBuffer[0]['MAX(id)'].toString());
  counter ??= 0;
  print("Making decisions to display content...");
  for (var i = 0; i <= counter - 1; i++) {
    var typeBuffer = await db.query("Content", columns: ["type"]);
    var type = typeBuffer[i]["type"].toString();

    var subtypeBuffer = await db.query("Content", columns: ["subtype"]);
    var subtype = subtypeBuffer[i]["subtype"].toString();

    var argoneBuffer = await db.query("Content", columns: ["text"]);
    var argone = argoneBuffer[i]["text"].toString();

    var argtwoBuffer = await db.query("Content", columns: ["raw"]);
    var argtwo = argtwoBuffer[i]["raw"];

    var weightBuffer = await db.query("Content", columns: ["weight"]);
    var weight = weightBuffer[i]["weight"];

    //We use a new buffer since it's not hooked to anything

    buffer.add(ContentData(
        contentid: i,
        contenttype: type,
        contentsubtype: subtype,
        contentargone: argone,
        contentargtwo: argtwo,
        contentweight: weight));
  }
  //print(buffer.length);

  if (buffer.isEmpty) {
    print("We have nothing to work with...");
    results.add(ContentData(
        contentid: 1,
        contenttype: "default",
        contentsubtype: "default",
        contentargone: "No Content",
        contentargtwo: "Go to Settings to add content."));
    content.add(0);
  } else {
    if (buffer.every((element) => element.contentweight == 3)) {
      print("Everything is weight of 3, using first couple of elements...");

      if (buffer.length < 6) {
        print(
            "We don't have enough content to populate a full list...using whatever we have...");
        for (int i = 0; i <= buffer.length - 1; i++) {
          switch (buffer[i].contenttype) {
            case "podcast":
              if (buffer[i].contentsubtype == "rss") {
                probeLatestPodcastRSS(buffer[i].contentargone);
              } else if (buffer[i].contentsubtype == "spotify") {
                probeLatestPodcastSpotify(buffer[i].contentargtwo);
              }

              break;

            case "event":
              probeLatestEvents(buffer[i].contentargone);
              break;

            default:
              results.add(ContentData(
                  contentid: buffer[i].contentid,
                  contenttype: buffer[i].contenttype,
                  contentsubtype: buffer[i].contentsubtype,
                  contentargone: buffer[i].contentargone,
                  contentargtwo: buffer[i].contentargtwo));
              content.add(i);
              // VibranceDatabase.instance.updateWeight(i, buffer[i].contentweight - 1);
              break;
          }
        }
      } else {
        print("We have plenty of data to work with... populating 6 entries");
        for (int i = 0; i < 6; i++) {
          switch (buffer[i].contenttype) {
            case "podcast":
              if (buffer[i].contentsubtype == "rss") {
                probeLatestPodcastRSS(buffer[i].contentargone);
              } else if (buffer[i].contentsubtype == "spotify") {
                probeLatestPodcastSpotify(buffer[i].contentargtwo);
              }
              break;

            case "event":
              probeLatestEvents(buffer[i].contentargone);
              break;

            default:
              results.add(ContentData(
                  contentid: buffer[i].contentid,
                  contenttype: buffer[i].contenttype,
                  contentargone: buffer[i].contentargone,
                  contentargtwo: buffer[i].contentargtwo));
              content.add(i);
              // VibranceDatabase.instance.updateWeight(i, buffer[i].contentweight - 1);
              break;
          }
        }
      }
    } else {
      print("Everything is not weight of 3, moving on...");
    }
    print(content);
    print(results);
    buffer.clear();
  }
}

//This is for manual intervention and testing
Future pullContentData(int id) async {
  final db = await VibranceDatabase.instance.database;

  var typeBuffer = await db.query("Content", columns: ["type"]);
  var type = typeBuffer[id - 1]["type"].toString();

  var argoneBuffer = await db.query("Content", columns: ["text"]);
  var argone = argoneBuffer[id - 1]["text"].toString();

  var argtwoBuffer = await db.query("Content", columns: ["raw"]);
  var argtwo = argtwoBuffer[id - 1]["raw"];

  results.add(ContentData(
      contentid: id,
      contenttype: type,
      contentargone: argone,
      contentargtwo: argtwo));
  content.add(id - 1);
  print(
      "${results.elementAt(id - 1).contentid}, ${results.elementAt(id - 1).contenttype}");
}
