/// PHOTO-CANDIDATURE-FIGEE (07/11/2026) : la photo envoyee avec une
/// candidature, figee dans le dossier a l'envoi des reponses
/// (`candidatures.photo_cle_figee`, migration 20261121300000). La direction
/// la lit par `photo_dossier_candidat(p_id)`, sous la garde de
/// `lire_candidature` ; la photo d'affichage de la personne, elle, reste libre
/// et n'est jamais lue ici.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import '../photos/photo_personne.dart';

/// La photo du dossier : son emplacement, ou rien.
@immutable
class PhotoDossier {
  /// Cree la lecture.
  const PhotoDossier({this.seau, this.cle, this.figeeLe});

  /// Le seau de stockage.
  final String? seau;

  /// La cle de l'objet ; `null` : aucune photo envoyee avec la candidature.
  final String? cle;

  /// Quand la photo a ete figee.
  final DateTime? figeeLe;
}

/// Lit la reponse de `photo_dossier_candidat`.
PhotoDossier photoDossierDepuis(Object? brut) {
  if (brut is! Map || brut['erreur'] != null) return const PhotoDossier();
  final Object? seau = brut['seau'];
  final Object? cle = brut['cle'];
  return PhotoDossier(
    seau: seau is String ? seau : null,
    cle: cle is String && cle.isNotEmpty ? cle : null,
    figeeLe: DateTime.tryParse('${brut['figeeLe']}'),
  );
}

/// La lecture de la photo d'un dossier.
abstract interface class PortPhotoDossier {
  /// La photo figee de la candidature [candidatureId].
  Future<PhotoDossier> lire(String candidatureId);
}

class _Indisponible implements PortPhotoDossier {
  const _Indisponible();

  @override
  Future<PhotoDossier> lire(String _) => Future<PhotoDossier>.error(
    const CapaciteIndisponible('photo_dossier_candidat'),
  );
}

/// L'adaptateur Supabase.
class PhotoDossierSupabase implements PortPhotoDossier {
  /// Cree l'adaptateur.
  const PhotoDossierSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<PhotoDossier> lire(String candidatureId) async => photoDossierDepuis(
    await _client.rpc<Object?>(
      'photo_dossier_candidat',
      params: <String, dynamic>{'p_id': candidatureId},
    ),
  );
}

/// Le port ; l'application le surcharge avec l'adaptateur Supabase.
final Provider<PortPhotoDossier> portPhotoDossierProvider =
    Provider<PortPhotoDossier>((Ref _) => const _Indisponible());

/// La photo du dossier et son URL signee (`null` : aucune photo). Relue seule
/// avant l'expiration de l'URL, comme `photoPersonneProvider`.
final FutureProviderFamily<({String? url, DateTime? figeeLe}), String>
photoDossierProvider = FutureProvider.autoDispose
    .family<({String? url, DateTime? figeeLe}), String>((
      Ref ref,
      String candidatureId,
    ) async {
      final PhotoDossier p = await ref
          .watch(portPhotoDossierProvider)
          .lire(candidatureId);
      final String? seau = p.seau;
      final String? cle = p.cle;
      if (seau == null || cle == null) {
        return (url: null, figeeLe: p.figeeLe);
      }
      final String url = await ref
          .watch(portPhotosProvider)
          .urlSignee(seau, cle);
      final Timer relecture = Timer(dureeVieUrl, ref.invalidateSelf);
      ref.onDispose(relecture.cancel);
      return (url: url, figeeLe: p.figeeLe);
    });
