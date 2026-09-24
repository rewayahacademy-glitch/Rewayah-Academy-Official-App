import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/seance_famille/port_seances_famille.dart';
import '../../core/seance_famille/seance_famille.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../accueil_famille/ancre_horloge_serveur.dart';
import 'carte_seance_classe.dart';
import 'contexte_classe.dart';

/// La Classe d'un eleve du foyer, vue par le tuteur
/// (`/tuteur/classes/:classeId?eleve=`, lot C, sous-paquet 2).
///
/// Maquette M1 (planche « Observation tuteur », telephone) ; tablette large
/// et bureau derives en deux colonnes de l'Accueil bureau (manifeste,
/// section 2) :
///
/// - en-tete : nom de la classe, « prenom · Sayyid prenom », disque retour
///   vers l'Accueil, cloche de la coquille ;
/// - la carte de classe : enseignant, parcours, prochaine seance,
///   observation ;
/// - UNE carte groupee de rubriques a filets : Planning, Travail a preparer,
///   Bibliotheque, Progression, Historique.
///
/// **Aucune entree « Rejoindre »** : la salle `/tc/classe` n'est pas ouverte
/// au tuteur ; il observe par l'entree du lot O, selon la politique serveur.
class ClasseTuteurPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const ClasseTuteurPage({
    required this.classeId,
    super.key,
    this.eleveId,
    this.horloge = DateTime.now,
  });

  /// La classe (groupe) affichee.
  final String classeId;

  /// L'eleve concerne (`?eleve=`), s'il est donne.
  final String? eleveId;

  /// L'horloge de l'appareil, pour mesurer un ecoulement seulement.
  final DateTime Function() horloge;

  @override
  ConsumerState<ClasseTuteurPage> createState() => _ClasseTuteurPageEtat();
}

class _ClasseTuteurPageEtat extends ConsumerState<ClasseTuteurPage>
    with AncreHorlogeServeur<ClasseTuteurPage> {
  @override
  DateTime Function() get horlogeAppareil => widget.horloge;

  @override
  Widget build(BuildContext context) {
    final DateTime? maintenant = maintenantServeur();
    return CadreClasse(
      cle: (classeId: widget.classeId, eleveId: widget.eleveId),
      sousTitre: (ContexteClasse c) => t.classe.sousTitre(
        prenom: c.eleve.prenom,
        enseignant: LibellesGroupe.enseignantNomme(c.classe.classe.enseignant),
      ),
      onRetour: () => GoRouter.of(context).go(Routes.tuteurAccueil),
      construire: (ContexteClasse c) =>
          _Contenu(contexte: c, maintenantServeurUtc: maintenant),
    );
  }
}

/// Le corps de la Classe, une fois la classe et l'eleve connus.
class _Contenu extends ConsumerWidget {
  const _Contenu({required this.contexte, required this.maintenantServeurUtc});

  final ContexteClasse contexte;
  final DateTime? maintenantServeurUtc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String eleveId = contexte.eleveId;
    final String classeId = contexte.classeId;
    final GoRouter routeur = GoRouter.of(context);

    // La prochaine seance de l'eleve (K2). Un eleve n'a qu'une classe active a
    // la fois (`groupe_membres_actif_uidx`, `0017`) ; une seance qui se dit
    // d'une AUTRE classe est ecartee, une seance sans classe connue
    // (DB-CRS-13) est gardee.
    final AsyncValue<SeanceFamille?> lue = ref.watch(
      prochaineSeanceProvider(eleveId),
    );
    final String? classeDeLaSeance = lue.value?.groupeId;
    final AsyncValue<SeanceFamille?> seance =
        classeDeLaSeance != null && classeDeLaSeance != classeId
        ? const AsyncValue<SeanceFamille?>.data(null)
        : lue;

    final Gabarit gabarit = AppGabarit.de(context);
    final bool large = classeEnColonnes(context);

    final Widget carte = CarteSeanceClasse(
      contexte: contexte,
      seance: seance,
      maintenantServeurUtc: maintenantServeurUtc,
      compact: gabarit == Gabarit.mobile,
      onReessayerSeance: () => ref.invalidate(prochaineSeanceProvider(eleveId)),
    );

    final Widget rubriques = GroupeReglages(
      lignes: <LigneRubrique>[
        for (final (String segment, AppIcon icone, String libelle)
            in <(String, AppIcon, String)>[
              ('planning', AppIcons.journee, t.classe.planning),
              ('travail', AppIcons.lecon, t.classe.travail),
              ('ressources', AppIcons.bibliotheque, t.classe.ressources),
              ('progression', AppIcons.suivi, t.classe.progression),
            ])
          LigneRubrique(
            icone: icone,
            libelle: libelle,
            onPress: () => routeur.go(cheminClasse(classeId, eleveId, segment)),
          ),
        // L'Historique filtre sur l'eleve et la classe (mapping 7.1, ligne
        // 26) : la destination Historique de la coquille, pas une copie.
        LigneRubrique(
          icone: AppIcons.historique,
          libelle: t.classe.historique,
          onPress: () => routeur.go(
            Uri(
              path: Routes.tuteurSuivi,
              queryParameters: <String, String>{
                'eleve': eleveId,
                'classe': classeId,
              },
            ).toString(),
          ),
        ),
      ],
    );

    if (!large) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[carte, Ecart.vLg, rubriques],
      );
    }
    // Tablette large et bureau : deux colonnes, environ 62 / 38, comme
    // l'Accueil bureau (V2 A) ; la carte a gauche, les rubriques a droite.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(flex: 62, child: carte),
        Ecart.hLg,
        Expanded(flex: 38, child: rubriques),
      ],
    );
  }
}
