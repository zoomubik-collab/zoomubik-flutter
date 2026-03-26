=== Zoomubik Geolocalización ===
Contributors: zoomubik
Tags: geolocation, redirect, provinces, spain, location
Requires at least: 5.0
Tested up to: 6.4
Stable tag: 1.0.0
Requires PHP: 7.4
License: GPLv2 or later
License URI: https://www.gnu.org/licenses/gpl-2.0.html

Redirige automáticamente a los usuarios a su provincia basado en su ubicación GPS o IP.

== Description ==

**Zoomubik Geolocalización** es un plugin que detecta automáticamente la ubicación del usuario y lo redirige a la página específica de su provincia en tu sitio web.

### 🌍 Características principales:

* **Detección automática por GPS**: Utiliza la geolocalización del navegador para obtener la ubicación precisa
* **Fallback por IP**: Si el GPS falla, utiliza la IP para determinar la ubicación
* **27 provincias españolas**: Soporte completo para las principales ciudades de España
* **Modal de confirmación**: Opción de mostrar una ventana de confirmación antes de redirigir
* **Configuración flexible**: Panel de administración completo con múltiples opciones
* **Timeout configurable**: Control total sobre los tiempos de espera
* **Modo debug**: Logs detallados para desarrollo y troubleshooting

### 🗺️ Provincias soportadas:

Madrid, Barcelona, Valencia, Sevilla, Zaragoza, Málaga, Murcia, Palma, Las Palmas, Bilbao, Alicante, Córdoba, Valladolid, Vigo, Gijón, Granada, Vitoria, Oviedo, Santander, Pamplona, Almería, Burgos, Salamanca, Huelva, Logroño, Badajoz, León, Cádiz.

### 🎯 Casos de uso:

* **Sitios inmobiliarios**: Redirigir usuarios a propiedades de su zona
* **Directorios locales**: Mostrar servicios de la provincia del usuario
* **E-commerce local**: Productos y servicios específicos por región
* **Noticias locales**: Contenido relevante por ubicación

### 🔧 Configuración:

El plugin incluye un panel de administración completo donde puedes:

* Activar/desactivar la geolocalización
* Configurar timeouts de GPS
* Habilitar/deshabilitar el modal de confirmación
* Establecer tiempo de auto-redirect
* Activar modo debug
* Ver estadísticas de uso

### 📱 Compatibilidad:

* **Navegadores**: Chrome, Firefox, Safari, Edge
* **Dispositivos**: Desktop, móvil, tablet
* **HTTPS**: Requerido para geolocalización GPS
* **WordPress**: 5.0+
* **PHP**: 7.4+

== Installation ==

### Instalación automática:

1. Ve a `Plugins > Añadir nuevo` en tu panel de WordPress
2. Busca "Zoomubik Geolocalización"
3. Haz clic en "Instalar ahora"
4. Activa el plugin

### Instalación manual:

1. Descarga el archivo ZIP del plugin
2. Ve a `Plugins > Añadir nuevo > Subir plugin`
3. Selecciona el archivo ZIP y haz clic en "Instalar ahora"
4. Activa el plugin

### Configuración:

1. Ve a `Ajustes > Zoomubik Geo`
2. Configura las opciones según tus necesidades
3. Guarda los cambios

== Frequently Asked Questions ==

= ¿Funciona sin HTTPS? =

La geolocalización por GPS requiere HTTPS. Sin HTTPS, el plugin utilizará únicamente la detección por IP.

= ¿Qué pasa si el usuario está fuera de España? =

El plugin detecta automáticamente si el usuario está fuera de España y no realiza ninguna redirección.

= ¿Puedo personalizar las provincias? =

Actualmente el plugin soporta las 27 provincias principales de España. Para personalizar, puedes modificar el código del plugin.

= ¿Afecta al rendimiento del sitio? =

El plugin es muy ligero y solo se ejecuta en la página principal (configurable). El impacto en el rendimiento es mínimo.

= ¿Funciona con caché? =

Sí, el plugin es compatible con sistemas de caché ya que utiliza JavaScript del lado del cliente.

= ¿Puedo ver estadísticas de uso? =

El panel de administración muestra información básica como tu IP actual y provincia detectada. Para estadísticas avanzadas, recomendamos usar Google Analytics.

== Screenshots ==

1. Panel de administración principal
2. Modal de confirmación de redirección
3. Configuración de timeouts y opciones
4. Lista de provincias soportadas

== Changelog ==

= 1.0.0 =
* Lanzamiento inicial
* Detección por GPS y IP
* 27 provincias españolas soportadas
* Panel de administración completo
* Modal de confirmación configurable
* Modo debug
* Shortcode para selector manual

== Upgrade Notice ==

= 1.0.0 =
Primera versión del plugin. Instala para comenzar a usar la geolocalización automática.

== Technical Details ==

### APIs utilizadas:

* **Navigator.geolocation**: Para obtener coordenadas GPS
* **BigDataCloud Reverse Geocoding**: Para convertir coordenadas en ubicaciones
* **IP-API**: Para geolocalización por IP como fallback

### Estructura de URLs:

El plugin redirige a URLs con la estructura: `/provincias/[provincia]/`

Ejemplo: `/provincias/madrid/`, `/provincias/barcelona/`

### Shortcodes:

`[zoomubik_provinces]` - Muestra un selector manual de todas las provincias

### Hooks disponibles:

* `zoomubik_geo_before_redirect` - Se ejecuta antes de la redirección
* `zoomubik_geo_province_detected` - Se ejecuta cuando se detecta una provincia

== Support ==

Para soporte técnico, visita: https://zoomubik.com/soporte

== Privacy Policy ==

Este plugin utiliza servicios de terceros para la geolocalización:

* **BigDataCloud**: Para geocodificación inversa (GPS a ubicación)
* **IP-API**: Para geolocalización por IP

No se almacenan datos de ubicación del usuario en tu servidor. La ubicación se utiliza únicamente para la redirección inicial.