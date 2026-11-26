/// Version affichée à l'utilisateur.
///
/// À garder alignée avec `version:` du `pubspec.yaml` : le numéro de build
/// (`+1`) n'est pas montré.
const String kAppVersion = '1.0.1';

/// Environnements d'exécution de l'application.
enum AppEnvironment {
  dev,
  staging,
  prod;

  static AppEnvironment fromName(String name) {
    return AppEnvironment.values.firstWhere(
      (environment) => environment.name == name,
      orElse: () => throw ArgumentError.value(
        name,
        'TONDE_ENVIRONMENT',
        'Environnement inconnu (attendu : dev, staging ou prod).',
      ),
    );
  }
}

/// Configuration non secrète fournie à la compilation via `--dart-define`.
class AppConfig {
  const AppConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.enableHttpLogging,
    required this.supportWhatsApp,
    required this.supportPhone,
    required this.supportEmail,
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig.parse(
      environmentName: const String.fromEnvironment(
        'TONDE_ENVIRONMENT',
        defaultValue: 'dev',
      ),
      apiBaseUrlRaw: const String.fromEnvironment('TONDE_API_BASE_URL'),
      enableHttpLogging: const bool.fromEnvironment(
        'TONDE_HTTP_LOGGING',
        defaultValue: false,
      ),
      // Aucune valeur par défaut : un numéro de support inventé vaudrait moins
      // que pas de numéro du tout, parce qu'il enverrait les gens appeler
      // quelqu'un qui n'a rien à voir avec TONDE.
      supportWhatsAppRaw: const String.fromEnvironment(
        'TONDE_SUPPORT_WHATSAPP',
      ),
      supportPhoneRaw: const String.fromEnvironment('TONDE_SUPPORT_PHONE'),
      supportEmailRaw: const String.fromEnvironment('TONDE_SUPPORT_EMAIL'),
    );
  }

  /// Construit la configuration depuis des valeurs brutes, pour les tests.
  factory AppConfig.parse({
    required String environmentName,
    required String apiBaseUrlRaw,
    required bool enableHttpLogging,
    String supportWhatsAppRaw = '',
    String supportPhoneRaw = '',
    String supportEmailRaw = '',
  }) {
    final environment = AppEnvironment.fromName(environmentName);
    Uri? apiBaseUrl;
    if (apiBaseUrlRaw.isNotEmpty) {
      apiBaseUrl = Uri.tryParse(apiBaseUrlRaw);
      if (apiBaseUrl == null || !apiBaseUrl.hasAuthority) {
        throw ArgumentError.value(
          apiBaseUrlRaw,
          'TONDE_API_BASE_URL',
          'URL invalide.',
        );
      }
      final isLocal =
          apiBaseUrl.host == 'localhost' || apiBaseUrl.host == '127.0.0.1';
      if (apiBaseUrl.scheme != 'https' &&
          !(isLocal && apiBaseUrl.scheme == 'http')) {
        throw ArgumentError.value(
          apiBaseUrlRaw,
          'TONDE_API_BASE_URL',
          'Le schéma doit être https (http toléré uniquement en local).',
        );
      }
    }
    return AppConfig._(
      environment: environment,
      apiBaseUrl: apiBaseUrl,
      enableHttpLogging: enableHttpLogging,
      supportWhatsApp: _digitsOrEmpty(supportWhatsAppRaw),
      supportPhone: _digitsOrEmpty(supportPhoneRaw),
      supportEmail: supportEmailRaw.trim(),
    );
  }

  final AppEnvironment environment;

  /// Base URL de l'API. Nulle tant que le backend n'est pas configuré.
  final Uri? apiBaseUrl;

  final bool enableHttpLogging;

  /// Numéro WhatsApp du support, chiffres seuls (`257…`), vide si non configuré.
  final String supportWhatsApp;

  /// Numéro de téléphone du support, vide si non configuré.
  final String supportPhone;

  /// Adresse e-mail du support, vide si non configurée.
  final String supportEmail;

  /// Vrai dès qu'au moins un canal de contact est configuré.
  bool get hasSupportContact =>
      supportWhatsApp.isNotEmpty ||
      supportPhone.isNotEmpty ||
      supportEmail.isNotEmpty;

  bool get isApiConfigured => apiBaseUrl != null;

  /// Racine versionnée de l'API (`https://…/api/v1`).
  ///
  /// Centralisée ici parce que trois consommateurs doivent parler au même
  /// endroit : le client HTTP, le WebSocket et les tests. Laisser chacun
  /// concaténer `/api/v1` produisait deux variantes selon qu'une barre oblique
  /// finale traînait ou non — et une seule des deux atteignait le serveur.
  Uri? get apiRoot {
    final base = apiBaseUrl;
    if (base == null) {
      return null;
    }
    final prefix = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    return base.replace(path: '$prefix/api/v1');
  }
}

/// Ne garde que les chiffres d'un numéro saisi avec des espaces, des tirets ou
/// un `+`. Les liens `tel:` et `wa.me` n'acceptent rien d'autre.
String _digitsOrEmpty(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  return digits;
}
