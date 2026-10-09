import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/features/inscription/etapes/genre_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/identite_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/recapitulatif_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/usage_etape.dart';
import 'package:rewayah_academy/features/inscription/inscription_page.dart';

import '../support/harnais.dart';

/// Une source dont le rafraichissement echoue tant qu'on le demande.
class _SourceCapricieuse extends FausseSourceSession {
  bool echoue = true;

  @override
  Future<void> rafraichir() async {
    rafraichissements++;
    if (echoue) {
      throw StateError('jeton');
    }
  }
}

/// Un dossier dont la creation reste en attente jusqu'a ce qu'on la libere,
/// pour surprendre un second appui pendant que le premier est encore en vol.
class _DossierLent extends FauxServiceDossier {
  final Completer<void> _porte = Completer<void>();

  void libere() => _porte.complete();

  @override
  Future<void> creerProfil({
    required AppRole role,
    required String prenom,
    required String nom,
    Genre? genre,
  }) async {
    await _porte.future;
    await super.creerProfil(role: role, prenom: prenom, nom: nom, genre: genre);
  }
}

/// Monte le parcours sur un routeur minimal portant les cinq routes du lot
/// et une page d'arrivee `/attente`. Mesure sur 390 x 844.
Future<(FauxServiceDossier, FausseSourceSession)> _monter(
  WidgetTester tester, {
  FausseSourceSession? source,
  FauxServiceDossier? dossierFourni,
  FauxServiceAuth? auth,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final FauxServiceDossier dossier = dossierFourni ?? FauxServiceDossier();
  final FausseSourceSession session = source ?? FausseSourceSession();

  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.inscription,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.inscription,
          builder: (BuildContext _, GoRouterState _) => const InscriptionPage(),
        ),
        GoRoute(
          path: Routes.inscriptionUsage,
          builder: (BuildContext _, GoRouterState _) => const UsageEtape(),
        ),
        GoRoute(
          path: Routes.inscriptionIdentite,
          builder: (BuildContext _, GoRouterState _) => const IdentiteEtape(),
        ),
        GoRoute(
          path: Routes.inscriptionGenre,
          builder: (BuildContext _, GoRouterState _) => const GenreEtape(),
        ),
        GoRoute(
          path: Routes.inscriptionRecapitulatif,
          builder: (BuildContext _, GoRouterState _) =>
              const RecapitulatifEtape(),
        ),
        GoRoute(
          path: Routes.attente,
          builder: (BuildContext _, GoRouterState _) =>
              const Scaffold(body: Text('ATTENTE')),
        ),
      ],
      surcharges: <Override>[
        serviceDossierProvider.overrideWithValue(dossier),
        sourceSessionProvider.overrideWithValue(session),
        serviceAuthProvider.overrideWithValue(auth ?? FauxServiceAuth()),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return (dossier, session);
}

/// Le CTA en pilule de la page courante.
ActionPrincipale _cta(WidgetTester tester) => tester
    .widgetList<ActionPrincipale>(find.byType(ActionPrincipale))
    .firstWhere((ActionPrincipale a) => a.pilule);

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

Future<void> _continuer(WidgetTester tester) =>
    _taper(tester, find.text(t.commun.continuer));

Future<void> _jusquAuRecap(WidgetTester tester) async {
  await _taper(tester, find.text(t.inscription.usage.moiTitre));
  await _continuer(tester);
  await tester.enterText(find.byKey(const Key('inscription-prenom')), 'Amina');
  await tester.enterText(find.byKey(const Key('inscription-nom')), 'Diallo');
  await _continuer(tester);
  // Demande du directeur (25/09) : symbole femme et symbole homme, plus la
  // silhouette neutre du profil.
  expect(find.byIcon(AppIcons.femme.repos), findsOneWidget);
  expect(find.byIcon(AppIcons.homme.repos), findsOneWidget);
  expect(find.byIcon(AppIcons.profil.repos), findsNothing);
  await _taper(tester, find.text(t.inscription.genreFemme));
  await _continuer(tester);
}

void main() {
  group('LA-2 : inscription par etapes', () {
    testWidgets('usage : deux cartes aux textes du mandat, sans « Autre », '
        'sans preselection', (WidgetTester tester) async {
      await _monter(tester);

      expect(find.text(t.inscription.usage.question), findsOneWidget);
      expect(find.text('Moi uniquement'), findsOneWidget);
      expect(
        find.text('Je souhaite suivre les cours avec mon propre profil élève.'),
        findsOneWidget,
      );
      expect(find.text('Moi et ma famille'), findsOneWidget);
      expect(
        find.text(
          'Inscrivez vos enfants ou vos proches, avec ou sans vous. Vous '
          'pourrez créer votre propre profil élève à tout moment.',
        ),
        findsOneWidget,
      );
      expect(find.text('Je suis enseignant'), findsOneWidget);
      expect(find.text('Autre'), findsNothing);
      expect(find.text('1 sur 4'), findsOneWidget);
      expect(_cta(tester).onPress, isNull);
      expect(find.byKey(const Key('inscription-deconnexion')), findsOneWidget);
    });

    testWidgets('le parcours complet cree le profil et part vers /attente', (
      WidgetTester tester,
    ) async {
      final (FauxServiceDossier dossier, FausseSourceSession source) =
          await _monter(tester);
      await _jusquAuRecap(tester);

      expect(find.text('4 sur 4'), findsOneWidget);
      expect(find.text('Amina Diallo'), findsOneWidget);
      expect(find.text(t.inscription.modifier), findsNWidgets(3));

      await _taper(tester, find.text(t.inscription.creer));

      expect(dossier.profilsCrees, hasLength(1));
      expect(dossier.profilsCrees.single.role, AppRole.guardian);
      expect(dossier.profilsCrees.single.genre, Genre.femme);
      expect(source.rafraichissements, 1);
      expect(find.text('ATTENTE'), findsOneWidget);
    });

    testWidgets('le lien enseignant declare le role enseignant', (
      WidgetTester tester,
    ) async {
      final (FauxServiceDossier dossier, _) = await _monter(tester);
      await _taper(
        tester,
        find.byKey(const Key('inscription-lien-enseignant')),
      );
      expect(find.text('2 sur 4'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('inscription-prenom')),
        'Ali',
      );
      await tester.enterText(find.byKey(const Key('inscription-nom')), 'Bah');
      await _continuer(tester);
      await _taper(tester, find.text(t.inscription.genreHomme));
      await _continuer(tester);
      await _taper(tester, find.text(t.inscription.creer));
      expect(dossier.profilsCrees.single.role, AppRole.teacher);
    });

    testWidgets('identite : les erreurs se disent sous les champs', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _taper(tester, find.text(t.inscription.usage.familleTitre));
      await _continuer(tester);
      await _continuer(tester);
      expect(find.text(t.inscription.champRequis), findsNWidgets(2));
      expect(find.text('2 sur 4'), findsOneWidget);
    });

    testWidgets('retour 48 dp et « Modifier » ramenent au bon endroit', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _jusquAuRecap(tester);

      await _taper(
        tester,
        find.byKey(const Key('inscription-modifier-identite')),
      );
      expect(find.text('2 sur 4'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('inscription-prenom')),
        'Awa',
      );
      await _continuer(tester);
      expect(find.text('4 sur 4'), findsOneWidget);
      expect(find.text('Awa Diallo'), findsOneWidget);

      await _taper(tester, find.byType(DisqueRetour));
      expect(find.text('3 sur 4'), findsOneWidget);
      expect(
        tester.getSize(find.byType(DisqueRetour)).width,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('actualisation en echec : aucune impasse, aucun doublon', (
      WidgetTester tester,
    ) async {
      final _SourceCapricieuse source = _SourceCapricieuse();
      final (FauxServiceDossier dossier, _) = await _monter(
        tester,
        source: source,
      );
      await _jusquAuRecap(tester);
      await _taper(tester, find.text(t.inscription.creer));

      expect(find.text(t.inscription.erreurActualisation), findsOneWidget);
      expect(find.byKey(const Key('inscription-deconnexion')), findsOneWidget);

      source.echoue = false;
      await _taper(tester, find.text(t.inscription.reessayer));
      expect(dossier.profilsCrees, hasLength(1));
      expect(source.rafraichissements, 2);
      expect(find.text('ATTENTE'), findsOneWidget);
    });

    testWidgets('un echec de creation se dit, et ne fait pas avancer', (
      WidgetTester tester,
    ) async {
      final (FauxServiceDossier dossier, _) = await _monter(tester);
      dossier.erreurAJeter = StateError('reseau');
      await _jusquAuRecap(tester);
      await _taper(tester, find.text(t.inscription.creer));
      expect(find.text(t.inscription.erreur), findsOneWidget);
      expect(find.text('4 sur 4'), findsOneWidget);
    });

    testWidgets('double soumission bloquee : un second appui pendant '
        'l-envoi ne cree pas de second profil', (WidgetTester tester) async {
      final _DossierLent dossier = _DossierLent();
      final (_, FausseSourceSession source) = await _monter(
        tester,
        dossierFourni: dossier,
      );
      await _jusquAuRecap(tester);

      final Finder cta = find.text(t.inscription.creer);
      await tester.tap(cta);
      await tester.pump();
      // Le premier envoi est toujours en vol (la porte n'est pas liberee) :
      // le CTA doit deja etre desactive, et un second appui ne rien faire.
      expect(_cta(tester).onPress, isNull);
      await tester.tap(cta, warnIfMissed: false);
      await tester.pump();

      dossier.libere();
      await tester.pumpAndSettle();

      expect(dossier.profilsCrees, hasLength(1));
      expect(source.rafraichissements, 1);
      expect(find.text('ATTENTE'), findsOneWidget);
    });

    testWidgets('le « Modifier » de l-usage et du genre ramenent au bon '
        'endroit', (WidgetTester tester) async {
      await _monter(tester);
      await _jusquAuRecap(tester);

      await _taper(tester, find.byKey(const Key('inscription-modifier-usage')));
      expect(find.text('1 sur 4'), findsOneWidget);
      await _taper(tester, find.text(t.inscription.usage.familleTitre));
      await _continuer(tester);
      expect(find.text('4 sur 4'), findsOneWidget);

      await _taper(tester, find.byKey(const Key('inscription-modifier-genre')));
      expect(find.text('3 sur 4'), findsOneWidget);
      await _taper(tester, find.text(t.inscription.genreHomme));
      await _continuer(tester);
      expect(find.text('4 sur 4'), findsOneWidget);
    });

    testWidgets('une fois le profil cree, « Modifier » et le retour '
        'disparaissent : aucune impasse mais aucun doublon', (
      WidgetTester tester,
    ) async {
      final _SourceCapricieuse source = _SourceCapricieuse();
      final FauxServiceAuth auth = FauxServiceAuth();
      await _monter(tester, source: source, auth: auth);
      await _jusquAuRecap(tester);
      await _taper(tester, find.text(t.inscription.creer));

      expect(find.text(t.inscription.erreurActualisation), findsOneWidget);
      expect(
        tester
            .widget<ActionPrincipale>(
              find.byKey(const Key('inscription-modifier-identite')),
            )
            .onPress,
        isNull,
      );
      expect(find.byKey(const Key('inscription-deconnexion')), findsOneWidget);
      // Plus d'etape precedente : la rangee reste, sans disque (demande
      // A-5.1) ; la seule sortie est « Se deconnecter », sans doublon.
      expect(find.byType(DisqueRetour), findsNothing);
      await _taper(tester, find.byKey(const Key('inscription-deconnexion')));
      expect(auth.deconnexions, 1);
      expect(find.text('3 sur 4'), findsNothing);
    });

    testWidgets('la premiere etape n a pas de disque retour, la rangee reste '
        '(A-5.1)', (WidgetTester tester) async {
      await _monter(tester);
      expect(find.byType(DisqueRetour), findsNothing);
      expect(find.text('1 sur 4'), findsOneWidget);
      expect(find.byKey(const Key('inscription-deconnexion')), findsOneWidget);
    });
  });
}
