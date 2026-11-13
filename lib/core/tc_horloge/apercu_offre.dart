// HORLOGE-ET-LIEU, partie B (13/11/2026, consigne de l'architecte) : a
// l'inscription dans une classe, la famille lit ce que devient l'heure du
// cours chez elle au prochain changement d'heure (« Chez vous : 19:00, puis
// 20:00 a partir du dimanche 28 mars 2027 »).
//
// Le calcul est fait par la base (`public.apercu_offre_horaire`) : le client
// n'a aucune regle IANA et ne connait ni le jour ni le fuseau d'origine de
// l'offre. Quand l'heure ne change jamais dans l'annee, ou quand le serveur
// ne repond pas (fonction pas encore installee, test sans Supabase), aucune
// phrase : jamais une heure fabriquee.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/suivi_foyer/filtres_historique.dart'
    show dateLongueHistorique;
import '../accessibilite/texte_sans_coupure.dart';
import '../config/env.dart';
import '../i18n/strings.g.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'apercu_creneau.dart';

/// L'acces au calcul de la base pour une offre.
abstract interface class PortApercuOffre {
  /// L'apercu de l'offre [offreId] lue chez [fuseau], ou `null` quand le
  /// serveur ne sait pas repondre.
  Future<ApercuCreneau?> lire({
    required String offreId,
    required String fuseau,
  });
}

/// Sans serveur (PLAYGROUND, test) : aucune reponse.
class ApercuOffreAbsent implements PortApercuOffre {
  /// Cree le port vide.
  const ApercuOffreAbsent();

  @override
  Future<ApercuCreneau?> lire({
    required String offreId,
    required String fuseau,
  }) async => null;
}

/// L'adaptateur de `public.apercu_offre_horaire`.
class ApercuOffreSupabase implements PortApercuOffre {
  /// Cree l'adaptateur.
  const ApercuOffreSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ApercuCreneau?> lire({
    required String offreId,
    required String fuseau,
  }) async {
    try {
      final Object? brut = await _client.rpc<Object?>(
        'apercu_offre_horaire',
        params: <String, dynamic>{'p_offre_id': offreId, 'p_fuseau': fuseau},
      );
      return ApercuCreneau.lire(brut);
    } on PostgrestException catch (e) {
      // 42501 : compte non valide ; 22023 : fuseau inconnu ; PGRST202 et
      // 42883 : la fonction n'est pas encore installee. Pas d'apercu.
      if (e.code == '42501' ||
          e.code == '22023' ||
          e.code == 'PGRST202' ||
          e.code == '42883') {
        return null;
      }
      rethrow;
    }
  }
}

/// Le port employe par l'application.
final Provider<PortApercuOffre> portApercuOffreProvider =
    Provider<PortApercuOffre>((Ref ref) {
      if (Env.playgroundActif) return const ApercuOffreAbsent();
      try {
        return ApercuOffreSupabase(Supabase.instance.client);
      } on Object {
        return const ApercuOffreAbsent();
      }
    });

/// La demande d'un apercu : l'offre et le fuseau chez qui on la lit.
typedef DemandeApercuOffre = ({String offreId, String fuseau});

/// L'apercu d'une offre, lu une fois par offre et par fuseau.
final FutureProviderFamily<ApercuCreneau?, DemandeApercuOffre>
apercuOffreProvider = FutureProvider.family<ApercuCreneau?, DemandeApercuOffre>(
  (Ref ref, DemandeApercuOffre d) => ref
      .watch(portApercuOffreProvider)
      .lire(offreId: d.offreId, fuseau: d.fuseau),
  retry: (int _, Object _) => null,
);

/// « Chez vous : 19:00, puis 20:00 a partir du dimanche 28 mars 2027. »
/// `null` quand l'heure ne change jamais dans l'annee.
String? phraseApercuOffre(ApercuCreneau c) {
  final DateTime? date = c.dateChangement;
  final String? apres = c.heureApres;
  if (c.meme || date == null || apres == null) return null;
  final h = t.tc.groupe.horloges;
  return h.apercuChezPuis(
    ou: h.chezVous,
    heure: c.heureMaintenant,
    apres: apres,
    date: dateLongueHistorique(date),
  );
}

/// La phrase d'apercu sous une offre. Rien tant que le serveur ne repond pas,
/// et rien quand l'heure ne change jamais.
class LigneApercuOffre extends ConsumerWidget {
  /// Cree la ligne.
  const LigneApercuOffre({
    required this.offreId,
    required this.fuseau,
    super.key,
  });

  /// L'offre lue.
  final String offreId;

  /// Le fuseau chez qui elle est lue.
  final String fuseau;

  /// Cle de la ligne.
  static const Key cle = ValueKey<String>('apercu-offre');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ApercuCreneau? apercu = ref
        .watch(apercuOffreProvider((offreId: offreId, fuseau: fuseau)))
        .value;
    final String? phrase = apercu == null ? null : phraseApercuOffre(apercu);
    if (phrase == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
      child: TexteSansCoupure(
        key: cle,
        phrase,
        style: AppTypography.tabulaire(
          Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
        ),
      ),
    );
  }
}
