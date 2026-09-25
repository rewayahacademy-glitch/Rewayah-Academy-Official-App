import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3 : il vit
// dans `misc.dart`, alors que `ProviderScope.overrides` en attend une liste.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/session/source_session.dart';
import 'package:rewayah_academy/core/tc_observation/activation_observation.dart';
import 'package:rewayah_academy/core/tc_observation/moteur_visite_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_visite_observation.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/service_video.dart';

// Les faux de salle d'Agent E, reutilises plutot que recopies : ils rejouent
// exactement ce que le vrai moteur PUBLIE -- trois flux et une liste -- et
// c'est tout ce dont l'ecran d'observation depend une fois entre en salle. En
// ecrire un second ici le ferait diverger du premier.
import '../../../support/harnais.dart'
    show FauxServiceAppairage, FauxServicePresence, FauxServiceReseau;
import '../../e/faux/faux_classe.dart';
import '../faux/faux_observation.dart';

/// L'hote minimal d'un composant d'observation sous test.
///
/// **Le sien, pas celui du depot.** `test/support/harnais.dart` est un fichier
/// unique de quarante kilo-octets deja modifie par le chantier enseignant : la
/// decision D-06 confie a chaque agent son propre hote sous
/// `test/teaching_core/<lettre>/support/`. Agent Z consolidera a
/// l'integration, pas avant.
///
/// Le theme est indispensable : `AppPalette.of` et `AppMetriques.of` lisent des
/// extensions de theme, et un composant monte sans elles echoue avant d'avoir
/// rendu quoi que ce soit.
Widget hoteTcG(
  Widget enfant, {
  List<Override> surcharges = const <Override>[],
  InterfaceMode mode = InterfaceMode.standard,
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(mode, Brightness.light),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: enfant),
        ),
      ),
    ),
  ),
);

/// L'hote d'un ecran d'observation qui navigue.
///
/// Le `GoRouter` est construit **ici**, hors de `lib/` : `verifier_jetons.dart`
/// refuse un second routeur dans `lib/`, et `routesTcG()` se contente donc de
/// retourner des routes. C'est ce test qui prouve qu'elles se montent.
Widget hoteRoutantTcG({
  required String depart,
  required List<RouteBase> routes,
  List<Override> surcharges = const <Override>[],
  InterfaceMode mode = InterfaceMode.standard,
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: MaterialApp.router(
      theme: AppTheme.pour(mode, Brightness.light),
      routerConfig: GoRouter(initialLocation: depart, routes: routes),
    ),
  ),
);

/// Une ligne de presence de `presence_seance_v`, ecrite court : l'enfant
/// `enfant-1`, present par defaut.
PresenceParticipant presenceDe({
  String profilId = 'enfant-1',
  EtatPresence etat = EtatPresence.presente,
}) => PresenceParticipant(
  profilId: profilId,
  role: 'student',
  prenom: 'Mariam',
  identifiantImmuable: 'STUD-TC-000001',
  etat: etat,
  consolide: false,
);

/// Une source de session en memoire, resolue d'emblee.
class FausseSourceSessionTcG implements SourceSession {
  /// Cree la source pour un role donne.
  FausseSourceSessionTcG(this.role);

  /// Le role porte par le jeton.
  final AppRole? role;

  @override
  Stream<SessionState> etats() => Stream<SessionState>.value(
    SessionState(
      resolue: true,
      role: role,
      profileId: 'p1',
      accountStatus: AccountStatus.active,
      lectureProfil: LectureProfil.presente,
    ),
  );

  @override
  Future<void> rafraichir() async {}
}

/// Les surcharges d'un ecran d'observation sous test.
///
/// Le moteur de salle et le service video sont TOUJOURS remplaces, meme quand
/// le test ne parle pas de video : `EntreeObservationPage` lit
/// `moteurSalleProvider` des son `initState`, et un test qui laisserait passer
/// le vrai construirait un `LiveKitSessionProvider`.
List<Override> surchargesTcG({
  AppRole? role,
  FauxPortVisite? visites,
  FauxPortPolitique? politique,
  FauxMoteurClasse? moteur,
  FauxServiceVideoClasse? video,
  Stream<void>? battement,
  DateTime Function()? horloge,
  List<Override> autres = const <Override>[],
  bool observationReelle = true,
  FauxServicePresence? presence,
  StockagePreferences? stockage,
  bool horsLigne = false,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(FausseSourceSessionTcG(role)),
  // La verification prealable du tuteur lit la presence de l'enfant, le foyer
  // (quand l'adresse ne nomme pas l'eleve) et la memoire « explication deja
  // vue » : tous en memoire, aucun Supabase ni base locale.
  servicePresenceProvider.overrideWithValue(
    presence ??
        FauxServicePresence(lignes: <PresenceParticipant>[presenceDe()]),
  ),
  serviceAppairageProvider.overrideWithValue(
    FauxServiceAppairage()
      ..elevesRendus = const <EleveDuFoyer>[
        EleveDuFoyer(
          id: 'enfant-1',
          prenom: 'Mariam',
          identifiantImmuable: 'STUD-TC-000001',
          mode: InterfaceMode.standard,
          camera: CameraPolicy.forbidden,
        ),
      ],
  ),
  stockagePreferencesProvider.overrideWithValue(
    stockage ?? StockagePreferencesMemoire(),
  ),
  serviceReseauProvider.overrideWithValue(
    FauxServiceReseau(horsLigneRendu: horsLigne),
  ),
  // L'interrupteur P3 est ouvert par defaut : ces tests decrivent la visite
  // telle qu'elle sera ouverte. Ferme, le tuteur ne voit que « pas encore
  // disponible » (test dedie).
  observationTuteurReelleProvider.overrideWithValue(observationReelle),
  // **Le battement d'affichage est coupe par defaut.** Le vrai vaut
  // `Stream.periodic(1 s)` : dans un test de widget, c'est un Timer qui reste
  // pendant apres le demontage de l'arbre, et le cadre de test echoue dessus.
  // Le couper ne retire rien a ce qui se verifie ici : il ne fait que
  // repeindre un chiffre, et la seule autorite sur la fin d'une visite est le
  // flux de budget du serveur.
  moteurVisiteObservationProvider.overrideWith((Ref ref, String sessionId) {
    final MoteurVisiteObservation moteurVisite = MoteurVisiteObservation(
      ref.watch(portVisiteObservationProvider),
      ref.watch(portPolitiqueObservationProvider),
      battement: battement ?? const Stream<void>.empty(),
      horloge: horloge,
    );
    ref.onDispose(() => unawaited(moteurVisite.dispose()));
    return moteurVisite;
  }),
  portVisiteObservationProvider.overrideWithValue(visites ?? FauxPortVisite()),
  portPolitiqueObservationProvider.overrideWithValue(
    politique ?? FauxPortPolitique(),
  ),
  moteurSalleProvider.overrideWithValue(moteur ?? FauxMoteurClasse()),
  // **Sans jeton par defaut, et c'est le bon defaut** : un test qui ne pose
  // aucun acces doit exercer le refus, pas une salle ouverte par commodite.
  serviceVideoProvider.overrideWithValue(video ?? FauxServiceVideoClasse()),
  ...autres,
];
