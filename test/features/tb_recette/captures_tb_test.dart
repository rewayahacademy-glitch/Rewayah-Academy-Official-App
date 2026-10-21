// TB-1b : squelette des captures du chantier Supports et tableau.
//
// Sautees sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md). Chaque etape
// TB ajoute ses situations a `_situationsCapturees` et garde les cadrages de
// la definition de « fait » (02_DECOUPAGE) : 390x844, 768x1024, 1440x900,
// clair et sombre, texte x2 aux trois tailles, 320 x1 et x2 (320 x 700 @2,
// le cadrage de salle_200_test).
//
// La page montee est `DemoSallePage`, celle que sert `/demo/salle?role=…&tb=…`.
//
// Commande :
//   CAPTURE_DIR=/tmp/tb flutter test test/features/tb_recette/captures_tb_test.dart
//
// TB-2 (VIS-01) : la barre de l'appel au repos (masquee apres le delai) et
// revelee (une touche sur le contenu), pour l'enseignant, l'eleve et le Mode
// Accessibilite (guidee), situation VIS-01. Rangees dans
// docs/current/captures/TB-2/ :
//   CAPTURE_DIR=docs/current/captures/TB-2 flutter test \
//     test/features/tb_recette/captures_tb_test.dart --name tb2_
//
// TB-3 (UI-01, CTX-01, CTX-02) : la capsule pendant le partage (UI-01) et le
// contexte deplie a la section du controle (CTX-02), pour l'enseignant,
// l'eleve et le Mode Accessibilite (guidee, pendant la visite du tuteur : la
// notice de l'enfant reste visible), plus RTL. Rangees dans
// docs/current/captures/TB-3/ :
//   CAPTURE_DIR=docs/current/captures/TB-3 flutter test \
//     test/features/tb_recette/captures_tb_test.dart --name tb3_
//
// TB-4 (CMD-01) : le declencheur « Commandes » ferme (PED-03), le panneau
// ouvert sur l'onglet « Support » et sur l'onglet « Outils » (CMD-01) pour
// l'enseignant ; l'eleve en CMD-01, sans rien de l'enseignant. 390, 768,
// 1440 et 320, texte x1 et x2, clair et sombre, plus RTL. Rangees dans
// docs/current/captures/TB-4/ :
//   CAPTURE_DIR=docs/current/captures/TB-4 flutter test \
//     test/features/tb_recette/captures_tb_test.dart --name tb4_
//
// TB-5 (UI-02, UI-03) : la salle de l'enseignant developpee (Participants a
// gauche, Commandes ouvertes a droite) et en focus, 768, 1024 et 1440, texte
// x1 et x2, clair (et sombre a x1), plus RTL a 1440. Rangees dans
// docs/current/captures/TB-5/ :
//   CAPTURE_DIR=docs/current/captures/TB-5 flutter test \
//     test/features/tb_recette/captures_tb_test.dart --name tb5_
//
// TB-6 (PED-01 a PED-04) : tableau libre, Support, Avec notes, Tableau,
// enseignant et eleve, 390 et 1440 clair et sombre, 390 x2, 320 x2. Rangees dans
// docs/current/captures/TB-6/ :
//   CAPTURE_DIR=docs/current/captures/TB-6 flutter test \
//     test/features/tb_recette/captures_tb_test.dart --name tb6_
//
// TB-7a : le calque au repere de la page, cercle de demonstration en PED-03
// (enseignant, eleve) et PED-04 (enseignant), 390 et 1440 clair et sombre,
// 390 x2, 320 x2 ; la page lue a 200 % (enseignant, 390 et 1440). Rangees
// dans docs/current/captures/TB-7a/ :
//   CAPTURE_DIR=docs/current/captures/TB-7a flutter test \
//     test/features/tb_recette/captures_tb_test.dart --name tb7a_
// (tb7a_trait_pose_* : un trait trace au doigt, outil arme et depot en
// memoire, capture apres le lever du doigt, puis a 200 %.)
//
// TB-8 (LIB-01 a LIB-04) : catalogue, apercu personnel, ouverture et echec,
// 390 et 1440 clair et sombre, 390 x2, 320 x2. Rangees dans
// docs/current/captures/TB-8/ :
//   CAPTURE_DIR=docs/current/captures/TB-8 flutter test \
//     test/features/tb_recette/captures_tb_test.dart --name tb8_
//
// TB-9 (ranger, reprendre, effacer) : avant (menu du titre ouvert), apres
// le rangement, la carte rangee et son point de reprise, confirmation
// d'effacement de la page et du tableau libre ; 390 et 1440 clair et
// sombre, 320 x2 clair et sombre. Rangees dans docs/current/captures/TB-9/ :
//   CAPTURE_DIR=docs/current/captures/TB-9 flutter test \
//     test/features/tb_recette/captures_tb_test.dart --name tb9_
//
// TB-11a : le tuteur observateur et le controleur, presentation en
// lecture seule (PED-01 a PED-04), 390 et 1440 clair et sombre, x2, 320 x2.
// Rangees dans docs/current/captures/TB-11a/ :
//   CAPTURE_DIR=docs/current/captures/TB-11a flutter test \
//     test/features/tb_recette/captures_tb_test.dart --name tb11a_
//
// TB-7b (CMD-02, CMD-03) : Ecrire. La palette courte (panneau ferme, un
// trait pose : outil actif, Annuler, Terminer), 390 x1 et 320 x2, clair et
// sombre ; le panneau ouvert (Commandes > Outils > Ecrire, options Couleur
// et Epaisseur), 1440 et 390, clair et sombre ; « le stylet n'ecrit que si
// Ecrire est actif » : un geste au stylet en lecture (rien ne reste) puis
// le meme geste avec Ecrire (le trait), 390 et 1440. Rangees dans
// docs/current/captures/TB-7b/ :
//   CAPTURE_DIR=docs/current/captures/TB-7b flutter test \
//     test/features/tb_recette/captures_tb_test.dart --name tb7b_
//
// TB-10 (plan V2 §5, §12, §19.3 ; UX-20 ; MA-CMD-1) : l'eleve autorise
// (information courte, Commandes avec Ecrire, palette apres un trait) et le
// droit retire, eleve standard et Mode Accessibilite (guidee), 390 x1 et
// x2, 1440, 320 x2, clair et sombre ; l'enseignant qui vient d'autoriser
// Mariam (fiche depliee, « Peut ecrire », « Retirer l'autorisation
// d'ecrire »), 1440 et 390, x1 et x2, 320 x2. Rangees dans
// docs/current/captures/TB-10/ :
//   CAPTURE_DIR=docs/current/captures/TB-10 flutter test \
//     test/features/tb_recette/captures_tb_test.dart --name tb10_
//
// TB-11b (plan V2 §10 a §12, §19.5) : synchronisation interrompue (ERR-01,
// enseignant et eleve), reprise (ERR-02), sauvegarde en echec (ERR-03) et
// conservation dans la seance ; 390 et 1440 clair et sombre, 320 x2 clair
// et sombre. Rangees dans docs/current/captures/TB-11b/ :
//   CAPTURE_DIR=docs/current/captures/TB-11b flutter test \
//     test/features/tb_recette/captures_tb_test.dart --name tb11b_
//
// AR-SALLE-1 : la salle en arabe (RTL), enseignant et eleve, 390 et 1440
// clair et sombre, 320 x2. Rangees dans docs/current/captures/AR-SALLE-1/ :
//   CAPTURE_DIR=docs/current/captures/AR-SALLE-1 flutter test \
//     test/features/tb_recette/captures_tb_test.dart --name ar_salle_
//
// TB-12 (recette) : cadrages ajoutes aux etapes (suffixe `_ar` : arabe,
// RTL, locale `ar`) :
//   TB-5 focus au telephone (390, 320 x1 et x2), developpe Commandes
//     fermees (1440 clair et sombre, 1024), telephone 320 x1 ;
//   TB-6 768 (x1 clair et sombre, x2), 1440 x2, 320 x1 ; Mode
//     Accessibilite (guidee) ; arabe (trois roles, PED-01 et PED-03) ;
//   TB-7a 768 x1 et x2 ; arabe ;
//   TB-7b palette AVANT le premier trait (320 et 390 x1) ; panneau Ecrire
//     a x2, colonne en tete, non defilee (390, 768, 1440, 320) ;
//   TB-8 recherche vide (LIB-04), 768, 320 x2 sombre ; arabe (catalogue,
//     recherche vide) ;
//   TB-9 390 x2, 768 ; arabe (avant, apres) ; l'eleve apres le rangement ;
//   TB-10 l'enseignant : prenom de Mariam et « Peut ecrire » visibles
//     ensemble dans la liste ;
//   TB-11a 768 ; arabe ;
//   TB-11b 768, x2 a 390 et 1440, 320 x1 ; arabe.
// Et la matrice de recette tb12_ (cinq profils, trois etats, quatorze
// cadrages, plus le rangement en cours en mouvement reduit et ordinaire),
// rangee dans docs/current/captures/TB-12/ :
//   CAPTURE_DIR=docs/current/captures/TB-12 flutter test \
//     test/features/tb_recette/captures_tb_test.dart --name tb12_

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/commandes_masquables.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/mouvement/envol_vers_cible.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart'
    show LibellesGroupe;
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart'
    show AnnotationLayer, OutilTrait, PointNormalise, TraitVectoriel;
import 'package:rewayah_academy/core/tc_outils/etat_outils.dart';
import 'package:rewayah_academy/core/tc_outils/port_annotations.dart';
import 'package:rewayah_academy/core/tc_outils/port_dock_hote.dart'
    show OutilDock;
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/salle_observateur_demo.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/bibliotheque_seance.dart';
import 'package:rewayah_academy/features/salle_seance/capsule_seance.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/composition_salle.dart';
import 'package:rewayah_academy/features/salle_seance/ecriture_seance.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/salle_seance/zone_support.dart';
import 'package:rewayah_academy/features/tc_catalogue/surface_bibliotheque.dart';
import 'package:rewayah_academy/features/tc_dock/barre_stylet.dart';

import '../../capture/outil_capture.dart';

/// L'outil d'ecriture arme (TB-7b le donnera par « Ecrire »).
class _ControleurArme extends ControleurOutils {
  @override
  EtatOutils build() => const EtatOutils(outilActif: OutilDock.stylet);
}

/// L'entree « Commandes » : le declencheur, ou, pendant l'ecriture, le
/// dernier bouton de la palette courte qui a pris sa place (TB-7b).
final Finder _entreeCommandes = find.byWidgetPredicate(
  (Widget w) =>
      w.key == DeclencheurCommandes.cle || w.key == BarreStylet.cleCommandes,
);

typedef _Cadrage = (
  String nom,
  Size logique,
  double densite,
  EdgeInsets zone,
  double texte,
  ThemeMode mode,
);

const EdgeInsets _zoneTelephone = EdgeInsets.only(top: 47, bottom: 34);

/// Les cadrages de la definition de « fait » (02_DECOUPAGE, point 3).
const List<_Cadrage> _cadragesTb = <_Cadrage>[
  ('390_x1_clair', Size(390, 844), 3, _zoneTelephone, 1, ThemeMode.light),
  ('390_x1_sombre', Size(390, 844), 3, _zoneTelephone, 1, ThemeMode.dark),
  ('390_x2_clair', Size(390, 844), 3, _zoneTelephone, 2, ThemeMode.light),
  ('768_x1_clair', Size(768, 1024), 2, EdgeInsets.zero, 1, ThemeMode.light),
  ('768_x1_sombre', Size(768, 1024), 2, EdgeInsets.zero, 1, ThemeMode.dark),
  ('768_x2_clair', Size(768, 1024), 2, EdgeInsets.zero, 2, ThemeMode.light),
  ('1440_x1_clair', Size(1440, 900), 1, EdgeInsets.zero, 1, ThemeMode.light),
  ('1440_x1_sombre', Size(1440, 900), 1, EdgeInsets.zero, 1, ThemeMode.dark),
  ('1440_x2_clair', Size(1440, 900), 1, EdgeInsets.zero, 2, ThemeMode.light),
  ('320_x1_clair', Size(320, 700), 2, EdgeInsets.zero, 1, ThemeMode.light),
  ('320_x2_clair', Size(320, 700), 2, EdgeInsets.zero, 2, ThemeMode.light),
];

/// TB-12 : les cadrages sombres a texte x2 hors de la liste de « fait ».
const List<_Cadrage> _cadragesPlus = <_Cadrage>[
  ('390_x2_sombre', Size(390, 844), 3, _zoneTelephone, 2, ThemeMode.dark),
  ('320_x2_sombre', Size(320, 700), 2, EdgeInsets.zero, 2, ThemeMode.dark),
];

/// Les cadrages nommes, dans l'ordre de [noms].
List<_Cadrage> _parNoms(List<String> noms) => <_Cadrage>[
  for (final String n in noms)
    <_Cadrage>[
      ..._cadragesTb,
      ..._cadragesPlus,
    ].firstWhere((_Cadrage c) => c.$1 == n),
];

/// TB-12 : un groupe dont les tests tournent en arabe (RTL), la locale
/// rendue au francais apres chacun.
void _groupeArabe(String nom, void Function() corps) => group(nom, () {
  setUp(() => LocaleSettings.setLocale(AppLocale.ar));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  corps();
});

/// La salle montee est-elle en arabe, de droite a gauche ?
void _verifierRtl(WidgetTester tester) => expect(
  Directionality.of(tester.element(find.byType(DemoSallePage))),
  TextDirection.rtl,
);

/// Les situations capturees, par role. TB-1b n'a aucune disposition
/// nouvelle : une seule situation, la salle et ses personnes (SAL-00),
/// prouve que le squelette tourne. Chaque etape ajoute les siennes.
const Map<RoleSeance, List<SituationTb>> _situationsCapturees =
    <RoleSeance, List<SituationTb>>{
      RoleSeance.eleve: <SituationTb>[SituationTb.sal00],
      RoleSeance.guidee: <SituationTb>[SituationTb.sal00],
      RoleSeance.enseignant: <SituationTb>[SituationTb.sal00],
    };

/// L'opacite visee par le fondu de la barre de l'appel.
double _opaciteBarre(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.ancestor(
        of: find.byKey(CommandesMasquables.commandesKey),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

void main() {
  test('le delai de masquage est celui de CommandesMasquables (4 s)', () {
    // Une seule valeur (plan V2 §18.1, TB7) : aucune seconde constante.
    expect(CommandesMasquables.delaiParDefaut, const Duration(seconds: 4));
  });

  test('chaque situation capturee a un sens pour son role', () {
    _situationsCapturees.forEach((RoleSeance role, List<SituationTb> l) {
      for (final SituationTb s in l) {
        expect(s.concerne(role), isTrue, reason: '${role.name} ${s.name}');
      }
    });
  });

  group(
    'TB-2 : barre de l\'appel au repos et revelee',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);

      for (final RoleSeance role in RoleSeance.values) {
        for (final _Cadrage cas in _cadragesTb) {
          for (final bool revelee in <bool>[false, true]) {
            final String nom =
                'tb2_${role.name}_${revelee ? 'revelee' : 'repos'}_${cas.$1}';
            testWidgets(nom, (WidgetTester tester) async {
              fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
              await tester.pumpWidget(
                hoteCapture(
                  DemoSallePage(role: role, situation: SituationTb.vis01),
                  themeMode: cas.$6,
                  echelleTexte: cas.$5,
                ),
              );
              await stabiliser(tester);
              // Le delai passe : la barre se masque (repos).
              await tester.pump(CommandesMasquables.delaiParDefaut);
              await tester.pump(const Duration(seconds: 1));
              if (revelee) {
                // Une touche au centre du support (pas un point fixe de
                // l'ecran : a texte x2, le tiers de la hauteur tombe dans
                // l'en-tete, hors de CommandesMasquables, et rien ne se
                // revelait) : la barre revient, rien d'autre ne change.
                await tester.tapAt(
                  tester.getCenter(find.byType(ZoneSupport).first),
                );
                // Un cadre pour lancer le fondu, puis sa duree.
                await tester.pump();
                await tester.pump(const Duration(milliseconds: 400));
              }
              // La capture prouve ce qu'elle nomme : barre a pleine opacite
              // une fois revelee, effacee au repos.
              expect(
                _opaciteBarre(tester),
                revelee ? 1 : 0,
                reason: '$nom : opacite de la barre',
              );
              expect(tester.takeException(), isNull);
              debugPrint('PNG ${await capturer(tester, nom)}');
            });
          }
        }
      }
    },
  );

  group('TB-3 : capsule et contexte', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    // Les cadrages de « fait », plus le sens de lecture force (K-41 n. 12).
    final List<(_Cadrage, TextDirection)> cadrages =
        <(_Cadrage, TextDirection)>[
          for (final _Cadrage c in _cadragesTb) (c, TextDirection.ltr),
          (
            (
              '390_x1_clair_rtl',
              const Size(390, 844),
              3,
              _zoneTelephone,
              1,
              ThemeMode.light,
            ),
            TextDirection.rtl,
          ),
          (
            (
              '320_x2_clair_rtl',
              const Size(320, 700),
              2,
              EdgeInsets.zero,
              2,
              ThemeMode.light,
            ),
            TextDirection.rtl,
          ),
        ];
    for (final RoleSeance role in RoleSeance.values) {
      for (final SituationTb situation in <SituationTb>[
        SituationTb.ui01,
        SituationTb.ctx02,
      ]) {
        for (final (_Cadrage cas, TextDirection sens) in cadrages) {
          final String nom = 'tb3_${role.name}_${situation.name}_${cas.$1}';
          testWidgets(nom, (WidgetTester tester) async {
            fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
            await tester.pumpWidget(
              hoteCapture(
                Directionality(
                  textDirection: sens,
                  child: DemoSallePage(
                    role: role,
                    situation: situation,
                    // Mode Accessibilite : la visite du tuteur, pour que la
                    // notice de l'enfant figure sur la capture.
                    etat: role == RoleSeance.guidee
                        ? EtatDemoSalle.visite
                        : null,
                  ),
                ),
                themeMode: cas.$6,
                echelleTexte: cas.$5,
              ),
            );
            await stabiliser(tester);
            await tester.pump(const Duration(milliseconds: 1400));
            // La capture prouve ce qu'elle nomme.
            expect(find.byKey(CapsuleSeance.cle), findsOneWidget);
            expect(
              find.byKey(SectionContexte.cle),
              situation == SituationTb.ctx02 ? findsOneWidget : findsNothing,
            );
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    }
  });

  group('TB-4 : declencheur et panneau Commandes', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    // 390, 768, 1440 et 320 ; x1 et x2 ; clair et sombre ; plus RTL.
    final List<(_Cadrage, TextDirection)> cadrages =
        <(_Cadrage, TextDirection)>[
          for (final (String, Size, double, EdgeInsets) taille
              in <(String, Size, double, EdgeInsets)>[
                ('390', const Size(390, 844), 3, _zoneTelephone),
                ('768', const Size(768, 1024), 2, EdgeInsets.zero),
                ('1440', const Size(1440, 900), 1, EdgeInsets.zero),
                ('320', const Size(320, 700), 2, EdgeInsets.zero),
              ])
            for (final double texte in <double>[1, 2])
              for (final ThemeMode mode in <ThemeMode>[
                ThemeMode.light,
                ThemeMode.dark,
              ])
                (
                  (
                    '${taille.$1}_x${texte.toInt()}_'
                        '${mode == ThemeMode.light ? 'clair' : 'sombre'}',
                    taille.$2,
                    taille.$3,
                    taille.$4,
                    texte,
                    mode,
                  ),
                  TextDirection.ltr,
                ),
          for (final (String, Size, double, EdgeInsets, double) taille
              in <(String, Size, double, EdgeInsets, double)>[
                ('390_x1', const Size(390, 844), 3, _zoneTelephone, 1),
                ('1440_x1', const Size(1440, 900), 1, EdgeInsets.zero, 1),
                ('320_x2', const Size(320, 700), 2, EdgeInsets.zero, 2),
              ])
            (
              (
                '${taille.$1}_clair_rtl',
                taille.$2,
                taille.$3,
                taille.$4,
                taille.$5,
                ThemeMode.light,
              ),
              TextDirection.rtl,
            ),
        ];
    // Enseignant : ferme, onglet Support, onglet Outils ; eleve : CMD-01.
    for (final (RoleSeance role, SituationTb situation, String etat)
        in <(RoleSeance, SituationTb, String)>[
          (RoleSeance.enseignant, SituationTb.ped03, 'ferme'),
          (RoleSeance.enseignant, SituationTb.cmd01, 'support'),
          (RoleSeance.enseignant, SituationTb.cmd01, 'outils'),
          (RoleSeance.eleve, SituationTb.cmd01, 'sans'),
        ]) {
      for (final (_Cadrage cas, TextDirection sens) in cadrages) {
        final String nom = 'tb4_${role.name}_${etat}_${cas.$1}';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
          await tester.pumpWidget(
            hoteCapture(
              Directionality(
                textDirection: sens,
                child: DemoSallePage(role: role, situation: situation),
              ),
              themeMode: cas.$6,
              echelleTexte: cas.$5,
            ),
          );
          await stabiliser(tester);
          if (etat == 'outils') {
            await tester.tap(
              find.descendant(
                of: find.byKey(CommandesPedagogiques.cleOnglets),
                matching: find.text('Outils'),
              ),
            );
            await stabiliser(tester);
          }
          await tester.pump(const Duration(milliseconds: 1400));
          // La capture prouve ce qu'elle nomme.
          final bool ouvert = etat == 'support' || etat == 'outils';
          expect(
            find.byKey(CommandesPedagogiques.cle),
            ouvert ? findsOneWidget : findsNothing,
          );
          // Revue du 09/10 : Commandes ouvertes, le declencheur s'efface
          // (le panneau porte le titre et « Reduire »). TB-10 : l'eleve a
          // aussi son declencheur (lecture, focus, ecriture accordee).
          expect(
            find.byKey(DeclencheurCommandes.cle),
            ouvert ? findsNothing : findsOneWidget,
          );
          if (etat == 'outils') {
            expect(
              find.byKey(const ValueKey<String>('outil-pointeur')),
              findsOneWidget,
            );
          }
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }
  });

  group('TB-5 : bureau equilibre et focus', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    final List<(String, Size, double, ThemeMode, TextDirection)> cadrages =
        <(String, Size, double, ThemeMode, TextDirection)>[
          for (final (String, Size) taille in <(String, Size)>[
            ('768', const Size(768, 1024)),
            ('1024', const Size(1024, 768)),
            ('1440', const Size(1440, 900)),
          ]) ...<(String, Size, double, ThemeMode, TextDirection)>[
            (
              '${taille.$1}_x1_clair',
              taille.$2,
              1,
              ThemeMode.light,
              TextDirection.ltr,
            ),
            (
              '${taille.$1}_x1_sombre',
              taille.$2,
              1,
              ThemeMode.dark,
              TextDirection.ltr,
            ),
            (
              '${taille.$1}_x2_clair',
              taille.$2,
              2,
              ThemeMode.light,
              TextDirection.ltr,
            ),
          ],
          (
            '1440_x1_clair_rtl',
            const Size(1440, 900),
            1,
            ThemeMode.light,
            TextDirection.rtl,
          ),
        ];
    for (final String etat in <String>['developpe', 'focus']) {
      for (final (String, Size, double, ThemeMode, TextDirection) cas
          in cadrages) {
        final String nom = 'tb5_enseignant_${etat}_${cas.$1}';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, cas.$2, cas.$2.width < 1200 ? 2 : 1);
          await tester.pumpWidget(
            hoteCapture(
              Directionality(
                textDirection: cas.$5,
                child: const DemoSallePage(
                  role: RoleSeance.enseignant,
                  situation: SituationTb.cmd01,
                ),
              ),
              themeMode: cas.$4,
              echelleTexte: cas.$3,
            ),
          );
          await stabiliser(tester);
          if (etat == 'focus') {
            final Finder focus = find.byKey(CommandesPedagogiques.cleFocus);
            await tester.ensureVisible(focus);
            await tester.pump();
            await tester.tap(focus);
            await stabiliser(tester);
          }
          await tester.pump(const Duration(milliseconds: 1400));
          // La capture prouve ce qu'elle nomme.
          final bool colonne =
              cas.$2.width / cas.$3 >= CompositionSalle.seuilColonne;
          expect(
            find.byType(PanneauEleves),
            etat == 'developpe' && colonne ? findsOneWidget : findsNothing,
          );
          expect(
            find.byKey(CommandesPedagogiques.cle),
            etat == 'developpe' ? findsOneWidget : findsNothing,
          );
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }
  });

  // TB-5 : au telephone, pendant le partage, pas de rangee « Eleves »
  // (l'avatar de la capsule ouvre les Participants) ; le support reprend la
  // place qui lui manquait a 320 x2 (reste de TB-4).
  group('TB-5 : telephone pendant le partage', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String, Size, double, EdgeInsets, double, ThemeMode) cas
        in <(String, Size, double, EdgeInsets, double, ThemeMode)>[
          (
            '390_x1_clair',
            const Size(390, 844),
            3,
            _zoneTelephone,
            1,
            ThemeMode.light,
          ),
          (
            '390_x2_clair',
            const Size(390, 844),
            3,
            _zoneTelephone,
            2,
            ThemeMode.light,
          ),
          (
            '320_x1_clair',
            const Size(320, 700),
            2,
            EdgeInsets.zero,
            1,
            ThemeMode.light,
          ),
          (
            '320_x2_clair',
            const Size(320, 700),
            2,
            EdgeInsets.zero,
            2,
            ThemeMode.light,
          ),
          (
            '320_x2_sombre',
            const Size(320, 700),
            2,
            EdgeInsets.zero,
            2,
            ThemeMode.dark,
          ),
        ]) {
      final String nom = 'tb5_enseignant_telephone_${cas.$1}';
      testWidgets(nom, (WidgetTester tester) async {
        fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
        await tester.pumpWidget(
          hoteCapture(
            const DemoSallePage(
              role: RoleSeance.enseignant,
              situation: SituationTb.ped03,
            ),
            themeMode: cas.$6,
            echelleTexte: cas.$5,
          ),
        );
        await stabiliser(tester);
        await tester.pump(const Duration(milliseconds: 1400));
        expect(
          find.byKey(const ValueKey<String>('bouton-eleves')),
          findsNothing,
        );
        expect(find.byType(ZoneSupport), findsOneWidget);
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, nom)}');
      });
    }
  });

  // TB-12 (cadrages manquants de TB-5) : le focus au telephone, par le vrai
  // bouton des Commandes ; le bureau developpe Commandes fermees (« Reduire »
  // du panneau) : Participants a gauche, aucune colonne vide a droite.
  group(
    'TB-5 : focus au telephone et Commandes fermees',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);
      for (final _Cadrage cas in <_Cadrage>[
        ..._cadragesTb.where(
          (_Cadrage c) => <String>[
            '390_x1_clair',
            '390_x2_clair',
            '320_x1_clair',
            '320_x2_clair',
          ].contains(c.$1),
        ),
        (
          '390_x1_sombre',
          const Size(390, 844),
          3,
          _zoneTelephone,
          1,
          ThemeMode.dark,
        ),
      ]) {
        final String nom = 'tb5_enseignant_focus_telephone_${cas.$1}';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
          await tester.pumpWidget(
            hoteCapture(
              const DemoSallePage(
                role: RoleSeance.enseignant,
                situation: SituationTb.cmd01,
              ),
              themeMode: cas.$6,
              echelleTexte: cas.$5,
            ),
          );
          await stabiliser(tester);
          final Finder focus = find.byKey(CommandesPedagogiques.cleFocus);
          await tester.ensureVisible(focus);
          await tester.pump();
          await tester.tap(focus);
          await stabiliser(tester);
          await tester.pump(const Duration(milliseconds: 1400));
          // La capture prouve ce qu'elle nomme : Commandes refermees, le
          // support seul dans l'ecran.
          expect(find.byKey(CommandesPedagogiques.cle), findsNothing);
          expect(find.byType(ZoneSupport), findsOneWidget);
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
      for (final (String n, Size taille, ThemeMode mode)
          in <(String, Size, ThemeMode)>[
            ('1440_x1_clair', const Size(1440, 900), ThemeMode.light),
            ('1440_x1_sombre', const Size(1440, 900), ThemeMode.dark),
            ('1024_x1_clair', const Size(1024, 768), ThemeMode.light),
          ]) {
        final String nom = 'tb5_enseignant_developpe_ferme_$n';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, taille, taille.width < 1200 ? 2 : 1);
          await tester.pumpWidget(
            hoteCapture(
              const DemoSallePage(
                role: RoleSeance.enseignant,
                situation: SituationTb.cmd01,
              ),
              themeMode: mode,
            ),
          );
          await stabiliser(tester);
          await tester.tap(find.byKey(PanneauSeance.cleReduire));
          await stabiliser(tester);
          await tester.pump(const Duration(milliseconds: 1400));
          expect(find.byKey(CommandesPedagogiques.cle), findsNothing);
          expect(find.byKey(DeclencheurCommandes.cle), findsOneWidget);
          expect(find.byType(PanneauEleves), findsOneWidget);
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    },
  );

  // TB-6 (PED-01 a PED-04) : les trois affichages et le tableau libre, chez
  // l'enseignant et l'eleve ; clair et sombre (la page reste claire).
  group('TB-6 : surface a page fixe', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    Future<void> scene(
      WidgetTester tester,
      _Cadrage cas,
      RoleSeance role,
      SituationTb situation, {
      bool arabe = false,
    }) async {
      fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
      await tester.pumpWidget(
        hoteCapture(
          DemoSallePage(role: role, situation: situation),
          themeMode: cas.$6,
          echelleTexte: cas.$5,
        ),
      );
      await stabiliser(tester);
      await tester.pump(const Duration(milliseconds: 1400));
      // La capture prouve ce qu'elle nomme.
      final bool page =
          situation == SituationTb.ped02 || situation == SituationTb.ped03;
      expect(
        find.byKey(SurfacePageFixe.clePage),
        page ? findsOneWidget : findsNothing,
      );
      expect(
        find.byKey(SurfacePageFixe.cleFeuille),
        page ? findsNothing : findsOneWidget,
      );
      if (arabe) _verifierRtl(tester);
      expect(tester.takeException(), isNull);
    }

    const List<SituationTb> affichages = <SituationTb>[
      SituationTb.ped01,
      SituationTb.ped02,
      SituationTb.ped03,
      SituationTb.ped04,
    ];
    // TB-12 : 768, 320 x1 et 1440 x2 ajoutes ; la guidee (Mode
    // Accessibilite) a ses propres cadrages ; l'arabe ci-dessous.
    for (final (RoleSeance role, List<String> noms)
        in <(RoleSeance, List<String>)>[
          for (final RoleSeance r in <RoleSeance>[
            RoleSeance.enseignant,
            RoleSeance.eleve,
          ])
            (
              r,
              const <String>[
                '390_x1_clair',
                '390_x1_sombre',
                '390_x2_clair',
                '768_x1_clair',
                '768_x1_sombre',
                '768_x2_clair',
                '1440_x1_clair',
                '1440_x1_sombre',
                '1440_x2_clair',
                '320_x1_clair',
                '320_x2_clair',
              ],
            ),
          (
            RoleSeance.guidee,
            const <String>[
              '390_x1_clair',
              '390_x2_clair',
              '1440_x1_clair',
              '1440_x1_sombre',
              '320_x2_clair',
            ],
          ),
        ]) {
      for (final SituationTb situation in affichages) {
        for (final _Cadrage cas in _parNoms(noms)) {
          final String nom = 'tb6_${role.name}_${situation.name}_${cas.$1}';
          testWidgets(nom, (WidgetTester tester) async {
            await scene(tester, cas, role, situation);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    }
    _groupeArabe('arabe', () {
      for (final RoleSeance role in RoleSeance.values) {
        for (final SituationTb situation in <SituationTb>[
          SituationTb.ped01,
          SituationTb.ped03,
        ]) {
          for (final _Cadrage cas in _parNoms(const <String>[
            '390_x1_clair',
            '1440_x1_clair',
          ])) {
            final String nom =
                'tb6_${role.name}_${situation.name}_${cas.$1}_ar';
            testWidgets(nom, (WidgetTester tester) async {
              await scene(tester, cas, role, situation, arabe: true);
              debugPrint('PNG ${await capturer(tester, nom)}');
            });
          }
        }
      }
    });
  });

  // TB-7a : le calque au repere de la page. Le cercle de demonstration sur
  // la page (PED-03) et sur la feuille du Tableau (PED-04), puis la meme
  // page lue a 200 % par le vrai bouton des Commandes : le cercle reste au
  // meme endroit de la page.
  group('TB-7a : calque au repere de la page', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    // TB-12 : 768 x1 et x2 ajoutes, et l'arabe.
    const List<String> tailles = <String>[
      '390_x1_clair',
      '390_x1_sombre',
      '390_x2_clair',
      '768_x1_clair',
      '768_x2_clair',
      '1440_x1_clair',
      '1440_x1_sombre',
      '320_x2_clair',
    ];
    const List<(RoleSeance, SituationTb)> scenes = <(RoleSeance, SituationTb)>[
      (RoleSeance.enseignant, SituationTb.ped03),
      (RoleSeance.eleve, SituationTb.ped03),
      (RoleSeance.enseignant, SituationTb.ped04),
    ];
    Future<void> calque(
      WidgetTester tester,
      _Cadrage cas,
      RoleSeance role,
      SituationTb situation, {
      bool arabe = false,
    }) async {
      fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
      await tester.pumpWidget(
        hoteCapture(
          DemoSallePage(role: role, situation: situation),
          themeMode: cas.$6,
          echelleTexte: cas.$5,
        ),
      );
      await stabiliser(tester);
      await tester.pump(const Duration(milliseconds: 1400));
      // La capture prouve ce qu'elle nomme : la couche couvre la page.
      expect(
        tester.getRect(find.byKey(SurfacePageFixe.cleCouche)),
        tester.getRect(
          find.byKey(
            situation == SituationTb.ped04
                ? SurfacePageFixe.cleFeuille
                : SurfacePageFixe.clePage,
          ),
        ),
      );
      if (arabe) _verifierRtl(tester);
      expect(tester.takeException(), isNull);
    }

    for (final (RoleSeance role, SituationTb situation) in scenes) {
      for (final _Cadrage cas in _parNoms(tailles)) {
        final String nom = 'tb7a_${role.name}_${situation.name}_${cas.$1}';
        testWidgets(nom, (WidgetTester tester) async {
          await calque(tester, cas, role, situation);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }
    _groupeArabe('arabe', () {
      for (final (RoleSeance role, SituationTb situation) in scenes) {
        for (final _Cadrage cas in _parNoms(const <String>[
          '390_x1_clair',
          '1440_x1_clair',
        ])) {
          final String nom = 'tb7a_${role.name}_${situation.name}_${cas.$1}_ar';
          testWidgets(nom, (WidgetTester tester) async {
            await calque(tester, cas, role, situation, arabe: true);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    });

    for (final _Cadrage cas in <_Cadrage>[
      for (final _Cadrage c in _cadragesTb)
        if (<String>[
          '390_x1_clair',
          '1440_x1_clair',
          '1440_x1_sombre',
        ].contains(c.$1))
          c,
    ]) {
      final String nom = 'tb7a_enseignant_ped03_zoom200_${cas.$1}';
      testWidgets(nom, (WidgetTester tester) async {
        fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
        await tester.pumpWidget(
          hoteCapture(
            const DemoSallePage(
              role: RoleSeance.enseignant,
              situation: SituationTb.ped03,
            ),
            themeMode: cas.$6,
            echelleTexte: cas.$5,
          ),
        );
        await stabiliser(tester);
        await tester.tap(_entreeCommandes);
        await stabiliser(tester);
        final Finder plus = find.byWidgetPredicate(
          (Widget w) =>
              w is Pressable && w.libelleSemantique == t.salle.seance.zoomPlus,
        );
        await tester.ensureVisible(plus.first);
        await tester.pump();
        for (int i = 0; i < 10; i++) {
          await tester.tap(plus.first);
          await tester.pump();
        }
        expect(
          find.text(
            LibellesGroupe.valeurSeule(t.salle.seance.zoomValeur(valeur: 200)),
          ),
          findsWidgets,
        );
        // Les Commandes refermees : la page seule, lue a 200 %.
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await stabiliser(tester);
        await tester.pump(const Duration(milliseconds: 1400));
        expect(find.byKey(CommandesPedagogiques.cle), findsNothing);
        expect(
          tester.getRect(find.byKey(SurfacePageFixe.cleCouche)),
          tester.getRect(find.byKey(SurfacePageFixe.clePage)),
        );
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, nom)}');
      });
    }
  });

  // TB-7a, revue du tour 2 : l'encre tracee par la personne reste peinte
  // apres le lever du doigt, puis suit la page au zoom 200 %. L'outil est
  // arme et le depot est en memoire (TB-7b et TB-BR les brancheront).
  group('TB-7a : trait pose', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final _Cadrage cas in <_Cadrage>[
      for (final _Cadrage c in _cadragesTb)
        if (<String>[
          '390_x1_clair',
          '1440_x1_sombre',
          '320_x2_clair',
        ].contains(c.$1))
          c,
    ]) {
      for (final bool zoom in <bool>[false, true]) {
        final String nom = 'tb7a_trait_pose_${zoom ? 'zoom200_' : ''}${cas.$1}';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
          final AnnotationsMemoire depot = AnnotationsMemoire('demo');
          addTearDown(depot.liberer);
          await tester.pumpWidget(
            hoteCapture(
              const DemoSallePage(
                role: RoleSeance.enseignant,
                situation: SituationTb.ped03,
              ),
              themeMode: cas.$6,
              echelleTexte: cas.$5,
              surcharges: <Override>[
                portAnnotationsProvider.overrideWithValue(depot),
                etatOutilsProvider.overrideWith(_ControleurArme.new),
              ],
            ),
          );
          await stabiliser(tester);
          await tester.pump(const Duration(milliseconds: 1400));
          final Finder page = find.byKey(SurfacePageFixe.clePage);
          Offset sur(PointNormalise p) {
            final Rect r = tester.getRect(page);
            return r.topLeft + Offset(p.x * r.width, p.y * r.height);
          }

          // Un trait sous le titre, au doigt, de 25 % a 75 % de la largeur.
          final TestPointer doigt = TestPointer(21);
          final Offset a = sur(const PointNormalise(0.25, 0.30));
          final Offset b = sur(const PointNormalise(0.75, 0.34));
          await tester.sendEventToBinding(doigt.down(a));
          for (int i = 1; i <= 8; i++) {
            await tester.sendEventToBinding(
              doigt.move(Offset.lerp(a, b, i / 8)!),
            );
            await tester.pump();
          }
          await tester.sendEventToBinding(doigt.up());
          await stabiliser(tester);
          expect(depot.couches.single.traits, hasLength(1));
          if (zoom) {
            await tester.tap(_entreeCommandes);
            await stabiliser(tester);
            // TB-7b : outil arme, les Commandes s'ouvrent sur « Outils ».
            await tester.tap(
              find.descendant(
                of: find.byKey(CommandesPedagogiques.cleOnglets),
                matching: find.text(t.salle.seance.commandes.ongletSupport),
              ),
            );
            await stabiliser(tester);
            final Finder plus = find.byWidgetPredicate(
              (Widget w) =>
                  w is Pressable &&
                  w.libelleSemantique == t.salle.seance.zoomPlus,
            );
            await tester.ensureVisible(plus.first);
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.tap(plus.first);
              await tester.pump();
            }
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await stabiliser(tester);
            await tester.pump(const Duration(milliseconds: 1400));
          }
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }
  });

  // TB-8 (LIB-01 a LIB-04) : catalogue, apercu personnel, ouverture et
  // echec, dans le panneau droit (bureau) ou la feuille (telephone).
  group('TB-8 : Bibliotheque en seance', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    Future<void> versCarte(WidgetTester tester, String titre) async {
      final Finder catalogue = find.byType(SurfaceBibliotheque);
      await tester.scrollUntilVisible(
        find.descendant(of: catalogue, matching: find.text(titre)),
        120,
        scrollable: find
            .descendant(of: catalogue, matching: find.byType(Scrollable))
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: catalogue, matching: find.text(titre)).first,
      );
      await tester.pumpAndSettle();
    }

    Future<void> bibliotheque(
      WidgetTester tester,
      _Cadrage cas,
      String etat, {
      bool arabe = false,
    }) async {
      fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
      await tester.pumpWidget(
        hoteCapture(
          DemoSallePage(
            role: RoleSeance.enseignant,
            situation: etat == 'recherche_vide'
                ? SituationTb.lib04
                : SituationTb.lib01,
          ),
          themeMode: cas.$6,
          echelleTexte: cas.$5,
        ),
      );
      await tester.pumpAndSettle();
      final bool catalogue = etat == 'catalogue' || etat == 'recherche_vide';
      if (etat == 'recherche_vide') {
        // LIB-04 : une recherche sans resultat, tapee dans le vrai champ.
        // A 320 x2, l'en-tete du catalogue pousse le champ hors de l'ecran :
        // le catalogue defile jusqu'a lui, puis jusqu'au message.
        final Finder catalogue = find.byType(SurfaceBibliotheque);
        final Finder defile = find
            .descendant(of: catalogue, matching: find.byType(Scrollable))
            .first;
        final Finder champ = find.descendant(
          of: catalogue,
          matching: find.byType(TextField),
        );
        await tester.scrollUntilVisible(champ, 120, scrollable: defile);
        await tester.pumpAndSettle();
        await tester.enterText(champ, 'zqxw');
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text(t.tc.bibliotheque.aucunResultat.message),
          120,
          scrollable: defile,
        );
        await tester.pumpAndSettle();
        expect(
          find.text(t.tc.bibliotheque.aucunResultat.message),
          findsOneWidget,
        );
      }
      expect(
        find.byType(SurfaceBibliotheque),
        catalogue ? findsOneWidget : findsNothing,
      );
      if (arabe) _verifierRtl(tester);
      expect(tester.takeException(), isNull);
    }

    // TB-12 : recherche vide (LIB-04), 768 et 320 x2 sombre ; l'arabe
    // (catalogue et recherche vide : les titres des cartes sont des donnees).
    for (final _Cadrage cas in _parNoms(const <String>[
      '390_x1_clair',
      '768_x1_clair',
      '1440_x1_clair',
      '1440_x1_sombre',
      '320_x2_clair',
      '320_x2_sombre',
    ])) {
      final String nom = 'tb8_enseignant_recherche_vide_${cas.$1}';
      testWidgets(nom, (WidgetTester tester) async {
        await bibliotheque(tester, cas, 'recherche_vide');
        debugPrint('PNG ${await capturer(tester, nom)}');
      });
    }
    _groupeArabe('arabe', () {
      for (final String etat in <String>['catalogue', 'recherche_vide']) {
        for (final _Cadrage cas in _parNoms(const <String>[
          '390_x1_clair',
          '1440_x1_clair',
        ])) {
          final String nom = 'tb8_enseignant_${etat}_${cas.$1}_ar';
          testWidgets(nom, (WidgetTester tester) async {
            await bibliotheque(tester, cas, etat, arabe: true);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    });

    for (final String etat in <String>[
      'catalogue',
      'apercu',
      'ouverture',
      'echec',
    ]) {
      for (final _Cadrage cas in _parNoms(const <String>[
        '390_x1_clair',
        '390_x1_sombre',
        '390_x2_clair',
        '768_x1_clair',
        '768_x2_clair',
        '1440_x1_clair',
        '1440_x1_sombre',
        '320_x2_clair',
        '320_x2_sombre',
      ])) {
        final String nom = 'tb8_enseignant_${etat}_${cas.$1}';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
          await tester.pumpWidget(
            hoteCapture(
              const DemoSallePage(
                role: RoleSeance.enseignant,
                situation: SituationTb.lib01,
              ),
              themeMode: cas.$6,
              echelleTexte: cas.$5,
            ),
          );
          await tester.pumpAndSettle();
          if (etat != 'catalogue') {
            await versCarte(
              tester,
              etat == 'echec' ? "Cahier d'écriture" : 'Fiche de mémorisation',
            );
          }
          if (etat == 'ouverture' || etat == 'echec') {
            final Finder presenter = find.byKey(
              BibliothequeSeance.clePresenter,
            );
            await tester.ensureVisible(presenter);
            await tester.pumpAndSettle();
            await tester.tap(presenter);
            await tester.pump();
            if (etat == 'echec') await tester.pumpAndSettle();
          }
          // La capture prouve ce qu'elle nomme.
          expect(
            find.byType(SurfaceBibliotheque),
            etat == 'catalogue' ? findsOneWidget : findsNothing,
          );
          expect(
            find.byKey(BibliothequeSeance.cleEchec),
            etat == 'echec' ? findsOneWidget : findsNothing,
          );
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
          // L'ouverture capturee, le chargement se termine.
          await tester.pumpAndSettle();
        });
      }
    }
  });

  // TB-9 (plan V2 §3, §12, §19.2) : avant et apres le rangement, la carte
  // rangee et son point de reprise, la confirmation d'effacement (page et
  // tableau libre).
  group('TB-9 : ranger, reprendre, effacer', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    Future<void> taper(WidgetTester tester, Finder cible) async {
      await tester.ensureVisible(cible);
      await tester.pumpAndSettle();
      await tester.tap(cible);
      await tester.pumpAndSettle();
    }

    final Finder menu = find.byKey(CommandesPedagogiques.cleMenu);
    Future<void> scene(
      WidgetTester tester,
      _Cadrage cas,
      String etat, {
      bool arabe = false,
    }) async {
      fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
      await tester.pumpWidget(
        hoteCapture(
          DemoSallePage(
            role: RoleSeance.enseignant,
            situation: switch (etat) {
              'effacer_page' => SituationTb.dlg01,
              'effacer_tableau' => SituationTb.effacementTableau,
              _ => SituationTb.ped03,
            },
          ),
          themeMode: cas.$6,
          echelleTexte: cas.$5,
        ),
      );
      await tester.pumpAndSettle();
      await taper(tester, find.byKey(DeclencheurCommandes.cle));
      if (etat == 'avant') {
        await taper(tester, menu);
      } else if (etat == 'apres' || etat == 'reprise') {
        await taper(tester, menu);
        await taper(tester, find.text(t.salle.seance.rangement.ranger).last);
        expect(find.byKey(SurfacePageFixe.clePage), findsNothing);
        expect(find.byKey(CommandesPedagogiques.cleRange), findsOneWidget);
        if (etat == 'reprise') {
          await taper(
            tester,
            find.byKey(CommandesPedagogiques.cleBibliotheque),
          );
          // Le catalogue defile en slivers : jusqu'a la section des
          // ranges (en tete), puis sa carte et son point de reprise.
          final Finder catalogue = find.byType(SurfaceBibliotheque);
          final Finder defile = find
              .descendant(of: catalogue, matching: find.byType(Scrollable))
              .first;
          await tester.scrollUntilVisible(
            find.text(t.salle.seance.rangement.section),
            120,
            scrollable: defile,
          );
          await tester.pumpAndSettle();
          expect(find.text(t.salle.seance.rangement.section), findsOneWidget);
        }
      } else {
        await taper(tester, menu);
        await taper(tester, find.text(t.salle.seance.rangement.effacer).last);
        expect(
          find.text(
            etat == 'effacer_page'
                ? t.salle.seance.rangement.questionPage
                : t.salle.seance.rangement.questionTableau,
          ),
          findsWidgets,
        );
      }
      if (arabe) _verifierRtl(tester);
      expect(tester.takeException(), isNull);
    }

    // TB-12 : 390 x2 et 768 ajoutes ; l'arabe (avant, apres).
    for (final String etat in <String>[
      'avant',
      'apres',
      'reprise',
      'effacer_page',
      'effacer_tableau',
    ]) {
      for (final _Cadrage cas in _parNoms(const <String>[
        '390_x1_clair',
        '390_x1_sombre',
        '390_x2_clair',
        '768_x1_clair',
        '768_x1_sombre',
        '1440_x1_clair',
        '1440_x1_sombre',
        '320_x2_clair',
        '320_x2_sombre',
      ])) {
        final String nom = 'tb9_enseignant_${etat}_${cas.$1}';
        testWidgets(nom, (WidgetTester tester) async {
          await scene(tester, cas, etat);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }
    _groupeArabe('arabe', () {
      for (final String etat in <String>['avant', 'apres']) {
        for (final _Cadrage cas in _parNoms(const <String>[
          '390_x1_clair',
          '1440_x1_clair',
        ])) {
          final String nom = 'tb9_enseignant_${etat}_${cas.$1}_ar';
          testWidgets(nom, (WidgetTester tester) async {
            await scene(tester, cas, etat, arabe: true);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    });

    // TB-12 : l'eleve apres le rangement. La demonstration ne transmet pas
    // le geste de l'enseignant a la salle de l'eleve (aucun etat partage
    // avant BR-1) : la capture montre ce que la vue de l'eleve projette
    // d'une seance sans support presente, le tableau libre (PED-01), sans
    // menu du support ni mention « Support range ».
    for (final _Cadrage cas in _parNoms(const <String>[
      '390_x1_clair',
      '1440_x1_clair',
      '320_x2_clair',
    ])) {
      final String nom = 'tb9_eleve_apres_rangement_${cas.$1}';
      testWidgets(nom, (WidgetTester tester) async {
        fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
        await tester.pumpWidget(
          hoteCapture(
            const DemoSallePage(
              role: RoleSeance.eleve,
              situation: SituationTb.ped01,
            ),
            themeMode: cas.$6,
            echelleTexte: cas.$5,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(SurfacePageFixe.clePage), findsNothing);
        expect(find.byKey(SurfacePageFixe.cleFeuille), findsOneWidget);
        expect(menu, findsNothing);
        expect(find.byKey(CommandesPedagogiques.cleRange), findsNothing);
        expect(find.text(t.salle.seance.rangement.range), findsNothing);
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, nom)}');
      });
    }
  });

  group('TB-11a : observateurs en lecture seule', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    const List<String> tous = <String>[
      '390_x1_clair',
      '390_x1_sombre',
      '390_x2_clair',
      '1440_x1_clair',
      '1440_x1_sombre',
      '1440_x2_clair',
      '320_x2_clair',
      // TB-12 : la tablette en portrait.
      '768_x1_clair',
      '768_x1_sombre',
      '768_x2_clair',
    ];
    for (final ObservateurDemo o in ObservateurDemo.values) {
      for (final SituationTb situation in <SituationTb>[
        SituationTb.ped01,
        SituationTb.ped02,
        SituationTb.ped03,
        SituationTb.ped04,
      ]) {
        for (final (_Cadrage cas, bool defile) in <(_Cadrage, bool)>[
          for (final _Cadrage c in _cadragesTb)
            if (situation == SituationTb.ped03
                ? tous.contains(c.$1)
                : c.$1 == '390_x1_clair' || c.$1 == '1440_x1_clair')
              (c, false),
          // Tour 2 (CT-3 tablette) : la colonne de presence du controleur
          // reste laterale et lisible a 900 et 1100 avec une presentation.
          if (situation == SituationTb.ped03) ...<(_Cadrage, bool)>[
            (
              (
                '900_x1_clair',
                const Size(900, 1200),
                2,
                EdgeInsets.zero,
                1,
                ThemeMode.light,
              ),
              false,
            ),
            (
              (
                '1100_x1_clair',
                const Size(1100, 700),
                2,
                EdgeInsets.zero,
                1,
                ThemeMode.light,
              ),
              false,
            ),
            (
              (
                '1100_x1_sombre',
                const Size(1100, 700),
                2,
                EdgeInsets.zero,
                1,
                ThemeMode.dark,
              ),
              false,
            ),
            // 320 x2 apres defilement : la scene sous la presentation.
            for (final _Cadrage c in _cadragesTb)
              if (c.$1 == '320_x2_clair') (c, true),
            // Tour 3 (CT-3, texte x2) : tablette en paysage et iPad en
            // paysage ; puis la colonne de presence defilee jusqu'au bout.
            for (final (String n, Size taille) in <(String, Size)>[
              ('1100_x2_clair', const Size(1100, 700)),
              ('1024_x2_clair', const Size(1024, 768)),
            ])
              for (final bool d in <bool>[false, true])
                ((n, taille, 2, EdgeInsets.zero, 2, ThemeMode.light), d),
          ],
        ]) {
          final String nom =
              'tb11a_${o.name}_${situation.name}_${cas.$1}'
              '${defile ? '_defile' : ''}';
          testWidgets(nom, (WidgetTester tester) async {
            fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
            await tester.pumpWidget(
              hoteCapture(
                DemoSallePage(observateur: o, situation: situation),
                themeMode: cas.$6,
                echelleTexte: cas.$5,
              ),
            );
            await stabiliser(tester);
            await tester.pump(const Duration(milliseconds: 1400));
            if (defile) {
              // Sur tablette, la colonne de presence laterale defile ; au
              // telephone, la colonne de la presentation et de la scene.
              final Finder presence = find.byKey(
                const ValueKey<String>('presence-defile'),
              );
              if (presence.evaluate().isNotEmpty) {
                await tester.drag(
                  presence,
                  Offset(0, -cas.$2.height),
                  warnIfMissed: false,
                );
              } else {
                await tester.ensureVisible(
                  find.byKey(const ValueKey<String>('demo-enseignant')),
                );
              }
              await tester.pumpAndSettle();
            }
            // La capture prouve ce qu'elle nomme : la presentation lue.
            expect(
              find.byKey(const ValueKey<String>('presentation-lue')),
              findsOneWidget,
            );
            expect(find.byType(SurfacePageFixe), findsOneWidget);
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    }
    // TB-12 : les observateurs en arabe, presentation avec notes.
    _groupeArabe('arabe', () {
      for (final ObservateurDemo o in ObservateurDemo.values) {
        for (final _Cadrage cas in _parNoms(const <String>[
          '390_x1_clair',
          '1440_x1_clair',
        ])) {
          final String nom = 'tb11a_${o.name}_ped03_${cas.$1}_ar';
          testWidgets(nom, (WidgetTester tester) async {
            fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
            await tester.pumpWidget(
              hoteCapture(
                DemoSallePage(observateur: o, situation: SituationTb.ped03),
                themeMode: cas.$6,
                echelleTexte: cas.$5,
              ),
            );
            await stabiliser(tester);
            await tester.pump(const Duration(milliseconds: 1400));
            expect(
              find.byKey(const ValueKey<String>('presentation-lue')),
              findsOneWidget,
            );
            _verifierRtl(tester);
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    });
  });

  // TB-7b : Ecrire (plan V2 §4.2, §7, §19.1).
  group('TB-7b : ecrire', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    const _Cadrage sombre320 = (
      '320_x2_sombre',
      Size(320, 700),
      2,
      EdgeInsets.zero,
      2,
      ThemeMode.dark,
    );
    Iterable<_Cadrage> cadrages(List<String> noms) => <_Cadrage>[
      ..._cadragesTb,
      sombre320,
    ].where((_Cadrage c) => noms.contains(c.$1));
    final Finder page = find.byKey(SurfacePageFixe.clePage);
    Offset sur(WidgetTester tester, double x, double y) {
      final Rect r = tester.getRect(page);
      return r.topLeft + Offset(x * r.width, y * r.height);
    }

    Future<void> geste(
      WidgetTester tester,
      PointerDeviceKind appareil,
      int id,
    ) async {
      final TestPointer p = TestPointer(id, appareil);
      final Offset a = sur(tester, 0.2, 0.22);
      final Offset b = sur(tester, 0.8, 0.27);
      await tester.sendEventToBinding(p.down(a));
      for (int i = 1; i <= 8; i++) {
        await tester.sendEventToBinding(p.move(Offset.lerp(a, b, i / 8)!));
        await tester.pump();
      }
      await tester.sendEventToBinding(p.up());
      await stabiliser(tester);
    }

    Future<void> taper(WidgetTester tester, Finder cible) async {
      await tester.ensureVisible(cible);
      await tester.pump();
      await tester.tap(cible);
      await stabiliser(tester);
    }

    Future<void> monter(WidgetTester tester, _Cadrage cas) async {
      fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
      await tester.pumpWidget(
        hoteCapture(
          const DemoSallePage(
            role: RoleSeance.enseignant,
            situation: SituationTb.ped03,
          ),
          themeMode: cas.$6,
          echelleTexte: cas.$5,
        ),
      );
      await stabiliser(tester);
      await tester.pump(const Duration(milliseconds: 1400));
    }

    /// Commandes > Outils > Ecrire, par les vrais boutons.
    Future<void> ecrire(WidgetTester tester) async {
      await taper(tester, find.byKey(DeclencheurCommandes.cle));
      await taper(
        tester,
        find.descendant(
          of: find.byKey(CommandesPedagogiques.cleOnglets),
          matching: find.text(t.salle.seance.commandes.ongletOutils),
        ),
      );
      await taper(tester, find.byKey(const ValueKey<String>('outil-ecrire')));
    }

    int traits(WidgetTester tester) {
      final PortAnnotations depot = ProviderScope.containerOf(
        tester.element(find.byType(SalleSeance)),
      ).read(portAnnotationsProvider);
      return <TraitVectoriel>[
        for (final AnnotationLayer c in (depot as AnnotationsMemoire).couches)
          ...c.traits,
      ].length;
    }

    // Tour 2 : toutes les tailles, par les vrais boutons (avec les polices
    // du depot, la feuille des Commandes tient a 320 x2).
    for (final _Cadrage cas in cadrages(<String>[
      '390_x1_clair',
      '390_x1_sombre',
      '390_x2_clair',
      '768_x1_clair',
      '768_x1_sombre',
      '768_x2_clair',
      '1440_x1_clair',
      '1440_x1_sombre',
      '1440_x2_clair',
      '320_x1_clair',
      '320_x2_clair',
      '320_x2_sombre',
    ])) {
      final String nom = 'tb7b_palette_${cas.$1}';
      testWidgets(nom, (WidgetTester tester) async {
        await monter(tester, cas);
        await ecrire(tester);
        await taper(tester, find.byKey(PanneauSeance.cleReduire));
        await geste(tester, PointerDeviceKind.touch, 91);
        expect(traits(tester), 1);
        expect(find.byKey(PaletteEcriture.cle), findsOneWidget);
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, nom)}');
      });
    }

    for (final _Cadrage cas in cadrages(<String>[
      '1440_x1_clair',
      '1440_x1_sombre',
      '1440_x2_clair',
      '768_x2_clair',
      '390_x1_clair',
      '390_x2_clair',
      '320_x1_clair',
      '320_x2_clair',
      '320_x2_sombre',
    ])) {
      final String nom = 'tb7b_panneau_ecrire_${cas.$1}';
      testWidgets(nom, (WidgetTester tester) async {
        await monter(tester, cas);
        await ecrire(tester);
        expect(find.byKey(EcritureSeance.cle), findsOneWidget);
        await tester.ensureVisible(find.byKey(EcritureSeance.cleEpaisseur));
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, nom)}');
      });
    }

    // TB-12 : la palette courte AVANT le premier trait (Ecrire choisi, le
    // panneau reduit, aucun geste), a 320 et 390 x1.
    for (final _Cadrage cas in _parNoms(const <String>[
      '320_x1_clair',
      '390_x1_clair',
    ])) {
      final String nom = 'tb7b_palette_avant_trait_${cas.$1}';
      testWidgets(nom, (WidgetTester tester) async {
        await monter(tester, cas);
        await ecrire(tester);
        await taper(tester, find.byKey(PanneauSeance.cleReduire));
        expect(traits(tester), 0);
        expect(find.byKey(PaletteEcriture.cle), findsOneWidget);
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, nom)}');
      });
    }

    // TB-12 : le panneau Ecrire a texte x2, NON defile : la colonne des
    // Commandes ramenee en tete, la barre du panneau (titre, « Reduire »)
    // dans l'ecran.
    for (final _Cadrage cas in _parNoms(const <String>[
      '390_x2_clair',
      '768_x2_clair',
      '1440_x2_clair',
      '320_x2_clair',
    ])) {
      final String nom = 'tb7b_panneau_ecrire_tete_${cas.$1}';
      testWidgets(nom, (WidgetTester tester) async {
        await monter(tester, cas);
        await ecrire(tester);
        expect(find.byKey(EcritureSeance.cle), findsOneWidget);
        for (final ScrollableState s in tester.stateList<ScrollableState>(
          find.descendant(
            of: find.byKey(CommandesPedagogiques.cle),
            matching: find.byType(Scrollable),
          ),
        )) {
          s.position.jumpTo(s.position.minScrollExtent);
        }
        await stabiliser(tester);
        final Rect reduire = tester.getRect(
          find.byKey(PanneauSeance.cleReduire),
        );
        expect(reduire.top, greaterThanOrEqualTo(0));
        expect(reduire.bottom, lessThanOrEqualTo(cas.$2.height));
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, nom)}');
      });
    }

    for (final _Cadrage cas in cadrages(<String>[
      '390_x1_clair',
      '1440_x1_clair',
    ])) {
      for (final bool arme in <bool>[false, true]) {
        final String nom =
            'tb7b_stylet_${arme ? 'ecrire' : 'lecture'}_${cas.$1}';
        testWidgets(nom, (WidgetTester tester) async {
          await monter(tester, cas);
          if (arme) {
            await ecrire(tester);
            await taper(tester, find.byKey(PanneauSeance.cleReduire));
          }
          await geste(tester, PointerDeviceKind.stylus, 92);
          // La capture prouve ce qu'elle nomme : en lecture, le stylet n'a
          // rien laisse ; avec Ecrire, un trait.
          expect(traits(tester), arme ? 1 : 0);
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }

    // RTL force (arabe) : la palette courte et le panneau Ecrire.
    group('arabe', () {
      setUp(() => LocaleSettings.setLocale(AppLocale.ar));
      tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
      for (final _Cadrage cas in cadrages(<String>[
        '390_x1_clair',
        '320_x2_clair',
      ])) {
        for (final bool panneau in <bool>[false, true]) {
          final String nom =
              'tb7b_${panneau ? 'panneau_ecrire' : 'palette'}_ar_${cas.$1}';
          testWidgets(nom, (WidgetTester tester) async {
            await monter(tester, cas);
            expect(
              Directionality.of(tester.element(find.byType(SalleSeance))),
              TextDirection.rtl,
            );
            await ecrire(tester);
            if (panneau) {
              await tester.ensureVisible(
                find.byKey(EcritureSeance.cleEpaisseur),
              );
              await stabiliser(tester);
            } else {
              await taper(tester, find.byKey(PanneauSeance.cleReduire));
              await geste(tester, PointerDeviceKind.touch, 93);
              expect(find.byKey(PaletteEcriture.cle), findsOneWidget);
            }
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    });
  });

  // TB-10 (plan V2 §5, §12, §19.3 ; UX-20 ; MA-CMD-1) : l'eleve autorise
  // (information courte, Commandes avec Ecrire, palette apres un trait),
  // le droit retire, le Mode Accessibilite (guidee) et l'enseignant qui
  // vient d'autoriser Mariam (fiche depliee, « Peut ecrire »).
  group(
    'TB-10 : eleve, Mode Accessibilite et autorisation',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);
      const List<_Cadrage> plus = <_Cadrage>[
        (
          '320_x2_sombre',
          Size(320, 700),
          2,
          EdgeInsets.zero,
          2,
          ThemeMode.dark,
        ),
        ('390_x2_sombre', Size(390, 844), 3, _zoneTelephone, 2, ThemeMode.dark),
      ];
      Iterable<_Cadrage> cadrages(List<String> noms) => <_Cadrage>[
        ..._cadragesTb,
        ...plus,
      ].where((_Cadrage c) => noms.contains(c.$1));
      final Finder page = find.byKey(SurfacePageFixe.clePage);

      Future<void> taper(WidgetTester tester, Finder cible) async {
        await tester.ensureVisible(cible);
        await tester.pump();
        await tester.tap(cible);
        await stabiliser(tester);
      }

      Future<void> monter(
        WidgetTester tester,
        _Cadrage cas,
        RoleSeance role,
        SituationTb situation,
      ) async {
        fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
        await tester.pumpWidget(
          hoteCapture(
            DemoSallePage(role: role, situation: situation),
            themeMode: cas.$6,
            echelleTexte: cas.$5,
          ),
        );
        await stabiliser(tester);
        await tester.pump(const Duration(milliseconds: 1400));
      }

      Future<void> trait(WidgetTester tester) async {
        final Rect r = tester.getRect(page);
        final TestPointer p = TestPointer(94);
        final Offset a = r.topLeft + Offset(0.2 * r.width, 0.3 * r.height);
        final Offset b = r.topLeft + Offset(0.8 * r.width, 0.36 * r.height);
        await tester.sendEventToBinding(p.down(a));
        for (int i = 1; i <= 8; i++) {
          await tester.sendEventToBinding(p.move(Offset.lerp(a, b, i / 8)!));
          await tester.pump();
        }
        await tester.sendEventToBinding(p.up());
        await stabiliser(tester);
      }

      for (final RoleSeance role in <RoleSeance>[
        RoleSeance.eleve,
        RoleSeance.guidee,
      ]) {
        final String qui = role == RoleSeance.eleve ? 'eleve' : 'ma';
        for (final _Cadrage cas in cadrages(<String>[
          '390_x1_clair',
          '390_x1_sombre',
          '390_x2_clair',
          '1440_x1_clair',
          '1440_x1_sombre',
          '320_x2_clair',
          '320_x2_sombre',
        ])) {
          for (final String etape in <String>['avis', 'commandes', 'palette']) {
            final String nom = 'tb10_${qui}_${etape}_${cas.$1}';
            testWidgets(nom, (WidgetTester tester) async {
              await monter(tester, cas, role, SituationTb.autorisationEcrire);
              expect(find.byKey(CommandesEleve.cleAvis), findsOneWidget);
              if (etape != 'avis') {
                await taper(tester, find.byKey(DeclencheurCommandes.cle));
                await taper(
                  tester,
                  find.byKey(const ValueKey<String>('outil-ecrire')),
                );
                expect(
                  find.byKey(BarreStylet.cleOutil(OutilTrait.surligneur)),
                  findsNothing,
                );
              }
              if (etape == 'palette') {
                await taper(tester, find.byKey(PanneauSeance.cleReduire));
                await trait(tester);
                expect(find.byKey(PaletteEcriture.cle), findsOneWidget);
              }
              expect(tester.takeException(), isNull);
              debugPrint('PNG ${await capturer(tester, nom)}');
            });
          }
        }
        for (final _Cadrage cas in cadrages(<String>[
          '390_x1_clair',
          '1440_x1_clair',
          '320_x2_clair',
        ])) {
          final String nom = 'tb10_${qui}_retrait_${cas.$1}';
          testWidgets(nom, (WidgetTester tester) async {
            await monter(tester, cas, role, SituationTb.droitRetire);
            expect(find.byKey(CommandesEleve.cleAvis), findsOneWidget);
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }

      for (final _Cadrage cas in cadrages(<String>[
        '1440_x1_clair',
        '1440_x1_sombre',
        '1440_x2_clair',
        '390_x1_clair',
        '390_x1_sombre',
        '390_x2_clair',
        '320_x2_clair',
        '320_x2_sombre',
      ])) {
        final String nom = 'tb10_enseignant_autorise_${cas.$1}';
        testWidgets(nom, (WidgetTester tester) async {
          await monter(tester, cas, RoleSeance.enseignant, SituationTb.per01);
          final Finder bouton = find.byKey(
            const ValueKey<String>('autoriser-ecrire-Mariam'),
          );
          await taper(tester, bouton);
          expect(
            find.byKey(const ValueKey<String>('peut-ecrire-Mariam')),
            findsOneWidget,
          );
          await tester.ensureVisible(
            find.byKey(const ValueKey<String>('eleve-Mariam')),
          );
          // Tour 2 : « Retirer l'autorisation d'ecrire » au milieu de la
          // liste, hors de la barre de l'appel posee en bas : la capture
          // montre l'action du meme etat.
          await Scrollable.ensureVisible(
            tester.element(bouton),
            alignment: 0.5,
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }

      // TB-12 : l'enseignant voit, dans le meme cadre, le prenom de Mariam
      // et sa mention « Peut ecrire » (la ligne ramenee en tete de la
      // liste, sans la cacher sous l'en-tete).
      for (final _Cadrage cas in cadrages(<String>[
        '1440_x1_clair',
        '1440_x1_sombre',
        '390_x1_clair',
        '390_x2_clair',
        '320_x2_clair',
      ])) {
        final String nom = 'tb10_enseignant_mariam_peut_ecrire_${cas.$1}';
        testWidgets(nom, (WidgetTester tester) async {
          await monter(tester, cas, RoleSeance.enseignant, SituationTb.per01);
          await taper(
            tester,
            find.byKey(const ValueKey<String>('autoriser-ecrire-Mariam')),
          );
          final Finder ligne = find.byKey(
            const ValueKey<String>('eleve-Mariam'),
          );
          final Finder mention = find.byKey(
            const ValueKey<String>('peut-ecrire-Mariam'),
          );
          // La ligne de Mariam en tete de la liste : son prenom, puis la
          // mention, dans la partie visible de la liste (sous l'en-tete fixe
          // du panneau, pas seulement dans l'ecran).
          await Scrollable.ensureVisible(tester.element(ligne));
          await stabiliser(tester);
          final Rect liste = tester.getRect(
            find.ancestor(of: ligne, matching: find.byType(Scrollable)).first,
          );
          bool dans(Rect r) =>
              r.left >= liste.left - 0.5 &&
              r.top >= liste.top - 0.5 &&
              r.right <= liste.right + 0.5 &&
              r.bottom <= liste.bottom + 0.5;
          final Rect prenom = tester.getRect(
            find.descendant(of: ligne, matching: find.text('Mariam')).first,
          );
          final Rect peut = tester.getRect(mention);
          expect(dans(prenom), isTrue, reason: 'prenom $prenom');
          expect(dans(peut), isTrue, reason: 'Peut ecrire $peut');
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    },
  );

  // TB-11b (plan V2 §10 a §12, §19.5) : les quatre etats, synchronisation
  // interrompue (ERR-01, enseignant et eleve), reprise (ERR-02, enseignant
  // et eleve), sauvegarde en echec (ERR-03) et conservation dans la seance
  // (Commandes ouvertes) ; 390 et 1440 clair et sombre, 320 x2 clair et
  // sombre.
  group('TB-11b : synchronisation et conservation', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    Future<void> scene(
      WidgetTester tester,
      _Cadrage cas,
      RoleSeance role,
      SituationTb situation,
      String etat, {
      bool arabe = false,
    }) async {
      fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
      await tester.pumpWidget(
        hoteCapture(
          DemoSallePage(role: role, situation: situation),
          themeMode: cas.$6,
          echelleTexte: cas.$5,
        ),
      );
      await tester.pumpAndSettle();
      // ERR-03 au bureau : le bandeau et la conservation ensemble ; au
      // telephone, le bandeau seul (la feuille le couvrirait).
      final bool commandes =
          etat == 'conservation' ||
          etat == 'ecriture_suspendue' ||
          (etat == 'err03' && cas.$2.width >= 1440);
      if (commandes) {
        final Finder declencheur = find.byKey(DeclencheurCommandes.cle);
        await tester.ensureVisible(declencheur);
        await tester.pumpAndSettle();
        await tester.tap(declencheur);
        await tester.pumpAndSettle();
      }
      if (etat == 'err03') {
        expect(
          find.textContaining(
            t.salle.seance.synchro.nonSauvegardees,
            findRichText: true,
          ),
          findsOneWidget,
        );
      }
      if (etat == 'ecriture_suspendue') {
        expect(
          find.byKey(CommandesPedagogiques.cleEcritureSuspendue),
          findsOneWidget,
        );
      }
      if (commandes && etat != 'ecriture_suspendue') {
        final Finder conservation = find.byKey(
          CommandesPedagogiques.cleConservation,
        );
        expect(conservation, findsOneWidget);
        // A 320 (x1 et x2), la feuille des Commandes defile : la phrase
        // est amenee au milieu de la partie visible ; ailleurs, la colonne
        // reste en tete. TB-12 (capture ouverte) : a 320 x2, la partie
        // visible de la feuille ne tient que deux lignes et demie, la
        // phrase n'y est PAS entiere (« uniquement » coupe par le bord
        // bas) ; a 320 x1 elle l'est.
        if (cas.$2.width < 390) {
          await tester.runAsync(
            () => Scrollable.ensureVisible(
              tester.element(conservation),
              alignment: 0.5,
            ),
          );
          await tester.pumpAndSettle();
        }
      }
      if (arabe) _verifierRtl(tester);
      expect(tester.takeException(), isNull);
    }

    const List<(RoleSeance, SituationTb, String)> etats =
        <(RoleSeance, SituationTb, String)>[
          (RoleSeance.enseignant, SituationTb.err01, 'err01'),
          (RoleSeance.eleve, SituationTb.err01, 'err01'),
          (RoleSeance.enseignant, SituationTb.err02, 'err02'),
          (RoleSeance.eleve, SituationTb.err02, 'err02'),
          (RoleSeance.enseignant, SituationTb.err03, 'err03'),
          (RoleSeance.enseignant, SituationTb.ped03, 'conservation'),
          // Tour 2 : la guidee en reprise (bandeau court) ; l'eleve autorise,
          // Commandes ouvertes : la phrase de la suspension a la place
          // d'« Ecrire ».
          (RoleSeance.guidee, SituationTb.err02, 'err02'),
          (RoleSeance.eleve, SituationTb.err01, 'ecriture_suspendue'),
        ];
    // TB-12 : 768, x2 a 390 et 1440, 320 x1 ajoutes ; l'arabe.
    for (final (RoleSeance role, SituationTb situation, String etat) in etats) {
      for (final _Cadrage cas in _parNoms(const <String>[
        '390_x1_clair',
        '390_x1_sombre',
        '390_x2_clair',
        '768_x1_clair',
        '1440_x1_clair',
        '1440_x1_sombre',
        '1440_x2_clair',
        '320_x1_clair',
        '320_x2_clair',
        '320_x2_sombre',
      ])) {
        final String nom = 'tb11b_${role.name}_${etat}_${cas.$1}';
        testWidgets(nom, (WidgetTester tester) async {
          await scene(tester, cas, role, situation, etat);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }
    _groupeArabe('arabe', () {
      for (final (RoleSeance role, SituationTb situation, String etat)
          in <(RoleSeance, SituationTb, String)>[
            (RoleSeance.enseignant, SituationTb.err01, 'err01'),
            (RoleSeance.eleve, SituationTb.err02, 'err02'),
            (RoleSeance.enseignant, SituationTb.err03, 'err03'),
            (RoleSeance.enseignant, SituationTb.ped03, 'conservation'),
          ]) {
        for (final _Cadrage cas in _parNoms(const <String>[
          '390_x1_clair',
          '1440_x1_clair',
        ])) {
          final String nom = 'tb11b_${role.name}_${etat}_${cas.$1}_ar';
          testWidgets(nom, (WidgetTester tester) async {
            await scene(tester, cas, role, situation, etat, arabe: true);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    });
  });

  // TB-12 : la matrice de recette du chantier. Cinq profils (enseignant,
  // eleve, Mode Accessibilite, tuteur, controleur), trois etats chacun :
  // sans support (tableau libre, PED-01), support avec notes (PED-03), et
  // Commandes ouvertes par le vrai declencheur (enseignant, eleve, Mode
  // Accessibilite) ou, pour les observateurs qui n'ont pas de Commandes,
  // l'etat equivalent lu : l'affichage « Tableau » choisi par l'enseignant
  // (PED-04), sans aucune commande. Quatorze cadrages : 390, 768 et 1440
  // en clair et sombre a x1, en clair a x2 (et 390 x2 sombre) ; 320 x1 et
  // x2 ; l'arabe (RTL) a 390 et 1440. Plus le rangement en cours, mouvement
  // reduit et mouvement ordinaire (enseignant, 390).
  group('TB-12 : matrice de recette', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    const List<String> cadrages = <String>[
      '390_x1_clair',
      '390_x1_sombre',
      '390_x2_clair',
      '390_x2_sombre',
      '768_x1_clair',
      '768_x1_sombre',
      '768_x2_clair',
      '1440_x1_clair',
      '1440_x1_sombre',
      '1440_x2_clair',
      '320_x1_clair',
      '320_x2_clair',
    ];
    const List<String> cadragesArabe = <String>[
      '390_x1_clair',
      '1440_x1_clair',
    ];

    // Les profils : un role de la salle, ou un observateur.
    const List<(String, RoleSeance?, ObservateurDemo?)> profils =
        <(String, RoleSeance?, ObservateurDemo?)>[
          ('enseignant', RoleSeance.enseignant, null),
          ('eleve', RoleSeance.eleve, null),
          ('guidee', RoleSeance.guidee, null),
          ('tuteur', null, ObservateurDemo.tuteur),
          ('controleur', null, ObservateurDemo.controleur),
        ];
    List<String> etatsDe(ObservateurDemo? o) => <String>[
      'libre',
      'notes',
      if (o == null) 'commandes' else 'lecture',
    ];

    Future<void> scene(
      WidgetTester tester,
      _Cadrage cas,
      RoleSeance? role,
      ObservateurDemo? observateur,
      String etat, {
      bool arabe = false,
    }) async {
      final SituationTb situation = switch (etat) {
        'libre' => SituationTb.ped01,
        'lecture' => SituationTb.ped04,
        _ => SituationTb.ped03,
      };
      fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
      await tester.pumpWidget(
        hoteCapture(
          DemoSallePage(
            role: role,
            observateur: observateur,
            situation: situation,
          ),
          themeMode: cas.$6,
          echelleTexte: cas.$5,
        ),
      );
      await stabiliser(tester);
      await tester.pump(const Duration(milliseconds: 1400));
      if (etat == 'commandes') {
        final Finder declencheur = find.byKey(DeclencheurCommandes.cle);
        await tester.ensureVisible(declencheur);
        await tester.pump();
        await tester.tap(declencheur);
        await stabiliser(tester);
        await tester.pump(const Duration(milliseconds: 400));
      }
      // La capture prouve ce qu'elle nomme.
      final bool page = situation == SituationTb.ped03;
      expect(
        find.byKey(SurfacePageFixe.clePage),
        page ? findsOneWidget : findsNothing,
      );
      expect(
        find.byKey(SurfacePageFixe.cleFeuille),
        page ? findsNothing : findsOneWidget,
      );
      if (page) {
        // PED-03 : les notes sont peintes sur la page.
        expect(
          tester
              .widget<Visibility>(find.byKey(SurfacePageFixe.cleCalque))
              .visible,
          isTrue,
        );
      }
      if (observateur != null) {
        expect(
          find.byKey(const ValueKey<String>('presentation-lue')),
          findsOneWidget,
        );
        expect(find.byType(DeclencheurCommandes), findsNothing);
        expect(find.byType(CommandesPedagogiques), findsNothing);
      } else if (etat == 'commandes') {
        expect(find.byKey(CommandesPedagogiques.cle), findsOneWidget);
        expect(find.byKey(DeclencheurCommandes.cle), findsNothing);
        if (role != RoleSeance.enseignant) {
          // L'eleve et le Mode Accessibilite : lecture et focus, rien de
          // l'enseignant (ni menu du support, ni Bibliotheque).
          expect(find.byKey(CommandesPedagogiques.cleLecture), findsOneWidget);
          expect(find.byKey(CommandesPedagogiques.cleMenu), findsNothing);
          expect(
            find.byKey(CommandesPedagogiques.cleBibliotheque),
            findsNothing,
          );
        }
      } else {
        expect(find.byKey(CommandesPedagogiques.cle), findsNothing);
      }
      if (arabe) _verifierRtl(tester);
      expect(tester.takeException(), isNull);
    }

    for (final (String nomProfil, RoleSeance? role, ObservateurDemo? o)
        in profils) {
      for (final String etat in etatsDe(o)) {
        for (final _Cadrage cas in _parNoms(cadrages)) {
          final String nom = 'tb12_${nomProfil}_${etat}_${cas.$1}';
          testWidgets(nom, (WidgetTester tester) async {
            await scene(tester, cas, role, o, etat);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    }
    _groupeArabe('arabe', () {
      for (final (String nomProfil, RoleSeance? role, ObservateurDemo? o)
          in profils) {
        for (final String etat in etatsDe(o)) {
          for (final _Cadrage cas in _parNoms(cadragesArabe)) {
            final String nom = 'tb12_${nomProfil}_${etat}_${cas.$1}_ar';
            testWidgets(nom, (WidgetTester tester) async {
              await scene(tester, cas, role, o, etat, arabe: true);
              debugPrint('PNG ${await capturer(tester, nom)}');
            });
          }
        }
      }
    });

    // Le rangement en cours (UX-22) : un cadre apres « Ranger dans la
    // bibliotheque ». Mouvement reduit : aucune copie en vol, l'etat final
    // aussitot ; mouvement ordinaire : la copie de la page en vol vers la
    // Bibliotheque, l'etat deja change dessous.
    for (final bool reduit in <bool>[true, false]) {
      final String nom =
          'tb12_enseignant_rangement_en_cours_'
          '${reduit ? 'mouvement_reduit' : 'mouvement_ordinaire'}_390_x1_clair';
      testWidgets(nom, (WidgetTester tester) async {
        if (reduit) {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
          );
        }
        final _Cadrage cas = _parNoms(const <String>['390_x1_clair']).single;
        fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
        await tester.pumpWidget(
          hoteCapture(
            const DemoSallePage(
              role: RoleSeance.enseignant,
              situation: SituationTb.ped03,
            ),
            themeMode: cas.$6,
            echelleTexte: cas.$5,
          ),
        );
        await tester.pumpAndSettle();
        Future<void> taper(Finder cible) async {
          await tester.ensureVisible(cible);
          await tester.pumpAndSettle();
          await tester.tap(cible);
          await tester.pumpAndSettle();
        }

        await taper(find.byKey(DeclencheurCommandes.cle));
        await taper(find.byKey(CommandesPedagogiques.cleMenu));
        await tester.tap(find.text(t.salle.seance.rangement.ranger).last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        // L'etat a change des le premier cadre, dans les deux cas.
        expect(find.byKey(SurfacePageFixe.clePage), findsNothing);
        expect(find.byKey(SurfacePageFixe.cleFeuille), findsOneWidget);
        expect(
          find.byKey(EnvolVersCible.cle),
          reduit ? findsNothing : findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, nom)}');
        await tester.pumpAndSettle();
      });
    }
  });

  group('TB : captures de la salle', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    _situationsCapturees.forEach((RoleSeance role, List<SituationTb> l) {
      for (final SituationTb situation in l) {
        for (final _Cadrage cas in _cadragesTb) {
          final String nom = 'tb_${role.name}_${situation.name}_${cas.$1}';
          testWidgets(nom, (WidgetTester tester) async {
            fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
            await tester.pumpWidget(
              hoteCapture(
                DemoSallePage(role: role, situation: situation),
                themeMode: cas.$6,
                echelleTexte: cas.$5,
              ),
            );
            await stabiliser(tester);
            // Un cycle du point clignotant : capture a pleine opacite.
            await tester.pump(const Duration(milliseconds: 1400));
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    });
  });

  // AR-SALLE-1 : la salle en arabe, de droite a gauche.
  group('AR-SALLE-1 : la salle en arabe', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(() => LocaleSettings.setLocale(AppLocale.ar));
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final (RoleSeance role, SituationTb situation)
        in <(RoleSeance, SituationTb)>[
          (RoleSeance.enseignant, SituationTb.sal00),
          (RoleSeance.enseignant, SituationTb.cmd01),
          (RoleSeance.enseignant, SituationTb.lib01),
          (RoleSeance.enseignant, SituationTb.ped01),
          (RoleSeance.eleve, SituationTb.ped03),
        ]) {
      for (final _Cadrage cas in <_Cadrage>[
        for (final _Cadrage c in _cadragesTb)
          if (<String>[
            '390_x1_clair',
            '390_x1_sombre',
            '1440_x1_clair',
            '1440_x1_sombre',
            '320_x2_clair',
          ].contains(c.$1))
            c,
      ]) {
        final String nom = 'ar_salle_${role.name}_${situation.name}_${cas.$1}';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
          await tester.pumpWidget(
            hoteCapture(
              DemoSallePage(role: role, situation: situation),
              themeMode: cas.$6,
              echelleTexte: cas.$5,
            ),
          );
          await tester.pumpAndSettle();
          // La capture prouve ce qu'elle nomme.
          expect(
            Directionality.of(tester.element(find.byType(DemoSallePage))),
            TextDirection.rtl,
          );
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }
  });
}
