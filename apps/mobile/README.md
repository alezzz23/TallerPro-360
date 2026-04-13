# TallerPro360 Mobile

Cliente Flutter para TallerPro 360.

## Requisitos

- Flutter instalado y disponible en `PATH`
- Android SDK configurado
- Un telefono Android con depuracion USB activa o instalacion manual de APK

## Ejecutar en desarrollo

```bash
flutter pub get
flutter run \
	--dart-define=API_BASE_URL=https://tallerpro-360-production.up.railway.app/api/v1 \
	--dart-define=WS_BASE_URL=wss://tallerpro-360-production.up.railway.app/ws
```

## Generar APK para probar en telefono

El proyecto usa `String.fromEnvironment`, asi que el APK debe compilarse con las URLs del backend y websocket:

```bash
flutter build apk --release \
	--dart-define=API_BASE_URL=https://tallerpro-360-production.up.railway.app/api/v1 \
	--dart-define=WS_BASE_URL=wss://tallerpro-360-production.up.railway.app/ws
```

APK generado:

```bash
build/app/outputs/flutter-apk/app-release.apk
```

## Instalar en el telefono

Con el telefono conectado por USB:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Si prefieres instalarlo manualmente, copia ese APK al telefono y abre el archivo desde el explorador.

## Credenciales demo

- `admin@demo.tallerpro360.com` / `TallerPro360!2026`
- `asesor@demo.tallerpro360.com` / `TallerPro360!2026`
- `tecnico@demo.tallerpro360.com` / `TallerPro360!2026`
- `jefe@demo.tallerpro360.com` / `TallerPro360!2026`

## Notas

- El `AndroidManifest.xml` ya declara permiso de internet, necesario para que el APK release consuma Railway.
- El `build.gradle` Android de momento firma release con la llave debug, suficiente para pruebas internas en dispositivo.
