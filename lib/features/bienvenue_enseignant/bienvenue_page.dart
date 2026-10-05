import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/profil/service_profil_enseignant.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../profil_enseignant/photo_publique.dart';

/// Les quatre prerequis de `ENS-01` (doc 04 section 10.1), tels que le serveur
/// les rendrait : `true` quand l'element est deja confirme.
///
/// **Rien n'est calcule ici (E6).** Avant BR-1, aucun contrat ne les rend :
/// [prerequisEnseignantProvider] vaut `null` et la carte « A completer »
/// n'est pas affichee. La demonstration les fournit.
@immutable
class PrerequisEnseignant {
  /// Cree l'etat des prerequis.
  const PrerequisEnseignant({
    required this.photo,
    required this.langues,
    required this.fuseau,
    required this.disponibilites,
  });

  /// La photo professionnelle est confirmee.
  final bool photo;

  /// Les langues d'enseignement sont verifiees.
  final bool langues;

  /// Le fuseau horaire est verifie.
  final bool fuseau;

  /// Les disponibilites sont declarees.
  final bool disponibilites;

  /// Le nombre d'elements confirmes.
  int get faits => <bool>[
    photo,
    langues,
    fuseau,
    disponibilites,
  ].where((bool f) => f).length;

  /// Le nombre total d'elements.
  static const int total = 4;
}

/// Les prerequis de l'enseignant, `null` tant qu'aucun contrat ne les rend.
final Provider<PrerequisEnseignant?> prerequisEnseignantProvider =
    Provider<PrerequisEnseignant?>((Ref ref) => null);

/// `ENS-01` : les premiers pas, traverses apres validation du dossier.
///
/// **Elle ne porte aucune grille de semaine.** La declaration des
/// disponibilites vit dans `ENS-06` (`Routes.enseignantCreneaux`) et nulle part
/// ailleurs. Elle n'est pas une destination : aucune barre, et ses sorties sont
/// dans la zone d'action collee en bas.
///
/// La carte « A completer » (00_MAQUETTES planche 1, UX_REVIEW_04 ligne
/// ENS-01) montre les quatre prerequis du doc 04 section 10.1 ; une ligne
/// faite garde sa place avec une coche et « Fait ». Le bouton principal porte
/// le premier manque (doc 04 section 10.2).
class BienvenueEnseignantPage extends ConsumerWidget {
  /// Cree l'ecran de bienvenue de l'enseignant.
  const BienvenueEnseignantPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AccountStatus? statut = ref.watch(
      sessionProvider.select((SessionState session) => session.accountStatus),
    );
    final AsyncValue<ProfilEnseignant?> profil = ref.watch(
      profilEnseignantProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final PrerequisEnseignant? prerequis = ref.watch(
      prerequisEnseignantProvider,
    );

    // Un compte qui n'est pas valide ne se fait pas feliciter. On ne devine pas
    // non plus : un statut absent ou illisible n'ouvre pas la bienvenue.
    final bool valide =
        statut == AccountStatus.active ||
        statut == AccountStatus.provisionalActive;

    if (!valide) {
      return PageShell(
        titre: t.enseignant.bienvenue.titre,
        child: EmptyState(
          message: t.enseignant.bienvenue.dossierIncomplet,
          invitation: t.enseignant.bienvenue.dossierIncompletDetail,
          icone: AppIcons.dossiers,
          libelleAction: t.enseignant.bienvenue.versAttente,
          onAction: () => GoRouter.of(context).go(Routes.attente),
        ),
      );
    }

    final String prenom = profil.value?.prenom.trim() ?? '';

    return PageShell(
      titre: t.enseignant.bienvenue.titre,
      // Les sorties survivent a l'echec de la lecture du profil : la
      // bienvenue n'est pas un cul-de-sac.
      actions: _Sorties(
        horsLigne: horsLigne,
        prerequis: prerequis,
        prenom: prenom,
      ),
      child: switch (profil) {
        // Les getters, jamais le type d'execution : Riverpod 3 relance un
        // provider en echec tout seul et l'etat repasse par `AsyncLoading` en
        // conservant `hasError`.
        AsyncValue<ProfilEnseignant?>(hasValue: true) => _Corps(
          prenom: prenom,
          prerequis: prerequis,
        ),
        AsyncValue<ProfilEnseignant?>(hasError: true) => EmptyState(
          message: t.enseignant.bienvenue.erreur,
          icone: AppIcons.avertissement,
          libelleAction: t.commun.reessayer,
          onAction: () => ref.invalidate(profilEnseignantProvider),
        ),
        _ => const Skeleton.liste(lignes: 5),
      },
    );
  }
}

/// Le premier prerequis manquant, dans l'ordre du doc 04 section 10.1.
enum _Manque { photo, informations, disponibilites, aucun }

_Manque _premierManque(PrerequisEnseignant p) {
  if (!p.photo) return _Manque.photo;
  if (!p.langues || !p.fuseau) return _Manque.informations;
  if (!p.disponibilites) return _Manque.disponibilites;
  return _Manque.aucun;
}

void _allerVers(BuildContext context, _Manque manque, String prenom) {
  switch (manque) {
    case _Manque.photo:
      unawaited(ouvrirPhotoPublique(context, prenom: prenom));
    case _Manque.informations:
      GoRouter.of(context).go(Routes.enseignantProfil);
    case _Manque.disponibilites:
      GoRouter.of(context).go(Routes.enseignantCreneaux);
    case _Manque.aucun:
      GoRouter.of(context).go(Routes.enseignantJournee);
  }
}

/// Le corps : un en-tete d'identite, « A completer », les deux mentions.
class _Corps extends StatelessWidget {
  const _Corps({required this.prenom, required this.prerequis});

  /// Le prenom, vide quand la lecture ne l'a pas rendu : la bienvenue ne
  /// fabrique pas un nom.
  final String prenom;

  final PrerequisEnseignant? prerequis;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle doux = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final PrerequisEnseignant? p = prerequis;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // En-tete d'identite sobre (K-42 point 5) : le nom, une ligne de
        // contexte, une pastille discrete.
        // Aucun mot coupe a 320 texte x2 (lecon 8) : « Bienvenue, » ne
        // tient pas en titre a 200 % ; l'echelle se borne juste assez
        // (EA-HL-DOUBLE-1d, vu sur la capture).
        TexteSansCoupure(
          prenom.isEmpty
              ? t.enseignant.bienvenue.salutationSansNom
              : t.enseignant.bienvenue.salutation(prenom: prenom),
          style: textes.headlineSmall,
        ),
        Ecart.vXs,
        Text(t.enseignant.bienvenue.sousTitre, style: doux),
        Ecart.vMd,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: StatusPill(
            libelle: t.enseignant.bienvenue.dossierValide,
            ton: TonEtat.succes,
          ),
        ),
        if (p != null && p.faits < PrerequisEnseignant.total) ...<Widget>[
          Ecart.vSection,
          _ACompleter(prerequis: p, prenom: prenom),
        ],
        Ecart.vSection,
        // **Les deux dispositifs de l'ADR-011, nommes en clair**, une ligne
        // chacun. Ils ont deja ete accuses a l'inscription.
        GroupeReglages(
          titre: t.enseignant.bienvenue.rappels,
          lignes: <LigneRubrique>[
            LigneRubrique(
              icone: AppIcons.micro,
              libelle: t.contrat.pointEnregistrement,
            ),
            LigneRubrique(
              icone: AppIcons.controleQualite,
              libelle: t.contrat.pointControle,
            ),
          ],
        ),
      ],
    );
  }
}

/// La carte groupee « A completer » : compteur en texte, une ligne par
/// prerequis manquant ; une tache deja confirmee n'est pas affichee
/// (spec 04 §10.1).
class _ACompleter extends StatelessWidget {
  const _ACompleter({required this.prerequis, required this.prenom});

  final PrerequisEnseignant prerequis;
  final String prenom;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final PrerequisEnseignant p = prerequis;

    LigneRubrique ligne(String libelle, AppIcon icone, _Manque manque) =>
        LigneRubrique(
          libelle: libelle,
          icone: icone,
          onPress: () => _allerVers(context, manque, prenom),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Le compteur est lu avec le titre (UX_REVIEW_04 ENS-01 a).
        MergeSemantics(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    t.enseignant.bienvenue.aCompleter,
                    style: palette.inkStrong.applyTo(
                      textes.titleMedium ?? const TextStyle(),
                    ),
                  ),
                ),
              ),
              Text(
                t.enseignant.bienvenue.compteur(
                  fait: p.faits,
                  total: PrerequisEnseignant.total,
                ),
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ],
          ),
        ),
        Ecart.vSm,
        GroupeReglages(
          lignes: <LigneRubrique>[
            if (!p.photo)
              ligne(
                t.enseignant.bienvenue.prerequisPhoto,
                AppIcons.image,
                _Manque.photo,
              ),
            if (!p.langues)
              ligne(
                t.enseignant.bienvenue.prerequisLangues,
                AppIcons.cours,
                _Manque.informations,
              ),
            if (!p.fuseau)
              ligne(
                t.enseignant.bienvenue.prerequisFuseau,
                AppIcons.horloge,
                _Manque.informations,
              ),
            if (!p.disponibilites)
              ligne(
                t.enseignant.bienvenue.declarer,
                AppIcons.disponibilites,
                _Manque.disponibilites,
              ),
          ],
        ),
      ],
    );
  }
}

/// Les sorties, collees en bas : le premier manque, puis la journee.
class _Sorties extends StatelessWidget {
  const _Sorties({
    required this.horsLigne,
    required this.prerequis,
    required this.prenom,
  });

  final bool horsLigne;
  final PrerequisEnseignant? prerequis;
  final String prenom;

  @override
  Widget build(BuildContext context) {
    final PrerequisEnseignant? p = prerequis;
    // Sans prerequis connus, l'action reste la declaration des disponibilites.
    final _Manque manque = p == null
        ? _Manque.disponibilites
        : _premierManque(p);
    final String libelle = switch (manque) {
      _Manque.photo => t.enseignant.bienvenue.ctaPhoto,
      _Manque.informations => t.enseignant.bienvenue.ctaInformations,
      _Manque.disponibilites => t.enseignant.bienvenue.declarer,
      _Manque.aucun => t.enseignant.bienvenue.ctaJournee,
    };
    // K-42 (style, regles 2 et 6) : sur bureau, le bouton a sa largeur
    // naturelle, au bord de fin ; pleine largeur sur telephone.
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;
    Widget borne(Widget bouton) => bureau
        ? Align(
            alignment: AlignmentDirectional.centerEnd,
            child: IntrinsicWidth(child: bouton),
          )
        : bouton;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Naviguer aboutit toujours ; POSER un creneau, non. On le dit avant le
        // geste plutot que de laisser la grille echouer apres.
        if (horsLigne) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              t.enseignant.bienvenue.horsLigne,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Ecart.vMd,
        ],
        borne(
          ActionPrincipale(
            libelle: libelle,
            onPress: () => _allerVers(context, manque, prenom),
          ),
        ),
        if (manque != _Manque.aucun) ...<Widget>[
          Ecart.vMd,
          borne(
            ActionPrincipale(
              libelle: t.enseignant.bienvenue.versJournee,
              niveau: NiveauAction.tertiaire,
              onPress: () => GoRouter.of(context).go(Routes.enseignantJournee),
            ),
          ),
        ],
      ],
    );
  }
}
