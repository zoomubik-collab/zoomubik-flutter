# 📦 Instalación del Plugin Zoomubik Geolocalización

## 🚀 Instalación Rápida

### Método 1: Subir carpeta completa
1. **Comprimir la carpeta** `zoomubik-geolocation-plugin` en un ZIP
2. **Ir a WordPress Admin** → Plugins → Añadir nuevo → Subir plugin
3. **Seleccionar el ZIP** y hacer clic en "Instalar ahora"
4. **Activar el plugin**

### Método 2: FTP/cPanel
1. **Subir la carpeta** `zoomubik-geolocation-plugin` a `/wp-content/plugins/`
2. **Ir a WordPress Admin** → Plugins
3. **Activar** "Zoomubik Geolocalización"

## ⚙️ Configuración

### 1. Acceder a la configuración
- **WordPress Admin** → Ajustes → **Zoomubik Geo**

### 2. Configuración recomendada para producción
```
✅ Habilitar Geolocalización: SÍ
✅ Mostrar Modal de Confirmación: SÍ  
⏱️ Timeout GPS: 8000ms (8 segundos)
⏱️ Auto-redirect: 5000ms (5 segundos)
❌ Habilitar en todas las páginas: NO (solo página principal)
❌ Modo Debug: NO (solo para desarrollo)
```

### 3. Verificar funcionamiento
1. **Abrir tu sitio** en modo incógnito
2. **Permitir ubicación** cuando aparezca el popup del navegador
3. **Verificar redirección** a tu provincia

## 🧪 Testing

### Probar en diferentes ubicaciones
```javascript
// Simular ubicación en consola del navegador (F12)
navigator.geolocation.getCurrentPosition = function(success) {
    success({
        coords: {
            latitude: 40.4168,  // Madrid
            longitude: -3.7038
        }
    });
};
```

### Coordenadas de prueba
- **Madrid**: 40.4168, -3.7038
- **Barcelona**: 41.3851, 2.1734
- **Valencia**: 39.4699, -0.3763
- **Sevilla**: 37.3891, -5.9845

## 🔧 Personalización

### Cambiar timeout
```php
// En el admin: Ajustes → Zoomubik Geo → Timeout GPS
// O directamente en la base de datos:
update_option('zoomubik_geo_timeout', 10000); // 10 segundos
```

### Deshabilitar modal
```php
// En el admin: Ajustes → Zoomubik Geo → Mostrar Modal de Confirmación: NO
// O directamente:
update_option('zoomubik_geo_show_modal', false);
```

### Agregar nueva provincia
```php
// Editar zoomubik-geolocation.php línea ~150
$provinces = array(
    // ... provincias existentes
    'nueva_ciudad' => 'provincias/nueva-ciudad',
);
```

## 📊 Monitoreo

### Ver logs en navegador
1. **Activar modo debug** en la configuración
2. **Abrir DevTools** (F12) → Console
3. **Recargar la página** y ver logs que empiecen con "🌍"

### Verificar IP y provincia detectada
- **WordPress Admin** → Ajustes → **Zoomubik Geo** → Ver estadísticas

## 🐛 Troubleshooting

### Plugin no funciona
1. **Verificar HTTPS**: La geolocalización GPS requiere HTTPS
2. **Comprobar JavaScript**: Abrir DevTools y buscar errores
3. **Verificar permisos**: El usuario debe permitir ubicación

### Redirige a provincia incorrecta
1. **Activar modo debug** y revisar logs
2. **Verificar coordenadas** reales con Google Maps
3. **Probar desde exterior** para mejor señal GPS

### No aparece el modal
1. **Verificar configuración**: "Mostrar Modal de Confirmación" debe estar activado
2. **Comprobar CSS**: Posibles conflictos con el tema
3. **Revisar JavaScript**: Errores en consola pueden bloquear el modal

## 🔒 Seguridad y Privacidad

### APIs utilizadas
- **BigDataCloud**: Geocodificación inversa (HTTPS)
- **IP-API**: Geolocalización por IP (HTTP/HTTPS)

### Datos almacenados
- **Ningún dato de ubicación** se guarda en tu servidor
- **Solo configuración** del plugin en wp_options
- **SessionStorage**: Para evitar múltiples redirecciones (se borra al cerrar navegador)

## 📱 Compatibilidad

### Navegadores soportados
- ✅ **Chrome** 50+
- ✅ **Firefox** 55+
- ✅ **Safari** 10+
- ✅ **Edge** 79+
- ❌ **Internet Explorer** (no soportado)

### Dispositivos
- ✅ **Desktop** (Windows, Mac, Linux)
- ✅ **Móvil** (Android, iOS)
- ✅ **Tablet** (Android, iPad)

## 🚀 Optimización

### Para sitios con mucho tráfico
```php
// Reducir timeout para carga más rápida
update_option('zoomubik_geo_timeout', 5000); // 5 segundos

// Deshabilitar modal para redirección directa
update_option('zoomubik_geo_show_modal', false);

// Reducir auto-redirect
update_option('zoomubik_geo_auto_redirect', 3000); // 3 segundos
```

### Caché y CDN
- **Compatible** con todos los sistemas de caché
- **JavaScript del lado cliente**: No afecta al caché del servidor
- **CDN friendly**: Funciona con Cloudflare, MaxCDN, etc.

## 📞 Soporte

### Información para soporte
Si necesitas ayuda, proporciona:
1. **URL del sitio**
2. **Versión de WordPress**
3. **Navegador y versión**
4. **Ubicación real vs detectada**
5. **Logs de la consola** (con modo debug activado)

### Logs útiles
```javascript
// En consola del navegador (F12):
console.log('Ubicación real:', navigator.geolocation);
console.log('Configuración plugin:', window.zoomubik_geo_config);
```

---

## ✅ Checklist de Instalación

- [ ] Plugin subido y activado
- [ ] Configuración básica completada
- [ ] HTTPS habilitado en el sitio
- [ ] Probado en modo incógnito
- [ ] Modal aparece correctamente
- [ ] Redirección funciona a provincia correcta
- [ ] Modo debug desactivado para producción

**¡El plugin está listo para usar!** 🎉