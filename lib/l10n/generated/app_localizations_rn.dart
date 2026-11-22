// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Rundi (`rn`).
class AppLocalizationsRn extends AppLocalizations {
  AppLocalizationsRn([String locale = 'rn']) : super(locale);

  @override
  String get appTitle => 'TONDE';

  @override
  String get foundationTitle => 'Ishingiro ry\'ubuhanga';

  @override
  String get foundationStatus => 'Icyiciro ca 1 — Ishingiro';

  @override
  String get foundationDescription =>
      'Iyi porogaramu iracyubakwa. Nta makuru y\'amabanki canke y\'ubuzima arahujwe na yo.';

  @override
  String get notFoundTitle => 'Urupapuro ntirubonetse';

  @override
  String get notFoundDescription => 'Urupapuro mwasavye ntirubaho.';

  @override
  String get backToHome => 'Subira ahabanza';

  @override
  String get organizationsSearchHint => 'Rondera ishirahamwe';

  @override
  String get organizationsEmpty => 'Nta shirahamwe riboneka.';

  @override
  String get organizationsNoResults =>
      'Nta shirahamwe rihuye n\'ivyo warondera.';

  @override
  String get loadError =>
      'Ntibishoboka kuronka amakuru. Raba urusamaro hanyuma ugerageze ubundi.';

  @override
  String get retry => 'Subira ugerageze';

  @override
  String get organizationTypeBank => 'Ibanki';

  @override
  String get organizationTypeHealth => 'Ubuzima';

  @override
  String get agenciesTitle => 'Amashami';

  @override
  String get agenciesEmpty => 'Nta shami riboneka kuri ubu.';

  @override
  String queueCountSemantics(Object count) {
    return '$count bantu bari muri umurongo';
  }

  @override
  String queueAhead(Object count) {
    return '$count bantu imbere yawe';
  }

  @override
  String get takeTicket => 'Fata itike';

  @override
  String get ticketNumberLabel => 'Nomero y\'itike ryawe';

  @override
  String ticketPositionLabel(Object position) {
    return 'Umwanya muri umurongo: $position';
  }

  @override
  String get ticketActiveTitle => 'Itike iriho';

  @override
  String ticketSuccessNote(Object agency) {
    return 'Ja ku biro vya $agency.';
  }

  @override
  String get ticketConflictTitle => 'Ufise itike iriho';

  @override
  String ticketConflictBody(Object agency, Object number) {
    return 'Ni itike imwe gusa ikora icyarimwe. Itike yawe: $number — $agency.';
  }

  @override
  String get viewMyTicket => 'Raba itike yanje';

  @override
  String get backToAgencies => 'Subira ku mashami';

  @override
  String get loginTitle => 'Kwinjira';

  @override
  String get loginSubtitle => 'Injira kugira utunganye imirongo yawe.';

  @override
  String get emailLabel => 'Aderesi imeyili';

  @override
  String get passwordLabel => 'Ijambo ry\'ibanga';

  @override
  String get loginButton => 'Injira';

  @override
  String get noAccount => 'Nta konti ufise?';

  @override
  String get registerLink => 'Fungura konti';

  @override
  String get registerTitle => 'Kwiyandikisha';

  @override
  String get registerSubtitle => 'Fungura konti yawe ya TONDE.';

  @override
  String get nameLabel => 'Amazina yose';

  @override
  String get registerButton => 'Iyandikishe';

  @override
  String get haveAccount => 'Ufise konti?';

  @override
  String get loginLink => 'Injira';

  @override
  String get invalidCredentials =>
      'Aderesi imeyili canke ijambo ry\'ibanga ntivyo.';

  @override
  String get emailTaken => 'Iyi aderesi imeyili isanzwe ikoreshwa.';

  @override
  String get fieldRequired => 'Iki kibanza kirakenewe.';

  @override
  String get tagline => 'Igihe cawe ni ngirakamaro';

  @override
  String get heroTitle => 'Tunganya umurongo wawe n\'ukwegeranye';

  @override
  String get heroBody =>
      'Fata itike, kurikira umwanya wawe uko bitasiba hanyuma uzigame umwanya.';

  @override
  String get heroCta => 'Fata itike';

  @override
  String get peopleAhead => 'bantu imbere yawe';

  @override
  String estimatedTime(int minutes) {
    return 'Igihe giteganyijwe: iminota $minutes';
  }

  @override
  String get seePosition => 'Raba umwanya wanje';

  @override
  String get myOrganizations => 'Amashirahamwe yanje';

  @override
  String get viewAll => 'Raba vyose';

  @override
  String get needHelp => 'Ukeneye ubufasha?';

  @override
  String get helpBody => 'Itsinda ryacu ririko kugufasha.';

  @override
  String get contact => 'Tuvugane';

  @override
  String get noActiveTicket => 'Nta tike rikora';

  @override
  String get noActiveTicketBody =>
      'Fata itike mu shami kugira ukurikirane umwanya wawe uko bitasiba.';

  @override
  String get comingSoon => 'Kirashika bidatevye';

  @override
  String get logout => 'Sohoka';

  @override
  String get profileTitle => 'Umusomyi wanje';

  @override
  String get aboutTitle => 'Ibiraba';

  @override
  String get tabHome => 'Intango';

  @override
  String get tabTickets => 'Amatike';

  @override
  String get tabNotifications => 'Amatangazo';

  @override
  String get tabAssistance => 'Ubufasha';

  @override
  String get tabMore => 'Ibindi';

  @override
  String get notifWelcome => 'Kaze kuri TONDE';

  @override
  String get notifWelcomeBody => 'Konti yawe y\'ikwerekana iriteguye.';

  @override
  String get notifQueue => 'Umurongo wawe uratera imbere';

  @override
  String get notifQueueBody => 'Urimo utera imbere mu murongo.';

  @override
  String get notifAgency => 'Ishami rishasha riraboneka';

  @override
  String get notifAgencyBody => 'Amashami mashasha amaze kongerwa.';

  @override
  String get profileEmail => 'Aderesi ya email';

  @override
  String get profilePhone => 'Telefoni';

  @override
  String get profileRole => 'Umwanya';

  @override
  String get profileOrganization => 'Ishirahamwe';

  @override
  String get profileMemberSince => 'Umunyamuryango guhera';

  @override
  String get profileAccountInfo => 'Amakuru y\'ikonti';

  @override
  String get profileNotAvailable => 'Ntibavugise';

  @override
  String get editProfile => 'Hindura umusomyi';

  @override
  String get editProfileTitle => 'Hindura amakuru yanjye';

  @override
  String get save => 'Bika';

  @override
  String get cancel => 'Hagarika';

  @override
  String get profileUpdated => 'Umusomyi wahindurwe';

  @override
  String get profileUpdateFailed => 'Ntibishoboka guhindura umusomyi.';

  @override
  String get invalidEmail => 'Aderesi ya email ntibikwiye.';

  @override
  String get invalidPhone => 'Nomero ya telefone ntibikwiye.';

  @override
  String get trackingTitle => 'Gukurikirana mu gihe nyacyo';

  @override
  String get trackingStatusWaiting => 'Utegereje';

  @override
  String get trackingStatusCalled => 'Yahamagawe';

  @override
  String get trackingStatusInService => 'Biriko birakorwa';

  @override
  String get trackingStatusAbsent => 'Ntaboneka';

  @override
  String get trackingCalledNow => 'Kuri ibiro ubu';

  @override
  String get trackingYourTicket => 'Itike yawe';

  @override
  String get trackingPosition => 'Umwanya wawe';

  @override
  String trackingYouAre(int position) {
    return 'Uri inomero $position mu murongo';
  }

  @override
  String get trackingQrHint => 'Erekana iyi kode ku biro';

  @override
  String get trackingLive => 'Mu gihe nyacyo';

  @override
  String get trackingPolling => 'Uburyo bw\'inyuma';

  @override
  String trackingUpdatedAt(String time) {
    return 'Yavuguruwe $time';
  }

  @override
  String get trackingCalledBanner => 'Ni igihe cawe';

  @override
  String get trackingCalledBannerBody => 'Erekana kode yawe ya QR ku biro.';

  @override
  String get trackingWaitTime => 'Igihe giteganyijwe';

  @override
  String trackingMinutesValue(int? minutes) {
    if (minutes == null) return trackingEtaUnavailable;
    return 'iminota $minutes';
  }

  @override
  String get trackingEtaUnavailable => 'Igihe kirategurwa';

  @override
  String trackingCounterPaused(String counter) {
    return '$counter iri mu kuruhuka.';
  }

  @override
  String trackingCounterPausedUntil(String counter, String time) {
    return '$counter iri mu kuruhuka kugeza saa $time.';
  }

  @override
  String get trackingInQueue => 'mu murongo';

  @override
  String get offlineMode => 'Nta murandasi';

  @override
  String get offlineLocalData => 'Amakuru abitswe mu telefone';

  @override
  String get offlinePendingSync => 'Itegereje guhuza';

  @override
  String offlinePendingActions(int count) {
    return 'Ibikorwa $count bitegereje';
  }

  @override
  String get ticketPendingSync => 'Ntibihujwe';

  @override
  String get trackingPendingTitle => 'Ugukurikirana kurategereje';

  @override
  String get trackingPendingBody =>
      'Itike yawe yabitswe kuri telefone. Ugukurikirana mu gihe nyacyo kuzotangira umurandasi umaze kugaruka.';

  @override
  String get ticketPendingTitle => 'Itike yabitswe nta murandasi';

  @override
  String get ticketPendingNote =>
      'Izohamwa no guhuzwa umurandasi umaze kugaruka.';

  @override
  String get moreSettings => 'Igenamiterere';

  @override
  String get moreLanguage => 'Ururimi';

  @override
  String get moreAppearance => 'Isura';

  @override
  String get languageSystem => 'Sisitemu';

  @override
  String get themeSystem => 'Sisitemu';

  @override
  String get themeLight => 'Umucyo';

  @override
  String get themeDark => 'Umwijima';

  @override
  String appVersion(String version) {
    return 'Verisiyo $version';
  }

  @override
  String get aboutBody =>
      'Porogarama y\'abaturage yo gucunga umurongo w\'abategereje mu mabanki n\'ibitaro mu Burundi.';

  @override
  String get ticketDetailsTitle => 'Ibisobanuro vy\'itike';

  @override
  String get passYourNumber => 'Inomero y\'itike yawe';

  @override
  String get passDesk => 'Idirishya';

  @override
  String get passDeskPending => 'Birindiriwe';

  @override
  String get passPendingQr => 'Kode QR izoboneka itike imaze kwemezwa.';

  @override
  String get passOpenDetails => 'Raba ibisobanuro vy\'itike';

  @override
  String ticketSemantics(String number, int position) {
    return 'Itike $number, umwanya $position mu murongo';
  }

  @override
  String get detailsQueue => 'Umurongo w\'abantu';

  @override
  String get detailsInstitution => 'Ikigo';

  @override
  String get detailsName => 'Izina';

  @override
  String get detailsAgency => 'Ishami';

  @override
  String get detailsAddress => 'Aderesi';

  @override
  String get detailsTicket => 'Itike';

  @override
  String get detailsPeopleAhead => 'Abantu imbere yawe';

  @override
  String get detailsCalledNumber => 'Inomero iri guhamagarwa';

  @override
  String get detailsCounter => 'Idirishya';

  @override
  String get detailsIssuedAt => 'Yatanzwe ku';

  @override
  String get detailsNumber => 'Inomero';

  @override
  String get detailsStatus => 'Uko ihagaze';

  @override
  String get detailsRefresh => 'Kuvugurura ugukurikirana';

  @override
  String get detailsRefreshing => 'Biravugururwa…';

  @override
  String get detailsNotifications => 'Amatangazo y\'itike';

  @override
  String get detailsNotificationsEmpty => 'Nta matangazo y\'itike iyi.';

  @override
  String get detailsCancel => 'Guhagarika itike';

  @override
  String detailsCancelTitle(String number) {
    return 'Guhagarika itike $number?';
  }

  @override
  String get detailsCancelBody =>
      'Umwanya wawe uzofungurwa ako kanya. Ntibishobora gusubizwa: uzokenera gufata itike nshasha.';

  @override
  String get detailsCancelKeep => 'Komeza ufise itike';

  @override
  String get detailsCancelConfirm => 'Ego, hagarika';

  @override
  String get detailsCancelled => 'Itike yahagaritswe';

  @override
  String get detailsQrTitle => 'Pass yo kwemeza';

  @override
  String get servicesTitle => 'Serivisi';

  @override
  String get servicesChooseHint => 'Hitamo serivisi ihuye n\'icyo ukeneye.';

  @override
  String get servicesEmpty => 'Nta serivisi iboneka kuri iri shami.';

  @override
  String get serviceUnavailable =>
      'Iyi serivisi ntisubira gutangwa kuri iri shami. Hitamo indi.';

  @override
  String get changeService => 'Hindura serivisi';

  @override
  String get detailsService => 'Serivisi';

  @override
  String get ticketCancelQuestion => 'Urashaka guhagarika itike?';

  @override
  String ticketCancelBody(String number) {
    return 'Itike $number izokurwa mu murongo kandi umwanya wawe uzobura.';
  }

  @override
  String get backToDashboard => 'Subira ku rupapuro rukuru';

  @override
  String get ticketServed => 'Yarangiye';

  @override
  String get onboardingSkip => 'Simbuka';

  @override
  String get onboardingNext => 'Komeza';

  @override
  String get onboardingBack => 'Subiza';

  @override
  String get onboardingStart => 'Tangira';

  @override
  String get onboardingTitle1 => 'Nta murongo muremure ukiriho.';

  @override
  String get onboardingBody1 =>
      'Fata itike yawe aho uri hose kandi ukurikire umurongo mu gihe nyaco ku telefone yawe.';

  @override
  String get onboardingTitle2 => 'Gera ku gihe nyaco.';

  @override
  String get onboardingBody2 =>
      'Raba abantu bari imbere yawe hanyuma umenyeshwe igihe umwanya wawe wegera.';

  @override
  String get onboardingTitle3 => 'Ufise itike y\'impapuro? Yisikane.';

  @override
  String get onboardingBody3 =>
      'Huza itike yawe yacapwe na telefone yawe kugira utegere aho ushaka utatakaje umwanya wawe.';

  @override
  String get ticketServedNote =>
      'Uraheze. Ushobora gufata itike indi igihe icyo ari cyo cose.';

  @override
  String notifTicketConfirmedTitle(String number) {
    return 'Itike yawe $number yemejwe';
  }

  @override
  String notifTicketConfirmedBody(String service, String agency) {
    return 'Uri mu murongo wa $service ku ishami rya $agency.';
  }

  @override
  String notifProgressTitle(int count) {
    return 'Harasigaye abantu $count imbere yawe';
  }

  @override
  String notifProgressBody(int minutes) {
    return 'Igihe utegereje: iminota $minutes. Tegura inyandiko zawe.';
  }

  @override
  String notifProgressBodyNoEta(int count) {
    return 'Harasigaye abantu $count imbere yawe. Tegura inyandiko zawe.';
  }

  @override
  String get notifApproachingTitle => 'Uru rwawe ruregereje!';

  @override
  String notifApproachingBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Harasigaye abantu $count gusa imbere yawe.',
      one: 'Harasigaye umuntu umwe gusa imbere yawe.',
    );
    return '$_temp0 Egera ku ishami.';
  }

  @override
  String get notifCalledTitle => 'Ni uru rwawe!';

  @override
  String notifCalledBody(String number, String counter) {
    return 'Itike $number irahamagarwa kuri $counter. Ihutire kwitaba.';
  }

  @override
  String get notifReminderTitle => 'Itike yawe iracahamagarwa';

  @override
  String notifReminderBody(String counter) {
    return 'Nyegera kuri $counter ntubandanye gutegereza.';
  }

  @override
  String get notifAbsentTitle => 'Wanditswe nk’uwo kuba adahari';

  @override
  String notifAbsentBody(String number) {
    return 'Itike $number yanditswe nk’iy’uwo kuba adahari. Raba porogaramu kugira ngo umenye uko ushobora kongera kwinjira mu murongo.';
  }

  @override
  String get notifResumedTitle => 'Itike yawe yongeye gukora';

  @override
  String notifResumedBody(String number) {
    return 'Itike $number iri mu murongo yongeye.';
  }

  @override
  String get notifServedTitle => 'Urugendo rwawe rwarangiye';

  @override
  String get notifServedBody => 'Urakoze gukoresha TONDE!';

  @override
  String get notifCounterFallback => 'guichet';

  @override
  String get notifCenterEmpty => 'Nta nkuru ufise ubu';

  @override
  String get notifCenterEmptyBody =>
      'Uzomenyeshwa mu ntambwe zose z’umurongo wawe.';

  @override
  String get moreNotifications => 'Amatangazo';

  @override
  String get moreNotificationsSubtitle =>
      'Amatangazo y’umurongo n’uhamagarwa ku guichet';

  @override
  String get notifDelete => 'Siba iyi nkuru';

  @override
  String notifUnreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zitarasomwa',
      one: '1 itarasomwa',
      zero: 'Nta nkuru itarasomwa',
    );
    return '$_temp0';
  }

  @override
  String get profilePhotoTitle => 'Ifoto y\'umusomyi';

  @override
  String get profilePhotoHint => 'Kanda ku ifoto kugira uyihindure';

  @override
  String get profilePhotoCamera => 'Fata ifoto';

  @override
  String get profilePhotoGallery => 'Hitamwo mu bishashara';

  @override
  String get profilePhotoRemove => 'Kuraho ifoto';

  @override
  String get profilePhotoUpdated => 'Ifoto yahindurwe';

  @override
  String get profilePhotoRemoved => 'Ifoto yakuwemo';

  @override
  String get profilePhotoFailed => 'Ifoto ntishoboye guhindurwa';

  @override
  String get emailInvalid => 'Andika aderesi imeyili ibereye.';

  @override
  String get networkError =>
      'Seriveri ntishobora kugerwaho. Reba umurongo wawe.';

  @override
  String get organizationTypeOther => 'Ibindi';

  @override
  String get trackingStatusDone => 'Byarangiye';

  @override
  String get accountDisabled =>
      'Iyi konti yahagaritswe. Vugana n\'umuryango wawe.';

  @override
  String get accountLocked =>
      'Ugerageje kenshi. Ongera ugerageze nyuma y\'iminota mike.';

  @override
  String get authErrorGeneric => 'Kwinjira ntibishobotse. Ongera ugerageze.';

  @override
  String get passwordTooShort =>
      'Ijambobanga rigomba kuba rifise nibura inyuguti 8.';
}
