import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/config/app_config_provider.dart';
import 'package:tonde/core/network/dio_provider.dart';
import 'package:tonde/features/tracking/data/mock_queue_tracking_service.dart';
import 'package:tonde/features/tracking/data/websocket_queue_tracking_service.dart';
import 'package:tonde/features/tracking/domain/queue_tracking_service.dart';

/// Point de bascule unique entre la démo et le backend réel.
///
/// Tant qu'aucune base URL n'est fournie à la compilation, le suivi est simulé
/// localement : c'est le comportement de la démo approuvée. Dès que
/// `TONDE_API_BASE_URL` est renseignée, le client WebSocket réel prend le
/// relais sans qu'aucun écran ne change.
final queueTrackingServiceProvider = Provider<QueueTrackingService>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.isApiConfigured) {
    return MockQueueTrackingService();
  }
  return WebSocketQueueTrackingService(
    config: config,
    dio: ref.watch(dioProvider),
  );
});
