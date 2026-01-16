import 'package:flutter_test/flutter_test.dart';
import 'package:scanstock/models/profile.dart';

void main() {
  group('Profile', () {
    group('fromJson', () {
      test('crea Profile desde JSON valido completo', () {
        final json = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'email': 'test@example.com',
          'full_name': 'Juan Perez',
          'role': 'admin',
          'created_at': '2024-01-15T10:30:00Z',
          'business_id': 'business-123',
          'is_super_admin': true,
        };

        final profile = Profile.fromJson(json);

        expect(profile.id, '123e4567-e89b-12d3-a456-426614174000');
        expect(profile.email, 'test@example.com');
        expect(profile.fullName, 'Juan Perez');
        expect(profile.role, 'admin');
        expect(profile.createdAt, isNotNull);
        expect(profile.businessId, 'business-123');
        expect(profile.isSuperAdmin, isTrue);
      });

      test('usa valores por defecto para campos opcionales', () {
        final json = {
          'id': '123',
          'email': 'test@example.com',
          'created_at': '2024-01-15T10:30:00Z',
        };

        final profile = Profile.fromJson(json);

        expect(profile.fullName, isNull);
        expect(profile.role, 'user'); // Default role
        expect(profile.businessId, isNull);
        expect(profile.isSuperAdmin, isFalse); // Default false
      });

      test('maneja role null como user', () {
        final json = {
          'id': '123',
          'email': 'test@example.com',
          'role': null,
          'created_at': '2024-01-15T10:30:00Z',
        };

        final profile = Profile.fromJson(json);

        expect(profile.role, 'user');
      });
    });

    group('toJson', () {
      test('convierte Profile a JSON correctamente', () {
        final profile = Profile(
          id: '123',
          email: 'test@example.com',
          fullName: 'Juan Perez',
          role: 'admin',
          createdAt: DateTime(2024, 1, 15, 10, 30),
          businessId: 'business-123',
          isSuperAdmin: true,
        );

        final json = profile.toJson();

        expect(json['id'], '123');
        expect(json['email'], 'test@example.com');
        expect(json['full_name'], 'Juan Perez');
        expect(json['role'], 'admin');
        expect(json['created_at'], isNotNull);
        expect(json['business_id'], 'business-123');
        expect(json['is_super_admin'], isTrue);
      });

      test('incluye valores null en JSON', () {
        final profile = Profile(
          id: '123',
          email: 'test@example.com',
          role: 'user',
          createdAt: DateTime.now(),
        );

        final json = profile.toJson();

        expect(json.containsKey('full_name'), isTrue);
        expect(json['full_name'], isNull);
        expect(json.containsKey('business_id'), isTrue);
        expect(json['business_id'], isNull);
      });
    });

    group('copyWith', () {
      test('crea copia con valores modificados', () {
        final original = Profile(
          id: '123',
          email: 'original@example.com',
          fullName: 'Original Name',
          role: 'user',
          createdAt: DateTime.now(),
          businessId: 'business-1',
          isSuperAdmin: false,
        );

        final copia = original.copyWith(
          fullName: 'Nuevo Nombre',
          role: 'admin',
        );

        expect(copia.id, '123');
        expect(copia.email, 'original@example.com');
        expect(copia.fullName, 'Nuevo Nombre');
        expect(copia.role, 'admin');
        expect(copia.businessId, 'business-1');
        expect(copia.isSuperAdmin, isFalse);
      });
    });

    group('getters de rol', () {
      test('isAdmin retorna true solo para role admin', () {
        final admin = Profile(
          id: '1',
          email: 'admin@test.com',
          role: 'admin',
          createdAt: DateTime.now(),
        );

        final user = Profile(
          id: '2',
          email: 'user@test.com',
          role: 'user',
          createdAt: DateTime.now(),
        );

        expect(admin.isAdmin, isTrue);
        expect(admin.isUser, isFalse);
        expect(user.isAdmin, isFalse);
        expect(user.isUser, isTrue);
      });

      test('isUser retorna true solo para role user', () {
        final user = Profile(
          id: '1',
          email: 'user@test.com',
          role: 'user',
          createdAt: DateTime.now(),
        );

        expect(user.isUser, isTrue);
        expect(user.isAdmin, isFalse);
      });
    });

    group('hasNegocio', () {
      test('retorna true cuando businessId no es null', () {
        final conNegocio = Profile(
          id: '1',
          email: 'test@test.com',
          role: 'user',
          createdAt: DateTime.now(),
          businessId: 'business-123',
        );

        expect(conNegocio.hasNegocio, isTrue);
      });

      test('retorna false cuando businessId es null', () {
        final sinNegocio = Profile(
          id: '1',
          email: 'test@test.com',
          role: 'user',
          createdAt: DateTime.now(),
        );

        expect(sinNegocio.hasNegocio, isFalse);
      });
    });

    group('isSuperAdmin', () {
      test('distingue entre super admin y admin regular', () {
        final superAdmin = Profile(
          id: '1',
          email: 'super@test.com',
          role: 'admin',
          createdAt: DateTime.now(),
          isSuperAdmin: true,
        );

        final adminRegular = Profile(
          id: '2',
          email: 'admin@test.com',
          role: 'admin',
          createdAt: DateTime.now(),
          isSuperAdmin: false,
        );

        expect(superAdmin.isSuperAdmin, isTrue);
        expect(superAdmin.isAdmin, isTrue);
        expect(adminRegular.isSuperAdmin, isFalse);
        expect(adminRegular.isAdmin, isTrue);
      });
    });
  });
}
