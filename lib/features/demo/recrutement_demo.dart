// Doubles de demonstration du recrutement enseignant (RECRUT-ECRANS, contrat
// C-19). Donnees fictives, jamais envoyees au serveur ; le code, l'empreinte,
// l'horodatage et les statuts sont SIMULES ici, le serveur les portera.
// Aucun adaptateur `*_supabase.dart` n'est ecrit par ce lot (zone de Codex).

import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

import '../../core/domain/enums.dart';
import '../../core/recrutement/port_invitations_enseignant.dart';
import '../../core/recrutement/port_signature_contrat.dart';
import '../../core/recrutement/port_statuts_signature.dart';

/// Les codes de demonstration que le candidat peut saisir, un par issue.
abstract final class CodesInvitationDemo {
  /// Un code valable.
  static const String valide = 'DEMO-VALIDE';

  /// Un code dont l'echeance est passee.
  static const String expire = 'DEMO-EXPIRE';

  /// Un code deja consomme.
  static const String utilise = 'DEMO-UTILISE';
}

/// Les invitations en memoire : l'administration invite, liste, revoque ; le
/// candidat verifie un code.
class InvitationsDemo
    implements PortInvitationsEnseignant, PortVerificationInvitation {
  /// Cree le port ; [maintenant] fixe l'horloge simulee du serveur.
  InvitationsDemo({DateTime? maintenant})
    : _maintenant = maintenant ?? DateTime.now().toUtc() {
    _invitations.addAll(<Invitation>[
      Invitation(
        code: CodesInvitationDemo.valide,
        email: 'candidat.valide@exemple.test',
        expireLe: _maintenant.add(const Duration(days: 6)),
        etat: EtatInvitation.active,
      ),
      Invitation(
        code: CodesInvitationDemo.utilise,
        email: 'candidat.inscrit@exemple.test',
        expireLe: _maintenant.add(const Duration(days: 2)),
        etat: EtatInvitation.utilisee,
        utiliseeLe: _maintenant.subtract(const Duration(days: 1)),
      ),
      Invitation(
        code: CodesInvitationDemo.expire,
        email: 'candidat.tardif@exemple.test',
        expireLe: _maintenant.subtract(const Duration(days: 3)),
        etat: EtatInvitation.expiree,
      ),
    ]);
  }

  final DateTime _maintenant;
  final List<Invitation> _invitations = <Invitation>[];
  int _compteur = 0;

  /// Une adresse qui a deja un compte, pour montrer le refus.
  static const String emailCompteExistant = 'existant@exemple.test';

  @override
  Future<Invitation> inviter(String email) async {
    final String propre = email.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(propre)) {
      throw const EmailInvalide();
    }
    if (propre == emailCompteExistant) {
      throw const CompteExistant();
    }
    for (final Invitation i in _invitations) {
      if (i.email == propre && i.etat == EtatInvitation.active) {
        throw DejaInvite(i);
      }
    }
    _compteur += 1;
    final Invitation nouvelle = Invitation(
      code: 'DEMO-${1000 + _compteur}',
      email: propre,
      expireLe: _maintenant.add(const Duration(days: 7)),
      etat: EtatInvitation.active,
    );
    _invitations.insert(0, nouvelle);
    return nouvelle;
  }

  @override
  Future<List<Invitation>> lister() async =>
      List<Invitation>.unmodifiable(_invitations);

  @override
  Future<void> revoquer(String code) async {
    final int rang = _invitations.indexWhere((Invitation i) => i.code == code);
    if (rang < 0 || _invitations[rang].etat != EtatInvitation.active) return;
    final Invitation i = _invitations[rang];
    _invitations[rang] = Invitation(
      code: i.code,
      email: i.email,
      expireLe: i.expireLe,
      etat: EtatInvitation.revoquee,
    );
  }

  @override
  Future<ResultatInvitation> verifierInvitation(String code) async {
    final String propre = code.trim().toUpperCase();
    for (final Invitation i in _invitations) {
      if (i.code != propre) continue;
      return switch (i.etat) {
        EtatInvitation.active => InvitationValide(expireLe: i.expireLe),
        EtatInvitation.expiree => InvitationExpiree(expireLe: i.expireLe),
        EtatInvitation.utilisee => const InvitationDejaUtilisee(),
        // Un code revoque ne se distingue pas d'un code inconnu : rien a
        // reveler.
        EtatInvitation.revoquee => const InvitationInconnue(),
      };
    }
    return const InvitationInconnue();
  }
}

/// Le scenario de la signature de demonstration.
enum ScenarioSignatureDemo {
  /// Rien de signe : le parcours complet.
  nonSigne,

  /// Deja signe a la version courante : la page en lecture.
  dejaSigne,

  /// La premiere signature echoue (le texte a change), puis la version
  /// courante passe a la suivante.
  versionPerimee,
}

/// La signature du contrat d'enseignant, en memoire.
class SignatureContratDemo implements PortSignatureContrat {
  /// Cree le port dans un [scenario].
  SignatureContratDemo({
    this.scenario = ScenarioSignatureDemo.nonSigne,
    DateTime? maintenant,
  }) : _maintenant = maintenant ?? DateTime.now().toUtc() {
    if (scenario == ScenarioSignatureDemo.dejaSigne) {
      _signature = Signature(
        kind: SorteContrat.contratEnseignant,
        version: _version,
        sha256: _empreinte(_texte(_version)),
        nomSaisi: 'Yasmine Haddad',
        signeLe: _maintenant.subtract(const Duration(days: 2)),
      );
    }
  }

  /// Le scenario joue.
  final ScenarioSignatureDemo scenario;

  final DateTime _maintenant;
  String _version = '2026-10-jur';
  Signature? _signature;

  static String _texte(String version) =>
      'Contrat d\'enseignant de Rewayah Academy, version $version.\n\n'
      'Texte de demonstration : le texte reel est celui valide par le '
      'directeur, servi tel quel par le serveur.\n\n'
      'Article 1. L\'enseignant donne ses cours dans la classe qui lui est '
      'attribuee, aux horaires convenus.\n\n'
      'Article 2. Les coordonnees des familles restent dans l\'application.';

  static String _empreinte(String texte) =>
      crypto.sha256.convert(utf8.encode(texte)).toString();

  @override
  Future<ContratCourant> contratCourant(SorteContrat kind) async {
    final String texte = _texte(_version);
    return ContratCourant(
      kind: kind,
      version: _version,
      texte: texte,
      sha256: _empreinte(texte),
    );
  }

  @override
  Future<Signature> signerContrat(
    SorteContrat kind,
    String version,
    String nomSaisi,
  ) async {
    final String nom = nomSaisi.trim();
    if (nom.isEmpty) throw const NomVide();
    if (nom.length > 120) throw const NomTropLong();
    if (scenario == ScenarioSignatureDemo.versionPerimee &&
        version == '2026-10-jur') {
      _version = '2026-10-jur-2';
      throw VersionPerimee(_version);
    }
    // Idempotent : une signature existante a cette version est rendue telle
    // quelle.
    final Signature? existante = _signature;
    if (existante != null && existante.version == version) return existante;
    final Signature s = Signature(
      kind: kind,
      version: version,
      sha256: _empreinte(_texte(version)),
      nomSaisi: nom,
      signeLe: _maintenant,
    );
    _signature = s;
    return s;
  }

  @override
  Future<Signature?> maSignature(SorteContrat kind) async => _signature;

  @override
  Future<String> copieSigneeUrl(SorteContrat kind) async =>
      'https://exemple.test/copie-signee/demo';
}

/// Les statuts de signature des dossiers de demonstration : la plupart sont
/// complets ; deux ne le sont pas (un contrat ancien, un contrat absent), et
/// ce sont deux dossiers que la demonstration ferme deja pour une autre
/// raison, pour ne changer aucun parcours existant.
class StatutsSignatureDemo implements PortStatutsSignature {
  /// Cree le port ; [parDossier] remplace les statuts d'un dossier.
  const StatutsSignatureDemo({
    this.parDossier = const <String, StatutsSignature>{
      'demo-dossier-10': StatutsSignature(
        contrat: SigneAncienneVersion('2026-09'),
        accuse: SigneVersionCourante(),
      ),
      'demo-dossier-09': StatutsSignature(
        contrat: NonSigne(),
        accuse: SigneVersionCourante(),
      ),
    },
  });

  /// Les statuts propres a un dossier.
  final Map<String, StatutsSignature> parDossier;

  @override
  Future<StatutsSignature?> pour(String dossierId) async =>
      parDossier[dossierId] ??
      const StatutsSignature(
        contrat: SigneVersionCourante(),
        accuse: SigneVersionCourante(),
      );
}
