// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables
import 'package:flutter/material.dart';
import 'package:vibrance/main.dart';
import 'package:vibrance/data_management.dart';

//For making decisions, lets use a quick buffer to store the data, this will be cleared when a decision has been made
var buffer = [];

Future populateBuffer() async {
  final db = await VibranceDatabase.instance.database;
  var counterBuffer = await db.query("Memories", columns: ["MAX(id)"]);
  var counter = int.tryParse(counterBuffer[0]['MAX(id)'].toString());
  counter ??= 0;
  print("Making decisions to display Memories...");
  for (var i = 0; i <= counter - 1; i++) {
    var memoriesdbResults = await db.query("Memories");

    //We use a new buffer since it's not hooked to anything

    buffer.add(MemoriesData(
        memoriesid: i + 1,
        memoriestextone: memoriesdbResults[i]["textone"].toString(),
        memoriestexttwo: memoriesdbResults[i]["texttwo"].toString(),
        memoriestype: memoriesdbResults[i]["type"].toString(),
        memoriessubtype: memoriesdbResults[i]["subtype"].toString(),
        memoriesprovider: memoriesdbResults[i]["provider"].toString(),
        memoriesdate: memoriesdbResults[i]["date"].toString(),
        memoriesargone: memoriesdbResults[i]["rawone"],
        memoriesargtwo: memoriesdbResults[i]["rawtwo"],
        memoriesargthree: memoriesdbResults[i]["rawthree"],
        memoriesargfour: memoriesdbResults[i]["rawfour"],
        memoriesweight: memoriesdbResults[i]["weight"]));
  }
}

Future makeDecisions(BuildContext context, mood) async {
  //Let's not overfill the screen...
  int entriesAmount = 6;
  if (MediaQuery.of(context).size.height < 1000) {
    entriesAmount = (MediaQuery.of(context).devicePixelRatio * 2).toInt();
  } else {
    entriesAmount = (MediaQuery.of(context).devicePixelRatio * 3).toInt();
  }

  buffer.clear();
  await populateBuffer();
  //We have the buffer filled, now let's filter it down
  Future pushContentFromBuffer(i) async {
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

      case "Photos":
        if (buffer[i].rawone.computeLuminance < 0.5) {
          if (mood < 4) {
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
                VibranceDatabase.instance.updateWeight(
                    buffer[i].memoriesid, buffer[i].memoriesweight - 1);
              } else {
                VibranceDatabase.instance.updateWeight(
                    buffer[i].memoriesid, buffer[i].memoriesweight + 1);
              }
            }
          }
        }
        break;

      case "Event":
        if (!context.mounted) return;
        await probeLatestEvents(buffer[i].memoriestextone);
        break;

      case "Tips":
        await probeLatestTip();
        break;
      case "Music":
        if (buffer[i].memoriessubtype == "Top Track") {
          if (buffer[i].memoriesprovider == "Spotify") {
            if (!context.mounted) return;
            await invokeSpotify(context);
            await probeTopTrackSpotify();
          }
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
          if (sorting == true) {
            if (buffer[i].memoriesweight > 1.1) {
              VibranceDatabase.instance.updateWeight(
                  buffer[i].memoriesid, buffer[i].memoriesweight - 1);
            } else {
              VibranceDatabase.instance.updateWeight(
                  buffer[i].memoriesid, buffer[i].memoriesweight + 1);
            }
          }
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
            VibranceDatabase.instance.updateWeight(
                buffer[i].memoriesid, buffer[i].memoriesweight - 1);
          } else {
            VibranceDatabase.instance.updateWeight(
                buffer[i].memoriesid, buffer[i].memoriesweight + 1);
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
      memoriesargtwo: "",
      memoriesweight: 3.0,
    ));
    memories.add(0);
  } else {
    if (buffer.every((element) => element.memoriesweight == 3)) {
      print("Everything is weight of 3, using first couple of elements...");

      if (buffer.length < entriesAmount) {
        print(
            "We don't have enough Memories to populate a full list...using whatever we have...");
        for (int i = 0; i <= buffer.length - 1; i++) {
          pushContentFromBuffer(i);
        }
      } else {
        print(
            "We have plenty of data to work with... populating $entriesAmount entries");
        //Certain memory types must remain a priority on the stack, if they aren't let's move them to the top
        for (int i = 0; i < buffer.length; i++) {
          switch (buffer[i].memoriestype) {
            case "Podcast":
            case "Event":
              buffer.insert(0, buffer[i]);
              buffer.removeAt(i + 1);
            case "Music":
              if (buffer[i].memoriessubtype == "Top Track") {
                buffer.insert(0, buffer[i]);
                buffer.removeAt(i + 1);
              } else {}
              break;

            default:
              break;
          }
        }
        if (buffer.length > entriesAmount) {
          //We only want to keep the first 6 elements
          buffer.removeRange(entriesAmount, buffer.length);
        }
        for (int i = 0; i < buffer.length; i++) {
          await pushContentFromBuffer(i);
        }
      }
    } else {
      print("Everything is not weight of 3, moving on...");
      if (sorting == true) {
        buffer.shuffle();
        buffer.sort(((a, b) {
          return (double.parse(b.memoriesweight.toString()))
              .compareTo(double.parse(a.memoriesweight.toString()));
        }));

        //Certain memory types must remain a priority on the stack, if they aren't let's move them to the top
        for (int i = 0; i < buffer.length; i++) {
          switch (buffer[i].memoriestype) {
            case "Podcast":
            case "Event":
              buffer.insert(0, buffer[i]);
              buffer.removeAt(i + 1);
            case "Music":
              if (buffer[i].memoriessubtype == "Top Track") {
                buffer.insert(0, buffer[i]);
                buffer.removeAt(i + 1);
              } else {}
              break;

            default:
              break;
          }
        }

        if (buffer.length > entriesAmount) {
          //We only want to keep the first 6 elements
          buffer.removeRange(entriesAmount, buffer.length);
        }
        print(buffer.length);
        for (int i = 0; i < buffer.length; i++) {
          await pushContentFromBuffer(i);
        }
      } else {
        if (buffer.length > entriesAmount) {
          //We only want to keep the first 6 elements
          buffer.removeRange(entriesAmount, buffer.length);
        }

        for (int i = 0; i < buffer.length; i++) {
          await pushContentFromBuffer(i);
        }
      }
    }
  }
  //buffer.clear();
}

Future pullAllMemoriesData() async {
  //Clear the arrays in case, as to not load in stale data...
  //For whatever reason, even though the length of the arrays could be 0, it's not "considered" empty
  if (results.isNotEmpty) {
    results.clear();
  }
  if (memories.isNotEmpty) {
    memories.clear();
  }

  final db = await VibranceDatabase.instance.database;

  var counterBuffer = await db.query("Memories", columns: ["MAX(id)"]);
  var counter = int.tryParse(counterBuffer[0]['MAX(id)'].toString());
  counter ??= 0;
  var memoriesdbResults = await db.query("Memories");
  print("Pulling all Memories Data...");
  for (var i = 0; i <= counter - 1; i++) {
    results.add(MemoriesData(
        memoriesid: i,
        memoriestextone: memoriesdbResults[i]["textone"].toString(),
        memoriestexttwo: memoriesdbResults[i]["texttwo"].toString(),
        memoriestype: memoriesdbResults[i]["type"].toString(),
        memoriessubtype: memoriesdbResults[i]["subtype"].toString(),
        memoriesprovider: memoriesdbResults[i]["provider"].toString(),
        memoriesdate: memoriesdbResults[i]["date"].toString(),
        memoriesargone: memoriesdbResults[i]["rawone"],
        memoriesargtwo: memoriesdbResults[i]["rawtwo"],
        memoriesargthree: memoriesdbResults[i]["rawthree"],
        memoriesargfour: memoriesdbResults[i]["rawfour"],
        memoriesweight: memoriesdbResults[i]["weight"]));
    memories.add(i);
  }
}

Future contingencyDecision(index) async {
//Using this in case we need to replace a memory with something safer
  if (buffer.isNotEmpty) {
    for (int i = 0; i < buffer.length; i++) {
      switch (buffer[i].memorytype) {
        case "Music":
          break;
        case "Photo":
          break;
        case "Voice":
          break;
        case "Text":
          break;
        case "Tips":
          break;
      }
    }
  }
}

//This is for manual intervention and testing
Future pullSingleMemoriesData(int id) async {
  final db = await VibranceDatabase.instance.database;
  var memoriesdbResults = await db.query("Memories");
  id = id - 1;
  results.add(MemoriesData(
      memoriesid: id,
      memoriestextone: memoriesdbResults[id]["textone"].toString(),
      memoriestexttwo: memoriesdbResults[id]["texttwo"].toString(),
      memoriestype: memoriesdbResults[id]["type"].toString(),
      memoriessubtype: memoriesdbResults[id]["subtype"].toString(),
      memoriesprovider: memoriesdbResults[id]["provider"].toString(),
      memoriesdate: memoriesdbResults[id]["date"].toString(),
      memoriesargone: memoriesdbResults[id]["rawone"],
      memoriesargtwo: memoriesdbResults[id]["rawtwo"],
      memoriesargthree: memoriesdbResults[id]["rawthree"],
      memoriesargfour: memoriesdbResults[id]["rawfour"],
      memoriesweight: memoriesdbResults[id]["weight"]));
  memories.add(id);
  print(
      "${results.elementAt(id - 1).memoriesid}, ${results.elementAt(id - 1).memoriestype}");
}
