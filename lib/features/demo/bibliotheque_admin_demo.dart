// CAP29-0 : le double de demonstration de la bibliotheque d'administration.
// Rien ne quitte l'appareil, aucun R2, aucun secret (K-28).
//
// Il simule ce que le serveur fera (lots CAP29-BACK-1 et CAP29-BACK-2) :
// - un catalogue de 240 supports, tous les types et tous les etats ;
// - des versions : une version publiee est immuable, une nouvelle version est
//   un nouveau brouillon ;
// - des droits revus a part, avec un controle de publication calcule depuis
//   l'etat reel (jamais un compteur code en dur) ;
// - un depot de fichier par intention, avec progression, annulation, echec ;
// - une revision par support : une ecriture perimee est un conflit ;
// - l'attribution aux classes (35 classes paralleles) et le retrait.
import 'dart:async';
import 'dart:typed_data';

import '../../core/admin/modeles_bibliotheque_admin.dart';
import '../../core/admin/port_bibliotheque_admin.dart';
import '../../core/mouvement/mouvement.dart';

/// Un support tel que le serveur simule le connait.
class _Etat {
  _Etat({
    required this.support,
    required this.versions,
    required this.droits,
    required this.historique,
    this.titreCourt = '',
    this.edition,
    this.organisme,
    this.description,
    this.fichierDepose = false,
    this.motifRetrait,
  });

  SupportAdmin support;
  List<VersionSupport> versions;
  DroitsSupport droits;
  List<EvenementAudit> historique;
  String titreCourt;
  String? edition;
  String? organisme;
  String? description;
  String? conditions;
  bool fichierDepose;
  int revision = 1;
  String? motifRetrait;
  final Set<String> classes = <String>{};
  bool epingle = false;
}

/// Le double de demonstration du port.
class BibliothequeAdminDemo implements PortBibliothequeAdmin {
  /// Cree le double. [pas] : le delai simule de chaque pas d'un depot.
  /// [echecDepot] : le prochain depot echoue ainsi.
  BibliothequeAdminDemo({
    this.droitsServeur = const CapacitesBibliotheque(
      peutLire: true,
      peutImporter: true,
      peutPublier: true,
      peutAttribuer: true,
    ),
    this.pas = Mouvement.court,
    this.echecDepot,
    int nombre = 240,
    DateTime? maintenant,
  }) : maintenant = maintenant ?? DateTime.utc(2026, 10, 10, 12) {
    for (int i = 0; i < nombre; i++) {
      final _Etat e = _generer(i);
      _supports[e.support.id] = e;
    }
  }

  /// Ce que la personne connectee peut faire.
  CapacitesBibliotheque droitsServeur;

  /// Le delai simule d'un pas de depot.
  final Duration pas;

  /// Si non nul, le prochain depot echoue avec cette cause (puis se remet a
  /// nul).
  ErreurUpload? echecDepot;

  /// « Maintenant », fixe pour des tests deterministes.
  final DateTime maintenant;

  /// Vrai : la lecture echoue, pour l'etat d'erreur.
  bool panne = false;

  final Map<String, _Etat> _supports = <String, _Etat>{};
  final Map<String, String> _uploads = <String, String>{};
  final Set<String> _annules = <String>{};
  int _compteur = 0;

  /// Les 35 classes paralleles de la demonstration.
  static final List<ClasseAttribuable> toutesLesClasses = <ClasseAttribuable>[
    for (int i = 1; i <= 35; i++)
      ClasseAttribuable(
        id: 'demo-classe-${i.toString().padLeft(2, '0')}',
        nom: 'Classe ${i.toString().padLeft(2, '0')}',
      ),
  ];

  static const List<String> _titres = <String>[
    'Introduction au Tajwid',
    'Les règles du Noon sākin',
    'Mémorisation de Juz Amma',
    'Alphabet arabe illustré',
    'Fiqh de la prière',
    'La vie du Prophète',
    'Les noms d\'Allah',
    'Récit des prophètes',
    'Invocations du quotidien',
    'Écriture des lettres',
  ];
  static const List<String> _categories = <String>[
    'Tajwid',
    'Mémorisation',
    'Langue arabe',
    'Fiqh',
    'Sira',
    'Éducation islamique',
  ];
  static const List<String> _niveaux = <String>['Débutant', 'Moyen', 'Avancé'];
  static const List<String> _langues = <String>['fr', 'ar', 'en'];

  _Etat _generer(int i) {
    final TypeRessource type = TypeRessource.values[i % 5];
    // Repartition des etats : 0 brouillon, 1 a verifier, 2 publie, 3 publie,
    // 4 retire, 5 droits expires.
    final int cas = i % 6;
    final String id = 'demo-support-${(i + 1).toString().padLeft(3, '0')}';
    final StatutVersionRessource statut = switch (cas) {
      0 || 1 => StatutVersionRessource.brouillon,
      _ => StatutVersionRessource.publiee,
    };
    final RevueDroits revue = switch (cas) {
      0 => RevueDroits.aVerifier,
      1 => RevueDroits.aVerifier,
      5 => RevueDroits.expire,
      _ => RevueDroits.approuve,
    };
    final DateTime modifie = maintenant.subtract(Duration(hours: 3 + i * 7));
    final String titre = '${_titres[i % _titres.length]} ${(i ~/ 10) + 1}';
    final bool retire = cas == 4;
    final SupportAdmin s = SupportAdmin(
      id: id,
      titre: titre,
      type: type,
      langue: _langues[i % _langues.length],
      categorie: _categories[i % _categories.length],
      niveau: i % 7 == 0 ? null : _niveaux[i % _niveaux.length],
      numeroVersion: 1 + (i % 3 == 0 ? 1 : 0),
      statutVersion: statut,
      revueDroits: revue,
      visibilite: statut == StatutVersionRessource.publiee
          ? PolitiqueAcces.groupeAssigne
          : PolitiqueAcces.admin,
      modifieLeUtc: modifie,
      retire: retire,
    );
    final int n = s.numeroVersion ?? 1;
    final List<VersionSupport> versions = <VersionSupport>[
      for (int k = n; k >= 1; k--)
        VersionSupport(
          id: '$id-v$k',
          numero: k,
          statut: k == n ? statut : StatutVersionRessource.archivee,
          revueDroits: k == n ? revue : RevueDroits.approuve,
          publieeLeUtc: k == n && statut != StatutVersionRessource.publiee
              ? null
              : modifie.subtract(Duration(days: 9 * (n - k) + 1)),
          empreinte: 'sha256:${id.hashCode.toRadixString(16)}$k',
        ),
    ];
    final bool rempli =
        revue == RevueDroits.approuve || revue == RevueDroits.expire;
    return _Etat(
      support: s,
      versions: versions,
      titreCourt: titre.length > 22 ? titre.substring(0, 22) : titre,
      edition: i % 4 == 0 ? 'Édition ${2020 + i % 6}' : null,
      organisme: rempli ? 'Éditions de démonstration' : null,
      description: 'Support de démonstration numéro ${i + 1}.',
      droits: DroitsSupport(
        revue: revue,
        sourceTitre: rempli ? 'Source de démonstration ${i + 1}' : null,
        titulaire: rempli ? 'Titulaire de démonstration' : null,
        preuveFournie: rempli,
        usages: rempli
            ? <UsageDroit>{UsageDroit.application, UsageDroit.classe}
            : const <UsageDroit>{},
        attribution: rempli
            ? 'Avec l\'aimable autorisation du titulaire.'
            : null,
        expireLeUtc: revue == RevueDroits.expire
            ? maintenant.subtract(const Duration(days: 12))
            : null,
      ),
      fichierDepose: statut == StatutVersionRessource.publiee || cas == 1,
      historique: <EvenementAudit>[
        if (statut == StatutVersionRessource.publiee)
          EvenementAudit(
            action: ActionAudit.publication,
            acteur: 'Administration',
            quandUtc: modifie,
            numeroVersion: n,
          ),
        if (retire)
          EvenementAudit(
            action: ActionAudit.retrait,
            acteur: 'Administration',
            quandUtc: modifie,
            motif: 'Licence non renouvelée.',
          ),
        EvenementAudit(
          action: ActionAudit.creation,
          acteur: 'Administration',
          quandUtc: modifie.subtract(const Duration(days: 2)),
          numeroVersion: 1,
        ),
      ],
      motifRetrait: retire ? 'Licence non renouvelée.' : null,
    );
  }

  CapacitesSupport _capacitesDe(_Etat e) => CapacitesSupport(
    peutModifier: droitsServeur.peutImporter && !e.support.retire,
    peutPublier: droitsServeur.peutPublier,
    peutAttribuer: droitsServeur.peutAttribuer,
    peutRetirer: droitsServeur.peutPublier,
  );

  void _garde() {
    if (panne) throw const BibliothequeHorsLigne();
    if (!droitsServeur.peutLire) throw const BibliothequeNonAutorisee();
  }

  _Etat _trouve(String id) {
    final _Etat? e = _supports[id];
    if (e == null) throw const BibliothequeIntrouvable();
    return e;
  }

  void _toucher(_Etat e, {ActionAudit? action, String? motif, int? version}) {
    e.revision++;
    e.support = SupportAdmin(
      id: e.support.id,
      titre: e.support.titre,
      type: e.support.type,
      langue: e.support.langue,
      categorie: e.support.categorie,
      niveau: e.support.niveau,
      numeroVersion: e.versions.isEmpty ? null : e.versions.first.numero,
      statutVersion: e.versions.isEmpty
          ? StatutVersionRessource.brouillon
          : e.versions.first.statut,
      revueDroits: e.droits.revue,
      visibilite: e.support.visibilite,
      modifieLeUtc: maintenant.add(Duration(minutes: ++_compteur)),
      retire: e.support.retire,
    );
    if (action != null) {
      e.historique.insert(
        0,
        EvenementAudit(
          action: action,
          acteur: 'Administration',
          quandUtc: e.support.modifieLeUtc,
          motif: motif,
          numeroVersion: version,
        ),
      );
    }
  }

  @override
  Future<CapacitesBibliotheque> capacites() async {
    if (panne) throw const BibliothequeHorsLigne();
    return droitsServeur;
  }

  @override
  Future<PageSupports> lister({
    FiltreCatalogue filtre = const FiltreCatalogue(),
    String? curseur,
    int limite = 25,
  }) async {
    _garde();
    final String q = filtre.recherche.trim().toLowerCase();
    final List<SupportAdmin> tous =
        <SupportAdmin>[
          for (final _Etat e in _supports.values)
            if (_correspond(e.support, filtre, q)) e.support,
        ]..sort((SupportAdmin a, SupportAdmin b) {
          final int c = b.modifieLeUtc.compareTo(a.modifieLeUtc);
          return c != 0 ? c : a.id.compareTo(b.id);
        });
    final int debut = int.tryParse(curseur ?? '') ?? 0;
    final int fin = (debut + limite).clamp(0, tous.length);
    return PageSupports(
      elements: tous.sublist(debut.clamp(0, tous.length), fin),
      curseur: fin < tous.length ? '$fin' : null,
    );
  }

  static bool _correspond(SupportAdmin s, FiltreCatalogue f, String q) {
    final bool etat = switch (f.etat) {
      EtatCatalogue.tous => true,
      EtatCatalogue.brouillons =>
        !s.retire && s.statutVersion == StatutVersionRessource.brouillon,
      EtatCatalogue.aVerifier =>
        !s.retire && s.revueDroits == RevueDroits.aVerifier,
      EtatCatalogue.publies => s.publie,
      EtatCatalogue.retires => s.retire,
      EtatCatalogue.droitsExpires => s.revueDroits == RevueDroits.expire,
    };
    if (!etat) return false;
    if (f.type != null && s.type != f.type) return false;
    if (f.niveau != null && s.niveau != f.niveau) return false;
    if (f.langue != null && s.langue != f.langue) return false;
    if (q.isNotEmpty &&
        !s.titre.toLowerCase().contains(q) &&
        !s.categorie.toLowerCase().contains(q)) {
      return false;
    }
    return true;
  }

  @override
  Future<FicheSupport> fiche(String supportId) async {
    _garde();
    final _Etat e = _trouve(supportId);
    return FicheSupport(
      support: e.support,
      revision: e.revision,
      titreCourt: e.titreCourt,
      edition: e.edition,
      organisme: e.organisme,
      description: e.description,
      conditionsAttribution: e.conditions,
      versions: List<VersionSupport>.of(e.versions),
      droits: e.droits,
      historique: List<EvenementAudit>.of(e.historique),
      capacites: _capacitesDe(e),
      classesServies: e.classes.length,
      motifRetrait: e.motifRetrait,
    );
  }

  @override
  Future<String> creerBrouillon(NouveauSupport saisie) async {
    _garde();
    if (!droitsServeur.peutImporter) throw const BibliothequeNonAutorisee();
    final String id =
        'demo-support-nouveau-${(++_compteur).toString().padLeft(3, '0')}';
    final DateTime quand = maintenant.add(Duration(minutes: _compteur));
    final VersionSupport v = VersionSupport(
      id: '$id-v1',
      numero: 1,
      statut: StatutVersionRessource.brouillon,
      revueDroits: RevueDroits.aVerifier,
    );
    _supports[id] = _Etat(
      support: SupportAdmin(
        id: id,
        titre: saisie.titre,
        type: saisie.type,
        langue: saisie.langue,
        categorie: saisie.categorie,
        niveau: saisie.niveau,
        numeroVersion: 1,
        statutVersion: StatutVersionRessource.brouillon,
        revueDroits: RevueDroits.aVerifier,
        visibilite: PolitiqueAcces.admin,
        modifieLeUtc: quand,
      ),
      versions: <VersionSupport>[v],
      droits: DroitsSupport(revue: RevueDroits.aVerifier),
      historique: <EvenementAudit>[
        EvenementAudit(
          action: ActionAudit.creation,
          acteur: 'Administration',
          quandUtc: quand,
          numeroVersion: 1,
        ),
      ],
      titreCourt: saisie.titre,
    );
    return id;
  }

  @override
  Future<ResultatEcriture> mettreAJour({
    required String supportId,
    required ModificationSupport modification,
    required int revisionAttendue,
  }) async {
    _garde();
    final _Etat e = _trouve(supportId);
    if (!droitsServeur.peutImporter) throw const BibliothequeNonAutorisee();
    if (e.revision != revisionAttendue) return const EcritureEnConflit();
    final ModificationSupport m = modification;
    if (m.titre != null) {
      e.support = SupportAdmin(
        id: e.support.id,
        titre: m.titre!,
        type: e.support.type,
        langue: e.support.langue,
        categorie: e.support.categorie,
        niveau: e.support.niveau,
        numeroVersion: e.support.numeroVersion,
        statutVersion: e.support.statutVersion,
        revueDroits: e.support.revueDroits,
        visibilite: m.visibilite ?? e.support.visibilite,
        modifieLeUtc: e.support.modifieLeUtc,
        retire: e.support.retire,
      );
    }
    e.titreCourt = m.titreCourt ?? e.titreCourt;
    e.edition = m.edition ?? e.edition;
    e.organisme = m.organisme ?? e.organisme;
    e.description = m.description ?? e.description;
    e.conditions = m.conditionsAttribution ?? e.conditions;
    _toucher(e);
    return EcritureFaite(revision: e.revision);
  }

  @override
  Future<String> nouvelleVersion(String supportId) async {
    _garde();
    final _Etat e = _trouve(supportId);
    if (!droitsServeur.peutImporter) throw const BibliothequeNonAutorisee();
    final int n = (e.versions.first.numero) + 1;
    e.versions.insert(
      0,
      VersionSupport(
        id: '$supportId-v$n',
        numero: n,
        statut: StatutVersionRessource.brouillon,
        revueDroits: RevueDroits.aVerifier,
      ),
    );
    // Changer de version reinitialise la revue juridique (spec M02).
    e.droits = DroitsSupport(
      revue: RevueDroits.aVerifier,
      sourceTitre: e.droits.sourceTitre,
      titulaire: e.droits.titulaire,
    );
    e.fichierDepose = false;
    _toucher(e, action: ActionAudit.creation, version: n);
    return '$supportId-v$n';
  }

  @override
  Future<IntentionUpload> demanderUpload({
    required String supportId,
    required FichierADeposer fichier,
  }) async {
    _garde();
    final _Etat e = _trouve(supportId);
    if (!droitsServeur.peutImporter) throw const BibliothequeNonAutorisee();
    if (e.versions.first.statut != StatutVersionRessource.brouillon) {
      throw const BibliothequeNonAutorisee();
    }
    final String id = 'demo-upload-${++_compteur}';
    _uploads[id] = supportId;
    return IntentionUpload(
      id: id,
      expireLeUtc: maintenant.add(const Duration(minutes: 15)),
    );
  }

  @override
  Stream<ProgressionUpload> deposer({
    required String uploadId,
    Uint8List? octets,
  }) async* {
    final String? supportId = _uploads[uploadId];
    if (supportId == null) {
      yield const ProgressionUpload(
        phase: PhaseUpload.echec,
        erreur: ErreurUpload.refuse,
      );
      return;
    }
    yield const ProgressionUpload(phase: PhaseUpload.envoi);
    final ErreurUpload? echec = echecDepot;
    for (int k = 1; k <= 4; k++) {
      await Future<void>.delayed(pas);
      if (_annules.remove(uploadId)) {
        yield const ProgressionUpload(phase: PhaseUpload.annule);
        return;
      }
      if (echec != null && k == 3) {
        echecDepot = null;
        yield ProgressionUpload(
          phase: PhaseUpload.echec,
          partie: 0.5,
          erreur: echec,
        );
        return;
      }
      yield ProgressionUpload(phase: PhaseUpload.envoi, partie: k / 4);
    }
    yield const ProgressionUpload(
      phase: PhaseUpload.enAttenteConfirmation,
      partie: 1,
    );
    await Future<void>.delayed(pas);
    yield const ProgressionUpload(phase: PhaseUpload.verification, partie: 1);
    await Future<void>.delayed(pas);
    final _Etat e = _trouve(supportId);
    e.fichierDepose = true;
    _toucher(e, action: ActionAudit.depot, version: e.versions.first.numero);
    yield const ProgressionUpload(phase: PhaseUpload.pret, partie: 1);
  }

  @override
  Future<void> annulerUpload(String uploadId) async {
    _annules.add(uploadId);
  }

  @override
  Future<ResultatEcriture> revoirDroits({
    required String supportId,
    required String versionId,
    required SaisieDroits saisie,
    required int revisionAttendue,
  }) async {
    _garde();
    final _Etat e = _trouve(supportId);
    if (!droitsServeur.peutImporter) throw const BibliothequeNonAutorisee();
    if (e.revision != revisionAttendue) return const EcritureEnConflit();
    final bool complet =
        (saisie.sourceTitre ?? '').trim().isNotEmpty &&
        (saisie.titulaire ?? '').trim().isNotEmpty &&
        saisie.preuveFournie &&
        saisie.usages.isNotEmpty;
    final RevueDroits revue = saisie.approuver && complet
        ? RevueDroits.approuve
        : RevueDroits.aVerifier;
    e.droits = DroitsSupport(
      revue: revue,
      sourceTitre: saisie.sourceTitre,
      titulaire: saisie.titulaire,
      preuveFournie: saisie.preuveFournie,
      usages: saisie.usages,
      attribution: saisie.attribution,
      expireLeUtc: saisie.expireLeUtc,
    );
    final VersionSupport v = e.versions.first;
    e.versions[0] = VersionSupport(
      id: v.id,
      numero: v.numero,
      statut: v.statut,
      revueDroits: revue,
      publieeLeUtc: v.publieeLeUtc,
      empreinte: v.empreinte,
    );
    _toucher(e, action: ActionAudit.revueDroits, version: v.numero);
    return EcritureFaite(revision: e.revision);
  }

  ControleVersion _controle(_Etat e) {
    final DroitsSupport d = e.droits;
    EtatCritere ok(bool b) => b ? EtatCritere.valide : EtatCritere.bloque;
    final List<CritereControle> c = <CritereControle>[
      CritereControle(
        cle: CleCritere.source,
        etat: ok((d.sourceTitre ?? '').trim().isNotEmpty),
      ),
      CritereControle(
        cle: CleCritere.titulaire,
        etat: ok((d.titulaire ?? '').trim().isNotEmpty),
      ),
      CritereControle(cle: CleCritere.preuve, etat: ok(d.preuveFournie)),
      CritereControle(
        cle: CleCritere.usageApplication,
        etat: ok(d.usages.contains(UsageDroit.application)),
      ),
      CritereControle(
        cle: CleCritere.usageClasse,
        etat: ok(d.usages.contains(UsageDroit.classe)),
      ),
      const CritereControle(
        cle: CleCritere.usageTelechargement,
        etat: EtatCritere.valide,
      ),
      CritereControle(
        cle: CleCritere.expirationAttribution,
        etat: d.expireLeUtc != null && d.expireLeUtc!.isBefore(maintenant)
            ? EtatCritere.bloque
            : EtatCritere.valide,
      ),
      CritereControle(cle: CleCritere.fichierSain, etat: ok(e.fichierDepose)),
      // Aucun rendu reel n'est teste par le double : jamais presume valide.
      CritereControle(
        cle: CleCritere.renduTeste,
        etat: e.fichierDepose ? EtatCritere.valide : EtatCritere.inconnu,
      ),
      CritereControle(
        cle: CleCritere.langueNiveau,
        etat: ok(e.support.niveau != null),
      ),
      CritereControle(
        cle: CleCritere.versionEmpreinte,
        etat: ok(e.fichierDepose),
      ),
    ];
    return ControleVersion(
      criteres: c,
      publiable:
          d.revue == RevueDroits.approuve &&
          c.every((CritereControle k) => k.etat == EtatCritere.valide),
    );
  }

  @override
  Future<ControleVersion> controler(String versionId) async {
    _garde();
    final String supportId = versionId.substring(
      0,
      versionId.lastIndexOf('-v'),
    );
    return _controle(_trouve(supportId));
  }

  @override
  Future<ResultatPublication> publier({
    required String supportId,
    required String versionId,
    required int revisionAttendue,
    required String cle,
  }) async {
    _garde();
    final _Etat e = _trouve(supportId);
    if (!droitsServeur.peutPublier) throw const BibliothequeNonAutorisee();
    if (e.revision != revisionAttendue) return const PublicationEnConflit();
    final ControleVersion c = _controle(e);
    if (!c.publiable) return PublicationBloquee(c);
    final VersionSupport v = e.versions.first;
    e.versions[0] = VersionSupport(
      id: v.id,
      numero: v.numero,
      statut: StatutVersionRessource.publiee,
      revueDroits: v.revueDroits,
      publieeLeUtc: maintenant.add(Duration(minutes: ++_compteur)),
      empreinte: v.empreinte ?? 'sha256:demo${v.numero}',
    );
    // La version precedente passe a archivee : le pointeur courant bascule.
    for (int k = 1; k < e.versions.length; k++) {
      final VersionSupport p = e.versions[k];
      if (p.statut == StatutVersionRessource.publiee) {
        e.versions[k] = VersionSupport(
          id: p.id,
          numero: p.numero,
          statut: StatutVersionRessource.archivee,
          revueDroits: p.revueDroits,
          publieeLeUtc: p.publieeLeUtc,
          empreinte: p.empreinte,
        );
      }
    }
    e.support = SupportAdmin(
      id: e.support.id,
      titre: e.support.titre,
      type: e.support.type,
      langue: e.support.langue,
      categorie: e.support.categorie,
      niveau: e.support.niveau,
      numeroVersion: v.numero,
      statutVersion: StatutVersionRessource.publiee,
      revueDroits: v.revueDroits,
      visibilite: PolitiqueAcces.groupeAssigne,
      modifieLeUtc: e.support.modifieLeUtc,
    );
    _toucher(e, action: ActionAudit.publication, version: v.numero);
    return VersionPubliee(revision: e.revision);
  }

  @override
  Future<PageClasses> classes({
    required String supportId,
    String? curseur,
    int limite = 25,
  }) async {
    _garde();
    final _Etat e = _trouve(supportId);
    final int debut = int.tryParse(curseur ?? '') ?? 0;
    final int fin = (debut + limite).clamp(0, toutesLesClasses.length);
    return PageClasses(
      elements: <ClasseAttribuable>[
        for (final ClasseAttribuable c in toutesLesClasses.sublist(debut, fin))
          ClasseAttribuable(
            id: c.id,
            nom: c.nom,
            dejaServie: e.classes.contains(c.id),
            epinglee: e.classes.contains(c.id) && e.epingle,
          ),
      ],
      curseur: fin < toutesLesClasses.length ? '$fin' : null,
    );
  }

  @override
  Future<ResultatEcriture> attribuer({
    required String supportId,
    required Set<String> classeIds,
    required bool epingler,
    required int revisionAttendue,
  }) async {
    _garde();
    final _Etat e = _trouve(supportId);
    if (!droitsServeur.peutAttribuer) throw const BibliothequeNonAutorisee();
    if (!e.support.publie) throw const BibliothequeNonAutorisee();
    if (e.revision != revisionAttendue) return const EcritureEnConflit();
    // Idempotent : une classe deja servie n'est pas comptee deux fois.
    e.classes.addAll(classeIds);
    e.epingle = epingler;
    _toucher(e, action: ActionAudit.attribution);
    return EcritureFaite(revision: e.revision);
  }

  @override
  Future<ResultatEcriture> retirer({
    required String supportId,
    required String motif,
    required int revisionAttendue,
  }) async {
    _garde();
    final _Etat e = _trouve(supportId);
    if (!droitsServeur.peutPublier) throw const BibliothequeNonAutorisee();
    if (e.revision != revisionAttendue) return const EcritureEnConflit();
    e.support = SupportAdmin(
      id: e.support.id,
      titre: e.support.titre,
      type: e.support.type,
      langue: e.support.langue,
      categorie: e.support.categorie,
      niveau: e.support.niveau,
      numeroVersion: e.support.numeroVersion,
      statutVersion: e.support.statutVersion,
      revueDroits: e.support.revueDroits,
      visibilite: e.support.visibilite,
      modifieLeUtc: e.support.modifieLeUtc,
      retire: true,
    );
    e.motifRetrait = motif;
    _toucher(e, action: ActionAudit.retrait, motif: motif);
    return EcritureFaite(revision: e.revision);
  }
}
