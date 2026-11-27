// WHATSAPP-FAMILLE (23/11/2026) : le numero WhatsApp de la famille, lu et
// corrige par la famille elle-meme (RPC `mon_whatsapp` et
// `definir_mon_whatsapp`, migration 20261201018500). Les comptes inscrits avant
// la demande n'ont pas de numero : rien n'est invente, l'accueil le demande.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ce que la famille a donne.
typedef EtatWhatsapp = ({bool possible, String? numero});

/// La lecture et l'ecriture du numero de la famille.
abstract interface class PortWhatsappFamille {
  /// L'etat : `possible` est faux pour un compte sans demande d'admission.
  Future<EtatWhatsapp> lire();

  /// Enregistre [numero] (format international, `+33612345678`).
  Future<void> definir(String numero);
}

/// Le port servi par Supabase.
class WhatsappFamilleSupabase implements PortWhatsappFamille {
  /// Cree l'adaptateur.
  const WhatsappFamilleSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<EtatWhatsapp> lire() async {
    final Object? json = await _client.rpc<Object?>('mon_whatsapp');
    if (json is! Map) {
      return (possible: false, numero: null);
    }
    final Object? numero = json['numero'];
    return (
      possible: json['possible'] == true,
      numero: numero is String && numero.isNotEmpty ? numero : null,
    );
  }

  @override
  Future<void> definir(String numero) => _client.rpc<void>(
    'definir_mon_whatsapp',
    params: <String, dynamic>{'p_numero': numero},
  );
}

/// La source, posee par `main.dart` ; `null` hors production.
final Provider<PortWhatsappFamille?> portWhatsappFamilleProvider =
    Provider<PortWhatsappFamille?>((Ref _) => null);

/// L'etat du numero de la famille. Sans source ou en echec, la ligne de
/// l'accueil ne s'affiche pas : un accueil ne tombe jamais pour un numero.
final FutureProvider<EtatWhatsapp> monWhatsappProvider =
    FutureProvider<EtatWhatsapp>((Ref ref) async {
      final PortWhatsappFamille? port = ref.watch(portWhatsappFamilleProvider);
      if (port == null) {
        return (possible: false, numero: null);
      }
      try {
        return await port.lire();
      } on Object {
        return (possible: false, numero: null);
      }
    });
