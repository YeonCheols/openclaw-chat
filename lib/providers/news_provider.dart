import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/news_item.dart';
import '../services/websocket_service.dart';

class NewsProvider extends ChangeNotifier {
  final WebSocketService _wsService;
  StreamSubscription<Map<String, dynamic>>? _sub;

  final List<NewsItem> _items = [];
  final _streamController = StreamController<List<NewsItem>>.broadcast();

  List<NewsItem> get items => List.unmodifiable(_items);
  Stream<List<NewsItem>> get itemsStream => _streamController.stream;

  NewsProvider(this._wsService) {
    _sub = _wsService.newsStream.listen(_onNews);
  }

  void requestNews({String? category}) {
    _wsService.requestNews(category: category);
  }

  void _onNews(Map<String, dynamic> data) {
    final payload = data['data'];
    if (payload is List) {
      final incoming = payload.cast<Map<String, dynamic>>().map(NewsItem.fromJson);
      _items.insertAll(0, incoming);
    } else if (payload is Map<String, dynamic>) {
      _items.insert(0, NewsItem.fromJson(payload));
    }
    _streamController.add(List.unmodifiable(_items));
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _streamController.add(const []);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _streamController.close();
    super.dispose();
  }
}
