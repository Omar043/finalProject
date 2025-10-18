/*
    main.dart
*/
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // for decoding json formatted text
import 'package:http/http.dart' as http; // for making the http request

void main() => runApp(MainPage());

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

//the following class is for storing information returned in the api request to oepnfoodfacts
class FoodCard {
  String? name;
  String? ingredients;
  Map<String, dynamic>? nutriments;
  List<dynamic>? allergenTags;
  List<dynamic>? traces;

  FoodCard({
    required this.name,
    required this.ingredients,
    required this.nutriments,
    required this.allergenTags,
  });
}

class _MainPageState extends State<MainPage> {
  //Appbar Color
  final Color _appBarColor = Colors.redAccent;

  //Functions assosiated with the shared_preferences function:
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
  }

  Future<Map<String, dynamic>?> retrieveFoodInformation(String barcode) async {
    /*
      URL Construction:
        The base url for OpenFoodFacts is the inital url.
        The barcode and query parameters are attached to the final url.
  */

    final Uri uri =
        Uri.parse(
          'https://world.openfoodfacts.org/api/v2/product/$barcode.json',
        ).replace(
          queryParameters: {
            'fields':
                'product_name,code,ingredients_text,nutriments, allergens,allergens_tags,traces_tags',
          },
        );

    /*
      HTTP Response Handling:
        Null will be returned in the case that the foodscan server does not respond or information pertaining to the food item is not found.
  */
    final response = await http.get(
      uri,
      headers: {'User-Agent': 'FoodScan/1.0 (20omarr04@gmail.com)'},
    );

    if (response.statusCode != 200) {
      return null;
    }
    final Map<String, dynamic> json = jsonDecode(response.body);

    if (json['status'] != 1) {
      return null;
    }
    final product = json['product'] as Map<String, dynamic>;
    final ingredients = product['ingredients_text'];
    final nutriments = product['nutriments'] as Map<String, dynamic>?;
    final allergenTags = product['allergens_tags'] as List<dynamic>?;
    final traces = product['traces_tags'] as List<dynamic>?;
    final foodName = product['product_name'] as String? ?? 'Unknown Food';

    return {
      'food_name': foodName,
      'ingredients': ingredients,
      'nutriments': nutriments,
      'allergen_tags': allergenTags,
      'traces': traces,
    };
  }

  List<Map<String, dynamic>?> foodReturnValues = [];

  Future<void> addItemsToList() async {
    List<String> foodItemUpcCodes = [
      "028400047913", //hot cheetoes
      "074323092301", //bimbo whole wheat
      "888109253097", //jumbo honey bun
    ];

    foodReturnValues.clear();
    for (var item in foodItemUpcCodes) {
      var itemToAdd = await retrieveFoodInformation(item); // wait for result
      if (itemToAdd != null) {
        // only items that have return value returned.
        foodReturnValues.add(itemToAdd);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgetList = [
      ElevatedButton(
        onPressed: () async {
          await addItemsToList();
        },
        child: Text('Press to load items'),
      ),
      Expanded(child: DisplayItems(itemsToShow: foodReturnValues)),
    ];

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: _appBarColor,
          title: const Text('CSCI567 Hello World'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: widgetList),
        ),
      ),
    );
  }
}

class DisplayItems extends StatelessWidget {
  final List<Map<String, dynamic>?> itemsToShow;

  const DisplayItems({required this.itemsToShow});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemsToShow.length,
      itemBuilder: (context, index) {
        final item = itemsToShow[index];

        //null check
        if (item == null) {
          return ListTile(title: Text("No data available"));
        }

        return Card(
          margin: EdgeInsets.all(8.0),
          child: ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              //elements from api request are retrieved
              children: [
                Text(
                  item['food_name'] ?? 'Unknown Food',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                Text(
                  "Ingredients: ${item['ingredients'] ?? 'Not available'}",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8.0),

                if (item['allergen_tags'] != null &&
                    item['allergen_tags']!.isNotEmpty)
                  Text(
                    "Allergens: ${item['allergen_tags']?.join(', ') ?? 'None'}",
                    style: TextStyle(fontSize: 16),
                  )
                else
                  Text("Allergens: None", style: TextStyle(fontSize: 16)),
                SizedBox(height: 8.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
