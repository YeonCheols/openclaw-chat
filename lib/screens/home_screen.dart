import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';
import '../widgets/connection_banner.dart';
import 'chat_screen.dart';
import 'news_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _tabs = [
    (label: '뉴스', icon: Icons.newspaper, screen: NewsScreen()),
    (label: '채팅', icon: Icons.chat, screen: ChatScreen()),
    (label: '설정', icon: Icons.settings, screen: SettingsScreen()),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WebSocketService>().connect();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // pubspec에 assets/icon.png가 없으면 일부 iOS 빌드에서 Image.asset이 예외로 크래시할 수 있음
            Icon(Icons.chat_bubble_rounded, size: 26, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('OpenClaw', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(28),
          child: ConnectionBanner(),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: _tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}
