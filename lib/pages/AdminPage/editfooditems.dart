import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';

class FoodItemsEdit extends StatefulWidget {
  final String documentId;

  const FoodItemsEdit({Key? key, required this.documentId}) : super(key: key);

  @override
  State<FoodItemsEdit> createState() => _FoodItemsEditState();
}

class _FoodItemsEditState extends State<FoodItemsEdit> {
  late Client client;
  late Databases database;
  final _formKey = GlobalKey<FormState>(); // Key for the form

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  bool isLoading = true;
  String? _selectedCategory;
  final List<String> categories = [
    'Platter',
    'Drinks',
    'Appetizers',
    'Dessert',
  ];

  @override
  void initState() {
    super.initState();

    client = Client()
      ..setEndpoint('https://cloud.appwrite.io/v1')
      ..setProject('676506150033480a87c5');

    database = Databases(client);
    fetchItemDetails();
  }

  Future<void> fetchItemDetails() async {
    try {
      final document = await database.getDocument(
        databaseId: '67650e170015d7a01bc8',
        collectionId: '679914b6002ca53ab39b',
        documentId: widget.documentId,
      );

      setState(() {
        _nameController.text = document.data['FoodItemName'];
        _descriptionController.text = document.data['Description'];
        _selectedCategory = document.data['Category'];
        _priceController.text = document.data['Price'].toString();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching item details: $e')),
      );
    }
  }

  Future<void> updateItemDetails() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await database.updateDocument(
        databaseId: '67650e170015d7a01bc8',
        collectionId: '679914b6002ca53ab39b',
        documentId: widget.documentId,
        data: {
          'FoodItemName': _nameController.text,
          'Description': _descriptionController.text,
          'Category': _selectedCategory,
          'Price': double.parse(_priceController.text), // Ensure valid price
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating item: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Item'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Name Field
                      const Text('Item Name',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      TextFormField(
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Item name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description Field
                      const Text('Description',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      TextFormField(
                        controller: _descriptionController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Description is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Category Dropdown
                      const Text('Category',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        hint: const Text('Select Category'),
                        isExpanded: true,
                        items: categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Price Field
                      const Text('Price',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          double? price = double.tryParse(value ?? '');
                          if (price == null || price <= 0) {
                            return 'Price must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Save Changes Button
                      Center(
                        child: ElevatedButton(
                          onPressed: updateItemDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 10),
                          ),
                          child: const Text('Save Changes',
                              style: TextStyle(color: Colors.white)),
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
