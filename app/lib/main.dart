import 'package:app/core/services/notification_service.dart';
import 'package:app/core/services/pin_service.dart';
import 'package:app/core/services/sync_manager.dart';
import 'package:app/myapp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await SyncManager.initialize();
  await NotificationService.instance.init();
  runApp(ChangeNotifierProvider(create: (_) => PinService(), child: MyApp()));
}
