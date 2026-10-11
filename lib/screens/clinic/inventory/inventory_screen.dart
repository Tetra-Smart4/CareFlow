import 'package:flutter/material.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Inventory')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          ('Paracetamol 500 mg', '250', 'In Stock'),
          ('Cetirizine 10 mg', '20', 'Low Stock'),
          ('Amoxicillin 500 mg', '0', 'Out of Stock'),
          ('Vitamin C', '150', 'In Stock'),
        ])
          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2),
              title: Text(x.$1),
              subtitle: Text('Stock: ${x.$2}'),
              trailing: Text(x.$3),
            ),
          ),
      ],
    ),
  );
}
