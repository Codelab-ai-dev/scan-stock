# Análisis Completo del Proyecto ScanStock

> **Fecha de análisis**: Enero 2026
> **Versión del proyecto**: Post-commit `d114adb`

---

## Resumen Ejecutivo

**ScanStock** es una solución de **gestión de inventario multi-tenant** compuesta por dos aplicaciones:

| Aplicación | Tecnología | Líneas de código | Propósito |
|------------|------------|------------------|-----------|
| App Móvil | Flutter/Dart | ~13,500 | Escaneo, ventas, reportes |
| Panel Admin | Next.js/React | ~7,600 | Gestión de negocios y usuarios |

**Stack tecnológico**: Supabase (Auth + DB), Flutter (Mobile), Next.js (Web), Tailwind CSS

---

## Estructura del Proyecto

```
/scan-app/
├── scanstock/                    # App móvil (Flutter)
│   ├── lib/
│   │   ├── config/               # Configuraciones
│   │   ├── models/               # Entidades de datos
│   │   ├── providers/            # State Management (Provider)
│   │   ├── screens/              # Pantallas (Auth, Admin, User, Sales, Profile)
│   │   ├── services/             # Servicios (Auth, Product, Report)
│   │   ├── widgets/              # Componentes reutilizables
│   │   └── main.dart             # Punto de entrada
│   └── pubspec.yaml              # Dependencias Flutter
│
└── scanstock-admin/              # Panel administrativo (Next.js)
    ├── src/
    │   ├── app/                  # Pages y API routes
    │   │   ├── (dashboard)/      # Rutas protegidas
    │   │   ├── api/              # Endpoints REST
    │   │   └── login/            # Landing page login
    │   ├── components/           # Componentes React
    │   ├── hooks/                # Custom hooks
    │   ├── lib/                  # Utilidades y clientes
    │   └── middleware.ts         # Middleware de autenticación
    └── package.json              # Dependencias Node.js
```

---

## Funcionalidades Actuales

### App Móvil (Por Rol)

#### Para ADMIN:
- Dashboard con estadísticas de ventas
- Gestión de productos (CRUD completo)
- Gestión de usuarios
- Historial de ventas completo
- Generación de reportes PDF/Excel
- Scanner de códigos de barras

#### Para USER:
- Scanner de códigos de barras
- Nueva venta (carrito interactivo)
- Historial de ventas personal
- Perfil de usuario

### Panel Admin (Super-admin)
- Dashboard con estadísticas globales
- CRUD de negocios multi-tenant
- Gestión de usuarios por negocio
- Configuración de módulos
- Upload de APK a Bunny CDN
- Página pública de descarga

---

## Modelos de Datos

### Entidades Principales (Supabase)

```sql
-- Profile (Usuario)
- id (UUID)
- email (string)
- full_name (string, nullable)
- role ('admin' | 'user')
- business_id (UUID, nullable)
- is_super_admin (boolean)
- created_at (timestamp)

-- Producto
- id (UUID)
- codigo_barras (string) - UNIQUE
- nombre (string)
- descripcion (string, nullable)
- precio (decimal)
- imagen_url (string, nullable)
- stock_cantidad (integer)
- stock_minimo (integer)
- business_id (UUID)
- created_by (UUID)
- created_at (timestamp)
- updated_at (timestamp)

-- Venta
- id (UUID)
- total (decimal)
- cantidad_items (integer)
- business_id (UUID)
- created_by (UUID)
- created_at (timestamp)

-- VentaItem
- id (UUID)
- venta_id (UUID)
- producto_id (UUID)
- producto_nombre (string)
- producto_codigo_barras (string)
- precio_unitario (decimal)
- cantidad (integer)
- subtotal (decimal)

-- Business
- id (UUID)
- name (string)
- slug (string) - UNIQUE
- logo_url (string, nullable)
- is_active (boolean)
- created_at (timestamp)
- updated_at (timestamp)

-- AppSettings
- id (UUID)
- apk_url (string, nullable)
- apk_version (string, nullable)
- apk_size (string, nullable)
- apk_filename (string, nullable)
- updated_at (timestamp)
```

---

## APIs y Endpoints

### Next.js API Routes

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/auth/login` | Login de usuarios |
| GET | `/api/businesses` | Listar negocios |
| POST | `/api/businesses` | Crear negocio |
| GET | `/api/businesses/[id]` | Detalle de negocio |
| PATCH | `/api/businesses/[id]` | Actualizar negocio |
| DELETE | `/api/businesses/[id]` | Eliminar negocio |
| GET | `/api/businesses/[id]/users` | Listar usuarios |
| POST | `/api/businesses/[id]/users` | Crear usuario |
| PATCH | `/api/businesses/[id]/users/[userId]` | Actualizar usuario |
| DELETE | `/api/businesses/[id]/users/[userId]` | Eliminar usuario |
| GET | `/api/upload-apk` | Verificar configuración APK |
| POST | `/api/upload-apk` | Subir APK |
| DELETE | `/api/upload-apk` | Eliminar APK |

---

## Tecnologías Utilizadas

### App Móvil (Flutter)

| Categoría | Dependencias |
|-----------|--------------|
| Core | Flutter 3.10+, Dart 3.10+ |
| Estado | provider ^6.1.2 |
| Backend | supabase_flutter ^2.8.0 |
| Escaneo | mobile_scanner ^6.0.2 |
| Reportes | pdf ^3.11.1, excel ^4.0.6 |
| UI | fl_chart ^0.69.0, cached_network_image ^3.4.1 |
| Utils | intl ^0.20.1, share_plus ^10.1.3 |

### Panel Admin (Next.js)

| Categoría | Dependencias |
|-----------|--------------|
| Framework | next ^15.1.3, react ^19.0.0 |
| Backend | @supabase/supabase-js ^2.47.10 |
| Estilos | tailwindcss ^3.4.17 |
| UI | lucide-react ^0.469.0, @radix-ui |
| Testing | vitest ^2.1.8, @testing-library/react |

---

## Seguridad Implementada

### Flutter
- Super-admin bloqueado en app móvil
- Validación de business_id obligatorio
- RoleGuard en router
- Sanitización de entrada

### Next.js
- Middleware de sesión SSR
- Verificación super-admin en APIs
- Validación y sanitización de datos
- Headers de seguridad

### Supabase
- Row-level security (RLS)
- Auth OAuth2 con JWT
- Refresh automático de tokens

---

# ANÁLISIS DE GAPS Y OPORTUNIDADES

---

## 🔴 Lo que HACE FALTA (Gaps Críticos)

### 1. Modo Offline

**Problema**: El sistema depende 100% de conectividad.

**Falta**:
- Caché local de productos
- Cola de sincronización para ventas offline
- Fallback cuando Supabase no está disponible

**Impacto**: Crítico para negocios en zonas con conexión intermitente.

---

### 2. Testing Insuficiente

**Estado actual**: Setup de Vitest existe pero cobertura es mínima.

**Falta**:
- Tests E2E
- Tests unitarios completos en Flutter
- Tests de integración de APIs
- Coverage reports

**Archivos de test existentes**:
```
scanstock-admin/src/__tests__/
├── api-client.test.ts
├── validation.test.ts
├── auth.test.ts
├── components/
└── hooks/
```

---

### 3. Rate Limiting y Seguridad API

**APIs expuestas sin protección**:
```typescript
POST /api/businesses
POST /api/upload-apk
```

**Falta**:
- Throttling de requests
- Captcha en endpoints sensibles
- IP blocking
- Abuse detection

---

### 4. Logging y Monitoreo

**Falta**:
- Sentry/Crashlytics para errores
- Analytics de uso (Mixpanel, Amplitude)
- Métricas de performance
- Audit trail de acciones críticas
- Alertas de salud del sistema

---

### 5. Notificaciones

**Falta**:
- Push notifications
- Alertas de stock bajo
- Notificaciones de ventas importantes
- Recordatorios programados

---

### 6. Backup y Recuperación

**Falta**:
- Estrategia de backup documentada
- Exports programados automáticos
- Plan de disaster recovery
- Versionado de datos críticos

---

## 🟡 Lo que MEJORARÍA

### 1. Dashboard Analytics Limitado

**Estado actual**: Solo muestra conteos básicos.

**Mejoras sugeridas**:
- Gráficas de tendencias temporales
- Comparativas periódicas (semana vs semana)
- Productos más/menos vendidos
- Horas pico de venta
- Margen de ganancia por producto

---

### 2. Gestión de Inventario Básica

**Falta**:
- Categorías de productos
- Manejo de lotes y fechas de caducidad
- Códigos de ubicación (warehouse/estante)
- Historial de cambios de precio
- Productos compuestos (kits)

---

### 3. Sistema de Roles Limitado

**Estado actual**: Solo `admin`, `user`, `super_admin`.

**Mejoras sugeridas**:
- Permisos granulares por acción
- Roles personalizables por negocio
- Restricción por módulo específico
- Auditoría de permisos

---

### 4. Reportes Básicos

**Estado actual**: PDF/Excel estáticos manuales.

**Mejoras sugeridas**:
- Programación de reportes automáticos
- Envío por email
- Dashboards personalizables
- Exportación a Google Sheets

---

## 🟢 DIFERENCIADORES PROPUESTOS

### 1. IA para Predicción de Stock

```dart
// Ejemplo conceptual
class StockPredictionService {
  Future<StockPrediction> predictStockNeeds(String productId) {
    // Analiza histórico de ventas
    // Identifica patrones estacionales
    // Predice cuándo se agotará
    // Sugiere cantidad óptima a reponer
  }
}
```

**Valor diferenciador**: Ningún competidor pequeño ofrece predicción de inventario. Reduce pérdidas por falta de stock y sobreinventario.

---

### 2. Reconocimiento de Productos por Imagen

**Funcionalidades**:
- Escanear producto visualmente (no solo barcode)
- Crear producto desde foto (OCR del empaque)
- Buscar producto similar en catálogo
- Detección de precios en etiquetas

**Tecnología sugerida**: Google ML Kit o TensorFlow Lite

---

### 3. Sincronización Offline-First

```dart
class OfflineSyncManager {
  LocalQueue pendingOperations;

  Future<void> recordSale(Sale sale) async {
    // Guarda localmente primero
    await localDb.insert(sale);
    pendingOperations.add(SyncOperation.insert(sale));

    // Intenta sincronizar
    if (await hasConnectivity()) {
      await syncPendingOperations();
    }
  }

  Future<void> syncWhenOnline() {
    // Detecta conectividad
    // Sincroniza cola de operaciones
    // Resuelve conflictos automáticamente
  }
}
```

**Valor diferenciador**: Crítico para negocios en zonas con mala conexión. La mayoría de competidores fallan aquí.

---

### 4. Alertas Inteligentes

**Tipos de alertas**:
- Stock bajo → notificación push inmediata
- Producto sin vender hace X días → sugerencia de promoción
- Venta inusualmente alta → posible error de cantidad
- Margen de ganancia por debajo del umbral
- Producto próximo a vencer

**Canales**: Push, Email, WhatsApp Business

---

### 5. Gamificación para Vendedores

```typescript
interface VendedorStats {
  ventasHoy: number;
  ventasSemana: number;
  rachaVentas: number;      // Días consecutivos con ventas
  ranking: number;          // Posición en leaderboard
  badges: Badge[];          // Logros desbloqueados
  puntosAcumulados: number; // Puntos canjeables
}

interface Badge {
  id: string;
  nombre: string;           // "Primera venta", "100 ventas", "Rey del mes"
  icono: string;
  fechaObtenido: Date;
}
```

**Elementos**:
- Leaderboard de ventas por período
- Badges por logros específicos
- Metas diarias/semanales configurables
- Puntos canjeables por beneficios
- Rachas y multiplicadores

---

### 6. Integraciones con Ecosistema

| Integración | Beneficio |
|-------------|-----------|
| **Facturación electrónica** | AFIP (Argentina), SAT (México), SUNAT (Perú) |
| **WhatsApp Business** | Notificar clientes de promociones/pedidos |
| **Marketplaces** | Sync inventario con Mercado Libre, Amazon |
| **Contabilidad** | QuickBooks, Contpaqi, integración contable |
| **Pagos** | Mercado Pago, Stripe para cobros |

---

### 7. PWA del Admin + App Desktop

```
scanstock-admin/     → PWA instalable en cualquier dispositivo
scanstock-desktop/   → Electron app para caja registradora
```

**Beneficios**:
- Admin accesible sin internet (PWA cached)
- App de escritorio para punto de venta fijo
- Soporte para impresoras de tickets
- Integración con cajón de dinero

---

### 8. Comandos de Voz

```dart
class VoiceCommandService {
  void startListening() {
    speechRecognizer.listen((transcript) {
      final command = parseCommand(transcript);

      switch (command.intent) {
        case 'add_to_cart':
          // "Agregar 5 coca colas"
          cart.add(command.product, command.quantity);
          break;
        case 'check_stock':
          // "Cuántas tengo de arroz"
          showStock(command.product);
          break;
        case 'complete_sale':
          // "Cobrar"
          completeSale();
          break;
      }
    });
  }
}
```

**Valor**: Manos libres mientras el vendedor manipula productos físicos.

---

### 9. Insights de Negocio Automáticos

**Ejemplos de insights**:
- "Tus ventas bajaron 15% vs semana pasada"
- "El producto X tiene mejor margen que Y, considera promocionarlo"
- "Horario sugerido para promociones: 2-4pm (mayor tráfico)"
- "Clientes compran frecuentemente A con B, considera bundle"
- Comparativa anónima con negocios similares del rubro

---

### 10. Multi-almacén con Transferencias

```sql
-- Estructura para múltiples ubicaciones
CREATE TABLE warehouses (
  id UUID PRIMARY KEY,
  business_id UUID REFERENCES businesses(id),
  name VARCHAR(100),
  address TEXT,
  is_primary BOOLEAN DEFAULT false
);

CREATE TABLE warehouse_stock (
  warehouse_id UUID REFERENCES warehouses(id),
  product_id UUID REFERENCES products(id),
  quantity INTEGER,
  PRIMARY KEY (warehouse_id, product_id)
);

CREATE TABLE transfers (
  id UUID PRIMARY KEY,
  from_warehouse UUID REFERENCES warehouses(id),
  to_warehouse UUID REFERENCES warehouses(id),
  product_id UUID REFERENCES products(id),
  quantity INTEGER,
  status VARCHAR(20), -- 'pending', 'in_transit', 'completed'
  created_at TIMESTAMP
);
```

**Valor**: Escala con el negocio cuando abre múltiples sucursales.

---

## Matriz de Priorización

| Prioridad | Feature | Esfuerzo | Impacto | Diferenciación |
|-----------|---------|----------|---------|----------------|
| 🔴 **Alta** | Modo Offline | Alto | Crítico | Media |
| 🔴 **Alta** | Alertas de Stock | Medio | Alto | Media |
| 🔴 **Alta** | Tests y Monitoreo | Medio | Alto | Baja |
| 🟡 **Media** | IA Predicción Stock | Alto | Alto | **Alta** |
| 🟡 **Media** | Categorías Productos | Bajo | Medio | Baja |
| 🟡 **Media** | Dashboard Mejorado | Medio | Alto | Media |
| 🟡 **Media** | Integraciones Facturación | Alto | Alto | Media |
| 🟢 **Baja** | Gamificación | Medio | Medio | **Alta** |
| 🟢 **Baja** | Comandos de Voz | Alto | Medio | **Alta** |
| 🟢 **Baja** | Multi-almacén | Alto | Medio | Media |

---

## Roadmap Sugerido

### Fase 1: Estabilización (1-2 meses)
- [ ] Implementar tests unitarios y E2E
- [ ] Agregar logging y monitoreo (Sentry)
- [ ] Implementar rate limiting en APIs
- [ ] Documentar APIs existentes

### Fase 2: Core Features (2-3 meses)
- [ ] Sistema de categorías de productos
- [ ] Alertas de stock bajo (push notifications)
- [ ] Dashboard mejorado con gráficas
- [ ] Modo offline básico (cache de productos)

### Fase 3: Diferenciación (3-4 meses)
- [ ] Sincronización offline-first completa
- [ ] IA para predicción de stock (MVP)
- [ ] Integración con facturación electrónica
- [ ] Insights automáticos de negocio

### Fase 4: Escala (4-6 meses)
- [ ] Multi-almacén con transferencias
- [ ] Gamificación para vendedores
- [ ] Integraciones con marketplaces
- [ ] PWA y app desktop

---

## Conclusión

**El proyecto tiene una base sólida** con arquitectura limpia, stack moderno y separación clara de responsabilidades. Los gaps principales son operacionales (offline, monitoreo, tests).

**Para diferenciarse** en el mercado de gestión de inventario, se recomienda enfocarse en:

1. **Offline-first** - La mayoría de competidores fallan aquí
2. **IA simple pero útil** - Predicciones de stock, insights automáticos
3. **Integraciones locales** - Facturación electrónica del país objetivo

El mercado de POS/inventario está saturado de soluciones genéricas. La oportunidad está en resolver problemas específicos que los grandes players ignoran: conectividad intermitente, predicción accesible, y experiencia de usuario superior.

---

*Documento generado como parte del análisis técnico del proyecto ScanStock.*
