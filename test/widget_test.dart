import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memedrop/main.dart';

void main() {
  testWidgets('Landing screen shows DROP. text', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MemeDropApp()));
    expect(find.text('DROP.'), findsOneWidget);
  });
}
