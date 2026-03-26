<?php
/**
 * The header for Astra Theme (modified).
 *
 * @package Astra
 * @since 1.0.0
 */
if ( ! defined( 'ABSPATH' ) ) {
    exit; // Exit if accessed directly.
}
?><!DOCTYPE html>
<html <?php language_attributes(); ?>>
<head>
    <!-- Charset first -->
    <meta charset="<?php bloginfo( 'charset' ); ?>">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <!-- Preconnect for analytics -->
    <link rel="preconnect" href="https://www.googletagmanager.com" crossorigin>

    <!-- Google tag (gtag.js) -->
    <script async src="https://www.googletagmanager.com/gtag/js?id=G-XPSBZJLJDL"></script>
    <script>
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', 'G-XPSBZJLJDL');
    </script>

    <?php astra_head_top(); ?>

    <?php
    if ( apply_filters( 'astra_header_profile_gmpg_link', true ) ) {
        ?>
        <link rel="profile" href="https://gmpg.org/xfn/11">
        <?php
    }
    ?>

    <?php wp_head(); ?>
    <?php astra_head_bottom(); ?>
    
    <?php
    // Detectar si el usuario está logueado
    $is_user_logged_in = is_user_logged_in();
    ?>
    
    <!-- MODAL LOGIN Y REGISTRO GLOBAL (REUTILIZABLE) -->
    <div id="global-login-modal" class="modal-login-overlay" style="display:none;">
        <div class="modal-login-content">
            <button id="global-login-modal-close" class="modal-close" aria-label="Cerrar">&times;</button>
            
            <h2>Inicia sesión o regístrate</h2>
            
            <div class="modal-login-buttons" id="global-modal-login-buttons">
                <?php echo do_shortcode('[nextend_social_login provider="google" label="Continua con Google"]'); ?>
                <button class="btn-email-login" id="global-btn-email-login">Iniciar sesión con email</button>
                <button class="btn-email-login" id="global-btn-email-registro">Registrarse con email</button>
            </div>
            
            <div id="global-email-register-form" style="display:none;">
                <h3>Registro por email</h3>
                <?php echo do_shortcode('[ultimatemember form_id="17"]'); ?>
                <a href="#" id="global-back-to-login" style="display:block;margin-top:10px; color:#2563eb; text-decoration:underline;">Volver</a>
            </div>
            
            <div id="global-email-login-form" style="display:none;">
                <h3>Iniciar sesión con email</h3>
                <?php echo do_shortcode('[ultimatemember form_id="18"]'); ?>
                <a href="#" id="global-back-to-login-from-email" style="display:block;margin-top:10px; color:#2563eb; text-decoration:underline;">Volver</a>
            </div>
        </div>
    </div>
    
    <style>
    /* MODAL */
    .modal-login-overlay {
        display: none;
        position: fixed;
        top: 0;
        left: 0;
        width: 100vw;
        height: 100vh;
        background: rgba(0,0,0,0.6);
        z-index: 9999999 !important;
        align-items: center;
        justify-content: center;
        padding: 10px;
        overflow-y: auto;
    }

    .modal-login-overlay[style*="display: flex"],
    .modal-login-overlay[style*="display: block"] {
        display: flex !important;
    }

    .modal-login-content {
        background: #fff;
        border-radius: 12px;
        padding: 16px 12px;
        max-width: 550px;
        width: 95vw;
        margin: auto;
        box-shadow: 0 8px 32px rgba(0,0,0,0.18);
        position: relative;
        text-align: center;
        z-index: 10000000 !important;
        max-height: 90vh;
        overflow-y: auto;
    }
    
    @media (max-width: 600px) {
        .modal-login-content {
            max-height: 85vh;
            padding: 12px 10px;
        }
    }
    
    .modal-login-content h2,
    .modal-login-content h3 {
        margin: 0 0 8px 0;
        font-size: 1.2em;
    }

    .modal-close {
        position: absolute;
        top: 8px;
        right: 8px;
        background: none;
        border: none;
        font-size: 1.8em;
        color: #2563eb;
        cursor: pointer;
        transition: color 0.18s;
    }

    .modal-close:hover {
        color: #e11d48;
    }

    .modal-login-buttons {
        display: flex;
        flex-direction: column;
        gap: 6px;
        margin-top: 8px;
    }

    .btn-email-login {
        background: #2563eb;
        color: #fff !important;
        border: none;
        border-radius: 8px;
        font-weight: 500;
        padding: 8px 0;
        display: block;
        width: 100%;
        text-align: center;
        font-size: 0.95em;
        cursor: pointer;
        transition: background 0.15s;
        text-decoration: none;
    }

    .btn-email-login:hover {
        background: #1749a3;
        color: #fff;
    }

    #global-email-register-form,
    #global-email-login-form {
        margin-top: 6px;
        text-align: left;
        display: none !important;
        max-height: 70vh;
        overflow-y: auto;
        padding-right: 2px;
    }
    
    @media (max-width: 600px) {
        #global-email-register-form,
        #global-email-login-form {
            max-height: 65vh;
        }
    }
    
    /* Hacer la barra de scroll más compacta y al margen derecho */
    #global-email-register-form::-webkit-scrollbar,
    #global-email-login-form::-webkit-scrollbar {
        width: 6px;
    }
    
    #global-email-register-form::-webkit-scrollbar-track,
    #global-email-login-form::-webkit-scrollbar-track {
        background: transparent;
    }
    
    #global-email-register-form::-webkit-scrollbar-thumb,
    #global-email-login-form::-webkit-scrollbar-thumb {
        background: #ccc;
        border-radius: 3px;
    }
    
    #global-email-register-form::-webkit-scrollbar-thumb:hover,
    #global-email-login-form::-webkit-scrollbar-thumb:hover {
        background: #999;
    }
    
    /* Bloquear scroll de la página cuando el modal está abierto */
    body.modal-open {
        overflow: hidden !important;
        height: 100vh !important;
        position: fixed !important;
        width: 100% !important;
    }
    
    /* Aumentar ancho del formulario de Ultimate Member dentro del modal */
    #global-email-register-form .um,
    #global-email-login-form .um {
        max-width: 100% !important;
    }
    
    #global-email-register-form.active,
    #global-email-login-form.active {
        display: block !important;
    }
    
    #global-modal-login-buttons.hidden {
        display: none !important;
    }

    /* Validación de usuario */
    .um-field-error-custom,
    .um-field-success-custom {
        display: block !important;
        visibility: visible !important;
        opacity: 1 !important;
        font-size: 14px !important;
        margin-top: 10px !important;
        padding: 12px 14px !important;
        border-radius: 6px !important;
        font-weight: 600 !important;
        text-align: center !important;
        width: 100% !important;
        box-sizing: border-box !important;
    }

    .um-field-error-custom {
        color: #fff !important;
        background: #d63638 !important;
    }

    .um-field-success-custom {
        color: #fff !important;
        background: #46b450 !important;
    }
    
    /* Botón de registro responsive - SOLO UNO */
    #header-registro-btn {
        background: none;
        padding: 0;
        margin-left: 8px;
        border: none;
        cursor: pointer;
        color: #1976d2;
        display: inline-block;
    }
    
    #header-registro-btn:hover {
        opacity: 0.8;
    }
    
    #header-registro-btn-desktop {
        display: none !important;
    }
    
    @media (max-width: 767px) {
        #header-registro-btn-desktop {
            display: none !important;
        }
        
        <?php if ($is_user_logged_in): ?>
        #header-registro-btn {
            display: none !important;
        }
        <?php endif; ?>
    }
    
    @media (min-width: 768px) {
        #header-registro-btn {
            display: none !important;
        }
        
        #header-auth-container {
            display: flex !important;
            flex-direction: column !important;
            align-items: center !important;
            gap: 0 !important;
        }
        
        #header-registro-btn-desktop {
            display: inline-block !important;
            background: #2563eb;
            color: #fff !important;
            padding: 12px 28px;
            border-radius: 8px;
            border: none;
            cursor: pointer;
            font-weight: 600;
            font-size: 15px;
        }
        
        #header-registro-btn-desktop:hover {
            background: #1749a3;
        }
        
        <?php if ($is_user_logged_in): ?>
        #header-auth-container {
            display: none !important;
        }
        <?php endif; ?>
    }
    </style>
    
    
    <script>
    document.addEventListener('DOMContentLoaded', function() {
        var modal = document.getElementById('global-login-modal');
        var registroBtn = document.getElementById('header-registro-btn');
        var registroBtnDesktop = document.getElementById('header-registro-btn-desktop');
        var closeBtn = document.getElementById('global-login-modal-close');
        var emailRegisterForm = document.getElementById('global-email-register-form');
        var modalLoginButtons = document.getElementById('global-modal-login-buttons');
        var btnEmailRegistro = document.getElementById('global-btn-email-registro');
        var backToLogin = document.getElementById('global-back-to-login');
        
        function abrirModal() {
            if (modal) {
                // Guardar URL actual en localStorage para redirect después de login/registro
                localStorage.setItem('zm_redirect_after_login', window.location.href);
                // Limpiar flag de registro anterior
                localStorage.removeItem('zm_just_registered');
                console.log('✅ URL guardada en localStorage:', window.location.href);
                
                modal.style.display = 'flex';
                
                // Bloquear scroll de la página
                document.body.classList.add('modal-open');
                
                // Resetear estado: mostrar botones, ocultar formularios
                if (modalLoginButtons) modalLoginButtons.classList.remove('hidden');
                if (emailRegisterForm) emailRegisterForm.classList.remove('active');
                if (emailLoginForm) emailLoginForm.classList.remove('active');
                
                // Limpiar campo de usuario después de que el modal se muestre
                setTimeout(function() {
                    var usernameField = document.querySelector('input[name^="user_login"]');
                    if (usernameField) {
                        usernameField.value = '';
                        usernameField.setAttribute('value', '');
                        
                        // Limpiar mensajes
                        const errorContainer = usernameField.closest('.um-field');
                        if (errorContainer) {
                            const oldMessages = errorContainer.querySelectorAll('.um-field-error-custom, .um-field-success-custom');
                            oldMessages.forEach(msg => msg.remove());
                        }
                    }
                }, 150);
            }
        }
        
        // Abrir modal desde botón móvil
        if (registroBtn) {
            registroBtn.addEventListener('click', abrirModal);
        }
        
        // Abrir modal desde botón desktop
        if (registroBtnDesktop) {
            registroBtnDesktop.addEventListener('click', abrirModal);
        }
        
        // Cerrar modal
        if (closeBtn) {
            closeBtn.addEventListener('click', function() {
                if (modal) {
                    modal.style.display = 'none';
                    // Desbloquear scroll de la página
                    document.body.classList.remove('modal-open');
                }
            });
        }
        
        // Mostrar formulario de login con email
        var btnEmailLogin = document.getElementById('global-btn-email-login');
        var emailLoginForm = document.getElementById('global-email-login-form');
        var backToLoginFromEmail = document.getElementById('global-back-to-login-from-email');
        var btnEmailRegistro = document.getElementById('global-btn-email-registro');
        var emailRegisterForm = document.getElementById('global-email-register-form');
        var backToLogin = document.getElementById('global-back-to-login');
        
        if (btnEmailLogin) {
            btnEmailLogin.addEventListener('click', function(e) {
                e.preventDefault();
                if (modalLoginButtons) modalLoginButtons.classList.add('hidden');
                if (emailLoginForm) {
                    emailLoginForm.classList.add('active');
                    
                    // Limpiar agresivamente el campo mientras se renderiza
                    let cleanupInterval = setInterval(function() {
                        var usernameField = document.querySelector('input[name^="user_login"]');
                        if (usernameField && usernameField.value !== '') {
                            usernameField.value = '';
                            usernameField.setAttribute('value', '');
                            usernameField.dispatchEvent(new Event('input', { bubbles: true }));
                            usernameField.dispatchEvent(new Event('change', { bubbles: true }));
                        }
                    }, 50);
                    
                    // Esperar a que Ultimate Member renderice el formulario
                    setTimeout(function() {
                        clearInterval(cleanupInterval);
                        
                        var usernameField = document.querySelector('input[name^="user_login"]');
                        
                        if (usernameField) {
                            // Limpiar el campo una última vez
                            usernameField.value = '';
                            usernameField.setAttribute('value', '');
                            usernameField.dispatchEvent(new Event('input', { bubbles: true }));
                            usernameField.dispatchEvent(new Event('change', { bubbles: true }));
                            
                            // Limpiar mensajes
                            const errorContainer = usernameField.closest('.um-field');
                            if (errorContainer) {
                                const oldMessages = errorContainer.querySelectorAll('.um-field-error-custom, .um-field-success-custom');
                                oldMessages.forEach(msg => msg.remove());
                            }
                            
                            // Enfocar el campo
                            usernameField.focus();
                        }
                    }, 800);
                }
            });
        }
        
        // Volver a opciones desde login con email
        if (backToLoginFromEmail) {
            backToLoginFromEmail.addEventListener('click', function(e) {
                e.preventDefault();
                if (emailLoginForm) emailLoginForm.classList.remove('active');
                if (modalLoginButtons) modalLoginButtons.classList.remove('hidden');
                
                // Limpiar campo
                var usernameField = document.querySelector('input[name^="user_login"]');
                if (usernameField) {
                    usernameField.value = '';
                    const errorContainer = usernameField.closest('.um-field');
                    if (errorContainer) {
                        const oldMessages = errorContainer.querySelectorAll('.um-field-error-custom, .um-field-success-custom');
                        oldMessages.forEach(msg => msg.remove());
                    }
                }
            });
        }
        
        // Mostrar formulario de registro desde botón en modal
        if (btnEmailRegistro) {
            btnEmailRegistro.addEventListener('click', function(e) {
                e.preventDefault();
                // Marcar que es registro
                localStorage.setItem('zm_is_registration', 'true');
                if (modalLoginButtons) modalLoginButtons.classList.add('hidden');
                if (emailRegisterForm) {
                    emailRegisterForm.classList.add('active');
                    
                    // Limpiar agresivamente el campo mientras se renderiza
                    let cleanupInterval = setInterval(function() {
                        var usernameField = document.querySelector('input[name^="user_login"]');
                        if (usernameField && usernameField.value !== '') {
                            usernameField.value = '';
                            usernameField.setAttribute('value', '');
                            usernameField.dispatchEvent(new Event('input', { bubbles: true }));
                            usernameField.dispatchEvent(new Event('change', { bubbles: true }));
                        }
                    }, 50);
                    
                    // Esperar a que Ultimate Member renderice el formulario
                    setTimeout(function() {
                        clearInterval(cleanupInterval);
                        
                        var usernameField = document.querySelector('input[name^="user_login"]');
                        
                        if (usernameField) {
                            // Limpiar el campo una última vez
                            usernameField.value = '';
                            usernameField.setAttribute('value', '');
                            usernameField.dispatchEvent(new Event('input', { bubbles: true }));
                            usernameField.dispatchEvent(new Event('change', { bubbles: true }));
                            
                            // Limpiar mensajes
                            const errorContainer = usernameField.closest('.um-field');
                            if (errorContainer) {
                                const oldMessages = errorContainer.querySelectorAll('.um-field-error-custom, .um-field-success-custom');
                                oldMessages.forEach(msg => msg.remove());
                            }
                            
                            // Enfocar el campo
                            usernameField.focus();
                            
                            // Inicializar validación completamente
                            if (typeof headerInicializarValidacion !== 'undefined') {
                                headerInicializarValidacion();
                            }
                        }
                    }, 800);
                }
            });
        }
        
        // Volver a opciones desde registro
        if (backToLogin) {
            backToLogin.addEventListener('click', function(e) {
                e.preventDefault();
                if (emailRegisterForm) emailRegisterForm.classList.remove('active');
                if (modalLoginButtons) modalLoginButtons.classList.remove('hidden');
                
                // Limpiar campo
                var usernameField = document.querySelector('input[name^="user_login"]');
                if (usernameField) {
                    usernameField.value = '';
                    const errorContainer = usernameField.closest('.um-field');
                    if (errorContainer) {
                        const oldMessages = errorContainer.querySelectorAll('.um-field-error-custom, .um-field-success-custom');
                        oldMessages.forEach(msg => msg.remove());
                    }
                }
            });
        }
        
        // Cerrar modal al hacer clic fuera
        window.addEventListener('click', function(e) {
            if (e.target === modal) {
                modal.style.display = 'none';
                // Desbloquear scroll de la página
                document.body.classList.remove('modal-open');
            }
        });
        
        // Hacer el modal accesible globalmente para otros scripts
        window.abrirGlobalLoginModal = abrirModal;
        
        // Interceptar botón de registro dentro del formulario de login usando MutationObserver
        function observarYInterceptarRegistro() {
            var emailLoginForm = document.getElementById('global-email-login-form');
            if (!emailLoginForm) return;
            
            var observer = new MutationObserver(function(mutations) {
                // Buscar todos los links/botones dentro del formulario de login
                var allElements = emailLoginForm.querySelectorAll('a, button');
                
                allElements.forEach(function(element) {
                    var text = element.textContent.toLowerCase();
                    var href = element.getAttribute('href') || '';
                    
                    // Si contiene "registr" o lleva a página de registro
                    if ((text.includes('registr') || href.includes('register') || href.includes('registro')) && 
                        !element.hasAttribute('data-intercepted')) {
                        
                        // Marcar como interceptado para no procesarlo de nuevo
                        element.setAttribute('data-intercepted', 'true');
                        
                        // Remover evento anterior si existe
                        var newElement = element.cloneNode(true);
                        element.parentNode.replaceChild(newElement, element);
                        
                        // Agregar nuevo evento
                        newElement.addEventListener('click', function(e) {
                            e.preventDefault();
                            e.stopPropagation();
                            
                            // Ocultar formulario de login
                            if (emailLoginForm) emailLoginForm.classList.remove('active');
                            
                            // Mostrar formulario de registro
                            if (emailRegisterForm) {
                                emailRegisterForm.classList.add('active');
                                
                                // Limpiar agresivamente el campo mientras se renderiza
                                let cleanupInterval = setInterval(function() {
                                    var usernameField = document.querySelector('input[name^="user_login"]');
                                    if (usernameField && usernameField.value !== '') {
                                        usernameField.value = '';
                                        usernameField.setAttribute('value', '');
                                        usernameField.dispatchEvent(new Event('input', { bubbles: true }));
                                        usernameField.dispatchEvent(new Event('change', { bubbles: true }));
                                    }
                                }, 50);
                                
                                // Esperar a que Ultimate Member renderice el formulario
                                setTimeout(function() {
                                    clearInterval(cleanupInterval);
                                    
                                    var usernameField = document.querySelector('input[name^="user_login"]');
                                    
                                    if (usernameField) {
                                        // Limpiar el campo una última vez
                                        usernameField.value = '';
                                        usernameField.setAttribute('value', '');
                                        usernameField.dispatchEvent(new Event('input', { bubbles: true }));
                                        usernameField.dispatchEvent(new Event('change', { bubbles: true }));
                                        
                                        // Limpiar mensajes
                                        const errorContainer = usernameField.closest('.um-field');
                                        if (errorContainer) {
                                            const oldMessages = errorContainer.querySelectorAll('.um-field-error-custom, .um-field-success-custom');
                                            oldMessages.forEach(msg => msg.remove());
                                        }
                                        
                                        // Enfocar el campo
                                        usernameField.focus();
                                        
                                        // Inicializar validación
                                        if (typeof headerInicializarValidacion !== 'undefined') {
                                            headerInicializarValidacion();
                                        }
                                    }
                                }, 800);
                            }
                        }, true);
                    }
                });
            });
            
            observer.observe(emailLoginForm, {
                childList: true,
                subtree: true,
                attributes: true
            });
            
            // Detener observer después de 5 segundos
            setTimeout(function() {
                observer.disconnect();
            }, 5000);
        }
        
        // Ejecutar observer cuando se abre el formulario de login
        if (btnEmailLogin) {
            btnEmailLogin.addEventListener('click', function() {
                setTimeout(observarYInterceptarRegistro, 900);
            });
        }
        
        // También ejecutar cuando se vuelve al login desde registro
        if (backToLoginFromEmail) {
            backToLoginFromEmail.addEventListener('click', function() {
                setTimeout(observarYInterceptarRegistro, 900);
            });
        }
        
        // ========== SCRIPT DE REDIRECT DESPUÉS DE LOGIN/REGISTRO ==========
        console.log('🔐 Script de redirect cargado en header');
        
        var redirectUrl = localStorage.getItem('zm_redirect_after_login');
        var isRegistration = localStorage.getItem('zm_is_registration') === 'true';
        console.log('🔐 Verificando localStorage zm_redirect_after_login:', redirectUrl);
        console.log('🔐 ¿Es registro?:', isRegistration);
        
        if (redirectUrl) {
            console.log('✅ URL de redirect guardada:', redirectUrl);
            
            // Guardar que el usuario acaba de registrarse
            localStorage.setItem('zm_just_registered', 'true');
            
            var redirectExecuted = false;
            var headerAuthContainer = document.getElementById('header-auth-container');
            
            // Monitorear si el usuario se loguea (verificar cada 100ms)
            var checkLoginInterval = setInterval(function() {
                // Verificar si el usuario está logueado
                var isLoggedIn = document.body.classList.contains('logged-in');
                var isAuthContainerHidden = headerAuthContainer && (headerAuthContainer.style.display === 'none' || window.getComputedStyle(headerAuthContainer).display === 'none');
                
                if ((isLoggedIn || isAuthContainerHidden) && !redirectExecuted) {
                    console.log('✅ Usuario logueado detectado, redirigiendo a:', redirectUrl);
                    redirectExecuted = true;
                    clearInterval(checkLoginInterval);
                    localStorage.removeItem('zm_redirect_after_login');
                    localStorage.removeItem('zm_is_registration');
                    
                    // Pequeño delay para asegurar que la página está lista
                    setTimeout(function() {
                        window.location.href = redirectUrl;
                    }, 300);
                }
            }, 100);
            
            // Timeout diferente según sea registro o login
            // Para registro: 3 segundos (tarda más en procesar)
            // Para login: no usar timeout, solo esperar a que se detecte el login
            if (isRegistration) {
                setTimeout(function() {
                    if (!redirectExecuted) {
                        console.log('⏱️ Timeout de registro (3s) alcanzado, redirigiendo de todas formas');
                        redirectExecuted = true;
                        clearInterval(checkLoginInterval);
                        localStorage.removeItem('zm_redirect_after_login');
                        localStorage.removeItem('zm_is_registration');
                        window.location.href = redirectUrl;
                    }
                }, 3000);
            } else {
                // Para login: timeout de seguridad muy largo (20s) solo para limpiar
                setTimeout(function() {
                    if (!redirectExecuted) {
                        console.log('⏱️ Timeout de seguridad (20s) alcanzado, limpiando localStorage');
                        clearInterval(checkLoginInterval);
                        localStorage.removeItem('zm_redirect_after_login');
                        localStorage.removeItem('zm_is_registration');
                    }
                }, 20000);
            }
        } else {
            console.log('🔐 No hay URL de redirect en localStorage');
        }
    });
    </script>
</head>
<body <?php astra_schema_body(); ?> <?php body_class(); ?>>
<?php astra_body_top(); ?>
<?php wp_body_open(); ?>

<!-- HEADER STICKY INICIO -->
<header class="mobile-header-sticky" role="banner">
  <div class="header-left">
    <?php
    if ( function_exists( 'the_custom_logo' ) && has_custom_logo() ) {
        the_custom_logo();
    } else {
        echo '<a href="' . esc_url( home_url( '/' ) ) . '">' . esc_html( get_bloginfo( 'name' ) ) . '</a>';
    }
    ?>
  </div>

  <div class="header-center">
    <span class="site-title-compact">
      <?php echo esc_html( get_bloginfo( 'name' ) ); ?>
    </span>
  </div>

  <!-- BARRA DE BÚSQUEDA EN EL HEADER (visible en todos los dispositivos) -->
  <div class="header-search-wrap">
    <form action="<?php echo esc_url( home_url( '/buscar/' ) ); ?>" method="get" class="header-search-bar" role="search" aria-label="<?php echo esc_attr__( 'Buscar anuncios', 'your-textdomain' ); ?>">
      <input type="text" name="search_term" placeholder="<?php echo esc_attr__( 'Buscar en Zoomubik...', 'your-textdomain' ); ?>" class="header-search-input" />
      <button type="submit" class="header-search-btn" aria-label="<?php echo esc_attr__( 'Buscar', 'your-textdomain' ); ?>">
        <svg width="22" height="22" viewBox="0 0 22 22" fill="none" aria-hidden="true" focusable="false">
          <title><?php echo esc_html__( 'Icono de búsqueda', 'your-textdomain' ); ?></title>
          <circle cx="10" cy="10" r="8" stroke="#1976d2" stroke-width="2"/>
          <line x1="16" y1="16" x2="21" y2="21" stroke="#1976d2" stroke-width="2"/>
        </svg>
      </button>
    </form>
    <!-- BOTÓN DE REGISTRO EN MÓVIL -->
    <button id="header-registro-btn" class="header-search-btn" style="background: none; padding: 0; margin-left: 8px;" aria-label="Registro">
      <svg width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">
        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
        <circle cx="12" cy="7" r="4"/>
      </svg>
    </button>
  </div>

  <div class="header-right header-buttons" role="navigation" aria-label="<?php echo esc_attr__( 'Menú superior', 'your-textdomain' ); ?>">
    <?php
      wp_nav_menu( array(
        'theme_location' => 'top-sticky',
        'menu_class'     => 'header-btns-list',
        'container'      => false,
        'link_before'    => '<span class="header-btn">',
        'link_after'     => '</span>',
        'fallback_cb'    => false,
      ) );
    ?>
    <!-- BOTÓN DE REGISTRO EN DESKTOP -->
    <div id="header-auth-container" style="display: flex; flex-direction: column; align-items: center; gap: 0;">
      <button id="header-registro-btn-desktop" class="header-btn" style="background: #2563eb; padding: 12px 28px; border-radius: 8px; border: none; cursor: pointer; font-weight: 600; display: none; font-size: 15px;">
        Acceder
      </button>
    </div>
  </div>
</header>
<!-- HEADER STICKY FIN -->

<div <?php
    echo wp_kses_post(
        astra_attr(
            'site',
            array(
                'id'    => 'page',
                'class' => 'hfeed site',
            )
        )
    );
    ?>>
    <?php astra_content_before(); ?>
    <div id="content" class="site-content">
        <div class="ast-container">
        <?php astra_content_top(); ?>