import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  ProductDetailScreen({required this.productId});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _firestore = FirebaseFirestore.instance;
  DocumentSnapshot? _product;
  int _quantity = 0;
  String _totalPrice = "";

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    final product = await _firestore.collection('Products').doc(widget.productId).get();
    setState(() {
      _product = product;
      _quantity = 1;
      _totalPrice = _product!['rate'];
    });
  }

  void _addToCart(String productId) async {
    final cartItem = await _firestore
        .collection('cart')
        .where('product_id', isEqualTo: productId)
        .get();

    if (cartItem.docs.isEmpty) {
      // Product not in cart, add new entry
      await _firestore.collection('cart').add({
        'product_id': productId,
        'quantity': _quantity,
        'total_price': _totalPrice,
      });
    } else {
      // Product already in cart, update quantity and total price
      final doc = cartItem.docs.first;
      final currentQuantity = doc['quantity'];
      final currentTotalPrice = doc['total_price'];
      await _firestore.collection('cart').doc(doc.id).update({
        'quantity': currentQuantity + _quantity,
        'total_price': currentTotalPrice + _totalPrice,
      });
    }
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
      _totalPrice = _product!['rate'] * _quantity;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
        _totalPrice = _product!['rate'] * _quantity;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_product == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Product Details'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Uncomment the following line if your products have images
            // Image.network(_product!['image_url']),
            Text(_product!['productName'], style: TextStyle(fontSize: 24)),
            Text(_product!['description']),
           Text('Rate: ${_product!['rate']}'),
           //  Row(
           //    children: <Widget>[
           //      IconButton(
           //        icon: Icon(Icons.remove),
           //        onPressed: _decrementQuantity,
           //      ),
           //      Text('$_quantity', style: TextStyle(fontSize: 20)),
           //      IconButton(
           //        icon: Icon(Icons.add),
           //        onPressed: _incrementQuantity,
           //      ),
           //    ],
           //  ),
           // // Text('Total Price: $_totalPrice'),
           //  ElevatedButton(
           //    onPressed: () {
           //      _addToCart(widget.productId);
           //    },
           //    child: Text('Add to Cart'),
           //  ),
          ],
        ),
      ),
    );
  }
}
