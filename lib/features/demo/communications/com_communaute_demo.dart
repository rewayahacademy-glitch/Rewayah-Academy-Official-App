// La demonstration de la voie COM-COMU (Communaute enseignants) :
// `/demo/communications?voie=communaute&role=enseignant&etat=...`.
//
// **Jamais en production** : la route n'existe que si
// `environnementAutoriseDemo` l'autorise (COM-F, DEMO-ENV-1). Aucun port reel
// n'est branche ici (K-28) : la Communaute, la moderation, les elements
// enregistres, la politique des pieces jointes et le choix d'un fichier sont
// des doubles en memoire, et rien ne quitte l'appareil.
//
// La VRAIE coquille de l'enseignant (`NavShell`, destinations de
// `destinationsPour(AppRole.teacher)`) porte la VRAIE page : Aujourd'hui
// (avec la ligne « Communaute enseignants ») ou la Communaute, jamais
// « Foyer » ni « Tuteur » des maquettes. La Communaute est reservee aux
// enseignants : le `?role=` de l'adresse ne change pas la coquille.
//
// Donnees (spec section 26) : six publications communautaires, trois
// categories (Pedagogie, Ressources, Gestion, celles de la maquette,
// marquees demonstration), des reponses, une piece jointe ; et, pour le
// garde anti-promotion (COM-COMU-2), deux publications bloquees (un lien
// affilie, une vente), une publicite retenue par un avertissement, et les
// quatre etats de lien. Ces verdicts sont une TABLE de contenus marques
// d'avance (`GardePromotionFixtures`), jamais une detection : la situation
// ouvre la nouvelle publication sur le brouillon marque, et modifier un mot
// le rend normal.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/communications/modeles_communication.dart';
import '../../../core/communications/moderation.dart';
import '../../../core/communications/port_brouillons.dart';
import '../../../core/communications/port_elements_enregistres.dart';
import '../../../core/communications/port_pieces_jointes.dart';
import '../../../core/domain/enums.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/router/routes.dart';
import '../../../core/tc_groupe/group_summary_vm.dart'
    show EnseignantVM, TitreEnseignant;
import '../../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/carte_piece_jointe.dart'
    show politiquePiecesJointesProvider;
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/nav_shell.dart';
import '../../../core/widgets/page_shell.dart';
import '../../com_communaute/communaute_page.dart';
import '../../com_communaute/composer_publication.dart';
import '../../com_communaute/entree_communaute.dart';
import '../../com_communaute/etat_lien.dart';
import '../../com_communaute/port_communaute.dart';
import '../../com_communaute/port_garde_promotion.dart';
import '../../journee/journee_page.dart';
import '../demo_enseignant_page.dart'
    show adresseDemoEnseignant, surchargesCoquilleEnseignantDemo;
import '../enseignant_demo.dart';
import '../repere_demonstration.dart';
import 'demo_communications_page.dart';

/// Les situations de la demonstration de la Communaute.
enum SituationDemoCommunaute {
  /// Aujourd'hui, avec la ligne « Communaute enseignants » (Q2).
  aujourdhui,

  /// Six publications, toutes les capacites.
  nominal,

  /// Une publication ouverte (comme depuis une notification).
  publication,

  /// Aucune publication.
  vide,

  /// La lecture echoue : « Reessayer ».
  erreur,

  /// Le port neutre de production : « Pas encore disponible ».
  indisponible,

  /// L'appareil est hors ligne : le bandeau, le contenu deja lu, les envois
  /// non confirmes.
  horsLigne,

  /// Les envois ne sont jamais confirmes.
  envoiNonConfirme,

  /// La moderation ne repond pas : le signalement dit « pas encore
  /// disponible ».
  moderationIndisponible,

  /// Lecture seule : ni publication ni reponse (capacites fermees).
  lecteurSeul,

  /// Une publicite : le garde retient la publication par un avertissement
  /// (R-COM-05).
  avertissementPromotion,

  /// Un lien affilie : le garde bloque la publication (R-COM-06).
  lienAffilie,

  /// Une vente : le garde bloque la publication.
  vente,

  /// Le signalement part, mais l'accuse ne revient pas : « pas encore
  /// confirme ».
  signalementNonConfirme;

  /// Le brouillon marque que la situation ouvre, s'il y en a un.
  BrouillonMarqueDemo? get brouillon => switch (this) {
    SituationDemoCommunaute.avertissementPromotion =>
      DonneesCommunauteDemo.brouillonPublicite,
    SituationDemoCommunaute.lienAffilie =>
      DonneesCommunauteDemo.brouillonAffilie,
    SituationDemoCommunaute.vente => DonneesCommunauteDemo.brouillonVente,
    _ => null,
  };
}

/// Un brouillon de demonstration marque par le garde : son contenu et le
/// verdict que la fixture lui donne.
typedef BrouillonMarqueDemo = ({
  String titre,
  String texte,
  VerificationPromotion verdict,
});

/// L'adresse d'une situation de la demonstration.
String adresseDemoCommunaute(SituationDemoCommunaute situation) => Uri(
  path: Routes.demoCommunications,
  queryParameters: <String, String>{
    'voie': VoieDemoCommunications.communaute.name,
    'role': RoleDemoCommunications.enseignant.name,
    'etat': situation.name,
  },
).toString();

/// Le libelle d'une situation.
String libelleSituationDemoCommunaute(SituationDemoCommunaute situation) {
  final d = t.com.communaute.demo;
  return switch (situation) {
    SituationDemoCommunaute.aujourdhui => d.aujourdhui,
    SituationDemoCommunaute.nominal => d.nominal,
    SituationDemoCommunaute.publication => d.publication,
    SituationDemoCommunaute.vide => d.vide,
    SituationDemoCommunaute.erreur => d.lectureEchouee,
    SituationDemoCommunaute.indisponible => d.indisponible,
    SituationDemoCommunaute.horsLigne => d.horsLigne,
    SituationDemoCommunaute.envoiNonConfirme => d.envoiNonConfirme,
    SituationDemoCommunaute.moderationIndisponible => d.moderationIndisponible,
    SituationDemoCommunaute.lecteurSeul => d.lecteurSeul,
    SituationDemoCommunaute.avertissementPromotion => d.avertissement,
    SituationDemoCommunaute.lienAffilie => d.lienAffilie,
    SituationDemoCommunaute.vente => d.vente,
    SituationDemoCommunaute.signalementNonConfirme => d.signalementNonConfirme,
  };
}

/// Les donnees fictives de la Communaute (spec section 26). Noms, categories,
/// publications, reponses et brouillons suivent la langue de l'interface
/// (COM-RC tour 7 : plus de francais dans l'arabe) ; les adresses et le code
/// promotionnel restent tels quels.
abstract final class DonneesCommunauteDemo {
  static Traductions$com$communaute$demo$f$fr get _f => t.com.communaute.demo.f;

  /// Le « maintenant » de la demonstration : lundi 28 septembre 2026, 14 h
  /// UTC (16 h a Paris, comme la demonstration enseignant).
  static final DateTime maintenant = DateTime.utc(2026, 9, 28, 14);

  /// La publication ouverte par la situation « publication ».
  static const String publicationOuverte = 'pub-memorisation';

  /// Pedagogie.
  static CategorieCommunaute get pedagogie =>
      CategorieCommunaute(id: 'pedagogie', libelle: _f.categoriePedagogie);

  /// Ressources.
  static CategorieCommunaute get ressources =>
      CategorieCommunaute(id: 'ressources', libelle: _f.categorieRessources);

  /// Gestion de Classe.
  static CategorieCommunaute get gestion =>
      CategorieCommunaute(id: 'gestion', libelle: _f.categorieGestion);

  /// Les categories, dans l'ordre de la maquette.
  static List<CategorieCommunaute> get categories => <CategorieCommunaute>[
    pedagogie,
    ressources,
    gestion,
  ];

  /// L'enseignant de la demonstration, auteur de ce qui est publie.
  static Participant get soi => Participant(
    id: DonneesEnseignantDemo.enseignantId,
    // « Sayyid Ibrahim » en francais, comme la demonstration enseignant ;
    // le prenom dans l'alphabet de la langue courante.
    nomAffiche: LibellesGroupe.enseignantNomme(
      EnseignantVM(
        enseignantId: DonneesEnseignantDemo.enseignantId,
        titre: TitreEnseignant.sayyid,
        nomAffichage: _f.prenomSoi,
      ),
    ),
    fonction: _f.fonctionSoi,
    estSoi: true,
  );

  static Participant get _samira => Participant(
    id: 'demo-ens-samira',
    nomAffiche: _f.samira,
    fonction: _f.fonctionSamira,
  );
  static Participant get _nour => Participant(
    id: 'demo-ens-nour',
    nomAffiche: _f.nour,
    fonction: _f.fonctionNour,
  );
  static Participant get _yasmine => Participant(
    id: 'demo-ens-yasmine',
    nomAffiche: _f.yasmine,
    fonction: _f.fonctionYasmine,
  );
  static Participant get _youssef => Participant(
    id: 'demo-ens-youssef',
    nomAffiche: _f.youssef,
    fonction: _f.fonctionYoussef,
  );
  static Participant get _mariam => Participant(
    id: 'demo-ens-mariam',
    nomAffiche: _f.mariam,
    fonction: _f.fonctionMariam,
  );
  static Participant get _hamza => Participant(
    id: 'demo-ens-hamza',
    nomAffiche: _f.hamza,
    fonction: _f.fonctionHamza,
  );

  static DateTime _ilYa({int jours = 0, int heures = 0, int minutes = 0}) =>
      maintenant.subtract(
        Duration(days: jours, hours: heures, minutes: minutes),
      );

  /// Les six publications (spec section 26).
  static List<PublicationCommunaute> publications() => <PublicationCommunaute>[
    PublicationCommunaute(
      id: publicationOuverte,
      auteur: _samira,
      titre: _f.memorisationTitre,
      texte: _f.memorisationTexte,
      categorie: pedagogie,
      publieeLe: _ilYa(heures: 2),
    ),
    PublicationCommunaute(
      id: 'pub-cartes',
      auteur: _nour,
      titre: _f.cartesTitre,
      texte: _f.cartesTexte,
      categorie: ressources,
      publieeLe: _ilYa(jours: 1, heures: 3),
      piecesJointes: <PieceJointe>[
        PieceJointe(
          reference: ReferencePieceJointe('demo-piece-cartes'),
          nom: _f.cartesFichier,
          nature: NaturePieceJointe.document,
          typeLisible: 'PDF',
          tailleOctets: 250880,
        ),
      ],
    ),
    PublicationCommunaute(
      id: 'pub-niveaux',
      auteur: _yasmine,
      titre: _f.niveauxTitre,
      texte: _f.niveauxTexte,
      categorie: gestion,
      publieeLe: _ilYa(jours: 2),
    ),
    PublicationCommunaute(
      id: 'pub-timides',
      auteur: _youssef,
      titre: _f.timidesTitre,
      texte: _f.timidesTexte,
      categorie: pedagogie,
      publieeLe: _ilYa(jours: 3, heures: 5),
    ),
    PublicationCommunaute(
      id: 'pub-fiche-suivi',
      auteur: _mariam,
      titre: _f.ficheTitre,
      texte: _f.ficheTexte,
      categorie: ressources,
      publieeLe: _ilYa(jours: 4),
    ),
    PublicationCommunaute(
      id: 'pub-heure',
      auteur: _hamza,
      titre: _f.heureTitre,
      texte: _f.heureTexte,
      categorie: gestion,
      publieeLe: _ilYa(jours: 6),
    ),
  ];

  /// Les reponses, par publication.
  static Map<String, List<ReponseCommunaute>> reponses() =>
      <String, List<ReponseCommunaute>>{
        publicationOuverte: <ReponseCommunaute>[
          ReponseCommunaute(
            id: 'rep-mariam',
            publicationId: publicationOuverte,
            auteur: _mariam,
            texte: _f.reponseMariam,
            publieeLe: _ilYa(heures: 1),
          ),
          ReponseCommunaute(
            id: 'rep-youssef',
            publicationId: publicationOuverte,
            auteur: _youssef,
            texte: _f.reponseYoussef,
            publieeLe: _ilYa(minutes: 45),
          ),
        ],
        'pub-cartes': <ReponseCommunaute>[
          ReponseCommunaute(
            id: 'rep-samira',
            publicationId: 'pub-cartes',
            auteur: _samira,
            texte: _f.reponseSamira,
            publieeLe: _ilYa(jours: 1),
          ),
        ],
        'pub-timides': <ReponseCommunaute>[
          ReponseCommunaute(
            id: 'rep-hamza',
            publicationId: 'pub-timides',
            auteur: _hamza,
            texte: _f.reponseHamza,
            publieeLe: _ilYa(jours: 3),
          ),
        ],
      };

  /// Un lien interne Rewayah (fixture).
  static const String lienInterne =
      'https://rewayah-academy.vercel.app/tc/bibliotheque';

  /// Une ressource pedagogique externe (fixture).
  static const String lienRessource = 'https://quran.com/1';

  /// Un lien affilie : commercial interdit (fixture).
  static const String lienAffilieDemo =
      'https://lecteur-coran.example/produit?ref=prof42';

  /// Un lien que le serveur n'a pas qualifie (fixture).
  static const String lienNonQualifie = 'https://app-revision.example/offre';

  /// L'etat de chaque lien des fixtures (spec section 5.4).
  static const Map<String, EtatLien> etatsLiens = <String, EtatLien>{
    lienInterne: EtatLien.interne,
    lienRessource: EtatLien.ressourceExterne,
    lienAffilieDemo: EtatLien.commercialInterdit,
    lienNonQualifie: EtatLien.nonVerifie,
  };

  /// Publication bloquee 1 (spec section 26) : un lien affilie.
  static BrouillonMarqueDemo get brouillonAffilie => (
    titre: _f.affilieTitre,
    texte: _f.affilieTexte(lien: lienAffilieDemo),
    verdict: const VerificationPromotion(
      verdict: VerdictPromotion.lienAffilie,
      motif: MotifSignalement.lienAffilie,
      liens: <LienAnalyse>[
        LienAnalyse(
          adresse: lienAffilieDemo,
          etat: EtatLien.commercialInterdit,
        ),
      ],
    ),
  );

  /// Publication bloquee 2 (spec section 26) : une vente.
  static BrouillonMarqueDemo get brouillonVente => (
    titre: _f.venteTitre,
    texte: _f.venteTexte,
    verdict: const VerificationPromotion(
      verdict: VerdictPromotion.vente,
      motif: MotifSignalement.venteNonAutorisee,
    ),
  );

  /// Une publicite retenue par un avertissement (R-COM-05), avec les trois
  /// autres etats de lien.
  static BrouillonMarqueDemo get brouillonPublicite => (
    titre: _f.publiciteTitre,
    texte: _f.publiciteTexte(
      lienOffre: lienNonQualifie,
      lienInterne: lienInterne,
      lienRessource: lienRessource,
    ),
    verdict: const VerificationPromotion(
      verdict: VerdictPromotion.avertissement,
      motif: MotifSignalement.publicite,
      liens: <LienAnalyse>[
        LienAnalyse(adresse: lienNonQualifie, etat: EtatLien.nonVerifie),
        LienAnalyse(adresse: lienInterne, etat: EtatLien.interne),
        LienAnalyse(adresse: lienRessource, etat: EtatLien.ressourceExterne),
      ],
    ),
  );

  /// Les brouillons marques, dans l'ordre de la spec section 26.
  static List<BrouillonMarqueDemo> get brouillonsMarques =>
      <BrouillonMarqueDemo>[
        brouillonAffilie,
        brouillonVente,
        brouillonPublicite,
      ];

  /// Une reponse marquee (revue COM-R, R-01) : un lien affilie poste en
  /// reponse est retenu comme une publication.
  static String get reponseAffilie => _f.reponseAffilie(lien: lienAffilieDemo);

  /// Le verdict de [reponseAffilie].
  static const VerificationPromotion verdictReponseAffilie =
      VerificationPromotion(
        verdict: VerdictPromotion.lienAffilie,
        motif: MotifSignalement.lienAffilie,
        liens: <LienAnalyse>[
          LienAnalyse(
            adresse: lienAffilieDemo,
            etat: EtatLien.commercialInterdit,
          ),
        ],
      );

  /// Le garde des fixtures : les trois brouillons marques, la reponse
  /// marquee et les quatre etats de lien. Tout autre contenu est normal.
  static GardePromotionFixtures garde() => GardePromotionFixtures(
    verdicts: <ContenuMarque, VerificationPromotion>{
      for (final BrouillonMarqueDemo b in brouillonsMarques)
        (titre: b.titre, texte: b.texte): b.verdict,
    },
    verdictsReponses: <String, VerificationPromotion>{
      reponseAffilie: verdictReponseAffilie,
    },
    liens: etatsLiens,
  );

  /// Les brouillons de session d'une situation : le brouillon marque deja
  /// ecrit, restaure a l'ouverture de la nouvelle publication.
  static BrouillonsMemoire brouillons(SituationDemoCommunaute situation) {
    final BrouillonsMemoire memoire = BrouillonsMemoire(
      maintenant: () => maintenant,
    );
    final BrouillonMarqueDemo? marque = situation.brouillon;
    if (marque != null) {
      // La memoire ecrit sans attendre : le brouillon est la des le retour.
      unawaited(
        memoire.enregistrer(ComposerPublication.brouillonTitre, marque.titre),
      );
      unawaited(
        memoire.enregistrer(ComposerPublication.brouillonTexte, marque.texte),
      );
    }
    return memoire;
  }

  /// La politique des pieces jointes de la demonstration : 10 Mo, documents
  /// PDF, images et audio.
  static final PolitiquePiecesJointes politique = PolitiquePiecesJointes(
    tailleMaxOctets: 10 * 1024 * 1024,
    typesAutorises: const <String>{'application/pdf', 'image/*', 'audio/*'},
  );

  /// Le fichier que le choix de la demonstration rend.
  static FichierChoisi get fichier => FichierChoisi(
    nom: _f.fichierChoisi,
    typeMime: 'application/pdf',
    typeLisible: 'PDF',
    tailleOctets: 184320,
  );

  /// La Communaute en memoire d'une situation.
  static PortCommunaute port(SituationDemoCommunaute situation) {
    if (situation == SituationDemoCommunaute.indisponible) {
      return const CommunauteIndisponible();
    }
    final bool vide = situation == SituationDemoCommunaute.vide;
    return CommunauteMemoire(
      categories: categories,
      publications: vide ? const <PublicationCommunaute>[] : publications(),
      reponses: vide ? const <String, List<ReponseCommunaute>>{} : reponses(),
      soi: soi,
      capacitesRendues: situation == SituationDemoCommunaute.lecteurSeul
          ? CapacitesCommunaute.aucune
          : const CapacitesCommunaute(peutPublier: true, peutRepondre: true),
      echecLecture: situation == SituationDemoCommunaute.erreur,
      echecEnvoi:
          situation == SituationDemoCommunaute.envoiNonConfirme ||
          situation == SituationDemoCommunaute.horsLigne,
      maintenant: () => maintenant,
    );
  }
}

/// La moderation de la demonstration : signaler est permis ; le signalement
/// est accuse, ou la moderation ne repond pas ([indisponible]). Rien ne
/// quitte l'appareil.
class ModerationDemo implements PortModeration {
  /// Cree la moderation. [dejaSignales] : les contenus que la personne
  /// avait signales avant la visite, rendus par [mesSignalements].
  ModerationDemo({
    this.indisponible = false,
    this.nonConfirme = false,
    Set<ObjetLie> dejaSignales = const <ObjetLie>{},
  }) : _dejaSignales = Set<ObjetLie>.of(dejaSignales);

  /// Vrai : chaque signalement echoue comme un port sans contrat.
  final bool indisponible;

  /// Vrai : l'accuse ne revient pas (reseau coupe) ; rien n'est garde.
  final bool nonConfirme;

  final Set<ObjetLie> _dejaSignales;

  /// Les cles d'idempotence deja accusees (tests) : un renvoi avec la meme
  /// cle ne cree rien.
  final Set<String> cles = <String>{};

  /// Les signalements accuses (tests).
  final List<(ObjetLie, MotifSignalement)> signalements =
      <(ObjetLie, MotifSignalement)>[];

  @override
  Future<CapacitesModeration> capacites() async =>
      CapacitesModeration(peutSignaler: true);

  @override
  Future<ResultatSignalement> signaler({
    required ObjetLie objet,
    required MotifSignalement motif,
    required String cleIdempotence,
    String? precision,
  }) async {
    if (indisponible) throw const CapaciteIndisponible('COM-BR-06');
    if (nonConfirme) throw StateError('accuse de signalement non recu');
    if (cles.contains(cleIdempotence)) return ResultatSignalement.enregistre;
    if (_dejaSignales.contains(objet)) return ResultatSignalement.dejaSignale;
    cles.add(cleIdempotence);
    _dejaSignales.add(objet);
    signalements.add((objet, motif));
    return ResultatSignalement.enregistre;
  }

  @override
  Future<Set<ObjetLie>> mesSignalements() async {
    if (indisponible) throw const CapaciteIndisponible('COM-BR-06');
    return Set<ObjetLie>.unmodifiable(_dejaSignales);
  }

  @override
  Future<List<ElementModeration>> file() async => const <ElementModeration>[];

  @override
  Future<void> appliquer({
    required String signalementId,
    required ActionModeration action,
  }) async {}
}

/// La politique des pieces jointes de la demonstration.
class PolitiquePiecesJointesDemo implements PortPolitiquePiecesJointes {
  /// Cree la politique.
  const PolitiquePiecesJointesDemo();

  @override
  Future<PolitiquePiecesJointes> politique() async =>
      DonneesCommunauteDemo.politique;
}

/// Le choix de fichier de la demonstration : toujours le meme fichier
/// fictif, aucune boite de dialogue du systeme.
class ChoixPieceDemo implements ChoixPieceCommunaute {
  /// Cree le choix.
  const ChoixPieceDemo();

  @override
  Future<FichierChoisi?> choisir() async => DonneesCommunauteDemo.fichier;
}

/// Les surcharges de la Communaute pour une situation : seuls des doubles
/// en memoire, aucun port reseau. Le hors ligne vient des surcharges de la
/// coquille enseignant (`EtatDemoEnseignant.horsLigne`).
List<Override> surchargesCommunauteDemo(
  SituationDemoCommunaute situation,
) => <Override>[
  portCommunauteProvider.overrideWithValue(
    DonneesCommunauteDemo.port(situation),
  ),
  portModerationProvider.overrideWithValue(
    ModerationDemo(
      indisponible: situation == SituationDemoCommunaute.moderationIndisponible,
      nonConfirme: situation == SituationDemoCommunaute.signalementNonConfirme,
    ),
  ),
  portGardePromotionProvider.overrideWithValue(DonneesCommunauteDemo.garde()),
  portElementsEnregistresProvider.overrideWithValue(
    ElementsEnregistresMemoire(
      maintenant: () => DonneesCommunauteDemo.maintenant,
    ),
  ),
  portPolitiquePiecesJointesProvider.overrideWithValue(
    const PolitiquePiecesJointesDemo(),
  ),
  choixPieceCommunauteProvider.overrideWithValue(const ChoixPieceDemo()),
  horlogeCommunauteProvider.overrideWithValue(
    () => DonneesCommunauteDemo.maintenant,
  ),
  // Les lectures du socle qui ne declarent pas leur port (politique des
  // pieces jointes, brouillons lies a la session) sont surchargees
  // elles-memes : sous ce ProviderScope imbrique, elles liraient sinon la
  // racine, ou aucun port de demonstration n'est pose.
  politiquePiecesJointesProvider.overrideWith(
    (Ref _) async => DonneesCommunauteDemo.politique,
  ),
  portBrouillonsProvider.overrideWithValue(
    DonneesCommunauteDemo.brouillons(situation),
  ),
  destinationCommunauteProvider.overrideWithValue(
    adresseDemoCommunaute(SituationDemoCommunaute.nominal),
  ),
];

/// La demonstration de la voie COM-COMU : l'index des situations, ou la
/// coquille enseignant sur la situation choisie (`?etat=`).
class ComCommunauteDemo extends StatelessWidget {
  /// Cree la demonstration de la voie.
  const ComCommunauteDemo({super.key, this.role, this.situation});

  /// Le role mis en scene (`?role=`) : la Communaute n'a que l'enseignant.
  final RoleDemoCommunications? role;

  /// La situation ; nulle, elle est lue dans l'adresse (`?etat=`).
  final SituationDemoCommunaute? situation;

  SituationDemoCommunaute? _situation(BuildContext context) {
    final SituationDemoCommunaute? donnee = situation;
    if (donnee != null) return donnee;
    if (GoRouter.maybeOf(context) == null) return null;
    final String? nom = GoRouterState.of(context).uri.queryParameters['etat'];
    for (final SituationDemoCommunaute s in SituationDemoCommunaute.values) {
      if (s.name == nom) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final SituationDemoCommunaute? s = _situation(context);
    if (s != null) return CoquilleCommunauteDemo(situation: s);

    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return PageShell(
      titre: t.com.communaute.titre,
      sousTitre: t.com.socle.navigation.demo.detail,
      onRetour: () => GoRouter.of(context).go(Routes.demoCommunications),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            t.com.communaute.demo.choisir,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
          for (final SituationDemoCommunaute s
              in SituationDemoCommunaute.values)
            LienFleche(
              key: ValueKey<String>('lien-communaute-${s.name}'),
              libelle: libelleSituationDemoCommunaute(s),
              onPress: () => GoRouter.of(context).go(adresseDemoCommunaute(s)),
            ),
        ],
      ),
    );
  }
}

/// La VRAIE coquille enseignant sur Aujourd'hui ou la Communaute, ses
/// providers surcharges par les donnees de demonstration.
class CoquilleCommunauteDemo extends StatelessWidget {
  /// Cree la coquille.
  const CoquilleCommunauteDemo({required this.situation, super.key});

  /// La situation montree.
  final SituationDemoCommunaute situation;

  @override
  Widget build(BuildContext context) {
    final List<Destination> destinations = destinationsPour(
      role: AppRole.teacher,
      mode: InterfaceMode.standard,
    );
    final EtatDemoEnseignant etatEnseignant =
        situation == SituationDemoCommunaute.horsLigne
        ? EtatDemoEnseignant.horsLigne
        : EtatDemoEnseignant.nominal;
    return ProviderScope(
      key: ValueKey<SituationDemoCommunaute>(situation),
      overrides: <Override>[
        ...surchargesCoquilleEnseignantDemo(etatEnseignant),
        ...surchargesCommunauteDemo(situation),
      ],
      child: RepereDemonstration(
        child: NavShell(
          destinations: destinations,
          // La Communaute est un raccourci d'Aujourd'hui (Q2) : Aujourd'hui
          // reste la destination active.
          indexActif: 0,
          libellesDansLeRail: true,
          onAller: (String chemin) {
            final int i = destinations.indexWhere(
              (Destination d) => d.chemin == chemin,
            );
            if (i == -1) return;
            GoRouter.of(context)
                .go(adresseDemoEnseignant(EcranDemoEnseignant.values[i]));
          },
          child: switch (situation) {
            SituationDemoCommunaute.aujourdhui => const JourneePage(),
            SituationDemoCommunaute.publication => CommunautePage(
              publicationId: DonneesCommunauteDemo.publicationOuverte,
              onRetour: () => GoRouter.of(
                context,
              ).go(adresseDemoCommunaute(SituationDemoCommunaute.aujourdhui)),
            ),
            _ => CommunautePage(
              // Le garde anti-promotion : la nouvelle publication s'ouvre
              // sur le brouillon marque.
              composerOuvert: situation.brouillon != null,
              onRetour: () => GoRouter.of(
                context,
              ).go(adresseDemoCommunaute(SituationDemoCommunaute.aujourdhui)),
            ),
          },
        ),
      ),
    );
  }
}
