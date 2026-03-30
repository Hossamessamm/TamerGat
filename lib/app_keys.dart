import 'package:flutter/material.dart';

/// Root keys for deep-link navigation and global SnackBars after stack reset.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
