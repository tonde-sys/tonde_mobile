import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/core/offline/local_cache.dart';
import 'package:tonde/core/offline/local_cache_provider.dart';
import 'package:tonde/features/auth/data/auth_service_provider.dart';
import 'package:tonde/features/auth/domain/user.dart';
import 'package:tonde/features/dashboard/presentation/pages/profile_page.dart';
import 'package:tonde/features/profile/domain/profile_photo_picker.dart';
import 'package:tonde/features/profile/presentation/controllers/profile_photo_providers.dart';
import 'package:tonde/features/profile/presentation/widgets/profile_avatar.dart';

import '../../helpers/fakes.dart';

const _user = User(
  id: 'u-jospin',
  name: 'Jospin Kanani',
  email: 'jospin@example.com',
);

/// Sélecteur piloté par le test : il ne touche ni à la galerie ni à l'appareil
/// photo, mais il enregistre exactement ce que l'écran lui demande.
class _FakePicker implements ProfilePhotoPicker {
  _FakePicker({this.next});

  /// Chemin renvoyé au prochain appel ; `null` simule une annulation.
  String? next;

  ProfilePhotoSource? lastSource;
  final List<String> deleted = <String>[];

  @override
  Future<String?> pick(ProfilePhotoSource source) async {
    lastSource = source;
    return next;
  }

  @override
  Future<void> delete(String path) async => deleted.add(path);
}

Future<ProviderContainer> _pumpProfile(
  WidgetTester tester, {
  required ProfilePhotoPicker picker,
  LocalCache? cache,
}) async {
  final container = ProviderContainer(
    overrides: [
      authServiceProvider.overrideWithValue(FakeAuthService(current: _user)),
      profilePhotoPickerProvider.overrideWithValue(picker),
      if (cache != null) localCacheProvider.overrideWithValue(cache),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: const ProfilePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Fichier image factice : le contenu importe peu, seule son existence compte
/// pour l'affichage et pour la suppression.
File _tempImage() {
  final directory = Directory.systemTemp.createTempSync('tonde_avatar');
  addTearDown(() => directory.deleteSync(recursive: true));
  return File('${directory.path}/photo.png')..writeAsBytesSync([0, 1, 2, 3]);
}

void main() {
  testWidgets('toucher l\'avatar propose la galerie et l\'appareil photo', (
    tester,
  ) async {
    await _pumpProfile(tester, picker: _FakePicker());

    await tester.tap(find.byType(ProfileAvatar));
    await tester.pumpAndSettle();

    expect(find.text('Prendre une photo'), findsOneWidget);
    expect(find.text('Choisir dans la galerie'), findsOneWidget);
    // Aucune photo personnelle : rien à supprimer.
    expect(find.text('Supprimer la photo'), findsNothing);
  });

  testWidgets('choisir une photo dans la galerie remplace l\'avatar', (
    tester,
  ) async {
    final photo = _tempImage();
    final picker = _FakePicker(next: photo.path);
    final cache = MemoryLocalCache();
    final container = await _pumpProfile(tester, picker: picker, cache: cache);

    expect(container.read(profilePhotoProvider).value, isNull);

    await tester.tap(find.byType(ProfileAvatar));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choisir dans la galerie'));
    await tester.pumpAndSettle();

    expect(picker.lastSource, ProfilePhotoSource.gallery);
    expect(container.read(profilePhotoProvider).value, photo.path);
    expect(find.text('Photo de profil mise à jour'), findsOneWidget);
    // La photo appartient au compte : elle est enregistrée sous son identifiant.
    expect(
      await cache.read(ProfilePhotoNotifier.keyFor(_user.id)),
      photo.path,
    );
  });

  testWidgets('l\'appareil photo est bien la source demandée', (tester) async {
    final photo = _tempImage();
    final picker = _FakePicker(next: photo.path);
    await _pumpProfile(tester, picker: picker);

    await tester.tap(find.byType(ProfileAvatar));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prendre une photo'));
    await tester.pumpAndSettle();

    expect(picker.lastSource, ProfilePhotoSource.camera);
  });

  testWidgets('une photo déjà choisie peut être supprimée', (tester) async {
    final photo = _tempImage();
    final picker = _FakePicker();
    final cache = MemoryLocalCache();
    await cache.write(ProfilePhotoNotifier.keyFor(_user.id), photo.path);

    final container = await _pumpProfile(tester, picker: picker, cache: cache);
    expect(container.read(profilePhotoProvider).value, photo.path);

    await tester.tap(find.byType(ProfileAvatar));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer la photo'));
    await tester.pumpAndSettle();

    expect(container.read(profilePhotoProvider).value, isNull);
    expect(find.text('Photo de profil supprimée'), findsOneWidget);
    expect(picker.deleted, [photo.path]);
    expect(
      await cache.read(ProfilePhotoNotifier.keyFor(_user.id)),
      isNull,
    );
  });

  testWidgets('une annulation du sélecteur ne change rien', (tester) async {
    // `next` reste null : l'utilisateur a fermé la galerie sans choisir.
    final picker = _FakePicker();
    final container = await _pumpProfile(tester, picker: picker);

    await tester.tap(find.byType(ProfileAvatar));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choisir dans la galerie'));
    await tester.pumpAndSettle();

    expect(container.read(profilePhotoProvider).value, isNull);
    expect(find.text('Photo de profil mise à jour'), findsNothing);
  });

  testWidgets('un fichier disparu retombe sur l\'illustration par défaut', (
    tester,
  ) async {
    final cache = MemoryLocalCache();
    await cache.write(
      ProfilePhotoNotifier.keyFor(_user.id),
      'C:/chemin/inexistant/avatar.png',
    );

    final container = await _pumpProfile(
      tester,
      picker: _FakePicker(),
      cache: cache,
    );

    expect(container.read(profilePhotoProvider).value, isNull);
  });
}
