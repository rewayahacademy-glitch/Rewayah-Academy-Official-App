import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 a sorti `Override` de l'export principal.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/agent/amorce_agent.dart';
import 'core/agent/session_agent.dart';
import 'core/capacites/classes_foyer_supabase.dart';
import 'core/capacites/notifications_supabase.dart';
import 'core/capacites/port_classes_foyer.dart';
import 'core/capacites/port_notifications.dart';
import 'core/capacites/revue_dossiers_depuis_validation.dart';
import 'core/config/ecran_configuration_absente.dart';
import 'core/config/env.dart';
import 'core/i18n/langue_demarrage.dart';
import 'core/i18n/strings.g.dart';
import 'core/observabilite/supervision.dart';
import 'core/session/session_controleur.dart';
import 'core/session/source_session_agent.dart';
import 'features/_dev/playground/playground_racine.dart';
import 'features/demo/dossiers_demo.dart';
import 'features/demo/mode_demonstration.dart';
import 'features/demo/racine_demonstrable.dart';
import 'features/demo/repere_demonstration.dart';

/// Les surcharges de l'application reelle (jamais le mode demonstration) :
/// le port des classes du foyer bascule sur l'adaptateur Supabase des que le
/// client est initialise (constat C-INT-1, `demandes/c.md`). Un provider
/// partage ne doit pas dependre implicitement d'un service reseau pour son
/// comportement par defaut ; ce branchement se fait ici et nulle part
/// ailleurs.
List<Override> _surchargesAppReelle() => <Override>[
  portClassesFoyerProvider.overrideWithValue(
    ClassesFoyerSupabase(Supabase.instance.client),
  ),
  portNotificationsProvider.overrideWithValue(
    NotificationsSupabase(
      Supabase.instance.client,
      contenuPour: contenuNotificationLocalise,
    ),
  ),
  surchargeRevueDossiersProduction,
];

/// Point d'entree unique de l'application.
///
/// Une seule cible, toutes les plateformes : Windows, Android, iOS et Web. Le
/// Web est ouvert a tous les roles (ADR-008), il n'y a donc aucune branche de
/// demarrage par plateforme.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // La supervision avant tout le reste : une erreur du demarrage lui-meme doit
  // remonter comme les autres, y compris l'ecran de configuration absente.
  // Sans DSN, cet appel ne fait rien. Il ne passe pas par `appRunner` : sur
  // Flutter 3.47, `PlatformDispatcher.onError` existe, donc Sentry n'ouvre
  // aucune zone gardee et `appRunner` ne capterait pas une erreur de plus.
  await Supervision.demarrer();

  // Jamais `LocaleSettings.useDeviceLocale()` : une langue systeme mal formee
  // (« en-US@posix ») y levait et arretait l'application (CLAVIER-ENTREE-1).
  await appliquerLangueDeLAppareil();

  // La configuration est injectee a la compilation, jamais versionnee.
  // Sans elle, on echoue tot, en clair, et EN RELEASE AUSSI : un `assert` seul
  // ne tient pas cette promesse, il disparait de la version compilee et laisse
  // l'application demarrer pour mourir plus loin sur un ecran gris.
  if (!Env.configuree) {
    runApp(const EcranConfigurationAbsente());
    return;
  }

  // L'observation par un agent IA (ADR-025) se decide ICI et nulle part
  // ailleurs : l'identite sous laquelle le client parle a la base est une
  // decision d'amorcage. Un ecran ne peut pas la prendre apres coup, puisque le
  // client est deja construit quand le premier ecran s'affiche.
  final String? jetonAgent = jetonAgentDeLUrl();
  if (jetonAgent != null) {
    await _demarrerObservation(jetonAgent);
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  // Demonstration tuteur (P2-07) : `?demo=tuteur`, jamais en production.
  if (demoTuteurActiveIci) {
    final ({EtatRevueDemo dossiers, String titulaire})? titulaireDemo =
        dossierTitulaireDemoPour(Uri.base);
    runApp(
      ProviderScope(
        overrides: surchargesDemoTuteur(
          dossiers: titulaireDemo?.dossiers,
          titulaire: titulaireDemo?.titulaire,
        ),
        child: TranslationProvider(
          child: RewayahApp(
            builder: (BuildContext context, Widget? child) =>
                RepereDemonstration(child: child),
          ),
        ),
      ),
    );
    return;
  }

  // Demonstration admin (AD-4) : `?demo=admin`, meme garde et meme repere.
  // Aucun adaptateur serveur des ports de revue n'est branche (K-28).
  if (demoAdminActiveIci) {
    runApp(
      ProviderScope(
        overrides: surchargesDemoAdmin(
          etat: etatRevueDemoPour(Uri.base),
          avecAlertes: true,
          arriveeAlerte: dureeArriveeAlerteDemo,
        ),
        child: TranslationProvider(
          child: RewayahApp(
            builder: (BuildContext context, Widget? child) =>
                RepereDemonstration(child: child),
          ),
        ),
      ),
    );
    return;
  }

  if (Env.playgroundActif) {
    runApp(
      ProviderScope(
        child: TranslationProvider(child: const PlaygroundRacine()),
      ),
    );
    return;
  }

  // Hors production, la racine porte l'entree « Essayer la demonstration »
  // (P2-07) ; en production elle n'a aucun lanceur et se comporte comme
  // l'application seule.
  runApp(RacineDemonstrable(surchargesReelles: _surchargesAppReelle()));
}

/// Demarre l'application en session d'observation.
///
/// L'echange du jeton se fait AVANT `Supabase.initialize`, pour deux raisons.
/// La premiere : le client s'initialise avec le passe-vole `accessToken`, donc
/// il faut deja savoir que l'observation est possible. La seconde, plus
/// importante : un jeton refuse doit le rester **avant** que le moindre ecran
/// metier existe. Ouvrir l'application puis echouer a la premiere requete
/// afficherait une coquille vide au lieu d'un refus.
///
/// Quand la remise echoue, on demarre l'application **normalement**, sur
/// `AGT-00`, qui dit ce qui s'est passe. Pas d'ecran d'erreur separe : un agent
/// qui a un jeton valide sous la main doit pouvoir s'en servir tout de suite.
Future<void> _demarrerObservation(String jeton) async {
  final PorteurSessionAgent porteur = PorteurSessionAgent(
    jeton: jeton,
    url: Env.supabaseUrl,
    cleAnon: Env.supabaseAnonKey,
  );

  EchecAgent? echec;
  try {
    await porteur.ouvrir();
  } on ErreurAgent catch (e) {
    echec = e.cause;
  } on Object {
    echec = EchecAgent.serviceIndisponible;
  }

  if (echec != null) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
    runApp(
      ProviderScope(
        overrides: <Override>[
          echecAgentProvider.overrideWithValue(echec),
          ..._surchargesAppReelle(),
        ],
        child: TranslationProvider(child: const RewayahApp()),
      ),
    );
    return;
  }

  // `accessToken` remplace l'authentification gotrue : `client.auth` devient
  // inutilisable, et c'est exactement ce qu'on veut. Une session d'observation
  // ne se connecte pas, ne se deconnecte pas, et ne porte aucun jeton de
  // rafraichissement -- le porteur repasse par la base a chaque renouvellement.
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
    accessToken: porteur.jetonFrais,
  );

  runApp(
    ProviderScope(
      overrides: <Override>[
        sourceSessionProvider.overrideWithValue(
          SourceSessionAgent(porteur, Supabase.instance.client),
        ),
        ..._surchargesAppReelle(),
      ],
      child: TranslationProvider(child: const RewayahApp()),
    ),
  );
}
