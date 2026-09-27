import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';

/// Le geste « Observer la seance », tel que l'ecran qui l'a recu le transmet a
/// la porte d'observation.
///
/// **Un objet sans donnee, et c'est ce qui le rend sur.** Passe en `extra`, il
/// vit dans la navigation en cours et nulle part ailleurs : `go_router` ne sait
/// pas l'ecrire dans l'historique du navigateur (ce n'est pas du JSON), il le
/// perd donc au rechargement, au retour arriere et sur un lien direct. La porte
/// n'entre d'elle-meme QUE s'il est present, et seulement quand l'explication a
/// deja ete lue (logigramme V7 : « Explication deja vue » -> connexion). Sans
/// lui, elle montre l'explication et attend « Observer maintenant » : aucun
/// rechargement ne consomme jamais une visite (V7 section 7, point 8).
@immutable
final class DemandeEntreeObservation {
  /// Cree le geste.
  const DemandeEntreeObservation();
}

/// Ouvre la porte d'observation d'une seance, depuis la classe.
///
/// **Le seul chemin vers `/tc/observation` pour un ecran du tuteur** : la
/// classe (lot C) l'appelle pour « Observer la seance » ([entrer] vrai) et
/// pour « Comment ca marche ? » ([entrer] faux). [classeId] et [eleveId]
/// portent le retour a la classe, avec le contexte de l'enfant, la politique
/// effective du groupe et la presence du bon eleve : des identifiants, jamais
/// une autorisation (la RLS et les fonctions serveur decident).
void ouvrirObservation(
  BuildContext context, {
  required String seanceId,
  String? classeId,
  String? eleveId,
  bool entrer = true,
}) => GoRouter.of(context).go(
  cheminObservation(seanceId, classeId: classeId, eleveId: eleveId),
  extra: entrer ? const DemandeEntreeObservation() : null,
);

/// L'adresse de la porte d'observation, avec le contexte du retour :
/// `/tc/observation/:seanceId?classe=&eleve=`.
///
/// ponytail: le chemin vient de `Routes.tcObservation` ; seule la requete est
/// posee ici. A promouvoir dans `routes.dart` par le coordinateur (demande
/// O-1), sans changer l'adresse.
String cheminObservation(String seanceId, {String? classeId, String? eleveId}) {
  final Map<String, String> requete = <String, String>{
    'classe': ?classeId,
    'eleve': ?eleveId,
  };
  return Uri(
    path: Routes.tcObservation(seanceId),
    queryParameters: requete.isEmpty ? null : requete,
  ).toString();
}
