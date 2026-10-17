/// ECHELLE-ADM-FUSION-1 : la mise en mots de la fusion, du transfert et de
/// l'historique. Fonctions pures : l'ecran dit ce que le port rend.
library;

import '../../core/admin/port_fusion_classes.dart';
import '../../core/i18n/strings.g.dart';

String _deuxChiffres(int n) => n.toString().padLeft(2, '0');

/// « 10/10/2026 à 18:05 » : la date et l'heure d'un evenement, telles que le
/// serveur les a tracees, en heure locale.
String libelleQuand(DateTime date) {
  final DateTime d = date.toLocal();
  return t.commun.formats.dateHeure(
    date: '${_deuxChiffres(d.day)}/${_deuxChiffres(d.month)}/${d.year}',
    heure: '${_deuxChiffres(d.hour)}:${_deuxChiffres(d.minute)}',
  );
}

/// La phrase d'un evenement de l'historique d'une classe.
String libelleEvenement(EvenementClasse e) => switch (e.type) {
  TypeEvenementClasse.fusionSortante => t.admin.fusion.evenementFusionSortante(
    n: e.nombre ?? 0,
    autre: e.autreClasse,
  ),
  TypeEvenementClasse.fusionEntrante => t.admin.fusion.evenementFusionEntrante(
    n: e.nombre ?? 0,
    autre: e.autreClasse,
  ),
  TypeEvenementClasse.transfertSortant =>
    t.admin.fusion.evenementTransfertSortant(
      prenom: e.prenom ?? '',
      autre: e.autreClasse,
    ),
  TypeEvenementClasse.transfertEntrant =>
    t.admin.fusion.evenementTransfertEntrant(
      prenom: e.prenom ?? '',
      autre: e.autreClasse,
    ),
};

/// La detail d'une classe cible : ses places libres, puis son enseignant (ou
/// l'absence d'enseignant).
String libelleDetailCible(ClasseCible c) =>
    '${t.admin.fusion.placesLibres(n: c.places)} · '
    '${c.enseignant == null ? t.admin.fusion.sansEnseignant : t.admin.fusion.enseignantDe(nom: c.enseignant!)}';

/// La phrase d'un refus de transfert.
String libelleRefusTransfert(
  TransfertRefuse refus, {
  required String prenom,
  required String cible,
}) => switch (refus.raison) {
  RaisonRefusTransfert.chevauchement => t.admin.fusion.refusChevauchement(
    prenom: prenom,
    cible: cible,
  ),
  RaisonRefusTransfert.classePleine => t.admin.fusion.refusClassePleine(
    cible: cible,
  ),
  RaisonRefusTransfert.autre => t.admin.fusion.refusAutre(
    motif: refus.motif ?? '',
  ),
};
