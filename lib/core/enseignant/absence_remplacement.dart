/// `ENS-13` Absence sur une seance et `ENS-13B` offre de remplacement (EN-8).
///
/// Source : doc 04 §17 et R-ENS-18, 00_MAQUETTES (ENS-13, §4 point 5),
/// UX_REVIEW_04 lignes 14 et 15.
///
/// - L'absence porte sur **une** seance. La Classe permanente garde le meme
///   titulaire (R-ENS-18, §17.4) : rien ici ne touche a l'affectation.
/// - L'etat d'une absence est celui que rend le serveur (§17.2, E6). Flutter
///   ne le calcule jamais, et « Remplacant confirme » ne s'affiche que sur sa
///   reponse (E7).
/// - Aucun branchement serveur avant BR-1 (K-28) : en production, les ports
///   sont absents ([declarationAbsenceProvider] et [reponseRemplacementProvider]
///   valent `null`), donc l'action ne s'affiche pas et aucune offre n'arrive.
///   La demonstration (`/demo/enseignant`) les surcharge.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Les etats serveur d'une absence declaree (doc 04 §17.2).
enum EtatAbsence {
  /// `Absence enregistree`.
  enregistree,

  /// `Recherche d'un remplacant`.
  recherche,

  /// `Remplacant confirme` : seulement sur reponse du serveur (E7).
  remplacantConfirme,

  /// `Aucun remplacant confirme`.
  aucunRemplacant,

  /// `Seance annulee`.
  seanceAnnulee,

  /// `Demande annulee`.
  demandeAnnulee,
}

/// Une offre de remplacement : une seance d'une autre Classe a assurer.
///
/// Seules les donnees que la feuille montre (UX_REVIEW_04 ligne 15, a) : la
/// Classe, la date, l'heure locale, la duree et le nombre d'eleves. Ni le
/// motif de l'absence, ni aucune donnee des familles (E5).
@immutable
class OffreRemplacement {
  /// Cree l'offre.
  const OffreRemplacement({
    required this.seanceId,
    required this.classe,
    required this.debut,
    required this.fin,
    required this.nbEleves,
    this.groupeId,
  });

  /// La seance a assurer.
  final String seanceId;

  /// Le nom de la Classe.
  final String classe;

  /// Debut, en heure locale.
  final DateTime debut;

  /// Fin prevue, en heure locale.
  final DateTime fin;

  /// Le nombre d'eleves.
  final int nbEleves;

  /// La Classe remplacee : le remplacant y trouve l'objectif, le support, la
  /// reprise et les eleves (doc 04 §17.3, question §33 n. 11). `null` si le
  /// serveur ne la donne pas.
  final String? groupeId;
}

/// Le port de declaration d'une absence.
abstract interface class DeclarationAbsence {
  /// Declare l'absence du titulaire sur [seanceId] et rend l'etat que le
  /// serveur a enregistre, ou `null` si la demande n'a pas abouti.
  Future<EtatAbsence?> declarer(String seanceId);
}

/// Le port de reponse a une offre de remplacement.
abstract interface class ReponseRemplacement {
  /// Accepte [offre]. Vrai seulement si le serveur confirme le remplacant.
  Future<bool> assurer(OffreRemplacement offre);
}

/// Le port de declaration : absent avant BR-1, donc pas d'action affichee.
final Provider<DeclarationAbsence?> declarationAbsenceProvider =
    Provider<DeclarationAbsence?>((Ref _) => null);

/// Le port de reponse aux offres : absent avant BR-1.
final Provider<ReponseRemplacement?> reponseRemplacementProvider =
    Provider<ReponseRemplacement?>((Ref _) => null);

/// Les offres de remplacement recues : aucune avant BR-1.
final Provider<List<OffreRemplacement>> offresRemplacementProvider =
    Provider<List<OffreRemplacement>>((Ref _) => const <OffreRemplacement>[]);

/// Les etats d'absence rendus par le serveur, par seance.
class EtatsAbsenceControleur extends Notifier<Map<String, EtatAbsence>> {
  @override
  Map<String, EtatAbsence> build() => const <String, EtatAbsence>{};

  /// Retient l'etat que le serveur a rendu pour [seanceId].
  void retenir(String seanceId, EtatAbsence etat) =>
      state = <String, EtatAbsence>{...state, seanceId: etat};
}

/// Les etats d'absence connus.
final NotifierProvider<EtatsAbsenceControleur, Map<String, EtatAbsence>>
etatsAbsenceProvider =
    NotifierProvider<EtatsAbsenceControleur, Map<String, EtatAbsence>>(
      EtatsAbsenceControleur.new,
    );

/// Les remplacements confirmes par le serveur.
class RemplacementsControleur extends Notifier<List<OffreRemplacement>> {
  @override
  List<OffreRemplacement> build() => const <OffreRemplacement>[];

  /// Retient [offre], apres la confirmation du serveur seulement.
  void confirmer(OffreRemplacement offre) =>
      state = <OffreRemplacement>[...state, offre];
}

/// Les remplacements que l'enseignant assure.
final NotifierProvider<RemplacementsControleur, List<OffreRemplacement>>
remplacementsConfirmesProvider =
    NotifierProvider<RemplacementsControleur, List<OffreRemplacement>>(
      RemplacementsControleur.new,
    );
