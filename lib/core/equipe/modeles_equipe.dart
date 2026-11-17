// BE-2b : les modeles de l'ecran « Equipe » (missions, attributions, personnes,
// invitations d'associes). Le serveur decide de tout (portee, droit, journal) ;
// ces classes ne font que lire ses reponses (`lister_missions`,
// `lister_attributions`, `lister_personnes_mission`, `lister_gestes_mission`,
// `invitations_associe_admin`). Une valeur illisible est ecartee, jamais devinee.
library;

import '../candidature/modeles_candidature.dart' show EtapeCandidature;

/// Une mission : un nom et une liste fermee de gestes, reutilisable par
/// plusieurs personnes.
class Mission {
  /// Cree une mission.
  const Mission({
    required this.id,
    required this.nom,
    required this.gestes,
    required this.porteurs,
    required this.archivee,
  });

  /// Lit une mission, ou `null` quand la ligne est illisible.
  static Mission? depuisJson(Object? brut) {
    if (brut is! Map) return null;
    final Object? id = brut['id'];
    final Object? nom = brut['nom'];
    final Object? gestes = brut['gestes'];
    if (id is! String || nom is! String || gestes is! List) return null;
    return Mission(
      id: id,
      nom: nom,
      gestes: List<String>.unmodifiable(<String>[
        for (final Object? g in gestes)
          if (g is String) g,
      ]),
      porteurs: brut['porteurs'] is num ? (brut['porteurs'] as num).toInt() : 0,
      archivee: brut['archiveeLe'] != null,
    );
  }

  /// L'identifiant.
  final String id;

  /// Le nom, choisi par la direction.
  final String nom;

  /// Les codes des gestes (liste fermee du serveur).
  final List<String> gestes;

  /// Le nombre de personnes qui la portent aujourd'hui.
  final int porteurs;

  /// Vrai quand la mission est archivee.
  final bool archivee;
}

/// Le perimetre d'une attribution tel que le serveur l'a ecrit : le cote est
/// celui de la personne, jamais choisi.
class PerimetreMission {
  /// Cree un perimetre.
  const PerimetreMission({
    this.cote,
    this.langues = const <String>[],
    this.etapes = const <EtapeCandidature>[],
    this.dossiers = 0,
  });

  /// Lit un perimetre ; un objet illisible donne un perimetre vide.
  static PerimetreMission depuisJson(Object? brut) {
    if (brut is! Map) return const PerimetreMission();
    final Object? langues = brut['langues'];
    final Object? etapes = brut['etapes'];
    final Object? dossiers = brut['dossiers'];
    return PerimetreMission(
      cote: brut['cote'] is String ? brut['cote'] as String : null,
      langues: List<String>.unmodifiable(<String>[
        if (langues is List)
          for (final Object? l in langues)
            if (l is String) l,
      ]),
      etapes: List<EtapeCandidature>.unmodifiable(<EtapeCandidature>[
        if (etapes is List)
          for (final Object? e in etapes)
            if (EtapeCandidature.depuisSql(e) case final EtapeCandidature v) v,
      ]),
      dossiers: dossiers is List ? dossiers.length : 0,
    );
  }

  /// `male` ou `female`, tel que le serveur l'a ecrit ; `null` si absent.
  final String? cote;

  /// Les langues (codes du questionnaire) ; vide : toutes.
  final List<String> langues;

  /// Les etapes ; vide : toutes.
  final List<EtapeCandidature> etapes;

  /// Le nombre de dossiers confies (BE-2c) ; 0 : pas de liste.
  final int dossiers;
}

/// Une mission accordee a une personne.
class Attribution {
  /// Cree une attribution.
  const Attribution({
    required this.id,
    required this.missionId,
    required this.mission,
    required this.profil,
    required this.nom,
    required this.role,
    required this.perimetre,
    required this.debut,
    required this.fin,
    required this.active,
    required this.retiree,
    this.motifRetrait,
  });

  /// Lit une attribution, ou `null` quand la ligne est illisible.
  static Attribution? depuisJson(Object? brut) {
    if (brut is! Map) return null;
    final Object? id = brut['id'];
    final Object? missionId = brut['missionId'];
    final Object? mission = brut['mission'];
    final Object? profil = brut['profil'];
    final DateTime? debut = brut['debut'] is String
        ? DateTime.tryParse(brut['debut'] as String)?.toUtc()
        : null;
    if (id is! String ||
        missionId is! String ||
        mission is! String ||
        profil is! String ||
        debut == null) {
      return null;
    }
    return Attribution(
      id: id,
      missionId: missionId,
      mission: mission,
      profil: profil,
      nom: brut['nomProfil'] is String ? (brut['nomProfil'] as String) : '',
      role: brut['roleProfil'] is String ? brut['roleProfil'] as String : '',
      perimetre: PerimetreMission.depuisJson(brut['perimetre']),
      debut: debut,
      fin: brut['fin'] is String
          ? DateTime.tryParse(brut['fin'] as String)?.toUtc()
          : null,
      active: brut['active'] == true,
      retiree: brut['retireeLe'] != null,
      motifRetrait: brut['motifRetrait'] is String
          ? brut['motifRetrait'] as String
          : null,
    );
  }

  /// L'identifiant de l'attribution.
  final String id;

  /// La mission accordee.
  final String missionId;

  /// Le nom de la mission.
  final String mission;

  /// Le compte qui la porte.
  final String profil;

  /// Le nom de la personne ; vide quand le serveur ne le rend pas.
  final String nom;

  /// Le role de la personne (`associe`, `teacher`, `accountant`).
  final String role;

  /// Le perimetre.
  final PerimetreMission perimetre;

  /// Le debut.
  final DateTime debut;

  /// La fin ; `null` : sans fin.
  final DateTime? fin;

  /// Vrai quand elle est en vigueur maintenant (serveur).
  final bool active;

  /// Vrai quand elle a ete retiree.
  final bool retiree;

  /// Le motif du retrait, s'il y en a un.
  final String? motifRetrait;
}

/// Une personne qui peut recevoir une mission.
class PersonneMission {
  /// Cree une personne.
  const PersonneMission({
    required this.id,
    required this.nom,
    required this.role,
    required this.cote,
  });

  /// Lit une personne, ou `null`.
  static PersonneMission? depuisJson(Object? brut) {
    if (brut is! Map) return null;
    final Object? id = brut['id'];
    final Object? nom = brut['nom'];
    final Object? role = brut['role'];
    final Object? cote = brut['cote'];
    if (id is! String || nom is! String || role is! String || cote is! String) {
      return null;
    }
    return PersonneMission(id: id, nom: nom, role: role, cote: cote);
  }

  /// L'identifiant du compte.
  final String id;

  /// Le nom.
  final String nom;

  /// Le role.
  final String role;

  /// `male` ou `female` : le cote ou la personne porte sa mission.
  final String cote;
}

/// L'etat d'une invitation d'associe.
enum EtatInvitationAssocie {
  /// En attente de reponse.
  active('active'),

  /// Consommee : le compte existe.
  utilisee('utilisee'),

  /// Expiree.
  expiree('expiree'),

  /// Revoquee par la direction.
  revoquee('revoquee');

  const EtatInvitationAssocie(this.valeurSql);

  /// La valeur du serveur.
  final String valeurSql;

  /// Lit un etat, ou `null`.
  static EtatInvitationAssocie? depuisSql(Object? v) {
    for (final EtatInvitationAssocie e in values) {
      if (e.valeurSql == v) return e;
    }
    return null;
  }
}

/// Une invitation d'associe.
class InvitationAssocie {
  /// Cree une invitation.
  const InvitationAssocie({
    required this.id,
    required this.code,
    required this.courriel,
    required this.etat,
    required this.expireLe,
    this.nom,
  });

  /// Lit une invitation, ou `null`.
  static InvitationAssocie? depuisJson(Object? brut) {
    if (brut is! Map) return null;
    final Object? id = brut['id'];
    final Object? code = brut['code'];
    final Object? email = brut['email'];
    final EtatInvitationAssocie? etat = EtatInvitationAssocie.depuisSql(
      brut['etat'],
    );
    final DateTime? expire = brut['expire_le'] is String
        ? DateTime.tryParse(brut['expire_le'] as String)?.toUtc()
        : null;
    if (id is! String ||
        code is! String ||
        email is! String ||
        etat == null ||
        expire == null) {
      return null;
    }
    return InvitationAssocie(
      id: id,
      code: code,
      courriel: email,
      etat: etat,
      expireLe: expire,
      nom: brut['nom'] is String ? brut['nom'] as String : null,
    );
  }

  /// L'identifiant.
  final String id;

  /// Le code, lu par la direction.
  final String code;

  /// L'adresse invitee.
  final String courriel;

  /// L'etat.
  final EtatInvitationAssocie etat;

  /// L'echeance.
  final DateTime expireLe;

  /// Le nom de la personne, s'il a ete donne.
  final String? nom;
}

/// Ce que rend `inviter_associe`.
enum StatutInvitation {
  /// L'invitation est creee.
  creee,

  /// Une invitation active existe deja pour cette adresse.
  dejaInvite,

  /// L'adresse n'est pas lisible.
  emailInvalide,

  /// Un compte existe deja avec cette adresse.
  compteExistant,
}

/// Le retour d'une invitation.
class ResultatInvitation {
  /// Cree un resultat.
  const ResultatInvitation({required this.statut, this.invitation});

  /// Lit la reponse du serveur ; `null` quand elle est illisible.
  static ResultatInvitation? depuisJson(Object? brut) {
    if (brut is! Map) return null;
    final StatutInvitation? statut = switch (brut['statut']) {
      'creee' => StatutInvitation.creee,
      'deja_invite' => StatutInvitation.dejaInvite,
      'email_invalide' => StatutInvitation.emailInvalide,
      'compte_existant' => StatutInvitation.compteExistant,
      _ => null,
    };
    if (statut == null) return null;
    return ResultatInvitation(
      statut: statut,
      invitation: InvitationAssocie.depuisJson(brut['invitation']),
    );
  }

  /// Le statut.
  final StatutInvitation statut;

  /// L'invitation, quand il y en a une.
  final InvitationAssocie? invitation;
}
