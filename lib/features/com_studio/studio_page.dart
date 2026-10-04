// Le Studio (COM-M03, COM-W03, COM-M04, COM-W00 ; spec section 6, section 7,
// section 8, section 9, section 14, section 15, section 18, section 23,
// section 25 ; QUESTIONS Q1).
//
// `/admin/studio` (Aujourd'hui, l'accueil du Studio, spec section 14),
// `/admin/studio?vue=canaux|enregistres|brouillons` (les autres vues) et
// `/admin/studio/canaux/:canalId` (un canal), ouverts par l'action « Le
// Studio » de l'en-tete de l'`AdminShell` (et du tiroir sous 600). En V1,
// seule la direction (admin) y entre : la garde est celle du routeur, la page
// ne lit aucun role.
//
// Hors de la coquille admin : Le Studio a SA coquille, posee ici sur les
// composants du depot (`NavShell`, `PageShell`), avec sa navigation propre
// (Aujourd'hui, Canaux, Elements enregistres, Brouillons : spec section 15 ;
// la recherche est un etat des Canaux, le Focus un etat du canal). La sortie
// (disque retour) ramene a l'Accueil admin. Rien de la
// maquette sombre n'est repris hors du perimetre : ni Taches, ni visio, ni
// « Nouvel espace », ni Projets, ni favoris (UX_REVIEW L0, ecart 14).
//
// Disposition, sur l'espace de travail adaptatif du socle :
//
// - ordinateur : Navigation | Canaux | Fil | Contexte ;
// - tablette : Navigation (rail) | Canaux | Fil, le contexte en feuille ;
// - telephone : une surface a la fois, les canaux (`/admin/studio`) OU le
//   canal (`/admin/studio/canaux/:canalId`) ; le disque retour du canal
//   ramene a la liste, celui de la liste quitte Le Studio ; la barre basse
//   du Studio accompagne la liste et s'efface dans un canal ouvert (tache
//   focalisee, comme la saisie d'un message).
//
// Aucune colonne vide : sans canal ouvert, la colonne du fil dit quoi faire ;
// sans liste a montrer (chargement, vide, erreur, indisponible), l'etat
// prend la place et aucune colonne n'est reservee.
//
// Etats (spec section 25) : chargement (squelette), contenu, vide (« Aucun
// canal pour le moment »), erreur (« Reessayer »), hors ligne (bandeau des
// communications, contenu deja lu garde), capacite indisponible (port
// neutre, sans « Reessayer »), canal retire ou prive non autorise (rien du
// canal n'est rendu, R-COM-08), envoi en cours, envoi non confirme
// (R-COM-13), non lu (badge), panneau de contexte ferme.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/port_elements_enregistres.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/communications/espace_travail_adaptatif.dart';
import '../../core/widgets/communications/etats_communication.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/nav_shell.dart';
import '../../core/widgets/page_shell.dart';
import 'aujourdhui_page.dart';
import 'brouillons_studio.dart';
import 'canal_page.dart';
import 'elements_enregistres_studio.dart';
import 'liste_canaux.dart';
import 'panneau_partages.dart';
import 'port_activite_studio.dart' show DestinationStudio;
import 'port_studio.dart';
import 'recherche_studio.dart';
import 'visibilite_canal.dart';

/// Les vues de premier niveau du Studio (sa navigation propre), dans
/// l'ordre de la navigation.
enum VueStudio {
  /// Aujourd'hui : l'accueil du Studio (COM-W00, COM-M04).
  aujourdhui,

  /// Les canaux, et le canal ouvert.
  canaux,

  /// Les elements enregistres.
  enregistres,

  /// Les brouillons.
  brouillons,
}

/// La vue demandee par l'adresse (`?vue=canaux`) ; Aujourd'hui sinon.
VueStudio vueStudioDepuis(String? nom) {
  for (final VueStudio v in VueStudio.values) {
    if (v.name == nom) return v;
  }
  return VueStudio.aujourdhui;
}

/// L'adresse d'un canal du Studio, son identifiant encode.
String cheminCanalStudio(String canalId) =>
    Routes.canalStudioPour(Uri.encodeComponent(canalId));

/// L'adresse d'une vue du Studio.
String adresseVueStudio(VueStudio vue) => switch (vue) {
  VueStudio.aujourdhui => Routes.adminStudio,
  VueStudio.canaux || VueStudio.enregistres || VueStudio.brouillons => Uri(
    path: Routes.adminStudio,
    queryParameters: <String, String>{'vue': vue.name},
  ).toString(),
};

/// Ouvre une destination du Studio : son chemin, et l'argument de
/// navigation qui ne passe jamais par l'adresse (l'identifiant d'un
/// dossier).
void ouvrirDestinationStudio(GoRouter routeur, DestinationStudio d) =>
    routeur.go(d.chemin, extra: d.argument);

/// Le Studio, page routee de la direction.
class StudioPage extends StatelessWidget {
  /// Cree la page.
  const StudioPage({super.key, this.canalId});

  /// Le canal demande par l'adresse, s'il y en a un. Jamais une
  /// autorisation : le port decide (COM-BR-08).
  final String? canalId;

  @override
  Widget build(BuildContext context) {
    final GoRouter routeur = GoRouter.of(context);
    final String? canal = canalId;
    final VueStudio vue = canal != null
        ? VueStudio.canaux
        : vueStudioDepuis(GoRouterState.of(context).uri.queryParameters['vue']);
    return CoquilleStudio(
      vue: vue,
      onAllerVue: (VueStudio v) => routeur.go(adresseVueStudio(v)),
      onQuitter: () => routeur.go(Routes.admin),
      onRetourListe: canal == null
          ? null
          : () => routeur.go(adresseVueStudio(VueStudio.canaux)),
      child: switch (vue) {
        VueStudio.aujourdhui => TableauAujourdhui(
          onOuvrir: (DestinationStudio d) =>
              ouvrirDestinationStudio(routeur, d),
          onVoirBrouillons: () =>
              routeur.go(adresseVueStudio(VueStudio.brouillons)),
          destinationCanal: cheminCanalStudio,
        ),
        VueStudio.canaux => EspaceStudio(
          canalId: canal,
          onOuvrirCanal: (String id) => routeur.go(cheminCanalStudio(id)),
          onOuvrir: routeur.go,
        ),
        VueStudio.enregistres => VueElementsEnregistres(onOuvrir: routeur.go),
        VueStudio.brouillons => VueBrouillonsStudio(
          onOuvrir: (DestinationStudio d) =>
              ouvrirDestinationStudio(routeur, d),
          destinationCanal: cheminCanalStudio,
        ),
      },
    );
  }
}

/// La coquille du Studio : sa navigation (Aujourd'hui, Canaux, Elements
/// enregistres, Brouillons), son titre et sa sortie. Posee par la page
/// routee et par la demonstration, chacune avec sa facon de changer de vue.
class CoquilleStudio extends StatelessWidget {
  /// Cree la coquille.
  const CoquilleStudio({
    required this.vue,
    required this.onAllerVue,
    required this.onQuitter,
    required this.child,
    super.key,
    this.onRetourListe,
    this.sousTitre,
  });

  /// La vue montree.
  final VueStudio vue;

  /// Change de vue.
  final ValueChanged<VueStudio> onAllerVue;

  /// Quitte Le Studio (vers l'Accueil admin, ou l'index de la
  /// demonstration) : le disque retour de la page.
  final VoidCallback onQuitter;

  /// Revient du canal ouvert a la liste des canaux ; nul si aucun canal
  /// n'est ouvert. Sur telephone, ou une seule surface se voit, c'est le
  /// disque retour qui le fait (comme les Messages metier) : le canal garde
  /// toute sa hauteur pour le fil et le champ. Ailleurs, la liste est a
  /// cote, et le disque retour quitte Le Studio.
  final VoidCallback? onRetourListe;

  /// Le contenu de la vue : il recoit une hauteur bornee et gere son propre
  /// defilement.
  final Widget child;

  /// Un sous-titre ; par defaut, celui de la vue (« Espace de travail de
  /// l'equipe » pour les canaux, « Le Studio » ailleurs).
  final String? sousTitre;

  /// Les destinations de la navigation du Studio, dans l'ordre de
  /// [VueStudio].
  static List<Destination> destinations() {
    final n = t.com.studio.navigation;
    return <Destination>[
      for (final VueStudio v in VueStudio.values)
        switch (v) {
          VueStudio.aujourdhui => Destination(
            libelle: n.aujourdhui,
            icone: AppIcons.journee,
            chemin: v.name,
          ),
          VueStudio.canaux => Destination(
            libelle: n.canaux,
            icone: AppIcons.discussion,
            chemin: v.name,
          ),
          VueStudio.enregistres => Destination(
            libelle: n.enregistres,
            icone: AppIcons.cahier,
            chemin: v.name,
          ),
          VueStudio.brouillons => Destination(
            libelle: n.brouillons,
            icone: AppIcons.crayon,
            chemin: v.name,
          ),
        },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<Destination> d = destinations();
    return NavShell(
      destinations: d,
      indexActif: VueStudio.values.indexOf(vue),
      onAller: (String chemin) => onAllerVue(vueStudioDepuis(chemin)),
      // Sur telephone, un canal ouvert est une tache focalisee : la barre
      // basse s'efface, le disque retour ramene a la liste, et le fil garde
      // sa hauteur au-dessus du clavier (R-COM-15).
      masquerBarreBasse: onRetourListe != null,
      child: PageShell(
        titre: switch (vue) {
          VueStudio.aujourdhui => t.com.studio.aujourdhui.titre,
          VueStudio.canaux => t.com.studio.titre,
          VueStudio.enregistres => t.com.studio.navigation.enregistres,
          VueStudio.brouillons => t.com.studio.brouillons.titre,
        },
        sousTitre:
            sousTitre ??
            switch (vue) {
              VueStudio.aujourdhui => t.com.studio.aujourdhui.sousTitre,
              VueStudio.canaux => t.com.studio.sousTitre,
              VueStudio.enregistres ||
              VueStudio.brouillons => t.com.studio.titre,
            },
        onRetour: switch (onRetourListe) {
          final VoidCallback retour
              when AppGabarit.de(context) == Gabarit.mobile =>
            retour,
          _ => onQuitter,
        },
        defilante: false,
        child: child,
      ),
    );
  }
}

/// La memoire des positions de lecture du Studio (la liste des canaux).
///
/// `/admin/studio` et `/admin/studio/canaux/:canalId` sont deux routes : a
/// chaque passage de l'une a l'autre, la page et son `PageStorage` sont
/// recrees. Cette memoire vit au-dessus des pages (dans le `ProviderScope`) :
/// la liste retrouve sa position quand on revient d'un canal (telephone) ou
/// quand on en ouvre un depuis la liste (ordinateur, tablette). Elle ne garde
/// que des positions de defilement, jamais un contenu : la liste est relue
/// a chaque page.
final Provider<PageStorageBucket> positionsStudioProvider =
    Provider<PageStorageBucket>((Ref ref) => PageStorageBucket());

/// L'espace des canaux du Studio : liste, canal, panneau, recherche, et
/// leurs etats.
///
/// Sans route : la page routee et la demonstration le posent, chacune avec
/// sa facon d'ouvrir un canal ([onOuvrirCanal]).
class EspaceStudio extends ConsumerStatefulWidget {
  /// Cree l'espace.
  const EspaceStudio({
    required this.onOuvrirCanal,
    required this.onOuvrir,
    super.key,
    this.canalId,
    this.destinationCanal = cheminCanalStudio,
  });

  /// Le canal ouvert, ou `null` pour la liste seule.
  final String? canalId;

  /// Ouvre un canal (par l'adresse, ou par l'etat de la demonstration).
  final ValueChanged<String> onOuvrirCanal;

  /// Ouvre un chemin interne (un lien utile du panneau).
  final ValueChanged<String> onOuvrir;

  /// Le chemin d'un canal : la destination de ses references enregistrees.
  final String Function(String canalId) destinationCanal;

  /// La cle de la phrase « Choisissez un canal », pour les tests.
  static const ValueKey<String> cleChoisir = ValueKey<String>('studio-choisir');

  /// La cle de l'entree de recherche du telephone, pour les tests.
  static const ValueKey<String> cleOuvrirRecherche = ValueKey<String>(
    'studio-ouvrir-recherche',
  );

  /// La cle de l'etat « canal indisponible », pour les tests.
  static const ValueKey<String> cleCanalIndisponible = ValueKey<String>(
    'studio-canal-indisponible',
  );

  @override
  ConsumerState<EspaceStudio> createState() => _EspaceStudioState();
}

class _EspaceStudioState extends ConsumerState<EspaceStudio> {
  AsyncValue<List<ResumeCanal>> _canaux =
      const AsyncValue<List<ResumeCanal>>.loading();
  AsyncValue<Canal?> _canal = const AsyncValue<Canal?>.loading();
  AsyncValue<PartagesCanal> _partages =
      const AsyncValue<PartagesCanal>.loading();
  EtatEnregistrements? _enregistrements;
  String? _retour;

  final TextEditingController _recherche = TextEditingController();
  AsyncValue<ResultatsStudio> _resultats =
      const AsyncValue<ResultatsStudio>.loading();
  FiltreRechercheStudio _filtre = FiltreRechercheStudio.tout;
  bool _surfaceRecherche = false;
  int _numeroRecherche = 0;
  String _texteCherche = '';

  PortStudio get _port => ref.read(portStudioProvider);

  @override
  void initState() {
    super.initState();
    _recherche.addListener(_auChangementRecherche);
    _chargerCanaux();
    unawaited(_chargerEnregistrements());
    final String? id = widget.canalId;
    if (id != null) _chargerCanal(id);
  }

  @override
  void didUpdateWidget(EspaceStudio ancien) {
    super.didUpdateWidget(ancien);
    final String? id = widget.canalId;
    if (id != ancien.canalId && id != null) _chargerCanal(id);
  }

  @override
  void dispose() {
    _recherche
      ..removeListener(_auChangementRecherche)
      ..dispose();
    super.dispose();
  }

  /// Lit la liste. [silencieux] : relecture apres une action (lu, envoi),
  /// la liste deja montree reste en place, et un echec ne l'efface pas.
  Future<void> _chargerCanaux({bool silencieux = false}) async {
    if (!silencieux) {
      setState(() => _canaux = const AsyncValue<List<ResumeCanal>>.loading());
    }
    final AsyncValue<List<ResumeCanal>> lus =
        await AsyncValue.guard<List<ResumeCanal>>(() async {
          // Defense de surface (R-COM-08) : un canal absent n'est jamais
          // rendu, meme si le port le laissait passer.
          return canauxRendus(
            await _port.canaux(),
            (ResumeCanal c) => c.visibilite,
          );
        });
    if (!mounted) return;
    if (silencieux && lus.hasError) return;
    setState(() => _canaux = lus);
  }

  Future<void> _chargerCanal(String id) async {
    setState(() {
      _canal = const AsyncValue<Canal?>.loading();
      _partages = const AsyncValue<PartagesCanal>.loading();
      _retour = null;
    });
    final AsyncValue<Canal?> lu = await AsyncValue.guard<Canal?>(() async {
      final Canal? canal = await _port.canal(id);
      // Un canal rendu sous un autre identifiant, ou absent pour la
      // personne, n'est pas celui demande : il est traite comme absent.
      return canal != null && canal.id == id && canal.resume.visibilite.estRendu
          ? canal
          : null;
    });
    if (!mounted || widget.canalId != id) return;
    setState(() => _canal = lu);
    if (lu.value != null) {
      unawaited(_chargerPartages(id));
      unawaited(_marquerLu(id));
    }
  }

  Future<void> _chargerPartages(String id) async {
    setState(() => _partages = const AsyncValue<PartagesCanal>.loading());
    final AsyncValue<PartagesCanal> lus = await AsyncValue.guard<PartagesCanal>(
      () => _port.partages(id),
    );
    if (!mounted || widget.canalId != id) return;
    setState(() => _partages = lus);
  }

  Future<void> _marquerLu(String id) async {
    try {
      await _port.marquerLu(id);
    } on Object {
      // Le badge reste tel quel : rien n'est affirme.
      return;
    }
    await _chargerCanaux(silencieux: true);
  }

  Future<void> _envoyer(String canalId, String texte, String cle) async {
    await _port.envoyer(canalId, texte, cle);
    // L'ordre et les non-lus de la liste suivent le message confirme.
    unawaited(_chargerCanaux(silencieux: true));
  }

  Future<void> _chargerEnregistrements() async {
    EtatEnregistrements etat;
    try {
      final List<ElementEnregistre> elements = await ref
          .read(portElementsEnregistresProvider)
          .liste();
      etat = EtatEnregistrements.disponibles(<ObjetLie>{
        for (final ElementEnregistre e in elements) e.objet,
      });
    } on Object {
      // Capacite absente ou echec : l'action n'est pas proposee.
      etat = const EtatEnregistrements.indisponibles();
    }
    if (!mounted) return;
    setState(() => _enregistrements = etat);
  }

  Future<void> _basculerEnregistrement(ObjetLie objet) async {
    final EtatEnregistrements? etat = _enregistrements;
    if (etat == null || !etat.disponible) return;
    final PortElementsEnregistres port = ref.read(
      portElementsEnregistresProvider,
    );
    final bool retirer = etat.contient(objet);
    final e = t.com.studio.enregistrer;
    try {
      if (retirer) {
        await port.retirer(objet);
      } else {
        await port.enregistrer(objet);
      }
    } on Object {
      if (!mounted) return;
      setState(() => _retour = e.nonConfirme);
      return;
    }
    if (!mounted) return;
    final Set<ObjetLie> objets = <ObjetLie>{...etat.objets};
    if (retirer) {
      objets.remove(objet);
    } else {
      objets.add(objet);
    }
    setState(() {
      _enregistrements = EtatEnregistrements.disponibles(objets);
      _retour = retirer
          ? e.retire(titre: objet.libelle)
          : e.ajoute(titre: objet.libelle);
    });
  }

  void _auChangementRecherche() {
    final String texte = _recherche.text.trim();
    if (texte == _texteCherche) return;
    _texteCherche = texte;
    if (texte.isEmpty) {
      setState(() {
        _resultats = const AsyncValue<ResultatsStudio>.loading();
        _filtre = FiltreRechercheStudio.tout;
      });
      return;
    }
    unawaited(_chercher(texte));
  }

  Future<void> _chercher(String texte) async {
    final int numero = ++_numeroRecherche;
    setState(() => _resultats = const AsyncValue<ResultatsStudio>.loading());
    final AsyncValue<ResultatsStudio> lus =
        await AsyncValue.guard<ResultatsStudio>(
          () async => (await _port.rechercher(texte)).sansCanalAbsent(),
        );
    // Une reponse plus ancienne que la derniere saisie est ignoree.
    if (!mounted || numero != _numeroRecherche) return;
    setState(() => _resultats = lus);
  }

  void _fermerSurfaceRecherche() {
    _recherche.clear();
    setState(() => _surfaceRecherche = false);
  }

  /// Ouvre un canal (depuis la liste ou un resultat) : la recherche est
  /// videe pour montrer le canal choisi ; sur telephone, sa surface se
  /// referme, sur ordinateur le champ reste en place (persistant).
  void _ouvrirCanal(String id) {
    _recherche.clear();
    setState(() => _surfaceRecherche = false);
    widget.onOuvrirCanal(id);
  }

  @override
  Widget build(BuildContext context) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return PageStorage(
      bucket: ref.watch(positionsStudioProvider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (horsLigne) ...<Widget>[
            const BandeauHorsLigneCommunication(encadre: true),
            Ecart.vLg,
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints contraintes) =>
                  _espace(colonnesPour(contraintes.maxWidth), horsLigne),
            ),
          ),
        ],
      ),
    );
  }

  Widget _espace(int colonnes, bool horsLigne) {
    final String? canalId = widget.canalId;
    final List<ResumeCanal>? canaux = _canaux.hasValue && !_canaux.isLoading
        ? _canaux.value
        : null;
    final bool contenu = canaux != null && canaux.isNotEmpty;
    final bool recherche = _texteCherche.isNotEmpty;
    final Widget vueResultats = ResultatsRechercheStudio(
      texte: _texteCherche,
      resultats: _resultats,
      filtre: _filtre,
      onFiltre: (FiltreRechercheStudio f) => setState(() => _filtre = f),
      onOuvrirCanal: _ouvrirCanal,
      onReessayer: () => _chercher(_texteCherche),
      horsLigne: horsLigne,
    );

    Widget? liste;
    if (contenu) {
      if (colonnes == 1 && _surfaceRecherche) {
        liste = SurfaceRechercheStudio(
          controleur: _recherche,
          onFermer: _fermerSurfaceRecherche,
          resultats: recherche ? vueResultats : const SizedBox.shrink(),
        );
      } else {
        liste = ListeCanaux(
          canaux: canaux,
          // Ouvrir un canal depuis la liste ferme une recherche en cours :
          // c'est le canal qu'on veut voir, pas les resultats.
          onOuvrir: _ouvrirCanal,
          canalSelectionne: colonnes > 1 ? canalId : null,
          entete: colonnes > 1
              ? ChampRechercheStudio(controleur: _recherche)
              : LienFleche(
                  key: EspaceStudio.cleOuvrirRecherche,
                  libelle: t.com.studio.recherche.champ,
                  icone: AppIcons.recherche,
                  fleche: false,
                  onPress: () => setState(() => _surfaceRecherche = true),
                ),
        );
      }
    }
    final Widget etatListe = _etatListe(horsLigne);

    // Sur ordinateur et tablette, les resultats prennent la place du canal,
    // qui reste monte dessous (brouillon et lecture gardes).
    Widget principalAvecRecherche(Widget principal) {
      if (colonnes == 1) return principal;
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Offstage(offstage: recherche, child: principal),
          if (recherche) vueResultats,
        ],
      );
    }

    if (canalId == null) {
      return EspaceTravailAdaptatif(
        liste: colonnes == 1 ? (liste ?? etatListe) : liste,
        surfaceMobile: SurfaceMobile.liste,
        principal: contenu ? principalAvecRecherche(_choisir()) : etatListe,
      );
    }
    final Canal? canal = _canal.hasValue && !_canal.isLoading
        ? _canal.value
        : null;
    return EspaceTravailAdaptatif(
      liste: liste ?? etatListe,
      principal: principalAvecRecherche(_vueCanal(canalId, horsLigne)),
      titreContexte: t.com.studio.panneau.titre,
      contexte: canal == null || (recherche && colonnes > 1)
          ? null
          : PanneauPartages(
              key: ValueKey<String>('studio-panneau-${canal.id}'),
              canal: canal,
              partages: _partages,
              destinationCanal: widget.destinationCanal(canal.id),
              enregistrements: _enregistrements,
              onBasculerEnregistrement: _basculerEnregistrement,
              onOuvrir: widget.onOuvrir,
              retour: _retour,
              onReessayerPartages: () => _chargerPartages(canal.id),
              horsLigne: horsLigne,
            ),
    );
  }

  /// La colonne du canal quand aucun canal n'est ouvert : dire quoi faire,
  /// jamais une colonne vide.
  Widget _choisir() {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final s = t.com.studio;
    return Center(
      key: EspaceStudio.cleChoisir,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                s.choisirTitre,
                textAlign: TextAlign.center,
                style: palette.inkStrong.applyTo(
                  textes.titleMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vSm,
            Text(
              s.choisir,
              textAlign: TextAlign.center,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// L'etat de la liste quand elle n'a pas de contenu a montrer.
  Widget _etatListe(bool horsLigne) {
    final s = t.com.studio;
    if (_canaux.isLoading) {
      return const SingleChildScrollView(
        child: VueEtatCommunication(etat: EtatCommunication.chargement),
      );
    }
    if (_canaux.hasError) {
      return SingleChildScrollView(
        child: _vueErreur(_canaux.error!, horsLigne, _chargerCanaux),
      );
    }
    return SingleChildScrollView(
      child: VueEtatCommunication(
        etat: EtatCommunication.vide,
        titreVide: s.aucunCanalTitre,
        phraseVide: s.aucunCanal,
      ),
    );
  }

  /// La colonne du canal demande : chargement, erreur, indisponible ou
  /// canal.
  Widget _vueCanal(String canalId, bool horsLigne) {
    if (_canal.isLoading) {
      return const SingleChildScrollView(
        child: VueEtatCommunication(etat: EtatCommunication.chargement),
      );
    }
    if (_canal.hasError) {
      return SingleChildScrollView(
        child: _vueErreur(
          _canal.error!,
          horsLigne,
          () => _chargerCanal(canalId),
        ),
      );
    }
    final Canal? canal = _canal.value;
    if (canal == null) {
      // Retire, ou prive et non autorise : rien du canal n'est rendu, ni
      // nom, ni membre, ni message (R-COM-08). Une seule phrase pour les
      // deux, pour ne pas dire qu'un canal prive existe. La nature est
      // « introuvable », jamais « acces refuse » : son cadenas laisserait
      // entendre qu'un canal verrouille est la (sans cadenas, R-COM-08).
      final c = t.com.studio.canal;
      return SingleChildScrollView(
        child: EtatSysteme(
          key: EspaceStudio.cleCanalIndisponible,
          nature: NatureEtat.introuvable,
          titre: c.indisponibleTitre,
          phrase: c.indisponible,
          dependance: 'COM-BR-08',
        ),
      );
    }
    return CanalStudio(
      key: ValueKey<String>('studio-canal-${canal.id}'),
      canal: canal,
      onEnvoyer: (String texte, String cle) => _envoyer(canal.id, texte, cle),
    );
  }

  /// Une lecture en echec : capacite absente (sans « Reessayer »), hors
  /// ligne ou echec (avec « Reessayer »).
  Widget _vueErreur(Object erreur, bool horsLigne, VoidCallback reessayer) {
    if (erreur is CapaciteIndisponible) {
      return VueEtatCommunication(
        etat: EtatCommunication.indisponible,
        dependance: erreur.dependance,
      );
    }
    return VueEtatCommunication(
      etat: horsLigne ? EtatCommunication.horsLigne : EtatCommunication.erreur,
      onReessayer: reessayer,
    );
  }
}
