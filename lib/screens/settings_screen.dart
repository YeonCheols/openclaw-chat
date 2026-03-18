import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/websocket_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _hostController;
  late TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    final ws = context.read<WebSocketService>();
    _hostController = TextEditingController(text: ws.host);
    _portController = TextEditingController(text: ws.port.toString());
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _saveAndReconnect() async {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 18789;
    if (host.isEmpty) return;

    final ws = context.read<WebSocketService>();
    await ws.configure(host, port);
    ws.disconnect();
    ws.connect();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$host:$port 로 재연결합니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 테마 섹션
        Text('테마', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Consumer<ThemeProvider>(
          builder: (context, tp, _) => Card(
            child: SwitchListTile(
              title: const Text('다크 모드'),
              subtitle: Text(tp.isDark ? '어두운 테마 사용 중' : '밝은 테마 사용 중'),
              secondary: Icon(tp.isDark ? Icons.dark_mode : Icons.light_mode),
              value: tp.isDark,
              onChanged: (_) => tp.toggle(),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 서버 설정 섹션
        Text('서버 연결', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          '맥미니의 로컬 IP 주소와 OpenClaw 포트를 입력하세요.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _hostController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: '맥미니 IP 주소',
                    hintText: '192.168.0.x',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.computer),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _portController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '포트',
                    hintText: '18789',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.settings_ethernet),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saveAndReconnect,
                    icon: const Icon(Icons.save),
                    label: const Text('저장 및 재연결'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 연결 상태 섹션
        Text('연결 상태', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Consumer<WebSocketService>(
          builder: (context, ws, _) {
            final (label, color, icon) = switch (ws.status) {
              ConnectionStatus.connected    => ('연결됨', Colors.green, Icons.check_circle),
              ConnectionStatus.pending      => ('승인 대기 중', Colors.amber, Icons.hourglass_top),
              ConnectionStatus.connecting   => ('연결 중...', Colors.orange, Icons.sync),
              ConnectionStatus.error        => ('연결 오류', Colors.red, Icons.error),
              ConnectionStatus.disconnected => ('연결 끊김', Colors.grey, Icons.cancel),
            };
            return Card(
              child: ListTile(
                leading: Icon(icon, color: color),
                title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                subtitle: Text('ws://${ws.host}:${ws.port}'),
                trailing: ws.status == ConnectionStatus.connected
                    ? TextButton(onPressed: ws.disconnect, child: const Text('끊기'))
                    : TextButton(onPressed: ws.connect, child: const Text('연결')),
              ),
            );
          },
        ),
      ],
    );
  }
}
