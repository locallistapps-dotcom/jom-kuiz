import 'package:equatable/equatable.dart';

/// A subscription package that parents can purchase.
///
/// Each package bundles a set of subjects, defines access for a fixed
/// duration, and caps the number of children that may inherit access.
class SubscriptionPackage extends Equatable {
  const SubscriptionPackage({
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

  /// Supabase UUID primary key.
  final String id;

  /// Display name of the package (e.g. "Starter Pack").
  final String name;

  /// Optional marketing description.
  final String? description;

  /// Maximum number of children that can inherit access under this package.
  final int maxChildren;

  /// UUIDs of [Subject]s included in this package.
  final List<String> includedSubjectIds;

  /// Price in minor currency units (sen for MYR, e.g. 2999 = RM 29.99).
  final int priceCents;

  /// How many days the subscription remains valid after activation.
  final int durationDays;

  /// Whether this package is visible to parents and purchasable.
  final bool isActive;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Price formatted as a display string (e.g. "RM 29.99").
  String get priceDisplay {
    final double ringgit = priceCents / 100;
    return 'RM ${ringgit.toStringAsFixed(2)}';
  }

  SubscriptionPackage copyWith({
    String? id,
    String? name,
    String? description,
    int? maxChildren,
    List<String>? includedSubjectIds,
    int? priceCents,
    int? durationDays,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      SubscriptionPackage(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        maxChildren: maxChildren ?? this.maxChildren,
        includedSubjectIds: includedSubjectIds ?? this.includedSubjectIds,
        priceCents: priceCents ?? this.priceCents,
        durationDays: durationDays ?? this.durationDays,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        description,
        maxChildren,
        includedSubjectIds,
        priceCents,
        durationDays,
        isActive,
        createdAt,
        updatedAt,
      ];
}
