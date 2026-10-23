/// `ADM-20` : la file des candidatures de la direction, sous Personnes.
///
/// Elle remplace l'onglet Invitations de Personnes (`DEC:27` : pas de septieme
/// onglet) sans casser les invitations existantes : la page des invitations
/// reste atteignable par un lien (`CAND-F01`), en tete de page.
///
/// **List-first (LISTES-1, 23/10/2026)** : le contenu metier est la priorite
/// visuelle. De haut en bas : l'en-tete (titre et « Invitations »), la
/// navigation de Personnes, **une seule barre de commandes** (la recherche, les
/// deux filtres les plus employes, « Plus » pour tous les autres), les filtres
/// en cours (retirables, seulement s'il y en a), **une synthese sur une ligne**
/// (le compteur et les alertes que le serveur sert), puis **le tableau
/// aussitot**, son en-tete de colonnes colle, et le pied de liste. A 1440 x 900
/// avec la coquille, dix lignes ou plus tiennent avant le premier defilement
/// (il en tenait deux).
///
/// **Tout vient du serveur, rien n'est recalcule ici** : la portee de genre (une
/// candidature hors portee n'apparait ni dans la liste ni dans un compteur), le
/// filtre, le tri, la pagination de 50, le total reel du filtre, les compteurs
/// d'etapes et les alertes. L'ecran lit ces champs. Les droits (gestes,
/// traitement groupe, exception de lecture du super-admin) sont des capacites
/// lues au serveur (`capacites_candidatures`), jamais un role.
///
/// **Ce que le serveur sert aujourd'hui, et rien de plus** : le tri par derniere
/// activite, par date de reception et par nom ; les filtres etape (salle), etat,
/// issue, pause, versement, pays de residence et autres competences ; la
/// recherche (nom, reference et courriel entiers). Ce que la fiche prevoit
/// au-dela (date d'entretien, responsable, besoin ouvert, provenance, alerte
/// posee en filtre, etat du courriel) n'est pas rendu : un controle qui ne peut
/// pas aboutir n'est pas affiche. La **taille de page est celle du serveur** (50,
/// en dur) : le pied la dit, il n'offre pas de choix qu'il ne tient pas.
///
/// **Une ligne, trois cibles** : la case (retenir), la ligne (ouvrir le dossier)
/// et le menu « ... » (« Ouvrir le dossier » et les gestes que l'etat de la
/// ligne permet, par la meme table que la fiche). Le geste d'une ligne lit le
/// dossier, recalcule ce qui est permis, puis ouvre la meme feuille que la
/// fiche ; apres succes, la liste se relit **en gardant recherche, filtres, tri
/// et page**.
///
/// **Traitement groupe** : une case par ligne et « cocher la page » ; le compte
/// est dit, la selection est **gardee d'une page a l'autre** (plafond 200) et
/// **retiree, avec un message, quand la recherche ou un filtre change**. La
/// barre compacte (au moins une candidature retenue) offre ce que le serveur
/// sait grouper : mettre en pause, lever la pause, refuser ; elle dit que les
/// autres gestes se font un par un. Le parcours est celui de `lot_candidatures.dart`.
///
/// Etats : chargement (squelette de table), contenu, vide, aucun resultat
/// (filtres rappeles, « Tout effacer »), erreur (« Reessayer »), hors ligne
/// (bandeau de `PageShell`, la derniere lecture reste, le menu ne propose que le
/// dossier, `EtatSansDonnees` quand rien n'a pu etre lu), capacite indisponible,
/// acces refuse, genre du lecteur inconnu, exception du super-admin.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/admin/admin_domaine.dart';
import '../../core/candidature/gestes_candidature.dart';
import '../../core/candidature/modeles_autres_competences.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidature_detail.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/modeles_lot_candidatures.dart';
import '../../core/candidature/port_autres_competences.dart';
import '../../core/candidature/port_candidatures_direction.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/i18n/pays_iso.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/recrutement/port_invitations_comptable.dart';
import '../../core/recrutement/port_invitations_enseignant.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/barre_selection.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/chargement_avec_delais.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/menu_commun.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pied_de_liste.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/puce_filtre_actif.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../admin_candidature/feuille_geste.dart';
import '../admin_candidature/gestes_proposes.dart';
import '../admin_candidature/libelles_candidature.dart';
import '../talents/libelles_talents.dart';
import 'libelles_candidatures.dart';
import 'ligne_candidature.dart';
import 'lot_candidatures.dart';
import 'menu_ligne_candidature.dart';
import 'synthese_candidatures.dart';

/// L'ecran « Candidatures ».
class CandidaturesPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  ///
  /// [ouvrirCandidature] mene au detail d'une candidature (`ADM-21`). Tant que
  /// sa destination n'est pas donnee, la ligne n'est pas pressable et le menu
  /// ne propose pas « Ouvrir le dossier ». Le traitement groupe n'a pas de
  /// destination : la page le porte elle-meme (`lot_candidatures.dart`), des
  /// que le serveur l'ouvre (`agirEnLot`). Aucune destination n'est inventee.
  const CandidaturesPage({super.key, this.ouvrirCandidature});

  /// Ouvre une candidature, ou `null` : la ligne ne s'ouvre pas.
  final void Function(LigneCandidature ligne)? ouvrirCandidature;

  /// La cle de la page.
  static const Key clePage = ValueKey<String>('candidatures-page');

  /// La cle de la barre de commandes.
  static const Key cleCommandes = ValueKey<String>('candidatures-commandes');

  /// La cle du pied de liste (avec la mention de la taille de page).
  static const Key clePied = ValueKey<String>('candidatures-pied');

  /// La cle de la barre du traitement groupe.
  static const Key cleBarreLot = ValueKey<String>('candidatures-barre-lot');

  /// La cle de l'operation de lot [geste].
  static Key cleOperationLot(GesteLot geste) =>
      ValueKey<String>('candidatures-lot-${geste.valeurSql}');

  /// La cle du message de selection (retiree, plafond).
  static const Key cleMessageSelection = ValueKey<String>(
    'candidatures-message-selection',
  );

  /// La cle de la ligne « lecture du dossier ».
  static const Key cleOuverture = ValueKey<String>('candidatures-ouverture');

  @override
  ConsumerState<CandidaturesPage> createState() => _CandidaturesPageEtat();
}

class _CandidaturesPageEtat extends ConsumerState<CandidaturesPage> {
  /// Le filtre courant : recherche, etape, etat, issue, pause, versement, pays.
  FiltreCandidatures _filtre = const FiltreCandidatures();

  /// Le tri, fait au serveur.
  TriCandidatures _tri = TriCandidatures.activite;

  /// La page courante, a partir de 1. Revient a 1 a chaque changement de
  /// filtre ou de tri.
  int _page = 1;

  /// La derniere page lue : ses compteurs (toute la portee, sans les autres
  /// filtres) restent affiches pendant qu'une autre page se charge.
  PageCandidatures? _derniere;

  final TextEditingController _recherche = TextEditingController();
  final GlobalKey _cleListe = GlobalKey(debugLabel: 'candidatures-liste');

  /// L'attente qui suit la derniere frappe : une page n'est demandee qu'une
  /// fois la saisie posee. Ce n'est pas un mouvement (aucune animation), donc
  /// pas un jeton d'`AppMouvement`.
  Timer? _attenteSaisie;

  static const Duration _delaiSaisie = Duration(
    microseconds: 300 * Duration.microsecondsPerMillisecond,
  );

  /// Les identifiants retenus, gardes d'une page a l'autre (200 au plus).
  final Set<String> _retenues = <String>{};

  /// Ce que la page dit de la selection : retiree (recherche ou filtre change)
  /// ou plafond atteint. Efface a la prochaine action de selection.
  String? _messageSelection;

  /// Le nom de la personne dont le dossier se lit pour un geste de ligne.
  String? _ouverture;

  /// Le geste d'une ligne qui n'a pas pu partir : dossier illisible, geste plus
  /// possible. Rien n'a ete fait.
  String? _echecLigne;

  /// Le retour du dernier geste : dit seulement apres la reponse du serveur.
  String? _retour;

  @override
  void dispose() {
    _attenteSaisie?.cancel();
    _recherche.dispose();
    super.dispose();
  }

  void _chercher(String texte) {
    _attenteSaisie?.cancel();
    _attenteSaisie = Timer(_delaiSaisie, () {
      if (mounted) _filtrer(_filtre.avec(recherche: texte));
    });
  }

  void _chercherTout(String texte) {
    _attenteSaisie?.cancel();
    _filtrer(_filtre.avec(recherche: texte));
  }

  /// Pose un filtre. La selection **ne survit pas** a un filtre ou une
  /// recherche qui change : des candidatures retenues hors de vue seraient une
  /// selection silencieuse. Elle est retiree, et la page le dit.
  ///
  /// Un filtre **egal** a l'actuel (la comparaison est celle de la requete : le
  /// blanc de bord d'une recherche n'en change pas) ne fait rien : ni selection
  /// retiree, ni retour a la premiere page.
  void _filtrer(FiltreCandidatures filtre) {
    if (filtre == _filtre) return;
    _poser(filtre);
  }

  void _poser(FiltreCandidatures filtre) => setState(() {
    if (_retenues.isNotEmpty) {
      _retenues.clear();
      _messageSelection = t.admin.candidatures.lot.selectionRetiree;
    }
    _filtre = filtre;
    _page = 1;
  });

  void _effacer() {
    _attenteSaisie?.cancel();
    _recherche.clear();
    _filtrer(_filtre.efface);
  }

  void _relire() => ref
    ..invalidate(pageCandidaturesProvider)
    ..invalidate(capacitesCandidaturesProvider);

  void _allerAPage(int numero) {
    setState(() => _page = numero);
    // Une nouvelle page commence en haut de la liste, pas au pied de la
    // precedente.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      final BuildContext? c = _cleListe.currentContext;
      if (mounted && c != null && c.mounted) {
        unawaited(Scrollable.ensureVisible(c));
      }
    });
  }

  // --- Selection ----------------------------------------------------------

  void _basculerLigne(LigneCandidature ligne) => setState(() {
    if (_retenues.remove(ligne.id)) {
      _messageSelection = null;
    } else if (_retenues.length >= plafondLotCandidatures) {
      _messageSelection = t.admin.candidatures.lot.plafond(
        n: plafondLotCandidatures,
      );
    } else {
      _retenues.add(ligne.id);
      _messageSelection = null;
    }
  });

  /// Coche ou vide **la page visible**, jamais « tous les resultats » du
  /// filtre. Au plafond, la page n'est cochee qu'en partie, et la page le dit.
  void _basculerPage(List<LigneCandidature> lignes, bool cocher) =>
      setState(() {
        _messageSelection = null;
        if (!cocher) {
          _retenues.removeAll(lignes.map((LigneCandidature l) => l.id));
          return;
        }
        for (final LigneCandidature l in lignes) {
          if (_retenues.contains(l.id)) continue;
          if (_retenues.length >= plafondLotCandidatures) {
            _messageSelection = t.admin.candidatures.lot.plafond(
              n: plafondLotCandidatures,
            );
            break;
          }
          _retenues.add(l.id);
        }
      });

  void _relacherTout() => setState(() {
    _retenues.clear();
    _messageSelection = null;
  });

  // --- Un geste depuis une ligne -----------------------------------------

  /// Le geste d'une ligne : lire le dossier (la ligne n'en porte ni la version
  /// ni les reponses), rappeler la table des gestes sur ce qu'on vient de lire,
  /// puis ouvrir **la meme feuille** que la fiche. Rien n'est fait si le geste
  /// n'est plus permis.
  Future<void> _gesteDeLigne(
    LigneCandidature ligne,
    GesteCandidature geste,
    CapacitesCandidatures capacites,
  ) async {
    if (_ouverture != null) return;
    final DemandeDossier demande = DemandeDossier(
      ligne.reference,
      id: ligne.id,
    );
    setState(() {
      _ouverture = nomAffiche(ligne);
      _echecLigne = null;
      _retour = null;
    });
    // Une lecture neuve : la version lue est celle d'aujourd'hui, jamais celle
    // d'un dossier garde en memoire.
    ref.invalidate(detailCandidatureProvider(demande));
    final ProviderSubscription<AsyncValue<DetailCandidature>> garde = ref
        .listenManual(
          detailCandidatureProvider(demande),
          (
            AsyncValue<DetailCandidature>? _,
            AsyncValue<DetailCandidature> _,
          ) {},
        );
    DetailCandidature? detail;
    try {
      detail = await ref.read(detailCandidatureProvider(demande).future);
    } on Object {
      detail = null;
    } finally {
      garde.close();
    }
    if (!mounted) return;
    final r = t.admin.candidatures.liste;
    if (detail == null) {
      setState(() {
        _ouverture = null;
        _echecLigne = r.dossierIllisible;
      });
      return;
    }
    setState(() => _ouverture = null);
    if (!gestePermis(geste, detail)) {
      setState(
        () => _echecLigne = r.gestePlusPossible(
          etat: libelleEtatCourant(
            issue: detail!.ligne.issue,
            enPause: detail.ligne.enPause,
            etape: detail.ligne.etape,
            etat: detail.ligne.etat,
          ),
        ),
      );
      // La ligne a change depuis la derniere lecture : la liste se relit.
      _relire();
      return;
    }
    final SortieFeuille? sortie = await ouvrirFeuilleGeste(
      context,
      geste: geste,
      detail: detail,
      capacites: capacites,
    );
    if (!mounted || sortie == null) return;
    // Recherche, filtres, tri et page sont dans l'etat de cette page : la
    // relecture les garde.
    _relire();
    // Un geste fait sur une ligne **retenue** la retire de la selection : son
    // etat vient de changer, la garder cochee serait une selection qui ne dit
    // plus ce qu'elle retient (relecture du code R-6).
    if (sortie.issue == IssueFeuille.fait) _retenues.remove(ligne.id);
    setState(
      () => _retour = sortie.issue == IssueFeuille.fait
          ? r.retourLigne(
              nom: nomAffiche(ligne),
              retour: sortie.rejoue
                  ? t.admin.candidatures.retours.rejoue
                  : libelleRetour(geste),
            )
          : null,
    );
  }

  // --- Le traitement groupe ----------------------------------------------

  Future<void> _lancerLot(GesteLot geste, CapacitesCandidatures caps) async {
    await ouvrirFeuilleLot(
      context,
      geste: geste,
      ids: _retenues.toList(),
      capacites: caps,
      onRapport: _apresLot,
    );
  }

  /// Le serveur a rendu son rapport : la liste se relit (filtres, tri et page
  /// gardes) et la selection est videe, que la feuille soit encore ouverte ou
  /// non.
  void _apresLot(RapportLot rapport) {
    if (!mounted) return;
    _relire();
    setState(() {
      _retenues.clear();
      _messageSelection = null;
      _retour = rapport.rejoue
          ? t.admin.candidatures.lot.feuille.rapport.rejoue
          : t.admin.candidatures.lot.feuille.rapport.reussies(
              n: rapport.reussies,
            );
    });
  }

  // --- Filtres ------------------------------------------------------------

  EntreeFiltre<T> _tous<T>({String? libelle}) => EntreeFiltre<T>(
    valeur: null,
    libelle: libelle ?? t.admin.candidatures.filtres.tous,
  );

  /// Les deux filtres les plus employes, puis tous les autres (sous « Plus »).
  List<Widget> _filtres(
    PageCandidatures reference,
    CapacitesCandidatures caps,
  ) {
    final f = t.admin.candidatures.filtres;
    final l = t.admin.candidatures.liste;

    EntreeFiltre<EtapeCandidature> salle(EtapeCandidature e, String libelle) {
      final int? n = reference.compteursEtapes[e];
      // Le compteur est celui des candidatures en cours de toute la portee, pas
      // celui de la liste filtree : l'entree retenue, que la puce reprend comme
      // libelle, ne le porte pas (elle dirait « 4 » au-dessus d'une liste de 6).
      return EntreeFiltre<EtapeCandidature>(
        valeur: e,
        libelle: n == null || _filtre.etape == e
            ? libelle
            : l.avecCompteur(libelle: libelle, n: n),
      );
    }

    final List<PaysIso> pays = <PaysIso>[...paysIso]
      ..sort(
        (PaysIso a, PaysIso b) =>
            formeDeRecherche(a.nom).compareTo(formeDeRecherche(b.nom)),
      );

    return <Widget>[
      MenuFiltre<EtatCandidature>(
        key: const ValueKey<String>('candidatures-filtre-etat'),
        libelle: f.etat,
        valeur: _filtre.etat,
        entrees: <EntreeFiltre<EtatCandidature>>[
          _tous<EtatCandidature>(),
          for (final EtatCandidature e in EtatCandidature.values)
            EntreeFiltre<EtatCandidature>(valeur: e, libelle: libelleEtat(e)),
        ],
        onChoix: (EtatCandidature? e) => _filtrer(_filtre.avec(etat: () => e)),
      ),
      // Les salles : l'ancienne rangee de puces (« Toutes », « Invitees »,
      // « Salle d'examen »...) devient un seul menu, compteurs compris.
      MenuFiltre<EtapeCandidature>(
        key: const ValueKey<String>('candidatures-filtre-salle'),
        libelle: l.salle,
        valeur: _filtre.etape,
        entrees: <EntreeFiltre<EtapeCandidature>>[
          _tous<EtapeCandidature>(libelle: l.toutesSalles),
          // « Garder pour suivi » attend la reponse du directeur (CONS 0.3) :
          // tant que le serveur ne l'ouvre pas, ni l'entree ni le mot ne sont
          // rendus.
          if (caps.peutGarderPourSuivi)
            salle(EtapeCandidature.recue, f.gardees),
          salle(EtapeCandidature.invitee, f.invitees),
          salle(EtapeCandidature.prequalification, t.recrutement.salles.examen),
          salle(
            EtapeCandidature.verifications,
            t.recrutement.salles.verification,
          ),
          salle(EtapeCandidature.confirmee, t.recrutement.salles.prets),
        ],
        onChoix: (EtapeCandidature? e) =>
            _filtrer(_filtre.avec(etape: () => e)),
      ),
      MenuFiltre<IssueCandidature>(
        key: const ValueKey<String>('candidatures-filtre-issue'),
        libelle: f.issue,
        valeur: _filtre.issue,
        entrees: <EntreeFiltre<IssueCandidature>>[
          _tous<IssueCandidature>(),
          for (final IssueCandidature i in IssueCandidature.values)
            EntreeFiltre<IssueCandidature>(valeur: i, libelle: libelleIssue(i)),
        ],
        onChoix: (IssueCandidature? i) =>
            _filtrer(_filtre.avec(issue: () => i)),
      ),
      MenuFiltre<bool>(
        key: const ValueKey<String>('candidatures-filtre-pause'),
        libelle: f.pause,
        valeur: _filtre.enPause,
        entrees: <EntreeFiltre<bool>>[
          _tous<bool>(),
          EntreeFiltre<bool>(
            valeur: true,
            libelle: t.admin.candidatures.etats.enPause,
          ),
          EntreeFiltre<bool>(valeur: false, libelle: f.sansPause),
        ],
        onChoix: (bool? p) => _filtrer(_filtre.avec(enPause: () => p)),
      ),
      MenuFiltre<EtatVersement>(
        key: const ValueKey<String>('candidatures-filtre-versement'),
        libelle: f.versement,
        valeur: _filtre.paiement,
        entrees: <EntreeFiltre<EtatVersement>>[
          _tous<EtatVersement>(),
          for (final EtatVersement v in EtatVersement.values)
            EntreeFiltre<EtatVersement>(
              valeur: v,
              libelle: libelleVersement(v),
            ),
        ],
        onChoix: (EtatVersement? v) =>
            _filtrer(_filtre.avec(paiement: () => v)),
      ),
      MenuFiltre<String>(
        key: const ValueKey<String>('candidatures-filtre-pays'),
        libelle: f.pays,
        valeur: _filtre.paysResidence,
        entrees: <EntreeFiltre<String>>[
          _tous<String>(),
          for (final PaysIso p in pays)
            EntreeFiltre<String>(valeur: p.code, libelle: p.nom),
        ],
        onChoix: (String? p) => _filtrer(_filtre.avec(paysResidence: () => p)),
      ),
      ..._filtresCompetences(),
    ];
  }

  /// Les quatre axes des autres competences (CAND-07, « Vos autres talents ») :
  /// le domaine (une famille, ou une competence du catalogue), le niveau minimum,
  /// la disponibilite et l'accord d'etre contacte. Le serveur ne rend ces
  /// personnes que si elles ont repondu ; aucune note, aucun classement.
  ///
  /// Les familles sont une liste fermee que l'application nomme : le menu du
  /// domaine marche sans le catalogue. Les competences s'y ajoutent des que la
  /// direction lit le catalogue (le sien, complet, desactivees comprises).
  List<Widget> _filtresCompetences() {
    final f = t.admin.candidatures.filtres.talents;
    final CatalogueCompetences? catalogue = ref
        .watch(catalogueCompetencesProvider)
        .value;
    final List<EntreeFiltre<String>> domaines = <EntreeFiltre<String>>[
      _tous<String>(),
      for (final FamilleCompetence famille
          in FamilleCompetence.values) ...<EntreeFiltre<String>>[
        // La famille « autre » n'a qu'une competence, du meme nom : une seule
        // entree.
        if (famille != FamilleCompetence.autre)
          EntreeFiltre<String>(
            valeur: famille.valeurSql,
            libelle: f.familleToutes(famille: titreFamille(famille)),
          ),
        for (final EntreeCatalogue e
            in catalogue?.competences ?? const <EntreeCatalogue>[])
          if (e.familleCode == famille.valeurSql)
            EntreeFiltre<String>(
              valeur: e.code,
              libelle: nomDomaineFiltre(e.code, catalogue: catalogue),
            ),
      ],
    ];
    return <Widget>[
      MenuFiltre<String>(
        key: const ValueKey<String>('candidatures-filtre-competence'),
        libelle: f.domaine,
        valeur: _filtre.competenceDomaine,
        entrees: domaines,
        onChoix: (String? d) =>
            _filtrer(_filtre.avec(competenceDomaine: () => d)),
      ),
      MenuFiltre<NiveauCompetence>(
        key: const ValueKey<String>('candidatures-filtre-competence-niveau'),
        libelle: f.niveau,
        valeur: _filtre.competenceNiveauMin,
        entrees: <EntreeFiltre<NiveauCompetence>>[
          _tous<NiveauCompetence>(),
          EntreeFiltre<NiveauCompetence>(
            valeur: NiveauCompetence.experience,
            libelle: f.niveauExperience,
          ),
          EntreeFiltre<NiveauCompetence>(
            valeur: NiveauCompetence.metier,
            libelle: f.niveauMetier,
          ),
        ],
        onChoix: (NiveauCompetence? n) =>
            _filtrer(_filtre.avec(competenceNiveauMin: () => n)),
      ),
      MenuFiltre<DisponibiliteMission>(
        key: const ValueKey<String>(
          'candidatures-filtre-competence-disponibilite',
        ),
        libelle: f.disponibilite,
        valeur: _filtre.competenceDisponibilite,
        entrees: <EntreeFiltre<DisponibiliteMission>>[
          _tous<DisponibiliteMission>(),
          for (final DisponibiliteMission d in DisponibiliteMission.values)
            EntreeFiltre<DisponibiliteMission>(
              valeur: d,
              libelle: libelleDisponibilite(d),
            ),
        ],
        onChoix: (DisponibiliteMission? d) =>
            _filtrer(_filtre.avec(competenceDisponibilite: () => d)),
      ),
      MenuFiltre<bool>(
        key: const ValueKey<String>('candidatures-filtre-competence-accord'),
        libelle: f.accord,
        valeur: _filtre.competenceAccord,
        entrees: <EntreeFiltre<bool>>[
          _tous<bool>(),
          EntreeFiltre<bool>(valeur: true, libelle: f.accordDonne),
          EntreeFiltre<bool>(valeur: false, libelle: f.accordAbsent),
        ],
        onChoix: (bool? a) => _filtrer(_filtre.avec(competenceAccord: () => a)),
      ),
    ];
  }

  /// Les filtres en cours **que la barre ne montre pas deja**, chacun retirable
  /// seul. La recherche (son champ porte sa croix), la salle et l'etat (leur
  /// bouton dit la valeur retenue, et « Tous » la retire) n'ont pas de puce : la
  /// rangee de puces repetait ce que la barre disait deja et coutait une rangee
  /// de 60 points (relecture visuelle C-07). Restent les axes ranges sous
  /// « Plus », que rien d'autre ne montre.
  List<FiltreActif> _filtresActifs() {
    final f = t.admin.candidatures.filtres;
    final l = t.admin.candidatures.liste;
    String axe(String nom, String valeur) => l.axe(axe: nom, valeur: valeur);
    return <FiltreActif>[
      if (_filtre.issue != null)
        FiltreActif(
          libelle: axe(f.issue, libelleIssue(_filtre.issue!)),
          onRetirer: () => _filtrer(_filtre.avec(issue: () => null)),
        ),
      if (_filtre.enPause != null)
        FiltreActif(
          libelle: axe(
            f.pause,
            _filtre.enPause! ? t.admin.candidatures.etats.enPause : f.sansPause,
          ),
          onRetirer: () => _filtrer(_filtre.avec(enPause: () => null)),
        ),
      if (_filtre.paiement != null)
        FiltreActif(
          libelle: axe(f.versement, libelleVersement(_filtre.paiement!)),
          onRetirer: () => _filtrer(_filtre.avec(paiement: () => null)),
        ),
      if (_filtre.paysResidence != null)
        FiltreActif(
          libelle: axe(f.pays, libellePays(_filtre.paysResidence) ?? ''),
          onRetirer: () => _filtrer(_filtre.avec(paysResidence: () => null)),
        ),
      if (_filtre.competenceDomaine != null)
        FiltreActif(
          libelle: axe(
            f.talents.domaine,
            nomDomaineFiltre(_filtre.competenceDomaine!),
          ),
          onRetirer: () =>
              _filtrer(_filtre.avec(competenceDomaine: () => null)),
        ),
      if (_filtre.competenceNiveauMin != null)
        FiltreActif(
          libelle: axe(
            f.talents.niveau,
            _filtre.competenceNiveauMin == NiveauCompetence.metier
                ? f.talents.niveauMetier
                : f.talents.niveauExperience,
          ),
          onRetirer: () =>
              _filtrer(_filtre.avec(competenceNiveauMin: () => null)),
        ),
      if (_filtre.competenceDisponibilite != null)
        FiltreActif(
          libelle: axe(
            f.talents.disponibilite,
            libelleDisponibilite(_filtre.competenceDisponibilite!),
          ),
          onRetirer: () =>
              _filtrer(_filtre.avec(competenceDisponibilite: () => null)),
        ),
      if (_filtre.competenceAccord != null)
        FiltreActif(
          libelle: axe(
            f.talents.accord,
            _filtre.competenceAccord!
                ? f.talents.accordDonne
                : f.talents.accordAbsent,
          ),
          onRetirer: () => _filtrer(_filtre.avec(competenceAccord: () => null)),
        ),
    ];
  }

  // --- La barre de commandes ---------------------------------------------

  /// La largeur a partir de laquelle la recherche, les filtres et la synthese
  /// tiennent dans **une seule bande**. En dessous, la synthese passe sous les
  /// filtres.
  static const double _largeurUneBande = 1000;

  /// La largeur de la recherche quand elle partage la bande (son libelle court
  /// y tient).
  static const double _largeurRecherche = 300;

  /// La largeur la plus grande que prend la synthese dans la bande.
  static const double _largeurSynthese = 440;

  /// La barre de commandes : la recherche, les deux filtres les plus employes,
  /// « Plus », et, quand la largeur le permet, la synthese **dans la meme bande**
  /// (le compteur et les alertes a droite des filtres). Une bande de moins par
  /// ecran : c'est ce qui laisse dix lignes de tableau a 1440 x 900.
  Widget _barreCommandes(
    PageCandidatures reference,
    CapacitesCandidatures caps,
    int? total, {
    required bool triVisible,
  }) {
    final r = t.admin.candidatures;
    Widget recherche(String libelle) => ChampRecherche(
      cleChamp: const ValueKey<String>('candidatures-recherche'),
      cleEffacer: const ValueKey<String>('candidatures-recherche-effacer'),
      controleur: _recherche,
      libelle: libelle,
      aide: r.rechercheAide,
      onChange: _chercher,
      onValider: _chercherTout,
    );
    final Widget filtresSeuls = RangeeFiltres(
      visiblesMax: 2,
      filtres: _filtres(reference, caps),
    );
    Widget synthese(WrapAlignment alignement) => SyntheseCandidatures(
      total: total,
      compteurs: reference.compteursAlertes,
      alignement: alignement,
    );
    // En cartes, il n'y a pas d'en-tete de colonnes pour trier : le tri que le
    // serveur sert (derniere activite, reception, nom) se choisit dans un menu,
    // au bout de la rangee des filtres (il avait sa propre rangee de 60 points,
    // et la premiere carte commencait a 70 % de la hauteur).
    final Widget menuTri = _MenuTri(
      valeur: _tri,
      onChoix: (TriCandidatures choisi) => setState(() {
        _tri = choisi;
        _page = 1;
      }),
    );
    final Widget filtres = triVisible
        ? LayoutBuilder(
            builder: (BuildContext contexte, BoxConstraints c) {
              // Le texte agrandi ou un ecran de 320 : les filtres gardent toute
              // la largeur, le tri passe dessous au lieu de les ecraser.
              final bool cote =
                  c.maxWidth >= 340 &&
                  MediaQuery.textScalerOf(contexte).scale(1) <= 1.3;
              if (!cote) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    filtresSeuls,
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: menuTri,
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: filtresSeuls),
                  Ecart.hSm,
                  menuTri,
                ],
              );
            },
          )
        : filtresSeuls;
    final Widget bande = LayoutBuilder(
      key: CandidaturesPage.cleCommandes,
      builder: (BuildContext contexte, BoxConstraints c) {
        if (c.maxWidth >= _largeurUneBande) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: _largeurRecherche,
                child: recherche(r.rechercheAide),
              ),
              Ecart.hMd,
              Expanded(child: filtres),
              Ecart.hMd,
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _largeurSynthese),
                child: Padding(
                  // Centree sur la hauteur de la recherche (56), pas sur celle
                  // de la bande.
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: synthese(WrapAlignment.end),
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            recherche(r.rechercheAide),
            Ecart.vSm,
            filtres,
            Ecart.vSm,
            synthese(WrapAlignment.start),
          ],
        );
      },
    );
    return bande;
  }

  // --- La barre du traitement groupe -------------------------------------

  Widget _barreLot(
    PageCandidatures page,
    CapacitesCandidatures caps,
    bool horsLigne,
  ) {
    final l = t.admin.candidatures.lot;
    final int n = _retenues.length;
    final int surLaPage = page.lignes
        .where((LigneCandidature x) => _retenues.contains(x.id))
        .length;
    final String titre = surLaPage < n
        ? l.avecDont(
            selection: l.selectionnees(n: n),
            dont: l.dontPage(n: surLaPage),
          )
        : l.selectionnees(n: n);
    return BarreSelection.compacte(
      key: CandidaturesPage.cleBarreLot,
      titre: titre,
      phrase: horsLigne
          ? t.admin.candidatures.selection.horsLigne
          : l.autresGestes,
      onRelacher: _relacherTout,
      // Hors ligne : aucune operation n'est rendue (jamais grisee), la phrase
      // dit pourquoi.
      operations: <Widget>[
        if (!horsLigne)
          for (final GesteLot g in GesteLot.values)
            if (caps.geste(g.geste.capacite))
              ActionPrincipale(
                key: CandidaturesPage.cleOperationLot(g),
                libelle: libelleGesteLot(g),
                niveau: g == GesteLot.refuser
                    ? NiveauAction.destructive
                    : NiveauAction.secondaire,
                compacte: true,
                pleineLargeur: false,
                onPress: () => _lancerLot(g, caps),
              ),
      ],
    );
  }

  // --- La liste -----------------------------------------------------------

  /// Le pied d'une liste paginee : la tranche, les fleches, et la taille de
  /// page que le serveur impose, **dite** a la place du choix qu'il ne tient
  /// pas. C'est le pied de Comptes, au meme endroit (relecture visuelle C-12).
  Widget _pied(PageCandidatures page) => KeyedSubtree(
    key: CandidaturesPage.clePied,
    child: PiedDeListe(
      debut: page.debut,
      fin: page.fin,
      total: page.total,
      mention: t.commun.listes.parPage(n: page.taillePage),
      onPrecedent: page.page > 1 ? () => _allerAPage(page.page - 1) : null,
      onSuivant: page.page < page.pages
          ? () => _allerAPage(page.page + 1)
          : null,
    ),
  );

  /// Les lignes d'information entre les commandes et la liste : ce qui s'ouvre,
  /// ce qui n'a pas pu l'etre, le retour du dernier geste, le message de la
  /// selection.
  List<Widget> _informations() {
    final String? ouverture = _ouverture;
    final String? echec = _echecLigne;
    final String? message = _messageSelection;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return <Widget>[
      if (ouverture != null) ...<Widget>[
        Semantics(
          liveRegion: true,
          child: Row(
            key: CandidaturesPage.cleOuverture,
            children: <Widget>[
              const SizedBox.square(
                dimension: AppSpacing.lg,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              Ecart.hSm,
              Flexible(
                child: TexteSansCoupure(
                  t.admin.candidatures.liste.ouverture(nom: ouverture),
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      if (echec != null) ...<Widget>[
        Ecart.vSm,
        BandeauAttention(
          key: const ValueKey<String>('candidatures-echec-ligne'),
          titre: t.admin.candidatures.liste.titreGesteNonFait,
          message: echec,
        ),
        Ecart.vSm,
      ],
      if (message != null) ...<Widget>[
        Semantics(
          liveRegion: true,
          child: TexteSansCoupure(
            message,
            key: CandidaturesPage.cleMessageSelection,
            style: palette.washAccent.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
      ],
      if (_retour != null) ...<Widget>[
        LocalFeedback(message: _retour),
        Ecart.vSm,
      ],
    ];
  }

  Widget _contenu(
    PageCandidatures page,
    CapacitesCandidatures caps, {
    required bool bureau,
    required bool horsLigne,
    required bool selectionPossible,
  }) {
    final r = t.admin.candidatures;
    if (page.lignes.isEmpty) {
      // La derniere ligne d'une page vient de disparaitre (un geste, un
      // filtre) : s'il reste des resultats avant, on y revient au lieu de dire
      // « aucun resultat ».
      if (page.total > 0 && page.page > 1) {
        WidgetsBinding.instance.addPostFrameCallback((Duration _) {
          if (mounted && _page > 1) setState(() => _page = page.pages);
        });
        return const SqueletteDansZone(child: Skeleton.tableDense());
      }
      final String? rappel = rappelFiltres(_filtre);
      return EmptyState(
        key: const ValueKey<String>('candidatures-aucun-resultat'),
        message: r.aucunResultat,
        invitation: rappel,
        icone: AppIcons.rienAAfficher,
        // Les puces de filtre portent deja « Tout effacer » : l'etat vide ne le
        // redit pas (relecture visuelle C-23, le bouton etait offert deux fois).
        libelleAction: _filtresActifs().isEmpty
            ? t.commun.listes.toutEffacer
            : null,
        onAction: _filtresActifs().isEmpty ? _effacer : null,
      );
    }

    final void Function(LigneCandidature)? ouvrir = widget.ouvrirCandidature;
    // Hors ligne : seul le dossier s'ouvre, aucun geste n'est propose.
    final CapacitesCandidatures capsMenu = horsLigne
        ? CapacitesCandidatures.aucune
        : caps;
    final GestesLigne gestes = GestesLigne(
      retenues: _retenues,
      basculer: selectionPossible ? _basculerLigne : null,
      ouvrir: ouvrir,
      menu: (BuildContext _, LigneCandidature l) => MenuLigneCandidature(
        ligne: l,
        capacites: capsMenu,
        onOuvrir: ouvrir == null ? null : () => ouvrir(l),
        onGeste: (GesteCandidature g) => unawaited(_gesteDeLigne(l, g, caps)),
      ),
    );

    final bool barreAuBureau =
        bureau && selectionPossible && _retenues.isNotEmpty;

    if (bureau) {
      final List<Widget> infos = _informations();
      // **Rien ne pousse le tableau** (relecture du code R-1, relecture visuelle
      // C-17) : la barre de selection et les messages (lecture d'un dossier,
      // echec d'un geste, retour, selection retiree) flottent au-dessus du pied
      // de liste, en bas de la zone. Insere au-dessus du tableau, le bloc le
      // descendait de 50 a 70 points sous le curseur et lui prenait une a deux
      // lignes visibles a chaque case cochee.
      final double basPied =
          AppMetriques.of(context).cibleTactile + 3 * AppSpacing.sm;
      return ZoneEtiree(
        child: Stack(
          key: const ValueKey<String>('candidatures-contenu'),
          fit: StackFit.expand,
          children: <Widget>[
            DataCollection<LigneCandidature>(
              // Une page, un tri ou un filtre neufs repartent du haut ; une
              // relecture apres un geste garde la position.
              key: ValueKey<RequeteCandidatures>(
                RequeteCandidatures(filtre: _filtre, tri: _tri, page: _page),
              ),
              colonnes: colonnesCandidatures(
                tri: _tri,
                onTri: (TriCandidatures t) => setState(() {
                  _tri = t;
                  _page = 1;
                }),
              ),
              lignes: page.lignes,
              cle: (LigneCandidature l) => cleCandidature(l.id),
              onSelectionner: ouvrir,
              selection: selectionPossible
                  ? SelectionCollection<LigneCandidature>(
                      estCochee: (LigneCandidature l) =>
                          _retenues.contains(l.id),
                      onBasculer: _basculerLigne,
                      onBasculerPage: (bool cocher) =>
                          _basculerPage(page.lignes, cocher),
                      libelleLigne: nomAffiche,
                    )
                  : null,
              actionsLigne: gestes.menu,
              piedCollant: _pied(page),
            ),
            if (barreAuBureau || infos.isNotEmpty)
              Positioned.directional(
                textDirection: Directionality.of(context),
                start: AppSpacing.sm,
                end: AppSpacing.sm,
                bottom: basPied,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (infos.isNotEmpty)
                      _PanneauFlottant(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: infos,
                        ),
                      ),
                    if (infos.isNotEmpty && barreAuBureau) Ecart.vSm,
                    if (barreAuBureau)
                      _PanneauFlottant(
                        sansFond: true,
                        child: _barreLot(page, caps, horsLigne),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
    final List<Widget> avant = _informations();
    return Column(
      key: const ValueKey<String>('candidatures-contenu'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ...avant,
        PileCartesLigne(lignes: page.lignes, gestes: gestes, tri: _tri),
        Ecart.vLg,
        _pied(page),
      ],
    );
  }

  /// Les etats propres a la file, avant le cas par defaut de [BlocAsynchrone].
  Widget? _etatErreur(Object erreur, VoidCallback? reessayer, bool horsLigne) {
    final r = t.admin.candidatures;
    if (erreur is CapaciteIndisponible) {
      return EtatSysteme(
        key: const ValueKey<String>('candidatures-indisponible'),
        nature: NatureEtat.indisponible,
        titre: t.commun.etats.branchementServeur,
        phrase: '',
        dependance: erreur.dependance,
      );
    }
    if (erreur is GenreLecteurInconnu) {
      return EtatSysteme(
        key: const ValueKey<String>('candidatures-genre-inconnu'),
        nature: NatureEtat.accesRefuse,
        titre: r.genreInconnuTitre,
        phrase: r.genreInconnu,
      );
    }
    if (erreur is PermissionInsuffisante) {
      return EtatSysteme(
        key: const ValueKey<String>('candidatures-acces-refuse'),
        nature: NatureEtat.accesRefuse,
        titre: r.accesRefuse,
        phrase: '',
      );
    }
    if (horsLigne) {
      return EtatSansDonnees(
        key: const ValueKey<String>('candidatures-sans-donnees'),
        quoi: r.sansDonnees,
        onAction: reessayer,
      );
    }
    return EtatSysteme(
      key: const ValueKey<String>('candidatures-erreur'),
      nature: NatureEtat.echecServeur,
      titre: r.lectureEchec,
      // Les essais epuises : la phrase le dit a la place du bouton.
      phrase: reessayer == null ? t.commun.etats.reessaisEpuises : '',
      onAction: reessayer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final RequeteCandidatures requete = RequeteCandidatures(
      filtre: _filtre,
      tri: _tri,
      page: _page,
    );
    final AsyncValue<PageCandidatures> valeur = ref.watch(
      pageCandidaturesProvider(requete),
    );
    if (valeur.hasValue) _derniere = valeur.requireValue;
    final PageCandidatures? reference = valeur.value ?? _derniere;
    final CapacitesCandidatures caps =
        ref.watch(capacitesCandidaturesProvider).value ??
        CapacitesCandidatures.aucune;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final r = t.admin.candidatures;

    // Rien du tout dans la portee du lecteur (aucun filtre, zero candidature) :
    // ni synthese, ni recherche, ni filtres, seulement le constat.
    final bool porteeVide =
        valeur.hasValue && valeur.requireValue.total == 0 && _filtre.estVide;
    final bool commandes = reference != null && !porteeVide;

    // La selection n'existe que si elle peut aboutir : le serveur ouvre
    // l'action en lot (capacite lue). Sans elle, ni case ni barre : une
    // selection sur laquelle on ne peut rien faire n'est pas offerte.
    final bool selectionPossible = caps.peutAgirEnLot;

    // Le tableau au bureau, les cartes ailleurs et quand le texte agrandi ne
    // laisse plus tenir les colonnes. En tableau, la liste defile seule sous
    // son en-tete colle ; en cartes, toute la page defile.
    final bool bureau =
        DataCollection.enTableau(context) &&
        MediaQuery.textScalerOf(context).scale(1) <= 1;

    final bool invitations =
        ref.watch(portInvitationsEnseignantProvider) != null ||
        ref.watch(portInvitationsComptableProvider) != null;

    Widget zone(Widget enfant) => bureau ? Expanded(child: enfant) : enfant;

    // Au bureau, le lien est a droite du titre ; ailleurs, sa place est la
    // premiere ligne du corps.
    final bool lienEnTete =
        MediaQuery.sizeOf(context).width >= _largeurUneBande;
    Widget lienInvitations() => LienFleche(
      key: const ValueKey<String>('candidatures-invitations'),
      libelle: t.recrutement.invitations.onglet,
      alignerEnFin: true,
      onPress: () => context.go(Routes.adminPersonnesInvitations),
    );
    // L'import des formulaires (ADM-23) : rendu seulement si le serveur le
    // permet (super-administrateur), jamais grise.
    final bool importer = caps.peutImporter;
    Widget lienImport() => LienFleche(
      key: const ValueKey<String>('candidatures-import'),
      libelle: t.admin.importFormulaires.lienEntree,
      alignerEnFin: true,
      onPress: () =>
          GoRouter.of(context).push(Routes.adminPersonnesCandidaturesImport),
    );

    final List<FiltreActif> actifs = commandes
        ? _filtresActifs()
        : const <FiltreActif>[];

    return PageShell(
      key: CandidaturesPage.clePage,
      titre: r.titre,
      // Le seul chemin vers les invitations : en tete de page, rendu dans tous
      // les etats (file vide, en erreur, serveur pas encore branche), tant que
      // l'un de ses deux ports est servi (CAND-F01). Sur un ecran etroit il
      // passerait sur le titre et le couperait : il prend alors la premiere
      // ligne du corps.
      actionsEntete: <Widget>[
        if (importer && lienEnTete) lienImport(),
        if (invitations && lienEnTete) lienInvitations(),
      ],
      entete: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SousNavigationDomaine(onglets: ongletsPersonnes(), indexActif: 2),
          // L'exception de lecture du super-admin se dit en tete, quand le
          // serveur la rend active (jamais deduite du role).
          if (caps.peutLireHorsGenre)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: BandeauAttention(
                key: const ValueKey<String>('candidatures-exception'),
                titre: r.exception.titre,
                message: r.exception.message,
              ),
            ),
        ],
      ),
      defilante: !bureau,
      actions:
          !bureau &&
              reference != null &&
              selectionPossible &&
              _retenues.isNotEmpty
          ? _barreLot(reference, caps, horsLigne)
          : null,
      child: ColonneCorps(
        minimumEtire: bureau ? DataCollection.minimumLisible(context) : 0,
        children: <Widget>[
          if (invitations && !lienEnTete) ...<Widget>[
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: lienInvitations(),
            ),
            Ecart.vXs,
          ],
          if (importer && !lienEnTete) ...<Widget>[
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: lienImport(),
            ),
            Ecart.vXs,
          ],
          if (commandes) ...<Widget>[
            KeyedSubtree(
              key: _cleListe,
              child: _barreCommandes(
                reference,
                caps,
                valeur.hasValue ? valeur.requireValue.total : null,
                triVisible: !bureau,
              ),
            ),
            if (actifs.isNotEmpty) ...<Widget>[
              Ecart.vSm,
              FiltresActifs(filtres: actifs, onToutEffacer: _effacer),
            ],
            Ecart.vXs,
          ],
          zone(
            BlocAsynchrone<PageCandidatures>(
              key: const ValueKey<String>('candidatures-bloc'),
              valeur: valeur,
              squelette: bureau
                  ? const SqueletteDansZone(child: Skeleton.tableDense())
                  : const Skeleton.liste(lignes: 4),
              onReessayer: _relire,
              estVide: (PageCandidatures p) => p.total == 0 && _filtre.estVide,
              vide: EmptyState(
                key: const ValueKey<String>('candidatures-vide'),
                message: r.vide,
                invitation: r.videDetail,
                // Rien a faire pour la direction : le constat et la raison,
                // sans bouton.
                registre: RegistreVide.subi,
                icone: AppIcons.dossiers,
              ),
              erreurVersEtat: (Object erreur, VoidCallback? reessayer) =>
                  _etatErreur(erreur, reessayer, horsLigne),
              construire: (PageCandidatures page) => _contenu(
                page,
                caps,
                bureau: bureau,
                horsLigne: horsLigne,
                selectionPossible: selectionPossible,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Les cartes de la liste (telephone, tablette, texte agrandi), separees d'un
/// ecart : jamais collees (K-55).
class PileCartesLigne extends StatelessWidget {
  /// Cree la pile.
  const PileCartesLigne({
    required this.lignes,
    required this.gestes,
    required this.tri,
    super.key,
  });

  /// Les lignes de la page.
  final List<LigneCandidature> lignes;

  /// Les gestes de la page.
  final GestesLigne gestes;

  /// Le tri, qui dit la date que la carte montre.
  final TriCandidatures tri;

  @override
  Widget build(BuildContext context) => PileCartes(
    children: <Widget>[
      for (final LigneCandidature l in lignes)
        CarteCandidature(ligne: l, gestes: gestes, tri: tri),
    ],
  );
}

/// Ce qui flotte au-dessus de la liste sans la pousser : un fond opaque, un filet
/// et l'ombre des surfaces qui recouvrent (jetons d'`AppElevation`). [sansFond] :
/// l'enfant porte deja sa surface, seule l'ombre est posee.
class _PanneauFlottant extends StatelessWidget {
  const _PanneauFlottant({required this.child, this.sansFond = false});

  final Widget child;
  final bool sansFond;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    const BorderRadius arrondi = AppRadius.arrondiSm;
    final List<BoxShadow> ombres = AppElevation.niveau2(palette.ombreDialogue);
    if (sansFond) {
      return DecoratedBox(
        decoration: BoxDecoration(borderRadius: arrondi, boxShadow: ombres),
        child: child,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surfaceOverlay.background,
        borderRadius: arrondi,
        border: Border.fromBorderSide(palette.contourCarte.asBorderSide()),
        boxShadow: ombres,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}

/// Le tri des cartes, en menu : une icone au bout de la rangee des filtres, la
/// section courante portant une coche (le meme principe que le selecteur de
/// section de `MenuFiltre`). Le serveur sert trois ordres ; aucun autre n'est
/// propose. Le menu est celui du produit (`MenuAncre`), jamais un second systeme.
class _MenuTri extends StatelessWidget {
  const _MenuTri({required this.valeur, required this.onChoix});

  final TriCandidatures valeur;
  final ValueChanged<TriCandidatures> onChoix;

  static String _nom(TriCandidatures tri) {
    final r = t.admin.candidatures;
    return switch (tri) {
      TriCandidatures.activite => r.tri.activite,
      TriCandidatures.recente => r.tri.reception,
      TriCandidatures.nom => r.colonnes.nom,
    };
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double cible = AppMetriques.of(context).cibleTactile;
    return MenuAncre<TriCandidatures>(
      key: const ValueKey<String>('candidatures-tri'),
      libelle: '${t.admin.candidatures.tri.titre} : ${_nom(valeur)}',
      contraintes: contraintesMenu,
      arrondiFocus: AppRadius.arrondiFull,
      onSelected: onChoix,
      itemBuilder: (BuildContext _) => <PopupMenuEntry<TriCandidatures>>[
        for (final TriCandidatures tri in TriCandidatures.values)
          PopupMenuItem<TriCandidatures>(
            value: tri,
            height: cible,
            padding: EdgeInsets.zero,
            child: LigneEntreeMenu(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TexteSansCoupure(
                      _nom(tri),
                      style: palette.inkStrong.applyTo(
                        Theme.of(context).textTheme.labelLarge ??
                            const TextStyle(),
                      ),
                    ),
                  ),
                  if (tri == valeur) ...<Widget>[
                    Ecart.hMd,
                    Icon(
                      AppIcons.succes.actif,
                      size: AppSpacing.lg,
                      color: palette.inkAccent.asIconTheme().color,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
      declencheur: (BuildContext _, EtatPression etat) => SizedBox(
        width: cible,
        height: cible,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: etat.survole || etat.presse
                ? palette.washAccent.background
                : null,
            border: Border.fromBorderSide(palette.borderStrong.asBorderSide()),
          ),
          child: Center(child: Icon(AppIcons.triNeutre.repos)),
        ),
      ),
    );
  }
}
