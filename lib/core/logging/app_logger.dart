import 'dart:developer' as developer;

/// Journalisation minimale et structurée, sans donnée personnelle ni secret.
abstract final class AppLogger {
  static const String _name = 'tonde';

  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: _name, error: error, stackTrace: stackTrace);
  }
}
