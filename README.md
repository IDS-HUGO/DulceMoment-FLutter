# DulceMoment · Flutter + Supabase

Migración de la app Android nativa (Kotlin/Compose) original a Flutter,
usando **Supabase** (Auth + Postgres + Realtime) en lugar del backend REST
propio + Room local.

## 1. Configurar el proyecto Supabase

1. Crea un proyecto en https://supabase.com.
2. Ve a **SQL Editor** y ejecuta completo el archivo:
   `lib/supabase/schema.sql`
   Esto crea las tablas (`profiles`, `products`, `product_options`, `orders`,
   `order_items`, `tracking_events`, `payments`, `push_alerts`), el trigger
   que crea el `profile` automáticamente al registrarse, las políticas RLS
   y activa Realtime en las tablas necesarias.
3. Ve a **Project Settings > API** y copia `Project URL` y `anon public key`.
4. Pégalos en `lib/core/supabase_config.dart`:

```dart
static const String url = 'https://TU_PROYECTO.supabase.co';
static const String anonKey = 'TU_ANON_KEY';
```

5. (Opcional pero recomendado) En **Authentication > Providers > Email**,
   desactiva "Confirm email" mientras desarrollas, para poder loguearte
   inmediatamente después de registrarte.

## 2. Instalar dependencias y correr

```bash
flutter pub get
flutter run
```

## 3. Estructura del lib/

```
lib/
├── core/
│   └── supabase_config.dart        # URL + anonKey + init de Supabase
├── models/                         # Entidades: AppUser, Product, CakeOrder...
├── services/
│   ├── auth_service.dart           # signUp / signIn / profiles
│   ├── product_service.dart        # catálogo, opciones, stock
│   ├── order_service.dart          # pedidos, tracking, resumen de ventas
│   ├── payment_service.dart        # validación de tarjeta + registro de pago
│   ├── alert_service.dart          # notificaciones internas
│   └── dulce_repository.dart       # fachada que combina todos los servicios
├── domain/
│   └── order_workflow.dart         # reglas de transición de estado del pedido
├── state/                          # ChangeNotifier providers (sesión, catálogo, pedidos, alertas)
├── screens/
│   ├── auth/                       # login, registro
│   ├── customer/                   # catálogo, detalle/personalización, pedidos, pago
│   ├── seller/                     # pedidos, productos, alta/edición, resumen
│   └── root_router.dart            # decide login / cliente / tienda
├── widgets/
│   └── product_card.dart
├── supabase/
│   └── schema.sql                  # ← TODO el SQL de Supabase (tablas + RLS + triggers)
└── main.dart
```

## 4. Notas importantes sobre la migración

- **Autenticación real**: en el original las contraseñas se guardaban en la
  tabla `users` (Room). Aquí se usa `Supabase Auth` (`auth.users` + JWT), que
  es lo correcto; el rol (`customer`/`store`) vive en `public.profiles`,
  vinculado 1:1 por `id` mediante un trigger.
- **Pagos**: el proyecto original delegaba el cobro real a un backend propio
  que hablaba con Stripe/Mercado Pago. Sin ese backend, `payment_service.dart`
  valida la tarjeta localmente (algoritmo de Luhn, como el original) y
  registra el pago directamente en `payments`. Para cobrar de verdad, crea
  una **Supabase Edge Function** que reciba los datos y llame a Stripe con la
  secret key del lado servidor, y sustituye el bloque comentado en
  `payment_service.dart` por `supabase.functions.invoke(...)`.
- **Tiempo real**: los listados de productos y pedidos usan
  `supabase.from(...).stream(...)` (Realtime), reemplazando los `Flow` de
  Room/StateFlow del proyecto Android.
- **Subida de imágenes**: el original subía a Cloudinary vía el backend. Aquí
  se dejó el campo `imageUrl` como texto libre; si quieres subir archivos
  desde el dispositivo, lo más directo en Supabase es usar **Supabase
  Storage** (`supabase.storage.from('bucket').upload(...)`) y guardar la URL
  pública resultante en `products.image_url`.
