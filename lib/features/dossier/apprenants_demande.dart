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

/// Ou en est la demande d'admission, vue par la personne (admission, lot C).
enum IssueDemandeFamille {
  /// La direction ne l'a pas encore decidee.
  enCours,

  /// La direction demande une precision.
  aCompleter,

  /// La direction ne peut pas y donner suite.
  refusee,
}

/// La demande de la personne : son issue, et la precision demandee.
typedef DemandeFamille = ({IssueDemandeFamille issue, String? precisions});

/// Lit `ma_demande_admission` ; `null` sans demande.
typedef LectureDemandeFamille = Future<DemandeFamille?> Function();

Future<DemandeFamille?> _lireDemande() async {
  final Object? r = await Supabase.instance.client.rpc<Object?>(
    'ma_demande_admission',
  );
  if (r is! Map<String, dynamic>) {
    return null;
  }
  final String? precisions = r['precisions'] as String?;
  return (
    issue: r['issue'] == 'refusee'
        ? IssueDemandeFamille.refusee
        : r['etat'] == 'a_completer'
        ? IssueDemandeFamille.aCompleter
        : IssueDemandeFamille.enCours,
    precisions: precisions == null || precisions.trim().isEmpty
        ? null
        : precisions.trim(),
  );
}

/// La lecture de la demande ; surchargee par les tests.
final Provider<LectureDemandeFamille> lectureDemandeFamilleProvider =
    Provider<LectureDemandeFamille>((Ref _) => _lireDemande);

/// La demande du compte connecte. Une lecture en echec ne se relance pas : la
/// page d'attente dit alors « Votre demande est en cours », qui reste vrai
/// tant que rien d'autre n'est lu.
final FutureProvider<DemandeFamille?> demandeFamilleProvider =
    FutureProvider<DemandeFamille?>(
      (Ref ref) => ref.watch(lectureDemandeFamilleProvider)(),
      retry: (int _, Object _) => null,
    );
