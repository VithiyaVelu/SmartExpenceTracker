import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:expense_tracker/main.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Expense tracker home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Expense Tracker'), findsOneWidget);
    expect(find.text('Total Balance'), findsOneWidget);
    expect(find.text('No transactions yet. Tap + to add one.'), findsOneWidget);
  });
}
