import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // needed before using SharedPreferences in main
  WidgetsFlutterBinding.ensureInitialized();

  // load the data from the last launch before the app starts
  Mortgage mortgage = Mortgage();
  await mortgage.loadData();

  // the provider gives both screens access to the same mortgage
  runApp(ChangeNotifierProvider.value(value: mortgage, child: const MyApp()));
}

// Mortgage class from the lab handout
// It extends ChangeNotifier so the Provider can tell the screens when it changes
class Mortgage extends ChangeNotifier {
  double _amount = 0;
  int _years = 0;
  double _rate = 0;

  Mortgage() {
    setAmount(100000.0);
    setYears(30);
    setRate(0.035);
  }

  void setAmount(double newAmount) {
    if (newAmount >= 0) {
      _amount = newAmount;
    }
  }

  void setYears(int newYears) {
    if (newYears >= 0) {
      _years = newYears;
    }
  }

  void setRate(double newRate) {
    if (newRate >= 0) {
      _rate = newRate;
    }
  }

  double getAmount() {
    return _amount;
  }

  String getFormattedAmount() {
    return '\$${_amount.toStringAsFixed(2)}';
  }

  int getYears() {
    return _years;
  }

  double getRate() {
    return _rate;
  }

  double monthlyPayment() {
    double mRate = _rate / 12; // monthly interest rate
    double temp = pow(1 / (1 + mRate), _years * 12).toDouble();
    return _amount * mRate / (1 - temp);
  }

  String formattedMonthlyPayment() {
    return '\$${monthlyPayment().toStringAsFixed(2)}';
  }

  double totalPayment() {
    return monthlyPayment() * _years * 12;
  }

  String formattedTotalPayment() {
    return '\$${totalPayment().toStringAsFixed(2)}';
  }

  // called by the modify screen when Done is pressed
  void updateMortgage(double newAmount, int newYears, double newRate) {
    setAmount(newAmount);
    setYears(newYears);
    setRate(newRate);

    // tells every screen that uses the mortgage to rebuild
    notifyListeners();

    saveData();
  }

  // saves the user's inputs on the phone
  Future<void> saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('amount', _amount);
    await prefs.setInt('years', _years);
    await prefs.setDouble('rate', _rate);
  }

  // reads the saved inputs (uses the default values on the first launch)
  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setAmount(prefs.getDouble('amount') ?? 100000.0);
    setYears(prefs.getInt('years') ?? 30);
    setRate(prefs.getDouble('rate') ?? 0.035);
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mortgage Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const HomeScreen(),
    );
  }
}

// First screen - shows the mortgage info and the payments
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool termsChecked = false;

  // opens the modify screen
  // (no data is passed back, the Provider updates this screen)
  void goToModifyScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ModifyScreen()),
    );
  }

  // shows the alert dialog for the terms and conditions
  void showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Terms and Conditions'),
          content: const Text(
            'The payments in this app are only estimates. Your real '
            'payment from a lender may be different.\n\n'
            'Do you agree to the terms and conditions?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  termsChecked = false;
                });
                Navigator.pop(context);
              },
              child: const Text('Decline'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  termsChecked = true;
                });
                Navigator.pop(context);
              },
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // gets the mortgage from the Provider
    // this screen rebuilds every time notifyListeners() is called
    Mortgage mortgage = Provider.of<Mortgage>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mortgage Calculator'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // loan info
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.attach_money, color: Colors.teal),
                    title: const Text('Amount'),
                    trailing: Text(
                      mortgage.getFormattedAmount(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.calendar_month,
                      color: Colors.teal,
                    ),
                    title: const Text('Years'),
                    trailing: Text(
                      '${mortgage.getYears()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.percent, color: Colors.teal),
                    title: const Text('Interest Rate'),
                    trailing: Text(
                      '${(mortgage.getRate() * 100).toStringAsFixed(2)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // payments
            Card(
              color: Colors.teal,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Payment',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    Text(
                      mortgage.formattedMonthlyPayment(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Total Payment',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    Text(
                      mortgage.formattedTotalPayment(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // terms and conditions check box
            CheckboxListTile(
              title: const Text('Terms and Conditions'),
              value: termsChecked,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                if (value == true) {
                  showTermsDialog();
                } else {
                  setState(() {
                    termsChecked = false;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // the button only works after the terms are accepted
            // (setting onPressed to null makes the button grayed out)
            ElevatedButton(
              onPressed: termsChecked ? goToModifyScreen : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Modify Data', style: TextStyle(fontSize: 18)),
            ),
            if (!termsChecked)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Accept the terms and conditions to modify data',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Second screen - lets the user change the years, amount, and interest rate
class ModifyScreen extends StatefulWidget {
  const ModifyScreen({super.key});

  @override
  State<ModifyScreen> createState() => _ModifyScreenState();
}

class _ModifyScreenState extends State<ModifyScreen> {
  int years = 30;
  double selectedRate = 3.5;
  TextEditingController amountController = TextEditingController();
  List<double> rates = [];

  @override
  void initState() {
    super.initState();

    // make the list of rates: 2.00, 2.25, 2.50 ... 15.00
    for (double r = 2.0; r <= 15.0; r = r + 0.25) {
      rates.add(r);
    }

    // start with the values from the Provider
    // (listen: false because this screen only reads the data once here)
    Mortgage mortgage = Provider.of<Mortgage>(context, listen: false);
    years = mortgage.getYears();
    amountController.text = mortgage.getAmount().toStringAsFixed(2);

    // the rate is saved as 0.035, so times 100 to get 3.5
    // (rounded to 2 decimals so it matches a number in the list)
    selectedRate = double.parse((mortgage.getRate() * 100).toStringAsFixed(2));
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void donePressed() {
    double? amount = double.tryParse(amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    // update the mortgage in the Provider (this also saves the data)
    Mortgage mortgage = Provider.of<Mortgage>(context, listen: false);
    mortgage.updateMortgage(amount, years, selectedRate / 100);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Loan'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Years',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            RadioGroup<int>(
              groupValue: years,
              onChanged: (value) {
                setState(() {
                  years = value!;
                });
              },
              child: const Row(
                children: [
                  Radio<int>(value: 10),
                  Text('10'),
                  Radio<int>(value: 15),
                  Text('15'),
                  Radio<int>(value: 30),
                  Text('30'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Amount',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Interest Rate: ${selectedRate.toStringAsFixed(2)}%',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // list of interest rates
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: ListView.builder(
                  itemCount: rates.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text('${rates[index].toStringAsFixed(2)}%'),
                      selected: rates[index] == selectedRate,
                      selectedTileColor: Colors.teal[50],
                      trailing: rates[index] == selectedRate
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () {
                        setState(() {
                          selectedRate = rates[index];
                        });
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: donePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
