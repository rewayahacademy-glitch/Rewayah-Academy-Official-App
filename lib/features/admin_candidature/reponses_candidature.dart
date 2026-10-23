// Les reponses d'une candidature, mises en mots pour la direction (`ADM-21`).
//
// Le serveur rend des **codes** (`hafs`, `coran_entier`, `Africa/Dakar`...),
// jamais des libelles : chaque reponse se dit par les textes du questionnaire
// (`recrutement.parcours.q.<champ>`, en francais et en arabe), ceux que le
// candidat a lus en repondant. Un code sans texte ne s'affiche pas tel quel :
// la ligne est omise plutot que montree en code brut, et un test verifie que
// chaque champ et chaque option de `salle-examen-1` ont leurs textes.
//
// Rien n'est calcule : ce fichier met en mots, il ne juge pas une reponse.
library;

import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidature_detail.dart';
import '../../core/i18n/strings.g.dart';
import '../candidature/libelles_parcours.dart';
import '../candidature/modele_questions.dart';
import '../candidature/recapitulatif_etape.dart';

/// Les champs de `salle-examen-1` dans l'ordre du questionnaire, avec la carte
/// (le theme) qui les porte.
const List<({String code, String carte})> champsDuQuestionnaire =
    <({String code, String carte})>[
      (code: 'langueMaternelle', carte: 'langues'),
      (code: 'languesExplication', carte: 'langues'),
      (code: 'niveauMemorisationDeclare', carte: 'recitation'),
      (code: 'niveauLectureTajwid', carte: 'recitation'),
      (code: 'riwayat', carte: 'recitation'),
      (code: 'ijazaPresentable', carte: 'recitation'),
      (code: 'experienceDebutants', carte: 'recitation'),
      (code: 'disponibilitesDeclarees', carte: 'disponibilites'),
      (code: 'fuseauIana', carte: 'disponibilites'),
      (code: 'classesSouhaitees', carte: 'disponibilites'),
      (code: 'debutPossible', carte: 'disponibilites'),
      (code: 'publics', carte: 'publics'),
      (code: 'paysResidence', carte: 'versement'),
      (code: 'paysVersement', carte: 'versement'),
      (code: 'compteBancaire', carte: 'versement'),
      (code: 'operateurs', carte: 'versement'),
      (code: 'moyensAccessibles', carte: 'versement'),
    ];

/// Une reponse mise en mots : le nom court du champ, ce qui a ete repondu, et,
/// pour les disponibilites, une ligne par groupe de jours.
class LigneReponse {
  /// Cree la ligne.
  const LigneReponse({
    required this.code,
    required this.libelle,
    this.valeur,
    this.groupes = const <String>[],
  });

  /// Le code du champ (cle des tests, jamais affiche).
  final String code;

  /// Le nom court du champ.
  final String libelle;

  /// Ce que la personne a repondu.
  final String? valeur;

  /// Les groupes de jours des disponibilites : « Lundi, mercredi : 18 h ».
  final List<String> groupes;
}

/// Les reponses d'une carte (un theme du questionnaire).
class CarteReponses {
  /// Cree la carte.
  const CarteReponses({
    required this.code,
    required this.titre,
    required this.lignes,
  });

  /// Le code de la carte.
  final String code;

  /// Le titre neutre de la carte.
  final String titre;

  /// Les reponses de la carte, dans l'ordre du questionnaire.
  final List<LigneReponse> lignes;
}

/// Les reponses de [document], par carte, mises en mots.
///
/// [nomsOperateurs] donne le nom des operateurs de monnaie mobile du pays de
/// versement (`options_paiement_confirmees`). Sans lui, les moyens se disent
/// par leur nombre : jamais un code d'operateur.
List<CarteReponses> cartesDeReponses(
  DocumentReponses document, {
  Map<String, String> nomsOperateurs = const <String, String>{},
}) {
  final int duree = dureeDeclareeDe(document.reponses['publics']);
  final Map<String, List<LigneReponse>> parCarte =
      <String, List<LigneReponse>>{};
  for (final ({String code, String carte}) champ in champsDuQuestionnaire) {
    if (!document.reponses.containsKey(champ.code)) {
      continue;
    }
    final Object? reponse = document.reponses[champ.code];
    final ModeleQuestion? modele = modelesQuestions[champ.code];
    final String? libelle = nomCourtQuestion(champ.code);
    if (modele == null || libelle == null || reponse == null) {
      continue;
    }
    final ChampQuestionnaire pour = ChampQuestionnaire(
      code: champ.code,
      carte: champ.carte,
      type: TypeChamp.choix,
      requis: false,
    );
    final LigneReponse? ligne = switch (modele.forme) {
      FormeQuestion.creneaux => _disponibilites(pour, libelle, reponse, duree),
      FormeQuestion.operateurs => _moyens(
        champ.code,
        libelle,
        reponse,
        nomsOperateurs,
      ),
      FormeQuestion.moyensAccessibles => _moyens(
        champ.code,
        libelle,
        reponse,
        const <String, String>{},
      ),
      _ => _ordinaire(pour, libelle, reponse, duree),
    };
    if (ligne != null) {
      (parCarte[champ.carte] ??= <LigneReponse>[]).add(ligne);
    }
  }
  return <CarteReponses>[
    for (final MapEntry<String, List<LigneReponse>> e in parCarte.entries)
      if (titreCarteDirection(e.key) case final String titre)
        CarteReponses(code: e.key, titre: titre, lignes: e.value),
  ];
}

LigneReponse? _ordinaire(
  ChampQuestionnaire champ,
  String libelle,
  Object reponse,
  int duree,
) {
  final String? valeur = resumeReponse(champ, reponse, dureeMinutes: duree);
  return valeur == null
      ? null
      : LigneReponse(code: champ.code, libelle: libelle, valeur: valeur);
}

LigneReponse? _disponibilites(
  ChampQuestionnaire champ,
  String libelle,
  Object reponse,
  int duree,
) {
  final List<String> groupes = <String>[
    for (final ({String jours, String heures}) g in groupesDeJours(
      champ,
      reponse,
      dureeMinutes: duree,
    ))
      t.admin.candidatures.detail.groupeJours(jours: g.jours, heures: g.heures),
  ];
  if (groupes.isEmpty) {
    return null;
  }
  return LigneReponse(code: champ.code, libelle: libelle, groupes: groupes);
}

LigneReponse? _moyens(
  String code,
  String libelle,
  Object reponse,
  Map<String, String> noms,
) {
  final List<String> codes = <String>[
    if (reponse is List)
      for (final Object? c in reponse)
        if (c is String) c,
  ];
  if (codes.isEmpty) {
    return null;
  }
  final List<String> connus = <String>[
    for (final String c in codes)
      if (noms[c] case final String nom) nom,
  ];
  // Tous les noms sont connus : on les dit. Sinon le nombre, jamais un code.
  return LigneReponse(
    code: code,
    libelle: libelle,
    valeur: connus.length == codes.length
        ? connus.join(t.recrutement.parcours.creneaux.separateurListe)
        : t.admin.candidatures.detail.moyensIndiques(n: codes.length),
  );
}

/// Le titre neutre d'une carte, ou `null` pour une carte inconnue.
String? titreCarteDirection(String carte) {
  final c = t.admin.candidatures.detail.cartes;
  return switch (carte) {
    'langues' => c.langues,
    'recitation' => c.recitation,
    'disponibilites' => c.disponibilites,
    'publics' => c.publics,
    'versement' => c.versement,
    _ => null,
  };
}

/// Les moyens de versement que la personne a declares : ce que le serveur
/// croise avec le referentiel quand la direction confirme ou ecarte un moyen.
class DeclarationVersement {
  /// Cree la declaration.
  const DeclarationVersement({
    this.pays,
    this.virement = false,
    this.operateurs = const <String>[],
  });

  /// Le pays de versement declare (code ISO), ou `null`.
  final String? pays;

  /// Vrai quand la personne a un compte bancaire.
  final bool virement;

  /// Les codes des operateurs de monnaie mobile declares.
  final List<String> operateurs;

  /// Aucun moyen n'est declare.
  bool get vide => !virement && operateurs.isEmpty;
}

/// Lit la declaration de versement dans les dernieres reponses du dossier.
DeclarationVersement declarationVersement(DetailCandidature detail) {
  final Map<String, Object?> r =
      detail.dernieresReponses?.reponses ?? const <String, Object?>{};
  final Object? pays = r['paysVersement'];
  final Object? operateurs = r['operateurs'];
  return DeclarationVersement(
    pays: pays is String && pays.isNotEmpty ? pays : null,
    virement: r['compteBancaire'] == true,
    operateurs: List<String>.unmodifiable(<String>[
      if (operateurs is List)
        for (final Object? o in operateurs)
          if (o is String && o.isNotEmpty) o,
    ]),
  );
}
