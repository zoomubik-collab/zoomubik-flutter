# Persistencia de Sesión en WebView - Zoomubik

## Problema

La WebView no mantenía la sesión de WordPress al cerrar la app porque:
1. Las cookies no se persistían entre sesiones
2. No había sincronización entre la sesión web y la app

## Solución Implementada

### 1. Configuración en iOS (AppDelegate.swift)

Se agregó configuración de cookies en el AppDelegate:

```swift
// Configurar cookies y sesión para WebView
let cookieStorage = HTTPCookieStorage.shared
cookieStorage.cookieAcceptPolicy = .always

// Configurar WKWebsiteDataStore para persistencia
if #available(iOS 11.0, *) {
  let dataStore = WKWebsiteDataStore.default()
  dataStore.httpShouldSetCookies = true
  dataStore.httpCookieAcceptPolicy = .always
  dataStore.httpShouldUseCookies = true
}
```

Esto permite que:
- Las cookies HTTP se guarden automáticamente
- La sesión de WordPress persista entre cierres de app
- El navegador web mantenga el estado de login

### 2. Configuración en Flutter (main.dart)

Se agregó:

**User Agent correcto:**
```dart
..setUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15')
```

Esto hace que WordPress reconozca la app como un navegador real.

**Script de sincronización de cookies:**
```javascript
// Guardar cookies en localStorage
if (document.cookie) {
  localStorage.setItem('wp_cookies', document.cookie);
}

// Restaurar cookies si existen
var savedCookies = localStorage.getItem('wp_cookies');
if (savedCookies && !document.cookie.includes('wordpress_logged_in')) {
  document.cookie = savedCookies;
}
```

Esto:
- Guarda las cookies en localStorage como backup
- Las restaura si se pierden
- Verifica que la sesión de WordPress esté activa

### 3. Almacenamiento Seguro del User ID

El user_id se guarda en `FlutterSecureStorage`:

```dart
await _secureStorage.write(key: 'wp_user_id', value: userId);
```

Esto persiste incluso si se cierra la app.

## Flujo de Funcionamiento

```
1. Usuario inicia sesión en WordPress
   ↓
2. WordPress crea cookie de sesión (wordpress_logged_in)
   ↓
3. iOS guarda la cookie automáticamente
   ↓
4. App guarda user_id en almacenamiento seguro
   ↓
5. Usuario cierra la app
   ↓
6. Usuario reabre la app
   ↓
7. iOS restaura las cookies automáticamente
   ↓
8. WebView carga con sesión activa
   ↓
9. App detecta user_id y obtiene token FCM
   ↓
10. Notificaciones funcionan correctamente
```

## Cómo Verificar que Funciona

### En iOS (Xcode)

1. Abre la app
2. Inicia sesión
3. Cierra la app completamente (swipe up)
4. Reabre la app
5. Verifica que NO pida login nuevamente
6. Revisa los logs:
   ```
   ✅ Página cargada: https://www.zoomubik.com
   🔍 User ID desde JS: 123
   ✅ User ID guardado: 123
   🔑 FCM Token: ey...
   ✅ Token guardado en WordPress: 200
   ```

### En WordPress

Verifica que el token FCM se guardó:
```sql
SELECT user_id, meta_value FROM wp_usermeta 
WHERE meta_key = 'fcm_token' 
ORDER BY user_id DESC LIMIT 1;
```

## Requisitos

- iOS 13.0 o superior (ya configurado en Podfile)
- WebKit framework (incluido en iOS)
- WordPress con cookies habilitadas

## Notas Importantes

1. **Cookies HTTP vs HTTPS**
   - Las cookies HTTPS son más seguras
   - Asegúrate de que tu sitio use HTTPS

2. **Política de Cookies**
   - iOS respeta la política de cookies del sitio
   - WordPress debe permitir cookies

3. **Limpieza de Datos**
   - Si el usuario limpia datos de la app, se pierden las cookies
   - Esto es normal y esperado

4. **Debugging**
   - Revisa los logs en Xcode para ver si las cookies se guardan
   - Usa Safari Developer Tools para inspeccionar cookies

## Troubleshooting

### La sesión se pierde al cerrar la app

1. Verifica que iOS esté guardando cookies:
   ```swift
   print(HTTPCookieStorage.shared.cookies ?? "No cookies")
   ```

2. Verifica que WordPress esté enviando cookies:
   - Abre Safari
   - Ve a tu sitio
   - Inicia sesión
   - Cierra Safari
   - Reabre Safari
   - ¿Sigue logueado?

3. Si WordPress no mantiene sesión en Safari, el problema es del servidor, no de la app

### El user_id no se detecta

1. Verifica que el sitio tenga la variable `zoomubik_user_id`
2. Revisa los logs en Xcode
3. Abre la consola del navegador (F12) en tu sitio y verifica que exista

### Las notificaciones no llegan

1. Verifica que el token FCM se guarde (revisa logs)
2. Verifica que el token esté en la base de datos
3. Usa test-notifications.php para enviar una notificación de prueba

## Cambios Realizados

- `ios/Runner/AppDelegate.swift` - Configuración de cookies
- `lib/main.dart` - Script de sincronización y user agent
- `SESION_PERSISTENCIA.md` - Este documento
