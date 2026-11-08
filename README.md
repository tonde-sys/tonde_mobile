# TONDE Mobile - Agent Starter Kit

Ce kit prépare les agents de code (Perch Terminal, OpenCode, etc.) à travailler dans le dépôt Flutter `tonde-mobile` sans inventer les contrats backend ni dériver de la vision produit.

## Installation recommandée

### 1. Préparer le dépôt Flutter
Dans le dossier du dépôt GitHub `tonde-mobile`, vérifie d'abord :

```bash
flutter --version
dart --version
git status --short
```

Si le dépôt est réellement vide (aucun projet Flutter existant), initialise le projet :

```bash
flutter create --org app --project-name tonde .
```

Cette commande génère normalement l'identifiant Android/iOS `app.tonde`. Vérifie impérativement `applicationId` côté Android et `PRODUCT_BUNDLE_IDENTIFIER` côté iOS avant publication. Ne relance pas `flutter create` sur un projet déjà initialisé.

Puis valide le socle :

```bash
flutter pub get
flutter analyze
flutter test
```

### 2. Installer ce kit à la racine
Décompresse le ZIP dans la racine de `tonde-mobile`, à côté de `pubspec.yaml`. Autorise la fusion avec les fichiers existants, mais ne remplace pas aveuglément un `AGENTS.md`, README ou une configuration déjà personnalisée.

### 3. Ouvrir l'agent dans la racine du dépôt
L'agent doit démarrer dans le dossier contenant `AGENTS.md` et `pubspec.yaml`. Les agents compatibles doivent lire `AGENTS.md` automatiquement. Pour les autres, colle le contenu de `AGENTS.md` ou utilise le prompt maître de `prompts/MASTER_PROMPT_DEEPSEEK.md`.

## Première mission à donner à l'agent

Ne lui demande pas de construire toutes les fonctionnalités. Demande-lui de réaliser uniquement la **fondation technique vérifiable** : audit du dépôt, architecture minimale, configuration d'environnements, thème, navigation, localisation FR/RN/EN, gestion d'erreurs, client API sans endpoints fictifs, stockage sécurisé abstrait, observabilité sans données sensibles et tests de base.

Le Queue Engine, les transitions de tickets, les calculs de position et l'anti-doublon restent exclusivement côté backend.

## Documents
- `AGENTS.md` : règles permanentes pour les agents.
- `docs/PRODUCT_CONTEXT.md` : vision et périmètre mobile.
- `docs/ARCHITECTURE.md` : architecture Flutter attendue.
- `docs/DECISIONS.md` : décisions retenues et contradictions documentaires à ne pas masquer.
- `docs/QUALITY_GATES.md` : définition de terminé et commandes de validation.
- `prompts/MASTER_PROMPT_DEEPSEEK.md` : prompt maître prêt à coller.
- `prompts/TASK_PROMPT_TEMPLATE.md` : modèle pour chaque tâche ultérieure.

## Règle d'or
Un agent n'est pas autorisé à transformer une hypothèse en fait. Il inspecte, cite les fichiers observés, propose, implémente par étapes et vérifie.
