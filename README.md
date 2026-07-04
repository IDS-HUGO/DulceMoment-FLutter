# DulceMoment · Flutter + Supabase

Dulce Moment es una aplicación móvil de pastelería (cliente y administrador/tienda) desarrollada en **Flutter**, utilizando **Supabase** (Auth + Postgres + Realtime) como backend y **Cloudinary** para el almacenamiento de imágenes.

## 1. Características Principales

*   **Roles Integrados:** Un mismo código maneja tanto la vista del cliente (catálogo, carrito, pago, seguimiento) como la del administrador/tienda (gestión de productos, recepción y avance de pedidos).
*   **Base de Datos en Tiempo Real:** Todos los pedidos y estados de catálogo se reflejan instantáneamente en los dispositivos conectados gracias a Supabase Realtime.
*   **Diseño Premium UI/UX:** Interfaz moderna con animaciones fluidas, gradientes dinámicos y navegación responsiva.

## 2. Aclaraciones Importantes del Proyecto (Manual)

### 💳 Pasarela de Pago Simulada
El sistema de pago incluido en esta aplicación está **SIMULADO** por motivos académicos/demostrativos. 
*   **¿Qué hace?** Valida localmente que el número de tarjeta ingresado sea un formato matemático válido (utilizando el Algoritmo de Luhn), que la fecha no esté expirada y que el CVC tenga longitud correcta.
*   **¿Qué NO hace?** No realiza cobros reales a bancos ni contacta a pasarelas como Stripe o PayPal. Al "aprobarse" el pago localmente, simplemente se registra la orden como "pagada" en Supabase.
*   *Para llevar esto a producción*, se debe integrar un SDK de pagos o una Supabase Edge Function que procese tokens reales de tarjeta.

### 🖼️ Subida de Imágenes con Cloudinary
Para la creación de productos desde la cuenta "Tienda", la aplicación integra el plugin `image_picker`. 
*   Al seleccionar una foto de la galería o tomarla con la cámara, la imagen se envía directamente a la API REST de **Cloudinary** firmando la petición en el dispositivo con SHA1 para mayor seguridad.
*   Cloudinary devuelve una URL pública y segura (`secure_url`) que se guarda en la base de datos de Supabase.

## 3. Configuración del Proyecto (Backend)

1.  Crea un proyecto en https://supabase.com.
2.  Ve a **SQL Editor** y ejecuta completo el archivo: `lib/supabase/schema.sql` (Esto crea tablas, triggers y políticas RLS).
3.  Ve a **Project Settings > API** y reemplaza los valores de `Project URL` y `anon public key` en `lib/core/supabase_config.dart`.
4.  En **Authentication > Providers > Email**, *apaga* "Confirm email" para evitar el límite de correos durante tus pruebas.

## 4. Instalación y Ejecución

```bash
# Obtener dependencias (incluye supabase, provider, image_picker, http, crypto)
flutter pub get

# (Opcional) Generar los íconos de la app si cambiaste el logo
dart run flutter_launcher_icons

# Compilar para Android (APK Release)
flutter clean
flutter build apk --release
```

### Configuración para Release (Android)
El proyecto ya cuenta con la configuración estricta para compilarse en Release en Android (`flutter build apk --release`):
*   **Permisos de Internet y Cámara** incluidos en `android/app/src/main/AndroidManifest.xml`.
*   **Network Security Config** habilitado para permitir conexiones HTTPS hacia `supabase.co`.
*   **Reglas ProGuard (`proguard-rules.pro`)** activadas para evitar que el compilador R8 elimine las clases necesarias para que Supabase funcione correctamente.

El APK resultante se encontrará en: `build/app/outputs/flutter-apk/app-release.apk`
