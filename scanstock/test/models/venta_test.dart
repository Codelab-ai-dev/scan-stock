import 'package:flutter_test/flutter_test.dart';
import 'package:scanstock/models/venta.dart';
import 'package:scanstock/models/venta_item.dart';

void main() {
  group('Venta', () {
    group('fromJson', () {
      test('crea Venta desde JSON valido', () {
        final json = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'total': 250.50,
          'cantidad_items': 5,
          'created_by': 'user-123',
          'created_at': '2024-01-15T10:30:00Z',
        };

        final venta = Venta.fromJson(json);

        expect(venta.id, '123e4567-e89b-12d3-a456-426614174000');
        expect(venta.total, 250.50);
        expect(venta.cantidadItems, 5);
        expect(venta.createdBy, 'user-123');
        expect(venta.createdAt, isNotNull);
        expect(venta.creadorNombre, isNull);
        expect(venta.creadorEmail, isNull);
      });

      test('extrae datos del creador desde profiles join', () {
        final json = {
          'id': '123',
          'total': 100.0,
          'cantidad_items': 2,
          'created_by': 'user-123',
          'created_at': '2024-01-15T10:30:00Z',
          'profiles': {
            'full_name': 'Juan Perez',
            'email': 'juan@example.com',
          },
        };

        final venta = Venta.fromJson(json);

        expect(venta.creadorNombre, 'Juan Perez');
        expect(venta.creadorEmail, 'juan@example.com');
      });

      test('convierte total de int a double', () {
        final json = {
          'id': '123',
          'total': 100, // int en lugar de double
          'cantidad_items': 1,
          'created_at': '2024-01-15T10:30:00Z',
        };

        final venta = Venta.fromJson(json);

        expect(venta.total, 100.0);
        expect(venta.total, isA<double>());
      });

      test('acepta items externos', () {
        final json = {
          'id': '123',
          'total': 100.0,
          'cantidad_items': 1,
          'created_at': '2024-01-15T10:30:00Z',
        };

        final items = <VentaItem>[
          VentaItem(
            id: 'item-1',
            ventaId: '123',
            productoId: 'prod-1',
            productoNombre: 'Producto 1',
            productoCodigoBarras: '7501234567890',
            precioUnitario: 50.0,
            cantidad: 2,
            subtotal: 100.0,
          ),
        ];

        final venta = Venta.fromJson(json, items: items);

        expect(venta.items, isNotNull);
        expect(venta.items!.length, 1);
        expect(venta.items!.first.productoNombre, 'Producto 1');
      });
    });

    group('toJson', () {
      test('convierte Venta a JSON correctamente', () {
        final venta = Venta(
          id: '123',
          total: 250.50,
          cantidadItems: 5,
          createdBy: 'user-123',
        );

        final json = venta.toJson();

        expect(json['id'], '123');
        expect(json['total'], 250.50);
        expect(json['cantidad_items'], 5);
        expect(json['created_by'], 'user-123');
      });

      test('excluye id y created_by cuando son null', () {
        final venta = Venta(
          total: 100.0,
          cantidadItems: 2,
        );

        final json = venta.toJson();

        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('created_by'), isFalse);
      });
    });

    group('copyWith', () {
      test('crea copia con valores modificados', () {
        final original = Venta(
          id: '123',
          total: 100.0,
          cantidadItems: 2,
          createdBy: 'user-1',
        );

        final copia = original.copyWith(
          total: 200.0,
          cantidadItems: 4,
        );

        expect(copia.id, '123');
        expect(copia.total, 200.0);
        expect(copia.cantidadItems, 4);
        expect(copia.createdBy, 'user-1');
      });
    });

    group('totalFormateado', () {
      test('formatea total con dos decimales', () {
        final venta1 = Venta(total: 99.99, cantidadItems: 1);
        final venta2 = Venta(total: 1000.0, cantidadItems: 1);
        final venta3 = Venta(total: 49.5, cantidadItems: 1);

        expect(venta1.totalFormateado, '\$99.99');
        expect(venta2.totalFormateado, '\$1000.00');
        expect(venta3.totalFormateado, '\$49.50');
      });
    });

    group('fechaFormateada', () {
      test('formatea fecha correctamente', () {
        final venta = Venta(
          total: 100.0,
          cantidadItems: 1,
          createdAt: DateTime(2024, 1, 15, 10, 30),
        );

        expect(venta.fechaFormateada, '15/01/2024 10:30');
      });

      test('retorna string vacio si createdAt es null', () {
        final venta = Venta(
          total: 100.0,
          cantidadItems: 1,
        );

        expect(venta.fechaFormateada, '');
      });

      test('formatea con padding para dias y meses menores a 10', () {
        final venta = Venta(
          total: 100.0,
          cantidadItems: 1,
          createdAt: DateTime(2024, 3, 5, 9, 5),
        );

        expect(venta.fechaFormateada, '05/03/2024 09:05');
      });
    });

    group('fechaCorta', () {
      test('formatea solo fecha sin hora', () {
        final venta = Venta(
          total: 100.0,
          cantidadItems: 1,
          createdAt: DateTime(2024, 12, 25, 14, 30),
        );

        expect(venta.fechaCorta, '25/12/2024');
      });

      test('retorna string vacio si createdAt es null', () {
        final venta = Venta(
          total: 100.0,
          cantidadItems: 1,
        );

        expect(venta.fechaCorta, '');
      });
    });
  });
}
