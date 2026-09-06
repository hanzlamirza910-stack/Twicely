import '../services/api_service.dart';

class CartManager {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  Future<void> syncWithBackend() async {
    final res = await ApiService.getCart();
    if (res['success'] == true && res['data'] != null) {
      final cartData = res['data'];
      final rawItems = cartData['items'];
      
      Iterable<dynamic> itemsIterable = [];
      if (rawItems is List) {
        itemsIterable = rawItems;
      } else if (rawItems is Map) {
        itemsIterable = rawItems.values;
      }

      _items.clear();
      for (final item in itemsIterable) {
        if (item is! Map) continue;

        final int packageId = int.tryParse(item['package_id']?.toString() ?? '') ?? 
                            int.tryParse(item['id']?.toString() ?? '') ?? 0;
        final String title = item['title']?.toString() ?? 'Selected Package';
        
        String imageUrl = 'assets/images/package_spa.jpg';
        if (item['primary_image'] != null && item['primary_image'].toString().isNotEmpty) {
          imageUrl = item['primary_image'].toString();
        } else if (item['cover_url'] != null && item['cover_url'].toString().isNotEmpty) {
          imageUrl = item['cover_url'].toString();
        }
        
        final double rawPrice = double.tryParse(item['price']?.toString() ?? '') ?? 0.0;
        final double priceVal = rawPrice;
        
        _items.add({
          'id': packageId,
          'imageUrl': imageUrl,
          'title': title,
          'subtitle': item['category']?.toString() ?? 'Package',
          'price': priceVal,
        });
      }
    }
  }

  void addItem(Map<String, dynamic> item) {
    // Only add if not already in local list to avoid duplicates
    if (!_items.any((x) => x['id'] == item['id'])) {
      _items.add(item);
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      final pkgId = _items[index]['id'];
      _items.removeAt(index);
      if (pkgId != null) {
        ApiService.removeFromCart(pkgId as int);
      }
    }
  }

  double get subtotal => _items.fold(0.0, (sum, item) => sum + (item['price'] as double));
  double get discount => 0.0;
  double get delivery => 0.0;
  double get tax => 0.0;
  double get total => subtotal - discount + delivery + tax;

  void clear() {
    _items.clear();
    ApiService.clearCart();
  }
}
