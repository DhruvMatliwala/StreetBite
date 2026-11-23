import 'package:flutter_test/flutter_test.dart';
import 'package:streetbite/utils/debouncer.dart';

void main() {
  group('Debouncer', () {
    test('coalesces rapid calls into a single execution', () async {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 60));
      var count = 0;

      debouncer.run(() => count++);
      debouncer.run(() => count++);
      debouncer.run(() => count++);

      expect(count, 0);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(count, 1);

      debouncer.dispose();
    });

    test('cancel prevents pending callback execution', () async {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 60));
      var count = 0;

      debouncer.run(() => count++);
      debouncer.cancel();

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(count, 0);

      debouncer.dispose();
    });
  });
}
