// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'TONDE';

  @override
  String get foundationTitle => 'Socle technique';

  @override
  String get foundationStatus => 'Phase 1 — Fondation';

  @override
  String get foundationDescription =>
      'Cette application est en cours de construction. Aucune donnée bancaire ou de santé n\'est encore connectée.';

  @override
  String get notFoundTitle => 'Page introuvable';

  @override
  String get notFoundDescription => 'La page demandée n\'existe pas.';

  @override
  String get backToHome => 'Retour à l\'accueil';

  @override
  String get organizationsSearchHint => 'Rechercher une organisation';

  @override
  String get organizationsEmpty => 'Aucune organisation disponible.';

  @override
  String get organizationsNoResults =>
      'Aucune organisation ne correspond à votre recherche.';

  @override
  String get loadError =>
      'Impossible de charger les données. Vérifiez votre connexion et réessayez.';

  @override
  String get retry => 'Réessayer';

  @override
  String get organizationTypeBank => 'Banque';

  @override
  String get organizationTypeHealth => 'Santé';

  @override
  String get agenciesTitle => 'Agences';

  @override
  String get agenciesEmpty => 'Aucune agence disponible pour le moment.';

  @override
  String queueCountSemantics(Object count) {
    return '$count personnes dans la file';
  }

  @override
  String queueAhead(Object count) {
    return '$count personnes devant vous';
  }

  @override
  String get takeTicket => 'Prendre un ticket';

  @override
  String get ticketNumberLabel => 'Votre numéro de ticket';

  @override
  String ticketPositionLabel(Object position) {
    return 'Position dans la file : $position';
  }

  @override
  String get ticketActiveTitle => 'Ticket actif';

  @override
  String ticketSuccessNote(Object agency) {
    return 'Présentez-vous à $agency.';
  }

  @override
  String get ticketConflictTitle => 'Vous avez déjà un ticket actif';

  @override
  String ticketConflictBody(Object agency, Object number) {
    return 'Un seul ticket actif à la fois. Votre ticket : $number — $agency.';
  }

  @override
  String get viewMyTicket => 'Voir mon ticket';

  @override
  String get backToAgencies => 'Retour aux agences';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get loginSubtitle => 'Connectez-vous pour gérer vos files d\'attente.';

  @override
  String get emailLabel => 'Adresse e-mail';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get noAccount => 'Pas encore de compte ?';

  @override
  String get registerLink => 'Créer un compte';

  @override
  String get registerTitle => 'Inscription';

  @override
  String get registerSubtitle => 'Créez votre compte TONDE.';

  @override
  String get nameLabel => 'Nom complet';

  @override
  String get registerButton => 'S\'inscrire';

  @override
  String get haveAccount => 'Déjà un compte ?';

  @override
  String get loginLink => 'Se connecter';

  @override
  String get invalidCredentials => 'Adresse e-mail ou mot de passe incorrect.';

  @override
  String get emailTaken => 'Cette adresse e-mail est déjà utilisée.';

  @override
  String get fieldRequired => 'Ce champ est obligatoire.';

  @override
  String get tagline => 'Votre temps a de la valeur';

  @override
  String get heroTitle => 'Gérez votre file d\'attente facilement';

  @override
  String get heroBody =>
      'Prenez un ticket, suivez votre position en temps réel et gagnez du temps.';

  @override
  String get heroCta => 'Prendre un ticket';

  @override
  String get peopleAhead => 'personnes avant vous';

  @override
  String estimatedTime(int minutes) {
    return 'Temps estimé : $minutes min';
  }

  @override
  String get seePosition => 'Voir ma position';

  @override
  String get myOrganizations => 'Mes organisations';

  @override
  String get viewAll => 'Voir tout';

  @override
  String get needHelp => 'Besoin d\'aide ?';

  @override
  String get helpBody => 'Notre équipe est là pour vous assister.';

  @override
  String get contact => 'Contacter';

  @override
  String get noActiveTicket => 'Aucun ticket actif';

  @override
  String get noActiveTicketBody =>
      'Prenez un ticket dans une agence pour suivre votre position en temps réel.';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get profileTitle => 'Mon profil';

  @override
  String get aboutTitle => 'À propos';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabTickets => 'Tickets';

  @override
  String get tabNotifications => 'Notifications';

  @override
  String get tabAssistance => 'Assistance';

  @override
  String get tabMore => 'Plus';

  @override
  String get notifWelcome => 'Bienvenue sur TONDE';

  @override
  String get notifWelcomeBody => 'Votre compte de démonstration est prêt.';

  @override
  String get notifQueue => 'Votre file avance';

  @override
  String get notifQueueBody =>
      'Vous gagnez des places dans la file d\'attente.';

  @override
  String get notifAgency => 'Nouvelle agence disponible';

  @override
  String get notifAgencyBody =>
      'De nouvelles agences viennent d\'être ajoutées.';

  @override
  String get profileEmail => 'Adresse e-mail';

  @override
  String get profilePhone => 'Téléphone';

  @override
  String get profileRole => 'Rôle';

  @override
  String get profileOrganization => 'Organisation';

  @override
  String get profileMemberSince => 'Membre depuis';

  @override
  String get profileAccountInfo => 'Informations du compte';

  @override
  String get profileNotAvailable => 'Non renseigné';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get editProfileTitle => 'Modifier mes informations';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get profileUpdated => 'Profil mis à jour';

  @override
  String get profileUpdateFailed => 'Impossible de mettre à jour le profil.';

  @override
  String get invalidEmail => 'Adresse e-mail invalide.';

  @override
  String get invalidPhone => 'Numéro de téléphone invalide.';

  @override
  String get trackingTitle => 'Suivi en direct';

  @override
  String get trackingStatusWaiting => 'En attente';

  @override
  String get trackingStatusCalled => 'Appelé';

  @override
  String get trackingStatusInService => 'En cours';

  @override
  String get trackingStatusAbsent => 'Absent';

  @override
  String get trackingCalledNow => 'Au guichet maintenant';

  @override
  String get trackingYourTicket => 'Votre ticket';

  @override
  String get trackingPosition => 'Votre position';

  @override
  String trackingYouAre(int position) {
    return 'Vous êtes n°$position dans la file';
  }

  @override
  String get trackingQrHint => 'Présentez ce code au guichet';

  @override
  String get trackingLive => 'Direct';

  @override
  String get trackingPolling => 'Mode secours';

  @override
  String trackingUpdatedAt(String time) {
    return 'Mis à jour à $time';
  }

  @override
  String get trackingCalledBanner => 'C\'est votre tour';

  @override
  String get trackingCalledBannerBody => 'Présentez votre QR code au guichet.';

  @override
  String get trackingWaitTime => 'Attente estimée';

  @override
  String trackingMinutesValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get trackingInQueue => 'dans la file';

  @override
  String get offlineMode => 'Mode hors ligne';

  @override
  String get offlineLocalData => 'Affichage des données locales';

  @override
  String get offlinePendingSync => 'En attente de synchronisation';

  @override
  String offlinePendingActions(int count) {
    return '$count action(s) en attente';
  }

  @override
  String get ticketPendingSync => 'Non synchronisé';

  @override
  String get trackingPendingTitle => 'Suivi en attente';

  @override
  String get trackingPendingBody =>
      'Votre ticket est enregistré sur ce téléphone. Le suivi en direct démarrera dès le retour du réseau.';

  @override
  String get ticketPendingTitle => 'Ticket enregistré hors ligne';

  @override
  String get ticketPendingNote =>
      'Il sera confirmé et synchronisé dès le retour du réseau.';

  @override
  String get moreSettings => 'Préférences';

  @override
  String get moreLanguage => 'Langue';

  @override
  String get moreAppearance => 'Apparence';

  @override
  String get languageSystem => 'Système';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutBody =>
      'Application citoyenne de gestion des files d\'attente pour les banques et les établissements de santé au Burundi.';

  @override
  String get ticketDetailsTitle => 'Détails du ticket';

  @override
  String get passYourNumber => 'Votre numéro de ticket';

  @override
  String get passDesk => 'Guichet';

  @override
  String get passDeskPending => 'En attente';

  @override
  String get passPendingQr =>
      'Le QR code apparaîtra dès la synchronisation du ticket.';

  @override
  String get passOpenDetails => 'Voir le détail du ticket';

  @override
  String ticketSemantics(String number, int position) {
    return 'Ticket $number, position $position dans la file';
  }

  @override
  String get detailsQueue => 'File d\'attente';

  @override
  String get detailsInstitution => 'Institution';

  @override
  String get detailsName => 'Nom';

  @override
  String get detailsAgency => 'Agence';

  @override
  String get detailsAddress => 'Adresse';

  @override
  String get detailsTicket => 'Ticket';

  @override
  String get detailsPeopleAhead => 'Personnes devant vous';

  @override
  String get detailsCalledNumber => 'Numéro appelé';

  @override
  String get detailsCounter => 'Guichet';

  @override
  String get detailsIssuedAt => 'Émis le';

  @override
  String get detailsNumber => 'Numéro';

  @override
  String get detailsStatus => 'Statut';

  @override
  String get detailsRefresh => 'Actualiser le suivi';

  @override
  String get detailsRefreshing => 'Actualisation…';

  @override
  String get detailsNotifications => 'Notifications du ticket';

  @override
  String get detailsNotificationsEmpty => 'Aucune notification pour ce ticket.';

  @override
  String get detailsCancel => 'Annuler le ticket';

  @override
  String detailsCancelTitle(String number) {
    return 'Annuler le ticket $number ?';
  }

  @override
  String get detailsCancelBody =>
      'Votre place sera libérée immédiatement. Cette action est définitive : il faudra reprendre un ticket à l\'accueil.';

  @override
  String get detailsCancelKeep => 'Conserver mon ticket';

  @override
  String get detailsCancelConfirm => 'Oui, annuler';

  @override
  String get detailsCancelled => 'Ticket annulé';

  @override
  String get detailsQrTitle => 'Pass de validation';

  @override
  String get servicesTitle => 'Services';

  @override
  String get servicesChooseHint =>
      'Choisissez le service qui correspond à votre demande.';

  @override
  String get servicesEmpty => 'Aucun service disponible pour cette agence.';

  @override
  String get serviceUnavailable =>
      'Ce service n\'est plus proposé par cette agence. Choisissez-en un autre.';

  @override
  String get changeService => 'Changer de service';

  @override
  String get detailsService => 'Service';

  @override
  String get ticketCancelQuestion => 'Voulez-vous annuler le ticket ?';

  @override
  String ticketCancelBody(String number) {
    return 'Le ticket $number sera retiré de la file et votre place sera perdue.';
  }

  @override
  String get backToDashboard => 'Retour au tableau de bord';

  @override
  String get ticketServed => 'Terminé';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingBack => 'Précédent';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get onboardingTitle1 => 'Fini les files d\'attente interminables.';

  @override
  String get onboardingBody1 =>
      'Prenez votre ticket à distance et suivez l\'évolution de la file en temps réel depuis votre téléphone.';

  @override
  String get onboardingTitle2 => 'Arrivez juste à temps.';

  @override
  String get onboardingBody2 =>
      'Visualisez le nombre de personnes avant vous et recevez une alerte dès que votre tour approche.';

  @override
  String get onboardingTitle3 => 'Déjà un ticket papier ? Scannez-le.';

  @override
  String get onboardingBody3 =>
      'Synchronisez votre ticket imprimé sur votre mobile pour patienter où vous voulez sans perdre votre place.';

  @override
  String get ticketServedNote =>
      'Votre passage est terminé. Vous pouvez reprendre un ticket à tout moment.';

  @override
  String notifTicketConfirmedTitle(String number) {
    return 'Votre ticket $number est confirmé';
  }

  @override
  String notifTicketConfirmedBody(String service, String agency) {
    return 'Vous êtes inscrit dans la file $service de l’agence $agency.';
  }

  @override
  String notifProgressTitle(int count) {
    return 'Encore $count personnes avant votre tour';
  }

  @override
  String notifProgressBody(int minutes) {
    return 'Temps d’attente estimé : $minutes minutes. Préparez vos documents.';
  }

  @override
  String get notifApproachingTitle => 'Votre tour approche !';

  @override
  String notifApproachingBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il ne reste que $count personnes avant vous.',
      one: 'Il ne reste qu’une personne avant vous.',
    );
    return '$_temp0 Rapprochez-vous de l’agence.';
  }

  @override
  String get notifCalledTitle => 'C’est votre tour !';

  @override
  String notifCalledBody(String number, String counter) {
    return 'Le ticket $number est appelé au $counter. Présentez-vous immédiatement.';
  }

  @override
  String get notifReminderTitle => 'Votre ticket est toujours appelé';

  @override
  String notifReminderBody(String counter) {
    return 'Veuillez rejoindre le $counter sans attendre.';
  }

  @override
  String get notifAbsentTitle => 'Vous avez été marqué absent';

  @override
  String notifAbsentBody(String number) {
    return 'Le ticket $number a été marqué absent. Consultez l’application pour vérifier les possibilités de reprise.';
  }

  @override
  String get notifResumedTitle => 'Votre ticket a été réactivé';

  @override
  String notifResumedBody(String number) {
    return 'Le ticket $number est de nouveau dans la file d’attente.';
  }

  @override
  String get notifServedTitle => 'Votre passage est terminé';

  @override
  String get notifServedBody => 'Merci d’avoir utilisé TONDE !';

  @override
  String get notifCounterFallback => 'guichet';

  @override
  String get notifCenterEmpty => 'Aucune notification pour le moment';

  @override
  String get notifCenterEmptyBody =>
      'Vous serez prévenu à chaque étape de votre file d’attente.';

  @override
  String get moreNotifications => 'Notifications';

  @override
  String get moreNotificationsSubtitle =>
      'Alertes de file d’attente et appels au guichet';

  @override
  String get notifDelete => 'Supprimer la notification';

  @override
  String notifUnreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count non lues',
      one: '1 non lue',
      zero: 'Aucune non lue',
    );
    return '$_temp0';
  }

  @override
  String get profilePhotoTitle => 'Photo de profil';

  @override
  String get profilePhotoHint => 'Touchez la photo pour la changer';

  @override
  String get profilePhotoCamera => 'Prendre une photo';

  @override
  String get profilePhotoGallery => 'Choisir dans la galerie';

  @override
  String get profilePhotoRemove => 'Supprimer la photo';

  @override
  String get profilePhotoUpdated => 'Photo de profil mise à jour';

  @override
  String get profilePhotoRemoved => 'Photo de profil supprimée';

  @override
  String get profilePhotoFailed =>
      'Impossible de mettre à jour la photo de profil';

  @override
  String get emailInvalid => 'Saisissez une adresse e-mail valide.';

  @override
  String get networkError => 'Serveur injoignable. Vérifiez votre connexion.';

  @override
  String get organizationTypeOther => 'Autre';

  @override
  String get trackingStatusDone => 'Terminé';

  @override
  String get accountDisabled =>
      'Ce compte a été désactivé. Contactez votre organisation.';

  @override
  String get accountLocked =>
      'Trop de tentatives. Réessayez dans quelques minutes.';

  @override
  String get authErrorGeneric => 'La connexion a échoué. Réessayez.';

  @override
  String get passwordTooShort =>
      'Le mot de passe doit contenir au moins 8 caractères.';
}
