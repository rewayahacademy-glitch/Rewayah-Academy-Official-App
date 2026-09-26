import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/service_comptes.dart' show EtatPiece;
import '../../core/dossier/service_validation.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/status_pill.dart';

/// La revue actuelle d'un dossier (`ADM-02`), DEPLACEE sans changement de
/// comportement depuis `dossiers_page.dart` (AD-5). Sa refonte (02B) releve
/// d'AD-6 : constat, verifications, verdict, dans cet ordre, sur le service
/// existant (`decider_dossier`).
///
/// **Separation stricte du constat et du jugement** : l'apercu du document en
/// haut, la checklist au milieu, les deux verdicts en bas.
///
/// Le cloisonnement de genre n'est pas applique ici : il vit dans
/// `read_kyc_documents()`, sur laquelle la file et le verdict sont tous deux
/// construits. L'ecran ne peut pas le contourner.
class RevueExistante extends ConsumerStatefulWidget {
  /// Cree la revue d'un dossier. A cle par dossier : changer de dossier
  /// repart de coches vides.
  const RevueExistante({
    required this.dossier,
    required this.onDecision,
    super.key,
  });

  /// Le dossier revu, tel que le service existant le rend.
  final DossierAValider dossier;

  /// Appele apres une decision reussie (la file est deja invalidee).
  final VoidCallback onDecision;

  @override
  ConsumerState<RevueExistante> createState() => _RevueExistanteState();
}

class _RevueExistanteState extends ConsumerState<RevueExistante> {
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

  Future<void> _decider({required bool approuve}) async {
    // Sans piece, il n'y a rien a trancher : l'ecran ne propose alors aucun
    // verdict, et ce garde-fou ferme le chemin si un geste arrive quand meme.
    final String? documentId = widget.dossier.documentId;
    if (documentId == null) {
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceValidationProvider)
          .decider(
            documentId: documentId,
            approuve: approuve,
            motif: approuve ? null : _motif.text.trim(),
          );
      ref.invalidate(dossiersEnAttenteProvider);
      if (mounted) {
        setState(() {
          _verifie.clear();
          _motif.clear();
          _refusEnCours = false;
          _erreur = null;
        });
        widget.onDecision();
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
  Widget build(BuildContext context) => _Dossier(
    dossier: widget.dossier,
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
    onOuvrirRefus: () => setState(() => _refusEnCours = true),
    onMotifChange: (String _) => setState(() {}),
    onApprouver: () => unawaited(_decider(approuve: true)),
    onRefuser: () => unawaited(_decider(approuve: false)),
    tousVerifies: _verifie.length == _points.length,
    points: _points,
  );
}

/// Le genre du lecteur manque : l'etat actuel, sans action (AD-9).
class GenreManquant extends StatelessWidget {
  /// Cree l'etat.
  const GenreManquant({super.key});

  @override
  Widget build(BuildContext context) => EmptyState(
    message: t.dossiers.genreManquant,
    icone: AppIcons.avertissement,
  );
}

class _Dossier extends StatelessWidget {
  const _Dossier({
    required this.dossier,
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
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // Nulle quand aucune piece n'a ete deposee, ou quand la regle de genre
    // interdit de la lire : depuis la migration `0015`, cette file contient des
    // personnes, pas seulement des documents.
    final String? cleObjet = dossier.cleObjet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Le compteur vit desormais dans l'en-tete de la file (AD-5).
        // 1. LE CONSTAT. L'apercu reste volontairement abstrait : aucune piece
        // d'identite reelle ou vraisemblable n'est representee dans ce depot.
        BentoTile(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(dossier.libelle, style: textes.titleLarge),
              // L'identifiant seulement quand le nom est lisible : masque, le
              // libelle **est** deja l'identifiant, et le repeter sous lui
              // n'apprend rien.
              if (dossier.nomConnu)
                Text(dossier.identifiantImmuable, style: textes.bodySmall),
              Ecart.vSm,
              if (cleObjet != null) ...<Widget>[
                Text(
                  t.dossiers.deposeLe(date: _jour(dossier.deposeLe)),
                  style: textes.bodySmall,
                ),
                Ecart.vLg,
                Text(t.dossiers.apercu, style: textes.bodyMedium),
                Ecart.vSm,
                _Apercu(cleObjet: cleObjet),
              ] else ...<Widget>[
                // Faute de depot, il n'y a pas de date de depot a dire : c'est
                // l'anciennete de l'inscription qui mesure l'attente, et c'est
                // justement cette personne qui attend le plus longtemps.
                Text(switch (dossier.joursDAttente(DateTime.now())) {
                  <= 0 => t.dossiers.inscritAujourdhui,
                  1 => t.dossiers.inscritDepuisUnJour,
                  final int jours => t.dossiers.inscritDepuis(jours: '$jours'),
                }, style: textes.bodySmall),
                Ecart.vMd,
                StatusPill(
                  libelle: dossier.etatPiece == EtatPiece.nonVisible
                      ? t.dossiers.pieceNonVisible
                      : t.dossiers.sansPiece,
                  ton: TonEtat.avertissement,
                ),
              ],
            ],
          ),
        ),
        Ecart.vXxl,

        if (!dossier.jugeable) ...<Widget>[
          // **Rien a constater, donc rien a trancher.** Afficher la checklist
          // et deux verdicts sur un dossier sans piece proposerait un geste
          // qui echouerait en base. L'ecran dit ce qui manque et chez qui se
          // trouve le geste -- c'est le meme choix que la carte « aucune heure
          // proposee » d'`ADM-05`.
          Text(t.dossiers.rienATrancher, style: textes.titleMedium),
          Ecart.vMd,
          Text(
            dossier.etatPiece == EtatPiece.nonVisible
                ? t.dossiers.pieceNonVisibleDetail
                : t.dossiers.sansPieceDetail,
            style: textes.bodyMedium,
          ),
        ] else ...<Widget>[
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
              niveau: NiveauAction.destructive,
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
              niveau: NiveauAction.secondaire,
            ),
          ],
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

String _jour(DateTime quand) =>
    '${quand.day.toString().padLeft(2, '0')}/'
    '${quand.month.toString().padLeft(2, '0')}/${quand.year}';
