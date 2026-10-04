/// Reasons a user can pick when reporting someone; the key is the server enum.
const reportReasons = <String, String>{
  'SPAM': 'Spam',
  'HARASSMENT': 'Harassment',
  'INAPPROPRIATE': 'Inappropriate content',
  'IMPERSONATION': 'Impersonation',
  'OTHER': 'Something else',
};

/// One row of the admin moderation queue.
class AdminReport {
  final String id;
  final String reportedUserId;
  final String reportedLabel;
  final String reporterLabel;
  final String reason;
  final String? details;
  final String status;

  /// Open reports against the reported user, across all reporters.
  final int openReports;

  /// True once the reported user has 3+ open reports.
  final bool flagged;

  const AdminReport({
    required this.id,
    required this.reportedUserId,
    required this.reportedLabel,
    required this.reporterLabel,
    required this.reason,
    required this.details,
    required this.status,
    required this.openReports,
    required this.flagged,
  });

  factory AdminReport.fromMap(Map<String, dynamic> map) {
    String label(Map<String, dynamic> user) {
      final username = user['username'] as String?;
      return username != null ? '@$username' : (user['name'] as String? ?? '');
    }

    final reported = map['reportedUser'] as Map<String, dynamic>;
    return AdminReport(
      id: map['id'] as String,
      reportedUserId: reported['id'] as String,
      reportedLabel: label(reported),
      reporterLabel: label(map['reporter'] as Map<String, dynamic>),
      reason: map['reason'] as String,
      details: map['details'] as String?,
      status: map['status'] as String,
      openReports: (map['openReports'] as num?)?.toInt() ?? 0,
      flagged: map['flagged'] as bool? ?? false,
    );
  }

  String get reasonLabel => reportReasons[reason] ?? reason;
}
