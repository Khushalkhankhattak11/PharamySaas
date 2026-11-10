enum ApprovalStatus {
  pending('pending', 'Pending Approval'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected'),
  suspended('suspended', 'Suspended');

  final String value;
  final String label;
  const ApprovalStatus(this.value, this.label);

  static ApprovalStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'approved':
        return ApprovalStatus.approved;
      case 'rejected':
        return ApprovalStatus.rejected;
      case 'suspended':
        return ApprovalStatus.suspended;
      case 'pending':
      default:
        return ApprovalStatus.pending;
    }
  }

  bool get isApproved => this == ApprovalStatus.approved;
  bool get isPending => this == ApprovalStatus.pending;
  bool get isRejected => this == ApprovalStatus.rejected;
  bool get isSuspended => this == ApprovalStatus.suspended;
}

