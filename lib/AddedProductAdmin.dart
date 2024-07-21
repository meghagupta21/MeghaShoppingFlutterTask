import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_firebase_shopping_app_task/OrderDeatailsScreenAdmin.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:uuid/uuid.dart';

class AdminProductMasterScreen extends StatefulWidget {
  final String? productId;
  final Map<String, dynamic>? existingProductData;

  AdminProductMasterScreen({this.productId, this.existingProductData});

  @override
  _AdminProductMasterScreenState createState() => _AdminProductMasterScreenState();
}

class _AdminProductMasterScreenState extends State<AdminProductMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  TextEditingController _productNameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _rateController = TextEditingController();
  File? _productImage;

  @override
  void initState() {
    super.initState();
    if (widget.existingProductData != null) {
      _productNameController.text = widget.existingProductData!['productName'];
      _descriptionController.text = widget.existingProductData!['description'];
      _rateController.text = widget.existingProductData!['rate'];
    }
  }

  Future<void> _addOrUpdateProduct() async {
    if (_formKey.currentState!.validate()) {
      String imageUrlSet = '';
      // Handle image upload
      if (_productImage != null) {
        UploadTask uploadTask = FirebaseStorage.instance.ref().child('product_images/${_productNameController.text}').child(Uuid().v1()).putFile(File(_productImage!.path));
       TaskSnapshot taskSnapshot=await uploadTask;
        String imageUrl=await taskSnapshot.ref.getDownloadURL();
      // setState(()async {
      //   imageUrl=await taskSnapshot.ref.getDownloadURL();
      // });
        setState(() {
          imageUrlSet=imageUrl;
        });
      }

      final productData = {
        'productName': _productNameController.text,
        'description': _descriptionController.text,
        'rate': _rateController.text,
        'imageUrl': imageUrlSet, // Add image URL if available
      };

      if (widget.productId == null) {
        await _firestore.collection('Products').add(productData);
      } else {
        await _firestore.collection('Products').doc(widget.productId).update(productData);
      }
      setState(() {
        _productImage=null;
      });
      Navigator.of(context).pop();

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null ? 'Add Product' : 'Edit Product'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _productNameController,
                decoration: InputDecoration(labelText: 'Product Name'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _rateController,
                decoration: InputDecoration(labelText: 'Rate'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter rate';
                  }
                  return null;
                },
              ),
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    File convertedFile = File(pickedFile.path);
                    setState(() {
                      _productImage = convertedFile;
                    });
                  }
                },
                child: Text('Upload Product Image'),
              ),
              SizedBox(width: 10), // Add some spacing between the button and the image
              _productImage != null
                  ? Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Image.file(
                  _productImage!,
                  fit: BoxFit.cover,
                ),
              )
                  : Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Center(child: Text('No Image')),
              ),
            ],
          ),

          ElevatedButton(
                onPressed: _addOrUpdateProduct,
                child: Text(widget.productId == null ? 'Add Product' : 'Update Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
