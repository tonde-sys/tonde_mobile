import 'package:dio/dio.dart';
import 'package:tonde/core/errors/app_exception.dart';

/// Traduit une erreur Dio en erreur applicative.
///
/// Le corps de la réponse est désormais LU. Il ne l'était pas, au motif que le
/// schéma d'erreur n'était pas contracté ; il l'est, et l'ignorer coûtait cher :
/// le serveur répond `{"detail": {"code": "TICKET_ALREADY_ACTIVE", ...}}` et le
/// mobile affichait « réponse inattendue ».
///
/// Deux formes coexistent côté backend, et les deux sont reconnues :
///   - `{"detail": {"code": ..., "message": ...}}` (HTTPException FastAPI) ;
///   - `{"success": false, "error": {"code": ..., "message": ...}}` (ErrorResponse).
/// Une erreur de validation (422) porte `detail` sous forme de LISTE : elle est
/// ramenée au premier message, seul exploitable à l'écran.
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
      code: errorCodeOf(error.response),
      serverMessage: errorMessageOf(error.response),
      cause: error,
    ),
    DioExceptionType.unknown => UnexpectedException(cause: error),
  };
}

/// Code métier d'une réponse d'erreur, ou null si le corps n'en porte pas.
String? errorCodeOf(Response<dynamic>? response) {
  final detail = _errorDetail(response?.data);
  final code = detail?['code'];
  return code is String && code.isNotEmpty ? code : null;
}

/// Message du serveur, ou null.
String? errorMessageOf(Response<dynamic>? response) {
  final detail = _errorDetail(response?.data);
  final message = detail?['message'];
  return message is String && message.isNotEmpty ? message : null;
}

Map<String, dynamic>? _errorDetail(Object? body) {
  if (body is! Map) {
    return null;
  }
  final detail = body['detail'] ?? body['error'];
  if (detail is Map) {
    return Map<String, dynamic>.from(detail);
  }
  // 422 : `detail` est une liste d'erreurs de champ.
  if (detail is List && detail.isNotEmpty) {
    final first = detail.first;
    if (first is Map) {
      final message = first['msg'] ?? first['message'];
      return <String, dynamic>{
        'code': 'VALIDATION_ERROR',
        if (message is String) 'message': message,
      };
    }
    if (first is String) {
      return <String, dynamic>{'code': 'VALIDATION_ERROR', 'message': first};
    }
  }
  return null;
}
