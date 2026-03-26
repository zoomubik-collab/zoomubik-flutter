# Funcionalidades Nativas para iOS

Este documento explica las funcionalidades nativas implementadas para cumplir con los requisitos de Apple App Store.

## Funcionalidades Implementadas

### 1. Compartir (Share Sheet)
- Permite compartir anuncios en redes sociales, mensajes, email, etc.
- Usa el Share Sheet nativo de iOS
- **Archivo**: `src/app/services/native.service.ts` - método `shareContent()`

### 2. Cámara
- Permite tomar fotos directamente desde la app
- Integración con la cámara nativa de iOS
- **Archivo**: `src/app/services/native.service.ts` - método `takePicture()`

### 3. Galería de Fotos
- Permite seleccionar fotos de la galería del dispositivo
- Integración con la librería de fotos nativa de iOS
- **Archivo**: `src/app/services/native.service.ts` - método `pickPhoto()`

### 4. Notificaciones Locales
- Envía notificaciones locales al usuario
- Solicita permisos automáticamente
- **Archivo**: `src/app/services/native.service.ts` - método `sendNotification()`

## Instalación

### 1. Instalar plugins de Capacitor

```bash
npm install @capacitor/share @capacitor/camera @capacitor/local-notifications
npx cap sync ios
```

### 2. Configurar permisos en iOS

Los permisos ya están configurados en `ios/App/App/Info.plist`:
- `NSCameraUsageDescription` - Acceso a cámara
- `NSPhotoLibraryUsageDescription` - Acceso a galería
- `NSUserNotificationUsageDescription` - Notificaciones
- `NSLocationWhenInUseUsageDescription` - Localización

### 3. Usar el servicio en tus componentes

```typescript
import { NativeService } from './services/native.service';

export class MyComponent {
  constructor(private nativeService: NativeService) {}

  // Compartir
  async share() {
    await this.nativeService.shareContent(
      'Título',
      'Descripción',
      'https://zoomubik.com'
    );
  }

  // Tomar foto
  async takePicture() {
    const photo = await this.nativeService.takePicture();
  }

  // Seleccionar foto
  async pickPhoto() {
    const photo = await this.nativeService.pickPhoto();
  }

  // Notificación
  async notify() {
    await this.nativeService.sendNotification(
      'Título',
      'Mensaje',
      5 // segundos
    );
  }
}
```

## Compilación para iOS

```bash
# Build web
npm run build

# Sincronizar con Capacitor
npx cap sync ios

# Abrir Xcode
npx cap open ios
```

En Xcode:
1. Selecciona el scheme "App"
2. Selecciona un dispositivo o simulador
3. Presiona Cmd+R para compilar y ejecutar

## Requisitos de Apple

Estas funcionalidades nativas ayudan a cumplir con los requisitos de Apple:

✅ **Funcionalidad nativa**: Usa APIs nativas de iOS (Share, Camera, Notifications)
✅ **Permisos claros**: Solicita permisos de forma explícita
✅ **Descripciones útiles**: Explica por qué necesita cada permiso
✅ **No es solo WebView**: Integra funcionalidades que van más allá de una web simple

## Notas Importantes

- Los permisos se solicitan automáticamente cuando se usan las funcionalidades
- Las fotos se devuelven en formato Base64 (dataUrl)
- Las notificaciones locales se programan con un delay en segundos
- El servicio maneja errores automáticamente

## Próximas Mejoras

- [ ] Biometría (Face ID / Touch ID)
- [ ] Push Notifications (APNs)
- [ ] Acceso a contactos
- [ ] Almacenamiento local (SQLite)
- [ ] Geolocalización mejorada
