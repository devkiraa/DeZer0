import 'package:flutter/material.dart';
import 'package:flutter_pin_code_fields/flutter_pin_code_fields.dart';
import 'main_screen.dart'; // FIX: Import main_screen.dart instead of home_screen.dart

class PasscodeScreen extends StatefulWidget {
  const PasscodeScreen({super.key});

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  final String _correctPin = "0000";

  void _onPinCompleted(String pin) {
    if (pin == _correctPin) {
      // FIX: Navigate to MainScreen() instead of HomeScreen()
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Incorrect PIN. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, size: 80, color: Colors.blueGrey),
              const SizedBox(height: 20),
              const Text(
                'Enter Passcode',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              PinCodeFields(
                length: 4,
                fieldBorderStyle: FieldBorderStyle.square,
                responsive: false,
                fieldHeight: 60.0,
                fieldWidth: 60.0,
                borderWidth: 2.0,
                activeBorderColor: Colors.blue,
                borderRadius: BorderRadius.circular(10.0),
                keyboardType: TextInputType.number,
                autoHideKeyboard: false,
                onComplete: _onPinCompleted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}