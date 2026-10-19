/// IMM-ACCUEIL-FRONT : l'apercu ligne par ligne d'un import d'inscriptions.
///
/// Cette analyse **precede** l'essai a blanc du serveur et ne le remplace pas :
/// elle lit la meme disposition (formulaires Google : une ligne par envoi,
/// jusqu'a cinq personnes, tuteur ou adulte) pour dire a la direction, avant
/// tout appel, quelle ligne sera refusee et pourquoi, quelles lignes meritent
/// un coup d'oeil (doublon, age, foyer sans adulte) et quels foyers seront
/// crees. Les motifs de refus sont ceux de `previsualiser_import_inscriptions`
/// (migration 20261012184501) ; le serveur reste l'arbitre : il relit tout a la
/// confirmation, et un motif qu'il rend et que cette analyse n'a pas vu est
/// ajoute a l'apercu par l'ecran.
///
/// Aucune borne d'age n'est ecrite ici : elles viennent du serveur
/// (`BornesAge`, tranches d'age).
library;

import 'package:flutter/foundation.dart';

import 'analyseur_csv.dart';

/// Quel fichier.
enum SourceImport {
  /// Le classeur « Eleves (Reponses) ».
  eleves,

  /// Le classeur « Enseignants (Reponses) ».
  enseignants,
}

/// Le poids d'un probleme.
enum GraviteProbleme {
  /// La ligne sera refusee par le serveur : rien n'est importe pour elle.
  refus,

  /// La ligne sera importee, mais elle merite un coup d'oeil.
  alerte,
}

/// Ce qui ne va pas dans une ligne (ou dans un fichier entier).
enum CodeProbleme {
  // --- refus (les motifs du serveur) ---

  /// Aucune cellule ne porte de texte (`empty_row`).
  ligneVide,

  /// Plus ou moins de cellules que d'en-tetes (`column_count_mismatch`).
  colonnesDifferentes,

  /// Ligne d'essai (`test_row`).
  ligneTest,

  /// Aucune personne nommee (`missing_person_name`).
  personneSansNom,

  /// Aucune adresse e-mail (`missing_email`).
  emailManquant,

  /// Adresse e-mail mal formee (`invalid_email`).
  emailInvalide,

  /// Date de naissance qui n'est pas JJ/MM/AAAA (`invalid_birth_date`).
  dateInvalide,

  /// Un motif de refus du serveur que cette analyse n'a pas vu.
  refusServeur,

  // --- fichier entier (rien ne part) ---

  /// L'en-tete n'a pas de colonne « Email ».
  enteteEmailAbsent,

  /// Un guillemet ouvert n'est jamais ferme.
  guillemetNonFerme,

  // --- alertes ---

  /// Meme adresse qu'une ligne plus haut : les deux lignes forment un foyer.
  doublonAdresse,

  /// Meme personne (adresse, nom, prenom, naissance) qu'une ligne plus haut :
  /// elle ne sera importee qu'une fois.
  doublonPersonne,

  /// Naissance dans le futur.
  dateFuture,

  /// Plus jeune que l'age minimum du serveur.
  ageTropJeune,

  /// Un adulte nomme (tuteur, adulte, enseignant) plus jeune que la majorite
  /// du serveur.
  adulteTropJeune,

  /// Un foyer dont tous les eleves sont mineurs et ou aucun adulte n'est nomme.
  foyerSansAdulte,
}

/// Les motifs du serveur, par ordre de [CodeProbleme].
const Map<String, CodeProbleme> motifsServeur = <String, CodeProbleme>{
  'empty_row': CodeProbleme.ligneVide,
  'column_count_mismatch': CodeProbleme.colonnesDifferentes,
  'test_row': CodeProbleme.ligneTest,
  'missing_person_name': CodeProbleme.personneSansNom,
  'missing_email': CodeProbleme.emailManquant,
  'invalid_email': CodeProbleme.emailInvalide,
  'invalid_birth_date': CodeProbleme.dateInvalide,
};

/// Les codes qui refusent la ligne.
const Set<CodeProbleme> codesRefus = <CodeProbleme>{
  CodeProbleme.ligneVide,
  CodeProbleme.colonnesDifferentes,
  CodeProbleme.ligneTest,
  CodeProbleme.personneSansNom,
  CodeProbleme.emailManquant,
  CodeProbleme.emailInvalide,
  CodeProbleme.dateInvalide,
  CodeProbleme.refusServeur,
};

/// Un probleme sur une ligne.
@immutable
class ProblemeLigne {
  /// Cree le probleme. [ligne] vaut 1 pour un probleme de fichier (l'en-tete).
  const ProblemeLigne({
    required this.source,
    required this.ligne,
    required this.code,
    this.autreLigne,
  });

  /// Le fichier.
  final SourceImport source;

  /// Le numero de ligne (l'en-tete est la ligne 1).
  final int ligne;

  /// Ce qui ne va pas.
  final CodeProbleme code;

  /// Pour un doublon : la ligne plus haut avec laquelle il se confond.
  final int? autreLigne;

  /// Refus ou alerte.
  GraviteProbleme get gravite => codesRefus.contains(code)
      ? GraviteProbleme.refus
      : code == CodeProbleme.enteteEmailAbsent ||
            code == CodeProbleme.guillemetNonFerme
      ? GraviteProbleme.refus
      : GraviteProbleme.alerte;

  /// Un probleme de fichier entier (pas d'une ligne).
  bool get deFichier =>
      code == CodeProbleme.enteteEmailAbsent ||
      code == CodeProbleme.guillemetNonFerme;

  @override
  bool operator ==(Object other) =>
      other is ProblemeLigne &&
      other.source == source &&
      other.ligne == ligne &&
      other.code == code;

  @override
  int get hashCode => Object.hash(source, ligne, code);
}

/// Le genre d'une personne lue.
enum GenrePersonne {
  /// Un eleve.
  eleve,

  /// Un tuteur.
  tuteur,

  /// Un adulte qui s'inscrit lui-meme.
  adulte,

  /// Un enseignant.
  enseignant,
}

/// Une personne lue dans une ligne acceptee.
@immutable
class PersonneApercu {
  /// Cree la personne.
  const PersonneApercu({
    required this.prenom,
    required this.nom,
    required this.genre,
    required this.ligne,
    this.naissance,
  });

  /// Son prenom.
  final String prenom;

  /// Son nom.
  final String nom;

  /// Son genre.
  final GenrePersonne genre;

  /// La ligne d'ou elle vient.
  final int ligne;

  /// Sa date de naissance, si le fichier la porte.
  final DateTime? naissance;
}

/// Un foyer qui sera cree : une adresse e-mail et les personnes qu'elle porte.
@immutable
class FoyerApercu {
  /// Cree le foyer.
  const FoyerApercu({required this.email, required this.personnes});

  /// L'adresse, en minuscules : la cle du foyer au serveur.
  final String email;

  /// Les personnes, dans l'ordre des lignes.
  final List<PersonneApercu> personnes;

  /// Le prenom de la personne qui recoit le mot : le premier tuteur, adulte ou
  /// enseignant ; sinon le premier eleve.
  String get destinataire {
    for (final PersonneApercu p in personnes) {
      if (p.genre != GenrePersonne.eleve) return p.prenom;
    }
    return personnes.isEmpty ? '' : personnes.first.prenom;
  }

  /// Les prenoms des eleves.
  List<String> get prenomsEleves => <String>[
    for (final PersonneApercu p in personnes)
      if (p.genre == GenrePersonne.eleve) p.prenom,
  ];
}

/// Les bornes d'age du serveur (tranches d'age), lues, jamais ecrites ici.
@immutable
class BornesAge {
  /// Cree les bornes.
  const BornesAge({this.minimum, this.adulte});

  /// Aucune borne connue : aucun controle d'age.
  static const BornesAge aucune = BornesAge();

  /// L'age minimum d'un eleve.
  final int? minimum;

  /// L'age a partir duquel on est adulte.
  final int? adulte;
}

/// Le resultat de l'analyse des deux fichiers.
@immutable
class ApercuLocal {
  /// Cree l'apercu.
  const ApercuLocal({
    required this.problemes,
    required this.foyers,
    required this.lignesEleves,
    required this.lignesEnseignants,
    required this.lignesRefusees,
  });

  /// L'apercu de rien.
  static const ApercuLocal vide = ApercuLocal(
    problemes: <ProblemeLigne>[],
    foyers: <FoyerApercu>[],
    lignesEleves: 0,
    lignesEnseignants: 0,
    lignesRefusees: 0,
  );

  /// Tous les problemes, par fichier puis par ligne.
  final List<ProblemeLigne> problemes;

  /// Les foyers qui seront crees (lignes acceptees seulement).
  final List<FoyerApercu> foyers;

  /// Le nombre de lignes de donnees lues dans le fichier des eleves.
  final int lignesEleves;

  /// Le nombre de lignes de donnees lues dans le fichier des enseignants.
  final int lignesEnseignants;

  /// Le nombre de lignes distinctes qui seront refusees.
  final int lignesRefusees;

  /// Le nombre de personnes qui seront importees.
  int get personnes =>
      foyers.fold(0, (int total, FoyerApercu f) => total + f.personnes.length);

  /// Les alertes (lignes importees mais a regarder).
  List<ProblemeLigne> get alertes => <ProblemeLigne>[
    for (final ProblemeLigne p in problemes)
      if (p.gravite == GraviteProbleme.alerte) p,
  ];

  /// Les refus.
  List<ProblemeLigne> get refus => <ProblemeLigne>[
    for (final ProblemeLigne p in problemes)
      if (p.gravite == GraviteProbleme.refus) p,
  ];

  /// Vrai quand un fichier entier est inutilisable (rien ne peut partir).
  bool get fichierBloque => problemes.any((ProblemeLigne p) => p.deFichier);

  /// Vrai quand rien ne sera importe.
  bool get rienAImporter => foyers.isEmpty;
}

final RegExp _adresse = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final RegExp _jourMoisAnnee = RegExp(
  r'^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/([0-9]{4})$',
);
final RegExp _adresseEssai = RegExp(r'^(test|demo|dummy)@');
const Set<String> _motsEssai = <String>{
  'test',
  'testing',
  'demo',
  'dummy',
  'test row',
  'ligne test',
  'dummy row',
  'demo row',
  'sample row',
};

/// Lit une date `JJ/MM/AAAA` stricte, ou `null`.
DateTime? lireDateNaissance(String texte) {
  final RegExpMatch? m = _jourMoisAnnee.firstMatch(texte);
  if (m == null) return null;
  final int jour = int.parse(m[1]!);
  final int mois = int.parse(m[2]!);
  final int annee = int.parse(m[3]!);
  final DateTime d = DateTime(annee, mois, jour);
  return d.year == annee && d.month == mois && d.day == jour ? d : null;
}

/// L'age en annees revolues de [naissance] au [jour].
int ageAu(DateTime naissance, DateTime jour) {
  int age = jour.year - naissance.year;
  if (jour.month < naissance.month ||
      (jour.month == naissance.month && jour.day < naissance.day)) {
    age--;
  }
  return age;
}

String _minuscules(String s) => s.trim().toLowerCase();

String _cleSpaces(String s) =>
    s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

/// L'analyse des deux fichiers.
abstract final class AnalyseInscriptions {
  /// Analyse [eleves] et [enseignants] au [jour], avec les [bornes] d'age.
  static ApercuLocal analyser({
    required TableCsv eleves,
    required TableCsv enseignants,
    required DateTime jour,
    BornesAge bornes = BornesAge.aucune,
  }) {
    final List<ProblemeLigne> problemes = <ProblemeLigne>[];
    final Map<String, List<PersonneApercu>> parAdresse =
        <String, List<PersonneApercu>>{};
    final Map<String, int> premiereLigneAdresse = <String, int>{};
    final Map<String, int> premiereLignePersonne = <String, int>{};
    final Set<(SourceImport, int)> lignesRefusees = <(SourceImport, int)>{};

    void signaler(
      SourceImport source,
      int ligne,
      CodeProbleme code, {
      int? autre,
    }) {
      final ProblemeLigne p = ProblemeLigne(
        source: source,
        ligne: ligne,
        code: code,
        autreLigne: autre,
      );
      if (problemes.contains(p)) return;
      problemes.add(p);
      if (p.gravite == GraviteProbleme.refus) {
        lignesRefusees.add((source, ligne));
      }
    }

    void adresseVue(String email, int ligne, SourceImport source) {
      final int? avant = premiereLigneAdresse[email];
      if (avant == null) {
        premiereLigneAdresse[email] = ligne;
        parAdresse[email] = <PersonneApercu>[];
      } else {
        signaler(source, ligne, CodeProbleme.doublonAdresse, autre: avant);
      }
    }

    void ajouter(
      String email,
      SourceImport source,
      PersonneApercu p,
      String cleFoyer,
    ) {
      final String cle = '$email\u001f$cleFoyer';
      final int? avant = premiereLignePersonne[cle];
      if (avant != null) {
        signaler(source, p.ligne, CodeProbleme.doublonPersonne, autre: avant);
        return;
      }
      premiereLignePersonne[cle] = p.ligne;
      parAdresse[email]!.add(p);
      final DateTime? n = p.naissance;
      if (n != null) {
        if (n.isAfter(jour)) {
          signaler(source, p.ligne, CodeProbleme.dateFuture);
        } else {
          final int age = ageAu(n, jour);
          if (p.genre == GenrePersonne.eleve) {
            final int? min = bornes.minimum;
            if (min != null && age < min) {
              signaler(source, p.ligne, CodeProbleme.ageTropJeune);
            }
          } else {
            final int? adulte = bornes.adulte;
            if (adulte != null && age < adulte) {
              signaler(source, p.ligne, CodeProbleme.adulteTropJeune);
            }
          }
        }
      }
    }

    // --- eleves ---
    if (!eleves.estVide) {
      if (eleves.guillemetNonFerme) {
        signaler(SourceImport.eleves, 1, CodeProbleme.guillemetNonFerme);
      }
      final List<String> entetes = eleves.entetes.map(_minuscules).toList();
      if (!entetes.contains('email')) {
        signaler(SourceImport.eleves, 1, CodeProbleme.enteteEmailAbsent);
      } else {
        for (final LigneCsv l in eleves.lignes) {
          _ligneEleve(
            l,
            entetes,
            signaler: signaler,
            adresseVue: adresseVue,
            ajouter: ajouter,
          );
        }
      }
    }

    // --- enseignants ---
    if (!enseignants.estVide) {
      if (enseignants.guillemetNonFerme) {
        signaler(SourceImport.enseignants, 1, CodeProbleme.guillemetNonFerme);
      }
      final List<String> entetes = enseignants.entetes
          .map(_minuscules)
          .toList();
      if (!entetes.contains('email')) {
        signaler(SourceImport.enseignants, 1, CodeProbleme.enteteEmailAbsent);
      } else {
        for (final LigneCsv l in enseignants.lignes) {
          _ligneEnseignant(
            l,
            entetes,
            signaler: signaler,
            adresseVue: adresseVue,
            ajouter: ajouter,
          );
        }
      }
    }

    final List<FoyerApercu> foyers = <FoyerApercu>[];
    parAdresse.forEach((String email, List<PersonneApercu> personnes) {
      if (personnes.isEmpty) return;
      foyers.add(FoyerApercu(email: email, personnes: personnes));
      final bool sansAdulte = personnes.every(
        (PersonneApercu p) => p.genre == GenrePersonne.eleve,
      );
      final int? adulte = bornes.adulte;
      if (sansAdulte && adulte != null) {
        final bool tousMineurs = personnes.every((PersonneApercu p) {
          final DateTime? n = p.naissance;
          return n != null && ageAu(n, jour) < adulte;
        });
        if (tousMineurs) {
          signaler(
            SourceImport.eleves,
            personnes.first.ligne,
            CodeProbleme.foyerSansAdulte,
          );
        }
      }
    });

    problemes.sort((ProblemeLigne a, ProblemeLigne b) {
      final int s = a.source.index.compareTo(b.source.index);
      if (s != 0) return s;
      final int l = a.ligne.compareTo(b.ligne);
      return l != 0 ? l : a.code.index.compareTo(b.code.index);
    });
    return ApercuLocal(
      problemes: problemes,
      foyers: foyers,
      lignesEleves: eleves.lignes.length,
      lignesEnseignants: enseignants.lignes.length,
      lignesRefusees: lignesRefusees.length,
    );
  }

  static bool _ligneEssai(List<String> cellules) {
    for (final String c in cellules) {
      final String m = _minuscules(c);
      if (_motsEssai.contains(m) || _adresseEssai.hasMatch(m)) return true;
    }
    return false;
  }

  static void _ligneEleve(
    LigneCsv l,
    List<String> entetes, {
    required void Function(SourceImport, int, CodeProbleme, {int? autre})
    signaler,
    required void Function(String, int, SourceImport) adresseVue,
    required void Function(String, SourceImport, PersonneApercu, String)
    ajouter,
  }) {
    const SourceImport src = SourceImport.eleves;
    if (l.estVide) {
      signaler(src, l.numero, CodeProbleme.ligneVide);
      return;
    }
    if (l.cellules.length != entetes.length) {
      signaler(src, l.numero, CodeProbleme.colonnesDifferentes);
      return;
    }
    final List<String> cellules = l.cellules
        .map((String c) => c.trim())
        .toList();
    bool refus = false;

    // Dates de naissance : toute cellule non vide sous un titre « date de
    // naissance » doit etre valide, sinon la ligne est refusee.
    for (int i = 0; i < entetes.length; i++) {
      if (entetes[i].contains('date de naissance') &&
          cellules[i].isNotEmpty &&
          lireDateNaissance(cellules[i]) == null) {
        signaler(src, l.numero, CodeProbleme.dateInvalide);
        refus = true;
      }
    }

    // Adresses : toute cellule non vide sous « email » ou « email du tuteur »
    // doit etre une adresse.
    for (int i = 0; i < entetes.length; i++) {
      if ((entetes[i] == 'email' || entetes[i] == 'email du tuteur') &&
          cellules[i].isNotEmpty &&
          !_adresse.hasMatch(cellules[i].toLowerCase())) {
        signaler(src, l.numero, CodeProbleme.emailInvalide);
        refus = true;
      }
    }

    if (_ligneEssai(cellules)) {
      signaler(src, l.numero, CodeProbleme.ligneTest);
      refus = true;
    }

    // Les personnes : un titre « nom... » rempli et son « prenom... » du meme
    // rang rempli.
    final List<_Lue> lues = <_Lue>[];
    final String formulaire = () {
      final int i = entetes.indexWhere(
        (String e) => e.startsWith('pour qui faites-vous cette inscription'),
      );
      return i < 0 ? '' : cellules[i].toLowerCase();
    }();
    for (int i = 0; i < entetes.length; i++) {
      final String titre = entetes[i];
      if (!titre.startsWith('nom') || cellules[i].isEmpty) continue;
      final String titrePrenom = titre.replaceFirst(RegExp('^nom'), 'prénom');
      final int rang = entetes
          .sublist(0, i + 1)
          .where((String e) => e == titre)
          .length;
      int vus = 0;
      int indexPrenom = -1;
      for (int k = 0; k < entetes.length; k++) {
        if (entetes[k] == titrePrenom && ++vus == rang) {
          indexPrenom = k;
          break;
        }
      }
      if (indexPrenom < 0 || cellules[indexPrenom].isEmpty) continue;
      int? indexNaissance;
      for (int k = i + 1; k < entetes.length; k++) {
        if (entetes[k].contains('date de naissance')) {
          indexNaissance = k;
          break;
        }
        if (entetes[k].startsWith('nom')) break;
      }
      final GenrePersonne genre;
      if (titre.startsWith("nom de l'élève") ||
          titre.startsWith("nom de l'eleve")) {
        genre = GenrePersonne.eleve;
      } else if (titre.startsWith('nom du tuteur')) {
        genre = GenrePersonne.tuteur;
      } else if (titre == 'nom' &&
          formulaire.contains('moi') &&
          !formulaire.contains('enfant')) {
        genre = GenrePersonne.adulte;
      } else if (titre == 'nom') {
        genre = GenrePersonne.tuteur;
      } else {
        genre = GenrePersonne.eleve;
      }
      lues.add(
        _Lue(
          PersonneApercu(
            prenom: cellules[indexPrenom],
            nom: cellules[i],
            genre: genre,
            ligne: l.numero,
            naissance: indexNaissance == null
                ? null
                : lireDateNaissance(cellules[indexNaissance]),
          ),
        ),
      );
    }
    if (lues.isEmpty) {
      signaler(src, l.numero, CodeProbleme.personneSansNom);
      refus = true;
    }

    // L'adresse du foyer : celle du tuteur si elle est donnee, sinon la
    // premiere colonne « email ».
    final int iTuteur = entetes.indexOf('email du tuteur');
    final int iEmail = entetes.indexOf('email');
    String email = iTuteur >= 0 ? cellules[iTuteur].toLowerCase() : '';
    if (email.isEmpty && iEmail >= 0) email = cellules[iEmail].toLowerCase();
    if (email.isEmpty) {
      final bool uneAutre = <int>[
        for (int i = 0; i < entetes.length; i++)
          if (entetes[i] == 'email') i,
      ].any((int i) => cellules[i].isNotEmpty);
      if (!uneAutre || iEmail < 0) {
        signaler(src, l.numero, CodeProbleme.emailManquant);
      }
      refus = true;
    }
    if (refus) return;

    adresseVue(email, l.numero, src);
    for (final _Lue lue in lues) {
      final PersonneApercu p = lue.personne;
      ajouter(
        email,
        src,
        p,
        '${_cleSpaces(p.nom)}\u001f${_cleSpaces(p.prenom)}\u001f'
        '${p.naissance?.toIso8601String() ?? ''}',
      );
    }
  }

  static void _ligneEnseignant(
    LigneCsv l,
    List<String> entetes, {
    required void Function(SourceImport, int, CodeProbleme, {int? autre})
    signaler,
    required void Function(String, int, SourceImport) adresseVue,
    required void Function(String, SourceImport, PersonneApercu, String)
    ajouter,
  }) {
    const SourceImport src = SourceImport.enseignants;
    if (l.estVide) {
      signaler(src, l.numero, CodeProbleme.ligneVide);
      return;
    }
    if (l.cellules.length != entetes.length) {
      signaler(src, l.numero, CodeProbleme.colonnesDifferentes);
      return;
    }
    final List<String> cellules = l.cellules
        .map((String c) => c.trim())
        .toList();
    final int iEmail = entetes.indexOf('email');
    final int iPrenom = entetes.indexOf('prénom');
    final int iNom = entetes.indexOf('nom');
    bool refus = false;
    final String email = cellules[iEmail].toLowerCase();
    if (email.isNotEmpty && !_adresse.hasMatch(email)) {
      signaler(src, l.numero, CodeProbleme.emailInvalide);
      return;
    }
    if (_ligneEssai(cellules)) {
      signaler(src, l.numero, CodeProbleme.ligneTest);
      refus = true;
    }
    if (iPrenom < 0 || cellules[iPrenom].isEmpty) {
      signaler(src, l.numero, CodeProbleme.personneSansNom);
      refus = true;
    }
    if (email.isEmpty) {
      signaler(src, l.numero, CodeProbleme.emailManquant);
      refus = true;
    }
    if (refus) return;
    adresseVue(email, l.numero, src);
    final String nom = iNom < 0 ? '' : cellules[iNom];
    ajouter(
      email,
      src,
      PersonneApercu(
        prenom: cellules[iPrenom],
        nom: nom,
        genre: GenrePersonne.enseignant,
        ligne: l.numero,
      ),
      'enseignant\u001f${_cleSpaces(nom)}\u001f${_cleSpaces(cellules[iPrenom])}',
    );
  }
}

class _Lue {
  const _Lue(this.personne);
  final PersonneApercu personne;
}
