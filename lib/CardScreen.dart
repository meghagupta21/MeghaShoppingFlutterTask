import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_shopping_app_task/CheckOutScreen.dart';

class CartScreen extends StatefulWidget {
  final String userId;

  CartScreen({required this.userId});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _cartItems = [];
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    final cartSnapshot = await _firestore
        .collection('cart')
        .where('user_id', isEqualTo: widget.userId)
        .get();

    final List<Map<String, dynamic>> cartItems = [];

    for (var cartItem in cartSnapshot.docs) {
      final productId = cartItem['product_id'];
      final productSnapshot = await _firestore.collection('Products').doc(productId).get();
      final productData = productSnapshot.data() ?? {};

      cartItems.add({
        'cart_id': cartItem.id,
        'product_id': productId,
        'product_name': productData['productName'] ?? 'Unknown',
        'total_price': double.parse(productData['rate']),
        'quantity': cartItem['quantity'],
      });
    }

    setState(() {
      _cartItems = cartItems;
      _calculateTotalAmount(); // Ensure the total amount is recalculated after fetching items
    });
  }

  void _calculateTotalAmount() {
    _totalAmount = 0.0;
    for (var item in _cartItems) {
      _totalAmount += item['quantity'] * item['total_price'];
    }
  }

  void _updateQuantity(String cartId, int quantity) async {
    await _firestore.collection('cart').doc(cartId).update({'quantity': quantity});
    _fetchCartItems();
  }

  void _removeItem(String cartId) async {
    await _firestore.collection('cart').doc(cartId).delete();
    _fetchCartItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
      ),
      body: _cartItems.isEmpty
          ? Center(child: Text('Your cart is empty'))
          : ListView.builder(
        itemCount: _cartItems.length,
        itemBuilder: (context, index) {
          var item = _cartItems[index];
          return ListTile(
            title: Text(item['product_name']),
            subtitle: Text('Rate: ${item['total_price']*item['quantity']} \nQuantity: ${item['quantity']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    if (item['quantity'] > 1) {
                      _updateQuantity(item['cart_id'], item['quantity'] - 1);
                    }
                  },
                ),
                Text(item['quantity'].toString()),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    _updateQuantity(item['cart_id'], item['quantity'] + 1);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _removeItem(item['cart_id']);
                  },
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total: \$$_totalAmount', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Navigate to checkout screen
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => CheckoutScreen(userId: widget.userId,totalAmount:_totalAmount,cartItems:_cartItems),
                ));
              },
              child: Text('Proceed to Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}

