// DOSSIER-DIRECTION (PE-C1, PE-C2, PE-C10, 20/11/2026).
//
// - PE-C1 : la reference du dossier depuis un profil (lecture, repli), et la
//   notification d'un candidat qui ouvre son dossier ;
// - PE-C2 : la synthese en tete du dossier (ce qui manque, piece, derniere
//   connexion, anciennete) et « Accueillir demande une piece verifiee » ;
// - PE-C10 : « Demander un complement » s'ouvre avec les elements manquants
//   deja coches.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/capacites/notifications_supabase.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';
import 'package:rewayah_academy/features/admin_candidature/feuille_geste.dart';
import 'package:rewayah_academy/features/admin_candidature/references_dossiers.dart';
import 'package:rewayah_academy/features/admin_candidature/synthese_tete_dossier.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/monter_recrutement.dart';
import 'hote_candidature.dart';

/// Le dossier [base] avec ce que la migration 20261130900000 ajoute.
DetailCandidature _avec(
  DetailCandidature base, {
  List<String>? manquants,
  bool connexionServie = true,
  DateTime? derniereConnexion,
}) => DetailCandidature(
  ligne: base.ligne,
  version: base.version,
  documents: base.documents,
  provenance: base.provenance,
  controles: base.controles,
  piece: base.piece,
  majorite: base.majorite,
  manquants: manquants,
  derniereConnexionServie: connexionServie,
  derniereConnexion: derniereConnexion,
);

final DateTime _maintenant = DateTime(2026, 11, 20, 15);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('lecture du dossier', () {
    test('derniereConnexion et manquants sont lus ; absents, rien', () {
      final Map<String, Object?> json = <String, Object?>{
        'id': 'c1',
        'reference': 'CAND-00001',
        'nomComplet': 'Essai Fictif',
        'type': 'enseignant',
        'etape': 'prequalification',
        'etat': 'a_completer',
        'issue': 'en_cours',
        'enPause': false,
        'restreinte': false,
        'indisponible': false,
        'paiement': 'inconnu',
        'derniereActivite': '2026-11-19T10:00:00Z',
        'recueLe': '2026-11-01T10:00:00Z',
        'gestes': <String>[],
        'version': 1,
      };
      final DetailCandidature avant = DetailCandidature.depuisJson(json);
      expect(avant.derniereConnexionServie, isFalse);
      expect(avant.manquants, isNull);
      final DetailCandidature apres = DetailCandidature.depuisJson(
        <String, Object?>{
          ...json,
          'derniereConnexion': '2026-11-19T08:30:00Z',
          'manquants': const <String>['photo', 'contrat'],
        },
      );
      expect(apres.derniereConnexionServie, isTrue);
      expect(apres.derniereConnexion, DateTime.utc(2026, 11, 19, 8, 30));
      expect(apres.manquants, <String>['photo', 'contrat']);
      final DetailCandidature jamais = DetailCandidature.depuisJson(
        <String, Object?>{...json, 'derniereConnexion': null},
      );
      expect(jamais.derniereConnexionServie, isTrue);
      expect(jamais.derniereConnexion, isNull);
    });
  });

  group('PE-C10 : elements a cocher', () {
    test('les manquants deviennent des elements du complement', () {
      final DetailCandidature d = _avec(
        detailTest(),
        manquants: <String>[
          'compte',
          'piece_identite',
          'pays_versement',
          'questionnaire',
          'photo',
          'langues',
        ],
      );
      expect(elementsComplementManquants(d), <String>{
        'piece_identite',
        'versement',
        'photo',
        'langues',
      });
    });

    test('sans manquants servis : rien de coche', () {
      expect(elementsComplementManquants(detailTest()), isEmpty);
    });
  });

  group('PE-C2 : valeurs de la synthese', () {
    test('la piece, lue dans le controle piece_validee', () {
      final v = t.recrutement.dossier3.tete.pieceValeurs;
      String? piece(bool valeur, [String? cause]) => valeurPiece(
        detailTest(
          controles: <ControleCandidature>[
            ControleCandidature(
              nom: 'piece_validee',
              valeur: valeur,
              cause: cause,
            ),
          ],
        ),
      );
      expect(piece(true), v.verifiee);
      expect(piece(false, 'piece_a_verifier'), v.aVerifier);
      expect(piece(false, 'piece_absente'), v.absente);
      expect(piece(false, 'piece_a_redeposer'), v.aRedeposer);
      expect(piece(false, 'compte_absent'), v.compteAbsent);
      expect(valeurPiece(detailTest()), isNull);
    });

    test('la derniere connexion et l\'anciennete', () {
      final s = t.recrutement.dossier3.tete;
      expect(valeurConnexion(null, _maintenant), s.connexionAucune);
      expect(
        valeurConnexion(DateTime(2026, 11, 20, 8), _maintenant),
        s.aujourdhui,
      );
      expect(valeurConnexion(DateTime(2026, 11, 19, 23), _maintenant), s.hier);
      expect(
        valeurConnexion(DateTime(2026, 11, 2, 9), _maintenant),
        contains('2026'),
      );
      expect(
        valeurAnciennete(DateTime(2026, 11, 8, 9), _maintenant),
        startsWith('Il y a 12 jours'),
      );
      expect(
        valeurAnciennete(DateTime(2026, 11, 19, 9), _maintenant),
        startsWith('Il y a 1 jour'),
      );
      expect(valeurAnciennete(_maintenant, _maintenant), s.aujourdhui);
    });
  });

  group('PE-C2 : la synthese sur le dossier', () {
    testWidgets('ce qui manque, la piece, la connexion, l\'anciennete', (
      WidgetTester tester,
    ) async {
      final DetailCandidature d = _avec(
        detailTest(
          controles: const <ControleCandidature>[
            ControleCandidature(
              nom: 'piece_validee',
              valeur: false,
              cause: 'piece_absente',
            ),
          ],
        ),
        manquants: <String>['piece_identite', 'photo'],
        derniereConnexion: DateTime.utc(2026, 10, 21, 9),
      );
      await monterCandidature(
        tester,
        port: FauxCandidaturesDirection(
          capacitesRendues: capacitesGestes,
          details: <DetailCandidature>[d],
        ),
        ouvrirRubriques: false,
      );
      final s = t.recrutement.dossier3.tete;
      expect(find.byKey(SyntheseTeteDossier.cle), findsOneWidget);
      expect(find.text(s.manque), findsOneWidget);
      Finder dans(String texte) => find.descendant(
        of: find.byKey(SyntheseTeteDossier.cle),
        matching: find.text(texte),
      );
      expect(dans(s.piece), findsOneWidget);
      expect(dans(s.pieceValeurs.absente), findsOneWidget);
      expect(dans(s.connexion), findsOneWidget);
      expect(dans(s.anciennete), findsOneWidget);
      // En Salle d'examen, « accepter » admet a l'entretien : la piece n'y
      // est pas exigee (Q4 sans reponse), aucune phrase.
      expect(find.byKey(SyntheseTeteDossier.clePieceExigee), findsNothing);
    });

    testWidgets(
      'en Salle de verification, une piece non verifiee : la phrase avant '
      '« Accueillir »',
      (WidgetTester tester) async {
        final DetailCandidature d = detailTest(
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.decisionEnAttente,
          controles: const <ControleCandidature>[
            ControleCandidature(
              nom: 'piece_validee',
              valeur: false,
              cause: 'piece_a_verifier',
            ),
          ],
        );
        await monterCandidature(
          tester,
          port: FauxCandidaturesDirection(
            capacitesRendues: capacitesGestes,
            details: <DetailCandidature>[d],
          ),
          ouvrirRubriques: false,
        );
        expect(
          find.byKey(SyntheseTeteDossier.clePieceExigee),
          findsOneWidget,
        );
      },
    );

    testWidgets('un serveur d\'avant : aucune ligne inventee', (
      WidgetTester tester,
    ) async {
      await monterCandidature(
        tester,
        port: FauxCandidaturesDirection(
          capacitesRendues: capacitesGestes,
          details: <DetailCandidature>[detailTest()],
        ),
        ouvrirRubriques: false,
      );
      final s = t.recrutement.dossier3.tete;
      expect(find.text(s.manque), findsNothing);
      expect(find.text(s.connexion), findsNothing);
      expect(find.text(s.anciennete), findsOneWidget);
    });
  });

  group('PE-C10 : le complement s\'ouvre deja coche', () {
    testWidgets('les elements manquants sont coches, les autres non', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        capacitesRendues: capacitesGestes,
        details: <DetailCandidature>[
          _avec(
            detailTest(),
            manquants: <String>['photo', 'pays_versement', 'questionnaire'],
          ),
        ],
      );
      await monterCandidature(tester, port: port, ouvrirRubriques: false);
      final Finder bouton = find.byKey(
        const ValueKey<String>('candidature-decision-demanderComplement'),
      );
      await tester.ensureVisible(bouton);
      await laisser(tester, fois: 2);
      await tester.tap(bouton, warnIfMissed: false);
      await laisser(tester);
      expect(find.byKey(FeuilleGeste.cle), findsOneWidget);
      final Set<String> coches = <String>{
        for (final ChoiceCardGroup g in tester.widgetList<ChoiceCardGroup>(
          find.descendant(
            of: find.byKey(FeuilleGeste.cle),
            matching: find.byType(ChoiceCardGroup),
          ),
        ))
          ...?g.valeurInitiale?.valeurs,
      };
      // Le questionnaire n'a pas d'element precis : rien ne le coche.
      expect(coches, <String>{'photo', 'versement'});
      // On decoche la photo, puis on envoie : seul le versement part.
      await tester.tap(find.byKey(const ValueKey<String>('element-photo')));
      await laisser(tester);
      final Finder valider = find.byKey(FeuilleGeste.cleValider);
      await tester.ensureVisible(valider);
      await laisser(tester);
      await tester.tap(valider, warnIfMissed: false);
      await laisser(tester);
      final DemandeGeste demande = port.appelsGeste.single.demande;
      expect(demande.geste, GesteCandidature.demanderComplement);
      expect(demande.elements, <String>['versement']);
    });
  });

  group('PE-C1 : la reference depuis un profil', () {
    test('lecture du serveur : lignes valides seulement', () {
      expect(
        referencesDepuisJson(<Object?>[
          <String, Object?>{'profile_id': 'p1', 'reference': 'CAND-00012'},
          <String, Object?>{'profile_id': 'p2', 'reference': 'pas-une-ref'},
          <String, Object?>{'profile_id': 'p3'},
          'bruit',
        ]),
        <String, String>{'p1': 'CAND-00012'},
      );
      expect(referencesDepuisJson(null), isEmpty);
    });

    test('le chemin : le dossier, ou « Fichiers a valider » sans reference', () {
      expect(
        cheminDossierDuProfil('CAND-00012'),
        Routes.adminPersonnesCandidaturePour('CAND-00012'),
      );
      expect(cheminDossierDuProfil(null), Routes.adminPersonnesDossiers);
      expect(cheminDossierDuProfil('x'), Routes.adminPersonnesDossiers);
    });

    test('la demande ne depend ni de l\'ordre ni des doublons', () {
      expect(
        ProfilsDemandes(const <String>['b', 'a', 'b', '']),
        ProfilsDemandes(const <String>['a', 'b']),
      );
    });

    test('notification : la reference ouvre le dossier', () {
      expect(
        destinationDuDossier('/admin/personnes/dossiers', 'CAND-00012'),
        '/admin/personnes/candidatures/CAND-00012',
      );
      expect(
        destinationDuDossier('/admin/personnes/candidatures', 'CAND-00012'),
        '/admin/personnes/candidatures/CAND-00012',
      );
      expect(
        destinationDuDossier('/admin/personnes/dossiers', null),
        '/admin/personnes/dossiers',
      );
      expect(
        destinationDuDossier('/admin/personnes/dossiers', '../x'),
        '/admin/personnes/dossiers',
      );
      // Une autre destination ne change jamais.
      expect(destinationDuDossier('/tuteur', 'CAND-00012'), '/tuteur');
      expect(destinationDuDossier(null, 'CAND-00012'), isNull);
    });

    test('la ligne de notification porte la destination du dossier', () {
      final n = notificationDepuis(
        <String, dynamic>{
          'id': 'n1',
          'evenement': 'piece_identite_deposee',
          'params': <String, dynamic>{
            'piece_id': 'k1',
            'reference': 'CAND-00012',
            'portee': 'direction',
          },
          'destination': '/admin/personnes/dossiers',
          'cree_le': '2026-11-20T10:00:00Z',
          'lu_le': null,
        },
        titrePour: (String _, Map<String, dynamic> _) =>
            const NotificationContenu(titre: 'Une piece'),
      );
      expect(n.destination, '/admin/personnes/candidatures/CAND-00012');
    });
  });
}
