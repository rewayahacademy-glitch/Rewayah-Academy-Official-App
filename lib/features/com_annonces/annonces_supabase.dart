// L'adaptateur Supabase des annonces de Classe (COM-BACK-1 ; COM-BR-10), sur
// les RPC `com_annonce*` de la migration 20261016090100.
//
// « Publiee » et « Planifiee » ne viennent que de l'accuse du serveur. Une
// lecture refusee (Classe qui n'est pas la sienne, compte desactive) ou une
// RPC pas encore deployee se lit comme une capacite indisponible.
//
// Non branche par defaut : `portAnnoncesProvider` reste neutre tant que les
// migrations ne sont pas appliquees et que les libelles des publics ne sont
// pas valides (voir le rapport COM-BACK-1).
//
// RACCORDEMENT-1016 (E) : les annonces « toute l'academie » et « public »
// destinees a la personne (`com_annonces_academie`, migration
// 20261016102300) rejoignent la liste de chaque Classe qu'elle lit, rendues
// dans le contexte de cette Classe. Tant que la RPC n'est pas deployee, la
// liste garde les seules annonces de la Classe.

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/communications_supabase.dart';
import '../../core/communications/modeles_communication.dart';
import 'port_annonces.dart';

/// Les annonces servies par Supabase.
class AnnoncesSupabase implements PortAnnonces {
  /// Cree l'adaptateur sur un appel RPC.
  const AnnoncesSupabase(this._appel, {required this.libelles});

  final AppelRpc _appel;

  /// Les mots composes a partir des donnees du serveur.
  final LibellesCommunication libelles;

  Future<Object?> _lire(String fonction, Map<String, dynamic> p) async {
    try {
      return await _appel(fonction, p);
    } on Object catch (e) {
      if (estRefusOuAbsence(e)) throw AnnoncesIndisponibles.manque;
      rethrow;
    }
  }

  @override
  Future<AnnoncesDeLaClasse> annoncesDeClasse(String classeId) async {
    if (!estUuid(classeId)) throw AnnoncesIndisponibles.manque;
    final Map<String, dynamic> v = objetJson(
      await _lire('com_annonces_de_classe', <String, dynamic>{
        'p_groupe_id': classeId,
      }),
    );
    final List<AnnonceClasse> deLaClasse = <AnnonceClasse>[
      for (final Map<String, dynamic> a in listeJson(v['annonces']))
        annonceClasseJson(a, libelles),
    ];
    final Set<String> vues = <String>{
      for (final AnnonceClasse a in deLaClasse) a.id,
    };
    final List<AnnonceClasse> annonces = <AnnonceClasse>[
      ...deLaClasse,
      for (final AnnonceClasse a in await _annoncesAcademie(classeId))
        if (vues.add(a.id)) a,
    ]..sort(_plusRecenteDabord);
    return AnnoncesDeLaClasse(
      annonces: List<AnnonceClasse>.unmodifiable(annonces),
      capacites: <CapaciteAnnonces>{
        if (v['peut_publier'] == true) CapaciteAnnonces.publier,
      },
    );
  }

  /// Les annonces generales destinees a la personne, dans le contexte de la
  /// Classe [classeId]. Une RPC absente ou refusee n'emporte pas la liste de
  /// la Classe : elle rend une liste vide.
  Future<List<AnnonceClasse>> _annoncesAcademie(String classeId) async {
    final Object? brut;
    try {
      brut = await _appel('com_annonces_academie', <String, dynamic>{
        'p_groupe_id': classeId,
      });
    } on Object catch (e) {
      if (estRefusOuAbsence(e)) return const <AnnonceClasse>[];
      rethrow;
    }
    return <AnnonceClasse>[
      for (final Map<String, dynamic> a in listeJson(
        objetJson(brut)['annonces'],
      ))
        if (a['classe'] is Map) annonceClasseJson(a, libelles),
    ];
  }

  static int _plusRecenteDabord(AnnonceClasse a, AnnonceClasse b) {
    final int parDate = b.publieeLe.compareTo(a.publieeLe);
    return parDate != 0 ? parDate : b.id.compareTo(a.id);
  }

  @override
  Future<AnnonceClasse?> annonce(String id) async {
    if (!estUuid(id)) return null;
    try {
      final Object? v = await _lire('com_annonce_lire', <String, dynamic>{
        'p_annonce_id': id,
      });
      // Une annonce generale sans Classe de contexte (personne sans Classe)
      // ne se rend pas comme annonce de Classe.
      return v is Map && v['classe'] is Map
          ? annonceClasseJson(objetJson(v), libelles)
          : null;
    } on CapaciteIndisponible {
      return null;
    }
  }

  @override
  Future<void> marquerLue(String annonceId) async {
    if (!estUuid(annonceId)) throw ArgumentError.value(annonceId, 'annonceId');
    await _appel('com_annonce_marquer_lue', <String, dynamic>{
      'p_annonce_id': annonceId,
    });
  }

  @override
  Future<List<CibleAnnonce>> ciblesPublication({String? classeId}) async {
    if (classeId != null && !estUuid(classeId)) return const <CibleAnnonce>[];
    return List<CibleAnnonce>.unmodifiable(<CibleAnnonce>[
      for (final Map<String, dynamic> c in listeJson(
        await _lire('com_annonces_cibles', <String, dynamic>{
          'p_groupe_id': classeId,
        }),
      ))
        cibleJson(c, libelles),
    ]);
  }

  @override
  Future<AnnonceConfirmee> publier({
    required BrouillonAnnonce brouillon,
    required String cleIdempotence,
  }) async {
    final Map<String, dynamic> accuse = objetJson(
      await _appel('com_annonce_publier', <String, dynamic>{
        'p_cible': brouillon.cible.id,
        'p_titre': brouillon.titre.trim(),
        'p_texte': brouillon.texte.trim(),
        'p_programmee_le': brouillon.programmeeLe?.toUtc().toIso8601String(),
        'p_cle_idempotence': cleServeur(cleIdempotence),
      }),
    );
    return AnnonceConfirmee(
      id: texteJson(accuse, 'id'),
      etat: _etat(accuse['etat']),
      le: instantJson(accuse, 'le'),
    );
  }

  @override
  Future<AnnoncesAdministration> annoncesAdministration() async {
    final Map<String, dynamic> v = objetJson(
      await _lire('com_annonces_administration', const <String, dynamic>{}),
    );
    List<AnnonceAdministration> liste(Object? brut) =>
        List<AnnonceAdministration>.unmodifiable(<AnnonceAdministration>[
          for (final Map<String, dynamic> a in listeJson(brut))
            AnnonceAdministration(
              id: texteJson(a, 'id'),
              titre: texteJson(a, 'titre'),
              texte: texteJson(a, 'texte'),
              cible: cibleJson(objetJson(a['cible']), libelles),
              etat: _etat(a['etat']),
              le: instantJson(a, 'le'),
            ),
        ]);
    return AnnoncesAdministration(
      publiees: liste(v['publiees']),
      planifiees: liste(v['planifiees']),
    );
  }
}

EtatAnnonce _etat(Object? v) => switch (v) {
  'publiee' => EtatAnnonce.publiee,
  'planifiee' => EtatAnnonce.planifiee,
  _ => throw const FormatException('Etat d annonce inconnu.'),
};

/// Une audience rendue par le serveur.
CibleAnnonce cibleJson(Map<String, dynamic> c, LibellesCommunication libelles) {
  final NatureCible nature = switch (c['nature']) {
    'classe' => NatureCible.classe,
    'public' => NatureCible.public,
    'toutes' => NatureCible.toutes,
    _ => throw const FormatException('Nature d audience inconnue.'),
  };
  final String libelle = texteJson(c, 'libelle');
  return CibleAnnonce(
    id: texteJson(c, 'id'),
    nature: nature,
    classeId: nature == NatureCible.classe ? texteJson(c, 'classe_id') : null,
    libelle: nature == NatureCible.classe
        ? libelles.classe(libelle)
        : libelles.publicAnnonce(libelle),
  );
}

/// Une annonce de Classe rendue par le serveur.
AnnonceClasse annonceClasseJson(
  Map<String, dynamic> a,
  LibellesCommunication libelles,
) {
  final Map<String, dynamic> classe = objetJson(a['classe']);
  final bool lue = a['lue'] == true;
  final Object? auteur = a['auteur'];
  return AnnonceClasse(
    id: texteJson(a, 'id'),
    titre: texteJson(a, 'titre'),
    texte: texteJson(a, 'texte'),
    publieeLe: instantJson(a, 'publiee_le'),
    classe: ObjetLie(
      type: TypeObjetLie.classe,
      id: texteJson(classe, 'id'),
      libelle: libelles.classe(texteJson(classe, 'libelle')),
    ),
    auteur: auteur is Map
        ? participantJson(Map<String, dynamic>.from(auteur), libelles)
        : null,
    lue: lue,
  );
}
