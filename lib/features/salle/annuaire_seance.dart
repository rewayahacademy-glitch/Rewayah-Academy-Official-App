// L'annuaire de la seance (directeur, test en production du 26/10/2026,
// 09:15) : les participants s'affichaient sous une chaine technique, parce
// que le jeton LiveKit ne porte qu'une identite (le profil) et un role,
// aucun nom. L'annuaire associe cette identite a la personne que
// l'application connait deja, et donne le nom a afficher et la photo :
//
// - l'enseignant de la seance ([FicheEnseignantSeance] : profil, prenom,
//   titre, cle de photo), lue la ou le role de l'appelant le permet (sa
//   propre fiche pour l'enseignant, la fiche lue par la direction, la Classe
//   de la famille pour l'eleve et le tuteur) : « Sayyid Prenom » ou
//   « Sayyida Prenom », le prenom seul sans titre connu ;
// - les autres, par la presence de la seance (`PresenceParticipant` : profil,
//   prenom, role) : « Prenom » ;
// - personne de connu : « Participant », jamais l'identite.
//
// Pur : il ne lit que ce que `SallePage` a deja lu, n'ouvre aucun appel.

import '../../core/i18n/strings.g.dart';
import '../../core/presence/service_presence.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/video/video_session_provider.dart';
import 'vue_salle.dart' show RoleSalle;

/// Une personne connue de la seance.
typedef PersonneSeance = ({String nom, String? clePhotoEnseignant});

/// L'enseignant de la seance, tel que l'appelant peut le lire ; [titre]
/// `null` quand il n'est pas renseigne (jamais devine).
typedef FicheEnseignantSeance = ({
  String id,
  String prenom,
  TitreEnseignant? titre,
  String? clePhoto,
});

/// L'annuaire d'une seance : l'identite LiveKit vers la personne.
class AnnuaireSeance {
  /// Compose l'annuaire depuis la presence lue et l'enseignant de la Classe.
  factory AnnuaireSeance({
    List<PresenceParticipant>? presence,
    FicheEnseignantSeance? enseignant,
  }) {
    final Map<String, PersonneSeance> personnes = <String, PersonneSeance>{};
    final Map<String, String> prenoms = <String, String>{};
    String? nomDeLEnseignant;
    for (final PresenceParticipant ligne
        in presence ?? const <PresenceParticipant>[]) {
      if (ligne.profilId.isEmpty || ligne.prenom.isEmpty) continue;
      final bool estEnseignant =
          RoleSalle.depuis(ligne.role) == RoleSalle.enseignant;
      prenoms[ligne.profilId] = ligne.prenom;
      personnes[ligne.profilId] = (
        nom: estEnseignant
            ? nomEnseignant(ligne.prenom, enseignant?.titre)
            : ligne.prenom,
        clePhotoEnseignant: null,
      );
      if (estEnseignant) nomDeLEnseignant = personnes[ligne.profilId]!.nom;
    }
    final FicheEnseignantSeance? e = enseignant;
    if (e != null && e.id.isNotEmpty) {
      final String prenom = e.prenom.isNotEmpty
          ? e.prenom
          : (prenoms[e.id] ?? '');
      if (prenom.isNotEmpty) {
        personnes[e.id] = (
          nom: nomEnseignant(prenom, e.titre),
          clePhotoEnseignant: e.clePhoto,
        );
        nomDeLEnseignant = personnes[e.id]!.nom;
      }
    }
    return AnnuaireSeance._(personnes, nomDeLEnseignant);
  }

  const AnnuaireSeance._(this._personnes, this.enseignant);

  final Map<String, PersonneSeance> _personnes;

  /// Le nom de l'enseignant de la seance (« Sayyida Amina »), meme avant
  /// son entree (« En attente de Sayyida Amina »), ou `null`.
  final String? enseignant;

  /// « Sayyid Prenom » ou « Sayyida Prenom » ; le prenom seul sans titre.
  static String nomEnseignant(String prenom, TitreEnseignant? titre) =>
      switch (titre) {
        TitreEnseignant.sayyid => t.salle.seance.enseignantTitre(
          titre: t.tc.groupe.enseignant.sayyid,
          prenom: prenom,
        ),
        TitreEnseignant.sayyida => t.salle.seance.enseignantTitre(
          titre: t.tc.groupe.enseignant.sayyida,
          prenom: prenom,
        ),
        null => prenom,
      };

  /// La personne derriere [identite], ou `null`.
  PersonneSeance? personne(String identite) => _personnes[identite];

  /// Le participant nomme : le nom de l'annuaire, sinon celui du jeton s'il
  /// en porte un qui n'est pas l'identite, sinon « Participant ».
  ParticipantSalle nommer(ParticipantSalle p) {
    final PersonneSeance? connue = _personnes[p.identite];
    if (connue != null) {
      return p.nomme(
        nom: connue.nom,
        clePhotoEnseignant: connue.clePhotoEnseignant,
      );
    }
    final bool nomDuJeton = p.nom.isNotEmpty && p.nom != p.identite;
    return p.nomme(nom: nomDuJeton ? p.nom : t.salle.participant);
  }
}
