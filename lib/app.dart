import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/accessibilite/mode_accessibilite.dart';
import 'core/communications/veille_messages.dart';
import 'core/domain/enums.dart';
import 'core/fraicheur/avis_ephemere.dart';
import 'core/fraicheur/avis_flottant.dart';
import 'core/fraicheur/relecture_page.dart';
import 'core/fraicheur/veille_fraicheur.dart';
import 'core/i18n/strings.g.dart';
import 'core/preferences/preferences_locales.dart';
import 'core/push/bandeau_invitation_push.dart';
import 'core/router/app_router.dart';
import 'core/router/fil_ariane.dart';
import 'core/session/session_controleur.dart';
import 'core/session/session_state.dart';
import 'core/source_inscription/source_inscription.dart';
import 'core/tc_horloge/mon_horloge.dart';
import 'core/theme/app_palette.dart';
import 'core/theme/app_theme.dart';
import 'core/version/bandeau_nouvelle_version.dart';
import 'core/widgets/bandeau_observation.dart';
import 'features/compte/correction_nom.dart';
import 'features/salle/passage_second_appareil.dart' show CoucheAutreAppareil;
import 'features/salle_seance/barre_seance_en_direct.dart';
import 'features/salle_seance/hors_salle.dart';

/// Racine de l'application.
///
/// Le mode d'interface porte par le profil eleve change le theme, jamais
/// l'arborescence de navigation (ADR-009) : c'est pour cela que le mode est lu
/// ici, une seule fois, et non dans chaque ecran.
///
/// Le theme clair/sombre suit **la preference Apparence** de l'appareil
/// (`preferencesLocalesProvider`, Systeme par defaut) : la page Compte >
/// Reglages > Apparence et la bascule soleil / lune de l'en-tete ecrivent la
/// meme preference, et elle est lue ici, une seule fois pour toute
/// l'application (decisions du coordinateur du 24/09/2026, section 3,
/// point 5). Avant ce branchement, la page Reglages ecrivait une preference
/// que rien ne lisait. Le choix est persiste sur l'appareil par
/// [persistanceApparenceProvider].
class RewayahApp extends ConsumerWidget {
  /// Cree la racine.
  ///
  /// [themeMode] force le mode clair/sombre, au-dessus de la preference :
  /// reserve au Playground et aux tests ; `null` (defaut) laisse la preference
  /// decider. [builder] est le passe-vole du meme nom de `MaterialApp` : le
  /// Playground force par la un gabarit d'apercu, la production n'en a aucun
  /// usage.
  const RewayahApp({super.key, this.themeMode, this.builder});

  /// Mode clair/sombre force, ou `null` pour suivre la preference Apparence.
  final ThemeMode? themeMode;

  /// Coupe le rendu sous la navigation, s'il y en a une.
  final Widget Function(BuildContext context, Widget? child)? builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter routeur = ref.watch(routeurProvider);
    final SessionState session = ref.watch(sessionProvider);
    // Lecture du theme persiste au montage, ecriture a chaque changement.
    ref.watch(persistanceApparenceProvider);
    // Meme regle pour la langue choisie (lot 22 a, PREFERENCES-WEB).
    ref.watch(persistanceLangueProvider);
    // Meme regle pour le repli de la navigation laterale (bouton de repli).
    ref.watch(persistanceNavigationProvider);
    // Meme regle pour les raccourcis clavier de la salle (EN-KB).
    ref.watch(persistanceRaccourcisProvider);
    // Fraicheur (27/10/2026) : une seule veille des classes et des seances,
    // ouverte avec la session, fermee avec elle.
    ref.watch(veilleFraicheurProvider);
    // MESSAGERIE-TEMPS-REEL (14/11/2026) : la veille des messages, meme
    // regle (ouverte avec la session, fermee avec elle).
    ref.watch(veilleMessagesProvider);
    // REF-SUIVI (22/11/2026) : la source gardee sur l'appareil part au serveur,
    // une fois, des que la personne est connectee.
    ref.watch(veilleSourceInscriptionProvider);
    // FUSEAUX (04/11/2026) : l'heure de chacun vient du fuseau de son profil.
    // Lue ici une fois, pour que chaque ecran se redessine quand elle arrive.
    ref.watch(monHorlogeProvider);
    final ThemeMode mode = themeMode ?? ref.watch(modeThemeProvider);
    // MA-2 (question 2 de MA-1b) : la presentation vient du fournisseur
    // unique du Mode Accessibilite, et le theme reste celui d'`AppTheme.pour`
    // existant, sans aucune couleur nouvelle (K-37).
    final InterfaceMode presentation = ref.watch(modeAccessibiliteActifProvider)
        ? InterfaceMode.enfant
        : InterfaceMode.standard;

    return MaterialApp.router(
      title: 'Rewayah Academy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.pour(presentation, Brightness.light),
      darkTheme: AppTheme.pour(presentation, Brightness.dark),
      themeMode: mode,
      // Le bandeau d'observation coiffe TOUS les ecrans, et il est pose ici
      // plutot que dans `PageShell` pour deux raisons : il doit survivre aux
      // ecrans qui n'emploient pas la coquille (la salle est immersive), et il
      // ne doit exister qu'une fois a l'ecran, quel que soit l'empilement.
      // Le passe-vole du Playground reste compose, jamais remplace.
      builder: (BuildContext context, Widget? child) {
        // MA-1b : le mouvement reduit (preference locale, reglage systeme,
        // reduceMotion iOS) est pose ici, une fois, pour tous les ecrans.
        final Widget? rendu = builder == null
            ? child
            : builder!(context, child);
        final Observation? observation = session.observation;
        // LG-FLASH : un fond opaque, celui du theme, sous TOUTES les routes.
        // Sans lui, une frame ou le contenu n'est pas encore opaque (fondu
        // d'onglet, page qui entre) laissait la toile transparente, et le
        // navigateur montrait le fond creme de `web/index.html` : un flash
        // clair a chaque changement d'ecran en mode sombre.
        final Color fond = AppPalette.of(context).surfaceCanvas.background;
        // PE-D11 (directeur, 19/11/2026, cause prouvee : PLAN §14.1) : plus
        // de `SelectionArea` global. Il ajoutait un appui long a chaque
        // toucher, boutons compris (« Tout selectionner » au moindre
        // toucher), et sa selection ne s'effacait jamais. Ce qui se lit se
        // selectionne localement, par `TexteSelectionnable`.
        // `Overlay.wrap` : les infobulles et menus poses ici, hors du
        // `Navigator`, gardent une couche ou s'afficher.
        return Overlay.wrap(
          // SALLE-SECOND-APPAREIL (directeur, 23/11/2026) : la question « Laisser
          // passer ? » arrive par-dessus l'ecran ouvert, salle reduite
          // comprise : le battement suit la connexion video, pas la page.
          child: CoucheAutreAppareil(
            enSalle: () => routeur.routerDelegate.currentConfiguration.uri.path
                .startsWith('/salle'),
            child: ReglageMouvement(
              child: ColoredBox(
                color: fond,
                // PE-D8 (directeur, 19/11/2026 : « rien ne pousse la page ») :
                // la nouvelle version et les avis courts (« Vous avez recu un
                // nouveau message. », « Cette classe n'existe plus. ») flottent
                // en haut, par-dessus l'ecran, au lieu de le decaler.
                child: CoucheAvis(
                  avis: <Widget>[
                    BandeauNouvelleVersion(
                      enSeance: () => routeur
                          .routerDelegate
                          .currentConfiguration
                          .uri
                          .path
                          .startsWith('/salle'),
                    ),
                    const BandeauAvisEphemere(),
                    // HORS-SALLE-1 (directeur, 12/11/2026 au soir) : le son
                    // bloque, salle reduite.
                    BandeauSonBloqueHorsSalle(routeur: routeur),
                    // NOTIF-DEFAUT : la demande des notifications, une fois par
                    // appareil.
                    const BandeauInvitationPush(),
                    // L'observation reste visible tant qu'elle dure, posee
                    // par-dessus, sans croix.
                    if (observation != null)
                      BandeauObservation(observation: observation),
                  ],
                  child: Column(
                    children: <Widget>[
                      // L'eleve sorti pendant son absence hors de l'application
                      // retrouve l'ecran du retour (ne rend rien).
                      RetourHorsApplication(routeur: routeur),
                      // R3 (30/10/2026) : tirer pour rafraichir (`PageShell`) et
                      // relire au retour sur un onglet ou dans l'application.
                      // Directeur, 31/10/2026 : « Seance toujours en direct » sur
                      // tous les ecrans hors de la salle, tant que l'appel continue.
                      Expanded(
                        child: BarreSeanceEnDirect(
                          routeur: routeur,
                          child: RelectureGenerale(
                            // FIL-ARIANE (06/11/2026) : l'arbre des routes du role,
                            // lu une fois ici, pour le fil de chaque `PageShell`.
                            child: ContexteFilAriane(
                              plan: planFilPour(session),
                              // NOM-PROPRE (14/11/2026) : un nom a corriger
                              // passe avant tout le reste.
                              child: GardeNomPropre(
                                child: rendu ?? const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      routerConfig: routeur,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
