import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mortgage_app/main.dart';

void main() {
  test('monthly payment for the default mortgage', () {
    Mortgage mortgage = Mortgage();
    expect(mortgage.formattedMonthlyPayment(), '\$449.04');
  });

  test('loadData reads the values saved last time', () async {
    SharedPreferences.setMockInitialValues({
      'amount': 200000.0,
      'years': 15,
      'rate': 0.05,
    });

    Mortgage mortgage = Mortgage();
    await mortgage.loadData();

    expect(mortgage.getAmount(), 200000.0);
    expect(mortgage.getYears(), 15);
    expect(mortgage.getRate(), 0.05);
  });

  testWidgets('Done updates the first screen and saves the data', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    Mortgage mortgage = Mortgage();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: mortgage, child: const MyApp()),
    );
    expect(find.text('\$100000.00'), findsOneWidget);
    expect(find.text('\$449.04'), findsOneWidget);

    // accept the terms and open the modify screen
    await tester.tap(find.text('Terms and Conditions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modify Data'));
    await tester.pumpAndSettle();

    // the modify screen starts with the data from the Provider
    expect(find.text('100000.00'), findsOneWidget);

    // change the years and amount, then press Done
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is Radio<int> && widget.value == 15,
      ),
    );
    await tester.enterText(find.byType(TextField), '200000');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // back on the first screen with the new values
    expect(find.text('\$200000.00'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);

    // the new values were saved
    SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('amount'), 200000.0);
    expect(prefs.getInt('years'), 15);
    expect(prefs.getDouble('rate'), 0.035);
  });
}
