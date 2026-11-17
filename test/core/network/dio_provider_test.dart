import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/core/config/app_config.dart';
import 'package:tonde/core/config/app_config_provider.dart';
import 'package:tonde/core/logging/app_log_interceptor.dart';
import 'package:tonde/core/network/dio_provider.dart';

AppConfig _config({
  String url = 'https://api.example.com',
  bool httpLogging = false,
}) {
  return AppConfig.parse(
    environmentName: 'dev',
    apiBaseUrlRaw: url,
    enableHttpLogging: httpLogging,
  );
}

ProviderContainer _container(AppConfig config) {
  final container = ProviderContainer(
    overrides: [appConfigProvider.overrideWithValue(config)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test(
    'dioProvider applique la base URL et les timeouts de la configuration',
    () {
      final dio = _container(_config()).read(dioProvider);

      // La base inclut le prefixe versionne : les chemins s'ecrivent
      // « /tickets », pas « /api/v1/tickets ».
      expect(dio.options.baseUrl, 'https://api.example.com/api/v1');
      expect(dio.options.connectTimeout, const Duration(seconds: 10));
      expect(dio.options.sendTimeout, const Duration(seconds: 20));
      expect(dio.options.receiveTimeout, const Duration(seconds: 20));
    },
  );

  test('dioProvider fonctionne sans base URL configurée', () {
    final dio = _container(_config(url: '')).read(dioProvider);

    expect(dio.options.baseUrl, '');
  });

  test("dioProvider ajoute l'intercepteur de logs uniquement si activé", () {
    final withLogs = _container(_config(httpLogging: true)).read(dioProvider);
    expect(withLogs.interceptors.whereType<AppLogInterceptor>(), hasLength(1));

    final withoutLogs = _container(
      _config(httpLogging: false),
    ).read(dioProvider);
    expect(withoutLogs.interceptors.whereType<AppLogInterceptor>(), isEmpty);
  });
}
