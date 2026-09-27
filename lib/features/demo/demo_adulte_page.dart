// La coquille de l'eleve adulte en demonstration : /demo/adulte (hors
// production, EA-1b).
//
// Sans parametre : les liens vers les ecrans, les situations et les variantes.
// Avec `ecran` (accueil, maClasse, coran, monEspace, forfaitFamille,
// maFamille), `etat` (un des 25 cas du doc section 18), `titulaire=femme` et
// `vue=conjoint` : la VRAIE coquille (`NavShell`) a quatre destinations,
// Accueil, Ma classe, Coran, Mon espace (UX_REVIEW_07 ligne 1, choix
// provisoire Q2 : deux coquilles). « Ma famille » ouvre la coquille du tuteur
// existante sur le VRAI Foyer (F20), jamais une cinquieme destination.
//
// Aucun role serveur n'est change : la demonstration choisit la coquille, le
// role reel reste lu du jeton. Aucun appel serveur (K-28).
//
// L'Accueil (EA-2), Ma classe (EA-3) et Mon espace (EA-4) sont les vrais
// ecrans ; chaque rubrique de Mon espace ouvre la vraie sous-page du Compte
// (informations, paiements, securite, preferences et apparence, aide,
// informations legales), avec un retour vers Mon espace ; « Mes accords » et
// « Cours et acces », sans source, disent qu'ils sont indisponibles. Coran et
// Forfait famille restent PROVISOIRES (Forfait famille : EA-8 et EA-11).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../core/appairage/service_appairage.dart' show EleveDuFoyer;
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/config/env.dart';
import '../../core/domain/enums.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/service_planning.dart' show monFuseauProvider;
import '../../core/profil/service_acceptations.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/nav_shell.dart';
import '../../core/widgets/page_shell.dart';
import '../accueil_adulte/accueil_adulte_page.dart';
import '../compte/aide_page.dart';
import '../compte/apparence_page.dart';
import '../compte/donnees_compte.dart' show identiteTitulaireProvider;
import '../compte/informations_legales_page.dart';
import '../compte/informations_page.dart';
import '../compte/paiements_page.dart';
import '../compte/preferences_page.dart';
import '../compte/securite_page.dart';
import '../foyer/foyer_page.dart';
import '../foyer/place_adulte.dart' show foyerTitulaireProvider;
import '../ma_classe_adulte/ma_classe_adulte_page.dart';
import '../mon_espace_adulte/mon_espace_adulte_page.dart';
import 'adulte_demo.dart';
import 'classe_demo.dart';
import 'demo_classe_page.dart'
    show PreparationEleveDemo, adressePreparationEleveDemo, surchargesEleveDemo;
import 'mode_demonstration.dart';
import 'repere_demonstration.dart';

/// Les ecrans de la demonstration. Les quatre premiers sont les
/// destinations de la coquille, dans leur ordre.
enum EcranDemoAdulte {
  /// Accueil (EA-2).
  accueil,

  /// Ma classe (EA-3).
  maClasse,

  /// Coran.
  coran,

  /// Mon espace (EA-4).
  monEspace,

  /// Forfait famille, ouvert depuis Mon espace par le second adulte (EA-4).
  forfaitFamille,

  /// Ma famille : la coquille du tuteur sur le Foyer (EA-5).
  maFamille,

  /// Paiements, ouverts depuis Mon espace (EA-4).
  paiements,

  /// Mes informations, ouvertes depuis Mon espace (EA-4).
  informations,

  /// Cours et acces, ouverts depuis Mon espace (EA-4).
  coursAcces,

  /// Mes accords, ouverts depuis Mon espace (EA-4).
  accords,

  /// Connexion et securite, ouvertes depuis Mon espace (EA-4).
  securite,

  /// Preferences, ouvertes depuis Mon espace (EA-4).
  preferences,

  /// Apparence, ouverte depuis les Preferences (EA-4).
  apparence,

  /// Aide et contact, ouverts depuis Mon espace (EA-4).
  aide,

  /// Informations legales, ouvertes depuis Mon espace (EA-4).
  informationsLegales,

  /// Paiements du foyer, ouverts depuis Ma famille (EA-5 ; la page du foyer
  /// vient avec EA-9).
  paiementsFoyer,
}

/// L'ecran de la demonstration qu'ouvre une rubrique de Mon espace.
EcranDemoAdulte ecranDeRubrique(RubriqueMonEspace r) => switch (r) {
  RubriqueMonEspace.informations => EcranDemoAdulte.informations,
  RubriqueMonEspace.coursAcces => EcranDemoAdulte.coursAcces,
  RubriqueMonEspace.paiements => EcranDemoAdulte.paiements,
  RubriqueMonEspace.accords => EcranDemoAdulte.accords,
  RubriqueMonEspace.securite => EcranDemoAdulte.securite,
  RubriqueMonEspace.preferences => EcranDemoAdulte.preferences,
  RubriqueMonEspace.aide => EcranDemoAdulte.aide,
  RubriqueMonEspace.informationsLegales => EcranDemoAdulte.informationsLegales,
};

/// Les routes de la demonstration adulte : AUCUNE en production.
List<RouteBase> routesDemoAdulte(String environnement) {
  if (!environnementAutoriseDemo(environnement)) return const <RouteBase>[];
  return <RouteBase>[
    GoRoute(
      path: Routes.demoAdulte,
      builder: (BuildContext _, GoRouterState etat) {
        final Map<String, String> p = etat.uri.queryParameters;
        return DemoAdultePage(
          ecran: _lire(EcranDemoAdulte.values, p['ecran']),
          etat:
              _lire(EtatDemoAdulte.values, p['etat']) ??
              EtatDemoAdulte.conjointActif,
          genre: p['titulaire'] == 'femme'
              ? GenreTitulaireDemo.femme
              : GenreTitulaireDemo.homme,
          vue: p['vue'] == 'conjoint'
              ? VueDemoAdulte.secondAdulte
              : VueDemoAdulte.titulaire,
          seance:
              _lire(EtatDemoClasse.values, p['seance']) ??
              EtatDemoClasse.aVenir,
        );
      },
    ),
  ];
}

T? _lire<T extends Enum>(List<T> valeurs, String? nom) {
  for (final T v in valeurs) {
    if (v.name == nom) return v;
  }
  return null;
}

/// L'adresse d'un ecran de la demonstration.
String adresseDemoAdulte(
  EcranDemoAdulte ecran, {
  EtatDemoAdulte etat = EtatDemoAdulte.conjointActif,
  GenreTitulaireDemo genre = GenreTitulaireDemo.homme,
  VueDemoAdulte vue = VueDemoAdulte.titulaire,
  EtatDemoClasse seance = EtatDemoClasse.aVenir,
}) => Uri(
  path: Routes.demoAdulte,
  queryParameters: <String, String>{
    'ecran': ecran.name,
    'etat': etat.name,
    if (genre == GenreTitulaireDemo.femme) 'titulaire': 'femme',
    if (vue == VueDemoAdulte.secondAdulte) 'vue': 'conjoint',
    if (seance != EtatDemoClasse.aVenir) 'seance': seance.name,
  },
).toString();

/// Le libelle d'un ecran : celui de sa destination ou de sa ligne.
String libelleEcranDemoAdulte(EcranDemoAdulte ecran) => switch (ecran) {
  EcranDemoAdulte.accueil => t.adulte.nav.accueil,
  EcranDemoAdulte.maClasse => t.adulte.nav.maClasse,
  EcranDemoAdulte.coran => t.adulte.nav.coran,
  EcranDemoAdulte.monEspace => t.adulte.nav.monEspace,
  EcranDemoAdulte.forfaitFamille => t.adulte.famille.forfaitFamille,
  EcranDemoAdulte.maFamille => t.adulte.famille.maFamille,
  EcranDemoAdulte.paiements => t.adulte.monEspace.paiements,
  EcranDemoAdulte.informations => t.adulte.monEspace.informations,
  EcranDemoAdulte.coursAcces => t.adulte.monEspace.coursAcces,
  EcranDemoAdulte.accords => t.adulte.monEspace.accords,
  EcranDemoAdulte.securite => t.compte.tuteur.securite.titre,
  EcranDemoAdulte.preferences => t.compte.tuteur.preferences,
  EcranDemoAdulte.apparence => t.compte.tuteur.pagePreferences.apparence,
  EcranDemoAdulte.aide => t.compte.tuteur.aide.ligne,
  EcranDemoAdulte.informationsLegales => t.compte.tuteur.aide.legal,
  EcranDemoAdulte.paiementsFoyer => t.adulte.famille.paiementsFoyer,
};

/// Le libelle d'une situation (doc section 18).
String libelleEtatDemoAdulte(EtatDemoAdulte etat) =>
    t['adulte.demo.etats.${etat.name}'] as String;

/// Les quatre destinations de l'eleve adulte (UX_REVIEW_07 ligne 1) : le
/// chemin est l'ecran de la demonstration, la coquille ne le lit pas.
List<Destination> destinationsEleveAdulte() => <Destination>[
  Destination(
    libelle: t.adulte.nav.accueil,
    icone: AppIcons.accueil,
    chemin: EcranDemoAdulte.accueil.name,
  ),
  Destination(
    libelle: t.adulte.nav.maClasse,
    icone: AppIcons.classes,
    chemin: EcranDemoAdulte.maClasse.name,
  ),
  Destination(
    libelle: t.adulte.nav.coran,
    icone: AppIcons.coran,
    chemin: EcranDemoAdulte.coran.name,
  ),
  Destination(
    libelle: t.adulte.nav.monEspace,
    icone: AppIcons.profil,
    chemin: EcranDemoAdulte.monEspace.name,
  ),
];

/// La session de demonstration : un adulte resolu, sans source serveur.
class _SessionAdulteDemo extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.student,
    profileId: DonneesAdulteDemo.mamadouId,
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );
}

/// La page : la liste des ecrans, ou la coquille sur l'ecran choisi.
class DemoAdultePage extends StatelessWidget {
  /// Cree la page.
  const DemoAdultePage({
    this.ecran,
    this.etat = EtatDemoAdulte.conjointActif,
    this.genre = GenreTitulaireDemo.homme,
    this.vue = VueDemoAdulte.titulaire,
    this.seance = EtatDemoClasse.aVenir,
    super.key,
  });

  /// La situation de la prochaine seance (Accueil).
  final EtatDemoClasse seance;

  /// L'ecran choisi, ou nul pour la liste.
  final EcranDemoAdulte? ecran;

  /// La situation du foyer.
  final EtatDemoAdulte etat;

  /// Le genre du titulaire.
  final GenreTitulaireDemo genre;

  /// La personne qui regarde.
  final VueDemoAdulte vue;

  @override
  Widget build(BuildContext context) {
    final EcranDemoAdulte? e = ecran;
    if (e != null) {
      return CoquilleAdulteDemo(
        ecran: e,
        etat: etat,
        genre: genre,
        vue: vue,
        seance: seance,
      );
    }
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    Widget titre(String valeur) => Semantics(
      header: true,
      child: Text(
        valeur,
        style: palette.inkStrong.applyTo(
          textes.titleMedium ?? const TextStyle(),
        ),
      ),
    );
    final bool femme = genre == GenreTitulaireDemo.femme;
    return PageShell(
      titre: t.adulte.demo.titre,
      sousTitre: t.adulte.demo.mention,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            t.adulte.demo.intro,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vXxl,
          titre(t.adulte.demo.ecrans),
          Ecart.vMd,
          for (final EcranDemoAdulte ecran in <EcranDemoAdulte>[
            EcranDemoAdulte.accueil,
            EcranDemoAdulte.maClasse,
            EcranDemoAdulte.coran,
            EcranDemoAdulte.monEspace,
            EcranDemoAdulte.maFamille,
          ])
            LienFleche(
              key: ValueKey<String>('lien-ecran-${ecran.name}'),
              libelle: libelleEcranDemoAdulte(ecran),
              onPress: () => context.go(adresseDemoAdulte(ecran)),
            ),
          Ecart.vXxl,
          titre(t.adulte.demo.variantes),
          Ecart.vMd,
          LienFleche(
            key: const ValueKey<String>('lien-titulaire-femme'),
            libelle: t.adulte.demo.titulaireFemme,
            onPress: () => context.go(
              adresseDemoAdulte(
                EcranDemoAdulte.monEspace,
                genre: GenreTitulaireDemo.femme,
              ),
            ),
          ),
          LienFleche(
            key: const ValueKey<String>('lien-vue-conjoint'),
            libelle: femme
                ? t.adulte.demo.vueConjoint
                : t.adulte.demo.vueConjointe,
            onPress: () => context.go(
              adresseDemoAdulte(
                EcranDemoAdulte.monEspace,
                genre: genre,
                vue: VueDemoAdulte.secondAdulte,
              ),
            ),
          ),
          Ecart.vXxl,
          titre(t.adulte.demo.situations),
          Ecart.vMd,
          for (final EtatDemoAdulte etat in EtatDemoAdulte.values)
            LienFleche(
              key: ValueKey<String>('lien-etat-${etat.name}'),
              libelle: libelleEtatDemoAdulte(etat),
              onPress: () => context.go(
                adresseDemoAdulte(EcranDemoAdulte.monEspace, etat: etat),
              ),
            ),
        ],
      ),
    );
  }
}

/// La VRAIE coquille de l'eleve adulte (NavShell, quatre destinations), ou,
/// pour « Ma famille », la VRAIE coquille du tuteur sur le VRAI Foyer.
class CoquilleAdulteDemo extends StatelessWidget {
  /// Cree la coquille.
  const CoquilleAdulteDemo({
    required this.ecran,
    this.etat = EtatDemoAdulte.conjointActif,
    this.genre = GenreTitulaireDemo.homme,
    this.vue = VueDemoAdulte.titulaire,
    this.seance = EtatDemoClasse.aVenir,
    this.environnement = Env.environnement,
    super.key,
  });

  /// La situation de la prochaine seance (Accueil).
  final EtatDemoClasse seance;

  /// L'ecran affiche.
  final EcranDemoAdulte ecran;

  /// La situation du foyer.
  final EtatDemoAdulte etat;

  /// Le genre du titulaire.
  final GenreTitulaireDemo genre;

  /// La personne qui regarde.
  final VueDemoAdulte vue;

  /// L'environnement compile : la coquille du tuteur n'est montee que hors
  /// production (`surchargesDemoTuteur` le verifie).
  final String environnement;

  String _adresse(EcranDemoAdulte e) =>
      adresseDemoAdulte(e, etat: etat, genre: genre, vue: vue, seance: seance);

  @override
  Widget build(BuildContext context) {
    if (ecran == EcranDemoAdulte.maFamille ||
        ecran == EcranDemoAdulte.paiementsFoyer) {
      return _foyer(context);
    }
    final List<Destination> destinations = destinationsEleveAdulte();
    // Les pages ouvertes depuis Mon espace gardent sa destination allumee.
    final bool depuisMonEspace = ecran.index >= EcranDemoAdulte.monEspace.index;
    final int actif = depuisMonEspace
        ? EcranDemoAdulte.monEspace.index
        : ecran.index;
    void versMonEspace() => context.go(_adresse(EcranDemoAdulte.monEspace));
    return ProviderScope(
      key: ValueKey<String>(_adresse(ecran)),
      overrides: <Override>[
        sessionProvider.overrideWith(_SessionAdulteDemo.new),
        // L'Accueil lit la Classe An-Nour de la demonstration de Classe
        // (seance, reseau, travail, supports), plus sa propre vue.
        if (ecran == EcranDemoAdulte.accueil) ...<Override>[
          ...surchargesEleveDemo(seance),
          // Le second adulte est eleve d'une autre Classe, que la
          // demonstration n'a pas : le fournisseur reel reste (indisponible),
          // jamais la Classe An-Nour du titulaire (EA-BR-13).
          if (DonneesAdulteDemo.accueil(genre, vue)
              case final AccueilAdulteVM accueil)
            accueilAdulteProvider.overrideWith((Ref _) async => accueil),
        ] else if (ecran == EcranDemoAdulte.maClasse) ...<Override>[
          // Ma classe lit la meme Classe An-Nour, plus sa propre vue (EA-3).
          ...surchargesEleveDemo(seance),
          // Le second adulte est eleve d'une autre Classe, que la
          // demonstration n'a pas : le fournisseur reel reste (indisponible).
          if (DonneesAdulteDemo.maClasse(genre, vue)
              case final MaClasseAdulteVM classe)
            maClasseAdulteProvider.overrideWith((Ref _) async => classe),
        ] else ...<Override>[
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
          // Mon espace et ses pages lisent l'identite de la personne qui
          // regarde par le port du Compte, et sa ligne famille (EA-4). Les
          // paiements et l'aide gardent leur fournisseur reel (indisponible,
          // DB-CPT-03 et DB-CPT-07) ; le fuseau et les textes acceptes, qui
          // partiraient vers le serveur, sont indisponibles : rien d'invente.
          if (depuisMonEspace) ...<Override>[
            identiteTitulaireProvider.overrideWith(
              (Ref _) async => DonneesAdulteDemo.identite(genre, vue),
            ),
            monEspaceAdulteProvider.overrideWith(
              (Ref _) async => DonneesAdulteDemo.monEspace(etat, genre, vue),
            ),
            monFuseauProvider.overrideWith(
              (Ref _) => Future<String>.error(
                const CapaciteIndisponible('demonstration'),
              ),
            ),
            acceptationsProvider.overrideWith(
              (Ref _) => Future<List<Acceptation>>.error(
                const CapaciteIndisponible('demonstration'),
              ),
            ),
          ],
        ],
      ],
      child: RepereDemonstration(
        child: NavShell(
          destinations: destinations,
          indexActif: actif,
          libellesDansLeRail: true,
          onAller: (String chemin) {
            final EcranDemoAdulte? cible = _lire(
              EcranDemoAdulte.values,
              chemin,
            );
            if (cible != null) context.go(_adresse(cible));
          },
          child: switch (ecran) {
            // La cloche reste sans destination jusqu'a EA-8 (centre de
            // notifications de l'eleve adulte) ; « Voir tout » ouvre Ma
            // classe, dont le « Voir tout » ouvre la Bibliotheque de la
            // Classe, avec toutes ses ressources (EA-3).
            EcranDemoAdulte.accueil => AccueilAdultePage(
              onRejoindre: (_) => context.go(
                adressePreparationEleveDemo(PreparationEleveDemo.pret),
              ),
              onVoirRessources: (_) =>
                  context.go(_adresse(EcranDemoAdulte.maClasse)),
            ),
            EcranDemoAdulte.maClasse => MaClasseAdultePage(
              onRejoindre: (_) => context.go(
                adressePreparationEleveDemo(PreparationEleveDemo.pret),
              ),
            ),
            EcranDemoAdulte.coran => _PageProvisoire(
              titre: t.adulte.nav.coran,
              phrase: t.adulte.provisoire.coran,
            ),
            // Chaque rubrique ouvre la VRAIE sous-page du Compte, retour vers
            // Mon espace (sans fork) ; « Mes accords » et « Cours et acces »,
            // qui n'ont aucune source, disent qu'ils sont indisponibles.
            EcranDemoAdulte.monEspace => MonEspaceAdultePage(
              onOuvrir: (RubriqueMonEspace r) =>
                  context.go(_adresse(ecranDeRubrique(r))),
              onFamille: (LigneFamilleAdulte ligne) => context.go(
                _adresse(
                  ligne == LigneFamilleAdulte.forfaitFamille
                      ? EcranDemoAdulte.forfaitFamille
                      : EcranDemoAdulte.maFamille,
                ),
              ),
            ),
            EcranDemoAdulte.paiements => PaiementsComptePage(
              onRetour: versMonEspace,
            ),
            EcranDemoAdulte.informations => InformationsComptePage(
              onRetour: versMonEspace,
            ),
            EcranDemoAdulte.coursAcces => RubriqueIndisponibleAdultePage(
              rubrique: RubriqueMonEspace.coursAcces,
              onRetour: versMonEspace,
            ),
            EcranDemoAdulte.accords => RubriqueIndisponibleAdultePage(
              rubrique: RubriqueMonEspace.accords,
              onRetour: versMonEspace,
            ),
            EcranDemoAdulte.securite => SecuriteComptePage(
              onRetour: versMonEspace,
            ),
            EcranDemoAdulte.preferences => PreferencesComptePage(
              onRetour: versMonEspace,
              onApparence: () =>
                  context.go(_adresse(EcranDemoAdulte.apparence)),
            ),
            EcranDemoAdulte.apparence => ApparenceComptePage(
              onRetour: () => context.go(_adresse(EcranDemoAdulte.preferences)),
            ),
            EcranDemoAdulte.aide => AideComptePage(onRetour: versMonEspace),
            EcranDemoAdulte.informationsLegales =>
              InformationsLegalesComptePage(onRetour: versMonEspace),
            EcranDemoAdulte.forfaitFamille => _PageProvisoire(
              titre: t.adulte.famille.forfaitFamille,
              phrase: t.adulte.provisoire.forfaitFamille,
              onRetour: versMonEspace,
            ),
            EcranDemoAdulte.maFamille ||
            EcranDemoAdulte.paiementsFoyer => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }

  /// La coquille du tuteur existante (Accueil, Foyer, Historique, Compte) sur
  /// Ma famille, le Foyer du tuteur peuple du foyer Diallo (EA-5). Le retour
  /// vers Mon espace est une ligne au bord de debut, au-dessus du Foyer
  /// (UX_REVIEW_07 ligne 1 a).
  ///
  /// Decision EA-5 (releve d'EA-1b, « seul le Foyer reagit ») : la coquille
  /// du tuteur n'est pas recreee ; chacune de ses destinations reagit, et
  /// celles qui n'ont pas de page dans l'espace foyer de la demonstration
  /// ramenent a l'espace eleve, dont elles ont l'equivalent : « Compte » ouvre
  /// Mon espace (une seule place pour le compte, E3), « Accueil » et
  /// « Historique » ouvrent l'Accueil (prochaine et dernieres seances). Les
  /// chemins internes du Foyer (ajout, fiche, appareils) n'ont pas encore de
  /// page de demonstration : ils ne quittent pas la coquille.
  Widget _foyer(BuildContext context) {
    final List<Destination> destinations = destinationsPour(
      role: AppRole.guardian,
      mode: InterfaceMode.standard,
    );
    final List<EleveDuFoyer> enfants = DonneesAdulteDemo.enfantsPour(etat);
    void versMaFamille() => context.go(_adresse(EcranDemoAdulte.maFamille));
    return ProviderScope(
      key: ValueKey<String>(_adresse(ecran)),
      overrides: <Override>[
        ...surchargesDemoTuteur(environnement: environnement, eleves: enfants),
        // Sous un ProviderScope imbrique, un provider derive non surcharge se
        // resoudrait dans le conteneur racine, sans les eleves Diallo.
        profilsElevesFoyerProvider.overrideWith(
          (Ref _) async => <ProfilEleveFoyer>[
            for (final EleveDuFoyer e in enfants) ProfilEleveFoyer.depuis(e),
          ],
        ),
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
        // Ma famille du titulaire (EA-5, EA-BR-14) : son identite par le port
        // du Compte, et la place adulte selon la situation.
        identiteTitulaireProvider.overrideWith(
          (Ref _) async =>
              DonneesAdulteDemo.identite(genre, VueDemoAdulte.titulaire),
        ),
        foyerTitulaireProvider.overrideWith(
          (Ref _) async => DonneesAdulteDemo.foyerTitulaire(etat, genre),
        ),
      ],
      child: RepereDemonstration(
        child: NavShell(
          destinations: destinations,
          indexActif: destinations.indexWhere(
            (Destination d) => d.chemin == Routes.tuteurFoyer,
          ),
          onAller: (String chemin) => context.go(
            _adresse(switch (chemin) {
              Routes.tuteurFoyer => EcranDemoAdulte.maFamille,
              Routes.tuteurCompte => EcranDemoAdulte.monEspace,
              _ => EcranDemoAdulte.accueil,
            }),
          ),
          child: ecran == EcranDemoAdulte.paiementsFoyer
              ? PaiementsComptePage(onRetour: versMaFamille)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: AppSpacing.lg,
                        end: AppSpacing.lg,
                        top: AppSpacing.sm,
                      ),
                      child: LienFleche(
                        key: const ValueKey<String>('retour-mon-espace'),
                        icone: AppIcons.retour,
                        fleche: false,
                        libelle: t.adulte.famille.retourMonEspace,
                        onPress: () =>
                            context.go(_adresse(EcranDemoAdulte.monEspace)),
                      ),
                    ),
                    Expanded(
                      child: FoyerPage(
                        onAller: (String _) {},
                        onPaiementsFoyer: () => context.go(
                          _adresse(EcranDemoAdulte.paiementsFoyer),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Une page provisoire : son titre et une phrase qui dit ce qui viendra.
class _PageProvisoire extends StatelessWidget {
  const _PageProvisoire({
    required this.titre,
    required this.phrase,
    this.onRetour,
  });

  final String titre;
  final String phrase;
  final VoidCallback? onRetour;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return PageShell(
      titre: titre,
      onRetour: onRetour,
      child: Text(
        phrase,
        style: palette.inkMuted.applyTo(
          Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
        ),
      ),
    );
  }
}
