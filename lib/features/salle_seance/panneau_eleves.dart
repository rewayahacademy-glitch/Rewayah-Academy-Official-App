// Le panneau Eleves (CLV-07), enseignant seulement.
//
// Repris de l'ancienne fiche de seance de `/tc/classe` (supprimee le
// 17/10/2026) : memes intitules (Niveau, Objectif actuel, Derniere seance,
// A reprendre, Presence recente, Travail actuel), memes quatre actions
// (Rappeler, Choisir pour reciter, Noter, Signaler un besoin), statuts de la liste de la vue
// (`VueSeance.eleves`, source unique du compteur, I-6). Connaissance privee
// minimale : ni telephone, ni e-mail, ni tuteur, ni « present » / « absent ».

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/isolation_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/mouvement/passage_scene.dart';
import '../../core/tc_classe/roster_classe_vm.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/bouton_outil.dart';
import '../../core/widgets/cadre_visage.dart';
import '../../core/widgets/pressable.dart';
import '../foyer/photo_eleve.dart';
import 'actions_seance.dart';
import 'vignette_video.dart' show SignalVideo;
import 'vue_seance.dart';

/// Le libelle d'un statut pendant la seance.
String libelleStatutEleve(StatutEleveSeance statut) => switch (statut) {
  StatutEleveSeance.connecte => t.salle.seance.statut.connecte,
  StatutEleveSeance.pasEncoreConnecte =>
    t.salle.seance.statut.pasEncoreConnecte,
  StatutEleveSeance.connexionInterrompue =>
    t.salle.seance.statut.connexionInterrompue,
};

/// La cle d'un inscrit dans le panneau : son identifiant d'academie ; a
/// defaut (demonstration, sans identifiant), son prenom.
String cleEleveSeance(EleveSeance eleve) => eleve.id ?? eleve.prenom;

AppInkColor _encreStatut(AppPalette palette, StatutEleveSeance statut) =>
    switch (statut) {
      StatutEleveSeance.connecte => palette.inkSuccess,
      StatutEleveSeance.pasEncoreConnecte => palette.inkWarning,
      StatutEleveSeance.connexionInterrompue => palette.inkAlert,
    };

/// La couleur de la pastille. L'attente se lit jaune orange (images) : le
/// fond d'avertissement plein, et non l'encre de texte brun olive.
Color _couleurPastille(AppPalette palette, StatutEleveSeance statut) =>
    switch (statut) {
      StatutEleveSeance.pasEncoreConnecte => palette.surfaceWarning.background,
      _ => _encreStatut(palette, statut).asBorderSide().color,
    };

/// Le corps des intitules et valeurs de la fiche (image CLV-07 : ≈ 13 px).
/// Plus Jakarta Sans n'a pas d'axe `opsz` : la retaille est sure.
const double _corpsFiche = 13;

TextStyle _styleFiche(BuildContext context) =>
    (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontSize: _corpsFiche,
    );

/// La liste des inscrits ; une fiche depliee a la fois.
class PanneauEleves extends StatefulWidget {
  const PanneauEleves({
    required this.eleves,
    required this.actions,
    this.recitation,
    this.large = false,
    this.serre = false,
    this.entete,
    this.tete,
    this.autorisationEcrire = false,
    this.visages,
    super.key,
  });

  final List<EleveSeance> eleves;
  final ActionsSeance actions;

  /// RUBAN-ORDINATEUR (MODES-AFFICHAGE §4, directeur, 11/11/2026) : les
  /// visages vivants des eleves, en mode Document ou Tableau (le ruban de
  /// l'enseignant sur ordinateur). Chaque carte d'eleve dans la salle porte
  /// alors son cadre ([CadreVisage]) a la place de l'initiale ; l'eleve qui
  /// recite passe en premier, son cadre en grand. `null` (mode Classe : les
  /// visages sont deja dans la grille ; ou sans moteur) : l'initiale ou la
  /// photo, jamais une seconde image de la meme personne.
  final VisagesPanneau? visages;

  /// TB-10 (plan V2 §4.3, §20 ; UX-20) : la fiche porte « Autoriser a
  /// ecrire » ou « Retirer l'autorisation d'ecrire » (capacite de la vue,
  /// [VueSeance.voitAutorisationEcrire], et rappel
  /// [ActionsSeance.onAutoriserEcrire]).
  final bool autorisationEcrire;

  /// TB-3 (CTX-01, CTX-02) : le contexte de l'enseignant et de la seance,
  /// deplie depuis la capsule, en tete du panneau de personnes (une seule
  /// gestion des participants, plan V2 §4.3). `null` : rien.
  final Widget? entete;

  /// Directeur, 11/11/2026 (lot SALLE-ORDINATEUR) : la tete du panneau sur
  /// ordinateur, la video de l'enseignant et « Eleves 2/3 », premier element
  /// de la MEME liste (elle defile avec les cartes, elle ne flotte pas).
  /// `null` : rien.
  final Widget? tete;

  /// La file de recitation (EN-9), en tete du panneau : l'eleve en cours,
  /// puis « A suivre ». `null` : pas de bloc.
  final FileRecitation? recitation;

  /// Feuille du telephone : ecarts resserres, pour que la liste des trois
  /// inscrits tienne entiere sous la fiche depliee (image CLV-07 mobile).
  final bool serre;

  /// Colonne desktop : intitules au corps des valeurs (image desktop) ;
  /// ailleurs, intitules en petit (images web etroit et telephone).
  final bool large;

  @override
  State<PanneauEleves> createState() => _PanneauElevesState();
}

class _PanneauElevesState extends State<PanneauEleves> {
  /// La cle de la fiche depliee : au depart, le premier eleve connecte qui a
  /// une fiche (image : Mariam). L'identifiant, jamais le prenom seul : deux
  /// inscrits de meme prenom ne se deplient pas ensemble.
  late String? _deplie = _premierDeplie();

  /// TB-RC (TB_RAPPORT §d n. 8) : la carte depliee, amenee entiere dans la
  /// liste (« Autoriser a ecrire » n'est plus coupe au bas du panneau).
  final GlobalKey _carteDepliee = GlobalKey(debugLabel: 'carte-depliee');

  @override
  void initState() {
    super.initState();
    _montrerCarteDepliee();
  }

  /// Quand la carte depliee tient dans la liste mais deborde en bas, la
  /// liste (elle seule) defile juste assez pour la montrer entiere, ses
  /// actions comprises. Plus haute que la liste : rien ne bouge, le prenom
  /// reste en haut. Le contexte deplie depuis la capsule garde la main
  /// (il amene sa propre section).
  void _montrerCarteDepliee() {
    if (widget.entete != null) return;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      final BuildContext? carte = _carteDepliee.currentContext;
      if (!mounted || carte == null) return;
      final ScrollableState? liste = Scrollable.maybeOf(carte);
      final RenderObject? cible = carte.findRenderObject();
      if (liste == null || cible is! RenderBox || !cible.hasSize) return;
      final ScrollPosition position = liste.position;
      // Le bord de la carte reste visible : une marge sous elle.
      if (cible.size.height + AppSpacing.md > position.viewportDimension) {
        return;
      }
      final double finCarte = RenderAbstractViewport.of(cible)
          .getOffsetToReveal(cible, 1)
          .offset;
      final double voulu = math.min(
        finCarte + AppSpacing.md,
        position.maxScrollExtent,
      );
      if (voulu > position.pixels) position.jumpTo(voulu);
    });
  }

  String? _premierDeplie() {
    for (final EleveSeance e in widget.eleves) {
      if (e.statut == StatutEleveSeance.connecte && e.fiche != null) {
        return cleEleveSeance(e);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final FileRecitation? file = widget.recitation;
    final Widget? entete = widget.entete;
    final Widget? enTete = widget.tete;
    final int premier = enTete == null ? 0 : 1;
    final int contexte = premier + (entete == null ? 0 : 1);
    final int tete = contexte + (file == null ? 0 : 1);
    // RUBAN-ORDINATEUR (MODES-AFFICHAGE §2, regle 5) : en ruban, l'eleve qui
    // recite passe en premier ; les autres gardent leur ordre.
    final String? recitant = file?.actif;
    final List<EleveSeance> eleves = widget.visages == null || recitant == null
        ? widget.eleves
        : <EleveSeance>[
            ...widget.eleves.where(
              (EleveSeance e) => cleEleveSeance(e) == recitant,
            ),
            ...widget.eleves.where(
              (EleveSeance e) => cleEleveSeance(e) != recitant,
            ),
          ];
    return ListView.separated(
      key: const ValueKey<String>('panneau-eleves'),
      // Colonne desktop : la liste se mesure, la colonne s'arrete apres elle
      // (image CLV-07) ; au-dela de la hauteur disponible, elle defile.
      shrinkWrap: widget.large,
      // Telephone : la feuille descend jusqu'au bord de l'ecran, la liste
      // defile jusque sous la barre du systeme.
      padding: EdgeInsets.only(
        bottom: AppSpacing.md + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: widget.eleves.length + tete,
      separatorBuilder: (BuildContext _, int _) => Ecart.vLg,
      itemBuilder: (BuildContext _, int index) {
        if (enTete != null && index == 0) return enTete;
        if (entete != null && index == premier) return entete;
        if (file != null && index == contexte) {
          return FileRecitationSeance(file: file, eleves: widget.eleves);
        }
        final EleveSeance e = eleves[index - tete];
        final String cle = cleEleveSeance(e);
        final bool deplie = _deplie == cle && e.fiche != null;
        return _CarteEleve(
          key: deplie ? _carteDepliee : null,
          eleve: e,
          deplie: deplie,
          large: widget.large,
          serre: widget.serre,
          actions: widget.actions,
          autorisationEcrire: widget.autorisationEcrire,
          recite: widget.recitation?.actif == cle,
          visages: widget.visages,
          onBasculer: e.fiche == null
              ? null
              : () {
                  setState(() => _deplie = deplie ? null : cle);
                  _montrerCarteDepliee();
                },
        );
      },
    );
  }
}

class _CarteEleve extends StatelessWidget {
  const _CarteEleve({
    super.key,
    required this.eleve,
    required this.deplie,
    required this.large,
    required this.serre,
    required this.actions,
    required this.onBasculer,
    this.autorisationEcrire = false,
    this.recite = false,
    this.visages,
  });

  /// GESTES-POINTEUR : cet eleve recite ; son bouton termine la recitation.
  final bool recite;

  /// RUBAN-ORDINATEUR : les visages vivants (modes Document et Tableau).
  final VisagesPanneau? visages;

  final EleveSeance eleve;
  final bool deplie;
  final bool large;
  final bool serre;
  final ActionsSeance actions;
  final VoidCallback? onBasculer;
  final bool autorisationEcrire;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final FicheEleveSeance? fiche = eleve.fiche;
    return DecoratedBox(
      key: ValueKey<String>('eleve-${cleEleveSeance(eleve)}'),
      decoration: palette.surfaceOverlay.decoration(
        borderRadius: AppRadius.arrondiMd,
        side: palette.borderHairline.asBorderSide(),
      ),
      child: Padding(
        padding: EdgeInsets.all(serre ? AppSpacing.xs : AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _EnTeteEleve(
              eleve: eleve,
              deplie: deplie,
              onBasculer: onBasculer,
              visages: visages,
              recite: recite,
            ),
            // RESEAU-ELEVES : un reseau mauvais depuis plusieurs secondes se
            // dit en une ligne dans la carte, jamais en alerte qui derange.
            if (eleve.phraseReseau case final String phrase)
              _PhraseReseau(
                key: ValueKey<String>('reseau-phrase-${cleEleveSeance(eleve)}'),
                phrase: phrase,
              ),
            if (deplie && fiche != null) ...<Widget>[
              if (serre) Ecart.vXs else Ecart.vSm,
              _GrilleFiche(fiche: fiche, large: large, serre: serre),
              _ActionsEleve(
                eleve: eleve,
                actions: actions,
                serre: serre,
                large: large,
                recite: recite,
              ),
              if (autorisationEcrire)
                if (actions.onAutoriserEcrire
                    case final ValueChanged<EleveSeance> autoriser)
                  _AutorisationEcrire(
                    eleve: eleve,
                    serre: serre,
                    onPress: () => autoriser(eleve),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EnTeteEleve extends StatelessWidget {
  const _EnTeteEleve({
    required this.eleve,
    required this.deplie,
    required this.onBasculer,
    this.visages,
    this.recite = false,
  });

  final EleveSeance eleve;
  final bool deplie;
  final VoidCallback? onBasculer;
  final VisagesPanneau? visages;
  final bool recite;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool connecte = eleve.statut == StatutEleveSeance.connecte;
    final AppInkColor encre = _encreStatut(palette, eleve.statut);
    final String statut = libelleStatutEleve(eleve.statut);
    // Verification TB-10 : en arabe a 320 x2, « Peut ecrire » etait
    // tronque en « الكتاب… » (une ligne et points de suspension). Les
    // deux mentions d'etat se lisent entieres : le droit d'ecrire passe
    // a la ligne, en bloc, quand il ne tient pas a cote du statut.
    final Widget role = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _Pastille(couleur: _couleurPastille(palette, eleve.statut)),
            Ecart.hXs,
            Flexible(
              child: TexteSansCoupure(
                statut,
                style: (connecte ? encre : palette.inkMuted).applyTo(
                  _styleFiche(context),
                ),
              ),
            ),
          ],
        ),
        // RESEAU-ELEVES (directeur, 11/11/2026) : le reseau de l'eleve,
        // les memes barres que la video (`SignalVideo`) : nombre de
        // barres, teinte d'attention a une barre, et le libelle lu avec
        // la carte. Sans mesure stable : aucun signe.
        if (connecte && eleve.reseau?.barres != null)
          SignalVideo(
            key: ValueKey<String>('reseau-${cleEleveSeance(eleve)}'),
            barres: eleve.reseau!.barres!,
          ),
        // TB-10 (plan V2 §12 « Autorisation de dessin » : eleve et droit
        // visibles dans Participants ; planche 8) : l'icone et le mot,
        // jamais la couleur seule.
        if (eleve.peutEcrire)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconTheme(
                key: ValueKey<String>('peut-ecrire-${cleEleveSeance(eleve)}'),
                data: palette.inkAccent.asIconTheme(size: AppSpacing.lg),
                child: Icon(AppIcons.annoter.repos),
              ),
              Ecart.hXs,
              Flexible(
                child: TexteSansCoupure(
                  t.salle.seance.ecriture.peutEcrire,
                  style: palette.inkAccent.applyTo(_styleFiche(context)),
                ),
              ),
            ],
          ),
      ],
    );
    final Widget? fin = onBasculer == null
        ? null
        : IconTheme(
            data: palette.inkStrong.asIconTheme(size: AppSpacing.xl),
            child: Icon(
              deplie ? AppIcons.replier.repos : AppIcons.chevron.repos,
            ),
          );
    final TextStyle styleNom = palette.inkStrong.applyTo(
      textes.titleSmall ?? const TextStyle(),
    );
    // RUBAN-ORDINATEUR : en mode Document ou Tableau, l'eleve dans la salle
    // porte son cadre vivant (sa camera, ou sa photo, ou son initiale dans
    // le cadre) ; celui qui recite, en grand au-dessus de son nom.
    final VisagesPanneau? visages = this.visages;
    final String? identite = eleve.profilId;
    final bool vivant = visages != null && connecte && identite != null;
    final Widget contenu;
    if (vivant) {
      final Widget cadre = CadreVivant(
        key: ValueKey<String>('cadre-ruban-${cleEleveSeance(eleve)}'),
        identite: identite,
        prenom: eleve.prenom,
        image: visages.image(identite),
        parle: visages.parle,
        microCoupe: !eleve.microOuvert,
        recite: recite,
      );
      contenu = Column(
        key: ValueKey<String>('ruban-vivant-$recite'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (recite) ...<Widget>[
            AspectRatio(aspectRatio: rapportCadreRuban, child: cadre),
            Ecart.vSm,
          ],
          Row(
            children: <Widget>[
              if (!recite) ...<Widget>[
                SizedBox(
                  width: largeurCadreRuban,
                  height: largeurCadreRuban / rapportCadreRuban,
                  child: cadre,
                ),
                Ecart.hMd,
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TexteSansCoupure(eleve.prenom, style: styleNom),
                    role,
                  ],
                ),
              ),
              if (fin != null) ...<Widget>[Ecart.hSm, fin],
            ],
          ),
        ],
      );
    } else {
      // AVATAR-1 : couple avatar + prenom du composant partage ; la ligne de
      // role est le statut, avec son point.
      contenu = AvatarNom.enLigne(
        key: const ValueKey<String>('ruban-initiale'),
        prenom: eleve.prenom,
        diametre: _Avatar._diametre,
        avatar: _Avatar(eleve: eleve),
        styleNom: styleNom,
        roleWidget: role,
        fin: fin,
      );
    }
    final Widget ligne = Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: _PassageCadre(vivant: vivant, child: contenu),
    );
    final VoidCallback? basculer = onBasculer;
    final String? reseau = connecte ? eleve.libelleReseau : null;
    final String etat = <String>[
      statut,
      ?reseau,
      if (eleve.peutEcrire) t.salle.seance.ecriture.peutEcrire,
    ].join(', ');
    // TB-RC (revue TB-R, m12) : le nom lu dit deja le prenom et l'etat ; la
    // ligne peinte se tait (sinon « Mariam, Connecte » est lu deux fois).
    if (basculer == null) {
      return Semantics(
        container: true,
        label: '${eleve.prenom}, $etat',
        child: ExcludeSemantics(child: ligne),
      );
    }
    return Semantics(
      expanded: deplie,
      child: Pressable(
        onPress: basculer,
        libelleSemantique:
            '${deplie ? t.salle.seance.replierFiche(dePrenom: deDevant(eleve.prenom)) : t.salle.seance.deplierFiche(dePrenom: deDevant(eleve.prenom))}, $etat',
        arrondiFocus: AppRadius.arrondiSm,
        child: ExcludeSemantics(child: ligne),
      ),
    );
  }
}

/// RESEAU-ELEVES : la phrase courte d'un reseau mauvais qui dure (« On
/// entend peut-etre mal Yasmine »), l'icone du reseau et le mot, jamais la
/// couleur seule.
class _PhraseReseau extends StatelessWidget {
  const _PhraseReseau({required this.phrase, super.key});

  final String phrase;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.xs,
        end: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ExcludeSemantics(
            child: IconTheme(
              data: palette.inkWarning.asIconTheme(size: AppSpacing.lg),
              child: Icon(AppIcons.reseau.repos),
            ),
          ),
          Ecart.hXs,
          Expanded(
            child: Text(
              phrase,
              style: palette.inkWarning.applyTo(_styleFiche(context)),
            ),
          ),
        ],
      ),
    );
  }
}

/// L'avatar : l'initiale pour l'eleve connecte (image : « M »), sinon la
/// silhouette avec la pastille du statut en bas a droite.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.eleve});

  final EleveSeance eleve;

  static const double _diametre = AppAvatar.moyen;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool connecte = eleve.statut == StatutEleveSeance.connecte;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: _diametre,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            // E5 et K-44 : la photo de l'eleve par `PhotoEleve`, les
            // initiales seulement en repli.
            Positioned.fill(
              child: PhotoEleve(
                prenom: eleve.prenom,
                cleAvatar: eleve.cleAvatar,
                personneId: eleve.profilId,
                diametre: _diametre,
              ),
            ),
            if (!connecte)
              PositionedDirectional(
                end: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: palette.surfaceOverlay.background,
                      width: AppSpacing.xs / 2,
                    ),
                  ),
                  child: _Pastille(
                    couleur: _couleurPastille(palette, eleve.statut),
                    grande: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille({required this.couleur, this.grande = false});

  final Color couleur;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final double d = grande ? AppSpacing.md : AppSpacing.sm;
    return SizedBox.square(
      dimension: d,
      child: DecoratedBox(
        decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
      ),
    );
  }
}

/// Les six champs, en grille de deux colonnes (images).
class _GrilleFiche extends StatelessWidget {
  const _GrilleFiche({
    required this.fiche,
    required this.large,
    required this.serre,
  });

  final FicheEleveSeance fiche;
  final bool large;
  final bool serre;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double ecart = large
        ? AppSpacing.md
        : (serre ? AppSpacing.xs : AppSpacing.sm);
    // Cellules serrees sur les cotes : les valeurs tiennent sur une ligne,
    // comme sur les images (« 3 seances cette semaine »).
    final EdgeInsets marge = EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: serre ? AppSpacing.sm : AppSpacing.md,
    );
    Widget champ(String intitule, String valeur, {bool objectif = false}) =>
        _Champ(
          intitule: intitule,
          valeur: valeur,
          large: large,
          serre: serre,
          objectif: objectif,
        );
    // Plan de composition du 26/10/2026 (`/salle`) : un fait que le serveur
    // ne projette pas encore reste vide ; il ne se montre pas (jamais une
    // valeur vide qui se lirait comme un zero). Sans aucun fait, la phrase
    // de la fiche dit que la donnee n'est pas ouverte.
    final List<Widget> gauches = <Widget>[
      if (fiche.niveau.isNotEmpty)
        champ(t.tc.classe.fiche.niveau, fiche.niveau),
      if (fiche.objectifActuel.isNotEmpty)
        champ(t.tc.classe.fiche.objectif, fiche.objectifActuel, objectif: true),
      if (fiche.derniereSeance.isNotEmpty)
        champ(t.tc.classe.fiche.derniereSeance, fiche.derniereSeance),
    ];
    final List<Widget> droites = <Widget>[
      if (fiche.aReprendre.isNotEmpty)
        champ(t.tc.classe.fiche.aReprendre, fiche.aReprendre),
      if (fiche.presenceRecente.isNotEmpty)
        champ(t.tc.classe.fiche.presenceRecente, fiche.presenceRecente),
      if (fiche.travailActuel.isNotEmpty)
        champ(t.tc.classe.fiche.travailActuel, fiche.travailActuel),
    ];
    if (gauches.isEmpty && droites.isEmpty) {
      return Text(
        t.tc.classe.fiche.sansPedagogie,
        key: const ValueKey<String>('fiche-eleve-vide'),
        style: palette.inkMuted.applyTo(_styleFiche(context)),
      );
    }
    final Widget gauche = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: ecart,
      children: gauches.isEmpty ? droites : gauches,
    );
    final Widget droite = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: ecart,
      children: gauches.isEmpty ? const <Widget>[] : droites,
    );
    return DecoratedBox(
      key: const ValueKey<String>('fiche-eleve'),
      decoration: palette.surfaceRaised.decoration(
        borderRadius: AppRadius.arrondiSm,
        side: palette.borderHairline.asBorderSide(),
      ),
      // 390 a texte agrandi : une seule colonne, pour que les mots ne se
      // coupent pas (W-144, W-1410 ; meme seuil que groupe_reglages).
      child:
          serre && MediaQuery.textScalerOf(context).scale(1) > seuilTexteEmpile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(padding: marge, child: gauche),
                Padding(padding: marge, child: droite),
              ],
            )
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: Padding(padding: marge, child: gauche),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: palette.borderHairline.asBorderSide().color,
                  ),
                  Expanded(
                    child: Padding(padding: marge, child: droite),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Au-dela, une valeur se replie sur deux lignes plutot que de rapetisser.
const int _valeurCourte = 28;

class _Champ extends StatelessWidget {
  const _Champ({
    required this.intitule,
    required this.valeur,
    required this.large,
    required this.serre,
    this.objectif = false,
  });

  final String intitule;
  final String valeur;
  final bool large;
  final bool serre;

  /// L'objectif actuel : le chapitre en gras sur sa ligne, la precision
  /// entre parentheses dessous (images : « Chapitre 1 » puis « (les bonnes
  /// manieres) »).
  final bool objectif;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle corps = _styleFiche(context);
    final TextStyle styleIntitule = large
        ? corps
        : Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    final int coupure = objectif ? valeur.indexOf(' (') : -1;
    // Donnee venue de la fiche : isolee en arabe, pour que ses chiffres et
    // ses parentheses restent a leur place (revue du 09/10).
    String isole(String texte) => donneeDansLeSens(context, texte);
    final Widget texteValeur = coupure > 0
        ? Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: isole(valeur.substring(0, coupure)),
                  style: AppTypography.graisse(corps, FontWeight.w700),
                ),
                TextSpan(text: '\n${isole(valeur.substring(coupure + 1))}'),
              ],
            ),
            style: palette.inkStrong.applyTo(corps),
          )
        : large &&
              valeur.length <= _valeurCourte &&
              MediaQuery.textScalerOf(context).scale(1) <= 1
        // Colonne desktop : une valeur courte tient sur sa ligne (image
        // CLV-07 : « 3 séances cette semaine »), quitte a se reduire un peu.
        // Texte agrandi : la valeur passe a la ligne plutot que d'annuler
        // l'agrandissement (W-144).
        ? FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              isole(valeur),
              maxLines: 1,
              style: palette.inkStrong.applyTo(corps),
            ),
          )
        : Text(isole(valeur), style: palette.inkStrong.applyTo(corps));
    // Un fait = une annonce : intitule et valeur lus ensemble.
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(intitule, style: palette.inkMuted.applyTo(styleIntitule)),
          if (!serre) Ecart.vXs,
          texteValeur,
        ],
      ),
    );
  }
}

/// Les quatre actions : tuiles icone pleine violette + libelle (images).
/// Une action sans rappel n'est pas rendue.
class _ActionsEleve extends StatelessWidget {
  const _ActionsEleve({
    required this.eleve,
    required this.actions,
    required this.serre,
    required this.large,
    this.recite = false,
  });

  final EleveSeance eleve;
  final ActionsSeance actions;
  final bool serre;

  /// GESTES-POINTEUR : cet eleve recite.
  final bool recite;

  /// Colonne desktop : deux rangees de deux, pour qu'aucun libelle ne se
  /// coupe au milieu d'un mot (WCAG 1.4.10 et 1.4.12).
  final bool large;

  @override
  Widget build(BuildContext context) {
    final bool dansLaSalle = eleve.statut == StatutEleveSeance.connecte;
    final List<(AppIcon, String, ValueChanged<EleveSeance>?)>
    liste = <(AppIcon, String, ValueChanged<EleveSeance>?)>[
      // Ordre de E14 : Faire reciter, Appeler, Noter, Signaler.
      //
      // GESTES-POINTEUR (directeur, 11/11/2026) : ces deux gestes agissent
      // dans la salle. Pour un eleve qui n'y est pas, ils ne peuvent pas
      // aboutir : ils ne sont pas rendus (un absent se joint par les
      // notifications et le remplacement, jamais par un second circuit).
      // L'eleve qui recite porte « Terminer la recitation » a la place.
      (
        AppIcons.reciter,
        recite
            ? t.salle.gestes.terminerRecitation
            : t.salle.seance.faireReciter,
        dansLaSalle || recite ? actions.onChoisirPourReciter : null,
      ),
      (
        AppIcons.rappeler,
        t.salle.seance.rappeler,
        dansLaSalle ? actions.onRappeler : null,
      ),
      (AppIcons.noter, t.tc.classe.action.noter, actions.onNoter),
      // « Signaler / un besoin » : l'espace insecable garde « un
      // besoin » ensemble, comme sur les images.
      (AppIcons.signaler, t.salle.seance.signalerBesoin, actions.onSignaler),
    ];
    final List<String> libelles = <String>[
      for (final (AppIcon _, String libelle, ValueChanged<EleveSeance>? r)
          in liste)
        if (r != null) libelle,
    ];
    final List<Widget> tuiles = <Widget>[
      for (final (AppIcon icone, String libelle, ValueChanged<EleveSeance>? r)
          in liste)
        if (r != null)
          Expanded(
            child: _TuileAction(
              icone: icone,
              libelle: libelle,
              serre: serre,
              onPress: () => r(eleve),
            ),
          ),
    ];
    if (tuiles.isEmpty) return const SizedBox.shrink();
    Widget rangee(List<Widget> enfants) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xs,
        children: enfants,
      ),
    );
    return Padding(
      padding: EdgeInsets.only(top: serre ? AppSpacing.xs : AppSpacing.sm),
      // TB-RC (TB-10 reste a, TB_RAPPORT §d n. 23) : le nombre de colonnes
      // se mesure. Quatre tant que chaque mot tient dans sa tuile, sinon
      // deux, sinon une : jamais un mot coupe (« Appeler di / scrèteme /
      // nt » a 768 et 1440 x2). Colonne desktop : deux au plus (images).
      child: LayoutBuilder(
        builder: (BuildContext contexte, BoxConstraints c) {
          int colonnes = colonnesSansCoupure(
            contexte,
            libelles: libelles,
            largeur: c.maxWidth,
          );
          if (large) colonnes = math.min(colonnes, 2);
          colonnes = math.min(colonnes, tuiles.length);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.xs,
            children: <Widget>[
              for (int i = 0; i < tuiles.length; i += colonnes)
                rangee(<Widget>[
                  ...tuiles.sublist(i, math.min(i + colonnes, tuiles.length)),
                  // La derniere rangee garde la largeur des autres.
                  for (
                    int k = tuiles.length;
                    k < i + colonnes && i + colonnes > tuiles.length;
                    k++
                  )
                    const Spacer(),
                ]),
            ],
          );
        },
      ),
    );
  }
}

/// TB-RC (TB-10 reste a) : le plus grand nombre de colonnes (4, 2 ou 1) ou
/// chaque mot de chaque [libelles] tient dans sa tuile, au style et au
/// texte de l'appareil (marges de `BoutonOutil` en tuile comprises). Un
/// espace insecable garde ses deux mots ensemble.
@visibleForTesting
int colonnesSansCoupure(
  BuildContext context, {
  required List<String> libelles,
  required double largeur,
}) {
  final TextStyle style = DefaultTextStyle.of(context).style
      .merge(Theme.of(context).textTheme.labelSmall);
  final TextScaler echelle = MediaQuery.textScalerOf(context);
  final TextDirection sens = Directionality.of(context);
  double motLePlusLong = 0;
  for (final String libelle in libelles) {
    for (final String mot in libelle.split(' ')) {
      final TextPainter peintre = TextPainter(
        text: TextSpan(text: mot, style: style),
        textDirection: sens,
        textScaler: echelle,
        maxLines: 1,
      )..layout();
      motLePlusLong = math.max(motLePlusLong, peintre.width);
      peintre.dispose();
    }
  }
  for (final int n in const <int>[4, 2]) {
    // La cellule, moins la marge interieure et le filet de la tuile.
    final double cellule =
        (largeur - (n - 1) * AppSpacing.xs) / n - 2 * AppSpacing.xs - 2;
    if (motLePlusLong <= cellule) return n;
  }
  return 1;
}

/// TB-10 (plan V2 §4.3, §20 ; UX-20) : « Autoriser a ecrire » ou « Retirer
/// l'autorisation d'ecrire », pres de la personne, apres ses quatre actions.
/// La consequence se dit avant le choix (K-58) ; bouton discret pose en bas
/// de la carte, sur toute sa largeur (K-56). Rien d'irreversible : le droit
/// se retire comme il se donne, les traits restent.
class _AutorisationEcrire extends StatelessWidget {
  const _AutorisationEcrire({
    required this.eleve,
    required this.serre,
    required this.onPress,
  });

  final EleveSeance eleve;
  final bool serre;
  final VoidCallback onPress;

  /// La cle du bouton d'un eleve.
  static Key cle(EleveSeance eleve) =>
      ValueKey<String>('autoriser-ecrire-${cleEleveSeance(eleve)}');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool autorise = eleve.peutEcrire;
    return Padding(
      padding: EdgeInsets.only(top: serre ? AppSpacing.sm : AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // TB-RC (revue TB-R, m12) : l'aide a son propre noeud, lu juste
          // avant le bouton, jamais fondue dans la carte avant le prenom.
          Semantics(
            container: true,
            child: Text(
              autorise
                  ? t.salle.seance.ecriture.retirerAide
                  : t.salle.seance.ecriture.autoriserAide(prenom: eleve.prenom),
              style: palette.inkMuted.applyTo(_styleFiche(context)),
            ),
          ),
          Ecart.vSm,
          ActionPrincipale(
            key: cle(eleve),
            libelle: autorise
                ? t.salle.seance.ecriture.retirer
                : t.salle.seance.ecriture.autoriser,
            libelleSemantique: autorise
                ? t.salle.seance.ecriture.retirerSemantique(
                    dePrenom: deDevant(eleve.prenom),
                  )
                : t.salle.seance.ecriture.autoriserSemantique(
                    prenom: eleve.prenom,
                  ),
            niveau: NiveauAction.secondaire,
            onPress: onPress,
          ),
        ],
      ),
    );
  }
}

class _TuileAction extends StatelessWidget {
  const _TuileAction({
    required this.icone,
    required this.libelle,
    required this.serre,
    required this.onPress,
  });

  final AppIcon icone;
  final String libelle;
  final bool serre;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    // Feuille du telephone : la cible reste d'au moins 48 de haut.
    constraints: BoxConstraints(
      minHeight: serre
          ? AppSpacing.titreEcran
          : AppSpacing.respiration + AppSpacing.lg,
    ),
    // La surface, l'icone et le mot centres sont peints par le composant du
    // core (K-54).
    child: BoutonOutil(
      icone: icone,
      libelle: libelle,
      avecLibelle: true,
      forme: FormeBoutonOutil.tuile,
      lignesLibelle: 3,
      iconeActive: true,
      serre: serre,
      tailleIcone: AppSpacing.xxl + AppSpacing.xs,
      onPress: onPress,
    ),
  );
}

/// Le prenom d'une cle de la file : l'inscrit de meme cle, ou la cle elle-meme.
String _prenomDe(String cle, List<EleveSeance> eleves) {
  for (final EleveSeance e in eleves) {
    if (cleEleveSeance(e) == cle) return e.prenom;
  }
  return cle;
}

/// La file de recitation (EN-9) : l'eleve en cours, puis « A suivre ».
/// Ni minuteur par eleve (E9), ni evaluation (E8) : des prenoms, rien d'autre.
class FileRecitationSeance extends StatelessWidget {
  const FileRecitationSeance({
    required this.file,
    required this.eleves,
    super.key,
  });

  final FileRecitation file;
  final List<EleveSeance> eleves;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? actif = file.actif;
    final List<String> suivants = file.suivantsVisibles;
    final TextStyle corps = textes.bodyMedium ?? const TextStyle();
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final TextStyle fort = palette.inkStrong.applyTo(corps);
    // EN-9b : un bloc compact (intitule, puis une seule ligne « Mariam
    // recite · A suivre : Yusuf, Aïcha »), pour que la fiche depliee et les
    // inscrits restent a l'ecran sous lui.
    final List<Widget> ligne = <Widget>[
      Text(
        actif == null
            ? t.tc.classe.recitation.personne
            : t.tc.classe.recitation.actif(prenom: _prenomDe(actif, eleves)),
        style: AppTypography.graisse(fort, FontWeight.w700),
      ),
      if (suivants.isNotEmpty) ...<Widget>[
        ExcludeSemantics(child: Text('·', style: discret)),
        Text(t.salle.seance.aSuivre, style: discret),
        ExcludeSemantics(child: Text(':', style: discret)),
        for (int i = 0; i < suivants.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(_prenomDe(suivants[i], eleves), style: fort),
              if (i < suivants.length - 1) Text(',', style: fort),
            ],
          ),
      ],
    ];
    return DecoratedBox(
      key: const ValueKey<String>('file-recitation'),
      decoration: palette.surfaceOverlay.decoration(
        borderRadius: AppRadius.arrondiMd,
        side: palette.borderHairline.asBorderSide(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(t.salle.seance.fileRecitation, style: discret),
            ),
            // Une seule lecture pour toute la ligne, annoncee quand l'eleve
            // qui recite change (W-413, W-131) ; l'intitule reste a part.
            MergeSemantics(
              child: Semantics(
                liveRegion: true,
                child: Wrap(
                  spacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: ligne,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// RUBAN-ORDINATEUR (MODES-AFFICHAGE §4) : ce qu'il faut au panneau pour
/// montrer les visages vivants, sans connaitre le moteur de la salle (il
/// recoit des widgets deja montes, ADR-001). Decide par `/salle`
/// (`salle_page.dart`), transmis par `PorteeMediaSalle`.
class VisagesPanneau {
  /// Cree les visages.
  const VisagesPanneau({required this.image, this.parle});

  /// L'image d'une personne par son identite (le `profile_id`), ou `null` :
  /// camera eteinte ou pas encore recue (le cadre montre alors sa photo ou
  /// son initiale).
  final Widget? Function(String identite) image;

  /// La parole d'une personne par son identite, pour l'anneau ; `null` : pas
  /// d'anneau.
  final Stream<bool> Function(String identite)? parle;
}

/// La largeur du cadre d'un eleve dans sa carte (ruban) : 96, en 4/3 (96 x
/// 72). Assez pour voir qui est la et s'il regarde ; la bouche qui se
/// corrige est celle de l'eleve qui recite, en grand.
const double largeurCadreRuban = AppSpacing.respiration * 1.5;

/// La forme des cadres du ruban (MODES-AFFICHAGE §3 : jamais plus large que
/// 4/3).
const double rapportCadreRuban = 4 / 3;

/// Un cadre vivant de la salle ([CadreVisage]) qui ecoute seul la parole de
/// sa personne : la page ne se reconstruit pas a chaque changement d'orateur
/// (audit reseau e). Dans une carte, le nom est ecrit a cote : le cadre ne le
/// repete pas.
class CadreVivant extends StatefulWidget {
  /// Cree le cadre.
  const CadreVivant({
    required this.identite,
    required this.prenom,
    super.key,
    this.nom = '',
    this.image,
    this.parle,
    this.microCoupe = false,
    this.recite = false,
  });

  /// L'identite de la personne (photo, parole).
  final String identite;

  /// Le prenom, pour l'initiale.
  final String prenom;

  /// Le nom ecrit sur le cadre ; vide quand la carte l'ecrit deja.
  final String nom;

  /// L'image, ou `null`.
  final Widget? image;

  /// La parole de la personne, ou `null`.
  final Stream<bool> Function(String identite)? parle;

  /// Vrai : le micro est ferme.
  final bool microCoupe;

  /// Vrai : la personne recite.
  final bool recite;

  @override
  State<CadreVivant> createState() => _EtatCadreVivant();
}

class _EtatCadreVivant extends State<CadreVivant> {
  bool _parle = false;
  StreamSubscription<bool>? _abonnement;

  @override
  void initState() {
    super.initState();
    _ecouter();
  }

  @override
  void didUpdateWidget(CadreVivant ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.identite != widget.identite ||
        (ancien.parle == null) != (widget.parle == null)) {
      unawaited(_abonnement?.cancel());
      _abonnement = null;
      _parle = false;
      _ecouter();
    }
  }

  void _ecouter() {
    final Stream<bool> Function(String)? parle = widget.parle;
    if (parle == null) return;
    try {
      _abonnement = parle(widget.identite).listen((bool p) {
        if (mounted && p != _parle) setState(() => _parle = p);
      });
    } on StateError {
      // Un moteur a flux unique (demonstration) : pas d'anneau.
      _abonnement = null;
    }
  }

  @override
  void dispose() {
    unawaited(_abonnement?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CadreVisage(
    nom: widget.nom,
    prenom: widget.prenom,
    image: widget.image,
    personneId: widget.identite,
    microCoupe: widget.microCoupe,
    parle: _parle,
    recite: widget.recite,
  );
}

/// RUBAN-ORDINATEUR (MODES-AFFICHAGE §5) : la tete d'une carte qui passe de
/// l'initiale au cadre vivant (vers le ruban) ou l'inverse (vers la grille).
/// Dans le meme temps et le meme sens que la grille du centre
/// ([PassageScene]) : vers le ruban, le cadre grandit en fondu (240 ms) ;
/// vers la grille, il s'efface plus vite (160 ms). La carte change de
/// hauteur sur le ressort sans rebond, rien ne saute. Rien au montage
/// (arrivee, reconnexion). « Reduire les animations » : un fondu seul.
class _PassageCadre extends StatelessWidget {
  const _PassageCadre({required this.vivant, required this.child});

  final bool vivant;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool reduit = AppMouvement.mouvementReduit(context);
    final Duration duree = reduit
        ? AppMouvement.fonduEntree
        : vivant
        ? AppMouvement.deplacementEntreeOrdinateur
        : AppMouvement.deplacementSortieOrdinateur;
    final Widget fondu = AnimatedSwitcher(
      duration: duree,
      reverseDuration: reduit
          ? AppMouvement.fonduSortie
          : AppMouvement.deplacementSortieOrdinateur,
      switchInCurve: AppMouvement.courbeFondu,
      switchOutCurve: AppMouvement.courbeFondu,
      layoutBuilder: (Widget? courant, List<Widget> anciens) => Stack(
        alignment: AlignmentDirectional.topStart,
        children: <Widget>[
          // Ce qui part ne se touche plus et ne se lit plus.
          for (final Widget a in anciens)
            IgnorePointer(child: ExcludeSemantics(child: a)),
          ?courant,
        ],
      ),
      transitionBuilder: (Widget enfant, Animation<double> a) => FadeTransition(
        opacity: a,
        child: reduit
            ? enfant
            : ScaleTransition(
                scale: Tween<double>(
                  begin: PassageScene.echelleRuban,
                  end: 1,
                ).animate(a),
                alignment: AlignmentDirectional.centerStart.resolve(
                  Directionality.of(context),
                ),
                child: enfant,
              ),
      ),
      child: child,
    );
    // « Reduire les animations » : la carte prend sa hauteur d'un coup
    // (`AnimatedSize` ne supporte pas une duree nulle).
    if (reduit) return fondu;
    return AnimatedSize(
      duration: duree,
      curve: AppMouvement.ressortDeplacement,
      alignment: AlignmentDirectional.topStart,
      child: fondu,
    );
  }
}
