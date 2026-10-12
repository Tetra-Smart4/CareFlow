import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryRepository {
  SupabaseClient get client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> listItems(String clinicId, {String? filter}) async {
    try {
      var query = client
          .from('careflow_inventory_items')
          .select()
          .eq('clinic_id', clinicId)
          .order('medicine_name', ascending: true);

      final data = await query;
      final items = List<Map<String, dynamic>>.from(data);

      if (filter == 'low_stock') {
        return items.where((it) {
          final stock = (it['stock_quantity'] as num?)?.toInt() ?? 0;
          final threshold = (it['reorder_threshold'] as num?)?.toInt() ?? 10;
          return stock <= threshold;
        }).toList();
      } else if (filter == 'expiring_soon') {
        final thresholdDate = DateTime.now().add(const Duration(days: 90));
        return items.where((it) {
          final expStr = it['expiry_date']?.toString();
          if (expStr == null || expStr.isEmpty) return false;
          final exp = DateTime.tryParse(expStr);
          return exp != null && exp.isBefore(thresholdDate);
        }).toList();
      }

      return items;
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> addItem({
    required String clinicId,
    required String medicineName,
    String? genericName,
    String? composition,
    String dosageForm = 'Tablet',
    String packSize = '10 tablets',
    String? batchNumber,
    String? expiryDate,
    int stockQuantity = 0,
    int reorderThreshold = 10,
    double? purchasePrice,
    double? sellingPrice,
    String? supplier,
  }) async {
    final res = await client
        .from('careflow_inventory_items')
        .insert({
          'clinic_id': clinicId,
          'medicine_name': medicineName,
          'generic_name': genericName,
          'composition': composition,
          'dosage_form': dosageForm,
          'pack_size': packSize,
          'batch_number': batchNumber,
          'expiry_date': expiryDate,
          'stock_quantity': stockQuantity,
          'reorder_threshold': reorderThreshold,
          'purchase_price': purchasePrice,
          'selling_price': sellingPrice,
          'supplier': supplier,
        })
        .select()
        .single();

    // Record initial stock transaction if quantity > 0
    if (stockQuantity > 0) {
      final itemId = res['id']?.toString();
      if (itemId != null) {
        await recordTransaction(
          itemId: itemId,
          clinicId: clinicId,
          type: 'received',
          quantity: stockQuantity,
          previousStock: 0,
          newStock: stockQuantity,
          batchNumber: batchNumber,
          notes: 'Initial stock entry',
        );
      }
    }

    return Map<String, dynamic>.from(res);
  }

  Future<void> recordTransaction({
    required String itemId,
    required String clinicId,
    required String type, // 'received', 'issued', 'dispensed', 'return', 'adjustment', 'wastage'
    required int quantity,
    required int previousStock,
    required int newStock,
    String? batchNumber,
    String? notes,
  }) async {
    final user = client.auth.currentUser;
    try {
      // 1. Insert transaction audit log
      await client.from('careflow_inventory_transactions').insert({
        'item_id': itemId,
        'clinic_id': clinicId,
        'transaction_type': type,
        'quantity': quantity,
        'previous_stock': previousStock,
        'new_stock': newStock,
        'batch_number': batchNumber,
        'notes': notes,
        'actor_id': user?.id,
      });

      // 2. Update item stock quantity
      await client
          .from('careflow_inventory_items')
          .update({
            'stock_quantity': newStock,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', itemId);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> listTransactions(String itemId) async {
    try {
      final res = await client
          .from('careflow_inventory_transactions')
          .select()
          .eq('item_id', itemId)
          .order('created_at', ascending: false)
          .limit(30);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }
}
