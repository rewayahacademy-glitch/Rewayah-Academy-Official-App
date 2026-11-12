// SUIVI-ATTENTE (S6) : la carte compacte des accueils.
//
// Ce que le test prouve :
// - sans port (production avant branchement) : l'ancienne carte, inchangee ;
// - sans demande ou pendant la premiere lecture : rien, silence ;
// - une carte par demande visible, la ligne de l'etape, un lien qui ouvre
//   l'ecran complet (un seul ecran de suivi) ;
// - une demande qui a quitte l'accueil (visible_accueil faux) ne s'y montre pas ;
// - une lecture en echec le dit ;
// - 320 px, texte x2, un seul bouton plein (aucun).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/attente_classe/modele_attente.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/attente_classe/carte_suivi_attente.dart';
import 'package:rewayah_academy/features/attente_classe/libelles_attente.dart';
import 'package:rewayah_academy/features/attente_classe/suivi_attente_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/attente_donnees.dart';
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';

Future<void> _accueil(
  WidgetTester tester, {
  required List<Override> surcharges,
  double largeur = 390,
  double echelle = 1,
  CheminsAttente chemins = CheminsAttente.tuteur,
  Widget? repli,
}) => monterRecrutement(
  tester,
  chemin: '/tuteur',
  ecran: (_) => Scaffold(
    body: SingleChildScrollView(
      child: CarteSuiviAttente(chemins: chemins, repli: repli),
    ),
  ),
  autres: <String>['/tuteur/attente/:demandeId'],
  surcharges: surcharges,
  largeur: largeur,
  echelle: echelle,
);

List<Override> _avec(PortSuiviAttente port) => <Override>[
  portSuiviAttenteProvider.overrideWithValue(port),
];

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
  });

  testWidgets('sans port : l\'ancienne carte, rien d\'autre', (
    WidgetTester tester,
  ) async {
    await _accueil(
      tester,
      surcharges: const <Override>[],
      repli: const Text('ancienne-carte', key: ValueKey<String>('repli')),
    );
    expect(find.byKey(const ValueKey<String>('repli')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('carte-attente')), findsNothing);
  });

  testWidgets('sans demande : silence', (WidgetTester tester) async {
    await _accueil(tester, surcharges: _avec(PortSuiviAttenteFaux()));
    expect(find.byKey(const ValueKey<String>('carte-attente')), findsNothing);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('pendant la premiere lecture : silence', (
    WidgetTester tester,
  ) async {
    await _accueil(tester, surcharges: _avec(const PortSuiviAttenteSansFin()));
    expect(find.byKey(const ValueKey<String>('carte-attente')), findsNothing);
  });

  testWidgets('une carte par demande, sa ligne, et le lien vers l\'ecran', (
    WidgetTester tester,
  ) async {
    final SuiviAttente yusuf = suiviDeTest(delai: delaiDeTest());
    final SuiviAttente ines = suiviDeTest(
      id: 'd2',
      prenom: 'Ines',
      etapes: etapesJusqua(2),
      classe: 'Classe Al-Fatiha',
    );
    await _accueil(
      tester,
      surcharges: _avec(PortSuiviAttenteFaux(<SuiviAttente>[yusuf, ines])),
    );
    expect(find.text(ligneCarte(yusuf)), findsOneWidget);
    expect(find.text(ligneCarte(ines)), findsOneWidget);
    expect(find.text(t.suiviAttente.carte.titre), findsNWidgets(2));
    await tester.tap(
      find.byKey(const ValueKey<String>('carte-attente-voir-d2')),
    );
    await laisser(tester);
    expect(find.text('temoin:/tuteur/attente/:demandeId'), findsOneWidget);
  });

  testWidgets('les demandes en cours d\'abord, les closes ensuite', (
    WidgetTester tester,
  ) async {
    await _accueil(
      tester,
      surcharges: _avec(
        PortSuiviAttenteFaux(<SuiviAttente>[
          suiviDeTest(
            id: 'close',
            prenom: 'Hana',
            cas: CasAttente.retiree,
            motif: MotifCloture.retraitFamille,
          ),
          suiviDeTest(id: 'vivante', delai: delaiDeTest()),
        ]),
      ),
    );
    final double vivante = tester
        .getTopLeft(find.byKey(const ValueKey<String>('carte-attente-vivante')))
        .dy;
    final double close = tester
        .getTopLeft(find.byKey(const ValueKey<String>('carte-attente-close')))
        .dy;
    expect(vivante, lessThan(close));
  });

  testWidgets('une demande qui a quitte l\'accueil n\'y est plus', (
    WidgetTester tester,
  ) async {
    await _accueil(
      tester,
      surcharges: _avec(
        PortSuiviAttenteFaux(<SuiviAttente>[
          suiviToutEstPret().copyAvecVisible(false),
        ]),
      ),
    );
    expect(find.byKey(const ValueKey<String>('carte-attente')), findsNothing);
  });

  testWidgets('tout est pret : le premier cours se dit sur la carte', (
    WidgetTester tester,
  ) async {
    await _accueil(
      tester,
      surcharges: _avec(
        PortSuiviAttenteFaux(<SuiviAttente>[suiviToutEstPret()]),
      ),
    );
    expect(find.textContaining('18:00'), findsOneWidget);
    expect(find.textContaining('Yusuf'), findsOneWidget);
  });

  testWidgets('l\'enfant de moins de 10 ans : titre au tutoiement', (
    WidgetTester tester,
  ) async {
    await _accueil(
      tester,
      surcharges: _avec(
        PortSuiviAttenteFaux(<SuiviAttente>[suiviDeTest(versionSimple: true)]),
      ),
      chemins: CheminsAttente.enfant,
    );
    expect(find.text(t.suiviAttente.carte.titreSimple), findsOneWidget);
  });

  testWidgets('lecture en echec : la carte le dit', (
    WidgetTester tester,
  ) async {
    await _accueil(tester, surcharges: _avec(const PortSuiviAttenteEnEchec()));
    expect(
      find.byKey(const ValueKey<String>('carte-attente-erreur')),
      findsOneWidget,
    );
    expect(find.text(t.suiviAttente.erreur), findsOneWidget);
  });

  for (final (String nom, double largeur, double echelle)
      in <(String, double, double)>[
        ('320 px, texte x2', 320, 2),
        ('1440 px', 1440, 1),
      ]) {
    testWidgets(
      '$nom : aucun debordement, aucun mot coupe, aucun bouton plein',
      (WidgetTester tester) async {
        await _accueil(
          tester,
          surcharges: _avec(
            PortSuiviAttenteFaux(<SuiviAttente>[
              suiviDeTest(delai: delaiDeTest()),
              suiviToutEstPret(id: 'd9'),
            ]),
          ),
          largeur: largeur,
          echelle: echelle,
        );
        expect(tester.takeException(), isNull);
        verifierUnSeulBoutonPlein(tester, maximum: 0);
        verifierEcranSansMotCoupe(tester);
      },
    );
  }
}

extension on SuiviAttente {
  SuiviAttente copyAvecVisible(bool visible) => SuiviAttente(
    demandeId: demandeId,
    eleveId: eleveId,
    prenom: prenom,
    fuseauIana: fuseauIana,
    cas: cas,
    etapes: etapes,
    typePublic: typePublic,
    versionSimple: versionSimple,
    motif: motif,
    creneau: creneau,
    delai: delai,
    classe: classe,
    premierCours: premierCours,
    premierCoursPasse: premierCoursPasse,
    creneauChangeLe: creneauChangeLe,
    enseignant: enseignant,
    peutChoisirAutreCreneau: peutChoisirAutreCreneau,
    visibleAccueil: visible,
  );
}
