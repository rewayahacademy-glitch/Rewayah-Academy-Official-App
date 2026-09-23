/// `ENS-02` : la journee de l'enseignant, en une seule colonne.
///
/// **Cours, pauses et prieres sont des entrees de meme nature**, du haut vers
/// le bas. C'est la demande explicite des specs produit, et elle interdit un
/// bloc « prieres » separe : une interruption doit se lire a sa place dans le
/// deroule, pas dans un encadre a cote. Le gabarit est donc litteralement le
/// meme pour les trois sortes, seul le contenu change.
///
/// **L'ordre de priorite visuelle est fixe** : prochain cours, puis la colonne
/// de la journee, puis les exceptions, puis le secondaire. Une seule entorse,
/// assumee : les alertes qui concernent le cours dominant (un eleve qui n'est
/// pas entre, un cours annule aujourd'hui) se posent juste sous la carte
/// dominante et non dans la section des exceptions. A 390 de large, une absence
/// annoncee sous la colonne serait lue apres le cours, c'est-a-dire trop tard.
///
/// **Le bouton de lancement existe depuis le lot N3**, et seulement dans la
/// fenetre ou il peut aboutir : de dix minutes avant le debut du cours jusqu'a
/// sa fin. Hors de cette fenetre, une phrase dit quand il s'ouvrira, plutot
/// qu'un bouton grise -- un bouton qui echoue apres le geste coute plus cher en
/// confiance qu'un bouton absent. **Le materiel est verifie avant**, par
/// `preVolProvider` : sans micro, il n'y a pas de bouton, il y a la raison.
///
/// La fenetre du client est la meme que celle de la base, et c'est la base qui
/// tranche : `autoriser_jeton_video()` refuse le jeton avant `debut - 10 min`
/// et apres `fin + 15 min` (ADR-005). Le seuil lu ici ne fait qu'eviter de
/// proposer un geste dont on sait qu'il serait refuse. Il s'appelle
/// `seuilOuvertureSalle` et vit dans `core/video/pre_vol.dart`, remonte a
/// l'integration du lot Enseignant (`CONTRACT_REQUEST_A.md` §1) : une constante
/// que tout ecran offrant l'entree doit respecter n'a pas sa place dans le
/// fichier de l'un d'eux. **Ne pas la redeclarer ici** -- elle doit rester egale
/// au seuil de la base, et deux copies finiraient par diverger.
///
/// **Depuis le pivot du 19 septembre 2026, un cours est celui d'un groupe** :
/// l'ecran lit `seancesEnseignantProvider`, une entree par seance, et non
/// `seancesProvider`, qui rend une ligne par eleve et afficherait cinq fois le
/// cours d'un groupe de cinq enfants.
///
/// **L'objectif commun de la seance n'est pas affiche, et c'est volontaire** :
/// aucune couche ne le porte (ni `sessions`, ni `SeanceEnseignant`). Se taire
/// coute moins cher qu'un tiret a chaque ligne. La demande est ecrite dans
/// `docs/archive/2026-09-pre-remise-a-plat/parallel-reports/CONTRACT_REQUEST_A.md`.
///
/// Les heures affichees sont celles de l'appareil. Aucune mention de fuseau
/// n'est posee ici, contrairement a la grille de `ENS-06` : les seances et les
/// prieres sont des instants absolus, et `mon_fuseau()` dit ou l'enseignant
/// **pose** ses creneaux, pas ou il se trouve. Annoncer « heures affichees en
/// Europe/Paris » a un enseignant en deplacement serait faux.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/enseignant/modeles_enseignant.dart';
import '../../core/enseignant/service_enseignant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/matching/service_matching.dart';
import '../../core/planning/journee.dart';
import '../../core/planning/service_planning.dart';
import '../../core/presence/service_presence.dart';
import '../../core/priere/reglages_priere.dart';
import '../../core/priere/service_priere.dart';
import '../../core/regles/service_regles.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/pre_vol.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/signal_row.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/stat_tile.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/timeline_row.dart';

/// Combien d'alertes individuelles la Journee accepte d'afficher a la fois.
///
/// **« Rares » est un mot du protocole, pas une intention.** Deux lignes se
/// lisent d'un coup d'oeil avant un cours ; cinq deviennent une liste que
/// personne ne lit, et la sixieme fait perdre la premiere. Au dela, une phrase
/// dit combien d'autres attendent, et le detail se lit en salle.
const int _maximumAlertes = 2;

/// `ENS-02`, la racine du role Enseignant.
class JourneePage extends ConsumerWidget {
  /// Cree l'ecran de la journee.
  const JourneePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Un seul `PageShell`, quel que soit l'etat : le titre d'ecran ne disparait
    // pas pendant une charge, et le bandeau hors ligne du shell coiffe la page
    // dans les six etats.
    return PageShell(
      titre: t.enseignant.journee.titre,
      child: _Cadence(
        constructeur: (DateTime maintenant) => _Corps(maintenant: maintenant),
      ),
    );
  }
}

/// Le battement d'une minute, pose sur l'ecran et non dans un provider.
///
/// Il vit dans un widget a part pour que [JourneePage] reste un
/// `ConsumerWidget` : c'est la declaration exacte que le routeur attend
/// (`docs/archive/2026-09-pre-remise-a-plat/architecture/TEACHER_FILE_OWNERSHIP.md` section 3), et une page
/// devenue `ConsumerStatefulWidget` pour porter une horloge serait un ecart de
/// contrat pour une raison purement interne.
class _Cadence extends StatefulWidget {
  const _Cadence({required this.constructeur});

  final Widget Function(DateTime maintenant) constructeur;

  @override
  State<_Cadence> createState() => _CadenceEtat();
}

class _CadenceEtat extends State<_Cadence> {
  Timer? _horloge;
  DateTime _maintenant = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Le minuteur se lit en minutes : le rafraichir a la seconde ferait
    // travailler l'ecran soixante fois pour rien.
    _horloge = Timer.periodic(
      const Duration(minutes: 1),
      (Timer _) => setState(() => _maintenant = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _horloge?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.constructeur(_maintenant);
}

/// Le corps de la journee : cinq lectures, six etats.
class _Corps extends ConsumerWidget {
  const _Corps({required this.maintenant});

  final DateTime maintenant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? monId = ref.watch(sessionProvider).profileId;

    if (monId == null) {
      return const Skeleton.liste(lignes: 4);
    }

    final AsyncValue<List<SeanceEnseignant>> seances = ref.watch(
      seancesEnseignantProvider,
    );
    final AsyncValue<ReglagesPriere?> reglages = ref.watch(
      reglagesPriereProvider(monId),
    );
    // La pause vient de `regle_effective()`, jamais d'une constante : elle peut
    // differer d'un profil a l'autre (ADR-017 section 2.4, invariant I10).
    final AsyncValue<int> pause = ref.watch(
      valeurRegleProvider((profilId: monId, cle: CleRegle.pauseEntreCours)),
    );
    final AsyncValue<List<CahierEnRetard>> retards = ref.watch(
      cahiersEnRetardProvider,
    );
    final AsyncValue<List<EleveEnAttente>> feed = ref.watch(
      elevesEnAttenteProvider,
    );

    // **Un seul test de chargement.** L'ecran en portait deux : le premier
    // interceptait la premiere charge, le second branchait un squelette que
    // rien ne pouvait plus atteindre. Le chemin mort est supprime, et c'est sa
    // forme -- carte dominante puis lignes de colonne -- qui est gardee, parce
    // qu'un squelette ressemble a ce qui arrive.
    final bool premiereCharge = <AsyncValue<Object?>>[
      seances,
      reglages,
      pause,
      retards,
      feed,
    ].any(
      (AsyncValue<Object?> lecture) => !lecture.hasValue && lecture.isLoading,
    );
    if (premiereCharge) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Skeleton.tuileBento(hauteur: 160),
          Ecart.vXl,
          Skeleton.ligneTimeline(lignes: 3),
        ],
      );
    }

    final List<SeanceEnseignant> toutes =
        seances.value ?? const <SeanceEnseignant>[];
    final Map<String, SeanceEnseignant> parId = <String, SeanceEnseignant>{
      for (final SeanceEnseignant seance in toutes) seance.id: seance,
    };
    // Le pont vers la journee partagee. `construireJournee`, `prochainCours` et
    // `seanceAnnuleeDuJour` raisonnent en `Seance`, et `TimelineRow` lit
    // `elevePrenom` : le pivot groupes n'a pas encore atteint ces trois-la, et
    // ce sont des fichiers partages. La conversion est donc locale, et le
    // resultat est **relu par identifiant** pour retrouver la seance riche.
    final List<Seance> pont = toutes.map(_versSeance).toList(growable: false);
    final Seance? relais = prochainCours(pont, maintenant);
    final SeanceEnseignant? dominant = relais == null ? null : parId[relais.id];
    final Seance? annulee = seanceAnnuleeDuJour(pont, maintenant);

    // Les bornes du jour civil local. `DateTime(annee, mois, jour + 1)` plutot
    // qu'une addition de 24 heures : deux fois par an, une journee civile ne
    // dure pas vingt-quatre heures, et la colonne perdrait ou doublerait une
    // heure de cours.
    final DateTime debutJour = DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day,
    );
    final DateTime finJour = DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day + 1,
    );

    final List<EntreeJournee> journee = construireJournee(
      seances: pont,
      reglages: reglages.value,
      debut: debutJour,
      fin: finJour,
      // Une regle illisible ne se remplace pas par une valeur inventee : sans
      // elle, aucun trou n'est declare pause, et les cours restent exacts.
      pauseMaximale: Duration(minutes: pause.value ?? 0),
    );

    final List<EntreeJournee> coursDuJour = journee
        .where((EntreeJournee entree) => entree.sorte == SorteEntree.cours)
        .toList(growable: false);
    final bool journeeFinie =
        coursDuJour.isNotEmpty &&
        coursDuJour.every(
          (EntreeJournee entree) => !maintenant.isBefore(entree.fin),
        );

    // Le feed rend **une ligne par creneau compatible** : le meme eleve y
    // figure autant de fois qu'il propose d'heures que cet enseignant peut
    // tenir. Compter les lignes annoncerait quatre familles la ou une seule
    // attend.
    final int enAttente = (feed.value ?? const <EleveEnAttente>[])
        .map((EleveEnAttente eleve) => eleve.eleveId)
        .toSet()
        .length;

    final List<CahierEnRetard> aDeposer =
        retards.value ?? const <CahierEnRetard>[];

    // Les lectures secondaires ne font pas echouer l'ecran, mais leur echec ne
    // s'avale plus en silence : une pause illisible fait disparaitre toutes les
    // pauses, et une priere illisible toutes les prieres.
    final bool erreurPartielle =
        reglages.hasError ||
        pause.hasError ||
        retards.hasError ||
        feed.hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (seances.hasError)
          EmptyState(
            message: t.enseignant.journee.erreur,
            icone: AppIcons.avertissement,
            libelleAction: t.commun.reessayer,
            onAction: () => ref.invalidate(seancesEnseignantProvider),
          )
        else ...<Widget>[
          _BlocDominant(seance: dominant, maintenant: maintenant),
          if (dominant != null) ...<Widget>[
            Ecart.vSm,
            _AlertesSeance(seance: dominant, maintenant: maintenant),
          ],
          if (annulee != null) ...<Widget>[
            Ecart.vSm,
            _LigneAlerte(
              phrase: t.enseignant.journee.coursAnnule(
                heure: _hhmm(annulee.debut),
              ),
              icone: AppIcons.avertissement,
            ),
          ],
          Ecart.vXl,
          SectionHeader(titre: t.enseignant.journee.colonne),
          Ecart.vMd,
          if (journee.isEmpty)
            _RienAujourdhui(prochain: dominant)
          else
            for (final EntreeJournee entree in journee)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TimelineRow(entree: entree),
              ),
          if (journeeFinie) ...<Widget>[
            Ecart.vSm,
            Text(
              coursDuJour.length == 1
                  ? t.enseignant.journee.journeeTermineeUn
                  : t.enseignant.journee.journeeTerminee(
                      nombre: '${coursDuJour.length}',
                    ),
              style: textes.bodySmall,
            ),
          ],
        ],
        if (erreurPartielle) ...<Widget>[
          Ecart.vSm,
          Text(
            t.enseignant.journee.erreurPartielle,
            // L'encre d'alerte, jamais la paire : `surfaceAlert` ecrit en
            // blanc, illisible sur la page.
            style: palette.inkAlert.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
        if (aDeposer.isNotEmpty) ...<Widget>[
          Ecart.vXl,
          SectionHeader(
            titre: t.enseignant.journee.rapportsTitre,
            compteur: aDeposer.length,
          ),
          Ecart.vMd,
          for (final CahierEnRetard cahier in aDeposer)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _LigneRapport(cahier: cahier),
            ),
        ],
        Ecart.vXl,
        SectionHeader(
          titre: t.enseignant.journee.enAttenteTitre,
          libelleAction: t.enseignant.journee.voirCreneaux,
          onAction: () => GoRouter.of(context).go(Routes.enseignantCreneaux),
        ),
        Ecart.vMd,
        // `StatTile` et non une tuile bricolee : le zero s'y affiche comme les
        // autres valeurs, les chiffres y sont tabulaires, et le compteur mene a
        // l'ecran ou il se traite (`ENS-06`).
        StatTile(
          valeur: enAttente,
          libelle: enAttente == 1
              ? t.enseignant.journee.enAttenteLibelleUn
              : t.enseignant.journee.enAttenteLibelle,
          onPress: () => GoRouter.of(context).go(Routes.enseignantCreneaux),
        ),
      ],
    );
  }
}

/// Le bloc dominant : le cours en cours, sinon le prochain a venir.
class _BlocDominant extends ConsumerWidget {
  const _BlocDominant({required this.seance, required this.maintenant});

  final SeanceEnseignant? seance;
  final DateTime maintenant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final SeanceEnseignant? cours = seance;

    if (cours == null) {
      return EmptyState(
        message: t.enseignant.journee.aucunCours,
        invitation: t.enseignant.journee.aucunCoursDetail,
        // Un constat, pas une porte : l'enseignant ne quitte pas cet ecran
        // pour agir, le bloc des eleves en attente en dessous le fait.
        registre: RegistreVide.subi,
      );
    }

    final bool enCours = cours.enCoursA(maintenant);
    final bool aujourdhui = _memeJour(cours.debut, maintenant);
    final bool fenetreOuverte =
        enCours || cours.avantDebut(maintenant) <= seuilOuvertureSalle;
    // Tant que la reponse est inconnue, l'appareil est repute en ligne : c'est
    // la lecture prescrite de ce provider, et elle evite de refuser un
    // lancement sur une ignorance.
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final String? libelleGroupe = cours.groupeLibelle;
    // Capture avant le test : un champ public n'est pas promu par une
    // comparaison a `null`, et le `!` qui en decoule est exactement ce qu'un
    // relecteur ne doit pas avoir a verifier.
    final String? idGroupe = cours.groupeId;

    // Carte posee, jamais un aplat sature : la regle de la zone pleine unique
    // n'attribue l'aplat qu'a l'action principale, et depuis le lot N3 c'est le
    // bouton de lancement qui la porte -- pas la carte qui l'entoure. L'etat
    // « en cours » se dit par la pastille, jamais par la couleur de fond.
    return BentoTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  enCours
                      ? t.enseignant.journee.coursEnCours
                      : t.enseignant.journee.prochainCours,
                  style: textes.labelLarge ?? const TextStyle(),
                ),
              ),
              if (enCours)
                StatusPill(libelle: t.etat.enDirect, ton: TonEtat.succes),
            ],
          ),
          Ecart.vXs,
          // Le nom du groupe, ou « Cours individuel » pour une seance
          // anterieure au pivot. Aucun prenom ici : `SeanceEnseignant` n'en
          // porte pas, et cinq prenoms dans la carte dominante feraient cinq
          // choses a lire avant un cours. Ils se lisent sur la fiche groupe.
          Text(
            libelleGroupe == null || libelleGroupe.isEmpty
                ? t.enseignant.journee.coursIndividuel
                : libelleGroupe,
            style: textes.headlineSmall ?? const TextStyle(),
          ),
          if (cours.estGroupe)
            Text(
              _effectif(cours.nbParticipants),
              style: textes.bodySmall ?? const TextStyle(),
            ),
          Ecart.vSm,
          Text(switch ((enCours, aujourdhui)) {
            (true, _) => t.enseignant.journee.jusqua(heure: _hhmm(cours.fin)),
            (false, true) => _minuteur(cours.avantDebut(maintenant)),
            (false, false) => t.enseignant.journee.unAutreJour(
              jour: t.disponibilites.joursLongs[cours.debut.weekday - 1],
              heure: _hhmm(cours.debut),
            ),
          }, style: textes.titleMedium ?? const TextStyle()),
          Ecart.vSm,
          // Le lancement, ou la raison de son absence. Jamais les deux, jamais
          // un bouton inerte.
          if (!fenetreOuverte)
            Text(
              t.enseignant.journee.lancementPlusTard,
              style: textes.bodySmall ?? const TextStyle(),
            )
          else if (horsLigne)
            // Une salle ne s'ouvre pas sans reseau : le geste echouerait apres
            // le tap, ce qui coute plus cher que son absence.
            Text(
              t.enseignant.journee.lancerHorsLigne,
              style: textes.bodySmall ?? const TextStyle(),
            )
          else
            _Lancement(seanceId: cours.id),
          if (idGroupe != null) ...<Widget>[
            Ecart.vSm,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ActionPrincipale(
                libelle: t.enseignant.journee.voirGroupe,
                niveau: NiveauAction.tertiaire,
                pleineLargeur: false,
                onPress: () =>
                    GoRouter.of(context).go(Routes.groupePour(idGroupe)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Le pre-vol, puis le lancement -- ou la raison qui le remplace.
///
/// **Un seul chemin de lecture du pre-vol** : `preVolProvider`, et non
/// `servicePreVolProvider` en imperatif. Deux chemins existaient, l'arbitrage
/// de l'Agent 0 a tranche pour le provider afin que la Journee et la salle
/// lisent le meme resultat.
class _Lancement extends ConsumerWidget {
  const _Lancement({required this.seanceId});

  final String seanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final AsyncValue<ResultatPreVol> preVol = ref.watch(preVolProvider);

    if (!preVol.hasValue && preVol.isLoading) {
      return Text(
        t.enseignant.journee.preflight,
        style: textes.bodySmall ?? const TextStyle(),
      );
    }

    final ResultatPreVol? resultat = preVol.value;
    // `peutEntrer` vaut `microDisponible && !permissionRefusee` : le micro
    // suffit, la camera n'est pas bloquante (ADR-001).
    if (resultat != null && resultat.peutEntrer) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            t.enseignant.journee.preflightOk,
            style: textes.bodySmall ?? const TextStyle(),
          ),
          Ecart.vSm,
          ActionPrincipale(
            libelle: t.enseignant.journee.lancer,
            onPress: () => GoRouter.of(context).go(
              Routes.salle,
              // Le billet passe par `extra`, jamais par l'URL (ADR-005) :
              // une adresse de salle copiee ne rouvre rien.
              extra: BilletSalle(sessionId: seanceId, emisA: DateTime.now()),
            ),
          ),
        ],
      );
    }

    // Pre-flight echoue : pas de bouton, la raison exacte, et de quoi relancer
    // la verification quand le micro est branche ou la permission accordee.
    final String raison = switch (resultat) {
      null => t.enseignant.journee.preflightIndisponible,
      ResultatPreVol(permissionRefusee: true) =>
        t.enseignant.journee.preflightBloque,
      _ => t.enseignant.journee.preflightSansMicro,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          raison,
          style: palette.inkAlert.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ActionPrincipale(
            libelle: t.commun.reessayer,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
            onPress: () => ref.invalidate(preVolProvider),
          ),
        ),
      ],
    );
  }
}

/// Les rares alertes individuelles du cours dominant.
///
/// **Lues seulement quand le cours se tient.** Avant l'heure, personne n'est
/// attendu en salle et une absence n'existe pas encore ; apres, c'est le cahier
/// de transmission qui porte le sujet.
///
/// `null` n'est pas une liste vide : `null` dit « je ne sais pas » et ne
/// s'annonce donc pas comme une absence (invariant J3). Seuls `absente` et
/// `deconnectee` deviennent une alerte -- `inconnu` est critique pour la salle,
/// pas pour la Journee, ou il n'apprendrait rien d'actionnable.
class _AlertesSeance extends ConsumerWidget {
  const _AlertesSeance({required this.seance, required this.maintenant});

  final SeanceEnseignant seance;
  final DateTime maintenant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!seance.enCoursA(maintenant)) {
      return const SizedBox.shrink();
    }

    final TextTheme textes = Theme.of(context).textTheme;
    final List<PresenceParticipant>? lignes = ref
        .watch(presenceSeanceProvider(seance.id))
        .value;
    if (lignes == null) {
      return const SizedBox.shrink();
    }

    final List<PresenceParticipant> manquants = lignes
        .where(
          (PresenceParticipant ligne) =>
              !ligne.estEnseignant &&
              (ligne.etat == EtatPresence.absente ||
                  ligne.etat == EtatPresence.deconnectee),
        )
        .toList(growable: false);
    if (manquants.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<PresenceParticipant> montrees = manquants
        .take(_maximumAlertes)
        .toList(growable: false);
    final int reste = manquants.length - montrees.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final PresenceParticipant ligne in montrees)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _LigneAlerte(
              phrase: ligne.etat == EtatPresence.absente
                  ? t.enseignant.journee.absenceDetectee(
                      eleve: _nommer(ligne),
                    )
                  : t.enseignant.journee.coupureDetectee(eleve: _nommer(ligne)),
              icone: AppIcons.avertissement,
            ),
          ),
        if (reste > 0)
          Text(
            t.enseignant.journee.autresAbsences(nombre: '$reste'),
            style: textes.bodySmall ?? const TextStyle(),
          ),
      ],
    );
  }
}

/// Une alerte en registre doux : fond `washWarning`, encre de la paire.
///
/// Ce n'est pas un `SignalRow` : celui-la est une ligne **actionnable**, avec
/// chevron et destination obligatoire. Une absence constatee pendant un cours
/// ne mene nulle part -- l'enseignant est deja en salle, ou le bouton de
/// lancement est juste au dessus.
class _LigneAlerte extends StatelessWidget {
  const _LigneAlerte({required this.phrase, required this.icone});

  final String phrase;
  final AppIcon icone;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return MergeSemantics(
      child: AppCard(
        surface: palette.washWarning,
        child: Row(
          children: <Widget>[
            Icon(icone.repos, size: AppSpacing.xl),
            Ecart.hMd,
            Expanded(
              child: Text(
                phrase,
                style: palette.washWarning.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une seance terminee dont le cahier manque, et le chemin pour le deposer.
class _LigneRapport extends ConsumerWidget {
  const _LigneRapport({required this.cahier});

  final CahierEnRetard cahier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SignalRow(
      phrase: t.enseignant.journee.rapportLigne(
        jour: t.disponibilites.joursLongs[cahier.debut.weekday - 1],
        heure: _hhmm(cahier.debut),
      ),
      icone: AppIcons.cahier,
      // Au dela de vingt-quatre heures, ce n'est plus une attente.
      ton: cahier.enRetard ? TonEtat.avertissement : TonEtat.neutre,
      anciennete: cahier.enRetard
          ? t.enseignant.journee.rapportRetard(
              heures: '${cahier.heuresDeRetard}',
            )
          : t.enseignant.journee.rapportAttente(
              heures: '${cahier.heuresDeRetard}',
            ),
      onPress: () async {
        // `push` et non `go` : au retour, la file se relit et la ligne
        // disparait d'elle-meme. Avec `go`, le provider garderait sa valeur en
        // cache et l'enseignant relirait un rapport qu'il vient de deposer.
        await GoRouter.of(context).push<void>(
          Routes.cahierPour(cahier.seanceId),
        );
        if (context.mounted) {
          ref.invalidate(cahiersEnRetardProvider);
          ref.invalidate(seancesEnseignantProvider);
        }
      },
    );
  }
}

/// Ce que la colonne dit quand la journee est vide.
class _RienAujourdhui extends StatelessWidget {
  const _RienAujourdhui({required this.prochain});

  final SeanceEnseignant? prochain;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final SeanceEnseignant? cours = prochain;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.enseignant.journee.rienAujourdhui, style: textes.bodyMedium),
        // Un etat vide est une invitation, pas un constat : quand un cours
        // existe ailleurs dans la semaine, il se dit ici.
        if (cours != null) ...<Widget>[
          Ecart.vXs,
          Text(
            t.enseignant.journee.rienAujourdhuiDetail(
              jour: t.disponibilites.joursLongs[cours.debut.weekday - 1],
              heure: _hhmm(cours.debut),
            ),
            style: textes.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// La seance d'enseignant, vue comme la `Seance` que la journee partagee sait
/// lire.
///
/// **Une conversion, pas un second modele.** `construireJournee` est le seul
/// point d'entree correct pour meler cours, pauses et prieres, et `TimelineRow`
/// le seul gabarit de ligne : les deux datent d'avant le pivot et raisonnent en
/// eleve unique. Plutot qu'une colonne locale, la seance de groupe est traduite
/// dans leur vocabulaire : `elevePrenom` porte le **nom du groupe** et
/// `eleveIdentifiant` son **effectif**, qui sont ce que la ligne doit dire d'un
/// cours de groupe.
///
/// `ponytail:` dette assumee. Plafond : un champ de modele partage employe pour
/// un libelle. Chemin de reprise : un champ de groupe sur `EntreeJournee` ou un
/// parametre de `TimelineRow`, demande dans `CONTRACT_REQUEST_A.md`. Les six
/// champs d'identite non repris (`eleveId`, les trois de l'enseignant) ne sont
/// lus par aucune des quatre fonctions consommatrices.
Seance _versSeance(SeanceEnseignant seance) {
  final String? libelle = seance.groupeLibelle;
  return Seance(
    id: seance.id,
    debut: seance.debut,
    fin: seance.fin,
    statut: seance.statut,
    eleveId: '',
    elevePrenom: libelle == null || libelle.isEmpty
        ? t.enseignant.journee.coursIndividuel
        : libelle,
    eleveIdentifiant: seance.estGroupe
        ? _effectif(seance.nbParticipants)
        : '',
    enseignantId: '',
    enseignantPrenom: '',
    enseignantIdentifiant: '',
    minutesInterruption: seance.minutesInterruption,
  );
}

/// Combien d'eleves, au singulier ou au pluriel.
String _effectif(int nombre) => nombre == 1
    ? t.enseignant.journee.effectifUn
    : t.enseignant.journee.effectif(nombre: '$nombre');

/// Comment nommer un eleve dans une alerte : son prenom, sinon son identifiant
/// immuable quand la base l'a masque. **Jamais un nom de famille** : la vue
/// n'en porte aucun.
String _nommer(PresenceParticipant ligne) =>
    ligne.prenom.trim().isEmpty ? ligne.identifiantImmuable : ligne.prenom;

/// L'heure locale d'un instant, sur deux chiffres.
String _hhmm(DateTime quand) =>
    '${quand.hour.toString().padLeft(2, '0')}:'
    '${quand.minute.toString().padLeft(2, '0')}';

/// Le temps restant avant le debut, en heures et minutes.
String _minuteur(Duration reste) {
  final int minutes = reste.inMinutes;
  if (minutes <= 0) {
    return t.enseignant.journee.minuteurImminent;
  }
  if (minutes < Duration.minutesPerHour) {
    return t.enseignant.journee.minuteurMinutes(minutes: '$minutes');
  }
  return t.enseignant.journee.minuteurHeures(
    heures: '${minutes ~/ Duration.minutesPerHour}',
    minutes: (minutes % Duration.minutesPerHour).toString().padLeft(2, '0'),
  );
}

/// Vrai quand deux instants tombent le meme jour civil local.
bool _memeJour(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
