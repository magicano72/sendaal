import 'package:flutter/material.dart';

import 'app_theme.dart';

ThemeData buildDarkTheme() =>
    AppTheme.buildTheme(palette: AppPalettes.dark, brightness: Brightness.dark);
