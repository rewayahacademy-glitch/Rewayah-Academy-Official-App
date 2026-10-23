// Regroupements de demandes du mode demonstration admin (OFFRES-ADM-1).
//
// Donnees fictives, jamais envoyees au serveur (`surchargesDemoAdmin`, garde
// compilee `environnementAutoriseDemo`). Le regroupement, le quota (5 enfants,
// 6 adultes, les valeurs d'`app_config` au 09/10), les heures dans les autres
// fuseaux et l'atomicite de la creation sont SIMULES ici ; le serveur les
// portera (lignes Backend d'OFFRES-ADM-1). Aucun nom d'eleve : le port n'en
// rend pas.

import 'dart:async';

import '../../core/capacites/port_enseignants_classe.dart' show GenreClasse;
import '../../core/offres/offre_horaire.dart' show PublicOffre;
import '../../core/offres/page_regroupements.dart';
import '../../core/offres/port_regroupements_admin.dart';

/// Le quota de demonstration d'un public (valeurs d'`app_config` au 09/10).
int quotaDemo(PublicOffre public) => switch (public) {
  PublicOffre.enfants => 5,
  PublicOffre.adultes => 6,
};

/// Le minimum de demonstration d'un public (R3 ; valeurs d'`app_config`
/// simulees, le serveur les portera).
int minimumDemo(PublicOffre public) => switch (public) {
  PublicOffre.enfants => 3,
  PublicOffre.adultes => 4,
};

/// Le nombre d'eleves de la demonstration a grande echelle (R17).
const int elevesVolumeDemo = 10000;

/// Un grand volume de demandes reunies : [eleves] demandes en tout,
/// reparties sur les jours, les heures, trois fuseaux, deux publics et trois
/// langues, avec des effectifs qui vont du reste isole a plusieurs classes
/// pleines. Deterministe : la meme liste a chaque appel.
List<RegroupementDemandes> regroupementsVolumeDemo({
  int eleves = elevesVolumeDemo,
}) {
  const List<int> effectifs = <int>[4, 9, 14, 23, 31, 12, 7, 19, 2, 27];
  const List<String> fuseaux = <String>[
    'Europe/Paris',
    'Europe/London',
    'America/Toronto',
  ];
  const List<(String, String)> langues = <(String, String)>[
    ('fr', 'Français'),
    ('en', 'English'),
    ('ar', 'العربية'),
  ];
  final List<RegroupementDemandes> liste = <RegroupementDemandes>[];
  int reste = eleves;
  for (int i = 0; reste > 0; i++) {
    final int n = effectifs[i % effectifs.length].clamp(1, reste);
    reste -= n;
    final PublicOffre public = i.isEven
        ? PublicOffre.enfants
        : PublicOffre.adultes;
    final int jour = i % 7 + 1;
    final int heure = 9 + (i ~/ 7) % 13;
    final (String, String) langue = langues[(i ~/ 3) % langues.length];
    liste.add(
      RegroupementDemandes(
        id: 'demo-reg-volume-$i',
        public: public,
        langueCode: langue.$1,
        langueNom: langue.$2,
        fuseau: fuseaux[(i ~/ 91) % fuseaux.length],
        occurrences: <OccurrenceCreneau>[
          OccurrenceCreneau(jourIso: jour, heure: heure),
          if (i % 4 == 0)
            OccurrenceCreneau(jourIso: (jour + 2 - 1) % 7 + 1, heure: heure),
        ],
        nombreEleves: n,
        quota: quotaDemo(public),
        minimum: minimumDemo(public),
        classesExistantes: i % 5,
        peutCreerClasse: true,
      ),
    );
  }
  return liste;
}

/// Les regroupements fictifs : un pret, des incomplets, un qui passe minuit
/// dans un autre fuseau.
List<RegroupementDemandes> regroupementsDemo() => <RegroupementDemandes>[
  RegroupementDemandes(
    id: 'demo-reg-enfants-fr-lmj-18',
    public: PublicOffre.enfants,
    langueCode: 'fr',
    langueNom: 'Français',
    fuseau: 'Europe/Paris',
    occurrences: const <OccurrenceCreneau>[
      OccurrenceCreneau(jourIso: 1, heure: 18),
      OccurrenceCreneau(jourIso: 2, heure: 18),
      OccurrenceCreneau(jourIso: 4, heure: 18),
    ],
    autresFuseaux: const <HeureDansFuseau>[
      HeureDansFuseau(fuseau: 'Europe/London', heure: 17),
      HeureDansFuseau(fuseau: 'America/Toronto', heure: 12),
    ],
    nombreEleves: 5,
    quota: quotaDemo(PublicOffre.enfants),
    peutCreerClasse: true,
    // R16 : trois classes paralleles existent deja sur cette cle.
    numeroProchaineClasse: 4,
    classesExistantes: 3,
    minimum: minimumDemo(PublicOffre.enfants),
  ),
  RegroupementDemandes(
    id: 'demo-reg-adultes-fr-sam-10',
    public: PublicOffre.adultes,
    langueCode: 'fr',
    langueNom: 'Français',
    fuseau: 'Europe/Paris',
    occurrences: const <OccurrenceCreneau>[
      OccurrenceCreneau(jourIso: 6, heure: 10, minute: 30),
    ],
    autresFuseaux: const <HeureDansFuseau>[
      HeureDansFuseau(fuseau: 'America/Toronto', heure: 4, minute: 30),
    ],
    nombreEleves: 4,
    quota: quotaDemo(PublicOffre.adultes),
    peutCreerClasse: true,
  ),
  RegroupementDemandes(
    id: 'demo-reg-enfants-ar-mer-17',
    public: PublicOffre.enfants,
    langueCode: 'ar',
    langueNom: 'العربية',
    fuseau: 'America/Toronto',
    occurrences: const <OccurrenceCreneau>[
      OccurrenceCreneau(jourIso: 3, heure: 17),
    ],
    autresFuseaux: const <HeureDansFuseau>[
      HeureDansFuseau(fuseau: 'Europe/Paris', heure: 23),
    ],
    nombreEleves: 2,
    quota: quotaDemo(PublicOffre.enfants),
    peutCreerClasse: true,
  ),
  RegroupementDemandes(
    id: 'demo-reg-adultes-en-mj-20',
    public: PublicOffre.adultes,
    langueCode: 'en',
    langueNom: 'English',
    fuseau: 'America/Los_Angeles',
    // C-11 bis : une heure differente selon le jour, et dans l'autre
    // fuseau une heure par jour.
    occurrences: const <OccurrenceCreneau>[
      OccurrenceCreneau(jourIso: 2, heure: 20),
      OccurrenceCreneau(jourIso: 4, heure: 20, minute: 30),
    ],
    autresFuseaux: const <HeureDansFuseau>[
      HeureDansFuseau(
        fuseau: 'Europe/Paris',
        heure: 5,
        decalageJour: 1,
        jourIso: 2,
      ),
      HeureDansFuseau(
        fuseau: 'Europe/Paris',
        heure: 5,
        minute: 30,
        decalageJour: 1,
        jourIso: 4,
      ),
    ],
    nombreEleves: 6,
    quota: quotaDemo(PublicOffre.adultes),
    peutCreerClasse: true,
  ),
];

/// Le port de demonstration : en memoire, avec une latence et une panne
/// reglables, et un second membre de la direction simule
/// ([creerParUnAutre]) pour la creation concurrente.
class RegroupementsDemo
    implements PortRegroupementsAdmin, PortRegroupementsPages {
  /// Cree le port.
  RegroupementsDemo({
    List<RegroupementDemandes>? depart,
    this.latence = Duration.zero,
    this.horsLigne = false,
  }) : _regroupements = depart ?? regroupementsDemo();

  final List<RegroupementDemandes> _regroupements;

  /// Le delai de chaque reponse.
  final Duration latence;

  /// Vrai : aucune reponse n'arrive (l'appel echoue).
  bool horsLigne;

  final Map<String, ClasseSansEnseignant> _classes =
      <String, ClasseSansEnseignant>{};
  final Map<String, ResultatCreationClasse> _parCle =
      <String, ResultatCreationClasse>{};
  final Set<String> _affectees = <String>{};

  /// Le nombre de creations reellement recues (double appui : une seule).
  int creationsRecues = 0;

  /// Les cles d'envoi recues, dans l'ordre (une par creation recue).
  final List<String> clesRecues = <String>[];

  /// Le nombre de confirmations d'enseignant reellement recues.
  int affectationsRecues = 0;

  /// L'enseignant retenu par classe.
  final Map<String, String> enseignantDe = <String, String>{};

  Future<void> _attendre() async {
    if (latence > Duration.zero) await Future<void>.delayed(latence);
    if (horsLigne) throw StateError('Aucune reponse du serveur.');
  }

  RegroupementDemandes _avecClasse(RegroupementDemandes r) {
    final ClasseSansEnseignant? classe = _classes[r.id];
    return classe == null
        ? r
        : RegroupementDemandes(
            id: r.id,
            public: r.public,
            langueCode: r.langueCode,
            langueNom: r.langueNom,
            fuseau: r.fuseau,
            occurrences: r.occurrences,
            autresFuseaux: r.autresFuseaux,
            nombreEleves: r.nombreEleves,
            quota: r.quota,
            peutCreerClasse: r.peutCreerClasse,
            classe: classe,
            classesPossibles: r.classesPossibles,
            numeroProchaineClasse: r.numeroProchaineClasse,
            minimum: r.minimum,
            classesExistantes: r.classesExistantes,
          );
  }

  @override
  Future<List<RegroupementDemandes>> regroupements() async {
    await _attendre();
    return <RegroupementDemandes>[
      for (final RegroupementDemandes r in _regroupements)
        if (!_affectees.contains(_classes[r.id]?.classeId)) _avecClasse(r),
    ];
  }

  /// Le nombre de pages reellement demandees (R17 : une page a la fois, jamais
  /// la liste entiere).
  int pagesDemandees = 0;

  @override
  Future<PageRegroupements> page(
    FiltreRegroupements filtre, {
    required int page,
    required int taille,
  }) async {
    pagesDemandees++;
    return paginerRegroupements(
      await regroupements(),
      filtre,
      page: page,
      taille: taille,
    );
  }

  ClasseCreee _creer(String regroupementId, GenreClasse genre, String libelle) {
    final RegroupementDemandes r = _regroupements.firstWhere(
      (RegroupementDemandes r) => r.id == regroupementId,
    );
    final ClasseSansEnseignant classe = ClasseSansEnseignant(
      classeId: 'demo-classe-regroupee-${_classes.length + 1}',
      libelle: libelle,
      genre: genre,
      peutAffecterEnseignant: true,
      numeroDansFamille: r.numeroProchaineClasse,
    );
    _classes[regroupementId] = classe;
    return ClasseCreee(classe: classe, elevesIntegres: r.nombreEleves);
  }

  /// Un autre membre de la direction cree la classe de [regroupementId]
  /// (creation concurrente simulee).
  void creerParUnAutre(String regroupementId) {
    if (_classes.containsKey(regroupementId)) return;
    _creer(regroupementId, GenreClasse.indetermine, 'Classe');
  }

  @override
  Future<ResultatCreationClasse> creerClasse({
    required String regroupementId,
    required GenreClasse genre,
    required String libelle,
    required String cleEnvoi,
  }) async {
    creationsRecues++;
    clesRecues.add(cleEnvoi);
    await _attendre();
    // Idempotence : la meme cle rend la meme reponse.
    final ResultatCreationClasse? deja = _parCle[cleEnvoi];
    if (deja != null) return deja;
    final ResultatCreationClasse resultat = _classes.containsKey(regroupementId)
        ? const CreationDejaFaite()
        : _creer(regroupementId, genre, libelle);
    _parCle[cleEnvoi] = resultat;
    return resultat;
  }

  @override
  Future<ResultatAffectation> affecterEnseignant({
    required String classeId,
    required String enseignantId,
  }) async {
    affectationsRecues++;
    await _attendre();
    // Comme le serveur (C11BIS-AFFECTATION) : le meme enseignant rejoue
    // (reponse perdue, puis nouvel appui) est deja en place, rien ne change
    // et la reponse est `affecte` ; un autre enseignant deja confirme rend
    // `dejaAffecte`.
    if (_affectees.contains(classeId)) {
      return enseignantDe[classeId] == enseignantId
          ? ResultatAffectation.affecte
          : ResultatAffectation.dejaAffecte;
    }
    _affectees.add(classeId);
    enseignantDe[classeId] = enseignantId;
    return ResultatAffectation.affecte;
  }
}
