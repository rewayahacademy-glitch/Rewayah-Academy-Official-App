import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/auth/service_auth.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/page_etape.dart';
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
/// tot (lien direct, rechargement) : jamais d'etape sans ses prealables. Une
/// etape que l'usage retenu n'a pas (le telephone d'un tuteur) renvoie de meme.
void exigerEtapesPrecedentes(
  BuildContext context,
  BrouillonInscription brouillon,
  String route,
) {
  final String manquante = brouillon.premiereEtapeManquante;
  final int rang = rangEtape(route, brouillon.usage);
  if (rang == 0 || rangEtape(manquante, brouillon.usage) < rang) {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (context.mounted) {
        context.go(manquante);
      }
    });
  }
}

/// Va a l'etape suivante de [usage], ou revient au recapitulatif apres
/// « Modifier ».
void avancerDepuis(
  BuildContext context,
  String route, {
  UsageInscription? usage,
}) {
  final bool modifier = GoRouterState.of(context).uri.queryParameters
      .containsKey(parametreModifier);
  final List<String> etapes = etapesPour(usage);
  final int rang = rangEtape(route, usage);
  context.go(
    modifier || rang >= etapes.length
        ? Routes.inscriptionRecapitulatif
        : etapes[rang],
  );
}

/// Revient a l'etape precedente de [usage] (ou au recapitulatif apres
/// « Modifier »).
void reculerDepuis(
  BuildContext context,
  String route, {
  UsageInscription? usage,
}) {
  final bool modifier = GoRouterState.of(context).uri.queryParameters
      .containsKey(parametreModifier);
  final int rang = rangEtape(route, usage);
  context.go(
    modifier ? Routes.inscriptionRecapitulatif : etapesPour(usage)[rang - 2],
  );
}

/// La coquille commune des etapes, posee sur le gabarit partage [PageEtape]
/// (demandes B-3 et A-2) : rangee d'etape (disque retour de 48, progression,
/// « n sur N » calcule par [etapesPour] selon l'usage retenu : quatre etapes
/// pour un tuteur, un eleve adulte ou un comptable, cinq pour un candidat
/// enseignant) sans actions de coquille ; en bas, CTA en pilule, une ligne
/// d'erreur au besoin, et la deconnexion toujours possible.
class CoquilleEtape extends ConsumerWidget {
  /// Cree la coquille d'une etape.
  const CoquilleEtape({
    required this.route,
    required this.question,
    required this.enfant,
    required this.onAction,
    super.key,
    this.libelleAction,
    this.explication,
    this.onRetour,
    this.enCours = false,
    this.souscription,
    this.complement,
    this.choix = false,
  });

  /// Vrai quand l'etape est un choix entre des cartes (usage, genre) : la
  /// colonne large de [PageEtape.colonneLarge], ou les cartes passent en
  /// bento sur grand ecran.
  final bool choix;

  /// La route de l'etape (sert au rang).
  final String route;

  /// La question, en une phrase.
  final String question;

  /// L'explication, quand la question en a besoin.
  final String? explication;

  /// Le corps de l'etape.
  final Widget enfant;

  /// Le libelle du CTA. `null` : l'etape n'a **aucun** bouton plein (un
  /// bouton qui ne peut pas aboutir n'est pas rendu, il n'est pas grise ; la
  /// phrase et les liens de l'etape disent quoi faire).
  final String? libelleAction;

  /// Le CTA ; `null` tant qu'on ne peut pas avancer.
  final VoidCallback? onAction;

  /// Le retour a l'etape precedente ; `null` quand il n'y en a pas (premiere
  /// etape, profil deja cree, envoi en cours). [PageEtape] ne montre alors
  /// aucun disque (demande A-5.1) : la sortie du parcours reste le lien
  /// « Se deconnecter », jamais un retour vers une etape qui recreerait un
  /// profil.
  final VoidCallback? onRetour;

  /// Vrai pendant un envoi.
  final bool enCours;

  /// Une ligne sous le CTA (erreur, precision).
  final Widget? souscription;

  /// Un lien discret sous le CTA (par exemple « J'ai un code d'invitation »).
  final Widget? complement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    void deconnecter() =>
        unawaited(ref.read(serviceAuthProvider).deconnexion());

    final UsageInscription? usage = ref.watch(
      brouillonInscriptionProvider.select((BrouillonInscription b) => b.usage),
    );
    final int total = etapesPour(usage).length;
    return PageEtape(
      numero: rangEtape(route, usage).clamp(1, total),
      total: total,
      onRetour: onRetour,
      colonneLarge: choix,
      action: Column(
        crossAxisAlignment: AppGabarit.de(context) == Gabarit.mobile
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (souscription != null) ...<Widget>[souscription!, Ecart.vMd],
          if (libelleAction case final String libelle)
            ActionPrincipale(
              libelle: libelle,
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
              onPress: deconnecter,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // COUPE-MOTS-4 : « souhaitez-vous » reduit son echelle plutot que
          // de se couper en Interface guidee a 320 px texte x2.
          TexteSansCoupure(
            question,
            style: textes.headlineSmall ?? const TextStyle(),
          ),
          if (explication != null) ...<Widget>[
            Ecart.vSm,
            TexteSansCoupure(
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
