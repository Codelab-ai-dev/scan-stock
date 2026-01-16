import 'package:flutter_test/flutter_test.dart';
import 'package:scanstock/models/producto.dart';

void main() {
  group('Producto', () {
    group('fromJson', () {
      test('crea Producto desde JSON valido', () {
        final json = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'codigo_barras': '7501234567890',
          'nombre': 'Producto de Prueba',
          'descripcion': 'Descripcion del producto',
          'precio': 99.99,
          'imagen_url': 'https://example.com/imagen.jpg',
          'stock_cantidad': 50,
          'stock_minimo': 10,
          'created_by': 'user-123',
          'created_at': '2024-01-15T10:30:00Z',
          'updated_at': '2024-01-16T15:45:00Z',
        };

        final producto = Producto.fromJson(json);

        expect(producto.id, '123e4567-e89b-12d3-a456-426614174000');
        expect(producto.codigoBarras, '7501234567890');
        expect(producto.nombre, 'Producto de Prueba');
        expect(producto.descripcion, 'Descripcion del producto');
        expect(producto.precio, 99.99);
        expect(producto.imagenUrl, 'https://example.com/imagen.jpg');
        expect(producto.stockCantidad, 50);
        expect(producto.stockMinimo, 10);
        expect(producto.createdBy, 'user-123');
        expect(producto.createdAt, isNotNull);
        expect(producto.updatedAt, isNotNull);
      });

      test('usa valores por defecto para campos opcionales', () {
        final json = {
          'codigo_barras': '7501234567890',
          'nombre': 'Producto Minimo',
          'precio': 50.0,
        };

        final producto = Producto.fromJson(json);

        expect(producto.id, isNull);
        expect(producto.descripcion, isNull);
        expect(producto.imagenUrl, isNull);
        expect(producto.stockCantidad, 0);
        expect(producto.stockMinimo, 5);
        expect(producto.createdBy, isNull);
        expect(producto.createdAt, isNull);
        expect(producto.updatedAt, isNull);
      });

      test('convierte precio de int a double', () {
        final json = {
          'codigo_barras': '7501234567890',
          'nombre': 'Producto',
          'precio': 100, // int en lugar de double
        };

        final producto = Producto.fromJson(json);

        expect(producto.precio, 100.0);
        expect(producto.precio, isA<double>());
      });
    });

    group('toJson', () {
      test('convierte Producto a JSON correctamente', () {
        final producto = Producto(
          id: '123',
          codigoBarras: '7501234567890',
          nombre: 'Producto Test',
          descripcion: 'Descripcion',
          precio: 99.99,
          imagenUrl: 'https://example.com/img.jpg',
          stockCantidad: 25,
          stockMinimo: 5,
          createdBy: 'user-123',
        );

        final json = producto.toJson();

        expect(json['id'], '123');
        expect(json['codigo_barras'], '7501234567890');
        expect(json['nombre'], 'Producto Test');
        expect(json['descripcion'], 'Descripcion');
        expect(json['precio'], 99.99);
        expect(json['imagen_url'], 'https://example.com/img.jpg');
        expect(json['stock_cantidad'], 25);
        expect(json['stock_minimo'], 5);
        expect(json['created_by'], 'user-123');
      });

      test('excluye id y created_by cuando son null', () {
        final producto = Producto(
          codigoBarras: '7501234567890',
          nombre: 'Producto Test',
          precio: 50.0,
        );

        final json = producto.toJson();

        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('created_by'), isFalse);
      });
    });

    group('copyWith', () {
      test('crea copia con valores modificados', () {
        final original = Producto(
          id: '123',
          codigoBarras: '7501234567890',
          nombre: 'Original',
          precio: 100.0,
          stockCantidad: 10,
        );

        final copia = original.copyWith(
          nombre: 'Modificado',
          precio: 150.0,
        );

        expect(copia.id, '123');
        expect(copia.codigoBarras, '7501234567890');
        expect(copia.nombre, 'Modificado');
        expect(copia.precio, 150.0);
        expect(copia.stockCantidad, 10);
      });

      test('mantiene valores originales si no se especifican', () {
        final original = Producto(
          id: '123',
          codigoBarras: '7501234567890',
          nombre: 'Original',
          descripcion: 'Descripcion original',
          precio: 100.0,
          stockCantidad: 50,
          stockMinimo: 10,
        );

        final copia = original.copyWith();

        expect(copia.id, original.id);
        expect(copia.codigoBarras, original.codigoBarras);
        expect(copia.nombre, original.nombre);
        expect(copia.descripcion, original.descripcion);
        expect(copia.precio, original.precio);
        expect(copia.stockCantidad, original.stockCantidad);
        expect(copia.stockMinimo, original.stockMinimo);
      });
    });

    group('getters de stock', () {
      test('tieneStockBajo retorna true cuando stock <= minimo', () {
        final productoBajo = Producto(
          codigoBarras: '123',
          nombre: 'Test',
          precio: 10.0,
          stockCantidad: 5,
          stockMinimo: 10,
        );

        final productoIgual = Producto(
          codigoBarras: '123',
          nombre: 'Test',
          precio: 10.0,
          stockCantidad: 10,
          stockMinimo: 10,
        );

        expect(productoBajo.tieneStockBajo, isTrue);
        expect(productoIgual.tieneStockBajo, isTrue);
      });

      test('tieneStockBajo retorna false cuando stock > minimo', () {
        final producto = Producto(
          codigoBarras: '123',
          nombre: 'Test',
          precio: 10.0,
          stockCantidad: 20,
          stockMinimo: 10,
        );

        expect(producto.tieneStockBajo, isFalse);
      });

      test('sinStock retorna true cuando stock <= 0', () {
        final sinStock = Producto(
          codigoBarras: '123',
          nombre: 'Test',
          precio: 10.0,
          stockCantidad: 0,
        );

        final conStock = Producto(
          codigoBarras: '123',
          nombre: 'Test',
          precio: 10.0,
          stockCantidad: 1,
        );

        expect(sinStock.sinStock, isTrue);
        expect(conStock.sinStock, isFalse);
      });

      test('estadoStock retorna estado correcto', () {
        final agotado = Producto(
          codigoBarras: '123',
          nombre: 'Test',
          precio: 10.0,
          stockCantidad: 0,
          stockMinimo: 5,
        );

        final bajo = Producto(
          codigoBarras: '123',
          nombre: 'Test',
          precio: 10.0,
          stockCantidad: 3,
          stockMinimo: 5,
        );

        final disponible = Producto(
          codigoBarras: '123',
          nombre: 'Test',
          precio: 10.0,
          stockCantidad: 20,
          stockMinimo: 5,
        );

        expect(agotado.estadoStock, 'agotado');
        expect(bajo.estadoStock, 'bajo');
        expect(disponible.estadoStock, 'disponible');
      });
    });

    group('precioFormateado', () {
      test('formatea precio con dos decimales', () {
        final producto1 = Producto(
          codigoBarras: '123',
          nombre: 'Test',
          precio: 99.99,
        );

        final producto2 = Producto(
          codigoBarras: '123',
          nombre: 'Test',
          precio: 100.0,
        );

        final producto3 = Producto(
          codigoBarras: '123',
          nombre: 'Test',
          precio: 49.5,
        );

        expect(producto1.precioFormateado, '\$99.99');
        expect(producto2.precioFormateado, '\$100.00');
        expect(producto3.precioFormateado, '\$49.50');
      });
    });
  });
}
