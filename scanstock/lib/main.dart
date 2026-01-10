import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/supabase_config.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'utils/role_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar la barra de estado para tema oscuro
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Bloquear orientacion a vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await SupabaseConfig.initialize();

  runApp(const ScanStockApp());
}

class ScanStockApp extends StatelessWidget {
  const ScanStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'ScanStock',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const RoleGuard(),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
