import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/data/local/update_installer.dart';
import 'package:dio/dio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UpdateInstaller(Dio()).removeStaleApk();
  runApp(const ProviderScope(child: Han1meApp()));
}
