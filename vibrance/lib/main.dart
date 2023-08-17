// ignore_for_file: avoid_print, use_build_context_synchronously, prefer_typing_uninitialized_variables,  prefer_const_constructors, unused_import, prefer_interpolation_to_compose_strings, unused_local_variable
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibrance/data_management.dart';
import 'package:vibrance/decisions.dart';
import 'package:vibrance/dialogs.dart';
import 'package:vibrance/theme/custom_theme.dart';
import 'package:vibrance/quotes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spotify/spotify.dart' as spotify;
import 'package:record/record.dart';
import 'package:sqflite/sqflite.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

void main() async {
  runApp(const MaterialApp(home: MainPage()));
  VibranceDatabase.instance.initStatefromDB();
  populateFromState();
  //https://feeds.simplecast.com/ozLNkAqI
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);
  @override
  State<MainPage> createState() => MyAppState();
  static const MainPage instance = MainPage._init();
  const MainPage._init();
}

GlobalKey<MyAppState> key = GlobalKey();
const sku = "Vibrance";
const version = "0.5";
const release = "Pre-Release";
const spotifycid = "677ce23bfdfd449e95956abadaded7a9";
const spotifysid = "449148ca0aa44a9e8d0dff16b517c7de";
double currentMood = 1;
var currentTheme; //Light or Dark theme
int onboarding = 0;
var days = [];
var results = [];
var services = [];
List<int> journal = [];
List<int> content = [];
DateTime currentDate = DateTime.now();
var spotifyApp;
final record = Record();
final photo = ImagePicker();
final event = Calendar();
final client = http.Client();
var deviceCalendarPlugin = DeviceCalendarPlugin();
var allCalendars;
var allCalendarsBuffer;
bool isRecording = false;
String date = currentDate.toString().substring(0, 10);
int dayCounter = 0;
var pageIndex = 0;
var note = "";
var noteBuffer;
var textBuffer;
var text;
double entrywidth = 350;
Color color = Color(0xFF4A3E7E);
var backgroundcolor;
String peptalk = "This one is a good one.";

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class DayData {
  var dayid;
  late var daydate;
  late var daymood;
  late var daynote;
  late var daycaption;
  late var daycolor;

  DayData(
      {this.dayid,
      required this.daydate,
      required this.daymood,
      this.daynote,
      this.daycaption,
      this.daycolor});
}

class ContentData {
  var contentid;
  late var contenttype;
  late var contentsubtype;
  late var contentdate;
  late var contentcaption;
  late var contentargone;
  late var contentargtwo;
  late var contentargthree;
  late var contentweight;

  ContentData(
      {this.contentid,
      required this.contenttype,
      this.contentsubtype,
      this.contentcaption,
      this.contentargone,
      this.contentargtwo,
      this.contentargthree,
      this.contentweight});
}

class ServiceData {
  var serviceid;
  late var servicename;
  late var dataone;
  late var datatwo;
  late var datathree;
  late var datafour;
  late var datafive;

  ServiceData(this.serviceid, this.servicename, this.dataone, this.datatwo,
      this.datathree, this.datafour, this.datafive);
}

Future<void> redirectURL(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw "Error launching link";
  }
}

//Audio Recording Components

Future beginRecording() async {
  final root = await getDatabasesPath();
  try {
    if (await record.hasPermission()) {
      await record.start(path: root + "/recording.m4a");
      isRecording = await record.isRecording();
      print("Recording: $isRecording");
      print(root);
    }
  } catch (e) {
    print(e);
  }
}

Future stopRecording() async {
  final selectedAudiotoData;
  isRecording = await record.isRecording();
  await record.stop();
  var path = await record.stop();
  print(path);

  if (path != null) {
    final XFile selectedAudio = XFile(path);
    //Disposing for when we are done to clear device space
    File filebuffer = File(path);
    selectedAudiotoData = await selectedAudio.readAsBytes();
    if (noteBuffer == "") {
      noteBuffer = DateTime.now().toString().substring(0, 10) + " Recording";
    }
    noteBuffer ??= DateTime.now().toString().substring(0, 10) + " Recording";
    note = noteBuffer;
    VibranceDatabase.instance
        .updateContentDB("voice", "", noteBuffer, selectedAudiotoData);
    filebuffer.delete();
    noteBuffer = "";
  }

  isRecording = false;
}

void openAudioPlayer(BuildContext context, argone, argtwo) async {
  final audioplayer = AudioPlayer();
  final root = await getDatabasesPath();
  //We know this file variable won't be used but we need an excuse for the file to be generated
  var file = File(root + "/recording.m4a").writeAsBytes(argtwo);
  //Disposing for when we are done to clear device space
  File filebuffer = await file;
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor: Colors.green,
          title: Text("Voice Note", style: dialogHeader),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(argone, style: dialogBody),
                Center(
                    child: Row(children: [
                  IconButton(
                      onPressed: () async {
                        await audioplayer
                            .play(DeviceFileSource(root + "/recording.m4a"));
                      },
                      iconSize: 50,
                      icon: Icon(Icons.play_arrow, color: Colors.white)),
                  IconButton(
                      onPressed: () async {
                        audioplayer.pause();
                      },
                      iconSize: 50,
                      icon: Icon(Icons.pause, color: Colors.white)),
                  IconButton(
                      onPressed: () async {
                        audioplayer.stop();
                      },
                      iconSize: 50,
                      icon: Icon(Icons.stop, color: Colors.white)),
                ]))
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK', style: dialogBody),
              onPressed: () {
                audioplayer.stop();
                filebuffer.delete();
                Navigator.of(context).pop();
              },
            )
          ]);
    },
  );
}

Future addContent() async {
  //Adding this here because of some weird IDE issue...
  content.add(0);
}

Future authenticateSpotify(BuildContext context) async {
  //This is the provider for logging into Spotify
  var responseUri;
  final credentials = spotify.SpotifyApiCredentials(spotifycid, spotifysid);
  final grant = spotify.SpotifyApi.authorizationCodeGrant(credentials);
  const redirectUri = "https://kgeok.github.io/Vibrance/Spotify/";
  final scopes = ['user-read-email', 'user-library-read'];
  final authUri =
      grant.getAuthorizationUrl(Uri.parse(redirectUri), scopes: scopes);

  var controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) async {
          if (request.url.startsWith(redirectUri)) {
            responseUri = request.url;
            print("Got: $responseUri");
            spotifyApp =
                spotify.SpotifyApi.fromAuthCodeGrant(grant, responseUri);
            var credentials = await spotifyApp.getCredentials();
            VibranceDatabase.instance.addService(
                1,
                "spotify",
                credentials.accessToken,
                credentials.refreshToken,
                credentials.scopes,
                credentials.expiration,
                ""); //TODO Fix this
          }
          return NavigationDecision.navigate;
        },
      ),
    )
    ..loadRequest(Uri.parse(authUri.toString()));

  showModalBottomSheet(
      backgroundColor: lightMode,
      context: context,
      enableDrag: false,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
            heightFactor: 0.9,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      icon: Icon(
                        Icons.close,
                        color: Colors.white,
                      )),
                  Expanded(child: WebViewWidget(controller: controller)),
                ]));
      });
}

//Podcast Components

Future probeLatestPodcastRSS(String url) async {
  var rssfeed = await client.get(Uri.parse(url));
  var content = RssFeed.parse(rssfeed.body);
  print(content.title);
  RssItem latestitem = content.items!.first;
  print(latestitem.title);
  print(latestitem.pubDate);

  results.add(ContentData(
      contenttype: "podcast",
      contentsubtype: "rss",
      contentargone: (content.title).toString(),
      contentargtwo: (latestitem.title).toString(),
      contentargthree: (latestitem.pubDate).toString()));

  addContent();
}

Future probeLatestPodcastSpotify(String id) async {
  //await invokeSpotify(context);
  if (spotifyApp != null) {
    //Because Show title isn't coming from the episode we will take it out seperately
    var show = await spotifyApp.shows.get(id);
    var episode = spotifyApp.shows.episodes(id);
    var latestitem = (await episode.first()).items!.first;
    print(show.name);
    print(latestitem.name);
    results.add(ContentData(
        contenttype: "podcast",
        contentsubtype: "spotify",
        contentargone: (show.name).toString(),
        contentargtwo: (latestitem.name).toString(),
        contentargthree: (latestitem.releaseDate).toString()));

    addContent();
  } else {
    print("Spotify not Ready...");
  }
}

//Events Components

Future probeLatestEvents(String name) async {
  //We have to use this function to pull the events out of the given calendar
  final startDate = DateTime.now().add(const Duration(days: -1));
  final endDate = DateTime.now().add(const Duration(days: 2));
  var eventparams =
      RetrieveEventsParams(startDate: startDate, endDate: endDate);
  //Because allCalendars is locked, lets make a buffer to store the data that we can touch
  allCalendars = await deviceCalendarPlugin.requestPermissions();
  allCalendars = await deviceCalendarPlugin.retrieveCalendars();
  allCalendarsBuffer = allCalendars?.data;

  //Since it's not so easy to just pull the contents using IndexOf or something else, we have to just traverse the array and match it to the given calendar
  for (int i = 0; i < (allCalendarsBuffer.length); i++) {
    if (allCalendarsBuffer[i].name == name) {
      var events = await deviceCalendarPlugin.retrieveEvents(
          allCalendarsBuffer[i].id, eventparams);
      var eventsBuffer = events.data;

      if (eventsBuffer != null) {
        for (int i = 0; i < eventsBuffer.length; i++) {
          //We're only going to poll three events
          print(eventsBuffer[i].title);
          print(eventsBuffer[i].start);

          results.add(ContentData(
              contentid: i,
              contenttype: "event",
              contentargone: (eventsBuffer[i].title).toString(),
              contentargtwo: (eventsBuffer[i].start).toString()));
          content.add(i);
        }
      }
    }
  }
}

void populateFromState() async {
  await Future.delayed(const Duration(
      milliseconds:
          1500)); //It apparently takes 1 second or so for DB to populate State

  var counterBuffer =
      dayCounter; //I need to freeze the state of the counter so that it doesn't keep iterating on append
  for (var i = 0; i < counterBuffer; i++) {
    currentMood = days[i].daymood;
    date = days[i].daydate;

    journal.add(i - 1);
    print("Restored Entry: ${i + 1}");
  }
  date = currentDate.toString().substring(0, 10);
  currentMood = 1;
}

//Journal Entry Components

Widget journalEntry(BuildContext context, final caption, final mood, var date,
    var color, var note, var id) {
  return Center(
      child: Wrap(
    direction: Axis.vertical,
    spacing: 4,
    children: [
      InkWell(
          splashColor: color,
          highlightColor: color,
          onTap: () {
            journalDialog(context, caption, mood, date, color, note, id);
          },
          child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: 0.9,
              child: Container(
                  padding: const EdgeInsets.fromLTRB(2, 0, 0, 2),
                  decoration: ShapeDecoration(
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 3), // changes position of shadow
                        ),
                      ],
                      color: color,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  height: 65.0,
                  width: entrywidth,
                  child: Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                        Text("Mood: ${mood.toInt()}/6",
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                            style: GoogleFonts.newsCycle(
                                color: color.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 16)),
                        Text(date,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                            style: GoogleFonts.newsCycle(
                                fontWeight: FontWeight.w500,
                                color: color.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 14))
                      ]))))),
      const SizedBox(height: 1),
    ],
  ));
}

//Journal Dialog is long because each of these set of widgets are generated at once for each day in real-time
void journalDialog(BuildContext context, var caption, var mood, var date,
    var color, var note, var id) {
  mood = mood.toInt();
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor: color,
          title: Text("Mood: $mood/6",
              style: GoogleFonts.newsCycle(
                  color: color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(date.toString(),
                    style: GoogleFonts.newsCycle(
                        fontWeight: FontWeight.w600,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white)),
                const Text(""),
                Text(note.toString(),
                    style: GoogleFonts.newsCycle(
                        fontWeight: FontWeight.w600,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Options",
                  style: GoogleFonts.newsCycle(
                      fontWeight: FontWeight.w600,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                        backgroundColor: color,
                        title: Text("Options",
                            style: GoogleFonts.newsCycle(
                                color: color.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white)),
                        content: SingleChildScrollView(
                          child: ListBody(
                            children: <Widget>[
                              SimpleDialogOption(
                                  child: Text("Copy Entry",
                                      style: GoogleFonts.newsCycle(
                                          fontWeight: FontWeight.w600,
                                          color: color.computeLuminance() > 0.5
                                              ? Colors.black
                                              : Colors.white)),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                        text:
                                            "${"Mood: " + mood.toString() + ", " + date} " +
                                                note));
                                  }),
                              SimpleDialogOption(
                                  child: Text("Edit Note",
                                      style: GoogleFonts.newsCycle(
                                          fontWeight: FontWeight.w600,
                                          color: color.computeLuminance() > 0.5
                                              ? Colors.black
                                              : Colors.white)),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                            backgroundColor: color,
                                            title: Text('Enter New Note',
                                                style: GoogleFonts.newsCycle(
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        color.computeLuminance() >
                                                                0.5
                                                            ? Colors.black
                                                            : Colors.white)),
                                            content: SingleChildScrollView(
                                              child: ListBody(
                                                children: <Widget>[
                                                  TextField(
                                                      autofocus: true,
                                                      decoration: InputDecoration(
                                                          fillColor:
                                                              Colors.grey[300],
                                                          filled: true,
                                                          border:
                                                              const OutlineInputBorder(),
                                                          hintText: note),
                                                      onChanged: (value) {
                                                        noteBuffer = value;
                                                      }),
                                                ],
                                              ),
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                child: Text('Cancel',
                                                    style: GoogleFonts.newsCycle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            color.computeLuminance() >
                                                                    0.5
                                                                ? Colors.black
                                                                : Colors
                                                                    .white)),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              TextButton(
                                                child: Text('OK',
                                                    style: GoogleFonts.newsCycle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            color.computeLuminance() >
                                                                    0.5
                                                                ? Colors.black
                                                                : Colors
                                                                    .white)),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  if (noteBuffer == "") {
                                                    noteBuffer = "";
                                                  }
                                                  noteBuffer ??= "";
                                                  note = noteBuffer;
                                                  noteBuffer = "";
                                                  Navigator.pop(context);
                                                  VibranceDatabase.instance
                                                      .updateDaysDB(id, caption,
                                                          note, color);
                                                },
                                              )
                                            ]);
                                      },
                                    );
                                  }),
                              SimpleDialogOption(
                                  child: Text("Delete Entry",
                                      style: GoogleFonts.newsCycle(
                                          fontWeight: FontWeight.w600,
                                          color: color.computeLuminance() > 0.5
                                              ? Colors.red[800]
                                              : Colors.red[100])),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                            backgroundColor: Colors.orange[800],
                                            title: Text("Delete Entry?",
                                                style: dialogHeader),
                                            content: SingleChildScrollView(
                                              child: ListBody(
                                                children: <Widget>[
                                                  Text(
                                                      "Are you sure you want to delete this entry?",
                                                      style: dialogBody),
                                                ],
                                              ),
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                child: Text('Cancel',
                                                    style: dialogBody),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              TextButton(
                                                child: Text('OK',
                                                    style: dialogBody),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  days.removeAt(id - 1);
                                                  VibranceDatabase.instance
                                                      .initDBfromState();
                                                  //reenumerateState();
                                                  Navigator.of(context).pop();
                                                },
                                              )
                                            ]);
                                      },
                                    );
                                  }),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text("Dismiss",
                                style: GoogleFonts.newsCycle(
                                    fontWeight: FontWeight.w600,
                                    color: color.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white)),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          )
                        ]);
                  },
                );
              },
            ),
            TextButton(
              child: Text("Dismiss",
                  style: GoogleFonts.newsCycle(
                      fontWeight: FontWeight.w600,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ]);
    },
  );
}

List<Widget> makeJournalEntry(BuildContext context) {
  return List<Widget>.generate(journal.length, (int index) {
    return journalEntry(
        context,
        days[index].daycaption,
        days[index].daymood,
        days[index].daydate,
        days[index].daycolor,
        days[index].daynote,
        (index + 1));
  });
}

//Content Entry Components

Widget contentEntry(BuildContext context, var id, var type, var argone,
    var argtwo, var argthree) {
  switch (type) {
    case "music":
      color = Colors.pink;
      return InkWell(
          splashColor: color,
          highlightColor: color,
          onTap: () {
            null;
          },
          child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: 0.9,
              child: Container(
                  padding: const EdgeInsets.fromLTRB(1, 0, 0, 1),
                  decoration: ShapeDecoration(
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.125),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 3), // changes position of shadow
                        ),
                      ],
                      color: color,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  height: (MediaQuery.of(context).size.width / 2) - 30,
                  width: (MediaQuery.of(context).size.width / 2) - 10,
                  child: Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                        Text(argone,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                            style: GoogleFonts.newsCycle(
                                color: color.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 16)),
                        Text(argtwo,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                            style: GoogleFonts.newsCycle(
                                fontWeight: FontWeight.w500,
                                color: color.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 14))
                      ])))));

    case "podcast":
      color = Colors.purple;
      return InkWell(
          splashColor: color,
          highlightColor: color,
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                    backgroundColor: Colors.purple,
                    title: Text(argone, style: dialogHeader),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          Text(argthree, style: dialogBody),
                          Text("", style: dialogBody),
                          Text(argtwo, style: dialogBody),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('OK', style: dialogBody),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      )
                    ]);
              },
            );
          },
          child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: 0.9,
              child: Container(
                  padding: const EdgeInsets.fromLTRB(1, 0, 0, 1),
                  decoration: ShapeDecoration(
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.125),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 3), // changes position of shadow
                        ),
                      ],
                      color: color,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  height: (MediaQuery.of(context).size.width / 2) - 30,
                  width: (MediaQuery.of(context).size.width / 2) - 10,
                  child: Center(
                      child: Padding(
                          padding: EdgeInsetsDirectional.all(5),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(argone,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    maxLines: 1,
                                    style: GoogleFonts.newsCycle(
                                        color: color.computeLuminance() > 0.5
                                            ? Colors.black
                                            : Colors.white,
                                        fontSize: 18)),
                                Text(argtwo,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.newsCycle(
                                        fontWeight: FontWeight.w500,
                                        color: color.computeLuminance() > 0.5
                                            ? Colors.black
                                            : Colors.white,
                                        fontSize: 14))
                              ]))))));

    case "event":
      color = Colors.yellow;
      return InkWell(
          splashColor: color,
          highlightColor: color,
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                    backgroundColor: Colors.yellow,
                    title: Text(argone, style: dialogHeader),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          Text("", style: dialogBody),
                          Text(argtwo, style: dialogBody),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('OK', style: dialogBody),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      )
                    ]);
              },
            );
          },
          child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: 0.9,
              child: Container(
                  padding: const EdgeInsets.fromLTRB(1, 0, 0, 1),
                  decoration: ShapeDecoration(
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.125),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 3), // changes position of shadow
                        ),
                      ],
                      color: color,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  height: (MediaQuery.of(context).size.width / 2) - 30,
                  width: (MediaQuery.of(context).size.width / 2) - 10,
                  child: Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                        Text(argone.toString(),
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                            style: GoogleFonts.newsCycle(
                                color: color.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 16)),
                        Text(argtwo.toString(),
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                            style: GoogleFonts.newsCycle(
                                fontWeight: FontWeight.w500,
                                color: color.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 14))
                      ])))));

    case "photo":
      color = Colors.blue;
      print("");
      return InkWell(
          splashColor: color,
          highlightColor: color,
          onTap: () {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    content: Container(
                        height: 400,
                        width: (MediaQuery.of(context).size.width) - 10,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                                image: MemoryImage(argtwo),
                                fit: BoxFit.contain))),
                  );
                });
          },
          child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: 0.9,
              child: Container(
                padding: const EdgeInsets.fromLTRB(1, 0, 0, 1),
                decoration: ShapeDecoration(
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.125),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset:
                            const Offset(0, 3), // changes position of shadow
                      ),
                    ],
                    color: color,
                    image: DecorationImage(
                        image: MemoryImage(argtwo), fit: BoxFit.cover),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30))),
                height: (MediaQuery.of(context).size.width / 2) - 30,
                width: (MediaQuery.of(context).size.width / 2) - 10,
              )));

    case "voice":
      color = Colors.green;
      return InkWell(
          splashColor: color,
          highlightColor: color,
          onTap: () {
            openAudioPlayer(context, argone, argtwo);
          },
          child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: 0.9,
              child: Container(
                  padding: const EdgeInsets.fromLTRB(1, 0, 0, 1),
                  decoration: ShapeDecoration(
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.125),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 3), // changes position of shadow
                        ),
                      ],
                      color: color,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  height: (MediaQuery.of(context).size.width / 2) - 30,
                  width: (MediaQuery.of(context).size.width / 2) - 10,
                  child: Center(
                      child: Padding(
                          padding: EdgeInsetsDirectional.all(5),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(argone,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    maxLines: 1,
                                    style: GoogleFonts.newsCycle(
                                        color: color.computeLuminance() > 0.5
                                            ? Colors.black
                                            : Colors.white,
                                        fontSize: 20)),
                                Text("Voice Note",
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    maxLines: 1,
                                    style: GoogleFonts.newsCycle(
                                        fontWeight: FontWeight.w500,
                                        color: color.computeLuminance() > 0.5
                                            ? Colors.black
                                            : Colors.white,
                                        fontSize: 14))
                              ]))))));

    case "text":
      color = Colors.orange;
      return InkWell(
          splashColor: color,
          highlightColor: color,
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                    backgroundColor: Colors.orange,
                    title: Text("Text Note", style: dialogHeader),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          Text(argone, style: dialogBody),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('OK', style: dialogBody),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      )
                    ]);
              },
            );
          },
          child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: 0.9,
              child: Container(
                  padding: const EdgeInsets.fromLTRB(1, 0, 0, 1),
                  decoration: ShapeDecoration(
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.125),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 3), // changes position of shadow
                        ),
                      ],
                      color: color,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  height: (MediaQuery.of(context).size.width / 2) - 30,
                  width: (MediaQuery.of(context).size.width / 2) - 10,
                  child: Center(
                      child: Padding(
                          padding: EdgeInsetsDirectional.all(5),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(argone,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    maxLines: 1,
                                    style: GoogleFonts.newsCycle(
                                        color: color.computeLuminance() > 0.5
                                            ? Colors.black
                                            : Colors.white,
                                        fontSize: 22)),
                              ]))))));

    default:
      color = lightMode;
      return InkWell(
          splashColor: color,
          highlightColor: color,
          onTap: () {
            Navigator.of(context).pop();
            MaterialPageRoute(builder: (context) => const OnboardingPage());
          },
          child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: 0.9,
              child: Container(
                  padding: const EdgeInsets.fromLTRB(2, 0, 0, 2),
                  decoration: ShapeDecoration(
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.125),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 3), // changes position of shadow
                        ),
                      ],
                      color: color,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  height: (MediaQuery.of(context).size.width / 2) - 30,
                  width: (MediaQuery.of(context).size.width) - 10,
                  child: Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                        Text("No Content.",
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                            style: GoogleFonts.newsCycle(
                                color: color.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 16)),
                        Text("Go to Settings to add content.",
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                            style: GoogleFonts.newsCycle(
                                fontWeight: FontWeight.w500,
                                color: color.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 14))
                      ])))));
  }
}

void setVibrance(int vibe) {
  switch (vibe) {
    case 1:
      color = ui.Color.fromARGB(255, 47, 0, 0);
      peptalk = "Let's get back on track.";
      break;

    case 2:
      color = ui.Color.fromARGB(255, 59, 47, 0);
      peptalk = "We can do this.";
      break;

    case 3:
      color = ui.Color.fromARGB(255, 77, 119, 0);
      peptalk = "Just a little push forward.";
      break;

    case 4:
      color = ui.Color.fromARGB(255, 0, 73, 112);
      peptalk = "We can do this.";
      break;

    case 5:
      color = ui.Color.fromARGB(255, 255, 174, 0);
      peptalk = "We're just about there.";
      break;

    case 6:
      color = ui.Color.fromARGB(255, 255, 125, 125);
      peptalk = "This is the best yet.";
      break;
    default:
      color = Color(0xFF4A3E7E);
      peptalk = "This one is a good one.";
      break;
  }
}

void clearDaysWarning(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor: Colors.orange[800],
          title: Text("Clear Journal?", style: dialogHeader),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Are you sure you want to clear Journal?",
                    style: dialogBody),
                Text("(This action cannot be reversed)", style: dialogBody),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: dialogBody),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('OK', style: dialogBody),
              onPressed: () {
                clearState();
                Navigator.of(context).pop();
              },
            )
          ]);
    },
  );
}

void clearContentWarning(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor: Colors.orange[800],
          title: Text("Clear Content?", style: dialogHeader),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Are you sure you want to clear Content?",
                    style: dialogBody),
                Text("(This action cannot be reversed)", style: dialogBody),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: dialogBody),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('OK', style: dialogBody),
              onPressed: () {
                VibranceDatabase.instance.clearContentDB();
                Navigator.of(context).pop();
              },
            )
          ]);
    },
  );
}

void clearServicesWarning(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor: Colors.orange[800],
          title: Text("Log Out?", style: dialogHeader),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Are you sure you want to log out of all services?",
                    style: dialogBody),
                Text("(You will need to log back in later.)",
                    style: dialogBody),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: dialogBody),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('OK', style: dialogBody),
              onPressed: () {
                VibranceDatabase.instance.removeAllServices();
                services.clear();
                spotifyApp = null;
                Navigator.of(context).pop();
              },
            )
          ]);
    },
  );
}

void clearState() {
  journal = [];
  days = [];
  dayCounter = 0;
  VibranceDatabase.instance.clearDaysDB();
}

Future startOnboarding(BuildContext context) async {
  await Future.delayed(const Duration(
      milliseconds:
          1500)); //It apparently takes 1 second or so for DB to populate State

  if (onboarding == 1) {
    onboardDialog(
        context,
        "Welcome to $sku",
        "This is $sku, a way to push you forward with your own content.",
        "Inspire yourself with the help of your Music, Photos, Podcasts, Voice and more.",
        "Keep track of how you were feeling with the Journal",
        "All on Device and not stored in the cloud.");

    print("Onboarding...");
  } else {
    print("No Onboarding...");
  }
}

class MyAppState extends State<MainPage> {
  var pages = <Widget>[HomePage(), JournalPage(), SettingsPage()];

  void reenumerateState() {
    noteBuffer = "";
    note = "";
    dayCounter = 0;
    days.clear();
    setState(() {
      journal = [];
    });
    VibranceDatabase.instance.initStatefromDB();
  }

  @override
  initState() {
    super.initState();
    startOnboarding(context);
    if (release == "Pre-Release") {
      scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
          content: const Text('Pre-Release Version'),
          duration: Duration(milliseconds: 3000),
          backgroundColor: Colors.red[800],
          action: SnackBarAction(
              label: 'More Info',
              textColor: Colors.white,
              onPressed: () {
                simpleDialog(
                    context,
                    "Pre-Release Version",
                    "Confidential and Proprietary, Please Don't Share Information or Screenshots",
                    "Please Report any Bugs and Crashes, Take note of what you were doing when they occurred.",
                    "error");
              })));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: CustomTheme.lightTheme,
        darkTheme: CustomTheme.darkTheme,
        home: Scaffold(
          //backgroundColor: color,
          appBar: AppBar(),
          bottomNavigationBar: BottomNavigationBar(
              showSelectedLabels: false,
              showUnselectedLabels: false,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.book), label: 'Journal'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.settings), label: 'Settings')
              ],
              currentIndex: pageIndex,
              selectedItemColor: Colors.grey[200],
              onTap: ((value) => setState(() {
                    pageIndex = value;
                  }))),
          body: SafeArea(child: pages.elementAt(pageIndex)),
        ));
  }
}

Future invokeSpotify(BuildContext context) async {
  //Let's grab the Services data from the DB and put it into our ServiceData object based List
  await VibranceDatabase.instance.provideServiceData();
  //Let's find out which item in the list is the Spotify Cred Data...
  var spotifyindex =
      services.indexWhere((item) => (item.servicename) == "spotify");
  //If the result is not empty, which is considered a -1 index result, we can move forward
  if (spotifyindex != -1) {
    //We don't want this leaking out during Prod usage
    if (release == "Pre-Release") {
      print(spotifyindex);
      print(services[spotifyindex].servicename);
      print(services[spotifyindex].dataone);
      print(services[spotifyindex].datatwo);
      print(services[spotifyindex].datathree);
      print(services[spotifyindex].datafour);
    }
    final credentials = spotify.SpotifyApiCredentials(spotifycid, spotifysid,
        accessToken: services[spotifyindex].dataone,
        refreshToken: services[spotifyindex].datatwo,
        scopes: ['user-read-email', 'user-library-read'],
        expiration: DateTime.parse(services[spotifyindex].datafour));
    //We need to check if the refresh token date is expired...
    if ((DateTime.now())
        .isBefore(DateTime.parse(services[spotifyindex].datafour))) {
      spotifyApp = spotify.SpotifyApi(credentials);
    } else {
      //Token Refresh
      //Remove whatever is in the DB, refresh and then dump in the new data

      spotify.SpotifyApi api = spotify.SpotifyApi(credentials,
          onCredentialsRefreshed:
              (spotify.SpotifyApiCredentials newCred) async {
        print("Getting new Spotify OAuth Refresh Token...");
        VibranceDatabase.instance.removeAllServices();
        services.removeWhere((item) => (item.servicename) == "spotify");
        //VibranceDatabase.instance.removeService("Spotify"); //TODO: Throwing somekind of error, remove the delete all services test and fix this one
        await VibranceDatabase.instance.addService(
            1,
            "spotify",
            newCred.accessToken.toString(),
            newCred.refreshToken.toString(),
            newCred.scopes.toString(),
            newCred.expiration.toString(),
            ""); //TODO Fix this
      });
      invokeSpotify(context);
    }
  } else {
    authenticateSpotify(context);
  }
}

Future openResult(BuildContext context) async {
  dayCounter++;
  print("Mood: $currentMood");
  journal.add(dayCounter - 1);
  content.clear();
  results.clear();
  setVibrance(currentMood.toInt());
  await makeDecisions(context);
  showModalBottomSheet(
      backgroundColor: color,
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return FractionallySizedBox(
              heightFactor: 0.8,
              widthFactor: 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                      child: Text("Mood: ${currentMood.toInt()}/6",
                          style: GoogleFonts.newsCycle(
                            color: Colors.white,
                            fontSize: 40,
                          ))),
                  Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                      child: Text(peptalk,
                          style: GoogleFonts.newsCycle(
                            color: Colors.white,
                            fontSize: 20,
                          ))),
                  SizedBox(height: 15),
                  Center(
                      child: SingleChildScrollView(
                          child: Column(children: [
                    Wrap(
                        direction: Axis.horizontal,
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            List<Widget>.generate(content.length, (int index) {
                          print("Displaying " +
                              content.length.toString() +
                              " Results...");
                          return contentEntry(
                              context,
                              results[index].contentid,
                              results[index].contenttype,
                              results[index].contentargone,
                              results[index].contentargtwo,
                              results[index].contentargthree);
                        }))
                  ]))),
                ],
              ));
        });
      });

  days.add(DayData(
      daymood: currentMood,
      daydate: date,
      daycolor: color,
      daynote: "",
      dayid: dayCounter,
      daycaption: ""));
  VibranceDatabase.instance
      .addDayDB(dayCounter, date, currentMood, color, note);
}

@override
void dispose() {}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        duration: Duration(seconds: 1),
        curve: Curves.fastOutSlowIn,
        color: backgroundcolor,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  child: Text("How are you\nfeeling?",
                      style: GoogleFonts.newsCycle(
                        color: Colors.white,
                        fontSize: 50,
                      ))),
              SizedBox(height: 10),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  child: Text(generateQuote(),
                      style: GoogleFonts.newsCycle(
                        color: Colors.white,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ))),
              SizedBox(height: 20),
              Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Card(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            leading: Icon(Icons.linear_scale),
                            title: Text("1 is lowest, 6 is highest",
                                style:
                                    GoogleFonts.newsCycle(color: Colors.black)),
                          ),
                          Text("${currentMood.toInt()}/6",
                              style: GoogleFonts.newsCycle(
                                  color: Colors.black, fontSize: 24)),
                          Slider(
                              value: currentMood,
                              min: 1,
                              max: 6,
                              divisions: 5,
                              onChanged: (double value) {
                                setState(() {
                                  switch (value) {
                                    case 1:
                                      backgroundcolor = lightMode[900];
                                      break;
                                    case 2:
                                      backgroundcolor = lightMode[700];
                                      break;
                                    case 3:
                                      backgroundcolor = lightMode[500];
                                      break;
                                    case 4:
                                      backgroundcolor = lightMode[100];
                                      break;
                                    case 5:
                                      backgroundcolor = lightMode[200];
                                      break;
                                    case 6:
                                      backgroundcolor = lightMode[400];
                                      break;
                                  }
                                  currentMood = value;
                                });
                              }),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      style: ButtonStyle(
                          minimumSize:
                              MaterialStatePropertyAll<Size>(Size(250, 50)),
                          backgroundColor: MaterialStatePropertyAll<Color>(
                              Colors.white.withOpacity(0.8)),
                          enableFeedback: true),
                      onPressed: () {
                        openResult(context);
                      },
                      child: Icon(
                        Icons.check,
                        color: Color.fromRGBO(110, 43, 113, 1),
                        size: 30,
                      ),
                    ),
                  ])
            ]));
  }
}

class ResultsPage extends StatefulWidget {
  const ResultsPage({Key? key}) : super(key: key);
  @override
  State<ResultsPage> createState() => ResultsPageState();
}

class ResultsPageState extends State<ResultsPage> {
  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return Scaffold(
          backgroundColor: color,
          appBar: AppBar(
            title: Text(sku, style: GoogleFonts.newsCycle(color: Colors.white)),
          ),
          body: SingleChildScrollView(
              child: Column(children: [
            Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.circle),
                    title: Text("Mood: ${currentMood.toInt()}/6",
                        style: GoogleFonts.newsCycle(
                            color: Colors.black, fontSize: 28)),
                  ),
                  ListTile(
                    leading: Icon(Icons.star),
                    title: Text(peptalk,
                        style: GoogleFonts.newsCycle(
                            color: Colors.grey, fontSize: 16)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 5),
            ListView.builder(
              shrinkWrap: true,
              itemCount: content.length,
              itemBuilder: (BuildContext context, int index) {
                print(content.length);
                print(results.length);
                return contentEntry(
                    context,
                    results[index].contentid,
                    results[index].contenttype,
                    results[index].contentargone,
                    results[index].contentargtwo,
                    results[index].contentargthree);
              },
            ),
          ])));
    });
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);
  @override
  State<OnboardingPage> createState() => OnboardingPageState();
}

class OnboardingPageState extends State<OnboardingPage> {
  @override
  Widget build(BuildContext context) {
    //Spotify Components

    Future spotifyData(datatype) async {
      var result;
      var searchResults = [];

      Future pickSpotifyData(item) async {
        //Dialog where we actually pick our songs or podcasts

        switch (item) {
          //Music Components
          case "Songs":
            result = await spotifyApp.me.topTracks();
            print(result.items);
            result.items?.forEach((item) => searchResults.add(ContentData(
                contentid: item.id,
                contenttype: "music",
                contentcaption: item.name,
                contentargone: item.artists,
                contentargtwo: item.name,
                contentargthree: item.uri)));
            break;
          case "Albums":
            result = await spotifyApp.me.savedAlbums().getPage(10, 0);
            print(result.items);
            result.items?.forEach((item) => searchResults.add(ContentData(
                contentid: item.id,
                contenttype: "music",
                contentcaption: item.name,
                contentargone: item.artists,
                contentargtwo: item.releaseDate,
                contentargthree: item.uri)));
            break;
          case "Artists":
            result = await spotifyApp.me.topArtists();
            print(result);

            break;

          //Podcast Components
          case "Shows":
            result = await spotifyApp.me.savedShows().getPage(10, 0);
            print(result.items);
            result.items?.forEach((item) => searchResults.add(ContentData(
                contentid: item.id,
                contenttype: "podcast",
                contentcaption: item.name,
                contentargone: item.publisher,
                contentargtwo: item.description,
                contentargthree: item.uri)));
            break;
        }

        List<Widget> spotifyItemList(BuildContext context) {
          return List<Widget>.generate(result.items.length, (int index) {
            return SimpleDialogOption(
                onPressed: () {
                  VibranceDatabase.instance.updateContentDB(
                      searchResults[index].contenttype,
                      "spotify",
                      searchResults[index].contentcaption,
                      searchResults[index].contentid);
                  Navigator.pop(context);
                },
                child: Text(searchResults[index].contentcaption,
                    style: GoogleFonts.newsCycle(
                      fontWeight: FontWeight.w600,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                    )));
          });
        }

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                title: Text('Select $item', style: dialogHeader),
                content: SingleChildScrollView(
                  child: ListBody(children: spotifyItemList(context)),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('OK', style: dialogBody),
                    onPressed: () {
                      setState(() {
                        Navigator.pop(context);
                      });
                    },
                  )
                ]);
          },
        );
      }

      switch (datatype) {
        case "music":
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  title: Text('Select Option', style: dialogHeader),
                  content: SingleChildScrollView(
                    child: ListBody(children: [
                      SimpleDialogOption(
                        onPressed: () {
                          pickSpotifyData("Songs");
                          Navigator.of(context).pop();
                        },
                        child: Text('Songs', style: dialogBody),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          pickSpotifyData("Albums");
                          Navigator.of(context).pop();
                        },
                        child: Text('Albums', style: dialogBody),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          pickSpotifyData("Artists");
                          Navigator.of(context).pop();
                        },
                        child: Text('Artists', style: dialogBody),
                      ),
                    ]),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text('OK', style: dialogBody),
                      onPressed: () {
                        setState(() {
                          Navigator.pop(context);
                        });
                      },
                    )
                  ]);
            },
          );

          break;

        case "podcasts":
          pickSpotifyData("Shows");
          break;

        default:
          break;
      }
    }

    Future podcastOnboarding() async {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text('Choose Provider', style: dialogHeader),
              content: SingleChildScrollView(
                  child: ListBody(children: <Widget>[
                SimpleDialogOption(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await invokeSpotify(context);
                    if (spotifyApp != null) {
                      spotifyData("podcasts");
                    }
                  },
                  child: Text('Spotify', style: dialogBody),
                ),
                SimpleDialogOption(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                            title: Text('Enter Podcast RSS URL',
                                style: dialogHeader),
                            content: SingleChildScrollView(
                              child: ListBody(
                                children: <Widget>[
                                  TextField(
                                      autofocus: true,
                                      keyboardType: TextInputType.multiline,
                                      minLines: 1,
                                      maxLines: 1,
                                      decoration: InputDecoration(
                                          fillColor: Colors.grey[300],
                                          filled: true,
                                          border: const OutlineInputBorder(),
                                          hintText: "Podcast RSS URL"),
                                      onChanged: (value) {
                                        setState(() {
                                          textBuffer = value;
                                        });
                                      }),
                                ],
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Cancel', style: dialogBody),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: Text('OK', style: dialogBody),
                                onPressed: () {
                                  setState(() {
                                    if (textBuffer == "") {}
                                    if (textBuffer == null) {}
                                    VibranceDatabase.instance.updateContentDB(
                                        "podcast", "rss", textBuffer, "");
                                    Navigator.pop(context);
                                  });
                                },
                              )
                            ]);
                      },
                    );
                  },
                  child: Text('RSS URL', style: dialogBody),
                ),
              ])),
              actions: <Widget>[
                TextButton(
                  child: Text('OK', style: dialogBody),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              ]);
        },
      );
    }

    Future eventOnboarding() async {
      //Because allCalendars is locked, lets make a buffer to store the data that we can touch
      allCalendars = await deviceCalendarPlugin.requestPermissions();
      allCalendars = await deviceCalendarPlugin.retrieveCalendars();
      print(allCalendars.data);
      allCalendarsBuffer = allCalendars?.data;

      //We want to grab the calendar name so that we know where to grab events from
      List<Widget> allCalendarsList(BuildContext context) {
        return List<Widget>.generate(allCalendarsBuffer.length, (int index) {
          return SimpleDialogOption(
              onPressed: () {
                VibranceDatabase.instance.updateContentDB(
                    "event", "", allCalendarsBuffer[index].name, "");
                Navigator.pop(context);
              },
              child: Text(allCalendarsBuffer[index].name,
                  style: GoogleFonts.newsCycle(
                    fontWeight: FontWeight.w600,
                    color: color.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                  )));
        });
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text('Select Calendar', style: dialogHeader),
              content: SingleChildScrollView(
                child: ListBody(children: allCalendarsList(context)),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('OK', style: dialogBody),
                  onPressed: () {
                    setState(() {
                      VibranceDatabase.instance
                          .updateContentDB("text", "", textBuffer, "");
                      Navigator.pop(context);
                    });
                  },
                )
              ]);
        },
      );
    }

    Future textOnboarding(BuildContext context) async {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text('Enter Text', style: dialogHeader),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(
                        autofocus: true,
                        keyboardType: TextInputType.multiline,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                            fillColor: Colors.grey[300],
                            filled: true,
                            border: const OutlineInputBorder(),
                            hintText: "Text"),
                        onChanged: (value) {
                          setState(() {
                            textBuffer = value;
                          });
                        }),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel', style: dialogBody),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('OK', style: dialogBody),
                  onPressed: () {
                    setState(() {
                      if (textBuffer == "") {}
                      if (textBuffer == null) {}
                      VibranceDatabase.instance
                          .updateContentDB("text", "", textBuffer, "");
                      Navigator.pop(context);
                    });
                  },
                )
              ]);
        },
      );
    }

    Future soundOnboarding(BuildContext context) async {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                    title: Text('Record Voice Note', style: dialogHeader),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          IconButton(
                              onPressed: null,
                              iconSize: 50,
                              icon: isRecording
                                  ? Icon(
                                      Icons.mic,
                                      color: Colors.red,
                                    )
                                  : Icon(
                                      Icons.mic,
                                      color: Colors.white,
                                    )),
                          TextButton(
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStatePropertyAll<Color>(
                                        Colors.white.withOpacity(0.8)),
                                enableFeedback: true),
                            onPressed: (() {
                              setState(() {
                                if (isRecording == false) {
                                  setState(() {
                                    beginRecording();
                                    isRecording = true;
                                  });
                                } else {
                                  setState(() {
                                    stopRecording();
                                    Navigator.pop(context);
                                  });
                                }
                              });
                            }),
                            child: isRecording
                                ? Text("Stop Recording")
                                : Text("Start Recording"),
                          ),
                          SizedBox(height: 10),
                          TextField(
                              decoration: InputDecoration(
                                  fillColor: Colors.grey[300],
                                  filled: true,
                                  border: const OutlineInputBorder(),
                                  hintText: "Voice Note Caption"),
                              onChanged: (value) {
                                noteBuffer = value;
                              }),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Cancel', style: dialogBody),
                        onPressed: () async {
                          await record.stop();
                          isRecording = false;
                          setState(() {
                            Navigator.pop(context);
                          });
                        },
                      )
                    ]);
              },
            );
          });
    }

    Future photoOnboarding(BuildContext context) async {
      final selectedPhotoToData;
      final XFile? selectedPhoto =
          await photo.pickImage(source: ImageSource.gallery);
      print(selectedPhoto.toString());
      if (selectedPhoto != null) {
        selectedPhotoToData = await selectedPhoto.readAsBytes();
        VibranceDatabase.instance
            .updateContentDB("photo", "", "", selectedPhotoToData);
      }
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(sku, style: GoogleFonts.newsCycle(color: Colors.white)),
        ),
        body: Column(children: [
          Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.sunny),
                  title: Text('What makes you happy?',
                      style: GoogleFonts.newsCycle(color: Colors.black)),
                  subtitle: Text("Add content to inpire you to be your best.",
                      style: GoogleFonts.newsCycle(color: Colors.grey)),
                ),
              ],
            ),
          ),
          Card(
            color: Colors.pink,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.music_note),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                            title: Text('Choose Provider', style: dialogHeader),
                            content: SingleChildScrollView(
                                child: ListBody(children: <Widget>[
                              SimpleDialogOption(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  invokeSpotify(context);
                                  if (spotifyApp != null) {
                                    spotifyData("music");
                                  }
                                },
                                child: Text('Spotify', style: dialogBody),
                              ),
                            ])),
                            actions: <Widget>[
                              TextButton(
                                child: Text('OK', style: dialogBody),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              )
                            ]);
                      },
                    );
                  },
                  title: Text('Music',
                      style: GoogleFonts.newsCycle(
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white)),
                  subtitle: Text("Songs to give you a jolt of energy.",
                      style: GoogleFonts.newsCycle(
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white)),
                ),
              ],
            ),
          ),
          Card(
            color: Colors.purple,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.podcasts),
                  onTap: () {
                    podcastOnboarding();
                  },
                  title: Text('Podcasts',
                      style: GoogleFonts.newsCycle(
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white)),
                  subtitle: Text("Podcasts to give you insight.",
                      style: GoogleFonts.newsCycle(
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white)),
                ),
              ],
            ),
          ),
          Card(
            color: Colors.yellow,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.calendar_month),
                  onTap: () {
                    eventOnboarding();
                  },
                  title: Text('Calendar Events',
                      style: GoogleFonts.newsCycle(color: Colors.black)),
                  subtitle: Text("Events to look forward to.",
                      style: GoogleFonts.newsCycle(color: Colors.black)),
                ),
              ],
            ),
          ),
          Card(
            color: Colors.blue,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.photo),
                  onTap: () {
                    photoOnboarding(context);
                  },
                  title: Text('Photos',
                      style: GoogleFonts.newsCycle(
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white)),
                  subtitle: Text("Photos to help you reminance.",
                      style: GoogleFonts.newsCycle(
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white)),
                ),
              ],
            ),
          ),
          Card(
            color: Colors.green,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.record_voice_over_rounded),
                  onTap: () {
                    soundOnboarding(context);
                  },
                  title: Text('Voice Notes',
                      style: GoogleFonts.newsCycle(
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white)),
                  subtitle: Text("Voice Notes to motivate you forward.",
                      style: GoogleFonts.newsCycle(
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white)),
                ),
              ],
            ),
          ),
          Card(
            color: Colors.orange,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.note),
                  onTap: () {
                    textOnboarding(context);
                  },
                  title: Text('Text Notes',
                      style: GoogleFonts.newsCycle(
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white)),
                  subtitle: Text("Text Notes to refect on.",
                      style: GoogleFonts.newsCycle(
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white)),
                ),
              ],
            ),
          ),
        ]));
  }
}

class JournalPage extends StatefulWidget {
  const JournalPage({Key? key}) : super(key: key);
  @override
  State<JournalPage> createState() => JournalPageState();
}

class JournalPageState extends State<JournalPage> {
  @override
  Widget build(BuildContext context) {
    setState(() {
      entrywidth = MediaQuery.of(context).size.width - 10;
    });
    void deleteLastEntry() {
      if (dayCounter > 0) {
        days.removeLast();
        setState(() {
          journal.removeLast();
        });
        VibranceDatabase.instance.deleteDayDB(dayCounter);
        dayCounter--;
      }
    }

    Widget actionMenu() => PopupMenuButton<int>(
          icon: Icon(Icons.more_horiz),
          tooltip: "Journal Options",
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 5,
              onTap: deleteLastEntry,
              child: Text(
                "Delete Last Entry",
                style: GoogleFonts.newsCycle(
                    fontWeight: FontWeight.w700, color: Colors.red),
              ),
            ),
          ],
        );

    return SingleChildScrollView(
        child: Column(children: [
      Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.bookmark),
              trailing: actionMenu(),
              title: Text("Journal",
                  style: GoogleFonts.newsCycle(color: Colors.black)),
              subtitle: Text(DateTime.now().toString().substring(0, 10),
                  style: GoogleFonts.newsCycle(color: Colors.grey)),
            ),
          ],
        ),
      ),
      SizedBox(height: 5),
      Wrap(direction: Axis.horizontal, children: makeJournalEntry(context)),
    ]));
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);
  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Column(children: [
      Card(
        color: Colors.purple[50],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.info),
              title:
                  Text(sku, style: GoogleFonts.newsCycle(color: Colors.black)),
              subtitle: Text("Version $version, ($release)",
                  style: GoogleFonts.newsCycle(color: Colors.grey)),
            ),
          ],
        ),
      ),
      Card(
          color: Colors.purple[50],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.person),
                title: Text("With 💖 by Kevin George",
                    style: GoogleFonts.newsCycle(color: Colors.black)),
                subtitle: Text("http://kgeok.github.io/",
                    style: GoogleFonts.newsCycle(color: Colors.grey)),
                onTap: () => redirectURL("https://kgeok.github.io"),
              ),
            ],
          )),
      Card(
          child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.group),
            title: Text("Acknowledgements",
                style: GoogleFonts.newsCycle(color: Colors.black)),
            onTap: () => showLicensePage(
                context: context,
                useRootNavigator: false,
                applicationName: sku,
                applicationVersion: version,
                applicationLegalese: "Kevin George"),
          ),
          ListTile(
            leading: Icon(Icons.phone_callback),
            title: Text("Additional Resources",
                style: GoogleFonts.newsCycle(color: Colors.black)),
            onTap: () => resourcesDialog(context),
          ),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text("Privacy Policy",
                style: GoogleFonts.newsCycle(color: Colors.black)),
            onTap: () => redirectURL(
                "https://github.com/kgeok/Vibrance/blob/main/PrivacyPolicy.pdf"),
          ),
          ListTile(
            leading: Icon(Icons.start),
            title: Text("Quick Start",
                style: GoogleFonts.newsCycle(color: Colors.black)),
            onTap: () => helpDialog(context),
          ),
          ListTile(
            leading: Icon(Icons.add),
            title: Text("Add Content",
                style: GoogleFonts.newsCycle(color: Colors.black)),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const OnboardingPage())),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever),
            title: Text("Clear Content",
                style: GoogleFonts.newsCycle(color: Colors.red)),
            onTap: () => clearContentWarning(context),
          ),
          ListTile(
            leading: Icon(Icons.restore_page),
            title: Text("Reset Journal",
                style: GoogleFonts.newsCycle(color: Colors.red)),
            onTap: () => clearDaysWarning(context),
          ),
          ListTile(
            leading: Icon(Icons.supervised_user_circle_sharp),
            title: Text("Log Out of All Services",
                style: GoogleFonts.newsCycle(color: Colors.red)),
            onTap: () => clearServicesWarning(context),
          ),
          ListTile(
            leading: Icon(Icons.settings_applications),
            title: Text("Test Button",
                style: GoogleFonts.newsCycle(color: Colors.yellow[900])),
            onTap: () => invokeSpotify(context),
          ),
        ],
      )),
    ]));
  }
}
