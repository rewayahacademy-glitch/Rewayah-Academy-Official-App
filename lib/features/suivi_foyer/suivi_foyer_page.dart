import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/service_planning.dart';
import '../../core/presence/service_presence.dart';
import '../../core/suivi/service_suivi.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/ligne_presence.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import 'vue_suivi_foyer.dart';

/// `TUT-06` : le suivi du foyer.
///
/// L'ecran repond a « comment se passent les cours de mes enfants », la ou
/// `TUT-01` repond a « que se passe-t-il maintenant ». Meme donnee, lue dans
/// l'autre sens -- du plus recent vers le passe -- et augmentee de l'etat de
/// presence, que l'accueil n'affiche jamais.
///
/// Trois choix de rendu, tous tenus par un test :
///
///   * **le sort du cours passe avant l'etat de l'enfant.** Un cours annule, un
///     cours ou l'enseignant ne s'est pas presente, un cours tombe en panne
///     n'ont produit aucun evenement de salle : `etat_presence()` en deduit
///     « absente », ce qui est exact au sens de la base et faux au sens de la
///     phrase. Ces cours disent donc ce qu'ils sont, et rien de l'enfant ;
///   * **la pastille sans phrase de contexte.** `LignePresence` accompagne
///     l'etat d'une duree -- « en salle depuis 12 min » -- qui n'a de sens que
///     pendant le cours ; comptee depuis un cours d'il y a trois semaines, elle
///     afficherait des dizaines de milliers de minutes. Le libelle vient
///     pourtant de `LignePresence.libelle`, pour que le tableau de presence de
///     la salle et le suivi ne nomment jamais un etat autrement ;
///   * **aucune action.** L'ecran est une lecture. Corriger un etat, excuser une
///     absence, tout cela appartient a l'enseignant et a l'administration, avec
///     motif et entree de journal (section 6.5 de la specification d'etape). Un
///     bouton ici donnerait au foyer le droit de corriger ce qui compte pour la
///     paie de l'enseignant.
class SuiviFoyerPage extends ConsumerStatefulWidget {
  /// Cree le suivi du foyer.
  const SuiviFoyerPage({super.key, this.horloge = DateTime.now});

  /// D'ou vient l'instant courant.
  ///
  /// Injectable comme sur `TUT-01`, `ELV-02` et `CTR-01` : le partage entre
  /// « Aujourd'hui », « Hier » et une date se joue sur le jour civil, et un test
  /// cale sur l'horloge de la machine changerait de resultat selon l'heure a
  /// laquelle la CI le lance.
  final DateTime Function() horloge;

  @override
  ConsumerState<SuiviFoyerPage> createState() => _SuiviFoyerPageEtat();
}

class _SuiviFoyerPageEtat extends ConsumerState<SuiviFoyerPage> {
  Timer? _minuteur;
  late DateTime _maintenant = widget.horloge();
  String? _enfantId;

  @override
  void initState() {
    super.initState();
    // Une minute, comme `TUT-01`. **Sans relecture**, contrairement a `CTR-01` :
    // un historique ne bouge pas pendant qu'on le regarde, et le seul fait qui
    // change tout seul est le passage a minuit, qui fait glisser « Aujourd'hui »
    // sur « Hier ».
    _minuteur = Timer.periodic(const Duration(minutes: 1), (Timer _) {
      if (!mounted) {
        return;
      }
      setState(() => _maintenant = widget.horloge());
    });
  }

  @override
  void dispose() {
    // La lecon de `N4` : un minuteur qui ne s'annule pas continue de courir
    // apres la sortie de l'ecran.
    _minuteur?.cancel();
    super.dispose();
  }

  void _changerEnfant(String? id) => setState(() => _enfantId = id);

  void _toutAfficher() => setState(() => _enfantId = null);

  void _relire() {
    ref
      ..invalidate(seancesDuSuiviProvider)
      ..invalidate(presenceDuSuiviProvider);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Seance>> seances = ref.watch(seancesDuSuiviProvider);
    final AsyncValue<List<PresenceParticipant>?> presences = ref.watch(
      presenceDuSuiviProvider,
    );

    final VueSuiviFoyer vue = VueSuiviFoyer.depuis(
      seances: seances.value ?? const <Seance>[],
      // `.value` et non `valueOrNull` : Riverpod 3 ne connait pas le second.
      // Le double `null` est volontaire -- un provider qui n'a rien rendu et une
      // lecture qui a rendu « indisponible » donnent tous deux l'inconnu, ce qui
      // est la bonne reponse dans les deux cas (invariant J3).
      presences: presences.value,
      maintenant: _maintenant,
      enfantId: _enfantId,
    );

    return PageShell(
      titre: t.tuteur.suivi.titre,
      // La collection defile elle-meme : l'en-tete de colonnes reste collee en
      // haut du tableau, et les filtres restent atteignables sans remonter.
      defilante: false,
      entete: _Entete(
        vue: vue,
        enfantId: _enfantId,
        onEnfant: _changerEnfant,
      ),
      // Plus d'`Expanded` ici : `PageShell` borne desormais la hauteur de son
      // contenu en mode `defilante: false`.
      child: _Corps(
        vue: vue,
        chargement: seances.isLoading,
        // Seule la lecture des cours peut vider l'ecran. Une presence
        // indisponible n'est pas une erreur d'ecran : elle a deja sa reponse,
        // ligne par ligne, et l'historique reste lisible sans elle.
        erreur: seances.hasError,
        maintenant: _maintenant,
        onReessayer: _relire,
        onToutAfficher: _toutAfficher,
      ),
    );
  }
}

/// La rangee de filtres, et elle seule.
///
/// Elle ne parait qu'a partir de deux enfants : un foyer qui n'en compte qu'un
/// n'a rien a filtrer, et une pilule unique toujours retenue est un ornement.
class _Entete extends StatelessWidget {
  const _Entete({
    required this.vue,
    required this.enfantId,
    required this.onEnfant,
  });

  final VueSuiviFoyer vue;
  final String? enfantId;
  final void Function(String?) onEnfant;

  @override
  Widget build(BuildContext context) {
    if (vue.enfants.length < 2) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: <Widget>[
          FilterPill(
            libelle: t.tuteur.suivi.tousLesEnfants,
            retenue: enfantId == null,
            onPress: () => onEnfant(null),
          ),
          for (final FacetteEnfant enfant in vue.enfants)
            FilterPill(
              libelle: enfant.prenom,
              compteur: enfant.nombre,
              retenue: enfantId == enfant.id,
              onPress: () =>
                  onEnfant(enfantId == enfant.id ? null : enfant.id),
            ),
        ],
      ),
    );
  }
}

/// La liste, et ses cinq etats.
class _Corps extends StatelessWidget {
  const _Corps({
    required this.vue,
    required this.chargement,
    required this.erreur,
    required this.maintenant,
    required this.onReessayer,
    required this.onToutAfficher,
  });

  final VueSuiviFoyer vue;
  final bool chargement;
  final bool erreur;
  final DateTime maintenant;
  final VoidCallback onReessayer;
  final VoidCallback onToutAfficher;

  @override
  Widget build(BuildContext context) {
    // L'erreur ne remplace la liste que si rien n'a ete lu : une relecture qui
    // echoue ne doit pas effacer l'historique deja affiche.
    if (erreur && vue.total == 0) {
      return EmptyState(
        message: t.tuteur.suivi.erreur,
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
      return vue.impasseDeFiltre
          ? EmptyState(
              message: t.tuteur.suivi.videFiltre,
              invitation: t.tuteur.suivi.videFiltreDetail,
              libelleAction: t.tuteur.suivi.effacerFiltres,
              onAction: onToutAfficher,
            )
          // Un foyer sans cours n'est pas une panne : c'est un foyer qui attend
          // le premier, et il n'a rien a faire pour l'obtenir -- l'attribution
          // se decide ailleurs. Donc aucun bouton (`02-regles-ux.md` section 6).
          : EmptyState(
              message: t.tuteur.suivi.vide,
              invitation: t.tuteur.suivi.videDetail,
              registre: RegistreVide.subi,
            );
    }

    return DataCollection<LigneSuivi>(
      lignes: vue.lignes,
      cle: (LigneSuivi l) => ValueKey<String>(l.seance.id),
      colonnes: colonnesSuivi(maintenant: maintenant),
      piedDePage: _PiedDePage(vue: vue),
    );
  }
}

/// Ce qui suit la derniere ligne : ce que la lecture n'a pas montre.
class _PiedDePage extends StatelessWidget {
  const _PiedDePage({required this.vue});

  final VueSuiviFoyer vue;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Text(
      vue.tronquee
          ? t.tuteur.suivi.tronquee(nombre: '${vue.total}')
          : (vue.total == 1
                ? t.tuteur.suivi.finUn
                : t.tuteur.suivi.fin(nombre: '${vue.total}')),
      style: palette.inkMuted.applyTo(textes.bodySmall ?? const TextStyle()),
    );
  }
}

/// Les colonnes du suivi, communes au tableau dense et aux cartes.
///
/// Une seule definition pour les deux rendus : c'est la regle de
/// `05-regles-responsive.md` section 4, portee par `DataCollection`.
@visibleForTesting
List<ColonneDonnees<LigneSuivi>> colonnesSuivi({required DateTime maintenant}) =>
    <ColonneDonnees<LigneSuivi>>[
      ColonneDonnees<LigneSuivi>(
        titre: t.tuteur.suivi.colonneDate,
        role: RoleColonne.identifiante,
        flex: 3,
        tabulaire: true,
        texte: (LigneSuivi l) => quand(l.seance.debut, maintenant),
      ),
      ColonneDonnees<LigneSuivi>(
        titre: t.tuteur.suivi.colonneEnfant,
        flex: 2,
        // Le prenom seul : un parent n'a pas besoin de l'identifiant immuable
        // de son propre enfant pour le reconnaitre, et deux enfants d'un meme
        // foyer qui partageraient un prenom se distingueraient par la pilule
        // qu'il vient de toucher.
        texte: (LigneSuivi l) => l.seance.elevePrenom,
      ),
      ColonneDonnees<LigneSuivi>(
        titre: t.tuteur.suivi.colonneEnseignant,
        flex: 3,
        // Prenom ET identifiant immuable, jamais le nom de famille (ADR-008) :
        // c'est ce qui permet a un foyer de nommer sans ambiguite l'enseignant
        // de son enfant dans une demande de reaffectation.
        texte: (LigneSuivi l) =>
            '${l.seance.enseignantPrenom} · ${l.seance.enseignantIdentifiant}',
      ),
      ColonneDonnees<LigneSuivi>(
        titre: t.tuteur.suivi.colonneEtat,
        role: RoleColonne.aPart,
        flex: 3,
        texte: libelleEtat,
        rendu: (BuildContext _, LigneSuivi l) =>
            StatusPill(libelle: libelleEtat(l), ton: tonDe(l)),
      ),
    ];

/// Le mot que porte la pastille d'une ligne.
///
/// **Le sort du cours d'abord, l'etat de l'enfant ensuite.** Le libelle d'un
/// etat de presence vient de `LignePresence.libelle`, jamais d'une seconde
/// table : la salle et le suivi doivent nommer le meme etat de la meme facon.
@visibleForTesting
String libelleEtat(LigneSuivi ligne) => switch (ligne.sort) {
  SortDuCours.annule => t.tuteur.suivi.annule,
  SortDuCours.nonTenu => t.tuteur.suivi.nonTenu,
  SortDuCours.tenu => LignePresence.libelle(ligne.presence.etat),
};

/// Le ton d'une ligne.
///
/// `avertissement` pour un cours non tenu, jamais `alerte` : ce n'est pas une
/// faute du foyer, et la couleur ne doit pas lui en faire porter une. Un cours
/// annule est neutre -- il a ete decide, il n'a pas echoue.
@visibleForTesting
TonEtat tonDe(LigneSuivi ligne) => switch (ligne.sort) {
  SortDuCours.annule => TonEtat.neutre,
  SortDuCours.nonTenu => TonEtat.avertissement,
  SortDuCours.tenu => ligne.presence.ton,
};

/// Quand un cours a eu lieu, en clair.
///
/// « Aujourd'hui » et « Hier » plutot qu'une date, parce que ce sont les deux
/// seuls jours qu'un parent compte de tete. Au dela, la date complete : un
/// « mardi » sans date serait ambigu des la deuxieme semaine, et c'est
/// exactement ce que la liste couvre.
///
/// Les bornes se calculent en composantes de date, jamais par soustraction de
/// vingt-quatre heures : la nuit du changement d'heure en compte vingt-trois.
@visibleForTesting
String quand(DateTime debut, DateTime maintenant) {
  final String heure = _hhmm(debut);
  final DateTime jour = DateTime(debut.year, debut.month, debut.day);
  final DateTime aujourdhui = DateTime(
    maintenant.year,
    maintenant.month,
    maintenant.day,
  );
  final DateTime hier = DateTime(
    maintenant.year,
    maintenant.month,
    maintenant.day - 1,
  );

  if (jour == aujourdhui) {
    return t.tuteur.suivi.aujourdhui(heure: heure);
  }
  if (jour == hier) {
    return t.tuteur.suivi.hier(heure: heure);
  }
  return t.tuteur.suivi.date(date: _jjmmaaaa(debut), heure: heure);
}

/// L'heure d'un instant, sur deux chiffres.
String _hhmm(DateTime quand) =>
    '${quand.hour.toString().padLeft(2, '0')}:'
    '${quand.minute.toString().padLeft(2, '0')}';

/// La date d'un instant, comme partout ailleurs dans le produit.
String _jjmmaaaa(DateTime quand) =>
    '${quand.day.toString().padLeft(2, '0')}/'
    '${quand.month.toString().padLeft(2, '0')}/${quand.year}';
