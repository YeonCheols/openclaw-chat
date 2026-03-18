import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketService>(
      builder: (context, ws, _) {
        final (label, color, icon) = switch (ws.status) {
          ConnectionStatus.connected    => ('연결됨', Colors.green, Icons.check_circle_outline),
          ConnectionStatus.pending      => ('승인 대기 중 — OpenClaw에서 이 기기를 허용해주세요', Colors.amber, Icons.hourglass_top),
          ConnectionStatus.connecting   => ('연결 중...', Colors.orange, Icons.sync),
          ConnectionStatus.error        => ('연결 오류', Colors.red, Icons.error_outline),
          ConnectionStatus.disconnected => ('연결 끊김', Colors.grey, Icons.cancel_outlined),
        };

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: color.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 14),
          child: Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (ws.status == ConnectionStatus.disconnected || ws.status == ConnectionStatus.error)
                GestureDetector(
                  onTap: ws.connect,
                  child: Text(
                    '재연결',
                    style: TextStyle(fontSize: 11, color: color, decoration: TextDecoration.underline),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
