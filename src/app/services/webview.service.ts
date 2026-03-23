import { Injectable, inject } from '@angular/core';
import { Platform } from '@ionic/angular';
import { InAppBrowser, iOSViewStyle, iOSAnimation, ToolbarPosition } from '@capacitor/inappbrowser';

@Injectable({
  providedIn: 'root'
})
export class WebViewService {
  private readonly ZOOMUBIK_URL = 'https://zoomubik.com';
  private platform = inject(Platform);

  async openWebView(): Promise<void> {
    if (!this.platform.is('capacitor')) {
      return;
    }

    await InAppBrowser.openInWebView({
      url: this.ZOOMUBIK_URL,
      options: {
        showURL: false,
        showToolbar: false,
        clearCache: false,
        clearSessionCache: false,
        mediaPlaybackRequiresUserAction: false,
        closeButtonText: 'Cerrar',
        toolbarPosition: ToolbarPosition.TOP,
        showNavigationButtons: false,
        leftToRight: false,
        iOS: {
          viewStyle: iOSViewStyle.FULL_SCREEN,
          animationEffect: iOSAnimation.COVER_VERTICAL,
          allowOverScroll: true,
          enableViewportScale: true,
          allowInLineMediaPlayback: true,
          surpressIncrementalRendering: false,
          allowsBackForwardNavigationGestures: true
        },
        android: {
          allowZoom: true,
          hardwareBack: true,
          pauseMedia: true
        }
      }
    });
  }

  getUrl(): string {
    return this.ZOOMUBIK_URL;
  }
}
