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
  String get heroTitleActive => 'Vous êtes dans la file';

  @override
  String get heroBodyActive =>
      'Votre position se met à jour en temps réel. Restez à portée de voix du guichet.';

  @override
  String get resumeTicket => 'Reprendre mon ticket';

  @override
  String get resumeSuccess => 'Votre ticket est de retour dans la file.';

  @override
  String get resumeWindowExpired =>
      'Le délai de reprise est écoulé. Prenez un nouveau ticket.';

  @override
  String get resumeMaxMissed =>
      'Trop d\'absences : la reprise n\'est plus possible. Prenez un nouveau ticket.';

  @override
  String get resumeFailed =>
      'La reprise n\'a pas abouti. Réessayez dans un instant.';

  @override
  String ticketAbsentNote(String time) {
    return 'Vous ne vous êtes pas présenté. Reprenez votre ticket avant $time.';
  }

  @override
  String get ticketClosedServedTitle => 'Votre passage est terminé';

  @override
  String ticketClosedServedBody(String number) {
    return 'Le guichet a clôturé le ticket $number. Vous pouvez en reprendre un quand vous voulez.';
  }

  @override
  String get ticketClosedExpiredTitle => 'Votre ticket a expiré';

  @override
  String ticketClosedExpiredBody(String number) {
    return 'Le ticket $number n\'est plus dans la file. Reprenez un ticket pour être rappelé.';
  }

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
  String get trackingEtaUnavailable => 'Estimation en cours';

  @override
  String trackingCounterPaused(Object counter) {
    return '$counter est en pause.';
  }

  @override
  String trackingCounterPausedUntil(Object counter, Object time) {
    return '$counter est en pause jusqu\'à $time.';
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
  String notifProgressBodyNoEta(Object count) {
    return 'Encore $count personnes avant vous. Préparez vos documents.';
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
  String get moreCallSound => 'Son à l’appel';

  @override
  String get moreCallSoundSubtitle =>
      'Fait sonner le téléphone quand votre numéro est appelé';

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

  @override
  String get assistanceMyTicket => 'Mon ticket';

  @override
  String get assistanceFaq => 'Questions fréquentes';

  @override
  String get assistanceContact => 'Nous contacter';

  @override
  String get assistanceGiveFeedback => 'Donner mon avis';

  @override
  String get assistanceGiveFeedbackBody =>
      'Dites-nous comment s\'est passé votre passage.';

  @override
  String get assistanceReportBug => 'Signaler un problème';

  @override
  String get assistanceReportBugBody =>
      'Quelque chose ne fonctionne pas ? Décrivez-le.';

  @override
  String get assistanceMyFeedback => 'Mes retours';

  @override
  String get assistanceMyFeedbackBody => 'Suivez ce que vous nous avez envoyé.';

  @override
  String get assistanceFeedbackSection => 'Avis et retours';

  @override
  String get assistanceServiceStatus => 'État du service';

  @override
  String get helpCenterTitle => 'Centre d\'aide';

  @override
  String get helpCenterQuestion => 'Comment pouvons-nous vous aider ?';

  @override
  String get helpInstitutionTitle => 'Contacter mon institution';

  @override
  String get helpInstitutionBody =>
      'Une question concernant votre ticket ou le service de l\'agence.';

  @override
  String get helpInstitutionAction => 'Appeler l\'institution';

  @override
  String get helpTondeTitle => 'Contacter TONDE';

  @override
  String get helpTondeBody =>
      'Un problème technique avec l\'application ou votre compte.';

  @override
  String get helpTondeAction => 'Contacter le support';

  @override
  String get helpFaqBody => 'Consultez les réponses aux questions courantes.';

  @override
  String get helpFaqAction => 'Consulter la FAQ';

  @override
  String get helpFeedbackTitle => 'Votre avis compte';

  @override
  String get helpFeedbackBody =>
      'Dites-nous ce que vous voulez voir s\'améliorer dans TONDE.';

  @override
  String get supportTondeSubtitle => 'Support technique de l\'application';

  @override
  String get supportAlwaysOpen => 'Disponible 24 h/24, 7 j/7';

  @override
  String get supportChooseInstitution => 'Choisir mon institution';

  @override
  String get supportInstitutionEmpty =>
      'Aucune institution liée à votre compte.';

  @override
  String get supportInstitutionEmptyBody =>
      'Prenez un ticket ou parcourez les institutions pour trouver leurs coordonnées.';

  @override
  String get supportBrowseInstitutions => 'Parcourir les institutions';

  @override
  String get supportInstitutionNoChannel =>
      'Cette institution n\'a pas publié de coordonnées.';

  @override
  String get supportInstitutionNoChannelBody =>
      'Présentez-vous à l\'agence : le personnel vous répondra sur place.';

  @override
  String get supportCallInstitution => 'Appeler l\'institution';

  @override
  String get supportLoadFailed => 'Impossible de charger les coordonnées.';

  @override
  String get supportClose => 'Fermer';

  @override
  String get faqIntro => 'Les réponses aux questions qu\'on nous pose le plus.';

  @override
  String get feedbackIntro =>
      'Dites-nous ce qui marche, ce qui bloque, ou ce qui manque.';

  @override
  String get feedbackThanksTitle => 'Merci !';

  @override
  String get feedbackThanksBody =>
      'Votre message est bien arrivé. Nous le lisons tous les jours.';

  @override
  String get serviceReachable => 'Service joignable';

  @override
  String get serviceUnreachable => 'Service injoignable';

  @override
  String get faqTakeTicketTitle => 'Comment prendre un ticket ?';

  @override
  String get faqTakeTicketBody =>
      'Ouvrez l\'accueil, choisissez l\'organisation, l\'agence et le service, puis confirmez. Votre ticket apparaît aussitôt avec votre position.';

  @override
  String get faqAbsentTitle => 'Je n\'ai pas entendu mon appel, que faire ?';

  @override
  String get faqAbsentBody =>
      'Votre ticket passe en « absent » mais garde sa place un moment. Depuis l\'accueil, appuyez sur « Reprendre mon ticket » avant l\'heure affichée : vous retrouvez la file, à la fin de votre priorité.';

  @override
  String get faqExpiredTitle => 'Mon ticket a expiré';

  @override
  String get faqExpiredBody =>
      'Un ticket non réclamé à temps quitte la file. Prenez-en un nouveau : votre position sera calculée sur la file du moment.';

  @override
  String get faqPausedTitle => 'Le guichet est en pause';

  @override
  String get faqPausedBody =>
      'L\'heure de reprise s\'affiche sous le nom du guichet. Votre position ne bouge pas pendant la pause : seul le temps d\'attente estimé est reporté.';

  @override
  String get faqNotificationsTitle => 'Je ne reçois pas de notifications';

  @override
  String get faqNotificationsBody =>
      'Vérifiez que les notifications sont autorisées pour TONDE dans les réglages du téléphone, et que le mode silencieux n\'est pas actif. L\'application reste utilisable sans elles : le suivi s\'affiche à l\'écran.';

  @override
  String get faqTwoTicketsTitle => 'Puis-je prendre deux tickets ?';

  @override
  String get faqTwoTicketsBody =>
      'Non. Un seul ticket actif par compte, toutes organisations confondues : c\'est ce qui garantit que la file reste honnête pour tout le monde.';

  @override
  String get feedbackReviewTitle => 'Donner mon avis';

  @override
  String get feedbackBugTitle => 'Signaler un problème';

  @override
  String get feedbackCategory => 'Catégorie';

  @override
  String get feedbackCategoryReview => 'Avis';

  @override
  String get feedbackCategoryBug => 'Problème';

  @override
  String get feedbackCategorySuggestion => 'Suggestion';

  @override
  String get feedbackRating => 'Votre note';

  @override
  String get feedbackRatingHint => 'Facultatif';

  @override
  String get feedbackMessage => 'Votre message';

  @override
  String get feedbackMessageHint =>
      'Décrivez ce qui s\'est passé, en quelques phrases.';

  @override
  String feedbackMessageCounter(int count) {
    return '$count/1000';
  }

  @override
  String feedbackMessageTooShort(int count) {
    return 'Encore $count caractères.';
  }

  @override
  String get feedbackSubmit => 'Envoyer';

  @override
  String get feedbackSent => 'Merci, votre retour est envoyé.';

  @override
  String get feedbackRateLimited =>
      'Vous avez envoyé plusieurs retours récemment. Réessayez dans une heure.';

  @override
  String get feedbackAlreadySent =>
      'Vous avez déjà signalé ce ticket dans cette catégorie.';

  @override
  String get feedbackFailed => 'L\'envoi a échoué. Réessayez.';

  @override
  String get feedbackPrivacyNote =>
      'Votre retour est associé à votre compte et n\'est jamais publié.';

  @override
  String get feedbackHistoryTitle => 'Mes retours';

  @override
  String get feedbackHistoryEmpty => 'Aucun retour envoyé';

  @override
  String get feedbackHistoryEmptyBody =>
      'Vos avis et signalements apparaîtront ici, avec leur état de traitement.';

  @override
  String get feedbackStatusReceived => 'Reçu';

  @override
  String get feedbackStatusRead => 'Lu';

  @override
  String get feedbackStatusResolved => 'Traité';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactCall => 'Appeler';

  @override
  String get contactEmail => 'E-mail';

  @override
  String get contactNoChannel =>
      'Aucun moyen de contact n\'est configuré pour cette organisation.';

  @override
  String get contactOpenFailed => 'Impossible d\'ouvrir cette application.';

  @override
  String get errOfflineDetail =>
      'Vérifiez votre connexion, puis réessayez. Rien n\'a été perdu.';

  @override
  String get errTicketActive => 'Vous avez déjà un ticket en cours.';

  @override
  String get errTicketActiveDetail =>
      'Un seul ticket à la fois. Suivez celui-ci, ou annulez-le avant d\'en prendre un autre.';

  @override
  String get errBranchClosed => 'Cette agence est fermée.';

  @override
  String get errBranchClosedDetail =>
      'Les tickets ne peuvent être pris que pendant les heures d\'ouverture.';

  @override
  String get errDailyLimit => 'La limite de tickets du jour est atteinte.';

  @override
  String get errDailyLimitDetail =>
      'Réessayez demain, ou choisissez une autre agence.';

  @override
  String get errRateLimited => 'Trop de tentatives.';

  @override
  String get errRateLimitedDetail => 'Patientez un instant avant de réessayer.';

  @override
  String get errGracePeriod => 'Votre ticket n\'est pas encore reprenable.';

  @override
  String get errGracePeriodDetail =>
      'Le guichet vient de vous appeler. Attendez la fin du délai, puis réessayez.';

  @override
  String get errTicketGone => 'Ce ticket n\'existe plus.';

  @override
  String get errTicketGoneDetail =>
      'Il a peut-être été clôturé entre-temps. Prenez-en un nouveau si besoin.';

  @override
  String get errServer => 'Le service a rencontré un problème.';

  @override
  String get errServerDetail =>
      'Ce n\'est pas de votre fait. Réessayez dans un instant.';

  @override
  String get errValidation => 'Certaines informations sont invalides.';

  @override
  String get errForbidden =>
      'Cette action n\'est pas autorisée pour votre compte.';

  @override
  String get errUnexpected => 'Une erreur inattendue est survenue.';

  @override
  String get errUnexpectedDetail =>
      'Réessayez. Si cela persiste, signalez-le depuis l\'assistance.';

  @override
  String get errInProgress => 'Une demande identique est déjà en cours.';

  @override
  String get errTechnicalDetails => 'Détails techniques';

  @override
  String get actionChooseService => 'Choisir un service';

  @override
  String get actionTakeNewTicket => 'Prendre un ticket';

  @override
  String get actionWait => 'Patientez';

  @override
  String errRateLimitedSeconds(int seconds) {
    return 'Trop de tentatives. Patientez $seconds secondes.';
  }

  @override
  String errIncident(String id) {
    return 'Référence : $id';
  }

  @override
  String get widgetEmptyTitle => 'Aucun ticket';

  @override
  String get widgetEmptyBody => 'Touchez pour en prendre un';

  @override
  String widgetPosition(int position) {
    return 'Position $position';
  }

  @override
  String widgetEta(int minutes) {
    return '≈ $minutes min';
  }

  @override
  String widgetUpdated(String time) {
    return 'Mis à jour à $time';
  }

  @override
  String get widgetCounterPaused => 'Guichet en pause';

  @override
  String widgetCounterPausedUntil(String time) {
    return 'Pause jusqu\'à $time';
  }

  @override
  String get moreHomeWidget => 'Widget d\'écran d\'accueil';

  @override
  String get moreHomeWidgetSubtitle =>
      'Votre ticket visible sans ouvrir l\'application';

  @override
  String get homeWidgetPinConfirm =>
      'Confirmez l\'ajout dans la fenêtre du lanceur.';

  @override
  String get homeWidgetPinUnsupported =>
      'Votre lanceur ne permet pas d\'ajouter le widget depuis l\'application. Ajoutez-le depuis l\'écran d\'accueil.';

  @override
  String get homeWidgetInviteTitle => 'Suivez votre position depuis l\'accueil';

  @override
  String get homeWidgetInviteBody =>
      'Ajoutez le widget TONDE pour voir votre numéro, votre position et l\'attente sans ouvrir l\'application.';

  @override
  String get homeWidgetInviteAccept => 'Ajouter le widget';

  @override
  String get homeWidgetInviteLater => 'Plus tard';
}
