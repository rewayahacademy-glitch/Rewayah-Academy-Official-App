// La coquille enseignant en demonstration : /demo/enseignant (hors production,
// EN-1b).
//
// Sans parametre : les liens ecran x situation. Avec `ecran` (aujourdhui,
// classes, disponibilites, profil) et `etat` (nominal, vide, horsLigne) : la
// VRAIE coquille (`NavShell`, destinations de `destinationsPour`) et la VRAIE
// page de la destination, ses providers surcharges par un ProviderScope sur
// les donnees d'enseignant_demo.dart (K-35). Les fournisseurs reels restent en
// place, aucun port reseau n'est modifie : aucun appel serveur (K-28).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../core/capacites/port_revenus_enseignant.dart';
import '../../core/domain/enums.dart';
import '../../core/enseignant/absence_remplacement.dart';
import '../../core/enseignant/depot_cahiers.dart';
import '../../core/enseignant/modeles_enseignant.dart';
import '../../core/enseignant/port_remplacements.dart';
import '../../core/enseignant/service_enseignant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/mouvement/mouvement.dart';
import '../../core/offres/service_offres.dart' show languesCoursProvider;
import '../../core/planning/service_planning.dart';
import '../../core/presence/service_presence.dart';
import '../../core/priere/service_priere.dart';
import '../../core/profil/service_acceptations.dart';
import '../../core/profil/service_declaration.dart';
import '../../core/profil/service_profil_enseignant.dart';
import '../../core/recrutement/port_signature_contrat.dart';
import '../../core/regles/service_regles.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/tc_groupe/group_summary_vm.dart' show TitreEnseignant;
import '../../core/tc_horloge/emplacement_entree.dart' show RoleEntree;
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/pre_vol.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/nav_shell.dart';
import '../../core/widgets/page_shell.dart';
import '../bienvenue_enseignant/bienvenue_page.dart';
import '../cahier/cahier_page.dart';
import '../cahier/vue_cahier.dart';
import '../creneaux/creneaux_page.dart';
import '../enseignant_classes/mes_classes_page.dart';
import '../journee/journee_page.dart';
import '../profil_enseignant/photo_publique.dart';
import '../profil_enseignant/profil_enseignant_page.dart';
import '../revenus_enseignant/revenus_enseignant_page.dart';
import 'classe_demo.dart' show DonneesClasseDemo, EtatDemoClasse;
import 'demo_classe_page.dart' show adresseDemoClasse;
import 'enseignant_demo.dart';
import 'finance_demo.dart' show RevenusEnseignantDemo;
import 'mode_demonstration.dart';
import 'recrutement_demo.dart';
import 'remplacements_demo.dart';
import 'repere_demonstration.dart';

/// Les routes de la demonstration enseignant : AUCUNE en production.
List<RouteBase> routesDemoEnseignant(String environnement) {
  if (!environnementAutoriseDemo(environnement)) return const <RouteBase>[];
  return <RouteBase>[
    GoRoute(
      path: Routes.demoEnseignant,
      builder: (BuildContext _, GoRouterState etat) => DemoEnseignantPage(
        ecran: _lire(
          EcranDemoEnseignant.values,
          etat.uri.queryParameters['ecran'],
        ),
        etat:
            _lire(
              EtatDemoEnseignant.values,
              etat.uri.queryParameters['etat'],
            ) ??
            EtatDemoEnseignant.nominal,
        titre: etat.uri.queryParameters['titre'] == 'sayyida'
            ? TitreEnseignant.sayyida
            : TitreEnseignant.sayyid,
      ),
    ),
  ];
}

T? _lire<T extends Enum>(List<T> valeurs, String? nom) {
  for (final T v in valeurs) {
    if (v.name == nom) return v;
  }
  return null;
}

/// L'adresse d'un ecran de la demonstration.
String adresseDemoEnseignant(
  EcranDemoEnseignant ecran, {
  EtatDemoEnseignant etat = EtatDemoEnseignant.nominal,
}) => Uri(
  path: Routes.demoEnseignant,
  queryParameters: <String, String>{'ecran': ecran.name, 'etat': etat.name},
).toString();

/// Le libelle d'un ecran : celui de sa destination dans la barre.
String libelleEcranDemoEnseignant(EcranDemoEnseignant ecran) => switch (ecran) {
  EcranDemoEnseignant.aujourdhui => t.nav.enseignant.journee,
  EcranDemoEnseignant.classes => t.nav.enseignant.classes,
  EcranDemoEnseignant.disponibilites => t.nav.enseignant.creneaux,
  EcranDemoEnseignant.premiersPas => t.enseignant.bienvenue.titre,
  EcranDemoEnseignant.cahier => t.enseignant.cahier.titre,
  EcranDemoEnseignant.profil => t.nav.enseignant.profil,
  EcranDemoEnseignant.revenus => t.enseignant.revenus.titre,
};

/// Le libelle d'une situation.
String libelleEtatDemoEnseignant(EtatDemoEnseignant etat) => switch (etat) {
  EtatDemoEnseignant.nominal => t.enseignant.demo.etatNominal,
  EtatDemoEnseignant.vide => t.enseignant.demo.etatVide,
  EtatDemoEnseignant.horsLigne => t.enseignant.demo.etatHorsLigne,
};

/// La session de demonstration : un enseignant resolu, sans source serveur.
class _SessionEnseignantDemo extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.teacher,
    profileId: DonneesEnseignantDemo.enseignantId,
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );
}

/// Les surcharges de la coquille enseignant pour une situation : seuls les
/// providers lus par les pages sont remplaces, aucun port reseau.
///
/// Les familles sont surchargees a leur argument exact : sous un ProviderScope
/// imbrique, une famille non surchargee se resoudrait dans le conteneur
/// racine, ou la session n'a pas d'enseignant.
List<Override> surchargesCoquilleEnseignantDemo(EtatDemoEnseignant etat) {
  const String id = DonneesEnseignantDemo.enseignantId;
  final bool vide = etat == EtatDemoEnseignant.vide;
  final List<SeanceEnseignant> seances = DonneesEnseignantDemo.seances(etat);
  final PortRemplacementsDemo remplacements = PortRemplacementsDemo(
    tableau: vide
        ? TableauRemplacementsDemo(
            const <(OffreRemplacement, PublicClasseDemo, String?)>[],
          )
        : TableauRemplacementsDemo.demonstration(),
    enseignantId: id,
    genre: GenreEnseignantDemo.homme,
    horsLigne: etat == EtatDemoEnseignant.horsLigne,
  );
  return <Override>[
    sessionProvider.overrideWith(_SessionEnseignantDemo.new),
    horsLigneProvider.overrideWith(
      (Ref _) => Stream<bool>.value(etat == EtatDemoEnseignant.horsLigne),
    ),
    // Aujourd'hui (ENS-02), a l'heure fixe de la demonstration (lundi
    // 28 septembre 2026, 16 h) : les seances fictives restent a venir.
    maintenantJourneeProvider.overrideWithValue(
      () => DonneesEnseignantDemo.maintenant,
    ),
    seancesEnseignantProvider.overrideWith((Ref _) async => seances),
    // Absence et remplacement (ENS-13, ENS-13B, EN-8) : des reponses
    // simulees qui ne quittent pas l'appareil (K-28). Hors ligne, aucune
    // reponse, donc aucun etat (E7).
    declarationAbsenceProvider.overrideWithValue(
      DeclarationAbsenceDemo(horsLigne: etat == EtatDemoEnseignant.horsLigne),
    ),
    reponseRemplacementProvider.overrideWithValue(
      ReponseRemplacementDemo(horsLigne: etat == EtatDemoEnseignant.horsLigne),
    ),
    // REMPL-1 : le tableau commun des remplacements, filtre par genre et
    // premier arrive, premier servi, simule sur l'appareil (K-28). Le genre
    // est un parametre de la demonstration (Sayyid : un enseignant). C'est
    // la seule source des offres (REMPL-1b) : l'Alerte utile de la Journee
    // et l'ecran commun le lisent tous deux.
    portRemplacementsProvider.overrideWithValue(remplacements),
    // Surcharge aussi : sous ce ProviderScope imbrique, le flux se
    // resoudrait sinon dans le conteneur racine, ou le port est absent, et
    // l'Alerte utile de la Journee resterait vide.
    offresCommunesProvider.overrideWith((Ref _) => remplacements.suivre()),
    // Classes (ENS-09) : les quatre Classes, leur niveau, leur langue et le
    // remplacement d'Al-Fatiha. Le cahier non valide d'Al-Badr vient de
    // `cahiersEnRetardProvider`, plus bas.
    groupesEnseignantProvider.overrideWith(
      (Ref _) async =>
          vide ? const <GroupeEnseignant>[] : DonneesEnseignantDemo.groupes(),
    ),
    detailsClassesProvider.overrideWithValue(<String, DetailClasse>{
      for (final ClasseEnseignantDemo c in DonneesEnseignantDemo.classes)
        c.id: DetailClasse(
          niveau: c.niveau,
          langue: c.langue,
          remplacement: c.remplacement,
        ),
    }),
    cahiersEnRetardProvider.overrideWith(
      (Ref _) async => DonneesEnseignantDemo.cahiersEnRetard(etat),
    ),
    reglagesPriereProvider(id).overrideWith((Ref _) async => null),
    valeurRegleProvider((profilId: id, cle: CleRegle.pauseEntreCours))
        .overrideWith((Ref _) async => 10),
    preVolProvider.overrideWith(
      (Ref _) async => const ResultatPreVol(
        microDisponible: true,
        cameraDisponible: true,
        sortieAudioDisponible: true,
        permissionRefusee: false,
      ),
    ),
    for (final SeanceEnseignant s in seances)
      presenceSeanceProvider(
        s.id,
      ).overrideWith((Ref _) => Stream<List<PresenceParticipant>?>.value(null)),
    // Disponibilites (ENS-06), hebdomadaires et sans date (E15).
    monFuseauProvider.overrideWith(
      (Ref _) async => DonneesEnseignantDemo.fuseau,
    ),
    disponibilitesProvider(id).overrideWith(
      (Ref _) async =>
          vide ? const <Creneau>[] : DonneesEnseignantDemo.disponibilites,
    ),
    affectationsProvider.overrideWith((Ref _) async => const <Affectation>[]),
    // Classes disponibles (ENS-06), une par etat.
    offresClassesProvider.overrideWithValue(
      vide ? const <OffreClasseDemo>[] : DonneesEnseignantDemo.offres,
    ),
    // Mes revenus (FI-10) : le double de la Finance (FI-BR-11), calcule dans
    // la demonstration, jamais dans l'ecran. Le provider de l'ecran est
    // surcharge aussi : sous ce ProviderScope imbrique, il se resoudrait
    // sinon dans le conteneur racine, ou le port reste indisponible.
    portRevenusEnseignantProvider.overrideWithValue(
      RevenusEnseignantDemo(vide: vide),
    ),
    moisRevenusProvider.overrideWith(MoisRevenusDemo.new),
    moisRevenusDisponiblesProvider.overrideWith(
      (Ref ref) => ref.watch(portRevenusEnseignantProvider).moisDisponibles(),
    ),
    revenusEnseignantProvider.overrideWith(
      (Ref ref) => lireRevenus(
        ref.watch(portRevenusEnseignantProvider),
        ref.watch(moisRevenusProvider),
      ),
    ),
    // Le releve aussi : resolu a la racine, il lisait la session de
    // l'application, et son echec s'affichait « Impossible de charger » au
    // lieu de l'etat honnete du port, « pas encore disponible » (R5-03).
    releveEnseignantProvider.overrideWith(
      (Ref ref) => ref.watch(portRevenusEnseignantProvider).releve(),
    ),
    // Profil (ENS-05).
    // Pays et langues se choisissent (FORM-L8) : l'ecriture reste sur
    // l'appareil (K-28) et le profil relu la reflete. Les langues proposees
    // sont celles que la base publie a sa creation (`0043`).
    profilEnseignantProvider.overrideWith(
      (Ref ref) async => ref.watch(declarationEnseignantDemoProvider).profil,
    ),
    serviceDeclarationProvider.overrideWith(
      (Ref ref) => ref.watch(declarationEnseignantDemoProvider),
    ),
    languesCoursProvider.overrideWith(
      (Ref _) async => DonneesEnseignantDemo.languesCours,
    ),
    // Le nom public avec son titre (R18), que le modele ne porte pas encore.
    nomPublicEnseignantProvider.overrideWithValue(
      DonneesEnseignantDemo.nomAffiche(TitreEnseignant.sayyid),
    ),
    acceptationsProvider.overrideWith(
      (Ref _) async => DonneesEnseignantDemo.acceptations,
    ),
    // Photo publique (ENS-05A) : sans photo au depart, un choix et un envoi
    // fictifs qui ne quittent pas l'appareil (K-28).
    photoPubliqueProvider.overrideWith(PhotoPubliqueControleur.new),
    choixPhotoPubliqueProvider.overrideWithValue(const _ChoixPhotoDemo()),
    envoiPhotoPubliqueProvider.overrideWithValue(const _EnvoiPhotoDemo()),
    // RECRUT-ECRANS : la signature du contrat d'enseignant, en memoire.
    portSignatureContratProvider.overrideWithValue(SignatureContratDemo()),
    // Premiers pas (ENS-01) : la photo manque, le reste est confirme (sauf
    // les disponibilites dans la situation vide).
    prerequisEnseignantProvider.overrideWith(
      (Ref ref) => PrerequisEnseignant(
        photo: ref.watch(photoPubliqueProvider) != null,
        langues: DonneesEnseignantDemo.profil.langues.isNotEmpty,
        fuseau: true,
        disponibilites: !vide,
      ),
    ),
  ];
}

/// Le choix de photo de la demonstration : aucun fichier, les initiales en
/// repli, comme toutes les photos de demonstration.
class _ChoixPhotoDemo implements ChoixPhotoPublique {
  const _ChoixPhotoDemo();

  @override
  Future<PhotoChoisie?> choisir() async => const PhotoChoisie();
}

/// La declaration d'absence de la demonstration (ENS-13, EN-8) : rien ne
/// part. L'etat n'arrive qu'apres la reponse simulee ; hors ligne, aucune
/// reponse, donc aucun etat (E7).
class DeclarationAbsenceDemo implements DeclarationAbsence {
  /// Cree le port ; [horsLigne] simule l'absence de reponse.
  const DeclarationAbsenceDemo({this.horsLigne = false});

  /// Vrai quand l'appareil est hors ligne.
  final bool horsLigne;

  @override
  Future<EtatAbsence?> declarer(String seanceId) =>
      Future<EtatAbsence?>.delayed(
        Mouvement.maximum,
        () => horsLigne ? null : DonneesEnseignantDemo.etatAbsenceDeclaree,
      );
}

/// La reponse aux offres de la demonstration (ENS-13B, EN-8) : rien ne part.
/// La confirmation n'arrive qu'apres la reponse simulee ; hors ligne, jamais.
class ReponseRemplacementDemo implements ReponseRemplacement {
  /// Cree le port ; [horsLigne] simule l'absence de reponse.
  const ReponseRemplacementDemo({this.horsLigne = false});

  /// Vrai quand l'appareil est hors ligne.
  final bool horsLigne;

  @override
  Future<bool> assurer(OffreRemplacement offre) =>
      Future<bool>.delayed(Mouvement.maximum, () => !horsLigne);
}

/// L'envoi de la demonstration : rien ne part, la cle est fictive. Le succes
/// n'arrive qu'apres la reponse simulee, jamais avant.
class _EnvoiPhotoDemo implements EnvoiPhotoPublique {
  const _EnvoiPhotoDemo();

  @override
  Future<String> envoyer(PhotoChoisie photo) => Future<String>.delayed(
    Mouvement.maximum,
    () => 'demo/enseignant/${DonneesEnseignantDemo.enseignantId}.png',
  );
}

/// La page : la liste des ecrans, ou la coquille sur l'ecran choisi.
class DemoEnseignantPage extends StatelessWidget {
  /// Cree la page.
  const DemoEnseignantPage({
    this.ecran,
    this.etat = EtatDemoEnseignant.nominal,
    this.titre = TitreEnseignant.sayyid,
    super.key,
  });

  /// L'ecran choisi, ou nul pour la liste.
  final EcranDemoEnseignant? ecran;

  /// La situation.
  final EtatDemoEnseignant etat;

  /// Le titre de l'enseignant : Sayyid par defaut, Sayyida en variante.
  final TitreEnseignant titre;

  @override
  Widget build(BuildContext context) {
    final EcranDemoEnseignant? e = ecran;
    if (e != null) return CoquilleEnseignantDemo(ecran: e, etat: etat);

    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    Text texte(String valeur, {bool fort = false}) => Text(
      valeur,
      style: (fort ? palette.inkStrong : palette.inkMuted).applyTo(
        (fort ? textes.titleMedium : textes.bodyMedium) ?? const TextStyle(),
      ),
    );
    return PageShell(
      titre: t.enseignant.demo.titre,
      sousTitre: t.enseignant.demo.mention,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          texte(t.enseignant.demo.intro),
          for (final EcranDemoEnseignant ecran
              in EcranDemoEnseignant.values) ...<Widget>[
            Ecart.vXxl,
            Semantics(
              header: true,
              child: texte(libelleEcranDemoEnseignant(ecran), fort: true),
            ),
            Ecart.vMd,
            for (final EtatDemoEnseignant etat in EtatDemoEnseignant.values)
              LienFleche(
                key: ValueKey<String>('lien-${ecran.name}-${etat.name}'),
                libelle: libelleEtatDemoEnseignant(etat),
                onPress: () =>
                    context.go(adresseDemoEnseignant(ecran, etat: etat)),
              ),
          ],
        ],
      ),
    );
  }
}

/// La VRAIE coquille enseignant, sur la VRAIE page de [ecran], ses providers
/// surcharges par les donnees de demonstration.
class CoquilleEnseignantDemo extends StatelessWidget {
  /// Cree la coquille.
  const CoquilleEnseignantDemo({
    required this.ecran,
    this.etat = EtatDemoEnseignant.nominal,
    super.key,
  });

  /// L'ecran affiche, donc la destination active.
  final EcranDemoEnseignant ecran;

  /// La situation.
  final EtatDemoEnseignant etat;

  @override
  Widget build(BuildContext context) {
    // Premiers pas : un flux d'activation, sans barre ni destination active
    // (00_MAQUETTES planche 1, R4).
    // Cahier de seance (ENS-04) : l'ecran de sortie de seance, sans barre
    // (planche 4, R5). Aucune ecriture ne part (K-28).
    if (ecran == EcranDemoEnseignant.cahier) {
      return ProviderScope(
        key: ValueKey<EtatDemoEnseignant>(etat),
        overrides: <Override>[
          ...surchargesCoquilleEnseignantDemo(etat),
          ...surchargesCahierDemo(etat),
        ],
        child: const RepereDemonstration(
          child: CahierPage(seanceId: DonneesEnseignantDemo.cahierDemoSeanceId),
        ),
      );
    }
    if (ecran == EcranDemoEnseignant.premiersPas) {
      return ProviderScope(
        key: ValueKey<EtatDemoEnseignant>(etat),
        overrides: surchargesCoquilleEnseignantDemo(etat),
        child: const RepereDemonstration(child: BienvenueEnseignantPage()),
      );
    }
    final List<Destination> destinations = destinationsPour(
      role: AppRole.teacher,
      mode: InterfaceMode.standard,
    );
    return ProviderScope(
      key: ValueKey<EtatDemoEnseignant>(etat),
      overrides: surchargesCoquilleEnseignantDemo(etat),
      child: RepereDemonstration(
        child: NavShell(
          destinations: destinations,
          // Mes revenus est une pose de la branche Profil.
          indexActif: ecran == EcranDemoEnseignant.revenus
              ? EcranDemoEnseignant.profil.index
              : ecran.index,
          libellesDansLeRail: true,
          onAller: (String chemin) {
            final int i = destinations.indexWhere(
              (Destination d) => d.chemin == chemin,
            );
            if (i == -1) return;
            context.go(
              adresseDemoEnseignant(EcranDemoEnseignant.values[i], etat: etat),
            );
          },
          child: switch (ecran) {
            EcranDemoEnseignant.aujourdhui => const JourneePage(),
            // An-Nour ouvre le VRAI Espace Classe enseignant de la
            // demonstration de Classe (CL-4, perfectionne en EN-3), avant sa
            // fenetre (E11, R4 : « Preparer la seance ») ; les autres Classes
            // n'ont pas de donnees de Classe et ne s'ouvrent pas (E3).
            EcranDemoEnseignant.classes => MesClassesPage(
              ouvrable: (String id) => id == DonneesClasseDemo.groupeId,
              onOuvrirClasse: (String id) {
                if (id != DonneesClasseDemo.groupeId) return;
                context.go(
                  adresseDemoClasse(
                    RoleEntree.enseignant,
                    EtatDemoClasse.aVenir,
                  ),
                );
              },
            ),
            EcranDemoEnseignant.disponibilites => const CreneauxPage(),
            EcranDemoEnseignant.profil => ProfilEnseignantPage(
              onOuvrirRevenus: (BuildContext c) => c.go(
                adresseDemoEnseignant(EcranDemoEnseignant.revenus, etat: etat),
              ),
            ),
            EcranDemoEnseignant.revenus => RevenusEnseignantPage(
              onRetour: () => context.go(
                adresseDemoEnseignant(EcranDemoEnseignant.profil, etat: etat),
              ),
            ),
            // Rendu plus haut, hors de la coquille.
            EcranDemoEnseignant.premiersPas ||
            EcranDemoEnseignant.cahier => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

/// Les surcharges du cahier de demonstration (ENS-04, EN-7) : le brouillon
/// d'Al-Badr, une soumission fictive et l'horloge de la demonstration.
///
/// Situation `vide` : aucun constat. Situation `horsLigne` : le cahier reste
/// en file, et l'ecran dit « En attente d'envoi », jamais « Cahier
/// enregistre » (doc 04 §20.8).
List<Override> surchargesCahierDemo(
  EtatDemoEnseignant etat, {
  bool deja = false,
}) => <Override>[
  brouillonCahierProvider(DonneesEnseignantDemo.cahierDemoSeanceId)
      .overrideWith(
        (Ref _) async => etat == EtatDemoEnseignant.vide
            ? null
            : DonneesEnseignantDemo.brouillonCahier(deja: deja),
      ),
  soumissionCahierProvider.overrideWithValue(
    SoumissionCahierDemo(enFile: etat == EtatDemoEnseignant.horsLigne),
  ),
  horlogeCahierProvider.overrideWithValue(
    () => DonneesEnseignantDemo.maintenant,
  ),
];

/// La soumission de la demonstration : rien ne part. Le sort n'arrive
/// qu'apres la reponse simulee, jamais avant (E7).
class SoumissionCahierDemo implements SoumissionCahier {
  /// Cree la soumission ; [enFile] simule une file hors ligne.
  const SoumissionCahierDemo({this.enFile = false});

  /// Vrai quand le cahier reste en file locale.
  final bool enFile;

  @override
  Future<SortCahier> soumettre(CahierARendre cahier) =>
      Future<SortCahier>.delayed(
        Mouvement.maximum,
        () => enFile ? SortCahier.enFile : SortCahier.envoye,
      );

  @override
  Future<int> rejouer() async => 0;
}

/// La declaration de la demonstration : pays et langues gardes en memoire,
/// jamais envoyes (K-28). Le profil relu part de celui de la demonstration.
class DeclarationEnseignantDemo implements ServiceDeclarationEnseignant {
  String? _pays = DonneesEnseignantDemo.profil.pays;
  List<String> _langues = DonneesEnseignantDemo.profil.langues;

  /// Le profil tel que la demonstration le relit apres une ecriture.
  ProfilEnseignant get profil {
    const ProfilEnseignant base = DonneesEnseignantDemo.profil;
    return ProfilEnseignant(
      prenom: base.prenom,
      identifiant: base.identifiant,
      pays: _pays,
      langues: _langues,
      plafondHeures: base.plafondHeures,
      statutCompte: base.statutCompte,
      verification: base.verification,
    );
  }

  @override
  Future<void> declarer({String? pays, List<String>? langues}) async {
    _pays = pays ?? _pays;
    _langues = langues ?? _langues;
  }
}

/// Une declaration par conteneur de demonstration.
final Provider<DeclarationEnseignantDemo> declarationEnseignantDemoProvider =
    Provider<DeclarationEnseignantDemo>((Ref _) => DeclarationEnseignantDemo());
