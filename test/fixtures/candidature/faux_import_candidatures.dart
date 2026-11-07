// Le double du port de l'import des formulaires, oracle des tests de widget
// d'`ADM-23` et de ses captures. Importe par aucune ligne de production
// (`CONTRAT_PORTS_CANDIDATURES.md`, section 2).
//
// Il ne lit pas le fichier : il rend l'apercu et le rapport qu'on lui donne, et
// note chaque appel (le texte envoye, le mappage, le jeton, les choix, la cle
// d'idempotence) pour qu'un test prouve ce qui part au serveur. Un test qui veut
// un refus le programme. **Aucune personne reelle** : les noms sont fictifs, les
// adresses en `@test.invalid`, les numeros hors plan de numerotation.

import 'dart:async';

import 'package:rewayah_academy/core/candidature/modeles_import_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_import_candidatures.dart';

/// Les 14 titres du questionnaire arabe (`MAPPAGE_IMPORT_FORMULAIRES.md`,
/// section 2), tels qu'un export Google Sheets les donne.
const List<String> titresFormulaire = <String>[
  'Horodateur',
  'هل أنت',
  'الاسم الكامل',
  'رقم الواتساب مع رمز الدولة',
  'ما هي لغتك الأم',
  'بأي لغات تستطيع أن تشرح للطالب وتصحح له أخطاءه',
  'ما مستواك في حفظ القرآن',
  'هل تستطيع تقديم شهادة أو إجازة تثبت مستواك عند المقابلة',
  'هل لديك خبرة في تعليم المبتدئين القراءة',
  'هل تستطيع التدريس في ساعات متأخرة من الليل بتوقيت مكة المكرمة',
  'كم ساعة في الأسبوع تستطيع التدريس بانتظام',
  'متى تستطيع أن تبدأ',
  'أوافق على أن يتصل بي فريق المشروع عبر واتساب',
  'البريد الألكتروني',
];

String _ligneCsv(List<String> cellules) => cellules
    .map((String c) => c.contains(',') ? '"$c"' : c)
    .join(',');

/// Un export fictif : l'en-tete, puis sept lignes (2 a 8) :
/// 2 normale, 3 et 6 au meme courriel, 4 sans courriel et au telephone
/// national, 5 vide, 7 au genre illisible, 8 deja connue.
final String csvFormulaires = <String>[
  _ligneCsv(titresFormulaire),
  _ligneCsv(<String>[
    '21/10/2026 09:15:00', 'ذكر', 'Personne Test 01', '+0000000001',
    'الفرنسية', 'الفرنسية', 'حفظت القرآن كله', 'نعم', 'نعم',
    'جاهز في أي وقت من اليوم', 'من 6 إلى 10', 'يمكن لي البدء فورا', 'أوافق',
    'personne01@test.invalid',
  ]),
  _ligneCsv(<String>[
    '21/10/2026 09:40:00', 'أنثى', 'Personne Test 02', '+0000000002',
    'العربية', 'الإنجليزية', 'حفظت أقل من 10 أجزاء', 'لا', 'نعم',
    'من 8 مساءً إلى 10 مساءً', 'من 3 إلى 5 ساعات في الأسبوع', 'في الشهر القادم', 'أوافق',
    'partage@test.invalid',
  ]),
  _ligneCsv(<String>[
    '21/10/2026 10:05:00', 'ذكر', 'Personne Test 03', '0600000003',
    'الفرنسية', 'الفرنسية', 'حفظت أكثر من 10 أجزاء', 'نعم', 'لا',
    'جاهز في أي وقت من اليوم', 'أكثر من 10', 'يمكن لي البدء فورا', '', '',
  ]),
  ',,,,,,,,,,,,,',
  _ligneCsv(<String>[
    '22/10/2026 08:00:00', 'أنثى', 'Personne Test 02 bis', '+0000000012',
    'العربية', 'الإنجليزية', 'حفظت أقل من 10 أجزاء', 'لا', 'نعم',
    'من 8 مساءً إلى 10 مساءً', 'من 3 إلى 5 ساعات في الأسبوع', 'في الشهر القادم', 'أوافق',
    'partage@test.invalid',
  ]),
  _ligneCsv(<String>[
    '22/10/2026 08:30:00', 'غير مفهوم', 'Personne Test 05', '+0000000005',
    'الفرنسية', 'الفرنسية', 'حفظت القرآن كله', 'نعم', 'نعم',
    'جاهز في أي وقت من اليوم', 'من 6 إلى 10', 'يمكن لي البدء فورا', 'أوافق',
    'personne05@test.invalid',
  ]),
  _ligneCsv(<String>[
    '22/10/2026 09:00:00', 'ذكر', 'Personne Test 06', '+0000000006',
    'الفرنسية', 'الفرنسية', 'حفظت القرآن كله', 'نعم', 'نعم',
    'جاهز في أي وقت من اليوم', 'من 6 إلى 10', 'يمكن لي البدء فورا', 'أوافق',
    'personne06@test.invalid',
  ]),
].join('\r\n');

/// Les colonnes d'un export normal : les 14 champs, dans l'ordre du formulaire.
const List<ChampFormulaire> champsDuFormulaire = <ChampFormulaire>[
  ChampFormulaire.horodatage,
  ChampFormulaire.genre,
  ChampFormulaire.nom,
  ChampFormulaire.telephone,
  ChampFormulaire.langueMaternelle,
  ChampFormulaire.languesExplication,
  ChampFormulaire.memorisation,
  ChampFormulaire.ijaza,
  ChampFormulaire.experience,
  ChampFormulaire.creneaux,
  ChampFormulaire.heures,
  ChampFormulaire.debut,
  ChampFormulaire.whatsapp,
  ChampFormulaire.courriel,
];

/// Les colonnes du formulaire reconnues, sauf celles de [sauf].
List<ColonneLue> colonnesTest({Set<ChampFormulaire> sauf = const {}}) =>
    <ColonneLue>[
      for (int i = 0; i < champsDuFormulaire.length; i++)
        ColonneLue(
          position: i + 1,
          champ: sauf.contains(champsDuFormulaire[i])
              ? null
              : champsDuFormulaire[i],
        ),
    ];

/// L'apercu de [csvFormulaires] : trois nouvelles, une deja connue, une
/// ignoree, une a corriger, et un groupe de deux lignes au meme courriel.
ApercuImport apercuTest({
  String jeton = 'jeton-a',
  List<ColonneLue>? colonnes,
  CompteursImport? compteurs,
  List<GroupeDoublons>? groupes,
  List<LigneApercu>? lignes,
}) => ApercuImport(
  jeton: jeton,
  colonnes: colonnes ?? colonnesTest(),
  compteurs:
      compteurs ??
      const CompteursImport(
        lignesLues: 7,
        nouvelles: 4,
        corrigees: 0,
        dejaConnues: 1,
        ignorees: 1,
        aCorriger: 1,
        historique: 1,
        personnes: 5,
      ),
  groupes:
      groupes ??
      const <GroupeDoublons>[
        GroupeDoublons(
          id: 'g1a2b3c4d5e6',
          nature: NatureCle.courriel,
          taille: 2,
          lignes: <int>[3, 6],
          retenueProposee: 6,
        ),
      ],
  lignes:
      lignes ??
      const <LigneApercu>[
        LigneApercu(
          ligne: 2,
          issue: IssueLigne.nouvelle,
          etatFinal: EtatFinalLigne.active,
        ),
        LigneApercu(
          ligne: 3,
          issue: IssueLigne.nouvelle,
          groupe: 'g1a2b3c4d5e6',
          etatFinal: EtatFinalLigne.historique,
        ),
        LigneApercu(
          ligne: 4,
          issue: IssueLigne.nouvelle,
          etatFinal: EtatFinalLigne.active,
          courrielAObtenir: true,
          indicatifAConfirmer: true,
          avertissements: <String>['format_national'],
        ),
        LigneApercu(
          ligne: 5,
          issue: IssueLigne.ignoree,
          motifs: <String>['ligne_vide'],
        ),
        LigneApercu(
          ligne: 6,
          issue: IssueLigne.nouvelle,
          groupe: 'g1a2b3c4d5e6',
          etatFinal: EtatFinalLigne.active,
        ),
        LigneApercu(
          ligne: 7,
          issue: IssueLigne.aCorriger,
          motifs: <String>['genre_illisible'],
        ),
        LigneApercu(
          ligne: 8,
          issue: IssueLigne.dejaConnue,
          etatFinal: EtatFinalLigne.active,
          avertissements: <String>['arabe_retire'],
        ),
      ],
);

/// Le rapport final correspondant a [apercuTest].
RapportImport rapportTest({
  bool rejoue = false,
  List<ChoixDoublon> choix = const <ChoixDoublon>[],
  CompteursImport? compteurs,
  List<LigneRapport>? lignes,
}) => RapportImport(
  lot: 'lot-1',
  rejoue: rejoue,
  choix: choix,
  compteurs:
      compteurs ??
      const CompteursImport(
        lignesLues: 7,
        nouvelles: 4,
        corrigees: 0,
        dejaConnues: 1,
        ignorees: 1,
        aCorriger: 1,
        historique: 1,
        personnes: 5,
      ),
  lignes:
      lignes ??
      const <LigneRapport>[
        LigneRapport(
          ligne: 2,
          issue: IssueLigne.nouvelle,
          reference: 'Formulaire enseignants|Reponses|21/10/2026 09:15:00',
          etatFinal: EtatFinalLigne.active,
        ),
        LigneRapport(
          ligne: 3,
          issue: IssueLigne.nouvelle,
          reference: 'Formulaire enseignants|Reponses|21/10/2026 09:40:00',
          etatFinal: EtatFinalLigne.historique,
        ),
        LigneRapport(
          ligne: 4,
          issue: IssueLigne.nouvelle,
          reference: 'Formulaire enseignants|Reponses|21/10/2026 10:05:00',
          etatFinal: EtatFinalLigne.active,
          avertissements: <String>['format_national'],
        ),
        LigneRapport(
          ligne: 5,
          issue: IssueLigne.ignoree,
          motifs: <String>['ligne_vide'],
        ),
        LigneRapport(
          ligne: 6,
          issue: IssueLigne.nouvelle,
          reference: 'Formulaire enseignants|Reponses|22/10/2026 08:00:00',
          etatFinal: EtatFinalLigne.active,
        ),
        LigneRapport(
          ligne: 7,
          issue: IssueLigne.aCorriger,
          reference: 'Formulaire enseignants|Reponses|22/10/2026 08:30:00',
          motifs: <String>['genre_illisible'],
        ),
        LigneRapport(
          ligne: 8,
          issue: IssueLigne.dejaConnue,
          reference: 'Formulaire enseignants|Reponses|22/10/2026 09:00:00',
          etatFinal: EtatFinalLigne.active,
        ),
      ],
);

/// Un appel a l'essai a blanc.
class AppelApercu {
  /// Cree la trace.
  const AppelApercu({
    required this.csv,
    required this.classeur,
    required this.onglet,
    required this.mappage,
    required this.fuseau,
  });

  /// Le CSV envoye.
  final String csv;

  /// Le classeur.
  final String classeur;

  /// L'onglet.
  final String onglet;

  /// Le mappage envoye.
  final MappageColonnes mappage;

  /// Le fuseau.
  final String fuseau;
}

/// Un appel a la confirmation.
class AppelConfirmation {
  /// Cree la trace.
  const AppelConfirmation({
    required this.csv,
    required this.classeur,
    required this.onglet,
    required this.jeton,
    required this.choix,
    required this.cleIdempotence,
    required this.mappage,
  });

  /// Le CSV envoye.
  final String csv;

  /// Le classeur.
  final String classeur;

  /// L'onglet.
  final String onglet;

  /// Le jeton de l'apercu.
  final String jeton;

  /// Les choix de doublons.
  final List<ChoixDoublon> choix;

  /// La cle d'idempotence.
  final String cleIdempotence;

  /// Le mappage envoye.
  final MappageColonnes mappage;
}

/// Le double du port.
class FauxImportCandidatures implements PortImportCandidatures {
  /// Cree le double.
  FauxImportCandidatures({
    this.capacitesRendues = const CapacitesImportCandidatures(
      peutImporter: true,
    ),
    ApercuImport? apercuRendu,
    RapportImport? rapportRendu,
    this.erreurApercu,
    this.erreurConfirmation,
  }) : apercuRendu = apercuRendu ?? apercuTest(),
       rapportRendu = rapportRendu ?? rapportTest();

  /// Les capacites rendues.
  CapacitesImportCandidatures capacitesRendues;

  /// Une erreur a lever a la lecture des capacites.
  Object? erreurCapacites;

  /// Retient les capacites jusqu'a la fin du completer.
  Completer<CapacitesImportCandidatures>? capacitesRetenues;

  /// L'apercu rendu (ou une fonction du numero d'appel, a partir de 1).
  ApercuImport apercuRendu;

  /// Le rapport rendu.
  RapportImport rapportRendu;

  /// L'erreur a lever a l'essai a blanc, selon le numero d'appel (a partir de
  /// 1) ; `null` : pas d'erreur.
  Object? Function(int appel)? erreurApercu;

  /// L'erreur a lever a la confirmation, selon le numero d'appel (a partir de
  /// 1).
  Object? Function(int appel)? erreurConfirmation;

  /// Retient l'essai a blanc jusqu'a la fin du completer.
  Completer<ApercuImport>? apercuRetenu;

  /// Retient la confirmation jusqu'a la fin du completer.
  Completer<RapportImport>? confirmationRetenue;

  /// Les essais a blanc recus.
  final List<AppelApercu> apercus = <AppelApercu>[];

  /// Les confirmations recues.
  final List<AppelConfirmation> confirmations = <AppelConfirmation>[];

  @override
  Future<CapacitesImportCandidatures> capacites() {
    if (capacitesRetenues != null) return capacitesRetenues!.future;
    if (erreurCapacites != null) {
      return Future<CapacitesImportCandidatures>.error(erreurCapacites!);
    }
    return Future<CapacitesImportCandidatures>.value(capacitesRendues);
  }

  @override
  Future<ApercuImport> apercu({
    required String csv,
    required String classeur,
    required String onglet,
    MappageColonnes mappage = MappageColonnes.aucun,
    String fuseau = 'UTC',
  }) {
    apercus.add(
      AppelApercu(
        csv: csv,
        classeur: classeur,
        onglet: onglet,
        mappage: mappage,
        fuseau: fuseau,
      ),
    );
    final Object? erreur = erreurApercu?.call(apercus.length);
    if (erreur != null) return Future<ApercuImport>.error(erreur);
    if (apercuRetenu != null) return apercuRetenu!.future;
    return Future<ApercuImport>.value(apercuRendu);
  }

  @override
  Future<RapportImport> confirmer({
    required String csv,
    required String classeur,
    required String onglet,
    required String jeton,
    required List<ChoixDoublon> choix,
    required String cleIdempotence,
    MappageColonnes mappage = MappageColonnes.aucun,
    String fuseau = 'UTC',
  }) {
    confirmations.add(
      AppelConfirmation(
        csv: csv,
        classeur: classeur,
        onglet: onglet,
        jeton: jeton,
        choix: List<ChoixDoublon>.of(choix),
        cleIdempotence: cleIdempotence,
        mappage: mappage,
      ),
    );
    final Object? erreur = erreurConfirmation?.call(confirmations.length);
    if (erreur != null) return Future<RapportImport>.error(erreur);
    if (confirmationRetenue != null) return confirmationRetenue!.future;
    return Future<RapportImport>.value(rapportRendu);
  }
}
