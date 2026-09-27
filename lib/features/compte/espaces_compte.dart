// Les espaces d'un compte (CT-9, vague Controleur).
//
// Controleur est une capacite, pas une identite (decision du directeur du
// 27/09/2026, C6) : un Enseignant ou un Admin passe en Controle par
// `Compte > Espaces`, avec le meme compte ; un raccourci d'en-tete ouvre CE
// MEME selecteur ([ouvrirSelecteurEspaces]), il ne cree pas un second
// mecanisme. Le tuteur n'est jamais controleur : aucun espace ne le porte.
//
// **Rien ici n'est deduit.** `SessionState` ne porte qu'un role effectif :
// le fournisseur par defaut rend ce seul espace, sans cumul. Le cumul
// (Enseignant-Controleur, Admin-Controleur), la mission en cours et la
// revocation viendront d'une projection serveur explicite (BR-1,
// `14_controleur/CT-BR.md`) ; la demonstration les simule en surchargeant
// [espacesCompteProvider]. Refus par defaut (C7, doc 08 §9.5) : sans
// capacite Controle connue, l'espace Controle est ferme.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/setting_row.dart';

/// Un espace de travail du compte.
enum EspaceTravail {
  /// L'espace Enseignant.
  enseignement,

  /// L'espace Admin.
  administration,

  /// L'espace Controle : une capacite qui s'ajoute, jamais un espace
  /// principal.
  controle,
}

/// L'acces a l'espace Controle, tel que la projection le dit.
enum AccesControle {
  /// La session n'est pas encore resolue : rien n'est montre, rien n'est
  /// refuse.
  enAttente,

  /// La capacite Controle est active.
  actif,

  /// Aucune capacite Controle connue, ou elle a ete retiree : refus
  /// generique, aucun contenu (C7, P-CTR-01).
  refuse,
}

/// Les espaces du compte et celui qui est actif.
@immutable
class EspacesCompte {
  /// Cree la projection.
  const EspacesCompte({
    required this.disponibles,
    required this.actif,
    this.missionEnCours = false,
    this.resolu = true,
  });

  /// Le seul espace du role effectif, sans cumul : ce que l'application sait
  /// aujourd'hui (le tuteur, l'eleve et le comptable n'ont aucun espace).
  factory EspacesCompte.roleSeul(AppRole? role) {
    final EspaceTravail? seul = switch (role) {
      AppRole.teacher => EspaceTravail.enseignement,
      AppRole.admin => EspaceTravail.administration,
      AppRole.controller => EspaceTravail.controle,
      AppRole.guardian || AppRole.student || AppRole.accountant || null => null,
    };
    return seul == null
        ? aucun
        : EspacesCompte(disponibles: <EspaceTravail>[seul], actif: seul);
  }

  /// Un cumul Enseignant-Controleur ou Admin-Controleur, tel que le serveur
  /// le projettera (BR-1). [principal] n'est jamais Controle.
  factory EspacesCompte.cumul({
    required EspaceTravail principal,
    required EspaceTravail actif,
    bool missionEnCours = false,
  }) {
    assert(
      principal != EspaceTravail.controle,
      'Controle est une capacite, jamais un espace principal (C6).',
    );
    return EspacesCompte(
      disponibles: <EspaceTravail>[principal, EspaceTravail.controle],
      actif: actif,
      missionEnCours: missionEnCours,
    );
  }

  /// Aucun espace.
  static const EspacesCompte aucun = EspacesCompte(
    disponibles: <EspaceTravail>[],
    actif: null,
  );

  /// La session n'est pas encore resolue.
  static const EspacesCompte enAttente = EspacesCompte(
    disponibles: <EspaceTravail>[],
    actif: null,
    resolu: false,
  );

  /// Les espaces ouverts au compte, l'espace principal d'abord.
  final List<EspaceTravail> disponibles;

  /// L'espace actif, ou nul.
  final EspaceTravail? actif;

  /// Vrai quand une mission de controle est en cours (salle, compte rendu
  /// non termine) : revenir a l'espace principal exige de la quitter (§4.2).
  final bool missionEnCours;

  /// Faux tant que la session n'est pas resolue.
  final bool resolu;

  /// Plus d'un espace : le selecteur a quelque chose a proposer.
  bool get plusieurs => disponibles.length > 1;

  /// L'espace principal (Enseignant ou Admin), ou nul pour un controleur
  /// externe.
  EspaceTravail? get principal {
    for (final EspaceTravail e in disponibles) {
      if (e != EspaceTravail.controle) return e;
    }
    return null;
  }

  /// L'acces a Controle, refuse par defaut.
  AccesControle get accesControle => !resolu
      ? AccesControle.enAttente
      : disponibles.contains(EspaceTravail.controle)
      ? AccesControle.actif
      : AccesControle.refuse;

  /// Vrai quand la mission en cours retient en Controle.
  bool get retenuParMission =>
      missionEnCours && actif == EspaceTravail.controle && principal != null;

  /// Vrai quand [espace] peut etre rejoint maintenant.
  bool peutRejoindre(EspaceTravail espace) =>
      disponibles.contains(espace) &&
      espace != actif &&
      !(retenuParMission && espace != EspaceTravail.controle);

  /// La meme projection, [espace] actif.
  EspacesCompte avecActif(EspaceTravail espace) => EspacesCompte(
    disponibles: disponibles,
    actif: espace,
    missionEnCours: missionEnCours,
    resolu: resolu,
  );

  /// La meme projection, sans la capacite Controle (revocation).
  EspacesCompte sansControle() => EspacesCompte(
    disponibles: <EspaceTravail>[
      for (final EspaceTravail e in disponibles)
        if (e != EspaceTravail.controle) e,
    ],
    actif: actif,
    resolu: resolu,
  );
}

/// Tient la projection des espaces. **Neutre par defaut** : le seul espace
/// du role de la session, aucun cumul, aucun appel reseau (K-28).
class EspacesCompteControleur extends Notifier<EspacesCompte> {
  @override
  EspacesCompte build() {
    final SessionState session = ref.watch(sessionProvider);
    if (!session.resolue) return EspacesCompte.enAttente;
    return EspacesCompte.roleSeul(session.role);
  }

  /// Rend [espace] actif, s'il peut etre rejoint.
  void activer(EspaceTravail espace) {
    if (state.peutRejoindre(espace)) state = state.avecActif(espace);
  }

  /// La capacite Controle est retiree (P-CTR-01).
  void revoquerControle() => state = state.sansControle();
}

/// Les espaces du compte.
///
/// Derive de la session : il en declare la dependance, pour suivre une
/// session surchargee dans un `ProviderScope` imbrique (demonstrations,
/// tests) au lieu de lire la session racine.
final NotifierProvider<EspacesCompteControleur, EspacesCompte>
espacesCompteProvider =
    NotifierProvider<EspacesCompteControleur, EspacesCompte>(
      EspacesCompteControleur.new,
      dependencies: <ProviderOrFamily>[sessionProvider],
    );

/// Ou mene chaque espace.
@immutable
class AdressesEspaces {
  /// Cree les adresses.
  const AdressesEspaces({
    required this.enseignement,
    required this.administration,
    required this.controle,
    required this.racine,
  });

  /// Les racines de l'application.
  static const AdressesEspaces reelles = AdressesEspaces(
    enseignement: Routes.enseignantJournee,
    administration: Routes.admin,
    controle: Routes.controleur,
    racine: Routes.racine,
  );

  /// L'espace Enseignant.
  final String enseignement;

  /// L'espace Admin.
  final String administration;

  /// L'espace Controle.
  final String controle;

  /// La racine, qui redecide selon la session.
  final String racine;

  /// L'adresse de [espace].
  String de(EspaceTravail espace) => switch (espace) {
    EspaceTravail.enseignement => enseignement,
    EspaceTravail.administration => administration,
    EspaceTravail.controle => controle,
  };

  /// « Revenir a mon espace » : l'espace principal, ou la racine.
  String monEspace(EspacesCompte espaces) {
    final EspaceTravail? p = espaces.principal;
    return p == null ? racine : de(p);
  }
}

/// Les adresses des espaces ; la demonstration les remplace.
final Provider<AdressesEspaces> adressesEspacesProvider =
    Provider<AdressesEspaces>((Ref _) => AdressesEspaces.reelles);

/// Le libelle d'un espace : celui du role, ou « Controle ».
String libelleEspace(EspaceTravail espace) => switch (espace) {
  EspaceTravail.enseignement => t.compte.roles.teacher,
  EspaceTravail.administration => t.compte.roles.admin,
  EspaceTravail.controle => t.nav.controleur.controle,
};

String _detailEspace(EspaceTravail espace) => switch (espace) {
  EspaceTravail.enseignement => t.compte.roleDetail.teacher,
  EspaceTravail.administration => t.compte.roleDetail.admin,
  EspaceTravail.controle => t.compte.roleDetail.controller,
};

AppIcon _iconeEspace(EspaceTravail espace) => switch (espace) {
  EspaceTravail.enseignement => AppIcons.journee,
  EspaceTravail.administration => AppIcons.tableauDeBord,
  EspaceTravail.controle => AppIcons.controleQualite,
};

/// Le selecteur d'espaces : UN seul widget, rendu dans `Compte > Espaces` et
/// dans la feuille du raccourci d'en-tete.
///
/// L'espace actif est marque « Actif » ; un espace qui ne peut pas etre
/// rejoint n'est pas un bouton, et une phrase dit pourquoi (mission en
/// cours, §4.2).
class SelecteurEspaces extends ConsumerWidget {
  /// Cree le selecteur.
  const SelecteurEspaces({super.key, this.onChoisi});

  /// Appele avant de rejoindre l'espace choisi (la feuille se ferme).
  final VoidCallback? onChoisi;

  /// La cle de la ligne d'un espace.
  static Key cleEspace(EspaceTravail espace) =>
      ValueKey<String>('espace-${espace.name}');

  /// La cle de la phrase « mission en cours ».
  static const Key missionEnCoursKey = ValueKey<String>('espaces-mission');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EspacesCompte espaces = ref.watch(espacesCompteProvider);
    final AdressesEspaces adresses = ref.watch(adressesEspacesProvider);
    final AppPalette palette = AppPalette.of(context);

    void rejoindre(EspaceTravail espace) {
      final GoRouter routeur = GoRouter.of(context);
      onChoisi?.call();
      ref.read(espacesCompteProvider.notifier).activer(espace);
      routeur.go(adresses.de(espace));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final EspaceTravail espace in espaces.disponibles)
          SettingRow(
            key: cleEspace(espace),
            title: libelleEspace(espace),
            description: _detailEspace(espace),
            value: espace == espaces.actif ? t.compte.actif : null,
            icon: _iconeEspace(espace),
            onPress: espaces.peutRejoindre(espace)
                ? () => rejoindre(espace)
                : null,
          ),
        if (espaces.retenuParMission) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(
              t.compte.espacesMissionEnCours,
              key: missionEnCoursKey,
              style: palette.inkMuted.applyTo(
                Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Ouvre le selecteur d'espaces dans une feuille : le MEME [SelecteurEspaces]
/// que `Compte > Espaces`, lu dans le meme conteneur de providers.
Future<void> ouvrirSelecteurEspaces(BuildContext context) {
  // La feuille vit dans l'overlay du navigateur, hors d'un ProviderScope
  // imbrique : elle lit le conteneur de l'appelant, jamais la racine.
  final ProviderContainer conteneur = ProviderScope.containerOf(context);
  return AppBottomSheet.ouvrir<void>(
    context,
    titre: t.compte.espaces,
    constructeur: (BuildContext feuille) => UncontrolledProviderScope(
      container: conteneur,
      child: SelecteurEspaces(onChoisi: () => Navigator.of(feuille).maybePop()),
    ),
  );
}

/// Le raccourci d'en-tete vers le selecteur d'espaces : rendu seulement
/// quand le compte a plus d'un espace.
class RaccourciEspaces extends ConsumerWidget {
  /// Cree le raccourci.
  const RaccourciEspaces({super.key});

  /// La cle du raccourci.
  static const Key cle = ValueKey<String>('raccourci-espaces');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool plusieurs = ref.watch(
      espacesCompteProvider.select((EspacesCompte e) => e.plusieurs),
    );
    if (!plusieurs) return const SizedBox.shrink();
    final AppPalette palette = AppPalette.of(context);
    final bool mobile = AppGabarit.de(context) == Gabarit.mobile;
    return Pressable(
      key: cle,
      onPress: () => ouvrirSelecteurEspaces(context),
      libelleSemantique: t.compte.espaces,
      arrondiFocus: AppRadius.arrondiFull,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: AppTouchTarget.standard,
          child: Center(
            child: IconTheme(
              data: (mobile ? palette.inkStrong : palette.inkMuted).asIconTheme(
                size: AppSpacing.xxl,
              ),
              child: Icon(AppIcons.reaffectation.repos),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pose le [RaccourciEspaces] dans l'en-tete des pages de [child], quand le
/// compte a plus d'un espace ; sinon rien ne change.
class EnteteEspaces extends ConsumerWidget {
  /// Cree l'en-tete.
  const EnteteEspaces({required this.child, super.key});

  /// La coquille.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool plusieurs = ref.watch(
      espacesCompteProvider.select((EspacesCompte e) => e.plusieurs),
    );
    if (!plusieurs) return child;
    return ActionsEnteteCoquille(
      actions: const <Widget>[RaccourciEspaces()],
      child: child,
    );
  }
}
