import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Comme partout ailleurs : le type d'une famille de providers n'est pas exporte
// par l'entree principale de Riverpod 3, il vit dans `misc.dart`.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/port_reponse_presentation.dart'
    show demandesPresentationProvider;
import '../../core/accueil/signaux_accueils.dart' show SignalAccueil;
import '../../core/accueil/signaux_famille.dart';
import '../../core/admission/profils_demande.dart';
import '../../core/appairage/service_appairage.dart';
import '../../core/capacites/consentements_supabase.dart'
    show accordsTitulaireProvider;
import '../../core/capacites/port_classes_foyer.dart';
import '../../core/capacites/port_partage_pedagogique.dart'
    show CompteRenduFamille;
import '../../core/domain/enums.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/mouvement/bascule_etat.dart';
import '../../core/offres/offre_horaire.dart';
import '../../core/offres/port_suivi_demandes.dart'
    show portSuiviDemandesProvider, suiviDemandesProvider;
import '../../core/offres/service_offres.dart'
    show
        offresCompatiblesProvider,
        parcoursFoyerProvider,
        reglesAcademieProvider;
import '../../core/photos/photo_personne.dart' show photoPersonneProvider;
import '../../core/presence/service_presence.dart';
import '../../core/presence/vue_presence.dart';
import '../../core/router/routes.dart';
import '../../core/seance_famille/port_seances_famille.dart';
import '../../core/seance_famille/seance_famille.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart' show EnseignantVM;
import '../../core/tc_horloge/horloge_vivante.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/tc_parcours/port_travail_a_venir.dart';
import '../../core/theme/app_delais.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/fondu_contenu_profil.dart';
import '../../core/widgets/grille_bento.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/lumiere_autour.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/selecteur_profils.dart';
import '../../core/widgets/skeleton.dart';
import '../acces_finance/acces_finance.dart'
    show BandeauPlace, OuvertureSeances, accesEleveProvider, ouvertureSeances;
import '../acces_finance/carte_acces_finance.dart';
import '../attente_classe/carte_suivi_attente.dart';
import '../attente_classe/suivi_attente_page.dart' show CheminsAttente;
import '../classe_tuteur/rejoindre_avec_eleve.dart';
import '../consentements/consentement_observation_page.dart';
import '../foyer/foyer_second_adulte.dart';
import '../foyer/invitation_conjoint.dart' show invitationRecueProvider;
import '../presentation_tuteur/demandes_presentation_page.dart'
    show CarteDemandePresentation;
import '../suivi_demandes/carte_suivi_demandes.dart';
import '../suivi_foyer/bloc_compte_rendu.dart' show compteRenduFamilleProvider;
import 'ancre_horloge_serveur.dart';
import 'bandeau_blocage.dart';
import 'bloc_seance.dart';
import 'carte_classe_seance.dart';
import 'carte_horaire.dart';
import 'feuille_autre_appareil.dart';
import 'ligne_bibliotheque_classe.dart';
import 'ligne_derniere_seance.dart';
import 'liste_preparation.dart';
import 'parcours_du_profil_choisi.dart';
import 'salle_rejoignable.dart';

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
  const AccueilFamillePage({
    super.key,
    this.horloge = DateTime.now,
    this.onOuvrirEspaceEleve,
    this.titulaireId,
  });

  /// La cle de la carte des finances du profil choisi (lot F1).
  static const Key financesKey = Key('tuteur.accueil.finances');

  /// L'entree vers l'espace d'eleve du tuteur qui suit aussi des cours
  /// (ONBOARDING-TUTEUR, 09/11/2026).
  static const Key espaceEleveKey = Key('tuteur.accueil.espaceEleve');

  /// Le lien discret « Utiliser un autre appareil » du titulaire sans appareil
  /// jumele (jamais une alerte).
  static const Key autreAppareilKey = Key('tuteur.accueil.autreAppareil');

  /// Le squelette de la page, tant que les lectures de la porte ne sont pas
  /// toutes arrivees.
  static const Key squeletteKey = Key('tuteur.accueil.squelette');

  /// La tuile « Rejoindre la salle avec {prenom} », salle ouverte (D6, R8).
  static const Key rejoindreKey = Key('tuteur.accueil.rejoindre');

  /// Ouvre l'espace d'eleve du tuteur qui suit aussi des cours. Nul : pas de
  /// lien (aucune action inerte, D9). Le routeur le donne quand la capacite
  /// « eleve autonome » est servie (`AccueilFamilleRelie`).
  final VoidCallback? onOuvrirEspaceEleve;

  /// L'identifiant du profil eleve du titulaire (le sien). Le lien « Ouvrir
  /// mon espace eleve » ne se montre que sous son profil, jamais sous celui
  /// d'un enfant (ACCUEIL-TUTEUR-UNE-PORTE, 09/11/2026).
  final String? titulaireId;

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
    // L'invitation au forfait famille se glisse en tete quand elle existe :
    // elle fait partie de la meme porte que le reste (un seul squelette).
    final bool invitationArrivee = _arrivee(ref.watch(invitationRecueProvider));
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // N2 (FA2) : une invitation au forfait famille attend la reponse,
          // en tete, meme quand le foyer est encore vide.
          if (invitationArrivee)
            AlertesSecondAdulte(
              aller: (String chemin) => GoRouter.of(context).go(chemin),
              avecReprise: false,
            ),
          BlocAsynchrone<List<ProfilEleveFoyer>>(
            // Tant que l'invitation n'est pas arrivee : l'attente, pas le vide.
            valeur: invitationArrivee
                ? profils
                : const AsyncValue<List<ProfilEleveFoyer>>.loading(),
            squelette: const _Squelette(),
            onReessayer: () => ref.invalidate(elevesDuFoyerProvider),
            vide: EtatSysteme(
              nature: NatureEtat.aucunResultat,
              titre: t.tuteur.accueil.foyerVideTitre,
              phrase: t.tuteur.accueil.foyerVidePhrase,
              libelleAction: t.tuteur.accueil.ajouterProfil,
              onAction: () =>
                  GoRouter.of(context).go(Routes.tuteurAjouterEnfant),
            ),
            construire: (List<ProfilEleveFoyer> liste) => _Contenu(
              profils: liste,
              maintenantServeurUtc: maintenant,
              onOuvrirEspaceEleve: widget.onOuvrirEspaceEleve,
              titulaireId: widget.titulaireId,
            ),
          ),
        ],
      ),
    );
  }
}

/// La forme de l'Accueil pendant la premiere lecture.
class _Squelette extends StatelessWidget {
  const _Squelette() : super(key: AccueilFamillePage.squeletteKey);

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

/// La lecture est « arrivee » : une valeur, ou un echec. Jamais l'attente.
bool _arrivee(AsyncValue<Object?> v) => v.hasValue || v.hasError;

/// DEFAUT DU 11/11/2026 (directeur) : a la premiere arrivee ou apres un
/// rafraichissement, l'Accueil montrait un squelette, puis « aucune classe »,
/// puis les cartes de demande, puis le vrai contenu, chaque bloc rendant son
/// etat intermediaire des qu'il avait repondu.
///
/// **Une seule porte.** Tant que les lectures qui decident de la forme de
/// l'ecran pour le profil choisi ne sont pas arrivees, un seul squelette ;
/// ensuite UN rendu complet, qui apparait une seule fois en fondu court
/// (`BasculeEtat`, mouvement reduit respecte). Au changement de profil
/// l'affichage precedent reste jusqu'a l'arrivee des nouvelles lectures (le
/// selecteur, lui, suit le geste tout de suite) ; un rafraichissement qui
/// garde sa valeur ne ramene jamais le squelette. Aucune lecture de plus : ce
/// sont celles des blocs, regroupees.
class _Contenu extends ConsumerStatefulWidget {
  const _Contenu({
    required this.profils,
    required this.maintenantServeurUtc,
    required this.onOuvrirEspaceEleve,
    required this.titulaireId,
  });

  final List<ProfilEleveFoyer> profils;
  final DateTime? maintenantServeurUtc;
  final VoidCallback? onOuvrirEspaceEleve;
  final String? titulaireId;

  @override
  ConsumerState<_Contenu> createState() => _ContenuEtat();
}

class _ContenuEtat extends ConsumerState<_Contenu> {
  /// Le profil dont le contenu est rendu ; nul avant la premiere ouverture.
  String? _affiche;

  /// Une lecture qui ne revient jamais ne garde pas l'ecran au squelette :
  /// passe le delai de requete, la porte s'ouvre sur ce qui est la.
  Timer? _delai;
  bool _force = false;

  @override
  void dispose() {
    _delai?.cancel();
    super.dispose();
  }

  /// Les lectures qui decident de la forme de l'ecran pour [eleveId].
  bool _lecturesPretes(String eleveId) {
    // Le selecteur montre l'etat court de chaque profil.
    for (final ProfilEleveFoyer p in widget.profils) {
      if (!_arrivee(ref.watch(prochaineSeanceProvider(p.eleveId)))) {
        return false;
      }
    }
    final AsyncValue<ClasseFoyer?> classe = ref.watch(
      classeDeLEleveProvider(eleveId),
    );
    final bool commun =
        _arrivee(classe) &&
        _arrivee(ref.watch(appareilsDuFoyerProvider)) &&
        _arrivee(ref.watch(accesEleveProvider(eleveId))) &&
        _arrivee(ref.watch(ancreServeurProvider)) &&
        _arrivee(ref.watch(parcoursFoyerProvider)) &&
        // Les cartes qui se glissent en tete quand elles ont quelque chose a
        // dire : leur arrivee ne pousse plus rien.
        _arrivee(ref.watch(demandesPresentationProvider)) &&
        _arrivee(ref.watch(accordsTitulaireProvider)) &&
        (ref.watch(portSuiviDemandesProvider) == null ||
            _arrivee(ref.watch(suiviDemandesProvider)));
    if (!commun) return false;
    final String? groupeId = classe.value?.classe.groupeId;
    if (groupeId != null &&
        !_arrivee(ref.watch(horlogeClasseVivanteProvider(groupeId)))) {
      return false;
    }
    final bool sansClasse =
        classe.value == null &&
        ref.watch(prochaineSeanceProvider(eleveId)).value == null;
    if (sansClasse && !_lecturesCarteHoraire(eleveId)) return false;
    return !sansClasse || _arrivee(ref.watch(reglesAcademieProvider));
  }

  /// DEFAUT DU 11/11/2026 (directeur) : la carte « Horaire a choisir » decide
  /// de son geste (« Voir les horaires », « Me prevenir », ou rien une fois la
  /// demande faite) avec deux lectures qu'elle faisait seule : les offres du
  /// profil, puis, si aucune, la demande deja faite. Elles sont dans la porte :
  /// la carte arrive avec son geste definitif, jamais un bouton retire ensuite.
  /// Les memes providers et la meme cle que la carte : aucune lecture en plus.
  bool _lecturesCarteHoraire(String eleveId) {
    final ParcoursApprenant? aChoisir = ref
        .watch(parcoursFoyerProvider)
        .value
        ?.where(
          (ParcoursApprenant p) =>
              p.eleveId == eleveId &&
              etapeParcours(p) == EtapeParcours.horaireAChoisir,
        )
        .firstOrNull;
    if (aChoisir == null) return true;
    final AsyncValue<List<OffreHoraire>> offres = ref.watch(
      offresCompatiblesProvider(cleOffresCarteHoraire(aChoisir)),
    );
    if (!_arrivee(offres)) return false;
    final bool aucune = offres.hasValue && offres.requireValue.isEmpty;
    return !aucune || _arrivee(ref.watch(demandesHoraireProvider));
  }

  @override
  Widget build(BuildContext context) {
    final String choisi = profilRetenu(
      widget.profils,
      ref.watch(selectionEleveProvider),
    )!.eleveId;
    final bool pret = _force || _lecturesPretes(choisi);
    if (pret) {
      _delai?.cancel();
      _delai = null;
      _force = false;
      _affiche = choisi;
    } else {
      _delai ??= Timer(AppDelais.requeteMax, () {
        if (mounted) setState(() => _force = true);
      });
    }
    // Un profil qui n'est plus au foyer ne reste pas affiche.
    final String? montre =
        widget.profils.any((ProfilEleveFoyer p) => p.eleveId == _affiche)
        ? _affiche
        : null;
    return BasculeEtat(
      etat: montre == null,
      child: montre == null
          ? const _Squelette()
          : _CorpsAccueil(
              profils: widget.profils,
              eleveId: montre,
              selectionId: choisi,
              maintenantServeurUtc: widget.maintenantServeurUtc,
              onOuvrirEspaceEleve: widget.onOuvrirEspaceEleve,
              titulaireId: widget.titulaireId,
            ),
    );
  }
}

/// Le corps de l'Accueil pour le profil [eleveId] : tout ce qu'il lit est deja
/// arrive (`_Contenu` ouvre la porte), il ne rend donc aucun etat intermediaire.
class _CorpsAccueil extends ConsumerWidget {
  const _CorpsAccueil({
    required this.profils,
    required this.eleveId,
    required this.selectionId,
    required this.maintenantServeurUtc,
    required this.onOuvrirEspaceEleve,
    required this.titulaireId,
  });

  final List<ProfilEleveFoyer> profils;

  /// Le profil dont le contenu s'affiche.
  final String eleveId;

  /// Le profil que le selecteur montre choisi : il suit le geste tout de
  /// suite, le contenu suit quand ses lectures sont arrivees.
  final String selectionId;
  final DateTime? maintenantServeurUtc;
  final VoidCallback? onOuvrirEspaceEleve;
  final String? titulaireId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // HEURES-PROFIL H1 (12/11/2026) : la page ecoute le fuseau du profil ;
    // quand il arrive apres son premier rendu, ses heures se redessinent.
    ref.watch(monHorlogeProvider);
    final Gabarit gabarit = AppGabarit.de(context);
    final bool compact = gabarit == Gabarit.mobile;
    final ProfilEleveFoyer profil = profils.firstWhere(
      (ProfilEleveFoyer p) => p.eleveId == eleveId,
    );
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

    // UX-009 : le profil choisi lit aussi l'horloge de sa classe, comme sa
    // carte ; le selecteur ne dit pas « Prévue » au-dessus de « En direct ».
    Widget selecteurAvec(SessionClockVM? horloge) => SelecteurProfils(
      profils: <ProfilSelectionnable>[
        for (final ProfilEleveFoyer p in profils)
          _selectionnable(
            ref,
            p,
            horlogeClasse: p.eleveId == eleveId ? horloge : null,
          ),
      ],
      selectionId: selectionId,
      onSelection: (String id) =>
          ref.read(selectionEleveProvider.notifier).choisir(id),
      onAjouter: () => routeur.go(Routes.tuteurAjouterEnfant),
    );
    final Widget selecteur = selecteurAvec(null);

    // ACCUEIL-TUTEUR-UNE-PORTE (09/11/2026) : sous la rangee, et seulement
    // quand le profil choisi est celui du titulaire et que la capacite est
    // servie. La rangee reste le premier bloc, a la meme place pour tous.
    final VoidCallback? ouvrirEspace = onOuvrirEspaceEleve;
    final Widget? lienEspaceEleve =
        ouvrirEspace != null && titulaireId != null && eleveId == titulaireId
        ? Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              key: AccueilFamillePage.espaceEleveKey,
              libelle: t.tuteur.accueil.ouvrirEspaceEleve,
              onPress: ouvrirEspace,
              alignerEnDebut: true,
              annonceLien: true,
            ),
          )
        : null;

    final bool sansClasse =
        classe.hasValue &&
        classe.value == null &&
        prochaine.hasValue &&
        prochaine.value == null;
    // ACCUEIL-HORAIRE (05/11/2026) : l'enfant choisi a un horaire a choisir ;
    // une seule carte le dit (CarteHoraireAccueil), a la place du bloc du
    // parcours et de « Aucune classe pour ... », qui disaient la meme chose.
    final ParcoursApprenant? horaireAChoisir = ref
        .watch(parcoursFoyerProvider)
        .value
        ?.where(
          (ParcoursApprenant p) =>
              p.eleveId == eleveId &&
              etapeParcours(p) == EtapeParcours.horaireAChoisir,
        )
        .firstOrNull;
    // PROFILS-EFFET (directeur, 12/11/2026) : entre deux profils, le contenu
    // change par un fondu court (FonduContenuProfil) ; le rond choisi, lui,
    // est pris des le toucher. La porte unique de la 422 reste la regle :
    // `eleveId` (le contenu) ne change que quand les donnees sont la ;
    // `selectionId` suit le toucher.
    // 432 (train du 11/11, choix du garde-cap) : le lien discret « Utiliser
    // un autre appareil » reste fixe avec la rangee, juste apres
    // lienEspaceEleve ; seul le contenu du profil change.
    Widget contenuProfil(
      Widget rangee,
      List<Widget> contenu, {
      Widget? autreAppareil,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        rangee,
        ?lienEspaceEleve,
        ?autreAppareil,
        FonduContenuProfil(
          profilId: eleveId,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: contenu,
          ),
        ),
      ],
    );
    if (sansClasse) {
      return contenuProfil(selecteur, <Widget>[
        Ecart.vXl,
        const CarteSuiviAttente(
          chemins: CheminsAttente.tuteur,
          repli: CarteSuiviDemandes(),
        ),
        const CarteDemandePresentation(),
        // L9 : les comptes d'avant l'accord des visites y sont conduits.
        const InviteConsentementObservation(),
        // Entree transitoire du questionnaire (revue C, M3 ; demande C-7) :
        // gardee tant que Fiche > Inscription (lot B) n'est pas integree.
        // Silencieuse quand aucun apprenant n'a de parcours a suivre.
        if (horaireAChoisir != null)
          CarteHoraireAccueil(apprenant: horaireAChoisir)
        else ...<Widget>[
          ParcoursDuProfilChoisi(eleveId: eleveId),
          EtatSysteme(
            nature: NatureEtat.aucunResultat,
            titre: t.tuteur.accueil.sansClasseTitre(prenom: profil.prenom),
            phrase: t.tuteur.accueil.sansClassePhrase(
              quePrenom: queDevant(profil.prenom),
            ),
            // DECISION-OFFRES-GROUPES-2026-10-09 : pas de catalogue.
            libelleAction: t.parcours.voirHoraires,
            onAction: () => routeur.go(Routes.parcoursPour(eleveId)),
          ),
        ],
      ]);
    }

    final bool inscrit = classe.value != null || prochaine.value != null;
    // TITULAIRE-SANS-APPAREIL (directeur, 11/11/2026) : le titulaire, qui suit
    // lui-meme ses cours (son id est celui du profil, jamais son role), entre
    // en salle depuis cet appareil : le serveur ne demande aucun appareil
    // jumele (`autoriser_jeton_video`). Aucune alerte, aucune lumiere rouge, il
    // n'est jamais compte parmi les bloques ; un lien discret et facultatif
    // mene a l'appairage.
    final bool titulaire = titulaireId != null && eleveId == titulaireId;
    final bool sansAppareil =
        inscrit &&
        appareils.hasValue &&
        !appareils.hasError &&
        aucunAppareilPret(appareils.requireValue, eleveId);
    final bool blocage = sansAppareil && !titulaire;
    final bool lienAutreAppareil = sansAppareil && titulaire;

    // D6 et R8 (24/10/2026) : salle ouverte ou seance en direct, la tache
    // immediate est d'y entrer ; le bouton prend la place du blocage en tete
    // (un seul bouton plein, jamais un bouton dans la carte-lien).
    // NAV-REFONTE 2b : « salle rejoignable » se lit dans le provider unique,
    // celui du halo vert du cercle Compte (seances fermees, seance ouverte,
    // concierge (a) par l'horloge de la Classe).
    final SalleDeLEleve salle = ref.watch(
      salleDeLEleveProvider((
        eleveId: eleveId,
        maintenantServeurUtc: maintenantServeurUtc,
      )),
    );
    final SeanceFamille? seanceOuverte = salle.seance;
    final BandeauPlace? bandeauPlace = BandeauPlace.pour(
      ref.watch(accesEleveProvider(eleveId)).value,
      prenom: profil.prenom,
    );
    final bool rejoindre = salle.parSeance;
    final SessionClockVM? horlogeClasse = salle.horlogeClasse;
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

    // PHOTOS-B : la photo vient de `photoPersonneProvider`, jamais de la cle
    // copiee dans le profil ; posee ailleurs, elle apparait ici sans recharger.
    final Widget carte = CarteClasseSeance(
      profil: profil,
      urlPhotoEleve: ref.watch(photoPersonneProvider(profil.eleveId)).value,
      classe: classe,
      seance: seanceAffichee,
      maintenantServeurUtc: maintenantServeurUtc,
      // UX-009 : la meme horloge que le bouton « Rejoindre la salle avec » ;
      // la carte ne dit plus « non confirmée » sous un bouton qui ouvre.
      horlogeClasse: horlogeClasse,
      compact: compact,
      onVoirClasse: (String id) =>
          routeur.go(Routes.classePour(id, eleveId: eleveId)),
      onReessayerClasse: () => ref.invalidate(classeDeLEleveProvider(eleveId)),
      onReessayerSeance: () => ref.invalidate(prochaineSeanceProvider(eleveId)),
      // « Recharger » : l'instant serveur, la seance et l'horloge de la classe
      // se relisent (ouverture non verifiee a l'heure du cours).
      onRecharger: () {
        ref.invalidate(ancreServeurProvider);
        ref.invalidate(prochaineSeanceProvider(eleveId));
        if (groupeId != null) {
          ref.invalidate(horlogeClasseVivanteProvider(groupeId));
        }
      },
    );

    // LUMIERE-ACCUEILS (11/11/2026) : trois lumieres, toutes tirees d'etats que
    // le serveur rend (voir `signauxFamille`) ; l'arbitre n'en fait tourner
    // qu'une seule par ecran.
    final bool fermees =
        ouvertureSeances(ref.watch(accesEleveProvider(eleveId)).value) ==
        OuvertureSeances.fermees;
    final AsyncValue<CompteRenduFamille>? cahier = derniereId == null
        ? null
        : ref.watch(
            compteRenduFamilleProvider((
              seanceId: derniereId,
              eleveId: eleveId,
            )),
          );
    final List<SignalAccueil<MotifFamille>> signaux = signauxFamille(
      // Le blocage n'est la tuile du haut que si la salle n'est pas
      // rejoignable : sinon la tuile est le bouton « Rejoindre ».
      salleRejoignable: salle.rejoignable,
      accesBloque:
          !salle.rejoignable &&
          (fermees ? bandeauPlace != null : (bandeauPlace == null && blocage)),
      maintenantServeurUtc: maintenantServeurUtc,
      debutProchaineUtc: prochaine.value?.debutUtc,
      travailAPreparer: travail?.value?.isNotEmpty ?? false,
      etatCahier: cahier?.value?.etat,
      debutDerniereUtc: derniere.value?.debutUtc,
    );

    final Widget? bandeau = rejoindre
        ? AppCard(
            key: AccueilFamillePage.rejoindreKey,
            marge: compact ? AppSpacing.lg : AppSpacing.xxl,
            child: BoutonRejoindreAvecEleve(
              // `parSeance` n'est vrai qu'avec une seance.
              seance: seanceOuverte!,
              eleve: profil,
            ),
          )
        : salle.parClasse
        ? AppCard(
            key: AccueilFamillePage.rejoindreKey,
            marge: compact ? AppSpacing.lg : AppSpacing.xxl,
            child: BoutonRejoindreClasseAvecEleve(
              // `parClasse` n'est vrai qu'avec une Classe et son horloge.
              groupeId: groupeId!,
              sessionId: horlogeClasse!.sessionId,
              eleve: profil,
            ),
          )
        // Lot (B), 02/11/2026 : seances fermees pour paiement, la famille lit
        // pourquoi et peut payer d'ici (bandeau existant, « Payer »).
        : bandeauPlace ??
              (blocage
                  ? BandeauBlocage(
                      prenom: profil.prenom,
                      onConnecter: () =>
                          routeur.go(Routes.appairerPour(eleveId)),
                    )
                  : null);
    final Widget? autreAppareil = lienAutreAppareil && bandeau == null
        ? Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              key: AccueilFamillePage.autreAppareilKey,
              libelle: t.tuteur.accueil.autreAppareil,
              // AUTRE-PROFIL-ELEVE (12/11/2026) : le titulaire se connecte a
              // son propre compte sur l'autre appareil, sans jumelage (le
              // serveur refuse d'appairer un compte tuteur).
              onPress: () => unawaited(ouvrirFeuilleAutreAppareil(context)),
              alignerEnDebut: true,
            ),
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
    return contenuProfil(selecteurAvec(horlogeClasse), <Widget>[
      Ecart.vXl,
      const CarteSuiviAttente(
        chemins: CheminsAttente.tuteur,
        repli: CarteSuiviDemandes(),
      ),
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
                  child: LumiereAutour(
                    nature:
                        lumierePourFamille(signaux, MotifFamille.acces) ??
                        lumierePourFamille(signaux, MotifFamille.salle),
                    // Pleine largeur : sinon la lueur, calee sur la tuile,
                    // se voit a cote d'une carte plus etroite (« Rejoindre »
                    // est une carte au contenu).
                    child: SizedBox(width: double.infinity, child: bandeau),
                  ),
                ),
              TuileBento(
                etendue: EtendueBento.grande,
                etendueLarge: pleine,
                // PROFILS P2 : la Bibliotheque, sous la classe du profil choisi.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[carte, const LigneBibliothequeClasse()],
                ),
              ),
              TuileBento(
                etendue: EtendueBento.grande,
                etendueLarge: pleine,
                child: LumiereAutour(
                  nature: lumierePourFamille(signaux, MotifFamille.preparer),
                  child: AppCard(marge: marge, child: preparation),
                ),
              ),
              TuileBento(
                etendue: EtendueBento.large,
                etendueLarge: const EtendueBento(4, 1),
                child: LumiereAutour(
                  nature: lumierePourFamille(signaux, MotifFamille.cahier),
                  child: AppCard(marge: marge, child: derniereSeance),
                ),
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
    ], autreAppareil: autreAppareil);
  }

  /// Un profil du selecteur : prenom, portrait, et l'etat court calcule
  /// **par la meme fonction** que la carte ([AffichageSeance]).
  ProfilSelectionnable _selectionnable(
    WidgetRef ref,
    ProfilEleveFoyer p, {
    SessionClockVM? horlogeClasse,
  }) {
    final AsyncValue<SeanceFamille?> seance = ref.watch(
      prochaineSeanceProvider(p.eleveId),
    );
    final String? photo = ref.watch(photoPersonneProvider(p.eleveId)).value;
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
      horlogeClasse: horlogeClasse,
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
