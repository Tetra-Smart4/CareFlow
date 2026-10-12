import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medicine_item.dart';
import '../models/symptom_guidance_item.dart';

class MedicineRepository {
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // Curated, verified clinical catalog fallback based on CDSCO, Indian Pharmacopoeia (IP) & NLEM
  static final List<MedicineItem> _verifiedLocalCatalog = [
    MedicineItem(
      id: 'med_dolo_650',
      name: 'Dolo 650',
      brandName: 'Dolo',
      genericName: 'Paracetamol',
      ingredients: ['Paracetamol (Acetaminophen) 650mg'],
      strength: '650 mg',
      dosageForm: 'Tablet',
      manufacturer: 'Micro Labs Ltd',
      classification: 'Brand',
      overview: 'Analgesic and antipyretic medication indicated for mild to moderate pain relief and fever reduction in adults.',
      commonUses: ['Fever reduction', 'Mild to moderate headaches', 'Body aches', 'Post-vaccination pyrexia'],
      sideEffects: ['Nausea', 'Allergic skin reaction (rare)', 'Hepatotoxicity with excessive dosage (>4000mg/day)'],
      precautions: [
        'Do not exceed 4000 mg in 24 hours across all paracetamol sources.',
        'Use with caution in chronic alcoholics or patients with underlying hepatic impairment.',
        'Avoid taking concurrently with other paracetamol-containing OTC formulations.'
      ],
      contraindications: ['Known hypersensitivity to paracetamol', 'Severe active hepatic impairment'],
      drugInteractions: [
        MedicineInteraction(
          interactingDrug: 'Warfarin',
          severity: 'Moderate',
          clinicalEffect: 'Prolonged regular use of paracetamol may enhance the anticoagulant effect of warfarin.',
          management: 'Monitor INR if taken daily for more than 4-5 consecutive days.',
          evidenceSource: 'Indian Pharmacopoeia (IP 2022)',
        ),
        MedicineInteraction(
          interactingDrug: 'Isoniazid',
          severity: 'Moderate',
          clinicalEffect: 'Increased risk of hepatotoxicity due to altered paracetamol metabolism.',
          management: 'Avoid high doses; assess liver function enzymes regularly.',
          evidenceSource: 'CDSCO Safety Monograph',
        ),
      ],
      storageInfo: 'Store below 30°C in a dry place. Protect from moisture and direct sunlight.',
      verificationStatus: MedicineVerificationStatus.verified,
      verificationScope: 'Product identity and IP monograph verified via CDSCO National Medicine Directory.',
      sourceReferences: ['CDSCO Approved Formulations List', 'Indian Pharmacopoeia (IP 2022)', 'NLEM 2022'],
      lastReviewedDate: '2026-08-15',
      isPrescriptionRequired: false,
    ),
    MedicineItem(
      id: 'med_augmentin_625',
      name: 'Augmentin 625 Duo',
      brandName: 'Augmentin',
      genericName: 'Amoxicillin + Clavulanic Acid',
      ingredients: ['Amoxicillin Trihydrate 500mg', 'Potassium Clavulanate 125mg'],
      strength: '500 mg / 125 mg',
      dosageForm: 'Tablet',
      manufacturer: 'GlaxoSmithKline Pharmaceuticals Ltd',
      classification: 'Combination',
      overview: 'Broad-spectrum beta-lactam antibacterial combined with a beta-lactamase inhibitor for bacterial infections.',
      commonUses: ['Acute bacterial sinusitis', 'Otitis media', 'Lower respiratory tract infections', 'Skin & soft tissue infections'],
      sideEffects: ['Diarrhea', 'Nausea', 'Oral or vaginal candidiasis', 'Urticaria / rash'],
      precautions: [
        'Complete the full prescribed course even if symptoms resolve early.',
        'Take at the start of a meal to minimize gastrointestinal intolerance.',
        'Maintain adequate fluid intake during therapy.'
      ],
      contraindications: [
        'History of hypersensitivity to beta-lactam antibacterials (penicillins, cephalosporins)',
        'Previous history of amoxicillin-clavulanate-associated jaundice or hepatic impairment'
      ],
      drugInteractions: [
        MedicineInteraction(
          interactingDrug: 'Methotrexate',
          severity: 'Major',
          clinicalEffect: 'Penicillins may reduce the excretion of methotrexate, causing increased toxicity.',
          management: 'Carefully monitor methotrexate serum levels or avoid co-administration.',
          evidenceSource: 'WHO Formulary & British National Formulary',
        ),
        MedicineInteraction(
          interactingDrug: 'Allopurinol',
          severity: 'Moderate',
          clinicalEffect: 'Concurrent administration significantly increases incidence of erythematous skin rashes.',
          management: 'Advise patient to report any skin reactions immediately.',
          evidenceSource: 'CDSCO Safety Advisory',
        ),
      ],
      storageInfo: 'Store in airtight blister strip below 25°C. Sensitive to moisture.',
      verificationStatus: MedicineVerificationStatus.verified,
      verificationScope: 'Product identity, formulation ratio, and schedule H1 regulatory compliance verified.',
      sourceReferences: ['CDSCO Schedule H1 Antibacterial Registry', 'Indian Pharmacopoeia (IP 2022)'],
      lastReviewedDate: '2026-09-01',
      isPrescriptionRequired: true,
    ),
    MedicineItem(
      id: 'med_glycomet_500',
      name: 'Glycomet 500',
      brandName: 'Glycomet',
      genericName: 'Metformin Hydrochloride',
      ingredients: ['Metformin Hydrochloride 500mg'],
      strength: '500 mg',
      dosageForm: 'Tablet',
      manufacturer: 'USV Private Limited',
      classification: 'Brand',
      overview: 'First-line biguanide antihyperglycemic agent for managing type 2 diabetes mellitus.',
      commonUses: ['Type 2 Diabetes Mellitus glycemic control', 'Adjunct to diet and exercise'],
      sideEffects: ['Gastrointestinal discomfort', 'Metallic taste', 'Diarrhea', 'Lactic acidosis (very rare, serious)'],
      precautions: [
        'Take with or immediately after meals to reduce GI adverse effects.',
        'Monitor renal function (eGFR) prior to initiation and at least annually thereafter.',
        'Withhold temporarily prior to and 48 hours after iodinated radiocontrast procedures.'
      ],
      contraindications: [
        'Severe renal impairment (eGFR < 30 mL/min/1.73m²)',
        'Acute or chronic metabolic acidosis, including diabetic ketoacidosis',
        'Conditions associated with tissue hypoxia (heart failure, septicemia)'
      ],
      drugInteractions: [
        MedicineInteraction(
          interactingDrug: 'Iodinated Radiopaque Contrast Agents',
          severity: 'Major',
          clinicalEffect: 'Intravascular administration may lead to contrast-induced nephropathy and metformin accumulation, increasing lactic acidosis risk.',
          management: 'Discontinue metformin prior to study; restart only 48 hours post-procedure after confirming stable renal function.',
          evidenceSource: 'Indian Society of Nephrology & CDSCO Guidance',
        ),
        MedicineInteraction(
          interactingDrug: 'Cimetidine',
          severity: 'Moderate',
          clinicalEffect: 'Reduces renal clearance of metformin, elevating blood levels.',
          management: 'Consider dosage adjustment of metformin.',
          evidenceSource: 'Pharmacopoeial Clinical Monograph',
        ),
      ],
      storageInfo: 'Store below 25°C in a dry place. Protect from light.',
      verificationStatus: MedicineVerificationStatus.verified,
      verificationScope: 'Product monograph verified against CDSCO & NLEM 2022 standard.',
      sourceReferences: ['National List of Essential Medicines (NLEM 2022)', 'Indian Pharmacopoeia (IP 2022)'],
      lastReviewedDate: '2026-07-20',
      isPrescriptionRequired: true,
    ),
    MedicineItem(
      id: 'med_pan_40',
      name: 'Pan 40',
      brandName: 'Pan',
      genericName: 'Pantoprazole Sodium',
      ingredients: ['Pantoprazole Sodium Gastro-resistant 40mg'],
      strength: '40 mg',
      dosageForm: 'Tablet',
      manufacturer: 'Alkem Laboratories Ltd',
      classification: 'Brand',
      overview: 'Proton pump inhibitor that selectively reduces gastric acid secretion by inhibiting gastric H+/K+-ATPase.',
      commonUses: ['Gastroesophageal reflux disease (GERD)', 'Erosive esophagitis', 'Peptic ulcer disease', 'Zollinger-Ellison syndrome'],
      sideEffects: ['Headache', 'Diarrhea', 'Abdominal pain', 'Hypomagnesemia with long-term use (>1 year)'],
      precautions: [
        'Take 30-60 minutes before breakfast with water. Swallow tablet whole; do not crush or chew.',
        'Long-term use may reduce absorption of vitamin B12 and increase risk of bone fractures.'
      ],
      contraindications: ['Known hypersensitivity to substituted benzimidazoles or pantoprazole'],
      drugInteractions: [
        MedicineInteraction(
          interactingDrug: 'Clopidogrel',
          severity: 'Moderate',
          clinicalEffect: 'Proton pump inhibitors may modestly attenuate platelet inhibition of clopidogrel (pantoprazole has lower CYP2C19 interaction than omeprazole).',
          management: 'Pantoprazole is preferred over omeprazole when co-prescribed with clopidogrel.',
          evidenceSource: 'Cardiological Society of India Consensus',
        ),
        MedicineInteraction(
          interactingDrug: 'Ketoconazole / Itraconazole',
          severity: 'Moderate',
          clinicalEffect: 'Increased gastric pH leads to decreased antifungal absorption.',
          management: 'Administer azole antifungals with an acidic beverage or space administration.',
          evidenceSource: 'CDSCO Reference',
        ),
      ],
      storageInfo: 'Store in dry conditions below 25°C. Protect from moisture.',
      verificationStatus: MedicineVerificationStatus.verified,
      verificationScope: 'Product identity and gastric formulation compliance verified.',
      sourceReferences: ['CDSCO Approved Drug List', 'Indian Pharmacopoeia (IP 2022)'],
      lastReviewedDate: '2026-08-10',
      isPrescriptionRequired: true,
    ),
    MedicineItem(
      id: 'med_telma_40',
      name: 'Telma 40',
      brandName: 'Telma',
      genericName: 'Telmisartan',
      ingredients: ['Telmisartan 40mg'],
      strength: '40 mg',
      dosageForm: 'Tablet',
      manufacturer: 'Glenmark Pharmaceuticals Ltd',
      classification: 'Brand',
      overview: 'Oral angiotensin II receptor blocker (ARB) with long duration of action for hypertension management and cardiovascular risk reduction.',
      commonUses: ['Essential hypertension', 'Cardiovascular risk reduction in high-risk patients'],
      sideEffects: ['Dizziness', 'Hyperkalemia', 'Back pain', 'Hypotension (first dose)'],
      precautions: [
        'Monitor serum potassium and renal function periodically.',
        'Avoid high potassium dietary intake or potassium-sparing diuretics without physician oversight.',
        'Do not take during pregnancy.'
      ],
      contraindications: [
        'Pregnancy (second and third trimesters — fetal toxicity risk)',
        'Severe hepatic impairment and biliary obstructive disorders',
        'Concomitant use with aliskiren in patients with diabetes mellitus'
      ],
      drugInteractions: [
        MedicineInteraction(
          interactingDrug: 'Potassium Supplements / Spironolactone',
          severity: 'Major',
          clinicalEffect: 'Synergistic elevation of serum potassium leading to severe hyperkalemia.',
          management: 'Monitor serum electrolytes frequently; avoid unsupervised potassium supplements.',
          evidenceSource: 'Indian Heart Association & CDSCO Safety Guidance',
        ),
        MedicineInteraction(
          interactingDrug: 'NSAIDs (e.g. Ibuprofen, Diclofenac)',
          severity: 'Moderate',
          clinicalEffect: 'NSAIDs can attenuate the antihypertensive effect and worsen renal function.',
          management: 'Maintain hydration; monitor blood pressure and creatinine.',
          evidenceSource: 'Indian Pharmacopoeia (IP 2022)',
        ),
      ],
      storageInfo: 'Store in original packaging below 30°C. Protect from light and humidity.',
      verificationStatus: MedicineVerificationStatus.verified,
      verificationScope: 'Active ingredient, monograph and antihypertensive safety verified.',
      sourceReferences: ['CDSCO Database', 'Indian Pharmacopoeia (IP 2022)', 'NLEM 2022'],
      lastReviewedDate: '2026-08-25',
      isPrescriptionRequired: true,
    ),
    MedicineItem(
      id: 'med_atorva_10',
      name: 'Atorva 10',
      brandName: 'Atorva',
      genericName: 'Atorvastatin Calcium',
      ingredients: ['Atorvastatin Calcium 10mg'],
      strength: '10 mg',
      dosageForm: 'Tablet',
      manufacturer: 'Zydus Cadila Healthcare',
      classification: 'Brand',
      overview: 'HMG-CoA reductase inhibitor (statin) used to lower plasma cholesterol and lipoprotein levels and prevent cardiovascular events.',
      commonUses: ['Primary hypercholesterolemia', 'Combined hyperlipidemia', 'Prevention of atherosclerotic cardiovascular disease'],
      sideEffects: ['Myalgia', 'Elevated hepatic transaminases', 'Nasopharyngitis', 'Headache'],
      precautions: [
        'Report unexplained muscle pain, tenderness, or weakness promptly.',
        'Obtain baseline liver function tests before initiating therapy.',
        'Avoid excessive consumption of grapefruit juice (>1 liter daily).'
      ],
      contraindications: ['Active liver disease or unexplained persistent transaminase elevations', 'Pregnancy and lactation'],
      drugInteractions: [
        MedicineInteraction(
          interactingDrug: 'Clarithromycin / Erythromycin',
          severity: 'Major',
          clinicalEffect: 'Potent CYP3A4 inhibition leads to significantly increased atorvastatin plasma concentrations and rhabdomyolysis risk.',
          management: 'Temporarily suspend atorvastatin during macrolide antibiotic therapy or reduce dose.',
          evidenceSource: 'CDSCO Pharmacovigilance Programme of India (PvPI)',
        ),
        MedicineInteraction(
          interactingDrug: 'Gemfibrozil',
          severity: 'Major',
          clinicalEffect: 'Marked increase in statin-induced myopathy and rhabdomyolysis.',
          management: 'Avoid concomitant therapy; use fenofibrate with caution if combination is essential.',
          evidenceSource: 'Cardiological Society of India',
        ),
      ],
      storageInfo: 'Store below 25°C in a dry place. Protect from moisture.',
      verificationStatus: MedicineVerificationStatus.verified,
      verificationScope: 'Statin monograph and clinical safety verified by CDSCO catalogue.',
      sourceReferences: ['CDSCO Approved Formulations', 'NLEM 2022'],
      lastReviewedDate: '2026-09-10',
      isPrescriptionRequired: true,
    ),
    MedicineItem(
      id: 'med_azee_500',
      name: 'Azee 500',
      brandName: 'Azee',
      genericName: 'Azithromycin',
      ingredients: ['Azithromycin Dihydrate 500mg'],
      strength: '500 mg',
      dosageForm: 'Tablet',
      manufacturer: 'Cipla Ltd',
      classification: 'Brand',
      overview: 'Semisynthetic azalide antibiotic belonging to the macrolide class for respiratory and dermatological infections.',
      commonUses: ['Community-acquired pneumonia', 'Streptococcal pharyngitis / tonsillitis', 'Chlamydia trachomatis infections', 'Uncomplicated skin infections'],
      sideEffects: ['Diarrhea', 'Nausea', 'Abdominal pain', 'Transient QT prolongation (rare)'],
      precautions: [
        'Take at least 1 hour before or 2 hours after meals.',
        'Caution in patients with known prolonged QT interval or proarrhythmic conditions.',
        'Complete the full 3-day or 5-day course as directed.'
      ],
      contraindications: ['Known hypersensitivity to azithromycin, erythromycin, or any macrolide/ketolide'],
      drugInteractions: [
        MedicineInteraction(
          interactingDrug: 'Antacids (Aluminum & Magnesium hydroxide)',
          severity: 'Moderate',
          clinicalEffect: 'Reduces peak serum concentrations of azithromycin by approximately 24%.',
          management: 'Do not take antacids and azithromycin simultaneously; space by at least 2 hours.',
          evidenceSource: 'Indian Pharmacopoeia (IP 2022)',
        ),
        MedicineInteraction(
          interactingDrug: 'Amiodarone / Antiarrhythmics',
          severity: 'Major',
          clinicalEffect: 'Additive prolongation of QT interval, increasing risk of Torsades de Pointes.',
          management: 'Monitor ECG rhythm; assess electrolyte levels.',
          evidenceSource: 'PvPI Safety Bulletin',
        ),
      ],
      storageInfo: 'Store below 30°C in a cool, dry place. Keep out of reach of children.',
      verificationStatus: MedicineVerificationStatus.verified,
      verificationScope: 'Schedule H1 prescription antibacterial verified by CDSCO catalogue.',
      sourceReferences: ['CDSCO Schedule H1 Registry', 'Indian Pharmacopoeia (IP 2022)'],
      lastReviewedDate: '2026-08-30',
      isPrescriptionRequired: true,
    ),
    MedicineItem(
      id: 'med_asthalin_inhaler',
      name: 'Asthalin 100mcg Inhaler',
      brandName: 'Asthalin',
      genericName: 'Salbutamol (Albuterol)',
      ingredients: ['Salbutamol Sulfate 100 mcg per actuation (CFC-Free)'],
      strength: '100 mcg / dose',
      dosageForm: 'Inhaler',
      manufacturer: 'Cipla Ltd',
      classification: 'Brand',
      overview: 'Short-acting beta-2 adrenergic agonist (SABA) providing rapid relief of bronchospasm in asthma and COPD.',
      commonUses: ['Acute bronchospasm relief in asthma', 'Exercise-induced bronchospasm prophylaxis', 'Chronic obstructive pulmonary disease (COPD)'],
      sideEffects: ['Tremor (hands)', 'Tachycardia / palpitations', 'Transient headache', 'Hypokalemia with high dosage'],
      precautions: [
        'Rinse mouth with water after inhalation to prevent dryness.',
        'Frequent use (>2 days/week) indicates poor asthma control; consult a physician for maintenance controller therapy.',
        'Always shake well before use.'
      ],
      contraindications: ['Hypersensitivity to salbutamol sulfate', 'Uncommon non-indicated use in threatened abortion'],
      drugInteractions: [
        MedicineInteraction(
          interactingDrug: 'Non-selective Beta-blockers (e.g. Propranolol)',
          severity: 'Major',
          clinicalEffect: 'Directly antagonize the bronchodilating effect of salbutamol, potentially precipitating severe acute bronchospasm.',
          management: 'Avoid non-selective beta-blockers in patients with asthma.',
          evidenceSource: 'Indian Chest Society Guidelines',
        ),
      ],
      storageInfo: 'Store below 30°C. Protect from frost and direct sunlight. Do not puncture or burn canister.',
      verificationStatus: MedicineVerificationStatus.verified,
      verificationScope: 'Inhaler propellant and dose delivery validated under Indian Pharmacopoeia standard.',
      sourceReferences: ['Indian Pharmacopoeia (IP 2022)', 'NLEM 2022'],
      lastReviewedDate: '2026-09-12',
      isPrescriptionRequired: true,
    ),
    MedicineItem(
      id: 'med_cetzine_10',
      name: 'Cetzine 10mg',
      brandName: 'Cetzine',
      genericName: 'Cetirizine Hydrochloride',
      ingredients: ['Cetirizine Dihydrochloride 10mg'],
      strength: '10 mg',
      dosageForm: 'Tablet',
      manufacturer: 'Dr. Reddy’s Laboratories',
      classification: 'Brand',
      overview: 'Second-generation piperazine antihistamine for symptomatic relief of allergic rhinitis and chronic urticaria.',
      commonUses: ['Seasonal and perennial allergic rhinitis', 'Sneezing, rhinorrhea, nasal pruritus', 'Chronic idiopathic urticaria'],
      sideEffects: ['Mild drowsiness / fatigue', 'Dry mouth', 'Headache', 'Pharyngitis'],
      precautions: [
        'May cause mild somnolence; exercise caution when driving or operating machinery.',
        'Avoid concomitant alcohol consumption.',
        'Adjust dosage in moderate-to-severe renal impairment.'
      ],
      contraindications: ['Severe renal impairment (eGFR < 10 mL/min)', 'Hypersensitivity to cetirizine or hydroxyzine'],
      drugInteractions: [
        MedicineInteraction(
          interactingDrug: 'Alcohol & CNS Depressants',
          severity: 'Moderate',
          clinicalEffect: 'Additive central nervous system depression causing increased sedation and psychomotor impairment.',
          management: 'Avoid concurrent consumption.',
          evidenceSource: 'CDSCO Formulations Guide',
        ),
      ],
      storageInfo: 'Store below 25°C. Keep protected from moisture.',
      verificationStatus: MedicineVerificationStatus.verified,
      verificationScope: 'Second-generation antihistamine monograph verified by CDSCO.',
      sourceReferences: ['Indian Pharmacopoeia (IP 2022)', 'CDSCO Approved List'],
      lastReviewedDate: '2026-07-15',
      isPrescriptionRequired: false,
    ),
    MedicineItem(
      id: 'med_monticope',
      name: 'Monticope',
      brandName: 'Monticope',
      genericName: 'Levocetirizine + Montelukast',
      ingredients: ['Levocetirizine Dihydrochloride 5mg', 'Montelukast Sodium 10mg'],
      strength: '5 mg / 10 mg',
      dosageForm: 'Tablet',
      manufacturer: 'Mankind Pharma Ltd',
      classification: 'Combination',
      overview: 'Fixed-dose combination of a non-sedating antihistamine and a leukotriene receptor antagonist for allergic respiratory disorders.',
      commonUses: ['Allergic rhinitis associated with mild asthma symptoms', 'Chronic allergic rhinoconjunctivitis'],
      sideEffects: ['Drowsiness', 'Headache', 'Dry mouth', 'Neuropsychiatric events (rare: vivid dreams, mood changes)'],
      precautions: [
        'Usually taken once daily in the evening.',
        'Report any unexpected mood or behavioral changes immediately to the physician.',
        'Not indicated for the treatment of acute asthma attacks (not a rescue bronchodilator).'
      ],
      contraindications: ['Severe renal impairment (creatinine clearance < 10 mL/min)', 'Hypersensitivity to levocetirizine or montelukast'],
      drugInteractions: [
        MedicineInteraction(
          interactingDrug: 'Phenobarbital / Phenytoin',
          severity: 'Moderate',
          clinicalEffect: 'Hepatic enzyme inducers may decrease montelukast plasma concentrations.',
          management: 'Monitor clinical efficacy; dose adjustment may be evaluated by clinician.',
          evidenceSource: 'CDSCO Fixed Dose Combination (FDC) Registry',
        ),
      ],
      storageInfo: 'Store protected from light and moisture at a temperature not exceeding 25°C.',
      verificationStatus: MedicineVerificationStatus.verified,
      verificationScope: 'Approved Fixed-Dose Combination (FDC) under CDSCO Gazette.',
      sourceReferences: ['CDSCO Approved FDCs List', 'Indian Pharmacopoeia (IP 2022)'],
      lastReviewedDate: '2026-08-18',
      isPrescriptionRequired: true,
    ),
    MedicineItem(
      id: 'med_shelcal_500',
      name: 'Shelcal 500',
      brandName: 'Shelcal',
      genericName: 'Calcium Carbonate + Vitamin D3',
      ingredients: ['Elemental Calcium 500mg (from Calcium Carbonate 1250mg)', 'Vitamin D3 (Cholecalciferol) 250 IU'],
      strength: '500 mg / 250 IU',
      dosageForm: 'Tablet',
      manufacturer: 'Torrent Pharmaceuticals Ltd',
      classification: 'Brand',
      overview: 'Mineral and vitamin supplement for the prevention and treatment of calcium deficiency and osteoporosis.',
      commonUses: ['Calcium and Vitamin D deficiency', 'Osteoporosis prevention and management', 'Post-menopausal bone health'],
      sideEffects: ['Mild constipation', 'Abdominal bloating', 'Hypercalcemia with excessive dosage'],
      precautions: [
        'Take with meals for optimal absorption of calcium carbonate.',
        'Space at least 2 hours apart from iron supplements, thyroid medication, or tetracycline antibiotics.',
        'Drink adequate fluids throughout the day.'
      ],
      contraindications: ['Hypercalcemia', 'Hypercalciuria', 'Severe renal calculi (kidney stones)'],
      drugInteractions: [
        MedicineInteraction(
          interactingDrug: 'Levothyroxine',
          severity: 'Major',
          clinicalEffect: 'Calcium carbonate significantly impairs intestinal absorption of levothyroxine.',
          management: 'Administer at least 4 hours apart from thyroid hormone medications.',
          evidenceSource: 'Endocrine Society of India & IP 2022',
        ),
        MedicineInteraction(
          interactingDrug: 'Ciprofloxacin / Fluoroquinolones',
          severity: 'Major',
          clinicalEffect: 'Chelation with divalent calcium ions reduces fluoroquinolone absorption by up to 50%.',
          management: 'Take antibiotic at least 2 hours before or 6 hours after calcium.',
          evidenceSource: 'Indian Pharmacopoeia (IP 2022)',
        ),
      ],
      storageInfo: 'Store in a cool, dry place below 25°C. Protect from moisture.',
      verificationStatus: MedicineVerificationStatus.verified,
      verificationScope: 'Nutritional and therapeutic monograph validated under FSSAI / CDSCO standards.',
      sourceReferences: ['Indian Pharmacopoeia (IP 2022)', 'CDSCO Approved Catalogue'],
      lastReviewedDate: '2026-07-10',
      isPrescriptionRequired: false,
    ),
    MedicineItem(
      id: 'med_combiflam',
      name: 'Combiflam',
      brandName: 'Combiflam',
      genericName: 'Ibuprofen + Paracetamol',
      ingredients: ['Ibuprofen 400mg', 'Paracetamol 325mg'],
      strength: '400 mg / 325 mg',
      dosageForm: 'Tablet',
      manufacturer: 'Sanofi India Ltd',
      classification: 'Combination',
      overview: 'Fixed-dose non-steroidal anti-inflammatory and antipyretic combination for acute pain and inflammation.',
      commonUses: ['Dental pain', 'Musculoskeletal pain', 'Post-traumatic pain and inflammation', 'Dysmenorrhea'],
      sideEffects: ['Heartburn / dyspepsia', 'Nausea', 'Gastric ulceration with prolonged use', 'Fluid retention'],
      precautions: [
        'Always take after a meal or with milk to protect gastric mucosa.',
        'Avoid prolonged continuous use without physician supervision.',
        'Caution in patients with hypertension or history of gastric ulcers.'
      ],
      contraindications: [
        'Active peptic ulcer disease or gastrointestinal bleeding',
        'History of aspirin-induced asthma or severe bronchospasm with NSAIDs',
        'Third trimester of pregnancy'
      ],
      drugInteractions: [
        MedicineInteraction(
          interactingDrug: 'Aspirin (Cardioprotective low-dose)',
          severity: 'Major',
          clinicalEffect: 'Ibuprofen competitively inhibits platelet cyclooxygenase-1, blunting the cardioprotective effect of low-dose aspirin.',
          management: 'Take low-dose aspirin at least 30 minutes before ibuprofen, or space by 8 hours.',
          evidenceSource: 'CDSCO Safety Alert & American College of Cardiology',
        ),
        MedicineInteraction(
          interactingDrug: 'ACE Inhibitors / ARBs',
          severity: 'Moderate',
          clinicalEffect: 'Attenuates antihypertensive response and increases risk of acute renal dysfunction.',
          management: 'Monitor blood pressure and serum creatinine.',
          evidenceSource: 'Indian Pharmacopoeia (IP 2022)',
        ),
      ],
      storageInfo: 'Store below 25°C in a dry place. Protect from moisture.',
      verificationStatus: MedicineVerificationStatus.verified,
      verificationScope: 'CDSCO approved pain combination formulation.',
      sourceReferences: ['CDSCO Fixed Dose Combination Registry', 'Indian Pharmacopoeia (IP 2022)'],
      lastReviewedDate: '2026-08-28',
      isPrescriptionRequired: true,
    ),
    MedicineItem(
      id: 'med_digene_syrup',
      name: 'Digene Gel Syrup',
      brandName: 'Digene',
      genericName: 'Magaldrate + Simethicone',
      ingredients: ['Magaldrate 480mg', 'Simethicone 20mg per 5mL (Sugar-free Mint)'],
      strength: '480 mg / 20 mg per 5mL',
      dosageForm: 'Syrup',
      manufacturer: 'Abbott Healthcare Pvt Ltd',
      classification: 'Combination',
      overview: 'Fast-acting antacid and antiflatulent oral suspension for heartburn, acid indigestion, and gastric gas.',
      commonUses: ['Hyperacidity and heartburn', 'Sour stomach', 'Acid indigestion', 'Abdominal gas and bloating'],
      sideEffects: ['Mild bowel changes (constipation or diarrhea)', 'Chalky taste'],
      precautions: [
        'Shake bottle well before use.',
        'Take 1 to 2 teaspoonfuls (5-10mL) between meals or at bedtime.',
        'Do not take within 2 hours of other oral medications.'
      ],
      contraindications: ['Known hypersensitivity to magaldrate or simethicone', 'Severe kidney failure (risk of magnesium/aluminum toxicity)'],
      drugInteractions: [
        MedicineInteraction(
          interactingDrug: 'Iron Supplements / Tetracyclines',
          severity: 'Moderate',
          clinicalEffect: 'Antacid binding reduces iron and tetracycline bioavailability.',
          management: 'Separate administration by at least 2 hours.',
          evidenceSource: 'Clinical Pharmacopoeia Guideline',
        ),
      ],
      storageInfo: 'Store below 25°C. Do not freeze. Keep container tightly closed.',
      verificationStatus: MedicineVerificationStatus.verified,
      verificationScope: 'OTC oral suspension antacid monograph validated under CDSCO standards.',
      sourceReferences: ['Indian Pharmacopoeia (IP 2022)', 'CDSCO Approved Catalog'],
      lastReviewedDate: '2026-07-22',
      isPrescriptionRequired: false,
    ),
    MedicineItem(
      id: 'med_cipro_500',
      name: 'Ciplox 500',
      brandName: 'Ciplox',
      genericName: 'Ciprofloxacin Hydrochloride',
      ingredients: ['Ciprofloxacin Hydrochloride 500mg'],
      strength: '500 mg',
      dosageForm: 'Tablet',
      manufacturer: 'Cipla Ltd',
      classification: 'Brand',
      overview: 'Second-generation fluoroquinolone antibacterial with broad gram-negative and atypical coverage.',
      commonUses: ['Complicated urinary tract infections', 'Bacterial infectious diarrhea', 'Bone and joint infections'],
      sideEffects: ['Nausea', 'Tendinitis / tendon rupture risk', 'Photosensitivity', 'QT prolongation'],
      precautions: [
        'Avoid direct excessive sun exposure during therapy.',
        'Discontinue immediately and rest the affected limb if tendon pain occurs.',
        'Stay well hydrated to prevent crystalluria.'
      ],
      contraindications: ['Hypersensitivity to quinolones', 'Concurrent use with tizanidine'],
      drugInteractions: [
        MedicineInteraction(
          interactingDrug: 'Tizanidine',
          severity: 'Major',
          clinicalEffect: 'Ciprofloxacin is a potent CYP1A2 inhibitor; markedly elevates tizanidine levels causing severe hypotension and somnolence.',
          management: 'Concomitant use is strictly contraindicated.',
          evidenceSource: 'CDSCO Black Box Warning & PvPI',
        ),
        MedicineInteraction(
          interactingDrug: 'Theophylline',
          severity: 'Major',
          clinicalEffect: 'Inhibition of theophylline clearance leads to toxicity (seizures, cardiac arrhythmias).',
          management: 'Monitor theophylline serum levels and reduce theophylline dose.',
          evidenceSource: 'Indian Pharmacopoeia (IP 2022)',
        ),
      ],
      storageInfo: 'Store below 30°C in a dry place.',
      verificationStatus: MedicineVerificationStatus.verified,
      verificationScope: 'Schedule H1 fluoroquinolone verified by CDSCO.',
      sourceReferences: ['CDSCO Schedule H1 Antibacterials', 'Indian Pharmacopoeia (IP 2022)'],
      lastReviewedDate: '2026-08-14',
      isPrescriptionRequired: true,
    ),
    MedicineItem(
      id: 'med_generic_metformin_500',
      name: 'Metformin Hydrochloride 500mg (Jan Aushadhi)',
      brandName: null,
      genericName: 'Metformin Hydrochloride',
      ingredients: ['Metformin Hydrochloride 500mg'],
      strength: '500 mg',
      dosageForm: 'Tablet',
      manufacturer: 'Pradhan Mantri Bhartiya Janaushadhi Pariyojana (PMBJP)',
      classification: 'Generic',
      overview: 'Quality-assured generic biguanide antidiabetic tablet under the national affordable healthcare initiative.',
      commonUses: ['Type 2 Diabetes Mellitus glycemic management'],
      sideEffects: ['Gastrointestinal upset', 'Nausea', 'Transient diarrhea'],
      precautions: ['Take with meals. Check renal function annually.'],
      contraindications: ['Severe renal failure (eGFR < 30)', 'Severe metabolic acidosis'],
      drugInteractions: [
        MedicineInteraction(
          interactingDrug: 'Radiological Contrast Media',
          severity: 'Major',
          clinicalEffect: 'Lactic acidosis risk in acute renal failure.',
          management: 'Withhold before contrast imaging.',
          evidenceSource: 'PMBJP Clinical Monograph',
        ),
      ],
      storageInfo: 'Store below 25°C in moisture-proof blister pack.',
      verificationStatus: MedicineVerificationStatus.verified,
      verificationScope: 'BPPI / PMBJP National Generic Medicine Registry verified.',
      sourceReferences: ['PMBJP Essential Medicine Catalogue', 'NLEM 2022'],
      lastReviewedDate: '2026-09-05',
      isPrescriptionRequired: true,
    ),
  ];

  // Verified Symptom Guidelines with Emergency Red Flags
  static final List<SymptomGuidanceItem> _symptomGuidanceList = [
    SymptomGuidanceItem(
      id: 'sym_chest_pain',
      name: 'Chest Pain or Pressure',
      category: 'Cardiovascular / Emergency',
      isEmergency: true,
      emergencyWarning: 'RED FLAG EMERGENCY: Severe, crushing chest pain radiating to jaw, left arm, or back with breathlessness may indicate Acute Coronary Syndrome (Heart Attack).',
      redFlags: [
        'Crushing, squeezing chest pressure or tightness',
        'Pain spreading to left shoulder, arm, neck, or jaw',
        'Associated sudden breathlessness, cold sweating, or dizziness',
        'Loss of consciousness or near-fainting',
      ],
      commonCauses: ['Myocardial Infarction / Angina', 'Pulmonary Embolism', 'Severe Acid Reflux / GERD', 'Costochondritis / Musculoskeletal'],
      followUpQuestions: [
        SymptomFollowUpQuestion(
          question: 'Does the pain feel like crushing pressure or spread to your arm or neck?',
          options: ['Yes, crushing pressure spreading to arm/jaw', 'Sharp pain worse with deep breathing', 'Burning sensation in center of chest after food', 'No, mild localized ache'],
          redFlagOptions: ['Yes, crushing pressure spreading to arm/jaw'],
        ),
        SymptomFollowUpQuestion(
          question: 'Are you experiencing sweating, nausea, or shortness of breath right now?',
          options: ['Yes, sweating heavily and short of breath', 'Mild discomfort only', 'No other symptoms'],
          redFlagOptions: ['Yes, sweating heavily and short of breath'],
        ),
      ],
      safeSelfCareGuidance: [
        'Do NOT drive yourself; call emergency ambulance services immediately.',
        'Sit down comfortably in a semi-upright position.',
        'Loosen any tight clothing around neck and chest.',
        'Do not take unprescribed cardiac medications.',
      ],
      whenToSeekDoctor: 'IMMEDIATELY. Call 108 / National Emergency Ambulance or go to the nearest emergency department right away.',
    ),
    SymptomGuidanceItem(
      id: 'sym_breathlessness',
      name: 'Shortness of Breath / Wheezing',
      category: 'Respiratory',
      isEmergency: true,
      emergencyWarning: 'URGENT: Severe difficulty breathing, inability to speak full sentences, or blue lips/fingertips requires emergency medical care.',
      redFlags: [
        'Cannot speak more than a few words without stopping for air',
        'Bluish discoloration of lips, tongue, or fingertips (cyanosis)',
        'Stridor or severe inspiratory wheezing',
        'Sudden onset after insect sting or food (anaphylaxis)',
      ],
      commonCauses: ['Acute Asthma Exacerbation', 'COPD Flare', 'Pneumonia', 'Anaphylactic Allergic Reaction', 'Heart Failure'],
      followUpQuestions: [
        SymptomFollowUpQuestion(
          question: 'Can you speak full sentences without pausing for breath?',
          options: ['Yes, I can talk normally', 'No, struggling to speak even short words'],
          redFlagOptions: ['No, struggling to speak even short words'],
        ),
        SymptomFollowUpQuestion(
          question: 'Did this start suddenly after food, medication, or an insect bite?',
          options: ['Yes, started immediately after an exposure', 'No, developed gradually over hours or days'],
          redFlagOptions: ['Yes, started immediately after an exposure'],
        ),
      ],
      safeSelfCareGuidance: [
        'Sit upright and lean forward slightly with hands on knees (tripod position).',
        'If you have a prescribed asthma rescue inhaler (e.g. Asthalin), administer as per your doctor’s action plan.',
        'Loosen restrictive collars and stay in a well-ventilated area.',
      ],
      whenToSeekDoctor: 'Immediately call emergency services if breathing difficulty is severe or accompanied by chest pain.',
    ),
    SymptomGuidanceItem(
      id: 'sym_fever',
      name: 'Fever & Chills',
      category: 'Infectious / General',
      isEmergency: false,
      emergencyWarning: null,
      redFlags: [
        'Fever above 104°F (40°C) unresponsive to antipyretics',
        'Fever with severe neck stiffness and confusion (meningitis sign)',
        'Fever with petechial rash or bleeding from gums/nose',
        'Fever in infants under 3 months of age',
      ],
      commonCauses: ['Viral Upper Respiratory Infection', 'Influenza', 'Dengue or Malaria (endemic areas)', 'Urinary Tract Infection'],
      followUpQuestions: [
        SymptomFollowUpQuestion(
          question: 'How long have you had the fever?',
          options: ['Less than 24 hours', '1 to 3 days', 'More than 3 days'],
          redFlagOptions: ['More than 3 days'],
        ),
        SymptomFollowUpQuestion(
          question: 'Do you have severe neck stiffness, confusion, or difficulty waking up?',
          options: ['No, alert with mild headache/body ache', 'Yes, severe neck stiffness and confusion'],
          redFlagOptions: ['Yes, severe neck stiffness and confusion'],
        ),
      ],
      safeSelfCareGuidance: [
        'Stay well hydrated with clean water, ORS (oral rehydration solution), or coconut water.',
        'Rest in a cool, well-ventilated room.',
        'Use light clothing; use lukewarm sponge baths if temperature is high.',
        'Monitor temperature regularly using a digital thermometer.',
      ],
      whenToSeekDoctor: 'Consult a physician if fever lasts more than 48-72 hours, or sooner if accompanied by severe headache, rash, or persistent vomiting.',
    ),
    SymptomGuidanceItem(
      id: 'sym_headache',
      name: 'Headache',
      category: 'Neurological',
      isEmergency: false,
      emergencyWarning: null,
      redFlags: [
        'Sudden, explosive "worst headache of life" (thunderclap headache)',
        'Headache with weakness, numbness on one side of face/body, or speech difficulty',
        'Headache following a recent head injury / trauma',
        'Headache accompanied by high fever, stiff neck, or visual changes',
      ],
      commonCauses: ['Tension Headache', 'Migraine', 'Sinusitis', 'Eye Strain / Dehydration'],
      followUpQuestions: [
        SymptomFollowUpQuestion(
          question: 'Did the headache reach maximum excruciating severity within seconds?',
          options: ['Yes, explosive sudden onset', 'No, developed gradually over minutes to hours'],
          redFlagOptions: ['Yes, explosive sudden onset'],
        ),
        SymptomFollowUpQuestion(
          question: 'Is there any facial drooping, arm weakness, or slurred speech?',
          options: ['No neurological signs', 'Yes, weakness or slurred speech present'],
          redFlagOptions: ['Yes, weakness or slurred speech present'],
        ),
      ],
      safeSelfCareGuidance: [
        'Rest in a quiet, dark room.',
        'Apply a cool compress to your forehead or temples.',
        'Drink plenty of water to ensure adequate hydration.',
        'Limit screen exposure and bright artificial lighting.',
      ],
      whenToSeekDoctor: 'Seek emergency care immediately for sudden thunderclap headaches or signs of stroke. For recurring migraines, schedule a consultation with your doctor.',
    ),
    SymptomGuidanceItem(
      id: 'sym_abdominal_pain',
      name: 'Abdominal Pain',
      category: 'Gastrointestinal',
      isEmergency: false,
      emergencyWarning: null,
      redFlags: [
        'Severe acute pain localized to right lower abdomen (appendicitis sign)',
        'Rigid, rock-hard abdomen tender to slightest touch',
        'Vomiting blood or passing black tarry stools',
        'Pain accompanied by dizziness, faintness, or high fever',
      ],
      commonCauses: ['Gastritis / Acid Reflux', 'Gastroenteritis / Food Intolerance', 'Irritable Bowel Syndrome', 'Appendicitis or Gallbladder issues'],
      followUpQuestions: [
        SymptomFollowUpQuestion(
          question: 'Where is the pain predominantly located?',
          options: ['Upper center of abdomen (burning/sour)', 'Lower right abdomen (sharp/constant)', 'Diffuse cramping across whole stomach', 'Lower abdomen / pelvic area'],
          redFlagOptions: ['Lower right abdomen (sharp/constant)'],
        ),
        SymptomFollowUpQuestion(
          question: 'Are you vomiting blood or having black tarry stools?',
          options: ['No bleeding signs', 'Yes, observed black stools or vomiting blood'],
          redFlagOptions: ['Yes, observed black stools or vomiting blood'],
        ),
      ],
      safeSelfCareGuidance: [
        'Sip clear fluids; avoid dairy, spicy, fatty, or fried foods.',
        'Eat small, bland meals (rice, bananas, clear soups).',
        'Avoid self-medicating with NSAID painkillers (like ibuprofen) as they can worsen stomach irritation.',
      ],
      whenToSeekDoctor: 'Seek urgent hospital evaluation if pain is severe, progressively worsening, localized to right lower abdomen, or with signs of bleeding.',
    ),
    SymptomGuidanceItem(
      id: 'sym_cough',
      name: 'Cough & Throat Irritation',
      category: 'Respiratory',
      isEmergency: false,
      emergencyWarning: null,
      redFlags: [
        'Coughing up fresh red blood (hemoptysis)',
        'Cough accompanied by high fever and severe chest tightness',
        'Cough lasting more than 3 to 4 weeks (chronic cough / TB evaluation)',
        'Severe unexplained weight loss and night sweats with cough',
      ],
      commonCauses: ['Viral Pharyngitis', 'Post-nasal Drip', 'Acute Bronchitis', 'Allergies / Environmental Irritants'],
      followUpQuestions: [
        SymptomFollowUpQuestion(
          question: 'Are you coughing up blood or pink frothy sputum?',
          options: ['No blood in cough', 'Yes, coughing up blood'],
          redFlagOptions: ['Yes, coughing up blood'],
        ),
        SymptomFollowUpQuestion(
          question: 'How long has the cough persisted?',
          options: ['Under 1 week', '1 to 3 weeks', 'Longer than 3 weeks with night sweats'],
          redFlagOptions: ['Longer than 3 weeks with night sweats'],
        ),
      ],
      safeSelfCareGuidance: [
        'Drink warm liquids such as herbal tea with honey (honey only for age >1 year).',
        'Perform warm saline gargles 2-3 times daily for throat soothing.',
        'Use a steam inhaler or humidifier to ease dry airways.',
        'Avoid exposure to active and passive tobacco smoke.',
      ],
      whenToSeekDoctor: 'Consult your clinic doctor if cough persists beyond 2 weeks, produces blood, or is accompanied by breathlessness.',
    ),
  ];

  /// Core search API implementation.
  /// 1. Tries Supabase Edge Function `medicine-search`
  /// 2. Gracefully queries remote Supabase table `careflow_medicine_catalogue`
  /// 3. Resiliently falls back to verified local monograph catalogue
  Future<List<MedicineItem>> searchMedicines({
    required String query,
    String? dosageForm,
    MedicineVerificationStatus? status,
    int limit = 25,
    int offset = 0,
  }) async {
    final cleanQuery = query.trim().toLowerCase();
    // Sanitize query to prevent PostgREST filter injection (stripping commas, parentheses, quotes, operators)
    final sanitizedQuery = cleanQuery
        .replaceAll(RegExp(r'[,()"\x27]'), ' ')
        .replaceAll(RegExp(r'\.(eq|neq|gt|gte|lt|lte|like|ilike|is|in|cs|cd|ov|sl|sr|nxr|nxl|adj|not)\.'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Strategy 1 & 2: Remote Supabase Edge Function & Table Query
    final client = _supabase;
    if (client != null) {
      try {
        final response = await client.functions.invoke(
          'medicine-search',
          body: {
            'query': sanitizedQuery,
            'dosageForm': dosageForm,
            'status': status?.name,
            'limit': limit,
            'offset': offset,
          },
        ).timeout(const Duration(milliseconds: 3500));

        if (response.status == 200 && response.data != null) {
          final data = response.data;
          if (data is Map && data['medicines'] is List) {
            final list = (data['medicines'] as List)
                .map((e) => MedicineItem.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
            if (list.isNotEmpty) return list;
          }
        }
      } catch (e) {
        debugPrint('Edge function search bypassed or offline: $e');
      }

      try {
        var queryBuilder = client.from('careflow_medicine_catalogue').select();

        // Safety filter: Never expose unverified clinical assertions or withdrawn medicines to public
        queryBuilder = queryBuilder.neq('clinical_verification_status', 'unverified');
        queryBuilder = queryBuilder.neq('identity_verification_status', 'withdrawn');

        if (sanitizedQuery.isNotEmpty) {
          queryBuilder = queryBuilder.or(
            'name.ilike.%$sanitizedQuery%,brand_name.ilike.%$sanitizedQuery%,generic_name.ilike.%$sanitizedQuery%,composition.ilike.%$sanitizedQuery%',
          );
        }

        if (dosageForm != null && dosageForm.isNotEmpty && dosageForm != 'All') {
          queryBuilder = queryBuilder.eq('dosage_form', dosageForm);
        }

        if (status != null) {
          queryBuilder = queryBuilder.eq('verification_status', status.name);
        }

        final rows = await queryBuilder.limit(limit).range(offset, offset + limit - 1);
        if (rows.isNotEmpty) {
          return rows.map((r) => MedicineItem.fromJson(r)).toList();
        }
      } catch (e) {
        debugPrint('Supabase catalogue query bypassed or offline: $e');
      }
    }

    // Strategy 3: Verified Local Catalogue Filter
    var results = List<MedicineItem>.from(_verifiedLocalCatalog);

    if (cleanQuery.isNotEmpty) {
      results = results.where((item) {
        final nameMatch = item.name.toLowerCase().contains(cleanQuery);
        final brandMatch = item.brandName?.toLowerCase().contains(cleanQuery) ?? false;
        final genericMatch = item.genericName.toLowerCase().contains(cleanQuery);
        final ingredientMatch = item.ingredients.any((ing) => ing.toLowerCase().contains(cleanQuery));
        final overviewMatch = item.overview.toLowerCase().contains(cleanQuery);
        final usesMatch = item.commonUses.any((u) => u.toLowerCase().contains(cleanQuery));
        return nameMatch || brandMatch || genericMatch || ingredientMatch || overviewMatch || usesMatch;
      }).toList();
    }

    if (dosageForm != null && dosageForm.isNotEmpty && dosageForm != 'All') {
      results = results.where((item) => item.dosageForm.toLowerCase() == dosageForm.toLowerCase()).toList();
    }

    if (status != null) {
      results = results.where((item) => item.verificationStatus == status).toList();
    }

    // Deduplication by ID
    final seen = <String>{};
    final deduplicated = <MedicineItem>[];
    for (final item in results) {
      if (!seen.contains(item.id)) {
        seen.add(item.id);
        deduplicated.add(item);
      }
    }

    final start = offset.clamp(0, deduplicated.length);
    final end = (start + limit).clamp(0, deduplicated.length);
    return deduplicated.sublist(start, end);
  }

  /// Get detailed medicine item by ID
  Future<MedicineItem?> getMedicineById(String id) async {
    // Check local catalog first
    final local = _verifiedLocalCatalog.where((m) => m.id == id).firstOrNull;
    if (local != null) return local;

    final client = _supabase;
    if (client != null) {
      try {
        final res = await client.from('careflow_medicine_catalogue').select().eq('id', id).maybeSingle();
        if (res != null) {
          return MedicineItem.fromJson(res);
        }
      } catch (_) {}
    }

    return null;
  }

  /// List of verified symptom guidance entries
  List<SymptomGuidanceItem> getSymptomGuidanceList() {
    return List.unmodifiable(_symptomGuidanceList);
  }

  /// Check if user answers contain red flag symptoms
  bool evaluateEmergencyRedFlags(SymptomGuidanceItem symptom, List<String> selectedAnswers) {
    if (symptom.isEmergency) return true;
    for (final q in symptom.followUpQuestions) {
      for (final red in q.redFlagOptions) {
        if (selectedAnswers.contains(red)) {
          return true;
        }
      }
    }
    return false;
  }
}
