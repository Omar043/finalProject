/*
    main.dart
*/
import 'package:flutter/material.dart';

void main() => runApp(MainPage());

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  ///
  /// AppBar color variables and functions
  ///
  Color _appBarColor = Colors.redAccent; //appBar variable

  void _changeAppBarColor() {
    //funcion that changes appBar color
    setState(() {
      if (_appBarColor == Colors.redAccent) {
        _appBarColor = Colors.blueAccent;
      } else {
        _appBarColor = Colors.redAccent;
      }
    });
  }

  ///
  /// List appendage variables and functions
  ///

  final TextEditingController _textBoxController = TextEditingController();
  final List<String> _items = [];
  void _addItem() {
    final text = _textBoxController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _items.add(text);
      });
      _textBoxController.clear(); // clear text field after adding
    }
  }

  @override //ovveride is used because we need  recontextualize build class
  Widget build(BuildContext context) {
    //widget list:
    List<Widget> widgetList = [
      /*
          Button that changes the color of the App
      */
      ElevatedButton(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
          // Background color (normal & pressed)
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.blueAccent.withValues(alpha: 0.5); // pressed color
            }
            return Colors.blueAccent; // default background
          }),
        ),

        onPressed: () {
          _changeAppBarColor();
        },
        child: Text(
          'button that changes appbar color',
          style: TextStyle(
            fontSize: 40.0,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      /*
          Button that prints response in console log
      */
      TextButton(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all<Color>(
            const Color.fromARGB(49, 255, 255, 255),
          ),
          // Background color (normal & pressed)
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.pressed)) {
              return const Color.fromARGB(
                255,
                68,
                255,
                243,
              ).withValues(alpha: 0.5); // pressed color
            }
            return const Color.fromARGB(
              255,
              68,
              255,
              239,
            ); // default background
          }),
        ),
        onPressed: () {
          print("21");
        },
        child: Text(
          'what is 9 + 10?(button prints answer)',
          style: TextStyle(
            fontSize: 40.0,
            color: const Color.fromARGB(255, 230, 46, 187),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      OutlinedButton(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all<Color>(
            const Color.fromARGB(210, 49, 175, 32),
          ),
          // Background color (normal & pressed)
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.pressed)) {
              return const Color.fromARGB(
                255,
                81,
                68,
                255,
              ).withValues(alpha: 0.5); // pressed color
            }
            return const Color.fromARGB(255, 81, 68, 255); // default background
          }),
        ),
        onPressed: () {
          _addItem();
        },
        child: Text(
          "tap to append text to list",
          style: TextStyle(
            fontSize: 40.0,
            color: const Color.fromARGB(255, 160, 121, 38),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      TextField(
        controller: _textBoxController,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: "Enter text",
        ),
      ),

      Expanded(
        child: ListView.builder(
          itemCount: _items.length,
          itemBuilder: (context, index) {
            return ListTile(title: Text(_items[index]));
          },
        ),
      ),
    ];

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: _appBarColor,
          title: const Text('CSCI567 Hello World'),
        ),
        body: Padding(
          //to construct the body, the padding element is used to store the elements of the widget
          padding: const EdgeInsets.all(16.0),
          child: Column(
            //widgets are iterated through as children of the padding element
            children: widgetList,
          ),
        ),
      ),
    );
  }
}
