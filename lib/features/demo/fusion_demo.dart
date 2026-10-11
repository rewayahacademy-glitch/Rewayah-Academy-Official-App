// La fusion de classes paralleles, le transfert d'un eleve et l'historique de
// la demonstration admin (R5, R9, R10,
// `DECISION-CLASSES-SIMULTANEES-2026-10-10.md`).
//
// Donnees fictives, jamais envoyees au serveur (`surchargesDemoAdmin`, garde
// compilee `environnementAutoriseDemo`). Le serveur portera, et la
// demonstration SIMULE : les classes cibles (meme horaire, meme categorie,
// meme genre, assez de place), l'apercu des effets, l'atomicite (la fusion
// deplace tous les eleves d'un coup), l'idempotence par cle d'envoi, le
// refus d'un chevauchement (R5 : l'eleve n° 4 de chaque classe suit un autre
// cours au meme moment) et l'historique. Les prenoms sont fictifs.

import 'dart:async';

import '../../core/admin/port_classes_admin.dart';
import '../../core/admin/port_fusion_classes.dart';
import '../../core/admin/service_groupes.dart';

const List<String> _prenoms = <String>[
  'Aïcha',
  'Bilal',
  'Chaïma',
  'Driss',
  'Émilie',
  'Farid',
  'Ghita',
  'Hamza',
  'Inès',
  'Jawad',
];

/// Le prenom fictif de l'eleve [rang] d'une classe.
String prenomDemo(int rang) => _prenoms[rang % _prenoms.length];

/// L'eleve qui, en demonstration, suit un autre cours au meme moment que
/// n'importe quelle classe cible : son transfert est refuse (R5). C'est
/// l'eleve n° 4 de sa classe d'origine.
bool eleveChevauche(String eleveId) => eleveId.endsWith('-e3');

/// Le port de demonstration : en memoire, avec une latence, une panne de
/// lecture et une panne d'ecriture reglables.
class FusionDemo implements PortFusionClasses {
  /// Cree le port. [classes] rend les classes **avant** tout mouvement
  /// (`ClassesAdminDemo.toutesBrutes`).
  FusionDemo({
    required this.classes,
    DateTime Function()? horloge,
    this.latence = Duration.zero,
    this.horsLigne = false,
    this.ecritureEnPanne = false,
  }) : _horloge = horloge ?? DateTime.now;

  /// Les classes de la demonstration, avant tout mouvement.
  final List<ClasseListee> Function() classes;
  final DateTime Function() _horloge;

  /// Le delai de chaque reponse.
  final Duration latence;

  /// Vrai : aucune lecture n'aboutit.
  bool horsLigne;

  /// Vrai : aucune ecriture n'aboutit (la reponse n'arrive pas).
  bool ecritureEnPanne;

  /// Les eleves deplaces : leur classe d'arrivee, par identifiant d'eleve.
  final Map<String, String> _deplaces = <String, String>{};

  /// Les classes fusionnees : elles sont closes.
  final Set<String> _fermees = <String>{};
  final Map<String, ClasseListee> _cache = <String, ClasseListee>{};
  final Map<String, Object> _parCle = <String, Object>{};
  final List<(String, EvenementClasse)> _historique =
      <(String, EvenementClasse)>[];

  /// Le nombre de fusions reellement faites (double appui : une seule).
  int fusionsFaites = 0;

  /// Le nombre de transferts reellement faits.
  int transfertsFaits = 0;

  /// Le nombre d'ecritures recues, abouties ou non.
  int ecrituresRecues = 0;

  /// Les cles d'envoi recues, dans l'ordre.
  final List<String> clesRecues = <String>[];

  Future<void> _lire() async {
    if (latence > Duration.zero) await Future<void>.delayed(latence);
    if (horsLigne) throw StateError('Aucune reponse du serveur.');
  }

  Future<void> _ecrire(String cle) async {
    ecrituresRecues++;
    clesRecues.add(cle);
    if (latence > Duration.zero) await Future<void>.delayed(latence);
    if (horsLigne || ecritureEnPanne) {
      throw StateError('Aucune reponse du serveur.');
    }
  }

  ClasseListee _classe(String id) {
    final ClasseListee? c = _cache[id];
    if (c != null) return c;
    for (final ClasseListee x in classes()) {
      _cache[x.id] = x;
    }
    return _cache[id] ?? (throw StateError('Classe inconnue : $id'));
  }

  /// Les eleves de [classeId] apres les mouvements deja faits.
  List<MembreTransferable> membresDe(String classeId) {
    final ClasseListee c = _classe(classeId);
    return <MembreTransferable>[
      for (int i = 0; i < c.groupe.nombreMembres; i++)
        if ((_deplaces['$classeId-e$i'] ?? classeId) == classeId)
          MembreTransferable(eleveId: '$classeId-e$i', prenom: prenomDemo(i)),
      for (final MapEntry<String, String> e in _deplaces.entries)
        if (e.value == classeId && !e.key.startsWith('$classeId-'))
          MembreTransferable(eleveId: e.key, prenom: prenomDemo(_rang(e.key))),
    ];
  }

  int _rang(String eleveId) =>
      int.tryParse(eleveId.substring(eleveId.lastIndexOf('-e') + 2)) ?? 0;

  /// L'effectif de [classeId] apres les mouvements deja faits.
  int nombre(String classeId) => membresDe(classeId).length;

  /// Vrai quand [classeId] a ete fusionnee dans une autre.
  bool estFermee(String classeId) => _fermees.contains(classeId);

  /// Ce que la demonstration a change a une classe : son effectif et son
  /// etat (`ClassesAdminDemo.ajuster`). Les capacites et le reste de la
  /// ligne ne bougent pas.
  ClasseListee ajuster(ClasseListee c) {
    final GroupeAdmin g = c.groupe;
    final int effectif = nombre(c.id);
    final bool ferme = estFermee(c.id);
    if (effectif == g.nombreMembres && !ferme) return c;
    return ClasseListee(
      groupe: GroupeAdmin(
        id: g.id,
        libelle: g.libelle,
        type: g.type,
        seuilMax: g.seuilMax,
        teacherId: g.teacherId,
        teacherIdentifiant: g.teacherIdentifiant,
        teacherPrenom: g.teacherPrenom,
        teacherNom: g.teacherNom,
        creneau: g.creneau,
        nombreMembres: effectif,
        actif: g.actif && !ferme,
      ),
      numeroDansFamille: c.numeroDansFamille,
      codeCourt: c.codeCourt,
      genre: c.genre,
      sansEnseignant: c.sansEnseignant,
      peutAffecterEnseignant: c.peutAffecterEnseignant,
      peutFusionner: c.peutFusionner,
      peutTransferer: c.peutTransferer,
    );
  }

  ClasseCible _cible(ClasseListee c) => ClasseCible(
    classeId: c.id,
    nom: c.nom,
    enseignant: c.enseignant,
    membres: nombre(c.id),
    capacite: c.groupe.seuilMax,
  );

  @override
  Future<List<ClasseCible>> classesCibles(
    String classeId, {
    int? eleves,
  }) async {
    await _lire();
    final ClasseListee source = _classe(classeId);
    final int besoin = eleves ?? nombre(classeId);
    final List<ClasseCible> cibles = <ClasseCible>[
      for (final ClasseListee c in classes())
        if (c.id != classeId &&
            c.groupe.actif &&
            !estFermee(c.id) &&
            c.groupe.creneau.jour == source.groupe.creneau.jour &&
            c.groupe.creneau.heure == source.groupe.creneau.heure &&
            c.groupe.creneau.fuseau == source.groupe.creneau.fuseau &&
            c.groupe.type == source.groupe.type &&
            c.genre == source.genre &&
            c.groupe.seuilMax - nombre(c.id) >= besoin)
          _cible(c),
    ]..sort((ClasseCible a, ClasseCible b) => a.nom.compareTo(b.nom));
    return cibles;
  }

  @override
  Future<ApercuFusion> apercu({
    required String sourceId,
    required String cibleId,
  }) async {
    await _lire();
    final ClasseListee source = _classe(sourceId);
    final int n = nombre(sourceId);
    return ApercuFusion(
      sourceNom: source.nom,
      cible: _cible(_classe(cibleId)),
      membresDeplaces: n,
      enseignantLibere: source.enseignant,
      // Les freres et soeurs partagent une famille : moins de familles que
      // d'eleves (simule).
      famillesNotifiees: (n * 3 + 3) ~/ 4,
    );
  }

  void _tracer(
    String classeId,
    TypeEvenementClasse type,
    String autre, {
    int? nombre,
    String? prenom,
  }) {
    _historique.add((
      classeId,
      EvenementClasse(
        id: 'evt-${_historique.length + 1}',
        type: type,
        quand: _horloge(),
        autreClasse: autre,
        nombre: nombre,
        prenom: prenom,
      ),
    ));
  }

  @override
  Future<ResultatFusion> fusionner({
    required String sourceId,
    required String cibleId,
    required String cleEnvoi,
  }) async {
    await _ecrire(cleEnvoi);
    // Idempotence : la meme cle rend la meme reponse.
    final Object? deja = _parCle[cleEnvoi];
    if (deja is ResultatFusion) return deja;
    final ResultatFusion resultat;
    if (estFermee(sourceId)) {
      resultat = const FusionDejaFaite();
    } else {
      final ClasseListee source = _classe(sourceId);
      final ClasseListee cible = _classe(cibleId);
      final List<MembreTransferable> membres = membresDe(sourceId);
      if (cible.groupe.seuilMax - nombre(cibleId) < membres.length) {
        resultat = const FusionRefusee(
          "la classe qui accueille n'a plus assez de place",
        );
      } else {
        for (final MembreTransferable m in membres) {
          _deplaces[m.eleveId] = cibleId;
        }
        _fermees.add(sourceId);
        fusionsFaites++;
        _tracer(
          sourceId,
          TypeEvenementClasse.fusionSortante,
          cible.nom,
          nombre: membres.length,
        );
        _tracer(
          cibleId,
          TypeEvenementClasse.fusionEntrante,
          source.nom,
          nombre: membres.length,
        );
        resultat = FusionFaite(
          cibleNom: cible.nom,
          elevesDeplaces: membres.length,
        );
      }
    }
    _parCle[cleEnvoi] = resultat;
    return resultat;
  }

  @override
  Future<List<MembreTransferable>> membres(String classeId) async {
    await _lire();
    return membresDe(classeId);
  }

  @override
  Future<ResultatTransfert> transferer({
    required String eleveId,
    required String sourceId,
    required String cibleId,
    required String cleEnvoi,
  }) async {
    await _ecrire(cleEnvoi);
    final Object? deja = _parCle[cleEnvoi];
    if (deja is ResultatTransfert) return deja;
    final ClasseListee source = _classe(sourceId);
    final ClasseListee cible = _classe(cibleId);
    final MembreTransferable? eleve = membresDe(sourceId)
        .where((MembreTransferable m) => m.eleveId == eleveId)
        .firstOrNull;
    final ResultatTransfert resultat;
    if (eleve == null) {
      resultat = const TransfertDejaFait();
    } else if (eleveChevauche(eleveId)) {
      resultat = const TransfertRefuse(RaisonRefusTransfert.chevauchement);
    } else if (cible.groupe.seuilMax - nombre(cibleId) < 1) {
      resultat = const TransfertRefuse(RaisonRefusTransfert.classePleine);
    } else {
      _deplaces[eleveId] = cibleId;
      transfertsFaits++;
      _tracer(
        sourceId,
        TypeEvenementClasse.transfertSortant,
        cible.nom,
        prenom: eleve.prenom,
      );
      _tracer(
        cibleId,
        TypeEvenementClasse.transfertEntrant,
        source.nom,
        prenom: eleve.prenom,
      );
      resultat = TransfertFait(prenom: eleve.prenom, cibleNom: cible.nom);
    }
    _parCle[cleEnvoi] = resultat;
    return resultat;
  }

  @override
  Future<List<EvenementClasse>> historique(String classeId) async {
    await _lire();
    return <EvenementClasse>[
      for (final (String id, EvenementClasse e) in _historique.reversed)
        if (id == classeId) e,
    ];
  }
}
