import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/service_auth.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pressable.dart';
import 'brouillon_inscription.dart';
import 'etapes/usage_etape.dart';

/// `TUT-00c` : creer son profil, en pages courtes.
///
/// Atteignable seulement par la porte `inscription`, donc avec une session
/// valide et aucune ligne `profiles`. `/inscription` n'est plus qu'une entree :
/// au depart elle montre directement l'etape d'usage (le routeur y envoie la
/// porte `inscription`, sans qu'on le touche) ; un brouillon deja commence
/// renvoie a la premiere etape sans reponse.
class InscriptionPage extends ConsumerStatefulWidget {
  /// Cree l'entree du parcours d'inscription.
  const InscriptionPage({super.key});

  @override
  ConsumerState<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends ConsumerState<InscriptionPage> {
  @override
  void initState() {
    super.initState();
    final String manquante = ref
        .read(brouillonInscriptionProvider)
        .premiereEtapeManquante;
    if (manquante != Routes.inscriptionUsage) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) {
          context.go(manquante);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => const UsageEtape();
}

/// Renvoie a la premiere etape sans reponse quand une etape est ouverte trop
/// tot (lien direct, rechargement) : jamais d'etape sans ses prealables.
void exigerEtapesPrecedentes(
  BuildContext context,
  BrouillonInscription brouillon,
  String route,
) {
  final String manquante = brouillon.premiereEtapeManquante;
  if (rangEtape(manquante) < rangEtape(route)) {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (context.mounted) {
        context.go(manquante);
      }
    });
  }
}

/// Va a l'etape suivante, ou revient au recapitulatif apres « Modifier ».
void avancerDepuis(BuildContext context, String route) {
  final bool modifier = GoRouterState.of(context).uri.queryParameters
      .containsKey(parametreModifier);
  final int rang = rangEtape(route);
  context.go(
    modifier || rang >= etapesInscription.length
        ? Routes.inscriptionRecapitulatif
        : etapesInscription[rang],
  );
}

/// Revient a l'etape precedente (ou au recapitulatif apres « Modifier »).
void reculerDepuis(BuildContext context, String route) {
  final bool modifier = GoRouterState.of(context).uri.queryParameters
      .containsKey(parametreModifier);
  final int rang = rangEtape(route);
  context.go(
    modifier ? Routes.inscriptionRecapitulatif : etapesInscription[rang - 2],
  );
}

/// La coquille commune des quatre etapes.
///
/// En-tete : disque de retour de 48 dp, « n sur N » calcule depuis
/// [etapesInscription], barre de progression. Bas : CTA en pilule, une ligne
/// d'erreur au besoin, et la deconnexion toujours possible.
class CoquilleEtape extends ConsumerWidget {
  /// Cree la coquille d'une etape.
  const CoquilleEtape({
    required this.route,
    required this.question,
    required this.enfant,
    required this.libelleAction,
    required this.onAction,
    super.key,
    this.explication,
    this.onRetour,
    this.enCours = false,
    this.souscription,
    this.complement,
  });

  /// La route de l'etape (sert au rang).
  final String route;

  /// La question, en une phrase.
  final String question;

  /// L'explication, quand la question en a besoin.
  final String? explication;

  /// Le corps de l'etape.
  final Widget enfant;

  /// Le libelle du CTA.
  final String libelleAction;

  /// Le CTA ; `null` tant qu'on ne peut pas avancer.
  final VoidCallback? onAction;

  /// Le retour ; `null` sur la premiere etape.
  final VoidCallback? onRetour;

  /// Vrai pendant un envoi.
  final bool enCours;

  /// Une ligne sous le CTA (erreur, precision).
  final Widget? souscription;

  /// Un lien discret sous le CTA (par exemple « Je suis enseignant »).
  final Widget? complement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final int numero = rangEtape(route);
    final int total = etapesInscription.length;

    return PageShell(
      entete: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (onRetour != null)
                _DisqueRetour(onPress: onRetour!)
              else
                const SizedBox.square(dimension: AppTouchTarget.standard),
              const Spacer(),
              Flexible(
                child: Text(
                  t.inscription.etapeCourte(n: numero, total: total),
                  textAlign: TextAlign.end,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ),
            ],
          ),
          Ecart.vMd,
          Semantics(
            label: t.inscription.etapeSur(n: numero, total: total),
            child: ClipRRect(
              borderRadius: AppRadius.arrondiFull,
              child: LinearProgressIndicator(
                value: numero / total,
                minHeight: AppSpacing.xs / 2,
                color: palette.surfacePrimary.background,
                backgroundColor: palette.surfaceSunken.background,
              ),
            ),
          ),
        ],
      ),
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (souscription != null) ...<Widget>[souscription!, Ecart.vMd],
          ActionPrincipale(
            libelle: libelleAction,
            onPress: enCours ? null : onAction,
            enCours: enCours,
            pilule: true,
            fleche: true,
          ),
          if (complement != null) ...<Widget>[Ecart.vSm, complement!],
          Ecart.vXs,
          Center(
            child: ActionPrincipale(
              key: const Key('inscription-deconnexion'),
              libelle: t.inscription.seDeconnecter,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              onPress: () =>
                  unawaited(ref.read(serviceAuthProvider).deconnexion()),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(question, style: textes.headlineSmall ?? const TextStyle()),
          if (explication != null) ...<Widget>[
            Ecart.vSm,
            Text(
              explication!,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ],
          Ecart.vXl,
          enfant,
        ],
      ),
    );
  }
}

class _DisqueRetour extends StatelessWidget {
  const _DisqueRetour({required this.onPress});

  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Pressable.selon(
      key: const Key('inscription-retour'),
      onPress: onPress,
      actif: true,
      libelleSemantique: t.inscription.retourEtape,
      respecterCibleTactile: false,
      arrondiFocus: AppRadius.arrondiFull,
      constructeur: (BuildContext contexte, EtatPression etat) =>
          SizedBox.square(
            dimension: AppTouchTarget.standard,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surfaceSunken.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.retour.resoudre(),
                color: palette.surfaceSunken.onBackground,
              ),
            ),
          ),
    );
  }
}

/// Une ligne d'erreur, dite en une phrase et annoncee.
class ErreurEtape extends StatelessWidget {
  /// Cree la ligne.
  const ErreurEtape({required this.message, super.key});

  /// Le message.
  final String message;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: palette.inkAlert.applyTo(
          Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        ),
      ),
    );
  }
}

/// Une carte de choix a radio, avec ou sans description.
///
/// Contournement local au lot A (demande B-3) : `ChoiceCardGroup` ne porte ni
/// description ni option desactivee, et la carte du lot B n'est pas un fichier
/// du lot A. A migrer vers le `ChoiceCardGroup` enrichi promis par COORD.
/// [verticale] donne la carte centree des choix cote a cote (genre).
class CarteChoixInscription extends StatelessWidget {
  /// Cree une carte.
  const CarteChoixInscription({
    required this.icone,
    required this.titre,
    required this.retenue,
    required this.onPress,
    super.key,
    this.description,
    this.verticale = false,
  });

  /// L'icone de la pastille.
  final AppIcon icone;

  /// Le titre.
  final String titre;

  /// La description, facultative.
  final String? description;

  /// Vrai quand la carte est retenue.
  final bool retenue;

  /// Le geste de choix.
  final VoidCallback onPress;

  /// Vrai pour la disposition centree (icone au-dessus du titre).
  final bool verticale;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair pastille = retenue
        ? palette.surfacePrimary
        : palette.surfaceSunken;

    final Widget rond = SizedBox.square(
      dimension: AppTouchTarget.standard,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: pastille.background,
          shape: BoxShape.circle,
        ),
        child: IconTheme(
          data: retenue
              ? IconThemeData(
                  color: pastille.onBackground,
                  size: AppSpacing.xxl,
                )
              : palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
          child: Icon(icone.resoudre(selectionne: retenue)),
        ),
      ),
    );
    final Widget titreTexte = Text(
      titre,
      textAlign: verticale ? TextAlign.center : TextAlign.start,
      style: palette.inkStrong.applyTo(textes.titleMedium ?? const TextStyle()),
    );

    Widget carte(BuildContext contexte, EtatPression etat) {
      final bool survol = etat.survole || etat.presse;
      return DecoratedBox(
        decoration: AppElevation.avecFilet(
          surface: retenue ? palette.washAccent : palette.surfaceRaised,
          filet: retenue
              ? palette.inkAccent
              : survol
              ? palette.borderStrong
              : palette.contourCarte,
          ombre: palette.ombre,
          arrondi: AppRadius.arrondiSm,
          ombres: AppElevation.niveau0,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: verticale
              ? Stack(
                  children: <Widget>[
                    Align(
                      alignment: AlignmentDirectional.topEnd,
                      child: _Radio(retenue: retenue),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Center(child: rond),
                          Ecart.vMd,
                          titreTexte,
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    rond,
                    Ecart.hLg,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          titreTexte,
                          if (description != null) ...<Widget>[
                            Ecart.vXs,
                            Text(
                              description!,
                              style: palette.inkMuted.applyTo(
                                textes.bodyMedium ?? const TextStyle(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Ecart.hMd,
                    _Radio(retenue: retenue),
                  ],
                ),
        ),
      );
    }

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: retenue,
      child: Pressable.selon(
        onPress: onPress,
        actif: true,
        libelleSemantique: description == null ? titre : '$titre. $description',
        respecterCibleTactile: false,
        arrondiFocus: AppRadius.arrondiSm,
        constructeur: carte,
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.retenue});

  final bool retenue;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: AppSpacing.xxl,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              (retenue ? palette.inkAccent : palette.borderStrong).asBorderSide(
                width: 2,
              ),
            ),
          ),
          child: retenue
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.surfacePrimary.background,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
