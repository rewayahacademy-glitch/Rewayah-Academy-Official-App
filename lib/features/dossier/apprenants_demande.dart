import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Un apprenant de la demande d'admission, tel que le titulaire le relit.
typedef ApprenantDemande = ({String prenom, int? age, bool titulaire});

/// Lit les apprenants de la demande (`mes_apprenants_demande`, admission,
/// lot B) ; rend une liste vide sans source.
typedef LectureApprenantsDemande = Future<List<ApprenantDemande>> Function();

Future<List<ApprenantDemande>> _lireSupabase() async {
  final Object? reponse = await Supabase.instance.client.rpc<Object?>(
    'mes_apprenants_demande',
  );
  return <ApprenantDemande>[
    if (reponse is List<Object?>)
      for (final Object? ligne in reponse)
        if (ligne is Map<String, dynamic> && ligne['prenom'] is String)
          (
            prenom: ligne['prenom'] as String,
            age: ligne['age'] is int ? ligne['age'] as int : null,
            titulaire: ligne['est_titulaire'] == true,
          ),
  ];
}

/// La lecture des apprenants ; surchargee par les tests.
final Provider<LectureApprenantsDemande> lectureApprenantsDemandeProvider =
    Provider<LectureApprenantsDemande>((Ref _) => _lireSupabase);

/// Les apprenants de la demande du compte connecte. Une lecture en echec ne
/// se relance pas : la page d'attente se lit sans cette ligne.
final FutureProvider<List<ApprenantDemande>> apprenantsDemandeProvider =
    FutureProvider<List<ApprenantDemande>>(
      (Ref ref) => ref.watch(lectureApprenantsDemandeProvider)(),
      retry: (int _, Object _) => null,
    );
