// Le Studio, Aujourd'hui (`StudioTodayBoard`, COM-W00, COM-M04 ; spec
// section 7, section 8.1, section 8.2, section 17 COM-W00, section 25 ;
// contrat COM-BR-15 ; R-COM-11).
//
// L'accueil du Studio (`/admin/studio`, spec section 14 « Studio
// Aujourd'hui : accueil Studio »). Un AGREGATEUR D'ATTENTION, pas un
// deuxieme centre operationnel : chaque ligne ouvre son module canonique
// (Finance, Planning, dossier, Classe, Admissions), aucune action metier
// n'est executee ici (R-COM-11). Une ligne sans page (Finance, Planning) est
// nommee sans chevron.
//
// Sept blocs (spec section 7) : A traiter aujourd'hui, Mentions et reponses,
// Decisions en attente, Echeances proches, Activite recente, Brouillons,
// Acces rapides ; au-dessus, les indicateurs d'attention (COM-W00). Une
// ligne d'activite n'est rangee que dans UN bloc (`ActiviteStudio.rubrique`).
//
// Aucune maquette COM-W00 ni COM-M04 dans le dossier (QUESTIONS Q3) : la
// composition suit le texte de la spec et la navigation de la maquette
// sombre (Aujourd'hui en tete de la navigation du Studio). Theme Rewayah
// seul.
//
// - ordinateur : indicateurs, puis trois colonnes fonctionnelles (A traiter
//   et Mentions | Decisions, Echeances et Activite | Brouillons et Acces
//   rapides) ;
// - tablette : deux colonnes ;
// - telephone : une colonne, les blocs dans l'ordre de la spec.
//
// Etats : chargement (squelette), contenu, vide (« Aucune activite a traiter
// ici. », brouillons et acces rapides gardes), erreur (« Reessayer »), hors
// ligne (bandeau ; contenu deja lu garde ; une lecture en echec dit la
// connexion), capacite indisponible (port neutre, sans « Reessayer »),
// erreur partielle (les brouillons ont leur propre etat), non lu et action
// requise (badge texte et icone).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/port_brouillons.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/espace_travail_adaptatif.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/stat_tile.dart';
import '../../core/widgets/vue_etat_communication.dart';
import 'activite.dart';
import 'brouillons_studio.dart';
import 'port_activite_studio.dart';
import 'port_studio.dart';
import 'visibilite_canal.dart';

/// Un acces rapide : un module canonique deja livre, jamais un module sans
/// page (un bouton qui ne peut pas aboutir n'est pas rendu).
@immutable
class AccesRapideStudio {
  /// Cree l'acces.
  const AccesRapideStudio({
    required this.libelle,
    required this.detail,
    required this.icone,
    required this.destination,
  });

  /// Le nom du module.
  final String libelle;

  /// Ce qu'on y trouve.
  final String detail;

  /// L'icone du module.
  final AppIcon icone;

  /// Ou il s'ouvre.
  final DestinationStudio destination;
}

/// Les acces rapides du Studio, vers les modules de l'administration qui ont
/// une page. Finance et Planning n'en ont pas : ils n'y sont pas.
List<AccesRapideStudio> accesRapidesStudio() {
  final x = t.com.studio.aujourdhui.acces;
  return <AccesRapideStudio>[
    AccesRapideStudio(
      libelle: x.messages,
      detail: x.messagesDetail,
      icone: AppIcons.discussion,
      destination: const DestinationStudio(
        chemin: Routes.adminCommunicationsMessages,
        module: ModuleCanonique.communications,
      ),
    ),
    AccesRapideStudio(
      libelle: x.annonces,
      detail: x.annoncesDetail,
      icone: AppIcons.notifications,
      destination: const DestinationStudio(
        chemin: Routes.adminCommunicationsAnnonces,
        module: ModuleCanonique.communications,
      ),
    ),
    AccesRapideStudio(
      libelle: x.dossiers,
      detail: x.dossiersDetail,
      icone: AppIcons.dossiers,
      destination: const DestinationStudio(
        chemin: Routes.adminPersonnesDossiers,
        module: ModuleCanonique.dossiers,
      ),
    ),
    AccesRapideStudio(
      libelle: x.classes,
      detail: x.classesDetail,
      icone: AppIcons.classes,
      destination: const DestinationStudio(
        chemin: Routes.adminOperationsGroupes,
        module: ModuleCanonique.classes,
      ),
    ),
    AccesRapideStudio(
      libelle: x.demandes,
      detail: x.demandesDetail,
      icone: AppIcons.reaffectation,
      destination: const DestinationStudio(
        chemin: Routes.adminOperationsDemandes,
        module: ModuleCanonique.demandes,
      ),
    ),
  ];
}

/// Ne garde que les lignes qui ne viennent pas d'un canal absent pour la
/// personne (defense de surface, R-COM-08) : avec la liste des canaux
/// ouverts [ouverts] (nulle si elle n'a pas pu etre lue, le serveur fait
/// alors foi), une ligne qui vise un canal hors de la liste n'est pas rendue.
List<ActiviteStudio> activitesRendues(
  List<ActiviteStudio> activites,
  Set<String>? ouverts,
) {
  if (ouverts == null) return activites;
  return <ActiviteStudio>[
    for (final ActiviteStudio a in activites)
      if (a.objet.type != TypeObjetLie.canal || ouverts.contains(a.objet.id)) a,
  ];
}

/// Le tableau Aujourd'hui du Studio (`StudioTodayBoard`).
///
/// Sans route : la page routee et la demonstration le posent, chacune avec
/// sa facon d'ouvrir une destination ([onOuvrir]).
class TableauAujourdhui extends ConsumerStatefulWidget {
  /// Cree le tableau.
  const TableauAujourdhui({
    required this.onOuvrir,
    required this.onVoirBrouillons,
    required this.destinationCanal,
    super.key,
  });

  /// Ouvre une destination canonique (module, canal).
  final ValueChanged<DestinationStudio> onOuvrir;

  /// Ouvre la vue de tous les brouillons.
  final VoidCallback onVoirBrouillons;

  /// Le chemin d'un canal du Studio.
  final String Function(String canalId) destinationCanal;

  /// La cle des indicateurs d'attention, pour les tests.
  static const ValueKey<String> cleIndicateurs = ValueKey<String>(
    'studio-aujourdhui-indicateurs',
  );

  /// La cle du bloc des acces rapides, pour les tests.
  static const ValueKey<String> cleAcces = ValueKey<String>(
    'studio-aujourdhui-acces',
  );

  /// La cle de l'etat de l'activite (vide, erreur, indisponible), pour les
  /// tests.
  static const ValueKey<String> cleEtat = ValueKey<String>(
    'studio-aujourdhui-etat',
  );

  /// La cle d'une colonne du tableau (0, 1, 2), pour les tests.
  static ValueKey<String> cleColonne(int i) =>
      ValueKey<String>('studio-aujourdhui-colonne-$i');

  /// La cle du bloc d'une rubrique, pour les tests.
  static ValueKey<String> cleBloc(RubriqueAujourdhui r) =>
      ValueKey<String>('studio-aujourdhui-bloc-${r.name}');

  /// La cle du bloc des brouillons, pour les tests.
  static const ValueKey<String> cleBrouillons = ValueKey<String>(
    'studio-aujourdhui-brouillons',
  );

  @override
  ConsumerState<TableauAujourdhui> createState() => _TableauAujourdhuiState();
}

class _TableauAujourdhuiState extends ConsumerState<TableauAujourdhui> {
  AsyncValue<List<ActiviteStudio>> _activites =
      const AsyncValue<List<ActiviteStudio>>.loading();
  AsyncValue<List<BrouillonStudio>> _brouillons =
      const AsyncValue<List<BrouillonStudio>>.loading();

  @override
  void initState() {
    super.initState();
    unawaited(_charger());
  }

  /// La liste des canaux ouverts, ou `null` si elle n'a pas pu etre lue.
  Future<List<ResumeCanal>?> _canaux() async {
    try {
      return canauxRendus(
        await ref.read(portStudioProvider).canaux(),
        (ResumeCanal c) => c.visibilite,
      );
    } on Object {
      return null;
    }
  }

  Future<void> _charger() async {
    setState(() {
      _activites = const AsyncValue<List<ActiviteStudio>>.loading();
      _brouillons = const AsyncValue<List<BrouillonStudio>>.loading();
    });
    final Future<List<ResumeCanal>?> canauxLus = _canaux();
    final Future<AsyncValue<List<ActiviteStudio>>> activitesLues =
        AsyncValue.guard<List<ActiviteStudio>>(
          () => ref.read(portActiviteStudioProvider).activites(),
        );
    final Future<AsyncValue<List<Brouillon>>> brouillonsLus =
        AsyncValue.guard<List<Brouillon>>(
          () => ref.read(portBrouillonsProvider).tous(),
        );
    final List<ResumeCanal>? canaux = await canauxLus;
    final AsyncValue<List<ActiviteStudio>> activites = await activitesLues;
    final AsyncValue<List<Brouillon>> brouillons = await brouillonsLus;
    if (!mounted) return;
    final Set<String>? ouverts = canaux == null
        ? null
        : <String>{for (final ResumeCanal c in canaux) c.id};
    setState(() {
      _activites = activites.whenData(
        (List<ActiviteStudio> a) => activitesRendues(a, ouverts),
      );
      _brouillons = brouillons.whenData(
        (List<Brouillon> b) =>
            resoudreBrouillonsStudio(b, canaux, widget.destinationCanal),
      );
    });
  }

  Future<void> _rechargerBrouillons() async {
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

  /// Ouvre une ligne dans son module, et la marque lue. Le Studio n'execute
  /// rien d'autre (R-COM-11).
  void _ouvrirActivite(ActiviteStudio activite, DestinationStudio destination) {
    if (!activite.lu) unawaited(_marquerLu(activite));
    widget.onOuvrir(destination);
  }

  Future<void> _marquerLu(ActiviteStudio activite) async {
    try {
      await ref.read(portActiviteStudioProvider).marquerLu(activite.id);
    } on Object {
      // Le badge reste « non lu » : rien n'est affirme sans accuse.
      return;
    }
    if (!mounted) return;
    final List<ActiviteStudio>? liste = _activites.value;
    if (liste == null) return;
    setState(() {
      _activites = AsyncValue<List<ActiviteStudio>>.data(<ActiviteStudio>[
        for (final ActiviteStudio a in liste)
          a.id == activite.id ? a.marqueeLue() : a,
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        final int colonnes = colonnesPour(contraintes.maxWidth);
        final List<ActiviteStudio>? activites =
            _activites.hasValue && !_activites.isLoading
            ? _activites.value
            : null;
        final bool contenu = activites != null && activites.isNotEmpty;
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          children: <Widget>[
            if (horsLigne) ...<Widget>[
              const BandeauHorsLigneCommunication(encadre: true),
              Ecart.vLg,
            ],
            if (contenu) ...<Widget>[
              _Indicateurs(
                rangees: rangerActivites(activites),
                nonLus: activites.where((ActiviteStudio a) => !a.lu).length,
                colonnes: colonnes,
              ),
              Ecart.vXxl,
            ],
            _disposer(
              colonnes,
              contenu ? _blocs(activites) : null,
              _etatActivite(horsLigne),
            ),
          ],
        );
      },
    );
  }

  /// Les cinq blocs d'activite, dans l'ordre de la spec.
  List<Widget> _blocs(List<ActiviteStudio> activites) {
    final a = t.com.studio.aujourdhui;
    final Map<RubriqueAujourdhui, List<ActiviteStudio>> rangees =
        rangerActivites(activites);
    Widget bloc(RubriqueAujourdhui r, String titre, String vide) =>
        BoiteActivite(
          key: TableauAujourdhui.cleBloc(r),
          titre: titre,
          vide: vide,
          activites: rangees[r]!,
          onOuvrir: _ouvrirActivite,
        );
    return <Widget>[
      bloc(
        RubriqueAujourdhui.aTraiter,
        a.blocs.aTraiter,
        a.videsBlocs.aTraiter,
      ),
      bloc(
        RubriqueAujourdhui.mentions,
        a.blocs.mentions,
        a.videsBlocs.mentions,
      ),
      bloc(
        RubriqueAujourdhui.decisions,
        a.blocs.decisions,
        a.videsBlocs.decisions,
      ),
      bloc(
        RubriqueAujourdhui.echeances,
        a.blocs.echeances,
        a.videsBlocs.echeances,
      ),
      bloc(
        RubriqueAujourdhui.activite,
        a.blocs.activite,
        a.videsBlocs.activite,
      ),
    ];
  }

  /// L'etat de l'activite quand elle n'a pas de contenu a montrer.
  Widget _etatActivite(bool horsLigne) {
    final a = t.com.studio.aujourdhui;
    if (_activites.isLoading) {
      return const VueEtatCommunication(
        key: TableauAujourdhui.cleEtat,
        etat: EtatCommunication.chargement,
      );
    }
    final Object? erreur = _activites.error;
    if (erreur != null) {
      if (erreur is CapaciteIndisponible) {
        return VueEtatCommunication(
          key: TableauAujourdhui.cleEtat,
          etat: EtatCommunication.indisponible,
          dependance: erreur.dependance,
        );
      }
      return VueEtatCommunication(
        key: TableauAujourdhui.cleEtat,
        etat: horsLigne
            ? EtatCommunication.horsLigne
            : EtatCommunication.erreur,
        onReessayer: _charger,
      );
    }
    return VueEtatCommunication(
      key: TableauAujourdhui.cleEtat,
      etat: EtatCommunication.vide,
      titreVide: a.videTitre,
      phraseVide: t.com.studio.vide,
    );
  }

  /// Les sept blocs dans 1, 2 ou 3 colonnes. Sans activite a montrer
  /// ([blocs] nul), l'etat prend la place des cinq blocs d'activite ;
  /// brouillons et acces rapides restent.
  Widget _disposer(int colonnes, List<Widget>? blocs, Widget etat) {
    final Widget brouillons = BlocBrouillons(
      key: TableauAujourdhui.cleBrouillons,
      brouillons: _brouillons,
      onOuvrir: widget.onOuvrir,
      onVoirTous: widget.onVoirBrouillons,
      onReessayer: _rechargerBrouillons,
    );
    final Widget acces = _AccesRapides(onOuvrir: widget.onOuvrir);
    Widget colonne(int i, List<Widget> enfants) =>
        PileCartes(key: TableauAujourdhui.cleColonne(i), children: enfants);
    Widget rangee(List<(int, List<Widget>)> colonnesDuTableau) => PileCartes(
      axe: Axis.horizontal,
      alignement: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < colonnesDuTableau.length; i++)
          Expanded(
            flex: colonnesDuTableau[i].$1,
            child: colonne(i, colonnesDuTableau[i].$2),
          ),
      ],
    );

    final List<Widget>? b = blocs;
    if (b == null) {
      return switch (colonnes) {
        1 => colonne(0, <Widget>[etat, brouillons, acces]),
        2 => rangee(<(int, List<Widget>)>[
          (1, <Widget>[etat]),
          (1, <Widget>[brouillons, acces]),
        ]),
        _ => rangee(<(int, List<Widget>)>[
          (2, <Widget>[etat]),
          (1, <Widget>[brouillons, acces]),
        ]),
      };
    }
    return switch (colonnes) {
      1 => colonne(0, <Widget>[...b, brouillons, acces]),
      2 => rangee(<(int, List<Widget>)>[
        (1, <Widget>[b[0], b[1], b[2]]),
        (1, <Widget>[b[3], b[4], brouillons, acces]),
      ]),
      _ => rangee(<(int, List<Widget>)>[
        (1, <Widget>[b[0], b[1]]),
        (1, <Widget>[b[2], b[3], b[4]]),
        (1, <Widget>[brouillons, acces]),
      ]),
    };
  }
}

/// Les indicateurs d'attention (COM-W00) : ce que comptent les blocs, zero
/// compris (`StatTile`). Ce sont des rapports, sans geste : chaque ligne
/// comptee est juste en dessous, avec sa destination.
class _Indicateurs extends StatelessWidget {
  const _Indicateurs({
    required this.rangees,
    required this.nonLus,
    required this.colonnes,
  });

  final Map<RubriqueAujourdhui, List<ActiviteStudio>> rangees;
  final int nonLus;
  final int colonnes;

  @override
  Widget build(BuildContext context) {
    final i = t.com.studio.aujourdhui.indicateurs;
    final List<Widget> tuiles = <Widget>[
      StatTile(
        valeur: rangees[RubriqueAujourdhui.aTraiter]!.length,
        libelle: i.aTraiter,
      ),
      StatTile(
        valeur: rangees[RubriqueAujourdhui.mentions]!.length,
        libelle: i.mentions,
      ),
      StatTile(
        valeur: rangees[RubriqueAujourdhui.decisions]!.length,
        libelle: i.decisions,
      ),
      StatTile(valeur: nonLus, libelle: i.nonLus),
    ];
    Widget rangee(List<Widget> enfants) => PileCartes(
      axe: Axis.horizontal,
      alignement: CrossAxisAlignment.start,
      children: <Widget>[
        for (final Widget enfant in enfants) Expanded(child: enfant),
      ],
    );
    return Semantics(
      key: TableauAujourdhui.cleIndicateurs,
      container: true,
      label: i.titre,
      child: colonnes == 1
          ? PileCartes(
              children: <Widget>[
                rangee(tuiles.sublist(0, 2)),
                rangee(tuiles.sublist(2)),
              ],
            )
          : rangee(tuiles),
    );
  }
}

/// Le bloc « Acces rapides ».
class _AccesRapides extends StatelessWidget {
  const _AccesRapides({required this.onOuvrir});

  final ValueChanged<DestinationStudio> onOuvrir;

  @override
  Widget build(BuildContext context) => GroupeReglages(
    key: TableauAujourdhui.cleAcces,
    titre: t.com.studio.aujourdhui.blocs.acces,
    lignes: <LigneRubrique>[
      for (final AccesRapideStudio a in accesRapidesStudio())
        LigneRubrique(
          icone: a.icone,
          libelle: a.libelle,
          legende: a.detail,
          onPress: () => onOuvrir(a.destination),
        ),
    ],
  );
}
