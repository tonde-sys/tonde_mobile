import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Indique si au moins un réseau exploitable est disponible.
bool hasConnection(List<ConnectivityResult> results) =>
    results.any((result) => result != ConnectivityResult.none);

/// État de connectivité observé en continu, avec valeur initiale immédiate.
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((
  ref,
) async* {
  final connectivity = Connectivity();
  yield await connectivity.checkConnectivity();
  yield* connectivity.onConnectivityChanged;
});

/// Vrai tant qu'aucune perte de réseau n'a été observée.
///
/// Optimiste avant la première mesure : pendant la restauration de session au
/// démarrage, afficher un bandeau hors ligne pour un réseau simplement pas
/// encore testé serait un faux positif.
final isOnlineProvider = Provider<bool>((ref) {
  final results = ref.watch(connectivityProvider).value;
  if (results == null) {
    return true;
  }
  return hasConnection(results);
});
