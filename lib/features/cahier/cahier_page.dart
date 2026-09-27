import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/coran/service_coran.dart' show PositionLecture;
import '../../core/enseignant/depot_cahiers.dart';
import '../../core/enseignant/modeles_enseignant.dart';
import '../../core/enseignant/service_enseignant.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/presence/vue_presence.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/ligne_presence.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/point_rappel.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../fiche_groupe/preparation_seance.dart'
    show ProjectionEleve, projectionElevesProvider;
import '../foyer/photo_eleve.dart';
import '../presence_correction/presence_correction.dart';
import '../presence_correction/presence_correction_page.dart';
import 'makharij.dart';
import 'vue_cahier.dart';

/// `ENS-04` : le cahier de seance (doc 04 §20, planche 4, K-45).
///
/// **L'ecran de sortie de seance, et le seul.** On y arrive en quittant la
/// salle, jamais depuis la barre de navigation (planche 4, R5).
///
/// **Moins de 45 secondes.** L'ecran est prerempli par `brouillon_cahier()` :
/// presence deduite, duree calculee par la base, position de lecture. Tout vaut
/// « Continuer » par defaut, et l'enseignant ne touche qu'aux exceptions.
/// L'enseignant juge, la machine ne juge jamais (K-45, point 4).
///
/// **Ordre de la planche 4** : resume et pastilles de statut, eleves (et leur
/// devoir), position de reprise, phrase d'integrite, « Valider le cahier ».
/// Sur bureau, deux colonnes : le resume et les eleves sans exception, puis
/// les exceptions et la reprise.
///
/// **Le cahier reste corrigeable apres validation** (K-45, point 5) :
/// l'enseignant ne voit que « Corrige le ... », l'historique est reserve a
/// l'academie.
class CahierPage extends ConsumerWidget {
  /// Cree le cahier d'une seance.
  const CahierPage({required this.seanceId, super.key});

  /// La seance dont on rend le cahier.
  final String seanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<BrouillonCahier?> lecture = ref.watch(
      brouillonCahierProvider(seanceId),
    );

    // Doc 04 §20.8 : un cahier valide hors ligne se lit « En attente
    // d'envoi » ; il ne rouvre pas le formulaire (question §33 n. 14).
    final bool enFile =
        ref.watch(cahiersEnFileProvider).value?.contains(seanceId) ?? false;

    // K-42 §5 : l'en-tete dit quelle Classe et quelle seance, avec les
    // libelles de « A terminer » (cahierLigne, cahierDetail). La Classe se
    // lit dans la seance ou dans la ligne « A terminer » ; sinon, le titre
    // generique reste.
    SeanceEnseignant? seance;
    for (final SeanceEnseignant s
        in ref.watch(seancesEnseignantProvider).value ??
            const <SeanceEnseignant>[]) {
      if (s.id == seanceId) seance = s;
    }
    CahierEnRetard? enRetard;
    for (final CahierEnRetard c
        in ref.watch(cahiersEnRetardProvider).value ??
            const <CahierEnRetard>[]) {
      if (c.seanceId == seanceId) enRetard = c;
    }
    final String? classe = seance?.groupeLibelle ?? enRetard?.groupeLibelle;

    return _Cahier(
      seanceId: seanceId,
      vue: VueCahier.depuis(lecture: lecture),
      enFile: enFile,
      classe: classe == null || classe.isEmpty ? null : classe,
      debut: seance?.debut ?? enRetard?.debut,
    );
  }
}

/// Le corps du cahier, qui porte les decisions en cours de saisie.
///
/// Une entree absente de la carte **est** la decision par defaut,
/// « Continuer » : le chemin nominal ne construit aucun objet.
class _Cahier extends ConsumerStatefulWidget {
  const _Cahier({
    required this.seanceId,
    required this.vue,
    this.enFile = false,
    this.classe,
    this.debut,
  });

  final String seanceId;
  final VueCahier vue;

  /// Le nom de la Classe de la seance, s'il est connu.
  final String? classe;

  /// Le debut de la seance, tant que le brouillon ne l'a pas apporte.
  final DateTime? debut;

  /// Vrai quand ce cahier, deja valide, attend le serveur dans la file locale.
  final bool enFile;

  @override
  ConsumerState<_Cahier> createState() => _CahierState();
}

class _CahierState extends ConsumerState<_Cahier> {
  final Map<String, DecisionEleve> _decisions = <String, DecisionEleve>{};
  final TextEditingController _reprise = TextEditingController();
  final FocusNode _focusReprise = FocusNode();

  bool _envoiEnCours = false;
  bool _echecEnvoi = false;
  bool _repriseManquante = false;
  bool _repriseProposee = false;
  bool _enCorrection = false;
  DateTime? _corrigeLe;
  SortCahier? _sort;

  @override
  void initState() {
    super.initState();
    _focusReprise.addListener(_sortieReprise);
  }

  @override
  void dispose() {
    _focusReprise
      ..removeListener(_sortieReprise)
      ..dispose();
    _reprise.dispose();
    super.dispose();
  }

  /// A la sortie du champ, un message calme si la reprise manque (K-45,
  /// point 2). Jamais pendant la frappe.
  void _sortieReprise() {
    if (_focusReprise.hasFocus) return;
    final bool manquante = _reprise.text.trim().isEmpty;
    if (manquante != _repriseManquante) {
      setState(() => _repriseManquante = manquante);
    }
  }

  /// Preremplit la reprise une seule fois, quand le brouillon arrive : c'est
  /// une proposition que l'enseignant verifie (doc 04 §20.1).
  void _proposerReprise(VueCahier vue) {
    if (_repriseProposee) return;
    final BrouillonCahier? brouillon = vue.brouillon;
    if (brouillon == null) return;
    _repriseProposee = true;
    final PositionLecture? position = repriseProposee(brouillon.participants);
    if (position != null && _reprise.text.isEmpty) {
      _reprise.text = t.enseignant.cahier.repriseProposee(
        sourate: '${position.sourate}',
        verset: '${position.verset}',
      );
    }
  }

  /// Les projections des eleves de la Classe de la seance, pour leur photo
  /// (E5, K-44) ; vides si la seance ne porte pas de Classe.
  Map<String, ProjectionEleve> _projections(VueCahier vue) {
    final String? groupeId = vue.brouillon?.groupeId;
    return groupeId == null
        ? const <String, ProjectionEleve>{}
        : ref.watch(projectionElevesProvider(groupeId));
  }

  @override
  Widget build(BuildContext context) {
    final VueCahier vue = widget.vue;
    final SortCahier? sort =
        _sort ?? (widget.enFile && !_enCorrection ? SortCahier.enFile : null);
    _proposerReprise(vue);
    final String? classe = widget.classe;
    final String titre = classe == null
        ? t.enseignant.cahier.titre
        : t.enseignant.journee.cahierLigne(classe: deDevant(classe));
    final DateTime? debut = vue.brouillon?.debut ?? widget.debut;
    final String? sousTitre = debut == null ? null : _seanceDu(debut);

    if (sort != null) {
      return PageShell(
        titre: titre,
        sousTitre: sousTitre,
        onRetour: _retourJournee,
        child: _ApresDepot(
          sort: sort,
          corrigeLe: _corrigeLe,
          onCorriger: sort == SortCahier.envoye ? _corriger : null,
          onRetour: _retourJournee,
        ),
      );
    }

    final bool lectureSeule =
        vue.etat == EtatCahier.dejaDepose && !_enCorrection;

    return PageShell(
      titre: titre,
      sousTitre: sousTitre,
      onRetour: _retourJournee,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_echecEnvoi) ...<Widget>[
            LocalFeedback(message: t.enseignant.cahier.echecEnvoi),
            Ecart.vLg,
          ],
          switch (vue.etat) {
            EtatCahier.chargement => const Skeleton.liste(lignes: 4),
            EtatCahier.erreur => _SansConstat(
              etat: EmptyState(
                message: t.enseignant.cahier.erreur,
                invitation: t.enseignant.cahier.erreurDetail,
                icone: AppIcons.avertissement,
                libelleAction: t.commun.reessayer,
                onAction: _relire,
              ),
              validation: _validation(vue, large: false),
            ),
            EtatCahier.vide => _SansConstat(
              etat: EmptyState(
                message: t.enseignant.cahier.vide,
                invitation: t.enseignant.cahier.videDetail,
                icone: AppIcons.cahier,
                registre: RegistreVide.subi,
              ),
              validation: _validation(vue, large: false),
            ),
            EtatCahier.dejaDepose || EtatCahier.constat => _Constat(
              vue: vue,
              decisions: _decisions,
              projections: _projections(vue),
              lectureSeule: lectureSeule,
              aValider: !lectureSeule && !_enCorrection,
              onAjuster: _ajuster,
              onCorriger: _corriger,
              onRetour: _retourJournee,
              validation: (bool large) => _validation(vue, large: large),
            ),
          },
        ],
      ),
    );
  }

  /// La fin du cahier : la reprise obligatoire, la phrase d'integrite, puis
  /// le seul bouton dominant, 16 sous ce qu'il confirme (contrat B).
  Widget _validation(VueCahier vue, {required bool large}) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String libelle =
        vue.etat == EtatCahier.constat || vue.etat == EtatCahier.dejaDepose
        ? t.enseignant.cahier.valider
        : t.enseignant.cahier.validerSansConstat;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Le champ porte deja ce libelle : le titre n'est pas relu (W-243).
        ExcludeSemantics(
          child: Text(t.enseignant.cahier.reprise, style: textes.titleSmall),
        ),
        Ecart.vSm,
        TextField(
          key: const ValueKey<String>('cahier-reprise'),
          controller: _reprise,
          focusNode: _focusReprise,
          textInputAction: TextInputAction.done,
          onChanged: (String valeur) {
            if (_repriseManquante && valeur.trim().isNotEmpty) {
              setState(() => _repriseManquante = false);
            }
          },
          decoration: InputDecoration(
            labelText: t.enseignant.cahier.reprise,
            helperText: t.enseignant.cahier.repriseDetail,
            helperMaxLines: 2,
            errorText: _repriseManquante
                ? t.enseignant.cahier.repriseRequise
                : null,
            errorMaxLines: 3,
          ),
        ),
        Ecart.vXxl,
        Text(
          t.enseignant.cahier.integrite,
          key: const ValueKey<String>('cahier-integrite'),
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vLg,
        Align(
          alignment: AlignmentDirectional.centerEnd,
          // `ActionPrincipale` s'etire a la largeur offerte ; IntrinsicWidth
          // lui rend sa largeur naturelle sur bureau (contrat B).
          child: _Borne(
            borne: large,
            child: ActionPrincipale(
              key: const ValueKey<String>('cahier-valider'),
              libelle: libelle,
              pleineLargeur: !large,
              enCours: _envoiEnCours,
              onPress: _envoiEnCours ? null : () => unawaited(_deposer(vue)),
            ),
          ),
        ),
      ],
    );
  }

  void _retourJournee() => GoRouter.of(context).go(Routes.enseignantJournee);

  void _relire() => ref.invalidate(brouillonCahierProvider(widget.seanceId));

  /// Rouvre le cahier deja valide pour le corriger (K-45, point 5).
  void _corriger() => setState(() {
    _enCorrection = true;
    _sort = null;
    _echecEnvoi = false;
  });

  /// Ouvre le reglage d'un eleve : la presence, le point phonetique,
  /// l'objectif, le devoir, la suspension du nouveau.
  Future<void> _ajuster(ParticipantBrouillon participant) async {
    final BrouillonCahier? brouillon = widget.vue.brouillon;
    if (brouillon == null) {
      return;
    }
    final String eleveId = participant.membre.studentId;

    final DecisionEleve? decision = await AppBottomSheet.ouvrir<DecisionEleve>(
      context,
      titre: t.enseignant.cahier.ajusterPour(eleve: participant.membre.libelle),
      constructeur: (BuildContext _) => _FeuilleAjuster(
        participant: participant,
        brouillon: brouillon,
        decision: _decisions[eleveId] ?? DecisionEleve(studentId: eleveId),
      ),
    );
    if (decision == null || !mounted) {
      return;
    }
    setState(() => _decisions[eleveId] = decision);
  }

  /// Depose le cahier : une seule ecriture, une seule cle.
  ///
  /// Sans position de reprise, rien ne part : le message calme s'affiche et
  /// le champ reprend le focus (K-45, point 2). Le bouton n'est jamais grise.
  Future<void> _deposer(VueCahier vue) async {
    if (!vue.peutDeposer && !_enCorrection) {
      return;
    }
    if (_reprise.text.trim().isEmpty) {
      setState(() => _repriseManquante = true);
      _focusReprise.requestFocus();
      return;
    }
    setState(() {
      _envoiEnCours = true;
      _echecEnvoi = false;
    });

    final CahierARendre cahier = CahierARendre(
      seanceId: widget.seanceId,
      decisions: <DecisionEleve>[
        for (final ParticipantBrouillon p in vue.participants)
          _decisions[p.membre.studentId] ??
              DecisionEleve(studentId: p.membre.studentId),
      ],
      positionReprise: _reprise.text.trim(),
    );

    try {
      final SortCahier sort = await ref
          .read(soumissionCahierProvider)
          .soumettre(cahier);
      if (!mounted) {
        return;
      }
      ref
        ..invalidate(cahiersEnRetardProvider)
        ..invalidate(cahiersEnFileProvider);
      final bool correction = _enCorrection;
      setState(() {
        _envoiEnCours = false;
        _sort = sort;
        _enCorrection = false;
        // « Corrige le ... » seulement quand le serveur a confirme (E7).
        if (correction && sort == SortCahier.envoye) {
          _corrigeLe = ref.read(horlogeCahierProvider)();
        }
      });
    } on Object {
      if (mounted) {
        setState(() {
          _envoiEnCours = false;
          _echecEnvoi = true;
        });
      }
    }
  }
}

/// Un cahier sans constat (vide ou erreur) : l'etat, puis la reprise et le
/// bouton. Un cahier tardif vaut mieux qu'un cahier perdu.
class _SansConstat extends StatelessWidget {
  const _SansConstat({required this.etat, required this.validation});

  final Widget etat;
  final Widget validation;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[etat, Ecart.vXxl, validation],
  );
}

/// Le constat prerempli, dans l'ordre de la planche 4.
class _Constat extends StatelessWidget {
  const _Constat({
    required this.vue,
    required this.decisions,
    required this.projections,
    required this.lectureSeule,
    required this.aValider,
    required this.onAjuster,
    required this.onCorriger,
    required this.onRetour,
    required this.validation,
  });

  final VueCahier vue;
  final Map<String, DecisionEleve> decisions;
  final Map<String, ProjectionEleve> projections;
  final bool lectureSeule;
  final bool aValider;
  final Future<void> Function(ParticipantBrouillon participant) onAjuster;
  final VoidCallback onCorriger;
  final VoidCallback onRetour;
  final Widget Function(bool large) validation;

  @override
  Widget build(BuildContext context) {
    final BrouillonCahier? brouillon = vue.brouillon;
    if (brouillon == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        // Deux colonnes a partir de 840 de largeur utile, divisee par le
        // facteur de texte (K-42, regle 6).
        final double texte = MediaQuery.textScalerOf(context).scale(1);
        final bool large =
            contraintes.maxWidth / texte >= AppGabarit.seuilEtendu;
        final Widget ecart = large ? Ecart.vXxxl : Ecart.vXxl;

        final Widget resume = _Resume(
          brouillon: brouillon,
          vue: vue,
          aValider: aValider,
        );
        final Widget? aRegarder = vue.exceptions.isEmpty
            ? null
            : _Section(
                titre: t.enseignant.cahier.exceptions,
                sousTitre: vue.exceptions.length == 1
                    ? t.enseignant.cahier.uneException
                    : t.enseignant.cahier.plusieursExceptions(
                        nombre: '${vue.exceptions.length}',
                      ),
                eleves: <LigneRubrique>[
                  for (final ParticipantBrouillon p in vue.exceptions)
                    _ligne(p, brouillon),
                ],
              );
        final Widget? nominaux = vue.nominaux.isEmpty
            ? null
            : _Section(
                titre: t.enseignant.cahier.nominaux,
                eleves: <LigneRubrique>[
                  for (final ParticipantBrouillon p in vue.nominaux)
                    _ligne(p, brouillon),
                ],
              );
        final Widget fin = lectureSeule
            ? _DejaDepose(onCorriger: onCorriger, onRetour: onRetour)
            : validation(large);

        if (!large) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              resume,
              if (aRegarder != null) ...<Widget>[ecart, aRegarder],
              if (nominaux != null) ...<Widget>[ecart, nominaux],
              ecart,
              fin,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  resume,
                  if (nominaux != null) ...<Widget>[ecart, nominaux],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xxxl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (aRegarder != null) ...<Widget>[aRegarder, ecart],
                  fin,
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// K-42 (style, regle 4) : une ligne par eleve dans un groupe, jamais une
  /// carte par eleve. Prenom et pastille de presence, une seule ligne douce
  /// (l'exception consignee, le devoir ou la lecture) ; le detail est dans
  /// la feuille « Ajuster ».
  LigneRubrique _ligne(ParticipantBrouillon p, BrouillonCahier brouillon) {
    final VuePresence presence = VuePresence.depuis(
      ligne: ligneDePresence(participant: p, brouillon: brouillon),
      maintenant: brouillon.fin,
    );
    final DecisionEleve? d = decisions[p.membre.studentId];
    final String? devoir = d?.travailMaison;
    final String? legende = d != null && !d.confirme
        ? t.enseignant.cahier.exceptionConsignee
        // K-45 : ce qui est consigne se relit avant de valider (EN-7).
        : d?.pointPhonetique != null
        ? t.enseignant.cahier.pointPhonetiqueNote
        : devoir != null
        ? '${t.enseignant.cahier.travailMaison} : $devoir'
        : p.unite?.nomHumain;
    return LigneRubrique(
      // La photo s'affiche chez l'enseignant (E5, K-44) ; les initiales en
      // repli seulement, sans cle d'avatar.
      meneur: PhotoEleve(
        prenom: p.membre.libelle,
        cleAvatar: projections[p.membre.studentId]?.cleAvatar,
        diametre: AppSpacing.section,
      ),
      libelle: p.membre.libelle,
      legende: legende,
      marque: StatusPill(
        libelle: LignePresence.libelle(presence.etat),
        ton: presence.ton,
      ),
      onPress: lectureSeule ? null : () => unawaited(onAjuster(p)),
    );
  }
}

/// Le resume de la seance : le rappel s'il reste a valider, la duree, le
/// nombre d'eleves et les pastilles de statut (un mot et un nombre, jamais la
/// seule couleur).
class _Resume extends StatelessWidget {
  const _Resume({
    required this.brouillon,
    required this.vue,
    required this.aValider,
  });

  final BrouillonCahier brouillon;
  final VueCahier vue;
  final bool aValider;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final StatutsCahier statuts = StatutsCahier.depuis(brouillon.participants);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (aValider) ...<Widget>[
          Row(
            children: <Widget>[
              PointRappel(
                key: const ValueKey<String>('cahier-point-rappel'),
                libelle: t.enseignant.classes.rappelCahier,
              ),
              Ecart.hSm,
              Flexible(
                child: ExcludeSemantics(
                  child: Text(
                    t.enseignant.cahier.aValider,
                    style: palette.inkMuted.applyTo(
                      textes.labelLarge ?? const TextStyle(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Ecart.vSm,
        ],
        // Doc 04 §20.3 et §33 n. 7 : la seance est dite une fois, dans
        // l'en-tete (K-42 §5), sous le nom de la Classe.
        // La duree du cahier est celle que la base a calculee, et une seule.
        Text(
          brouillon.minutesInterruption > 0
              ? t.enseignant.cahier.dureeEtInterruption(
                  minutes: '${brouillon.dureeMinutes}',
                  interruption: '${brouillon.minutesInterruption}',
                )
              : t.enseignant.cahier.duree(minutes: '${brouillon.dureeMinutes}'),
          style: textes.titleMedium,
        ),
        Ecart.vXs,
        Text(
          brouillon.participants.length == 1
              ? t.enseignant.cahier.unEleve
              : t.enseignant.cahier.eleves(
                  nombre: '${brouillon.participants.length}',
                ),
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            StatusPill(
              libelle: t.enseignant.cahier.statutPresents(
                nombre: '${statuts.presents}',
              ),
              ton: TonEtat.neutre,
            ),
            StatusPill(
              libelle: t.enseignant.cahier.statutAbsents(
                nombre: '${statuts.absents}',
              ),
              ton: statuts.absents > 0 ? TonEtat.alerte : TonEtat.neutre,
            ),
            StatusPill(
              libelle: t.enseignant.cahier.statutEnRetard(
                nombre: '${statuts.enRetard}',
              ),
              ton: statuts.enRetard > 0
                  ? TonEtat.avertissement
                  : TonEtat.neutre,
            ),
          ],
        ),
        if (vue.toutEstNominal) ...<Widget>[
          Ecart.vMd,
          Text(t.enseignant.cahier.toutEstNominal, style: textes.bodyMedium),
        ],
      ],
    );
  }
}

/// Une section d'eleves : un titre, une ligne douce, puis un seul groupe.
class _Section extends StatelessWidget {
  const _Section({required this.titre, required this.eleves, this.sousTitre});

  final String titre;
  final String? sousTitre;
  final List<LigneRubrique> eleves;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? sous = sousTitre;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(header: true, child: Text(titre, style: textes.titleSmall)),
        if (sous != null) ...<Widget>[
          Ecart.vXs,
          Text(
            sous,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vSm,
        GroupeReglages(lignes: eleves),
      ],
    );
  }
}

/// Le cahier deja valide : il se lit, et il reste corrigeable (K-45, point 5).
class _DejaDepose extends StatelessWidget {
  const _DejaDepose({required this.onCorriger, required this.onRetour});

  final VoidCallback onCorriger;
  final VoidCallback onRetour;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.enseignant.cahier.dejaDepose, style: textes.titleMedium),
        Ecart.vLg,
        _Actions(onCorriger: onCorriger, onRetour: onRetour),
      ],
    );
  }
}

/// « Corriger le cahier » (tertiaire), puis « Retour a ma journee » au bord
/// de fin (contrat B).
class _Actions extends StatelessWidget {
  const _Actions({required this.onRetour, this.onCorriger});

  final VoidCallback? onCorriger;
  final VoidCallback onRetour;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? corriger = onCorriger;
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        if (corriger != null)
          IntrinsicWidth(
            child: ActionPrincipale(
              key: const ValueKey<String>('cahier-corriger'),
              libelle: t.enseignant.cahier.corriger,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              onPress: corriger,
            ),
          ),
        IntrinsicWidth(
          child: ActionPrincipale(
            libelle: t.enseignant.cahier.retourJournee,
            pleineLargeur: false,
            onPress: onRetour,
          ),
        ),
      ],
    );
  }
}

/// Le bloc d'un eleve : sa photo, sa presence preremplie, puis son
/// evaluation (K-45, point 3) : performance, faiblesses, devoir a faire.
/// La feuille de reglage d'un eleve.
///
/// **La correction de presence n'est pas redessinee** : c'est
/// `PresenceCorrectionPanneau`, deja teste, avec ses quatre etats de mutation et
/// sa regle de motif obligatoire, que son propre commentaire destinait « a la
/// salle enseignant ou a l'espace administration ». Le cahier le branche ici.
class _FeuilleAjuster extends StatefulWidget {
  const _FeuilleAjuster({
    required this.participant,
    required this.brouillon,
    required this.decision,
  });

  final ParticipantBrouillon participant;
  final BrouillonCahier brouillon;
  final DecisionEleve decision;

  @override
  State<_FeuilleAjuster> createState() => _FeuilleAjusterState();
}

class _FeuilleAjusterState extends State<_FeuilleAjuster> {
  late final TextEditingController _objectif = TextEditingController(
    text: widget.decision.objectifPersonnel ?? '',
  );
  late final TextEditingController _travail = TextEditingController(
    text: widget.decision.travailMaison ?? '',
  );

  late String? _motifException = widget.decision.motifException;
  late String? _phonetique = widget.decision.pointPhonetique;
  late bool _nouveauSuspendu = widget.decision.nouveauSuspendu;

  @override
  void dispose() {
    _objectif.dispose();
    _travail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final ParticipantBrouillon participant = widget.participant;
    final UniteCurriculum? unite = participant.unite;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // EN-12 (K-42, regle 4) : le detail de l'eleve, sorti de la ligne
        // du cahier, se lit ici.
        Text(participant.membre.identifiantImmuable, style: discret),
        if (unite != null) ...<Widget>[
          Ecart.vSm,
          // Le nom humain seul fait titre ; le code technique reste un
          // sous-texte discret.
          Text(unite.nomHumain, style: textes.bodyMedium),
          Text(unite.codeTechnique, style: discret),
        ],
        if (participant.position case final position?) ...<Widget>[
          Ecart.vSm,
          Text(
            t.enseignant.cahier.position(
              sourate: '${position.sourate}',
              verset: '${position.verset}',
            ),
            style: discret,
          ),
        ],
        // EN-7 : echelle attendue du directeur. Performance et faiblesses
        // (K-45, point 3) : ni le doc 04 §20 ni la planche 4 ne donnent
        // d'echelle ni de mots. L'emplacement reste vide.
        const SizedBox.shrink(
          key: ValueKey<String>('cahier-emplacement-performance'),
        ),
        const SizedBox.shrink(
          key: ValueKey<String>('cahier-emplacement-faiblesses'),
        ),
        Ecart.vSection,
        PresenceCorrectionPanneau(
          cible: PresenceCorrectionCible(
            ligne: ligneDePresence(
              participant: widget.participant,
              brouillon: widget.brouillon,
            ),
            vue: VuePresence.depuis(
              ligne: ligneDePresence(
                participant: widget.participant,
                brouillon: widget.brouillon,
              ),
              maintenant: widget.brouillon.fin,
            ),
          ),
          // Des capacites, jamais un role : un `if (role == admin)` dans un
          // ecran est un defaut (lib/CLAUDE.md). L'enseignant de la seance peut
          // signaler les deux exceptions que le contrat autorise, et rien de
          // plus.
          capacites: const PresenceCorrectionCapacites(
            peutCorriger: true,
            // « Excuser l'absence » retire : l'enseignant ne juge pas une
            // absence (planche 4, R2).
            peutExcuser: false,
          ),
          adaptateur: _AdaptateurExceptionCahier(_consigner),
          libelles: libellesCorrectionCahier(),
        ),
        Ecart.vSection,
        Text(t.enseignant.cahier.pointPhonetique, style: textes.titleSmall),
        Ecart.vXs,
        Text(t.enseignant.cahier.pointPhonetiqueDetail, style: discret),
        Ecart.vMd,
        ChoiceCardGroup(
          options: referentielMakharij(),
          valeurInitiale: _reponseInitiale(),
          onChange: _choisirPhonetique,
        ),
        Ecart.vSection,
        Text(t.enseignant.cahier.objectif, style: textes.titleSmall),
        Ecart.vXs,
        // La marge autorisee d'un objectif personnel n'existe pas encore comme
        // regle : `CleRegle` ne porte que quatre cles, toutes en minutes ou en
        // nombre d'eleves. L'ecran ne borne donc rien avec une constante
        // inventee ; il dit ce qui encadre l'objectif
        // (`CONTRACT_REQUEST_C.md`).
        Text(t.enseignant.cahier.objectifDetail, style: discret),
        Ecart.vMd,
        TextField(
          controller: _objectif,
          maxLines: 2,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(labelText: t.enseignant.cahier.objectif),
        ),
        Ecart.vXl,
        Text(t.enseignant.cahier.travailMaison, style: textes.titleSmall),
        Ecart.vXs,
        Text(t.enseignant.cahier.travailMaisonDetail, style: discret),
        Ecart.vMd,
        TextField(
          controller: _travail,
          maxLines: 2,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            labelText: t.enseignant.cahier.travailMaison,
          ),
        ),
        Ecart.vXl,
        SettingRow(
          title: t.enseignant.cahier.suspendreNouveau,
          description: t.enseignant.cahier.suspendreNouveauDetail,
          icon: AppIcons.pause,
          controle: Switch(
            value: _nouveauSuspendu,
            onChanged: (bool actif) => setState(() => _nouveauSuspendu = actif),
          ),
        ),
        Ecart.vSection,
        // Un libelle qui lui est propre, et non « Valider » : la feuille de
        // confirmation du panneau de presence porte deja ce mot, et deux boutons
        // « Valider » sur une meme surface ne se distinguent pas.
        ActionPrincipale(
          libelle: t.enseignant.cahier.ajusterValider,
          onPress: _rendre,
        ),
      ],
    );
  }

  ReponseChoix? _reponseInitiale() {
    final String? phonetique = _phonetique;
    if (phonetique == null || phonetique.isEmpty) {
      return null;
    }
    final bool connu = referentielMakharij().any(
      (OptionChoix o) => o.valeur == phonetique,
    );
    return connu
        ? ReponseChoix(valeurs: <String>{phonetique})
        : ReponseChoix(
            valeurs: const <String>{ChoiceCardGroup.valeurAutre},
            saisieLibre: phonetique,
          );
  }

  void _choisirPhonetique(ReponseChoix reponse) {
    final String? libre = reponse.saisieLibre?.trim();
    setState(() {
      if (reponse.valeurs.contains(ChoiceCardGroup.valeurAutre)) {
        _phonetique = libre == null || libre.isEmpty ? null : libre;
      } else {
        _phonetique = reponse.valeurs.isEmpty ? null : reponse.valeurs.first;
      }
    });
  }

  /// Consigne l'exception signalee par le panneau partage.
  ///
  /// Elle part **dans le cahier**, pas dans une seconde ecriture : le contenu du
  /// cahier porte le motif, la file hors ligne porte la cle, et une seule
  /// ecriture atteint la base. L'application de l'exception a
  /// `session_presence_override` demande un adaptateur serveur qui n'existe pas
  /// encore (`CONTRACT_REQUEST_C.md`) ; l'ecrire ici ferait deux chemins vers la
  /// meme decision.
  void _consigner(PresenceCorrectionCommande commande) =>
      setState(() => _motifException = commande.motif);

  void _rendre() {
    final String objectif = _objectif.text.trim();
    final String travail = _travail.text.trim();
    final String? motif = _motifException;

    Navigator.of(context).pop(
      DecisionEleve(
        studentId: widget.participant.membre.studentId,
        confirme: motif == null,
        motifException: motif,
        pointPhonetique: _phonetique,
        objectifPersonnel: objectif.isEmpty ? null : objectif,
        travailMaison: travail.isEmpty ? null : travail,
        nouveauSuspendu: _nouveauSuspendu,
      ),
    );
  }
}

/// L'adaptateur du panneau de correction, cote cahier.
///
/// Il n'ecrit rien tout seul : il **consigne** la decision dans le cahier en
/// cours de redaction, qui partira avec sa cle d'idempotence. C'est ce qui rend
/// l'exception aussi resistante a la coupure que le reste du cahier.
class _AdaptateurExceptionCahier implements PresenceCorrectionAdaptateur {
  const _AdaptateurExceptionCahier(this._consigner);

  final void Function(PresenceCorrectionCommande commande) _consigner;

  @override
  Future<void> appliquer(PresenceCorrectionCommande commande) async =>
      _consigner(commande);
}

/// Les libelles du panneau de correction, lus depuis l'i18n.
///
/// `PresenceCorrectionLibelles` injecte treize chaines en parametres au lieu de
/// lire `t.*` : c'est une dette de son lot d'origine, pas une liberte. Cette
/// fonction est le seul endroit du cahier ou elle se paie, et elle la paie avec
/// des cles slang.
PresenceCorrectionLibelles libellesCorrectionCahier() =>
    PresenceCorrectionLibelles(
      titre: t.enseignant.cahier.exceptionTitre,
      corriger: t.enseignant.cahier.exceptionCorriger,
      excuser: t.enseignant.cahier.exceptionExcuser,
      confirmation: t.enseignant.cahier.exceptionConfirmation,
      motif: t.enseignant.cahier.exceptionMotif,
      motifRequis: t.enseignant.cahier.exceptionMotifRequis,
      confirmer: t.commun.valider,
      annuler: t.commun.annuler,
      mutationEnCours: t.enseignant.cahier.exceptionEnCours,
      succes: t.enseignant.cahier.exceptionSucces,
      erreur: t.enseignant.cahier.exceptionErreur,
      horsLigne: t.enseignant.cahier.exceptionHorsLigne,
    );

/// Ce que l'ecran dit une fois le cahier parti (doc 04 §20.7 et §20.8).
///
/// « Cahier enregistre » seulement sur la confirmation du serveur ; en file
/// locale, « En attente d'envoi ». Aucune minuterie : rien ne se ferme seul.
class _ApresDepot extends StatelessWidget {
  const _ApresDepot({
    required this.sort,
    required this.corrigeLe,
    required this.onCorriger,
    required this.onRetour,
  });

  final SortCahier sort;
  final DateTime? corrigeLe;
  final VoidCallback? onCorriger;
  final VoidCallback onRetour;

  @override
  Widget build(BuildContext context) {
    final DateTime? corrige = corrigeLe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        switch (sort) {
          SortCahier.envoye => EmptyState(
            message: t.enseignant.cahier.depose,
            invitation: corrige == null
                ? t.enseignant.cahier.deposeDetail
                : t.enseignant.cahier.corrigeLe(date: _date(corrige)),
            icone: AppIcons.succes,
            registre: RegistreVide.bonneNouvelle,
          ),
          SortCahier.enFile => EmptyState(
            message: t.enseignant.cahier.enFileTitre,
            invitation: t.enseignant.cahier.enFileDetail,
            icone: AppIcons.enAttenteEnvoi,
            registre: RegistreVide.subi,
          ),
        },
        Ecart.vLg,
        _Actions(onCorriger: onCorriger, onRetour: onRetour),
      ],
    );
  }

  /// « lundi 28 septembre », par les libelles `commun.dates`.
  static String _date(DateTime d) => t.commun.dates.jourDate(
    jour: t.commun.dates.jours[d.weekday - 1].toLowerCase(),
    numero: d.day,
    mois: t.commun.dates.mois[d.month - 1],
  );
}

/// Rend a un bouton sa largeur naturelle quand [borne] est vrai.
class _Borne extends StatelessWidget {
  const _Borne({required this.borne, required this.child});

  final bool borne;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      borne ? IntrinsicWidth(child: child) : child;
}

/// « Seance du {jour} {numero} {mois} a {heure} » (libelle de « A terminer »).
String _seanceDu(DateTime debut) => t.enseignant.journee.cahierDetail(
  jour: t.commun.dates.jours[debut.weekday - 1].toLowerCase(),
  numero: '${debut.day}',
  mois: t.commun.dates.mois[debut.month - 1],
  heure:
      '${debut.hour.toString().padLeft(2, '0')}:'
      '${debut.minute.toString().padLeft(2, '0')}',
);
