import 'package:dio/dio.dart';

import 'app_exception.dart';

/// Maps any thrown error/exception to a typed, user-friendly [AppException].
///
/// Dio errors are mapped by HTTP status; everything else becomes
/// [UnknownException] so no raw stack trace can ever reach the UI.
AppException mapException(Object error) {
  if (error is AppException) return error;

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ServerException(
          'The server is taking too long to respond. '
          'Please check your connection and try again.',
        );
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badCertificate:
        return ServerException(
          'A secure connection could not be established with the server.',
        );
      case DioExceptionType.cancel:
        return const UnknownException('The request was cancelled.');
      case DioExceptionType.badResponse:
        return _mapStatusCode(error.response);
      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
        return const UnknownException();
    }
  }

  if (error is FormatException) {
    return const ServerException('The server returned an unexpected response.');
  }
  return const UnknownException();
}

AppException _mapStatusCode(Response<dynamic>? response) {
  final status = response?.statusCode ?? 0;
  final data = response?.data;

  // Prefer a backend-provided message when the contract exposes one.
  final String? backendMessage = switch (data) {
    {'message': final String m} => m,
    {'detail': final String d} => d,
    _ => null,
  };

  switch (status) {
    case 400:
      return ValidationException(
        backendMessage ?? 'The request could not be processed. Please review the details and retry.',
      );
    case 401:
      return const UnauthorizedException();
    case 403:
      return const ForbiddenException();
    case 404:
      return const NotFoundException();
    case 422:
      return ValidationException(
        backendMessage ?? 'Some details are invalid. Please review and retry.',
      );
    case 429:
      return ServerException('Too many requests. Please wait a moment and retry.');
    default:
      if (status >= 500) {
        return ServerException(
          'The server is temporarily unavailable. Please try again shortly.',
        );
      }
      return const UnknownException();
  }
}
