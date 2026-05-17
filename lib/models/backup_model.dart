class BackupModel {
  final String appName;
  final String version;
  final DateTime backupDate;
  final String deviceInfo;
  final Map<String, dynamic> data;

  static const String currentVersion = '1.0.0';
  static const String appIdentifier = 'HisaabKitaab';

  BackupModel({
    this.appName = appIdentifier,
    this.version = currentVersion,
    DateTime? backupDate,
    this.deviceInfo = '',
    required this.data,
  }) : backupDate = backupDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'app': appName,
        'version': version,
        'backup_date': backupDate.toIso8601String(),
        'device': deviceInfo,
        'data': data,
      };

  factory BackupModel.fromJson(Map<String, dynamic> json) => BackupModel(
        appName: json['app'] ?? appIdentifier,
        version: json['version'] ?? currentVersion,
        backupDate: DateTime.parse(json['backup_date']),
        deviceInfo: json['device'] ?? '',
        data: Map<String, dynamic>.from(json['data']),
      );

  /// Validation — check this is a valid HisaabKitaab backup file
  bool get isValid =>
      appName == appIdentifier &&
      data.containsKey('accounts') &&
      data.containsKey('transactions');

  /// Summary for restore preview
  String get summary {
    final accounts = (data['accounts'] as List?)?.length ?? 0;
    final txns = (data['transactions'] as List?)?.length ?? 0;
    final loans = (data['loans'] as List?)?.length ?? 0;
    final payments = (data['payments'] as List?)?.length ?? 0;
    return '$txns વ્યવહારો • $loans ઉધાર • $accounts ખાતા • $payments હપ્તા';
  }
}
