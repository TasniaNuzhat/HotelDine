import 'dart:io';

import 'package:appwrite/models.dart';
import 'package:appwrite/models.dart';
import 'package:appwrite/models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hoteldineflutter/pages/UserPage/myorder.dart';
import 'dart:typed_data';
import 'package:hoteldineflutter/pages/UserPage/myprofile.dart';
import 'package:hoteldineflutter/pages/UserPage/mycart.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class Availablefoods extends StatefulWidget {
  @override
  AvailablefoodsState createState() => AvailablefoodsState();
}

class AvailablefoodsState extends State<Availablefoods> {
  int currentIndex = 0;

  late Client client;
  late Databases database;
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> filteredItems = [];
  bool isLoading = true;

  List<String> categories = [
    'All',
    'Platter',
    'Drinks',
    'Appetizers',
    'Dessert',
  ];
  String selectedCategory = 'All';

  @override
  void initState() {
    super.initState();

    client = Client()
      ..setEndpoint('https://cloud.appwrite.io/v1')
      ..setProject('676506150033480a87c5');

    database = Databases(client);

    fetchItems();
  }

  Future<void> fetchItems() async {
    setState(() {
      isLoading = true;
    });
    try {
      final result = await database.listDocuments(
        databaseId: '67650e170015d7a01bc8',
        collectionId: '679914b6002ca53ab39b',
      );

      setState(() {
        items = result.documents.map((doc) {
          return {
            'documentId': doc.$id,
            'itemName': doc.data['FoodItemName'],
            'itemDescription': doc.data['Description'],
            'category': doc.data['Category'],
            'price': doc.data['Price'],
            'image': doc.data['ImageUrl'],
          };
        }).toList();

        filteredItems = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching items: $e')),
      );
    }
  }

  // Save cart details to the database
  void saveCartToDatabase(String itemName, String itemDescription, String price,
      String imageUrl) async {
    try {
      firebase_auth.User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        Fluttertoast.showToast(msg: 'Please log in to add items to cart');
        return;
      }

      // Check if the item already exists in the cart for this user
      final result = await database.listDocuments(
        databaseId: '67650e170015d7a01bc8',
        collectionId: '679e8489002cd468bb6b',
        queries: [
          Query.equal('Email', user.email ?? ''),
          Query.equal('cartItemName', itemName),
        ],
      );

      if (result.documents.isNotEmpty) {
        // Item is already in the cart

        return;
      }

      // Generate a unique ID for the cart item
      final String cartItemId = ID.unique();

      await database.createDocument(
        databaseId: '67650e170015d7a01bc8',
        collectionId: '679e8489002cd468bb6b',
        documentId: cartItemId,
        data: {
          'cartItemName': itemName,
          'cartDescription': itemDescription,
          'Price': double.tryParse(price) ?? 0.0,
          'ImageUrl': imageUrl,
          'Email': user.email ?? '',
        },
      );

      Fluttertoast.showToast(
        msg: '$itemName added to cart!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding item to cart: $e')),
      );
    }
  }

  void _filterItems(String query) {
    setState(() {
      filteredItems = items.where((item) {
        bool matchesSearch =
            item['itemName'].toLowerCase().contains(query.toLowerCase());
        bool matchesCategory =
            selectedCategory == 'All' || item['category'] == selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> body = [
      _homePage(),
      Mycart(),
      Myorder(),
      myprofile(),
    ];

    final List<String> appBarTitles = [
      'Available Food',
      'Cart',
      'Order History',
      'Profile',
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          appBarTitles[currentIndex],
          style: TextStyle(color: Colors.black),
        ),
        elevation: 1.0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh), // Reload icon
            onPressed: fetchItems, // Call reload function
          ),
        ],
      ),
      body: body[currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.shopping_cart), label: 'My Cart'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Order'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
        selectedIndex: currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _homePage() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Search Field
                        Flexible(
                          flex: 3,
                          child: TextField(
                            onChanged: _filterItems,
                            decoration: InputDecoration(
                              hintText: 'Item name',
                              hintStyle: TextStyle(color: Color(0xFFC8BEBE)),
                              filled: true,
                              fillColor: const Color(0x4EE4ECDD),
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        // Dropdown with fixed width
                        SizedBox(
                          width: 130, // Adjust as needed
                          child: DropdownButtonFormField<String>(
                            value: selectedCategory,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedCategory = newValue!;
                                _filterItems('');
                              });
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0x4EE4ECDD),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: categories.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: 0.5,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];

                      return Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 4.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.network(
                                  'https://cloud.appwrite.io/v1/storage/buckets/6784cf9d002262613d60/files/${item['image']}/view?project=676506150033480a87c5',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 120,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.error),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['itemName'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        item['itemDescription'],
                                        style: TextStyle(fontSize: 14),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        item['category'],
                                        style: TextStyle(fontSize: 14),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Price: ৳${item['price']}',
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .end, // Aligns the child to the right
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              // Show a toast when the button is pressed
                                              Fluttertoast.showToast(
                                                msg:
                                                    '${item['itemName']} added to cart!',
                                                toastLength: Toast.LENGTH_SHORT,
                                                gravity: ToastGravity.BOTTOM,
                                                backgroundColor: Colors.black,
                                                textColor: Colors.white,
                                                fontSize: 16.0,
                                              );

                                              // Save cart item to the database (you can pass the relevant details)
                                              saveCartToDatabase(
                                                item['itemName'],
                                                item['itemDescription'],
                                                item['price'].toString(),
                                                'https://cloud.appwrite.io/v1/storage/buckets/6784cf9d002262613d60/files/${item['image']}/view?project=676506150033480a87c5',
                                              );
                                            },
                                            child: Text(
                                              'ADD TO CART',
                                              style: TextStyle(
                                                color: Color(0xFFBB8506),
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
