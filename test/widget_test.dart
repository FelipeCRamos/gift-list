import 'package:flutter_test/flutter_test.dart';
import 'package:gift_list/app.dart';

void main() {
  testWidgets('app boots to the landing page', (tester) async {
    await tester.pumpWidget(const GiftListApp());
    await tester.pumpAndSettle();

    expect(find.text('Gift Registry'), findsWidgets);
    expect(find.text('View a sample list'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
