// WHATSAPP-FAMILLE (23/11/2026) : la lecture, par la direction, du numero
// WhatsApp d'une famille (RPC `whatsapp_famille_direction`, migration
// 20261201018500). Le serveur decide de tout : direction active seulement, nul
// sous masquage d'identite, lecture journalisee. L'adaptateur lit, il ne calcule
// rien.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ce que la direction lit : le numero d'une demande d'admission, ou celui du
/// titulaire du foyer d'un eleve.
typedef CibleWhatsapp = ({String? candidatureId, String? profilId});

/// La lecture du numero.
abstract interface class PortWhatsappDirection {
  /// Le numero international (`+33612345678`), ou `null` quand il n'est pas
  /// connu.
  Future<String?> lire(CibleWhatsapp cible);
}

/// Le numero lu sur Supabase.
class WhatsappDirectionSupabase implements PortWhatsappDirection {
  /// Cree l'adaptateur.
  const WhatsappDirectionSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<String?> lire(CibleWhatsapp cible) async {
    final Object? numero = await _client.rpc<Object?>(
      'whatsapp_famille_direction',
      params: <String, dynamic>{
        'p_candidature': ?cible.candidatureId,
        'p_profil': ?cible.profilId,
      },
    );
    return numero is String && numero.isNotEmpty ? numero : null;
  }
}

/// La source du numero, posee par `main.dart` ; `null` hors production.
final Provider<PortWhatsappDirection?> portWhatsappDirectionProvider =
    Provider<PortWhatsappDirection?>((Ref _) => null);

/// Le numero d'une cible ; une source absente est une erreur, jamais un
/// numero vide.
final FutureProviderFamily<String?, CibleWhatsapp> whatsappDirectionProvider =
    FutureProvider.family<String?, CibleWhatsapp>((
      Ref ref,
      CibleWhatsapp cible,
    ) async {
      final PortWhatsappDirection? port = ref.watch(
        portWhatsappDirectionProvider,
      );
      if (port == null) {
        throw StateError('whatsapp : aucune source');
      }
      return port.lire(cible);
    });

/// Le lien qui ouvre la conversation WhatsApp avec [numero] : `wa.me`, le
/// numero sans le « + ».
Uri lienWhatsapp(String numero) =>
    Uri.https('wa.me', '/${numero.replaceAll(RegExp('[^0-9]'), '')}');
