import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/matching/service_matching.dart';
import '../../core/planning/journee.dart';
import '../../core/planning/service_planning.dart';
import '../../core/priere/reglages_priere.dart';
import '../../core/priere/service_priere.dart';
import '../../core/regles/service_regles.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/timeline_row.dart';

/// `ENS-02` : la journee de l'enseignant, en une seule colonne.
///
/// **Cours, pauses et prieres sont des entrees de meme nature**, du haut vers
/// le bas. C'est la demande explicite des specs produit, et elle interdit un
/// bloc « prieres » separe : une interruption doit se lire a sa place dans le
/// deroule, pas dans un encadre a cote. Le gabarit est donc litteralement le
/// meme pour les trois sortes, seul le contenu change.
///
/// **Le bouton de lancement existe depuis le lot N3**, et seulement dans la
/// fenetre ou il peut aboutir : de dix minutes avant le debut du cours jusqu'a
/// sa fin. Hors de cette fenetre, une phrase dit quand il s'ouvrira, plutot
/// qu'un bouton grise -- un bouton qui echoue apres le geste coute plus cher en
/// confiance qu'un bouton absent.
///
/// La fenetre du client est la meme que celle de la base, et c'est la base qui
/// tranche : `autoriser_jeton_video()` refuse le jeton avant `debut - 10 min`
/// et apres `fin + 15 min` (ADR-005). Le seuil pose ici ne fait qu'eviter de
/// proposer un geste dont on sait qu'il serait refuse.
///
/// Les heures affichees sont celles de l'appareil. Aucune mention de fuseau
/// n'est posee ici, contrairement a la grille de `ENS-06` : les seances et les
/// prieres sont des instants absolus, et `mon_fuseau()` dit ou l'enseignant
/// **pose** ses creneaux, pas ou il se trouve. Annoncer « heures affichees en
/// Europe/Paris » a un enseignant en deplacement serait faux.
/// A partir de quand la salle s'ouvre a l'enseignant.
///
/// Le meme seuil que la base (ADR-005 : `debut - 10 minutes`), pose ici pour
/// **ne pas proposer** un geste dont on sait qu'il serait refuse. Ce n'est pas
/// une barriere : c'est `autoriser_jeton_video()` qui refuse, et elle refuserait
/// aussi bien si ce seuil etait faux.
///
/// L'enseignant l'obtient avant l'eleve, dont l'accueil n'offre « Rejoindre »
/// qu'en direct : c'est lui qui ouvre la salle, verifie son micro et accueille.
const Duration seuilOuvertureSalle = Duration(minutes: 10);

class JourneePage extends ConsumerStatefulWidget {
  /// Cree l'ecran de la journee.
  const JourneePage({super.key});

  @override
  ConsumerState<JourneePage> createState() => _JourneePageEtat();
}

class _JourneePageEtat extends ConsumerState<JourneePage> {
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
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? monId = ref.watch(sessionProvider).profileId;

    if (monId == null) {
      return PageShell(
        child: EmptyState(message: t.commun.chargement, invitation: ''),
      );
    }

    final AsyncValue<List<Seance>> seances = ref.watch(seancesProvider);
    final AsyncValue<ReglagesPriere?> reglages = ref.watch(
      reglagesPriereProvider(monId),
    );
    // La pause vient de `regle_effective()`, jamais d'une constante : elle peut
    // differer d'un profil a l'autre (ADR-017 section 2.4, invariant I10).
    final AsyncValue<int> pause = ref.watch(
      valeurRegleProvider((profilId: monId, cle: CleRegle.pauseEntreCours)),
    );
    final AsyncValue<List<EleveEnAttente>> feed = ref.watch(
      elevesEnAttenteProvider,
    );

    final List<Seance> toutes = seances.value ?? const <Seance>[];
    final Seance? dominant = prochainCours(toutes, _maintenant);

    // Les bornes du jour civil local. `DateTime(annee, mois, jour + 1)` plutot
    // qu'une addition de 24 heures : deux fois par an, une journee civile ne
    // dure pas vingt-quatre heures, et la colonne perdrait ou doublerait une
    // heure de cours.
    final DateTime debutJour = DateTime(
      _maintenant.year,
      _maintenant.month,
      _maintenant.day,
    );
    final DateTime finJour = DateTime(
      _maintenant.year,
      _maintenant.month,
      _maintenant.day + 1,
    );

    final List<EntreeJournee> journee = construireJournee(
      seances: toutes,
      reglages: reglages.value,
      debut: debutJour,
      fin: finJour,
      // Une regle illisible ne se remplace pas par une valeur inventee : sans
      // elle, aucun trou n'est declare pause, et les cours restent exacts.
      pauseMaximale: Duration(minutes: pause.value ?? 0),
    );

    final List<EntreeJournee> coursDuJour = journee
        .where((EntreeJournee e) => e.sorte == SorteEntree.cours)
        .toList();
    final bool journeeFinie =
        coursDuJour.isNotEmpty &&
        coursDuJour.every((EntreeJournee e) => !_maintenant.isBefore(e.fin));

    // Le feed rend **une ligne par creneau compatible** : le meme eleve y
    // figure autant de fois qu'il propose d'heures que cet enseignant peut
    // tenir. Compter les lignes annoncerait quatre familles la ou une seule
    // attend.
    final int enAttente = (feed.value ?? const <EleveEnAttente>[])
        .map((EleveEnAttente e) => e.eleveId)
        .toSet()
        .length;

    final bool enChargement = seances.isLoading && seances.value == null;

    return PageShell(
      titre: t.enseignant.journee.titre,
      child: enChargement
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Skeleton.tuileBento(hauteur: 160),
                Ecart.vXl,
                Skeleton.ligneTimeline(lignes: 3),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _BlocDominant(seance: dominant, maintenant: _maintenant),
          if (seances.hasError) ...<Widget>[
            Ecart.vSm,
            Text(
              t.enseignant.journee.erreur,
              // L'encre d'alerte, jamais la paire : `surfaceAlert`
              // ecrit en blanc, illisible sur la page.
              style: palette.inkAlert.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ],
          Ecart.vXl,
          Text(t.enseignant.journee.colonne, style: textes.titleMedium),
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
          Ecart.vXl,
          _BlocMatching(nombre: enAttente),
        ],
      ),
    );
  }
}

/// Le bloc dominant : le cours en cours, sinon le prochain a venir.
class _BlocDominant extends StatelessWidget {
  const _BlocDominant({required this.seance, required this.maintenant});

  final Seance? seance;
  final DateTime maintenant;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final Seance? cours = seance;

    if (cours == null) {
      return EmptyState(
        message: t.enseignant.journee.aucunCours,
        invitation: t.enseignant.journee.aucunCoursDetail,
        // Un constat, pas une porte : l'enseignant ne quitte pas cet ecran
        // pour agir, le bloc matching en dessous le fait.
        registre: RegistreVide.subi,
      );
    }

    final bool enCours = cours.enCoursA(maintenant);
    final bool aujourdhui = _memeJour(cours.debut, maintenant);

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
          Text(
            cours.elevePrenom,
            style: textes.headlineSmall ?? const TextStyle(),
          ),
          // Prenom et identifiant immuable, jamais le nom de famille (ADR-008).
          Text(
            cours.eleveIdentifiant,
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
          if (cours.avantDebut(maintenant) <= seuilOuvertureSalle ||
              enCours)
            ActionPrincipale(
              libelle: t.enseignant.journee.lancer,
              onPress: () => GoRouter.of(context).go(
                Routes.salle,
                // Le billet passe par `extra`, jamais par l'URL (ADR-005) :
                // une adresse de salle copiee ne rouvre rien.
                extra: BilletSalle(
                  sessionId: cours.id,
                  emisA: DateTime.now(),
                ),
              ),
            )
          else
            Text(
              t.enseignant.journee.lancementPlusTard,
              style: textes.bodySmall ?? const TextStyle(),
            ),
        ],
      ),
    );
  }
}

/// Ce que la colonne dit quand la journee est vide.
class _RienAujourdhui extends StatelessWidget {
  const _RienAujourdhui({required this.prochain});

  final Seance? prochain;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final Seance? cours = prochain;

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

/// Le bloc secondaire : combien attendent, et la porte vers `ENS-06`.
class _BlocMatching extends StatelessWidget {
  const _BlocMatching({required this.nombre});

  final int nombre;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String phrase = switch (nombre) {
      0 => t.enseignant.journee.aucunEleveEnAttente,
      1 => t.enseignant.journee.unEleveEnAttente,
      _ => t.enseignant.journee.elevesEnAttente(nombre: '$nombre'),
    };

    return BentoTile(
      libelleSemantique: phrase,
      onPress: () => GoRouter.of(context).go(Routes.enseignantCreneaux),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(phrase, style: textes.titleMedium),
          Ecart.vXs,
          Text(
            t.enseignant.journee.voirCreneaux,
            style: palette.inkAccent.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

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
