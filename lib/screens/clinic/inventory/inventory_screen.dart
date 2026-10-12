import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/clinic_repository.dart';
import '../../../repositories/inventory_repository.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _inventoryRepo = InventoryRepository();
  final _clinicRepo = ClinicRepository();
  final _searchController = TextEditingController();

  bool _loading = true;
  String? _clinicId;
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  String _activeFilter = 'all'; // 'all', 'low_stock', 'expiring_soon'

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final cid = await _clinicRepo.getCurrentUserClinicId() ?? user?.id;
      _clinicId = cid;

      if (cid != null) {
        final items = await _inventoryRepo.listItems(cid);
        if (mounted) {
          setState(() {
            _allItems = items;
            _applyFilters();
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();
    final thresholdDate = now.add(const Duration(days: 90));

    setState(() {
      _filteredItems = _allItems.where((item) {
        final name = (item['medicine_name'] ?? '').toString().toLowerCase();
        final generic = (item['generic_name'] ?? '').toString().toLowerCase();
        final batch = (item['batch_number'] ?? '').toString().toLowerCase();

        final matchesSearch = query.isEmpty ||
            name.contains(query) ||
            generic.contains(query) ||
            batch.contains(query);

        if (!matchesSearch) return false;

        final stock = (item['stock_quantity'] as num?)?.toInt() ?? 0;
        final threshold = (item['reorder_threshold'] as num?)?.toInt() ?? 10;
        final expStr = item['expiry_date']?.toString();
        final expDate = expStr != null && expStr.isNotEmpty ? DateTime.tryParse(expStr) : null;

        if (_activeFilter == 'low_stock') {
          return stock <= threshold;
        } else if (_activeFilter == 'expiring_soon') {
          return expDate != null && expDate.isBefore(thresholdDate);
        }

        return true;
      }).toList();
    });
  }

  Future<void> _showAdjustStockDialog(Map<String, dynamic> item) async {
    final qtyController = TextEditingController();
    final notesController = TextEditingController();
    String selectedType = 'received';
    final currentStock = (item['stock_quantity'] as num?)?.toInt() ?? 0;
    final itemId = item['id'].toString();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Adjust Stock: ${item['medicine_name']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Stock: $currentStock ${item['dosage_form'] ?? 'units'}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: ColorTokens.primaryBlue),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Movement Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'received', child: Text('Stock Received (Add)')),
                    DropdownMenuItem(value: 'dispensed', child: Text('Dispensed to Patient (Deduct)')),
                    DropdownMenuItem(value: 'return', child: Text('Supplier Return (Deduct)')),
                    DropdownMenuItem(value: 'adjustment', child: Text('Stock Count Correction')),
                    DropdownMenuItem(value: 'wastage', child: Text('Expired / Damaged (Deduct)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'e.g. 50',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Reason / Reference Note',
                    hintText: 'e.g. Invoice #9842 or Physical Audit',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final qty = int.tryParse(qtyController.text.trim());
                if (qty == null || qty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid positive quantity.')),
                  );
                  return;
                }

                int newStock = currentStock;
                if (selectedType == 'received') {
                  newStock += qty;
                } else if (selectedType == 'adjustment') {
                  newStock = qty; // Direct count override
                } else {
                  if (qty > currentStock) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cannot deduct more than available stock.')),
                    );
                    return;
                  }
                  newStock -= qty;
                }

                if (_clinicId != null) {
                  await _inventoryRepo.recordTransaction(
                    itemId: itemId,
                    clinicId: _clinicId!,
                    type: selectedType,
                    quantity: qty,
                    previousStock: currentStock,
                    newStock: newStock,
                    notes: notesController.text.trim(),
                  );
                }

                if (ctx.mounted) Navigator.pop(ctx);
                _loadInventory();
              },
              child: const Text('Save Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddMedicineDialog() async {
    final nameCtrl = TextEditingController();
    final genericCtrl = TextEditingController();
    final compCtrl = TextEditingController();
    final batchCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '0');
    final thresholdCtrl = TextEditingController(text: '10');
    final supplierCtrl = TextEditingController();
    String dosageForm = 'Tablet';
    DateTime? selectedExpiry;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Medicine to Inventory'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Brand / Medicine Name *'),
                ),
                TextField(
                  controller: genericCtrl,
                  decoration: const InputDecoration(labelText: 'Generic / Chemical Name'),
                ),
                TextField(
                  controller: compCtrl,
                  decoration: const InputDecoration(labelText: 'Composition / Strength (e.g. 500mg)'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: dosageForm,
                  decoration: const InputDecoration(labelText: 'Dosage Form'),
                  items: const [
                    DropdownMenuItem(value: 'Tablet', child: Text('Tablet')),
                    DropdownMenuItem(value: 'Capsule', child: Text('Capsule')),
                    DropdownMenuItem(value: 'Syrup', child: Text('Syrup / Liquid')),
                    DropdownMenuItem(value: 'Injection', child: Text('Injection')),
                    DropdownMenuItem(value: 'Ointment', child: Text('Ointment / Gel')),
                    DropdownMenuItem(value: 'Drops', child: Text('Drops')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => dosageForm = val);
                  },
                ),
                TextField(
                  controller: batchCtrl,
                  decoration: const InputDecoration(labelText: 'Batch Number'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    selectedExpiry == null
                        ? 'Select Expiry Date'
                        : 'Expiry: ${selectedExpiry!.year}-${selectedExpiry!.month.toString().padLeft(2, '0')}-${selectedExpiry!.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.calendar_today_rounded, size: 20),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedExpiry = picked);
                    }
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Initial Stock'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: thresholdCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Reorder Alert'),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: supplierCtrl,
                  decoration: const InputDecoration(labelText: 'Supplier / Distributor'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medicine brand name is required.')),
                  );
                  return;
                }

                if (_clinicId == null) return;

                final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;
                final threshold = int.tryParse(thresholdCtrl.text.trim()) ?? 10;
                final expStr = selectedExpiry != null
                    ? '${selectedExpiry!.year}-${selectedExpiry!.month.toString().padLeft(2, '0')}-${selectedExpiry!.day.toString().padLeft(2, '0')}'
                    : null;

                await _inventoryRepo.addItem(
                  clinicId: _clinicId!,
                  medicineName: name,
                  genericName: genericCtrl.text.trim(),
                  composition: compCtrl.text.trim(),
                  dosageForm: dosageForm,
                  batchNumber: batchCtrl.text.trim(),
                  expiryDate: expStr,
                  stockQuantity: stock,
                  reorderThreshold: threshold,
                  supplier: supplierCtrl.text.trim(),
                );

                if (ctx.mounted) Navigator.pop(ctx);
                _loadInventory();
              },
              child: const Text('Add Medicine'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalSkus = _allItems.length;
    int lowStockCount = 0;
    int expiringSoonCount = 0;
    final now = DateTime.now();
    final thresholdDate = now.add(const Duration(days: 90));

    for (final it in _allItems) {
      final stock = (it['stock_quantity'] as num?)?.toInt() ?? 0;
      final threshold = (it['reorder_threshold'] as num?)?.toInt() ?? 10;
      if (stock <= threshold) lowStockCount++;

      final expStr = it['expiry_date']?.toString();
      if (expStr != null && expStr.isNotEmpty) {
        final exp = DateTime.tryParse(expStr);
        if (exp != null && exp.isBefore(thresholdDate)) expiringSoonCount++;
      }
    }

    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Clinic Medicine Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadInventory,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMedicineDialog,
        backgroundColor: ColorTokens.primaryBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Medicine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInventory,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // KPI Summary Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ColorTokens.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$totalSkus', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy)),
                        const Text('Total Medicines', style: TextStyle(fontSize: 11, color: ColorTokens.muted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ColorTokens.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$lowStockCount', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ColorTokens.warning)),
                        const Text('Low Stock Alerts', style: TextStyle(fontSize: 11, color: ColorTokens.muted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ColorTokens.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$expiringSoonCount', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ColorTokens.error)),
                        const Text('Expiring Soon', style: TextStyle(fontSize: 11, color: ColorTokens.muted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search medicines by brand, generic, or batch...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (_) => _applyFilters(),
            ),
            const SizedBox(height: 10),

            // Filter Chips
            Row(
              children: [
                ChoiceChip(
                  label: const Text('All Items'),
                  selected: _activeFilter == 'all',
                  onSelected: (_) {
                    setState(() => _activeFilter = 'all');
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Low Stock'),
                  selected: _activeFilter == 'low_stock',
                  onSelected: (_) {
                    setState(() => _activeFilter = 'low_stock');
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Expiring Soon'),
                  selected: _activeFilter == 'expiring_soon',
                  onSelected: (_) {
                    setState(() => _activeFilter = 'expiring_soon');
                    _applyFilters();
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_filteredItems.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: const [
                      Icon(Icons.inventory_2_outlined, size: 54, color: ColorTokens.muted),
                      SizedBox(height: 12),
                      Text(
                        'No Medicine Records Found',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Add medicines using the button below to start tracking clinic stock levels.',
                        style: TextStyle(color: ColorTokens.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._filteredItems.map((item) {
                final name = item['medicine_name'] ?? 'Unnamed Medicine';
                final generic = item['generic_name'] ?? '';
                final composition = item['composition'] ?? '';
                final dosageForm = item['dosage_form'] ?? 'Tablet';
                final stock = (item['stock_quantity'] as num?)?.toInt() ?? 0;
                final threshold = (item['reorder_threshold'] as num?)?.toInt() ?? 10;
                final batch = item['batch_number'] ?? 'N/A';
                final expiry = item['expiry_date'] ?? 'N/A';

                final isLow = stock <= threshold;
                final isOut = stock == 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: ColorTokens.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: isOut
                                  ? ColorTokens.error.withValues(alpha: 0.12)
                                  : isLow
                                      ? ColorTokens.lightWarning
                                      : ColorTokens.lightGreen,
                              child: Icon(
                                Icons.medication_outlined,
                                color: isOut
                                    ? ColorTokens.error
                                    : isLow
                                        ? ColorTokens.warning
                                        : ColorTokens.careGreen,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: ColorTokens.darkNavy,
                                    ),
                                  ),
                                  if (generic.isNotEmpty || composition.isNotEmpty)
                                    Text(
                                      '$generic • $composition',
                                      style: const TextStyle(fontSize: 12.5, color: ColorTokens.muted),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Batch: $batch • Expiry: $expiry',
                                    style: const TextStyle(fontSize: 12, color: ColorTokens.muted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isOut
                                    ? ColorTokens.error.withValues(alpha: 0.12)
                                    : isLow
                                        ? ColorTokens.lightWarning
                                        : ColorTokens.lightGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isOut
                                    ? 'OUT OF STOCK'
                                    : isLow
                                        ? 'LOW STOCK'
                                        : 'IN STOCK',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isOut
                                      ? ColorTokens.error
                                      : isLow
                                          ? ColorTokens.warning
                                          : ColorTokens.careGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: ColorTokens.border),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Available Stock: $stock $dosageForm',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: isOut ? ColorTokens.error : ColorTokens.darkNavy,
                              ),
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.sync_alt_rounded, size: 16),
                              label: const Text('Adjust Stock'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              onPressed: () => _showAdjustStockDialog(item),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
