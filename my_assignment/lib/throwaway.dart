import 'package:flutter/material.dart';

class FloatFieldWithController extends StatefulWidget {
  @override
  _FloatFieldWithControllerState createState() => _FloatFieldWithControllerState();
}

class _FloatFieldWithControllerState extends State<FloatFieldWithController> {
  // This variable holds the text value of the field
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = "0.0"; // initial value
  }

  void _printValue() {
    double? number = double.tryParse(_controller.text);
    print("Current floating-point value: $number");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Text Field Controller Example')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller, // connect controller here
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Enter a floating-point number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _printValue,
              child: const Text('Print Value'),
            ),
          ],
        ),
      ),
    );
  }
}
