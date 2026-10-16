import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const testSupportedLocales = [Locale('tr'), Locale('en')];

const testLocalizationDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
