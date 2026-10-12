import 'package:flutter/material.dart';
import '../../core/theme/color_tokens.dart';
import '../../screens/shared/medicine/medicine_search_screen.dart';

enum MedicineCardRole {
  patient,
  doctor,
  clinic,
}

class MedicineSearchBarCard extends StatefulWidget {
  final MedicineCardRole role;
  final VoidCallback? onCustomTap;

  const MedicineSearchBarCard({
    super.key,
    required this.role,
    this.onCustomTap,
  });

  @override
  State<MedicineSearchBarCard> createState() => _MedicineSearchBarCardState();
}

class _MedicineSearchBarCardState extends State<MedicineSearchBarCard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openSearch([String? query]) {
    final effectiveQuery = query ?? _controller.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicineSearchScreen(
          role: widget.role.name,
          initialQuery: effectiveQuery.isNotEmpty ? effectiveQuery : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.role) {
      case MedicineCardRole.patient:
        return _buildPatientTealCard();
      case MedicineCardRole.doctor:
        return _buildDoctorBlueCard();
      case MedicineCardRole.clinic:
        return _buildClinicAmberCard();
    }
  }

  /// Patient Dashboard: Prominent Teal Card
  Widget _buildPatientTealCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Pill Icon & Title
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medication_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Medicine Intelligence',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Search medicines and explore symptom guidance',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFCCFBF1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rounded White Search Field inside the Teal Card
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openSearch(),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Icon(Icons.search_rounded, color: Color(0xFF0D9488), size: 22),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (val) => _openSearch(val),
                      decoration: const InputDecoration(
                        hintText: 'Search medicine name or brand...',
                        hintStyle: TextStyle(
                          fontSize: 13.5,
                          color: ColorTokens.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF0D9488), size: 20),
                    onPressed: () => _openSearch(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Doctor Dashboard: Clean Light-Blue Accent Card
  Widget _buildDoctorBlueCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Blue Icon & Titles
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medication_rounded, color: Color(0xFF0284C7), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Medicine Intelligence',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: ColorTokens.darkNavy,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Search medicines, check clinical details and review safety information',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: ColorTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search Field
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.search_rounded, color: Color(0xFF0284C7), size: 20),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (val) => _openSearch(val),
                    decoration: const InputDecoration(
                      hintText: 'Search medicine name, brand or ingredient...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: ColorTokens.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF0284C7), size: 19),
                  onPressed: () => _openSearch(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Clinic Admin Dashboard: Soft Amber/Orange Accent Card
  Widget _buildClinicAmberCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFED7AA), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Amber Icon & Titles
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medication_rounded, color: Color(0xFFD97706), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Medicine Intelligence',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: ColorTokens.darkNavy,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Search medicines, view product information and manage clinic inventory',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: ColorTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search Field
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.search_rounded, color: Color(0xFFD97706), size: 20),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (val) => _openSearch(val),
                    decoration: const InputDecoration(
                      hintText: 'Search medicine name, brand or ingredient...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: ColorTokens.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFFD97706), size: 19),
                  onPressed: () => _openSearch(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
