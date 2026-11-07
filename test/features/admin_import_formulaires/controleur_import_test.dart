// ADM-23 : le controleur de l'import des formulaires, sans aucun widget.
//
// Ce que le test prouve : l'ordre des huit pas et ce qui les ouvre ; qu'aucun
// appel ne part avant « Analyser » ; que le serveur est consulte une fois par
// fichier, noms et mappage ; la deduction du classeur et de l'onglet ; le
// mappage incomplet ou ambigu (l'apercu dit ce qu'il sait, le pas des colonnes
// attend une association) ; les choix de doublons envoyes sous la reference
// source de la ligne ; l'ecart des comptes ; et que la cle d'idempotence de la
// confirmation survit a une reponse perdue, change quand le contenu change, et
// ne sert qu'une fois a un succes. Rien n'est dit importe avant la reponse.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/fichier_formulaires.dart';
import 'package:rewayah_academy/core/candidature/modeles_import_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_import_candidatures.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/controleur_import.dart';

import '../../fixtures/candidature/faux_import_candidatures.dart';

const String _nom = 'Formulaire enseignants - Réponses.csv';

ControleurImportCandidatures _controleur(
  FauxImportCandidatures port, {
  bool horsLigne = false,
  List<String>? cles,
}) {
  int n = 0;
  return ControleurImportCandidatures(
    port: port,
    horsLigne: () => horsLigne,
    cleIdempotence: () => cles == null ? 'import-cle-${++n}-xxxx' : cles[n++],
  );
}

Future<ControleurImportCandidatures> _jusquauxComptes(
  FauxImportCandidatures port,
) async {
  final ControleurImportCandidatures c = _controleur(port)
    ..deposer(nom: _nom, texte: csvFormulaires);
  await c.analyser();
  await c.suivant(); // colonnes
  await c.suivant(); // doublons
  await c.suivant(); // erreurs
  await c.suivant(); // comptes
  return c;
}

void main() {
  group('pas 1 : deposer', () {
    test('rien ne part tant que le fichier n\'est pas analyse', () {
      final FauxImportCandidatures port = FauxImportCandidatures();
      final ControleurImportCandidatures c = _controleur(port)
        ..deposer(nom: _nom, texte: csvFormulaires);
      expect(port.apercus, isEmpty);
      expect(c.pas, PasImport.depot);
      expect(c.peutAnalyser, isTrue);
    });

    test('le classeur et l\'onglet se deduisent du nom du fichier', () {
      final ControleurImportCandidatures c = _controleur(
        FauxImportCandidatures(),
      )..deposer(nom: _nom, texte: csvFormulaires);
      expect(c.noms.classeur, 'Formulaire enseignants');
      expect(c.noms.onglet, 'Réponses');
    });

    test('un nom sans onglet empeche d\'analyser jusqu\'a la correction', () {
      final ControleurImportCandidatures c = _controleur(
        FauxImportCandidatures(),
      )..deposer(nom: 'export.csv', texte: csvFormulaires);
      expect(c.peutAnalyser, isFalse);
      c.corrigerNoms(onglet: 'Réponses');
      expect(c.peutAnalyser, isTrue);
      c.corrigerNoms(onglet: 'a|b');
      expect(c.peutAnalyser, isFalse, reason: 'la barre verticale est refusee');
    });

    test(
      'un fichier sans ligne, ou aux guillemets ouverts, n\'est pas envoye',
      () {
        final ControleurImportCandidatures c = _controleur(
          FauxImportCandidatures(),
        )..deposer(nom: _nom, texte: 'Horodateur,Nom\n');
        expect(c.fichierSansLigne, isTrue);
        expect(c.peutAnalyser, isFalse);
        c.deposer(nom: _nom, texte: 'A,B\n1,"2\n3,4\n');
        expect(c.problemeFichier?.cause, CauseFichier.guillemetNonFerme);
        expect(
          c.problemeFichier?.ligne,
          2,
          reason: 'la ligne du guillemet ouvert',
        );
        expect(c.peutAnalyser, isFalse);
      },
    );

    test('plus de 5 Mo : refuse avant tout envoi', () {
      final ControleurImportCandidatures c =
          _controleur(FauxImportCandidatures())..deposer(
            nom: _nom,
            texte: 'A\n${List<String>.filled(700000, 'abcdefgh').join('\n')}',
          );
      expect(c.problemeFichier?.cause, CauseFichier.tropVolumineux);
      expect(c.peutAnalyser, isFalse);
    });

    test(
      'un nouveau fichier oublie tout ce que l\'ancien avait appris',
      () async {
        final FauxImportCandidatures port = FauxImportCandidatures();
        final ControleurImportCandidatures c = _controleur(port)
          ..deposer(nom: _nom, texte: csvFormulaires);
        await c.analyser();
        c.choisir('g1a2b3c4d5e6', const PersonnesDistinctes());
        c.deposer(nom: 'Autre - Feuille.csv', texte: csvFormulaires);
        expect(c.apercu, isNull);
        expect(c.pas, PasImport.depot);
        expect(c.choixDuGroupe('g1a2b3c4d5e6'), isA<ParDefaut>());
      },
    );
  });

  group('l\'essai a blanc', () {
    test(
      'envoie le CSV en virgules, les noms, le fuseau, et va a l\'apercu',
      () async {
        final FauxImportCandidatures port = FauxImportCandidatures();
        final ControleurImportCandidatures c = _controleur(port)
          ..deposer(nom: _nom, texte: csvFormulaires);
        await c.analyser();
        expect(port.apercus.length, 1);
        expect(port.apercus.single.classeur, 'Formulaire enseignants');
        expect(port.apercus.single.onglet, 'Réponses');
        expect(port.apercus.single.fuseau, 'UTC');
        expect(port.apercus.single.mappage, MappageColonnes.aucun);
        expect(port.apercus.single.csv, c.fichier!.csv);
        expect(c.pas, PasImport.apercu);
        expect(c.apercu?.jeton, 'jeton-a');
      },
    );

    test(
      'pendant l\'analyse, le controleur est occupe et rien d\'autre ne part',
      () async {
        final FauxImportCandidatures port = FauxImportCandidatures()
          ..apercuRetenu = Completer<ApercuImport>();
        final ControleurImportCandidatures c = _controleur(port)
          ..deposer(nom: _nom, texte: csvFormulaires);
        final Future<void> analyse = c.analyser();
        await Future<void>.delayed(Duration.zero);
        expect(c.phase, PhaseImport.analyse);
        expect(c.occupe, isTrue);
        unawaited(c.analyser());
        expect(port.apercus.length, 1, reason: 'pas de second appel en vol');
        port.apercuRetenu!.complete(apercuTest());
        await analyse;
        expect(c.phase, PhaseImport.repos);
        expect(c.pas, PasImport.apercu);
      },
    );

    test('un apercu deja lu pour ce fichier n\'est pas redemande', () async {
      final FauxImportCandidatures port = FauxImportCandidatures();
      final ControleurImportCandidatures c = _controleur(port)
        ..deposer(nom: _nom, texte: csvFormulaires);
      await c.analyser();
      c.precedent();
      expect(c.pas, PasImport.depot);
      await c.analyser();
      expect(port.apercus.length, 1);
      expect(c.pas, PasImport.apercu);
      // Une autre reference source : l'apercu ne vaut plus.
      c.precedent();
      c.corrigerNoms(onglet: 'Autre');
      await c.analyser();
      expect(port.apercus.length, 2);
    });

    test('hors ligne : rien ne part, l\'echec le dit', () async {
      final FauxImportCandidatures port = FauxImportCandidatures();
      final ControleurImportCandidatures c = _controleur(port, horsLigne: true)
        ..deposer(nom: _nom, texte: csvFormulaires);
      await c.analyser();
      expect(port.apercus, isEmpty);
      expect(c.erreurAnalyse, isA<ImportHorsLigne>());
      expect(c.pas, PasImport.depot);
    });

    test('un echec sans reponse reste au depot, et se rejoue', () async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..erreurApercu = (int n) => n == 1 ? StateError('muet') : null;
      final ControleurImportCandidatures c = _controleur(port)
        ..deposer(nom: _nom, texte: csvFormulaires);
      await c.analyser();
      expect(c.erreurAnalyse, isA<StateError>());
      expect(c.pas, PasImport.depot);
      await c.analyser();
      expect(c.erreurAnalyse, isNull);
      expect(c.pas, PasImport.apercu);
    });

    test(
      'un fichier que le serveur dit illisible ou vide reste au depot',
      () async {
        final FauxImportCandidatures port = FauxImportCandidatures()
          ..erreurApercu = (int n) => n == 1
              ? const FichierIllisible(
                  'CSV mal formé après un guillemet fermant',
                )
              : const FichierVide();
        final ControleurImportCandidatures c = _controleur(port)
          ..deposer(nom: _nom, texte: csvFormulaires);
        await c.analyser();
        expect(c.problemeFichier?.cause, CauseFichier.malForme);
        expect(c.pas, PasImport.depot);
        expect(c.peutAnalyser, isFalse, reason: 'il faut un autre fichier');
        c.deposer(nom: _nom, texte: csvFormulaires);
        expect(c.problemeFichier, isNull);
        await c.analyser();
        expect(c.fichierSansLigne, isTrue);
        expect(c.pas, PasImport.depot);
      },
    );

    test(
      '0 ligne lue par le serveur : le fichier est vide, on reste au depot',
      () async {
        final FauxImportCandidatures port = FauxImportCandidatures(
          apercuRendu: apercuTest(
            compteurs: const CompteursImport(
              lignesLues: 0,
              nouvelles: 0,
              corrigees: 0,
              dejaConnues: 0,
              ignorees: 0,
              aCorriger: 0,
              historique: 0,
              personnes: 0,
            ),
            groupes: const <GroupeDoublons>[],
            lignes: const <LigneApercu>[],
          ),
        );
        final ControleurImportCandidatures c = _controleur(port)
          ..deposer(nom: _nom, texte: csvFormulaires);
        await c.analyser();
        expect(c.fichierSansLigne, isTrue);
        expect(c.pas, PasImport.depot);
      },
    );
  });

  group('pas 3 : colonnes', () {
    test('un mappage incomplet : l\'apercu dit ce qu\'il sait, les colonnes attendent', () async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..erreurApercu = (int n) => n == 1
            ? MappageIncomplet(
                champs: const <ChampManquant>[ChampManquant.nom],
                colonnes: colonnesTest(
                  sauf: <ChampFormulaire>{ChampFormulaire.nom},
                ),
              )
            : null;
      final ControleurImportCandidatures c = _controleur(port)
        ..deposer(nom: _nom, texte: csvFormulaires);
      await c.analyser();
      expect(c.pas, PasImport.apercu);
      expect(c.apercu, isNull);
      expect(c.manquants, <ChampManquant>[ChampManquant.nom]);
      expect(c.colonnesCompletes, isFalse);
      await c.suivant();
      expect(c.pas, PasImport.colonnes);
      await c.suivant();
      expect(c.pas, PasImport.colonnes, reason: 'on n\'avance pas sans le nom');
      expect(port.apercus.length, 1, reason: 'aucun appel de plus');

      // La direction dit que la colonne 3 est le nom : l'apercu se relit.
      c.associer(3, ChampFormulaire.nom);
      expect(c.colonnesCompletes, isTrue);
      expect(c.colonnesAReLire, isTrue);
      await c.suivant();
      expect(port.apercus.length, 2);
      expect(port.apercus.last.mappage.versJson(), <String, String?>{
        '3': 'nom',
      });
      expect(c.pas, PasImport.doublons);
    });

    test(
      'deux colonnes pour un champ : rien n\'avance avant une association',
      () async {
        final FauxImportCandidatures port = FauxImportCandidatures()
          ..erreurApercu = (int n) => n == 1
              ? EntetesAmbigus(
                  champs: const <ChampFormulaire>[ChampFormulaire.nom],
                  colonnes: colonnesTest(),
                )
              : null;
        final ControleurImportCandidatures c = _controleur(port)
          ..deposer(nom: _nom, texte: csvFormulaires);
        await c.analyser();
        expect(c.ambigu, isTrue);
        expect(c.champsAmbigus, <ChampFormulaire>[ChampFormulaire.nom]);
        expect(c.colonnesCompletes, isFalse);
        c.associer(3, ChampFormulaire.nom);
        expect(c.ambigu, isFalse);
        expect(c.colonnesCompletes, isTrue);
      },
    );

    test(
      'deux colonnes pour un champ : une autre association ne tranche rien',
      () async {
        final FauxImportCandidatures port = FauxImportCandidatures()
          ..erreurApercu = (int n) => n == 1
              ? EntetesAmbigus(
                  champs: const <ChampFormulaire>[ChampFormulaire.nom],
                  colonnes: colonnesTest(),
                )
              : null;
        final ControleurImportCandidatures c = _controleur(port)
          ..deposer(nom: _nom, texte: csvFormulaires);
        await c.analyser();
        c.associer(9, null);
        expect(c.mappage.estVide, isFalse);
        expect(c.ambigu, isTrue, reason: 'le champ double attend SON choix');
        expect(c.colonnesCompletes, isFalse);
        await c.suivant();
        await c.suivant();
        expect(c.pas, PasImport.colonnes);
        expect(port.apercus.length, 1, reason: 'aucun appel de plus');
        c.associer(3, ChampFormulaire.nom);
        expect(c.ambigu, isFalse);
      },
    );

    test('lire une colonne ailleurs : la reference suit la colonne de l\'horodateur', () async {
      final FauxImportCandidatures port = FauxImportCandidatures();
      final ControleurImportCandidatures c = _controleur(port)
        ..deposer(nom: _nom, texte: csvFormulaires);
      await c.analyser();
      c.associer(1, null);
      expect(c.manquants, <ChampManquant>[ChampManquant.horodatage]);
      expect(c.colonnesCompletes, isFalse);
    });
  });

  group('pas 4 : doublons', () {
    test(
      'sans choix, rien n\'est envoye : le serveur applique la plus recente',
      () async {
        final FauxImportCandidatures port = FauxImportCandidatures();
        final ControleurImportCandidatures c = _controleur(port)
          ..deposer(nom: _nom, texte: csvFormulaires);
        await c.analyser();
        expect(c.choixPourLeServeur(), isEmpty);
        expect(c.groupesTranches, 0);
      },
    );

    test('garder une ligne : la reference source de cette ligne', () async {
      final FauxImportCandidatures port = FauxImportCandidatures();
      final ControleurImportCandidatures c = _controleur(port)
        ..deposer(nom: _nom, texte: csvFormulaires);
      await c.analyser();
      c.choisir('g1a2b3c4d5e6', const GardeLigne(3));
      expect(c.choixPourLeServeur(), const <ChoixDoublon>[
        ChoixDoublon(
          groupe: 'g1a2b3c4d5e6',
          retenue: 'Formulaire enseignants|Réponses|21/10/2026 09:40:00',
        ),
      ]);
      expect(c.groupesTranches, 1);
    });

    test('personnes distinctes : le mot du serveur', () async {
      final FauxImportCandidatures port = FauxImportCandidatures();
      final ControleurImportCandidatures c = _controleur(port)
        ..deposer(nom: _nom, texte: csvFormulaires);
      await c.analyser();
      c.choisir('g1a2b3c4d5e6', const PersonnesDistinctes());
      expect(c.choixPourLeServeur().single.retenue, 'distinctes');
    });

    test('revenir au defaut retire le choix', () async {
      final FauxImportCandidatures port = FauxImportCandidatures();
      final ControleurImportCandidatures c = _controleur(port)
        ..deposer(nom: _nom, texte: csvFormulaires);
      await c.analyser();
      c.choisir('g1a2b3c4d5e6', const PersonnesDistinctes());
      c.choisir('g1a2b3c4d5e6', const ParDefaut());
      expect(c.choixPourLeServeur(), isEmpty);
    });

    test('une relecture qui retire un groupe lui retire son choix', () async {
      final FauxImportCandidatures port = FauxImportCandidatures();
      final ControleurImportCandidatures c = _controleur(port)
        ..deposer(nom: _nom, texte: csvFormulaires);
      await c.analyser();
      c.choisir('g1a2b3c4d5e6', const PersonnesDistinctes());
      port.apercuRendu = apercuTest(groupes: const <GroupeDoublons>[]);
      await c.relireLeFichier();
      expect(c.choixPourLeServeur(), isEmpty);
    });
  });

  group('pas 6 : comptes', () {
    test('sans decompte a comparer, aucun ecart', () async {
      final ControleurImportCandidatures c = await _jusquauxComptes(
        FauxImportCandidatures(),
      );
      expect(c.pas, PasImport.comptes);
      expect(c.comptesRepondus, isFalse);
      c.repondreAttendus(ReponseAttendus.aucun);
      expect(c.comptesRepondus, isTrue);
      expect(c.ecarts, isEmpty);
    });

    test('le fichier du 21 octobre : 440 lignes, 409 personnes', () async {
      final ControleurImportCandidatures c = await _jusquauxComptes(
        FauxImportCandidatures(),
      );
      c.repondreAttendus(ReponseAttendus.fichierDu2110);
      expect(
        c.ecarts.map((EcartCompte e) => (e.nature, e.attendu, e.lu)),
        <(NatureCompte, int, int)>[
          (NatureCompte.lignes, 440, 7),
          (NatureCompte.personnes, 409, 5),
        ],
      );
    });

    test('d\'autres nombres : seul ce qui est saisi se compare', () async {
      final ControleurImportCandidatures c = await _jusquauxComptes(
        FauxImportCandidatures(),
      );
      c.repondreAttendus(ReponseAttendus.autres);
      expect(c.comptesRepondus, isFalse, reason: 'aucun nombre saisi');
      c.repondreAttendus(ReponseAttendus.autres, lignes: 7);
      expect(c.comptesRepondus, isTrue);
      expect(c.ecarts, isEmpty);
      c.repondreAttendus(ReponseAttendus.autres, lignes: 8, personnes: 5);
      expect(c.ecarts.single.nature, NatureCompte.lignes);
      expect(c.ecarts.single.attendu, 8);
      expect(c.ecarts.single.lu, 7);
    });

    test('on ne passe pas a la confirmation sans avoir repondu', () async {
      final ControleurImportCandidatures c = await _jusquauxComptes(
        FauxImportCandidatures(),
      );
      await c.suivant();
      expect(c.pas, PasImport.comptes);
      c.repondreAttendus(ReponseAttendus.aucun);
      await c.suivant();
      expect(c.pas, PasImport.confirmation);
    });
  });

  group('pas 7 : confirmation', () {
    Future<ControleurImportCandidatures> aLaConfirmation(
      FauxImportCandidatures port, {
      List<String>? cles,
      bool horsLigne = false,
    }) async {
      final ControleurImportCandidatures c = _controleur(
        port,
        cles: cles,
        horsLigne: horsLigne,
      )..deposer(nom: _nom, texte: csvFormulaires);
      await c.analyser();
      for (int i = 0; i < 4; i++) {
        await c.suivant();
      }
      c.repondreAttendus(ReponseAttendus.aucun);
      await c.suivant();
      expect(c.pas, PasImport.confirmation);
      return c;
    }

    test('la page fermee pendant l\'envoi ne fait pas lever le controleur', () async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..confirmationRetenue = Completer<RapportImport>();
      final ControleurImportCandidatures c = await aLaConfirmation(port);
      final Future<void> envoi = c.confirmer();
      expect(c.occupe, isTrue);
      c.dispose();
      port.confirmationRetenue!.complete(rapportTest());
      await envoi;
    });

    test('un nom de classeur a espaces de bord part sans eux, comme la reference', () async {
      final FauxImportCandidatures port = FauxImportCandidatures();
      final ControleurImportCandidatures c = await aLaConfirmation(port);
      expect(sansEspaces('  Classeur  '), 'Classeur');
      await c.confirmer();
      expect(port.confirmations.last.classeur, sansEspaces(c.noms.classeur));
    });

    test('rien n\'est dit importe avant la reponse du serveur', () async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..confirmationRetenue = Completer<RapportImport>();
      final ControleurImportCandidatures c = await aLaConfirmation(port);
      final Future<void> envoi = c.confirmer();
      await Future<void>.delayed(Duration.zero);
      expect(c.phase, PhaseImport.envoi);
      expect(c.rapport, isNull);
      expect(c.pas, PasImport.confirmation);
      port.confirmationRetenue!.complete(rapportTest());
      await envoi;
      expect(c.rapport, isNotNull);
      expect(c.pas, PasImport.rapport);
    });

    test(
      'envoie le jeton de l\'apercu, la cle, les choix et le mappage',
      () async {
        final FauxImportCandidatures port = FauxImportCandidatures();
        final ControleurImportCandidatures c = await aLaConfirmation(port);
        await c.confirmer();
        final AppelConfirmation a = port.confirmations.single;
        expect(a.jeton, 'jeton-a');
        expect(a.cleIdempotence, startsWith('import-'));
        expect(a.cleIdempotence.length, inInclusiveRange(8, 200));
        expect(a.classeur, 'Formulaire enseignants');
        expect(a.onglet, 'Réponses');
        expect(a.choix, isEmpty);
        expect(a.csv, c.fichier!.csv);
      },
    );

    test('une reponse perdue laisse l\'import non confirme ; la meme cle le rejoue', () async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..erreurConfirmation = (int n) =>
            n == 1 ? const ImportHorsLigne() : null;
      final ControleurImportCandidatures c = await aLaConfirmation(port);
      await c.confirmer();
      expect(c.rapport, isNull);
      expect(c.pas, PasImport.confirmation);
      expect(c.erreurConfirmation, isA<ImportHorsLigne>());
      await c.confirmer();
      expect(port.confirmations.length, 2);
      expect(
        port.confirmations.last.cleIdempotence,
        port.confirmations.first.cleIdempotence,
        reason: 'la meme demande ne s\'enregistre qu\'une fois',
      );
      expect(c.pas, PasImport.rapport);
    });

    test(
      'un choix change apres un echec : une autre demande, une autre cle',
      () async {
        final FauxImportCandidatures port = FauxImportCandidatures()
          ..erreurConfirmation = (int n) =>
              n == 1 ? const ImportHorsLigne() : null;
        final ControleurImportCandidatures c = await aLaConfirmation(port);
        await c.confirmer();
        c.choisir('g1a2b3c4d5e6', const PersonnesDistinctes());
        await c.confirmer();
        expect(
          port.confirmations.last.cleIdempotence,
          isNot(port.confirmations.first.cleIdempotence),
        );
        expect(port.confirmations.last.choix.single.retenue, 'distinctes');
      },
    );

    test(
      'un succes libere la cle : l\'import suivant en tire une autre',
      () async {
        final FauxImportCandidatures port = FauxImportCandidatures();
        final ControleurImportCandidatures c = await aLaConfirmation(
          port,
          cles: <String>['import-cle-aaaa', 'import-cle-bbbb'],
        );
        await c.confirmer();
        expect(port.confirmations.single.cleIdempotence, 'import-cle-aaaa');
        c.recommencer();
        expect(c.pas, PasImport.depot);
        expect(c.fichier, isNull);
        expect(c.rapport, isNull);
      },
    );

    test('hors ligne : rien ne part', () async {
      final FauxImportCandidatures port = FauxImportCandidatures();
      final ControleurImportCandidatures c = await aLaConfirmation(
        port,
        horsLigne: false,
      );
      // La connexion tombe entre l'apercu et la confirmation.
      final ControleurImportCandidatures coupe = _controleur(
        port,
        horsLigne: true,
      );
      expect(coupe.horsLigne(), isTrue);
      await coupe.confirmer();
      expect(port.confirmations, isEmpty);
      expect(c.pas, PasImport.confirmation);
    });

    test('un jeton perime : rien n\'est ecrit, on relit le fichier', () async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..erreurConfirmation = (int n) => n == 1 ? const JetonPerime() : null;
      final ControleurImportCandidatures c = await aLaConfirmation(port);
      await c.confirmer();
      expect(c.erreurConfirmation, isA<JetonPerime>());
      expect(c.rapport, isNull);
      await c.relireLeFichier();
      expect(port.apercus.length, 2);
      expect(c.pas, PasImport.doublons);
      expect(c.erreurConfirmation, isNull);
    });

    test(
      'le refus d\'un lecteur sans droit est un refus, pas un echec',
      () async {
        final FauxImportCandidatures port = FauxImportCandidatures()
          ..erreurConfirmation = (_) => const PermissionInsuffisante('x');
        final ControleurImportCandidatures c = await aLaConfirmation(port);
        await c.confirmer();
        expect(c.erreurConfirmation, isA<PermissionInsuffisante>());
        expect(c.rapport, isNull);
      },
    );
  });

  group('navigation', () {
    test('le retour ne quitte ni le depot ni le rapport', () async {
      final FauxImportCandidatures port = FauxImportCandidatures();
      final ControleurImportCandidatures c = _controleur(port)
        ..deposer(nom: _nom, texte: csvFormulaires);
      c.precedent();
      expect(c.pas, PasImport.depot);
      await c.analyser();
      c.precedent();
      expect(c.pas, PasImport.depot);
    });

    test('les pas se suivent dans l\'ordre de la fiche', () async {
      final FauxImportCandidatures port = FauxImportCandidatures();
      final ControleurImportCandidatures c = _controleur(port)
        ..deposer(nom: _nom, texte: csvFormulaires);
      final List<PasImport> vus = <PasImport>[c.pas];
      await c.analyser();
      vus.add(c.pas);
      for (int i = 0; i < 3; i++) {
        await c.suivant();
        vus.add(c.pas);
      }
      expect(vus, <PasImport>[
        PasImport.depot,
        PasImport.apercu,
        PasImport.colonnes,
        PasImport.doublons,
        PasImport.erreurs,
      ]);
      expect(PasImport.values.length, 8);
      expect(c.numeroPas, 5);
    });
  });

  test(
    'FichierFormulaires et ProblemeFichier : la cause du serveur se traduit',
    () {
      expect(
        ProblemeFichier.depuisServeur('CSV absent ou supérieur à 5 Mo').cause,
        CauseFichier.tropVolumineux,
      );
      expect(
        ProblemeFichier.depuisServeur('CSV mal formé: guillemet non fermé')
            .cause,
        CauseFichier.guillemetNonFerme,
      );
      expect(
        ProblemeFichier.depuisServeur(
          'CSV mal formé après un guillemet fermant',
        ).cause,
        CauseFichier.malForme,
      );
      expect(ProblemeFichier.depuisServeur('?').cause, CauseFichier.inconnue);
      expect(deduireNoms(_nom).valides, isTrue);
    },
  );
}
