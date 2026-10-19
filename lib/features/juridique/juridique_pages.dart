import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/jour_du_mois.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/protection_enfants/responsable_protection.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../compte/carte_rubriques.dart';
import '../dossier/politique_controle.dart';
import 'textes_juridiques.dart';

/// Le retour d'une page juridique : la page precedente si elle existe (Compte,
/// connexion, liste), sinon la racine, que la garde envoie au bon endroit.
void _retour(BuildContext context) {
  final GoRouter routeur = GoRouter.of(context);
  if (routeur.canPop()) {
    routeur.pop();
  } else {
    routeur.go(Routes.racine);
  }
}

String _dateDuTexte() {
  final DateTime d = VersionsJuridiques.date;
  return t.compte.tuteur.dateLongue(
    jour: jourDuMois(d.day),
    mois: t.commun.dates.mois[d.month - 1],
    annee: d.year,
  );
}

/// La version et la date des textes, en une ligne.
String ligneVersionJuridique() => t.juridique.version(
  version: VersionsJuridiques.version,
  date: _dateDuTexte(),
);

/// Les six textes, en une carte a lignes fines. Utilisee par la page
/// `/juridique` et par les informations legales du Compte.
class ListeTextesJuridiques extends StatelessWidget {
  /// Cree la liste.
  const ListeTextesJuridiques({super.key});

  @override
  Widget build(BuildContext context) => GroupeReglages(
    lignes: <LigneRubrique>[
      for (final TexteJuridique x in TexteJuridique.values)
        LigneRubrique(
          icone: AppIcons.journal,
          libelle: x.titre,
          legende: x.resume,
          onPress: () => GoRouter.of(context).push(x.chemin),
        ),
    ],
  );
}

/// `/juridique` : la liste des textes, sans connexion.
class JuridiquePage extends StatelessWidget {
  /// Cree la page.
  const JuridiquePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return PageShell(
      titre: t.juridique.titre,
      onRetour: () => _retour(context),
      child: ColonneSousPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              t.juridique.intro,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
            Ecart.vSm,
            Text(
              ligneVersionJuridique(),
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
            Ecart.vLg,
            const ListeTextesJuridiques(),
          ],
        ),
      ),
    );
  }
}

/// `/juridique/<texte>` : un texte, avec sa version et sa date.
class TexteJuridiquePage extends ConsumerWidget {
  /// Cree la page d'un [texte].
  const TexteJuridiquePage({required this.texte, super.key, this.renseignes});

  /// Le texte a lire.
  final TexteJuridique texte;

  /// Les champs donnes par la direction (injectable pour les tests).
  final Map<ChampJuridique, String>? renseignes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    // Le responsable regle par la direction. Le texte ne l'attend pas et ne
    // montre aucune erreur : chargement, echec de lecture ou compte non
    // connecte, le defaut s'affiche.
    final ResponsableProtection? responsable = ref
        .watch(responsableProtectionProvider)
        .asData
        ?.value;
    final List<SectionPolitique> sections = sectionsJuridiques(
      texte,
      renseignes: renseignes,
      responsable: responsable,
    );
    return PageShell(
      titre: texte.titre,
      onRetour: () => _retour(context),
      child: ColonneSousPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(ligneVersionJuridique(), style: attenue),
            Ecart.vSm,
            Text(texte.intro, style: textes.bodyLarge),
            for (final SectionPolitique s in sections) ...<Widget>[
              Ecart.vXl,
              Semantics(
                header: true,
                child: Text(s.titre, style: textes.titleMedium),
              ),
              Ecart.vSm,
              for (int b = 0; b < s.blocs.length; b++) ...<Widget>[
                if (b > 0) Ecart.vMd,
                BlocTexteLegal(bloc: s.blocs[b]),
              ],
            ],
            Ecart.vXl,
          ],
        ),
      ),
    );
  }
}
