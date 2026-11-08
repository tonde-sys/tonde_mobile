# TONDE Mobile - Instructions permanentes pour les agents de code

Tu travailles sur `tonde-mobile`, l'application mobile officielle de TONDE. Ce dépôt est un produit réel destiné à être livré à des institutions pilotes au Burundi. Le fondateur/Tech Lead, Vizane, valide les décisions structurantes.

## 1. Règles non négociables
- Lis `README.md` et tous les documents pertinents de `docs/` avant de modifier le code.
- Respecte les décisions de `docs/DECISIONS.md`. Si une exigence est contradictoire ou absente, signale-la et demande une décision au lieu d'inventer.
- Inspecte le dépôt, les versions Flutter/Dart et les fichiers existants avant toute modification. Ne remplace jamais un fichier de configuration sans en comprendre l'impact.
- Ne génère pas toute l'application en une seule opération. Travaille par incréments petits, testables et réversibles.
- Ne prétends jamais qu'une fonctionnalité, un test, un build ou une intégration fonctionne sans l'avoir exécuté et vérifié.
- Ne simule pas un backend réel. Aucun endpoint, payload, champ, statut ou événement WebSocket ne doit être inventé. Si le contrat backend manque, crée une interface abstraite et documente le blocage.
- N'ajoute aucune dépendance sans raison précise. Vérifie compatibilité, maintenance, taille, licences et impact sur Android/iOS.
- Ne commit/push/merge, ne publie aucune release et ne modifie aucun secret sans demande explicite.

## 2. Produit et invariants métier
- TONDE est une plateforme multi-tenant de gestion des files d'attente pour banques et établissements de santé en priorité.
- Une seule app mobile sert les citoyens de plusieurs organisations. Un utilisateur ne voit que les organisations auxquelles il est effectivement inscrit.
- Un utilisateur ne peut posséder qu'un seul ticket actif globalement, toutes organisations et agences confondues. Le backend est l'autorité et doit faire respecter cette règle. Le mobile ne fait qu'afficher l'état reçu.
- Les règles de file, priorités, position, ETA, transitions de ticket et anti-doublon appartiennent au backend. Ne les réimplémente pas dans Flutter.
- Les clients communiquent uniquement avec le backend via HTTPS/REST et WebSocket. Jamais d'accès direct à PostgreSQL ou Redis.
- Réseau intermittent, appareils Android modestes, coût des données et faible stockage sont des contraintes de conception de premier ordre.

## 3. Stack et architecture
- Flutter / Dart, Android et iOS.
- Architecture Feature-First avec séparation pragmatique `data / domain / presentation` pour les domaines métier.
- Riverpod pour l'état et l'injection de dépendances. Ne mélange pas Riverpod avec BLoC ou Provider.
- GoRouter pour la navigation.
- Dio pour HTTP, avec gestion centralisée des erreurs et des tokens.
- `flutter_secure_storage` pour les secrets/tokens persistants. Ne stocke jamais un token dans SharedPreferences, Hive, logs ou code source.
- WebSocket pour les événements temps réel, avec reconnexion bornée, backoff, heartbeat si le contrat serveur le prévoit, et resynchronisation REST après reconnexion.
- Internationalisation Flutter gen-l10n dès le départ : français (`fr`), kirundi (`rn`), anglais (`en`). Aucun texte métier visible codé en dur dans les widgets.
- Tests unitaires, providers, widgets et intégration selon le risque.

## 4. Architecture cible indicative
- `lib/app/`: composition de l'application, router, thèmes.
- `lib/core/`: configuration, réseau, sécurité, stockage, erreurs, observabilité, utilitaires réellement transverses.
- `lib/features/<feature>/{data,domain,presentation}/`: code isolé par feature.
- `lib/l10n/`: fichiers ARB.
- `test/`: tests miroir des couches/features.
Ne crée pas des dossiers vides ou des couches cérémonielles. Chaque abstraction doit résoudre un besoin réel.

## 5. Sécurité obligatoire
- Valide les données entrantes et les réponses réseau. Traite les réponses distantes comme non fiables.
- Ne journalise jamais OTP, mots de passe, access/refresh tokens, numéros de compte ou données personnelles sensibles.
- L'access token reste en mémoire autant que possible; le refresh token est conservé dans le stockage sécurisé du système.
- Les erreurs affichées à l'utilisateur sont compréhensibles et ne divulguent pas de détails internes.
- TLS en production. N'ajoute aucun mode qui désactive la validation des certificats.
- Les actions critiques sont idempotentes côté backend. Le client ne doit pas réessayer aveuglément une création de ticket si le résultat est inconnu.
- Les données offline sont explicitement marquées comme potentiellement obsolètes. Ne présente jamais un état cache comme une confirmation serveur.

## 6. Qualité et workflow
Avant modification :
1. Résume l'état observé du dépôt et les contraintes.
2. Propose un plan court avec fichiers à créer/modifier.
3. Identifie les décisions manquantes et risques.

Après modification :
1. Formate avec `dart format`.
2. Exécute `flutter analyze`.
3. Exécute les tests concernés, puis `flutter test` si possible.
4. Donne les commandes réellement exécutées et leurs résultats exacts.
5. Liste les fichiers modifiés, les limites restantes et la prochaine tâche unique.

## 7. Interdictions
- Pas de `dynamic` généralisé, de `catch` silencieux, de `print` en production, de `!` non justifié, de logique métier dans les widgets, ni de dépendances circulaires.
- Pas de gros fichiers fourre-tout, de duplication, de faux repositories qui retournent des données fictives en production.
- Pas de refactor global non demandé.
- Pas de changement d'API/backend supposé.
- Pas de TODO sans description du blocage, du propriétaire attendu et de la condition de résolution.

## 8. Autorité
En cas de conflit entre un prompt utilisateur récent et ce document, le prompt utilisateur récent prévaut. En cas de conflit entre les documents historiques du projet, `docs/DECISIONS.md` indique la règle de travail et les points encore à arbitrer. Toute modification des invariants métier ou du stack doit être proposée à Vizane avant implémentation.
