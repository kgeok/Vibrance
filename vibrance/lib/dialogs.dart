// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_typing_uninitialized_variables, unused_import

import 'package:vibrance/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibrance/theme/custom_theme.dart';

var buttonaction1 = "";
var buttonaction2 = "";
var dialogColor;

var dialogHeader =
    GoogleFonts.newsCycle(fontWeight: FontWeight.w700, color: Colors.white);

var dialogBody =
    GoogleFonts.newsCycle(fontWeight: FontWeight.w600, color: Colors.white);

void simpleDialog(
    BuildContext context, var header, var body1, var body2, var type) {
  switch (type) {
    case "warning":
      buttonaction1 = "Cancel";
      buttonaction2 = "OK";
      dialogColor = Colors.orange[800];
      break;

    case "error":
      buttonaction1 = "";
      buttonaction2 = "Dismiss";
      dialogColor = Colors.red[900];
      break;

    case "info":
      buttonaction1 = "";
      buttonaction2 = "OK";
      dialogColor =
          MediaQuery.of(context).platformBrightness == Brightness.light
              ? lightMode
              : darkMode;
      break;

    default:
      buttonaction1 = "Cancel";
      buttonaction2 = "OK";
      dialogColor =
          MediaQuery.of(context).platformBrightness == Brightness.light
              ? lightMode
              : darkMode;
      break;
  }
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor: dialogColor,
          title: Text(header, style: dialogHeader),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(body1, style: dialogBody),
                Text(body2, style: dialogBody),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(buttonaction1, style: dialogBody),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(buttonaction2, style: dialogBody),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ]);
    },
  );
}

void complexDialog(BuildContext context, var header, var body1, var body2,
    var body3, var body4, var type) {
  switch (type) {
    case "warning":
      buttonaction1 = "Cancel";
      buttonaction2 = "OK";
      dialogColor = Colors.orange[800];
      break;

    case "error":
      buttonaction1 = "";
      buttonaction2 = "Dismiss";
      dialogColor = Colors.red[900];
      break;

    case "info":
      buttonaction1 = "";
      buttonaction2 = "OK";
      dialogColor =
          MediaQuery.of(context).platformBrightness == Brightness.light
              ? lightMode.withOpacity(0.8)
              : darkMode.withOpacity(0.8);
      break;

    default:
      buttonaction1 = "Cancel";
      buttonaction2 = "OK";
      dialogColor =
          MediaQuery.of(context).platformBrightness == Brightness.light
              ? lightMode.withOpacity(0.8)
              : darkMode.withOpacity(0.8);
      break;
  }
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor: dialogColor,
          title: Text(header, style: dialogHeader),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(body1, style: dialogBody),
                Text("", style: dialogBody),
                Text(body2, style: dialogBody),
                Text("", style: dialogBody),
                Text(body3, style: dialogBody),
                Text("", style: dialogBody),
                Text(body4, style: dialogBody),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(buttonaction1, style: dialogBody),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(buttonaction2, style: dialogBody),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ]);
    },
  );
}

void onboardDialog(BuildContext context) {
  showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
    ),
    constraints: const BoxConstraints(maxWidth: 500),
    builder: (BuildContext context) {
      return Container(
          constraints: const BoxConstraints(maxWidth: 500),
          color: MediaQuery.of(context).platformBrightness == Brightness.light
              ? lightMode.withOpacity(1)
              : darkMode.withOpacity(1),
          child: FractionallySizedBox(
              // heightFactor: 0.6,
              child: SingleChildScrollView(
                  child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 35, 0, 0),
                child: Text("Welcome to $sku",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.newsCycle(
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: Colors.white)),
              ),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                  child: Text(
                      "Our memories are a valuable source of inspiration.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.newsCycle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white))),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Text(
                      "Inspire yourself with the help of your Music, Photos, Podcasts, Voice and more.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.newsCycle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white))),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Text(
                      "Keep track of how you were feeling with the Journal",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.newsCycle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white))),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Text(
                      "Use the slider to rate how you are feeling on a scale from 1-6 (1 being the lowest and 6 being the highest)",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.newsCycle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white))),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Text(
                      "Add memories in Settings to help inspire you after rating your mood",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.newsCycle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white))),
              Center(
                  child: SingleChildScrollView(
                      child: Column(children: [
                const SizedBox(height: 30),
                TextButton(
                  style: ButtonStyle(
                      minimumSize:
                          const MaterialStatePropertyAll<Size>(Size(250, 50)),
                      backgroundColor: MaterialStatePropertyAll<Color>(
                        MediaQuery.of(context).platformBrightness ==
                                Brightness.light
                            ? darkMode.withOpacity(1)
                            : lightMode.withOpacity(1),
                      ),
                      enableFeedback: true),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Get Started",
                      style: GoogleFonts.newsCycle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 16)),
                ),
                const SizedBox(height: 50),
              ])))
            ],
          ))));
    },
  );
}

void resourcesDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor:
              MediaQuery.of(context).platformBrightness == Brightness.light
                  ? lightMode
                  : darkMode,
          title: Text("Additional Resources", style: dialogHeader),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("USA: National Crisis Hotline: 988", style: dialogBody),
                Text("USA: Crisis Text Line: Text SIGNS to 741741",
                    style: dialogBody),
                Text("USA: Disaster Distress Helpline: 1-800-985-5990",
                    style: dialogBody),
                Text("National Domestic Violence Hotline: 1-800-799-7233",
                    style: dialogBody),
                Text("National Child Abuse Hotline: 1-800-422-4453",
                    style: dialogBody),
                Text("National Sexual Abuse Hotline: 1-800-656-HOPE",
                    style: dialogBody),
                Text("", style: dialogBody),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("OK", style: dialogBody),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ]);
    },
  );
}

void helpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor:
              MediaQuery.of(context).platformBrightness == Brightness.light
                  ? lightMode.withOpacity(1)
                  : darkMode.withOpacity(1),
          title: Text("Quick Start", style: dialogHeader),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Use the slider to rate how you are feeling on a scale from 1-6 (1 being the lowest and 6 being the highest)',
                    style: dialogBody),
                const Text(''),
                Text(
                    'Add memories in Settings to help inspire you after rating your mood',
                    style: dialogBody),
                const Text(''),
                Text('Open the Journal to get a record of your mood ratings',
                    style: dialogBody),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Dismiss', style: dialogBody),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ]);
    },
  );
}
