import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../i18n/strings.g.dart';
import '../theme/app_spacing.dart';
import '../widgets/etat_systeme.dart';
import '../widgets/page_shell.dart';
import 'routes.dart';

/// Une page entiere qui ne dit qu'un etat systeme (contrat K5, portee page).
///
/// Elle sert les ecrans transverses du routeur (page introuvable, acces
/// refuse, hors ligne au demarrage) et les ecrans de lot pas encore livres
/// (les `STUB PHASE 0`). Elle passe par [PageShell] : bandeau hors ligne,
/// gouttiere, zone sure, et, dans la coquille du tuteur, sa cloche.
///
/// **L'action par defaut ramene a la racine** (`/`), que la redirection
/// renvoie ensuite a la bonne porte : l'accueil du role, la connexion,
/// l'inscription ou le portail d'attente. Aucune page d'etat n'est donc une
/// impasse, meme sans barre de navigation.
class PageEtat extends StatelessWidget {
  /// Cree la page.
  const PageEtat({
    required this.nature,
    super.key,
    this.titre,
    this.phrase,
    this.libelleAction,
    this.onAction,
    this.actionEnCours = false,
    this.libelleSecondaire,
    this.onSecondaire,
    this.dependance,
  });

  /// La nature de l'etat.
  final NatureEtat nature;

  /// Le titre, s'il doit etre plus precis que celui de la nature.
  final String? titre;

  /// La phrase, si elle doit etre plus precise que celle de la nature.
  final String? phrase;

  /// Le libelle de l'action ; par defaut « Retour a l'accueil ».
  final String? libelleAction;

  /// L'action ; par defaut, un `go` vers la racine.
  final VoidCallback? onAction;

  /// Vrai pendant que l'action aboutit.
  final bool actionEnCours;

  /// Le libelle du lien secondaire.
  final String? libelleSecondaire;

  /// Le lien secondaire. Sans lui, aucun lien n'est rendu.
  final VoidCallback? onSecondaire;

  /// Ce qui manque (`DB-xxx`, `LOT-x`), pour la trace et les tests : jamais
  /// affiche.
  final String? dependance;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxl),
        child: EtatSysteme(
          nature: nature,
          portee: PorteeEtat.page,
          titre: titre,
          phrase: phrase,
          libelleAction: libelleAction ?? t.commun.etats.actions.retourAccueil,
          onAction: onAction ?? () => GoRouter.of(context).go(Routes.racine),
          actionEnCours: actionEnCours,
          libelleSecondaire: libelleSecondaire,
          onSecondaire: onSecondaire,
          dependance: dependance,
        ),
      ),
    );
  }
}
