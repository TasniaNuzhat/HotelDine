import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hoteldineflutter/pages/UserPage/editprofile.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../login.dart';

class myprofile extends StatefulWidget {
  @override
  _MyProfileState createState() => _MyProfileState();
}

class _MyProfileState extends State<myprofile> {
  late Client client;
  late Databases database;
  bool isLoading = true;
  Map<String, String> user = {};

  @override
  void initState() {
    super.initState();

    client = Client()
      ..setEndpoint('https://cloud.appwrite.io/v1')
      ..setProject('676506150033480a87c5');

    database = Databases(client);

    fetchUserData();
  }

  Future<void> fetchUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get the current user from Firebase
      firebase_auth.User? firebaseUser =
          firebase_auth.FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        setState(() => isLoading = false);
        return;
      }

      // Fetch all documents from Appwrite
      final response = await database.listDocuments(
        databaseId: '67650e170015d7a01bc8',
        collectionId: '67650e290037f19f628f',
      );

      // Debugging: Print response
      print('Appwrite documents: ${response.documents}');

      // Find the document matching the user's email
      appwrite_models.Document? userDoc;
      try {
        userDoc = response.documents.firstWhere(
          (doc) => doc.data['email'] == firebaseUser.email,
        );
      } catch (e) {
        userDoc = null; // No document found
      }

      if (userDoc == null) {
        setState(() {
          isLoading = false;
          user = {
            'name': 'Name not available',
            'email': 'Email not available',
            'phone': 'Phone number not available',
            'dob': 'Date of birth not available',
          };
        });
      } else {
        setState(() {
          user = {
            'name': userDoc?.data["fullName"] ?? 'Name not available',
            'email': userDoc?.data['email'] ?? 'Email not available',
            'phone': userDoc?.data['phone'] ?? 'Phone number not available',
            'dob': userDoc?.data['dob'] ?? 'Date of birth not available',
          };
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image Section
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black, width: 2),
                          image: DecorationImage(
                            image: AssetImage('assets/images/user_icon.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0), // Add horizontal padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Name: ${user['name']}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Email: ${user['email']}',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Phone: ${user['phone']}',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Date of Birth: ${user['dob']}',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Edit Profile Button
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfile(),
                          ),
                        );
                      },
                      child: Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blueAccent,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),

                    // Logout Button
                    ElevatedButton(
                      onPressed: () async {
                        bool confirmLogout = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text("Confirm Logout"),
                                  content: const Text(
                                      "Are you sure you want to log out?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context)
                                          .pop(false), // Cancel
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context)
                                          .pop(true), // Confirm
                                      child: const Text(
                                        "Logout",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ) ??
                            false; // Default to false if dialog is dismissed

                        if (confirmLogout) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear(); // Clear login session
                          await FirebaseAuth.instance
                              .signOut(); // Sign out from Firebase

                          // Navigate to login page
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => login()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE70A0A),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 47, vertical: 3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        minimumSize: const Size(double.infinity, 36),
                      ),
                      child: const Text(
                        'Log out',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
