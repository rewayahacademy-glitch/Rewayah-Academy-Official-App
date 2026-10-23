// Les formes de donnees de l'import des formulaires (`ADM-23`,
// `PortImportCandidatures`,
// `docs/current/CANDIDATURES/CONTRAT_PORTS_CANDIDATURES.md`, section 2).
//
// Miroir Dart de ce que rendent `apercu_import_formulaires` et
// `confirmer_import_formulaires`
// (`20261022000600_cand_l3_inscription_import_rapprochement.sql`). L'ecran lit
// ces champs ; il ne recalcule ni un compteur, ni une issue, ni la ligne
// retenue d'un groupe de doublons.
//
// **Aucune donnee personnelle.** Le serveur ne rend ni nom, ni courriel, ni
// telephone, ni reponse : une ligne ne porte que son numero dans le fichier,
// son issue, des codes de motif et deux marques (« courriel a obtenir »,
// « indicatif a confirmer »). Un groupe de doublons dit la **nature** de sa
// cle, jamais sa valeur. Ce fichier n'a aucun champ pour les recevoir.
//
// La lecture est stricte : une forme inattendue est une [FormatException],
// jamais un zero silencieux.
library;

import 'package:flutter/foundation.dart';

/// Le champ du formulaire que porte une colonne, par le code du serveur
/// (`private.formulaires_entetes`, `formulaires_lire`).
enum ChampFormulaire {
  /// L'horodateur de la reponse : il fait la reference source.
  horodatage('horodatage', obligatoire: true),

  /// Le genre declare.
  genre('genre', obligatoire: true),

  /// Le nom complet.
  nom('nom', obligatoire: true),

  /// Le numero WhatsApp avec indicatif.
  telephone('telephone', contact: true),

  /// La langue maternelle.
  langueMaternelle('langueMaternelle'),

  /// Les langues d'explication.
  languesExplication('languesExplication'),

  /// Le niveau de memorisation.
  memorisation('memorisation'),

  /// L'ijaza presentable.
  ijaza('ijaza'),

  /// L'experience avec les debutants.
  experience('experience'),

  /// Les creneaux (heure de La Mecque, sans jour).
  creneaux('creneaux'),

  /// Les heures par semaine.
  heures('heures'),

  /// Le debut possible.
  debut('debut'),

  /// L'accord de contact par WhatsApp.
  whatsapp('whatsapp'),

  /// Le courriel.
  courriel('courriel', contact: true);

  const ChampFormulaire(
    this.code, {
    this.obligatoire = false,
    this.contact = false,
  });

  /// Le code du serveur (`p_mappage`, `entetes[].champ`).
  final String code;

  /// Vrai quand le serveur refuse un fichier sans ce champ
  /// (`mappage_incomplet`).
  final bool obligatoire;

  /// Vrai pour le telephone et le courriel : le serveur veut au moins l'un des
  /// deux (le « champ » `contact` de `mappage_incomplet`).
  final bool contact;

  /// Le champ de code [code], ou `null` pour un code inconnu.
  static ChampFormulaire? depuisCode(Object? code) {
    for (final ChampFormulaire c in values) {
      if (c.code == code) return c;
    }
    return null;
  }
}

/// Un champ que le serveur dit manquant : l'un des champs obligatoires, ou
/// `contact` (ni telephone ni courriel).
enum ChampManquant {
  /// Pas d'horodateur.
  horodatage('horodatage'),

  /// Pas de genre.
  genre('genre'),

  /// Pas de nom.
  nom('nom'),

  /// Ni telephone ni courriel.
  contact('contact');

  const ChampManquant(this.code);

  /// Le code du serveur.
  final String code;

  /// Le champ manquant de code [code], ou `null` pour un code inconnu.
  static ChampManquant? depuisCode(Object? code) {
    for (final ChampManquant c in values) {
      if (c.code == code) return c;
    }
    return null;
  }
}

/// La colonne d'un fichier et le champ que le serveur y a reconnu. `champ`
/// nul : colonne non reconnue, donc non lue.
@immutable
class ColonneLue {
  /// Cree la colonne.
  const ColonneLue({required this.position, this.champ});

  /// Lit `{position, champ}`.
  factory ColonneLue.depuisJson(Object? brut) {
    if (brut is! Map) throw const FormatException('colonne attendue');
    final Object? position = brut['position'];
    if (position is! num) throw const FormatException('position de colonne');
    final Object? champ = brut['champ'];
    final ChampFormulaire? lu = ChampFormulaire.depuisCode(champ);
    if (champ != null && lu == null) {
      throw FormatException('champ inconnu : $champ');
    }
    return ColonneLue(position: position.toInt(), champ: lu);
  }

  /// La position de la colonne, a partir de 1.
  final int position;

  /// Le champ reconnu, ou `null`.
  final ChampFormulaire? champ;

  @override
  bool operator ==(Object other) =>
      other is ColonneLue && other.position == position && other.champ == champ;

  @override
  int get hashCode => Object.hash(position, champ);
}

/// Les associations corrigees a la main, position de colonne vers champ (`null` :
/// ne pas lire cette colonne). Envoyees telles quelles en `p_mappage`, au
/// serveur, qui les lit apres sa propre reconnaissance des titres.
///
/// Le jeton de l'apercu porte ce mappage : la confirmation doit envoyer
/// exactement le meme. Aucune surcharge vaut `null`, jamais `{}`.
@immutable
class MappageColonnes {
  /// Cree le mappage.
  const MappageColonnes([this.surcharges = const <int, ChampFormulaire?>{}]);

  /// Aucune correction : le serveur lit les titres.
  static const MappageColonnes aucun = MappageColonnes();

  /// Position de colonne vers champ corrige.
  final Map<int, ChampFormulaire?> surcharges;

  /// Vrai sans correction.
  bool get estVide => surcharges.isEmpty;

  /// Le mappage avec la colonne [position] lue comme [champ] (`null` : non
  /// lue). Un champ n'a qu'une colonne : l'attribuer a [position] le retire des
  /// autres corrections.
  MappageColonnes avec(int position, ChampFormulaire? champ) {
    final Map<int, ChampFormulaire?> suivant = <int, ChampFormulaire?>{
      for (final MapEntry<int, ChampFormulaire?> e in surcharges.entries)
        if (champ == null || e.value != champ) e.key: e.value,
      position: champ,
    };
    return MappageColonnes(Map<int, ChampFormulaire?>.unmodifiable(suivant));
  }

  /// Ce qui part au serveur (`p_mappage`), ou `null` sans correction.
  Map<String, String?>? versJson() => surcharges.isEmpty
      ? null
      : <String, String?>{
          for (final MapEntry<int, ChampFormulaire?> e in surcharges.entries)
            '${e.key}': e.value?.code,
        };

  /// Les colonnes telles que le serveur les a lues, apres les corrections :
  /// la position corrigee prend son champ, un champ attribue ailleurs quitte
  /// son ancienne colonne. Idempotent sur un resultat qui les porte deja.
  List<ColonneLue> appliquerA(List<ColonneLue> lues) {
    final Map<int, ChampFormulaire?> champs = <int, ChampFormulaire?>{
      for (final ColonneLue c in lues) c.position: c.champ,
    };
    for (final MapEntry<int, ChampFormulaire?> e in surcharges.entries) {
      if (e.value != null) {
        for (final int p in champs.keys.toList()) {
          if (champs[p] == e.value) champs[p] = null;
        }
      }
      champs[e.key] = e.value;
    }
    final List<int> positions = champs.keys.toList()..sort();
    return <ColonneLue>[
      for (final int p in positions) ColonneLue(position: p, champ: champs[p]),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is MappageColonnes && mapEquals(other.surcharges, surcharges);

  @override
  int get hashCode => Object.hashAll(<Object?>[
    for (final MapEntry<int, ChampFormulaire?> e in surcharges.entries) ...[
      e.key,
      e.value,
    ],
  ]);
}

/// Les champs obligatoires qui n'ont aucune colonne dans [colonnes], dans
/// l'ordre du serveur (horodatage, genre, nom, puis contact). Meme regle que
/// `formulaires_lire` : le calcul sert a ne pas proposer « Continuer » avant
/// qu'une association corrigee suffise ; le serveur reste l'arbitre.
List<ChampManquant> champsManquants(List<ColonneLue> colonnes) {
  final Set<ChampFormulaire> presents = <ChampFormulaire>{
    for (final ColonneLue c in colonnes) ?c.champ,
  };
  return <ChampManquant>[
    if (!presents.contains(ChampFormulaire.horodatage))
      ChampManquant.horodatage,
    if (!presents.contains(ChampFormulaire.genre)) ChampManquant.genre,
    if (!presents.contains(ChampFormulaire.nom)) ChampManquant.nom,
    if (!presents.contains(ChampFormulaire.telephone) &&
        !presents.contains(ChampFormulaire.courriel))
      ChampManquant.contact,
  ];
}

/// Ce que devient une ligne du fichier.
enum IssueLigne {
  /// Une reponse que la base ne connait pas encore.
  nouvelle('nouvelle'),

  /// Une reponse connue dont le contenu a change dans le classeur.
  corrigee('corrigee'),

  /// Une reponse deja en base (ou une personne de l'import du 12/10).
  dejaConnue('deja_connue'),

  /// Une ligne vide, ou repetee a l'identique.
  ignoree('ignoree'),

  /// Une ligne illisible : rien n'en est ecrit.
  aCorriger('a_corriger');

  const IssueLigne(this.code);

  /// Le code du serveur.
  final String code;

  /// L'issue de code [code]. Un code inconnu est une erreur de lecture.
  static IssueLigne depuisCode(Object? code) {
    for (final IssueLigne i in values) {
      if (i.code == code) return i;
    }
    throw FormatException('issue inconnue : $code');
  }
}

/// L'etat d'une ligne une fois les doublons regles.
enum EtatFinalLigne {
  /// La reponse de la personne.
  active('active'),

  /// Remplacee par une plus recente : gardee, jamais effacee.
  historique('historique');

  const EtatFinalLigne(this.code);

  /// Le code du serveur.
  final String code;

  /// L'etat de code [code], ou `null` (ligne ignoree, a corriger...).
  static EtatFinalLigne? depuisCode(Object? code) {
    if (code == null) return null;
    for (final EtatFinalLigne e in values) {
      if (e.code == code) return e;
    }
    throw FormatException('etat final inconnu : $code');
  }
}

List<String> _codes(Object? brut, String cle) {
  if (brut == null) return const <String>[];
  if (brut is! List) throw FormatException(cle);
  return List<String>.unmodifiable(<String>[
    for (final Object? c in brut)
      if (c is String) c else throw FormatException(cle),
  ]);
}

int _entier(Map<dynamic, dynamic> j, String cle) {
  final Object? v = j[cle];
  if (v is! num) throw FormatException(cle);
  return v.toInt();
}

/// Une ligne de l'apercu : ce que le serveur en a lu, sans aucune donnee
/// personnelle.
@immutable
class LigneApercu {
  /// Cree la ligne.
  const LigneApercu({
    required this.ligne,
    required this.issue,
    this.motifs = const <String>[],
    this.avertissements = const <String>[],
    this.courrielAObtenir = false,
    this.indicatifAConfirmer = false,
    this.groupe,
    this.etatFinal,
  });

  /// Lit une ligne de `apercu_import_formulaires().lignes`.
  factory LigneApercu.depuisJson(Object? brut) {
    if (brut is! Map) throw const FormatException('ligne attendue');
    final Object? groupe = brut['groupe'];
    if (groupe != null && groupe is! String) {
      throw const FormatException('groupe de la ligne');
    }
    return LigneApercu(
      ligne: _entier(brut, 'ligne'),
      issue: IssueLigne.depuisCode(brut['issue']),
      motifs: _codes(brut['motifs'], 'motifs'),
      avertissements: _codes(brut['avertissements'], 'avertissements'),
      courrielAObtenir: brut['courrielAObtenir'] == true,
      indicatifAConfirmer: brut['indicatifAConfirmer'] == true,
      groupe: groupe as String?,
      etatFinal: EtatFinalLigne.depuisCode(brut['etatFinal']),
    );
  }

  /// Le numero dans le fichier : l'en-tete est la ligne 1, les lignes vides ne
  /// comptent pas.
  final int ligne;

  /// Ce que devient la ligne.
  final IssueLigne issue;

  /// Pourquoi elle n'est pas importee (codes du serveur).
  final List<String> motifs;

  /// Ce qui merite un coup d'oeil (codes du serveur).
  final List<String> avertissements;

  /// Pas de courriel valide : la personne ne s'invite pas.
  final bool courrielAObtenir;

  /// Un telephone sans indicatif reconnu.
  final bool indicatifAConfirmer;

  /// L'identifiant du groupe de doublons, ou `null`.
  final String? groupe;

  /// Active ou en historique, ou `null`.
  final EtatFinalLigne? etatFinal;
}

/// Les compteurs du serveur. Une ligne lue compte une fois.
@immutable
class CompteursImport {
  /// Cree les compteurs.
  const CompteursImport({
    required this.lignesLues,
    required this.nouvelles,
    required this.corrigees,
    required this.dejaConnues,
    required this.ignorees,
    required this.aCorriger,
    required this.historique,
    required this.personnes,
  });

  /// Lit `compteurs`.
  factory CompteursImport.depuisJson(Object? brut) {
    if (brut is! Map) throw const FormatException('compteurs attendus');
    return CompteursImport(
      lignesLues: _entier(brut, 'lignesLues'),
      nouvelles: _entier(brut, 'nouvelles'),
      corrigees: _entier(brut, 'corrigees'),
      dejaConnues: _entier(brut, 'dejaConnues'),
      ignorees: _entier(brut, 'ignorees'),
      aCorriger: _entier(brut, 'aCorriger'),
      historique: _entier(brut, 'historique'),
      personnes: _entier(brut, 'personnes'),
    );
  }

  /// Les lignes lues dans le fichier (l'en-tete exclu).
  final int lignesLues;

  /// Reponses que la base ne connait pas.
  final int nouvelles;

  /// Reponses connues corrigees dans le classeur.
  final int corrigees;

  /// Reponses deja en base : rien ne change.
  final int dejaConnues;

  /// Lignes vides ou repetees.
  final int ignorees;

  /// Lignes illisibles : rien n'en est ecrit.
  final int aCorriger;

  /// Lignes ecrites ou gardees en historique, remplacees par une plus recente.
  final int historique;

  /// Les personnes que le fichier touche, doublons rapproches.
  final int personnes;
}

/// Ce qui relie les lignes d'un groupe : la **nature** de la cle, jamais sa
/// valeur.
enum NatureCle {
  /// Le meme courriel valide.
  courriel('courriel'),

  /// Le meme telephone normalise.
  telephone('telephone'),

  /// Les deux.
  courrielEtTelephone('courriel_et_telephone');

  const NatureCle(this.code);

  /// Le code du serveur.
  final String code;

  /// La nature de code [code]. Un code inconnu est une erreur de lecture.
  static NatureCle depuisCode(Object? code) {
    for (final NatureCle n in values) {
      if (n.code == code) return n;
    }
    throw FormatException('nature de cle inconnue : $code');
  }
}

/// Le mot du serveur pour « ces lignes sont des personnes distinctes ».
const String retenueDistinctes = 'distinctes';

/// Un groupe de doublons probables.
@immutable
class GroupeDoublons {
  /// Cree le groupe.
  const GroupeDoublons({
    required this.id,
    required this.nature,
    required this.taille,
    required this.lignes,
    this.retenueProposee,
    this.retenueDansLaBase = false,
    this.choisi = false,
    this.choix,
  });

  /// Lit un element de `groupes`.
  factory GroupeDoublons.depuisJson(Object? brut) {
    if (brut is! Map) throw const FormatException('groupe attendu');
    final Object? id = brut['id'];
    if (id is! String || id.isEmpty) throw const FormatException('groupe.id');
    final Object? lignes = brut['lignes'];
    if (lignes is! List) throw const FormatException('groupe.lignes');
    final Object? proposee = brut['retenueProposee'];
    if (proposee != null && proposee is! num) {
      throw const FormatException('groupe.retenueProposee');
    }
    final Object? choix = brut['choix'];
    if (choix != null && choix is! String) {
      throw const FormatException('groupe.choix');
    }
    return GroupeDoublons(
      id: id,
      nature: NatureCle.depuisCode(brut['nature']),
      taille: _entier(brut, 'taille'),
      lignes: List<int>.unmodifiable(<int>[
        for (final Object? l in lignes)
          if (l is num) l.toInt() else throw const FormatException('ligne'),
      ]),
      retenueProposee: (proposee as num?)?.toInt(),
      retenueDansLaBase: brut['retenueDansLaBase'] == true,
      choisi: brut['choisi'] == true,
      choix: choix as String?,
    );
  }

  /// L'identifiant du groupe : l'empreinte de ses lignes, stable d'un fichier
  /// corrige a l'autre.
  final String id;

  /// Ce qui relie les lignes.
  final NatureCle nature;

  /// Le nombre de lignes du groupe, celles du fichier et celles que la base
  /// garde.
  final int taille;

  /// Les numeros des lignes du fichier qui sont dans le groupe.
  final List<int> lignes;

  /// La ligne du fichier que le serveur gardera sans choix (la plus recente),
  /// ou `null` quand la retenue est deja en base ou quand le choix est
  /// « personnes distinctes ».
  final int? retenueProposee;

  /// La ligne gardee est deja en base (un import precedent).
  final bool retenueDansLaBase;

  /// Un choix d'un import precedent est gardé pour ce groupe.
  final bool choisi;

  /// Ce choix : [retenueDistinctes] ou la reference source de la ligne
  /// retenue.
  final String? choix;
}

/// La reponse du serveur a un essai a blanc : rien n'est ecrit.
@immutable
class ApercuImport {
  /// Cree l'apercu.
  const ApercuImport({
    required this.jeton,
    required this.colonnes,
    required this.compteurs,
    required this.groupes,
    required this.lignes,
  });

  /// Lit la reponse de `apercu_import_formulaires`.
  factory ApercuImport.depuisJson(Object? brut) {
    if (brut is! Map) throw const FormatException('apercu attendu');
    if (brut['ecritureEffectuee'] != false) {
      throw const FormatException('un apercu n ecrit rien');
    }
    final Object? jeton = brut['jeton'];
    if (jeton is! String || jeton.isEmpty) {
      throw const FormatException('jeton');
    }
    final Object? entetes = brut['entetes'];
    final Object? groupes = brut['groupes'];
    final Object? lignes = brut['lignes'];
    if (entetes is! List || groupes is! List || lignes is! List) {
      throw const FormatException('apercu : listes attendues');
    }
    return ApercuImport(
      jeton: jeton,
      colonnes: <ColonneLue>[for (final Object? e in entetes) ColonneLue.depuisJson(e)],
      compteurs: CompteursImport.depuisJson(brut['compteurs']),
      groupes: <GroupeDoublons>[
        for (final Object? g in groupes) GroupeDoublons.depuisJson(g),
      ],
      lignes: <LigneApercu>[for (final Object? l in lignes) LigneApercu.depuisJson(l)],
    );
  }

  /// Le jeton que la confirmation doit rendre : le fichier, le classeur,
  /// l'onglet, le mappage ou le fuseau qui change le perime.
  final String jeton;

  /// Les colonnes du fichier et le champ reconnu dans chacune.
  final List<ColonneLue> colonnes;

  /// Les compteurs, sans les choix de doublons (ils ne changent aucune issue).
  final CompteursImport compteurs;

  /// Les groupes de doublons probables.
  final List<GroupeDoublons> groupes;

  /// Une ligne par ligne lue.
  final List<LigneApercu> lignes;

  /// Le nombre de colonnes dont un champ est reconnu.
  int get colonnesReconnues =>
      colonnes.where((ColonneLue c) => c.champ != null).length;

  /// Les lignes de l'issue [issue].
  Iterable<LigneApercu> deIssue(IssueLigne issue) =>
      lignes.where((LigneApercu l) => l.issue == issue);

  /// Les lignes qui portent au moins un avertissement ou un motif.
  Iterable<LigneApercu> get avecRemarques => lignes.where(
    (LigneApercu l) => l.motifs.isNotEmpty || l.avertissements.isNotEmpty,
  );
}

/// Le choix de la direction pour un groupe de doublons, tel que le serveur le
/// lit : [retenue] est la reference source de la ligne gardee, ou
/// [retenueDistinctes].
@immutable
class ChoixDoublon {
  /// Cree le choix.
  const ChoixDoublon({required this.groupe, required this.retenue});

  /// L'identifiant du groupe.
  final String groupe;

  /// La reference source retenue, ou [retenueDistinctes].
  final String retenue;

  /// Ce qui part au serveur (`p_choix`).
  Map<String, String> versJson() => <String, String>{
    'groupe': groupe,
    'retenue': retenue,
  };

  @override
  bool operator ==(Object other) =>
      other is ChoixDoublon &&
      other.groupe == groupe &&
      other.retenue == retenue;

  @override
  int get hashCode => Object.hash(groupe, retenue);
}

/// Une ligne du rapport final : la reference source et ce qui en est devenu,
/// **jamais un nom**.
@immutable
class LigneRapport {
  /// Cree la ligne.
  const LigneRapport({
    required this.ligne,
    required this.issue,
    this.reference,
    this.etatFinal,
    this.motifs = const <String>[],
    this.avertissements = const <String>[],
  });

  /// Lit une ligne de `confirmer_import_formulaires().lignes`.
  factory LigneRapport.depuisJson(Object? brut) {
    if (brut is! Map) throw const FormatException('ligne du rapport');
    final Object? reference = brut['reference'];
    if (reference != null && reference is! String) {
      throw const FormatException('reference');
    }
    return LigneRapport(
      ligne: _entier(brut, 'ligne'),
      issue: IssueLigne.depuisCode(brut['issue']),
      reference: reference as String?,
      etatFinal: EtatFinalLigne.depuisCode(brut['etatFinal']),
      motifs: _codes(brut['motifs'], 'motifs'),
      avertissements: _codes(brut['avertissements'], 'avertissements'),
    );
  }

  /// Le numero dans le fichier.
  final int ligne;

  /// Ce qu'est devenue la ligne.
  final IssueLigne issue;

  /// La reference source (classeur, onglet, horodatage ecrit), ou `null` pour
  /// une ligne qui n'en a pas (ligne vide, horodatage illisible).
  final String? reference;

  /// Active ou en historique.
  final EtatFinalLigne? etatFinal;

  /// Pourquoi elle n'est pas importee.
  final List<String> motifs;

  /// Ce qui meritait un coup d'oeil.
  final List<String> avertissements;
}

/// Le rapport de la confirmation, ecrit par le serveur : rien n'est dit
/// importe avant lui.
@immutable
class RapportImport {
  /// Cree le rapport.
  const RapportImport({
    required this.lot,
    required this.compteurs,
    required this.lignes,
    required this.choix,
    required this.rejoue,
  });

  /// Lit la reponse de `confirmer_import_formulaires`.
  factory RapportImport.depuisJson(Object? brut) {
    if (brut is! Map) throw const FormatException('rapport attendu');
    if (brut['ecritureEffectuee'] != true) {
      throw const FormatException('un rapport suit une ecriture');
    }
    final Object? lot = brut['lot'];
    final Object? lignes = brut['lignes'];
    final Object? choix = brut['choix'];
    if (lot is! String || lignes is! List || choix is! List) {
      throw const FormatException('rapport : champs attendus');
    }
    return RapportImport(
      lot: lot,
      compteurs: CompteursImport.depuisJson(brut['compteurs']),
      lignes: <LigneRapport>[for (final Object? l in lignes) LigneRapport.depuisJson(l)],
      choix: <ChoixDoublon>[
        for (final Object? c in choix)
          if (c is Map && c['groupe'] is String && c['retenue'] is String)
            ChoixDoublon(
              groupe: c['groupe'] as String,
              retenue: c['retenue'] as String,
            )
          else
            throw const FormatException('choix du rapport'),
      ],
      rejoue: brut['rejoue'] == true,
    );
  }

  /// L'identifiant du lot (trace, jamais affiche).
  final String lot;

  /// Les compteurs de ce que l'import a fait, choix de doublons compris.
  final CompteursImport compteurs;

  /// Une entree par ligne lue.
  final List<LigneRapport> lignes;

  /// Les choix de doublons de cette demande.
  final List<ChoixDoublon> choix;

  /// Vrai quand la meme demande avait deja ete enregistree : rien n'a ete
  /// ajoute une seconde fois.
  final bool rejoue;
}

/// Ce que ce lecteur peut faire de l'import (`capacites_candidatures`).
@immutable
class CapacitesImportCandidatures {
  /// Cree les capacites.
  const CapacitesImportCandidatures({
    this.peutImporter = false,
    this.doubleVerificationRequise = false,
  });

  /// Aucune capacite.
  static const CapacitesImportCandidatures aucune =
      CapacitesImportCandidatures();

  /// Lit `peutImporter` et `doubleVerificationRequise`. Une cle absente vaut
  /// faux : une capacite ne se suppose jamais.
  factory CapacitesImportCandidatures.depuisJson(Object? brut) {
    if (brut is! Map) throw const FormatException('capacites attendues');
    return CapacitesImportCandidatures(
      peutImporter: brut['peutImporter'] == true,
      doubleVerificationRequise: brut['doubleVerificationRequise'] == true,
    );
  }

  /// `candidatures.importer` : le super-admin, en double verification.
  final bool peutImporter;

  /// Le super-admin n'est pas en double verification : le serveur refuse
  /// l'import tant qu'il ne l'est pas.
  final bool doubleVerificationRequise;
}
