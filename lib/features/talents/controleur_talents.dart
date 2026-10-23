// Le parcours « Vos autres talents » (`CAND-07`) : ce que la personne a choisi
// jusqu'ici et ou elle en est. Un controleur sans logique de passage : il garde
// des choix, dit ce qui manque pour continuer, et compose ce qu'on envoie. Il ne
// valide rien a la place du serveur (le catalogue, la regle d'une competence
// desactivee et la borne du texte restent ceux du serveur) et ne decide d'aucun
// droit.
//
// Quatre etapes : l'introduction (ce que l'academie fait de ces reponses), les
// competences, le niveau de chacune, la disponibilite et l'accord. Une personne
// qui revient modifier ses reponses saute l'introduction.
library;

import 'package:flutter/foundation.dart';

import '../../core/candidature/modeles_autres_competences.dart';
import '../../core/candidature/port_ma_candidature.dart'
    show nouvelleCleIdempotence;

/// Une etape du parcours.
enum EtapeTalents {
  /// Pourquoi l'academie demande, et ce qu'elle en fait.
  introduction,

  /// Les competences, par famille.
  competences,

  /// Le niveau de chaque competence choisie.
  niveaux,

  /// La disponibilite et l'accord d'etre contacte.
  disponibilite,
}

/// Ce qui manque pour continuer.
enum ManqueTalents {
  /// Aucune competence choisie.
  aucuneCompetence,

  /// « Autre domaine » est choisi sans texte.
  autreVide,

  /// Le texte « Autre domaine » depasse la borne du serveur.
  autreTropLong,

  /// Une competence choisie n'a pas de niveau.
  niveau,

  /// Aucune disponibilite choisie.
  disponibilite,
}

/// Ce que la personne a choisi et pas encore enregistre : de quoi reprendre le
/// parcours apres une relecture du serveur sans lui faire tout ressaisir.
@immutable
class BrouillonTalents {
  /// Cree un brouillon.
  const BrouillonTalents({
    required this.choisies,
    required this.niveaux,
    required this.autreTexte,
    required this.disponibilite,
    required this.accord,
  });

  /// Les codes des competences choisies.
  final Set<String> choisies;

  /// Le niveau de chacune, quand il est choisi.
  final Map<String, NiveauCompetence> niveaux;

  /// Le texte « Autre domaine », tel que saisi.
  final String autreTexte;

  /// La disponibilite choisie, ou `null`.
  final DisponibiliteMission? disponibilite;

  /// L'accord d'etre contacte.
  final bool accord;
}

/// Le parcours des autres competences.
class ControleurTalents extends ChangeNotifier {
  /// Cree le parcours a partir de la lecture du serveur. [avecIntroduction]
  /// faux : la personne modifie des reponses deja enregistrees. [reprise] : un
  /// brouillon a reprendre a la place des reponses enregistrees (une competence
  /// choisie venait d'etre retiree du catalogue) ; une competence que la lecture
  /// ne propose plus en est ecartee, tout le reste est garde.
  ControleurTalents({
    required this.lecture,
    required bool avecIntroduction,
    BrouillonTalents? reprise,
  }) : etapes = List<EtapeTalents>.unmodifiable(<EtapeTalents>[
         if (avecIntroduction) EtapeTalents.introduction,
         EtapeTalents.competences,
         EtapeTalents.niveaux,
         EtapeTalents.disponibilite,
       ]) {
    if (reprise != null) {
      final Set<String> enregistrees =
          lecture.reponses?.domaines.keys.toSet() ?? const <String>{};
      bool proposee(String code) {
        final EntreeCatalogue? e = lecture.referentiel.entree(code);
        return e != null && (e.actif || enregistrees.contains(code));
      }

      for (final String code in reprise.choisies) {
        if (proposee(code)) {
          _choisies.add(code);
          if (reprise.niveaux[code] case final NiveauCompetence n) {
            _niveaux[code] = n;
          }
        }
      }
      _autreTexte = reprise.autreTexte;
      _disponibilite = reprise.disponibilite;
      _accord = reprise.accord;
      return;
    }
    final ReponsesAutresCompetences? r = lecture.reponses;
    if (r != null) {
      _choisies.addAll(r.domaines.keys);
      _niveaux.addAll(r.domaines);
      _autreTexte = r.autreTexte ?? '';
      _disponibilite = r.disponibilite;
      _accord = r.accord;
    }
  }

  /// Ce que le serveur a rendu a l'ouverture : la version attendue, le
  /// catalogue et les listes.
  final AutresCompetences lecture;

  /// Les etapes, dans l'ordre.
  final List<EtapeTalents> etapes;

  int _index = 0;
  final Set<String> _choisies = <String>{};
  final Map<String, NiveauCompetence> _niveaux = <String, NiveauCompetence>{};
  String _autreTexte = '';
  DisponibiliteMission? _disponibilite;
  bool _accord = false;
  String? _cle;
  String? _empreinte;

  /// Le rang de l'etape courante, a partir de 0.
  int get index => _index;

  /// L'etape courante.
  EtapeTalents get courante => etapes[_index];

  /// Vrai a la premiere etape : « Retour » sort du parcours.
  bool get estPremiere => _index == 0;

  /// Vrai a la derniere etape : le bouton plein enregistre.
  bool get estDerniere => _index == etapes.length - 1;

  /// Passe a l'etape suivante.
  void avancer() {
    if (!estDerniere) {
      _index++;
      notifyListeners();
    }
  }

  /// Revient a l'etape precedente.
  void reculer() {
    if (!estPremiere) {
      _index--;
      notifyListeners();
    }
  }

  // --- Les competences -----------------------------------------------------

  /// Vrai quand la competence [code] est choisie.
  bool estChoisie(String code) => _choisies.contains(code);

  /// Les codes choisis parmi [codes] (une famille).
  Set<String> choisiesParmi(Iterable<String> codes) => <String>{
    for (final String c in codes)
      if (_choisies.contains(c)) c,
  };

  /// Pose le choix d'une famille : parmi [codes], seuls [retenus] sont choisis.
  /// Le niveau d'une competence qu'on retire s'oublie ; celui d'une competence
  /// gardee reste.
  void definirFamille(Iterable<String> codes, Set<String> retenus) {
    for (final String code in codes) {
      if (retenus.contains(code)) {
        _choisies.add(code);
      } else {
        _choisies.remove(code);
        _niveaux.remove(code);
      }
    }
    notifyListeners();
  }

  /// Le nombre de competences choisies.
  int get nombreChoisies => _choisies.length;

  /// Les competences choisies, dans l'ordre du catalogue. Un code que le
  /// catalogue ne rend pas n'y est pas (il garde pourtant son niveau, renvoye
  /// tel quel au serveur).
  List<EntreeCatalogue> get competencesChoisies => <EntreeCatalogue>[
    for (final EntreeCatalogue e in lecture.referentiel.competences)
      if (_choisies.contains(e.code)) e,
  ];

  /// Vrai quand « Autre domaine » est choisi.
  bool get autreChoisi => _choisies.contains(EntreeCatalogue.codeAutre);

  /// Le texte « Autre domaine », tel que saisi.
  String get autreTexte => _autreTexte;

  /// Pose le texte « Autre domaine ».
  void definirAutreTexte(String texte) {
    _autreTexte = texte;
    notifyListeners();
  }

  // --- Les niveaux ---------------------------------------------------------

  /// Le niveau de la competence [code], ou `null`.
  NiveauCompetence? niveau(String code) => _niveaux[code];

  /// Pose le niveau de la competence [code].
  void definirNiveau(String code, NiveauCompetence niveau) {
    _niveaux[code] = niveau;
    notifyListeners();
  }

  /// Le code de la premiere competence choisie sans niveau, ou `null`.
  String? get premierSansNiveau {
    for (final String code in _choisies) {
      if (!_niveaux.containsKey(code)) {
        return code;
      }
    }
    return null;
  }

  // --- Disponibilite et accord ---------------------------------------------

  /// La disponibilite choisie, ou `null`.
  DisponibiliteMission? get disponibilite => _disponibilite;

  /// Pose la disponibilite.
  void definirDisponibilite(DisponibiliteMission dispo) {
    _disponibilite = dispo;
    notifyListeners();
  }

  /// L'accord d'etre contacte pour une mission.
  bool get accord => _accord;

  /// Pose l'accord.
  void definirAccord({required bool accord}) {
    _accord = accord;
    notifyListeners();
  }

  // --- Ce qui manque -------------------------------------------------------

  /// Ce qui manque pour quitter [etape], ou `null` quand on peut continuer.
  ManqueTalents? manque(EtapeTalents etape) {
    switch (etape) {
      case EtapeTalents.introduction:
        return null;
      case EtapeTalents.competences:
        if (_choisies.isEmpty) {
          return ManqueTalents.aucuneCompetence;
        }
        if (autreChoisi) {
          final String texte = _autreTexte.trim();
          if (texte.isEmpty) {
            return ManqueTalents.autreVide;
          }
          if (texte.runes.length > lecture.referentiel.autreTexteMax) {
            return ManqueTalents.autreTropLong;
          }
        }
        return null;
      case EtapeTalents.niveaux:
        return premierSansNiveau == null ? null : ManqueTalents.niveau;
      case EtapeTalents.disponibilite:
        return _disponibilite == null ? ManqueTalents.disponibilite : null;
    }
  }

  /// Ce qui manque pour enregistrer, toutes etapes confondues, avec l'etape a
  /// rouvrir : `null` quand tout y est.
  ({EtapeTalents etape, ManqueTalents manque})? get premierManque {
    for (final EtapeTalents e in <EtapeTalents>[
      EtapeTalents.competences,
      EtapeTalents.niveaux,
      EtapeTalents.disponibilite,
    ]) {
      final ManqueTalents? m = manque(e);
      if (m != null) {
        return (etape: e, manque: m);
      }
    }
    return null;
  }

  // --- Ce qu'on envoie -----------------------------------------------------

  /// Les domaines et leur niveau, tels qu'envoyes au serveur.
  Map<String, NiveauCompetence> get domainesAEnvoyer =>
      <String, NiveauCompetence>{
        for (final String code in _choisies)
          if (_niveaux[code] case final NiveauCompetence n) code: n,
      };

  /// Le texte « Autre domaine » envoye : sans blancs de bord, et seulement si le
  /// domaine est choisi.
  String? get autreTexteAEnvoyer => autreChoisi ? _autreTexte.trim() : null;

  /// La cle d'idempotence de l'enregistrement en cours : la meme tant que ce
  /// qu'on envoie ne change pas (une issue incertaine se rejoue sans risque),
  /// neuve des qu'une reponse change.
  String cleIdempotence() {
    final String empreinte = <String>[
      for (final MapEntry<String, NiveauCompetence> e
          in (domainesAEnvoyer.entries.toList()..sort(
            (
              MapEntry<String, NiveauCompetence> a,
              MapEntry<String, NiveauCompetence> b,
            ) => a.key.compareTo(b.key),
          )))
        '${e.key}=${e.value.valeurSql}',
      autreTexteAEnvoyer ?? '',
      _disponibilite?.valeurSql ?? '',
      '$_accord',
      '${lecture.version}',
    ].join('|');
    if (_cle == null || _empreinte != empreinte) {
      _cle = nouvelleCleIdempotence();
      _empreinte = empreinte;
    }
    return _cle!;
  }

  /// Oublie la cle : la reponse du serveur est definitive.
  void oublierCle() {
    _cle = null;
    _empreinte = null;
  }

  /// Ce qui est choisi a cet instant, pour reprendre le parcours apres une
  /// relecture (voir [BrouillonTalents]).
  BrouillonTalents brouillon() => BrouillonTalents(
    choisies: Set<String>.unmodifiable(_choisies),
    niveaux: Map<String, NiveauCompetence>.unmodifiable(_niveaux),
    autreTexte: _autreTexte,
    disponibilite: _disponibilite,
    accord: _accord,
  );
}
