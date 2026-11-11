// Lot RESEAU-PREUVE (directeur, 11/11/2026 ; cahier de la salle §6, defaut
// R-2) : l'envoi borne du releve de qualite de connexion. Dart pur, sans SDK
// ni widget.
//
// **Ce qui part de l'appareil, et rien d'autre** : quand l'etat filtre du
// lien de CE participant change (`seuils_reseau.dart` : 3 s tenues), un des
// trois mots « bon », « faible », « perdu », et si son micro est ouvert.
// Jamais de son, d'image, d'adresse, de mesure brute, ni l'heure de
// l'appareil : l'heure est celle du serveur, a l'ecriture. Jamais l'etat d'un
// autre participant : le serveur refuse d'ecrire la ligne d'un autre
// (`noter_qualite_lien`, migration 20261123000000).
//
// **Pourquoi l'appareil** : le serveur de visio ne dit la qualite d'un lien
// qu'aux applications connectees ; ni ses webhooks ni la liste des
// participants ne la portent.
//
// **Le rythme** : une ligne au plus toutes les [intervalleEnvoi]. Un etat qui
// change plus vite n'est pas perdu : le dernier etat part a l'echeance. Le
// serveur tient la meme borne de son cote (8 s) ; l'appareil ne fait que ne
// pas l'atteindre.
//
// Ce que la loi permet de garder, pourquoi, combien de temps et qui lit :
// `docs/current/salle/DROIT-RELEVE-QUALITE.md`.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../observabilite/journal_dev.dart';
import 'fermeture_salle.dart' show roleQuiAttend;
import 'publication_differee.dart' show roleQuiConduit;
import 'seuils_reseau.dart';
import 'video_session_provider.dart';

/// Le temps minimal entre deux lignes envoyees par un appareil.
///
/// Justification : le filtre de `seuils_reseau.dart` laisse passer au plus un
/// changement toutes les 3 s ; un lien qui bat ferait donc jusqu'a 1 200
/// lignes par heure. Dix secondes bornent a 360 lignes par heure (le serveur
/// plafonne a 400 par participant et par seance) et restent courtes devant
/// la question posee (« a-t-on pu s'entendre ? » se juge en dizaines de
/// secondes, pas en secondes).
const Duration intervalleEnvoi = Duration(seconds: 10);

/// Le nombre d'echecs de suite (reseau coupe, serveur injoignable) apres
/// lequel l'appareil cesse de reessayer jusqu'au prochain changement.
const int echecsAvantSilence = 3;

/// Les trois etats gardes. Le nom est le mot attendu par le serveur.
enum EtatReleve {
  /// Lien excellent ou bon : la voix passe.
  bon,

  /// Lien mediocre : la voix peut arriver abimee.
  faible,

  /// Lien perdu.
  perdu,
}

/// L'etat garde pour une qualite de lien, ou `null` : pas de mesure, donc
/// rien a ecrire (jamais un etat invente).
EtatReleve? etatRelevePour(QualiteLien qualite) => switch (qualite) {
  QualiteLien.excellente || QualiteLien.bonne => EtatReleve.bon,
  QualiteLien.mediocre => EtatReleve.faible,
  QualiteLien.perdue => EtatReleve.perdu,
  QualiteLien.inconnue => null,
};

/// Ce que le serveur a fait d'une ligne.
enum ReponseReleve {
  /// La ligne est ecrite.
  ecrite,

  /// Le serveur l'a ignoree (rythme, etat inchange, plafond) : rien a refaire.
  ignoree,

  /// Le serveur l'a refusee (pas participant, hors de la seance) : cet
  /// appareil n'ecrit plus rien pour cette entree en salle.
  refusee,
}

/// L'ecriture d'une ligne du releve au serveur.
abstract interface class PortReleveQualite {
  /// Ecrit l'etat du lien de [profilId] dans [seanceId]. Leve si le serveur
  /// est injoignable.
  Future<ReponseReleve> noter({
    required String seanceId,
    required String profilId,
    required EtatReleve etat,
    required bool microOuvert,
  });
}

/// Le port par defaut : n'ecrit rien (tests, demonstration, galerie).
/// L'application le remplace dans `lib/main.dart`.
class ReleveQualiteMuet implements PortReleveQualite {
  /// Cree le port muet.
  const ReleveQualiteMuet();

  @override
  Future<ReponseReleve> noter({
    required String seanceId,
    required String profilId,
    required EtatReleve etat,
    required bool microOuvert,
  }) async => ReponseReleve.ignoree;
}

/// Le port du releve employe par l'application.
final Provider<PortReleveQualite> portReleveQualiteProvider =
    Provider<PortReleveQualite>((Ref ref) => const ReleveQualiteMuet());

/// Ce qui est ecrit : l'etat, et le micro seulement quand le lien n'est pas
/// bon (sur un bon lien, on ne garde pas la trace des prises de parole).
typedef _Situation = ({EtatReleve etat, bool microOuvert});

bool _memeSituation(_Situation a, _Situation b) =>
    a.etat == b.etat &&
    (a.etat == EtatReleve.bon || a.microOuvert == b.microOuvert);

/// L'envoi borne du releve d'UN participant : celui de cet appareil.
///
/// [observer] est appele a chaque changement de la salle ; l'envoi ne part
/// que si la situation a change, et jamais plus d'une fois par
/// [intervalle]. Un echec n'arrete pas le cours : il est journalise en
/// developpement, retente au plus [echecsAvantSilence] fois, puis attend le
/// prochain changement.
class EnvoiReleve {
  /// Cree l'envoi. [port] est lu a chaque envoi (jamais a la construction).
  EnvoiReleve({
    required this.port,
    DateTime Function()? horloge,
    this.intervalle = intervalleEnvoi,
  }) : _horloge = horloge ?? DateTime.now;

  /// Rend le port du releve (celui de l'application, ou un faux en test).
  final PortReleveQualite Function() port;
  final DateTime Function() _horloge;

  /// Le temps minimal entre deux envois.
  final Duration intervalle;

  String? _seanceId;
  String? _profilId;
  _Situation? _envoyee;
  _Situation? _voulue;
  _Situation? _abandonnee;
  DateTime? _dernierEnvoi;
  Timer? _minuterie;
  bool _enVol = false;
  bool _refuse = false;
  int _echecs = 0;
  int _generation = 0;

  /// Prend l'etat de la salle : la liste des participants et les etats
  /// filtres de `SuiviReseau.etats()`. Seul le participant local compte, et
  /// seulement s'il est l'enseignant ou un eleve (un observateur n'a pas de
  /// ligne ; le serveur le refuserait).
  void observer({
    required String seanceId,
    required Iterable<ParticipantSalle> participants,
    required Map<String, EtatReseau> etats,
  }) {
    if (_refuse) return;
    ParticipantSalle? moi;
    for (final ParticipantSalle p in participants) {
      if (p.estLocal) moi = p;
    }
    if (moi == null || moi.identite.isEmpty) return;
    if (moi.role != roleQuiConduit && moi.role != roleQuiAttend) return;
    final EtatReseau? reseau = etats[moi.identite];
    final EtatReleve? etat = reseau == null
        ? null
        : etatRelevePour(reseau.qualite);
    if (etat == null) return;
    if (_seanceId != seanceId || _profilId != moi.identite) {
      // Une autre seance ou une autre personne : on repart de zero.
      remettre();
      _seanceId = seanceId;
      _profilId = moi.identite;
    }
    final _Situation situation = (etat: etat, microOuvert: moi.micro);
    final _Situation? abandonnee = _abandonnee;
    if (abandonnee != null) {
      // Les essais de cette situation ont echoue : on attend qu'elle change.
      if (_memeSituation(abandonnee, situation)) return;
      _abandonnee = null;
      _echecs = 0;
    }
    _voulue = situation;
    _avancer();
  }

  void _avancer() {
    final _Situation? voulue = _voulue;
    if (voulue == null || _enVol || _refuse) return;
    final _Situation? envoyee = _envoyee;
    if (envoyee != null && _memeSituation(envoyee, voulue)) {
      _minuterie?.cancel();
      _minuterie = null;
      return;
    }
    final DateTime maintenant = _horloge();
    final DateTime? dernier = _dernierEnvoi;
    final Duration attente = dernier == null
        ? Duration.zero
        : intervalle - maintenant.difference(dernier);
    if (attente > Duration.zero) {
      _minuterie?.cancel();
      _minuterie = Timer(attente, () {
        _minuterie = null;
        _avancer();
      });
      return;
    }
    _minuterie?.cancel();
    _minuterie = null;
    unawaited(_envoyer(voulue, maintenant));
  }

  Future<void> _envoyer(_Situation situation, DateTime maintenant) async {
    final String? seance = _seanceId;
    final String? profil = _profilId;
    if (seance == null || profil == null) return;
    final int generation = _generation;
    _enVol = true;
    _dernierEnvoi = maintenant;
    try {
      final ReponseReleve reponse = await port().noter(
        seanceId: seance,
        profilId: profil,
        etat: situation.etat,
        microOuvert: situation.microOuvert,
      );
      if (generation != _generation) return;
      if (reponse == ReponseReleve.refusee) {
        _refuse = true;
        _voulue = null;
        return;
      }
      // Ecrite ou ignoree par le serveur : dans les deux cas, rien a refaire.
      _envoyee = situation;
      _echecs = 0;
    } on Object catch (e) {
      if (generation != _generation) return;
      journalDev('salle.releve : ligne non ecrite : $e');
      _echecs++;
      if (_echecs >= echecsAvantSilence) {
        // On se tait jusqu'au prochain changement : pas de flot d'essais.
        _abandonnee = situation;
        _voulue = null;
      }
    } finally {
      if (generation == _generation) {
        _enVol = false;
        _avancer();
      }
    }
  }

  /// Oublie ce qui a ete envoye (nouvelle entree en salle) : le premier etat
  /// stable de la nouvelle entree repart. L'heure du dernier envoi, elle,
  /// est gardee : une sortie puis une entree rapides ne passent pas sous le
  /// rythme (le serveur ignorerait la ligne, et l'etat serait perdu).
  void remettre() {
    _generation++;
    _minuterie?.cancel();
    _minuterie = null;
    _seanceId = null;
    _profilId = null;
    _envoyee = null;
    _voulue = null;
    _abandonnee = null;
    _enVol = false;
    _refuse = false;
    _echecs = 0;
  }

  /// Arrete la minuterie (sortie de la salle).
  void fermer() => remettre();
}
