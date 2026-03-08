import 'package:equatable/equatable.dart';

/// Represents the state of branch selection
class BranchState extends Equatable {
  /// Currently selected branch name
  final String? selectedBranch;

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
    List<String>? availableBranches,
    bool? canSwitchBranches,
    bool? isLoading,
    String? roleName,
  }) {
    return BranchState(
      selectedBranch: selectedBranch ?? this.selectedBranch,
      availableBranches: availableBranches ?? this.availableBranches,
      canSwitchBranches: canSwitchBranches ?? this.canSwitchBranches,
      isLoading: isLoading ?? this.isLoading,
      roleName: roleName ?? this.roleName,
    );
  }

  @override
  List<Object?> get props => [
    selectedBranch,
    availableBranches,
    canSwitchBranches,
    isLoading,
    roleName,
  ];
}
