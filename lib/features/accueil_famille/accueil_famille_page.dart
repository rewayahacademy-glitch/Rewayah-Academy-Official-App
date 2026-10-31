import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Comme partout ailleurs : le type d'une famille de providers n'est pas exporte
// par l'entree principale de Riverpod 3, il vit dans `misc.dart`.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';

import '../../core/admission/profils_demande.dart';
import '../../core/appairage/service_appairage.dart';
import '../../core/appairage/service_avatar.dart';
import '../../core/capacites/port_classes_foyer.dart';
import '../../core/domain/enums.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/presence/service_presence.dart';
import '../../core/presence/vue_presence.dart';
import '../../core/router/routes.dart';
import '../../core/seance_famille/port_seances_famille.dart';
import '../../core/seance_famille/seance_famille.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart' show EnseignantVM;
import '../../core/tc_horloge/horloge_vivante.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/tc_parcours/port_travail_a_venir.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/grille_bento.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/selecteur_profils.dart';
import '../../core/widgets/skeleton.dart';
import '../acces_finance/carte_acces_finance.dart';
import '../classe_tuteur/rejoindre_avec_eleve.dart';
import '../consentements/consentement_observation_page.dart';
import '../parcours_offres/bloc_parcours.dart';
import '../presentation_tuteur/demandes_presentation_page.dart'
    show CarteDemandePresentation;
import '../suivi_demandes/carte_suivi_demandes.dart';
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
/// Une seule composition, la grille Bento partagee (BENTO-2, DASH_STRATEGIE.md
/// §3.4) : une colonne sur telephone, tuiles de tailles variees au-dela. Seul
/// le format change la composition, jamais le theme.
///
/// **Ce que l'ecran ne fait plus**, et ou la fonction vit desormais (une
/// fonction = un seul endroit) : « Assister » (l'observation se fait depuis
/// la classe, lot O) ; « Gerer le foyer » et les dates d'acces (Foyer, lot B ;
/// Compte, lot E) ; le lien « Mes groupes » (remplace par « Voir la
/// classe »).
class AccueilFamillePage extends ConsumerStatefulWidget {
  /// Cree l'Accueil.
  const AccueilFamillePage({super.key, this.horloge = DateTime.now});

  /// La cle de la carte des finances du profil choisi (lot F1).
  static const Key financesKey = Key('tuteur.accueil.finances');

  /// La tuile « Rejoindre la salle avec {prenom} », salle ouverte (D6, R8).
  static const Key rejoindreKey = Key('tuteur.accueil.rejoindre');

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
    // Admission, lot C : a la premiere ouverture apres l'acceptation, les
    // enfants de la demande recoivent leur profil ; le foyer se relit.
    ref.listen<AsyncValue<int>>(profilsDemandeCreesProvider, (
      AsyncValue<int>? _,
      AsyncValue<int> lies,
    ) {
      if ((lies.value ?? 0) > 0) {
        ref.invalidate(elevesDuFoyerProvider);
      }
    });

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
          const CarteSuiviDemandes(),
          const CarteDemandePresentation(),
          // L9 : les comptes d'avant l'accord des visites y sont conduits.
          const InviteConsentementObservation(),
          // Entree transitoire du questionnaire (revue C, M3 ; demande C-7) :
          // gardee tant que Fiche > Inscription (lot B) n'est pas integree.
          // Silencieuse quand aucun apprenant n'a de parcours a suivre.
          const BlocParcours(),
          EtatSysteme(
            nature: NatureEtat.aucunResultat,
            titre: t.tuteur.accueil.sansClasseTitre(prenom: profil.prenom),
            phrase: t.tuteur.accueil.sansClassePhrase(
              quePrenom: queDevant(profil.prenom),
            ),
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

    // D6 et R8 (24/10/2026) : salle ouverte ou seance en direct, la tache
    // immediate est d'y entrer ; le bouton prend la place du blocage en tete
    // (un seul bouton plein, jamais un bouton dans la carte-lien).
    final SeanceFamille? seanceOuverte = prochaine.value;
    final bool rejoindre =
        seanceOuverte != null &&
        !prochaine.hasError &&
        salleRejoignable(
          AffichageSeance.depuis(
            seanceOuverte,
            maintenantServeurUtc: maintenantServeurUtc,
          ).etat,
        );
    // Concierge (a), tuteur : sans seance rejoignable connue, l'horloge de la
    // Classe (tiree des creneaux) ouvre la porte ; le concierge rend la seance.
    final SessionClockVM? horlogeClasse = groupeId == null || rejoindre
        ? null
        : ref.watch(horlogeClasseVivanteProvider(groupeId)).value;
    // Defaut du 30/10/2026 : le cours du moment d'une Classe sans seance en
    // base (nee pendant son creneau) passe avant la prochaine seance creee,
    // celle de la semaine suivante ; la carte le dit, l'horloge du serveur
    // donne ses bornes.
    final SeanceFamille? coursDuMoment = coursSansSeanceAvant(
      horlogeClasse,
      prochaine: prochaine.value,
      eleveId: eleveId,
      groupeId: groupeId,
      enseignant: classe.value?.classe.enseignant,
    );
    final AsyncValue<SeanceFamille?> seanceAffichee = coursDuMoment == null
        ? prochaine
        : AsyncValue<SeanceFamille?>.data(coursDuMoment);

    final String? cleAvatar = profil.cleAvatar;
    final Widget carte = CarteClasseSeance(
      profil: profil,
      urlPhotoEleve: cleAvatar == null
          ? null
          : ref.watch(avatarUrlProvider(cleAvatar)).value,
      classe: classe,
      seance: seanceAffichee,
      maintenantServeurUtc: maintenantServeurUtc,
      compact: compact,
      onVoirClasse: (String id) =>
          routeur.go(Routes.classePour(id, eleveId: eleveId)),
      onReessayerClasse: () => ref.invalidate(classeDeLEleveProvider(eleveId)),
      onReessayerSeance: () => ref.invalidate(prochaineSeanceProvider(eleveId)),
    );

    final Widget? bandeau = rejoindre
        ? AppCard(
            key: AccueilFamillePage.rejoindreKey,
            marge: compact ? AppSpacing.lg : AppSpacing.xxl,
            child: BoutonRejoindreAvecEleve(
              seance: seanceOuverte,
              eleve: profil,
            ),
          )
        : groupeId != null && classeRejoignableSansSeance(horlogeClasse)
        ? AppCard(
            key: AccueilFamillePage.rejoindreKey,
            marge: compact ? AppSpacing.lg : AppSpacing.xxl,
            child: BoutonRejoindreClasseAvecEleve(
              groupeId: groupeId,
              sessionId: horlogeClasse!.sessionId,
              eleve: profil,
            ),
          )
        : blocage
        ? BandeauBlocage(
            prenom: profil.prenom,
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

    // Lot F1 : les finances du profil choisi en un geste (solde, prochain
    // debit, ce qu'il reste a financer). Aucun chiffre ici : la fiche
    // Finances est la seule lecture, et dit « pas encore publie » tant que
    // le serveur ne rend rien (FI-BR-03).
    final Widget finances = CarteAccesFinance(
      key: AccueilFamillePage.financesKey,
      titre: t.tuteur.accueil.financesTitre(
        dePrenom: deDevant(profil.prenom, cle: 'tuteur.accueil.financesTitre'),
      ),
      phrase: t.tuteur.accueil.financesPhrase,
      onPress: () => routeur.go(Routes.ficheEleveSousPage(eleveId, 'finances')),
    );

    // BENTO-2 : la grille Bento partagee, disposition de DASH_STRATEGIE.md
    // §3.4. Le blocage, s'il existe, d'abord et en large ; la classe et sa
    // prochaine seance, puis « Avant le prochain cours », en grandes tuiles
    // cote a cote sur quatre colonnes ; la derniere seance en large. Chaque
    // tuile garde la hauteur de son contenu ; sur telephone, une colonne.
    // BENTO-2b : cote a cote seulement si chaque moitie offre
    // [largeurMinCarteClasse] x echelle du texte (grille de 736 px x echelle,
    // ecran de 864 px a texte 100 %) ; sinon (tablette de 600 a 863 px,
    // texte agrandi) la carte et « Avant le prochain cours » passent en
    // pleine largeur, comme avant BENTO-2. La ligne « 18:10 | Duree 45 min »
    // se protege en plus elle-meme (BENTO-2c, `BlocSeance`).
    final double marge = compact ? AppSpacing.lg : AppSpacing.xxl;
    final double echelle = MediaQuery.textScalerOf(context).scale(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        selecteur,
        Ecart.vXl,
        const CarteSuiviDemandes(),
        const CarteDemandePresentation(),
        // L9 : les comptes d'avant l'accord des visites y sont conduits.
        const InviteConsentementObservation(),
        LayoutBuilder(
          builder: (BuildContext _, BoxConstraints contraintes) {
            final bool coteACote =
                (contraintes.maxWidth - GrilleBento.ecart) / 2 >=
                largeurMinCarteClasse * math.max(1, echelle);
            final EtendueBento? pleine = coteACote
                ? null
                : const EtendueBento(4, 1);
            return GrilleBento(
              hauteurContenu: true,
              tuiles: <TuileBento>[
                if (bandeau != null)
                  TuileBento(
                    etendue: EtendueBento.large,
                    etendueLarge: const EtendueBento(4, 1),
                    child: bandeau,
                  ),
                TuileBento(
                  etendue: EtendueBento.grande,
                  etendueLarge: pleine,
                  child: carte,
                ),
                TuileBento(
                  etendue: EtendueBento.grande,
                  etendueLarge: pleine,
                  child: AppCard(marge: marge, child: preparation),
                ),
                TuileBento(
                  etendue: EtendueBento.large,
                  etendueLarge: const EtendueBento(4, 1),
                  child: AppCard(marge: marge, child: derniereSeance),
                ),
                // Pleine largeur, apres la derniere seance : jamais cote a
                // cote avec une carte de meme taille.
                TuileBento(
                  etendue: EtendueBento.large,
                  etendueLarge: const EtendueBento(4, 1),
                  child: finances,
                ),
              ],
            );
          },
        ),
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
      enDirect: affichage.etatPastille == EtatPastilleSeance.enDirect,
      annulee: affichage.etatPastille == EtatPastilleSeance.annulee,
    );
  }
}

/// Le cours du moment d'une Classe, tire de son horloge ([horloge], lue sur
/// le serveur par `horloge_classe`), quand sa seance n'existe pas encore et
/// qu'il passe avant [prochaine] (defaut du 30/10/2026). `null` sinon : la
/// carte garde la prochaine seance creee.
///
/// La seance rendue n'a pas d'identifiant (`seanceId` vide) : la carte ne
/// fait que l'afficher ; « Rejoindre » passe par l'horloge et le concierge
/// (`BoutonRejoindreClasseAvecEleve`).
SeanceFamille? coursSansSeanceAvant(
  SessionClockVM? horloge, {
  required SeanceFamille? prochaine,
  required String eleveId,
  required String? groupeId,
  EnseignantVM? enseignant,
}) {
  if (horloge == null || horloge.sessionId != null) return null;
  if (prochaine != null && !horloge.debutUtc.isBefore(prochaine.debutUtc)) {
    return null;
  }
  return SeanceFamille(
    seanceId: '',
    eleveId: eleveId,
    groupeId: groupeId,
    debutUtc: horloge.debutUtc,
    finPrevueUtc: horloge.finPrevueUtc,
    statutServeur: StatutSeance.planifiee,
    fenetre: FenetreSeance(
      debutUtc: horloge.debutUtc,
      finPrevueUtc: horloge.finPrevueUtc,
      fenetreAcces: horloge.fenetreAcces,
      graceApresFin: horloge.graceApresFin,
    ),
    heureFoyer: horloge.horlogeUtilisateur,
    heureGroupe: horloge.horlogeContrepartie,
    enseignant:
        prochaine?.enseignant ??
        EnseignantSeance(
          prenom: enseignant?.nomAffichage ?? '',
          titre: enseignant?.titre,
          clePhoto: enseignant?.photoUrlOuCle,
          pays: enseignant?.pays,
        ),
  );
}
