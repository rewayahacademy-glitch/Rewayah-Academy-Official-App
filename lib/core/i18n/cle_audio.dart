import 'package:flutter/foundation.dart';

import 'strings.g.dart';

/// Une cle de libelle, valable pour le texte **et** pour le son.
///
/// Les libelles audio suivent la meme logique que les chaines textuelles : une
/// cle identique pointe vers un fichier son plutot que vers une chaine
/// (`docs/architecture/etape-2-core-flutter.md` section 5). Texte et audio
/// restent ainsi dans un seul systeme, pas deux qui divergent.
///
/// Le composant `AudioLabel` consomme ce type, jamais une chaine libre.
/// `test/i18n/cle_audio_test.dart` verifie que chaque cle declaree ici existe
/// bien dans le catalogue de traduction.
@immutable
class CleAudio {
  /// Declare une cle de libelle.
  const CleAudio(this.chemin);

  /// Le chemin de la cle, en points : `eleve.accueil.rejoindre`.
  final String chemin;

  /// Le fichier son correspondant pour une langue donnee.
  String fichierPour(String codeLangue) => 'assets/audio/$codeLangue/$chemin.mp3';

  @override
  bool operator ==(Object other) => other is CleAudio && other.chemin == chemin;

  @override
  int get hashCode => chemin.hashCode;

  @override
  String toString() => 'CleAudio($chemin)';
}

/// Lecture d'une traduction par son chemin plutot que par son accesseur genere.
///
/// Reserve aux composants qui recoivent une [CleAudio] et doivent afficher le
/// texte correspondant. Partout ailleurs, on passe par l'accesseur type
/// (`t.eleve.accueil.rejoindre`), qui est verifie a la compilation.
extension TraductionParCle on Traductions {
  /// Le texte associe a une cle de libelle.
  String parCle(CleAudio cle) => $meta.getTranslation(cle.chemin) as String;
}

/// Les libelles qui existent en texte et en son.
///
/// Le zero-lecture du mode enfant repose sur cette liste : tout ce qu'un enfant
/// de 6 ans doit comprendre sans savoir lire y figure.
abstract final class ClesAudio {
  /// Bouton d'entree en seance sur l'accueil eleve.
  static const CleAudio eleveAccueilRejoindre = CleAudio(
    'eleve.accueil.rejoindre',
  );

  /// Acces au Coran depuis l'accueil eleve.
  static const CleAudio eleveAccueilCoran = CleAudio('eleve.accueil.coran');

  /// Annonce du prochain cours.
  static const CleAudio eleveAccueilProchainCours = CleAudio(
    'eleve.accueil.prochainCours',
  );

  /// Annonce d'un cours deja commence.
  static const CleAudio eleveAccueilCoursEnDirect = CleAudio(
    'eleve.accueil.coursEnDirect',
  );

  /// Invite du pave numerique.
  static const CleAudio pinTitre = CleAudio('pin.titre');

  /// Echec de saisie du code.
  static const CleAudio pinErreur = CleAudio('pin.erreur');

  /// Toutes les cles declarees. Sert au test de coherence texte-audio.
  static const List<CleAudio> toutes = <CleAudio>[
    eleveAccueilRejoindre,
    eleveAccueilCoran,
    eleveAccueilProchainCours,
    eleveAccueilCoursEnDirect,
    pinTitre,
    pinErreur,
  ];
}
