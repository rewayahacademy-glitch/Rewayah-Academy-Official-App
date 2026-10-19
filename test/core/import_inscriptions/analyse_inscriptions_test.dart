// IMM-ACCUEIL-FRONT : l'analyse ligne par ligne des deux fichiers (champs
// manquants, doublons, age, foyer), sur des CSV inventes a la disposition des
// formulaires Google.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/import_inscriptions/analyse_inscriptions.dart';
import 'package:rewayah_academy/core/import_inscriptions/analyseur_csv.dart';

final DateTime _jour = DateTime(2026, 10, 18);
const BornesAge _bornes = BornesAge(minimum: 6, adulte: 18);

const String _entete =
    'Horodateur,Pour qui faites-vous cette inscription ?,Email du tuteur,'
    'Nom du tuteur,Prénom du tuteur,Nom de l\'élève,Prénom de l\'élève,'
    'Date de naissance,Nom de l\'élève,Prénom de l\'élève,Date de naissance,Email';

ApercuLocal _analyser(
  String eleves, {
  String enseignants = '',
  BornesAge bornes = _bornes,
}) => AnalyseInscriptions.analyser(
  eleves: AnalyseurCsv.lire(eleves),
  enseignants: AnalyseurCsv.lire(enseignants),
  jour: _jour,
  bornes: bornes,
);

Iterable<CodeProbleme> _codes(ApercuLocal a, int ligne) => a.problemes
    .where((ProblemeLigne p) => p.ligne == ligne)
    .map((ProblemeLigne p) => p.code);

void main() {
  test('une ligne complete : un foyer, un tuteur, deux eleves', () {
    final ApercuLocal a = _analyser(
      '$_entete\n'
      '01/10/2026,Mon enfant,parent@exemple.test,Diallo,Mariama,Diallo,Yasmine,'
      '02/03/2015,Diallo,Omar,05/06/2012,\n',
    );
    expect(a.problemes, isEmpty);
    expect(a.foyers, hasLength(1));
    final FoyerApercu f = a.foyers.single;
    expect(f.email, 'parent@exemple.test');
    expect(f.destinataire, 'Mariama');
    expect(f.prenomsEleves, <String>['Yasmine', 'Omar']);
    expect(a.personnes, 3);
    expect(a.lignesEleves, 1);
  });

  test('champs manquants : personne, adresse', () {
    final ApercuLocal a = _analyser(
      '$_entete\n'
      '01/10/2026,Mon enfant,parent@exemple.test,,,,,,,,,\n'
      '01/10/2026,Mon enfant,,Diallo,Mariama,,,,,,,\n',
    );
    expect(_codes(a, 2), contains(CodeProbleme.personneSansNom));
    expect(_codes(a, 3), contains(CodeProbleme.emailManquant));
    expect(a.foyers, isEmpty);
    expect(a.rienAImporter, isTrue);
    expect(a.lignesRefusees, 2);
    expect(a.refus, hasLength(2));
  });

  test('adresse mal ecrite, date impossible, ligne d\'essai, colonnes', () {
    final ApercuLocal a = _analyser(
      '$_entete\n'
      '01/10/2026,Mon enfant,pas-une-adresse,Diallo,Mariama,Diallo,Yasmine,02/03/2015,,,,\n'
      '01/10/2026,Mon enfant,a@exemple.test,Diallo,Mariama,Diallo,Yasmine,31/02/2015,,,,\n'
      '01/10/2026,Mon enfant,test@exemple.test,Diallo,Mariama,Diallo,Yasmine,02/03/2015,,,,\n'
      'trop,peu\n'
      ',,,,,,,,,,,\n',
    );
    expect(_codes(a, 2), contains(CodeProbleme.emailInvalide));
    expect(_codes(a, 3), contains(CodeProbleme.dateInvalide));
    expect(_codes(a, 4), contains(CodeProbleme.ligneTest));
    expect(_codes(a, 5), contains(CodeProbleme.colonnesDifferentes));
    expect(_codes(a, 6), contains(CodeProbleme.ligneVide));
    expect(a.foyers, isEmpty);
    expect(a.lignesRefusees, 5);
  });

  test(
    'doublons : meme adresse regroupee, meme personne importee une fois',
    () {
      final ApercuLocal a = _analyser(
        '$_entete\n'
        '01/10/2026,Mon enfant,parent@exemple.test,Diallo,Mariama,Diallo,Yasmine,02/03/2015,,,,\n'
        '02/10/2026,Mon enfant,Parent@Exemple.test,Diallo,Mariama,Diallo,Yasmine,02/03/2015,,,,\n'
        '03/10/2026,Mon enfant,PARENT@exemple.test,Diallo,Mariama,Diallo,Omar,05/06/2012,,,,\n',
      );
      expect(a.foyers, hasLength(1));
      expect(a.foyers.single.personnes, hasLength(3));
      final ProblemeLigne adresse = a.problemes.firstWhere(
        (ProblemeLigne p) =>
            p.ligne == 3 && p.code == CodeProbleme.doublonAdresse,
      );
      expect(adresse.autreLigne, 2);
      expect(adresse.gravite, GraviteProbleme.alerte);
      expect(_codes(a, 3), contains(CodeProbleme.doublonPersonne));
      expect(_codes(a, 4), contains(CodeProbleme.doublonAdresse));
      // Le tuteur revient a la ligne 4 : lui aussi n'est importe qu'une fois.
      expect(
        a.problemes
            .where(
              (ProblemeLigne p) =>
                  p.ligne == 4 && p.code == CodeProbleme.doublonPersonne,
            )
            .single
            .autreLigne,
        2,
      );
      // Les alertes n'enlevent rien : aucune ligne refusee.
      expect(a.lignesRefusees, 0);
    },
  );

  test('age : trop jeune, futur, adulte mineur, foyer sans adulte', () {
    final ApercuLocal a = _analyser(
      '$_entete\n'
      '01/10/2026,Mon enfant,a@exemple.test,Diallo,Mariama,Diallo,Petit,01/01/2024,,,,\n'
      '01/10/2026,Mon enfant,b@exemple.test,Diallo,Mariama,Diallo,Futur,01/01/2030,,,,\n'
      '01/10/2026,Mon enfant,c@exemple.test,Diallo,Jeune,Diallo,Yasmine,02/03/2015,,,,\n',
    );
    expect(_codes(a, 2), contains(CodeProbleme.ageTropJeune));
    expect(_codes(a, 3), contains(CodeProbleme.dateFuture));
    // Le tuteur sans date : aucune alerte d'adulte. L'age vient des dates lues.
    expect(_codes(a, 4), isNot(contains(CodeProbleme.adulteTropJeune)));
    expect(a.foyers, hasLength(3));
  });

  test('foyer de mineurs sans adulte nomme', () {
    final ApercuLocal a = _analyser(
      '$_entete\n'
      '01/10/2026,Mon enfant,a@exemple.test,,,Diallo,Yasmine,02/03/2015,,,,\n',
    );
    expect(a.foyers, hasLength(1));
    expect(_codes(a, 2), contains(CodeProbleme.foyerSansAdulte));
  });

  test('sans bornes du serveur, aucun controle d\'age', () {
    final ApercuLocal a = _analyser(
      '$_entete\n'
      '01/10/2026,Mon enfant,a@exemple.test,Diallo,Mariama,Diallo,Petit,01/01/2024,,,,\n',
      bornes: BornesAge.aucune,
    );
    expect(a.problemes, isEmpty);
  });

  test('"pour moi" : un adulte qui s\'inscrit lui-meme', () {
    final ApercuLocal a = _analyser(
      'Horodateur,Pour qui faites-vous cette inscription ?,Email,Nom,Prénom,Date de naissance\n'
      '01/10/2026,Pour moi,adulte@exemple.test,Haddad,Karim,10/04/1990\n',
    );
    expect(a.foyers.single.personnes.single.genre, GenrePersonne.adulte);
    expect(a.problemes, isEmpty);
  });

  test('un adulte nomme comme tel mais mineur', () {
    final ApercuLocal a = _analyser(
      'Pour qui faites-vous cette inscription ?,Email,Nom,Prénom,Date de naissance\n'
      'Pour moi,jeune@exemple.test,Haddad,Karim,10/04/2012\n',
    );
    expect(_codes(a, 2), contains(CodeProbleme.adulteTropJeune));
    expect(a.lignesRefusees, 0);
  });

  test('l\'en-tete sans colonne Email bloque le fichier', () {
    final ApercuLocal a = _analyser('Nom,Prénom\nDiallo,Aminata\n');
    expect(a.fichierBloque, isTrue);
    expect(a.problemes.single.code, CodeProbleme.enteteEmailAbsent);
    expect(a.problemes.single.source, SourceImport.eleves);
  });

  test('guillemet non ferme', () {
    final ApercuLocal a = _analyser('Email,Nom\n"x@y.fr,A\n');
    expect(
      a.problemes.map((ProblemeLigne p) => p.code),
      contains(CodeProbleme.guillemetNonFerme),
    );
    expect(a.fichierBloque, isTrue);
  });

  group('enseignants', () {
    const String entete = 'Horodateur,Prénom,Nom,Email';

    test('un enseignant forme son propre foyer', () {
      final ApercuLocal a = _analyser(
        '',
        enseignants: '$entete\n2026-10-01,Ibrahim,Sow,Ibrahim@Exemple.test\n',
      );
      expect(a.foyers.single.email, 'ibrahim@exemple.test');
      expect(a.foyers.single.personnes.single.genre, GenrePersonne.enseignant);
      expect(a.lignesEnseignants, 1);
    });

    test('prenom, adresse, essai', () {
      final ApercuLocal a = _analyser(
        '',
        enseignants:
            '$entete\n'
            '2026-10-01,,Sow,a@exemple.test\n'
            '2026-10-01,Ibrahim,Sow,\n'
            '2026-10-01,Ibrahim,Sow,mal-ecrit\n'
            '2026-10-01,Test,Sow,b@exemple.test\n',
      );
      expect(_codes(a, 2), contains(CodeProbleme.personneSansNom));
      expect(_codes(a, 3), contains(CodeProbleme.emailManquant));
      expect(_codes(a, 4), contains(CodeProbleme.emailInvalide));
      expect(_codes(a, 5), contains(CodeProbleme.ligneTest));
      expect(
        a.problemes.every(
          (ProblemeLigne p) => p.source == SourceImport.enseignants,
        ),
        isTrue,
      );
      expect(a.rienAImporter, isTrue);
    });

    test('meme adresse qu\'un eleve : un seul foyer', () {
      final ApercuLocal a = _analyser(
        '$_entete\n'
        '01/10/2026,Mon enfant,prof@exemple.test,Sow,Aicha,Sow,Yasmine,02/03/2015,,,,\n',
        enseignants: '$entete\n2026-10-01,Ibrahim,Sow,prof@exemple.test\n',
      );
      expect(a.foyers, hasLength(1));
      expect(a.foyers.single.personnes, hasLength(3));
      expect(_codes(a, 2), contains(CodeProbleme.doublonAdresse));
    });
  });

  test('lireDateNaissance et ageAu', () {
    expect(lireDateNaissance('29/02/2024'), DateTime(2024, 2, 29));
    expect(lireDateNaissance('29/02/2023'), isNull);
    expect(lireDateNaissance('2015-03-02'), isNull);
    expect(ageAu(DateTime(2015, 10, 19), _jour), 10);
    expect(ageAu(DateTime(2015, 10, 18), _jour), 11);
  });
}
