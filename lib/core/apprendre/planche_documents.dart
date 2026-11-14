/// ESPACE-APPRENDRE (lot 5, 12/11/2026) : la planche de documents, **ecrite une
/// seule fois** pour toute l'application (la salle la reprendra plus tard).
///
/// Elle montre des [DocumentPlanche] en deux rayons (« Documents des cours »,
/// puis « Pour aller plus loin »), en grille (par defaut) ou en liste au choix
/// de l'eleve, garde sur l'appareil ([affichagePlancheProvider]), avec un
/// filtre par type ([typesRetenusPlancheProvider]).
///
/// - **Pas un faux controle** : le filtre par type n'existe que si au moins
///   deux types sont presents ; une puce n'existe que pour un type qui a au
///   moins un document. Un filtre qui ne laisse rien le dit, avec « Tout
///   effacer ».
/// - **Le second rayon vide dit la verite** : « D'autres documents arriveront
///   ici », sans prix ni mot d'argent (la vente n'est pas ouverte).
/// - **Un lien externe** est une petite carte avec sa description ; il
///   s'ouvre par **sa fiche** (la Bibliotheque une, lot 3) : la fiche relit
///   l'adresse et demande la confirmation avant de quitter l'application. La
///   planche n'a aucun chemin de sortie qui lui soit propre.
/// - **La page defile, la planche ne defile pas** : un seul defilement par
///   ecran (DECISION-DEFILEMENT-2026-11-01). Les rangees de la grille sont des
///   `Row` de cellules egales, jamais une grille a hauteur fixe qui deborde a
///   200 % de texte.
/// - Mouvement : les huit premieres cellules apparaissent en decale
///   (`ElementEchelonne`), le mouvement reduit est respecte par les briques.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../mouvement/apparition_douce.dart';
import '../tc_bibliotheque/contenu_arabe.dart';
import '../tc_bibliotheque/library_resource.dart'
    show RayonBibliotheque, codeRayonCours, codeRayonPlusLoin;
import '../theme/app_gabarit.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_card.dart';
import '../widgets/bouton_icone.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_pill.dart';
import '../widgets/pressable.dart';
import '../widgets/puce_filtre_actif.dart';
import '../widgets/rangee_filtres.dart';
import '../widgets/section_header.dart';
import '../widgets/status_pill.dart';
import 'affichage_planche.dart';
import 'document_planche.dart';
import 'vignette_document.dart';

/// Le libelle d'un type de document.
String libelleTypeDocument(TypeDocumentPlanche type) {
  final c = t.apprendre.bibliotheque.type;
  return switch (type) {
    TypeDocumentPlanche.document => c.document,
    TypeDocumentPlanche.audio => c.audio,
    TypeDocumentPlanche.video => c.video,
    TypeDocumentPlanche.lienExterne => c.lienExterne,
  };
}

/// La planche. Se pose dans une colonne de la page : elle ne defile pas.
class PlancheDocuments extends ConsumerStatefulWidget {
  /// Cree la planche pour [documents].
  const PlancheDocuments({
    required this.documents,
    super.key,
    this.surOuvrir,
    this.rubriqueClasse,
    this.rayons = const <RayonBibliotheque>[],
  });

  /// Les rayons du serveur, avec leurs intitules (`PortCatalogue.rayons()`).
  /// Vide : la planche garde ses intitules ecrits.
  final List<RayonBibliotheque> rayons;

  /// L'etat de la rubrique « Pour cette classe » quand elle n'est pas encore
  /// des documents : sa place reservee pendant la lecture (pas de saut de mise
  /// en page), ou sa phrase d'echec. Nul : rien a dire.
  final Widget? rubriqueClasse;

  /// Les documents, dans l'ordre voulu (le Coran en premier).
  final List<DocumentPlanche> documents;

  /// Ce qui se passe quand un document est ouvert. Par defaut : l'adresse du
  /// routeur (sa fiche, ou le lecteur du Coran).
  final ValueChanged<DocumentPlanche>? surOuvrir;

  /// Les cles des tests.
  static const Key cleAffichageGrille = ValueKey<String>(
    'planche-affichage-grille',
  );

  /// Idem, pour la liste.
  static const Key cleAffichageListe = ValueKey<String>(
    'planche-affichage-liste',
  );

  /// La cle d'une cellule, d'une ligne ou d'une carte de lien.
  static Key cleDocument(String id) => ValueKey<String>('planche-doc-$id');

  /// La cle du rayon d'un rang.
  static Key cleRayon(RayonPlanche rayon) =>
      ValueKey<String>('planche-rayon-${rayon.name}');

  /// La cle de l'etat vide du second rayon.
  static const Key cleRayonPlusLoinVide = ValueKey<String>(
    'planche-rayon-plus-loin-vide',
  );

  /// La cle de « aucun resultat ».
  static const Key cleAucunResultat = ValueKey<String>(
    'planche-aucun-resultat',
  );

  @override
  ConsumerState<PlancheDocuments> createState() => _PlancheEtat();
}

class _PlancheEtat extends ConsumerState<PlancheDocuments> {
  @override
  Widget build(BuildContext context) {
    final AffichagePlanche affichage = ref.watch(affichagePlancheProvider);
    final Set<TypeDocumentPlanche> retenusBruts = ref.watch(
      typesRetenusPlancheProvider,
    );
    final List<DocumentPlanche> tous = widget.documents;
    final List<TypeDocumentPlanche> presents = <TypeDocumentPlanche>[
      for (final TypeDocumentPlanche type in TypeDocumentPlanche.values)
        if (tous.any((DocumentPlanche d) => d.type == type)) type,
    ];
    // Un type retenu qui n'existe plus ne filtre plus rien.
    final Set<TypeDocumentPlanche> retenus = <TypeDocumentPlanche>{
      for (final TypeDocumentPlanche type in retenusBruts)
        if (presents.contains(type)) type,
    };
    final bool filtreOffert = presents.length >= 2;
    final bool filtreActif = filtreOffert && retenus.isNotEmpty;
    final List<DocumentPlanche> visibles = <DocumentPlanche>[
      for (final DocumentPlanche d in tous)
        if (!filtreActif || retenus.contains(d.type)) d,
    ];

    final c = t.apprendre.bibliotheque;
    final bool rienDuTout = tous.isEmpty;
    final bool aucunResultat = !rienDuTout && visibles.isEmpty;

    final List<Widget> rayons = <Widget>[];
    if (!aucunResultat) {
      int rang = 0;
      for (final RayonPlanche rayon in RayonPlanche.values) {
        final List<DocumentPlanche> dansCeRayon = <DocumentPlanche>[
          for (final DocumentPlanche d in visibles)
            if (d.rayon == rayon) d,
        ];
        rayons.addAll(
          _rayon(
            context,
            rayon: rayon,
            dansCeRayon: dansCeRayon,
            existeDansCeRayon: tous.any(
              (DocumentPlanche d) => d.rayon == rayon,
            ),
            affichage: affichage,
            premierRang: rang,
          ),
        );
        rang += dansCeRayon.length;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (!rienDuTout)
          _Commandes(
            presents: filtreOffert ? presents : const <TypeDocumentPlanche>[],
            retenus: retenus,
            affichage: affichage,
          ),
        if (filtreActif) ...<Widget>[
          Ecart.vSm,
          FiltresActifs(
            filtres: <FiltreActif>[
              for (final TypeDocumentPlanche type in presents)
                if (retenus.contains(type))
                  FiltreActif(
                    libelle: libelleTypeDocument(type),
                    onRetirer: () => ref
                        .read(typesRetenusPlancheProvider.notifier)
                        .basculer(type),
                  ),
            ],
            onToutEffacer: () =>
                ref.read(typesRetenusPlancheProvider.notifier).toutEffacer(),
          ),
        ],
        Ecart.vLg,
        if (aucunResultat)
          EmptyState(
            key: PlancheDocuments.cleAucunResultat,
            message: c.aucunResultat.message,
            invitation: c.aucunResultat.invitation,
            libelleAction: t.commun.listes.toutEffacer,
            onAction: () =>
                ref.read(typesRetenusPlancheProvider.notifier).toutEffacer(),
          ),
        if (widget.rubriqueClasse != null) ...<Widget>[
          widget.rubriqueClasse!,
          Ecart.vSection,
        ],
        ...rayons,
      ],
    );
  }

  List<Widget> _rayon(
    BuildContext context, {
    required RayonPlanche rayon,
    required List<DocumentPlanche> dansCeRayon,
    required bool existeDansCeRayon,
    required AffichagePlanche affichage,
    required int premierRang,
  }) {
    final c = t.apprendre.bibliotheque;
    // L'intitule vient du serveur quand il est connu (donnee, jamais un
    // ecran), sinon du texte ecrit (les memes mots).
    final String? code = switch (rayon) {
      RayonPlanche.pourCetteClasse => null,
      RayonPlanche.documentsDesCours => codeRayonCours,
      RayonPlanche.pourAllerPlusLoin => codeRayonPlusLoin,
    };
    final String langue = LocaleSettings.currentLocale.languageCode;
    final String? duServeur = code == null
        ? null
        : widget.rayons
              .where((RayonBibliotheque r) => r.code == code)
              .map((RayonBibliotheque r) => r.titrePour(langue))
              .where((String titre) => titre.isNotEmpty)
              .firstOrNull;
    final String titre =
        duServeur ??
        switch (rayon) {
          RayonPlanche.pourCetteClasse => c.rayonClasse,
          RayonPlanche.documentsDesCours => c.rayonCours,
          RayonPlanche.pourAllerPlusLoin => c.rayonPlusLoin,
        };
    // Un filtre qui laisse un rayon sans document le retire de la page ; un
    // rayon qui n'a jamais eu de document dit la verite.
    if (existeDansCeRayon && dansCeRayon.isEmpty) return const <Widget>[];
    // « Pour cette classe » n'existe que s'il y a quelque chose a y mettre :
    // elle disparait, elle ne dit pas « vide ».
    if (rayon == RayonPlanche.pourCetteClasse && !existeDansCeRayon) {
      return const <Widget>[];
    }

    final Widget corps;
    if (!existeDansCeRayon) {
      corps = rayon == RayonPlanche.pourAllerPlusLoin
          ? EmptyState(
              key: PlancheDocuments.cleRayonPlusLoinVide,
              message: c.rayonPlusLoinVide,
              icone: AppIcons.bibliotheque,
              registre: RegistreVide.subi,
            )
          : EmptyState(
              message: c.rayonCoursVide.message,
              invitation: c.rayonCoursVide.invitation,
              icone: AppIcons.bibliotheque,
              registre: RegistreVide.subi,
            );
    } else {
      corps = _CorpsRayon(
        documents: dansCeRayon,
        affichage: affichage,
        premierRang: premierRang,
        ouvrir: _ouvrir,
      );
    }
    return <Widget>[
      KeyedSubtree(
        key: PlancheDocuments.cleRayon(rayon),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SectionHeader(
              titre: titre,
              compteur: existeDansCeRayon ? dansCeRayon.length : null,
            ),
            Ecart.vMd,
            corps,
          ],
        ),
      ),
      Ecart.vSection,
    ];
  }

  Future<void> _ouvrir(DocumentPlanche document) async {
    final ValueChanged<DocumentPlanche>? surOuvrir = widget.surOuvrir;
    if (surOuvrir != null) {
      surOuvrir(document);
      return;
    }
    switch (document.ouverture) {
      case OuvrirDansLApplication(:final String chemin):
        // `go`, comme la Bibliotheque d'origine et l'accueil : l'adresse
        // change, le retour est celui de la fiche (`?retour=`). Un lien
        // externe s'ouvre aussi par SA fiche : elle relit l'adresse et
        // demande la confirmation avant de quitter l'application (le chemin
        // de la Bibliotheque une, un seul).
        context.go(chemin);
    }
  }
}

/// La rangee de commandes : les filtres par type, puis grille ou liste.
class _Commandes extends ConsumerWidget {
  const _Commandes({
    required this.presents,
    required this.retenus,
    required this.affichage,
  });

  final List<TypeDocumentPlanche> presents;
  final Set<TypeDocumentPlanche> retenus;
  final AffichagePlanche affichage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = t.apprendre.bibliotheque;
    final Widget bascule = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BoutonIcone(
          key: PlancheDocuments.cleAffichageGrille,
          icone: AppIcons.grille,
          libelle: c.affichage.grille,
          selectionne: affichage == AffichagePlanche.grille,
          onPress: () => ref
              .read(affichagePlancheProvider.notifier)
              .choisir(AffichagePlanche.grille),
        ),
        Ecart.hSm,
        BoutonIcone(
          key: PlancheDocuments.cleAffichageListe,
          icone: AppIcons.liste,
          libelle: c.affichage.liste,
          selectionne: affichage == AffichagePlanche.liste,
          onPress: () => ref
              .read(affichagePlancheProvider.notifier)
              .choisir(AffichagePlanche.liste),
        ),
      ],
    );
    if (presents.isEmpty) {
      return Align(alignment: AlignmentDirectional.centerEnd, child: bascule);
    }
    final Widget filtres = Semantics(
      container: true,
      label: c.filtres.libelle,
      child: RangeeFiltres(
        filtres: <Widget>[
          for (final TypeDocumentPlanche type in presents)
            FilterPill(
              libelle: libelleTypeDocument(type),
              retenue: retenus.contains(type),
              onPress: () =>
                  ref.read(typesRetenusPlancheProvider.notifier).basculer(type),
            ),
        ],
      ),
    );
    // Au telephone, les filtres gardent toute la largeur (a cote de la bascule
    // il ne resterait de place que pour une puce) ; la bascule passe au-dessus,
    // a la fin de la ligne. Des la tablette, tout tient sur une rangee.
    if (AppGabarit.de(context) == Gabarit.mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Align(alignment: AlignmentDirectional.centerEnd, child: bascule),
          Ecart.vSm,
          filtres,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(child: filtres),
        Ecart.hMd,
        bascule,
      ],
    );
  }
}

/// Le corps d'un rayon : la grille de tuiles et de petites cartes de lien, ou
/// la liste.
class _CorpsRayon extends StatelessWidget {
  const _CorpsRayon({
    required this.documents,
    required this.affichage,
    required this.premierRang,
    required this.ouvrir,
  });

  final List<DocumentPlanche> documents;
  final AffichagePlanche affichage;
  final int premierRang;
  final Future<void> Function(DocumentPlanche) ouvrir;

  /// La largeur minimale d'une tuile : a 320, deux colonnes tiennent.
  static const double largeurMiniTuile = 128;

  @override
  Widget build(BuildContext context) {
    if (affichage == AffichagePlanche.liste) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.lg,
        children: <Widget>[
          for (final (int i, DocumentPlanche d) in documents.indexed)
            ElementEchelonne(
              key: PlancheDocuments.cleDocument(d.id),
              index: premierRang + i,
              child: d.type == TypeDocumentPlanche.lienExterne
                  ? _CarteLien(document: d, ouvrir: ouvrir)
                  : _LigneDocument(document: d, ouvrir: ouvrir),
            ),
        ],
      );
    }
    final List<DocumentPlanche> tuiles = <DocumentPlanche>[
      for (final DocumentPlanche d in documents)
        if (d.type != TypeDocumentPlanche.lienExterne) d,
    ];
    final List<DocumentPlanche> liens = <DocumentPlanche>[
      for (final DocumentPlanche d in documents)
        if (d.type == TypeDocumentPlanche.lienExterne) d,
    ];
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints c) {
        final Gabarit gabarit = AppGabarit.de(contexte);
        final int voulues = switch (gabarit) {
          Gabarit.mobile => 2,
          Gabarit.tablette => 3,
          Gabarit.desktop => 4,
        };
        final int tiennent =
            ((c.maxWidth + AppSpacing.lg) / (largeurMiniTuile + AppSpacing.lg))
                .floor();
        final int colonnesTuiles = voulues < tiennent ? voulues : tiennent;
        final int colonnesLiens = switch (gabarit) {
          Gabarit.mobile => 1,
          Gabarit.tablette => 2,
          Gabarit.desktop => 3,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (tuiles.isNotEmpty)
              _Grille(
                colonnes: colonnesTuiles < 1 ? 1 : colonnesTuiles,
                cellules: <Widget>[
                  for (final (int i, DocumentPlanche d) in tuiles.indexed)
                    ElementEchelonne(
                      key: PlancheDocuments.cleDocument(d.id),
                      index: premierRang + i,
                      child: _TuileDocument(document: d, ouvrir: ouvrir),
                    ),
                ],
              ),
            if (tuiles.isNotEmpty && liens.isNotEmpty) Ecart.vXl,
            if (liens.isNotEmpty)
              _Grille(
                colonnes: colonnesLiens,
                cellules: <Widget>[
                  for (final (int i, DocumentPlanche d) in liens.indexed)
                    ElementEchelonne(
                      key: PlancheDocuments.cleDocument(d.id),
                      index: premierRang + tuiles.length + i,
                      child: _CarteLien(document: d, ouvrir: ouvrir),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

/// Des rangees de [colonnes] cellules egales, la derniere completee.
///
/// Des `Row` d'`Expanded`, pas un `GridView` : chaque cellule prend la hauteur
/// de son contenu, a 200 % de texte comme a 100 %, sans debordement et sans
/// second defilement.
class _Grille extends StatelessWidget {
  const _Grille({required this.colonnes, required this.cellules});

  final int colonnes;
  final List<Widget> cellules;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rangees = <Widget>[];
    for (int debut = 0; debut < cellules.length; debut += colonnes) {
      final List<Widget> rangee = <Widget>[];
      for (int j = 0; j < colonnes; j++) {
        if (j > 0) rangee.add(Ecart.hLg);
        final int index = debut + j;
        rangee.add(
          Expanded(
            child: index < cellules.length
                ? cellules[index]
                : const SizedBox.shrink(),
          ),
        );
      }
      rangees.add(
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: rangee),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xl,
      children: rangees,
    );
  }
}

String _semantiqueDocument(DocumentPlanche d) {
  final String base = t.apprendre.bibliotheque.carte.document(
    titre: d.titre,
    type: libelleTypeDocument(d.type),
  );
  final String? description = d.description;
  final String? horsLigne = d.horsLigne?.libelle;
  return <String>[base, ?description, ?horsLigne].join('. ');
}

/// Une tuile de la grille : la vignette, puis le titre et une ligne.
class _TuileDocument extends StatelessWidget {
  const _TuileDocument({required this.document, required this.ouvrir});

  final DocumentPlanche document;
  final Future<void> Function(DocumentPlanche) ouvrir;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Pressable(
      onPress: () => unawaited(ouvrir(document)),
      libelleSemantique: _semantiqueDocument(document),
      respecterCibleTactile: false,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            VignetteDocument(document: document),
            Ecart.vSm,
            _TexteContenu(
              document.titre,
              style: palette.inkStrong.applyTo(
                textes.titleSmall ?? const TextStyle(),
              ),
            ),
            Ecart.vXs,
            // La description est du contenu ; le nom du type, repli quand
            // elle manque, est de l'interface.
            document.description == null
                ? TexteSansCoupure(
                    libelleTypeDocument(document.type),
                    style: palette.inkMuted.applyTo(
                      textes.bodySmall ?? const TextStyle(),
                    ),
                  )
                : _TexteContenu(
                    document.description!,
                    style: palette.inkMuted.applyTo(
                      textes.bodySmall ?? const TextStyle(),
                    ),
                  ),
            if (document.horsLigne != null) ...<Widget>[
              Ecart.vSm,
              _PastilleHorsLigne(document.horsLigne!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Une ligne de la liste : la petite vignette, le titre, la description et le
/// type.
class _LigneDocument extends StatelessWidget {
  const _LigneDocument({required this.document, required this.ouvrir});

  final DocumentPlanche document;
  final Future<void> Function(DocumentPlanche) ouvrir;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final double largeurVignette = AppMetriques.of(context).estEnfant
        ? AppSpacing.respiration + AppSpacing.lg
        : AppSpacing.respiration;
    final String? description = document.description;
    return AppCard(
      onPress: () => unawaited(ouvrir(document)),
      libelleSemantique: _semantiqueDocument(document),
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: largeurVignette,
              child: VignetteDocument(document: document),
            ),
            Ecart.hLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _TexteContenu(
                    document.titre,
                    style: palette.surfaceRaised.applyTo(
                      textes.titleMedium ?? const TextStyle(),
                    ),
                  ),
                  if (description != null) ...<Widget>[
                    Ecart.vXs,
                    _TexteContenu(
                      description,
                      style: palette.inkMuted.applyTo(
                        textes.bodyMedium ?? const TextStyle(),
                      ),
                    ),
                  ],
                  Ecart.vXs,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconTheme(
                        data: palette.inkMuted.asIconTheme(size: AppSpacing.lg),
                        child: Icon(
                          VignetteDocument.iconeDe(document.type).repos,
                        ),
                      ),
                      Ecart.hXs,
                      Flexible(
                        child: TexteSansCoupure(
                          libelleTypeDocument(document.type),
                          style: palette.inkMuted.applyTo(
                            textes.bodySmall ?? const TextStyle(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (document.horsLigne != null) ...<Widget>[
                    Ecart.vSm,
                    _PastilleHorsLigne(document.horsLigne!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La petite carte d'un lien externe : l'icone, le titre et la description ;
/// elle s'ouvre par sa fiche, qui demande la confirmation.
class _CarteLien extends StatelessWidget {
  const _CarteLien({required this.document, required this.ouvrir});

  final DocumentPlanche document;
  final Future<void> Function(DocumentPlanche) ouvrir;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? description = document.description;
    final String semantique = <String>[
      t.apprendre.bibliotheque.carte.lien(titre: document.titre),
      ?description,
    ].join('. ');
    return AppCard(
      lien: true,
      onPress: () => unawaited(ouvrir(document)),
      libelleSemantique: semantique,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                IconTheme(
                  data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
                  child: Icon(AppIcons.lienExterne.repos),
                ),
                Ecart.hMd,
                Expanded(
                  child: _TexteContenu(
                    document.titre,
                    style: palette.surfaceRaised.applyTo(
                      textes.titleMedium ?? const TextStyle(),
                    ),
                  ),
                ),
              ],
            ),
            if (description != null) ...<Widget>[
              Ecart.vSm,
              _TexteContenu(
                description,
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Un texte de CONTENU de la planche (titre ou description d'un document) :
/// en police du Coran quand il contient de l'arabe, lu de droite a gauche
/// quand il commence par de l'arabe (directeur, 13/11/2026 ; style du lot 3,
/// `styleContenuArabe`). L'arabe d'interface ne passe jamais ici.
class _TexteContenu extends StatelessWidget {
  const _TexteContenu(this.texte, {required this.style});

  final String texte;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => dirigerContenuArabe(
    texte,
    TexteSansCoupure(texte, style: styleContenuArabe(texte, style)),
  );
}

/// L'etat hors ligne d'un document gardé sur l'appareil : une pastille et un
/// mot (jamais la couleur seule).
class _PastilleHorsLigne extends StatelessWidget {
  const _PastilleHorsLigne(this.etat);

  final HorsLigneDocument etat;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: StatusPill(libelle: etat.libelle, ton: etat.ton),
  );
}
