package app.tonde

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

/**
 * Widget d'écran d'accueil : le ticket en cours, sans ouvrir l'application.
 *
 * Le widget ne fait aucun calcul. Il lit l'état écrit par Dart dans [PREFS] et
 * le peint. Toute la logique — position, estimation, statut traduit — reste
 * côté application : un widget qui recalculerait un temps d'attente afficherait
 * un chiffre différent de l'écran, et l'utilisateur ne saurait plus lequel
 * croire. Les libellés arrivent eux aussi déjà composés, depuis les fichiers
 * ARB : traduire ici obligerait à maintenir le français, l'anglais et le
 * kirundi dans deux langues de code.
 *
 * Quand il n'y a pas de ticket, le widget affiche une invitation à en prendre
 * un plutôt que de disparaître : un widget qui s'efface laisse croire qu'il a
 * été retiré, et l'utilisateur le recrée.
 */
class TondeWidgetProvider : AppWidgetProvider() {

    companion object {
        /** Nom du fichier de préférences partagé avec le code Dart. */
        const val PREFS = "tonde_widget"

        const val KEY_HAS_TICKET = "has_ticket"
        const val KEY_NUMBER = "number"
        const val KEY_AGENCY = "agency"
        const val KEY_STATUS = "status"
        const val KEY_POSITION = "position"
        const val KEY_ETA = "eta"
        const val KEY_UPDATED = "updated"
        const val KEY_EMPTY_TITLE = "empty_title"
        const val KEY_EMPTY_BODY = "empty_body"

        /**
         * Toutes les clés écrites par l'application.
         *
         * Elles sont effacées avant chaque écriture : sans cela, un ticket qui
         * n'a plus d'estimation garderait l'ancienne valeur, et le widget
         * afficherait « 12 min » pour un ticket déjà terminé.
         */
        private val ALL_KEYS = arrayOf(
            KEY_HAS_TICKET,
            KEY_NUMBER,
            KEY_AGENCY,
            KEY_STATUS,
            KEY_POSITION,
            KEY_ETA,
            KEY_UPDATED,
            KEY_EMPTY_TITLE,
            KEY_EMPTY_BODY,
        )

        private fun prefs(context: Context) =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        /**
         * Enregistre l'état à afficher puis repeint les widgets posés.
         *
         * Les valeurs arrivent du canal `app.tonde/home_widget` sous forme de
         * map. Un type inattendu est converti en chaîne plutôt que de faire
         * échouer l'appel : le pire qui puisse arriver est un texte bizarre
         * dans un widget, jamais un crash de l'application.
         */
        fun applyState(context: Context, values: Map<*, *>) {
            val editor = prefs(context).edit()
            for (key in ALL_KEYS) {
                editor.remove(key)
            }
            for ((key, value) in values) {
                if (key !is String) continue
                when (value) {
                    null -> editor.remove(key)
                    is Boolean -> editor.putBoolean(key, value)
                    is Int -> editor.putInt(key, value)
                    is Long -> editor.putLong(key, value)
                    is String -> editor.putString(key, value)
                    else -> editor.putString(key, value.toString())
                }
            }
            editor.apply()
            refresh(context)
        }

        /** Efface l'état : le widget retombe sur son invitation. */
        fun clearState(context: Context) {
            prefs(context).edit().clear().apply()
            refresh(context)
        }

        /** Rafraîchit toutes les instances posées sur l'écran d'accueil. */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, TondeWidgetProvider::class.java)
            )
            if (ids.isEmpty()) {
                return
            }
            for (id in ids) {
                manager.updateAppWidget(id, buildViews(context))
            }
        }

        private fun buildViews(context: Context): RemoteViews {
            val prefs = prefs(context)
            val views = RemoteViews(context.packageName, R.layout.tonde_widget)

            // Le tap ouvre l'application. `FLAG_IMMUTABLE` est obligatoire
            // depuis Android 12 : un PendingIntent mutable est refusé.
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pending = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.tonde_widget_root, pending)

            if (!prefs.getBoolean(KEY_HAS_TICKET, false)) {
                views.setTextViewText(
                    R.id.widget_number,
                    prefs.getString(KEY_EMPTY_TITLE, "TONDE")
                )
                views.setTextViewText(
                    R.id.widget_agency,
                    prefs.getString(KEY_EMPTY_BODY, "")
                )
                views.setTextViewText(R.id.widget_status, "")
                views.setViewVisibility(R.id.widget_row_stats, View.GONE)
                views.setTextViewText(R.id.widget_updated, "")
                return views
            }

            views.setTextViewText(R.id.widget_number, prefs.getString(KEY_NUMBER, "—"))
            views.setTextViewText(R.id.widget_agency, prefs.getString(KEY_AGENCY, ""))
            views.setTextViewText(R.id.widget_status, prefs.getString(KEY_STATUS, ""))
            views.setTextViewText(R.id.widget_updated, prefs.getString(KEY_UPDATED, ""))

            val position = prefs.getString(KEY_POSITION, "").orEmpty()
            val eta = prefs.getString(KEY_ETA, "").orEmpty()
            views.setTextViewText(R.id.widget_position, position)
            views.setTextViewText(R.id.widget_eta, eta)
            // Les deux informations manquent parfois — file dégradée, estimation
            // pas encore fiable. On masque alors la ligne au lieu de laisser une
            // bande vide au milieu du widget.
            views.setViewVisibility(
                R.id.widget_row_stats,
                if (position.isEmpty() && eta.isEmpty()) View.GONE else View.VISIBLE
            )
            views.setViewVisibility(
                R.id.widget_position,
                if (position.isEmpty()) View.GONE else View.VISIBLE
            )
            views.setViewVisibility(
                R.id.widget_eta,
                if (eta.isEmpty()) View.GONE else View.VISIBLE
            )
            return views
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context))
        }
    }

    override fun onEnabled(context: Context) {
        // Posé pour la première fois : on peint tout de suite l'état courant,
        // sinon le widget reste sur la mise en page de prévisualisation
        // jusqu'au prochain changement de ticket.
        refresh(context)
    }
}
