import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/clinic_repository.dart';
import '../../../repositories/doctor_repository.dart';
import '../../../widgets/common/careflow_feature_icon.dart';

class DoctorManagementScreen extends StatefulWidget {
  const DoctorManagementScreen({super.key});

  @override
  State<DoctorManagementScreen> createState() => _DoctorManagementScreenState();
}

class _DoctorManagementScreenState extends State<DoctorManagementScreen> {
  final _doctorRepo = DoctorRepository();
  final _clinicRepo = ClinicRepository();

  bool _loading = true;
  String? _errorMessage;
  String? _clinicId;
  List<Map<String, dynamic>> _doctors = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final clinicId = await _clinicRepo.getCurrentUserClinicId() ?? user?.id;
      _clinicId = clinicId;

      if (clinicId == null) {
        setState(() {
          _loading = false;
          _doctors = [];
        });
        return;
      }

      final list = await _doctorRepo.getByClinic(clinicId);

      if (mounted) {
        setState(() {
          _doctors = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Failed to load clinic doctors: $e';
        });
      }
    }
  }

  Future<void> _toggleAvailability(String doctorId, bool current) async {
    try {
      final clinicId = _clinicId;
      await _doctorRepo.setAvailability(doctorId, !current, clinicId: clinicId);
      await _loadDoctors();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Doctor availability updated to ${!current ? "Available" : "Unavailable"}.'),
            backgroundColor: ColorTokens.careGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update availability: $e'), backgroundColor: ColorTokens.error),
        );
      }
    }
  }

  Future<void> _resendInvitation(String doctorId, String email) async {
    try {
      final result = await _doctorRepo.resendInvitation(email, doctorId: doctorId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']?.toString() ?? 'Invitation resent successfully.'),
            backgroundColor: ColorTokens.careGreen,
          ),
        );
        _loadDoctors();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend invitation: $e'), backgroundColor: ColorTokens.error),
        );
      }
    }
  }

  Future<void> _approveFeeProposal(String doctorId, double proposedFee) async {
    final clinicId = _clinicId;
    if (clinicId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Fee Proposal'),
        content: Text(
          'Are you sure you want to approve the new consultation fee of ₹$proposedFee for this clinic?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorTokens.careGreen, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve Fee'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _doctorRepo.approveConsultationFee(doctorId, clinicId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Consultation fee of ₹$proposedFee approved successfully.'),
            backgroundColor: ColorTokens.careGreen,
          ),
        );
        _loadDoctors();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve fee: $e'), backgroundColor: ColorTokens.error),
        );
      }
    }
  }

  Future<void> _rejectFeeProposal(String doctorId, double proposedFee) async {
    final clinicId = _clinicId;
    if (clinicId == null) return;

    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Fee Proposal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter reason for declining the proposed fee of ₹$proposedFee:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g., Higher than current clinic benchmark',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorTokens.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _doctorRepo.rejectConsultationFee(
        doctorId,
        clinicId,
        reason: reasonController.text.trim().isNotEmpty
            ? reasonController.text.trim()
            : 'Does not match clinic pricing.',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fee proposal declined. Existing approved fee remains active.'),
            backgroundColor: ColorTokens.darkNavy,
          ),
        );
        _loadDoctors();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline fee: $e'), backgroundColor: ColorTokens.error),
        );
      }
    }
  }

  Future<void> _toggleDeactivation(String doctorId, bool isCurrentlyActive, String doctorName) async {
    final clinicId = _clinicId;
    if (clinicId == null) return;

    if (isCurrentlyActive) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Deactivate Doctor at Clinic'),
          content: Text(
            'Deactivating Dr. $doctorName will prevent new patient bookings at this clinic.\n\n'
            'All past consultations, prescriptions, reports, and clinical history will remain completely preserved.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ColorTokens.warning, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Deactivate'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      try {
        await _doctorRepo.deactivateDoctor(doctorId, clinicId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dr. $doctorName deactivated at this clinic.'),
              backgroundColor: ColorTokens.warning,
            ),
          );
          _loadDoctors();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to deactivate doctor: $e'), backgroundColor: ColorTokens.error),
          );
        }
      }
    } else {
      try {
        await _doctorRepo.reactivateDoctor(doctorId, clinicId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dr. $doctorName reactivated at this clinic.'),
              backgroundColor: ColorTokens.careGreen,
            ),
          );
          _loadDoctors();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reactivate doctor: $e'), backgroundColor: ColorTokens.error),
          );
        }
      }
    }
  }

  Future<void> _removeDoctorAssociation(String doctorId, String doctorName) async {
    final clinicId = _clinicId;
    if (clinicId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Doctor from Clinic'),
        content: Text(
          'Are you sure you want to remove Dr. $doctorName from this clinic?\n\n'
          '• Future bookings will be discontinued.\n'
          '• The doctor’s account and medical history remain preserved.\n'
          '• Other clinic affiliations of the doctor remain intact.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorTokens.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove Association'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _doctorRepo.removeDoctor(doctorId, clinicId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dr. $doctorName removed from this clinic.'),
            backgroundColor: ColorTokens.darkNavy,
          ),
        );
        _loadDoctors();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove doctor: $e'), backgroundColor: ColorTokens.error),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredDoctors {
    if (_searchQuery.trim().isEmpty) return _doctors;
    final q = _searchQuery.toLowerCase();
    return _doctors.where((d) {
      final name = (d['full_name'] ?? '').toLowerCase();
      final spec = (d['specialization'] ?? '').toLowerCase();
      final phone = (d['phone'] ?? '').toLowerCase();
      final email = (d['email'] ?? '').toLowerCase();
      return name.contains(q) || spec.contains(q) || phone.contains(q) || email.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Clinic Doctors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDoctors,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/clinic/doctors/add').then((_) => _loadDoctors());
        },
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Invite Doctor'),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search doctors by name, specialty, or email...',
                prefixIcon: const Icon(Icons.search, size: 20, color: ColorTokens.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ColorTokens.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ColorTokens.border)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: ColorTokens.error),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: ColorTokens.muted)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _loadDoctors, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : _filteredDoctors.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CareFlowFeatureIcon(
                                    icon: Icons.search_rounded,
                                    iconColor: ColorTokens.careGreen,
                                    backgroundColor: ColorTokens.lightGreen,
                                    containerSize: 84,
                                    iconSize: 42,
                                    borderRadius: 24,
                                    hasShadow: true,
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'No Doctors Added Yet',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Approved clinics can invite doctors to join their practice.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: ColorTokens.muted, fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/clinic/doctors/add').then((_) => _loadDoctors());
                                    },
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Invite Doctor'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadDoctors,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredDoctors.length,
                              itemBuilder: (ctx, i) {
                                final d = _filteredDoctors[i];
                                final name = d['full_name'] ?? 'Doctor';
                                final spec = d['specialization'] ?? 'General Physician';
                                final qual = d['qualification'] ?? '';
                                final regNo = d['registration_number'] ?? '';
                                final email = d['email'] ?? '';
                                final phone = d['phone'] ?? '';
                                final status = (d['status'] ?? 'active').toString().toLowerCase();
                                final isInvited = status == 'invited' || status == 'pending_activation';
                                final isInactive = status == 'inactive';
                                final isActive = status == 'active' && d['active'] == true;
                                final isAvailable = d['is_available'] == true && isActive;
                                final dId = d['id'].toString();

                                final approvedFee = d['approved_fee'] ?? d['consultation_fee'];
                                final proposedFee = d['proposed_fee'] is num ? (d['proposed_fee'] as num).toDouble() : null;
                                final proposalStatus = (d['proposal_status'] ?? 'none').toString().toLowerCase();
                                final hasPendingProposal = proposalStatus == 'pending' && proposedFee != null;

                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: hasPendingProposal
                                          ? ColorTokens.primaryBlue.withValues(alpha: 0.5)
                                          : ColorTokens.border,
                                      width: hasPendingProposal ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header Row: Avatar, Name, Specialty, Status
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 24,
                                              backgroundColor: isInvited
                                                  ? ColorTokens.lightWarning
                                                  : isInactive
                                                      ? ColorTokens.border
                                                      : ColorTokens.lightBlue,
                                              child: Text(
                                                name.isNotEmpty ? name[0].toUpperCase() : 'D',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  color: isInvited
                                                      ? ColorTokens.warning
                                                      : isInactive
                                                          ? ColorTokens.muted
                                                          : ColorTokens.primaryBlue,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                                                  ),
                                                  Text(
                                                    [spec, if (qual.isNotEmpty) qual].join(' • '),
                                                    style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                                                  ),
                                                  if (regNo.isNotEmpty)
                                                    Text('Reg: $regNo', style: const TextStyle(fontSize: 11, color: ColorTokens.textMuted)),
                                                  if (email.isNotEmpty)
                                                    Text(email, style: const TextStyle(fontSize: 11, color: ColorTokens.primaryBlue)),
                                                  if (phone.isNotEmpty)
                                                    Text(phone, style: const TextStyle(fontSize: 11, color: ColorTokens.textMuted)),
                                                ],
                                              ),
                                            ),
                                            // Status Badge
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: isInvited
                                                        ? ColorTokens.lightWarning
                                                        : isInactive
                                                            ? ColorTokens.border.withValues(alpha: 0.5)
                                                            : ColorTokens.lightGreen,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    isInvited
                                                        ? 'Invited'
                                                        : isInactive
                                                            ? 'Inactive'
                                                            : 'Active',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: isInvited
                                                          ? ColorTokens.warning
                                                          : isInactive
                                                              ? ColorTokens.muted
                                                              : ColorTokens.careGreen,
                                                    ),
                                                  ),
                                                ),
                                                if (approvedFee != null) ...[
                                                  const SizedBox(height: 4),
                                                  Text('₹$approvedFee', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy)),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),

                                        // Fee Proposal Banner (if doctor proposed a new fee)
                                        if (hasPendingProposal) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: ColorTokens.lightBlue,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: ColorTokens.primaryBlue.withValues(alpha: 0.3)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.currency_rupee, color: ColorTokens.primaryBlue, size: 18),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        'Proposed Fee: ₹$proposedFee (Current: ₹${approvedFee ?? 'None'})',
                                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ColorTokens.darkNavy),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    OutlinedButton(
                                                      onPressed: () => _rejectFeeProposal(dId, proposedFee),
                                                      style: OutlinedButton.styleFrom(
                                                        foregroundColor: ColorTokens.error,
                                                        side: const BorderSide(color: ColorTokens.error),
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      ),
                                                      child: const Text('Decline'),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    ElevatedButton(
                                                      onPressed: () => _approveFeeProposal(dId, proposedFee),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: ColorTokens.careGreen,
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                      ),
                                                      child: const Text('Approve Fee'),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],

                                        // Invitation Resend Banner (if invited)
                                        if (isInvited) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: ColorTokens.lightWarning.withValues(alpha: 0.5),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.schedule_send_rounded, color: ColorTokens.warning, size: 18),
                                                const SizedBox(width: 8),
                                                const Expanded(
                                                  child: Text(
                                                    'Invitation sent. Pending password setup by doctor.',
                                                    style: TextStyle(fontSize: 12, color: ColorTokens.darkNavy),
                                                  ),
                                                ),
                                                TextButton.icon(
                                                  onPressed: () => _resendInvitation(dId, email),
                                                  icon: const Icon(Icons.send_rounded, size: 14),
                                                  label: const Text('Resend', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],

                                        const SizedBox(height: 12),
                                        const Divider(height: 1, color: ColorTokens.border),
                                        const SizedBox(height: 10),

                                        // Actions Bar
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Duty availability switch (only when active)
                                            if (isActive)
                                              Row(
                                                children: [
                                                  const Text('On-Duty', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ColorTokens.darkNavy)),
                                                  const SizedBox(width: 4),
                                                  Switch(
                                                    value: isAvailable,
                                                    activeThumbColor: ColorTokens.careGreen,
                                                    onChanged: (_) => _toggleAvailability(dId, isAvailable),
                                                  ),
                                                ],
                                              )
                                            else
                                              Text(
                                                isInactive ? 'Association Inactive' : 'Account Pending',
                                                style: const TextStyle(fontSize: 12, color: ColorTokens.muted, fontStyle: FontStyle.italic),
                                              ),

                                            // Association Actions Menu
                                            PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert_rounded, color: ColorTokens.darkNavy),
                                              onSelected: (val) {
                                                if (val == 'toggle_status') {
                                                  _toggleDeactivation(dId, isActive, name);
                                                } else if (val == 'remove') {
                                                  _removeDoctorAssociation(dId, name);
                                                } else if (val == 'resend') {
                                                  _resendInvitation(dId, email);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                if (isInvited)
                                                  const PopupMenuItem(
                                                    value: 'resend',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.send_rounded, size: 18, color: ColorTokens.primaryBlue),
                                                        SizedBox(width: 8),
                                                        Text('Resend Invitation'),
                                                      ],
                                                    ),
                                                  ),
                                                PopupMenuItem(
                                                  value: 'toggle_status',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                                                        size: 18,
                                                        color: isActive ? ColorTokens.warning : ColorTokens.careGreen,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(isActive ? 'Deactivate Doctor' : 'Reactivate Doctor'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'remove',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.person_remove_outlined, size: 18, color: ColorTokens.error),
                                                      SizedBox(width: 8),
                                                      Text('Remove Association', style: TextStyle(color: ColorTokens.error)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
