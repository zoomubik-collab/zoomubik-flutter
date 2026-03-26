# Configuración de Push Notifications para iOS

## Requisitos

1. **Apple Developer Account** ($99/año)
2. **Firebase Project** (gratuito)
3. **APNs Certificate** de Apple

## Paso 1: Crear APNs Certificate en Apple Developer

1. Ve a [Apple Developer Console](https://developer.apple.com/account)
2. Identifiers → App IDs → Selecciona tu app
3. Capabilities → Habilita "Push Notifications"
4. Certificates, Identifiers & Profiles → Certificates
5. Crea un nuevo "Apple Push Notification service (APNs) SSL Certificate"
6. Descarga el certificado (.cer)
7. Abre con Keychain Access y exporta como .p8 (PKCS#8)

## Paso 2: Configurar Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto
3. Project Settings → Cloud Messaging
4. Sube el certificado APNs (.p8)
5. Ingresa tu Team ID de Apple

## Paso 3: Descargar GoogleService-Info.plist

1. En Firebase Console → Project Settings
2. Descarga `GoogleService-Info.plist`
3. Cópialo a `ios/App/App/GoogleService-Info.plist`

## Paso 4: Instalar Plugin

```bash
npm install @capacitor/push-notifications firebase @angular/fire
npx cap sync ios
```

## Paso 5: Configurar en app.module.ts

```typescript
import { initializeApp } from 'firebase/app';
import { getMessaging } from 'firebase/messaging';

const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_AUTH_DOMAIN",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_STORAGE_BUCKET",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  appId: "YOUR_APP_ID"
};

const app = initializeApp(firebaseConfig);
const messaging = getMessaging(app);
```

## Paso 6: Usar en tu componente

```typescript
import { PushNotificationsService } from './services/push-notifications.service';

export class AppComponent implements OnInit {
  constructor(private pushService: PushNotificationsService) {}

  ngOnInit() {
    // El servicio se inicializa automáticamente
    const token = this.pushService.getPushToken();
    console.log('Push token:', token);
  }
}
```

## Paso 7: Enviar notificaciones desde tu servidor

### Desde Node.js/Express:

```javascript
const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const message = {
  notification: {
    title: 'Nuevo mensaje',
    body: 'Tienes un nuevo mensaje'
  },
  data: {
    type: 'new_message',
    from: 'user123'
  },
  token: pushToken // Token del dispositivo
};

admin.messaging().send(message)
  .then((response) => {
    console.log('Notificación enviada:', response);
  })
  .catch((error) => {
    console.error('Error enviando notificación:', error);
  });
```

### Desde PHP (tu servidor actual):

```php
<?php
require 'vendor/autoload.php';

use Kreait\Firebase\Factory;

$factory = new Factory();
$messaging = $factory->createMessaging();

$message = \Kreait\Firebase\Messaging\CloudMessage::withData([
    'type' => 'new_message',
    'from' => 'user123'
])
->withNotification(\Kreait\Firebase\Messaging\Notification::create()
    ->withTitle('Nuevo mensaje')
    ->withBody('Tienes un nuevo mensaje')
);

$messaging->send($message, $pushToken);
?>
```

## Estructura de datos en notificaciones

```json
{
  "notification": {
    "title": "Título",
    "body": "Cuerpo del mensaje"
  },
  "data": {
    "type": "new_message|new_announcement|new_chat",
    "id": "123",
    "from": "user_id"
  }
}
```

## Tipos de notificaciones recomendadas

- `new_message` - Nuevo mensaje privado
- `new_announcement` - Nuevo anuncio relacionado
- `new_chat` - Nuevo chat
- `announcement_viewed` - Tu anuncio fue visto
- `announcement_contact` - Alguien contactó tu anuncio

## Compilar para iOS

```bash
npm run build
npx cap sync ios
npx cap open ios
```

En Xcode:
1. Selecciona el target "App"
2. Signing & Capabilities → + Capability
3. Agrega "Push Notifications"
4. Agrega "Background Modes" → Habilita "Remote notifications"

## Pruebas

Para probar sin compilar:
1. Usa Firebase Console → Cloud Messaging
2. Envía una notificación de prueba al token del dispositivo

## Troubleshooting

**No recibo notificaciones:**
- Verifica que el APNs certificate sea válido
- Comprueba que el token se guardó correctamente
- Revisa los logs en Firebase Console

**Token no se registra:**
- Verifica permisos en Info.plist
- Comprueba que el plugin esté instalado correctamente
- Revisa la consola de Xcode

**Notificaciones no se muestran:**
- Asegúrate de que la app esté en background
- Verifica que el payload sea correcto
- Comprueba que el dispositivo tenga conexión
