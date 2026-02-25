import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../provider/search_provider.dart';
import '../provider/wishlist_provider.dart';
import '../widgets/floating_voice_assistant.dart'; // ADDED: Voice Assistant Widget

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search for dresses, kurtis, sarees...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                _searchController.clear();
                searchProvider.clearSearch();
              },
            )
                : null,
          ),
          onChanged: (query) {
            searchProvider.searchProducts(query);
          },
        ),
        actions: [
          // ADDED: Voice Agent Button
          IconButton(
            icon: const Icon(Icons.mic, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/voiceAgent');
            },
            tooltip: 'Voice Assistant',
          ),
          // ADDED: Cart Button
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
            tooltip: 'My Cart',
          ),
          // AI Support button in AppBar
          IconButton(
            icon: const Icon(Icons.support_agent, color: Colors.white),
            tooltip: 'AI Customer Support',
            onPressed: () => Navigator.pushNamed(context, '/support'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search suggestions / categories
          if (_searchController.text.isEmpty) _buildQuickFilters(searchProvider),

          // Sort and Filter Bar
          if (searchProvider.hasResults) _buildSortFilterBar(searchProvider),

          // Search Results
          Expanded(
            child: _buildSearchResults(searchProvider, wishlistProvider),
          ),
        ],
      ),

      // UPDATED: Changed to Voice Assistant FAB
      floatingActionButton: const FloatingVoiceAssistant(),
    );
  }

  Widget _buildQuickFilters(SearchProvider searchProvider) {
    final categories = [
      {'name': 'Dresses', 'icon': Icons.checkroom},
      {'name': 'Kurtis', 'icon': Icons.local_mall},
      {'name': 'Sarees', 'icon': Icons.dry_cleaning},
      {'name': 'Tops', 'icon': Icons.shopping_bag},
      {'name': 'Jeans', 'icon': Icons.style},
      {'name': 'Ethnic Wear', 'icon': Icons.festival},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Quick Search',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // ADDED: Voice search prompt
              TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/voiceAgent');
                },
                icon: const Icon(Icons.mic, size: 16),
                label: const Text('Use Voice', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((category) {
              return InkWell(
                onTap: () {
                  _searchController.text = category['name'] as String;
                  searchProvider.searchProducts(category['name'] as String);
                },
                child: Chip(
                  avatar: Icon(
                    category['icon'] as IconData,
                    size: 18,
                    color: Colors.purple,
                  ),
                  label: Text(category['name'] as String),
                  backgroundColor: Colors.purple[50],
                  labelStyle: TextStyle(color: Colors.purple[700]),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSortFilterBar(SearchProvider searchProvider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${searchProvider.searchResults.length} products found',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => _showSortOptions(searchProvider),
            icon: const Icon(Icons.sort, size: 18),
            label: const Text('Sort'),
            style: TextButton.styleFrom(foregroundColor: Colors.purple),
          ),
          TextButton.icon(
            onPressed: () => _showFilterOptions(searchProvider),
            icon: const Icon(Icons.filter_list, size: 18),
            label: const Text('Filter'),
            style: TextButton.styleFrom(foregroundColor: Colors.purple),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
      SearchProvider searchProvider, WishlistProvider wishlistProvider) {
    if (searchProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Search for products',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Find dresses, ethnic wear, and more',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),

            // ADDED: Voice Search Suggestion Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade50, Colors.purple.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.mic,
                    size: 48,
                    color: Colors.purple.shade600,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Try Voice Search!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Say "Add red dress to cart"',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.purple.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/voiceAgent'),
                    icon: const Icon(Icons.mic, size: 20),
                    label: const Text('Start Voice Shopping'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Help suggestion
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/support'),
              icon: const Icon(Icons.support_agent),
              label: const Text('Need help finding products?'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF9C27B0),
                side: const BorderSide(color: Color(0xFF9C27B0)),
              ),
            ),
          ],
        ),
      );
    }

    if (searchProvider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),

            // ADDED: Voice search suggestion for no results
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Try Voice Search Instead',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/voiceAgent'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Use Voice'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // AI Help button
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/support'),
              icon: const Icon(Icons.support_agent),
              label: const Text('Ask AI for help'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: searchProvider.searchResults.length,
      itemBuilder: (context, index) {
        final product = searchProvider.searchResults[index];
        final isInWishlist = wishlistProvider.isInWishlist(product.id);

        return _buildProductCard(product, isInWishlist, wishlistProvider);
      },
    );
  }

  Widget _buildProductCard(
      Product product, bool isInWishlist, WishlistProvider wishlistProvider) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to product detail
          Navigator.pushNamed(
            context,
            '/productDetail',
            arguments: product,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Wishlist Icon
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    product.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image,
                          size: 60, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        isInWishlist ? Icons.favorite : Icons.favorite_border,
                        color: isInWishlist ? Colors.red : Colors.grey[600],
                      ),
                      iconSize: 20,
                      onPressed: () async {
                        await wishlistProvider.toggleWishlist(
                          userId: 'user_123',
                          productId: product.id,
                          productName: product.name,
                          productImage: product.imageUrl,
                          price: product.price,
                          category: product.category,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isInWishlist
                                    ? 'Removed from wishlist'
                                    : 'Added to wishlist',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                // Discount badge (if applicable)
                if (product.discount != null && product.discount! > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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

            // Product Details
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
                    const SizedBox(height: 4),
                    if (product.category != null)
                      Text(
                        product.category!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        if (product.originalPrice != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(
                              '₹${product.originalPrice!.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions(SearchProvider searchProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort By',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _sortOption('Price: Low to High', 'price_low_high', searchProvider),
            _sortOption('Price: High to Low', 'price_high_low', searchProvider),
            _sortOption('Name: A to Z', 'name_a_z', searchProvider),
            _sortOption('Name: Z to A', 'name_z_a', searchProvider),
            _sortOption('Newest First', 'newest', searchProvider),
          ],
        ),
      ),
    );
  }

  Widget _sortOption(
      String label, String value, SearchProvider searchProvider) {
    return ListTile(
      title: Text(label),
      onTap: () {
        searchProvider.sortResults(value);
        Navigator.pop(context);
      },
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }

  void _showFilterOptions(SearchProvider searchProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter By Price',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _filterOption('Under ₹500', 0, 500, searchProvider),
            _filterOption('₹500 - ₹1000', 500, 1000, searchProvider),
            _filterOption('₹1000 - ₹2000', 1000, 2000, searchProvider),
            _filterOption('Above ₹2000', 2000, 100000, searchProvider),
          ],
        ),
      ),
    );
  }

  Widget _filterOption(
      String label, double min, double max, SearchProvider searchProvider) {
    return ListTile(
      title: Text(label),
      onTap: () {
        searchProvider.filterByPriceRange(min, max);
        Navigator.pop(context);
      },
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}