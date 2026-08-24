library;

import 'dart:convert';

class HealthStatus {
  final String status;
  final String service;
  final String version;
  final String env;
  final int uptimeSeconds;
  final bool databaseConnected;
  final int migrationsApplied;
  final String schemaVersion;

  HealthStatus({
    required this.status,
    required this.service,
    required this.version,
    required this.env,
    required this.uptimeSeconds,
    required this.databaseConnected,
    required this.migrationsApplied,
    required this.schemaVersion,
  });

  bool get isHealthy => status == 'ok' && databaseConnected;

  HealthStatus copyWith({
    String? status,
    String? service,
    String? version,
    String? env,
    int? uptimeSeconds,
    bool? databaseConnected,
    int? migrationsApplied,
    String? schemaVersion,
  }) {
    return HealthStatus(
      status: status ?? this.status,
      service: service ?? this.service,
      version: version ?? this.version,
      env: env ?? this.env,
      uptimeSeconds: uptimeSeconds ?? this.uptimeSeconds,
      databaseConnected: databaseConnected ?? this.databaseConnected,
      migrationsApplied: migrationsApplied ?? this.migrationsApplied,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'status': status,
      'service': service,
      'version': version,
      'env': env,
      'uptime_seconds': uptimeSeconds,
      'database': {
        'connected': databaseConnected,
        'migrations_applied': migrationsApplied,
        'schema_version': schemaVersion,
      },
    };
  }

  factory HealthStatus.fromMap(Map<String, dynamic> map) {
    final database =
        (map['database'] as Map?)?.cast<String, dynamic>() ?? const {};

    return HealthStatus(
      status: map['status'] != null ? map['status'] as String : 'unknown',
      service: map['service'] != null ? map['service'] as String : 'zoa-api',
      version: map['version'] != null ? map['version'] as String : '?',
      env: map['env'] != null ? map['env'] as String : '?',
      uptimeSeconds: map['uptime_seconds'] != null
          ? (map['uptime_seconds'] as num).toInt()
          : 0,
      databaseConnected: database['connected'] != null
          ? database['connected'] as bool
          : false,
      migrationsApplied: database['migrations_applied'] != null
          ? (database['migrations_applied'] as num).toInt()
          : 0,
      schemaVersion: database['schema_version'] != null
          ? database['schema_version'] as String
          : '',
    );
  }

  String toJson() => json.encode(toMap());

  factory HealthStatus.fromJson(String source) =>
      HealthStatus.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'HealthStatus(status: $status, service: $service, version: $version, env: $env, uptimeSeconds: $uptimeSeconds, databaseConnected: $databaseConnected, migrationsApplied: $migrationsApplied, schemaVersion: $schemaVersion)';
  }

  @override
  bool operator ==(covariant HealthStatus other) {
    if (identical(this, other)) return true;

    return other.status == status &&
        other.service == service &&
        other.version == version &&
        other.env == env &&
        other.uptimeSeconds == uptimeSeconds &&
        other.databaseConnected == databaseConnected &&
        other.migrationsApplied == migrationsApplied &&
        other.schemaVersion == schemaVersion;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        service.hashCode ^
        version.hashCode ^
        env.hashCode ^
        uptimeSeconds.hashCode ^
        databaseConnected.hashCode ^
        migrationsApplied.hashCode ^
        schemaVersion.hashCode;
  }
}

class MaterialInfo {
  final String key;
  final String group;
  final String label;
  final int pointsPerKg;

  MaterialInfo({
    required this.key,
    required this.group,
    required this.label,
    required this.pointsPerKg,
  });

  bool get requiresSourceType => group == 'organic';

  MaterialInfo copyWith({
    String? key,
    String? group,
    String? label,
    int? pointsPerKg,
  }) {
    return MaterialInfo(
      key: key ?? this.key,
      group: group ?? this.group,
      label: label ?? this.label,
      pointsPerKg: pointsPerKg ?? this.pointsPerKg,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'key': key,
      'group': group,
      'label': label,
      'points_per_kg': pointsPerKg,
    };
  }

  factory MaterialInfo.fromMap(Map<String, dynamic> map) {
    return MaterialInfo(
      key: map['key'] != null ? map['key'] as String : '',
      group: map['group'] != null ? map['group'] as String : 'other',
      label: map['label'] != null
          ? map['label'] as String
          : map['key'] as String,
      pointsPerKg: map['points_per_kg'] != null
          ? (map['points_per_kg'] as num).toInt()
          : 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory MaterialInfo.fromJson(String source) =>
      MaterialInfo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MaterialInfo(key: $key, group: $group, label: $label, pointsPerKg: $pointsPerKg)';
  }

  @override
  bool operator ==(covariant MaterialInfo other) {
    if (identical(this, other)) return true;

    return other.key == key &&
        other.group == group &&
        other.label == label &&
        other.pointsPerKg == pointsPerKg;
  }

  @override
  int get hashCode {
    return key.hashCode ^
        group.hashCode ^
        label.hashCode ^
        pointsPerKg.hashCode;
  }
}

class MetaCatalog {
  final List<MaterialInfo> materials;

  MetaCatalog({required this.materials});

  Map<String, List<MaterialInfo>> get byGroup {
    final grouped = <String, List<MaterialInfo>>{};
    for (final material in materials) {
      grouped.putIfAbsent(material.group, () => []).add(material);
    }
    return grouped;
  }

  String labelFor(String key) {
    for (final material in materials) {
      if (material.key == key) return material.label;
    }
    return key;
  }

  int? rateFor(String key) {
    for (final material in materials) {
      if (material.key == key) return material.pointsPerKg;
    }
    return null;
  }

  MaterialInfo? materialFor(String key) {
    for (final material in materials) {
      if (material.key == key) return material;
    }
    return null;
  }

  MetaCatalog copyWith({List<MaterialInfo>? materials}) {
    return MetaCatalog(materials: materials ?? this.materials);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'materials': materials.map((x) => x.toMap()).toList(),
    };
  }

  factory MetaCatalog.fromMap(Map<String, dynamic> map) {
    final raw = map['materials'] as List? ?? const [];
    return MetaCatalog(
      materials: raw
          .whereType<Map>()
          .map((m) => MaterialInfo.fromMap(m.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  String toJson() => json.encode(toMap());

  factory MetaCatalog.fromJson(String source) =>
      MetaCatalog.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MetaCatalog(materials: $materials)';
  }

  @override
  bool operator ==(covariant MetaCatalog other) {
    if (identical(this, other)) return true;

    return other.materials == materials;
  }

  @override
  int get hashCode {
    return materials.hashCode;
  }
}
