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
  String get emailLabel => 'Email address';

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
  String get invalidCredentials => 'Incorrect email address or password.';

  @override
  String get emailTaken => 'This email address is already in use.';

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
  String get heroTitleActive => 'You\'re in the queue';

  @override
  String get heroBodyActive =>
      'Your position updates in real time. Stay within earshot of the counter.';

  @override
  String get resumeTicket => 'Resume my ticket';

  @override
  String get resumeSuccess => 'Your ticket is back in the queue.';

  @override
  String get resumeWindowExpired =>
      'The recovery window has closed. Take a new ticket.';

  @override
  String get resumeMaxMissed =>
      'Too many missed calls: you can no longer resume. Take a new ticket.';

  @override
  String get resumeFailed =>
      'The ticket could not be resumed. Try again in a moment.';

  @override
  String ticketAbsentNote(String time) {
    return 'You didn\'t show up. Resume your ticket before $time.';
  }

  @override
  String get ticketClosedServedTitle => 'Your visit is complete';

  @override
  String ticketClosedServedBody(String number) {
    return 'The counter closed ticket $number. You can take another one whenever you like.';
  }

  @override
  String get ticketClosedExpiredTitle => 'Your ticket has expired';

  @override
  String ticketClosedExpiredBody(String number) {
    return 'Ticket $number is no longer in the queue. Take a new ticket to be called again.';
  }

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
  String get trackingEtaUnavailable => 'Estimating…';

  @override
  String trackingCounterPaused(Object counter) {
    return '$counter is paused.';
  }

  @override
  String trackingCounterPausedUntil(Object counter, Object time) {
    return '$counter is paused until $time.';
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
  String notifProgressBodyNoEta(Object count) {
    return '$count people still ahead of you. Get your documents ready.';
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
  String get moreCallSound => 'Call sound';

  @override
  String get moreCallSoundSubtitle => 'Rings when your number is called';

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

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get networkError => 'Server unreachable. Check your connection.';

  @override
  String get organizationTypeOther => 'Other';

  @override
  String get trackingStatusDone => 'Completed';

  @override
  String get accountDisabled =>
      'This account has been disabled. Contact your organization.';

  @override
  String get accountLocked => 'Too many attempts. Try again in a few minutes.';

  @override
  String get authErrorGeneric => 'Sign-in failed. Try again.';

  @override
  String get passwordTooShort =>
      'The password must be at least 8 characters long.';

  @override
  String get assistanceMyTicket => 'My ticket';

  @override
  String get assistanceFaq => 'Frequently asked questions';

  @override
  String get assistanceContact => 'Contact us';

  @override
  String get assistanceGiveFeedback => 'Give feedback';

  @override
  String get assistanceGiveFeedbackBody => 'Tell us how your visit went.';

  @override
  String get assistanceReportBug => 'Report a problem';

  @override
  String get assistanceReportBugBody => 'Something not working? Describe it.';

  @override
  String get assistanceMyFeedback => 'My feedback';

  @override
  String get assistanceMyFeedbackBody => 'Track what you have sent us.';

  @override
  String get assistanceFeedbackSection => 'Reviews and feedback';

  @override
  String get assistanceServiceStatus => 'Service status';

  @override
  String get helpCenterTitle => 'Help center';

  @override
  String get helpCenterQuestion => 'How can we help you?';

  @override
  String get helpInstitutionTitle => 'Contact my institution';

  @override
  String get helpInstitutionBody =>
      'A question about your ticket or the agency\'s service.';

  @override
  String get helpInstitutionAction => 'Call the institution';

  @override
  String get helpTondeTitle => 'Contact TONDE';

  @override
  String get helpTondeBody =>
      'A technical problem with the app or your account.';

  @override
  String get helpTondeAction => 'Contact support';

  @override
  String get helpFaqBody => 'Read the answers to common questions.';

  @override
  String get helpFaqAction => 'Read the FAQ';

  @override
  String get helpFeedbackTitle => 'Your feedback matters';

  @override
  String get helpFeedbackBody =>
      'Tell us what you would like to see improved in TONDE.';

  @override
  String get supportTondeSubtitle => 'App technical support';

  @override
  String get supportAlwaysOpen => 'Available 24/7';

  @override
  String get supportChooseInstitution => 'Choose my institution';

  @override
  String get supportInstitutionEmpty =>
      'No institution is linked to your account.';

  @override
  String get supportInstitutionEmptyBody =>
      'Take a ticket or browse the institutions to find their contact details.';

  @override
  String get supportBrowseInstitutions => 'Browse institutions';

  @override
  String get supportInstitutionNoChannel =>
      'This institution has not published contact details.';

  @override
  String get supportInstitutionNoChannelBody =>
      'Go to the agency: the staff will answer you on site.';

  @override
  String get supportCallInstitution => 'Call the institution';

  @override
  String get supportLoadFailed => 'Could not load the contact details.';

  @override
  String get supportClose => 'Close';

  @override
  String get faqIntro => 'The answers to the questions we get most often.';

  @override
  String get feedbackIntro =>
      'Tell us what works, what is broken, or what is missing.';

  @override
  String get feedbackThanksTitle => 'Thank you!';

  @override
  String get feedbackThanksBody =>
      'Your message has arrived. We read them every day.';

  @override
  String get serviceReachable => 'Service reachable';

  @override
  String get serviceUnreachable => 'Service unreachable';

  @override
  String get faqTakeTicketTitle => 'How do I take a ticket?';

  @override
  String get faqTakeTicketBody =>
      'Open the home screen, pick the organisation, the branch and the service, then confirm. Your ticket appears right away with your position.';

  @override
  String get faqAbsentTitle => 'I missed my call, what now?';

  @override
  String get faqAbsentBody =>
      'Your ticket switches to \"absent\" but keeps its place for a while. From the home screen, tap \"Resume my ticket\" before the time shown: you rejoin the queue at the end of your priority band.';

  @override
  String get faqExpiredTitle => 'My ticket expired';

  @override
  String get faqExpiredBody =>
      'A ticket nobody claims in time leaves the queue. Take a new one: your position will be computed from the queue at that moment.';

  @override
  String get faqPausedTitle => 'The counter is paused';

  @override
  String get faqPausedBody =>
      'The resumption time is shown under the counter name. Your position does not move during the pause: only the estimated wait is pushed back.';

  @override
  String get faqNotificationsTitle => 'I am not getting notifications';

  @override
  String get faqNotificationsBody =>
      'Check that notifications are allowed for TONDE in your phone settings, and that silent mode is off. The app works without them: tracking stays on screen.';

  @override
  String get faqTwoTicketsTitle => 'Can I take two tickets?';

  @override
  String get faqTwoTicketsBody =>
      'No. One active ticket per account, across all organisations: that is what keeps the queue honest for everyone.';

  @override
  String get feedbackReviewTitle => 'Give feedback';

  @override
  String get feedbackBugTitle => 'Report a problem';

  @override
  String get feedbackCategory => 'Category';

  @override
  String get feedbackCategoryReview => 'Review';

  @override
  String get feedbackCategoryBug => 'Problem';

  @override
  String get feedbackCategorySuggestion => 'Suggestion';

  @override
  String get feedbackRating => 'Your rating';

  @override
  String get feedbackRatingHint => 'Optional';

  @override
  String get feedbackMessage => 'Your message';

  @override
  String get feedbackMessageHint =>
      'Describe what happened, in a few sentences.';

  @override
  String feedbackMessageCounter(int count) {
    return '$count/1000';
  }

  @override
  String feedbackMessageTooShort(int count) {
    return '$count characters to go.';
  }

  @override
  String get feedbackSubmit => 'Send';

  @override
  String get feedbackSent => 'Thank you, your feedback has been sent.';

  @override
  String get feedbackRateLimited =>
      'You have sent several reports recently. Try again in an hour.';

  @override
  String get feedbackAlreadySent =>
      'You already reported this ticket in this category.';

  @override
  String get feedbackFailed => 'Sending failed. Try again.';

  @override
  String get feedbackPrivacyNote =>
      'Your feedback is tied to your account and is never published.';

  @override
  String get feedbackHistoryTitle => 'My feedback';

  @override
  String get feedbackHistoryEmpty => 'No feedback sent';

  @override
  String get feedbackHistoryEmptyBody =>
      'Your reviews and reports will appear here, with how they are being handled.';

  @override
  String get feedbackStatusReceived => 'Received';

  @override
  String get feedbackStatusRead => 'Read';

  @override
  String get feedbackStatusResolved => 'Resolved';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactCall => 'Call';

  @override
  String get contactEmail => 'Email';

  @override
  String get contactNoChannel =>
      'No contact method is configured for this organisation.';

  @override
  String get contactOpenFailed => 'Could not open that app.';

  @override
  String get errOfflineDetail =>
      'Check your connection, then try again. Nothing was lost.';

  @override
  String get errTicketActive => 'You already have a ticket in progress.';

  @override
  String get errTicketActiveDetail =>
      'One ticket at a time. Track this one, or cancel it before taking another.';

  @override
  String get errBranchClosed => 'This branch is closed.';

  @override
  String get errBranchClosedDetail =>
      'Tickets can only be taken during opening hours.';

  @override
  String get errDailyLimit => 'Today\'s ticket limit has been reached.';

  @override
  String get errDailyLimitDetail =>
      'Try again tomorrow, or choose another branch.';

  @override
  String get errRateLimited => 'Too many attempts.';

  @override
  String get errRateLimitedDetail => 'Wait a moment before trying again.';

  @override
  String get errGracePeriod => 'Your ticket cannot be resumed yet.';

  @override
  String get errGracePeriodDetail =>
      'The counter has just called you. Wait until the delay ends, then try again.';

  @override
  String get errTicketGone => 'That ticket no longer exists.';

  @override
  String get errTicketGoneDetail =>
      'It may have been closed in the meantime. Take a new one if needed.';

  @override
  String get errServer => 'The service ran into a problem.';

  @override
  String get errServerDetail =>
      'This is not your fault. Try again in a moment.';

  @override
  String get errValidation => 'Some information is invalid.';

  @override
  String get errForbidden => 'This action is not allowed for your account.';

  @override
  String get errUnexpected => 'An unexpected error occurred.';

  @override
  String get errUnexpectedDetail =>
      'Try again. If it persists, report it from the help tab.';

  @override
  String get errInProgress => 'An identical request is already in progress.';

  @override
  String get errTechnicalDetails => 'Technical details';

  @override
  String get actionChooseService => 'Choose a service';

  @override
  String get actionTakeNewTicket => 'Take a ticket';

  @override
  String get actionWait => 'Please wait';

  @override
  String errRateLimitedSeconds(int seconds) {
    return 'Too many attempts. Wait $seconds seconds.';
  }

  @override
  String errIncident(String id) {
    return 'Reference: $id';
  }

  @override
  String get widgetEmptyTitle => 'No ticket';

  @override
  String get widgetEmptyBody => 'Tap to get one';

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
    return 'Updated at $time';
  }

  @override
  String get widgetCounterPaused => 'Desk paused';

  @override
  String widgetCounterPausedUntil(String time) {
    return 'Paused until $time';
  }

  @override
  String get moreHomeWidget => 'Home screen widget';

  @override
  String get moreHomeWidgetSubtitle =>
      'Your ticket at a glance, without opening the app';

  @override
  String get homeWidgetPinConfirm =>
      'Confirm the addition in your launcher\'s dialog.';

  @override
  String get homeWidgetPinUnsupported =>
      'Your launcher doesn\'t allow adding the widget from the app. Add it from your home screen.';

  @override
  String get homeWidgetInviteTitle => 'Follow your place from your home screen';

  @override
  String get homeWidgetInviteBody =>
      'Add the TONDE widget to see your number, your place and the wait without opening the app.';

  @override
  String get homeWidgetInviteAccept => 'Add the widget';

  @override
  String get homeWidgetInviteLater => 'Later';
}
