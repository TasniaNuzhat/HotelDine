import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:uuid/uuid.dart';

class AddItem extends StatefulWidget {
  @override
  State<AddItem> createState() => _AddItem();
}

class _AddItem extends State<AddItem> {
  final itemName = TextEditingController();
  final itemDescription = TextEditingController();
  final itemCategory = TextEditingController();
  final itemPrice = TextEditingController();

  late Client client;
  late Databases database;
  late Storage storage;

  File? _image;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Initialize Appwrite Client
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

  void InsertedFood() async {
    if (_formKey.currentState?.validate() == true) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an image')),
        );
        return;
      }

      try {
        final String fileId = ID.unique();

        // Upload image
        models.File uploadedFile = await storage.createFile(
          bucketId: '6784cf9d002262613d60', // Replace with your bucket ID
          fileId: fileId,
          file: InputFile.fromPath(path: _image!.path),
        );

        // Insert into database
        await database.createDocument(
          databaseId: '67650e170015d7a01bc8',
          collectionId: '679914b6002ca53ab39b',
          documentId: ID.unique(),
          data: {
            'FoodItemName': itemName.text,
            'Description': itemDescription.text,
            'Category': itemCategory.text,
            'Price': double.tryParse(itemPrice.text) ?? 0.0,
            'ImageUrl': uploadedFile.$id,
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item added successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding item: $e')),
        );
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
          icon: Icon(Icons.arrow_back),
        ),
        title: Text(
          'Add Food',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: itemName,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Item name',
                  hintStyle: TextStyle(color: Color(0xFFA2A2A2)),
                  filled: true,
                  fillColor: const Color(0xFFDCDCDC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Item name is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: itemDescription,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Item description',
                  hintStyle: TextStyle(color: Color(0xFFA2A2A2)),
                  filled: true,
                  fillColor: const Color(0xFFDCDCDC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Item description is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                items:
                    ['Platter', 'Drinks', 'Appetizers', 'Dessert']
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                onChanged: (value) {
                  itemCategory.text = value ?? '';
                },
                decoration: InputDecoration(
                  hintText: 'Item category',
                  hintStyle: TextStyle(color: Color(0xFFA2A2A2)),
                  filled: true,
                  fillColor: const Color(0xFFDCDCDC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Item category is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: itemPrice,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Item price',
                  hintStyle: TextStyle(color: Color(0xFFA2A2A2)),
                  filled: true,
                  fillColor: const Color(0xFFDCDCDC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Item price is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
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
                onPressed: InsertedFood,
                child: Text(
                  'Insert Item',
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
      ),
    );
  }

  @override
  void dispose() {
    itemName.dispose();
    itemDescription.dispose();
    itemPrice.dispose();
    super.dispose();
  }
}
