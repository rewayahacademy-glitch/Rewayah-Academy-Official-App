/// ECHELLE-CTRL-DIRECT-1 : la mise en mots des regles et de l'historique des
/// tirages. Fonctions pures : l'ecran dit ce que le port rend.
library;

import '../../core/controle/port_tirage_controle.dart';
import '../../core/i18n/strings.g.dart';

String _deuxChiffres(int n) => n.toString().padLeft(2, '0');

/// « 10/10/2026 à 18:05 », en heure locale.
String libelleQuandTirage(DateTime date) {
  final DateTime d = date.toLocal();
  return t.admin.tirage.quand(
    date: '${_deuxChiffres(d.day)}/${_deuxChiffres(d.month)}/${d.year}',
    heure: '${_deuxChiffres(d.hour)}:${_deuxChiffres(d.minute)}',
  );
}

/// Le mot d'un critere de ponderation.
String libelleCritere(CriterePonderation c) => switch (c) {
  CriterePonderation.enseignantsRecents =>
    t.admin.tirage.critereEnseignantsRecents,
  CriterePonderation.classesSignalees => t.admin.tirage.critereClassesSignalees,
  CriterePonderation.heuresDePointe => t.admin.tirage.critereHeuresDePointe,
};

/// Le mot d'un poids.
String libelleNiveau(NiveauPonderation n) => switch (n) {
  NiveauPonderation.aucun => t.admin.tirage.niveauAucun,
  NiveauPonderation.normal => t.admin.tirage.niveauNormal,
  NiveauPonderation.fort => t.admin.tirage.niveauFort,
};

/// Le mot du statut d'un tirage.
String libelleStatutTirage(StatutTirage s) => switch (s) {
  StatutTirage.attribuee => t.admin.tirage.statutAttribuee,
  StatutTirage.enCours => t.admin.tirage.statutEnCours,
  StatutTirage.controlee => t.admin.tirage.statutControlee,
  StatutTirage.nonControlee => t.admin.tirage.statutNonControlee,
  StatutTirage.dejaControlee => t.admin.tirage.statutDejaControlee,
};

/// Pourquoi cette seance a ete tiree.
String libelleCritereTirage(CritereTirage c) => switch (c) {
  CritereTirage.aleatoire => t.admin.tirage.critereAleatoire,
  CritereTirage.ponderation => t.admin.tirage.criterePonderation,
  CritereTirage.cible => t.admin.tirage.critereCible,
};

/// « Classe » ou « Enseignant ».
String libelleTypeCible(TypeCible type) => switch (type) {
  TypeCible.classe => t.admin.tirage.cibleClasse,
  TypeCible.enseignant => t.admin.tirage.cibleEnseignant,
};

/// Les frequences proposees ; la carte « Autre » prend tout entier de
/// [missionsMin] a [missionsMax].
const List<int> frequencesProposees = <int>[0, 1, 2, 3, 5, 10];

/// Le nombre saisi, ou `null` s'il n'est pas un entier de [missionsMin] a
/// [missionsMax] (courtoisie : le serveur decide).
int? lireMissions(String? texte) {
  final String s = (texte ?? '').trim();
  if (!RegExp(r'^\d{1,3}$').hasMatch(s)) return null;
  final int n = int.parse(s);
  return n < missionsMin || n > missionsMax ? null : n;
}
