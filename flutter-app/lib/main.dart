import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const VyshApp());
}

class VyshApp extends StatelessWidget {
  const VyshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VYSH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC9A227),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ShopHome(),
    );
  }
}

const List<String> kCollections = ['nails', 'hoodies', 'tshirts', 'sweatshirts'];
const Map<String, String> kCollectionLabels = {
  'nails': 'Nail Art & Extensions',
  'hoodies': 'Hoodies',
  'tshirts': 'T-Shirts',
  'sweatshirts': 'Sweatshirts',
};

class ShopHome extends StatefulWidget {
  const ShopHome({super.key});

  @override
  State<ShopHome> createState() => _ShopHomeState();
}

class _ShopHomeState extends State<ShopHome> {
  int _tab = 0;
  String _collection = 'hoodies';
  final List<Map<String, dynamic>> _bag = [];

  SupabaseClient get _db => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _loadProducts() async {
    final rows = await _db
        .from('products')
        .select()
        .eq('collection', _collection)
        .eq('status', 'live')
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  double get _bagTotal => _bag.fold<double>(
      0, (sum, item) => sum + (item['price'] as num).toDouble());

  void _addToBag(Map<String, dynamic> product) {
    setState(() => _bag.add(product));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product['name']} added to bag')),
    );
  }

  void _showProduct(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product['name'] ?? 'Product',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('₹${product['price'] ?? ''}  •  Stock: ${product['stock'] ?? 0}'),
            const SizedBox(height: 8),
            Text(product['description'] ?? ''),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _addToBag(product);
              },
              child: const Text('Add to bag'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shopTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            children: kCollections.map((c) {
              return ChoiceChip(
                label: Text(kCollectionLabels[c]!),
                selected: _collection == c,
                onSelected: (_) => setState(() => _collection = c),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Could not load products.\n${snapshot.error}'));
              }
              final products = snapshot.data ?? [];
              if (products.isEmpty) {
                return const Center(
                    child: Text('Nothing here yet — the owner has not posted designs.'));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, i) {
                  final p = products[i];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _showProduct(p),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              color: Colors.white10,
                              alignment: Alignment.center,
                              child: const Icon(Icons.checkroom, size: 48),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['name'] ?? '',
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text('₹${p['price'] ?? ''}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _bagTab() {
    return Column(
      children: [
        Expanded(
          child: _bag.isEmpty
              ? const Center(child: Text('Your bag is empty.'))
              : ListView.builder(
                  itemCount: _bag.length,
                  itemBuilder: (context, i) => ListTile(
                    title: Text(_bag[i]['name'] ?? ''),
                    trailing: Text('₹${_bag[i]['price'] ?? ''}'),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: ₹$_bagTotal',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              FilledButton(
                onPressed: _bag.isEmpty ? null : () {},
                child: const Text('Checkout'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ownerTab() {
    return const OwnerPanel();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [_shopTab(), _bagTab(), _ownerTab()];
    return Scaffold(
      appBar: AppBar(title: const Text('VYSH — Unisex Fashion')),
      body: tabs[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.store), label: 'Shop'),
          NavigationDestination(icon: Icon(Icons.shopping_bag), label: 'Bag'),
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Owner'),
        ],
      ),
    );
  }
}

class OwnerPanel extends StatefulWidget {
  const OwnerPanel({super.key});

  @override
  State<OwnerPanel> createState() => _OwnerPanelState();
}

class _OwnerPanelState extends State<OwnerPanel> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  String _collection = 'hoodies';
  String _status = 'live';
  bool _posting = false;

  SupabaseClient get _db => Supabase.instance.client;

  Future<void> _postDesign() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _posting = true);
    try {
      await _db.from('products').insert({
        'name': _name.text.trim(),
        'collection': _collection,
        'price': double.tryParse(_price.text.trim()) ?? 0,
        'stock': int.tryParse(_stock.text.trim()) ?? 0,
        'status': _status,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Design posted to the shop.')));
      _name.clear();
      _price.clear();
      _stock.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not post: $e')));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Post a new design',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Design name')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _collection,
          decoration: const InputDecoration(labelText: 'Collection'),
          items: kCollections
              .map((c) => DropdownMenuItem(
                  value: c, child: Text(kCollectionLabels[c]!)))
              .toList(),
          onChanged: (v) => setState(() => _collection = v ?? 'hoodies'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: TextField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Price (₹)'))),
            const SizedBox(width: 12),
            Expanded(
                child: TextField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Stock'))),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _status,
          decoration: const InputDecoration(labelText: 'Status'),
          items: const [
            DropdownMenuItem(value: 'live', child: Text('Live')),
            DropdownMenuItem(value: 'draft', child: Text('Draft')),
            DropdownMenuItem(value: 'hidden', child: Text('Hidden')),
          ],
          onChanged: (v) => setState(() => _status = v ?? 'live'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _posting ? null : _postDesign,
          child: Text(_posting ? 'Posting…' : 'Post design'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Posted designs appear on the shop straight away, in the chosen collection.',
          style: TextStyle(color: Colors.white60),
        ),
      ],
    );
  }
}
