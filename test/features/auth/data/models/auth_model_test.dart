import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/features/auth/data/models/auth_model.dart';

void main() {
  group('Profiles', () {
    const testId = 'user-uuid-001';
    const testName = 'Budi Santoso';
    const testUsername = 'budi_santoso';
    const testEmail = 'budi@example.com';
    const testRole = 'admin';
    const testNoTelp = '081234567890';

    final testMap = {
      'id': testId,
      'name': testName,
      'username': testUsername,
      'email': testEmail,
      'role': testRole,
      'no_telp': testNoTelp,
    };

    late Profiles testProfile;

    setUp(() {
      testProfile = Profiles(
        id: testId,
        name: testName,
        username: testUsername,
        email: testEmail,
        role: testRole,
        noTelp: testNoTelp,
      );
    });

    group('Constructor', () {
      test('should create Profiles with all required fields', () {
        expect(testProfile.id, testId);
        expect(testProfile.name, testName);
        expect(testProfile.username, testUsername);
        expect(testProfile.email, testEmail);
        expect(testProfile.role, testRole);
        expect(testProfile.noTelp, testNoTelp);
      });

      test('should create Profiles without optional username', () {
        final profile = Profiles(
          id: testId,
          name: testName,
          email: testEmail,
          role: testRole,
          noTelp: testNoTelp,
        );
        expect(profile.username, isNull);
      });
    });

    group('fromMap', () {
      test('should create Profiles from valid map', () {
        final profile = Profiles.fromMap(testMap);

        expect(profile.id, testId);
        expect(profile.name, testName);
        expect(profile.username, testUsername);
        expect(profile.email, testEmail);
        expect(profile.role, testRole);
        expect(profile.noTelp, testNoTelp);
      });

      test('should create Profiles with null username from map', () {
        final mapWithNullUsername = Map<String, dynamic>.from(testMap)
          ..['username'] = null;

        final profile = Profiles.fromMap(mapWithNullUsername);

        expect(profile.username, isNull);
      });
    });

    group('toMap', () {
      test('should convert Profiles to map correctly', () {
        final map = testProfile.toMap();

        expect(map['id'], testId);
        expect(map['name'], testName);
        expect(map['username'], testUsername);
        expect(map['email'], testEmail);
        expect(map['role'], testRole);
        expect(map['no_telp'], testNoTelp);
      });
    });

    group('roles', () {
      test('should correctly represent admin role', () {
        final profile = Profiles(
          id: '1',
          name: 'Admin',
          email: 'admin@example.com',
          role: 'admin',
          noTelp: '081111111111',
        );
        expect(profile.role, 'admin');
      });

      test('should correctly represent manager role', () {
        final profile = Profiles(
          id: '2',
          name: 'Manager',
          email: 'manager@example.com',
          role: 'manager',
          noTelp: '082222222222',
        );
        expect(profile.role, 'manager');
      });

      test('should correctly represent driver role', () {
        final profile = Profiles(
          id: '3',
          name: 'Driver',
          email: 'driver@example.com',
          role: 'driver',
          noTelp: '083333333333',
        );
        expect(profile.role, 'driver');
      });
    });
  });
}
