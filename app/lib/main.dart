import 'package:app/core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:app/core/services/pin_service.dart';
import 'package:app/myapp.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(ChangeNotifierProvider(create: (_) => PinService(), child: MyApp()));
}
