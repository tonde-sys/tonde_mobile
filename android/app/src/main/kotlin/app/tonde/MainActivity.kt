package app.tonde

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.media.AudioManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Activité hôte de Flutter, plus le pont vers le widget d'écran d'accueil.
 *
 * Le pont est un simple [MethodChannel] plutôt qu'un greffon tiers : il tient
 * en trente lignes, il n'ajoute aucune dépendance à maintenir, et il écrit
 * exactement dans le fichier de préférences que lit [TondeWidgetProvider]. Un
 * paquet générique écrirait dans son propre fichier et il faudrait de toute
 * façon adapter le fournisseur côté natif.
 *
 * Aucun de ces appels n'est critique : si le canal échoue, l'application
 * continue normalement et seul le widget reste en retard.
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "app.tonde/home_widget"

        /**
         * Mode sonore du téléphone.
         *
         * Flutter n'expose pas le mode sonnerie : sans ce canal, la sonnerie
         * d'appel retentirait dans un téléphone mis en silencieux.
         */
        private const val AUDIO_CHANNEL = "app.tonde/audio_mode"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "update" -> {
                        val values = call.arguments as? Map<*, *>
                        if (values == null) {
                            result.error(
                                "bad_arguments",
                                "update attend une map de valeurs.",
                                null
                            )
                        } else {
                            TondeWidgetProvider.applyState(this, values)
                            result.success(null)
                        }
                    }

                    "clear" -> {
                        TondeWidgetProvider.clearState(this)
                        result.success(null)
                    }

                    // Android 8.0 est la première version où le lanceur peut
                    // épingler un widget depuis l'application. En dessous, il
                    // faut passer par le sélecteur d'écran d'accueil, et
                    // l'écran de réglages masque alors le bouton.
                    "isPinSupported" -> result.success(isPinSupported())

                    "requestPin" -> result.success(requestPin())

                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // "silent" | "vibrate" | "normal"
                    "ringerMode" -> result.success(ringerMode())
                    else -> result.notImplemented()
                }
            }
    }

    private fun ringerMode(): String {
        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        return when (audio.ringerMode) {
            AudioManager.RINGER_MODE_SILENT -> "silent"
            AudioManager.RINGER_MODE_VIBRATE -> "vibrate"
            else -> "normal"
        }
    }

    private fun isPinSupported(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return false
        }
        val manager = AppWidgetManager.getInstance(this)
        return manager.isRequestPinAppWidgetSupported
    }

    private fun requestPin(): Boolean {
        if (!isPinSupported()) {
            return false
        }
        val manager = AppWidgetManager.getInstance(this)
        val provider = ComponentName(this, TondeWidgetProvider::class.java)
        // Pas de callback : l'utilisateur peut refuser dans la boîte de
        // dialogue du lanceur, et ce refus n'est pas une erreur à signaler.
        return manager.requestPinAppWidget(provider, null, null)
    }
}
