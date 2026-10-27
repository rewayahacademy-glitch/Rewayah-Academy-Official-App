import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Comme partout ailleurs : le type d'une famille de providers n'est pas exporte
// par l'entree principale de Riverpod 3, il vit dans `misc.dart`.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/appairage/service_appairage.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_classes_foyer.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/fraicheur/classe_disparue.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';

/// La cle d'un ecran de classe : la classe de l'adresse, et l'eleve demande
/// (`?eleve=`) quand l'adresse le donne.
typedef CleClasse = ({String classeId, String? eleveId});

/// Une classe, vue pour **un** eleve du foyer.
@immutable
class ContexteClasse {
  /// Cree le contexte.
  const ContexteClasse({required this.eleve, required this.classe});

  /// L'eleve concerne.
  final ProfilEleveFoyer eleve;

  /// Sa classe (contrat K6).
  final ClasseFoyer classe;

  /// L'identifiant de la classe.
  String get classeId => classe.classe.groupeId;

  /// L'identifiant de l'eleve.
  String get eleveId => eleve.eleveId;
}

/// La classe de l'adresse et l'eleve du foyer qui y est inscrit.
///
/// **Un identifiant d'adresse est une demande, jamais une autorisation** :
/// l'eleve demande doit etre un profil du foyer (K1), et la classe doit etre
/// l'une des siennes selon le port (K6), que la RLS borne. Sans `?eleve=`,
/// le premier profil du foyer inscrit dans cette classe est retenu.
///
/// `null` : classe introuvable pour ce foyer (close, d'un autre foyer, ou
/// d'un autre eleve). Un port absent leve `CapaciteIndisponible`, et l'ecran
/// dit « pas encore disponible », jamais « introuvable ».
final FutureProviderFamily<ContexteClasse?, CleClasse> contexteClasseProvider =
    FutureProvider.family<ContexteClasse?, CleClasse>((
      Ref ref,
      CleClasse cle,
    ) async {
      final List<ProfilEleveFoyer> profils = await ref.watch(
        profilsElevesFoyerProvider.future,
      );
      final PortClassesFoyer port = ref.watch(portClassesFoyerProvider);
      final String? demande = cle.eleveId;
      for (final ProfilEleveFoyer profil in profils) {
        if (demande != null && profil.eleveId != demande) {
          continue;
        }
        final ClasseFoyer? classe = await port.classe(
          groupeId: cle.classeId,
          eleveId: profil.eleveId,
        );
        if (classe != null) {
          return ContexteClasse(eleve: profil, classe: classe);
        }
      }
      return null;
    });

/// Le nom d'une Classe a l'affichage : « Classe An-Nour » passe a la ligne
/// entre les mots, jamais dans « An- / Nour » (lecon 8, K-54). Voir
/// [traitsDUnionInsecables].
String nomClasseInsecable(String libelle) => traitsDUnionInsecables(libelle);

/// La ligne sous le titre d'une sous-page : « Classe An-Nour · Mariam ».
String sousTitreSousPage(ContexteClasse contexte) => LibellesGroupe.joindre(
  nomClasseInsecable(contexte.classe.classe.libelle),
  contexte.eleve.prenom,
);

/// Une adresse d'ecran de classe, avec l'eleve concerne.
String cheminClasse(String classeId, String eleveId, [String? segment]) => Uri(
  path: segment == null
      ? '${Routes.tuteurClasses}/$classeId'
      : Routes.classeSousPage(classeId, segment),
  queryParameters: <String, String>{'eleve': eleveId},
).toString();

/// Le cadre commun de la Classe et de ses sous-pages : en-tete a disque retour
/// (pages de niveau 2 et 3, aucune impasse), puis les etats de la lecture du
/// contexte, puis le contenu.
///
/// Etats, dans l'ordre : capacite absente (production tant que le port K6
/// n'est pas branche : « pas encore disponible », sans « Reessayer ») ;
/// chargement, chargement prolonge et echec (`BlocAsynchrone`) ; classe
/// introuvable (etat explique, retour a l'accueil) ; contenu. Le hors ligne
/// est porte par `PageShell` (bandeau) et par l'echec de bloc.
class CadreClasse extends ConsumerWidget {
  /// Cree le cadre.
  const CadreClasse({
    required this.cle,
    required this.onRetour,
    required this.construire,
    super.key,
    this.titre,
    this.sousTitre,
  });

  /// La classe et l'eleve demandes.
  final CleClasse cle;

  /// Le titre de la page ; `null` : le nom de la classe.
  final String? titre;

  /// La ligne sous le titre, une fois le contexte lu.
  final String Function(ContexteClasse contexte)? sousTitre;

  /// Le disque retour.
  final VoidCallback onRetour;

  /// Le contenu, une fois le contexte lu.
  final Widget Function(ContexteClasse contexte) construire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ligne 7 (27/10/2026) : la classe etait la, la relecture (veille de
    // fraicheur) ne la trouve plus : « Cette classe n'existe plus. », retour
    // a l'accueil du role.
    ref.listen<AsyncValue<ContexteClasse?>>(contexteClasseProvider(cle), (
      AsyncValue<ContexteClasse?>? avant,
      AsyncValue<ContexteClasse?> apres,
    ) {
      if (classeDisparue<ContexteClasse?>(
        avant,
        apres,
        presente: (ContexteClasse? c) => c != null,
      )) {
        revenirApresClasseDisparue(context, ref);
      }
    });
    final AsyncValue<ContexteClasse?> lecture = ref.watch(
      contexteClasseProvider(cle),
    );
    final ContexteClasse? contexte = lecture.value;
    final Object? erreur = lecture.error;

    final Widget corps;
    if (erreur is CapaciteIndisponible) {
      corps = EtatSysteme(
        nature: NatureEtat.indisponible,
        phrase: t.classe.indisponiblePhrase,
        dependance: erreur.dependance,
      );
    } else {
      corps = BlocAsynchrone<ContexteClasse?>(
        valeur: lecture,
        squelette: const _Squelette(),
        onReessayer: () {
          ref
            ..invalidate(elevesDuFoyerProvider)
            ..invalidate(contexteClasseProvider(cle));
        },
        vide: EtatSysteme(
          nature: NatureEtat.introuvable,
          titre: t.classe.introuvableTitre,
          phrase: t.classe.introuvablePhrase,
          onAction: () => GoRouter.of(context).go(Routes.tuteurAccueil),
        ),
        construire: (ContexteClasse? lu) => construire(lu!),
      );
    }

    return PageShell(
      titre:
          titre ??
          (contexte == null
              ? t.classe.titre
              : nomClasseInsecable(contexte.classe.classe.libelle)),
      sousTitre: contexte == null ? null : sousTitre?.call(contexte),
      onRetour: onRetour,
      child: corps,
    );
  }
}

/// Vrai a partir de 840 de large (tablette large et bureau) : les ecrans de
/// classe passent en colonnes (vraie version desktop, jamais une colonne de
/// telephone etiree).
bool classeEnColonnes(BuildContext context) =>
    AppGabarit.classe(MediaQuery.sizeOf(context).width).index >=
    ClasseLargeur.etendue.index;

/// La composition d'une sous-page de classe.
///
/// Telephone et tablette etroite : une colonne, les precisions sous le
/// contenu. A partir de 840 : le contenu a gauche (environ 62 %), les
/// precisions a droite (environ 38 %), comme la Classe ; sans precisions, le
/// contenu garde une largeur de lecture (`AppPage.largeurLecture`).
class ColonnesSousPage extends StatelessWidget {
  /// Cree la composition.
  const ColonnesSousPage({required this.principal, super.key, this.precisions});

  /// Le contenu de la rubrique.
  final Widget principal;

  /// Ce qu'il faut savoir a cote : limites, fuseau, dependances dites.
  final Widget? precisions;

  @override
  Widget build(BuildContext context) {
    final Widget? aCote = precisions;
    if (!classeEnColonnes(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          principal,
          if (aCote != null) ...<Widget>[Ecart.vLg, aCote],
        ],
      );
    }
    if (aCote == null) {
      return Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurLecture),
          child: principal,
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(flex: 62, child: principal),
        Ecart.hLg,
        Expanded(flex: 38, child: aCote),
      ],
    );
  }
}

/// Une lecture de sous-page de classe : capacite absente (phrase propre a la
/// rubrique, sans « Reessayer »), puis les etats de `BlocAsynchrone`
/// (squelette, chargement prolonge, echec borne, vide, contenu).
class LectureClasse<T> extends StatelessWidget {
  /// Cree la lecture.
  const LectureClasse({
    required this.valeur,
    required this.phraseIndisponible,
    required this.construire,
    required this.onReessayer,
    super.key,
    this.vide,
  });

  /// La valeur lue.
  final AsyncValue<T> valeur;

  /// Ce que la rubrique dit tant que sa source n'est pas branchee.
  final String phraseIndisponible;

  /// Le contenu.
  final Widget Function(T valeur) construire;

  /// Relance la lecture.
  final VoidCallback onReessayer;

  /// L'etat vide.
  final Widget? vide;

  @override
  Widget build(BuildContext context) {
    final Object? erreur = valeur.error;
    if (erreur is CapaciteIndisponible) {
      return EtatSysteme(
        nature: NatureEtat.indisponible,
        phrase: phraseIndisponible,
        dependance: erreur.dependance,
      );
    }
    return BlocAsynchrone<T>(
      valeur: valeur,
      squelette: const Skeleton.liste(),
      onReessayer: onReessayer,
      vide: vide,
      construire: construire,
    );
  }
}

/// La forme d'un ecran de classe pendant la premiere lecture.
class _Squelette extends StatelessWidget {
  const _Squelette();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Skeleton(hauteur: AppSpacing.respiration * 4),
      Ecart.vLg,
      Skeleton(hauteur: AppSpacing.respiration * 2),
    ],
  );
}
