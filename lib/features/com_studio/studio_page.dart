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
// Mode focus (COM-W03F, COM-M05 ; spec section 10, section 20, section 23 ;
// COM-STU-3, dossier `focus/`) : un ETAT local du canal ouvert, jamais une
// route ni le plein ecran du navigateur. La coquille porte l'etat
// (`EtatFocusStudio`) ; en Focus, elle retire sa navigation (colonne, rail,
// barre basse), son titre, son disque retour et les actions de coquille, et
// ne pose au-dessus du canal que le bandeau de sortie (« Le Studio »,
// « Focus active », « Quitter le focus »). L'espace des canaux retire la
// liste, la recherche et le panneau de contexte, et centre le fil a la
// largeur de lecture (« Contenu centre + composer + sortie », section 23).
// Le bandeau hors ligne et les erreurs du fil restent. Le contenu de la
// coquille garde son sous-arbre d'une disposition a l'autre (cle globale) :
// canal, fil, brouillon, envois en attente, recherche et panneau ne sont
// jamais reconstruits ; le restaurateur remet la position de lecture, que le
// changement de largeur deplace. Sortie : « Quitter le focus », Echap sans
// dialogue prioritaire, retour explicite du telephone.
//
// Etats (spec section 25) : chargement (squelette), contenu, vide (« Aucun
// canal pour le moment »), erreur (« Reessayer »), hors ligne (bandeau des
// communications, contenu deja lu garde), capacite indisponible (port
// neutre, sans « Reessayer »), canal retire ou prive non autorise (rien du
// canal n'est rendu, R-COM-08), envoi en cours, envoi non confirme
// (R-COM-13), non lu (badge), panneau de contexte ferme, Focus.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/communications/port_elements_enregistres.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/espace_travail_adaptatif.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/nav_shell.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/surface_recherche.dart';
import '../../core/widgets/vue_etat_communication.dart';
import '../com_vocal/envoi_vocal.dart';
import '../com_vocal/port_enregistreur_vocal.dart';
import 'aujourdhui_page.dart';
import 'brouillons_studio.dart';
import 'canal_page.dart';
import 'elements_enregistres_studio.dart';
import 'focus/bascule_focus.dart';
import 'focus/restauration_focus.dart';
import 'focus/sortie_focus.dart';
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
      onCompte: () => routeur.go(Routes.compte),
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
///
/// Elle porte aussi le Mode focus du canal ouvert ([EtatFocusStudio]) :
/// en Focus, sa navigation, son titre et son retour s'effacent derriere le
/// bandeau de sortie, et son contenu garde son etat.
class CoquilleStudio extends StatefulWidget {
  /// Cree la coquille.
  const CoquilleStudio({
    required this.vue,
    required this.onAllerVue,
    required this.onQuitter,
    required this.child,
    super.key,
    this.onRetourListe,
    this.sousTitre,
    this.focusInitial = false,
    this.onCompte,
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

  /// Ouvre le canal deja en Focus (la demonstration « Mode focus ») ; sans
  /// canal ouvert, sans effet.
  final bool focusInitial;

  /// Ouvre « Mon compte » ; donne, la colonne de navigation porte, sous les
  /// vues, l'identite de la personne connectee (« Administrateur », comme le
  /// pied de l'`AdminShell`), qui y mene (revue COM-R, R-05). Nul (la
  /// demonstration) : aucune identite.
  final VoidCallback? onCompte;

  /// L'entree d'identite de la colonne (« Administrateur »), vers le compte.
  static Destination identite() => Destination(
    libelle: t.compte.roles.admin,
    icone: AppIcons.profil,
    chemin: Routes.compte,
  );

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
  State<CoquilleStudio> createState() => _CoquilleStudioState();
}

class _CoquilleStudioState extends State<CoquilleStudio> {
  final EtatFocusStudio _focus = EtatFocusStudio();

  /// Le contenu change de parent quand la navigation s'efface : cette cle
  /// le deplace avec tout son etat (canal, fil, champ, recherche, panneau).
  final GlobalKey _cleContenu = GlobalKey(debugLabel: 'studio-contenu');

  /// Le Focus n'a de sens que dans un canal ouvert.
  bool get _canalOuvert =>
      widget.vue == VueStudio.canaux && widget.onRetourListe != null;

  @override
  void initState() {
    super.initState();
    if (widget.focusInitial && _canalOuvert) _focus.entrer();
  }

  @override
  void didUpdateWidget(CoquilleStudio ancien) {
    super.didUpdateWidget(ancien);
    // Une autre vue, ou le canal referme : le Focus prend fin, sans
    // restauration (la personne est allee ailleurs).
    if (!_canalOuvert) _focus.quitterPlusTard();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PorteeFocusStudio(
    etat: _focus,
    child: ListenableBuilder(
      listenable: _focus,
      builder: (BuildContext context, Widget? _) {
        final bool focus = _focus.actif && _canalOuvert;
        final Widget contenu = KeyedSubtree(
          key: _cleContenu,
          child: widget.child,
        );
        return GardeSortieFocus(
          actif: focus,
          onQuitter: _focus.quitter,
          child: focus ? _enFocus(contenu) : _coquille(context, contenu),
        );
      },
    ),
  );

  /// En Focus : ni navigation, ni titre, ni retour, ni actions de coquille
  /// (cloche) ; le contenu seul. Le bandeau de sortie est pose par l'espace
  /// des canaux, dans la MEME colonne centree que le fil (revue COM-R,
  /// R-12) : il s'aligne sur le fil a toutes les largeurs.
  ///
  /// Il reste le premier element d'un CORPS non defilant, jamais l'`entete`
  /// de la page : sur telephone a texte agrandi (200 %) ou sur une vue tres
  /// basse, `PageShell` fait defiler sa tete avec le corps, et « Quitter le
  /// focus » sortait de l'ecran pendant la lecture. Sans titre ni entete, la
  /// tete n'est plus qu'une respiration ; le bandeau, pose juste dessous,
  /// reste donc toujours entier a l'ecran (section 10.6, R-COM-09). Seul le
  /// fil defile.
  Widget _enFocus(Widget contenu) => PageShell(
    actionsCoquille: false,
    defilante: false,
    // D-FUS-3 : le corps du Focus pose le bandeau des Communications.
    bandeauHorsLigne: const SizedBox.shrink(),
    child: contenu,
  );

  Widget _coquille(BuildContext context, Widget contenu) {
    final VueStudio vue = widget.vue;
    final VoidCallback? onRetourListe = widget.onRetourListe;
    final List<Destination> d = CoquilleStudio.destinations();
    final VoidCallback? onCompte = widget.onCompte;
    return NavShell(
      destinations: d,
      indexActif: VueStudio.values.indexOf(vue),
      onAller: (String chemin) => widget.onAllerVue(vueStudioDepuis(chemin)),
      // L'identite et l'acces au compte, sous les vues (R-05) ; la barre
      // basse du telephone ne la porte pas : « Mon compte » est alors dans
      // les actions de l'en-tete.
      secondaires: onCompte == null
          ? const <Destination>[]
          : <Destination>[CoquilleStudio.identite()],
      onAllerSecondaire: onCompte == null ? null : (String _) => onCompte(),
      // Sur telephone, un canal ouvert est une tache focalisee : la barre
      // basse s'efface, le disque retour ramene a la liste, et le fil garde
      // sa hauteur au-dessus du clavier (R-COM-15).
      masquerBarreBasse: onRetourListe != null,
      child: PageShell(
        // D-FUS-3 : chaque vue du Studio pose le bandeau des Communications.
        bandeauHorsLigne: const SizedBox.shrink(),
        titre: switch (vue) {
          VueStudio.aujourdhui => t.com.studio.aujourdhui.titre,
          VueStudio.canaux => t.com.studio.titre,
          VueStudio.enregistres => t.com.studio.navigation.enregistres,
          VueStudio.brouillons => t.com.studio.brouillons.titre,
        },
        sousTitre:
            widget.sousTitre ??
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
          _ => widget.onQuitter,
        },
        defilante: false,
        child: contenu,
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

  /// La colonne centree du canal (le fil, et en Focus son bandeau de
  /// sortie), pour les tests.
  static const ValueKey<String> cleCentre = ValueKey<String>('studio-centre');

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

  /// Le panneau de contexte est-il ouvert ? Suivi a chaque bascule, et
  /// rendu a l'espace adaptatif comme etat de depart s'il est reconstruit.
  bool _panneauOuvert = true;

  /// Le Focus du Studio qui entoure l'espace ; nul hors d'un Studio.
  EtatFocusStudio? _focus;

  /// La recherche locale (texte, filtre, surface ouverte), gardee pendant le
  /// Focus, qui la masque.
  late final SourceValeur<(TextEditingValue, FiltreRechercheStudio, bool)>
  _sourceRecherche =
      SourceValeur<(TextEditingValue, FiltreRechercheStudio, bool)>(
        lire: () => (_recherche.value, _filtre, _surfaceRecherche),
        ecrire: ((TextEditingValue, FiltreRechercheStudio, bool) v) {
          if (_recherche.value != v.$1) _recherche.value = v.$1;
          setState(() {
            _filtre = v.$2;
            _surfaceRecherche = v.$3;
          });
        },
      );

  /// Le panneau droit (ouvert ou ferme), garde pendant le Focus, qui le
  /// retire.
  late final SourceValeur<bool> _sourcePanneau = SourceValeur<bool>(
    lire: () => _panneauOuvert,
    ecrire: (bool ouvert) => setState(() => _panneauOuvert = ouvert),
  );

  /// La cle de la source « recherche » aupres du restaurateur du Focus.
  static const String cleSourceRecherche = 'espace-recherche';

  /// La cle de la source « panneau ».
  static const String cleSourcePanneau = 'espace-panneau';

  PortStudio get _port => ref.read(portStudioProvider);

  /// Le fil dans sa colonne centree : il garde sa place (et son etat)
  /// quand le bandeau de sortie apparait au-dessus de lui.
  static const Key _cleFilCentre = ValueKey<String>('studio-centre-fil');

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final EtatFocusStudio? focus = PorteeFocusStudio.de(context);
    if (!identical(focus, _focus)) {
      _retirerSources();
      _focus = focus;
      focus?.restaurateur
        ?..inscrire(cleSourceRecherche, _sourceRecherche)
        ..inscrire(cleSourcePanneau, _sourcePanneau);
    }
  }

  @override
  void didUpdateWidget(EspaceStudio ancien) {
    super.didUpdateWidget(ancien);
    final String? id = widget.canalId;
    if (id != ancien.canalId) {
      // Un autre canal : le Focus du precedent prend fin, sans restauration.
      _focus?.quitterPlusTard();
      if (id != null) _chargerCanal(id);
    }
  }

  void _retirerSources() {
    _focus?.restaurateur
      ?..retirer(cleSourceRecherche, _sourceRecherche)
      ..retirer(cleSourcePanneau, _sourcePanneau);
  }

  @override
  void dispose() {
    _retirerSources();
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

  /// L'envoi d'un vocal (COM-FUS) : par le port des vocaux (COM-BR-03),
  /// neutre en production ; la liste suit le vocal confirme.
  Future<void> _envoyerVocal(
    String canalId,
    EnregistrementVocal vocal,
    String cle,
  ) async {
    await ref
        .read(portEnvoiVocalProvider)
        .envoyer(
          destination: DestinationVocal.canal(canalId),
          vocal: vocal,
          cleIdempotence: cle,
        );
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
    // En Focus, le bandeau hors ligne passe sous le bandeau de sortie, dans
    // la colonne centree du fil (R-12).
    final bool focus = widget.canalId != null && (_focus?.actif ?? false);
    return PageStorage(
      bucket: ref.watch(positionsStudioProvider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (horsLigne && !focus) ...<Widget>[
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
    // En Focus (canal ouvert seulement) : ni liste, ni recherche, ni
    // panneau ; le fil centre a la largeur de lecture.
    final bool focus = canalId != null && (_focus?.actif ?? false);
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
        liste = SurfaceRecherche(
          key: ClesRechercheStudio.surface,
          controleur: _recherche,
          libelle: t.com.studio.recherche.champ,
          aide: t.com.studio.recherche.aide,
          cleChamp: ClesRechercheStudio.champ,
          cleEffacer: ClesRechercheStudio.effacer,
          cleFermer: ClesRechercheStudio.fermer,
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
              ? ChampRecherche(
                  controleur: _recherche,
                  libelle: t.com.studio.recherche.champ,
                  aide: t.com.studio.recherche.aide,
                  cleChamp: ClesRechercheStudio.champ,
                  cleEffacer: ClesRechercheStudio.effacer,
                )
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
    // qui reste monte dessous (brouillon et lecture gardes). La forme ne
    // change pas avec le nombre de colonnes, que l'entree dans le Focus peut
    // faire varier (la navigation rend sa largeur) : le canal garde son
    // etat. En Focus, les resultats s'effacent, la recherche reste gardee.
    final bool resultatsVisibles = recherche && colonnes > 1 && !focus;
    Widget principalAvecRecherche(Widget principal) => Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Offstage(offstage: resultatsVisibles, child: principal),
        if (resultatsVisibles) vueResultats,
      ],
    );

    // « Contenu centre + composer + sortie » en Focus (section 23) : le fil a
    // la largeur de lecture, centre, et le bandeau de sortie au-dessus de lui
    // dans la MEME colonne (R-12) : ses bords sont ceux du fil. Meme forme
    // hors Focus, a toute la largeur : le canal recoit toujours une taille
    // fixe, et garde son etat d'une disposition a l'autre (colonne cle).
    Widget centre(Widget principal) => LayoutBuilder(
      builder: (BuildContext _, BoxConstraints c) => Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          key: EspaceStudio.cleCentre,
          width: focus
              ? math.min(c.maxWidth, AppPage.largeurLecture)
              : c.maxWidth,
          height: c.maxHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (focus) ...<Widget>[
                const BandeauSortieFocus(),
                Ecart.vXl,
                if (horsLigne) ...<Widget>[
                  const BandeauHorsLigneCommunication(encadre: true),
                  Ecart.vLg,
                ],
              ],
              Expanded(key: _cleFilCentre, child: principal),
            ],
          ),
        ),
      ),
    );

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
      liste: focus ? null : liste ?? etatListe,
      principal: principalAvecRecherche(centre(_vueCanal(canalId, horsLigne))),
      // R-02 : un canal rendu pose (i) dans la rangee de son en-tete, au
      // lieu d'une rangee a part qui lui prend de la hauteur.
      barreDansEntete: canal != null,
      titreContexte: t.com.studio.panneau.titre,
      contexteOuvertInitial: _panneauOuvert,
      onContexteBascule: (bool ouvert) => _panneauOuvert = ouvert,
      contexte: focus || canal == null || resultatsVisibles
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
  /// jamais une colonne vide (vue partagee, R-23).
  Widget _choisir() => VueChoisirCommunication(
    key: EspaceStudio.cleChoisir,
    titre: t.com.studio.choisirTitre,
    phrase: t.com.studio.choisir,
  );

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
        child: VueEtatCommunication.depuisErreur(
          _canaux.error!,
          horsLigne: horsLigne,
          onReessayer: _chargerCanaux,
        ),
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
        child: VueEtatCommunication.depuisErreur(
          _canal.error!,
          horsLigne: horsLigne,
          onReessayer: () => _chargerCanal(canalId),
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
      // COM-FUS : le composer vocal seulement si la capacite `envoyerVocal`
      // est ouverte (COM-BR-16) ; fermee en production, rien n'est rendu.
      onEnvoyerVocal: vocalOuvert(ref)
          ? (EnregistrementVocal v, String cle) =>
                _envoyerVocal(canal.id, v, cle)
          : null,
    );
  }
}
