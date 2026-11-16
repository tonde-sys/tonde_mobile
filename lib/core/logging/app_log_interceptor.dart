import 'package:dio/dio.dart';
import 'package:tonde/core/logging/app_logger.dart';

/// Journalise méthode, chemin (sans query) et statut des requêtes.
///
/// N'enregistre jamais les en-têtes ni les corps, qui peuvent contenir des
/// secrets ou des données personnelles.
final class AppLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.debug('HTTP ${options.method} ${_safeUri(options.uri)}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    AppLogger.debug(
      'HTTP ${response.requestOptions.method} '
      '${_safeUri(response.requestOptions.uri)} -> ${response.statusCode}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    AppLogger.debug(
      'HTTP ${err.requestOptions.method} ${_safeUri(err.requestOptions.uri)}'
      ' -> erreur ${err.type.name}${status != null ? ' ($status)' : ''}',
    );
    handler.next(err);
  }

  static String _safeUri(Uri uri) => uri.replace(query: null).toString();
}
