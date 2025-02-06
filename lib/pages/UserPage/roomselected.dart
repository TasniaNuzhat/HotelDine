import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:hoteldineflutter/pages/UserPage/chooseroom.dart';
import 'package:intl/intl.dart';

class RoomSelected extends StatefulWidget {
  final Map<String, dynamic> room;
  final String checkInDate;
  final String checkOutDate;
  final int totalGuests;

  const RoomSelected({
    Key? key,
    required this.room,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalGuests,
  }) : super(key: key);

  @override
  _RoomSelectedState createState() => _RoomSelectedState();
}

class _RoomSelectedState extends State<RoomSelected> {
  late Client client;
  late Databases database;
  firebase_auth.User? currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  int totalNights = 0;
  double totalPrice = 0.0;

  // Payment-related variables
  String? _selectedPaymentMethod;
  final TextEditingController _transactionIdController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeAppwrite();
    getCurrentUser();
    calculateTotalPrice();
  }

  void initializeAppwrite() {
    client = Client()
      ..setEndpoint('https://cloud.appwrite.io/v1')
      ..setProject('676506150033480a87c5');

    database = Databases(client);
  }

  void getCurrentUser() {
    final FirebaseAuth auth = FirebaseAuth.instance;
    setState(() {
      currentUser = auth.currentUser;
    });

    if (currentUser != null) {
      fetchUserData(currentUser!.email);
    }
  }

  Future<void> fetchUserData(String? email) async {
    if (email == null) return;

    try {
      setState(() {
        isLoading = true;
      });

      final result = await database.listDocuments(
        databaseId: '67650e170015d7a01bc8',
        collectionId: '67650e290037f19f628f',
      );

      for (var doc in result.documents) {
        if (doc.data['email'] == email) {
          setState(() {
            userData = doc.data;
            isLoading = false;
          });
          break;
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> requestToBook(String? email) async {
    if (email == null) return;

    try {
      setState(() {
        isLoading = true;
      });

      await database.createDocument(
        databaseId: '67650e170015d7a01bc8',
        collectionId: '67a066880000448ec129',
        documentId: 'unique()',
        data: {
          'Name': userData?['fullName'] ?? '',
          'Phone': userData?['phone'] ?? '',
          'DateOfBirth': userData?['dob'] ?? '',
          'Check_in_Date': widget.checkInDate,
          'Check_out_date': widget.checkOutDate,
          'TotalPrice': totalPrice,
          'RoomNumber': widget.room?['roomNumber'] ?? 'N/A',
          'Email': email,
          'PaymentMethod': _selectedPaymentMethod ?? '',
          'TransactionID': _transactionIdController.text,
          'Status': 'Pending',
        },
      );

      setState(() {
        isLoading = false;
      });

      Navigator.push(
          context, MaterialPageRoute(builder: (context) => ChooseRoom()));
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to store: $e')));

      print("Error requesting to book: $e");
    }
  }

  void calculateTotalPrice() {
    try {
      DateTime checkIn = DateFormat('yyyy-MM-dd').parse(widget.checkInDate);
      DateTime checkOut = DateFormat('yyyy-MM-dd').parse(widget.checkOutDate);
      int nights = checkOut.difference(checkIn).inDays;

      setState(() {
        totalNights = nights > 0 ? nights : 1;
        totalPrice = totalNights *
            (widget.room['price'] is double
                ? widget.room['price'] as double
                : (widget.room['price'] as num).toDouble());
      });
    } catch (e) {
      print("Error calculating total price: $e");
    }
  }

  void reloadPage() {
    setState(() {
      isLoading = true;
    });
    initializeAppwrite();
    getCurrentUser();
    calculateTotalPrice();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Room'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: reloadPage,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isLoading) Center(child: CircularProgressIndicator()),

            // **User Details Card**
            if (userData != null) ...[
              Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User Details',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Divider(),
                      Text('Name: ${userData!['fullName'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 16)),
                      Text('Phone: ${userData!['phone'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 16)),
                      Text('Date of Birth: ${userData!['dob'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: 20),

            // **Room Details**
            Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Room Details',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Divider(),
                    Text('Room: ${widget.room['roomNumber'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 16)),
                    Text('Check-in: ${widget.checkInDate}',
                        style: TextStyle(fontSize: 16)),
                    Text('Check-out: ${widget.checkOutDate}',
                        style: TextStyle(fontSize: 16)),
                    Text('Total Nights: $totalNights',
                        style: TextStyle(fontSize: 16)),
                    Text('Total Price: $totalPrice',
                        style: TextStyle(fontSize: 16, color: Colors.red)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            Text('Payment Methods',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            SizedBox(height: 5),
            Text(
              'Number: 01714227495 (Bkash,Nagod,Rocket)',
              style: TextStyle(fontSize: 12),
            ),

            Row(
              children: [
                Radio<String>(
                  value: 'Bkash',
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) =>
                      setState(() => _selectedPaymentMethod = value),
                ),
                Image.asset('assets/images/bkash_logo.png',
                    width: 30, height: 30),
                SizedBox(width: 10),
              ],
            ),
            Row(
              children: [
                Radio<String>(
                  value: 'Nagad',
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) =>
                      setState(() => _selectedPaymentMethod = value),
                ),
                Image.asset('assets/images/nagad_logo.png',
                    width: 30, height: 30),
                SizedBox(width: 10),
              ],
            ),
            Row(
              children: [
                Radio<String>(
                  value: 'Rocket',
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) =>
                      setState(() => _selectedPaymentMethod = value),
                ),
                Image.asset('assets/images/rocket_logo.png',
                    width: 30, height: 30),
                SizedBox(width: 10),
              ],
            ),

            TextField(
              controller: _transactionIdController,
              decoration: InputDecoration(
                  labelText: 'Transaction ID', border: OutlineInputBorder()),
            ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Check if payment method is selected
                      if (_selectedPaymentMethod == null ||
                          _selectedPaymentMethod!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Please select a payment method.')),
                        );
                        return;
                      }

                      // Check if transaction ID is entered
                      if (_transactionIdController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Please enter a transaction ID.')),
                        );
                        return; // Prevent further execution if transaction ID is empty
                      }

                      // Proceed with booking request if validation is successful
                      await requestToBook(currentUser?.email);
                    },
              child: isLoading
                  ? CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF35AF14)))
                  : Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
