import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/doctor_repository.dart';
import '../../../services/auth_service.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _authService = AuthService();
  final _doctorRepo = DoctorRepository();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _clinicAssociations = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _error = 'User not authenticated.';
        });
        return;
      }

      final profileData = await _doctorRepo.getById(user.id);
      final associations = await _doctorRepo.getDoctorClinicAssociations(user.id);

      if (mounted) {
        setState(() {
          _profile = profileData;
          _clinicAssociations = associations;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load profile: $e';
        });
      }
    }
  }

  Future<void> _openEditProfileDialog() async {
    if (_profile == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final nameController = TextEditingController(text: _profile!['full_name']?.toString() ?? '');
    final phoneController = TextEditingController(text: _profile!['phone']?.toString() ?? '');
    final specController = TextEditingController(text: _profile!['specialization']?.toString() ?? '');
    final qualController = TextEditingController(text: _profile!['qualification']?.toString() ?? '');
    final expController = TextEditingController(text: _profile!['experience']?.toString() ?? '');
    final regController = TextEditingController(text: _profile!['registration_number']?.toString() ?? '');
    final bioController = TextEditingController(text: _profile!['bio']?.toString() ?? '');

    final formKey = GlobalKey<FormState>();

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Edit Professional Profile',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx, false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: specController,
                        decoration: const InputDecoration(labelText: 'Specialization *', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Specialization is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: qualController,
                        decoration: const InputDecoration(labelText: 'Qualifications (e.g., MBBS, MD)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: regController,
                        decoration: const InputDecoration(labelText: 'Medical Council Reg. Number', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: expController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Years of Experience', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: bioController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Professional Bio', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorTokens.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: saving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setModalState(() => saving = true);
                                  try {
                                    final exp = int.tryParse(expController.text.trim());
                                    await _doctorRepo.updateProfessionalProfile(
                                      doctorId: user.id,
                                      fullName: nameController.text.trim(),
                                      phone: phoneController.text.trim(),
                                      specialization: specController.text.trim(),
                                      qualification: qualController.text.trim(),
                                      experience: exp,
                                      registrationNumber: regController.text.trim(),
                                      bio: bioController.text.trim(),
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(ctx, true);
                                    }
                                  } catch (e) {
                                    setModalState(() => saving = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error updating profile: $e'), backgroundColor: ColorTokens.error),
                                      );
                                    }
                                  }
                                },
                          child: saving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (updated == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: ColorTokens.careGreen),
        );
        _loadProfile();
      }
    }
  }

  Future<void> _proposeFeeDialog(String clinicId, String clinicName, double? currentApproved) async {
    final feeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final proposed = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Propose Consultation Fee\n$clinicName', style: const TextStyle(fontSize: 16)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentApproved != null)
                Text(
                  'Currently Approved Fee: ₹$currentApproved',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: ColorTokens.careGreen),
                ),
              const SizedBox(height: 10),
              const Text(
                'Submitting a proposal will not change current booking prices until approved by the clinic.',
                style: TextStyle(fontSize: 12, color: ColorTokens.muted),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: feeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Proposed Fee (₹)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  final parsed = double.tryParse(val?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Please enter a valid positive fee';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorTokens.primaryBlue, foregroundColor: Colors.white),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final fee = double.parse(feeController.text.trim());
                Navigator.pop(ctx, fee);
              }
            },
            child: const Text('Submit Proposal'),
          ),
        ],
      ),
    );

    if (proposed != null) {
      try {
        await _doctorRepo.proposeConsultationFee(clinicId, proposed);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Proposed fee of ₹$proposed submitted for $clinicName.'),
              backgroundColor: ColorTokens.careGreen,
            ),
          );
          _loadProfile();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit proposal: $e'), backgroundColor: ColorTokens.error),
          );
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of CareFlow?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorTokens.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authService.signOut();
      } catch (_) {
        await Supabase.instance.client.auth.signOut();
      }
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/auth/login', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Doctor Profile'),
        actions: [
          if (!_loading && _profile != null)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded),
              tooltip: 'Edit Profile',
              onPressed: _openEditProfileDialog,
            ),
          IconButton(
            onPressed: _loading ? null : _loadProfile,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: ColorTokens.error),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: ColorTokens.muted)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 16),
                    _buildProfessionalInfoCard(),
                    const SizedBox(height: 16),
                    _buildClinicAssociationsCard(),
                    const SizedBox(height: 16),
                    _buildPracticeHoursCard(),
                    const SizedBox(height: 16),
                    _buildSettingsCard(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorTokens.error,
                          side: const BorderSide(color: ColorTokens.error),
                        ),
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
    );
  }

  Widget _buildHeaderCard() {
    final name = _profile?['full_name'] ?? 'Doctor';
    final spec = _profile?['specialization'] ?? 'Healthcare Specialist';
    final email = _profile?['email'] ?? '';
    final phone = _profile?['phone'] ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: ColorTokens.lightBlue,
              child: Text(
                _initials(name),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: ColorTokens.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: ColorTokens.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              spec,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorTokens.primaryBlue,
              ),
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(email, style: const TextStyle(fontSize: 12, color: ColorTokens.textMuted)),
            ],
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(phone, style: const TextStyle(fontSize: 12, color: ColorTokens.textMuted)),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: ColorTokens.lightGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Active Doctor Account',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ColorTokens.careGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalInfoCard() {
    final qual = _profile?['qualification']?.toString() ?? 'MBBS';
    final regNo = _profile?['registration_number']?.toString() ?? 'Pending Verification';
    final exp = _profile?['experience'];
    final bio = _profile?['bio']?.toString();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Professional Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ColorTokens.navy),
                ),
                TextButton.icon(
                  onPressed: _openEditProfileDialog,
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow('Qualifications', qual),
            const Divider(height: 20),
            _infoRow('Medical Registration', regNo),
            if (exp != null) ...[
              const Divider(height: 20),
              _infoRow('Experience', '$exp years'),
            ],
            if (bio != null && bio.isNotEmpty) ...[
              const Divider(height: 20),
              const Text('Biography', style: TextStyle(fontSize: 13, color: ColorTokens.muted)),
              const SizedBox(height: 4),
              Text(bio, style: const TextStyle(fontSize: 13, color: ColorTokens.darkNavy, height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClinicAssociationsCard() {
    if (_clinicAssociations.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Clinic Affiliations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ColorTokens.navy),
              ),
              const SizedBox(height: 12),
              const Text(
                'You are not currently affiliated with any clinic. Clinics can invite you to join their team.',
                style: TextStyle(color: ColorTokens.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Associated Clinics & Consultation Fees',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ColorTokens.navy),
            ),
            const SizedBox(height: 12),
            ..._clinicAssociations.map((assoc) {
              final clinic = assoc['clinics'] is Map ? assoc['clinics'] as Map : {};
              final clinicName = clinic['name']?.toString() ?? 'CareFlow Health Clinic';
              final clinicPhone = clinic['phone']?.toString() ?? '';
              final clinicId = assoc['clinic_id'].toString();
              final isAssocActive = assoc['active'] == true && assoc['status'] == 'active';

              final approvedFee = assoc['approved_fee'] is num
                  ? (assoc['approved_fee'] as num).toDouble()
                  : double.tryParse(assoc['approved_fee']?.toString() ?? '');

              final proposedFee = assoc['proposed_fee'] is num
                  ? (assoc['proposed_fee'] as num).toDouble()
                  : double.tryParse(assoc['proposed_fee']?.toString() ?? '');

              final proposalStatus = (assoc['proposal_status'] ?? 'none').toString().toLowerCase();
              final hasPendingProposal = proposalStatus == 'pending' && proposedFee != null;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ColorTokens.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ColorTokens.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            clinicName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: ColorTokens.darkNavy),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isAssocActive ? ColorTokens.lightGreen : ColorTokens.border.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isAssocActive ? 'Affiliated' : 'Inactive',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isAssocActive ? ColorTokens.careGreen : ColorTokens.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (clinicPhone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(clinicPhone, style: const TextStyle(fontSize: 12, color: ColorTokens.textMuted)),
                    ],
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    // Current Approved Fee
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Approved Fee:', style: TextStyle(fontSize: 13, color: ColorTokens.muted)),
                        Text(
                          approvedFee != null ? '₹$approvedFee' : 'Not Set',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                        ),
                      ],
                    ),

                    // Pending Proposal Banner
                    if (hasPendingProposal) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ColorTokens.lightBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hourglass_top_rounded, color: ColorTokens.primaryBlue, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pending Proposal: ₹$proposedFee (Awaiting clinic review)',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ColorTokens.primaryBlue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Rejected Proposal Banner
                    if (proposalStatus == 'rejected') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ColorTokens.lightWarning.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: ColorTokens.warning, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Proposal Declined: ${assoc['rejection_reason'] ?? 'Fee does not match clinic pricing.'}',
                                style: const TextStyle(fontSize: 12, color: ColorTokens.darkNavy),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _proposeFeeDialog(clinicId, clinicName, approvedFee),
                        icon: const Icon(Icons.currency_rupee, size: 16),
                        label: Text(
                          hasPendingProposal ? 'Update Proposed Fee' : 'Propose Consultation Fee',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeHoursCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Practice Schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ColorTokens.navy,
              ),
            ),
            const SizedBox(height: 12),
            _infoRow('Working Days', 'Monday – Saturday'),
            const Divider(height: 20),
            _infoRow('Working Hours', '09:00 AM – 05:00 PM'),
            const Divider(height: 20),
            _infoRow('Slot Duration', '30 Minutes'),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: ColorTokens.primaryBlue),
            title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/doctor/notifications'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: ColorTokens.primaryBlue),
            title: const Text('Security & Password', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/auth/reset-password'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline, color: ColorTokens.primaryBlue),
            title: const Text('About CareFlow', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Version 1.0.0 • Professional Clinic Suite'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: ColorTokens.muted)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ColorTokens.navy),
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
