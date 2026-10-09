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
import '../../core/offres/port_regroupements_admin.dart';

/// Le quota de demonstration d'un public (valeurs d'`app_config` au 09/10).
int quotaDemo(PublicOffre public) => switch (public) {
  PublicOffre.enfants => 5,
  PublicOffre.adultes => 6,
};

/// Les regroupements fictifs : un pret, des incomplets, un qui passe minuit
/// dans un autre fuseau.
List<RegroupementDemandes> regroupementsDemo() => <RegroupementDemandes>[
  RegroupementDemandes(
    id: 'demo-reg-enfants-fr-lmj-18',
    public: PublicOffre.enfants,
    langueCode: 'fr',
    langueNom: 'Français',
    jours: const <int>[1, 2, 4],
    reference: const HeureDansFuseau(fuseau: 'Europe/Paris', heure: 18),
    autresFuseaux: const <HeureDansFuseau>[
      HeureDansFuseau(fuseau: 'Europe/London', heure: 17),
      HeureDansFuseau(fuseau: 'America/Toronto', heure: 12),
    ],
    nombreEleves: 5,
    quota: quotaDemo(PublicOffre.enfants),
    peutCreerClasse: true,
  ),
  RegroupementDemandes(
    id: 'demo-reg-adultes-fr-sam-10',
    public: PublicOffre.adultes,
    langueCode: 'fr',
    langueNom: 'Français',
    jours: const <int>[6],
    reference: const HeureDansFuseau(
      fuseau: 'Europe/Paris',
      heure: 10,
      minute: 30,
    ),
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
    jours: const <int>[3],
    reference: const HeureDansFuseau(fuseau: 'America/Toronto', heure: 17),
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
    jours: const <int>[2, 4],
    reference: const HeureDansFuseau(fuseau: 'America/Los_Angeles', heure: 20),
    autresFuseaux: const <HeureDansFuseau>[
      HeureDansFuseau(fuseau: 'Europe/Paris', heure: 5, decalageJour: 1),
    ],
    nombreEleves: 6,
    quota: quotaDemo(PublicOffre.adultes),
    peutCreerClasse: true,
  ),
];

/// Le port de demonstration : en memoire, avec une latence et une panne
/// reglables, et un second membre de la direction simule
/// ([creerParUnAutre]) pour la creation concurrente.
class RegroupementsDemo implements PortRegroupementsAdmin {
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
            jours: r.jours,
            reference: r.reference,
            autresFuseaux: r.autresFuseaux,
            nombreEleves: r.nombreEleves,
            quota: r.quota,
            peutCreerClasse: r.peutCreerClasse,
            classe: classe,
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

  ClasseCreee _creer(String regroupementId, GenreClasse genre, String libelle) {
    final RegroupementDemandes r = _regroupements.firstWhere(
      (RegroupementDemandes r) => r.id == regroupementId,
    );
    final ClasseSansEnseignant classe = ClasseSansEnseignant(
      classeId: 'demo-classe-regroupee-${_classes.length + 1}',
      libelle: libelle,
      genre: genre,
      peutAffecterEnseignant: true,
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
    if (_affectees.contains(classeId)) return ResultatAffectation.dejaAffecte;
    _affectees.add(classeId);
    enseignantDe[classeId] = enseignantId;
    return ResultatAffectation.affecte;
  }
}
