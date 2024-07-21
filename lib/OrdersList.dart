import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firebase_shopping_app_task/OrderListDetails.dart';

class OrdersListScreen extends StatelessWidget {
  final String customerId;

  OrdersListScreen({required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orders List'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Customers').doc(customerId).collection('Orders').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No orders available.'));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return ListTile(
                title: Text(order['contactNumber']),
                subtitle: Text('Delivery Date: ${order['deliveryDate']}'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => OrderDetailScreen(
                        customerId: customerId,
                        orderId: order.id,
                        orderData: order.data() as Map<String, dynamic>,
                      ),
                    ),
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
