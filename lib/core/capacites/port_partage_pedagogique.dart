// Le partage pedagogique avec les familles (PED-APRES-1, spec V1 du 11/10/2026).
//
// **Un seul port, trois besoins** : (1) ce que la famille d'un eleve peut lire
// d'une seance, (2) la politique de partage par classe et par eleve, (3) la
// publication ou la revocation ciblee d'un compte rendu. Les trois partagent
// la meme verite serveur (la regle effective), d'ou un seul contrat.
//
// **Frontend seul.** Aucun adaptateur Supabase n'est ecrit ici : la production
// rend `CapaciteIndisponible`. L'ecran dit alors « Le reglage de partage n'est
// pas encore disponible. » et ne pose aucune fausse bascule. Le contrat de
// chaque methode est ecrit dans `docs/current/PED-APRES/CONTRAT_PORTS_PED_APRES.md`
// pour la carte PED-APRES-BACK.
//
// **Confidentialite par la forme.** [CompteRenduFamille] n'a **aucun champ**
// pour une note interne, un autre eleve ou une donnee de paie : le type ne peut
// pas les transporter. Ce que le cahier K-45 contient n'est jamais lu ici.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import 'capacite_indisponible.dart';
import 'partage_pedagogique_demonstration.dart';
import 'permission_insuffisante.dart';

/// Ce que la famille voit d'une seance, tel que le serveur l'autorise.
enum EtatCompteRendu {
  /// Des champs partageables sont presents et autorises : le bloc s'affiche.
  partage,

  /// Le partage est desactive pour cet eleve, ou ce compte rendu a ete revoque
  /// (la famille ne distingue pas les deux : meme phrase).
  nonPartage,

  /// Le cahier n'est pas encore confirme (absent, en file hors ligne, echec).
  enAttente,

  /// Le cahier est confirme mais aucun champ partageable n'existe.
  aucunChamp,
}

/// Le compte rendu pedagogique d'un eleve pour une seance, **projection
/// familiale** (jamais le cahier brut de la classe).
@immutable
class CompteRenduFamille {
  /// Cree un compte rendu. Les champs absents restent `null` ou vides : l'ecran
  /// n'affiche **que** ce qui existe, sans rubrique vide.
  const CompteRenduFamille({
    required this.etat,
    this.travaille,
    this.appreciation,
    this.aRenforcer = const <String>[],
    this.aPreparer = const <String>[],
    this.commentairePartage,
    this.corrigeLe,
  });

  /// L'etat de restitution.
  final EtatCompteRendu etat;

  /// Ce qui a ete travaille.
  final String? travaille;

  /// L'appreciation de la seance, uniquement si elle existe.
  final String? appreciation;

  /// Les points a renforcer, un par ligne.
  final List<String> aRenforcer;

  /// Ce qu'il faut preparer pour la prochaine seance, un point par ligne.
  final List<String> aPreparer;

  /// Le commentaire declare partageable et reellement publie.
  final String? commentairePartage;

  /// La date de correction de la version familiale, si le cahier a ete corrige.
  final DateTime? corrigeLe;

  /// Vrai si au moins un champ partageable est present.
  bool get aDuContenu =>
      (travaille ?? '').isNotEmpty ||
      (appreciation ?? '').isNotEmpty ||
      aRenforcer.isNotEmpty ||
      aPreparer.isNotEmpty ||
      (commentairePartage ?? '').isNotEmpty;
}

/// La regle appliquee a un eleve.
enum ReglePartageEleve {
  /// Utiliser la regle de la classe.
  regleClasse,

  /// Toujours partager automatiquement.
  toujours,

  /// Ne pas partager automatiquement.
  jamais,
}

/// D'ou vient la regle effective d'un eleve (priorite : exception eleve, puis
/// classe, puis defaut).
enum SourceRegle {
  /// Exception individuelle.
  exceptionEleve,

  /// Regle de la classe.
  classe,

  /// Valeur generale par defaut (active).
  defaut,
}

/// La situation de l'eleve dans la classe.
enum SituationEleveClasse {
  /// Membre actif.
  actif,

  /// Retire ou transfere : sa ligne est lisible, aucune modification n'est
  /// proposee.
  retire,
}

/// Une ligne de la liste des eleves : la regle et ses effets.
@immutable
class PartageEleve {
  /// Cree la ligne.
  const PartageEleve({
    required this.eleveId,
    required this.libelle,
    required this.regle,
    required this.source,
    required this.visible,
    this.situation = SituationEleveClasse.actif,
    this.modifieLe,
    this.modifiePar,
  });

  /// L'eleve.
  final String eleveId;

  /// Son nom, tel que l'administration a le droit de le lire.
  final String libelle;

  /// Le choix enregistre pour cet eleve.
  final ReglePartageEleve regle;

  /// La source de la regle effective.
  final SourceRegle source;

  /// Vrai : les comptes rendus eligibles sont visibles de sa famille.
  final bool visible;

  /// Sa situation dans la classe.
  final SituationEleveClasse situation;

  /// La derniere modification, si la source la donne.
  final DateTime? modifieLe;

  /// L'auteur de cette modification, si la source le donne.
  final String? modifiePar;
}

/// Le reglage de partage d'une classe, avec une page de ses eleves.
@immutable
class PartageClasse {
  /// Cree le reglage.
  const PartageClasse({
    required this.classeId,
    required this.actif,
    required this.version,
    required this.eleves,
    required this.total,
    this.page = 1,
    this.modifieLe,
    this.modifiePar,
  });

  /// La classe.
  final String classeId;

  /// Vrai : « Partager automatiquement avec les familles ».
  final bool actif;

  /// Le jeton de concurrence optimiste : toute ecriture le renvoie, le serveur
  /// refuse (`ConflitPartage`) si la valeur n'est plus la sienne.
  final String version;

  /// Une page d'eleves (pagination serveur, jamais la classe entiere copiee).
  final List<PartageEleve> eleves;

  /// Le nombre d'eleves de la classe (reel, jamais un compteur fictif).
  final int total;

  /// La page lue, a partir de 1.
  final int page;

  /// La derniere modification de la regle de classe, si la source la donne.
  final DateTime? modifieLe;

  /// L'auteur de cette modification, si la source le donne.
  final String? modifiePar;
}

/// Ce que la direction sait de la diffusion d'un compte rendu precis.
enum EtatDiffusion {
  /// Le cahier n'est pas confirme (ou en file hors ligne).
  nonValide,

  /// Confirme, non partage a la famille.
  confirmeNonPartage,

  /// Partage automatiquement.
  partageAuto,

  /// Publie manuellement par la direction.
  partageManuel,

  /// Revoque par la direction.
  revoque,

  /// Corrige apres une publication manuelle : la famille voit la derniere
  /// version approuvee, la nouvelle attend une decision.
  corrigeApresPartageManuel,
}

/// Une action de l'historique d'un compte rendu (affichee seulement si la
/// source la fournit : aucune piste d'audit inventee).
@immutable
class ActionPartage {
  /// Cree l'action.
  const ActionPartage({required this.quand, required this.type, this.auteur});

  /// Quand.
  final DateTime quand;

  /// Le type : `publication`, `revocation`, `partage_automatique`.
  final String type;

  /// Qui (`null` : le systeme).
  final String? auteur;
}

/// Un compte rendu vu par la direction : l'apercu exact et l'etat de diffusion.
@immutable
class ApercuAdmin {
  /// Cree l'apercu.
  const ApercuAdmin({
    required this.seanceId,
    required this.eleveId,
    required this.elevePrenom,
    required this.classeLibelle,
    required this.seanceLe,
    required this.etat,
    required this.regleEffective,
    required this.apercu,
    required this.version,
    this.enseignant,
    this.sourceRegle,
    this.historique,
    this.misAJourLe,
  });

  /// La seance.
  final String seanceId;

  /// L'eleve.
  final String eleveId;

  /// Le prenom de l'eleve (pour « Publier ce compte rendu pour la famille de
  /// {prenom} ? »).
  final String elevePrenom;

  /// La classe.
  final String classeLibelle;

  /// La date de la seance.
  final DateTime seanceLe;

  /// L'enseignant, si l'administration peut le lire.
  final String? enseignant;

  /// L'etat de diffusion de **ce** compte rendu.
  final EtatDiffusion etat;

  /// Vrai : le partage automatique est effectivement actif pour cet eleve.
  final bool regleEffective;

  /// D'ou vient cette regle effective, si la source le dit.
  final SourceRegle? sourceRegle;

  /// Exactement ce que la famille recevra : meme projection que le tuteur.
  final CompteRenduFamille apercu;

  /// Le jeton de concurrence optimiste de ce compte rendu.
  final String version;

  /// L'historique des actions. `null` : la source n'en fournit pas.
  final List<ActionPartage>? historique;

  /// La derniere mise a jour, si la source la donne.
  final DateTime? misAJourLe;

  /// Vrai si l'action coherente avec cet etat est « Publier » : le cahier est
  /// confirme, un contenu partageable existe, et le compte rendu n'est pas deja
  /// visible. Le serveur reste la barriere ; ceci ne decide que de l'affichage.
  bool get publiable =>
      apercu.aDuContenu &&
      (etat == EtatDiffusion.confirmeNonPartage ||
          etat == EtatDiffusion.revoque);

  /// Vrai si l'action coherente avec cet etat est « Revoquer ».
  bool get revocable =>
      etat == EtatDiffusion.partageAuto ||
      etat == EtatDiffusion.partageManuel ||
      etat == EtatDiffusion.corrigeApresPartageManuel;
}

/// Une ligne de la liste des comptes rendus d'un eleve (point d'entree vers
/// l'apercu).
@immutable
class LigneCompteRendu {
  /// Cree la ligne.
  const LigneCompteRendu({
    required this.seanceId,
    required this.seanceLe,
    required this.etat,
  });

  /// La seance.
  final String seanceId;

  /// Sa date.
  final DateTime seanceLe;

  /// L'etat de diffusion.
  final EtatDiffusion etat;
}

/// Le serveur a refuse l'ecriture parce que la valeur lue est perimee
/// (un autre administrateur a modifie entre-temps). L'ecran relit et informe ;
/// il n'ecrase jamais en silence.
class ConflitPartage implements Exception {
  /// Cree le conflit.
  const ConflitPartage();

  @override
  String toString() => 'ConflitPartage';
}

/// Le partage pedagogique (contrat PED-APRES, voir le document de contrat).
abstract interface class PortPartagePedagogique {
  /// Le compte rendu que la famille de [eleveId] peut lire pour [seanceId].
  /// Jamais le cahier brut.
  Future<CompteRenduFamille> compteRenduFamille({
    required String seanceId,
    required String eleveId,
  });

  /// Le reglage de partage de [classeId], page [page] (a partir de 1) de ses
  /// eleves, filtree par [recherche] si elle est donnee.
  Future<PartageClasse> partageClasse({
    required String classeId,
    int page = 1,
    String? recherche,
  });

  /// Pose la regle de classe. [versionAttendue] est celle que l'ecran a lue.
  /// Leve [ConflitPartage] si elle n'est plus a jour, [PermissionInsuffisante]
  /// si l'administrateur n'a pas le droit. Rend la valeur confirmee.
  Future<PartageClasse> definirPartageClasse({
    required String classeId,
    required bool actif,
    required String versionAttendue,
    required String cleIdempotence,
  });

  /// Pose la regle d'**un** eleve. Memes erreurs que [definirPartageClasse].
  Future<PartageClasse> definirRegleEleve({
    required String classeId,
    required String eleveId,
    required ReglePartageEleve regle,
    required String versionAttendue,
    required String cleIdempotence,
  });

  /// Les comptes rendus d'un eleve dans une classe, du plus recent au plus
  /// ancien.
  Future<List<LigneCompteRendu>> comptesRendusEleve({
    required String classeId,
    required String eleveId,
  });

  /// L'apercu familial exact et l'etat de diffusion d'un compte rendu.
  Future<ApercuAdmin> apercuFamilial({
    required String seanceId,
    required String eleveId,
  });

  /// Publie **ce** compte rendu pour la famille. Ne change ni la classe ni
  /// l'eleve. Memes erreurs que [definirPartageClasse].
  Future<ApercuAdmin> publier({
    required String seanceId,
    required String eleveId,
    required String versionAttendue,
    required String cleIdempotence,
  });

  /// Revoque l'acces de la famille a **ce** compte rendu. Le cahier et la
  /// seance restent valides.
  Future<ApercuAdmin> revoquer({
    required String seanceId,
    required String eleveId,
    required String versionAttendue,
    required String cleIdempotence,
  });
}

/// Le port de production tant que le serveur ne sert rien : chaque methode
/// leve `CapaciteIndisponible`, jamais un faux succes.
class PartagePedagogiqueIndisponible implements PortPartagePedagogique {
  /// Cree l'implementation.
  const PartagePedagogiqueIndisponible();

  /// La dependance nommee (trace et tests, jamais affichee).
  static const String dependance = 'PED-APRES-BACK';

  Future<T> _indisponible<T>() =>
      Future<T>.error(const CapaciteIndisponible(dependance));

  @override
  Future<CompteRenduFamille> compteRenduFamille({
    required String seanceId,
    required String eleveId,
  }) => _indisponible();

  @override
  Future<PartageClasse> partageClasse({
    required String classeId,
    int page = 1,
    String? recherche,
  }) => _indisponible();

  @override
  Future<PartageClasse> definirPartageClasse({
    required String classeId,
    required bool actif,
    required String versionAttendue,
    required String cleIdempotence,
  }) => _indisponible();

  @override
  Future<PartageClasse> definirRegleEleve({
    required String classeId,
    required String eleveId,
    required ReglePartageEleve regle,
    required String versionAttendue,
    required String cleIdempotence,
  }) => _indisponible();

  @override
  Future<List<LigneCompteRendu>> comptesRendusEleve({
    required String classeId,
    required String eleveId,
  }) => _indisponible();

  @override
  Future<ApercuAdmin> apercuFamilial({
    required String seanceId,
    required String eleveId,
  }) => _indisponible();

  @override
  Future<ApercuAdmin> publier({
    required String seanceId,
    required String eleveId,
    required String versionAttendue,
    required String cleIdempotence,
  }) => _indisponible();

  @override
  Future<ApercuAdmin> revoquer({
    required String seanceId,
    required String eleveId,
    required String versionAttendue,
    required String cleIdempotence,
  }) => _indisponible();
}

/// Choisit le port selon le mode de compilation.
///
/// **En production, aucune source n'existe** : [PartagePedagogiqueIndisponible].
/// La demonstration ne sort que sous `PLAYGROUND=true`, que le deploiement force
/// a `false` (meme regle que `portGroupesSelon`).
PortPartagePedagogique portPartagePedagogiqueSelon({required bool demo}) => demo
    ? PartagePedagogiqueDemonstration()
    : const PartagePedagogiqueIndisponible();

/// Le port de partage pedagogique employe par l'application.
final Provider<PortPartagePedagogique> portPartagePedagogiqueProvider =
    Provider<PortPartagePedagogique>(
      (Ref ref) => portPartagePedagogiqueSelon(demo: Env.playgroundActif),
    );
