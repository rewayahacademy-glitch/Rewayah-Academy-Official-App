import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../admin/admin_domaine.dart';
import '../domain/enums.dart';
import '../i18n/strings.g.dart';
import '../session/session_state.dart';
import '../widgets/nav_shell.dart';
import 'etat_routeur_sur.dart';
import 'routes.dart';

/// FIL-ARIANE (directeur, 06/11/2026 : « impossible de sortir de cette page,
/// et c'est partout pareil sur ordinateur […] pour la file d'ariane c'est
/// maintenant ») : le fil d'Ariane se **calcule**, il ne s'ecrit pas page par
/// page. Ce fichier tient le calcul, pur et testable sans routeur ; le rendu
/// est `FilAriane` (`lib/core/widgets/fil_ariane.dart`), pose par `PageShell`.

/// Un segment du fil : un libelle, et le chemin ou il mene. Le dernier segment
/// (la page courante) n'a pas de chemin.
@immutable
class SegmentFil {
  /// Cree un segment.
  const SegmentFil({required this.libelle, this.chemin});

  /// Ce qui est lu.
  final String libelle;

  /// Ou le segment mene ; `null` : la page courante, qui ne se touche pas.
  final String? chemin;

  @override
  bool operator ==(Object other) =>
      other is SegmentFil && other.libelle == libelle && other.chemin == chemin;

  @override
  int get hashCode => Object.hash(libelle, chemin);

  @override
  String toString() => 'SegmentFil($libelle, $chemin)';
}

/// L'arbre des routes d'un role, lu pour le fil : son accueil, ses
/// destinations de premier niveau (la barre ou la colonne de sa coquille) et
/// les pages de second niveau qui ont un nom fixe (les onglets d'un domaine
/// de la direction). Construit par [planFilPour] depuis les listes qui
/// alimentent deja les coquilles : aucun libelle n'est ecrit deux fois.
@immutable
class PlanFil {
  /// Cree le plan.
  const PlanFil({
    required this.accueil,
    required this.racines,
    this.libelles = const <String, String>{},
    this.compte,
    this.apprendre,
  });

  /// L'accueil du role : le premier segment d'une page qui n'est sous aucune
  /// destination, et le repli du disque retour au telephone.
  final SegmentFil accueil;

  /// Les destinations de premier niveau : chemin vers libelle. Une page qui
  /// en est une n'a pas de fil (niveau 1).
  final Map<String, String> racines;

  /// Les autres pages nommees de l'arbre (chemin vers libelle).
  final Map<String, String> libelles;

  /// ESPACE-APPRENDRE (lot 5) : pour l'eleve, l'espace Apprendre, parent de la
  /// Bibliotheque et de la fiche d'un document (le fil dit « Apprendre >
  /// Bibliotheque > document », pas « Compte > ... »). `null` : les autres
  /// roles, qui gardent le Compte.
  final SegmentFil? apprendre;

  /// Le Compte du role (la ou vivent les reglages, la Bibliotheque, les
  /// donnees) : le parent d'une page `/compte...` ou de la Bibliotheque quand
  /// rien d'autre ne le dit. `null` : l'accueil.
  final String? compte;

  @override
  bool operator ==(Object other) =>
      other is PlanFil &&
      other.accueil == accueil &&
      other.compte == compte &&
      other.apprendre == apprendre &&
      mapEquals(other.racines, racines) &&
      mapEquals(other.libelles, libelles);

  @override
  int get hashCode => Object.hash(accueil, compte, racines.length);

  String? _libelle(String chemin) => racines[chemin] ?? libelles[chemin];

  SegmentFil _segment(String chemin) =>
      SegmentFil(libelle: _libelle(chemin)!, chemin: chemin);
}

/// Les pages dont le parent est le Compte du role quand ni l'adresse ni
/// l'ecran d'avant ne le disent (une adresse tapee, un lien profond).
bool _sousLeCompte(String chemin) =>
    chemin == Routes.compte ||
    chemin.startsWith('${Routes.compte}/') ||
    chemin == Routes.tcBibliotheque ||
    chemin.startsWith('${Routes.tcBibliotheque}/');

bool _sousLaBibliotheque(String chemin) =>
    chemin == Routes.tcBibliotheque ||
    chemin.startsWith('${Routes.tcBibliotheque}/');

/// Les segments qui precedent la page [chemin] (la page elle-meme exclue),
/// ou une liste vide quand la page est de niveau 1 (une destination, ou
/// l'accueil).
///
/// L'ordre de lecture de l'arbre :
/// 1. les **ancetres par l'adresse** : chaque prefixe de [chemin] qui est une
///    page nommee du plan (`/tuteur/foyer` pour `/tuteur/foyer/x/finances`) ;
/// 2. sinon, **l'ecran d'avant** ([precedent], lu sur la pile du routeur) :
///    une page poussee hors de toute coquille (la Bibliotheque ouverte depuis
///    le Compte) prend pour parent l'ecran d'ou elle vient ;
/// 3. sinon, le **parent logique** : le Compte pour les pages du compte et la
///    Bibliotheque, l'accueil pour le reste.
///
/// Le fil commence toujours par une destination de premier niveau : quand ce
/// qui precede n'en est pas une, l'accueil du role est pose devant. Une page
/// n'a donc jamais un fil vide hors du niveau 1 : il y a toujours une sortie.
List<SegmentFil> ancetresFil({
  required PlanFil plan,
  required String chemin,
  String? precedent,
}) {
  final String page = _sansRequete(chemin);
  if (page.isEmpty || plan.racines.containsKey(page)) {
    return const <SegmentFil>[];
  }
  if (page == plan.accueil.chemin) {
    return const <SegmentFil>[];
  }

  // Une destination est une racine : ce qui la precede dans l'adresse (le
  // `/tuteur` de l'Accueil devant `/tuteur/foyer`) n'est pas son parent.
  List<SegmentFil> rogner(List<SegmentFil> trouves) {
    final int racine = trouves.lastIndexWhere(
      (SegmentFil s) => plan.racines.containsKey(s.chemin),
    );
    return racine <= 0 ? trouves : trouves.sublist(racine);
  }

  List<SegmentFil> parAdresse(String cible) => rogner(<SegmentFil>[
    for (final String prefixe in _prefixes(cible))
      if (plan._libelle(prefixe) != null) plan._segment(prefixe),
  ]);

  List<SegmentFil> segments = parAdresse(page);
  // ESPACE-APPRENDRE : la Bibliotheque et la fiche d'un document de l'eleve
  // sont sous l'espace Apprendre, quel que soit l'ecran d'ou l'on vient.
  final SegmentFil? apprendre = plan.apprendre;
  if (apprendre != null && _sousLaBibliotheque(page)) {
    final String? biblio = plan._libelle(Routes.tcBibliotheque);
    return <SegmentFil>[
      apprendre,
      if (biblio != null && page != Routes.tcBibliotheque)
        SegmentFil(libelle: biblio, chemin: Routes.tcBibliotheque),
    ];
  }
  if (segments.isEmpty && precedent != null) {
    final String avant = _sansRequete(precedent);
    if (avant.isNotEmpty && avant != page && !_prefixes(avant).contains(page)) {
      segments = rogner(<SegmentFil>[
        ...parAdresse(avant),
        if (plan._libelle(avant) != null) plan._segment(avant),
      ]);
    }
  }
  if (segments.isEmpty) {
    final String? compte = plan.compte;
    if (compte != null &&
        compte != page &&
        _sousLeCompte(page) &&
        plan._libelle(compte) != null) {
      segments = <SegmentFil>[plan._segment(compte)];
    }
  }
  if (segments.isEmpty || !plan.racines.containsKey(segments.first.chemin)) {
    if (segments.isEmpty || segments.first.chemin != plan.accueil.chemin) {
      segments = <SegmentFil>[plan.accueil, ...segments];
    }
  }
  return <SegmentFil>[
    for (final SegmentFil s in segments)
      if (s.chemin != page) s,
  ];
}

/// Le fil complet d'une page : ses ancetres, puis la page elle-meme
/// ([titre], sans chemin). Vide au niveau 1.
List<SegmentFil> filAriane({
  required PlanFil plan,
  required String chemin,
  required String? titre,
  String? precedent,
}) {
  final List<SegmentFil> ancetres = ancetresFil(
    plan: plan,
    chemin: chemin,
    precedent: precedent,
  );
  if (ancetres.isEmpty) {
    return const <SegmentFil>[];
  }
  return <SegmentFil>[
    ...ancetres,
    if (titre != null && titre.isNotEmpty) SegmentFil(libelle: titre),
  ];
}

String _sansRequete(String chemin) {
  final int i = chemin.indexOf('?');
  final String sans = i == -1 ? chemin : chemin.substring(0, i);
  return sans.length > 1 && sans.endsWith('/')
      ? sans.substring(0, sans.length - 1)
      : sans;
}

/// Les prefixes propres de [chemin], du plus court au plus long
/// (`/a/b/c` : `/a`, `/a/b`).
List<String> _prefixes(String chemin) {
  final List<String> morceaux = chemin
      .split('/')
      .where((String m) => m.isNotEmpty)
      .toList();
  return <String>[
    for (int i = 1; i < morceaux.length; i++) '/${morceaux.take(i).join('/')}',
  ];
}

/// Le plan du role de [session], depuis les listes qui alimentent ses
/// coquilles (`destinationsPour`, `domainesAdmin` et les onglets de chaque
/// domaine). `null` sans role : un visiteur n'a pas de fil.
PlanFil? planFilPour(SessionState session) {
  final AppRole? role = session.role;
  if (role == null) {
    return null;
  }
  if (role == AppRole.admin) {
    final Map<String, String> racines = <String, String>{
      for (final AdminDomaine d in domainesAdmin(
        voitDirection: session.peutVoirDirection,
      ))
        if (d.chemin case final String chemin) chemin: d.libelle,
    };
    final Map<String, String> libelles = <String, String>{
      for (final ({String libelle, String chemin}) o
          in <({String libelle, String chemin})>[
            ...ongletsOperations(),
            ...ongletsPersonnes(),
            ...ongletsPedagogie(),
            ...ongletsFinance(),
            ...ongletsConfiguration(politiqueRevueKyc: true),
            ...ongletsSecurite(),
            ...ongletsCommunications(),
            ...ciblesRechercheAdmin(voitDirection: session.peutVoirDirection),
          ])
        if (!racines.containsKey(o.chemin)) o.chemin: o.libelle,
    };
    return PlanFil(
      accueil: SegmentFil(
        libelle: AdminDomaine.accueil.libelle,
        chemin: Routes.admin,
      ),
      racines: racines,
      libelles: libelles,
    );
  }
  final List<Destination> destinations = destinationsPour(
    role: role,
    mode: InterfaceMode.standard,
    eleveAdulte: role == AppRole.student && session.eleveAutonome,
  );
  if (destinations.isEmpty) {
    return null;
  }
  final Map<String, String> racines = <String, String>{
    for (final Destination d in destinations) d.chemin: d.libelle,
    // ESPACE-APPRENDRE (lot 5) : le lecteur du Coran vit dans la branche
    // Apprendre (la barre y allume Apprendre) ; il reste une page de premier
    // niveau, comme quand il etait lui-meme la destination : pas de fil.
    if (destinations.any((Destination d) => d.chemin == Routes.eleveApprendre))
      Routes.eleveCoran: destinations
          .firstWhere((Destination d) => d.chemin == Routes.eleveApprendre)
          .libelle,
  };
  final String? compte = <String>[
    Routes.tuteurCompte,
    Routes.enseignantProfil,
    Routes.compte,
  ].where(racines.containsKey).firstOrNull;
  final Destination? apprendre = destinations
      .where((Destination d) => d.chemin == Routes.eleveApprendre)
      .firstOrNull;
  return PlanFil(
    accueil: SegmentFil(
      libelle: destinations.first.libelle,
      chemin: destinations.first.chemin,
    ),
    racines: racines,
    // La Bibliotheque de l'eleve est celle d'Apprendre : son fil le dit.
    libelles: apprendre == null
        ? const <String, String>{}
        : <String, String>{
            Routes.tcBibliotheque: t.apprendre.sections.bibliotheque,
          },
    compte: compte,
    apprendre: apprendre == null
        ? null
        : SegmentFil(libelle: apprendre.libelle, chemin: apprendre.chemin),
  );
}

/// Le plan du role, pose une fois pour toute l'application (`RewayahApp`) et
/// lu par `PageShell`. Absent (un test qui monte une page seule, un
/// visiteur) : aucun fil, aucun repli de retour.
class ContexteFilAriane extends InheritedWidget {
  /// Pose le plan pour le sous-arbre.
  const ContexteFilAriane({
    required this.plan,
    required super.child,
    super.key,
  });

  /// Le plan du role, ou `null`.
  final PlanFil? plan;

  /// Le plan pose au-dessus de [context], ou `null`.
  static PlanFil? de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ContexteFilAriane>()?.plan;

  @override
  bool updateShouldNotify(ContexteFilAriane ancien) => plan != ancien.plan;
}

/// Ce que le routeur sait de la page de [context] : son chemin, et l'ecran
/// d'ou elle a ete poussee. `null` hors du routeur (une page montee seule).
({String chemin, String? precedent, bool peutRevenir})? positionDansLaPile(
  BuildContext context,
) {
  final GoRouter? routeur = GoRouter.maybeOf(context);
  if (routeur == null) {
    return null;
  }
  // CRASH-MON-ESPACE (12/11/2026) : une page poussee hors du routeur
  // (`Navigator.push` d'une `MaterialPageRoute`, les sous-pages du Compte de
  // l'enseignant) n'a pas de `Page` dans ses reglages. `GoRouterState.of`
  // (go_router 18.0.1, state.dart:139) remonte alors au navigateur de la
  // coquille, dont la page n'a pas d'etat associe, puis
  // `Navigator.maybeOf(contexte du navigateur)` lui rend le MEME navigateur :
  // la boucle `while (true)` ne finit jamais, rien n'est leve, et
  // l'application gele (en production : « tout plante »). Une telle page n'a
  // pas de place dans la pile du routeur : pas de fil.
  if (ModalRoute.of(context)?.settings is! Page<Object?>) {
    return null;
  }
  // GOROUTERSTATE-SUR : la lecture sure, seule permise (page du routeur ici,
  // donc trouvee au premier tour).
  final GoRouterState? etat = etatRouteurSur(context);
  if (etat == null) {
    return null;
  }
  final String chemin = etat.uri.path;
  // Les ecrans de la pile, du bas vers le haut : la page la plus profonde de
  // la configuration de base, puis chaque page poussee (`push`).
  final List<String> ecrans = <String>[];
  String? base;
  void parcourir(List<RouteMatchBase> correspondances) {
    for (final RouteMatchBase m in correspondances) {
      if (m is ImperativeRouteMatch) {
        if (base != null) {
          ecrans.add(base!);
          base = null;
        }
        ecrans.add(m.matches.uri.path);
      } else if (m is ShellRouteMatch) {
        parcourir(m.matches);
      } else if (ecrans.isEmpty) {
        base = m.matchedLocation;
      }
    }
  }

  try {
    parcourir(routeur.routerDelegate.currentConfiguration.matches);
  } on Object {
    return (chemin: chemin, precedent: null, peutRevenir: false);
  }
  if (base != null) {
    ecrans.add(base!);
  }
  final int i = ecrans.lastIndexOf(chemin);
  return (
    chemin: chemin,
    precedent: i > 0 ? ecrans[i - 1] : null,
    peutRevenir: i > 0,
  );
}
