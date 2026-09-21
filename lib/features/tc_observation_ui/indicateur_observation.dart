import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_observation/port_annonce_observation.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/status_pill.dart';

/// Vrai quand cet eleve doit recevoir l'indicateur discret.
///
/// **Lui seul.** La specification 11.3 est explicite : « les autres eleves
/// n'ont pas besoin d'etre interrompus ». Une classe de cinq enfants ou tout le
/// monde apprend qu'un parent regarde transformerait une visite de deux minutes
/// en evenement collectif.
///
/// Fonction pure, testable sans arbre de widgets.
///
/// **Reservee au cote ENSEIGNANT.** Elle filtre une liste d'annonces, et cette
/// liste ne parvient jamais a un eleve : `annonces_observation` la refuse a qui
/// n'est pas l'enseignant de la seance. L'eleve, lui, passe par
/// [monTuteurObserveProvider], qui interroge `annonce_observation_pour_moi`
/// (migration `0040`) -- une lecture que le serveur borne lui-meme a la ligne
/// de l'appelant. Le filtrage cote client ne serait pas une borne de vie
/// privee : la borne est en base.
bool enfantConcerneParObservation(
  List<AnnonceObservation> annonces,
  String? monProfilId,
) {
  if (monProfilId == null) {
    return false;
  }
  for (final AnnonceObservation annonce in annonces) {
    if (annonce.enfantConcerneId == monProfilId) {
      return true;
    }
  }
  return false;
}

/// L'annonce lue par l'enseignant pendant qu'un ou plusieurs tuteurs observent.
///
/// **Discrete par construction.** Ni bandeau qui pousse le contenu, ni son, ni
/// fenetre. Et **aucune notification de sortie** : le flux cesse simplement de
/// porter l'annonce.
///
/// Deux formes, decidees par le nombre d'observateurs (regle dictee par
/// l'operateur le 21/09) :
///
/// * **Un seul tuteur** : un oeil et la phrase entiere, « Tuteur de {prenom}
///   observe », avec le temps restant. Rien ne bouge, rien ne se replie : une
///   ligne ne merite pas une animation.
/// * **Deux ou plus** : un oeil, les prenoms TRONQUES, et leur nombre. Les
///   prenoms se montrent quelques secondes a l'arrivee, puis **glissent
///   derriere l'oeil** et cessent d'etre visibles. Le survol de la souris, la
///   pression du doigt ou le focus clavier les font ressortir ; leur fin les
///   renvoie derriere l'oeil.
///
/// **Pourquoi replier plutot qu'empiler.** Le parent de chaque enfant peut
/// venir : a cinq enfants, cinq lignes repoussent le contenu pedagogique de
/// cinq lignes vers le bas, pendant que l'enseignant enseigne. La forme
/// repliee tient sur une ligne quel que soit le nombre d'observateurs.
///
/// **Le tuteur n'est jamais nomme, l'enfant l'est.** C'est la decision de
/// l'operateur : l'enseignant connait deja les cinq enfants de son groupe, et
/// savoir DE QUI le parent regarde est precisement ce qui lui sert. L'identite
/// du tuteur, elle, ne lui apprendrait rien et circulerait pour rien.
class IndicateurObservation extends StatefulWidget {
  /// Cree l'indicateur.
  const IndicateurObservation({required this.annonces, super.key});

  /// Les observations en cours. Vide = rien ne s'affiche.
  final List<AnnonceObservation> annonces;

  /// A partir de combien d'observateurs les prenoms se replient.
  static const int seuilDeRepli = 2;

  /// La bande de prenoms repliable.
  ///
  /// Posee pour que le test MESURE le repli au lieu de le supposer : une fois
  /// replies, les prenoms restent dans l'arbre, simplement rognes a une largeur
  /// nulle. `find.text` les trouverait donc encore, et un test ecrit dessus
  /// serait vert quoi qu'il arrive.
  @visibleForTesting
  static const Key cleBandePrenoms = Key('tc-observation-bande-prenoms');

  @override
  State<IndicateurObservation> createState() => _IndicateurObservationEtat();
}

class _IndicateurObservationEtat extends State<IndicateurObservation> {
  /// Vrai pendant la fenetre d'affichage automatique qui suit un changement.
  bool _montreParMinuterie = false;
  Timer? _repli;

  @override
  void initState() {
    super.initState();
    _montrerPuisReplier();
  }

  @override
  void didUpdateWidget(IndicateurObservation ancien) {
    super.didUpdateWidget(ancien);
    // Un tuteur qui arrive ou qui repart rouvre la fenetre : sans cela, le
    // deuxieme observateur d'une seance apparaitrait deja replie, et
    // l'enseignant ne saurait jamais qu'il est la.
    if (_signature(ancien.annonces) != _signature(widget.annonces)) {
      _montrerPuisReplier();
    }
  }

  @override
  void dispose() {
    _repli?.cancel();
    super.dispose();
  }

  /// Ce qui distingue deux etats d'observation. Le temps restant en est exclu :
  /// il change toutes les dix secondes et rouvrirait la fenetre sans arret.
  static String _signature(List<AnnonceObservation> annonces) => annonces
      .map((AnnonceObservation a) => '${a.enfantConcerneId}/${a.prenomEnfant}')
      .join('\u0000');

  void _montrerPuisReplier() {
    _repli?.cancel();
    if (widget.annonces.length < IndicateurObservation.seuilDeRepli) {
      _montreParMinuterie = false;
      return;
    }
    _montreParMinuterie = true;
    _repli = Timer(AppMouvement.retourLocalMaintien, () {
      if (mounted) {
        setState(() => _montreParMinuterie = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.annonces.isEmpty) {
      return const SizedBox.shrink();
    }
    if (widget.annonces.length < IndicateurObservation.seuilDeRepli) {
      return _LigneUnique(annonce: widget.annonces.first);
    }
    return _BandeRepliable(
      annonces: widget.annonces,
      montreParMinuterie: _montreParMinuterie,
      // Une pression rouvre la fenetre : au doigt, le survol n'existe pas, et
      // sans cela un appui bref ne laisserait rien le temps d'etre lu.
      onPress: () => setState(_montrerPuisReplier),
    );
  }
}

/// L'oeil de l'observation, a la taille et a l'encre des indicateurs discrets.
class _Oeil extends StatelessWidget {
  const _Oeil();

  @override
  Widget build(BuildContext context) => IconTheme(
    data: AppPalette.of(context).inkMuted.asIconTheme(size: AppSpacing.xl),
    child: Icon(AppIcons.observationEnCours.repos),
  );
}

/// La forme a un seul observateur : l'oeil et la phrase entiere.
class _LigneUnique extends StatelessWidget {
  const _LigneUnique({required this.annonce});

  final AnnonceObservation annonce;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          const _Oeil(),
          Ecart.hSm,
          Expanded(
            child: Text(
              annonce.libelle,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
          if (annonce.tempsRestant case final Duration restant) ...<Widget>[
            Ecart.hSm,
            StatusPill(
              libelle: t.tc.observation.annonce.restant(
                secondes: restant.inSeconds,
              ),
              ton: TonEtat.neutre,
            ),
          ],
        ],
      ),
    );
  }
}

/// La forme a plusieurs observateurs : l'oeil, les prenoms qui glissent, le
/// nombre.
class _BandeRepliable extends StatelessWidget {
  const _BandeRepliable({
    required this.annonces,
    required this.montreParMinuterie,
    required this.onPress,
  });

  final List<AnnonceObservation> annonces;
  final bool montreParMinuterie;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle styleDiscret = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Pressable.selon(
        onPress: onPress,
        // **Le lecteur d'ecran recoit les PRENOMS, pas seulement le compte.**
        // Le repli est une economie de PLACE, jamais une reserve
        // d'information : a l'oeil nu les prenoms sont a un survol de distance,
        // et savoir DE QUI le parent regarde est ce qui sert a l'enseignant.
        // Les annoncer ici est le SEUL moyen de les rendre atteignables : ni le
        // survol de la souris ni le focus clavier n'existent pour un lecteur
        // d'ecran tactile, et un `Opacity` a zero retire son sous-arbre de
        // l'arbre semantique (`RenderOpacity` ne le visite pas a alpha nul).
        libelleSemantique: <String>[
          t.tc.observation.annonce.tuteursObservent(nombre: annonces.length),
          for (final AnnonceObservation annonce in annonces) annonce.libelle,
        ].join('. '),
        // La zone est une ligne d'en-tete, pas un bouton : lui imposer la
        // cible tactile de 48 points la ferait pousser le contenu, ce que tout
        // ce composant existe pour eviter.
        respecterCibleTactile: false,
        arrondiFocus: AppRadius.arrondiFull,
        constructeur: (BuildContext context, EtatPression etat) {
          // Trois entrees pour un meme etat : le survol n'existe pas au doigt,
          // le focus n'existe pas au telephone, et la pression n'existe pas au
          // clavier (`05-regles-responsive.md` section 5).
          final bool deploye =
              montreParMinuterie || etat.survole || etat.presse || etat.focus;

          // `ExcludeSemantics` : le libelle ci-dessus porte deja le compte ET
          // les prenoms. Sans cela, l'etat deploye les annoncerait deux fois,
          // une fois par le libelle et une fois par les `Text` eux-memes.
          return ExcludeSemantics(
            child: Row(
              children: <Widget>[
                const _Oeil(),
                Ecart.hSm,
                Flexible(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: deploye ? 1 : 0),
                    // `AppMouvement.duree` rend zero sous reduction du
                    // mouvement : les prenoms apparaissent et disparaissent
                    // alors d'un coup, sans glissement, et le composant garde
                    // son sens.
                    duration: AppMouvement.duree(
                      context,
                      deploye
                          ? AppMouvement.apparition
                          : AppMouvement.feuilleFermeture,
                    ),
                    curve: deploye ? AppMouvement.entree : AppMouvement.sortie,
                    builder:
                        (
                          BuildContext context,
                          double avancement,
                          Widget? prenoms,
                        ) => ClipRect(
                          // Le repli se fait vers le DEBUT de la ligne, c'est-a-
                          // dire vers l'oeil : a gauche en francais, a droite en
                          // arabe. `AlignmentDirectional` est ce qui le garantit
                          // dans les deux sens de lecture.
                          child: Align(
                            key: IndicateurObservation.cleBandePrenoms,
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: avancement,
                            child: Opacity(opacity: avancement, child: prenoms),
                          ),
                        ),
                    child: _Prenoms(annonces: annonces, style: styleDiscret),
                  ),
                ),
                Ecart.hSm,
                // Le nombre reste lisible repli ou non : c'est lui qui dit
                // combien de prenoms sont caches derriere l'oeil.
                Text('${annonces.length}', style: styleDiscret),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Les prenoms des enfants observes, tronques, sur une seule ligne.
class _Prenoms extends StatelessWidget {
  const _Prenoms({required this.annonces, required this.style});

  final List<AnnonceObservation> annonces;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (final (int rang, AnnonceObservation annonce)
          in annonces.indexed) ...<Widget>[
        if (rang > 0) Ecart.hSm,
        // `Flexible` sans `flex` : chaque prenom recoit une part EGALE de la
        // bande, pas la place dont il a besoin. `RenderFlex` calcule
        // `spacePerFlex` une fois pour toutes avant de mesurer le moindre
        // enfant, et la place qu'un prenom court n'utilise pas n'est PAS
        // redistribuee au suivant. Consequence assumee : a cinq prenoms, un
        // « Abdurrahman » se coupe alors qu'« Ali » laisse de la place a cote.
        // C'est le comportement le plus previsible -- chaque prenom garde la
        // meme largeur d'une lecture a l'autre -- et la bande est de toute
        // facon un apercu : le libelle semantique, lui, porte les prenoms
        // entiers.
        Flexible(
          child: Text(
            annonce.prenomEnfant,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: style,
          ),
        ),
      ],
    ],
  );
}

/// L'indicateur discret, du cote de l'enfant observe.
///
/// Un mot, sans action et sans bouton. Un enfant de sept ans n'a rien a decider
/// ici : il a seulement le droit de savoir.
///
/// **La borne de vie privee est en base, pas ici.** Ce temoin s'allume sur
/// [monTuteurObserveProvider], qui interroge `annonce_observation_pour_moi`
/// (migration `0040`). Cette fonction porte `enfant_profile_id = auth.uid()`
/// dans son WHERE : elle ne peut rendre que la ligne de l'appelant. Un enfant
/// n'apprend donc jamais que le parent d'un AUTRE enfant observe -- ni son nom,
/// ni son existence, ni leur nombre (specification 11.3, « les autres eleves
/// n'ont pas besoin d'etre interrompus »). Mesure du 21/09 sur la base, deux
/// enfants de foyers differents dans le meme groupe : l'enfant observe recoit
/// `observe: true`, l'autre `observe: false`.
class IndicateurObservationEnfant extends StatelessWidget {
  /// Cree l'indicateur.
  const IndicateurObservationEnfant({required this.visible, super.key});

  /// Vrai quand le tuteur de cet enfant observe.
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    final AppPalette palette = AppPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const _Oeil(),
        Ecart.hSm,
        Flexible(
          child: Text(
            t.tc.observation.annonce.enfantIndicateur,
            style: palette.inkMuted.applyTo(
              Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
            ),
          ),
        ),
      ],
    );
  }
}
