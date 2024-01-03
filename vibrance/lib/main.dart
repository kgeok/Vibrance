// ignore_for_file: avoid_print, use_build_context_synchronously, prefer_typing_uninitialized_variables,  prefer_const_constructors, unused_import, prefer_interpolation_to_compose_strings, unused_local_variable
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
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
import 'package:fl_chart/fl_chart.dart';

void main() async {
  runApp(const MaterialApp(home: MainPage()));
  VibranceDatabase.instance.initStatefromDB();
  populateFromState();
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
const version = "1.0";
const release = "Pre-Release, Concept B";
const spotifycid = "677ce23bfdfd449e95956abadaded7a9";
const spotifysid = "449148ca0aa44a9e8d0dff16b517c7de";
double currentMood = 1;
var currentTheme; //Light or Dark theme
int onboarding = 0;
var days = [];
var results = [];
var services = [];
List<int> journal = [];
List<int> memories = [];
DateTime currentDate = DateTime.now();
var spotifyApp;
final record = AudioRecorder();
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
Color defaultcolor = Color(0xFF752983);
var backgroundcolor;
var buttoncolor = Color(0xFF65496A);
bool enabled = true;

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class DayData {
  int dayid = 0;
  late var daydate;
  late var daymood;
  late String daynote = "";
  late String daytextone = "";
  late Color daycolorone = Color(0xFF000000);
  late Color daycolortwo = Color(0xFF000000);
  late Color daycolorthree = Color(0xFF000000);
  late Color daycolorfour = Color(0xFF000000);
  late Color daycolorfive = Color(0xFF000000);
  late Color daycolorsix = Color(0xFF000000);

  DayData({
    required this.dayid,
    required this.daydate,
    required this.daymood,
    required this.daynote,
    required this.daytextone,
    required this.daycolorone,
    required this.daycolortwo,
    required this.daycolorthree,
    required this.daycolorfour,
    required this.daycolorfive,
    required this.daycolorsix,
  });
}

class MemoriesData {
//We're going to be using this as a foundation to structure our content data
//Memory arguements for any special data that the content has
  var memoriesid;
  late var memoriestype;
  late var memoriessubtype;
  late var memoriesprovider;
  late var memoriesdate;
  late var memoriestextone;
  late var memoriestexttwo;
  late var memoriesargone;
  late var memoriesargtwo;
  late var memoriesargthree;
  late var memoriesargfour;
  late var memoriesweight;

  MemoriesData(
      {this.memoriesid,
      required this.memoriestype,
      required this.memoriessubtype,
      required this.memoriesprovider,
      this.memoriesdate,
      this.memoriestextone,
      this.memoriestexttwo,
      this.memoriesargone,
      this.memoriesargtwo,
      this.memoriesargthree,
      this.memoriesargfour,
      this.memoriesweight});
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

const memoriesColors = {
  //Organizing this way in case we want to make updates to the future
  "Music": 0xFFE91E63,
  "Podcasts": 0xFF9C27B0,
  "Podcast": 0xFF9C27B0,
  "Photos": 0xFF2196F3,
  "Photo": 0xFF2196F3,
  "Events": 0xFFFFEB3B,
  "Event": 0xFFFFEB3B,
  "Voice": 0xFF4CAF50,
  "Text": 0xFFFF9800,
  "Tips": 0xFF8C8C8C,
  "Default": 0xFF000000
};

Color darkenColor(Color color) {
  final darkvariant = HSLColor.fromColor(color).withLightness(
      (HSLColor.fromColor(color).lightness - .3).clamp(0.0, 1.0));
  return darkvariant.toColor();
}

Future redirectURL(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    print("Unable to Launch URL");
  }
}

//Audio Recording Components

Future beginRecording(BuildContext context) async {
  final root = await getDatabasesPath();
  try {
    if (await record.hasPermission()) {
      await record.start(const RecordConfig(), path: root + "/recording.m4a");
      isRecording = await record.isRecording();
      // print("Recording: $isRecording");
      // print(root);
    }
  } catch (e) {
    record.stop();
    isRecording = false;
    Navigator.of(context).pop();
    //print(e);
    simpleDialog(context, "Unable to Start/Save Recording", "Error: $e",
        "Check your Settings and try again", "error");
  }
}

Future stopRecording() async {
  final selectedAudiotoData;
  String? path = await record.stop();
  print(path);
  if (path != null) {
    final XFile selectedAudio = XFile(path);
    //Disposing for when we are done to clear device space
    File fileBuffer = File(path);
    selectedAudiotoData = await selectedAudio.readAsBytes();
    if (noteBuffer == "") {
      noteBuffer = DateTime.now().toString().substring(0, 10) + " Recording";
    }
    noteBuffer ??= DateTime.now().toString().substring(0, 10) + " Recording";
    VibranceDatabase.instance.updateMemoriesDB("Voice", "Audio", "System",
        noteBuffer, "", selectedAudiotoData, "", "");
    fileBuffer.delete();
    noteBuffer = "";
  }
  isRecording = await record.isRecording();
  isRecording = false;
  //record.dispose();
}

void openAudioPlayer(BuildContext context, argone, textone) async {
  final audioplayer = AudioPlayer();
  final root = await getDatabasesPath();
  //We know this file variable won't be used but we need an excuse for the file to be generated
  var file = File(root + "/recording.m4a").writeAsBytes(argone);
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
                Text(textone, style: dialogBody),
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

Future addMemories() async {
  //Adding this here because of some weird IDE issue...
  memories.add(0);
}

Future authenticateSpotify(BuildContext context) async {
  //This is the provider for logging into Spotify
  var responseUri;
  final credentials = spotify.SpotifyApiCredentials(spotifycid, spotifysid);
  final grant = spotify.SpotifyApi.authorizationCodeGrant(credentials);
  const redirectUri = "https://kgeok.github.io/Vibrance/Spotify/";
  final scopes = [
    'user-read-email',
    'user-library-read',
    'user-top-read',
    'user-read-private',
    'user-read-recently-played',
  ];
  final authUri =
      grant.getAuthorizationUrl(Uri.parse(redirectUri), scopes: scopes);

  var controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) async {
          if (request.url.startsWith(redirectUri)) {
            responseUri = request.url;
            // print("Got: $responseUri");
            spotifyApp =
                spotify.SpotifyApi.fromAuthCodeGrant(grant, responseUri);
            var credentials = await spotifyApp.getCredentials();
            VibranceDatabase.instance.addService(
                1,
                "Spotify",
                credentials.accessToken,
                credentials.refreshToken,
                credentials.scopes,
                credentials.expiration,
                "");
          }
          return NavigationDecision.navigate;
        },
      ),
    )
    ..loadRequest(Uri.parse(authUri.toString()));

  showModalBottomSheet(
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
                        size: 30,
                      )),
                  Expanded(child: WebViewWidget(controller: controller)),
                ]));
      });
}

//Podcast Components

Future probeLatestPodcastRSS(String url, albumart) async {
  try {
    //We need to clean up the url for the check to work properly
    String cleanurl = (url.replaceAll(RegExp("http://|https://|rss://"), ""));
    final connection = await InternetAddress.lookup(
        cleanurl.substring(0, cleanurl.indexOf('/')));
    if (connection.isNotEmpty && connection[0].rawAddress.isNotEmpty) {
      // print('Connected to $url');

      var rssfeed = await client.get(Uri.parse(url));
      var content = RssFeed.parse(rssfeed.body);
      // print(content.title);
      RssItem latestitem = content.items!.first;
      // print(latestitem.title);
      // print(latestitem.pubDate);
      // print(albumart);

      results.add(MemoriesData(
          memoriesid: 0,
          memoriestextone: (content.title).toString(),
          memoriestexttwo: (content.author).toString(),
          memoriestype: "Podcast",
          memoriessubtype: "Episode",
          memoriesprovider: "RSS",
          memoriesargone: (latestitem.title).toString(),
          memoriesargtwo: (latestitem.pubDate).toString(),
          memoriesargthree: (latestitem.link).toString(),
          memoriesargfour: albumart));

      addMemories();
    }
  } on SocketException catch (_) {
    print('Not Connected to $url');
  }
}

Future probeLatestTip() async {
  Random random = Random();
  int randomBuffer = random.nextInt(tips.length);
  results.add(MemoriesData(
      memoriesid: 0,
      memoriestextone: tips.values.elementAt(randomBuffer),
      memoriestexttwo: "",
      memoriestype: "Tips",
      memoriessubtype: "Wellness",
      memoriesprovider: "System",
      memoriesargone: tips.keys.elementAt(randomBuffer),
      memoriesargtwo: "",
      memoriesargthree: "",
      memoriesargfour: ""));

  addMemories();
}

Future probeTopTrackSpotify() async {
  try {
    final connection = await InternetAddress.lookup('accounts.spotify.com');
    if (connection.isNotEmpty && connection[0].rawAddress.isNotEmpty) {
      print('Connected to Spotify');
      if (spotifyApp != null) {
        var result;
        result = await spotifyApp.me.topTracks().first();
        results.add(MemoriesData(
            memoriesid: 0,
            memoriestextone: result.items?.first.name,
            memoriestexttwo: result.items?.first.artists[0].name,
            memoriestype: "Music",
            memoriessubtype: "Track",
            memoriesprovider: "Spotify",
            memoriesargone: result.items?.first.id,
            memoriesargtwo:
                await getAlbumArt("Spotify", result.items?.first.id, "Track"),
            memoriesargthree: result.items?.first.uri,
            memoriesargfour: ""));

        addMemories();
      }
    }
  } on SocketException catch (_) {
    print('Not Connected to Spotify');
  }
}

Future probeLatestPodcastSpotify(String id, albumart) async {
  try {
    final connection = await InternetAddress.lookup('accounts.spotify.com');
    if (connection.isNotEmpty && connection[0].rawAddress.isNotEmpty) {
      print('Connected to Spotify');
      if (spotifyApp != null) {
        //Because Show title isn't coming from the episode we will take it out seperately
        var show = await spotifyApp.shows.get(id);
        var episode = spotifyApp.shows.episodes(id);
        var latestitem = (await episode.first()).items!.first;
        results.add(MemoriesData(
            memoriesid: 0,
            memoriestextone: (show.name).toString(),
            memoriestexttwo: (show.publisher).toString(),
            memoriestype: "Podcast",
            memoriessubtype: "Episode",
            memoriesprovider: "Spotify",
            memoriesargone: (latestitem.name).toString(),
            memoriesargtwo: (latestitem.releaseDate).toString(),
            memoriesargthree: id,
            memoriesargfour: albumart));
        memories.add(0);
      }
    }
  } on SocketException catch (_) {
    print('Not Connected to Spotify');
  }
}

Future getAlbumArt(String provider, String id, String type) async {
//Use this function to get artwork for services
  var result;
  print("Getting Album Art");
  switch (provider) {
    case ("Spotify"):
      switch (type) {
        case ("Album"):
          var album = await spotifyApp.albums.get(id);
          var albumArt = album.images[0];
          var albumarttoData = await http.readBytes(Uri.parse(albumArt.url));
          return albumarttoData;

        case ("Track"):
          var track = await spotifyApp.tracks.get(id);
          var albumArt = track.album.images[0];
          var albumarttoData = await http.readBytes(Uri.parse(albumArt.url));
          return albumarttoData;

        case ("Show"):
          var show = await spotifyApp.shows.get(id);
          var albumArt = show.images[0];
          var albumarttoData = await http.readBytes(Uri.parse(albumArt.url));
          return albumarttoData;
      }
    case ("RSS"):
      var rssfeed = await client.get(Uri.parse(id));
      var content = RssFeed.parse(rssfeed.body);
      var contenturl = content.image?.url ?? "";
      var albumarttoData = await http.readBytes(Uri.parse(contenturl));
      return albumarttoData;

    default:
      break;
  }
}

//Events Components

Future probeLatestEvents(String name) async {
  try {
    //We have to use this function to pull the events out of the given calendar
    final startDate = DateTime.now().add(const Duration(days: -1));
    final endDate = DateTime.now().add(const Duration(days: 2));
    var eventparams =
        RetrieveEventsParams(startDate: startDate, endDate: endDate);
    //Because allCalendars is locked, lets make a buffer to store the data that we can touch
    allCalendars = await deviceCalendarPlugin.requestPermissions();
    allCalendars = await deviceCalendarPlugin.retrieveCalendars();
    allCalendarsBuffer = allCalendars?.data;

    //Since it's not so easy to just pull the Memoriess using IndexOf or something else, we have to just traverse the array and match it to the given calendar
    for (int i = 0; i < (allCalendarsBuffer.length); i++) {
      if (allCalendarsBuffer[i].name == name) {
        var events = await deviceCalendarPlugin.retrieveEvents(
            allCalendarsBuffer[i].id, eventparams);
        var eventsBuffer = events.data;

        if (eventsBuffer != null) {
          for (int i = 0; i < eventsBuffer.length; i++) {
            //We're only going to poll three events
            // print(eventsBuffer[i].title);
            // print(eventsBuffer[i].start);

            results.add(MemoriesData(
                memoriesid: i,
                memoriestype: "Event",
                memoriessubtype: "Event",
                memoriesprovider: "System",
                memoriestextone: (eventsBuffer[i].title).toString(),
                memoriestexttwo: (eventsBuffer[i].start).toString(),
                memoriesargone: name));
            memories.add(i);
          }
        }
      }
    }
  } catch (e) {
    print("An Error occurred getting Calendar events.");
  }
}

void populateFromState() async {
  await Future.delayed(const Duration(
      milliseconds:
          1500)); //It apparently takes 1 second or so for DB to populate State

  int counterBuffer =
      dayCounter; //I need to freeze the state of the counter so that it doesn't keep iterating on append
  for (int i = 0; i < counterBuffer; i++) {
    currentMood = days[i].daymood;
    date = days[i].daydate;

    journal.add(i - 1);
    print("Restored Entry: ${i + 1}");
  }
  date = currentDate.toString().substring(0, 10);
  currentMood = 1;
}

//Memory Entry Components

Widget memoriesEntry(
    BuildContext context,
    int id,
    String textone,
    String texttwo,
    String type,
    String subtype,
    String provider,
    var argone,
    var argtwo,
    var argthree,
    var argfour) {
  double cardwidth() {
    if (MediaQuery.of(context).size.width < 500) {
      return (MediaQuery.of(context).size.width / 2) - 10;
    } else {
      return 200;
    }
  }

  double cardheight() {
    if (MediaQuery.of(context).size.height < 500) {
      return (MediaQuery.of(context).size.height / 2) - 30;
    } else {
      return 180;
    }
  }

  switch (type) {
    case "Music":
      var typecolor = Color(int.parse(memoriesColors[type].toString()));

      return InkWell(
          splashColor: typecolor,
          highlightColor: typecolor,
          onTap: () {
            memoriesDialog(context, type, textone, texttwo, subtype, provider,
                argone, argtwo, argthree);
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
                      color: typecolor,
                      image: DecorationImage(
                          colorFilter:
                              ColorFilter.mode(Colors.pink, BlendMode.modulate),
                          image: MemoryImage(argtwo),
                          fit: BoxFit.cover),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  height: cardheight(),
                  width: cardwidth(),
                  child: Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                        Text(textone,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                            style: GoogleFonts.newsCycle(
                                color: typecolor.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 18)),
                        Text(texttwo,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                            style: GoogleFonts.newsCycle(
                                fontWeight: FontWeight.w500,
                                color: typecolor.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 14)),
                      ])))));

    case "Podcast":
      var typecolor = Color(int.parse(memoriesColors[type].toString()));
      return InkWell(
          splashColor: typecolor,
          highlightColor: typecolor,
          onTap: () {
            memoriesDialog(context, type, textone, texttwo, subtype, provider,
                argone, argtwo, argthree);
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
                      color: typecolor,
                      image: DecorationImage(
                          colorFilter: ColorFilter.mode(
                              Colors.purple, BlendMode.modulate),
                          image: MemoryImage(argfour),
                          fit: BoxFit.cover),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  height: cardheight(),
                  width: cardwidth(),
                  child: Center(
                      child: Padding(
                          padding: EdgeInsetsDirectional.all(5),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(textone,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    maxLines: 1,
                                    style: GoogleFonts.newsCycle(
                                        color:
                                            typecolor.computeLuminance() > 0.5
                                                ? Colors.black
                                                : Colors.white,
                                        fontSize: 18)),
                                Text(texttwo,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.newsCycle(
                                        fontWeight: FontWeight.w500,
                                        color:
                                            typecolor.computeLuminance() > 0.5
                                                ? Colors.black
                                                : Colors.white,
                                        fontSize: 14))
                              ]))))));

    case "Event":
      var typecolor = Color(int.parse(memoriesColors[type].toString()));
      return InkWell(
          splashColor: typecolor,
          highlightColor: typecolor,
          onTap: () {
            memoriesDialog(context, type, textone, texttwo, subtype, provider,
                argone, argtwo, argthree);
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
                      color: typecolor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  height: cardheight(),
                  width: cardwidth(),
                  child: Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                        Text(textone.toString(),
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                            style: GoogleFonts.newsCycle(
                                color: typecolor.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 16)),
                        Text(argone.toString().substring(0, 16),
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                            style: GoogleFonts.newsCycle(
                                fontWeight: FontWeight.w500,
                                color: typecolor.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 20))
                      ])))));

    case "Photo":
      var typecolor = Color(int.parse(memoriesColors[type].toString()));
      return InkWell(
          splashColor: typecolor,
          highlightColor: typecolor,
          onTap: () {
            memoriesDialog(context, type, textone, texttwo, subtype, provider,
                argone, argtwo, argthree);
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
                    color: typecolor,
                    image: DecorationImage(
                        image: MemoryImage(argone), fit: BoxFit.cover),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30))),
                height: cardheight(),
                width: cardwidth(),
              )));

    case "Voice":
      var typecolor = Color(int.parse(memoriesColors[type].toString()));
      return InkWell(
          splashColor: typecolor,
          highlightColor: typecolor,
          onTap: () {
            memoriesDialog(context, type, textone, texttwo, subtype, provider,
                argone, argtwo, argthree);
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
                      color: typecolor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  height: cardheight(),
                  width: cardwidth(),
                  child: Center(
                      child: Padding(
                          padding: EdgeInsetsDirectional.all(5),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(textone,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    maxLines: 1,
                                    style: GoogleFonts.newsCycle(
                                        color:
                                            typecolor.computeLuminance() > 0.5
                                                ? Colors.black
                                                : Colors.white,
                                        fontSize: 20)),
                                Text("Voice Note",
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    maxLines: 1,
                                    style: GoogleFonts.newsCycle(
                                        fontWeight: FontWeight.w500,
                                        color:
                                            typecolor.computeLuminance() > 0.5
                                                ? Colors.black
                                                : Colors.white,
                                        fontSize: 14))
                              ]))))));

    case "Text":
      var typecolor = Color(int.parse(memoriesColors[type].toString()));
      return InkWell(
          splashColor: typecolor,
          highlightColor: typecolor,
          onTap: () {
            memoriesDialog(context, type, textone, texttwo, subtype, provider,
                argone, argtwo, argthree);
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
                      color: typecolor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  height: cardheight(),
                  width: cardwidth(),
                  child: Center(
                      child: Padding(
                          padding: EdgeInsetsDirectional.all(5),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(textone,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    maxLines: 1,
                                    style: GoogleFonts.newsCycle(
                                        color:
                                            typecolor.computeLuminance() > 0.5
                                                ? Colors.black
                                                : Colors.white,
                                        fontSize: 22)),
                              ]))))));

    case "Tips":
      var typecolor = Color(int.parse(memoriesColors[type].toString()));
      return InkWell(
          splashColor: typecolor,
          highlightColor: typecolor,
          onTap: () {
            memoriesDialog(context, type, textone, texttwo, subtype, provider,
                argone, argtwo, argthree);
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
                      color: typecolor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  height: cardheight(),
                  width: cardwidth(),
                  child: Center(
                      child: Padding(
                          padding: EdgeInsetsDirectional.all(5),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(textone,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    maxLines: 1,
                                    style: GoogleFonts.newsCycle(
                                        color:
                                            typecolor.computeLuminance() > 0.5
                                                ? Colors.black
                                                : Colors.white,
                                        fontSize: 22)),
                              ]))))));

    default:
      var typecolor = Color(int.parse(memoriesColors["Default"].toString()));
      return InkWell(
          splashColor: typecolor,
          highlightColor: typecolor,
          onTap: () {},
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
                      color: typecolor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  height: cardheight(),
                  width: (MediaQuery.of(context).size.width) - 10,
                  child: Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                        Text("No Memories Available.",
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                            style: GoogleFonts.newsCycle(
                                color: typecolor.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 16)),
                        Text("Go to Settings to add Memories.",
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                            style: GoogleFonts.newsCycle(
                                fontWeight: FontWeight.w500,
                                color: typecolor.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 14))
                      ])))));
  }
}

void memoriesDialog(
    BuildContext context,
    String type,
    String textone,
    String texttwo,
    String subtype,
    String provider,
    var argone,
    var argtwo,
    var argthree) {
  switch (type) {
    case "Music":
      var typecolor = Color(int.parse(memoriesColors[type].toString()));
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              backgroundColor: Colors.pink,
              title: Text(textone, style: dialogHeader),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(texttwo, style: dialogBody),
                    Text(subtype, style: dialogBody),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Open', style: dialogBody),
                  onPressed: () {
                    Navigator.of(context).pop();
                    switch (provider) {
                      case "Spotify":
                        switch (subtype) {
                          case "Album":
                            redirectURL(
                                "https://open.spotify.com/album/" + argone);
                            break;
                          case "Track":
                            redirectURL(
                                "https://open.spotify.com/track/" + argone);
                            break;
                        }

                        break;
                      default:
                        break;
                    }
                  },
                ),
                TextButton(
                  child: Text('OK', style: dialogBody),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ]);
        },
      );

    case "Podcast":
      var typecolor = Color(int.parse(memoriesColors[type].toString()));
      switch (subtype) {
        case "Show":
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  backgroundColor: Colors.purple,
                  title: Text(textone, style: dialogHeader),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: <Widget>[
                        Text(texttwo, style: dialogBody),
                        Text("Podcast", style: dialogBody),
                        Text("", style: dialogBody),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text('Open', style: dialogBody),
                      onPressed: () {
                        Navigator.of(context).pop();
                        switch (provider) {
                          case "Spotify":
                            switch (subtype) {
                              case "Show":
                                redirectURL(
                                    "https://open.spotify.com/show/" + argone);
                                break;
                            }
                          case "RSS":
                            redirectURL(argthree);
                            break;

                          default:
                            break;
                        }
                      },
                    ),
                    TextButton(
                      child: Text('OK', style: dialogBody),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    )
                  ]);
            },
          );
          break;

        case "Episode":
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  backgroundColor: Colors.purple,
                  title: Text(textone, style: dialogHeader),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: <Widget>[
                        Text(argone, style: dialogBody),
                        Text("", style: dialogBody),
                        Text(argtwo, style: dialogBody),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text('Open', style: dialogBody),
                      onPressed: () {
                        Navigator.of(context).pop();
                        switch (provider) {
                          case "Spotify":
                            switch (subtype) {
                              case "Episode":
                                redirectURL("https://open.spotify.com/show/" +
                                    argthree);
                                break;
                            }
                          case "RSS":
                            redirectURL(argthree);
                            break;

                          default:
                            break;
                        }
                      },
                    ),
                    TextButton(
                      child: Text('OK', style: dialogBody),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    )
                  ]);
            },
          );
          break;
      }

    case "Event":
      var typecolor = Color(int.parse(memoriesColors[type].toString()));
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              backgroundColor: Colors.yellow,
              title: Text(textone,
                  style: GoogleFonts.newsCycle(
                      fontWeight: FontWeight.w700, color: Colors.black)),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text("", style: dialogBody),
                    Text(argone,
                        style: GoogleFonts.newsCycle(
                            fontWeight: FontWeight.w600, color: Colors.black)),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('OK',
                      style: GoogleFonts.newsCycle(
                          fontWeight: FontWeight.w600, color: Colors.black)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ]);
        },
      );
    case "Photo":
      var typecolor = Color(int.parse(memoriesColors[type].toString()));
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.blue,
              content: Container(
                  height: 400,
                  width: (MediaQuery.of(context).size.width) - 10,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: MemoryImage(argone), fit: BoxFit.contain))),
            );
          });
    case "Voice":
      var typecolor = Color(int.parse(memoriesColors[type].toString()));
      openAudioPlayer(context, argone, argtwo);
      break;
    case "Text":
      var typecolor = Color(int.parse(memoriesColors[type].toString()));
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              backgroundColor: Colors.orange,
              title: Text("Text Note", style: dialogHeader),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(textone, style: dialogBody),
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

    case "Tips":
      var typecolor = Color(int.parse(memoriesColors[type].toString()));
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              backgroundColor: Colors.grey,
              title: Text("Tips", style: dialogHeader),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(textone, style: dialogBody),
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

    default:
      var typecolor = Color(int.parse(memoriesColors["Default"].toString()));
      Navigator.of(context).pop();
      MaterialPageRoute(builder: (context) => const OnboardingPage());
      break;
  }
}

String peptalk(int vibe) {
  switch (vibe) {
    case 1:
      return "Let's get back on track.";
    case 2:
      return "We can do this.";
    case 3:
      return "Just a little push forward.";
    case 4:
      return "We can do this.";
    case 5:
      return "We're just about there.";
    case 6:
      return "This is the best yet.";
    default:
      return "This one is a good one.";
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

Future manageMemories(BuildContext context) async {
  await pullAllMemoriesData();
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          title: Text("Manage Memories", style: dialogHeader),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                SingleChildScrollView(
                    child: ListBody(
                        children:
                            List<Widget>.generate(memories.length, (int index) {
                  return SimpleDialogOption(
                      onPressed: () {
                        memoriesDialog(
                            context,
                            results[index].memoriestype,
                            results[index].memoriestextone,
                            results[index].memoriestexttwo,
                            results[index].memoriessubtype,
                            results[index].memoriesprovider,
                            results[index].memoriesargone,
                            results[index].memoriesargtwo,
                            results[index].memoriesargthree);
                      },
                      child: Text(
                          (results[index].memoriestype) +
                              ", Added: " +
                              results[index].memoriesdate,
                          style: dialogBody));
                })))
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Delete All', style: dialogBody),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                        backgroundColor: Colors.orange[800],
                        title: Text("Clear Memories?", style: dialogHeader),
                        content: SingleChildScrollView(
                          child: ListBody(
                            children: <Widget>[
                              Text("Are you sure you want to clear Memories?",
                                  style: dialogBody),
                              Text("(This action cannot be reversed)",
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
                              VibranceDatabase.instance.clearMemoriesDB();
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                            },
                          )
                        ]);
                  },
                );
              },
            ),
            TextButton(
              child: Text('OK', style: dialogBody),
              onPressed: () {
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
          title: Text("Sign Out?", style: dialogHeader),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Are you sure you want to sign out of all Providers?",
                    style: dialogBody),
                Text("(You will need to sign back in later.)",
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
          500)); //It apparently takes 1 second or so for DB to populate State

  if (onboarding == 1) {
    showModalBottomSheet(
        context: context,
        enableDrag: true,
        backgroundColor: lightMode,
        isScrollControlled: true,
        useRootNavigator: true,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Wrap(children: [
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                        child: Text("Welcome to $sku",
                            style: GoogleFonts.newsCycle(
                              color: Colors.white,
                              fontSize: 25,
                            ))),
                    SizedBox(height: 15),
                    Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                        child: Text(
                            "This is $sku, a way to push you forward with your own Memories.",
                            style: GoogleFonts.newsCycle(
                              color: Colors.white,
                              fontSize: 16,
                            ))),
                    SizedBox(height: 15),
                    Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                        child: Text(
                            "Inspire yourself with the help of your Music, Photos, Podcasts, Voice and more.",
                            style: GoogleFonts.newsCycle(
                              color: Colors.white,
                              fontSize: 16,
                            ))),
                    SizedBox(height: 15),
                    Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                        child: Text(
                            "Keep track of how you were feeling with the Journal",
                            style: GoogleFonts.newsCycle(
                              color: Colors.white,
                              fontSize: 16,
                            ))),
                    SizedBox(height: 15),
                    Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                        child:
                            Text("All on Device and not stored in the cloud.",
                                style: GoogleFonts.newsCycle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ))),
                    SizedBox(height: 15),
                    Center(
                        child: SingleChildScrollView(
                            child: Column(children: [
                      const SizedBox(height: 30),
                      TextButton(
                        style: ButtonStyle(
                            minimumSize:
                                MaterialStatePropertyAll<Size>(Size(250, 50)),
                            backgroundColor:
                                MaterialStatePropertyAll<Color>(darkMode),
                            enableFeedback: true),
                        onPressed: () {
                          Navigator.of(context).pop();
                          helpDialog(context);
                        },
                        child: Text("Quick Start",
                            style: GoogleFonts.newsCycle(
                                color: Colors.white, fontSize: 16)),
                      ),
                      const SizedBox(height: 50),
                    ])))
                  ])
            ]);
          });
        });

    print("Onboarding...");
  } else {
    print("No Onboarding...");
  }
}

class MyAppState extends State<MainPage> {
  var pages = <Widget>[HomePage(), JournalPage(), SettingsPage()];
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
  try {
    final connection = await InternetAddress.lookup('accounts.spotify.com');
    if (connection.isNotEmpty && connection[0].rawAddress.isNotEmpty) {
      print('Connected to Spotify');
      //Let's grab the Services data from the DB and put it into our ServiceData object based List
      await VibranceDatabase.instance.provideServiceData();
      //Let's find out which item in the list is the Spotify Cred Data...

      var spotifyindex =
          services.indexWhere((item) => (item.servicename) == "Spotify");
      //If the result is not empty, which is considered a -1 index result, we can move forward
      if (spotifyindex != -1) {
        spotifyApp = spotify.SpotifyApi(
            spotify.SpotifyApiCredentials(spotifycid, spotifysid,
                accessToken: services[spotifyindex].dataone,
                refreshToken: services[spotifyindex].datatwo,
                scopes: [
                  'user-read-email',
                  'user-library-read',
                  'user-top-read',
                  'user-read-private',
                  'user-read-recently-played'
                ],
                expiration: DateTime.parse(services[spotifyindex].datafour)),
            onCredentialsRefreshed:
                (spotify.SpotifyApiCredentials newCred) async {
          print("Refreshing Spotify OAuth Data...");
          services.removeWhere((item) => (item.servicename) == "Spotify");
          VibranceDatabase.instance.removeService("Spotify");
          await VibranceDatabase.instance.addService(
              1,
              "Spotify",
              newCred.accessToken.toString(),
              newCred.refreshToken.toString(),
              newCred.scopes.toString(),
              newCred.expiration.toString(),
              "");
        });
      } else {
        authenticateSpotify(context);
      }
    }
  } on SocketException catch (_) {
    print('Not Connected to Spotify');

    simpleDialog(context, "No Connection", "Unable to Connect to Spotify",
        "Check your Settings and try again", "error");
  }
}

Future openResult(BuildContext context) async {
  currentDate = DateTime.now();
  dayCounter++;
  print("Mood: $currentMood");
  journal.add(dayCounter - 1);
  memories.clear();
  results.clear();
  await makeDecisions(context);
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Wrap(children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    child: Text(peptalk(currentMood.toInt()),
                        style: GoogleFonts.newsCycle(
                          color: Colors.white,
                          fontSize: 25,
                        ))),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    child: Text("Here are some Memories:",
                        style: GoogleFonts.newsCycle(
                          color: Colors.white,
                          fontSize: 16,
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
                          List<Widget>.generate(memories.length, (int index) {
/*                         print("Displaying " +
                            memories.length.toString() +
                            " Results..."); */
                        if (results[index].memoriestype == null) {
                          results[index].memoriestype = "Default";
                        }
                        return memoriesEntry(
                            context,
                            results[index].memoriesid,
                            results[index].memoriestextone,
                            results[index].memoriestexttwo,
                            results[index].memoriestype,
                            results[index].memoriessubtype,
                            results[index].memoriesprovider,
                            results[index].memoriesargone,
                            results[index].memoriesargtwo,
                            results[index].memoriesargthree,
                            results[index].memoriesargfour);
                      })),
                  SizedBox(height: 30),
                ]))),
              ],
            )
          ]);
        });
      });

  switch (results.length - 1) {
    case 0:
      days.add(DayData(
          daymood: currentMood,
          daydate: date,
          daycolorone: Color(
              int.parse(memoriesColors[results[0].memoriestype].toString())),
          daycolortwo: Color(
              int.parse(memoriesColors[results[0].memoriestype].toString())),
          daycolorthree: Color(
              int.parse(memoriesColors[results[0].memoriestype].toString())),
          daycolorfour: Color(
              int.parse(memoriesColors[results[0].memoriestype].toString())),
          daycolorfive: Color(
              int.parse(memoriesColors[results[0].memoriestype].toString())),
          daycolorsix: Color(
              int.parse(memoriesColors[results[0].memoriestype].toString())),
          daynote: note,
          dayid: dayCounter,
          daytextone: ""));

      VibranceDatabase.instance.addDayDB(
          dayCounter,
          date,
          currentMood,
          Color(int.parse(memoriesColors[results[0].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[0].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[0].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[0].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[0].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[0].memoriestype].toString())),
          note);

      break;

    case 1:
      days.add(DayData(
          daymood: currentMood,
          daydate: date,
          daycolorone: Color(
              int.parse(memoriesColors[results[0].memoriestype].toString())),
          daycolortwo: Color(
              int.parse(memoriesColors[results[0].memoriestype].toString())),
          daycolorthree: Color(
              int.parse(memoriesColors[results[0].memoriestype].toString())),
          daycolorfour: Color(
              int.parse(memoriesColors[results[1].memoriestype].toString())),
          daycolorfive: Color(
              int.parse(memoriesColors[results[1].memoriestype].toString())),
          daycolorsix: Color(
              int.parse(memoriesColors[results[1].memoriestype].toString())),
          daynote: note,
          dayid: dayCounter,
          daytextone: ""));

      VibranceDatabase.instance.addDayDB(
          dayCounter,
          date,
          currentMood,
          Color(int.parse(memoriesColors[results[0].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[0].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[0].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[1].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[1].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[1].memoriestype].toString())),
          note);

      break;

    case 2:
      days.add(DayData(
          daymood: currentMood,
          daydate: date,
          daycolorone: Color(
              int.parse(memoriesColors[results[0].memoriestype].toString())),
          daycolortwo: Color(
              int.parse(memoriesColors[results[0].memoriestype].toString())),
          daycolorthree: Color(
              int.parse(memoriesColors[results[1].memoriestype].toString())),
          daycolorfour: Color(
              int.parse(memoriesColors[results[1].memoriestype].toString())),
          daycolorfive: Color(
              int.parse(memoriesColors[results[2].memoriestype].toString())),
          daycolorsix: Color(
              int.parse(memoriesColors[results[2].memoriestype].toString())),
          daynote: note,
          dayid: dayCounter,
          daytextone: ""));

      VibranceDatabase.instance.addDayDB(
          dayCounter,
          date,
          currentMood,
          Color(int.parse(memoriesColors[results[0].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[0].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[1].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[1].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[2].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[2].memoriestype].toString())),
          note);

      break;

    case 3:
      days.add(DayData(
          daymood: currentMood,
          daydate: date,
          daycolorone: Color(
              int.parse(memoriesColors[results[0].memoriestype].toString())),
          daycolortwo: Color(
              int.parse(memoriesColors[results[0].memoriestype].toString())),
          daycolorthree: Color(
              int.parse(memoriesColors[results[1].memoriestype].toString())),
          daycolorfour: Color(
              int.parse(memoriesColors[results[2].memoriestype].toString())),
          daycolorfive: Color(
              int.parse(memoriesColors[results[3].memoriestype].toString())),
          daycolorsix: Color(
              int.parse(memoriesColors[results[3].memoriestype].toString())),
          daynote: note,
          dayid: dayCounter,
          daytextone: ""));

      VibranceDatabase.instance.addDayDB(
          dayCounter,
          date,
          currentMood,
          Color(int.parse(memoriesColors[results[0].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[0].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[1].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[2].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[3].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[3].memoriestype].toString())),
          note);

      break;

    case 4:
      days.add(DayData(
          daymood: currentMood,
          daydate: date,
          daycolorone: Color(
              int.parse(memoriesColors[results[0].memoriestype].toString())),
          daycolortwo: Color(
              int.parse(memoriesColors[results[1].memoriestype].toString())),
          daycolorthree: Color(
              int.parse(memoriesColors[results[2].memoriestype].toString())),
          daycolorfour: Color(
              int.parse(memoriesColors[results[2].memoriestype].toString())),
          daycolorfive: Color(
              int.parse(memoriesColors[results[3].memoriestype].toString())),
          daycolorsix: Color(
              int.parse(memoriesColors[results[4].memoriestype].toString())),
          daynote: note,
          dayid: dayCounter,
          daytextone: ""));

      VibranceDatabase.instance.addDayDB(
          dayCounter,
          date,
          currentMood,
          Color(int.parse(memoriesColors[results[0].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[1].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[2].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[2].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[3].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[4].memoriestype].toString())),
          note);

      break;

    case 5:
      days.add(DayData(
          daymood: currentMood,
          daydate: date,
          daycolorone: Color(
              int.parse(memoriesColors[results[0].memoriestype].toString())),
          daycolortwo: Color(
              int.parse(memoriesColors[results[1].memoriestype].toString())),
          daycolorthree: Color(
              int.parse(memoriesColors[results[2].memoriestype].toString())),
          daycolorfour: Color(
              int.parse(memoriesColors[results[3].memoriestype].toString())),
          daycolorfive: Color(
              int.parse(memoriesColors[results[4].memoriestype].toString())),
          daycolorsix: Color(
              int.parse(memoriesColors[results[5].memoriestype].toString())),
          daynote: note,
          dayid: dayCounter,
          daytextone: ""));

      VibranceDatabase.instance.addDayDB(
          dayCounter,
          date,
          currentMood,
          Color(int.parse(memoriesColors[results[0].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[1].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[2].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[3].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[4].memoriestype].toString())),
          Color(int.parse(memoriesColors[results[5].memoriestype].toString())),
          note);

      break;

    default:
      break;
  }

  note = "";
  text = "";
  noteBuffer = "";
  textBuffer = "";
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
                                      buttoncolor =
                                          Color.fromRGBO(110, 43, 113, 1);
                                      break;
                                    case 2:
                                      backgroundcolor = lightMode[700];
                                      buttoncolor =
                                          Color.fromRGBO(110, 43, 113, 1);
                                      break;
                                    case 3:
                                      backgroundcolor = lightMode[500];
                                      buttoncolor =
                                          Color.fromRGBO(110, 43, 113, 1);
                                      break;
                                    case 4:
                                      backgroundcolor = lightMode[100];
                                      buttoncolor =
                                          Color.fromRGBO(54, 9, 61, 1);
                                      break;
                                    case 5:
                                      backgroundcolor = lightMode[200];
                                      buttoncolor =
                                          Color.fromRGBO(54, 9, 61, 1);
                                      break;
                                    case 6:
                                      backgroundcolor = lightMode[400];
                                      buttoncolor =
                                          Color.fromRGBO(54, 9, 61, 1);
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
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                                title: Text('Enter Note', style: dialogHeader),
                                content: SingleChildScrollView(
                                  child: ListBody(
                                    children: <Widget>[
                                      Text(
                                          "You can add addtional context of how you're feeling or when this feeling occurred.",
                                          style: dialogBody),
                                      Text(""),
                                      TextField(
                                          autofocus: true,
                                          keyboardType: TextInputType.multiline,
                                          minLines: 1,
                                          maxLines: 3,
                                          decoration: InputDecoration(
                                              fillColor: Colors.grey[300],
                                              filled: true,
                                              border:
                                                  const OutlineInputBorder(),
                                              hintText: "Note"),
                                          onChanged: (value) {
                                            setState(() {
                                              noteBuffer = value;
                                              note = noteBuffer;
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
                                        if (noteBuffer == "") {}
                                        if (noteBuffer == null) {}
                                        note = noteBuffer;
                                        noteBuffer = "";
                                        Navigator.pop(context);
                                      });
                                    },
                                  )
                                ]);
                          },
                        );
                      },
                      child: Text(
                        "Add Note",
                        style: TextStyle(color: buttoncolor),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      style: ButtonStyle(
                          minimumSize:
                              MaterialStatePropertyAll<Size>(Size(250, 50)),
                          backgroundColor:
                              MaterialStatePropertyAll<Color>(buttoncolor),
                          enableFeedback: true),
                      onPressed: enabled
                          ? () {
                              setState(() {
                                //enabled = false;
                              });
                              openResult(context);
                            }
                          : null,
                      child: Icon(
                        Icons.check,
                        color: Colors.white.withOpacity(0.8),
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
          //backgroundColor: color,
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
                    title: Text(peptalk(currentMood.toInt()),
                        style: GoogleFonts.newsCycle(
                            color: Colors.grey, fontSize: 16)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 5),
            ListView.builder(
              shrinkWrap: true,
              itemCount: memories.length,
              itemBuilder: (BuildContext context, int index) {
                return memoriesEntry(
                    context,
                    results[index].memoriesid,
                    results[index].memoriestextone,
                    results[index].memoriestexttwo,
                    results[index].memoriestype,
                    results[index].memoriessubtype,
                    results[index].memoriesprovider,
                    results[index].memoriesargone,
                    results[index].memoriesargtwo,
                    results[index].memoriesargthree,
                    results[index].memoriesargfour);
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
      if (spotifyApp != null) {
        var result;
        List searchResults = [];
        Future pickSpotifyData(item) async {
          //Dialog where we actually pick our songs or podcasts
          switch (item) {
            //Music Components
            case "Recently Played":
              result = await spotifyApp.me.recentlyPlayed(limit: 5).first();
              result.items?.forEach((item) => searchResults.add(MemoriesData(
                  memoriesid: item.track.id,
                  memoriestype: "Music",
                  memoriessubtype: "Track",
                  memoriesprovider: "Spotify",
                  memoriestextone: item.track.name,
                  memoriestexttwo: item.track.artists[0].name,
                  memoriesargone: "",
                  memoriesargtwo: item.track.uri,
                  memoriesargthree: "")));
              break;

            case "Albums":
              result = await spotifyApp.me.savedAlbums().getPage(10, 0);
              result.items?.forEach((item) => searchResults.add(MemoriesData(
                  memoriesid: item.id,
                  memoriestype: "Music",
                  memoriessubtype: "Album",
                  memoriesprovider: "Spotify",
                  memoriestextone: item.name,
                  memoriestexttwo: item.artists[0].name,
                  memoriesargone: item.releaseDate,
                  memoriesargtwo: item.uri,
                  memoriesargthree: "")));
              break;

            //Podcast Components
            case "Shows":
              result = await spotifyApp.me.savedShows().getPage(10, 0);
              result.items?.forEach((item) => searchResults.add(MemoriesData(
                  memoriesid: item.id,
                  memoriestype: "Podcast",
                  memoriessubtype: "Show",
                  memoriesprovider: "Spotify",
                  memoriestextone: item.name,
                  memoriestexttwo: item.publisher,
                  memoriesargone: item.description,
                  memoriesargtwo: item.uri,
                  memoriesargthree: "")));
              break;
          }

          List<Widget> spotifyItemList(BuildContext context) {
            return List<Widget>.generate(result.items.length, (int index) {
              return SimpleDialogOption(
                  onPressed: () async {
                    VibranceDatabase.instance.updateMemoriesDB(
                        searchResults[index].memoriestype,
                        searchResults[index].memoriessubtype,
                        "Spotify",
                        searchResults[index].memoriestextone,
                        searchResults[index].memoriestexttwo,
                        searchResults[index].memoriesid,
                        await getAlbumArt(
                            "Spotify",
                            searchResults[index].memoriesid,
                            searchResults[index].memoriessubtype),
                        "");
                    Navigator.pop(context);
                  },
                  child: Text(searchResults[index].memoriestextone,
                      style: GoogleFonts.newsCycle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
          case "Music":
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                    title: Text('Select Option', style: dialogHeader),
                    content: SingleChildScrollView(
                      child: ListBody(children: [
                        SimpleDialogOption(
                          onPressed: () {
                            pickSpotifyData("Recently Played");
                            Navigator.of(context).pop();
                          },
                          child: Text('Recently Played', style: dialogBody),
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
                            Navigator.of(context).pop();
                            VibranceDatabase.instance.updateMemoriesDB(
                                "Music",
                                "Top Track",
                                "Spotify",
                                "Top Track",
                                "",
                                "",
                                "",
                                "");
                            simpleDialog(
                                context,
                                "Top Track Added",
                                "Your Top Track will now be added automatically.",
                                "",
                                "info");
                          },
                          child: Text('Top Track', style: dialogBody),
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

          case "Podcasts":
            pickSpotifyData("Shows");
            break;

          default:
            break;
        }
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
                    spotifyData("Podcasts");
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
                                onPressed: () async {
                                  if (textBuffer == "") {}
                                  if (textBuffer == null) {}
                                  try {
                                    String cleanurl = (textBuffer.replaceAll(
                                        RegExp("http://|https://|rss://"), ""));
                                    final connection =
                                        await InternetAddress.lookup(
                                            cleanurl.substring(
                                                0, cleanurl.indexOf('/')));
                                    if (connection.isNotEmpty &&
                                        connection[0].rawAddress.isNotEmpty) {
                                      var rssfeed = await client
                                          .get(Uri.parse(textBuffer));
                                      VibranceDatabase.instance
                                          .updateMemoriesDB(
                                              "Podcast",
                                              "Show",
                                              "RSS",
                                              "RSS Podcast",
                                              textBuffer,
                                              "",
                                              await getAlbumArt(
                                                  "RSS", textBuffer, "RSS"),
                                              "");
                                      Navigator.pop(context);
                                    }
                                  } catch (e) {
                                    simpleDialog(
                                        context,
                                        "Invalid RSS URL",
                                        "RSS URL may be incorrect.",
                                        "Check the URL and try again",
                                        "error");
                                  }
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
      if (Platform.isIOS &&
          Platform.operatingSystemVersion.startsWith("Version 17")) {
        simpleDialog(
            context,
            "Unable to Access Calendars",
            "Calendar Support is Currently Unavailable on iOS 17, iPadOS 17 and macOS Sonoma",
            "Support will be added at a later time. ",
            "error");
      } else {
        try {
          //Because allCalendars is locked, lets make a buffer to store the data that we can touch
          allCalendars = await deviceCalendarPlugin.requestPermissions();
          allCalendars = await deviceCalendarPlugin.retrieveCalendars();
          // print(allCalendars.data);
          allCalendarsBuffer = allCalendars?.data;

          //We want to grab the calendar name so that we know where to grab events from
          List<Widget> allCalendarsList(BuildContext context) {
            return List<Widget>.generate(allCalendarsBuffer.length,
                (int index) {
              return SimpleDialogOption(
                  onPressed: () {
                    VibranceDatabase.instance.updateMemoriesDB(
                        "Event",
                        "Calendar",
                        "System",
                        allCalendarsBuffer[index].name,
                        "",
                        "",
                        "",
                        "");
                    Navigator.pop(context);
                  },
                  child: Text(allCalendarsBuffer[index].name,
                      style: GoogleFonts.newsCycle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
                          VibranceDatabase.instance.updateMemoriesDB(
                              "Text", "", "System", textBuffer, "", "", "", "");
                          Navigator.pop(context);
                        });
                      },
                    )
                  ]);
            },
          );
        } catch (e) {
          //print(e);
          simpleDialog(context, "Unable to Retrieve Calendars", "Error: $e",
              "Check your Settings and try again", "error");
        }
      }
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
                      VibranceDatabase.instance.updateMemoriesDB(
                          "Text", "", "System", textBuffer, "", "", "", "");
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
                            onPressed: (() async {
                              if (isRecording == false) {
                                await beginRecording(context);
                                setState(() {
                                  isRecording = true;
                                });
                              } else {
                                await stopRecording();
                                setState(() {
                                  Navigator.pop(context);
                                });
                              }
                            }),
                            child: isRecording
                                ? Text("Stop Recording",
                                    style: TextStyle(color: buttoncolor))
                                : Text("Start Recording",
                                    style: TextStyle(color: buttoncolor)),
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
      if (selectedPhoto != null) {
        selectedPhotoToData = await selectedPhoto.readAsBytes();
        VibranceDatabase.instance.updateMemoriesDB(
            "Photo", "Photo", "System", "", "", selectedPhotoToData, "", "");
      }
    }

    return Scaffold(
        appBar: AppBar(
          title: Text("", style: GoogleFonts.newsCycle(color: Colors.white)),
        ),
        body: SingleChildScrollView(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.sunny),
                      title: Text('What makes you happy?',
                          style: GoogleFonts.newsCycle(color: Colors.black)),
                      subtitle: Text(
                          "Add memories to inpire you to be your best.",
                          style: GoogleFonts.newsCycle(
                              color: Color.fromRGBO(81, 81, 81, 1))),
                    ),
                  ],
                ),
              ),
              Card(
                color: Color(memoriesColors.values.elementAt(0)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.music_note),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                                title: Text('Choose Provider',
                                    style: dialogHeader),
                                content: SingleChildScrollView(
                                    child: ListBody(children: <Widget>[
                                  SimpleDialogOption(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      await invokeSpotify(context);
                                      spotifyData("Music");
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
                          style: GoogleFonts.newsCycle(color: Colors.white)),
                      subtitle: Text("Songs to give you a jolt of energy.",
                          style: GoogleFonts.newsCycle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              Card(
                color: Color(memoriesColors.values.elementAt(1)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.podcasts),
                      onTap: () {
                        podcastOnboarding();
                      },
                      title: Text('Podcasts',
                          style: GoogleFonts.newsCycle(color: Colors.white)),
                      subtitle: Text("Podcasts to give you insight.",
                          style: GoogleFonts.newsCycle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              Card(
                color: Color(memoriesColors.values.elementAt(5)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                color: Color(memoriesColors.values.elementAt(3)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.photo),
                      onTap: () {
                        photoOnboarding(context);
                      },
                      title: Text('Photos',
                          style: GoogleFonts.newsCycle(color: Colors.white)),
                      subtitle: Text("Photos to help you reminance.",
                          style: GoogleFonts.newsCycle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              Card(
                color: Color(memoriesColors.values.elementAt(7)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.record_voice_over_rounded),
                      onTap: () {
                        soundOnboarding(context);
                      },
                      title: Text('Voice Notes',
                          style: GoogleFonts.newsCycle(color: Colors.white)),
                      subtitle: Text("Voice Notes to motivate you forward.",
                          style: GoogleFonts.newsCycle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              Card(
                color: Color(memoriesColors.values.elementAt(8)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.sticky_note_2),
                      onTap: () {
                        textOnboarding(context);
                      },
                      title: Text('Text Notes',
                          style: GoogleFonts.newsCycle(color: Colors.black)),
                      subtitle: Text("Text Notes to refect on.",
                          style: GoogleFonts.newsCycle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
              Card(
                color: Color(memoriesColors.values.elementAt(9)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.lightbulb),
                      onTap: () {
                        VibranceDatabase.instance.updateMemoriesDB(
                            "Tips", "Wellness", "System", "", "", "", "", "");
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                                title: Text("Tips", style: dialogHeader),
                                content: SingleChildScrollView(
                                  child: ListBody(
                                    children: <Widget>[
                                      Text("Tips Added.", style: dialogBody),
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
                      title: Text('Tips',
                          style: GoogleFonts.newsCycle(color: Colors.white)),
                      subtitle: Text("General tips to consider.",
                          style: GoogleFonts.newsCycle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ])));
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

    Future reenumerateState() async {
      noteBuffer = "";
      note = "";
      dayCounter = 0;
      days.clear();
      setState(() {
        journal = [];
      });
      VibranceDatabase.instance.initStatefromDB();
      await Future.delayed(const Duration(
          milliseconds:
              1500)); //It apparently takes 1 second or so for DB to populate State
      setState(() {
        int counterBuffer =
            dayCounter; //I need to freeze the state of the counter so that it doesn't keep iterating on append
        for (int i = 0; i < counterBuffer; i++) {
          currentMood = days[i].daymood;
          date = days[i].daydate;

          journal.add(i - 1);
          print("Restored Entry: ${i + 1}");
        }
        date = currentDate.toString().substring(0, 10);
        currentMood = 1;
      });
    }

//Journal Dialog is long because each of these set of widgets are generated at once for each day in real-time
    void journalDialog(
        BuildContext context,
        String textone,
        var mood,
        var date,
        Color colorone,
        Color colortwo,
        Color colorthree,
        Color colorfour,
        Color colorfive,
        Color colorsix,
        String note,
        int id) {
      mood = mood.toInt();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text("Mood: $mood/6",
                  style: GoogleFonts.newsCycle(color: Colors.white)),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(date.toString(),
                        style: GoogleFonts.newsCycle(
                            fontWeight: FontWeight.w600, color: Colors.white)),
                    const Text(""),
                    Text(note.toString(),
                        style: GoogleFonts.newsCycle(
                            fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text("Options",
                      style: GoogleFonts.newsCycle(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                            title: Text("Options",
                                style:
                                    GoogleFonts.newsCycle(color: Colors.white)),
                            content: SingleChildScrollView(
                              child: ListBody(
                                children: <Widget>[
                                  SimpleDialogOption(
                                      child: Text("Copy Entry",
                                          style: GoogleFonts.newsCycle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white)),
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
                                              color: Colors.white)),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('Enter New Note',
                                                    style:
                                                        GoogleFonts.newsCycle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                Colors.white)),
                                                content: SingleChildScrollView(
                                                  child: ListBody(
                                                    children: <Widget>[
                                                      Text(
                                                          "You can add addtional context of how you're feeling or when this feeling occurred.",
                                                          style: GoogleFonts
                                                              .newsCycle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Colors
                                                                      .white)),
                                                      Text(""),
                                                      TextField(
                                                          autofocus: true,
                                                          decoration: InputDecoration(
                                                              fillColor: Colors
                                                                  .grey[300],
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
                                                        style: GoogleFonts
                                                            .newsCycle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: Colors
                                                                    .white)),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: Text('OK',
                                                        style: GoogleFonts
                                                            .newsCycle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: Colors
                                                                    .white)),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                      if (noteBuffer == "") {
                                                        noteBuffer = "";
                                                      }
                                                      noteBuffer ??= "";
                                                      note = noteBuffer;
                                                      noteBuffer = "";
                                                      Navigator.pop(context);
                                                      VibranceDatabase.instance
                                                          .updateDaysDB(
                                                              id,
                                                              mood,
                                                              colorone,
                                                              colortwo,
                                                              colorthree,
                                                              colorfour,
                                                              colorfive,
                                                              colorsix,
                                                              note);
                                                      reenumerateState();
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
                                              color: Colors.red[800])),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                                backgroundColor:
                                                    Colors.orange[800],
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
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: Text('OK',
                                                        style: dialogBody),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                      days.removeAt(id - 1);
                                                      VibranceDatabase.instance
                                                          .initDBfromState();
                                                      reenumerateState();
                                                      Navigator.of(context)
                                                          .pop();
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
                                        color: Colors.white)),
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
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ]);
        },
      );
    }

    Widget journalEntry(
        BuildContext context,
        String textone,
        final mood,
        String date,
        Color colorone,
        Color colortwo,
        Color colorthree,
        Color colorfour,
        Color colorfive,
        Color colorsix,
        String note,
        int id) {
      IconData icon = Icons.format_list_bulleted;

      return Card(
          //color: color,
          child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment(0.5, 1),
                      colors: [
                        darkenColor(colorone),
                        darkenColor(colortwo),
                        darkenColor(colorthree),
                        darkenColor(colorfour),
                        darkenColor(colorfive),
                        darkenColor(colorsix)
                      ])),
              child: ListTile(
                leading: Icon(
                  icon,
                  color: Colors.white,
                ),
                title: Text("Mood: ${mood.toInt()}/6",
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    maxLines: 1,
                    style: GoogleFonts.newsCycle(
                        color: Colors.white, fontSize: 16)),
                subtitle: Text(date,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    maxLines: 1,
                    style: GoogleFonts.newsCycle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 14)),
                onTap: () {
                  journalDialog(
                      context,
                      textone,
                      mood,
                      date,
                      colorone,
                      colortwo,
                      colorthree,
                      colorfour,
                      colorfive,
                      colorsix,
                      note,
                      id);
                },
              )));
    }

    List<Widget> makeJournalEntry(BuildContext context) {
      return List<Widget>.generate(journal.length, (int index) {
        return journalEntry(
            context,
            days[index].daytextone,
            days[index].daymood,
            days[index].daydate,
            days[index].daycolorone,
            days[index].daycolortwo,
            days[index].daycolorthree,
            days[index].daycolorfour,
            days[index].daycolorfive,
            days[index].daycolorsix,
            days[index].daynote,
            (index + 1));
      });
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

    Widget graphSummary() {
      var points = days;
      if (journal.length < 5) {
        return SizedBox(
            height: 80,
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                  Text("Keep using Vibrance to get a summary",
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      maxLines: 1,
                      style: GoogleFonts.newsCycle(
                          color: Colors.black, fontSize: 14)),
                ])));
      } else {
        return SizedBox(
            height: 80,
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                  Text(
                      "Average Mood: ${((days[days.length - 1].daymood + days[days.length - 2].daymood + days[days.length - 3].daymood + days[days.length - 4].daymood + days[days.length - 5].daymood) / days.length).toInt()}/6",
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      maxLines: 1,
                      style: GoogleFonts.newsCycle(
                          color: Colors.black, fontSize: 18)),
                  LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: 5,
                      minY: 0,
                      maxY: 5,
                      lineBarsData: [
                        LineChartBarData(
                          spots: points
                              .map((point) =>
                                  FlSpot(point.daymood, point.daymood))
                              .toList(),
                          isCurved: false,
                        )
                      ],
                    ),
                  ),
                ])));
      }
    }

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
              subtitle: Text(
                  "Today is " + DateTime.now().toString().substring(0, 10),
                  style: GoogleFonts.newsCycle(
                      color: Color.fromRGBO(81, 81, 81, 1))),
            ),
          ],
        ),
      ),
/*       Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.graphic_eq_outlined),
              title: Text("Summary",
                  style: GoogleFonts.newsCycle(color: Colors.black)),
              subtitle: Text("Here's a Summary",
                  style: GoogleFonts.newsCycle(
                      color: Color.fromRGBO(81, 81, 81, 1))),
            ),
            graphSummary(),
          ],
        ),
      ), */
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
                  style: GoogleFonts.newsCycle(
                      color: Color.fromRGBO(81, 81, 81, 1))),
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
                    style: GoogleFonts.newsCycle(
                        color: Color.fromRGBO(81, 81, 81, 1))),
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
            leading: Icon(Icons.flag),
            title: Text("Quick Start",
                style: GoogleFonts.newsCycle(color: Colors.black)),
            onTap: () => helpDialog(context),
          ),
          ListTile(
            leading: Icon(Icons.library_add),
            title: Text("Add Memories",
                style: GoogleFonts.newsCycle(color: Colors.black)),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const OnboardingPage())),
          ),
          ListTile(
            leading: Icon(Icons.playlist_add_check_rounded),
            title: Text("Manage Memories",
                style: GoogleFonts.newsCycle(color: Colors.black)),
            onTap: () => manageMemories(context),
          ),
          ListTile(
            leading: Icon(Icons.restore_page),
            title: Text("Reset Journal",
                style: GoogleFonts.newsCycle(color: Colors.red)),
            onTap: () => clearDaysWarning(context),
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text("Sign Out of Providers",
                style: GoogleFonts.newsCycle(color: Colors.red)),
            onTap: () => clearServicesWarning(context),
          ),
        ],
      )),
    ]));
  }
}
