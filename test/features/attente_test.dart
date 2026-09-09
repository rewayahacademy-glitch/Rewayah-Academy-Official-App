import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/dossier/attente_page.dart';

import '../support/harnais.dart';

Future<void> _monter(WidgetTester tester, FauxServiceDossier dossier) async {
  await tester.pumpWidget(
    hote(
      const AttentePage(),
      surcharges: <Override>[serviceDossierProvider.overrideWithValue(dossier)],
    ),
  );
  await tester.pumpAndSettle();
}

EtatDossier _etat({
  AccountStatus statut = AccountStatus.pendingKyc,
  bool accuse = false,
  bool contrat = false,
  bool piece = false,
  StatutPiece? statutPiece,
  String? motif,
  DateTime? depose,
}) => EtatDossier(
  profilExiste: true,
  role: AppRole.guardian,
  statutCompte: statut,
  accuseSigne: accuse,
  contratSigne: contrat,
  pieceDeposee: piece,
  statutPiece: statutPiece,
  motifRefus: motif,
  deposeLe: depose,
);

void main() {
  group('Scenario 10 : le portail d attente affiche le bon etat', () {
    testWidgets('dossier incomplet : la liste de ce qui manque, dans l ordre', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat();
      await _monter(tester, dossier);

      expect(find.text(t.attente.dossierIncomplet), findsOneWidget);
      expect(find.text(t.attente.carteAccuse), findsOneWidget);
      expect(find.text(t.attente.signatureContrat), findsOneWidget);
      expect(find.text(t.attente.pieceIdentite), findsOneWidget);

      // L'accuse precede le contrat : il dit en langage clair ce que le
      // contrat formalisera ensuite (ADR-011).
      final double yAccuse = tester
          .getTopLeft(find.text(t.attente.carteAccuse))
          .dy;
      final double yContrat = tester
          .getTopLeft(find.text(t.attente.signatureContrat))
          .dy;
      expect(yAccuse, lessThan(yContrat));
    });

    testWidgets('en verification : le statut, la date et le delai', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(
          accuse: true,
          contrat: true,
          piece: true,
          statutPiece: StatutPiece.enAttente,
          depose: DateTime(2026, 9, 4),
        );
      await _monter(tester, dossier);

      expect(find.text(t.attente.titre), findsOneWidget);
      expect(find.textContaining('04/09/2026'), findsOneWidget);
      expect(find.text(t.attente.dossierIncomplet), findsNothing);
    });

    testWidgets('refuse : le motif en une phrase, et de quoi corriger', (
      WidgetTester tester,
    ) async {
      const String motif = 'Photo illisible, merci de la reprendre.';
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(
          accuse: true,
          contrat: true,
          piece: true,
          statutPiece: StatutPiece.refusee,
          motif: motif,
        );
      await _monter(tester, dossier);

      expect(find.text(t.attente.refuse), findsOneWidget);
      expect(find.text(motif), findsOneWidget);
      expect(find.text(t.attente.corriger), findsOneWidget);
    });

    testWidgets('suspendu : le motif prime sur l etat du dossier', (
      WidgetTester tester,
    ) async {
      // Un compte suspendu le reste meme si son dossier est complet : sinon
      // l ecran lui dirait « nous verifions » alors que rien n avance.
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(
          statut: AccountStatus.disabled,
          accuse: true,
          contrat: true,
          piece: true,
          statutPiece: StatutPiece.enAttente,
        );
      await _monter(tester, dossier);

      expect(find.text(t.attente.suspendu), findsOneWidget);
      expect(find.text(t.attente.titre), findsNothing);
    });

    testWidgets('un etat illisible se dit, et laisse reessayer', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..erreurAJeter = StateError('reseau');
      await _monter(tester, dossier);

      expect(find.text(t.commun.reessayer), findsOneWidget);
      expect(find.text(t.attente.dossierIncomplet), findsNothing);
    });

    testWidgets('le portail ne laisse jamais deviner ce qui est derriere', (
      WidgetTester tester,
    ) async {
      // Un portail qui montre l application sous un voile cree de la
      // frustration. Aucun libelle de navigation de role ne doit apparaitre.
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat();
      await _monter(tester, dossier);

      for (final String interdit in <String>[
        t.nav.tuteur.foyer,
        t.nav.tuteur.disponibilites,
        t.nav.eleve.coran,
        t.nav.enseignant.journee,
      ]) {
        expect(find.text(interdit), findsNothing, reason: interdit);
      }
    });
  });

  group('EtatDossier : ce qui manque, et dans quel ordre', () {
    test('un refus prime sur une piece manquante', () {
      // C est le refus qui porte le motif, donc ce que la famille doit lire.
      final EtatDossier refuse = _etat(
        accuse: true,
        contrat: true,
        piece: true,
        statutPiece: StatutPiece.refusee,
        motif: 'flou',
      );
      expect(refuse.etape, EtapeDossier.refuse);
    });

    test('un dossier complet passe en verification', () {
      expect(
        _etat(
          accuse: true,
          contrat: true,
          piece: true,
          statutPiece: StatutPiece.enAttente,
        ).etape,
        EtapeDossier.enVerification,
      );
    });

    test('la lecture de etat_dossier() sait rendre un compte sans profil', () {
      final EtatDossier lu = EtatDossier.depuisJson(const <String, dynamic>{
        'profil': false,
      });
      expect(lu.profilExiste, isFalse);
    });

    test(
      'la lecture reprend le motif et la date telle que la base les donne',
      () {
        final EtatDossier lu = EtatDossier.depuisJson(const <String, dynamic>{
          'profil': true,
          'role': 'teacher',
          'statut': 'pending_kyc',
          'piece_deposee': true,
          'piece_statut': 'rejected',
          'motif_refus': 'Photo illisible.',
          'depose_le': '2026-09-04T08:30:00Z',
          'contrat_signe': true,
          'accuse_signe': true,
        });

        expect(lu.role, AppRole.teacher);
        expect(lu.statutPiece, StatutPiece.refusee);
        expect(lu.motifRefus, 'Photo illisible.');
        expect(lu.deposeLe?.toUtc(), DateTime.utc(2026, 9, 4, 8, 30));
        expect(lu.etape, EtapeDossier.refuse);
      },
    );
  });
}
