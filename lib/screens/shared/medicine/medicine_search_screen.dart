import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../models/medicine_item.dart';
import '../../../repositories/medicine_repository.dart';
import 'medicine_details_screen.dart';

class MedicineSearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String role; // 'patient', 'doctor', 'clinic', 'staff', 'family'

  const MedicineSearchScreen({
    super.key,
    this.initialQuery,
    this.role = 'patient',
  });

  @override
  State<MedicineSearchScreen> createState() => _MedicineSearchScreenState();
}

class _MedicineSearchScreenState extends State<MedicineSearchScreen> {
  final MedicineRepository _repository = MedicineRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<MedicineItem> _results = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedDosageForm = 'All';
  MedicineVerificationStatus? _selectedStatus;
  Timer? _debounceTimer;

  final List<String> _dosageForms = [
    'All',
    'Tablet',
    'Capsule',
    'Inhaler',
    'Syrup',
    'Suspension',
    'Injection',
    'Infusion',
    'Ointment',
    'Cream',
    'Drops',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialQuery!.trim();
    }
    _executeSearch(_searchController.text);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executeSearch(value);
    });
  }

  Future<void> _executeSearch(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _repository.searchMedicines(
        query: query,
        dosageForm: _selectedDosageForm == 'All' ? null : _selectedDosageForm,
        status: _selectedStatus,
        limit: 30,
      );

      if (mounted) {
        setState(() {
          _results = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to complete medicine search. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Color get _roleAccentColor {
    switch (widget.role.toLowerCase()) {
      case 'doctor':
        return const Color(0xFF0284C7); // Clinical Blue
      case 'clinic':
      case 'admin':
        return const Color(0xFFD97706); // Amber / Orange
      case 'patient':
      default:
        return const Color(0xFF0D9488); // Teal
    }
  }

  Color _getVerificationColor(MedicineVerificationStatus status) {
    switch (status) {
      case MedicineVerificationStatus.verified:
        return const Color(0xFF10B981); // Emerald Green
      case MedicineVerificationStatus.partiallyVerified:
        return const Color(0xFF0284C7); // Blue
      case MedicineVerificationStatus.underReview:
        return const Color(0xFFF59E0B); // Amber
      case MedicineVerificationStatus.withdrawn:
        return const Color(0xFFEF4444); // Red
      case MedicineVerificationStatus.notVerified:
        return const Color(0xFF64748B); // Slate Muted
    }
  }

  Widget _buildVerificationBadge(MedicineVerificationStatus status) {
    final color = _getVerificationColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == MedicineVerificationStatus.verified
                ? Icons.verified_rounded
                : status == MedicineVerificationStatus.withdrawn
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _roleAccentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.medication_rounded, color: _roleAccentColor, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Medicine Intelligence',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Column(
            children: [
              // Search Input Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ColorTokens.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    onSubmitted: _executeSearch,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: widget.role == 'doctor'
                          ? 'Search medicine name, brand or ingredient...'
                          : widget.role == 'clinic'
                              ? 'Search medicine name, brand or ingredient...'
                              : 'Search medicine name or brand...',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: ColorTokens.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(Icons.search_rounded, color: _roleAccentColor),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: ColorTokens.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                _executeSearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),

              // Filter Chips
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _dosageForms.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final form = _dosageForms[index];
                    final isSelected = _selectedDosageForm == form;
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() => _selectedDosageForm = form);
                        _executeSearch(_searchController.text);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? _roleAccentColor : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? _roleAccentColor : ColorTokens.border,
                          ),
                        ),
                        child: Text(
                          form,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : ColorTokens.darkNavy,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Searching approved medicine catalogue...',
              style: TextStyle(color: ColorTokens.textSecondary, fontSize: 13.5),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: ColorTokens.error, size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ColorTokens.darkNavy),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _executeSearch(_searchController.text),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry Search'),
              ),
            ],
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: ColorTokens.lightBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search_off_rounded, color: _roleAccentColor, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Medicines Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text.trim().isEmpty
                    ? 'Search by Indian brand name (e.g., Dolo, Augmentin, Glycomet), generic name, or active ingredient.'
                    : 'No matches found for "${_searchController.text}". Check your spelling or try searching by generic ingredient.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5, color: ColorTokens.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildSearchSuggestionChip('Paracetamol'),
                  _buildSearchSuggestionChip('Augmentin'),
                  _buildSearchSuggestionChip('Metformin'),
                  _buildSearchSuggestionChip('Pantoprazole'),
                  _buildSearchSuggestionChip('Asthalin Inhaler'),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final medicine = _results[index];
        return _buildMedicineCard(medicine);
      },
    );
  }

  Widget _buildSearchSuggestionChip(String query) {
    return ActionChip(
      label: Text(query),
      backgroundColor: Colors.white,
      side: const BorderSide(color: ColorTokens.border),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _roleAccentColor,
      ),
      onPressed: () {
        _searchController.text = query;
        _executeSearch(query);
      },
    );
  }

  Widget _buildMedicineCard(MedicineItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorTokens.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MedicineDetailsScreen(
                  medicine: item,
                  role: widget.role,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Classification & Verification Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ColorTokens.lightBlue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.classification.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: ColorTokens.primaryBlue,
                        ),
                      ),
                    ),
                    _buildVerificationBadge(item.verificationStatus),
                  ],
                ),
                const SizedBox(height: 10),

                // Medicine Name & Dosage form chip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: ColorTokens.darkNavy,
                            ),
                          ),
                          if (item.genericName.isNotEmpty && item.genericName != item.name) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.genericName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: ColorTokens.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.dosageForm} • ${item.strength}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ColorTokens.darkNavy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Ingredients / Active Composition
                if (item.ingredients.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.science_outlined, size: 14, color: ColorTokens.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.ingredients.join(' • '),
                          style: const TextStyle(
                            fontSize: 12,
                            color: ColorTokens.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],

                // Overview snippet
                Text(
                  item.overview,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: ColorTokens.darkNavy,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: ColorTokens.border),
                const SizedBox(height: 8),

                // Bottom row: Manufacturer & Navigation Arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.manufacturer ?? 'Regulated Indian Formulation',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ColorTokens.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _roleAccentColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 11, color: _roleAccentColor),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
