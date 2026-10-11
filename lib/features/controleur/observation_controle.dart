// L'observation structuree du controleur (CTR-03A, CT-5, doc 08 P-CTR-05) :
// nature, domaine, personne concernee, texte. Brouillon en memoire seulement
// (C12) : rien n'est persiste, rien ne part avant « Envoyer le compte rendu ».
//
// Le roster autorise est neutre par defaut : aucun eleve, aucun appel serveur
// (K-28). La source reelle (BR-1, `14_controleur/CT-BR.md`) se branche dans
// `main.dart` ; la demonstration le surcharge.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/controle/modele_observation_controle.dart';

export '../../core/controle/modele_observation_controle.dart';

/// Le texte est obligatoire pour une intervention de l'administration et pour
/// un point important ; facultatif sinon (choix provisoire, question 3).
bool texteObligatoire({
  required bool important,
  required NatureObservation? nature,
}) => important || nature == NatureObservation.interventionAdmin;

/// Le roster autorise de la visite de la seance donnee, lu PAR SEANCE
/// (CTRL-SEANCE-1) : l'observation de la Classe A ne propose jamais les
/// prenoms de la Classe B. **Neutre par defaut** : aucun eleve.
final FutureProviderFamily<List<EleveRoster>, String> rosterControleProvider =
    FutureProvider.family<List<EleveRoster>, String>(
      (Ref _, String _) async => const <EleveRoster>[],
    );
