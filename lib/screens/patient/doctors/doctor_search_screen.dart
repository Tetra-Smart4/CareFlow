import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../services/doctor_service.dart';

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _symptomController = TextEditingController();
  final DoctorService _doctorService = DoctorService();

  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _selectedTab = 0; // 0: Search Doctors, 1: Find by Symptoms
  String? _recommendedSpecialty;
  final Set<String> _selectedSymptoms = {};

  final List<Map<String, dynamic>> _popularSymptoms = [
    {'name': 'Fever', 'specialty': 'General Physician'},
    {'name': 'Cough & Cold', 'specialty': 'General Physician'},
    {'name': 'Headache', 'specialty': 'General Physician'},
    {'name': 'Chest Pain', 'specialty': 'Cardiologist'},
    {'name': 'Skin Rash', 'specialty': 'Dermatologist'},
    {'name': 'Joint Pain', 'specialty': 'Orthopedic Specialist'},
    {'name': 'Stomach Ache', 'specialty': 'Gastroenterologist'},
    {'name': 'Toothache', 'specialty': 'Dentist'},
    {'name': 'Ear / Throat Pain', 'specialty': 'ENT Specialist'},
    {'name': 'Eye Irritation', 'specialty': 'Ophthalmologist'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _symptomController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _doctorService.loadDoctors();
      if (!mounted) return;
      setState(() {
        _doctors = result;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  void _onSymptomTextChanged(String text) {
    if (text.trim().isEmpty && _selectedSymptoms.isEmpty) {
      setState(() {
        _recommendedSpecialty = null;
      });
      return;
    }

    final query = text.toLowerCase();
    String? matched;

    if (query.contains('chest') || query.contains('heart') || query.contains('palpitation')) {
      matched = 'Cardiologist';
    } else if (query.contains('skin') || query.contains('rash') || query.contains('itch') || query.contains('acne')) {
      matched = 'Dermatologist';
    } else if (query.contains('bone') || query.contains('joint') || query.contains('fracture') || query.contains('back pain')) {
      matched = 'Orthopedic Specialist';
    } else if (query.contains('stomach') || query.contains('belly') || query.contains('vomit') || query.contains('acid')) {
      matched = 'Gastroenterologist';
    } else if (query.contains('tooth') || query.contains('teeth') || query.contains('dental') || query.contains('gum')) {
      matched = 'Dentist';
    } else if (query.contains('ear') || query.contains('throat') || query.contains('sinus')) {
      matched = 'ENT Specialist';
    } else if (query.contains('eye') || query.contains('vision')) {
      matched = 'Ophthalmologist';
    } else if (query.isNotEmpty) {
      matched = 'General Physician';
    }

    setState(() {
      _recommendedSpecialty = matched;
    });
  }

  void _toggleSymptomChip(String name, String specialty) {
    setState(() {
      if (_selectedSymptoms.contains(name)) {
        _selectedSymptoms.remove(name);
      } else {
        _selectedSymptoms.add(name);
      }

      if (_selectedSymptoms.isNotEmpty) {
        // Map based on selected chips
        for (final item in _popularSymptoms) {
          if (_selectedSymptoms.contains(item['name'])) {
            _recommendedSpecialty = item['specialty'] as String;
            break;
          }
        }
      } else if (_symptomController.text.isNotEmpty) {
        _onSymptomTextChanged(_symptomController.text);
      } else {
        _recommendedSpecialty = null;
      }
    });
  }

  List<Map<String, dynamic>> get _filteredDoctors {
    if (_selectedTab == 0) {
      final q = _searchController.text.trim().toLowerCase();
      if (q.isEmpty) return _doctors;
      return _doctors.where((doc) {
        final name = (doc['full_name'] ?? '').toString().toLowerCase();
        final spec = (doc['specialization'] ?? '').toString().toLowerCase();
        return name.contains(q) || spec.contains(q);
      }).toList();
    } else {
      // Find by symptoms
      if (_recommendedSpecialty == null) return _doctors;
      final target = _recommendedSpecialty!.toLowerCase();

      final matching = _doctors.where((doc) {
        final spec = (doc['specialization'] ?? '').toString().toLowerCase();
        return spec.contains(target) || target.contains(spec);
      }).toList();

      // If no doctor has the exact specialized keyword, return all doctors so patient has healthcare access
      return matching.isNotEmpty ? matching : _doctors;
    }
  }

  void _openDoctorProfile(Map<String, dynamic> doctor) {
    Navigator.pushNamed(
      context,
      '/patient/doctors/detail',
      arguments: {'doctor': doctor, 'doctorId': doctor['id']},
    );
  }

  void _openBooking(Map<String, dynamic> doctor) {
    Navigator.pushNamed(
      context,
      '/patient/appointments/book',
      arguments: {'doctorId': doctor['id'], 'doctorName': doctor['full_name']},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Find Doctors'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadDoctors,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDoctors,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tab Selector
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Search Doctors')),
                    selected: _selectedTab == 0,
                    onSelected: (val) {
                      if (val) setState(() => _selectedTab = 0);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Find by Symptoms')),
                    selected: _selectedTab == 1,
                    onSelected: (val) {
                      if (val) setState(() => _selectedTab = 1);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_selectedTab == 0) _buildDoctorSearchControls() else _buildSymptomSearchControls(),

            const SizedBox(height: 16),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              _buildErrorState()
            else if (_filteredDoctors.isEmpty)
              _buildEmptyState()
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filteredDoctors.length} Doctor${_filteredDoctors.length == 1 ? '' : 's'} Available',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ColorTokens.navy,
                    ),
                  ),
                  if (_recommendedSpecialty != null && _selectedTab == 1)
                    Text(
                      'Matching: $_recommendedSpecialty',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ColorTokens.primaryBlue,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ..._filteredDoctors.map(_buildDoctorCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorSearchControls() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: 'Search by doctor name or specialty',
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              )
            : null,
      ),
    );
  }

  Widget _buildSymptomSearchControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _symptomController,
          onChanged: _onSymptomTextChanged,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.healing_rounded),
            hintText: 'Describe symptoms (e.g. fever, headache, chest pain)',
            suffixIcon: _symptomController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _symptomController.clear();
                      _onSymptomTextChanged('');
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Common Symptoms:',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ColorTokens.muted),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _popularSymptoms.map((sym) {
            final name = sym['name'] as String;
            final spec = sym['specialty'] as String;
            final isSelected = _selectedSymptoms.contains(name);
            return FilterChip(
              label: Text(name),
              selected: isSelected,
              onSelected: (_) => _toggleSymptomChip(name, spec),
            );
          }).toList(),
        ),
        if (_recommendedSpecialty != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ColorTokens.lightBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorTokens.primaryBlue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: ColorTokens.primaryBlue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Suggested Specialty: $_recommendedSpecialty',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: ColorTokens.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'These symptoms may be suitable for consultation with a $_recommendedSpecialty.',
                  style: const TextStyle(fontSize: 13, color: ColorTokens.navy, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Important: This guidance is an automated specialty suggestion and NOT a medical diagnosis. Please consult a qualified doctor for medical evaluation.',
                  style: TextStyle(fontSize: 11, color: ColorTokens.muted, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final name = (doctor['full_name'] ?? 'Doctor').toString();
    final spec = (doctor['specialization'] ?? 'Specialist').toString();
    final qual = doctor['qualification']?.toString();
    final fee = doctor['consultation_fee'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: ColorTokens.lightBlue,
                  child: Text(
                    _initials(name),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ColorTokens.primaryBlue,
                    ),
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
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: ColorTokens.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        spec,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: ColorTokens.primaryBlue,
                        ),
                      ),
                      if (qual != null && qual.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          qual,
                          style: const TextStyle(fontSize: 12, color: ColorTokens.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                if (fee != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorTokens.lightGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '₹$fee',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: ColorTokens.careGreen,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _openDoctorProfile(doctor),
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: const Text('View Profile'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _openBooking(doctor),
                  style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: const Text('Book Appointment'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: const [
            Icon(Icons.person_search_rounded, size: 52, color: ColorTokens.muted),
            SizedBox(height: 12),
            Text(
              'No doctors found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ColorTokens.navy),
            ),
            SizedBox(height: 4),
            Text(
              'Try adjusting your search terms or symptoms.',
              style: TextStyle(color: ColorTokens.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52, color: ColorTokens.error),
            const SizedBox(height: 12),
            const Text(
              'Unable to load doctors',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ColorTokens.navy),
            ),
            const SizedBox(height: 4),
            Text(_errorMessage ?? 'Something went wrong.', style: const TextStyle(color: ColorTokens.muted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDoctors,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
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
