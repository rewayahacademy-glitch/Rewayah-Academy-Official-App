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
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/groupe_reglages.dart';
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
    // Un profil sans role lisible ne se devine ni tuteur ni enseignant : il
    // se dit illisible, avec Reessayer, plutot que de demander une piece.
    final EtatDossier? lu = etat.hasValue && !etat.requireValue.roleIllisible
        ? etat.requireValue
        : null;
    final bool illisible = lu == null && (etat.hasError || etat.hasValue);

    // Les getters, jamais le type d'execution : Riverpod 3 relance un provider
    // en echec tout seul, et l'etat repasse alors par `AsyncLoading` en
    // conservant `hasError`.
    final _Prochaine? prochaine = lu != null
        ? _prochaine(
            lu,
            adulte:
                ref.watch(brouillonInscriptionProvider).usage ==
                UsageInscription.moi,
          )
        : illisible
        ? _Prochaine(
            t.commun.reessayer,
            () => ref.invalidate(etatDossierProvider),
          )
        : null;

    return PageShell(
      // K-47 : un tuteur n'a pas de dossier a faire verifier, seulement un
      // compte a ouvrir.
      titre: lu?.estTuteur ?? false
          ? t.attente.titreCompte
          : t.attente.titreDossier,
      // HL-A-5 : le pied ne garde que Se deconnecter ; la prochaine action
      // se place 16 sous la carte d'etat qu'elle confirme.
      actions: ActionPrincipale(
        libelle: t.attente.seDeconnecter,
        onPress: () => unawaited(ref.read(serviceAuthProvider).deconnexion()),
        niveau: NiveauAction.tertiaire,
      ),
      // AD-NETTOYAGE-2 (m6, m8) : une seule tete (le titre de la page ; la
      // carte d'etat porte le sien) et une colonne bornee comme la politique
      // KYC, sans etirer la carte a 1140 sur bureau.
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppCard(
                child: lu != null
                    ? _Statut(etat: lu)
                    : illisible
                    ? _Illisible(erreur: etat.error ?? const FormatException())
                    : const _Patience(),
              ),
              // HL-A-5 (DESIGN-GOV B) : les actions rattachees a la carte d'etat
              // se placent 16 sous elle, au bord de fin, et non dans le pied ;
              // pleine largeur sur mobile, largeur naturelle au-dela.
              if (prochaine != null) ...<Widget>[
                Ecart.vLg,
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  // IntrinsicWidth au-dela du mobile : le Container centre
                  // d'ActionPrincipale s'etirerait sinon (meme remede que 02B).
                  child: _AuContenu(
                    actif: AppGabarit.de(context) != Gabarit.mobile,
                    child: ActionPrincipale(
                      libelle: prochaine.libelle,
                      onPress: prochaine.chemin != null
                          ? () => routeur?.go(prochaine.chemin!)
                          : prochaine.geste,
                      fleche: prochaine.chemin != null,
                      pleineLargeur: AppGabarit.de(context) == Gabarit.mobile,
                    ),
                  ),
                ),
              ],
              if (lu?.etape
                  case EtapeDossier.enVerification ||
                      EtapeDossier.accesEnPreparation) ...<Widget>[
                Ecart.vLg,
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  // AD-NETTOYAGE-2 (m7) : sans IntrinsicWidth, le Container centre
                  // d'ActionPrincipale s'etire et le bouton se centre.
                  child: _AuContenu(
                    actif: true,
                    child: ActionPrincipale(
                      libelle: lu!.estTuteur
                          ? t.attente.actualiserCompte
                          : t.attente.actualiser,
                      onPress: () => unawaited(_relire()),
                      niveau: NiveauAction.tertiaire,
                      pleineLargeur: false,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Le bouton a sa largeur naturelle quand [actif].
class _AuContenu extends StatelessWidget {
  const _AuContenu({required this.actif, required this.child});

  final bool actif;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      actif ? IntrinsicWidth(child: child) : child;
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
    final TextTheme textes = Theme.of(context).textTheme;

    return switch (etat.etape) {
      EtapeDossier.incomplet => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            etat.estTuteur
                ? t.attente.accordsARelire
                : t.attente.dossierIncomplet,
            style: textes.headlineSmall,
          ),
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
      // K-47 (HL-A-6) : l'etat honnete du tuteur tant que le serveur le fait
      // naitre en attente (BR-1) : ni piece, ni verification, ni delai. Rien
      // n'est promis « en cours » : aucun ecran admin ne l'ouvre avant BR-1,
      // la sortie est de joindre l'academie (comme l'etat suspendu).
      EtapeDossier.accesEnPreparation => _Bloc(
        titre: t.attente.accesTitre,
        message: t.attente.accesEnPreparation,
        detail: <String>[
          t.attente.aucunDocument,
          t.attente.accesContact,
        ].join('\n'),
        icone: AppIcons.foyer,
      ),
      EtapeDossier.refuse => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.attente.refuse, style: textes.headlineSmall),
          Ecart.vMd,
          // La base refuse un verdict negatif sans motif : cette phrase existe
          // toujours quand on arrive ici.
          Text(etat.motifRefus ?? '', style: textes.bodyLarge),
          Ecart.vMd,
          // La phrase suit le premier element a corriger, celui que « Corriger »
          // ouvre (P-ADM-09.2) ; sans element, la sortie est de joindre
          // l'academie (K-47 : seul l'enseignant passe par ce refus).
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
