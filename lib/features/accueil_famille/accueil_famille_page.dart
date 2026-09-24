import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Comme partout ailleurs : le type d'une famille de providers n'est pas exporte
// par l'entree principale de Riverpod 3, il vit dans `misc.dart`.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/appairage/service_avatar.dart';
import '../../core/capacites/port_classes_foyer.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/presence/service_presence.dart';
import '../../core/presence/vue_presence.dart';
import '../../core/router/routes.dart';
import '../../core/seance_famille/port_seances_famille.dart';
import '../../core/seance_famille/seance_famille.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_parcours/port_travail_a_venir.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/selecteur_profils.dart';
import '../../core/widgets/skeleton.dart';
import 'ancre_horloge_serveur.dart';
import 'bandeau_blocage.dart';
import 'bloc_seance.dart';
import 'carte_classe_seance.dart';
import 'ligne_derniere_seance.dart';
import 'liste_preparation.dart';

/// La classe courante d'un eleve (contrat K6), `null` s'il n'en a pas.
///
/// Un eleve n'a qu'une classe active a la fois (`groupe_membres_actif_uidx`,
/// `0017`) : la premiere suffit.
final FutureProviderFamily<ClasseFoyer?, String> classeDeLEleveProvider =
    FutureProvider.family<ClasseFoyer?, String>((
      Ref ref,
      String eleveId,
    ) async {
      final List<ClasseFoyer> classes = await ref
          .watch(portClassesFoyerProvider)
          .classesDe(eleveId);
      return classes.isEmpty ? null : classes.first;
    });

/// La cle de lecture d'une presence : une seance, un eleve.
typedef ClePresenceEleve = ({String seanceId, String eleveId});

/// La presence d'un eleve a une seance passee, lue **une fois** (une seance
/// close ne change plus d'etat toutes les vingt secondes, contrairement a la
/// salle). `null` : presence illisible ou absente, affichee comme inconnue.
final FutureProviderFamily<PresenceParticipant?, ClePresenceEleve>
presenceEleveProvider =
    FutureProvider.family<PresenceParticipant?, ClePresenceEleve>((
      Ref ref,
      ClePresenceEleve cle,
    ) async {
      final List<PresenceParticipant>? lignes = await ref
          .watch(servicePresenceProvider)
          .presence(cle.seanceId);
      return maPresence(lignes, cle.eleveId);
    });

/// L'Accueil du tuteur (`/tuteur`, lot C, sous-paquet 1).
///
/// Ordre de lecture du mandat et des maquettes V1 / V2 : titre et
/// notifications (portes par la coquille), selecteur des profils eleves,
/// prochaine seance du profil selectionne, blocage eventuel, « Avant le
/// prochain cours », « Derniere seance ».
///
/// Trois compositions, un seul arbre de donnees (manifeste : seul le format
/// change la composition, jamais le theme) :
///
/// - telephone : une colonne, cartes separees (V1) ;
/// - tablette : la carte classe, puis une carte groupee (V2 B) ;
/// - bureau : deux colonnes, carte classe a gauche, carte groupee a droite
///   (V2 A, C).
///
/// **Ce que l'ecran ne fait plus**, et ou la fonction vit desormais (une
/// fonction = un seul endroit) : « Assister » (l'observation se fait depuis
/// la classe, lot O) ; « Gerer le foyer » et les dates d'acces (Foyer, lot B ;
/// Compte, lot E) ; le lien « Mes groupes » (remplace par « Voir la
/// classe »).
class AccueilFamillePage extends ConsumerStatefulWidget {
  /// Cree l'Accueil.
  const AccueilFamillePage({super.key, this.horloge = DateTime.now});

  /// L'horloge de l'appareil, **pour mesurer un ecoulement seulement** :
  /// l'instant affiche est l'instant serveur lu a l'ouverture, avance du
  /// temps ecoule depuis cette lecture. Injectable pour les tests.
  final DateTime Function() horloge;

  @override
  ConsumerState<AccueilFamillePage> createState() => _AccueilFamillePageEtat();
}

class _AccueilFamillePageEtat extends ConsumerState<AccueilFamillePage>
    with AncreHorlogeServeur<AccueilFamillePage> {
  @override
  DateTime Function() get horlogeAppareil => widget.horloge;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ProfilEleveFoyer>> profils = ref.watch(
      profilsElevesFoyerProvider,
    );
    final DateTime? maintenant = maintenantServeur();

    return PageShell(
      titre: t.tuteur.accueil.titre,
      child: BlocAsynchrone<List<ProfilEleveFoyer>>(
        valeur: profils,
        squelette: const _Squelette(),
        onReessayer: () => ref.invalidate(elevesDuFoyerProvider),
        vide: EtatSysteme(
          nature: NatureEtat.aucunResultat,
          titre: t.tuteur.accueil.foyerVideTitre,
          phrase: t.tuteur.accueil.foyerVidePhrase,
          libelleAction: t.tuteur.accueil.ajouterProfil,
          onAction: () => GoRouter.of(context).go(Routes.tuteurAjouterEnfant),
        ),
        construire: (List<ProfilEleveFoyer> liste) =>
            _Contenu(profils: liste, maintenantServeurUtc: maintenant),
      ),
    );
  }
}

/// La forme de l'Accueil pendant la premiere lecture.
class _Squelette extends StatelessWidget {
  const _Squelette();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Skeleton(hauteur: AppSpacing.respiration + AppSpacing.xxxl),
      Ecart.vXl,
      Skeleton(hauteur: AppSpacing.respiration * 4),
    ],
  );
}

/// L'Accueil, une fois les profils lus.
class _Contenu extends ConsumerWidget {
  const _Contenu({required this.profils, required this.maintenantServeurUtc});

  final List<ProfilEleveFoyer> profils;
  final DateTime? maintenantServeurUtc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Gabarit gabarit = AppGabarit.de(context);
    final bool compact = gabarit == Gabarit.mobile;
    final ProfilEleveFoyer profil = profilRetenu(
      profils,
      ref.watch(selectionEleveProvider),
    )!;
    final String eleveId = profil.eleveId;
    final GoRouter routeur = GoRouter.of(context);

    final AsyncValue<ClasseFoyer?> classe = ref.watch(
      classeDeLEleveProvider(eleveId),
    );
    final AsyncValue<SeanceFamille?> prochaine = ref.watch(
      prochaineSeanceProvider(eleveId),
    );
    final AsyncValue<SeanceFamille?> derniere = ref.watch(
      derniereSeanceProvider(eleveId),
    );
    final AsyncValue<List<AppareilAppaire>> appareils = ref.watch(
      appareilsDuFoyerProvider,
    );
    final String? groupeId = classe.value?.classe.groupeId;
    final AsyncValue<List<SlotAction>?>? travail = groupeId == null
        ? null
        : ref.watch(
            travailAVenirProvider((groupeId: groupeId, studentId: eleveId)),
          );
    final String? derniereId = derniere.value?.seanceId;
    final AsyncValue<PresenceParticipant?>? presence = derniereId == null
        ? null
        : ref.watch(
            presenceEleveProvider((seanceId: derniereId, eleveId: eleveId)),
          );

    final Widget selecteur = SelecteurProfils(
      profils: <ProfilSelectionnable>[
        for (final ProfilEleveFoyer p in profils) _selectionnable(ref, p),
      ],
      selectionId: eleveId,
      onSelection: (String id) =>
          ref.read(selectionEleveProvider.notifier).choisir(id),
      onAjouter: () => routeur.go(Routes.tuteurAjouterEnfant),
    );

    final bool sansClasse =
        classe.hasValue &&
        classe.value == null &&
        prochaine.hasValue &&
        prochaine.value == null;
    if (sansClasse) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          selecteur,
          Ecart.vXl,
          EtatSysteme(
            nature: NatureEtat.aucunResultat,
            titre: t.tuteur.accueil.sansClasseTitre(prenom: profil.prenom),
            phrase: t.tuteur.accueil.sansClassePhrase(prenom: profil.prenom),
            libelleAction: t.classe.catalogue,
            onAction: () => routeur.go(
              Uri(
                path: Routes.tuteurClassesCatalogue,
                queryParameters: <String, String>{'eleve': eleveId},
              ).toString(),
            ),
          ),
        ],
      );
    }

    final bool inscrit = classe.value != null || prochaine.value != null;
    final bool blocage =
        inscrit &&
        appareils.hasValue &&
        !appareils.hasError &&
        aucunAppareilPret(appareils.requireValue, eleveId);

    final String? cleAvatar = profil.cleAvatar;
    final Widget carte = CarteClasseSeance(
      profil: profil,
      urlPhotoEleve: cleAvatar == null
          ? null
          : ref.watch(avatarUrlProvider(cleAvatar)).value,
      classe: classe,
      seance: prochaine,
      maintenantServeurUtc: maintenantServeurUtc,
      compact: compact,
      onVoirClasse: (String id) =>
          routeur.go(Routes.classePour(id, eleveId: eleveId)),
      onReessayerClasse: () => ref.invalidate(classeDeLEleveProvider(eleveId)),
      onReessayerSeance: () => ref.invalidate(prochaineSeanceProvider(eleveId)),
    );

    final Widget? bandeau = blocage
        ? BandeauBlocage(
            prenom: profil.prenom,
            compact: compact,
            onConnecter: () => routeur.go(Routes.appairerPour(eleveId)),
          )
        : null;

    final Widget preparation = ListePreparation(
      travail: travail,
      onVoirTout: groupeId == null
          ? null
          : () => routeur.go(
              Uri(
                path: Routes.classeSousPage(groupeId, 'travail'),
                queryParameters: <String, String>{'eleve': eleveId},
              ).toString(),
            ),
    );

    final Widget derniereSeance = LigneDerniereSeance(
      derniere: derniere,
      presence: presence,
      maintenantServeurUtc: maintenantServeurUtc,
      onVoirHistorique: () => routeur.go(
        Uri(
          path: Routes.tuteurSuivi,
          queryParameters: <String, String>{'eleve': eleveId},
        ).toString(),
      ),
      onDetails: (String seanceId) => routeur.go(Routes.seancePour(seanceId)),
      onReessayer: () => ref.invalidate(derniereSeanceProvider(eleveId)),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          selecteur,
          Ecart.vXl,
          carte,
          if (bandeau != null) ...<Widget>[Ecart.vLg, bandeau],
          Ecart.vLg,
          AppCard(marge: AppSpacing.lg, child: preparation),
          Ecart.vLg,
          AppCard(marge: AppSpacing.lg, child: derniereSeance),
        ],
      );
    }

    // Tablette et bureau : blocage, preparation et derniere seance dans UNE
    // carte groupee, sujets separes par un filet (decisions 1 ter, point 3).
    final Widget carteGroupee = AppCard(
      marge: AppSpacing.xxl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (bandeau != null) ...<Widget>[
            bandeau,
            Ecart.vXl,
            const FiletHorizontal(),
            Ecart.vXl,
          ],
          preparation,
          Ecart.vXl,
          const FiletHorizontal(),
          Ecart.vXl,
          derniereSeance,
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        selecteur,
        Ecart.vXl,
        if (gabarit == Gabarit.desktop)
          // Deux colonnes de hauteur egale, environ 62 / 38 (V2 A).
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(flex: 62, child: carte),
                Ecart.hLg,
                Expanded(flex: 38, child: carteGroupee),
              ],
            ),
          )
        else ...<Widget>[carte, Ecart.vLg, carteGroupee],
      ],
    );
  }

  /// Un profil du selecteur : prenom, portrait, et l'etat court calcule
  /// **par la meme fonction** que la carte ([AffichageSeance]).
  ProfilSelectionnable _selectionnable(WidgetRef ref, ProfilEleveFoyer p) {
    final AsyncValue<SeanceFamille?> seance = ref.watch(
      prochaineSeanceProvider(p.eleveId),
    );
    final String? cle = p.cleAvatar;
    final String? photo = cle == null
        ? null
        : ref.watch(avatarUrlProvider(cle)).value;
    final e = t.tuteur.accueil.etatCourt;

    if (seance.hasError) {
      return ProfilSelectionnable(
        id: p.eleveId,
        prenom: p.prenom,
        etat: e.illisible,
        urlPhoto: photo,
      );
    }
    if (!seance.hasValue) {
      return ProfilSelectionnable(
        id: p.eleveId,
        prenom: p.prenom,
        etat: t.commun.chargement,
        urlPhoto: photo,
      );
    }
    final SeanceFamille? prochaine = seance.value;
    if (prochaine == null) {
      return ProfilSelectionnable(
        id: p.eleveId,
        prenom: p.prenom,
        etat: e.aucune,
        urlPhoto: photo,
        point: PointStatut.neutre,
      );
    }
    final AffichageSeance affichage = AffichageSeance.depuis(
      prochaine,
      maintenantServeurUtc: maintenantServeurUtc,
    );
    return ProfilSelectionnable(
      id: p.eleveId,
      prenom: p.prenom,
      etat: affichage.etatCourt,
      urlPhoto: photo,
      point: affichage.point,
    );
  }
}
