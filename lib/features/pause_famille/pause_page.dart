// CALENDRIER-ET-PAUSES (lot 2, 12/11/2026) : « Demander une pause d'un mois ».
//
// Le tuteur la demande pour son enfant, l'eleve adulte pour lui-meme. La regle
// se lit AVANT la demande : un mois civil entier, au moins N jours avant son
// debut, au plus M mois sur P mois (au-dela la direction repond sous D jours),
// la place est gardee, la date limite de l'etape recule. Toutes ces valeurs
// viennent du serveur (`app_config`), jamais d'ici. Les mois proposes disent
// ceux qui vont a la direction. Le serveur decide et refuse ; l'ecran dit.
// Pedagogie seulement : rien d'argent.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calendrier/libelles_calendrier.dart';
import '../../core/calendrier/port_calendrier.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/session/session_controleur.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';

/// La page de demande de pause.
class PausePage extends ConsumerStatefulWidget {
  /// Cree la page. [eleveId] nul : l'eleve adulte connecte.
  const PausePage({this.eleveId, super.key});

  /// L'enfant du tuteur ; nul pour l'eleve adulte.
  final String? eleveId;

  @override
  ConsumerState<PausePage> createState() => _PausePageEtat();
}

class _PausePageEtat extends ConsumerState<PausePage> {
  DateTime? _mois;
  bool _envoi = false;
  String? _erreur;
  String? _confirmation;

  String? get _eleve {
    if (widget.eleveId != null) return widget.eleveId;
    try {
      return ref.read(sessionProvider).profileId;
    } on Object {
      return null;
    }
  }

  Future<void> _demander(LecturePauses lecture) async {
    final PortPauses? port = ref.read(portPausesProvider);
    final DateTime? mois = _mois;
    final String? eleve = _eleve;
    if (port == null || mois == null || eleve == null) return;
    setState(() {
      _envoi = true;
      _erreur = null;
      _confirmation = null;
    });
    try {
      final ReponseDemandePause r = await port.demander(eleve, mois);
      ref.invalidate(lecturePausesProvider(eleve));
      if (!mounted) return;
      setState(() {
        _mois = null;
        _confirmation = r.statut == StatutPause.acceptee
            ? t.pause.reponse.acceptee(mois: moisEnMots(r.debut))
            : LibellesGroupe.insecable(
                t.pause.reponse.demandee(
                  delai: lecture.regle.delaiReponseJours,
                ),
              );
      });
    } on PauseRefusee catch (r) {
      if (mounted) {
        setState(
          () => _erreur = messageRefusDemandePause(
            r.motif,
            preavisJours: lecture.regle.preavisJours,
          ),
        );
      }
    } on Object {
      if (mounted) {
        setState(
          () => _erreur = messageRefusDemandePause(MotifRefusPause.inconnu),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _annuler(PauseEleve pause, LecturePauses lecture) async {
    final PortPauses? port = ref.read(portPausesProvider);
    final String? eleve = _eleve;
    if (port == null || eleve == null) return;
    setState(() {
      _erreur = null;
      _confirmation = null;
    });
    try {
      await port.annuler(pause.id);
      ref.invalidate(lecturePausesProvider(eleve));
    } on PauseRefusee catch (r) {
      if (mounted) {
        setState(
          () => _erreur = messageRefusDemandePause(
            r.motif,
            preavisJours: lecture.regle.preavisJours,
          ),
        );
      }
    } on Object {
      if (mounted) {
        setState(
          () => _erreur = messageRefusDemandePause(MotifRefusPause.inconnu),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? eleve = _eleve;
    final bool sansPort = ref.watch(portPausesProvider) == null;
    final AsyncValue<LecturePauses?> lecture = eleve == null || sansPort
        ? const AsyncData<LecturePauses?>(null)
        : ref.watch(lecturePausesProvider(eleve));
    final String? prenom = lecture.value?.prenom;
    return PageShell(
      titre: t.pause.titre,
      sousTitre: prenom == null || prenom.isEmpty
          ? null
          : t.pause.sousTitre(
              dePrenom: deDevant(prenom, cle: 'pause.sousTitre'),
            ),
      child: sansPort || eleve == null
          ? EmptyState(
              message: t.pause.indisponible,
              icone: AppIcons.rienAAfficher,
              registre: RegistreVide.subi,
            )
          : BlocAsynchrone<LecturePauses?>(
              valeur: lecture,
              squelette: const Skeleton.liste(lignes: 4),
              titreEchec: t.pause.erreur,
              onReessayer: () => ref.invalidate(lecturePausesProvider(eleve)),
              estVide: (LecturePauses? l) => l == null,
              vide: EmptyState(
                message: t.pause.indisponible,
                icone: AppIcons.rienAAfficher,
                registre: RegistreVide.subi,
              ),
              construire: (LecturePauses? l) => _corps(context, l!),
            ),
    );
  }

  /// Les pauses de l'eleve, de la plus recente a la plus ancienne, avec le lien
  /// pour annuler celles qui n'ont pas commence.
  List<Widget> _listeDesPauses(LecturePauses l, TextTheme textes) {
    return <Widget>[
      SectionHeader(titre: t.pause.demandesTitre),
      Ecart.vMd,
      if (l.pauses.isEmpty)
        Text(t.pause.demandesVide, style: textes.bodyMedium)
      else
        CarteLignes(
          lignes: <Widget>[
            for (final PauseEleve p in l.pauses)
              SettingRow(
                key: ValueKey<String>('pause-${p.id}'),
                title: moisEnMots(p.debut),
                description: <String>[
                  t.pause.periode(
                    du: jourEnMots(p.debut),
                    au: jourEnMots(p.fin),
                  ),
                  if (p.type == TypePause.exception) t.pause.exceptionAccordee,
                  if (p.statut == StatutPause.demandee &&
                      p.repondreAvant != null)
                    t.pause.reponseAvant(date: jourEnMots(p.repondreAvant!)),
                  if ((p.motifDecision ?? '').isNotEmpty)
                    t.pause.reponseMotif(motif: p.motifDecision!),
                ].join('\n'),
                controle: StatusPill(
                  libelle: libelleStatutPause(p.statut, famille: true),
                  ton: switch (p.statut) {
                    StatutPause.acceptee => TonEtat.succes,
                    StatutPause.refusee => TonEtat.alerte,
                    StatutPause.annulee => TonEtat.neutre,
                    StatutPause.demandee => TonEtat.avertissement,
                  },
                ),
              ),
          ],
        ),
      for (final PauseEleve p in l.pauses.where((PauseEleve p) => p.annulable))
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: LienFleche(
            key: ValueKey<String>('pause-annuler-${p.id}'),
            libelle: t.pause.annuler(mois: moisEnMots(p.debut)),
            alignerEnDebut: true,
            onPress: () => _annuler(p, l),
          ),
        ),
    ];
  }

  /// La demande est fermee par le reglage du serveur : une phrase, la
  /// direction comme recours ; les pauses deja accordees restent lisibles.
  Widget _corpsFerme(BuildContext context, LecturePauses l, TextTheme textes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        EmptyState(
          key: const ValueKey<String>('pause-fermee'),
          message: t.pause.fermeeTitre,
          invitation: t.pause.fermeeDetail,
          icone: AppIcons.rienAAfficher,
          registre: RegistreVide.subi,
        ),
        if (l.pauses.isNotEmpty) ...<Widget>[
          Ecart.vXl,
          ..._listeDesPauses(l, textes),
        ],
      ],
    );
  }

  Widget _corps(BuildContext context, LecturePauses l) {
    final TextTheme textes = Theme.of(context).textTheme;
    if (!l.demandeOuverte) return _corpsFerme(context, l, textes);
    final r = t.pause.regle;
    final ReglePause regle = l.regle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // La regle, AVANT la demande.
        SectionHeader(titre: t.pause.regleTitre),
        Ecart.vMd,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(r.moisEntier, style: textes.bodyMedium),
              Ecart.vSm,
              Text(
                LibellesGroupe.insecable(r.preavis(jours: regle.preavisJours)),
                style: textes.bodyMedium,
              ),
              Ecart.vSm,
              Text(
                LibellesGroupe.insecable(
                  r.plafond(
                    mois: regle.plafondMois,
                    fenetre: regle.fenetreMois,
                    delai: regle.delaiReponseJours,
                  ),
                ),
                style: textes.bodyMedium,
              ),
              Ecart.vSm,
              Text(r.placeGardee, style: textes.bodyMedium),
              Ecart.vSm,
              Text(r.dateLimite, style: textes.bodyMedium),
              Ecart.vSm,
              Text(r.absence, style: textes.bodyMedium),
            ],
          ),
        ),
        Ecart.vXl,
        SectionHeader(titre: t.pause.choisir),
        Ecart.vMd,
        if (l.moisProposes.isEmpty)
          Text(t.pause.aucunMois, style: textes.bodyMedium)
        else
          ChoiceCardGroup(
            autoriserSaisieLibre: false,
            valeurInitiale: _mois == null
                ? null
                : ReponseChoix(valeurs: <String>{jourVersSql(_mois!)}),
            options: <OptionChoix>[
              for (final MoisPropose m in l.moisProposes)
                OptionChoix(
                  valeur: jourVersSql(m.mois),
                  libelle: moisEnMots(m.mois),
                  description: switch (m.etat) {
                    StatutPause.acceptee => t.pause.moisDejaAccepte,
                    StatutPause.demandee => t.pause.moisDejaDemande,
                    _ =>
                      m.aLaDirection
                          ? LibellesGroupe.insecable(
                              t.pause.moisALaDirection(
                                delai: regle.delaiReponseJours,
                              ),
                            )
                          : t.pause.moisDansRegle,
                  },
                  disponible: m.etat == null,
                ),
            ],
            onChange: (ReponseChoix choix) => setState(() {
              _mois = choix.valeurs.isEmpty
                  ? null
                  : jourDepuisSql(choix.valeurs.first);
              _erreur = null;
              _confirmation = null;
            }),
          ),
        if (_confirmation != null) ...<Widget>[
          Ecart.vLg,
          Text(
            _confirmation!,
            key: const ValueKey<String>('pause-confirmation'),
            style: textes.bodyMedium,
          ),
        ],
        if (_erreur != null) ...<Widget>[
          Ecart.vLg,
          Text(
            _erreur!,
            key: const ValueKey<String>('pause-erreur'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        Ecart.vLg,
        if (_mois == null)
          Text(t.pause.choisirPourDemander, style: textes.bodyMedium)
        else
          ActionPrincipale(
            key: const ValueKey<String>('pause-demander'),
            libelle: t.pause.demander,
            enCours: _envoi,
            onPress: () => _demander(l),
          ),
        Ecart.vXl,
        ..._listeDesPauses(l, textes),
      ],
    );
  }
}
