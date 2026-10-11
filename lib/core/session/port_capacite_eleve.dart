import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_capacite_eleve_supabase.dart';

/// Ce que le serveur sait de la capacite « eleve autonome » d'un compte
/// (contrat C-24, feuille de liaison ; EA-ROLE-BR cote serveur).
///
/// L'eleve adulte n'est ni un role ni un age suppose : c'est un profil
/// autonome appartenant a l'identite connectee, servi par le serveur.
/// **Un widget lit cette capacite, jamais `AppRole.student`.**
sealed class CapaciteEleve {
  const CapaciteEleve();
}

/// Le compte suit lui-meme des cours : il a un profil eleve autonome.
final class EleveAutonome extends CapaciteEleve {
  /// Cree la capacite « eleve autonome ».
  const EleveAutonome();
}

/// Le serveur a repondu : ce compte n'est pas un eleve autonome (tuteur
/// seul, enseignant, administration).
final class PasEleve extends CapaciteEleve {
  /// Cree la reponse « pas d'eleve autonome ».
  const PasEleve();
}

/// Le serveur n'a pas repondu, ou n'existe pas encore. On ne devine pas :
/// traite comme « pas autonome », sans jamais ouvrir ce qu'on n'a pas su lire.
final class CapaciteInconnue extends CapaciteEleve {
  /// Cree la reponse « inconnue ».
  const CapaciteInconnue();
}

/// Port de lecture de la capacite. L'adaptateur Supabase est ecrit par
/// ChatGPT (Codex) dans `*_supabase.dart` (COHABITATION.md) ; ce fichier
/// ne contient que le contrat et un adaptateur factice.
abstract interface class PortCapaciteEleve {
  /// Lit la capacite du profil [profileId]. Ne leve pas : un echec se rend
  /// par [CapaciteInconnue].
  Future<CapaciteEleve> lire(String profileId);
}

/// Production, tant que l'adaptateur du serveur n'existe pas : inconnue.
final class PortCapaciteEleveInconnu implements PortCapaciteEleve {
  /// Cree le port neutre.
  const PortCapaciteEleveInconnu();

  @override
  Future<CapaciteEleve> lire(String profileId) async =>
      const CapaciteInconnue();
}

/// Adaptateur factice pour la demonstration et les tests : les profils
/// listes sont autonomes, les autres ne le sont pas.
final class PortCapaciteEleveFactice implements PortCapaciteEleve {
  /// Cree un port factice dont [autonomes] sont les profils autonomes.
  const PortCapaciteEleveFactice({this.autonomes = const <String>{}});

  /// Identifiants de profil servis comme eleve autonome.
  final Set<String> autonomes;

  @override
  Future<CapaciteEleve> lire(String profileId) async =>
      autonomes.contains(profileId) ? const EleveAutonome() : const PasEleve();
}

/// Le port de capacite eleve utilise par l'application.
final Provider<PortCapaciteEleve> portCapaciteEleveProvider =
    Provider<PortCapaciteEleve>(
      (Ref ref) => PortCapaciteEleveSupabase(Supabase.instance.client),
    );
