import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/core/config/app_config.dart';

void main() {
  group('AppEnvironment.fromName', () {
    test('accepte les environnements connus', () {
      expect(AppEnvironment.fromName('dev'), AppEnvironment.dev);
      expect(AppEnvironment.fromName('staging'), AppEnvironment.staging);
      expect(AppEnvironment.fromName('prod'), AppEnvironment.prod);
    });

    test('rejette un environnement inconnu', () {
      expect(() => AppEnvironment.fromName('beta'), throwsArgumentError);
    });
  });

  group('AppConfig.parse', () {
    test('accepte une URL https', () {
      final config = AppConfig.parse(
        environmentName: 'staging',
        apiBaseUrlRaw: 'https://api.example.com',
        enableHttpLogging: false,
      );

      expect(config.environment, AppEnvironment.staging);
      expect(config.apiBaseUrl, Uri.parse('https://api.example.com'));
      expect(config.isApiConfigured, isTrue);
    });

    test("accepte l'absence d'URL (backend non configuré)", () {
      final config = AppConfig.parse(
        environmentName: 'dev',
        apiBaseUrlRaw: '',
        enableHttpLogging: false,
      );

      expect(config.apiBaseUrl, isNull);
      expect(config.isApiConfigured, isFalse);
    });

    test('accepte http uniquement en local', () {
      final config = AppConfig.parse(
        environmentName: 'dev',
        apiBaseUrlRaw: 'http://127.0.0.1:8080',
        enableHttpLogging: false,
      );

      expect(config.apiBaseUrl, isNotNull);
    });

    test('rejette http hors local', () {
      expect(
        () => AppConfig.parse(
          environmentName: 'dev',
          apiBaseUrlRaw: 'http://api.example.com',
          enableHttpLogging: false,
        ),
        throwsArgumentError,
      );
    });

    test('rejette une URL invalide', () {
      expect(
        () => AppConfig.parse(
          environmentName: 'dev',
          apiBaseUrlRaw: 'pas une url',
          enableHttpLogging: false,
        ),
        throwsArgumentError,
      );
    });
  });
}
