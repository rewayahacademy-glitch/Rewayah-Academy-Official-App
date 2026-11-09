// ONBOARDING-TUTEUR (09/11/2026) : le tuteur qui suit aussi des cours entre dans
// son espace d'eleve depuis l'Accueil famille ; il doit pouvoir en revenir sans
// second compte. Ce fichier dit quand le retour se montre ; la carte est posee
// par `AccueilAdultePage`, qui ne lit pas la session (ses tests la montent
// sans) : le routeur lui donne le rappel (`routes_accueil_adulte.dart`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dossier/etat_dossier.dart';
import '../../core/session/atterrissage_adulte.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';

/// Vrai quand le compte tient un foyer ET que l'usage choisi a l'inscription
/// n'est pas « Moi » : seul ce compte a un Accueil famille a retrouver (un
/// compte « Moi » y serait renvoye par le routeur, ce serait une boucle). Un
/// usage encore en lecture, ou inconnu, ne montre rien : jamais un retour qui
/// apparait puis disparait. Un widget lit une capacite, jamais le role.
final Provider<bool> retourAccueilFamilleProvider = Provider<bool>((Ref ref) {
  final SessionState session = ref.watch(sessionProvider);
  final String? profil = session.profileId;
  if (!session.aUnFoyer || profil == null) return false;
  final UsageTitulaire? usage = ref.watch(usageTitulaireProvider(profil)).value;
  return usage != null && usage != UsageTitulaire.moi;
});

/// La cle de la carte « Revenir a l'accueil de votre famille ».
const Key retourAccueilFamilleKey = Key('adulte.accueil.retourFamille');
