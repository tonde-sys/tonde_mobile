import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/core/errors/api_error_mapper.dart';
import 'package:tonde/core/errors/app_exception.dart';

RequestOptions _request() => RequestOptions(path: '/');

void main() {
  test('connectionError -> NetworkException', () {
    expect(
      mapDioException(
        DioException(
          requestOptions: _request(),
          type: DioExceptionType.connectionError,
        ),
      ),
      isA<NetworkException>(),
    );
  });

  test('connectionTimeout -> NetworkException', () {
    expect(
      mapDioException(
        DioException(
          requestOptions: _request(),
          type: DioExceptionType.connectionTimeout,
        ),
      ),
      isA<NetworkException>(),
    );
  });

  test('receiveTimeout -> RequestTimeoutException', () {
    expect(
      mapDioException(
        DioException(
          requestOptions: _request(),
          type: DioExceptionType.receiveTimeout,
        ),
      ),
      isA<RequestTimeoutException>(),
    );
  });

  test('transformTimeout -> RequestTimeoutException', () {
    expect(
      mapDioException(
        DioException(
          requestOptions: _request(),
          type: DioExceptionType.transformTimeout,
        ),
      ),
      isA<RequestTimeoutException>(),
    );
  });

  test('badCertificate -> SecureConnectionException', () {
    expect(
      mapDioException(
        DioException(
          requestOptions: _request(),
          type: DioExceptionType.badCertificate,
        ),
      ),
      isA<SecureConnectionException>(),
    );
  });

  test('cancel -> RequestCancelledException', () {
    expect(
      mapDioException(
        DioException(requestOptions: _request(), type: DioExceptionType.cancel),
      ),
      isA<RequestCancelledException>(),
    );
  });

  test('badResponse 500 -> ApiException(500)', () {
    final mapped = mapDioException(
      DioException.badResponse(
        statusCode: 500,
        requestOptions: _request(),
        response: Response(requestOptions: _request(), statusCode: 500),
      ),
    );

    expect(mapped, isA<ApiException>());
    expect((mapped as ApiException).statusCode, 500);
  });

  test('unknown -> UnexpectedException', () {
    expect(
      mapDioException(
        DioException(
          requestOptions: _request(),
          type: DioExceptionType.unknown,
        ),
      ),
      isA<UnexpectedException>(),
    );
  });
}
