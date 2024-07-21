import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class OrderListScreenAdmin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order List'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Customers').snapshots(),
        builder: (context, customerSnapshot) {
          if (customerSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!customerSnapshot.hasData || customerSnapshot.data!.docs.isEmpty) {
            return Center(child: Text('No customers available.'));
          }

          final customerDocs = customerSnapshot.data!.docs;

          return ListView.builder(
            itemCount: customerDocs.length,
            itemBuilder: (context, customerIndex) {
              final customerDoc = customerDocs[customerIndex];
              final customerId = customerDoc.id;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Customers')
                    .doc(customerId)
                    .collection('Orders')
                    .snapshots(),
                builder: (context, orderSnapshot) {
                  if (orderSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final orderDocs = orderSnapshot.data!.docs;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer ID: $customerId', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ListView.builder(
                        shrinkWrap: true, // Important to prevent infinite height error
                        physics: NeverScrollableScrollPhysics(), // Prevent scrolling inside the inner ListView
                        itemCount: orderDocs.length,
                        itemBuilder: (context, orderIndex) {
                          final orderDoc = orderDocs[orderIndex];
                          final orderData = orderDoc.data() as Map<String, dynamic>;

                          return ListTile(
                            title: Text('Order ID: ${orderDoc.id}'),
                            subtitle: Text('Total Amount: ${orderData['totalAmount']}'),
                            trailing: IconButton(
                              icon: Icon(Icons.arrow_forward),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => OrderDetailScreenAdmin(
                                      customerId: customerId,
                                      orderId: orderDoc.id,
                                      orderData: orderData,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      Divider(), // To separate orders of different customers
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}



class OrderDetailScreenAdmin extends StatelessWidget {
  final String customerId;
  final String orderId;
  final Map<String, dynamic> orderData;

  OrderDetailScreenAdmin({
    required this.customerId,
    required this.orderId,
    required this.orderData,
  });

  void _updateOrderStatus(BuildContext context, String status) async {
    try {
      // Update order status in Firestore
      await FirebaseFirestore.instance
          .collection('Customers')
          .doc(customerId)
          .collection('Orders')
          .doc(orderId)
          .update({'status': status});

      // Get the customer's FCM token
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('Customers')
          .doc(customerId)
          .get();

      String? fcmToken = customerDoc['fcmToken']; // Assuming you store the token under 'fcmToken'

      // Send a notification if the token exists
      if (fcmToken != null) {
        await _sendNotification(fcmToken, 'Order Update', 'Your order has been $status.');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $status')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order status: $error')),
      );
    }
  }

  Future<void> _sendNotification(String token, String title, String body) async {
    final String serverKey = "AIzaSyC68BHaZEpOxz4lKiWuEC8grNlllBdmLtw";
    print('sending notification: ');
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(
          {
            'notification': <String, dynamic>{
              'title': title,
              'body': body,
            },
            'priority': 'high',
            'registration_ids': [token],
          },
        ),
      );
      print('sending notification: ');

    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    List products = orderData['products'] as List;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer Name: ${orderData['customerName']}', style: TextStyle(fontSize: 18)),
              Text('Shipping Address: ${orderData['shippingAddress']}', style: TextStyle(fontSize: 18)),
              Text('Contact Number: ${orderData['contactNumber']}', style: TextStyle(fontSize: 18)),
              Text('Delivery Date: ${orderData['deliveryDate']}', style: TextStyle(fontSize: 18)),
              Text('Delivery Time: ${orderData['deliveryTime']}', style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              Text('Products:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true, // Use this to make the ListView.builder work inside a Column
                physics: NeverScrollableScrollPhysics(), // Prevent scrolling inside
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index] as Map<String, dynamic>;
                  return ListTile(
                    title: Text(product['productName'] ?? ''),
                    subtitle: Text('Quantity: ${product['quantity'] ?? ''}'),
                    trailing: Text('Price: ${product['total_price'] ?? ''}'),
                  );
                },
              ),
              SizedBox(height: 20),
              Text('Total Amount: ${orderData['totalAmount']}', style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              Text('Payment Status: ${orderData['paymentStatus']}', style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              Text('Order Status: ${orderData['status']}', style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () => _updateOrderStatus(context, 'Accepted'),
                    child: Text('Accept'),
                  ),
                  ElevatedButton(
                    onPressed: () => _updateOrderStatus(context, 'Rejected'),
                    child: Text('Reject'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
