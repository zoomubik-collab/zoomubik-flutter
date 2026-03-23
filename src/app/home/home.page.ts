import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IonHeader, IonToolbar, IonTitle, IonContent, IonButton, IonCard, IonCardContent, IonSpinner, IonCardHeader, IonCardTitle, IonItem, IonLabel, IonIcon, IonChip } from '@ionic/angular/standalone';
import { addIcons } from 'ionicons';
import { camera, image, shareSocial } from 'ionicons/icons';
import { NativeService } from '../services/native.service';

addIcons({ camera, image, shareSocial });

@Component({
  selector: 'app-home',
  templateUrl: 'home.page.html',
  styleUrls: ['home.page.scss'],
  imports: [CommonModule, IonHeader, IonToolbar, IonTitle, IonContent, IonButton, IonCard, IonCardContent, IonSpinner, IonCardHeader, IonCardTitle, IonItem, IonLabel, IonIcon, IonChip],
  providers: [NativeService]
})
export class HomePage {
  selectedPhoto: string | null = null;
  loading = false;

  private nativeService = inject(NativeService);

  async shareAnnouncement() {
    this.loading = true;
    await this.nativeService.shareContent(
      'Mi Anuncio',
      'Descripción del anuncio',
      'https://zoomubik.com'
    );
    this.loading = false;
  }

  async capturePhoto() {
    this.loading = true;
    const photo = await this.nativeService.takePicture();
    if (photo) {
      this.selectedPhoto = photo;
    }
    this.loading = false;
  }

  async selectPhotoFromGallery() {
    this.loading = true;
    const photo = await this.nativeService.pickPhoto();
    if (photo) {
      this.selectedPhoto = photo;
    }
    this.loading = false;
  }
}
