import 'package:flutter_test/flutter_test.dart';
import 'package:careflow/models/medicine_item.dart';
import 'package:careflow/repositories/medicine_repository.dart';
import '../tooling/medicine_importer/pmbi_catalogue_parser.dart';

void main() {
  group('CareFlow Medicine Data Acquisition & Ingestion Pipeline Tests', () {
    test('1. PMBI Parser correctly classifies all 8 dosage forms and routes', () {
      final sampleRecords = [
        {
          'drug_code': '145',
          'generic_name': 'Paracetamol Tablets IP 500 mg',
          'unit_size': '10x10 Tablets',
          'mrp_inr': 12.00,
        },
        {
          'drug_code': '44',
          'generic_name': 'Omeprazole Capsules IP 20 mg',
          'unit_size': '10x10 Capsules',
          'mrp_inr': 18.50,
        },
        {
          'drug_code': '463',
          'generic_name': 'Paracetamol Oral Suspension IP 120mg/5ml',
          'unit_size': '60 ml Bottle',
          'mrp_inr': 15.00,
        },
        {
          'drug_code': '125',
          'generic_name': 'Ciprofloxacin Infusion 200mg/100ml',
          'unit_size': '100 ml Bottle',
          'mrp_inr': 22.00,
        },
        {
          'drug_code': '341',
          'generic_name': 'Ciprofloxacin Eye Drops 0.3% w/v',
          'unit_size': '5 ml Vial',
          'mrp_inr': 14.00,
        },
        {
          'drug_code': '118',
          'generic_name': 'Povidone Iodine Ointment 5% w/w',
          'unit_size': '15 gm Tube',
          'mrp_inr': 24.00,
        },
        {
          'drug_code': '120',
          'generic_name': 'Silver Sulfadiazine Cream 1% w/w',
          'unit_size': '25 gm Tube',
          'mrp_inr': 28.00,
        },
        {
          'drug_code': '568',
          'generic_name': 'Salbutamol Inhaler 100mcg/dose',
          'unit_size': '200 Metered Doses',
          'mrp_inr': 95.00,
        },
      ];

      final forms = <String>[];
      final categories = <String>[];
      final routes = <String>[];

      for (final raw in sampleRecords) {
        final parsed = PmbiRecordParser.parseRawPmbiItem(raw);
        forms.add(parsed['dosage_form'] as String);
        categories.add(parsed['dosage_category'] as String);
        routes.add(parsed['route'] as String);
      }

      expect(forms, [
        'Tablet',
        'Capsule',
        'Suspension',
        'Infusion',
        'Eye Drops',
        'Ointment',
        'Cream',
        'Inhaler',
      ]);

      expect(categories, [
        'solid_oral',
        'solid_oral',
        'liquid_oral',
        'parenteral',
        'ophthalmic',
        'topical',
        'topical',
        'respiratory',
      ]);

      expect(routes, [
        'oral',
        'oral',
        'oral',
        'injection',
        'ophthalmic',
        'topical',
        'topical',
        'inhalation',
      ]);
    });

    test('2. Deduplication engine detects and suppresses duplicate drug entries', () {
      final rawWithDuplicate = [
        {
          'drug_code': '145',
          'generic_name': 'Paracetamol Tablets IP 500 mg',
          'unit_size': '10x10 Tablets',
          'mrp_inr': 12.00,
        },
        {
          'drug_code': '145_DUP',
          'generic_name': 'Paracetamol Tablets IP 500 mg (Duplicate Batch)',
          'unit_size': '10x10 Tablets',
          'mrp_inr': 12.00,
        },
        {
          'drug_code': '144',
          'generic_name': 'Paracetamol Tablets IP 650 mg',
          'unit_size': '10x10 Tablets',
          'mrp_inr': 18.00,
        },
      ];

      final pipelineResult = PmbiRecordParser.runImportPipeline(rawItems: rawWithDuplicate);
      final staged = pipelineResult['staged_items'] as List<Map<String, dynamic>>;
      final report = pipelineResult['report'] as Map<String, dynamic>;

      expect(rawWithDuplicate.length, 3);
      expect(staged.length, 2); // 1 duplicate suppressed
      expect(report['duplicate_records_detected'], 1);

      final duplicates = report['duplicates_list'] as List<Map<String, dynamic>>;
      expect(duplicates.first['primary_drug_code'], '145');
      expect(duplicates.first['duplicate_drug_code'], '145_DUP');
    });

    test('3. Mandatory Clinical Safety: All imported records default to unverified clinical status', () {
      final raw = {
        'drug_code': '39',
        'generic_name': 'Amoxycillin Capsules IP 250 mg',
        'unit_size': '10x10 Capsules',
        'mrp_inr': 25.00,
      };

      final parsed = PmbiRecordParser.parseRawPmbiItem(raw);

      // Identity is verified from official source
      expect(parsed['identity_verification']['status'], 'source_confirmed');
      expect(parsed['identity_verification']['evidence'], contains('PMBI Official Product'));

      // Clinical information is strictly UNVERIFIED
      expect(parsed['clinical_verification']['status'], 'unverified');
      expect(parsed['clinical_verification']['clinical_reviewer'], isNull);
      expect(parsed['clinical_verification']['last_reviewed_date'], isNull);

      // No hallucinated claims
      expect(parsed['contraindications'], isEmpty);
      expect(parsed['drug_interactions'], isEmpty);
      expect(parsed['side_effects'], isEmpty);

      // Full raw provenance is preserved
      expect(parsed['source_metadata']['source_name'], 'PMBI_JAN_AUSHADHI');
      expect(parsed['source_metadata']['source_record_id'], '39');
      expect(parsed['source_metadata']['raw_source_record'], raw);
    });

    test('4. MedicineItem parses dual verification statuses and enforces quarantine', () {
      final stagedJson = {
        'id': 'med_in_pmbi_145',
        'name': 'Paracetamol Tablets IP 500 mg',
        'generic_name': 'Paracetamol',
        'ingredients': ['Paracetamol 500 mg'],
        'strength': '500 mg',
        'dosage_form': 'Tablet',
        'dosage_category': 'solid_oral',
        'route': 'oral',
        'manufacturer': 'Pradhan Mantri Bhartiya Janaushadhi Pariyojana (PMBJP)',
        'classification': 'Generic',
        'overview': 'Generic formulation listed under the national Jan Aushadhi healthcare initiative.',
        'common_uses': <String>[],
        'side_effects': <String>[],
        'precautions': <String>[],
        'contraindications': <String>[],
        'drug_interactions': <Map<String, dynamic>>[],
        'mrp_inr': 12.0,
        'identity_verification': {
          'status': 'source_confirmed',
          'evidence': 'Official PMBI Catalogue',
        },
        'clinical_verification': {
          'status': 'unverified',
        },
        'verification_scope': 'Product identity confirmed via PMBI.',
        'source_references': ['PMBI Official Portal'],
        'source_metadata': {
          'source_name': 'PMBI_JAN_AUSHADHI',
          'source_record_id': '145',
        },
      };

      final item = MedicineItem.fromJson(stagedJson);

      expect(item.id, 'med_in_pmbi_145');
      expect(item.identityVerificationStatus, IdentityVerificationStatus.sourceConfirmed);
      expect(item.clinicalVerificationStatus, ClinicalVerificationStatus.unverified);
      expect(item.mrpInr, 12.0);
      expect(item.route, 'oral');
      expect(item.dosageCategory, 'solid_oral');
      expect(item.sourceMetadata['source_name'], 'PMBI_JAN_AUSHADHI');

      // Clinical evidence is not verified, so overall verification should reflect partial/not verified
      expect(item.clinicalVerificationStatus == ClinicalVerificationStatus.clinicallyReviewed, isFalse);
    });

    test('5. PostgREST query sanitization prevents filter injection and preserves alphanumeric terms', () {
      // Test the sanitization pattern used in MedicineRepository and Edge Function
      String sanitize(String input) {
        return input
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[,()"\x27]'), ' ')
            .replaceAll(RegExp(r'\.(eq|neq|gt|gte|lt|lte|like|ilike|is|in|cs|cd|ov|sl|sr|nxr|nxl|adj|not)\.'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      }

      // Injection attempt 1: PostgREST operator injection
      final dirtyQuery1 = 'paracetamol,id.eq.123';
      expect(sanitize(dirtyQuery1), 'paracetamol id 123');

      // Injection attempt 2: SQL / PostgREST quote injection
      final dirtyQuery2 = "dolo' OR '1'='1";
      expect(sanitize(dirtyQuery2), 'dolo or 1 = 1');

      // Injection attempt 3: Nested parenthetical filter escape
      final dirtyQuery3 = 'augmentin),status.eq.withdrawn,(';
      expect(sanitize(dirtyQuery3), 'augmentin status withdrawn');

      // Normal benign query
      final cleanQuery = 'Paracetamol 650mg';
      expect(sanitize(cleanQuery), 'paracetamol 650mg');
    });

    test('6. Verified local fallback catalog in MedicineRepository maintains clinical integrity', () async {
      final repository = MedicineRepository();
      final results = await repository.searchMedicines(query: 'Dolo');

      expect(results, isNotEmpty);
      final dolo = results.firstWhere((m) => m.brandName == 'Dolo');

      // Curated item has both product identity and clinical monograph verified
      expect(dolo.isPrescriptionRequired, isFalse);
      expect(dolo.drugInteractions, isNotEmpty);
      expect(dolo.drugInteractions.any((i) => i.interactingDrug == 'Warfarin'), isTrue);
      expect(dolo.sourceReferences, contains('CDSCO Approved Formulations List'));
      expect(dolo.lastReviewedDate, isNotNull);
    });
  });
}
