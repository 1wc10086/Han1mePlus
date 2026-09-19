import 'package:flutter/material.dart';

final appShellScaffoldKey = GlobalKey<ScaffoldState>();

void openAppDrawer() => appShellScaffoldKey.currentState?.openDrawer();

bool permanentNavigationDrawer(BuildContext context) => MediaQuery.sizeOf(context).shortestSide >= 600;
