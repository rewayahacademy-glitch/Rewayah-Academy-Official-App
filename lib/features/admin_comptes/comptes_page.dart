import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/service_comptes.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';

/// `ADM-08` : les comptes du produit.
///
/// **L'ecran qui manquait, et son absence coutait des personnes.** Mesure en
/// production le 18 septembre 2026 : trois enseignants inscrits les 11 et 15
/// septembre attendaient depuis sept jours, contrats signes, sans avoir depose
/// leur piece d'identite. Aucun ecran de l'administration ne les montrait.
/// `ADM-02` ne listait que les pieces deposees, `ADM-05` que les eleves sans
/// enseignant, et le tableau de bord affichait « 0 dossiers a valider ».
/// L'academie etait bloquee et l'interface annoncait qu'il n'y avait rien a
/// faire.
///
/// Trois choix de rendu, chacun paye par une raison :
///
///   * **ce qui attend une decision passe devant**, et se dit en haut en une
///     phrase. Un compte bloque depuis une semaine ne doit pas se lire apres
///     trente comptes actifs, et le tri vient de la base, pas de l'ecran ;
///   * **l'anciennete est rendue, jamais la seule date**. « Depuis 7 jours »
///     est un fait qui appelle un geste ; « 11/09 » demande un calcul ;
///   * **une piece absente est un etat affiche**, pas une case vide. C'est
///     precisement l'etat qui etait invisible.
class ComptesPage extends ConsumerStatefulWidget {
  /// Cree l'ecran des comptes.
  const ComptesPage({super.key});

  @override
  ConsumerState<ComptesPage> createState() => _ComptesPageEtat();
}

class _ComptesPageEtat extends ConsumerState<ComptesPage> {
  /// Le filtre courant. `null` veut dire « tous ».
  AccountStatus? _etat;
  AppRole? _role;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<CompteAdmin>> comptes = ref.watch(comptesProvider);

    return PageShell(
      titre: t.admin.comptes.titre,
      // `DataCollection` porte son propre `ListView` : il exige une hauteur
      // bornee, donc l'ecran gere son defilement, comme `ADM-04`.
      defilante: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.admin.comptes.intro, style: textes.bodyMedium),
          Ecart.vXl,
          // Les getters, jamais le type d'execution : Riverpod 3 relance un
          // provider en echec tout seul, et l'etat repasse par `AsyncLoading`
          // en conservant `hasError`.
          switch (comptes) {
            AsyncValue<List<CompteAdmin>>(hasValue: true) => Expanded(
              child: _Corps(
                comptes: comptes.requireValue,
                etat: _etat,
                role: _role,
                onEtat: (AccountStatus? etat) => setState(() => _etat = etat),
                onRole: (AppRole? role) => setState(() => _role = role),
              ),
            ),
            // Registre **actionnable**, et pas « subi » : `EmptyState` ne rend
            // son bouton que dans ce registre (« c'est le registre qui
            // tranche, pas l'oubli de l'appelant »). Un etat d'erreur declare
            // en registre subi affiche un message sans le moindre « Reessayer »,
            // et l'ecran devient un cul-de-sac. Defaut trouve le 18 septembre
            // 2026, `ADM-07` le portait aussi.
            AsyncValue<List<CompteAdmin>>(hasError: true) => EmptyState(
              message: t.admin.comptes.erreur,
              icone: AppIcons.avertissement,
              libelleAction: t.commun.reessayer,
              onAction: () => ref.invalidate(comptesProvider),
            ),
            _ => const Skeleton.liste(lignes: 5),
          },
        ],
      ),
    );
  }
}

/// Le bandeau d'attente, les filtres, puis le tableau.
class _Corps extends StatelessWidget {
  const _Corps({
    required this.comptes,
    required this.etat,
    required this.role,
    required this.onEtat,
    required this.onRole,
  });

  final List<CompteAdmin> comptes;
  final AccountStatus? etat;
  final AppRole? role;
  final void Function(AccountStatus? etat) onEtat;
  final void Function(AppRole? role) onRole;

  @override
  Widget build(BuildContext context) {
    final DateTime maintenant = DateTime.now();
    final List<CompteAdmin> attendent = comptes
        .where((CompteAdmin c) => c.attendUneDecision)
        .toList(growable: false);

    final List<CompteAdmin> visibles = comptes
        .where(
          (CompteAdmin c) =>
              (etat == null || c.etat == etat) &&
              (role == null || c.role == role),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Le fait d'abord, et en toutes lettres. C'est exactement ce que
        // l'ancien « 0 » cachait.
        if (attendent.isNotEmpty) ...<Widget>[
          AppCard(
            contourFort: true,
            child: Text(
              attendent.length == 1
                  ? t.admin.comptes.attenteUne(
                      jours: '${attendent.first.joursDAttente(maintenant)}',
                    )
                  : t.admin.comptes.attentePlusieurs(
                      nombre: '${attendent.length}',
                    ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Ecart.vXl,
        ],

        // Filtres : l'etat d'abord, parce que c'est lui qui appelle un geste.
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            FilterPill(
              libelle: t.admin.comptes.filtreTousEtats,
              retenue: etat == null,
              onPress: () => onEtat(null),
            ),
            for (final AccountStatus valeur in AccountStatus.values)
              FilterPill(
                libelle: _nomEtat(valeur),
                retenue: etat == valeur,
                onPress: () => onEtat(valeur),
              ),
          ],
        ),
        Ecart.vMd,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            FilterPill(
              libelle: t.admin.comptes.filtreTousRoles,
              retenue: role == null,
              onPress: () => onRole(null),
            ),
            for (final AppRole valeur in AppRole.values)
              if (comptes.any((CompteAdmin c) => c.role == valeur))
                FilterPill(
                  libelle: _nomRole(valeur),
                  retenue: role == valeur,
                  onPress: () => onRole(valeur),
                ),
          ],
        ),
        Ecart.vXl,

        if (visibles.isEmpty)
          EmptyState(
            message: t.admin.comptes.aucunAvecCeFiltre,
            invitation: t.admin.comptes.aucunAvecCeFiltreDetail,
            registre: RegistreVide.subi,
            icone: AppIcons.rienAAfficher,
          )
        else
          Expanded(
            child: DataCollection<CompteAdmin>(
              lignes: visibles,
              colonnes: <ColonneDonnees<CompteAdmin>>[
                ColonneDonnees<CompteAdmin>(
                  titre: t.admin.comptes.colonnePersonne,
                  role: RoleColonne.identifiante,
                  flex: 2,
                  texte: (CompteAdmin c) => c.libelle,
                ),
                ColonneDonnees<CompteAdmin>(
                  titre: t.admin.comptes.colonneIdentifiant,
                  texte: (CompteAdmin c) => c.identifiant,
                ),
                ColonneDonnees<CompteAdmin>(
                  titre: t.admin.comptes.colonneRole,
                  texte: (CompteAdmin c) => c.role == null
                      ? t.admin.comptes.roleInconnu
                      : _nomRole(c.role!),
                ),
                ColonneDonnees<CompteAdmin>(
                  titre: t.admin.comptes.colonneEtat,
                  texte: (CompteAdmin c) => c.etat == null
                      ? t.admin.comptes.etatInconnu
                      : _nomEtat(c.etat!),
                  rendu: (BuildContext _, CompteAdmin c) => StatusPill(
                    libelle: c.etat == null
                        ? t.admin.comptes.etatInconnu
                        : _nomEtat(c.etat!),
                    ton: _tonEtat(c.etat),
                  ),
                ),
                ColonneDonnees<CompteAdmin>(
                  titre: t.admin.comptes.colonnePiece,
                  texte: (CompteAdmin c) => _nomPiece(c.piece),
                ),
                ColonneDonnees<CompteAdmin>(
                  titre: t.admin.comptes.colonneAttente,
                  tabulaire: true,
                  // L'anciennete, pas la date : c'est elle qui appelle un geste.
                  texte: (CompteAdmin c) =>
                      _attente(c.joursDAttente(DateTime.now())),
                ),
                ColonneDonnees<CompteAdmin>(
                  titre: t.admin.comptes.colonneContrats,
                  tabulaire: true,
                  texte: (CompteAdmin c) => '${c.contrats}',
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _attente(int jours) => switch (jours) {
    0 => t.admin.comptes.attendAujourdhui,
    1 => t.admin.comptes.attendUnJour,
    _ => t.admin.comptes.attendJours(jours: '$jours'),
  };
}

String _nomEtat(AccountStatus etat) => switch (etat) {
  AccountStatus.pendingKyc => t.admin.comptes.etatEnAttente,
  AccountStatus.active => t.admin.comptes.etatActif,
  AccountStatus.provisionalActive => t.admin.comptes.etatProvisoire,
  AccountStatus.disabled => t.admin.comptes.etatSuspendu,
};

TonEtat _tonEtat(AccountStatus? etat) => switch (etat) {
  AccountStatus.pendingKyc => TonEtat.avertissement,
  AccountStatus.active => TonEtat.succes,
  AccountStatus.provisionalActive => TonEtat.neutre,
  AccountStatus.disabled => TonEtat.alerte,
  null => TonEtat.neutre,
};

String _nomRole(AppRole role) => switch (role) {
  AppRole.admin => t.admin.comptes.roleAdmin,
  AppRole.accountant => t.admin.comptes.roleComptable,
  AppRole.controller => t.admin.comptes.roleControleur,
  AppRole.teacher => t.admin.comptes.roleEnseignant,
  AppRole.guardian => t.admin.comptes.roleTuteur,
  AppRole.student => t.admin.comptes.roleEleve,
};

String _nomPiece(EtatPiece piece) => switch (piece) {
  EtatPiece.aucune => t.admin.comptes.pieceAucune,
  EtatPiece.aVerifier => t.admin.comptes.pieceAVerifier,
  EtatPiece.validee => t.admin.comptes.pieceValidee,
  EtatPiece.refusee => t.admin.comptes.pieceRefusee,
  EtatPiece.nonVisible => t.admin.comptes.pieceNonVisible,
};
