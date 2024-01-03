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

void onboardDialog(BuildContext context, var header, var body1, var body2,
    var body3, var body4) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor:
              MediaQuery.of(context).platformBrightness == Brightness.light
                  ? lightMode.withOpacity(1)
                  : darkMode.withOpacity(1),
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
              child: Text("Quick Start", style: dialogBody),
              onPressed: () {
                Navigator.of(context).pop();
                helpDialog(context);
              },
            ),
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
                    'Use the slider to rate how you are feeling on a scale from 1-6',
                    style: dialogBody),
                const Text(''),
                Text(
                    'Add content in Settings to help inspire you after rating your mood',
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
