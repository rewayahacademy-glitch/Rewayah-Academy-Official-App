// Les doubles de test du partage de la carte (CAND-06) : le menu de partage de
// l'appareil, l'enregistrement de l'image et le rendu en PNG. Importes par les
// tests seulement, jamais par une ligne de production.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:rewayah_academy/core/partage_offre/port_partage_offre.dart';
import 'package:rewayah_academy/core/tc_telechargement/port_enregistrement_fichier.dart';

/// Le menu de partage d'un appareil, sans appareil.
class FauxPartageOffre implements PortPartageOffre {
  /// Cree le faux pour un [niveau] de partage.
  FauxPartageOffre({this.niveau = NiveauPartage.image});

  @override
  final NiveauPartage niveau;

  /// Ce que le menu rendra : la carte transmise, ou fermee par la personne.
  IssuePartage issue = IssuePartage.partage;

  /// Ce que le menu doit jeter (`PartageImpossible` pour un refus de
  /// l'appareil, tout autre objet pour une panne). `null` : rien.
  Object? erreur;

  /// Un menu qui reste ouvert jusqu'a ce que le test le ferme.
  Completer<IssuePartage>? ouvert;

  /// Les appels recus.
  final List<AppelPartage> appels = <AppelPartage>[];

  @override
  Future<IssuePartage> partager({
    required Uint8List png,
    required String nomFichier,
    required String titre,
    required String texte,
    required Uri lien,
  }) {
    appels.add(
      AppelPartage(
        png: png,
        nomFichier: nomFichier,
        titre: titre,
        texte: texte,
        lien: lien,
      ),
    );
    final Object? panne = erreur;
    if (panne != null) {
      return Future<IssuePartage>.error(panne);
    }
    return ouvert?.future ?? Future<IssuePartage>.value(issue);
  }
}

/// Un appel au menu de partage.
class AppelPartage {
  /// Cree l'appel.
  const AppelPartage({
    required this.png,
    required this.nomFichier,
    required this.titre,
    required this.texte,
    required this.lien,
  });

  /// L'image transmise.
  final Uint8List png;

  /// Le nom du fichier.
  final String nomFichier;

  /// Le titre du message.
  final String titre;

  /// Le texte du message.
  final String texte;

  /// Le lien du message.
  final Uri lien;
}

/// Un enregistrement de fichier qui n'ouvre aucune boite de dialogue et garde
/// ce qu'on lui donne.
class FauxEnregistrementImage implements PortEnregistrementFichier {
  /// Cree le faux.
  FauxEnregistrementImage({
    this.destinationRendue = 'file:///rewayah-carte.png',
  });

  /// Ce que le selecteur rendra. `null` simule une renonciation.
  String? destinationRendue;

  /// Ce que le selecteur doit jeter. `null` : rien.
  Object? erreur;

  /// Les enregistrements recus.
  final List<({String nom, String mime, List<int> octets})> appels =
      <({String nom, String mime, List<int> octets})>[];

  @override
  Future<String?> enregistrerCopie({
    required List<int> octets,
    required String nomFichierPropose,
    required String typeMime,
  }) async {
    appels.add((nom: nomFichierPropose, mime: typeMime, octets: octets));
    final Object? panne = erreur;
    if (panne != null) {
      // Volontairement un Object : le vrai selecteur jette aussi bien une
      // exception de plateforme qu'une erreur.
      // ignore: only_throw_errors
      throw panne;
    }
    return destinationRendue;
  }
}

/// Un rendu de la carte qui rend des octets fixes, sans peindre.
class FauxRenduCarte {
  /// Cree le faux.
  FauxRenduCarte({Uint8List? octets})
    : octets = octets ?? Uint8List.fromList(<int>[137, 80, 78, 71, 1, 2, 3]);

  /// Les octets rendus.
  final Uint8List octets;

  /// Ce que le rendu doit jeter. `null` : rien.
  Object? erreur;

  /// Un rendu qui reste en cours jusqu'a ce que le test le termine.
  Completer<Uint8List>? enCours;

  /// Le nombre de rendus demandes.
  int appels = 0;

  /// Le rendu, tel que la page l'appelle.
  Future<Uint8List> rendre(GlobalKey cle) {
    appels++;
    final Object? panne = erreur;
    if (panne != null) {
      return Future<Uint8List>.error(panne);
    }
    return enCours?.future ?? Future<Uint8List>.value(octets);
  }
}
