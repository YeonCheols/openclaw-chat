import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/news_item.dart';
import '../providers/news_provider.dart';
import '../services/websocket_service.dart';
import '../widgets/news_card.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final List<String> _categories = ['전체', '경제', '정치', '기술', '사회'];
  String _selected = '전체';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchNews());
  }

  void _fetchNews() {
    final ws = context.read<WebSocketService>();
    final news = context.read<NewsProvider>();
    if (ws.status == ConnectionStatus.connected) {
      news.requestNews(category: _selected == '전체' ? null : _selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CategoryBar(
          categories: _categories,
          selected: _selected,
          onSelect: (c) {
            setState(() => _selected = c);
            _fetchNews();
          },
        ),
        Expanded(
          child: StreamBuilder<List<NewsItem>>(
            stream: context.read<NewsProvider>().itemsStream,
            initialData: context.read<NewsProvider>().items,
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return _EmptyState(onRefresh: _fetchNews);
              }

              return RefreshIndicator(
                onRefresh: () async => _fetchNews(),
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    // 봇 브리핑(category == 'briefing')은 강조 카드로
                    if (item.category == 'briefing') {
                      return NewsBriefingCard(item: item);
                    }
                    return NewsCard(item: item);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.newspaper, size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text('뉴스를 불러오는 중...', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('새로고침'),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryBar({required this.categories, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = cat == selected;
          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (_) => onSelect(cat),
            selectedColor: theme.colorScheme.primary,
            labelStyle: TextStyle(
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }
}
