import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/profils_locaux.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/eleve_connexion/eleve_connexion_page.dart';

import '../support/harnais.dart';

/// Une base locale qui refuse de s'ouvrir.
///
/// Ce n'est pas un cas theorique : sur le web, la base passe par un moteur
/// `wasm` servi a la racine, et tant que ses fichiers manquaient, c'est
/// exactement ce que faisait la vraie.
class _ProfilsIndisponibles implements ProfilsLocaux {
  @override
  Future<List<ProfilLocal>> lister() async =>
      throw StateError('base locale indisponible');

  @override
  Future<void> enregistrer(ProfilLocal profil) async {}

  @override
  Future<void> oublier(String profilId) async {}
}

/// Une base locale qui connait deja quelqu'un.
class _ProfilsConnus implements ProfilsLocaux {
  @override
  Future<List<ProfilLocal>> lister() async => const <ProfilLocal>[
    ProfilLocal(id: 'p1', prenom: 'Aminata', identifiantImmuable: 'i1'),
  ];

  @override
  Future<void> enregistrer(ProfilLocal profil) async {}

  @override
  Future<void> oublier(String profilId) async {}
}

Future<void> _monter(WidgetTester tester, ProfilsLocaux profils) async {
  await tester.pumpWidget(
    hote(
      const EleveConnexionPage(),
      surcharges: <Override>[profilsLocauxProvider.overrideWithValue(profils)],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ELV-01 : l entree de l eleve', () {
    testWidgets('une base locale indisponible mene a la saisie du code', (
      WidgetTester tester,
    ) async {
      // **L'invariant du lot.** L'ecran restait indefiniment sur son indicateur
      // de chargement quand la base locale ne s'ouvrait pas : la lecture des
      // profils n'avait pas de `catch` et partait en `unawaited`, donc l'echec
      // ne remontait nulle part et `setState` n'etait jamais appele. Vu de
      // l'operateur : un bouton sur lequel on clique, et rien ne charge jamais.
      //
      // Un appareil sans memoire locale est un appareil qui n'a pas ete
      // appaire. Il demande un code. C'est le pire cas acceptable.
      await _monter(tester, _ProfilsIndisponibles());

      expect(find.text(t.commun.chargement), findsNothing);
      expect(find.text(t.eleveConnexion.codeInvite), findsOneWidget);
    });

    testWidgets('un appareil deja appaire ne redemande pas de code', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _ProfilsConnus());

      expect(find.text(t.eleveConnexion.choisirProfil), findsOneWidget);
      expect(find.text(t.eleveConnexion.codeInvite), findsNothing);
    });
  });
}
