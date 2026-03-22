import { Injectable, inject } from '@angular/core';
import { Share } from '@capacitor/share';
import { Camera, CameraResultType, CameraSource } from '@capacitor/camera';
import { LocalNotifications } from '@capacitor/local-notifications';
import { PushNotifications } from '@capacitor/push-notifications';
import { Platform } from '@ionic/angular';

@Injectable({
  providedIn: 'root'
})
export class NativeService {
  private platform = inject(Platform);

  constructor() {
    this.initializeNotifications();
    this.initializePushNotifications();
  }

  async shareContent(title: string, text: string, url?: string) {
    try {
      await Share.share({
        title: title,
        text: text,
        url: url,
        dialogTitle: 'Compartir'
      });
    } catch (error) {
      console.error('Error compartiendo:', error);
    }
  }

  async takePicture(): Promise<string | null> {
    try {
      const image = await Camera.getPhoto({
        quality: 90,
        allowEditing: true,
        resultType: CameraResultType.DataUrl,
        source: CameraSource.Camera
      });
      return image.dataUrl || null;
    } catch (error) {
      console.error('Error tomando foto:', error);
      return null;
    }
  }

  async pickPhoto(): Promise<string | null> {
    try {
      const image = await Camera.getPhoto({
        quality: 90,
        allowEditing: true,
        resultType: CameraResultType.DataUrl,
        source: CameraSource.Photos
      });
      return image.dataUrl || null;
    } catch (error) {
      console.error('Error seleccionando foto:', error);
      return null;
    }
  }

  private async initializeNotifications() {
    if (this.platform.is('ios') || this.platform.is('android')) {
      try {
        const permission = await LocalNotifications.requestPermissions();
        if (permission.display === 'granted') {
          console.log('Permisos de notificaciones otorgados');
        }
      } catch (error) {
        console.error('Error solicitando permisos de notificaciones:', error);
      }
    }
  }

  // --- Push notifications reales (FCM/APNs) ---
  private async initializePushNotifications() {
    if (this.platform.is('ios') || this.platform.is('android')) {
      try {
        // Solicitar permisos push
        const permStatus = await PushNotifications.requestPermissions();
        if (permStatus.receive !== 'granted') {
          console.warn('Permiso de push denegado');
          return;
        }

        // Registrar para recibir token
        await PushNotifications.register();

        // Escuchar evento de registro para obtener token
        PushNotifications.addListener('registration', async (token) => {
          console.log('Push registration token:', token.value);

          // Enviar token al backend (WordPress)
          try {
            const resp = await fetch('https://zoomubik.com/wp-json/zoomubik/v1/push/register', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ token: token.value })
            });
            const data = await resp.json();
            if (data.ok) {
              console.log('Token FCM registrado correctamente en WP');
            } else {
              console.error('Error guardando token FCM:', data.error || data);
            }
          } catch (err) {
            console.error('Error enviando token FCM:', err);
          }
        });

        // Escuchar errores en el registro
        PushNotifications.addListener('registrationError', (error) => {
          console.error('Error en registro de push:', error);
        });

        // Opcional: gestionar recepción de notificaciones mientras la app está abierta
        PushNotifications.addListener('pushNotificationReceived', (notification) => {
          console.log('Push recibido: ', notification);
          // Aquí puedes mostrar una LocalNotification, toast, etc.
        });

      } catch (err) {
        console.error('Error inicializando PushNotifications:', err);
      }
    }
  }

  async sendNotification(title: string, body: string, delaySeconds: number = 5) {
    try {
      await LocalNotifications.schedule({
        notifications: [
          {
            title: title,
            body: body,
            id: Math.floor(Math.random() * 10000),
            schedule: { at: new Date(Date.now() + delaySeconds * 1000) },
            smallIcon: 'ic_stat_icon_config_sample',
            iconColor: '#488AFF'
          }
        ]
      });
    } catch (error) {
      console.error('Error enviando notificación:', error);
    }
  }

  async cancelAllNotifications() {
    try {
      await LocalNotifications.cancel({ notifications: [] });
    } catch (error) {
      console.error('Error cancelando notificaciones:', error);
    }
  }
}
