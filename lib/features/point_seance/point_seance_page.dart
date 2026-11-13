// POINT-DE-SEANCE (lot 6 de la charte ; directeur, 13/11/2026 : « le cahier me
// fatigue »). La page du point de fin de seance : les presents, tous « A
// suivi » ; un toucher pour « A renforcer » ; un seul toucher obligatoire,
// pour l'eleve tire. Le serveur decide de tout (presents, tirage, delai) ;
// cette page affiche et envoie.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/point_seance/port_point_seance.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart' show TonEtat;
import '../../core/widgets/zone_saisie.dart';

/// Le libelle d'une reponse.
String libelleReponsePoint(ReponsePoint r) => switch (r) {
  ReponsePoint.aSuivi => t.pointSeance.aSuivi,
  ReponsePoint.aRenforcer => t.pointSeance.aRenforcer,
  ReponsePoint.acquis => t.pointSeance.acquis,
  ReponsePoint.pasEcoute => t.pointSeance.pasEcoute,
};

/// La page du point de fin de seance de [seanceId].
class PointSeancePage extends ConsumerWidget {
  /// Cree la page.
  const PointSeancePage({required this.seanceId, super.key});

  /// La seance.
  final String seanceId;

  void _retour(BuildContext context) {
    final GoRouter routeur = GoRouter.of(context);
    if (routeur.canPop()) {
      routeur.pop();
    } else {
      routeur.go(Routes.enseignantJournee);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PointSeance?> lecture = ref.watch(
      pointSeanceProvider(seanceId),
    );
    void relire() => ref.invalidate(pointSeanceProvider(seanceId));

    final PointSeance? point = lecture.value;
    final Widget corps;
    if (!lecture.hasValue && !lecture.hasError) {
      corps = const Skeleton.liste(
        key: ValueKey<String>('point-seance-chargement'),
        lignes: 4,
      );
    } else if (point == null) {
      // Hors ligne, le bandeau de la page le dit ; le bloc dit ce qui manque.
      final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
      corps = horsLigne
          ? EtatSysteme.sansDonnees(
              key: const ValueKey<String>('point-seance-erreur'),
              quoi: t.pointSeance.sansDonnees,
              onAction: relire,
            )
          : EtatSysteme(
              key: const ValueKey<String>('point-seance-erreur'),
              nature: NatureEtat.echecServeur,
              phrase: t.pointSeance.erreur,
              libelleAction: t.commun.reessayer,
              onAction: relire,
            );
    } else if (!point.tenue) {
      corps = EmptyState(
        key: const ValueKey<String>('point-seance-non-tenue'),
        message: t.pointSeance.nonTenueTitre,
        invitation: t.pointSeance.nonTenue,
        icone: AppIcons.attente,
        registre: RegistreVide.subi,
      );
    } else if (point.eleves.isEmpty) {
      corps = EmptyState(
        key: const ValueKey<String>('point-seance-vide'),
        message: t.pointSeance.aucunPresent,
        icone: AppIcons.suivi,
        registre: RegistreVide.subi,
      );
    } else {
      corps = _Formulaire(
        // Une page relue (liste des presents changee) repart de zero.
        key: ValueKey<String>(
          'point-${point.seanceId}-${point.envoye}-'
          '${point.eleves.map((ElevePoint e) => e.eleveId).join(',')}',
        ),
        point: point,
        onRelire: relire,
      );
    }

    return PageShell(
      titre: t.pointSeance.titre,
      sousTitre: point == null
          ? null
          : t.pointSeance.sousTitre(
              classe: point.classe,
              jour: t.commun.dates.jours[point.debut.weekday - 1].toLowerCase(),
              numero: '${point.debut.day}',
              mois: t.commun.dates.mois[point.debut.month - 1],
            ),
      onRetour: () => _retour(context),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: corps,
        ),
      ),
    );
  }
}

class _Formulaire extends ConsumerStatefulWidget {
  const _Formulaire({required this.point, required this.onRelire, super.key});

  final PointSeance point;
  final VoidCallback onRelire;

  @override
  ConsumerState<_Formulaire> createState() => _FormulaireState();
}

class _FormulaireState extends ConsumerState<_Formulaire> {
  late final Map<String, ReponsePoint> _reponses = <String, ReponsePoint>{
    for (final ElevePoint e in widget.point.eleves)
      if (e.reponse != null) e.eleveId: e.reponse!,
  };
  late final TextEditingController _note = TextEditingController(
    text: widget.point.note ?? '',
  );
  bool _envoi = false;
  String? _echec;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  ElevePoint? get _tire {
    for (final ElevePoint e in widget.point.eleves) {
      if (e.tire) return e;
    }
    return null;
  }

  String _phraseRefus(RefusPoint refus) => switch (refus) {
    RefusPoint.eleveTireSansReponse => t.pointSeance.manqueTire(
      prenom: _tire?.prenom ?? '',
    ),
    RefusPoint.delaiDepasse => t.pointSeance.refusDelai,
    RefusPoint.seanceNonTenue => t.pointSeance.nonTenue,
    RefusPoint.presentsChanges => t.pointSeance.refusPresents,
    RefusPoint.aucunPresent => t.pointSeance.aucunPresent,
    RefusPoint.refuse => t.pointSeance.refusAcces,
    RefusPoint.reseau => t.pointSeance.refusReseau,
  };

  Future<void> _envoyer([Map<String, ReponsePoint>? reponses]) async {
    final PortPointSeance? port = ref.read(portPointSeanceProvider);
    if (port == null || _envoi) return;
    setState(() {
      _envoi = true;
      _echec = null;
    });
    try {
      final String note = _note.text.trim();
      await port.envoyer(
        widget.point.seanceId,
        reponses ?? _reponses,
        note: note.isEmpty ? null : note,
      );
      if (!mounted) return;
      ref
        ..invalidate(pointSeanceProvider(widget.point.seanceId))
        ..invalidate(pointsAFaireProvider);
    } on EchecPointSeance catch (e) {
      if (!mounted) return;
      setState(() => _echec = _phraseRefus(e.refus));
      // La liste a change, ou le delai est passe : la page se relit.
      if (e.refus == RefusPoint.presentsChanges ||
          e.refus == RefusPoint.delaiDepasse) {
        widget.onRelire();
      }
    } on Object {
      if (!mounted) return;
      setState(() => _echec = t.pointSeance.refusReseau);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final PointSeance point = widget.point;
    final ElevePoint? tire = _tire;
    final bool modifiable = point.peutEnvoyer;
    final bool tireRepondu = tire == null || _reponses[tire.eleveId] != null;
    final List<ElevePoint> autres = <ElevePoint>[
      for (final ElevePoint e in point.eleves)
        if (!e.tire) e,
    ];
    final DateTime? jusqua = point.modifiableJusqua;
    final TextStyle corps = Theme.of(context).textTheme.bodyLarge!;
    final TextStyle doux = AppPalette.of(context).inkMuted.applyTo(corps);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (point.envoye) ...<Widget>[
          BandeauAttention(
            key: const ValueKey<String>('point-seance-envoye'),
            ton: TonEtat.succes,
            titre: t.pointSeance.envoyeTitre,
            message: modifiable && jusqua != null
                ? t.pointSeance.envoyeCorrigible(
                    numero: '${jusqua.day}',
                    mois: t.commun.dates.mois[jusqua.month - 1],
                    heure:
                        '${jusqua.hour.toString().padLeft(2, '0')}:'
                        '${jusqua.minute.toString().padLeft(2, '0')}',
                  )
                : t.pointSeance.envoyeFige,
            action: LienFleche(
              key: const ValueKey<String>('point-seance-vers-cahier'),
              libelle: t.pointSeance.versCahier,
              alignerEnDebut: true,
              onPress: () =>
                  GoRouter.of(context)
                      .push<void>(Routes.cahierPour(point.seanceId)),
            ),
          ),
          Ecart.vXl,
        ] else if (modifiable) ...<Widget>[
          Text(t.pointSeance.intro, style: doux),
          Ecart.vXl,
        ] else ...<Widget>[
          Text(
            t.pointSeance.pasEncoreEnvoye,
            key: const ValueKey<String>('point-seance-pas-envoye'),
            style: corps,
          ),
          Ecart.vXl,
        ],
        PileCartes(
          children: <Widget>[
            if (tire != null)
              AppCard(
                key: const ValueKey<String>('point-seance-tire'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SectionHeader(titre: t.pointSeance.tireTitre),
                    Text(
                      t.pointSeance.tireAide(prenom: tire.prenom),
                      style: doux,
                    ),
                    Ecart.vLg,
                    _LigneEleve(
                      eleve: tire,
                      choix: const <ReponsePoint>[
                        ReponsePoint.acquis,
                        ReponsePoint.aRenforcer,
                      ],
                      // « Pas eu le temps » n'est pas un segment : aucun des
                      // deux n'est retenu.
                      valeur: _reponses[tire.eleveId] == ReponsePoint.pasEcoute
                          ? null
                          : _reponses[tire.eleveId],
                      modifiable: modifiable,
                      onChoix: (ReponsePoint r) =>
                          setState(() => _reponses[tire.eleveId] = r),
                    ),
                    if (_reponses[tire.eleveId] == ReponsePoint.pasEcoute) ...[
                      Ecart.vMd,
                      Text(
                        t.pointSeance.pasEcoute,
                        key: const ValueKey<String>('point-seance-pas-ecoute'),
                        style: corps,
                      ),
                    ],
                    // La sortie honnete : un toucher qui envoie le point.
                    if (modifiable && !tireRepondu) ...<Widget>[
                      Ecart.vMd,
                      LienFleche(
                        key: const ValueKey<String>(
                          'point-seance-pas-eu-le-temps',
                        ),
                        libelle: t.pointSeance.pasEcoute,
                        alignerEnDebut: true,
                        onPress: () => _envoyer(<String, ReponsePoint>{
                          ..._reponses,
                          tire.eleveId: ReponsePoint.pasEcoute,
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            if (autres.isNotEmpty)
              AppCard(
                key: const ValueKey<String>('point-seance-presents'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SectionHeader(titre: t.pointSeance.presentsTitre),
                    for (final (int i, ElevePoint e) in autres.indexed) ...[
                      if (i > 0) Ecart.vLg,
                      _LigneEleve(
                        eleve: e,
                        choix: const <ReponsePoint>[
                          ReponsePoint.aSuivi,
                          ReponsePoint.aRenforcer,
                        ],
                        valeur: _reponses[e.eleveId] ?? ReponsePoint.aSuivi,
                        modifiable: modifiable,
                        onChoix: (ReponsePoint r) =>
                            setState(() => _reponses[e.eleveId] = r),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
        if (point.horsPoint.isNotEmpty) ...<Widget>[
          Ecart.vLg,
          Text(
            t.pointSeance.horsPoint(
              noms: <String>[
                for (final EleveHorsPoint h in point.horsPoint)
                  switch (h.presence) {
                    PresencePoint.absente => t.pointSeance.horsAbsent(
                      prenom: h.prenom,
                    ),
                    PresencePoint.partielle => t.pointSeance.horsPartiel(
                      prenom: h.prenom,
                    ),
                    _ => t.pointSeance.horsInconnu(prenom: h.prenom),
                  },
              ].join(', '),
            ),
            key: const ValueKey<String>('point-seance-hors-point'),
            style: doux,
          ),
        ],
        if (modifiable) ...<Widget>[
          Ecart.vXl,
          ZoneSaisie(
            controleur: _note,
            cleChamp: const ValueKey<String>('point-seance-note'),
            libelle: t.pointSeance.noteLibelle,
            aide: t.pointSeance.noteAide,
            minLignes: 2,
            maxLignes: 4,
          ),
        ] else if ((point.note ?? '').isNotEmpty) ...<Widget>[
          Ecart.vLg,
          Text(t.historiqueSeances.noteDe(note: point.note!), style: corps),
        ],
        LocalFeedback(message: _echec, persistant: true),
        if (modifiable) ...<Widget>[
          Ecart.vLg,
          if (tireRepondu)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: ActionPrincipale(
                key: const ValueKey<String>('point-seance-envoyer'),
                libelle: point.envoye
                    ? t.pointSeance.corriger
                    : t.pointSeance.envoyer,
                enCours: _envoi,
                onPress: _envoyer,
              ),
            )
          else
            // Un bouton qui ne peut pas aboutir n'est pas rendu : la phrase
            // dit ce qui manque.
            Text(
              t.pointSeance.manqueTire(prenom: tire.prenom),
              key: const ValueKey<String>('point-seance-manque-tire'),
              style: corps,
            ),
        ],
      ],
    );
  }
}

/// Une ligne : le prenom (et l'etape), et le choix a deux etats. Sans droit
/// d'ecrire, la reponse se lit en mots.
class _LigneEleve extends StatelessWidget {
  const _LigneEleve({
    required this.eleve,
    required this.choix,
    required this.valeur,
    required this.modifiable,
    required this.onChoix,
  });

  final ElevePoint eleve;
  final List<ReponsePoint> choix;
  final ReponsePoint? valeur;
  final bool modifiable;
  final ValueChanged<ReponsePoint> onChoix;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final Widget nom = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(eleve.prenom, style: textes.titleMedium),
        if (eleve.etape != null)
          Text(
            eleve.etape!,
            style: palette.inkMuted.applyTo(textes.bodyMedium!),
          ),
      ],
    );
    final Widget reponse = modifiable
        ? Semantics(
            container: true,
            label: t.pointSeance.reponseDe(prenom: eleve.prenom),
            child: ControleSegmente<ReponsePoint?>(
              key: ValueKey<String>('point-seance-choix-${eleve.eleveId}'),
              segments: <Segment<ReponsePoint?>>[
                for (final ReponsePoint r in choix)
                  Segment<ReponsePoint?>(
                    valeur: r,
                    libelle: libelleReponsePoint(r),
                  ),
              ],
              valeur: valeur,
              onChange: (ReponsePoint? r) {
                if (r != null) onChoix(r);
              },
            ),
          )
        : Text(
            valeur == null ? '' : libelleReponsePoint(valeur!),
            style: textes.bodyLarge,
          );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final bool cote =
            c.maxWidth >= 560 &&
            MediaQuery.textScalerOf(context).scale(16) / 16 <= 1.3;
        if (cote) {
          return Row(
            children: <Widget>[
              Expanded(flex: 2, child: nom),
              Ecart.hXl,
              Expanded(flex: 3, child: reponse),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[nom, Ecart.vMd, reponse],
        );
      },
    );
  }
}
