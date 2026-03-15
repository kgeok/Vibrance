// ignore_for_file: avoid_print, unnecessary_null_comparison
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';
import 'package:vibrance/main.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
/* These are the default value we use for settings
These will also be the values to fall back on in case DB can't be loaded
They will also be loaded into DB on init */

var pathBuffer = "";

String colorToString(Color color) {
  return ("0x${color.toHexString()}");
}

class VibranceDatabase {
  static final VibranceDatabase instance = VibranceDatabase._init();

  static Database? _database;

  VibranceDatabase._init();

  Future get database async {
    if (_database != null) return _database!;
    _database = await _initDB('VibranceDB.db');
    return _database!;
  }

  Future _initDB(String fpath) async {
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
        'CREATE TABLE Memories (id INTEGER, type TEXT, subtype TEXT, provider TEXT, date TEXT, textone MEDIUMTEXT, texttwo MEDIUMTEXT, textthree MEDIUMTEXT, textfour MEDIUMTEXT, rawone LONGBLOB, rawtwo LONGBLOB, rawthree LONGBLOB, rawfour LONGBLOB, weight FLOAT)');

    db.execute(
        'CREATE TABLE Days (id INTEGER, date TEXT, mood INTEGER, colorone TEXT, colortwo TEXT, colorthree TEXT, colorfour TEXT, colorfive TEXT, colorsix TEXT, notes MEDIUMTEXT, rawone LONGBLOB, rawtwo LONGBLOB, rawthree LONGBLOB)');

    db.execute(
        'CREATE TABLE Configuration (id INTEGER, service MEDIUMTEXT, dataone MEDIUMTEXT, datatwo MEDIUMTEXT, datathree MEDIUMTEXT, datafour MEDIUMTEXT, datafive MEDIUMTEXT)');

    db.execute('CREATE TABLE Prefs (id INTEGER, animations BOOLEAN)');

    db.rawInsert(
        'INSERT INTO Prefs (id, animations) VALUES(?, ?)', ['1', 'TRUE']);

    print("DB Made!");
    onboarding = 1;
  }

  Future addDayDB(
      int id,
      String date,
      var mood,
      Color colorone,
      Color colortwo,
      Color colorthree,
      Color colorfour,
      Color colorfive,
      Color colorsix,
      String note) async {
    final db = await instance.database;

    db.rawInsert(
        'INSERT INTO Days (id, date, mood, colorone, colortwo, colorthree, colorfour, colorfive, colorsix, notes) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          '$id',
          date,
          mood,
          colorToString(colorone),
          colorToString(colortwo),
          colorToString(colorthree),
          colorToString(colorfour),
          colorToString(colorfive),
          colorToString(colorsix),
          note
        ]);
  }

  Future updateDaysDB(
      int id,
      var mood,
      Color colorone,
      Color colortwo,
      Color colorthree,
      Color colorfour,
      Color colorfive,
      Color colorsix,
      String note) async {
    final db = await instance.database;

    db.rawUpdate(
        '''UPDATE Days SET mood = ?, colorone = ?, colortwo = ?, colorthree = ?, colorfour = ?, colorfive = ?, colorsix = ?, notes = ? WHERE id = ?''',
        [
          mood,
          colorToString(colorone),
          colorToString(colortwo),
          colorToString(colorthree),
          colorToString(colorfour),
          colorToString(colorfive),
          colorToString(colorsix),
          note,
          id
        ]);
  }

  Future updatePrefsDB() async {
    final db = await instance.database;
    await db.rawUpdate('''UPDATE Prefs SET animations = ? WHERE id = ?''',
        [animations.toString(), '1']);
  }

  Future closeDB() async {
    final db = await instance.database;
    db.close();
  }

  Future initStatefromDB() async {
/*  Let's using this function to fill up the map and Journal when booting the app
    Is using all these variables the way that I am the smartest way to do it?
    Probably not but I'll figure something out later maybe type type-casting is the right way to go */
    final db = await instance.database;

    if (pathBuffer != null) {
      //Load User Data
      var counterBuffer = await db.query("Days", columns: ["MAX(id)"]);
      var counter = int.tryParse(counterBuffer[0]['MAX(id)'].toString());
      var daysdbResults = await db.query("Days");
      var prefsdbResults = await db.query("Prefs");
      animations = bool.parse(prefsdbResults[0]['animations'].toString(),
          caseSensitive: false);

      counter ??= 0;
      dayCounter = counter;

/*    This part is the star of the show, we are parsing everything from the Days DB
      Then by counter we are attempting, one by one to place everything in the journal */

      for (var i = 0; i <= dayCounter - 1; i++) {
        if (!(daysdbResults[i]["colorone"].toString())
            .toLowerCase()
            .startsWith("0xff")) {
          print("Error With Entry: ${i + 1}");
          print(
              "We're going to need to fix it otherwise we will run into issues...");
          await db.rawUpdate('''UPDATE Days SET colorone = ? WHERE id = ?''',
              ['0xff000000', i + 1]);
          daysdbResults = await db.query("Days");
        }

        if (!(daysdbResults[i]["colortwo"].toString())
            .toLowerCase()
            .startsWith("0xff")) {
          print("Error With Entry: ${i + 1}");
          print(
              "We're going to need to fix it otherwise we will run into issues...");
          await db.rawUpdate('''UPDATE Days SET colortwo = ? WHERE id = ?''',
              ['0xff000000', i + 1]);
          daysdbResults = await db.query("Days");
        }

        if (!(daysdbResults[i]["colorthree"].toString())
            .toLowerCase()
            .startsWith("0xff")) {
          print("Error With Entry: ${i + 1}");
          print(
              "We're going to need to fix it otherwise we will run into issues...");
          await db.rawUpdate('''UPDATE Days SET colorthree = ? WHERE id = ?''',
              ['0xff000000', i + 1]);
          daysdbResults = await db.query("Days");
        }

        if (!(daysdbResults[i]["colorfour"].toString())
            .toLowerCase()
            .startsWith("0xff")) {
          print("Error With Entry: ${i + 1}");
          print(
              "We're going to need to fix it otherwise we will run into issues...");
          await db.rawUpdate('''UPDATE Days SET colorfour = ? WHERE id = ?''',
              ['0xff000000', i + 1]);
          daysdbResults = await db.query("Days");
        }

        if (!(daysdbResults[i]["colorfive"].toString())
            .toLowerCase()
            .startsWith("0xff")) {
          print("Error With Entry: ${i + 1}");
          print(
              "We're going to need to fix it otherwise we will run into issues...");
          await db.rawUpdate('''UPDATE Days SET colorfive = ? WHERE id = ?''',
              ['0xff000000', i + 1]);
          daysdbResults = await db.query("Days");
        }

        if (!(daysdbResults[i]["colorsix"].toString())
            .toLowerCase()
            .startsWith("0xff")) {
          print("Error With Entry: ${i + 1}");
          print(
              "We're going to need to fix it otherwise we will run into issues...");
          await db.rawUpdate('''UPDATE Days SET colorsix = ? WHERE id = ?''',
              ['0xff000000', i + 1]);
          daysdbResults = await db.query("Days");
        }

        if (double.tryParse(daysdbResults[i]["mood"].toString()) == null) {
          print("Error With Entry: ${i + 1}");
          print(
              "We're going to need to fix it otherwise we will run into issues...");
          await db.rawUpdate(
              '''UPDATE Days SET mood = ? WHERE id = ?''', [0, i + 1]);
          daysdbResults = await db.query("Days");
        }

        days.add(DayData(
          dayid: i,
          daydate: daysdbResults[i]["date"].toString(),
          daynote: daysdbResults[i]["notes"].toString(),
          daycolorone:
              Color(int.parse(daysdbResults[i]["colorone"].toString())),
          daycolortwo:
              Color(int.parse(daysdbResults[i]["colortwo"].toString())),
          daycolorthree:
              Color(int.parse(daysdbResults[i]["colorthree"].toString())),
          daycolorfour:
              Color(int.parse(daysdbResults[i]["colorfour"].toString())),
          daycolorfive:
              Color(int.parse(daysdbResults[i]["colorfive"].toString())),
          daycolorsix:
              Color(int.parse(daysdbResults[i]["colorsix"].toString())),
          daymood: double.parse((daysdbResults[i]["mood"] ?? 0).toString()),
          daytextone: "",
        ));
      }
    } else {
      print("Empty/No DB, Skipping...");
    }
  }

  Future initDBfromState(String type) async {
    switch (type) {
      case "Days":
        clearDaysDB(); //We need to clean out the existing DB and reappend it
        for (var i = 0; i < days.length; i++) {
          addDayDB(
            i + 1,
            days[i].daydate,
            days[i].daymood,
            days[i].daycolorone,
            days[i].daycolortwo,
            days[i].daycolorthree,
            days[i].daycolorfour,
            days[i].daycolorfive,
            days[i].daycolorsix,
            days[i].daynote,
          );
        }
        break;
      case "Memories":
        clearMemoriesDB(); //We need to clean out the existing DB and reappend it
        for (var i = 0; i < results.length; i++) {
          await updateMemoriesDB(
            results[i].memoriestype,
            results[i].memoriessubtype,
            results[i].memoriesprovider,
            results[i].memoriestextone,
            results[i].memoriestexttwo,
            results[i].memoriesargone,
            results[i].memoriesargtwo,
            results[i].memoriesargthree,
          );
        }
        break;
    }
  }

  Future updateMemoriesDB(
      String type,
      String subtype,
      String provider,
      String textone,
      String texttwo,
      var rawone,
      var rawtwo,
      var rawthree) async {
    final db = await instance.database;

    var counterBuffer = await db.query("Memories", columns: ["MAX(id)"]);
    var counter = int.tryParse(counterBuffer[0]['MAX(id)'].toString());
    counter ??= 0;
    counter = counter + 1;
    const weight = 3;
    print(counter);
    db.rawInsert(
        'INSERT INTO Memories (id, type, subtype, provider, date, textone, texttwo, textthree, textfour, rawone, rawtwo, rawthree, rawfour, weight) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          counter,
          type,
          subtype,
          provider,
          date,
          textone,
          texttwo,
          null,
          null,
          rawone,
          rawtwo,
          rawthree,
          null,
          weight
        ]);
  }

  Future updateWeight(int id, double weight) async {
    final db = await instance.database;
    print("Updating weight: $id, $weight");
    db.rawUpdate('''UPDATE Memories SET weight = ? WHERE id = ?''',
        [weight.toInt(), id]);
  }

  Future resetWeight() async {
    final db = await instance.database;
    db.execute("ALTER TABLE Memories DROP COLUMN weight");
    db.execute(
        "ALTER TABLE Memories ADD COLUMN weight FLOAT DEFAULT '3' NOT NULL;");
  }

  Future resetDB() async {
    final db = await instance.database;
    db.delete("Memories");
    db.delete("Prefs");
    db.delete("Days");
  }

  Future clearDaysDB() async {
    final db = await instance.database;
    db.delete("Days");
  }

  Future clearMemoriesDB() async {
    final db = await instance.database;
    db.delete("Memories");
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

  Future deleteDayDB(int id) async {
    final db = await instance.database;
    db.query("Days");
    db.execute("DELETE FROM Days WHERE id = $id");
  }

  Future addService(int id, service, var dataone, var datatwo, var datathree,
      var datafour, var datafive) async {
    final db = await instance.database;
    db.rawInsert(
        'INSERT INTO Configuration (id, service, dataone, datatwo, datathree, datafour, datafive) VALUES(?, ?, ?, ?, ?, ?, ?)',
        [
          '$id',
          '$service',
          '$dataone',
          '$datatwo',
          '$datathree',
          '$datafour',
          '$datafive'
        ]);
  }

  Future deleteMemoriesDB(int id) async {
    final db = await instance.database;
    db.query("Memories");
    db.execute("DELETE FROM Memories WHERE id = $id");
  }

  Future deleteMemoriesByServiceDB(String service) async {
    final db = await instance.database;
    db.query("Memories");
    db.execute("DELETE FROM Memories WHERE provider = '$service'");
  }

  Future removeService(String service) async {
    final db = await instance.database;
    db.query("Configuration");
    db.execute("DELETE FROM Configuration WHERE service = '$service'");
  }

  Future removeAllServices() async {
    final db = await instance.database;
    db.query("Configuration");
    db.delete("Configuration");
  }

  Future provideServiceData() async {
    final db = await instance.database;
    var counterBuffer = await db.query("Configuration", columns: ["MAX(id)"]);
    var counter = int.tryParse(counterBuffer[0]['MAX(id)'].toString());
    counter ??= 0;
    services.clear();
    for (var i = 0; i <= counter - 1; i++) {
      var servicenameBuffer =
          await db.query("Configuration", columns: ["service"]);
      var servicename = servicenameBuffer[i]["service"].toString();

      var dataoneBuffer = await db.query("Configuration", columns: ["dataone"]);
      var dataone = dataoneBuffer[i]["dataone"].toString();
      var datatwoBuffer = await db.query("Configuration", columns: ["datatwo"]);
      var datatwo = datatwoBuffer[i]["datatwo"].toString();
      var datathreeBuffer =
          await db.query("Configuration", columns: ["datathree"]);
      var datathree = datathreeBuffer[i]["datathree"].toString();
      var datafourBuffer =
          await db.query("Configuration", columns: ["datafour"]);
      var datafour = datafourBuffer[i]["datafour"].toString();
      var datafiveBuffer =
          await db.query("Configuration", columns: ["datafive"]);
      var datafive = datafiveBuffer[i]["datafive"].toString();

      services.add(ServiceData(
          i, servicename, dataone, datatwo, datathree, datafour, datafive));
    }
  }
}
