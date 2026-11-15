import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../admin/admin_domaine.dart';
import '../admin/sous_liens_coquille.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../preferences/preferences_locales.dart' show navigationReplieeProvider;
import '../router/routes.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_bottom_sheet.dart';
import 'avatar_nom.dart';
import 'bascule_theme.dart';
import 'brand_logo.dart';
import 'entete_page.dart';
import 'halo_lumiere.dart' show ArbitreLumieres;
import 'lien_fleche.dart';
import 'menu_actions.dart';
import 'nav_shell.dart' show BoutonPanneau, Destination, PiedComptePanneau;
import 'page_shell.dart';
import 'pressable.dart';

/// La coquille de navigation du panneau admin : huit domaines, jamais plus
/// granulaire (gel d'architecture, `docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md`).
///
/// **Distincte de `NavShell`**, qui plafonne a quatre destinations pour les
/// autres roles (`03-architecture-information.md` section 5) -- une limite
/// pensee pour le MVP. L'operateur a tranche que le panneau admin grandira
/// avec un RBAC a plusieurs roles, et qu'une barre a quatre entrees n'y
/// suffit plus. La regle qui reste absolue n'est plus « quatre » mais
/// « jamais plus granulaire que les huit domaines eux-memes » -- voir
/// [maxDomaines], qui la tient par un `assert` vivant, pas par une relecture.
///
/// **Un domaine sans fonction livree reste visible mais inerte** : l'audit
/// interdit explicitement de construire un ecran vide pour remplir le
/// chrome (`AdminDomaine.chemin` est alors nul). Le libelle et l'icone sont
/// rendus attenues, et un tap n'y declenche aucune navigation -- le meme
/// traitement qu'un compteur d'`ADM-01` sans destination, jamais un bouton
/// grise qui mentirait sur ce que la personne peut obtenir.
///
/// Trois formes, une seule liste de domaines : tiroir sous 600, rail replie
/// de 600 a 1199, barre laterale permanente a partir de 1200. **Jamais de
/// barre basse ici** : la mission l'interdit explicitement pour l'admin,
/// huit domaines n'y tiendraient pas.
///
/// **En-tete (AD-S, maquette 02A)** : a partir de 600, aucune barre
/// superieure. Les actions de la coquille (Recherche, bascule de theme,
/// compte) se posent a droite de l'en-tete de chaque page par
/// [ActionsEnteteCoquille], a cote du titre et du sous-titre de la page.
/// Sous 600, une barre mobile garde Menu, le champ de recherche et le
/// compte. Pas de cloche tant qu'aucun service de notifications n'existe
/// (Q5) : [cloche] n'est fournie que lorsque la capacite « alertes » rend
/// quelque chose (ALERTE-1), et se pose alors avant le compte, sur toutes
/// les formes. Chaque page recoit aussi le retour vers l'Accueil
/// ([onRetour]).
///
/// **Communications (COM-F)** : la cloche des notifications
/// ([onNotifications]) mene a la `NotificationsPage` existante, sans point
/// tant que le port est indisponible (comme le tuteur) ; l'action « Le
/// Studio » ([onStudio]) ouvre l'espace de travail interne (QUESTIONS Q1),
/// jamais un neuvieme domaine. **La coquille ne lit aucun role** : elle rend
/// ces deux entrees seulement quand son appelant les lui donne (le routeur,
/// sous le prefixe `/admin` que la garde reserve a l'admin). Sur la page des
/// notifications, la cloche se montre active ([notificationsActives],
/// reponse Q5 du 04/10). La cloche des alertes ([cloche], ALERTE-1) et celle
/// des notifications sont deux entrees distinctes (JONCTION-LIGNES-1).
class AdminShell extends StatelessWidget {
  /// Cree la coquille admin.
  ///
  /// **Volontairement non `const`**, meme raison que `NavShell` : l'assertion
  /// porte sur la longueur d'une liste, qui n'est pas une expression
  /// constante.
  // ignore: prefer_const_constructors_in_immutables
  AdminShell({
    required this.domaines,
    required this.domaineActif,
    required this.onAller,
    required this.onCompte,
    required this.child,
    super.key,
    this.onRetour,
    this.cloche,
    this.messages,
    this.bandeau,
    this.onNotifications,
    this.notificationsActives = false,
    this.onStudio,
    this.onRechercheMetier,
    this.onDeconnexion,
    this.sousLiens = const <AdminDomaine, List<SousLien>>{},
    this.cheminCourant,
    this.conversationOuverte = false,
  }) : assert(
         domaines.length <= maxDomaines,
         'La sidebar admin ne contient jamais plus de $maxDomaines domaines '
         '(gel d\'architecture, regle absolue).',
       );

  /// Les domaines visibles, dans l'ordre impose.
  final List<AdminDomaine> domaines;

  /// Le domaine actif, pour le surligner.
  final AdminDomaine? domaineActif;

  /// Ce qui se passe quand un domaine actif ou un resultat de recherche est
  /// choisi. Recoit une route, jamais un domaine : la recherche peut mener a
  /// un ecran qu'aucun libelle de domaine ne nomme.
  final void Function(String chemin) onAller;

  /// Ouvre « Mon compte », partage par tous les roles.
  final VoidCallback onCompte;

  /// WEB-BUREAU (P1, 06/11/2026) : la deconnexion, dans le menu du compte en
  /// haut a droite, a partir de 600 (au telephone, elle reste en bas du
  /// Compte). Nul : le bouton « Mon compte » seul, comme avant.
  final VoidCallback? onDeconnexion;

  /// Le retour pose sur chaque page de la coquille (spec section 26 ter,
  /// Q14) : vers l'Accueil, nul sur l'Accueil lui-meme.
  final VoidCallback? onRetour;

  /// La cloche des alertes, ou `null` sans capacite « alertes » (Q5).
  final Widget? cloche;

  /// MESSAGERIE-TEMPS-REEL (14/11/2026) : l'acces aux Messages avec le nombre
  /// de non lus, pose seulement quand un message attend ; `null` sinon. Il
  /// se range a cote de la cloche des alertes, a toutes les tailles.
  final Widget? messages;

  /// Le bandeau pose tout en haut de chaque page : l'alerte urgente
  /// (ALERTE-1). Nul : aucun.
  ///
  /// **Fige au-dessus de la page, jamais dans sa tete** (ALERTE-1b) : la
  /// coquille le pose au-dessus de la page ouverte, hors de la zone qui
  /// defile. Il reste en vue tant que l'alerte est ouverte, et pousse la page
  /// vers le bas sans jamais la recouvrir (« tout en haut de l'ecran,
  /// jusqu'a ce qu'elle soit traitee », decision du 05/10). Sa hauteur est
  /// bornee a la moitie de la vue : au-dela (vue tres basse, texte a 400 %),
  /// il defile dans sa propre zone et la page garde l'autre moitie
  /// (WCAG 1.4.10).
  final Widget? bandeau;

  /// Ouvre les notifications (`/admin/notifications`). Nul : aucune cloche.
  final VoidCallback? onNotifications;

  /// La page ouverte est celle des notifications : la cloche s'y montre
  /// active (icone pleine, etat selectionne), aucun domaine ne l'etant.
  final bool notificationsActives;

  /// Ouvre la recherche metier (`/recherche`, RECH-D5) : la loupe d'en-tete
  /// garde sa recherche de navigation et y ajoute ce lien. Nul quand aucun
  /// domaine n'est servi a cet espace : la loupe est alors inchangee.
  final VoidCallback? onRechercheMetier;

  /// Ouvre Le Studio (`/admin/studio`). Nul : aucune action Studio.
  final VoidCallback? onStudio;

  /// L'ecran affiche.
  final Widget child;

  /// NAV-SOUS-LIENS (14/11/2026) : les pages de chaque domaine, montrees
  /// par le panneau sur tablette et ordinateur (`sousLiensAdmin`). Vide :
  /// aucun sous-lien, et les pages gardent leur sous-navigation.
  final Map<AdminDomaine, List<SousLien>> sousLiens;

  /// L'adresse de la page ouverte, pour allumer son sous-lien.
  final String? cheminCourant;

  /// MESSAGERIE-PLEIN-ECRAN : une conversation est ouverte ; au telephone
  /// (moins de 600), la coquille rend la page seule, la conversation porte sa
  /// propre barre.
  final bool conversationOuverte;

  /// Le nombre maximal de domaines. **Huit, pas quatre** : la regle du gel
  /// d'architecture, distincte de `NavShell.maxDestinations`.
  static const int maxDomaines = 8;

  /// Cles stables pour verifier les trois presentations adaptatives.
  static const Key tiroirKey = ValueKey<String>('admin-shell-tiroir');
  static const Key railKey = ValueKey<String>('admin-shell-rail');
  static const Key barreLateraleKey = ValueKey<String>(
    'admin-shell-barre-laterale',
  );

  /// Cle du bouton du panneau, a partir de 1200 (NAV-REFONTE etape 4).
  static const Key boutonPanneauKey = ValueKey<String>(
    'admin-shell-bouton-panneau',
  );

  /// Largeur de la barre laterale permanente.
  ///
  /// **Plus large que `AppGabarit.largeurBarreLaterale` (256)**, et
  /// volontairement independante de ce jeton partage par les quatre autres
  /// roles : leurs libelles tiennent en un mot (« Journee », « Profil »), les
  /// huit domaines admin comptent plusieurs libelles a deux ou trois mots
  /// (« Sécurité et audit », « Configuration »), qui debordent a 256. Poser
  /// ici une largeur propre a `AdminShell` evite d'elargir la barre des
  /// quatre autres roles pour un besoin qui n'est que le sien.
  static const double largeurBarreLaterale = 288;

  /// La place que le titre de la page garde a cote des actions de l'en-tete,
  /// en tailles de son texte (em, `headlineMedium` a l'echelle courante) :
  /// en dessous, les actions quittent la ligne du titre (COUPE-MOTS-FOND-1).
  static const double _emTitreMinimum = 10;

  // HALO 2a-bis (garde-cap, 11/11/2026) : l'arbitre des lumieres de la
  // direction, pose une seule fois ici, comme dans NavShell ; aucun ecran ne
  // le recopie.
  @override
  Widget build(BuildContext context) =>
      ArbitreLumieres(child: _construire(context));

  /// Le compte au pied de la colonne (NAV-REFONTE etape 4) : le meme pied
  /// que les roles ([PiedComptePanneau]), photo, nom et menu (Mon compte,
  /// theme, Se deconnecter).
  Widget _pied({required bool repliee}) => PiedComptePanneau(
    destination: Destination(
      libelle: t.nav.compte,
      icone: AppIcons.profil,
      chemin: Routes.compte,
      compte: true,
    ),
    actif: false,
    repliee: repliee,
    guide: false,
    onAller: (String _) => onCompte(),
    onDeconnexion: onDeconnexion,
  );

  Widget _construire(BuildContext context) {
    final int trouve = domaineActif == null
        ? -1
        : domaines.indexOf(domaineActif!);
    final int? actif = trouve == -1 ? null : trouve;

    final ChromeNavigation chrome = AppGabarit.de(context).chrome;
    if (conversationOuverte && chrome == ChromeNavigation.barreBasse) {
      return child;
    }

    // LOGO-APP : le logo d'en-tete ramene a l'Accueil admin.
    void accueil() {
      if (AdminDomaine.accueil.chemin case final String chemin) {
        onAller(chemin);
      }
    }

    void choisir(int index) {
      final String? chemin = domaines[index].chemin;
      // Un domaine inerte ne navigue nulle part : construire un ecran vide
      // pour l'occasion est exactement ce que l'audit interdit.
      if (chemin != null) {
        onAller(chemin);
      }
    }

    // Les actions de l'en-tete de page, a partir de 600 : Recherche, theme,
    // compte, dans cet ordre (maquette 02A).
    //
    // ALERTE-1b : le bandeau n'est plus rendu par `PageShell` (il etait dans
    // la tete, qui defile avec le corps, et sortait de la vue) ; il est pose
    // ici, au-dessus de la page, par [_ZoneBandeau], et reste en vue.
    // PAGESHELL-200-1e (decide par delegation le 09/10) : la tete de la page
    // (titre, onglets et, des 600, Recherche, theme, cloche, compte) reste
    // fixe sous le bandeau, qui la pousse sans la recouvrir. `PageShell` le
    // sait ([ActionsEnteteCoquille.sousBandeau]) : la presence du bandeau ne
    // fait jamais defiler la tete. Elle ne defile que si elle ne laisse plus
    // au corps une cible tactile (d'abord son complement, la chaine et les
    // filtres du Journal ; le titre et les onglets en dernier), dans une
    // fenetre de moins de 360 de haut, ou a texte agrandi (au-dela de 130 %
    // sur une page defilante, 200 % sur telephone : la page defile pour le
    // reste, PAGESHELL-200-1d). Le bandeau, lui, ne bouge jamais.
    // COM-F : Le Studio apres la Recherche, et la cloche des notifications
    // en dernier ; sous 600, cette cloche seule (la barre mobile garde
    // Menu, Recherche, alertes et compte).
    final VoidCallback? notifications = onNotifications;
    final VoidCallback? studio = onStudio;
    Widget contenu({required bool avecActions}) {
      final List<Widget> actions = <Widget>[
        if (avecActions) ...<Widget>[
          _BoutonRecherche(
            onRecherche: onAller,
            onRechercheMetier: onRechercheMetier,
            studio: studio != null,
          ),
          if (studio != null) _BoutonStudio(onStudio: studio),
          const BasculeTheme(),
          ?messages,
          ?cloche,
          // NAV-REFONTE etape 4 : le compte vit au pied de la colonne
          // (photo, nom, menu), il quitte l'en-tete, comme pour les roles.
        ],
        if (notifications != null)
          ClocheNotifications(
            onPress: notifications,
            actif: notificationsActives,
          ),
      ];
      Widget pageAvec(List<Widget> enTete) => ActionsEnteteCoquille(
        actions: enTete,
        onRetour: onRetour,
        sousBandeau: bandeau != null,
        child: child,
      );
      // COUPE-MOTS-FOND-1 : en Interface guidee (cibles de 72) ou dans une
      // colonne etroite (rail a 800), sept cibles a cote du titre ne lui
      // laissaient plus que deux lettres par ligne (« Diagnosti / cs »,
      // « Centre de commande » lettre a lettre). Quand elles ne laissent plus
      // au titre dix fois la taille de son texte, elles passent sur leur
      // propre rangee, au-dessus de la page, et le titre reprend la ligne.
      final Widget page = !avecActions
          ? pageAvec(actions)
          : LayoutBuilder(
              builder: (BuildContext contexte, BoxConstraints c) {
                final double cible = AppMetriques.of(contexte).cibleTactile;
                // La bascule de theme vaut deux cibles ; le retour, une.
                final double besoin =
                    (actions.length + 2) * (cible + AppSpacing.xs);
                final double em = MediaQuery.textScalerOf(contexte).scale(
                  Theme.of(contexte).textTheme.headlineMedium?.fontSize ??
                      AppSpacing.xxl,
                );
                if (c.maxWidth - besoin >= _emTitreMinimum * em) {
                  return pageAvec(actions);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _RangeeActions(actions: actions),
                    Expanded(
                      child: MediaQuery.removePadding(
                        context: contexte,
                        removeTop: true,
                        child: pageAvec(const <Widget>[]),
                      ),
                    ),
                  ],
                );
              },
            );
      return switch (bandeau) {
        null => page,
        final Widget b => _ZoneBandeau(
          bandeau: b,
          // Sous 600, la barre mobile tient deja le haut de l'ecran (et sa
          // marge de securite) : le bandeau se pose sous elle.
          sousBarre: chrome == ChromeNavigation.barreBasse,
          child: page,
        ),
      };
    }

    // **Un seul `Scaffold`, quel que soit le gabarit.** La barre mobile porte
    // un `TextField`, qui exige un ancetre `Material` ; le mobile a de toute
    // facon besoin d'un `Scaffold` pour son tiroir ouvrable.
    // FIL-ARIANE : la barre laterale (au telephone, le menu) est une sortie
    // visible ; `PageShell` n'y ajoute pas de disque retour de repli.
    // NAV-SOUS-LIENS : sur tablette et ordinateur, le panneau montre les
    // pages du domaine ouvert ; les pages le savent et ne repetent pas leur
    // sous-navigation (`SousLiensCoquille`). Au telephone, rien ne change.
    final bool avecSousLiens =
        sousLiens.isNotEmpty && chrome != ChromeNavigation.barreBasse;
    Widget pageCouverte() {
      final Widget page = contenu(avecActions: true);
      if (!avecSousLiens) return page;
      return SousLiensCoquille(
        chemins: <String>{
          for (final List<SousLien> liens in sousLiens.values)
            for (final SousLien lien in liens) lien.chemin,
        },
        child: page,
      );
    }

    return NavigationDeCoquille(
      child: Scaffold(
        // Telephone : le tiroir du bouton Menu. Tablette (600 a 1199) : le
        // panneau entier, ouvert par le bouton du rail, PAR-DESSUS la page
        // avec un voile (Material 3 « Modal navigation drawer » ; point 6 de
        // la revue, NAV-SOUS-LIENS) : la page garde sa largeur.
        drawer: switch (chrome) {
          ChromeNavigation.barreBasse => _Tiroir(
            domaines: domaines,
            indexActif: actif,
            onChoisir: choisir,
            onCompte: onCompte,
            onStudio: studio,
            onRechercheMetier: onRechercheMetier,
            onAccueil: accueil,
          ),
          ChromeNavigation.rail => _Tiroir(
            domaines: domaines,
            indexActif: actif,
            onChoisir: choisir,
            onCompte: onCompte,
            onAccueil: accueil,
            sousLiens: sousLiens,
            cheminCourant: cheminCourant,
            onAller: onAller,
            surTablette: true,
          ),
          ChromeNavigation.barreLaterale => null,
        },
        body: switch (chrome) {
          ChromeNavigation.barreBasse => Column(
            children: <Widget>[
              _BarreMobile(
                onRecherche: onAller,
                onCompte: onCompte,
                cloche: cloche,
                messages: messages,
                studio: studio != null,
              ),
              // La barre a deja pose la zone sure du haut (encoche, barre
              // d'etat) : la page en dessous ne la repose pas, sinon un vide
              // de la hauteur de l'encoche separe la barre du titre.
              // Lu SOUS le `Scaffold` (`Builder`) : celui-ci a deja retire du
              // corps l'encart du clavier ; relire celui du dessus le ferait
              // eviter deux fois.
              Expanded(
                child: Builder(
                  builder: (BuildContext corps) => MediaQuery.removePadding(
                    context: corps,
                    removeTop: true,
                    child: contenu(avecActions: false),
                  ),
                ),
              ),
            ],
          ),
          ChromeNavigation.rail => Row(
            children: <Widget>[
              // NAV-SOUS-LIENS (point 6) : sous 1200, le bouton du rail ouvre
              // le panneau par-dessus la page, avec un voile.
              Builder(
                builder: (BuildContext dansScaffold) => _Rail(
                  domaines: domaines,
                  indexActif: actif,
                  onChoisir: choisir,
                  onAccueil: accueil,
                  onBasculer: () => Scaffold.of(dansScaffold).openDrawer(),
                  sousLiens: sousLiens,
                  cheminCourant: cheminCourant,
                  onAller: onAller,
                  pied: _pied(repliee: true),
                ),
              ),
              Expanded(child: pageCouverte()),
            ],
          ),
          ChromeNavigation.barreLaterale => Row(
            children: <Widget>[
              // NAV-REFONTE etape 4 : a partir de 1200, le bouton du panneau,
              // toujours a la meme place ; le choix est garde par appareil
              // (`navigation.repliee`, partage avec les roles).
              Consumer(
                builder: (BuildContext _, WidgetRef ref, Widget? _) {
                  final bool repliee =
                      ref.watch(navigationReplieeProvider) ?? false;
                  void basculer() => ref
                      .read(navigationReplieeProvider.notifier)
                      .choisir(repliee: !repliee);
                  return repliee
                      ? _Rail(
                          domaines: domaines,
                          indexActif: actif,
                          onChoisir: choisir,
                          onAccueil: accueil,
                          onBasculer: basculer,
                          sousLiens: sousLiens,
                          cheminCourant: cheminCourant,
                          onAller: onAller,
                          pied: _pied(repliee: true),
                        )
                      : _Sidebar(
                          domaines: domaines,
                          indexActif: actif,
                          onChoisir: choisir,
                          onAccueil: accueil,
                          onBasculer: basculer,
                          sousLiens: sousLiens,
                          cheminCourant: cheminCourant,
                          onAller: onAller,
                          pied: _pied(repliee: false),
                        );
                },
              ),
              // Un panneau contextuel pourra prendre place a droite du contenu
              // le jour ou un ecran en aura besoin. Rien n'en a besoin
              // aujourd'hui : ce commentaire tient la place, pas un widget vide.
              Expanded(child: pageCouverte()),
            ],
          ),
        },
      ),
    );
  }
}

/// La zone du bandeau d'alerte urgente (ALERTE-1b) : le bandeau fige en
/// haut, la page dessous, dans la hauteur qui reste.
///
/// Le bandeau prend la gouttiere et la largeur bornee de la colonne de page
/// (`PageShell`), pour s'aligner sur le titre. Sa hauteur ne depasse jamais
/// la moitie de la vue : au-dela, il defile dans sa zone.
class _ZoneBandeau extends StatelessWidget {
  const _ZoneBandeau({
    required this.bandeau,
    required this.sousBarre,
    required this.child,
  });

  final Widget bandeau;
  final bool sousBarre;
  final Widget child;

  /// La part maximale de la hauteur que le bandeau occupe.
  static const double partMaximale = 0.5;

  @override
  Widget build(BuildContext context) {
    final double gouttiere = AppGabarit.de(context).gouttiere;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SafeArea(
            top: !sousBarre,
            bottom: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: contraintes.maxHeight * partMaximale,
              ),
              child: SingleChildScrollView(
                child: Align(
                  alignment: AlignmentDirectional.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppPage.largeurMaxContenu,
                    ),
                    child: Padding(
                      // Directionnel : en arabe, la gouttiere de debut est a
                      // droite. 8 sous le bandeau, avant la tete de la page.
                      padding: EdgeInsetsDirectional.only(
                        start: gouttiere,
                        end: gouttiere,
                        bottom: AppSpacing.sm,
                      ),
                      child: bandeau,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            // La marge de securite du haut est deja prise au-dessus du
            // bandeau : la page ne la reprend pas.
            child: MediaQuery.removePadding(
              context: context,
              removeTop: !sousBarre,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Les actions de l'en-tete sur leur propre rangee, au-dessus de la page,
/// au bord de fin (COUPE-MOTS-FOND-1) : quand elles ne laisseraient plus au
/// titre dix fois la taille de son texte. Meme ordre, memes composants ; la
/// rangee passe a la ligne plutot que de deborder.
class _RangeeActions extends StatelessWidget {
  const _RangeeActions({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final double gouttiere = AppGabarit.de(context).gouttiere;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: gouttiere,
          end: gouttiere,
          top: AppSpacing.lg,
        ),
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: actions,
        ),
      ),
    );
  }
}

/// La route que vise une saisie de recherche, ou nulle.
///
/// Une recherche de navigation, pas une recherche metier.
///
/// ponytail : correspondance simple, premiere sous-chaine trouvee dans une
/// liste fixe de moins de dix libelles. Pas de classement ni de tolerance aux
/// fautes de frappe -- une liste de cette taille n'en a pas besoin, et aucune
/// donnee n'est interrogee, seulement des libelles et leurs routes.
///
/// [studio] faux retire Le Studio des cibles quand il n'a pas de serveur
/// (PORTS-DIRECTION) : la recherche ne mene jamais a un « indisponible ».
String? _cheminRecherche(String saisie, {required bool studio}) {
  final String requete = saisie.trim().toLowerCase();
  if (requete.isEmpty) {
    return null;
  }
  for (final ({String libelle, String chemin}) cible in ciblesRechercheAdmin(
    voitDirection: false,
    studio: studio,
  )) {
    if (cible.libelle.toLowerCase().contains(requete)) {
      return cible.chemin;
    }
  }
  return null;
}

/// Une entree de navigation, libelle sur une seule ligne, jamais debordant.
///
/// Attenuee quand le domaine est inerte (aucune fonction livree) : ni gris de
/// bouton desactive, ni ecran vide derriere -- juste une encre plus discrete
/// pour dire « pas encore », comme un compteur d'`ADM-01` sans destination.
/// Retrait horizontal par defaut d'une tuile de NavigationDrawer.
const double _retraitTuileNav = 12;

/// Hauteur d'une ligne de labelMedium a 100 % (M3 : 16).
const double _hauteurLibelleNav = 16;

Widget _libelleEntree(
  AppPalette palette,
  AdminDomaine domaine, {
  int lignes = 1,
}) => Text(
  domaine.libelle,
  overflow: TextOverflow.ellipsis,
  maxLines: lignes,
  softWrap: lignes > 1,
  style: domaine.actif
      ? null
      : TextStyle(color: palette.inkFaint.asBorderSide().color),
);

Widget _iconeEntree(
  AppPalette palette,
  AdminDomaine domaine, {
  required bool selectionnee,
}) {
  final Color? couleur = domaine.actif
      ? null
      : palette.inkFaint.asBorderSide().color;
  return Icon(
    selectionnee ? domaine.icone.actif : domaine.icone.repos,
    color: couleur,
  );
}

/// L'info-bulle du rail : le libelle complet, au survol ou a l'appui long.
/// Hors semantique : le libelle de la destination l'annonce deja.
Widget _infoBulle(AdminDomaine domaine, Widget icone) =>
    Tooltip(message: domaine.libelle, excludeFromSemantics: true, child: icone);

/// La tete du tiroir et de la barre laterale : le logo horizontal (LOGO-APP,
/// README du logo : en-tete de navigation large), au debut de ligne, seul
/// logo de l'ecran et seul cliquable : il ramene a l'Accueil admin.
///
/// Le logo porte sa zone de protection (25 % de sa hauteur, 8) : les 8 de
/// retrait et les 16 au-dessus et au-dessous completent les 16 et 24 de
/// l'ancien mot-symbole.
class _TeteNavigation extends StatelessWidget {
  const _TeteNavigation({required this.onAccueil, this.onBasculer});

  final VoidCallback onAccueil;

  /// NAV-REFONTE etape 4 : le bouton du panneau, devant le logo, a la meme
  /// place que dans le rail replie. Nul dans le tiroir du telephone.
  final VoidCallback? onBasculer;

  @override
  Widget build(BuildContext context) {
    final Widget logo = BrandLogo(
      variante: VarianteLogo.horizontal,
      hauteur: AppSpacing.xxxl,
      onAccueil: onAccueil,
    );
    final VoidCallback? basculer = onBasculer;
    if (basculer == null) {
      return Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.lg,
        ),
        child: Align(alignment: AlignmentDirectional.centerStart, child: logo),
      );
    }
    // Le bouton a 16 du bord de debut et 12 du haut, comme replie.
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          BoutonPanneau(
            cleBouton: AdminShell.boutonPanneauKey,
            repliee: false,
            onBasculer: basculer,
          ),
          Ecart.hSm,
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: logo,
            ),
          ),
        ],
      ),
    );
  }
}

/// Le pied du tiroir et de la barre laterale : qui est connecte, et le
/// chemin vers « Mon compte ». La session ne porte pas de nom : le texte est
/// celui du role, cle existante (« Administrateur », initiale « A »). La
/// maquette 02A montre « AD · Admin » : ecart soumis au directeur (question
/// Q-S4 du concepteur), aucune cle creee sans son accord.
class _PiedUtilisateur extends StatelessWidget {
  const _PiedUtilisateur({required this.onCompte});

  final VoidCallback onCompte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String nom = t.compte.roles.admin;
    final String role = t.admin.comptes.roleAdmin;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: palette.borderHairline.asBorderSide()),
      ),
      child: Pressable(
        onPress: onCompte,
        libelleSemantique: '$nom, $role',
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            // AD-11 (1.4.4) : nom et role jamais coupes a 200 %, ils passent
            // a la ligne. AVATAR-1 : couple avatar + nom du composant partage.
            child: AvatarNom.enLigne(
              prenom: nom,
              role: role,
              styleNom: textes.titleSmall,
              styleRole: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Le tiroir mobile : les huit domaines, dans une vraie modale ouvrable.
class _Tiroir extends StatelessWidget {
  const _Tiroir({
    required this.domaines,
    required this.indexActif,
    required this.onChoisir,
    required this.onCompte,
    required this.onAccueil,
    this.onStudio,
    this.onRechercheMetier,
    this.sousLiens = const <AdminDomaine, List<SousLien>>{},
    this.cheminCourant,
    this.onAller,
    this.surTablette = false,
  });

  final List<AdminDomaine> domaines;
  final int? indexActif;
  final void Function(int index) onChoisir;
  final VoidCallback onCompte;
  final VoidCallback onAccueil;

  /// NAV-SOUS-LIENS : les pages des domaines (vide au telephone).
  final Map<AdminDomaine, List<SousLien>> sousLiens;

  /// L'adresse ouverte, pour allumer son sous-lien.
  final String? cheminCourant;

  /// Mene a un sous-lien.
  final void Function(String chemin)? onAller;

  /// Vrai quand le panneau s'ouvre par-dessus la page depuis le rail (600 a
  /// 1199) : le bouton du panneau le referme, a la meme place que dans le
  /// rail ; le compte reste au pied du rail.
  final bool surTablette;

  /// Ouvre Le Studio ; nul, aucun lien (COM-F).
  final VoidCallback? onStudio;

  /// Ouvre la recherche metier (RECH-D5) ; nul, aucun lien. Le champ de la
  /// barre mobile reste une recherche de navigation : la recherche metier
  /// s'ouvre d'ici, comme Le Studio.
  final VoidCallback? onRechercheMetier;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    // AD-11 (1.4.10) : l'indicateur M3 mesure 336 de large (tiroir de 360) ;
    // a 320 de large (1280 a 400 %), il deborderait de 40. Il suit donc la
    // largeur de la vue, retrait de tuile compris.
    final double largeurIndicateur =
        (MediaQuery.sizeOf(context).width - 2 * _retraitTuileNav)
            .clamp(0, 336)
            .toDouble();
    // AD-11 (1.4.4) : a 200 %, un libelle ne tient plus sur une ligne dans la
    // rangee M3 (non flexible) et la faisait deborder. Il passe a deux lignes
    // flexibles, et la tuile grandit d'autant : 2 lignes de 20 + 16 = 56 a
    // 100 %, soit la hauteur M3 inchangee.
    final double hauteurTuile = math.max(
      56,
      2 * MediaQuery.textScalerOf(context).scale(20) + 16,
    );

    return NavigationDrawerTheme(
      data: NavigationDrawerThemeData(
        tileHeight: hauteurTuile,
        indicatorSize: Size(largeurIndicateur, hauteurTuile),
        labelTextStyle: _stylesLibelleNav(context, palette),
        iconTheme: _stylesIconeNav(palette),
      ),
      child: NavigationDrawer(
        key: AdminShell.tiroirKey,
        selectedIndex: indexActif,
        backgroundColor: palette.surfaceRaised.background,
        indicatorColor: palette.washAccent.background,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.arrondiSm,
        ),
        onDestinationSelected: (int index) {
          Navigator.of(context).pop();
          onChoisir(index);
        },
        children: <Widget>[
          _TeteNavigation(
            onAccueil: () {
              Navigator.of(context).pop();
              onAccueil();
            },
            // Le bouton referme le panneau ouvert par-dessus la page ; il ne
            // touche pas au choix garde par appareil.
            onBasculer: surTablette ? () => Navigator.of(context).pop() : null,
          ),
          ..._entreesPanneau(
            domaines: domaines,
            indexActif: indexActif,
            sousLiens: sousLiens,
            cheminCourant: cheminCourant,
            onSousLien: (String chemin) {
              Navigator.of(context).pop();
              onAller?.call(chemin);
            },
            destination: (AdminDomaine domaine) => NavigationDrawerDestination(
              icon: _iconeEntree(palette, domaine, selectionnee: false),
              selectedIcon: _iconeEntree(palette, domaine, selectionnee: true),
              // Flexible : enfant direct de la rangee M3 (DefaultTextStyle
              // n'a pas d'objet de rendu).
              label: Flexible(
                child: _libelleEntree(palette, domaine, lignes: 2),
              ),
            ),
          ),
          Ecart.vLg,
          // Le Studio n'est pas un domaine (Q1) : un lien sous la liste,
          // jamais une neuvieme destination du tiroir.
          if (onStudio case final VoidCallback ouvrir)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.lg,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: LienFleche(
                  libelle: t.com.socle.navigation.studio,
                  libelleSemantique: t.com.socle.navigation.ouvrirStudio,
                  icone: AppIcons.studio,
                  onPress: () {
                    Navigator.of(context).pop();
                    ouvrir();
                  },
                ),
              ),
            ),
          if (onRechercheMetier case final VoidCallback ouvrir)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.lg,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: LienFleche(
                  libelle: t.recherche.initial.titre,
                  icone: AppIcons.recherche,
                  onPress: () {
                    Navigator.of(context).pop();
                    ouvrir();
                  },
                ),
              ),
            ),
          if (!surTablette)
            _PiedUtilisateur(
              onCompte: () {
                Navigator.of(context).pop();
                onCompte();
              },
            ),
        ],
      ),
    );
  }
}

/// Le rail replie, de 600 a 1199 (et a partir de 1200 quand le panneau est
/// replie) : icone seule, libelle en info-bulle et en semantique, symbole du
/// logo en tete, compte au pied.
///
/// **NAV-SOUS-LIENS (14/11/2026)** : un domaine qui a des pages ouvre leur
/// menu au clic (Windows « NavigationView » compact, Material 3 « Navigation
/// rail » + menu) : deux gestes vers n'importe quelle page, sans deplier le
/// panneau. Un domaine sans pages y mene directement. Le bouton du panneau,
/// en tete, l'ouvre en entier (par-dessus la page sous 1200).
///
/// Les libelles complets (« Opérations », « Configuration ») ne tiennent pas
/// en 80 : le rail n'affiche que l'icone, le libelle reste dans l'infobulle
/// et dans la voix du lecteur d'ecran.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.domaines,
    required this.indexActif,
    required this.onChoisir,
    required this.onAccueil,
    required this.pied,
    required this.onBasculer,
    required this.sousLiens,
    required this.cheminCourant,
    required this.onAller,
  });

  final List<AdminDomaine> domaines;
  final int? indexActif;
  final void Function(int index) onChoisir;
  final VoidCallback onAccueil;

  /// Le compte au pied du rail (photo seule, nom en infobulle).
  final Widget pied;

  /// Ouvre le panneau entier.
  final VoidCallback onBasculer;

  /// Les pages des domaines, ouvertes en menu.
  final Map<AdminDomaine, List<SousLien>> sousLiens;

  /// L'adresse ouverte, pour cocher sa page dans le menu.
  final String? cheminCourant;

  /// Mene a une page.
  final void Function(String chemin) onAller;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final List<Widget> entrees = <Widget>[];
    for (int i = 0; i < domaines.length; i++) {
      final AdminDomaine domaine = domaines[i];
      if (i > 0 && sectionDe(domaine) != sectionDe(domaines[i - 1])) {
        entrees.add(const _SeparationRail());
      }
      final bool selectionne = i == indexActif;
      final List<SousLien> pages = sousLiens[domaine] ?? const <SousLien>[];
      Widget pastille(EtatPression etat) => _infoBulle(
        domaine,
        _PastilleRail(
          domaine: domaine,
          selectionnee: selectionne,
          survolee: etat.survole || etat.presse,
          palette: palette,
        ),
      );
      if (domaine.actif && pages.isNotEmpty) {
        final SousLien? courant = sousLienCourant(pages, cheminCourant);
        entrees.add(
          MenuActions(
            libelle: t.nav.admin.sousLiens.pagesDe(domaine: domaine.libelle),
            actions: <EntreeAction>[
              for (final SousLien page in pages)
                EntreeAction(
                  libelle: page.libelle,
                  // La page ouverte se reconnait a son icone (jamais la
                  // couleur seule).
                  icone: page == courant ? AppIcons.pageOuverte : null,
                  onChoix: () => onAller(page.chemin),
                ),
            ],
            declencheur: (BuildContext _, EtatPression etat) => pastille(etat),
          ),
        );
      } else {
        entrees.add(
          Pressable.selon(
            // Un domaine inerte ne navigue pas (choisir l'ignore) : il
            // reste lisible et focalisable, jamais grise.
            onPress: () => onChoisir(i),
            libelleSemantique: domaine.libelle,
            selectionne: selectionne,
            arrondiFocus: AppRadius.arrondiSm,
            constructeur: (BuildContext _, EtatPression etat) => pastille(etat),
          ),
        );
      }
    }

    return SizedBox(
      key: AdminShell.railKey,
      width: AppGabarit.largeurRail,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: BorderDirectional(end: palette.borderHairline.asBorderSide()),
        ),
        child: ColoredBox(
          color: palette.surfaceRaised.background,
          child: SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: AppSpacing.lg,
                      ),
                      child: BoutonPanneau(
                        cleBouton: AdminShell.boutonPanneauKey,
                        repliee: true,
                        onBasculer: onBasculer,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        Ecart.vSm,
                        // LOGO-APP : en tete du rail, le symbole seul,
                        // cliquable vers l'Accueil.
                        BrandLogo(
                          variante: VarianteLogo.symbole,
                          hauteur: AppSpacing.xxxl,
                          onAccueil: onAccueil,
                        ),
                        Ecart.vSm,
                        ...entrees,
                      ],
                    ),
                  ),
                ),
                pied,
                Ecart.vSm,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// La pastille d'un domaine du rail : 56 sur 32 (Material 3 « Navigation
/// rail »), dans une rangee de la hauteur de la cible. Choisie : fond doux,
/// icone pleine a l'encre d'accent (jamais la couleur seule : l'icone change).
class _PastilleRail extends StatelessWidget {
  const _PastilleRail({
    required this.domaine,
    required this.selectionnee,
    required this.survolee,
    required this.palette,
  });

  final AdminDomaine domaine;
  final bool selectionnee;
  final bool survolee;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final double cible = AppMetriques.of(context).cibleTactile;
    final Color? fond = selectionnee
        ? palette.washAccent.background
        : survolee
        ? palette.surfaceSunken.background
        : null;
    final AppInkColor encre = !domaine.actif
        ? palette.inkFaint
        : selectionnee
        ? palette.inkAccent
        : palette.inkMuted;
    return SizedBox(
      width: AppGabarit.largeurRail,
      height: math.max(cible, AppSpacing.titreEcran + AppSpacing.sm),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fond,
            borderRadius: AppRadius.arrondiSm,
          ),
          child: SizedBox(
            width: AppSpacing.titreEcran + AppSpacing.sm,
            height: AppSpacing.xxxl,
            child: Center(
              child: IconTheme(
                data: encre.asIconTheme(size: AppSpacing.xxl),
                child: Icon(
                  selectionnee ? domaine.icone.actif : domaine.icone.repos,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Le passage d'une section a la suivante dans le rail : un filet court.
class _SeparationRail extends StatelessWidget {
  const _SeparationRail();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: SizedBox(
      width: AppSpacing.xxxl,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: AppPalette.of(context).borderHairline.asBorderSide(),
          ),
        ),
      ),
    ),
  );
}

/// NAV-SOUS-LIENS : les entrees du panneau (tiroir et barre laterale) : le
/// titre de chaque section, ses domaines, et sous le domaine ouvert ses
/// pages (Apple HIG « Sidebars » : groupes et elements deplies ; Stripe,
/// GitHub : la section ouverte montre ses pages). L'ordre des domaines ne
/// change pas, et `NavigationDrawer` compte toujours ses destinations dans
/// le meme ordre.
List<Widget> _entreesPanneau({
  required List<AdminDomaine> domaines,
  required int? indexActif,
  required Map<AdminDomaine, List<SousLien>> sousLiens,
  required String? cheminCourant,
  required void Function(String chemin) onSousLien,
  required Widget Function(AdminDomaine domaine) destination,
}) => <Widget>[
  for (int i = 0; i < domaines.length; i++) ...<Widget>[
    if (i == 0 || sectionDe(domaines[i]) != sectionDe(domaines[i - 1]))
      _TitreSection(section: sectionDe(domaines[i])),
    destination(domaines[i]),
    if (i == indexActif && (sousLiens[domaines[i]]?.isNotEmpty ?? false))
      _SousLiens(
        liens: sousLiens[domaines[i]]!,
        courant: sousLienCourant(sousLiens[domaines[i]]!, cheminCourant),
        onSousLien: onSousLien,
      ),
  ],
];

/// Le panneau deplie defile : l'entree qui recoit le focus du clavier est
/// amenee dans la vue (WCAG 2.4.11, focus jamais masque), meme quand Tab
/// revient au debut du panneau depuis la fin de la page.
class _VisibleAuFocus extends StatelessWidget {
  const _VisibleAuFocus({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onFocusChange: (bool focalise) {
      if (focalise) {
        unawaited(Scrollable.ensureVisible(context));
      }
    },
    child: child,
  );
}

/// Le titre d'une section du panneau : petit, en phrase, a l'encre douce
/// (jamais en capitales espacees), aligne sur les libelles des domaines.
class _TitreSection extends StatelessWidget {
  const _TitreSection({required this.section});

  final SectionAdmin section;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle base =
        Theme.of(context).textTheme.labelMedium ?? const TextStyle();
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: _retraitTuileNav + AppSpacing.lg,
        end: _retraitTuileNav + AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(section.libelle, style: palette.inkMuted.applyTo(base)),
      ),
    );
  }
}

/// Les pages du domaine ouvert, sous lui, en retrait sur la colonne de son
/// libelle. La page ouverte : fond doux, graisse et encre d'accent (trois
/// signaux, jamais la couleur seule), annoncee « selectionnee ».
class _SousLiens extends StatelessWidget {
  const _SousLiens({
    required this.liens,
    required this.courant,
    required this.onSousLien,
  });

  final List<SousLien> liens;
  final SousLien? courant;
  final void Function(String chemin) onSousLien;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double cible = AppMetriques.of(context).cibleTactile;
    final TextStyle base =
        Theme.of(context).textTheme.labelMedium ?? const TextStyle();
    final double retrait = MediaQuery.textScalerOf(context).scale(1) > 1.3
        ? AppSpacing.lg
        : AppSpacing.lg + AppSpacing.xxl + AppSpacing.md;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final SousLien lien in liens)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _retraitTuileNav),
              child: _VisibleAuFocus(
                child: Pressable.selon(
                  onPress: () => onSousLien(lien.chemin),
                  libelleSemantique: lien.libelle,
                  selectionne: lien == courant,
                  lien: true,
                  arrondiFocus: AppRadius.arrondiSm,
                  constructeur: (BuildContext _, EtatPression etat) {
                    final bool choisi = lien == courant;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: choisi
                            ? palette.washAccent.background
                            : etat.survole || etat.presse
                            ? palette.surfaceSunken.background
                            : null,
                        borderRadius: AppRadius.arrondiSm,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: cible),
                        child: Padding(
                          // Sur la colonne du libelle du domaine : 16, icone
                          // de 24, 12. Texte agrandi (au-dela de 130 %) : le
                          // retrait tombe a 16, pour qu'un mot long
                          // (« Communications ») tienne entier (WCAG 1.4.4).
                          padding: EdgeInsetsDirectional.only(
                            start: retrait,
                            end: AppSpacing.lg,
                            top: AppSpacing.sm,
                            bottom: AppSpacing.sm,
                          ),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: ExcludeSemantics(
                              // Jamais coupe (WCAG 1.4.4) : a 200 %, il passe
                              // a la ligne et la rangee grandit.
                              child: Text(
                                lien.libelle,
                                style: choisi
                                    ? AppTypography.graisse(
                                        palette.inkAccent.applyTo(base),
                                        FontWeight.w600,
                                      )
                                    : palette.inkStrong.applyTo(base),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// La barre laterale permanente, a partir de 1200 : mot-symbole, libelles
/// complets, pied utilisateur.
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.domaines,
    required this.indexActif,
    required this.onChoisir,
    required this.onAccueil,
    required this.onBasculer,
    required this.pied,
    required this.sousLiens,
    required this.cheminCourant,
    required this.onAller,
  });

  final List<AdminDomaine> domaines;
  final int? indexActif;
  final void Function(int index) onChoisir;
  final VoidCallback onAccueil;

  /// NAV-SOUS-LIENS : les pages des domaines, depliees sous le domaine
  /// ouvert.
  final Map<AdminDomaine, List<SousLien>> sousLiens;

  /// L'adresse ouverte, pour allumer son sous-lien.
  final String? cheminCourant;

  /// Mene a un sous-lien.
  final void Function(String chemin) onAller;

  /// Replie le panneau (le bouton, a la meme place que replie).
  final VoidCallback onBasculer;

  /// Le compte au pied : photo, nom, menu.
  final Widget pied;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double cible = AppMetriques.of(context).cibleTactile;
    // Deux lignes de libelle a l'echelle courante, jamais moins que la cible.
    final double hauteurTuile = math.max(
      cible,
      MediaQuery.textScalerOf(context).scale(_hauteurLibelleNav) * 2 +
          AppSpacing.md,
    );
    // Retraits du tiroir (12 de chaque cote), puis 16, icone, 12 (Flutter).
    const double largeurTuile =
        AdminShell.largeurBarreLaterale - _retraitTuileNav * 2;
    const double largeurLibelle =
        largeurTuile -
        AppSpacing.lg -
        AppSpacing.xxl -
        AppSpacing.md -
        AppSpacing.lg;

    return SizedBox(
      key: AdminShell.barreLateraleKey,
      width: AdminShell.largeurBarreLaterale,
      // NAV-SOUS-LIENS : le panneau deplie peut defiler ; Tab le parcourt
      // dans l'ordre de lecture des entrees, jamais selon leur position a
      // l'ecran (qui change quand il defile), puis passe a la page.
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surfaceRaised.background,
            border: BorderDirectional(
              end: palette.borderHairline.asBorderSide(),
            ),
          ),
          child: SafeArea(
            child: Material(
              color: palette.surfaceRaised.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: NavigationDrawerTheme(
                      data: NavigationDrawerThemeData(
                        // La tuile grandit avec le texte (200 %) : le libelle
                        // passe sur deux lignes au lieu de deborder.
                        tileHeight: hauteurTuile,
                        indicatorSize: Size(largeurTuile, hauteurTuile),
                        labelTextStyle: _stylesLibelleNav(context, palette),
                        iconTheme: _stylesIconeNav(palette),
                      ),
                      child: NavigationDrawer(
                        selectedIndex: indexActif,
                        backgroundColor: palette.surfaceRaised.background,
                        indicatorColor: palette.washAccent.background,
                        indicatorShape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.arrondiSm,
                        ),
                        onDestinationSelected: onChoisir,
                        children: <Widget>[
                          _VisibleAuFocus(
                            child: _TeteNavigation(
                              onAccueil: onAccueil,
                              onBasculer: onBasculer,
                            ),
                          ),
                          ..._entreesPanneau(
                            domaines: domaines,
                            indexActif: indexActif,
                            sousLiens: sousLiens,
                            cheminCourant: cheminCourant,
                            onSousLien: onAller,
                            destination: (AdminDomaine domaine) =>
                                NavigationDrawerDestination(
                                  icon: _iconeEntree(
                                    palette,
                                    domaine,
                                    selectionnee: false,
                                  ),
                                  selectedIcon: _iconeEntree(
                                    palette,
                                    domaine,
                                    selectionnee: true,
                                  ),
                                  // La rangee du tiroir ne borne pas son
                                  // libelle : largeur explicite, sinon il
                                  // deborde a 200 %.
                                  label: SizedBox(
                                    width: largeurLibelle,
                                    child: _libelleEntree(
                                      palette,
                                      domaine,
                                      lignes: 2,
                                    ),
                                  ),
                                ),
                          ),
                          Ecart.vLg,
                        ],
                      ),
                    ),
                  ),
                  pied,
                  Ecart.vSm,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

WidgetStateProperty<TextStyle?> _stylesLibelleNav(
  BuildContext context,
  AppPalette palette,
) {
  final TextStyle base =
      Theme.of(context).textTheme.labelMedium ?? const TextStyle();
  // L'etat actif ne passe pas par la couleur seule (spec section 20) : la
  // graisse le porte aussi, sur le fond discret `washAccent`.
  return WidgetStateProperty.resolveWith<TextStyle?>(
    (Set<WidgetState> states) => states.contains(WidgetState.selected)
        ? AppTypography.graisse(
            base.copyWith(color: palette.inkAccent.asBorderSide().color),
            FontWeight.w600,
          )
        : base.copyWith(color: palette.inkMuted.asBorderSide().color),
  );
}

WidgetStateProperty<IconThemeData?> _stylesIconeNav(AppPalette palette) {
  return WidgetStateProperty.resolveWith<IconThemeData?>(
    (Set<WidgetState> states) => states.contains(WidgetState.selected)
        ? palette.inkAccent.asIconTheme(size: AppSpacing.xxl)
        : palette.inkMuted.asIconTheme(size: AppSpacing.xxl),
  );
}

/// Un bouton icone de l'en-tete : cible de 48, meme anatomie que
/// `ClocheNotifications`.
class _BoutonIcone extends StatelessWidget {
  const _BoutonIcone({
    required this.icone,
    required this.libelle,
    required this.onPress,
  });

  final IconData icone;
  final String libelle;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Pressable(
      onPress: onPress,
      libelleSemantique: libelle,
      arrondiFocus: AppRadius.arrondiFull,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: AppTouchTarget.standard,
          child: Center(
            child: IconTheme(
              data: palette.inkMuted.asIconTheme(size: AppSpacing.xxl),
              child: Icon(icone),
            ),
          ),
        ),
      ),
    );
  }
}

/// « Le Studio » (QUESTIONS Q1) : une action de l'en-tete, jamais un
/// domaine. Icone et info-bulle « Le Studio », lue « Ouvrir Le Studio ».
class _BoutonStudio extends StatelessWidget {
  const _BoutonStudio({required this.onStudio});

  final VoidCallback onStudio;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: t.com.socle.navigation.studio,
    excludeFromSemantics: true,
    child: _BoutonIcone(
      icone: AppIcons.studio.repos,
      libelle: t.com.socle.navigation.ouvrirStudio,
      onPress: onStudio,
    ),
  );
}

/// « Mon compte », dans la barre du telephone : la deconnexion y est, donc
/// atteignable partout. A partir de 600, le compte vit au pied de la colonne
/// ([PiedComptePanneau], NAV-REFONTE etape 4).
class _BoutonCompte extends StatelessWidget {
  const _BoutonCompte({required this.onCompte});

  final VoidCallback onCompte;

  @override
  Widget build(BuildContext context) => _BoutonIcone(
    icone: AppIcons.profil.repos,
    libelle: t.nav.compte,
    onPress: onCompte,
  );
}

/// La recherche a partir de 600 : un bouton qui ouvre le champ existant dans
/// une feuille (Q-S2). Aucune largeur inventee dans l'en-tete.
class _BoutonRecherche extends StatelessWidget {
  const _BoutonRecherche({
    required this.onRecherche,
    required this.studio,
    this.onRechercheMetier,
  });

  final void Function(String chemin) onRecherche;

  /// Vrai quand Le Studio a un serveur, et peut donc etre une cible.
  final bool studio;

  /// RECH-D5 : le lien vers la recherche metier, quand un domaine est servi.
  final VoidCallback? onRechercheMetier;

  Future<void> _ouvrir(BuildContext context) async {
    bool metier = false;
    final String? chemin = await AppBottomSheet.ouvrir<String>(
      context,
      titre: t.nav.admin.recherche,
      constructeur: (BuildContext contexte) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            autofocus: true,
            onSubmitted: (String saisie) {
              final String? cible = _cheminRecherche(saisie, studio: studio);
              if (cible != null) {
                Navigator.of(contexte).pop(cible);
              }
            },
            decoration: InputDecoration(
              isDense: true,
              hintText: t.nav.admin.rechercheIndication,
              hintMaxLines: lignesTexteAide(t.nav.admin.rechercheIndication),
              prefixIcon: Icon(AppIcons.recherche.repos),
            ),
          ),
          if (onRechercheMetier != null) ...<Widget>[
            Ecart.vSm,
            LienFleche(
              libelle: t.recherche.initial.titre,
              alignerEnDebut: true,
              onPress: () {
                metier = true;
                Navigator.of(contexte).pop();
              },
            ),
          ],
        ],
      ),
    );
    if (metier) {
      onRechercheMetier?.call();
    } else if (chemin != null) {
      onRecherche(chemin);
    }
  }

  @override
  Widget build(BuildContext context) => _BoutonIcone(
    icone: AppIcons.recherche.repos,
    libelle: t.nav.admin.recherche,
    onPress: () => unawaited(_ouvrir(context)),
  );
}

/// La barre mobile, sous 600 : menu, recherche, compte.
///
/// **Rien d'autre n'y vit** : ni reglage, ni eleve, ni groupe, ni bouton
/// metier isole.
class _BarreMobile extends StatefulWidget {
  const _BarreMobile({
    required this.onRecherche,
    required this.onCompte,
    required this.studio,
    this.cloche,
    this.messages,
  });

  final void Function(String chemin) onRecherche;
  final VoidCallback onCompte;
  final Widget? cloche;

  /// L'acces aux Messages quand un message attend (MESSAGERIE-TEMPS-REEL).
  final Widget? messages;

  /// Vrai quand Le Studio a un serveur, et peut donc etre une cible.
  final bool studio;

  @override
  State<_BarreMobile> createState() => _BarreMobileState();
}

class _BarreMobileState extends State<_BarreMobile> {
  final TextEditingController _recherche = TextEditingController();

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  void _lancer(String saisie) {
    final String? chemin = _cheminRecherche(saisie, studio: widget.studio);
    if (chemin != null) {
      widget.onRecherche(chemin);
      _recherche.clear();
    }
  }

  /// La largeur sous laquelle le champ de recherche ne montre plus son
  /// indication entiere sur UNE ligne. ALERTE-1b (lecon 8) mesurait le mot
  /// le plus long (« Rec / her… ») ; COM-F-Q5 exige la ligne entiere (une
  /// bande de 6 px la passait a la ligne et doublait la barre). JONCTION-
  /// LIGNES-1 garde la regle la plus stricte, qui contient l'autre : ce que
  /// l'`InputDecorator` Material 3 reserve autour de l'indication (icone de
  /// tete, son ecart au texte, la marge de fin et l'ecart du contour).
  double _largeurChampUtile(BuildContext context) {
    final TextPainter indication = TextPainter(
      text: TextSpan(
        text: t.nav.admin.rechercheIndication,
        style: Theme.of(context).inputDecorationTheme.hintStyle,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final double largeur =
        indication.width +
        AppTouchTarget.standard +
        AppSpacing.xs +
        AppSpacing.lg +
        AppSpacing.xs;
    indication.dispose();
    return largeur;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surfaceRaised.background,
        border: Border(bottom: palette.borderHairline.asBorderSide()),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          // PAGESHELL-200-1e (decide par delegation le 09/10) : en Interface
          // guidee, menu, recherche, cloche et compte prennent chacun une
          // cible de 72 ; a 320 px, ils ne tiennent plus avec leurs ecarts de
          // 8 (24 de debordement). Les ecarts tombent alors : les cibles se
          // touchent, leurs icones restent espacees de plus de 48.
          child: LayoutBuilder(
            builder: (BuildContext _, BoxConstraints c) {
              final int boutons =
                  3 +
                  (widget.cloche == null ? 0 : 1) +
                  (widget.messages == null ? 0 : 1);
              final bool serre =
                  c.maxWidth <
                  boutons * AppMetriques.of(context).cibleTactile +
                      (boutons - 1) * AppSpacing.sm;
              return _rangee(serre ? const SizedBox.shrink() : Ecart.hSm);
            },
          ),
        ),
      ),
    );
  }

  /// Menu, recherche, cloche et compte, separes par [ecart].
  Widget _rangee(Widget ecart) => Builder(
    builder: (BuildContext context) {
      // AD-11 (1.4.4) : au-dela de 150 % de texte, le champ en ligne n'a
      // plus la place de montrer son indication entiere entre menu et
      // compte ; la barre prend alors le bouton qui ouvre le meme champ en
      // feuille (motif deja servi a partir de 600). Rendu inchange a 100 %.
      final bool texteAgrandi = MediaQuery.textScalerOf(context).scale(1) > 1.5;
      return Row(
        children: <Widget>[
          Builder(
            builder: (BuildContext contexte) => _BoutonIcone(
              icone: AppIcons.menu.repos,
              libelle: t.nav.admin.menu,
              onPress: () => Scaffold.of(contexte).openDrawer(),
            ),
          ),
          ecart,
          if (texteAgrandi) ...<Widget>[
            const Spacer(),
            _BoutonRecherche(
              onRecherche: widget.onRecherche,
              studio: widget.studio,
            ),
          ] else
            Expanded(
              // ALERTE-1b (lecon 8) : avec la cloche, le champ peut ne
              // plus avoir la place du mot le plus long de son
              // indication (« Rec / her… » en Interface guidee a 390,
              // a 320 en taille normale). Il cede alors la place au
              // bouton qui ouvre le meme champ en feuille.
              child: LayoutBuilder(
                builder: (BuildContext contexte, BoxConstraints c) =>
                    c.maxWidth < _largeurChampUtile(contexte)
                    ? Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: _BoutonRecherche(
                          onRecherche: widget.onRecherche,
                          studio: widget.studio,
                        ),
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppPage.largeurFormulaire,
                        ),
                        child: TextField(
                          controller: _recherche,
                          onSubmitted: _lancer,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: t.nav.admin.rechercheIndication,
                            // AD-11 (1.4.4) : a 200 %, l'indication passe
                            // a la ligne au lieu d'etre coupee.
                            hintMaxLines: lignesTexteAide(
                              t.nav.admin.rechercheIndication,
                            ),
                            prefixIcon: Icon(AppIcons.recherche.repos),
                          ),
                        ),
                      ),
              ),
            ),
          ecart,
          if (widget.messages case final Widget messages) ...<Widget>[
            messages,
            ecart,
          ],
          if (widget.cloche case final Widget cloche) ...<Widget>[
            cloche,
            ecart,
          ],
          _BoutonCompte(onCompte: widget.onCompte),
        ],
      );
    },
  );
}
