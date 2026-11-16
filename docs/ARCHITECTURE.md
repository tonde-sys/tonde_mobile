# Architecture cible - TONDE Mobile

## Principes
- Feature-First, Clean Architecture pragmatique.
- Dépendances orientées vers le domaine; la présentation ne dépend pas directement de Dio, du stockage ou du SDK Firebase.
- Le backend est propriétaire des règles métier et des états autorisés.
- La synchronisation offline ne doit jamais inventer une confirmation de ticket.

## Structure cible

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router/
│   └── theme/
├── core/
│   ├── config/
│   ├── errors/
│   ├── logging/
│   ├── network/
│   ├── security/
│   ├── storage/
│   ├── connectivity/
│   └── utils/
├── features/
│   ├── authentication/
│   ├── organizations/
│   ├── discovery/
│   ├── tickets/
│   ├── queue_tracking/
│   ├── notifications/
│   └── profile/
└── l10n/

test/
├── core/
├── features/
└── integration/
```

N'ajoute un domaine que lorsqu'il a un cas d'usage MVP concret. Dans chaque feature réellement développée :

```text
feature_name/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── controllers/   # Notifier/AsyncNotifier Riverpod
    ├── pages/
    └── widgets/
```

Évite de créer une classe UseCase pour chaque getter trivial. La séparation doit protéger les règles et permettre les tests, pas multiplier le boilerplate.

## Gestion d'état
Riverpod est le mécanisme unique de gestion d'état et d'injection. Préférer `Provider`, `FutureProvider`, `StreamProvider`, `Notifier` ou `AsyncNotifier` selon le besoin. Les widgets restent minces et ne contiennent pas de logique métier.

## Navigation
GoRouter. Les guards de navigation améliorent l'expérience mais ne remplacent jamais l'autorisation backend. Les redirections doivent gérer chargement de session, session expirée et deep links sans boucle.

## Configuration d'environnement
- Configuration non secrète via `--dart-define` au moment de la compilation (voir `lib/core/config/`) :
  - `TONDE_ENVIRONMENT` : `dev` (défaut), `staging` ou `prod`.
  - `TONDE_API_BASE_URL` : base URL de l'API, optionnelle. Sans valeur, l'application reste non connectée au backend. Schéma `https` obligatoire ; `http` toléré uniquement vers `localhost`/`127.0.0.1`.
  - `TONDE_HTTP_LOGGING` : `true`/`false` (défaut `false`), journalisation des requêtes en développement.
- Aucun secret dans ces définitions ni dans le dépôt.
- Exemple : `flutter run --dart-define=TONDE_ENVIRONMENT=staging --dart-define=TONDE_API_BASE_URL=https://api.example.com`

## Réseau
- Dio centralisé avec timeouts raisonnables, interceptors testables et parsing strict.
- Base URL par environnement, fournie par configuration non secrète.
- Un seul endroit pour traduire les erreurs HTTP en erreurs applicatives.
- Refresh token : mécanisme single-flight pour éviter plusieurs refresh simultanés; sur échec définitif, effacer la session sécurisée et revenir à l'état non authentifié.
- Manifest Android : permissions `INTERNET` et `ACCESS_NETWORK_STATE` dans le manifest principal ; aucune permission runtime supplémentaire au socle.
- Ne jamais réessayer automatiquement une requête mutante non idempotente sans clé d'idempotence ou contrat serveur explicite.
- Pas d'URL d'API ou de payload inventé : les contrats doivent venir du backend/OpenAPI validé.

## Temps réel
- WebSocket pour les événements de file si le backend fournit un contrat documenté.
- Reconnexion avec backoff exponentiel plafonné et jitter; arrêter à la sortie de l'écran/session.
- Après reconnexion, resynchroniser via endpoint REST autoritaire. Dédupliquer les événements si le protocole fournit un identifiant/sequence.
- Prévoir un état `connecting / connected / reconnecting / offline / stale` visible et accessible.
- Si WebSocket indisponible, fallback HTTP seulement si un endpoint de snapshot/polling est défini par le backend.

## Stockage et offline
- Refresh token uniquement dans `flutter_secure_storage` ; access token en mémoire uniquement (perdu au redémarrage, récupéré via refresh).
- Le cache métier doit être séparé des secrets et versionné.
- Les données en cache sont présentées comme telles avec timestamp/indicateur de fraîcheur.
- Les commandes de création de ticket ne sont pas mises en file offline par défaut : un ticket n'existe qu'après confirmation backend. Une stratégie offline de prise de ticket nécessite un protocole d'allocation/idempotence explicitement conçu côté backend.
- La technologie du cache persistant doit suivre l'arbitrage dans `DECISIONS.md`; ne pas ajouter Hive et Drift simultanément.

## Internationalisation
Utiliser `flutter gen-l10n`, ARB pour `fr`, `rn`, `en`. Prévoir pluralisation, formats date/heure/nombres, textes accessibles et changement de langue sans redémarrage si possible. La locale `rn` correspond au code langue utilisé dans les documents du projet pour le kirundi.

## Design system
- Couleur principale du rapport UI/UX : `#2563EB`.
- Couleur secondaire : `#1E293B`.
- Typographie : Inter ou Roboto, avec fallback système.
- Style minimaliste fintech/SaaS, contraste élevé, composants cohérents.
- Icônes accompagnées de libellés lorsque leur sens n'est pas universel.
- Respecter tailles de texte système, lecteurs d'écran, zones tactiles et états loading/empty/error/offline.

## Observabilité
Logs structurés et utiles au diagnostic, sans PII ni secrets. Ajouter un identifiant de corrélation seulement si le backend en fournit un. Ne pas introduire Firebase Crashlytics/Sentry sans configuration projet et décision de dépendance validées.
