# Dulce Moment — Manual del proyecto

## 1. ¿Qué es esta app?

**Dulce Moment** es una app de pedidos para una pastelería, con dos roles:
cliente (arma su pastel, pide y paga) y tienda (gestiona catálogo y da
seguimiento a los pedidos).

## 2. Tecnología usada

**Frontend:** Se usó **Flutter** para construir la aplicación, por ahora
compilada solo para **Android**. Como Flutter es multiplataforma (un mismo
código en Dart), más adelante se podrá compilar también para **iOS** sin
reescribir la lógica de negocio — solo se necesita una Mac con Xcode para
generar ese build.

**Backend: Supabase.** Supabase es una plataforma "Backend as a Service"
construida sobre PostgreSQL. En vez de programar un servidor propio (rutas,
autenticación, base de datos) desde cero, Supabase entrega listos:

- **Auth** — registro/login de usuarios con correo y contraseña (tokens JWT).
- **Base de datos Postgres** — tablas relacionales con relaciones y reglas
  de acceso (Row Level Security) para que cada usuario solo vea lo que le
  corresponde.
- **Realtime** — la app recibe actualizaciones en vivo (por ejemplo, el
  cliente ve el pedido cambiar de estado sin recargar) mediante WebSockets.
- **Storage** (opcional, no usado aún) — para subir imágenes de productos.

La app Flutter se conecta a Supabase con el paquete `supabase_flutter`,
usando una URL de proyecto y una llave pública (`anonKey`); Supabase valida
cada operación contra las políticas de seguridad antes de permitirla.

## 3. ¿Dónde está la query?

Todo el SQL que crea la base de datos vive en:

```
lib/supabase/schema.sql
```

Ese archivo se ejecuta **una sola vez**, pegándolo completo en
**Supabase Dashboard → SQL Editor → Run**. Crea las tablas (`profiles`,
`products`, `order_items`, `orders`, `tracking_events`, `payments`,
`push_alerts`), el trigger que da de alta el perfil al registrarse, y las
políticas de seguridad por rol (cliente/tienda).

Las consultas que la app hace en tiempo real (día a día, no el setup)
están repartidas por función en `lib/services/`:

| Archivo | Qué hace |
|---|---|
| `auth_service.dart` | registro, login, perfil |
| `product_service.dart` | catálogo, stock, alta/edición de productos |
| `order_service.dart` | crear pedido, cambiar estado, historial |
| `payment_service.dart` | validar tarjeta y registrar el pago |
| `alert_service.dart` | notificaciones internas |

La configuración de conexión (URL + anonKey) está en:
```
lib/core/supabase_config.dart
```

## 4. Problema encontrado: el logo no se aplicaba al compilar

**Causa:** en `pubspec.yaml` existía el bloque de configuración
`flutter_launcher_icons:` (que le dice a Flutter qué imagen usar como
ícono), pero el paquete **nunca se agregó como dependencia** — sin el
paquete instalado, ese bloque no hace nada y Android sigue usando el
ícono de Flutter por defecto. Además, `assets/logo.png` es un logotipo
ancho (texto + ícono, 2720×1520 px), y un ícono de app debe ser
**cuadrado y simple** — un banner con texto se ve deformado o ilegible
al reducirse a 48×48 dp en el launcher.

**Arreglado:**
1. Se agregó `flutter_launcher_icons` a `dev_dependencies`.
2. Se creó `assets/app_icon.png` (1024×1024, cuadrado) solo con el ícono del
   pastel, sin texto — el logotipo con texto (`assets/logo.png`) se conserva
   para usarlo dentro de la app (login, splash), no como ícono del launcher.
3. Se configuró `adaptive_icon_background`/`adaptive_icon_foreground` para
   que se vea bien en Android 8+ (íconos adaptables con forma circular,
   squircle, etc. según el fabricante).

**Para aplicar el cambio, corre en tu máquina:**
```bash
flutter pub get
dart run flutter_launcher_icons
```
Esto reescribe automáticamente los archivos en
`android/app/src/main/res/mipmap-*/ic_launcher.png` con tu logo real.
Después, para ver el ícono nuevo en un dispositivo/emulador donde ya
tenías la app instalada, **desinstálala primero** (Android cachea el
ícono anterior si solo reinstalas encima).

## 5. Compilar el APK para pruebas

```bash
flutter clean
flutter pub get
dart run flutter_launcher_icons
flutter build apk --release
```

El instalable queda en:
```
build/app/outputs/flutter-apk/app-release.apk
```

Se comparte por WhatsApp/Bluetooth como cualquier archivo; en el celular que
lo reciba hay que permitir "instalar apps de orígenes desconocidos" la
primera vez.
