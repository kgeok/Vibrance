// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:vibrance/main.dart';
import 'package:vibrance/data_management.dart';

//For making decisions, lets use a quick buffer to store the data, this will be cleared when a decsion has been made
var buffer = [];

Future makeDecisions(BuildContext context) async {
  final db = await VibranceDatabase.instance.database;

  var counterBuffer = await db.query("Memories", columns: ["MAX(id)"]);
  var counter = int.tryParse(counterBuffer[0]['MAX(id)'].toString());
  counter ??= 0;
  print("Making decisions to display Memories...");
  for (var i = 0; i <= counter - 1; i++) {
    var typeBuffer = await db.query("Memories", columns: ["type"]);
    var type = typeBuffer[i]["type"].toString();

    var subtypeBuffer = await db.query("Memories", columns: ["subtype"]);
    var subtype = subtypeBuffer[i]["subtype"].toString();

    var providerBuffer = await db.query("Memories", columns: ["provider"]);
    var provider = providerBuffer[i]["provider"].toString();

    var captionBuffer = await db.query("Memories", columns: ["text"]);
    var caption = captionBuffer[i]["text"].toString();

    var argoneBuffer = await db.query("Memories", columns: ["raw"]);
    var argone = argoneBuffer[i]["raw"];

    var weightBuffer = await db.query("Memories", columns: ["weight"]);
    var weight = weightBuffer[i]["weight"];

    //We use a new buffer since it's not hooked to anything

    buffer.add(MemoriesData(
        memoriesid: i,
        memoriescaption: caption,
        memoriestype: type,
        memoriessubtype: subtype,
        memoriesprovider: provider,
        memoriesargone: argone,
        memoriesargtwo: "",
        memoriesweight: weight));
  }
  //print(buffer.length);

  if (buffer.isEmpty) {
    print("We have nothing to work with...");
    results.add(MemoriesData(
        memoriesid: 1,
        memoriescaption: "No Memories",
        memoriestype: "default",
        memoriessubtype: "default",
        memoriesprovider: "system",
        memoriesargone: "Go to Settings to add Memories.",
        memoriesargtwo: ""));
    memories.add(0);
  } else {
    if (buffer.every((element) => element.memoriesweight == 3)) {
      print("Everything is weight of 3, using first couple of elements...");

      if (buffer.length < 6) {
        print(
            "We don't have enough Memories to populate a full list...using whatever we have...");
        for (int i = 0; i <= buffer.length - 1; i++) {
          switch (buffer[i].memoriestype) {
            case "podcast":
              if (buffer[i].memoriesprovider == "rss") {
                probeLatestPodcastRSS(buffer[i].memoriescaption);
              } else if (buffer[i].memoriesprovider == "spotify") {
                if (!context.mounted) return;
                await invokeSpotify(context);
                probeLatestPodcastSpotify(buffer[i].memoriesargone);
              }

              break;

            case "event":
              probeLatestEvents(buffer[i].memoriescaption);
              break;

            default:
              results.add(MemoriesData(
                  memoriesid: buffer[i].memoriesid,
                  memoriescaption: buffer[i].memoriescaption,
                  memoriestype: buffer[i].memoriestype,
                  memoriessubtype: buffer[i].memoriessubtype,
                  memoriesprovider: buffer[i].memoriesprovider,
                  memoriesargone: buffer[i].memoriesargone,
                  memoriesargtwo: buffer[i].memoriesargtwo));
              memories.add(i);

              break;
          }
        }
      } else {
        print("We have plenty of data to work with... populating 6 entries");
        for (int i = 0; i < 6; i++) {
          switch (buffer[i].memoriestype) {
            case "podcast":
              if (buffer[i].memoriesprovider == "rss") {
                probeLatestPodcastRSS(buffer[i].memoriescaption);
              } else if (buffer[i].memoriesprovider == "spotify") {
                if (!context.mounted) return;
                await invokeSpotify(context);
                probeLatestPodcastSpotify(buffer[i].memoriesargone);
              }
              break;

            case "event":
              probeLatestEvents(buffer[i].memoriescaption);
              break;

            default:
              results.add(MemoriesData(
                  memoriesid: buffer[i].memoriesid,
                  memoriescaption: buffer[i].memoriescaption,
                  memoriestype: buffer[i].memoriestype,
                  memoriessubtype: buffer[i].memoriessubtype,
                  memoriesprovider: buffer[i].memoriesprovider,
                  memoriesargone: buffer[i].memoriesargone,
                  memoriesargtwo: buffer[i].memoriesargtwo));
              memories.add(i);
/*               VibranceDatabase.instance
                  .updateWeight(i, buffer[i].memoriesweight - 1); */
              break;
          }
        }
      }
    } else {
      print("Everything is not weight of 3, moving on...");
    }
    print(memories);
    print(results);
    buffer.clear();
  }
}

//This is for manual intervention and testing
Future pullMemoriesData(int id) async {
  final db = await VibranceDatabase.instance.database;

  var typeBuffer = await db.query("Memories", columns: ["type"]);
  var type = typeBuffer[id - 1]["type"].toString();

  var subtypeBuffer = await db.query("Memories", columns: ["subtype"]);
  var subtype = subtypeBuffer[id - 1]["subtype"].toString();

  var providerBuffer = await db.query("Memories", columns: ["provider"]);
  var provider = providerBuffer[id - 1]["provider"].toString();

  var captionBuffer = await db.query("Memories", columns: ["text"]);
  var caption = captionBuffer[id - 1]["text"].toString();

  var argoneBuffer = await db.query("Memories", columns: ["raw"]);
  var argone = argoneBuffer[id - 1]["raw"];

  results.add(MemoriesData(
      memoriesid: id,
      memoriescaption: caption,
      memoriestype: type,
      memoriessubtype: subtype,
      memoriesprovider: provider,
      memoriesargone: argone,
      memoriesargtwo: ""));
  memories.add(id - 1);
  print(
      "${results.elementAt(id - 1).memoriesid}, ${results.elementAt(id - 1).memoriestype}");
}
