import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/admin/service_diagnostics.dart';
import '../../core/admin/service_programme.dart';
import '../../core/formulaires/motifs_proposes.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/selecteur_motif.dart';
import '../../core/widgets/selecteur_niveau_programme.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';

/// `ADM-10` : Pedagogie > Diagnostics, fonction primaire du domaine.
///
/// **Un eleve a la fois, la meme discipline que `ADM-02`** : decider un
/// placement merite une attention sequentielle, pas une grille. La file vient
/// de `diagnostics_a_traiter()` (migration `0021`) -- calculee, jamais une
/// colonne d'etat a garder synchronisee.
///
/// **Depend du programme publie** (`ADM-13`) : sans version publiee, il n'y a
/// aucun niveau reel sur lequel placer un eleve. L'ecran le dit et oriente
/// vers Programmes plutot que d'inventer un choix.
class DiagnosticsPage extends ConsumerStatefulWidget {
  /// Cree l'ecran des diagnostics.
  const DiagnosticsPage({super.key});

  @override
  ConsumerState<DiagnosticsPage> createState() => _DiagnosticsPageEtat();
}

class _DiagnosticsPageEtat extends ConsumerState<DiagnosticsPage> {
  String? _niveauId;
  final TextEditingController _motif = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  /// Vrai quand le motif manque : il se dit sous les puces (drapeau, jamais
  /// une comparaison de textes).
  bool _motifManquant = false;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  void _reinitialiser() => setState(() {
    _niveauId = null;
    _motif.clear();
    _erreur = null;
    _motifManquant = false;
  });

  Future<void> _decider(String studentId) async {
    final String? niveauId = _niveauId;
    // Bouton jamais grise (K-56) : presse trop tot, il dit ce qui manque.
    if (niveauId == null) {
      setState(() {
        _erreur = t.admin.diagnostics.manqueNiveau;
        _motifManquant = false;
      });
      return;
    }
    if (_motif.text.trim().isEmpty) {
      setState(() {
        _erreur = null;
        _motifManquant = true;
      });
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
      _motifManquant = false;
    });
    try {
      await ref
          .read(serviceDiagnosticsProvider)
          .deciderPlacement(
            studentId: studentId,
            niveauId: niveauId,
            motif: _motif.text.trim(),
          );
      ref.invalidate(diagnosticsATraiterProvider);
      if (mounted) _reinitialiser();
    } catch (erreur) {
      if (mounted) {
        setState(
          () => _erreur = t.admin.diagnostics.deciderErreur(
            message: _message(erreur),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<VersionProgramme?> versionActive = ref.watch(
      versionActiveProgrammeProvider,
    );

    return PageShell(
      titre: t.admin.diagnostics.titre,
      entete: SousNavigationDomaine(onglets: ongletsPedagogie(), indexActif: 0),
      child: switch (versionActive) {
        AsyncValue<VersionProgramme?>(hasValue: true) =>
          versionActive.requireValue == null
              ? EmptyState(
                  message: t.admin.diagnostics.aucunProgramme,
                  invitation: t.admin.diagnostics.aucunProgrammeDetail,
                  icone: AppIcons.rienAAfficher,
                  registre: RegistreVide.subi,
                )
              : _Corps(
                  version: versionActive.requireValue!,
                  niveauId: _niveauId,
                  motif: _motif,
                  envoi: _envoi,
                  erreur: _erreur,
                  motifManquant: _motifManquant,
                  onNiveau: (String id) => setState(() {
                    _niveauId = id;
                    _erreur = null;
                  }),
                  onMotifChange: (String _) => setState(() {
                    _erreur = null;
                    _motifManquant = false;
                  }),
                  onDecider: (String studentId) =>
                      unawaited(_decider(studentId)),
                ),
        AsyncValue<VersionProgramme?>(hasError: true) => EmptyState(
          message: t.admin.diagnostics.erreur,
          icone: AppIcons.avertissement,
          libelleAction: t.commun.reessayer,
          onAction: () => ref.invalidate(versionActiveProgrammeProvider),
        ),
        _ => const Skeleton.liste(lignes: 4),
      },
    );
  }
}

class _Corps extends ConsumerWidget {
  const _Corps({
    required this.version,
    required this.niveauId,
    required this.motif,
    required this.envoi,
    required this.erreur,
    required this.motifManquant,
    required this.onNiveau,
    required this.onMotifChange,
    required this.onDecider,
  });

  final VersionProgramme version;
  final String? niveauId;
  final TextEditingController motif;
  final bool envoi;
  final String? erreur;

  /// Vrai quand le motif manque : il se dit sous les puces.
  final bool motifManquant;
  final void Function(String niveauId) onNiveau;
  final void Function(String motif) onMotifChange;
  final void Function(String studentId) onDecider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<EleveADiagnostiquer>> file = ref.watch(
      diagnosticsATraiterProvider,
    );
    final AsyncValue<List<NiveauProgramme>> niveaux = ref.watch(
      niveauxProgrammeProvider(version.id),
    );

    return switch (file) {
      // Les getters, jamais le type d'execution : meme regle que
      // `admin_dossiers/dossiers_page.dart`.
      AsyncValue<List<EleveADiagnostiquer>>(hasValue: true) =>
        file.requireValue.isEmpty
            ? EmptyState(
                message: t.admin.diagnostics.aucun,
                invitation: t.admin.diagnostics.aucunDetail,
                icone: AppIcons.succes,
                registre: RegistreVide.bonneNouvelle,
              )
            : _Decision(
                eleve: file.requireValue.first,
                restants: file.requireValue.length,
                niveaux: niveaux,
                niveauId: niveauId,
                motif: motif,
                envoi: envoi,
                erreur: erreur,
                motifManquant: motifManquant,
                onNiveau: onNiveau,
                onMotifChange: onMotifChange,
                onDecider: () => onDecider(file.requireValue.first.studentId),
              ),
      AsyncValue<List<EleveADiagnostiquer>>(hasError: true) => EmptyState(
        message: t.admin.diagnostics.erreur,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: () => ref.invalidate(diagnosticsATraiterProvider),
      ),
      _ => const Skeleton.liste(lignes: 4),
    };
  }
}

class _Decision extends StatelessWidget {
  const _Decision({
    required this.eleve,
    required this.restants,
    required this.niveaux,
    required this.niveauId,
    required this.motif,
    required this.envoi,
    required this.erreur,
    required this.motifManquant,
    required this.onNiveau,
    required this.onMotifChange,
    required this.onDecider,
  });

  final EleveADiagnostiquer eleve;
  final int restants;
  final AsyncValue<List<NiveauProgramme>> niveaux;
  final String? niveauId;
  final TextEditingController motif;
  final bool envoi;
  final String? erreur;

  /// Vrai quand le motif manque : il se dit sous les puces.
  final bool motifManquant;
  final void Function(String niveauId) onNiveau;
  final void Function(String motif) onMotifChange;
  final VoidCallback onDecider;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final int jours = eleve.joursDAttente(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          restants == 1
              ? t.admin.diagnostics.restantUn
              : t.admin.diagnostics.restants(n: restants),
          style: textes.bodySmall,
        ),
        Ecart.vXl,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(eleve.libelle, style: textes.titleLarge),
              Text(switch (jours) {
                <= 0 => t.admin.diagnostics.inscritAujourdhui,
                1 => t.admin.diagnostics.inscritDepuisUnJour,
                final int j => LibellesGroupe.insecable(
                  t.admin.diagnostics.inscritDepuis(jours: j),
                ),
              }, style: textes.bodySmall),
            ],
          ),
        ),
        Ecart.vXxl,
        Text(t.admin.diagnostics.champNiveau, style: textes.titleMedium),
        Ecart.vMd,
        switch (niveaux) {
          AsyncValue<List<NiveauProgramme>>(hasValue: true) =>
            SelecteurNiveauProgramme(
              niveaux: niveaux.requireValue,
              selectionne: niveauId,
              onSelectionner: onNiveau,
            ),
          AsyncValue<List<NiveauProgramme>>(hasError: true) => Text(
            t.admin.diagnostics.erreur,
          ),
          _ => const Skeleton.liste(lignes: 2),
        },
        Ecart.vXxl,
        Text(t.admin.diagnostics.champMotif, style: textes.titleMedium),
        Ecart.vSm,
        Text(t.admin.diagnostics.motifRequis, style: textes.bodySmall),
        Ecart.vSm,
        SelecteurMotif(
          motifs: MotifsProposes.placement(),
          controleur: motif,
          libelleChamp: t.admin.diagnostics.champMotif,
          // Le motif manquant se dit sous les puces.
          erreur: motifManquant ? t.formulaire.motif.manque : null,
          onChange: onMotifChange,
        ),
        if (erreur != null) ...<Widget>[
          Ecart.vMd,
          Text(
            erreur!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        Ecart.vLg,
        ActionPrincipale(
          libelle: t.admin.diagnostics.decider,
          enCours: envoi,
          onPress: onDecider,
        ),
      ],
    );
  }
}

String _message(Object erreur) {
  final String brut = erreur.toString();
  final int deuxPoints = brut.indexOf(': ');
  return deuxPoints >= 0 && deuxPoints + 2 < brut.length
      ? brut.substring(deuxPoints + 2)
      : brut;
}
