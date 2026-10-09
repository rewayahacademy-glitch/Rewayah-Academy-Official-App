// Les Communications en demonstration : /demo/communications (hors
// production, COM-F).
//
// Sans parametre : un lien par voie (Messages, Vocal, Communaute, Le Studio,
// Annonces). Avec `voie=...` (et `role=...`, lu par la voie) : l'ecran de
// demonstration de la voie, qui vit dans son propre fichier
// (`com_*_demo.dart`) et que seule la voie remplit (`02_DECOUPAGE`, regle
// des fichiers 1). Le socle ne sait rien de ce qu'une voie montre.
//
// **Jamais en production** : la route n'est enregistree que si
// `environnementAutoriseDemo` l'autorise (DEMO-ENV-1, lecon 14), et aucune
// voie ne branche de port reel ici (K-28).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/strings.g.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/page_shell.dart';
import '../mode_demonstration.dart';
import 'com_annonces_demo.dart';
import 'com_communaute_demo.dart';
import 'com_messages_demo.dart';
import 'com_studio_demo.dart';
import 'com_vocal_demo.dart';

/// Les cinq voies des Communications, dans l'ordre du decoupage.
enum VoieDemoCommunications {
  /// Messages metier (COM-MSG).
  messages,

  /// Message vocal (COM-VOC).
  vocal,

  /// Communaute enseignants (COM-COMU).
  communaute,

  /// Le Studio (COM-STU).
  studio,

  /// Annonces et notifications (COM-ANN).
  annonces,
}

/// Le role que la demonstration d'une voie met en scene (`?role=`). Un
/// choix d'affichage de la demonstration, jamais un role de session : le
/// role reel reste celui du jeton.
enum RoleDemoCommunications {
  /// La famille.
  tuteur,

  /// L'enseignant.
  enseignant,

  /// L'eleve adulte.
  adulte,

  /// La direction.
  admin,

  /// Le controleur.
  controleur,
}

/// Les routes de la demonstration des Communications : aucune hors
/// d'un environnement qui autorise la demonstration.
List<RouteBase> routesDemoCommunications(String environnement) {
  if (!environnementAutoriseDemo(environnement)) return const <RouteBase>[];
  return <RouteBase>[
    GoRoute(
      path: Routes.demoCommunications,
      builder: (BuildContext _, GoRouterState etat) => DemoCommunicationsPage(
        voie: _lire(
          VoieDemoCommunications.values,
          etat.uri.queryParameters['voie'],
        ),
        role: _lire(
          RoleDemoCommunications.values,
          etat.uri.queryParameters['role'],
        ),
      ),
    ),
  ];
}

T? _lire<T extends Enum>(List<T> valeurs, String? nom) {
  for (final T v in valeurs) {
    if (v.name == nom) return v;
  }
  return null;
}

/// L'adresse de la demonstration d'une voie.
String adresseDemoCommunications(
  VoieDemoCommunications voie, {
  RoleDemoCommunications? role,
}) => Uri(
  path: Routes.demoCommunications,
  queryParameters: <String, String>{'voie': voie.name, 'role': ?role?.name},
).toString();

/// Le libelle d'une voie : le titre de son sous-bloc i18n.
String libelleVoieDemoCommunications(VoieDemoCommunications voie) =>
    switch (voie) {
      VoieDemoCommunications.messages => t.com.messages.titre,
      VoieDemoCommunications.vocal => t.com.vocal.titre,
      VoieDemoCommunications.communaute => t.com.communaute.titre,
      VoieDemoCommunications.studio => t.com.studio.titre,
      VoieDemoCommunications.annonces => t.com.annonces.titre,
    };

/// La demonstration des Communications : l'index des voies, ou l'ecran de
/// demonstration d'une voie.
class DemoCommunicationsPage extends StatelessWidget {
  /// Cree la page.
  const DemoCommunicationsPage({super.key, this.voie, this.role});

  /// La voie montree ; nulle, l'index.
  final VoieDemoCommunications? voie;

  /// Le role mis en scene, lu par la voie.
  final RoleDemoCommunications? role;

  @override
  Widget build(BuildContext context) {
    final RoleDemoCommunications? r = role;
    switch (voie) {
      case VoieDemoCommunications.messages:
        return ComMessagesDemo(role: r);
      case VoieDemoCommunications.vocal:
        return ComVocalDemo(role: r);
      case VoieDemoCommunications.communaute:
        return ComCommunauteDemo(role: r);
      case VoieDemoCommunications.studio:
        return ComStudioDemo(role: r);
      case VoieDemoCommunications.annonces:
        return ComAnnoncesDemo(role: r);
      case null:
        break;
    }

    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final demo = t.com.socle.navigation.demo;
    return PageShell(
      titre: demo.titre,
      sousTitre: demo.detail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            demo.choisir,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
          for (final VoieDemoCommunications v in VoieDemoCommunications.values)
            LienFleche(
              key: ValueKey<String>('lien-voie-${v.name}'),
              libelle: libelleVoieDemoCommunications(v),
              onPress: () =>
                  GoRouter.of(context).go(adresseDemoCommunications(v)),
            ),
        ],
      ),
    );
  }
}

/// L'ecran d'une voie qui n'a pas encore rempli sa demonstration : son
/// titre, « Bientot disponible », et le retour a l'index. Chaque voie le
/// remplace dans son propre fichier `com_*_demo.dart`.
class VoieDemoProvisoire extends StatelessWidget {
  /// Cree l'ecran de la voie [voie].
  const VoieDemoProvisoire({required this.voie, super.key});

  /// La voie concernee.
  final VoieDemoCommunications voie;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: libelleVoieDemoCommunications(voie),
      sousTitre: t.com.socle.navigation.demo.detail,
      onRetour: () => GoRouter.of(context).go(Routes.demoCommunications),
      child: EtatSysteme(
        nature: NatureEtat.indisponible,
        titre: t.com.socle.navigation.bientot,
        phrase: t.com.socle.composants.etats.indisponible,
      ),
    );
  }
}
