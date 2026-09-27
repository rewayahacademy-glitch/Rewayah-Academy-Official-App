import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/dossier/etat_dossier.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/dossier/versions_contrat.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../connexion/recuperation_page.dart'
    show IssueEnvoiLien, issueEchecEnvoi;
import '../consentements/texte_observation.dart';

/// La carte a accuser une fois (ADR-011).
///
/// **Elle vient avant le contrat, pas apres.** Les deux dispositifs qu'elle
/// nomme, l'enregistrement audio et la visite de controle, figurent aussi dans
/// le contrat ; mais une clause signee au milieu d'un texte long n'informe
/// personne, et « un enseignant qui decouvre le dispositif apres coup est un
/// litige » (ADR-011). Cette carte est courte pour etre lue.
class AccusePage extends ConsumerWidget {
  /// Cree la carte d'accuse.
  const AccusePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PageASigner(
      titre: t.accuse.titre,
      libelleAction: t.accuse.compris,
      sorte: SorteContrat.accuseEnregistrementControle,
      points: <String>[t.contrat.pointEnregistrement, t.contrat.pointControle],
    );
  }
}

/// Le contrat propre au role : conditions du tuteur, ou non-concurrence de
/// l'enseignant.
///
/// Pour le tuteur, la version signee est celle qui ajoute le paragraphe des
/// visites d'observation (03 section 1 bis-2 et 3) au texte existant, notice
/// d'enregistrement comprise ; la case d'accord n'est jamais precochee.
/// `?pour=moi` donne la variante eleve adulte.
class ContratPage extends ConsumerWidget {
  /// Cree la page de contrat.
  const ContratPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<EtatDossier> etat = ref.watch(etatDossierProvider);
    final AppRole role = etat.value?.role ?? AppRole.guardian;
    String? pour;
    try {
      pour = GoRouterState.of(context).uri.queryParameters['pour'];
    } on Object {
      pour = null;
    }

    return _PageASigner(
      titre: t.contrat.titre,
      introduction: t.contrat.intro,
      libelleAction: t.contrat.accepter,
      sorte: SorteContrat.pour(role),
      points: <String>[
        t.contrat.pointEnregistrement,
        t.contrat.pointControle,
        // L'occultation des coordonnees ne concerne que l'enseignant : c'est ce
        // qu'il accepte, et c'est aussi le controle anti-pillage central de
        // l'ADR-008.
        if (role == AppRole.teacher) t.contrat.pointCoordonnees,
      ],
      observation: role == AppRole.teacher
          ? null
          : VarianteObservation.depuisParametre(pour),
    );
  }
}

/// La coquille commune : des points en clair dans UNE carte groupee, un
/// bouton, rien d'autre.
class _PageASigner extends ConsumerStatefulWidget {
  const _PageASigner({
    required this.titre,
    required this.libelleAction,
    required this.sorte,
    required this.points,
    this.introduction,
    this.observation,
  });

  final String titre;
  final String? introduction;
  final String libelleAction;
  final SorteContrat sorte;
  final List<String> points;

  /// Avec une variante, le paragraphe des visites d'observation et sa case.
  final VarianteObservation? observation;

  @override
  ConsumerState<_PageASigner> createState() => _PageASignerState();
}

class _PageASignerState extends ConsumerState<_PageASigner> {
  bool _envoi = false;
  bool _cochee = false;
  String? _erreur;

  bool get _signable => widget.observation == null || _cochee;

  Future<void> _signer() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceDossierProvider)
          .accepterContrat(widget.sorte, VersionsContrat.pour(widget.sorte));
      ref.invalidate(etatDossierProvider);
      if (mounted) {
        GoRouter.of(context).go(Routes.attente);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(
          () => _erreur = issueEchecEnvoi(e) == IssueEnvoiLien.horsLigne
              ? t.contrat.horsLigne
              : t.contrat.erreur,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final VarianteObservation? observation = widget.observation;

    return PageShell(
      titre: widget.titre,
      onRetour: () => GoRouter.of(context).go(Routes.attente),
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_erreur != null) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                _erreur!,
                textAlign: TextAlign.center,
                style: palette.inkAlert.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vMd,
          ],
          ActionPrincipale(
            libelle: widget.libelleAction,
            onPress: _signable ? () => unawaited(_signer()) : null,
            enCours: _envoi,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (widget.introduction != null) ...<Widget>[
            Text(widget.introduction!, style: textes.bodyMedium),
            Ecart.vXl,
          ],
          GroupeReglages(
            lignes: <LigneRubrique>[
              for (final String point in widget.points)
                LigneRubrique(icone: AppIcons.controleQualite, libelle: point),
            ],
          ),
          if (observation != null) ...<Widget>[
            Ecart.vXxl,
            Text(t.consentement.texte.titre, style: textes.titleMedium),
            Ecart.vMd,
            TexteObservation(variante: observation),
            Ecart.vXl,
            CaseAccordObservation(
              variante: observation,
              cochee: _cochee,
              onChanged: _envoi
                  ? null
                  : (bool v) => setState(() => _cochee = v),
            ),
          ],
        ],
      ),
    );
  }
}
