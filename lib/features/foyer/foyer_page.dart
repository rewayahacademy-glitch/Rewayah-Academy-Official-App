import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_classes_foyer.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/offres/offre_horaire.dart';
import '../../core/offres/service_offres.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'ligne_membre.dart';

/// L'horloge du Foyer, pour dire qu'une echeance d'acces est passee.
///
/// Un provider plutot qu'un appel direct a `DateTime.now` : les tests fixent
/// l'instant, l'application garde l'horloge de l'appareil.
final Provider<DateTime Function()> horlogeFoyerProvider =
    Provider<DateTime Function()>((Ref ref) => DateTime.now);

/// Les classes d'un membre du foyer (port K6 `PortClassesFoyer`).
///
/// En production, le port n'a pas encore de service (DB-TRV-07, adaptateur du
/// lot C) : la lecture rend `CapaciteIndisponible`, et la page le dit une fois
/// au lieu d'inventer une classe ou une absence de classe.
final FutureProviderFamily<List<ClasseFoyer>, String> classesMembreProvider =
    FutureProvider.family<List<ClasseFoyer>, String>(
      (Ref ref, String eleveId) =>
          ref.watch(portClassesFoyerProvider).classesDe(eleveId),
    );

/// Le Foyer (`/tuteur/foyer`, deuxieme destination du tuteur).
///
/// Aucune maquette haute fidelite : la composition derive du manifeste
/// visuel (section 2, ligne `/tuteur/foyer`) : contenu de l'ancienne capture
/// « Foyer Member », rendu des lignes de rubrique de « Mon compte ». Titre,
/// action « Ajouter un profil eleve » en tete, les membres en UN groupe a
/// filets (prenom, classe quand elle est connue, statut d'acces en texte,
/// chevron vers la fiche), les appareils partages en une ligne vers l'ecran
/// du lot D, et l'option discrete « Creer mon profil eleve ». Aucun compteur
/// decoratif. Sur bureau (a partir de 1200), deux colonnes comme le Compte.
class FoyerPage extends ConsumerWidget {
  /// Cree la page.
  const FoyerPage({super.key});

  /// L'action « Ajouter un profil eleve » de l'en-tete.
  static const Key ajouterKey = Key('foyer.ajouter');

  /// Le groupe des profils eleves.
  static const Key membresKey = Key('foyer.membres');

  /// La section des appareils partages.
  static const Key appareilsKey = Key('foyer.appareils');

  /// Le lien « Creer mon profil eleve ».
  static const Key monProfilKey = Key('foyer.monProfil');

  /// Le lien « Relire les classes » apres un echec de lecture.
  static const Key relireClassesKey = Key('foyer.relireClasses');

  /// La phrase qui dit que l'inscription en cours ne se lit pas.
  static const Key inscriptionIllisibleKey = Key('foyer.inscriptionIllisible');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;
    final GoRouter routeur = GoRouter.of(context);

    const Widget membres = KeyedSubtree(key: membresKey, child: _Membres());
    final Widget annexes = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        KeyedSubtree(
          key: appareilsKey,
          child: GroupeReglages(
            titre: t.foyer.appareilsPartages,
            lignes: <LigneRubrique>[
              LigneRubrique(
                icone: AppIcons.appareil,
                libelle: t.foyer.appareilsFoyer,
                legende: t.foyer.appareilsFoyerLegende,
                onPress: () => routeur.go(Routes.tuteurFoyerAppareils),
              ),
            ],
          ),
        ),
        Ecart.vXxl,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LienFleche(
            key: monProfilKey,
            libelle: t.foyer.creerMonProfil,
            onPress: () => routeur.go(Routes.tuteurAjouterPourMoi),
          ),
        ),
      ],
    );

    // L'action d'ajout tient a droite du titre sur bureau. En dessous de
    // 1200, le titre, la bascule de theme, la cloche et le libelle complet
    // ne tiennent pas toujours sur une ligne (358 sur telephone) : elle passe
    // juste sous le titre, hors de la zone defilante, toujours visible. Une
    // seule action, un seul endroit. CTA dominant « libelle + fleche »
    // (03, section 3 point 3).
    final Widget ajouter = ActionPrincipale(
      key: ajouterKey,
      libelle: t.foyer.ajouterProfil,
      fleche: true,
      pleineLargeur: AppGabarit.de(context) == Gabarit.mobile,
      onPress: () => routeur.go(Routes.tuteurAjouterEnfant),
    );

    return PageShell(
      titre: t.foyer.titre,
      sousTitre: t.foyer.sousTitre,
      actionsEntete: <Widget>[if (bureau) ajouter],
      entete: bureau
          ? null
          : Align(alignment: AlignmentDirectional.centerStart, child: ajouter),
      child: bureau
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Expanded(flex: 3, child: membres),
                Ecart.hXxl,
                Expanded(flex: 2, child: annexes),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[membres, Ecart.vSection, annexes],
            ),
    );
  }
}

/// Les membres : chargement, contenu, vide, erreur, hors ligne.
class _Membres extends ConsumerWidget {
  const _Membres();

  void _relire(WidgetRef ref) => ref.invalidate(elevesDuFoyerProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La source (`profils_du_foyer_v`) d'abord : pendant les nouvelles
    // tentatives automatiques de Riverpod, `profilsElevesFoyerProvider`
    // (K1, qui attend `elevesDuFoyerProvider.future`) reste en chargement
    // sans exposer l'echec (mesure : test `foyer_page_test.dart`, etat
    // « erreur »). L'echec de la source est donc lu ici, tel quel, pour que
    // la page dise l'erreur au lieu d'un squelette sans fin (demande B-3).
    final AsyncValue<List<EleveDuFoyer>> source = ref.watch(
      elevesDuFoyerProvider,
    );
    final AsyncValue<List<ProfilEleveFoyer>> profils = source.hasError
        ? AsyncValue<List<ProfilEleveFoyer>>.error(
            source.error!,
            source.stackTrace ?? StackTrace.empty,
          )
        : ref.watch(profilsElevesFoyerProvider);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    // Sans reseau, un echec se dit comme tel : « hors ligne », pas « le
    // serveur n'a pas repondu ».
    if (horsLigne &&
        profils.hasError &&
        profils.error is! CapaciteIndisponible) {
      return EtatSysteme(
        nature: NatureEtat.horsLigne,
        onAction: () => _relire(ref),
      );
    }

    return BlocAsynchrone<List<ProfilEleveFoyer>>(
      valeur: profils,
      squelette: const Skeleton.liste(),
      onReessayer: () => _relire(ref),
      vide: EtatSysteme(
        nature: NatureEtat.aucunResultat,
        titre: t.foyer.vide.titre,
        phrase: t.foyer.vide.phrase,
      ),
      construire: _ListeMembres.new,
    );
  }
}

class _ListeMembres extends ConsumerWidget {
  const _ListeMembres(this.profils);

  final List<ProfilEleveFoyer> profils;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final DateTime maintenant = ref.watch(horlogeFoyerProvider)();
    final GoRouter routeur = GoRouter.of(context);
    // L'inscription en cours de chaque membre sans classe connue
    // (`v_parcours_onboarding`, 0043). Non appliquee en production : la
    // lecture echoue, et la page le dit une fois au lieu d'inventer une
    // etape.
    final AsyncValue<List<ParcoursApprenant>> parcours = ref.watch(
      parcoursFoyerProvider,
    );

    bool classesIndisponibles = false;
    final List<String> classesEnEchec = <String>[];
    final List<LigneRubrique> lignes = <LigneRubrique>[];
    for (final ProfilEleveFoyer profil in profils) {
      final ClasseMembre classe = classeMembreLue(
        ref.watch(classesMembreProvider(profil.eleveId)),
      );
      if (classeIndisponible(classe)) {
        classesIndisponibles = true;
      }
      if (classeEnEchec(classe)) {
        classesEnEchec.add(profil.eleveId);
      }
      lignes.add(
        ligneMembre(
          profil: profil,
          classe: classe,
          maintenant: maintenant,
          inscription: etapeInscriptionLue(parcours, profil.eleveId),
          onPress: () => routeur.go(Routes.ficheElevePour(profil.eleveId)),
        ),
      );
    }

    final TextStyle note = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GroupeReglages(titre: t.foyer.membres, lignes: lignes),
        if (classesIndisponibles) ...<Widget>[
          Ecart.vSm,
          Text(t.foyer.classesIndisponibles, style: note),
        ],
        if (parcours.hasError) ...<Widget>[
          Ecart.vSm,
          Text(
            key: FoyerPage.inscriptionIllisibleKey,
            t.foyer.inscriptionIllisible,
            style: note,
          ),
        ],
        if (classesEnEchec.isNotEmpty) ...<Widget>[
          Ecart.vSm,
          Text(t.foyer.classesEchec, style: note),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              key: FoyerPage.relireClassesKey,
              libelle: t.foyer.relireClasses,
              onPress: () {
                for (final String id in classesEnEchec) {
                  ref.invalidate(classesMembreProvider(id));
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}
