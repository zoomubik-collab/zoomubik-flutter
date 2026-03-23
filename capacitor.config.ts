import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.zoomubik.app',
  appName: 'Zoomubik',
  webDir: 'www',
  server: {
    // Wrapper puro: carga la web directamente en el WebView principal
    url: 'https://zoomubik.com',

    // Permite navegar dentro de tu dominio (y subdominios)
    allowNavigation: ['zoomubik.com', '*.zoomubik.com']
  }
};

export default config;
