import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/chemin_retour.dart';
import '../../core/router/routes.dart';
import '../../core/tc_bibliotheque/couverture_ressource.dart';
import '../../core/tc_bibliotheque/donnees_catalogue.dart';
import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/tc_telechargement/download_asset.dart';
import '../../core/tc_telechargement/port_enregistrement_fichier.dart';
import '../../core/tc_telechargement/port_etat_offline.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import 'carte_ressource.dart';
import 'libelles_bibliotheque.dart';
import 'rendu_ressource.dart';
import 'vignette_ressource.dart';

/// Le detail minimal d'une ressource.
///
/// « Minimal » au sens de la spec : ce qu'il faut pour savoir ce qu'est le
/// support, s'il est disponible hors ligne, et pour en enregistrer une copie.
/// **Pas de rendu du contenu** : aucun moteur PDF n'est present dans
/// `pubspec.yaml`, et le Coran appartient au moteur d'Agent C. L'ecran le dit
/// au lieu de faire semblant.
class DetailRessourcePage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const DetailRessourcePage({required this.resourceId, super.key});

  /// La ressource affichee.
  final String resourceId;

  @override
  ConsumerState<DetailRessourcePage> createState() => _DetailEtat();
}

class _DetailEtat extends ConsumerState<DetailRessourcePage> {
  String? _message;
  bool _enCours = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<DetailRessource?> detail = ref.watch(
      detailRessourceProvider(widget.resourceId),
    );

    return PageShell(
      titre: t.tc.bibliotheque.detail.titre,
      onRetour: _retour(context),
      child: switch (detail) {
        AsyncValue<DetailRessource?>(hasValue: true) =>
          detail.requireValue == null
              // L'appelant ne voit pas cette ressource. La barriere est
              // serveur ; l'ecran ne fait que l'expliquer sans accuser la
              // personne d'avoir mal fait.
              ? EmptyState(
                  message: t.tc.bibliotheque.introuvable.message,
                  invitation: t.tc.bibliotheque.introuvable.invitation,
                  registre: RegistreVide.subi,
                )
              : _Corps(
                  detail: detail.requireValue!,
                  message: _message,
                  enCours: _enCours,
                  onTelecharger: _telecharger,
                  onLiberer: _liberer,
                  onEnregistrerCopie: _enregistrerCopie,
                ),
        AsyncValue<DetailRessource?>(hasError: true) => EmptyState(
          message: t.tc.bibliotheque.indisponible.message,
          invitation: t.tc.bibliotheque.indisponible.invitation,
          icone: AppIcons.avertissement,
          libelleAction: t.tc.bibliotheque.indisponible.action,
          onAction: () =>
              ref.invalidate(detailRessourceProvider(widget.resourceId)),
        ),
        _ => const Skeleton.texte(lignes: 6),
      },
    );
  }

  /// Le disque retour : d'abord le chemin `?retour=` de l'adresse (la
  /// bibliotheque d'une classe, cote tuteur), **valide comme chemin interne**
  /// (`cheminRetourValide`) ; sinon l'ecran d'en dessous (la Bibliotheque,
  /// route parente, cote eleve). Sans l'un ni l'autre (lien profond,
  /// rechargement hors de la classe) : la Bibliotheque elle-meme, jamais une
  /// impasse (revue C, m5).
  VoidCallback? _retour(BuildContext context) {
    final GoRouter? routeur = GoRouter.maybeOf(context);
    if (routeur == null) {
      return null;
    }
    final String? retour = cheminRetourValide(
      GoRouterState.of(context).uri.queryParameters['retour'],
    );
    if (retour != null) {
      return () => routeur.go(retour);
    }
    return routeur.canPop()
        ? routeur.pop
        : () => routeur.go(Routes.tcBibliotheque);
  }

  Future<void> _telecharger() async {
    setState(() => _enCours = true);
    try {
      await ref
          .read(portEtatOfflineProvider)
          .demanderTelechargement(widget.resourceId);
    } on EchecTelechargementRessource {
      // L'echec est nomme et montre. Le taire laisserait la personne relancer
      // indefiniment un geste qui ne peut pas aboutir.
      if (mounted) {
        setState(
          () => _message = t.tc.bibliotheque.message.telechargementImpossible,
        );
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
      ref.invalidate(detailRessourceProvider(widget.resourceId));
    }
  }

  Future<void> _liberer() async {
    await ref.read(portEtatOfflineProvider).libererCache(widget.resourceId);
    ref.invalidate(detailRessourceProvider(widget.resourceId));
  }

  /// « Enregistrer une copie », par le selecteur de fichiers du systeme.
  ///
  /// Trois etapes, et chacune peut echouer proprement : l'artefact existe ou
  /// non, ses octets sont obtenables ou non, la personne choisit une
  /// destination ou renonce. **Une renonciation ne produit aucun message** :
  /// elle n'est pas une erreur.
  Future<void> _enregistrerCopie(DetailRessource detail) async {
    final DownloadAsset? asset = detail.artefactPdf;
    if (asset == null) return;

    setState(() => _enCours = true);
    try {
      final List<int>? octets = await ref
          .read(lecteurArtefactProvider)
          .octets(asset);
      if (octets == null) {
        if (mounted) {
          setState(() => _message = t.tc.bibliotheque.message.copieImpossible);
        }
        return;
      }
      final String? destination = await ref
          .read(portEnregistrementFichierProvider)
          .enregistrerCopie(
            octets: octets,
            nomFichierPropose: nomFichierPropose(
              detail.ressource.title,
              asset.format,
            ),
            typeMime: asset.format.typeMime,
          );
      if (mounted && destination != null) {
        setState(() => _message = t.tc.bibliotheque.message.copieEnregistree);
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }
}

/// Le corps de la fiche.
class _Corps extends StatelessWidget {
  const _Corps({
    required this.detail,
    required this.message,
    required this.enCours,
    required this.onTelecharger,
    required this.onLiberer,
    required this.onEnregistrerCopie,
  });

  final DetailRessource detail;
  final String? message;
  final bool enCours;
  final Future<void> Function() onTelecharger;
  final Future<void> Function() onLiberer;
  final Future<void> Function(DetailRessource detail) onEnregistrerCopie;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final LibraryResource r = detail.ressource;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          dominante: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: CarteRessource.largeurVignettePour(context),
                child: VignetteRessource(
                  couverture: CouvertureRessource.pour(r),
                ),
              ),
              Ecart.hLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      r.title,
                      // Le titre de la ressource : un cran sous le titre d'ecran
                      // de la page (HIER-1), jamais a la meme taille.
                      style: palette.surfaceRaised.applyTo(
                        textes.titleLarge ?? const TextStyle(),
                      ),
                    ),
                    Ecart.vXs,
                    Text(
                      _sousTitre(r),
                      style: palette.inkMuted.applyTo(
                        textes.bodySmall ?? const TextStyle(),
                      ),
                    ),
                    Ecart.vSm,
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: StatusPill(
                        libelle: libelleOffline(detail.etatOffline),
                        ton: CarteRessource.tonDe(detail.etatOffline),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Ecart.vXl,
        RenduRessource(detail: detail),
        if (r.levelScope.isNotEmpty) ...<Widget>[
          Ecart.vSection,
          SectionHeader(titre: t.tc.bibliotheque.detail.niveaux),
          Ecart.vSm,
          Text(r.levelScope.join(' · '), style: textes.bodyMedium),
        ],
        if (r.capabilities.isNotEmpty) ...<Widget>[
          Ecart.vSection,
          SectionHeader(
            titre: t.tc.bibliotheque.detail.capacites,
            compteur: r.capabilities.length,
          ),
          Ecart.vSm,
          Text(
            r.capabilities
                .map((CapaciteRessource c) => c.valeurSql)
                .join(' · '),
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vSection,
        ..._actions(context),
        Ecart.vLg,
        LocalFeedback(message: message),
      ],
    );
  }

  /// Les actions reellement possibles.
  ///
  /// **Un bouton qui ne peut pas aboutir n'est pas rendu, il n'est pas
  /// grise** : la limite s'explique par une phrase a la place du bouton
  /// (`lib/CLAUDE.md`, rappels de l'etape 3).
  List<Widget> _actions(BuildContext context) {
    final List<Widget> sortie = <Widget>[];

    switch (detail.etatOffline) {
      case EtatOffline.aTelecharger:
        sortie.add(
          ActionPrincipale(
            libelle: t.tc.bibliotheque.action.telecharger,
            niveau: NiveauAction.secondaire,
            enCours: enCours,
            onPress: onTelecharger,
          ),
        );
      case EtatOffline.telecharge || EtatOffline.enCache:
        sortie.add(
          ActionPrincipale(
            libelle: t.tc.bibliotheque.action.liberer,
            niveau: NiveauAction.tertiaire,
            onPress: onLiberer,
          ),
        );
      case EtatOffline.enCours:
        sortie.add(
          ActionPrincipale(
            libelle: t.tc.bibliotheque.offline.enCours,
            niveau: NiveauAction.secondaire,
            enCours: true,
            // Un telechargement en cours n'est pas une action : le bouton
            // porte l'etat, il ne le relance pas.
            onPress: null,
          ),
        );
      case EtatOffline.indisponible:
        break;
    }

    sortie.add(Ecart.vMd);
    if (detail.copiePossible) {
      sortie.add(
        ActionPrincipale(
          libelle: t.tc.bibliotheque.action.enregistrerCopie,
          enCours: enCours,
          onPress: () => onEnregistrerCopie(detail),
        ),
      );
    } else {
      final AppPalette palette = AppPalette.of(context);
      sortie.add(
        Text(
          t.tc.bibliotheque.message.aucunTelechargement,
          style: palette.inkMuted.applyTo(
            Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
          ),
        ),
      );
    }
    return sortie;
  }

  static String _sousTitre(LibraryResource r) => <String>[
    libelleTypeRessource(r.resourceType),
    if (r.category.isNotEmpty) r.category,
    if (r.edition != null) r.edition!,
    r.language,
  ].join(' · ');
}
