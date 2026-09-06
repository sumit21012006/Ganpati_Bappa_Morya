/// Business/retailer model — mirrors shared `businesses`,
/// `business_identifiers` and `business_locations` tables.
enum BusinessType {
  manufacturer,
  packer,
  importer,
  retailer,
  wholesaler,
  distributor,
  other;

  String get label => switch (this) {
        BusinessType.manufacturer => 'Manufacturer',
        BusinessType.packer => 'Packer',
        BusinessType.importer => 'Importer',
        BusinessType.retailer => 'Retailer',
        BusinessType.wholesaler => 'Wholesaler',
        BusinessType.distributor => 'Distributor',
        BusinessType.other => 'Other',
      };

  static BusinessType fromLabel(String? label) => BusinessType.values
      .where((t) => t.label.toLowerCase() == label?.toLowerCase())
      .firstOrNull ?? BusinessType.retailer;
}

enum BusinessStatus { active, pending, suspended }

extension BusinessStatusX on BusinessStatus {
  String get label => switch (this) {
        BusinessStatus.active => 'Active',
        BusinessStatus.pending => 'Verification Pending',
        BusinessStatus.suspended => 'Suspended',
      };
}

class BusinessLocation {
  const BusinessLocation({
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    this.latitude,
    this.longitude,
  });

  final String addressLine;
  final String city;
  final String state;
  final String pincode;

  /// PostGIS coordinates come from the backend; display-only here.
  final double? latitude;
  final double? longitude;

  String get singleLine => '$addressLine, $city, $state — $pincode';

  factory BusinessLocation.fromJson(Map<String, dynamic> json) =>
      BusinessLocation(
        addressLine: json['addressLine'] as String,
        city: json['city'] as String,
        state: json['state'] as String,
        pincode: json['pincode'] as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}

class Business {
  const Business({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.location,
    this.gstin,
    this.ownerName,
    this.contactPhone,
    this.contactEmail,
    this.pan,
    this.annualTurnover,
  });

  final String id;
  final String name;
  final BusinessType type;
  final BusinessStatus status;
  final BusinessLocation location;
  final String? gstin;
  final String? ownerName;
  final String? contactPhone;
  final String? contactEmail;
  final String? pan;

  /// In rupees — display formatted, backend authoritative.
  final double? annualTurnover;

  Business copyWith({
    String? id,
    String? name,
    BusinessType? type,
    BusinessStatus? status,
    BusinessLocation? location,
    String? gstin,
    String? ownerName,
    String? contactPhone,
    String? contactEmail,
    String? pan,
    double? annualTurnover,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      location: location ?? this.location,
      gstin: gstin ?? this.gstin,
      ownerName: ownerName ?? this.ownerName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      pan: pan ?? this.pan,
      annualTurnover: annualTurnover ?? this.annualTurnover,
    );
  }

  factory Business.fromJson(Map<String, dynamic> json) => Business(
        id: json['id'] as String,
        name: json['name'] as String,
        type: BusinessType.fromLabel(json['type'] as String?),
        status: switch (json['status'] as String?) {
          'PENDING' => BusinessStatus.pending,
          'SUSPENDED' => BusinessStatus.suspended,
          _ => BusinessStatus.active,
        },
        location:
            BusinessLocation.fromJson(json['location'] as Map<String, dynamic>),
        gstin: json['gstin'] as String?,
        ownerName: json['ownerName'] as String?,
        contactPhone: json['contactPhone'] as String?,
        contactEmail: json['contactEmail'] as String?,
        pan: json['pan'] as String?,
        annualTurnover: (json['annualTurnover'] as num?)?.toDouble(),
      );
}

/// Registration request DTO. GSTIN verification is backend-driven (Member 6).
class BusinessRegistrationRequest {
  const BusinessRegistrationRequest({
    required this.name,
    required this.type,
    required this.location,
    this.gstin,
    this.ownerName,
    this.contactPhone,
    this.contactEmail,
    this.pan,
    this.annualTurnover,
  });

  final String name;
  final BusinessType type;
  final BusinessLocation location;
  final String? gstin;
  final String? ownerName;
  final String? contactPhone;
  final String? contactEmail;
  final String? pan;
  final double? annualTurnover;

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.label,
        'location': {
          'addressLine': location.addressLine,
          'city': location.city,
          'state': location.state,
          'pincode': location.pincode,
        },
        if (gstin != null) 'gstin': gstin,
        if (ownerName != null) 'ownerName': ownerName,
        if (contactPhone != null) 'contactPhone': contactPhone,
        if (contactEmail != null) 'contactEmail': contactEmail,
        if (pan != null) 'pan': pan,
        if (annualTurnover != null) 'annualTurnover': annualTurnover,
      };
}
