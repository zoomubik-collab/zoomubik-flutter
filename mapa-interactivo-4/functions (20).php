<?php

// === Encolar el CSS del tema hijo (style.css) y el mapa ===
add_action('wp_enqueue_scripts', function() {
    wp_enqueue_style('astra-style', get_template_directory_uri() . '/style.css');
    wp_enqueue_style('postaldream-child-style', get_stylesheet_uri(), array('astra-style'), '1.1'); // Versión actualizada
    wp_enqueue_style('mapa-css', plugins_url('mapa-interactivo-4/css/mapa.css'), array(), '2.2');
    // Encolar el CSS del footer sticky
    // COMENTADO: archivo no existe, causaba 404
    // wp_enqueue_style('footer-sticky-css', get_stylesheet_directory_uri() . '/includes/style.css', array(), '1.1');
});

// === PRELOAD DE RECURSOS CRÍTICOS PARA VELOCIDAD ===
add_action('wp_head', function() {
    echo '<link rel="preconnect" href="https://maps.googleapis.com">' . "\n";
    echo '<link rel="preconnect" href="https://fonts.googleapis.com">' . "\n";
    echo '<link rel="dns-prefetch" href="//maps.googleapis.com">' . "\n";
    
    // Ocultar imagen no deseada lo más rápido posible
    echo '<style>img[src*="1000108795_b6c5a4e8135d7ba506bcecb91aa8e2e4"],img[src*="wp-content/uploads/2025/05/1000108795"]{display:none!important;visibility:hidden!important;width:0!important;height:0!important;position:absolute!important;left:-9999px!important;top:-9999px!important;opacity:0!important;}</style>' . "\n";
}, 1);

// Filtro para ocultar la imagen en el contenido
add_filter('the_content', function($content) {
    $content = preg_replace('/<img[^>]*src=["\']?[^"\']*1000108795[^"\']*["\']?[^>]*>/i', '', $content);
    return $content;
});

// === LAZY LOADING AUTOMÁTICO DE IMÁGENES ===
add_filter('wp_get_attachment_image_attributes', function($attr) {
    // No añadir lazy loading si ya tiene fetchpriority="high"
    if (!isset($attr['loading']) && (!isset($attr['fetchpriority']) || $attr['fetchpriority'] !== 'high')) {
        $attr['loading'] = 'lazy';
    }
    return $attr;
});

add_filter('the_content', function($content) {
    if (is_feed() || is_admin()) return $content;
    // No añadir lazy loading a imágenes que ya tienen fetchpriority="high"
    $content = preg_replace_callback('/<img\s+([^>]*?)>/i', function($matches) {
        $tag = $matches[1];
        if (strpos($tag, 'fetchpriority="high"') !== false || strpos($tag, "fetchpriority='high'") !== false) {
            return '<img ' . $tag . '>';
        }
        if (strpos($tag, 'loading=') === false) {
            return '<img loading="lazy" ' . $tag . '>';
        }
        return '<img ' . $tag . '>';
    }, $content);
    return $content;
});

// === Shortcode: Últimos 3 posts, títulos adaptables y responsive ===
if (!function_exists('ultimos_tres_posts_hz_adaptable')) :
function ultimos_tres_posts_hz_adaptable() {
    $recent_posts = new WP_Query(array(
        'posts_per_page' => 3,
        'post_status' => 'publish'
    ));
    ob_start();
    if ($recent_posts->have_posts()) { ?>
        <style>
        .ultimos-posts-home-hz { display: flex; gap: 22px; justify-content: center; margin: 2em 0; max-width: 100vw; overflow-x: visible;}
        .ultimos-posts-home-hz .post-item {background: #f7fafd; border-radius: 12px; box-shadow: 0 2px 12px rgba(59,161,218,0.09); padding: 18px 10px; max-width: 320px; width: 100%; display: flex; flex-direction: column; box-sizing: border-box;}
        .ultimos-posts-home-hz .post-thumb {display: flex; justify-content: center; height: 150px; width: 100%; margin-bottom: 10px;}
        .ultimos-posts-home-hz .post-thumb img {border-radius: 10px; width: 100%; max-width: 260px; height: 100%; object-fit: cover; box-shadow: 0 2px 10px rgba(21,65,138,0.07);}
        .ultimos-posts-home-hz .post-title {font-size: 1.1em; font-weight: bold; color: #15418a; text-align: center; text-decoration: none; margin-top: 0.3em; line-height: 1.3em; min-height: 2.6em; word-break: normal; overflow-wrap: anywhere; hyphens: auto; white-space: normal; display: block;}
        @media (max-width: 900px) {
            .ultimos-posts-home-hz {flex-direction: column; gap: 16px; align-items: center;}
            .ultimos-posts-home-hz .post-item {max-width: 99vw; width: 99vw;}
            .ultimos-posts-home-hz .post-thumb img {max-width: 98vw; width: 100%; height: auto; object-fit: contain;}
            .ultimos-posts-home-hz .post-title {font-size: 1.05em; min-height: 2.5em; line-height: 1.25em;}
        }
        </style>
        <section class="ultimos-posts-home-hz">
        <?php while ($recent_posts->have_posts()) { $recent_posts->the_post(); ?>
            <div class="post-item">
                <a class="post-thumb" href="<?php the_permalink(); ?>">
                    <?php
                    if (has_post_thumbnail()) {
                        the_post_thumbnail('large', [
                            'alt' => get_the_title(),
                            'loading' => 'lazy'
                        ]);
                    } else {
                        echo '<img src="https://via.placeholder.com/260x150?text=Sin+Imagen" alt="Sin imagen" loading="lazy">';
                    }
                    ?>
                </a>
                <a class="post-title" href="<?php the_permalink(); ?>"><?php the_title(); ?></a>
            </div>
        <?php } ?>
        </section>
        <?php
        wp_reset_postdata();
    }
    return ob_get_clean();
}
endif;
add_shortcode('ultimos_posts', 'ultimos_tres_posts_hz_adaptable');

// === FUNCIÓN CTA PUBLICAR ANUNCIO ADAPTATIVO (con estilos y posición personalizada) ===
function mostrar_publicar_anuncio_adaptativo($ubicacion = 'categoria') {
    // Solo mostrar en home
    if ($ubicacion === 'home') {
        ?>
        <div class="pd-cta-bloque-anuncio pd-cta-enmarcado-home">
            <div class="pd-cta-bloque-anuncio-top">
                ¿Cansado de buscar vivienda?
            </div>
            <button id="mostrar-formulario-btn" class="pd-btn-primary pd-btn-anuncio-azul-contorno destello-azul">
                <span class="pd-btn-icon">★</span>
                Publicar anuncio
            </button>
            <div class="pd-cta-bloque-anuncio-bottom">
                ¡Dale la vuelta y deja que te encuentren!
            </div>
        </div>
        <style>
        .pd-cta-enmarcado-home {
            max-width: 400px;
            margin: 40px auto 30px auto;
            border: 3px solid #ffe082;
            background: #fffbe0;
            border-radius: 18px;
            box-shadow: 0 4px 24px rgba(247,201,72,0.13);
            padding: 30px 28px 18px 28px;
            text-align: center;
        }
        </style>
        <?php
        return;
    }
    
    // Para categorías, no mostrar nada (el bloque se muestra desde JavaScript en mapa.js)
    return;
}

// === AGREGAR SCRIPT PARA MOSTRAR BLOQUE DE PUBLICAR EN CATEGORÍAS ===
add_action('wp_footer', function() {
    if (is_page() && in_array(get_query_var('pagename'), [
        'desean-alquilar-vivienda',
        'desean-comprar-vivienda',
        'desean-compartir-piso',
        'desean-alquilar-plaza-de-garaje',
        'desean-comprar-plaza-de-garaje',
        'desean-alquilar-habitacion',
        'desean-compartir-garaje'
    ])) {
        ?>
        <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Crear contenedor de fondo
            var bgDiv = document.createElement("div");
            bgDiv.id = "form-provincia-categoria";
            bgDiv.style.cssText = `
                background: linear-gradient(135deg, #e8ecf1 0%, #f0f3f7 100%);
                padding: 25px 20px;
                margin: 20px auto;
                width: 100%;
                max-width: 100%;
                display: flex;
                justify-content: center;
                align-items: center;
            `;
            
            var div = document.createElement("div");
            div.id = "form-provincia-categoria-inner";
            div.style.cssText = `
                background: linear-gradient(135deg, #f5f7fa 0%, #ffffff 100%);
                border: 3px solid;
                border-image: linear-gradient(45deg, #9c27b0, #ff9800, #4ecdc4, #00e676, #9c27b0) 1;
                padding: 20px 20px;
                border-radius: 12px;
                box-shadow: 0 0 20px rgba(156, 39, 176, 0.3), 0 0 30px rgba(255, 152, 0, 0.3), 0 0 40px rgba(78, 205, 196, 0.2), 0 0 60px rgba(0, 230, 118, 0.2), inset 0 0 20px rgba(156, 39, 176, 0.05);
                text-align: center;
                max-width: 420px;
                margin: 0 auto;
                position: relative;
                overflow: hidden;
                animation: neon-glow-home 3s ease-in-out infinite;
            `;
            
            // Agregar animación CSS
            var styleTag = document.createElement("style");
            styleTag.textContent = `
                @keyframes neon-glow-home {
                    0%, 100% { 
                        box-shadow: 0 0 20px rgba(156, 39, 176, 0.3), 0 0 30px rgba(255, 152, 0, 0.3), 0 0 40px rgba(78, 205, 196, 0.2), 0 0 60px rgba(0, 230, 118, 0.2), inset 0 0 20px rgba(156, 39, 176, 0.05);
                    }
                    50% { 
                        box-shadow: 0 0 30px rgba(156, 39, 176, 0.5), 0 0 40px rgba(255, 152, 0, 0.5), 0 0 60px rgba(78, 205, 196, 0.4), 0 0 80px rgba(0, 230, 118, 0.4), inset 0 0 30px rgba(156, 39, 176, 0.1);
                    }
                }
            `;
            document.head.appendChild(styleTag);
            
            div.innerHTML = `
              <div style="position: absolute; top: -50px; right: -50px; width: 150px; height: 150px; background: radial-gradient(circle, rgba(0,0,0,0.02) 0%, transparent 70%); border-radius: 50%;"></div>
              
              <div style="margin-bottom: 20px;">
                <h3 style="
                  font-weight: 700;
                  font-size: 1.35em;
                  color: #15418a;
                  margin: 0 0 6px 0;
                  line-height: 1.3;
                ">
                  Publica tu anuncio GRATIS
                </h3>
                <p style="
                  color: #666;
                  font-size: 0.9em;
                  margin: 0;
                  line-height: 1.4;
                ">
                  Selecciona tu provincia y deja que te encuentren
                </p>
              </div>
              
              <!-- Flecha animada apuntando al select -->
              <div style="text-align:center;margin-bottom:5px;animation:bounce 2s infinite;">
                <svg width="50" height="50" viewBox="0 0 24 24" fill="none" style="filter:drop-shadow(0 3px 6px rgba(37,211,102,0.5));">
                  <path d="M12 4v16m0 0l-6-6m6 6l6-6" stroke="#25D366" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
              </div>
              <style>
                @keyframes bounce {
                  0%, 20%, 50%, 80%, 100% { transform: translateY(0); }
                  40% { transform: translateY(-15px); }
                  60% { transform: translateY(-8px); }
                }
              </style>
              
              <div style="margin-bottom: 15px; text-align: center; display: flex; justify-content: center; width: 100%;">
                <select id="selector-provincia-categoria" style="width:90%;max-width:300px;padding:12px 15px;font-size:16px;border:2px solid #3ba1da;border-radius:8px;background:white;color:black;height:55px;line-height:1.5;box-sizing:border-box;margin:0 auto;">
                  <option value="">Selecciona tu provincia</option>
                  <option value="alava">Álava</option>
                  <option value="albacete">Albacete</option>
                  <option value="alicante">Alicante</option>
                  <option value="almeria">Almería</option>
                  <option value="asturias">Asturias</option>
                  <option value="avila">Ávila</option>
                  <option value="badajoz">Badajoz</option>
                  <option value="barcelona">Barcelona</option>
                  <option value="burgos">Burgos</option>
                  <option value="caceres">Cáceres</option>
                  <option value="cadiz">Cádiz</option>
                  <option value="cantabria">Cantabria</option>
                  <option value="castellon">Castellón</option>
                  <option value="ciudad-real">Ciudad Real</option>
                  <option value="cordoba">Córdoba</option>
                  <option value="a-coruna">A Coruña</option>
                  <option value="cuenca">Cuenca</option>
                  <option value="girona">Girona</option>
                  <option value="granada">Granada</option>
                  <option value="guadalajara">Guadalajara</option>
                  <option value="guipuzcoa">Guipúzcoa</option>
                  <option value="huelva">Huelva</option>
                  <option value="huesca">Huesca</option>
                  <option value="illes-balears">Illes Balears</option>
                  <option value="jaen">Jaén</option>
                  <option value="leon">León</option>
                  <option value="lleida">Lleida</option>
                  <option value="lugo">Lugo</option>
                  <option value="madrid">Madrid</option>
                  <option value="malaga">Málaga</option>
                  <option value="murcia">Murcia</option>
                  <option value="navarra">Navarra</option>
                  <option value="ourense">Ourense</option>
                  <option value="palencia">Palencia</option>
                  <option value="las-palmas">Las Palmas</option>
                  <option value="pontevedra">Pontevedra</option>
                  <option value="la-rioja">La Rioja</option>
                  <option value="salamanca">Salamanca</option>
                  <option value="santa-cruz-de-tenerife">Santa Cruz de Tenerife</option>
                  <option value="segovia">Segovia</option>
                  <option value="sevilla">Sevilla</option>
                  <option value="soria">Soria</option>
                  <option value="tarragona">Tarragona</option>
                  <option value="teruel">Teruel</option>
                  <option value="toledo">Toledo</option>
                  <option value="valencia">Valencia</option>
                  <option value="valladolid">Valladolid</option>
                  <option value="vizcaya">Vizcaya</option>
                  <option value="zamora">Zamora</option>
                  <option value="zaragoza">Zaragoza</option>
                  <option value="ceuta">Ceuta</option>
                  <option value="melilla">Melilla</option>
                </select>
              </div>
            `;
            
            // Insertar el marco después del mapa
            const mapaWrapper = document.querySelector(".mapa-interactivo-wrapper");
            if (mapaWrapper && mapaWrapper.parentNode) {
                bgDiv.appendChild(div);
                mapaWrapper.parentNode.insertBefore(bgDiv, mapaWrapper.nextSibling);
            } else {
                const bloqueCentral = document.querySelector(".bloque-central");
                if (bloqueCentral) {
                    const miniAnuncios = document.getElementById("mini-anuncios-provincia");
                    bgDiv.appendChild(div);
                    if (miniAnuncios) {
                        bloqueCentral.insertBefore(bgDiv, miniAnuncios);
                    } else {
                        bloqueCentral.appendChild(bgDiv);
                    }
                } else {
                    bgDiv.appendChild(div);
                    document.body.appendChild(bgDiv);
                }
            }
            
            // Agregar evento al select
            const selector = document.getElementById('selector-provincia-categoria');
            if (selector) {
                selector.addEventListener('change', function() {
                    const slug = this.value;
                    if (slug) {
                        window.location.href = "/provincias/" + slug + "/";
                    }
                });
            }
        });
        </script>
        <?php
    }
});

// === CARGAR CSS SOLO EN LA URL DE DETALLE DE MARCADOR (tanto por slug como por id) ===
function detalle_marcador_styles() {
    if (
        strpos($_SERVER['REQUEST_URI'], 'detalle-de-marcador') !== false ||
        (get_query_var('anuncio_categoria') && get_query_var('anuncio_provincia') && get_query_var('anuncio_titulo'))
    ) {
        wp_enqueue_style(
            'detalle-marcador',
            get_stylesheet_directory_uri() . '/css/detalle-marcador.css',
            [],
            '1.0'
        );
    }
}
add_action('wp_enqueue_scripts', 'detalle_marcador_styles');

// === MENÚ STICKY SUPERIOR ===
register_nav_menus([
  'top-sticky' => 'Menú Sticky Superior',
]);

// === REGLAS DE URLS AMIGABLES ===
add_action('init', function() {
    // /categoria/provincia/titulo/
    add_rewrite_rule(
        '^([a-z0-9-]+)/([a-z0-9-]+)/([a-z0-9-]+)/?$',
        'index.php?anuncio_categoria=$matches[1]&anuncio_provincia=$matches[2]&anuncio_titulo=$matches[3]',
        'top'
    );
    // /CATEGORIA/PROVINCIA/ (incluye desean-alquilar-habitacion)
    add_rewrite_rule(
        '^(desean-alquilar-vivienda|desean-comprar-vivienda|desean-compartir-piso|desean-alquilar-plaza-de-garaje|desean-comprar-plaza-de-garaje|desean-alquilar-habitacion|desean-compartir-garaje)/([a-z0-9-]+)/?$',
        'index.php?pagename=$matches[1]&provincia=$matches[2]',
        'top'
    );
    // /CATEGORIA/ (base solo categoría)
    add_rewrite_rule(
        '^(desean-alquilar-vivienda|desean-comprar-vivienda|desean-compartir-piso|desean-alquilar-plaza-de-garaje|desean-comprar-plaza-de-garaje|desean-alquilar-habitacion|desean-compartir-garaje)/?$',
        'index.php?pagename=$matches[1]',
        'top'
    );
});
add_filter('query_vars', function($vars) {
    $vars[] = 'anuncio_categoria';
    $vars[] = 'anuncio_provincia';
    $vars[] = 'anuncio_titulo';
    $vars[] = 'provincia';
    return $vars;
});

// === REDIRECCIÓN DESDE LA URL ANTIGUA (?id=XXX) ===
add_action('template_redirect', function() {
    if (isset($_GET['id']) && is_numeric($_GET['id'])) {
        global $wpdb;
        $table = $wpdb->prefix . "marcadores";
        $anuncio = $wpdb->get_row($wpdb->prepare("SELECT * FROM $table WHERE id = %d", $_GET['id']));
        if ($anuncio && $anuncio->categoria_slug && $anuncio->provincia_slug && $anuncio->titulo_slug) {
            $url = '/' . $anuncio->categoria_slug . '/' . $anuncio->provincia_slug . '/' . $anuncio->titulo_slug . '/';
            wp_redirect($url, 301);
            exit;
        }
    }
});

// === PLANTILLA PARA MOSTRAR EL ANUNCIO SEGÚN LA URL AMIGABLE ===
// Preparar datos del anuncio en template_redirect
add_action('template_redirect', function() {
    $cat = get_query_var('anuncio_categoria');
    $prov = get_query_var('anuncio_provincia');
    $title = get_query_var('anuncio_titulo');
    
    if ($cat && $prov && $title) {
        global $wpdb;
        $table = $wpdb->prefix . "marcadores";
        $anuncio = $wpdb->get_row(
            $wpdb->prepare(
                "SELECT * FROM $table WHERE categoria_slug = %s AND provincia_slug = %s AND titulo_slug = %s",
                $cat, $prov, $title
            )
        );
        
        // Guardar el anuncio para usarlo en el template
        set_query_var('anuncio', $anuncio);
        
        // Añadir meta tags SEO y Schema.org
        if ($anuncio) {
            add_action('wp_head', function() use ($anuncio) {
                $titulo = esc_html($anuncio->titulo);
                $descripcion = esc_html(mb_substr($anuncio->comentario, 0, 160));
                $url = home_url('/' . $anuncio->categoria_slug . '/' . $anuncio->provincia_slug . '/' . $anuncio->titulo_slug . '/');
                $imagen = !empty($anuncio->avatar_url) ? esc_url($anuncio->avatar_url) : 'https://zoomubik.com/wp-content/uploads/2025/06/postaldrem_avatar.jpg';
                
                // Meta tags básicos
                echo '<meta name="description" content="' . $descripcion . '">' . "\n";
                echo '<meta name="robots" content="index, follow">' . "\n";
                echo '<link rel="canonical" href="' . $url . '">' . "\n";
                
                // Open Graph
                echo '<meta property="og:title" content="' . $titulo . '">' . "\n";
                echo '<meta property="og:description" content="' . $descripcion . '">' . "\n";
                echo '<meta property="og:url" content="' . $url . '">' . "\n";
                echo '<meta property="og:type" content="article">' . "\n";
                echo '<meta property="og:image" content="' . $imagen . '">' . "\n";
                echo '<meta property="og:site_name" content="Zoomubik">' . "\n";
                
                // Twitter Card
                echo '<meta name="twitter:card" content="summary_large_image">' . "\n";
                echo '<meta name="twitter:title" content="' . $titulo . '">' . "\n";
                echo '<meta name="twitter:description" content="' . $descripcion . '">' . "\n";
                echo '<meta name="twitter:image" content="' . $imagen . '">' . "\n";
                
                // Schema.org JSON-LD
                $precio = '';
                if (!empty($anuncio->precio_alquiler)) $precio = $anuncio->precio_alquiler;
                elseif (!empty($anuncio->precio_compra)) $precio = $anuncio->precio_compra;
                elseif (!empty($anuncio->precio_garaje)) $precio = $anuncio->precio_garaje;
                elseif (!empty($anuncio->precio_alquiler_habitacion)) $precio = $anuncio->precio_alquiler_habitacion;
                
                $schema = [
                    "@context" => "https://schema.org",
                    "@type" => "RealEstateListing",
                    "name" => $titulo,
                    "description" => $anuncio->comentario,
                    "url" => $url,
                    "image" => $imagen,
                    "datePosted" => date('Y-m-d', strtotime($anuncio->fecha ?? 'now')),
                    "address" => [
                        "@type" => "PostalAddress",
                        "addressRegion" => ucwords(str_replace('-', ' ', $anuncio->provincia)),
                        "addressCountry" => "ES"
                    ]
                ];
                
                if ($precio) {
                    $schema["offers"] = [
                        "@type" => "Offer",
                        "price" => $precio,
                        "priceCurrency" => "EUR"
                    ];
                }
                
                echo '<script type="application/ld+json">' . json_encode($schema, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) . '</script>' . "\n";
            }, 1);
        }
    }
});

// Usar template_include en lugar de include + exit para mantener el ciclo de WordPress
add_filter('template_include', function($template) {
    $cat = get_query_var('anuncio_categoria');
    $prov = get_query_var('anuncio_provincia');
    $title = get_query_var('anuncio_titulo');
    
    if ($cat && $prov && $title) {
        $custom_template = locate_template('page-detalle-de-marcador.php');
        if ($custom_template) {
            return $custom_template;
        }
    }
    
    return $template;
});

// === FUNCIÓN: DEVUELVE EL ICONO DE MARCADOR SEGÚN LA CATEGORÍA (SLUG) ===
function icono_marcador_por_categoria($cat) {
    if (!$cat) return "https://maps.google.com/mapfiles/ms/icons/yellow-dot.png";
    $cat = strtolower($cat);
    $catNorm = str_replace('-', ' ', $cat);

    if ($cat === "desean-alquilar-plaza-de-garaje" || $catNorm === "desean alquilar plaza de garaje")
        return "https://maps.google.com/mapfiles/ms/icons/orange-dot.png";
    if ($cat === "desean-comprar-plaza-de-garaje" || $catNorm === "desean comprar plaza de garaje")
        return "https://maps.google.com/mapfiles/ms/icons/ltblue-dot.png";
    if ($cat === "desean-compartir-garaje" || $catNorm === "desean compartir garaje")
        return "https://maps.google.com/mapfiles/ms/icons/pink-dot.png";
    if (strpos($cat, "comprar") !== false || strpos($catNorm, "comprar") !== false)
        return "https://maps.google.com/mapfiles/ms/icons/red-dot.png";
    if (strpos($cat, "habitacion") !== false || strpos($catNorm, "habitacion") !== false)
        return "https://maps.google.com/mapfiles/ms/icons/purple-dot.png";
    if (strpos($cat, "compartir") !== false || strpos($catNorm, "compartir") !== false)
        return "https://maps.google.com/mapfiles/ms/icons/blue-dot.png";
    if (strpos($cat, "vivienda") !== false || strpos($catNorm, "vivienda") !== false)
        return "https://maps.google.com/mapfiles/ms/icons/green-dot.png";
    return "https://maps.google.com/mapfiles/ms/icons/yellow-dot.png";
}

// === BREADCRUMBS CON SCHEMA.ORG ===
function mostrar_breadcrumbs($categoria = '', $provincia = '', $titulo = '') {
    $breadcrumbs = [
        ['name' => 'Inicio', 'url' => home_url('/')]
    ];
    
    if ($categoria) {
        $cat_nombre = ucwords(str_replace('-', ' ', $categoria));
        $breadcrumbs[] = ['name' => $cat_nombre, 'url' => home_url('/' . $categoria . '/')];
    }
    
    if ($provincia) {
        $prov_nombre = ucwords(str_replace('-', ' ', $provincia));
        $breadcrumbs[] = ['name' => $prov_nombre, 'url' => home_url('/' . $categoria . '/' . $provincia . '/')];
    }
    
    if ($titulo) {
        $breadcrumbs[] = ['name' => ucwords(str_replace('-', ' ', $titulo)), 'url' => ''];
    }
    
    // HTML visible
    echo '<nav class="breadcrumbs" style="padding:10px 0;margin-bottom:15px;margin-top:80px;font-size:14px;color:#666;">';
    foreach ($breadcrumbs as $i => $crumb) {
        if ($i > 0) echo ' › ';
        if ($crumb['url']) {
            echo '<a href="' . esc_url($crumb['url']) . '" style="color:#15418a;text-decoration:none;">' . esc_html($crumb['name']) . '</a>';
        } else {
            echo '<span style="color:#666;">' . esc_html($crumb['name']) . '</span>';
        }
    }
    echo '</nav>';
    
    // Schema.org JSON-LD
    $schema = [
        "@context" => "https://schema.org",
        "@type" => "BreadcrumbList",
        "itemListElement" => []
    ];
    
    foreach ($breadcrumbs as $i => $crumb) {
        $schema["itemListElement"][] = [
            "@type" => "ListItem",
            "position" => $i + 1,
            "name" => $crumb['name'],
            "item" => $crumb['url'] ?: home_url($_SERVER['REQUEST_URI'])
        ];
    }
    
    echo '<script type="application/ld+json">' . json_encode($schema, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) . '</script>';
}

// === Helper: Capitalizar provincia para presentación ===
function nombre_provincia_presentacion($provincia_slug) {
    return ucwords(str_replace('-', ' ', $provincia_slug));
}

// === BOTONES DE CATEGORÍAS NAVEGABLES (MODIFICADO SOLO "Volver" fuera de home) ===
function mostrar_botones_categorias_nav() {
    $provincia = get_query_var('provincia');
    $categoria = get_query_var('anuncio_categoria');
    $is_home = is_front_page() || is_home() || is_page('mapa-interactivo');

    $categorias = [
        'desean-alquilar-habitacion' => 'Desean compartir piso',
        'desean-alquilar-vivienda' => 'Desean alquilar vivienda',
        'desean-comprar-vivienda' => 'Desean comprar vivienda',
        'desean-alquilar-plaza-de-garaje' => 'Desean alquilar plaza de garaje',
        'desean-comprar-plaza-de-garaje' => 'Desean comprar plaza de garaje',
    ];
    ?>
    <div id="categoria-botones" style="text-align:center;margin-bottom:12px;">
        <?php
        if ($is_home) : // Solo en la home o página principal del mapa
            foreach($categorias as $slug => $label):
                $url = $provincia ? "/$slug/$provincia/" : "/$slug/";
        ?>
                <a href="<?php echo esc_url($url); ?>" class="categoria-btn"><?php echo esc_html($label); ?></a>
        <?php
            endforeach;
        endif; ?>
    </div>
    <style>
    .volver-btn {
        background: linear-gradient(90deg, #eee 0%, #bbb 100%);
        color: #15418a;
        font-weight: bold;
        border: none;
        padding: 13px 32px;
        border-radius: 8px;
        font-size: 18px;
        margin-bottom: 12px;
        box-shadow: 0 2px 9px rgba(21,65,138,0.09);
        text-decoration: none;
        display: inline-block;
    }
    .volver-btn:hover,
    .volver-btn:focus {
        background: linear-gradient(90deg, #bbb 0%, #eee 100%);
        color: #15418a;
    }
    </style>
    <script>
    // Marcar activo el botón según la URL
    document.addEventListener("DOMContentLoaded", function() {
        var path = window.location.pathname.replace(/\/$/, '');
        document.querySelectorAll("#categoria-botones .categoria-btn").forEach(function(btn) {
            if (btn.getAttribute("href").replace(/\/$/, '') === path) {
                btn.classList.add("active");
            }
        });
    });
    </script>
    <?php
}

// === BLOQUE PARA MOSTRAR EL MAPA Y LOS MINIANUNCIOS FILTRADOS EN URLs CATEGORIA/PROVINCIA Y SOLO CATEGORIA ===
add_action('wp', function() {
    $categorias = [
        'desean-alquilar-vivienda',
        'desean-comprar-vivienda',
        'desean-compartir-piso',
        'desean-alquilar-plaza-de-garaje',
        'desean-comprar-plaza-de-garaje',
        'desean-alquilar-habitacion',
        'desean-compartir-garaje'
    ];
    foreach ($categorias as $cat) {
        if (is_page($cat)) {
            // Añadir meta tags SEO para páginas de categorías
            add_action('wp_head', function() use ($cat) {
                $provincia = get_query_var('provincia');
                $cat_nombre = ucwords(str_replace('-', ' ', $cat));
                
                if ($provincia) {
                    $prov_nombre = ucwords(str_replace('-', ' ', $provincia));
                    $titulo = $cat_nombre . ' en ' . $prov_nombre . ' | Zoomubik';
                    $descripcion = 'Encuentra personas que ' . strtolower($cat_nombre) . ' en ' . $prov_nombre . '. Publica tu búsqueda gratis y conecta con propietarios e inmobiliarias.';
                    $url = home_url('/' . $cat . '/' . $provincia . '/');
                } else {
                    $titulo = $cat_nombre . ' en España | Zoomubik';
                    $descripcion = 'Encuentra personas que ' . strtolower($cat_nombre) . ' en toda España. Publica tu anuncio gratis en el mapa y recibe ofertas.';
                    $url = home_url('/' . $cat . '/');
                }
                
                echo '<title>' . esc_html($titulo) . '</title>' . "\n";
                echo '<meta name="description" content="' . esc_attr($descripcion) . '">' . "\n";
                echo '<link rel="canonical" href="' . esc_url($url) . '">' . "\n";
                echo '<meta property="og:title" content="' . esc_attr($titulo) . '">' . "\n";
                echo '<meta property="og:description" content="' . esc_attr($descripcion) . '">' . "\n";
                echo '<meta property="og:url" content="' . esc_url($url) . '">' . "\n";
                echo '<meta property="og:type" content="website">' . "\n";
            }, 1);
            
            add_action('the_content', function($content) use ($cat) {
                $provincia = get_query_var('provincia'); // puede estar vacío
                global $wpdb;
                $table = $wpdb->prefix . "marcadores";
                // Si hay provincia, filtra; si no, muestra todos de esa categoría
                if ($provincia) {
                    $anuncios = $wpdb->get_results(
                        $wpdb->prepare(
                            "SELECT * FROM $table WHERE categoria_slug = %s AND provincia_slug = %s ORDER BY id DESC LIMIT 50",
                            $cat, $provincia
                        )
                    );
                } else {
                    $anuncios = $wpdb->get_results(
                        $wpdb->prepare(
                            "SELECT * FROM $table WHERE categoria_slug = %s ORDER BY id DESC LIMIT 50",
                            $cat
                        )
                    );
                }

                ob_start();
                // Breadcrumbs
                mostrar_breadcrumbs($cat, $provincia);
                
                // AÑADIR CONTENIDO SEO AL INICIO
                echo do_shortcode('[contenido_categoria_seo]');
                
                // Botones de categorías navegables ANTES del mapa
                mostrar_botones_categorias_nav();

                // Contenido SEO ahora se inyecta via shortcode [contenido_categoria_seo]
                // El div .seo-content duplicado ha sido removido para evitar redundancia
                ?>
                <div class="mapa-interactivo-wrapper">
                    <div id="mapa-interactivo" style="height:500px;margin-bottom:10px;"></div>
                </div>
                <script>
                window.mapaCategoria = "<?php echo esc_js($cat); ?>";
                window.mapaProvincia = "<?php echo esc_js($provincia); ?>";
                window.mapa_ajax_obj = {
                    ajaxurl: "<?php echo admin_url('admin-ajax.php'); ?>",
                    usuario_logueado: "<?php echo is_user_logged_in() ? '1' : '0'; ?>",
                    user_id: "<?php echo get_current_user_id(); ?>",
                    is_admin: "<?php echo current_user_can('manage_options') ? '1' : '0'; ?>",
                    siteurl: "<?php echo site_url(); ?>",
                    provincia: "<?php echo esc_js($provincia); ?>",
                    modo: "normal",
                    login_url: "<?php echo site_url('/login'); ?>",
                    register_url: "<?php echo site_url('/register'); ?>"
                };
                </script>
                <?php
                // === MOSTRAR CTA PUBLICAR ANUNCIO ADAPTATIVO DEBAJO DEL MAPA ===
                mostrar_publicar_anuncio_adaptativo('categoria');
                ?>
                <div class="mini-anuncios-cards" style="margin-top:28px;">
                <?php
                if ($anuncios) {
                    foreach ($anuncios as $a) {
                        $url = '/' . $a->categoria_slug . '/' . $a->provincia_slug . '/' . $a->titulo_slug . '/';
                        
                        // Obtener avatar del usuario
                        $avatar = '';
                        if (!empty($a->user_id)) {
                            // Usar la función que tiene fallbacks integrados
                            if (function_exists('perfil_avatares_obtener_url_mapa')) {
                                $avatar = perfil_avatares_obtener_url_mapa($a->user_id);
                            } else {
                                // Fallback si la función no existe
                                if (function_exists('perfil_avatares_obtener_avatar')) {
                                    $avatar = perfil_avatares_obtener_avatar($a->user_id);
                                }
                            }
                        }
                        if (empty($avatar)) {
                            $avatar = 'https://zoomubik.com/wp-content/uploads/2025/06/postaldrem_avatar.jpg';
                        }
                        
                        $pin_icon = icono_marcador_por_categoria($a->categoria_slug);
                        $precio = "";
                        if (!empty($a->precio_garaje) && intval($a->precio_garaje) > 0)
                            $precio = number_format($a->precio_garaje, 0, ',', '.') . " €";
                        elseif (!empty($a->precio_alquiler) && intval($a->precio_alquiler) > 0)
                            $precio = number_format($a->precio_alquiler, 0, ',', '.') . " €";
                        elseif (!empty($a->precio_compra) && intval($a->precio_compra) > 0)
                            $precio = number_format($a->precio_compra, 0, ',', '.') . " €";
                        elseif (!empty($a->precio_alquiler_habitacion) && intval($a->precio_alquiler_habitacion) > 0)
                            $precio = number_format($a->precio_alquiler_habitacion, 0, ',', '.') . " €";
                        ?>
                        <a href="<?php echo esc_url($url); ?>" class="mini-anuncio-card">
                            <span class="corazon-favorito" data-id="<?php echo esc_attr($a->id); ?>" title="Añadir a favoritos">♡</span>
                            <div class="mini-anuncio-contenido" style="display:flex;flex-direction:column;align-items:center;gap:7px;">
                                <img src="<?php echo esc_url($avatar); ?>" alt="Avatar" class="mini-anuncio-avatar">
                                <button 
                                    type="button" 
                                    class="btn-mapa-zoom"
                                    title="Ver en el mapa"
                                    onclick="centrarEnMarcador(<?php echo esc_attr($a->id); ?>); event.stopPropagation(); return false;"
                                    style="margin-top:4px;">
                                    <img src="<?php echo esc_url($pin_icon); ?>" alt="Ir a marcador" class="google-pin-icon">
                                </button>
                                <div style="width:100%">
                                    <div class="mini-anuncio-titulo"><?php echo esc_html($a->titulo); ?></div>
                                    <?php if ($precio): ?>
                                        <div class="mini-anuncio-precio"><?php echo $precio; ?></div>
                                    <?php endif; ?>
                                    <div class="mini-anuncio-ciudad"><?php echo nombre_provincia_presentacion($a->provincia); ?></div>
                                    <div class="mini-anuncio-comentario"><?php echo esc_html(mb_substr($a->comentario, 0, 80)) . (mb_strlen($a->comentario) > 80 ? "..." : ""); ?></div>
                                </div>
                            </div>
                        </a>
                        <?php
                    }
                } else {
                    echo '<p>No hay anuncios en esta categoría' . ($provincia ? ' y provincia.' : '.') . '</p>';
                }
                ?>
                </div>
                <?php
                // Contador de anuncios y botón volver arriba
                $total_anuncios = count($anuncios);
                echo '<div style="text-align:center;margin:30px 0;padding:20px;background:#f8f9fa;border-radius:8px;">';
                echo '<p style="font-size:16px;color:#666;margin-bottom:15px;">📊 Mostrando <strong>' . $total_anuncios . '</strong> anuncios en esta zona</p>';
                echo '<button onclick="window.scrollTo({top:0,behavior:\'smooth\'})" style="background:linear-gradient(135deg,#3ba1da 0%,#15418a 100%);color:white;border:none;padding:12px 30px;border-radius:8px;font-size:16px;font-weight:600;cursor:pointer;box-shadow:0 4px 15px rgba(59,161,218,0.3);transition:all 0.3s;">⬆️ Volver arriba</button>';
                echo '</div>';
                
                // Añadir enlaces relacionados para SEO
                generar_enlaces_relacionados($provincia, $cat);
                
                return ob_get_clean();
            });
            // Encolar scripts y estilos siempre que se muestre el bloque
            add_action('wp_enqueue_scripts', function() {
                wp_enqueue_script('mapa-js', plugins_url('mapa-interactivo-4/js/mapa.js'), [], '1.4', true);
                wp_enqueue_style('mapa-css', plugins_url('mapa-interactivo-4/css/mapa.css'), [], '2.2');
                $k = esc_attr(get_option('mapa_interactivo_apikey'));
                if ($k) {
                    wp_enqueue_script('google-maps',
                        "https://maps.googleapis.com/maps/api/js?key=$k&libraries=places,geometry&callback=initMap",
                        [], null, true);
                }
            });
            break;
        }
    }
});

// === NO CACHE PARA LOGIN/REGISTER (WordPress + LiteSpeed) ===
function no_cache_for_custom_login_register() {
    $current_url = $_SERVER['REQUEST_URI'];
    $no_cache_urls = ['/login', '/register', '/wp-login.php', '/mensajes-privados'];
    
    foreach ($no_cache_urls as $url) {
        if (strpos($current_url, $url) !== false) {
            // Headers estándar de WordPress
            header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
            header("Pragma: no-cache");
            
            // Headers específicos para LiteSpeed Cache
            header("X-LiteSpeed-Cache-Control: no-cache");
            header("X-LiteSpeed-Cache: off");
            break;
        }
    }
}
add_action('send_headers', 'no_cache_for_custom_login_register');

// === EXCLUIR LOGIN DEL CACHE DE LITESPEED EN INIT ===
add_action('init', function() {
    $current_url = $_SERVER['REQUEST_URI'];
    $no_cache_urls = ['/login', '/register', '/wp-login.php', '/mensajes-privados'];
    
    foreach ($no_cache_urls as $url) {
        if (strpos($current_url, $url) !== false) {
            header('Cache-Control: no-cache, no-store, must-revalidate, max-age=0');
            header('X-LiteSpeed-Cache-Control: no-cache');
            header('X-LiteSpeed-Cache: off');
            break;
        }
    }
});

// === MODAL DE LOGIN MEJORADO PARA HEADER ===
add_action('wp_footer', function() {
    if (!is_user_logged_in()) {
        // Obtener URLs de Ultimate Member
        $um_login_url = function_exists('um_get_core_page_id') ? get_permalink( um_get_core_page_id('login') ) : home_url('/login/');
        $um_register_form_id = '17'; // ID del formulario de registro UM
        ?>
        <!-- Modal de login para header -->
        <div id="header-login-modal" class="modal-login-overlay" style="display:none;">
            <div class="modal-login-content">
                <button id="header-login-modal-close" class="modal-close" aria-label="Cerrar">&times;</button>
                
                <h2>Inicia sesión</h2>
                <div class="modal-login-buttons" id="header-modal-login-buttons">
                    <?php echo do_shortcode('[nextend_social_login provider="google" label="Continua con Google"]'); ?>
                    <button class="btn-email-login" onclick="window.location.href='<?php echo esc_url($um_login_url); ?>'">📧 Continuar con email</button>
                    <span class="modal-register-link" id="header-open-email-register">¿No tienes cuenta? Regístrate</span>
                </div>
                
                <div id="header-email-register-form" style="display:none;">
                    <h3>Registro por email</h3>
                    <?php echo do_shortcode('[ultimatemember form_id="' . esc_attr($um_register_form_id) . '"]'); ?>
                    <a href="#" id="header-back-to-login" style="display:block;margin-top:10px; color:#2563eb; text-decoration:underline;">Volver</a>
                </div>
            </div>
        </div>
        
        <style>
        /* Estilos del modal del header - copiados del footer */
        .modal-login-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.6);
            z-index: 9999;
            display: flex;
            align-items: center;
            justify-content: center;
            backdrop-filter: blur(2px);
        }
        
        .modal-login-content {
            background: white;
            border-radius: 12px;
            max-width: 420px;
            width: 90%;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
            animation: modalFadeIn 0.3s ease-out;
            position: relative;
            padding: 45px 25px 25px 25px;
        }
        
        @keyframes modalFadeIn {
            from { opacity: 0; transform: scale(0.9); }
            to { opacity: 1; transform: scale(1); }
        }
        
        .modal-close {
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
        
        .modal-close:hover {
            background: #f0f0f0;
            color: #333;
        }
        
        .modal-login-content h2,
        .modal-login-content h3 {
            margin-top: 0;
            margin-bottom: 15px;
            padding-right: 40px;
            line-height: 1.3;
            color: #333;
            text-align: center;
        }
        
        .modal-login-buttons {
            display: flex;
            flex-direction: column;
            gap: 15px;
        }
        
        .btn-email-login {
            display: block;
            text-align: center;
            padding: 14px 20px;
            background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
            border: none;
            border-radius: 8px;
            text-decoration: none;
            color: white;
            font-weight: 600;
            transition: all 0.3s;
            cursor: pointer;
            font-family: inherit;
            font-size: 16px;
            width: 100%;
            box-sizing: border-box;
            box-shadow: 0 4px 15px rgba(37, 99, 235, 0.2);
        }
        
        .btn-email-login:hover {
            background: linear-gradient(135deg, #1d4ed8 0%, #1e40af 100%);
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(37, 99, 235, 0.3);
        }
        
        .modal-register-link {
            text-align: center;
            font-size: 14px;
            color: #666;
            cursor: pointer;
            transition: color 0.2s;
        }
        
        .modal-register-link:hover {
            color: #2563eb;
            text-decoration: underline;
        }
        
        /* Estilos para los botones sociales */
        .modal-login-content .nsl-container {
            margin-bottom: 0;
        }
        
        .modal-login-content .nsl-button {
            width: 100% !important;
            margin-bottom: 0 !important;
            border-radius: 8px !important;
            font-size: 16px !important;
            padding: 14px 20px !important;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1) !important;
            transition: all 0.3s !important;
        }
        
        .modal-login-content .nsl-button:hover {
            transform: translateY(-2px) !important;
            box-shadow: 0 4px 15px rgba(0,0,0,0.15) !important;
        }
        
        /* Responsive para móvil */
        @media (max-width: 480px) {
            .modal-login-content {
                padding: 50px 20px 25px 20px;
                margin: 20px;
                width: calc(100% - 40px);
            }
            
            .modal-login-content h2,
            .modal-login-content h3 {
                padding-right: 45px;
                font-size: 1.3em;
            }
        }
        </style>
        
        <script>
        document.addEventListener("DOMContentLoaded", function() {
            var headerModal = document.getElementById('header-login-modal');
            var headerCloseBtn = document.getElementById('header-login-modal-close');
            var headerOpenEmailRegister = document.getElementById('header-open-email-register');
            var headerEmailRegisterForm = document.getElementById('header-email-register-form');
            var headerModalLoginButtons = document.getElementById('header-modal-login-buttons');
            var headerBackToLogin = document.getElementById('header-back-to-login');
            
            // Interceptar clics en enlaces de login del header
            var headerLoginLinks = document.querySelectorAll('a[href*="login"], a[href*="wp-login"], .menu-item a[href*="iniciar"]');
            
            headerLoginLinks.forEach(function(link) {
                if (!link.closest('#footer-cuenta-menu')) {
                    link.addEventListener('click', function(e) {
                        e.preventDefault();
                        headerModal.style.display = 'flex';
                        document.body.style.overflow = 'hidden';
                    });
                }
            });
            
            // Función para mostrar opciones de login (Google + Email)
            window.mostrarOpcionesLoginHeader = function() {
                var modalContent = document.querySelector('#header-login-modal .modal-login-content');
                if (modalContent) {
                    modalContent.innerHTML = `
                        <button id="header-login-modal-close-new" class="modal-close" aria-label="Cerrar">&times;</button>
                        <h2>Elige cómo iniciar sesión</h2>
                        <div class="modal-login-buttons">
                            <?php echo do_shortcode('[nextend_social_login provider="google" label="Continuar con Google"]'); ?>
                            <button class="btn-email-login" onclick="window.location.href='<?php echo esc_url($um_login_url); ?>'">📧 Continuar con email</button>
                            <span class="modal-register-link" onclick="mostrarRegistroHeader()">¿No tienes cuenta? Regístrate</span>
                        </div>
                    `;
                    
                    var newCloseBtn = document.getElementById('header-login-modal-close-new');
                    if (newCloseBtn) {
                        newCloseBtn.addEventListener('click', closeHeaderModal);
                    }
                }
            };

            // Función para mostrar registro
            window.mostrarRegistroHeader = function() {
                var modalContent = document.querySelector('#header-login-modal .modal-login-content');
                if (modalContent) {
                    modalContent.innerHTML = `
                        <button id="header-login-modal-close-reg" class="modal-close" aria-label="Cerrar">&times;</button>
                        <h3>Registro por email</h3>
                        <?php echo do_shortcode('[ultimatemember form_id="' . esc_attr($um_register_form_id) . '"]'); ?>
                        <a href="#" onclick="volverALoginHeader()" style="display:block;margin-top:10px; color:#2563eb; text-decoration:underline;">Volver</a>
                    `;
                    
                    var newCloseBtn = document.getElementById('header-login-modal-close-reg');
                    if (newCloseBtn) {
                        newCloseBtn.addEventListener('click', closeHeaderModal);
                    }
                }
            };

            // Función para volver al login inicial
            window.volverALoginHeader = function() {
                location.reload();
            };
            
            // Mostrar registro desde el enlace inicial
            if(headerOpenEmailRegister && headerEmailRegisterForm && headerModalLoginButtons) {
                headerOpenEmailRegister.addEventListener('click', function(e) {
                    e.preventDefault();
                    headerModalLoginButtons.style.display = 'none';
                    headerEmailRegisterForm.style.display = 'block';
                });
            }

            if(headerBackToLogin && headerEmailRegisterForm && headerModalLoginButtons) {
                headerBackToLogin.addEventListener('click', function(e) {
                    e.preventDefault();
                    headerModalLoginButtons.style.display = 'block';
                    headerEmailRegisterForm.style.display = 'none';
                });
            }
            
            // Cerrar modal
            function closeHeaderModal() {
                headerModal.style.display = 'none';
                document.body.style.overflow = '';
            }
            
            if(headerCloseBtn) {
                headerCloseBtn.addEventListener('click', closeHeaderModal);
            }
            
            // Cerrar al hacer clic fuera
            headerModal.addEventListener('click', function(e) {
                if (e.target === headerModal) {
                    closeHeaderModal();
                }
            });
            
            // Cerrar con tecla Escape
            document.addEventListener('keydown', function(e) {
                if (e.key === 'Escape' && headerModal.style.display === 'flex') {
                    closeHeaderModal();
                }
            });
        });
        </script>
        <?php
    }
});

// === INTERCEPTAR BOTÓN LOGIN DEL HEADER PARA ABRIR MODAL ===
add_action('wp_footer', function() {
    if (!is_user_logged_in()) {
        ?>
        <script>
        document.addEventListener("DOMContentLoaded", function() {
            // Interceptar clics en enlaces de "Iniciar sesión" del header
            var headerLoginLinks = document.querySelectorAll('a[href*="login"], a[href*="wp-login"], .menu-item a[href*="iniciar"]');
            
            headerLoginLinks.forEach(function(link) {
                // Solo interceptar si no es el del footer
                if (!link.closest('#footer-cuenta-menu')) {
                    link.addEventListener('click', function(e) {
                        e.preventDefault();
                        
                        // Simular clic en el botón cuenta del footer para abrir el modal
                        var cuentaBtn = document.getElementById('footer-cuenta-btn');
                        var cuentaMenu = document.getElementById('footer-cuenta-menu');
                        
                        if (cuentaBtn && cuentaMenu) {
                            // Abrir el menú cuenta
                            cuentaMenu.style.display = 'block';
                            document.body.classList.add('cuenta-abierta');
                            
                            // Opcional: hacer scroll hacia el footer para que se vea
                            cuentaBtn.scrollIntoView({ behavior: 'smooth', block: 'center' });
                        }
                    });
                }
            });
        });
        </script>
        <?php
    }
});

// === AJAX PARA OBTENER BOTONES SOCIALES ===
add_action('wp_ajax_get_social_login_buttons', 'get_social_login_buttons_ajax');
add_action('wp_ajax_nopriv_get_social_login_buttons', 'get_social_login_buttons_ajax');

function get_social_login_buttons_ajax() {
    // Generar los botones sociales usando el shortcode
    $social_buttons = do_shortcode('[nextend_social_login]');
    
    // Envolver en un div con estilos
    $output = '<div class="modal-social-buttons" style="text-align: center;">' . $social_buttons . '</div>';
    
    echo $output;
    wp_die();
}

// === ENLACES INTERNOS AUTOMÁTICOS PARA SEO ===
function generar_enlaces_relacionados($provincia_actual = '', $categoria_actual = '') {
    $categorias = [
        'desean-alquilar-vivienda' => 'Alquilar vivienda',
        'desean-comprar-vivienda' => 'Comprar vivienda',
        'desean-alquilar-habitacion' => 'Compartir piso',
        'desean-alquilar-plaza-de-garaje' => 'Alquilar garaje',
        'desean-comprar-plaza-de-garaje' => 'Comprar garaje',
        'desean-compartir-garaje' => 'Compartir garaje'
    ];
    
    $provincias_populares = ['madrid', 'barcelona', 'valencia', 'sevilla', 'malaga', 'bilbao'];
    
    echo '<div class="enlaces-relacionados" style="margin-top:40px;padding:20px;background:#f8f9fa;border-radius:8px;">';
    echo '<h3 style="margin-top:0;">Búsquedas relacionadas</h3>';
    echo '<div style="display:flex;flex-wrap:wrap;gap:10px;">';
    
    // Enlaces a otras categorías en la misma provincia
    if ($provincia_actual) {
        foreach ($categorias as $slug => $nombre) {
            if ($slug !== $categoria_actual) {
                $url = home_url('/' . $slug . '/' . $provincia_actual . '/');
                echo '<a href="' . esc_url($url) . '" style="padding:8px 16px;background:white;border:1px solid #ddd;border-radius:6px;text-decoration:none;color:#15418a;font-size:14px;">' . $nombre . ' en ' . ucwords(str_replace('-', ' ', $provincia_actual)) . '</a>';
            }
        }
    }
    
    // Enlaces a la misma categoría en otras provincias
    if ($categoria_actual) {
        foreach ($provincias_populares as $prov) {
            if ($prov !== $provincia_actual) {
                $url = home_url('/' . $categoria_actual . '/' . $prov . '/');
                $cat_nombre = $categorias[$categoria_actual] ?? ucwords(str_replace('-', ' ', $categoria_actual));
                echo '<a href="' . esc_url($url) . '" style="padding:8px 16px;background:white;border:1px solid #ddd;border-radius:6px;text-decoration:none;color:#15418a;font-size:14px;">' . $cat_nombre . ' en ' . ucwords($prov) . '</a>';
            }
        }
    }
    
    echo '</div>';
    echo '</div>';
}

// === JS PARA MENÚ CUENTA Y SCROLL ===
add_action('wp_footer', function() { ?>
<script>
document.addEventListener("DOMContentLoaded", function() {
  var cuentaBtn = document.getElementById('footer-cuenta-btn');
  var cuentaMenu = document.getElementById('footer-cuenta-menu');
  var scrollTopBtn = document.getElementById('ast-scroll-top');

  function toggleScrollTopButton() {
    if(document.body.classList.contains('cuenta-abierta')) {
      if(scrollTopBtn) scrollTopBtn.style.display = 'none';
    } else {
      if(scrollTopBtn) scrollTopBtn.style.display = '';
    }
  }

  if (cuentaBtn && cuentaMenu) {
    cuentaBtn.addEventListener('click', function(e) {
      e.stopPropagation();
      var isOpen = cuentaMenu.style.display === 'block';
      if (!isOpen) {
        cuentaMenu.style.display = 'block';
        document.body.classList.add('cuenta-abierta');
      } else {
        cuentaMenu.style.display = 'none';
        document.body.classList.remove('cuenta-abierta');
      }
      toggleScrollTopButton();
    });

    document.addEventListener('click', function(e) {
      if (!cuentaBtn.contains(e.target) && !cuentaMenu.contains(e.target)) {
        cuentaMenu.style.display = 'none';
        document.body.classList.remove('cuenta-abierta');
        toggleScrollTopButton();
      }
    });
  }

  window.addEventListener('scroll', toggleScrollTopButton);
});
</script>
<?php });


// === INCLUIR FAQ SCHEMA PARA LA HOME ===
require_once get_stylesheet_directory() . '/faq-schema.php';

// === INCLUIR COMPARTIR SOCIAL ===
require_once get_stylesheet_directory() . '/compartir-social.php';

// === CARGAR MODAL PROVINCIAS MEJORADO DESDE EL TEMA ===
add_action('wp_enqueue_scripts', function() {
    // Desencolar el modal antiguo del plugin si existe
    wp_dequeue_script('modal-provincias-js');
    
    // COMENTADO: archivo no existe, causaba 404
    // Cargar el nuevo desde el tema hijo
    /*
    wp_enqueue_script(
        'modal-provincias-nuevo',
        get_stylesheet_directory_uri() . '/js/modal-provincias-nuevo.js',
        [],
        '1.0',
        true
    );
    */
}, 100);

// === GOOGLE ADS - TRACKING DE REGISTRO COMPLETADO ===
// Hook que se ejecuta cuando Ultimate Member completa un registro
add_action('um_registration_complete', function($user_id, $args) {
    // Guardar en sesión que se completó un registro
    if (!session_id()) {
        session_start();
    }
    $_SESSION['um_registration_completed'] = true;
    $_SESSION['um_registered_user_id'] = $user_id;
}, 10, 2);

// Agregar script para detectar registro completado
add_action('wp_footer', function() {
    if (!session_id()) {
        session_start();
    }
    
    // Verificar si se completó un registro en esta sesión
    if (isset($_SESSION['um_registration_completed']) && $_SESSION['um_registration_completed'] === true) {
        $user_id = isset($_SESSION['um_registered_user_id']) ? $_SESSION['um_registered_user_id'] : 0;
        $user = get_userdata($user_id);
        $username = $user ? $user->user_login : 'Usuario';
        ?>
        <script>
        // Mostrar modal de éxito
        (function() {
            console.log("🎉 Registro completado detectado - Usuario ID: <?php echo $user_id; ?>");
            
            // Crear modal de éxito
            const modal = document.createElement('div');
            modal.id = 'modal-registro-exito';
            modal.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: rgba(0, 0, 0, 0.5);
                display: flex;
                align-items: center;
                justify-content: center;
                z-index: 10000;
            `;
            
            modal.innerHTML = `
                <div style="
                    background: white;
                    border-radius: 16px;
                    padding: 40px 30px;
                    max-width: 450px;
                    width: 90%;
                    box-shadow: 0 15px 50px rgba(0, 0, 0, 0.3);
                    text-align: center;
                    animation: slideUp 0.4s ease-out;
                ">
                    <div style="font-size: 60px; margin-bottom: 20px;">✅</div>
                    <h2 style="color: #15418a; margin: 0 0 10px 0; font-size: 1.5em; font-weight: bold;">¡Registro completado!</h2>
                    <p style="color: #666; margin: 0 0 10px 0; font-size: 1.05em;">Bienvenid@, <strong><?php echo esc_html($username); ?></strong></p>
                    <p style="color: #888; margin: 0 0 30px 0; font-size: 0.95em;">Tu cuenta ha sido creada exitosamente. Ya puedes publicar tus anuncios.</p>
                    <button id="modal-registro-cerrar" style="
                        background: linear-gradient(135deg, #3ba1da 0%, #15418a 100%);
                        color: white;
                        border: none;
                        padding: 14px 40px;
                        border-radius: 8px;
                        font-size: 1.05em;
                        font-weight: bold;
                        cursor: pointer;
                        transition: transform 0.2s, box-shadow 0.2s;
                        box-shadow: 0 4px 15px rgba(21, 65, 138, 0.3);
                    ">Continuar</button>
                </div>
                <style>
                    @keyframes slideUp {
                        from {
                            opacity: 0;
                            transform: translateY(30px);
                        }
                        to {
                            opacity: 1;
                            transform: translateY(0);
                        }
                    }
                </style>
            `;
            
            document.body.appendChild(modal);
            
            // Cerrar modal
            document.getElementById('modal-registro-cerrar').addEventListener('click', function() {
                modal.style.display = 'none';
                // Recargar página para mostrar usuario logueado
                setTimeout(() => {
                    window.location.reload();
                }, 300);
            });
            
            // Disparar evento de Google Analytics
            if (typeof gtag !== 'undefined') {
                gtag('event', 'registro_completado', {
                    'event_category': 'registro',
                    'event_label': 'Ultimate Member - Exitoso',
                    'user_id': '<?php echo $user_id; ?>'
                });
                console.log("✅ Evento GA4 enviado");
            }
        })();
        </script>
        <?php
        // Limpiar la sesión para no disparar el evento múltiples veces
        unset($_SESSION['um_registration_completed']);
        unset($_SESSION['um_registered_user_id']);
    }
}, 999);

// ========================================
// FUNCIÓN DE PRUEBA - EMAIL DE NOTIFICACIONES
// ========================================
add_action('wp_ajax_zm_test_email_preview', function() {
    if (!current_user_can('manage_options')) {
        echo '<h2>❌ Sin permisos</h2><p>Debes ser administrador.</p>';
        wp_die();
    }
    
    $user = wp_get_current_user();
    $unread_count = 3;
    
    $conversations_html = '
        <li style="margin-bottom:15px;padding-bottom:15px;border-bottom:1px solid #eee;">
            <strong>2 mensajes nuevos</strong><br>
            <span style="color:#666;font-size:14px;">Hola, me interesa tu anuncio de piso en alquiler en Madrid. ¿Podríamos hablar?...</span>
        </li>
        <li style="margin-bottom:15px;padding-bottom:15px;border-bottom:1px solid #eee;">
            <strong>1 mensaje nuevo</strong><br>
            <span style="color:#666;font-size:14px;">Buenos días, ¿sigue disponible la habitación que publicaste?...</span>
        </li>';
    
    $messages_url = site_url('/mensajes-privados/');
    $settings_url = site_url('/mi-cuenta/');
    
    $message = '
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="margin:0;padding:0;font-family:Arial,sans-serif;background-color:#f5f5f5;">
        <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f5f5f5;padding:20px;">
            <tr>
                <td align="center">
                    <table width="600" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:10px;overflow:hidden;box-shadow:0 2px 10px rgba(0,0,0,0.1);">
                        <tr>
                            <td style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);padding:30px;text-align:center;">
                                <h1 style="color:#ffffff;margin:0;font-size:24px;">📬 Mensajes sin leer</h1>
                            </td>
                        </tr>
                        <tr>
                            <td style="padding:30px;">
                                <p style="font-size:16px;color:#333;margin:0 0 20px;">Hola <strong>' . esc_html($user->display_name) . '</strong>,</p>
                                <p style="font-size:16px;color:#333;margin:0 0 20px;">
                                    Tienes <strong>' . $unread_count . ' mensajes sin leer</strong> en Zoomubik:
                                </p>
                                <ul style="list-style:none;padding:0;margin:0 0 30px;">
                                    ' . $conversations_html . '
                                </ul>
                                <div style="text-align:center;margin:30px 0;">
                                    <a href="' . esc_url($messages_url) . '" style="display:inline-block;background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);color:#ffffff;text-decoration:none;padding:15px 40px;border-radius:25px;font-size:16px;font-weight:bold;">
                                        Ver mis mensajes
                                    </a>
                                </div>
                            </td>
                        </tr>
                        <tr>
                            <td style="background-color:#f8f9fa;padding:20px;text-align:center;border-top:1px solid #eee;">
                                <p style="font-size:12px;color:#666;margin:0 0 10px;">
                                    Recibes este email porque tienes mensajes sin leer en Zoomubik.
                                </p>
                                <p style="font-size:12px;color:#666;margin:0;">
                                    <a href="' . esc_url($settings_url) . '" style="color:#667eea;text-decoration:none;">Desactivar notificaciones por email</a>
                                </p>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
        </table>
    </body>
    </html>';
    
    $headers = array(
        'Content-Type: text/html; charset=UTF-8',
        'From: Zoomubik <noreply@zoomubik.com>'
    );
    
    $subject = '📬 Tienes ' . $unread_count . ' mensajes sin leer en Zoomubik';
    
    echo '<div style="max-width:900px;margin:20px auto;padding:20px;background:#fff;border-radius:10px;box-shadow:0 2px 10px rgba(0,0,0,0.1);">';
    echo '<h2>🧪 Vista Previa - Email de Notificaciones</h2>';
    echo '<p><strong>Para:</strong> ' . esc_html($user->user_email) . '</p>';
    echo '<p><strong>Asunto:</strong> ' . esc_html($subject) . '</p>';
    
    $result = wp_mail($user->user_email, $subject, $message, $headers);
    
    if ($result) {
        echo '<div style="background:#d4edda;color:#155724;padding:15px;border-radius:5px;margin:20px 0;">';
        echo '<strong>✅ Email enviado correctamente</strong><br>';
        echo 'Revisa tu bandeja de entrada: ' . esc_html($user->user_email);
        echo '</div>';
    } else {
        echo '<div style="background:#f8d7da;color:#721c24;padding:15px;border-radius:5px;margin:20px 0;">';
        echo '<strong>❌ Error al enviar</strong><br>';
        echo 'Verifica la configuración de correo de WordPress.';
        echo '</div>';
    }
    
    echo '<hr style="margin:30px 0;">';
    echo '<h3>Vista previa del email:</h3>';
    echo '<div style="border:2px solid #ddd;padding:20px;background:#f9f9f9;">';
    echo $message;
    echo '</div>';
    echo '</div>';
    
    wp_die();
});


// === REDIRECT DE URLS: desean-compartir-piso a desean-alquilar-habitacion ===
add_action('template_redirect', function() {
    // Obtener la URL actual
    $request_uri = $_SERVER['REQUEST_URI'];
    
    // Si la URL contiene "desean-compartir-piso", redirigir a "desean-alquilar-habitacion"
    if (strpos($request_uri, '/desean-compartir-piso/') !== false) {
        // Reemplazar la URL
        $new_url = str_replace('/desean-compartir-piso/', '/desean-alquilar-habitacion/', $request_uri);
        
        // Hacer el redirect permanente (301)
        wp_redirect(home_url($new_url), 301);
        exit;
    }
});

