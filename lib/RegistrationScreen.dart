import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_shopping_app_task/LoginScreen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;


class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  TextEditingController _nameController = TextEditingController();
  TextEditingController _contactController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _pinCodeController = TextEditingController();
  TextEditingController _stateController = TextEditingController();
  TextEditingController _cityController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  PickedFile? _addressProof;
  String? _verificationId;

  Future<void> _fetchCityState(String pinCode) async {
    final response = await http.get(Uri.parse('http://www.postalpincode.in/api/pincode/$pinCode'));
    final data = json.decode(response.body);
    if (data['Status'] == 'Success') {
      setState(() {
        _cityController.text = data['PostOffice'][0]['District'];
        _stateController.text = data['PostOffice'][0]['State'];
      });
    } else {
      // Handle error
    }
  }

  Future<void> _uploadAddressProof() async {
    if (_addressProof != null) {
      final storageRef = FirebaseStorage.instance.ref().child('address_proofs/${_contactController.text}');
      await storageRef.putFile(File(_addressProof!.path));
    }
  }

  Future<void> _registerCustomer() async {
    if (_formKey.currentState!.validate()) {
      final userDoc = await _firestore.collection('Customers').doc(_contactController.text).get();

      if (userDoc.exists) {
        // User already exists, show dialog to login
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('User Exists'),
            content: Text('This contact number is already registered. Please log in.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => LoginScreen()));
                },
                child:
                Text('Login', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        );
      } else {



        await _uploadAddressProof();
        String? token = await FirebaseMessaging.instance.getToken();
        await _firestore.collection('Customers').doc(_contactController.text).set({
          'customerName': _nameController.text,
          'contactNumber': _contactController.text,
          'emailId': _emailController.text,
          'pinCode': _pinCodeController.text,
          'state': _stateController.text,
          'city': _cityController.text,
          'address': _addressController.text,
          'password': _passwordController.text,
          'fcmToken': token
        });



        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('User Register Successfully'),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => LoginScreen()));
                },
                child:
                Text('Login', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        );
        print("User Added");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Registration'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => LoginScreen()));
            },
            child:  Icon(Icons.login,color: Colors.black,),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Customer Name'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(labelText: 'Contact Number'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter contact number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email ID'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter email ID';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _pinCodeController,
                decoration: InputDecoration(labelText: 'Pin Code'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter pin code';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value.length == 6) {
                    _fetchCityState(value);
                  }
                },
              ),
              TextFormField(
                controller: _stateController,
                decoration: InputDecoration(labelText: 'State'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter state';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(labelText: 'City'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter city';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Address'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter password';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  setState(() {
                    _addressProof = pickedFile as PickedFile?;
                  });
                },
                child: Text('Upload Address Proof'),
              ),
              ElevatedButton(
                onPressed: _registerCustomer,
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
