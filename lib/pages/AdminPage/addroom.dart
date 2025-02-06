import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:appwrite/appwrite.dart'; // Import Appwrite SDK
import 'package:appwrite/models.dart' as models; // For Appwrite models
import 'package:uuid/uuid.dart';

import '../Database/database.dart';

class AddRoom extends StatefulWidget {
  @override
  State<AddRoom> createState() => _AddRoom();
}

class _AddRoom extends State<AddRoom> {
  final roomNumber = TextEditingController();
  final roomName = TextEditingController();
  final roomDescription = TextEditingController();
  final roomCategory = TextEditingController();
  final roomPrice = TextEditingController();
  int? selectedValue;

  File? _image;
  final ImagePicker _picker = ImagePicker();

  late Client client;
  late Databases database;
  late Storage storage;

  String? roomNumberError;

  @override
  void initState() {
    super.initState();

    client = Client()
      ..setEndpoint('https://cloud.appwrite.io/v1')
      ..setProject('676506150033480a87c5');

    database = Databases(client);
    storage = Storage(client);
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void InsertedRoom() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    // Check if the room number is already taken:
    try {
      final existingRooms = await database.listDocuments(
        databaseId: '67650e170015d7a01bc8',
        collectionId: '6784c4dd00332fc62aeb',
        queries: [
          Query.equal('RoomNumber', roomNumber.text),
        ],
      );

      if (existingRooms.documents.isNotEmpty) {
        setState(() {
          roomNumberError =
              'Room number is already used. Please choose a different one.';
        });
        return;
      }

      setState(() {
        roomNumberError = null;
      });

      final String fileId = ID.unique();

      try {
        // Upload the file to Appwrite Storage
        models.File uploadedFile = await storage.createFile(
          bucketId:
              '6784cf9d002262613d60', // Replace with your storage bucket ID
          fileId: fileId,
          file: InputFile.fromPath(path: _image!.path),
        );

        try {
          await database.createDocument(
            databaseId: '67650e170015d7a01bc8', // Your actual database ID
            collectionId: '6784c4dd00332fc62aeb', // Your actual collection ID
            documentId: ID.unique(), // Generate a unique ID for the document
            data: {
              'RoomNumber': roomNumber.text,
              'RoomName': roomName.text,
              'RoomDescription': roomDescription.text,
              'RoomCategory': roomCategory.text,
              'price': double.tryParse(roomPrice.text) ??
                  0.0, // Convert price to double
              'ImageUrl': fileId, // Store image file ID
            },
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Room added successfully')),
          );
          Navigator.pop(context);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding room 1: $e')),
          );
        }
      } catch (e) {
        print('Error uploading file: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding room 2: $e')),
        );
      }
    } catch (e) {
      print('Error checking room number uniqueness: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking room number uniqueness: $e')),
      );
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
          icon: Icon(Icons.arrow_back),
        ),
        title: Text(
          'Add room',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: roomNumber,
              keyboardType: TextInputType.number,
              readOnly: true, // Prevents manual editing
              decoration: InputDecoration(
                hintText: 'Room number eg. 1001',
                hintStyle: TextStyle(color: Color(0xFFA2A2A2)),
                filled: true,
                fillColor: Color(0xFFDCDCDC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: BorderSide.none,
                ),
                errorText: roomNumberError,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedValue,
                      hint: Text("Select"),
                      items: [10, 20, 30, 40, 50]
                          .map((int value) => DropdownMenuItem<int>(
                                value: value,
                                child: Text(value.toString()),
                              ))
                          .toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          selectedValue = newValue;
                          roomNumber.text = newValue != null ? '$newValue' : '';
                          roomNumberError =
                              null; // Clear error when selecting a prefix
                        });
                      },
                    ),
                  ),
                ),
              ),
              onTap: () async {
                if (selectedValue == null) {
                  Fluttertoast.showToast(msg: 'Please select a prefix first.');
                  return;
                }

                String? result = await showDialog(
                  context: context,
                  builder: (context) {
                    TextEditingController numberController =
                        TextEditingController();
                    return AlertDialog(
                      title: Text('Enter Room Number'),
                      content: TextField(
                        controller: numberController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            hintText: 'Enter at least 2 digits',
                            hintStyle: TextStyle(color: Colors.grey[500])),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, null);
                          },
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            String enteredText = numberController.text.trim();
                            if (enteredText.length >= 2 &&
                                RegExp(r'^\d+$').hasMatch(enteredText)) {
                              Navigator.pop(context, enteredText);
                            } else {
                              Fluttertoast.showToast(
                                  msg:
                                      "Enter at least 2 digits after the prefix.");
                            }
                          },
                          child: Text('Done'),
                        ),
                      ],
                    );
                  },
                );

                setState(() {
                  if (result != null && result.length >= 2) {
                    roomNumber.text = '$selectedValue$result';
                    roomNumberError = null; // Clear error on valid input
                  } else {
                    roomNumberError =
                        "Room number must have at least 2 digits after the prefix.";
                    roomNumber.text =
                        ''; // Reset room number if invalid input is given
                  }
                });
              },
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: roomName,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: 'Room name',
                hintStyle: TextStyle(color: Color(0xFFA2A2A2)),
                filled: true,
                fillColor: const Color(0xFFDCDCDC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: roomDescription,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: 'Room description',
                hintStyle: TextStyle(color: Color(0xFFA2A2A2)),
                filled: true,
                fillColor: const Color(0xFFDCDCDC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              items: ['Air Conditioning', 'Non Air Conditioning']
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                roomCategory.text = value ?? '';
              },
              decoration: InputDecoration(
                hintText: 'Room category',
                hintStyle: TextStyle(color: Color(0xFFA2A2A2)),
                filled: true,
                fillColor: const Color(0xFFDCDCDC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: roomPrice,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Room price',
                hintStyle: TextStyle(color: Color(0xFFA2A2A2)),
                filled: true,
                fillColor: const Color(0xFFDCDCDC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 24),
            Container(
              width: 137,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: _image != null
                    ? DecorationImage(
                        image: FileImage(_image!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text(
                'Select Image',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF19A7FE),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: InsertedRoom,
              child: Text(
                'Insert Room',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5870E8),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    roomNumber.dispose();
    roomName.dispose();
    roomDescription.dispose();
    roomCategory.dispose();
    roomPrice.dispose();
    super.dispose();
  }
}
