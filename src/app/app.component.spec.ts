import { TestBed } from '@angular/core/testing';
import { AppComponent } from './app.component';
import { Platform } from '@ionic/angular';
import { NativeService } from './services/native.service';
import { WebViewService } from './services/webview.service';

describe('AppComponent', () => {
  it('should create the app', async () => {
    const platformSpy = jasmine.createSpyObj('Platform', ['ready', 'is']);
    platformSpy.ready.and.returnValue(Promise.resolve('dom'));
    platformSpy.is.and.returnValue(false);

    const nativeServiceSpy = jasmine.createSpyObj('NativeService', [
      'takePicture', 'pickPhoto', 'sendNotification', 'shareContent', 'cancelAllNotifications'
    ]);

    const webViewServiceSpy = jasmine.createSpyObj('WebViewService', ['openWebView', 'getUrl']);
    webViewServiceSpy.openWebView.and.returnValue(Promise.resolve());
    webViewServiceSpy.getUrl.and.returnValue('https://zoomubik.com');

    await TestBed.configureTestingModule({
      imports: [AppComponent],
      providers: [
        { provide: Platform, useValue: platformSpy },
        { provide: NativeService, useValue: nativeServiceSpy },
        { provide: WebViewService, useValue: webViewServiceSpy }
      ]
    }).compileComponents();

    const fixture = TestBed.createComponent(AppComponent);
    const app = fixture.componentInstance;
    expect(app).toBeTruthy();
  });
});
