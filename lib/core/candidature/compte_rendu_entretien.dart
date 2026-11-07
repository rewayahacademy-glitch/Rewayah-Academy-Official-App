/// SALLE-2-ENTRETIEN (07/11/2026) : le compte rendu d'une personne qui mene
/// l'entretien, sur `ecrire_compte_rendu_entretien` (V1-a, deja en
/// production, jamais appelee jusqu'ici).
///
/// Le serveur decide : seul un participant de l'entretien, du cote de la
/// candidature, au compte valide, ecrit SON compte rendu, apres le debut et
/// tant que l'issue n'est pas consignee. Il le reecrit autant qu'il veut
/// (une ligne par auteur). Les refus metier arrivent dans la reponse.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import '../capacites/permission_insuffisante.dart';
import 'port_entretiens_direction.dart' show dependanceEntretiens;

/// L'avis du compte rendu (lu par la direction seulement).
enum AvisEntretien {
  /// « Avis favorable ».
  favorable('favorable'),

  /// « Avis reserve ».
  reserve('reserve'),

  /// « Avis defavorable ».
  defavorable('defavorable');

  const AvisEntretien(this.valeurSql);

  /// La valeur en base.
  final String valeurSql;
}

/// Ce qu'on ecrit.
class CompteRenduAEcrire {
  /// Cree le compte rendu.
  const CompteRenduAEcrire({
    required this.texte,
    required this.avis,
    this.memorisation,
    this.tajwid,
    this.ijaza,
    this.riwayat = const <String>[],
  });

  /// Le texte libre (1 a 4000 signes).
  final String texte;

  /// L'avis.
  final AvisEntretien avis;

  /// Le constat de memorisation (codes de la salle d'examen), ou `null`.
  final String? memorisation;

  /// Le constat de tajwid, ou `null`.
  final String? tajwid;

  /// L'ijaza presentee (`oui`, `pret_test`, `non`), ou `null`.
  final String? ijaza;

  /// Les riwayat observees (codes).
  final List<String> riwayat;
}

/// Le refus d'une ecriture.
enum RefusCompteRendu {
  /// L'entretien n'a pas encore commence.
  pasCommence,

  /// L'issue est deja consignee.
  consigne,

  /// Le texte est vide ou trop long.
  texteInvalide,

  /// Un code du constat est refuse.
  constatInvalide,

  /// Toute autre raison.
  autre,
}

/// La porte du compte rendu.
abstract interface class PortCompteRenduEntretien {
  /// Ecrit (ou reecrit) mon compte rendu de [sessionId]. Rend `null` quand
  /// il est enregistre, le refus sinon.
  Future<RefusCompteRendu?> ecrire(String sessionId, CompteRenduAEcrire cr);
}

/// L'adaptateur Supabase.
class CompteRenduEntretienSupabase implements PortCompteRenduEntretien {
  /// Cree l'adaptateur.
  const CompteRenduEntretienSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<RefusCompteRendu?> ecrire(
    String sessionId,
    CompteRenduAEcrire cr,
  ) async {
    final Object? brut;
    try {
      brut = await _client.rpc<Object?>(
        'ecrire_compte_rendu_entretien',
        params: <String, dynamic>{
          'p_session': sessionId,
          'p_texte': cr.texte,
          'p_avis': cr.avis.valeurSql,
          'p_memorisation': cr.memorisation,
          'p_tajwid': cr.tajwid,
          'p_riwayat': cr.riwayat,
          'p_ijaza': cr.ijaza,
        },
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw const PermissionInsuffisante('ecrire_compte_rendu_entretien');
      }
      if (e.code == 'PGRST202' || e.code == '42883') {
        throw const CapaciteIndisponible(dependanceEntretiens);
      }
      rethrow;
    }
    final Object? erreur = brut is Map ? brut['erreur'] : null;
    if (erreur == null) return null;
    return switch (erreur) {
      'entretien_pas_commence' => RefusCompteRendu.pasCommence,
      'entretien_consigne' => RefusCompteRendu.consigne,
      'texte_invalide' => RefusCompteRendu.texteInvalide,
      'constat_invalide' => RefusCompteRendu.constatInvalide,
      _ => RefusCompteRendu.autre,
    };
  }
}

/// Le port ; absent avant le branchement (la capacite est alors
/// indisponible, jamais un faux enregistrement).
final Provider<PortCompteRenduEntretien?> portCompteRenduEntretienProvider =
    Provider<PortCompteRenduEntretien?>((Ref _) => null);
