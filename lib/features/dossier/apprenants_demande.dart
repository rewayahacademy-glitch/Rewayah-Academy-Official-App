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

/// La demande de la personne : son issue, la precision demandee, et, apres un
/// refus, le modele du refus (`refus_general`, `refus_niveau`, `refus_besoins`,
/// `refus_sans_reponse`) : la raison se lit dans l'application, pas seulement
/// dans un courriel qui peut se perdre (audit famille, 22/11/2026).
typedef DemandeFamille = ({
  IssueDemandeFamille issue,
  String? precisions,
  String? motif,
});

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
    motif: r['issue'] == 'refusee' && r['motif'] is String
        ? (r['motif'] as String).trim()
        : null,
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

/// Quand la demande a ete envoyee et quand la direction a decide (precisions
/// demandees ou acceptation), tels que le serveur les rend
/// (`ma_demande_admission`, PARCOURS-BOUT-EN-BOUT). Instants UTC : l'ecran les
/// lit a l'heure de la personne. Aucune date inventee : `null` quand le
/// serveur n'en donne pas.
typedef DatesAdmission = ({DateTime? recueLe, DateTime? decisionLe});

/// Lit les dates de `ma_demande_admission` ; `null` sans demande.
typedef LectureDatesAdmission = Future<DatesAdmission?> Function();

DateTime? _instant(Object? brut) =>
    brut is String ? DateTime.tryParse(brut)?.toUtc() : null;

Future<DatesAdmission?> _lireDates() async {
  final Object? r = await Supabase.instance.client.rpc<Object?>(
    'ma_demande_admission',
  );
  if (r is! Map<String, dynamic>) {
    return null;
  }
  return (
    recueLe: _instant(r['recue_le']),
    decisionLe: _instant(r['decision_le']),
  );
}

/// La lecture des dates ; surchargee par les tests.
final Provider<LectureDatesAdmission> lectureDatesAdmissionProvider =
    Provider<LectureDatesAdmission>((Ref _) => _lireDates);

/// Les dates de la demande du compte connecte. Une lecture en echec ne se
/// relance pas : la frise se lit alors sans dates.
final FutureProvider<DatesAdmission?> datesAdmissionProvider =
    FutureProvider<DatesAdmission?>(
      (Ref ref) => ref.watch(lectureDatesAdmissionProvider)(),
      retry: (int _, Object _) => null,
    );
