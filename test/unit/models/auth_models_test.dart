import 'package:flutter_test/flutter_test.dart';
import 'package:bdr_tournament_recorder/domain/models/auth_models.dart';

void main() {
  group('UserInfo', () {
    test('should create with required fields only', () {
      final user = UserInfo(
        id: 1,
        email: 'test@example.com',
      );

      expect(user.id, 1);
      expect(user.email, 'test@example.com');
      expect(user.name, isNull);
      expect(user.nickname, isNull);
      expect(user.displayName, isNull);
      expect(user.canCreateTournament, false);
    });

    test('should create with all fields', () {
      final user = UserInfo(
        id: 1,
        publicId: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        nickname: 'tester',
        displayName: 'Test Display',
        membershipType: 'premium',
        canCreateTournament: true,
        avatarUrl: 'https://example.com/avatar.png',
      );

      expect(user.id, 1);
      expect(user.publicId, 'user_123');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.nickname, 'tester');
      expect(user.displayName, 'Test Display');
      expect(user.membershipType, 'premium');
      expect(user.canCreateTournament, true);
      expect(user.avatarUrl, 'https://example.com/avatar.png');
    });

    group('fromJson', () {
      test('should parse all fields', () {
        final json = {
          'id': 42,
          'public_id': 'pub_42',
          'email': 'user@test.com',
          'name': 'User Name',
          'nickname': 'nick',
          'display_name': 'Display',
          'membership_type': 'free',
          'can_create_tournament': true,
          'avatar_url': 'https://img.com/a.png',
        };

        final user = UserInfo.fromJson(json);

        expect(user.id, 42);
        expect(user.publicId, 'pub_42');
        expect(user.email, 'user@test.com');
        expect(user.name, 'User Name');
        expect(user.nickname, 'nick');
        expect(user.displayName, 'Display');
        expect(user.membershipType, 'free');
        expect(user.canCreateTournament, true);
        expect(user.avatarUrl, 'https://img.com/a.png');
      });

      test('should handle missing optional fields', () {
        final json = {
          'id': 1,
          'email': 'min@test.com',
        };

        final user = UserInfo.fromJson(json);

        expect(user.id, 1);
        expect(user.email, 'min@test.com');
        expect(user.publicId, isNull);
        expect(user.name, isNull);
        expect(user.canCreateTournament, false);
      });

      test('should handle null can_create_tournament as false', () {
        final json = {
          'id': 1,
          'email': 'test@test.com',
          'can_create_tournament': null,
        };

        final user = UserInfo.fromJson(json);
        expect(user.canCreateTournament, false);
      });
    });

    group('toJson', () {
      test('should serialize all fields', () {
        final user = UserInfo(
          id: 1,
          publicId: 'pub_1',
          email: 'test@example.com',
          name: 'Test',
          nickname: 'tester',
          displayName: 'Test User',
          membershipType: 'pro',
          canCreateTournament: true,
          avatarUrl: 'https://img.com/test.png',
        );

        final json = user.toJson();

        expect(json['id'], 1);
        expect(json['public_id'], 'pub_1');
        expect(json['email'], 'test@example.com');
        expect(json['name'], 'Test');
        expect(json['nickname'], 'tester');
        expect(json['display_name'], 'Test User');
        expect(json['membership_type'], 'pro');
        expect(json['can_create_tournament'], true);
        expect(json['avatar_url'], 'https://img.com/test.png');
      });
    });

    group('displayNameOrEmail', () {
      test('should return displayName if available', () {
        final user = UserInfo(
          id: 1,
          email: 'test@example.com',
          name: 'Name',
          nickname: 'Nick',
          displayName: 'Display',
        );

        expect(user.displayNameOrEmail, 'Display');
      });

      test('should return nickname if displayName is null', () {
        final user = UserInfo(
          id: 1,
          email: 'test@example.com',
          name: 'Name',
          nickname: 'Nick',
        );

        expect(user.displayNameOrEmail, 'Nick');
      });

      test('should return name if displayName and nickname are null', () {
        final user = UserInfo(
          id: 1,
          email: 'test@example.com',
          name: 'Name',
        );

        expect(user.displayNameOrEmail, 'Name');
      });

      test('should return email prefix if all others are null', () {
        final user = UserInfo(
          id: 1,
          email: 'test@example.com',
        );

        expect(user.displayNameOrEmail, 'test');
      });

      test('should handle email with multiple @ symbols', () {
        final user = UserInfo(
          id: 1,
          email: 'weird@email@example.com',
        );

        expect(user.displayNameOrEmail, 'weird');
      });
    });
  });

  group('LoginResponse', () {
    test('should create with all fields', () {
      final user = UserInfo(id: 1, email: 'test@example.com');
      final expiresAt = DateTime(2024, 12, 31, 23, 59, 59);

      final response = LoginResponse(
        token: 'test_token_123',
        user: user,
        expiresAt: expiresAt,
      );

      expect(response.token, 'test_token_123');
      expect(response.user.id, 1);
      expect(response.expiresAt, expiresAt);
    });

    group('fromJson', () {
      test('should parse from json', () {
        final json = {
          'token': 'jwt_token',
          'user': {
            'id': 5,
            'email': 'user@test.com',
          },
          'expires_at': '2024-06-15T12:00:00.000Z',
        };

        final response = LoginResponse.fromJson(json);

        expect(response.token, 'jwt_token');
        expect(response.user.id, 5);
        expect(response.user.email, 'user@test.com');
        expect(response.expiresAt.year, 2024);
        expect(response.expiresAt.month, 6);
        expect(response.expiresAt.day, 15);
      });
    });

    group('toJson', () {
      test('should serialize to json', () {
        final expiresAt = DateTime.utc(2024, 6, 15, 12, 0, 0);
        final response = LoginResponse(
          token: 'my_token',
          user: UserInfo(id: 10, email: 'ser@test.com'),
          expiresAt: expiresAt,
        );

        final json = response.toJson();

        expect(json['token'], 'my_token');
        expect(json['user']['id'], 10);
        expect(json['expires_at'], '2024-06-15T12:00:00.000Z');
      });
    });
  });

  group('MyTournamentInfo', () {
    test('should create with required fields', () {
      final tournament = MyTournamentInfo(
        id: 'tour_1',
        name: 'Summer League',
        status: 'in_progress',
        role: 'organizer',
        canEdit: true,
      );

      expect(tournament.id, 'tour_1');
      expect(tournament.name, 'Summer League');
      expect(tournament.status, 'in_progress');
      expect(tournament.role, 'organizer');
      expect(tournament.canEdit, true);
      expect(tournament.teamCount, 0);
      expect(tournament.matchCount, 0);
    });

    test('should create with all fields', () {
      final startDate = DateTime(2024, 6, 1);
      final endDate = DateTime(2024, 8, 31);

      final tournament = MyTournamentInfo(
        id: 'tour_2',
        name: 'Winter Cup',
        status: 'draft',
        format: 'single_elimination',
        startDate: startDate,
        endDate: endDate,
        venueName: 'Main Arena',
        venueAddress: '123 Sports St',
        teamCount: 16,
        matchCount: 15,
        seriesName: 'Regional Series',
        role: 'admin',
        canEdit: false,
        apiToken: 'api_token_123',
        logoUrl: 'https://logo.com/cup.png',
      );

      expect(tournament.format, 'single_elimination');
      expect(tournament.startDate, startDate);
      expect(tournament.endDate, endDate);
      expect(tournament.venueName, 'Main Arena');
      expect(tournament.venueAddress, '123 Sports St');
      expect(tournament.teamCount, 16);
      expect(tournament.matchCount, 15);
      expect(tournament.seriesName, 'Regional Series');
      expect(tournament.apiToken, 'api_token_123');
      expect(tournament.logoUrl, 'https://logo.com/cup.png');
    });

    group('fromJson', () {
      test('should parse all fields', () {
        final json = {
          'id': 'tour_123',
          'name': 'Test Tournament',
          'status': 'registration_open',
          'format': 'round_robin',
          'start_date': '2024-07-01T00:00:00.000Z',
          'end_date': '2024-07-15T00:00:00.000Z',
          'venue_name': 'Stadium',
          'venue_address': '456 Field Rd',
          'team_count': 8,
          'match_count': 28,
          'series_name': 'Summer Series',
          'role': 'editor',
          'can_edit': true,
          'api_token': 'token_xyz',
          'logo_url': 'https://example.com/logo.png',
        };

        final tournament = MyTournamentInfo.fromJson(json);

        expect(tournament.id, 'tour_123');
        expect(tournament.name, 'Test Tournament');
        expect(tournament.status, 'registration_open');
        expect(tournament.format, 'round_robin');
        expect(tournament.startDate?.year, 2024);
        expect(tournament.startDate?.month, 7);
        expect(tournament.venueName, 'Stadium');
        expect(tournament.teamCount, 8);
        expect(tournament.matchCount, 28);
        expect(tournament.role, 'editor');
        expect(tournament.canEdit, true);
        expect(tournament.apiToken, 'token_xyz');
      });

      test('should handle missing optional fields', () {
        final json = {
          'id': 'tour_min',
          'name': 'Minimal',
          'status': 'draft',
          'role': 'viewer',
        };

        final tournament = MyTournamentInfo.fromJson(json);

        expect(tournament.id, 'tour_min');
        expect(tournament.format, isNull);
        expect(tournament.startDate, isNull);
        expect(tournament.teamCount, 0);
        expect(tournament.canEdit, false);
      });

      test('should handle null dates', () {
        final json = {
          'id': 'tour_null',
          'name': 'Null Dates',
          'status': 'draft',
          'role': 'admin',
          'start_date': null,
          'end_date': null,
        };

        final tournament = MyTournamentInfo.fromJson(json);

        expect(tournament.startDate, isNull);
        expect(tournament.endDate, isNull);
      });
    });

    group('statusText', () {
      test('should return correct text for draft', () {
        final t = MyTournamentInfo(id: '1', name: 't', status: 'draft', role: 'admin', canEdit: true);
        expect(t.statusText, '준비 중');
      });

      test('should return correct text for registration_open', () {
        final t = MyTournamentInfo(id: '1', name: 't', status: 'registration_open', role: 'admin', canEdit: true);
        expect(t.statusText, '모집 중');
      });

      test('should return correct text for registration_closed', () {
        final t = MyTournamentInfo(id: '1', name: 't', status: 'registration_closed', role: 'admin', canEdit: true);
        expect(t.statusText, '모집 마감');
      });

      test('should return correct text for in_progress', () {
        final t = MyTournamentInfo(id: '1', name: 't', status: 'in_progress', role: 'admin', canEdit: true);
        expect(t.statusText, '진행 중');
      });

      test('should return correct text for completed', () {
        final t = MyTournamentInfo(id: '1', name: 't', status: 'completed', role: 'admin', canEdit: true);
        expect(t.statusText, '종료');
      });

      test('should return correct text for cancelled', () {
        final t = MyTournamentInfo(id: '1', name: 't', status: 'cancelled', role: 'admin', canEdit: true);
        expect(t.statusText, '취소됨');
      });

      test('should return raw status for unknown', () {
        final t = MyTournamentInfo(id: '1', name: 't', status: 'unknown_status', role: 'admin', canEdit: true);
        expect(t.statusText, 'unknown_status');
      });
    });

    group('roleText', () {
      test('should return correct text for organizer', () {
        final t = MyTournamentInfo(id: '1', name: 't', status: 'draft', role: 'organizer', canEdit: true);
        expect(t.roleText, '주최자');
      });

      test('should return correct text for owner', () {
        final t = MyTournamentInfo(id: '1', name: 't', status: 'draft', role: 'owner', canEdit: true);
        expect(t.roleText, '소유자');
      });

      test('should return correct text for admin', () {
        final t = MyTournamentInfo(id: '1', name: 't', status: 'draft', role: 'admin', canEdit: true);
        expect(t.roleText, '관리자');
      });

      test('should return correct text for editor', () {
        final t = MyTournamentInfo(id: '1', name: 't', status: 'draft', role: 'editor', canEdit: true);
        expect(t.roleText, '편집자');
      });

      test('should return correct text for viewer', () {
        final t = MyTournamentInfo(id: '1', name: 't', status: 'draft', role: 'viewer', canEdit: false);
        expect(t.roleText, '열람자');
      });

      test('should return raw role for unknown', () {
        final t = MyTournamentInfo(id: '1', name: 't', status: 'draft', role: 'custom_role', canEdit: true);
        expect(t.roleText, 'custom_role');
      });
    });

    group('canRecord', () {
      test('should return true for in_progress', () {
        final t = MyTournamentInfo(id: '1', name: 't', status: 'in_progress', role: 'admin', canEdit: true);
        expect(t.canRecord, true);
      });

      test('should return true for registration_closed', () {
        final t = MyTournamentInfo(id: '1', name: 't', status: 'registration_closed', role: 'admin', canEdit: true);
        expect(t.canRecord, true);
      });

      test('should return true for registration_open', () {
        final t = MyTournamentInfo(id: '1', name: 't', status: 'registration_open', role: 'admin', canEdit: true);
        expect(t.canRecord, true);
      });

      test('should return false for draft', () {
        final t = MyTournamentInfo(id: '1', name: 't', status: 'draft', role: 'admin', canEdit: true);
        expect(t.canRecord, false);
      });

      test('should return false for completed', () {
        final t = MyTournamentInfo(id: '1', name: 't', status: 'completed', role: 'admin', canEdit: true);
        expect(t.canRecord, false);
      });

      test('should return false for cancelled', () {
        final t = MyTournamentInfo(id: '1', name: 't', status: 'cancelled', role: 'admin', canEdit: true);
        expect(t.canRecord, false);
      });
    });

    group('toJson', () {
      test('should serialize all fields', () {
        final tournament = MyTournamentInfo(
          id: 'tour_json',
          name: 'JSON Test',
          status: 'in_progress',
          format: 'bracket',
          startDate: DateTime.utc(2024, 1, 1),
          endDate: DateTime.utc(2024, 1, 31),
          venueName: 'Arena',
          venueAddress: 'Address',
          teamCount: 4,
          matchCount: 3,
          seriesName: 'Series',
          role: 'admin',
          canEdit: true,
          apiToken: 'token',
          logoUrl: 'url',
        );

        final json = tournament.toJson();

        expect(json['id'], 'tour_json');
        expect(json['name'], 'JSON Test');
        expect(json['status'], 'in_progress');
        expect(json['format'], 'bracket');
        expect(json['start_date'], '2024-01-01T00:00:00.000Z');
        expect(json['end_date'], '2024-01-31T00:00:00.000Z');
        expect(json['venue_name'], 'Arena');
        expect(json['team_count'], 4);
        expect(json['role'], 'admin');
        expect(json['can_edit'], true);
        expect(json['api_token'], 'token');
      });
    });
  });

  group('AuthStatus', () {
    test('should have all enum values', () {
      expect(AuthStatus.values.length, 5);
      expect(AuthStatus.values, contains(AuthStatus.initial));
      expect(AuthStatus.values, contains(AuthStatus.loading));
      expect(AuthStatus.values, contains(AuthStatus.authenticated));
      expect(AuthStatus.values, contains(AuthStatus.unauthenticated));
      expect(AuthStatus.values, contains(AuthStatus.error));
    });
  });

  group('AuthState', () {
    test('should have correct default values', () {
      final state = AuthState();

      expect(state.status, AuthStatus.initial);
      expect(state.user, isNull);
      expect(state.token, isNull);
      expect(state.expiresAt, isNull);
      expect(state.errorMessage, isNull);
    });

    test('should create with all fields', () {
      final user = UserInfo(id: 1, email: 'test@test.com');
      final expiresAt = DateTime(2024, 12, 31);

      final state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        token: 'auth_token',
        expiresAt: expiresAt,
        errorMessage: null,
      );

      expect(state.status, AuthStatus.authenticated);
      expect(state.user, user);
      expect(state.token, 'auth_token');
      expect(state.expiresAt, expiresAt);
    });

    group('isAuthenticated', () {
      test('should return true when authenticated with token', () {
        final state = AuthState(
          status: AuthStatus.authenticated,
          token: 'token',
        );

        expect(state.isAuthenticated, true);
      });

      test('should return false when authenticated but no token', () {
        final state = AuthState(
          status: AuthStatus.authenticated,
          token: null,
        );

        expect(state.isAuthenticated, false);
      });

      test('should return false when not authenticated', () {
        final state = AuthState(
          status: AuthStatus.unauthenticated,
          token: 'token',
        );

        expect(state.isAuthenticated, false);
      });
    });

    group('isLoading', () {
      test('should return true when loading', () {
        final state = AuthState(status: AuthStatus.loading);
        expect(state.isLoading, true);
      });

      test('should return false when not loading', () {
        final state = AuthState(status: AuthStatus.authenticated);
        expect(state.isLoading, false);
      });
    });

    group('copyWith', () {
      test('should copy with all fields changed', () {
        final original = AuthState();
        final user = UserInfo(id: 1, email: 'test@test.com');
        final expiresAt = DateTime(2024, 12, 31);

        final copied = original.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          token: 'new_token',
          expiresAt: expiresAt,
          errorMessage: 'error',
        );

        expect(copied.status, AuthStatus.authenticated);
        expect(copied.user, user);
        expect(copied.token, 'new_token');
        expect(copied.expiresAt, expiresAt);
        expect(copied.errorMessage, 'error');
      });

      test('should preserve unchanged fields', () {
        final user = UserInfo(id: 1, email: 'test@test.com');
        final original = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          token: 'orig_token',
        );

        final copied = original.copyWith(status: AuthStatus.loading);

        expect(copied.status, AuthStatus.loading);
        expect(copied.user, user);
        expect(copied.token, 'orig_token');
      });
    });
  });
}
