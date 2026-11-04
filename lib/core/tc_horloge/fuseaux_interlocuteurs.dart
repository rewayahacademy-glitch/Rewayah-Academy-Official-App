// FUSEAUX, partie client (garde-cap, 04/11/2026 ; PLAN-LOTS §12). Mots du
// directeur : « chacun voit son fuseau et celui de son interlocuteur :
// exemple, 08h chez vous (paris), et 06h chez "Sayyid/sayda" (C.Ivoire) et
// vice versa ».
//
// Le serveur (`horloge_interlocuteurs`, migration 20261109500000) rend, pour
// une classe et selon l'appelant, le fuseau de chaque interlocuteur avec son
// decalage UTC actuel et l'instant de son prochain changement d'heure. Le
// client ne fait AUCUNE conversion IANA (`pubspec.yaml` gele) : une heure se
// lit « instant UTC + decalage », et seulement tant que ce decalage est sur.

import 'package:flutter/foundation.dart';

/// Le fuseau d'une personne, tel que le serveur le donne.
@immutable
class FuseauVu {
  /// Cree un fuseau lu.
  const FuseauVu({
    required this.fuseau,
    required this.decalage,
    this.prochainChangement,
    this.decalageApres,
    this.changementSuivant,
    this.decalageApresConnu = false,
  });

  /// Lit l'objet `{fuseau, decalage_secondes, prochain_changement, ...}`.
  /// `null` pour un objet absent ou incomplet : le serveur n'a pas su lire ce
  /// fuseau, et l'ecran le dit au lieu d'inventer une heure.
  static FuseauVu? lire(Object? brut) {
    if (brut is! Map) return null;
    final Object? fuseau = brut['fuseau'];
    final Object? decalage = brut['decalage_secondes'];
    if (fuseau is! String || fuseau.trim().isEmpty || decalage is! num) {
      return null;
    }
    return FuseauVu(
      fuseau: fuseau,
      decalage: Duration(seconds: decalage.toInt()),
      prochainChangement: _instant(brut['prochain_changement']),
      decalageApresConnu: brut.containsKey('decalage_apres'),
      decalageApres: brut['decalage_apres'] is num
          ? Duration(seconds: (brut['decalage_apres'] as num).toInt())
          : null,
      changementSuivant: _instant(brut['changement_suivant']),
    );
  }

  /// L'identifiant IANA, par exemple `Africa/Abidjan`.
  final String fuseau;

  /// L'ecart avec UTC en ce moment (une heure pour Paris l'hiver).
  final Duration decalage;

  /// L'instant UTC du prochain changement d'heure, `null` s'il n'y en a pas
  /// dans l'annee.
  final DateTime? prochainChangement;

  /// L'ecart avec UTC juste apres [prochainChangement], quand le serveur le
  /// donne (cle `decalage_apres`).
  final Duration? decalageApres;

  /// Vrai quand le serveur a donne la cle `decalage_apres` (meme nulle).
  final bool decalageApresConnu;

  /// Le changement d'heure d'apres, `null` s'il n'y en a pas dans l'annee.
  final DateTime? changementSuivant;

  /// L'ecart avec UTC a l'instant [utc], ou `null` quand on ne le sait pas :
  /// apres le prochain changement sans `decalage_apres`, ou apres le
  /// changement suivant. Jamais une heure fausse.
  Duration? decalageA(DateTime utc) {
    final DateTime? changement = prochainChangement;
    if (changement == null || utc.isBefore(changement)) return decalage;
    if (!decalageApresConnu || decalageApres == null) return null;
    final DateTime? suivant = changementSuivant;
    if (suivant != null && !utc.isBefore(suivant)) return null;
    return decalageApres;
  }

  /// L'heure murale (champs annee, mois, jour, heure, minute) a l'instant
  /// [utc] dans ce fuseau, ou `null` quand le decalage n'est pas sur.
  DateTime? muraleA(DateTime utc) {
    final Duration? d = decalageA(utc);
    if (d == null) return null;
    return utc.toUtc().add(d);
  }

  /// « 08:00 » a l'instant [utc], ou `null` quand le decalage n'est pas sur.
  String? heureA(DateTime utc) {
    final DateTime? m = muraleA(utc);
    if (m == null) return null;
    return '${_deux(m.hour)}:${_deux(m.minute)}';
  }

  /// Vrai quand les deux fuseaux donnent la meme heure en ce moment et au
  /// prochain changement : afficher deux fois la meme heure ferait croire a
  /// une difference qui n'existe pas.
  bool memeHeureQue(FuseauVu autre) =>
      autre.fuseau == fuseau ||
      (autre.decalage == decalage &&
          autre.prochainChangement == prochainChangement &&
          autre.decalageApres == decalageApres);

  @override
  bool operator ==(Object other) =>
      other is FuseauVu &&
      other.fuseau == fuseau &&
      other.decalage == decalage &&
      other.prochainChangement == prochainChangement &&
      other.decalageApres == decalageApres &&
      other.changementSuivant == changementSuivant &&
      other.decalageApresConnu == decalageApresConnu;

  @override
  int get hashCode => Object.hash(
    fuseau,
    decalage,
    prochainChangement,
    decalageApres,
    changementSuivant,
    decalageApresConnu,
  );
}

/// Le titre enregistre de l'enseignant (`teacher_profiles.titre`), jamais
/// deduit du nom.
enum TitreInterlocuteur {
  /// Sayyid.
  sayyid,

  /// Sayyida.
  sayyida,
}

/// L'enseignant effectif de la prochaine seance, vu par la famille ou par la
/// direction.
@immutable
class EnseignantInterlocuteur {
  /// Cree l'enseignant lu.
  const EnseignantInterlocuteur({
    required this.remplacant,
    required this.fuseauDeLaClasse,
    this.titre,
    this.prenom,
    this.pays,
    this.fuseau,
  });

  /// Le titre enregistre, `null` s'il ne l'est pas.
  final TitreInterlocuteur? titre;

  /// Le prenom (l'identifiant en observation), `null` s'il manque.
  final String? prenom;

  /// Le code du pays (`CI`), `null` s'il manque.
  final String? pays;

  /// Vrai quand un remplacant tient la prochaine seance.
  final bool remplacant;

  /// Le fuseau de l'enseignant, ou celui de la classe quand le sien manque.
  final FuseauVu? fuseau;

  /// Vrai quand [fuseau] est celui de la classe (`source = 'classe'`) :
  /// l'ecran dit alors « heure de la classe », jamais « chez Sayyid X ».
  final bool fuseauDeLaClasse;
}

/// Un fuseau des familles de la classe, vu par l'enseignant ou la direction :
/// jamais un nom, seulement le nombre de familles.
@immutable
class FamillesDuFuseau {
  /// Cree le groupe de familles.
  const FamillesDuFuseau({required this.fuseau, required this.familles});

  /// Le fuseau, `null` quand le serveur ne l'a pas su lire.
  final FuseauVu? fuseau;

  /// Combien de familles y vivent.
  final int familles;
}

/// Les interlocuteurs d'une classe, selon qui regarde.
@immutable
class InterlocuteursClasse {
  /// Cree la lecture.
  const InterlocuteursClasse({
    required this.maintenantServeur,
    required this.familles,
    this.moi,
    this.classe,
    this.enseignant,
  });

  /// Lit la reponse de `horloge_interlocuteurs`. Leve [FormatException] sur
  /// une reponse sans `maintenant` lisible : sans instant serveur, aucune
  /// heure courante n'est affichee.
  factory InterlocuteursClasse.lire(Object? brut) {
    if (brut is! Map) {
      throw const FormatException('horloge_interlocuteurs : objet attendu');
    }
    final DateTime? maintenant = _instant(brut['maintenant']);
    if (maintenant == null) {
      throw const FormatException('horloge_interlocuteurs : maintenant');
    }
    final Object? e = brut['enseignant'];
    EnseignantInterlocuteur? enseignant;
    if (e is Map) {
      enseignant = EnseignantInterlocuteur(
        titre: switch (e['titre']) {
          'sayyid' => TitreInterlocuteur.sayyid,
          'sayyida' => TitreInterlocuteur.sayyida,
          _ => null,
        },
        prenom: _texte(e['prenom']),
        pays: _texte(e['pays']),
        remplacant: e['remplacant'] == true,
        fuseau: FuseauVu.lire(e),
        fuseauDeLaClasse: e['source'] == 'classe',
      );
    }
    final Object? f = brut['familles'];
    return InterlocuteursClasse(
      maintenantServeur: maintenant,
      moi: FuseauVu.lire(brut['moi']),
      classe: FuseauVu.lire(brut['classe']),
      enseignant: enseignant,
      familles: <FamillesDuFuseau>[
        if (f is List)
          for (final Object? x in f)
            if (x is Map && x['familles'] is num)
              FamillesDuFuseau(
                fuseau: FuseauVu.lire(x),
                familles: (x['familles'] as num).toInt(),
              ),
      ],
    );
  }

  /// L'instant serveur de la lecture.
  final DateTime maintenantServeur;

  /// Le fuseau de la personne qui regarde.
  final FuseauVu? moi;

  /// Le fuseau de la classe.
  final FuseauVu? classe;

  /// L'enseignant, pour la famille, l'eleve et la direction.
  final EnseignantInterlocuteur? enseignant;

  /// Les fuseaux des familles, pour l'enseignant et la direction (vide sinon).
  final List<FamillesDuFuseau> familles;

  /// Le premier instant ou cette lecture devient fausse : le plus proche
  /// changement d'heure parmi tous les fuseaux lus. L'ecran relit alors le
  /// serveur (`null` : aucun changement dans l'annee).
  DateTime? get relireA {
    DateTime? plusTot;
    void voir(FuseauVu? f) {
      final DateTime? c = f?.prochainChangement;
      if (c != null && (plusTot == null || c.isBefore(plusTot!))) plusTot = c;
    }

    voir(moi);
    voir(classe);
    voir(enseignant?.fuseau);
    for (final FamillesDuFuseau g in familles) {
      voir(g.fuseau);
    }
    return plusTot;
  }
}

DateTime? _instant(Object? brut) =>
    brut is String ? DateTime.tryParse(brut)?.toUtc() : null;

String? _texte(Object? brut) {
  if (brut is! String) return null;
  final String nu = brut.trim();
  return nu.isEmpty ? null : nu;
}

String _deux(int n) => n.toString().padLeft(2, '0');
