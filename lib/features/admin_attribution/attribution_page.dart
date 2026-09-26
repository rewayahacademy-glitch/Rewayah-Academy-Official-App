import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/service_admin.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/matching/service_attribution.dart';
import '../../core/planning/service_planning.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';

/// `ADM-05` : l'attribution manuelle.
///
/// **L'ecran de secours du matching inverse**, et le seul endroit du produit ou
/// une affectation se cree sans qu'un enseignant l'ait demandee. Deux listes et
/// un bouton : les eleves que personne n'a pris a gauche, les enseignants a
/// droite, la confirmation en dessous. Le meme geste que `ENS-06`, vu depuis
/// l'administration (`parcours-utilisateurs.md` section 5).
///
/// Trois choix de rendu, tous tenus par un test :
///
///   * **l'eleve qui n'a pose aucune heure reste dans la liste**, et dit
///     pourquoi il n'est pas attribuable. Le masquer donnerait un compteur
///     `ADM-01` a 1 et une liste vide en face, ce qui ressemble a une panne ;
///   * **les enseignants qui ne partagent aucune heure sont rendus eux aussi**,
///     apres les autres. Les retirer viderait l'ecran le jour precis ou l'on
///     en a besoin ;
///   * **le chargement montre la forme de ce qui arrive**, pas le mot
///     « Chargement ». C'est le premier ecran du produit a employer `Skeleton`.
class AttributionPage extends ConsumerStatefulWidget {
  /// Cree l'ecran d'attribution.
  const AttributionPage({super.key});

  @override
  ConsumerState<AttributionPage> createState() => _AttributionPageEtat();
}

class _AttributionPageEtat extends ConsumerState<AttributionPage> {
  final TextEditingController _motif = TextEditingController();
  String? _eleveChoisi;
  String? _enseignantChoisi;
  Creneau? _creneauChoisi;
  bool _envoi = false;
  String? _erreur;
  String? _succes;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  void _choisirEleve(String? eleveId) => setState(() {
    _eleveChoisi = eleveId;
    // Changer d'eleve annule tout le reste : un creneau propose par une famille
    // n'a aucun sens pour une autre, et un motif ecrit pour un enfant ne se
    // recycle pas sur le suivant.
    _enseignantChoisi = null;
    _creneauChoisi = null;
    _motif.clear();
    _erreur = null;
  });

  /// Choisit un enseignant, et preselectionne l'heure quand elle est evidente.
  ///
  /// C'est ce qui fait tenir la promesse des « deux taps » : une seule heure
  /// possible ne se redemande pas.
  void _choisirEnseignant(
    EnseignantCandidat enseignant,
    List<Creneau> offerts,
  ) => setState(() {
    _enseignantChoisi = enseignant.id;
    _creneauChoisi = offerts.length == 1 ? offerts.first : null;
    _motif.clear();
    _erreur = null;
  });

  Future<void> _attribuer({
    required FoyerEnAttente eleve,
    required EnseignantCandidat enseignant,
    required Creneau creneau,
  }) async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceAttributionProvider)
          .attribuer(
            eleveId: eleve.eleveId,
            enseignantId: enseignant.id,
            creneau: creneau,
            motif: enseignant.croise ? null : _motif.text.trim(),
          );
      ref
        ..invalidate(foyersEnAttenteProvider)
        // Le centre de commande compte cet eleve dans « Foyers sans
        // enseignant » : le laisser tel quel afficherait un chiffre que cet
        // ecran vient de dementir.
        ..invalidate(indicateursProvider)
        ..invalidate(enseignantsPourProvider(eleve.eleveId));
      if (mounted) {
        setState(() {
          _succes = t.admin.attribution.attribuer(
            eleve: eleve.libelle,
            enseignant: enseignant.libelleCourt,
          );
          _eleveChoisi = null;
          _enseignantChoisi = null;
          _creneauChoisi = null;
          _motif.clear();
        });
      }
    } on Object catch (erreur) {
      if (mounted) {
        setState(() => _erreur = _message(erreur));
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final bool large = AppGabarit.de(context).estLarge;
    final AsyncValue<List<FoyerEnAttente>> file = ref.watch(
      foyersEnAttenteProvider,
    );

    return PageShell(
      titre: t.admin.attribution.titre,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.admin.attribution.intro, style: textes.bodyMedium),
          Ecart.vXl,
          if (_succes != null) ...<Widget>[
            LocalFeedback(message: _succes),
            Ecart.vLg,
          ],
          // Les getters, jamais le type d'execution : Riverpod 3 relance un
          // provider en echec tout seul, et l'etat repasse par `AsyncLoading` en
          // conservant `hasError`.
          switch (file) {
            AsyncValue<List<FoyerEnAttente>>(hasValue: true) => _Corps(
              foyers: file.requireValue,
              eleveChoisi: _eleveChoisi,
              enseignantChoisi: _enseignantChoisi,
              creneauChoisi: _creneauChoisi,
              motif: _motif,
              envoi: _envoi,
              erreur: _erreur,
              large: large,
              onChoisirEleve: _choisirEleve,
              onChoisirEnseignant: _choisirEnseignant,
              onChoisirCreneau: (Creneau creneau) =>
                  setState(() => _creneauChoisi = creneau),
              onMotifChange: (String _) => setState(() {}),
              onAttribuer: _attribuer,
            ),
            AsyncValue<List<FoyerEnAttente>>(hasError: true) => EmptyState(
              message: t.admin.attribution.erreurEleves,
              icone: AppIcons.avertissement,
              libelleAction: t.commun.reessayer,
              onAction: () => ref.invalidate(foyersEnAttenteProvider),
            ),
            // Pas le mot « Chargement » : la forme de ce qui arrive. C'est le
            // plus gros ecart de rendu que la Bible section 18 reprochait au
            // produit, et il se voit des la premiere seconde d'usage.
            _ => const Skeleton.liste(lignes: 4),
          },
        ],
      ),
    );
  }
}

/// Les deux listes, et la confirmation dessous.
class _Corps extends StatelessWidget {
  const _Corps({
    required this.foyers,
    required this.eleveChoisi,
    required this.enseignantChoisi,
    required this.creneauChoisi,
    required this.motif,
    required this.envoi,
    required this.erreur,
    required this.large,
    required this.onChoisirEleve,
    required this.onChoisirEnseignant,
    required this.onChoisirCreneau,
    required this.onMotifChange,
    required this.onAttribuer,
  });

  final List<FoyerEnAttente> foyers;
  final String? eleveChoisi;
  final String? enseignantChoisi;
  final Creneau? creneauChoisi;
  final TextEditingController motif;
  final bool envoi;
  final String? erreur;
  final bool large;
  final void Function(String? eleveId) onChoisirEleve;
  final void Function(EnseignantCandidat enseignant, List<Creneau> offerts)
  onChoisirEnseignant;
  final void Function(Creneau creneau) onChoisirCreneau;
  final void Function(String motif) onMotifChange;
  final Future<void> Function({
    required FoyerEnAttente eleve,
    required EnseignantCandidat enseignant,
    required Creneau creneau,
  })
  onAttribuer;

  @override
  Widget build(BuildContext context) {
    if (foyers.isEmpty) {
      return EmptyState(
        message: t.admin.attribution.aucunEleve,
        invitation: t.admin.attribution.aucunEleveDetail,
        icone: AppIcons.attribution,
      );
    }

    final FoyerEnAttente? eleve = _selection(foyers, eleveChoisi);

    final Widget colonneEleves = _ColonneEleves(
      foyers: foyers,
      choisi: eleveChoisi,
      // Sur mobile, la file cede la place des qu'un eleve est choisi : empiler
      // deux listes longues obligerait a chercher a l'aveugle sous le pli ce que
      // le premier tap vient de faire apparaitre.
      replie: !large && eleve != null,
      onChoisir: onChoisirEleve,
    );

    final Widget colonneEnseignants = eleve == null
        ? EmptyState(
            message: t.admin.attribution.choisirEleve,
            invitation: t.admin.attribution.choisirEleveDetail,
            icone: AppIcons.creneaux,
          )
        : _ColonneEnseignants(
            eleve: eleve,
            enseignantChoisi: enseignantChoisi,
            creneauChoisi: creneauChoisi,
            motif: motif,
            envoi: envoi,
            erreur: erreur,
            onChoisirEnseignant: onChoisirEnseignant,
            onChoisirCreneau: onChoisirCreneau,
            onMotifChange: onMotifChange,
            onAttribuer: onAttribuer,
          );

    if (!large) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          colonneEleves,
          if (eleve != null) ...<Widget>[Ecart.vXxl, colonneEnseignants],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: colonneEleves),
        Ecart.hXl,
        Expanded(child: colonneEnseignants),
      ],
    );
  }

  static FoyerEnAttente? _selection(List<FoyerEnAttente> foyers, String? id) {
    if (id == null) {
      return null;
    }
    for (final FoyerEnAttente foyer in foyers) {
      if (foyer.eleveId == id) {
        return foyer;
      }
    }
    // L'eleve choisi vient d'etre attribue par quelqu'un d'autre : la liste
    // relue ne le porte plus, et la colonne de droite repart a zero plutot que
    // de proposer un geste qui echouerait.
    return null;
  }
}

/// La colonne de gauche : les eleves que personne n'a pris.
class _ColonneEleves extends StatelessWidget {
  const _ColonneEleves({
    required this.foyers,
    required this.choisi,
    required this.replie,
    required this.onChoisir,
  });

  final List<FoyerEnAttente> foyers;
  final String? choisi;
  final bool replie;
  final void Function(String? eleveId) onChoisir;

  @override
  Widget build(BuildContext context) {
    final List<FoyerEnAttente> visibles = replie
        ? foyers.where((FoyerEnAttente f) => f.eleveId == choisi).toList()
        : foyers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          titre: t.admin.attribution.colonneEleves,
          compteur: foyers.length,
          libelleAction: replie ? t.admin.attribution.changerEleve : null,
          onAction: replie ? () => onChoisir(null) : null,
        ),
        Ecart.vMd,
        for (final FoyerEnAttente foyer in visibles)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _CarteEleve(
              foyer: foyer,
              selectionne: foyer.eleveId == choisi,
              onPress: foyer.attribuable
                  ? () => onChoisir(foyer.eleveId)
                  : null,
            ),
          ),
      ],
    );
  }
}

/// Un eleve en attente.
class _CarteEleve extends StatelessWidget {
  const _CarteEleve({
    required this.foyer,
    required this.selectionne,
    required this.onPress,
  });

  final FoyerEnAttente foyer;
  final bool selectionne;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    return AppCard(
      onPress: onPress,
      selectionnee: selectionne,
      libelleSemantique: foyer.libelle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(foyer.libelle, style: textes.titleMedium),
          // Masque, le libelle **est** l'identifiant : le repeter sous lui
          // n'apprend rien.
          if (foyer.prenomConnu)
            Text(foyer.identifiantImmuable, style: textes.bodySmall),
          if (foyer.niveau != null)
            Text(
              t.admin.attribution.niveau(niveau: foyer.niveau!),
              style: textes.bodySmall,
            ),
          Ecart.vSm,
          if (foyer.attribuable) ...<Widget>[
            Text(_attente(foyer), style: textes.bodyMedium),
            Ecart.vSm,
            StatusPill(
              libelle: foyer.creneaux.length == 1
                  ? t.admin.attribution.heureProposee
                  : t.admin.attribution.heuresProposees(
                      nombre: '${foyer.creneaux.length}',
                    ),
              ton: TonEtat.neutre,
            ),
          ] else ...<Widget>[
            // Un eleve non attribuable n'est pas une carte grisee sans
            // explication : il dit ce qui manque, et chez qui le geste se
            // trouve.
            StatusPill(
              libelle: t.admin.attribution.sansHeure,
              ton: TonEtat.avertissement,
            ),
            Ecart.vXs,
            Text(t.admin.attribution.sansHeureDetail, style: textes.bodySmall),
          ],
        ],
      ),
    );
  }

  /// Depuis quand ce foyer attend. Appelee seulement quand il a pose une heure :
  /// sans creneau, `depuis` est nul et la carte dit autre chose.
  String _attente(FoyerEnAttente foyer) {
    final int? jours = foyer.joursDAttente(DateTime.now());
    return switch (jours) {
      null || 0 => t.admin.attribution.attendAujourdhui,
      1 => t.admin.attribution.attendUnJour,
      _ => t.admin.attribution.attendJours(jours: '$jours'),
    };
  }
}

/// La colonne de droite : les enseignants, puis la confirmation.
class _ColonneEnseignants extends ConsumerWidget {
  const _ColonneEnseignants({
    required this.eleve,
    required this.enseignantChoisi,
    required this.creneauChoisi,
    required this.motif,
    required this.envoi,
    required this.erreur,
    required this.onChoisirEnseignant,
    required this.onChoisirCreneau,
    required this.onMotifChange,
    required this.onAttribuer,
  });

  final FoyerEnAttente eleve;
  final String? enseignantChoisi;
  final Creneau? creneauChoisi;
  final TextEditingController motif;
  final bool envoi;
  final String? erreur;
  final void Function(EnseignantCandidat enseignant, List<Creneau> offerts)
  onChoisirEnseignant;
  final void Function(Creneau creneau) onChoisirCreneau;
  final void Function(String motif) onMotifChange;
  final Future<void> Function({
    required FoyerEnAttente eleve,
    required EnseignantCandidat enseignant,
    required Creneau creneau,
  })
  onAttribuer;

  /// Les heures proposables pour un enseignant donne.
  ///
  /// Celles qu'il partage avec la famille quand il en partage, sinon toutes
  /// celles que la famille propose : c'est la que se joue l'ADR-021, et c'est la
  /// seule difference entre le chemin nominal et le passage en force.
  static List<Creneau> offerts(
    FoyerEnAttente eleve,
    EnseignantCandidat enseignant,
  ) => enseignant.croise ? enseignant.creneauxCommuns : eleve.creneaux;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<EnseignantCandidat>> liste = ref.watch(
      enseignantsPourProvider(eleve.eleveId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          titre: t.admin.attribution.colonneEnseignants,
          compteur: liste.value?.length,
        ),
        Ecart.vMd,
        switch (liste) {
          AsyncValue<List<EnseignantCandidat>>(hasValue: true) => _Candidats(
            eleve: eleve,
            candidats: liste.requireValue,
            enseignantChoisi: enseignantChoisi,
            creneauChoisi: creneauChoisi,
            motif: motif,
            envoi: envoi,
            erreur: erreur,
            onChoisirEnseignant: onChoisirEnseignant,
            onChoisirCreneau: onChoisirCreneau,
            onMotifChange: onMotifChange,
            onAttribuer: onAttribuer,
          ),
          AsyncValue<List<EnseignantCandidat>>(hasError: true) => EmptyState(
            message: t.admin.attribution.erreurEnseignants,
            icone: AppIcons.avertissement,
            libelleAction: t.commun.reessayer,
            onAction: () =>
                ref.invalidate(enseignantsPourProvider(eleve.eleveId)),
          ),
          _ => const Skeleton.liste(lignes: 3),
        },
      ],
    );
  }
}

/// Les cartes d'enseignant, et la confirmation sous celle qui est choisie.
class _Candidats extends StatelessWidget {
  const _Candidats({
    required this.eleve,
    required this.candidats,
    required this.enseignantChoisi,
    required this.creneauChoisi,
    required this.motif,
    required this.envoi,
    required this.erreur,
    required this.onChoisirEnseignant,
    required this.onChoisirCreneau,
    required this.onMotifChange,
    required this.onAttribuer,
  });

  final FoyerEnAttente eleve;
  final List<EnseignantCandidat> candidats;
  final String? enseignantChoisi;
  final Creneau? creneauChoisi;
  final TextEditingController motif;
  final bool envoi;
  final String? erreur;
  final void Function(EnseignantCandidat enseignant, List<Creneau> offerts)
  onChoisirEnseignant;
  final void Function(Creneau creneau) onChoisirCreneau;
  final void Function(String motif) onMotifChange;
  final Future<void> Function({
    required FoyerEnAttente eleve,
    required EnseignantCandidat enseignant,
    required Creneau creneau,
  })
  onAttribuer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final EnseignantCandidat candidat in candidats) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _CarteEnseignant(
              candidat: candidat,
              selectionne: candidat.id == enseignantChoisi,
              // Un enseignant au plafond ne se choisit pas : la base refuserait
              // apres le geste, et un bouton qui echoue apres coup coute plus
              // cher qu'un choix absent.
              onPress: candidat.complet
                  ? null
                  : () => onChoisirEnseignant(
                      candidat,
                      _ColonneEnseignants.offerts(eleve, candidat),
                    ),
            ),
          ),
          if (candidat.id == enseignantChoisi)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _Confirmation(
                eleve: eleve,
                enseignant: candidat,
                creneauChoisi: creneauChoisi,
                motif: motif,
                envoi: envoi,
                erreur: erreur,
                onChoisirCreneau: onChoisirCreneau,
                onMotifChange: onMotifChange,
                onAttribuer: onAttribuer,
              ),
            ),
        ],
      ],
    );
  }
}

/// Un enseignant candidat.
class _CarteEnseignant extends StatelessWidget {
  const _CarteEnseignant({
    required this.candidat,
    required this.selectionne,
    required this.onPress,
  });

  final EnseignantCandidat candidat;
  final bool selectionne;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final Creneau? premier = candidat.creneauxCommuns.isEmpty
        ? null
        : candidat.creneauxCommuns.first;

    return AppCard(
      onPress: onPress,
      selectionnee: selectionne,
      libelleSemantique: candidat.libelle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(candidat.libelle, style: textes.titleMedium),
          if (candidat.identiteConnue)
            Text(candidat.identifiantImmuable, style: textes.bodySmall),
          Ecart.vSm,
          Text(
            t.admin.attribution.charge(
              actifs: '${candidat.elevesActifs}',
              plafond: '${candidat.plafond}',
            ),
            style: textes.bodyMedium,
          ),
          Ecart.vSm,
          if (candidat.complet)
            StatusPill(
              libelle: t.admin.attribution.complet,
              ton: TonEtat.avertissement,
            )
          else if (premier == null)
            // L'ecart se dit, il ne se cache pas : c'est lui qui appellera un
            // motif a l'etape suivante.
            StatusPill(
              libelle: t.admin.attribution.sansHeureCommune,
              ton: TonEtat.neutre,
            )
          else
            StatusPill(
              libelle: candidat.creneauxCommuns.length == 1
                  ? t.admin.attribution.libreSur(
                      jour: _jour(premier),
                      heure: '${premier.heure}',
                    )
                  : t.admin.attribution.libreSurPlusieurs(
                      nombre: '${candidat.creneauxCommuns.length}',
                    ),
              ton: TonEtat.succes,
            ),
        ],
      ),
    );
  }
}

/// L'heure, le motif s'il en faut un, puis le geste.
class _Confirmation extends StatelessWidget {
  const _Confirmation({
    required this.eleve,
    required this.enseignant,
    required this.creneauChoisi,
    required this.motif,
    required this.envoi,
    required this.erreur,
    required this.onChoisirCreneau,
    required this.onMotifChange,
    required this.onAttribuer,
  });

  final FoyerEnAttente eleve;
  final EnseignantCandidat enseignant;
  final Creneau? creneauChoisi;
  final TextEditingController motif;
  final bool envoi;
  final String? erreur;
  final void Function(Creneau creneau) onChoisirCreneau;
  final void Function(String motif) onMotifChange;
  final Future<void> Function({
    required FoyerEnAttente eleve,
    required EnseignantCandidat enseignant,
    required Creneau creneau,
  })
  onAttribuer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final List<Creneau> offerts = _ColonneEnseignants.offerts(
      eleve,
      enseignant,
    );
    final bool motifRequis = !enseignant.croise;
    final bool pret =
        creneauChoisi != null && (!motifRequis || motif.text.trim().isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (offerts.length > 1) ...<Widget>[
          Text(t.admin.attribution.quelleHeure, style: textes.titleMedium),
          Ecart.vSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final Creneau creneau in offerts)
                AppCard(
                  marge: AppSpacing.sm,
                  selectionnee: creneau == creneauChoisi,
                  onPress: () => onChoisirCreneau(creneau),
                  child: Text(
                    t.admin.attribution.creneau(
                      jour: _jour(creneau),
                      heure: '${creneau.heure}',
                    ),
                    style: textes.bodyMedium,
                  ),
                ),
            ],
          ),
          Ecart.vLg,
        ],
        if (motifRequis) ...<Widget>[
          Text(
            t.admin.attribution.motifRequis(prenom: enseignant.libelleCourt),
            style: textes.bodySmall,
          ),
          Ecart.vSm,
          TextField(
            controller: motif,
            // Sans ce rappel, le bouton resterait inerte alors que le motif est
            // saisi : piege de l'etape 3, deja paye deux fois.
            onChanged: onMotifChange,
            maxLines: 2,
            decoration: InputDecoration(labelText: t.admin.attribution.motif),
          ),
          Ecart.vLg,
        ],
        ActionPrincipale(
          libelle: t.admin.attribution.attribuer(
            eleve: eleve.libelle,
            enseignant: enseignant.libelleCourt,
          ),
          enCours: envoi,
          onPress: pret
              ? () => unawaited(
                  onAttribuer(
                    eleve: eleve,
                    enseignant: enseignant,
                    creneau: creneauChoisi!,
                  ),
                )
              : null,
        ),
        if (erreur != null) ...<Widget>[
          Ecart.vSm,
          Text(
            erreur!,
            textAlign: TextAlign.center,
            // L'encre d'alerte, jamais la paire : `surfaceAlert` ecrit en blanc,
            // illisible sur la page.
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vSm,
        Text(
          t.admin.attribution.effet,
          textAlign: TextAlign.center,
          style: textes.bodySmall,
        ),
        Ecart.vXs,
        // Rappelee en toutes lettres sous le bouton, comme sur `ADM-02` et
        // `ADM-06`, et pas dans une page d'aide.
        Text(
          t.admin.attribution.journalisation,
          textAlign: TextAlign.center,
          style: textes.bodySmall,
        ),
      ],
    );
  }
}

/// Le nom du jour d'un creneau, dans les mots de la grille de disponibilites.
///
/// **Une seule source pour les sept jours** : deux listes jumelles finiraient
/// par nommer le meme jour de deux facons dans le meme produit.
String _jour(Creneau creneau) =>
    t.disponibilites.joursLongs[(creneau.jour - 1).clamp(0, 6)];

/// Le message metier d'une exception, sans son type.
String _message(Object erreur) {
  final String brut = erreur.toString();
  // Les exceptions Postgrest portent le message metier en clair : c'est lui
  // qu'il faut montrer, pas le type de l'exception.
  final int deuxPoints = brut.indexOf(': ');
  return deuxPoints >= 0 && deuxPoints + 2 < brut.length
      ? brut.substring(deuxPoints + 2)
      : brut;
}
