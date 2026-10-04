// Le composer d'un message vocal, `VoiceMessageComposer` (spec
// Communications V1, section 11 ; accessibilite, section 24 ; recette
// R-COM-03 et R-COM-04).
//
// Il se pose dans l'emplacement vocal du composer des communications
// (`FilDiscussion.emplacementVocal`, pose par COM-F), sous le champ texte. Le
// branchement dans Messages et Le Studio est fait a COM-FUS.
//
// Regles tenues ici :
//
// - **jamais d'envoi automatique a l'arret** : « Arreter » et la limite de
//   3:00 menent a la pre-ecoute (duree, ecoute, « Supprimer », « Envoyer ») ;
//   seul le bouton « Envoyer » appelle [ComposerVocal.onEnvoyer] ;
// - la permission du micro s'explique avant d'etre demandee ; refusee, elle
//   se dit avec la phrase exacte de la spec et « Fermer » (aucun paquet ne
//   permet d'ouvrir les reglages : UX_REVIEW_COMMUNICATIONS_L0, point 10) ;
// - « Pause », « Reprendre », « Supprimer », « Envoyer » sont des boutons
//   nommes (`ActionPrincipale`), lus tels quels par le lecteur d'ecran ;
//   l'etat se dit en mots dans une region vivante, la duree en toutes
//   lettres ; la barre de progression est decorative ;
// - un bouton qui ne peut pas aboutir n'est pas rendu (hors ligne :
//   « Envoyer » laisse la place a une phrase, le vocal est garde) ;
// - le port d'enregistrement est neutre en production
//   (`EnregistreurVocalIndisponible`) : le composer dit alors que le vocal
//   n'est pas disponible, sans jamais simuler un micro.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/lien_fleche.dart';
import 'etats_vocal.dart';
import 'lecteur_vocal.dart';
import 'port_enregistreur_vocal.dart';

/// L'intervalle de rafraichissement de la duree affichee pendant
/// l'enregistrement. La limite, elle, a sa propre minuterie, exacte.
const Duration _intervalleAffichage = Duration(seconds: 1);

/// La part de la hauteur d'ecran qu'un panneau du composer occupe au plus.
const double _partEcranMax = 0.5;

/// Ce que le composer sait du micro avant tout geste.
enum _Disponibilite {
  /// Lecture de l'etat du micro : rien n'est rendu (pas de bouton qui
  /// clignote).
  verification,

  /// Un enregistreur repond.
  disponible,

  /// Aucun enregistreur (port neutre, `CapaciteIndisponible`).
  indisponible,

  /// La lecture de l'etat du micro a echoue : « Reessayer ».
  erreur,
}

/// Le composer d'un message vocal.
class ComposerVocal extends ConsumerStatefulWidget {
  /// Cree le composer.
  const ComposerVocal({required this.onEnvoyer, super.key});

  /// L'envoi d'un vocal : le futur se termine sur l'accuse du serveur, et
  /// echoue si l'envoi n'est pas confirme (le vocal est alors garde).
  final Future<void> Function(EnregistrementVocal vocal) onEnvoyer;

  /// « Enregistrer un message vocal ».
  static const ValueKey<String> cleEnregistrer = ValueKey<String>(
    'vocal-enregistrer',
  );

  /// « Autoriser le microphone ».
  static const ValueKey<String> cleAutoriser = ValueKey<String>(
    'vocal-autoriser',
  );

  /// « Annuler » (avant la demande d'autorisation).
  static const ValueKey<String> cleAnnuler = ValueKey<String>('vocal-annuler');

  /// « Fermer » (permission refusee).
  static const ValueKey<String> cleFermer = ValueKey<String>('vocal-fermer');

  /// « Pause ».
  static const ValueKey<String> clePause = ValueKey<String>('vocal-pause');

  /// « Reprendre ».
  static const ValueKey<String> cleReprendre = ValueKey<String>(
    'vocal-reprendre',
  );

  /// « Arreter ».
  static const ValueKey<String> cleArreter = ValueKey<String>('vocal-arreter');

  /// « Supprimer » (demande).
  static const ValueKey<String> cleSupprimer = ValueKey<String>(
    'vocal-supprimer',
  );

  /// « Supprimer » (confirmation).
  static const ValueKey<String> cleConfirmerSuppression = ValueKey<String>(
    'vocal-supprimer-confirmer',
  );

  /// « Garder ».
  static const ValueKey<String> cleGarder = ValueKey<String>('vocal-garder');

  /// « Envoyer ».
  static const ValueKey<String> cleEnvoyer = ValueKey<String>('vocal-envoyer');

  /// « Reessayer » (envoi non confirme).
  static const ValueKey<String> cleReessayer = ValueKey<String>(
    'vocal-reessayer',
  );

  /// L'etat ecrit, region vivante.
  static const ValueKey<String> cleStatut = ValueKey<String>('vocal-statut');

  /// La duree ecrite (« 0:12 sur 3:00 », « Duree : 0:42 »).
  static const ValueKey<String> cleDuree = ValueKey<String>('vocal-duree');

  /// La phrase d'indisponibilite.
  static const ValueKey<String> cleIndisponible = ValueKey<String>(
    'vocal-indisponible',
  );

  /// Le titre d'un etat du composer (lu dans la region vivante).
  static String titreEtat(EtatVocal etat) {
    final c = t.com.vocal.composer;
    return switch (etat) {
      EtatVocal.permissionRequise => c.permissionTitre,
      EtatVocal.permissionRefusee => c.refuse,
      EtatVocal.enregistrement || EtatVocal.limiteProche => c.enregistrement,
      EtatVocal.reprise => c.reprise,
      EtatVocal.pause => c.pause,
      EtatVocal.limiteAtteinte || EtatVocal.preEcoute => c.preEcoute,
      EtatVocal.supprimer => c.confirmerTitre,
      EtatVocal.envoi => c.envoi,
      EtatVocal.echecEnvoi => c.nonConfirme,
      EtatVocal.envoye => c.envoye,
      EtatVocal.repos ||
      EtatVocal.vocalRecu ||
      EtatVocal.lecture ||
      EtatVocal.pauseLecture ||
      EtatVocal.finLecture => c.libelle,
    };
  }

  @override
  ConsumerState<ComposerVocal> createState() => _ComposerVocalState();
}

class _ComposerVocalState extends ConsumerState<ComposerVocal> {
  final MachineEnregistrementVocal _machine = MachineEnregistrementVocal();
  late final PortEnregistreurVocal _port = ref.read(
    portEnregistreurVocalProvider,
  );
  late final HorlogeVocale _horloge = ref.read(horlogeVocaleProvider);

  _Disponibilite _disponibilite = _Disponibilite.verification;
  EnregistrementVocal? _vocal;
  Timer? _rafraichir;
  Timer? _limite;
  bool _occupe = false;
  String? _erreurMicro;

  @override
  void initState() {
    super.initState();
    unawaited(_verifier());
  }

  @override
  void dispose() {
    _desarmer();
    // Quitter l'ecran ne garde pas de vocal : il n'y a pas de brouillon vocal
    // en V1. Un enregistrement en cours est abandonne, un vocal arrete et pas
    // envoye est efface. Un vocal en cours d'envoi est laisse a l'envoi.
    final EnregistrementVocal? vocal = _vocal;
    if (_machine.enCours) {
      unawaited(_port.abandonner().then((_) {}, onError: (Object _) {}));
    } else if (vocal != null && _machine.etat != EtatVocal.envoi) {
      unawaited(_port.supprimer(vocal).then((_) {}, onError: (Object _) {}));
    }
    super.dispose();
  }

  // --- Micro ---------------------------------------------------------------

  Future<void> _verifier() async {
    if (_disponibilite != _Disponibilite.verification) {
      setState(() => _disponibilite = _Disponibilite.verification);
    }
    _Disponibilite lue;
    try {
      await _port.permission();
      lue = _Disponibilite.disponible;
    } on CapaciteIndisponible {
      lue = _Disponibilite.indisponible;
    } on Object {
      lue = _Disponibilite.erreur;
    }
    if (mounted) setState(() => _disponibilite = lue);
  }

  /// Un appel au micro a echoue en cours de route : l'enregistrement est
  /// abandonne, la phrase dit quoi faire.
  void _echecMicro(Object erreur, String phrase) {
    if (!mounted) return;
    _desarmer();
    setState(() {
      _machine.annulerDemarrage();
      _vocal = null;
      if (erreur is CapaciteIndisponible) {
        _disponibilite = _Disponibilite.indisponible;
        _erreurMicro = null;
      } else {
        _erreurMicro = phrase;
      }
    });
  }

  Future<void> _enregistrer() async {
    if (_occupe) return;
    setState(() {
      _occupe = true;
      _erreurMicro = null;
    });
    try {
      // Relue a chaque geste : la personne a pu changer ses reglages.
      final PermissionMicro permission = await _port.permission();
      if (!mounted) return;
      switch (permission) {
        case PermissionMicro.accordee:
          await _demarrer();
        case PermissionMicro.aDemander:
          setState(_machine.exigerPermission);
        case PermissionMicro.refusee:
          setState(_machine.refuserPermission);
      }
    } on Object catch (erreur) {
      _echecMicro(erreur, t.com.vocal.composer.erreurDemarrage);
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  Future<void> _autoriser() async {
    if (_occupe) return;
    setState(() => _occupe = true);
    try {
      final PermissionMicro reponse = await _port.demanderPermission();
      if (!mounted) return;
      switch (reponse) {
        case PermissionMicro.accordee:
          await _demarrer();
        case PermissionMicro.refusee:
          setState(_machine.refuserPermission);
        case PermissionMicro.aDemander:
          // La question a ete ecartee sans reponse : l'explication reste.
          break;
      }
    } on Object catch (erreur) {
      _echecMicro(erreur, t.com.vocal.composer.erreurDemarrage);
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  Future<void> _demarrer() async {
    await _port.demarrer();
    if (!mounted) return;
    setState(() => _machine.demarrer(_horloge()));
    _armer();
  }

  void _armer() {
    _desarmer();
    _rafraichir = Timer.periodic(_intervalleAffichage, (_) => _surTic());
    _limite = Timer(_machine.restant(_horloge()), _surTic);
  }

  void _desarmer() {
    _rafraichir?.cancel();
    _limite?.cancel();
    _rafraichir = null;
    _limite = null;
  }

  void _surTic() {
    if (!mounted || !_machine.enregistre) return;
    final bool limite = _machine.tic(_horloge());
    if (limite) {
      // R-COM-04 : arret a 3:00, puis pre-ecoute. Rien ne part.
      unawaited(_arreter(limite: true));
    } else {
      setState(() {});
    }
  }

  Future<void> _mettreEnPause() async {
    if (!_machine.enregistre) return;
    final DateTime maintenant = _horloge();
    _desarmer();
    setState(() => _machine.mettreEnPause(maintenant));
    try {
      await _port.mettreEnPause();
    } on Object catch (erreur) {
      _echecMicro(erreur, t.com.vocal.composer.erreurInterrompu);
    }
  }

  Future<void> _reprendre() async {
    // Un second toucher pendant que le micro repart ne fait rien.
    if (_occupe || _machine.etat != EtatVocal.pause) return;
    _occupe = true;
    try {
      await _port.reprendre();
    } on Object catch (erreur) {
      _echecMicro(erreur, t.com.vocal.composer.erreurInterrompu);
      return;
    } finally {
      _occupe = false;
    }
    if (!mounted || _machine.etat != EtatVocal.pause) return;
    setState(() => _machine.reprendre(_horloge()));
    _armer();
  }

  Future<void> _arreter({bool limite = false}) async {
    if (!_machine.enCours) return;
    final DateTime maintenant = _horloge();
    _desarmer();
    final Duration duree = _machine.arreter(maintenant, limite: limite);
    setState(() {});
    try {
      final EnregistrementVocal vocal = await _port.arreter(duree: duree);
      if (!mounted) return;
      setState(() => _vocal = vocal);
    } on Object catch (erreur) {
      _echecMicro(erreur, t.com.vocal.composer.erreurInterrompu);
    }
  }

  // --- Suppression ---------------------------------------------------------

  void _demanderSuppression() => setState(_machine.demanderSuppression);

  void _garder() => setState(_machine.garder);

  Future<void> _confirmerSuppression() async {
    final bool enPause = _machine.suppressionEnPause;
    final EnregistrementVocal? vocal = _vocal;
    setState(() {
      _machine.confirmerSuppression();
      _vocal = null;
    });
    try {
      if (enPause) {
        await _port.abandonner();
      } else if (vocal != null) {
        await _port.supprimer(vocal);
      }
    } on Object {
      // Le vocal n'est plus propose : un effacement local qui echoue ne
      // change rien a ce que la personne voit ni a ce qui part.
    }
  }

  // --- Envoi ---------------------------------------------------------------

  Future<void> _envoyer() async {
    final EnregistrementVocal? vocal = _vocal;
    if (vocal == null || _machine.etat == EtatVocal.envoi) return;
    setState(_machine.envoyer);
    try {
      await widget.onEnvoyer(vocal);
      if (!mounted) return;
      setState(() {
        _machine.confirmerEnvoi();
        _vocal = null;
      });
    } on Object {
      if (!mounted) return;
      setState(_machine.echouer);
    }
  }

  // --- Rendu ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final c = t.com.vocal.composer;
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );

    final Widget contenu = switch (_disponibilite) {
      _Disponibilite.verification => const SizedBox.shrink(),
      _Disponibilite.indisponible => Text(
        c.indisponible,
        key: ComposerVocal.cleIndisponible,
        style: discret,
      ),
      _Disponibilite.erreur => _Panneau(
        titre: c.erreurVerificationTitre,
        alerte: true,
        actions: <Widget>[
          _action(
            c.erreurVerificationAction,
            _verifier,
            const ValueKey<String>('vocal-verifier'),
          ),
        ],
      ),
      _Disponibilite.disponible => _selonEtat(context, discret),
    };
    // Un groupe nomme « Message vocal » ; chaque bouton reste un noeud a
    // part, lu avec son nom (« Pause », « Envoyer »).
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: c.libelle,
      child: contenu,
    );
  }

  Widget _selonEtat(BuildContext context, TextStyle discret) {
    final c = t.com.vocal.composer;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final String max = libelleDureeVocal(_machine.dureeMax);
    final EtatVocal etat = _machine.etat;
    final EnregistrementVocal? vocal = _vocal;

    switch (etat) {
      case EtatVocal.repos ||
          EtatVocal.envoye ||
          EtatVocal.vocalRecu ||
          EtatVocal.lecture ||
          EtatVocal.pauseLecture ||
          EtatVocal.finLecture:
        final String? erreur = _erreurMicro;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (etat == EtatVocal.envoye) _Statut(texte: c.envoye),
            if (erreur != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  erreur,
                  style: AppPalette.of(context).inkAlert.applyTo(discret),
                ),
              ),
            LienFleche(
              key: ComposerVocal.cleEnregistrer,
              libelle: c.enregistrer,
              icone: AppIcons.micro,
              fleche: false,
              onPress: _enregistrer,
            ),
          ],
        );

      case EtatVocal.permissionRequise:
        return _Panneau(
          titre: c.permissionTitre,
          phrase: c.permissionPhrase,
          actions: <Widget>[
            _action(
              c.annuler,
              () => setState(_machine.fermer),
              ComposerVocal.cleAnnuler,
              niveau: NiveauAction.tertiaire,
            ),
            _action(
              c.autoriser,
              _autoriser,
              ComposerVocal.cleAutoriser,
              enCours: _occupe,
            ),
          ],
        );

      case EtatVocal.permissionRefusee:
        return _Panneau(
          titre: c.refuse,
          phrase: c.refuseAide,
          actions: <Widget>[
            _action(
              c.fermer,
              () => setState(_machine.fermer),
              ComposerVocal.cleFermer,
            ),
          ],
        );

      case EtatVocal.enregistrement ||
          EtatVocal.reprise ||
          EtatVocal.limiteProche ||
          EtatVocal.pause:
        final DateTime maintenant = _horloge();
        final Duration ecoule = _machine.ecoule(maintenant);
        final bool enPause = etat == EtatVocal.pause;
        return _Panneau(
          titre: ComposerVocal.titreEtat(etat),
          duree: c.ecoule(ecoule: libelleDureeVocal(ecoule), max: max),
          progression: ecoule.inMilliseconds / _machine.dureeMax.inMilliseconds,
          annonce: etat == EtatVocal.limiteProche
              ? c.limiteProche(
                  restant: libelleDureeVocal(_machine.restant(maintenant)),
                  max: max,
                )
              : null,
          actions: <Widget>[
            if (enPause)
              _action(
                c.actionSupprimer,
                _demanderSuppression,
                ComposerVocal.cleSupprimer,
                niveau: NiveauAction.destructive,
              ),
            _action(c.actionArreter, _arreter, ComposerVocal.cleArreter),
            if (enPause)
              _action(c.actionReprendre, _reprendre, ComposerVocal.cleReprendre)
            else
              _action(c.actionPause, _mettreEnPause, ComposerVocal.clePause),
          ],
        );

      case EtatVocal.preEcoute || EtatVocal.limiteAtteinte:
        return _Panneau(
          titre: c.preEcoute,
          annonce: etat == EtatVocal.limiteAtteinte
              ? c.limiteAtteinte(max: max)
              : null,
          phrase: etat == EtatVocal.limiteAtteinte ? null : c.preEcouteAide,
          duree: c.duree(duree: libelleDureeVocal(_machine.duree)),
          lecteur: vocal == null
              ? null
              : LecteurVocal(
                  key: ValueKey<String>('vocal-pre-ecoute-${vocal.id}'),
                  ouvrir: () => _port.preEcoute(vocal),
                  duree: vocal.duree,
                ),
          remarque: horsLigne ? c.horsLigne : null,
          actions: <Widget>[
            _action(
              c.actionSupprimer,
              _demanderSuppression,
              ComposerVocal.cleSupprimer,
              niveau: NiveauAction.destructive,
            ),
            if (!horsLigne && vocal != null)
              _action(c.actionEnvoyer, _envoyer, ComposerVocal.cleEnvoyer),
          ],
        );

      case EtatVocal.supprimer:
        return _Panneau(
          titre: c.confirmerTitre,
          phrase: c.confirmerPhrase,
          actions: <Widget>[
            _action(c.garder, _garder, ComposerVocal.cleGarder),
            _action(
              c.actionSupprimer,
              _confirmerSuppression,
              ComposerVocal.cleConfirmerSuppression,
              niveau: NiveauAction.destructive,
            ),
          ],
        );

      case EtatVocal.envoi:
        return _Panneau(
          titre: c.envoi,
          duree: c.duree(duree: libelleDureeVocal(_machine.duree)),
          actions: <Widget>[
            _action(
              c.actionEnvoyer,
              _envoyer,
              ComposerVocal.cleEnvoyer,
              enCours: true,
            ),
          ],
        );

      case EtatVocal.echecEnvoi:
        return _Panneau(
          titre: c.nonConfirme,
          alerte: true,
          phrase: c.nonConfirmeAide,
          duree: c.duree(duree: libelleDureeVocal(_machine.duree)),
          remarque: horsLigne ? c.horsLigne : null,
          actions: <Widget>[
            _action(
              c.actionSupprimer,
              _demanderSuppression,
              ComposerVocal.cleSupprimer,
              niveau: NiveauAction.destructive,
            ),
            if (!horsLigne)
              _action(c.reessayer, _envoyer, ComposerVocal.cleReessayer),
          ],
        );
    }
  }

  Widget _action(
    String libelle,
    VoidCallback onPress,
    Key cle, {
    NiveauAction niveau = NiveauAction.secondaire,
    bool enCours = false,
  }) => ActionPrincipale(
    key: cle,
    libelle: libelle,
    onPress: onPress,
    niveau: niveau,
    enCours: enCours,
    pleineLargeur: false,
  );
}

/// L'etat ecrit, annonce une fois a chaque changement (region vivante).
class _Statut extends StatelessWidget {
  const _Statut({required this.texte, this.alerte = false});

  final String texte;
  final bool alerte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle base =
        Theme.of(context).textTheme.titleSmall ?? const TextStyle();
    return Semantics(
      liveRegion: true,
      child: Text(
        texte,
        key: ComposerVocal.cleStatut,
        style: alerte
            ? palette.inkAlert.applyTo(base)
            : palette.surfaceRaised.applyTo(base),
      ),
    );
  }
}

/// Le panneau d'un etat actif du composer : l'etat en mots, la duree, la
/// progression (decorative), une annonce, le lecteur de pre-ecoute, puis les
/// actions au bord de fin, a 16 du contenu qu'elles concernent.
class _Panneau extends StatelessWidget {
  const _Panneau({
    required this.titre,
    required this.actions,
    this.alerte = false,
    this.phrase,
    this.duree,
    this.progression,
    this.annonce,
    this.lecteur,
    this.remarque,
  });

  final String titre;
  final bool alerte;
  final String? phrase;
  final String? duree;
  final double? progression;
  final String? annonce;
  final Widget? lecteur;
  final String? remarque;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle corps = palette.surfaceRaised.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final String? phrase = this.phrase;
    final String? duree = this.duree;
    final double? progression = this.progression;
    final String? annonce = this.annonce;
    final Widget? lecteur = this.lecteur;
    final String? remarque = this.remarque;
    // Le panneau vit sous le champ d'un fil qui ne defile pas : borne a la
    // moitie de l'ecran, il defile lui-meme (texte x2, petit telephone) au
    // lieu de deborder ou de cacher le champ.
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * _partEcranMax,
      ),
      child: AppCard(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _Statut(texte: titre, alerte: alerte),
              if (phrase != null) ...<Widget>[
                Ecart.vXs,
                Text(phrase, style: corps),
              ],
              if (duree != null) ...<Widget>[
                Ecart.vSm,
                Text(duree, key: ComposerVocal.cleDuree, style: discret),
              ],
              if (progression != null) ...<Widget>[
                Ecart.vSm,
                // Decorative : la duree est ecrite juste au-dessus.
                ExcludeSemantics(
                  child: LinearProgressIndicator(
                    value: progression.clamp(0, 1).toDouble(),
                  ),
                ),
              ],
              if (annonce != null) ...<Widget>[
                Ecart.vSm,
                Semantics(liveRegion: true, child: Text(annonce, style: corps)),
              ],
              if (lecteur != null) ...<Widget>[Ecart.vLg, lecteur],
              if (remarque != null) ...<Widget>[
                Ecart.vSm,
                Text(remarque, style: discret),
              ],
              Ecart.vLg,
              RangeeActions(children: actions),
            ],
          ),
        ),
      ),
    );
  }
}
