import 'package:flutter/material.dart';

ThemeData appTheme = ThemeData(
  fontFamily: 'Satoshi', // Replace with your desired font family if you have one
  colorScheme: ColorScheme.light(
    primary: Colors.white, // Primary color - white for buttons and backgrounds
    secondary: Colors.black, // Secondary color - black for text and secondary buttons
    tertiary: Colors.orange, // Tertiary color - orange for accent and key actions
    surface: Colors.grey.shade50, // Background color - light grey
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0, // Remove appbar shadow for a flatter look
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.grey.shade100, // Slightly darker background for depth
      foregroundColor: Colors.black,
      elevation: 5, // Increased elevation for more pronounced shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shadowColor: Colors.grey.shade500, // Shadow color
      surfaceTintColor: Colors.white, // Surface tint for elevation
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.black, // Default text button color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: Colors.black, // Default icon button color
    ),
  ),
  // Add more theme customizations here (e.g., text styles, cardTheme, etc.)
);