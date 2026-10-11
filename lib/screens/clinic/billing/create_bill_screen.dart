import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';

class CreateBillScreen extends StatefulWidget {
  const CreateBillScreen({super.key});

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  final _amountController = TextEditingController(text: '500');
  final _descriptionController = TextEditingController(text: 'General Consultation');
  String _paymentMethod = 'Cash';
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _generateBill() {
    setState(() => _isSaving = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice generated successfully!'),
            backgroundColor: ColorTokens.careGreen,
          ),
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    String patientName = 'Patient';
    if (args is Map && args['patientName'] != null) {
      patientName = args['patientName'].toString();
    }

    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(title: const Text('Create Invoice')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: ColorTokens.lightBlue,
                child: Icon(Icons.person_rounded, color: ColorTokens.primaryBlue),
              ),
              title: Text(patientName, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('CareFlow Registered Patient'),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bill Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ColorTokens.navy),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Service Description',
                      hintText: 'E.g. Consultation, Blood Test',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (₹)',
                      hintText: '500',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Method',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Cash', label: Text('Cash')),
                      ButtonSegment(value: 'Card', label: Text('Card')),
                      ButtonSegment(value: 'UPI', label: Text('UPI')),
                    ],
                    selected: {_paymentMethod},
                    onSelectionChanged: (val) {
                      setState(() => _paymentMethod = val.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _generateBill,
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text('Generate & Issue Invoice', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
