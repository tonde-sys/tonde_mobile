import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_rn.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('rn'),
  ];

  /// Nom commercial de l'application.
  ///
  /// In fr, this message translates to:
  /// **'TONDE'**
  String get appTitle;

  /// Titre de la page de fondation affichée tant que l'application n'est pas connectée au backend.
  ///
  /// In fr, this message translates to:
  /// **'Socle technique'**
  String get foundationTitle;

  /// Statut indiquant que seule la fondation technique est en place.
  ///
  /// In fr, this message translates to:
  /// **'Phase 1 — Fondation'**
  String get foundationStatus;

  /// Explication affichée sur la page de fondation pour éviter toute ambiguïté sur l'état du produit.
  ///
  /// In fr, this message translates to:
  /// **'Cette application est en cours de construction. Aucune donnée bancaire ou de santé n\'est encore connectée.'**
  String get foundationDescription;

  /// Titre affiché lorsqu'une route inconnue est demandée.
  ///
  /// In fr, this message translates to:
  /// **'Page introuvable'**
  String get notFoundTitle;

  /// Explication affichée lorsqu'une route inconnue est demandée.
  ///
  /// In fr, this message translates to:
  /// **'La page demandée n\'existe pas.'**
  String get notFoundDescription;

  /// Libellé du bouton qui ramène l'utilisateur à la page d'accueil.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get backToHome;

  /// Texte indicatif du champ de recherche des organisations.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une organisation'**
  String get organizationsSearchHint;

  /// Message affiché quand l'utilisateur n'a aucune organisation.
  ///
  /// In fr, this message translates to:
  /// **'Aucune organisation disponible.'**
  String get organizationsEmpty;

  /// Message affiché quand la recherche ne retourne aucun résultat.
  ///
  /// In fr, this message translates to:
  /// **'Aucune organisation ne correspond à votre recherche.'**
  String get organizationsNoResults;

  /// Message générique d'échec de chargement.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les données. Vérifiez votre connexion et réessayez.'**
  String get loadError;

  /// Libellé du bouton de nouvelle tentative.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// Libellé de la catégorie banque.
  ///
  /// In fr, this message translates to:
  /// **'Banque'**
  String get organizationTypeBank;

  /// Libellé de la catégorie santé.
  ///
  /// In fr, this message translates to:
  /// **'Santé'**
  String get organizationTypeHealth;

  /// Titre de la section listant les agences d'une organisation.
  ///
  /// In fr, this message translates to:
  /// **'Agences'**
  String get agenciesTitle;

  /// Message affiché quand une organisation n'a aucune agence.
  ///
  /// In fr, this message translates to:
  /// **'Aucune agence disponible pour le moment.'**
  String get agenciesEmpty;

  /// Libellé d'accessibilité du compteur de personnes en attente d'une agence.
  ///
  /// In fr, this message translates to:
  /// **'{count} personnes dans la file'**
  String queueCountSemantics(Object count);

  /// Nombre de personnes déjà en file avant l'utilisateur.
  ///
  /// In fr, this message translates to:
  /// **'{count} personnes devant vous'**
  String queueAhead(Object count);

  /// Bouton principal de prise de ticket.
  ///
  /// In fr, this message translates to:
  /// **'Prendre un ticket'**
  String get takeTicket;

  /// Libellé au-dessus du numéro de ticket.
  ///
  /// In fr, this message translates to:
  /// **'Votre numéro de ticket'**
  String get ticketNumberLabel;

  /// Position de l'utilisateur dans la file d'attente.
  ///
  /// In fr, this message translates to:
  /// **'Position dans la file : {position}'**
  String ticketPositionLabel(Object position);

  /// Titre affiché quand le ticket est pris.
  ///
  /// In fr, this message translates to:
  /// **'Ticket actif'**
  String get ticketActiveTitle;

  /// Consigne affichée après la prise de ticket.
  ///
  /// In fr, this message translates to:
  /// **'Présentez-vous à {agency}.'**
  String ticketSuccessNote(Object agency);

  /// Titre du conflit quand un ticket est déjà actif.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà un ticket actif'**
  String get ticketConflictTitle;

  /// Explication du conflit avec le ticket actif existant.
  ///
  /// In fr, this message translates to:
  /// **'Un seul ticket actif à la fois. Votre ticket : {number} — {agency}.'**
  String ticketConflictBody(Object agency, Object number);

  /// Bouton ouvrant le ticket actif depuis le conflit.
  ///
  /// In fr, this message translates to:
  /// **'Voir mon ticket'**
  String get viewMyTicket;

  /// Bouton retournant à la liste des agences.
  ///
  /// In fr, this message translates to:
  /// **'Retour aux agences'**
  String get backToAgencies;

  /// Titre de la page de connexion.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get loginTitle;

  /// Sous-titre de la page de connexion.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour gérer vos files d\'attente.'**
  String get loginSubtitle;

  /// Libellé du champ identifiant de connexion. Le backend n'a pas de nom d'utilisateur : le compte est identifié par l'e-mail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get emailLabel;

  /// Libellé du champ mot de passe.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get passwordLabel;

  /// Bouton de soumission du formulaire de connexion.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginButton;

  /// Invitation à créer un compte.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get noAccount;

  /// Lien vers la page d'inscription.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get registerLink;

  /// Titre de la page d'inscription.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get registerTitle;

  /// Sous-titre de la page d'inscription.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre compte TONDE.'**
  String get registerSubtitle;

  /// Libellé du champ nom complet.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get nameLabel;

  /// Bouton de soumission du formulaire d'inscription.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get registerButton;

  /// Invitation à se connecter.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get haveAccount;

  /// Lien vers la page de connexion.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginLink;

  /// Erreur affichée quand les identifiants sont refusés.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail ou mot de passe incorrect.'**
  String get invalidCredentials;

  /// Réponse du serveur (EMAIL_EXISTS) à l'inscription.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse e-mail est déjà utilisée.'**
  String get emailTaken;

  /// Erreur de validation d'un champ requis.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire.'**
  String get fieldRequired;

  /// Slogan affiché sous le nom de l'application.
  ///
  /// In fr, this message translates to:
  /// **'Votre temps a de la valeur'**
  String get tagline;

  /// Titre de la bannière d'accueil.
  ///
  /// In fr, this message translates to:
  /// **'Gérez votre file d\'attente facilement'**
  String get heroTitle;

  /// Texte de la bannière d'accueil.
  ///
  /// In fr, this message translates to:
  /// **'Prenez un ticket, suivez votre position en temps réel et gagnez du temps.'**
  String get heroBody;

  /// Bouton principal de la bannière d'accueil.
  ///
  /// In fr, this message translates to:
  /// **'Prendre un ticket'**
  String get heroCta;

  /// Légende sous l'indicateur de position.
  ///
  /// In fr, this message translates to:
  /// **'personnes avant vous'**
  String get peopleAhead;

  /// Temps d'attente estimé, {minutes} est un nombre de minutes.
  ///
  /// In fr, this message translates to:
  /// **'Temps estimé : {minutes} min'**
  String estimatedTime(int minutes);

  /// Bouton qui mène à la position dans la file.
  ///
  /// In fr, this message translates to:
  /// **'Voir ma position'**
  String get seePosition;

  /// Titre de la bannière d'accueil quand un ticket est actif.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes dans la file'**
  String get heroTitleActive;

  /// Texte de la bannière d'accueil quand un ticket est actif.
  ///
  /// In fr, this message translates to:
  /// **'Votre position se met à jour en temps réel. Restez à portée de voix du guichet.'**
  String get heroBodyActive;

  /// Bouton de reprise après une absence au guichet.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre mon ticket'**
  String get resumeTicket;

  /// Confirmation après une reprise de ticket réussie.
  ///
  /// In fr, this message translates to:
  /// **'Votre ticket est de retour dans la file.'**
  String get resumeSuccess;

  /// Refus serveur RECOVERY_WINDOW_EXPIRED.
  ///
  /// In fr, this message translates to:
  /// **'Le délai de reprise est écoulé. Prenez un nouveau ticket.'**
  String get resumeWindowExpired;

  /// Refus serveur MAX_MISSED_COUNT_REACHED.
  ///
  /// In fr, this message translates to:
  /// **'Trop d\'absences : la reprise n\'est plus possible. Prenez un nouveau ticket.'**
  String get resumeMaxMissed;

  /// Échec générique d'une reprise de ticket.
  ///
  /// In fr, this message translates to:
  /// **'La reprise n\'a pas abouti. Réessayez dans un instant.'**
  String get resumeFailed;

  /// Rappel affiché sous un ticket absent, avec l'heure limite de reprise.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne vous êtes pas présenté. Reprenez votre ticket avant {time}.'**
  String ticketAbsentNote(String time);

  /// Titre affiché quand le ticket a été appelé puis clôturé au guichet.
  ///
  /// In fr, this message translates to:
  /// **'Votre passage est terminé'**
  String get ticketClosedServedTitle;

  /// Explication affichée sous le titre, pour un ticket servi.
  ///
  /// In fr, this message translates to:
  /// **'Le guichet a clôturé le ticket {number}. Vous pouvez en reprendre un quand vous voulez.'**
  String ticketClosedServedBody(String number);

  /// Titre affiché quand le ticket a quitté la file sans avoir été appelé.
  ///
  /// In fr, this message translates to:
  /// **'Votre ticket a expiré'**
  String get ticketClosedExpiredTitle;

  /// Explication affichée sous le titre, pour un ticket expiré ou retiré de la file.
  ///
  /// In fr, this message translates to:
  /// **'Le ticket {number} n\'est plus dans la file. Reprenez un ticket pour être rappelé.'**
  String ticketClosedExpiredBody(String number);

  /// Titre de la section organisations de l'accueil.
  ///
  /// In fr, this message translates to:
  /// **'Mes organisations'**
  String get myOrganizations;

  /// Lien vers la liste complète des organisations.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get viewAll;

  /// Titre de la bannière d'aide.
  ///
  /// In fr, this message translates to:
  /// **'Besoin d\'aide ?'**
  String get needHelp;

  /// Texte de la bannière d'aide.
  ///
  /// In fr, this message translates to:
  /// **'Notre équipe est là pour vous assister.'**
  String get helpBody;

  /// Bouton de contact de la bannière d'aide.
  ///
  /// In fr, this message translates to:
  /// **'Contacter'**
  String get contact;

  /// État vide quand aucun ticket n'est actif.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ticket actif'**
  String get noActiveTicket;

  /// Explication de l'état sans ticket actif.
  ///
  /// In fr, this message translates to:
  /// **'Prenez un ticket dans une agence pour suivre votre position en temps réel.'**
  String get noActiveTicketBody;

  /// Message pour les fonctionnalités à venir.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get comingSoon;

  /// Action de déconnexion.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logout;

  /// Entrée de menu du profil.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get profileTitle;

  /// Entrée de menu à propos de l'application.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get aboutTitle;

  /// Onglet accueil de la navigation basse.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get tabHome;

  /// Onglet tickets de la navigation basse.
  ///
  /// In fr, this message translates to:
  /// **'Tickets'**
  String get tabTickets;

  /// Onglet notifications de la navigation basse.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get tabNotifications;

  /// Onglet assistance de la navigation basse.
  ///
  /// In fr, this message translates to:
  /// **'Assistance'**
  String get tabAssistance;

  /// Onglet plus de la navigation basse.
  ///
  /// In fr, this message translates to:
  /// **'Plus'**
  String get tabMore;

  /// Première notification fictive de la démo.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur TONDE'**
  String get notifWelcome;

  /// Détail de la notification de bienvenue.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte de démonstration est prêt.'**
  String get notifWelcomeBody;

  /// Deuxième notification fictive de la démo.
  ///
  /// In fr, this message translates to:
  /// **'Votre file avance'**
  String get notifQueue;

  /// Détail de la notification de file.
  ///
  /// In fr, this message translates to:
  /// **'Vous gagnez des places dans la file d\'attente.'**
  String get notifQueueBody;

  /// Troisième notification fictive de la démo.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle agence disponible'**
  String get notifAgency;

  /// Détail de la notification d'agence.
  ///
  /// In fr, this message translates to:
  /// **'De nouvelles agences viennent d\'être ajoutées.'**
  String get notifAgencyBody;

  /// Libellé du champ e-mail sur la page profil.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get profileEmail;

  /// Libellé du champ téléphone sur la page profil.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get profilePhone;

  /// Libellé du champ rôle sur la page profil.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get profileRole;

  /// Libellé du champ organisation sur la page profil.
  ///
  /// In fr, this message translates to:
  /// **'Organisation'**
  String get profileOrganization;

  /// Libellé de la date d'inscription sur la page profil.
  ///
  /// In fr, this message translates to:
  /// **'Membre depuis'**
  String get profileMemberSince;

  /// Titre de la section informations du compte.
  ///
  /// In fr, this message translates to:
  /// **'Informations du compte'**
  String get profileAccountInfo;

  /// Valeur affichée quand une information est absente.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get profileNotAvailable;

  /// Bouton ouvrant l'édition du profil.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get editProfile;

  /// Titre de la page d'édition du profil.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mes informations'**
  String get editProfileTitle;

  /// Bouton de sauvegarde du formulaire.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// Bouton d'annulation du formulaire.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// Confirmation affichée après la sauvegarde du profil.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour'**
  String get profileUpdated;

  /// Erreur affichée quand la sauvegarde du profil échoue.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour le profil.'**
  String get profileUpdateFailed;

  /// Erreur de validation du champ e-mail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide.'**
  String get invalidEmail;

  /// Erreur de validation du champ téléphone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone invalide.'**
  String get invalidPhone;

  /// Titre de l'écran de suivi temps réel de la file.
  ///
  /// In fr, this message translates to:
  /// **'Suivi en direct'**
  String get trackingTitle;

  /// Badge de statut : le ticket attend son tour.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get trackingStatusWaiting;

  /// Badge de statut : le numéro vient d'être appelé.
  ///
  /// In fr, this message translates to:
  /// **'Appelé'**
  String get trackingStatusCalled;

  /// Badge de statut : prise en charge en cours.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get trackingStatusInService;

  /// Badge de statut : le client ne s'est pas présenté.
  ///
  /// In fr, this message translates to:
  /// **'Absent'**
  String get trackingStatusAbsent;

  /// Libellé du numéro actuellement appelé au guichet.
  ///
  /// In fr, this message translates to:
  /// **'Au guichet maintenant'**
  String get trackingCalledNow;

  /// Libellé du bloc affichant le numéro de ticket.
  ///
  /// In fr, this message translates to:
  /// **'Votre ticket'**
  String get trackingYourTicket;

  /// Libellé du rang du client dans la file.
  ///
  /// In fr, this message translates to:
  /// **'Votre position'**
  String get trackingPosition;

  /// Phrase indiquant le rang du client dans la file.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes n°{position} dans la file'**
  String trackingYouAre(int position);

  /// Consigne d'usage du QR code du ticket.
  ///
  /// In fr, this message translates to:
  /// **'Présentez ce code au guichet'**
  String get trackingQrHint;

  /// Indique que les mises à jour arrivent par WebSocket.
  ///
  /// In fr, this message translates to:
  /// **'Direct'**
  String get trackingLive;

  /// Indique que les mises à jour arrivent par rafraîchissement périodique.
  ///
  /// In fr, this message translates to:
  /// **'Mode secours'**
  String get trackingPolling;

  /// Heure de la dernière mise à jour reçue.
  ///
  /// In fr, this message translates to:
  /// **'Mis à jour à {time}'**
  String trackingUpdatedAt(String time);

  /// Bandeau affiché quand le numéro du client est appelé.
  ///
  /// In fr, this message translates to:
  /// **'C\'est votre tour'**
  String get trackingCalledBanner;

  /// Consigne affichée avec le bandeau d'appel.
  ///
  /// In fr, this message translates to:
  /// **'Présentez votre QR code au guichet.'**
  String get trackingCalledBannerBody;

  /// Libellé du temps d'attente estimé.
  ///
  /// In fr, this message translates to:
  /// **'Attente estimée'**
  String get trackingWaitTime;

  /// Valeur du temps d'attente, en minutes.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String trackingMinutesValue(int minutes);

  /// No description provided for @trackingEtaUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Estimation en cours'**
  String get trackingEtaUnavailable;

  /// No description provided for @trackingCounterPaused.
  ///
  /// In fr, this message translates to:
  /// **'{counter} est en pause.'**
  String trackingCounterPaused(Object counter);

  /// No description provided for @trackingCounterPausedUntil.
  ///
  /// In fr, this message translates to:
  /// **'{counter} est en pause jusqu\'à {time}.'**
  String trackingCounterPausedUntil(Object counter, Object time);

  /// Suffixe de la carte de position : « 4 / dans la file ».
  ///
  /// In fr, this message translates to:
  /// **'dans la file'**
  String get trackingInQueue;

  /// Préfixe du bandeau affiché quand l'appareil n'a plus de réseau.
  ///
  /// In fr, this message translates to:
  /// **'Mode hors ligne'**
  String get offlineMode;

  /// Suffixe du bandeau hors ligne : les données affichées viennent du cache local.
  ///
  /// In fr, this message translates to:
  /// **'Affichage des données locales'**
  String get offlineLocalData;

  /// Libellé de l'attente de synchronisation.
  ///
  /// In fr, this message translates to:
  /// **'En attente de synchronisation'**
  String get offlinePendingSync;

  /// Nombre d'actions enregistrées localement et pas encore envoyées au serveur.
  ///
  /// In fr, this message translates to:
  /// **'{count} action(s) en attente'**
  String offlinePendingActions(int count);

  /// Pastille d'un ticket pris hors ligne, pas encore confirmé par le serveur.
  ///
  /// In fr, this message translates to:
  /// **'Non synchronisé'**
  String get ticketPendingSync;

  /// Titre affiché à la place du suivi quand le ticket attend sa synchronisation.
  ///
  /// In fr, this message translates to:
  /// **'Suivi en attente'**
  String get trackingPendingTitle;

  /// Explication du suivi différé d'un ticket pris hors ligne.
  ///
  /// In fr, this message translates to:
  /// **'Votre ticket est enregistré sur ce téléphone. Le suivi en direct démarrera dès le retour du réseau.'**
  String get trackingPendingBody;

  /// Titre de l'écran de succès quand le ticket a été pris hors ligne.
  ///
  /// In fr, this message translates to:
  /// **'Ticket enregistré hors ligne'**
  String get ticketPendingTitle;

  /// Explication de la confirmation différée du ticket.
  ///
  /// In fr, this message translates to:
  /// **'Il sera confirmé et synchronisé dès le retour du réseau.'**
  String get ticketPendingNote;

  /// Titre de la section de préférences de l'onglet Plus.
  ///
  /// In fr, this message translates to:
  /// **'Préférences'**
  String get moreSettings;

  /// Entrée de menu ouvrant le choix de la langue.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get moreLanguage;

  /// Entrée de menu ouvrant le choix du thème clair ou sombre.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get moreAppearance;

  /// Option de langue : suivre la langue du téléphone.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get languageSystem;

  /// Option de thème : suivre le réglage du téléphone.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSystem;

  /// Option de thème : affichage clair.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// Option de thème : affichage sombre.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @appVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// Description de l'application dans la fenêtre À propos.
  ///
  /// In fr, this message translates to:
  /// **'Application citoyenne de gestion des files d\'attente pour les banques et les établissements de santé au Burundi.'**
  String get aboutBody;

  /// Titre de l'écran de détail du ticket.
  ///
  /// In fr, this message translates to:
  /// **'Détails du ticket'**
  String get ticketDetailsTitle;

  /// Libellé au-dessus du numéro sur la carte pass.
  ///
  /// In fr, this message translates to:
  /// **'Votre numéro de ticket'**
  String get passYourNumber;

  /// Libellé du guichet assigné sur la carte pass.
  ///
  /// In fr, this message translates to:
  /// **'Guichet'**
  String get passDesk;

  /// Guichet pas encore attribué.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get passDeskPending;

  /// Explication quand le ticket n'a pas encore de QR code.
  ///
  /// In fr, this message translates to:
  /// **'Le QR code apparaîtra dès la synchronisation du ticket.'**
  String get passPendingQr;

  /// Invitation à ouvrir l'écran de détail depuis la carte.
  ///
  /// In fr, this message translates to:
  /// **'Voir le détail du ticket'**
  String get passOpenDetails;

  /// Étiquette d'accessibilité de la carte ticket.
  ///
  /// In fr, this message translates to:
  /// **'Ticket {number}, position {position} dans la file'**
  String ticketSemantics(String number, int position);

  /// Titre de la section file d'attente.
  ///
  /// In fr, this message translates to:
  /// **'File d\'attente'**
  String get detailsQueue;

  /// Titre de la section institution.
  ///
  /// In fr, this message translates to:
  /// **'Institution'**
  String get detailsInstitution;

  /// No description provided for @detailsName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get detailsName;

  /// Libellé de l'agence.
  ///
  /// In fr, this message translates to:
  /// **'Agence'**
  String get detailsAgency;

  /// Libellé de l'adresse de l'agence.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get detailsAddress;

  /// Titre de la section ticket.
  ///
  /// In fr, this message translates to:
  /// **'Ticket'**
  String get detailsTicket;

  /// Nombre de personnes devant le client.
  ///
  /// In fr, this message translates to:
  /// **'Personnes devant vous'**
  String get detailsPeopleAhead;

  /// Numéro actuellement appelé au guichet.
  ///
  /// In fr, this message translates to:
  /// **'Numéro appelé'**
  String get detailsCalledNumber;

  /// Guichet attribué au ticket.
  ///
  /// In fr, this message translates to:
  /// **'Guichet'**
  String get detailsCounter;

  /// Date et heure d'émission du ticket.
  ///
  /// In fr, this message translates to:
  /// **'Émis le'**
  String get detailsIssuedAt;

  /// Numéro du ticket.
  ///
  /// In fr, this message translates to:
  /// **'Numéro'**
  String get detailsNumber;

  /// Statut courant du ticket.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get detailsStatus;

  /// Bouton de rafraîchissement manuel.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser le suivi'**
  String get detailsRefresh;

  /// État du bouton pendant le rafraîchissement.
  ///
  /// In fr, this message translates to:
  /// **'Actualisation…'**
  String get detailsRefreshing;

  /// Bouton ouvrant les notifications du ticket.
  ///
  /// In fr, this message translates to:
  /// **'Notifications du ticket'**
  String get detailsNotifications;

  /// Liste vide de notifications.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification pour ce ticket.'**
  String get detailsNotificationsEmpty;

  /// Action d'annulation du ticket.
  ///
  /// In fr, this message translates to:
  /// **'Annuler le ticket'**
  String get detailsCancel;

  /// Confirmation d'annulation.
  ///
  /// In fr, this message translates to:
  /// **'Annuler le ticket {number} ?'**
  String detailsCancelTitle(String number);

  /// Conséquence de l'annulation.
  ///
  /// In fr, this message translates to:
  /// **'Votre place sera libérée immédiatement. Cette action est définitive : il faudra reprendre un ticket à l\'accueil.'**
  String get detailsCancelBody;

  /// Bouton d'abandon de l'annulation.
  ///
  /// In fr, this message translates to:
  /// **'Conserver mon ticket'**
  String get detailsCancelKeep;

  /// Confirmation définitive de l'annulation.
  ///
  /// In fr, this message translates to:
  /// **'Oui, annuler'**
  String get detailsCancelConfirm;

  /// Message affiché après annulation.
  ///
  /// In fr, this message translates to:
  /// **'Ticket annulé'**
  String get detailsCancelled;

  /// Titre du bloc QR code.
  ///
  /// In fr, this message translates to:
  /// **'Pass de validation'**
  String get detailsQrTitle;

  /// Titre de l'écran de choix du service.
  ///
  /// In fr, this message translates to:
  /// **'Services'**
  String get servicesTitle;

  /// Invitation à choisir un service.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le service qui correspond à votre demande.'**
  String get servicesChooseHint;

  /// Liste de services vide.
  ///
  /// In fr, this message translates to:
  /// **'Aucun service disponible pour cette agence.'**
  String get servicesEmpty;

  /// Service introuvable (lien obsolète).
  ///
  /// In fr, this message translates to:
  /// **'Ce service n\'est plus proposé par cette agence. Choisissez-en un autre.'**
  String get serviceUnavailable;

  /// Retour au choix du service.
  ///
  /// In fr, this message translates to:
  /// **'Changer de service'**
  String get changeService;

  /// Service demandé, affiché sur la feuille du ticket.
  ///
  /// In fr, this message translates to:
  /// **'Service'**
  String get detailsService;

  /// Confirmation d'annulation depuis l'accueil.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous annuler le ticket ?'**
  String get ticketCancelQuestion;

  /// Conséquence de l'annulation depuis l'accueil.
  ///
  /// In fr, this message translates to:
  /// **'Le ticket {number} sera retiré de la file et votre place sera perdue.'**
  String ticketCancelBody(String number);

  /// Retour à l'accueil depuis la confirmation de ticket.
  ///
  /// In fr, this message translates to:
  /// **'Retour au tableau de bord'**
  String get backToDashboard;

  /// Pastille affichée quand le client est déjà passé au guichet.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get ticketServed;

  /// Bouton d'abandon de la présentation initiale.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get onboardingSkip;

  /// Bouton d'avancement dans la présentation.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get onboardingNext;

  /// Bouton de retour dans la présentation.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get onboardingBack;

  /// Bouton final de la présentation.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboardingStart;

  /// Titre du premier écran de présentation.
  ///
  /// In fr, this message translates to:
  /// **'Fini les files d\'attente interminables.'**
  String get onboardingTitle1;

  /// Texte du premier écran de présentation.
  ///
  /// In fr, this message translates to:
  /// **'Prenez votre ticket à distance et suivez l\'évolution de la file en temps réel depuis votre téléphone.'**
  String get onboardingBody1;

  /// Titre du deuxième écran de présentation.
  ///
  /// In fr, this message translates to:
  /// **'Arrivez juste à temps.'**
  String get onboardingTitle2;

  /// Texte du deuxième écran de présentation.
  ///
  /// In fr, this message translates to:
  /// **'Visualisez le nombre de personnes avant vous et recevez une alerte dès que votre tour approche.'**
  String get onboardingBody2;

  /// Titre du troisième écran de présentation.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un ticket papier ? Scannez-le.'**
  String get onboardingTitle3;

  /// Texte du troisième écran de présentation.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisez votre ticket imprimé sur votre mobile pour patienter où vous voulez sans perdre votre place.'**
  String get onboardingBody3;

  /// No description provided for @ticketServedNote.
  ///
  /// In fr, this message translates to:
  /// **'Votre passage est terminé. Vous pouvez reprendre un ticket à tout moment.'**
  String get ticketServedNote;

  /// No description provided for @notifTicketConfirmedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre ticket {number} est confirmé'**
  String notifTicketConfirmedTitle(String number);

  /// No description provided for @notifTicketConfirmedBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes inscrit dans la file {service} de l’agence {agency}.'**
  String notifTicketConfirmedBody(String service, String agency);

  /// No description provided for @notifProgressTitle.
  ///
  /// In fr, this message translates to:
  /// **'Encore {count} personnes avant votre tour'**
  String notifProgressTitle(int count);

  /// No description provided for @notifProgressBody.
  ///
  /// In fr, this message translates to:
  /// **'Temps d’attente estimé : {minutes} minutes. Préparez vos documents.'**
  String notifProgressBody(int minutes);

  /// No description provided for @notifProgressBodyNoEta.
  ///
  /// In fr, this message translates to:
  /// **'Encore {count} personnes avant vous. Préparez vos documents.'**
  String notifProgressBodyNoEta(Object count);

  /// No description provided for @notifApproachingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre tour approche !'**
  String get notifApproachingTitle;

  /// No description provided for @notifApproachingBody.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Il ne reste qu’une personne avant vous.} other{Il ne reste que {count} personnes avant vous.}} Rapprochez-vous de l’agence.'**
  String notifApproachingBody(int count);

  /// No description provided for @notifCalledTitle.
  ///
  /// In fr, this message translates to:
  /// **'C’est votre tour !'**
  String get notifCalledTitle;

  /// No description provided for @notifCalledBody.
  ///
  /// In fr, this message translates to:
  /// **'Le ticket {number} est appelé au {counter}. Présentez-vous immédiatement.'**
  String notifCalledBody(String number, String counter);

  /// No description provided for @notifReminderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre ticket est toujours appelé'**
  String get notifReminderTitle;

  /// No description provided for @notifReminderBody.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez rejoindre le {counter} sans attendre.'**
  String notifReminderBody(String counter);

  /// No description provided for @notifAbsentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez été marqué absent'**
  String get notifAbsentTitle;

  /// No description provided for @notifAbsentBody.
  ///
  /// In fr, this message translates to:
  /// **'Le ticket {number} a été marqué absent. Consultez l’application pour vérifier les possibilités de reprise.'**
  String notifAbsentBody(String number);

  /// No description provided for @notifResumedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre ticket a été réactivé'**
  String get notifResumedTitle;

  /// No description provided for @notifResumedBody.
  ///
  /// In fr, this message translates to:
  /// **'Le ticket {number} est de nouveau dans la file d’attente.'**
  String notifResumedBody(String number);

  /// No description provided for @notifServedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre passage est terminé'**
  String get notifServedTitle;

  /// No description provided for @notifServedBody.
  ///
  /// In fr, this message translates to:
  /// **'Merci d’avoir utilisé TONDE !'**
  String get notifServedBody;

  /// No description provided for @notifCounterFallback.
  ///
  /// In fr, this message translates to:
  /// **'guichet'**
  String get notifCounterFallback;

  /// No description provided for @notifCenterEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification pour le moment'**
  String get notifCenterEmpty;

  /// No description provided for @notifCenterEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous serez prévenu à chaque étape de votre file d’attente.'**
  String get notifCenterEmptyBody;

  /// No description provided for @moreNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get moreNotifications;

  /// No description provided for @moreNotificationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Alertes de file d’attente et appels au guichet'**
  String get moreNotificationsSubtitle;

  /// No description provided for @moreCallSound.
  ///
  /// In fr, this message translates to:
  /// **'Son à l’appel'**
  String get moreCallSound;

  /// No description provided for @moreCallSoundSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Fait sonner le téléphone quand votre numéro est appelé'**
  String get moreCallSoundSubtitle;

  /// No description provided for @notifDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la notification'**
  String get notifDelete;

  /// No description provided for @notifUnreadCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune non lue} =1{1 non lue} other{{count} non lues}}'**
  String notifUnreadCount(int count);

  /// No description provided for @profilePhotoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil'**
  String get profilePhotoTitle;

  /// No description provided for @profilePhotoHint.
  ///
  /// In fr, this message translates to:
  /// **'Touchez la photo pour la changer'**
  String get profilePhotoHint;

  /// No description provided for @profilePhotoCamera.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get profilePhotoCamera;

  /// No description provided for @profilePhotoGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get profilePhotoGallery;

  /// No description provided for @profilePhotoRemove.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la photo'**
  String get profilePhotoRemove;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil mise à jour'**
  String get profilePhotoUpdated;

  /// No description provided for @profilePhotoRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil supprimée'**
  String get profilePhotoRemoved;

  /// No description provided for @profilePhotoFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour la photo de profil'**
  String get profilePhotoFailed;

  /// Validation locale avant envoi, pour éviter un aller-retour réseau sur une adresse manifestement fausse.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez une adresse e-mail valide.'**
  String get emailInvalid;

  /// Erreur de transport (pas de réseau, délai dépassé) : distincte d'un refus du serveur.
  ///
  /// In fr, this message translates to:
  /// **'Serveur injoignable. Vérifiez votre connexion.'**
  String get networkError;

  /// No description provided for @organizationTypeOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get organizationTypeOther;

  /// Statut d'un ticket dont le service est rendu ou annulé.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get trackingStatusDone;

  /// No description provided for @accountDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte a été désactivé. Contactez votre organisation.'**
  String get accountDisabled;

  /// No description provided for @accountLocked.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Réessayez dans quelques minutes.'**
  String get accountLocked;

  /// No description provided for @authErrorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'La connexion a échoué. Réessayez.'**
  String get authErrorGeneric;

  /// No description provided for @passwordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 8 caractères.'**
  String get passwordTooShort;

  /// No description provided for @assistanceMyTicket.
  ///
  /// In fr, this message translates to:
  /// **'Mon ticket'**
  String get assistanceMyTicket;

  /// No description provided for @assistanceFaq.
  ///
  /// In fr, this message translates to:
  /// **'Questions fréquentes'**
  String get assistanceFaq;

  /// No description provided for @assistanceContact.
  ///
  /// In fr, this message translates to:
  /// **'Nous contacter'**
  String get assistanceContact;

  /// No description provided for @assistanceGiveFeedback.
  ///
  /// In fr, this message translates to:
  /// **'Donner mon avis'**
  String get assistanceGiveFeedback;

  /// No description provided for @assistanceGiveFeedbackBody.
  ///
  /// In fr, this message translates to:
  /// **'Dites-nous comment s\'est passé votre passage.'**
  String get assistanceGiveFeedbackBody;

  /// No description provided for @assistanceReportBug.
  ///
  /// In fr, this message translates to:
  /// **'Signaler un problème'**
  String get assistanceReportBug;

  /// No description provided for @assistanceReportBugBody.
  ///
  /// In fr, this message translates to:
  /// **'Quelque chose ne fonctionne pas ? Décrivez-le.'**
  String get assistanceReportBugBody;

  /// No description provided for @assistanceMyFeedback.
  ///
  /// In fr, this message translates to:
  /// **'Mes retours'**
  String get assistanceMyFeedback;

  /// No description provided for @assistanceMyFeedbackBody.
  ///
  /// In fr, this message translates to:
  /// **'Suivez ce que vous nous avez envoyé.'**
  String get assistanceMyFeedbackBody;

  /// No description provided for @assistanceFeedbackSection.
  ///
  /// In fr, this message translates to:
  /// **'Avis et retours'**
  String get assistanceFeedbackSection;

  /// No description provided for @assistanceServiceStatus.
  ///
  /// In fr, this message translates to:
  /// **'État du service'**
  String get assistanceServiceStatus;

  /// No description provided for @helpCenterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Centre d\'aide'**
  String get helpCenterTitle;

  /// No description provided for @helpCenterQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Comment pouvons-nous vous aider ?'**
  String get helpCenterQuestion;

  /// No description provided for @helpInstitutionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contacter mon institution'**
  String get helpInstitutionTitle;

  /// No description provided for @helpInstitutionBody.
  ///
  /// In fr, this message translates to:
  /// **'Une question concernant votre ticket ou le service de l\'agence.'**
  String get helpInstitutionBody;

  /// No description provided for @helpInstitutionAction.
  ///
  /// In fr, this message translates to:
  /// **'Appeler l\'institution'**
  String get helpInstitutionAction;

  /// No description provided for @helpTondeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contacter TONDE'**
  String get helpTondeTitle;

  /// No description provided for @helpTondeBody.
  ///
  /// In fr, this message translates to:
  /// **'Un problème technique avec l\'application ou votre compte.'**
  String get helpTondeBody;

  /// No description provided for @helpTondeAction.
  ///
  /// In fr, this message translates to:
  /// **'Contacter le support'**
  String get helpTondeAction;

  /// No description provided for @helpFaqBody.
  ///
  /// In fr, this message translates to:
  /// **'Consultez les réponses aux questions courantes.'**
  String get helpFaqBody;

  /// No description provided for @helpFaqAction.
  ///
  /// In fr, this message translates to:
  /// **'Consulter la FAQ'**
  String get helpFaqAction;

  /// No description provided for @helpFeedbackTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre avis compte'**
  String get helpFeedbackTitle;

  /// No description provided for @helpFeedbackBody.
  ///
  /// In fr, this message translates to:
  /// **'Dites-nous ce que vous voulez voir s\'améliorer dans TONDE.'**
  String get helpFeedbackBody;

  /// No description provided for @supportTondeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Support technique de l\'application'**
  String get supportTondeSubtitle;

  /// No description provided for @supportAlwaysOpen.
  ///
  /// In fr, this message translates to:
  /// **'Disponible 24 h/24, 7 j/7'**
  String get supportAlwaysOpen;

  /// No description provided for @supportChooseInstitution.
  ///
  /// In fr, this message translates to:
  /// **'Choisir mon institution'**
  String get supportChooseInstitution;

  /// No description provided for @supportInstitutionEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune institution liée à votre compte.'**
  String get supportInstitutionEmpty;

  /// No description provided for @supportInstitutionEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Prenez un ticket ou parcourez les institutions pour trouver leurs coordonnées.'**
  String get supportInstitutionEmptyBody;

  /// No description provided for @supportBrowseInstitutions.
  ///
  /// In fr, this message translates to:
  /// **'Parcourir les institutions'**
  String get supportBrowseInstitutions;

  /// No description provided for @supportInstitutionNoChannel.
  ///
  /// In fr, this message translates to:
  /// **'Cette institution n\'a pas publié de coordonnées.'**
  String get supportInstitutionNoChannel;

  /// No description provided for @supportInstitutionNoChannelBody.
  ///
  /// In fr, this message translates to:
  /// **'Présentez-vous à l\'agence : le personnel vous répondra sur place.'**
  String get supportInstitutionNoChannelBody;

  /// No description provided for @supportCallInstitution.
  ///
  /// In fr, this message translates to:
  /// **'Appeler l\'institution'**
  String get supportCallInstitution;

  /// No description provided for @supportLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les coordonnées.'**
  String get supportLoadFailed;

  /// No description provided for @supportClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get supportClose;

  /// No description provided for @faqIntro.
  ///
  /// In fr, this message translates to:
  /// **'Les réponses aux questions qu\'on nous pose le plus.'**
  String get faqIntro;

  /// No description provided for @feedbackIntro.
  ///
  /// In fr, this message translates to:
  /// **'Dites-nous ce qui marche, ce qui bloque, ou ce qui manque.'**
  String get feedbackIntro;

  /// No description provided for @feedbackThanksTitle.
  ///
  /// In fr, this message translates to:
  /// **'Merci !'**
  String get feedbackThanksTitle;

  /// No description provided for @feedbackThanksBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre message est bien arrivé. Nous le lisons tous les jours.'**
  String get feedbackThanksBody;

  /// No description provided for @serviceReachable.
  ///
  /// In fr, this message translates to:
  /// **'Service joignable'**
  String get serviceReachable;

  /// No description provided for @serviceUnreachable.
  ///
  /// In fr, this message translates to:
  /// **'Service injoignable'**
  String get serviceUnreachable;

  /// No description provided for @faqTakeTicketTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment prendre un ticket ?'**
  String get faqTakeTicketTitle;

  /// No description provided for @faqTakeTicketBody.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez l\'accueil, choisissez l\'organisation, l\'agence et le service, puis confirmez. Votre ticket apparaît aussitôt avec votre position.'**
  String get faqTakeTicketBody;

  /// No description provided for @faqAbsentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Je n\'ai pas entendu mon appel, que faire ?'**
  String get faqAbsentTitle;

  /// No description provided for @faqAbsentBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre ticket passe en « absent » mais garde sa place un moment. Depuis l\'accueil, appuyez sur « Reprendre mon ticket » avant l\'heure affichée : vous retrouvez la file, à la fin de votre priorité.'**
  String get faqAbsentBody;

  /// No description provided for @faqExpiredTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon ticket a expiré'**
  String get faqExpiredTitle;

  /// No description provided for @faqExpiredBody.
  ///
  /// In fr, this message translates to:
  /// **'Un ticket non réclamé à temps quitte la file. Prenez-en un nouveau : votre position sera calculée sur la file du moment.'**
  String get faqExpiredBody;

  /// No description provided for @faqPausedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le guichet est en pause'**
  String get faqPausedTitle;

  /// No description provided for @faqPausedBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'heure de reprise s\'affiche sous le nom du guichet. Votre position ne bouge pas pendant la pause : seul le temps d\'attente estimé est reporté.'**
  String get faqPausedBody;

  /// No description provided for @faqNotificationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Je ne reçois pas de notifications'**
  String get faqNotificationsTitle;

  /// No description provided for @faqNotificationsBody.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez que les notifications sont autorisées pour TONDE dans les réglages du téléphone, et que le mode silencieux n\'est pas actif. L\'application reste utilisable sans elles : le suivi s\'affiche à l\'écran.'**
  String get faqNotificationsBody;

  /// No description provided for @faqTwoTicketsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Puis-je prendre deux tickets ?'**
  String get faqTwoTicketsTitle;

  /// No description provided for @faqTwoTicketsBody.
  ///
  /// In fr, this message translates to:
  /// **'Non. Un seul ticket actif par compte, toutes organisations confondues : c\'est ce qui garantit que la file reste honnête pour tout le monde.'**
  String get faqTwoTicketsBody;

  /// No description provided for @feedbackReviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Donner mon avis'**
  String get feedbackReviewTitle;

  /// No description provided for @feedbackBugTitle.
  ///
  /// In fr, this message translates to:
  /// **'Signaler un problème'**
  String get feedbackBugTitle;

  /// No description provided for @feedbackCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get feedbackCategory;

  /// No description provided for @feedbackCategoryReview.
  ///
  /// In fr, this message translates to:
  /// **'Avis'**
  String get feedbackCategoryReview;

  /// No description provided for @feedbackCategoryBug.
  ///
  /// In fr, this message translates to:
  /// **'Problème'**
  String get feedbackCategoryBug;

  /// No description provided for @feedbackCategorySuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion'**
  String get feedbackCategorySuggestion;

  /// No description provided for @feedbackRating.
  ///
  /// In fr, this message translates to:
  /// **'Votre note'**
  String get feedbackRating;

  /// No description provided for @feedbackRatingHint.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif'**
  String get feedbackRatingHint;

  /// No description provided for @feedbackMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre message'**
  String get feedbackMessage;

  /// No description provided for @feedbackMessageHint.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez ce qui s\'est passé, en quelques phrases.'**
  String get feedbackMessageHint;

  /// No description provided for @feedbackMessageCounter.
  ///
  /// In fr, this message translates to:
  /// **'{count}/1000'**
  String feedbackMessageCounter(int count);

  /// No description provided for @feedbackMessageTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Encore {count} caractères.'**
  String feedbackMessageTooShort(int count);

  /// No description provided for @feedbackSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get feedbackSubmit;

  /// No description provided for @feedbackSent.
  ///
  /// In fr, this message translates to:
  /// **'Merci, votre retour est envoyé.'**
  String get feedbackSent;

  /// No description provided for @feedbackRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez envoyé plusieurs retours récemment. Réessayez dans une heure.'**
  String get feedbackRateLimited;

  /// No description provided for @feedbackAlreadySent.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà signalé ce ticket dans cette catégorie.'**
  String get feedbackAlreadySent;

  /// No description provided for @feedbackFailed.
  ///
  /// In fr, this message translates to:
  /// **'L\'envoi a échoué. Réessayez.'**
  String get feedbackFailed;

  /// No description provided for @feedbackPrivacyNote.
  ///
  /// In fr, this message translates to:
  /// **'Votre retour est associé à votre compte et n\'est jamais publié.'**
  String get feedbackPrivacyNote;

  /// No description provided for @feedbackHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes retours'**
  String get feedbackHistoryTitle;

  /// No description provided for @feedbackHistoryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun retour envoyé'**
  String get feedbackHistoryEmpty;

  /// No description provided for @feedbackHistoryEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Vos avis et signalements apparaîtront ici, avec leur état de traitement.'**
  String get feedbackHistoryEmptyBody;

  /// No description provided for @feedbackStatusReceived.
  ///
  /// In fr, this message translates to:
  /// **'Reçu'**
  String get feedbackStatusReceived;

  /// No description provided for @feedbackStatusRead.
  ///
  /// In fr, this message translates to:
  /// **'Lu'**
  String get feedbackStatusRead;

  /// No description provided for @feedbackStatusResolved.
  ///
  /// In fr, this message translates to:
  /// **'Traité'**
  String get feedbackStatusResolved;

  /// No description provided for @contactWhatsApp.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp'**
  String get contactWhatsApp;

  /// No description provided for @contactCall.
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get contactCall;

  /// No description provided for @contactEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get contactEmail;

  /// No description provided for @contactNoChannel.
  ///
  /// In fr, this message translates to:
  /// **'Aucun moyen de contact n\'est configuré pour cette organisation.'**
  String get contactNoChannel;

  /// No description provided for @contactOpenFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir cette application.'**
  String get contactOpenFailed;

  /// No description provided for @errOfflineDetail.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre connexion, puis réessayez. Rien n\'a été perdu.'**
  String get errOfflineDetail;

  /// No description provided for @errTicketActive.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà un ticket en cours.'**
  String get errTicketActive;

  /// No description provided for @errTicketActiveDetail.
  ///
  /// In fr, this message translates to:
  /// **'Un seul ticket à la fois. Suivez celui-ci, ou annulez-le avant d\'en prendre un autre.'**
  String get errTicketActiveDetail;

  /// No description provided for @errBranchClosed.
  ///
  /// In fr, this message translates to:
  /// **'Cette agence est fermée.'**
  String get errBranchClosed;

  /// No description provided for @errBranchClosedDetail.
  ///
  /// In fr, this message translates to:
  /// **'Les tickets ne peuvent être pris que pendant les heures d\'ouverture.'**
  String get errBranchClosedDetail;

  /// No description provided for @errDailyLimit.
  ///
  /// In fr, this message translates to:
  /// **'La limite de tickets du jour est atteinte.'**
  String get errDailyLimit;

  /// No description provided for @errDailyLimitDetail.
  ///
  /// In fr, this message translates to:
  /// **'Réessayez demain, ou choisissez une autre agence.'**
  String get errDailyLimitDetail;

  /// No description provided for @errRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives.'**
  String get errRateLimited;

  /// No description provided for @errRateLimitedDetail.
  ///
  /// In fr, this message translates to:
  /// **'Patientez un instant avant de réessayer.'**
  String get errRateLimitedDetail;

  /// No description provided for @errGracePeriod.
  ///
  /// In fr, this message translates to:
  /// **'Votre ticket n\'est pas encore reprenable.'**
  String get errGracePeriod;

  /// No description provided for @errGracePeriodDetail.
  ///
  /// In fr, this message translates to:
  /// **'Le guichet vient de vous appeler. Attendez la fin du délai, puis réessayez.'**
  String get errGracePeriodDetail;

  /// No description provided for @errTicketGone.
  ///
  /// In fr, this message translates to:
  /// **'Ce ticket n\'existe plus.'**
  String get errTicketGone;

  /// No description provided for @errTicketGoneDetail.
  ///
  /// In fr, this message translates to:
  /// **'Il a peut-être été clôturé entre-temps. Prenez-en un nouveau si besoin.'**
  String get errTicketGoneDetail;

  /// No description provided for @errServer.
  ///
  /// In fr, this message translates to:
  /// **'Le service a rencontré un problème.'**
  String get errServer;

  /// No description provided for @errServerDetail.
  ///
  /// In fr, this message translates to:
  /// **'Ce n\'est pas de votre fait. Réessayez dans un instant.'**
  String get errServerDetail;

  /// No description provided for @errValidation.
  ///
  /// In fr, this message translates to:
  /// **'Certaines informations sont invalides.'**
  String get errValidation;

  /// No description provided for @errForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Cette action n\'est pas autorisée pour votre compte.'**
  String get errForbidden;

  /// No description provided for @errUnexpected.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur inattendue est survenue.'**
  String get errUnexpected;

  /// No description provided for @errUnexpectedDetail.
  ///
  /// In fr, this message translates to:
  /// **'Réessayez. Si cela persiste, signalez-le depuis l\'assistance.'**
  String get errUnexpectedDetail;

  /// No description provided for @errInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Une demande identique est déjà en cours.'**
  String get errInProgress;

  /// No description provided for @errTechnicalDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails techniques'**
  String get errTechnicalDetails;

  /// No description provided for @actionChooseService.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un service'**
  String get actionChooseService;

  /// No description provided for @actionTakeNewTicket.
  ///
  /// In fr, this message translates to:
  /// **'Prendre un ticket'**
  String get actionTakeNewTicket;

  /// No description provided for @actionWait.
  ///
  /// In fr, this message translates to:
  /// **'Patientez'**
  String get actionWait;

  /// No description provided for @errRateLimitedSeconds.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Patientez {seconds} secondes.'**
  String errRateLimitedSeconds(int seconds);

  /// No description provided for @errIncident.
  ///
  /// In fr, this message translates to:
  /// **'Référence : {id}'**
  String errIncident(String id);

  /// Titre du widget d'écran d'accueil quand aucun ticket n'est actif.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ticket'**
  String get widgetEmptyTitle;

  /// Invitation du widget d'écran d'accueil quand aucun ticket n'est actif.
  ///
  /// In fr, this message translates to:
  /// **'Touchez pour en prendre un'**
  String get widgetEmptyBody;

  /// Position dans la file, telle qu'affichée par le widget d'écran d'accueil.
  ///
  /// In fr, this message translates to:
  /// **'Position {position}'**
  String widgetPosition(int position);

  /// Attente estimée, telle qu'affichée par le widget d'écran d'accueil.
  ///
  /// In fr, this message translates to:
  /// **'≈ {minutes} min'**
  String widgetEta(int minutes);

  /// Heure de dernière mise à jour du widget d'écran d'accueil.
  ///
  /// In fr, this message translates to:
  /// **'Mis à jour à {time}'**
  String widgetUpdated(String time);

  /// Widget : un guichet de la file est en pause, heure de reprise inconnue.
  ///
  /// In fr, this message translates to:
  /// **'Guichet en pause'**
  String get widgetCounterPaused;

  /// Widget : un guichet de la file est en pause jusqu'à une heure connue.
  ///
  /// In fr, this message translates to:
  /// **'Pause jusqu\'à {time}'**
  String widgetCounterPausedUntil(String time);

  /// Entrée de menu qui propose d'épingler le widget.
  ///
  /// In fr, this message translates to:
  /// **'Widget d\'écran d\'accueil'**
  String get moreHomeWidget;

  /// Sous-titre de l'entrée de menu du widget.
  ///
  /// In fr, this message translates to:
  /// **'Votre ticket visible sans ouvrir l\'application'**
  String get moreHomeWidgetSubtitle;

  /// Message affiché après une demande d'épinglage du widget.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez l\'ajout dans la fenêtre du lanceur.'**
  String get homeWidgetPinConfirm;

  /// Message affiché quand le lanceur refuse l'épinglage.
  ///
  /// In fr, this message translates to:
  /// **'Votre lanceur ne permet pas d\'ajouter le widget depuis l\'application. Ajoutez-le depuis l\'écran d\'accueil.'**
  String get homeWidgetPinUnsupported;

  /// Titre de la proposition d'épingler le widget, sur l'écran de confirmation d'un ticket.
  ///
  /// In fr, this message translates to:
  /// **'Suivez votre position depuis l\'accueil'**
  String get homeWidgetInviteTitle;

  /// Corps de la proposition d'épingler le widget.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez le widget TONDE pour voir votre numéro, votre position et l\'attente sans ouvrir l\'application.'**
  String get homeWidgetInviteBody;

  /// Bouton qui demande l'épinglage du widget.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter le widget'**
  String get homeWidgetInviteAccept;

  /// Bouton qui écarte la proposition d'épingler le widget.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get homeWidgetInviteLater;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'rn'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'rn':
      return AppLocalizationsRn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
