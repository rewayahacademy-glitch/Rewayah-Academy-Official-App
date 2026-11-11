import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/service_planning.dart';
import '../../core/presence/service_presence.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/suivi/service_suivi.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/ligne_presence.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/pays_enseignant.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../suivi_foyer/carte_messages_academie.dart';
import '../suivi_foyer/carte_suivi_pedagogique.dart';
import '../suivi_foyer/filtres_historique.dart' show libelleStatut, statutDe;
import '../suivi_foyer/vue_suivi_foyer.dart';
import 'entree_bibliotheque.dart';

/// Le suivi de l'eleve : une lecture de la meme projection que `TUT-06`.
///
/// La borne d'acces vient de `mes_seances_v` et `presence_seance_v`. Cette
/// page ne filtre donc pas les eleves cote client et ne rend aucune donnee
/// d'un autre participant.
class SuiviElevePage extends ConsumerStatefulWidget {
  /// Cree le suivi de l'eleve.
  const SuiviElevePage({super.key, this.horloge = DateTime.now});

  /// Horloge injectable pour les libelles de date et les durees de presence.
  final DateTime Function() horloge;

  @override
  ConsumerState<SuiviElevePage> createState() => _SuiviElevePageEtat();
}

class _SuiviElevePageEtat extends ConsumerState<SuiviElevePage> {
  Timer? _minuteur;
  late DateTime _maintenant = widget.horloge();

  @override
  void initState() {
    super.initState();
    _minuteur = Timer.periodic(const Duration(minutes: 1), (Timer _) {
      if (mounted) {
        setState(() => _maintenant = widget.horloge());
      }
    });
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  void _relire() {
    ref
      ..invalidate(seancesDeMonSuiviProvider)
      ..invalidate(presenceDuSuiviProvider);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Seance>> seances = ref.watch(
      seancesDeMonSuiviProvider,
    );
    final AsyncValue<List<PresenceParticipant>?> presences = ref.watch(
      presenceDuSuiviProvider,
    );
    final VueSuiviFoyer vue = VueSuiviFoyer.depuis(
      seances: seances.value ?? const <Seance>[],
      presences: presences.value,
      maintenant: _maintenant,
    );

    return PageShell(
      // Le titre de la page est celui de l'onglet actif (garde-cap,
      // 11/11/2026) : « Suivi » dans la barre de l'eleve adulte, « Ma classe »
      // sinon. Meme capacite que la barre.
      titre:
          ref.watch(
            sessionProvider.select((SessionState s) => s.barreEleveAdulte),
          )
          ? t.nav.eleve.suivi
          : t.nav.eleve.maClasse,
      defilante: false,
      // Plus d'`Expanded` ici : `PageShell` borne desormais la hauteur de son
      // contenu en mode `defilante: false`.
      child: _Corps(
        vue: vue,
        chargement: seances.isLoading,
        erreur: seances.hasError,
        // Lu seulement en echec : rien d'autre ne depend du reseau ici.
        horsLigne:
            seances.hasError && (ref.watch(horsLigneProvider).value ?? false),
        maintenant: _maintenant,
        onReessayer: _relire,
      ),
    );
  }
}

class _Corps extends StatelessWidget {
  const _Corps({
    required this.vue,
    required this.chargement,
    required this.erreur,
    required this.horsLigne,
    required this.maintenant,
    required this.onReessayer,
  });

  final VueSuiviFoyer vue;
  final bool chargement;
  final bool erreur;
  final bool horsLigne;
  final DateTime maintenant;
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    // SUIVI-ELEVE (07/11/2026) : « Où j'en suis » en tete, dans tous les
    // etats de la liste des seances (un eleve sans seance passee a deja une
    // etape), puis les messages de l'academie (D1-ter). Defile avec la page.
    // La Bibliotheque passe avant tout (garde-cap, 11/11/2026).
    const Widget tete = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // La Bibliotheque en tete de « Ma classe » (garde-cap, 11/11/2026).
        EntreeBibliothequeMaClasse(),
        CarteSuiviPedagogique(),
        CarteMessagesAcademie(),
      ],
    );

    if (erreur && vue.total == 0) {
      return _VideDefilant(
        tete: tete,
        child: horsLigne
            // EA-HL-DOUBLE-1 : le bandeau dit l'absence de reseau ; le bloc
            // dit ce qui manque.
            ? EtatSansDonnees(quoi: t.eleve.suivi.erreur, onAction: onReessayer)
            : EmptyState(
                message: t.eleve.suivi.erreur,
                icone: AppIcons.avertissement,
                libelleAction: t.commun.reessayer,
                onAction: onReessayer,
              ),
      );
    }

    if (vue.total == 0 && chargement) {
      return const Skeleton.liste(lignes: 5);
    }

    if (vue.lignes.isEmpty) {
      return _VideDefilant(
        tete: tete,
        child: EmptyState(
          message: t.eleve.suivi.vide,
          invitation: t.eleve.suivi.videDetail,
          registre: RegistreVide.subi,
        ),
      );
    }

    final Widget? erreurLecture = erreur
        ? Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(t.eleve.suivi.erreur),
                Ecart.vSm,
                ActionPrincipale(
                  libelle: t.commun.reessayer,
                  onPress: onReessayer,
                  niveau: NiveauAction.tertiaire,
                  pleineLargeur: false,
                ),
              ],
            ),
          )
        : null;

    return DataCollection<LigneSuivi>(
      // D1-ter (03/11/2026) : « Messages de l'académie » de l'eleve qui lit,
      // s'il y en a ; le serveur ne rend rien a un mineur. SUIVI-ELEVE : le
      // bloc « Où j'en suis » au-dessus. Defile avec la liste.
      tete: tete,
      lignes: vue.lignes,
      cle: (LigneSuivi ligne) => ValueKey<String>(ligne.seance.id),
      colonnes: _colonnesSuiviEleve(
        maintenant: maintenant,
        avecPays: vue.lignes.any(
          (LigneSuivi l) =>
              PaysEnseignant.nomAffichable(l.seance.enseignantPays) != null,
        ),
      ),
      piedDePage: erreurLecture == null
          ? _PiedDePage(vue: vue)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                erreurLecture,
                _PiedDePage(vue: vue),
              ],
            ),
    );
  }
}

class _PiedDePage extends StatelessWidget {
  const _PiedDePage({required this.vue});

  final VueSuiviFoyer vue;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle style =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    return Text(
      vue.tronquee
          ? t.eleve.suivi.tronquee(nombre: '${vue.total}')
          : (vue.total == 1
                ? t.eleve.suivi.finUn
                : t.eleve.suivi.fin(nombre: '${vue.total}')),
      style: palette.inkMuted.applyTo(style),
    );
  }
}

List<ColonneDonnees<LigneSuivi>> _colonnesSuiviEleve({
  required DateTime maintenant,
  bool avecPays = false,
}) => <ColonneDonnees<LigneSuivi>>[
  ColonneDonnees<LigneSuivi>(
    titre: t.eleve.suivi.colonneDate,
    role: RoleColonne.identifiante,
    flex: 3,
    tabulaire: true,
    texte: (LigneSuivi ligne) => _quand(ligne.seance.debut, maintenant),
  ),
  ColonneDonnees<LigneSuivi>(
    titre: t.eleve.suivi.colonneCours,
    flex: 3,
    texte: (_) => t.eleve.suivi.cours,
  ),
  ColonneDonnees<LigneSuivi>(
    titre: t.eleve.suivi.colonneEnseignant,
    flex: 5,
    texte: _enseignant,
  ),
  // ENS-PAYS-1 : le pays de l'enseignant, comme dans les tableaux de
  // l'administration, seulement quand une ligne au moins le porte (pas de
  // colonne vide avant BR-1).
  if (avecPays)
    ColonneDonnees<LigneSuivi>(
      titre: t.enseignant.profil.pays,
      role: RoleColonne.aPart,
      flex: 3,
      texte: (LigneSuivi l) =>
          PaysEnseignant.nomAffichable(l.seance.enseignantPays) ?? '',
      rendu: (BuildContext _, LigneSuivi l) =>
          PaysEnseignant(pays: l.seance.enseignantPays),
    ),
  // SUIVI-ELEVE (07/11/2026) : la meme regle que l'Historique du tuteur
  // (`statutDe`, `libelleStatut`) : la presence mesuree par le serveur, sinon
  // « en cours de verification » les premieres heures, puis « pas encore
  // connue ». Jamais l'etat en direct d'une salle fermee (« Lien coupe ») ;
  // l'etat en direct reste pour un cours a venir ou en cours.
  ColonneDonnees<LigneSuivi>(
    titre: t.eleve.suivi.colonneEtat,
    role: RoleColonne.aPart,
    flex: 4,
    texte: (LigneSuivi l) => _libelleEtat(l, maintenant),
    rendu: (BuildContext context, LigneSuivi ligne) => Semantics(
      label:
          '${t.eleve.suivi.colonneEtat} : ${_libelleEtat(ligne, maintenant)}',
      excludeSemantics: true,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        // Une seance annulee se reconnait d'un coup d'oeil (ANNUL-VIS-1).
        child: ligne.sort == SortDuCours.annule
            ? PastilleEtatSeance(
                etat: EtatPastilleSeance.annulee,
                libelle: libelleStatut(ligne),
              )
            : _enCours(ligne, maintenant)
            ? LignePresence(
                nom: t.eleve.suivi.moi,
                vue: ligne.presence,
                afficherConsolide: false,
              )
            : StatusPill(
                libelle: libelleStatut(ligne),
                ton: statutDe(ligne).ton,
              ),
      ),
    ),
  ),
];

/// Vrai tant que le cours n'est pas fini : l'etat en direct a alors un sens
/// (« Cours à venir », « En salle »). La mesure du serveur ne vaut qu'une
/// fois le cours fini (elle rend « absente » pour un cours a venir).
bool _enCours(LigneSuivi ligne, DateTime maintenant) =>
    ligne.sort == SortDuCours.tenu && ligne.seance.fin.isAfter(maintenant);

String _libelleEtat(LigneSuivi ligne, DateTime maintenant) =>
    _enCours(ligne, maintenant)
    ? LignePresence.libelle(ligne.presence.etat)
    : libelleStatut(ligne);

String _enseignant(LigneSuivi ligne) =>
    '${ligne.seance.enseignantPrenom} · ${ligne.seance.enseignantIdentifiant}';

String _quand(DateTime debut, DateTime maintenant) {
  final String heure = _hhmm(debut);
  final DateTime jour = DateTime(debut.year, debut.month, debut.day);
  final DateTime aujourdHui = DateTime(
    maintenant.year,
    maintenant.month,
    maintenant.day,
  );
  final DateTime hier = DateTime(
    maintenant.year,
    maintenant.month,
    maintenant.day - 1,
  );

  if (jour == aujourdHui) {
    return t.eleve.suivi.aujourdhui(heure: heure);
  }
  if (jour == hier) {
    return t.eleve.suivi.hier(heure: heure);
  }
  return t.eleve.suivi.date(date: _jjmmaaaa(debut), heure: heure);
}

String _hhmm(DateTime quand) =>
    '${quand.hour.toString().padLeft(2, '0')}:${quand.minute.toString().padLeft(2, '0')}';

String _jjmmaaaa(DateTime quand) =>
    '${quand.day.toString().padLeft(2, '0')}/${quand.month.toString().padLeft(2, '0')}/${quand.year}';

/// Un etat vide centre qui defile quand il ne tient pas : la page ne defile
/// pas (`defilante: false`), et la barre du bas du Mode Accessibilite
/// (MA-CMD-1, onglets de 72) lui laisse moins de hauteur a 390.
class _VideDefilant extends StatelessWidget {
  const _VideDefilant({required this.tete, required this.child});

  /// Ce qui precede l'etat (« Où j'en suis », messages), en haut, defilant.
  final Widget tete;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: contraintes.hasBoundedHeight
                  ? contraintes.maxHeight
                  : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[tete, child],
            ),
          ),
        );
      },
    );
  }
}
