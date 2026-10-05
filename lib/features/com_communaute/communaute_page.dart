// La Communaute enseignants (COM-M02 telephone, COM-W02 ordinateur ; spec
// section 4, section 16, section 17, section 18, section 23 « Responsive »,
// section 25).
//
// `/enseignant/communaute` (et `/:publicationId`, ouverte par une
// notification) : un raccourci d'Aujourd'hui (Q2), dans la VRAIE coquille de
// l'enseignant, jamais « Foyer » ni « Tuteur » des maquettes (spec section
// 17, correction obligatoire de COM-W02). Le retour ramene a Aujourd'hui.
//
// Disposition : `EspaceTravailAdaptatif` du socle, un seul ecran.
// - Ordinateur : Navigation (la coquille) | Flux | Publication/Reponses |
//   Aide/Regles. Les categories et la recherche persistante tiennent la
//   ligne au-dessus des colonnes.
// - Tablette (deux colonnes) : Flux | Publication ; l'aide s'ouvre en
//   feuille. Dans la vraie coquille Enseignant, le rail a libelles laisse
//   moins de 600 a l'espace a 768 : les deux colonnes n'arrivent qu'a partir
//   de 1024 ; a 768, c'est la disposition du telephone (seuils
//   d'`EspaceTravailAdaptatif` avec un rail a libelles : point ouvert
//   COM-FUS).
// - Telephone : une surface a la fois (le flux, la publication ou le
//   composer), retour explicite ; la recherche est une surface temporaire
//   dont la fermeture rend le flux tel qu'il etait (spec section 18).
//
// Ce que la maquette montre et qui n'est pas repris : les coeurs et leurs
// compteurs (section 32), « Ressources utiles » (concurrence de la
// Bibliotheque), le sous-titre « de Classe An-Nour » (la Communaute est
// transversale), les onglets Messages / Communaute / Le Studio (UX_REVIEW L0,
// section 5).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/modeles_communication.dart';
import '../../core/communications/port_brouillons.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/espace_travail_adaptatif.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/surface_recherche.dart';
import '../../core/widgets/vue_etat_communication.dart';
import 'composer_publication.dart';
import 'flux_publications.dart';
import 'port_communaute.dart';
import 'publication_detail.dart';
import 'regles_communaute.dart';

/// La Communaute enseignants.
class CommunautePage extends ConsumerStatefulWidget {
  /// Cree la page.
  const CommunautePage({
    super.key,
    this.publicationId,
    this.onRetour,
    this.composerOuvert = false,
  });

  /// La publication demandee par l'adresse, s'il y en a une.
  final String? publicationId;

  /// Le retour hors de la Communaute ; par defaut, Aujourd'hui (d'ou part le
  /// raccourci, Q2). La demonstration passe le sien.
  final VoidCallback? onRetour;

  /// Vrai : la page s'ouvre sur la nouvelle publication (si la personne
  /// peut publier). La demonstration du garde anti-promotion s'en sert pour
  /// montrer un brouillon deja ecrit ; aucune route ne le pose.
  final bool composerOuvert;

  /// La cle de la ligne des categories et de la recherche (ordinateur et
  /// tablette), pour les tests.
  static const ValueKey<String> cleBarreFiltres = ValueKey<String>(
    'communaute-barre-filtres',
  );

  /// La cle de la surface « aucune publication ouverte », pour les tests.
  static const ValueKey<String> cleAucuneSelection = ValueKey<String>(
    'communaute-aucune-selection',
  );

  @override
  ConsumerState<CommunautePage> createState() => _CommunautePageState();
}

class _CommunautePageState extends ConsumerState<CommunautePage> {
  String? _categorie;
  final TextEditingController _recherche = TextEditingController();
  bool _rechercheOuverte = false;
  late String? _selection = widget.publicationId;
  late bool _composer = widget.composerOuvert;
  late SurfaceMobile _surface =
      widget.publicationId == null && !widget.composerOuvert
      ? SurfaceMobile.liste
      : SurfaceMobile.principal;
  String? _retourLocal;

  /// Le nombre de colonnes de la derniere mise en page : lu par le retour,
  /// au moment du geste.
  int _colonnes = 1;

  /// Vrai tant que le panneau Aide/Regles est ouvert (il se ferme par le
  /// bouton du socle) : ferme, le bandeau des regles revient dans le flux.
  bool _contexteOuvert = true;

  /// Les objets signales pendant la visite : ils survivent au changement de
  /// publication ouverte, pour qu'un objet ne soit jamais signale deux fois
  /// et que la confirmation reste dite.
  final Set<ObjetLie> _signales = <ObjetLie>{};

  FiltreFlux get _filtre =>
      (categorieId: _categorie, recherche: _recherche.text);

  @override
  void initState() {
    super.initState();
    _recherche.addListener(_auChangementRecherche);
  }

  @override
  void dispose() {
    _recherche
      ..removeListener(_auChangementRecherche)
      ..dispose();
    super.dispose();
  }

  /// La recherche filtre le flux deja lu a chaque frappe (et a « Effacer »).
  void _auChangementRecherche() => setState(() {});

  void _quitter() {
    final VoidCallback? retour = widget.onRetour;
    if (retour != null) {
      retour();
    } else {
      GoRouter.of(context).go(Routes.enseignantJournee);
    }
  }

  /// Le retour explicite : sur une colonne, la publication, le composer ou
  /// la recherche reviennent au flux ; sinon, on quitte la Communaute.
  void _retour() {
    if (_colonnes == 1 && _surface == SurfaceMobile.principal) {
      _revenirAuFlux();
      return;
    }
    if (_colonnes == 1 && _rechercheOuverte) {
      _fermerRecherche();
      return;
    }
    if (_composer) {
      setState(() => _composer = false);
      return;
    }
    _quitter();
  }

  bool get _retourInterne =>
      _colonnes == 1 &&
      (_surface == SurfaceMobile.principal || _rechercheOuverte);

  void _revenirAuFlux() => setState(() {
    _surface = SurfaceMobile.liste;
    _composer = false;
  });

  void _ouvrir(String id) => setState(() {
    _selection = id;
    _composer = false;
    _surface = SurfaceMobile.principal;
    _retourLocal = null;
  });

  void _ouvrirComposer() => setState(() {
    _composer = true;
    _surface = SurfaceMobile.principal;
    _retourLocal = null;
  });

  void _fermerRecherche() {
    _recherche.clear();
    setState(() => _rechercheOuverte = false);
  }

  void _publiee(PublicationCommunaute publication) {
    ref
      ..invalidate(publicationsCommunauteProvider)
      ..invalidate(publicationCommunauteProvider(publication.id));
    setState(() {
      _composer = false;
      _selection = publication.id;
      _surface = SurfaceMobile.principal;
      _retourLocal = t.com.communaute.composer.confirmee;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = t.com.communaute;
    // Les brouillons de session (nouvelle publication, reponses) vivent tant
    // que la Communaute est ouverte : la page les ecoute, pour qu'un composer
    // ferme puis rouvert retrouve son texte (spec section 8.2).
    ref.watch(portBrouillonsProvider);
    // Telephone, une publication ou le composer ouvert : la phrase qui
    // presente la Communaute reste sur le flux. Elle ne prend pas la hauteur
    // de la publication (COM-RC tour 2, R-01 : a 320, texte x2, elle
    // occupait quatre lignes au-dessus de la publication).
    final bool telephone =
        MediaQuery.sizeOf(context).width < AppGabarit.seuilTablette;
    final bool surfacePrincipale =
        telephone && _surface == SurfaceMobile.principal;
    // COM-RC tour 3 : sur telephone a texte agrandi, la phrase se replie
    // aussi sur le flux. A 320 et texte x2, elle prenait quatre lignes a
    // cote du retour et aucune publication n'etait au premier ecran ; le
    // bandeau des regles dit deja ce qu'est l'espace.
    final bool texteAgrandi =
        MediaQuery.textScalerOf(context).scale(1) >=
        FluxPublications.echelleSerree;
    final bool phraseRepliee = surfacePrincipale || (telephone && texteAgrandi);
    return PageShell(
      titre: c.titre,
      sousTitre: phraseRepliee ? null : c.sousTitre,
      onRetour: _retour,
      defilante: false,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints contraintes) {
          _colonnes = colonnesPour(contraintes.maxWidth);
          return PopScope(
            canPop: !_retourInterne,
            onPopInvokedWithResult: (bool fait, Object? _) {
              if (!fait) _retour();
            },
            child: _corps(context),
          );
        },
      ),
    );
  }

  Widget _corps(BuildContext context) {
    final AsyncValue<CapacitesCommunaute> capacitesLues = ref.watch(
      capacitesCommunauteProvider,
    );
    final AsyncValue<List<CategorieCommunaute>> categoriesLues = ref.watch(
      categoriesCommunauteProvider,
    );
    // Les capacites et les categories conditionnent l'ecran entier : sans
    // elles, aucune colonne ne s'ouvre (un port neutre dit « Pas encore
    // disponible », un echec propose « Reessayer »).
    final Object? erreur = capacitesLues.error ?? categoriesLues.error;
    if (erreur != null) {
      return SingleChildScrollView(
        child: erreur is CapaciteIndisponible
            // Le port neutre de production : l'espace n'est pas encore
            // branche (COM-BR-05). Ni un echec, ni un vide : pas de
            // « Reessayer ».
            ? EtatSysteme(
                nature: NatureEtat.indisponible,
                titre: t.com.socle.composants.etats.indisponibleTitre,
                phrase: t.com.socle.navigation.provisoire.communauteDetail,
                dependance: erreur.dependance,
              )
            : VueEtatCommunication.depuisErreur(
                erreur,
                horsLigne: ref.watch(horsLigneProvider).value ?? false,
                onReessayer: () => ref
                  ..invalidate(capacitesCommunauteProvider)
                  ..invalidate(categoriesCommunauteProvider),
              ),
      );
    }
    if (!capacitesLues.hasValue || !categoriesLues.hasValue) {
      return Semantics(
        label: t.com.socle.composants.etats.chargement,
        child: const ExcludeSemantics(
          child: SingleChildScrollView(child: Skeleton.liste()),
        ),
      );
    }
    final CapacitesCommunaute capacites = capacitesLues.requireValue;
    final List<CategorieCommunaute> categories = categoriesLues.requireValue;
    final bool uneColonne = _colonnes == 1;
    // Le panneau Aide/Regles n'est en colonne qu'a trois colonnes et tant
    // qu'il est ouvert ; sinon le bandeau « Partage pedagogique uniquement »
    // se pose dans le flux, toujours present (spec section 5.2, section 16).
    final bool avecContexte = _colonnes >= 3 && _contexteOuvert;

    final Widget? entree = capacites.peutPublier && !_composer
        ? EntreeNouvellePublication(
            onOuvrir: _ouvrirComposer,
            pleineLargeur: uneColonne,
          )
        : null;

    final bool surfaceRecherche = uneColonne && _rechercheOuverte;
    final Widget publications = FluxPublications(
      filtre: _filtre,
      selection: uneColonne ? null : _selection,
      onOuvrir: _ouvrir,
      compacte: uneColonne,
      avecBandeau: !avecContexte && !surfaceRecherche,
      enTete: uneColonne && !surfaceRecherche ? _teteMobile() : null,
      entreeComposer: surfaceRecherche ? null : entree,
    );
    final r = t.com.communaute.recherche;
    // Telephone : la recherche ouverte est la surface partagee (R-07), le
    // flux filtre en dessous ; la fermer rend le flux tel qu'il etait.
    final Widget flux = surfaceRecherche
        ? SurfaceRecherche(
            key: ClesRechercheCommunaute.surface,
            controleur: _recherche,
            libelle: r.champ,
            aide: r.aide,
            cleChamp: ClesRechercheCommunaute.champ,
            cleEffacer: ClesRechercheCommunaute.effacer,
            cleFermer: ClesRechercheCommunaute.fermer,
            onFermer: _fermerRecherche,
            resultats: publications,
          )
        : publications;

    // Les ecarts entre colonnes et le retrait apres le filet sont ceux de
    // l'espace adaptatif (R-10) : la page n'en ajoute pas.
    final Widget principal = _principal(capacites, categories);

    final Widget espace = EspaceTravailAdaptatif(
      liste: flux,
      principal: principal,
      contexte: const ReglesCommunaute(),
      titreContexte: t.com.communaute.regles.panneau,
      surfaceMobile: _surface,
      // Le composer et la publication posent (i) dans leur en-tete
      // (`RangeeEnteteEspace`) : aucune rangee a part ne prend de hauteur
      // a la publication, et (i) ne s'empile pas sur la fermeture du
      // composer (COM-RC tour 2).
      barreDansEntete:
          (_composer && capacites.peutPublier) || _selection != null,
      contexteOuvertInitial: _contexteOuvert,
      onContexteBascule: (bool ouvert) =>
          setState(() => _contexteOuvert = ouvert),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!uneColonne) ...<Widget>[
          Row(
            key: CommunautePage.cleBarreFiltres,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SelecteurCategories(
                    valeur: _categorie,
                    onChange: (String? id) => setState(() => _categorie = id),
                  ),
                ),
              ),
              Ecart.hLg,
              // La largeur de la file (336, R-10) : a 256, l'etiquette
              // « Rechercher une publication » etait tronquee a 1440
              // (COM-RC tour 2).
              SizedBox(
                width: EspaceTravailAdaptatif.largeurListeLarge,
                child: ChampRecherche(
                  controleur: _recherche,
                  libelle: t.com.communaute.recherche.champ,
                  aide: t.com.communaute.recherche.aide,
                  cleChamp: ClesRechercheCommunaute.champ,
                  cleEffacer: ClesRechercheCommunaute.effacer,
                ),
              ),
            ],
          ),
          Ecart.vLg,
        ],
        // Le retour local (« Votre publication est en ligne. ») : pose pres
        // de ce qui a change, il s'efface seul (`LocalFeedback`).
        LocalFeedback(message: _retourLocal),
        Expanded(child: espace),
      ],
    );
  }

  /// La tete du flux sur telephone : categories et entree de la recherche.
  Widget _teteMobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SelecteurCategories(
          valeur: _categorie,
          onChange: (String? id) => setState(() => _categorie = id),
        ),
        Ecart.vSm,
        EntreeRechercheCommunaute(
          onOuvrir: () => setState(() => _rechercheOuverte = true),
        ),
      ],
    );
  }

  Widget _principal(
    CapacitesCommunaute capacites,
    List<CategorieCommunaute> categories,
  ) {
    if (_composer && capacites.peutPublier) {
      return ComposerPublication(
        key: const ValueKey<String>('communaute-composer'),
        categories: categories,
        categorieInitiale: _categorie,
        onPubliee: _publiee,
        onFermer: () => setState(() {
          _composer = false;
          if (_colonnes == 1 || _selection == null) {
            _surface = SurfaceMobile.liste;
          }
        }),
      );
    }
    final String? selection = _selection;
    if (selection == null) {
      // Le flux est vide (aucune publication, ou aucune pour ce filtre) : il
      // dit deja son etat vide, le centre n'en ajoute pas un second a cote
      // (revue COM-R, R-13).
      final AsyncValue<List<PublicationCommunaute>> lues = ref.watch(
        publicationsCommunauteProvider((
          categorieId: _filtre.categorieId,
          recherche: '',
        )),
      );
      if (lues.hasValue &&
          !lues.hasError &&
          filtrerPublications(lues.requireValue, _filtre.recherche).isEmpty) {
        return const SizedBox.shrink(key: CommunautePage.cleAucuneSelection);
      }
      final c = t.com.communaute.publication;
      return VueChoisirCommunication(
        key: CommunautePage.cleAucuneSelection,
        titre: c.choisirTitre,
        phrase: c.choisir,
      );
    }
    return PublicationDetail(
      key: ValueKey<String>('communaute-detail-$selection'),
      publicationId: selection,
      peutRepondre: capacites.peutRepondre,
      signales: _signales,
      onSignale: (ObjetLie objet) => setState(() => _signales.add(objet)),
      onRevenir: () => setState(() {
        _selection = null;
        _surface = SurfaceMobile.liste;
      }),
    );
  }
}
