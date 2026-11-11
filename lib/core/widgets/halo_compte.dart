// NAV-REFONTE, etape 2a (decisions du directeur du 09/11/2026) : le halo du
// cercle Compte de la barre flottante, et la feuille « En ce moment ».
//
// Le halo est une lumiere qui rayonne autour du cercle, comme une lampe (pas
// un anneau). Elle tourne quelques fois, puis reste en lueur fixe (WCAG
// 2.2.2) ; sous mouvement reduit, la lueur fixe d'emblee. Persistance
// (arbitrage du garde-cap du 09/11/2026) : la lueur ne s'eteint jamais tant
// que la situation dure ; la rotation (ses quelques tours, jamais infinie) se
// rejoue a chaque ouverture de l'application, a chaque retour au premier plan
// et a chaque apparition d'un ecran. Un seul halo a la
// fois, le plus prioritaire l'emporte : Urgent, puis la salle ouverte, puis
// Nouveau. La salle ouverte (etape 2b, 10/11/2026) : un halo vert qui respire,
// lu dans le calcul unique « salle rejoignable » (tuteur et enseignant).
//
// Jamais la couleur seule : la vitesse (rapide, un seul tour), la pastille
// d'icone de 18 sur le bord, et le nom lu (« Compte, une alerte urgente »).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'action_principale.dart';
import 'app_bottom_sheet.dart';
import 'halo_lumiere.dart';
import 'lien_fleche.dart';

export 'halo_lumiere.dart' show NatureHalo;

/// L'etat du halo du cercle Compte : calcule une fois, hors du widget, par une
/// fonction pure de la source (`haloDepuisNotifications`), jamais deduit d'un
/// role.
@immutable
class EtatHaloCompte {
  /// Une alerte urgente : [titre] et [detail] sont ceux de la notification,
  /// deja rediges par le serveur ; [chemin] ouvre l'alerte.
  EtatHaloCompte.urgent({
    required this.titre,
    required this.chemin,
    this.detail,
  }) : nature = NatureHalo.urgent,
       nombre = null,
       idsNonLus = const <String>{},
       action = t.nav.halo.ouvrirAlerte,
       agir = null;

  /// La salle est ouverte : [action] est le mot du bouton (« Rejoindre la
  /// salle avec Yasmine », « Rejoindre la salle ») et [agir] le geste de
  /// l'ecran qui sait entrer (le meme que son bouton) ; [chemin] est l'ecran
  /// de ce bouton, lu si le geste manque.
  EtatHaloCompte.salle({
    required this.action,
    required this.chemin,
    required void Function(BuildContext contexte) this.agir,
    this.detail,
  }) : nature = NatureHalo.salle,
       titre = t.classe.entree.annonce.fenetreOuverte,
       nombre = null,
       idsNonLus = const <String>{};

  /// [nombre] nouveautes a lire ; [chemin] ouvre les notifications.
  EtatHaloCompte.nouveau({
    required int this.nombre,
    required this.chemin,
    this.idsNonLus = const <String>{},
  }) : nature = NatureHalo.nouveau,
       titre = t.nav.halo.nouveauTitre(n: nombre, nombre: nombre),
       detail = null,
       action = t.nav.halo.lire,
       agir = null;

  /// Ce que le halo signale.
  final NatureHalo nature;

  /// Le titre de la feuille « En ce moment ».
  final String titre;

  /// La ligne sous le titre, ou `null`.
  final String? detail;

  /// Le mot du bouton plein de la feuille.
  final String action;

  /// Le chemin interne que le bouton plein ouvre.
  final String chemin;

  /// Le geste du bouton plein quand il n'est pas un chemin (entrer dans la
  /// salle, avec son billet), ou `null`.
  final void Function(BuildContext contexte)? agir;

  /// Le nombre de nouveautes, pour [NatureHalo.nouveau].
  final int? nombre;

  /// Les notifications non lues que ce halo signale, pour
  /// [NatureHalo.nouveau] : toucher le cercle les marque vues, et le halo
  /// « Nouveau » s'eteint jusqu'a la prochaine nouveaute (arbitrage du
  /// garde-cap du 09/11/2026). Urgent reste allume tant que la situation dure.
  final Set<String> idsNonLus;

  /// La lumiere de cet etat (seule exception au branding, 09/11).
  AppHaloColor get couleurs => nature.couleurs;

  /// L'icone de la pastille.
  IconData get icone => switch (nature) {
    NatureHalo.urgent => AppIcons.avertissement.actif,
    NatureHalo.salle => AppIcons.camera.actif,
    NatureHalo.aPreparer => throw StateError(_horsDuCercle),
    NatureHalo.nouveau => AppIcons.notifications.actif,
  };

  /// Le mot court ecrit sous « Compte » dans la tuile du Mode Accessibilite.
  String get motCourt => switch (nature) {
    NatureHalo.urgent => t.nav.halo.urgentMot,
    NatureHalo.salle => t.tc.groupe.temps.salleOuverteCourt,
    NatureHalo.aPreparer => throw StateError(_horsDuCercle),
    NatureHalo.nouveau => t.nav.halo.nouveauMot,
  };

  /// Le nom lu du cercle : [compte] (« Compte », « Profil »...) et l'etat.
  String nomAccessible(String compte) => switch (nature) {
    NatureHalo.urgent => t.nav.halo.urgentNom(compte: compte),
    NatureHalo.salle => t.nav.halo.salleNom(compte: compte),
    NatureHalo.aPreparer => throw StateError(_horsDuCercle),
    NatureHalo.nouveau => t.nav.halo.nouveauNom(
      n: nombre ?? 0,
      compte: compte,
      nombre: nombre ?? 0,
    ),
  };

  /// La duree d'un tour de lumiere.
  Duration get dureeTour => nature.dureeTour;

  /// Le nombre de tours avant la lumiere fixe.
  int get tours => nature.tours;

  @override
  bool operator ==(Object other) =>
      other is EtatHaloCompte &&
      other.nature == nature &&
      other.titre == titre &&
      other.detail == detail &&
      other.chemin == chemin &&
      other.nombre == nombre;

  @override
  int get hashCode => Object.hash(nature, titre, detail, chemin, nombre);
}

/// Le halo autour d'un cercle de [diametre] : la lumiere qui tourne puis la
/// lueur fixe, la pastille d'etat sur le bord (cote fin, a gauche en arabe),
/// et le retournement unique de [child] vers l'icone d'etat. Sans [etat],
/// [child] seul.
///
/// Purement visuel : le nom lu est porte par le bouton qui l'entoure. Le halo
/// ne retarde jamais un toucher (DECISION-FLUIDITE) : il ne recoit aucun
/// geste.
class HaloCompte extends StatefulWidget {
  /// Cree le halo.
  const HaloCompte({
    required this.etat,
    required this.diametre,
    required this.child,
    this.apparition,
    super.key,
  });

  /// Ce qui fait rejouer la rotation quand il change : l'ecran affiche (la
  /// destination ouverte). La rotation se rejoue aussi a chaque retour de
  /// l'application au premier plan, et a la construction du halo (ouverture
  /// de l'application, barre qui revient apres une tache focalisee).
  final Object? apparition;

  /// La cle de la pastille d'etat (tests).
  static const Key pastilleKey = ValueKey<String>('halo-compte-pastille');

  /// La cle de la lumiere qui tourne (tests) : celle de [HaloLumiere].
  static const Key lumiereKey = HaloLumiere.lumiereKey;

  /// La cle de la lueur fixe (tests) : celle de [HaloLumiere].
  static const Key lueurKey = HaloLumiere.lueurKey;

  /// Diametre de la pastille d'etat.
  static const double diametrePastille = 18;

  /// Le cerclage de la pastille, de la couleur de la surface : il la detache
  /// de la photo.
  static const double epaisseurCerclage = 2;

  /// Portee de la lumiere au-dela du bord du cercle : bornee, elle ne deborde
  /// pas sur l'onglet voisin (8 d'ecart et le bord de la pilule).
  static const double portee = HaloLumiere.portee;

  /// L'etat signale, ou `null` : aucun halo.
  final EtatHaloCompte? etat;

  /// Le diametre du cercle entoure.
  final double diametre;

  /// Le cercle (la photo ou l'initiale).
  final Widget child;

  @override
  State<HaloCompte> createState() => _EtatHaloCompte();
}

class _EtatHaloCompte extends State<HaloCompte>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  AnimationController? _retournement;
  bool _reduit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    // Retour au premier plan : la personne regarde, la lumiere tourne.
    if (etat == AppLifecycleState.resumed) _rejouer();
  }

  void _rejouer() {
    if (!mounted) return;
    setState(() {
      _arreter();
      if (!_reduit) _demarrer(widget.etat);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduit = AppMouvement.mouvementReduit(context);
    if (reduit != _reduit) {
      _reduit = reduit;
      if (reduit) _arreter();
    }
    if (_retournement == null && !_reduit) _demarrer(widget.etat);
  }

  @override
  void didUpdateWidget(HaloCompte ancien) {
    super.didUpdateWidget(ancien);
    // Un nouvel etat (ou une autre nature) rejoue la lumiere ; le meme etat,
    // reconstruit, ne la relance pas.
    // Un autre ecran qui apparait rejoue aussi la rotation (jamais infinie).
    if (ancien.etat?.nature != widget.etat?.nature ||
        ancien.apparition != widget.apparition) {
      _arreter();
      if (!_reduit) _demarrer(widget.etat);
    }
  }

  void _demarrer(EtatHaloCompte? etat) {
    if (etat == null) return;
    _retournement = AnimationController(
      vsync: this,
      duration: AppMouvement.retournementHalo,
    )..forward();
  }

  void _arreter() {
    _retournement?.dispose();
    _retournement = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _arreter();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EtatHaloCompte? etat = widget.etat;
    if (etat == null) return widget.child;
    final AppPalette palette = AppPalette.of(context);
    final double d = widget.diametre;
    final AnimationController? retournement = _retournement;
    return SizedBox.square(
      dimension: d,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          // La lumiere : elle tourne, puis la lueur fixe la remplace
          // (HaloLumiere, un seul composant du core, arbitre par ecran).
          HaloLumiere(
            nature: etat.nature,
            taille: Size.square(d),
            apparition: widget.apparition,
          ),
          if (retournement == null)
            widget.child
          else
            AnimatedBuilder(
              animation: retournement,
              builder: (BuildContext _, Widget? photo) =>
                  _retourne(etat, retournement.value, photo!, d),
              child: widget.child,
            ),
          PositionedDirectional(
            end: 0,
            bottom: 0,
            child: _Pastille(etat: etat, cerclage: palette.surfaceRaised),
          ),
        ],
      ),
    );
  }

  /// Le retournement unique : la photo se tourne vers l'icone d'etat, puis
  /// revient (decision du directeur du 09/11/2026).
  static Widget _retourne(
    EtatHaloCompte etat,
    double t,
    Widget photo,
    double diametre,
  ) {
    final double angle = math.sin(math.pi * t) * math.pi;
    final bool dos = angle > math.pi / 2;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(dos ? angle - math.pi : angle),
      child: dos ? _Dos(etat: etat, diametre: diametre) : photo,
    );
  }
}

/// Le dos du cercle pendant le retournement : l'icone d'etat.
class _Dos extends StatelessWidget {
  const _Dos({required this.etat, required this.diametre});

  final EtatHaloCompte etat;
  final double diametre;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: etat.couleurs.pastille.decoration(
      borderRadius: BorderRadius.circular(diametre / 2),
    ),
    child: SizedBox.square(
      dimension: diametre,
      child: Center(
        child: IconTheme(
          data: IconThemeData(
            color: etat.couleurs.pastille.onBackground,
            size: diametre / 2,
          ),
          child: Icon(etat.icone),
        ),
      ),
    ),
  );
}

/// La pastille d'etat de 18, sur le bord du cercle, comme un badge.
class _Pastille extends StatelessWidget {
  const _Pastille({required this.etat, required this.cerclage});

  final EtatHaloCompte etat;
  final AppColorPair cerclage;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: HaloCompte.pastilleKey,
    decoration: BoxDecoration(
      color: etat.couleurs.pastille.background,
      shape: BoxShape.circle,
      border: Border.fromBorderSide(
        BorderSide(
          color: cerclage.background,
          width: HaloCompte.epaisseurCerclage,
        ),
      ),
    ),
    child: SizedBox.square(
      dimension: HaloCompte.diametrePastille,
      child: Center(
        child: IconTheme(
          data: IconThemeData(
            color: etat.couleurs.pastille.onBackground,
            size: AppSpacing.md,
          ),
          child: Icon(etat.icone),
        ),
      ),
    ),
  );
}

/// La pastille d'etat posee dans un coin de la tuile Compte du Mode
/// Accessibilite (aucune lumiere qui tourne : une lueur fixe sur le
/// contour, decision du directeur du 09/11).
class PastilleHaloCompte extends StatelessWidget {
  /// Cree la pastille.
  const PastilleHaloCompte({required this.etat, super.key});

  /// L'etat signale.
  final EtatHaloCompte etat;

  @override
  Widget build(BuildContext context) =>
      _Pastille(etat: etat, cerclage: AppPalette.of(context).surfaceRaised);
}

/// La feuille « En ce moment », ouverte au toucher du cercle Compte quand un
/// halo est actif : l'action (ouvrir l'alerte, lire) en seul bouton plein
/// (K-56), et dessous « Mon compte ». Sans halo, le toucher ouvre directement
/// le Compte. La feuille est courte et ne defile pas ; Echap la ferme et rend
/// le focus au cercle (`AppBottomSheet`).
Future<void> ouvrirFeuilleEnCeMoment(
  BuildContext context, {
  required EtatHaloCompte etat,
  required String cheminCompte,
  required void Function(String chemin) onAller,
}) async {
  final String? aller = await AppBottomSheet.ouvrir<String>(
    context,
    titre: t.nav.halo.enCeMoment,
    constructeur: (BuildContext contexte) => _CorpsEnCeMoment(etat: etat),
    actions: (BuildContext contexte) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ActionPrincipale(
          libelle: etat.action,
          onPress: () => Navigator.of(
            contexte,
          ).pop(etat.agir == null ? etat.chemin : _agirIci),
        ),
        Ecart.vMd,
        LienFleche(
          libelle: t.nav.halo.monCompte,
          onPress: () => Navigator.of(contexte).pop(cheminCompte),
        ),
      ],
    ),
  );
  if (aller == _agirIci) {
    // Le geste de l'ecran qui sait entrer, apres la fermeture de la feuille.
    if (context.mounted) etat.agir?.call(context);
  } else if (aller != null) {
    onAller(aller);
  }
}

/// Ce que la feuille rend quand son bouton est un geste et non un chemin (un
/// chemin interne commence toujours par « / »).
const String _agirIci = 'agir';

class _CorpsEnCeMoment extends StatelessWidget {
  const _CorpsEnCeMoment({required this.etat});

  final EtatHaloCompte etat;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? detail = etat.detail;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ExcludeSemantics(
          child: _Dos(etat: etat, diametre: AppSpacing.section),
        ),
        Ecart.hMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                etat.titre,
                style: palette.inkStrong.applyTo(
                  AppTypography.graisse(
                    textes.titleMedium ?? const TextStyle(),
                    FontWeight.w700,
                  ),
                ),
              ),
              if (detail != null && detail.isNotEmpty) ...<Widget>[
                Ecart.vXs,
                Text(
                  detail,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// « A preparer » est une lumiere d'ecran (lots E et H), jamais celle du
/// cercle Compte : aucun `EtatHaloCompte` ne la porte.
const String _horsDuCercle = 'a preparer : lumiere d ecran, pas du cercle';
