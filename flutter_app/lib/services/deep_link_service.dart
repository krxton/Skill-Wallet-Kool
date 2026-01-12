import 'dart:async';
import 'package:uni_links/uni_links.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  StreamSubscription? _sub;

  // ✅ Start listening for deep links
  void startListening(Function(Uri) onLink) {
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        print('📱 Deep link received: $uri');
        onLink(uri);
      }
    }, onError: (err) {
      print('❌ Deep link error: $err');
    });
  }

  // ✅ Stop listening
  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  // ✅ Get initial link (เมื่อแอปเปิดจาก deep link)
  Future<Uri?> getInitialLink() async {
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        print('📱 Initial deep link: $initialUri');
      }
      return initialUri;
    } catch (e) {
      print('❌ Get initial link error: $e');
      return null;
    }
  }
}
