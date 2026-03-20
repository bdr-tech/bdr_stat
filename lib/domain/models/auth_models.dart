/// 로그인 응답 모델
class LoginResponse {
  LoginResponse({
    required this.token,
    required this.user,
    required this.expiresAt,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final expiresAtStr = json['expires_at'] as String?;
    return LoginResponse(
      token: json['token'] as String,
      user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
      expiresAt: expiresAtStr != null
          ? DateTime.parse(expiresAtStr)
          : DateTime.now().add(const Duration(days: 30)),
    );
  }

  final String token;
  final UserInfo user;
  final DateTime expiresAt;

  Map<String, dynamic> toJson() => {
        'token': token,
        'user': user.toJson(),
        'expires_at': expiresAt.toIso8601String(),
      };
}

/// 사용자 정보 모델
class UserInfo {
  UserInfo({
    required this.id,
    this.publicId,
    required this.email,
    this.name,
    this.nickname,
    this.displayName,
    this.membershipType,
    this.canCreateTournament = false,
    this.avatarUrl,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    // id: API returns String ("1"), handle both int and String
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.parse(rawId.toString());
    // membership_type: API may return int (0) or String
    final rawMembership = json['membership_type'];
    final membershipType = rawMembership is String
        ? rawMembership
        : rawMembership?.toString();
    return UserInfo(
      id: id,
      publicId: json['public_id'] as String?,
      email: json['email'] as String,
      name: json['name'] as String?,
      nickname: json['nickname'] as String?,
      displayName: json['display_name'] as String?,
      membershipType: membershipType,
      canCreateTournament: json['can_create_tournament'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  final int id;
  final String? publicId;
  final String email;
  final String? name;
  final String? nickname;
  final String? displayName;
  final String? membershipType;
  final bool canCreateTournament;
  final String? avatarUrl;

  /// 표시용 이름 (닉네임 > 이름 > 이메일)
  String get displayNameOrEmail =>
      displayName ?? nickname ?? name ?? email.split('@').first;

  Map<String, dynamic> toJson() => {
        'id': id,
        'public_id': publicId,
        'email': email,
        'name': name,
        'nickname': nickname,
        'display_name': displayName,
        'membership_type': membershipType,
        'can_create_tournament': canCreateTournament,
        'avatar_url': avatarUrl,
      };
}

/// 내 대회 정보 모델
class MyTournamentInfo {
  MyTournamentInfo({
    required this.id,
    required this.name,
    required this.status,
    this.format,
    this.startDate,
    this.endDate,
    this.venueName,
    this.venueAddress,
    this.teamCount = 0,
    this.matchCount = 0,
    this.seriesName,
    required this.role,
    required this.canEdit,
    this.apiToken,
    this.logoUrl,
  });

  factory MyTournamentInfo.fromJson(Map<String, dynamic> json) {
    return MyTournamentInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      format: json['format'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
      endDate:
          json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
      venueName: json['venue_name'] as String?,
      venueAddress: json['venue_address'] as String?,
      teamCount: json['team_count'] as int? ?? 0,
      matchCount: json['match_count'] as int? ?? 0,
      seriesName: json['series_name'] as String?,
      role: json['role'] as String,
      canEdit: json['can_edit'] as bool? ?? false,
      apiToken: json['api_token'] as String?,
      logoUrl: json['logo_url'] as String?,
    );
  }

  final String id;
  final String name;
  final String status;
  final String? format;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? venueName;
  final String? venueAddress;
  final int teamCount;
  final int matchCount;
  final String? seriesName;
  final String role;
  final bool canEdit;
  final String? apiToken;
  final String? logoUrl;

  /// 상태 표시 텍스트
  String get statusText {
    switch (status) {
      case 'draft':
        return '준비 중';
      case 'registration_open':
        return '모집 중';
      case 'registration_closed':
        return '모집 마감';
      case 'in_progress':
        return '진행 중';
      case 'completed':
        return '종료';
      case 'cancelled':
        return '취소됨';
      default:
        return status;
    }
  }

  /// 역할 표시 텍스트
  String get roleText {
    switch (role) {
      case 'organizer':
        return '주최자';
      case 'owner':
        return '소유자';
      case 'admin':
        return '관리자';
      case 'editor':
        return '편집자';
      case 'viewer':
        return '열람자';
      default:
        return role;
    }
  }

  /// 대회가 기록 가능한 상태인지
  bool get canRecord =>
      status == 'in_progress' ||
      status == 'registration_closed' ||
      status == 'registration_open';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status,
        'format': format,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'venue_name': venueName,
        'venue_address': venueAddress,
        'team_count': teamCount,
        'match_count': matchCount,
        'series_name': seriesName,
        'role': role,
        'can_edit': canEdit,
        'api_token': apiToken,
        'logo_url': logoUrl,
      };
}

/// 인증 상태
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// 인증 상태 모델
class AuthState {
  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.token,
    this.expiresAt,
    this.errorMessage,
    this.isDevMode = false,
  });

  final AuthStatus status;
  final UserInfo? user;
  final String? token;
  final DateTime? expiresAt;
  final String? errorMessage;
  final bool isDevMode;

  bool get isAuthenticated => status == AuthStatus.authenticated && token != null;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    UserInfo? user,
    String? token,
    DateTime? expiresAt,
    String? errorMessage,
    bool? isDevMode,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
      errorMessage: errorMessage ?? this.errorMessage,
      isDevMode: isDevMode ?? this.isDevMode,
    );
  }
}
