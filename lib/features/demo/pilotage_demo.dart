// Le tableau de pilotage de la demonstration admin a grande echelle (R7, R9,
// R17, R19, `DECISION-CLASSES-SIMULTANEES-2026-10-10.md`).
//
// Donnees fictives, jamais envoyees au serveur (`surchargesDemoAdmin`, garde
// compilee `environnementAutoriseDemo`). Les lignes sont **calculees a la
// demande** a partir des classes (`ClassesAdminDemo`) et des demandes
// reunies (`RegroupementsDemo`) de la meme demonstration : confirmer un
// enseignant fait donc bouger le tableau. Les enseignants libres, le minimum
// d'une classe et la pagination sont SIMULES ici ; le serveur les portera
// (ligne Contrats de ECHELLE-ADM-PILOTAGE-1). Aucun nom d'eleve.

import 'dart:async';

import '../../core/admin/port_classes_admin.dart';
import '../../core/admin/port_pilotage.dart';
import '../../core/admin/service_groupes.dart' show TypePublicGroupe;
import '../../core/capacites/port_enseignants_classe.dart' show GenreClasse;
import '../../core/offres/offre_horaire.dart' show PublicOffre;
import '../../core/offres/port_regroupements_admin.dart';
import '../../core/planning/service_planning.dart' show Creneau;
import 'regroupements_demo.dart' show minimumDemo;

/// Une valeur stable d'une cle : la somme de ses unites de code. Pas de
/// hasard, pas de `hashCode` : la meme cle donne le meme nombre d'une
/// execution a l'autre.
int _graine(String cle) =>
    cle.codeUnits.fold<int>(0, (int somme, int u) => somme * 31 + u) &
    0x7fffffff;

PublicOffre _offre(TypePublicGroupe t) => switch (t) {
  TypePublicGroupe.enfant => PublicOffre.enfants,
  TypePublicGroupe.adulte => PublicOffre.adultes,
};

class _Cumul {
  _Cumul(this.creneau, this.type);

  final Creneau creneau;
  final TypePublicGroupe type;
  int classes = 0;
  int effectif = 0;
  int capacite = 0;
  int sousMinimum = 0;
  int attente = 0;
  int attenteHommes = 0;
  int attenteFemmes = 0;
  int attenteSansGenre = 0;
  int demandes = 0;
  int classesAOuvrir = 0;
}

/// Les lignes du tableau, calculees des classes et des demandes reunies.
List<LignePilotage> lignesPilotageDemo({
  required List<ClasseListee> classes,
  required List<RegroupementDemandes> regroupements,
}) {
  final Map<String, _Cumul> cumuls = <String, _Cumul>{};
  _Cumul cumul(Creneau c, TypePublicGroupe t) => cumuls.putIfAbsent(
    '${c.jour}|${c.heure}|${c.fuseau}|${t.name}',
    () => _Cumul(c, t),
  );
  for (final ClasseListee c in classes) {
    final GroupeAdminSimple g = (
      creneau: c.groupe.creneau,
      type: c.groupe.type,
      actif: c.groupe.actif,
    );
    if (!g.actif) continue;
    final _Cumul x = cumul(g.creneau, g.type);
    x.classes++;
    x.effectif += c.groupe.nombreMembres;
    x.capacite += c.groupe.seuilMax;
    if (c.groupe.nombreMembres < minimumDemo(_offre(g.type))) x.sousMinimum++;
    if (c.sansEnseignant) {
      x.attente++;
      switch (c.genre) {
        case GenreClasse.hommes:
          x.attenteHommes++;
        case GenreClasse.femmes:
          x.attenteFemmes++;
        case GenreClasse.indetermine || null:
          x.attenteSansGenre++;
      }
    }
  }
  for (final RegroupementDemandes r in regroupements) {
    if (r.classe != null || r.occurrences.isEmpty) continue;
    final OccurrenceCreneau o = r.occurrences.first;
    final _Cumul x = cumul(
      Creneau(jour: o.jourIso, heure: o.heure, fuseau: r.fuseau),
      r.public == PublicOffre.enfants
          ? TypePublicGroupe.enfant
          : TypePublicGroupe.adulte,
    );
    x.demandes += r.nombreEleves;
    x.classesAOuvrir += r.decoupage.classes;
  }
  return <LignePilotage>[
    for (final MapEntry<String, _Cumul> e in cumuls.entries)
      _ligne(e.key, e.value),
  ];
}

typedef GroupeAdminSimple = ({
  Creneau creneau,
  TypePublicGroupe type,
  bool actif,
});

LignePilotage _ligne(String cle, _Cumul x) {
  final int graine = _graine(cle);
  // Les enseignants libres a cet horaire, par genre (simule).
  int libresH = graine % 3;
  int libresF = (graine ~/ 3) % 3;
  final int manquantsH = x.attenteHommes > libresH
      ? x.attenteHommes - libresH
      : 0;
  final int manquantsF = x.attenteFemmes > libresF
      ? x.attenteFemmes - libresF
      : 0;
  libresH = libresH > x.attenteHommes ? libresH - x.attenteHommes : 0;
  libresF = libresF > x.attenteFemmes ? libresF - x.attenteFemmes : 0;
  // Les classes dont le genre n'est pas connu, et celles que les demandes
  // ouvriront, se couvrent avec ce qui reste, tous genres confondus.
  final int sansGenre = x.attenteSansGenre + x.classesAOuvrir;
  final int restants = libresH + libresF;
  final int manquantsSansGenre = sansGenre > restants
      ? sansGenre - restants
      : 0;
  return LignePilotage(
    id: cle,
    creneau: x.creneau,
    type: x.type,
    classes: x.classes,
    effectif: x.effectif,
    capacite: x.capacite,
    classesSousMinimum: x.sousMinimum,
    classesAttenteEnseignant: x.attente,
    demandesEnAttente: x.demandes,
    parGenre: <EnseignantsGenre>[
      EnseignantsGenre(
        genre: GenreClasse.hommes,
        libres: libresH,
        manquants: manquantsH,
      ),
      EnseignantsGenre(
        genre: GenreClasse.femmes,
        libres: libresF,
        manquants: manquantsF,
      ),
      if (manquantsSansGenre > 0)
        EnseignantsGenre(
          genre: GenreClasse.indetermine,
          libres: 0,
          manquants: manquantsSansGenre,
        ),
    ],
  );
}

/// Le port de demonstration : les lignes se recalculent a chaque lecture
/// depuis les classes et les demandes reunies de la demonstration, puis se
/// paginent en memoire comme le serveur le fera en SQL.
class PilotageDemo implements PortPilotage {
  /// Cree le port. [classes] et [regroupements] lisent l'etat courant de la
  /// demonstration.
  PilotageDemo({
    required this.classes,
    required this.regroupements,
    this.latence = Duration.zero,
    this.horsLigne = false,
  });

  /// Les classes de la demonstration.
  final List<ClasseListee> Function() classes;

  /// Les demandes reunies de la demonstration.
  final Future<List<RegroupementDemandes>> Function() regroupements;

  /// Le delai de chaque reponse.
  final Duration latence;

  /// Vrai : aucune reponse n'arrive (l'appel echoue).
  bool horsLigne;

  /// Le nombre de pages reellement demandees.
  int pagesDemandees = 0;

  @override
  Future<PagePilotage> page(
    FiltrePilotage filtre, {
    required int page,
    required int taille,
  }) async {
    pagesDemandees++;
    if (latence > Duration.zero) await Future<void>.delayed(latence);
    if (horsLigne) throw StateError('Aucune reponse du serveur.');
    return paginerPilotage(
      lignesPilotageDemo(
        classes: classes(),
        regroupements: await regroupements(),
      ),
      filtre,
      page: page,
      taille: taille,
    );
  }
}
