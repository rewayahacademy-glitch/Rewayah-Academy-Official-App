// RACCORDEMENT-1016 (A) : l'Accueil de l'eleve en Mode Accessibilite lu sur
// le serveur, a la place du port neutre (« pas encore disponible »).
//
// Quatre lectures, toutes sous la session de l'eleve, aucune ecriture :
//
// 1. `profiles` : son prenom (policy de lecture de soi) ;
// 2. `student_profiles` : mineur ou non, ce qui decide du tutoiement (MA4) ;
// 3. ses Classes courantes, par le meme adaptateur que le foyer
//    (`ClassesFoyerSupabase` : `groupe_membres`, puis `mes_groupes_famille_v`) ;
// 4. pour chacune, la prochaine seance reelle (`prochaine_seance_groupe`, puis
//    `horloge_seance`, par `HorlogeSeanceSupabase`).
//
// La Classe montree est celle dont la prochaine seance arrive en premier ;
// sans seance programmee, la premiere Classe, sans horloge (la carte dit
// alors qu'aucune seance n'est planifiee, jamais un compte a rebours
// fabrique). Sans Classe : l'etat vide. « Avant le prochain cours » vient du
// travail a venir de la Classe ; s'il manque ou echoue, la liste est vide et
// le reste de l'Accueil s'affiche (D11).

import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/classes_foyer_supabase.dart';
import '../capacites/port_classes_foyer.dart';
import '../tc_groupe/group_home_vm.dart';
import '../tc_horloge/horloge_supabase.dart';
import '../tc_horloge/port_horloge_seance.dart';
import '../tc_horloge/session_clock_vm.dart';
import '../tc_parcours/port_travail_a_venir.dart';
import 'port_accueil_accessibilite.dart';

/// L'Accueil du Mode Accessibilite servi par Supabase.
class AccueilAccessibiliteSupabase implements PortAccueilAccessibilite {
  /// Cree l'adaptateur. [utilisateur] rend l'identifiant de la session (par
  /// defaut celui du client) ; [classes], [horloges] et [travail] sont
  /// injectables pour les tests.
  AccueilAccessibiliteSupabase(
    this._client, {
    String? Function()? utilisateur,
    PortClassesFoyer? classes,
    PortHorlogeSeance? horloges,
    this.travail,
  }) : _utilisateur = utilisateur ?? (() => _client.auth.currentUser?.id),
       _classes = classes ?? ClassesFoyerSupabase(_client),
       _horloges = horloges ?? HorlogeSeanceSupabase(_client);

  final SupabaseClient _client;
  final String? Function() _utilisateur;
  final PortClassesFoyer _classes;
  final PortHorlogeSeance _horloges;

  /// Le travail a venir de la Classe ; nul : « Avant le prochain cours »
  /// reste vide.
  final PortTravailAVenir? travail;

  @override
  Future<DonneesAccueilAccessibilite> lire() async {
    final String? eleveId = _utilisateur();
    if (eleveId == null) {
      throw StateError('aucune session');
    }
    final Map<String, dynamic>? profil = await _client
        .from('profiles')
        .select('first_name')
        .eq('id', eleveId)
        .maybeSingle();
    final Map<String, dynamic>? eleve = await _client
        .from('student_profiles')
        .select('student_type')
        .eq('profile_id', eleveId)
        .maybeSingle();
    // Sans profil lisible, la lecture a echoue : jamais un prenom de
    // remplacement (D10).
    final String? prenom = profil?['first_name'] as String?;
    if (prenom == null) {
      throw StateError('profil de l eleve illisible');
    }
    final List<ClasseFoyer> classes = await _classes.classesDe(eleveId);

    GroupHomeVM? espace;
    if (classes.isNotEmpty) {
      ClasseFoyer retenue = classes.first;
      SessionClockVM? horloge;
      for (final ClasseFoyer c in classes) {
        final SessionClockVM? h = await _horloges.horlogeDe(
          groupeId: c.classe.groupeId,
        );
        if (h != null &&
            (horloge == null || h.debutUtc.isBefore(horloge.debutUtc))) {
          retenue = c;
          horloge = h;
        }
      }
      espace = GroupHomeVM.pourRole(
        identite: retenue.classe.avecHorloge(horloge),
        role: RoleEspaceGroupe.eleve,
        actions: await _actions(retenue.classe.groupeId, eleveId),
      );
    }

    return DonneesAccueilAccessibilite(
      prenom: prenom,
      tutoiement: eleve?['student_type'] == 'minor',
      espace: espace,
    );
  }

  Future<List<SlotAction>> _actions(String groupeId, String eleveId) async {
    final PortTravailAVenir? port = travail;
    if (port == null) return const <SlotAction>[];
    try {
      // Le plafond de trois est garanti par le port, jamais tronque ici.
      return await port.avantProchainCours(
        groupeId: groupeId,
        studentId: eleveId,
      );
    } on Object {
      return const <SlotAction>[];
    }
  }
}
