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
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/ligne_presence.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/skeleton.dart';
import '../suivi_foyer/vue_suivi_foyer.dart';

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
      presences: presences.value,
      maintenant: _maintenant,
    );

    return PageShell(
      titre: t.eleve.suivi.titre,
      defilante: false,
      // Plus d'`Expanded` ici : `PageShell` borne desormais la hauteur de son
      // contenu en mode `defilante: false`.
      child: _Corps(
        vue: vue,
        chargement: seances.isLoading,
        erreur: seances.hasError,
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
    required this.maintenant,
    required this.onReessayer,
  });

  final VueSuiviFoyer vue;
  final bool chargement;
  final bool erreur;
  final DateTime maintenant;
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    if (erreur && vue.total == 0) {
      return EmptyState(
        message: t.eleve.suivi.erreur,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: onReessayer,
      );
    }

    if (vue.total == 0 && chargement) {
      return const Skeleton.liste(lignes: 5);
    }

    if (vue.lignes.isEmpty) {
      return EmptyState(
        message: t.eleve.suivi.vide,
        invitation: t.eleve.suivi.videDetail,
        registre: RegistreVide.subi,
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
      lignes: vue.lignes,
      cle: (LigneSuivi ligne) => ValueKey<String>(ligne.seance.id),
      colonnes: _colonnesSuiviEleve(maintenant: maintenant),
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
  ColonneDonnees<LigneSuivi>(
    titre: t.eleve.suivi.colonneEtat,
    role: RoleColonne.aPart,
    flex: 4,
    texte: _libelleEtat,
    rendu: (BuildContext context, LigneSuivi ligne) => Semantics(
      label: '${t.eleve.suivi.colonneEtat} : ${_libelleEtat(ligne)}',
      excludeSemantics: true,
      child: ligne.montrePresence
          ? LignePresence(
              nom: t.eleve.suivi.moi,
              vue: ligne.presence,
              afficherConsolide: false,
            )
          : ligne.sort == SortDuCours.annule
          // Une seance annulee se reconnait d'un coup d'oeil (ANNUL-VIS-1).
          ? Align(
              alignment: AlignmentDirectional.centerStart,
              child: PastilleEtatSeance(
                etat: EtatPastilleSeance.annulee,
                libelle: _libelleEtat(ligne),
              ),
            )
          : Text(
              _libelleEtat(ligne),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
    ),
  ),
];

String _enseignant(LigneSuivi ligne) =>
    '${ligne.seance.enseignantPrenom} · ${ligne.seance.enseignantIdentifiant}';

String _libelleEtat(LigneSuivi ligne) => switch (ligne.sort) {
  SortDuCours.annule => t.eleve.suivi.annule,
  SortDuCours.nonTenu => t.eleve.suivi.nonTenu,
  SortDuCours.tenu => LignePresence.libelle(ligne.presence.etat),
};

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
