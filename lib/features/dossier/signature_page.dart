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
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/marque_page.dart';
import '../../core/widgets/page_shell.dart';

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
class ContratPage extends ConsumerWidget {
  /// Cree la page de contrat.
  const ContratPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<EtatDossier> etat = ref.watch(etatDossierProvider);
    final AppRole role = etat.value?.role ?? AppRole.guardian;

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
    );
  }
}

/// La coquille commune : des points en clair, un bouton, rien d'autre.
class _PageASigner extends ConsumerStatefulWidget {
  const _PageASigner({
    required this.titre,
    required this.libelleAction,
    required this.sorte,
    required this.points,
    this.introduction,
  });

  final String titre;
  final String? introduction;
  final String libelleAction;
  final SorteContrat sorte;
  final List<String> points;

  @override
  ConsumerState<_PageASigner> createState() => _PageASignerState();
}

class _PageASignerState extends ConsumerState<_PageASigner> {
  bool _envoi = false;
  String? _erreur;

  Future<void> _signer() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceDossierProvider)
          .accepterContrat(widget.sorte, VersionsContrat.courante);
      ref.invalidate(etatDossierProvider);
      if (mounted) {
        GoRouter.of(context).go(Routes.attente);
      }
    } on Object {
      if (mounted) {
        setState(() => _erreur = t.contrat.erreur);
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

    return PageShell(
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
            onPress: () => unawaited(_signer()),
            enCours: _envoi,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const MarquePage(),
          Ecart.vXxxl,
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(widget.titre, style: textes.headlineSmall),
                if (widget.introduction != null) ...<Widget>[
                  Ecart.vMd,
                  Text(widget.introduction!, style: textes.bodyMedium),
                ],
                Ecart.vXxl,
                for (final String point in widget.points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: BentoTile(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          IconTheme(
                            data: palette.inkAccent.asIconTheme(
                              size: AppSpacing.xxl,
                            ),
                            child: Icon(AppIcons.controleQualite.repos),
                          ),
                          Ecart.hMd,
                          Expanded(
                            child: Text(point, style: textes.bodyLarge),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
