import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/config/app_config_provider.dart';
import 'package:tonde/core/logging/app_log_interceptor.dart';
import 'package:tonde/core/network/api_client.dart';
import 'package:tonde/core/security/security_providers.dart';

/// Client HTTP unique, configuré depuis [AppConfig].
///
/// La base inclut le préfixe versionné (`/api/v1`) : les chemins passés au
/// client s'écrivent donc `/tickets`, `/auth/login`… sans le répéter, et une
/// montée de version de l'API se règle à un seul endroit.
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiRoot?.toString() ?? '',
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
    ),
  );

  if (config.enableHttpLogging) {
    dio.interceptors.add(AppLogInterceptor());
  }

  ref.onDispose(dio.close);
  return dio;
});

/// Client applicatif : jeton d'accès, renouvellement et erreurs typées.
///
/// Séparé de [dioProvider] parce que le transport et la politique de session
/// n'ont pas la même durée de vie ni les mêmes tests : `Dio` se moque, le
/// client applicatif se vérifie.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    dio: ref.watch(dioProvider),
    tokens: ref.watch(authTokenStoreProvider),
  );
});
