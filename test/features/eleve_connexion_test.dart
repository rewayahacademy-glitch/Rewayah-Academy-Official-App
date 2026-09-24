import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/lecteur_qr.dart';
import 'package:rewayah_academy/core/appairage/profils_locaux.dart';
import 'package:rewayah_academy/core/cache/secure/stockage_securise.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/eleve_connexion/eleve_connexion_page.dart';
import 'package:rewayah_academy/features/eleve_connexion/saisie_code_page.dart';

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

/// Monte `/connexion/eleve` sur un petit routeur qui porte aussi la saisie
/// du code, ou l'ecran renvoie un appareil sans profil.
Future<GoRouter> _monter(
  WidgetTester tester,
  ProfilsLocaux profils, {
  Object? extra,
}) async {
  final GoRouter routeur = GoRouter(
    initialLocation: Routes.connexionEleve,
    initialExtra: extra,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.connexionEleve,
        builder: (BuildContext _, GoRouterState _) =>
            const EleveConnexionPage(),
      ),
      GoRoute(
        path: Routes.connexionEleveCode,
        builder: (BuildContext _, GoRouterState _) => const SaisieCodePage(),
      ),
    ],
  );
  await tester.pumpWidget(
    hoteRoutantAvec(
      routeur,
      surcharges: <Override>[
        profilsLocauxProvider.overrideWithValue(profils),
        stockageSecuriseProvider.overrideWithValue(FauxStockageSecurise()),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        lecteurQrDisponibleProvider.overrideWithValue(true),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return routeur;
}

/// L'hote d'un routeur deja construit (pour lire son adresse ensuite).
Widget hoteRoutantAvec(
  GoRouter routeur, {
  List<Override> surcharges = const <Override>[],
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: MaterialApp.router(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      routerConfig: routeur,
    ),
  ),
);

String _lieu(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri.path;

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
      // appaire. Il demande un code, sur la route de saisie (une fonction, un
      // seul endroit). C'est le pire cas acceptable.
      final GoRouter routeur = await _monter(tester, _ProfilsIndisponibles());

      expect(_lieu(routeur), Routes.connexionEleveCode);
      expect(find.byType(SaisieCodePage), findsOneWidget);
      expect(find.text(t.eleveConnexion.saisie.titre), findsOneWidget);
    });

    testWidgets('un appareil deja appaire ne redemande pas de code', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester, _ProfilsConnus());

      expect(_lieu(routeur), Routes.connexionEleve);
      expect(find.text(t.eleveConnexion.choisirProfil), findsOneWidget);
      expect(find.byType(SaisieCodePage), findsNothing);
    });

    testWidgets(
      'le profil qui arrive de la saisie passe droit au code personnel, '
      'meme sans base locale',
      (WidgetTester tester) async {
        final GoRouter routeur = await _monter(
          tester,
          _ProfilsIndisponibles(),
          extra: const ProfilLocal(
            id: 'e1',
            prenom: 'Amina',
            identifiantImmuable: '',
          ),
        );

        expect(_lieu(routeur), Routes.connexionEleve);
        expect(find.text(t.eleveConnexion.nouveauCode), findsOneWidget);
      },
    );
  });
}
