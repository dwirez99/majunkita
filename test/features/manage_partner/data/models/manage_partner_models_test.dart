import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/features/manage_partner/data/models/manage_partner_models.dart';

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // UserProfile
  // ────────────────────────────────────────────────────────────────────────────
  group('UserProfile', () {
    const testId = 'user-001';
    const testName = 'Andi Wijaya';
    const testEmail = 'andi@example.com';
    const testNoTelp = '081234567890';
    const testRole = 'admin';
    const testUsername = 'andi_wijaya';

    final validJson = {
      'id': testId,
      'name': testName,
      'email': testEmail,
      'no_telp': testNoTelp,
      'role': testRole,
      'username': testUsername,
    };

    group('Constructor', () {
      test('should create UserProfile with required fields', () {
        final profile = UserProfile(
          id: testId,
          name: testName,
          email: testEmail,
          noTelp: testNoTelp,
          role: testRole,
        );
        expect(profile.id, testId);
        expect(profile.name, testName);
        expect(profile.email, testEmail);
        expect(profile.noTelp, testNoTelp);
        expect(profile.role, testRole);
        expect(profile.username, isNull);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON correctly', () {
        final profile = UserProfile.fromJson(validJson);

        expect(profile.id, testId);
        expect(profile.name, testName);
        expect(profile.email, testEmail);
        expect(profile.noTelp, testNoTelp);
        expect(profile.role, testRole);
        expect(profile.username, testUsername);
      });

      test('should use default "Tanpa Nama" when name is null', () {
        final json = Map<String, dynamic>.from(validJson)..['name'] = null;
        final profile = UserProfile.fromJson(json);
        expect(profile.name, 'Tanpa Nama');
      });

      test('should use default empty string for missing email', () {
        final json = Map<String, dynamic>.from(validJson)..remove('email');
        final profile = UserProfile.fromJson(json);
        expect(profile.email, '');
      });

      test('should use default "-" for missing no_telp', () {
        final json = Map<String, dynamic>.from(validJson)..remove('no_telp');
        final profile = UserProfile.fromJson(json);
        expect(profile.noTelp, '-');
      });

      test('should use "staff" as default role when missing', () {
        final json = Map<String, dynamic>.from(validJson)..remove('role');
        final profile = UserProfile.fromJson(json);
        expect(profile.role, 'staff');
      });

      test('should handle null username', () {
        final json = Map<String, dynamic>.from(validJson)
          ..['username'] = null;
        final profile = UserProfile.fromJson(json);
        expect(profile.username, isNull);
      });
    });

    group('toJson', () {
      test('should produce correct JSON', () {
        final profile = UserProfile(
          id: testId,
          name: testName,
          email: testEmail,
          noTelp: testNoTelp,
          role: testRole,
          username: testUsername,
        );
        final json = profile.toJson();

        expect(json['id'], testId);
        expect(json['name'], testName);
        expect(json['email'], testEmail);
        expect(json['no_telp'], testNoTelp);
        expect(json['role'], testRole);
        expect(json['username'], testUsername);
      });
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Admin
  // ────────────────────────────────────────────────────────────────────────────
  group('Admin', () {
    const testId = 'admin-001';
    const testName = 'Citra Lestari';
    const testEmail = 'citra@example.com';
    const testNoTelp = '082111222333';
    const testAddress = 'Jl. Admin No. 5, Yogyakarta';
    const testUsername = 'citra_admin';

    final validJson = {
      'id': testId,
      'name': testName,
      'email': testEmail,
      'no_telp': testNoTelp,
      'address': testAddress,
      'username': testUsername,
    };

    group('Constructor', () {
      test('should create Admin with required fields', () {
        final admin = Admin(
          id: testId,
          name: testName,
          email: testEmail,
          noTelp: testNoTelp,
        );
        expect(admin.id, testId);
        expect(admin.name, testName);
        expect(admin.email, testEmail);
        expect(admin.noTelp, testNoTelp);
        expect(admin.username, isNull);
        expect(admin.address, isNull);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON correctly', () {
        final admin = Admin.fromJson(validJson);

        expect(admin.id, testId);
        expect(admin.name, testName);
        expect(admin.email, testEmail);
        expect(admin.noTelp, testNoTelp);
        expect(admin.address, testAddress);
        expect(admin.username, testUsername);
      });

      test('should use default "Tanpa Nama" for null name', () {
        final json = Map<String, dynamic>.from(validJson)..['name'] = null;
        final admin = Admin.fromJson(json);
        expect(admin.name, 'Tanpa Nama');
      });

      test('should use default empty string for null email', () {
        final json = Map<String, dynamic>.from(validJson)..['email'] = null;
        final admin = Admin.fromJson(json);
        expect(admin.email, '');
      });

      test('should use default "-" for null no_telp', () {
        final json = Map<String, dynamic>.from(validJson)..['no_telp'] = null;
        final admin = Admin.fromJson(json);
        expect(admin.noTelp, '-');
      });

      test('should allow null address', () {
        final json = Map<String, dynamic>.from(validJson)..remove('address');
        final admin = Admin.fromJson(json);
        expect(admin.address, isNull);
      });
    });

    group('toJson', () {
      test('should produce correct JSON', () {
        final admin = Admin(
          id: testId,
          name: testName,
          email: testEmail,
          noTelp: testNoTelp,
          address: testAddress,
          username: testUsername,
        );
        final json = admin.toJson();

        expect(json['id'], testId);
        expect(json['name'], testName);
        expect(json['email'], testEmail);
        expect(json['no_telp'], testNoTelp);
        expect(json['address'], testAddress);
        expect(json['username'], testUsername);
      });
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Driver
  // ────────────────────────────────────────────────────────────────────────────
  group('Driver', () {
    const testId = 'driver-001';
    const testName = 'Joko Susanto';
    const testEmail = 'joko@example.com';
    const testNoTelp = '085999888777';
    const testAddress = 'Jl. Sopir No. 10, Semarang';

    final validJson = {
      'id': testId,
      'name': testName,
      'email': testEmail,
      'no_telp': testNoTelp,
      'address': testAddress,
      'username': 'joko_driver',
    };

    group('Constructor', () {
      test('should create Driver with required fields', () {
        final driver = Driver(
          id: testId,
          name: testName,
          email: testEmail,
          noTelp: testNoTelp,
        );
        expect(driver.id, testId);
        expect(driver.name, testName);
        expect(driver.email, testEmail);
        expect(driver.noTelp, testNoTelp);
        expect(driver.username, isNull);
        expect(driver.address, isNull);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON correctly', () {
        final driver = Driver.fromJson(validJson);

        expect(driver.id, testId);
        expect(driver.name, testName);
        expect(driver.email, testEmail);
        expect(driver.noTelp, testNoTelp);
        expect(driver.address, testAddress);
        expect(driver.username, 'joko_driver');
      });

      test('should use "Tanpa Nama" default for null name', () {
        final json = Map<String, dynamic>.from(validJson)..['name'] = null;
        final driver = Driver.fromJson(json);
        expect(driver.name, 'Tanpa Nama');
      });

      test('should use default "-" for null no_telp', () {
        final json = Map<String, dynamic>.from(validJson)..['no_telp'] = null;
        final driver = Driver.fromJson(json);
        expect(driver.noTelp, '-');
      });
    });

    group('toJson', () {
      test('should produce correct JSON', () {
        final driver = Driver(
          id: testId,
          name: testName,
          email: testEmail,
          noTelp: testNoTelp,
          address: testAddress,
          username: 'joko_driver',
        );
        final json = driver.toJson();

        expect(json['id'], testId);
        expect(json['name'], testName);
        expect(json['email'], testEmail);
        expect(json['no_telp'], testNoTelp);
        expect(json['address'], testAddress);
        expect(json['username'], 'joko_driver');
      });
    });
  });
}
