// L1 des listes (01/11/2026) : la liste des classes de la direction et la
// fiche-page d'une classe, empilee au-dessus (meme forme que le routeur de
// l'application), pour les tests qui ouvrent une classe.

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/port_classes_admin.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/admin_groupes/groupes_page.dart';

/// La liste des classes, et la fiche d'une classe en route enfant.
List<RouteBase> routesClassesAdmin() => <RouteBase>[
  GoRoute(
    path: Routes.adminOperationsGroupes,
    builder: (BuildContext _, GoRouterState _) => const GroupesPage(),
    routes: <RouteBase>[
      GoRoute(
        path: ':groupeId',
        builder: (BuildContext _, GoRouterState etat) => FicheClasseAdminPage(
          groupeId: etat.pathParameters['groupeId']!,
          classe: etat.extra as ClasseListee?,
        ),
      ),
    ],
  ),
];
