// SCENE-CLASSE (directeur, 11/11/2026) : la scene de `/salle` en mode
// Classe, sortie de `salle_page.dart`. La regle :
// `docs/current/salle/MODES-AFFICHAGE.md` §2 et §3 ; journal D-028.
//
// Les visages en grille ([GrilleVisages]), chacun dans LE cadre de la salle
// ([CadreVisage]) ; sa propre image est le dernier cadre, jamais un objet
// flottant ; « Ouvrir le Coran » se pose sous la grille, jamais sur un
// visage ; seul dans la salle, la scene d'attente.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/livekit_session_provider.dart';
import '../../core/video/video_session_provider.dart';
import '../../core/widgets/cadre_visage.dart';
import '../../core/widgets/grille_visages.dart';
import '../../core/widgets/porte_lumiere.dart';
import '../../core/widgets/scene_attente.dart';
import '../salle_seance/media_salle.dart';
import 'vue_salle.dart';

/// La scene : les visages en grille, soi-meme en dernier, et ce qui
/// s'affiche quand on est seul.
///
/// MODES-AFFICHAGE §3 : l'enseignant d'abord (chez l'eleve, l'ordre de la
/// vue), l'eleve qui recite en premier, soi-meme en dernier ; l'ordre ne
/// change pas quand quelqu'un parle (l'anneau suffit).
class SceneClasse extends StatelessWidget {
  /// Cree la scene.
  const SceneClasse({
    required this.vue,
    super.key,
    this.attendu,
    this.recitant,
    this.menuPour,
    this.moiDejaEnCadre = false,
    this.tutoie = false,
    this.fond = false,
  });

  /// VISAGES (directeur, 12/11/2026, point 8) : vrai quand cette scene est
  /// LA scene en mode Classe (`ModeScene.classe`) : le visuel de l'ouverture
  /// (le symbole et sa porte de lumiere, [PorteLumiere]) se pose en fond,
  /// a tres faible opacite, SOUS les visages. Faux (par defaut) quand la
  /// scene vit a cote d'un document ou du tableau : jamais de fond la.
  final bool fond;

  /// La cle du fond doux de la scene (tests, captures).
  static const Key cleFond = ValueKey<String>('scene-classe-fond');

  /// L'opacite du fond doux, theme clair : une image decorative, jamais un
  /// texte (aucune opacite sur du texte).
  static const double opaciteFondClair = 0.07;

  /// L'opacite du fond doux, theme sombre : le violet du symbole se lit
  /// moins sur la nuit de la page.
  static const double opaciteFondSombre = 0.12;

  /// AGE-SALLE (garde-cap, 11/11/2026) : l'eleve devant l'ecran est un
  /// enfant, les phrases d'attente lui disent « tu » (l'age est lu sur le
  /// serveur par la page, jamais devine ici).
  final bool tutoie;

  /// GESTES-POINTEUR (directeur, 11/11/2026 : « la video de l'enseignant
  /// apparait deux fois ») : **une personne, un cadre**. Vrai quand l'image
  /// de la personne devant l'ecran a deja son cadre ailleurs (la vignette de
  /// l'enseignant) : la scene ne la montre pas une seconde fois.
  final bool moiDejaEnCadre;

  final VueSalle vue;

  /// Le prenom de l'enseignant attendu, pour l'attente de l'eleve.
  final String? attendu;

  /// Point 2 (30/10/2026) : l'identite de l'eleve qui recite, mis en avant
  /// chez tous (premier cadre, marque « Recite »), ou `null`.
  final String? recitant;

  /// Le menu des gestes sur un cadre (enseignant, `can_moderate`), ou `null`.
  final Widget? Function(ParticipantSalle, {required bool recite})? menuPour;

  /// La hauteur d'une rangee de la bande de l'observateur (presentation
  /// lue, `_CorpsDocument`) : deux respirations.
  static const double _hauteurPlancher = AppSpacing.respiration * 2;

  /// L'ecart entre deux cadres (K-55, VIDEO-TUILE-1) : 16.
  static const double _ecart = AppSpacing.lg;

  /// Le nombre de colonnes de la bande de l'observateur pour [total]
  /// cadres dans [gabarit].
  static int _colonnes(int total, Gabarit gabarit) => switch (total) {
    2 => gabarit.estLarge ? 2 : 1,
    3 || 4 => 2,
    _ => gabarit.estLarge ? 3 : 2,
  };

  /// TB-RC (TB_RAPPORT §d n° 5 et 11) : la hauteur ou toutes les rangees de
  /// [total] cadres tiennent a leur plancher, sans defilement interne (la
  /// bande de la scene de l'observateur).
  static double hauteurEntiere(int total, Gabarit gabarit) {
    final int colonnes = _colonnes(total, gabarit);
    final int lignes = (total + colonnes - 1) ~/ colonnes;
    return lignes * _hauteurPlancher + (lignes - 1) * _ecart;
  }

  /// La premiere rangee a son plancher, et l'ecart qui la suit.
  static const double premiereRangee = _hauteurPlancher + _ecart;

  /// La cle de la zone de l'action sous la grille (tests, captures).
  static const Key cleAction = ValueKey<String>('scene-classe-action');

  /// RUBAN-TELEPHONE : la cle de son propre cadre quand on est seul dans la
  /// salle, camera allumee (tests, captures).
  static const Key cleMoiSeul = ValueKey<String>('scene-classe-moi-seul');

  /// La largeur maximale de son propre cadre quand on est seul : celle d'un
  /// cadre de la grille ([largeurMaxCadre]). En dessous, il prend toute la
  /// largeur du bloc d'attente (directeur, 11/11/2026, soir).
  static const double largeurMoiSeul = largeurMaxCadre;

  /// RUBAN-TELEPHONE (MODES-AFFICHAGE §2, regle 2) : LE cadre vivant de
  /// [identite] hors de la grille (la vignette de l'eleve, la capsule de
  /// l'enseignant, la bande de cote) : le meme widget que dans la grille,
  /// nourri par le moteur (image, micro, parole). `null` : la personne n'est
  /// pas dans la salle.
  static Widget? cadreHorsGrille(
    VueSalle vue,
    String identite, {
    String? recitant,
    String? libelleNom,
    Widget? coin,
    bool detache = false,
  }) {
    for (final ParticipantSalle p in <ParticipantSalle>[
      ?vue.moi,
      ?vue.dominant,
      ...vue.autres,
    ]) {
      if (p.identite == identite) {
        return _CadreParticipant(
          key: ValueKey<String>('cadre-hors-grille-${p.identite}'),
          participant: p,
          moi: p.estLocal,
          recite: recitant != null && p.identite == recitant,
          // CAMARADES (12/11/2026) : la regle de la video, a un seul
          // endroit ([videoMontree]).
          videoPermise: videoMontree(vue, p.identite, recitant: recitant),
          libelleNom: libelleNom,
          coin: coin,
          detache: detache,
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Les distants dans l'ordre de lecture que la vue a decide : le role
    // attendu d'abord, les autres ensuite.
    final List<ParticipantSalle> ordre = <ParticipantSalle>[
      if (vue.dominant case final ParticipantSalle premier) premier,
      ...vue.autres,
    ];
    // Point 2 : l'eleve qui recite passe en premier, le reste garde son
    // ordre.
    final List<ParticipantSalle> distants = <ParticipantSalle>[
      ...ordre.where((ParticipantSalle p) => p.identite == recitant),
      ...ordre.where((ParticipantSalle p) => p.identite != recitant),
    ];

    // SCENE-CLASSE : sa propre image est le DERNIER cadre de la grille, et
    // seulement quand la camera publie (« elle disparait si sa camera est
    // coupee ») ; jamais quand elle a deja un cadre ailleurs.
    final ParticipantSalle? moi = switch (vue.moi) {
      final ParticipantSalle local when local.camera && !moiDejaEnCadre =>
        local,
      _ => null,
    };
    final ({String libelle, VoidCallback onPress})? action =
        ActionSousLaScene.de(context);

    // VIDEO-TUILE-1 : aucun cadre ne touche le bord de l'ecran (16 de
    // chaque cote) ni ne passe sous les commandes (16 dessous).
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: distants.isEmpty
          // Seul dans la salle : la scene d'attente, inchangee.
          ? _Seul(
              role: vue.role,
              attendu: attendu,
              tutoie: tutoie,
              action: action,
              // RUBAN-TELEPHONE (MODES-AFFICHAGE §3, precise le 11/11) :
              // camera allumee, son propre cadre sous la scene d'attente.
              moi: moi,
            )
          : Stack(
              children: <Widget>[
                if (fond) const Positioned.fill(child: _FondDoux()),
                Positioned.fill(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        child: GrilleVisages(
                          cadres: <EntreeGrille>[
                            for (final ParticipantSalle p in distants)
                              EntreeGrille(
                                cle: ValueKey<String>(p.identite),
                                cadre: _CadreParticipant(
                                  participant: p,
                                  moi: p.estLocal,
                                  recite: p.identite == recitant,
                                  // CAMARADES (12/11/2026) : chez un eleve,
                                  // un camarade est en video seulement
                                  // pendant qu'il recite ([videoMontree]).
                                  videoPermise: videoMontree(
                                    vue,
                                    p.identite,
                                    recitant: recitant,
                                  ),
                                  menu: menuPour?.call(
                                    p,
                                    recite: p.identite == recitant,
                                  ),
                                ),
                              ),
                            if (moi case final ParticipantSalle local)
                              EntreeGrille(
                                cle: ValueKey<String>(local.identite),
                                // Couper sa camera retire son cadre tout de suite.
                                attendreAuDepart: false,
                                cadre: _CadreParticipant(
                                  participant: local,
                                  moi: true,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // « Ouvrir le Coran » : sous la grille, centre, jamais sur un
                      // visage (MODES-AFFICHAGE §3).
                      if (action != null) ...<Widget>[
                        Ecart.vLg,
                        Center(
                          key: cleAction,
                          child: ActionSousLaScene.bouton(action),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// Le fond doux de la scene en mode Classe (VISAGES, point 8) : le visuel de
/// l'ouverture, le symbole de la marque et sa porte de lumiere
/// ([PorteLumiere], qui pose le logo par `BrandLogo`), centre, a tres faible
/// opacite, derriere la grille. Decoratif : exclu de la semantique, ne recoit
/// aucun geste. Immobile : rien a reduire sous « Reduire les animations ».
class _FondDoux extends StatelessWidget {
  const _FondDoux();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: RepaintBoundary(
        child: Opacity(
          key: SceneClasse.cleFond,
          opacity: AppPalette.of(context).estSombre
              ? SceneClasse.opaciteFondSombre
              : SceneClasse.opaciteFondClair,
          child: const Center(
            child: FractionallySizedBox(
              widthFactor: 0.8,
              heightFactor: 0.8,
              child: FittedBox(child: PorteLumiere()),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Le cadre d'un participant de la salle : [CadreVisage], nourri par le
/// moteur (son image) et par la parole en direct.
///
/// Lot salle 3, audit reseau (e) : un changement d'orateur seul ne
/// reconstruit pas la page ; c'est ce cadre, et lui seul, qui l'ecoute.
class _CadreParticipant extends ConsumerStatefulWidget {
  const _CadreParticipant({
    required this.participant,
    required this.moi,
    super.key,
    this.recite = false,
    this.menu,
    this.libelleNom,
    this.coin,
    this.detache = false,
    this.videoPermise = true,
  });

  final ParticipantSalle participant;

  /// CAMARADES (directeur, 12/11/2026) : faux quand la regle de la salle
  /// ([videoMontree]) ne montre pas la camera de cette personne a qui
  /// regarde : le cadre garde sa photo, ou sa couleur et son initiale.
  final bool videoPermise;
  final bool moi;
  final bool recite;
  final Widget? menu;

  /// RUBAN-TELEPHONE : voir [CadreVisage.libelleNom] et [CadreVisage.coin].
  final String? libelleNom;
  final Widget? coin;
  final bool detache;

  @override
  ConsumerState<_CadreParticipant> createState() => _CadreParticipantEtat();
}

class _CadreParticipantEtat extends ConsumerState<_CadreParticipant> {
  late bool _parle = widget.participant.parle;
  StreamSubscription<List<ParticipantSalle>>? _abonnement;

  @override
  void initState() {
    super.initState();
    try {
      _abonnement = ref
          .read(moteurSalleProvider)
          .participants
          .listen(_surParticipants);
    } on StateError {
      // Un moteur a flux unique (demonstration) : la parole reste celle de
      // la liste recue.
      _abonnement = null;
    }
  }

  void _surParticipants(List<ParticipantSalle> liste) {
    if (!mounted) return;
    for (final ParticipantSalle p in liste) {
      if (p.identite == widget.participant.identite) {
        if (p.parle != _parle) setState(() => _parle = p.parle);
        return;
      }
    }
  }

  @override
  void dispose() {
    unawaited(_abonnement?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ParticipantSalle p = widget.participant;
    // **L'ecran ne recoit pas une piste, il recoit un widget deja monte**
    // (ADR-001) : aucun import de `livekit_client` ici.
    final VideoSessionProvider moteur = ref.watch(moteurSalleProvider);
    final Widget? image = widget.videoPermise
        ? moteur.renduVideo(p.identite)
        : null;
    return CadreVisage(
      nom: widget.moi ? t.salle.vousMeme : p.nom,
      prenom: p.nom,
      image: image,
      // PHOTOS-A (04/11/2026) : la photo de chaque personne se lit par son
      // id a la source unique ; le serveur dit si l'appelant peut la voir.
      personneId: p.identite.isEmpty ? null : p.identite,
      microCoupe: !p.micro,
      parle: _parle,
      recite: widget.recite,
      menu: widget.menu,
      libelleNom: widget.libelleNom,
      coin: widget.coin,
      detache: widget.detache,
      // RA-STAFF : la direction est montree par l'icone de l'academie.
      staff: estStaff(p.role),
    );
  }
}

/// Seul dans la salle.
///
/// Lot salle 2 (directeur, 25/10/2026, capture du telephone de l'eleve) :
/// l'attente etait un texte blanc sur gris clair, illisible. Elle se pose sur
/// sa propre surface teintee du theme (`surfaceSunken`, jamais du blanc pur),
/// avec l'ornement de la marque, un titre qui nomme qui l'on attend et une
/// phrase : ce qui se passe et quoi faire. Encre de la surface (contraste
/// > 4,5:1, clair et sombre). Le depart de l'enseignant ramene ici.
class _Seul extends StatelessWidget {
  const _Seul({
    required this.role,
    this.attendu,
    this.action,
    this.moi,
    this.tutoie = false,
  });

  /// AGE-SALLE : un enfant est tutoye.
  final bool tutoie;

  /// RUBAN-TELEPHONE : soi-meme, camera allumee et sans cadre ailleurs, ou
  /// `null` : la scene d'attente seule.
  final ParticipantSalle? moi;

  final RoleSalle role;

  /// N3 : l'action de la scene (« Ouvrir le Coran »), posee sous la phrase
  /// d'attente, jamais dessus ; `null` ailleurs.
  final ({String libelle, VoidCallback onPress})? action;

  /// Le prenom de l'enseignant attendu (eleve), s'il est connu. Le titre
  /// Sayyid / Sayyida n'est pas lu dans `/salle` : le prenom seul, jamais
  /// « le professeur » (TB-10).
  final String? attendu;

  /// La cle de l'attente (tests, captures).
  static const Key cle = ValueKey<String>('salle-attente');

  /// La largeur du cadre de soi sous l'attente : toute la largeur utile du
  /// bloc (les memes bords que la phrase), bornee comme un cadre de la
  /// grille, et jamais plus que ce que la hauteur restante permet en 4:3
  /// (le symbole, les deux phrases, les ecarts et l'action sont deja la).
  /// Plancher : le plus petit cadre de la grille ; s'il ne tient pas (petit
  /// telephone, texte agrandi), `null` : pas de cadre du tout, jamais un
  /// cadre coupe ni un bloc qui defile pour lui.
  double? _largeurMoiSeul(
    BuildContext context,
    BoxConstraints c,
    (String, String) phrase, {
    required bool avecAction,
  }) {
    final TextTheme textes = Theme.of(context).textTheme;
    final double utile = math.max(0, c.maxWidth - 2 * AppSpacing.xxl);
    final double cible = math.min(SceneClasse.largeurMoiSeul, utile);
    if (!c.maxHeight.isFinite) return cible;
    double hauteurDe(String texte, TextStyle? style) {
      final TextPainter mesure = TextPainter(
        text: TextSpan(text: texte, style: style),
        textAlign: TextAlign.center,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: utile);
      final double h = mesure.height;
      mesure.dispose();
      return h;
    }

    final double cote = math.min(
      SceneAttente.coteStandard,
      c.biggest.shortestSide / 2,
    );
    final double pris =
        2 * AppSpacing.xxl +
        cote +
        AppSpacing.lg +
        hauteurDe(phrase.$1, textes.titleMedium) +
        AppSpacing.sm +
        hauteurDe(phrase.$2, textes.bodyMedium) +
        AppSpacing.lg +
        (avecAction
            ? AppSpacing.lg + AppMetriques.of(context).cibleTactile
            : 0);
    final double reste = c.maxHeight - pris;
    if (reste < coteMinCadre) return null;
    return math.min(cible, (reste * 4 / 3).floorToDouble());
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? nom = attendu?.trim();

    // Qui manque depend de qui attend.
    final (String, String) phrase = switch (role) {
      RoleSalle.eleve => (
        nom == null || nom.isEmpty
            ? (tutoie ? t.salle.seulEnseignantTutoie : t.salle.seulEnseignant)
            : t.salle.attenteDe(deNom: deDevant(nom, cle: 'salle.attenteDe')),
        tutoie
            ? t.salle.seulEnseignantDetailTutoie
            : t.salle.seulEnseignantDetail,
      ),
      RoleSalle.enseignant => (t.salle.seulEleve, t.salle.seulEleveDetail),
      RoleSalle.candidat || RoleSalle.intervieweur => (
        t.salle.seulEntretien,
        t.salle.seulEntretienDetail,
      ),
      RoleSalle.tuteurObservateur ||
      RoleSalle.controleur ||
      RoleSalle.administrateurIncognito ||
      RoleSalle.administrateurVisible ||
      RoleSalle.inconnu => (
        t.salle.seulObservation,
        t.salle.seulObservationDetail,
      ),
    };

    // SALLE-200-1 : la phrase d'attente defile plutot que de deborder quand
    // le texte est agrandi sur un petit ecran.
    // Directeur, 11/11/2026 : l'attente porte le symbole de la marque au
    // centre d'ondes lentes ([SceneAttente]).
    return DecoratedBox(
      key: cle,
      decoration: palette.surfaceSunken.decoration(
        borderRadius: AppRadius.arrondiLg,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SceneAttente(
                  cote: math.min(
                    SceneAttente.coteStandard,
                    c.biggest.shortestSide / 2,
                  ),
                ),
                Ecart.vLg,
                Text(
                  phrase.$1,
                  textAlign: TextAlign.center,
                  style: palette.surfaceSunken.applyTo(
                    textes.titleMedium ?? const TextStyle(),
                  ),
                ),
                Ecart.vSm,
                Text(
                  phrase.$2,
                  textAlign: TextAlign.center,
                  style: palette.surfaceSunken.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
                // RUBAN-TELEPHONE : son propre cadre, centre, borne a 240,
                // dans la mise en page (rien ne flotte) : on verifie son
                // image avant l'arrivee des autres.
                if ((
                      moi,
                      moi == null
                          ? null
                          : _largeurMoiSeul(
                              context,
                              c,
                              phrase,
                              avecAction: action != null,
                            ),
                    )
                    case (
                      final ParticipantSalle local,
                      final double largeurMoi,
                    )) ...<Widget>[
                  Ecart.vLg,
                  SizedBox(
                    key: SceneClasse.cleMoiSeul,
                    // Directeur, 11/11/2026 (soir) : « ca reste random la
                    // ou il est place ». Le cadre prend toute la largeur du
                    // bloc d'attente (les memes bords que la phrase), borne
                    // comme un cadre de la grille ; 4:3.
                    //
                    // Et jamais plus haut que ce qui reste du bloc : sur un
                    // ecran large et bas, la hauteur commande et le cadre
                    // s'arrete a la marge du bas (il etait coupe a 1440 x
                    // 900, vu par le test « eleve sur ordinateur »).
                    width: largeurMoi,
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      // Pose seul sur une surface de la meme couleur que
                      // son fond : son bord se dessine (WCAG 1.4.11), pour
                      // que « Vous » ne flotte jamais sans cadre tant que
                      // l'image n'est pas arrivee.
                      child: _CadreParticipant(
                        participant: local,
                        moi: true,
                        detache: true,
                      ),
                    ),
                  ),
                ],
                if (action
                    case final ({String libelle, VoidCallback onPress})
                        a) ...<Widget>[Ecart.vLg, ActionSousLaScene.bouton(a)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
