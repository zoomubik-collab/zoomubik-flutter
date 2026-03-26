<?php
/**
 * Plugin Name: Zoomubik Sitemap Personalizado
 * Description: Genera sitemap XML personalizado para URLs dinámicas
 * Version: 1.0
 * Author: Zoomubik
 */

if (!defined('ABSPATH')) exit;

// Registrar el endpoint del sitemap
add_action('init', function() {
    add_rewrite_rule('^sitemap-zoomubik\.xml$', 'index.php?zoomubik_sitemap=1', 'top');
    add_rewrite_tag('%zoomubik_sitemap%', '([^&]+)');
}, 10);

// Generar el sitemap - ejecutar antes de que WordPress renderice
add_action('template_redirect', function() {
    if (!get_query_var('zoomubik_sitemap')) {
        return;
    }
    
    // Headers XML
    header('Content-Type: application/xml; charset=UTF-8', true);
    header('Cache-Control: public, max-age=3600', true);
    
    echo zoomubik_generate_sitemap();
    exit;
}, 1);

function zoomubik_generate_sitemap() {
    global $wpdb;
    
    $lastmod = date('Y-m-d');
    $tabla = "jbgl_marcadores";
    
    // Categorías
    $categorias = [
        'desean-alquilar-habitacion',
        'desean-alquilar-vivienda',
        'desean-comprar-vivienda',
        'desean-alquilar-plaza-de-garaje',
        'desean-comprar-plaza-de-garaje',
        'desean-compartir-garaje'
    ];
    
    // Provincias
    $provincias = [
        'almeria', 'cadiz', 'cordoba', 'granada', 'huelva', 'jaen', 'malaga', 'sevilla',
        'huesca', 'teruel', 'zaragoza', 'asturias',
        'mallorca', 'menorca', 'ibiza', 'formentera',
        'barcelona', 'girona', 'lleida', 'tarragona',
        'burgos', 'leon', 'palencia', 'salamanca', 'segovia', 'soria', 'valladolid', 'zamora', 'avila',
        'cuenca', 'guadalajara', 'toledo', 'albacete', 'ciudad-real',
        'alicante', 'castellon', 'valencia',
        'caceres', 'badajoz',
        'pontevedra', 'ourense', 'lugo', 'a-coruna',
        'las-palmas', 'santa-cruz-de-tenerife',
        'cantabria', 'la-rioja', 'madrid', 'murcia', 'navarra',
        'guipuzcoa', 'vizcaya', 'alava',
        'ceuta', 'melilla'
    ];
    
    $xml = '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
    $xml .= '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' . "\n";
    
    // Página principal
    $xml .= "  <url>\n";
    $xml .= "    <loc>" . esc_url(home_url('/')) . "</loc>\n";
    $xml .= "    <lastmod>$lastmod</lastmod>\n";
    $xml .= "    <changefreq>daily</changefreq>\n";
    $xml .= "    <priority>1.0</priority>\n";
    $xml .= "  </url>\n";
    
    // Páginas estáticas
    $static_pages = [
        '/como-funciona-zoomubik/' => 0.9,
        '/blog/' => 0.8
    ];
    
    foreach ($static_pages as $page => $priority) {
        $xml .= "  <url>\n";
        $xml .= "    <loc>" . esc_url(home_url($page)) . "</loc>\n";
        $xml .= "    <lastmod>$lastmod</lastmod>\n";
        $xml .= "    <changefreq>monthly</changefreq>\n";
        $xml .= "    <priority>$priority</priority>\n";
        $xml .= "  </url>\n";
    }
    
    // Categorías principales
    foreach ($categorias as $categoria) {
        $xml .= "  <url>\n";
        $xml .= "    <loc>" . esc_url(home_url('/' . $categoria . '/')) . "</loc>\n";
        $xml .= "    <lastmod>$lastmod</lastmod>\n";
        $xml .= "    <changefreq>weekly</changefreq>\n";
        $xml .= "    <priority>0.8</priority>\n";
        $xml .= "  </url>\n";
    }
    
    // Categorías + provincia
    foreach ($categorias as $categoria) {
        foreach ($provincias as $provincia) {
            $xml .= "  <url>\n";
            $xml .= "    <loc>" . esc_url(home_url('/' . $categoria . '/' . $provincia . '/')) . "</loc>\n";
            $xml .= "    <lastmod>$lastmod</lastmod>\n";
            $xml .= "    <changefreq>weekly</changefreq>\n";
            $xml .= "    <priority>0.7</priority>\n";
            $xml .= "  </url>\n";
        }
    }
    
    // Anuncios por provincia
    foreach ($provincias as $provincia) {
        $xml .= "  <url>\n";
        $xml .= "    <loc>" . esc_url(home_url('/anuncios-provincia/' . $provincia . '/')) . "</loc>\n";
        $xml .= "    <lastmod>$lastmod</lastmod>\n";
        $xml .= "    <changefreq>weekly</changefreq>\n";
        $xml .= "    <priority>0.7</priority>\n";
        $xml .= "  </url>\n";
    }
    
    // Anuncios individuales
    $anuncios = $wpdb->get_results("
        SELECT categoria_slug, provincia_slug, titulo_slug, fecha
        FROM $tabla 
        WHERE categoria_slug IS NOT NULL 
        AND provincia_slug IS NOT NULL 
        AND titulo_slug IS NOT NULL
        ORDER BY fecha DESC
        LIMIT 10000
    ");
    
    if (!empty($anuncios)) {
        foreach ($anuncios as $anuncio) {
            $url = home_url('/' . $anuncio->categoria_slug . '/' . $anuncio->provincia_slug . '/' . $anuncio->titulo_slug . '/');
            $fecha = !empty($anuncio->fecha) ? date('Y-m-d', strtotime($anuncio->fecha)) : $lastmod;
            
            $xml .= "  <url>\n";
            $xml .= "    <loc>" . esc_url($url) . "</loc>\n";
            $xml .= "    <lastmod>$fecha</lastmod>\n";
            $xml .= "    <changefreq>weekly</changefreq>\n";
            $xml .= "    <priority>0.6</priority>\n";
            $xml .= "  </url>\n";
        }
    }
    
    // URLs dinámicas SEO (palabra + provincia)
    $keywords_table = $wpdb->prefix . 'seo_keywords';
    $keywords_exists = $wpdb->get_var("SHOW TABLES LIKE '$keywords_table'") == $keywords_table;
    
    if ($keywords_exists) {
        $allowed_keywords = $wpdb->get_col("SELECT keyword FROM $keywords_table WHERE enabled = 1");
        
        if (!empty($allowed_keywords)) {
            foreach ($allowed_keywords as $keyword) {
                // Solo generar URLs para provincias que tengan anuncios con esta palabra clave
                $seo_provincias = $wpdb->get_col($wpdb->prepare(
                    "SELECT DISTINCT provincia FROM $tabla 
                    WHERE (titulo LIKE %s OR comentario LIKE %s) 
                    AND provincia IS NOT NULL 
                    AND provincia != ''",
                    '%' . $keyword . '%',
                    '%' . $keyword . '%'
                ));
                
                foreach ($seo_provincias as $provincia) {
                    $palabra_slug = sanitize_title($keyword);
                    $provincia_slug = sanitize_title($provincia);
                    $url = home_url('/anuncios/' . $palabra_slug . '/' . $provincia_slug . '/');
                    
                    $xml .= "  <url>\n";
                    $xml .= "    <loc>" . esc_url($url) . "</loc>\n";
                    $xml .= "    <lastmod>$lastmod</lastmod>\n";
                    $xml .= "    <changefreq>weekly</changefreq>\n";
                    $xml .= "    <priority>0.7</priority>\n";
                    $xml .= "  </url>\n";
                }
            }
        }
    }
    
    $xml .= '</urlset>';
    
    return $xml;
}

// Agregar el sitemap al índice de Yoast
add_filter('wpseo_sitemap_index', function($sitemap_index) {
    $sitemap_index .= '  <sitemap>' . "\n";
    $sitemap_index .= '    <loc>' . home_url('/sitemap-zoomubik.xml') . '</loc>' . "\n";
    $sitemap_index .= '  </sitemap>' . "\n";
    return $sitemap_index;
});
