import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'dart:typed_data';
import 'package:hoteldineflutter/pages/AdminPage/editroom.dart';
import 'package:hoteldineflutter/pages/AdminPage/deleteroom.dart';

class ViewRoom extends StatefulWidget {
  @override
  _ViewRoomState createState() => _ViewRoomState();
}

class _ViewRoomState extends State<ViewRoom> {
  final List<Map<String, dynamic>> rooms = [];
  List<Map<String, dynamic>> filteredRooms = [];
  late Databases databases;
  late Storage storage;
  bool isLoading = true;
  final String databaseId = '67650e170015d7a01bc8';
  final String collectionId = '6784c4dd00332fc62aeb';

  @override
  void initState() {
    super.initState();
    initializeAppwrite();
    fetchRooms();
  }

  void initializeAppwrite() {
    Client client = Client()
        .setEndpoint('https://cloud.appwrite.io/v1')
        .setProject('676506150033480a87c5');
    databases = Databases(client);
    storage = Storage(client);
  }

  void _filterRooms(String query) {
    setState(() {
      filteredRooms = query.isEmpty
          ? rooms
          : rooms.where((room) {
              // Convert the query to lowercase for case-insensitive matching
              String lowerCaseQuery = query.toLowerCase();
              String category = room['category'].toLowerCase();
              String roomNumber = room['roomNumber'].toString();

              List<String> queryWords = lowerCaseQuery.split(' ');
              String firstWord = queryWords.first;
              List<String> remainingWords =
                  queryWords.skip(1).toList(); // Remaining words in the query

              bool firstWordMatches =
                  category.split(' ').first.contains(firstWord);

              bool remainingWordsMatch = remainingWords.every((word) {
                return category.contains(word);
              });

              return (firstWordMatches && remainingWordsMatch) ||
                  roomNumber.contains(query);
            }).toList();
    });
  }

  Future<void> fetchRooms() async {
    try {
      DocumentList documentList = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
      );

      setState(() {
        rooms.clear();
        for (var doc in documentList.documents) {
          rooms.add({
            'roomNumber': doc.data['RoomNumber'],
            'roomName': doc.data['RoomName'],
            'description': doc.data['RoomDescription'],
            'category': doc.data['RoomCategory'],
            'price': doc.data['price'],
            'image': doc.data['ImageUrl'],
            'documentId': doc.$id,
          });
        }
        filteredRooms = rooms;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching rooms: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _reloadRooms() async {
    setState(() {
      isLoading = true; // Set loading state to true
    });
    await fetchRooms(); // Reload data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('View Room'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh), // Reload icon
            onPressed: _reloadRooms, // Call reload function
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterRooms,
              decoration: InputDecoration(
                hintText: 'Search by room number or category',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: const Color(0xFFDCDCDC),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredRooms.length,
              itemBuilder: (context, index) {
                final room = filteredRooms[index];
                return Card(
                  color: Color(0xFFE9FBFF),
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // First Column: Room details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Room no. ${room['roomNumber']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    room['roomName'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Non-refundable',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    room['description'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.free_breakfast,
                                        color: Colors.green,
                                        size: 16,
                                      ), // Breakfast icon
                                      SizedBox(width: 8),
                                      Text(
                                        'Breakfast included',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.bathtub,
                                        color: Colors.green,
                                        size: 16,
                                      ), // Bathroom icon
                                      SizedBox(width: 8),
                                      Text(
                                        'Private Bathroom',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.wifi,
                                        color: Colors.green,
                                        size: 16,
                                      ), // WiFi icon
                                      SizedBox(width: 8),
                                      Text(
                                        'Free WiFi',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    room['category'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'BDT ${room['price']}/Night',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  Text(
                                    '*Price includes VAT and tax',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            // Second Column: Edit and Delete buttons
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    IconButton(
                                      icon:
                                          Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditRoom(
                                              roomNumber: room['roomNumber'],
                                            ),
                                          ),
                                        );
                                        if (result == true) {
                                          _reloadRooms(); // Reload rooms after editing
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DeleteRoom(
                                              roomNumber: room['roomNumber'],
                                            ),
                                          ),
                                        );
                                        if (result == true) {
                                          _reloadRooms(); // Reload rooms after deletion
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: FutureBuilder<Uint8List>(
                                    future: storage.getFileDownload(
                                      bucketId: '6784cf9d002262613d60',
                                      fileId: room['image'],
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      } else if (snapshot.hasError) {
                                        return Icon(Icons.error);
                                      } else if (snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!,
                                          height: 120,
                                          width: 120,
                                          fit: BoxFit.cover,
                                        );
                                      } else {
                                        return Icon(Icons.image_not_supported);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                        // Image below the row
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
