// ADM-23 : l'ecran « Importer les formulaires de candidature ».
//
// Ce que le test prouve, pas par pas : les cinq etats (chargement, contenu,
// vide, erreur, hors ligne), la capacite indisponible, l'acces refuse et la
// double verification traduite en mots et en action ; les huit pas dans l'ordre
// de la fiche ; **0 courriel, 0 telephone et 0 nom rendus aux pas 2 a 8**, cles
// de doublon comprises ; un seul bouton plein par pas ; le fichier illisible
// (ligne et cause), les colonnes a associer, les doublons a choisir, l'ecart
// des comptes, le jeton perime ; que rien n'est dit importe avant la reponse du
// serveur, qu'une reponse perdue se rejoue avec la meme cle ; la liste des pas
// selon la largeur ; 320 px et texte x2, gauche a droite et droite a gauche.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/candidature/modeles_import_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_import_candidatures.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/composants_import.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/controleur_import.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/import_formulaires_page.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/libelles_import.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/pas_apercu.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/pas_colonnes.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/pas_comptes.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/pas_confirmation.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/pas_depot.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/pas_doublons.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/pas_rapport.dart';
import 'package:rewayah_academy/features/admin_import_inscriptions/selecteur_csv.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/candidature/faux_import_candidatures.dart';
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart' show FauxServiceAuth;
import '../../support/monter_recrutement.dart';

const String _chemin = '/admin/personnes/candidatures/import';
const String _nomFichier = 'Formulaire enseignants - Réponses.csv';

class _Selecteur implements SelecteurCsv {
  _Selecteur(this.texte, {this.nom = _nomFichier});

  String texte;
  String nom;
  int ouvertures = 0;

  @override
  Future<CsvChoisi?> choisir() async {
    ouvertures++;
    return CsvChoisi(nom: nom, texte: texte);
  }
}

class _SelecteurEnEchec implements SelecteurCsv {
  @override
  Future<CsvChoisi?> choisir() =>
      Future<CsvChoisi?>.error(const FormatException('illisible'));
}

Future<void> _monter(
  WidgetTester tester,
  PortImportCandidatures? port, {
  SelecteurCsv? selecteur,
  FauxServiceAuth? auth,
  bool horsLigne = false,
  double largeur = 390,
  double hauteur = 3000,
  double echelle = 1,
  TextDirection? direction,
  Stream<bool>? reseau,
}) => monterRecrutement(
  tester,
  chemin: _chemin,
  ecran: (_) => reseau == null
      ? const ImportFormulairesPage()
      // Le reseau qui change en route : une etendue qui lui est propre (le
      // hote commun ne le fixe qu'une fois).
      : ProviderScope(
          overrides: <Override>[
            horsLigneProvider.overrideWith((Ref _) => reseau),
          ],
          child: const ImportFormulairesPage(),
        ),
  autres: <String>['/admin/personnes/candidatures'],
  surcharges: <Override>[
    if (port != null) portImportCandidaturesProvider.overrideWithValue(port),
    selecteurCsvProvider.overrideWithValue(
      selecteur ?? _Selecteur(csvFormulaires),
    ),
    serviceAuthProvider.overrideWithValue(auth ?? FauxServiceAuth()),
  ],
  horsLigne: horsLigne,
  largeur: largeur,
  hauteur: hauteur,
  echelle: echelle,
  direction: direction,
);

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await laisser(tester);
}

/// Un lien pose au bord de debut : la cible est le lien, pas toute la ligne.
Future<void> _toucherLien(WidgetTester tester, Key cle) => _toucher(
  tester,
  find.descendant(of: find.byKey(cle), matching: find.byType(LienFleche)),
);

Future<void> _suivant(WidgetTester tester) =>
    _toucher(tester, find.byKey(ActionsDuPas.actionKey));

Future<void> _retour(WidgetTester tester) =>
    _toucher(tester, find.byKey(ActionsDuPas.retourKey));

Future<void> _choisirFichier(WidgetTester tester) =>
    _toucher(tester, find.byKey(PasDepot.carteFichierKey));

Future<void> _jusqua(WidgetTester tester, PasImport pas) async {
  await _choisirFichier(tester);
  if (pas == PasImport.depot) return;
  await _suivant(tester);
  if (pas == PasImport.apercu) return;
  await _suivant(tester);
  if (pas == PasImport.colonnes) return;
  await _suivant(tester);
  if (pas == PasImport.doublons) return;
  await _suivant(tester);
  if (pas == PasImport.erreurs) return;
  await _suivant(tester);
  if (pas == PasImport.comptes) return;
  await _toucher(tester, _cle('import-attendu-aucun'));
  await _suivant(tester);
  if (pas == PasImport.confirmation) return;
  await _suivant(tester);
}

/// L'arabe est une bibliotheque differee : elle se charge hors de l'horloge
/// simulee du test.
Future<void> _enArabe(WidgetTester tester) async {
  await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
}

/// Du pas des doublons a la confirmation : erreurs, comptes (sans decompte a
/// comparer), puis la confirmation.
Future<void> _deLaListeDesDoublons(WidgetTester tester) async {
  await _suivant(tester);
  await _suivant(tester);
  await _toucher(tester, _cle('import-attendu-aucun'));
  await _suivant(tester);
}

/// Les textes rendus (Text et saisies) a l'ecran.
Iterable<String> _textes(WidgetTester tester) sync* {
  for (final Element e in find.byType(Text).evaluate()) {
    final Text t = e.widget as Text;
    yield t.data ?? t.textSpan?.toPlainText() ?? '';
  }
  for (final Element e in find.byType(EditableText).evaluate()) {
    yield (e.widget as EditableText).controller.text;
  }
}

/// 0 courriel, 0 telephone, 0 nom de personne : ni en clair, ni comme valeur
/// d'une cle de doublon (fiche ADM-23, controles d'acceptation).
void _aucuneDonneePersonnelle(WidgetTester tester) {
  final List<String> fautes = <String>[
    for (final String s in _textes(tester))
      if (s.contains('@') ||
          s.contains('test.invalid') ||
          s.contains('+0000') ||
          s.contains('0600000003') ||
          s.contains('Personne Test'))
        s,
  ];
  expect(fautes, isEmpty, reason: 'donnee personnelle rendue : $fautes');
}

void _gardes(WidgetTester tester) {
  expect(tester.takeException(), isNull);
  verifierUnSeulBoutonPlein(tester);
  _aucuneDonneePersonnelle(tester);
}

void main() {
  final a = t.admin.importFormulaires;

  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('portes', () {
    testWidgets('port absent : disponible au branchement serveur', (
      tester,
    ) async {
      await _monter(tester, null);
      expect(_cle('import-indisponible'), findsOneWidget);
      expect(find.text(t.commun.etats.branchementServeur), findsOneWidget);
      expect(find.byKey(PasDepot.carteFichierKey), findsNothing);
      verifierUnSeulBoutonPlein(tester, maximum: 0);
    });

    testWidgets('capacite indisponible rendue par le port : meme etat', (
      tester,
    ) async {
      await _monter(
        tester,
        FauxImportCandidatures()
          ..erreurCapacites = const CapaciteIndisponible('CAND-BR-09'),
      );
      expect(_cle('import-indisponible'), findsOneWidget);
      // Le code ne se montre jamais.
      expect(find.textContaining('CAND-BR'), findsNothing);
    });

    testWidgets('chargement : un squelette, puis le parcours', (tester) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..capacitesRetenues = Completer<CapacitesImportCandidatures>();
      await _monter(tester, port);
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byKey(PasDepot.carteFichierKey), findsNothing);
      port.capacitesRetenues!.complete(
        const CapacitesImportCandidatures(peutImporter: true),
      );
      await laisser(tester);
      expect(find.byKey(PasDepot.carteFichierKey), findsOneWidget);
    });

    testWidgets('erreur de lecture : « Reessayer » relit les droits', (
      tester,
    ) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..erreurCapacites = StateError('muet');
      await _monter(tester, port);
      expect(_cle('import-lecture-echec'), findsOneWidget);
      expect(find.text(a.lectureDroits), findsOneWidget);
      port.erreurCapacites = null;
      await tester.tap(find.text(t.commun.reessayer).first);
      await laisser(tester);
      expect(find.byKey(PasDepot.carteFichierKey), findsOneWidget);
    });

    testWidgets('hors ligne sans rien a montrer : dit ce qui manque', (
      tester,
    ) async {
      await _monter(
        tester,
        FauxImportCandidatures()..erreurCapacites = StateError('muet'),
        horsLigne: true,
      );
      expect(_cle('import-sans-donnees'), findsOneWidget);
    });

    testWidgets('double verification : en mots, et en action', (tester) async {
      final FauxServiceAuth auth = FauxServiceAuth();
      await _monter(
        tester,
        FauxImportCandidatures(
          capacitesRendues: const CapacitesImportCandidatures(
            doubleVerificationRequise: true,
          ),
        ),
        auth: auth,
      );
      expect(_cle('import-double'), findsOneWidget);
      expect(
        find.text(t.admin.importInscriptions.acces.doubleTitre),
        findsOneWidget,
      );
      expect(
        find.textContaining(a.acces.doublePhrase),
        findsOneWidget,
        reason: 'le texte de la fiche, puis ce que le bouton fait',
      );
      expect(find.textContaining(a.acces.doubleSuite), findsOneWidget);
      expect(find.byKey(PasDepot.carteFichierKey), findsNothing);
      await tester.tap(find.text(a.acces.doubleAction));
      await laisser(tester);
      expect(auth.deconnexions, 1);
    });

    testWidgets('ni droit ni double verification : acces refuse', (
      tester,
    ) async {
      await _monter(
        tester,
        FauxImportCandidatures(
          capacitesRendues: CapacitesImportCandidatures.aucune,
        ),
      );
      expect(_cle('import-refuse'), findsOneWidget);
      expect(find.text(a.acces.refuseTitre), findsOneWidget);
      expect(find.byKey(PasDepot.carteFichierKey), findsNothing);
    });

    testWidgets('une permission refusee a la lecture : acces refuse', (
      tester,
    ) async {
      await _monter(
        tester,
        FauxImportCandidatures()
          ..erreurCapacites = const PermissionInsuffisante('x'),
      );
      expect(_cle('import-refuse'), findsOneWidget);
    });
  });

  group('pas 1 : deposer le fichier', () {
    testWidgets('au debut : une carte a toucher, aucun bouton, une phrase', (
      tester,
    ) async {
      await _monter(tester, FauxImportCandidatures());
      expect(find.text(a.depot.question), findsOneWidget);
      expect(find.text(a.depot.carteTitre), findsOneWidget);
      expect(find.byKey(ActionsDuPas.actionKey), findsNothing);
      expect(find.text(a.depot.manqueFichier), findsOneWidget);
      // Aucun champ a remplir : le fichier se choisit, il ne se tape pas.
      expect(find.byType(EditableText), findsNothing);
      _gardes(tester);
    });

    testWidgets('sur telephone, la phrase qui rassure suit la carte', (
      tester,
    ) async {
      await _monter(tester, FauxImportCandidatures());
      expect(find.text(a.intro), findsOneWidget);
    });

    testWidgets(
      'un fichier choisi : ses noms se deduisent, « Analyser » apparait',
      (tester) async {
        final _Selecteur selecteur = _Selecteur(csvFormulaires);
        await _monter(tester, FauxImportCandidatures(), selecteur: selecteur);
        await _choisirFichier(tester);
        expect(selecteur.ouvertures, 1);
        expect(
          find.text(a.depot.carteChoisi(nom: _nomFichier)),
          findsOneWidget,
        );
        expect(find.text(a.depot.lignesLues(n: 7)), findsOneWidget);
        expect(
          find.text(
            a.depot.noms.ligne(
              classeur: 'Formulaire enseignants',
              onglet: 'Réponses',
            ),
          ),
          findsOneWidget,
        );
        expect(find.text(a.depot.analyser), findsOneWidget);
        expect(find.text(a.depot.manqueFichier), findsNothing);
        _gardes(tester);
      },
    );

    testWidgets('un nom sans onglet : le champ s\'ouvre, le bouton attend', (
      tester,
    ) async {
      final FauxImportCandidatures port = FauxImportCandidatures();
      await _monter(
        tester,
        port,
        selecteur: _Selecteur(csvFormulaires, nom: 'export.csv'),
      );
      await _choisirFichier(tester);
      expect(find.byKey(PasDepot.champOngletKey), findsNothing);
      expect(find.byKey(ActionsDuPas.actionKey), findsNothing);
      expect(find.text(a.depot.noms.ongletManquant), findsOneWidget);
      expect(find.byType(EditableText), findsNWidgets(2));
      await tester.enterText(
        find
            .descendant(
              of: find.byType(AppCard),
              matching: find.byType(EditableText),
            )
            .last,
        'Réponses',
      );
      await laisser(tester);
      expect(find.byKey(ActionsDuPas.actionKey), findsOneWidget);
      await _suivant(tester);
      expect(port.apercus.single.classeur, 'export');
      expect(port.apercus.single.onglet, 'Réponses');
    });

    testWidgets('corriger les noms : ce qui est tape part au serveur', (
      tester,
    ) async {
      final FauxImportCandidatures port = FauxImportCandidatures();
      await _monter(tester, port);
      await _choisirFichier(tester);
      await _toucherLien(tester, PasDepot.corrigerNomsKey);
      expect(find.byType(EditableText), findsNWidgets(2));
      await tester.enterText(
        find.byType(EditableText).first,
        'Classeur corrige',
      );
      await laisser(tester);
      expect(
        find.text(
          a.depot.noms.ligne(classeur: 'Classeur corrige', onglet: 'Réponses'),
        ),
        findsOneWidget,
      );
      await _suivant(tester);
      expect(port.apercus.single.classeur, 'Classeur corrige');
    });

    testWidgets('un nom invalide : une phrase, pas de bouton', (tester) async {
      await _monter(tester, FauxImportCandidatures());
      await _choisirFichier(tester);
      await _toucherLien(tester, PasDepot.corrigerNomsKey);
      await tester.enterText(find.byType(EditableText).last, 'a|b');
      await laisser(tester);
      expect(find.text(a.depot.noms.invalide), findsOneWidget);
      expect(find.byKey(ActionsDuPas.actionKey), findsNothing);
    });

    testWidgets('le selecteur qui echoue : fichier illisible, quoi faire', (
      tester,
    ) async {
      await _monter(
        tester,
        FauxImportCandidatures(),
        selecteur: _SelecteurEnEchec(),
      );
      await _choisirFichier(tester);
      expect(_cle('import-selection-echec'), findsOneWidget);
      expect(find.textContaining(a.fichier.quoiFaire), findsOneWidget);
    });

    testWidgets('un guillemet jamais referme : la ligne et la cause', (
      tester,
    ) async {
      final FauxImportCandidatures port = FauxImportCandidatures();
      await _monter(tester, port, selecteur: _Selecteur('A,B\n1,"2\n3,4\n'));
      await _choisirFichier(tester);
      expect(_cle('import-fichier-illisible'), findsOneWidget);
      expect(
        find.textContaining(
          a.fichier.illisibleLigne(
            ligne: 2,
            cause: a.fichier.cause.guillemetNonFerme,
          ),
        ),
        findsOneWidget,
      );
      expect(find.textContaining(a.fichier.quoiFaire), findsOneWidget);
      expect(find.byKey(ActionsDuPas.actionKey), findsNothing);
      expect(port.apercus, isEmpty);
      // Un fichier illisible n'a pas de nombre de lignes a dire.
      expect(find.textContaining(a.depot.lignesLues(n: 0)), findsNothing);
      expect(find.text(a.depot.lignesLues(n: 0)), findsNothing);
    });

    testWidgets('un fichier sans ligne : « aucune ligne a importer »', (
      tester,
    ) async {
      final FauxImportCandidatures port = FauxImportCandidatures();
      await _monter(tester, port, selecteur: _Selecteur('Horodateur,Nom\n'));
      await _choisirFichier(tester);
      expect(_cle('import-vide'), findsOneWidget);
      expect(find.text(a.depot.vide), findsOneWidget);
      expect(find.byKey(ActionsDuPas.actionKey), findsNothing);
      expect(port.apercus, isEmpty);
    });

    testWidgets(
      'hors ligne : l\'analyse n\'est pas offerte, une phrase le dit',
      (tester) async {
        final FauxImportCandidatures port = FauxImportCandidatures();
        await _monter(tester, port, horsLigne: true);
        await _choisirFichier(tester);
        expect(find.byKey(ActionsDuPas.actionKey), findsNothing);
        expect(find.text(a.depot.horsLigne), findsOneWidget);
        expect(port.apercus, isEmpty);
      },
    );

    testWidgets('l\'analyse : un squelette, et rien n\'est encore enregistre', (
      tester,
    ) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..apercuRetenu = Completer<ApercuImport>();
      await _monter(tester, port);
      await _choisirFichier(tester);
      await _suivant(tester);
      expect(_cle('import-analyse'), findsOneWidget);
      expect(find.text(a.depot.analyseEnCours), findsOneWidget);
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byKey(ActionsDuPas.actionKey), findsNothing);
      port.apercuRetenu!.complete(apercuTest());
      await laisser(tester);
      expect(find.text(a.apercu.question), findsOneWidget);
    });

    testWidgets(
      'une analyse qui echoue : « L\'analyse n\'a pas abouti. » et reessayer',
      (tester) async {
        final FauxImportCandidatures port = FauxImportCandidatures()
          ..erreurApercu = (int n) => n == 1 ? StateError('muet') : null;
        await _monter(tester, port);
        await _choisirFichier(tester);
        await _suivant(tester);
        expect(_cle('import-analyse-echec'), findsOneWidget);
        expect(find.text(a.analyse.echec), findsOneWidget);
        expect(find.text(a.analyse.echecPhrase), findsOneWidget);
        await tester.tap(find.text(a.analyse.reessayer));
        await laisser(tester);
        expect(port.apercus.length, 2);
        expect(find.text(a.apercu.question), findsOneWidget);
      },
    );

    testWidgets(
      'le serveur refuse les arguments : une phrase qui dit quoi verifier',
      (tester) async {
        final FauxImportCandidatures port = FauxImportCandidatures()
          ..erreurApercu = (int n) => const ImportInvalide('x');
        await _monter(tester, port);
        await _choisirFichier(tester);
        await _suivant(tester);
        expect(find.text(a.analyse.refus), findsOneWidget);
      },
    );

    testWidgets('un fichier que le serveur dit illisible : la cause en mots', (
      tester,
    ) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..erreurApercu = (int n) =>
            const FichierIllisible('CSV mal formé après un guillemet fermant');
      await _monter(tester, port);
      await _choisirFichier(tester);
      await _suivant(tester);
      expect(_cle('import-fichier-illisible'), findsOneWidget);
      expect(
        find.textContaining(
          a.fichier.illisible(cause: a.fichier.cause.malForme),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('guillemet fermant'),
        findsNothing,
        reason: 'le message du serveur ne s\'affiche pas tel quel',
      );
    });

    testWidgets('un refus du serveur pour tout l\'import remplace le pas', (
      tester,
    ) async {
      for (final (Object erreur, String cle) in <(Object, String)>[
        (const DoubleVerificationRequise(), 'import-double'),
        (const PermissionInsuffisante('x'), 'import-refuse'),
        (const CapaciteIndisponible('CAND-BR-09'), 'import-indisponible'),
      ]) {
        final FauxImportCandidatures port = FauxImportCandidatures()
          ..erreurApercu = (int n) => erreur;
        await _monter(tester, port);
        await _choisirFichier(tester);
        await _suivant(tester);
        expect(_cle(cle), findsOneWidget, reason: '$erreur');
        expect(find.byKey(PasDepot.carteFichierKey), findsNothing);
        expect(find.textContaining('CAND-BR'), findsNothing);
      }
    });
  });

  group('pas 2 : apercu', () {
    testWidgets(
      'lignes lues, colonnes reconnues, premieres lignes, contacts masques',
      (tester) async {
        await _monter(tester, FauxImportCandidatures());
        await _jusqua(tester, PasImport.apercu);
        expect(find.text(a.apercu.question), findsOneWidget);
        expect(_cle('import-apercu-lignes'), findsOneWidget);
        expect(find.text(a.apercu.lignes(n: 7)), findsOneWidget);
        expect(
          find.text(a.apercu.colonnesReconnues(reconnues: '14', total: '14')),
          findsOneWidget,
        );
        expect(find.text(a.apercu.contactsMasques), findsOneWidget);
        expect(find.text(a.apercu.ligne(ligne: 2)), findsOneWidget);
        expect(find.text(a.apercu.marque.courrielAObtenir), findsOneWidget);
        expect(_cle('import-apercu-aide-marques'), findsOneWidget);
        expect(find.text(a.apercu.marque.indicatifAConfirmer), findsOneWidget);
        expect(find.text(a.apercu.autres(n: 2)), findsOneWidget);
        expect(find.text(t.commun.continuer), findsOneWidget);
        _gardes(tester);
      },
    );

    testWidgets(
      'des colonnes a associer : l\'apercu le dit et mene aux colonnes',
      (tester) async {
        final FauxImportCandidatures port = FauxImportCandidatures()
          ..erreurApercu = (int n) => n == 1
              ? MappageIncomplet(
                  champs: const <ChampManquant>[
                    ChampManquant.nom,
                    ChampManquant.contact,
                  ],
                  colonnes: colonnesTest(
                    sauf: <ChampFormulaire>{ChampFormulaire.nom},
                  ),
                )
              : null;
        await _monter(tester, port);
        await _jusqua(tester, PasImport.apercu);
        expect(_cle('import-apercu-manquants'), findsOneWidget);
        expect(
          find.text(
            a.apercu.mappageIncomplet(
              champs: '${a.champ.nom}, ${a.champ.contact}',
            ),
          ),
          findsOneWidget,
        );
        expect(_cle('import-apercu-sans-lignes'), findsOneWidget);
        expect(find.byKey(PasApercu.premieresKey), findsNothing);
        _gardes(tester);
      },
    );
  });

  group('pas 3 : colonnes', () {
    testWidgets('une ligne par colonne, avec le titre du fichier tel quel', (
      tester,
    ) async {
      await _monter(tester, FauxImportCandidatures());
      await _jusqua(tester, PasImport.colonnes);
      expect(find.text(a.colonnes.question), findsOneWidget);
      expect(find.byKey(PasColonnes.listeKey), findsOneWidget);
      for (int n = 1; n <= 14; n++) {
        expect(_cle('import-colonne-$n'), findsOneWidget);
      }
      expect(
        find.text(a.colonnes.titreColonne(n: 1, titre: 'Horodateur')),
        findsOneWidget,
      );
      expect(
        find.text(a.colonnes.titreColonne(n: 3, titre: 'الاسم الكامل')),
        findsOneWidget,
      );
      expect(find.text(a.champ.nom), findsOneWidget);
      // La table des libelles est celle du serveur : l'ecran le dit.
      expect(find.text(a.colonnes.libelles.texte), findsOneWidget);
      expect(find.text(t.commun.continuer), findsOneWidget);
      expect(find.text(a.colonnes.relecture), findsNothing);
      _gardes(tester);
    });

    testWidgets(
      'toucher une colonne ouvre sa question, en lignes, sans fenetre',
      (tester) async {
        await _monter(tester, FauxImportCandidatures());
        await _jusqua(tester, PasImport.colonnes);
        await _toucher(tester, _cle('import-colonne-4'));
        expect(find.byKey(PasColonnes.choixKey), findsOneWidget);
        expect(find.byKey(PasColonnes.listeKey), findsNothing);
        expect(find.text(a.colonnes.choisir(n: 4)), findsOneWidget);
        // Quatorze champs et « Ne pas lire cette colonne » : quinze lignes, dont
        // une seule porte « Choix actuel ».
        expect(find.text(a.colonnes.choixActuel), findsOneWidget);
        for (final ChampFormulaire champ in ChampFormulaire.values) {
          expect(_cle('import-champ-${champ.code}'), findsOneWidget);
        }
        expect(_cle('import-champ-aucun'), findsOneWidget);
        // Un champ lu ailleurs le dit, avec sa consequence.
        expect(
          find.textContaining(a.colonnes.dejaAssocie(n: 3)),
          findsOneWidget,
          reason: 'le nom est lu dans la colonne 3',
        );
        // Pas de bouton plein : le choix s'applique en touchant la carte.
        expect(find.byKey(ActionsDuPas.actionKey), findsNothing);
        expect(find.byType(Dialog), findsNothing);
        expect(find.byType(EditableText), findsNothing);
        _gardes(tester);
      },
    );

    testWidgets('« Ne pas lire cette colonne » : relecture avant de continuer', (
      tester,
    ) async {
      final FauxImportCandidatures port = FauxImportCandidatures();
      await _monter(tester, port);
      await _jusqua(tester, PasImport.colonnes);
      await _toucher(tester, _cle('import-colonne-5'));
      await _toucher(tester, _cle('import-champ-aucun'));
      expect(find.byKey(PasColonnes.choixKey), findsNothing);
      expect(find.text(a.colonnes.nonLue), findsOneWidget);
      expect(find.text(a.champ.langueMaternelle), findsNothing);
      // Une association corrigee demande une nouvelle lecture avant d'avancer.
      expect(find.text(a.colonnes.relecture), findsOneWidget);
      await _suivant(tester);
      expect(port.apercus.length, 2);
      expect(port.apercus.last.mappage.versJson(), <String, String?>{
        '5': null,
      });
      expect(find.text(a.doublons.question), findsOneWidget);
    });

    testWidgets(
      'colonnes a associer : le bouton attend, les champs sont nommes',
      (tester) async {
        final FauxImportCandidatures port = FauxImportCandidatures()
          ..erreurApercu = (int n) => n == 1
              ? MappageIncomplet(
                  champs: const <ChampManquant>[ChampManquant.nom],
                  colonnes: colonnesTest(
                    sauf: <ChampFormulaire>{ChampFormulaire.nom},
                  ),
                )
              : null;
        await _monter(tester, port);
        await _jusqua(tester, PasImport.apercu);
        await _suivant(tester);
        expect(find.byKey(PasColonnes.listeKey), findsOneWidget);
        expect(_cle('import-colonnes-attention'), findsOneWidget);
        expect(
          find.text(a.colonnes.manquants(champs: a.champ.nom)),
          findsOneWidget,
        );
        expect(find.byKey(ActionsDuPas.actionKey), findsNothing);
        // La direction dit que la colonne 3 contient le nom.
        await _toucher(tester, _cle('import-colonne-3'));
        await _toucher(tester, _cle('import-champ-nom'));
        expect(_cle('import-colonnes-attention'), findsNothing);
        expect(find.byKey(ActionsDuPas.actionKey), findsOneWidget);
        await _suivant(tester);
        expect(port.apercus.length, 2);
        expect(port.apercus.last.mappage.versJson(), <String, String?>{
          '3': 'nom',
        });
        expect(find.text(a.doublons.question), findsOneWidget);
        _gardes(tester);
      },
    );

    testWidgets('deux colonnes pour un champ : rien n\'avance avant un choix', (
      tester,
    ) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..erreurApercu = (int n) => n == 1
            ? EntetesAmbigus(
                champs: const <ChampFormulaire>[ChampFormulaire.nom],
                colonnes: colonnesTest(),
              )
            : null;
      await _monter(tester, port);
      await _jusqua(tester, PasImport.apercu);
      expect(_cle('import-apercu-ambigu'), findsOneWidget);
      await _suivant(tester);
      expect(find.text(a.colonnes.ambigu(champs: a.champ.nom)), findsOneWidget);
      expect(find.byKey(ActionsDuPas.actionKey), findsNothing);
      await _toucher(tester, _cle('import-colonne-3'));
      await _toucher(tester, _cle('import-champ-nom'));
      expect(find.byKey(ActionsDuPas.actionKey), findsOneWidget);
    });

    testWidgets('le retour de la question d\'une colonne revient a la liste', (
      tester,
    ) async {
      await _monter(tester, FauxImportCandidatures());
      await _jusqua(tester, PasImport.colonnes);
      await _toucher(tester, _cle('import-colonne-2'));
      await _retour(tester);
      expect(find.byKey(PasColonnes.listeKey), findsOneWidget);
      expect(find.byKey(PasColonnes.choixKey), findsNothing);
    });
  });

  group('pas 4 : doublons', () {
    testWidgets('un cas dit la nature de sa cle, jamais sa valeur', (
      tester,
    ) async {
      await _monter(tester, FauxImportCandidatures());
      await _jusqua(tester, PasImport.doublons);
      expect(find.text(a.doublons.question), findsOneWidget);
      expect(find.text(a.doublons.total(n: 1)), findsOneWidget);
      expect(find.byKey(PasDoublons.listeKey), findsOneWidget);
      expect(find.text(a.doublons.nature.courriel), findsOneWidget);
      expect(
        find.textContaining(a.doublons.lignes(liste: '3, 6')),
        findsOneWidget,
      );
      expect(find.textContaining(a.doublons.etat.recente), findsOneWidget);
      expect(
        find.text(a.doublons.tranches(choisis: '0', total: '1')),
        findsOneWidget,
      );
      _gardes(tester);
    });

    testWidgets(
      'un cas s\'ouvre : la plus recente, une autre ligne, ou distinctes',
      (tester) async {
        await _monter(tester, FauxImportCandidatures());
        await _jusqua(tester, PasImport.doublons);
        await _toucher(tester, _cle('import-doublon-g1a2b3c4d5e6'));
        expect(find.byKey(PasDoublons.casKey), findsOneWidget);
        expect(find.byKey(PasDoublons.listeKey), findsNothing);
        expect(
          find.text(
            a.doublons.casTitre(
              nature: a.doublons.nature.courriel,
              n: 1,
              total: 1,
            ),
          ),
          findsOneWidget,
        );
        expect(find.textContaining(a.doublons.choisirLigne), findsOneWidget);
        expect(
          find.text(a.doublons.option.recente.titre(ligne: 6)),
          findsOneWidget,
        );
        expect(
          find.text(a.doublons.option.recente.description),
          findsOneWidget,
        );
        expect(
          find.text(a.doublons.option.ligne.titre(ligne: 3)),
          findsOneWidget,
        );
        expect(find.text(a.doublons.option.distinctes.titre), findsOneWidget);
        expect(
          find.text(a.doublons.option.distinctes.description),
          findsOneWidget,
        );
        expect(find.byKey(ActionsDuPas.actionKey), findsNothing);
        _gardes(tester);
      },
    );

    testWidgets('choisir une ligne : elle part sous sa reference source', (
      tester,
    ) async {
      final FauxImportCandidatures port = FauxImportCandidatures();
      await _monter(tester, port);
      await _jusqua(tester, PasImport.doublons);
      await _toucher(tester, _cle('import-doublon-g1a2b3c4d5e6'));
      await _toucher(tester, _cle('import-doublon-option-ligne-3'));
      expect(find.byKey(PasDoublons.listeKey), findsOneWidget);
      expect(
        find.textContaining(a.doublons.etat.ligne(ligne: 3)),
        findsOneWidget,
      );
      expect(
        find.text(a.doublons.tranches(choisis: '1', total: '1')),
        findsOneWidget,
      );
      await _deLaListeDesDoublons(tester);
      expect(
        find.text(a.confirmation.resume.doublons(choisis: '1', total: '1')),
        findsOneWidget,
      );
      await _suivant(tester);
      final ChoixDoublon choix = port.confirmations.single.choix.single;
      expect(choix.groupe, 'g1a2b3c4d5e6');
      expect(
        choix.retenue,
        'Formulaire enseignants|Réponses|21/10/2026 09:40:00',
      );
    });

    testWidgets('personnes distinctes : le mot du serveur part', (
      tester,
    ) async {
      final FauxImportCandidatures port = FauxImportCandidatures();
      await _monter(tester, port);
      await _jusqua(tester, PasImport.doublons);
      await _toucher(tester, _cle('import-doublon-g1a2b3c4d5e6'));
      await _toucher(tester, _cle('import-doublon-option-distinctes'));
      expect(find.textContaining(a.doublons.etat.distinctes), findsOneWidget);
      await _deLaListeDesDoublons(tester);
      await _suivant(tester);
      expect(port.confirmations.single.choix.single.retenue, 'distinctes');
    });

    testWidgets('sans choix, rien n\'est envoye pour le cas', (tester) async {
      final FauxImportCandidatures port = FauxImportCandidatures();
      await _monter(tester, port);
      await _jusqua(tester, PasImport.confirmation);
      await _suivant(tester);
      expect(port.confirmations.single.choix, isEmpty);
    });

    testWidgets('aucun doublon probable : le pas le dit', (tester) async {
      await _monter(
        tester,
        FauxImportCandidatures(
          apercuRendu: apercuTest(groupes: const <GroupeDoublons>[]),
        ),
      );
      await _jusqua(tester, PasImport.doublons);
      expect(_cle('import-doublons-aucun'), findsOneWidget);
      expect(find.text(a.doublons.aucun), findsOneWidget);
      expect(find.text(t.commun.continuer), findsOneWidget);
    });

    testWidgets('un choix d\'un import precedent, ou une ligne deja en base', (
      tester,
    ) async {
      await _monter(
        tester,
        FauxImportCandidatures(
          apercuRendu: apercuTest(
            groupes: const <GroupeDoublons>[
              GroupeDoublons(
                id: 'ga',
                nature: NatureCle.telephone,
                taille: 2,
                lignes: <int>[3, 6],
                choisi: true,
                choix: retenueDistinctes,
              ),
              GroupeDoublons(
                id: 'gb',
                nature: NatureCle.courriel,
                taille: 3,
                lignes: <int>[4, 8],
                retenueDansLaBase: true,
              ),
            ],
          ),
        ),
      );
      await _jusqua(tester, PasImport.doublons);
      expect(find.textContaining(a.doublons.etat.enregistre), findsOneWidget);
      expect(find.textContaining(a.doublons.etat.base), findsOneWidget);
      expect(
        find.textContaining(a.doublons.dansLaBase(n: 1)),
        findsOneWidget,
        reason: 'seul le groupe de trois garde une ligne en base',
      );
      await _toucher(tester, _cle('import-doublon-ga'));
      expect(find.text(a.doublons.option.enregistre.titre), findsOneWidget);
      expect(
        find.text(a.doublons.option.enregistre.distinctes),
        findsOneWidget,
      );
      expect(
        _cle('import-doublon-option-distinctes'),
        findsNothing,
        reason: 'le choix enregistre est deja « personnes distinctes »',
      );
      await _retour(tester);
      await _toucher(tester, _cle('import-doublon-gb'));
      expect(find.text(a.doublons.option.base.titre), findsOneWidget);
    });

    testWidgets('beaucoup de cas : vingt a la fois', (tester) async {
      await _monter(
        tester,
        FauxImportCandidatures(
          apercuRendu: apercuTest(
            groupes: <GroupeDoublons>[
              for (int i = 0; i < 45; i++)
                GroupeDoublons(
                  id: 'g$i',
                  nature: NatureCle.courriel,
                  taille: 2,
                  lignes: <int>[2 + i, 3 + i],
                  retenueProposee: 3 + i,
                ),
            ],
          ),
        ),
        hauteur: 6000,
      );
      await _jusqua(tester, PasImport.doublons);
      expect(find.text(a.doublons.total(n: 45)), findsOneWidget);
      expect(_cle('import-doublon-g19'), findsOneWidget);
      expect(_cle('import-doublon-g20'), findsNothing);
      expect(find.text(a.doublons.plus(n: 20)), findsOneWidget);
      await _toucherLien(
        tester,
        const ValueKey<String>('import-doublons-plus'),
      );
      expect(_cle('import-doublon-g20'), findsOneWidget);
      expect(_cle('import-doublon-g39'), findsOneWidget);
      expect(_cle('import-doublon-g40'), findsNothing);
      expect(find.text(a.doublons.plus(n: 5)), findsOneWidget);
    });
  });

  group('pas 5 : erreurs et avertissements', () {
    testWidgets('trois listes, ligne par ligne, sans aucun nom', (
      tester,
    ) async {
      await _monter(tester, FauxImportCandidatures());
      await _jusqua(tester, PasImport.erreurs);
      expect(find.text(a.controle.question), findsOneWidget);
      expect(find.text(a.controle.aCorriger.titre), findsOneWidget);
      expect(
        find.text(a.controle.ligne(ligne: 7, motif: a.motif.genreIllisible)),
        findsOneWidget,
      );
      expect(find.text(a.controle.avertissements.titre), findsOneWidget);
      // La ligne 4 : un avertissement et deux marques, en mots.
      expect(
        find.textContaining(
          a.controle.ligne(ligne: 4, motif: a.avertissement.formatNational),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(a.apercu.marque.courrielAObtenir),
        findsWidgets,
      );
      expect(find.text(a.controle.ignorees.titre), findsOneWidget);
      expect(
        find.text(a.controle.ligne(ligne: 5, motif: a.motif.ligneVide)),
        findsOneWidget,
      );
      expect(find.text(a.controle.explication), findsOneWidget);
      expect(find.text(t.commun.continuer), findsOneWidget);
      _gardes(tester);
    });

    testWidgets('aucun code du serveur ne s\'affiche', (tester) async {
      await _monter(
        tester,
        FauxImportCandidatures(
          apercuRendu: apercuTest(
            lignes: const <LigneApercu>[
              LigneApercu(
                ligne: 2,
                issue: IssueLigne.aCorriger,
                motifs: <String>['motif_du_futur', 'genre_illisible'],
                avertissements: <String>['libelle_inconnu_genre'],
              ),
            ],
          ),
        ),
      );
      await _jusqua(tester, PasImport.erreurs);
      expect(find.textContaining('_'), findsNothing);
      expect(find.textContaining(a.motif.inconnu), findsOneWidget);
      expect(
        find.textContaining(a.avertissement.libelleInconnu),
        findsOneWidget,
      );
    });

    testWidgets('rien a corriger : le pas le dit', (tester) async {
      await _monter(
        tester,
        FauxImportCandidatures(
          apercuRendu: apercuTest(
            lignes: const <LigneApercu>[
              LigneApercu(ligne: 2, issue: IssueLigne.nouvelle),
            ],
          ),
        ),
      );
      await _jusqua(tester, PasImport.erreurs);
      expect(_cle('import-erreurs-aucune'), findsOneWidget);
      expect(find.text(a.controle.aucune), findsOneWidget);
    });

    testWidgets('cinquante lignes a la fois', (tester) async {
      await _monter(
        tester,
        FauxImportCandidatures(
          apercuRendu: apercuTest(
            lignes: <LigneApercu>[
              for (int i = 2; i < 130; i++)
                LigneApercu(
                  ligne: i,
                  issue: IssueLigne.aCorriger,
                  motifs: const <String>['nom_absent'],
                ),
            ],
          ),
        ),
        hauteur: 9000,
      );
      await _jusqua(tester, PasImport.erreurs);
      expect(_cle('import-ligne-a-corriger-51'), findsOneWidget);
      expect(_cle('import-ligne-a-corriger-52'), findsNothing);
      expect(find.text(a.controle.plus(n: 50)), findsOneWidget);
      await _toucherLien(
        tester,
        const ValueKey<String>('import-plus-a-corriger'),
      );
      expect(_cle('import-ligne-a-corriger-52'), findsOneWidget);
      expect(_cle('import-ligne-a-corriger-101'), findsOneWidget);
      expect(_cle('import-ligne-a-corriger-102'), findsNothing);
      expect(find.text(a.controle.plus(n: 28)), findsOneWidget);
    });
  });

  group('pas 6 : comptes', () {
    testWidgets(
      'les quatre compteurs du serveur, une question, pas de bouton',
      (tester) async {
        await _monter(tester, FauxImportCandidatures());
        await _jusqua(tester, PasImport.comptes);
        expect(find.text(a.comptes.question), findsOneWidget);
        for (final (String cle, String valeur) in <(String, String)>[
          ('nouvelles', '4'),
          ('dejaConnues', '1'),
          ('ignorees', '1'),
          ('aCorriger', '1'),
        ]) {
          expect(
            tester
                .widget<Text>(
                  find.descendant(
                    of: _cle('import-compteur-$cle'),
                    matching: find.byType(Text),
                  ),
                )
                .data,
            valeur,
            reason: 'compteur $cle',
          );
        }
        expect(find.text(a.comptes.nouvelles), findsOneWidget);
        expect(find.text(a.comptes.attendus.question), findsOneWidget);
        expect(find.byKey(ActionsDuPas.actionKey), findsNothing);
        expect(find.text(a.comptes.choisir), findsOneWidget);
        _gardes(tester);
      },
    );

    testWidgets(
      'le fichier du 21 octobre : l\'ecart se lit avant de confirmer',
      (tester) async {
        await _monter(tester, FauxImportCandidatures());
        await _jusqua(tester, PasImport.comptes);
        await _toucher(tester, _cle('import-attendu-fichier2110'));
        expect(_cle('import-comptes-ecart'), findsOneWidget);
        expect(
          find.text(
            a.comptes.ecart(
              attendu:
                  '${a.unite.lignes(n: 440)}, ${a.unite.personnes(n: 409)}',
              lu: '${a.unite.lignes(n: 7)}, ${a.unite.personnes(n: 5)}',
            ),
          ),
          findsOneWidget,
        );
        expect(find.byKey(ActionsDuPas.actionKey), findsOneWidget);
        _gardes(tester);
      },
    );

    testWidgets(
      'd\'autres nombres : des chiffres, puis l\'accord ou l\'ecart',
      (tester) async {
        await _monter(tester, FauxImportCandidatures());
        await _jusqua(tester, PasImport.comptes);
        await _toucher(tester, _cle('import-attendu-autres'));
        expect(find.byType(EditableText), findsNWidgets(2));
        expect(find.byKey(ActionsDuPas.actionKey), findsNothing);
        expect(find.text(a.comptes.saisirNombre), findsOneWidget);
        final Finder lignes = find.descendant(
          of: find.byKey(PasComptes.champLignesKey),
          matching: find.byType(EditableText),
        );
        await tester.enterText(lignes, 'ab-3x');
        await laisser(tester);
        expect(
          tester.widget<EditableText>(lignes).controller.text,
          '3',
          reason: 'des chiffres seulement',
        );
        await tester.enterText(lignes, '7');
        await laisser(tester);
        expect(_cle('import-comptes-accord'), findsOneWidget);
        expect(find.text(a.comptes.accord), findsOneWidget);
        expect(find.byKey(ActionsDuPas.actionKey), findsOneWidget);
        await tester.enterText(lignes, '8');
        await laisser(tester);
        expect(
          find.text(
            a.comptes.ecart(
              attendu: a.unite.lignes(n: 8),
              lu: a.unite.lignes(n: 7),
            ),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('aucun decompte a comparer : on continue sans ecart', (
      tester,
    ) async {
      await _monter(tester, FauxImportCandidatures());
      await _jusqua(tester, PasImport.comptes);
      await _toucher(tester, _cle('import-attendu-aucun'));
      expect(_cle('import-comptes-ecart'), findsNothing);
      expect(find.byKey(ActionsDuPas.actionKey), findsOneWidget);
    });
  });

  group('pas 7 : confirmation', () {
    testWidgets('le resume, ce que l\'import ne fait pas, un seul bouton', (
      tester,
    ) async {
      await _monter(tester, FauxImportCandidatures());
      await _jusqua(tester, PasImport.confirmation);
      expect(find.text(a.confirmation.question), findsOneWidget);
      expect(find.byKey(PasConfirmation.resumeKey), findsOneWidget);
      expect(find.text(a.confirmation.garanties.titre), findsOneWidget);
      expect(find.text(a.confirmation.garanties.texte), findsOneWidget);
      expect(find.text(a.confirmation.importer), findsOneWidget);
      expect(find.text(a.confirmation.horsLigne), findsNothing);
      verifierUnSeulBoutonPlein(tester);
      _gardes(tester);
    });

    testWidgets('l\'ecart du pas precedent se relit avant de confirmer', (
      tester,
    ) async {
      await _monter(tester, FauxImportCandidatures());
      await _jusqua(tester, PasImport.comptes);
      await _toucher(tester, _cle('import-attendu-fichier2110'));
      await _suivant(tester);
      expect(_cle('import-confirmation-ecart'), findsOneWidget);
    });

    testWidgets('rien n\'est dit importe avant la reponse du serveur', (
      tester,
    ) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..confirmationRetenue = Completer<RapportImport>();
      await _monter(tester, port);
      await _jusqua(tester, PasImport.confirmation);
      await _suivant(tester);
      expect(port.confirmations.length, 1);
      expect(find.text(a.confirmation.envoi), findsOneWidget);
      // Pendant l'envoi, « Retour » n'est pas rendu : il ne pourrait pas aboutir.
      expect(find.byKey(ActionsDuPas.retourKey), findsNothing);
      expect(find.byKey(PasRapport.titreKey), findsNothing);
      expect(find.text(a.rapport.titre), findsNothing);
      // Un second toucher ne renvoie rien.
      await tester.tap(find.byKey(ActionsDuPas.actionKey), warnIfMissed: false);
      await laisser(tester);
      expect(port.confirmations.length, 1);
      port.confirmationRetenue!.complete(rapportTest());
      await laisser(tester);
      expect(find.byKey(PasRapport.titreKey), findsOneWidget);
    });

    testWidgets(
      'hors ligne : la confirmation n\'est pas offerte, l\'apercu reste',
      (tester) async {
        final StreamController<bool> reseau = StreamController<bool>();
        addTearDown(reseau.close);
        reseau.add(false);
        await _monter(tester, FauxImportCandidatures(), reseau: reseau.stream);
        await _jusqua(tester, PasImport.confirmation);
        expect(find.byKey(ActionsDuPas.actionKey), findsOneWidget);
        reseau.add(true);
        await laisser(tester);
        expect(find.byKey(ActionsDuPas.actionKey), findsNothing);
        expect(find.text(a.confirmation.horsLigne), findsOneWidget);
        expect(find.byKey(PasConfirmation.resumeKey), findsOneWidget);
        reseau.add(false);
        await laisser(tester);
        expect(find.byKey(ActionsDuPas.actionKey), findsOneWidget);
      },
    );

    testWidgets('une reponse perdue : non confirme, la meme cle le rejoue', (
      tester,
    ) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..erreurConfirmation = (int n) =>
            n == 1 ? const ImportHorsLigne() : null;
      await _monter(tester, port);
      await _jusqua(tester, PasImport.confirmation);
      await _suivant(tester);
      expect(find.byKey(PasConfirmation.echecKey), findsOneWidget);
      expect(find.text(a.confirmation.titreNonConfirme), findsOneWidget);
      expect(find.text(a.confirmation.nonConfirme), findsOneWidget);
      expect(find.byKey(PasRapport.titreKey), findsNothing);
      await _suivant(tester);
      expect(port.confirmations.length, 2);
      expect(
        port.confirmations.last.cleIdempotence,
        port.confirmations.first.cleIdempotence,
      );
      expect(port.confirmations.last.jeton, port.confirmations.first.jeton);
      expect(find.byKey(PasRapport.titreKey), findsOneWidget);
    });

    testWidgets('un jeton perime : rien n\'est ecrit, relancer l\'analyse', (
      tester,
    ) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..erreurConfirmation = (int n) => n == 1 ? const JetonPerime() : null;
      await _monter(tester, port);
      await _jusqua(tester, PasImport.confirmation);
      await _suivant(tester);
      expect(find.text(a.confirmation.jetonPerime), findsOneWidget);
      expect(find.text(a.confirmation.titreARefaire), findsOneWidget);
      expect(
        find.byKey(ActionsDuPas.actionKey),
        findsNothing,
        reason: 'l\'analyse est a refaire avant de confirmer',
      );
      await _toucherLien(tester, PasConfirmation.relancerKey);
      expect(port.apercus.length, 2);
      expect(find.text(a.doublons.question), findsOneWidget);
    });

    testWidgets('un choix de doublon que le serveur ne reconnait plus', (
      tester,
    ) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..erreurConfirmation = (int n) =>
            n == 1 ? const ChoixInvalide(<String>['g1']) : null;
      await _monter(tester, port);
      await _jusqua(tester, PasImport.confirmation);
      await _suivant(tester);
      expect(find.text(a.confirmation.choixInvalide), findsOneWidget);
      expect(find.byKey(PasConfirmation.relancerKey), findsOneWidget);
    });

    testWidgets('le serveur refuse l\'import : une phrase, pas un code', (
      tester,
    ) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..erreurConfirmation = (int n) =>
            const ImportRefuseInconnu('code_du_futur');
      await _monter(tester, port);
      await _jusqua(tester, PasImport.confirmation);
      await _suivant(tester);
      expect(find.text(a.confirmation.refus), findsOneWidget);
      expect(find.textContaining('code_du_futur'), findsNothing);
    });

    testWidgets(
      'la double verification perdue en route : en mots et en action',
      (tester) async {
        final FauxServiceAuth auth = FauxServiceAuth();
        final FauxImportCandidatures port = FauxImportCandidatures()
          ..erreurConfirmation = (int n) => const DoubleVerificationRequise();
        await _monter(tester, port, auth: auth);
        await _jusqua(tester, PasImport.confirmation);
        await _suivant(tester);
        expect(_cle('import-double'), findsOneWidget);
        await tester.tap(find.text(a.acces.doubleAction));
        await laisser(tester);
        expect(auth.deconnexions, 1);
      },
    );
  });

  group('pas 8 : rapport', () {
    testWidgets(
      'apres la reponse : compteurs, lignes par reference, sans nom',
      (tester) async {
        await _monter(tester, FauxImportCandidatures());
        await _jusqua(tester, PasImport.rapport);
        expect(find.byKey(PasRapport.titreKey), findsOneWidget);
        expect(find.text(a.rapport.titre), findsOneWidget);
        expect(find.byKey(CompteursCarte.carteKey), findsOneWidget);
        expect(find.text(a.rapport.compteurs.nouvelles), findsOneWidget);
        expect(find.text(a.rapport.sansCandidature), findsOneWidget);
        expect(
          find.text(
            a.rapport.lignes.reference(
              reference: horodatageDeReference(
                'Formulaire enseignants|Reponses|21/10/2026 09:15:00',
              ),
            ),
          ),
          findsOneWidget,
        );
        expect(find.text(a.rapport.lignes.sansReference), findsOneWidget);
        expect(find.text(a.issue.historique), findsOneWidget);
        expect(find.text(a.rapport.historique(n: 1)), findsOneWidget);
        // Aucun bouton plein : deux liens.
        verifierUnSeulBoutonPlein(tester, maximum: 0);
        expect(find.byKey(PasRapport.revenirKey), findsOneWidget);
        expect(find.byKey(PasRapport.autreFichierKey), findsOneWidget);
        expect(find.text(a.retourCandidatures), findsOneWidget);
        _aucuneDonneePersonnelle(tester);
      },
    );

    testWidgets('une demande rejouee le dit : rien n\'a ete ajoute', (
      tester,
    ) async {
      await _monter(
        tester,
        FauxImportCandidatures(rapportRendu: rapportTest(rejoue: true)),
      );
      await _jusqua(tester, PasImport.rapport);
      expect(find.text(a.rapport.rejoue), findsOneWidget);
    });

    testWidgets('« Revenir aux candidatures » mene a la file', (tester) async {
      await _monter(tester, FauxImportCandidatures());
      await _jusqua(tester, PasImport.rapport);
      await _toucherLien(tester, PasRapport.revenirKey);
      expect(find.text('temoin:/admin/personnes/candidatures'), findsOneWidget);
    });

    testWidgets('« Importer un autre fichier » repart du premier pas', (
      tester,
    ) async {
      await _monter(tester, FauxImportCandidatures());
      await _jusqua(tester, PasImport.rapport);
      await _toucherLien(tester, PasRapport.autreFichierKey);
      expect(find.text(a.depot.question), findsOneWidget);
      expect(find.byKey(ActionsDuPas.actionKey), findsNothing);
      expect(find.byKey(PasDepot.carteFichierKey), findsOneWidget);
    });

    testWidgets('un rapport de 440 lignes : cinquante a la fois', (
      tester,
    ) async {
      await _monter(
        tester,
        FauxImportCandidatures(
          rapportRendu: rapportTest(
            lignes: <LigneRapport>[
              for (int i = 2; i < 442; i++)
                LigneRapport(
                  ligne: i,
                  issue: IssueLigne.nouvelle,
                  reference: 'C|O|$i',
                  etatFinal: EtatFinalLigne.active,
                ),
            ],
          ),
        ),
        hauteur: 9000,
      );
      await _jusqua(tester, PasImport.rapport);
      expect(_cle('import-ligne-rapport-51'), findsOneWidget);
      expect(_cle('import-ligne-rapport-52'), findsNothing);
      await _toucherLien(tester, const ValueKey<String>('import-plus-rapport'));
      expect(_cle('import-ligne-rapport-52'), findsOneWidget);
      expect(_cle('import-ligne-rapport-101'), findsOneWidget);
      expect(_cle('import-ligne-rapport-102'), findsNothing);
    });
  });

  group('la liste des pas selon la largeur', () {
    testWidgets('telephone : la barre de progression', (tester) async {
      await _monter(tester, FauxImportCandidatures(), largeur: 390);
      expect(find.byKey(ProgressionPas.progressionKey), findsOneWidget);
      expect(find.byKey(BandePas.bandeKey), findsNothing);
      expect(find.byKey(RailPas.railKey), findsNothing);
      expect(
        find.text(a.pas.surTotalNomme(n: 1, total: 8, nom: a.pas.depot)),
        findsOneWidget,
      );
    });

    testWidgets('tablette : les huit disques en haut', (tester) async {
      await _monter(tester, FauxImportCandidatures(), largeur: 768);
      expect(find.byKey(BandePas.bandeKey), findsOneWidget);
      expect(find.byKey(ProgressionPas.progressionKey), findsNothing);
      expect(find.byKey(RailPas.railKey), findsNothing);
    });

    testWidgets('bureau : le rail des huit pas au debut, le pas a la fin', (
      tester,
    ) async {
      await _monter(tester, FauxImportCandidatures(), largeur: 1440);
      expect(find.byKey(RailPas.railKey), findsOneWidget);
      for (final PasImport pas in PasImport.values) {
        expect(_cle('import-rail-${pas.name}'), findsOneWidget);
      }
      final Rect rail = tester.getRect(find.byKey(RailPas.railKey));
      final Rect carte = tester.getRect(find.byKey(PasDepot.carteFichierKey));
      expect(rail.right, lessThan(carte.left), reason: 'le rail est au debut');
      expect(rail.width, closeTo(largeurRail, 1));
      // Le pas courant se dit en mots, pas par la couleur seule.
      expect(find.text(a.pas.enCours), findsOneWidget);
      expect(find.text(a.pas.aVenir), findsNWidgets(7));
      await _jusqua(tester, PasImport.apercu);
      expect(find.text(a.pas.fait), findsOneWidget);
    });

    testWidgets(
      'bureau : le bouton est au bord de fin, a 16 sous son contenu',
      (tester) async {
        await _monter(tester, FauxImportCandidatures(), largeur: 1440);
        await _jusqua(tester, PasImport.apercu);
        final Rect bouton = tester.getRect(find.byKey(ActionsDuPas.actionKey));
        final Rect carte = tester.getRect(find.byKey(PasApercu.premieresKey));
        final Rect colonne = tester.getRect(
          find.byKey(const ValueKey<String>('import-pas-apercu')),
        );
        expect(bouton.right, closeTo(colonne.right, 1));
        expect(bouton.top - carte.bottom, closeTo(16, 1));
        expect(
          bouton.width,
          lessThan(colonne.width / 2),
          reason: 'pas de bouton pleine largeur sur bureau',
        );
      },
    );
  });

  group('gabarits : 320 px, texte x2, gauche a droite et droite a gauche', () {
    for (final TextDirection d in TextDirection.values) {
      testWidgets('les huit pas en ${d.name}', (tester) async {
        if (d == TextDirection.rtl) await _enArabe(tester);
        final FauxImportCandidatures port = FauxImportCandidatures();
        await _monter(
          tester,
          port,
          largeur: 320,
          hauteur: 4000,
          echelle: 2,
          direction: d,
        );
        void gardes() {
          expect(tester.takeException(), isNull);
          verifierEcranSansMotCoupe(tester);
          verifierUnSeulBoutonPlein(tester);
          _aucuneDonneePersonnelle(tester);
        }

        gardes();
        await _choisirFichier(tester);
        gardes();
        await _suivant(tester);
        gardes();
        await _suivant(tester);
        gardes();
        await _toucher(tester, _cle('import-colonne-4'));
        gardes();
        await _retour(tester);
        await _suivant(tester);
        gardes();
        await _toucher(tester, _cle('import-doublon-g1a2b3c4d5e6'));
        gardes();
        await _retour(tester);
        await _suivant(tester);
        gardes();
        await _suivant(tester);
        gardes();
        await _toucher(tester, _cle('import-attendu-fichier2110'));
        gardes();
        await _suivant(tester);
        gardes();
        await _suivant(tester);
        gardes();
        expect(find.byKey(PasRapport.titreKey), findsOneWidget);
      });
    }

    testWidgets('bureau en arabe : le rail est au bord de debut (a droite)', (
      tester,
    ) async {
      await _enArabe(tester);
      await _monter(
        tester,
        FauxImportCandidatures(),
        largeur: 1440,
        direction: TextDirection.rtl,
      );
      final Rect rail = tester.getRect(find.byKey(RailPas.railKey));
      final Rect carte = tester.getRect(find.byKey(PasDepot.carteFichierKey));
      expect(
        rail.left,
        greaterThan(carte.right),
        reason: 'le debut est a droite',
      );
      expect(tester.takeException(), isNull);
    });
  });
}
