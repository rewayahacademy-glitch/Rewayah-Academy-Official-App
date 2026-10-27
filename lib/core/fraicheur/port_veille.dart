// La veille de fraicheur (fiche « Fraicheur et notifications » du 27/10/2026,
// lignes 1 a 9) : ce que le serveur signale quand une table des classes ou
// des seances change, et par quel port l'application l'ecoute.
//
// Le signal ne porte aucune donnee a afficher : a chaque signal, l'application
// relit ses lectures habituelles, sous RLS. C'est le meme principe que le
// support actif de la salle (`support_actif_supabase.dart`), etendu aux
// quatre tables publiees par la migration 20261027100000.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Les familles de lectures que la veille tient a jour. Un changement sur une
/// table invalide toutes les lectures de sa famille (arbitrage du pilote du
/// 27/10 : simple et juste, l'optimisation attendra une mesure).
enum FamilleLecture {
  /// Les classes : identite, membres, creneaux, enseignant.
  classes,

  /// Les seances : planning, prochaine et derniere seance, cahiers.
  seances,

  /// Les notifications de la personne : la liste du centre et le point de
  /// non-lus de la cloche (fiche du 27/10, lignes 12 et 14 ; lot 2).
  notifications,
}

/// Les tables veillees : celles de la migration 20261027100000, et
/// `notifications` depuis 20261027120000.
const List<String> tablesVeillees = <String>[
  'groupes',
  'groupe_membres',
  'groupe_creneaux',
  'sessions',
  'notifications',
];

/// La famille d'une table veillee ; `null` pour une table inconnue, qui ne
/// declenche rien.
FamilleLecture? familleDeLaTable(String table) => switch (table) {
  'groupes' || 'groupe_membres' || 'groupe_creneaux' => FamilleLecture.classes,
  'sessions' => FamilleLecture.seances,
  'notifications' => FamilleLecture.notifications,
  _ => null,
};

/// Ce que la veille signale.
sealed class SignalVeille {
  const SignalVeille();
}

/// Une ligne d'une table veillee a change : insertion, modification ou
/// suppression. Pour une suppression, Realtime ne transmet que la cle
/// primaire, a tous les abonnes : le signal vaut donc « a relire », jamais
/// « cette ligne vous concerne ».
final class ChangementTable extends SignalVeille {
  /// Cree le signal.
  const ChangementTable(this.table);

  /// Le nom de la table, sans schema.
  final String table;
}

/// Le canal vient d'etre joint ou rejoint (ouverture, retour du reseau,
/// reconnexion du serveur) : ce qui a pu changer entre-temps est inconnu,
/// tout est a relire.
final class CanalRejoint extends SignalVeille {
  /// Cree le signal.
  const CanalRejoint();
}

/// Par ou l'application ecoute le serveur.
abstract interface class PortVeille {
  /// Ouvre la veille pour la personne connectee et signale chaque changement
  /// des [tablesVeillees] que la RLS laisse voir. La veille se ferme quand
  /// l'ecoute est annulee. Un abonnement par appel : rien n'est partage.
  Stream<SignalVeille> ecouter();
}

/// Une veille qui ne signale rien : tests, galerie, demonstration, et tout
/// ecran monte sans Supabase.
class VeilleMuette implements PortVeille {
  /// Cree la veille muette.
  const VeilleMuette();

  @override
  Stream<SignalVeille> ecouter() => const Stream<SignalVeille>.empty();
}

/// Le port de veille employe par l'application. Par defaut **muet** (aucun
/// appel serveur implicite) ; l'adaptateur reel `VeilleSupabase` est branche
/// au demarrage reel (`lib/main.dart`), comme `portClassesFoyerProvider`.
final Provider<PortVeille> portVeilleProvider = Provider<PortVeille>(
  (Ref ref) => const VeilleMuette(),
);
