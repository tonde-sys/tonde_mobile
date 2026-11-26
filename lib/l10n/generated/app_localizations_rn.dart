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
  String get heroTitleActive => 'Uri mu murongo';

  @override
  String get heroBodyActive =>
      'Umwanya wawe urahinduka uko igihe kigenda. Guma hafi y\'idirishya.';

  @override
  String get resumeTicket => 'Ongera ufate itike yawe';

  @override
  String get resumeSuccess => 'Itike yawe yasubiye mu murongo.';

  @override
  String get resumeWindowExpired =>
      'Igihe co gusubiza gishize. Fata itike nshasha.';

  @override
  String get resumeMaxMissed =>
      'Wabuze inshuro nyinshi: ntushobora gusubiza. Fata itike nshasha.';

  @override
  String get resumeFailed =>
      'Gusubiza ntibishobotse. Gerageza kandi ako kanya.';

  @override
  String ticketAbsentNote(String time) {
    return 'Ntiwabonetse. Ongera ufate itike yawe imbere ya $time.';
  }

  @override
  String get ticketClosedServedTitle => 'Itike yawe yarangiye';

  @override
  String ticketClosedServedBody(String number) {
    return 'Idirishya ryarangiye itike $number. Ushobora gufata irindi igihe cose ushakiye.';
  }

  @override
  String get ticketClosedExpiredTitle => 'Itike yawe yashize';

  @override
  String ticketClosedExpiredBody(String number) {
    return 'Itike $number ntikiri mu murongo. Fata itike nshasha kugira uhamagarwe.';
  }

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
  String trackingMinutesValue(int minutes) {
    return 'iminota $minutes';
  }

  @override
  String get trackingEtaUnavailable => 'Igihe kirategurwa';

  @override
  String trackingCounterPaused(Object counter) {
    return '$counter iri mu kuruhuka.';
  }

  @override
  String trackingCounterPausedUntil(Object counter, Object time) {
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
  String notifProgressBodyNoEta(Object count) {
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
  String get moreCallSound => 'Ijwi iyo uhamagariwe';

  @override
  String get moreCallSoundSubtitle =>
      'Ijwi ryumvikana iyo nimero yawe ihamagariwe';

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

  @override
  String get assistanceMyTicket => 'Itike yanje';

  @override
  String get assistanceFaq => 'Ibibazo bibazwa kenshi';

  @override
  String get assistanceContact => 'Tuvugane';

  @override
  String get assistanceGiveFeedback => 'Tanga ivyiyumviro vyawe';

  @override
  String get assistanceGiveFeedbackBody => 'Tubwire uko vyagenda ku biro.';

  @override
  String get assistanceReportBug => 'Menyesha ikibazo';

  @override
  String get assistanceReportBugBody => 'Hari ikidashira? Sobanura.';

  @override
  String get assistanceMyFeedback => 'Ivyo wantanze';

  @override
  String get assistanceMyFeedbackBody => 'Kurikirana ivyo watwohereje.';

  @override
  String get assistanceFeedbackSection => 'Ivyiyumviro n\'ibibazo';

  @override
  String get assistanceServiceStatus => 'Uko serivisi ihagaze';

  @override
  String get helpCenterTitle => 'Ikigo c\'ubufasha';

  @override
  String get helpCenterQuestion => 'Twoshobora kubafasha gute?';

  @override
  String get helpInstitutionTitle => 'Vugana n\'umuryango wawe';

  @override
  String get helpInstitutionBody =>
      'Ikibazo ku itike yawe canke ku murimo w\'ibiro.';

  @override
  String get helpInstitutionAction => 'Hamagara umuryango';

  @override
  String get helpTondeTitle => 'Vugana na TONDE';

  @override
  String get helpTondeBody => 'Ikibazo ku porogarama canke kuri konti yawe.';

  @override
  String get helpTondeAction => 'Vugana n\'ubufasha';

  @override
  String get helpFaqBody => 'Raba inyishu z\'ibibazo bibazwa kenshi.';

  @override
  String get helpFaqAction => 'Raba FAQ';

  @override
  String get helpFeedbackTitle => 'Ivyiyumviro vyawe ni vy\'ingirakamaro';

  @override
  String get helpFeedbackBody => 'Tubwire ivyo ushaka ko TONDE itunganya.';

  @override
  String get supportTondeSubtitle => 'Ubufasha bwa tekiniki bw\'iyi porogarama';

  @override
  String get supportAlwaysOpen =>
      'Iraboneka amasaha 24 kuri 24, imisi 7 kuri 7';

  @override
  String get supportChooseInstitution => 'Hitamo umuryango wawe';

  @override
  String get supportInstitutionEmpty => 'Nta muryango wometse kuri konti yawe.';

  @override
  String get supportInstitutionEmptyBody =>
      'Fata itike canke raba amashirahamwe kugira ubone aho avugira.';

  @override
  String get supportBrowseInstitutions => 'Raba amashirahamwe';

  @override
  String get supportInstitutionNoChannel =>
      'Uyu muryango ntuwereka aho uvugira.';

  @override
  String get supportInstitutionNoChannelBody =>
      'Ja ku biro: abakozi bazokwishura aho.';

  @override
  String get supportCallInstitution => 'Hamagara umuryango';

  @override
  String get supportLoadFailed => 'Ntivyashobotse kuronka aho bavugira.';

  @override
  String get supportClose => 'Funga';

  @override
  String get faqIntro => 'Inyishu z\'ibibazo bibazwa kenshi.';

  @override
  String get feedbackIntro => 'Tubwire ivyiza, ividashira, canke ivyobura.';

  @override
  String get feedbackThanksTitle => 'Urakoze cane!';

  @override
  String get feedbackThanksBody =>
      'Ubutumwa bwawe bwageze. Turawusoma imisi yose.';

  @override
  String get serviceReachable => 'Serivisi iraboneka';

  @override
  String get serviceUnreachable => 'Serivisi ntiboneka';

  @override
  String get faqTakeTicketTitle => 'Nofata gute itike?';

  @override
  String get faqTakeTicketBody =>
      'Fungura ahabanza, uhitemwo ishirahamwe, ishami na serivisi, hanyuma wemeze. Itike yawe irahita iboneka hamwe n\'umwanya wawe.';

  @override
  String get faqAbsentTitle => 'Sinumvise aho nahamagarirwa, nkore iki?';

  @override
  String get faqAbsentBody =>
      'Itike yawe ihinduka « ntaboneka » ariko igumana umwanya wayo akanya. Ku rupapuro rw\'ahabanza, kanda « Ongera ufate itike yawe » imbere y\'isaha yerekanywe: usubira mu murongo, ku mpera y\'urwego rwawe.';

  @override
  String get faqExpiredTitle => 'Itike yanje yarangiye';

  @override
  String get faqExpiredBody =>
      'Itike itasavwe ku gihe irakuka mu murongo. Fata indi nshasha: umwanya wawe uzobarwa ku murongo wo kuri uwo mwanya.';

  @override
  String get faqPausedTitle => 'Ibiro biri mu kiruhuko';

  @override
  String get faqPausedBody =>
      'Isaha yo gusubira iraboneka munsi y\'izina ry\'ibiro. Umwanya wawe ntuhinduka mu kiruhuko: igihe utegereje gusa ni co kijanjagurwa.';

  @override
  String get faqNotificationsTitle => 'Sinkirabwa n\'imenyesha';

  @override
  String get faqNotificationsBody =>
      'Raba ko imenyesha yemererwa kuri TONDE mu ma settings y\'telefone, kandi ko mode idahumye itari gukora. Porogaramu irakora nta zo: ukurikiranira ku rupapuro.';

  @override
  String get faqTwoTicketsTitle => 'Noshobora gufata itike zibiri?';

  @override
  String get faqTwoTicketsBody =>
      'Oya. Itike imwe gusa ikora kuri konti imwe, mu mashirahamwe yose: ni co gituma umurongo uguma ari uwo ukuri ku bose.';

  @override
  String get feedbackReviewTitle => 'Tanga ivyiyumviro vyawe';

  @override
  String get feedbackBugTitle => 'Menyesha ikibazo';

  @override
  String get feedbackCategory => 'Icyiciro';

  @override
  String get feedbackCategoryReview => 'Ivyiyumviro';

  @override
  String get feedbackCategoryBug => 'Ikibazo';

  @override
  String get feedbackCategorySuggestion => 'Inama';

  @override
  String get feedbackRating => 'Amanota yawe';

  @override
  String get feedbackRatingHint => 'Si ngombwa';

  @override
  String get feedbackMessage => 'Ubutumwa bwawe';

  @override
  String get feedbackMessageHint => 'Sobanura ivyabaye mu nteruro nke.';

  @override
  String feedbackMessageCounter(int count) {
    return '$count/1000';
  }

  @override
  String feedbackMessageTooShort(int count) {
    return 'Harasigaye inyuguti $count.';
  }

  @override
  String get feedbackSubmit => 'Rungika';

  @override
  String get feedbackSent => 'Urakoze, ivyiyumviro vyawe vyarungitswe.';

  @override
  String get feedbackRateLimited =>
      'Warungitse ivyiyumviro vyinshi vuba. Ongera ugerageze mu saha imwe.';

  @override
  String get feedbackAlreadySent =>
      'Wamaze kumenyesha iyi tike muri iki cyiciro.';

  @override
  String get feedbackFailed => 'Kurungika ntibishobotse. Ongera ugerageze.';

  @override
  String get feedbackPrivacyNote =>
      'Ivyiyumviro vyawe bifitanye isano na konti yawe, ntibisohoka ahabona.';

  @override
  String get feedbackHistoryTitle => 'Ivyo wantanze';

  @override
  String get feedbackHistoryEmpty => 'Nta kintu warungitse';

  @override
  String get feedbackHistoryEmptyBody =>
      'Ivyiyumviro n\'ibibazo watanze bizoboneka ngaha, hamwe n\'uko biriko birakorwa.';

  @override
  String get feedbackStatusReceived => 'Byakiriwe';

  @override
  String get feedbackStatusRead => 'Byasomwe';

  @override
  String get feedbackStatusResolved => 'Byakorewe';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactCall => 'Hamagara';

  @override
  String get contactEmail => 'Imeyili';

  @override
  String get contactNoChannel =>
      'Nta nzira yo kuvugana yashizweho kuri iri shirahamwe.';

  @override
  String get contactOpenFailed => 'Ntibishobotse kufungura iyi porogaramu.';

  @override
  String get errOfflineDetail =>
      'Raba umurongo wawe, hanyuma ugerageze ubundi. Nta kintu catakaye.';

  @override
  String get errTicketActive => 'Ufise itike iriho.';

  @override
  String get errTicketActiveDetail =>
      'Itike imwe gusa icyarimwe. Kurikirana iyi, canke uyihagarike imbere yo gufata indi.';

  @override
  String get errBranchClosed => 'Iri shami ryafunze.';

  @override
  String get errBranchClosedDetail =>
      'Itike zifatwa gusa mu ma saha yo gufungura.';

  @override
  String get errDailyLimit => 'Umusozo w\'amatike y\'uyu munsi wageze.';

  @override
  String get errDailyLimitDetail =>
      'Ongera ugerageze ejo, canke uhitemwo irindi shami.';

  @override
  String get errRateLimited => 'Wagerageje kenshi.';

  @override
  String get errRateLimitedDetail =>
      'Tegereza akanya imbere yo kongera ugerageza.';

  @override
  String get errGracePeriod => 'Itike yawe ntirashobora gufatwa ubundi.';

  @override
  String get errGracePeriodDetail =>
      'Ibiro biherutse kuguhamagara. Tegereza ko igihe kirangira, hanyuma ugerageze ubundi.';

  @override
  String get errTicketGone => 'Iyi tike ntisubira kuboneka.';

  @override
  String get errTicketGoneDetail =>
      'Hashobora kuba yarafunzwe hagati. Fata indi niba bikenewe.';

  @override
  String get errServer => 'Serivisi yahuye n\'ikibazo.';

  @override
  String get errServerDetail =>
      'Si amakosa yawe. Ongera ugerageze akanya gato.';

  @override
  String get errValidation => 'Hari amakuru adakwiye.';

  @override
  String get errForbidden => 'Iki gikorwa ntikwemererwa kuri konti yawe.';

  @override
  String get errUnexpected => 'Habaye ikibazo kitateganijwe.';

  @override
  String get errUnexpectedDetail =>
      'Ongera ugerageze. Niba biguma, bimenyeshe ku rupapuro rw\'ubufasha.';

  @override
  String get errInProgress => 'Hari ikindi gisabwa kimwe kiriko kirakorwa.';

  @override
  String get errTechnicalDetails => 'Amatariki y\'ubuhinga';

  @override
  String get actionChooseService => 'Hitamo serivisi';

  @override
  String get actionTakeNewTicket => 'Fata itike';

  @override
  String get actionWait => 'Tegereza';

  @override
  String errRateLimitedSeconds(int seconds) {
    return 'Wagerageje kenshi. Tegereza amasegonda $seconds.';
  }

  @override
  String errIncident(String id) {
    return 'Inomero: $id';
  }

  @override
  String get widgetEmptyTitle => 'Nta tike';

  @override
  String get widgetEmptyBody => 'Kanda ufate itike';

  @override
  String widgetPosition(int position) {
    return 'Umwanya $position';
  }

  @override
  String widgetEta(int minutes) {
    return '≈ $minutes min';
  }

  @override
  String widgetUpdated(String time) {
    return 'Byavuguruwe saa $time';
  }

  @override
  String get widgetCounterPaused => 'Icyumba kirahagaze';

  @override
  String widgetCounterPausedUntil(String time) {
    return 'Bihagaze kugeza $time';
  }

  @override
  String get moreHomeWidget => 'Widgeti y\'ecran y\'itangiriro';

  @override
  String get moreHomeWidgetSubtitle =>
      'Itike yawe iragaragara utarinjiye muri porogaramu';

  @override
  String get homeWidgetPinConfirm => 'Emeza ko wongeyeko widgeti.';

  @override
  String get homeWidgetPinUnsupported =>
      'Ecran yawe ntishobora kwongerako widgeti uhereye muri porogaramu. Yongeza ku ecran y\'itangiriro.';

  @override
  String get homeWidgetInviteTitle =>
      'Kurikirana ikibanza cawe kuva ku ecran y\'itangiriro';

  @override
  String get homeWidgetInviteBody =>
      'Ongeraho widgeti TONDE kugira ngo ubone inomero, ikibanza n\'igihe gisigaye utarinze gufungura porogaramu.';

  @override
  String get homeWidgetInviteAccept => 'Ongeraho widgeti';

  @override
  String get homeWidgetInviteLater => 'Nyuma';
}
