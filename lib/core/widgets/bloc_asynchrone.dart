import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';
import '../i18n/strings.g.dart';
import '../mouvement/bascule_etat.dart';
import '../theme/app_delais.dart';
import '../theme/app_spacing.dart';
import 'etat_systeme.dart';

/// Un bloc de page qui lit une valeur asynchrone (contrat K5).
///
/// Quatre temps, dans cet ordre, et jamais un autre :
///
/// 1. **squelette** a la forme du contenu (le delai d'apparition,
///    `AppMouvement.apparition` soit 180 ms, est tenu par `Skeleton`) ;
/// 2. passe [AppDelais.chargementProlonge], le squelette reste et une phrase
///    dit que c'est long (`NatureEtat.chargementProlonge`) ;
/// 3. passe [AppDelais.requeteMax], la tentative est **tenue pour perdue** :
///    erreur de bloc, la page autour reste en place ;
/// 4. le contenu, ou [vide] quand la valeur est vide.
///
/// Regles portees ici plutot que par chaque ecran :
///
/// - un `CapaciteIndisponible` n'est pas une erreur : il rend
///   `NatureEtat.indisponible`, **sans** « Reessayer » (une capacite absente
///   ne revient pas en insistant) ;
/// - « Reessayer » est borne a [reessaisMax] pressions consecutives sans
///   succes, jamais relance tout seul : pas de boucle ;
/// - une reponse qui arrive **apres** que la tentative a ete declaree perdue
///   est ignoree jusqu'a la tentative suivante : l'ecran ne passe pas d'un
///   echec annonce a un contenu sans que la personne l'ait demande ;
/// - quitter l'ecran annule les minuteries : une reponse tardive ne rouvre
///   rien ;
/// - l'`AsyncValue` se lit par `hasValue`, `hasError`, `isLoading`, jamais
///   par son type (Riverpod 3 relance un provider en echec en gardant
///   `hasError`, `lib/CLAUDE.md`). Une valeur deja la reste affichee pendant
///   un rafraichissement.
class BlocAsynchrone<T> extends StatefulWidget {
  /// Cree un bloc.
  const BlocAsynchrone({
    required this.valeur,
    required this.squelette,
    required this.construire,
    super.key,
    this.onReessayer,
    this.vide,
    this.estVide,
    this.titreProlonge,
    this.titreEchec,
    this.erreurVersEtat,
    this.piedEchec,
  });

  /// Ce que la page garde sous tout echec ou indisponibilite de ce bloc
  /// (erreur typee, erreur par defaut, tentative perdue) : une source en
  /// echec n'emporte que ce qu'elle remplit (D11). Le squelette et le
  /// contenu placent eux-memes ce bloc. Nul : rien dessous.
  final Widget? piedEchec;

  /// Le titre du chargement prolonge propre a l'ecran. Nul : celui de la
  /// nature.
  final String? titreProlonge;

  /// Le titre de l'echec propre a l'ecran. Nul : celui de la nature.
  final String? titreEchec;

  /// Rend un etat propre a une erreur typee (permission, hors ligne, capacite
  /// absente...), consulte AVANT le cas `CapaciteIndisponible`. Nul, ou
  /// rendant nul : traitement par defaut. Recoit « Reessayer » quand il en
  /// reste.
  final Widget? Function(Object erreur, VoidCallback? reessayer)?
  erreurVersEtat;

  /// La valeur lue, telle que le provider la rend.
  final AsyncValue<T> valeur;

  /// La forme du contenu pendant le chargement.
  final Widget squelette;

  /// Le contenu, une fois la valeur la.
  final Widget Function(T valeur) construire;

  /// Relance la lecture (en general `ref.invalidate`). Sans lui, aucun
  /// bouton « Reessayer » n'est rendu.
  final VoidCallback? onReessayer;

  /// L'etat « aucun resultat ». Sans lui, une valeur vide passe par
  /// [construire].
  final Widget? vide;

  /// Dit si une valeur est vide. Par defaut : `null`, une collection vide ou
  /// une table vide.
  final bool Function(T valeur)? estVide;

  /// Nombre de pressions consecutives sur « Reessayer » sans succes, au-dela
  /// duquel le bouton disparait au profit d'une phrase.
  static const int reessaisMax = 3;

  @override
  State<BlocAsynchrone<T>> createState() => _BlocAsynchroneState<T>();
}

/// Ou en est une attente.
enum _Attente { normale, prolongee, perdue }

/// Le temps affiche, qui cle le fondu de [BasculeEtat].
enum _Temps { chargement, contenu, vide, echec, indisponible }

class _BlocAsynchroneState<T> extends State<BlocAsynchrone<T>> {
  Timer? _prolongement;
  Timer? _perte;
  _Attente _attente = _Attente.normale;
  int _reessais = 0;

  static bool _enAttente(AsyncValue<Object?> v) => !v.hasValue && !v.hasError;

  @override
  void initState() {
    super.initState();
    if (_enAttente(widget.valeur)) {
      _armer();
    }
  }

  @override
  void didUpdateWidget(BlocAsynchrone<T> ancien) {
    super.didUpdateWidget(ancien);
    // Tentative declaree perdue : ce qui arrive maintenant lui appartient
    // encore, et reste ignore jusqu'a la prochaine pression.
    if (_attente == _Attente.perdue) {
      return;
    }
    final bool attend = _enAttente(widget.valeur);
    if (attend && !_enAttente(ancien.valeur)) {
      _armer();
    } else if (!attend) {
      _desarmer();
      _attente = _Attente.normale;
      if (widget.valeur.hasValue && !widget.valeur.hasError) {
        _reessais = 0;
      }
    }
  }

  @override
  void dispose() {
    _desarmer();
    super.dispose();
  }

  void _armer() {
    _desarmer();
    _attente = _Attente.normale;
    _prolongement = Timer(AppDelais.chargementProlonge, () {
      if (mounted && _attente == _Attente.normale) {
        setState(() => _attente = _Attente.prolongee);
      }
    });
    _perte = Timer(AppDelais.requeteMax, () {
      if (mounted) {
        setState(() => _attente = _Attente.perdue);
      }
    });
  }

  void _desarmer() {
    _prolongement?.cancel();
    _perte?.cancel();
    _prolongement = null;
    _perte = null;
  }

  bool get _peutReessayer =>
      widget.onReessayer != null && _reessais < BlocAsynchrone.reessaisMax;

  void _reessayer() {
    if (!_peutReessayer) {
      return;
    }
    setState(() {
      _reessais++;
      _attente = _Attente.normale;
    });
    // Une nouvelle tentative : nouvelles minuteries, meme si la valeur
    // n'a pas encore change d'etat.
    if (_enAttente(widget.valeur)) {
      _armer();
    }
    widget.onReessayer!();
  }

  bool _vide(T valeur) {
    final bool Function(T valeur)? predicat = widget.estVide;
    if (predicat != null) {
      return predicat(valeur);
    }
    final Object? v = valeur;
    return v == null ||
        (v is Iterable<Object?> && v.isEmpty) ||
        (v is Map<Object?, Object?> && v.isEmpty);
  }

  /// L'echec de bloc, avec « Reessayer » tant qu'il reste des essais.
  Widget _echec({bool enCours = false}) => EtatSysteme(
    nature: NatureEtat.echecServeur,
    titre: widget.titreEchec,
    phrase: widget.onReessayer != null && !_peutReessayer
        ? t.commun.etats.reessaisEpuises
        : (widget.titreEchec != null ? '' : null),
    onAction: _peutReessayer ? _reessayer : null,
    actionEnCours: enCours,
  );

  /// Le passage d'un temps a l'autre (squelette, contenu, vide, echec,
  /// indisponible) se fait en fondu court (P2-16) ; un rafraichissement qui
  /// reste dans le meme temps ne relance rien.
  @override
  Widget build(BuildContext context) {
    final (_Temps temps, Widget enfant) = _rendu();
    final Widget? pied = widget.piedEchec;
    final bool echoue = temps == _Temps.echec || temps == _Temps.indisponible;
    return BasculeEtat(
      etat: temps,
      child: pied == null || !echoue
          ? enfant
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[enfant, pied],
            ),
    );
  }

  (_Temps, Widget) _rendu() {
    final AsyncValue<T> v = widget.valeur;

    if (_attente == _Attente.perdue) {
      return (_Temps.echec, _echec());
    }
    if (v.hasError) {
      final Object? erreur = v.error;
      final Widget? propre = erreur == null
          ? null
          : widget.erreurVersEtat?.call(
              erreur,
              _peutReessayer ? _reessayer : null,
            );
      if (propre != null) {
        return (_Temps.indisponible, propre);
      }
      if (erreur is CapaciteIndisponible) {
        return (
          _Temps.indisponible,
          EtatSysteme(
            nature: NatureEtat.indisponible,
            dependance: erreur.dependance,
          ),
        );
      }
      return (_Temps.echec, _echec(enCours: v.isLoading));
    }
    if (v.hasValue) {
      final T valeur = v.requireValue;
      final Widget? vide = widget.vide;
      if (vide != null && _vide(valeur)) {
        return (_Temps.vide, vide);
      }
      return (_Temps.contenu, widget.construire(valeur));
    }
    if (_attente == _Attente.prolongee) {
      final Widget prolonge = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          widget.squelette,
          Ecart.vMd,
          EtatSysteme(
            nature: NatureEtat.chargementProlonge,
            titre: widget.titreProlonge,
            phrase: widget.titreProlonge != null ? '' : null,
            onAction: _peutReessayer ? _reessayer : null,
          ),
        ],
      );
      return (_Temps.chargement, prolonge);
    }
    return (_Temps.chargement, widget.squelette);
  }
}
