<?php
/**
 * Plugin Name: Zoomubik Messages Fixed - Tablas Originales SECURE
 * Description: Plugin con mejoras de seguridad completas v7.0.0 + Diseño bonito
 * Version: 7.0.0 - SECURE + DISEÑO BONITO
 * Author: Zoomubik
 */

if (!defined('ABSPATH')) exit;

error_log("🔍 Plugin ZoomubikMessagesFixedOriginal cargándose...");

class ZoomubikMessagesFixedOriginal {
    
    private $server_key;
    private $table_conversations;
    private $table_messages;
    private $table_participants;
    private $upload_dir;
    
    private $allowed_mime_types = array(
        'image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp',
        'video/mp4', 'video/quicktime', 'video/x-msvideo',
        'audio/mpeg', 'audio/wav', 'audio/ogg',
        'application/pdf'
    );
    
    private $allowed_extensions = array(
        'jpg', 'jpeg', 'png', 'gif', 'webp',
        'mp4', 'mov', 'avi',
        'mp3', 'wav', 'ogg',
        'pdf'
    );
    
    public function __construct() {
        global $wpdb;
        $this->server_key = defined('ZOOMUBIK_FCM_KEY') ? ZOOMUBIK_FCM_KEY : '';
        $this->table_conversations = $wpdb->prefix . 'zoomubik_conversations';
        $this->table_messages = $wpdb->prefix . 'zoomubik_messages';
        $this->table_participants = $wpdb->prefix . 'zoomubik_participants';
        $upload_dir = wp_upload_dir();
        $this->upload_dir = $upload_dir['basedir'] . '/zoomubik-messages/';
        add_action('init', array($this, 'init'));
        add_action('wp_loaded', array($this, 'check_tables'));
    }
    
    public function init() {
        add_action('wp_ajax_zmoriginal_send_message', array($this, 'send_message'));
        add_action('wp_ajax_zmoriginal_get_conversations', array($this, 'get_conversations'));
        add_action('wp_ajax_zmoriginal_get_messages', array($this, 'get_messages'));
        add_action('wp_ajax_zmoriginal_mark_read', array($this, 'mark_messages_read'));
        add_action('wp_ajax_zmoriginal_get_unread_count', array($this, 'get_unread_count'));
        add_action('wp_ajax_zmoriginal_search_users', array($this, 'search_users'));
        add_action('wp_ajax_zmoriginal_create_conversation', array($this, 'create_conversation'));
        add_action('wp_ajax_zmoriginal_upload_file', array($this, 'upload_file'));
        add_action('wp_ajax_zmoriginal_delete_conversation', array($this, 'delete_conversation'));
        add_action('wp_ajax_zmoriginal_block_user', array($this, 'block_user'));
        add_action('wp_ajax_zmoriginal_mute_conversation', array($this, 'mute_conversation'));
        add_action('wp_ajax_zmoriginal_report_user', array($this, 'report_user'));
        add_action('wp_ajax_zm_upload_file', array($this, 'upload_file'));
        add_action('wp_ajax_nopriv_zm_upload_file', array($this, 'upload_file'));
        add_action('wp_ajax_zm_test', array($this, 'test_endpoint'));
        add_action('wp_ajax_nopriv_zm_test', array($this, 'test_endpoint'));
        add_action('wp_ajax_zm_debug', array($this, 'debug_endpoint'));
        add_action('wp_ajax_nopriv_zm_debug', array($this, 'debug_endpoint'));
        add_action('wp_ajax_nopriv_zmoriginal_flutter_get_unread_count', array($this, 'flutter_get_unread_count'));
        add_action('wp_ajax_zmoriginal_flutter_get_unread_count', array($this, 'flutter_get_unread_count'));
        add_action('wp_ajax_nopriv_zmoriginal_save_fcm_token', array($this, 'save_fcm_token'));
        add_action('wp_ajax_zmoriginal_save_fcm_token', array($this, 'save_fcm_token'));
        add_action('wp_ajax_nopriv_get_nonce', array($this, 'get_nonce'));
        add_action('wp_ajax_get_nonce', array($this, 'get_nonce'));
        // ⭐ NUEVO: Endpoint de prueba de push
        add_action('wp_ajax_zm_test_push', array($this, 'test_push'));
        add_action('wp_ajax_nopriv_zm_test_push', array($this, 'test_push'));
        
        add_shortcode('zoomubik_messages_original_fixed', array($this, 'messages_shortcode'));
        add_action('wp_enqueue_scripts', array($this, 'enqueue_scripts'));
        $this->create_upload_directory();
    }
    
    private function create_upload_directory() {
        if (!file_exists($this->upload_dir)) {
            wp_mkdir_p($this->upload_dir);
            $htaccess_content = "Options -Indexes\n";
            $htaccess_content .= "<Files *.php>\ndeny from all\n</Files>\n";
            $htaccess_content .= "<Files *.phtml>\ndeny from all\n</Files>\n";
            file_put_contents($this->upload_dir . '.htaccess', $htaccess_content);
            file_put_contents($this->upload_dir . 'index.php', '<?php // Silence is golden');
        }
    }
    
    private function validate_file_security($file) {
        $errors = array();
        if ($file['error'] !== UPLOAD_ERR_OK) { $errors[] = 'Error en la subida del archivo'; return $errors; }
        if ($file['size'] > 20 * 1024 * 1024) { $errors[] = 'Archivo demasiado grande (máximo 20MB)'; }
        if (function_exists('finfo_open')) {
            $finfo = finfo_open(FILEINFO_MIME_TYPE);
            $real_mime = finfo_file($finfo, $file['tmp_name']);
            finfo_close($finfo);
            if (!in_array($real_mime, $this->allowed_mime_types)) { $errors[] = 'Tipo de archivo no permitido'; }
        }
        $extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
        if (!in_array($extension, $this->allowed_extensions)) { $errors[] = 'Extensión no permitida'; }
        if (strpos($file['name'], '..') !== false || strpos($file['name'], '/') !== false) { $errors[] = 'Nombre de archivo inválido'; }
        return $errors;
    }
    
    private function sanitize_image($file_path) {
        $extension = strtolower(pathinfo($file_path, PATHINFO_EXTENSION));
        if (!in_array($extension, array('jpg', 'jpeg', 'png', 'gif'))) return true;
        $image = wp_get_image_editor($file_path);
        if (is_wp_error($image)) { error_log("Error al procesar imagen: " . $image->get_error_message()); return false; }
        $saved = $image->save($file_path);
        if (is_wp_error($saved)) { error_log("Error al guardar imagen sanitizada: " . $saved->get_error_message()); return false; }
        return true;
    }
    
    public function check_tables() {
        global $wpdb;
        $table_exists = $wpdb->get_var("SHOW TABLES LIKE '$this->table_conversations'");
        if (!$table_exists) {
            echo '<div style="background:#f8d7da;color:#721c24;padding:15px;margin:20px;border-radius:5px;"><strong>⚠️ ATENCIÓN:</strong> Las tablas originales no existen.</div>';
        }
    }
    
    public function enqueue_scripts() {
        global $post;
        $has_shortcode = false;
        if ($post && (has_shortcode($post->post_content, 'zoomubik_messages_original_fixed') || strpos($post->post_content, '[zoomubik_messages_original_fixed]') !== false)) {
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
        global $wpdb;
        $table_exists = $wpdb->get_var("SHOW TABLES LIKE '$this->table_conversations'");
        if (!$table_exists) {
            return '<div style="background:#f8d7da;color:#721c24;padding:20px;margin:20px 0;border-radius:10px;"><h3>⚠️ Tablas No Encontradas</h3></div>';
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

    public function upload_file() {
        if (isset($_POST['nonce'])) {
            check_ajax_referer('zmoriginal_nonce', 'nonce');
            if (!is_user_logged_in()) wp_die('No autorizado');
        }
        if (!isset($_FILES['file']) && !isset($_POST['conversation_id'])) {
            wp_send_json_success(array('status' => 'Endpoint zm_upload_file funcionando', 'timestamp' => current_time('mysql')));
        }
        if (!isset($_FILES['file']) && isset($_POST['file_name'])) {
            wp_send_json_success(array('message' => 'Archivo recibido desde WebView: ' . $_POST['file_name'], 'source' => 'webview'));
        }
        if (!isset($_FILES['file'])) { wp_send_json_error('No se recibió archivo'); }
        $conversation_id = isset($_POST['conversation_id']) ? intval($_POST['conversation_id']) : 1;
        $sender_id = isset($_POST['sender_id']) ? intval($_POST['sender_id']) : get_current_user_id();
        $file = $_FILES['file'];
        $validation_errors = $this->validate_file_security($file);
        if (!empty($validation_errors)) { wp_send_json_error(implode(', ', $validation_errors)); }
        $file_extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
        $unique_name = wp_generate_password(12, false) . '_' . $sender_id . '_' . time() . '.' . $file_extension;
        $file_path = $this->upload_dir . $unique_name;
        if (!move_uploaded_file($file['tmp_name'], $file_path)) { wp_send_json_error('Error moviendo archivo'); }
        chmod($file_path, 0644);
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $mime_type = finfo_file($finfo, $file_path);
        finfo_close($finfo);
        if (strpos($mime_type, 'image/') === 0) {
            $sanitize_result = $this->sanitize_image($file_path);
            if ($sanitize_result !== true) { if (file_exists($file_path)) unlink($file_path); wp_send_json_error('Error procesando imagen'); }
        }
        $message_type = 'file';
        if (strpos($mime_type, 'image/') === 0) $message_type = 'image';
        elseif (strpos($mime_type, 'video/') === 0) $message_type = 'video';
        elseif (strpos($mime_type, 'audio/') === 0) $message_type = 'audio';
        $file_url = wp_upload_dir()['baseurl'] . '/zoomubik-messages/' . $unique_name;
        global $wpdb;
        $result = $wpdb->insert($this->table_messages, array('conversation_id' => $conversation_id, 'sender_id' => $sender_id, 'message' => sanitize_file_name($file['name']), 'message_type' => $message_type, 'file_url' => $file_url), array('%d', '%d', '%s', '%s', '%s'));
        if ($result === false) { if (file_exists($file_path)) unlink($file_path); wp_send_json_error('Error guardando mensaje'); }
        $message_id = $wpdb->insert_id;
        $wpdb->update($this->table_conversations, array('updated_at' => current_time('mysql')), array('id' => $conversation_id), array('%s'), array('%d'));
        $this->send_push_notifications($conversation_id, $sender_id, "📎 " . sanitize_file_name($file['name']));
        $message_data = $wpdb->get_row($wpdb->prepare("SELECT m.*, u.display_name as sender_name FROM $this->table_messages m JOIN {$wpdb->users} u ON m.sender_id = u.ID WHERE m.id = %d", $message_id));
        wp_send_json_success(array('message' => $message_data, 'formatted_time' => date('H:i', strtotime($message_data->created_at))));
    }
    
    public function test_endpoint() {
        wp_send_json_success(array('status' => 'Plugin funcionando correctamente', 'timestamp' => current_time('mysql')));
    }
    
    public function debug_endpoint() {
        wp_send_json_success(array('message' => 'Debug endpoint funcionando', 'post_data' => $_POST, 'method' => $_SERVER['REQUEST_METHOD']));
    }

    // ⭐ NUEVO: Endpoint de prueba de notificaciones push
    public function test_push() {
        $token = sanitize_text_field($_POST['token']);
        if (empty($token)) {
            wp_send_json_error('Token vacío');
            return;
        }
        $access_token = $this->get_firebase_access_token();
        if (!$access_token) {
            wp_send_json_error('No se pudo obtener access token de Firebase');
            return;
        }
        $this->send_fcm_notification($token, 'Test Zoomubik', 'Notificación de prueba');
        wp_send_json_success('Push enviado correctamente');
    }
    
    public function send_message() {
        check_ajax_referer('zmoriginal_nonce', 'nonce');
        if (!is_user_logged_in()) wp_die('No autorizado');
        $conversation_id = intval($_POST['conversation_id']);
        $message = sanitize_textarea_field($_POST['message']);
        $sender_id = get_current_user_id();
        if (empty($message) || empty($conversation_id)) { wp_send_json_error('Datos incompletos'); }
        global $wpdb;
        $is_participant = $wpdb->get_var($wpdb->prepare("SELECT COUNT(*) FROM $this->table_participants WHERE conversation_id = %d AND user_id = %d", $conversation_id, $sender_id));
        if (!$is_participant) { wp_send_json_error('No tienes permiso para enviar mensajes en esta conversación'); }
        $recent_messages = $wpdb->get_var($wpdb->prepare("SELECT COUNT(*) FROM $this->table_messages WHERE sender_id = %d AND created_at > DATE_SUB(NOW(), INTERVAL 1 MINUTE)", $sender_id));
        if ($recent_messages >= 10) { wp_send_json_error('Demasiados mensajes. Espera un momento antes de enviar más.'); }
        if (!$this->validate_urls_in_message($message)) { wp_send_json_error('El mensaje contiene enlaces no permitidos.'); }
        $result = $wpdb->insert($this->table_messages, array('conversation_id' => $conversation_id, 'sender_id' => $sender_id, 'message' => $message, 'message_type' => 'text'), array('%d', '%d', '%s', '%s'));
        if ($result === false) { wp_send_json_error('Error al enviar mensaje'); }
        $message_id = $wpdb->insert_id;
        $wpdb->update($this->table_conversations, array('updated_at' => current_time('mysql')), array('id' => $conversation_id), array('%s'), array('%d'));
        $this->send_push_notifications($conversation_id, $sender_id, $message);
        do_action('zm_message_received', $conversation_id, $sender_id, $message);
        $message_data = $wpdb->get_row($wpdb->prepare("SELECT m.*, u.display_name as sender_name FROM $this->table_messages m JOIN {$wpdb->users} u ON m.sender_id = u.ID WHERE m.id = %d", $message_id));
        wp_send_json_success(array('message' => $message_data, 'formatted_time' => date('H:i', strtotime($message_data->created_at))));
    }
    
    public function get_conversations() {
        check_ajax_referer('zmoriginal_nonce', 'nonce');
        if (!is_user_logged_in()) wp_die('No autorizado');
        $user_id = get_current_user_id();
        global $wpdb;
        $conversations = $wpdb->get_results($wpdb->prepare("
            SELECT c.*, 
                   (SELECT COUNT(*) FROM $this->table_messages m2 JOIN $this->table_participants p2 ON m2.conversation_id = p2.conversation_id WHERE p2.user_id = %d AND m2.id > p2.last_read_message_id AND m2.conversation_id = c.id AND m2.sender_id != %d) as unread_count,
                   (SELECT m.message FROM $this->table_messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC LIMIT 1) as last_message,
                   (SELECT m.created_at FROM $this->table_messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC LIMIT 1) as last_message_time
            FROM $this->table_conversations c
            JOIN $this->table_participants p ON c.id = p.conversation_id
            WHERE p.user_id = %d
            ORDER BY c.updated_at DESC
        ", $user_id, $user_id, $user_id));
        foreach ($conversations as &$conv) {
            if ($conv->type === 'private' && empty($conv->name)) {
                $other_user = $wpdb->get_row($wpdb->prepare("SELECT u.display_name, u.ID FROM $this->table_participants p JOIN {$wpdb->users} u ON p.user_id = u.ID WHERE p.conversation_id = %d AND p.user_id != %d LIMIT 1", $conv->id, $user_id));
                if ($other_user) {
                    $conv->name = $other_user->display_name;
                    if (function_exists('perfil_avatares_obtener_url_mapa')) { $conv->avatar = perfil_avatares_obtener_url_mapa($other_user->ID); } else { $conv->avatar = get_avatar_url($other_user->ID); }
                }
            }
            $conv->formatted_time = $conv->last_message_time ? date('H:i', strtotime($conv->last_message_time)) : '';
        }
        wp_send_json_success($conversations);
    }
    
    public function get_messages() {
        check_ajax_referer('zmoriginal_nonce', 'nonce');
        if (!is_user_logged_in()) wp_die('No autorizado');
        $conversation_id = intval($_POST['conversation_id']);
        $user_id = get_current_user_id();
        global $wpdb;
        $messages = $wpdb->get_results($wpdb->prepare("SELECT m.*, u.display_name as sender_name, CASE WHEN m.sender_id = %d THEN 1 ELSE 0 END as is_own FROM $this->table_messages m JOIN {$wpdb->users} u ON m.sender_id = u.ID WHERE m.conversation_id = %d ORDER BY m.created_at ASC", $user_id, $conversation_id));
        foreach ($messages as &$message) {
            if (function_exists('perfil_avatares_obtener_url_mapa')) { $message->sender_avatar = perfil_avatares_obtener_url_mapa($message->sender_id); } else { $message->sender_avatar = get_avatar_url($message->sender_id); }
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
        $last_message = $wpdb->get_var($wpdb->prepare("SELECT MAX(id) FROM $this->table_messages WHERE conversation_id = %d", $conversation_id));
        if ($last_message) { 
            $wpdb->update($this->table_participants, array('last_read_message_id' => $last_message), array('conversation_id' => $conversation_id, 'user_id' => $user_id), array('%d'), array('%d', '%d')); 
        }
        wp_send_json_success();
    }
    
    public function get_unread_count() {
        check_ajax_referer('zmoriginal_nonce', 'nonce');
        if (!is_user_logged_in()) wp_die('No autorizado');
        
        $user_id = get_current_user_id();
        global $wpdb;
        
        $unread_count = $wpdb->get_var($wpdb->prepare(
            "SELECT COUNT(DISTINCT m.id) FROM $this->table_messages m 
             JOIN $this->table_participants p ON m.conversation_id = p.conversation_id 
             WHERE p.user_id = %d AND m.id > p.last_read_message_id AND m.sender_id != %d",
            $user_id, $user_id
        ));
        
        wp_send_json_success(array('unread_count' => intval($unread_count)));
    }
    
    public function search_users() {
        check_ajax_referer('zmoriginal_nonce', 'nonce');
        if (!is_user_logged_in()) wp_die('No autorizado');
        $search = sanitize_text_field($_POST['search']);
        $current_user_id = get_current_user_id();
        if (strlen($search) < 2) { wp_send_json_success(array()); }
        global $wpdb;
        $users = $wpdb->get_results($wpdb->prepare("SELECT ID, display_name FROM {$wpdb->users} WHERE display_name LIKE %s AND ID != %d LIMIT 10", '%' . $search . '%', $current_user_id));
        foreach ($users as &$user) {
            if (function_exists('perfil_avatares_obtener_url_mapa')) { $user->avatar = perfil_avatares_obtener_url_mapa($user->ID); } else { $user->avatar = get_avatar_url($user->ID); }
        }
        wp_send_json_success($users);
    }
    
    public function create_conversation() {
        check_ajax_referer('zmoriginal_nonce', 'nonce');
        if (!is_user_logged_in()) wp_die('No autorizado');
        $user_ids = array_map('intval', $_POST['user_ids']);
        $current_user_id = get_current_user_id();
        if (empty($user_ids)) { wp_send_json_error('Selecciona al menos un usuario'); }
        global $wpdb;
        $today_conversations = $wpdb->get_var($wpdb->prepare("SELECT COUNT(DISTINCT c.id) FROM $this->table_conversations c JOIN $this->table_participants p ON c.id = p.conversation_id WHERE p.user_id = %d AND DATE(c.created_at) = CURDATE()", $current_user_id));
        if ($today_conversations >= 20) { wp_send_json_error('Límite de 20 conversaciones por día alcanzado'); }
        $blocked_users = get_user_meta($current_user_id, 'zm_blocked_users', true);
        if (is_array($blocked_users)) { foreach ($user_ids as $user_id) { if (in_array($user_id, $blocked_users)) { wp_send_json_error('No puedes crear conversaciones con usuarios bloqueados'); } } }
        foreach ($user_ids as $user_id) { $their_blocked_users = get_user_meta($user_id, 'zm_blocked_users', true); if (is_array($their_blocked_users) && in_array($current_user_id, $their_blocked_users)) { wp_send_json_error('No puedes crear conversaciones con este usuario'); } }
        $user_ids[] = $current_user_id;
        $user_ids = array_unique($user_ids);
        if (count($user_ids) == 2) {
            $existing = $wpdb->get_var($wpdb->prepare("SELECT c.id FROM $this->table_conversations c JOIN $this->table_participants p1 ON c.id = p1.conversation_id JOIN $this->table_participants p2 ON c.id = p2.conversation_id WHERE c.type = 'private' AND p1.user_id = %d AND p2.user_id = %d AND (SELECT COUNT(*) FROM $this->table_participants p3 WHERE p3.conversation_id = c.id) = 2", $user_ids[0], $user_ids[1]));
            if ($existing) { wp_send_json_success(array('conversation_id' => $existing)); }
        }
        $result = $wpdb->insert($this->table_conversations, array('type' => count($user_ids) == 2 ? 'private' : 'group', 'name' => count($user_ids) == 2 ? '' : 'Grupo'), array('%s', '%s'));
        if ($result === false) { wp_send_json_error('Error creando conversación'); }
        $conversation_id = $wpdb->insert_id;
        foreach ($user_ids as $user_id) { $wpdb->insert($this->table_participants, array('conversation_id' => $conversation_id, 'user_id' => $user_id, 'is_admin' => $user_id == $current_user_id ? 1 : 0), array('%d', '%d', '%d')); }
        wp_send_json_success(array('conversation_id' => $conversation_id));
    }
    
    public function flutter_get_unread_count() {
        $user_id = intval($_REQUEST['user_id']);
        if (!$user_id) wp_die('Usuario no válido');
        global $wpdb;
        $unread_count = $wpdb->get_var($wpdb->prepare("SELECT COUNT(DISTINCT m.id) FROM $this->table_messages m JOIN $this->table_participants p ON m.conversation_id = p.conversation_id WHERE p.user_id = %d AND m.id > p.last_read_message_id AND m.sender_id != %d", $user_id, $user_id));
        wp_send_json_success(array('unread_count' => intval($unread_count)));
    }
    
    public function save_fcm_token() {
        $user_id = intval($_POST['user_id']);
        $token = sanitize_text_field($_POST['token']);
        
        if (!$user_id || !$token) {
            error_log('❌ save_fcm_token: user_id o token vacío');
            wp_send_json_error('Datos incompletos');
            return;
        }
        
        // Guardar token
        update_user_meta($user_id, 'fcm_token', $token);
        error_log('✅ FCM Token guardado para usuario ' . $user_id . ': ' . substr($token, 0, 20) . '...');
        
        wp_send_json_success(array('message' => 'Token guardado correctamente'));
    }
    
    public function get_nonce() {
        wp_send_json_success(array('nonce' => wp_create_nonce('zmoriginal_nonce')));
    }
    
    private function send_push_notifications($conversation_id, $sender_id, $message) {
        global $wpdb;
        
        // Obtener participantes con tokens FCM
        $participants = $wpdb->get_results($wpdb->prepare(
            "SELECT p.user_id, um.meta_value as fcm_token, u.display_name 
             FROM $this->table_participants p 
             LEFT JOIN {$wpdb->usermeta} um ON p.user_id = um.user_id AND um.meta_key = 'fcm_token' 
             JOIN {$wpdb->users} u ON p.user_id = u.ID 
             WHERE p.conversation_id = %d AND p.user_id != %d AND um.meta_value IS NOT NULL",
            $conversation_id, $sender_id
        ));
        
        if (empty($participants)) {
            error_log('⚠️ No hay participantes con tokens FCM en conversación ' . $conversation_id);
            return;
        }
        
        $sender_name = get_userdata($sender_id)->display_name;
        $notification_title = $sender_name;
        $notification_body = substr($message, 0, 100);
        
        error_log('📤 Enviando notificaciones a ' . count($participants) . ' participantes');
        
        foreach ($participants as $participant) {
            if (!empty($participant->fcm_token)) {
                error_log('📬 Enviando a usuario ' . $participant->user_id . ' con token: ' . substr($participant->fcm_token, 0, 20) . '...');
                $this->send_fcm_notification(
                    $participant->fcm_token,
                    $notification_title,
                    $notification_body,
                    array('conversation_id' => $conversation_id)
                );
            }
        }
    }
    
    private function get_firebase_access_token() {
        $credentials_file = defined('ZOOMUBIK_FIREBASE_CREDENTIALS') ? ZOOMUBIK_FIREBASE_CREDENTIALS : '';
        if (!file_exists($credentials_file)) { error_log('❌ Firebase credentials file not found: ' . $credentials_file); return null; }
        $credentials = json_decode(file_get_contents($credentials_file), true);
        if (!$credentials) { error_log('❌ Invalid Firebase credentials JSON'); return null; }
        $now = time();
        $header = base64_encode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
        $payload = base64_encode(json_encode(['iss' => $credentials['client_email'], 'scope' => 'https://www.googleapis.com/auth/firebase.messaging', 'aud' => 'https://oauth2.googleapis.com/token', 'iat' => $now, 'exp' => $now + 3600]));
        $header = str_replace(['+', '/', '='], ['-', '_', ''], $header);
        $payload = str_replace(['+', '/', '='], ['-', '_', ''], $payload);
        $signature_input = $header . '.' . $payload;
        $private_key = openssl_pkey_get_private($credentials['private_key']);
if ($private_key === false) {
    error_log('❌ Invalid private key: ' . openssl_error_string());
    return null;
}

if (!openssl_sign($signature_input, $signature, $private_key, OPENSSL_ALGO_SHA256)) {
    error_log('❌ Error signing JWT: ' . openssl_error_string());
    return null;
}
        $signature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
        $jwt = $signature_input . '.' . $signature;
        $response = wp_remote_post('https://oauth2.googleapis.com/token', ['body' => ['grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer', 'assertion' => $jwt]]);
        if (is_wp_error($response)) { error_log('❌ Error getting access token: ' . $response->get_error_message()); return null; }
        $body = json_decode(wp_remote_retrieve_body($response), true);
        if (!isset($body['access_token'])) { error_log('❌ No access token in response: ' . print_r($body, true)); return null; }
        return $body['access_token'];
    }
    
    private function send_fcm_notification($token, $title, $body, $data = array()) {
        $access_token = $this->get_firebase_access_token();
        if (!$access_token) {
            error_log('❌ No se pudo obtener access token de Firebase');
            return false;
        }
        
        $project_id = 'ios-app-42b04';
        $url = 'https://fcm.googleapis.com/v1/projects/' . $project_id . '/messages:send';
        
        // Construir payload con APNS configurado correctamente para iOS
        $payload = array(
            'message' => array(
                'token' => $token,
                'notification' => array(
                    'title' => $title,
                    'body' => $body,
                ),
                'data' => array_merge(array(
                    'type' => 'message',
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                ), $data),
                'apns' => array(
                    'payload' => array(
                        'aps' => array(
                            'alert' => array(
                                'title' => $title,
                                'body' => $body,
                            ),
                            'sound' => 'default',
                            'badge' => 1,
                            'mutable-content' => 1,
                            'category' => 'MESSAGE_CATEGORY',
                        ),
                        'acme' => array(
                            'type' => 'message',
                        ),
                    ),
                ),
            ),
        );
        
        $response = wp_remote_post($url, array(
            'headers' => array(
                'Authorization' => 'Bearer ' . $access_token,
                'Content-Type' => 'application/json',
            ),
            'body' => json_encode($payload),
            'timeout' => 15,
        ));
        
        if (is_wp_error($response)) {
            error_log('❌ FCM error: ' . $response->get_error_message());
            return false;
        }
        
        $response_body = json_decode(wp_remote_retrieve_body($response), true);
        $http_code = wp_remote_retrieve_response_code($response);
        
        if ($http_code === 200) {
            error_log('✅ FCM enviado correctamente: ' . $response_body['name']);
            return true;
        } else {
            error_log('❌ FCM error HTTP ' . $http_code . ': ' . print_r($response_body, true));
            return false;
        }
    }
    
    private function validate_urls_in_message($message) {
        preg_match_all('#\bhttps?://[^,\s()<>]+(?:\([\w\d]+\)|([^,[:punct:]\s]|/))#', $message, $matches);
        if (empty($matches[0])) return true;
        $blacklist = array('bit.ly', 'tinyurl.com', 'goo.gl', 'ow.ly', 't.co', 'is.gd', 'buff.ly', 'adf.ly', 'bc.vc', 'shorte.st', 'ouo.io', 'sh.st', 'clk.sh', 'linkvertise.com');
        foreach ($matches[0] as $url) {
            $domain = parse_url($url, PHP_URL_HOST);
            if (!$domain) continue;
            $domain = str_replace('www.', '', strtolower($domain));
            foreach ($blacklist as $blocked) { if (strpos($domain, $blocked) !== false) return false; }
        }
        return true;
    }
    
    private function get_html_interface() {
        return '
        <div style="max-width:100%;padding:0 20px;margin:20px auto 0;">
            <button id="back-to-previous-page" style="background:linear-gradient(135deg,#3ba1da 0%,#15418a 100%);border:none;cursor:pointer;padding:12px 24px;border-radius:25px;display:inline-flex;align-items:center;gap:8px;transition:all 0.3s;font-size:15px;color:white;font-weight:500;box-shadow:0 4px 15px rgba(59,161,218,0.3);">
                <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path d="M12 4l1.4 1.4L7.8 11H20v2H7.8l5.6 5.6L12 20l-8-8 8-8z"></path></svg>
                <span>Volver</span>
            </button>
        </div>
        
        <div id="zoomubik-messages-original" style="max-width:100%;margin:0;padding:20px;font-family:-apple-system,BlinkMacSystemFont,\'Segoe UI\',Roboto,sans-serif;">
            <div style="background:linear-gradient(135deg,#3ba1da 0%,#15418a 100%);color:white;padding:30px;border-radius:20px;text-align:center;margin-bottom:30px;box-shadow:0 8px 30px rgba(59,161,218,0.3);">
                <h1 style="margin:0;font-size:32px;font-weight:700;display:flex;align-items:center;justify-content:center;gap:12px;">
                    <svg viewBox="0 0 24 24" width="36" height="36" fill="currentColor"><path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm0 14H6l-2 2V4h16v12z"></path></svg>
                    Mensajes Privados
                </h1>
                <p style="margin:10px 0 0 0;opacity:0.95;font-size:16px;">Conecta con otros usuarios de Zoomubik</p>
            </div>
            
            <div id="zm-main-container" style="display:flex;height:75vh;min-height:600px;border-radius:20px;overflow:hidden;box-shadow:0 8px 30px rgba(0,0,0,0.1);background:white;">
                <div id="conversations-panel" style="width:380px;border-right:2px solid #e8f4f8;background:linear-gradient(180deg,#f8fbff 0%,#ffffff 100%);">
                    <div style="padding:20px;border-bottom:2px solid #e8f4f8;background:white;">
                        <button id="new-conversation-btn" style="width:100%;padding:14px;background:linear-gradient(135deg,#3ba1da 0%,#15418a 100%);color:white;border:none;border-radius:12px;cursor:pointer;font-weight:600;font-size:15px;transition:all 0.3s;box-shadow:0 4px 15px rgba(59,161,218,0.3);display:flex;align-items:center;justify-content:center;gap:8px;">
                            <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z"></path></svg>
                            Nueva Conversación
                        </button>
                    </div>
                    <div id="conversations-list" style="height:calc(100% - 84px);overflow-y:auto;"></div>
                </div>
                
                <div id="messages-panel" style="flex:1;display:flex;flex-direction:column;background:#f0f4f8;">
                    <div id="messages-header" style="padding:20px 25px;border-bottom:2px solid #e8f4f8;background:white;display:none;align-items:center;gap:15px;position:relative;">
                        <button id="back-to-conversations" style="background:transparent;border:none;cursor:pointer;padding:10px;border-radius:50%;transition:background 0.2s;display:flex;align-items:center;justify-content:center;">
                            <svg viewBox="0 0 24 24" width="24" height="24" fill="#3ba1da"><path d="M12 4l1.4 1.4L7.8 11H20v2H7.8l5.6 5.6L12 20l-8-8 8-8z"></path></svg>
                        </button>
                        <img id="conversation-avatar" src="" style="width:48px;height:48px;border-radius:50%;border:3px solid #3ba1da;display:none;">
                        <h3 id="conversation-title" style="margin:0;color:#15418a;flex:1;font-size:20px;font-weight:700;"></h3>
                        <button id="chat-options-btn" style="background:transparent;border:none;cursor:pointer;padding:10px;border-radius:50%;transition:background 0.2s;display:flex;align-items:center;justify-content:center;">
                            <svg viewBox="0 0 24 24" width="24" height="24" fill="#3ba1da"><path d="M12 8c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"></path></svg>
                        </button>
                        <div id="chat-options-menu" style="display:none;position:absolute;top:70px;right:25px;background:white;border:2px solid #e8f4f8;border-radius:12px;box-shadow:0 8px 30px rgba(0,0,0,0.15);min-width:220px;z-index:1000;overflow:hidden;">
                            <div class="chat-option-item" data-action="delete" style="padding:14px 18px;cursor:pointer;border-bottom:1px solid #f0f4f8;display:flex;align-items:center;gap:12px;">
                                <span style="font-size:20px;">🗑️</span><span style="color:#333;font-size:15px;font-weight:500;">Eliminar conversación</span>
                            </div>
                            <div class="chat-option-item" data-action="block" style="padding:14px 18px;cursor:pointer;border-bottom:1px solid #f0f4f8;display:flex;align-items:center;gap:12px;">
                                <span style="font-size:20px;">🚫</span><span style="color:#333;font-size:15px;font-weight:500;">Bloquear usuario</span>
                            </div>
                            <div class="chat-option-item" data-action="mute" style="padding:14px 18px;cursor:pointer;border-bottom:1px solid #f0f4f8;display:flex;align-items:center;gap:12px;">
                                <span style="font-size:20px;">🔕</span><span style="color:#333;font-size:15px;font-weight:500;">Silenciar notificaciones</span>
                            </div>
                            <div class="chat-option-item" data-action="report" style="padding:14px 18px;cursor:pointer;display:flex;align-items:center;gap:12px;">
                                <span style="font-size:20px;">⚠️</span><span style="color:#d32f2f;font-size:15px;font-weight:500;">Reportar usuario</span>
                            </div>
                        </div>
                    </div>
                    
                    <div id="messages-container" style="flex:1;padding:25px;overflow-y:auto;background:#f0f4f8;">
                        <div style="text-align:center;color:#666;margin-top:80px;">
                            <svg viewBox="0 0 24 24" width="64" height="64" fill="#3ba1da" style="opacity:0.5;margin-bottom:20px;"><path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm0 14H6l-2 2V4h16v12z"></path></svg>
                            <h3 style="color:#15418a;font-size:22px;margin:0 0 10px 0;">Selecciona una conversación</h3>
                            <p style="color:#666;font-size:16px;margin:0;">Elige un chat de la lista para comenzar a conversar</p>
                        </div>
                    </div>
                    
                    <div id="message-input-container" style="padding:20px 25px;border-top:2px solid #e8f4f8;background:white;display:none;">
                        <div style="display:flex;gap:12px;align-items:center;">
                            <input type="file" id="file-input" style="display:none;" accept="image/*,video/*,audio/*,.pdf">
                            <button id="attach-btn" style="padding:0;background:transparent;border:none;cursor:pointer;width:48px;height:48px;display:flex;align-items:center;justify-content:center;border-radius:50%;">
                                <svg viewBox="0 0 24 24" width="28" height="28" fill="#3ba1da"><path d="M1.816 15.556v.002c0 1.502.584 2.912 1.646 3.972s2.472 1.647 3.974 1.647a5.58 5.58 0 0 0 3.972-1.645l9.547-9.548c.769-.768 1.147-1.767 1.058-2.817-.079-.968-.548-1.927-1.319-2.698-1.594-1.592-4.068-1.711-5.517-.262l-7.916 7.915c-.881.881-.792 2.25.214 3.261.959.958 2.423 1.053 3.263.215l5.511-5.512c.28-.28.267-.722.053-.936l-.244-.244c-.191-.191-.567-.349-.957.04l-5.506 5.506c-.18.18-.635.127-.976-.214-.098-.097-.576-.613-.213-.973l7.915-7.917c.818-.817 2.267-.699 3.23.262.5.501.802 1.1.849 1.685.051.573-.156 1.111-.589 1.543l-9.547 9.549a3.97 3.97 0 0 1-2.829 1.171 3.975 3.975 0 0 1-2.83-1.173 3.973 3.973 0 0 1-1.172-2.828c0-1.071.415-2.076 1.172-2.83l7.209-7.211c.157-.157.264-.579.028-.814L11.5 4.36a.572.572 0 0 0-.834.018l-7.205 7.207a5.577 5.577 0 0 0-1.645 3.971z"></path></svg>
                            </button>
                            <div style="flex:1;background:#f8fbff;border:2px solid #e8f4f8;border-radius:12px;padding:10px 16px;display:flex;align-items:center;">
                                <textarea id="message-input" placeholder="Escribe tu mensaje..." style="flex:1;border:none;outline:none;resize:none;max-height:120px;font-size:16px;font-family:-apple-system,BlinkMacSystemFont,\'Segoe UI\',Roboto,sans-serif;background:transparent;color:#333;"></textarea>
                            </div>
                            <button id="send-btn" style="padding:0;background:linear-gradient(135deg,#3ba1da 0%,#15418a 100%);border:none;cursor:pointer;width:48px;height:48px;display:flex;align-items:center;justify-content:center;border-radius:50%;box-shadow:0 4px 15px rgba(59,161,218,0.3);">
                                <svg viewBox="0 0 24 24" width="24" height="24" fill="white"><path d="M1.101 21.757L23.8 12.028 1.101 2.3l.011 7.912 13.623 1.816-13.623 1.817-.011 7.912z"></path></svg>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
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
        #zoomubik-messages-original * { box-sizing: border-box; }
        #zm-main-container { display:flex;height:70vh;min-height:500px;border:1px solid #ddd;border-top:none;margin-bottom:40px; }
        #conversations-panel { width:300px;border-right:1px solid #ddd;background:#f8f9fa;display:flex;flex-direction:column; }
        #conversations-list { flex:1;overflow-y:auto;-webkit-overflow-scrolling:touch; }
        #messages-panel { flex:1;display:flex;flex-direction:column; }
        #messages-container { flex:1;padding:20px;overflow-y:auto;background:#e5ddd5; }
        @media (max-width: 768px) {
            #zm-main-container { height:calc(100vh - 120px);min-height:400px;position:relative; }
            #conversations-panel { width:100%;position:absolute;top:0;left:0;right:0;bottom:0;z-index:2;transition:transform 0.3s ease; }
            #conversations-panel.hidden-mobile { transform:translateX(-100%); }
            #messages-panel { width:100%;position:absolute;top:0;left:0;right:0;bottom:0;z-index:1;transform:translateX(100%);transition:transform 0.3s ease; }
            #messages-panel.active-mobile { transform:translateX(0);z-index:3; }
            #back-to-conversations { display:flex !important; }
            #messages-container { padding:15px 10px; }
            .conversation-item { padding:12px !important; }
            .message { max-width:85% !important; }
        }
        .conversation-item { padding:18px 20px;border-bottom:1px solid #e8f4f8;cursor:pointer;transition:all 0.3s;display:flex;align-items:center;background:white;margin:0 10px;border-radius:12px;margin-bottom:8px; }
        .conversation-item:hover { background:#f8fbff;transform:translateX(5px);box-shadow:0 2px 8px rgba(59,161,218,0.1); }
        .conversation-item.active { background:linear-gradient(135deg,#e8f4f8 0%,#f0f8ff 100%);border-left:4px solid #3ba1da;box-shadow:0 4px 12px rgba(59,161,218,0.15); }
        .conversation-item img { width:56px;height:56px;border-radius:50%;object-fit:cover;margin-right:15px;border:3px solid #e8f4f8; }
        .message { margin:12px 0;max-width:70%;clear:both; }
        .message.own { margin-left:auto;text-align:right;float:right; }
        .message:not(.own) { float:left; }
        .message-bubble { padding:12px 16px;border-radius:16px;display:inline-block;word-wrap:break-word;max-width:100%;font-size:16px;line-height:1.5;box-shadow:0 2px 8px rgba(0,0,0,0.08); }
        .message.own .message-bubble { background:linear-gradient(135deg,#3ba1da 0%,#15418a 100%);color:white;border-bottom-right-radius:4px; }
        .message:not(.own) .message-bubble { background:white;color:#333;border:2px solid #e8f4f8;border-bottom-left-radius:4px; }
        .message-time { font-size:12px;color:rgba(255,255,255,0.8);margin-top:6px;opacity:0.9; }
        .message:not(.own) .message-time { color:#999; }
        .user-item { padding:12px;border-bottom:1px solid #eee;cursor:pointer;display:flex;align-items:center;gap:12px; }
        .user-item:hover { background:#f0f0f0; }
        .user-item.selected { background:#e7f7f4;border-left:3px solid #00a884; }
        #conversations-list::-webkit-scrollbar, #messages-container::-webkit-scrollbar { width:6px; }
        #conversations-list::-webkit-scrollbar-thumb, #messages-container::-webkit-scrollbar-thumb { background:#ccc;border-radius:3px; }
        .file-message { padding:12px;border:1px solid #ddd;border-radius:12px;background:#f9f9f9;margin:8px 0;max-width:100%; }
        .file-message img, .file-message video { max-width:100%;max-height:300px;border-radius:8px;display:block; }
        #messages-container::after { content:"";display:table;clear:both; }
        </style>
        
        <script>
        jQuery(document).ready(function($) {
            let currentConversationId = null;
            let selectedUsers = [];
            
            function loadConversations() {
                $.post(zmoriginal_ajax.ajax_url, { action: "zmoriginal_get_conversations", nonce: zmoriginal_ajax.nonce }, function(response) {
                    if (response.success) displayConversations(response.data);
                });
            }
            
            function displayConversations(conversations) {
                let html = "";
                conversations.forEach(function(conv) {
                    let unreadBadge = conv.unread_count > 0 ? `<span style="background:#ff4444;color:white;border-radius:10px;padding:2px 6px;font-size:11px;margin-left:5px;">${conv.unread_count}</span>` : "";
                    html += `<div class="conversation-item" data-id="${conv.id}">
                        <div style="display:flex;align-items:center;gap:10px;">
                            <img src="${conv.avatar || zmoriginal_ajax.current_user_avatar}" style="width:40px;height:40px;border-radius:50%;">
                            <div style="flex:1;">
                                <div style="font-weight:bold;">${conv.name || "Conversación"}${unreadBadge}</div>
                                <div style="font-size:12px;color:#666;margin-top:2px;">${conv.last_message || "Sin mensajes"}</div>
                            </div>
                            <div style="font-size:11px;color:#999;">${conv.formatted_time}</div>
                        </div>
                    </div>`;
                });
                $("#conversations-list").html(html);
            }
            
            function loadMessages(conversationId) {
                $.post(zmoriginal_ajax.ajax_url, { action: "zmoriginal_get_messages", conversation_id: conversationId, nonce: zmoriginal_ajax.nonce }, function(response) {
                    if (response.success) { displayMessages(response.data); markMessagesRead(conversationId); }
                });
            }
            
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
                            messageContent = `<div class="file-message"><img src="${msg.file_url}" alt="${msg.message}" onclick="window.open(this.src)"><div>${fileIcon} ${msg.message}</div></div>`;
                        } else if (msg.message_type === "video") {
                            messageContent = `<div class="file-message"><video controls src="${msg.file_url}"></video><div>${fileIcon} ${msg.message}</div></div>`;
                        } else {
                            messageContent = `<div class="file-message"><a href="${msg.file_url}" target="_blank">${fileIcon} ${msg.message}</a></div>`;
                        }
                    }
                    html += `<div class="message ${msg.is_own ? "own" : ""}"><div class="message-bubble">${messageContent}</div><div class="message-time">${msg.formatted_time}</div></div>`;
                });
                $("#messages-container").html(html);
                $("#messages-container").scrollTop($("#messages-container")[0].scrollHeight);
            }
            
            function markMessagesRead(conversationId) {
                $.post(zmoriginal_ajax.ajax_url, { action: "zmoriginal_mark_read", conversation_id: conversationId, nonce: zmoriginal_ajax.nonce });
            }
            
            function sendMessage() {
                let message = $("#message-input").val().trim();
                if (!message || !currentConversationId) return;
                $.post(zmoriginal_ajax.ajax_url, { action: "zmoriginal_send_message", conversation_id: currentConversationId, message: message, nonce: zmoriginal_ajax.nonce }, function(response) {
                    if (response.success) { $("#message-input").val(""); loadMessages(currentConversationId); loadConversations(); }
                });
            }
            
            function uploadFile(file) {
                if (!currentConversationId) return;
                if (file.size > 10 * 1024 * 1024) { alert("El archivo es muy grande (máximo 10MB)"); return; }
                const formData = new FormData();
                formData.append("action", "zm_upload_file");
                formData.append("conversation_id", currentConversationId);
                formData.append("sender_id", zmoriginal_ajax.current_user_id);
                formData.append("file", file);
                $.ajax({ url: zmoriginal_ajax.ajax_url, type: "POST", data: formData, processData: false, contentType: false, success: function(response) { if (response.success) loadMessages(currentConversationId); else alert("Error: " + response.data); } });
            }
            
            function searchUsers(query) {
                if (query.length < 2) { $("#users-list").html(""); return; }
                $.post(zmoriginal_ajax.ajax_url, { action: "zmoriginal_search_users", search: query, nonce: zmoriginal_ajax.nonce }, function(response) { if (response.success) displayUsers(response.data); });
            }
            
            function displayUsers(users) {
                let html = "";
                users.forEach(function(user) {
                    let selected = selectedUsers.includes(user.ID) ? "selected" : "";
                    html += `<div class="user-item ${selected}" data-id="${user.ID}"><img src="${user.avatar}" style="width:30px;height:30px;border-radius:50%;"><div><div style="font-weight:bold;">${user.display_name}</div></div></div>`;
                });
                $("#users-list").html(html);
            }
            
            function createConversation() {
                if (selectedUsers.length === 0) { alert("Selecciona al menos un usuario"); return; }
                $.post(zmoriginal_ajax.ajax_url, { action: "zmoriginal_create_conversation", user_ids: selectedUsers, nonce: zmoriginal_ajax.nonce }, function(response) {
                    if (response.success) { $("#new-conversation-modal").hide(); selectedUsers = []; loadConversations(); }
                });
            }
            
            $(document).on("click", ".conversation-item", function() {
                currentConversationId = $(this).data("id");
                $(".conversation-item").removeClass("active");
                $(this).addClass("active");
                $("#messages-header").show();
                $("#message-input-container").show();
                $("#conversation-title").text($(this).find("div:first div:first").text());
                if (window.innerWidth <= 768) { $("#conversations-panel").addClass("hidden-mobile"); $("#messages-panel").addClass("active-mobile"); }
                loadMessages(currentConversationId);
            });
            
            $("#back-to-conversations").click(function() {
                $("#conversations-panel").removeClass("hidden-mobile");
                $("#messages-panel").removeClass("active-mobile");
                $(".conversation-item").removeClass("active");
                $("#messages-header").hide();
                $("#message-input-container").hide();
                $("#messages-container").html("<div style=\"text-align:center;color:#666;margin-top:50px;\"><h3>💬 Selecciona una conversación</h3></div>");
                currentConversationId = null;
            });
            
            $("#chat-options-btn").click(function(e) { e.stopPropagation(); $("#chat-options-menu").toggle(); });
            $(document).click(function(e) { if (!$(e.target).closest("#chat-options-btn, #chat-options-menu").length) { $("#chat-options-menu").hide(); } });
            
            $(".chat-option-item").click(function() {
                var action = $(this).data("action");
                $("#chat-options-menu").hide();
                if (!currentConversationId) { alert("No hay conversación seleccionada"); return; }
                switch(action) {
                    case "delete":
                        if (confirm("¿Eliminar esta conversación?")) {
                            $.post(zmoriginal_ajax.ajax_url, { action: "zmoriginal_delete_conversation", conversation_id: currentConversationId, nonce: zmoriginal_ajax.nonce }, function(r) { if (r.success) { alert("✓ Conversación eliminada"); loadConversations(); $("#back-to-conversations").click(); } });
                        }
                        break;
                    case "block":
                        if (confirm("¿Bloquear a este usuario?")) {
                            $.post(zmoriginal_ajax.ajax_url, { action: "zmoriginal_block_user", conversation_id: currentConversationId, nonce: zmoriginal_ajax.nonce }, function(r) { if (r.success) { alert("✓ Usuario bloqueado"); loadConversations(); $("#back-to-conversations").click(); } });
                        }
                        break;
                    case "mute":
                        $.post(zmoriginal_ajax.ajax_url, { action: "zmoriginal_mute_conversation", conversation_id: currentConversationId, nonce: zmoriginal_ajax.nonce }, function(r) { if (r.success) alert("✓ Notificaciones silenciadas"); });
                        break;
                    case "report":
                        var reason = prompt("Motivo del reporte:");
                        if (reason && reason.trim()) {
                            $.post(zmoriginal_ajax.ajax_url, { action: "zmoriginal_report_user", conversation_id: currentConversationId, reason: reason, nonce: zmoriginal_ajax.nonce }, function(r) { if (r.success) alert("✓ Usuario reportado"); });
                        }
                        break;
                }
            });
            
            $("#back-to-previous-page").click(function(e) {
                e.preventDefault();
                e.stopPropagation();
                if (document.referrer && document.referrer.includes(\'/mensajes-privados/\')) { window.history.go(-2); }
                else if (document.referrer && document.referrer.indexOf(window.location.host) !== -1) { window.location.href = document.referrer; }
                else { window.location.href = "/"; }
            });
            
            $("#send-btn").click(sendMessage);
            $("#message-input").keypress(function(e) { if (e.which === 13 && !e.shiftKey) { e.preventDefault(); sendMessage(); } });
            $("#attach-btn").click(function() { $("#file-input").click(); });
            $("#file-input").change(function() { const file = this.files[0]; if (file) uploadFile(file); });
            $("#new-conversation-btn").click(function() { $("#new-conversation-modal").show(); selectedUsers = []; });
            $("#cancel-conversation").click(function() { $("#new-conversation-modal").hide(); });
            $("#create-conversation").click(createConversation);
            $("#user-search").on("input", function() { searchUsers($(this).val()); });
            $(document).on("click", ".user-item", function() {
                let userId = parseInt($(this).data("id"));
                if (selectedUsers.includes(userId)) { selectedUsers = selectedUsers.filter(id => id !== userId); $(this).removeClass("selected"); }
                else { selectedUsers.push(userId); $(this).addClass("selected"); }
            });
            
            loadConversations();
            setInterval(function() { if (currentConversationId) loadMessages(currentConversationId); loadConversations(); }, 30000);
            
            function getUrlParameter(name) {
                name = name.replace(/[\\[]/, "\\\\[").replace(/[\\]]/, "\\\\]");
                var regex = new RegExp("[\\\\?&]" + name + "=([^&#]*)");
                var results = regex.exec(location.search);
                return results === null ? "" : decodeURIComponent(results[1].replace(/\\+/g, " "));
            }
            
            var targetUserId = getUrlParameter("user_id");
            if (targetUserId) {
                $.post(zmoriginal_ajax.ajax_url, { action: "zmoriginal_create_conversation", user_ids: [parseInt(targetUserId)], nonce: zmoriginal_ajax.nonce }, function(response) {
                    if (response.success) {
                        loadConversations();
                        setTimeout(function() {
                            var conversationId = response.data.conversation_id;
                            $(".conversation-item").each(function() { if (parseInt($(this).data("id")) === parseInt(conversationId)) { $(this).click(); return false; } });
                        }, 1000);
                        if (window.history && window.history.pushState) { window.history.pushState({}, document.title, window.location.pathname); }
                    }
                });
            }
        });
        </script>';
    }
    
    public function delete_conversation() {
        check_ajax_referer('zmoriginal_nonce', 'nonce');
        $conversation_id = intval($_POST['conversation_id']);
        $current_user_id = get_current_user_id();
        if (!$conversation_id || !$current_user_id) { wp_send_json_error('Datos inválidos'); }
        global $wpdb;
        $is_participant = $wpdb->get_var($wpdb->prepare("SELECT COUNT(*) FROM $this->table_participants WHERE conversation_id = %d AND user_id = %d", $conversation_id, $current_user_id));
        if (!$is_participant) { wp_send_json_error('No tienes permiso'); }
        $wpdb->delete($this->table_messages, array('conversation_id' => $conversation_id), array('%d'));
        $wpdb->delete($this->table_participants, array('conversation_id' => $conversation_id), array('%d'));
        $wpdb->delete($this->table_conversations, array('id' => $conversation_id), array('%d'));
        wp_send_json_success();
    }
    
    public function block_user() {
        check_ajax_referer('zmoriginal_nonce', 'nonce');
        $conversation_id = intval($_POST['conversation_id']);
        $current_user_id = get_current_user_id();
        if (!$conversation_id || !$current_user_id) { wp_send_json_error('Datos inválidos'); }
        global $wpdb;
        $other_user_id = $wpdb->get_var($wpdb->prepare("SELECT user_id FROM $this->table_participants WHERE conversation_id = %d AND user_id != %d LIMIT 1", $conversation_id, $current_user_id));
        if (!$other_user_id) { wp_send_json_error('Usuario no encontrado'); }
        $blocked_users = get_user_meta($current_user_id, 'zm_blocked_users', true);
        if (!is_array($blocked_users)) $blocked_users = array();
        if (!in_array($other_user_id, $blocked_users)) { $blocked_users[] = $other_user_id; update_user_meta($current_user_id, 'zm_blocked_users', $blocked_users); }
        $wpdb->delete($this->table_messages, array('conversation_id' => $conversation_id), array('%d'));
        $wpdb->delete($this->table_participants, array('conversation_id' => $conversation_id), array('%d'));
        $wpdb->delete($this->table_conversations, array('id' => $conversation_id), array('%d'));
        wp_send_json_success();
    }
    
    public function mute_conversation() {
        check_ajax_referer('zmoriginal_nonce', 'nonce');
        $conversation_id = intval($_POST['conversation_id']);
        $current_user_id = get_current_user_id();
        if (!$conversation_id || !$current_user_id) { wp_send_json_error('Datos inválidos'); }
        $muted_conversations = get_user_meta($current_user_id, 'zm_muted_conversations', true);
        if (!is_array($muted_conversations)) $muted_conversations = array();
        if (!in_array($conversation_id, $muted_conversations)) { $muted_conversations[] = $conversation_id; update_user_meta($current_user_id, 'zm_muted_conversations', $muted_conversations); }
        wp_send_json_success();
    }
    
    public function report_user() {
        check_ajax_referer('zmoriginal_nonce', 'nonce');
        $conversation_id = intval($_POST['conversation_id']);
        $reason = sanitize_textarea_field($_POST['reason']);
        $current_user_id = get_current_user_id();
        if (!$conversation_id || !$current_user_id || !$reason) { wp_send_json_error('Datos inválidos'); }
        global $wpdb;
        $other_user_id = $wpdb->get_var($wpdb->prepare("SELECT user_id FROM $this->table_participants WHERE conversation_id = %d AND user_id != %d LIMIT 1", $conversation_id, $current_user_id));
        if (!$other_user_id) { wp_send_json_error('Usuario no encontrado'); }
        $admin_email = get_option('admin_email');
        $reporter = get_userdata($current_user_id);
        $reported = get_userdata($other_user_id);
        $subject = '[Zoomubik] Reporte de usuario';
        $message = "Reportado por: " . $reporter->display_name . " (ID: " . $current_user_id . ")\nUsuario reportado: " . $reported->display_name . " (ID: " . $other_user_id . ")\nMotivo:\n" . $reason;
        wp_mail($admin_email, $subject, $message);
        wp_send_json_success();
    }
}

new ZoomubikMessagesFixedOriginal();

// ========================================
// NOTIFICACIONES POR EMAIL
// ========================================

add_action('init', function() {
    if (class_exists('ZoomubikMessagesFixedOriginal')) {
        add_action('zm_message_received', 'zm_send_instant_notification', 10, 3);
    }
});

function zm_send_instant_notification($conversation_id, $sender_id, $message_text) {
    global $wpdb;
    $table_participants = $wpdb->prefix . 'zoomubik_participants';
    $recipients = $wpdb->get_results($wpdb->prepare("SELECT user_id FROM {$table_participants} WHERE conversation_id = %d AND user_id != %d", $conversation_id, $sender_id));
    if (empty($recipients)) return;
    $sender = get_userdata($sender_id);
    $sender_name = $sender ? $sender->display_name : 'Un usuario';
    foreach ($recipients as $recipient_data) {
        $user_id = $recipient_data->user_id;
        $email_notifications = get_user_meta($user_id, 'zm_email_notifications', true);
        if ($email_notifications === '0') continue;
        $muted_conversations = get_user_meta($user_id, 'zm_muted_conversations', true);
        if (is_array($muted_conversations) && in_array($conversation_id, $muted_conversations)) continue;
        $last_email_time = get_user_meta($user_id, 'zm_last_instant_email_' . $conversation_id, true);
        $current_time = time();
        if ($last_email_time && ($current_time - $last_email_time) < 7200) {
            $pending_count = get_user_meta($user_id, 'zm_pending_messages_' . $conversation_id, true);
            $pending_count = $pending_count ? intval($pending_count) + 1 : 1;
            update_user_meta($user_id, 'zm_pending_messages_' . $conversation_id, $pending_count);
            continue;
        }
        $user = get_userdata($user_id);
        if (!$user || !$user->user_email) continue;
        $pending_count = get_user_meta($user_id, 'zm_pending_messages_' . $conversation_id, true);
        $total_messages = $pending_count ? intval($pending_count) + 1 : 1;
        zm_send_instant_email($user, $sender_name, $message_text, $conversation_id, $total_messages);
        update_user_meta($user_id, 'zm_last_instant_email_' . $conversation_id, $current_time);
        delete_user_meta($user_id, 'zm_pending_messages_' . $conversation_id);
    }
}

function zm_send_instant_email($user, $sender_name, $message_text, $conversation_id, $total_messages = 1) {
    $to = $user->user_email;
    $subject = $total_messages > 1 ? '💬 ' . $total_messages . ' nuevos mensajes de ' . $sender_name . ' en Zoomubik' : '💬 Nuevo mensaje de ' . $sender_name . ' en Zoomubik';
    $message_preview = wp_strip_all_tags(substr($message_text, 0, 100));
    $messages_url = site_url('/mensajes-privados/');
    $settings_url = site_url('/account/');
    $message = '<!DOCTYPE html><html><head><meta charset="UTF-8"></head><body style="margin:0;padding:0;font-family:Arial,sans-serif;background-color:#f5f5f5;">
        <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f5f5f5;padding:20px 0;"><tr><td align="center">
        <table width="100%" style="max-width:600px;background:#ffffff;border-radius:12px;overflow:hidden;" cellpadding="0" cellspacing="0">
            <tr><td style="background:linear-gradient(135deg,#3ba1da 0%,#15418a 100%);padding:30px;text-align:center;"><h1 style="color:#ffffff;margin:0;font-size:24px;">💬 ' . ($total_messages > 1 ? 'Nuevos mensajes' : 'Nuevo mensaje') . '</h1></td></tr>
            <tr><td style="padding:30px;">
                <p style="font-size:16px;color:#333;margin:0 0 20px;">Hola <strong>' . esc_html($user->display_name) . '</strong>,</p>
                <p style="font-size:16px;color:#333;margin:0 0 20px;"><strong style="color:#3ba1da;">' . esc_html($sender_name) . '</strong> te ha enviado ' . ($total_messages > 1 ? $total_messages . ' mensajes' : 'un mensaje') . ':</p>
                <div style="background:#f8f9fa;border-left:4px solid #3ba1da;padding:15px 20px;margin:0 0 15px;border-radius:4px;"><p style="font-size:15px;color:#555;margin:0;font-style:italic;">"' . esc_html($message_preview) . '..."</p></div>
                <div style="text-align:center;margin:30px 0;"><a href="' . esc_url($messages_url) . '" style="display:inline-block;background:linear-gradient(135deg,#3ba1da 0%,#15418a 100%);color:#ffffff;text-decoration:none;padding:15px 40px;border-radius:25px;font-size:16px;font-weight:600;">Ver mensaje</a></div>
            </td></tr>
            <tr><td style="background-color:#f8f9fa;padding:20px;text-align:center;border-top:1px solid #e9ecef;">
                <p style="font-size:13px;color:#666;margin:0;"><a href="' . esc_url($settings_url) . '" style="color:#3ba1da;text-decoration:none;">Gestionar notificaciones</a></p>
            </td></tr>
        </table></td></tr></table></body></html>';
    $headers = array('Content-Type: text/html; charset=UTF-8', 'From: Zoomubik <noreply@zoomubik.com>');
    wp_mail($to, $subject, $message, $headers);
}

add_action('rest_api_init', function () {
    register_rest_route('zoomubik/v1', '/push/register', array(
        'methods' => 'POST',
        'callback' => 'zoomubik_push_register',
        'permission_callback' => function () { return is_user_logged_in(); }
    ));
});

function zoomubik_push_register(WP_REST_Request $request) {
    $token = sanitize_text_field($request->get_param('token'));
    if (empty($token)) return new WP_REST_Response(array('error' => 'token required'), 400);
    $user_id = get_current_user_id();
    update_user_meta($user_id, 'fcm_token', $token);
    return new WP_REST_Response(array('ok' => true), 200);
}

register_deactivation_hook(__FILE__, function() {
    $timestamp = wp_next_scheduled('zm_daily_unread_summary');
    if ($timestamp) wp_unschedule_event($timestamp, 'zm_daily_unread_summary');
});


// === LOGIN AUTOMÁTICO PARA FLUTTER ===
add_action('wp_ajax_nopriv_zm_flutter_login', function() {
    $email = sanitize_email($_POST['email'] ?? '');
    $password = sanitize_text_field($_POST['password'] ?? '');
    
    if (empty($email) || empty($password)) {
        wp_send_json_error('Email o contraseña vacíos');
        return;
    }
    
    $user = wp_authenticate($email, $password);
    
    if (is_wp_error($user)) {
        wp_send_json_error('Credenciales inválidas');
        return;
    }
    
    wp_set_current_user($user->ID);
    wp_set_auth_cookie($user->ID, true);
    
    wp_send_json_success(array(
        'user_id' => $user->ID,
        'display_name' => $user->display_name,
        'email' => $user->user_email
    ));
});

add_action('wp_ajax_zm_flutter_login', function() {
    do_action('wp_ajax_nopriv_zm_flutter_login');
});


// === TOKEN DE SESIÓN PERSISTENTE ===
add_action('wp_ajax_nopriv_zm_get_session_token', function() {
    $user_id = intval($_POST['user_id'] ?? 0);
    if (!$user_id) {
        wp_send_json_error('User ID requerido');
        return;
    }
    
    $token = bin2hex(random_bytes(32));
    update_user_meta($user_id, 'zm_session_token', $token);
    
    error_log('✅ Token de sesión generado para usuario ' . $user_id);
    wp_send_json_success(array('token' => $token));
});

add_action('wp_ajax_zm_get_session_token', function() {
    do_action('wp_ajax_nopriv_zm_get_session_token');
});

// Verificar token y restaurar sesión
add_action('wp_ajax_nopriv_zm_restore_session', function() {
    $user_id = intval($_POST['user_id'] ?? 0);
    $token = sanitize_text_field($_POST['token'] ?? '');
    
    if (!$user_id || !$token) {
        wp_send_json_error('Datos incompletos');
        return;
    }
    
    $stored_token = get_user_meta($user_id, 'zm_session_token', true);
    
    if ($stored_token === $token) {
        wp_set_current_user($user_id);
        wp_set_auth_cookie($user_id, true);
        error_log('✅ Sesión restaurada para usuario ' . $user_id);
        wp_send_json_success(array('user_id' => $user_id));
    } else {
        error_log('❌ Token inválido para usuario ' . $user_id);
        wp_send_json_error('Token inválido');
    }
});

add_action('wp_ajax_zm_restore_session', function() {
    do_action('wp_ajax_nopriv_zm_restore_session');
});
