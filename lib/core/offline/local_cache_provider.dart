import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/offline/local_cache.dart';

/// Cache local de l'application.
///
/// Le cache mémoire par défaut ne sert qu'aux tests et aux aperçus, où
/// l'initialisation disque n'a pas de sens. `main()` surcharge ce provider
/// avec [HiveLocalCache] : la persistance réelle est donc explicitement
/// câblée au démarrage, jamais supposée.
final localCacheProvider = Provider<LocalCache>((ref) => MemoryLocalCache());
