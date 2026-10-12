enum IdentityVerificationStatus {
  unverified,
  sourceConfirmed,
  regulatoryRegistered,
  withdrawn;

  String get displayName {
    switch (this) {
      case IdentityVerificationStatus.unverified:
        return 'Identity Unverified';
      case IdentityVerificationStatus.sourceConfirmed:
        return 'Source Confirmed';
      case IdentityVerificationStatus.regulatoryRegistered:
        return 'Regulatory Registered';
      case IdentityVerificationStatus.withdrawn:
        return 'Withdrawn / Recalled';
    }
  }

  static IdentityVerificationStatus fromString(String? val) {
    if (val == null) return IdentityVerificationStatus.unverified;
    final normalized = val.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    switch (normalized) {
      case 'source_confirmed':
      case 'sourceconfirmed':
      case 'confirmed':
        return IdentityVerificationStatus.sourceConfirmed;
      case 'regulatory_registered':
      case 'regulatoryregistered':
      case 'registered':
      case 'verified':
        return IdentityVerificationStatus.regulatoryRegistered;
      case 'withdrawn':
      case 'recalled':
        return IdentityVerificationStatus.withdrawn;
      default:
        return IdentityVerificationStatus.unverified;
    }
  }
}

enum ClinicalVerificationStatus {
  unverified,
  monographLinked,
  clinicallyReviewed,
  flaggedForReview;

  String get displayName {
    switch (this) {
      case ClinicalVerificationStatus.unverified:
        return 'Clinical Info Unverified';
      case ClinicalVerificationStatus.monographLinked:
        return 'Monograph Linked';
      case ClinicalVerificationStatus.clinicallyReviewed:
        return 'Clinically Reviewed';
      case ClinicalVerificationStatus.flaggedForReview:
        return 'Flagged for Review';
    }
  }

  static ClinicalVerificationStatus fromString(String? val) {
    if (val == null) return ClinicalVerificationStatus.unverified;
    final normalized = val.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    switch (normalized) {
      case 'monograph_linked':
      case 'monographlinked':
      case 'linked':
      case 'partial':
      case 'partially_verified':
        return ClinicalVerificationStatus.monographLinked;
      case 'clinically_reviewed':
      case 'clinicallyreviewed':
      case 'reviewed':
      case 'verified':
        return ClinicalVerificationStatus.clinicallyReviewed;
      case 'flagged_for_review':
      case 'flagged':
      case 'under_review':
        return ClinicalVerificationStatus.flaggedForReview;
      default:
        return ClinicalVerificationStatus.unverified;
    }
  }
}

enum MedicineVerificationStatus {
  verified,
  partiallyVerified,
  notVerified,
  underReview,
  withdrawn;

  String get displayName {
    switch (this) {
      case MedicineVerificationStatus.verified:
        return 'Verified';
      case MedicineVerificationStatus.partiallyVerified:
        return 'Partially Verified';
      case MedicineVerificationStatus.notVerified:
        return 'Not Verified';
      case MedicineVerificationStatus.underReview:
        return 'Under Review';
      case MedicineVerificationStatus.withdrawn:
        return 'Withdrawn / Recalled';
    }
  }

  static MedicineVerificationStatus fromString(String? val) {
    if (val == null) return MedicineVerificationStatus.notVerified;
    final normalized = val.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    switch (normalized) {
      case 'verified':
        return MedicineVerificationStatus.verified;
      case 'partially_verified':
      case 'partial':
        return MedicineVerificationStatus.partiallyVerified;
      case 'under_review':
        return MedicineVerificationStatus.underReview;
      case 'withdrawn':
      case 'recalled':
        return MedicineVerificationStatus.withdrawn;
      default:
        return MedicineVerificationStatus.notVerified;
    }
  }
}

class MedicineInteraction {
  final String interactingDrug;
  final String severity; // Major, Moderate, Minor
  final String clinicalEffect;
  final String management;
  final String evidenceSource;

  const MedicineInteraction({
    required this.interactingDrug,
    required this.severity,
    required this.clinicalEffect,
    required this.management,
    required this.evidenceSource,
  });

  factory MedicineInteraction.fromJson(Map<String, dynamic> json) {
    return MedicineInteraction(
      interactingDrug: (json['interacting_drug'] ?? json['interactingDrug'] ?? '').toString(),
      severity: (json['severity'] ?? 'Moderate').toString(),
      clinicalEffect: (json['clinical_effect'] ?? json['clinicalEffect'] ?? '').toString(),
      management: (json['management'] ?? '').toString(),
      evidenceSource: (json['evidence_source'] ?? json['evidenceSource'] ?? 'Clinical Reference').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interacting_drug': interactingDrug,
      'severity': severity,
      'clinical_effect': clinicalEffect,
      'management': management,
      'evidence_source': evidenceSource,
    };
  }
}

class MedicineItem {
  final String id;
  final String name;
  final String? brandName;
  final String genericName;
  final List<String> ingredients;
  final String strength;
  final String dosageForm;
  final String dosageCategory;
  final String route;
  final String? manufacturer;
  final String classification; // Brand, Generic, Combination
  final String overview;
  final List<String> commonUses;
  final List<String> sideEffects;
  final List<String> precautions;
  final List<String> contraindications;
  final List<MedicineInteraction> drugInteractions;
  final String? storageInfo;
  final IdentityVerificationStatus identityVerificationStatus;
  final ClinicalVerificationStatus clinicalVerificationStatus;
  final MedicineVerificationStatus? _explicitVerificationStatus;
  final String verificationScope;
  final List<String> sourceReferences;
  final Map<String, dynamic> sourceMetadata;
  final double? mrpInr;
  final String? lastReviewedDate;
  final bool isPrescriptionRequired;

  MedicineVerificationStatus get verificationStatus {
    if (_explicitVerificationStatus != null) {
      return _explicitVerificationStatus;
    }
    if (identityVerificationStatus == IdentityVerificationStatus.withdrawn) {
      return MedicineVerificationStatus.withdrawn;
    }
    if (clinicalVerificationStatus == ClinicalVerificationStatus.clinicallyReviewed &&
        (identityVerificationStatus == IdentityVerificationStatus.regulatoryRegistered ||
         identityVerificationStatus == IdentityVerificationStatus.sourceConfirmed)) {
      return MedicineVerificationStatus.verified;
    }
    if (clinicalVerificationStatus == ClinicalVerificationStatus.monographLinked ||
        identityVerificationStatus == IdentityVerificationStatus.sourceConfirmed) {
      return MedicineVerificationStatus.partiallyVerified;
    }
    if (clinicalVerificationStatus == ClinicalVerificationStatus.flaggedForReview) {
      return MedicineVerificationStatus.underReview;
    }
    return MedicineVerificationStatus.notVerified;
  }

  const MedicineItem({
    required this.id,
    required this.name,
    this.brandName,
    required this.genericName,
    required this.ingredients,
    required this.strength,
    required this.dosageForm,
    this.dosageCategory = 'solid_oral',
    this.route = 'oral',
    this.manufacturer,
    required this.classification,
    required this.overview,
    required this.commonUses,
    required this.sideEffects,
    required this.precautions,
    required this.contraindications,
    required this.drugInteractions,
    this.storageInfo,
    this.identityVerificationStatus = IdentityVerificationStatus.unverified,
    this.clinicalVerificationStatus = ClinicalVerificationStatus.unverified,
    MedicineVerificationStatus? verificationStatus,
    required this.verificationScope,
    required this.sourceReferences,
    this.sourceMetadata = const {},
    this.mrpInr,
    this.lastReviewedDate,
    this.isPrescriptionRequired = true,
  }) : _explicitVerificationStatus = verificationStatus;

  factory MedicineItem.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is String) {
        if (value.startsWith('[') && value.endsWith(']')) {
          final stripped = value.substring(1, value.length - 1);
          return stripped
              .split(',')
              .map((e) => e.replaceAll('"', '').replaceAll("'", '').trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
        return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    List<MedicineInteraction> parseInteractions(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) {
          if (e is Map<String, dynamic>) {
            return MedicineInteraction.fromJson(e);
          }
          return MedicineInteraction(
            interactingDrug: e.toString(),
            severity: 'Moderate',
            clinicalEffect: 'Consult physician for co-administration guidance.',
            management: 'Monitor patient closely.',
            evidenceSource: 'Reference Pharmacopoeia',
          );
        }).toList();
      }
      return [];
    }

    Map<String, dynamic> parseSourceMetadata(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return {};
    }

    // Determine Identity Status
    IdentityVerificationStatus identityStatus = IdentityVerificationStatus.unverified;
    if (json['identity_verification_status'] != null || json['identityVerificationStatus'] != null) {
      identityStatus = IdentityVerificationStatus.fromString(
        json['identity_verification_status']?.toString() ?? json['identityVerificationStatus']?.toString(),
      );
    } else if (json['identity_verification'] is Map) {
      identityStatus = IdentityVerificationStatus.fromString(
        json['identity_verification']['status']?.toString(),
      );
    } else if (json['verification_status'] != null) {
      final legacy = MedicineVerificationStatus.fromString(json['verification_status']?.toString());
      if (legacy == MedicineVerificationStatus.verified) {
        identityStatus = IdentityVerificationStatus.sourceConfirmed;
      } else if (legacy == MedicineVerificationStatus.withdrawn) {
        identityStatus = IdentityVerificationStatus.withdrawn;
      }
    }

    // Determine Clinical Status
    ClinicalVerificationStatus clinicalStatus = ClinicalVerificationStatus.unverified;
    if (json['clinical_verification_status'] != null || json['clinicalVerificationStatus'] != null) {
      clinicalStatus = ClinicalVerificationStatus.fromString(
        json['clinical_verification_status']?.toString() ?? json['clinicalVerificationStatus']?.toString(),
      );
    } else if (json['clinical_verification'] is Map) {
      clinicalStatus = ClinicalVerificationStatus.fromString(
        json['clinical_verification']['status']?.toString(),
      );
    } else if (json['verification_status'] != null) {
      final legacy = MedicineVerificationStatus.fromString(json['verification_status']?.toString());
      if (legacy == MedicineVerificationStatus.verified) {
        clinicalStatus = ClinicalVerificationStatus.monographLinked;
      } else if (legacy == MedicineVerificationStatus.underReview) {
        clinicalStatus = ClinicalVerificationStatus.flaggedForReview;
      }
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    return MedicineItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['medicine_name'] ?? 'Unknown Medicine').toString(),
      brandName: json['brand_name']?.toString() ?? json['brandName']?.toString(),
      genericName: (json['generic_name'] ?? json['genericName'] ?? '').toString(),
      ingredients: parseStringList(json['ingredients'] ?? json['composition']),
      strength: (json['strength'] ?? '').toString(),
      dosageForm: (json['dosage_form'] ?? json['dosageForm'] ?? 'Tablet').toString(),
      dosageCategory: (json['dosage_category'] ?? json['dosageCategory'] ?? 'solid_oral').toString(),
      route: (json['route'] ?? 'oral').toString(),
      manufacturer: json['manufacturer']?.toString(),
      classification: (json['classification'] ?? 'Brand').toString(),
      overview: (json['overview'] ?? '').toString(),
      commonUses: parseStringList(json['common_uses'] ?? json['commonUses'] ?? json['indications']),
      sideEffects: parseStringList(json['side_effects'] ?? json['sideEffects']),
      precautions: parseStringList(json['precautions']),
      contraindications: parseStringList(json['contraindications']),
      drugInteractions: parseInteractions(json['drug_interactions'] ?? json['drugInteractions']),
      storageInfo: json['storage_info']?.toString() ?? json['storageInfo']?.toString(),
      identityVerificationStatus: identityStatus,
      clinicalVerificationStatus: clinicalStatus,
      verificationScope: (json['verification_scope'] ??
              json['verificationScope'] ??
              'Product identity supported by regulatory monographs')
          .toString(),
      sourceReferences: parseStringList(json['source_references'] ?? json['sourceReferences']),
      sourceMetadata: parseSourceMetadata(json['source_metadata'] ?? json['sourceMetadata']),
      mrpInr: parseDouble(json['mrp_inr'] ?? json['mrpInr']),
      lastReviewedDate: json['last_reviewed_date']?.toString() ?? json['lastReviewedDate']?.toString(),
      isPrescriptionRequired: json['is_prescription_required'] ?? json['isPrescriptionRequired'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand_name': brandName,
      'generic_name': genericName,
      'ingredients': ingredients,
      'strength': strength,
      'dosage_form': dosageForm,
      'dosage_category': dosageCategory,
      'route': route,
      'manufacturer': manufacturer,
      'classification': classification,
      'overview': overview,
      'common_uses': commonUses,
      'side_effects': sideEffects,
      'precautions': precautions,
      'contraindications': contraindications,
      'drug_interactions': drugInteractions.map((e) => e.toJson()).toList(),
      'storage_info': storageInfo,
      'verification_status': verificationStatus.name,
      'identity_verification_status': identityVerificationStatus.name,
      'clinical_verification_status': clinicalVerificationStatus.name,
      'verification_scope': verificationScope,
      'source_references': sourceReferences,
      'source_metadata': sourceMetadata,
      'mrp_inr': mrpInr,
      'last_reviewed_date': lastReviewedDate,
      'is_prescription_required': isPrescriptionRequired,
    };
  }
}
