// PERSONNES-UNE-PAGE, etape (b) (directeur, 20/11/2026 : « J'aime bien les
// onglets qui les affichent toutes comme dans la nouvelle page "Comptes" [...]
// Ajoute des icones sur les onglets pour etre plus reconnaissable, car il y a
// desormais un risque de faire quelque chose sur la liste des enseignants alors
// qu'on voulait les familles »).
//
// Une seule page « Personnes », la racine de la rubrique : quatre onglets avec
// icone (Eleves, Familles, Enseignants, Direction et equipe), chacun avec son
// nombre. L'onglet et la personne choisie vivent dans l'adresse (`onglet`,
// `element`, `page`) : recharger rend le meme ecran.
//
// Disposition « liste + apercu » (pilote, 21/11/2026, comme la messagerie) : a
// partir de 1024 points de fenetre, la liste a gauche (environ 40 %, colonnes
// reduites : la personne, son etat, UNE colonne utile a l'onglet) et l'apercu a
// droite ; toucher une ligne remplit l'apercu sans quitter la page ; les
// fleches haut et bas passent a la personne voisine. En dessous de 1024, la
// ligne ouvre le dossier (enseignant) ou l'apercu en feuille (les autres),
// comme dans Comptes depuis l'etape (a).
//
// Etape (d) : l'onglet des enseignants a ses vues (`vue` dans l'adresse) :
// Candidats (`lister_candidatures`, les 26 filtres de la file), En accueil,
// Actifs, Partis (`lister_enseignants`), Pieces a verifier
// (`dossiers_en_attente_references`). Chaque vue dit son nombre. Le dossier
// complet recoit la file de la vue : precedent, suivant et passage au suivant
// apres une decision y marchent comme depuis l'ancienne liste ; l'apercu passe
// lui aussi au suivant apres une decision (meme reglage).
//
// Aucune regle ici : les comptes viennent de `comptesProvider`, les
// enseignants de `pageEnseignantsProvider` (phase, « qui attend » decides par
// le serveur), l'apercu d'un enseignant de `lire_candidature`
// (`ApercuProfilCandidat`). Aucune donnee de contact dans l'apercu. Les
// anciennes pages gardent leur adresse.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/admin/port_fondateurs.dart';
import '../../core/admin/service_comptes.dart';
import '../../core/candidature/gestes_candidature.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/modeles_lot_candidatures.dart';
import '../../core/candidature/port_autres_competences.dart';
import '../../core/candidature/port_candidatures_direction.dart';
import '../../core/domain/enums.dart';
import '../../core/dossier/service_validation.dart';
import '../../core/enseignants/modeles_enseignants.dart';
import '../../core/enseignants/port_enseignants.dart';
import '../../core/i18n/identifiant_insecable.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/lieu/lieu_direction.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/barre_precedent_suivant.dart';
import '../../core/widgets/barre_selection.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pied_de_liste.dart';
import '../../core/widgets/puce_filtre_actif.dart';
import '../../core/widgets/selecteur_section.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../admin_candidature/libelles_candidature.dart' show libelleGeste;
import '../admin_candidature/references_dossiers.dart';
import '../admin_candidatures/feuille_filtres.dart' show ouvrirFeuilleTri;
import '../admin_candidatures/libelles_candidatures.dart'
    show etatAffiche, libelleSalle, nomAffiche;
import '../admin_candidatures/menu_ligne_candidature.dart'
    show gestesDuMenuLigne, iconeDuGeste;
import '../admin_candidatures/selection_lot.dart';
import '../admin_comptes/apercu_compte.dart';
import '../admin_comptes/gestes_compte.dart';
import '../admin_comptes/liste_comptes.dart';
import '../admin_enseignants/enseignants_page.dart'
    show gestesDeLot, gestesDuMenuEnseignant, libellePhase, motAttend;
import '../com_messages/apercu_profil_candidat.dart'
    show apercuCandidatureProvider;
import '../foyer/photo_eleve.dart';
import 'apercu_candidat.dart';
import 'barre_filtres_personnes.dart';
import 'filtres_personnes.dart';

/// Les onglets de la page, un par population.
enum OngletPersonnes {
  /// Les eleves (un tuteur qui apprend pour lui-meme y est aussi).
  eleves('eleves'),

  /// Les familles : les tuteurs.
  familles('familles'),

  /// Les enseignants, candidats compris.
  enseignants('enseignants'),

  /// La direction et l'equipe.
  equipe('equipe');

  const OngletPersonnes(this.cle);

  /// La valeur ecrite dans l'adresse (`onglet=`).
  final String cle;

  /// L'onglet de l'adresse ; sans valeur lisible, les enseignants (la
  /// population qui attend le plus de decisions aujourd'hui).
  static OngletPersonnes depuis(String? cle) => values.firstWhere(
    (OngletPersonnes o) => o.cle == cle,
    orElse: () => OngletPersonnes.enseignants,
  );

  /// La vue des comptes de cet onglet, ou `null` pour les enseignants.
  VueComptes? get vue => switch (this) {
    OngletPersonnes.eleves => VueComptes.eleves,
    OngletPersonnes.familles => VueComptes.familles,
    OngletPersonnes.equipe => VueComptes.direction,
    OngletPersonnes.enseignants => null,
  };
}

/// La largeur de fenetre a partir de laquelle la liste et l'apercu se posent
/// cote a cote (pilote, 21/11/2026).
const double largeurListeEtApercu = 1024;

/// L'echelle du texte au-dela de laquelle la page reste en une colonne.
const double echelleMaxCoteACote = 1.3;

/// La part de la liste dans la disposition cote a cote.
const double _partListe = 0.4;

/// Une liste lue au serveur pour une vue des enseignants.
typedef ListeVue = ({
  List<LignePersonne> lignes,
  int total,
  int page,
  int taillePage,
});

/// La derniere liste d'une vue des enseignants affichee : pendant qu'un filtre
/// ou une recherche se relit au serveur, elle reste a l'ecran (la liste ne
/// saute pas, le champ de recherche garde sa saisie et son focus). Ce n'est
/// qu'un confort d'affichage : la liste lue la remplace des qu'elle arrive.
({VueEnseignants vue, ListeVue liste})? _derniereListe;

/// La vue « Actifs » sans phase choisie : chaque phase de [phasesActives] est
/// lue au serveur (`lister_enseignants` ne filtre qu'une phase a la fois), en
/// entier, puis les lignes se suivent phase par phase (le tri vaut dans
/// chaque phase). La cle : le texte cherche et le tri.
final enseignantsActifsProvider = FutureProvider.autoDispose
    .family<PageEnseignants, ({String recherche, TriEnseignants tri})>((
      Ref ref,
      ({String recherche, TriEnseignants tri}) demande,
    ) async {
      // Une seule ligne par dossier : une personne qui change de phase entre
      // deux lectures serait rendue par deux phases. La derniere lue gagne,
      // a sa place la plus recente.
      final Map<String, LigneEnseignant> parReference =
          <String, LigneEnseignant>{};
      CompteursEnseignants compteurs = const CompteursEnseignants();
      for (final PhaseEnseignant phase in phasesActives) {
        for (int page = 1; page <= _pagesMaxParPhase; page++) {
          final PageEnseignants lue = await ref.watch(
            pageEnseignantsProvider(
              RequeteEnseignants(
                filtre: FiltreEnseignants(
                  recherche: demande.recherche,
                  phase: phase,
                ),
                tri: demande.tri,
                page: page,
              ),
            ).future,
          );
          compteurs = lue.compteurs;
          for (final LigneEnseignant l in lue.lignes) {
            parReference
              ..remove(l.dossier.reference)
              ..[l.dossier.reference] = l;
          }
          if (lue.lignes.isEmpty || page >= lue.pages) break;
        }
      }
      final List<LigneEnseignant> lignes = parReference.values.toList(
        growable: false,
      );
      return PageEnseignants(
        lignes: lignes,
        total: lignes.length,
        page: 1,
        taillePage: lignes.isEmpty ? 1 : lignes.length,
        compteurs: compteurs,
      );
    }, retry: (int _, Object _) => null);

/// Garde-fou de [enseignantsActifsProvider] : jamais plus de pages par phase.
const int _pagesMaxParPhase = 20;

/// Une ligne de la page : une personne, quel que soit l'onglet.
@immutable
class LignePersonne {
  const LignePersonne._({
    required this.cle,
    required this.nom,
    required this.prenom,
    required this.profilId,
    required this.colonne,
    this.etat,
    this.ton = TonEtat.neutre,
    this.compte,
    this.dossier,
    this.enseignant,
    this.piece,
  });

  /// Ce qui designe la personne dans l'adresse : son matricule, ou la
  /// reference de son dossier (jamais un nom).
  final String cle;

  /// Le nom affiche.
  final String nom;

  /// Le prenom, pour le cercle.
  final String prenom;

  /// Le profil, pour la photo ; `null` pour un dossier sans compte.
  final String? profilId;

  /// La colonne utile a l'onglet.
  final String colonne;

  /// L'etat qui sort de l'ordinaire, ou `null`.
  final String? etat;

  /// Le ton de la pastille de [etat].
  final TonEtat ton;

  /// Le compte, pour un eleve, une famille, un membre de l'equipe.
  final CompteAdmin? compte;

  /// Le dossier de candidature, pour un candidat ou un enseignant.
  final LigneCandidature? dossier;

  /// La ligne du serveur, pour un enseignant (vues hors « Candidats »).
  final LigneEnseignant? enseignant;

  /// La piece a verifier (vue « Pieces a verifier »).
  final DossierAValider? piece;
}

/// L'ecran « Personnes ».
class PersonnesPage extends ConsumerStatefulWidget {
  /// Cree l'ecran. [requete] : les parametres de l'adresse.
  const PersonnesPage({
    super.key,
    this.requete = const <String, String>{},
    this.ouvrirDossier,
  });

  /// `onglet`, `vue`, `element`, `page`, la recherche et les filtres.
  final Map<String, String> requete;

  /// Ouvre le dossier complet d'un enseignant ; par defaut, le routeur.
  final void Function(String chemin, String identifiant)? ouvrirDossier;

  /// La cle du selecteur des vues de l'onglet des enseignants.
  static const Key cleVues = ValueKey<String>('personnes-vues');

  /// La cle du lien « Verifier la piece » de l'apercu d'une piece.
  static const Key cleVerifierPiece = ValueKey<String>(
    'personnes-verifier-piece',
  );

  /// La cle des onglets.
  static const Key cleOnglets = ValueKey<String>('personnes-onglets');

  /// La cle de l'apercu de droite.
  static const Key cleApercu = ValueKey<String>('personnes-apercu');

  /// La cle de la barre precedent / suivant de l'apercu.
  static const Key cleVoisins = ValueKey<String>('personnes-voisins');

  /// La cle du menu des anciennes pages de la rubrique.
  static const Key cleAutresPages = ValueKey<String>('personnes-autres-pages');

  /// La cle du nom de l'onglet ouvert, ecrit en toutes lettres au telephone.
  static const Key cleNomOnglet = ValueKey<String>('personnes-nom-onglet');

  /// L'icone d'un onglet. Quatre dessins sans parente : un livre (l'eleve
  /// apprend), une maison (la famille), la toque (l'enseignant), la mallette
  /// (l'equipe). Jamais deux groupes de personnes cote a cote (directeur,
  /// 20/11/2026 : le risque d'agir sur la mauvaise liste).
  static AppIcon iconeOnglet(OngletPersonnes o) => switch (o) {
    OngletPersonnes.eleves => AppIcons.livreOuvert,
    OngletPersonnes.familles => AppIcons.maison,
    OngletPersonnes.enseignants => AppIcons.pedagogie,
    OngletPersonnes.equipe => AppIcons.studio,
  };

  /// La cle de la liste.
  static const Key cleListe = ValueKey<String>('personnes-liste');

  /// La cle du bouton « Trier par ».
  static const Key cleTri = ValueKey<String>('personnes-tri');

  /// La cle de la barre du lot (dossiers retenus).
  static const Key cleBarreLot = ValueKey<String>('personnes-barre-lot');

  /// La cle de l'operation d'un geste du lot.
  static Key cleOperationLot(GesteLot geste) =>
      ValueKey<String>('personnes-lot-${geste.name}');

  /// La cle de la barre des comptes choisis.
  static const Key cleBarreComptes = ValueKey<String>(
    'personnes-barre-comptes',
  );

  /// La cle de « Supprimer » de la barre des comptes choisis.
  static const Key cleSupprimerComptes = ValueKey<String>(
    'personnes-supprimer-comptes',
  );

  /// La cle du menu « ... » d'une ligne.
  static Key cleMenuLigne(String cle) =>
      ValueKey<String>('personnes-menu-$cle');

  @override
  ConsumerState<PersonnesPage> createState() => _PersonnesPageEtat();
}

class _PersonnesPageEtat extends ConsumerState<PersonnesPage>
    with GesteDeLigneEtat<PersonnesPage> {
  Map<String, String> get requete => widget.requete;

  /// Etape (f) point 2 : les dossiers retenus pour un lot (onglet des
  /// enseignants), gardes d'une page a l'autre (`selection_lot.dart`).
  final SelectionLot<LigneEnseignant> _lot = SelectionLot<LigneEnseignant>();

  /// Les comptes choisis pour une suppression (les autres onglets).
  final Map<String, CompteAdmin> _choisis = <String, CompteAdmin>{};

  /// Les references des dossiers d'enseignant, par profil ; vide tant
  /// qu'elles ne sont pas lues.
  Map<String, String> _references = const <String, String>{};

  /// Le compte de chaque dossier dont la reference est connue.
  Map<String, CompteAdmin> _compteParReference = const <String, CompteAdmin>{};

  /// Les villes des enseignants, par profil.
  Map<String, LieuEnseignantDirection> _lieux =
      const <String, LieuEnseignantDirection>{};

  /// Ce qui designe la liste affichee : l'adresse sans la personne choisie ni
  /// la page.
  static String _cleDeListe(Map<String, String> requete) {
    final List<String> cles = <String>[
      for (final String k in requete.keys)
        if (k != 'element' && k != 'page') k,
    ]..sort();
    return cles.map((String k) => '$k=${requete[k]}').join('&');
  }

  /// Un onglet, une vue, un filtre, une recherche ou un tri qui change retire
  /// la selection, et le dit (DECISION-LISTES §6 : jamais en silence).
  @override
  void didUpdateWidget(PersonnesPage ancien) {
    super.didUpdateWidget(ancien);
    if (_cleDeListe(ancien.requete) == _cleDeListe(widget.requete)) return;
    final bool memeOnglet =
        OngletPersonnes.depuis(ancien.requete['onglet']) == _onglet;
    if (!_lot.estVide) {
      _lot.relacherTout();
      retourLigne = memeOnglet && _onglet == OngletPersonnes.enseignants
          ? t.admin.candidatures.lot.selectionRetiree
          : null;
    }
    if (_choisis.isNotEmpty) {
      _choisis.clear();
      _bilan = memeOnglet
          ? BilanSuppression.message(
              t.admin.comptes.retrait.selectionRetiree,
              alerte: false,
            )
          : null;
    }
  }

  void Function(String chemin, String identifiant)? get ouvrirDossier =>
      widget.ouvrirDossier;

  /// Etape (f) : la phrase du dernier geste sur un compte (coche
  /// « fondateur »), ou `null`.
  String? _retour;

  /// Le bilan de la derniere suppression, ou `null`.
  BilanSuppression? _bilan;

  /// Une suppression est partie : un second toucher est ignore.
  bool _suppressionEnCours = false;

  /// Coche ou decoche [c] ; la phrase apres la reponse du serveur seulement.
  Future<void> _poserFondateur(CompteAdmin c, {required bool fondateur}) async {
    final String? message = await poserFondateur(ref, c, fondateur: fondateur);
    if (message == null || !mounted) return;
    setState(() => _retour = null);
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) setState(() => _retour = message);
    });
  }

  /// Marque la ville de [c] comme verifiee ; la phrase apres la reponse.
  Future<void> _verifierVille(CompteAdmin c) async {
    final String message = await verifierVilleDuCompte(ref, c);
    if (!mounted) return;
    setState(() => _retour = null);
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) setState(() => _retour = message);
    });
  }

  /// Supprime [comptes] apres sa confirmation (le geste de la page
  /// « Comptes »).
  Future<void> _supprimer(List<CompteAdmin> comptes) async {
    if (_suppressionEnCours || comptes.isEmpty) return;
    final BilanSuppression? bilan = await supprimerComptes(
      context,
      ref,
      comptes,
      onDebut: () => setState(() {
        _suppressionEnCours = true;
        _bilan = null;
      }),
    );
    if (bilan == null || !mounted) return;
    setState(() {
      _suppressionEnCours = false;
      _bilan = bilan;
      // Rien n'est parti (hors connexion avant l'envoi) : la selection reste.
      if (!bilan.avantEnvoi) _choisis.clear();
    });
  }

  /// Les gestes d'un compte : ceux de la page « Comptes », dans le meme ordre
  /// (`gestesDuCompte`), le destructif en dernier. Au telephone en Interface
  /// guidee, pas de suppression (comme dans « Comptes »).
  List<EntreeAction> _gestesCompte(
    BuildContext context,
    CompteAdmin c,
    VueComptes vue, {
    bool dossier = true,
  }) {
    final Set<String>? fondateurs = ref.watch(fondateursProvider).value;
    final bool suppressionOfferte =
        DataCollection.enTableau(context) ||
        !AppMetriques.of(context).estEnfant;
    return gestesDuCompte(
      context,
      c,
      fondateur: porteLaCocheFondateur(c, vue, fondateurs)
          ? fondateurs!.contains(c.profilId)
          : null,
      onFondateur: ({required bool fondateur}) =>
          unawaited(_poserFondateur(c, fondateur: fondateur)),
      onSupprimer:
          suppressionOfferte && compteSupprimable(c) && !_suppressionEnCours
          ? () => unawaited(_supprimer(<CompteAdmin>[c]))
          : null,
      // « Ouvrir le dossier », « Verifier la ville » (ceux de « Comptes »).
      propres: gestesDossierEtVille(
        context,
        c,
        references: _references,
        lieux: _lieux,
        onVerifierVille: () => unawaited(_verifierVille(c)),
        dossier: dossier,
      ),
    );
  }

  OngletPersonnes get _onglet => OngletPersonnes.depuis(requete['onglet']);

  int get _page => (int.tryParse(requete['page'] ?? '') ?? 1).clamp(1, 100000);

  VueEnseignants get _vue => VueEnseignants.depuis(requete['vue']);

  void _aller(
    BuildContext context, {
    OngletPersonnes? onglet,
    VueEnseignants? vue,
    String? element,
    int? page,
    Map<String, String>? filtres,
    String? recherche,
    String? tri,
    bool sansHistorique = false,
  }) {
    final OngletPersonnes o = onglet ?? _onglet;
    // Changer d'onglet, de vue, de filtre ou de recherche revient a la
    // premiere page.
    final bool autreListe = onglet != null || vue != null;
    final bool neuf =
        autreListe || filtres != null || recherche != null || tri != null;
    // Le tri pose reste, sauf sur une autre liste ; vide : l'ordre par defaut.
    final String ordre = autreListe
        ? ''
        : tri ?? requete[cleTriPersonnes] ?? '';
    final int p = neuf ? 1 : (page ?? _page);
    // Un autre onglet ou une autre vue oublie filtres et recherche : ils ne
    // sont pas les siens.
    final Map<String, String> f = autreListe
        ? const <String, String>{}
        : filtres ?? _filtresPoses;
    final String q = autreListe
        ? ''
        : recherche ?? rechercheDeLAdresse(requete);
    final String adresse = Uri(
      path: Routes.adminPersonnes,
      queryParameters: <String, String>{
        'onglet': o.cle,
        if (o == OngletPersonnes.enseignants)
          'vue':
              (vue ?? (onglet == null ? _vue : VueEnseignants.candidats)).cle,
        if (p > 1) 'page': '$p',
        if (q.isNotEmpty) cleRecherchePersonnes: q,
        ...f,
        if (ordre.isNotEmpty) cleTriPersonnes: ordre,
        'element': ?element,
      },
    ).toString();
    final GoRouter routeur = GoRouter.of(context);
    // Choisir une personne ne remplit pas l'historique du navigateur : le
    // retour ramene a ce qu'on faisait avant, pas a chaque ligne regardee.
    if (sansHistorique) {
      Router.neglect(context, () => routeur.go(adresse));
    } else {
      routeur.go(adresse);
    }
  }

  /// Les filtres de l'adresse, sans le catalogue des competences (les cles
  /// posees y restent : seule une valeur inconnue du menu est ecartee a
  /// l'affichage).
  Map<String, String> get _filtresPoses => <String, String>{
    for (final TypeFiltrePersonnes type in typesDeFiltre(_onglet, vue: _vue))
      if (requete[type.cle] case final String v when v.isNotEmpty) type.cle: v,
  };

  /// Ouvre le dossier complet de [dossier], avec la file de la vue : dans le
  /// dossier, precedent, suivant et passage au suivant suivent cette liste.
  void _ouvrirDossier(
    BuildContext context,
    LigneCandidature dossier, {
    PhaseEnseignant? phase,
  }) {
    final String chemin = Routes.adminPersonnesCandidaturePour(
      dossier.reference,
      fileDeLaListe: <String, String>{
        ...fileDeLaVue(_vue, _filtresPoses, phaseDeLaLigne: phase),
        // Le dossier suit la liste dans son ordre.
        if (requete[cleTriPersonnes] case final String ordre
            when ordre.isNotEmpty && _vue != VueEnseignants.pieces)
          cleTriPersonnes: ordre,
        if (_page > 1) 'page': '$_page',
      },
    );
    _ouvrir(context, chemin, dossier.id);
  }

  void _ouvrir(BuildContext context, String chemin, String identifiant) {
    final void Function(String, String)? ouvrir = ouvrirDossier;
    if (ouvrir != null) {
      ouvrir(chemin, identifiant);
    } else {
      unawaited(GoRouter.of(context).push<void>(chemin, extra: identifiant));
    }
  }

  /// La liste de la vue [vue] des enseignants, telle que le serveur la rend.
  ({
    AsyncValue<ListeVue> valeur,
    VoidCallback relire,
    String echec,
    String vide,
  })
  _listeEnseignants(
    WidgetRef ref,
    VueEnseignants vue,
    Map<String, String> filtres,
    String recherche,
  ) {
    switch (vue) {
      case VueEnseignants.candidats:
        final RequeteCandidatures r = RequeteCandidatures(
          filtre: filtreCandidatsDe(filtres, recherche),
          tri: triCandidatsDe(requete[cleTriPersonnes]),
          page: _page,
        );
        return (
          valeur: ref
              .watch(pageCandidaturesProvider(r))
              .whenData(
                (PageCandidatures page) => (
                  lignes: <LignePersonne>[
                    for (final LigneCandidature l in page.lignes)
                      _deCandidat(l),
                  ],
                  total: page.total,
                  page: page.page,
                  taillePage: page.taillePage,
                ),
              ),
          relire: () => ref.invalidate(pageCandidaturesProvider),
          echec: t.admin.candidatures.lectureEchec,
          vide: t.admin.candidatures.vide,
        );
      case VueEnseignants.pieces:
        return (
          valeur: ref.watch(piecesAVerifierProvider).whenData((
            List<DossierAValider> tous,
          ) {
            final List<LignePersonne> lignes = <LignePersonne>[
              for (final DossierAValider d in _piecesEnseignants(tous))
                if (_pieceCorrespond(d, recherche)) _dePiece(d),
            ];
            return (
              lignes: lignes,
              total: lignes.length,
              page: 1,
              taillePage: lignes.isEmpty ? 1 : lignes.length,
            );
          }),
          relire: () => ref.invalidate(piecesAVerifierProvider),
          echec: t.dossiers.file.erreur,
          vide: t.dossiers.aucun,
        );
      case VueEnseignants.accueil ||
          VueEnseignants.actifs ||
          VueEnseignants.partis:
        final FiltreEnseignants f = filtreEnseignantsDe(
          vue,
          filtres,
          recherche,
        );
        final bool fusion = vue == VueEnseignants.actifs && f.phase == null;
        final TriEnseignants ordre = triEnseignantsDe(requete[cleTriPersonnes]);
        final RequeteEnseignants r = RequeteEnseignants(
          filtre: f,
          tri: ordre,
          page: _page,
        );
        final AsyncValue<PageEnseignants> lue = fusion
            ? ref.watch(
                enseignantsActifsProvider((
                  recherche: f.rechercheNette,
                  tri: ordre,
                )),
              )
            : ref.watch(pageEnseignantsProvider(r));
        return (
          valeur: lue.whenData(
            (PageEnseignants page) => (
              lignes: <LignePersonne>[
                for (final LigneEnseignant l in page.lignes) _deEnseignant(l),
              ],
              total: page.total,
              page: page.page,
              taillePage: page.taillePage,
            ),
          ),
          relire: () => ref
            ..invalidate(pageEnseignantsProvider)
            ..invalidate(enseignantsActifsProvider),
          echec: t.admin.listeEnseignants.lectureEchec,
          vide: t.admin.comptes.videEnseignants,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = t.admin.personnesPage;
    final OngletPersonnes onglet = _onglet;
    final AsyncValue<List<CompteAdmin>> comptes = ref.watch(comptesProvider);
    final bool ens = onglet == OngletPersonnes.enseignants;
    final VueEnseignants vueEns = _vue;
    final bool candidats = ens && vueEns == VueEnseignants.candidats;
    final CapacitesCandidatures caps =
        ref.watch(capacitesCandidaturesProvider).value ??
        CapacitesCandidatures.aucune;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    // Etape (f) point 2 : la reference du dossier de chaque compte qui peut
    // porter une candidature d'enseignant (« Ouvrir le dossier »), et, pour
    // l'onglet des enseignants, le compte de chaque dossier (ses gestes de
    // compte) et sa ville.
    _references = comptes.hasValue
        ? ref
                  .watch(
                    referencesDossiersProvider(
                      profilsAvecDossierPossible(comptes.requireValue),
                    ),
                  )
                  .value ??
              const <String, String>{}
        : const <String, String>{};
    _compteParReference = <String, CompteAdmin>{
      for (final CompteAdmin c in comptes.value ?? const <CompteAdmin>[])
        if (_references[c.profilId] case final String reference) reference: c,
    };
    _lieux = ens
        ? ref.watch(lieuxEnseignantsProvider).value ??
              const <String, LieuEnseignantDirection>{}
        : const <String, LieuEnseignantDirection>{};
    final List<TypeFiltrePersonnes> types = typesDeFiltre(
      onglet,
      vue: vueEns,
      // Le catalogue des autres competences et « Garder pour suivi » ne se
      // lisent que pour la vue qui les propose.
      catalogue: candidats
          ? ref.watch(catalogueCompetencesProvider).value
          : null,
      garderPourSuivi:
          candidats &&
          (ref
                  .watch(capacitesCandidaturesProvider)
                  .value
                  ?.peutGarderPourSuivi ??
              false),
    );
    final Map<String, String> filtres = filtresDeLAdresse(types, requete);
    final String recherche = rechercheDeLAdresse(requete);
    final bool filtre = filtres.isNotEmpty || recherche.isNotEmpty;
    // Le nombre de l'onglet des enseignants et ceux de ses vues : la lecture
    // sans filtre (gardee en cache), ses compteurs par phase.
    final PageEnseignants? tousEnseignants = ref
        .watch(pageEnseignantsProvider(const RequeteEnseignants()))
        .value;
    final int? totalEnseignants = tousEnseignants?.total;
    // La liste de la vue, filtree par le serveur.
    final liste = ens
        ? _listeEnseignants(ref, vueEns, filtres, recherche)
        : null;
    final AsyncValue<ListeVue>? lue = liste?.valeur;
    if (lue != null && lue.hasValue && !lue.isLoading) {
      _derniereListe = (vue: vueEns, liste: lue.requireValue);
    }
    // Relecture apres un filtre : la liste precedente de la vue reste affichee.
    final ListeVue? precedente = _derniereListe?.vue == vueEns
        ? _derniereListe?.liste
        : null;
    final AsyncValue<ListeVue>? listeAffichee =
        lue != null && lue.isLoading && !lue.hasError && precedente != null
        ? AsyncData<ListeVue>(precedente)
        : lue;
    // Le nombre de chaque vue, sans filtre ; `null` tant qu'il n'est pas lu.
    int? nombreVue(VueEnseignants v) => switch (v) {
      VueEnseignants.candidats =>
        ref
            .watch(pageCandidaturesProvider(const RequeteCandidatures()))
            .value
            ?.total,
      VueEnseignants.accueil => tousEnseignants?.compteurs.de(
        PhaseEnseignant.accueil,
      ),
      VueEnseignants.actifs =>
        tousEnseignants == null
            ? null
            : phasesActives.fold<int>(
                0,
                (int n, PhaseEnseignant ph) =>
                    n + tousEnseignants.compteurs.de(ph),
              ),
      VueEnseignants.partis => tousEnseignants?.compteurs.de(
        PhaseEnseignant.parti,
      ),
      VueEnseignants.pieces =>
        ref.watch(piecesAVerifierProvider).value == null
            ? null
            : _piecesEnseignants(
                ref.watch(piecesAVerifierProvider).requireValue,
              ).length,
    };
    // Texte agrandi au-dela de 130 % : une seule colonne qui defile en
    // entier (les onglets agrandis ne tiennent plus au-dessus de deux cadres ;
    // garde de reflow AD-11).
    final bool coteACote =
        MediaQuery.sizeOf(context).width >= largeurListeEtApercu &&
        MediaQuery.textScalerOf(context).scale(1) <= echelleMaxCoteACote;

    int? nombre(OngletPersonnes o) => switch (o.vue) {
      null => totalEnseignants,
      final VueComptes vue =>
        comptes.value
            ?.where((CompteAdmin c) => VueComptes.de(c).contains(vue))
            .length,
    };
    String court(OngletPersonnes o) => switch (o) {
      OngletPersonnes.eleves => t.admin.comptes.vueEleves,
      OngletPersonnes.familles => t.admin.comptes.vueFamilles,
      OngletPersonnes.enseignants => t.admin.comptes.vueEnseignants,
      OngletPersonnes.equipe => p.ongletEquipeCourt,
    };
    String libelle(OngletPersonnes o) {
      final String nom = o == OngletPersonnes.equipe
          ? p.ongletEquipe
          : court(o);
      final int? n = nombre(o);
      return n == null ? nom : p.ongletAvecNombre(nom: nom, n: n);
    }

    final Widget selecteur = SelecteurSection<OngletPersonnes>(
      key: PersonnesPage.cleOnglets,
      libelle: p.choix,
      menuAuContenu: true,
      valeur: onglet,
      onChange: (OngletPersonnes o) => _aller(context, onglet: o),
      sections: <Segment<OngletPersonnes>>[
        for (final OngletPersonnes o in OngletPersonnes.values)
          Segment<OngletPersonnes>(
            valeur: o,
            libelle: libelle(o),
            // Au telephone, le mot court sous l'icone (pilote, 21/11/2026).
            libelleCourt: court(o),
            icone: PersonnesPage.iconeOnglet(o),
          ),
      ],
    );
    // Au telephone, le nom de l'onglet ouvert et son nombre en toutes
    // lettres, sous les onglets : on sait toujours quelle liste on regarde,
    // meme quand les onglets se reduisent a leurs icones.
    final TextTheme textes = Theme.of(context).textTheme;
    String libelleVue(VueEnseignants v) {
      final String nom = switch (v) {
        VueEnseignants.candidats => p.vueCandidats,
        VueEnseignants.accueil => p.vueAccueil,
        VueEnseignants.actifs => p.vueActifs,
        VueEnseignants.partis => p.vuePartis,
        VueEnseignants.pieces => p.vuePieces,
      };
      final int? n = nombreVue(v);
      return n == null ? nom : p.ongletAvecNombre(nom: nom, n: n);
    }

    // Les vues de l'onglet des enseignants : cinq sections, donc en ligne a
    // l'ordinateur et en menu deroulant au telephone (ONGLETS-1 : jamais une
    // rangee qui defile).
    final Widget? vues = ens
        ? SelecteurSection<VueEnseignants>(
            key: PersonnesPage.cleVues,
            libelle: p.choixVue,
            menuAuContenu: true,
            valeur: vueEns,
            onChange: (VueEnseignants v) => _aller(context, vue: v),
            sections: <Segment<VueEnseignants>>[
              for (final VueEnseignants v in VueEnseignants.values)
                Segment<VueEnseignants>(valeur: v, libelle: libelleVue(v)),
            ],
          )
        : null;
    final Widget onglets =
        MediaQuery.sizeOf(context).width >= AppGabarit.seuilTablette
        ? selecteur
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              selecteur,
              Ecart.vSm,
              Semantics(
                header: true,
                child: Text(
                  libelle(onglet),
                  key: PersonnesPage.cleNomOnglet,
                  style: AppPalette.of(context).inkStrong
                      .applyTo(textes.titleMedium ?? const TextStyle()),
                ),
              ),
              Ecart.vSm,
            ],
          );

    // Les comptes de l'onglet, puis ceux qui passent le filtre.
    final VueComptes? vue = onglet.vue;
    final List<CompteAdmin>? deLaVue = vue == null
        ? null
        : comptes.value
              ?.where((CompteAdmin c) => VueComptes.de(c).contains(vue))
              .toList(growable: false);
    final String? ordreBrut = requete[cleTriPersonnes];
    final TriComptes? triComptes = vue == null ? null : triComptesDe(ordreBrut);
    final List<CompteAdmin>? gardes = deLaVue == null
        ? null
        : filtrerComptes(
            deLaVue,
            filtres: filtres,
            recherche: recherche,
            maintenant: DateTime.now(),
            tri: triComptes,
          );
    // Le tri : un seul bouton « Trier par », et l'ordre pose dit en puce,
    // comme un filtre (jamais un ordre qu'on ne voit pas).
    final rTri = t.admin.candidatures.tri;
    final k = t.admin.comptes;
    Widget? boutonTri;
    String? ordrePose;
    if (candidats) {
      final TriCandidatures ordre = triCandidatsDe(ordreBrut);
      boutonTri = BoutonIcone(
        key: PersonnesPage.cleTri,
        icone: AppIcons.triNeutre,
        libelle: rTri.titre,
        onPress: () => unawaited(
          ouvrirFeuilleTri(
            context,
            lire: () => ordre,
            poser: (TriCandidatures choisi) => _aller(
              context,
              tri: choisi == TriCandidatures.activite ? '' : choisi.name,
            ),
          ),
        ),
      );
      ordrePose = switch (ordre) {
        TriCandidatures.activite => null,
        TriCandidatures.recente => rTri.reception,
        TriCandidatures.ancienne => rTri.anciennete,
        TriCandidatures.nom => k.colonnePersonne,
      };
    } else if (ens && vueEns != VueEnseignants.pieces) {
      final TriEnseignants ordre = triEnseignantsDe(ordreBrut);
      boutonTri = MenuActions(
        key: PersonnesPage.cleTri,
        libelle: rTri.titre,
        icone: AppIcons.triNeutre,
        actions: <EntreeAction>[
          EntreeAction(
            libelle: rTri.activite,
            onChoix: () => _aller(context, tri: ''),
          ),
          EntreeAction(
            libelle: rTri.reception,
            onChoix: () => _aller(context, tri: TriEnseignants.recente.name),
          ),
        ],
      );
      ordrePose = switch (ordre) {
        TriEnseignants.activite => null,
        TriEnseignants.recente => rTri.reception,
        TriEnseignants.nom => k.colonnePersonne,
      };
    } else if (vue != null) {
      String colonne(ChampTriComptes c) => switch (c) {
        ChampTriComptes.nom => k.colonnePersonne,
        ChampTriComptes.etat => k.colonneEtat,
        ChampTriComptes.inscrit => k.colonneAttente,
      };
      boutonTri = MenuActions(
        key: PersonnesPage.cleTri,
        libelle: rTri.titre,
        icone: AppIcons.triNeutre,
        actions: <EntreeAction>[
          // Le cycle de la page « Comptes » : croissant, decroissant, plus
          // de tri (`TriComptes.suivant`).
          for (final ChampTriComptes c in ChampTriComptes.values)
            EntreeAction(
              libelle: colonne(c),
              onChoix: () => _aller(
                context,
                tri:
                    adresseDuTriComptes(TriComptes.suivant(triComptes, c)) ??
                    '',
              ),
            ),
        ],
      );
      ordrePose = triComptes == null
          ? null
          : triComptes.croissant
          ? colonne(triComptes.champ)
          : p.triInverse(colonne: colonne(triComptes.champ));
    }

    final Widget barre = BarreFiltresPersonnes(
      types: types,
      filtres: filtres,
      recherche: recherche,
      affiches: vue == null
          ? (lue == null || lue.isLoading ? null : lue.value?.total)
          : gardes?.length,
      // Sans filtre, le total est celui de la liste lue ; avec, celui de la
      // vue entiere.
      total: vue == null
          ? (filtre
                ? nombreVue(vueEns)
                : (lue == null || lue.isLoading ? null : lue.value?.total))
          : deLaVue?.length,
      onFiltre: (String type, String? valeur) => _aller(
        context,
        filtres: <String, String>{
          for (final MapEntry<String, String> e in filtres.entries)
            if (e.key != type) e.key: e.value,
          type: ?valeur,
        },
      ),
      onRecherche: (String texte) {
        if (texte != recherche) {
          _aller(context, recherche: texte, sansHistorique: true);
        }
      },
      onToutEffacer: () => _aller(
        context,
        filtres: const <String, String>{},
        recherche: '',
        tri: '',
      ),
      tri: boutonTri,
      triActif: ordrePose == null
          ? null
          : FiltreActif(
              libelle: p.puce(type: rTri.titre, valeur: ordrePose),
              onRetirer: () => _aller(context, tri: ''),
            ),
    );
    // Etape (f) point 2 : la barre de ce qui est retenu (dossiers pour un
    // lot, comptes pour une suppression). Celle des comptes : a partir de 640
    // points elle tient sur une ligne et reste collee sous la liste ; au
    // telephone elle vient dans le fil, en tete (comme dans « Comptes »).
    final List<LignePersonne> lignesLues =
        listeAffichee?.value?.lignes ?? const <LignePersonne>[];
    Widget? barreSelection;
    if (ens && !_lot.estVide) {
      barreSelection = BarreLot(
        cleBarre: PersonnesPage.cleBarreLot,
        nombre: _lot.nombre,
        surLaPage: lignesLues
            .where(
              (LignePersonne l) =>
                  l.dossier != null && _lot.contient(l.dossier!.id),
            )
            .length,
        capacites: caps,
        horsLigne: horsLigne,
        // Candidats : tous les gestes du lot que les capacites ouvrent ; les
        // autres vues : ceux que toutes les lignes retenues permettent.
        gestes: candidats ? GesteLot.values : gestesDeLot(_lot.lignes.values),
        parTranches: candidats,
        onRelacher: () => setState(_lot.relacherTout),
        onLancer: (GesteLot g) => unawaited(
          lancerLotDeLaSelection<LigneEnseignant>(
            context,
            selection: _lot,
            geste: g,
            capacites: caps,
            onRapport: (RapportLot rapport) {
              if (!mounted) return;
              liste?.relire();
              setState(() => retourLigne = _lot.apresRapport(rapport));
            },
            onAucunEligible: (List<String> ids) {
              if (mounted) setState(() => _lot.reporterEnFin(ids));
            },
          ),
        ),
        cleOperation: PersonnesPage.cleOperationLot,
      );
    } else if (vue != null && _choisis.isNotEmpty) {
      barreSelection = BarreSuppressionComptes(
        cleBarre: PersonnesPage.cleBarreComptes,
        cleSupprimer: PersonnesPage.cleSupprimerComptes,
        nombre: _choisis.length,
        surLaPage:
            gardes
                ?.where((CompteAdmin c) => _choisis.containsKey(c.profilId))
                .length ??
            _choisis.length,
        enCours: _suppressionEnCours,
        onRelacher: () => setState(_choisis.clear),
        onSupprimer: () => unawaited(_supprimer(_choisis.values.toList())),
      );
    }
    // La barre du lot reste collee en bas a toute largeur (comme dans la file
    // des candidatures) : en tete, au telephone, elle cacherait la liste.
    final bool barreCollee =
        (ens && !_lot.estVide) ||
        MediaQuery.sizeOf(context).width >= BarreSelection.largeurCoteACote;
    final TextStyle discret = AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle());
    // Les onglets, les vues (enseignants), puis la recherche et le filtre :
    // toujours a la meme place, que la liste se lise, soit vide ou pleine.
    final Widget entete = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        onglets,
        if (vues != null) ...<Widget>[Ecart.vSm, vues],
        Ecart.vMd,
        if (coteACote)
          // Au-dessus de la liste, a sa largeur.
          FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: _partListe,
            child: barre,
          )
        else
          barre,
        if (!barreCollee && barreSelection != null) ...<Widget>[
          barreSelection,
          Ecart.vSm,
        ],
        // « Selectionner la page », puis « Selectionner les N resultats »
        // (candidats : le serveur rend tous les resultats du filtre).
        if (ens && !_lot.estVide && listeAffichee?.value != null) ...<Widget>[
          LigneSelectionTous<LigneEnseignant>(
            selection: _lot,
            idsDeLaPage: <String>[
              for (final LignePersonne l in lignesLues)
                if (_retenable(l)) l.dossier!.id,
            ],
            total: listeAffichee!.requireValue.total,
            onRetenirPage: () => setState(() {
              for (final LignePersonne l in lignesLues) {
                if (_retenable(l)) _lot.retenir(l.dossier!.id, l.enseignant);
              }
              _lot.oublierTous();
            }),
            onRetenirTous: candidats
                ? () => unawaited(_retenirTous(filtres, recherche))
                : null,
          ),
          Ecart.vSm,
        ],
        // Le dossier qui se lit avant un geste du menu d'une ligne, son
        // echec en mots, puis ce que le serveur a repondu.
        if (ouvertureLigne case final String nom) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              t.admin.candidatures.liste.ouverture(nom: nom),
              style: discret,
            ),
          ),
          Ecart.vSm,
        ],
        if (echecLigne case final String echec) ...<Widget>[
          LocalFeedback(message: echec),
          Ecart.vSm,
        ],
        if (retourLigne case final String retour) ...<Widget>[
          LocalFeedback(message: retour),
          Ecart.vSm,
        ],
        // Etape (f) : ce qu'un geste sur un compte vient de donner (coche
        // « fondateur », ville, suppression), dans le fil, au-dessus de la
        // liste.
        LocalFeedback(message: _retour),
        if (_bilan case final BilanSuppression bilan) ...<Widget>[
          VueBilanSuppression(
            bilan: bilan,
            onFermer: () => setState(() => _bilan = null),
          ),
          Ecart.vSm,
        ],
        // Au-dela du plafond, « Supprimer » n'est pas propose : on dit
        // pourquoi.
        if (_choisis.length > plafondSuppressionComptes) ...<Widget>[
          Text(
            t.admin.comptes.retrait.tropGrand(n: '$plafondSuppressionComptes'),
            style: discret,
          ),
          Ecart.vSm,
        ],
      ],
    );

    // Autant de lignes que la hauteur en tient (comme Comptes) : a 320 x 256
    // (reflow a 400 %), huit lignes deborderaient.
    final Widget lignesSquelette = LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints contraintes) {
        final double pas =
            AppMetriques.of(contexte).cibleTactile + AppSpacing.sm;
        return Skeleton.tableDense(
          lignes: contraintes.hasBoundedHeight
              ? (contraintes.maxHeight / pas).floor().clamp(2, 10)
              : 6,
        );
      },
    );
    // Pendant la lecture, l'en-tete reste : seule la liste est un squelette.
    // (Une colonne qui defile : a 320 x 256, l'en-tete depasse la hauteur.)
    final Widget squelette = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[entete, lignesSquelette],
      ),
    );
    final Widget corps = vue == null
        ? BlocAsynchrone<ListeVue>(
            valeur: listeAffichee!,
            squelette: squelette,
            titreEchec: liste!.echec,
            onReessayer: liste.relire,
            construire: (ListeVue page) => _contenu(
              context,
              ref,
              onglets: entete,
              coteACote: coteACote,
              lignes: page.lignes,
              vide: filtre ? p.aucunResultat : liste.vide,
              relire: liste.relire,
              decalage: (page.page - 1) * page.taillePage,
              total: page.total,
              pied: page.total > page.lignes.length
                  ? PiedDeListe(
                      debut: (page.page - 1) * page.taillePage + 1,
                      fin:
                          (page.page - 1) * page.taillePage +
                          page.lignes.length,
                      total: page.total,
                      onPrecedent: page.page > 1
                          ? () => _aller(context, page: page.page - 1)
                          : null,
                      onSuivant: page.page * page.taillePage < page.total
                          ? () => _aller(context, page: page.page + 1)
                          : null,
                    )
                  : null,
            ),
          )
        : BlocAsynchrone<List<CompteAdmin>>(
            valeur: comptes,
            squelette: squelette,
            titreEchec: t.admin.comptes.erreur,
            onReessayer: () => ref.invalidate(comptesProvider),
            construire: (List<CompteAdmin> tous) => _contenu(
              context,
              ref,
              onglets: entete,
              coteACote: coteACote,
              lignes: <LignePersonne>[
                for (final CompteAdmin c in gardes ?? tous) _deCompte(c, vue),
              ],
              relire: () => ref.invalidate(comptesProvider),
              vide: filtre
                  ? p.aucunResultat
                  : switch (vue) {
                      VueComptes.eleves => t.admin.comptes.videEleves,
                      VueComptes.familles => t.admin.comptes.videFamilles,
                      VueComptes.enseignants => t.admin.comptes.videEnseignants,
                      VueComptes.direction => t.admin.comptes.videDirection,
                    },
            ),
          );

    return PageShell(
      titre: t.nav.admin.personnes,
      listeBureau: true,
      // Les anciennes pages restent atteignables d'ici, au telephone aussi
      // (son tiroir ne montre pas les sous-liens), jusqu'a l'etape (e).
      actionsEntete: <Widget>[
        MenuActions(
          key: PersonnesPage.cleAutresPages,
          libelle: p.autresPages,
          icone: AppIcons.reglages,
          actions: <EntreeAction>[
            for (final SousLien lien in ongletsPersonnes())
              EntreeAction(
                libelle: lien.libelle,
                onChoix: () => GoRouter.of(context).go(lien.chemin),
              ),
          ],
        ),
      ],
      defilante: false,
      actions: barreCollee ? barreSelection : null,
      child: corps,
    );
  }

  /// Vrai quand la ligne peut etre retenue pour un lot : un candidat, ou un
  /// enseignant dont le serveur annonce au moins un geste groupable.
  bool _retenable(LignePersonne l) =>
      l.dossier != null &&
      l.piece == null &&
      (l.enseignant == null || l.enseignant!.gestesGroupables.isNotEmpty);

  /// « Selectionner les N resultats » de la vue « Candidats ».
  Future<void> _retenirTous(
    Map<String, String> filtres,
    String recherche,
  ) async {
    final PortCandidaturesDirection? port = ref.read(
      portCandidaturesDirectionProvider,
    );
    if (port == null) return;
    final String cle = _cleDeListe(requete);
    await retenirTousLesResultats<LigneEnseignant>(
      selection: _lot,
      port: port,
      filtre: filtreCandidatsDe(filtres, recherche),
      tri: triCandidatsDe(requete[cleTriPersonnes]),
      // La liste a change pendant la lecture : la reponse ne vaut plus.
      encoreCourant: () => _cleDeListe(requete) == cle,
      maj: setState,
      monte: () => mounted,
    );
  }

  /// Le menu « ... » d'un dossier (candidat ou enseignant) : « Ouvrir le
  /// dossier », les gestes que le serveur permet (ceux des anciennes listes),
  /// puis ceux de son compte quand il en a un (ville, coche « fondateur »,
  /// suppression). Les gestes qui retirent en dernier.
  Widget _menuDossier(
    BuildContext contexte,
    LignePersonne l, {
    required CapacitesCandidatures capacites,
    required bool horsLigne,
    required VoidCallback relire,
    required VoidCallback ouvrir,
  }) {
    final LigneCandidature d = l.dossier!;
    // Hors ligne : seul le dossier s'ouvre, aucun geste n'est propose.
    final List<GesteCandidature> gestes = horsLigne
        ? const <GesteCandidature>[]
        : l.enseignant != null
        ? gestesDuMenuEnseignant(l.enseignant!)
        : gestesDuMenuLigne(d, capacites);
    final CompteAdmin? c = _compteParReference[d.reference];
    final List<EntreeAction> duCompte = c == null || horsLigne
        ? const <EntreeAction>[]
        : _gestesCompte(contexte, c, VueComptes.enseignants, dossier: false);
    EntreeAction entree(GesteCandidature g) => EntreeAction(
      libelle: libelleGeste(g),
      icone: iconeDuGeste(g),
      destructif: g.destructif,
      onChoix: () =>
          unawaited(jouerGesteDeLigne(d, g, capacites, relire: relire)),
    );
    return MenuActions(
      key: PersonnesPage.cleMenuLigne(l.cle),
      points: true,
      objet: l.nom,
      actions: <EntreeAction>[
        EntreeAction(
          libelle: t.admin.candidatures.liste.ouvrirDossier,
          icone: AppIcons.dossiers,
          onChoix: ouvrir,
        ),
        for (final GesteCandidature g in gestes)
          if (!g.destructif) entree(g),
        ...duCompte.where((EntreeAction g) => !g.destructif),
        for (final GesteCandidature g in gestes)
          if (g.destructif) entree(g),
        ...duCompte.where((EntreeAction g) => g.destructif),
      ],
    );
  }

  Widget _contenu(
    BuildContext context,
    WidgetRef ref, {
    required Widget onglets,
    required bool coteACote,
    required List<LignePersonne> lignes,
    required String vide,
    required VoidCallback relire,
    Widget? pied,
    int decalage = 0,
    int? total,
  }) {
    final CapacitesCandidatures caps =
        ref.watch(capacitesCandidaturesProvider).value ??
        CapacitesCandidatures.aucune;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final bool suppressionOfferte =
        DataCollection.enTableau(context) ||
        !AppMetriques.of(context).estEnfant;
    // La case n'existe que si une operation groupee peut aboutir (LISTES-1) :
    // un lot que le serveur ouvre, ou une suppression.
    final bool lot = caps.peutAgirEnLot && lignes.any(_retenable);
    final bool suppression =
        suppressionOfferte &&
        lignes.any(
          (LignePersonne l) => l.compte != null && compteSupprimable(l.compte!),
        );
    final String? element = requete['element'];
    final int rang = lignes.indexWhere((LignePersonne l) => l.cle == element);
    final LignePersonne? choisie = rang < 0 ? null : lignes[rang];

    // Ouvre la page de la personne (dossier, piece, apercu en feuille).
    void toucherLigne(LignePersonne l) {
      if (l.piece case final DossierAValider d) {
        _ouvrirPiece(context, d);
      } else if (l.dossier case final LigneCandidature d) {
        _ouvrirDossier(context, d, phase: l.enseignant?.phase);
      } else if (l.compte case final CompteAdmin c) {
        unawaited(
          ouvrirApercuCompte(
            context,
            nom: l.nom,
            informations: informationsDuCompte(c, _onglet.vue!),
            // Les gestes du menu de la ligne, sauf celui qui efface (il reste
            // dans le menu « ... », avec sa confirmation).
            gestes: <EntreeAction>[
              for (final EntreeAction g in _gestesCompte(
                context,
                c,
                _onglet.vue!,
              ))
                if (!g.destructif) g,
            ],
          ),
        );
      }
    }

    void toucher(LignePersonne l) {
      if (coteACote) {
        _aller(context, element: l.cle, sansHistorique: true);
      } else {
        toucherLigne(l);
      }
    }

    final Widget liste = lignes.isEmpty
        ? EmptyState(
            message: vide,
            registre: RegistreVide.subi,
            icone: AppIcons.rienAAfficher,
          )
        : DataCollection<LignePersonne>(
            key: PersonnesPage.cleListe,
            lignes: lignes,
            cle: (LignePersonne l) => ValueKey<String>(l.cle),
            // Rendu par tranches (LISTES-2) : des lignes, jamais de grandes
            // cartes ; table quand les colonnes tiennent, lignes denses sinon.
            // La collection porte les onglets (ils defilent avec elle) et son
            // propre defilement.
            tete: coteACote ? const SizedBox.shrink() : onglets,
            densiteTelephone: true,
            lignesCartes: true,
            onSelectionner: toucher,
            estSelectionnee: coteACote
                ? (LignePersonne l) => l.cle == element
                : null,
            piedCollant: pied,
            // Etape (f) point 2 : la case de chaque ligne qu'une operation
            // groupee peut prendre (jamais une case grisee).
            selection: lot || suppression
                ? SelectionCollection<LignePersonne>(
                    estCochee: (LignePersonne l) => l.compte != null
                        ? _choisis.containsKey(l.compte!.profilId)
                        : l.dossier != null && _lot.contient(l.dossier!.id),
                    estCochable: (LignePersonne l) => l.compte != null
                        ? suppression && compteSupprimable(l.compte!)
                        : lot && _retenable(l),
                    onBasculer: (LignePersonne l) => setState(() {
                      if (l.compte case final CompteAdmin c) {
                        _bilan = null;
                        if (_choisis.remove(c.profilId) == null) {
                          _choisis[c.profilId] = c;
                        }
                      } else {
                        retourLigne = null;
                        _lot.basculer(l.dossier!.id, l.enseignant);
                      }
                    }),
                    // « Cocher la page » : la page visible seulement.
                    onBasculerPage: (bool cocher) => setState(() {
                      for (final LignePersonne l in lignes) {
                        if (l.compte case final CompteAdmin c) {
                          if (!suppression || !compteSupprimable(c)) continue;
                          _bilan = null;
                          if (cocher) {
                            _choisis[c.profilId] = c;
                          } else {
                            _choisis.remove(c.profilId);
                          }
                        } else if (lot && _retenable(l)) {
                          if (cocher) {
                            _lot.retenir(l.dossier!.id, l.enseignant);
                          } else {
                            _lot.relacher(l.dossier!.id);
                          }
                        }
                      }
                      _lot.oublierTous();
                    }),
                    libelleLigne: (LignePersonne l) => l.nom,
                  )
                : null,
            // Etape (f) : le menu d'actions en fin de ligne, hors de la cible
            // de la ligne (la ligne entiere reste cliquable). Une seule
            // colonne, jugee sur toute la liste. Un dossier (candidat,
            // enseignant) a toujours « Ouvrir le dossier ».
            actionsLigne:
                lignes.any(
                  (LignePersonne l) =>
                      (l.dossier != null && l.piece == null) ||
                      (l.compte != null &&
                          _gestesCompte(
                            context,
                            l.compte!,
                            _onglet.vue!,
                          ).isNotEmpty),
                )
                ? (BuildContext contexte, LignePersonne l) {
                    if (l.dossier != null && l.piece == null) {
                      return _menuDossier(
                        contexte,
                        l,
                        capacites: caps,
                        horsLigne: horsLigne,
                        relire: relire,
                        ouvrir: () => toucherLigne(l),
                      );
                    }
                    final List<EntreeAction> gestes = l.compte == null
                        ? const <EntreeAction>[]
                        : _gestesCompte(contexte, l.compte!, _onglet.vue!);
                    return gestes.isEmpty
                        ? const SizedBox.shrink()
                        : MenuActions(
                            points: true,
                            objet: l.nom,
                            actions: gestes,
                          );
                  }
                : null,
            colonnes: <ColonneDonnees<LignePersonne>>[
              ColonneDonnees<LignePersonne>(
                titre: t.admin.comptes.colonnePersonne,
                role: RoleColonne.identifiante,
                flex: 3,
                texte: (LignePersonne l) => l.nom,
                rendu: DataCollection.enTableau(context)
                    ? (BuildContext _, LignePersonne l) => AvatarNom.enLigne(
                        prenom: l.prenom,
                        avatar: PhotoEleve(
                          prenom: l.prenom,
                          cleAvatar: null,
                          personneId: l.profilId,
                          diametre: AppAvatar.petit,
                        ),
                        nom: l.nom,
                        diametre: AppAvatar.petit,
                        roleWidget: l.etat == null
                            ? null
                            : StatusPill(libelle: l.etat!, ton: l.ton),
                      )
                    : null,
              ),
              if (!DataCollection.enTableau(context))
                ColonneDonnees<LignePersonne>(
                  titre: t.admin.comptes.colonneEtat,
                  texte: (LignePersonne l) => l.etat ?? '',
                  rendu: (BuildContext _, LignePersonne l) => l.etat == null
                      ? const SizedBox.shrink()
                      : StatusPill(libelle: l.etat!, ton: l.ton),
                ),
              ColonneDonnees<LignePersonne>(
                titre: switch (_onglet) {
                  OngletPersonnes.eleves => t.admin.comptes.colonneClasse,
                  OngletPersonnes.familles =>
                    t.admin.comptes.colonneElevesRattaches,
                  OngletPersonnes.enseignants => switch (_vue) {
                    VueEnseignants.candidats => t.recrutement.file.salle,
                    VueEnseignants.pieces => t.admin.comptes.colonneAttente,
                    _ => t.admin.listeEnseignants.colonnes.attend,
                  },
                  OngletPersonnes.equipe => t.admin.comptes.colonneRole,
                },
                flex: 2,
                texte: (LignePersonne l) => l.colonne,
              ),
            ],
          );

    if (!coteACote) {
      // Une liste vide n'a pas de collection : les onglets restent au-dessus.
      return lignes.isEmpty
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[onglets, liste],
              ),
            )
          : liste;
    }

    // Le voisin suivant se lit pendant qu'on regarde celui-ci.
    final LignePersonne? suivante = rang >= 0 && rang + 1 < lignes.length
        ? lignes[rang + 1]
        : null;
    final String? aPrecharger = suivante?.dossier?.id;

    void voisin(int pas) {
      if (lignes.isEmpty) return;
      final int cible = (rang < 0 ? 0 : rang + pas).clamp(0, lignes.length - 1);
      if (cible != rang) {
        _aller(context, element: lignes[cible].cle, sansHistorique: true);
      }
    }

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => voisin(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => voisin(-1),
      },
      child: Focus(
        autofocus: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Les onglets sur toute la largeur : les quatre restent visibles.
            onglets,
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext _, BoxConstraints c) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: c.maxWidth * _partListe,
                      child: lignes.isEmpty
                          ? SingleChildScrollView(child: liste)
                          : liste,
                    ),
                    Ecart.hLg,
                    Expanded(
                      child: SingleChildScrollView(
                        key: PersonnesPage.cleApercu,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (choisie != null) ...<Widget>[
                              // Precedent / suivant, sans revenir a la liste.
                              BarrePrecedentSuivant(
                                key: PersonnesPage.cleVoisins,
                                position: t.recrutement.suivant.position(
                                  rang: decalage + rang + 1,
                                  total: total ?? lignes.length,
                                ),
                                libellePrecedent:
                                    t.admin.personnesPage.precedente,
                                libelleSuivant: t.admin.personnesPage.suivante,
                                onPrecedent: rang > 0 ? () => voisin(-1) : null,
                                onSuivant: rang + 1 < lignes.length
                                    ? () => voisin(1)
                                    : null,
                              ),
                              Ecart.vMd,
                            ],
                            _apercu(
                              context,
                              choisie,
                              relire,
                              ouvrir: choisie == null
                                  ? null
                                  : () => toucherLigne(choisie),
                              suivant: rang >= 0 && rang + 1 < lignes.length
                                  ? () => voisin(1)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (aPrecharger != null)
                      Consumer(
                        builder: (BuildContext _, WidgetRef r, Widget? _) {
                          r.watch(apercuCandidatureProvider(aPrecharger));
                          return const SizedBox.shrink();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ouvre la verification de la piece : dans le dossier de candidature quand
  /// le compte en a un (la piece s'y decide), sinon dans « Dossiers a
  /// valider ».
  void _ouvrirPiece(BuildContext context, DossierAValider d) {
    final String? reference = d.candidatureReference;
    final String? id = d.candidatureId;
    if (reference != null && id != null && referenceDossierValide(reference)) {
      _ouvrir(context, Routes.adminPersonnesCandidaturePour(reference), id);
    } else {
      _ouvrir(context, Routes.adminPersonnesDossiers, d.profilId);
    }
  }

  Widget _apercu(
    BuildContext context,
    LignePersonne? l,
    VoidCallback relire, {
    VoidCallback? ouvrir,
    VoidCallback? suivant,
  }) {
    final p = t.admin.personnesPage;
    if (l == null) {
      return EmptyState(
        message: p.apercuVide,
        registre: RegistreVide.subi,
        icone: AppIcons.profil,
      );
    }
    if (l.piece case final DossierAValider d) {
      final k = t.admin.comptes;
      final int jours = d.joursDAttente(DateTime.now());
      return AppCard(
        key: ValueKey<String>('apercu-${l.cle}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AvatarNom.enLigne(
              prenom: l.prenom,
              avatar: PhotoEleve(
                prenom: l.prenom,
                cleAvatar: null,
                personneId: l.profilId,
                diametre: AppAvatar.moyen,
              ),
              nom: l.nom,
              diametre: AppAvatar.moyen,
              roleWidget: l.etat == null
                  ? null
                  : StatusPill(libelle: l.etat!, ton: l.ton),
            ),
            Ecart.vLg,
            if (d.identifiantImmuable.isNotEmpty)
              LigneCleValeur(
                cle: k.colonneIdentifiant,
                valeur: identifiantInsecable(d.identifiantImmuable),
              ),
            LigneCleValeur(cle: k.colonnePiece, valeur: _libellePiece(d)),
            LigneCleValeur(
              cle: k.colonneAttente,
              valeur: switch (jours) {
                0 => k.attendAujourdhui,
                1 => k.attendUnJour,
                _ => k.attendJours(jours: jours),
              },
            ),
            Ecart.vMd,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: LienFleche(
                key: PersonnesPage.cleVerifierPiece,
                libelle: p.verifierPiece,
                alignerEnDebut: true,
                onPress: ouvrir ?? () {},
              ),
            ),
          ],
        ),
      );
    }
    if (l.dossier case final LigneCandidature d) {
      return AppCard(
        // Une cle par dossier : l'apercu du voisin ne garde rien du precedent.
        key: ValueKey<String>('apercu-${d.id}'),
        child: ApercuCandidatPersonnes(
          ligne: d,
          onOuvrirDossier: ouvrir ?? () {},
          onChange: relire,
          onSuivant: suivant,
        ),
      );
    }
    final CompteAdmin c = l.compte!;
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      key: ValueKey<String>('apercu-${l.cle}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AvatarNom.enLigne(
            prenom: l.prenom,
            avatar: PhotoEleve(
              prenom: l.prenom,
              cleAvatar: null,
              personneId: l.profilId,
              diametre: AppAvatar.moyen,
            ),
            nom: l.nom,
            diametre: AppAvatar.moyen,
            roleWidget: l.etat == null
                ? null
                : StatusPill(libelle: l.etat!, ton: l.ton),
          ),
          Ecart.vLg,
          for (final InformationCompte i in informationsDuCompte(
            c,
            _onglet.vue!,
          ))
            if (i.valeur.trim().isNotEmpty)
              LigneCleValeur(cle: i.titre, valeur: i.valeur),
          if (c.admissionATraiter) ...<Widget>[
            Ecart.vMd,
            Text(
              p.demandeATraiter,
              style: AppPalette.of(context).inkMuted
                  .applyTo(textes.bodyMedium ?? const TextStyle()),
            ),
          ],
          // Etape (f) : les gestes du compte, ceux du menu de sa ligne, sauf
          // celui qui efface. Jamais de bouton plein : l'apercu informe
          // d'abord (K-56).
          for (final (int rang, EntreeAction g) in _gestesCompte(
            context,
            c,
            _onglet.vue!,
          ).where((EntreeAction g) => !g.destructif).indexed) ...<Widget>[
            if (rang == 0) Ecart.vLg else Ecart.vSm,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ActionPrincipale(
                key: cleGesteApercuCompte(rang),
                libelle: g.libelle,
                niveau: NiveauAction.secondaire,
                pleineLargeur: false,
                onPress: g.onChoix,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

LignePersonne _deEnseignant(LigneEnseignant l) => LignePersonne._(
  cle: l.dossier.reference,
  nom: nomAffiche(l.dossier),
  prenom: nomAffiche(l.dossier),
  profilId: null,
  colonne: motAttend(l) ?? '',
  etat: libellePhase(l.phase),
  ton: switch (l.phase) {
    PhaseEnseignant.enPoste || PhaseEnseignant.disponible => TonEtat.succes,
    PhaseEnseignant.accueil => TonEtat.accent,
    _ => TonEtat.neutre,
  },
  dossier: l.dossier,
  enseignant: l,
);

/// Une candidature de la vue « Candidats » : son etat en pastille (celui de la
/// file des candidatures), sa salle en colonne.
LignePersonne _deCandidat(LigneCandidature l) {
  final etat = etatAffiche(l);
  return LignePersonne._(
    cle: l.reference,
    nom: nomAffiche(l),
    prenom: nomAffiche(l),
    profilId: null,
    colonne: libelleSalle(l.etape) ?? '',
    etat: etat?.libelle,
    ton: etat?.ton ?? TonEtat.neutre,
    dossier: l,
  );
}

/// Les pieces de la vue : celles des enseignants (la file des pieces porte
/// aussi d'autres comptes, qui ont leur onglet).
List<DossierAValider> _piecesEnseignants(List<DossierAValider> tous) =>
    <DossierAValider>[
      for (final DossierAValider d in tous)
        if (d.role == AppRole.teacher) d,
    ];

/// Vrai quand [recherche] se lit dans le nom ou l'identifiant de [d].
bool _pieceCorrespond(DossierAValider d, String recherche) {
  final String q = recherche.trim().toLowerCase();
  return q.isEmpty ||
      d.libelle.toLowerCase().contains(q) ||
      d.identifiantImmuable.toLowerCase().contains(q) ||
      (d.candidatureReference ?? '').toLowerCase().contains(q);
}

String _libellePiece(DossierAValider d) => switch (d.etatPiece) {
  EtatPiece.aucune => t.admin.comptes.pieceAucune,
  EtatPiece.aVerifier => t.admin.comptes.pieceAVerifier,
  EtatPiece.validee => t.admin.comptes.pieceValidee,
  EtatPiece.refusee => t.admin.comptes.pieceRefusee,
  EtatPiece.nonVisible => t.admin.comptes.pieceNonVisible,
};

LignePersonne _dePiece(DossierAValider d) {
  final int jours = d.joursDAttente(DateTime.now());
  return LignePersonne._(
    // Le matricule, ou la reference du dossier : jamais un nom dans l'adresse.
    cle: d.identifiantImmuable.isNotEmpty
        ? d.identifiantImmuable
        : d.candidatureReference ?? d.profilId,
    nom: d.nomConnu ? d.libelle : identifiantInsecable(d.libelle),
    prenom: d.prenom,
    profilId: d.profilId,
    colonne: switch (jours) {
      0 => t.admin.comptes.attendAujourdhui,
      1 => t.admin.comptes.attendUnJour,
      _ => t.admin.comptes.attendJours(jours: jours),
    },
    etat: _libellePiece(d),
    ton: d.etatPiece == EtatPiece.aVerifier
        ? TonEtat.avertissement
        : TonEtat.neutre,
    piece: d,
  );
}

LignePersonne _deCompte(CompteAdmin c, VueComptes vue) {
  final EtatAffiche e = EtatAffiche.de(c);
  return LignePersonne._(
    cle: c.identifiant.isEmpty ? c.profilId : c.identifiant,
    nom: c.libelle == c.identifiant
        ? identifiantInsecable(c.identifiant)
        : c.libelle,
    prenom: c.prenom ?? '',
    profilId: c.profilId,
    colonne: switch (vue) {
      VueComptes.eleves => nomClasseEleve(c) ?? t.admin.comptes.classeAucune,
      VueComptes.familles => '${c.enfantsDuFoyer}',
      VueComptes.direction || VueComptes.enseignants => nomDuRole(c.role),
    },
    etat: e == EtatAffiche.actif ? null : libelleEtatAffiche(e),
    ton: switch (e) {
      EtatAffiche.attente => TonEtat.avertissement,
      EtatAffiche.suspendu => TonEtat.alerte,
      _ => TonEtat.neutre,
    },
    compte: c,
  );
}

/// Le mot d'un etat de compte.
String libelleEtatAffiche(EtatAffiche e) => switch (e) {
  EtatAffiche.attente => t.admin.comptes.etatEnAttente,
  EtatAffiche.sansDecision => t.admin.comptes.etatSansDecision,
  EtatAffiche.actif => t.admin.comptes.etatActif,
  EtatAffiche.provisoire => t.admin.comptes.etatProvisoire,
  EtatAffiche.suspendu => t.admin.comptes.etatSuspendu,
  EtatAffiche.inconnu => t.admin.comptes.etatInconnu,
};

/// Le nom d'un role, pour la direction.
String nomDuRole(AppRole? role) => switch (role) {
  null => t.admin.comptes.roleInconnu,
  AppRole.admin => t.admin.comptes.roleAdmin,
  AppRole.accountant => t.admin.comptes.roleComptable,
  AppRole.controller => t.admin.comptes.roleControleur,
  AppRole.teacher => t.admin.comptes.roleEnseignant,
  AppRole.guardian => t.admin.comptes.roleTuteur,
  AppRole.student => t.admin.comptes.roleEleve,
  AppRole.associe => t.admin.comptes.roleAssocie,
};

/// Ce que l'apercu d'un compte dit, par onglet : bref, sans donnee de contact.
List<InformationCompte> informationsDuCompte(CompteAdmin c, VueComptes vue) {
  final k = t.admin.comptes;
  final int jours = c.joursDAttente(DateTime.now());
  return <InformationCompte>[
    (titre: k.colonneIdentifiant, valeur: identifiantInsecable(c.identifiant)),
    if (vue == VueComptes.eleves) ...<InformationCompte>[
      (
        titre: k.colonneTranche,
        valeur: switch (c.tranche) {
          TrancheAge.enfant => k.trancheEnfant,
          TrancheAge.adulte => k.trancheAdulte,
          null => k.trancheInconnue,
        },
      ),
      (titre: k.colonneClasse, valeur: nomClasseEleve(c) ?? k.classeAucune),
      (titre: k.colonneTuteur, valeur: c.tuteurLibelle ?? k.tuteurAucun),
    ],
    if (vue == VueComptes.familles)
      (titre: k.colonneElevesRattaches, valeur: '${c.enfantsDuFoyer}'),
    if (vue == VueComptes.direction)
      (titre: k.colonneRole, valeur: nomDuRole(c.role)),
    (titre: k.colonneEtat, valeur: libelleEtatAffiche(EtatAffiche.de(c))),
    (
      titre: k.colonneAttente,
      valeur: switch (jours) {
        0 => k.attendAujourdhui,
        1 => k.attendUnJour,
        _ => k.attendJours(jours: jours),
      },
    ),
  ];
}
