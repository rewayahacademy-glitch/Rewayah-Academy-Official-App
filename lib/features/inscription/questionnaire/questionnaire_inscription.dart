import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/foyer/profil_eleve_brouillon.dart';
import '../../../core/observabilite/journal_dev.dart';
import '../../../core/offres/offre_horaire.dart';
import '../brouillon_inscription.dart' show UsageInscription;
import 'memoire_appareil.dart';
import 'onboarding_donnees.dart';

/// ONBOARDING-PRAXIS (directeur, 22/11/2026 ; maquette validee
/// `docs/current/maquettes/onboarding-praxis/prototype.html`, decisions
/// datees dans `docs/current/ONBOARDING-PRAXIS-2026-11-22.md`) : le
/// questionnaire pose **avant** le compte, une question par ecran, guide par
/// Praxis, en quatre chapitres (Qui apprend, Ou en est le niveau, Vos cours,
/// Votre demande) et quatre interludes.
///
/// Les reponses attendent la connexion sur l'appareil ([memoire_appareil.dart]),
/// partent avec la demande (`inscrire_titulaire`, `p_apprenants` et
/// `p_source`), puis s'effacent. Aucune donnee d'enfant n'entre dans un compte
/// avant la decision de la direction.

/// « Pour qui » : les trois cartes de la maquette.
enum PourQui {
  /// « Pour moi » : un adulte, son propre tuteur.
  moi,

  /// « Pour mon enfant ».
  unEnfant,

  /// « Pour plusieurs enfants » : apres le premier, « Ajouter l'enfant
  /// suivant ».
  plusieurs,
}

/// Ce qu'une personne dit d'un apprenant : un enfant, ou le titulaire
/// lui-meme (« Pour moi », ou le parent qui suivra aussi des cours).
class ApprenantQuestionnaire {
  /// Cree un apprenant, sans reponse ; la lecture de Hafs est preselectionnee
  /// (directeur, 22/11/2026).
  const ApprenantQuestionnaire({
    this.prenom = '',
    this.age,
    this.genre,
    this.niveau,
    this.lecture = LectureCoran.hafs,
    this.lectureAutre = '',
    this.quantite,
    this.juz = const <int>[],
    this.sourates = const <String>[],
    this.objectif,
    this.titulaire = false,
  });

  /// Le prenom, deja valide ([prenomValide]) ; vide tant qu'il ne l'est pas.
  final String prenom;

  /// L'age d'un enfant, de [ageMinimum] a [ageMaximum] ; nul pour le
  /// titulaire.
  final int? age;

  /// Le genre (les classes ne sont pas mixtes par defaut).
  final Genre? genre;

  /// Le niveau declare (ce n'est pas le niveau officiel).
  final NiveauDeclare? niveau;

  /// La lecture du Coran (posee seulement s'il lit deja ou a memorise).
  final LectureCoran lecture;

  /// La lecture precisee quand [lecture] vaut [LectureCoran.autre].
  final String lectureAutre;

  /// Combien est deja memorise (seulement « a deja memorise une partie »).
  final QuantiteMemorisee? quantite;

  /// Les juz deja memorises, facultatif (1 a 30).
  final List<int> juz;

  /// Les sourates des bases deja memorisees, facultatif (codes de
  /// [souratesDesBases]).
  final List<String> sourates;

  /// L'objectif choisi.
  final ObjectifOnboarding? objectif;

  /// Vrai pour le titulaire du compte : ni age, ni prenom redemande apres la
  /// connexion.
  final bool titulaire;

  /// Vrai quand la lecture est demandee pour ce niveau.
  bool get lectureDemandee =>
      niveau == NiveauDeclare.lectureCourante ||
      niveau == NiveauDeclare.memorisationPartielle;

  /// Vrai quand la quantite memorisee est demandee.
  bool get memorisationDemandee =>
      niveau == NiveauDeclare.memorisationPartielle;

  /// Vrai quand le detail (juz ou sourates) est demande.
  bool get detailDemande =>
      memorisationDemandee &&
      quantite != null &&
      quantite != QuantiteMemorisee.coranEntier;

  /// Vrai quand le detail se dit en juz (sinon en sourates).
  bool get detailEnJuz => quantite != QuantiteMemorisee.quelquesSourates;

  /// Vrai pour un debutant complet : seule la courbe du « chemin » a des
  /// durees du programme.
  bool get debutant => niveau == NiveauDeclare.debutLettres;

  /// La tranche d'age du programme (6-9, 10-13, 14-17, 18+).
  TrancheAge get tranche => titulaire || (age ?? 18) >= 18
      ? TrancheAge.adulte
      : age! <= 9
      ? TrancheAge.de6a9
      : age! <= 13
      ? TrancheAge.de10a13
      : TrancheAge.de14a17;

  /// L'objectif tel que la base l'attend.
  String? get objectifSql => switch (objectif) {
    null => null,
    ObjectifOnboarding.lire =>
      niveau == NiveauDeclare.debutLettres ||
              niveau == NiveauDeclare.lettresAvecAide
          ? ObjectifApprentissage.apprendreALire.valeurSql
          : ObjectifApprentissage.devenirFluide.valeurSql,
    ObjectifOnboarding.memoriser => ObjectifApprentissage.memoriser.valeurSql,
    ObjectifOnboarding.priere => 'priere_invocations',
    ObjectifOnboarding.indecis => ObjectifApprentissage.indecis.valeurSql,
  };

  /// Une copie modifiee. [effacerQuantite] remet la quantite a nul.
  ApprenantQuestionnaire copier({
    String? prenom,
    int? age,
    Genre? genre,
    NiveauDeclare? niveau,
    LectureCoran? lecture,
    String? lectureAutre,
    QuantiteMemorisee? quantite,
    List<int>? juz,
    List<String>? sourates,
    ObjectifOnboarding? objectif,
    bool? titulaire,
  }) => ApprenantQuestionnaire(
    prenom: prenom ?? this.prenom,
    age: age ?? this.age,
    genre: genre ?? this.genre,
    niveau: niveau ?? this.niveau,
    lecture: lecture ?? this.lecture,
    lectureAutre: lectureAutre ?? this.lectureAutre,
    quantite: quantite ?? this.quantite,
    juz: juz ?? this.juz,
    sourates: sourates ?? this.sourates,
    objectif: objectif ?? this.objectif,
    titulaire: titulaire ?? this.titulaire,
  );

  /// L'apprenant tel que `inscrire_titulaire` l'attend.
  Map<String, Object?> versServeur({
    required String? langue,
    required String? langueSecours,
    required String langueAutre,
  }) => <String, Object?>{
    if (titulaire) 'est_titulaire': true else 'prenom': prenom.trim(),
    if (!titulaire) 'age': age,
    if (!titulaire) 'genre': genre?.valeurSql,
    'niveau': niveau?.valeurSql,
    'objectif': objectifSql,
    'moments': const <String>[],
    'langue': langue,
    'langue_secours': ?langueSecours,
    if (langueAutre.trim().isNotEmpty) 'langue_autre': langueAutre.trim(),
    if (lectureDemandee) 'riwaya': lecture.name,
    if (lectureDemandee &&
        lecture == LectureCoran.autre &&
        lectureAutre.trim().isNotEmpty)
      'riwaya_autre': lectureAutre.trim(),
    if (memorisationDemandee && quantite != null)
      'memorise': quantite!.valeurSql,
    if (detailDemande && detailEnJuz) 'juz': (<int>[...juz]..sort()),
    if (detailDemande && !detailEnJuz) 'sourates': sourates,
  };

  Map<String, Object?> _versJson() => <String, Object?>{
    'prenom': prenom,
    'age': age,
    'genre': genre?.valeurSql,
    'niveau': niveau?.valeurSql,
    'lecture': lecture.name,
    'lectureAutre': lectureAutre,
    'quantite': quantite?.valeurSql,
    'juz': juz,
    'sourates': sourates,
    'objectif': objectif?.name,
    'titulaire': titulaire,
  };

  static ApprenantQuestionnaire _depuisJson(Map<String, Object?> json) {
    final Object? juz = json['juz'];
    final Object? sourates = json['sourates'];
    return ApprenantQuestionnaire(
      prenom: json['prenom'] is String ? json['prenom']! as String : '',
      age: json['age'] is int ? json['age']! as int : null,
      genre: Genre.depuisSql(json['genre'] as String?),
      niveau: NiveauDeclare.depuisSql(json['niveau'] as String?),
      lecture:
          LectureCoran.values
              .where((LectureCoran l) => l.name == json['lecture'])
              .firstOrNull ??
          LectureCoran.hafs,
      lectureAutre: json['lectureAutre'] is String
          ? json['lectureAutre']! as String
          : '',
      quantite: QuantiteMemorisee.depuisSql(json['quantite'] as String?),
      juz: <int>[
        if (juz is List<Object?>)
          for (final Object? j in juz)
            if (j is int && j >= 1 && j <= 30) j,
      ],
      sourates: <String>[
        if (sourates is List<Object?>)
          for (final Object? s in sourates)
            if (s is String && souratesDesBases.contains(s)) s,
      ],
      objectif: ObjectifOnboarding.values
          .where((ObjectifOnboarding o) => o.name == json['objectif'])
          .firstOrNull,
      titulaire: json['titulaire'] == true,
    );
  }
}

/// L'age le plus jeune propose : 6 ans (decision du 13/10/2026). Lu dans la
/// seule source partagee avec l'ajout d'un profil eleve.
final int ageMinimum = BornesAge.clientActuelle.min;

/// L'age le plus grand d'un enfant ; a 18 ans, on s'inscrit soi-meme.
const int ageMaximum = 17;

/// Le nombre d'apprenants qu'une demande porte au plus (borne du serveur).
const int apprenantsMaximum = 6;

/// Un prenom accepte (directeur, 22/11/2026) : des lettres seulement, de
/// toute ecriture (arabe comprise), de 2 a 30 signes ; espace, apostrophe et
/// trait d'union entre les lettres ; ni chiffre ni emoji.
bool prenomValide(String saisie) {
  final String v = saisie.trim();
  if (v.length < 2 || v.length > 30) return false;
  return RegExp(r"^\p{L}[\p{L}\p{M}' \-]*$", unicode: true).hasMatch(v) &&
      RegExp(r'\p{L}', unicode: true).allMatches(v).length >= 2;
}

/// La sorte d'un ecran du questionnaire.
enum SorteEtape {
  /// « Bienvenue chez Rewayah Academy ».
  accueil,

  /// « Vous venez pour apprendre, ou pour enseigner ? »
  garde,

  /// La branche « Enseigner » : la candidature commence ici.
  enseigner,

  /// « Qui va suivre les cours ? »
  pourQui,

  /// Le prenom d'un apprenant.
  prenom,

  /// L'age d'un enfant.
  age,

  /// Le genre d'un apprenant.
  genre,

  /// Interlude « Voici votre famille ».
  famille,

  /// Le niveau d'un apprenant.
  niveau,

  /// La lecture du Coran.
  lecture,

  /// Combien est memorise.
  memorise,

  /// Quels juz ou quelles sourates.
  detail,

  /// L'objectif.
  objectif,

  /// Interlude « Votre point de depart ».
  depart,

  /// La langue des explications.
  langue,

  /// La langue de secours.
  langueSecours,

  /// Interlude « Votre chemin ».
  chemin,

  /// Interlude « Voici ce que nous avons compris ».
  recap,
}

/// Les quatre chapitres de la barre de progression.
enum Chapitre {
  /// Qui apprend.
  quiApprend,

  /// Ou en est le niveau.
  niveau,

  /// Vos cours.
  cours,

  /// Votre demande.
  demande,
}

/// Un ecran du questionnaire : sa sorte et, pour un apprenant, son rang.
class EtapeQuestionnaire {
  /// Cree un ecran.
  const EtapeQuestionnaire(this.sorte, [this.rang = 0]);

  /// Lit un ecran depuis l'adresse (`prenom-1`, `objectif-0`), ou `null`.
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

  /// Le rang de l'apprenant (0 pour les ecrans communs).
  final int rang;

  /// Vrai quand l'ecran porte sur un apprenant.
  bool get parApprenant => switch (sorte) {
    SorteEtape.prenom ||
    SorteEtape.age ||
    SorteEtape.genre ||
    SorteEtape.niveau ||
    SorteEtape.lecture ||
    SorteEtape.memorise ||
    SorteEtape.detail ||
    SorteEtape.objectif => true,
    _ => false,
  };

  /// Vrai pour un interlude (un toucher, pas une question).
  bool get interlude => switch (sorte) {
    SorteEtape.famille ||
    SorteEtape.depart ||
    SorteEtape.chemin ||
    SorteEtape.recap => true,
    _ => false,
  };

  /// Le chapitre de l'ecran ; `null` pour l'accueil et la branche
  /// « Enseigner ».
  Chapitre? get chapitre => switch (sorte) {
    SorteEtape.accueil || SorteEtape.enseigner => null,
    SorteEtape.garde ||
    SorteEtape.pourQui ||
    SorteEtape.prenom ||
    SorteEtape.age ||
    SorteEtape.genre ||
    SorteEtape.famille => Chapitre.quiApprend,
    SorteEtape.niveau ||
    SorteEtape.lecture ||
    SorteEtape.memorise ||
    SorteEtape.detail ||
    SorteEtape.objectif ||
    SorteEtape.depart => Chapitre.niveau,
    SorteEtape.langue ||
    SorteEtape.langueSecours ||
    SorteEtape.chemin => Chapitre.cours,
    SorteEtape.recap => Chapitre.demande,
  };

  /// Le code de l'adresse.
  String get code => parApprenant ? '${sorte.name}-$rang' : sorte.name;

  @override
  bool operator ==(Object other) =>
      other is EtapeQuestionnaire && other.sorte == sorte && other.rang == rang;

  @override
  int get hashCode => Object.hash(sorte, rang);

  @override
  String toString() => code;
}

/// Les reponses du questionnaire.
class QuestionnaireInscription {
  /// Cree un questionnaire.
  const QuestionnaireInscription({
    this.commence = false,
    this.apprendre = false,
    this.pourQui,
    this.apprenants = const <ApprenantQuestionnaire>[],
    this.langue,
    this.langueSecours,
    this.langueAutre = '',
    this.source,
  });

  /// « Commencer » a ete touche sur l'accueil.
  final bool commence;

  /// « Apprendre » a ete choisi (jamais « Enseigner » : ce chemin ne cree
  /// aucune demande d'eleve).
  final bool apprendre;

  /// La reponse a « Qui va suivre les cours ? ».
  final PourQui? pourQui;

  /// Les apprenants, dans l'ordre de saisie.
  final List<ApprenantQuestionnaire> apprenants;

  /// La langue des explications (code de [languesDesExplications]).
  final String? langue;

  /// La langue de secours, facultative ; `null` : aucune.
  final String? langueSecours;

  /// Une langue absente de la liste, facultative (pour mesurer la demande).
  final String langueAutre;

  /// « Comment avez-vous connu Rewayah ? », facultatif.
  final SourceConnaissance? source;

  /// L'usage, tel que l'inscription le connait.
  UsageInscription? get usage => switch (pourQui) {
    null => null,
    PourQui.moi => UsageInscription.moi,
    PourQui.unEnfant || PourQui.plusieurs => UsageInscription.famille,
  };

  /// L'apprenant titulaire, s'il y en a un.
  ApprenantQuestionnaire? get titulaire =>
      apprenants.where((ApprenantQuestionnaire a) => a.titulaire).firstOrNull;

  /// Vrai quand le titulaire suit des cours.
  bool get titulaireApprend => titulaire != null;

  /// Les enfants, dans l'ordre de saisie.
  List<ApprenantQuestionnaire> get enfants => <ApprenantQuestionnaire>[
    for (final ApprenantQuestionnaire a in apprenants)
      if (!a.titulaire) a,
  ];

  /// Vrai sur l'interlude « famille » de « Pour plusieurs enfants » tant
  /// qu'un seul apprenant est inscrit : le bouton dit « Ajouter l'enfant
  /// suivant ».
  bool get encoreUnEnfant =>
      pourQui == PourQui.plusieurs && apprenants.length < 2;

  /// Vrai quand un apprenant de plus est encore permis.
  bool get peutAjouter => apprenants.length < apprenantsMaximum;

  /// Les ecrans, dans l'ordre, pour les reponses deja donnees (la maquette :
  /// les branches changent la liste).
  List<EtapeQuestionnaire> get etapes {
    final List<EtapeQuestionnaire> liste = <EtapeQuestionnaire>[
      const EtapeQuestionnaire(SorteEtape.accueil),
      const EtapeQuestionnaire(SorteEtape.garde),
      const EtapeQuestionnaire(SorteEtape.pourQui),
    ];
    for (final (int i, ApprenantQuestionnaire a) in apprenants.indexed) {
      liste.add(EtapeQuestionnaire(SorteEtape.prenom, i));
      if (!a.titulaire) liste.add(EtapeQuestionnaire(SorteEtape.age, i));
      liste.add(EtapeQuestionnaire(SorteEtape.genre, i));
    }
    if (apprenants.isNotEmpty) {
      liste.add(const EtapeQuestionnaire(SorteEtape.famille));
    }
    for (final (int i, ApprenantQuestionnaire a) in apprenants.indexed) {
      liste.add(EtapeQuestionnaire(SorteEtape.niveau, i));
      if (a.lectureDemandee) {
        liste.add(EtapeQuestionnaire(SorteEtape.lecture, i));
      }
      if (a.memorisationDemandee) {
        liste.add(EtapeQuestionnaire(SorteEtape.memorise, i));
        if (a.detailDemande) {
          liste.add(EtapeQuestionnaire(SorteEtape.detail, i));
        }
      }
      liste.add(EtapeQuestionnaire(SorteEtape.objectif, i));
    }
    liste.addAll(const <EtapeQuestionnaire>[
      EtapeQuestionnaire(SorteEtape.depart),
      EtapeQuestionnaire(SorteEtape.langue),
      EtapeQuestionnaire(SorteEtape.langueSecours),
      EtapeQuestionnaire(SorteEtape.chemin),
      EtapeQuestionnaire(SorteEtape.recap),
    ]);
    return liste;
  }

  ApprenantQuestionnaire? _apprenant(int rang) =>
      rang < apprenants.length ? apprenants[rang] : null;

  /// Vrai quand [etape] a sa reponse (un interlude, un ecran facultatif : des
  /// qu'il est atteignable).
  bool repondue(EtapeQuestionnaire etape) => switch (etape.sorte) {
    SorteEtape.accueil => commence,
    SorteEtape.garde => apprendre,
    SorteEtape.enseigner => false,
    SorteEtape.pourQui => pourQui != null && apprenants.isNotEmpty,
    SorteEtape.prenom => prenomValide(_apprenant(etape.rang)?.prenom ?? ''),
    SorteEtape.age => _apprenant(etape.rang)?.age != null,
    SorteEtape.genre => _apprenant(etape.rang)?.genre != null,
    SorteEtape.famille => !encoreUnEnfant,
    SorteEtape.niveau => _apprenant(etape.rang)?.niveau != null,
    SorteEtape.lecture || SorteEtape.detail => true,
    SorteEtape.memorise => _apprenant(etape.rang)?.quantite != null,
    SorteEtape.objectif => _apprenant(etape.rang)?.objectif != null,
    SorteEtape.langue => langue != null,
    SorteEtape.depart ||
    SorteEtape.langueSecours ||
    SorteEtape.chemin ||
    SorteEtape.recap => true,
  };

  /// Le premier ecran sans reponse, ou `null` quand tout est repondu.
  EtapeQuestionnaire? get premiereManquante =>
      etapes.where((EtapeQuestionnaire e) => !repondue(e)).firstOrNull;

  /// Vrai quand tout est repondu : l'acces (adresse e-mail) s'ouvre.
  bool get complet => premiereManquante == null;

  /// Les apprenants, tels que `inscrire_titulaire` les attend
  /// (`p_apprenants`) : dans l'ordre de saisie, le titulaire compris.
  List<Map<String, Object?>> apprenantsPourServeur() => <Map<String, Object?>>[
    for (final ApprenantQuestionnaire a in apprenants)
      a.versServeur(
        langue: langue,
        langueSecours: langueSecours,
        langueAutre: langueAutre,
      ),
  ];

  /// La source declaree, telle que `inscrire_titulaire` l'attend
  /// (`p_source`).
  String? get sourcePourServeur => source?.name;

  /// Une copie modifiee ; [sansSecours] et [sansSource] remettent ces
  /// reponses a nul.
  QuestionnaireInscription copier({
    bool? commence,
    bool? apprendre,
    PourQui? pourQui,
    List<ApprenantQuestionnaire>? apprenants,
    String? langue,
    String? langueSecours,
    bool sansSecours = false,
    String? langueAutre,
    SourceConnaissance? source,
    bool sansSource = false,
  }) => QuestionnaireInscription(
    commence: commence ?? this.commence,
    apprendre: apprendre ?? this.apprendre,
    pourQui: pourQui ?? this.pourQui,
    apprenants: apprenants ?? this.apprenants,
    langue: langue ?? this.langue,
    langueSecours: sansSecours ? null : langueSecours ?? this.langueSecours,
    langueAutre: langueAutre ?? this.langueAutre,
    source: sansSource ? null : source ?? this.source,
  );

  /// Le texte garde sur l'appareil.
  String versTexte() => jsonEncode(<String, Object?>{
    'version': 2,
    'commence': commence,
    'apprendre': apprendre,
    'pourQui': pourQui?.name,
    'apprenants': <Object?>[
      for (final ApprenantQuestionnaire a in apprenants) a._versJson(),
    ],
    'langue': langue,
    'langueSecours': langueSecours,
    'langueAutre': langueAutre,
    'source': source?.name,
  });

  /// Relit le texte garde ; un texte illisible, ou d'avant ce questionnaire,
  /// rend un questionnaire vide.
  static QuestionnaireInscription depuisTexte(String? texte) {
    if (texte == null || texte.isEmpty) {
      return const QuestionnaireInscription();
    }
    try {
      final Object? json = jsonDecode(texte);
      if (json is! Map<String, Object?> || json['version'] != 2) {
        return const QuestionnaireInscription();
      }
      final Object? apprenants = json['apprenants'];
      return QuestionnaireInscription(
        commence: json['commence'] == true,
        apprendre: json['apprendre'] == true,
        pourQui: PourQui.values
            .where((PourQui p) => p.name == json['pourQui'])
            .firstOrNull,
        apprenants: <ApprenantQuestionnaire>[
          if (apprenants is List<Object?>)
            for (final Object? a in apprenants.take(apprenantsMaximum))
              if (a is Map<String, Object?>)
                ApprenantQuestionnaire._depuisJson(a),
        ],
        langue: _codeLangue(json['langue']),
        langueSecours: _codeLangue(json['langueSecours']),
        langueAutre: json['langueAutre'] is String
            ? json['langueAutre']! as String
            : '',
        source: SourceConnaissance.values
            .where((SourceConnaissance s) => s.name == json['source'])
            .firstOrNull,
      );
    } on Object catch (erreur) {
      journalDev('Questionnaire d inscription illisible : $erreur');
      return const QuestionnaireInscription();
    }
  }

  static String? _codeLangue(Object? brut) =>
      brut is String && codesDesExplications.contains(brut) ? brut : null;
}

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

  /// « Commencer ».
  void commencer() => _poser(state.copier(commence: true));

  /// « Apprendre » (la garde).
  void apprendre() => _poser(state.copier(apprendre: true));

  /// Un compte deja ouvert, sans questionnaire (l'etape d'usage de
  /// l'inscription) : l'accueil et la garde sont passes, « Pour qui » est
  /// propose avec cette reponse. Changer d'usage repart d'un questionnaire
  /// vide.
  void reprendreDepuisCompte(UsageInscription usage) {
    final PourQui p = usage == UsageInscription.moi
        ? PourQui.moi
        : PourQui.unEnfant;
    if (state.usage == usage) return;
    _poser(
      QuestionnaireInscription(commence: true, apprendre: true, pourQui: p),
    );
  }

  /// Retient « Pour qui » (sans encore creer d'apprenant).
  void choisirPourQui(PourQui pourQui) =>
      _poser(state.copier(pourQui: pourQui));

  /// « Continuer » sur « Pour qui » : le premier apprenant existe, titulaire
  /// pour « Pour moi » (et seul).
  void validerPourQui() {
    final PourQui? p = state.pourQui;
    if (p == null) return;
    final bool moi = p == PourQui.moi;
    final List<ApprenantQuestionnaire> liste = state.apprenants.isEmpty
        ? <ApprenantQuestionnaire>[ApprenantQuestionnaire(titulaire: moi)]
        : <ApprenantQuestionnaire>[
            state.apprenants.first.copier(titulaire: moi),
            if (!moi) ...state.apprenants.skip(1),
          ];
    _poser(state.copier(apprenants: liste));
  }

  /// Modifie l'apprenant de [rang].
  void modifier(
    int rang,
    ApprenantQuestionnaire Function(ApprenantQuestionnaire a) modifier,
  ) {
    if (rang >= state.apprenants.length) return;
    final List<ApprenantQuestionnaire> liste = <ApprenantQuestionnaire>[
      ...state.apprenants,
    ];
    liste[rang] = modifier(liste[rang]);
    _poser(state.copier(apprenants: liste));
  }

  /// Retient le niveau ; « a deja memorise » preselectionne « Memoriser ».
  void choisirNiveau(int rang, NiveauDeclare niveau) => modifier(
    rang,
    (ApprenantQuestionnaire a) => ApprenantQuestionnaire(
      prenom: a.prenom,
      age: a.age,
      genre: a.genre,
      niveau: niveau,
      lecture: a.lecture,
      lectureAutre: a.lectureAutre,
      quantite: niveau == NiveauDeclare.memorisationPartielle
          ? a.quantite
          : null,
      juz: niveau == NiveauDeclare.memorisationPartielle
          ? a.juz
          : const <int>[],
      sourates: niveau == NiveauDeclare.memorisationPartielle
          ? a.sourates
          : const <String>[],
      objectif:
          a.objectif ??
          (niveau == NiveauDeclare.memorisationPartielle
              ? ObjectifOnboarding.memoriser
              : null),
      titulaire: a.titulaire,
    ),
  );

  /// Ajoute ou retire un juz, ou une sourate, du detail.
  void basculerDetail(int rang, {int? juz, String? sourate}) =>
      modifier(rang, (ApprenantQuestionnaire a) {
        final List<int> j = <int>[...a.juz];
        final List<String> s = <String>[...a.sourates];
        if (juz != null && !j.remove(juz)) j.add(juz);
        if (sourate != null && !s.remove(sourate)) s.add(sourate);
        return a.copier(juz: j, sourates: s);
      });

  /// Ajoute un apprenant ; rend son rang, ou `null` a la borne.
  int? ajouter({bool titulaire = false}) {
    if (!state.peutAjouter || (titulaire && state.titulaireApprend)) {
      return null;
    }
    final List<ApprenantQuestionnaire> liste = <ApprenantQuestionnaire>[
      ...state.apprenants,
      ApprenantQuestionnaire(titulaire: titulaire),
    ];
    _poser(state.copier(apprenants: liste));
    return liste.length - 1;
  }

  /// Retire l'apprenant de [rang] (ajoute puis abandonne avant son prenom).
  /// Le premier reste.
  void retirer(int rang) {
    if (rang == 0 || rang >= state.apprenants.length) return;
    _poser(
      state.copier(
        apprenants: <ApprenantQuestionnaire>[...state.apprenants]
          ..removeAt(rang),
      ),
    );
  }

  /// Retient la langue des explications ; la langue de secours ne peut pas
  /// etre la meme.
  void choisirLangue(String code) => _poser(
    state.copier(langue: code, sansSecours: state.langueSecours == code),
  );

  /// Retient la langue de secours ; `null` : « Aucune autre ».
  void choisirLangueSecours(String? code) => _poser(
    code == null
        ? state.copier(sansSecours: true)
        : state.copier(langueSecours: code),
  );

  /// Retient la langue absente de la liste.
  void saisirLangueAutre(String texte) =>
      _poser(state.copier(langueAutre: texte.trim()));

  /// Retient la source ; la meme source touchee deux fois se retire
  /// (facultatif).
  void basculerSource(SourceConnaissance source) => _poser(
    state.source == source
        ? state.copier(sansSource: true)
        : state.copier(source: source),
  );

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

/// INSCRIPTION-3 (constat du directeur, 01/11/2026) : vrai entre la demande
/// envoyee (profil cree) et l'arrivee sur `/attente`.
class DepartDemande extends Notifier<bool> {
  @override
  bool build() => false;

  /// La demande est partie : l'ecran ne propose plus rien jusqu'au depart.
  void commencer() => state = true;

  /// Arrivee sur `/attente`, ou actualisation en echec.
  void finir() => state = false;
}

/// Le depart en cours de la demande ([DepartDemande]).
final NotifierProvider<DepartDemande, bool> departDemandeProvider =
    NotifierProvider<DepartDemande, bool>(DepartDemande.new);

/// ONBOARDING-BOUCLE (directeur, 14/11/2026) : vrai quand une session vient de
/// s'ouvrir ici (lien de connexion ouvert dans un autre navigateur que celui
/// du questionnaire) alors que le questionnaire de cet appareil est vide.
class ReponsesResteesAilleurs extends Notifier<bool> {
  @override
  bool build() => false;

  /// Pose la marque : la prochaine ouverture du questionnaire le dit.
  void signaler() => state = true;
}

/// Le repere de [ReponsesResteesAilleurs].
final NotifierProvider<ReponsesResteesAilleurs, bool>
reponsesResteesAilleursProvider =
    NotifierProvider<ReponsesResteesAilleurs, bool>(
      ReponsesResteesAilleurs.new,
    );
