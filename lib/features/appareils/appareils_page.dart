import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'liste_appareils_eleve.dart';

/// `/tuteur/foyer/appareils` : les appareils du foyer.
///
/// Composition (manifeste section 2 : « Nom, profils autorises, gestion »,
/// lignes de Mon compte #6 ; contenu de l'ancienne capture « Foyer Member »
/// #30) : UN groupe a filets « Profils eleves », une ligne par profil (prenom,
/// appareils connectes et leurs noms, chevron vers ses appareils), puis
/// l'explication de l'appareil partage. Bureau : le groupe a gauche,
/// l'explication a droite.
///
/// **Une fonction, un seul endroit** : le retrait et la connexion d'un
/// appareil vivent sur la page de chaque profil
/// (`/tuteur/foyer/:eleveId/appareils`) ; cette page y mene. L'ajout d'un
/// profil eleve vit au Foyer : ici, seul l'etat vide y invite.
///
/// Aucun compteur decoratif, aucune limite codee (DB-APP-04), aucun
/// « appareil familial » invente : la vue ne sait pas regrouper un appareil
/// partage (DB-APP-05), l'explication le dit.
///
/// Etats : chargement (squelette), contenu, vide (aucun profil), erreur
/// (« Reessayer »), hors ligne sans donnees.
class AppareilsPage extends ConsumerWidget {
  /// Cree la page.
  const AppareilsPage({super.key, this.onAller, this.onRetour});

  /// Ouvre un chemin (ajout, appareils d'un profil) ; par defaut, le
  /// routeur. La demonstration adulte y garde la personne dans sa coquille.
  final void Function(String chemin)? onAller;

  /// Le retour ; par defaut, le Foyer par le routeur (niveau 2).
  final VoidCallback? onRetour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<DonneesAppareilsFoyer> donnees = ref.watch(
      donneesAppareilsFoyerProvider,
    );
    final AsyncValue<bool> reseau = ref.watch(horsLigneProvider);
    final bool horsLigne = reseau.hasValue && reseau.requireValue;
    final void Function(String chemin)? aller =
        onAller ?? GoRouter.maybeOf(context)?.go;

    // Tant que le Foyer du lot B n'est pas livre, la destination Foyer rend
    // cette page (STUB de `foyer_page.dart`) : a sa propre racine, elle n'a
    // pas de retour. A `/tuteur/foyer/appareils`, le retour mene au Foyer.
    final bool niveau2 = _cheminCourant(context) != Routes.tuteurFoyer;

    final Widget corps = horsLigne && !donnees.hasValue
        // Le bandeau de `PageShell` dit le reseau, le bloc dit ce qui manque
        // (EA-HL-DOUBLE-1).
        ? EtatSansDonnees(
            quoi: t.appareils.foyer.sansDonnees,
            onAction: () => relireAppareilsFoyer(ref),
          )
        : BlocAsynchrone<DonneesAppareilsFoyer>(
            valeur: donnees,
            squelette: const _Squelette(),
            onReessayer: () => relireAppareilsFoyer(ref),
            estVide: (DonneesAppareilsFoyer d) => d.eleves.isEmpty,
            vide: EtatSysteme(
              nature: NatureEtat.aucunResultat,
              titre: t.appareils.foyer.videTitre,
              phrase: t.appareils.foyer.vide,
              libelleAction: t.appareils.foyer.videAction,
              onAction: () => aller?.call(Routes.tuteurAjouterEnfant),
            ),
            construire: (DonneesAppareilsFoyer d) => _Contenu(
              donnees: d,
              onProfil: (String eleveId) =>
                  aller?.call(Routes.ficheEleveSousPage(eleveId, 'appareils')),
            ),
          );

    return PageShell(
      titre: t.appareils.foyer.titre,
      onRetour:
          onRetour ??
          (niveau2 && aller != null ? () => aller(Routes.tuteurFoyer) : null),
      child: corps,
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({required this.donnees, required this.onProfil});

  final DonneesAppareilsFoyer donnees;
  final void Function(String eleveId) onProfil;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final f = t.appareils.foyer;
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;

    final List<Widget> principal = <Widget>[
      Text(
        f.phrase,
        style: palette.inkMuted.applyTo(textes.bodyLarge ?? const TextStyle()),
      ),
      Ecart.vXxl,
      GroupeReglages(
        titre: f.groupeProfils,
        lignes: <LigneRubrique>[
          for (final EleveDuFoyer eleve in elevesParPrenom(donnees.eleves))
            LigneRubrique(
              icone: AppIcons.profil,
              libelle: eleve.prenom,
              legende: resumeAppareils(
                appareilsActifsDe(eleve.id, donnees.appareils),
              ),
              onPress: () => onProfil(eleve.id),
            ),
        ],
      ),
    ];

    final Widget partage = EncartAppareils(
      icone: AppIcons.verrou,
      titre: f.partageTitre,
      phrase: f.partage,
    );

    if (bureau) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: principal,
            ),
          ),
          const SizedBox(width: AppSpacing.section),
          Expanded(flex: 2, child: partage),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[...principal, Ecart.vSection, partage],
    );
  }
}

class _Squelette extends StatelessWidget {
  const _Squelette();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Skeleton(hauteur: AppSpacing.xxxl),
      Ecart.vXxl,
      Skeleton(hauteur: AppSpacing.respiration * 3),
    ],
  );
}

/// Le chemin de l'ecran courant, `null` hors routeur.
String? _cheminCourant(BuildContext context) {
  try {
    return GoRouterState.of(context).uri.path;
  } on Object {
    return null;
  }
}
