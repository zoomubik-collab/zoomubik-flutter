import { Component, OnInit } from '@angular/core';
import { IonApp } from '@ionic/angular/standalone';
import { Platform } from '@ionic/angular';
import { NativeService } from './services/native.service';
import { PushNotifications } from '@capacitor/push-notifications';

@Component({
  selector: 'app-root',
  templateUrl: 'app.component.html',
  styleUrls: ['app.component.scss'],
  imports: [IonApp],
})
export class AppComponent implements OnInit {
  constructor(
    private platform: Platform,
    private nativeService: NativeService
  ) {}

  async ngOnInit(): Promise<void> {
    await this.platform.ready();
    // No abrir InAppBrowser: Capacitor cargará https://zoomubik.com vía server.url

    // Solicita permisos de notificaciones push al arrancar
    PushNotifications.requestPermissions().then(result => {
      if (result.receive === 'granted') {
        PushNotifications.register();
        console.log('Permiso concedido, registrado push');
      } else {
        console.log('Permiso NO concedido');
      }
    });

    PushNotifications.addListener('registration',
      (token) => { console.log('Push token:', token); }
    );
    PushNotifications.addListener('registrationError',
      (error) => { console.error('Push registration error:', error); }
    );
    PushNotifications.addListener('pushNotificationReceived',
      (notification) => { console.log('Notificación recibida:', notification); }
    );
  }
}
