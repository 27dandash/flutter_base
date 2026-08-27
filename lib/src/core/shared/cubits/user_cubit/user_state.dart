part of 'user_cubit.dart';

enum UserStatus { restoring, loggedIn, loggedOut, blocked, needsActivation }

class UserState extends Equatable {
  const UserState({
    required this.userModel,
    required this.userStatus,
    this.terminationReason,
    this.message,
    this.activationData,
    this.cleanupFailures = const [],
  });

  factory UserState.initial() => UserState(
    userModel: UserModel.initial(),
    userStatus: UserStatus.restoring,
  );

  factory UserState.loggedOut({
    SessionTerminationReason? reason,
    String? message,
    List<String> cleanupFailures = const [],
  }) => UserState(
    userModel: UserModel.initial(),
    userStatus: UserStatus.loggedOut,
    terminationReason: reason,
    message: message,
    cleanupFailures: cleanupFailures,
  );

  final UserModel userModel;
  final UserStatus userStatus;
  final SessionTerminationReason? terminationReason;
  final String? message;
  final Object? activationData;
  final List<String> cleanupFailures;

  bool get isAuthenticated => userStatus == UserStatus.loggedIn;

  UserState copyWith({
    UserModel? userModel,
    UserStatus? userStatus,
    SessionTerminationReason? terminationReason,
    String? message,
    Object? activationData,
    List<String>? cleanupFailures,
  }) {
    return UserState(
      userModel: userModel ?? this.userModel,
      userStatus: userStatus ?? this.userStatus,
      terminationReason: terminationReason ?? this.terminationReason,
      message: message ?? this.message,
      activationData: activationData ?? this.activationData,
      cleanupFailures: cleanupFailures ?? this.cleanupFailures,
    );
  }

  @override
  List<Object?> get props => [
    userModel,
    userStatus,
    terminationReason,
    message,
    activationData,
    cleanupFailures,
  ];
}
