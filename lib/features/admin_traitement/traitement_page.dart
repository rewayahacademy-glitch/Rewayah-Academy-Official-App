import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/admin/service_admin.dart';
import '../../core/admin/service_comptes.dart' show EtatPiece;
import '../../core/domain/enums.dart';
import '../../core/dossier/service_validation.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/matching/service_matching.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pied_de_liste.dart';
import '../../core/widgets/puce_filtre_actif.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';
import 'elements_a_traiter.dart';

/// `ADM-18` : l'Espace de traitement.
///
/// **Une file, deux sources reelles** : les dossiers d'identite en attente et
/// les demandes en attente, reunis et tries du plus recent au plus ancien
/// par defaut. **Aucune decision ici** : une ligne mene a l'ecran ou la
/// decision se prend (`ADM-02` pour un dossier, `ADM-06` pour une demande),
/// avec ses verifications, ses confirmations et ses controles serveur
/// (docs/current/AD-X_DECOUPAGE.md §2, ecran 2).
///
/// L4 des listes (02/11/2026, DECISION-LISTES §5 quater.10 quater) : la
/// liste est la page, comme Classes, Comptes et Classes a ouvrir. Le
/// maitre-detail d'avant (une file de 336 et un detail de 728, chacun son
/// defilement) est retire (DECISION-DEFILEMENT-2026-11-01 : une seule barre
/// de defilement par ecran) : ce que le detail disait passe en colonnes, et
/// la ligne ouvre directement l'ecran de decision, comme le faisait son seul
/// bouton.
class TraitementPage extends ConsumerStatefulWidget {
  /// Cree l'Espace de traitement.
  const TraitementPage({super.key, this.horloge = DateTime.now});

  /// D'ou vient l'instant courant : « Aujourd'hui » et « Hier » se comptent
  /// en jours, et un test cale sur l'horloge de la machine changerait de
  /// resultat.
  final DateTime Function() horloge;

  /// La liste.
  static const Key cleFile = ValueKey<String>('adm18-file');

  /// La cle d'une ligne.
  static ValueKey<String> cleLigne(String id) =>
      ValueKey<String>('adm18-ligne-$id');

  @override
  ConsumerState<TraitementPage> createState() => _TraitementPageEtat();
}

class _TraitementPageEtat extends ConsumerState<TraitementPage> {
  /// Le filtre de nature. Nul : tout.
  NatureElement? _nature;

  TriFile _tri = TriFile.plusRecent;

  /// LISTES-3 : au bureau, le panneau des filtres.
  bool _filtresOuverts = false;

  void _relire() {
    ref
      ..invalidate(dossiersEnAttenteProvider)
      ..invalidate(demandesProvider);
  }

  /// L'ecran ou la decision se prend : le dossier par `extra`, jamais par
  /// l'adresse (spec l.1933) ; la demande dans la file des demandes.
  void _ouvrir(ElementATraiter e) {
    final GoRouter routeur = GoRouter.of(context);
    final DossierAValider? dossier = e.dossier;
    if (dossier != null) {
      routeur.go(Routes.adminPersonnesDossiers, extra: dossier.profilId);
    } else {
      routeur.go(Routes.adminOperationsDemandes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<DossierAValider>> dossiers = ref.watch(
      dossiersEnAttenteProvider,
    );
    final AsyncValue<List<Demande>> demandes = ref.watch(demandesProvider);
    final bool bureau = DataCollection.enTableau(context);
    final List<FiltreActif> actifs = <FiltreActif>[
      if (_nature case final NatureElement nature)
        FiltreActif(
          libelle: switch (nature) {
            NatureElement.dossier => t.admin.traitement.filtreDossiers,
            NatureElement.demande => t.admin.traitement.filtreDemandes,
          },
          onRetirer: () => setState(() => _nature = null),
        ),
      if (_tri == TriFile.plusAncien)
        FiltreActif(
          libelle: t.admin.traitement.triAncien,
          onRetirer: () => setState(() => _tri = TriFile.plusRecent),
        ),
    ];

    return PageShell(
      titre: t.admin.traitement.titre,
      // La sous-navigation Operations, Espace de traitement et Classes, qui
      // tient lieu de titre (§5 ter.2).
      entete: SousNavigationDomaine(
        onglets: ongletsOperations(),
        indexActif: 0,
      ),
      // LISTES-2 et LISTES-3 : la tete defile avec la liste, qui prend toute
      // la largeur au bureau, sans retour (la barre laterale navigue).
      teteAvecLaListe: true,
      listeBureau: true,
      actionsEntete: <Widget>[
        if (bureau)
          RangeeFiltres.bascule(
            key: const ValueKey<String>('adm18-bascule-filtres'),
            ouverts: _filtresOuverts,
            retenus: actifs.length,
            onBasculer: () =>
                setState(() => _filtresOuverts = !_filtresOuverts),
          ),
      ],
      // `DataCollection` porte le defilement de la page (une seule barre).
      defilante: false,
      child: ColonneCorps(
        children: <Widget>[
          Expanded(child: _corps(dossiers, demandes, bureau, actifs)),
        ],
      ),
    );
  }

  Widget _corps(
    AsyncValue<List<DossierAValider>> dossiers,
    AsyncValue<List<Demande>> demandes,
    bool bureau,
    List<FiltreActif> actifs,
  ) {
    // Les getters, jamais le type : Riverpod 3 relance un provider en echec
    // en gardant `hasError` (lib/CLAUDE.md).
    final bool dossiersLus = dossiers.hasValue;
    final bool demandesLues = demandes.hasValue;
    if (!dossiersLus && !demandesLues) {
      if (dossiers.hasError && demandes.hasError) {
        return _SansListe(
          tete: const SizedBox.shrink(),
          child: EmptyState(
            message: t.admin.traitement.erreur,
            icone: AppIcons.avertissement,
            libelleAction: t.commun.reessayer,
            onAction: _relire,
          ),
        );
      }
      if (dossiers.isLoading || demandes.isLoading) {
        // Une source au moins est encore en route : la forme de la liste.
        return const _SansListe(
          tete: SizedBox.shrink(),
          child: Skeleton.tableDense(lignes: 6),
        );
      }
    }

    final List<DossierAValider> lusDossiers =
        dossiers.value ?? const <DossierAValider>[];
    final List<Demande> lusDemandes = demandes.value ?? const <Demande>[];
    final List<ElementATraiter> tous = reunirFile(
      dossiers: lusDossiers,
      demandes: lusDemandes,
    );
    final List<ElementATraiter> visibles = reunirFile(
      dossiers: lusDossiers,
      demandes: lusDemandes,
      nature: _nature,
      tri: _tri,
    );
    final int nbDossiers = tous
        .where((ElementATraiter e) => e.nature == NatureElement.dossier)
        .length;

    // Une source en echec n'emporte que ce qu'elle remplit (D11) : la phrase
    // dit laquelle, et l'autre reste affichee.
    final List<String> erreurs = <String>[
      if (dossiers.hasError && !dossiersLus) t.admin.traitement.erreurDossiers,
      if (demandes.hasError && !demandesLues) t.admin.traitement.erreurDemandes,
    ];

    final List<Widget> puces = <Widget>[
      FilterPill(
        libelle: t.admin.traitement.filtreTous,
        compteur: tous.length,
        retenue: _nature == null,
        onPress: () => setState(() => _nature = null),
      ),
      FilterPill(
        libelle: t.admin.traitement.filtreDossiers,
        compteur: nbDossiers,
        retenue: _nature == NatureElement.dossier,
        onPress: () => setState(() => _nature = NatureElement.dossier),
      ),
      FilterPill(
        libelle: t.admin.traitement.filtreDemandes,
        compteur: tous.length - nbDossiers,
        retenue: _nature == NatureElement.demande,
        onPress: () => setState(() => _nature = NatureElement.demande),
      ),
      // Le tri : « Plus recent » est l'ordre par defaut (valeur nulle, le
      // bouton dit « Trier ») ; « Plus ancien » se lit comme un choix retenu.
      MenuFiltre<TriFile>(
        libelle: t.admin.traitement.tri,
        valeur: _tri == TriFile.plusAncien ? TriFile.plusAncien : null,
        entrees: <EntreeFiltre<TriFile>>[
          EntreeFiltre<TriFile>(
            valeur: null,
            libelle: t.admin.traitement.triRecent,
          ),
          EntreeFiltre<TriFile>(
            valeur: TriFile.plusAncien,
            libelle: t.admin.traitement.triAncien,
          ),
        ],
        onChoix: (TriFile? tri) =>
            setState(() => _tri = tri ?? TriFile.plusRecent),
      ),
    ];

    // LISTES-3 (bureau) : les filtres en panneau, derriere l'icone ; replie,
    // les filtres retenus restent dits. Au telephone, §5 ter : la rangee de
    // filtres defile avec la liste.
    final Widget tete = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (tous.isNotEmpty)
          if (!bureau) ...<Widget>[
            RangeeFiltres(filtres: puces),
            Ecart.vLg,
          ] else if (_filtresOuverts) ...<Widget>[
            RangeeFiltres(
              key: const ValueKey<String>('adm18-panneau-filtres'),
              enPanneau: true,
              filtres: puces,
            ),
            Ecart.vLg,
          ] else if (actifs.isNotEmpty) ...<Widget>[
            FiltresActifs(
              filtres: actifs,
              onToutEffacer: () => setState(() {
                _nature = null;
                _tri = TriFile.plusRecent;
              }),
            ),
            Ecart.vLg,
          ],
        for (final String erreur in erreurs) ...<Widget>[
          EtatSysteme(
            nature: NatureEtat.echecServeur,
            titre: erreur,
            libelleAction: t.commun.reessayer,
            onAction: _relire,
          ),
          Ecart.vLg,
        ],
      ],
    );

    // Une source en echec et l'autre vide : la file n'est pas connue, la
    // phrase d'erreur parle seule (jamais « Rien a traiter » sur une
    // lecture manquee).
    if (tous.isEmpty && erreurs.isNotEmpty) {
      return _SansListe(tete: tete, child: const SizedBox.shrink());
    }
    if (tous.isEmpty || visibles.isEmpty) {
      return _SansListe(
        tete: tete,
        child: EmptyState(
          message: tous.isEmpty
              ? t.admin.traitement.vide
              : t.admin.traitement.videFiltre,
          invitation: tous.isEmpty
              ? t.admin.traitement.videDetail
              : t.admin.traitement.videFiltreDetail,
          registre: RegistreVide.subi,
          icone: AppIcons.rienAAfficher,
        ),
      );
    }

    final DateTime maintenant = widget.horloge();
    final bool avecDossiers = visibles.any(
      (ElementATraiter e) => e.nature == NatureElement.dossier,
    );
    final bool avecDemandes = visibles.any(
      (ElementATraiter e) => e.nature == NatureElement.demande,
    );
    return DataCollection<ElementATraiter>(
      key: TraitementPage.cleFile,
      // LISTES-2 et LISTES-3 (§5 quater) : la tete defile avec les lignes ;
      // au bureau, des cartes sous des en-tetes discrets ; au telephone, des
      // lignes denses.
      prendTeteDePage: true,
      tete: tete,
      densiteTelephone: true,
      lignesCartes: true,
      lignes: visibles,
      cle: (ElementATraiter e) => TraitementPage.cleLigne(e.id),
      onSelectionner: _ouvrir,
      colonnes: <ColonneDonnees<ElementATraiter>>[
        ColonneDonnees<ElementATraiter>(
          titre: t.admin.traitement.cleConcerne,
          role: RoleColonne.identifiante,
          flex: 3,
          texte: (ElementATraiter e) => e.nom,
          // Le nom, sa nature dessous (la legende de la ligne d'avant), et
          // l'etat de piece que le serveur dit explicitement.
          rendu: (BuildContext _, ElementATraiter e) => _Identite(element: e),
        ),
        ColonneDonnees<ElementATraiter>(
          titre: t.admin.traitement.cleParQui,
          flex: 2,
          texte: _parQui,
        ),
        if (avecDossiers)
          ColonneDonnees<ElementATraiter>(
            titre: t.admin.traitement.clePiece,
            flex: 2,
            texte: _piece,
          ),
        if (avecDemandes)
          ColonneDonnees<ElementATraiter>(
            titre: t.admin.demandes.motifDemande,
            flex: 3,
            texte: (ElementATraiter e) => e.demande?.motif ?? '',
          ),
        ColonneDonnees<ElementATraiter>(
          titre: t.admin.traitement.colonneDepuis,
          flex: 2,
          tabulaire: true,
          texte: (ElementATraiter e) => _depuis(e.depuis, maintenant),
        ),
      ],
      // La file entiere, sans page : les deux lectures sont completes (pas de
      // taille imposee, rien a proposer).
      piedCollant: PiedDeListe(
        key: const ValueKey<String>('adm18-pied'),
        debut: 1,
        fin: visibles.length,
        total: visibles.length,
      ),
    );
  }
}

/// Sans ligne, pas de liste pour prendre la tete : la page fait defiler sa
/// tete et ce corps ensemble (jamais un cadre de hauteur fixe).
class _SansListe extends StatelessWidget {
  const _SansListe({required this.tete, required this.child});

  final Widget tete;
  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[tete, child],
    ),
  );
}

/// La cellule d'identite : le nom, sa nature (« Dossier d'identite ·
/// Enseignant », « Demande · Changement d'enseignant ») et, pour un dossier,
/// l'etat de piece que le serveur dit explicitement (aucune, hors de
/// portee) ; aucune pastille « en attente » repetee sur chaque ligne (releve
/// AD-3R).
class _Identite extends StatelessWidget {
  const _Identite({required this.element});

  final ElementATraiter element;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final Widget? pastille = switch (element.dossier?.etatPiece) {
      EtatPiece.aucune => StatusPill(
        libelle: t.dossiers.sansPiece,
        ton: TonEtat.neutre,
      ),
      EtatPiece.nonVisible => StatusPill(
        libelle: t.dossiers.pieceNonVisible,
        ton: TonEtat.avertissement,
      ),
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(element.nom, style: textes.titleSmall),
        Text(
          element.precision,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        if (pastille != null) ...<Widget>[Ecart.vXs, pastille],
      ],
    );
  }
}

/// Qui a demande : l'enseignant qui a depose son dossier, ou le role de
/// l'auteur de la demande.
String _parQui(ElementATraiter e) => switch (e.demande?.roleDemandeur) {
  _ when e.dossier != null => t.admin.demandes.roleTeacher,
  AppRole.guardian => t.admin.demandes.roleGuardian,
  AppRole.teacher => t.admin.demandes.roleTeacher,
  AppRole.student => t.admin.demandes.roleStudent,
  AppRole.admin => t.admin.demandes.roleAdmin,
  AppRole.controller => t.admin.demandes.roleController,
  _ => t.admin.demandes.roleInconnu,
};

/// L'etat de la piece d'un dossier : « Deposee, a verifier ». Aucune piece,
/// ou une piece hors de portee, se disent par la pastille sous le nom (une
/// seule fois) ; vide pour une demande.
String _piece(ElementATraiter e) => switch (e.dossier?.etatPiece) {
  null when e.dossier == null => '',
  EtatPiece.aucune || EtatPiece.nonVisible => '',
  _ => t.admin.traitement.pieceAVerifier,
};

String _deux(int n) => n.toString().padLeft(2, '0');

/// Depuis quand l'element attend : « Aujourd'hui · 14:05 », « Hier ·
/// 09:12 », sinon « 31 oct. · 22:32 » (les groupes de jour d'avant, dits
/// dans la ligne ; la meme heure que la ligne d'avant).
String _depuis(DateTime depuis, DateTime maintenant) {
  final String heure = '${_deux(depuis.hour)}:${_deux(depuis.minute)}';
  final String jour = switch (groupePour(depuis, maintenant)) {
    GroupeTemps.aujourdhui => t.admin.traitement.groupeAujourdhui,
    GroupeTemps.hier => t.admin.traitement.groupeHier,
    _ => '${depuis.day} ${t.historique.moisCourts[depuis.month - 1]}',
  };
  return '$jour · $heure';
}
