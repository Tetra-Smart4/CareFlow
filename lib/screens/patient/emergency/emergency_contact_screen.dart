import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../models/emergency_contact.dart';
import '../../../repositories/emergency_contact_repository.dart';
import '../../../services/auth_service.dart';

class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({super.key});

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  final EmergencyContactRepository _repo = EmergencyContactRepository();

  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;
  String? _errorMessage;

  String get _currentUserId => AuthService().currentUser?.id ?? 'demo_patient';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contacts = await _repo.getContacts(_currentUserId);
      if (mounted) {
        setState(() {
          _contacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load emergency contacts: $e';
        });
      }
    }
  }

  Future<void> _openContactDialog({EmergencyContact? contact}) async {
    final nameController = TextEditingController(text: contact?.name ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    String relationship = contact?.relationship ?? 'Parent';
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    final relationships = ['Parent', 'Spouse', 'Sibling', 'Child', 'Guardian', 'Other'];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorTokens.lightBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.contact_emergency_rounded, color: ColorTokens.primaryBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                contact == null ? 'Add Emergency Contact' : 'Edit Contact',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: ColorTokens.darkNavy),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Full Name *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ColorTokens.darkNavy)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Suresh Kumar',
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        filled: true,
                        fillColor: ColorTokens.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ColorTokens.border)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 14),

                    const Text('Phone Number *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ColorTokens.darkNavy)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'e.g. +91 9876543210',
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                        filled: true,
                        fillColor: ColorTokens.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ColorTokens.border)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone number is required' : null,
                    ),
                    const SizedBox(height: 14),

                    const Text('Relationship *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ColorTokens.darkNavy)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: relationship,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: ColorTokens.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ColorTokens.border)),
                      ),
                      items: relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => relationship = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorTokens.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);

                      try {
                        if (contact == null) {
                          await _repo.addContact(
                            patientId: _currentUserId,
                            name: nameController.text.trim(),
                            phone: phoneController.text.trim(),
                            relationship: relationship,
                          );
                        } else {
                          await _repo.updateContact(
                            id: contact.id,
                            patientId: _currentUserId,
                            name: nameController.text.trim(),
                            phone: phoneController.text.trim(),
                            relationship: relationship,
                          );
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadContacts();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: ColorTokens.careGreen,
                              content: Text(contact == null ? 'Emergency contact added.' : 'Emergency contact updated.'),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to save contact: $e')),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(contact == null ? 'Save Contact' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Remove Contact', style: TextStyle(fontWeight: FontWeight.w800, color: ColorTokens.darkNavy)),
        content: Text('Are you sure you want to remove ${contact.name} from your emergency contacts?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorTokens.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repo.deleteContact(id: contact.id, patientId: _currentUserId);
        _loadContacts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: ColorTokens.darkNavy,
              content: Text('Emergency contact removed.'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove contact: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ColorTokens.darkNavy),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: ColorTokens.darkNavy),
            tooltip: 'Refresh',
            onPressed: _loadContacts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadContacts,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Info banner explaining post-login setup & future alerts
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ColorTokens.lightBlue.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ColorTokens.primaryBlue.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, color: ColorTokens.primaryBlue, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Patient Emergency Network',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: ColorTokens.darkNavy,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Emergency contacts are stored securely in PostgreSQL and linked to your patient profile. They can be reached immediately during medical urgencies and alert workflows.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ColorTokens.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header with Count and Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Contacts (${_contacts.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ColorTokens.darkNavy,
                        ),
                      ),
                      ElevatedButton.icon(
                        key: const Key('add_emergency_contact_button'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorTokens.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () => _openContactDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Contact', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Error if any
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ColorTokens.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_errorMessage!, style: const TextStyle(color: ColorTokens.error, fontSize: 13)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Empty State
                  if (_contacts.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ColorTokens.border),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: ColorTokens.lightBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.contact_phone_outlined, size: 32, color: ColorTokens.primaryBlue),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Emergency Contacts Yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: ColorTokens.darkNavy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add trusted relatives or guardians who should be reached during critical health events.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: ColorTokens.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ColorTokens.primaryBlue,
                              side: const BorderSide(color: ColorTokens.primaryBlue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: () => _openContactDialog(),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Your First Contact', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),

                  // Contacts List
                  ..._contacts.map(
                    (contact) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: ColorTokens.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: ColorTokens.primaryBlue.withValues(alpha: 0.1),
                                child: Text(
                                  contact.name.isNotEmpty ? contact.name.trim()[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: ColorTokens.primaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            contact.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: ColorTokens.darkNavy,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: ColorTokens.lightBlue,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            contact.relationship,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: ColorTokens.primaryBlue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      contact.phone,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: ColorTokens.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.call_outlined, color: ColorTokens.careGreen, size: 22),
                                tooltip: 'Call Contact',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Calling ${contact.name} at ${contact.phone}...')),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: ColorTokens.textMuted, size: 20),
                                tooltip: 'Edit',
                                onPressed: () => _openContactDialog(contact: contact),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: ColorTokens.error, size: 20),
                                tooltip: 'Remove',
                                onPressed: () => _deleteContact(contact),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
