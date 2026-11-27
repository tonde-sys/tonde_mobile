import 'dart:convert';

import 'package:flutter/foundation.dart';
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
///
/// **L'ouverture est paresseuse.** `main()` ne l'attend plus : Hive passe par
/// `path_provider`, donc par un canal de plateforme, et un disque lent ne doit
/// pas retenir la première image. La boîte s'ouvre à la première lecture ou
/// écriture, une seule fois, puis reste ouverte.
final class HiveLocalCache implements LocalCache {
  HiveLocalCache();

  static const String boxName = 'tonde_cache';

  /// Plafond d'ouverture de la boîte.
  ///
  /// Passé ce délai, le cache bascule en mémoire pour la session : mieux vaut
  /// une application utilisable sans persistance qu'un écran qui attend un
  /// disque qui ne répond pas.
  static const Duration openBudget = Duration(seconds: 3);

  Future<Box<String>?>? _opening;

  /// Contenu de secours quand le disque est indisponible.
  final Map<String, String> _memory = <String, String>{};

  /// Ouvre la boîte à la première utilisation, et une seule fois.
  Future<Box<String>?> _box() => _opening ??= _open();

  Future<Box<String>?> _open() async {
    try {
      await Hive.initFlutter().timeout(openBudget);
      return await Hive.openBox<String>(boxName).timeout(openBudget);
    } on Object catch (error, stackTrace) {
      // Un stockage indisponible ne doit pas empêcher l'application de
      // démarrer, mais l'incident est remonté plutôt que masqué.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'tonde',
          context: ErrorDescription('ouverture du cache local'),
        ),
      );
      return null;
    }
  }

  @override
  Future<Object?> read(String key) async {
    final box = await _box();
    final raw = box == null ? _memory[key] : box.get(key);
    if (raw == null) {
      return null;
    }
    try {
      return jsonDecode(raw);
    } on FormatException {
      // Entrée corrompue (écriture interrompue, changement de schéma) :
      // on la traite comme absente plutôt que de bloquer l'écran.
      await write(key, null);
      return null;
    }
  }

  @override
  Future<void> write(String key, Object? document) async {
    final box = await _box();
    if (document == null) {
      if (box == null) {
        _memory.remove(key);
      } else {
        await box.delete(key);
      }
      return;
    }
    final raw = jsonEncode(document);
    if (box == null) {
      _memory[key] = raw;
    } else {
      await box.put(key, raw);
    }
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
