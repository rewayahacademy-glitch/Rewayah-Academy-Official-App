// Le canal d'aide lu SANS compte (audit famille, 22/11/2026, correctif 1).
//
// `canal_support()` exige un compte valide : une personne qui n'arrive pas a
// entrer (lien perdu, adresse fausse, demande refusee, compte suspendu) n'avait
// aucune sortie. `canal_support_public()` rend le meme canal a tout le monde ;
// l'adresse est deja publiee sur le site public. Une lecture en echec ou sans
// canal ne montre rien : la page reste celle d'avant, jamais une adresse
// inventee.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_support.dart';

/// Lit le canal public ; `null` sans canal publie.
typedef LectureCanalSupportPublic = Future<CanalSupport?> Function();

Future<CanalSupport?> _lireCanalPublic() async {
  try {
    final List<dynamic> lignes = await Supabase.instance.client
        .rpc<List<dynamic>>('canal_support_public');
    if (lignes.length != 1 || lignes.single is! Map<String, dynamic>) {
      return null;
    }
    final Map<String, dynamic> ligne = lignes.single as Map<String, dynamic>;
    final String? adresse = (ligne['adresse'] as String?)?.trim();
    final NatureCanalSupport? nature = switch (ligne['nature']) {
      'courriel' => NatureCanalSupport.courriel,
      'lien' => NatureCanalSupport.lien,
      _ => null,
    };
    if (nature == null || adresse == null || adresse.isEmpty) {
      return null;
    }
    return CanalSupport(nature: nature, adresse: adresse);
  } on Object {
    return null;
  }
}

/// La lecture du canal public ; surchargee par les tests.
final Provider<LectureCanalSupportPublic> lectureCanalSupportPublicProvider =
    Provider<LectureCanalSupportPublic>((Ref _) => _lireCanalPublic);

/// Le canal d'aide public ; `null` quand il n'y en a pas (ou en cas d'echec).
final FutureProvider<CanalSupport?> canalSupportPublicProvider =
    FutureProvider<CanalSupport?>(
      (Ref ref) => ref.watch(lectureCanalSupportPublicProvider)(),
      retry: (int _, Object _) => null,
    );
