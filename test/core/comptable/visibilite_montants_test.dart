// CPT-F : l'etat de visibilite des montants (spec §7.3 ; DR-06). R-FIN-01 :
// masque au depart ; R-FIN-02 : affiche sur demande ; R-FIN-03 : de nouveau
// masque apres une deconnexion ou une nouvelle session. Jamais conserve.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/comptable/visibilite_montants.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';

import '../../router/support_routeur.dart';

Future<void> _attendre() => Future<void>.delayed(Duration.zero);

void main() {
  late SourcePilotee source;
  late ProviderContainer conteneur;

  setUp(() {
    source = SourcePilotee(sessionActive(AppRole.accountant));
    conteneur = ProviderContainer(
      overrides: <Override>[
        sourceSessionProvider.overrideWithValue(source),
        stockagePreferencesProvider.overrideWithValue(
          StockagePreferencesMemoire(),
        ),
      ],
    );
    addTearDown(conteneur.dispose);
    // La session se resout.
    conteneur.listen(sessionProvider, (SessionState? _, SessionState _) {});
    conteneur.listen(visibiliteMontantsProvider, (bool? _, bool _) {});
  });

  test('R-FIN-01 : masque au depart de la session', () async {
    await _attendre();
    expect(conteneur.read(sessionProvider).role, AppRole.accountant);
    expect(conteneur.read(visibiliteMontantsProvider), isFalse);
  });

  test('R-FIN-02 : afficher, basculer, masquer', () async {
    await _attendre();
    final VisibiliteMontants v = conteneur.read(
      visibiliteMontantsProvider.notifier,
    );
    v.afficher();
    expect(conteneur.read(visibiliteMontantsProvider), isTrue);
    v.basculer();
    expect(conteneur.read(visibiliteMontantsProvider), isFalse);
    v.basculer();
    expect(conteneur.read(visibiliteMontantsProvider), isTrue);
    v.masquer();
    expect(conteneur.read(visibiliteMontantsProvider), isFalse);
  });

  test('R-FIN-03 : la deconnexion remasque', () async {
    await _attendre();
    conteneur.read(visibiliteMontantsProvider.notifier).afficher();
    expect(conteneur.read(visibiliteMontantsProvider), isTrue);

    source.emettre(const SessionState.deconnecte());
    await _attendre();
    expect(conteneur.read(sessionProvider).role, isNull);
    expect(conteneur.read(visibiliteMontantsProvider), isFalse);
  });

  test('R-FIN-03 : une nouvelle session (autre compte) remasque', () async {
    await _attendre();
    conteneur.read(visibiliteMontantsProvider.notifier).afficher();
    expect(conteneur.read(visibiliteMontantsProvider), isTrue);

    source.emettre(
      sessionActive(AppRole.accountant).copyWith(profileId: 'cpt-autre'),
    );
    await _attendre();
    expect(conteneur.read(visibiliteMontantsProvider), isFalse);
  });

  test('un changement de mode d interface ne remasque pas', () async {
    await _attendre();
    conteneur.read(visibiliteMontantsProvider.notifier).afficher();

    source.emettre(
      sessionActive(AppRole.accountant, mode: InterfaceMode.enfant),
    );
    await _attendre();
    expect(conteneur.read(visibiliteMontantsProvider), isTrue);
  });
}
