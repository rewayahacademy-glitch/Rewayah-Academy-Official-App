// L'entree en classe en demonstration : /demo/classe (hors production, CL-4.2).
//
// Sans parametre : les liens role x etat. Avec `role` et `etat` : un
// recapitulatif texte de l'emplacement d'entree, que CL-4.3 remplacera par les
// ecrans. EspaceGroupePage et FicheGroupePage ne sont pas reutilises ici : ils
// lisent des ports reseau (groupes, travail, reseau, roster Supabase) qu'il
// faudrait tous surcharger, et leur rendu ignore encore EmplacementEntree.
// Aucun appel serveur (consigne K-28).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/tc_horloge/emplacement_entree.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import 'classe_demo.dart';
import 'mode_demonstration.dart';

/// Les routes de la demonstration de l'entree : AUCUNE en production.
List<RouteBase> routesDemoClasse(String environnement) {
  if (!environnementAutoriseDemo(environnement)) return const <RouteBase>[];
  return <RouteBase>[
    GoRoute(
      path: Routes.demoClasse,
      builder: (BuildContext _, GoRouterState etat) => DemoClassePage(
        role: _lire(RoleEntree.values, etat.uri.queryParameters['role']),
        etat: _lire(EtatDemoClasse.values, etat.uri.queryParameters['etat']),
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

/// L'adresse d'une situation de la demonstration.
String adresseDemoClasse(RoleEntree role, EtatDemoClasse etat) => Uri(
  path: Routes.demoClasse,
  queryParameters: <String, String>{'role': role.name, 'etat': etat.name},
).toString();

/// Les situations proposees a un role. Le hors-ligne et l'illisible sont
/// communs ; aucune situation n'est propre a un seul role a ce stade.
List<EtatDemoClasse> etatsDemoClasse(RoleEntree role) => EtatDemoClasse.values;

/// Le libelle d'un role.
String libelleRoleEntree(RoleEntree role) => switch (role) {
  RoleEntree.eleve => t.classe.entree.demo.roles.eleve,
  RoleEntree.eleveGuide => t.classe.entree.demo.roles.guidee,
  RoleEntree.enseignant => t.classe.entree.demo.roles.enseignant,
};

/// Le libelle d'une situation.
String libelleEtatDemoClasse(EtatDemoClasse etat) => switch (etat) {
  EtatDemoClasse.aVenir => t.classe.entree.demo.etats.aVenir,
  EtatDemoClasse.fenetreOuverte => t.classe.entree.demo.etats.fenetreOuverte,
  EtatDemoClasse.preparation => t.classe.entree.demo.etats.preparation,
  EtatDemoClasse.attente => t.classe.entree.demo.etats.attente,
  EtatDemoClasse.enDirect => t.classe.entree.demo.etats.enDirect,
  EtatDemoClasse.tempsEcoule => t.classe.entree.demo.etats.tempsEcoule,
  EtatDemoClasse.terminee => t.classe.entree.demo.etats.terminee,
  EtatDemoClasse.annulee => t.classe.entree.demo.etats.annulee,
  EtatDemoClasse.horsLigne => t.classe.entree.demo.etats.horsLigne,
  EtatDemoClasse.indisponible => t.classe.entree.demo.etats.indisponible,
  EtatDemoClasse.changementHeure => t.classe.entree.demo.etats.changementHeure,
};

/// La page : la liste, ou le recapitulatif si [role] et [etat] sont donnes.
class DemoClassePage extends StatelessWidget {
  /// Cree la page.
  const DemoClassePage({this.role, this.etat, super.key});

  /// Le role choisi.
  final RoleEntree? role;

  /// La situation choisie.
  final EtatDemoClasse? etat;

  @override
  Widget build(BuildContext context) {
    final RoleEntree? r = role;
    final EtatDemoClasse? e = etat;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    Text texte(String valeur, {bool fort = false}) => Text(
      valeur,
      style: (fort ? palette.inkStrong : palette.inkMuted).applyTo(
        (fort ? textes.titleMedium : textes.bodyMedium) ?? const TextStyle(),
      ),
    );

    if (r == null || e == null) {
      return PageShell(
        titre: t.classe.entree.demo.titre,
        sousTitre: t.classe.entree.demo.mention,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            texte(t.classe.entree.demo.intro),
            for (final RoleEntree role in RoleEntree.values) ...<Widget>[
              Ecart.vXxl,
              Semantics(
                header: true,
                child: texte(libelleRoleEntree(role), fort: true),
              ),
              Ecart.vMd,
              for (final EtatDemoClasse etat in etatsDemoClasse(role))
                LienFleche(
                  key: ValueKey<String>('lien-${role.name}-${etat.name}'),
                  libelle: libelleEtatDemoClasse(etat),
                  onPress: () => context.go(adresseDemoClasse(role, etat)),
                ),
            ],
          ],
        ),
      );
    }

    final EmplacementEntree emplacement = DonneesClasseDemo.emplacement(r, e);
    return PageShell(
      titre: DonneesClasseDemo.classe,
      sousTitre: t.classe.entree.demo.mention,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          texte(
            '${libelleRoleEntree(r)} · ${libelleEtatDemoClasse(e)}',
            fort: true,
          ),
          Ecart.vLg,
          if (emplacement.avisDst != null) ...<Widget>[
            texte(emplacement.avisDst!),
            Ecart.vMd,
          ],
          texte(emplacement.libelle, fort: true),
          Ecart.vSm,
          texte(
            emplacement.estBouton
                ? t.classe.entree.demo.formeBouton
                : t.classe.entree.demo.formeLigne,
          ),
          if (emplacement.libelleLecteur != null)
            texte(
              t.classe.entree.demo.lecteur(texte: emplacement.libelleLecteur!),
            ),
          if (emplacement.detail != null)
            texte(t.classe.entree.demo.detail(texte: emplacement.detail!)),
          if (emplacement.reessayer) texte(t.classe.entree.reessayer),
          texte(t.classe.entree.demo.annonce(texte: emplacement.annonce)),
          Ecart.vXxl,
          LienFleche(
            libelle: t.classe.entree.demo.retour,
            onPress: () => context.go(Routes.demoClasse),
          ),
        ],
      ),
    );
  }
}
