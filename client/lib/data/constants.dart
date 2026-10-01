import 'package:flutter/material.dart';

class KConstants {
  static const String themeModeKey = 'themeModeKey';
}

class KTextStyle {
  static const TextStyle titleText = TextStyle(
    fontSize: 20.0,
    color: Colors.teal,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle descriptionText = TextStyle(
    fontSize: 16.0,
    color: Colors.white,
    fontWeight: FontWeight.normal,
  );
}

final ThemeData appTheme = ThemeData(
  primaryColor: const Color(0xFF39D2C0),
  scaffoldBackgroundColor: const Color(0xFF161630),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(
      fontFamily: 'Poppins',
      color: Colors.white,
      fontSize: 14,
    ),
  ),
);
