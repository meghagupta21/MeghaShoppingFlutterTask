import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetailScreen extends StatelessWidget {
  final String customerId;
  final String orderId;
  final Map<String, dynamic> orderData;

  OrderDetailScreen({required this.customerId, required this.orderId, required this.orderData});

  Future<void> _updateOrderStatus(String status) async {
    await FirebaseFirestore.instance
        .collection('Customers')
        .doc(customerId)
        .collection('Orders')
        .doc(orderId)
        .update({'status': status});
    // Send notification to customer (you can implement this using Firebase Cloud Messaging)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shipping Address: ${orderData['shippingAddress']}'),
            Text('Contact Number: ${orderData['contactNumber']}'),
            Text('Delivery Date: ${orderData['deliveryDate']}'),
            Text('Delivery Time: ${orderData['deliveryTime']}'),
            SizedBox(height: 16.0),
            Text('Products:'),
            ...orderData['products'].map<Widget>((product) {
              return Text('${product['productName']} (x${product['quantity']})');
            }).toList(),
            SizedBox(height: 16.0),
            Text('Payment Status: ${orderData['status']}'),
            SizedBox(height: 16.0),
            // ElevatedButton(
            //   onPressed: () {
            //     _updateOrderStatus('Accepted');
            //   },
            //   child: Text('Accept Order'),
            // ),
            // ElevatedButton(
            //   onPressed: () {
            //     _updateOrderStatus('Rejected');
            //   },
            //   child: Text('Reject Order'),
            // ),
          ],
        ),
      ),
    );
  }
}
