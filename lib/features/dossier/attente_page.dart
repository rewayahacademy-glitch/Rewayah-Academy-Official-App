import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/service_auth.dart';
import '../../core/domain/enums.dart';
import '../../core/dossier/etat_dossier.dart';
import '../../core/dossier/service_dossier.dart';
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
import '../../core/widgets/skeleton.dart';

/// `TUT-00b` : le portail d'attente.
///
/// **Il ne montre jamais l'application derriere un voile.** Un portail qui
/// laisse deviner ce qu'on rate cree de la frustration ; celui-ci dit ce qui
/// manque et rien d'autre (`docs/produit/parcours-utilisateurs.md`).
///
/// Quatre etats, calcules en base par `etat_dossier()` et non ici : le portail
/// doit dire exactement ce que l'administration voit, et deux calculs finissent
/// toujours par diverger.
class AttentePage extends ConsumerWidget {
  /// Cree le portail d'attente.
  const AttentePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<EtatDossier> etat = ref.watch(etatDossierProvider);

    return PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const MarquePage(),
          Ecart.vXxxl,
          AppCard(
            // Les getters, jamais le type d'execution : Riverpod 3 relance un
            // provider en echec tout seul, et l'etat repasse alors par
            // `AsyncLoading` en conservant `hasError`. Un `switch` sur
            // `AsyncError<T>` rate donc l'erreur une fois sur deux, selon
            // l'instant du rendu.
            child: etat.hasValue
                ? _Contenu(etat: etat.requireValue)
                : etat.hasError
                ? _Indisponible(
                    onReessayer: () => ref.invalidate(etatDossierProvider),
                  )
                : const _Patience(),
          ),
          Ecart.vXxxl,
          _Deconnexion(
            onDeconnexion: () =>
                unawaited(ref.read(serviceAuthProvider).deconnexion()),
          ),
        ],
      ),
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({required this.etat});

  final EtatDossier etat;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    return switch (etat.etape) {
      EtapeDossier.incomplet => _Incomplet(etat: etat),
      EtapeDossier.enVerification => _Bloc(
        titre: t.attente.titre,
        message: t.attente.enVerification,
        detail: <String>[
          if (etat.deposeLe != null)
            t.attente.deposeLe(date: _date(etat.deposeLe!)),
          t.attente.delai,
        ].join('\n'),
        icone: AppIcons.dossiers,
      ),
      EtapeDossier.refuse => _Refuse(etat: etat),
      EtapeDossier.suspendu => _Bloc(
        titre: t.attente.suspendu,
        message: t.attente.suspenduDetail,
        icone: AppIcons.avertissement,
        alerte: true,
        pied: Text(t.attente.contacterAcademie, style: textes.bodyMedium),
      ),
    };
  }
}

/// Etat « dossier incomplet » : deux ou trois elements, chacun avec son bouton.
class _Incomplet extends StatelessWidget {
  const _Incomplet({required this.etat});

  final EtatDossier etat;

  /// Vrai quand seule la piece manque, pour un eleve ou un tuteur : le KYC
  /// des familles est propose, jamais bloquant (contrat du sprint, section
  /// 5.1). Un enseignant n'a pas cette sortie.
  bool get _peutContinuerSansPiece {
    final AppRole? role = etat.role;
    if (role != AppRole.guardian && role != AppRole.student) {
      return false;
    }
    final List<PieceManquante> manquants = etat.manquants;
    return manquants.length == 1 &&
        manquants.single == PieceManquante.pieceIdentite;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.attente.dossierIncomplet, style: textes.headlineSmall),
        Ecart.vXl,
        Text(t.attente.aFournir, style: textes.bodySmall),
        Ecart.vMd,
        for (final PieceManquante manquant in etat.manquants)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _AFournir(manquant: manquant),
          ),
        if (_peutContinuerSansPiece) ...<Widget>[
          Ecart.vSm,
          Text(t.classes.kyc.plusTardDetail, style: textes.bodySmall),
          Ecart.vMd,
          ActionPrincipale(
            libelle: t.classes.kyc.continuerSansPiece,
            niveau: NiveauAction.tertiaire,
            onPress: () =>
                GoRouter.of(context).go(Routes.racinePour(etat.role!)),
          ),
        ],
      ],
    );
  }
}

/// Une ligne « il manque ceci », avec son bouton et rien d'autre.
class _AFournir extends StatelessWidget {
  const _AFournir({required this.manquant});

  final PieceManquante manquant;

  (String, String, String) get _textes => switch (manquant) {
    PieceManquante.accuse => (
      t.attente.carteAccuse,
      t.attente.lireLaCarte,
      Routes.attenteAccuse,
    ),
    PieceManquante.contrat => (
      t.attente.signatureContrat,
      t.attente.signerLeContrat,
      Routes.attenteContrat,
    ),
    PieceManquante.pieceIdentite => (
      t.attente.pieceIdentite,
      t.attente.deposerLaPiece,
      Routes.attentePiece,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (String libelle, String action, String chemin) = _textes;

    return BentoTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(libelle, style: Theme.of(context).textTheme.titleMedium),
          Ecart.vMd,
          ActionPrincipale(
            libelle: action,
            onPress: () => GoRouter.of(context).go(chemin),
          ),
        ],
      ),
    );
  }
}

/// Etat « refuse » : le motif en une phrase, et l'action pour corriger.
class _Refuse extends StatelessWidget {
  const _Refuse({required this.etat});

  final EtatDossier etat;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.attente.refuse, style: textes.headlineSmall),
        Ecart.vMd,
        // La base refuse un verdict negatif sans motif : cette phrase existe
        // toujours quand on arrive ici.
        Text(
          etat.motifRefus ?? '',
          style: palette.inkAlert.applyTo(
            textes.titleMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vXxl,
        ActionPrincipale(
          libelle: t.attente.corriger,
          onPress: () => GoRouter.of(context).go(Routes.attentePiece),
        ),
      ],
    );
  }
}

/// Un etat du portail, en un bloc.
class _Bloc extends StatelessWidget {
  const _Bloc({
    required this.titre,
    required this.message,
    required this.icone,
    this.detail,
    this.pied,
    this.alerte = false,
  });

  final String titre;
  final String message;
  final String? detail;
  final AppIcon icone;
  final Widget? pied;
  final bool alerte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        IconTheme(
          data: alerte
              ? palette.inkAlert.asIconTheme(size: AppSpacing.xxxl * 2)
              : palette.inkAccent.asIconTheme(size: AppSpacing.xxxl * 2),
          child: Icon(icone.repos),
        ),
        Ecart.vXl,
        Text(titre, textAlign: TextAlign.center, style: textes.headlineSmall),
        Ecart.vMd,
        Text(message, textAlign: TextAlign.center, style: textes.bodyMedium),
        if (detail != null) ...<Widget>[
          Ecart.vMd,
          Text(detail!, textAlign: TextAlign.center, style: textes.bodySmall),
        ],
        if (pied != null) ...<Widget>[Ecart.vXxl, pied!],
      ],
    );
  }
}

class _Patience extends StatelessWidget {
  const _Patience();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
    child: Skeleton.liste(lignes: 3),
  );
}

class _Indisponible extends StatelessWidget {
  const _Indisponible({required this.onReessayer});

  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    // Un etat de dossier illisible ne se devine pas : on le dit, et on laisse
    // reessayer. C'est la contrepartie a l'ecran de la regle de session, ou un
    // echec de lecture ferme au lieu d'ouvrir.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t.attente.titre,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Ecart.vXxl,
        ActionPrincipale(libelle: t.commun.reessayer, onPress: onReessayer),
      ],
    );
  }
}

class _Deconnexion extends StatelessWidget {
  const _Deconnexion({required this.onDeconnexion});

  final VoidCallback onDeconnexion;

  @override
  Widget build(BuildContext context) {
    return ActionPrincipale(
      libelle: t.attente.seDeconnecter,
      onPress: onDeconnexion,
      niveau: NiveauAction.secondaire,
    );
  }
}

String _date(DateTime quand) =>
    '${quand.day.toString().padLeft(2, '0')}/'
    '${quand.month.toString().padLeft(2, '0')}/${quand.year}';
