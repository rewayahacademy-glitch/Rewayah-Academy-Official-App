// COM-CAPT : captures de recette des Communications V1 (spec section 27),
// chaque ecran COM-* sur le VRAI routeur, dans la VRAIE coquille du role
// (tuteur, enseignant, admin, Studio), remplie des donnees de la
// demonstration (`lib/features/demo/communications/`), posees a la racine
// du test seulement.
//
// Ecrans principaux : 320, 390, 768 et 1440, clair et sombre, plus le texte
// double a 320 (vrai `textScaler` 2, par la plateforme) et l'arabe (RTL) a
// 390. Etats cles (hors ligne, vide, vocal, garde anti-promotion,
// signalement, reponse retenue par la garde, Focus) : 390 et 1440, clair
// et sombre.
//
// Les debordements (`RenderFlex overflowed`) ne font pas echouer la
// capture : ils sont relevés dans `CAPTURE_DIR/com_debordements.txt`, pour
// la lecture de la recette (COM-CAPT.md).
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien. Mode
// d'emploi : `test/capture/LISEZ-MOI.md`.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/profils_locaux.dart';
import 'package:rewayah_academy/core/cache/db/app_database.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/communications/capacites_communication.dart';
import 'package:rewayah_academy/core/communications/moderation.dart';
import 'package:rewayah_academy/core/communications/port_brouillons.dart';
import 'package:rewayah_academy/core/communications/port_elements_enregistres.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/classe_tuteur/carte_seance_classe.dart';
import 'package:rewayah_academy/features/classe_tuteur/contexte_classe.dart'
    show cheminClasse;
import 'package:rewayah_academy/features/com_annonces/annonces_de_classe.dart';
import 'package:rewayah_academy/features/com_annonces/port_annonces.dart';
import 'package:rewayah_academy/features/com_communaute/composer_publication.dart';
import 'package:rewayah_academy/features/com_communaute/feuille_signalement_communaute.dart';
import 'package:rewayah_academy/features/com_communaute/flux_publications.dart';
import 'package:rewayah_academy/features/com_communaute/publication_detail.dart';
import 'package:rewayah_academy/features/com_communaute/reponses.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/com_studio/focus/bascule_focus.dart';
import 'package:rewayah_academy/features/com_studio/port_activite_studio.dart';
import 'package:rewayah_academy/features/com_studio/port_studio.dart';
import 'package:rewayah_academy/features/com_studio/studio_page.dart';
import 'package:rewayah_academy/features/com_vocal/composer_vocal.dart';
import 'package:rewayah_academy/features/com_vocal/envoi_vocal.dart';
import 'package:rewayah_academy/features/com_vocal/port_enregistreur_vocal.dart';
import 'package:rewayah_academy/features/demo/communications/com_annonces_demo.dart';
import 'package:rewayah_academy/features/demo/communications/com_communaute_demo.dart';
import 'package:rewayah_academy/features/demo/communications/com_messages_demo.dart';
import 'package:rewayah_academy/features/demo/communications/com_studio_demo.dart';
import 'package:rewayah_academy/features/demo/communications/com_vocal_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../features/classe_tuteur/demo_an_nour.dart';
import '../features/classe_tuteur/support_classe.dart';
import '../features/com_messages/support_messages.dart' show FauxMessagesMetier;
import '../features/com_vocal/support_vocal.dart';
import '../router/support_routeur.dart' hide stabiliser;
import '../support/harnais.dart';
import 'outil_capture.dart';

/// L'heure des fixtures : celle des tests des voies.
final DateTime _maintenant = DateTime.utc(2026, 10, 4, 12);

/// Une variante : nom, taille logique, densite, zone sure, echelle de
/// texte, theme, langue.
typedef _Variante = (
  String,
  Size,
  double,
  EdgeInsets,
  double,
  ThemeMode,
  AppLocale,
);

const EdgeInsets _zone390 = EdgeInsets.only(top: 47, bottom: 34);

const List<_Variante> _completes = <_Variante>[
  (
    '320_clair',
    Size(320, 640),
    2,
    EdgeInsets.zero,
    1,
    ThemeMode.light,
    AppLocale.fr,
  ),
  (
    '320_sombre',
    Size(320, 640),
    2,
    EdgeInsets.zero,
    1,
    ThemeMode.dark,
    AppLocale.fr,
  ),
  ('390_clair', Size(390, 844), 2, _zone390, 1, ThemeMode.light, AppLocale.fr),
  ('390_sombre', Size(390, 844), 2, _zone390, 1, ThemeMode.dark, AppLocale.fr),
  (
    '768_clair',
    Size(768, 1024),
    1,
    EdgeInsets.zero,
    1,
    ThemeMode.light,
    AppLocale.fr,
  ),
  (
    '768_sombre',
    Size(768, 1024),
    1,
    EdgeInsets.zero,
    1,
    ThemeMode.dark,
    AppLocale.fr,
  ),
  (
    '1440_clair',
    Size(1440, 900),
    1,
    EdgeInsets.zero,
    1,
    ThemeMode.light,
    AppLocale.fr,
  ),
  (
    '1440_sombre',
    Size(1440, 900),
    1,
    EdgeInsets.zero,
    1,
    ThemeMode.dark,
    AppLocale.fr,
  ),
];

const List<_Variante> _accessibilite = <_Variante>[
  (
    '320x2_clair',
    Size(320, 640),
    2,
    EdgeInsets.zero,
    2,
    ThemeMode.light,
    AppLocale.fr,
  ),
  (
    '390_rtl_clair',
    Size(390, 844),
    2,
    _zone390,
    1,
    ThemeMode.light,
    AppLocale.ar,
  ),
];

const List<_Variante> _etats = <_Variante>[
  ('390_clair', Size(390, 844), 2, _zone390, 1, ThemeMode.light, AppLocale.fr),
  ('390_sombre', Size(390, 844), 2, _zone390, 1, ThemeMode.dark, AppLocale.fr),
  (
    '1440_clair',
    Size(1440, 900),
    1,
    EdgeInsets.zero,
    1,
    ThemeMode.light,
    AppLocale.fr,
  ),
  (
    '1440_sombre',
    Size(1440, 900),
    1,
    EdgeInsets.zero,
    1,
    ThemeMode.dark,
    AppLocale.fr,
  ),
];

/// Un ecran capture : son nom, l'adresse ou le routeur va, les surcharges
/// (coquille du role comprise), et le geste qui l'amene a l'etat voulu.
class _Ecran {
  const _Ecran(
    this.nom,
    this.chemin,
    this.surcharges, {
    this.geste,
    this.principal = false,
    this.variantes,
  });

  final String nom;
  final String chemin;
  final List<Override> Function() surcharges;
  final Future<void> Function(WidgetTester tester)? geste;
  final bool principal;

  /// Variantes propres a cet ecran ; sinon celles de `principal`.
  final List<_Variante>? variantes;
}

// --- Coquilles des roles ----------------------------------------------------

/// Une base en memoire : l'ecriture du PNG laisse courir le vrai temps, et la
/// base de l'appareil chercherait un dossier que le test n'a pas.
Override _baseMemoire() => baseLocaleProvider.overrideWith((Ref ref) {
  final AppDatabase base = AppDatabase.surExecuteur(NativeDatabase.memory());
  ref.onDispose(base.close);
  return base;
});

/// La coquille d'un role de session (tuteur, enseignant) sur le vrai
/// routeur, sans serveur.
List<Override> _role(AppRole role) => <Override>[
  ...surchargesRouteur(FausseSourceSession(sessionActive(role))),
  _baseMemoire(),
];

/// La coquille admin reelle, en demonstration admin, sans serveur.
List<Override> _admin() => <Override>[
  ...surchargesDemoAdmin(environnement: 'staging'),
  _baseMemoire(),
];

Override _horsLigne() =>
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true));

// --- Donnees de demonstration par voie -------------------------------------

/// Les capacites ouvertes en demonstration pour les Messages (ecrire, vocal).
Override _capacitesMessages({
  Set<CapaciteCommunication> autres = const <CapaciteCommunication>{},
}) => portCapacitesCommunicationsProvider.overrideWithValue(
  CapacitesCommunicationsFixes(<CapaciteCommunication>{
    CapaciteCommunication.ecrireDansFil,
    CapaciteCommunication.envoyerVocal,
    ...autres,
  }),
);

List<Override> _messages(
  RoleDemoCommunications role, {
  SituationDemoMessages situation = SituationDemoMessages.normale,
  PortMessagesMetier? port,
  HorlogeManuelle? horloge,
  PermissionMicro permission = PermissionMicro.accordee,
}) {
  final HorlogeManuelle h = horloge ?? HorlogeManuelle();
  return <Override>[
    portMessagesMetierProvider.overrideWithValue(
      port ??
          MessagesMetierDemo(
            role: role,
            situation: situation,
            maintenant: _maintenant,
          ),
    ),
    _capacitesMessages(),
    portEnregistreurVocalProvider.overrideWithValue(
      EnregistreurVocalDemonstration(
        horloge: h.horloge,
        permissionInitiale: permission,
      ),
    ),
    portLectureVocaleProvider.overrideWithValue(
      LecturesVocalesDemonstration(horloge: h.horloge),
    ),
    portEnvoiVocalProvider.overrideWithValue(EnvoiVocalDemonstration()),
    horlogeVocaleProvider.overrideWithValue(h.horloge),
    if (situation == SituationDemoMessages.horsLigne) _horsLigne(),
  ];
}

List<Override> _studio({
  SituationDemoStudio situation = SituationDemoStudio.normale,
}) => <Override>[
  portStudioProvider.overrideWithValue(
    StudioDemo(situation: situation, maintenant: _maintenant),
  ),
  portActiviteStudioProvider.overrideWithValue(
    ActiviteStudioDemo(situation: situation, maintenant: _maintenant),
  ),
  portBrouillonsProvider.overrideWithValue(
    brouillonsStudioDemo(situation, maintenant: () => _maintenant),
  ),
  portElementsEnregistresProvider.overrideWithValue(
    ElementsEnregistresMemoire(),
  ),
  // Comme la demonstration du Studio : le composer vocal du canal.
  portCapacitesCommunicationsProvider.overrideWithValue(
    const CapacitesCommunicationsFixes(<CapaciteCommunication>{
      CapaciteCommunication.envoyerVocal,
    }),
  ),
  ...surchargesVocalDemo(),
  if (situation == SituationDemoStudio.horsLigne) _horsLigne(),
];

/// Les annonces et notifications de la demonstration pour [role], les
/// annonces de la Classe An-Nour rangees aussi sous [classeReelle].
List<Override> _annonces(
  RoleDemoCommunications role, {
  String? classeReelle,
  Set<CapaciteCommunication> capacites = const <CapaciteCommunication>{},
}) {
  final Map<String, List<AnnonceClasse>> parClasse = annoncesDemo(
    role,
    _maintenant,
  );
  final String? reelle = classeReelle;
  final AnnoncesDemonstration annonces = AnnoncesDemonstration(
    <String, List<AnnonceClasse>>{
      ...parClasse,
      ?reelle: parClasse[ClassesDemoAnnonces.nour] ?? <AnnonceClasse>[],
    },
    cibles: role == RoleDemoCommunications.admin
        ? ciblesDemo()
        : const <CibleAnnonce>[],
    publiees: role == RoleDemoCommunications.admin
        ? annoncesAdministrationDemo(_maintenant).publiees
        : const <AnnonceAdministration>[],
    planifiees: role == RoleDemoCommunications.admin
        ? annoncesAdministrationDemo(_maintenant).planifiees
        : const <AnnonceAdministration>[],
    maintenant: () => _maintenant,
  );
  return <Override>[
    portNotificationsProvider.overrideWithValue(
      NotificationsDemonstration(notificationsDemo(role, _maintenant)),
    ),
    ...surchargesAdministrationDemo(
      annonces: annonces,
      moderation: ModerationAdministrationDemo(maintenant: _maintenant),
      capacites: capacites,
    ),
  ];
}

// --- Gestes -----------------------------------------------------------------

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible.first);
  await _stabiliser(tester);
  await tester.tap(cible.first);
  await _stabiliser(tester);
}

/// Ecrit une publication marquee et touche « Publier » : le garde repond.
Future<void> Function(WidgetTester) _publierMarque(BrouillonMarqueDemo m) =>
    (WidgetTester tester) async {
      await _toucher(tester, find.byKey(EntreeNouvellePublication.cle));
      await _toucher(
        tester,
        find.byKey(
          ComposerPublication.cleCategorie(DonneesCommunauteDemo.pedagogie.id),
        ),
      );
      await tester.enterText(find.byKey(ComposerPublication.cleTitre), m.titre);
      await tester.enterText(find.byKey(ComposerPublication.cleTexte), m.texte);
      await _stabiliser(tester);
      await _toucher(tester, find.byKey(ComposerPublication.clePublier));
      final Finder verdict = find.byKey(ComposerPublication.cleVerdict);
      if (verdict.evaluate().isNotEmpty) {
        await tester.ensureVisible(verdict);
        await _stabiliser(tester);
      }
    };

Future<void> _signaler(WidgetTester tester) async {
  await _toucher(tester, find.byKey(PublicationDetail.cleMenu));
  await _toucher(tester, find.text(t.com.communaute.publication.signaler));
  await _toucher(
    tester,
    find.byKey(
      FeuilleSignalementCommunaute.cleMotif(MotifSignalement.publicite),
    ),
  );
}

/// Ecrit une reponse marquee (lien affilie) et touche « Envoyer » : la
/// garde retient la reponse (revue COM-R, R-01).
Future<void> _repondreMarque(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(ComposerReponse.cleChamp));
  await _stabiliser(tester);
  await tester.enterText(
    find.byKey(ComposerReponse.cleChamp),
    DonneesCommunauteDemo.reponseAffilie,
  );
  await _stabiliser(tester);
  await _toucher(tester, find.byKey(ComposerReponse.cleEnvoyer));
  final Finder garde = find.byKey(ComposerReponse.cleGarde);
  if (garde.evaluate().isNotEmpty) {
    await tester.ensureVisible(garde.first);
    await _stabiliser(tester);
  }
}

/// Fait defiler la publication jusqu'au composer de reponse, place apres
/// les reponses depuis COM-RC tour 2 (lot E).
Future<void> _allerAuComposerReponse(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(ComposerReponse.cleEnvoyer));
  await _stabiliser(tester);
}

/// Entre en Focus. A texte agrandi, l'en-tete du canal defile avec le fil
/// (COM-RC, R-02) : « Mode focus » se retrouve en remontant le fil, comme
/// dans `test/features/com_studio/support_focus.dart`.
Future<void> _focus(WidgetTester tester) async {
  final Finder entrer = find.byKey(BasculeFocus.cleEntrer);
  if (entrer.evaluate().isEmpty) {
    tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(FilDiscussion),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position
        .jumpTo(0);
    await _stabiliser(tester);
  }
  await _toucher(tester, entrer);
}

Future<void> Function(WidgetTester) _vocal(
  HorlogeManuelle horloge, {
  bool arreter = false,
}) => (WidgetTester tester) async {
  await _toucher(tester, find.byKey(FilDiscussion.cleMicro));
  horloge.avancer(const Duration(seconds: 12));
  await tester.pump(const Duration(seconds: 12));
  await _stabiliser(tester);
  if (arreter) {
    await _toucher(tester, find.byKey(ComposerVocal.cleArreter));
  }
};

Future<void> _vocalRefuse(WidgetTester tester) =>
    _toucher(tester, find.byKey(FilDiscussion.cleMicro));

/// Le planning : la capture descend jusqu'a la pastille de la premiere
/// seance (salle ouverte), sous la date.
Future<void> _premiereSeanceDuPlanning(WidgetTester tester) async {
  final Finder pastille = find.byType(StatusPill);
  if (pastille.evaluate().isNotEmpty) {
    await tester.ensureVisible(pastille.first);
    await _stabiliser(tester);
  }
}

/// R-16 : la seance ouverte passe avant les annonces de la Classe. La
/// capture part de la carte de seance, les annonces suivent dessous ; sans
/// carte, elle part des annonces.
Future<void> _seancePuisAnnonces(WidgetTester tester) async {
  final Finder carte = find.byType(CarteSeanceClasse);
  final Finder annonces = find.byType(AnnoncesDeClasse);
  final Finder cible = carte.evaluate().isNotEmpty ? carte : annonces;
  if (cible.evaluate().isNotEmpty) {
    await tester.ensureVisible(cible.first);
    await _stabiliser(tester);
  }
}

// --- Les ecrans -------------------------------------------------------------

List<_Ecran> _ecrans() {
  final HorlogeManuelle horlogeEnregistrement = HorlogeManuelle();
  final HorlogeManuelle horlogePreEcoute = HorlogeManuelle();
  const RoleDemoCommunications tuteur = RoleDemoCommunications.tuteur;
  const RoleDemoCommunications enseignant = RoleDemoCommunications.enseignant;
  const RoleDemoCommunications admin = RoleDemoCommunications.admin;
  List<Override> communaute(SituationDemoCommunaute s) => <Override>[
    ..._role(AppRole.teacher),
    ...surchargesCommunauteDemo(s),
    if (s == SituationDemoCommunaute.horsLigne) _horsLigne(),
  ];
  List<Override> administration() => <Override>[
    ..._admin(),
    ..._annonces(admin, capacites: capacitesDemoAdministration),
  ];
  return <_Ecran>[
    // Messages metier (COM-M01, COM-W01).
    _Ecran(
      'messages_liste_tuteur',
      Routes.tuteurMessages,
      () => <Override>[..._role(AppRole.guardian), ..._messages(tuteur)],
      principal: true,
    ),
    _Ecran(
      'messages_fil_tuteur',
      Routes.tuteurFilPour('fil-adam'),
      () => <Override>[..._role(AppRole.guardian), ..._messages(tuteur)],
      principal: true,
    ),
    _Ecran(
      'messages_fil_contexte_enseignant',
      Routes.enseignantFilPour('fil-yasmine'),
      () => <Override>[..._role(AppRole.teacher), ..._messages(enseignant)],
      principal: true,
    ),
    _Ecran(
      'messages_hors_ligne_tuteur',
      Routes.tuteurFilPour('fil-adam'),
      () => <Override>[
        ..._role(AppRole.guardian),
        ..._messages(tuteur, situation: SituationDemoMessages.horsLigne),
      ],
    ),
    _Ecran(
      'messages_vide_tuteur',
      Routes.tuteurMessages,
      () => <Override>[
        ..._role(AppRole.guardian),
        ..._messages(tuteur, port: FauxMessagesMetier()),
      ],
    ),
    // Vocal (COM-VOC-1, branche a COM-FUS).
    _Ecran(
      'vocal_enregistrement_tuteur',
      Routes.tuteurFilPour('fil-adam'),
      () => <Override>[
        ..._role(AppRole.guardian),
        ..._messages(tuteur, horloge: horlogeEnregistrement),
      ],
      geste: _vocal(horlogeEnregistrement),
    ),
    _Ecran(
      'vocal_pre_ecoute_tuteur',
      Routes.tuteurFilPour('fil-adam'),
      () => <Override>[
        ..._role(AppRole.guardian),
        ..._messages(tuteur, horloge: horlogePreEcoute),
      ],
      geste: _vocal(horlogePreEcoute, arreter: true),
    ),
    _Ecran(
      'vocal_micro_refuse_tuteur',
      Routes.tuteurFilPour('fil-adam'),
      () => <Override>[
        ..._role(AppRole.guardian),
        ..._messages(tuteur, permission: PermissionMicro.refusee),
      ],
      geste: _vocalRefuse,
    ),
    // Communaute enseignants (COM-M02, COM-W02).
    _Ecran(
      'communaute_flux',
      Routes.enseignantCommunaute,
      () => communaute(SituationDemoCommunaute.nominal),
      principal: true,
    ),
    _Ecran(
      'communaute_publication',
      Routes.enseignantPublicationPour(
        DonneesCommunauteDemo.publicationOuverte,
      ),
      () => communaute(SituationDemoCommunaute.nominal),
      principal: true,
    ),
    _Ecran(
      'communaute_garde_bloque',
      Routes.enseignantCommunaute,
      () => communaute(SituationDemoCommunaute.nominal),
      geste: _publierMarque(DonneesCommunauteDemo.brouillonAffilie),
    ),
    _Ecran(
      'communaute_garde_averti',
      Routes.enseignantCommunaute,
      () => communaute(SituationDemoCommunaute.nominal),
      geste: _publierMarque(DonneesCommunauteDemo.brouillonPublicite),
    ),
    _Ecran(
      'communaute_signalement',
      Routes.enseignantPublicationPour(
        DonneesCommunauteDemo.publicationOuverte,
      ),
      () => communaute(SituationDemoCommunaute.nominal),
      geste: _signaler,
    ),
    _Ecran(
      'communaute_reponse_bloquee',
      Routes.enseignantPublicationPour(
        DonneesCommunauteDemo.publicationOuverte,
      ),
      () => communaute(SituationDemoCommunaute.nominal),
      geste: _repondreMarque,
    ),
    _Ecran(
      'communaute_publication_composer',
      Routes.enseignantPublicationPour(
        DonneesCommunauteDemo.publicationOuverte,
      ),
      () => communaute(SituationDemoCommunaute.nominal),
      geste: _allerAuComposerReponse,
      variantes: <_Variante>[..._accessibilite, ..._etats],
    ),
    _Ecran(
      'communaute_vide',
      Routes.enseignantCommunaute,
      () => communaute(SituationDemoCommunaute.vide),
    ),
    _Ecran(
      'communaute_hors_ligne',
      Routes.enseignantCommunaute,
      () => communaute(SituationDemoCommunaute.horsLigne),
    ),
    // Le Studio (COM-M03, COM-M04, COM-M05, COM-W00, COM-W03, COM-W03F).
    _Ecran(
      'studio_aujourdhui',
      Routes.adminStudio,
      () => <Override>[..._admin(), ..._studio()],
      principal: true,
    ),
    _Ecran(
      'studio_canal',
      cheminCanalStudio(canalFocusDemo),
      () => <Override>[..._admin(), ..._studio()],
      principal: true,
    ),
    _Ecran(
      'studio_focus',
      cheminCanalStudio(canalFocusDemo),
      () => <Override>[..._admin(), ..._studio()],
      geste: _focus,
      // Le Focus aussi en texte double a 320 (recette apres COM-RC tour 4).
      variantes: <_Variante>[_accessibilite.first, ..._etats],
    ),
    _Ecran(
      'studio_hors_ligne',
      cheminCanalStudio(canalFocusDemo),
      () => <Override>[
        ..._admin(),
        ..._studio(situation: SituationDemoStudio.horsLigne),
      ],
    ),
    _Ecran(
      'studio_aujourdhui_vide',
      Routes.adminStudio,
      () => <Override>[
        ..._admin(),
        ..._studio(situation: SituationDemoStudio.aujourdhuiVide),
      ],
    ),
    // Notifications et annonce de Classe (COM-M06, COM-ANN-1).
    _Ecran(
      'notifications_tuteur',
      Routes.tuteurNotifications,
      () => <Override>[..._role(AppRole.guardian), ..._annonces(tuteur)],
      principal: true,
    ),
    _Ecran(
      'notifications_enseignant',
      Routes.enseignantNotifications,
      () => <Override>[..._role(AppRole.teacher), ..._annonces(enseignant)],
    ),
    _Ecran(
      'annonce_classe_tuteur',
      Routes.classePour(classeA, eleveId: eleveA1),
      () => <Override>[
        // Lot L : la page, la carte et l'annonce disent la Classe An-Nour.
        ...surchargesClasseAnNour(_maintenant),
        _baseMemoire(),
        ..._annonces(tuteur, classeReelle: classeA),
      ],
      geste: _seancePuisAnnonces,
      principal: true,
    ),
    // Lot L : le planning de la meme Classe An-Nour (page, annonce,
    // planning disent la meme Classe ; sous-titre sans « An- / Nour »).
    _Ecran(
      'planning_classe_tuteur',
      cheminClasse(classeA, eleveA1, 'planning'),
      () => <Override>[...surchargesClasseAnNour(_maintenant), _baseMemoire()],
      geste: _premiereSeanceDuPlanning,
      variantes: <_Variante>[_etats.first, ..._accessibilite],
    ),
    // Administration des communications (COM-W04, COM-ANN-2, COM-MSG-2).
    _Ecran(
      'admin_annonces',
      Routes.adminCommunicationsAnnonces,
      administration,
      principal: true,
    ),
    _Ecran(
      'admin_moderation',
      Routes.adminCommunicationsModeration,
      administration,
      principal: true,
    ),
    _Ecran(
      'admin_messages',
      Routes.adminFilPour('fil-mission'),
      () => <Override>[
        ..._admin(),
        portMessagesMetierProvider.overrideWithValue(
          MessagesMetierDemo(role: admin, maintenant: _maintenant),
        ),
        _capacitesMessages(),
        ...surchargesVocalDemo(),
      ],
      principal: true,
    ),
  ];
}

// --- Montage et capture -----------------------------------------------------

void _preparer(WidgetTester tester, _Variante v) {
  final (
    _,
    Size logique,
    double densite,
    EdgeInsets zone,
    double echelle,
    _,
    AppLocale l,
  ) = v;
  fixerVueCapture(tester, logique, densite, zoneSure: zone);
  tester.platformDispatcher.textScaleFactorTestValue = echelle;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  LocaleSettings.setLocaleSync(l);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
}

Future<void> _monter(WidgetTester tester, _Ecran ecran, ThemeMode mode) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: ecran.surcharges(),
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: mode,
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
              );
            },
          ),
        ),
      ),
    ),
  );
  await _stabiliser(tester);
  routeur.go(ecran.chemin);
  await _stabiliser(tester);
}

/// Releve les debordements de rendu sans faire echouer la capture.
Future<void> _consigner(String nom, List<String> erreurs) async {
  if (erreurs.isEmpty) return;
  final File journal = File(
    '${dossierCapture!}${Platform.pathSeparator}com_debordements.txt',
  );
  await journal.parent.create(recursive: true);
  await journal.writeAsString(
    '== $nom\n${erreurs.join('\n')}\n',
    mode: FileMode.append,
  );
}

void _capturerEcran(_Ecran ecran, _Variante v) {
  final (String variante, _, _, _, _, ThemeMode mode, _) = v;
  final String nom = 'com_${ecran.nom}_$variante';
  testWidgets(nom, (WidgetTester tester) async {
    _preparer(tester, v);
    final List<String> erreurs = <String>[];
    final void Function(FlutterErrorDetails)? avant = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails d) {
      final String texte = d.exceptionAsString();
      erreurs.add(texte.split('\n').first);
      if (!texte.contains('overflowed')) avant?.call(d);
    };
    try {
      await _monter(tester, ecran, mode);
      final Future<void> Function(WidgetTester)? geste = ecran.geste;
      if (geste != null) await geste(tester);
      debugPrint('PNG ${await capturer(tester, nom)}');
    } finally {
      FlutterError.onError = avant;
    }
    await tester.runAsync(() => _consigner(nom, erreurs));
    // Demonte l'arbre : minuteries des blocs asynchrones et du vocal.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}

void main() {
  group('Capture : Communications V1 (COM-CAPT)', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      // La bibliotheque arabe est differee : chargee une fois, hors du
      // `FakeAsync` des tests, pour que `setLocaleSync` la trouve.
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.fr);
    });

    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    for (final _Ecran ecran in _ecrans()) {
      final List<_Variante> variantes =
          ecran.variantes ??
          (ecran.principal
              ? <_Variante>[..._completes, ..._accessibilite]
              : _etats);
      for (final _Variante v in variantes) {
        _capturerEcran(ecran, v);
      }
    }
  });
}
