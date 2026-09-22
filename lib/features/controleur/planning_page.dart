import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/controle/service_controle.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/service_planning.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/service_video.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import 'vue_planning.dart';

/// `CTR-01` : le planning global du controle qualite.
///
/// **La seule destination du role** : un controleur n'a qu'un travail, donc
/// aucune barre de navigation (`parcours-utilisateurs.md`, modele de
/// navigation). L'ecran repond a une seule question, celle que
/// `02-regles-ux.md` lui assigne : « qu'est-ce qui necessite une verification ».
///
/// Trois choix de rendu, tous tenus par un test :
///
///   * **l'heure locale et l'heure UTC, toutes les deux** (section 4 des
///     parcours). L'academie est a cheval sur plusieurs fuseaux ; l'heure locale
///     sert a savoir quand entrer, l'heure UTC a parler de la meme seance avec
///     quelqu'un qui n'est pas dans le meme pays. Aucune des deux ne suffit
///     seule, et la seconde ne se deduit pas de tete ;
///   * **le bouton d'entree n'est pose que sur ce qui a lieu maintenant.**
///     Ailleurs, pas de bouton grise : un bouton qui echoue apres le geste coute
///     plus cher en confiance qu'un bouton absent, et c'est deja la regle de
///     `ENS-02` ;
///   * **le rappel de la journalisation est permanent**, comme le bandeau de la
///     salle l'est pour les participants. L'ADR-011 fait de la visite une
///     fonction annoncee a tous et tracee pour chacun : l'ecran qui la declenche
///     est le dernier endroit ou l'on devrait le decouvrir apres coup.
///
/// Le bouton porte le niveau **secondaire**, pas l'aplat sature : une liste de
/// vingt cours en direct ferait vingt zones pleines, et la regle de la zone
/// pleine unique n'en admet qu'une par ecran
/// (`01-systeme-visuel.md` section 3).
class PlanningControleurPage extends ConsumerStatefulWidget {
  /// Cree le planning du controle qualite.
  const PlanningControleurPage({super.key, this.horloge = DateTime.now});

  /// D'ou vient l'instant courant.
  ///
  /// Injectable comme sur `TUT-01` et `ELV-02` : le partage entre « en cours »
  /// et « a venir » se compte en minutes, et un test cale sur l'horloge de la
  /// machine changerait de resultat selon l'heure a laquelle la CI le lance.
  final DateTime Function() horloge;

  @override
  ConsumerState<PlanningControleurPage> createState() =>
      _PlanningControleurPageEtat();
}

class _PlanningControleurPageEtat
    extends ConsumerState<PlanningControleurPage> {
  /// Le pas de rafraichissement.
  ///
  /// Une minute : c'est la resolution des heures affichees, et c'est aussi ce
  /// qui fait passer une ligne de « a venir » a « en cours » sans que personne
  /// ne recharge la page. Relire a la seconde ferait soixante lectures par
  /// minute pour une liste qui ne bouge qu'aux heures rondes.
  static const Duration pas = Duration(minutes: 1);

  Timer? _minuteur;
  late DateTime _maintenant = widget.horloge();
  String? _enseignantId;
  FiltrePlanning _filtre = FiltrePlanning.tous;
  String? _echec;
  String? _entreeEnCours;

  @override
  void initState() {
    super.initState();
    _minuteur = Timer.periodic(pas, (Timer _) {
      if (!mounted) {
        return;
      }
      setState(() => _maintenant = widget.horloge());
      // Relire, et pas seulement recalculer : une seance peut etre creee,
      // annulee ou basculee en incident pendant que l'ecran est ouvert.
      ref.invalidate(planningGlobalProvider);
    });
  }

  @override
  void dispose() {
    // La lecon de `N4` : un flux qui ne s'annule pas continue d'attendre apres
    // la sortie de l'ecran.
    _minuteur?.cancel();
    super.dispose();
  }

  Future<void> _observer(LignePlanning ligne) async {
    setState(() {
      _entreeEnCours = ligne.seance.id;
      _echec = null;
    });
    try {
      await ref.read(serviceVideoProvider).observerEnControle(ligne.seance.id);
    } on Object {
      // Le refus ne se detaille pas : la base ne dit pas si la seance vient de
      // se clore ou si le compte a perdu son role, et l'ecran n'a pas a
      // l'inventer.
      if (mounted) {
        setState(() {
          _entreeEnCours = null;
          _echec = t.controleur.planning.entreeRefusee;
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _entreeEnCours = null);
    GoRouter.of(context).go(
      Routes.salle,
      // Le billet passe par `extra`, jamais par l'URL (ADR-005) : une adresse
      // de salle copiee ne rouvre rien, pas meme pour un controleur.
      extra: BilletSalle(
        sessionId: ligne.seance.id,
        emisA: DateTime.now(),
        enseignantPrenom: ligne.seance.enseignantPrenom,
      ),
    );
  }

  void _changerEtat(FiltrePlanning filtre) => setState(() => _filtre = filtre);

  void _changerEnseignant(String? id) => setState(() => _enseignantId = id);

  void _toutAfficher() => setState(() {
    _filtre = FiltrePlanning.tous;
    _enseignantId = null;
  });

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Seance>> planning = ref.watch(planningGlobalProvider);
    final VuePlanning vue = VuePlanning.depuis(
      seances: planning.value ?? const <Seance>[],
      maintenant: _maintenant,
      enseignantId: _enseignantId,
      filtre: _filtre,
    );

    return PageShell(
      titre: t.controleur.planning.titre,
      // La collection defile elle-meme : l'en-tete de colonnes reste collee en
      // haut du tableau, et les filtres restent atteignables sans remonter.
      defilante: false,
      entete: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SettingRow(
            title: t.compte.titre,
            description: t.compte.profilDetail,
            icon: AppIcons.profil,
            onPress: () => GoRouter.of(context).push(Routes.compte),
          ),
          Ecart.vMd,
          _Entete(
            vue: vue,
            filtre: _filtre,
            enseignantId: _enseignantId,
            echec: _echec,
            onEtat: _changerEtat,
            onEnseignant: _changerEnseignant,
          ),
        ],
      ),
      // Plus d'`Expanded` ici : `PageShell` borne desormais la hauteur de son
      // contenu en mode `defilante: false`.
      child: _Corps(
        vue: vue,
        chargement: planning.isLoading,
        erreur: planning.hasError,
        maintenant: _maintenant,
        entreeEnCours: _entreeEnCours,
        onObserver: _observer,
        onReessayer: () => ref.invalidate(planningGlobalProvider),
        onToutAfficher: _toutAfficher,
      ),
    );
  }
}

/// Le rappel permanent, le retour local, puis les deux rangees de filtres.
class _Entete extends StatelessWidget {
  const _Entete({
    required this.vue,
    required this.filtre,
    required this.enseignantId,
    required this.echec,
    required this.onEtat,
    required this.onEnseignant,
  });

  final VuePlanning vue;
  final FiltrePlanning filtre;
  final String? enseignantId;
  final String? echec;
  final void Function(FiltrePlanning) onEtat;
  final void Function(String?) onEnseignant;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          child: Text(
            t.controleur.planning.visiteJournalisee,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ),
        LocalFeedback(message: echec),
        Ecart.vLg,
        // Les etats ne dependent d'aucune lecture reussie : la rangee s'affiche
        // meme quand le planning n'a pas pu etre lu.
        _Rangee(
          pilules: <Widget>[
            for (final FiltrePlanning valeur in FiltrePlanning.values)
              FilterPill(
                libelle: switch (valeur) {
                  FiltrePlanning.tous => t.controleur.planning.tousEtats,
                  FiltrePlanning.enCours => t.controleur.planning.etatEnCours,
                  FiltrePlanning.aVenir => t.controleur.planning.etatAVenir,
                  FiltrePlanning.incident => t.controleur.planning.etatIncident,
                },
                compteur: switch (valeur) {
                  FiltrePlanning.tous => null,
                  FiltrePlanning.enCours => vue.nombreEnCours,
                  FiltrePlanning.aVenir => vue.nombreAVenir,
                  FiltrePlanning.incident => vue.nombreIncident,
                },
                retenue: filtre == valeur,
                onPress: () => onEtat(valeur),
              ),
          ],
        ),
        if (vue.enseignants.length > 1) ...<Widget>[
          Ecart.vSm,
          _Rangee(
            pilules: <Widget>[
              FilterPill(
                libelle: t.controleur.planning.tousEnseignants,
                retenue: enseignantId == null,
                onPress: () => onEnseignant(null),
              ),
              for (final FacetteEnseignant e in vue.enseignants)
                FilterPill(
                  libelle: e.prenom,
                  compteur: e.nombre,
                  retenue: enseignantId == e.id,
                  onPress: () =>
                      onEnseignant(enseignantId == e.id ? null : e.id),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Une rangee de pilules qui passe a la ligne plutot que de defiler.
class _Rangee extends StatelessWidget {
  const _Rangee({required this.pilules});

  final List<Widget> pilules;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: pilules,
  );
}

/// La liste, et ses cinq etats.
class _Corps extends StatelessWidget {
  const _Corps({
    required this.vue,
    required this.chargement,
    required this.erreur,
    required this.maintenant,
    required this.entreeEnCours,
    required this.onObserver,
    required this.onReessayer,
    required this.onToutAfficher,
  });

  final VuePlanning vue;
  final bool chargement;
  final bool erreur;
  final DateTime maintenant;
  final String? entreeEnCours;
  final Future<void> Function(LignePlanning) onObserver;
  final VoidCallback onReessayer;
  final VoidCallback onToutAfficher;

  @override
  Widget build(BuildContext context) {
    // L'erreur ne remplace la liste que si rien n'a ete lu : une relecture qui
    // echoue ne doit pas effacer le planning deja affiche.
    if (erreur && vue.total == 0) {
      return EmptyState(
        message: t.controleur.planning.erreur,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: onReessayer,
      );
    }

    if (vue.total == 0 && chargement) {
      // Pas le mot « Chargement » : la forme de ce qui arrive.
      return const Skeleton.liste(lignes: 5);
    }

    if (vue.lignes.isEmpty) {
      // Un planning vide sous filtre est une impasse dont on sort ; un planning
      // vide tout court n'est pas une panne (`02-regles-ux.md` section 6).
      return vue.impasseDeFiltre
          ? EmptyState(
              message: t.controleur.planning.videFiltre,
              invitation: t.controleur.planning.videFiltreDetail,
              libelleAction: t.controleur.planning.effacerFiltres,
              onAction: onToutAfficher,
            )
          : EmptyState(
              message: t.controleur.planning.vide,
              invitation: t.controleur.planning.videDetail,
              registre: RegistreVide.subi,
            );
    }

    return DataCollection<LignePlanning>(
      lignes: vue.lignes,
      cle: (LignePlanning l) => ValueKey<String>(l.seance.id),
      colonnes: colonnesPlanning(
        maintenant: maintenant,
        entreeEnCours: entreeEnCours,
        onObserver: onObserver,
      ),
      piedDePage: _PiedDePage(vue: vue),
    );
  }
}

/// Ce qui suit la derniere ligne : ce que la lecture n'a pas montre.
class _PiedDePage extends StatelessWidget {
  const _PiedDePage({required this.vue});

  final VuePlanning vue;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Text(
      vue.tronquee
          ? t.controleur.planning.tronquee(nombre: '${vue.total}')
          : (vue.total == 1
                ? t.controleur.planning.finUne
                : t.controleur.planning.fin(nombre: '${vue.total}')),
      style: palette.inkMuted.applyTo(textes.bodySmall ?? const TextStyle()),
    );
  }
}

/// Les colonnes du planning, communes au tableau dense et aux cartes.
///
/// Une seule definition pour les deux rendus : c'est la regle de
/// `05-regles-responsive.md` section 4, portee par `DataCollection`.
@visibleForTesting
List<ColonneDonnees<LignePlanning>> colonnesPlanning({
  required DateTime maintenant,
  required String? entreeEnCours,
  required Future<void> Function(LignePlanning) onObserver,
}) => <ColonneDonnees<LignePlanning>>[
  ColonneDonnees<LignePlanning>(
    titre: t.controleur.planning.colonneEnseignant,
    role: RoleColonne.identifiante,
    flex: 3,
    // Prenom ET identifiant immuable : deux enseignants peuvent partager un
    // prenom, et c'est justement sur celui-la que le controle porte (ADR-008,
    // jamais de nom de famille).
    texte: (LignePlanning l) =>
        '${l.seance.enseignantPrenom} · ${l.seance.enseignantIdentifiant}',
  ),
  ColonneDonnees<LignePlanning>(
    titre: t.controleur.planning.colonneEleve,
    flex: 3,
    texte: (LignePlanning l) =>
        '${l.seance.elevePrenom} · ${l.seance.eleveIdentifiant}',
  ),
  ColonneDonnees<LignePlanning>(
    titre: t.controleur.planning.colonneHeure,
    flex: 2,
    tabulaire: true,
    texte: (LignePlanning l) => _heureLocale(l.seance, maintenant),
  ),
  ColonneDonnees<LignePlanning>(
    titre: t.controleur.planning.colonneEtat,
    flex: 2,
    texte: (LignePlanning l) => _libelleEtat(l.etat),
    rendu: (BuildContext _, LignePlanning l) =>
        StatusPill(libelle: _libelleEtat(l.etat), ton: _ton(l.etat)),
  ),
  ColonneDonnees<LignePlanning>(
    titre: t.controleur.planning.colonneUtc,
    // Sur sa propre ligne en rendu carte : l'heure UTC est une precision, elle
    // ne se lit pas dans la meme foulee que le reste.
    role: RoleColonne.aPart,
    flex: 2,
    tabulaire: true,
    texte: (LignePlanning l) => t.controleur.planning.plageUtc(
      debut: _hhmm(l.seance.debut.toUtc()),
      fin: _hhmm(l.seance.fin.toUtc()),
    ),
  ),
  ColonneDonnees<LignePlanning>(
    titre: t.controleur.planning.colonneEntree,
    role: RoleColonne.aPart,
    flex: 2,
    // Vide quand la seance n'a pas lieu maintenant : c'est ce vide qui fait
    // disparaitre la cellule de la carte, plutot qu'un bouton inerte.
    texte: (LignePlanning l) =>
        l.observable ? t.controleur.planning.observer : '',
    rendu: (BuildContext _, LignePlanning l) => l.observable
        ? ActionPrincipale(
            libelle: t.controleur.planning.observer,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
            enCours: entreeEnCours == l.seance.id,
            onPress: () => unawaited(onObserver(l)),
          )
        : const SizedBox.shrink(),
  ),
];

String _libelleEtat(EtatLignePlanning etat) => switch (etat) {
  EtatLignePlanning.enCours => t.controleur.planning.etatEnCours,
  EtatLignePlanning.aVenir => t.controleur.planning.etatAVenir,
  EtatLignePlanning.incident => t.controleur.planning.etatIncident,
};

/// Le ton d'un etat.
///
/// `avertissement` pour l'incident, jamais `alerte` : un cours qui a mal tourne
/// se verifie, il ne condamne personne avant d'avoir ete regarde.
TonEtat _ton(EtatLignePlanning etat) => switch (etat) {
  EtatLignePlanning.enCours => TonEtat.succes,
  EtatLignePlanning.aVenir => TonEtat.neutre,
  EtatLignePlanning.incident => TonEtat.avertissement,
};

/// La plage locale, avec le jour quand ce n'est pas aujourd'hui.
String _heureLocale(Seance seance, DateTime maintenant) {
  final String debut = _hhmm(seance.debut);
  final String fin = _hhmm(seance.fin);
  final bool memeJour =
      seance.debut.year == maintenant.year &&
      seance.debut.month == maintenant.month &&
      seance.debut.day == maintenant.day;
  return memeJour
      ? t.controleur.planning.plage(debut: debut, fin: fin)
      : t.controleur.planning.plageAutreJour(
          jour: t.disponibilites.joursCourts[seance.debut.weekday - 1],
          debut: debut,
          fin: fin,
        );
}

/// L'heure d'un instant, sur deux chiffres.
String _hhmm(DateTime quand) =>
    '${quand.hour.toString().padLeft(2, '0')}:'
    '${quand.minute.toString().padLeft(2, '0')}';
