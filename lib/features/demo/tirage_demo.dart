// Le tirage des missions de controle de la demonstration (R18, BR-CT-02,
// BR-CT-03, BR-CT-15, BR-CT-18, `DECISION-CLASSES-SIMULTANEES-2026-10-10.md`).
//
// Donnees fictives, jamais envoyees au serveur (`surchargesDemoAdmin`, garde
// compilee `environnementAutoriseDemo`). **Le serveur portera, et la
// demonstration SIMULE** : le tirage lui-meme ([tirerMissions], atomique
// cote serveur par `FOR UPDATE SKIP LOCKED`), l'exclusion de la classe du
// controleur, un seul controle par classe, l'audit et le signalement d'une
// mission non controlee. Le controleur ne choisit jamais : il recoit zero ou
// une mission.

import 'dart:async';
import 'dart:math' as math;

import '../../core/controle/port_tirage_controle.dart';
import '../controleur/mission_controle.dart';

/// Une seance en direct, telle que le tirage la voit.
class SeanceEnDirect {
  /// Cree la seance.
  const SeanceEnDirect({
    required this.id,
    required this.classe,
    required this.enseignantId,
    required this.enseignant,
    this.numero,
    this.poids = 1,
  });

  /// L'identifiant de la seance.
  final String id;

  /// Le nom de la classe.
  final String classe;

  /// Son numero parmi les classes paralleles (R16).
  final int? numero;

  /// L'identifiant de son enseignant.
  final String enseignantId;

  /// Son enseignant, avec son titre.
  final String enseignant;

  /// Son poids dans le tirage (1 : normal, 0 : jamais, plus : plus de
  /// chances).
  final int poids;
}

/// Un controleur, et ce qui l'exclut du tirage.
class ControleurDemo {
  /// Cree le controleur.
  const ControleurDemo({
    required this.id,
    required this.libelle,
    this.enseigneId,
  });

  /// L'identifiant.
  final String id;

  /// Le nom que le serveur donne a la direction.
  final String libelle;

  /// L'identifiant d'enseignant quand le controleur enseigne aussi : ses
  /// classes sont exclues de ses missions (BR-CT-02).
  final String? enseigneId;
}

/// Une mission tiree : un controleur, une seance.
class MissionTiree {
  /// Cree la mission.
  const MissionTiree({required this.controleurId, required this.seanceId});

  /// Le controleur.
  final String controleurId;

  /// La seance.
  final String seanceId;
}

/// Tire au sort les missions. Chaque controleur recoit **au plus une**
/// mission ; jamais une seance dont il est l'enseignant (BR-CT-02) ; jamais
/// deux controleurs sur la meme seance (BR-CT-18) ; jamais une seance dont le
/// controle est deja ouvert ([controlesOuverts]) ; jamais pour un controleur
/// qui a atteint sa frequence ([missionsRecues] >= [parControleur]).
///
/// L'ordre des controleurs et le choix de la seance viennent de [hasard] :
/// aucun motif previsible. Les poids des seances ([SeanceEnDirect.poids])
/// orientent le choix sans le rendre previsible.
List<MissionTiree> tirerMissions({
  required List<SeanceEnDirect> seances,
  required List<ControleurDemo> controleurs,
  required math.Random hasard,
  Set<String> controlesOuverts = const <String>{},
  Map<String, int> missionsRecues = const <String, int>{},
  int parControleur = 1,
}) {
  final List<ControleurDemo> ordre = <ControleurDemo>[...controleurs]
    ..shuffle(hasard);
  final Set<String> prises = <String>{...controlesOuverts};
  final List<MissionTiree> missions = <MissionTiree>[];
  for (final ControleurDemo c in ordre) {
    if ((missionsRecues[c.id] ?? 0) >= parControleur) continue;
    final List<SeanceEnDirect> eligibles = <SeanceEnDirect>[
      for (final SeanceEnDirect s in seances)
        if (!prises.contains(s.id) &&
            s.poids > 0 &&
            (c.enseigneId == null || c.enseigneId != s.enseignantId))
          s,
    ];
    if (eligibles.isEmpty) continue;
    final int total = eligibles.fold<int>(
      0,
      (int n, SeanceEnDirect s) => n + s.poids,
    );
    int curseur = hasard.nextInt(total);
    SeanceEnDirect choisie = eligibles.last;
    for (final SeanceEnDirect s in eligibles) {
      if (curseur < s.poids) {
        choisie = s;
        break;
      }
      curseur -= s.poids;
    }
    prises.add(choisie.id);
    missions.add(MissionTiree(controleurId: c.id, seanceId: choisie.id));
  }
  return missions;
}

/// Les trente classes paralleles « Garcons debutants », lundi 18 h, en
/// direct ensemble : trente seances, douze enseignants.
List<SeanceEnDirect> seancesSimultaneesDemo({int nombre = 30}) =>
    <SeanceEnDirect>[
      for (int n = 1; n <= nombre; n++)
        SeanceEnDirect(
          id: 'demo-seance-$n',
          classe: 'Garçons débutants · n° $n',
          numero: n,
          enseignantId: 'demo-ens-${n % 12}',
          enseignant: _titres[n % _titres.length],
        ),
    ];

const List<String> _titres = <String>[
  'Sayyid Ibrahim',
  'Sayyid Yusuf',
  'Sayyida Maryam',
  'Sayyid Bilal',
  'Sayyida Khadija',
  'Sayyid Omar',
  'Sayyida Amina',
  'Sayyid Hamza',
  'Sayyida Inès',
  'Sayyid Idris',
  'Sayyida Nour',
  'Sayyid Zakaria',
];

/// Les trois controleurs de la demonstration : le deuxieme enseigne aussi
/// (sa propre classe est exclue de ses missions).
const List<ControleurDemo> controleursDemo = <ControleurDemo>[
  ControleurDemo(id: 'demo-ctrl-1', libelle: 'Contrôleur 1'),
  ControleurDemo(
    id: 'demo-ctrl-2',
    libelle: 'Contrôleur 2',
    enseigneId: 'demo-ens-5',
  ),
  ControleurDemo(id: 'demo-ctrl-3', libelle: 'Contrôleur 3'),
];

/// La mission que voit un controleur : la seance tiree, sans autre choix.
MissionControle missionVueParLeControleur(
  SeanceEnDirect s, {
  required DateTime debut,
  EtatMissionControle etat = EtatMissionControle.enDirect,
}) => MissionControle(
  seanceId: s.id,
  classe: 'Garçons débutants',
  numeroDansFamille: s.numero,
  enseignant: s.enseignant,
  nombreEleves: 5,
  debut: debut,
  finPrevue: debut.add(const Duration(hours: 1)),
  etat: etat,
);

/// Le port de demonstration : les regles en memoire, l'historique de douze
/// semaines de tirages, des pannes et des capacites reglables.
class TirageDemo implements PortTirageControle {
  /// Cree le port.
  TirageDemo({
    this.acces$ = const AccesTirage(peutLire: true, peutModifier: true),
    ReglesTirage? regles,
    this.latence = Duration.zero,
    this.horsLigne = false,
    this.ecritureEnPanne = false,
    List<TirageAudite>? historique,
  }) : _regles = regles ?? reglesParDefautDemo(),
       _historique = historique ?? historiqueDemo();

  /// Ce que la personne connectee peut faire (modifiable en test).
  AccesTirage acces$;

  /// Le delai de chaque reponse.
  final Duration latence;

  /// Vrai : aucune lecture n'aboutit.
  bool horsLigne;

  /// Vrai : aucune ecriture n'aboutit (la reponse n'arrive pas).
  bool ecritureEnPanne;

  ReglesTirage _regles;
  final List<TirageAudite> _historique;
  final Map<String, ResultatRegles> _parCle = <String, ResultatRegles>{};

  /// Les cles d'envoi recues, dans l'ordre.
  final List<String> clesRecues = <String>[];

  /// Le nombre d'enregistrements reellement faits (double appui : un seul).
  int enregistrementsFaits = 0;

  /// Le nombre de pages reellement demandees.
  int pagesDemandees = 0;

  /// Les regles en vigueur.
  ReglesTirage get reglesCourantes => _regles;

  Future<void> _attendre() async {
    if (latence > Duration.zero) await Future<void>.delayed(latence);
    if (horsLigne) throw StateError('Aucune reponse du serveur.');
  }

  @override
  Future<AccesTirage> acces() async {
    await _attendre();
    return acces$;
  }

  @override
  Future<ReglesTirage> regles() async {
    await _attendre();
    return _regles;
  }

  @override
  Future<ResultatRegles> enregistrer(
    ReglesTirage regles, {
    required String cleEnvoi,
  }) async {
    clesRecues.add(cleEnvoi);
    await _attendre();
    if (ecritureEnPanne) throw StateError('Aucune reponse du serveur.');
    final ResultatRegles? deja = _parCle[cleEnvoi];
    if (deja != null) return deja;
    final ResultatRegles resultat;
    if (!acces$.peutModifier) {
      resultat = const ReglesRefusees(
        'votre compte ne peut pas modifier ces règles',
      );
    } else {
      _regles = regles;
      enregistrementsFaits++;
      resultat = const ReglesEnregistrees();
    }
    _parCle[cleEnvoi] = resultat;
    return resultat;
  }

  @override
  Future<List<CibleTirage>> candidatsCible() async {
    await _attendre();
    final List<SeanceEnDirect> seances = seancesSimultaneesDemo();
    return <CibleTirage>[
      for (final SeanceEnDirect s in seances.take(6))
        CibleTirage(id: s.id, type: TypeCible.classe, libelle: s.classe),
      for (final SeanceEnDirect s in seances.take(4))
        CibleTirage(
          id: s.enseignantId,
          type: TypeCible.enseignant,
          libelle: s.enseignant,
        ),
    ];
  }

  @override
  Future<PageTirages> tirages(
    FiltreTirages filtre, {
    required int page,
    required int taille,
  }) async {
    pagesDemandees++;
    await _attendre();
    return paginerTirages(_historique, filtre, page: page, taille: taille);
  }
}

/// Les regles de depart : une mission par semaine, poids normaux, aucune
/// cible.
ReglesTirage reglesParDefautDemo() => const ReglesTirage(
  missionsParSemaine: 1,
  ponderations: <CriterePonderation, NiveauPonderation>{
    CriterePonderation.enseignantsRecents: NiveauPonderation.normal,
    CriterePonderation.classesSignalees: NiveauPonderation.fort,
    CriterePonderation.heuresDePointe: NiveauPonderation.normal,
  },
  cibles: <CibleTirage>[],
);

/// Douze semaines de tirages, trois controleurs chacune : de quoi paginer
/// (36 lignes), avec des missions non controlees (rapport envoye, BR-CT-15),
/// des classes deja controlees (BR-CT-18) et des controles en cours.
/// Deterministe : le meme historique a chaque appel.
List<TirageAudite> historiqueDemo({int semaines = 12}) {
  final List<SeanceEnDirect> seances = seancesSimultaneesDemo();
  final math.Random hasard = math.Random(18);
  final List<TirageAudite> lignes = <TirageAudite>[];
  final DateTime depart = DateTime(2026, 7, 20, 18);
  for (int semaine = 0; semaine < semaines; semaine++) {
    final DateTime quand = depart.add(Duration(days: 7 * semaine));
    final List<MissionTiree> missions = tirerMissions(
      seances: seances,
      controleurs: controleursDemo,
      hasard: hasard,
    );
    for (final MissionTiree m in missions) {
      final SeanceEnDirect s = seances.firstWhere(
        (SeanceEnDirect x) => x.id == m.seanceId,
      );
      final ControleurDemo c = controleursDemo.firstWhere(
        (ControleurDemo x) => x.id == m.controleurId,
      );
      final int tirage = hasard.nextInt(20);
      final StatutTirage statut = switch (tirage) {
        < 11 => StatutTirage.controlee,
        < 15 => StatutTirage.nonControlee,
        < 17 => StatutTirage.dejaControlee,
        < 19 => StatutTirage.attribuee,
        _ => StatutTirage.enCours,
      };
      lignes.add(
        TirageAudite(
          id: 'tirage-$semaine-${c.id}',
          quand: quand,
          classe: 'Garçons débutants · n° ${s.numero}',
          enseignant: s.enseignant,
          controleur: c.libelle,
          statut: statut,
          critere: switch (hasard.nextInt(6)) {
            0 => CritereTirage.cible,
            < 3 => CritereTirage.ponderation,
            _ => CritereTirage.aleatoire,
          },
          rapportEnvoye: statut == StatutTirage.nonControlee,
        ),
      );
    }
  }
  return lignes;
}
