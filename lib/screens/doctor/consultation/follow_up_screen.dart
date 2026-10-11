import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';

class DoctorFollowUpScreen extends StatefulWidget {
  const DoctorFollowUpScreen({super.key});

  @override
  State<DoctorFollowUpScreen> createState() => _DoctorFollowUpScreenState();
}

class _DoctorFollowUpScreenState extends State<DoctorFollowUpScreen> {
  final _reasonController = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(title: const Text('Schedule Follow-up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Follow-up Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ColorTokens.navy),
            ),
            const SizedBox(height: 8),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.calendar_today, color: ColorTokens.primaryBlue),
              title: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) {
                  setState(() => _date = picked);
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Reason for Follow-up',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ColorTokens.navy),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter clinical reason or tests to review...',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'date': '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                    'reason': _reasonController.text.trim(),
                  });
                },
                child: const Text('Confirm Follow-up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
