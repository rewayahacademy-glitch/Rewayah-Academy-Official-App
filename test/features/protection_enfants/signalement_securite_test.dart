// PE (18/10/2026) : la categorie « Securite d'un enfant » de « Signaler un
// besoin ».
//
// Ce que le test prouve : la categorie est proposee ; la choisir retire le
// champ du message pour la famille et affiche la notice (prioritaire, qui lit,
// qui ne voit pas) ; la ligne du responsable dit « La direction recoit votre
// signalement. » quand rien n'est saisi, nomme le responsable et son courriel
// quand l'administration l'a fait, et dit la panne de lecture sans la faire
// passer pour un reglage vide ; le depot part avec la bonne categorie et sans
// message famille, meme si un message avait ete choisi avant ; la liste de
// l'enseignant n'a jamais ce signalement ; le modele refuse de le transmettre.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/protection_enfants/responsable_protection.dart';
import 'package:rewayah_academy/core/tc_parcours/libelles_parcours.dart';
import 'package:rewayah_academy/core/tc_parcours/port_signalement.dart';
import 'package:rewayah_academy/core/tc_parcours/student_concern.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_eleve_enseignant.dart';
import 'package:rewayah_academy/features/protection_enfants/ligne_responsable.dart';
import 'package:rewayah_academy/features/protection_enfants/notice_securite_enfant.dart';
import 'package:rewayah_academy/features/tc_flux_academique/feuille_signalement.dart';

import '../../teaching_core/h/support/hote_h.dart';

/// Un responsable lu, ou une panne de lecture.
class _FauxResponsable implements PortResponsableProtection {
  _FauxResponsable(this.valeur, {this.panne = false});

  final ResponsableProtection valeur;
  final bool panne;
  int lectures = 0;

  @override
  Future<ResponsableProtection> lire() async {
    lectures++;
    if (panne) {
      throw Exception('hors ligne');
    }
    return valeur;
  }
}

/// Un depot qui garde ce qu'il a recu.
class _DepotEspion extends SignalementMemoire {
  _DepotEspion() : super('ens-1');

  CategorieSignalement? categorieRecue;
  String? familleRecue = 'jamais appele';

  @override
  Future<StudentConcern> signaler({
    required CategorieSignalement categorie,
    required String groupeId,
    String? sessionId,
    required String academyId,
    required String internalDetails,
    String? familySummary,
  }) {
    categorieRecue = categorie;
    familleRecue = familySummary;
    return super.signaler(
      categorie: categorie,
      groupeId: groupeId,
      sessionId: sessionId,
      academyId: academyId,
      internalDetails: internalDetails,
      familySummary: familySummary,
    );
  }
}

class _Ouvreur extends StatelessWidget {
  const _Ouvreur();

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => FeuilleSignalement.ouvrir(
      context,
      groupeId: 'g1',
      academyId: 'RA-AB0012',
      prenomEleve: 'Amina',
    ),
    child: const Text('ouvrir'),
  );
}

Future<void> _ouvrir(WidgetTester tester, List<Override> surcharges) async {
  await tester.pumpWidget(hoteH(const _Ouvreur(), surcharges: surcharges));
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

Future<void> _choisirSecurite(WidgetTester tester) => _toucher(
  tester,
  find
      .text(libelleCategorieSignalement(CategorieSignalement.securiteEnfant))
      .first,
);

List<Override> _surcharges(
  PortSignalement depot,
  PortResponsableProtection responsable,
) => <Override>[
  portSignalementProvider.overrideWithValue(depot),
  portResponsableProtectionProvider.overrideWithValue(responsable),
];

void main() {
  group('PE : categorie « Securite d un enfant »', () {
    testWidgets('la categorie est proposee et dit ce qu elle est', (
      WidgetTester tester,
    ) async {
      telephone(tester);
      await _ouvrir(
        tester,
        _surcharges(
          SignalementMemoire('ens-1'),
          _FauxResponsable(ResponsableProtection.aucun),
        ),
      );

      expect(t.protectionEnfants.categorie, 'Sécurité d\'un enfant');
      expect(
        find.text(
          libelleCategorieSignalement(CategorieSignalement.securiteEnfant),
        ),
        findsOneWidget,
      );
      // Tant qu'elle n'est pas choisie, le champ famille et ses phrases sont la.
      expect(find.byKey(NoticeSecuriteEnfant.noticeKey), findsNothing);
      expect(
        find.text(t.motifs.signalement.pedagogique.renforcement),
        findsOneWidget,
      );
    });

    testWidgets('la choisir retire le message famille et dit qui lit', (
      WidgetTester tester,
    ) async {
      telephone(tester);
      await _ouvrir(
        tester,
        _surcharges(
          SignalementMemoire('ens-1'),
          _FauxResponsable(ResponsableProtection.aucun),
        ),
      );

      await _choisirSecurite(tester);

      expect(find.byKey(NoticeSecuriteEnfant.noticeKey), findsOneWidget);
      expect(find.text(t.protectionEnfants.prioritaireTitre), findsOneWidget);
      expect(find.text(t.protectionEnfants.prioritaireDetail), findsOneWidget);
      expect(find.text(t.protectionEnfants.urgence), findsOneWidget);
      // Plus de message pour la famille, ni de phrases-types.
      expect(find.text(t.tc.parcours.signalement.famille), findsNothing);
      expect(
        find.text(t.motifs.signalement.pedagogique.renforcement),
        findsNothing,
      );
      // Un seul champ : la note interne.
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('responsable vide : la direction recoit le signalement', (
      WidgetTester tester,
    ) async {
      telephone(tester);
      await _ouvrir(
        tester,
        _surcharges(
          SignalementMemoire('ens-1'),
          _FauxResponsable(ResponsableProtection.aucun),
        ),
      );
      await _choisirSecurite(tester);

      expect(
        find.text('La direction reçoit votre signalement.'),
        findsOneWidget,
      );
      expect(find.textContaining('Courriel de contact'), findsNothing);
    });

    testWidgets('responsable saisi : son nom et son courriel s affichent', (
      WidgetTester tester,
    ) async {
      telephone(tester);
      await _ouvrir(
        tester,
        _surcharges(
          SignalementMemoire('ens-1'),
          _FauxResponsable(
            const ResponsableProtection(
              nom: 'Sayyid Yusuf',
              courriel: 'protection@example.test',
            ),
          ),
        ),
      );
      await _choisirSecurite(tester);

      expect(
        find.text('Sayyid Yusuf et la direction reçoivent votre signalement.'),
        findsOneWidget,
      );
      // L'adresse porte des points de coupure invisibles : on la cherche sans.
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is Text &&
              (w.data ?? '')
                  .replaceAll('​', '')
                  .contains('protection@example.test'),
        ),
        findsOneWidget,
      );
      expect(find.text('La direction reçoit votre signalement.'), findsNothing);
    });

    testWidgets('lecture impossible : la panne se dit, la lecture se relance', (
      WidgetTester tester,
    ) async {
      telephone(tester);
      final _FauxResponsable port = _FauxResponsable(
        ResponsableProtection.aucun,
        panne: true,
      );
      await _ouvrir(tester, _surcharges(SignalementMemoire('ens-1'), port));
      await _choisirSecurite(tester);

      expect(find.byKey(LigneResponsableProtection.erreurKey), findsOneWidget);
      expect(find.text(t.protectionEnfants.erreurLecture), findsOneWidget);
      // Ce n'est pas un reglage vide : la phrase « la direction » n'est pas dite.
      expect(find.text(t.protectionEnfants.direction), findsNothing);

      final int avant = port.lectures;
      await _toucher(tester, find.text(t.commun.reessayer));
      expect(port.lectures, greaterThan(avant));
    });

    testWidgets('le depot part prioritaire, sans message famille', (
      WidgetTester tester,
    ) async {
      telephone(tester);
      final _DepotEspion depot = _DepotEspion();
      await _ouvrir(
        tester,
        _surcharges(depot, _FauxResponsable(ResponsableProtection.aucun)),
      );

      // Une phrase famille choisie avant de changer de categorie ne part pas.
      await _toucher(
        tester,
        find.text(t.motifs.signalement.pedagogique.renforcement),
      );
      await _choisirSecurite(tester);
      await tester.enterText(find.byType(TextField).first, 'Note interne.');
      await tester.pumpAndSettle();
      final Finder envoyer = find.text(t.tc.parcours.signalement.envoyer);
      await _toucher(tester, envoyer);

      expect(depot.categorieRecue, CategorieSignalement.securiteEnfant);
      expect(depot.familleRecue, isNull);
      // L'enseignant ne relit pas ce signalement (comme cote serveur).
      expect(await depot.mesSignalements(), isEmpty);
    });

    test(
      'le modele refuse de transmettre un signalement de securite',
      () async {
        final SignalementMemoire depot = SignalementMemoire('ens-1');
        final StudentConcern c = await depot.signaler(
          categorie: CategorieSignalement.securiteEnfant,
          groupeId: 'g1',
          academyId: 'RA-AB0012',
          internalDetails: 'Note.',
          familySummary: 'Un message qui ne doit pas rester.',
        );
        expect(c.familySummary, isNull);
        expect(c.peutEtreTransmis, isFalse);
        expect(c.pourLaFamille(), isNull);
        await expectLater(
          depot.transmettre(
            concernId: c.id,
            cible: CibleTransmission.tuteurDuMineur,
          ),
          throwsA(isA<EchecSignalement>()),
        );
        expect(
          CategorieSignalement.depuisSql('securite_enfant'),
          CategorieSignalement.securiteEnfant,
        );
        expect(
          CategorieSignalement.securiteEnfant.valeurSql,
          'securite_enfant',
        );
      },
    );
  });

  group('PE : meme categorie dans la fiche de l eleve', () {
    testWidgets('la notice remplace le resume partageable', (
      WidgetTester tester,
    ) async {
      telephone(tester);
      await tester.pumpWidget(
        hoteH(
          const SignalerBesoin(
            eleve: EleveFiche(
              membre: MembreSeance(
                studentId: 'e1',
                identifiantImmuable: 'RA-AB0012',
                prenom: 'Amina',
              ),
              classe: 'Classe du lundi',
            ),
          ),
          surcharges: <Override>[
            portResponsableProtectionProvider.overrideWithValue(
              _FauxResponsable(ResponsableProtection.aucun),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.signalement.resume), findsOneWidget);
      await _toucher(tester, find.text(CategorieBesoin.securiteEnfant.libelle));

      expect(find.text(t.enseignant.signalement.resume), findsNothing);
      expect(find.byKey(NoticeSecuriteEnfant.noticeKey), findsOneWidget);
      expect(
        find.text('La direction reçoit votre signalement.'),
        findsOneWidget,
      );
    });
  });
}
