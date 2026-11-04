import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/capacites/port_catalogue_classes.dart'
    show catalogueClassesOuvert, portCatalogueClassesProvider;
import '../../../core/capacites/port_classes_foyer.dart';
import '../../../core/foyer/selection_eleve.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/offres/offre_horaire.dart';
import '../../../core/offres/service_offres.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/groupe_reglages.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../fiche_eleve_page.dart';
import '../foyer_page.dart';
import '../ligne_membre.dart';

/// Le parcours et l'inscription d'un profil eleve
/// (`/tuteur/foyer/:eleveId/inscription`).
///
/// Une **synthese** qui renvoie vers les flux existants, jamais une copie :
/// la ligne « Questionnaire » ouvre le questionnaire du lot A
/// (`/tuteur/parcours/:eleveId`), la ligne « Classe » ouvre la classe de
/// l'eleve quand elle est connue, sinon le choix de classe du lot C
/// (`/tuteur/classes/catalogue?eleve=`). Rendu du recapitulatif E6 : rangees
/// a filets en retrait, correction par rangee.
///
/// Sources : `v_parcours_onboarding` (0043, non appliquee en production :
/// la lecture echoue et la ligne le dit, DB-ADM-01) et le port des classes
/// (K6, sans service en production : DB-TRV-07). Aucune etape ni classe
/// inventee ; le vocabulaire de l'ecran dit « classe », jamais le mot
/// interne du modele.
class InscriptionElevePage extends StatelessWidget {
  /// Cree la page.
  const InscriptionElevePage({required this.eleveId, super.key});

  /// L'eleve concerne.
  final String eleveId;

  /// Le lien « Relire la classe » apres un echec de lecture.
  static const Key relireClasseKey = Key('ficheEleve.inscription.relire');

  @override
  Widget build(BuildContext context) {
    return PageFiche(
      eleveId: eleveId,
      titre: t.ficheEleve.inscription.titre,
      onRetour: retourVersFiche(context, eleveId),
      construire: (BuildContext context, ProfilEleveFoyer profil) =>
          _Synthese(profil: profil),
    );
  }
}

class _Synthese extends ConsumerWidget {
  const _Synthese({required this.profil});

  final ProfilEleveFoyer profil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter routeur = GoRouter.of(context);
    final AsyncValue<List<ParcoursApprenant>> parcours = ref.watch(
      parcoursFoyerProvider,
    );
    final AsyncValue<List<ClasseFoyer>> lectureClasses = ref.watch(
      classesMembreProvider(profil.eleveId),
    );
    final ClasseMembre classe = classeMembreLue(lectureClasses);

    // Le questionnaire : l'etape de CET eleve, ou une phrase qui dit que
    // l'etat ne s'affiche pas (lecture en echec ou eleve absent de la vue).
    final String legendeQuestionnaire;
    if (parcours.hasValue && !parcours.hasError) {
      ParcoursApprenant? trouve;
      for (final ParcoursApprenant p in parcours.requireValue) {
        if (p.eleveId == profil.eleveId) {
          trouve = p;
        }
      }
      legendeQuestionnaire = trouve == null
          ? t.ficheEleve.inscription.etatInconnu
          : libelleEtapeFiche(etapeParcours(trouve));
    } else if (parcours.hasError) {
      legendeQuestionnaire = t.ficheEleve.inscription.etatInconnu;
    } else {
      legendeQuestionnaire = t.ficheEleve.inscription.lecture;
    }

    // La classe : son nom et la classe elle-meme quand elle est connue ;
    // sinon le choix de classe, sans jamais dire « pas de classe » faute de
    // savoir.
    final List<ClasseFoyer> classes =
        lectureClasses.hasValue && !lectureClasses.hasError
        ? lectureClasses.requireValue
        : const <ClasseFoyer>[];
    // Un echec de lecture n'est pas une fonction absente : il se dit comme
    // tel, avec un moyen de relire (annexe), jamais « ne s'affiche pas
    // encore ».
    final bool echecClasses = classeEnEchec(classe);
    final String legendeClasse = classes.isNotEmpty
        ? texteClasse(classe)!
        : echecClasses
        ? t.ficheEleve.inscription.classeEchec
        : classeIndisponible(classe)
        ? t.ficheEleve.inscription.classeIndisponible
        : lectureClasses.isLoading
        ? t.ficheEleve.inscription.lecture
        : t.ficheEleve.inscription.classeAucune;
    final String destinationClasse = classes.isNotEmpty
        ? Routes.classePour(
            classes.first.classe.groupeId,
            eleveId: profil.eleveId,
          )
        // Tri du 31/10/2026 : catalogue ferme (production), le parcours.
        : catalogueClassesOuvert(ref.watch(portCatalogueClassesProvider))
        ? Uri(
            path: Routes.tuteurClassesCatalogue,
            queryParameters: <String, String>{'eleve': profil.eleveId},
          ).toString()
        : Routes.parcoursPour(profil.eleveId);

    return ColonnesFiche(
      annexe: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          NoteFiche(t.ficheEleve.inscription.intro(prenom: profil.prenom)),
          if (echecClasses)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: LienFleche(
                key: InscriptionElevePage.relireClasseKey,
                libelle: t.ficheEleve.inscription.relireClasse,
                onPress: () =>
                    ref.invalidate(classesMembreProvider(profil.eleveId)),
              ),
            ),
        ],
      ),
      principal: GroupeReglages(
        lignes: <LigneRubrique>[
          LigneRubrique(
            icone: AppIcons.lecon,
            libelle: t.ficheEleve.inscription.questionnaire,
            legende: legendeQuestionnaire,
            onPress: () => routeur.go(Routes.parcoursPour(profil.eleveId)),
          ),
          LigneRubrique(
            icone: AppIcons.cours,
            libelle: t.ficheEleve.inscription.classe,
            legende: legendeClasse,
            onPress: () => routeur.go(destinationClasse),
          ),
        ],
      ),
    );
  }
}
