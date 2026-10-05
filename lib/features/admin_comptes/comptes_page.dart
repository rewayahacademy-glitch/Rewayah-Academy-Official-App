import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/admin/service_comptes.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pays_enseignant.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
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
  const ComptesPage({super.key, this.echusSeulement = false});

  /// Ouvre la page sur les seuls acces echus (DASH-ADM-ECHUS, adresse
  /// `Routes.adminPersonnesComptesEchus`).
  final bool echusSeulement;

  @override
  ConsumerState<ComptesPage> createState() => _ComptesPageEtat();
}

class _ComptesPageEtat extends ConsumerState<ComptesPage> {
  /// Le filtre courant. `null` veut dire « tous ».
  AccountStatus? _etat;
  AppRole? _role;

  /// Vrai : seuls les acces echus (DASH-ADM-ECHUS).
  late bool _echus = widget.echusSeulement;

  /// L'adresse porte le filtre, et go_router garde ce `State` d'une requete a
  /// l'autre (la page est cle sur le chemin seul) : sans ce recalage, passer
  /// de `?filtre=echus` a l'adresse nue (entree « Comptes » de la navigation)
  /// laissait l'ecran filtre.
  @override
  void didUpdateWidget(ComptesPage ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.echusSeulement != widget.echusSeulement) {
      _echus = widget.echusSeulement;
      if (_echus) {
        _etat = null;
      }
    }
  }

  /// Une seule pastille retenue a la fois dans la rangee des etats : « Tous »,
  /// un etat, ou « Acces echus ». Choisir l'une relache les autres.
  void _choisir({AccountStatus? etat, bool echus = false}) {
    setState(() {
      _etat = echus ? null : etat;
      _echus = echus;
    });
    _ecrireAdresse(echus);
  }

  /// Reporte le filtre des echus dans l'adresse, pour qu'elle dise toujours ce
  /// que montre l'ecran (lien partage, retour arriere, rechargement). Hors
  /// routeur (tests montes sans GoRouter), rien a faire.
  void _ecrireAdresse(bool echus) {
    final GoRouter? routeur = GoRouter.maybeOf(context);
    if (routeur == null) {
      return;
    }
    final Uri actuelle = routeur.routerDelegate.currentConfiguration.uri;
    if ((actuelle.queryParameters['filtre'] == 'echus') == echus) {
      return;
    }
    final Map<String, String> requete = Map<String, String>.of(
      actuelle.queryParameters,
    );
    if (echus) {
      requete['filtre'] = 'echus';
    } else {
      requete.remove('filtre');
    }
    routeur.go(
      Uri(
        path: actuelle.path,
        queryParameters: requete.isEmpty ? null : requete,
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<CompteAdmin>> comptes = ref.watch(comptesProvider);

    return PageShell(
      titre: t.admin.comptes.titre,
      entete: SousNavigationDomaine(onglets: ongletsPersonnes(), indexActif: 1),
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
                echus: _echus,
                onEchus: (bool echus) => _choisir(echus: echus),
                onEtat: (AccountStatus? etat) => _choisir(etat: etat),
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
    required this.echus,
    required this.onEchus,
    required this.onEtat,
    required this.onRole,
  });

  final List<CompteAdmin> comptes;
  final AccountStatus? etat;
  final AppRole? role;

  /// Vrai : seuls les acces echus.
  final bool echus;
  final void Function(bool echus) onEchus;
  final void Function(AccountStatus? etat) onEtat;
  final void Function(AppRole? role) onRole;

  @override
  Widget build(BuildContext context) {
    final DateTime maintenant = DateTime.now();
    final List<CompteAdmin> attendent = comptes
        .where((CompteAdmin c) => c.attendUneDecision)
        .toList(growable: false);

    // Un compte en attente dont le role est illisible n'attend « une decision »
    // que dans le doute : il n'est compte nulle part, donc l'ecran le dit.
    final int roleIllisible = comptes
        .where(
          (CompteAdmin c) =>
              c.etat == AccountStatus.pendingKyc && c.role == null,
        )
        .length;

    final List<CompteAdmin> filtres = comptes
        .where(
          (CompteAdmin c) =>
              (etat == null || _dansEtat(c, etat!)) &&
              (role == null || c.role == role) &&
              (!echus || c.accesEchu(maintenant)),
        )
        .toList(growable: false);
    // Tri stable cote client : ce qui attend une decision d'abord, le reste
    // dans l'ordre rendu par la base. La base met les tuteurs `pending_kyc` en
    // tete, ce qui repoussait les enseignants sous des lignes sans decision.
    final List<CompteAdmin> visibles = <CompteAdmin>[
      ...filtres.where((CompteAdmin c) => c.attendUneDecision),
      ...filtres.where((CompteAdmin c) => !c.attendUneDecision),
    ];

    // Les etats et les roles **presents dans les donnees**, avec leur compte.
    // Rendre les quatre etats et les six roles produisait onze pastilles qui
    // repoussaient la liste sous le pli : l'accent doit porter la selection,
    // pas decorer un inventaire de possibilites (registre produit d'Impeccable).
    final Map<AccountStatus, int> parEtat = <AccountStatus, int>{};
    final Set<AppRole> rolesPresents = <AppRole>{};
    for (final CompteAdmin compte in comptes) {
      final AccountStatus? e = compte.etat;
      if (e != null && _dansEtat(compte, e)) {
        parEtat[e] = (parEtat[e] ?? 0) + 1;
      }
      final AppRole? r = compte.role;
      if (r != null) {
        rolesPresents.add(r);
      }
    }

    // Quand l'identite est masquee, le prenom est nul et le libelle se replie
    // sur l'identifiant : les colonnes « Personne » et « Identifiant »
    // afficheraient alors deux fois la meme valeur.
    final bool identitesConnues = comptes.any(
      (CompteAdmin c) => c.prenom != null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Le fait d'abord, en une phrase et sans cadre. Une carte bordee pour
        // une seule ligne de texte est du poids visuel sans information.
        if (attendent.isNotEmpty) ...<Widget>[
          Text(
            attendent.length == 1
                ? switch (attendent.first.joursDAttente(maintenant)) {
                    <= 0 => t.admin.comptes.attenteUneAujourdhui,
                    1 => t.admin.comptes.attenteUneUnJour,
                    final int jours => t.admin.comptes.attenteUne(
                      jours: '$jours',
                    ),
                  }
                : t.admin.comptes.attentePlusieurs(
                    nombre: '${attendent.length}',
                  ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Ecart.vLg,
        ],
        if (roleIllisible > 0) ...<Widget>[
          Text(
            roleIllisible == 1
                ? t.admin.comptes.roleIllisibleUn
                : t.admin.comptes.roleIllisiblePlusieurs(
                    nombre: '$roleIllisible',
                  ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Ecart.vLg,
        ],

        // Une seule rangee, et les deux axes dans le meme groupe : l'etat en
        // pastilles parce qu'il appelle un geste, le role dans un menu parce
        // que c'est l'axe secondaire. Colles l'un a l'autre et non pousses aux
        // deux bords : deux filtres separes par la largeur de l'ecran ne se
        // lisent plus comme deux filtres, mais comme deux fonctions.
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            FilterPill(
              libelle: t.admin.comptes.filtreTousEtats,
              compteur: comptes.length,
              // « Tous » ne se dit retenu que s'il l'est vraiment : avec les
              // echus retenus, deux pastilles allumees pour une seule liste
              // mentaient sur ce qui est affiche.
              retenue: etat == null && !echus,
              onPress: () => onEtat(null),
            ),
            for (final AccountStatus valeur in AccountStatus.values)
              if (parEtat.containsKey(valeur) || etat == valeur)
                FilterPill(
                  key: ValueKey<String>('comptes-filtre-etat-${valeur.name}'),
                  libelle: _nomEtat(valeur),
                  compteur: parEtat[valeur] ?? 0,
                  retenue: etat == valeur,
                  onPress: () => onEtat(valeur),
                ),
            // DASH-ADM-ECHUS : les acces echus, le meme chiffre que le Centre
            // de commande. Rendu des qu'il y en a, ou quand la page a ete
            // ouverte sur eux (le filtre retenu doit pouvoir se relacher).
            if (echus || _nombreEchus(comptes, maintenant) > 0)
              FilterPill(
                key: const ValueKey<String>('comptes-filtre-echus'),
                libelle: t.admin.tableau.comptes,
                compteur: _nombreEchus(comptes, maintenant),
                retenue: echus,
                onPress: () => onEchus(!echus),
              ),
            // Un seul role present : le menu n'offrirait aucun choix, et un
            // controle sans choix n'est pas un controle.
            if (rolesPresents.length > 1)
              MenuFiltre<AppRole>(
                libelle: t.admin.comptes.filtreRole,
                valeur: role,
                onChoix: onRole,
                entrees: <EntreeFiltre<AppRole>>[
                  EntreeFiltre<AppRole>(
                    valeur: null,
                    libelle: t.admin.comptes.filtreTousRoles,
                    compteur: comptes.length,
                  ),
                  for (final AppRole valeur in AppRole.values)
                    if (rolesPresents.contains(valeur))
                      EntreeFiltre<AppRole>(
                        valeur: valeur,
                        libelle: _nomRole(valeur),
                        compteur: comptes
                            .where((CompteAdmin c) => c.role == valeur)
                            .length,
                      ),
                ],
              ),
          ],
        ),
        Ecart.vLg,

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
                // Sous masquage, `libelle` **est** l'identifiant : la colonne
                // dediee afficherait deux fois la meme valeur cote a cote.
                if (identitesConnues)
                  ColonneDonnees<CompteAdmin>(
                    titre: t.admin.comptes.colonneIdentifiant,
                    texte: (CompteAdmin c) => c.identifiant,
                  ),
                // ENS-PAYS-1 : le pays des comptes enseignants, seulement
                // quand une ligne au moins le porte (pas de colonne vide).
                if (visibles.any(
                  (CompteAdmin c) =>
                      PaysEnseignant.nomAffichable(c.paysEnseignant) != null,
                ))
                  ColonneDonnees<CompteAdmin>(
                    // « Pays » : la colonne ne porte que des comptes enseignants, et
                    // « Pays de l'enseignant » se tronquait a 1440.
                    titre: t.enseignant.profil.pays,
                    // Sa propre ligne en carte (sous 1200), avec le drapeau :
                    // la ligne secondaire jointe ne rendrait que du texte.
                    role: RoleColonne.aPart,
                    texte: (CompteAdmin c) =>
                        PaysEnseignant.nomAffichable(c.paysEnseignant) ?? '',
                    rendu: (BuildContext _, CompteAdmin c) =>
                        PaysEnseignant(pays: c.paysEnseignant),
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
                  // K-47 : seul l'enseignant depose une piece. « Aucune piece
                  // deposee » preterait un manque qui n'existe pas au tuteur,
                  // a l'eleve et au personnel. Un role illisible garde le
                  // texte reel : on ne sait pas s'il en doit une.
                  texte: (CompteAdmin c) => _pieceSansObjet(c)
                      ? t.admin.comptes.pieceSansObjet
                      : _nomPiece(c.piece),
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

/// Vrai quand [compte] entre dans la pastille d'etat [etat].
///
/// Decision « pastille-attente » du 05/10 (AD-NETTOYAGE-2, decidee par
/// delegation du directeur) : « En attente » ne compte que les enseignants
/// qui attendent une decision, le meme chiffre que la tuile « Dossiers a
/// valider » du Centre de commande (enseignants seulement, m1
/// d'AD-NETTOYAGE). Un tuteur `pending_kyc` n'a aucune piece a faire valider
/// (voir [_pieceSansObjet]) : il reste dans « Tous » et sous son role.
bool _dansEtat(CompteAdmin compte, AccountStatus etat) =>
    etat == AccountStatus.pendingKyc
    ? compte.attendUneDecision
    : compte.etat == etat;

/// Vrai quand la piece d'identite n'a pas de sens pour ce compte : le tuteur
/// (toujours) et les autres roles lisibles tant qu'ils n'en ont depose aucune.
bool _pieceSansObjet(CompteAdmin c) =>
    c.role == AppRole.guardian ||
    (c.role != null &&
        c.role != AppRole.teacher &&
        c.piece == EtatPiece.aucune);

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

/// Combien d'acces sont echus parmi [comptes].
int _nombreEchus(List<CompteAdmin> comptes, DateTime maintenant) =>
    comptes.where((CompteAdmin c) => c.accesEchu(maintenant)).length;
