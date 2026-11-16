import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Stockage clé/valeur persistant des données affichées hors ligne.
///
/// Les valeurs sont des documents JSON (`Map`, `List`, `String`, `num`,
/// `bool`) : aucun adaptateur généré n'est nécessaire et le contenu reste
/// inspectable lors d'une migration de schéma.
abstract interface class LocalCache {
  /// Écrit [document] sous [key]. Un document `null` supprime l'entrée.
  Future<void> write(String key, Object? document);

  /// Lit l'entrée [key], ou null si elle est absente ou illisible.
  Future<Object?> read(String key);
}

/// Cache persistant sur disque, adossé à Hive.
///
/// Une seule boîte (`tonde_cache`) contient des chaînes JSON : les documents
/// métier évoluent sans exiger de régénérer un adaptateur, et une entrée
/// corrompue est ignorée plutôt que de faire échouer le démarrage.
final class HiveLocalCache implements LocalCache {
  HiveLocalCache._(this._box);

  static const String boxName = 'tonde_cache';

  final Box<String> _box;

  /// Ouvre (ou crée) la boîte de cache. À appeler une fois au démarrage.
  static Future<LocalCache> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<String>(boxName);
    return HiveLocalCache._(box);
  }

  @override
  Future<Object?> read(String key) async {
    final raw = _box.get(key);
    if (raw == null) {
      return null;
    }
    try {
      return jsonDecode(raw);
    } on FormatException {
      // Entrée corrompue (écriture interrompue, changement de schéma) :
      // on la traite comme absente plutôt que de bloquer l'écran.
      await _box.delete(key);
      return null;
    }
  }

  @override
  Future<void> write(String key, Object? document) async {
    if (document == null) {
      await _box.delete(key);
      return;
    }
    await _box.put(key, jsonEncode(document));
  }
}

/// Cache volatil, utilisé par les tests et les aperçus.
///
/// L'application réelle surcharge `localCacheProvider` avec [HiveLocalCache]
/// dans `main()`.
final class MemoryLocalCache implements LocalCache {
  final Map<String, Object?> _documents = <String, Object?>{};

  @override
  Future<Object?> read(String key) async => _documents[key];

  @override
  Future<void> write(String key, Object? document) async {
    if (document == null) {
      _documents.remove(key);
      return;
    }
    _documents[key] = document;
  }
}
