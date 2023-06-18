// ignore_for_file: avoid_print, unnecessary_null_comparison
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';
import 'package:vibrance/main.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';

/* These are the default value we use for settings
These will also be the values to fall back on in case DB can't be loaded
They will also be loaded into DB on init */

var pathBuffer = "";

class ProjectMirrorDatabase {
  static final ProjectMirrorDatabase instance = ProjectMirrorDatabase._init();

  static Database? _database;

  ProjectMirrorDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ProjectMirrorDB.db');
    return _database!;
  }

  Future<Database> _initDB(String fpath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fpath);
    print(path);
    pathBuffer =
        path; //We wanna use this variable in the initState so that we don't read a dead DB

    return await openDatabase(path,
        version: 1, onCreate: createDB, onUpgrade: upgradeDB);
  }

  Future createDB(Database db, int version) async {
    db.execute(
        'CREATE TABLE Content (id INTEGER, type TEXT, date TEXT, text MEDIUMTEXT, raw LONGBLOB, weight INT)');
    //db.execute('CREATE TABLE Prefs ()');
    db.execute(
        'CREATE TABLE Days (id INTEGER, date TEXT, mood INTEGER, color TEXT, notes MEDIUMTEXT)');

    print("DB Made!");
    onboarding = 1;
  }

  Future addDayDB(id, date, mood, color, note) async {
    final db = await instance.database;
    var colorBuffer = color.toString();
    colorBuffer = colorBuffer.replaceAll("Color(", "");
    colorBuffer = colorBuffer.replaceAll(")", "");

    db.rawInsert(
        'INSERT INTO Days (id, date, mood, color, notes) VALUES(?, ?, ?, ?, ?)',
        ['$id', date, mood, colorBuffer, '$note']);
  }

  Future closeDB() async {
    final db = await instance.database;
    db.close();
  }

  Future initStatefromDB() async {
/*     Let's using this function to fill up the map and Journal when booting the app
    Is using all these variables the way that I am the smartest way to do it?
    Probably not but I'll figure something out later maybe type type-casting is the right way to go */
    final db = await instance.database;

    if (pathBuffer != null) {
      //Load Prefs Data

      //Load User Data
      var counterBuffer = await db.query("Days", columns: ["MAX(id)"]);
      var counter = int.tryParse(counterBuffer[0]['MAX(id)'].toString());
      var colorBuffer = await db.query("Days", columns: ["color"]);

      counter ??= 0;
      dayCounter = counter;

/*       This part is the star of the show, we are parsing everything from the Days DB
      Then by counter we are attempting, one by one to place everything on the map */
      for (var i = 0; i <= counter - 1; i++) {
        var colorBuffer2 = colorBuffer[i]["color"].toString();
        color = Color(int.parse(colorBuffer2));

        //Parse the Day's date
        var dateBuffer = await db.query("Days", columns: ["date"]);
        var date = dateBuffer[i]["date"].toString();

        //Parse the Day's note
        var noteBuffer = await db.query("Days", columns: ["notes"]);
        var note = noteBuffer[i]["notes"].toString();

        var moodBuffer = await db.query("Days", columns: ["mood"]);
        var mood = double.parse(moodBuffer[i]["mood"].toString());

        days.add(DayData(
          dayid: i,
          daydate: date,
          daynote: note,
          daycolor: color,
          daymood: mood,
        ));
      }
    } else {
      print("Empty/No DB, Skipping...");
    }
  }

  Future initDBfromState() async {
    clearDaysDB(); //We need to clean out the existing DB and reappend it
    for (var i = 0; i < days.length; i++) {
      addDayDB(
        i + 1,
        days[i].daydate,
        days[i].daymood,
        days[i].daycolor,
        days[i].daynote,
      );
    }
  }

  Future updateDaysDB(var id, var caption, var note, var color) async {}

  Future updateContentDB(var type, var text, var raw) async {
    final db = await instance.database;

    var counterBuffer = await db.query("Content", columns: ["MAX(id)"]);
    var counter = int.tryParse(counterBuffer[0]['MAX(id)'].toString());
    counter ??= 0;
    counter = counter + 1;
    const weight = 3;

    db.rawInsert(
        'INSERT INTO Content (id, type, date, text, raw, weight) VALUES(?, ?, ?, ?, ?, ?)',
        [counter, type, date, text, raw, weight]);
  }

  Future updateWeight(var id, var weight) async {
    final db = await instance.database;

    db.rawUpdate(
        '''UPDATE Content SET weight = ? WHERE id = ?''', [weight, id]);
  }

  Future resetDB() async {
    final db = await instance.database;
    db.delete("Content");
    db.delete("Prefs");
    db.delete("Days");
  }

  Future clearDaysDB() async {
    final db = await instance.database;
    db.delete("Days");
  }

  Future clearContentDB() async {
    final db = await instance.database;
    db.delete("Content");
  }

  void upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      switch (oldVersion) {
        //If DB version is version 1, it needs to pick up ALL the newer changes, not just the latest ones
        case 1:
          print("Updating DB to Version 2...");
          //Version 2 Changes
          print("Update Complete.");
          break;
        default:
          print("No changes made to DB...");
          break;
      }
    }
  }

  Future deleteDayDB(id) async {
    final db = await instance.database;
    db.query("Days");
    db.execute("DELETE FROM Days WHERE id = $id");
  }
}
