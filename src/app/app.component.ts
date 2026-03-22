import { Component, OnInit, inject } from '@angular/core';
import { IonApp } from '@ionic/angular/standalone';
import { Platform } from '@ionic/angular';
import { NativeService } from './services/native.service';

@Component({
  selector: 'app-root',
  templateUrl: 'app.component.html',
  styleUrls: ['app.component.scss'],
  imports: [IonApp],
})
export class AppComponent implements OnInit {
  private platform = inject(Platform);

  // Se inyecta para inicializar features nativas (luego aquí pondremos Push remotas)
  private nativeService = inject(NativeService);

  async ngOnInit(): Promise<void> {
    await this.platform.ready();
    // No abrir InAppBrowser: Capacitor cargará https://zoomubik.com vía server.url
  }
}
