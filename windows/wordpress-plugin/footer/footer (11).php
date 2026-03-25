<?php
/**
 * The template for displaying the footer.
 *
 * @package Astra
 * @since 1.0.0
 */

if ( ! defined( 'ABSPATH' ) ) exit;
?>

<?php astra_content_bottom(); ?>

	</div> <!-- ast-container -->

	</div><!-- #content -->

	<?php
		astra_content_after();

		astra_footer_before();

		astra_footer();

		astra_footer_after();
	?>

</div><!-- #page -->

<?php
	astra_body_bottom();

// Obtener URL de login Ultimate Member y registro
$um_login_url = function_exists('um_get_core_page_id') ? get_permalink( um_get_core_page_id('login') ) : home_url('/login/');
$um_register_form_id = '17';
$is_logged_in = is_user_logged_in();
$current_user = wp_get_current_user();
$profile_url = $is_logged_in ? home_url( '/user/' . $current_user->user_nicename . '/' ) : $um_login_url;
$edit_profile_url = $is_logged_in ? home_url( '/user/' . $current_user->user_nicename . '/?um_action=edit' ) : $um_login_url;
$account_url = home_url( '/account/' );
$um_logout_url = home_url( '/logout/' );
$play_store_url = 'https://play.google.com/store/apps/details?id=com.zoomubik.webview&hl=es';
$play_badge_img = 'https://zoomubik.com/wp-content/uploads/2025/11/es_badge_web_generic.png';
$messages_url = home_url( '/mensajes-privados/' );
?>

<!-- ========== FOOTER PRINCIPAL CON ENLACES ========== -->
<footer class="footer-principal">
    <div class="footer-container">
        <div class="footer-columnas">
            <div class="footer-columna">
                <h3>Sobre Zoomubik</h3>
                <p>La plataforma que conecta a personas que buscan vivienda con propietarios e inmobiliarias. Publica gratis y encuentra tu hogar ideal.</p>
                <div class="footer-redes-sociales">
                    <a href="https://facebook.com/zoomubik" target="_blank" rel="noopener" aria-label="Facebook">
                        <svg width="24" height="24" fill="currentColor" viewBox="0 0 24 24"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>
                    </a>
                    <a href="https://twitter.com/zoomubik" target="_blank" rel="noopener" aria-label="Twitter">
                        <svg width="24" height="24" fill="currentColor" viewBox="0 0 24 24"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg>
                    </a>
                    <a href="https://instagram.com/zoomubik" target="_blank" rel="noopener" aria-label="Instagram">
                        <svg width="24" height="24" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/></svg>
                    </a>
                </div>
            </div>
            <div class="footer-columna">
                <h3>Enlaces rápidos</h3>
                <ul class="footer-links">
                    <li><a href="<?php echo home_url('/'); ?>">Inicio</a></li>
                    <li><a href="<?php echo home_url('/como-funciona-zoomubik/'); ?>">Cómo funciona Zoomubik</a></li>
                    <li><a href="<?php echo home_url('/desean-alquilar-vivienda/'); ?>">Alquilar vivienda</a></li>
                    <li><a href="<?php echo home_url('/desean-comprar-vivienda/'); ?>">Comprar vivienda</a></li>
                    <li><a href="<?php echo home_url('/desean-alquilar-habitacion/'); ?>">Compartir piso</a></li>
                    <li><a href="<?php echo home_url('/blog/'); ?>">Blog</a></li>
                </ul>
            </div>
            <div class="footer-columna">
                <h3>Legal</h3>
                <ul class="footer-links">
                    <li><a href="<?php echo home_url('/aviso-legal/'); ?>">Aviso Legal</a></li>
                    <li><a href="<?php echo home_url('/politica-privacidad/'); ?>">Política de Privacidad</a></li>
                    <li><a href="<?php echo home_url('/politica-cookies/'); ?>">Política de Cookies</a></li>
                    <li><a href="<?php echo home_url('/rgpd/'); ?>">RGPD</a></li>
                    <li><a href="<?php echo home_url('/terminos-condiciones/'); ?>">Términos y Condiciones</a></li>
                </ul>
            </div>
            <div class="footer-columna">
                <h3>Contacto</h3>
                <ul class="footer-contacto">
                    <li>
                        <svg width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>
                        <a href="mailto:soporte@zoomubik.com">soporte@zoomubik.com</a>
                    </li>
                    <li>
                        <svg width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/><path d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
                        <span>España</span>
                    </li>
                </ul>
                <a href="<?php echo home_url('/contacto/'); ?>" class="footer-btn-contacto">Formulario de contacto</a>
            </div>
        </div>
        
        <!-- SECCIÓN APP + COPYRIGHT -->
        <div class="footer-app-section">
            <a href="<?php echo esc_url($play_store_url); ?>" target="_blank" rel="noopener noreferrer" class="footer-app-badge" aria-label="Descargar en Google Play">
                <img src="<?php echo esc_url($play_badge_img); ?>" alt="Disponible en Google Play">
            </a>
            <div class="footer-copyright">
                <p>&copy; <?php echo date('Y'); ?> Zoomubik. Todos los derechos reservados.</p>
                <p class="footer-slogan">Encuentra tu hogar, comparte tu espacio</p>
            </div>
        </div>
    </div>
</footer>

<style>
/* OCULTAR COPYRIGHT DUPLICADO Y BARRAS GRISES DEL TEMA ASTRA */
.ast-footer-copyright,
.site-info,
.ast-small-footer,
.ast-small-footer-wrap,
footer .site-info,
.site-footer .site-info,
.ast-footer-bar,
.ast-footer-bar-wrap,
.site-footer,
#colophon,
.ast-footer-overlay {
    display: none !important;
}

/* Eliminar padding/margin extra del contenedor principal */
#page {
    margin-bottom: 0 !important;
    padding-bottom: 0 !important;
}

.site-content {
    margin-bottom: 0 !important;
    padding-bottom: 0 !important;
}

.footer-principal{background:linear-gradient(135deg,#3ba1da 0%,#15418a 100%);color:white;padding:40px 20px 0 20px;margin-top:40px}
.footer-container{max-width:1200px;margin:0 auto}
.footer-columnas{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:40px;margin-bottom:30px}
.footer-columna h3{color:#ffe082;font-size:1.2em;margin-bottom:20px;font-weight:600}
.footer-columna p{line-height:1.6;margin-bottom:20px;opacity:.9}
.footer-links{list-style:none;padding:0;margin:0}
.footer-links li{margin-bottom:12px}
.footer-links a{color:white;text-decoration:none;transition:all .3s;display:inline-block;opacity:.9}
.footer-links a:hover{opacity:1;transform:translateX(5px);color:#ffe082}
.footer-contacto{list-style:none;padding:0;margin:0 0 20px 0}
.footer-contacto li{display:flex;align-items:center;gap:10px;margin-bottom:15px;opacity:.9}
.footer-contacto svg{flex-shrink:0}
.footer-contacto a{color:white;text-decoration:none;transition:color .3s}
.footer-contacto a:hover{color:#ffe082}
.footer-btn-contacto{display:inline-block;background:#ffe082;color:#15418a;padding:12px 24px;border-radius:8px;text-decoration:none;font-weight:600;transition:all .3s;margin-top:10px}
.footer-btn-contacto:hover{background:#ffd54f;transform:translateY(-2px);box-shadow:0 4px 12px rgba(255,224,130,.3)}
.footer-redes-sociales{display:flex;gap:15px;margin-top:20px}
.footer-redes-sociales a{display:flex;align-items:center;justify-content:center;width:40px;height:40px;background:rgba(255,255,255,.1);border-radius:50%;color:white;transition:all .3s}
.footer-redes-sociales a:hover{background:#ffe082;color:#15418a;transform:translateY(-3px)}

/* SECCIÓN GOOGLE PLAY + COPYRIGHT */
.footer-app-section{text-align:center;padding:25px 20px 15px 20px;border-top:1px solid rgba(255,255,255,.2);margin-top:20px}
.footer-app-badge{display:inline-block;margin-bottom:15px}
.footer-app-badge img{max-width:180px;height:auto;transition:transform .3s}
.footer-app-badge:hover img{transform:scale(1.05)}
.footer-copyright{text-align:center;padding-bottom:15px}
.footer-copyright p{margin:5px 0;opacity:.85;font-size:0.95em}
.footer-slogan{font-style:italic;color:#ffe082;font-size:0.9em}

@media (max-width:768px){
    .footer-principal{padding:40px 15px 0 15px;margin-top:50px}
    .footer-columnas{grid-template-columns:1fr;gap:30px}
    .footer-columna h3{font-size:1.1em}
    .footer-app-section{padding:20px 15px 10px 15px}
    .footer-app-badge img{max-width:160px}
    .footer-copyright{padding-bottom:80px}
}
@media (max-width:480px){
    .footer-principal{padding:30px 10px 0 10px}
    .footer-btn-contacto{width:100%;text-align:center}
    .footer-app-badge img{max-width:150px}
}
</style>

<?php wp_footer(); ?>

<!-- MODAL LOGIN Y REGISTRO -->
<div id="footer-login-modal" class="modal-login-overlay" style="display:none;">
    <div class="modal-login-content">
        <button id="footer-login-modal-close" class="modal-close" aria-label="Cerrar">&times;</button>
        
        <?php if(!$is_logged_in): ?>
            <h2>Inicia sesión</h2>
            <div class="modal-login-buttons" id="modal-login-buttons">
                <?php echo do_shortcode('[nextend_social_login provider="google" label="Continua con Google"]'); ?>
                <button class="btn-email-login" onclick="window.location.href='<?php echo esc_url($um_login_url); ?>'">Continuar con email</button>
                <span class="modal-register-link" id="open-email-register">¿No tienes cuenta? Regístrate</span>
            </div>
            
            <div id="email-register-form" style="display:none;">
                <h3>Registro por email</h3>
                <?php echo do_shortcode('[ultimatemember form_id="' . esc_attr($um_register_form_id) . '"]'); ?>
                <a href="#" id="back-to-login" style="display:block;margin-top:10px; color:#2563eb; text-decoration:underline;">Volver</a>
            </div>
        <?php else: ?>
            <h2>Ya has iniciado sesión</h2>
            <p>¡Ya puedes publicar, guardar favoritos y enviar mensajes!</p>
            <button id="footer-login-modal-close2" class="btn-email-login" style="margin-top:20px;">Cerrar</button>
        <?php endif; ?>
    </div>
</div>

<!-- Sticky Footer -->
<div class="mobile-footer-sticky">
    <!-- INICIO -->
    <a href="<?php echo esc_url(home_url('/')); ?>" class="tab-btn tab-btn-inicio" id="footer-inicio-btn">
        <!-- Icono casa SVG -->
        <svg width="24" height="24" viewBox="0 0 32 32" fill="none">
            <path d="M4 14L16 4L28 14" stroke="#2563eb" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
            <rect x="8" y="14" width="16" height="12" rx="2" stroke="#176ab5" stroke-width="3"/>
        </svg>
        <span>Inicio</span>
    </a>

    <a href="/mis-favoritos" class="tab-btn tab-btn-favoritos" id="footer-favoritos-btn">
        <!-- Icono corazón SVG -->
        <svg width="24" height="24" fill="none" stroke="#e11d48" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M12 21C12 21 5 13.5 5 8.5C5 6.01472 7.01472 4 9.5 4C11.1569 4 12 5.34315 12 5.34315C12 5.34315 12.8431 4 14.5 4C16.9853 4 19 6.01472 19 8.5C19 13.5 12 21 12 21Z"/>
        </svg>
        <span>Favoritos</span>
    </a>

    <a href="#" id="sticky-publicar-btn" class="tab-btn tab-btn-center neon-publicar-btn">
        <!-- Icono "+" en recuadro SVG con borde neón -->
        <svg width="24" height="24" viewBox="0 0 44 44" fill="none">
            <defs>
                <linearGradient id="neonGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" style="stop-color:#9c27b0;stop-opacity:1" />
                    <stop offset="25%" style="stop-color:#ff9800;stop-opacity:1" />
                    <stop offset="50%" style="stop-color:#4ecdc4;stop-opacity:1" />
                    <stop offset="75%" style="stop-color:#00e676;stop-opacity:1" />
                    <stop offset="100%" style="stop-color:#9c27b0;stop-opacity:1" />
                </linearGradient>
            </defs>
            <rect x="2" y="2" width="40" height="40" rx="8" fill="#2563eb"/>
            <rect x="2" y="2" width="40" height="40" rx="8" fill="none" stroke="url(#neonGradient)" stroke-width="2.5"/>
            <line x1="22" y1="13" x2="22" y2="31" stroke="white" stroke-width="3" stroke-linecap="round"/>
            <line x1="13" y1="22" x2="31" y2="22" stroke="white" stroke-width="3" stroke-linecap="round"/>
        </svg>
        <span>Publicar</span>
    </a>

    <!-- MENSAJES CON CONTADOR -->
    <a href="<?php echo $is_logged_in ? esc_url($messages_url) : '#'; ?>" class="tab-btn tab-btn-mensajes" id="footer-mensajes-btn">
        <div class="mensajes-icon-container">
            <!-- Icono chat SVG -->
            <svg width="24" height="24" fill="none" stroke="#2563eb" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2z"/>
            </svg>
            <!-- Badge de mensajes no leídos -->
            <span id="mensajes-badge" class="mensajes-badge" style="display:none;">0</span>
        </div>
        <span>Mensajes</span>
    </a>

    <a href="#" class="tab-btn tab-btn-cuenta" id="footer-cuenta-btn">
        <!-- Icono usuario SVG -->
        <svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
            <circle cx="12" cy="7" r="4"/>
        </svg>
        <span>Cuenta</span>
    </a>
        
    <div class="cuenta-menu-modern" id="footer-cuenta-menu" style="display:none;">
        <?php if ( $is_logged_in ) : ?>
            <!-- Header con nombre de usuario -->
            <div class="cuenta-menu-header">
                <div class="cuenta-user-avatar">
                    <?php 
                    // Usar avatar del plugin de avatares
                    $avatar_url = '';
                    if (function_exists('perfil_avatares_obtener_url_mapa')) {
                        $avatar_url = perfil_avatares_obtener_url_mapa($current_user->ID);
                    }
                    if (empty($avatar_url)) {
                        $avatar_url = home_url('/wp-content/uploads/2025/06/postaldrem_avatar.jpg');
                    }
                    ?>
                    <img src="<?php echo esc_url($avatar_url); ?>" alt="<?php echo esc_attr($current_user->display_name); ?>" class="cuenta-avatar-img">
                </div>
                <div class="cuenta-user-info">
                    <p class="cuenta-user-name"><?php echo esc_html( $current_user->display_name ); ?></p>
                    <p class="cuenta-user-email"><?php echo esc_html( $current_user->user_email ); ?></p>
                </div>
            </div>
            
            <div class="cuenta-menu-divider"></div>
            
            <!-- Opciones principales -->
            <a href="<?php echo esc_url( $account_url ); ?>" class="cuenta-menu-item cuenta-menu-item-cuenta">
                <span class="cuenta-menu-icon">⚙️</span>
                <span class="cuenta-menu-text">Mi cuenta</span>
            </a>
            <a href="<?php echo home_url('/mis-anuncios/'); ?>" class="cuenta-menu-item cuenta-menu-item-anuncios">
                <span class="cuenta-menu-icon">📋</span>
                <span class="cuenta-menu-text">Mis anuncios</span>
            </a>
            <a href="<?php echo home_url('/mi-avatar/'); ?>" class="cuenta-menu-item cuenta-menu-item-avatar">
                <span class="cuenta-menu-icon">🎭</span>
                <span class="cuenta-menu-text">Mi Avatar</span>
            </a>
            
            <div class="cuenta-menu-divider"></div>
            
            <!-- Cerrar sesión -->
            <a href="<?php echo esc_url( $um_logout_url ); ?>" class="cuenta-menu-item cuenta-menu-item-logout">
                <span class="cuenta-menu-icon">🚪</span>
                <span class="cuenta-menu-text">Cerrar sesión</span>
            </a>
        <?php else: ?>
            <!-- Botones de autenticación -->
            <div class="cuenta-menu-auth">
                <button id="cuenta-menu-login-btn" class="cuenta-menu-btn cuenta-menu-btn-login" type="button">
                    <span class="cuenta-menu-icon">🔓</span>
                    Acceder
                </button>
            </div>
        <?php endif; ?>
    </div>
</div>

<!-- Modal provincia, si lo tienes -->
<div id="provincia-modal" class="provincia-modal-overlay" style="display:none;">
    <div class="provincia-modal-content">
        <button class="provincia-modal-close" id="cerrar-provincia-modal" aria-label="Cerrar">&times;</button>
        <h2>Selecciona tu provincia</h2>
        <select id="select-provincia">
            <option value="">Elige una provincia...</option>
            <!-- opciones de provincias aquí -->
        </select>
        <button id="provincia-modal-ir" class="provincia-modal-ir-btn">Ir</button>
    </div>
</div>

<!-- CSS para el badge de mensajes -->
<style>
.mensajes-icon-container {
    position: relative;
    display: inline-block;
}

.mensajes-badge {
    position: absolute;
    top: -8px;
    right: -8px;
    background: #ef4444;
    color: white;
    border-radius: 50%;
    min-width: 18px;
    height: 18px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 11px;
    font-weight: 600;
    line-height: 1;
    border: 2px solid white;
    box-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

.mensajes-badge.pulse {
    animation: badgePulse 2s infinite;
}

@keyframes badgePulse {
    0% { transform: scale(1); }
    50% { transform: scale(1.1); }
    100% { transform: scale(1); }
}

/* Animación cuando se actualiza el contador */
.mensajes-badge.updated {
    animation: badgeUpdate 0.6s ease-out;
}

@keyframes badgeUpdate {
    0% { transform: scale(1); }
    50% { transform: scale(1.3); background: #f59e0b; }
    100% { transform: scale(1); }
}

/* Estilos para el modal de login del footer */
#footer-login-modal .modal-login-content {
    position: relative;
    padding: 45px 25px 25px 25px; /* Más padding arriba para el botón X */
}

#footer-login-modal .modal-close {
    position: absolute;
    top: 15px;
    right: 20px;
    background: none;
    border: none;
    font-size: 24px;
    cursor: pointer;
    color: #666;
    width: 30px;
    height: 30px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
    transition: all 0.2s;
    z-index: 10;
}

#footer-login-modal .modal-close:hover {
    background: #f0f0f0;
    color: #333;
}

/* Asegurar que el título tenga suficiente margen */
#footer-login-modal h2,
#footer-login-modal h3 {
    margin-top: 0;
    margin-bottom: 15px;
    padding-right: 40px; /* Espacio para el botón X */
    line-height: 1.3;
}

/* Responsive para móvil */
@media (max-width: 480px) {
    #footer-login-modal .modal-login-content {
        padding: 50px 20px 25px 20px;
    }
    
    #footer-login-modal h2,
    #footer-login-modal h3 {
        padding-right: 45px;
        font-size: 1.3em;
    }
}

/* === MENÚ MODERNO DE CUENTA === */
.tab-btn-cuenta {
    position: relative !important;
    background: none !important;
    border: none !important;
    cursor: pointer !important;
    padding: 8px 0 0 0 !important;
    display: flex !important;
    flex-direction: column !important;
    align-items: center !important;
    gap: 0px !important;
    z-index: 100 !important;
    pointer-events: auto !important;
    width: auto !important;
    height: auto !important;
    min-width: auto !important;
    min-height: auto !important;
    justify-content: flex-start !important;
}

.tab-btn-cuenta:hover {
    opacity: 0.8 !important;
}

.tab-btn-cuenta:active {
    transform: scale(0.95) !important;
}

.tab-btn-cuenta svg {
    pointer-events: none !important;
    width: 24px !important;
    height: 24px !important;
}

.tab-btn-cuenta span {
    pointer-events: none !important;
    margin: 0 !important;
    margin-top: 6px !important;
    padding: 0 !important;
    line-height: 1 !important;
    font-size: 12px !important;
}

.cuenta-menu-modern {
    position: fixed !important;
    bottom: 80px !important;
    right: 10px !important;
    background: white !important;
    border-radius: 16px !important;
    box-shadow: 0 10px 40px rgba(0, 0, 0, 0.15) !important;
    min-width: 280px !important;
    z-index: 1001 !important;
    overflow: hidden !important;
    animation: slideUpMenu 0.3s ease-out !important;
    pointer-events: auto !important;
}

@media (max-width: 480px) {
    .cuenta-menu-modern {
        min-width: 260px;
        right: 5px;
    }
}

@keyframes slideUpMenu {
    from {
        opacity: 0;
        transform: translateY(10px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

/* Header con usuario logueado */
.cuenta-menu-header {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 16px;
    background: linear-gradient(135deg, #f0f8ff 0%, #e6f4ff 100%);
    border-bottom: 1px solid #e0e8f0;
}

.cuenta-user-avatar {
    flex-shrink: 0;
}

.cuenta-avatar-img {
    width: 48px;
    height: 48px;
    border-radius: 50%;
    border: 2px solid #3ba1da;
    object-fit: cover;
}

.cuenta-user-info {
    flex: 1;
    min-width: 0;
}

.cuenta-user-name {
    margin: 0;
    font-weight: 600;
    color: #15418a;
    font-size: 14px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}

.cuenta-user-email {
    margin: 4px 0 0 0;
    font-size: 12px;
    color: #666;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}

/* Divisor */
.cuenta-menu-divider {
    height: 1px;
    background: linear-gradient(90deg, transparent, #e0e0e0, transparent);
    margin: 8px 0;
}

/* Items del menú */
.cuenta-menu-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 12px 16px;
    color: #333;
    text-decoration: none;
    font-size: 14px;
    font-weight: 500;
    transition: all 0.2s ease;
    cursor: pointer;
    border-left: 3px solid transparent;
}

.cuenta-menu-item:hover {
    background: #f8f9fa;
    border-left-color: #3ba1da;
    padding-left: 18px;
    color: #3ba1da;
}

.cuenta-menu-icon {
    font-size: 18px;
    min-width: 24px;
    text-align: center;
}

.cuenta-menu-text {
    flex: 1;
}

/* Logout especial */
.cuenta-menu-item-logout {
    color: #e74c3c;
    border-top: 1px solid #f0f0f0;
    margin-top: 4px;
    padding-top: 12px;
}

.cuenta-menu-item-logout:hover {
    background: #fff5f5;
    border-left-color: #e74c3c;
    color: #c0392b;
}

/* Botones de autenticación */
.cuenta-menu-auth {
    padding: 12px;
    display: flex;
    flex-direction: column;
    gap: 10px;
}

.cuenta-menu-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    padding: 12px 16px;
    border: none;
    border-radius: 10px;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s ease;
    text-decoration: none;
}

.cuenta-menu-btn-login {
    background: linear-gradient(135deg, #3ba1da 0%, #15418a 100%);
    color: white;
    box-shadow: 0 4px 12px rgba(21, 65, 138, 0.2);
}

.cuenta-menu-btn-login:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 16px rgba(21, 65, 138, 0.3);
}

.cuenta-menu-btn-register {
    background: white;
    color: #3ba1da;
    border: 2px solid #3ba1da;
}

.cuenta-menu-btn-register:hover {
    background: #f0f8ff;
    border-color: #15418a;
    color: #15418a;
    transform: translateY(-2px);
}

/* Responsive */
@media (max-width: 480px) {
    .cuenta-menu-modern {
        min-width: 260px;
        right: 5px;
        bottom: 68px;
    }
    
    .cuenta-menu-header {
        padding: 12px;
    }
    
    .cuenta-avatar-img {
        width: 40px;
        height: 40px;
    }
    
    .cuenta-user-name {
        font-size: 13px;
    }
    
    .cuenta-user-email {
        font-size: 11px;
    }
    
    .cuenta-menu-item {
        padding: 10px 12px;
        font-size: 13px;
    }
    
    .cuenta-menu-item:hover {
        padding-left: 14px;
    }
    
    .cuenta-menu-btn {
        padding: 10px 14px;
        font-size: 13px;
    }
}

/* === EFECTO NEÓN PARA BOTÓN PUBLICAR === */
.neon-publicar-btn {
    position: relative !important;
}

.neon-publicar-btn svg {
    animation: neon-glow-btn 3s ease-in-out infinite;
}

.neon-publicar-btn:hover svg {
    animation: neon-glow-btn 1.5s ease-in-out infinite;
}

@keyframes neon-glow-btn {
    0%, 100% { 
        opacity: 0.8;
    }
    50% { 
        opacity: 1;
    }
}
</style>

<script>
document.addEventListener("DOMContentLoaded", function() {
    // Variables globales
    var modal = document.getElementById('footer-login-modal');
    var cerrarBtn = document.getElementById('footer-login-modal-close');
    var cerrarBtn2 = document.getElementById('footer-login-modal-close2');
    var openEmailRegister = document.getElementById('open-email-register');
    var emailRegisterForm = document.getElementById('email-register-form');
    var modalLoginButtons = document.getElementById('modal-login-buttons');
    var backToLogin = document.getElementById('back-to-login');
    var isUserLoggedIn = <?php echo json_encode($is_logged_in); ?>;
    
    // CONTADOR DE MENSAJES NO LEÍDOS
    var mensajesBadge = document.getElementById('mensajes-badge');
    var mensajesPolling = null;
    
    function actualizarContadorMensajes() {
        if (!isUserLoggedIn) return;
        
        fetch('<?php echo admin_url('admin-ajax.php'); ?>', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: 'action=zmoriginal_get_unread_count&nonce=<?php echo wp_create_nonce('zmoriginal_nonce'); ?>'
        })
        .then(response => response.json())
        .then(data => {
            if (data.success && mensajesBadge) {
                var count = parseInt(data.data.unread_count);
                var currentCount = parseInt(mensajesBadge.textContent) || 0;
                
                if (count > 0) {
                    mensajesBadge.textContent = count > 99 ? '99+' : count;
                    mensajesBadge.style.display = 'flex';
                    
                    // Animación si el contador aumentó
                    if (count > currentCount) {
                        mensajesBadge.classList.add('updated');
                        setTimeout(() => mensajesBadge.classList.remove('updated'), 600);
                    }
                    
                    // Pulso si hay mensajes
                    if (count > 0) {
                        mensajesBadge.classList.add('pulse');
                    }
                } else {
                    mensajesBadge.style.display = 'none';
                    mensajesBadge.classList.remove('pulse');
                }
            }
        })
        .catch(error => {
            console.log('Error obteniendo contador de mensajes:', error);
        });
    }
    
    // Actualizar contador al cargar la página
    if (isUserLoggedIn) {
        actualizarContadorMensajes();
        
        // Polling cada 30 segundos para actualizar el contador
        mensajesPolling = setInterval(actualizarContadorMensajes, 30000);
    }
    
    // Limpiar contador cuando se hace clic en mensajes
    var mensajesBtn = document.getElementById('footer-mensajes-btn');
    if (mensajesBtn) {
        mensajesBtn.addEventListener('click', function() {
            if (isUserLoggedIn && mensajesBadge) {
                // Limpiar badge inmediatamente (se actualizará con el polling)
                setTimeout(() => {
                    mensajesBadge.style.display = 'none';
                    mensajesBadge.classList.remove('pulse');
                }, 1000);
            }
        });
    }
    
    // MODAL LOGIN Y REGISTRO
    if(openEmailRegister && emailRegisterForm && modalLoginButtons) {
        openEmailRegister.addEventListener('click', function(e) {
            e.preventDefault();
            modalLoginButtons.style.display = 'none';
            emailRegisterForm.style.display = 'block';
        });
    }

    // Función para mostrar opciones de login (Google + Email)
    window.mostrarOpcionesLogin = function() {
        // Cambiar el contenido del modal para mostrar las opciones
        var modalContent = document.querySelector('#footer-login-modal .modal-login-content');
        if (modalContent) {
            modalContent.innerHTML = `
                <button id="footer-login-modal-close-new" class="modal-close" aria-label="Cerrar">&times;</button>
                <h2>Elige cómo iniciar sesión</h2>
                <div class="modal-login-buttons">
                    <?php echo do_shortcode('[nextend_social_login provider="google" label="Continuar con Google"]'); ?>
                    <button class="btn-email-login" onclick="window.location.href='<?php echo esc_url($um_login_url); ?>'">📧 Continuar con email</button>
                    <span class="modal-register-link" onclick="mostrarRegistro()">¿No tienes cuenta? Regístrate</span>
                </div>
            `;
            
            // Añadir evento al nuevo botón cerrar
            var newCloseBtn = document.getElementById('footer-login-modal-close-new');
            if (newCloseBtn) {
                newCloseBtn.addEventListener('click', function() {
                    modal.style.display = 'none';
                });
            }
        }
    };

    // Función para mostrar registro
    window.mostrarRegistro = function() {
        var modalContent = document.querySelector('#footer-login-modal .modal-login-content');
        if (modalContent) {
            modalContent.innerHTML = `
                <button id="footer-login-modal-close-reg" class="modal-close" aria-label="Cerrar">&times;</button>
                <h3>Registro por email</h3>
                <?php echo do_shortcode('[ultimatemember form_id="' . esc_attr($um_register_form_id) . '"]'); ?>
                <a href="#" onclick="volverALogin()" style="display:block;margin-top:10px; color:#2563eb; text-decoration:underline;">Volver</a>
            `;
            
            // Añadir evento al nuevo botón cerrar
            var newCloseBtn = document.getElementById('footer-login-modal-close-reg');
            if (newCloseBtn) {
                newCloseBtn.addEventListener('click', function() {
                    modal.style.display = 'none';
                });
            }
        }
    };

    // Función para volver al login inicial
    window.volverALogin = function() {
        location.reload(); // Recargar para volver al estado inicial
    };

    // Función para abrir login de UltimateMember con opciones (mantener por compatibilidad)
    // COMENTADA: Esta función causaba carga doble en login - usar el modal del header en su lugar
    // window.abrirLoginUltimateMember = function() {
    //     // Cerrar el modal actual
    //     if (modal) modal.style.display = 'none';
    //     
    //     // Abrir la página de login de UltimateMember en la misma ventana
    //     window.location.href = '<?php echo esc_url($um_login_url); ?>';
    // };

    if(backToLogin && emailRegisterForm && modalLoginButtons) {
        backToLogin.addEventListener('click', function(e) {
            e.preventDefault();
            modalLoginButtons.style.display = 'block';
            emailRegisterForm.style.display = 'none';
        });
    }

    // Cerrar modal
    if(cerrarBtn) {
        cerrarBtn.addEventListener('click', function() {
            modal.style.display = 'none';
        });
    }

    if(cerrarBtn2) {
        cerrarBtn2.addEventListener('click', function() {
            modal.style.display = 'none';
        });
    }

    window.addEventListener('click', function(e) {
        if (e.target === modal) {
            modal.style.display = 'none';
        }
    });

    // Sticky footer: login modal para no logueados
    var favoritosBtn = document.getElementById('footer-favoritos-btn');
    var publicarBtn = document.getElementById('sticky-publicar-btn');
    var cuentaBtn = document.getElementById('footer-cuenta-btn');
    var cuentaMenu = document.getElementById('footer-cuenta-menu');
    var loginMenuLink = document.getElementById('cuenta-menu-login-link');

    function openLoginModal() {
        if (modal) modal.style.display = 'flex';
        if (cuentaBtn) cuentaBtn.classList.remove('open');
        if (cuentaMenu) cuentaMenu.style.display = 'none';
    }

    function openPublicarLoginModal() {
        if (modal) modal.style.display = 'flex';
        if (cuentaBtn) cuentaBtn.classList.remove('open');
        if (cuentaMenu) cuentaMenu.style.display = 'none';
        
        // Cambiar el contenido del modal para publicar
        var modalContent = document.querySelector('#footer-login-modal .modal-login-content');
        if (modalContent) {
            modalContent.innerHTML = `
                <button id="footer-login-modal-close-publicar" class="modal-close" aria-label="Cerrar">&times;</button>
                <h2>Para publicar necesitas una cuenta</h2>
                <p style="text-align: center; color: #666; margin-bottom: 20px;">Elige cómo quieres registrarte o iniciar sesión:</p>
                <div class="modal-login-buttons">
                    <?php echo do_shortcode('[nextend_social_login provider="google" label="Continuar con Google"]'); ?>
                    <button class="btn-email-login" onclick="window.location.href='<?php echo esc_url($um_login_url); ?>'">📧 Continuar con email</button>
                    <span class="modal-register-link" onclick="mostrarRegistroPublicar()">¿No tienes cuenta? Regístrate aquí</span>
                </div>
            `;
            
            // Añadir evento al nuevo botón cerrar
            var newCloseBtn = document.getElementById('footer-login-modal-close-publicar');
            if (newCloseBtn) {
                newCloseBtn.addEventListener('click', function() {
                    modal.style.display = 'none';
                });
            }
        }
    }

    // Función específica para registro desde publicar
    window.mostrarRegistroPublicar = function() {
        var modalContent = document.querySelector('#footer-login-modal .modal-login-content');
        if (modalContent) {
            modalContent.innerHTML = `
                <button id="footer-login-modal-close-reg-pub" class="modal-close" aria-label="Cerrar">&times;</button>
                <h3>Crear cuenta para publicar</h3>
                <p style="text-align: center; color: #666; margin-bottom: 15px;">Completa el registro y podrás publicar inmediatamente:</p>
                <?php echo do_shortcode('[ultimatemember form_id="' . esc_attr($um_register_form_id) . '"]'); ?>
                <a href="#" onclick="openPublicarLoginModal()" style="display:block;margin-top:10px; color:#2563eb; text-decoration:underline;">Ya tengo cuenta, iniciar sesión</a>
            `;
            
            // Añadir evento al nuevo botón cerrar
            var newCloseBtn = document.getElementById('footer-login-modal-close-reg-pub');
            if (newCloseBtn) {
                newCloseBtn.addEventListener('click', function() {
                    modal.style.display = 'none';
                });
            }
        }
    };

    if (favoritosBtn) {
        favoritosBtn.addEventListener('click', function(e) {
            if (!isUserLoggedIn) {
                e.preventDefault();
                // Usar el modal global del header
                if (typeof window.abrirGlobalLoginModal === 'function') {
                    window.abrirGlobalLoginModal();
                } else {
                    openLoginModal();
                }
            }
        });
    }

    if (publicarBtn) {
        publicarBtn.addEventListener('click', function(e) {
            e.preventDefault();
            if (!isUserLoggedIn) {
                // Usar el modal global del header
                if (typeof window.abrirGlobalLoginModal === 'function') {
                    window.abrirGlobalLoginModal();
                } else {
                    openPublicarLoginModal();
                }
            } else {
                // Abrir el modal de provincias en lugar de hacer scroll
                if (typeof abrirModalProvincias === 'function') {
                    abrirModalProvincias();
                } else {
                    // Fallback al comportamiento anterior si el modal no está disponible
                    var btn = document.getElementById('mostrar-formulario-btn');
                    if (btn) {
                        btn.scrollIntoView({ behavior: "smooth", block: "center" });
                        setTimeout(function() {
                            btn.click();
                            let intentos = 0;
                            function intentarFocus() {
                                var provincia = document.getElementById('provincia-selector');
                                if (provincia && provincia.offsetParent !== null) {
                                    provincia.focus();
                                } else if (intentos < 10) {
                                    intentos++;
                                    setTimeout(intentarFocus, 150);
                                }
                            }
                            intentarFocus();
                        }, 700);
                    } else {
                        window.location.href = "<?php echo esc_url(home_url('/')); ?>?abrir_publicar=1";
                    }
                }
            }
        });
    }

    if (mensajesBtn) {
        mensajesBtn.addEventListener('click', function(e) {
            if (!isUserLoggedIn) {
                e.preventDefault();
                // Usar el modal global del header
                if (typeof window.abrirGlobalLoginModal === 'function') {
                    window.abrirGlobalLoginModal();
                } else {
                    openLoginModal();
                }
            }
        });
    }

    // Menú cuenta - VERSIÓN SIMPLIFICADA
    var cuentaBtn = document.getElementById('footer-cuenta-btn');
    var cuentaMenu = document.getElementById('footer-cuenta-menu');
    
    if (cuentaBtn) {
        console.log('✓ Botón cuenta encontrado');
        cuentaBtn.addEventListener('click', function(e) {
            e.preventDefault();
            console.log('✓ Click en botón cuenta');
            if (cuentaMenu) {
                var isOpen = cuentaMenu.style.display === 'block';
                cuentaMenu.style.display = isOpen ? 'none' : 'block';
                cuentaMenu.classList.toggle('active');
                console.log('✓ Menú ahora:', cuentaMenu.style.display);
            }
        });
    } else {
        console.log('✗ Botón cuenta NO encontrado');
    }
    
    if (cuentaMenu) {
        console.log('✓ Menú cuenta encontrado');
    } else {
        console.log('✗ Menú cuenta NO encontrado');
    }

    // Cerrar menú al hacer clic fuera
    document.addEventListener('click', function(e) {
        if (cuentaMenu && cuentaBtn && !cuentaBtn.contains(e.target) && !cuentaMenu.contains(e.target)) {
            cuentaMenu.style.display = 'none';
            cuentaMenu.classList.remove('active');
        }
    });

    // Botones de autenticación en el menú
    var cuentaLoginBtn = document.getElementById('cuenta-menu-login-btn');
    var cuentaRegisterBtn = document.getElementById('cuenta-menu-register-btn');

    if (cuentaLoginBtn) {
        cuentaLoginBtn.addEventListener('click', function(e) {
            e.preventDefault();
            if (cuentaMenu) cuentaMenu.style.display = 'none';
            // Usar el modal global del header
            if (typeof window.abrirGlobalLoginModal === 'function') {
                window.abrirGlobalLoginModal();
            } else if (modal) {
                modal.style.display = 'flex';
            }
        });
    }

    // Iniciar sesión en menú cuenta solo abre el modal en móvil
    function isMobile() {
        return window.matchMedia("(max-width: 768px)").matches;
    }

    var loginMenuLink = document.getElementById('cuenta-menu-login-link');
    if(loginMenuLink && modal && cerrarBtn) {
        loginMenuLink.addEventListener('click', function(e) {
            if(isMobile()) {
                e.preventDefault();
                modal.style.display = 'flex';
                if (cuentaBtn) cuentaBtn.classList.remove('open');
                if (cuentaMenu) cuentaMenu.style.display = 'none';
            }
        });
    }

    // Modal publicar desde query param
    function getParam(name) {
        const urlParams = new URLSearchParams(window.location.search);
        return urlParams.get(name);
    }

    if (getParam('abrir_publicar') == '1') {
        var btn = document.getElementById('mostrar-formulario-btn');
        if (btn) {
            btn.scrollIntoView({ behavior: "smooth", block: "center" });
            setTimeout(function() {
                btn.click();
                let intentos = 0;
                function intentarFocus() {
                    var provincia = document.getElementById('provincia-selector');
                    if (provincia && provincia.offsetParent !== null) {
                        provincia.focus();
                    } else if (intentos < 10) {
                        intentos++;
                        setTimeout(intentarFocus, 150);
                    }
                }
                intentarFocus();
            }, 700);
        }
    }
    
    // Limpiar polling al salir de la página
    window.addEventListener('beforeunload', function() {
        if (mensajesPolling) {
            clearInterval(mensajesPolling);
        }
    });
});
</script>

<script>
document.addEventListener("DOMContentLoaded", function() {
    // Variables globales ya existentes
    var modalPublicar = document.getElementById('provincia-modal');
    var cerrarModalBtn = document.getElementById('cerrar-provincia-modal');
    var continuarModalBtn = document.getElementById('provincia-modal-ir');
    var selectProvincia = document.getElementById('select-provincia');
    var isLoggedIn = <?php echo json_encode($is_logged_in); ?>; // Estado de sesión

    // Cerrar el modal
    if (cerrarModalBtn) {
        cerrarModalBtn.addEventListener('click', function() {
            if (modalPublicar) {
                modalPublicar.style.display = 'none';
            }
        });
    }

    // Continuar en el modal con una provincia seleccionada
    if (continuarModalBtn) {
        continuarModalBtn.addEventListener('click', function() {
            if (selectProvincia && selectProvincia.value) {
                // Redirigir al formulario/publicar según la provincia
                window.location.href = "/publicar/" + selectProvincia.value;
            } else {
                alert("Por favor, selecciona una provincia.");
            }
        });
    }

    // Cerrar el modal al hacer clic fuera de él
    window.addEventListener('click', function(e) {
        if (e.target === modalPublicar) {
            modalPublicar.style.display = 'none';
        }
    });
});
</script>
</body>
</html>