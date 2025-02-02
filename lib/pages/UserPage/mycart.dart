import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hoteldineflutter/pages/UserPage/availablefoods.dart';
import 'package:hoteldineflutter/pages/UserPage/restaurantpayment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class Mycart extends StatefulWidget {
  final String itemName;
  final String price;
  final String imageUrl;

  Mycart({
    required this.itemName,
    required this.price,
    required this.imageUrl,
  });

  @override
  MycartState createState() => MycartState();
}

class MycartState extends State<Mycart> {
  List<Map<String, dynamic>> cartItems = [];
  double totalAmount = 0.0;
  bool isLoading = false; // To control the visibility of the progress bar

  late Client client;
  late Databases database;
  late Storage storage;

  @override
  void initState() {
    super.initState();

    client = Client()
      ..setEndpoint('https://cloud.appwrite.io/v1')
      ..setProject('676506150033480a87c5');

    database = Databases(client);
    storage = Storage(client);

    fetchCartData(); // Fetch stored cart data when screen loads
  }

  Future<void> fetchCartData() async {
    setState(() {
      isLoading = true; // Show the progress bar when data is being fetched
    });

    try {
      // Get the current user from Firebase
      firebase_auth.User? user =
          firebase_auth.FirebaseAuth.instance.currentUser;

      if (user == null) {
        Fluttertoast.showToast(msg: 'Please log in to view cart data');
        return;
      }

      // Fetch all documents from Appwrite
      final response = await database.listDocuments(
        databaseId: '67650e170015d7a01bc8', // Replace with your database ID
        collectionId: '679e8489002cd468bb6b', // Replace with your collection ID
      );

      // Filter documents based on the current user's email
      setState(() {
        cartItems = response.documents.where((doc) {
          return doc.data['Email'] ==
              user.email; // Match email field in Appwrite with Firebase email
        }).map((doc) {
          return {
            'documentId': doc.$id,
            'cartItemName': doc.data['cartItemName'] ?? 'Unknown Item',
            'price': (doc.data['Price'] as num?)?.toDouble() ?? 0.0,
            'imageUrl': doc.data['ImageUrl'] ?? '',
            'quantity': (doc.data['Quantity'] as num?)?.toInt() ?? 1,
            'Email': doc.data['Email'],
          };
        }).toList();

        // Combine duplicate items with the same name and increase their quantity
        List<Map<String, dynamic>> updatedCartItems = [];
        for (var item in cartItems) {
          int existingIndex = updatedCartItems.indexWhere((existingItem) =>
              existingItem['cartItemName'] == item['cartItemName']);
          if (existingIndex == -1) {
            // Item doesn't exist in the list, add it
            updatedCartItems.add(item);
          } else {
            // Item exists, increase the quantity
            updatedCartItems[existingIndex]['quantity'] += item['quantity'];
          }
        }

        cartItems = updatedCartItems;

        // Recalculate the total amount
        totalAmount = cartItems.fold(
            0.0, (sum, item) => sum + (item['price'] * item['quantity']));
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching cart: $e')));
    } finally {
      setState(() {
        isLoading = false; // Hide the progress bar after the data is fetched
      });
    }
  }

  void updateQuantity(int index, int change) {
    setState(() {
      cartItems[index]['quantity'] += change;
      if (cartItems[index]['quantity'] < 1) {
        cartItems[index]['quantity'] = 1;
      }
      totalAmount = cartItems.fold(
          0.0, (sum, item) => sum + (item['price'] * item['quantity']));
    });
  }

  void removeItemFromCart(int index) async {
    try {
      // Get the document ID of the item you want to delete
      String documentId = cartItems[index]['documentId'];

      // Delete the item from the Appwrite database
      await database.deleteDocument(
        databaseId: '67650e170015d7a01bc8', // Replace with your database ID
        collectionId: '679e8489002cd468bb6b', // Replace with your collection ID
        documentId: documentId,
      );

      // Remove the item from the UI list
      setState(() {
        totalAmount -= cartItems[index]['price'] * cartItems[index]['quantity'];
        cartItems.removeAt(index);
      });

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Item removed from cart and database successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deleting item: $e')));
    }
  }

  Future<void> saveCartToDatabase() async {
    try {
      for (var item in cartItems) {
        await database.createDocument(
          databaseId: '67650e170015d7a01bc8',
          collectionId: '679d386f000950a1c082',
          documentId: ID.unique(),
          data: {
            'ItemName': item['cartItemName'],
            'Price': item['price'],
            'Quantity': item['quantity'],
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error saving cart: $e')));
    }
  }

  Future<void> _reloadCart() async {
    setState(() {
      isLoading = true; // Show the progress bar during reload
    });

    try {
      cartItems.clear();
      totalAmount = 0.0;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.remove('cart_items');
      setState(() {});
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Cart data has been cleared.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing cart data: $e')));
    } finally {
      setState(() {
        isLoading = false; // Hide the progress bar after reload
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (isLoading)
              Center(
                child: CircularProgressIndicator(), // Progress bar during load
              )
            else if (cartItems.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("You haven’t added anything to your cart!",
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Availablefoods()));
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFBB8506),
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: Text("Browse",
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    var item = cartItems[index];
                    return ListTile(
                      leading: Image.network(item['imageUrl'],
                          width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(item['cartItemName'],
                          style: TextStyle(color: Colors.black)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BDT ${item['price']}'),
                          Row(
                            children: [
                              IconButton(
                                  icon: Icon(Icons.remove_circle_outline,
                                      color: Colors.red),
                                  onPressed: () => updateQuantity(index, -1)),
                              Text('${item['quantity']}',
                                  style: TextStyle(fontSize: 18)),
                              IconButton(
                                  icon: Icon(Icons.add_circle_outline,
                                      color: Colors.green),
                                  onPressed: () => updateQuantity(index, 1)),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => removeItemFromCart(index)),
                    );
                  },
                ),
              ),
            if (cartItems.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Amount',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        Text('BDT ${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        saveCartToDatabase(); // Save the cart items to the database (if needed)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Paynow(
                              cartItems: cartItems, // Pass the cart items
                              totalAmount: totalAmount, // Pass the total amount
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFBB8506),
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text("Pay Now",
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
