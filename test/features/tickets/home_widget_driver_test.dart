import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/core/platform/home_widget_bridge.dart';
import 'package:tonde/features/tickets/data/ticket_service_provider.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/presentation/controllers/home_widget_driver.dart';
import 'package:tonde/features/tickets/presentation/controllers/ticket_controller.dart';
import 'package:tonde/features/tracking/data/queue_tracking_service_provider.dart';

import '../../helpers/fakes.dart';

/// Source d'état pilotable depuis le test.
///
/// Elle remplace `homeWidgetStateProvider` pour éprouver le pilote seul : le
/// calcul de l'état a ses propres tests, et le mélanger ici obligerait à
/// simuler tout le graphe (ticket, flux, langue) pour vérifier un simple
/// « ne publie pas deux fois la même chose ».
class _MutableState extends Notifier<HomeWidgetState?> {
  @override
  HomeWidgetState? build() => null;

  void set(HomeWidgetState? value) => state = value;
}

final _stateProvider = NotifierProvider<_MutableState, HomeWidgetState?>(
  _MutableState.new,
);

/// Passerelle qui enregistre les publications et peut échouer à la demande.
class _RecordingBridge implements HomeWidgetBridge {
  _RecordingBridge({this.failure});

  /// Exception levée à chaque appel quand elle est renseignée.
  final Object? failure;

  final List<HomeWidgetState> updates = <HomeWidgetState>[];
  int clearCalls = 0;

  @override
  Future<void> update(HomeWidgetState state) async {
    final error = failure;
    if (error != null) {
      throw error;
    }
    updates.add(state);
  }

  @override
  Future<void> clear() async => clearCalls++;

  @override
  Future<bool> isPinSupported() async => true;

  @override
  Future<bool> requestPin() async => true;
}

const _withTicket = HomeWidgetState(
  hasTicket: true,
  number: 'A-014',
  status: 'En attente',
);

const _withTicketCalled = HomeWidgetState(
  hasTicket: true,
  number: 'A-014',
  status: 'Appelé',
);

void main() {
  ProviderContainer containerWith(HomeWidgetBridge bridge) {
    final container = ProviderContainer(
      overrides: [
        homeWidgetBridgeProvider.overrideWithValue(bridge),
        homeWidgetStateProvider.overrideWith(
          (ref) => ref.watch(_stateProvider),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Monte le pilote et le garde en vie.
  ///
  /// `read` seul ne suffit pas : sans abonnement, le provider est libéré et
  /// son écoute avec lui. Dans l'application, c'est `ref.watch` au sommet de
  /// l'arbre qui le maintient.
  void mount(ProviderContainer container) {
    final subscription = container.listen(
      homeWidgetDriverProvider,
      (previous, next) {},
    );
    addTearDown(subscription.close);
  }

  group('publication', () {
    test('publie l\'état courant dès le montage', () async {
      final bridge = _RecordingBridge();
      final container = containerWith(bridge);

      container.read(_stateProvider.notifier).set(_withTicket);
      mount(container);
      await pumpEventQueue();

      expect(bridge.updates, [_withTicket]);
    });

    test('ne republie pas un état identique', () async {
      final bridge = _RecordingBridge();
      final container = containerWith(bridge);

      container.read(_stateProvider.notifier).set(_withTicket);
      mount(container);
      await pumpEventQueue();

      // Même contenu, instance différente : le widget ne doit pas être réveillé.
      container.read(_stateProvider.notifier).set(
        const HomeWidgetState(hasTicket: true, number: 'A-014', status: 'En attente'),
      );
      await pumpEventQueue();

      expect(bridge.updates, hasLength(1));
    });

    test('publie dès que l\'état change', () async {
      final bridge = _RecordingBridge();
      final container = containerWith(bridge);

      container.read(_stateProvider.notifier).set(_withTicket);
      mount(container);
      await pumpEventQueue();

      container.read(_stateProvider.notifier).set(_withTicketCalled);
      await pumpEventQueue();

      expect(bridge.updates, [_withTicket, _withTicketCalled]);
    });

    test('un état inconnu ne touche pas au widget', () async {
      final bridge = _RecordingBridge();
      final container = containerWith(bridge);

      mount(container);
      await pumpEventQueue();

      expect(bridge.updates, isEmpty);
    });
  });

  group('pannes', () {
    test('un canal absent coupe les tentatives pour de bon', () async {
      final bridge = _RecordingBridge(failure: MissingPluginException('absent'));
      final container = containerWith(bridge);

      container.read(_stateProvider.notifier).set(_withTicket);
      mount(container);
      await pumpEventQueue();

      container.read(_stateProvider.notifier).set(_withTicketCalled);
      await pumpEventQueue();

      // Deux états publiés, aucune écriture : la passerelle a renoncé.
      expect(bridge.updates, isEmpty);
    });

    test('une erreur de plateforme n\'interrompt pas le pilote', () async {
      final bridge = _RecordingBridge(
        failure: PlatformException(code: 'boom'),
      );
      final container = containerWith(bridge);

      container.read(_stateProvider.notifier).set(_withTicket);
      mount(container);
      await pumpEventQueue();

      expect(bridge.updates, isEmpty);
      // L'application continue : l'erreur est consommée par le pilote, aucune
      // exception ne s'échappe de la zone de test.
      expect(container.read(_stateProvider), _withTicket);
    });
  });

  group('câblage réel', () {
    test('ne publie rien tant que le ticket n\'est pas lu', () async {
      final container = ProviderContainer(
        overrides: [
          ticketServiceProvider.overrideWithValue(
            FakeTicketService(
              ticket: const Ticket(
                id: 't-1',
                number: 'A-014',
                position: 3,
                estimatedMinutes: 12,
                organizationId: 'org-1',
                organizationName: 'TONDE',
                agencyId: 'agency-1',
                agencyName: 'Agence Centre',
              ),
            ),
          ),
          queueTrackingServiceProvider.overrideWithValue(
            StaticQueueTrackingService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Avant la première réponse : on ne sait pas, donc on ne touche à rien.
      expect(container.read(homeWidgetStateProvider), isNull);

      await container.read(activeTicketProvider.future);
      await pumpEventQueue();

      final state = container.read(homeWidgetStateProvider);
      expect(state, isNotNull);
      expect(state!.hasTicket, isTrue);
      expect(state.number, 'A-014');
      // `flutter_test` fixe la langue de l'appareil à l'anglais : sans
      // préférence enregistrée, le widget parle donc anglais. C'est la règle
      // attendue — la langue de l'utilisateur d'abord, celle de l'appareil
      // ensuite.
      expect(state.status, 'Waiting');
      expect(state.position, 'Position 3');
    });
  });
}
