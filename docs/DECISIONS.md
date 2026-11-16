# Registre des décisions et arbitrages

Ce fichier empêche les agents de transformer les incohérences des anciens documents en choix techniques silencieux.

## Décisions de travail retenues

| Sujet | Règle de travail | Justification |
|---|---|---|
| Framework | Flutter / Dart | Décision constante dans les documents TONDE |
| State management | Riverpod uniquement | Guide d'initialisation et fichier d'orientation IA; l'architecture système cite BLoC, et la roadmap mentionne « Bloc/Riverpod » |
| Navigation | GoRouter | Guide d'initialisation et orientation IA |
| HTTP | Dio | Guide d'initialisation et orientation IA |
| Langues initiales | Français, Kirundi (`rn`), Anglais (`en`) | Documents produit et guide d'initialisation |
| Couleurs UI | Bleu `#2563EB`, slate `#1E293B` | Rapport UI/UX stratégique |
| Source de vérité métier | Backend | Architecture système |
| Ticket actif | Un seul globalement par utilisateur | Décision métier confirmée dans le contexte projet; toute validation backend reste nécessaire |

## Arbitrages à ne pas inventer

### Stockage offline : Hive ou Drift/SQLite
- Le guide d'initialisation et la roadmap citent Hive.
- Le document d'architecture système justifie Drift/SQLite.
- Ces choix ne doivent pas coexister dans le même projet sans besoin démontré.
- Règle temporaire : ne pas ajouter de base locale métier avant d'avoir défini les données à conserver, les besoins transactionnels et le protocole de synchronisation. Les tokens restent dans `flutter_secure_storage`.
- Décision à prendre avec Vizane avant la première feature offline persistante.

### Architecture de couches : Clean Architecture/BLoC ou Feature-First/Riverpod
- Le document d'architecture système mentionne Clean Architecture avec BLoC.
- Le guide d'initialisation et le fichier d'orientation IA indiquent Feature-First et Riverpod.
- Règle de travail : Feature-First + séparation data/domain/presentation pragmatique + Riverpod. Ne pas introduire BLoC.

### Authentification et périmètre MVP
- Les documents détaillent OTP SMS, email, OAuth et PIN, mais la roadmap 90 jours décrit un mobile MVP centré sur prise de ticket, suivi, notifications et offline.
- Ne pas construire tous les fournisseurs d'authentification sans contrat backend et validation du parcours pilote.
- Commencer par les contrats d'auth réellement exposés par le backend et le parcours choisi par le produit.

### Contrats API et WebSocket
- Les documents historiques présentent des exemples et des endpoints, mais ils ne prouvent pas que le backend actuel les expose.
- Source autoritaire : OpenAPI et documentation du backend actuel, validées par l'équipe backend.
- En l'absence de contrat, créer une interface de domaine et marquer l'intégration comme bloquée. Ne pas fabriquer de JSON d'exemple en production.

### Format d'erreur API
- Les documents ne sont pas parfaitement cohérents sur `error` et `detail`.
- Utiliser le schéma réellement exposé par le backend actuel. Ne pas figer un parser sur une hypothèse.

### Configuration d'environnement via `--dart-define`
- Contexte : l'architecture impose une base URL par environnement fournie par configuration non secrète, alors qu'aucun contrat backend n'existait au moment du Lot 2.
- Options étudiées : fichier `.env` avec dépendance tierce ; `--dart-define` natif ; valeurs codées en dur (rejetée : URLs dans le dépôt).
- Décision : `--dart-define` natif (`TONDE_ENVIRONMENT`, `TONDE_API_BASE_URL`, `TONDE_HTTP_LOGGING`), aucune dépendance, aucune valeur dans le dépôt. URL `https` obligatoire, `http` uniquement vers `localhost`/`127.0.0.1`.
- Conséquences : les valeurs sont figées à la compilation ; changer d'environnement exige une recompilation, acceptable pour le MVP.
- Date : 2026-11-09. Approbateur : à valider par Vizane.

### Stockage des tokens
- Contexte : les exigences de sécurité imposent de minimiser la persistance des secrets et de traiter proprement expiration/révocation.
- Options étudiées : persister access + refresh tokens dans le stockage sécurisé ; access token en mémoire uniquement et refresh token dans `flutter_secure_storage` (retenue).
- Décision : l'access token vit uniquement en mémoire ; seul le refresh token est persisté, dans `flutter_secure_storage` sous la clé `refresh_token`. Après redémarrage, la session est récupérée via le refresh token (mécanisme single-flight à implémenter).
- Conséquences : aucun access token sur disque ; un redémarrage impose un refresh, et tout échec définitif efface la session et ramène à l'état non authentifié.
- Date : 2026-11-09. Approbateur : exigence de sécurité du commanditaire.

### Phase 2, premier lot : découverte des organisations sans contrat backend
- Contexte : le master prompt exige de choisir avec Vizane une seule feature verticale pour la Phase 2 et de n'entamer l'intégration qu'après réception du contrat backend. Aucun contrat n'est encore fourni.
- Options étudiées : découverte des organisations ; session/auth ; tickets ; attendre le contrat sans rien coder.
- Décision : feature unique retenue — découverte des organisations (choix Vizane du 2026-11-09). En l'absence de contrat : entité minimale `Organization` (id, name) fondée sur les invariants documentés, interface `OrganizationRepository`, implémentation `BlockedOrganizationRepository` qui lève `IntegrationBlockedException`, et provider d'injection. Aucun endpoint, payload ou champ non documenté n'est introduit.
- Conséquences : la présentation et l'implémentation Dio viendront après réception du contrat (OpenAPI/documentation validée) ; toute évolution de l'entité suivra ce contrat.
- Date : 2026-11-09. Approbateur : Vizane.

## Processus de modification
Toute nouvelle décision doit être ajoutée ici avec : contexte, options étudiées, décision, conséquences, date et approbateur. Les décisions touchant invariants métier, sécurité, stack ou contrats inter-apps exigent validation de Vizane.

### Phase 2, démo : données fictives en mémoire sans contrat backend
- Contexte : le master prompt interdit les faux écrans, faux utilisateurs et faux endpoints, et impose d'attendre le contrat backend. Vizane a explicitement demandé le 2026-11-09 de ne plus attendre : « go pour la phase 2. n'attend pas le backend, utilise le mock, les donnees fictives. c'est un demo que nous allons presenter ».
- Options étudiées : rester bloqué sans écran ; inventer des endpoints HTTP (rejetée : viole l'interdiction d'inventer un contrat) ; données fictives en mémoire derrière l'interface de repository existante (retenue).
- Décision : dérogation approuvée par Vizane pour la démo. `MockOrganizationRepository` retourne des organisations et agences fictives entièrement en mémoire, sans aucun endpoint, payload, statut ou événement inventé. L'intégration réelle (Dio) reste à écrire dès réception du contrat backend ; le remplacement se fera uniquement au niveau du provider, sans toucher domaine ni présentation. Noms d'établissements volontairement fictifs (aucune institution réelle citée). Traductions kirundi toujours provisoires.
- Conséquences : les écrans de découverte sont démontrables sur téléphone ; le risque de « faux écran fonctionnel » est contenu (aucune donnée présentée comme réelle, aucune logique de ticket inventée). Le mock devra être retiré avant toute connexion au backend réel.
- Date : 2026-11-09. Approbateur : Vizane.

### Phase 2, démo : extension du mock au parcours de ticket
- Contexte : dans la même dérogation démo (2026-11-09), Vizane a demandé d'afficher à droite de chaque agence uniquement le nombre de personnes ayant déjà pris un ticket, puis de permettre de cliquer une agence pour prendre un ticket : « le design reste le meme mais a cote droit de chaque agence tu dois montre seulement les nombres des personnes qui ont deja pris le ticket, puis la personne peut cliquer dans une agence pour aller prendre un ticket ».
- Options étudiées : ne rien faire en attendant le contrat backend (rejetée : démo à présenter) ; inventer un endpoint de file d'attente (rejetée : interdiction d'inventer un contrat) ; étendre le mock en mémoire existant au domaine ticket (retenue).
- Décision : le mock en mémoire est étendu au parcours ticket, toujours sans endpoint, payload ou statut inventé. `Agency.waitingCount` (compteur de file, fourni par le mock) est affiché en badge à droite de chaque agence ; `MockTicketService` attribue un numéro de ticket fictif et simule en mémoire l'invariant « un seul ticket actif par utilisateur » (`TicketAlreadyActiveException`). L'UI affiche alors un écran de conflit qui renvoie vers le ticket actif — elle ne décide jamais elle-même, elle présente l'état simulé. Le point de remplacement reste le provider uniquement ; ce mock sera retiré avant toute connexion au backend réel (Phase 3, contrat validé requis).
- Conséquences : le parcours complet (compteurs → prise de ticket → ticket actif → conflit) est démontrable sur téléphone ; aucune donnée n'est présentée comme réelle et aucun contrat backend n'est prétendu. Le nombre de personnes en file viendra du backend réel dès que son contrat sera disponible.
- Date : 2026-11-09. Approbateur : Vizane.

### Phase 2, démo : extension du mock à l'authentification et au tableau de bord
- Contexte : Vizane a demandé (2026-11-09) des pages de connexion et d'inscription puis un tableau de bord conforme à sa maquette après connexion : « TU peux creer la page de connexion et de s'inscrire. puis quand on va se connecter on arriver sur un tableau de bord qui est comme ca… voici l'exemple du nom utilisateurs a utiliser : kanani jospin, mots de passe : 12345 ». Il a également demandé de ne pas compiler ce lot (compilation par ses soins ensuite).
- Options étudiées : attendre le contrat d'authentification backend (rejetée : démo à présenter) ; inventer un endpoint de login (rejetée : interdiction d'inventer un contrat) ; étendre le mock en mémoire au domaine auth (retenue).
- Décision : `MockAuthService` simule en mémoire une session utilisateur avec les identifiants de démonstration `jospin kanani` / `12345` (donnés par Vizane, corrigés par lui le 2026-11-10 : il avait d'abord écrit `kanani jospin`) ; l'inscription accepte tout compte non pris et ouvre une session. Aucun endpoint, payload, jeton ou mécanisme de sécurité n'est prétendu : ce service est un faux à usage strictement démonstratif, derrière l'interface `AuthService` existante. La porte d'authentification est réalisée côté client par une redirection GoRouter (`redirect` lisant `authControllerProvider`) : elle ne constitue pas une sécurité réelle et sera remplacée par le flux backend dès réception de son contrat (Phase 3). Les règles de file (position, ETA…) restent au backend : l'UI du tableau de bord affiche uniquement l'état du ticket actif ; l'estimation de temps vient du mock (`Ticket.estimatedMinutes`), jamais d'un calcul dans un widget.
- Conséquences : parcours démontrable complet (connexion → tableau de bord à 5 onglets → déconnexion) ; les identifiants de démo ne doivent jamais être présentés comme un vrai système d'authentification ; le mock sera retiré avant toute connexion au backend réel.
- Date : 2026-11-09. Approbateur : Vizane (demande explicite, validée en session).

### Lot 13, démo : sphère ASCII animée dans le hero et menu « Plus » réduit
- Contexte : Vizane a demandé (2026-11-11) de retirer les entrées « Mon profil » et « À propos » de l'onglet Plus pour ne laisser que « Se déconnecter », et d'afficher dans le hero de l'accueil la sphère ASCII animée décrite par sa spécification (projection orthographique, tri par profondeur, couleur violet→cyan).
- Options étudiées : reprendre la spécification à l'identique (sphère 300×300, opacité 0.5) — rejetée sur mobile car elle couvre 90 % d'une carte de 328 px et rend le titre illisible ; adapter taille et opacité au contexte mobile (retenue).
- Décision : `AnimatedSphereWidget` implémente l'algorithme de la spécification (grille phi/theta pas 0.15, rotations Y puis X, projection orthographique, `radius = min(w,h) * 0.52`, tri Z croissant, interpolation de couleur et d'opacité selon la profondeur). Deux écarts assumés : la sphère est rendue en 200×200 à l'opacité 0.55 (au lieu de 300×300 / 0.5) pour rester une décoration de coin sur un écran de 360 px ; les `TextPainter` sont précalculés par couple (caractère, palier de profondeur) au lieu d'être créés à chaque image, le rendu restant identique. L'animation est coupée quand l'onglet Accueil n'est plus affiché (`TickerMode`) et peut être figée globalement pour les tests (`AnimatedSphereWidget.animationsEnabled`), sans quoi `pumpAndSettle` ne retombe jamais au repos.
- Écarts de la spécification signalés, non corrigés d'office : la liste de caractères annoncée « 19 » n'en contient que 18 (index borné à la longueur réelle) ; la prose annonce le violet à l'avant alors que la formule d'interpolation « exacte » place le cyan à l'avant — c'est la formule qui est implémentée.
- Conséquences : le hero est animé en démo ; la décoration reste purement visuelle et sans impact sur les invariants métier. Le coût de rendu (~880 caractères par image) devra être mesuré sur appareil d'entrée de gamme ; le pas de la grille (0.15 → 0.20) est le levier prévu par la spécification.
- Date : 2026-11-11. Approbateur : à valider par Vizane.

### Lot 14, démo : écran de suivi temps réel de la file

- Contexte : Vizane a demandé (2026-11-13) l'écran cœur de l'expérience TONDE — suivi live du ticket (numéro appelé, rang, ETA, QR code, badges de statut) avec WebSocket et repli HTTP. Le bouton « Voir ma position » ne faisait jusqu'ici que rouvrir la page de l'agence.
- Contrainte : aucun contrat backend n'existe. `docs/DECISIONS.md` interdit de figer un parser sur une hypothèse et de fabriquer des payloads de production.
- Options étudiées : (a) implémenter directement le WebSocket contre l'URL fournie — rejetée, l'écran serait vide et non testable en démo ; (b) écran purement fictif — rejetée, aucun moteur réutilisable ; (c) interface de domaine + deux implémentations interchangeables derrière un point de bascule unique (retenue).
- Décision : la feature `tracking` expose `QueueTrackingService` (flux froid, un abonnement = une connexion). Deux implémentations :
  - `MockQueueTrackingService`, active tant qu'aucune base URL n'est fournie : rejoue une file qui avance d'une place toutes les 3 s, conserve sa progression par numéro de ticket, produit un QR de démonstration explicitement marqué `sig=DEMO`.
  - `WebSocketQueueTrackingService`, active dès que `TONDE_API_BASE_URL` est renseignée : ouvre `wss://<api>/ws/queue/{ticket}`, et bascule automatiquement sur un polling `GET /queue/{ticket}` toutes les 30 s en cas de rupture, en retentant le WebSocket tous les 4 cycles. La source (`Direct` / `Mode secours`) est affichée à l'utilisateur.
- Écarts assumés par rapport à la demande initiale :
  - L'URL fournie était `ws://api.tonde.app/...` ; le schéma est **dérivé** de la configuration (`https` → `wss`), pour ne jamais transmettre de jeton en clair. Un `ws://` littéral en production serait un défaut de sécurité.
  - Le QR code n'est **jamais signé par le mobile** : il affiche la charge utile reçue du backend. En démo, `MockQueueTrackingService` fabrique un payload marqué `DEMO`, qui ne doit pas être accepté par un guichet.
  - Les chemins `/ws/queue/{ticket}` et `/queue/{ticket}` restent **provisoires** et isolés dans `WebSocketQueueTrackingService` : c'est le seul fichier à ajuster à réception du contrat.
- Conséquences : deux dépendances ajoutées (`web_socket_channel` 3.0.3, `qr_flutter` 4.1.0). `Ticket` devient un objet-valeur (`==`/`hashCode`) car il sert de clé de famille Riverpod. Le badge « Appelé » pulse ; comme la sphère du hero, son animation est figée dans `test/flutter_test_config.dart` pour que `pumpAndSettle` aboutisse.
- Date : 2026-11-13. Approbateur : à valider par Vizane.

### Lot 15, démo : stratégie hors ligne (cache local + bandeau)

- Contexte : Vizane a demandé (2026-11-13) que l'application ne montre **jamais** d'écran d'erreur réseau pour une action critique, affiche un indicateur discret quand le réseau manque, et conserve le ticket actif, l'historique et les agences en local pour une consultation sans 3G/4G.
- Contrainte : le backend n'existe toujours pas. `docs/DECISIONS.md` interdit d'inventer un contrat ; le cache doit donc être un décorateur autour des services actuels, remplaçable sans toucher à l'UI.
- Options étudiées :
  - `shared_preferences` — rejetée : stockage clé/valeur plat, inadapté à des documents structurés et sans lecture partielle.
  - Isar — rejetée : bibliothèque native + génération de code + poids de build pour trois documents de quelques centaines d'octets.
  - Hive avec des valeurs JSON encodées en chaînes — retenue : persistance disque réelle, aucun adaptateur généré, format inspectable, migration de schéma sans régénération.
- Décision :
  - `core/offline/local_cache.dart` expose `LocalCache` (écriture/lecture de documents JSON) avec deux implémentations : `HiveLocalCache` (une boîte `tonde_cache`) et `MemoryLocalCache` (tests et aperçus). `main()` ouvre le cache **avant** le premier écran et surcharge `localCacheProvider` ; si l'ouverture échoue, l'incident est remonté via `FlutterError.reportError` et l'application démarre sur le cache mémoire plutôt que de refuser de se lancer.
  - `CachedTicketService` et `CachedOrganizationRepository` enveloppent les services existants. Règle unique : le réseau fait foi **quand il répond**, le cache prend le relais sinon. Un ticket pris hors ligne est enregistré localement avec un numéro préfixé `L-` et le drapeau `pendingSync`, puis rejoué automatiquement au retour du réseau (`TicketNotifier` écoute `isOnlineProvider`).
  - Interface : bandeau fin au-dessus de la barre de navigation, en trois états (réseau absent / action en attente / rien). Volontairement ambre et non rouge : ce n'est pas une erreur, c'est un mode de fonctionnement.
- Écarts assumés par rapport à la demande :
  - **L'historique n'est pas mis en cache** : l'application n'a encore aucun modèle d'historique ni écran associé. Cacher une liste que personne ne lit aurait été du code mort ; le point reste ouvert et sera traité avec le contrat backend.
  - **Un ticket pris hors ligne n'est pas un vrai ticket** : il porte un numéro `L-` local qui ne doit jamais être présenté au guichet, et son suivi temps réel est remplacé par un écran d'attente de synchronisation (ouvrir le WebSocket sur un numéro inconnu du serveur produirait précisément l'erreur réseau que l'exigence interdit).
  - **La connectivité est optimiste au démarrage** : tant que la première mesure n'est pas arrivée, l'application se considère en ligne. L'inverse afficherait un bandeau hors ligne pendant la restauration de session, pour un réseau simplement pas encore testé.
  - **Le mock de tickets simule désormais un serveur qui se souvient.** Il conservait son ticket en mémoire : au redémarrage avec réseau, il répondait « aucun ticket actif », le mobile effaçait donc son cache, et le ticket disparaissait. `MockTicketService` accepte maintenant un `LocalCache` et persiste son état sous une clé distincte (`mock.activeTicket`) de celle du cache d'affichage (`ticket.active`) : les deux couches restent séparées, comme le seront le backend et le cache réel.
  - **La session de démonstration est désormais persistée.** Le mock d'authentification conservait la session en mémoire uniquement (décision du 2026-11-09) : après une relance, l'utilisateur retombait sur l'écran de connexion et ne pouvait plus voir son ticket, ce qui vidait l'exigence hors ligne de son sens. `MockAuthService` accepte maintenant un `LocalCache` et restaure le profil sous la clé `session.user` ; la déconnexion efface cette clé. Sans cache injecté (tests, aperçus), le comportement en mémoire est inchangé. Le flux backend réel gardera son propre mécanisme (refresh token dans `flutter_secure_storage`), qui n'est pas modifié.
  - **Le cache n'est pas chiffré.** Il ne contient ni jeton ni mot de passe (ils restent dans `flutter_secure_storage`), seulement le ticket actif et le catalogue des agences. À revoir si le backend renvoie des champs sensibles.
- Conséquences : deux dépendances ajoutées (`hive` 2.2.3, `hive_flutter` 1.1.0). `Ticket` porte `pendingSync`, qui entre dans l'égalité par valeur : un ticket en attente et sa version confirmée sont deux objets distincts, donc deux abonnements de suivi distincts — c'est voulu. Une entrée de cache illisible est traitée comme absente, jamais comme une erreur bloquante.
- Date : 2026-11-13. Approbateur : à valider par Vizane.

### Lot 16, démo : page profil accessible et préférences d'affichage

- Contexte : depuis le Lot 13, l'onglet Plus ne contenait plus que « Se déconnecter » et les informations du compte n'étaient plus atteignables. Vizane a demandé (2026-11-13) de rendre le profil accessible et d'ajouter le choix de la langue et du thème pour la démo.
- Contrainte : le kirundi (`rn`) n'est couvert ni par `GlobalMaterialLocalizations` ni par `GlobalCupertinoLocalizations`. Choisir cette langue sans délégué dédié fait lever une exception à la première feuille modale ou boîte de dialogue.
- Options étudiées :
  - garder les informations du compte dans l'onglet Plus — rejetée : l'onglet doit rester un menu de réglages, pas une fiche ;
  - écrire un jeu complet de libellés Material en kirundi — rejetée : des centaines de chaînes hors périmètre, sans relecteur linguistique ;
  - réutiliser les libellés Material/Cupertino français pour `rn` — retenue : le français est langue d'administration au Burundi, et les textes métier de l'application restent en kirundi ;
  - persister les préférences côté serveur — rejetée : ce sont des préférences d'appareil, elles doivent s'appliquer sans réseau et avant toute session.
- Décision :
  - `MoreTab` devient un menu : tuile de compte réduite à l'icône de l'utilisateur (aucun nom, aucun `@username` affiché), section « Préférences » (langue, apparence, à propos), puis déconnexion. Un clic sur l'icône ouvre `/profil`, qui porte toutes les informations (nom, `@username`, e-mail, téléphone, rôle, organisation). L'onglet Plus ne montre donc aucune donnée personnelle, ce qui le rend présentable sur un téléphone partagé ; la tuile reste annoncée « Mon profil » aux lecteurs d'écran via `Semantics`.
  - `core/settings/settings_providers.dart` : `themeModeProvider` et `localeProvider`, persistés dans le cache local (`settings.theme`, `settings.locale`) et non dans le stockage sécurisé — ce ne sont pas des secrets. La restauration est asynchrone : le premier rendu part du thème et de la langue du système, puis la préférence s'applique. `locale == null` signifie « suivre le téléphone ».
  - `settings_sheets.dart` : feuilles modales de choix (langue, thème) et fenêtre « À propos ». Les langues sont nommées dans leur propre langue (endonymes) pour rester reconnaissables quelle que soit la langue courante. La feuille de langue propose « Système » en plus de fr/rn/en : sans cette entrée, un choix explicite serait définitif.
  - `app/l10n/kirundi_localizations.dart` : deux délégués qui délèguent aux implémentations françaises pour `rn`.
- Écarts assumés :
  - « À propos » est une boîte de dialogue Material (`showAboutDialog`), pas une page : elle donne version, description et accès aux licences, sans nouvel écran à maintenir.
  - Le libellé de la langue affiché dans le menu est celui réellement appliqué (préférence ou résolution système), pas la valeur brute du provider.
  - La préférence de langue ne modifie pas `supportedLocales` : fr, rn et en restent les seules langues de l'application.
- Conséquences : aucune dépendance ajoutée (`flutter_localizations` était déjà déclarée). Le kirundi hérite des libellés Material/Cupertino français, ce qui est visible dans les feuilles et dialogues ; à remplacer par une traduction kirundi dédiée si un relecteur est disponible. Les tests couvrent la navigation vers le profil, le changement de langue (y compris retour au système), le changement de thème et la restauration après redémarrage. Défaut d'affichage connu : sur une largeur de 360 dp, le libellé « Notifications » de la barre de navigation passe sur deux lignes.
- Date : 2026-11-13. Approbateur : à valider par Vizane.
