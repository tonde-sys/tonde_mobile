# Quality gates - TONDE Mobile

## Avant toute PR
- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug` (si Android SDK disponible)
- vérifier que `git diff --check` ne signale aucun problème

## Critères d'acceptation du socle
1. Le projet compile sur la version Flutter/Dart du dépôt.
2. Aucun warning/error d'analyse non justifié.
3. Navigation initiale et routes inconnues gérées proprement.
4. Thème centralisé et composants de base cohérents.
5. Localisations FR/RN/EN générées et chargées.
6. Configuration dev/staging/prod sans secrets dans Git.
7. Gestion d'erreurs réseau testée avec erreurs, timeout et absence de réseau.
8. Stockage sécurisé encapsulé et testé sans afficher les valeurs sensibles.
9. Les providers et clients réseau sont testables sans vrais services externes.
10. Aucun endpoint métier ou payload fictif.

## Critères de sécurité
- Aucun secret, token, OTP ou donnée personnelle sensible dans logs ou fixtures commitées.
- Pas de désactivation TLS.
- Pas de token dans stockage non sécurisé.
- Pas de donnée cache présentée comme fraîche sans timestamp.
- Pas de création de ticket en mode offline non autorisée par un protocole backend.

## Rapport final obligatoire de l'agent
- Résumé des livrables.
- Liste des fichiers créés/modifiés.
- Commandes réellement exécutées avec résultat.
- Tests non exécutés et raison.
- Hypothèses ou contrats manquants.
- Risques résiduels.
- Une seule prochaine étape recommandée.
