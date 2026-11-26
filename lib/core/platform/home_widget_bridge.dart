import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// État affiché par le widget d'écran d'accueil Android.
///
/// Les textes arrivent **déjà composés** : le widget natif ne traduit rien et
/// ne formate rien. C'est le seul moyen de garantir que le widget et l'écran
/// affichent la même chose — deux formats d'heure, deux façons d'écrire
/// « ≈ 12 min » et le client se demande lequel croire.
///
/// [hasTicket] est distinct du contenu : un ticket sans estimation fiable a des
/// champs vides mais reste un ticket. Sans ce drapeau, le widget ne saurait pas
/// distinguer « aucune donnée à montrer » de « aucun ticket ».
@immutable
final class HomeWidgetState {
  const HomeWidgetState({
    required this.hasTicket,
    this.number = '',
    this.agency = '',
    this.status = '',
    this.position = '',
    this.eta = '',
    this.updated = '',
    this.emptyTitle = '',
    this.emptyBody = '',
  });

  /// État « aucun ticket » : le widget invite à en prendre un.
  const HomeWidgetState.empty({required String title, required String body})
    : this(hasTicket: false, emptyTitle: title, emptyBody: body);

  final bool hasTicket;
  final String number;
  final String agency;
  final String status;
  final String position;
  final String eta;
  final String updated;
  final String emptyTitle;
  final String emptyBody;

  /// Clés du contrat avec `TondeWidgetProvider` (côté Kotlin).
  Map<String, Object?> toMap() => <String, Object?>{
    'has_ticket': hasTicket,
    'number': number,
    'agency': agency,
    'status': status,
    'position': position,
    'eta': eta,
    'updated': updated,
    'empty_title': emptyTitle,
    'empty_body': emptyBody,
  };

  // Égalité par valeur : le pilotage compare l'état courant au précédent pour
  // ne pas réveiller le widget à chaque reconstruction de l'écran d'accueil.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is HomeWidgetState &&
        other.hasTicket == hasTicket &&
        other.number == number &&
        other.agency == agency &&
        other.status == status &&
        other.position == position &&
        other.eta == eta &&
        other.updated == updated &&
        other.emptyTitle == emptyTitle &&
        other.emptyBody == emptyBody;
  }

  @override
  int get hashCode => Object.hash(
    hasTicket,
    number,
    agency,
    status,
    position,
    eta,
    updated,
    emptyTitle,
    emptyBody,
  );

  @override
  String toString() =>
      'HomeWidgetState(hasTicket: $hasTicket, number: $number, '
      'position: $position, eta: $eta)';
}

/// Passerelle vers le widget d'écran d'accueil.
///
/// Abstraite pour deux raisons : iOS n'a pas de widget d'écran d'accueil
/// Android (il faudrait une extension WidgetKit, hors périmètre), et les tests
/// ont besoin d'observer ce qui est publié sans passer par un canal natif.
abstract interface class HomeWidgetBridge {
  /// Publie [state] et repeint le widget.
  Future<void> update(HomeWidgetState state);

  /// Efface l'état : le widget retombe sur son invitation.
  Future<void> clear();

  /// Vrai si le lanceur sait épingler un widget depuis l'application
  /// (Android 8.0+ et lanceur compatible).
  Future<bool> isPinSupported();

  /// Demande au lanceur d'épingler le widget. Vrai si la demande est partie.
  Future<bool> requestPin();
}

/// Passerelle réelle, par canal de méthode vers `MainActivity`.
final class MethodChannelHomeWidgetBridge implements HomeWidgetBridge {
  const MethodChannelHomeWidgetBridge([
    this._channel = const MethodChannel(channelName),
  ]);

  /// Doit rester aligné sur `MainActivity.CHANNEL` côté Kotlin.
  static const String channelName = 'app.tonde/home_widget';

  final MethodChannel _channel;

  @override
  Future<void> update(HomeWidgetState state) =>
      _channel.invokeMethod<void>('update', state.toMap());

  @override
  Future<void> clear() => _channel.invokeMethod<void>('clear');

  @override
  Future<bool> isPinSupported() async =>
      await _channel.invokeMethod<bool>('isPinSupported') ?? false;

  @override
  Future<bool> requestPin() async =>
      await _channel.invokeMethod<bool>('requestPin') ?? false;
}

/// Passerelle inerte : plateforme sans widget d'écran d'accueil.
final class NoopHomeWidgetBridge implements HomeWidgetBridge {
  const NoopHomeWidgetBridge();

  @override
  Future<void> update(HomeWidgetState state) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<bool> isPinSupported() async => false;

  @override
  Future<bool> requestPin() async => false;
}
