/**
 * Zoomubik Geolocation - Sin contador
 * Version: 1.0.2
 */

console.log('[Zoomubik] Script cargado');

class ZoomubikGeolocation {
    constructor() {
        this.config = window.zoomubik_geo_config || {
            debug: false,
            timeout: 10000,
            enabled: true,
            enable_global: false
        };
        this.hasRedirected = false;
    }

    async init() {
        if (!this.config.enabled) {
            console.log('[Zoomubik] Geolocation disabled');
            return;
        }
        
        if (!this.config.enable_global && window.location.pathname !== '/' && !window.location.pathname.includes('index')) {
            console.log('[Zoomubik] Not on home page');
            return;
        }

        // Verificar si ya se ha rechazado previamente
        const noRedirect = localStorage.getItem('zoomubik_geo_no_redirect');
        if (noRedirect === 'true') {
            console.log('[Zoomubik] User previously rejected geolocation');
            return;
        }

        // Verificar si ya se ha comprobado en esta sesión
        const alreadyChecked = sessionStorage.getItem('zoomubik_geo_checked');
        if (alreadyChecked) {
            console.log('[Zoomubik] Already checked in this session');
            return;
        }

        console.log('[Zoomubik] Starting geolocation...');
        await this.delay(2000); // Esperar 2 segundos en lugar de 5
        this.startGeolocation();
    }

    async startGeolocation() {
        try {
            console.log('[Zoomubik] Requesting GPS position...');
            const position = await this.getCurrentPosition();
            console.log('[Zoomubik] GPS position obtained:', position);
            
            const province = await this.getProvinceFromCoordinates(position.coords.latitude, position.coords.longitude);
            console.log('[Zoomubik] Province detected:', province);
            
            if (province) {
                console.log('[Zoomubik] Showing banner for province:', province);
                this.showBanner(province);
            } else {
                console.log('[Zoomubik] No province detected from GPS, trying IP fallback');
                this.fallbackToIP();
            }
        } catch (error) {
            console.log('[Zoomubik] Error GPS:', error.message, 'Code:', error.code);
            // Si el usuario rechaza el GPS, NO hacer fallback a IP
            if (error.code !== 1) { // 1 = PERMISSION_DENIED
                console.log('[Zoomubik] Not a permission error, trying IP fallback');
                this.fallbackToIP();
            } else {
                // Usuario rechazó el permiso, guardar preferencia
                console.log('[Zoomubik] User denied permission');
                localStorage.setItem('zoomubik_geo_no_redirect', 'true');
            }
        }
        
        sessionStorage.setItem('zoomubik_geo_checked', 'true');
    }

    getCurrentPosition() {
        return new Promise((resolve, reject) => {
            if (!navigator.geolocation) {
                reject(new Error('Geolocation not supported'));
                return;
            }

            navigator.geolocation.getCurrentPosition(
                resolve,
                (error) => {
                    // Crear un error con el código de geolocalización
                    const geoError = new Error(error.message);
                    geoError.code = error.code; // 1 = PERMISSION_DENIED, 2 = POSITION_UNAVAILABLE, 3 = TIMEOUT
                    reject(geoError);
                },
                { timeout: this.config.timeout, enableHighAccuracy: false, maximumAge: 0 }
            );
        });
    }

    async getProvinceFromCoordinates(lat, lng) {
        try {
            const response = await fetch(`https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${lat}&longitude=${lng}&localityLanguage=es`);
            const data = await response.json();
            
            if (!data.countryName || (!data.countryName.toLowerCase().includes('spain') && !data.countryName.toLowerCase().includes('espana'))) {
                return null;
            }

            const locations = [
                data.city?.toLowerCase(),
                data.locality?.toLowerCase(),
                data.principalSubdivision?.toLowerCase()
            ].filter(Boolean);

            return this.findProvince(locations);
        } catch (error) {
            console.log('[Zoomubik] Error getting province:', error);
            return null;
        }
    }

    async fallbackToIP() {
        try {
            const response = await fetch('https://ipapi.co/json/');
            const data = await response.json();
            
            if (data.country_code !== 'ES') return;

            const locations = [
                data.city?.toLowerCase(),
                data.region?.toLowerCase()
            ].filter(Boolean);

            const province = this.findProvince(locations);
            if (province) {
                this.showBanner(province);
            }
        } catch (error) {
            console.log('[Zoomubik] Error IP fallback:', error);
        }
    }

    findProvince(locations) {
        const provinces = {
            'madrid': 'madrid',
            'barcelona': 'barcelona',
            'valencia': 'valencia',
            'sevilla': 'sevilla',
            'zaragoza': 'zaragoza',
            'malaga': 'malaga',
            'murcia': 'murcia',
            'palma': 'palma',
            'las palmas': 'las-palmas',
            'bilbao': 'bilbao',
            'alicante': 'alicante',
            'cordoba': 'cordoba',
            'valladolid': 'valladolid',
            'vigo': 'vigo',
            'gijon': 'gijon',
            'granada': 'granada',
            'vitoria': 'vitoria',
            'oviedo': 'oviedo',
            'santander': 'santander',
            'pamplona': 'pamplona',
            'almeria': 'almeria',
            'burgos': 'burgos',
            'salamanca': 'salamanca',
            'huelva': 'huelva',
            'logrono': 'logrono',
            'badajoz': 'badajoz',
            'leon': 'leon',
            'cadiz': 'cadiz'
        };

        for (const location of locations) {
            if (!location) continue;
            if (provinces[location]) return provinces[location];
            
            for (const [key, value] of Object.entries(provinces)) {
                if (location.includes(key) || key.includes(location)) {
                    return value;
                }
            }
        }
        return null;
    }

    showBanner(province) {
        if (this.hasRedirected) return;
        this.hasRedirected = true;

        const existingBanner = document.getElementById('zoomubik-banner');
        if (existingBanner) existingBanner.remove();

        const banner = document.createElement('div');
        banner.id = 'zoomubik-banner';
        banner.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            background: linear-gradient(135deg, #007cba 0%, #005a8b 100%);
            color: white;
            padding: 15px 20px;
            z-index: 999998;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            transform: translateY(-100%);
            transition: transform 0.4s ease;
        `;

        const provinceName = province.replace('-', ' ').toUpperCase();
        
        const html = `
            <div style="display: flex; align-items: center; justify-content: space-between; max-width: 1200px; margin: 0 auto; flex-wrap: wrap; gap: 10px;">
                <div style="flex: 1; min-width: 200px;">
                    <div style="font-weight: 600; font-size: 14px;">Detectamos que estás en ${provinceName}</div>
                </div>
                <div style="display: flex; gap: 10px; flex-shrink: 0;">
                    <button id="zoomubik-yes" style="background: rgba(255,255,255,0.2); color: white; border: 1px solid rgba(255,255,255,0.3); padding: 8px 16px; border-radius: 6px; cursor: pointer; font-size: 13px; font-weight: 600; white-space: nowrap;">Sí, ir a ${provinceName}</button>
                    <button id="zoomubik-no" style="background: transparent; color: rgba(255,255,255,0.8); border: 1px solid rgba(255,255,255,0.3); padding: 8px 12px; border-radius: 6px; cursor: pointer; font-size: 13px; white-space: nowrap;">No, gracias</button>
                    <button id="zoomubik-close" style="background: transparent; color: rgba(255,255,255,0.8); border: none; padding: 6px; cursor: pointer; font-size: 18px; line-height: 1;">X</button>
                </div>
            </div>
        `;

        banner.innerHTML = html;
        document.body.appendChild(banner);

        setTimeout(() => {
            banner.style.transform = 'translateY(0)';
        }, 100);

        document.getElementById('zoomubik-yes').addEventListener('click', () => {
            window.location.href = `/provincias/${province}/`;
        });

        document.getElementById('zoomubik-no').addEventListener('click', () => {
            this.closeBanner(banner);
            localStorage.setItem('zoomubik_geo_no_redirect', 'true');
        });

        document.getElementById('zoomubik-close').addEventListener('click', () => {
            this.closeBanner(banner);
        });

        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.closeBanner(banner);
            }
        });
    }

    closeBanner(banner) {
        banner.style.transform = 'translateY(-100%)';
        setTimeout(() => {
            if (document.body.contains(banner)) {
                banner.remove();
            }
        }, 400);
    }

    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

let zoomubikInitialized = false;

function initZoomubik() {
    if (zoomubikInitialized) return;
    zoomubikInitialized = true;
    
    try {
        const geo = new ZoomubikGeolocation();
        geo.init();
    } catch (error) {
        console.error('[Zoomubik] Error:', error);
    }
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initZoomubik);
} else {
    setTimeout(initZoomubik, 100);
}
