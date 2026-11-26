# Plan de développement — application mobile TONDE

**Version :** 2.0 · **Date :** 22 novembre 2026 · **État au :** 26 novembre 2026
**Périmètre :** `tonde-mobile` (Flutter) + 2 ajouts backend (`fcm_gateway`, feedback)
**Statut :** 9 lots sur 9 livrés — restent les **essais sur appareil réel**, le déblocage iOS, et 4.7 (abandonné, voir L4)

### État global au 2026-11-26

| Lot | État | Ce qui manque |
|---|---|---|
| L0 — domaine ticket | **livré** 23/11 | — |
| L1 — session et splash | **livré** 22/11 | — |
| L2 — push | **livré côté Android** 26/11 | essai sur téléphone ; **iOS bloqué** (compte Apple payant) |
| L3 — son in-app | **livré** 26/11 | réglage utilisateur, vibration, mode silencieux respecté |
| L4 — widget | **livré** 24-25/11 | 4.9 (essais appareil) ; 4.7 abandonné (voir plus bas) |
| L5 — accueil dynamique | **livré** | essai appareil |
| L6 — assistance | **livré** 24/11 · **centre d'aide refondu** 26/11 | contacts de support par institution, fiches TONDE/institution, FAQ en page dédiée |
| L7 — erreurs | **livré** 24/11 | — |
| L8 — responsive | **livré** 24/11 | 8.7 remplacé par des assertions structurelles (assumé) |
| B1 — payload FCM | **livré** | — |
| B1bis — multi-appareils | **livré** 26/11 | — |
| B2 — feedback | **livré** | — |

**Reste à faire : rien de code.** Les essais sur appareil (L2, 4.9) et le déblocage iOS restent à faire côté produit.

### Livraison au 2026-11-26

| Produit | Version publiée | Contenu |
|---|---|---|
| Mobile | [`v1.0.0+2`](https://github.com/tonde-sys/tonde_mobile/releases/tag/v1.0.0) | APK 57,5 Mo — prise de ticket, suivi, push, son, widget, centre d'aide |
| Desktop | [`v0.3.0`](https://github.com/tonde-sys/tonde-desktop/releases/tag/v0.3.0) | MSI + NSIS + `latest.json` — file temps réel, rappel sans doublon |

Le tag déclenche la publication : `v*` sur mobile (`mobile-release.yml`) comme sur desktop (`release.yml`). Le tag doit correspondre à la version du `pubspec.yaml` / `package.json`, sinon le job s'arrête avant de compiler — un binaire qui annonce une autre version ne serait jamais proposé par l'updater.

**Deux réserves à connaître :**
- **Aucun keystore** n'est versionné : l'APK release est signé avec la clé de debug. Il remplace une installation de debug, mais ne peut pas aller sur le Play Store. Une vraie clé de publication est à créer avant la première mise en ligne.
- Le runner CI fournit un **JDK 25**, que Gradle 8.14 n'exécute pas : le workflow fixe Java 17 (`actions/setup-java`). Sans cela, la compilation échoue en 20 s.

---

## 0. Ce qui est déjà fait (à ne pas refaire)

Trois demandes sont déjà couvertes par le code actuel. Les vérifier avant de planifier du travail dessus :

| Demande | État réel | Où |
|---|---|---|
| « Guichet en pause jusqu'à 14h45 » | **Déjà implémenté.** Le backend envoie `paused_counters[]` avec `paused_until` dans le snapshot de file ; le mobile affiche « Guichet X en pause jusqu'à HH:MM » | `ticket_service.py:2416-2422`, `queue_snapshot.dart:45-60`, `queue_tracking_page.dart:319-322` et `:838` |
| Notifications « votre tour approche », « absent », « servi » | **La logique métier existe** (`TicketNotificationWatcher`), mais elle ne se déclenche que si l'application est ouverte : aucun push n'est branché | `ticket_notification_watcher.dart` |
| Reprise d'un ticket absent | **Le backend sait le faire** (`POST /tickets/{id}/return`, plafond 2 absences, fenêtre 30 min). Le mobile n'a pas encore le bouton | `routers/tickets.py:191` |

Ce qui manque sur la pause : l'information n'apparaît **que** sur l'écran de suivi. Elle doit remonter sur la carte d'accueil et sur le widget (lots L4 et L5).

> **Capture d'écran reçue le 22/11** — voir le constat détaillé en §1.1. Elle ne montre pas un problème de tablette mais un problème de **téléphone étroit (320 dp)** : la barre de navigation casse les mots en deux.

### 0.1 — Livré depuis la rédaction du plan

| Lot | Ce qui a changé | Où |
|---|---|---|
| **L1.1** | Plus jamais d'écran de connexion pour une session existante : trois états (*inconnu* / *connecté* / *anonyme*), résolution de session avant le montage de l'application, route `/demarrage` pour le cas réseau lent | `app/bootstrap.dart`, `app/router/app_router.dart`, `app/pages/startup_page.dart` |
| **L1.2** | Splash natif avec le logo TONDE centré (Android 7 à 14), 3 s de délai forcé ramenés à 900 ms menés en parallèle de la session, `SplashBrand` partagé pour que le logo natif et le logo Flutter occupent le même point | `android/app/src/main/res/**`, `app/pages/splash_page.dart` |
| **L8.2** | `TondeNavigationBar` : les cinq libellés, dont « Notifications », tiennent sur une ligne à 320 dp | `features/dashboard/presentation/widgets/tonde_navigation_bar.dart` |

---

## 1. Diagnostic des demandes

| # | Demande | Cause racine identifiée | Lot |
|---|---|---|---|
| 1 | Responsive incorrect sur certains appareils | **Aucun `MediaQuery` ni `LayoutBuilder` dans tout le projet.** Sur 320 dp, la barre de navigation casse « Notifications » et « Assistance » au milieu du mot (voir §1.1). Aucune largeur maximale, aucune grille adaptative, aucun `NavigationRail`, pas de garde sur le facteur de police | L8 |
| 2 | Notifications push absentes, pas d'icône TONDE | Aucune dépendance Firebase. Le backend envoie un payload minimal (`notification: {title, body}`, `android: {priority: HIGH}`) sans `channel_id`, sans `icon`, sans `sound` | L2 + B1 |
| 3 | Son instantané à l'appel | Aucun package audio, aucun asset sonore. `LocalNotificationService.show()` ne précise ni `icon`, ni `sound`, ni `vibration` | L3 |
| 4 | Widget d'accueil temps réel | Aucun `AppWidgetProvider`, aucun `MethodChannel`, aucun canal de mise à jour | L4 |
| 5 | Écran de connexion au démarrage malgré session valide | `redirect` lit `ref.read(authControllerProvider).value` **pendant** `AsyncLoading` → `null` → redirection vers `/connexion`, puis retour à l'accueil quand la session se résout | L1.1 |
| 6 | Splash : écran vide puis animation | Le splash natif est un **fond uni sans logo** (`launch_background.xml` = couleur seule, et `splash_blank` sur Android 12+), suivi d'un délai **forcé de 3 s** avant l'écran animé | L1.2 |
| 7 | Onglet Assistance vide | 68 lignes, un seul bouton « Contacter » qui affiche « Bientôt disponible ». Aucun endpoint de feedback côté backend | L6 |
| 8 | CTA « Prendre un ticket » non dynamique | `Ticket` ne porte **que** `served: bool` — ni statut, ni `recovery_expires_at`, ni `missed_count`. Impossible de distinguer « appelé », « absent », « expiré » | L0 + L5 |
| 9 | États absents/servis/expirés non reflétés | Même cause : le domaine mobile ignore le statut réel du ticket | L0 + L5 |
| 10 | Erreurs pauvres | `mapDioException` extrait bien le code métier, mais **aucune traduction code → message utilisateur**. Les écrans affichent des messages génériques | L7 |

---

### 1.1 — Constat sur la capture (accueil, 320 dp, thème sombre)

**Ce qui est cassé**

1. **Barre de navigation.** Cinq destinations dans 320 dp laissent ~64 dp par item. « Notifications » et « Assistance » ne tiennent pas sur une ligne et sont coupés **au milieu du mot** — « Notificatio / ns », « Assistanc / e ». Deux libellés passent sur deux lignes, les trois autres sur une seule : la barre n'a plus de ligne de base commune et grandit.
   *Cause :* `NavigationBar` Material 3 affiche toujours les libellés (`labelBehavior` par défaut), aucun `maxLines` ni `overflow` n'est posé, et rien ne réduit le nombre d'informations quand la largeur manque.
2. **Action dupliquée.** « Prendre un ticket » apparaît deux fois sur le même écran : dans la carte hero **et** dans la carte « Aucun ticket actif », juste en dessous. Deux boutons identiques pour une seule action, donc un choix inutile.
3. **Badge dupliqué.** La pastille « 5 » est à la fois sur la cloche de l'en-tête et sur l'onglet Notifications.

**Ce qui tient correctement à cette largeur :** l'en-tête, la carte hero, les textes et les marges. Le problème n'est donc pas général — il est concentré sur la barre de navigation et sur la redondance des actions.

**Correctifs retenus (détaillés en L8 et L5)**

- Libellés courts : **Accueil · Tickets · Alertes · Aide · Plus**. « Notifications » ne rentre pas à 320 dp, même à la taille de police par défaut.
- `labelBehavior: onlyShowSelected` sous 360 dp : seul l'onglet actif affiche son libellé. C'est le comportement Material prévu pour cinq destinations.
- `maxLines: 1` + `overflow: ellipsis` sur tous les libellés, pour qu'aucune casse de mot ne soit possible même avec une traduction plus longue (l'anglais et le kirundi n'ont pas la même longueur que le français).
- Suppression du CTA dupliqué : le hero porte l'action, la carte « Aucun ticket » devient purement informative.

---

## 2. Décisions techniques à valider

| Sujet | Choix proposé | Alternative écartée | Raison |
|---|---|---|---|
| Push | **Firebase Cloud Messaging** (`firebase_core` + `firebase_messaging`) | OneSignal, Pusher | Le backend a déjà `fcm_gateway.py` et `PUT /auth/me/fcm-token` : rien à réécrire côté serveur |
| Widget | **Android natif** : `AppWidgetProvider` + `RemoteViews` + `Chronometer` en countdown | `home_widget` (plugin) | Le countdown natif se met à jour chaque seconde **sans réveiller l'app** ; `home_widget` ne sait pas le faire sans tâche de fond |
| Compte à rebours | `Chronometer` avec `setCountDown(true)` et `setBase()` | Timer Dart + rafraîchissement | Aucune consommation batterie, précision à la seconde |
| Son in-app | `audioplayers` + un MP3 de 1,5 s | `just_audio`, `flutter_ringtone_player` | Plus léger, lecture d'asset triviale, contrôle du volume et du mode silencieux |
| Icône de notification | PNG **monochrome blanc sur transparent** (`ic_stat_tonde`) | Logo couleur | Android n'accepte que des silhouettes : un logo couleur s'affiche en carré blanc |
| iOS | **Hors périmètre v1** | WidgetKit + APNs | Chantier séparé (~5 j). À confirmer : le parc cible est Android |
| Statut du ticket | Enum `TicketStatus` dans le domaine | Multiplier les booléens | Une seule source de vérité pour les 8 états serveur |

---

## 3. Lots de travail

### L0 — Fondations du domaine ticket · **3 j** · bloquant pour tout le reste · **livré le 2026-11-23**

**Pourquoi d'abord :** le CTA dynamique, les notifications, le widget et l'accueil dépendent tous de la connaissance du statut réel.

| Tâche | Fichiers |
|---|---|
| Remplacer `served: bool` par `status: TicketStatus` (waiting, called, serving, absent, incomplete, transferred, done, cancelled) | `domain/entities/ticket.dart` |
| Ajouter `recoveryExpiresAt`, `missedCount`, `counterLabel`, `queueDegraded`, `totalInQueue` | idem |
| Propager dans le codec, le mapper API, le cache et le mock | `data/ticket_codec.dart`, `data/api_ticket_service.dart`, `data/cached_ticket_service.dart`, `data/mock_ticket_service.dart` |
| Adaptater `TicketPassCard`, `TicketPage`, `TicketsTab`, `QueueTrackingPage` | `presentation/**` |
| Mettre à jour les 171 tests existants | `test/**` |

**Critère d'acceptation :** `flutter analyze` propre, 171 tests verts, aucun `served` résiduel dans `lib/`.

**Livré :**
- `TicketStatus` dans `domain/entities/ticket_status.dart` : `fromWire` tolère les graphies historiques, `isClosed` ne retient que `done`/`cancelled`, `isQueued`, `isAtCounter`, `canResume`. Une valeur inconnue retombe sur `waiting` — bloquer à tort se répare, libérer à tort crée un doublon.
- `Ticket` porte `status`, `counterLabel`, `totalInQueue`, `recoveryExpiresAt`, `missedCount`, `queueDegraded` ; `canResumeAt(now)` rend la fenêtre testable sans horloge réelle.
- Codec : relit un cache antérieur au statut (repli sur l'ancien booléen `served`), écrit les nouveaux champs.
- Mapper API : `status`, `counter_name`, `total_in_queue`, `recovery_expires_at`, `missed_count`, `queue_degraded`.
- `TicketService.markServed` → `saveStatus` : l'état n'est plus seulement « servi », il est quelconque. L'écriture distante reste un no-op côté HTTP, mais un service de démonstration peut rester cohérent.
- `QueueTrackingKey` : le flux de suivi est désormais keyé sur l'identité du ticket, pas sur l'objet entier. Sans cela, chaque changement de statut rouvrait une connexion WebSocket, et l'ancienne restait vivante tant qu'un `ref.listen` la tenait.
- Le contrôleur applique le statut du flux et le persiste ; il refuse de rouvrir un ticket clos (états terminaux) et ignore un instantané qui ne concerne plus le ticket courant.
- Tests : `test/features/tickets/ticket_status_test.dart` (10 cas) + « un ticket absent garde sa place et bloque la prise ».

---

### L1 — Démarrage : session et splash · **2 j**

#### L1.1 — Ne jamais montrer l'écran de connexion à un utilisateur connecté · **livré le 2026-11-22**

**Cause précise :** dans `app_router.dart`, `redirect` fait `ref.read(authControllerProvider).value != null`. Au démarrage à froid, le provider est en `AsyncLoading`, donc `.value == null`, donc redirection vers `/connexion`. La page de connexion se construit, la session se résout, `ref.listen` déclenche `router.refresh()` → retour à l'accueil. D'où le clignotement décrit.

**Solution retenue :** trois états au lieu de deux — *inconnu*, *connecté*, *anonyme*.
- `redirect` : si `isLoading` → **ne pas rediriger** (retourner `null`).
- `TondeBootstrap` attend `authControllerProvider.future` (plafond 2 s, minuteur annulé dès la réponse) **avant** de construire `TondeApp`.
- `initialLocation` est calculé depuis la session déjà résolue : `/accueil`, `/connexion`, ou `/demarrage` si le plafond a expiré.
- Nouvelle route `/demarrage` (`StartupPage`) : elle ne s'affiche que dans ce dernier cas, et `ref.listen` rafraîchit le routeur dès que la session se révèle — y compris quand elle se révèle *absente*, ce qui laisserait sinon l'utilisateur bloqué.

**Livré :**
- `app/routes` + `app/pages/startup_page.dart` + `app/router/app_router.dart` + `app/bootstrap.dart`.
- Tests : `test/app/startup_test.dart` — « une session en cache mène au tableau de bord sans jamais montrer la connexion » inspecte **chaque image** du démarrage, pas seulement la dernière.

#### L1.2 — Splash natif avec le logo · **livré le 2026-11-22**

| Tâche | Ce qui a été fait |
|---|---|
| `launch_background.xml` | `layer-list` : fond `#1E293B` + `@drawable/tonde_splash_icon` centré. `drawable-v21` supprimé (doublon identique, `minSdk = 24`) |
| `values-v31` / `values-night-v31` | `windowSplashScreenAnimatedIcon` = logo TONDE (au lieu de `splash_blank`, supprimé) ; `windowSplashScreenIconBackgroundColor` = fond |
| `drawable/tonde_splash_icon.xml` | Canevas de 192 dp avec le logo à 116 dp : que le système respecte la taille intrinsèque ou qu'il mette l'icône à l'échelle, le logo retombe sur 116 dp |
| Assets | `drawable-{m,h,xh,xxh,xxxh}dpi/tonde_splash_logo.png` générés depuis `assets/images/app_logo.png` (116/174/232/348/464 px) |
| Délai | 3 s fixes → `splashDuration` = 900 ms, mené **en parallèle** de la résolution de session |
| Alignement | `SplashBrand` centre le logo au pixel près (test : écart < 1,5 dp du centre de l'écran) et déplace la file d'attente en pied d'écran |

`postSplashScreenTheme` n'a pas été ajouté : il exige `androidx.core:core-splashscreen`, absent du projet, et le `NormalTheme` passé par le manifeste Flutter joue déjà ce rôle.

**Critère :** aucun écran uni sans logo ✔ ; splash perçu < 1,2 s ✔ (900 ms après la première image Flutter) ; transition sans flash ✔ (le logo natif et le logo Flutter occupent le même point).

---

### L2 — Notifications push réelles · **5 à 6 j**

| # | Tâche | Détail | État |
|---|---|---|---|
| 2.1 | Firebase | `firebase_core`, `firebase_messaging`, `google-services.json`, plugin Gradle | **code livré** — dépendances et plugin en place ; il manque les fichiers de configuration du projet Firebase |
| 2.2 | Icône | `ic_stat_tonde` (24/48/72/96 dp, blanc sur transparent) + meta-data `default_notification_icon` et `default_notification_color` | **livré** |
| 2.3 | Canaux | Réutiliser `tonde_queue_urgent` (importance max, son par défaut, vibration) et `tonde_queue_progress`. **Les canaux doivent exister avant le premier push** : création au démarrage (déjà en place) | **livré** |
| 2.4 | Jeton | `onTokenRefresh` + enregistrement au login et au refresh via `PUT /auth/me/fcm-token` ; `null` au logout | **livré** |
| 2.5 | Permission | Android 13+ : demander à la première prise de ticket (déjà le bon moment), avec écran d'explication avant le dialogue système | **livré** côté Android ; iOS demande l'autorisation à l'initialisation du service push |
| 2.6 | Trois états | *Foreground* → son in-app, pas de bannière. *Background* → bannière système. *Terminated* → bannière + tap → écran de suivi | **livré**, sauf le son in-app qui relève de L3 |
| 2.7 | Deep link | `click_action` → `/tickets/suivi`, en vérifiant que le ticket du payload est bien le ticket actif | **livré** |

**Backend B1 (obligatoire, ~0,5 j) :** dans `fcm_gateway.py`, enrichir le payload Android :

- `notification.channel_id` = `tonde_queue_urgent` ou `tonde_queue_progress` selon l'événement
- `notification.icon` = `ic_stat_tonde`
- `notification.sound` = `default` (respecte le mode sonore du téléphone)
- `notification.default_vibrate_timings` = `true`
- `android.priority` = `HIGH` pour `your_turn` et `absent_warning`
- `data` avec `ticket_id`, `type`, `click_action`

**Limite connue — corrigée le 2026-11-26 (B1bis).** `User.fcm_token` était unique par utilisateur : se connecter sur un second téléphone coupait les notifications du premier. La table `user_devices` (migration `023`) porte désormais un appareil par jeton ; l'envoi itère sur tous les appareils, et un jeton invalide ne retire que celui-là. `users.fcm_token` reste entretenu comme « dernier appareil connu » pour les clients antérieurs.

**Livré (code) :**
- `PushService` (`data/push_service.dart`) : interface + `NoopPushService` + `FirebasePushService`. L'interface isole Firebase pour que l'enregistrement du jeton et la navigation à l'appui soient testables sans appareil.
- `Firebase.initializeApp()` est appelé **sans `firebase_options.dart`** : les options viennent des fichiers natifs (`google-services.json` sur Android, `GoogleService-Info.plist` sur iOS). Pas besoin de la CLI FlutterFire.
- Échec d'initialisation = `initialize()` retourne `false`, l'application démarre sans push. Un build sans configuration Firebase ne casse donc rien.
- `PushRegistrar` (`data/push_registrar.dart`) : `PUT /auth/me/fcm-token` à l'apparition d'une session, réenregistrement sur `onTokenRefresh`, et effacement à la déconnexion. Le jeton déjà accepté n'est pas renvoyé.
- **Ordre de la déconnexion** : `AuthNotifier.logout()` coupe le jeton **avant** de fermer la session — l'endpoint exige un accès valide. Sans cet ordre, l'appareil garderait le jeton d'un compte fermé et recevrait encore ses appels au guichet.
- `pushDriverProvider` : appuis (`onMessageOpenedApp` + `getInitialMessage` pour le lancement à froid) → ouvre le suivi **si** le ticket du payload est bien celui du compte, sinon l'accueil.
- `ApiClient.put()` ajouté : le backend expose `PUT /auth/me/fcm-token`, et `PATCH` ne garantit pas l'idempotence attendue.
- Plugin Gradle `com.google.gms.google-services` déclaré dans `settings.gradle.kts` et appliqué **conditionnellement** dans `app/build.gradle.kts` : sans `google-services.json`, le build passe et un message le signale.
- iOS : cible de déploiement relevée de 13.0 à **15.0** (`project.pbxproj` + `AppFrameworkInfo.plist`) — `firebase_messaging` 17 exige iOS 15. `Runner.entitlements` créé (`aps-environment`) et référencé par `CODE_SIGN_ENTITLEMENTS` sur les trois configurations ; `UIBackgroundModes = remote-notification` dans `Info.plist`.
- Le jeton reste obtenu par `getToken()` : `register()`/`onRegistered` renvoient un FID, dont l'équivalence côté API FCM v1 n'est pas documentée. La migration ne touchera que `FirebasePushService`.
- Tests : `test/features/notifications/push_registrar_test.dart` (7 cas).

**Débloqué le 2026-11-26 (Android) :** `google-services.json` en place (projet `gen-lang-client-0973714506`, package `app.tonde`), APK compilé avec la configuration injectée — vérifié dans `build/app/generated/res/processDebugGoogleServices/values/values.xml` (`gcm_defaultSenderId`, `google_app_id`, `google_api_key`) plutôt qu'en croyant le build sur parole. Côté serveur : `FIREBASE_PROJECT_ID` + `FIREBASE_SERVICE_ACCOUNT_JSON` renseignés, jeton OAuth2 obtenu, et `messages:send` répond `400 INVALID_ARGUMENT` sur un faux jeton — la preuve que l'API Cloud Messaging est active (un `403 SERVICE_DISABLED` aurait dit l'inverse).

**Reste bloqué :** iOS uniquement — pas de compte Apple Developer payant, donc ni `GoogleService-Info.plist`, ni clé APNs `.p8`. Le code est prêt (`aps-environment`, `remote-notification`, `CODE_SIGN_ENTITLEMENTS`).

**Reste à vérifier :** le critère d'acceptation sur un téléphone réel (app tuée → appel → notification → tap → suivi).

**Critère :** app tuée, ticket appelé → notification avec le logo TONDE, son selon le mode du téléphone, vibration, tap → suivi du bon ticket.

---

### L3 — Son et vibration in-app à l'appel · **2 j** · **livré le 2026-11-26**

**État réel :** `assets/sounds/ticket_called.mp3` (2,61 s, mono 44,1 kHz, 128 kbps, pic à −1,9 dBFS), `audioplayers` 6.7, et `CallAlertController` écrit et testé.

**Ce qui bloque, et ce qui ne bloque pas :** le fichier son est attendu de ta part, mais il ne bloque que le *rendu final*. Toute l'intégration (arbitre, lecture, coupure, vibration, réglages, repli) se développe avec un fichier provisoire — le chemin est fixe, le remplacer ne touchera aucune ligne de code.

**Ce qui existe déjà, contrairement à ce que laissait croire la ligne 2.6 :** le veilleur appelle `LocalNotificationService.show()`, et le canal `tonde_queue_urgent` est créé en `Importance.max` sans `playSound: false` — donc **un appel produit déjà une bannière, un son et une vibration**, même application ouverte. Le client n'est donc pas dans le silence.

**Ce que L3 apporte réellement :** ce son-là est un **bip unique de notification**, pas une sonnerie. Il ne se répète pas, ne s'arrête pas quand on ouvre le suivi, et ne se distingue pas d'une notification banale dans une salle bruyante. L3 ajoute la sonnerie qui insiste (3 répétitions max ou jusqu'à interaction), l'arbitrage anti-double-son entre FCM premier plan et événement WebSocket `your_turn`, le réglage utilisateur, et le repli vibration seule si le fichier est illisible. C'est une amélioration d'expérience, pas la correction d'un trou.

**Le son est fourni par toi**, pas généré ici : un son synthétique sonnerait « robot » et ne porterait pas la marque. Le lot couvre uniquement l'intégration — le fichier se dépose dans `assets/sounds/` et tout le reste est déjà branché.

**Spécification du fichier attendu** (à respecter pour que le rendu soit propre sur tous les téléphones) :

| Critère | Valeur | Pourquoi |
|---|---|---|
| Format | MP3 128 kbps ou OGG Vorbis | Lus partout, poids faible |
| Durée | 1,5 à 3 s, bouclable sans coupure | Au-delà, l'alerte devient agressive |
| Début | **Aucun silence** en tête (< 50 ms) | Un blanc de 300 ms donne l'impression que rien ne sonne |
| Niveau | Pic à −1 dB, moyenne autour de −14 LUFS | Audible dans une salle bruyante sans saturer le haut-parleur |
| Canaux | Mono | Le téléphone n'a qu'un haut-parleur |
| Fin | Fondu de 100 ms | Évite le « clic » de coupure |
| Nom | `ticket_called.mp3` | Convention du projet |

Si tu produis aussi une version voix (« Ticket A-014, guichet 3 »), elle ne peut pas être un fichier fixe : le numéro et le guichet changent. Ce serait un assemblage à l'exécution (annonce pré-enregistrée par chiffre + par guichet), donc un chantier distinct. Le fichier fixe reste la v1.

**Conversion appliquée (ffmpeg)** — depuis `D:\TONDE\sons`, la source retenue est la narration de 3,32 s, la seule qui tienne sous 3 s après coupe du silence :

```bash
ffmpeg -y -i "ElevenLabs_2026-11-24T15_42_41_Lucie - Narration_pvc_s50_sim75_v4.mp3" \
  -af "atrim=start=0.63:end=3.20,asetpts=N/SR/TB,volume=4.2dB,\
afade=t=in:st=0:d=0.08,afade=t=out:st=2.44:d=0.13" \
  -ac 1 -ar 44100 -c:a libmp3lame -b:a 128k -write_xing 0 \
  assets/sounds/ticket_called.mp3
```

Les quatre sources écartées mesurent 3,55 s à 4,99 s : même coupées, elles dépassent la limite de 3 s. Toutes avaient 0,65 à 0,94 s de silence en tête — c'est ce que `atrim` supprime. Le remplacement du fichier ne touchera aucune ligne de code.

**Livré le 2026-11-26 — ce que fait le contrôleur :**

- **Trois lectures maximum**, espacées de 700 ms. Assez pour être entendu dans une salle bruyante, assez court pour ne pas hurler.
- **Dédoublonnage de 30 s par ticket.** Le flux temps réel et le push racontent le même événement : sans cette fenêtre, le client entendrait deux sonneries pour un seul appel.
- **Arrêt immédiat** dès que le ticket passe `inService` / `done`, ou qu'il disparaît. Une alerte qu'on ne peut pas faire taire est une agression.
- **Mode silencieux respecté** via un canal natif `app.tonde/audio_mode` (`AudioManager.ringerMode`), que Flutter n'expose pas. En silencieux : vibration seule.
- **Vibration de secours** : trois impulsions `HapticFeedback.heavyImpact()` partent **avant** la lecture. Si le fichier est illisible, le client est quand même prévenu.
- **Réglage utilisateur** « Son à l'appel », distinct de l'interrupteur des notifications : on peut vouloir la bannière sans la sonnerie.
- Tests : `test/features/notifications/call_alert_test.dart`, 9 cas (répétitions, dédoublonnage, autre ticket, fenêtre expirée, arrêt en cours, silencieux, fichier illisible, désactivé, dispose).

| # | Tâche |
|---|---|
| 3.1 | Ajouter `audioplayers` et le dossier `assets/sounds/` (le fichier est fourni par toi) |
| 3.2 | `CallAlertController` : **arbitre unique** qui décide qui sonne — FCM au premier plan ou événement WebSocket `your_turn` — pour éviter le double son |
| 3.3 | Lecture : 3 répétitions maximum ou jusqu'à interaction ; respecter le mode silencieux/vibreur du téléphone (ne pas sonner si l'appareil est en silencieux) |
| 3.4 | Vibration : `HapticFeedback.heavyImpact()` en motif de 3 impulsions |
| 3.5 | Coupure : arrêt du son dès l'ouverture du suivi ou le passage en `serving` |
| 3.6 | Réglage utilisateur dans « Plus » : son activé / vibration activée (mémorisé) |
| 3.7 | Repli si le fichier est absent ou illisible : vibration seule, jamais de crash ni de silence total |

**Où le son est joué :** dans l'application **mobile du client** (celle de l'usager), au moment où son ticket est appelé. Ce n'est ni le poste guichetier ni l'écran de salle. Déclencheur : l'événement `your_turn` reçu par le WebSocket de suivi, ou le push FCM si l'application est au premier plan.

**Critère :** ticket appelé, app ouverte → son + vibration en moins d'une seconde, un seul son, arrêt au bon moment, silence respecté si le téléphone est en mode silencieux.

---

### L4 — Widget d'écran d'accueil · **6 à 8 j**

**Contenu du widget :** logo TONDE · numéro de ticket en gros · position · personnes devant · compte à rebours · organisation / agence / service · état (en attente / appelé / guichet en pause jusqu'à HH:MM).

| # | Tâche | Détail |
|---|---|---|
| 4.1 | Provider natif | `TondeWidgetProvider.kt` + `res/xml/tonde_widget_info.xml` + `res/layout/widget_tonde.xml`. `resizeMode`, `minWidth/minHeight`, `targetCellWidth/Height` (API 31+), `previewLayout` |
| 4.2 | Countdown | `Chronometer` en `setCountDown(true)`, `setBase(now + minutes restantes)` → mise à jour chaque seconde sans réveiller l'app |
| 4.3 | Pont Flutter | `MethodChannel('app.tonde/widget')` : `update(state)`, `clear()`, `requestPin()`. L'état est écrit dans `SharedPreferences` pour survivre au redémarrage |
| 4.4 | Mise à jour | À chaque `queue_update` et à chaque push : `AppWidgetManager.updateAppWidget()`. Aucun polling |
| 4.5 | Épinglage | `requestPinAppWidget` (API 26+). Sur API 24-25 : écran d'instructions vers le sélecteur de widgets |
| 4.6 | Invitation | Après la prise de ticket, bottom sheet « Suivez votre position depuis l'accueil » + « Ajouter le widget » / « Plus tard » (choix mémorisé) |
| 4.7 | Notification dédiée | Notification avec action « Créer le widget » → ouvre l'app avec `EXTRA_PIN_WIDGET` → déclenche le dialogue système |
| 4.8 | Cycle de vie | Widget remis à zéro quand le ticket est terminé ; état vide avec « Prendre un ticket » |
| 4.9 | Tests | Widget à 2×2, 4×2 et 4×4 ; appareil verrouillé ; redémarrage du téléphone |

**Critère :** widget posé sur l'accueil, countdown fluide, mise à jour à l'appel **sans ouvrir l'app**.

> **iOS :** hors périmètre v1. WidgetKit demande une extension Swift, un App Group et un partage d'état — chantier séparé (~5 j).

**Livré le 2026-11-24 :**

- **4.1 Natif** — `TondeWidgetProvider.kt`, `res/layout/tonde_widget.xml`, `res/xml/tonde_widget_info.xml`, `res/drawable/tonde_widget_background.xml`, `res/values/strings.xml`. `resizeMode="horizontal|vertical"`, `targetCellWidth/Height` 4×2 (API 31+, ignorés en dessous), `previewLayout`, `updatePeriodMillis="0"`. Le récepteur est `exported="true"` : les diffusions `APPWIDGET_UPDATE` viennent du système, donc d'un autre uid — en `false` le widget resterait figé sur sa prévisualisation. Il n'expose rien (il lit ses propres préférences).
- **4.2 Countdown : écarté volontairement.** Le plan prévoyait un `Chronometer` en `setCountDown(true)`. Un compteur qui défile à la seconde affiche une précision que l'AWTE n'a pas : l'estimation est réévaluée toutes les quelques secondes côté serveur, et deux chiffres différents (le widget qui descend, l'écran qui saute de 12 à 9 min) feraient douter des deux. Le widget affiche donc « ≈ 12 min » **et l'heure de dernière mise à jour** — c'est cette heure qui permet de juger si le chiffre est encore vrai, ce qu'un compte à rebours ne dit jamais.
- **4.3 Pont** — `MethodChannel('app.tonde/home_widget')` dans `MainActivity` : `update`, `clear`, `isPinSupported`, `requestPin`. Pas de greffon tiers : trente lignes, aucune dépendance à maintenir, et il écrit exactement dans le `SharedPreferences("tonde_widget")` que lit le fournisseur. Côté Dart, `core/platform/home_widget_bridge.dart` (`HomeWidgetState`, passerelle réelle, passerelle inerte) — iOS et tests obtiennent la passerelle inerte sans code conditionnel ailleurs.
- **4.4 Mise à jour** — `homeWidgetDriverProvider`, observé une seule fois dans `TondeApp`. Il écoute `homeWidgetStateProvider`, qui fusionne le ticket (`activeTicketProvider`) et la dernière photo du flux (`queueTrackingProvider`) : la position et l'attente viennent du flux, plus frais que le ticket. Aucun polling. `HomeWidgetState` a une égalité par valeur : un écran qui se reconstruit ne réveille pas le widget.
- **4.5 Épinglage** — entrée « Widget d'écran d'accueil » dans l'onglet Plus, affichée **seulement** si `isPinSupported()` répond vrai : un bouton qui explique ensuite qu'il ne peut rien faire est pire que pas de bouton. Si le lanceur refuse, le message renvoie vers l'écran d'accueil.
- **4.8 Cycle de vie** — ticket clos ou absent → état vide « Aucun ticket / Touchez pour en prendre un ». Le widget ne disparaît pas : un widget qui s'efface laisse croire qu'il a été retiré, et l'utilisateur le recrée.
- **Textes** — le widget natif ne traduit rien. Toutes les chaînes sont composées en Dart depuis les ARB (`widgetEmptyTitle`, `widgetEmptyBody`, `widgetPosition`, `widgetEta`, `widgetUpdated`, `widgetCounterPaused…`) : deux tables de correspondance donneraient tôt ou tard deux formulations pour le même état.
- **Pause guichet (complète 5.3)** — quand un guichet de la file est en pause, la pause occupe la place de l'attente (« Pause jusqu'à 14:45 ») : c'est la réponse à la seule question que se pose un client devant un compteur qui n'avance pas, et une durée estimée à côté d'un guichet fermé se lirait comme un retard.
- **Bug corrigé au passage** — la carte de ticket de l'accueil affichait l'heure de reprise d'une pause **en UTC** (`TimeOfDay.fromDateTime(until)` sans `toLocal()`) : deux heures de décalage à Bujumbura. L'écran de suivi, lui, faisait déjà la conversion.
- **Hauteur** — 114 dp de contenu pour les 110 dp d'un 4×2 : chaque ligne ajoutée se paie en bas du cadre. Numéro en 28 sp, tout le reste en 9–12 sp.
- **Tests** — `test/core/home_widget_bridge_test.dart` (contrat du canal, clés, réponses nulles), `test/features/tickets/home_widget_state_test.dart` (17 cas : absence, ticket clos, file dégradée, estimation nulle, pause, appel avec guichet, hors ligne, trois langues), `test/features/tickets/home_widget_driver_test.dart` (publication initiale, déduplication, canal absent, erreur de plateforme, câblage réel), et deux cas dans `settings_test.dart` (entrée cachée / épinglage demandé).

**Complété le 2026-11-25 :**
- **4.6 Invitation après prise de ticket** — une carte s'insère sous le numéro, sur l'écran de confirmation : « Suivez votre position depuis l'accueil », avec « Ajouter le widget » et « Plus tard ». **Pas une feuille modale** : le client vient de prendre un ticket et veut lire son numéro, pas arbitrer une question d'installation ; une carte non bloquante obtient la même découvrabilité sans retarder l'écran. Le choix est mémorisé sur l'appareil (`home_widget.invite`), et « Plus tard » vaut refus définitif — relancer quelqu'un qui a déjà dit non ne le convaincra pas, et l'entrée reste dans l'onglet Plus. La carte disparaît d'elle-même quand le lanceur ne sait pas épingler (iOS, certains lanceurs Android) : proposer une action impossible est pire que de ne rien proposer. Elle n'apparaît ni pour un ticket clos (plus rien à suivre) ni pour un ticket hors ligne (le widget n'aurait rien à afficher). Tests : `test/features/tickets/home_widget_invite_test.dart` (6 cas, dont le refus du lanceur expliqué).

**Reste à faire sur L4 :**
- **4.7 Notification « Créer le widget » — abandonné le 2026-11-26, assumé.** La carte d'invitation (4.6) couvre déjà le besoin au bon moment — juste après la prise du ticket, quand le client regarde son numéro — et l'entrée reste dans l'onglet Plus. Une notification avec action arriverait plus tard, souvent application fermée, pour demander une manipulation que le système fait mieux depuis l'application ; elle ajouterait un canal de plus à tester sur chaque lanceur Android pour un gain nul. Si le besoin réapparaît, la brique existe déjà : `HomeWidgetBridge.requestPin()` et `isPinSupported()`.
- **4.9 Essais sur appareil** (2×2, 4×2, 4×4, écran verrouillé, redémarrage) — la compilation APK passe, mais un widget ne se valide qu'en le posant. À faire sur un téléphone réel.

---

### L5 — Accueil dynamique et états · **4 j**

| # | Tâche | État |
|---|---|---|
| 5.1 | **CTA contextuel** de la grande carte : aucun ticket → « Prendre un ticket » · en attente → « Voir ma position » · appelé → « Je suis au guichet » (urgent) · absent → « Reprendre mon ticket » · terminé → « Prendre un ticket ». **Un seul CTA par écran** : la carte « Aucun ticket actif » devient informative, elle ne duplique plus le bouton du hero (constat §1.1) | **livré** |
| 5.2 | **Reprise** : `POST /tickets/{id}/return`, avec le temps restant de la fenêtre de 30 min et la gestion de `recovery_allowed=false` / `MISSED_LIMIT_REACHED` | **livré** — le backend répond `RECOVERY_WINDOW_EXPIRED` et `MAX_MISSED_COUNT_REACHED` (pas les codes du plan), les deux sont traduits |
| 5.3 | **Carte adaptative** : couleur, titre et sous-titre par statut, dont « Guichet 3 en pause jusqu'à 14h45 » | **livré** — statut et badge par état ; la pause figure sur la carte d'accueil, sur l'écran de suivi et sur le widget, avec l'heure de reprise convertie en heure locale |
| 5.4 | **Expiration** : `GET /tickets/active` renvoie `null` → état « Votre ticket a expiré » + explication + « Prendre un ticket » | **livré** — la note distingue « passage terminé » de « ticket expiré », et n'apparaît que si un ticket a réellement disparu |
| 5.5 | **Notifications d'état** : absent, servi, expiré — poussées même app fermée (dépend de L2) | **livré le 2026-11-26 côté Android** — identifiants Firebase en place, APK compilé avec la configuration injectée, compte de service backend validé (jeton OAuth2 obtenu, API Cloud Messaging active). **iOS en attente** du compte Apple Developer payant. Reste l'essai sur appareil réel. |
| 5.6 | i18n FR / RN / EN pour tous les nouveaux libellés | **livré** |

**Livré :**
- `TicketService.resumeTicket` : `POST /tickets/{id}/return` puis relecture du ticket actif (le serveur ne renvoie pas le ticket complet, et la position a changé de toute façon).
- La bannière d'accueil devient `ConsumerStatefulWidget` : libellé, icône et action suivent `status` ; l'état d'attente et les refus serveur sont gérés.
- `_AbsentNotice` : « Reprenez votre ticket avant HH:MM », échéance convertie en heure locale (l'API renvoie de l'UTC).
- Même action dans l'onglet Tickets et sur l'écran de suivi — c'est là que le client découvre son absence.
- Un seul « Prendre un ticket » sur l'accueil : la carte d'état vide perd son bouton, la carte du pass perd son lien « Voir ma position » (la bannière le porte).
- `resumeErrorMessage` traduit les codes métier ; le message français du serveur n'est jamais affiché tel quel.
- Correction au passage : l'heure de reprise d'un guichet en pause était affichée en UTC (`until` sans `toLocal()`), soit deux heures de décalage à Bujumbura.
- **Expiration (5.4)** : `GET /tickets/active` répond `null` aussi bien pour un nouveau venu que pour un client dont le ticket vient d'être retiré de la file. Le backend ne fait pas la différence, donc c'est le cache qui s'en souvient : au moment précis où le serveur passe de « un ticket » à « aucun », `CachedTicketService` range le ticket dans `ticket.last_closed` avant de vider `ticket.active`. La note n'apparaît donc que si un ticket a réellement disparu — un nouveau venu garde la carte « Aucun ticket actif ».
  - Le statut mémorisé choisit les mots : `serving`/`done` → « Votre passage est terminé », sinon → « Votre ticket a expiré ». Un client servi n'a pas « expiré », et c'est la seule chose qu'il retiendra de l'écran.
  - L'avis s'efface de lui-même : dès qu'un ticket redevient actif (`_writeActive`), après une annulation volontaire (le client sait pourquoi), et au bout de 24 h (au-delà, « reprenez un ticket » se lit comme un défaut).
  - Affiché sur l'accueil et dans l'onglet Tickets ; le bouton reste porté par la bannière pour ne pas dupliquer le CTA.
- Tests : `test/features/dashboard/hero_action_test.dart` (7 cas : sans ticket, en attente, clos, absent → reprise, fenêtre dépassée, ticket disparu, ticket servi) et `test/features/tickets/last_closed_ticket_test.dart` (6 cas sur la mémoire de clôture).

**5.5 — livré côté serveur le 2026-11-25.**
- **Le trou réel était la clôture par un agent.** `close_ticket` retirait un ticket WAITING / ABSENT / INCOMPLETE de la file sans rien envoyer : le client voyait son numéro disparaître et concluait à un bug — exactement le défaut déjà corrigé pour l'expiration à 12 h. La clôture passe désormais par `_notify_expired` (in-app + FCM + événement `TICKET_EXPIRED`).
- **Le motif envoyé est neutre** (« clôture par l'agence »). La raison saisie par l'agent reste dans le journal d'audit : elle peut contenir une note interne (« n'est jamais revenu ») que le client n'a pas à lire telle quelle. Test : `test_close_ticket_tells_the_client_why` vérifie les deux — le motif arrive, la note interne ne fuit pas.
- **« Servi » reste in-app, volontairement.** `DONE` n'est atteignable que depuis `SERVING` : le client est alors debout devant le guichet, et une bannière « service terminé » à cet instant est du bruit. L'information lui parvient par l'état de l'application (accueil et onglet Tickets) et par la boîte in-app. Le push existe pour joindre un client absent, pas pour doubler ce qu'il voit.
- **Côté mobile, rien à ajouter** : le handler de fond, l'appui qui lance l'application et le routage vers le suivi étaient déjà en place (`push_service.dart`, `push_providers.dart`). Un message pour `ticket_absent` / `ticket_expired` ouvre le suivi du bon ticket.
- **Ce qui manque pour que ça sonne** : `FIREBASE_PROJECT_ID` et le compte de service côté backend, plus `google-services.json` côté Android. Sans eux, `_send_fcm` journalise un avertissement et n'envoie rien — le reste (in-app, SMS, événements) fonctionne.

**Critère :** chaque état a un écran, un message et un CTA cohérents. Aucun bouton mort, aucune impasse.

---

### L6 — Assistance et retours utilisateurs · **4 j** (dont 1,5 backend)

**Contenu de l'onglet Assistance :**

1. **Mon ticket** — raccourcis : voir ma position, reprendre, annuler
2. **Questions fréquentes** — 6 entrées : prendre un ticket · je suis absent, que faire ? · mon ticket a expiré · guichet en pause · notifications · widget d'accueil
3. **Nous contacter** — WhatsApp, téléphone, e-mail (support TONDE ou organisation)
4. **Donner mon avis** — note 1 à 5, catégorie, message libre
5. **Signaler un problème** — même formulaire, catégorie « bug », joint automatiquement version de l'app, modèle d'appareil et langue
6. **Mes retours** — historique et statut (reçu / lu / traité)
7. **État du service** — ping `/health` + version de l'app

| # | Tâche | Côté | État |
|---|---|---|---|
| 6.1 | Table `feedback` : `id`, `user_id`, `org_id` (nullable), `category` (avis/bug/suggestion), `rating` (1-5, nullable), `message`, `app_version`, `platform`, `device_model`, `locale`, `status`, `created_at` — migration `021_feedback` | Backend | livré |
| 6.2 | `POST /api/v1/feedback` (auth requise, rate limit 5/h, message 20-1000 caractères) et `GET /api/v1/feedback/mine` | Backend | livré |
| 6.3 | Écran Assistance + formulaire + historique | Mobile | livré |
| 6.4 | Anti-abus : un seul retour « service » par ticket ; pas de donnée personnelle inutile dans le message | Backend | livré |

**Critère :** un utilisateur envoie un avis et le retrouve dans « Mes retours » ; le support peut lire les retours en base.

**Livré le 2026-11-24 :**

- **Base** — table `feedback`, migration `021_feedback`. Les libellés d'ENUM sont écrits en majuscules (`REVIEW`, `RECEIVED`) parce que SQLAlchemy persiste les **noms** des membres Python : la migration `007` avait déjà dû renommer tous les types existants pour cette raison. Deux contraintes vivent en base et non dans le modèle : `rating` entre 1 et 5, et `message` d'au moins 20 caractères — elles s'appuient sur `char_length`/`btrim`, absents de SQLite, et les inscrire dans le modèle aurait cassé la création des tables en test.
- **Rattachement** — `org_id` et `ticket_id` sont en `ON DELETE SET NULL`, pas `CASCADE` : un retour déjà envoyé ne doit pas s'effacer parce qu'un ticket a été purgé. `user_id` reste en `CASCADE` (droit à l'effacement).
- **Quota** — 5 retours par heure **par compte**, pas par IP. Un cybercafé de Bujumbura fait sortir des dizaines de clients derrière la même adresse : une limite par IP punirait des gens qui n'ont rien fait. Test dédié : le premier compte est bloqué, le second passe.
- **Doublon** — un seul retour par `(utilisateur, ticket, catégorie)`. Un avis et un bug sur le même passage restent possibles : ce ne sont pas les mêmes informations.
- **Confiance** — `ticket_id` doit appartenir à l'appelant (404 et non 403 : répondre « interdit » confirmerait l'existence du ticket), `org_id` doit exister.
- **Écran** — sections dans l'ordre des questions qu'on se pose : mon ticket (voir / reprendre / annuler), 6 questions fréquentes, contact, avis-bug-historique, état du service. La 6e entrée de FAQ est « puis-je prendre deux tickets ? » et non le widget d'accueil : le widget n'existe pas encore, l'annoncer serait un mensonge.
- **Contact** — aucun numéro n'est codé en dur. `TONDE_SUPPORT_WHATSAPP`, `TONDE_SUPPORT_PHONE` et `TONDE_SUPPORT_EMAIL` sont lus à la compilation ; sans eux, l'écran l'écrit noir sur blanc au lieu d'afficher des boutons qui ne mènent nulle part.
- **Champs techniques** — version depuis `kAppVersion` (aligné sur `pubspec.yaml`, pas de `package_info_plus`), plateforme depuis `Platform`, et `device_model` reçoit la version du système (`Android 13 (SDK 33)`) plutôt qu'un modèle commercial : c'est ce que le support peut reproduire, et cela évite une dépendance native de plus.
- **Piège corrigé** — Riverpod 3 relance automatiquement un provider en erreur. Sur un serveur muet, cela laissait un minuteur actif après la fermeture de l'écran (les tests de l'application entière échouaient sur « A Timer is still pending »). `retry` est désactivé sur `serviceReachableProvider` et `myFeedbackProvider` : le tirer-vers-le-bas suffit à réessayer.
- Tests : 10 backend (`test_feedback_service.py`), 8 backend (`test_feedback_schema.py`), 20 mobile (`test/features/assistance/`).

> **Hors périmètre v1 :** écran d'administration des retours dans `tonde-web`. À planifier quand le volume le justifiera.

**Livré le 2026-11-26 — centre d'aide refondu :**

- **Trois portes, dans l'ordre où le client se les pose.** « Contacter mon institution » (le service, la file, mon ticket), « Contacter TONDE » (l'application, mon compte), « Questions fréquentes ». Le contact passe avant la FAQ : quelqu'un qui ouvre cet écran est bloqué maintenant, pas en train de se documenter. La FAQ devient une page dédiée (`/assistance/faq`) — à six entrées dépliées, elle repoussait le contact hors de l'écran.
- **Coordonnées TONDE** — `lib/core/config/tonde_support.dart` : `+257 71 16 57 41` (appel et WhatsApp) et `vitalzagabe156@gmail.com`, disponibles 24 h/24. Ce sont des données **produit**, pas d'environnement : les mettre en `--dart-define` obligeait à reconstruire l'APK pour changer un numéro. Le numéro n'est jamais affiché — seule l'icône téléphone est proposée, comme demandé.
- **Coordonnées par institution** — `organizations.support_whatsapp` et `organizations.support_hours` (migration `022_org_support_contacts`) ; `phone` et `email` existaient déjà et servent de canaux, plutôt que d'être dupliqués. Exposées dans le bloc `support` de `/public/organizations`, avec les horaires en texte libre (« Lun–Ven 8h–16h ») : un modèle de plages structuré n'aurait pas été rempli.
- **La fiche institution se charge à l'ouverture**, pas au rendu de l'onglet. Sans institution rattachée, elle le dit et propose de parcourir les institutions — jamais de bouton mort.
- **Retours** — chaque retour enregistré déclenche un e-mail vers `FEEDBACK_INBOX` (`vitalzagabe156@gmail.com`), avec catégorie, note, message, identité du client et contexte technique ; `Reply-To` pointe sur l'adresse du client. L'envoi est **best-effort après le commit** : un SMTP en panne ne transforme pas un envoi réussi en erreur 500. **Il reste à renseigner `SMTP_HOST`/`SMTP_USER`/`SMTP_PASSWORD`** — sans eux, l'e-mail est seulement journalisé.
- **Après envoi**, le formulaire affiche un écran de remerciement animé au lieu de se fermer d'un coup : un formulaire qui disparaît laisse le doute « est-ce parti ? ».
- **Piège corrigé au passage** — la migration `021_feedback` n'était **jamais passée** : elle créait le type ENUM deux fois (`DuplicateObjectError`) et la table `feedback` n'existait pas en base, donc `POST /feedback` échouait. Corrigée avec `postgresql.ENUM(..., create_type=False)` ; les migrations `021` puis `022` sont appliquées, la base est à `022_org_support_contacts`.

---

### L7 — Gestion d'erreurs enrichie · **2 j**

`mapDioException` extrait déjà le code métier — il manque la **traduction en langage utilisateur**.

| Code serveur | Message | Action proposée |
|---|---|---|
| `TICKET_ALREADY_ACTIVE` | Vous avez déjà un ticket en cours | Voir ma position |
| `BRANCH_CLOSED` / `COUNTER_CLOSED` | Cette agence est fermée | Voir les horaires |
| `SERVICE_INACTIVE` | Ce service est indisponible | Choisir un autre service |
| `DAILY_QUOTA_REACHED` | Limite de tickets atteinte pour aujourd'hui | Réessayer demain |
| `RATE_LIMIT_EXCEEDED` | Trop de tentatives | Patientez X secondes (lit `retry_after`) |
| `GRACE_PERIOD_NOT_ELAPSED` | Attendez la fin du délai | Compte à rebours |
| `MISSED_LIMIT_REACHED` | Reprise impossible | Prendre un nouveau ticket |
| `NETWORK` / `TIMEOUT` | Vous êtes hors ligne, vos données sont conservées | Réessayer |

| # | Tâche | État |
|---|---|---|
| 7.1 | Table centrale code → clé de traduction + action, dans `core/errors/user_message.dart` | livré |
| 7.2 | Identifiant d'incident court (8 caractères) affiché à l'écran et journalisé, pour le support | livré |
| 7.3 | `ErrorView` unifié : icône, message clair, une action principale, un détail technique repliable | livré |
| 7.4 | Journalisation sans donnée sensible (`AppLogInterceptor` existe déjà) | livré |

**Critère :** aucun message technique brut visible par l'usager, sur les trois langues.

**Livré le 2026-11-24 :**

- **`user_message.dart`** — un `switch` sur le code métier, et non une table de 60 entrées : seuls les codes qu'un client peut réellement rencontrer y figurent. Une table exhaustive aurait été de la documentation déguisée en code, que personne ne met à jour.
- **Actions** — `ErrorAction` décrit une *intention* (`retry`, `seePosition`, `chooseService`, `takeNewTicket`, `wait`), pas un bouton. C'est l'appelant qui fournit le comportement, parce que lui seul sait où revenir. Sans gestionnaire, aucun bouton : c'est ce qui a fait écarter « Voir les horaires » de la table du plan — aucun écran n'affiche d'horaires, le bouton aurait été mort.
- **`retry_after`** — `ApiException.retryAfterSeconds` est alimenté depuis le corps (`retry_after`, `retry_after_seconds`) puis l'en-tête `Retry-After`. Le message dit « Patientez 45 secondes » au lieu de « trop de tentatives ».
- **`ErrorView`** — icône selon la nature (réseau / serveur / refus métier), phrase, explication, action, et « Détails techniques » replié portant la référence d'incident, le code et le statut. Replié mais présent : sans lui, un utilisateur qui appelle le support n'a rien d'exploitable à transmettre.
- **`AsyncErrorView`** — 9 écrans migrés d'un coup en ajoutant `error:` à l'appel : accueil, onglet Tickets, organisations, agence, services, page de prise de ticket, suivi. Tous affichaient « impossible de charger » pour un quota atteint ou une agence fermée.
- **Journalisation** — une ligne par affichage, avec la même référence que l'écran : `incident=… type=… code=… status=…`. Ni jeton, ni corps de requête, ni message serveur (il peut recopier une saisie).
- Tests : 18 (`test/core/user_message_test.dart`) + 5 (`test/core/error_view_test.dart`).

---

### L8 — Responsive multi-appareils · **4 j**

**Constat :** zéro `MediaQuery`, zéro `LayoutBuilder` dans `lib/`. Le cas réel observé (§1.1) est un téléphone de **320 dp** sur lequel la barre de navigation coupe « Notifications » et « Assistance » au milieu du mot.

| # | Tâche | Détail | État |
|---|---|---|---|
| 8.1 | `AppBreakpoints` | compact < 360 dp · standard 360-600 · medium 600-900 · expanded > 900 | livré |
| 8.2 | **Barre de navigation** · **livré le 2026-11-22** | `TondeNavigationBar` maison remplace `NavigationBar` : `FittedBox` par libellé, donc mot entier garanti à toute largeur. Le libellé « Notifications » est **conservé** (le renommer en « Alertes » avait été écarté). `NavigationRail` en medium/expanded et en paysage : livré le 2026-11-24 | livré |
| 8.3 | `ResponsiveCenter` | Largeur de contenu maximale 560 dp, centrée sur grand écran | livré |
| 8.4 | Grilles adaptatives | Organisations 1 / 2 / 3 colonnes selon la largeur | livré |
| 8.5 | Facteur de police | Plafond à 1,3 (le système peut monter à 2,0 et casse toutes les rangées) + `maxLines`/`overflow` sur les libellés critiques | livré |
| 8.6 | Suppression des redondances | Un seul CTA « Prendre un ticket » (L5.1) ; un seul badge de notifications | livré |
| 8.7 | Tests golden | 320×640, 360×800, 412×915, 800×1280, 1280×800 — portrait et paysage, police à 100 % et 200 % | remplacé par des assertions structurelles (voir plus bas) |

**Note sur 8.2 —** `NavigationDestination.label` est une `String` rendue dans la largeur d'un cinquième d'écran, sans réduction ni `maxLines` possible : aucun réglage de `NavigationBar` ne peut faire tenir « Notifications » en 320 dp. D'où le composant maison, qui conserve l'apparence Material 3 (pastille du parent sélectionné, encrage) et la sémantique lecteur d'écran. Test : `test/features/dashboard/navigation_bar_test.dart`, en français, à 320 dp.

**Critère :** aucun libellé coupé au milieu d'un mot, aucun `RenderFlex overflowed`, sur les 5 tailles et dans les 3 langues.

**Livré le 2026-11-24 :**

- **`core/layout/app_breakpoints.dart`** — quatre classes, pas cinq : au-delà de 900 dp la mise en page ne change plus, elle s'élargit. Les seuils sont écrits une seule fois ; un `MediaQuery…width > 600` recopié à deux endroits finit toujours par diverger, et la moitié de l'écran change de disposition avant l'autre.
- **`NavigationRail`** — dès 600 dp, dans `DashboardShell`. Le bandeau hors-ligne reste sous le contenu, pas sous le rail. `TondeNavigationBar` reste pour les téléphones : c'est elle qui garantit un mot entier à 320 dp.
- **`core/layout/responsive_center.dart`** — plafond à 560 dp. Au-delà d'environ 70 caractères par ligne, l'œil perd le début de la ligne suivante.
- **`core/layout/text_scale.dart`** — plafond à 1,3, appliqué par le `builder` de `MaterialApp` : un seul endroit, donc aucun écran ne peut l'oublier. À 2,0 les rangées de la carte de ticket débordent, et le texte devient moins lisible qu'à taille normale — l'inverse du but.
- **Grille des organisations** — 1 / 2 / 3 colonnes. Sur téléphone la liste est conservée (hauteur libre, donc un nom sur deux lignes ne déborde pas) ; en grille, `mainAxisExtent: 96` et `maxLines: 1` + ellipsis sur le titre et le sous-titre.
- **8.7 — remplacé, et pourquoi.** Des tests golden auraient comparé des images rendues à des références figées : illisibles en revue de code (personne ne voit qu'un pixel a bougé pour une bonne raison), et cassants au moindre changement de police ou de version de Flutter. `test/core/layout_test.dart` vérifie ce qui compte réellement : les seuils, la présence du rail à 1024 dp, son absence à 360 dp, le libellé « Notifications » entier, le plafond de police et la largeur maximale du contenu. C'est plus fragile à écrire, mais un échec y dit *quoi* est cassé.

---

## 4. Ce que le backend doit fournir

| # | Livrable | Effort | Existant ? |
|---|---|---|---|
| B1 | Payload FCM enrichi (`channel_id`, `icon`, `sound`, `vibrate`, `click_action`) | 0,5 j | Payload minimal actuel |
| B1bis | Multi-appareils (`user_devices` au lieu de `User.fcm_token`) | 1 j | **Livré** 26/11 |
| B2 | Table `feedback` + `POST /feedback` + `GET /feedback/mine` | 1,5 j | Non |
| B3 | Vérifier que `GET /tickets/active` renvoie bien `status`, `recovery_expires_at`, `missed_count` | 0 j | **Oui** |
| B4 | `POST /tickets/{id}/return` | 0 j | **Oui** |
| B5 | `paused_counters` dans le snapshot | 0 j | **Oui** |

**Total backend : ~3 j.** Aucune modification du moteur de file n'est nécessaire.

**B1bis — livré le 2026-11-26.** `user_devices` (migration `023`) : `user_id`, `token` unique, `platform`, `device_model`, `app_version`, `last_seen_at`. `PUT /auth/me/fcm-token` accepte désormais `platform`, `device_model`, `app_version` et `device_token` ; à la déconnexion, le mobile envoie le jeton de **cet** appareil, ce qui permet de n'en retirer qu'un. Un jeton déjà connu d'un autre compte est déplacé, jamais dupliqué — sur un téléphone partagé, les appels d'un client ne doivent pas arriver chez un autre. `_send_fcm` itère sur tous les appareils : un jeton invalide est supprimé sans priver les autres de l'alerte, et une seule ligne d'audit est écrite par envoi (le support veut savoir si l'alerte est partie, pas combien de téléphones le client possède).

---

## 5. Ordre de livraison

```
L0 (3 j) ──┬─→ L1 (2 j) ──────────────→ L7 (2 j)
           ├─→ L2 (5-6 j) ──→ L3 (2 j)
           ├─→ L4 (6-8 j)
           └─→ L5 (4 j)
L8 (4 j) et L6 (4 j) : parallélisables à tout moment
```

| Étape | Contenu | Effort | Valeur livrée |
|---|---|---:|---|
| **1** | L0 + L1 | 5 j | Démarrage propre : plus de clignotement de connexion, splash avec logo |
| **2** | L2 + L3 + B1 | 8 j | **Le client est prévenu de son tour, app fermée.** C'est le cœur du produit |
| **3** | L5 + L7 | 6 j | App dynamique : CTA contextuel, reprise après absence, erreurs utiles |
| **4** | L4 | 7 j | Widget d'accueil avec countdown |
| **5** | L6 + L8 + B2 | 8 j | Assistance réelle, responsive, retours utilisateurs |

**Total : ~34 j/homme**, soit environ 7 semaines à temps plein, ou 9 à 10 semaines à mi-temps. Les étapes 1 à 3 (19 j) suffisent à un pilote crédible.

---

## 6. Qualité

| Garde-fou | Quand |
|---|---|
| `flutter analyze` + `flutter test` sur chaque PR | **En place depuis le 2026-11-25** — `.github/workflows/mobile-ci.yml` |
| Tests unitaires du domaine ticket (statuts, transitions, expiration) | L0 |
| Test widget « session en cache → pas de login » | L1.1 |
| Test du veilleur de notifications par statut | L3 |
| Tests golden responsive (5 tailles) | L8 |
| Test manuel sur 3 appareils réels minimum (petit, moyen, tablette) | Avant chaque étape |

**Dette à traiter au passage :** le test instable observé lors de l'audit (170/171 puis 171/171) doit être isolé avant d'activer la CI, sinon elle sera rouge par intermittence.

**État au 2026-11-25 —** l'instabilité ne s'est pas laissé reproduire : une exécution complète a échoué une fois (`301 passés, 1 échec`) sans que la sortie ait été conservée, et une autre s'est bloquée dans le `tearDownAll` du fichier de notifications alors que la suite backend tournait en parallèle sur la même machine (fichier relancé seul : moins d'une seconde, 10/10). Deux exécutions complètes consécutives, sans autre processus, passent à **302/302**. Conclusion pratique : ce n'était pas un test fautif mais la machine saturée (deux suites + Gradle sur 16 Go, et un disque D: arrivé à 0 octet libre). La CI tourne sur un runner dédié ; si un échec apparaît, son journal nommera le test, ce que les exécutions locales tronquées n'ont pas permis. En cas de récidive locale : `flutter test --concurrency=2`.

---

## 7. Risques

| Risque | Impact | Mitigation |
|---|---|---|
| Firebase non configuré (pas de projet, pas de `google-services.json`) | Bloque L2 et L4 | **À faire avant l'étape 2** : création du projet, package `app.tonde`, empreintes SHA-1 |
| Comportement des fabricants (Xiaomi, Huawei, Oppo) qui tuent les services | Push et widget ne se mettent pas à jour | Tester sur au moins un appareil chinois ; documenter l'exception d'optimisation batterie |
| `requestPinAppWidget` non supporté par certains launchers | Pas de dialogue d'épinglage | Repli sur les instructions manuelles (L4.5) |
| Icône monochrome mal rendue | Carré blanc au lieu du logo | Vérifier `ic_stat_tonde` sur Android 8, 12 et 14 |
| Refonte du domaine ticket (L0) casse les 171 tests | Retard en cascade | L0 isolé dans une PR dédiée, avant tout le reste |
| Widget et app désynchronisés | Position fausse à l'accueil | Une seule source : l'état poussé par l'app à chaque événement, jamais recalculé par le widget |
| Fichier son non disponible au moment de L3 | Bloque la validation du critère | Développer avec un fichier provisoire ; le remplacement ne touche aucune ligne de code (chemin fixe `assets/sounds/ticket_called.mp3`) |

---

## 8. Questions ouvertes

1. **Libellés de navigation** — je propose « Accueil · Tickets · Alertes · Aide · Plus ». « Alertes » plutôt que « Notifications » est le seul changement de sens : il tient à 320 dp et reste clair. Tu valides, ou tu préfères garder « Notifications » avec un libellé masqué par défaut ?
2. **iOS** — le widget et le push iOS sont-ils dans le périmètre, ou Android seulement pour le pilote ?
3. **Contact du support** — quel canal afficher dans Assistance : WhatsApp, numéro de téléphone, e-mail ? Lequel est réellement surveillé ?
4. **Retours utilisateurs** — qui les lit ? Faut-il une notification interne (e-mail ou dashboard) à chaque nouveau retour ?
5. **Widget** — afficher aussi le QR code du ticket sur le widget (pratique au guichet, mais consomme de la place) ?
6. **Son** — tu fournis le fichier. Dis-moi quand il sera prêt et je branche l'intégration ; en attendant, L3 peut être développée avec un fichier de test provisoire, remplacé ensuite sans changer une ligne de code.
