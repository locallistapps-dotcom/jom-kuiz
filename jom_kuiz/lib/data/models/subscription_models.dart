import '../../domain/entities/parent_subscription.dart';
import '../../domain/entities/subject_access.dart';
import '../../domain/entities/subscription_package.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SubscriptionPackage
// ═══════════════════════════════════════════════════════════════════════════════

class SubscriptionPackageModel {
  const SubscriptionPackageModel({
    required this.id,
    required this.name,
    required this.maxChildren,
    required this.includedSubjectIds,
    required this.priceCents,
    required this.durationDays,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  final String id;
  final String name;
  final String? description;
  final int maxChildren;
  final List<String> includedSubjectIds;
  final int priceCents;
  final int durationDays;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SubscriptionPackageModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawIds = json['included_subject_ids'];
    final List<String> subjectIds = rawIds is List
        ? rawIds.map((dynamic e) => e.toString()).toList()
        : <String>[];

    return SubscriptionPackageModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      maxChildren: (json['max_children'] as num?)?.toInt() ?? 5,
      includedSubjectIds: subjectIds,
      priceCents: (json['price_cents'] as num?)?.toInt() ?? 0,
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 30,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'description': description,
        'max_children': maxChildren,
        'included_subject_ids': includedSubjectIds,
        'price_cents': priceCents,
        'duration_days': durationDays,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  SubscriptionPackage toEntity() => SubscriptionPackage(
        id: id,
        name: name,
        description: description,
        maxChildren: maxChildren,
        includedSubjectIds: includedSubjectIds,
        priceCents: priceCents,
        durationDays: durationDays,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

// ── Request bodies ────────────────────────────────────────────────────────────

class CreatePackageRequest {
  const CreatePackageRequest({
    required this.name,
    required this.maxChildren,
    required this.includedSubjectIds,
    required this.priceCents,
    required this.durationDays,
    this.description,
  });

  final String name;
  final String? description;
  final int maxChildren;
  final List<String> includedSubjectIds;
  final int priceCents;
  final int durationDays;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        if (description != null) 'description': description,
        'max_children': maxChildren,
        'included_subject_ids': includedSubjectIds,
        'price_cents': priceCents,
        'duration_days': durationDays,
        'is_active': true,
      };
}

class UpdatePackageRequest {
  const UpdatePackageRequest({
    required this.name,
    required this.maxChildren,
    required this.includedSubjectIds,
    required this.priceCents,
    required this.durationDays,
    required this.isActive,
    this.description,
  });

  final String name;
  final String? description;
  final int maxChildren;
  final List<String> includedSubjectIds;
  final int priceCents;
  final int durationDays;
  final bool isActive;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'description': description,
        'max_children': maxChildren,
        'included_subject_ids': includedSubjectIds,
        'price_cents': priceCents,
        'duration_days': durationDays,
        'is_active': isActive,
      };
}

// ═══════════════════════════════════════════════════════════════════════════════
// ParentSubscription
// ═══════════════════════════════════════════════════════════════════════════════

class ParentSubscriptionModel {
  const ParentSubscriptionModel({
    required this.id,
    required this.parentId,
    required this.packageId,
    required this.startDate,
    required this.expiryDate,
    required this.status,
    required this.autoRenew,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String parentId;
  final String packageId;
  final DateTime startDate;
  final DateTime expiryDate;
  final String status;
  final bool autoRenew;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ParentSubscriptionModel.fromJson(Map<String, dynamic> json) =>
      ParentSubscriptionModel(
        id: json['id'] as String,
        parentId: json['parent_id'] as String,
        packageId: json['package_id'] as String,
        startDate: DateTime.parse(json['start_date'] as String),
        expiryDate: DateTime.parse(json['expiry_date'] as String),
        status: json['status'] as String? ?? 'pending',
        autoRenew: json['auto_renew'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'parent_id': parentId,
        'package_id': packageId,
        'start_date': startDate.toIso8601String(),
        'expiry_date': expiryDate.toIso8601String(),
        'status': status,
        'auto_renew': autoRenew,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  ParentSubscription toEntity() => ParentSubscription(
        id: id,
        parentId: parentId,
        packageId: packageId,
        startDate: startDate,
        expiryDate: expiryDate,
        status: ParentSubscriptionStatusX.fromString(status),
        autoRenew: autoRenew,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

class CreateSubscriptionRequest {
  const CreateSubscriptionRequest({
    required this.parentId,
    required this.packageId,
    required this.startDate,
    required this.expiryDate,
  });

  final String parentId;
  final String packageId;
  final DateTime startDate;
  final DateTime expiryDate;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'parent_id': parentId,
        'package_id': packageId,
        'start_date': startDate.toIso8601String().substring(0, 10),
        'expiry_date': expiryDate.toIso8601String().substring(0, 10),
        'status': 'active',
      };
}

// ═══════════════════════════════════════════════════════════════════════════════
// SubjectAccess
// ═══════════════════════════════════════════════════════════════════════════════

class SubjectAccessModel {
  const SubjectAccessModel({
    required this.id,
    required this.parentId,
    required this.subjectId,
    required this.grantedAt,
    required this.source,
    this.expiresAt,
  });

  final String id;
  final String parentId;
  final String subjectId;
  final DateTime grantedAt;
  final String source;
  final DateTime? expiresAt;

  factory SubjectAccessModel.fromJson(Map<String, dynamic> json) =>
      SubjectAccessModel(
        id: json['id'] as String,
        parentId: json['parent_id'] as String,
        subjectId: json['subject_id'] as String,
        grantedAt: DateTime.parse(json['granted_at'] as String),
        source: json['source'] as String? ?? 'subscription',
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'parent_id': parentId,
        'subject_id': subjectId,
        'granted_at': grantedAt.toIso8601String(),
        'source': source,
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      };

  SubjectAccess toEntity() => SubjectAccess(
        id: id,
        parentId: parentId,
        subjectId: subjectId,
        grantedAt: grantedAt,
        source: SubjectAccessSourceX.fromString(source),
        expiresAt: expiresAt,
      );
}

class GrantAccessRequest {
  const GrantAccessRequest({
    required this.parentId,
    required this.subjectId,
    required this.source,
    this.expiresAt,
  });

  final String parentId;
  final String subjectId;
  final String source;
  final DateTime? expiresAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'parent_id': parentId,
        'subject_id': subjectId,
        'source': source,
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      };
}
