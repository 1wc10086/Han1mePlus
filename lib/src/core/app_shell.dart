import 'package:flutter/material.dart';

final appShellScaffoldKey = GlobalKey<ScaffoldState>();

void openAppDrawer() => appShellScaffoldKey.currentState?.openDrawer();
