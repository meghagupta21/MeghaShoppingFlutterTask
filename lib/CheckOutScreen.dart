import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckoutScreen extends StatefulWidget {
  final String userId;
  final double totalAmount;
  final List<Map<String, dynamic>> cartItems;

  CheckoutScreen({required this.userId, required this.totalAmount, required this.cartItems});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late Razorpay _razorpay;
  final _addressController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _deliveryDateController = TextEditingController();
  final _deliveryTimeController = TextEditingController();
  String _selectedPaymentMethod = 'Pay on Delivery';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWalletSelected);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _initializeDefaults() {
    final currentDate = DateTime.now();
    final deliveryDate = currentDate.add(Duration(days: 2)); // Default to 2 days from now
    final formattedDate = DateFormat('yyyy-MM-dd').format(deliveryDate);

    _deliveryDateController.text = formattedDate;
    _deliveryTimeController.text = '10:00 AM'; // Default time
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Fluttertoast.showToast(msg: "Payment Successful: ${response.paymentId}");
    _addOrderToFirestore(paymentStatus: 'Success', paymentId: response.paymentId);
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    Fluttertoast.showToast(msg: "Payment Failed: ${response.message}");
    _addOrderToFirestore(paymentStatus: 'Failed');
  }

  void _handleExternalWalletSelected(ExternalWalletResponse response) {
    Fluttertoast.showToast(msg: "External Wallet Selected: ${response.walletName}");
  }

  void _placeOrder() {
    if (_addressController.text.isEmpty ||
        _contactNumberController.text.isEmpty ||
        _deliveryDateController.text.isEmpty ||
        _deliveryTimeController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill all the details';
      });
      return;
    }

    if (_selectedPaymentMethod == 'Online') {
      _openCheckout();
    } else {
      _addOrderToFirestore(paymentStatus: 'Pending');
      Fluttertoast.showToast(msg: "Order placed successfully with Pay on Delivery");
    }
  }

  void _openCheckout() {
    double amountInPaise = widget.totalAmount * 100; // Convert to paise
    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag',
      'amount': amountInPaise,
      'name': 'Your Shop Name',
      'description': 'Order Payment',
      'prefill': {
        'contact': _contactNumberController.text,
        'email': 'guptameghamanoj@gmail.com',
      },
      'external': {
        'wallets': ['paytm'],
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _addOrderToFirestore({required String paymentStatus, String? paymentId}) {
    List<Map<String, dynamic>> products = widget.cartItems.map((item) {
      return {
        'productId': item['product_id'],
        'productName': item['product_name'],
        'quantity': item['quantity'],
      };
    }).toList();

    final orderData = {
      'shippingAddress': _addressController.text,
      'contactNumber': _contactNumberController.text,
      'deliveryDate': _deliveryDateController.text,
      'deliveryTime': _deliveryTimeController.text,
      'products': products, // Use the products list created from cartItems
      'totalAmount': widget.totalAmount,
      'status': paymentStatus,
    };

    FirebaseFirestore.instance
        .collection('Customers')
        .doc(widget.userId)
        .collection('Orders')
        .add(orderData)
        .then((_) {
      Fluttertoast.showToast(msg: "Order placed successfully");
      Navigator.of(context).pop(); // Navigate back after placing order
    }).catchError((error) {
      Fluttertoast.showToast(msg: "Failed to place order: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Use SingleChildScrollView to avoid overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shipping Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: _contactNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: 'Contact Number'),
              ),
              TextField(
                controller: _deliveryDateController,
                decoration: InputDecoration(labelText: 'Delivery Date'),
                readOnly: true, // Make it read-only to prevent manual edits
              ),
              TextField(
                controller: _deliveryTimeController,
                decoration: InputDecoration(labelText: 'Delivery Time'),
              ),
              SizedBox(height: 20),
              Text('Payment Method', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Radio<String>(
                    value: 'Online',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value!;
                      });
                    },
                  ),
                  Text('Online'),
                  Radio<String>(
                    value: 'Pay on Delivery',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value!;
                      });
                    },
                  ),
                  Text('Pay on Delivery'),
                ],
              ),
              SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: TextStyle(color: Colors.red)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _placeOrder,
                child: Text('Place Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
