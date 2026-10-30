import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/observabilite/journal_dev.dart';
import '../../../core/offres/offre_horaire.dart';
import '../../parcours_offres/libelles_parcours.dart' show MomentJournee;
import '../brouillon_inscription.dart' show UsageInscription;
import 'memoire_appareil.dart';

/// Le questionnaire d'inscription, pose **avant** le compte (admission,
/// lot B ; fiche `docs/current/FICHE-ONBOARDING-2026-10-29.md`, validee le
/// 29/10/2026) : pour qui, chaque enfant (prenom, age, genre), le parent
/// aussi, le niveau de chaque apprenant, l'objectif, les moments. Les
/// reponses attendent la connexion sur l'appareil ([memoire_appareil.dart]),
/// partent avec la demande, puis s'effacent.
///
/// Aucune donnee d'enfant n'entre dans un compte avant la decision de la
/// direction : le serveur les range avec la demande
/// (`candidature_apprenants`), et les profils sont crees a l'acceptation.

/// Ce qu'une famille dit d'un enfant.
class EnfantQuestionnaire {
  /// Cree un enfant, sans reponse.
  const EnfantQuestionnaire({
    this.prenom = '',
    this.age,
    this.genre,
    this.niveau,
  });

  /// Le prenom saisi.
  final String prenom;

  /// L'age, de [ageMinimum] a [ageMaximum].
  final int? age;

  /// Le genre (les classes ne sont pas mixtes par defaut, decision du 10/10).
  final Genre? genre;

  /// Le niveau declare (ce n'est pas le niveau officiel).
  final NiveauDeclare? niveau;

  /// Une copie modifiee.
  EnfantQuestionnaire copier({
    String? prenom,
    int? age,
    Genre? genre,
    NiveauDeclare? niveau,
  }) => EnfantQuestionnaire(
    prenom: prenom ?? this.prenom,
    age: age ?? this.age,
    genre: genre ?? this.genre,
    niveau: niveau ?? this.niveau,
  );

  Map<String, Object?> _versJson() => <String, Object?>{
    'prenom': prenom,
    'age': age,
    'genre': genre?.valeurSql,
    'niveau': niveau?.valeurSql,
  };

  static EnfantQuestionnaire _depuisJson(Map<String, Object?> json) =>
      EnfantQuestionnaire(
        prenom: json['prenom'] is String ? json['prenom']! as String : '',
        age: json['age'] is int ? json['age']! as int : null,
        genre: Genre.depuisSql(json['genre'] as String?),
        niveau: NiveauDeclare.depuisSql(json['niveau'] as String?),
      );
}

/// L'age le plus jeune propose : celui de la premiere cohorte
/// (`cohortes_age`, `enfant_5_7`).
const int ageMinimum = 5;

/// L'age le plus grand d'un enfant ; a 18 ans, on s'inscrit soi-meme.
const int ageMaximum = 17;

/// Le nombre d'apprenants qu'une demande porte au plus (borne du serveur).
const int apprenantsMaximum = 6;

/// La sorte d'un ecran du questionnaire.
enum SorteEtape {
  /// « Pour qui creez-vous ce compte ? »
  pourQui,

  /// Le prenom d'un enfant.
  prenom,

  /// L'age d'un enfant.
  age,

  /// Le genre d'un enfant.
  genre,

  /// « Suivez-vous aussi des cours ? »
  parent,

  /// La langue du cours, une pour toute la demande.
  langue,

  /// Le niveau d'un enfant.
  niveau,

  /// Le niveau du titulaire.
  niveauTitulaire,

  /// L'objectif.
  objectif,

  /// Les moments de la journee.
  moments,
}

/// Un ecran du questionnaire : sa sorte et, pour un enfant, son rang.
class EtapeQuestionnaire {
  /// Cree un ecran.
  const EtapeQuestionnaire(this.sorte, [this.rang = 0]);

  /// Lit un ecran depuis l'adresse (`prenom-1`, `objectif`), ou `null`.
  static EtapeQuestionnaire? depuisCode(String? code) {
    if (code == null) {
      return null;
    }
    final List<String> morceaux = code.split('-');
    final SorteEtape? sorte = SorteEtape.values
        .where((SorteEtape s) => s.name == morceaux.first)
        .firstOrNull;
    if (sorte == null) {
      return null;
    }
    final int rang = morceaux.length > 1 ? int.tryParse(morceaux[1]) ?? -1 : 0;
    return rang < 0 ? null : EtapeQuestionnaire(sorte, rang);
  }

  /// La sorte.
  final SorteEtape sorte;

  /// Le rang de l'enfant (0 pour les ecrans communs).
  final int rang;

  /// Vrai quand l'ecran porte sur un enfant.
  bool get parEnfant => switch (sorte) {
    SorteEtape.prenom ||
    SorteEtape.age ||
    SorteEtape.genre ||
    SorteEtape.niveau => true,
    _ => false,
  };

  /// Le code de l'adresse.
  String get code => parEnfant ? '${sorte.name}-$rang' : sorte.name;

  @override
  bool operator ==(Object other) =>
      other is EtapeQuestionnaire && other.sorte == sorte && other.rang == rang;

  @override
  int get hashCode => Object.hash(sorte, rang);
}

/// Les reponses du questionnaire.
class QuestionnaireInscription {
  /// Cree un questionnaire.
  const QuestionnaireInscription({
    this.usage,
    this.enfants = const <EnfantQuestionnaire>[],
    this.parentSuitDesCours,
    this.niveauTitulaire,
    this.objectif,
    this.moments = const <MomentJournee>{},
    this.langue,
  });

  /// « Pour moi » ou « mon enfant » ; jamais enseignant ni comptable.
  final UsageInscription? usage;

  /// Les enfants, dans l'ordre de saisie.
  final List<EnfantQuestionnaire> enfants;

  /// La reponse a « Suivez-vous aussi des cours ? » (famille).
  final bool? parentSuitDesCours;

  /// Le niveau du titulaire, quand il apprend.
  final NiveauDeclare? niveauTitulaire;

  /// L'objectif.
  final ObjectifApprentissage? objectif;

  /// Les moments retenus.
  final Set<MomentJournee> moments;

  /// La langue du cours (code de `langues_cours`), lue sans compte
  /// (`langues_cours_publiques`).
  final String? langue;

  /// Vrai quand le titulaire suit des cours.
  bool get titulaireApprend =>
      usage == UsageInscription.moi || parentSuitDesCours == true;

  /// Les ecrans, dans l'ordre, pour les reponses deja donnees.
  List<EtapeQuestionnaire> get etapes {
    final List<EtapeQuestionnaire> liste = <EtapeQuestionnaire>[
      const EtapeQuestionnaire(SorteEtape.pourQui),
    ];
    if (usage == UsageInscription.famille) {
      // Les quatre ecrans d'un enfant se suivent : son niveau se dit juste
      // apres son prenom, son age et son genre.
      final int n = enfants.isEmpty ? 1 : enfants.length;
      for (int i = 0; i < n; i++) {
        liste.addAll(<EtapeQuestionnaire>[
          EtapeQuestionnaire(SorteEtape.prenom, i),
          EtapeQuestionnaire(SorteEtape.age, i),
          EtapeQuestionnaire(SorteEtape.genre, i),
          EtapeQuestionnaire(SorteEtape.niveau, i),
        ]);
      }
      liste.add(const EtapeQuestionnaire(SorteEtape.parent));
    }
    liste.add(const EtapeQuestionnaire(SorteEtape.langue));
    if (titulaireApprend) {
      liste.add(const EtapeQuestionnaire(SorteEtape.niveauTitulaire));
    }
    liste.addAll(const <EtapeQuestionnaire>[
      EtapeQuestionnaire(SorteEtape.objectif),
      EtapeQuestionnaire(SorteEtape.moments),
    ]);
    return liste;
  }

  EnfantQuestionnaire? _enfant(int rang) =>
      rang < enfants.length ? enfants[rang] : null;

  /// Vrai quand [etape] a sa reponse.
  bool repondue(EtapeQuestionnaire etape) => switch (etape.sorte) {
    SorteEtape.pourQui =>
      usage == UsageInscription.moi || usage == UsageInscription.famille,
    SorteEtape.prenom => _enfant(etape.rang)?.prenom.trim().isNotEmpty ?? false,
    SorteEtape.age => _enfant(etape.rang)?.age != null,
    SorteEtape.genre => _enfant(etape.rang)?.genre != null,
    SorteEtape.parent => parentSuitDesCours != null,
    SorteEtape.langue => langue != null,
    SorteEtape.niveau => _enfant(etape.rang)?.niveau != null,
    SorteEtape.niveauTitulaire => niveauTitulaire != null,
    SorteEtape.objectif => objectif != null,
    SorteEtape.moments => moments.isNotEmpty,
  };

  /// Le premier ecran sans reponse, ou `null` quand tout est repondu.
  EtapeQuestionnaire? get premiereManquante =>
      etapes.where((EtapeQuestionnaire e) => !repondue(e)).firstOrNull;

  /// Vrai quand tout est repondu.
  bool get complet => premiereManquante == null;

  /// Les apprenants, tels que `inscrire_titulaire` les attend
  /// (`p_apprenants`) : les enfants, puis le titulaire s'il apprend.
  List<Map<String, Object?>> apprenantsPourServeur() {
    final List<String> momentsSql = <String>[
      for (final MomentJournee m in MomentJournee.values)
        if (moments.contains(m)) momentSql(m),
    ];
    return <Map<String, Object?>>[
      if (usage == UsageInscription.famille)
        for (final EnfantQuestionnaire e in enfants)
          <String, Object?>{
            'prenom': e.prenom.trim(),
            'age': e.age,
            'genre': e.genre?.valeurSql,
            'niveau': e.niveau?.valeurSql,
            'objectif': objectif?.valeurSql,
            'moments': momentsSql,
            'langue': langue,
          },
      if (titulaireApprend)
        <String, Object?>{
          'est_titulaire': true,
          'niveau': niveauTitulaire?.valeurSql,
          'objectif': objectif?.valeurSql,
          'moments': momentsSql,
          'langue': langue,
        },
    ];
  }

  /// Une copie modifiee ; aucune reponse ne se remet a `null` par elle.
  QuestionnaireInscription copier({
    UsageInscription? usage,
    List<EnfantQuestionnaire>? enfants,
    bool? parentSuitDesCours,
    NiveauDeclare? niveauTitulaire,
    ObjectifApprentissage? objectif,
    Set<MomentJournee>? moments,
    String? langue,
  }) => QuestionnaireInscription(
    usage: usage ?? this.usage,
    enfants: enfants ?? this.enfants,
    parentSuitDesCours: parentSuitDesCours ?? this.parentSuitDesCours,
    niveauTitulaire: niveauTitulaire ?? this.niveauTitulaire,
    objectif: objectif ?? this.objectif,
    moments: moments ?? this.moments,
    langue: langue ?? this.langue,
  );

  /// Le texte garde sur l'appareil.
  String versTexte() => jsonEncode(<String, Object?>{
    'usage': usage?.name,
    'enfants': <Object?>[
      for (final EnfantQuestionnaire e in enfants) e._versJson(),
    ],
    'parent': parentSuitDesCours,
    'niveauTitulaire': niveauTitulaire?.valeurSql,
    'objectif': objectif?.valeurSql,
    'moments': <String>[for (final MomentJournee m in moments) m.name],
    'langue': langue,
  });

  /// Relit le texte garde ; un texte illisible rend un questionnaire vide.
  static QuestionnaireInscription depuisTexte(String? texte) {
    if (texte == null || texte.isEmpty) {
      return const QuestionnaireInscription();
    }
    try {
      final Object? json = jsonDecode(texte);
      if (json is! Map<String, Object?>) {
        return const QuestionnaireInscription();
      }
      final UsageInscription? usage = <UsageInscription>[
        UsageInscription.moi,
        UsageInscription.famille,
      ].where((UsageInscription u) => u.name == json['usage']).firstOrNull;
      final Object? enfants = json['enfants'];
      final Object? moments = json['moments'];
      return QuestionnaireInscription(
        usage: usage,
        enfants: <EnfantQuestionnaire>[
          if (enfants is List<Object?>)
            for (final Object? e in enfants.take(apprenantsMaximum))
              if (e is Map<String, Object?>) EnfantQuestionnaire._depuisJson(e),
        ],
        parentSuitDesCours: json['parent'] is bool
            ? json['parent']! as bool
            : null,
        niveauTitulaire: NiveauDeclare.depuisSql(
          json['niveauTitulaire'] as String?,
        ),
        objectif: ObjectifApprentissage.depuisSql(json['objectif'] as String?),
        moments: <MomentJournee>{
          if (moments is List<Object?>)
            for (final MomentJournee m in MomentJournee.values)
              if (moments.contains(m.name)) m,
        },
        langue: json['langue'] is String ? json['langue']! as String : null,
      );
    } on Object catch (erreur) {
      journalDev('Questionnaire d inscription illisible : $erreur');
      return const QuestionnaireInscription();
    }
  }
}

/// La valeur serveur d'un moment (`candidature_apprenants.moments`).
String momentSql(MomentJournee moment) => switch (moment) {
  MomentJournee.matin => 'matin',
  MomentJournee.apresMidi => 'apres_midi',
  MomentJournee.soir => 'soir',
};

/// La clef du questionnaire dans la memoire de l'appareil.
const String clefQuestionnaire = 'rewayah.inscription.questionnaire';

/// Tient le questionnaire, et le garde sur l'appareil a chaque reponse.
class QuestionnaireControleur extends Notifier<QuestionnaireInscription> {
  @override
  QuestionnaireInscription build() => QuestionnaireInscription.depuisTexte(
    lireMemoireAppareil(clefQuestionnaire),
  );

  void _poser(QuestionnaireInscription q) {
    state = q;
    ecrireMemoireAppareil(clefQuestionnaire, q.versTexte());
  }

  /// Retient l'usage. Changer d'usage repart d'un questionnaire vide.
  void choisirUsage(UsageInscription usage) {
    if (state.usage != usage) {
      _poser(QuestionnaireInscription(usage: usage));
    }
  }

  /// Modifie l'enfant de [rang] (cree au besoin).
  void modifierEnfant(
    int rang,
    EnfantQuestionnaire Function(EnfantQuestionnaire e) modifier,
  ) {
    final List<EnfantQuestionnaire> enfants = <EnfantQuestionnaire>[
      ...state.enfants,
    ];
    while (enfants.length <= rang) {
      enfants.add(const EnfantQuestionnaire());
    }
    enfants[rang] = modifier(enfants[rang]);
    _poser(state.copier(enfants: enfants));
  }

  /// Ajoute un enfant sans reponse ; rend son rang, ou `null` a la borne.
  int? ajouterEnfant() {
    if (state.enfants.length + (state.titulaireApprend ? 1 : 0) >=
        apprenantsMaximum) {
      return null;
    }
    final List<EnfantQuestionnaire> enfants = <EnfantQuestionnaire>[
      ...state.enfants,
      const EnfantQuestionnaire(),
    ];
    _poser(state.copier(enfants: enfants));
    return enfants.length - 1;
  }

  /// Retire l'enfant de [rang] (le dernier ajoute, quand on revient de son
  /// prenom sans l'avoir saisi). Le premier enfant d'une famille reste.
  void retirerEnfant(int rang) {
    if (rang == 0 || rang >= state.enfants.length) {
      return;
    }
    _poser(
      state.copier(
        enfants: <EnfantQuestionnaire>[...state.enfants]..removeAt(rang),
      ),
    );
  }

  /// Retient la reponse du parent.
  void choisirParent({required bool suit}) =>
      _poser(state.copier(parentSuitDesCours: suit));

  /// Retient le niveau du titulaire.
  void choisirNiveauTitulaire(NiveauDeclare niveau) =>
      _poser(state.copier(niveauTitulaire: niveau));

  /// Retient l'objectif.
  void choisirObjectif(ObjectifApprentissage objectif) =>
      _poser(state.copier(objectif: objectif));

  /// Retient la langue du cours.
  void choisirLangue(String langue) => _poser(state.copier(langue: langue));

  /// Ajoute ou retire un moment.
  void basculerMoment(MomentJournee moment) {
    final Set<MomentJournee> moments = <MomentJournee>{...state.moments};
    if (!moments.remove(moment)) {
      moments.add(moment);
    }
    _poser(state.copier(moments: moments));
  }

  /// Efface le questionnaire, une fois la demande envoyee.
  void effacer() {
    state = const QuestionnaireInscription();
    effacerMemoireAppareil(clefQuestionnaire);
  }
}

/// Le questionnaire de cet appareil.
final NotifierProvider<QuestionnaireControleur, QuestionnaireInscription>
questionnaireInscriptionProvider =
    NotifierProvider<QuestionnaireControleur, QuestionnaireInscription>(
      QuestionnaireControleur.new,
    );
