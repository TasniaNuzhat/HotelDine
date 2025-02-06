import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart'; // Import Appwrite SDK
import 'package:appwrite/models.dart';
import 'package:hoteldineflutter/pages/AdminPage/viewroom.dart'; // For Appwrite models

class EditRoom extends StatefulWidget {
  final String roomNumber;

  EditRoom({required this.roomNumber});

  @override
  _EditRoomState createState() => _EditRoomState();
}

class _EditRoomState extends State<EditRoom> {
  late Databases databases;
  late Storage storage;
  late Client client;

  final String databaseId = '67650e170015d7a01bc8';
  final String collectionId = '6784c4dd00332fc62aeb';

  Map<String, dynamic>? roomData;
  bool isLoading = true;
  String selectedCategory = '';

  @override
  void initState() {
    super.initState();
    initializeAppwrite();
    fetchRoomData();
  }

  // Initialize Appwrite Client
  void initializeAppwrite() {
    client = Client();
    client
        .setEndpoint('https://cloud.appwrite.io/v1')
        .setProject('676506150033480a87c5');
    databases = Databases(client);
    storage = Storage(client);
  }

  // Fetch room data based on the room number
  Future<void> fetchRoomData() async {
    try {
      DocumentList documentList = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: [
          Query.equal('RoomNumber', widget.roomNumber),
        ],
      );

      if (documentList.documents.isNotEmpty) {
        setState(() {
          roomData = documentList.documents.first.data;
          selectedCategory = roomData!['RoomCategory'];

          isLoading = false;
        });
      } else {
        setState(() {
          roomData = null;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching room data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Edit Room'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : roomData == null
              ? Center(child: Text('Room not found'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          initialValue: roomData!['RoomNumber'],
                          decoration: InputDecoration(
                            labelText: 'Room Number',
                          ),
                          readOnly: true,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          initialValue: roomData!['RoomName'],
                          decoration: InputDecoration(
                            labelText: 'Room Name',
                          ),
                          onChanged: (value) {
                            setState(() {
                              roomData!['RoomName'] = value;
                            });
                          },
                        ),
                        SizedBox(height: 16),
                        // Dropdown for Room Category (AC / Non-AC)
                        DropdownButtonFormField<String>(
                          value: selectedCategory.isEmpty
                              ? null
                              : selectedCategory,
                          items: ['Air Conditioning', 'Non Air Conditioning']
                              .map((category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value ?? '';
                              roomData!['RoomCategory'] =
                                  selectedCategory; // Update the category in roomData
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Room Category',
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          initialValue: roomData!['RoomDescription'],
                          decoration: InputDecoration(
                            labelText: 'Room Description',
                          ),
                          onChanged: (value) {
                            setState(() {
                              roomData!['RoomDescription'] = value;
                            });
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          initialValue: roomData!['price'].toString(),
                          decoration: InputDecoration(
                            labelText: 'Room Price',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              roomData!['price'] =
                                  double.tryParse(value) ?? 0.0;
                            });
                          },
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            await saveRoomData();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ViewRoom()),
                            );
                          },
                          child: Text('Save Changes'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  // Save the updated room data to Appwrite
  Future<void> saveRoomData() async {
    try {
      String documentId = roomData!['\$id'];

      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
        data: {
          'RoomName': roomData!['RoomName'],
          'RoomDescription': roomData!['RoomDescription'],
          'price': roomData!['price'],
          'RoomCategory': roomData!['RoomCategory'],
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room updated successfully')),
      );
    } catch (e) {
      print('Error updating room: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating room: $e')),
      );
    }
  }
}
