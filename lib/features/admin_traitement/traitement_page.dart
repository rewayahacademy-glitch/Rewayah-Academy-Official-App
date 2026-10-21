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
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';
import '../admin_dossiers/dossiers_page.dart'
    show ecartFileDetail, largeurDetailDossier, largeurFileDossiers;
import '../admin_dossiers/textes_dossier.dart';
import 'elements_a_traiter.dart';

/// `ADM-18` : l'Espace de traitement (AD-X, image ADMIN-SHELL-02).
///
/// **Une file, deux sources reelles** : les dossiers d'identite en attente et
/// les demandes en attente, reunis, groupes par jour (Aujourd'hui, Hier,
/// Cette semaine, Plus ancien) et tries du plus recent au plus ancien par
/// defaut. Le detail dit qui, quoi, depuis quand, et mene a l'ecran ou la
/// decision se prend (`ADM-02` pour un dossier, `ADM-06` pour une demande) :
/// **aucune decision ici**, elle a ses verifications, ses confirmations et
/// ses controles serveur (docs/current/AD-X_DECOUPAGE.md §2, ecran 2).
///
/// A partir de 1088 de largeur utile et sous 200 % de texte, file 336 et
/// detail 728 cote a cote (contrat D) ; sinon la file seule, le detail en
/// feuille.
class TraitementPage extends ConsumerStatefulWidget {
  /// Cree l'Espace de traitement.
  const TraitementPage({super.key, this.horloge = DateTime.now});

  /// D'ou vient l'instant courant : les groupes de temps se comptent en jours,
  /// et un test cale sur l'horloge de la machine changerait de resultat.
  final DateTime Function() horloge;

  /// Le panneau de detail, en maitre-detail.
  static const Key cleDetail = ValueKey<String>('adm18-detail');

  /// La file.
  static const Key cleFile = ValueKey<String>('adm18-file');

  @override
  ConsumerState<TraitementPage> createState() => _TraitementPageEtat();
}

class _TraitementPageEtat extends ConsumerState<TraitementPage> {
  /// Le filtre de nature. Nul : tout.
  NatureElement? _nature;

  TriFile _tri = TriFile.plusRecent;

  /// L'element choisi, par sa cle.
  String? _choisi;

  void _relire() {
    ref
      ..invalidate(dossiersEnAttenteProvider)
      ..invalidate(demandesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<DossierAValider>> dossiers = ref.watch(
      dossiersEnAttenteProvider,
    );
    final AsyncValue<List<Demande>> demandes = ref.watch(demandesProvider);

    return PageShell(
      titre: t.admin.traitement.titre,
      sousTitre: t.admin.traitement.sousTitre,
      entete: SousNavigationDomaine(
        onglets: ongletsOperations(),
        indexActif: 0,
      ),
      defilante: false,
      child: _corps(context, dossiers, demandes),
    );
  }

  Widget _corps(
    BuildContext context,
    AsyncValue<List<DossierAValider>> dossiers,
    AsyncValue<List<Demande>> demandes,
  ) {
    // Les getters, jamais le type : Riverpod 3 relance un provider en echec
    // en gardant `hasError` (lib/CLAUDE.md).
    final bool dossiersLus = dossiers.hasValue;
    final bool demandesLues = demandes.hasValue;
    if (!dossiersLus && !demandesLues) {
      if (dossiers.hasError && demandes.hasError) {
        return EmptyState(
          message: t.admin.traitement.erreur,
          icone: AppIcons.avertissement,
          libelleAction: t.commun.reessayer,
          onAction: _relire,
        );
      }
      if (!dossiers.hasError || !demandes.hasError) {
        // Une source au moins est encore en route : la forme de la file.
        if (dossiers.isLoading || demandes.isLoading) {
          return const Skeleton.liste(lignes: 5);
        }
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

    // FILTRES-1 : une seule rangee de puces, qui defile quand elle ne tient
    // pas (porte par JONCTION-LIGNES-1).
    final Widget filtres = RangeeFiltres(
      filtres: <Widget>[
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
        // bouton dit « Trier ») ; « Plus ancien » se lit comme un choix
        // retenu.
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
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        filtres,
        for (final String erreur in erreurs) ...<Widget>[
          Ecart.vLg,
          EtatSysteme(
            nature: NatureEtat.echecServeur,
            titre: erreur,
            libelleAction: t.commun.reessayer,
            onAction: _relire,
          ),
        ],
        Ecart.vLg,
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints contraintes) {
              final bool maitreDetail =
                  MediaQuery.textScalerOf(context).scale(1) < 2 &&
                  contraintes.maxWidth >=
                      largeurFileDossiers +
                          ecartFileDetail +
                          largeurDetailDossier;
              // Une source en echec et l'autre vide : la file n'est pas
              // connue, la phrase d'erreur au-dessus parle seule (jamais
              // « Rien a traiter » sur une lecture manquee).
              if (tous.isEmpty && erreurs.isNotEmpty) {
                return const SizedBox.shrink();
              }
              if (tous.isEmpty || visibles.isEmpty) {
                return SingleChildScrollView(
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
              final ElementATraiter? choisi = maitreDetail
                  ? (visibles
                            .where((ElementATraiter e) => e.id == _choisi)
                            .firstOrNull ??
                        visibles.first)
                  : null;
              final Widget file = SingleChildScrollView(
                key: const PageStorageKey<String>('adm18-file'),
                child: _File(
                  key: TraitementPage.cleFile,
                  elements: visibles,
                  maintenant: widget.horloge(),
                  choisi: choisi?.id,
                  onChoisir: (ElementATraiter e) {
                    if (maitreDetail) {
                      setState(() => _choisi = e.id);
                    } else {
                      AppBottomSheet.ouvrir<void>(
                        context,
                        titre: _titre(e),
                        constructeur: (BuildContext _) =>
                            DetailElement(element: e, avecTitre: false),
                      );
                    }
                  },
                ),
              );
              if (!maitreDetail || choisi == null) {
                return file;
              }
              return FocusTraversalGroup(
                policy: WidgetOrderTraversalPolicy(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(width: largeurFileDossiers, child: file),
                    const SizedBox(width: ecartFileDetail),
                    SizedBox(
                      width: largeurDetailDossier,
                      child: SingleChildScrollView(
                        key: ValueKey<String>(choisi.id),
                        child: DetailElement(
                          key: TraitementPage.cleDetail,
                          element: choisi,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Le titre d'un element : « Dossier de/d'{nom} », « Demande pour {nom} ».
String _titre(ElementATraiter e) => switch (e.nature) {
  NatureElement.dossier => titreRevue(e.nom),
  NatureElement.demande => t.admin.traitement.titreDemande(nom: e.nom),
};

String _deux(int n) => n.toString().padLeft(2, '0');

/// L'instant d'une ligne : l'heure le jour meme, sinon le jour et le mois.
String _quand(DateTime depuis, DateTime maintenant) =>
    groupePour(depuis, maintenant) == GroupeTemps.aujourdhui
    ? '${_deux(depuis.hour)}:${_deux(depuis.minute)}'
    : '${depuis.day} ${t.historique.moisCourts[depuis.month - 1]}';

/// La file, groupee par jour : un titre de groupe avec son nombre, puis une
/// carte groupee de lignes (`GroupeReglages`, contenus lies).
class _File extends StatelessWidget {
  const _File({
    required this.elements,
    required this.maintenant,
    required this.choisi,
    required this.onChoisir,
    super.key,
  });

  final List<ElementATraiter> elements;
  final DateTime maintenant;
  final String? choisi;
  final void Function(ElementATraiter element) onChoisir;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final Map<GroupeTemps, List<ElementATraiter>> groupes =
        <GroupeTemps, List<ElementATraiter>>{};
    for (final ElementATraiter e in elements) {
      groupes
          .putIfAbsent(
            groupePour(e.depuis, maintenant),
            () => <ElementATraiter>[],
          )
          .add(e);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          liveRegion: true,
          child: Text(
            elements.length == 1
                ? t.admin.traitement.compteurUn
                : t.admin.traitement.compteur(n: elements.length),
            style: textes.titleSmall,
          ),
        ),
        for (final MapEntry<GroupeTemps, List<ElementATraiter>> g
            in groupes.entries) ...<Widget>[
          Ecart.vLg,
          Semantics(
            header: true,
            child: Text(
              '${titreGroupe(g.key)} (${g.value.length})',
              style: palette.inkMuted.applyTo(
                textes.labelLarge ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vSm,
          GroupeReglages(
            lignes: <LigneRubrique>[
              for (final ElementATraiter e in g.value)
                LigneRubrique(
                  libelle: e.nom,
                  legende: e.precision,
                  valeur: _quand(e.depuis, maintenant),
                  selectionnee: choisi == null ? null : e.id == choisi,
                  pastille: _pastille(e),
                  pastilleSousLibelle: true,
                  libelleSemantique: t.admin.traitement.ligneSemantique(
                    nom: e.nom,
                    nature: e.precision,
                    quand: _quand(e.depuis, maintenant),
                  ),
                  onPress: () => onChoisir(e),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// La pastille d'une ligne : seulement l'etat de piece que le serveur dit
/// explicitement (aucune, hors de portee) ; aucune pastille « en attente »
/// repetee sur chaque ligne (releve AD-3R, pastille nominale retiree).
Widget? _pastille(ElementATraiter e) => switch (e.dossier?.etatPiece) {
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

/// Le detail d'un element : en-tete, « Informations generales », le bouton
/// qui mene a l'ecran de decision, puis « Suivi du traitement » (pas encore
/// branche, AD-X-BR-01 et 02).
class DetailElement extends StatelessWidget {
  /// Cree le detail.
  const DetailElement({
    required this.element,
    super.key,
    this.avecTitre = true,
  });

  /// L'element montre.
  final ElementATraiter element;

  /// Faux dans une feuille, qui porte deja le titre.
  final bool avecTitre;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final DossierAValider? dossier = element.dossier;
    final Demande? demande = element.demande;

    final List<Widget> lignes = <Widget>[
      if (dossier != null) ...<Widget>[
        LigneCleValeur(
          cle: t.admin.traitement.cleNom,
          valeur: dossier.nom.isEmpty ? dossier.libelle : dossier.nom,
        ),
        if (dossier.prenom.isNotEmpty)
          LigneCleValeur(
            cle: t.admin.traitement.clePrenom,
            valeur: dossier.prenom,
          ),
        LigneCleValeur(
          cle: t.admin.traitement.cleType,
          valeur: t.admin.journal.roleEnseignant,
        ),
        LigneCleValeur(
          cle: t.admin.traitement.cleDepot,
          valeur: dateRevue(dossier.deposeLe),
          chiffres: true,
        ),
        LigneCleValeur(
          cle: t.admin.traitement.clePiece,
          valeur: switch (dossier.etatPiece) {
            EtatPiece.aucune => t.dossiers.sansPiece,
            EtatPiece.nonVisible => t.dossiers.pieceNonVisible,
            _ => t.admin.traitement.pieceAVerifier,
          },
        ),
      ],
      if (demande != null) ...<Widget>[
        LigneCleValeur(
          cle: t.admin.traitement.cleConcerne,
          valeur: demande.sujetLibelle,
        ),
        LigneCleValeur(
          cle: t.admin.demandes.reclame,
          valeur: element.precision,
        ),
        LigneCleValeur(
          cle: t.admin.traitement.cleParQui,
          valeur: switch (demande.roleDemandeur) {
            AppRole.guardian => t.admin.demandes.roleGuardian,
            AppRole.teacher => t.admin.demandes.roleTeacher,
            AppRole.student => t.admin.demandes.roleStudent,
            AppRole.admin => t.admin.demandes.roleAdmin,
            AppRole.controller => t.admin.demandes.roleController,
            _ => t.admin.demandes.roleInconnu,
          },
        ),
        LigneCleValeur(
          cle: t.admin.demandes.motifDemande,
          valeur: demande.motif,
        ),
        LigneCleValeur(
          cle: t.admin.traitement.cleDateDemande,
          valeur: dateRevue(demande.creeeLe),
          chiffres: true,
        ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (avecTitre) ...<Widget>[
          Semantics(
            header: true,
            child: Text(_titre(element), style: textes.titleLarge),
          ),
          Ecart.vSm,
          Text(
            element.precision,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vXxxl,
        ],
        SectionHeader(titre: t.admin.traitement.infos),
        Ecart.vSm,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < lignes.length; i++) ...<Widget>[
                if (i > 0) Ecart.vMd,
                lignes[i],
              ],
            ],
          ),
        ),
        // L'objet, 16, puis le bouton qui agit dessus, au bord de fin
        // (contrat B). Le seul bouton plein de l'ecran.
        Ecart.vLg,
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ActionPrincipale(
            libelle: dossier != null
                ? ouvrirDossier(element.nom)
                : t.admin.traitement.ouvrirDemande(nom: element.nom),
            pleineLargeur: false,
            onPress: () {
              final GoRouter routeur = GoRouter.of(context);
              // Dans la feuille, la fermer d'abord ; en maitre-detail, rien.
              if (!avecTitre) Navigator.of(context).pop();
              if (dossier != null) {
                // Le dossier par `extra`, jamais par l'URL (spec l.1933).
                routeur.go(
                  Routes.adminPersonnesDossiers,
                  extra: dossier.profilId,
                );
              } else {
                routeur.go(Routes.adminOperationsDemandes);
              }
            },
          ),
        ),
        Ecart.vXxxl,
        SectionHeader(titre: t.admin.traitement.suiviTitre),
        Ecart.vSm,
        Text(
          t.admin.traitement.suiviPhrase,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
      ],
    );
  }
}
