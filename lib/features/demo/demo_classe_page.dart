// L'entree en classe en demonstration : /demo/classe (hors production, CL-4.2).
//
// Sans parametre : les liens role x etat. Avec `role` et `etat` :
// - eleve (CL-4.3) : le VRAI EspaceGroupePage, ses providers surcharges par un
//   ProviderScope sur les donnees de classe_demo.dart (aucun port reseau
//   modifie) ;
// - enseignant et Interface guidee : un recapitulatif texte de l'emplacement
//   d'entree (l'enseignant passe en CL-4.4).
// Aucun appel serveur (consigne K-28).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/tc_bibliotheque/catalogue_local.dart';
import '../../core/tc_bibliotheque/donnees_catalogue.dart';
import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/tc_groupe/port_groupes.dart';
import '../../core/tc_horloge/emplacement_entree.dart';
import '../../core/tc_horloge/port_horloge_seance.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/tc_parcours/port_travail_a_venir.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../tc_espace_groupe/emplacements_groupe.dart';
import '../tc_espace_groupe/espace_groupe_page.dart';
import 'classe_demo.dart';
import 'mode_demonstration.dart';
import 'repere_demonstration.dart';

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

    // CL-4.3 : l'eleve voit le VRAI ecran. L'enseignant garde son
    // recapitulatif jusqu'a CL-4.4 ; l'Interface guidee rejoint depuis son
    // Accueil (spec 2.2), l'Espace Classe n'est pas son chemin.
    if (r == RoleEntree.eleve) return EcranEleveDemo(etat: e);

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

/// Les surcharges de la page eleve pour une situation : aucun port reseau
/// n'est modifie, seuls les providers lus par la page sont remplaces.
List<Override> surchargesEleveDemo(
  EtatDemoClasse etat, {
  PortTravailAVenir travail = const TravailAVenirDemo(),
}) {
  const String id = DonneesClasseDemo.groupeId;
  return <Override>[
    groupeProvider(id)
        .overrideWith((Ref _) async => DonneesClasseDemo.groupe(etat)),
    horlogeGroupeProvider(id).overrideWith(
      (Ref _) => etat == EtatDemoClasse.indisponible
          ? Stream<SessionClockVM>.error(StateError('demonstration'))
          : Stream<SessionClockVM>.value(DonneesClasseDemo.horloge(etat)),
    ),
    horsLigneProvider.overrideWith(
      (Ref _) => Stream<bool>.value(etat == EtatDemoClasse.horsLigne),
    ),
    seanceAnnuleeProvider(id)
        .overrideWith((Ref _) => etat == EtatDemoClasse.annulee),
    progressionGroupeProvider(id)
        .overrideWith((Ref _) => DonneesClasseDemo.progression),
    portTravailAVenirProvider.overrideWithValue(travail),
    // Surcharge aussi la famille : sous un ProviderScope imbrique, elle se
    // resoudrait sinon dans le conteneur racine, ou le port vaut `null`.
    travailAVenirProvider((groupeId: id, studentId: null))
        .overrideWith((Ref _) => travail.avantProchainCours(groupeId: id)),
    portCatalogueProvider.overrideWithValue(
      CatalogueLocal(
        ressources: DonneesClasseDemo.supports,
        assignationsParGroupe: <String, List<String>>{
          id: <String>[
            for (final LibraryResource r in DonneesClasseDemo.supports) r.id,
          ],
        },
      ),
    ),
  ];
}

/// Le VRAI Espace Classe eleve (`EspaceGroupePage`) sur les donnees de
/// demonstration d'une situation (CL-4.3).
class EcranEleveDemo extends StatelessWidget {
  /// Cree l'ecran.
  const EcranEleveDemo({required this.etat, super.key});

  /// La situation.
  final EtatDemoClasse etat;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: ValueKey<EtatDemoClasse>(etat),
      overrides: surchargesEleveDemo(etat),
      child: RepereDemonstration(
        child: EspaceGroupePage(
          groupeId: DonneesClasseDemo.groupeId,
          onRejoindre: (_) {},
        ),
      ),
    );
  }
}
