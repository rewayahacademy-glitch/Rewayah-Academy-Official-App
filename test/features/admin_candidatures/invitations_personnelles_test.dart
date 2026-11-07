// INVITATIONS-PERSONNELLES (lot 7, 07/11/2026) : le lien « Envoyer les codes
// personnels » de la file des candidatures et sa feuille.
//
// Ce que le test prouve :
// - le lien n'existe que pour qui peut importer (super administrateur) et si
//   le port est servi, jamais grise ;
// - les comptes par situation, le rythme du jour, un seul bouton plein ;
// - l'envoi : « {n} messages mis en file », le nombre attendu est celui de
//   l'apercu, puis celui que le serveur a rendu ;
// - « le nombre a change » : rien n'est dit parti, l'apercu se relit ;
// - la limite du jour : aucun bouton, « reprenez demain » ;
// - plus personne a inviter : l'etat vide, sans bouton ;
// - double verification requise : l'etat qui la demande ; acces refuse ;
// - une coupure pendant l'envoi : « non confirme », « Reessayer » ;
// - 320 px a texte x2, et l'arabe (droite a gauche).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_import_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_import_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_invitations_personnelles.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/admin_candidatures/invitations_personnelles.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/import_formulaires_page.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../fixtures/candidature/faux_import_candidatures.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';
import 'hote_candidatures.dart';

const Key _lien = ValueKey<String>('candidatures-codes-personnels');

ApercuInvitationsPersonnelles _apercu({
  int aInviter = 3,
  int aRenvoyer = 1,
  int reste = 300,
  int importees = 20,
  int varianteA = 2,
}) => ApercuInvitationsPersonnelles(
  aInviter: aInviter,
  aRenvoyer: aRenvoyer,
  dejaInvites: 2,
  dejaInscrits: 5,
  revoquees: 1,
  desinscrits: 1,
  sansAdresse: 4,
  plafondJour: 300,
  resteAujourdhui: reste,
  reponsesImportees: importees,
  varianteA: varianteA,
);

class _Faux implements PortInvitationsPersonnelles {
  _Faux({ApercuInvitationsPersonnelles? apercu, this.erreurApercu})
    : apercuRendu = apercu ?? _apercu();

  ApercuInvitationsPersonnelles apercuRendu;
  Exception? erreurApercu;
  Exception? erreurEnvoi;
  ResultatInvitationsPersonnelles resultat =
      const ResultatInvitationsPersonnelles(
        misEnFile: 4,
        restants: 0,
        resteAujourdhui: 296,
      );
  final List<(int, int)> envois = <(int, int)>[];
  int apercus = 0;

  @override
  Future<ApercuInvitationsPersonnelles> apercu() async {
    apercus++;
    final Exception? e = erreurApercu;
    if (e != null) throw e;
    return apercuRendu;
  }

  @override
  Future<ResultatInvitationsPersonnelles> envoyer({
    required int attendu,
    int limite = limiteInvitationsParEnvoi,
  }) async {
    envois.add((attendu, limite));
    final Exception? e = erreurEnvoi;
    if (e != null) throw e;
    return resultat;
  }

  @override
  Future<ResultatLien> lienPour({
    required String candidatureId,
    required String courriel,
  }) => throw UnimplementedError();
}

Future<void> _monter(
  WidgetTester tester,
  _Faux? faux, {
  bool peutImporter = true,
  bool doubleRequise = false,
  bool horsLigne = false,
  double largeur = 390,
  double echelle = 1,
  TextDirection? direction,
}) => monterCandidatures(
  tester,
  port: FauxCandidaturesDirection(
    lignes: <LigneCandidature>[ligneTest(id: 'a1')],
    capacitesRendues: CapacitesCandidatures(
      peutLire: true,
      genreLecteurConnu: true,
      peutImporter: peutImporter,
    ),
  ),
  surcharges: <Override>[
    portImportCandidaturesProvider.overrideWithValue(
      FauxImportCandidatures(
        capacitesRendues: CapacitesImportCandidatures(
          peutImporter: peutImporter,
          doubleVerificationRequise: doubleRequise,
        ),
      ),
    ),
    portInvitationsPersonnellesProvider.overrideWithValue(faux),
  ],
  horsLigne: horsLigne,
  largeur: largeur,
  echelle: echelle,
  direction: direction,
);

Future<void> _ouvrir(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(_lien));
  await tester.pump();
  await tester.tap(find.byKey(_lien));
  await laisser(tester);
}

Future<void> _envoyer(WidgetTester tester) async {
  final Finder f = find.byKey(FeuilleInvitationsPersonnelles.cleEnvoyer);
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await laisser(tester);
}

String _libelle(WidgetTester tester) => tester
    .widget<ActionPrincipale>(
      find.byKey(FeuilleInvitationsPersonnelles.cleEnvoyer),
    )
    .libelle;

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('le lien', () {
    testWidgets('present pour qui peut importer, port servi', (tester) async {
      await _monter(tester, _Faux());
      expect(find.byKey(_lien), findsOneWidget);
      expect(find.text('Envoyer les codes personnels'), findsOneWidget);
    });

    testWidgets('absent sans le port', (tester) async {
      await _monter(tester, null);
      expect(find.byKey(_lien), findsNothing);
    });

    testWidgets('absent pour une direction qui ne peut pas importer', (
      tester,
    ) async {
      await _monter(tester, _Faux(), peutImporter: false);
      expect(find.byKey(_lien), findsNothing);
    });
  });

  group('la feuille', () {
    testWidgets('les comptes, le rythme et un seul bouton plein', (
      tester,
    ) async {
      await _monter(tester, _Faux());
      await _ouvrir(tester);
      expect(find.byKey(FeuilleInvitationsPersonnelles.cle), findsOneWidget);
      expect(find.text('3 personnes à inviter'), findsOneWidget);
      expect(find.text('1 code expiré à renvoyer'), findsOneWidget);
      expect(find.text('2 personnes ont déjà un code valide'), findsOneWidget);
      expect(find.text('4 réponses sans adresse e-mail'), findsOneWidget);
      expect(
        find.byKey(FeuilleInvitationsPersonnelles.cleRythme),
        findsOneWidget,
      );
      expect(_libelle(tester), 'Envoyer leur code à 4 personnes');
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('l envoi attend le nombre vu, puis dit le resultat', (
      tester,
    ) async {
      final _Faux faux = _Faux();
      await _monter(tester, faux);
      await _ouvrir(tester);
      await _envoyer(tester);
      expect(faux.envois, <(int, int)>[(4, limiteInvitationsParEnvoi)]);
      expect(
        find.byKey(FeuilleInvitationsPersonnelles.cleResultat),
        findsOneWidget,
      );
      expect(find.text(t.candidatsFlux.file.misEnFile(n: 4)), findsOneWidget);
      expect(
        find.text(t.candidatsFlux.invitationsPersonnelles.resultat.tout),
        findsOneWidget,
      );
      expect(
        find.byKey(FeuilleInvitationsPersonnelles.cleEnvoyer),
        findsNothing,
      );
    });

    testWidgets('s il reste du monde, le geste suivant attend ce reste', (
      tester,
    ) async {
      final _Faux faux = _Faux(apercu: _apercu(aInviter: 250, aRenvoyer: 0))
        ..resultat = const ResultatInvitationsPersonnelles(
          misEnFile: 200,
          restants: 50,
          resteAujourdhui: 100,
        );
      await _monter(tester, faux);
      await _ouvrir(tester);
      expect(_libelle(tester), 'Envoyer leur code à 200 personnes');
      await _envoyer(tester);
      expect(_libelle(tester), 'Envoyer leur code à 50 personnes');
      await _envoyer(tester);
      expect(faux.envois, <(int, int)>[(250, 200), (50, 200)]);
    });

    testWidgets('le nombre a change : rien de parti, l apercu se relit', (
      tester,
    ) async {
      final _Faux faux = _Faux()..erreurEnvoi = const NombreChange(6);
      await _monter(tester, faux);
      await _ouvrir(tester);
      final int avant = faux.apercus;
      faux.apercuRendu = _apercu(aInviter: 5);
      await _envoyer(tester);
      expect(
        find.byKey(FeuilleInvitationsPersonnelles.cleNombreChange),
        findsOneWidget,
      );
      expect(faux.apercus, greaterThan(avant));
      expect(find.text('5 personnes à inviter'), findsOneWidget);
      expect(find.text(t.candidatsFlux.file.misEnFile(n: 4)), findsNothing);
    });

    testWidgets('la limite du jour : aucun bouton, reprenez demain', (
      tester,
    ) async {
      await _monter(tester, _Faux(apercu: _apercu(reste: 0)));
      await _ouvrir(tester);
      expect(
        find.byKey(FeuilleInvitationsPersonnelles.clePlafond),
        findsOneWidget,
      );
      expect(find.textContaining('reprenez demain'), findsOneWidget);
      expect(
        find.byKey(FeuilleInvitationsPersonnelles.cleEnvoyer),
        findsNothing,
      );
    });

    testWidgets('refus « plafond » rendu a l envoi : plus de bouton', (
      tester,
    ) async {
      final _Faux faux = _Faux()..erreurEnvoi = const PlafondAtteint(4);
      await _monter(tester, faux);
      await _ouvrir(tester);
      await _envoyer(tester);
      expect(
        find.byKey(FeuilleInvitationsPersonnelles.clePlafond),
        findsOneWidget,
      );
      expect(
        find.byKey(FeuilleInvitationsPersonnelles.cleEnvoyer),
        findsNothing,
      );
    });

    testWidgets('aucune reponse importee : la phrase, aucun bouton', (
      tester,
    ) async {
      await _monter(tester, _Faux(apercu: _apercu(importees: 0)));
      await _ouvrir(tester);
      expect(
        find.byKey(FeuilleInvitationsPersonnelles.cleAucuneImportee),
        findsOneWidget,
      );
      expect(
        find.text(t.candidatsFlux.invitationsPersonnelles.aucuneImportee),
        findsOneWidget,
      );
      expect(
        find.byKey(FeuilleInvitationsPersonnelles.cleEnvoyer),
        findsNothing,
      );
    });

    testWidgets('la variante A se compte a part', (tester) async {
      await _monter(tester, _Faux());
      await _ouvrir(tester);
      expect(
        find.text(
          "dont 2 personnes qui ont reçu le courriel d'attente de fin octobre",
        ),
        findsOneWidget,
      );
    });

    testWidgets('plus personne a inviter : l etat vide, sans bouton', (
      tester,
    ) async {
      await _monter(tester, _Faux(apercu: _apercu(aInviter: 0, aRenvoyer: 0)));
      await _ouvrir(tester);
      expect(
        find.byKey(FeuilleInvitationsPersonnelles.cleVide),
        findsOneWidget,
      );
      expect(
        find.byKey(FeuilleInvitationsPersonnelles.cleEnvoyer),
        findsNothing,
      );
    });

    testWidgets('double verification requise : l etat qui la demande', (
      tester,
    ) async {
      await _monter(
        tester,
        _Faux(erreurApercu: const PermissionInsuffisante('apercu')),
        doubleRequise: true,
      );
      await _ouvrir(tester);
      expect(find.byType(EtatDoubleVerification), findsOneWidget);
      expect(
        find.byKey(FeuilleInvitationsPersonnelles.cleEnvoyer),
        findsNothing,
      );
    });

    testWidgets('acces refuse par le serveur', (tester) async {
      await _monter(
        tester,
        _Faux(erreurApercu: const PermissionInsuffisante('apercu')),
      );
      await _ouvrir(tester);
      expect(
        find.byKey(FeuilleInvitationsPersonnelles.cleRefus),
        findsOneWidget,
      );
    });

    testWidgets('coupure pendant l envoi : non confirme, Reessayer', (
      tester,
    ) async {
      final _Faux faux = _Faux()
        ..erreurEnvoi = const InvitationsPersonnellesHorsLigne();
      await _monter(tester, faux);
      await _ouvrir(tester);
      await _envoyer(tester);
      expect(
        find.byKey(FeuilleInvitationsPersonnelles.cleNonConfirme),
        findsOneWidget,
      );
      expect(_libelle(tester), t.commun.reessayer);
      expect(find.text(t.candidatsFlux.file.misEnFile(n: 4)), findsNothing);
    });

    testWidgets('320 px, texte x2 : rien ne deborde', (tester) async {
      await _monter(tester, _Faux(), largeur: 320, echelle: 2);
      await _ouvrir(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(FeuilleInvitationsPersonnelles.cleEnvoyer), findsOne);
    });

    testWidgets('en arabe, de droite a gauche', (tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monter(tester, _Faux(), direction: TextDirection.rtl);
      await _ouvrir(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('إرسال الرموز الشخصية'), findsWidgets);
    });
  });
}
