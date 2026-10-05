import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

import '../appairage/service_appairage.dart';
import '../session/session_state.dart';
import 'profil_eleve_brouillon.dart';

/// Ce qu'une demande de creation de profil a produit.
sealed class ResultatCreationProfil {
  const ResultatCreationProfil();
}

/// Le profil est cree.
final class ProfilCree extends ResultatCreationProfil {
  /// Cree le resultat.
  const ProfilCree({this.eleveId});

  /// L'identifiant du profil cree. `null` aujourd'hui : `creerEnfant` ne rend
  /// rien au client, l'identifiant se relit dans le foyer.
  final String? eleveId;
}

/// Le serveur a refuse la creation. Rien n'a ete cree.
final class CreationRefusee extends ResultatCreationProfil {
  /// Cree le resultat.
  const CreationRefusee(this.motif);

  /// Pourquoi.
  final MotifRefusCreation motif;
}

/// La reponse est perdue : le profil a **peut-etre** ete cree.
///
/// La creation n'est pas idempotente (DB-FOY-06) : un nouvel essai aveugle
/// peut creer un doublon. L'ecran relit le foyer, montre ce qu'il contient, et
/// laisse la personne choisir de reessayer ou non.
final class CreationIncertaine extends ResultatCreationProfil {
  /// Cree le resultat.
  const CreationIncertaine();
}

/// Pourquoi le serveur refuse une creation.
enum MotifRefusCreation {
  /// Le compte du titulaire n'est pas (ou plus) valide (DB-ADM-04).
  compteNonValide,

  /// L'age sort des bornes du serveur.
  ageHorsBornes,

  /// Tout autre refus. L'ecran ne l'explique pas davantage.
  refuse,
}

/// La creation d'un profil eleve du foyer (contrat K3).
abstract interface class PortCreationProfilEleve {
  /// Vrai quand ce choix est creable pour un compte a cette porte.
  ///
  /// Faux pour [PourQui.moiMeme] (DB-FOY-01), et pour tout compte qui n'est pas [PorteAcces.actif]
  /// (DB-ADM-04). **Une commodite d'ecran** : le serveur refait le controle.
  bool peutCreer(PourQui pourQui, {required PorteAcces porte});

  /// Cree le profil. Ne leve pas : tout aboutit a un resultat type.
  Future<ResultatCreationProfil> creer(BrouillonProfilEleve brouillon);
}

/// Traduit un refus de la fonction Edge `creer-profil-enfant`.
///
/// **Un refus certain vient d'un statut 4xx** : la fonction et
/// `creer_profil_enfant()` controlent avant d'ecrire, et compensent un echec
/// d'ecriture. Un statut 0 (reponse jamais recue) ou 5xx ne prouve rien sur ce
/// qui a ete ecrit : [CreationIncertaine]. Le texte du serveur n'est lu que
/// pour reconnaitre deux motifs connus, jamais affiche.
ResultatCreationProfil resultatDepuisRefus(FunctionException erreur) {
  if (erreur.status < 400 || erreur.status >= 500) {
    return const CreationIncertaine();
  }
  final Object? details = erreur.details;
  final String message = details is Map
      ? '${details['error'] ?? ''}'
      : '${details ?? ''}';
  if (message.contains('compte tuteur non valide')) {
    return const CreationRefusee(MotifRefusCreation.compteNonValide);
  }
  if (message.contains('age hors bornes')) {
    return const CreationRefusee(MotifRefusCreation.ageHorsBornes);
  }
  return const CreationRefusee(MotifRefusCreation.refuse);
}

/// L'adaptateur reel, sur `ServiceAppairage.creerEnfant` (fonction Edge
/// `creer-profil-enfant`).
///
/// **Double soumission bloquee ici aussi** : un second appel pendant le premier
/// rend le meme futur, sans second envoi. L'ecran bloque deja son bouton ;
/// cette garde couvre le double appui qui passe entre deux images.
class CreationProfilEleveAppairage implements PortCreationProfilEleve {
  /// Cree l'adaptateur.
  CreationProfilEleveAppairage(
    this._service, {
    this.bornes = BornesAge.clientActuelle,
    this._relireFoyer,
  });

  final ServiceAppairage _service;

  /// Appele apres une creation reussie ou incertaine, pour que le foyer se
  /// relise : c'est la que l'identifiant cree, ou un doublon possible, se voit.
  final void Function()? _relireFoyer;

  /// Les bornes d'age verifiees avant l'envoi.
  final BornesAge bornes;

  Future<ResultatCreationProfil>? _enVol;

  @override
  bool peutCreer(PourQui pourQui, {required PorteAcces porte}) =>
      pourQui == PourQui.enfantOuMineur && porte == PorteAcces.actif;

  @override
  Future<ResultatCreationProfil> creer(BrouillonProfilEleve brouillon) {
    final Future<ResultatCreationProfil>? enVol = _enVol;
    if (enVol != null) {
      return enVol;
    }
    final Future<ResultatCreationProfil> envoi = _envoyer(brouillon)
        .whenComplete(() => _enVol = null);
    _enVol = envoi;
    return envoi;
  }

  Future<ResultatCreationProfil> _envoyer(
    BrouillonProfilEleve brouillon,
  ) async {
    if (brouillon.pourQui != PourQui.enfantOuMineur) {
      return const CreationRefusee(MotifRefusCreation.refuse);
    }
    final Map<ChampProfilEleve, ErreurChamp> erreurs = brouillon.valider(
      bornes,
    );
    final int? age = brouillon.age;
    if (erreurs.isNotEmpty || age == null) {
      return CreationRefusee(
        erreurs[ChampProfilEleve.age] == ErreurChamp.horsBornes
            ? MotifRefusCreation.ageHorsBornes
            : MotifRefusCreation.refuse,
      );
    }

    final ResultatCreationProfil resultat = await _appeler(brouillon, age);
    if (resultat is! CreationRefusee) {
      // Cree ou peut-etre cree : le foyer se relit dans les deux cas.
      _relireFoyer?.call();
    }
    return resultat;
  }

  Future<ResultatCreationProfil> _appeler(
    BrouillonProfilEleve brouillon,
    int age,
  ) async {
    try {
      await _service.creerEnfant(
        prenom: brouillon.prenom.trim(),
        nom: brouillon.nom.trim(),
        age: age,
      );
      return const ProfilCree();
    } on FunctionException catch (erreur) {
      return resultatDepuisRefus(erreur);
    } on Object {
      // Coupure, delai, reponse illisible : rien ne dit ce qui a ete ecrit.
      return const CreationIncertaine();
    }
  }
}

/// Le port de creation employe par l'application.
///
/// Une creation reussie ou incertaine relit le foyer
/// (`elevesDuFoyerProvider`) : le nouveau profil, ou un doublon possible,
/// apparait sans que l'ecran ait a le savoir.
final Provider<PortCreationProfilEleve> portCreationProfilEleveProvider =
    Provider<PortCreationProfilEleve>(
      (Ref ref) => CreationProfilEleveAppairage(
        ref.watch(serviceAppairageProvider),
        relireFoyer: () => ref.invalidate(elevesDuFoyerProvider),
      ),
    );
