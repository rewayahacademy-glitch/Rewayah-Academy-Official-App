// L'Administration des communications (COM-W04 ; spec section 13.4,
// section 17, section 20, section 5.5).
//
// `/admin/operations/communications/...`, dans la VRAIE coquille Admin
// (`AdminShell`, domaine Operations allume), jamais un neuvieme domaine ni
// la barre inventee de la maquette (QUESTIONS Q4). Trois onglets pairs,
// chacun une route, par `SousNavigationDomaine` :
//
// - **Annonces** : l'action « Nouvelle annonce » (seulement avec la capacite
//   `publierAnnonce`, COM-BR-16), les quatre indicateurs, les annonces
//   publiees et planifiees, la matrice des regles de portee ;
// - **Moderation** : la file (`FileModeration`) ;
// - **Messages** : la voie COM-MSG-2 la remplit ; ecran provisoire ici.
//
// **Les quatre indicateurs** ne viennent que de lectures reelles ou de
// demonstration marquee : publiees et planifiees (`PortAnnonces`,
// COM-BR-10), contenus en moderation (`PortModeration.file`, COM-BR-06),
// regles de portee (`PortReglesAudience`, COM-BR-11). Une source absente
// (port neutre) dit « pas encore disponible », jamais un chiffre invente ;
// une lecture en echec offre « Réessayer » ; pas de fleche de tendance
// (UX_REVIEW L0, ecart 16). Le compteur de moderation suit la capacite de
// moderer (`CapacitesModeration.voitLaFile`) : sans elle, la file n'est pas
// lue et la tuile ne mene nulle part.
//
// « Nouvelle annonce » ouvre le publieur unique (`PublieurAnnonce`) a la
// place de l'onglet, comme une tache focalisee : la coquille Admin reste.
// « Publiée » n'est dit qu'apres l'accuse du serveur.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/capacites_communication.dart';
import '../../core/communications/moderation.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/stat_tile.dart';
import '../../core/widgets/vue_etat_communication.dart';
import 'annonces_planifiees.dart';
import 'file_moderation.dart';
import 'matrice_audience.dart';
import 'port_annonces.dart';
import 'port_regles_audience.dart';
import 'publieur_annonce.dart';

/// Les trois onglets de l'Administration des communications, dans l'ordre de
/// [ongletsCommunications].
enum OngletCommunications {
  /// Les annonces (COM-ANN-2).
  annonces,

  /// La file de moderation (COM-ANN-2).
  moderation,

  /// Les fils de messages, cote administration (COM-MSG-2).
  messages,
}

/// L'Administration des communications.
class AdministrationCommunicationsPage extends ConsumerStatefulWidget {
  /// Cree la page sur l'onglet [onglet].
  const AdministrationCommunicationsPage({
    required this.onglet,
    super.key,
    this.filId,
    this.onglets,
    this.horloge,
  });

  /// L'onglet ouvert.
  final OngletCommunications onglet;

  /// Le fil ouvert dans l'onglet Messages, s'il y en a un.
  final String? filId;

  /// Les onglets et leurs adresses ; par defaut, ceux du socle
  /// ([ongletsCommunications]). La demonstration passe les siens, pour
  /// rester dans ses adresses.
  final List<({String libelle, String chemin})>? onglets;

  /// L'horloge des creneaux du publieur ; par defaut, maintenant.
  final DateTime Function()? horloge;

  /// La cle de l'action « Nouvelle annonce », pour les tests.
  static const ValueKey<String> cleNouvelle = ValueKey<String>(
    'administration-nouvelle-annonce',
  );

  /// La cle de l'action « Réessayer » d'une tuile en echec, par libelle,
  /// pour les tests.
  static ValueKey<String> cleReessayerIndicateur(String libelle) =>
      ValueKey<String>('administration-indicateur-reessayer-$libelle');

  /// La cle de la rangee des indicateurs, pour les tests.
  static const ValueKey<String> cleIndicateurs = ValueKey<String>(
    'administration-indicateurs',
  );

  @override
  ConsumerState<AdministrationCommunicationsPage> createState() =>
      _AdministrationCommunicationsPageState();
}

class _AdministrationCommunicationsPageState
    extends ConsumerState<AdministrationCommunicationsPage> {
  bool _publication = false;
  String? _retourLocal;

  List<({String libelle, String chemin})> get _onglets =>
      widget.onglets ?? ongletsCommunications();

  void _confirmee(AnnonceConfirmee confirmee) {
    ref.invalidate(annoncesAdministrationProvider);
    _retourLocal = messageConfirmationAnnonce(confirmee);
  }

  @override
  Widget build(BuildContext context) {
    if (_publication && widget.onglet == OngletCommunications.annonces) {
      return _PublicationAdministration(
        horloge: widget.horloge,
        onConfirmee: _confirmee,
        onQuitter: () => setState(() => _publication = false),
      );
    }
    final n = t.com.socle.navigation.provisoire;
    return PageShell(
      titre: n.administrationTitre,
      entete: SousNavigationDomaine(
        onglets: _onglets,
        indexActif: widget.onglet.index,
      ),
      // La file de moderation et ses colonnes defilent elles-memes.
      defilante: widget.onglet != OngletCommunications.moderation,
      child: switch (widget.onglet) {
        OngletCommunications.annonces => _OngletAnnonces(
          retourLocal: _retourLocal,
          cheminModeration:
              _onglets[OngletCommunications.moderation.index].chemin,
          onNouvelle: () => setState(() {
            _retourLocal = null;
            _publication = true;
          }),
        ),
        OngletCommunications.moderation => const FileModeration(),
        // L'onglet Messages appartient a COM-MSG-2.
        OngletCommunications.messages => EtatSysteme(
          nature: NatureEtat.indisponible,
          titre: t.com.socle.composants.etats.indisponibleTitre,
          phrase: n.administrationDetail,
          dependance: 'COM-MSG-2',
        ),
      },
    );
  }
}

/// L'onglet Annonces.
class _OngletAnnonces extends ConsumerWidget {
  const _OngletAnnonces({
    required this.retourLocal,
    required this.cheminModeration,
    required this.onNouvelle,
  });

  final String? retourLocal;
  final String cheminModeration;
  final VoidCallback onNouvelle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = t.com.annonces.administration;
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;
    final bool mobile = AppGabarit.de(context) == Gabarit.mobile;
    // Une capacite absente n'est pas rendue (jamais grisee) ; tant qu'elle
    // n'est pas lue, rien non plus.
    final bool peutPublier =
        ref
            .watch(capacitesCommunicationProvider)
            .value
            ?.peut(CapaciteCommunication.publierAnnonce) ??
        false;

    const Widget publiees = SectionAnnoncesAdministration(
      etat: EtatAnnonce.publiee,
    );
    const Widget planifiees = SectionAnnoncesAdministration(
      etat: EtatAnnonce.planifiee,
    );
    const Widget matrice = MatriceAudience();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (peutPublier) ...<Widget>[
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ActionPrincipale(
              key: AdministrationCommunicationsPage.cleNouvelle,
              libelle: a.nouvelle,
              pleineLargeur: mobile,
              onPress: onNouvelle,
            ),
          ),
          Ecart.vLg,
        ],
        LocalFeedback(message: retourLocal),
        _Indicateurs(cheminModeration: cheminModeration),
        Ecart.vSection,
        if (bureau)
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xxxl,
            children: <Widget>[
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[publiees, Ecart.vSection, matrice],
                ),
              ),
              Expanded(flex: 2, child: planifiees),
            ],
          )
        else ...<Widget>[
          publiees,
          Ecart.vSection,
          planifiees,
          Ecart.vSection,
          matrice,
        ],
      ],
    );
  }
}

/// Le compte d'une lecture, sans perdre son erreur : pendant une relance
/// automatique, Riverpod 3 garde l'erreur sur un etat de chargement, qu'un
/// `whenData` effacerait (la tuile repasserait en squelette).
AsyncValue<int> _compte<T>(AsyncValue<T> lue, int Function(T valeur) compter) {
  if (lue.hasError) {
    return AsyncError<int>(lue.error!, lue.stackTrace ?? StackTrace.empty);
  }
  if (lue.hasValue) return AsyncData<int>(compter(lue.requireValue));
  return const AsyncLoading<int>();
}

/// Un indicateur : son libelle et sa valeur lue, ou ce qui manque ; ou il
/// mene, et comment relire sa source.
typedef _Mesure = ({
  String libelle,
  AsyncValue<int> valeur,
  VoidCallback? va,
  VoidCallback relire,
});

/// La moderation refusee a la personne : la file n'est pas lue (capacite du
/// serveur, jamais un role).
class _ModerationReservee implements Exception {
  const _ModerationReservee();
}

/// Les quatre indicateurs du haut de l'onglet Annonces.
class _Indicateurs extends ConsumerWidget {
  const _Indicateurs({required this.cheminModeration});

  final String cheminModeration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = t.com.annonces.administration.indicateurs;
    final AsyncValue<AnnoncesAdministration> annonces = ref.watch(
      annoncesAdministrationProvider,
    );
    // La file ne se lit qu'avec la capacite de moderer : sans elle, ni
    // compte ni lien vers une file refusee.
    final AsyncValue<CapacitesModeration> capacites = ref.watch(
      capacitesModerationFileProvider,
    );
    final bool voitLaFile =
        capacites.hasValue &&
        !capacites.hasError &&
        capacites.requireValue.voitLaFile;
    final AsyncValue<List<ElementModeration>> file;
    if (capacites.hasError) {
      file = AsyncError<List<ElementModeration>>(
        capacites.error!,
        capacites.stackTrace ?? StackTrace.empty,
      );
    } else if (!capacites.hasValue) {
      file = const AsyncLoading<List<ElementModeration>>();
    } else if (!voitLaFile) {
      file = const AsyncError<List<ElementModeration>>(
        _ModerationReservee(),
        StackTrace.empty,
      );
    } else {
      file = ref.watch(fileModerationProvider);
    }
    final AsyncValue<ReglesAudience> regles = ref.watch(reglesAudienceProvider);
    final bool demonstration =
        (annonces.value?.demonstration ?? false) ||
        (regles.value?.demonstration ?? false) ||
        (voitLaFile &&
            file.hasValue &&
            ref.watch(moderationDemonstrationProvider));
    void relireAnnonces() => ref.invalidate(annoncesAdministrationProvider);

    final List<_Mesure> mesures = <_Mesure>[
      (
        libelle: i.publiees,
        valeur: _compte(
          annonces,
          (AnnoncesAdministration v) => v.publiees.length,
        ),
        va: null,
        relire: relireAnnonces,
      ),
      (
        libelle: i.planifiees,
        valeur: _compte(
          annonces,
          (AnnoncesAdministration v) => v.planifiees.length,
        ),
        va: null,
        relire: relireAnnonces,
      ),
      (
        libelle: i.moderation,
        valeur: _compte(file, (List<ElementModeration> v) => v.length),
        va: voitLaFile ? () => GoRouter.of(context).go(cheminModeration) : null,
        relire: () => ref
          ..invalidate(capacitesModerationFileProvider)
          ..invalidate(fileModerationProvider),
      ),
      (
        libelle: i.regles,
        valeur: _compte(regles, (ReglesAudience v) => v.regles.length),
        va: null,
        relire: () => ref.invalidate(reglesAudienceProvider),
      ),
    ];
    final List<Widget> tuiles = <Widget>[
      for (final _Mesure m in mesures) _Indicateur(mesure: m),
    ];
    return Column(
      key: AdministrationCommunicationsPage.cleIndicateurs,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        EnTeteSectionAdministration(
          titre: i.titre,
          demonstration: demonstration,
        ),
        Ecart.vMd,
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            // Quatre de front des la classe moyenne, deux par deux sur
            // telephone : jamais une tuile ecrasee.
            if (AppGabarit.classe(c.maxWidth) != ClasseLargeur.compacte) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.lg,
                  children: <Widget>[
                    for (final Widget tuile in tuiles) Expanded(child: tuile),
                  ],
                ),
              );
            }
            return PileCartes(
              children: <Widget>[
                for (int r = 0; r < tuiles.length; r += 2)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpacing.lg,
                      children: <Widget>[
                        Expanded(child: tuiles[r]),
                        Expanded(child: tuiles[r + 1]),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Une tuile d'indicateur : le chiffre lu (zero compris), sinon ce qui
/// manque en mots, jamais un chiffre invente.
class _Indicateur extends StatelessWidget {
  const _Indicateur({required this.mesure});

  final _Mesure mesure;

  @override
  Widget build(BuildContext context) {
    final i = t.com.annonces.administration.indicateurs;
    final AsyncValue<int> v = mesure.valeur;
    if (v.hasValue && !v.hasError) {
      return StatTile(
        valeur: v.requireValue,
        libelle: mesure.libelle,
        onPress: mesure.va,
      );
    }
    final Object? erreur = v.error;
    if (erreur == null) {
      return Semantics(
        label: t.com.socle.composants.etats.chargement,
        child: const ExcludeSemantics(child: Skeleton.tuileBento()),
      );
    }
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle style = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    // Une source absente ou refusee : une phrase, rien a relancer. Une
    // lecture en echec : la phrase et « Réessayer ».
    if (erreur is CapaciteIndisponible || erreur is _ModerationReservee) {
      return AppCard(
        child: Text(
          erreur is _ModerationReservee
              ? i.reserve(libelle: mesure.libelle)
              : i.indisponible(libelle: mesure.libelle),
          style: style,
        ),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(i.echec(libelle: mesure.libelle), style: style),
          Ecart.vXs,
          LienFleche(
            key: AdministrationCommunicationsPage.cleReessayerIndicateur(
              mesure.libelle,
            ),
            libelle: t.commun.etats.actions.reessayer,
            onPress: mesure.relire,
          ),
        ],
      ),
    );
  }
}

/// Le publieur de l'Administration : les audiences ouvertes par le serveur,
/// puis le publieur unique.
class _PublicationAdministration extends ConsumerWidget {
  const _PublicationAdministration({
    required this.onConfirmee,
    required this.onQuitter,
    this.horloge,
  });

  final ValueChanged<AnnonceConfirmee> onConfirmee;
  final VoidCallback onQuitter;
  final DateTime Function()? horloge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChargementPublieur(
      classeId: null,
      titre: t.com.annonces.publieur.titre,
      onQuitter: onQuitter,
      construire: (List<CibleAnnonce> cibles, bool peutProgrammer) =>
          PublieurAnnonce(
            cibles: cibles,
            peutProgrammer: peutProgrammer,
            horloge: horloge,
            onConfirmee: onConfirmee,
            onQuitter: onQuitter,
          ),
    );
  }
}

/// Lit ce qu'il faut au publieur (les audiences du serveur, la capacite de
/// programmer), avec les etats chargement, erreur, hors ligne, indisponible
/// et vide (aucune audience ouverte), puis construit le publieur.
///
/// Partage par l'Administration ([classeId] nul) et par la publication
/// depuis une Classe : un seul chemin de lecture pour un seul publieur.
class ChargementPublieur extends ConsumerWidget {
  /// Cree le chargement.
  const ChargementPublieur({
    required this.classeId,
    required this.titre,
    required this.onQuitter,
    required this.construire,
    super.key,
    this.retenir,
  });

  /// Ne garde que les audiences qui passent ce filtre (la Classe de
  /// l'adresse, pour l'enseignant) ; par defaut, toutes celles du serveur.
  final bool Function(CibleAnnonce cible)? retenir;

  /// La Classe visee, ou `null` pour l'Administration.
  final String? classeId;

  /// Le titre de la page tant que le publieur n'est pas pret.
  final String titre;

  /// Le retour.
  final VoidCallback onQuitter;

  /// Le publieur, sur les audiences lues et la capacite de programmer.
  final Widget Function(List<CibleAnnonce> cibles, bool peutProgrammer)
  construire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = t.com.annonces.publieur;
    final bool Function(CibleAnnonce)? filtre = retenir;
    // L'`AsyncValue` se lit par `hasValue` / `hasError` (lib/CLAUDE.md) ; le
    // filtre s'applique a la valeur seulement.
    final AsyncValue<List<CibleAnnonce>> cibles = ref.watch(
      ciblesPublicationProvider(classeId),
    );
    final List<CibleAnnonce>? retenues = cibles.hasValue && !cibles.hasError
        ? <CibleAnnonce>[
            for (final CibleAnnonce c in cibles.requireValue)
              if (filtre == null || filtre(c)) c,
          ]
        : null;
    final AsyncValue<CapacitesCommunication> capacites = ref.watch(
      capacitesCommunicationProvider,
    );
    if (retenues != null &&
        retenues.isNotEmpty &&
        capacites.hasValue &&
        !capacites.hasError) {
      return construire(
        retenues,
        capacites.requireValue.peut(CapaciteCommunication.programmer),
      );
    }
    final Object? erreur = cibles.error ?? capacites.error;
    final Widget corps;
    if (erreur is CapaciteIndisponible) {
      corps = EtatSysteme(
        nature: NatureEtat.indisponible,
        titre: t.com.socle.composants.etats.indisponibleTitre,
        phrase: p.indisponible,
        dependance: erreur.dependance,
      );
    } else if (erreur != null) {
      corps =
          etatErreurAdministration(ref, erreur, () => _relire(ref)) ??
          VueEtatCommunication(
            etat: EtatCommunication.erreur,
            onReessayer: () => _relire(ref),
          );
    } else if (cibles.hasValue && capacites.hasValue) {
      corps = EtatSysteme(
        nature: NatureEtat.accesRefuse,
        titre: p.aucuneCibleTitre,
        phrase: p.aucuneCible,
      );
    } else {
      corps = Semantics(
        label: t.com.socle.composants.etats.chargement,
        child: const ExcludeSemantics(child: Skeleton.liste()),
      );
    }
    return PageShell(titre: titre, onRetour: onQuitter, child: corps);
  }

  void _relire(WidgetRef ref) => ref
    ..invalidate(ciblesPublicationProvider(classeId))
    ..invalidate(capacitesCommunicationProvider);
}
