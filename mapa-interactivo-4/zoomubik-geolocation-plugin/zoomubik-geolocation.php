<?php
/**
 * Plugin Name: Zoomubik Geolocalización
 * Plugin URI: https://zoomubik.com
 * Description: Redirige automáticamente a los usuarios a su provincia basado en su ubicación GPS o IP
 * Version: 1.0.0
 * Author: Zoomubik
 * License: GPL v2 or later
 * Text Domain: zoomubik-geo
 */

// Evitar acceso directo
if (!defined('ABSPATH')) {
    exit;
}

// Definir constantes del plugin
define('ZOOMUBIK_GEO_VERSION', '1.0.0');
define('ZOOMUBIK_GEO_PLUGIN_URL', plugin_dir_url(__FILE__));
define('ZOOMUBIK_GEO_PLUGIN_PATH', plugin_dir_path(__FILE__));

class ZoomubikGeolocation {
    
    public function __construct() {
        add_action('init', array($this, 'init'));
        add_action('wp_enqueue_scripts', array($this, 'enqueue_scripts'));
        add_action('wp_head', array($this, 'add_geolocation_meta'));
        add_action('admin_menu', array($this, 'add_admin_menu'));
        add_action('admin_init', array($this, 'admin_init'));
        
        // Hook de activación
        register_activation_hook(__FILE__, array($this, 'activate'));
        register_deactivation_hook(__FILE__, array($this, 'deactivate'));
    }
    
    public function init() {
        // Cargar textdomain para traducciones
        load_plugin_textdomain('zoomubik-geo', false, dirname(plugin_basename(__FILE__)) . '/languages');
    }
    
    public function enqueue_scripts() {
        // Solo cargar en la página principal o si está habilitado globalmente
        $enable_global = get_option('zoomubik_geo_enable_global', false);
        
        if (is_home() || is_front_page() || $enable_global) {
            wp_enqueue_script(
                'zoomubik-geolocation',
                ZOOMUBIK_GEO_PLUGIN_URL . 'assets/geolocation-redirect.js',
                array(),
                ZOOMUBIK_GEO_VERSION,
                true
            );
            
            // Asegurar codificación UTF-8
            wp_script_add_data('zoomubik-geolocation', 'charset', 'UTF-8');
            
            // Pasar configuración a JavaScript
            $config = array(
                'ajax_url' => admin_url('admin-ajax.php'),
                'nonce' => wp_create_nonce('zoomubik_geo_nonce'),
                'debug' => get_option('zoomubik_geo_debug', false),
                'timeout' => get_option('zoomubik_geo_timeout', 10000),
                'show_modal' => get_option('zoomubik_geo_show_modal', true),
                'auto_redirect_time' => 0,
                'enabled' => get_option('zoomubik_geo_enabled', true),
                'enable_global' => get_option('zoomubik_geo_enable_global', false)
            );
            
            wp_localize_script('zoomubik-geolocation', 'zoomubik_geo_config', $config);
        }
    }
    
    public function add_geolocation_meta() {
        if (get_option('zoomubik_geo_enabled', true)) {
            echo '<meta name="zoomubik-geolocation" content="enabled">' . "\n";
            echo '<meta name="zoomubik-geo-version" content="' . ZOOMUBIK_GEO_VERSION . '">' . "\n";
            echo '<meta charset="UTF-8">' . "\n";
        }
    }
    
    /**
     * Función para obtener la provincia basada en IP (fallback)
     */
    public static function get_user_province_by_ip() {
        $ip = self::get_user_ip();
        
        // Usar servicio gratuito de geolocalización por IP
        $response = wp_remote_get("http://ip-api.com/json/{$ip}?lang=es", array(
            'timeout' => 5,
            'user-agent' => 'Zoomubik Geolocation Plugin'
        ));
        
        if (is_wp_error($response)) {
            return null;
        }
        
        $body = wp_remote_retrieve_body($response);
        $data = json_decode($body, true);
        
        if ($data && $data['status'] === 'success' && $data['countryCode'] === 'ES') {
            return self::normalize_province_name($data['city'] ?? $data['regionName'] ?? '');
        }
        
        return null;
    }
    
    /**
     * Obtener IP real del usuario
     */
    private static function get_user_ip() {
        $ip_keys = array(
            'HTTP_CF_CONNECTING_IP',     // Cloudflare
            'HTTP_CLIENT_IP',
            'HTTP_X_FORWARDED_FOR',
            'HTTP_X_FORWARDED',
            'HTTP_X_CLUSTER_CLIENT_IP',
            'HTTP_FORWARDED_FOR',
            'HTTP_FORWARDED',
            'REMOTE_ADDR'
        );
        
        foreach ($ip_keys as $key) {
            if (array_key_exists($key, $_SERVER) === true) {
                foreach (explode(',', $_SERVER[$key]) as $ip) {
                    $ip = trim($ip);
                    if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE) !== false) {
                        return $ip;
                    }
                }
            }
        }
        
        return $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
    }
    
    /**
     * Normalizar nombres de provincia
     */
    private static function normalize_province_name($name) {
        $provinces = array(
            'madrid' => 'provincias/madrid',
            'barcelona' => 'provincias/barcelona',
            'valencia' => 'provincias/valencia',
            'sevilla' => 'provincias/sevilla',
            'seville' => 'provincias/sevilla',
            'zaragoza' => 'provincias/zaragoza',
            'málaga' => 'provincias/malaga',
            'malaga' => 'provincias/malaga',
            'murcia' => 'provincias/murcia',
            'palma' => 'provincias/palma',
            'las palmas' => 'provincias/las-palmas',
            'bilbao' => 'provincias/bilbao',
            'alicante' => 'provincias/alicante',
            'córdoba' => 'provincias/cordoba',
            'cordoba' => 'provincias/cordoba',
            'valladolid' => 'provincias/valladolid',
            'vigo' => 'provincias/vigo',
            'gijón' => 'provincias/gijon',
            'gijon' => 'provincias/gijon',
            'granada' => 'provincias/granada',
            'vitoria' => 'provincias/vitoria',
            'oviedo' => 'provincias/oviedo',
            'santander' => 'provincias/santander',
            'pamplona' => 'provincias/pamplona',
            'almería' => 'provincias/almeria',
            'almeria' => 'provincias/almeria',
            'burgos' => 'provincias/burgos',
            'salamanca' => 'provincias/salamanca',
            'huelva' => 'provincias/huelva',
            'logroño' => 'provincias/logrono',
            'logrono' => 'provincias/logrono',
            'badajoz' => 'provincias/badajoz',
            'león' => 'provincias/leon',
            'leon' => 'provincias/leon',
            'cádiz' => 'provincias/cadiz',
            'cadiz' => 'provincias/cadiz',
        );
        
        $name = strtolower(trim($name));
        
        // Buscar coincidencia exacta
        if (isset($provinces[$name])) {
            return $provinces[$name];
        }
        
        // Buscar coincidencia parcial
        foreach ($provinces as $key => $value) {
            if (strpos($name, $key) !== false || strpos($key, $name) !== false) {
                return $value;
            }
        }
        
        return null;
    }
    
    /**
     * Agregar menú de administración
     */
    public function add_admin_menu() {
        add_options_page(
            'Zoomubik Geolocalización',
            'Zoomubik Geo',
            'manage_options',
            'zoomubik-geo',
            array($this, 'admin_page')
        );
    }
    
    /**
     * Inicializar configuración de admin
     */
    public function admin_init() {
        register_setting('zoomubik_geo_settings', 'zoomubik_geo_enabled');
        register_setting('zoomubik_geo_settings', 'zoomubik_geo_debug');
        register_setting('zoomubik_geo_settings', 'zoomubik_geo_timeout');
        register_setting('zoomubik_geo_settings', 'zoomubik_geo_show_modal');
        register_setting('zoomubik_geo_settings', 'zoomubik_geo_auto_redirect');
        register_setting('zoomubik_geo_settings', 'zoomubik_geo_enable_global');
    }
    
    /**
     * Página de administración
     */
    public function admin_page() {
        ?>
        <div class="wrap">
            <h1>🌍 Zoomubik Geolocalización</h1>
            <p>Configuración del sistema de redirección automática por ubicación.</p>
            
            <form method="post" action="options.php">
                <?php settings_fields('zoomubik_geo_settings'); ?>
                <?php do_settings_sections('zoomubik_geo_settings'); ?>
                
                <table class="form-table">
                    <tr>
                        <th scope="row">Habilitar Geolocalización</th>
                        <td>
                            <input type="checkbox" name="zoomubik_geo_enabled" value="1" <?php checked(1, get_option('zoomubik_geo_enabled', true)); ?> />
                            <p class="description">Activar/desactivar la redirección automática por ubicación.</p>
                        </td>
                    </tr>
                    
                    <tr>
                        <th scope="row">Mostrar Modal de Confirmación</th>
                        <td>
                            <input type="checkbox" name="zoomubik_geo_show_modal" value="1" <?php checked(1, get_option('zoomubik_geo_show_modal', true)); ?> />
                            <p class="description">Mostrar ventana de confirmación antes de redirigir.</p>
                        </td>
                    </tr>
                    
                    <tr>
                        <th scope="row">Timeout GPS (milisegundos)</th>
                        <td>
                            <input type="number" name="zoomubik_geo_timeout" value="<?php echo esc_attr(get_option('zoomubik_geo_timeout', 15000)); ?>" min="5000" max="30000" />
                            <p class="description">Tiempo máximo para obtener ubicación GPS (recomendado: 15000ms para dar tiempo al usuario).</p>
                        </td>
                    </tr>
                    
                    <tr>
                        <th scope="row">Auto-redirect (milisegundos)</th>
                        <td>
                            <input type="number" name="zoomubik_geo_auto_redirect" value="<?php echo esc_attr(get_option('zoomubik_geo_auto_redirect', 5000)); ?>" min="2000" max="10000" />
                            <p class="description">Tiempo antes de redirigir automáticamente (recomendado: 5000ms).</p>
                        </td>
                    </tr>
                    
                    <tr>
                        <th scope="row">Habilitar en todas las páginas</th>
                        <td>
                            <input type="checkbox" name="zoomubik_geo_enable_global" value="1" <?php checked(1, get_option('zoomubik_geo_enable_global', false)); ?> />
                            <p class="description">Por defecto solo funciona en la página principal. Marcar para habilitar en todas las páginas.</p>
                        </td>
                    </tr>
                    
                    <tr>
                        <th scope="row">Modo Debug</th>
                        <td>
                            <input type="checkbox" name="zoomubik_geo_debug" value="1" <?php checked(1, get_option('zoomubik_geo_debug', false)); ?> />
                            <p class="description">Mostrar logs detallados en la consola del navegador.</p>
                        </td>
                    </tr>
                </table>
                
                <?php submit_button(); ?>
            </form>
            
            <hr>
            
            <h2>📊 Estadísticas</h2>
            <p><strong>Versión del Plugin:</strong> <?php echo ZOOMUBIK_GEO_VERSION; ?></p>
            <p><strong>Tu IP actual:</strong> <?php echo self::get_user_ip(); ?></p>
            <p><strong>Provincia detectada por IP:</strong> 
                <?php 
                $province = self::get_user_province_by_ip();
                echo $province ? $province : 'No detectada';
                ?>
            </p>
            
            <h2>🗺️ Provincias Soportadas</h2>
            <p>El plugin redirige automáticamente a estas provincias:</p>
            <div style="columns: 3; column-gap: 20px;">
                <ul>
                    <li>Madrid → /provincias/madrid/</li>
                    <li>Barcelona → /provincias/barcelona/</li>
                    <li>Valencia → /provincias/valencia/</li>
                    <li>Sevilla → /provincias/sevilla/</li>
                    <li>Zaragoza → /provincias/zaragoza/</li>
                    <li>Málaga → /provincias/malaga/</li>
                    <li>Murcia → /provincias/murcia/</li>
                    <li>Palma → /provincias/palma/</li>
                    <li>Las Palmas → /provincias/las-palmas/</li>
                    <li>Bilbao → /provincias/bilbao/</li>
                    <li>Alicante → /provincias/alicante/</li>
                    <li>Córdoba → /provincias/cordoba/</li>
                    <li>Valladolid → /provincias/valladolid/</li>
                    <li>Vigo → /provincias/vigo/</li>
                    <li>Gijón → /provincias/gijon/</li>
                    <li>Granada → /provincias/granada/</li>
                    <li>Vitoria → /provincias/vitoria/</li>
                    <li>Oviedo → /provincias/oviedo/</li>
                    <li>Santander → /provincias/santander/</li>
                    <li>Pamplona → /provincias/pamplona/</li>
                    <li>Almería → /provincias/almeria/</li>
                    <li>Burgos → /provincias/burgos/</li>
                    <li>Salamanca → /provincias/salamanca/</li>
                    <li>Huelva → /provincias/huelva/</li>
                    <li>Logroño → /provincias/logrono/</li>
                    <li>Badajoz → /provincias/badajoz/</li>
                    <li>León → /provincias/leon/</li>
                    <li>Cádiz → /provincias/cadiz/</li>
                </ul>
            </div>
        </div>
        <?php
    }
    
    /**
     * Activación del plugin
     */
    public function activate() {
        // Establecer valores por defecto
        add_option('zoomubik_geo_enabled', true);
        add_option('zoomubik_geo_debug', false);
        add_option('zoomubik_geo_timeout', 15000); // 15 segundos para dar tiempo al usuario
        add_option('zoomubik_geo_show_modal', true);
        add_option('zoomubik_geo_auto_redirect', 0); // SIN AUTO-REDIRECT
        add_option('zoomubik_geo_enable_global', false);
    }
    
    /**
     * Desactivación del plugin
     */
    public function deactivate() {
        // Limpiar opciones si es necesario
        // delete_option('zoomubik_geo_enabled');
    }
}

/**
 * Shortcode para mostrar selector manual de provincia
 */
function zoomubik_province_selector() {
    $provinces = array(
        'provincias/madrid' => 'Madrid',
        'provincias/barcelona' => 'Barcelona',
        'provincias/valencia' => 'Valencia',
        'provincias/sevilla' => 'Sevilla',
        'provincias/zaragoza' => 'Zaragoza',
        'provincias/malaga' => 'Málaga',
        'provincias/murcia' => 'Murcia',
        'provincias/palma' => 'Palma',
        'provincias/las-palmas' => 'Las Palmas',
        'provincias/bilbao' => 'Bilbao',
        'provincias/alicante' => 'Alicante',
        'provincias/cordoba' => 'Córdoba',
        'provincias/valladolid' => 'Valladolid',
        'provincias/vigo' => 'Vigo',
        'provincias/gijon' => 'Gijón',
        'provincias/granada' => 'Granada',
        'provincias/vitoria' => 'Vitoria',
        'provincias/oviedo' => 'Oviedo',
        'provincias/santander' => 'Santander',
        'provincias/pamplona' => 'Pamplona',
        'provincias/almeria' => 'Almería',
        'provincias/burgos' => 'Burgos',
        'provincias/salamanca' => 'Salamanca',
        'provincias/huelva' => 'Huelva',
        'provincias/logrono' => 'Logroño',
        'provincias/badajoz' => 'Badajoz',
        'provincias/leon' => 'León',
        'provincias/cadiz' => 'Cádiz',
    );
    
    ob_start();
    ?>
    <div class="zoomubik-province-selector">
        <h3>🗺️ Selecciona tu provincia</h3>
        <div class="province-grid" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 10px; margin: 20px 0;">
            <?php foreach ($provinces as $slug => $name): ?>
                <a href="/<?php echo esc_attr($slug); ?>/" 
                   class="province-link" 
                   style="display: block; padding: 15px; background: #f0f0f0; text-decoration: none; border-radius: 8px; text-align: center; transition: background 0.3s;"
                   onmouseover="this.style.background='#007cba'; this.style.color='white';"
                   onmouseout="this.style.background='#f0f0f0'; this.style.color='inherit';">
                    📍 <?php echo esc_html($name); ?>
                </a>
            <?php endforeach; ?>
        </div>
    </div>
    <?php
    return ob_get_clean();
}
add_shortcode('zoomubik_provinces', 'zoomubik_province_selector');

// Inicializar el plugin
new ZoomubikGeolocation();
?>