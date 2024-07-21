import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_shopping_app_task/AddedProductAdmin.dart';
import 'package:flutter_firebase_shopping_app_task/HomeScreen.dart';
import 'AdminScreen.dart';
import 'ProductScreen.dart';
import 'RegistrationScreen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  TextEditingController _contactController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    if (_contactController.text == "1231231233" && _passwordController.text == "123") {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => ProductAdminListScreen()));
    } else if (_formKey.currentState!.validate()) {
      final querySnapshot = await _firestore
          .collection('Customers')
          .where('contactNumber', isEqualTo: _contactController.text)
          .where('password', isEqualTo: _passwordController.text)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userId = querySnapshot.docs[0].id; // Get the user ID

        print('Login Successful');
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen(user_id: userId)));

      } else {
        // Show error message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Login Failed'),
            content: Text('Invalid contact number or password'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Login'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
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
                onPressed: _login,
                child: Text('Login'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => RegistrationScreen()));
                },
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
