// Passer d'un dossier a l'autre sans revenir a la liste (BE-SUIVANT, lot
// BE-1b, directeur, 15 et 16/11/2026 : « Apres confirmation, je ne peux pas
// enchainer, je dois revenir sur la liste et [...] je me perds »).
//
// Le serveur sait deja rendre le precedent, le suivant, le rang et le total
// **dans le meme filtre et le meme tri que la liste** (`voisins_candidature`,
// PR 505) : ce fichier n'invente aucun ordre. La liste ouvre le dossier avec
// son filtre et son tri dans l'adresse (`Routes.adminPersonnesCandidaturePour`,
// `fileDeLaListe`) ; un dossier ouvert d'ailleurs (un message, un entretien)
// n'a pas de file : rien ne s'affiche.
//
// Limite dite : le texte cherche dans la liste n'est pas dans l'adresse (c'est
// un nom de personne, relecture du coordinateur du 16/11). Si la liste avait
// une recherche, le suivant suit le filtre et le tri sans ce texte.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/candidature/modeles_candidature_detail.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/port_candidatures_direction.dart';
import '../../core/observabilite/journal_dev.dart';
import '../../core/preferences/preferences_locales.dart';
import '../admin_candidatures/adresse_candidatures.dart';

/// La file d'ou le dossier a ete ouvert : l'adresse de la liste (filtre, tri).
@immutable
class FileDuDossier {
  /// Cree la file.
  const FileDuDossier(this.adresse);

  /// Lit la file dans l'adresse du dossier, ou `null` : le dossier n'a pas ete
  /// ouvert depuis la liste (`depuis=liste`), il n'a pas de file.
  static FileDuDossier? depuis(Map<String, String>? requete) {
    if (requete == null || requete['depuis'] != 'liste') return null;
    return FileDuDossier(<String, String>{
      for (final MapEntry<String, String> e in requete.entries)
        if (clesAdresseCandidatures.contains(e.key) && e.key != 'q')
          e.key: e.value,
    });
  }

  /// Les parametres de la liste : filtre, tri (et page, sans effet ici).
  final Map<String, String> adresse;

  /// Le filtre et le tri de la file.
  RequeteCandidatures get requete => requeteDepuisAdresse(adresse);

  /// Une ecriture stable de la file, pour s'en servir de cle.
  String get cle {
    final List<String> cles = adresse.keys.toList()..sort();
    return cles.map((String k) => '$k=${adresse[k]}').join('&');
  }

  @override
  bool operator ==(Object other) => other is FileDuDossier && other.cle == cle;

  @override
  int get hashCode => cle.hashCode;
}

/// Ce que l'on demande au serveur : les voisins de [reference] dans [file].
@immutable
class DemandeVoisins {
  /// Cree la demande.
  const DemandeVoisins(this.reference, this.file);

  /// La reference `CAND-…` du dossier ouvert.
  final String reference;

  /// La file.
  final FileDuDossier file;

  @override
  bool operator ==(Object other) =>
      other is DemandeVoisins &&
      other.reference == reference &&
      other.file == file;

  @override
  int get hashCode => Object.hash(reference, file);
}

/// Les voisins du dossier dans sa file, lus au serveur. Une lecture refusee ou
/// en echec n'affiche rien : jamais un rang invente.
final FutureProviderFamily<VoisinsCandidature?, DemandeVoisins>
voisinsDuDossierProvider = FutureProvider.autoDispose
    .family<VoisinsCandidature?, DemandeVoisins>((
      Ref ref,
      DemandeVoisins demande,
    ) async {
      final PortCandidaturesDirection? port = ref.watch(
        portCandidaturesDirectionProvider,
      );
      if (port == null) return null;
      final RequeteCandidatures r = demande.file.requete;
      return port.voisins(demande.reference, filtre: r.filtre, tri: r.tri);
    });

/// La clef du reglage dans le stockage des preferences de l'appareil.
const String clefPasserAuSuivant = 'dossier.passerAuSuivant';

/// « Passer au suivant apres une decision » : active par defaut, memorise sur
/// l'appareil (pas sur le compte).
final NotifierProvider<PasserAuSuivantControleur, bool>
passerAuSuivantProvider = NotifierProvider<PasserAuSuivantControleur, bool>(
  PasserAuSuivantControleur.new,
);

/// Porte le reglage.
class PasserAuSuivantControleur extends Notifier<bool> {
  /// Vrai des qu'un choix a ete fait pendant cette session : la lecture du
  /// stockage, qui peut arriver apres, ne l'ecrase jamais.
  bool _choisi = false;

  @override
  bool build() {
    unawaited(_restaurer());
    return true;
  }

  Future<void> _restaurer() async {
    try {
      final String? lu = await ref
          .read(stockagePreferencesProvider)
          .lire(clefPasserAuSuivant);
      if (ref.mounted && !_choisi && (lu == 'true' || lu == 'false')) {
        state = lu == 'true';
      }
    } on Object catch (erreur) {
      journalDev(
        'Reglage « passer au suivant » illisible, en memoire : $erreur',
      );
    }
  }

  /// Active ou coupe le passage au suivant, et le garde sur l'appareil.
  Future<void> choisir({required bool actif}) async {
    _choisi = true;
    state = actif;
    try {
      await ref
          .read(stockagePreferencesProvider)
          .ecrire(clefPasserAuSuivant, '$actif');
    } on Object catch (erreur) {
      journalDev(
        'Reglage « passer au suivant » non ecrit, en memoire : $erreur',
      );
    }
  }
}
