import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:appwrite/models.dart' as appwrite_models;

import 'changepassword.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailAddressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;

  bool isLoading = true;
  late Client client;
  late Databases database;
  Map<String, String> user = {};

  @override
  void initState() {
    super.initState();

    // Initialize Appwrite client
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
        Fluttertoast.showToast(msg: 'Please log in to view and edit profile');
        setState(() => isLoading = false);
        return;
      }

      // Fetch all documents from Appwrite
      final response = await database.listDocuments(
        databaseId: '67650e170015d7a01bc8', // Replace with your database ID
        collectionId: '67650e290037f19f628f', // Replace with your collection ID
      );

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
          };
        });
      } else {
        setState(() {
          user = {
            'name': userDoc?.data["fullName"] ?? 'Name not available',
            'email': userDoc?.data['email'] ?? 'Email not available',
            'phone': userDoc?.data['phone'] ?? 'Phone number not available',
          };
          nameController.text = user['name']!;
          emailAddressController.text = user['email']!;
          phoneController.text = user['phone']!;
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

  // Update profile data in Appwrite
  Future<void> updateProfileData() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        firebase_auth.User? firebaseUser =
            firebase_auth.FirebaseAuth.instance.currentUser;

        if (firebaseUser == null) {
          Fluttertoast.showToast(msg: 'Please log in to update your profile');
          setState(() {
            isLoading = false;
          });
          return;
        }

        // Fetch the latest user document
        final response = await database.listDocuments(
          databaseId: '67650e170015d7a01bc8',
          collectionId: '67650e290037f19f628f',
        );

        appwrite_models.Document? userDoc;
        try {
          userDoc = response.documents.firstWhere(
            (doc) => doc.data['email'] == firebaseUser.email,
          );
        } catch (e) {
          userDoc = null;
        }

        // Ensure userDoc is not null
        if (userDoc == null) {
          Fluttertoast.showToast(msg: 'User document not found!');
          setState(() {
            isLoading = false;
          });
          return;
        }

        String documentId = userDoc.$id;

        final updateResponse = await database.updateDocument(
          databaseId: '67650e170015d7a01bc8',
          collectionId: '67650e290037f19f628f',
          documentId: documentId,
          data: {
            'fullName': nameController.text,
            'email': emailAddressController.text,
            'phone': phoneController.text,
          },
        );
        print("Update Response: ${updateResponse.data}");

        Fluttertoast.showToast(msg: 'Profile updated successfully');
        setState(() {
          isLoading = false;
        });

        Navigator.pop(context);
      } catch (e) {
        setState(() => isLoading = false);
        Fluttertoast.showToast(msg: 'Error updating profile: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Email Field
                TextFormField(
                  controller: emailAddressController,
                  keyboardType: TextInputType.emailAddress,
                  readOnly: true,
                  style: const TextStyle(color: Color(0xFF808080)),
                  decoration: InputDecoration(
                    hintText: 'Email address',
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: nameController,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    hintText: 'Full Name',
                    filled: true,
                    fillColor: const Color(0xFFDCDCDC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Phone number',
                    filled: true,
                    fillColor: const Color(0xFFDCDCDC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ChangePasswordPage()),
                      );
                    },
                    child: const Text(
                      'Change Password',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                const SizedBox(height: 20),

                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await updateProfileData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Profile updated successfully!')),
                        );
                      }
                    },
                    child: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
