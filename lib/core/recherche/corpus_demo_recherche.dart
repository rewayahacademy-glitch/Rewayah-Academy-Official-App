import 'modeles_recherche.dart';
import 'moteur_recherche_demo.dart';

const List<String> _prenoms = <String>[
  'Mariam',
  'Yusuf',
  'Amina',
  'Ibrahim',
  'Khadija',
  'Oumar',
  'Fatoumata',
  'Idriss',
];

const List<String> _sourates = <String>[
  'Al-Fatiha',
  'Al-Baqara',
  'Al Imran',
  'An-Nās',
  'Al-Ikhlas',
  'Al-Falaq',
  'Ya-Sin',
  'Al-Kawthar',
];

const List<String> _jours = <String>[
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];

/// Plusieurs milliers de classes fictives (« Classe Al-Fātiḥa 12 »), pour
/// mesurer le comportement sur un volume sans serveur (spec §10.2). Donnees
/// de demonstration : aucune n'est une donnee reelle.
List<EntreeCorpusDemo> corpusClassesDemo({
  int nombre = 3000,
}) => <EntreeCorpusDemo>[
  for (int i = 0; i < nombre; i++)
    EntreeCorpusDemo(
      type: TypeResultat.classe,
      reference: 'classe-demo-$i',
      titre:
          'Classe ${_sourates[i % _sourates.length]} ${i ~/ _sourates.length + 1}',
      contexte:
          'Votre classe · ${_jours[i % _jours.length]} · ${16 + i % 5}\u00a0h',
      cible: CibleRecherche(
        kind: KindCible.classe,
        reference: 'classe-demo-$i',
      ),
    ),
];

/// Plusieurs milliers de supports fictifs (« Al-Fātiḥa, leçon 12 »).
List<EntreeCorpusDemo> corpusSupportsDemo({
  int nombre = 3000,
}) => <EntreeCorpusDemo>[
  for (int i = 0; i < nombre; i++)
    EntreeCorpusDemo(
      type: TypeResultat.support,
      reference: 'support-demo-$i',
      titre:
          '${_sourates[i % _sourates.length]}, leçon ${i ~/ _sourates.length + 1}',
      contexte: i.isEven
          ? 'Coran · Sourate ${i % 114 + 1}'
          : 'Lecture · Support de classe',
      cible: CibleRecherche(
        kind: KindCible.support,
        reference: 'support-demo-$i',
      ),
    ),
];

/// Plusieurs milliers d'eleves fictifs en projection pedagogique.
List<EntreeCorpusDemo> corpusElevesClasseDemo({
  int nombre = 3000,
}) => <EntreeCorpusDemo>[
  for (int i = 0; i < nombre; i++)
    EntreeCorpusDemo(
      type: TypeResultat.eleveClasse,
      reference: 'eleve-demo-$i',
      titre: '${_prenoms[i % _prenoms.length]} ${i ~/ _prenoms.length + 1}',
      contexte:
          'Élève de la classe ${_sourates[i % _sourates.length]} · Fiche pédagogique',
      cible: CibleRecherche(kind: KindCible.eleve, reference: 'eleve-demo-$i'),
    ),
];
