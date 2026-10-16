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
    return AnnoncesDeLaClasse(
      annonces: List<AnnonceClasse>.unmodifiable(<AnnonceClasse>[
        for (final Map<String, dynamic> a in listeJson(v['annonces']))
          annonceClasseJson(a, libelles),
      ]),
      capacites: <CapaciteAnnonces>{
        if (v['peut_publier'] == true) CapaciteAnnonces.publier,
      },
    );
  }

  @override
  Future<AnnonceClasse?> annonce(String id) async {
    if (!estUuid(id)) return null;
    try {
      final Object? v = await _lire('com_annonce_lire', <String, dynamic>{
        'p_annonce_id': id,
      });
      return v == null ? null : annonceClasseJson(objetJson(v), libelles);
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
