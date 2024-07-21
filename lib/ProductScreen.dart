import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firebase_shopping_app_task/CardScreen.dart';
import 'package:flutter_firebase_shopping_app_task/OrdersList.dart';
import 'package:flutter_firebase_shopping_app_task/ProductDetailsScreen.dart';

class ProductListScreen extends StatefulWidget {
  final String user_id;

  const ProductListScreen({super.key, required this.user_id});
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
        automaticallyImplyLeading: false, // This removes the back button
        actions: [
          IconButton(
            icon: Icon(Icons.card_travel),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CartScreen(userId: widget.user_id),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.reorder),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OrdersListScreen(customerId: widget.user_id), // Navigate to add new product screen
                ),
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('Products').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading:product['imageUrl'] != null
              ? Container(
                height: 200,
                width: 100,
                child: Image.network(
                  product['imageUrl'],
                  fit: BoxFit.cover,
                ),
              )
                  : Container(
              height: 200,
              width: 100,
              child: Center(
              child: Icon(Icons.image_not_supported),
              ),
              ),

              title: Text(product['productName']),
                subtitle: Text(product['rate']),
                trailing: IconButton(
                  icon: Icon(Icons.add_shopping_cart),
                  onPressed: () {
                    _addToCart(product.id);
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(productId: product.id),
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

  void _addToCart(String productId) async {
    // Check if the product already exists in the cart
    final querySnapshot = await _firestore
        .collection('cart')
        .where('user_id', isEqualTo: widget.user_id)
        .where('product_id', isEqualTo: productId)
        .get();

    if (querySnapshot.docs.isEmpty) {
      // If product does not exist in the cart, add it
      await _firestore.collection('cart').add({
        'user_id': widget.user_id,
        'product_id': productId,
        'quantity': 1,
        'total_price': 0, // You can set the price based on your product's price
      });
    } else {
      // If product already exists in the cart, update the quantity
      final docId = querySnapshot.docs.first.id;
      final currentQuantity = querySnapshot.docs.first['quantity'];
      await _firestore.collection('cart').doc(docId).update({
        'quantity': currentQuantity + 1,
      });
    }
  }
}
