import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/cart_provider.dart';
import '../provider/wishlist_provider.dart';
import '../models/product_model.dart';

class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock products
    final products = [
      Product(
        id: 'p1',
        name: 'Floral Summer Dress',
        description: 'Beautiful floral print dress',
        price: 599,
        imageUrl: 'https://imgs.search.brave.com/DnPHvi2TVKMn24Ce9QTyPuxxC9ABAf56HBFnSsIKSGk/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9pLnBp/bmltZy5jb20vb3Jp/Z2luYWxzLzBhLzZl/L2E5LzBhNmVhOTNl/ZjM3MmVkZmJhOTJl/NTMzNTI1MTgyZDk1/LmpwZw',
        stock: 10,
        category: 'Dresses',
        originalPrice: 999,
        discount: 40,
      ),
      Product(
        id: 'p2',
        name: 'Cotton Kurti Set',
        description: 'Comfortable cotton kurti',
        price: 799,
        imageUrl: 'https://imgs.search.brave.com/QriLj8pBwkX2bYmosnHo0MkYXlmLWf-JoOAfhBmKA0E/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9pbWcu/ZmFiYWxsZXkuY29t/L2ltYWdlcy9Qcm9k/dWN0L1hLUzI4NzI1/QS9kMy5qcGc',
        stock: 15,
        category: 'Ethnic Wear',
      ),
      Product(
        id: 'p3',
        name: 'Designer Saree',
        description: 'Elegant designer saree',
        price: 1499,
        imageUrl: 'https://imgs.search.brave.com/Sauv5EBol8Vo6QGvYOfPgI5Fp3MbH2FkiFsAxQ4JE-w/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly93d3cu/dG9yYW5pLmluL2Nk/bi9zaG9wL2ZpbGVz/LzExLTA4LTI0LVRP/UkFOSTE0NTQucG5n/P3Y9MTcyNTUzNTk1/OCZ3aWR0aD0xMTAw',
        stock: 8,
        category: 'Sarees',
        originalPrice: 2499,
        discount: 40,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Shopping'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
              ),
              Consumer<CartProvider>(
                builder: (context, cart, _) {
                  if (cart.itemCount == 0) return const SizedBox();
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cart.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return _ProductCard(product: products[index]);
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final isInWishlist = wishlistProvider.isInWishlist(product.id);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  product.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 60),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    isInWishlist ? Icons.favorite : Icons.favorite_border,
                    color: isInWishlist ? Colors.red : Colors.white,
                  ),
                  onPressed: () {
                    wishlistProvider.toggleWishlist(
                      userId: 'user_123',
                      productId: product.id,
                      productName: product.name,
                      productImage: product.imageUrl,
                      price: product.price,
                      category: product.category,
                    );
                  },
                ),
              ),
              if (product.discount != null && product.discount! > 0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${product.discount}% OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  cartProvider.addToCart(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to cart')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Add to Cart', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}