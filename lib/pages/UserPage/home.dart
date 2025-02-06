import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Database/database.dart';
import 'package:hoteldineflutter/pages/UserPage/chooseroom.dart';
import 'package:hoteldineflutter/pages/UserPage/availablefoods.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoteldineflutter/pages/login.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  Future<Map<String, dynamic>> getUserData(String email) async {
    try {
      // Fetch user data from the Appwrite database
      final userCollection = databaseService.getCollection('Users');
      final response = await userCollection['list'](
        queries: [
          'equal("email", "$email")', // Query to match email
          print('Error fetching user data: $email')
        ],
      );
      final documents = response.documents;
      if (documents.isNotEmpty) {
        return documents.first.data; // Return the first matching document
      }
      return {};
    } catch (e) {
      print('Error fetching user data: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: user != null
            ? FutureBuilder<Map<String, dynamic>>(
                future: getUserData(user.email!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError || snapshot.data == null) {
                    return const Center(
                        child: Text('Error loading user data.'));
                  }

                  final userData = snapshot.data!;
                  final name = userData['fullName'] ?? 'Guest';
                  final emailAddress = userData['email'] ?? 'No email';
                  final profilePhoto = userData['profilePhoto'];

                  return Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            width: 452,
                            height: 296,
                            decoration: BoxDecoration(
                              image: const DecorationImage(
                                image: AssetImage('assets/images/welcome.png'),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 48),
                                  child: Text(
                                    'Hey Mr/Mrs! ',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.white,
                                          blurRadius: 4.0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 48),
                                  child: Text(
                                    'Discover your perfect place',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Choose your option",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Hotel Option
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Image.asset(
                                "assets/images/hotel.png",
                                width: 386,
                                height: 186,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Our Awesome Hotel",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ChooseRoom()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF19A7FE),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 47,
                                    vertical: 3,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Explore Rooms",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(
                                        width:
                                            8), // Add spacing between text and icon
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Restaurant Option
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Image.asset(
                                "assets/images/restaurant.png",
                                width: 386,
                                height: 186,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Our Awesome Restaurant",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Availablefoods()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF19A7FE),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 47,
                                    vertical: 3,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Explore Menu",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(
                                        width:
                                            8),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Logout button
                        ],
                      ),
                    ),
                  );
                },
              )
            : const Center(child: Text('No user logged in.')),
      ),
    );
  }
}
