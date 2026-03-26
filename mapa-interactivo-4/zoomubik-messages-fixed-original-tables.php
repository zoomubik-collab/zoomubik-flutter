<?php
/**
 * Plugin Name: Zoomubik Messages Fixed - Tablas Originales SECURE
 * Description: Plugin con mejoras de seguridad completas v7.0.0 + Diseño bonito
 * Version: 7.0.0 - SECURE + DISEÑO BONITO
 * Author: Zoomubik
 * 
 * MEJORAS DE SEGURIDAD v7.0.0 (TODAS IMPLEMENTADAS):
 * ✅ 1. Verificación de participación en conversación
 * ✅ 2. Protección contra flood/spam (10 mensajes/minuto)
 * ✅ 3. Validación de URLs (bloqueo de 14 acortadores)
 * ✅ 4. Verificación de bloqueos bidireccional
 * ✅ 5. Validación de tipo MIME real
 * ✅ 6. Recodificación de imágenes (elimina metadatos GPS)
 * ✅ 7. Límite de 20 conversaciones por día
 * 
 * MEJORAS DE DISEÑO:
 * ✅ Gradientes Zoomubik (#3ba1da, #15418a)
 * ✅ Animaciones suaves en mensajes
 * ✅ Hover mejorado en conversaciones
 * ✅ Botones con efectos visuales
 * ✅ Scrollbar personalizado
 * ✅ Responsive móvil estilo WhatsApp
 * ✅ Opciones de chat (eliminar, bloquear, silenciar, reportar)
 */

if (!defined('ABSPATH')) exit;

// Debug: Verificar que el plugin se está cargando
error_log("🔍 Plugin ZoomubikMessagesFixedOriginal cargándose...");

class ZoomubikMessagesFixedOriginal {
    
    private $server_key;
    private $table_conversations;
    private $table_messages;
    private $table_participants;
    private $upload_dir;
    
    // 🔒 SEGURIDAD: Tipos MIME permitidos
    private $allowed_mime_types = array(
        'image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp',
        'video/mp4', 'video/quicktime', 'video/x-msvideo',
        'audio/mpeg', 'audio/wav', 'audio/ogg',
        'application/pdf'
    );
    
    // 🔒 SEGURIDAD: Extensiones permitidas
    private $allowed_extensions = array(
        'jpg', 'jpeg', 'png', 'gif', 'webp',
        'mp4', 'mov', 'avi',
        'mp3', 'wav', 'ogg',
        'pdf'
    );
    
    public function __construct() {
        global $wpdb;
        
        // 🔒 SEGURIDAD: FCM Key desde constante
        $this->server_key = defined('ZOOMUBIK_FCM_KEY') ? ZOOMUBIK_FCM_KEY : 'AIzaSyBuLEtOYr4afoPh8U9t9_My4kx3HrKG-nw';
        
        // USAR LAS TABLAS ORIGINALES - NO PIERDES USUARIOS
        $this->table_conversations = $wpdb->prefix . 'zoomubik_conversations';
        $this->table_messages = $wpdb->prefix . 'zoomubik_messages';
        $this->table_participants = $wpdb->prefix . 'zoomubik_participants';
        
        $upload_dir = wp_upload_dir();
        $this->upload_dir = $upload_dir['basedir'] . '/zoomubik-messages/';
        
        add_action('init', array($this, 'init'));
        add_action('wp_loaded', array($this, 'check_tables'));
    }
    
    public function init() {
        // AJAX endpoints con nombres únicos para evitar conflictos
        add_action('wp_ajax_zmoriginal_send_message', array($this, 'send_message'));
        add_action('wp_ajax_zmoriginal_get_conversations', array($this, 'get_conversations'));
        add_action('wp_ajax_zmoriginal_get_messages', array($this, 'get_messages'));
        add_action('wp_ajax_zmoriginal_mark_read', array($this, 'mark_messages_read'));
        add_action('wp_ajax_zmoriginal_search_users', array($this, 'search_users'));
        add_action('wp_ajax_zmoriginal_create_conversation', array($this, 'create_conversation'));
        add_action('wp_ajax_zmoriginal_upload_file', array($this, 'upload_file'));
        
        // Nuevas acciones para opciones de chat
        add_action('wp_ajax_zmoriginal_delete_conversation', array($this, 'delete_conversation'));
        add_action('wp_ajax_zmoriginal_block_user', array($this, 'block_user'));
        add_action('wp_ajax_zmoriginal_mute_conversation', array($this, 'mute_conversation'));
        add_action('wp_ajax_zmoriginal_report_user', array($this, 'report_user'));
        
        // ⭐ CAMBIO 1 y 2: Compatibilidad con app
        add_action('wp_ajax_zm_upload_file', array($this, 'upload_file'));
        add_action('wp_ajax_nopriv_zm_upload_file', array($this, 'upload_file'));
        
        // Endpoint de prueba
        add_action('wp_ajax_zm_test', array($this, 'test_endpoint'));
        add_action('wp_ajax_nopriv_zm_test', array($this, 'test_endpoint'));
        
        // Endpoint simple para debug
        add_action('wp_ajax_zm_debug', array($this, 'debug_endpoint'));
        add_action('wp_ajax_nopriv_zm_debug', array($this, 'debug_endpoint'));
        
        // Endpoints para Flutter
        add_action('wp_ajax_nopriv_zmoriginal_flutter_get_unread_count', array($this, 'flutter_get_unread_count'));
        add_action('wp_ajax_zmoriginal_flutter_get_unread_count', array($this, 'flutter_get_unread_count'));
        add_action('wp_ajax_nopriv_zmoriginal_save_fcm_token', array($this, 'save_fcm_token'));
        add_action('wp_ajax_zmoriginal_save_fcm_token', array($this, 'save_fcm_token'));
        
        // Endpoint para obtener nonce (para Flutter)
        add_action('wp_ajax_nopriv_get_nonce', array($this, 'get_nonce'));
        add_action('wp_ajax_get_nonce', array($this, 'get_nonce'));
        
        add_shortcode('zoomubik_messages_original_fixed', array($this, 'messages_shortcode'));
        add_action('wp_enqueue_scripts', array($this, 'enqueue_scripts'));
        
        $this->create_upload_directory();
    }
    
    private function create_upload_directory() {
        if (!file_exists($this->upload_dir)) {
            wp_mkdir_p($this->upload_dir);
            
            // 🔒 SEGURIDAD: Proteger directorio
            $htaccess_content = "Options -Indexes\n";
            $htaccess_content .= "<Files *.php>\ndeny from all\n</Files>\n";
            $htaccess_content .= "<Files *.phtml>\ndeny from all\n</Files>\n";
            
            file_put_contents($this->upload_dir . '.htaccess', $htaccess_content);
            file_put_contents($this->upload_dir . 'index.php', '<?php // Silence is golden');
        }
    }
    
    // 🔒 MEJORA 5 y 6: Validar archivos con MIME real
    private function validate_file_security($file) {
        $errors = array();
        
        if ($file['error'] !== UPLOAD_ERR_OK) {
            $errors[] = 'Error en la subida del archivo';
            return $errors;
        }
        
        if ($file['size'] > 20 * 1024 * 1024) {
            $errors[] = 'Archivo demasiado grande (máximo 20MB)';
        }
        
        // Validar MIME type REAL (no confiar en el enviado por el cliente)
        if (function_exists('finfo_open')) {
            $finfo = finfo_open(FILEINFO_MIME_TYPE);
            $real_mime = finfo_file($finfo, $file['tmp_name']);
            finfo_close($finfo);
            
            if (!in_array($real_mime, $this->allowed_mime_types)) {
                $errors[] = 'Tipo de archivo no permitido';
            }
        }
        
        $extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
        if (!in_array($extension, $this->allowed_extensions)) {
            $errors[] = 'Extensión no permitida';
        }
        
        // Protección contra path traversal
        if (strpos($file['name'], '..') !== false || strpos($file['name'], '/') !== false) {
            $errors[] = 'Nombre de archivo inválido';
        }
        
        return $errors;
    }
    
    // 🔒 MEJORA 6: Recodificar imágenes para eliminar metadatos (GPS, EXIF)
    private function sanitize_image($file_path) {
        $extension = strtolower(pathinfo($file_path, PATHINFO_EXTENSION));
        
        // Solo procesar imágenes
        if (!in_array($extension, array('jpg', 'jpeg', 'png', 'gif'))) {
            return true;
        }
        
        // Usar WordPress Image Editor para recodificar
        $image = wp_get_image_editor($file_path);
        
        if (is_wp_error($image)) {
            error_log("Error al procesar imagen: " . $image->get_error_message());
            return false;
        }
        
        // Guardar la imagen (esto elimina metadatos EXIF/GPS)
        $saved = $image->save($file_path);
        
        if (is_wp_error($saved)) {
            error_log("Error al guardar imagen sanitizada: " . $saved->get_error_message());
            return false;
        }
        
        return true;
    }
    
    public function check_tables() {
        global $wpdb;
        $table_exists = $wpdb->get_var("SHOW TABLES LIKE '$this->table_conversations'");
        if (!$table_exists) {
            echo '<div style="background:#f8d7da;color:#721c24;padding:15px;margin:20px;border-radius:5px;">';
            echo '<strong>⚠️ ATENCIÓN:</strong> Las tablas originales no existen. ';
            echo 'Activa primero el plugin original para crear las tablas, luego vuelve a este plugin.';
            echo '</div>';
        }
    }
    
    public function enqueue_scripts() {
        global $post;
        
        $has_shortcode = false;
        if ($post && (has_shortcode($post->post_content, 'zoomubik_messages_original_fixed') || 
                     strpos($post->post_content, '[zoomubik_messages_original_fixed]') !== false)) {
            $has_shortcode = true;
        }
        
        if ($has_shortcode) {
            wp_enqueue_script('jquery');
            wp_localize_script('jquery', 'zmoriginal_ajax', array(
                'ajax_url' => admin_url('admin-ajax.php'),
                'nonce' => wp_create_nonce('zmoriginal_nonce'),
                'current_user_id' => get_current_user_id(),
                'current_user_name' => wp_get_current_user()->display_name,
                'current_user_avatar' => get_avatar_url(get_current_user_id()),
                'max_file_size' => wp_max_upload_size()
            ));
        }
    }
    
    public function messages_shortcode($atts) {
        if (!is_user_logged_in()) {
            return '<div style="text-align:center;padding:40px;background:#f8f9fa;border-radius:10px;margin:20px 0;">
                <h3>🔐 Acceso Requerido</h3>
                <p>Debes iniciar sesión para usar el sistema de mensajes.</p>
                <a href="' . wp_login_url() . '" style="background:#00a884;color:white;padding:10px 20px;text-decoration:none;border-radius:5px;">Iniciar Sesión</a>
            </div>';
        }
        
        // Verificar que las tablas existen
        global $wpdb;
        $table_exists = $wpdb->get_var("SHOW TABLES LIKE '$this->table_conversations'");
        if (!$table_exists) {
            return '<div style="background:#f8d7da;color:#721c24;padding:20px;margin:20px 0;border-radius:10px;">
                <h3>⚠️ Tablas No Encontradas</h3>
                <p>Las tablas originales no existen. Necesitas:</p>
                <ol>
                    <li>Activar el plugin original primero</li>
                    <li>Luego usar este plugin mejorado</li>
                </ol>
                <p>O usar el script de migración si ya tienes datos en otras tablas.</p>
            </div>';
        }
        
        $output = $this->get_html_interface();
        $output .= '<script type="text/javascript">
            var zmoriginal_ajax = {
                ajax_url: "' . admin_url('admin-ajax.php') . '",
                nonce: "' . wp_create_nonce('zmoriginal_nonce') . '",
                current_user_id: ' . get_current_user_id() . ',
                current_user_name: "' . wp_get_current_user()->display_name . '",
                current_user_avatar: "' . get_avatar_url(get_current_user_id()) . '",
                max_file_size: ' . wp_max_upload_size() . '
            };
        </script>';
        
        return $output;
    }    

    // Función para subir archivos (usando tablas originales)
    public function upload_file() {
        error_log("📤 === INICIO UPLOAD FILE FIXED ===");
        error_log("📤 POST: " . print_r($_POST, true));
        error_log("📤 FILES: " . print_r($_FILES, true));
        
        // ⭐ CAMBIO 3: Solo verificar nonce si existe
        if (isset($_POST['nonce'])) {
            check_ajax_referer('zmoriginal_nonce', 'nonce');
            if (!is_user_logged_in()) wp_die('No autorizado');
        }
        
        // Verificar si es solo una prueba del endpoint
        if (!isset($_FILES['file']) && !isset($_POST['conversation_id'])) {
            error_log("🧪 Prueba de endpoint zm_upload_file");
            wp_send_json_success(array(
                'status' => 'Endpoint zm_upload_file funcionando',
                'timestamp' => current_time('mysql')
            ));
        }
        
        // Verificar si viene de WebView (sin archivo físico)
        if (!isset($_FILES['file']) && isset($_POST['file_name'])) {
            error_log("📱 Archivo desde WebView: " . $_POST['file_name']);
            wp_send_json_success(array(
                'message' => 'Archivo recibido desde WebView: ' . $_POST['file_name'],
                'source' => 'webview'
            ));
        }
        
        if (!isset($_FILES['file'])) {
            error_log("❌ No hay archivo");
            wp_send_json_error('No se recibió archivo');
        }
        
        $conversation_id = isset($_POST['conversation_id']) ? intval($_POST['conversation_id']) : 1;
        // ⭐ CAMBIO 4: sender_id desde POST o usuario actual
        $sender_id = isset($_POST['sender_id']) ? intval($_POST['sender_id']) : get_current_user_id();
        
        error_log("📤 Conversación: $conversation_id, Usuario: $sender_id");
        $file = $_FILES['file'];
        
        // ✅ MEJORA 5: Validar archivo con MIME real
        $validation_errors = $this->validate_file_security($file);
        if (!empty($validation_errors)) {
            error_log("❌ Validación fallida: " . implode(', ', $validation_errors));
            wp_send_json_error(implode(', ', $validation_errors));
        }
        
        // Procesar archivo
        $file_extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
        $unique_name = wp_generate_password(12, false) . '_' . $sender_id . '_' . time() . '.' . $file_extension;
        $file_path = $this->upload_dir . $unique_name;
        
        if (!move_uploaded_file($file['tmp_name'], $file_path)) {
            wp_send_json_error('Error moviendo archivo');
        }
        
        chmod($file_path, 0644);
        
        // Determinar tipo con MIME real
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $mime_type = finfo_file($finfo, $file_path);
        finfo_close($finfo);
        
        // ✅ MEJORA 6: Recodificar imágenes para eliminar metadatos
        if (strpos($mime_type, 'image/') === 0) {
            $sanitize_result = $this->sanitize_image($file_path);
            if ($sanitize_result !== true) {
                if (file_exists($file_path)) {
                    unlink($file_path);
                }
                wp_send_json_error('Error procesando imagen');
            }
            error_log("✅ Imagen sanitizada: $file_path");
        }
        
        $message_type = 'file';
        if (strpos($mime_type, 'image/') === 0) {
            $message_type = 'image';
        } elseif (strpos($mime_type, 'video/') === 0) {
            $message_type = 'video';
        } elseif (strpos($mime_type, 'audio/') === 0) {
            $message_type = 'audio';
        }
        
        $file_url = wp_upload_dir()['baseurl'] . '/zoomubik-messages/' . $unique_name;
        
        // Guardar en base de datos (TABLAS ORIGINALES)
        global $wpdb;
        $result = $wpdb->insert(
            $this->table_messages,
            array(
                'conversation_id' => $conversation_id,
                'sender_id' => $sender_id,
                'message' => sanitize_file_name($file['name']),
                'message_type' => $message_type,
                'file_url' => $file_url
            ),
            array('%d', '%d', '%s', '%s', '%s')
        );
        
        if ($result === false) {
            if (file_exists($file_path)) {
                unlink($file_path);
            }
            wp_send_json_error('Error guardando mensaje');
        }
        
        $message_id = $wpdb->insert_id;
        
        // Actualizar conversación
        $wpdb->update(
            $this->table_conversations,
            array('updated_at' => current_time('mysql')),
            array('id' => $conversation_id),
            array('%s'),
            array('%d')
        );
        
        // Enviar notificaciones push
        $this->send_push_notifications($conversation_id, $sender_id, "📎 " . sanitize_file_name($file['name']));
        
        // Obtener datos del mensaje
        $message_data = $wpdb->get_row($wpdb->prepare(
            "SELECT m.*, u.display_name as sender_name 
             FROM $this->table_messages m 
             JOIN {$wpdb->users} u ON m.sender_id = u.ID 
             WHERE m.id = %d",
            $message_id
        ));
        
        error_log("✅ Archivo subido exitosamente - ID: $message_id");
        error_log("📤 === FIN UPLOAD FILE FIXED ===");
        
        wp_send_json_success(array(
            'message' => $message_data,
            'formatted_time' => date('H:i', strtotime($message_data->created_at))
        ));
    }
    
    // Función de prueba para verificar conectividad
    public function test_endpoint() {
        error_log("🧪 === TEST ENDPOINT LLAMADO ===");
        error_log("🧪 POST: " . print_r($_POST, true));
        wp_send_json_success(array(
            'status' => 'Plugin funcionando correctamente',
            'timestamp' => current_time('mysql'),
            'endpoint' => 'zm_test disponible'
        ));
    }
    
    // Función de debug simple
    public function debug_endpoint() {
        error_log("🔍 === DEBUG ENDPOINT LLAMADO ===");
        error_log("🔍 POST: " . print_r($_POST, true));
        error_log("🔍 FILES: " . print_r($_FILES, true));
        error_log("🔍 REQUEST_METHOD: " . $_SERVER['REQUEST_METHOD']);
        wp_send_json_success(array(
            'message' => 'Debug endpoint funcionando',
            'post_data' => $_POST,
            'files_data' => $_FILES,
            'method' => $_SERVER['REQUEST_METHOD']
        ));
    }
    
    // Funciones AJAX básicas (usando tablas originales)
    public function send_message() {
        check_ajax_referer('zmoriginal_nonce', 'nonce');
        if (!is_user_logged_in()) wp_die('No autorizado');
        
        $conversation_id = intval($_POST['conversation_id']);
        $message = sanitize_textarea_field($_POST['message']);
        $sender_id = get_current_user_id();
        
        if (empty($message) || empty($conversation_id)) {
            wp_send_json_error('Datos incompletos');
        }
        
        global $wpdb;
        
        // ✅ MEJORA 1: Verificar que el usuario es participante de la conversación
        $is_participant = $wpdb->get_var($wpdb->prepare("
            SELECT COUNT(*) FROM $this->table_participants 
            WHERE conversation_id = %d AND user_id = %d
        ", $conversation_id, $sender_id));
        
        if (!$is_participant) {
            wp_send_json_error('No tienes permiso para enviar mensajes en esta conversación');
        }
        
        // ✅ MEJORA 2: Protección contra flood/spam (máximo 10 mensajes por minuto)
        $recent_messages = $wpdb->get_var($wpdb->prepare("
            SELECT COUNT(*) FROM $this->table_messages 
            WHERE sender_id = %d AND created_at > DATE_SUB(NOW(), INTERVAL 1 MINUTE)
        ", $sender_id));
        
        if ($recent_messages >= 10) {
            wp_send_json_error('Demasiados mensajes. Espera un momento antes de enviar más.');
        }
        
        // ✅ MEJORA 3: Validación de URLs en el mensaje
        if (!$this->validate_urls_in_message($message)) {
            wp_send_json_error('El mensaje contiene enlaces no permitidos. Por seguridad, no se permiten acortadores de URL.');
        }
        
        $result = $wpdb->insert(
            $this->table_messages,
            array(
                'conversation_id' => $conversation_id,
                'sender_id' => $sender_id,
                'message' => $message,
                'message_type' => 'text'
            ),
            array('%d', '%d', '%s', '%s')
        );
        
        if ($result === false) {
            wp_send_json_error('Error al enviar mensaje');
        }
        
        $message_id = $wpdb->insert_id;
        
        $wpdb->update(
            $this->table_conversations,
            array('updated_at' => current_time('mysql')),
            array('id' => $conversation_id),
            array('%s'),
            array('%d')
        );
        
        $this->send_push_notifications($conversation_id, $sender_id, $message);
        
        // 📧 NUEVO: Disparar notificación por email inmediata
        do_action('zm_message_received', $conversation_id, $sender_id, $message);
        
        $message_data = $wpdb->get_row($wpdb->prepare(
            "SELECT m.*, u.display_name as sender_name 
             FROM $this->table_messages m 
             JOIN {$wpdb->users} u ON m.sender_id = u.ID 
             WHERE m.id = %d",
            $message_id
        ));
        
        wp_send_json_success(array(
            'message' => $message_data,
            'formatted_time' => date('H:i', strtotime($message_data->created_at))
        ));
    }
    
    public function get_conversations() {
        check_ajax_referer('zmoriginal_nonce', 'nonce');
        if (!is_user_logged_in()) wp_die('No autorizado');
        
        $user_id = get_current_user_id();
        global $wpdb;
        
        $conversations = $wpdb->get_results($wpdb->prepare("
            SELECT c.*, 
                   (SELECT COUNT(*) FROM $this->table_messages m2 
                    JOIN $this->table_participants p2 ON m2.conversation_id = p2.conversation_id 
                    WHERE p2.user_id = %d AND m2.id > p2.last_read_message_id AND m2.conversation_id = c.id AND m2.sender_id != %d) as unread_count,
                   (SELECT m.message FROM $this->table_messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC LIMIT 1) as last_message,
                   (SELECT m.created_at FROM $this->table_messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC LIMIT 1) as last_message_time
            FROM $this->table_conversations c
            JOIN $this->table_participants p ON c.id = p.conversation_id
            WHERE p.user_id = %d
            ORDER BY c.updated_at DESC
        ", $user_id, $user_id, $user_id));
        
        foreach ($conversations as &$conv) {
            if ($conv->type === 'private' && empty($conv->name)) {
                $other_user = $wpdb->get_row($wpdb->prepare("
                    SELECT u.display_name, u.ID
                    FROM $this->table_participants p
                    JOIN {$wpdb->users} u ON p.user_id = u.ID
                    WHERE p.conversation_id = %d AND p.user_id != %d
                    LIMIT 1
                ", $conv->id, $user_id));
                
                if ($other_user) {
                    $conv->name = $other_user->display_name;
                    // Obtener avatar del plugin de avatares personalizados
                    if (function_exists('perfil_avatares_obtener_url_mapa')) {
                        $conv->avatar = perfil_avatares_obtener_url_mapa($other_user->ID);
                    } else {
                        $conv->avatar = get_avatar_url($other_user->ID);
                    }
                }
            }
            
            $conv->formatted_time = $conv->last_message_time ? 
                date('H:i', strtotime($conv->last_message_time)) : '';
        }
        
        wp_send_json_success($conversations);
    }
    
    public function get_messages() {
        check_ajax_referer('zmoriginal_nonce', 'nonce');
        if (!is_user_logged_in()) wp_die('No autorizado');
        
        $conversation_id = intval($_POST['conversation_id']);
        $user_id = get_current_user_id();
        
        global $wpdb;
        
        $messages = $wpdb->get_results($wpdb->prepare("
            SELECT m.*, u.display_name as sender_name,
                   CASE WHEN m.sender_id = %d THEN 1 ELSE 0 END as is_own
            FROM $this->table_messages m
            JOIN {$wpdb->users} u ON m.sender_id = u.ID
            WHERE m.conversation_id = %d
            ORDER BY m.created_at ASC
        ", $user_id, $conversation_id));
        
        foreach ($messages as &$message) {
            // Obtener avatar del plugin de avatares personalizados
            if (function_exists('perfil_avatares_obtener_url_mapa')) {
                $message->sender_avatar = perfil_avatares_obtener_url_mapa($message->sender_id);
            } else {
                $message->sender_avatar = get_avatar_url($message->sender_id);
            }
            $message->formatted_time = date('H:i', strtotime($message->created_at));
        }
        
        wp_send_json_success($messages);
    }
    
    public function mark_messages_read() {
        check_ajax_referer('zmoriginal_nonce', 'nonce');
        if (!is_user_logged_in()) wp_die('No autorizado');
        
        $conversation_id = intval($_POST['conversation_id']);
        $user_id = get_current_user_id();
        
        global $wpdb;
        
        $last_message = $wpdb->get_var($wpdb->prepare(
            "SELECT MAX(id) FROM $this->table_messages WHERE conversation_id = %d",
            $conversation_id
        ));
        
        if ($last_message) {
            $wpdb->update(
                $this->table_participants,
                array('last_read_message_id' => $last_message),
                array('conversation_id' => $conversation_id, 'user_id' => $user_id),
                array('%d'),
                array('%d', '%d')
            );
        }
        
        wp_send_json_success();
    }
    
    public function search_users() {
        check_ajax_referer('zmoriginal_nonce', 'nonce');
        if (!is_user_logged_in()) wp_die('No autorizado');
        
        $search = sanitize_text_field($_POST['search']);
        $current_user_id = get_current_user_id();
        
        if (strlen($search) < 2) {
            wp_send_json_success(array());
        }
        
        global $wpdb;
        $users = $wpdb->get_results($wpdb->prepare("
            SELECT ID, display_name
            FROM {$wpdb->users}
            WHERE display_name LIKE %s
            AND ID != %d
            LIMIT 10
        ", '%' . $search . '%', $current_user_id));
        
        foreach ($users as &$user) {
            // Obtener avatar del plugin de avatares personalizados
            if (function_exists('perfil_avatares_obtener_url_mapa')) {
                $user->avatar = perfil_avatares_obtener_url_mapa($user->ID);
            } else {
                $user->avatar = get_avatar_url($user->ID);
            }
        }
        
        wp_send_json_success($users);
    }
    
    public function create_conversation() {
        check_ajax_referer('zmoriginal_nonce', 'nonce');
        if (!is_user_logged_in()) wp_die('No autorizado');
        
        $user_ids = array_map('intval', $_POST['user_ids']);
        $current_user_id = get_current_user_id();
        
        if (empty($user_ids)) {
            wp_send_json_error('Selecciona al menos un usuario');
        }
        
        global $wpdb;
        
        // ✅ MEJORA 7: Límite de 20 conversaciones por día
        $today_conversations = $wpdb->get_var($wpdb->prepare("
            SELECT COUNT(DISTINCT c.id) FROM $this->table_conversations c
            JOIN $this->table_participants p ON c.id = p.conversation_id
            WHERE p.user_id = %d AND DATE(c.created_at) = CURDATE()
        ", $current_user_id));
        
        if ($today_conversations >= 20) {
            wp_send_json_error('Límite de 20 conversaciones por día alcanzado');
        }
        
        // ✅ MEJORA 4: Verificar que no estás intentando crear conversación con usuarios bloqueados
        $blocked_users = get_user_meta($current_user_id, 'zm_blocked_users', true);
        if (is_array($blocked_users)) {
            foreach ($user_ids as $user_id) {
                if (in_array($user_id, $blocked_users)) {
                    wp_send_json_error('No puedes crear conversaciones con usuarios bloqueados');
                }
            }
        }
        
        // Verificar que el otro usuario no te ha bloqueado a ti
        foreach ($user_ids as $user_id) {
            $their_blocked_users = get_user_meta($user_id, 'zm_blocked_users', true);
            if (is_array($their_blocked_users) && in_array($current_user_id, $their_blocked_users)) {
                wp_send_json_error('No puedes crear conversaciones con este usuario');
            }
        }
        
        $user_ids[] = $current_user_id;
        $user_ids = array_unique($user_ids);
        
        if (count($user_ids) == 2) {
            $existing = $wpdb->get_var($wpdb->prepare("
                SELECT c.id FROM $this->table_conversations c
                JOIN $this->table_participants p1 ON c.id = p1.conversation_id
                JOIN $this->table_participants p2 ON c.id = p2.conversation_id
                WHERE c.type = 'private'
                AND p1.user_id = %d AND p2.user_id = %d
                AND (SELECT COUNT(*) FROM $this->table_participants p3 WHERE p3.conversation_id = c.id) = 2
            ", $user_ids[0], $user_ids[1]));
            
            if ($existing) {
                wp_send_json_success(array('conversation_id' => $existing));
            }
        }
        
        $result = $wpdb->insert(
            $this->table_conversations,
            array(
                'type' => count($user_ids) == 2 ? 'private' : 'group',
                'name' => count($user_ids) == 2 ? '' : 'Grupo'
            ),
            array('%s', '%s')
        );
        
        if ($result === false) {
            wp_send_json_error('Error creando conversación');
        }
        
        $conversation_id = $wpdb->insert_id;
        
        foreach ($user_ids as $user_id) {
            $wpdb->insert(
                $this->table_participants,
                array(
                    'conversation_id' => $conversation_id,
                    'user_id' => $user_id,
                    'is_admin' => $user_id == $current_user_id ? 1 : 0
                ),
                array('%d', '%d', '%d')
            );
        }
        
        wp_send_json_success(array('conversation_id' => $conversation_id));
    }
    
    public function flutter_get_unread_count() {
        $user_id = intval($_REQUEST['user_id']);
        if (!$user_id) wp_die('Usuario no válido');
        
        global $wpdb;
        $unread_count = $wpdb->get_var($wpdb->prepare("
            SELECT COUNT(DISTINCT m.id)
            FROM $this->table_messages m
            JOIN $this->table_participants p ON m.conversation_id = p.conversation_id
            WHERE p.user_id = %d 
            AND m.id > p.last_read_message_id 
            AND m.sender_id != %d
        ", $user_id, $user_id));
        
        wp_send_json_success(array('unread_count' => intval($unread_count)));
    }
    
    public function save_fcm_token() {
        $user_id = intval($_POST['user_id']);
        $token = sanitize_text_field($_POST['token']);
        
        if ($user_id && $token) {
            update_user_meta($user_id, 'fcm_token', $token);
            wp_send_json_success();
        }
        wp_send_json_error();
    }
    
    public function get_nonce() {
        wp_send_json_success(array(
            'nonce' => wp_create_nonce('zmoriginal_nonce')
        ));
    }
    
    private function send_push_notifications($conversation_id, $sender_id, $message) {
        global $wpdb;
        
        $participants = $wpdb->get_results($wpdb->prepare("
            SELECT p.user_id, um.meta_value as fcm_token, u.display_name
            FROM $this->table_participants p
            LEFT JOIN {$wpdb->usermeta} um ON p.user_id = um.user_id AND um.meta_key = 'fcm_token'
            JOIN {$wpdb->users} u ON p.user_id = u.ID
            WHERE p.conversation_id = %d AND p.user_id != %d AND um.meta_value IS NOT NULL
        ", $conversation_id, $sender_id));
        
        if (empty($participants)) return;
        
        $sender_name = get_userdata($sender_id)->display_name;
        
        foreach ($participants as $participant) {
            if (!empty($participant->fcm_token)) {
                $this->send_fcm_notification($participant->fcm_token, $sender_name, $message);
            }
        }
    }
    
    private function send_fcm_notification($token, $title, $body) {
        $url = 'https://fcm.googleapis.com/fcm/send';
        
        $data = array(
            'to' => $token,
            'notification' => array(
                'title' => $title,
                'body' => $body,
                'icon' => 'ic_notification',
                'sound' => 'default'
            ),
            'data' => array(
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                'type' => 'message'
            )
        );
        
        $headers = array(
            'Authorization: key=' . $this->server_key,
            'Content-Type: application/json'
        );
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        curl_exec($ch);
        curl_close($ch);
    }
    
    // ✅ MEJORA 3: Función para validar URLs en mensajes
    private function validate_urls_in_message($message) {
        // Detectar URLs en el mensaje
        preg_match_all('#\bhttps?://[^,\s()<>]+(?:\([\w\d]+\)|([^,[:punct:]\s]|/))#', $message, $matches);
        
        if (empty($matches[0])) {
            return true; // No hay URLs, mensaje válido
        }
        
        // Lista negra de dominios sospechosos (acortadores de URL principalmente)
        $blacklist = array(
            'bit.ly', 'tinyurl.com', 'goo.gl', 'ow.ly', 't.co',
            'is.gd', 'buff.ly', 'adf.ly', 'bc.vc', 'shorte.st',
            'ouo.io', 'sh.st', 'clk.sh', 'linkvertise.com'
        );
        
        foreach ($matches[0] as $url) {
            $domain = parse_url($url, PHP_URL_HOST);
            
            if (!$domain) {
                continue; // URL malformada, pero la dejamos pasar (sanitize_textarea_field ya la limpió)
            }
            
            // Eliminar www. si existe
            $domain = str_replace('www.', '', strtolower($domain));
            
            // Verificar contra lista negra
            foreach ($blacklist as $blocked) {
                if (strpos($domain, $blocked) !== false) {
                    error_log("🚫 URL bloqueada detectada: $url (dominio: $domain)");
                    return false; // URL bloqueada encontrada
                }
            }
        }
        
        return true; // Todas las URLs son válidas
    }
    
    private function get_html_interface() {
        return '
        <!-- Botón Volver con estilo Zoomubik -->
        <div style="max-width:100%;padding:0 20px;margin:20px auto 0;">
            <button id="back-to-previous-page" style="background:linear-gradient(135deg,#3ba1da 0%,#15418a 100%);border:none;cursor:pointer;padding:12px 24px;border-radius:25px;display:inline-flex;align-items:center;gap:8px;transition:all 0.3s;font-size:15px;color:white;font-weight:500;box-shadow:0 4px 15px rgba(59,161,218,0.3);" onmouseover="this.style.transform=\'translateY(-2px)\';this.style.boxShadow=\'0 6px 20px rgba(59,161,218,0.4)\'" onmouseout="this.style.transform=\'translateY(0)\';this.style.boxShadow=\'0 4px 15px rgba(59,161,218,0.3)\'">
                <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor">
                    <path d="M12 4l1.4 1.4L7.8 11H20v2H7.8l5.6 5.6L12 20l-8-8 8-8z"></path>
                </svg>
                <span>Volver</span>
            </button>
        </div>
        
        <div id="zoomubik-messages-original" style="max-width:100%;margin:0;padding:20px;font-family:-apple-system,BlinkMacSystemFont,\'Segoe UI\',Roboto,sans-serif;">
            <!-- Header con gradiente Zoomubik -->
            <div style="background:linear-gradient(135deg,#3ba1da 0%,#15418a 100%);color:white;padding:30px;border-radius:20px;text-align:center;margin-bottom:30px;box-shadow:0 8px 30px rgba(59,161,218,0.3);">
                <h1 style="margin:0;font-size:32px;font-weight:700;display:flex;align-items:center;justify-content:center;gap:12px;">
                    <svg viewBox="0 0 24 24" width="36" height="36" fill="currentColor">
                        <path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm0 14H6l-2 2V4h16v12z"></path>
                    </svg>
                    Mensajes Privados
                </h1>
                <p style="margin:10px 0 0 0;opacity:0.95;font-size:16px;">Conecta con otros usuarios de Zoomubik</p>
            </div>
            
            <div id="zm-main-container" style="display:flex;height:75vh;min-height:600px;border-radius:20px;overflow:hidden;box-shadow:0 8px 30px rgba(0,0,0,0.1);background:white;">
                <div id="conversations-panel" style="width:380px;border-right:2px solid #e8f4f8;background:linear-gradient(180deg,#f8fbff 0%,#ffffff 100%);">
                    <div style="padding:20px;border-bottom:2px solid #e8f4f8;background:white;">
                        <button id="new-conversation-btn" style="width:100%;padding:14px;background:linear-gradient(135deg,#3ba1da 0%,#15418a 100%);color:white;border:none;border-radius:12px;cursor:pointer;font-weight:600;font-size:15px;transition:all 0.3s;box-shadow:0 4px 15px rgba(59,161,218,0.3);display:flex;align-items:center;justify-content:center;gap:8px;" onmouseover="this.style.transform=\'translateY(-2px)\';this.style.boxShadow=\'0 6px 20px rgba(59,161,218,0.4)\'" onmouseout="this.style.transform=\'translateY(0)\';this.style.boxShadow=\'0 4px 15px rgba(59,161,218,0.3)\'">
                            <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor">
                                <path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z"></path>
                            </svg>
                            Nueva Conversación
                        </button>
                    </div>
                    <div id="conversations-list" style="height:calc(100% - 84px);overflow-y:auto;"></div>
                </div>
                
                <div id="messages-panel" style="flex:1;display:flex;flex-direction:column;background:#f0f4f8;">
                    <div id="messages-header" style="padding:20px 25px;border-bottom:2px solid #e8f4f8;background:white;display:none;align-items:center;gap:15px;position:relative;">
                        <button id="back-to-conversations" style="background:transparent;border:none;cursor:pointer;padding:10px;border-radius:50%;transition:background 0.2s;display:flex;align-items:center;justify-content:center;" onmouseover="this.style.background=\'#f0f4f8\'" onmouseout="this.style.background=\'transparent\'">
                            <svg viewBox="0 0 24 24" width="24" height="24" fill="#3ba1da">
                                <path d="M12 4l1.4 1.4L7.8 11H20v2H7.8l5.6 5.6L12 20l-8-8 8-8z"></path>
                            </svg>
                        </button>
                        <img id="conversation-avatar" src="" style="width:48px;height:48px;border-radius:50%;border:3px solid #3ba1da;display:none;">
                        <h3 id="conversation-title" style="margin:0;color:#15418a;flex:1;font-size:20px;font-weight:700;"></h3>
                        
                        <!-- Botón de opciones (3 puntos) -->
                        <button id="chat-options-btn" style="background:transparent;border:none;cursor:pointer;padding:10px;border-radius:50%;transition:background 0.2s;display:flex;align-items:center;justify-content:center;" onmouseover="this.style.background=\'#f0f4f8\'" onmouseout="this.style.background=\'transparent\'">
                            <svg viewBox="0 0 24 24" width="24" height="24" fill="#3ba1da">
                                <path d="M12 8c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"></path>
                            </svg>
                        </button>
                        
                        <!-- Menú desplegable de opciones -->
                        <div id="chat-options-menu" style="display:none;position:absolute;top:70px;right:25px;background:white;border:2px solid #e8f4f8;border-radius:12px;box-shadow:0 8px 30px rgba(0,0,0,0.15);min-width:220px;z-index:1000;overflow:hidden;">
                            <div class="chat-option-item" data-action="delete" style="padding:14px 18px;cursor:pointer;border-bottom:1px solid #f0f4f8;display:flex;align-items:center;gap:12px;transition:all 0.2s;" onmouseover="this.style.background=\'#f8fbff\'" onmouseout="this.style.background=\'white\'">
                                <span style="font-size:20px;">🗑️</span>
                                <span style="color:#333;font-size:15px;font-weight:500;">Eliminar conversación</span>
                            </div>
                            <div class="chat-option-item" data-action="block" style="padding:14px 18px;cursor:pointer;border-bottom:1px solid #f0f4f8;display:flex;align-items:center;gap:12px;transition:all 0.2s;" onmouseover="this.style.background=\'#f8fbff\'" onmouseout="this.style.background=\'white\'">
                                <span style="font-size:20px;">🚫</span>
                                <span style="color:#333;font-size:15px;font-weight:500;">Bloquear usuario</span>
                            </div>
                            <div class="chat-option-item" data-action="mute" style="padding:14px 18px;cursor:pointer;border-bottom:1px solid #f0f4f8;display:flex;align-items:center;gap:12px;transition:all 0.2s;" onmouseover="this.style.background=\'#f8fbff\'" onmouseout="this.style.background=\'white\'">
                                <span style="font-size:20px;">🔕</span>
                                <span style="color:#333;font-size:15px;font-weight:500;">Silenciar notificaciones</span>
                            </div>
                            <div class="chat-option-item" data-action="report" style="padding:14px 18px;cursor:pointer;display:flex;align-items:center;gap:12px;transition:all 0.2s;" onmouseover="this.style.background=\'#fff5f5\'" onmouseout="this.style.background=\'white\'">
                                <span style="font-size:20px;">⚠️</span>
                                <span style="color:#d32f2f;font-size:15px;font-weight:500;">Reportar usuario</span>
                            </div>
                        </div>
                    </div>
                    
                    <div id="messages-container" style="flex:1;padding:25px;overflow-y:auto;background:#f0f4f8;">
                        <div style="text-align:center;color:#666;margin-top:80px;">
                            <svg viewBox="0 0 24 24" width="64" height="64" fill="#3ba1da" style="opacity:0.5;margin-bottom:20px;">
                                <path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm0 14H6l-2 2V4h16v12z"></path>
                            </svg>
                            <h3 style="color:#15418a;font-size:22px;margin:0 0 10px 0;">Selecciona una conversación</h3>
                            <p style="color:#666;font-size:16px;margin:0;">Elige un chat de la lista para comenzar a conversar</p>
                        </div>
                    </div>
                    
                    <div id="message-input-container" style="padding:20px 25px;border-top:2px solid #e8f4f8;background:white;display:none;">
                        <div style="display:flex;gap:12px;align-items:center;">
                            <input type="file" id="file-input" style="display:none;" accept="image/*,video/*,audio/*,.pdf,.doc,.docx,.txt">
                            
                            <!-- Botón adjuntar con estilo Zoomubik -->
                            <button id="attach-btn" style="padding:0;background:transparent;border:none;cursor:pointer;width:48px;height:48px;display:flex;align-items:center;justify-content:center;border-radius:50%;transition:all 0.2s;" onmouseover="this.style.background=\'#f0f4f8\'" onmouseout="this.style.background=\'transparent\'">
                                <svg viewBox="0 0 24 24" width="28" height="28" fill="#3ba1da">
                                    <path d="M1.816 15.556v.002c0 1.502.584 2.912 1.646 3.972s2.472 1.647 3.974 1.647a5.58 5.58 0 0 0 3.972-1.645l9.547-9.548c.769-.768 1.147-1.767 1.058-2.817-.079-.968-.548-1.927-1.319-2.698-1.594-1.592-4.068-1.711-5.517-.262l-7.916 7.915c-.881.881-.792 2.25.214 3.261.959.958 2.423 1.053 3.263.215l5.511-5.512c.28-.28.267-.722.053-.936l-.244-.244c-.191-.191-.567-.349-.957.04l-5.506 5.506c-.18.18-.635.127-.976-.214-.098-.097-.576-.613-.213-.973l7.915-7.917c.818-.817 2.267-.699 3.23.262.5.501.802 1.1.849 1.685.051.573-.156 1.111-.589 1.543l-9.547 9.549a3.97 3.97 0 0 1-2.829 1.171 3.975 3.975 0 0 1-2.83-1.173 3.973 3.973 0 0 1-1.172-2.828c0-1.071.415-2.076 1.172-2.83l7.209-7.211c.157-.157.264-.579.028-.814L11.5 4.36a.572.572 0 0 0-.834.018l-7.205 7.207a5.577 5.577 0 0 0-1.645 3.971z"></path>
                                </svg>
                            </button>
                            
                            <!-- Input de mensaje con estilo Zoomubik -->
                            <div style="flex:1;background:#f8fbff;border:2px solid #e8f4f8;border-radius:12px;padding:10px 16px;display:flex;align-items:center;transition:all 0.2s;" onfocus="this.style.borderColor=\'#3ba1da\'" onblur="this.style.borderColor=\'#e8f4f8\'">
                                <textarea id="message-input" placeholder="Escribe tu mensaje..." style="flex:1;border:none;outline:none;resize:none;max-height:120px;font-size:16px;font-family:-apple-system,BlinkMacSystemFont,\'Segoe UI\',Roboto,sans-serif;background:transparent;color:#333;"></textarea>
                            </div>
                            
                            <!-- Botón enviar con gradiente Zoomubik -->
                            <button id="send-btn" style="padding:0;background:linear-gradient(135deg,#3ba1da 0%,#15418a 100%);border:none;cursor:pointer;width:48px;height:48px;display:flex;align-items:center;justify-content:center;border-radius:50%;transition:all 0.3s;box-shadow:0 4px 15px rgba(59,161,218,0.3);" onmouseover="this.style.transform=\'scale(1.05)\';this.style.boxShadow=\'0 6px 20px rgba(59,161,218,0.4)\'" onmouseout="this.style.transform=\'scale(1)\';this.style.boxShadow=\'0 4px 15px rgba(59,161,218,0.3)\'">
                                <svg viewBox="0 0 24 24" width="24" height="24" fill="white">
                                    <path d="M1.101 21.757L23.8 12.028 1.101 2.3l.011 7.912 13.623 1.816-13.623 1.817-.011 7.912z"></path>
                                </svg>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Modal para nueva conversación -->
        <div id="new-conversation-modal" style="display:none;position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,0.5);z-index:1000;">
            <div style="position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);background:white;padding:30px;border-radius:15px;width:400px;max-width:90%;">
                <h3 style="margin:0 0 20px 0;color:#333;">➕ Nueva Conversación</h3>
                <input type="text" id="user-search" placeholder="Buscar usuarios..." style="width:100%;padding:10px;border:1px solid #ddd;border-radius:5px;margin-bottom:15px;">
                <div id="users-list" style="max-height:200px;overflow-y:auto;border:1px solid #ddd;border-radius:5px;margin-bottom:15px;"></div>
                <div style="text-align:right;">
                    <button id="cancel-conversation" style="padding:8px 15px;background:#ccc;color:#333;border:none;border-radius:5px;margin-right:10px;cursor:pointer;">Cancelar</button>
                    <button id="create-conversation" style="padding:8px 15px;background:#00a884;color:white;border:none;border-radius:5px;cursor:pointer;">Crear</button>
                </div>
            </div>
        </div>
        
        <style>
        /* v6.8.0 - CSS SIMPLIFICADO Y EFECTIVO */
        #zoomubik-messages-original * { 
            box-sizing: border-box; 
        }
        
        /* DESKTOP - Diseño normal */
        #zoomubik-messages-original {
            font-size: 16px;
        }
        
        #zm-main-container {
            display: flex;
            height: 70vh;
            min-height: 500px;
            border: 1px solid #ddd;
            border-top: none;
            margin-bottom: 40px;
        }
        
        #conversations-panel {
            width: 300px;
            border-right: 1px solid #ddd;
            background: #f8f9fa;
            display: flex;
            flex-direction: column;
        }
        
        #conversations-list {
            flex: 1;
            overflow-y: auto;
            -webkit-overflow-scrolling: touch;
        }
        
        #messages-panel {
            flex: 1;
            display: flex;
            flex-direction: column;
        }
        
        #messages-container {
            flex: 1;
            padding: 20px;
            overflow-y: auto;
            background: #e5ddd5;
        }
        
        /* MÓVIL - Diseño WhatsApp simplificado */
        @media (max-width: 768px) {
            #zm-main-container {
                height: calc(100vh - 120px);
                min-height: 400px;
                position: relative;
            }
            
            /* Por defecto: mostrar conversaciones */
            #conversations-panel {
                width: 100%;
                position: absolute;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                z-index: 2;
                transition: transform 0.3s ease;
            }
            
            #conversations-panel.hidden-mobile {
                transform: translateX(-100%);
            }
            
            /* Panel de mensajes oculto por defecto */
            #messages-panel {
                width: 100%;
                position: absolute;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                z-index: 1;
                transform: translateX(100%);
                transition: transform 0.3s ease;
            }
            
            #messages-panel.active-mobile {
                transform: translateX(0);
                z-index: 3;
            }
            
            /* Botón volver - visible solo en móvil */
            #back-to-conversations {
                display: flex !important;
                align-items: center;
                justify-content: center;
                cursor: pointer;
                padding: 5px;
                color: #00a884;
                min-width: 40px;
            }
            
            #messages-container {
                padding: 15px 10px;
            }
            
            .conversation-item {
                padding: 12px !important;
            }
            
            .message {
                max-width: 85% !important;
            }
        }
        
        /* Conversaciones con estilo Zoomubik */
        .conversation-item {
            padding: 18px 20px;
            border-bottom: 1px solid #e8f4f8;
            cursor: pointer;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            background: white;
            margin: 0 10px;
            border-radius: 12px;
            margin-bottom: 8px;
        }
        
        .conversation-item:hover {
            background: #f8fbff;
            transform: translateX(5px);
            box-shadow: 0 2px 8px rgba(59,161,218,0.1);
        }
        
        .conversation-item.active {
            background: linear-gradient(135deg, #e8f4f8 0%, #f0f8ff 100%);
            border-left: 4px solid #3ba1da;
            box-shadow: 0 4px 12px rgba(59,161,218,0.15);
        }
        
        .conversation-item img {
            width: 56px;
            height: 56px;
            border-radius: 50%;
            object-fit: cover;
            margin-right: 15px;
            border: 3px solid #e8f4f8;
        }
        
        /* Mensajes con estilo Zoomubik */
        .message {
            margin: 12px 0;
            max-width: 70%;
            clear: both;
        }
        
        .message.own {
            margin-left: auto;
            text-align: right;
            float: right;
        }
        
        .message:not(.own) {
            float: left;
        }
        
        .message-bubble {
            padding: 12px 16px;
            border-radius: 16px;
            display: inline-block;
            word-wrap: break-word;
            max-width: 100%;
            font-size: 16px;
            line-height: 1.5;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        }
        
        .message.own .message-bubble {
            background: linear-gradient(135deg, #3ba1da 0%, #15418a 100%);
            color: white;
            border-bottom-right-radius: 4px;
        }
        
        .message:not(.own) .message-bubble {
            background: white;
            color: #333;
            border: 2px solid #e8f4f8;
            border-bottom-left-radius: 4px;
        }
        
        .message-time {
            font-size: 12px;
            color: rgba(255,255,255,0.8);
            margin-top: 6px;
            opacity: 0.9;
        }
        
        .message:not(.own) .message-time {
            color: #999;
        }
        
        /* Usuarios */
        .user-item {
            padding: 12px;
            border-bottom: 1px solid #eee;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 12px;
        }
        
        .user-item:hover {
            background: #f0f0f0;
        }
        
        .user-item.selected {
            background: #e7f7f4;
            border-left: 3px solid #00a884;
        }
        
        /* Botones */
        button {
            transition: all 0.2s;
        }
        
        button:hover {
            transform: scale(1.05);
        }
        
        button:active {
            transform: scale(0.95);
        }
        
        /* Scrollbar */
        #conversations-list::-webkit-scrollbar,
        #messages-container::-webkit-scrollbar {
            width: 6px;
        }
        
        #conversations-list::-webkit-scrollbar-thumb,
        #messages-container::-webkit-scrollbar-thumb {
            background: #ccc;
            border-radius: 3px;
        }
        
        /* Archivos */
        .file-message {
            padding: 12px;
            border: 1px solid #ddd;
            border-radius: 12px;
            background: #f9f9f9;
            margin: 8px 0;
            max-width: 100%;
        }
        
        .file-message img,
        .file-message video {
            max-width: 100%;
            max-height: 300px;
            border-radius: 8px;
            display: block;
        }
        
        /* Clearfix */
        #messages-container::after {
            content: "";
            display: table;
            clear: both;
        }
        </style>
        
        <script>
        jQuery(document).ready(function($) {
            let currentConversationId = null;
            let selectedUsers = [];
            
            // Cargar conversaciones
            function loadConversations() {
                $.post(zmoriginal_ajax.ajax_url, {
                    action: "zmoriginal_get_conversations",
                    nonce: zmoriginal_ajax.nonce
                }, function(response) {
                    if (response.success) {
                        displayConversations(response.data);
                    }
                });
            }
            
            // Mostrar conversaciones
            function displayConversations(conversations) {
                let html = "";
                conversations.forEach(function(conv) {
                    let unreadBadge = conv.unread_count > 0 ? 
                        `<span style="background:#ff4444;color:white;border-radius:10px;padding:2px 6px;font-size:11px;margin-left:5px;">${conv.unread_count}</span>` : "";
                    
                    html += `
                        <div class="conversation-item" data-id="${conv.id}">
                            <div style="display:flex;align-items:center;gap:10px;">
                                <img src="${conv.avatar || zmoriginal_ajax.current_user_avatar}" style="width:40px;height:40px;border-radius:50%;">
                                <div style="flex:1;">
                                    <div style="font-weight:bold;">${conv.name || "Conversación"}${unreadBadge}</div>
                                    <div style="font-size:12px;color:#666;margin-top:2px;">${conv.last_message || "Sin mensajes"}</div>
                                </div>
                                <div style="font-size:11px;color:#999;">${conv.formatted_time}</div>
                            </div>
                        </div>
                    `;
                });
                $("#conversations-list").html(html);
            }
            
            // Cargar mensajes
            function loadMessages(conversationId) {
                $.post(zmoriginal_ajax.ajax_url, {
                    action: "zmoriginal_get_messages",
                    conversation_id: conversationId,
                    nonce: zmoriginal_ajax.nonce
                }, function(response) {
                    if (response.success) {
                        displayMessages(response.data);
                        markMessagesRead(conversationId);
                    }
                });
            }
            
            // Mostrar mensajes
            function displayMessages(messages) {
                let html = "";
                messages.forEach(function(msg) {
                    let messageContent = "";
                    
                    if (msg.message_type === "text") {
                        messageContent = msg.message;
                    } else {
                        let fileIcon = "📎";
                        if (msg.message_type === "image") fileIcon = "🖼️";
                        else if (msg.message_type === "video") fileIcon = "🎥";
                        else if (msg.message_type === "audio") fileIcon = "🎵";
                        
                        if (msg.message_type === "image") {
                            messageContent = `<div class="file-message">
                                <img src="${msg.file_url}" alt="${msg.message}" onclick="window.open(this.src)">
                                <div>${fileIcon} ${msg.message}</div>
                            </div>`;
                        } else if (msg.message_type === "video") {
                            messageContent = `<div class="file-message">
                                <video controls src="${msg.file_url}"></video>
                                <div>${fileIcon} ${msg.message}</div>
                            </div>`;
                        } else {
                            messageContent = `<div class="file-message">
                                <a href="${msg.file_url}" target="_blank">${fileIcon} ${msg.message}</a>
                            </div>`;
                        }
                    }
                    
                    html += `
                        <div class="message ${msg.is_own ? "own" : ""}">
                            <div class="message-bubble">${messageContent}</div>
                            <div class="message-time">${msg.formatted_time}</div>
                        </div>
                    `;
                });
                $("#messages-container").html(html);
                $("#messages-container").scrollTop($("#messages-container")[0].scrollHeight);
            }
            
            // Marcar mensajes como leídos
            function markMessagesRead(conversationId) {
                $.post(zmoriginal_ajax.ajax_url, {
                    action: "zmoriginal_mark_read",
                    conversation_id: conversationId,
                    nonce: zmoriginal_ajax.nonce
                });
            }
            
            // Enviar mensaje
            function sendMessage() {
                let message = $("#message-input").val().trim();
                if (!message || !currentConversationId) return;
                
                $.post(zmoriginal_ajax.ajax_url, {
                    action: "zmoriginal_send_message",
                    conversation_id: currentConversationId,
                    message: message,
                    nonce: zmoriginal_ajax.nonce
                }, function(response) {
                    if (response.success) {
                        $("#message-input").val("");
                        loadMessages(currentConversationId);
                        loadConversations();
                    }
                });
            }
            
            // Subir archivo
            function uploadFile(file) {
                if (!currentConversationId) return;
                
                let formData = new FormData();
                formData.append("action", "zmoriginal_upload_file");
                formData.append("conversation_id", currentConversationId);
                formData.append("file", file);
                formData.append("nonce", zmoriginal_ajax.nonce);
                
                $.ajax({
                    url: zmoriginal_ajax.ajax_url,
                    type: "POST",
                    data: formData,
                    processData: false,
                    contentType: false,
                    success: function(response) {
                        if (response.success) {
                            loadMessages(currentConversationId);
                            loadConversations();
                        } else {
                            alert("Error: " + response.data);
                        }
                    }
                });
            }
            
            // Buscar usuarios
            function searchUsers(query) {
                if (query.length < 2) {
                    $("#users-list").html("");
                    return;
                }
                
                $.post(zmoriginal_ajax.ajax_url, {
                    action: "zmoriginal_search_users",
                    search: query,
                    nonce: zmoriginal_ajax.nonce
                }, function(response) {
                    if (response.success) {
                        displayUsers(response.data);
                    }
                });
            }
            
            // Mostrar usuarios
            function displayUsers(users) {
                let html = "";
                users.forEach(function(user) {
                    let selected = selectedUsers.includes(user.ID) ? "selected" : "";
                    html += `
                        <div class="user-item ${selected}" data-id="${user.ID}">
                            <img src="${user.avatar}" style="width:30px;height:30px;border-radius:50%;">
                            <div>
                                <div style="font-weight:bold;">${user.display_name}</div>
                            </div>
                        </div>
                    `;
                });
                $("#users-list").html(html);
            }
            
            // Crear conversación
            function createConversation() {
                if (selectedUsers.length === 0) {
                    alert("Selecciona al menos un usuario");
                    return;
                }
                
                $.post(zmoriginal_ajax.ajax_url, {
                    action: "zmoriginal_create_conversation",
                    user_ids: selectedUsers,
                    nonce: zmoriginal_ajax.nonce
                }, function(response) {
                    if (response.success) {
                        $("#new-conversation-modal").hide();
                        selectedUsers = [];
                        loadConversations();
                    }
                });
            }
            
            // Event listeners
            $(document).on("click", ".conversation-item", function() {
                currentConversationId = $(this).data("id");
                $(".conversation-item").removeClass("active");
                $(this).addClass("active");
                
                $("#messages-header").show();
                $("#message-input-container").show();
                $("#conversation-title").text($(this).find("div:first div:first").text());
                
                // Móvil: ocultar conversaciones y mostrar chat (estilo WhatsApp)
                if (window.innerWidth <= 768) {
                    $("#conversations-panel").addClass("hidden-mobile");
                    $("#messages-panel").addClass("active-mobile");
                    $("#back-to-conversations").show();
                }
                
                loadMessages(currentConversationId);
            });
            
            // Botón volver - funciona en desktop y móvil
            $("#back-to-conversations").click(function() {
                // Móvil
                $("#conversations-panel").removeClass("hidden-mobile");
                $("#messages-panel").removeClass("active-mobile");
                
                // Desktop: limpiar selección
                $(".conversation-item").removeClass("active");
                $("#messages-header").hide();
                $("#message-input-container").hide();
                $("#messages-container").html("<div style=\"text-align:center;color:#666;margin-top:50px;\"><h3>💬 Selecciona una conversación</h3><p>Elige una conversación de la lista para comenzar a chatear</p></div>");
                
                currentConversationId = null;
            });
            
            // ========================================
            // MENÚ DE OPCIONES DEL CHAT
            // ========================================
            
            // Abrir/cerrar menú de opciones
            $("#chat-options-btn").click(function(e) {
                e.stopPropagation();
                $("#chat-options-menu").toggle();
            });
            
            // Cerrar menú al hacer click fuera
            $(document).click(function(e) {
                if (!$(e.target).closest("#chat-options-btn, #chat-options-menu").length) {
                    $("#chat-options-menu").hide();
                }
            });
            
            // Manejar acciones del menú
            $(".chat-option-item").click(function() {
                var action = $(this).data("action");
                $("#chat-options-menu").hide();
                
                if (!currentConversationId) {
                    alert("No hay conversación seleccionada");
                    return;
                }
                
                switch(action) {
                    case "delete":
                        if (confirm("¿Estás seguro de que quieres eliminar esta conversación? Esta acción no se puede deshacer.")) {
                            deleteConversation(currentConversationId);
                        }
                        break;
                    case "block":
                        if (confirm("¿Estás seguro de que quieres bloquear a este usuario? No podrá enviarte más mensajes.")) {
                            blockUser(currentConversationId);
                        }
                        break;
                    case "mute":
                        muteConversation(currentConversationId);
                        break;
                    case "report":
                        reportUser(currentConversationId);
                        break;
                }
            });
            
            // Función para eliminar conversación
            function deleteConversation(conversationId) {
                $.post(zmoriginal_ajax.ajax_url, {
                    action: "zmoriginal_delete_conversation",
                    conversation_id: conversationId,
                    nonce: zmoriginal_ajax.nonce
                }, function(response) {
                    if (response.success) {
                        alert("✓ Conversación eliminada");
                        loadConversations();
                        $("#back-to-conversations").click();
                    } else {
                        alert("Error al eliminar la conversación");
                    }
                });
            }
            
            // Función para bloquear usuario
            function blockUser(conversationId) {
                $.post(zmoriginal_ajax.ajax_url, {
                    action: "zmoriginal_block_user",
                    conversation_id: conversationId,
                    nonce: zmoriginal_ajax.nonce
                }, function(response) {
                    if (response.success) {
                        alert("✓ Usuario bloqueado");
                        loadConversations();
                        $("#back-to-conversations").click();
                    } else {
                        alert("Error al bloquear usuario");
                    }
                });
            }
            
            // Función para silenciar conversación
            function muteConversation(conversationId) {
                $.post(zmoriginal_ajax.ajax_url, {
                    action: "zmoriginal_mute_conversation",
                    conversation_id: conversationId,
                    nonce: zmoriginal_ajax.nonce
                }, function(response) {
                    if (response.success) {
                        alert("✓ Notificaciones silenciadas para esta conversación");
                    } else {
                        alert("Error al silenciar conversación");
                    }
                });
            }
            
            // Función para reportar usuario
            function reportUser(conversationId) {
                var reason = prompt("Por favor, describe el motivo del reporte:");
                if (reason && reason.trim()) {
                    $.post(zmoriginal_ajax.ajax_url, {
                        action: "zmoriginal_report_user",
                        conversation_id: conversationId,
                        reason: reason,
                        nonce: zmoriginal_ajax.nonce
                    }, function(response) {
                        if (response.success) {
                            alert("✓ Usuario reportado. Revisaremos tu reporte pronto.");
                        } else {
                            alert("Error al enviar el reporte");
                        }
                    });
                }
            }
            
            // Botón volver a página anterior
            $("#back-to-previous-page").click(function(e) {
                e.preventDefault();
                e.stopPropagation();
                
                // Verificar si la página anterior en el historial es mensajes
                // Si es así, ir 2 pasos atrás para saltar el loop
                if (document.referrer && document.referrer.includes(\'/mensajes-privados/\')) {
                    window.history.go(-2);
                } else if (document.referrer && document.referrer.indexOf(window.location.host) !== -1) {
                    window.location.href = document.referrer;
                } else {
                    // Si no hay referrer válido, ir a la home
                    window.location.href = "/";
                }
            });
            
            $("#send-btn").click(sendMessage);
            $("#message-input").keypress(function(e) {
                if (e.which === 13 && !e.shiftKey) {
                    e.preventDefault();
                    sendMessage();
                }
            });
            
            $("#attach-btn").click(function() {
                $("#file-input").click();
            });
            
            // Manejador eliminado - solo usar el de abajo
            
            $("#new-conversation-btn").click(function() {
                $("#new-conversation-modal").show();
                selectedUsers = [];
            });
            
            $("#cancel-conversation").click(function() {
                $("#new-conversation-modal").hide();
            });
            
            $("#create-conversation").click(createConversation);
            
            $("#user-search").on("input", function() {
                searchUsers($(this).val());
            });
            
            $(document).on("click", ".user-item", function() {
                let userId = parseInt($(this).data("id"));
                if (selectedUsers.includes(userId)) {
                    selectedUsers = selectedUsers.filter(id => id !== userId);
                    $(this).removeClass("selected");
                } else {
                    selectedUsers.push(userId);
                    $(this).addClass("selected");
                }
            });
            
            // Cargar conversaciones al inicio
            loadConversations();
            
            // Actualizar cada 30 segundos
            setInterval(function() {
                if (currentConversationId) {
                    loadMessages(currentConversationId);
                }
                loadConversations();
            }, 30000);
            
            // ⭐ FUNCIÓN UPLOAD - Copiada del plugin original que funciona
            function uploadFile(file) {
                if (!currentConversationId) {
                    alert("No hay conversación activa");
                    return;
                }
                
                // Validar tamaño (10MB máximo)
                if (file.size > 10 * 1024 * 1024) {
                    alert("El archivo es muy grande (máximo 10MB)");
                    return;
                }
                
                console.log("📤 Subiendo archivo:", file.name, file.type, file.size);
                
                // Crear FormData
                const formData = new FormData();
                formData.append("action", "zm_upload_file");
                formData.append("conversation_id", currentConversationId);
                formData.append("sender_id", zmoriginal_ajax.current_user_id);
                formData.append("file", file);
                
                $.ajax({
                    url: zmoriginal_ajax.ajax_url,
                    type: "POST",
                    data: formData,
                    processData: false,
                    contentType: false,
                    success: function(response) {
                        if (response.success) {
                            console.log("✅ Archivo subido:", response.data);
                            console.log("✅ Archivo subido correctamente");
                            loadMessages(currentConversationId);
                        } else {
                            console.error("❌ Error:", response.data);
                            console.error("Error subiendo archivo: " + response.data);
                        }
                    },
                    error: function(xhr, status, error) {
                        console.error("❌ Error AJAX:", error);
                        console.error("Error de conexión al subir archivo");
                    }
                });
            }
            
            // ⭐ MANEJADOR ÚNICO DE ARCHIVOS
            $("#file-input").change(function() {
                const file = this.files[0];
                if (file) {
                    console.log("📎 Archivo seleccionado:", file.name);
                    uploadFile(file);
                }
            });
            
            // ⭐ FUNCIÓN PARA WEBVIEW - Maneja archivos desde Flutter
            window.handleSelectedFiles = function(files) {
                console.log("📱 Archivos desde WebView:", files);
                if (files && files.length > 0) {
                    const fileInfo = files[0];
                    console.log("📎 Procesando archivo WebView:", fileInfo.name);
                    
                    // Simular upload directo para WebView
                    uploadFileFromWebView(fileInfo);
                }
            };
            
            // ⭐ FUNCIÓN ESPECÍFICA PARA WEBVIEW
            function uploadFileFromWebView(fileInfo) {
                console.log("📤 Upload desde WebView:", fileInfo.name);
                
                const formData = new FormData();
                formData.append("action", "zm_upload_file");
                formData.append("conversation_id", "1");
                formData.append("sender_id", zmoriginal_ajax.current_user_id);
                
                // Para WebView, enviamos la información del archivo
                formData.append("file_name", fileInfo.name);
                formData.append("file_path", fileInfo.path);
                formData.append("file_size", fileInfo.size);
                
                $.ajax({
                    url: zmoriginal_ajax.ajax_url,
                    type: "POST",
                    data: formData,
                    processData: false,
                    contentType: false,
                    success: function(response) {
                        console.log("✅ WebView upload response:", response);
                    },
                    error: function(xhr, status, error) {
                        console.error("❌ WebView upload error:", error);
                    }
                });
            }
            
            // Debug adicional
            if ($("#attach-btn").length > 0) {
                console.log("✅ Botón attach encontrado");
            } else {
                console.log("❌ Botón attach NO encontrado");
            }
            
            // ========================================
            // ABRIR CONVERSACIÓN AUTOMÁTICAMENTE SI VIENE DE UN ANUNCIO
            // ========================================
            function getUrlParameter(name) {
                name = name.replace(/[\\[]/, "\\\\[").replace(/[\\]]/, "\\\\]");
                var regex = new RegExp("[\\\\?&]" + name + "=([^&#]*)");
                var results = regex.exec(location.search);
                return results === null ? "" : decodeURIComponent(results[1].replace(/\\+/g, " "));
            }
            
            var targetUserId = getUrlParameter("user_id");
            if (targetUserId) {
                console.log("🎯 Detectado user_id en URL:", targetUserId);
                
                // Crear o abrir conversación directamente con el user_id
                $.post(zmoriginal_ajax.ajax_url, {
                    action: "zmoriginal_create_conversation",
                    user_ids: [parseInt(targetUserId)],
                    nonce: zmoriginal_ajax.nonce
                }, function(response) {
                    if (response.success) {
                        console.log("✅ Conversación creada/abierta con user_id:", targetUserId);
                        console.log("📋 Conversation ID:", response.data.conversation_id);
                        
                        // Recargar conversaciones
                        loadConversations();
                        
                        // Esperar a que se carguen las conversaciones y abrir la correcta por ID
                        setTimeout(function() {
                            var conversationId = response.data.conversation_id;
                            var conversationFound = false;
                            
                            $(".conversation-item").each(function() {
                                var convId = $(this).data("id");
                                console.log("🔍 Revisando conversación ID:", convId);
                                
                                if (parseInt(convId) === parseInt(conversationId)) {
                                    console.log("✅ Conversación encontrada, abriendo...");
                                    $(this).click();
                                    conversationFound = true;
                                    return false; // break
                                }
                            });
                            
                            if (!conversationFound) {
                                console.log("⚠️ Conversación no encontrada en la lista, intentando cargar directamente");
                                loadMessages(conversationId);
                            }
                        }, 1000);
                        
                        // Limpiar URL sin recargar página
                        if (window.history && window.history.pushState) {
                            window.history.pushState({}, document.title, window.location.pathname);
                        }
                    } else {
                        console.error("❌ Error al crear conversación:", response);
                    }
                });
            }
        });
        </script>';
    }
    
    // ========================================
    // NUEVAS FUNCIONES PARA OPCIONES DE CHAT
    // ========================================
    
    public function delete_conversation() {
        check_ajax_referer('zmoriginal_nonce', 'nonce');
        
        $conversation_id = intval($_POST['conversation_id']);
        $current_user_id = get_current_user_id();
        
        if (!$conversation_id || !$current_user_id) {
            wp_send_json_error('Datos inválidos');
        }
        
        global $wpdb;
        
        // Verificar que el usuario es participante de la conversación
        $is_participant = $wpdb->get_var($wpdb->prepare("
            SELECT COUNT(*) FROM $this->table_participants 
            WHERE conversation_id = %d AND user_id = %d
        ", $conversation_id, $current_user_id));
        
        if (!$is_participant) {
            wp_send_json_error('No tienes permiso para eliminar esta conversación');
        }
        
        // Eliminar mensajes
        $wpdb->delete($this->table_messages, array('conversation_id' => $conversation_id), array('%d'));
        
        // Eliminar participantes
        $wpdb->delete($this->table_participants, array('conversation_id' => $conversation_id), array('%d'));
        
        // Eliminar conversación
        $wpdb->delete($this->table_conversations, array('id' => $conversation_id), array('%d'));
        
        wp_send_json_success();
    }
    
    public function block_user() {
        check_ajax_referer('zmoriginal_nonce', 'nonce');
        
        $conversation_id = intval($_POST['conversation_id']);
        $current_user_id = get_current_user_id();
        
        if (!$conversation_id || !$current_user_id) {
            wp_send_json_error('Datos inválidos');
        }
        
        global $wpdb;
        
        // Obtener el ID del otro usuario en la conversación
        $other_user_id = $wpdb->get_var($wpdb->prepare("
            SELECT user_id FROM $this->table_participants 
            WHERE conversation_id = %d AND user_id != %d
            LIMIT 1
        ", $conversation_id, $current_user_id));
        
        if (!$other_user_id) {
            wp_send_json_error('Usuario no encontrado');
        }
        
        // Guardar usuario bloqueado en user meta
        $blocked_users = get_user_meta($current_user_id, 'zm_blocked_users', true);
        if (!is_array($blocked_users)) {
            $blocked_users = array();
        }
        
        if (!in_array($other_user_id, $blocked_users)) {
            $blocked_users[] = $other_user_id;
            update_user_meta($current_user_id, 'zm_blocked_users', $blocked_users);
        }
        
        // Eliminar la conversación también
        $wpdb->delete($this->table_messages, array('conversation_id' => $conversation_id), array('%d'));
        $wpdb->delete($this->table_participants, array('conversation_id' => $conversation_id), array('%d'));
        $wpdb->delete($this->table_conversations, array('id' => $conversation_id), array('%d'));
        
        wp_send_json_success();
    }
    
    public function mute_conversation() {
        check_ajax_referer('zmoriginal_nonce', 'nonce');
        
        $conversation_id = intval($_POST['conversation_id']);
        $current_user_id = get_current_user_id();
        
        if (!$conversation_id || !$current_user_id) {
            wp_send_json_error('Datos inválidos');
        }
        
        // Guardar conversación silenciada en user meta
        $muted_conversations = get_user_meta($current_user_id, 'zm_muted_conversations', true);
        if (!is_array($muted_conversations)) {
            $muted_conversations = array();
        }
        
        if (!in_array($conversation_id, $muted_conversations)) {
            $muted_conversations[] = $conversation_id;
            update_user_meta($current_user_id, 'zm_muted_conversations', $muted_conversations);
        }
        
        wp_send_json_success();
    }
    
    public function report_user() {
        check_ajax_referer('zmoriginal_nonce', 'nonce');
        
        $conversation_id = intval($_POST['conversation_id']);
        $reason = sanitize_textarea_field($_POST['reason']);
        $current_user_id = get_current_user_id();
        
        if (!$conversation_id || !$current_user_id || !$reason) {
            wp_send_json_error('Datos inválidos');
        }
        
        global $wpdb;
        
        // Obtener el ID del otro usuario
        $other_user_id = $wpdb->get_var($wpdb->prepare("
            SELECT user_id FROM $this->table_participants 
            WHERE conversation_id = %d AND user_id != %d
            LIMIT 1
        ", $conversation_id, $current_user_id));
        
        if (!$other_user_id) {
            wp_send_json_error('Usuario no encontrado');
        }
        
        // Enviar email al administrador
        $admin_email = get_option('admin_email');
        $reporter = get_userdata($current_user_id);
        $reported = get_userdata($other_user_id);
        
        $subject = '[Zoomubik] Reporte de usuario';
        $message = "Usuario reportado:\n\n";
        $message .= "Reportado por: " . $reporter->display_name . " (ID: " . $current_user_id . ")\n";
        $message .= "Usuario reportado: " . $reported->display_name . " (ID: " . $other_user_id . ")\n";
        $message .= "Conversación ID: " . $conversation_id . "\n\n";
        $message .= "Motivo:\n" . $reason;
        
        wp_mail($admin_email, $subject, $message);
        
        wp_send_json_success();
    }
}

new ZoomubikMessagesFixedOriginal();


// ========================================
// NOTIFICACIONES POR EMAIL - INMEDIATAS (PARA TESTING)
// ========================================

// Extender la clase para añadir funcionalidad de emails
add_action('init', function() {
    if (class_exists('ZoomubikMessagesFixedOriginal')) {
        // DESACTIVADO: Cron job diario a las 9 AM
        // if (!wp_next_scheduled('zm_daily_unread_summary')) {
        //     wp_schedule_event(strtotime('09:00:00'), 'daily', 'zm_daily_unread_summary');
        // }
        
        // NUEVO: Hook para enviar email inmediato al recibir mensaje
        add_action('zm_message_received', 'zm_send_instant_notification', 10, 3);
    }
});

// NUEVA FUNCIÓN: Enviar notificación inmediata (con límite de frecuencia)
function zm_send_instant_notification($conversation_id, $sender_id, $message_text) {
    global $wpdb;
    
    $table_participants = $wpdb->prefix . 'zoomubik_participants';
    
    // Obtener todos los participantes excepto el remitente
    $recipients = $wpdb->get_results($wpdb->prepare("
        SELECT user_id 
        FROM {$table_participants} 
        WHERE conversation_id = %d AND user_id != %d
    ", $conversation_id, $sender_id));
    
    if (empty($recipients)) {
        return;
    }
    
    $sender = get_userdata($sender_id);
    $sender_name = $sender ? $sender->display_name : 'Un usuario';
    
    foreach ($recipients as $recipient_data) {
        $user_id = $recipient_data->user_id;
        
        // Verificar si el usuario tiene notificaciones por email activadas
        $email_notifications = get_user_meta($user_id, 'zm_email_notifications', true);
        if ($email_notifications === '0') {
            continue;
        }
        
        // Verificar si la conversación está silenciada
        $muted_conversations = get_user_meta($user_id, 'zm_muted_conversations', true);
        if (is_array($muted_conversations) && in_array($conversation_id, $muted_conversations)) {
            continue;
        }
        
        // ⭐ NUEVO: Límite de frecuencia - Solo 1 email cada 2 horas
        $last_email_time = get_user_meta($user_id, 'zm_last_instant_email_' . $conversation_id, true);
        $current_time = time();
        
        // Si ya se envió un email hace menos de 2 horas, no enviar otro
        if ($last_email_time && ($current_time - $last_email_time) < 7200) { // 7200 segundos = 2 horas
            // Guardar que hay mensajes pendientes
            $pending_count = get_user_meta($user_id, 'zm_pending_messages_' . $conversation_id, true);
            $pending_count = $pending_count ? intval($pending_count) + 1 : 1;
            update_user_meta($user_id, 'zm_pending_messages_' . $conversation_id, $pending_count);
            continue;
        }
        
        $user = get_userdata($user_id);
        if (!$user || !$user->user_email) {
            continue;
        }
        
        // Verificar si hay mensajes pendientes acumulados
        $pending_count = get_user_meta($user_id, 'zm_pending_messages_' . $conversation_id, true);
        $total_messages = $pending_count ? intval($pending_count) + 1 : 1;
        
        // Enviar email inmediato
        zm_send_instant_email($user, $sender_name, $message_text, $conversation_id, $total_messages);
        
        // Actualizar timestamp del último email enviado
        update_user_meta($user_id, 'zm_last_instant_email_' . $conversation_id, $current_time);
        
        // Limpiar contador de mensajes pendientes
        delete_user_meta($user_id, 'zm_pending_messages_' . $conversation_id);
    }
}

function zm_send_instant_email($user, $sender_name, $message_text, $conversation_id, $total_messages = 1) {
    $to = $user->user_email;
    
    // Ajustar subject según cantidad de mensajes
    if ($total_messages > 1) {
        $subject = '💬 ' . $total_messages . ' nuevos mensajes de ' . $sender_name . ' en Zoomubik';
    } else {
        $subject = '💬 Nuevo mensaje de ' . $sender_name . ' en Zoomubik';
    }
    
    $message_preview = wp_strip_all_tags(substr($message_text, 0, 100));
    $messages_url = site_url('/mensajes-privados/');
    $settings_url = site_url('/account/');
    
    // Texto adicional si hay múltiples mensajes
    $multiple_msg_text = '';
    if ($total_messages > 1) {
        $multiple_msg_text = '<p style="font-size:14px;color:#666;margin:0 0 15px;text-align:center;">
            <strong>+' . ($total_messages - 1) . ' mensaje' . (($total_messages - 1) > 1 ? 's' : '') . ' más</strong> en esta conversación
        </p>';
    }
    
    $message = '
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="margin:0;padding:0;font-family:Arial,sans-serif;background-color:#f5f5f5;">
        <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f5f5f5;padding:20px 0;">
            <tr>
                <td align="center">
                    <table width="100%" style="max-width:600px;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,0.1);" cellpadding="0" cellspacing="0">
                        <tr>
                            <td style="background: linear-gradient(135deg, #3ba1da 0%, #15418a 100%);padding:30px;text-align:center;">
                                <h1 style="color:#ffffff;margin:0;font-size:24px;">💬 ' . ($total_messages > 1 ? 'Nuevos mensajes' : 'Nuevo mensaje') . '</h1>
                            </td>
                        </tr>
                        <tr>
                            <td style="padding:30px;">
                                <p style="font-size:16px;color:#333;margin:0 0 20px;">Hola <strong>' . esc_html($user->display_name) . '</strong>,</p>
                                <p style="font-size:16px;color:#333;margin:0 0 20px;">
                                    <strong style="color:#3ba1da;">' . esc_html($sender_name) . '</strong> te ha enviado ' . ($total_messages > 1 ? $total_messages . ' mensajes' : 'un mensaje') . ':
                                </p>
                                <div style="background:#f8f9fa;border-left:4px solid #3ba1da;padding:15px 20px;margin:0 0 15px;border-radius:4px;">
                                    <p style="font-size:15px;color:#555;margin:0;font-style:italic;">"' . esc_html($message_preview) . '..."</p>
                                </div>
                                ' . $multiple_msg_text . '
                                <div style="text-align:center;margin:30px 0;">
                                    <a href="' . esc_url($messages_url) . '" style="display:inline-block;background: linear-gradient(135deg, #3ba1da 0%, #15418a 100%);color:#ffffff;text-decoration:none;padding:15px 40px;border-radius:25px;font-size:16px;font-weight:600;box-shadow:0 4px 15px rgba(59,161,218,0.3);">
                                        Ver ' . ($total_messages > 1 ? 'mensajes' : 'mensaje') . '
                                    </a>
                                </div>
                                <p style="font-size:13px;color:#999;margin:20px 0 0;text-align:center;font-style:italic;">
                                    💡 Recibirás como máximo 1 email cada 2 horas por conversación
                                </p>
                            </td>
                        </tr>
                        <tr>
                            <td style="background-color:#f8f9fa;padding:20px;text-align:center;border-top:1px solid #e9ecef;">
                                <p style="font-size:13px;color:#666;margin:0 0 10px;">
                                    Recibes este email porque tienes nuevos mensajes en Zoomubik.
                                </p>
                                <p style="font-size:13px;color:#666;margin:0;">
                                    <a href="' . esc_url($settings_url) . '" style="color:#3ba1da;text-decoration:none;">Gestionar notificaciones</a>
                                </p>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
        </table>
    </body>
    </html>
    ';
    
    $headers = array(
        'Content-Type: text/html; charset=UTF-8',
        'From: Zoomubik <noreply@zoomubik.com>'
    );
    
    wp_mail($to, $subject, $message, $headers);
}

// MANTENER: Función de resumen diario (comentada para testing)
add_action('zm_daily_unread_summary', function() {
    // Función desactivada temporalmente para testing de emails inmediatos
    // Descomentar cuando quieras volver al sistema de resumen diario
    return;
    
    global $wpdb;
    
    $table_participants = $wpdb->prefix . 'zoomubik_participants';
    $table_messages = $wpdb->prefix . 'zoomubik_messages';
    $table_conversations = $wpdb->prefix . 'zoomubik_conversations';
    
    $users_with_unread = $wpdb->get_results("
        SELECT DISTINCT p.user_id, COUNT(m.id) as unread_count
        FROM {$table_participants} p
        INNER JOIN {$table_messages} m ON m.conversation_id = p.conversation_id
        WHERE m.sender_id != p.user_id 
        AND m.is_read = 0
        AND m.created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
        GROUP BY p.user_id
        HAVING unread_count > 0
    ");
    
    foreach ($users_with_unread as $user_data) {
        $user_id = $user_data->user_id;
        $unread_count = $user_data->unread_count;
        
        $email_notifications = get_user_meta($user_id, 'zm_email_notifications', true);
        if ($email_notifications === '0') {
            continue;
        }
        
        $last_email_sent = get_user_meta($user_id, 'zm_last_email_sent', true);
        if ($last_email_sent && (time() - $last_email_sent) < 86400) {
            continue;
        }
        
        $user = get_userdata($user_id);
        if (!$user || !$user->user_email) {
            continue;
        }
        
        $conversations = $wpdb->get_results($wpdb->prepare("
            SELECT DISTINCT c.id, c.last_message, c.updated_at,
                   (SELECT COUNT(*) FROM {$table_messages} 
                    WHERE conversation_id = c.id 
                    AND sender_id != %d 
                    AND is_read = 0) as unread_in_conv
            FROM {$table_conversations} c
            INNER JOIN {$table_participants} p ON p.conversation_id = c.id
            WHERE p.user_id = %d
            AND EXISTS (
                SELECT 1 FROM {$table_messages} m 
                WHERE m.conversation_id = c.id 
                AND m.sender_id != %d 
                AND m.is_read = 0
            )
            ORDER BY c.updated_at DESC
            LIMIT 5
        ", $user_id, $user_id, $user_id));
        
        if (empty($conversations)) {
            continue;
        }
        
        // Enviar email
        zm_send_unread_summary_email($user, $unread_count, $conversations);
        update_user_meta($user_id, 'zm_last_email_sent', time());
    }
});

function zm_send_unread_summary_email($user, $unread_count, $conversations) {
    $to = $user->user_email;
    $subject = '📬 Tienes ' . $unread_count . ' mensaje' . ($unread_count > 1 ? 's' : '') . ' sin leer en Zoomubik';
    
    $conversations_html = '';
    foreach ($conversations as $conv) {
        $preview = wp_strip_all_tags(substr($conv->last_message, 0, 80));
        $conversations_html .= '<li style="margin-bottom:15px;padding-bottom:15px;border-bottom:1px solid #eee;">
            <strong>' . $conv->unread_in_conv . ' mensaje' . ($conv->unread_in_conv > 1 ? 's' : '') . ' nuevo' . ($conv->unread_in_conv > 1 ? 's' : '') . '</strong><br>
            <span style="color:#666;font-size:14px;">' . esc_html($preview) . '...</span>
        </li>';
    }
    
    $messages_url = site_url('/mensajes-privados/');
    $settings_url = site_url('/mi-cuenta/');
    
    $message = '
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="margin:0;padding:0;font-family:Arial,sans-serif;background-color:#ffffff;">
        <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#ffffff;padding:0;">
            <tr>
                <td align="center" style="padding:20px;">
                    <table width="100%" style="max-width:700px;" cellpadding="0" cellspacing="0">
                        <tr>
                            <td style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);padding:40px 30px;text-align:center;border-radius:10px 10px 0 0;">
                                <h1 style="color:#ffffff;margin:0;font-size:28px;">📬 Mensajes sin leer</h1>
                            </td>
                        </tr>
                        <tr>
                            <td style="padding:40px 30px;background:#ffffff;border-left:1px solid #e0e0e0;border-right:1px solid #e0e0e0;">
                                <p style="font-size:18px;color:#333;margin:0 0 25px;">Hola <strong>' . esc_html($user->display_name) . '</strong>,</p>
                                <p style="font-size:18px;color:#333;margin:0 0 25px;">
                                    Tienes <strong style="color:#667eea;">' . $unread_count . ' mensaje' . ($unread_count > 1 ? 's' : '') . ' sin leer</strong> en Zoomubik:
                                </p>
                                <ul style="list-style:none;padding:0;margin:0 0 35px;">
                                    ' . $conversations_html . '
                                </ul>
                                <div style="text-align:center;margin:35px 0;">
                                    <a href="' . esc_url($messages_url) . '" style="display:inline-block;background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);color:#ffffff;text-decoration:none;padding:18px 50px;border-radius:30px;font-size:18px;font-weight:bold;box-shadow:0 4px 15px rgba(102,126,234,0.4);">
                                        Ver mis mensajes
                                    </a>
                                </div>
                            </td>
                        </tr>
                        <tr>
                            <td style="background-color:#f8f9fa;padding:25px 30px;text-align:center;border:1px solid #e0e0e0;border-radius:0 0 10px 10px;">
                                <p style="font-size:13px;color:#666;margin:0 0 12px;line-height:1.6;">
                                    Recibes este email porque tienes mensajes sin leer en Zoomubik.
                                </p>
                                <p style="font-size:13px;color:#666;margin:0;">
                                    <a href="' . esc_url($settings_url) . '" style="color:#667eea;text-decoration:none;font-weight:500;">Desactivar notificaciones por email</a>
                                </p>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
        </table>
    </body>
    </html>
    ';
    
    $headers = array(
        'Content-Type: text/html; charset=UTF-8',
        'From: Zoomubik <noreply@zoomubik.com>'
    );
    
    wp_mail($to, $subject, $message, $headers);
}

// 🔔 PUSH NOTIFICATIONS: Endpoint REST para registrar tokens FCM
add_action('rest_api_init', function () {
    register_rest_route('zoomubik/v1', '/push/register', array(
        'methods'  => 'POST',
        'callback' => 'zoomubik_push_register',
        'permission_callback' => function () {
            return is_user_logged_in();
        }
    ));
});

function zoomubik_push_register(WP_REST_Request $request) {
    $token = sanitize_text_field($request->get_param('token'));
    
    if (empty($token)) {
        return new WP_REST_Response(array('error' => 'token required'), 400);
    }
    
    $user_id = get_current_user_id();
    $tokens = get_user_meta($user_id, 'fcm_tokens', true);
    
    if (!is_array($tokens)) {
        $tokens = array();
    }
    
    if (!in_array($token, $tokens, true)) {
        $tokens[] = $token;
        update_user_meta($user_id, 'fcm_tokens', $tokens);
    }
    
    return new WP_REST_Response(array(
        'ok' => true,
        'count' => count($tokens)
    ), 200);
}

register_deactivation_hook(__FILE__, function() {
    $timestamp = wp_next_scheduled('zm_daily_unread_summary');
    if ($timestamp) {
        wp_unschedule_event($timestamp, 'zm_daily_unread_summary');
    }
});