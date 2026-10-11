import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../services/doctor_service.dart';

class DoctorDetailsScreen extends StatefulWidget {
  const DoctorDetailsScreen({super.key});

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  final _doctorService = DoctorService();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _doctor;
  String? _clinicName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDoctor();
    });
  }

  Future<void> _loadDoctor() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    String? docId;
    Map<String, dynamic>? passedDoc;

    if (args is Map) {
      if (args['doctor'] is Map) {
        passedDoc = Map<String, dynamic>.from(args['doctor'] as Map);
      }
      docId = args['doctorId']?.toString() ?? passedDoc?['id']?.toString();
    } else if (args is String) {
      docId = args;
    }

    if (docId == null && passedDoc == null) {
      setState(() {
        _loading = false;
        _error = 'No doctor information provided.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final docData = passedDoc ?? await _doctorService.getDoctorById(docId!);
      if (docData == null) {
        setState(() {
          _loading = false;
          _error = 'Doctor profile not found.';
        });
        return;
      }

      // Load clinic name if doctor is assigned to a clinic
      String? clinic;
      try {
        final cd = await Supabase.instance.client
            .from('clinic_doctors')
            .select('clinic_id, clinics(name)')
            .eq('doctor_id', docData['id'])
            .limit(1)
            .maybeSingle();

        if (cd != null && cd['clinics'] != null) {
          final cInfo = cd['clinics'];
          if (cInfo is Map && cInfo['name'] != null) {
            clinic = cInfo['name'].toString();
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _doctor = docData;
          _clinicName = clinic;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load doctor profile.';
        });
      }
    }
  }

  void _bookAppointment() {
    if (_doctor == null) return;
    Navigator.pushNamed(
      context,
      '/patient/appointments/book',
      arguments: {
        'doctorId': _doctor!['id'],
        'doctorName': _doctor!['full_name'] ?? 'Doctor',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Doctor Profile'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: ColorTokens.error),
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: ColorTokens.muted)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDoctor,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _doctor == null
                  ? const Center(child: Text('Doctor not found'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 16),
                        _buildDetailsCard(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _bookAppointment,
                            icon: const Icon(Icons.calendar_month_rounded),
                            label: const Text(
                              'Book Appointment',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildHeaderCard() {
    final name = _doctor!['full_name'] ?? 'Doctor';
    final spec = _doctor!['specialization'] ?? 'Specialist';
    final qual = _doctor!['qualification'];
    final exp = _doctor!['experience'];

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
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: ColorTokens.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: ColorTokens.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              spec,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ColorTokens.primaryBlue,
              ),
            ),
            if (qual != null && qual.toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                qual.toString(),
                style: const TextStyle(fontSize: 13, color: ColorTokens.muted),
              ),
            ],
            if (exp != null) ...[
              const SizedBox(height: 4),
              Text(
                '$exp years experience',
                style: const TextStyle(fontSize: 13, color: ColorTokens.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    final fee = _doctor!['consultation_fee'];
    final phone = _doctor!['phone'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Clinic & Practice Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ColorTokens.navy,
              ),
            ),
            const SizedBox(height: 12),
            _infoRow(
              Icons.local_hospital_outlined,
              'Clinic',
              _clinicName ?? 'CareFlow Partner Clinic',
            ),
            if (fee != null) ...[
              const Divider(height: 20),
              _infoRow(
                Icons.payments_outlined,
                'Consultation Fee',
                '₹$fee',
              ),
            ],
            if (phone != null && phone.toString().isNotEmpty) ...[
              const Divider(height: 20),
              _infoRow(
                Icons.phone_outlined,
                'Contact',
                phone.toString(),
              ),
            ],
            const Divider(height: 20),
            _infoRow(
              Icons.check_circle_outline,
              'Status',
              'Available for Consultation',
              valueColor: ColorTokens.careGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: ColorTokens.primaryBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: ColorTokens.muted)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? ColorTokens.navy,
                ),
              ),
            ],
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
