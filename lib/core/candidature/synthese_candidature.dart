// La synthese d'une candidature (etage 2 du dossier, BE-DOSSIER, coordinateur,
// 16/11/2026 ; reprise telle quelle par les colonnes de la liste) : un
// tableau a deux colonnes, un libelle court a gauche et une valeur courte a
// droite, une ligne par critere, jamais la phrase du candidat.
//
// Le directeur lit plus de mille dossiers : chaque valeur est un ou plusieurs
// mots-cles separes par « · ». Les mots viennent d'une table de correspondance
// (code de reponse vers mot court, `recrutement.dossier3.synthese`), jamais
// d'un texte invente ; un code que la table ne connait pas n'est pas montre.
// Aucune donnee nouvelle : tout vient des reponses du dossier. Le dossier ne
// fait que l'afficher.
library;

import '../../features/candidature/libelles_parcours.dart';
import '../../features/candidature/modele_questions.dart';
import '../i18n/isolat_bidi.dart';
import '../i18n/strings.g.dart';
import 'disponibilites_declarees.dart';
import 'modeles_candidature_detail.dart';

/// Une ligne de la synthese : son libelle court et sa valeur courte.
typedef LigneSynthese = ({String cle, String valeur});

/// Le mot-cle de [code] dans la table de correspondance, ou `null`.
typedef _Mot = String? Function(String code);

String? _motMemorisation(String code) {
  final v = t.recrutement.dossier3.synthese.memorisationValeurs;
  return switch (code) {
    'aucune' => v.aucune,
    'moins_10_juz' => v.moins_10_juz,
    'de_10_a_29_juz' => v.de_10_a_29_juz,
    'coran_entier' => v.coran_entier,
    _ => null,
  };
}

String? _motIjaza(String code) {
  final v = t.recrutement.dossier3.synthese.ijazaValeurs;
  return switch (code) {
    'oui' => v.oui,
    'pret_test' => v.pret_test,
    'non' => v.non,
    _ => null,
  };
}

String? _motPublic(String code) {
  final v = t.recrutement.dossier3.synthese.publicValeurs;
  return switch (code) {
    '6_9' => v.k69,
    '10_13' => v.k1013,
    '14_17' => v.k1417,
    'adultes' => v.adultes,
    _ => null,
  };
}

/// En arabe, un texte qui porte des chiffres ou des heures s'isole dans son
/// propre sens de lecture : les chiffres restent latins et ne se retournent
/// pas. Dans les autres langues, le texte reste nu.
String _iso(String texte) =>
    LocaleSettings.currentLocale == AppLocale.ar ? isolerSens(texte) : texte;

String _jourCourt(int jour) {
  final j = t.recrutement.dossier3.synthese.jours;
  return switch (jour) {
    1 => j.j1,
    2 => j.j2,
    3 => j.j3,
    4 => j.j4,
    5 => j.j5,
    6 => j.j6,
    _ => j.j7,
  };
}

/// Le nom court d'une langue : « Poular (peul, fulfulde) » se dit « Poular ».
String? _langueCourte(String code) {
  final String? nom = nomDeLangue(code);
  if (nom == null) return null;
  final int parenthese = nom.indexOf(' (');
  return parenthese < 0 ? nom : nom.substring(0, parenthese);
}

List<String> _codes(Object? reponse) => <String>[
  if (reponse is String) reponse,
  if (reponse is List)
    for (final Object? x in reponse)
      if (x is String) x,
];

/// Les mots-cles de [reponse], par la table [mot], dans l'ordre, sans doublon.
List<String> _mots(Object? reponse, _Mot mot) {
  final List<String> mots = <String>[];
  for (final String code in _codes(reponse)) {
    final String? m = mot(code);
    if (m != null && !mots.contains(m)) mots.add(m);
  }
  return mots;
}

/// « Lun · Mer : 18 h, 19 h » : un groupe de jours qui ont les memes heures,
/// une ligne par groupe. Les heures sont celles que la personne a declarees,
/// telles quelles.
List<String> _disponibilites(Object? reponse, Object? publics) {
  final DisponibilitesDeclarees dispo = DisponibilitesDeclarees.depuisPlages(
    reponse,
    dureeMinutes: dureeDeclareeDe(publics),
  );
  final Map<String, List<int>> parHeures = <String, List<int>>{};
  for (final int jour in dispo.jours) {
    (parHeures[libelleHeures(dispo.debuts(jour))] ??= <int>[]).add(jour);
  }
  final String separateur = t.admin.candidatures.historique.separateur;
  return <String>[
    for (final MapEntry<String, List<int>> e in parHeures.entries)
      t.recrutement.dossier3.synthese.heuresDe(
        jours: e.value.map(_jourCourt).join(separateur),
        heures: e.key,
      ),
  ];
}

/// La synthese de [detail] : une ligne par critere, dans l'ordre. Une ligne
/// sans reponse n'est pas rendue. [nomsOperateurs] donne le nom des operateurs
/// de monnaie mobile du pays de versement.
List<LigneSynthese> syntheseDuDossier(
  DetailCandidature detail, {
  Map<String, String> nomsOperateurs = const <String, String>{},
}) {
  final DocumentReponses? doc = detail.dernieresReponses;
  if (doc == null) return const <LigneSynthese>[];
  final Map<String, Object?> r = doc.reponses;
  final String separateur = t.admin.candidatures.historique.separateur;
  final s = t.recrutement.dossier3.synthese;

  // Les langues : la langue maternelle d'abord, puis celles des explications.
  final List<String> langues = <String>[];
  for (final String code in <String>[
    ..._codes(r['langueMaternelle']),
    ..._codes(r['languesExplication']),
  ]) {
    final String? nom = _langueCourte(code);
    if (nom != null && !langues.contains(nom)) langues.add(nom);
  }

  // Le versement : le pays, puis les moyens nommes (jamais un code, jamais un
  // nombre : un moyen dont le nom n'est pas connu ne se dit pas).
  final List<String> versement = <String>[
    ..._codes(r['paysVersement']).take(1).map(nomDePaysConnu).nonNulls,
    if (_codes(r['paysVersement']).isEmpty)
      ..._codes(r['paysResidence']).take(1).map(nomDePaysConnu).nonNulls,
    if (r['compteBancaire'] == true) t.admin.candidatures.moyens.virement,
    for (final String code in _codes(r['operateurs'])) ?nomsOperateurs[code],
  ];

  String? isole(List<String> mots, {bool chiffres = false}) {
    if (mots.isEmpty) return null;
    final String texte = mots.join(separateur);
    return chiffres ? _iso(texte) : texte;
  }

  final List<String> dispos = _disponibilites(
    r['disponibilitesDeclarees'],
    r['publics'],
  );
  final List<({String cle, String? valeur})> lignes =
      <({String cle, String? valeur})>[
        (cle: s.langues, valeur: isole(langues)),
        (
          cle: s.memorisation,
          valeur: isole(
            _mots(r['niveauMemorisationDeclare'], _motMemorisation),
            chiffres: true,
          ),
        ),
        (cle: s.ijaza, valeur: isole(_mots(r['ijazaPresentable'], _motIjaza))),
        (
          cle: s.disponibilites,
          valeur: dispos.isEmpty ? null : dispos.map(_iso).join('\n'),
        ),
        (cle: s.versement, valeur: isole(versement)),
        (
          cle: s.public,
          valeur: isole(_mots(r['publics'], _motPublic), chiffres: true),
        ),
      ];
  return <LigneSynthese>[
    for (final ({String cle, String? valeur}) l in lignes)
      if (l.valeur != null) (cle: l.cle, valeur: l.valeur!),
  ];
}
