// Le Studio : les brouillons (`DraftPersistence`, COM-STU-2 ; spec
// section 8.2, section 20 ; contrat COM-BR-12).
//
// Sur `PortBrouillons` du socle, sans second stockage : en V1, la MEMOIRE DE
// SESSION (`BrouillonsMemoire`). Le brouillon survit a la navigation locale
// (changer de canal, passer par Aujourd'hui, revenir), pas a la fermeture de
// l'application ; aucune couche locale n'est approuvee pour le texte d'un
// message (`StockagePreferencesDrift` ne garde que des preferences), et
// aucune synchronisation entre appareils n'est promise : l'ecran le dit.
//
// Trois pieces :
//
// - [PersistanceBrouillonCanal] ecrit le texte du champ d'un canal dans le
//   port a chaque frappe, et le remet a la reouverture (« Brouillon
//   restaure ») ; un envoi vide le champ, donc efface le brouillon.
// - [BlocBrouillons] : le bloc « Brouillons » d'Aujourd'hui (les plus
//   recents, puis « Voir tous les brouillons »).
// - [VueBrouillonsStudio] : la vue « Brouillons » de la navigation du Studio.
//
// Seuls les brouillons de CANAUX sont ceux du Studio : un brouillon de fil de
// Messages metier ou de publication de la Communaute vit dans sa surface.
// Chaque brouillon ouvre son canal (sa destination canonique) ; un canal qui
// n'est plus ouvert a la personne est nomme « un canal qui n'est plus
// disponible », sans chevron, sans redire son nom (R-COM-08).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/communications/port_brouillons.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/communications/etats_communication.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import 'canal_page.dart' show horodatageCanal;
import 'port_activite_studio.dart';
import 'port_studio.dart';
import 'visibilite_canal.dart';

/// La cle du brouillon d'un canal.
CleBrouillon cleBrouillonCanal(String canalId) =>
    CleBrouillon(type: TypeObjetLie.canal, objetId: canalId);

/// Ce que l'on sait du canal d'un brouillon.
enum CanalDuBrouillon {
  /// Le canal est ouvert a la personne : il est nomme et s'ouvre.
  connu,

  /// La liste des canaux n'a pas pu etre lue : le brouillon s'ouvre, la
  /// page du canal dira s'il est encore la.
  inconnu,

  /// La liste est lue et le canal n'y est plus : ni nom, ni geste.
  indisponible,
}

/// Un brouillon du Studio, avec son canal resolu.
@immutable
class BrouillonStudio {
  /// Cree le brouillon resolu.
  const BrouillonStudio({
    required this.brouillon,
    required this.canal,
    this.nomCanal,
    this.destination,
  });

  /// Le brouillon garde.
  final Brouillon brouillon;

  /// Ce que l'on sait de son canal.
  final CanalDuBrouillon canal;

  /// Le nom du canal, s'il est connu.
  final String? nomCanal;

  /// La destination qui rouvre le canal ; `null` s'il n'est plus ouvert.
  final DestinationStudio? destination;
}

/// Les brouillons du Studio parmi [tous] (les brouillons de canaux), le plus
/// recent d'abord, resolus avec [canaux] (`null` si la liste n'a pas pu
/// etre lue). [destinationCanal] donne le chemin d'un canal.
List<BrouillonStudio> resoudreBrouillonsStudio(
  List<Brouillon> tous,
  List<ResumeCanal>? canaux,
  String Function(String canalId) destinationCanal,
) {
  final Map<String, ResumeCanal>? ouverts = canaux == null
      ? null
      : <String, ResumeCanal>{
          for (final ResumeCanal c in canauxRendus(
            canaux,
            (ResumeCanal c) => c.visibilite,
          ))
            c.id: c,
        };
  final List<Brouillon> duStudio =
      tous.where((Brouillon b) => b.cle.type == TypeObjetLie.canal).toList()
        ..sort(
          (Brouillon a, Brouillon b) => b.modifieLe.compareTo(a.modifieLe),
        );
  DestinationStudio ouvrir(String id) => DestinationStudio(
    chemin: destinationCanal(id),
    module: ModuleCanonique.studio,
  );
  return <BrouillonStudio>[
    for (final Brouillon b in duStudio)
      if (ouverts == null)
        BrouillonStudio(
          brouillon: b,
          canal: CanalDuBrouillon.inconnu,
          destination: ouvrir(b.cle.objetId),
        )
      else if (ouverts[b.cle.objetId] case final ResumeCanal c)
        BrouillonStudio(
          brouillon: b,
          canal: CanalDuBrouillon.connu,
          nomCanal: c.nom,
          destination: ouvrir(c.id),
        )
      else
        BrouillonStudio(brouillon: b, canal: CanalDuBrouillon.indisponible),
  ];
}

/// Le debut d'un brouillon, sur une ligne : les retours a la ligne deviennent
/// des espaces, et au-dela de [longueur] caracteres le texte s'arrete sur
/// « … ».
String extraitBrouillon(String texte, {int longueur = 80}) {
  final String ligne = texte.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (ligne.length <= longueur) return ligne;
  return '${ligne.substring(0, longueur).trimRight()}…';
}

/// Lit les brouillons du Studio : le port des brouillons (son echec est celui
/// du bloc), puis la liste des canaux pour les nommer (son echec laisse les
/// brouillons ouvrables, sans nom).
Future<List<BrouillonStudio>> lireBrouillonsStudio(
  PortBrouillons brouillons,
  PortStudio studio,
  String Function(String canalId) destinationCanal,
) async {
  final List<Brouillon> tous = await brouillons.tous();
  if (!tous.any((Brouillon b) => b.cle.type == TypeObjetLie.canal)) {
    return const <BrouillonStudio>[];
  }
  List<ResumeCanal>? canaux;
  try {
    canaux = await studio.canaux();
  } on Object {
    canaux = null;
  }
  return resoudreBrouillonsStudio(tous, canaux, destinationCanal);
}

/// La ligne d'un brouillon : ou il a ete ecrit, son debut, quand.
LigneRubrique ligneBrouillon(
  BrouillonStudio b,
  ValueChanged<DestinationStudio> onOuvrir,
) {
  final x = t.com.studio.brouillons;
  final String legende = <String>[
    extraitBrouillon(b.brouillon.texte),
    x.modifie(moment: horodatageCanal(b.brouillon.modifieLe)),
  ].join('\n');
  final String libelle = switch (b.canal) {
    CanalDuBrouillon.connu => x.dansCanal(nom: b.nomCanal ?? ''),
    CanalDuBrouillon.inconnu => x.canalInconnu,
    CanalDuBrouillon.indisponible => x.canalIndisponible,
  };
  final DestinationStudio? destination = b.destination;
  if (destination == null) {
    return LigneRubrique(
      icone: AppIcons.crayon,
      libelle: libelle,
      legende: legende,
    );
  }
  return LigneRubrique(
    icone: AppIcons.crayon,
    libelle: libelle,
    legende: legende,
    libelleSemantique: b.nomCanal == null
        ? null
        : x.reprendre(nom: b.nomCanal!),
    onPress: () => onOuvrir(destination),
  );
}

/// Le bloc « Brouillons » d'Aujourd'hui : les [maximum] plus recents, puis
/// « Voir tous les brouillons » s'il y en a davantage.
class BlocBrouillons extends StatelessWidget {
  /// Cree le bloc.
  const BlocBrouillons({
    required this.brouillons,
    required this.onOuvrir,
    required this.onVoirTous,
    required this.onReessayer,
    super.key,
    this.maximum = 3,
  });

  /// Les brouillons lus.
  final AsyncValue<List<BrouillonStudio>> brouillons;

  /// Ouvre le canal d'un brouillon.
  final ValueChanged<DestinationStudio> onOuvrir;

  /// Ouvre la vue de tous les brouillons.
  final VoidCallback onVoirTous;

  /// Relit les brouillons.
  final VoidCallback onReessayer;

  /// Le nombre de brouillons montres ici.
  final int maximum;

  /// La cle du lien « Voir tous les brouillons », pour les tests.
  static const ValueKey<String> cleVoirTous = ValueKey<String>(
    'studio-brouillons-tous',
  );

  @override
  Widget build(BuildContext context) {
    final a = t.com.studio.aujourdhui;
    final x = t.com.studio.brouillons;
    return BlocCommunication<List<BrouillonStudio>>(
      valeur: brouillons,
      onReessayer: onReessayer,
      // Le vide garde le titre du bloc : un bloc ne disparait pas.
      estVide: (List<BrouillonStudio> _) => false,
      construire: (List<BrouillonStudio> liste) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GroupeReglages(
            titre: a.blocs.brouillons,
            lignes: liste.isEmpty
                ? <LigneRubrique>[
                    LigneRubrique(icone: AppIcons.crayon, libelle: x.vide),
                  ]
                : <LigneRubrique>[
                    for (final BrouillonStudio b in liste.take(maximum))
                      ligneBrouillon(b, onOuvrir),
                  ],
          ),
          if (liste.length > maximum) ...<Widget>[
            Ecart.vSm,
            LienFleche(
              key: cleVoirTous,
              libelle: x.tous(nombre: liste.length),
              onPress: onVoirTous,
            ),
          ],
        ],
      ),
    );
  }
}

/// La vue « Brouillons » du Studio : tous les brouillons de canaux.
class VueBrouillonsStudio extends ConsumerStatefulWidget {
  /// Cree la vue.
  const VueBrouillonsStudio({
    required this.onOuvrir,
    required this.destinationCanal,
    super.key,
  });

  /// Ouvre le canal d'un brouillon.
  final ValueChanged<DestinationStudio> onOuvrir;

  /// Le chemin d'un canal.
  final String Function(String canalId) destinationCanal;

  /// La cle du groupe des brouillons, pour les tests.
  static const ValueKey<String> cleListe = ValueKey<String>(
    'studio-brouillons-liste',
  );

  @override
  ConsumerState<VueBrouillonsStudio> createState() =>
      _VueBrouillonsStudioState();
}

class _VueBrouillonsStudioState extends ConsumerState<VueBrouillonsStudio> {
  AsyncValue<List<BrouillonStudio>> _brouillons =
      const AsyncValue<List<BrouillonStudio>>.loading();

  @override
  void initState() {
    super.initState();
    unawaited(_charger());
  }

  Future<void> _charger() async {
    setState(
      () => _brouillons = const AsyncValue<List<BrouillonStudio>>.loading(),
    );
    final AsyncValue<List<BrouillonStudio>> lus =
        await AsyncValue.guard<List<BrouillonStudio>>(
          () => lireBrouillonsStudio(
            ref.read(portBrouillonsProvider),
            ref.read(portStudioProvider),
            widget.destinationCanal,
          ),
        );
    if (!mounted) return;
    setState(() => _brouillons = lus);
  }

  @override
  Widget build(BuildContext context) {
    final x = t.com.studio.brouillons;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: <Widget>[
        // Hors ligne : les brouillons sont sur l'appareil, ils restent lus.
        if (horsLigne) ...<Widget>[
          const BandeauHorsLigneCommunication(encadre: true),
          Ecart.vLg,
        ],
        Text(
          x.detail,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vLg,
        BlocCommunication<List<BrouillonStudio>>(
          valeur: _brouillons,
          onReessayer: _charger,
          titreVide: x.videTitre,
          phraseVide: x.vide,
          construire: (List<BrouillonStudio> liste) => GroupeReglages(
            key: VueBrouillonsStudio.cleListe,
            lignes: <LigneRubrique>[
              for (final BrouillonStudio b in liste)
                ligneBrouillon(b, widget.onOuvrir),
            ],
          ),
        ),
      ],
    );
  }
}

/// Garde le texte du champ d'un canal comme brouillon, et le remet a la
/// reouverture.
///
/// Le champ est celui de `FilDiscussion` (socle), qui ne l'expose pas : la
/// persistance le trouve dans ses descendants, comme le canal y trouve deja
/// sa zone defilante (`canal_page.dart`). Une ligne COM-FUS demande au socle
/// un parametre « texte initial et changement » pour s'en passer.
///
/// [constructeur] recoit vrai tant que le brouillon restaure n'a pas ete
/// modifie : le canal le dit (« Brouillon restaure »).
class PersistanceBrouillonCanal extends ConsumerStatefulWidget {
  /// Cree la persistance du canal [canalId].
  const PersistanceBrouillonCanal({
    required this.canalId,
    required this.constructeur,
    super.key,
  });

  /// Le canal dont le champ est garde.
  final String canalId;

  /// Construit le canal ; `restaure` est vrai tant que le brouillon remis
  /// n'a pas ete touche.
  final Widget Function(BuildContext context, bool restaure) constructeur;

  @override
  ConsumerState<PersistanceBrouillonCanal> createState() =>
      _PersistanceBrouillonCanalState();
}

class _PersistanceBrouillonCanalState
    extends ConsumerState<PersistanceBrouillonCanal> {
  TextEditingController? _champ;
  late PortBrouillons _port;
  String _dernier = '';
  bool _restaure = false;

  CleBrouillon get _cle => cleBrouillonCanal(widget.canalId);

  @override
  void initState() {
    super.initState();
    _port = ref.read(portBrouillonsProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _brancher());
  }

  @override
  void dispose() {
    // Le champ appartient a `FilDiscussion`, souvent libere avant nous :
    // retirer une ecoute d'un `ChangeNotifier` libere est permis.
    _champ?.removeListener(_auChangement);
    super.dispose();
  }

  TextEditingController? _trouverChamp() {
    if (!mounted) return null;
    TextEditingController? trouve;
    void visiter(Element e) {
      if (trouve != null) return;
      final Widget w = e.widget;
      if (w is EditableText) {
        trouve = w.controller;
        return;
      }
      e.visitChildren(visiter);
    }

    (context as Element).visitChildren(visiter);
    return trouve;
  }

  Future<void> _brancher() async {
    final TextEditingController? champ = _trouverChamp();
    // Un canal en lecture seule n'a pas de champ : rien a garder.
    if (champ == null) return;
    _champ = champ;
    Brouillon? garde;
    try {
      garde = await _port.lire(_cle);
    } on Object {
      garde = null;
    }
    if (!mounted || _champ != champ) return;
    final Brouillon? b = garde;
    if (b != null && champ.text.isEmpty) {
      champ.value = TextEditingValue(
        text: b.texte,
        selection: TextSelection.collapsed(offset: b.texte.length),
      );
      setState(() => _restaure = true);
    }
    _dernier = champ.text;
    champ.addListener(_auChangement);
  }

  void _auChangement() {
    final TextEditingController? champ = _champ;
    if (champ == null) return;
    final String texte = champ.text;
    if (texte == _dernier) return;
    _dernier = texte;
    if (_restaure && mounted) setState(() => _restaure = false);
    // Un texte vide (apres un envoi, ou tout efface) efface le brouillon.
    unawaited(
      _port.enregistrer(_cle, texte).catchError((Object _) {
        // Le brouillon n'est pas garde ; le texte reste dans le champ.
      }),
    );
  }

  @override
  Widget build(BuildContext context) => widget.constructeur(context, _restaure);
}
