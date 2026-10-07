import 'package:flutter/material.dart';

import '../../../services/doctor_service.dart';

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final TextEditingController controller = TextEditingController();
  final DoctorService doctorService = DoctorService();

  List<Map<String, dynamic>> doctors = [];
  String query = '';

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await doctorService.loadDoctors();

      if (!mounted) return;

      setState(() {
        doctors = result;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  List<Map<String, dynamic>> get filteredDoctors {
    final searchText = query.trim().toLowerCase();

    if (searchText.isEmpty) {
      return doctors;
    }

    return doctors.where((doctor) {
      final name = (doctor['full_name'] ?? '').toString().toLowerCase();
      final role = (doctor['role'] ?? '').toString().toLowerCase();
      final phone = (doctor['phone'] ?? '').toString().toLowerCase();

      return name.contains(searchText) ||
          role.contains(searchText) ||
          phone.contains(searchText);
    }).toList();
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
    final filtered = filteredDoctors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Doctors'),
        actions: [
          IconButton(
            onPressed: isLoading ? null : _loadDoctors,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh doctors',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDoctors,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            TextField(
              controller: controller,
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search by doctor name',
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          controller.clear();
                          setState(() {
                            query = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 6,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: true,
                  onSelected: (_) {},
                ),
                ChoiceChip(
                  label: const Text('Doctors'),
                  selected: false,
                  onSelected: (_) {},
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (errorMessage != null)
              _buildErrorState()
            else if (filtered.isEmpty)
              _buildEmptyState()
            else ...[
              Text(
                '${filtered.length} doctor${filtered.length == 1 ? '' : 's'} available',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              ...filtered.map((doctor) => _buildDoctorCard(doctor)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final name = (doctor['full_name'] ?? 'Doctor').toString();
    final role = (doctor['role'] ?? 'doctor').toString();
    final phone = (doctor['phone'] ?? '').toString();
    final gender = (doctor['gender'] ?? '').toString();
    final age = doctor['age'];

    final details = <String>[
      'CareFlow Doctor',
      if (gender.isNotEmpty) gender,
      if (age != null) 'Age $age',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 26,
          child: Text(
            _initials(name),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(details.join(' • ')),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text('Phone: $phone'),
              ],
              const SizedBox(height: 3),
              Text(
                'Role: $role',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        isThreeLine: true,
        trailing: FilledButton(
          onPressed: () => _openBooking(doctor),
          child: const Text('Book'),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 52),
          const SizedBox(height: 16),
          const Text(
            'Unable to load doctors',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _loadDoctors,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = query.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.person_search, size: 52),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'No doctors found' : 'No doctors available',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Try searching with a different doctor name.'
                : 'There are currently no doctors available in CareFlow.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final cleaned = name.trim();

    if (cleaned.isEmpty) {
      return 'D';
    }

    final words = cleaned.split(RegExp(r'\s+'));

    if (words.length == 1) {
      return words.first
          .substring(0, words.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}
