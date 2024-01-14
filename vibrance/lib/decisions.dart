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

    var textoneBuffer = await db.query("Memories", columns: ["textone"]);
    var textone = textoneBuffer[i]["textone"].toString();

    var texttwoBuffer = await db.query("Memories", columns: ["texttwo"]);
    var texttwo = texttwoBuffer[i]["texttwo"].toString();

    var argoneBuffer = await db.query("Memories", columns: ["rawone"]);
    var argone = argoneBuffer[i]["rawone"];

    var argtwoBuffer = await db.query("Memories", columns: ["rawtwo"]);
    var argtwo = argtwoBuffer[i]["rawtwo"];

    var argthreeBuffer = await db.query("Memories", columns: ["rawthree"]);
    var argthree = argthreeBuffer[i]["rawthree"];

    var weightBuffer = await db.query("Memories", columns: ["weight"]);
    var weight = weightBuffer[i]["weight"];

    //We use a new buffer since it's not hooked to anything

    buffer.add(MemoriesData(
        memoriesid: i,
        memoriestextone: textone,
        memoriestexttwo: texttwo,
        memoriestype: type,
        memoriessubtype: subtype,
        memoriesprovider: provider,
        memoriesargone: argone,
        memoriesargtwo: argtwo,
        memoriesargthree: argthree,
        memoriesweight: weight));
  }
  void pushContentFromBuffer(i) async {
    switch (buffer[i].memoriestype) {
      case "Podcast":
        if (buffer[i].memoriesprovider == "RSS") {
          await probeLatestPodcastRSS(
              buffer[i].memoriesargone, buffer[i].memoriesargtwo);
        } else if (buffer[i].memoriesprovider == "Spotify") {
          if (!context.mounted) return;
          await invokeSpotify(context);
          await probeLatestPodcastSpotify(
              buffer[i].memoriesargone, buffer[i].memoriesargtwo);
        }

        break;

      case "Event":
        await probeLatestEvents(buffer[i].memoriestextone);
        break;

      case "Tips":
        await probeLatestTip();
        break;
      case "Music":
        if (buffer[i].memoriessubtype == "Top Track") {
          if (!context.mounted) return;
          await invokeSpotify(context);
          await probeTopTrackSpotify();
        } else {
          results.add(MemoriesData(
              memoriesid: buffer[i].memoriesid,
              memoriestextone: buffer[i].memoriestextone,
              memoriestexttwo: buffer[i].memoriestexttwo,
              memoriestype: buffer[i].memoriestype,
              memoriessubtype: buffer[i].memoriessubtype,
              memoriesprovider: buffer[i].memoriesprovider,
              memoriesweight: buffer[i].memoriesweight,
              memoriesargone: buffer[i].memoriesargone,
              memoriesargtwo: buffer[i].memoriesargtwo,
              memoriesargthree: buffer[i].memoriesargthree));
          memories.add(i);
        }
        break;

      default:
        results.add(MemoriesData(
            memoriesid: buffer[i].memoriesid,
            memoriestextone: buffer[i].memoriestextone,
            memoriestexttwo: buffer[i].memoriestexttwo,
            memoriestype: buffer[i].memoriestype,
            memoriessubtype: buffer[i].memoriessubtype,
            memoriesprovider: buffer[i].memoriesprovider,
            memoriesweight: buffer[i].memoriesweight,
            memoriesargone: buffer[i].memoriesargone,
            memoriesargtwo: buffer[i].memoriesargtwo,
            memoriesargthree: buffer[i].memoriesargthree));
        memories.add(i);
        if (sorting == true) {
          if (buffer[i].memoriesweight > 1.1) {
            VibranceDatabase.instance
                .updateWeight(i, buffer[i].memoriesweight - 1);
          } else {
            VibranceDatabase.instance
                .updateWeight(i, buffer[i].memoriesweight + 1);
          }
        }
        break;
    }
  }

  if (buffer.isEmpty) {
    print("We have nothing to work with...");
    results.add(MemoriesData(
        memoriesid: 1,
        memoriestextone: "No Memories",
        memoriestexttwo: "",
        memoriestype: "Default",
        memoriessubtype: "Default",
        memoriesprovider: "System",
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
          pushContentFromBuffer(i);
        }
      } else {
        print("We have plenty of data to work with... populating 6 entries");
        for (int i = 0; i < 6; i++) {
          pushContentFromBuffer(i);
        }
      }
    } else {
      print("Everything is not weight of 3, moving on...");
      if (sorting == true) {
        //buffer.shuffle();
        buffer.sort(((b, a) {
          return (double.parse(a.memoriesweight.toString()))
              .compareTo(double.parse(b.memoriesweight.toString()));
        }));

        for (int i = 0; i < 6; i++) {
          pushContentFromBuffer(i);
        }
      } else {
        for (int i = 0; i < 6; i++) {
          pushContentFromBuffer(i);
        }
      }
    }
    buffer.clear();
  }
}

Future pullAllMemoriesData() async {
  if (results.isNotEmpty) {
    results.clear();
    memories.clear();
  }
  final db = await VibranceDatabase.instance.database;

  var counterBuffer = await db.query("Memories", columns: ["MAX(id)"]);
  var counter = int.tryParse(counterBuffer[0]['MAX(id)'].toString());
  counter ??= 0;
  print("Pulling all Memories Data...");
  for (var i = 0; i <= counter - 1; i++) {
    var typeBuffer = await db.query("Memories", columns: ["type"]);
    var type = typeBuffer[i]["type"].toString();

    var subtypeBuffer = await db.query("Memories", columns: ["subtype"]);
    var subtype = subtypeBuffer[i]["subtype"].toString();

    var providerBuffer = await db.query("Memories", columns: ["provider"]);
    var provider = providerBuffer[i]["provider"].toString();

    var textoneBuffer = await db.query("Memories", columns: ["textone"]);
    var textone = textoneBuffer[i]["textone"].toString();

    var texttwoBuffer = await db.query("Memories", columns: ["texttwo"]);
    var texttwo = texttwoBuffer[i]["texttwo"].toString();

    var dateBuffer = await db.query("Memories", columns: ["date"]);
    var date = dateBuffer[i]["date"].toString();

    var argoneBuffer = await db.query("Memories", columns: ["rawone"]);
    var argone = argoneBuffer[i]["rawone"];

    var argtwoBuffer = await db.query("Memories", columns: ["rawtwo"]);
    var argtwo = argtwoBuffer[i]["rawtwo"];

    var argthreeBuffer = await db.query("Memories", columns: ["rawthree"]);
    var argthree = argthreeBuffer[i]["rawthree"];

    var weightBuffer = await db.query("Memories", columns: ["weight"]);
    var weight = weightBuffer[i]["weight"];

    results.add(MemoriesData(
        memoriesid: i,
        memoriestextone: textone,
        memoriestexttwo: texttwo,
        memoriestype: type,
        memoriessubtype: subtype,
        memoriesprovider: provider,
        memoriesweight: weight,
        memoriesdate: date,
        memoriesargone: argone,
        memoriesargtwo: argtwo,
        memoriesargthree: argthree));
    memories.add(i);
/*     print(
        "${results.elementAt(i).memoriesid}, ${results.elementAt(i).memoriestype}"); */
  }
}

//This is for manual intervention and testing
Future pullSingleMemoriesData(int id) async {
  final db = await VibranceDatabase.instance.database;

  var typeBuffer = await db.query("Memories", columns: ["type"]);
  var type = typeBuffer[id - 1]["type"].toString();

  var subtypeBuffer = await db.query("Memories", columns: ["subtype"]);
  var subtype = subtypeBuffer[id - 1]["subtype"].toString();

  var providerBuffer = await db.query("Memories", columns: ["provider"]);
  var provider = providerBuffer[id - 1]["provider"].toString();

  var textoneBuffer = await db.query("Memories", columns: ["textone"]);
  var textone = textoneBuffer[id - 1]["textone"].toString();

  var texttwoBuffer = await db.query("Memories", columns: ["textwwo"]);
  var texttwo = texttwoBuffer[id - 1]["texttwo"].toString();
  var argoneBuffer = await db.query("Memories", columns: ["rawone"]);
  var argone = argoneBuffer[id - 1]["rawone"];

  var argtwoBuffer = await db.query("Memories", columns: ["rawtwo"]);
  var argtwo = argtwoBuffer[id - 1]["rawtwo"];

  var argthreeBuffer = await db.query("Memories", columns: ["rawthree"]);
  var argthree = argthreeBuffer[id - 1]["rawthree"];

  var weightBuffer = await db.query("Memories", columns: ["weight"]);
  var weight = weightBuffer[id - 1]["weight"];

  results.add(MemoriesData(
      memoriesid: id,
      memoriestextone: textone,
      memoriestexttwo: texttwo,
      memoriestype: type,
      memoriessubtype: subtype,
      memoriesprovider: provider,
      memoriesweight: weight,
      memoriesargone: argone,
      memoriesargtwo: argtwo,
      memoriesargthree: argthree));
  memories.add(id - 1);
  print(
      "${results.elementAt(id - 1).memoriesid}, ${results.elementAt(id - 1).memoriestype}");
}
