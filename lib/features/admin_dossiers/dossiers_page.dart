import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dossier/service_validation.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/pressable.dart';

/// `ADM-02` : la validation des dossiers.
///
/// **Un dossier a la fois, jamais une grille de vignettes** : la verification
/// d'identite merite une attention sequentielle, pas un balayage rapide.
///
/// **Separation stricte du constat et du jugement** : l'apercu du document en
/// haut, la checklist au milieu, les deux verdicts en bas, dans cet ordre et
/// jamais melanges (`docs/produit/parcours-utilisateurs.md`).
///
/// Le cloisonnement de genre n'est pas applique ici : il vit dans
/// `read_kyc_documents()`, sur laquelle la file et le verdict sont tous deux
/// construits. L'ecran ne peut pas le contourner.
class DossiersPage extends ConsumerStatefulWidget {
  /// Cree l'ecran de validation.
  const DossiersPage({super.key});

  @override
  ConsumerState<DossiersPage> createState() => _DossiersPageState();
}

class _DossiersPageState extends ConsumerState<DossiersPage> {
  final Set<String> _verifie = <String>{};
  final TextEditingController _motif = TextEditingController();
  bool _refusEnCours = false;
  bool _envoi = false;
  String? _erreur;

  /// Les trois constats a poser avant de juger.
  static const List<String> _points = <String>['lisible', 'nom', 'validite'];

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  void _reinitialiser() => setState(() {
    _verifie.clear();
    _motif.clear();
    _refusEnCours = false;
    _erreur = null;
  });

  Future<void> _decider(DossierAValider dossier, {required bool approuve}) async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceValidationProvider)
          .decider(
            documentId: dossier.documentId,
            approuve: approuve,
            motif: approuve ? null : _motif.text.trim(),
          );
      ref.invalidate(dossiersEnAttenteProvider);
      if (mounted) {
        _reinitialiser();
      }
    } on Object {
      if (mounted) {
        setState(() => _erreur = t.dossiers.erreur);
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);
    final AsyncValue<List<DossierAValider>> file = ref.watch(
      dossiersEnAttenteProvider,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const OfflineBanner(),
            Expanded(
              // Les getters, jamais le type d'execution : Riverpod 3 relance un
              // provider en echec tout seul, et l'etat repasse alors par
              // `AsyncLoading` en conservant `hasError`. Un `switch` sur
              // `AsyncError<T>` rate donc l'erreur une fois sur deux.
              child: switch (file) {
                AsyncValue<List<DossierAValider>>(hasValue: true) =>
                  file.requireValue.isEmpty
                      ? EmptyState(
                          message: t.dossiers.aucun,
                          invitation: t.dossiers.aucunDetail,
                          icone: AppIcons.dossiers,
                        )
                      : _Dossier(
                          dossier: file.requireValue.first,
                          restants: file.requireValue.length,
                          verifie: _verifie,
                          motif: _motif,
                          refusEnCours: _refusEnCours,
                          envoi: _envoi,
                          erreur: _erreur,
                          onCocher: (String point) => setState(() {
                            if (!_verifie.remove(point)) {
                              _verifie.add(point);
                            }
                          }),
                          onOuvrirRefus: () =>
                              setState(() => _refusEnCours = true),
                          onMotifChange: (String _) => setState(() {}),
                          onApprouver: () => unawaited(
                            _decider(file.requireValue.first, approuve: true),
                          ),
                          onRefuser: () => unawaited(
                            _decider(file.requireValue.first, approuve: false),
                          ),
                          tousVerifies: _verifie.length == _points.length,
                          points: _points,
                        ),
                AsyncValue<List<DossierAValider>>(hasError: true) =>
                  _Indisponible(
                    genreManquant: file.error is GenreLecteurInconnu,
                    onReessayer: () =>
                        ref.invalidate(dossiersEnAttenteProvider),
                  ),
                _ => Padding(
                  padding: EdgeInsets.all(metriques.marge),
                  child: Center(child: Text(t.commun.chargement)),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Dossier extends StatelessWidget {
  const _Dossier({
    required this.dossier,
    required this.restants,
    required this.verifie,
    required this.motif,
    required this.refusEnCours,
    required this.envoi,
    required this.erreur,
    required this.onCocher,
    required this.onOuvrirRefus,
    required this.onApprouver,
    required this.onRefuser,
    required this.onMotifChange,
    required this.tousVerifies,
    required this.points,
  });

  final DossierAValider dossier;
  final int restants;
  final Set<String> verifie;
  final TextEditingController motif;
  final bool refusEnCours;
  final bool envoi;
  final String? erreur;
  final void Function(String point) onCocher;
  final VoidCallback onOuvrirRefus;
  final VoidCallback onApprouver;
  final VoidCallback onRefuser;
  final void Function(String motif) onMotifChange;
  final bool tousVerifies;
  final List<String> points;

  String _libelle(String point) => switch (point) {
    'lisible' => t.dossiers.pointLisible,
    'nom' => t.dossiers.pointNom,
    _ => t.dossiers.pointValidite,
  };

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return ListView(
      padding: EdgeInsets.all(metriques.marge),
      children: <Widget>[
        Text(t.dossiers.titre, style: textes.headlineSmall),
        Ecart.vSm,
        Text(t.dossiers.restants(n: restants), style: textes.bodySmall),
        Ecart.vXl,

        // 1. LE CONSTAT. L'apercu reste volontairement abstrait : aucune piece
        // d'identite reelle ou vraisemblable n'est representee dans ce depot.
        BentoTile(
          avecBordure: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('${dossier.prenom} ${dossier.nom}', style: textes.titleLarge),
              Text(dossier.identifiantImmuable, style: textes.bodySmall),
              Ecart.vSm,
              Text(
                t.dossiers.deposeLe(date: _jour(dossier.deposeLe)),
                style: textes.bodySmall,
              ),
              Ecart.vLg,
              Text(t.dossiers.apercu, style: textes.bodyMedium),
              Ecart.vSm,
              _Apercu(cleObjet: dossier.cleObjet),
            ],
          ),
        ),
        Ecart.vXxl,

        // 2. LA CHECKLIST, separee du constat comme du jugement.
        Text(t.dossiers.verifications, style: textes.titleMedium),
        Ecart.vMd,
        for (final String point in points)
          _Case(
            libelle: _libelle(point),
            cochee: verifie.contains(point),
            onPress: () => onCocher(point),
          ),
        Ecart.vXxl,

        // 3. LE JUGEMENT, en dernier et jamais melange au reste.
        Text(t.dossiers.verdict, style: textes.titleMedium),
        Ecart.vMd,
        if (refusEnCours) ...<Widget>[
          TextField(
            controller: motif,
            // Le bouton de refus depend de ce champ : sans ce rappel, il
            // resterait inerte alors que le motif est saisi.
            onChanged: onMotifChange,
            maxLines: 2,
            decoration: InputDecoration(labelText: t.dossiers.motif),
          ),
          Ecart.vSm,
          Text(t.dossiers.motifRequis, style: textes.bodySmall),
          Ecart.vMd,
          ActionPrincipale(
            libelle: t.dossiers.refuser,
            enCours: envoi,
            surface: palette.surfaceAlert,
            onPress: motif.text.trim().isEmpty ? null : onRefuser,
          ),
        ] else ...<Widget>[
          ActionPrincipale(
            libelle: t.dossiers.approuver,
            enCours: envoi,
            onPress: tousVerifies ? onApprouver : null,
          ),
          Ecart.vMd,
          ActionPrincipale(
            libelle: t.dossiers.refuser,
            onPress: onOuvrirRefus,
            surface: palette.surfaceCanvas,
          ),
        ],
        if (erreur != null) ...<Widget>[
          Ecart.vMd,
          Text(
            erreur!,
            textAlign: TextAlign.center,
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vLg,
        // Rappelee en toutes lettres sous les boutons de decision, pas dans une
        // page d'aide.
        Text(
          t.dossiers.journalisation,
          textAlign: TextAlign.center,
          style: textes.bodySmall,
        ),
      ],
    );
  }
}

/// L'apercu de la piece.
///
/// L'URL signee est demandee a l'affichage et vit une minute : une URL de piece
/// d'identite qui traine dans un historique de navigateur est une piece
/// d'identite qui traine.
class _Apercu extends ConsumerWidget {
  const _Apercu({required this.cleObjet});

  final String cleObjet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);

    return FutureBuilder<String>(
      future: ref.read(serviceValidationProvider).apercu(cleObjet),
      builder: (BuildContext context, AsyncSnapshot<String> instantane) {
        if (instantane.hasError || instantane.data == null) {
          return Text(
            t.dossiers.apercuIndisponible,
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          child: ColoredBox(
            color: palette.surfaceCanvas.background,
            child: Image.network(
              instantane.data!,
              fit: BoxFit.contain,
              errorBuilder: (BuildContext _, Object _, StackTrace? _) => Text(
                t.dossiers.apercuIndisponible,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Case extends StatelessWidget {
  const _Case({
    required this.libelle,
    required this.cochee,
    required this.onPress,
  });

  final String libelle;
  final bool cochee;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);

    return Pressable(
      onPress: onPress,
      libelleSemantique: libelle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: <Widget>[
            IconTheme(
              data: cochee
                  ? palette.inkAccent.asIconTheme(size: AppSpacing.xxl)
                  : palette.borderStrong.asIconTheme(size: AppSpacing.xxl),
              child: Icon(AppIcons.succes.resoudre(selectionne: cochee)),
            ),
            SizedBox(width: metriques.marge),
            Expanded(
              child: Text(
                libelle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Indisponible extends StatelessWidget {
  const _Indisponible({
    required this.genreManquant,
    required this.onReessayer,
  });

  final bool genreManquant;
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    // La base refuse la lecture quand le genre du lecteur est inconnu, plutot
    // que de rendre la moitie des dossiers en silence. Ce n'est pas une panne :
    // c'est une information manquante que l'administrateur peut fournir.
    return EmptyState(
      message: genreManquant ? t.dossiers.genreManquant : t.dossiers.erreur,
      invitation: genreManquant ? null : t.reseau.horsLigne,
      icone: AppIcons.avertissement,
      libelleAction: genreManquant ? null : t.commun.reessayer,
      onAction: genreManquant ? null : onReessayer,
    );
  }
}

String _jour(DateTime quand) =>
    '${quand.day.toString().padLeft(2, '0')}/'
    '${quand.month.toString().padLeft(2, '0')}/${quand.year}';
