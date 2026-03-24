import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'providers/news_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'services/websocket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ws = WebSocketService();
  try {
    await ws.loadSavedSettings();
  } catch (e, stack) {
    FlutterError.dumpErrorToConsole(
      FlutterErrorDetails(exception: e, stack: stack, library: 'openclaw main'),
    );
    // 키체인/SharedPreferences/암호 키 생성 실패 시에도 앱은 기본값으로 기동
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ws),
        ChangeNotifierProxyProvider<WebSocketService, NewsProvider>(
          create: (ctx) => NewsProvider(ctx.read<WebSocketService>()),
          update: (_, ws, prev) => prev ?? NewsProvider(ws),
        ),
        ChangeNotifierProxyProvider<WebSocketService, ChatProvider>(
          create: (ctx) => ChatProvider(ctx.read<WebSocketService>()),
          update: (_, ws, prev) => prev ?? ChatProvider(ws),
        ),
      ],
      child: const OpenClawApp(),
    ),
  );
}

class OpenClawApp extends StatelessWidget {
  const OpenClawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) {
        return MaterialApp(
          title: 'OpenClaw',
          debugShowCheckedModeBanner: false,
          themeMode: theme.mode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: const HomeScreen(),
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0057FF),
      brightness: brightness,
    ),
    cardTheme: const CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
  );
}
