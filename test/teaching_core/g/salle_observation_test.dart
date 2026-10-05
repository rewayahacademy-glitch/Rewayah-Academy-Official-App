// Lot O, sous-paquet 2 : la salle d'observation (maquettes V8 M3, M4, D1 ;
// decision du directeur `03` section 1 bis-5). Chaque parcours part d'une
// classe et se fait en TOUCHANT les boutons : « Observer la seance »,
// « Observer maintenant », « Agrandir », « Reduire », « Quitter », la
// confirmation, le retour du systeme.
//
// La classe est ici un double minimal qui appelle `ouvrirObservation`, le
// geste du bloc Observation de la classe (lot C). Le parcours depuis la vraie
// navigation de l'application est dans `entree_observation_navigation_test`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_observation/port_visite_observation.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/avatar_nom.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/features/tc_observation_ui/barre_commandes_observation.dart';
import 'package:rewayah_academy/features/tc_observation_ui/compteur_visite.dart';
import 'package:rewayah_academy/features/tc_observation_ui/ouverture_observation.dart';
import 'package:rewayah_academy/features/tc_observation_ui/panneau_observation_tuteur.dart';
import 'package:rewayah_academy/features/tc_observation_ui/routes_tc_g.dart';

import '../../fixtures/tuteur/faux_classes_foyer.dart';
import '../../support/aucun_mot_coupe.dart';
import '../e/faux/faux_classe.dart'
    show FauxMoteurClasse, FauxServiceVideoClasse, accesDe, participantDe;
import 'faux/faux_observation.dart';
import 'support/hote_tc_g.dart';

/// La classe, reduite a son bouton « Observer la seance » (lot C).
class _ClasseDouble extends StatelessWidget {
  const _ClasseDouble({required this.classeId, this.eleveId});

  final String classeId;
  final String? eleveId;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: <Widget>[
        Text('CLASSE $classeId'),
        ActionPrincipale(
          libelle: t.classe.observer,
          onPress: () => ouvrirObservation(
            context,
            seanceId: 's1',
            classeId: classeId,
            eleveId: eleveId,
          ),
        ),
      ],
    ),
  );
}

List<RouteBase> _routes() => <RouteBase>[
  GoRoute(
    path: '${Routes.tuteurClasses}/:classeId',
    builder: (BuildContext _, GoRouterState etat) => _ClasseDouble(
      classeId: etat.pathParameters['classeId']!,
      eleveId: etat.uri.queryParameters['eleve'],
    ),
  ),
  ...routesTcG(),
];

/// La reponse du serveur a l'entree : premiere visite sur deux, 1 min 42 s.
ResultatEntreeObservation _entree({
  Duration restant = const Duration(seconds: 102),
  int utilisees = 1,
  int max = 2,
}) => ResultatEntreeObservation(
  autorise: true,
  visite: uneVisite(),
  budget: unBudget(
    restant: restant,
    visitesUtilisees: utilisees,
    visitesMax: max,
    total: const Duration(seconds: 240),
  ),
);

/// Ce que le test garde en main apres l'entree en salle.
class _Salle {
  _Salle(
    this.visites,
    this.politique,
    this.moteur,
    this.horloge,
    this.battement,
  );

  final FauxPortVisite visites;
  final FauxPortPolitique politique;
  final FauxMoteurClasse moteur;
  final HorlogeReglable horloge;
  final StreamController<void> battement;
}

/// Monte la classe double, touche « Observer la seance » puis « Observer
/// maintenant » : la salle est ouverte.
Future<_Salle> _entrerEnSalle(
  WidgetTester tester, {
  ResultatEntreeObservation? reponse,
  Size taille = const Size(390, 844),
  ThemeMode mode = ThemeMode.light,
  double echelleTexte = 1,
  PortClassesFoyer? classes,
  bool horsLigne = false,
  TextDirection? sens,
  EdgeInsets zoneSure = EdgeInsets.zero,
  InterfaceMode interface = InterfaceMode.standard,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(
    left: zoneSure.left,
    top: zoneSure.top,
    right: zoneSure.right,
    bottom: zoneSure.bottom,
  );
  addTearDown(tester.view.reset);
  final FauxPortVisite visites = FauxPortVisite(reponse: reponse ?? _entree());
  final FauxPortPolitique politique = FauxPortPolitique();
  addTearDown(politique.fermer);
  final FauxMoteurClasse moteur = FauxMoteurClasse();
  final HorlogeReglable horloge = HorlogeReglable();
  final StreamController<void> battement = StreamController<void>.broadcast();
  addTearDown(battement.close);

  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesTcG(
        role: AppRole.guardian,
        visites: visites,
        politique: politique,
        moteur: moteur,
        video: FauxServiceVideoClasse(acces0: accesDe('guardian_observer')),
        battement: battement.stream,
        horloge: horloge.lire,
        horsLigne: horsLigne,
        autres: <Override>[
          if (classes != null)
            portClassesFoyerProvider.overrideWithValue(classes),
        ],
      ),
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(interface, Brightness.light),
          darkTheme: AppTheme.pour(interface, Brightness.dark),
          themeMode: mode,
          builder: (BuildContext context, Widget? enfant) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(echelleTexte)),
            child: sens == null
                ? enfant!
                : Directionality(textDirection: sens, child: enfant!),
          ),
          routerConfig: GoRouter(
            initialLocation: '/tuteur/classes/c1?eleve=enfant-1',
            routes: _routes(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _presser(tester, find.text(t.classe.observer));
  await _presser(tester, find.text(t.tc.observation.explication.observer));
  return _Salle(visites, politique, moteur, horloge, battement);
}

/// Laisse aboutir la fermeture de la visite.
///
/// Le moteur attend l'annulation de ses abonnements avant d'appeler le
/// serveur ; une annulation deja close rend un futur de la zone racine, que
/// l'horloge simulee du test ne fait jamais avancer. Un tour de la vraie
/// boucle suffit.
Future<void> _laisserFinir(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

Future<void> _presser(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// L'enseignant et l'enfant, et deux camarades qui ne doivent jamais sortir.
void _publierParticipants(FauxMoteurClasse moteur) =>
    moteur.publier(<ParticipantSalle>[
      participantDe(identite: 'prof-1', role: 'teacher', nom: 'Amina'),
      participantDe(identite: 'enfant-1', role: 'student', nom: 'Mariam'),
      participantDe(identite: 'enfant-2', role: 'student', nom: 'Camarade'),
    ]);

final v = t.tc.observation.visite;

Finder get _decompte => find.byKey(const ValueKey<String>('decompte-visite'));

String _texteDecompte(WidgetTester tester) =>
    tester.widget<Text>(_decompte).data!;

void main() {
  group('La salle, au format telephone (M4)', () {
    testWidgets('Observer la seance, Observer maintenant : la salle, son '
        'bandeau, trois commandes, deux personnes', (
      WidgetTester tester,
    ) async {
      final _Salle salle = await _entrerEnSalle(tester);
      _publierParticipants(salle.moteur);
      await tester.pumpAndSettle();

      expect(find.byType(PanneauObservationTuteur), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Le bandeau pleine largeur : le decompte et les visites restantes.
      expect(_texteDecompte(tester), '01:42');
      expect(
        find.text('1/2 visite restante pour cette séance'),
        findsOneWidget,
      );
      final double largeurBandeau = tester
          .getSize(find.byType(BandeauDecompteVisite))
          .width;
      final double largeurSalle = tester
          .getSize(find.byType(PanneauObservationTuteur))
          .width;
      expect(largeurBandeau, largeurSalle);
      // Le bandeau est en haut : rien au-dessus de lui dans la salle.
      expect(
        tester.getTopLeft(find.byType(BandeauDecompteVisite)).dy,
        tester.getTopLeft(find.byType(PanneauObservationTuteur)).dy,
      );

      // Le direct, reel : la salle est jointe.
      expect(find.text(v.enDirect), findsOneWidget);
      // Trois commandes, pas une de plus : ni micro, ni camera, ni chat.
      expect(find.text(v.sonRecu), findsOneWidget);
      expect(find.text(v.agrandir), findsOneWidget);
      expect(find.text(v.quitter), findsOneWidget);
      expect(find.textContaining('Micro'), findsNothing);
      expect(find.textContaining('micro'), findsNothing);

      // L'enseignant et l'enfant ; le camarade ne sort pas de la vue.
      expect(find.text('Amina'), findsOneWidget);
      expect(find.text('Mariam'), findsWidgets);
      expect(find.text('Camarade'), findsNothing);

      // Tache focalisee : ni navigation, ni disque retour (le retour passe par
      // « Quitter »).
      expect(find.byType(DisqueRetour), findsNothing);
    });

    testWidgets('le decompte descend seconde par seconde, et une horloge qui '
        'recule ne rend pas de temps', (WidgetTester tester) async {
      final _Salle salle = await _entrerEnSalle(tester);
      expect(_texteDecompte(tester), '01:42');

      salle.horloge.avancer(const Duration(seconds: 1));
      salle.battement.add(null);
      await tester.pumpAndSettle();
      expect(_texteDecompte(tester), '01:41');

      salle.horloge.avancer(const Duration(seconds: 1));
      salle.battement.add(null);
      await tester.pumpAndSettle();
      expect(_texteDecompte(tester), '01:40');

      // Reculer l'horloge de la machine ne rallonge pas la visite.
      salle.horloge.reculer(const Duration(minutes: 5));
      salle.battement.add(null);
      await tester.pumpAndSettle();
      expect(_texteDecompte(tester), '01:42');
    });

    testWidgets('pluriel : 2/3 visites restantes', (WidgetTester tester) async {
      await _entrerEnSalle(tester, reponse: _entree(max: 3));
      expect(
        find.text('2/3 visites restantes pour cette séance'),
        findsOneWidget,
      );
    });

    testWidgets('derniere visite : « Aucune visite restante pour cette '
        'seance »', (WidgetTester tester) async {
      await _entrerEnSalle(tester, reponse: _entree(utilisees: 2));
      expect(
        find.text('Aucune visite restante pour cette séance'),
        findsOneWidget,
      );
    });

    testWidgets(
      'les trente dernieres secondes passent au ton d\'avertissement',
      (WidgetTester tester) async {
        await _entrerEnSalle(
          tester,
          reponse: _entree(restant: const Duration(seconds: 20)),
        );
        expect(_texteDecompte(tester), '00:20');
        final BuildContext contexte = tester.element(_decompte);
        final DecoratedBox fond = tester.widget<DecoratedBox>(
          find
              .ancestor(of: _decompte, matching: find.byType(DecoratedBox))
              .first,
        );
        expect(
          (fond.decoration as BoxDecoration).color,
          AppPalette.of(contexte).washWarning.background,
        );
      },
    );

    testWidgets('Agrandir : le support seul, le bandeau et Quitter restent ; '
        'Reduire rend la salle', (WidgetTester tester) async {
      final _Salle salle = await _entrerEnSalle(tester);
      _publierParticipants(salle.moteur);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('vignette-enfant')),
        findsOneWidget,
      );

      await _presser(tester, find.text(v.agrandir));

      expect(find.text(v.reduire), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('vignette-enfant')),
        findsNothing,
      );
      expect(find.text(v.titre), findsNothing);
      expect(find.byType(BandeauDecompteVisite), findsOneWidget);
      expect(find.text(v.quitter), findsOneWidget);
      expect(find.text(v.supportIndisponible), findsOneWidget);

      await _presser(tester, find.text(v.reduire));
      expect(find.text(v.agrandir), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('vignette-enfant')),
        findsOneWidget,
      );
    });

    testWidgets('Quitter demande confirmation ; Annuler garde la visite, '
        'confirmer la referme', (WidgetTester tester) async {
      final _Salle salle = await _entrerEnSalle(tester);

      await _presser(tester, find.text(v.quitter));
      expect(find.text(v.quitterQuestion), findsOneWidget);
      expect(
        find.text(v.quitterConsequence(duree: '1 min 42 s')),
        findsOneWidget,
      );
      await _presser(tester, find.text(t.commun.annuler));

      // Rien n'est referme : la visite continue.
      expect(salle.visites.sorties, isEmpty);
      expect(find.byType(PanneauObservationTuteur), findsOneWidget);

      await _presser(tester, find.text(v.quitter));
      await _presser(tester, find.text(v.quitterConfirmer));
      await _laisserFinir(tester);

      expect(salle.visites.sorties, <String>['s1']);
      expect(salle.moteur.departs, 1);
      expect(find.byType(PanneauObservationTuteur), findsNothing);
      expect(
        find.text(t.tc.observation.resultat.premiereTerminee),
        findsOneWidget,
      );
    });

    testWidgets('le retour du systeme passe par la meme confirmation', (
      WidgetTester tester,
    ) async {
      final _Salle salle = await _entrerEnSalle(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text(v.quitterQuestion), findsOneWidget);
      expect(salle.visites.sorties, isEmpty);
      await _presser(tester, find.text(v.quitterConfirmer));
      await _laisserFinir(tester);
      expect(salle.visites.sorties, <String>['s1']);
    });

    testWidgets('reconnexion : jamais « En direct », le decompte continue sans '
        'remise a zero', (WidgetTester tester) async {
      final _Salle salle = await _entrerEnSalle(tester);
      salle.horloge.avancer(const Duration(seconds: 10));
      salle.battement.add(null);
      await tester.pumpAndSettle();
      expect(_texteDecompte(tester), '01:32');

      salle.moteur.poser(EtatSalle.reconnexion);
      await tester.pumpAndSettle();
      expect(find.text(v.enDirect), findsNothing);
      expect(find.text(v.reconnexion), findsOneWidget);
      expect(find.text(v.reconnexionDetail), findsOneWidget);
      expect(find.text(v.sonInterrompu), findsOneWidget);
      expect(_texteDecompte(tester), '01:32');

      salle.moteur.poser(EtatSalle.retabli);
      await tester.pumpAndSettle();
      expect(find.text(v.enDirect), findsOneWidget);
      expect(find.text(v.sonRecu), findsOneWidget);
      expect(_texteDecompte(tester), '01:32');
    });

    testWidgets('l\'en-tete lit la classe du foyer : nom, enfant, enseignant '
        'avec son titre', (WidgetTester tester) async {
      final _Salle salle = await _entrerEnSalle(
        tester,
        classes: FauxClassesFoyer(
          classes: <ClasseFoyer>[
            ClasseFoyer(
              eleveId: 'enfant-1',
              classe: classeFictive(groupeId: 'c1'),
            ),
          ],
        ),
      );
      _publierParticipants(salle.moteur);
      await tester.pumpAndSettle();

      expect(find.text('Classe fictive A'), findsOneWidget);
      expect(find.text('Mariam · Sayyid Enseignant X'), findsOneWidget);
    });

    testWidgets('sans classe lisible : le titre generique, les noms de la '
        'salle', (WidgetTester tester) async {
      final _Salle salle = await _entrerEnSalle(tester);
      _publierParticipants(salle.moteur);
      await tester.pumpAndSettle();

      expect(find.text(v.titre), findsOneWidget);
      expect(find.text('Mariam · Amina'), findsOneWidget);
    });

    testWidgets('personne encore dans la salle : « Pas encore dans la '
        'salle », jamais « absent »', (WidgetTester tester) async {
      await _entrerEnSalle(tester);
      expect(find.text(v.pasEncoreLa), findsNWidgets(2));
      expect(find.textContaining('absent'), findsNothing);
    });

    testWidgets('quitter la page sans « Quitter » referme la visite', (
      WidgetTester tester,
    ) async {
      final _Salle salle = await _entrerEnSalle(tester);
      await tester.pumpWidget(const SizedBox());
      await _laisserFinir(tester);
      expect(salle.visites.sorties, <String>['s1']);
    });

    testWidgets('hors ligne pendant la visite : le bandeau hors ligne, la '
        'salle reste entiere', (WidgetTester tester) async {
      await _entrerEnSalle(tester, horsLigne: true);
      expect(find.byType(PanneauObservationTuteur), findsOneWidget);
      expect(find.text(v.quitter), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Formats et themes', () {
    testWidgets('bureau 1440 (D1) : le support a gauche, les vignettes en '
        'colonne a droite, la barre pleine largeur', (
      WidgetTester tester,
    ) async {
      final _Salle salle = await _entrerEnSalle(
        tester,
        taille: const Size(1440, 900),
      );
      _publierParticipants(salle.moteur);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final Rect support = tester.getRect(
        find.byKey(const ValueKey<String>('support-observation')),
      );
      final Rect enseignant = tester.getRect(
        find.byKey(const ValueKey<String>('vignette-enseignant')),
      );
      final Rect enfant = tester.getRect(
        find.byKey(const ValueKey<String>('vignette-enfant')),
      );
      // Deux colonnes : les vignettes a droite du support, l'une sous l'autre.
      expect(enseignant.left, greaterThan(support.right));
      expect(enfant.top, greaterThan(enseignant.bottom));
      // Le support domine : environ trois quarts de la largeur.
      expect(support.width, greaterThan(enseignant.width * 3));
      // Son a gauche, Agrandir au centre, Quitter a droite.
      final double son = tester.getCenter(find.text(v.sonRecu)).dx;
      final double agrandir = tester.getCenter(find.text(v.agrandir)).dx;
      final double quitter = tester.getCenter(find.text(v.quitter)).dx;
      expect(son, lessThan(agrandir));
      expect(agrandir, lessThan(quitter));
    });

    testWidgets('tablette 1024x768 et paysage 844x390 : rien ne deborde', (
      WidgetTester tester,
    ) async {
      for (final Size taille in <Size>[
        const Size(1024, 768),
        const Size(844, 390),
      ]) {
        final _Salle salle = await _entrerEnSalle(tester, taille: taille);
        _publierParticipants(salle.moteur);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$taille');
        expect(find.text(v.quitter), findsOneWidget, reason: '$taille');
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    });

    testWidgets('sombre : meme salle, aucune erreur', (
      WidgetTester tester,
    ) async {
      final _Salle salle = await _entrerEnSalle(tester, mode: ThemeMode.dark);
      _publierParticipants(salle.moteur);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_texteDecompte(tester), '01:42');
    });

    testWidgets('texte agrandi a 200 % a 390 : rien ne deborde, Quitter '
        'atteignable', (WidgetTester tester) async {
      final _Salle salle = await _entrerEnSalle(tester, echelleTexte: 2);
      _publierParticipants(salle.moteur);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _presser(tester, find.text(v.quitter));
      expect(find.text(v.quitterQuestion), findsOneWidget);
    });
  });
  // PAGESHELL-200-1 (reserve 2 de la revue OBS-COUPE-1b) : des la
  // tablette, la barre de D1 gardait « Agrandir » au centre a sa largeur
  // propre ; de 680 a 840 px a texte agrandi, « Quitter » n'avait plus que
  // quelques points et se lisait lettre par lettre (« Son recu » aussi a
  // 300 %). Elle passe en deux rangees quand une seule ne tient pas.
  group('PAGESHELL-200-1 : barre large sans mot coupe', () {
    for (final double largeur in const <double>[
      680,
      700,
      720,
      768,
      840,
      1024,
      1440,
    ]) {
      for (final double echelle in const <double>[1, 2, 3]) {
        for (final TextDirection sens in TextDirection.values) {
          testWidgets('${largeur.toInt()}x900, texte x${echelle.toInt()}, '
              '${sens.name}', (WidgetTester tester) async {
            final _Salle salle = await _entrerEnSalle(
              tester,
              taille: Size(largeur, 900),
              echelleTexte: echelle,
              sens: sens,
            );
            _publierParticipants(salle.moteur);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            final Finder barre = find.byType(BarreCommandesObservation);
            expect(barre, findsOneWidget);
            final Rect cadre = tester.getRect(barre);
            for (final String libelle in <String>[
              v.sonRecu,
              v.agrandir,
              v.quitter,
            ]) {
              final Finder texte = find.descendant(
                of: barre,
                matching: find.text(libelle),
              );
              expect(texte, findsOneWidget);
              final Rect r = tester.getRect(texte);
              expect(
                r.left >= cadre.left - 0.5 && r.right <= cadre.right + 0.5,
                isTrue,
                reason: '« $libelle » sort de la barre : $r dans $cadre',
              );
            }
            verifierAucunMotCoupe(tester, barre);
            // D1 reste tenue la ou elle tient : texte a 100 %, son, agrandir
            // et quitter sur une seule rangee.
            if (echelle == 1) {
              expect(
                tester.getCenter(find.text(v.quitter)).dy,
                moreOrLessEquals(
                  tester.getCenter(find.text(v.agrandir)).dy,
                  epsilon: 4,
                ),
              );
            }
          });
        }
      }
    }
  });
  // PAGESHELL-200-1 (reserve 1 de la revue OBS-COUPE-1b) : sur telephone a
  // 200 %, la tete de `PageShell` defile et le corps non defilant recevait
  // toute la hauteur de la vue sous elle ; la salle depassait de la hauteur
  // de la tete et le bas de sa barre passait sous la zone sure au premier
  // affichage (390x844 : bas du panneau a 834 pour une zone sure a 810).
  group('PAGESHELL-200-1 : barre entiere au premier affichage', () {
    const EdgeInsets zoneSure = EdgeInsets.only(top: 47, bottom: 34);
    for (final (Size, double, TextDirection) cas
        in const <(Size, double, TextDirection)>[
          (Size(390, 844), 2, TextDirection.ltr),
          (Size(320, 844), 2, TextDirection.ltr),
          (Size(390, 844), 2, TextDirection.rtl),
          (Size(320, 844), 2, TextDirection.rtl),
          (Size(390, 844), 1, TextDirection.ltr),
          (Size(360, 800), 2, TextDirection.ltr),
        ]) {
      testWidgets('${cas.$1.width.toInt()}x${cas.$1.height.toInt()}, texte '
          'x${cas.$2.toInt()}, ${cas.$3.name}', (WidgetTester tester) async {
        final _Salle salle = await _entrerEnSalle(
          tester,
          taille: cas.$1,
          echelleTexte: cas.$2,
          sens: cas.$3,
          zoneSure: zoneSure,
        );
        _publierParticipants(salle.moteur);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final double basZoneSure = cas.$1.height - zoneSure.bottom;
        // Premier affichage : aucun defilement.
        for (final ScrollableState defileur
            in tester.stateList<ScrollableState>(find.byType(Scrollable))) {
          if (defileur.position.axis == Axis.vertical) {
            expect(defileur.position.pixels, 0);
          }
        }
        final Rect barre = tester.getRect(
          find.byType(BarreCommandesObservation),
        );
        final Rect panneau = tester.getRect(
          find.byType(PanneauObservationTuteur),
        );
        expect(barre.top, greaterThanOrEqualTo(zoneSure.top));
        expect(barre.bottom, lessThanOrEqualTo(basZoneSure));
        expect(panneau.bottom, lessThanOrEqualTo(basZoneSure));
        expect(
          tester.getRect(find.text(v.quitter)).bottom,
          lessThanOrEqualTo(basZoneSure),
        );
        // Rien n'est vole : la salle descend jusqu'au bas de la zone sure.
        expect(panneau.bottom, closeTo(basZoneSure, 0.5));
      });
    }
  });
  // TUILE-TUTEUR-1 : sans image, la vignette du tuteur prend la tuile sans
  // image partagee (VIDEO-TUILE-1) : cercle, nom centre dessous, une seule
  // fois ; « Camera fermee » reste lu.
  group('TUILE-TUTEUR-1 : vignette sans image', () {
    // TUILE-TUTEUR-1b : les deux sens d'ecriture (revue du 4 octobre 2026).
    for (final (Size, double, TextDirection) cas
        in const <(Size, double, TextDirection)>[
          (Size(390, 844), 1, TextDirection.ltr),
          (Size(320, 844), 2, TextDirection.ltr),
          (Size(1440, 900), 1, TextDirection.ltr),
          (Size(390, 844), 1, TextDirection.rtl),
          (Size(320, 844), 2, TextDirection.rtl),
        ]) {
      testWidgets('${cas.$1.width.toInt()} px, texte x${cas.$2.toInt()}, '
          '${cas.$3.name}', (WidgetTester tester) async {
        final _Salle salle = await _entrerEnSalle(
          tester,
          taille: cas.$1,
          echelleTexte: cas.$2,
          sens: cas.$3,
        );
        _publierParticipants(salle.moteur);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        for (final (String cle, String nom) vignette in <(String, String)>[
          ('vignette-enfant', 'Mariam'),
          ('vignette-enseignant', 'Amina'),
        ]) {
          final Finder cadre = find.byKey(ValueKey<String>(vignette.$1));
          final Finder tuile = find.descendant(
            of: cadre,
            matching: find.byType(TuileSansImage),
          );
          expect(tuile, findsOneWidget);
          // Le nom une seule fois : l'etiquette du bas ne le redit pas.
          expect(
            find.descendant(of: cadre, matching: find.text(vignette.$2)),
            findsOneWidget,
          );
          final Rect cercle = tester.getRect(
            find.descendant(
              of: tuile,
              matching: find.byKey(
                const ValueKey<String>('tuile-sans-image-cercle'),
              ),
            ),
          );
          final Rect nomRect = tester.getRect(
            find.descendant(
              of: tuile,
              matching: find.byKey(
                const ValueKey<String>('tuile-sans-image-nom'),
              ),
            ),
          );
          expect(
            nomRect.center.dx,
            moreOrLessEquals(cercle.center.dx, epsilon: 1),
          );
          expect(nomRect.top, greaterThanOrEqualTo(cercle.bottom));
          // Tout dans le cadre.
          final Rect bord = tester.getRect(cadre);
          expect(bord.contains(cercle.topLeft), isTrue);
          expect(nomRect.bottom, lessThanOrEqualTo(bord.bottom + 0.5));
          // TUILE-TUTEUR-1b : un seul noeud porte le nom, celui du cadre ;
          // la tuile ne le redit pas dessous (« Mariam » puis « Mariam,
          // Camera fermee » sur 1910b943).
          expect(
            tester.getSemantics(cadre).label,
            '${vignette.$2}, ${v.cameraFermee}',
          );
          expect(_noeudsNommant(tester, cadre, vignette.$2), 1);
        }
        // OBS-COUPE-1b : la ligne d'attente du support se lit en entier,
        // jamais rognee par sa carte.
        final Rect support = tester.getRect(
          find.byKey(const ValueKey<String>('support-observation')),
        );
        final Rect attente = tester.getRect(find.text(v.supportIndisponible));
        expect(attente.top, greaterThanOrEqualTo(support.top));
        expect(attente.bottom, lessThanOrEqualTo(support.bottom));
        // TUILE-TUTEUR-1b : la vignette se voit vraiment, une fois amenee a
        // l'ecran (a 320 px et 200 %, elle est sous le pli) : son cercle est
        // dans la fenetre, pas seulement dans son cadre.
        final Finder enfant = find.byKey(
          const ValueKey<String>('vignette-enfant'),
        );
        await tester.ensureVisible(enfant);
        await tester.pumpAndSettle();
        final Rect ecran = Offset.zero & cas.$1;
        final Rect cercleEnfant = tester.getRect(
          find.descendant(
            of: enfant,
            matching: find.byKey(
              const ValueKey<String>('tuile-sans-image-cercle'),
            ),
          ),
        );
        expect(ecran.contains(cercleEnfant.topLeft), isTrue);
        expect(ecran.contains(cercleEnfant.bottomRight), isTrue);
        expect(tester.getSemantics(enfant).flagsCollection.isHidden, isFalse);
        // « Camera fermee » est dit au lecteur d'ecran.
        expect(
          find.bySemanticsLabel(RegExp(RegExp.escape(v.cameraFermee))),
          findsNWidgets(2),
        );
      });
    }

    // TUILE-TUTEUR-1b : sans image, la parole se voit par les ondes dans le
    // coin de la tuile (l'etiquette du bas n'est plus la pour les porter), et
    // se dit au lecteur d'ecran.
    for (final TextDirection sens in TextDirection.values) {
      testWidgets('ondes de parole sans image, ${sens.name}', (
        WidgetTester tester,
      ) async {
        final _Salle salle = await _entrerEnSalle(tester, sens: sens);
        salle.moteur.publier(<ParticipantSalle>[
          participantDe(identite: 'prof-1', role: 'teacher', nom: 'Amina'),
          const ParticipantSalle(
            identite: 'enfant-1',
            nom: 'Mariam',
            role: 'student',
            estLocal: false,
            micro: true,
            camera: false,
            parle: true,
            qualite: QualiteLien.bonne,
          ),
        ]);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        Finder ondes(String cle) => find.descendant(
          of: find.descendant(
            of: find.byKey(ValueKey<String>(cle)),
            matching: find.byType(TuileSansImage),
          ),
          matching: find.byIcon(AppIcons.libelleAudio.repos),
        );
        expect(ondes('vignette-enfant'), findsOneWidget);
        expect(ondes('vignette-enseignant'), findsNothing);
        // Dans le coin bas de fin de la tuile.
        final Rect tuile = tester.getRect(
          find.descendant(
            of: find.byKey(const ValueKey<String>('vignette-enfant')),
            matching: find.byType(TuileSansImage),
          ),
        );
        final Rect icone = tester.getRect(ondes('vignette-enfant'));
        expect(icone.center.dy, greaterThan(tuile.center.dy));
        if (sens == TextDirection.ltr) {
          expect(icone.center.dx, greaterThan(tuile.center.dx));
        } else {
          expect(icone.center.dx, lessThan(tuile.center.dx));
        }
        expect(
          tester
              .getSemantics(
                find.byKey(const ValueKey<String>('vignette-enfant')),
              )
              .label,
          '${v.parle(nom: 'Mariam')}, ${v.cameraFermee}',
        );
      });
    }
  });
  // PAGESHELL-200-1b : en Interface guidee a 320 px et 200 %, le titre de
  // la salle, serre contre la pastille du direct, se coupait dans un mot
  // (« Class / e »). La pastille passe sous le titre.
  group('PAGESHELL-200-1b : en-tete sans mot coupe', () {
    for (final InterfaceMode interface in InterfaceMode.values) {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('320x844, texte x2, ${interface.name}, ${sens.name}', (
          WidgetTester tester,
        ) async {
          final _Salle salle = await _entrerEnSalle(
            tester,
            taille: const Size(320, 844),
            echelleTexte: 2,
            sens: sens,
            interface: interface,
            zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
            classes: FauxClassesFoyer(
              classes: <ClasseFoyer>[
                ClasseFoyer(
                  eleveId: 'enfant-1',
                  classe: classeFictive(groupeId: 'c1'),
                ),
              ],
            ),
          );
          _publierParticipants(salle.moteur);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final Finder titre = find.text(classeFictive(groupeId: 'c1').libelle);
          expect(titre, findsOneWidget);
          verifierAucunMotCoupe(tester, titre);
          verifierAucunMotCoupe(tester, find.text(v.enDirect));
        });
      }
    }
  });
  // PAGESHELL-200-1b (reserves 1 et 2 de la revue PAGESHELL-200-1) : a 200 %
  // sous une tete qui defile, le corps recevait `vue - tete` sans connaitre
  // la hauteur dont la salle a besoin (bandeau et barre agrandis). En
  // paysage sous les barres du systeme et en portrait a hauteur atypique, la
  // colonne de la salle debordait et le bas de la barre sortait de la zone
  // sure, sans que la page puisse defiler pour l'atteindre (defileur a 0).
  // Le corps recoit maintenant max(minimum utile, vue - tete) : aucun
  // debordement, et la barre entiere est toujours atteignable.
  group('PAGESHELL-200-1b : geometrie de la salle a 200 %', () {
    // (taille, zone sure, sens, la salle tient-elle sans defiler ?)
    for (final (Size, EdgeInsets, TextDirection, bool) cas
        in const <(Size, EdgeInsets, TextDirection, bool)>[
          // Portrait a hauteur atypique : debordait (17, 5 et 4 px).
          (
            Size(320, 568),
            EdgeInsets.only(top: 47, bottom: 34),
            TextDirection.ltr,
            false,
          ),
          (
            Size(320, 568),
            EdgeInsets.only(top: 47, bottom: 34),
            TextDirection.rtl,
            false,
          ),
          (
            Size(320, 580),
            EdgeInsets.only(top: 47, bottom: 34),
            TextDirection.ltr,
            false,
          ),
          (Size(320, 520), EdgeInsets.only(top: 20), TextDirection.ltr, false),
          // Paysage sous les barres d'Android : debordait (56, 32, 26 et
          // 2 px), sans pouvoir defiler.
          (
            Size(800, 360),
            EdgeInsets.only(top: 24, bottom: 48),
            TextDirection.ltr,
            false,
          ),
          (
            Size(800, 360),
            EdgeInsets.only(top: 24, bottom: 48),
            TextDirection.rtl,
            false,
          ),
          (
            Size(800, 360),
            EdgeInsets.only(top: 24, bottom: 24),
            TextDirection.ltr,
            false,
          ),
          (
            Size(844, 390),
            EdgeInsets.only(top: 24, bottom: 48),
            TextDirection.ltr,
            false,
          ),
          (
            Size(896, 414),
            EdgeInsets.only(top: 24, bottom: 48),
            TextDirection.ltr,
            false,
          ),
          // PAGESHELL-200-1c : ces vues tenaient sans defiler, mais la zone
          // du support n'y etait qu'une fenetre de 60, 139, 48 et 65 px ou
          // l'on ne voyait que le haut de l'en-tete. Elles defilent
          // maintenant, et la page montre l'en-tete et le support entiers.
          (
            Size(360, 640),
            EdgeInsets.only(top: 24, bottom: 48),
            TextDirection.ltr,
            false,
          ),
          (Size(375, 667), EdgeInsets.only(top: 20), TextDirection.ltr, false),
          (
            Size(844, 390),
            EdgeInsets.only(left: 47, right: 47, bottom: 21),
            TextDirection.ltr,
            false,
          ),
          (
            Size(932, 430),
            EdgeInsets.only(left: 59, right: 59, bottom: 21),
            TextDirection.rtl,
            false,
          ),
          // Non-regression : ce qui tenait avec une zone du support d'au
          // moins sa hauteur lisible tient toujours, sans defiler.
          (
            Size(414, 896),
            EdgeInsets.only(top: 44, bottom: 34),
            TextDirection.rtl,
            true,
          ),
        ]) {
      final Size taille = cas.$1;
      final EdgeInsets zone = cas.$2;
      testWidgets('${taille.width.toInt()}x${taille.height.toInt()} '
          '(zone sure ${zone.top.toInt()}/${zone.bottom.toInt()}), '
          '${cas.$3.name}', (WidgetTester tester) async {
        final _Salle salle = await _entrerEnSalle(
          tester,
          taille: taille,
          echelleTexte: 2,
          sens: cas.$3,
          zoneSure: zone,
        );
        _publierParticipants(salle.moteur);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final double hautZone = zone.top;
        final double basZone = taille.height - zone.bottom;
        // Le defileur de la page, s'il y en a un (tete qui defile).
        final List<ScrollableState> page = tester
            .stateList<ScrollableState>(
              find.ancestor(
                of: find.byType(PanneauObservationTuteur),
                matching: find.byType(Scrollable),
              ),
            )
            .toList();
        final ScrollPosition? position = page.isEmpty
            ? null
            : page.last.position;
        if (cas.$4) {
          expect(position?.maxScrollExtent ?? 0, 0);
        }
        // En haut de la page : le bandeau du decompte commence dans la zone
        // sure.
        position?.jumpTo(0);
        await tester.pump();
        expect(
          tester.getRect(find.byType(BandeauDecompteVisite)).top,
          greaterThanOrEqualTo(hautZone - 0.5),
        );
        // Au bout de la page : la barre entiere est dans la zone sure.
        position?.jumpTo(position.maxScrollExtent);
        await tester.pump();
        expect(tester.takeException(), isNull);
        final Rect barre = tester.getRect(
          find.byType(BarreCommandesObservation),
        );
        expect(barre.top, greaterThanOrEqualTo(hautZone - 0.5));
        expect(barre.bottom, lessThanOrEqualTo(basZone + 0.5));
        for (final String libelle in <String>[
          v.sonRecu,
          v.agrandir,
          v.quitter,
        ]) {
          final Rect r = tester.getRect(find.text(libelle));
          expect(r.top, greaterThanOrEqualTo(hautZone - 0.5));
          expect(r.bottom, lessThanOrEqualTo(basZone + 0.5));
        }
        // Sous une tete qui defile, la zone du support garde au moins une
        // cible tactile de hauteur (bandeau, ecart, support, ecart, barre :
        // borne basse en paysage, ou la carte ajoute sa marge).
        if (position != null) {
          final double support =
              barre.top -
              tester.getRect(find.byType(BandeauDecompteVisite)).bottom -
              2 * AppSpacing.md;
          expect(support, greaterThanOrEqualTo(AppTouchTarget.standard));
        }
        // PAGESHELL-200-1c : une salle qui ne tient pas fait defiler la
        // page, et sa zone du support montre l'en-tete et le support
        // entiers, sans defilement imbrique.
        if (!cas.$4) {
          expect(position?.maxScrollExtent ?? 0, greaterThan(0));
          await _verifierSupportVisible(tester);
        }
      });
    }
  });
  // PAGESHELL-200-1c (reserve 2 de la revue PAGESHELL-200-1b) : 667x375 sans
  // zone sure, a 200 %, la tete restait fixe (vue de 375, gabarit tablette)
  // et la colonne de la salle debordait de 45 px, de 213 en Interface
  // guidee, la barre hors d'atteinte. La page passe en defilement global.
  // PAGESHELL-200-1c, non-regression : a 100 %, un telephone en paysage
  // garde sa tete fixe et sa barre au premier affichage ; le minimum utile
  // du support ne fait pas defiler une salle qui tient.
  group('PAGESHELL-200-1c : paysage a 100 %, barre au premier affichage', () {
    for (final (Size, EdgeInsets) cas in const <(Size, EdgeInsets)>[
      (Size(667, 375), EdgeInsets.zero),
      (Size(844, 390), EdgeInsets.only(left: 47, right: 47, bottom: 21)),
      (Size(800, 400), EdgeInsets.only(top: 24, bottom: 16)),
    ]) {
      testWidgets('${cas.$1.width.toInt()}x${cas.$1.height.toInt()}', (
        WidgetTester tester,
      ) async {
        final _Salle salle = await _entrerEnSalle(
          tester,
          taille: cas.$1,
          zoneSure: cas.$2,
        );
        _publierParticipants(salle.moteur);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final double bas = cas.$1.height - cas.$2.bottom;
        for (final String libelle in <String>[
          v.sonRecu,
          v.agrandir,
          v.quitter,
        ]) {
          expect(
            tester.getRect(find.text(libelle)).bottom,
            lessThanOrEqualTo(bas + 0.5),
          );
        }
      });
    }
  });
  group('PAGESHELL-200-1c : 667x375 sans zone sure, a 200 %', () {
    for (final InterfaceMode interface in InterfaceMode.values) {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('${interface.name}, ${sens.name}', (
          WidgetTester tester,
        ) async {
          final _Salle salle = await _entrerEnSalle(
            tester,
            taille: const Size(667, 375),
            echelleTexte: 2,
            sens: sens,
            interface: interface,
          );
          _publierParticipants(salle.moteur);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final ScrollPosition page = tester
              .stateList<ScrollableState>(
                find.ancestor(
                  of: find.byType(PanneauObservationTuteur),
                  matching: find.byType(Scrollable),
                ),
              )
              .last
              .position;
          expect(page.maxScrollExtent, greaterThan(0));
          page.jumpTo(page.maxScrollExtent);
          await tester.pump();
          expect(tester.takeException(), isNull);
          for (final String libelle in <String>[
            v.sonRecu,
            v.agrandir,
            v.quitter,
          ]) {
            final Rect r = tester.getRect(find.text(libelle));
            expect(r.top, greaterThanOrEqualTo(-0.5));
            expect(r.bottom, lessThanOrEqualTo(375 + 0.5));
          }
          page.jumpTo(0);
          await tester.pump();
          await _verifierSupportVisible(tester);
        });
      }
    }
  });
}

/// PAGESHELL-200-1c : la zone du support (le defileur imbrique de la salle)
/// montre, sans defiler, l'en-tete et le support a sa hauteur lisible. Avant,
/// elle pouvait n'etre qu'une fenetre de 48 px sur le haut de l'en-tete.
Future<void> _verifierSupportVisible(WidgetTester tester) async {
  final Finder support = find.byKey(
    const ValueKey<String>('support-observation'),
  );
  final Finder zone = find
      .ancestor(of: support, matching: find.byType(Scrollable))
      .first;
  final ScrollPosition imbrique = tester.state<ScrollableState>(zone).position;
  imbrique.jumpTo(imbrique.minScrollExtent);
  await tester.pump();
  final Rect cadre = tester.getRect(zone);
  final Rect r = tester.getRect(support);
  expect(r.height, greaterThanOrEqualTo(200 - 0.5));
  expect(r.top, greaterThanOrEqualTo(cadre.top - 0.5));
  expect(r.bottom, lessThanOrEqualTo(cadre.bottom + 0.5));
  // L'en-tete aussi, pastille du direct comprise.
  final Rect pastille = tester.getRect(
    find.descendant(of: zone, matching: find.text(v.enDirect)),
  );
  expect(pastille.top, greaterThanOrEqualTo(cadre.top - 0.5));
  expect(pastille.bottom, lessThanOrEqualTo(cadre.bottom + 0.5));
}

/// Le nombre de noeuds semantiques, sous [cadre] compris, dont le libelle
/// contient [nom].
int _noeudsNommant(WidgetTester tester, Finder cadre, String nom) {
  int n = 0;
  void visiter(SemanticsNode noeud) {
    if (noeud.label.contains(nom)) n++;
    noeud.visitChildren((SemanticsNode enfant) {
      visiter(enfant);
      return true;
    });
  }

  visiter(tester.getSemantics(cadre));
  return n;
}
