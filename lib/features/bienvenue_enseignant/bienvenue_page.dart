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
import 'reste_a_configurer.dart';

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
    // UNE seule liste « a configurer », la meme que la carte de la Journee.
    final ListeAConfigurer liste = ref.watch(listeAConfigurerProvider);

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
      // bienvenue n'est pas un cul-de-sac. Quand le profil est lu, elles
      // viennent dans le corps, juste sous « A completer » (garde-cap,
      // 07/11/2026) : l'action se voit sans defiler et ne depend pas de la
      // place d'une zone d'action en bas de page.
      actions: profil.hasValue
          ? null
          : _Sorties(horsLigne: horsLigne, liste: liste, prenom: prenom),
      child: switch (profil) {
        // Les getters, jamais le type d'execution : Riverpod 3 relance un
        // provider en echec tout seul et l'etat repasse par `AsyncLoading` en
        // conservant `hasError`.
        AsyncValue<ProfilEnseignant?>(hasValue: true) => _Corps(
          prenom: prenom,
          liste: liste,
          horsLigne: horsLigne,
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

/// Le corps : un en-tete d'identite, « A completer », les deux mentions.
class _Corps extends StatelessWidget {
  const _Corps({
    required this.prenom,
    required this.liste,
    required this.horsLigne,
  });

  /// L'appareil est hors ligne : les sorties le disent avant le geste.
  final bool horsLigne;

  /// Le prenom, vide quand la lecture ne l'a pas rendu : la bienvenue ne
  /// fabrique pas un nom.
  final String prenom;

  /// Ce qu'il reste a configurer : la source unique des deux ecrans.
  final ListeAConfigurer liste;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle doux = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );

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
        if (liste.restes.isNotEmpty) ...<Widget>[
          Ecart.vSection,
          _ACompleter(liste: liste, prenom: prenom),
        ],
        // L'action, juste sous ce qui reste a configurer (garde-cap, 07/11).
        Ecart.vSection,
        _Sorties(horsLigne: horsLigne, liste: liste, prenom: prenom),
        Ecart.vSection,
        // **Les deux dispositifs de l'ADR-011, nommes en clair**, une ligne
        // chacun. Ils ont deja ete accuses a l'inscription. Le texte est celui
        // de l'accuse E1 valide le 02/10/2026, mot pour mot.
        GroupeReglages(
          titre: t.enseignant.bienvenue.rappels,
          lignes: <LigneRubrique>[
            LigneRubrique(
              icone: AppIcons.micro,
              libelle: t.contrat.a3.quoiTitre,
              legende: t.contrat.e1.quoi,
            ),
            LigneRubrique(
              icone: AppIcons.controleQualite,
              libelle: t.contrat.a3.quiTitre,
              legende: t.contrat.a3.qui,
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
  const _ACompleter({required this.liste, required this.prenom});

  final ListeAConfigurer liste;
  final String prenom;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

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
                  fait: liste.faits,
                  total: liste.lus,
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
            for (final ResteAConfigurer reste in liste.restes)
              LigneRubrique(
                libelle: libelleReste(reste),
                icone: iconeReste(reste),
                onPress: () => allerVersReste(context, reste, prenom: prenom),
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
    required this.liste,
    required this.prenom,
  });

  final bool horsLigne;
  final ListeAConfigurer liste;
  final String prenom;

  @override
  Widget build(BuildContext context) {
    // Le premier a faire porte le bouton ; sans aucune lecture, l'action reste
    // la declaration des disponibilites.
    final ResteAConfigurer? premier = liste.restes.isNotEmpty
        ? liste.restes.first
        : (liste.lus == 0 ? ResteAConfigurer.disponibilites : null);
    final String libelle = switch (premier) {
      ResteAConfigurer.versement =>
        t.comptable.beneficiaires.recevoir.configurer,
      ResteAConfigurer.photo => t.enseignant.bienvenue.ctaPhoto,
      ResteAConfigurer.langues ||
      ResteAConfigurer.fuseau => t.enseignant.bienvenue.ctaInformations,
      ResteAConfigurer.disponibilites => t.enseignant.bienvenue.declarer,
      null => t.enseignant.bienvenue.ctaJournee,
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
            onPress: () => premier == null
                ? GoRouter.of(context).go(Routes.enseignantJournee)
                : allerVersReste(context, premier, prenom: prenom),
          ),
        ),
        if (premier != null) ...<Widget>[
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
