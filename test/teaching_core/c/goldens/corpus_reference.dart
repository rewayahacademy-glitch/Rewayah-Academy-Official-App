import 'dart:convert';
import 'dart:io';

import 'package:rewayah_academy/core/tc_coran/page_mushaf_vm.dart';
import 'package:rewayah_academy/core/tc_coran/port_corpus_coran.dart';

/// Le corpus de reference des goldens, lu depuis son fichier.
///
/// **Le fichier fait foi, pas ce code.** Un golden qui vit dans un `.dart` se
/// modifie en meme temps que ce qu'il verifie, sans que le diff le montre. Un
/// golden qui vit dans un `.json` se relit, se compare et se discute : le
/// fichier porte d'ailleurs sa propre note de provenance, et dit ce qui est
/// reel et ce qui est construit.
class CorpusReference {
  CorpusReference._(this._racine);

  /// Charge le corpus depuis `test/teaching_core/c/goldens/`.
  factory CorpusReference.charger() {
    final File fichier = File(_chemin);
    if (!fichier.existsSync()) {
      throw StateError('golden introuvable : $_chemin');
    }
    final Object? lu = jsonDecode(fichier.readAsStringSync());
    if (lu is! Map<String, dynamic>) {
      throw StateError('golden illisible : $_chemin');
    }
    return CorpusReference._(lu);
  }

  static const String _chemin =
      'test/teaching_core/c/goldens/corpus_reference.json';

  final Map<String, dynamic> _racine;

  /// Le nombre de pages du corpus reduit.
  int get nombrePages => _racine['nombrePages'] as int;

  /// Les sourates declarees.
  List<SourateVM> get sourates => <SourateVM>[
    for (final Object? brut in _racine['sourates']! as List<Object?>)
      _sourate(brut! as Map<String, dynamic>),
  ];

  /// Les pages du corpus, dans l'ordre.
  List<PageCorpus> get pages => <PageCorpus>[
    for (final Object? brut in _racine['pages']! as List<Object?>)
      _page(brut! as Map<String, dynamic>),
  ];

  /// Une page par son numero.
  PageCorpus page(int numero) =>
      pages.firstWhere((PageCorpus p) => p.numero == numero);

  /// Les compositions attendues, page par page.
  List<CompositionAttendue> get compositions => <CompositionAttendue>[
    for (final Object? brut in _racine['compositionAttendue']! as List<Object?>)
      CompositionAttendue._(brut! as Map<String, dynamic>),
  ];

  static SourateVM _sourate(Map<String, dynamic> brut) => SourateVM(
    numero: brut['numero'] as int,
    nomArabe: brut['nomArabe'] as String,
    nomTranslittere: brut['nomTranslittere'] as String,
    mecquoise: brut['mecquoise'] as bool,
    nombreVersets: brut['nombreVersets'] as int,
  );

  static PageCorpus _page(Map<String, dynamic> brut) {
    final int numero = brut['numero'] as int;
    return PageCorpus(
      numero: numero,
      juzNumero: brut['juz'] as int?,
      versets: <VersetCorpus>[
        for (final Object? v in brut['versets']! as List<Object?>)
          _verset(v! as Map<String, dynamic>, numero),
      ],
    );
  }

  /// Le texte est un marqueur neutre : voir la note du fichier golden.
  static VersetCorpus _verset(Map<String, dynamic> brut, int page) {
    final int sourate = brut['sourate'] as int;
    final int numero = brut['numero'] as int;
    return VersetCorpus(
      sourate: sourate,
      numero: numero,
      texte: 'texte $sourate:$numero',
      pageNumero: page,
    );
  }
}

/// Ce que le moteur doit produire pour une page de reference.
class CompositionAttendue {
  CompositionAttendue._(this._brut);

  final Map<String, dynamic> _brut;

  /// La page concernee.
  int get page => _brut['page'] as int;

  /// Le cote attendu.
  CoteDePage get cote =>
      _brut['cote'] == 'droite' ? CoteDePage.droite : CoteDePage.gauche;

  /// La page qui lui fait face dans une ouverture.
  int get ouvertureAvec => _brut['ouvertureAvec'] as int;

  /// Les sections attendues, dans l'ordre.
  List<SectionAttendue> get sections => <SectionAttendue>[
    for (final Object? brut in _brut['sections']! as List<Object?>)
      SectionAttendue._(brut! as Map<String, dynamic>),
  ];
}

/// Une section de sourate attendue sur une page.
class SectionAttendue {
  SectionAttendue._(this._brut);

  final Map<String, dynamic> _brut;

  /// Le rang de la sourate.
  int get sourate => _brut['sourate'] as int;

  /// Vrai quand la sourate commence sur cette page.
  bool get commenceLaSourate => _brut['commenceLaSourate'] as bool;

  /// Le premier verset de la section.
  int get premier => _brut['premier'] as int;

  /// Le dernier verset de la section.
  int get dernier => _brut['dernier'] as int;
}
