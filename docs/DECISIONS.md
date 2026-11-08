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

## Processus de modification
Toute nouvelle décision doit être ajoutée ici avec : contexte, options étudiées, décision, conséquences, date et approbateur. Les décisions touchant invariants métier, sécurité, stack ou contrats inter-apps exigent validation de Vizane.
