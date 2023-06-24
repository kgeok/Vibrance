import 'package:flutter/material.dart';

Map<int, Color> color = {
  50: const Color.fromRGBO(110, 43, 113, 0.6),
  100: const Color.fromRGBO(110, 43, 113, .7),
  200: const Color.fromRGBO(110, 43, 113, .8),
  300: const Color.fromRGBO(110, 43, 113, .9),
  400: const Color.fromRGBO(110, 43, 113, 1),
  500: const Color.fromRGBO(54, 9, 61, .6),
  600: const Color.fromRGBO(54, 9, 61, .7),
  700: const Color.fromRGBO(54, 9, 61, .8),
  800: const Color.fromRGBO(54, 9, 61, .9),
  900: const Color.fromRGBO(54, 9, 61, 1),
};

MaterialColor lightMode = MaterialColor(0xff6E2B71, color);
MaterialColor darkMode = MaterialColor(0xff36093D, color);

class CustomTheme {
  static ThemeData get lightTheme {
    //1
    return ThemeData(
      //2
      dialogTheme: DialogTheme(backgroundColor: lightMode),
      useMaterial3: true,
      splashColor: darkMode.withOpacity(0.4),
      primarySwatch: lightMode,
      primaryColor: lightMode,
      fontFamily: 'NewsCycle',
      dialogBackgroundColor: lightMode,
      sliderTheme: const SliderThemeData(
          thumbColor: Color.fromRGBO(110, 43, 113, 1),
          activeTrackColor: Color.fromRGBO(54, 9, 61, 1),
          inactiveTrackColor: Color(0xFF8D8E98),
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10)),
      buttonTheme: const ButtonThemeData(),
      scaffoldBackgroundColor: lightMode,
      canvasColor: lightMode,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          unselectedItemColor: Color.fromRGBO(54, 9, 61, 1)),
      appBarTheme: AppBarTheme(
        backgroundColor: lightMode,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      dialogTheme: DialogTheme(backgroundColor: darkMode),
      useMaterial3: true,
      splashColor: lightMode.withOpacity(0.4),
      primarySwatch: darkMode,
      primaryColor: darkMode,
      fontFamily: 'NewsCycle',
      dialogBackgroundColor: darkMode,
      sliderTheme: const SliderThemeData(
          activeTrackColor: Color.fromRGBO(110, 43, 113, 1),
          inactiveTrackColor: Color(0xFF8D8E98),
          thumbColor: Color.fromRGBO(54, 9, 61, 1),
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12)),
      scaffoldBackgroundColor: darkMode,
      canvasColor: darkMode,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          unselectedItemColor: Color.fromRGBO(110, 43, 113, 1)),
      appBarTheme: AppBarTheme(
        backgroundColor: darkMode,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }
}
