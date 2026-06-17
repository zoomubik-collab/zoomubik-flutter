package com.zoomubik.app

import android.os.Bundle
import android.webkit.CookieManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ── COOKIES DE SESIÓN (equivalente al cookieAcceptPolicy = .always de iOS) ──
        // Sin esto, el WebView de Android no acepta/persiste la cookie de login de
        // WordPress, y el usuario se queda fuera tras registrarse o iniciar sesión.
        val cookieManager = CookieManager.getInstance()
        cookieManager.setAcceptCookie(true)
        cookieManager.flush()
    }
}
