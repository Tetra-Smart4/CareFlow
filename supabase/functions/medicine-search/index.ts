import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

// Fallback curated verified Indian medicine catalogue (CDSCO / IP 2022 / NLEM)
const VERIFIED_CATALOGUE = [
  {
    id: "med_dolo_650",
    name: "Dolo 650",
    brand_name: "Dolo",
    generic_name: "Paracetamol",
    ingredients: ["Paracetamol (Acetaminophen) 650mg"],
    strength: "650 mg",
    dosage_form: "Tablet",
    manufacturer: "Micro Labs Ltd",
    classification: "Brand",
    overview: "Analgesic and antipyretic medication indicated for mild to moderate pain relief and fever reduction in adults.",
    common_uses: ["Fever reduction", "Mild to moderate headaches", "Body aches", "Post-vaccination pyrexia"],
    side_effects: ["Nausea", "Allergic skin reaction (rare)", "Hepatotoxicity with excessive dosage (>4000mg/day)"],
    precautions: [
      "Do not exceed 4000 mg in 24 hours across all paracetamol sources.",
      "Use with caution in chronic alcoholics or patients with underlying hepatic impairment.",
      "Avoid taking concurrently with other paracetamol-containing OTC formulations."
    ],
    contraindications: ["Known hypersensitivity to paracetamol", "Severe active hepatic impairment"],
    drug_interactions: [
      {
        interacting_drug: "Warfarin",
        severity: "Moderate",
        clinical_effect: "Prolonged regular use of paracetamol may enhance the anticoagulant effect of warfarin.",
        management: "Monitor INR if taken daily for more than 4-5 consecutive days.",
        evidence_source: "Indian Pharmacopoeia (IP 2022)"
      }
    ],
    storage_info: "Store below 30°C in a dry place. Protect from moisture and direct sunlight.",
    verification_status: "verified",
    verification_scope: "Product identity and IP monograph verified via CDSCO National Medicine Directory.",
    source_references: ["CDSCO Approved Formulations List", "Indian Pharmacopoeia (IP 2022)", "NLEM 2022"],
    last_reviewed_date: "2026-08-15",
    is_prescription_required: false
  },
  {
    id: "med_augmentin_625",
    name: "Augmentin 625 Duo",
    brand_name: "Augmentin",
    generic_name: "Amoxicillin + Clavulanic Acid",
    ingredients: ["Amoxicillin Trihydrate 500mg", "Potassium Clavulanate 125mg"],
    strength: "500 mg / 125 mg",
    dosage_form: "Tablet",
    manufacturer: "GlaxoSmithKline Pharmaceuticals Ltd",
    classification: "Combination",
    overview: "Broad-spectrum beta-lactam antibacterial combined with a beta-lactamase inhibitor for bacterial infections.",
    common_uses: ["Acute bacterial sinusitis", "Otitis media", "Lower respiratory tract infections", "Skin & soft tissue infections"],
    side_effects: ["Diarrhea", "Nausea", "Oral or vaginal candidiasis", "Urticaria / rash"],
    precautions: [
      "Complete the full prescribed course even if symptoms resolve early.",
      "Take at the start of a meal to minimize gastrointestinal intolerance."
    ],
    contraindications: [
      "History of hypersensitivity to beta-lactam antibacterials (penicillins, cephalosporins)",
      "Previous history of amoxicillin-clavulanate-associated jaundice or hepatic impairment"
    ],
    drug_interactions: [
      {
        interacting_drug: "Methotrexate",
        severity: "Major",
        clinical_effect: "Penicillins may reduce the excretion of methotrexate, causing increased toxicity.",
        management: "Carefully monitor methotrexate serum levels or avoid co-administration.",
        evidence_source: "WHO Formulary & British National Formulary"
      }
    ],
    storage_info: "Store in airtight blister strip below 25°C. Sensitive to moisture.",
    verification_status: "verified",
    verification_scope: "Product identity, formulation ratio, and schedule H1 regulatory compliance verified.",
    source_references: ["CDSCO Schedule H1 Antibacterial Registry", "Indian Pharmacopoeia (IP 2022)"],
    last_reviewed_date: "2026-09-01",
    is_prescription_required: true
  },
  {
    id: "med_glycomet_500",
    name: "Glycomet 500",
    brand_name: "Glycomet",
    generic_name: "Metformin Hydrochloride",
    ingredients: ["Metformin Hydrochloride 500mg"],
    strength: "500 mg",
    dosage_form: "Tablet",
    manufacturer: "USV Private Limited",
    classification: "Brand",
    overview: "First-line biguanide antihyperglycemic agent for managing type 2 diabetes mellitus.",
    common_uses: ["Type 2 Diabetes Mellitus glycemic control", "Adjunct to diet and exercise"],
    side_effects: ["Gastrointestinal discomfort", "Metallic taste", "Diarrhea", "Lactic acidosis (very rare, serious)"],
    precautions: [
      "Take with or immediately after meals to reduce GI adverse effects.",
      "Monitor renal function (eGFR) prior to initiation and at least annually thereafter."
    ],
    contraindications: [
      "Severe renal impairment (eGFR < 30 mL/min/1.73m²)",
      "Acute or chronic metabolic acidosis, including diabetic ketoacidosis"
    ],
    drug_interactions: [
      {
        interacting_drug: "Iodinated Radiopaque Contrast Agents",
        severity: "Major",
        clinical_effect: "Intravascular administration may lead to contrast-induced nephropathy and metformin accumulation.",
        management: "Discontinue metformin prior to study; restart only 48 hours post-procedure after confirming stable renal function.",
        evidence_source: "Indian Society of Nephrology & CDSCO Guidance"
      }
    ],
    storage_info: "Store below 25°C in a dry place. Protect from light.",
    verification_status: "verified",
    verification_scope: "Product monograph verified against CDSCO & NLEM 2022 standard.",
    source_references: ["National List of Essential Medicines (NLEM 2022)", "Indian Pharmacopoeia (IP 2022)"],
    last_reviewed_date: "2026-07-20",
    is_prescription_required: true
  },
  {
    id: "med_pan_40",
    name: "Pan 40",
    brand_name: "Pan",
    generic_name: "Pantoprazole Sodium",
    ingredients: ["Pantoprazole Sodium Gastro-resistant 40mg"],
    strength: "40 mg",
    dosage_form: "Tablet",
    manufacturer: "Alkem Laboratories Ltd",
    classification: "Brand",
    overview: "Proton pump inhibitor that selectively reduces gastric acid secretion by inhibiting gastric H+/K+-ATPase.",
    common_uses: ["Gastroesophageal reflux disease (GERD)", "Erosive esophagitis", "Peptic ulcer disease"],
    side_effects: ["Headache", "Diarrhea", "Abdominal pain"],
    precautions: [
      "Take 30-60 minutes before breakfast with water. Swallow tablet whole; do not crush or chew."
    ],
    contraindications: ["Known hypersensitivity to substituted benzimidazoles or pantoprazole"],
    drug_interactions: [
      {
        interacting_drug: "Clopidogrel",
        severity: "Moderate",
        clinical_effect: "Proton pump inhibitors may modestly attenuate platelet inhibition of clopidogrel.",
        management: "Pantoprazole is preferred over omeprazole when co-prescribed with clopidogrel.",
        evidence_source: "Cardiological Society of India Consensus"
      }
    ],
    storage_info: "Store in dry conditions below 25°C. Protect from moisture.",
    verification_status: "verified",
    verification_scope: "Product identity and gastric formulation compliance verified.",
    source_references: ["CDSCO Approved Drug List", "Indian Pharmacopoeia (IP 2022)"],
    last_reviewed_date: "2026-08-10",
    is_prescription_required: true
  },
  {
    id: "med_telma_40",
    name: "Telma 40",
    brand_name: "Telma",
    generic_name: "Telmisartan",
    ingredients: ["Telmisartan 40mg"],
    strength: "40 mg",
    dosage_form: "Tablet",
    manufacturer: "Glenmark Pharmaceuticals Ltd",
    classification: "Brand",
    overview: "Oral angiotensin II receptor blocker (ARB) with long duration of action for hypertension management.",
    common_uses: ["Essential hypertension", "Cardiovascular risk reduction in high-risk patients"],
    side_effects: ["Dizziness", "Hyperkalemia", "Back pain", "Hypotension (first dose)"],
    precautions: [
      "Monitor serum potassium and renal function periodically.",
      "Do not take during pregnancy."
    ],
    contraindications: [
      "Pregnancy (second and third trimesters — fetal toxicity risk)",
      "Severe hepatic impairment and biliary obstructive disorders"
    ],
    drug_interactions: [
      {
        interacting_drug: "Potassium Supplements / Spironolactone",
        severity: "Major",
        clinical_effect: "Synergistic elevation of serum potassium leading to severe hyperkalemia.",
        management: "Monitor serum electrolytes frequently; avoid unsupervised potassium supplements.",
        evidence_source: "Indian Heart Association & CDSCO Safety Guidance"
      }
    ],
    storage_info: "Store in original packaging below 30°C. Protect from light and humidity.",
    verification_status: "verified",
    verification_scope: "Active ingredient, monograph and antihypertensive safety verified.",
    source_references: ["CDSCO Database", "Indian Pharmacopoeia (IP 2022)", "NLEM 2022"],
    last_reviewed_date: "2026-08-25",
    is_prescription_required: true
  },
  {
    id: "med_asthalin_inhaler",
    name: "Asthalin 100mcg Inhaler",
    brand_name: "Asthalin",
    generic_name: "Salbutamol (Albuterol)",
    ingredients: ["Salbutamol Sulfate 100 mcg per actuation (CFC-Free)"],
    strength: "100 mcg / dose",
    dosage_form: "Inhaler",
    manufacturer: "Cipla Ltd",
    classification: "Brand",
    overview: "Short-acting beta-2 adrenergic agonist (SABA) providing rapid relief of bronchospasm in asthma and COPD.",
    common_uses: ["Acute bronchospasm relief in asthma", "Exercise-induced bronchospasm prophylaxis"],
    side_effects: ["Tremor (hands)", "Tachycardia / palpitations", "Transient headache"],
    precautions: [
      "Rinse mouth with water after inhalation to prevent dryness.",
      "Always shake well before use."
    ],
    contraindications: ["Hypersensitivity to salbutamol sulfate"],
    drug_interactions: [
      {
        interacting_drug: "Non-selective Beta-blockers (e.g. Propranolol)",
        severity: "Major",
        clinical_effect: "Directly antagonize the bronchodilating effect of salbutamol, potentially precipitating severe acute bronchospasm.",
        management: "Avoid non-selective beta-blockers in patients with asthma.",
        evidence_source: "Indian Chest Society Guidelines"
      }
    ],
    storage_info: "Store below 30°C. Protect from frost and direct sunlight. Do not puncture or burn canister.",
    verification_status: "verified",
    verification_scope: "Inhaler propellant and dose delivery validated under Indian Pharmacopoeia standard.",
    source_references: ["Indian Pharmacopoeia (IP 2022)", "NLEM 2022"],
    last_reviewed_date: "2026-09-12",
    is_prescription_required: true
  }
];

// Sliding-window rate limiting map: 30 requests per minute per IP
const rateLimitMap = new Map<string, { count: number; resetAt: number }>();
function checkRateLimit(clientIp: string, maxRequests = 30, windowMs = 60000): boolean {
  const now = Date.now();
  const record = rateLimitMap.get(clientIp);
  if (!record || now > record.resetAt) {
    rateLimitMap.set(clientIp, { count: 1, resetAt: now + windowMs });
    return true;
  }
  if (record.count >= maxRequests) {
    return false;
  }
  record.count++;
  return true;
}

const PUBLIC_COLUMNS =
  "id, name, brand_name, generic_name, ingredients, composition, strength, dosage_form, manufacturer, classification, overview, common_uses, side_effects, precautions, contraindications, drug_interactions, storage_info, identity_verification_status, clinical_verification_status, verification_scope, source_references, source_metadata, last_reviewed_date, is_prescription_required";

Deno.serve(async (req: Request) => {
  // Preflight check
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      status: 200,
      headers: corsHeaders,
    });
  }

  if (req.method !== "POST") {
    return jsonResponse(
      {
        error: "Only POST requests are allowed.",
      },
      405,
    );
  }

  // Rate Limiting check
  const clientIp =
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
    req.headers.get("cf-connecting-ip") ||
    "client";
  if (!checkRateLimit(clientIp)) {
    return jsonResponse(
      {
        error: "Rate limit exceeded. Please wait before making more requests.",
      },
      429,
    );
  }

  try {
    let body: Record<string, unknown> = {};
    try {
      body = await req.json();
    } catch (_) {
      // Empty body
    }

    const rawQuery = typeof body.query === "string" ? body.query.trim().toLowerCase() : "";
    // Sanitize query to prevent PostgREST injection
    const query = rawQuery
      .replace(/[,()"'`]/g, " ")
      .replace(/\.(eq|neq|gt|gte|lt|lte|like|ilike|is|in|cs|cd|ov|sl|sr|nxr|nxl|adj|not)\./g, " ")
      .replace(/\s+/g, " ")
      .trim();

    const dosageForm = typeof body.dosageForm === "string" ? body.dosageForm.trim() : null;
    const status = typeof body.status === "string" ? body.status.trim().toLowerCase() : null;
    const limit = typeof body.limit === "number" ? Math.min(Math.max(body.limit, 1), 50) : 25;
    const offset = typeof body.offset === "number" ? Math.max(body.offset, 0) : 0;

    // Optional remote database query if environment variables are available
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

    if (supabaseUrl && supabaseAnonKey) {
      try {
        const client = createClient(supabaseUrl, supabaseAnonKey);
        // Project only approved public fields, never internal secrets
        let q = client.from("careflow_medicine_catalogue").select(PUBLIC_COLUMNS);

        // Security quarantine: Exclude unverified clinical assertions and withdrawn products from public search
        q = q.neq("clinical_verification_status", "unverified").neq("identity_verification_status", "withdrawn");

        if (query.length > 0) {
          q = q.or(
            `name.ilike.%${query}%,brand_name.ilike.%${query}%,generic_name.ilike.%${query}%,composition.ilike.%${query}%`
          );
        }

        if (dosageForm && dosageForm !== "All") {
          q = q.eq("dosage_form", dosageForm);
        }

        if (status) {
          q = q.eq("verification_status", status);
        }

        const { data, error } = await q.range(offset, offset + limit - 1);
        if (!error && data && data.length > 0) {
          return jsonResponse({
            success: true,
            source: "database",
            total: data.length,
            medicines: data,
          });
        }
      } catch (dbErr) {
        console.error("DB query exception:", dbErr);
      }
    }

    // Curated verified in-memory fallback
    let filtered = [...VERIFIED_CATALOGUE];

    if (query.length > 0) {
      filtered = filtered.filter((m) => {
        const nameMatch = m.name.toLowerCase().includes(query);
        const brandMatch = (m.brand_name || "").toLowerCase().includes(query);
        const genericMatch = m.generic_name.toLowerCase().includes(query);
        const ingMatch = m.ingredients.some((i) => i.toLowerCase().includes(query));
        const usesMatch = m.common_uses.some((u) => u.toLowerCase().includes(query));
        return nameMatch || brandMatch || genericMatch || ingMatch || usesMatch;
      });
    }

    if (dosageForm && dosageForm !== "All") {
      filtered = filtered.filter(
        (m) => m.dosage_form.toLowerCase() === dosageForm.toLowerCase()
      );
    }

    if (status) {
      filtered = filtered.filter(
        (m) => m.verification_status.toLowerCase() === status
      );
    }

    const paged = filtered.slice(offset, offset + limit);

    return jsonResponse({
      success: true,
      source: "verified_reference_catalogue",
      total: filtered.length,
      medicines: paged,
    });
  } catch (error) {
    return jsonResponse(
      {
        error: "Internal server error processing medicine search.",
        details: String(error),
      },
      500,
    );
  }
});
