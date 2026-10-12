import 'dart:convert';
import 'dart:io';
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

    test('2. Deduplication engine detects duplicate raw rows sharing the same drug code', () {
      final rawWithDuplicate = [
        {
          'sr_no': '1',
          'drug_code': '145',
          'generic_name': 'Paracetamol Tablets IP 500 mg',
          'unit_size': '10x10 Tablets',
          'mrp_inr': 12.00,
        },
        {
          'sr_no': '2',
          'drug_code': '145', // Exact duplicate PMBI Drug Code
          'generic_name': 'Paracetamol Tablets IP 500 mg (Duplicate Batch)',
          'unit_size': '10x10 Tablets',
          'mrp_inr': 12.00,
        },
        {
          'sr_no': '3',
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
      expect(report['duplicate_source_rows_count'], 1);

      final duplicates = report['duplicate_source_rows'] as List<Map<String, dynamic>>;
      expect(duplicates.first['drug_code'], '145');
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
      String sanitize(String input) {
        return input
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[,()"\x27]'), ' ')
            .replaceAll(RegExp(r'\.(eq|neq|gt|gte|lt|lte|like|ilike|is|in|cs|cd|ov|sl|sr|nxr|nxl|adj|not)\.'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      }

      final dirtyQuery1 = 'paracetamol,id.eq.123';
      expect(sanitize(dirtyQuery1), 'paracetamol id 123');

      final dirtyQuery2 = "dolo' OR '1'='1";
      expect(sanitize(dirtyQuery2), 'dolo or 1 = 1');

      final dirtyQuery3 = 'augmentin),status.eq.withdrawn,(';
      expect(sanitize(dirtyQuery3), 'augmentin status withdrawn');

      final cleanQuery = 'Paracetamol 650mg';
      expect(sanitize(cleanQuery), 'paracetamol 650mg');
    });

    test('6. Verified local fallback catalog in MedicineRepository maintains clinical integrity', () async {
      final repository = MedicineRepository();
      final results = await repository.searchMedicines(query: 'Dolo');

      expect(results, isNotEmpty);
      final dolo = results.firstWhere((m) => m.brandName == 'Dolo');

      expect(dolo.isPrescriptionRequired, isFalse);
      expect(dolo.drugInteractions, isNotEmpty);
      expect(dolo.drugInteractions.any((i) => i.interactingDrug == 'Warfarin'), isTrue);
      expect(dolo.sourceReferences, contains('CDSCO Approved Formulations List'));
      expect(dolo.lastReviewedDate, isNotNull);
    });

    test('7. SKU Preservation: Different drug codes remain separate even with identical names or formulations', () {
      final items = [
        {
          'drug_code': '124',
          'generic_name': 'Povidone Iodine Ointment 5% w/w',
          'unit_size': '250 gm tubes/Jar',
          'mrp_inr': 107.82,
        },
        {
          'drug_code': '125',
          'generic_name': 'Povidone Iodine Ointment 5% w/w',
          'unit_size': '15 gm tubes',
          'mrp_inr': 14.44,
        },
      ];

      final result = PmbiRecordParser.runImportPipeline(rawItems: items);
      final staged = result['staged_items'] as List<Map<String, dynamic>>;

      // Both SKUs must be preserved
      expect(staged.length, 2);
      expect(staged[0]['id'], 'med_in_pmbi_124');
      expect(staged[1]['id'], 'med_in_pmbi_125');
      expect(staged[0]['pack_size'], '250 gm tubes/Jar');
      expect(staged[1]['pack_size'], '15 gm tubes');
      expect(staged[0]['mrp_inr'], 107.82);
      expect(staged[1]['mrp_inr'], 14.44);

      // They share the exact same formulation key as a clinical concept
      expect(staged[0]['formulation_key'], staged[1]['formulation_key']);
      expect(staged[0]['formulation_key'], contains('povidone_iodine_5_percent_w_w_ointment'));
    });

    test('8. Formulation Key: Different combination ingredient strengths produce distinct keys', () {
      final item1 = PmbiRecordParser.parseRawPmbiItem({
        'drug_code': '214',
        'generic_name': 'Rabeprazole 20mg (Enteric Coated) and Domperidone 30mg (Sustained Release) Capsules',
        'unit_size': "10's",
        'mrp_inr': 16.88,
      });

      final item2 = PmbiRecordParser.parseRawPmbiItem({
        'drug_code': '682',
        'generic_name': 'Rabeprazole 20mg and Domperidone 10mg Capsules',
        'unit_size': "10's",
        'mrp_inr': 20.63,
      });

      // Formulation keys must be distinct because Domperidone strength differs (30mg vs 10mg)
      expect(item1['formulation_key'], isNot(equals(item2['formulation_key'])));
      expect(item1['formulation_key'], contains('domperidone_30mg'));
      expect(item2['formulation_key'], contains('domperidone_10mg'));
    });

    test('9. Formulation Key: Commercial pack size and MRP do not alter the formulation key', () {
      final item1 = PmbiRecordParser.parseRawPmbiItem({
        'drug_code': '197',
        'generic_name': 'Lactulose Solution IP 10g per 15ml',
        'unit_size': '100 ml',
        'mrp_inr': 57.0,
      });

      final item2 = PmbiRecordParser.parseRawPmbiItem({
        'drug_code': '687',
        'generic_name': 'Lactulose Solution IP 10g per 15ml',
        'unit_size': '200 ml',
        'mrp_inr': 120.0,
      });

      // Keys must match despite pack size (100ml vs 200ml) and MRP (57 vs 120)
      expect(item1['formulation_key'], equals(item2['formulation_key']));
      expect(item1['formulation_key'], isNot(contains('100_ml')));
      expect(item1['formulation_key'], isNot(contains('57')));
    });

    test('10. Classification: Medical devices and surgical equipment are correctly classified', () {
      final deviceRecords = [
        {'drug_code': '5030', 'name': 'Surgical Blade, No. 22, Sterilized'},
        {'drug_code': '8078', 'name': 'Skin Grafting Knife Blade (Sterile)'},
        {'drug_code': '8120', 'name': 'Lancets, Round Sterile, 28G'},
        {'drug_code': '8128', 'name': 'Medical Digital Thermometer'},
        {'drug_code': '8172', 'name': 'Pulse Oximeter'},
        {'drug_code': '6031', 'name': 'Sterile Disposable Infusion set with Microdrip (I.V.) (Pediatric use)'},
        {'drug_code': '1460', 'name': 'Insulin Pen'},
      ];

      for (final r in deviceRecords) {
        final parsed = PmbiRecordParser.parseRawPmbiItem({
          'drug_code': r['drug_code'],
          'generic_name': r['name'],
          'unit_size': "1's",
          'mrp_inr': 50.0,
        });

        expect(parsed['dosage_form'], 'Medical Device', reason: 'Failed for ${r['name']}');
        expect(parsed['product_category'], 'medical_device', reason: 'Failed for ${r['name']}');
        expect(parsed['classification'], 'Medical Device', reason: 'Failed for ${r['name']}');
        expect(parsed['dosage_category'], 'device_consumable');
        expect(parsed['route'], 'external');
      }
    });

    test('11. Classification: Pharmaceutical strips and kits are classified as medicines', () {
      final pharmaRecords = [
        {'drug_code': '2266', 'name': 'Nicotine 2mg Oral Disintegrating Strips', 'form': 'Oral Disintegrating Strip'},
        {'drug_code': '2268', 'name': 'Ondansetron 4mg Oral Disintegrating Strips', 'form': 'Oral Disintegrating Strip'},
        {'drug_code': '2270', 'name': 'Sildenafil 50mg Oral Disintegrating Strips', 'form': 'Oral Disintegrating Strip'},
        {'drug_code': '2271', 'name': 'Vitamin D3 60000 IU Oral Disintegrating Strips', 'form': 'Oral Disintegrating Strip'},
        {'drug_code': '1892', 'name': 'Artesunate 200mg Tablets, Sulfadoxine 500mg and Pyrimethamine 25mg Tablets IP Combi kit', 'form': 'Tablet'},
        {'drug_code': '2146', 'name': 'Combikit of Eplerenone Tablets 25mg and Torsemide Tablets IP 10mg', 'form': 'Tablet'},
      ];

      for (final r in pharmaRecords) {
        final parsed = PmbiRecordParser.parseRawPmbiItem({
          'drug_code': r['drug_code'],
          'generic_name': r['name'],
          'unit_size': 'Mono carton',
          'mrp_inr': 60.0,
        });

        expect(parsed['product_category'], 'medicine', reason: 'Failed for ${r['name']}');
        expect(parsed['dosage_form'], r['form'], reason: 'Failed for ${r['name']}');
        expect(parsed['route'], 'oral', reason: 'Failed for ${r['name']}');
      }
    });

    test('12. Classification: Infusion medicines vs sterile infusion equipment', () {
      final infusionSolution = PmbiRecordParser.parseRawPmbiItem({
        'drug_code': '125',
        'generic_name': 'Ciprofloxacin Infusion 200mg/100ml',
        'unit_size': '100 ml Bottle',
        'mrp_inr': 22.0,
      });

      final infusionSet = PmbiRecordParser.parseRawPmbiItem({
        'drug_code': '6032',
        'generic_name': 'Sterile Disposable Infusion set with Microdrip (I.V.) (Adult use)',
        'unit_size': "1's",
        'mrp_inr': 14.07,
      });

      expect(infusionSolution['product_category'], 'medicine');
      expect(infusionSolution['dosage_form'], 'Infusion');
      expect(infusionSolution['route'], 'injection');

      expect(infusionSet['product_category'], 'medical_device');
      expect(infusionSet['dosage_form'], 'Medical Device');
      expect(infusionSet['route'], 'external');
    });

    test('13. Source data integrity: Genuine zero MRP is preserved and distinguished from missing', () {
      final zeroMrpItem = PmbiRecordParser.parseRawPmbiItem({
        'drug_code': '2146',
        'generic_name': 'Combikit of Eplerenone Tablets 25mg and Torsemide Tablets IP 10mg',
        'unit_size': '20 Tablets',
        'mrp_inr': 0.0,
      });

      expect(zeroMrpItem['mrp_inr'], 0.0);
      expect(zeroMrpItem['is_zero_mrp'], isTrue);
      expect(zeroMrpItem['mrp_status'], 'zero_mrp_review');

      final missingMrpItem = PmbiRecordParser.parseRawPmbiItem({
        'drug_code': '9999',
        'generic_name': 'Hypothetical Medicine Without MRP',
        'unit_size': "10's",
        'mrp_inr': null,
      });

      expect(missingMrpItem['mrp_inr'], isNull);
      expect(missingMrpItem['is_zero_mrp'], isFalse);
      expect(missingMrpItem['mrp_status'], 'missing');
    });

    test('14. Full-source dataset reconciliation: All 2,439 raw records reconcile 1:1', () {
      final sourceFile = File('tooling/medicine_importer/raw_pmbi_catalogue_full.json');
      expect(sourceFile.existsSync(), isTrue);

      final rawList = jsonDecode(sourceFile.readAsStringSync()) as List<dynamic>;
      expect(rawList.length, 2439);

      final rawItems = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final pipelineResult = PmbiRecordParser.runImportPipeline(
        rawItems: rawItems,
        sourceFilePath: sourceFile.path,
        sourceFileSizeBytes: sourceFile.lengthSync(),
      );

      final staged = pipelineResult['staged_items'] as List<Map<String, dynamic>>;
      final report = pipelineResult['report'] as Map<String, dynamic>;

      // Core Invariant 1: Exactly 2,439 staged items
      expect(staged.length, 2439);
      expect(report['total_raw_records_processed'], 2439);
      expect(report['valid_unique_records_staged'], 2439);
      expect(report['distinct_source_drug_codes'], 2439);
      expect(report['distinct_staged_drug_codes'], 2439);

      // Core Invariant 2: Zero duplicate source rows in genuine PMBI catalogue
      expect(report['duplicate_source_rows_count'], 0);
      expect(report['rejected_records_count'], 0);

      // Core Invariant 3: 118 previously suppressed records restored
      expect(report['previously_suppressed_records_restored'], 118);

      // Core Invariant 4: Dual verification integrity
      expect(report['identity_verification_breakdown']['source_confirmed'], 2439);
      expect(report['clinical_verification_breakdown']['unverified'], 2439);

      // Core Invariant 5: Exact mathematical reconciliation
      final reconciliation = report['reconciliation_statement'] as Map<String, dynamic>;
      expect(reconciliation['raw_source_rows'], 2439);
      expect(reconciliation['staged_skus'], 2439);
      expect(reconciliation['unaccounted_records'], 0);
      expect(reconciliation['status'], 'FULL_1_TO_1_RECONCILIATION_CONFIRMED');
    });
  });
}
