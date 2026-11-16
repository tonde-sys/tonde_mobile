import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tonde/core/security/auth_token_store.dart';
import 'package:tonde/core/security/secure_key_value_store.dart';

final secureKeyValueStoreProvider = Provider<SecureKeyValueStore>(
  (ref) => const FlutterSecureKeyValueStore(FlutterSecureStorage()),
);

final authTokenStoreProvider = Provider<AuthTokenStore>(
  (ref) => AuthTokenStore(ref.watch(secureKeyValueStoreProvider)),
);
