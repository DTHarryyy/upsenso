import 'package:equatable/equatable.dart';

/// Represents the state of branch selection
class BranchState extends Equatable {
  /// Currently selected branch name
  final String? selectedBranch;

  /// Currently selected branch ID
  final String? selectedBranchId;

  /// List of available branches for the user
  final List<String> availableBranches;

  /// Whether the user can switch branches (Super Admin only)
  final bool canSwitchBranches;

  /// Whether we're loading branches
  final bool isLoading;

  /// User's role name
  final String? roleName;

  const BranchState({
    this.selectedBranch,
    this.selectedBranchId,
    this.availableBranches = const [],
    this.canSwitchBranches = false,
    this.isLoading = false,
    this.roleName,
  });

  /// Initial state
  factory BranchState.initial() => const BranchState();

  /// Loading state
  factory BranchState.loading() => const BranchState(isLoading: true);

  BranchState copyWith({
    String? selectedBranch,
    String? selectedBranchId,
    List<String>? availableBranches,
    bool? canSwitchBranches,
    bool? isLoading,
    String? roleName,
  }) {
    return BranchState(
      selectedBranch: selectedBranch ?? this.selectedBranch,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      availableBranches: availableBranches ?? this.availableBranches,
      canSwitchBranches: canSwitchBranches ?? this.canSwitchBranches,
      isLoading: isLoading ?? this.isLoading,
      roleName: roleName ?? this.roleName,
    );
  }

  @override
  List<Object?> get props => [
    selectedBranch,
    selectedBranchId,
    availableBranches,
    canSwitchBranches,
    isLoading,
    roleName,
  ];
}
