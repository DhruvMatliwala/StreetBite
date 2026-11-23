import 'dart:async';
import 'dart:ui';

/// Coalesces rapid calls (such as search typing) into a single delayed action.
class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 380)});

  final Duration duration;
  Timer? _timer;

  bool get isActive => _timer?.isActive ?? false;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    cancel();
  }
}
