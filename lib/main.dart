import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:tutora/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase chỉ phục vụ push notification. Máy dev chưa có google-services.json thì
  // bỏ qua để app vẫn chạy (không có push), thay vì crash ngay khi mở.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase chưa được cấu hình, tắt push notification: $e');
  }

  await initializeDateFormatting('vi_VN');
  Intl.defaultLocale = 'vi_VN';

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: App()));
}
