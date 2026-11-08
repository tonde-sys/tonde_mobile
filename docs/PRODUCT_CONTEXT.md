# TONDE Mobile - Contexte produit

## Produit
TONDE signifie « file d'attente » en kirundi. C'est une plateforme de gestion des files d'attente conçue pour les réalités africaines. Le mobile est l'interface citoyenne d'un écosystème comprenant backend, guichet, dashboard, affichage et autres surfaces.

## Utilisateurs et organisations
- Une application mobile unique pour les citoyens.
- Un utilisateur peut être inscrit auprès de plusieurs organisations.
- L'utilisateur ne doit voir que les organisations auxquelles son adhésion est confirmée.
- Les mécanismes d'adhésion et de vérification sont définis par chaque institution. Pour les banques, un numéro client peut être utilisé uniquement dans le cadre d'un mécanisme de vérification approuvé par la banque. Ne jamais traiter un numéro saisi comme preuve suffisante ni le stocker sans nécessité et protection explicites.

## Invariant ticket global
Un utilisateur ne peut avoir qu'un seul ticket actif globalement, y compris entre deux organisations différentes. Le backend est la source de vérité et doit imposer cet invariant de manière transactionnelle. Le mobile doit présenter les conflits et l'état du ticket actif retournés par l'API, jamais décider seul qu'un ticket est autorisé.

## Objectifs UX
- Obtenir un ticket en moins de trois actions lorsque le parcours et l'authentification le permettent.
- Afficher clairement le numéro de ticket, la position et l'état du suivi.
- Réduire le stress, rendre l'attente prévisible et garder l'utilisateur orienté.
- Limiter la densité visuelle, privilégier lisibilité, contraste, accessibilité et textes explicites.
- Rester utilisable sur appareils modestes et connexions instables.

## Périmètre mobile MVP
Le MVP doit rester volontairement réduit. La roadmap 90 jours place le mobile dans le sprint/phase « Mobile + QA » (jours 57 à 70), avec :
1. application Flutter Android testable;
2. prise de ticket;
3. suivi de position;
4. notifications push FCM;
5. cache local et synchronisation adaptée;
6. QA terrain et performance, notamment premier écran inférieur à 2 secondes sur 3G comme cible de validation.

Les modules fonctionnels d'architecture détaillent également l'authentification, la découverte des organisations/agences/services, le suivi temps réel, les priorités, la sécurité et le multilingue. Ils ne justifient pas de livrer tous les modules avancés avant le MVP.

## À différer sauf validation explicite
- Paiements Mobile Money et tickets VIP payants.
- Réservation de rendez-vous.
- IA/prédiction et recommandations d'agence.
- USSD et intégrations opérateurs.
- Fonctionnalités sociales, marketplace et monétisation avancée.
- Biométrie comme prérequis initial.

## Contraintes terrain
- Connexions mobiles intermittentes et coûteuses.
- Appareils Android d'entrée/milieu de gamme.
- Reconnexion fiable et récupération de l'état serveur.
- Afficher clairement l'ancienneté des données en cache.
- Réduire les appels réseau et la taille des réponses lorsque le contrat backend le permet.

## Sources internes du projet
Synthèse fondée sur les documents fournis : `tonde_orientation_ia.md`, `TONDE_Roadmap_MVP_90days.pdf`, `Tonde_Architecture_v1.0.pdf`, `Tonde_Guide_Initialisation_Projet.pdf`, `TONDE_UI_UX_Strategie.pdf`. En cas de conflit, consulter `DECISIONS.md`.
