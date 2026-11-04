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
// - les camarades de l'eleve adulte, par sa Classe
//   (`participants_classe_eleve_adulte`, PHOTOS-2b) : « Prenom » ;
// - personne de connu : « Participant » chez l'enseignant et le controleur,
//   qui lisent la liste ; **aucun nom** chez l'eleve et le tuteur (PHOTOS-2b,
//   pilote, 04/11/2026) : un enfant ne lit pas le prenom de ses camarades
//   (protection des mineurs, decision du pilote du 04/11/2026), la vignette
//   garde la photo ouverte par K-44 ou un cercle neutre ; jamais l'identite.
//
// Pur : il ne lit que ce que `SallePage` a deja lu, n'ouvre aucun appel.

import '../../core/i18n/strings.g.dart';
import '../../core/presence/service_presence.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/video/video_session_provider.dart';
import 'vue_salle.dart' show RoleSalle;

/// Une personne connue de la seance.
typedef PersonneSeance = ({String nom, String? clePhotoEnseignant});

/// Un camarade de Classe connu par son identifiant de profil et son prenom.
typedef CamaradeSeance = ({String id, String prenom});

/// L'enseignant de la seance, tel que l'appelant peut le lire ; [titre]
/// `null` quand il n'est pas renseigne (jamais devine). [pays] : le pays de
/// l'enseignant (DRAPEAUX, 04/11/2026), nul s'il n'est pas lisible ou si
/// l'identite est masquee.
typedef FicheEnseignantSeance = ({
  String id,
  String prenom,
  TitreEnseignant? titre,
  String? clePhoto,
  String? pays,
});

/// L'annuaire d'une seance : l'identite LiveKit vers la personne.
class AnnuaireSeance {
  /// Compose l'annuaire depuis la presence lue et l'enseignant de la Classe.
  ///
  /// [camarades] : les prenoms de la Classe que l'appelant a le droit de lire
  /// (l'eleve adulte) ; la presence passe devant. [nommerLesInconnus] : vrai
  /// chez qui lit la liste des participants (enseignant, controleur), qui
  /// garde « Participant » ; faux ailleurs, ou l'inconnu reste sans nom.
  factory AnnuaireSeance({
    List<PresenceParticipant>? presence,
    FicheEnseignantSeance? enseignant,
    List<CamaradeSeance> camarades = const <CamaradeSeance>[],
    bool nommerLesInconnus = true,
  }) {
    final Map<String, PersonneSeance> personnes = <String, PersonneSeance>{
      for (final CamaradeSeance c in camarades)
        if (c.id.isNotEmpty && c.prenom.trim().isNotEmpty)
          c.id: (nom: c.prenom.trim(), clePhotoEnseignant: null),
    };
    final Map<String, String> prenoms = <String, String>{};
    String? nomDeLEnseignant;
    String? paysDeLEnseignant;
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
        paysDeLEnseignant = e.pays;
      }
    }
    return AnnuaireSeance._(
      personnes,
      nomDeLEnseignant,
      paysDeLEnseignant,
      nommerLesInconnus,
    );
  }

  const AnnuaireSeance._(
    this._personnes,
    this.enseignant,
    this.paysEnseignant,
    this._nommerLesInconnus,
  );

  final bool _nommerLesInconnus;

  /// Le pays de l'enseignant de la seance (DRAPEAUX), seulement quand son nom
  /// est connu ; `null` sinon.
  final String? paysEnseignant;

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
  /// en porte un qui n'est pas l'identite, sinon « Participant » chez qui
  /// lit la liste, et aucun nom ailleurs (PHOTOS-2b).
  ParticipantSalle nommer(ParticipantSalle p) {
    final PersonneSeance? connue = _personnes[p.identite];
    if (connue != null) {
      return p.nomme(
        nom: connue.nom,
        clePhotoEnseignant: connue.clePhotoEnseignant,
      );
    }
    final bool nomDuJeton = p.nom.isNotEmpty && p.nom != p.identite;
    return p.nomme(
      nom: nomDuJeton
          ? p.nom
          : _nommerLesInconnus
          ? t.salle.participant
          : '',
    );
  }
}
