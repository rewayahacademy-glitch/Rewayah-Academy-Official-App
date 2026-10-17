// LIVE-PAUSE-01 : le reglage de la pause programmee, dans la fiche de la
// classe de l'enseignant (decision F3, 27/09/2026).
//
// Activer ou non, le moment (minutes apres le debut de la seance) et la duree.
// Le reglage vaut de seance en seance jusqu'a ce que l'enseignant le change.
//
// Les cinq etats : chargement (squelette), contenu (le reglage), vide (aucune
// pause programmee : l'interrupteur dit « Aucune pause »), erreur (relire) et
// hors ligne (le bandeau du reseau le dit une seule fois ; un envoi sans
// reponse n'affirme rien). En production, la capacite est indisponible : le bloc le dit en
// clair et ne pose aucune fausse bascule.
//
// **Un widget lit une capacite, jamais un role** : les commandes n'existent
// que si le serveur a rendu `peutModifier`. Aucun bouton grise : « Enregistrer
// la pause » n'est rendu que lorsque le brouillon differe du reglage lu.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/pause_seance/port_pause_seance.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';

/// Les moments proposes, en minutes apres le debut (le reglage servi s'y
/// ajoute quand il n'y figure pas).
const List<int> momentsPause = <int>[15, 30, 45, 60, 90];

/// Les durees proposees, en minutes.
const List<int> dureesPause = <int>[5, 10, 15, 20, 30];

/// Le bloc « Pause de la seance » de la fiche de la classe.
class BlocPauseClasse extends ConsumerStatefulWidget {
  /// Cree le bloc pour la classe [groupeId].
  const BlocPauseClasse({required this.groupeId, super.key});

  /// La classe.
  final String groupeId;

  /// La cle de l'interrupteur.
  static const Key cleInterrupteur = ValueKey<String>('pause-classe-actif');

  /// La cle du choix du moment.
  static const Key cleMoment = ValueKey<String>('pause-classe-moment');

  /// La cle du choix de la duree.
  static const Key cleDuree = ValueKey<String>('pause-classe-duree');

  /// La cle de « Enregistrer la pause ».
  static const Key cleEnregistrer = ValueKey<String>(
    'pause-classe-enregistrer',
  );

  /// La cle de l'etat « indisponible ».
  static const Key cleIndisponible = ValueKey<String>(
    'pause-classe-indisponible',
  );

  @override
  ConsumerState<BlocPauseClasse> createState() => _BlocPauseClasseEtat();
}

class _BlocPauseClasseEtat extends ConsumerState<BlocPauseClasse> {
  /// Le brouillon, ou `null` tant que l'enseignant n'a rien change : le bloc
  /// montre alors le reglage lu.
  ReglagePause? _brouillon;
  bool _envoi = false;
  String? _retour;
  bool _retourDefinitif = false;
  int _essai = 0;

  void _relire() => ref.invalidate(reglagePauseProvider(widget.groupeId));

  void _dire(String message, {required bool definitif}) {
    setState(() {
      _retour = message;
      _retourDefinitif = definitif;
      _essai++;
    });
  }

  Future<void> _enregistrer(ReglagePause lu, ReglagePause voulu) async {
    if (_envoi) {
      return;
    }
    final d = t.enseignant.ficheGroupe.pause;
    setState(() {
      _envoi = true;
      _retour = null;
    });
    String? message;
    bool definitif = false;
    try {
      await ref
          .read(portPauseSeanceProvider)
          .enregistrerReglage(
            groupeId: widget.groupeId,
            actif: voulu.actif,
            apresMinutes: voulu.apresMinutes,
            dureeMinutes: voulu.dureeMinutes,
            versionAttendue: lu.version,
            cleIdempotence: const Uuid().v4(),
          );
      message = d.enregistree;
    } on ReglagePauseObsolete {
      message = d.obsolete;
      definitif = true;
    } on Object {
      message = d.echec;
      definitif = true;
    }
    if (!mounted) {
      return;
    }
    // Dans tous les cas on relit : la valeur affichee est celle du serveur.
    ref.invalidate(reglagePauseProvider(widget.groupeId));
    setState(() {
      _envoi = false;
      _brouillon = null;
    });
    _dire(message, definitif: definitif);
  }

  @override
  Widget build(BuildContext context) {
    final d = t.enseignant.ficheGroupe.pause;
    final AsyncValue<ReglagePause> lecture = ref.watch(
      reglagePauseProvider(widget.groupeId),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: d.titre),
        Ecart.vMd,
        BlocAsynchrone<ReglagePause>(
          valeur: lecture,
          squelette: const Skeleton.liste(lignes: 2),
          onReessayer: _relire,
          titreEchec: d.illisible,
          erreurVersEtat: (Object erreur, VoidCallback? _) =>
              erreur is CapaciteIndisponible
              ? EtatSysteme(
                  key: BlocPauseClasse.cleIndisponible,
                  nature: NatureEtat.indisponible,
                  titre: d.indisponibleTitre,
                  phrase: d.indisponiblePhrase,
                  dependance: erreur.dependance,
                )
              : null,
          construire: (ReglagePause lu) => _Reglage(
            lu: lu,
            brouillon: _brouillon ?? lu,
            envoi: _envoi,
            onChange: (ReglagePause b) => setState(() {
              _brouillon = b == lu ? null : b;
              _retour = null;
            }),
            onEnregistrer: (ReglagePause b) => _enregistrer(lu, b),
          ),
        ),
        LocalFeedback(
          key: ValueKey<int>(_essai),
          message: _retour,
          persistant: _retourDefinitif,
        ),
      ],
    );
  }
}

class _Reglage extends StatelessWidget {
  const _Reglage({
    required this.lu,
    required this.brouillon,
    required this.envoi,
    required this.onChange,
    required this.onEnregistrer,
  });

  final ReglagePause lu;
  final ReglagePause brouillon;
  final bool envoi;
  final ValueChanged<ReglagePause> onChange;
  final ValueChanged<ReglagePause> onEnregistrer;

  List<Segment<int>> _segments(List<int> base, int courant) {
    final List<int> valeurs = <int>{...base, courant}.toList()..sort();
    return <Segment<int>>[
      for (final int v in valeurs)
        Segment<int>(
          valeur: v,
          libelle: isolerSens(
            LibellesGroupe.insecable(t.commun.formats.minutes(minutes: v)),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final d = t.enseignant.ficheGroupe.pause;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    Widget phrase(String texte) => Text(
      isolerSens(texte),
      style: palette.inkMuted.applyTo(textes.bodyMedium ?? const TextStyle()),
    );

    // Sans la capacite de modifier : le reglage se lit, sans commande.
    if (!lu.peutModifier) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          phrase(d.detail),
          Ecart.vSm,
          phrase(
            lu.actif
                ? LibellesGroupe.insecable(
                    d.resume(duree: lu.dureeMinutes, moment: lu.apresMinutes),
                  )
                : d.etatInactif,
          ),
          Ecart.vSm,
          phrase(d.refuse),
        ],
      );
    }

    final bool modifie = brouillon != lu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        phrase(d.detail),
        Ecart.vMd,
        GroupeReglages(
          lignes: <LigneRubrique>[
            LigneRubrique(
              libelle: d.actif,
              pastille: StatusPill(
                libelle: brouillon.actif ? d.etatActif : d.etatInactif,
                ton: brouillon.actif ? TonEtat.succes : TonEtat.neutre,
              ),
              controle: Switch.adaptive(
                key: BlocPauseClasse.cleInterrupteur,
                value: brouillon.actif,
                // Pendant l'envoi, un seul geste a la fois (jamais un faux
                // etat) ; la bascule reste lisible.
                onChanged: envoi
                    ? null
                    : (bool actif) =>
                          onChange(brouillon.copyWith(actif: actif)),
              ),
            ),
          ],
        ),
        if (brouillon.actif) ...<Widget>[
          Ecart.vLg,
          Semantics(
            header: true,
            child: Text(d.moment, style: textes.titleSmall),
          ),
          Ecart.vXs,
          phrase(d.momentAide),
          Ecart.vSm,
          ControleSegmente<int>(
            key: BlocPauseClasse.cleMoment,
            segments: _segments(momentsPause, brouillon.apresMinutes),
            valeur: brouillon.apresMinutes,
            onChange: (int v) => onChange(brouillon.copyWith(apresMinutes: v)),
          ),
          Ecart.vLg,
          Semantics(
            header: true,
            child: Text(d.duree, style: textes.titleSmall),
          ),
          Ecart.vSm,
          ControleSegmente<int>(
            key: BlocPauseClasse.cleDuree,
            segments: _segments(dureesPause, brouillon.dureeMinutes),
            valeur: brouillon.dureeMinutes,
            onChange: (int v) => onChange(brouillon.copyWith(dureeMinutes: v)),
          ),
        ],
        // Jamais un bouton grise : « Enregistrer » n'existe que lorsqu'il y a
        // quelque chose a enregistrer.
        if (modifie) ...<Widget>[
          Ecart.vLg,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionPrincipale(
              key: BlocPauseClasse.cleEnregistrer,
              libelle: d.enregistrer,
              pleineLargeur: false,
              enCours: envoi,
              onPress: () => onEnregistrer(brouillon),
            ),
          ),
        ],
      ],
    );
  }
}
