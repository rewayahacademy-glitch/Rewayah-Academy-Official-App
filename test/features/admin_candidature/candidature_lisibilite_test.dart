// ADM-21 : la lisibilite de la candidature entiere. A chaque etat de la fiche
// (contenu, controles servis, pause, refusee, confirmee restreinte, erreur,
// hors ligne, capacite indisponible, hors portee, absente, acces refuse, genre
// inconnu) et chaque feuille de geste, a chaque configuration (320 x 568 texte
// x2, 390 x 844, 1440 x 900 texte x1 et x2, francais et arabe de droite a
// gauche) : aucun debordement, aucun mot coupe ni tronque, une ponctuation
// jamais seule, une reference jamais coupee, une seule action pleine par
// surface.
//
// Avec les VRAIES polices du depot (`chargerPolicesDuDepot`) : le texte de test
// par defaut (Ahem) est plus large que toute police du produit et ne mesure
// rien de ce que l'on voit.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/admin_candidature/blocs_candidature.dart';
import 'package:rewayah_academy/features/admin_candidature/feuille_geste.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/garde_coupe_mots_rendu.dart';
import '../../support/monter_recrutement.dart';
import 'hote_candidature.dart';

/// Les gabarits de la fiche : 320 texte x2, 390, 1440 texte x1 et x2.
const List<({String nom, Size taille, double echelle})> _gabarits =
    <({String nom, Size taille, double echelle})>[
      (nom: '320 x2', taille: Size(320, 568), echelle: 2),
      (nom: '390 x1', taille: Size(390, 844), echelle: 1),
      (nom: '1440 x1', taille: Size(1440, 900), echelle: 1),
      (nom: '1440 x2', taille: Size(1440, 900), echelle: 2),
    ];

typedef _Gabarit = ({String nom, Size taille, double echelle});

FauxCandidaturesDirection _port(
  DetailCandidature detail, {
  Object? Function(int)? erreurLire,
  List<ResponsablePossible> responsables = const <ResponsablePossible>[
    ResponsablePossible(id: 'r1', nom: 'Salma Idrissi'),
    ResponsablePossible(id: 'r2', nom: 'Leila Benkacem'),
  ],
}) => FauxCandidaturesDirection(
  capacitesRendues: capacitesGestes,
  details: <DetailCandidature>[detail],
  erreurLire: erreurLire,
  responsables: responsables,
  contacts: const <String, ContactCandidat>{
    'c1': ContactCandidat(
      courriel: 'amina.diallo.longue.adresse@exemple-academie.org',
      telephoneBrut: '0771234567',
    ),
  },
  moyens: const <String, MoyensConfirmes>{
    'SN': MoyensConfirmes(
      virementBancaire: true,
      operateurs: <OperateurPaiement>[
        OperateurPaiement(code: 'orange_money', nom: 'Orange Money'),
      ],
    ),
  },
  historiques: <String, List<EvenementCandidature>>{
    'c1': <EvenementCandidature>[
      evenementTest(
        id: 3,
        auteur: AuteurEvenement.direction,
        etatAvant: EtatCandidature.enExamen,
        etatApres: EtatCandidature.aCompleter,
        etapeAvant: EtapeCandidature.prequalification,
        etapeApres: EtapeCandidature.prequalification,
        motif:
            'Disponibilites a preciser pour le soir, et le pays de versement '
            'a confirmer avant la fin du mois.',
      ),
      evenementTest(id: 2, type: 'lecture_hors_portee'),
      evenementTest(id: 1, type: 'creee', auteur: AuteurEvenement.systeme),
    ],
  },
);

/// Un etat de la page : son port et ses options de montage.
typedef _Etat = ({
  String nom,
  PortCandidaturesDirection Function() port,
  bool horsLigne,
});

final List<_Etat> _etats = <_Etat>[
  (
    nom: 'contenu',
    port: () => _port(detailTest(courrielAObtenir: true)),
    horsLigne: false,
  ),
  (
    nom: 'controles servis',
    port: () => _port(
      detailTest(
        controles: const <ControleCandidature>[
          ControleCandidature(nom: 'paiement_compatible', valeur: true),
          ControleCandidature(
            nom: 'cadre_religieux',
            valeur: false,
            cause: 'non_accepte',
          ),
          ControleCandidature(
            nom: 'questionnaire_complet',
            valeur: false,
            cause: 'perime',
          ),
        ],
        piece: EtatPiece.aCorriger,
      ),
    ),
    horsLigne: false,
  ),
  (
    nom: 'en pause avec message',
    port: () => _port(
      detailTest(
        enPause: true,
        repriseLe: DateTime.utc(2026, 11, 10),
        pauseModele: 'pause_attente_informations',
      ),
    ),
    horsLigne: false,
  ),
  (
    nom: 'refusee',
    port: () => _port(
      detailTest(
        issue: IssueCandidature.refusee,
        refusModele: 'refus_sans_reponse',
      ),
    ),
    horsLigne: false,
  ),
  (
    nom: 'confirmee restreinte',
    port: () => _port(
      detailTest(
        etape: EtapeCandidature.confirmee,
        etat: null,
        restreinte: true,
        restrictionCause: 'paiement',
        indisponible: true,
      ),
    ),
    horsLigne: false,
  ),
  (
    nom: 'importee',
    port: () => _port(
      detailTest(
        provenance: ProvenanceCandidature.importee,
        documents: <DocumentReponses>[
          DocumentReponses(
            questionnaireVersion: 'salle-examen-1',
            reponses: reponsesTest(),
            importe: true,
          ),
        ],
      ),
    ),
    horsLigne: false,
  ),
  (nom: 'hors ligne', port: () => _port(detailTest()), horsLigne: true),
  (
    nom: 'erreur',
    port: () => _port(detailTest(), erreurLire: (int _) => StateError('panne')),
    horsLigne: false,
  ),
  (
    nom: 'hors ligne, rien de lu',
    port: () => _port(detailTest(), erreurLire: (int _) => StateError('panne')),
    horsLigne: true,
  ),
  (
    nom: 'capacite indisponible',
    port: () => const CandidaturesDirectionIndisponible(),
    horsLigne: false,
  ),
  (
    nom: 'hors portee',
    port: () => _port(
      detailTest(),
      erreurLire: (int _) => const CandidatureHorsPortee(),
    ),
    horsLigne: false,
  ),
  (
    nom: 'absente',
    port: () => _port(
      detailTest(),
      erreurLire: (int _) => const CandidatureIntrouvable(),
    ),
    horsLigne: false,
  ),
  (
    nom: 'acces refuse',
    port: () => _port(
      detailTest(),
      erreurLire: (int _) => const PermissionInsuffisante('lire'),
    ),
    horsLigne: false,
  ),
  (
    nom: 'genre inconnu',
    port: () =>
        _port(detailTest(), erreurLire: (int _) => const GenreLecteurInconnu()),
    horsLigne: false,
  ),
];

Future<void> _verifier(WidgetTester tester, String quoi) async {
  final List<String> fautes = await defautsEcranDefile(tester);
  expect(fautes, isEmpty, reason: 'defaut de texte : $quoi');
  // Un seul bouton plein par surface : la page, ou la feuille ouverte.
  final Finder pleins = find.byWidgetPredicate(
    (Widget w) => w is ActionPrincipale && w.niveau == NiveauAction.principale,
  );
  final Finder feuille = find.byKey(FeuilleGeste.cle);
  final int dansFeuille = feuille.evaluate().isEmpty
      ? 0
      : find.descendant(of: feuille, matching: pleins).evaluate().length;
  final int total = pleins.evaluate().length;
  expect(dansFeuille, lessThanOrEqualTo(1), reason: 'feuille : $quoi');
  expect(total - dansFeuille, lessThanOrEqualTo(1), reason: 'page : $quoi');
}

Future<void> _monter(
  WidgetTester tester,
  PortCandidaturesDirection port,
  _Gabarit g, {
  bool horsLigne = false,
  TextDirection? direction,
}) => monterCandidature(
  tester,
  port: port,
  horsLigne: horsLigne,
  largeur: g.taille.width,
  hauteur: g.taille.height,
  echelle: g.echelle,
  direction: direction,
);

Future<void> _tapper(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await laisser(tester, fois: 2);
  await tester.tap(f, warnIfMissed: false);
  await laisser(tester);
}

/// Ouvre la feuille de [geste] : par la prochaine action quand c'est elle, sinon
/// par le menu.
Future<void> _ouvrir(WidgetTester tester, GesteCandidature geste) async {
  final Finder bouton = find.byKey(BlocProchaineAction.cleBouton);
  final String libelle = switch (geste) {
    GesteCandidature.admettreVerifications =>
      t.admin.candidatures.gestes.admettre,
    GesteCandidature.confirmerMoyenPaiement =>
      t.admin.candidatures.gestes.confirmerMoyen,
    GesteCandidature.leverPause => t.admin.candidatures.gestes.leverPause,
    GesteCandidature.infirmerMoyenPaiement =>
      t.admin.candidatures.gestes.ecarterMoyen,
    GesteCandidature.demanderComplement =>
      t.admin.candidatures.gestes.demanderComplement,
    GesteCandidature.cloreComplement =>
      t.admin.candidatures.gestes.cloreComplement,
    GesteCandidature.mettreEnPause => t.admin.candidatures.gestes.mettreEnPause,
    GesteCandidature.refuser => t.admin.candidatures.gestes.refuser,
    GesteCandidature.consignerRetrait => t.admin.candidatures.gestes.retrait,
    GesteCandidature.rouvrir => t.admin.candidatures.gestes.rouvrir,
    GesteCandidature.definirResponsable =>
      t.admin.candidatures.gestes.responsable,
  };
  final Finder surBouton = find.descendant(
    of: bouton,
    matching: find.text(libelle),
  );
  if (surBouton.evaluate().isNotEmpty) {
    await _tapper(tester, bouton);
    return;
  }
  await _tapper(tester, find.byKey(BlocProchaineAction.cleMenu));
  // Le menu defile : a 320 en texte double, toutes ses entrees ne tiennent pas.
  await tester.ensureVisible(find.text(libelle).last);
  await laisser(tester, fois: 2);
  await tester.tap(find.text(libelle).last);
  await laisser(tester);
}

/// Le dossier ou ce geste est propose.
DetailCandidature _detailPour(GesteCandidature g) => switch (g) {
  GesteCandidature.admettreVerifications => detailTest(
    paiement: EtatVersement.compatible,
  ),
  GesteCandidature.leverPause => detailTest(enPause: true),
  GesteCandidature.rouvrir => detailTest(issue: IssueCandidature.retiree),
  GesteCandidature.cloreComplement => detailTest(
    etape: EtapeCandidature.verifications,
    etat: EtatCandidature.entretienAPlanifier,
  ),
  _ => detailTest(),
};

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  for (final _Etat etat in _etats) {
    for (final _Gabarit g in _gabarits) {
      testWidgets('francais, ${etat.nom}, ${g.nom} : tout se lit', (
        WidgetTester tester,
      ) async {
        await _monter(tester, etat.port(), g, horsLigne: etat.horsLigne);
        await _verifier(tester, '${etat.nom}, ${g.nom}');
      });
    }
  }

  // L'arabe de droite a gauche aux gabarits les plus durs, sur les etats qui
  // portent le plus de texte.
  for (final _Etat etat in _etats.where(
    (_Etat e) => <String>{
      'contenu',
      'controles servis',
      'en pause avec message',
      'refusee',
      'importee',
      'hors ligne',
      'erreur',
      'hors portee',
      'genre inconnu',
    }.contains(e.nom),
  )) {
    for (final _Gabarit g in _gabarits.where(
      (_Gabarit g) => g.nom != '1440 x2',
    )) {
      testWidgets(
        'arabe de droite a gauche, ${etat.nom}, ${g.nom} : tout se lit',
        (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
          await _monter(
            tester,
            etat.port(),
            g,
            horsLigne: etat.horsLigne,
            direction: TextDirection.rtl,
          );
          await _verifier(tester, 'arabe, ${etat.nom}, ${g.nom}');
        },
      );
    }
  }

  // Le contact : la feuille, avec une adresse longue.
  for (final _Gabarit g in _gabarits.where(
    (_Gabarit g) => g.nom != '1440 x1',
  )) {
    testWidgets('francais, contact ouvert, ${g.nom} : tout se lit', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _port(detailTest()), g);
      await _tapper(tester, find.byKey(BlocContact.cleVoir));
      await _verifier(tester, 'contact, ${g.nom}');
    });
  }

  // Chaque feuille de geste, a vide, puis avec ses refus de validation.
  for (final GesteCandidature geste in GesteCandidature.values) {
    for (final _Gabarit g in _gabarits.where(
      (_Gabarit g) => g.nom != '1440 x1',
    )) {
      testWidgets('francais, feuille ${geste.name}, ${g.nom} : tout se lit', (
        WidgetTester tester,
      ) async {
        await _monter(tester, _port(_detailPour(geste)), g);
        await _ouvrir(tester, geste);
        expect(find.byKey(FeuilleGeste.cle), findsOneWidget);
        await _verifier(tester, 'feuille ${geste.name}, ${g.nom}');
        // Valider a vide dit ce qui manque : le message aussi se lit.
        final Finder valider = find.byKey(FeuilleGeste.cleValider);
        if (valider.evaluate().isNotEmpty) {
          await _tapper(tester, valider);
          await _verifier(tester, 'feuille ${geste.name} a valider, ${g.nom}');
        }
      });
    }
  }

  for (final GesteCandidature geste in <GesteCandidature>[
    GesteCandidature.refuser,
    GesteCandidature.demanderComplement,
    GesteCandidature.confirmerMoyenPaiement,
    GesteCandidature.consignerRetrait,
  ]) {
    for (final _Gabarit g in _gabarits.where(
      (_Gabarit g) => g.nom == '320 x2' || g.nom == '390 x1',
    )) {
      testWidgets('arabe de droite a gauche, feuille ${geste.name}, ${g.nom}', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        await _monter(
          tester,
          _port(_detailPour(geste)),
          g,
          direction: TextDirection.rtl,
        );
        await _ouvrir(tester, geste);
        await _verifier(tester, 'arabe, feuille ${geste.name}, ${g.nom}');
        final Finder valider = find.byKey(FeuilleGeste.cleValider);
        if (valider.evaluate().isNotEmpty) {
          await _tapper(tester, valider);
          await _verifier(
            tester,
            'arabe, feuille ${geste.name} a valider, ${g.nom}',
          );
        }
      });
    }
  }
}
