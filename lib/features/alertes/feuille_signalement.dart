// D1-bis (03/11/2026) : traiter un signalement d'enseignant, depuis la page
// des alertes de la direction. Une feuille : ce que l'enseignant a ecrit, le
// message pour la famille, et les gestes que le serveur permet sur ce
// signalement (« Examiner », « Transmettre », « Clore »).
//
// * Les gestes affiches sont ceux que la file rend pour cette ligne
//   (`SignalementATraiter.peut...`) : jamais deduits d'un role. Un geste non
//   permis n'est pas montre ; aucun bouton grise.
// * La feuille relit le signalement dans la file a chaque emission : apres un
//   geste, elle montre le statut du serveur ; un signalement clos n'y est plus
//   et la feuille le dit.
// * « Transmettre » et « Clore » demandent une seconde confirmation, « Annuler »
//   par defaut : une transmission ne se reprend pas, un signalement clos ne
//   se rouvre pas (migration 20261106200000).
// * Aucun ecran de la famille ne lit encore le message transmis : la feuille
//   le dit, au lieu de promettre une lecture qui n'existe pas.
//
// Etats : contenu, chargement d'un geste (bouton en cours), erreur (bandeau),
// refus (la file est relue), hors ligne (phrase, sans geste). Le chargement
// et le vide de la file restent ceux de la page.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/signaler_manque.dart';
import '../../core/alertes/alerte.dart';
import '../../core/alertes/port_alertes.dart';
import '../../core/alertes/traitement_signalement.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/zone_saisie.dart';
import '../suivi_foyer/filtres_historique.dart';
import 'ligne_alerte.dart';

/// Le libelle d'une categorie de signalement.
String libelleCategorie(String code) {
  final c = t.tc.parcours.signalement.categorieValeur;
  return switch (code) {
    'securite_enfant' => c.securiteEnfant,
    'pedagogique' => c.pedagogique,
    'presence' => c.presence,
    'technique' => c.technique,
    'changement' => c.changement,
    _ => c.autre,
  };
}

/// Ou en est un signalement, en mots.
String libelleStatutSignalement(StatutSignalement statut) {
  final s = t.alertes.traitement.statutValeur;
  return switch (statut) {
    StatutSignalement.ouvert => s.aExaminer,
    StatutSignalement.enExamen => s.enExamen,
    StatutSignalement.transmis => s.transmis,
  };
}

/// La couleur du statut : registre doux, le mot dit toujours le statut.
TonEtat tonStatutSignalement(StatutSignalement statut) => switch (statut) {
  StatutSignalement.ouvert => TonEtat.avertissement,
  StatutSignalement.enExamen => TonEtat.accent,
  StatutSignalement.transmis => TonEtat.succes,
};

/// A qui part le message, au fil de la phrase.
String libelleCible(CibleTransmission cible) => switch (cible) {
  CibleTransmission.tuteurDuMineur => t.alertes.traitement.cibleTuteur,
  CibleTransmission.eleveAdulte => t.alertes.traitement.cibleAdulte,
};

/// Ouvre la feuille de traitement de [alerte].
Future<void> ouvrirTraitementSignalement(
  BuildContext context,
  Alerte alerte,
) async {
  final SignalementATraiter? s = alerte.signalement;
  if (s == null) return;
  final ProviderContainer portee = ProviderScope.containerOf(
    context,
    listen: false,
  );
  await AppBottomSheet.ouvrir<void>(
    context,
    titre: t.alertes.traitement.titre,
    constructeur: (BuildContext _) => UncontrolledProviderScope(
      container: portee,
      child: FeuilleSignalement(initial: s, gravite: alerte.gravite),
    ),
  );
}

enum _Geste { examiner, transmettre, clore }

enum _Issue { aucune, examen, transmis, clos, refuse, erreur, indisponible }

/// Le contenu de la feuille.
class FeuilleSignalement extends ConsumerStatefulWidget {
  /// Cree la feuille sur le signalement [initial], tel que la file l'a rendu.
  const FeuilleSignalement({
    required this.initial,
    required this.gravite,
    super.key,
  });

  /// Le signalement a l'ouverture.
  final SignalementATraiter initial;

  /// La gravite de son alerte.
  final GraviteAlerte gravite;

  /// La cle du bouton « Examiner ».
  static const Key cleExaminer = ValueKey<String>('signalement-examiner');

  /// La cle du bouton « Transmettre ».
  static const Key cleTransmettre = ValueKey<String>('signalement-transmettre');

  /// La cle du bouton « Clore ».
  static const Key cleClore = ValueKey<String>('signalement-clore');

  /// La cle du champ du message pour la famille.
  static const Key cleMessage = ValueKey<String>('signalement-message');

  /// La cle du champ du motif.
  static const Key cleMotif = ValueKey<String>('signalement-motif');

  /// La cle du bandeau d'issue.
  static const Key cleIssue = ValueKey<String>('signalement-issue');

  @override
  ConsumerState<FeuilleSignalement> createState() => _FeuilleSignalementState();
}

class _FeuilleSignalementState extends ConsumerState<FeuilleSignalement> {
  late final TextEditingController _message = TextEditingController(
    text: widget.initial.resume ?? '',
  );
  final TextEditingController _motif = TextEditingController();
  final FocusNode _focusMessage = FocusNode();
  final FocusNode _focusMotif = FocusNode();
  _Geste? _enCours;
  _Issue _issue = _Issue.aucune;
  CibleTransmission? _cibleTransmise;

  /// Vrai pendant qu'une confirmation est ouverte : un double appui n'en
  /// ouvre pas une seconde.
  bool _question = false;

  /// Le champ qui manquait au dernier appui, dit sous le champ.
  bool _messageManque = false;
  bool _motifManque = false;

  @override
  void dispose() {
    _message.dispose();
    _motif.dispose();
    _focusMessage.dispose();
    _focusMotif.dispose();
    super.dispose();
  }

  /// Le signalement tel que la file le rend maintenant ; `null` s'il n'y est
  /// plus (clos). Tant que la file n'est pas relue, le dernier connu.
  SignalementATraiter? _actuel() {
    final List<Alerte>? file = ref.watch(alertesProvider).value;
    if (file == null) return widget.initial;
    for (final Alerte a in file) {
      if (a.signalement?.id == widget.initial.id) return a.signalement;
    }
    return null;
  }

  Future<bool> _confirmer(
    String question,
    String consequence,
    String oui,
  ) async {
    _question = true;
    final bool r = await ConfirmDestructive.demander(
      context,
      question: question,
      consequence: consequence,
      libelleConfirmer: oui,
      annulerParDefaut: true,
    );
    _question = false;
    return r && mounted;
  }

  Future<void> _faire(_Geste geste, SignalementATraiter s) async {
    if (_enCours != null || _question) return;
    final tr = t.alertes.traitement;
    final String message = _message.text.trim();
    final String motif = _motif.text.trim();
    switch (geste) {
      case _Geste.examiner:
        break;
      case _Geste.transmettre:
        final CibleTransmission? cible = s.cible;
        if (cible == null) return;
        if (message.isEmpty) {
          setState(() => _messageManque = true);
          signalerManque(context, tr.messageManque, champ: _focusMessage);
          return;
        }
        if (!await _confirmer(
          switch (cible) {
            CibleTransmission.tuteurDuMineur => tr.transmettreQuestionTuteur,
            CibleTransmission.eleveAdulte => tr.transmettreQuestionAdulte,
          },
          tr.transmettreConsequence,
          tr.transmettreOui,
        )) {
          return;
        }
      case _Geste.clore:
        if (s.motifRequis && motif.isEmpty) {
          setState(() => _motifManque = true);
          signalerManque(context, tr.motifManque, champ: _focusMotif);
          return;
        }
        if (!await _confirmer(
          tr.cloreQuestion,
          tr.cloreConsequence,
          tr.cloreOui,
        )) {
          return;
        }
    }
    setState(() {
      _enCours = geste;
      _issue = _Issue.aucune;
    });
    final PortTraitementSignalement port = ref.read(
      portTraitementSignalementProvider,
    );
    _Issue issue;
    try {
      switch (geste) {
        case _Geste.examiner:
          await port.examiner(s.id);
          issue = _Issue.examen;
        case _Geste.transmettre:
          // Le message ecrit ici part d'abord, puis la transmission : un
          // seul geste pour la direction.
          if (message != (s.resume ?? '').trim()) {
            await port.rediger(s.id, message);
          }
          await port.transmettre(s.id, s.cible!);
          _cibleTransmise = s.cible;
          issue = _Issue.transmis;
        case _Geste.clore:
          await port.clore(s.id, motif: motif.isEmpty ? null : motif);
          issue = _Issue.clos;
      }
    } on TransitionRefusee {
      issue = _Issue.refuse;
    } on CapaciteIndisponible {
      issue = _Issue.indisponible;
    } on Object {
      issue = _Issue.erreur;
    }
    if (!mounted) return;
    // La file est relue dans tous les cas : un refus veut dire qu'elle a
    // change, un succes la change.
    if (issue != _Issue.erreur && issue != _Issue.indisponible) {
      ref.invalidate(alertesProvider);
    }
    setState(() {
      _enCours = null;
      _issue = issue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final SignalementATraiter? s = _actuel();
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    if (s == null) {
      // Clos ici, ou par un autre poste : il n'est plus dans les alertes.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          BandeauAttention(
            key: FeuilleSignalement.cleIssue,
            titre: t.alertes.traitement.faitClosTitre,
            message: t.alertes.traitement.faitClosPhrase,
            ton: TonEtat.succes,
          ),
          Ecart.vXl,
          _rangee(<Widget>[_fermer()]),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ..._detail(context, s),
        if (s.securiteEnfant) ...<Widget>[
          Ecart.vLg,
          BandeauAttention(
            titre: libelleCategorie(s.categorie),
            message: t.alertes.traitement.securitePhrase,
            ton: TonEtat.alerte,
          ),
        ],
        if (!horsLigne && s.transmissible) ...<Widget>[
          Ecart.vLg,
          ..._zoneMessage(s),
        ],
        if (!horsLigne && s.peutClore) ...<Widget>[
          Ecart.vLg,
          ZoneSaisie(
            controleur: _motif,
            cleChamp: FeuilleSignalement.cleMotif,
            noeud: _focusMotif,
            libelle: t.alertes.traitement.motif,
            aide: s.motifRequis
                ? t.alertes.traitement.motifRequisAide
                : t.alertes.traitement.motifFacultatifAide,
            erreur: _motifManque ? t.alertes.traitement.motifManque : null,
            onChanged: (String _) {
              if (_motifManque) setState(() => _motifManque = false);
            },
            maxLignes: 4,
          ),
        ],
        ..._issueVue(),
        Ecart.vXl,
        if (horsLigne) ...<Widget>[
          Text(t.alertes.traitement.horsLigne),
          Ecart.vMd,
        ],
        _rangee(<Widget>[
          _fermer(),
          if (!horsLigne && s.peutExaminer)
            ActionPrincipale(
              key: FeuilleSignalement.cleExaminer,
              libelle: t.alertes.traitement.examiner,
              niveau: NiveauAction.secondaire,
              enCours: _enCours == _Geste.examiner,
              onPress: () => _faire(_Geste.examiner, s),
            ),
          if (!horsLigne && s.peutClore)
            ActionPrincipale(
              key: FeuilleSignalement.cleClore,
              libelle: t.alertes.traitement.clore,
              niveau: NiveauAction.secondaire,
              enCours: _enCours == _Geste.clore,
              onPress: () => _faire(_Geste.clore, s),
            ),
          if (!horsLigne && s.transmissible)
            ActionPrincipale(
              key: FeuilleSignalement.cleTransmettre,
              libelle: t.alertes.traitement.transmettre,
              enCours: _enCours == _Geste.transmettre,
              onPress: () => _faire(_Geste.transmettre, s),
            ),
        ]),
      ],
    );
  }

  List<Widget> _detail(BuildContext context, SignalementATraiter s) {
    final tr = t.alertes.traitement;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return <Widget>[
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: <Widget>[
          StatusPill(
            libelle: libelleGravite(widget.gravite),
            ton: tonGravite(widget.gravite),
          ),
          StatusPill(
            libelle: libelleStatutSignalement(s.statut),
            ton: tonStatutSignalement(s.statut),
          ),
        ],
      ),
      Ecart.vMd,
      LigneCleValeur(cle: tr.categorie, valeur: libelleCategorie(s.categorie)),
      LigneCleValeur(cle: tr.eleve, valeur: s.matricule),
      LigneCleValeur(
        cle: tr.recu,
        valeur: t.alertes.creeeLe(
          date: dateCourte(s.recuLe.toLocal()),
          heure: heureMinute(s.recuLe.toLocal()),
        ),
      ),
      Ecart.vMd,
      Text(
        tr.note,
        style: palette.inkStrong.applyTo(
          textes.titleSmall ?? const TextStyle(),
        ),
      ),
      Ecart.vXs,
      Text(s.note, style: textes.bodyMedium),
      Ecart.vXs,
      Text(
        tr.noteAide,
        style: palette.inkMuted.applyTo(textes.bodySmall ?? const TextStyle()),
      ),
    ];
  }

  List<Widget> _zoneMessage(SignalementATraiter s) {
    final tr = t.alertes.traitement;
    final CibleTransmission cible = s.cible!;
    return <Widget>[
      ZoneSaisie(
        controleur: _message,
        cleChamp: FeuilleSignalement.cleMessage,
        noeud: _focusMessage,
        libelle: tr.message,
        aide: tr.messageAide(cible: libelleCible(cible)),
        erreur: _messageManque ? tr.messageManque : null,
        onChanged: (String _) {
          if (_messageManque) setState(() => _messageManque = false);
        },
        // Le message deja ecrit part tel quel quand le serveur ne permet plus
        // de le reecrire.
        lectureSeule: !s.peutRediger,
        minLignes: 2,
        maxLignes: 6,
      ),
      Ecart.vXs,
      Text(
        tr.pasEncoreAffiche,
        style: AppPalette.of(context).inkMuted.applyTo(
          Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
        ),
      ),
    ];
  }

  List<Widget> _issueVue() {
    final tr = t.alertes.traitement;
    final (String, String, TonEtat)? b = switch (_issue) {
      _Issue.examen => (
        tr.faitExamenTitre,
        tr.faitExamenPhrase,
        TonEtat.succes,
      ),
      _Issue.transmis => (
        tr.faitTransmisTitre,
        tr.faitTransmisPhrase(cible: libelleCible(_cibleTransmise!)),
        TonEtat.succes,
      ),
      _Issue.clos => (tr.faitClosTitre, tr.faitClosPhrase, TonEtat.succes),
      _Issue.refuse => (tr.refuseTitre, tr.refusePhrase, TonEtat.avertissement),
      _Issue.erreur => (tr.erreurTitre, tr.erreurPhrase, TonEtat.alerte),
      _Issue.indisponible => (
        tr.indisponibleTitre,
        tr.indisponiblePhrase,
        TonEtat.avertissement,
      ),
      _Issue.aucune => null,
    };
    if (b == null) return const <Widget>[];
    return <Widget>[
      Ecart.vLg,
      BandeauAttention(
        key: FeuilleSignalement.cleIssue,
        titre: b.$1,
        message: b.$2,
        ton: b.$3,
      ),
    ];
  }

  Widget _fermer() => ActionPrincipale(
    libelle: t.commun.fermer,
    niveau: NiveauAction.tertiaire,
    onPress: () => Navigator.of(context).pop(),
  );

  Widget _rangee(List<Widget> boutons) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    alignment: WrapAlignment.end,
    children: boutons,
  );
}
