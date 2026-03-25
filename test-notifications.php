<?php
/**
 * Script de Prueba para Notificaciones Push
 * Uso: Coloca este archivo en la raíz de WordPress y accede a:
 * https://www.zoomubik.com/test-notifications.php?user_id=123&token=TU_TOKEN
 */

// Cargar WordPress
if (file_exists('wp-load.php')) {
    require_once('wp-load.php');
} elseif (file_exists('../wp-load.php')) {
    require_once('../wp-load.php');
} else {
    die('❌ No se pudo cargar WordPress. Asegúrate de que el archivo está en la raíz de WordPress.');
}

if (!is_user_logged_in()) {
    die('❌ Debes iniciar sesión.');
}

if (!current_user_can('manage_options')) {
    die('❌ Acceso denegado. Solo administradores pueden usar esta herramienta.');
}

// Habilitar display de errores para debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

$user_id = intval($_GET['user_id'] ?? 0);
$token = sanitize_text_field($_GET['token'] ?? '');

?>
<!DOCTYPE html>
<html>
<head>
    <title>Test Notificaciones Push - Zoomubik</title>
    <style>
        body { font-family: Arial; max-width: 800px; margin: 50px auto; }
        .container { background: #f5f5f5; padding: 20px; border-radius: 10px; }
        input, button { padding: 10px; margin: 5px; font-size: 14px; }
        button { background: #3ba1da; color: white; border: none; border-radius: 5px; cursor: pointer; }
        button:hover { background: #15418a; }
        .result { margin-top: 20px; padding: 15px; border-radius: 5px; }
        .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
        code { background: #f0f0f0; padding: 2px 5px; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔔 Test Notificaciones Push - Zoomubik</h1>
        
        <form method="GET">
            <div>
                <label>User ID:</label><br>
                <input type="number" name="user_id" value="<?php echo $user_id; ?>" required>
            </div>
            
            <div>
                <label>FCM Token:</label><br>
                <textarea name="token" style="width: 100%; height: 100px;"><?php echo $token; ?></textarea>
            </div>
            
            <button type="submit">Enviar Notificación de Prueba</button>
        </form>

        <?php
        if ($user_id && $token) {
            echo '<div class="result info">';
            echo '<strong>📤 Enviando notificación...</strong><br>';
            
            // Obtener datos del usuario
            $user = get_userdata($user_id);
            if (!$user) {
                echo '<div class="result error">❌ Usuario no encontrado</div>';
            } else {
                echo 'Usuario: <strong>' . $user->display_name . '</strong> (ID: ' . $user_id . ')<br>';
                echo 'Token: <code>' . substr($token, 0, 30) . '...</code><br><br>';
                
                // Instanciar el plugin para usar sus métodos
                global $wpdb;
                
                // Obtener access token
                $credentials_file = defined('ZOOMUBIK_FIREBASE_CREDENTIALS') ? ZOOMUBIK_FIREBASE_CREDENTIALS : '';
                
                if (!file_exists($credentials_file)) {
                    echo '<div class="result error">❌ Archivo de credenciales de Firebase no encontrado: ' . $credentials_file . '</div>';
                } else {
                    echo '✅ Archivo de credenciales encontrado<br>';
                    
                    // Crear JWT y obtener access token
                    $credentials = json_decode(file_get_contents($credentials_file), true);
                    
                    if (!$credentials) {
                        echo '<div class="result error">❌ Error al decodificar credenciales JSON</div>';
                    } else {
                        echo '✅ Credenciales cargadas<br>';
                        
                        // Generar JWT
                        $now = time();
                        $header = base64_encode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
                        $payload = base64_encode(json_encode([
                            'iss' => $credentials['client_email'],
                            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                            'aud' => 'https://oauth2.googleapis.com/token',
                            'iat' => $now,
                            'exp' => $now + 3600
                        ]));
                        
                        $header = str_replace(['+', '/', '='], ['-', '_', ''], $header);
                        $payload = str_replace(['+', '/', '='], ['-', '_', ''], $payload);
                        $signature_input = $header . '.' . $payload;
                        
                        $private_key = openssl_pkey_get_private($credentials['private_key']);
                        if ($private_key === false) {
                            echo '<div class="result error">❌ Error con la clave privada</div>';
                        } else {
                            openssl_sign($signature_input, $signature, $private_key, OPENSSL_ALGO_SHA256);
                            $signature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
                            $jwt = $signature_input . '.' . $signature;
                            
                            echo '✅ JWT generado<br>';
                            
                            // Obtener access token
                            $response = wp_remote_post('https://oauth2.googleapis.com/token', [
                                'body' => [
                                    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                                    'assertion' => $jwt
                                ]
                            ]);
                            
                            if (is_wp_error($response)) {
                                echo '<div class="result error">❌ Error obteniendo access token: ' . $response->get_error_message() . '</div>';
                            } else {
                                $body = json_decode(wp_remote_retrieve_body($response), true);
                                
                                if (!isset($body['access_token'])) {
                                    echo '<div class="result error">❌ No se obtuvo access token: ' . print_r($body, true) . '</div>';
                                } else {
                                    $access_token = $body['access_token'];
                                    echo '✅ Access token obtenido<br>';
                                    
                                    // Enviar notificación
                                    $project_id = 'ios-app-42b04';
                                    $url = 'https://fcm.googleapis.com/v1/projects/' . $project_id . '/messages:send';
                                    
                                    $payload = [
                                        'message' => [
                                            'token' => $token,
                                            'notification' => [
                                                'title' => 'Test Zoomubik',
                                                'body' => 'Esta es una notificación de prueba',
                                            ],
                                            'data' => [
                                                'type' => 'message',
                                                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                                            ],
                                            'apns' => [
                                                'payload' => [
                                                    'aps' => [
                                                        'alert' => [
                                                            'title' => 'Test Zoomubik',
                                                            'body' => 'Esta es una notificación de prueba',
                                                        ],
                                                        'sound' => 'default',
                                                        'badge' => 1,
                                                        'mutable-content' => 1,
                                                    ],
                                                ],
                                            ],
                                        ],
                                    ];
                                    
                                    $fcm_response = wp_remote_post($url, [
                                        'headers' => [
                                            'Authorization' => 'Bearer ' . $access_token,
                                            'Content-Type' => 'application/json',
                                        ],
                                        'body' => json_encode($payload),
                                        'timeout' => 15,
                                    ]);
                                    
                                    if (is_wp_error($fcm_response)) {
                                        echo '<div class="result error">❌ Error enviando a FCM: ' . $fcm_response->get_error_message() . '</div>';
                                    } else {
                                        $fcm_body = json_decode(wp_remote_retrieve_body($fcm_response), true);
                                        $http_code = wp_remote_retrieve_response_code($fcm_response);
                                        
                                        if ($http_code === 200) {
                                            echo '<div class="result success">✅ ¡Notificación enviada correctamente!<br>';
                                            echo 'Message ID: <code>' . $fcm_body['name'] . '</code></div>';
                                        } else {
                                            echo '<div class="result error">❌ Error HTTP ' . $http_code . '<br>';
                                            echo 'Respuesta: <pre>' . json_encode($fcm_body, JSON_PRETTY_PRINT) . '</pre></div>';
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            echo '</div>';
        }
        ?>
        
        <hr>
        
        <h2>📋 Información Útil</h2>
        
        <h3>Usuarios con Tokens Guardados:</h3>
        <?php
        $users_with_tokens = $wpdb->get_results(
            "SELECT u.ID, u.display_name, um.meta_value as token 
             FROM {$wpdb->users} u 
             LEFT JOIN {$wpdb->usermeta} um ON u.ID = um.user_id AND um.meta_key = 'fcm_token' 
             WHERE um.meta_value IS NOT NULL 
             ORDER BY u.ID DESC 
             LIMIT 10"
        );
        
        if (empty($users_with_tokens)) {
            echo '<p>❌ No hay usuarios con tokens guardados</p>';
        } else {
            echo '<table border="1" cellpadding="10" style="width: 100%; border-collapse: collapse;">';
            echo '<tr><th>ID</th><th>Usuario</th><th>Token</th><th>Acción</th></tr>';
            foreach ($users_with_tokens as $u) {
                $token_preview = substr($u->token, 0, 30) . '...';
                echo '<tr>';
                echo '<td>' . $u->ID . '</td>';
                echo '<td>' . $u->display_name . '</td>';
                echo '<td><code>' . $token_preview . '</code></td>';
                echo '<td><a href="?user_id=' . $u->ID . '&token=' . urlencode($u->token) . '">Probar</a></td>';
                echo '</tr>';
            }
            echo '</table>';
        }
        ?>
        
        <h3>Configuración Firebase:</h3>
        <ul>
            <li>Project ID: <code>ios-app-42b04</code></li>
            <li>Credentials File: <code><?php echo $credentials_file ?: 'NO CONFIGURADO'; ?></code></li>
            <li>Credentials Exist: <?php echo file_exists($credentials_file) ? '✅ Sí' : '❌ No'; ?></li>
        </ul>
    </div>
</body>
</html>
