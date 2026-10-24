// ADM-20 : la lisibilite de la file entiere. A chaque etat de la fiche (liste,
// selection, vide, aucun resultat, erreur, hors ligne, capacite indisponible,
// acces refuse, genre inconnu, exception du super-admin, alertes a zero) et a
// chaque configuration (320 x 568 texte x2, 390 x 844, 1440 x 900 texte x1 et
// x2, francais et arabe de droite a gauche) : aucun debordement, aucun mot
// coupe ni tronque, une ponctuation jamais seule, un seul bouton plein.
//
// Avec les VRAIES polices du depot (`chargerPolicesDuDepot`) : le texte de test
// par defaut (Ahem) est plus large que toute police du produit et ne mesure
// rien de ce que l'on voit.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/case_a_cocher.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/garde_coupe_mots_rendu.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';
import 'hote_candidatures.dart';

/// Six candidatures, de longueur de nom variee, avec marques et dates.
List<LigneCandidature> _lignes() => <LigneCandidature>[
  ligneTest(
    id: 'a1',
    nom: 'Amina Diallo',
    courrielAObtenir: true,
    indicatifAConfirmer: true,
  ),
  ligneTest(
    id: 'b2',
    nom: 'Abdelrahmane Ould Mohamed-Lemine',
    etape: EtapeCandidature.verifications,
    etat: EtatCandidature.entretienAPlanifier,
    paysResidence: 'FR',
    paiement: EtatVersement.aVerifier,
  ),
  ligneTest(
    id: 'c3',
    nom: 'Carla Mendes',
    etape: EtapeCandidature.confirmee,
    etat: null,
    indisponible: true,
    indisponibleJusquAu: DateTime.utc(2026, 11, 3),
    paysResidence: 'PT',
  ),
  ligneTest(
    id: 'd4',
    nom: 'Dina Saidi',
    etape: EtapeCandidature.invitee,
    etat: null,
    paiement: EtatVersement.inconnu,
    paysResidence: null,
  ),
  ligneTest(
    id: 'e5',
    nom: 'Emna Gharbi',
    etat: EtatCandidature.aCompleter,
    enPause: true,
    repriseLe: DateTime.utc(2026, 11, 10),
    paiement: EtatVersement.incompatible,
    paysResidence: 'TN',
  ),
  ligneTest(
    id: 'f6',
    nom: 'Farah Nasser',
    etat: EtatCandidature.paiementNonDisponible,
    issue: IssueCandidature.refusee,
    paysResidence: 'AE',
  ),
];

/// Les gabarits de la fiche : 320 texte x2, 390, 1440 texte x1 et x2.
const List<({String nom, Size taille, double echelle})> _gabarits =
    <({String nom, Size taille, double echelle})>[
      (nom: '320 x2', taille: Size(320, 568), echelle: 2),
      (nom: '390 x1', taille: Size(390, 844), echelle: 1),
      (nom: '1440 x1', taille: Size(1440, 900), echelle: 1),
      (nom: '1440 x2', taille: Size(1440, 900), echelle: 2),
    ];

/// Un etat de la file : son port et ses options de montage.
typedef _Etat = ({
  String nom,
  PortCandidaturesDirection? Function() port,
  bool horsLigne,
  bool avecSelection,
});

Future<void> _verifier(WidgetTester tester, String quoi) async {
  final List<String> fautes = await defautsEcranDefile(tester);
  expect(fautes, isEmpty, reason: 'defaut de texte : $quoi');
  verifierUnSeulBoutonPlein(tester);
}

Future<void> _etat(
  WidgetTester tester,
  _Etat etat,
  ({String nom, Size taille, double echelle}) g, {
  TextDirection? direction,
}) async {
  await monterCandidatures(
    tester,
    port: etat.port(),
    horsLigne: etat.horsLigne,
    largeur: g.taille.width,
    hauteur: g.taille.height,
    echelle: g.echelle,
    direction: direction,
    invitations: true,
  );
  await _verifier(tester, '${etat.nom}, ${g.nom}');
  if (etat.avecSelection) {
    for (final String nom in <String>['Amina Diallo', 'Carla Mendes']) {
      // La case de la carte, ou celle du tableau : la meme voix de lecteur
      // d'ecran (« Cocher Amina Diallo »).
      final Finder f = find.byWidgetPredicate(
        (Widget w) =>
            w is CaseACocher &&
            w.libelle == t.commun.listes.cocherLigne(objet: nom),
      );
      await tester.ensureVisible(f);
      await tester.pump();
      await tester.tap(f);
      await laisser(tester);
    }
    await _verifier(tester, '${etat.nom} avec selection, ${g.nom}');
  }
}

final List<_Etat> _etats = <_Etat>[
  (
    nom: 'liste',
    port: () => FauxCandidaturesDirection(
      lignes: _lignes(),
      capacitesRendues: capacitesGestes,
    ),
    horsLigne: false,
    avecSelection: false,
  ),
  (
    nom: 'liste et selection',
    port: () => FauxCandidaturesDirection(
      lignes: _lignes(),
      capacitesRendues: capacitesGestes,
    ),
    horsLigne: false,
    avecSelection: true,
  ),
  (
    nom: 'liste hors ligne et selection',
    port: () => FauxCandidaturesDirection(
      lignes: _lignes(),
      capacitesRendues: capacitesGestes,
    ),
    horsLigne: true,
    avecSelection: true,
  ),
  (
    nom: 'exception du super-admin et gardees pour suivi',
    port: () => FauxCandidaturesDirection(
      lignes: _lignes(),
      capacitesRendues: const CapacitesCandidatures(
        peutLire: true,
        peutLireHorsGenre: true,
        gestes: <String, bool>{'garderPourSuivi': true},
      ),
    ),
    horsLigne: false,
    avecSelection: false,
  ),
  (
    nom: 'alertes a zero',
    port: () => FauxCandidaturesDirection(
      lignes: _lignes(),
      alertes: const CompteursAlertes(
        bloquees: 0,
        entretiensEnRetard: 0,
        informationsManquantes: 0,
        confirmeesIndisponibles: 0,
      ),
    ),
    horsLigne: false,
    avecSelection: false,
  ),
  (
    nom: 'vide',
    port: FauxCandidaturesDirection.new,
    horsLigne: false,
    avecSelection: false,
  ),
  (
    nom: 'erreur',
    port: () =>
        FauxCandidaturesDirection(erreurLister: (int _) => StateError('panne')),
    horsLigne: false,
    avecSelection: false,
  ),
  (
    nom: 'hors ligne, rien de lu',
    port: () =>
        FauxCandidaturesDirection(erreurLister: (int _) => StateError('panne')),
    horsLigne: true,
    avecSelection: false,
  ),
  (
    nom: 'capacite indisponible',
    port: () => const CandidaturesDirectionIndisponible(),
    horsLigne: false,
    avecSelection: false,
  ),
  (
    nom: 'acces refuse',
    port: () => FauxCandidaturesDirection(
      erreurLister: (int _) => const PermissionInsuffisante('lister'),
    ),
    horsLigne: false,
    avecSelection: false,
  ),
  (
    nom: 'genre inconnu',
    port: () => FauxCandidaturesDirection(
      erreurLister: (int _) => const GenreLecteurInconnu(),
    ),
    horsLigne: false,
    avecSelection: false,
  ),
];

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  for (final _Etat etat in _etats) {
    for (final ({String nom, Size taille, double echelle}) g in _gabarits) {
      testWidgets('francais, ${etat.nom}, ${g.nom} : tout se lit', (
        WidgetTester tester,
      ) async {
        await _etat(tester, etat, g);
      });
    }
  }

  // L'arabe de droite a gauche aux gabarits les plus durs, sur les etats qui
  // portent le plus de texte.
  for (final _Etat etat in _etats.where(
    (_Etat e) => <String>{
      'liste',
      'liste et selection',
      'alertes a zero',
      'vide',
      'erreur',
      'genre inconnu',
    }.contains(e.nom),
  )) {
    for (final ({String nom, Size taille, double echelle}) g in _gabarits.where(
      (g) => g.nom != '1440 x2',
    )) {
      testWidgets(
        'arabe de droite a gauche, ${etat.nom}, ${g.nom} : tout se lit',
        (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
          await _etat(tester, etat, g, direction: TextDirection.rtl);
        },
      );
    }
  }
}
