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
// PERSONNES-UNE-PAGE (d) : la file peut aussi etre une vue des enseignants de
// la page « Personnes » (`file=enseignants`, la phase, les partis) : le
// precedent et le suivant viennent alors de `voisins_enseignant`, aux memes
// filtres et au meme tri que `lister_enseignants`. `vue` (la vue de la page
// « Personnes » d'ou l'on vient) voyage avec la file, pour le retour.
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
import '../../core/enseignants/modeles_enseignants.dart';
import '../../core/enseignants/port_enseignants.dart';
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
    if (requete['file'] == 'enseignants') {
      return FileDuDossier(<String, String>{
        for (final String cle in _clesFileEnseignants)
          if (requete[cle] case final String v) cle: v,
      });
    }
    return FileDuDossier(<String, String>{
      for (final MapEntry<String, String> e in requete.entries)
        if ((clesAdresseCandidatures.contains(e.key) && e.key != 'q') ||
            e.key == 'vue')
          e.key: e.value,
    });
  }

  /// Les parametres d'une file d'enseignants.
  static const List<String> _clesFileEnseignants = <String>[
    'file',
    'vue',
    'phase',
    'phase_file',
    'partis',
    'page',
  ];

  /// Vrai : la file est une vue des enseignants (`voisins_enseignant`).
  bool get enseignants => adresse['file'] == 'enseignants';

  /// La vue de la page « Personnes » d'ou le dossier a ete ouvert, ou `null`
  /// (ouvert depuis l'ancienne liste des candidatures).
  String? get vuePersonnes => adresse['vue'];

  /// Le filtre d'une file d'enseignants.
  FiltreEnseignants get filtreEnseignants => FiltreEnseignants(
    // `phase` : le filtre pose dans la page ; `phase_file` : la phase que
    // la vue impose (elle ne revient pas dans l'adresse de la page).
    phase: PhaseEnseignant.depuisSql(adresse['phase'] ?? adresse['phase_file']),
    partis: adresse['partis'] == 'oui',
  );

  /// Les parametres de la liste : filtre, tri (et page, sans effet ici).
  final Map<String, String> adresse;

  /// Le tri de la file des enseignants (`tri` dans l'adresse).
  TriEnseignants get triEnseignants => TriEnseignants.values.firstWhere(
    (TriEnseignants x) => x.name == adresse['tri'],
    orElse: () => TriEnseignants.activite,
  );

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
      if (demande.file.enseignants) {
        final Object? enseignants = ref.watch(portEnseignantsProvider);
        if (enseignants is! PortVoisinsEnseignant) return null;
        return enseignants.voisins(
          demande.reference,
          filtre: demande.file.filtreEnseignants,
          tri: demande.file.triEnseignants,
        );
      }
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
