import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/admin/service_qualite.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/zone_saisie.dart';

/// `ADM-14` : Pedagogie > Qualite, dernier ecran du domaine.
///
/// **Calcule, jamais stocke** : chaque anomalie vient de
/// `anomalies_qualite()` (migration `0024`), qui recoupe des tables deja
/// existantes (`sessions`/`lesson_reports`, `progression_exceptions`,
/// `evaluations`) sans rien dupliquer. Le premier type -- rapport manquant --
/// raccorde enfin le compteur « rapports manquants » d'`ADM-01`, present
/// depuis la toute premiere migration mais jamais consomme par aucun ecran.
///
/// **Le suivi enseignant** (mission) se lit directement sur la colonne
/// « Concerne » du groupe Rapports manquants -- pas un agregat separe : le
/// nom de l'enseignant qui doit un rapport y est deja visible, seance par
/// seance.
class QualitePage extends ConsumerStatefulWidget {
  /// Cree l'ecran de qualite.
  const QualitePage({super.key});

  @override
  ConsumerState<QualitePage> createState() => _QualitePageEtat();
}

enum _Filtre { toutes, ouvertes, traitees }

class _QualitePageEtat extends ConsumerState<QualitePage> {
  _Filtre _filtre = _Filtre.ouvertes;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<AnomalieQualite>> anomalies = ref.watch(
      anomaliesQualiteProvider,
    );

    return PageShell(
      titre: t.admin.qualite.titre,
      entete: SousNavigationDomaine(onglets: ongletsPedagogie(), indexActif: 5),
      defilante: false,
      // FILTRES-1b : une seule colonne de corps (intro, filtres, liste) qui
      // dit a `PageShell` la hauteur qui lui manque : a 320 px texte x2,
      // l'intro et la rangee de filtres ne laissent plus de place a la
      // liste, la page defile alors au lieu de deborder, et la liste garde
      // au moins un titre de groupe et une ligne lisibles.
      child: ColonneCorps(
        minimumEtire: DataCollection.minimumLisible(context),
        children: <Widget>[
          Text(t.admin.qualite.intro, style: textes.bodyMedium),
          Ecart.vXl,
          ...switch (anomalies) {
            AsyncValue<List<AnomalieQualite>>(hasValue: true) =>
              anomalies.requireValue.isEmpty
                  ? <Widget>[
                      EmptyState(
                        message: t.admin.qualite.aucune,
                        invitation: t.admin.qualite.aucuneDetail,
                        icone: AppIcons.succes,
                        registre: RegistreVide.bonneNouvelle,
                      ),
                    ]
                  : _corps(
                      context,
                      anomalies: anomalies.requireValue,
                      filtre: _filtre,
                      onFiltre: (_Filtre f) => setState(() => _filtre = f),
                      onTraiter: (AnomalieQualite a) =>
                          _ouvrirTraitement(context, ref, a),
                    ),
            AsyncValue<List<AnomalieQualite>>(hasError: true) => <Widget>[
              EmptyState(
                message: t.admin.qualite.erreur,
                icone: AppIcons.avertissement,
                libelleAction: t.commun.reessayer,
                onAction: () => ref.invalidate(anomaliesQualiteProvider),
              ),
            ],
            _ => const <Widget>[Skeleton.liste(lignes: 5)],
          },
        ],
      ),
    );
  }
}

bool _correspond(AnomalieQualite a, _Filtre f) => switch (f) {
  _Filtre.toutes => true,
  _Filtre.ouvertes => a.controleStatut == StatutControleQualite.ouvert,
  _Filtre.traitees => a.controleStatut == StatutControleQualite.traite,
};

String _libelleFiltre(_Filtre f) => switch (f) {
  _Filtre.toutes => t.admin.qualite.filtreToutes,
  _Filtre.ouvertes => t.admin.qualite.filtreOuvertes,
  _Filtre.traitees => t.admin.qualite.filtreTraitees,
};

String _libelleGroupe(TypeAnomalieQualite type) => switch (type) {
  TypeAnomalieQualite.rapportManquant => t.admin.qualite.groupeRapportManquant,
  TypeAnomalieQualite.blocageSansSuivi =>
    t.admin.qualite.groupeBlocageSansSuivi,
  TypeAnomalieQualite.evaluationEnRetard =>
    t.admin.qualite.groupeEvaluationEnRetard,
};

/// La rangee de filtres et la liste, enfants de la colonne de corps.
List<Widget> _corps(
  BuildContext context, {
  required List<AnomalieQualite> anomalies,
  required _Filtre filtre,
  required void Function(_Filtre filtre) onFiltre,
  required void Function(AnomalieQualite anomalie) onTraiter,
}) {
  final List<AnomalieQualite> visibles = anomalies
      .where((AnomalieQualite a) => _correspond(a, filtre))
      .toList(growable: false);

  return <Widget>[
    RangeeFiltres(
      filtres: <Widget>[
        for (final _Filtre f in _Filtre.values)
          FilterPill(
            libelle: _libelleFiltre(f),
            compteur: anomalies
                .where((AnomalieQualite a) => _correspond(a, f))
                .length,
            retenue: filtre == f,
            onPress: () => onFiltre(f),
          ),
      ],
    ),
    Ecart.vLg,
    if (visibles.isEmpty)
      EmptyState(
        message: t.admin.qualite.aucune,
        invitation: t.admin.qualite.aucuneDetail,
        icone: AppIcons.rienAAfficher,
        registre: RegistreVide.subi,
      )
    else
      Expanded(
        child: ListView(
          children: <Widget>[
            for (final TypeAnomalieQualite type in TypeAnomalieQualite.values)
              if (visibles.any(
                (AnomalieQualite a) => a.type == type,
              )) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    _libelleGroupe(type),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _GroupeAnomalies(
                  anomalies: visibles
                      .where((AnomalieQualite a) => a.type == type)
                      .toList(growable: false),
                  onTraiter: onTraiter,
                ),
                Ecart.vXl,
              ],
          ],
        ),
      ),
  ];
}

class _GroupeAnomalies extends StatelessWidget {
  const _GroupeAnomalies({required this.anomalies, required this.onTraiter});

  final List<AnomalieQualite> anomalies;
  final void Function(AnomalieQualite anomalie) onTraiter;

  @override
  Widget build(BuildContext context) {
    return DataCollection<AnomalieQualite>(
      // Une section de la liste de la page, qui defile deja (FILTRES-1b).
      defileSeule: false,
      lignes: anomalies,
      cle: (AnomalieQualite a) =>
          ValueKey<String>('${a.type.valeurSql}-${a.refId}'),
      colonnes: <ColonneDonnees<AnomalieQualite>>[
        ColonneDonnees<AnomalieQualite>(
          titre: t.admin.qualite.colonnePersonne,
          role: RoleColonne.identifiante,
          flex: 2,
          texte: (AnomalieQualite a) => a.personneLibelle,
        ),
        ColonneDonnees<AnomalieQualite>(
          titre: t.admin.qualite.colonneDepuis,
          tabulaire: true,
          texte: (AnomalieQualite a) => _depuis(a.joursDepuis(DateTime.now())),
        ),
        ColonneDonnees<AnomalieQualite>(
          titre: t.admin.qualite.colonneStatut,
          texte: (AnomalieQualite a) =>
              a.controleStatut == StatutControleQualite.traite
              ? t.admin.qualite.statutTraite
              : t.admin.qualite.statutOuvert,
          rendu: (BuildContext _, AnomalieQualite a) => StatusPill(
            libelle: a.controleStatut == StatutControleQualite.traite
                ? t.admin.qualite.statutTraite
                : t.admin.qualite.statutOuvert,
            ton: a.controleStatut == StatutControleQualite.traite
                ? TonEtat.succes
                : TonEtat.avertissement,
          ),
        ),
        ColonneDonnees<AnomalieQualite>(
          titre: '',
          role: RoleColonne.aPart,
          flex: 0,
          // Vide a dessein, meme convention que
          // `admin_groupes/groupes_page.dart`.
          texte: (AnomalieQualite _) => '',
          rendreMemeSiTexteVide: true,
          rendu: (BuildContext _, AnomalieQualite a) =>
              a.controleStatut == StatutControleQualite.ouvert
              ? MenuActions(
                  tooltip: a.personneLibelle,
                  actions: <EntreeAction>[
                    EntreeAction(
                      libelle: t.admin.qualite.actionTraiter,
                      onChoix: () => onTraiter(a),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

String _depuis(int jours) => switch (jours) {
  <= 0 => t.admin.qualite.depuisAujourdhui,
  1 => t.admin.qualite.depuisUnJour,
  final int j => LibellesGroupe.valeurSeule(
    t.admin.qualite.depuisJours(jours: j),
  ),
};

String _message(Object erreur) {
  final String brut = erreur.toString();
  final int deuxPoints = brut.indexOf(': ');
  return deuxPoints >= 0 && deuxPoints + 2 < brut.length
      ? brut.substring(deuxPoints + 2)
      : brut;
}

void _ouvrirTraitement(
  BuildContext context,
  WidgetRef ref,
  AnomalieQualite anomalie,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.qualite.traiterTitre(personne: anomalie.personneLibelle),
    constructeur: (BuildContext contexte) => _FeuilleTraitement(
      onEnvoyer: (String? note) => ref
          .read(serviceQualiteProvider)
          .traiter(type: anomalie.type, refId: anomalie.refId, note: note),
      onSucces: () => ref.invalidate(anomaliesQualiteProvider),
    ),
  );
}

/// Le formulaire de traitement : une note optionnelle, un bouton.
class _FeuilleTraitement extends StatefulWidget {
  const _FeuilleTraitement({required this.onEnvoyer, required this.onSucces});

  final Future<void> Function(String? note) onEnvoyer;
  final VoidCallback onSucces;

  @override
  State<_FeuilleTraitement> createState() => _FeuilleTraitementEtat();
}

class _FeuilleTraitementEtat extends State<_FeuilleTraitement> {
  final TextEditingController _note = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await widget.onEnvoyer(
        _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      widget.onSucces();
      if (mounted) Navigator.of(context).pop();
    } catch (erreur) {
      setState(
        () =>
            _erreur = t.admin.qualite.traiterErreur(message: _message(erreur)),
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ZoneSaisie(
          controleur: _note,
          minLignes: 2,
          libelle: t.admin.qualite.champNote,
        ),
        if (_erreur != null) ...<Widget>[
          Ecart.vMd,
          Text(
            _erreur!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        Ecart.vLg,
        ActionPrincipale(
          libelle: t.admin.qualite.traiterEnvoyer,
          enCours: _envoi,
          onPress: _envoyer,
        ),
      ],
    );
  }
}
