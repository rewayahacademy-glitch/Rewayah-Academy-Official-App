// ESPACE-APPRENDRE (lot 5) : outils partages par les tests de l'espace et par
// le script de capture. L'espace est monte par le VRAI routeur de
// l'application (jamais une page seule), pour l'eleve adulte (compte tuteur
// servi « eleve autonome ») et pour l'eleve mineur (Interface guidee).
// Donnees de test seulement : rien ne vient de la production.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/apprendre/affichage_planche.dart';
import 'package:rewayah_academy/core/apprendre/dates_ecole.dart';
import 'package:rewayah_academy/core/apprendre/document_planche.dart';
import 'package:rewayah_academy/core/apprendre/documents_apprendre.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';
import 'package:rewayah_academy/core/suivi/ma_progression.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/couverture_ressource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

/// Les deux profils de l'espace.
enum ProfilApprendre {
  /// L'eleve adulte : un compte tuteur servi « eleve autonome ».
  adulte,

  /// L'eleve mineur, en Interface guidee.
  mineurGuide,
}

/// Une etape du cycle, telle que `ma_progression` la rend.
Map<String, Object?> etapeLue(
  int ordre,
  String nom,
  String statut, {
  required List<String> objectifs,
  required bool dates,
  int prevue = 3,
  int limite = 4,
}) => <String, Object?>{
  'ordre': ordre,
  'nom': nom,
  'statut': statut,
  'objectifs': objectifs,
  'duree_prevue_semaines': dates ? prevue : null,
  'date_limite_semaines': dates ? limite : null,
  if (dates && statut == 'franchie') 'atteinte_le': '2026-10-01T10:00:00Z',
};

/// La lecture `ma_progression` (hub de l'ecran « Ma progression », qui lit
/// `etape_eleve_lecture` : lot 1) : l'eleve est a l'etape 2, la 1 est
/// franchie (« Etape precedente »). [dates] : `eleve_voit_dates` (faux de 6 a
/// 9 ans : le serveur retient alors la date limite, l'horizon, le rythme et
/// les durees).
Map<String, Object?> lectureDemo({required bool dates}) => <String, Object?>{
  'eleve_voit_dates': dates,
  'etape': <String, Object?>{
    'code': 'BASES-2',
    'ordre': 2,
    'nom': 'Lire avec les voyelles',
    'objectifs': <Object?>[
      'Lit une lettre avec chacune des trois voyelles',
      'Lit un mot de trois lettres sans aide',
    ],
    'matiere_principale': 'Le livre de lecture de Rewayah : les voyelles',
    'matiere_secondaire': 'Al-Fatiha, puis les paroles de la prière',
    'duree_prevue_semaines': dates ? 6 : null,
    'date_limite_semaines': dates ? 8 : null,
    'entree_le': dates ? '2026-10-22' : null,
    'date_limite': dates ? '2026-12-17' : null,
    'semaines_ecoulees': dates ? 3 : null,
    'rythme': dates ? 'dans_les_temps' : null,
  },
  'niveau': <String, Object?>{
    'nom': 'Les bases',
    'horizon': dates ? '2027-03-11' : null,
  },
  'etapes_du_cycle': <Object?>[
    etapeLue(
      1,
      'Les lettres',
      'franchie',
      objectifs: <String>['Reconnaît chaque lettre dans le désordre'],
      dates: dates,
    ),
    etapeLue(
      2,
      'Lire avec les voyelles',
      'en_cours',
      objectifs: <String>[
        'Lit une lettre avec chacune des trois voyelles',
        'Lit un mot de trois lettres sans aide',
      ],
      dates: dates,
      prevue: 6,
      limite: 8,
    ),
    etapeLue(
      3,
      'Lire dans le Coran',
      'a_venir',
      objectifs: <String>['Lit un verset court avec le tajwid des bases'],
      dates: dates,
    ),
    etapeLue(
      4,
      "Les sourates courtes, d'Al-Masad à Az-Zalzalah",
      'a_venir',
      objectifs: <String>['Récite les sourates courtes sans aide'],
      dates: dates,
    ),
  ],
  'sourates': <String, Object?>{'sourates_validees': 3, 'sourates_total': 17},
};

/// Ce que lit le port de la progression.
sealed class LectureSuivi {
  const LectureSuivi();
}

/// La reponse du serveur.
class SuiviLu extends LectureSuivi {
  /// Cree la lecture.
  const SuiviLu(this.brut);

  /// La reponse brute (jsonb), lue par `SuiviPedagogique.depuisLecture`.
  final Object? brut;
}

/// Un echec de lecture.
class SuiviEnEchec extends LectureSuivi {
  /// Cree la lecture.
  const SuiviEnEchec();
}

/// Une lecture qui ne repond jamais (chargement).
class SuiviEnAttente extends LectureSuivi {
  /// Cree la lecture.
  const SuiviEnAttente();
}

class _PortSuivi implements PortMaProgression {
  const _PortSuivi(this.lecture);

  final LectureSuivi lecture;

  @override
  Future<MaProgression?> pourEleve(String eleveId) => switch (lecture) {
    SuiviLu(:final Object? brut) => Future<MaProgression?>.value(
      MaProgression.depuisJson(brut),
    ),
    SuiviEnEchec() => Future<MaProgression?>.error(StateError('lecture')),
    SuiviEnAttente() => Completer<MaProgression?>().future,
  };
}

/// Un port des dates de l'academie fixe.
class DatesEcoleFixes implements PortDatesEcole {
  /// Cree le port.
  const DatesEcoleFixes(this.dates);

  /// Les dates rendues.
  final List<DateEcole> dates;

  @override
  Future<List<DateEcole>> pourEleve(String eleveId) async => dates;
}

/// La couverture d'un document de test.
CouvertureRessource couvertureDe(String titre) => CouvertureRessource(
  indexTeinte: 1 + titre.length % 10,
  motif: MotifCouverture.lignes,
  monogramme: titre.substring(0, 1),
  type: TypeRessource.lecon,
);

/// Un document de test.
DocumentPlanche documentDe(
  String id,
  String titre, {
  TypeDocumentPlanche type = TypeDocumentPlanche.document,
  RayonPlanche rayon = RayonPlanche.documentsDesCours,
  String? description,
  OuvertureDocument? ouverture,
}) => DocumentPlanche(
  id: id,
  titre: titre,
  description: description,
  type: type,
  rayon: rayon,
  ouverture: ouverture ?? OuvrirDansLApplication(cheminFicheDocument(id)),
  couverture: type == TypeDocumentPlanche.document
      ? (id == idDocumentCoran
            ? CouvertureRessource.coran(titre)
            : couvertureDe(titre))
      : null,
);

/// Le Coran, premier document de l'academie.
DocumentPlanche coranDemo() => DocumentPlanche(
  id: idDocumentCoran,
  titre: 'Le Coran',
  description: 'Édition de Médine',
  type: TypeDocumentPlanche.document,
  rayon: RayonPlanche.documentsDesCours,
  ouverture: const OuvrirDansLApplication(Routes.eleveCoran),
  couverture: CouvertureRessource.coran('Le Coran'),
);

/// Un lien externe publie par l'academie.
DocumentPlanche lienDemo() => documentDe(
  'lien-lettres',
  'Les lettres arabes, en images',
  type: TypeDocumentPlanche.lienExterne,
  description: 'Une présentation courte des lettres, publiée par Rewayah.',
  ouverture: OuvrirHorsApplication(Uri.parse('https://exemple.org/lettres')),
);

/// Une bibliotheque complete : le Coran, un document, un audio, une video, un
/// lien externe.
List<DocumentPlanche> documentsComplets() => <DocumentPlanche>[
  coranDemo(),
  documentDe(
    'livre-lecture',
    'Le livre de lecture Rewayah',
    description: 'Les lettres, les voyelles, les premiers mots.',
  ),
  documentDe(
    'audio-lettres',
    'Les lettres, à écouter',
    type: TypeDocumentPlanche.audio,
    description: 'La voix du directeur, lettre par lettre.',
  ),
  documentDe(
    'video-priere',
    'La prière, pas à pas',
    type: TypeDocumentPlanche.video,
  ),
  lienDemo(),
];

/// Monte l'espace sur le vrai routeur et ouvre [depart].
///
/// [documents] : la bibliotheque ; nul, le vrai adaptateur du catalogue
/// existant (vide). [suivi] : la lecture du programme ; nul, aucun port (comme
/// avant le branchement). [horsLigne] : l'appareil est hors ligne.
Future<GoRouter> monterApprendre(
  WidgetTester tester, {
  ProfilApprendre profil = ProfilApprendre.adulte,
  String depart = Routes.eleveApprendre,
  Size taille = const Size(390, 844),
  double echelle = 1,
  TextDirection? direction,
  ThemeMode theme = ThemeMode.light,
  Object? documents = _vraiAdaptateur,
  LectureSuivi? suivi,
  PortDatesEcole? dates,
  bool horsLigne = false,
  List<Override> autres = const <Override>[],
}) {
  final bool adulte = profil == ProfilApprendre.adulte;
  final AppRole role = adulte ? AppRole.guardian : AppRole.student;
  final InterfaceMode mode = adulte
      ? InterfaceMode.standard
      : InterfaceMode.enfant;
  return monterRouteur(
    tester,
    depart,
    source: FausseSourceSession(sessionActive(role, mode: mode)),
    taille: taille,
    themeMode: theme,
    interface: mode,
    direction: direction,
    echelle: echelle,
    surcharges: <Override>[
      if (adulte)
        portCapaciteEleveProvider.overrideWithValue(
          PortCapaciteEleveFactice(autonomes: <String>{'p-${role.valeurSql}'}),
        ),
      if (documents is Future<List<DocumentPlanche>> Function())
        documentsApprendreProvider.overrideWith((Ref _) => documents())
      else if (documents is List<DocumentPlanche>)
        documentsApprendreProvider.overrideWith((Ref _) async => documents),
      if (suivi != null)
        portMaProgressionProvider.overrideWithValue(_PortSuivi(suivi)),
      if (dates != null) portDatesEcoleProvider.overrideWithValue(dates),
      serviceCoranProvider.overrideWithValue(_CoranVide()),
      horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
      ...autres,
    ],
  );
}

/// Le marqueur « le vrai adaptateur » : aucun `documentsApprendreProvider`
/// remplace.
const Object _vraiAdaptateur = Object();

/// Un corpus vide : le Coran s'ouvre sans Supabase.
class _CoranVide implements ServiceCoran {
  @override
  Future<String?> editionCourante() async => 'edition-test';
  @override
  Future<List<Sourate>?> sourates() async => const <Sourate>[];
  @override
  Future<PageCoran?> page(int numero) async =>
      PageCoran(numero: numero, versets: const <VersetCoran>[]);
  @override
  Future<int?> pageDe(int sourate, int verset) async => null;
  @override
  Future<PositionLecture?> position(String profilId) async => null;
  @override
  Future<bool> enregistrerPosition(
    String profilId,
    PositionLecture position,
  ) async => true;
  @override
  Future<({int sourate, int verset})?> debutDeJuz(int juz) async => null;
  @override
  Future<List<VersetCoran>?> rechercher(
    String requete, {
    int limite = 50,
  }) async => const <VersetCoran>[];
}

/// Le stockage de l'appareil de l'application montee (un stockage en
/// memoire, pose par le harnais du routeur).
StockagePreferencesMemoire stockageDeLAppareil(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
            .read(stockagePreferencesProvider)
        as StockagePreferencesMemoire;

/// Pose le choix grille ou liste sur l'appareil **comme s'il avait ete fait
/// au lancement d'avant** : ecrit dans le stockage, puis relit.
Future<void> preferer(WidgetTester tester, AffichagePlanche affichage) async {
  final ProviderContainer c = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
  await c
      .read(stockagePreferencesProvider)
      .ecrire(clefAffichagePlanche, affichage.name);
  c.invalidate(affichagePlancheProvider);
  c.read(affichagePlancheProvider);
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
