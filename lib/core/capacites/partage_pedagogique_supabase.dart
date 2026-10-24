// Adaptateur PED-APRES-BACK : le partage pedagogique avec les familles, sur les
// RPC de la migration 20261018190000 (et X2-20, X2-21).
//
// **Le serveur decide** : la regle effective, l'etat de diffusion, la
// projection familiale. Ici, aucun calcul, aucune regle : on decode strictement
// (`FormatException` plutot qu'une valeur inventee) et on traduit les refus.
//
// Erreurs : 42501 devient [PermissionInsuffisante], 40001 devient
// [ConflitPartage], une fonction absente (PGRST202) devient
// [CapaciteIndisponible]. Toute autre erreur (reseau, serveur) remonte telle
// quelle : l'ecran dit l'echec ou le hors ligne, jamais un faux vide.
//
// Les mots viennent de l'application (slang), pas du serveur : le serveur rend
// des codes (`a_renforcer`, `makharij`...), l'adaptateur les nomme.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../i18n/strings.g.dart';
import 'capacite_indisponible.dart';
import 'permission_insuffisante.dart';
import 'port_partage_pedagogique.dart';
import 'rpc_finance_supabase.dart'
    show
        AppelRpc,
        appelRpcSupabase,
        booleenJson,
        entierJson,
        instantJson,
        listeJson,
        objetJson,
        texteJson,
        texteNullableJson;

/// Les mots que l'adaptateur donne aux codes du serveur.
abstract interface class LibellesPartagePedagogique {
  /// L'etat montre a la famille : `a_renforcer` ou `acquis`.
  String appreciation(String code);

  /// Un point a renforcer : `makharij`, `madd`, `ghunna`, `waqf`, `fluidite`,
  /// `memorisation`.
  String pointARenforcer(String code);

  /// L'intitule d'une rubrique du cahier lu par la direction.
  String rubrique(String code);

  /// Le texte d'une valeur de rubrique a choix (performance, suite).
  String valeur(String rubrique, String code);
}

/// Les mots de l'application, lus dans slang a chaque appel.
class LibellesPartageSlang implements LibellesPartagePedagogique {
  /// Cree les libelles.
  const LibellesPartageSlang();

  @override
  String appreciation(String code) => switch (code) {
    'a_renforcer' => t.historique.compteRendu.etatARenforcer,
    'acquis' => t.historique.compteRendu.etatAcquis,
    _ => throw FormatException('appreciation inconnue: $code'),
  };

  @override
  String pointARenforcer(String code) => switch (code) {
    'makharij' => t.enseignant.cahier.faiblesseMakharij,
    'madd' => t.enseignant.cahier.faiblesseMadd,
    'ghunna' => t.enseignant.cahier.faiblesseGhunna,
    'waqf' => t.enseignant.cahier.faiblesseWaqf,
    'fluidite' => t.enseignant.cahier.faiblesseFluidite,
    'memorisation' => t.enseignant.cahier.faiblesseMemorisation,
    _ => throw FormatException('point inconnu: $code'),
  };

  @override
  String rubrique(String code) => switch (code) {
    'performance' => t.enseignant.cahier.performance,
    'faiblesses' => t.enseignant.cahier.faiblesses,
    'point_phonetique' => t.enseignant.cahier.pointPhonetique,
    'travail_maison' => t.admin.groupes.cahiers.rubriqueTravail,
    'objectif_personnel' => t.admin.groupes.cahiers.rubriqueObjectif,
    'suite' => t.admin.groupes.cahiers.rubriqueSuite,
    'motif_exception' => t.admin.groupes.cahiers.rubriqueMotif,
    _ => throw FormatException('rubrique inconnue: $code'),
  };

  @override
  String valeur(String rubrique, String code) => switch ((rubrique, code)) {
    ('performance', 'aRevoir') => t.enseignant.cahier.niveauARevoir,
    ('performance', 'enProgres') => t.enseignant.cahier.niveauEnProgres,
    ('performance', 'acquis') => t.enseignant.cahier.niveauAcquis,
    ('performance', 'maitrise') => t.enseignant.cahier.niveauMaitrise,
    ('suite', 'continuer') => t.enseignant.cahier.suiteContinuer,
    ('suite', 'renforcer') => t.enseignant.cahier.suiteRenforcer,
    ('suite', 'suspendreNouveau') => t.enseignant.cahier.suspendreNouveau,
    _ => throw FormatException('valeur inconnue: $rubrique/$code'),
  };
}

/// Le partage pedagogique servi par Supabase.
class PartagePedagogiqueSupabase implements PortPartagePedagogique {
  /// Cree l'adaptateur sur le client de l'application.
  PartagePedagogiqueSupabase(
    SupabaseClient client, {
    this.libelles = const LibellesPartageSlang(),
  }) : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  PartagePedagogiqueSupabase.avecAppel(
    this._appel, {
    this.libelles = const LibellesPartageSlang(),
  });

  final AppelRpc _appel;

  /// Les mots donnes aux codes du serveur.
  final LibellesPartagePedagogique libelles;

  /// La dependance nommee quand une fonction manque (trace, jamais affichee).
  static const String dependance = 'PED-APRES-BACK';

  Future<Object?> _rpc(String fonction, Map<String, dynamic> params) async {
    try {
      return await _appel(fonction, params);
    } on PostgrestException catch (e) {
      switch (e.code) {
        case 'PGRST202':
          throw const CapaciteIndisponible(dependance);
        case '42501':
          throw PermissionInsuffisante(fonction);
        case '40001':
          throw const ConflitPartage();
      }
      rethrow;
    }
  }

  @override
  Future<CompteRenduFamille> compteRenduFamille({
    required String seanceId,
    required String eleveId,
  }) async => decoderCompteRenduFamille(
    await _rpc('compte_rendu_famille', <String, dynamic>{
      'p_seance_id': seanceId,
      'p_eleve_id': eleveId,
    }),
    libelles,
  );

  @override
  Future<PartageClasse> partageClasse({
    required String classeId,
    int page = 1,
    String? recherche,
  }) async => decoderPartageClasse(
    await _rpc('partage_classe', <String, dynamic>{
      'p_classe_id': classeId,
      'p_page': page,
      'p_recherche': recherche,
    }),
  );

  @override
  Future<PartageClasse> definirPartageClasse({
    required String classeId,
    required bool actif,
    required String versionAttendue,
    required String cleIdempotence,
  }) async => decoderPartageClasse(
    await _rpc('definir_partage_classe', <String, dynamic>{
      'p_classe_id': classeId,
      'p_actif': actif,
      'p_version_attendue': versionAttendue,
      'p_cle_idempotence': cleIdempotence,
    }),
  );

  @override
  Future<PartageClasse> definirRegleEleve({
    required String classeId,
    required String eleveId,
    required ReglePartageEleve regle,
    required String versionAttendue,
    required String cleIdempotence,
  }) async => decoderPartageClasse(
    await _rpc('definir_regle_partage_eleve', <String, dynamic>{
      'p_classe_id': classeId,
      'p_eleve_id': eleveId,
      'p_regle': regle.name,
      'p_version_attendue': versionAttendue,
      'p_cle_idempotence': cleIdempotence,
    }),
  );

  @override
  Future<List<LigneCompteRendu>> comptesRendusEleve({
    required String classeId,
    required String eleveId,
  }) async {
    final Map<String, dynamic> j = objetJson(
      await _rpc('comptes_rendus_eleve', <String, dynamic>{
        'p_classe_id': classeId,
        'p_eleve_id': eleveId,
      }),
      'comptes_rendus_eleve',
    );
    return List<LigneCompteRendu>.unmodifiable(<LigneCompteRendu>[
      for (final Object? l in listeJson(j['lignes'], 'lignes'))
        _ligneCompteRendu(objetJson(l, 'ligne')),
    ]);
  }

  @override
  Future<PageCahiersClasse> comptesRendusClasse({
    required String classeId,
    int page = 1,
    EtatDiffusion? filtreEtat,
  }) async {
    final Map<String, dynamic> j = objetJson(
      await _rpc('comptes_rendus_classe', <String, dynamic>{
        'p_classe_id': classeId,
        'p_page': page,
        'p_filtre_etat': filtreEtat?.name,
      }),
      'comptes_rendus_classe',
    );
    return PageCahiersClasse(
      lignes: List<LigneCahierClasse>.unmodifiable(<LigneCahierClasse>[
        for (final Object? l in listeJson(j['lignes'], 'lignes'))
          _ligneCahierClasse(objetJson(l, 'ligne')),
      ]),
      total: entierJson(j, 'total'),
      page: entierJson(j, 'page'),
    );
  }

  @override
  Future<CahierAdmin> lireCahierAdmin({
    required String seanceId,
    required String eleveId,
  }) async => decoderCahierAdmin(
    await _rpc('lire_cahier_admin', <String, dynamic>{
      'p_seance_id': seanceId,
      'p_eleve_id': eleveId,
    }),
    libelles,
  );

  @override
  Future<ApercuAdmin> apercuFamilial({
    required String seanceId,
    required String eleveId,
  }) async => decoderApercuAdmin(
    await _rpc('apercu_familial', <String, dynamic>{
      'p_seance_id': seanceId,
      'p_eleve_id': eleveId,
    }),
    libelles,
  );

  @override
  Future<ApercuAdmin> publier({
    required String seanceId,
    required String eleveId,
    required String versionAttendue,
    required String cleIdempotence,
  }) async {
    await _rpc('publier_resume_seance', <String, dynamic>{
      'p_session_id': seanceId,
      'p_student_id': eleveId,
      'p_version_attendue': versionAttendue,
      'p_cle_idempotence': cleIdempotence,
    });
    return apercuFamilial(seanceId: seanceId, eleveId: eleveId);
  }

  @override
  Future<ApercuAdmin> revoquer({
    required String seanceId,
    required String eleveId,
    required String versionAttendue,
    required String cleIdempotence,
  }) async {
    await _rpc('revoquer_resume_seance', <String, dynamic>{
      'p_session_id': seanceId,
      'p_student_id': eleveId,
      'p_version_attendue': versionAttendue,
      'p_cle_idempotence': cleIdempotence,
    });
    return apercuFamilial(seanceId: seanceId, eleveId: eleveId);
  }

  // --- Decodage strict ------------------------------------------------------

  /// Decode `compte_rendu_famille`.
  static CompteRenduFamille decoderCompteRenduFamille(
    Object? brut, [
    LibellesPartagePedagogique libelles = const LibellesPartageSlang(),
  ]) {
    final Map<String, dynamic> j = objetJson(brut, 'compte_rendu');
    final EtatCompteRendu etat = switch (texteJson(j, 'etat')) {
      'partage' => EtatCompteRendu.partage,
      'nonPartage' => EtatCompteRendu.nonPartage,
      'enAttente' => EtatCompteRendu.enAttente,
      'aucunChamp' => EtatCompteRendu.aucunChamp,
      final String autre => throw FormatException('etat inconnu: $autre'),
    };
    // Un etat sans contenu ne porte aucun champ : on ne lit rien d'autre.
    if (etat != EtatCompteRendu.partage) return CompteRenduFamille(etat: etat);
    return _projection(j, etat, libelles);
  }

  static CompteRenduFamille _projection(
    Map<String, dynamic> j,
    EtatCompteRendu etat,
    LibellesPartagePedagogique libelles,
  ) {
    final String? appreciation = texteNullableJson(j, 'appreciation');
    final Object? corrige = j['corrige_le'];
    return CompteRenduFamille(
      etat: etat,
      travaille: texteNullableJson(j, 'travaille'),
      appreciation: appreciation == null
          ? null
          : libelles.appreciation(appreciation),
      aRenforcer: List<String>.unmodifiable(<String>[
        for (final Object? p in listeJson(j['a_renforcer'], 'a_renforcer'))
          libelles.pointARenforcer(p! as String),
      ]),
      aPreparer: List<String>.unmodifiable(<String>[
        for (final Object? p in listeJson(j['a_preparer'], 'a_preparer'))
          p! as String,
      ]),
      commentairePartage: texteNullableJson(j, 'commentaire_partage'),
      corrigeLe: corrige == null ? null : instantJson(corrige, 'corrige_le'),
    );
  }

  static EtatDiffusion _etatDiffusion(Object? v) {
    for (final EtatDiffusion e in EtatDiffusion.values) {
      if (e.name == v) return e;
    }
    throw FormatException('etat de diffusion inconnu: $v');
  }

  static SourceRegle _source(Object? v) {
    for (final SourceRegle s in SourceRegle.values) {
      if (s.name == v) return s;
    }
    throw FormatException('source de regle inconnue: $v');
  }

  static ReglePartageEleve _regle(Object? v) {
    for (final ReglePartageEleve r in ReglePartageEleve.values) {
      if (r.name == v) return r;
    }
    throw FormatException('regle inconnue: $v');
  }

  /// Decode `partage_classe` (et les ecritures, qui rendent la meme forme).
  static PartageClasse decoderPartageClasse(Object? brut) {
    final Map<String, dynamic> j = objetJson(brut, 'partage_classe');
    final Object? modifie = j['modifie_le'];
    return PartageClasse(
      classeId: texteJson(j, 'classe_id'),
      actif: booleenJson(j, 'actif'),
      version: texteJson(j, 'version'),
      total: entierJson(j, 'total'),
      page: entierJson(j, 'page'),
      modifieLe: modifie == null ? null : instantJson(modifie, 'modifie_le'),
      eleves: List<PartageEleve>.unmodifiable(<PartageEleve>[
        for (final Object? e in listeJson(j['eleves'], 'eleves'))
          _partageEleve(objetJson(e, 'eleve')),
      ]),
    );
  }

  static PartageEleve _partageEleve(Map<String, dynamic> j) {
    final Object? modifie = j['modifie_le'];
    return PartageEleve(
      eleveId: texteJson(j, 'eleve_id'),
      libelle: texteJson(j, 'libelle'),
      regle: _regle(j['regle']),
      source: _source(j['source']),
      visible: booleenJson(j, 'visible'),
      situation: switch (j['situation']) {
        'actif' => SituationEleveClasse.actif,
        'retire' => SituationEleveClasse.retire,
        final Object? autre => throw FormatException(
          'situation inconnue: $autre',
        ),
      },
      modifieLe: modifie == null ? null : instantJson(modifie, 'modifie_le'),
    );
  }

  static LigneCompteRendu _ligneCompteRendu(Map<String, dynamic> j) =>
      LigneCompteRendu(
        seanceId: texteJson(j, 'seance_id'),
        seanceLe: instantJson(j['seance_le'], 'seance_le'),
        etat: _etatDiffusion(j['etat']),
      );

  static LigneCahierClasse _ligneCahierClasse(Map<String, dynamic> j) =>
      LigneCahierClasse(
        seanceId: texteJson(j, 'seance_id'),
        eleveId: texteJson(j, 'eleve_id'),
        elevePrenom: texteJson(j, 'eleve_prenom'),
        seanceLe: instantJson(j['seance_le'], 'seance_le'),
        etat: _etatDiffusion(j['etat']),
      );

  /// Decode `apercu_familial`.
  static ApercuAdmin decoderApercuAdmin(
    Object? brut, [
    LibellesPartagePedagogique libelles = const LibellesPartageSlang(),
  ]) {
    final Map<String, dynamic> j = objetJson(brut, 'apercu');
    final Map<String, dynamic> apercu = objetJson(j['apercu'], 'apercu.apercu');
    final Object? maj = j['mis_a_jour_le'];
    final Object? source = j['source_regle'];
    final CompteRenduFamille projection = _projection(
      apercu,
      EtatCompteRendu.partage,
      libelles,
    );
    return ApercuAdmin(
      seanceId: texteJson(j, 'seance_id'),
      eleveId: texteJson(j, 'eleve_id'),
      elevePrenom: texteJson(j, 'eleve_prenom'),
      classeLibelle: texteJson(j, 'classe_libelle'),
      seanceLe: instantJson(j['seance_le'], 'seance_le'),
      enseignant: texteNullableJson(j, 'enseignant'),
      etat: _etatDiffusion(j['etat']),
      regleEffective: booleenJson(j, 'regle_effective'),
      sourceRegle: source == null ? null : _source(source),
      // Une fiche sans champ ne se montre pas comme un compte rendu vide.
      apercu: projection.aDuContenu
          ? projection
          : const CompteRenduFamille(etat: EtatCompteRendu.aucunChamp),
      version: texteJson(j, 'version'),
      historique: List<ActionPartage>.unmodifiable(<ActionPartage>[
        for (final Object? a in listeJson(j['historique'], 'historique'))
          _action(objetJson(a, 'action')),
      ]),
      misAJourLe: maj == null ? null : instantJson(maj, 'mis_a_jour_le'),
    );
  }

  static ActionPartage _action(Map<String, dynamic> j) => ActionPartage(
    quand: instantJson(j['quand'], 'quand'),
    type: texteJson(j, 'type'),
    auteur: texteNullableJson(j, 'auteur'),
  );

  /// Decode `lire_cahier_admin`. Les rubriques de l'evaluation sont nommees
  /// avec les mots de l'application ; une cle que l'on ne sait pas nommer est
  /// ignoree plutot qu'affichee brute.
  static CahierAdmin decoderCahierAdmin(
    Object? brut, [
    LibellesPartagePedagogique libelles = const LibellesPartageSlang(),
  ]) {
    final Map<String, dynamic> j = objetJson(brut, 'cahier');
    final Map<String, dynamic> eval = objetJson(j['evaluation'], 'evaluation');
    final Object? corrige = j['corrige_le'];
    final List<RubriqueInterne> rubriques = <RubriqueInterne>[];
    for (final String cle in const <String>[
      'performance',
      'faiblesses',
      'point_phonetique',
      'travail_maison',
      'objectif_personnel',
      'suite',
    ]) {
      final Object? v = eval[cle];
      if (v == null) continue;
      final String texte = switch (cle) {
        'performance' || 'suite' => libelles.valeur(cle, v as String),
        'faiblesses' => listeJson(
          v,
          cle,
        ).map((Object? p) => libelles.pointARenforcer(p! as String)).join(', '),
        _ => v as String,
      };
      if (texte.isNotEmpty) {
        rubriques.add(
          RubriqueInterne(libelle: libelles.rubrique(cle), texte: texte),
        );
      }
    }
    return CahierAdmin(
      seanceId: texteJson(j, 'seance_id'),
      eleveId: texteJson(j, 'eleve_id'),
      elevePrenom: texteJson(j, 'eleve_prenom'),
      classeLibelle: texteJson(j, 'classe_libelle'),
      seanceLe: instantJson(j['seance_le'], 'seance_le'),
      confirme: booleenJson(j, 'confirme'),
      enseignant: texteNullableJson(j, 'enseignant'),
      evaluation: List<RubriqueInterne>.unmodifiable(rubriques),
      // Le serveur ne rend aujourd'hui qu'un detail interne : le motif de
      // l'exception. Son intitule vient de l'application, pas du serveur.
      detailsInternes: List<RubriqueInterne>.unmodifiable(<RubriqueInterne>[
        for (final Object? d in listeJson(
          j['details_internes'],
          'details_internes',
        ))
          RubriqueInterne(
            libelle: libelles.rubrique('motif_exception'),
            texte: texteJson(objetJson(d, 'detail'), 'texte'),
          ),
      ]),
      corrigeLe: corrige == null ? null : instantJson(corrige, 'corrige_le'),
    );
  }
}
