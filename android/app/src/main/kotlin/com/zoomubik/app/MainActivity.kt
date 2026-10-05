package com.zoomubik.app

import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.webkit.CookieManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

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

    // ── HÁPTICO NATIVO ──────────────────────────────────────────────────────
    // El plugin "vibration" solo manda "vibra X ms con amplitud Y", y en muchos
    // Android eso se siente flojo aunque la amplitud sea la máxima. Aquí se usan
    // los efectos PREDEFINIDOS del sistema (CLICK y HEAVY_CLICK, Android 10+):
    // son formas de onda afinadas por el fabricante para su motor, bastante más
    // contundentes que un pulso plano. En versiones anteriores se cae a un pulso
    // corto de amplitud máxima. Si algo falla, Dart usa el plugin como respaldo.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zoomubik/haptic")
            .setMethodCallHandler { call, result ->
                if (call.method == "golpe") {
                    val fuerte = call.argument<Boolean>("fuerte") ?: false
                    try {
                        golpe(fuerte)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun obtenerVibrador(): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    private fun golpe(fuerte: Boolean) {
        val v = obtenerVibrador() ?: return
        if (!v.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            if (fuerte) {
                // Anuncio nuevo en directo: doble golpe fuerte (pausa de 40 ms)
                val tiempos = longArrayOf(0, 45, 40, 45)
                val amplitudes = intArrayOf(0, 255, 0, 255)
                v.vibrate(VibrationEffect.createWaveform(tiempos, amplitudes, -1))
            } else {
                // Marcador que cae: click fuerte
                v.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_HEAVY_CLICK))
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            v.vibrate(VibrationEffect.createOneShot(if (fuerte) 45L else 30L, 255))
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(if (fuerte) 45L else 30L)
        }
    }
}
