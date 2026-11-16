// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TONDE';

  @override
  String get foundationTitle => 'Technical foundation';

  @override
  String get foundationStatus => 'Phase 1 — Foundation';

  @override
  String get foundationDescription =>
      'This application is under construction. No banking or health data is connected yet.';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundDescription => 'The requested page does not exist.';

  @override
  String get backToHome => 'Back to home';

  @override
  String get organizationsSearchHint => 'Search for an organization';

  @override
  String get organizationsEmpty => 'No organizations available.';

  @override
  String get organizationsNoResults => 'No organizations match your search.';

  @override
  String get loadError =>
      'Unable to load data. Check your connection and try again.';

  @override
  String get retry => 'Retry';

  @override
  String get organizationTypeBank => 'Bank';

  @override
  String get organizationTypeHealth => 'Health';

  @override
  String get agenciesTitle => 'Agencies';

  @override
  String get agenciesEmpty => 'No agencies available yet.';

  @override
  String queueCountSemantics(Object count) {
    return '$count people in the queue';
  }

  @override
  String queueAhead(Object count) {
    return '$count people ahead of you';
  }

  @override
  String get takeTicket => 'Take a ticket';

  @override
  String get ticketNumberLabel => 'Your ticket number';

  @override
  String ticketPositionLabel(Object position) {
    return 'Position in the queue: $position';
  }

  @override
  String get ticketActiveTitle => 'Active ticket';

  @override
  String ticketSuccessNote(Object agency) {
    return 'Go to the $agency branch.';
  }

  @override
  String get ticketConflictTitle => 'You already have an active ticket';

  @override
  String ticketConflictBody(Object agency, Object number) {
    return 'Only one active ticket at a time. Your ticket: $number — $agency.';
  }

  @override
  String get viewMyTicket => 'View my ticket';

  @override
  String get backToAgencies => 'Back to agencies';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle => 'Sign in to manage your queues.';

  @override
  String get usernameLabel => 'Username';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Sign in';

  @override
  String get noAccount => 'No account yet?';

  @override
  String get registerLink => 'Create an account';

  @override
  String get registerTitle => 'Sign up';

  @override
  String get registerSubtitle => 'Create your TONDE account.';

  @override
  String get nameLabel => 'Full name';

  @override
  String get registerButton => 'Sign up';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get loginLink => 'Sign in';

  @override
  String get invalidCredentials => 'Incorrect username or password.';

  @override
  String get usernameTaken => 'This username is already in use.';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get tagline => 'Your time matters';

  @override
  String get heroTitle => 'Manage your queue easily';

  @override
  String get heroBody =>
      'Take a ticket, track your position in real time and save time.';

  @override
  String get heroCta => 'Take a ticket';

  @override
  String get peopleAhead => 'people ahead of you';

  @override
  String estimatedTime(int minutes) {
    return 'Estimated time: $minutes min';
  }

  @override
  String get seePosition => 'See my position';

  @override
  String get myOrganizations => 'My organizations';

  @override
  String get viewAll => 'View all';

  @override
  String get needHelp => 'Need help?';

  @override
  String get helpBody => 'Our team is here to assist you.';

  @override
  String get contact => 'Contact';

  @override
  String get noActiveTicket => 'No active ticket';

  @override
  String get noActiveTicketBody =>
      'Take a ticket at an agency to track your position in real time.';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get logout => 'Sign out';

  @override
  String get profileTitle => 'My profile';

  @override
  String get aboutTitle => 'About';

  @override
  String get tabHome => 'Home';

  @override
  String get tabTickets => 'Tickets';

  @override
  String get tabNotifications => 'Notifications';

  @override
  String get tabAssistance => 'Assistance';

  @override
  String get tabMore => 'More';

  @override
  String get notifWelcome => 'Welcome to TONDE';

  @override
  String get notifWelcomeBody => 'Your demo account is ready.';

  @override
  String get notifQueue => 'Your queue is moving';

  @override
  String get notifQueueBody => 'You are moving up in the queue.';

  @override
  String get notifAgency => 'New agency available';

  @override
  String get notifAgencyBody => 'New agencies have just been added.';

  @override
  String get profileEmail => 'Email address';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profileRole => 'Role';

  @override
  String get profileOrganization => 'Organization';

  @override
  String get profileMemberSince => 'Member since';

  @override
  String get profileAccountInfo => 'Account information';

  @override
  String get profileNotAvailable => 'Not provided';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get editProfileTitle => 'Edit my information';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get profileUpdateFailed => 'Unable to update the profile.';

  @override
  String get invalidEmail => 'Invalid email address.';

  @override
  String get invalidPhone => 'Invalid phone number.';

  @override
  String get trackingTitle => 'Live tracking';

  @override
  String get trackingStatusWaiting => 'Waiting';

  @override
  String get trackingStatusCalled => 'Called';

  @override
  String get trackingStatusInService => 'In service';

  @override
  String get trackingStatusAbsent => 'Absent';

  @override
  String get trackingCalledNow => 'Now at the counter';

  @override
  String get trackingYourTicket => 'Your ticket';

  @override
  String get trackingPosition => 'Your position';

  @override
  String trackingYouAre(int position) {
    return 'You are #$position in line';
  }

  @override
  String get trackingQrHint => 'Show this code at the counter';

  @override
  String get trackingLive => 'Live';

  @override
  String get trackingPolling => 'Fallback';

  @override
  String trackingUpdatedAt(String time) {
    return 'Updated at $time';
  }

  @override
  String get trackingCalledBanner => 'It\'s your turn';

  @override
  String get trackingCalledBannerBody => 'Show your QR code at the counter.';

  @override
  String get trackingWaitTime => 'Estimated wait';

  @override
  String trackingMinutesValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get trackingInQueue => 'in the queue';

  @override
  String get offlineMode => 'Offline mode';

  @override
  String get offlineLocalData => 'Showing local data';

  @override
  String get offlinePendingSync => 'Waiting to sync';

  @override
  String offlinePendingActions(int count) {
    return '$count action(s) pending';
  }

  @override
  String get ticketPendingSync => 'Not synced';

  @override
  String get trackingPendingTitle => 'Tracking pending';

  @override
  String get trackingPendingBody =>
      'Your ticket is saved on this phone. Live tracking will start as soon as the network is back.';

  @override
  String get ticketPendingTitle => 'Ticket saved offline';

  @override
  String get ticketPendingNote =>
      'It will be confirmed and synced as soon as the network is back.';

  @override
  String get moreSettings => 'Preferences';

  @override
  String get moreLanguage => 'Language';

  @override
  String get moreAppearance => 'Appearance';

  @override
  String get languageSystem => 'System';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutBody =>
      'Citizen app for managing queues in banks and health facilities in Burundi.';

  @override
  String get ticketDetailsTitle => 'Ticket details';

  @override
  String get passYourNumber => 'Your ticket number';

  @override
  String get passDesk => 'Counter';

  @override
  String get passDeskPending => 'Pending';

  @override
  String get passPendingQr =>
      'The QR code will appear once the ticket is synced.';

  @override
  String get passOpenDetails => 'View ticket details';

  @override
  String ticketSemantics(String number, int position) {
    return 'Ticket $number, position $position in the queue';
  }

  @override
  String get detailsQueue => 'Queue';

  @override
  String get detailsInstitution => 'Institution';

  @override
  String get detailsName => 'Name';

  @override
  String get detailsAgency => 'Branch';

  @override
  String get detailsAddress => 'Address';

  @override
  String get detailsTicket => 'Ticket';

  @override
  String get detailsPeopleAhead => 'People ahead of you';

  @override
  String get detailsCalledNumber => 'Now calling';

  @override
  String get detailsCounter => 'Counter';

  @override
  String get detailsIssuedAt => 'Issued at';

  @override
  String get detailsNumber => 'Number';

  @override
  String get detailsStatus => 'Status';

  @override
  String get detailsRefresh => 'Refresh tracking';

  @override
  String get detailsRefreshing => 'Refreshing…';

  @override
  String get detailsNotifications => 'Ticket notifications';

  @override
  String get detailsNotificationsEmpty => 'No notifications for this ticket.';

  @override
  String get detailsCancel => 'Cancel ticket';

  @override
  String detailsCancelTitle(String number) {
    return 'Cancel ticket $number?';
  }

  @override
  String get detailsCancelBody =>
      'Your place will be released immediately. This cannot be undone: you will need to take a new ticket.';

  @override
  String get detailsCancelKeep => 'Keep my ticket';

  @override
  String get detailsCancelConfirm => 'Yes, cancel';

  @override
  String get detailsCancelled => 'Ticket cancelled';

  @override
  String get detailsQrTitle => 'Validation pass';

  @override
  String get servicesTitle => 'Services';

  @override
  String get servicesChooseHint => 'Choose the service you need.';

  @override
  String get servicesEmpty => 'No services available for this branch.';

  @override
  String get serviceUnavailable =>
      'This service is no longer offered by this branch. Please choose another one.';

  @override
  String get changeService => 'Change service';

  @override
  String get detailsService => 'Service';

  @override
  String get ticketCancelQuestion => 'Do you want to cancel the ticket?';

  @override
  String ticketCancelBody(String number) {
    return 'Ticket $number will be removed from the queue and your place will be lost.';
  }

  @override
  String get backToDashboard => 'Back to dashboard';

  @override
  String get ticketServed => 'Completed';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingTitle1 => 'No more endless queues.';

  @override
  String get onboardingBody1 =>
      'Take your ticket remotely and follow the queue in real time from your phone.';

  @override
  String get onboardingTitle2 => 'Arrive right on time.';

  @override
  String get onboardingBody2 =>
      'See how many people are ahead of you and get an alert when your turn approaches.';

  @override
  String get onboardingTitle3 => 'Already have a paper ticket? Scan it.';

  @override
  String get onboardingBody3 =>
      'Sync your printed ticket to your phone and wait anywhere without losing your place.';

  @override
  String get ticketServedNote =>
      'You\'re all set. You can take another ticket whenever you need.';

  @override
  String notifTicketConfirmedTitle(String number) {
    return 'Your ticket $number is confirmed';
  }

  @override
  String notifTicketConfirmedBody(String service, String agency) {
    return 'You’re in the $service queue at $agency.';
  }

  @override
  String notifProgressTitle(int count) {
    return '$count people ahead of you';
  }

  @override
  String notifProgressBody(int minutes) {
    return 'Estimated wait: $minutes minutes. Get your documents ready.';
  }

  @override
  String get notifApproachingTitle => 'Your turn is coming up!';

  @override
  String notifApproachingBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Only $count people are ahead of you.',
      one: 'Only one person is ahead of you.',
    );
    return '$_temp0 Head to the agency.';
  }

  @override
  String get notifCalledTitle => 'It’s your turn!';

  @override
  String notifCalledBody(String number, String counter) {
    return 'Ticket $number is being called at $counter. Please come forward now.';
  }

  @override
  String get notifReminderTitle => 'Your ticket is still being called';

  @override
  String notifReminderBody(String counter) {
    return 'Please go to $counter right away.';
  }

  @override
  String get notifAbsentTitle => 'You were marked absent';

  @override
  String notifAbsentBody(String number) {
    return 'Ticket $number was marked absent. Check the app to see how to get back in line.';
  }

  @override
  String get notifResumedTitle => 'Your ticket is active again';

  @override
  String notifResumedBody(String number) {
    return 'Ticket $number is back in the queue.';
  }

  @override
  String get notifServedTitle => 'Your visit is complete';

  @override
  String get notifServedBody => 'Thanks for using TONDE!';

  @override
  String get notifCounterFallback => 'counter';

  @override
  String get notifCenterEmpty => 'No notifications yet';

  @override
  String get notifCenterEmptyBody =>
      'You’ll be notified at every step of your queue.';

  @override
  String get moreNotifications => 'Notifications';

  @override
  String get moreNotificationsSubtitle => 'Queue alerts and counter calls';

  @override
  String get notifDelete => 'Delete notification';

  @override
  String notifUnreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread',
      one: '1 unread',
      zero: 'None unread',
    );
    return '$_temp0';
  }

  @override
  String get profilePhotoTitle => 'Profile photo';

  @override
  String get profilePhotoHint => 'Tap the photo to change it';

  @override
  String get profilePhotoCamera => 'Take a photo';

  @override
  String get profilePhotoGallery => 'Choose from gallery';

  @override
  String get profilePhotoRemove => 'Remove photo';

  @override
  String get profilePhotoUpdated => 'Profile photo updated';

  @override
  String get profilePhotoRemoved => 'Profile photo removed';

  @override
  String get profilePhotoFailed => 'Could not update the profile photo';
}
