import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/service_auth.dart';
import '../../core/dossier/etat_dossier.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/marque_page.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../connexion/recuperation_page.dart'
    show IssueEnvoiLien, issueEchecEnvoi;
import '../inscription/brouillon_inscription.dart';

/// `TUT-00b` : le portail d'attente, refondu (05 section A, sous-paquet 3).
///
/// **Le statut exact et UNE prochaine action**, jamais des cartes empilees ni
/// plusieurs boutons pleins : les pieces manquantes sont listees en une carte
/// groupee, sans bouton par ligne, et la seule action pleine ouvre la premiere
/// d'entre elles. La deconnexion reste toujours possible, en action discrete.
///
/// Quatre etats, calcules en base par `etat_dossier()` et non ici : le portail
/// doit dire exactement ce que l'administration voit, et deux calculs finissent
/// toujours par diverger.
class AttentePage extends ConsumerStatefulWidget {
  /// Cree le portail d'attente.
  const AttentePage({super.key});

  @override
  ConsumerState<AttentePage> createState() => _AttentePageState();
}

class _AttentePageState extends ConsumerState<AttentePage> {
  /// Relit l'etat au retour dans l'application (P-ADM-11.1) : aucun signal
  /// serveur n'existe (AD-BR-26), la relecture est le seul moyen honnete de
  /// voir une decision prise pendant l'absence.
  late final AppLifecycleListener _cycle;

  @override
  void initState() {
    super.initState();
    _cycle = AppLifecycleListener(onResume: () => unawaited(_relire()));
  }

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }

  /// Relit le dossier puis la session : un compte devenu actif est alors
  /// redirige par la garde existante vers la racine de son role.
  Future<void> _relire() async {
    ref.invalidate(etatDossierProvider);
    await ref.read(sourceSessionProvider).rafraichir();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<EtatDossier> etat = ref.watch(etatDossierProvider);
    final GoRouter? routeur = GoRouter.maybeOf(context);

    // Les getters, jamais le type d'execution : Riverpod 3 relance un provider
    // en echec tout seul, et l'etat repasse alors par `AsyncLoading` en
    // conservant `hasError`.
    final _Prochaine? prochaine = etat.hasValue
        ? _prochaine(
            etat.requireValue,
            adulte:
                ref.watch(brouillonInscriptionProvider).usage ==
                UsageInscription.moi,
          )
        : etat.hasError
        ? _Prochaine(
            t.commun.reessayer,
            () => ref.invalidate(etatDossierProvider),
          )
        : null;

    return PageShell(
      titre: t.attente.titreDossier,
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (prochaine != null) ...<Widget>[
            ActionPrincipale(
              libelle: prochaine.libelle,
              onPress: prochaine.chemin != null
                  ? () => routeur?.go(prochaine.chemin!)
                  : prochaine.geste,
              fleche: prochaine.chemin != null,
            ),
            Ecart.vMd,
          ],
          ActionPrincipale(
            libelle: t.attente.seDeconnecter,
            onPress: () =>
                unawaited(ref.read(serviceAuthProvider).deconnexion()),
            niveau: NiveauAction.tertiaire,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const MarquePage(),
          Ecart.vXxl,
          AppCard(
            child: etat.hasValue
                ? _Statut(etat: etat.requireValue)
                : etat.hasError
                ? _Illisible(erreur: etat.error!)
                : const _Patience(),
          ),
          // HL-A-5 (DESIGN-GOV B) : l'action rattachee a la carte d'etat se
          // place 16 sous elle, au bord de fin, et non dans le pied.
          if (etat.value?.etape == EtapeDossier.enVerification) ...<Widget>[
            Ecart.vLg,
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: ActionPrincipale(
                libelle: t.attente.actualiser,
                onPress: () => unawaited(_relire()),
                niveau: NiveauAction.tertiaire,
                pleineLargeur: false,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// La prochaine action : une route, ou un geste (reessayer).
class _Prochaine {
  const _Prochaine(this.libelle, this.geste) : chemin = null;
  const _Prochaine.vers(this.libelle, String this.chemin) : geste = null;

  final String libelle;
  final String? chemin;
  final VoidCallback? geste;
}

/// `adulte` : l'inscription vient de « Moi uniquement » (eleve adulte, son
/// propre tuteur) ; le contrat s'ouvre alors en variante eleve adulte
/// (`?pour=moi`). Sans brouillon (rechargement), variante responsable legal.
_Prochaine? _prochaine(EtatDossier etat, {required bool adulte}) =>
    switch (etat.etape) {
      EtapeDossier.incomplet when etat.manquants.isNotEmpty => _Prochaine.vers(
        _action(etat.manquants.first),
        _chemin(etat.manquants.first, adulte: adulte),
      ),
      // « Corriger » mene au premier element a corriger (P-ADM-09.2) : la piece
      // refusee figure dans manquants, apres l'accuse et le contrat.
      EtapeDossier.refuse
          when etat.correctionAutorisee != false && etat.manquants.isNotEmpty =>
        _Prochaine.vers(
          t.attente.corriger,
          _chemin(etat.manquants.first, adulte: adulte),
        ),
      _ => null,
    };

String _libelle(PieceManquante piece) => switch (piece) {
  PieceManquante.accuse => t.attente.carteAccuse,
  PieceManquante.contrat => t.attente.signatureContrat,
  PieceManquante.pieceIdentite => t.attente.pieceIdentite,
};

String _action(PieceManquante piece) => switch (piece) {
  PieceManquante.accuse => t.attente.lireLaCarte,
  PieceManquante.contrat => t.attente.signerLeContrat,
  PieceManquante.pieceIdentite => t.attente.deposerLaPiece,
};

String _chemin(PieceManquante piece, {required bool adulte}) => switch (piece) {
  PieceManquante.accuse => Routes.attenteAccuse,
  PieceManquante.contrat =>
    adulte ? '${Routes.attenteContrat}?pour=moi' : Routes.attenteContrat,
  PieceManquante.pieceIdentite => Routes.attentePiece,
};

AppIcon _icone(PieceManquante piece) => switch (piece) {
  PieceManquante.accuse => AppIcons.controleQualite,
  PieceManquante.contrat => AppIcons.cahier,
  PieceManquante.pieceIdentite => AppIcons.dossiers,
};

class _Statut extends StatelessWidget {
  const _Statut({required this.etat});

  final EtatDossier etat;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return switch (etat.etape) {
      EtapeDossier.incomplet => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.attente.dossierIncomplet, style: textes.headlineSmall),
          Ecart.vMd,
          Text(
            t.attente.reste(n: etat.manquants.length),
            style: textes.bodyMedium,
          ),
          if (etat.manquants.isNotEmpty) ...<Widget>[
            Ecart.vXl,
            GroupeReglages(
              titre: t.attente.aFournir,
              lignes: <LigneRubrique>[
                for (final PieceManquante manquant in etat.manquants)
                  LigneRubrique(
                    icone: _icone(manquant),
                    libelle: _libelle(manquant),
                    valeur: t.attente.etatAFournir,
                  ),
              ],
            ),
            Ecart.vXl,
            Text(
              t.attente.prochaineEtape(etape: _libelle(etat.manquants.first)),
              style: textes.titleMedium,
            ),
          ],
        ],
      ),
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
      EtapeDossier.refuse => Column(
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
          Ecart.vMd,
          // La phrase suit le premier element a corriger, celui que « Corriger »
          // ouvre (P-ADM-09.2) ; sans element (famille dispensee), aucune
          // piece n'est demandee (P-ADM-08.3).
          Text(
            etat.correctionAutorisee == false
                ? t.attente.correctionImpossible
                : etat.manquants.isEmpty
                ? t.attente.refuseSansElement
                : t.attente.refuseDetail(
                    element: _libelle(etat.manquants.first),
                  ),
            style: textes.bodyMedium,
          ),
        ],
      ),
      EtapeDossier.suspendu => _Bloc(
        titre: t.attente.suspendu,
        message: t.attente.suspenduDetail,
        icone: AppIcons.avertissement,
        alerte: true,
        detail: t.attente.contacterAcademie,
      ),
    };
  }
}

/// Un etat sans action, en un bloc centre.
class _Bloc extends StatelessWidget {
  const _Bloc({
    required this.titre,
    required this.message,
    required this.icone,
    this.detail,
    this.alerte = false,
  });

  final String titre;
  final String message;
  final String? detail;
  final AppIcon icone;
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

/// Un etat de dossier illisible ne se devine pas : on le dit (hors ligne ou
/// non), et l'unique action est de reessayer.
class _Illisible extends StatelessWidget {
  const _Illisible({required this.erreur});

  final Object erreur;

  @override
  Widget build(BuildContext context) {
    final bool horsLigne = issueEchecEnvoi(erreur) == IssueEnvoiLien.horsLigne;
    return Semantics(
      liveRegion: true,
      child: Text(
        horsLigne ? t.attente.horsLigne : t.attente.illisible,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

String _date(DateTime quand) =>
    '${quand.day.toString().padLeft(2, '0')}/'
    '${quand.month.toString().padLeft(2, '0')}/${quand.year}';
