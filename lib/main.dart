import 'package:flutter/material.dart';

import 'di/app_config.dart';
import 'di/app_dependencies.dart';
import 'presentation/navigation/app_navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The stored session is read before the first frame so that the app opens on the right screen.
  final dependencies = await AppDependencies.create(AppConfig.fromEnvironment());
  runApp(TodoApp(dependencies: dependencies));
}
