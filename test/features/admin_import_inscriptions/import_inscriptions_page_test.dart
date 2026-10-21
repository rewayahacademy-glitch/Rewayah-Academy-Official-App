// IMM-ACCUEIL-FRONT : l'ecran « Importer les inscriptions » de la direction.
//
// Ce que le test prouve : les cinq etats (chargement, contenu, vide, erreur,
// hors ligne) et le port absent ; la double verification et l'acces refuse ;
// l'apercu ligne par ligne avec ses erreurs ; l'essai a blanc du serveur ;
// l'envoi (confirmation, options par foyer et pour tout le lot, un fichier a
// point-virgule repart en virgules) ; le resultat (crees, deja presents,
// refuses avec motif, invitations) ; une coupure laisse l'import « non
// confirme » et se rejoue ; 320 px, texte x2, LTR et RTL.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/import_inscriptions/analyse_inscriptions.dart';
import 'package:rewayah_academy/core/import_inscriptions/port_import_inscriptions.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_import_inscriptions/import_inscriptions_page.dart';
import 'package:rewayah_academy/features/admin_import_inscriptions/selecteur_csv.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';

const String _entete =
    'Horodateur,Pour qui faites-vous cette inscription ?,Email du tuteur,'
    'Nom du tuteur,Prénom du tuteur,Nom de l\'élève,Prénom de l\'élève,'
    'Date de naissance,Nom de l\'élève,Prénom de l\'élève,Date de naissance,Email';

/// Deux foyers valides, une adresse mal ecrite, une ligne d'essai, une ligne
/// sans personne, un enfant trop jeune (alerte).
const String _eleves =
    '$_entete\n'
    '01/10/2026,Mon enfant,mariama@exemple.test,Diallo,Mariama,Diallo,Yasmine,02/03/2015,Diallo,Omar,05/06/2012,\n'
    '01/10/2026,Mon enfant,karim@exemple.test,Haddad,Karim,Haddad,Lina,10/04/2014,,,,\n'
    '01/10/2026,Mon enfant,pas-une-adresse,Sow,Aicha,Sow,Binta,02/03/2015,,,,\n'
    '01/10/2026,Mon enfant,test@exemple.test,Sow,Aicha,Sow,Binta,02/03/2015,,,,\n'
    '01/10/2026,Mon enfant,vide@exemple.test,,,,,,,,,\n'
    '01/10/2026,Mon enfant,petit@exemple.test,Ba,Awa,Ba,Petit,01/01/2024,,,,\n';

const String _enseignants =
    'Horodateur,Prénom,Nom,Email\n2026-10-01,Ibrahim,Sow,ibrahim@exemple.test\n';

class _Port implements PortImportInscriptions {
  _Port({
    this.capacitesLues = const CapacitesImport(
      peutImporter: true,
      bornes: BornesAge(minimum: 6, adulte: 18),
    ),
    this.coupures = 0,
  });

  CapacitesImport capacitesLues;
  Completer<CapacitesImport>? retenue;
  bool echecCapacites = false;
  bool echecApercu = false;
  int coupures;
  final List<(String, String)> apercus = <(String, String)>[];
  final List<(String, String, List<OptionFoyer>)> confirmations =
      <(String, String, List<OptionFoyer>)>[];
  ApercuServeur apercuRendu = const ApercuServeur(
    foyers: 3,
    personnes: 6,
    doublons: 0,
    lignesRejetees: 2,
    motifs: <MotifRejetServeur>[
      MotifRejetServeur(
        source: SourceImport.eleves,
        ligne: 4,
        motif: 'invalid_email',
      ),
      MotifRejetServeur(
        source: SourceImport.eleves,
        ligne: 7,
        motif: 'motif_inconnu_du_serveur',
      ),
    ],
  );
  ResultatImport resultat = const ResultatImport(
    foyersTraites: 4,
    foyersCrees: 3,
    personnesCreees: 6,
    personnesDejaImportees: 1,
  );

  @override
  Future<CapacitesImport> capacites() {
    if (retenue != null) return retenue!.future;
    if (echecCapacites) return Future<CapacitesImport>.error('x');
    return Future<CapacitesImport>.value(capacitesLues);
  }

  @override
  Future<ApercuServeur> apercu({
    required String elevesCsv,
    required String enseignantsCsv,
  }) async {
    apercus.add((elevesCsv, enseignantsCsv));
    if (echecApercu) throw const ImportHorsLigne();
    return apercuRendu;
  }

  @override
  Future<ResultatImport> confirmer({
    required String elevesCsv,
    required String enseignantsCsv,
    required List<OptionFoyer> options,
  }) async {
    confirmations.add((elevesCsv, enseignantsCsv, options));
    if (coupures > 0) {
      coupures--;
      throw const ImportHorsLigne();
    }
    return resultat;
  }
}

class _Selecteur implements SelecteurCsv {
  _Selecteur(this.fichiers);

  final List<CsvChoisi?> fichiers;

  @override
  Future<CsvChoisi?> choisir() async =>
      fichiers.isEmpty ? null : fichiers.removeAt(0);
}

Future<void> _monter(
  WidgetTester tester,
  PortImportInscriptions? port, {
  SelecteurCsv? selecteur,
  bool horsLigne = false,
  double largeur = 390,
  double echelle = 1,
  TextDirection? direction,
}) => monterRecrutement(
  tester,
  chemin: '/admin/personnes/import',
  ecran: (_) => const ImportInscriptionsPage(),
  autres: <String>[
    '/admin/personnes/dossiers',
    '/admin/personnes/comptes',
    '/admin/personnes/invitations',
    '/admin/personnes/reprises',
  ],
  surcharges: <Override>[
    if (port != null) portImportInscriptionsProvider.overrideWithValue(port),
    horlogeImportProvider.overrideWithValue(() => DateTime(2026, 10, 18)),
    if (selecteur != null) selecteurCsvProvider.overrideWithValue(selecteur),
  ],
  horsLigne: horsLigne,
  largeur: largeur,
  echelle: echelle,
  direction: direction,
);

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

Future<void> _saisir(
  WidgetTester tester, {
  String eleves = _eleves,
  String enseignants = _enseignants,
}) async {
  if (eleves.isNotEmpty) {
    await tester.enterText(_cle('import-champ-eleves'), eleves);
  }
  if (enseignants.isNotEmpty) {
    await tester.enterText(_cle('import-champ-enseignants'), enseignants);
  }
  await laisser(tester, fois: 2);
}

Future<void> _voirApercu(WidgetTester tester) async {
  final Finder bouton = _cle('import-voir-apercu');
  await tester.ensureVisible(bouton);
  await tester.tap(bouton);
  await laisser(tester);
}

Future<void> _confirmer(WidgetTester tester) async {
  final Finder bouton = _cle('import-confirmer');
  await tester.ensureVisible(bouton);
  await tester.tap(bouton);
  await laisser(tester);
  // La feuille de confirmation : le dernier « Confirmer l'import ».
  await tester.tap(find.text(t.admin.importInscriptions.confirmer).last);
  await laisser(tester);
}

void main() {
  final a = t.admin.importInscriptions;

  group('portes', () {
    testWidgets('port absent : disponible au branchement serveur', (
      tester,
    ) async {
      await _monter(tester, null);
      expect(_cle('import-indisponible'), findsOneWidget);
      expect(find.text(a.indisponiblePhrase), findsOneWidget);
    });

    testWidgets('chargement des capacites', (tester) async {
      final _Port p = _Port()..retenue = Completer<CapacitesImport>();
      await _monter(tester, p);
      expect(find.byType(Skeleton), findsWidgets);
    });

    testWidgets('erreur de lecture : Reessayer', (tester) async {
      await _monter(tester, _Port()..echecCapacites = true);
      expect(_cle('import-erreur'), findsOneWidget);
      expect(find.text(a.erreur), findsOneWidget);
      expect(find.byType(EtatSysteme), findsOneWidget);
    });

    testWidgets('hors ligne sans rien de lu', (tester) async {
      await _monter(tester, _Port()..echecCapacites = true, horsLigne: true);
      expect(_cle('import-sans-donnees'), findsOneWidget);
    });

    testWidgets('direction sans double verification : on dit quoi faire', (
      tester,
    ) async {
      await _monter(
        tester,
        _Port(
          capacitesLues: const CapacitesImport(
            peutImporter: false,
            doubleVerificationRequise: true,
          ),
        ),
      );
      expect(_cle('import-double'), findsOneWidget);
      expect(find.text(a.acces.doublePhrase), findsOneWidget);
      expect(_cle('import-voir-apercu'), findsNothing);
    });

    testWidgets('sans capacite : acces refuse, rien du formulaire', (
      tester,
    ) async {
      await _monter(tester, _Port(capacitesLues: CapacitesImport.aucune));
      expect(_cle('import-refuse'), findsOneWidget);
      expect(_cle('import-champ-eleves'), findsNothing);
    });
  });

  group('deposer', () {
    testWidgets('rien de colle : une phrase dit quoi faire, rien ne part', (
      tester,
    ) async {
      final _Port p = _Port();
      await _monter(tester, p);
      await _voirApercu(tester);
      expect(find.text(a.manqueFichier), findsOneWidget);
      expect(_cle('import-apercu'), findsNothing);
      expect(p.apercus, isEmpty);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('choisir un fichier remplit le champ et dit son nom', (
      tester,
    ) async {
      await _monter(
        tester,
        _Port(),
        selecteur: _Selecteur(<CsvChoisi?>[
          const CsvChoisi(nom: 'eleves.csv', texte: _eleves),
        ]),
      );
      await tester.tap(_cle('import-choisir-eleves'));
      await laisser(tester);
      expect(find.text(a.fichierCharge(nom: 'eleves.csv')), findsOneWidget);
      expect(find.textContaining('mariama@exemple.test'), findsWidgets);
    });

    testWidgets('fichier illisible : une phrase, pas de plantage', (
      tester,
    ) async {
      await _monter(tester, _Port(), selecteur: _Echec());
      await tester.tap(_cle('import-choisir-enseignants'));
      await laisser(tester);
      expect(find.text(a.fichierIllisible), findsOneWidget);
    });
  });

  group('apercu', () {
    testWidgets('erreurs ligne par ligne, alertes et foyers', (tester) async {
      final _Port p = _Port();
      await _monter(tester, p);
      await _saisir(tester);
      await _voirApercu(tester);

      expect(_cle('import-apercu'), findsOneWidget);
      // Les refus, chacun avec sa ligne et son motif.
      String ligne(SourceImport s, int n, String motif) => a.ligne(
        fichier: s == SourceImport.eleves
            ? a.fichier.eleves
            : a.fichier.enseignants,
        ligne: n,
        motif: motif,
      );
      expect(
        find.text(ligne(SourceImport.eleves, 4, a.motif.emailInvalide)),
        findsOneWidget,
      );
      expect(
        find.text(ligne(SourceImport.eleves, 5, a.motif.ligneTest)),
        findsOneWidget,
      );
      expect(
        find.text(ligne(SourceImport.eleves, 6, a.motif.personneSansNom)),
        findsOneWidget,
      );
      // Un refus du serveur que l'analyse locale n'a pas vu est ajoute.
      expect(
        find.text(ligne(SourceImport.eleves, 7, a.motif.serveur)),
        findsOneWidget,
      );
      // L'alerte d'age : importee, a regarder.
      expect(
        find.text(ligne(SourceImport.eleves, 7, a.motif.ageTropJeune)),
        findsOneWidget,
      );
      // Les chiffres : trois foyers lus localement + l'enseignant.
      expect(find.text(a.serveur.titre), findsOneWidget);
      expect(find.text(a.serveur.foyers), findsOneWidget);
      // Le serveur a recu du CSV a virgules, avec les deux fichiers.
      expect(p.apercus, hasLength(1));
      expect(p.apercus.single.$1, startsWith('Horodateur,'));
      expect(p.apercus.single.$2, startsWith('Horodateur,Prénom,Nom,Email'));
      // Rien n'est ecrit : aucune confirmation.
      expect(p.confirmations, isEmpty);
      // Un seul bouton plein : la confirmation.
      expect(_cle('import-confirmer'), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('aucune ligne importable : etat vide, pas de confirmation', (
      tester,
    ) async {
      final _Port p = _Port();
      await _monter(tester, p);
      await _saisir(
        tester,
        eleves:
            '$_entete\n01/10/2026,Mon enfant,pas-une-adresse,A,B,C,D,,,,,\n',
        enseignants: '',
      );
      await _voirApercu(tester);
      expect(find.byType(EmptyState), findsOneWidget);
      expect(_cle('import-vide'), findsOneWidget);
      expect(_cle('import-confirmer'), findsNothing);
      // Le serveur n'a rien a essayer.
      expect(p.apercus, isEmpty);
      // Revenir modifier les fichiers.
      await tester.tap(find.text(a.apercu.modifier));
      await laisser(tester);
      expect(_cle('import-saisie'), findsOneWidget);
    });

    testWidgets('en-tete sans Email : fichier bloque, rien ne part', (
      tester,
    ) async {
      final _Port p = _Port();
      await _monter(tester, p);
      await _saisir(
        tester,
        eleves: 'Nom,Prénom\nDiallo,Aminata\n',
        enseignants: '',
      );
      await _voirApercu(tester);
      expect(find.textContaining(a.motif.enteteEmailAbsent), findsOneWidget);
      expect(p.apercus, isEmpty);
      expect(_cle('import-confirmer'), findsNothing);
    });

    testWidgets('hors ligne : apercu local lisible, confirmation non offerte', (
      tester,
    ) async {
      final _Port p = _Port();
      await _monter(tester, p, horsLigne: true);
      await _saisir(tester);
      await _voirApercu(tester);
      expect(_cle('import-apercu'), findsOneWidget);
      expect(
        find.text(
          a.ligne(
            fichier: a.fichier.eleves,
            ligne: 4,
            motif: a.motif.emailInvalide,
          ),
        ),
        findsOneWidget,
      );
      expect(_cle('import-serveur-indisponible'), findsOneWidget);
      expect(find.text(a.horsLigne), findsOneWidget);
      expect(_cle('import-confirmer'), findsNothing);
      expect(p.apercus, isEmpty);
    });

    testWidgets('essai a blanc du serveur en echec : pas de confirmation', (
      tester,
    ) async {
      final _Port p = _Port()..echecApercu = true;
      await _monter(tester, p);
      await _saisir(tester);
      await _voirApercu(tester);
      expect(_cle('import-serveur-indisponible'), findsOneWidget);
      expect(find.text(a.serveur.indisponible), findsOneWidget);
      expect(_cle('import-confirmer'), findsNothing);
      // L'apercu local reste la.
      expect(find.text(a.apercu.refusees), findsWidgets);
    });

    testWidgets('un fichier a point-virgule repart en virgules', (
      tester,
    ) async {
      final _Port p = _Port();
      await _monter(tester, p);
      await _saisir(
        tester,
        eleves:
            'Pour qui faites-vous cette inscription ?;Email;Nom;Prénom\n'
            'Pour moi;adulte@exemple.test;"Haddad, fils";Karim\n',
        enseignants: '',
      );
      await _voirApercu(tester);
      expect(p.apercus.single.$1, contains(',adulte@exemple.test,'));
      expect(p.apercus.single.$1, isNot(contains(';')));
      expect(p.apercus.single.$1, contains('"Haddad, fils"'));
      // Pas de fichier enseignants : un en-tete, comme le serveur l'exige.
      expect(p.apercus.single.$2, 'Prénom,Nom,Email\r\n');
    });
  });

  group('mots d\'accueil et envoi', () {
    testWidgets('mot commun, case a patiente, mot d\'un foyer, puis envoi', (
      tester,
    ) async {
      final _Port p = _Port();
      await _monter(tester, p);
      await _saisir(tester);
      await _voirApercu(tester);

      // Un mot pour tout le lot.
      await tester.ensureVisible(_cle('import-mot-lot'));
      await tester.enterText(_cle('import-mot-lot'), 'Bienvenue chez vous.');
      // Les familles ont toutes patiente, sauf Karim.
      await tester.ensureVisible(_cle('import-patiente-lot'));
      await tester.tap(_cle('import-patiente-lot'));
      await laisser(tester, fois: 2);
      await tester.ensureVisible(_cle('import-patiente-karim@exemple.test'));
      await tester.tap(_cle('import-patiente-karim@exemple.test'));
      await laisser(tester, fois: 2);
      // Un mot personnel pour Mariama.
      await tester.ensureVisible(_cle('import-retoucher-mariama@exemple.test'));
      await tester.tap(_cle('import-retoucher-mariama@exemple.test'));
      await laisser(tester, fois: 2);
      await tester.ensureVisible(_cle('import-mot-mariama@exemple.test'));
      await tester.enterText(
        _cle('import-mot-mariama@exemple.test'),
        'Mariama, merci d\'avoir attendu.',
      );
      await laisser(tester, fois: 2);

      await _confirmer(tester);

      expect(p.confirmations, hasLength(1));
      final List<OptionFoyer> options = p.confirmations.single.$3;
      OptionFoyer de(String email) =>
          options.firstWhere((OptionFoyer o) => o.email == email);
      expect(
        de('mariama@exemple.test').motAccueil,
        'Mariama, merci d\'avoir attendu.',
      );
      expect(de('mariama@exemple.test').aPatiente, isTrue);
      expect(de('karim@exemple.test').motAccueil, 'Bienvenue chez vous.');
      expect(de('karim@exemple.test').aPatiente, isFalse);
      expect(de('ibrahim@exemple.test').motAccueil, 'Bienvenue chez vous.');
      expect(de('ibrahim@exemple.test').aPatiente, isTrue);
      // Les lignes refusees ne donnent aucun foyer.
      expect(
        options.map((OptionFoyer o) => o.email),
        isNot(contains('vide@exemple.test')),
      );
    });

    testWidgets('sans reglage : les options sont neutres, le serveur choisit', (
      tester,
    ) async {
      final _Port p = _Port();
      await _monter(tester, p);
      await _saisir(tester);
      await _voirApercu(tester);
      await _confirmer(tester);
      expect(
        p.confirmations.single.$3.every((OptionFoyer o) => o.neutre),
        isTrue,
      );
    });

    testWidgets('renoncer a la confirmation : rien ne part', (tester) async {
      final _Port p = _Port();
      await _monter(tester, p);
      await _saisir(tester);
      await _voirApercu(tester);
      final Finder bouton = _cle('import-confirmer');
      await tester.ensureVisible(bouton);
      await tester.tap(bouton);
      await laisser(tester);
      expect(find.text(a.confirmation.consequence), findsOneWidget);
      await tester.tap(find.text(t.commun.annuler).last);
      await laisser(tester);
      expect(p.confirmations, isEmpty);
      expect(_cle('import-resultat'), findsNothing);
    });

    testWidgets('resultat : crees, deja presents, refuses, invitations', (
      tester,
    ) async {
      final _Port p = _Port();
      await _monter(tester, p);
      await _saisir(tester);
      await _voirApercu(tester);
      await _confirmer(tester);

      expect(_cle('import-resultat'), findsOneWidget);
      expect(find.text(a.resultat.titre), findsOneWidget);
      expect(find.text(a.resultat.personnesCreees), findsOneWidget);
      expect(find.text(a.resultat.personnesPresentes), findsOneWidget);
      expect(find.text(a.resultat.invitations), findsOneWidget);
      expect(find.text(a.resultat.invitationsAide), findsOneWidget);
      // Les lignes refusees gardent leur motif.
      expect(
        find.text(
          a.ligne(
            fichier: a.fichier.eleves,
            ligne: 4,
            motif: a.motif.emailInvalide,
          ),
        ),
        findsOneWidget,
      );
      expect(_cle('import-rien-de-nouveau'), findsNothing);
      // Plus de bouton plein : on peut recommencer.
      verifierUnSeulBoutonPlein(tester);
      await tester.tap(_cle('import-recommencer'));
      await laisser(tester);
      expect(_cle('import-saisie'), findsOneWidget);
    });

    testWidgets('rejeu : tout etait deja importe', (tester) async {
      final _Port p = _Port()
        ..resultat = const ResultatImport(
          foyersTraites: 3,
          foyersCrees: 0,
          personnesCreees: 0,
          personnesDejaImportees: 7,
        );
      await _monter(tester, p);
      await _saisir(tester);
      await _voirApercu(tester);
      await _confirmer(tester);
      expect(_cle('import-rien-de-nouveau'), findsOneWidget);
    });

    testWidgets('coupure : non confirme, la meme demande se rejoue', (
      tester,
    ) async {
      final _Port p = _Port(coupures: 1);
      await _monter(tester, p);
      await _saisir(tester);
      await _voirApercu(tester);
      await _confirmer(tester);
      expect(_cle('import-echec'), findsOneWidget);
      expect(find.text(a.echec.horsLigne), findsOneWidget);
      expect(_cle('import-resultat'), findsNothing);
      // Nouvelle tentative : les memes fichiers repartent.
      await _confirmer(tester);
      expect(p.confirmations, hasLength(2));
      expect(p.confirmations[0].$1, p.confirmations[1].$1);
      expect(_cle('import-resultat'), findsOneWidget);
    });
  });

  group('gabarits', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection d in TextDirection.values) {
      testWidgets('320 px, texte x2, ${d.name} : deposer, apercu, resultat', (
        tester,
      ) async {
        final _Port p = _Port();
        await _monter(tester, p, largeur: 320, echelle: 2, direction: d);
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
        verifierUnSeulBoutonPlein(tester);

        await _saisir(tester);
        await _voirApercu(tester);
        expect(_cle('import-apercu'), findsOneWidget);
        await tester.ensureVisible(
          _cle('import-retoucher-mariama@exemple.test'),
        );
        await tester.tap(_cle('import-retoucher-mariama@exemple.test'));
        await laisser(tester);
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
        verifierUnSeulBoutonPlein(tester);

        await _confirmer(tester);
        expect(_cle('import-resultat'), findsOneWidget);
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
        verifierUnSeulBoutonPlein(tester);
      });
    }
  });
}

class _Echec implements SelecteurCsv {
  @override
  Future<CsvChoisi?> choisir() =>
      Future<CsvChoisi?>.error(const FormatException('illisible'));
}
