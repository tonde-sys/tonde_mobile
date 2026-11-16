import 'package:dio/dio.dart';
import 'package:tonde/core/errors/app_exception.dart';

/// Traduit une erreur Dio en erreur applicative.
///
/// Le corps de la réponse n'est pas parsé ici : le schéma d'erreur du backend
/// n'est pas encore contracté (voir DECISIONS.md). Seul le statut HTTP est
/// conservé dans [ApiException].
AppException mapDioException(DioException error) {
  return switch (error.type) {
    DioExceptionType.connectionError => NetworkException(cause: error),
    DioExceptionType.connectionTimeout => NetworkException(cause: error),
    DioExceptionType.sendTimeout => RequestTimeoutException(cause: error),
    DioExceptionType.receiveTimeout => RequestTimeoutException(cause: error),
    DioExceptionType.transformTimeout => RequestTimeoutException(cause: error),
    DioExceptionType.badCertificate => SecureConnectionException(cause: error),
    DioExceptionType.cancel => RequestCancelledException(cause: error),
    DioExceptionType.badResponse => ApiException(
      statusCode: error.response?.statusCode ?? 0,
      cause: error,
    ),
    DioExceptionType.unknown => UnexpectedException(cause: error),
  };
}
