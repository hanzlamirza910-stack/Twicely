class CartManager {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<Map<String, dynamic>> _items = [
    {
      'imageUrl': 'assets/images/package_spa.jpg',
      'title': 'HydraFacial Glow Treatment',
      'subtitle': 'Premium Skincare • 60 Mins',
      'price': 100.0,
    },
    {
      'imageUrl': 'assets/images/package_yoga.jpg',
      'title': 'Private Yoga Session',
      'subtitle': 'Wellness Retreat • Individual',
      'price': 85.0,
    },
  ];

  List<Map<String, dynamic>> get items => _items;

  void addItem(Map<String, dynamic> item) {
    // Prevent duplicate mock additions for simplicity or just allow them
    _items.add(item);
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
    }
  }

  double get subtotal => _items.fold(0.0, (sum, item) => sum + (item['price'] as double));
  double get discount => 0.0;
  double get delivery => 0.0;
  double get tax => 0.0;
  double get total => subtotal - discount + delivery + tax;

  void clear() {
    _items.clear();
  }
}
