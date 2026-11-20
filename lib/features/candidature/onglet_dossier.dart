// PE-B5 (directeur, 19/11/2026) : l'onglet Dossier de l'accueil du candidat.
// Une ligne d'etapes, UN seul « a faire maintenant » (ou « rien a faire, nous
// vous ecrirons »), puis le dossier element par element : chaque ligne se
// deplie au toucher et dit ce qu'elle est (retours du directeur sur la
// maquette, PLAN §15.2).
//
// Rien n'est calcule ici : `lireDossier` range ce que `etat_dossier()` rend.
// Mouvement : ce qui se touche s'enfonce et revient en ressort
// (`ToucherVivant`), la ligne d'etapes se remplit une fois, puis tout se tait.
// Sous « Reduire les effets », plus aucun mouvement, toute l'information reste.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/mode_accessibilite.dart';
import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/dossier/etat_dossier.dart';
import '../../core/fraicheur/avis_ephemere.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/vivant/praxis_vivant.dart';
import '../../core/vivant/ressort.dart';
import '../../core/vivant/toucher_vivant.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/status_pill.dart';
import '../com_annonces/port_annonces_direction.dart';
import 'carte_entretien_proche.dart';
import 'carte_reprise.dart';
import 'lecture_dossier.dart';
import 'ligne_etapes.dart';
import 'majorite_etape.dart';
import 'portail_candidature.dart';

bool _effetsReduits(BuildContext context) =>
    EffetsReduits.de(context) || AppMouvement.mouvementReduit(context);

/// Ce qui se deplie sous une ligne : la hauteur suit le contenu en douceur.
/// Sous « Reduire les effets », le contenu est pose d'emblee, sans mouvement
/// (un `AnimatedSize` de duree nulle se relance pendant sa propre mise en
/// page : il n'est alors pas construit du tout).
class Depliant extends StatelessWidget {
  /// Cree le depliant.
  const Depliant({required this.child, super.key});

  /// Le contenu ; une boite vide de pleine largeur quand la ligne est repliee.
  final Widget child;

  @override
  Widget build(BuildContext context) => _effetsReduits(context)
      ? child
      : AnimatedSize(
          duration: AppMouvement.apparition,
          curve: AppMouvement.entree,
          alignment: AlignmentDirectional.topStart,
          child: child,
        );
}

/// L'onglet Dossier : ou en est la candidature, ce qu'il y a a faire
/// maintenant, ce qui se passe ensuite.
class OngletDossier extends ConsumerWidget {
  /// Cree l'onglet. [perime] : la derniere relecture a echoue, ce qui est
  /// montre date de la lecture d'avant. [onRelire] relit le dossier.
  const OngletDossier({
    required this.dossier,
    required this.onRelire,
    required this.onVoirAcademie,
    super.key,
    this.perime = false,
  });

  /// L'etat du dossier, avec sa candidature.
  final EtatDossier dossier;

  /// Vrai quand la derniere relecture a echoue.
  final bool perime;

  /// Relit le dossier.
  final Future<void> Function() onRelire;

  /// Ouvre l'onglet Academie (l'annonce en une ligne y mene).
  final VoidCallback onVoirAcademie;

  /// La cle du titre de la page.
  static const Key cleTitre = ValueKey<String>('dossier-titre');

  /// La cle de la carte « a faire maintenant ».
  static const Key cleAFaire = ValueKey<String>('dossier-a-faire');

  /// La cle de la carte « rien a faire ».
  static const Key cleRien = ValueKey<String>('dossier-rien-a-faire');

  /// La cle de la phrase « Ensuite ».
  static const Key cleEnsuite = ValueKey<String>('dossier-ensuite');

  /// La cle de l'avis « pas a jour ».
  static const Key clePerime = ValueKey<String>('dossier-perime');

  /// La cle du lien « Actualiser ».
  static const Key cleActualiser = ValueKey<String>('dossier-actualiser');

  /// La cle de la ligne [code] du dossier.
  static Key cleLigne(String code) => ValueKey<String>('dossier-ligne-$code');

  /// La cle du detail deplie de la ligne [code].
  static Key cleDetail(String code) => ValueKey<String>('dossier-detail-$code');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CandidatureDossier c = dossier.candidature;
    final LectureDossier lu = lireDossier(dossier);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final GoRouter? routeur = GoRouter.maybeOf(context);
    final int? rang = rangDeSalle(c);
    final String? passage = phrasePassage(c);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final TextStyle corps = textes.bodyMedium ?? const TextStyle();
    final TextStyle muet = palette.inkMuted.applyTo(corps);
    final ActionDossier? action = lu.action;
    final String? entretien = libelleEntretienPortail(c);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // SALLE2-ENTRETIEN (directeur, 14/11/2026) : l'entretien proche ou
        // ouvert, en tete (une alerte urgente va toujours en tete).
        const CarteEntretienProche(),
        // A9 : l'annonce nouvelle, en une ligne qui se ferme, AU-DESSUS du
        // titre (maquette) ; sans annonce, la marge de tete d'une page.
        AnnonceEnLigne(onVoir: onVoirAcademie),
        // Le titre de la page : celui de `PageShell`, pose ici pour passer
        // sous l'annonce.
        Semantics(
          header: true,
          child: TexteSansCoupure(
            t.attente.titreDossier,
            key: cleTitre,
            style: textes.headlineLarge ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        if (perime) ...<Widget>[
          _AvisPerime(horsLigne: horsLigne, onRelire: onRelire),
          Ecart.vLg,
        ],
        // MAJEUR (directeur, 16/11/2026) : l'age a attester, la ou le
        // candidat est (rien n'est rendu une fois fait).
        CarteMajorite(candidature: c),
        if (passage != null) ...<Widget>[
          Text(passage, key: EnteteSalle.passageKey, style: textes.bodyLarge),
          Ecart.vLg,
        ],
        if (rang != null) ...<Widget>[
          // L'etat se dit a cote de la position (« Etape 1 sur 3 · … ») :
          // aucun second titre.
          LigneEtapes(
            rang: rang,
            part: lu.partFaite,
            fermee: lu.fermee,
            etat: lu.titre,
          ),
        ] else if (lu.titre != null)
          Semantics(
            header: true,
            child: Text(
              lu.titre!,
              key: StatutCandidature.titreKey,
              style: textes.titleMedium,
            ),
          ),
        for (final PhraseDossier p in lu.phrases) ...<Widget>[
          Ecart.vMd,
          Text(
            p.texte,
            key: p.cle == null ? null : ValueKey<String>(p.cle!),
            style: p.forte
                ? textes.bodyLarge
                : p.muette
                ? muet
                : corps,
          ),
        ],
        if (lu.retiree) ...<Widget>[
          Ecart.vLg,
          CarteReprise(candidature: c),
        ] else if (!lu.fermee) ...<Widget>[
          Ecart.vLg,
          // Praxis, en petit : UNE information urgente, ou rien.
          if (PraxisDuDossier.urgence(dossier, lu)
              case final String urgent) ...[
            PraxisDuDossier(phrase: urgent, soucieux: pieceRefusee(dossier)),
            Ecart.vMd,
          ],
          // UN seul « a faire maintenant », ou « rien a faire ».
          if (action != null)
            CarteAFaire(
              key: cleAFaire,
              phrase: action.phrase,
              libelle: action.libelle,
              cleBouton: action.chemin == Routes.attenteEntretien
                  ? EnteteSalle.entretienKey
                  : null,
              onPress: () => routeur?.go(action.chemin),
            )
          else
            CarteRienAFaire(
              key: cleRien,
              phrase: lu.attendMajorite
                  ? t.recrutement.accueil.aFaire.majorite
                  : null,
            ),
          if (lu.ensuite != null) ...<Widget>[
            Ecart.vMd,
            Text(lu.ensuite!, key: cleEnsuite, style: muet),
          ],
          // SALLE-2-ENTRETIEN : l'entretien a fixer ou fixe garde son entree
          // (« Voir mon entretien »), quand il n'est pas deja l'action a
          // faire maintenant.
          if (entretien != null &&
              action?.chemin != Routes.attenteEntretien) ...<Widget>[
            Ecart.vSm,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: LienFleche(
                key: EnteteSalle.entretienKey,
                libelle: entretien,
                alignerEnDebut: true,
                onPress: () => routeur?.go(Routes.attenteEntretien),
              ),
            ),
          ],
        ],
        if (lu.lignes.isNotEmpty) ...<Widget>[
          Ecart.vXl,
          // Des contenus lies : UNE carte a lignes fines (K-55).
          CarteGroupee(
            sections: <Widget>[
              for (final LigneDossier l in lu.lignes)
                LigneDepliable(key: cleLigne(l.code), ligne: l),
            ],
          ),
        ],
        // Apres l'envoi, les reponses se relisent (lecture seule de CAND-01).
        if (lu.relisible) ...<Widget>[
          Ecart.vMd,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              key: const ValueKey<String>('portail-relire'),
              libelle: t.recrutement.portail.relire,
              alignerEnDebut: true,
              onPress: () => routeur?.go(Routes.attenteCandidature),
            ),
          ),
        ],
        if (lu.actualisable && !perime) ...<Widget>[
          Ecart.vMd,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              key: cleActualiser,
              libelle: t.attente.actualiser,
              fleche: false,
              alignerEnDebut: true,
              onPress: () => unawaited(onRelire()),
            ),
          ),
        ],
      ],
    );
  }
}

/// « Ce que vous voyez n'a pas pu etre mis a jour » : une phrase vraie et
/// « Reessayer » (contrat de navigation §8). Hors connexion, elle le dit.
class _AvisPerime extends StatelessWidget {
  const _AvisPerime({required this.horsLigne, required this.onRelire});

  final bool horsLigne;
  final Future<void> Function() onRelire;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final e = t.recrutement.accueil.etat;
    return AppCard(
      key: OngletDossier.clePerime,
      surface: palette.washAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              horsLigne ? e.horsLigne : e.perime,
              style: palette.washAccent.applyTo(
                Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
          LienFleche(
            libelle: t.commun.reessayer,
            fleche: false,
            alignerEnDebut: true,
            onPress: () => unawaited(onRelire()),
          ),
        ],
      ),
    );
  }
}

/// La carte « A faire maintenant » : la seule zone pleine de l'ecran, avec
/// son seul bouton. Violet de la marque en clair, lavande en sombre (jamais
/// le violet sur un fond sombre).
class CarteAFaire extends StatefulWidget {
  /// Cree la carte.
  const CarteAFaire({
    required this.phrase,
    required this.libelle,
    required this.onPress,
    super.key,
    this.cleBouton,
  });

  /// La cle du bouton, quand un test ou un lien d'avant le nomme.
  final Key? cleBouton;

  /// Ce qu'il y a a faire.
  final String phrase;

  /// Le libelle du bouton.
  final String libelle;

  /// Le geste.
  final VoidCallback onPress;

  @override
  State<CarteAFaire> createState() => _EtatCarteAFaire();
}

class _EtatCarteAFaire extends State<CarteAFaire>
    with SingleTickerProviderStateMixin<CarteAFaire>, VieDesRessorts {
  // La carte se pose a l'arrivee : elle part un peu plus petite, depasse a
  // peine, puis se tait.
  final Ressort _pose = Ressort(1, raideur: 240, frein: 15);
  bool _lance = false;

  @override
  Iterable<Ressort> get ressorts => <Ressort>[_pose];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lance) return;
    _lance = true;
    _pose
      ..x = 0.96
      ..cible = 1;
    WidgetsBinding.instance.addPostFrameCallback((_) => reveil());
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair fond = palette.surfacePrimary;
    final TextTheme textes = theme.textTheme;
    // Le bouton de la carte est son negatif : la couleur du texte de la
    // carte en fond, la couleur de la carte en texte (blanc et violet en
    // clair, encre et lavande en sombre). Aucune couleur hors de la palette.
    final AppColorPair negatif = AppColorPair(
      background: fond.onBackground,
      onBackground: fond.background,
    );
    final ThemeData themeBouton = theme.copyWith(
      extensions: <ThemeExtension<ThemeExtension<dynamic>>>[
        ...theme.extensions.values
            .where((ThemeExtension<dynamic> e) => e is! AppPalette)
            .cast<ThemeExtension<ThemeExtension<dynamic>>>(),
        palette.copyWith(surfaceActionDouce: negatif),
      ],
    );
    return Transform.scale(
      scale: _pose.x,
      child: Material(
        color: fond.background,
        shape: AppRadius.coinContinu(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                t.recrutement.accueil.aFaire.titre,
                style: fond.applyTo(textes.titleMedium ?? const TextStyle()),
              ),
              Ecart.vSm,
              Text(
                widget.phrase,
                style: fond.applyTo(textes.bodyLarge ?? const TextStyle()),
              ),
              // DESIGN-GOV B : l'objet vers le bouton qui agit dessus, 16.
              Ecart.vLg,
              Theme(
                data: themeBouton,
                child: ActionPrincipale(
                  key: widget.cleBouton,
                  libelle: widget.libelle,
                  onPress: widget.onPress,
                  fleche: true,
                  pilule: true,
                  pleineLargeur: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Praxis sur l'accueil du candidat (directeur, 20/11/2026) : present, en
/// plus petit que sur les autres ecrans, pour pointer UNE information
/// urgente. Il ne dit que des faits rendus par le serveur pour ce candidat ;
/// rien quand il n'y a rien a dire. Le dessin est celui de `PraxisVivant`
/// (reference de la competence praxis-rewayah), employe sans le modifier ;
/// il se tait seul, et ne bouge pas sous « Reduire les effets ».
class PraxisDuDossier extends StatelessWidget {
  /// Cree la ligne. [soucieux] : un blocage a signaler.
  const PraxisDuDossier({
    required this.phrase,
    super.key,
    this.soucieux = false,
  });

  /// Ce qu'il dit : un fait, en une phrase.
  final String phrase;

  /// Vrai quand l'information est un blocage.
  final bool soucieux;

  /// La cle de la ligne.
  static const Key cle = ValueKey<String>('dossier-praxis');

  /// La largeur de Praxis ici (120 ailleurs).
  static const double taille = AppSpacing.section;

  /// L'information la plus urgente de [d], ou `null` quand il n'y a rien a
  /// dire. Dans l'ordre : une piece refusee, puis ce qui reste a terminer.
  static String? urgence(EtatDossier d, LectureDossier lu) {
    if (lu.fermee || lu.retiree) return null;
    final p = t.recrutement.accueil.praxis;
    if (pieceRefusee(d)) return p.pieceRefusee;
    final int reste = lu.lignes
        .where((LigneDossier l) => l.etat == EtatLigne.aFaire)
        .length;
    return reste > 0 ? p.reste(n: reste) : null;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Row(
      key: cle,
      children: <Widget>[
        ExcludeSemantics(
          child: PraxisVivant(
            taille: taille,
            // Pose a sa place : a cette taille, une chute passerait sur la
            // ligne d'etapes.
            tombe: false,
            humeur: soucieux ? HumeurPraxis.soucieux : HumeurPraxis.calme,
          ),
        ),
        Ecart.hMd,
        Expanded(
          child: Text(
            phrase,
            style: palette.inkStrong.applyTo(
              Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
      ],
    );
  }
}

/// « Rien a faire pour l'instant » : la carte calme quand la main est a
/// l'academie. [phrase] remplace la phrase par defaut (l'age a declarer).
class CarteRienAFaire extends StatelessWidget {
  /// Cree la carte.
  const CarteRienAFaire({super.key, this.phrase});

  /// La phrase, ou `null` pour « Nous vous ecrirons ici ».
  final String? phrase;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair fond = palette.washAccent;
    final a = t.recrutement.accueil.aFaire;
    return Material(
      color: fond.background,
      shape: AppRadius.coinContinu(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ExcludeSemantics(
              child: IconTheme(
                data: IconThemeData(
                  size: AppSpacing.xxl,
                  color: fond.onBackground,
                ),
                child: Icon(AppIcons.attente.repos),
              ),
            ),
            Ecart.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    phrase == null ? a.rienTitre : a.titre,
                    style: fond.applyTo(
                      textes.titleMedium ?? const TextStyle(),
                    ),
                  ),
                  Ecart.vXs,
                  Text(
                    phrase ?? a.rien,
                    style: fond.applyTo(textes.bodyMedium ?? const TextStyle()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une ligne du dossier : son nom, son etat, et au toucher ce qu'elle est
/// (directeur, PLAN §15.2 : « une ligne du dossier se deplie au toucher :
/// description, exemple si possible »).
class LigneDepliable extends StatefulWidget {
  /// Cree la ligne.
  const LigneDepliable({required this.ligne, super.key});

  /// La ligne.
  final LigneDossier ligne;

  @override
  State<LigneDepliable> createState() => _EtatLigneDepliable();
}

class _EtatLigneDepliable extends State<LigneDepliable> {
  bool _ouverte = false;

  @override
  Widget build(BuildContext context) {
    final LigneDossier l = widget.ligne;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final a = t.recrutement.accueil.lignes;
    final bool fait = l.etat == EtatLigne.fait;
    // Un texte tres agrandi (ou 320 de large) : l'etat passe sous le nom, qui
    // garde toute la largeur ; aucun mot ne se coupe.
    final bool agrandi = MediaQuery.textScalerOf(context).scale(14) / 14 > 1.3;
    final Widget nom = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          l.libelle,
          style: palette.inkStrong.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        if (l.legende != null) ...<Widget>[
          Ecart.vXs,
          Text(
            l.legende!,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );
    // Comme la maquette : fait en vert, a faire en ambre. Jamais la couleur
    // seule : le mot dit l'etat.
    final Widget etat = StatusPill(
      libelle: l.valeur,
      ton: fait ? TonEtat.succes : TonEtat.avertissement,
    );
    final Widget tete = agrandi
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[nom, Ecart.vSm, etat],
          )
        : Row(
            children: <Widget>[
              Expanded(child: nom),
              Ecart.hSm,
              etat,
            ],
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ToucherVivant(
          enfoncement: 0.985,
          onPress: () => setState(() => _ouverte = !_ouverte),
          libelleSemantique:
              '${l.libelle}, ${l.valeur}. '
              '${_ouverte ? a.masquer(element: l.libelle) : a.afficher(element: l.libelle)}',
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppTouchTarget.standard,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: tete,
            ),
          ),
        ),
        Depliant(
          child: _ouverte
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    l.detail,
                    key: OngletDossier.cleDetail(l.code),
                    style: palette.inkMuted.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// A9 : l'annonce nouvelle de l'academie, en UNE ligne qui se ferme. Fermee
/// (ou glissee), elle est comptee « vue » et ne vit plus que dans l'onglet
/// Academie, ou toutes les annonces sont rangees.
class AnnonceEnLigne extends ConsumerStatefulWidget {
  /// Cree la ligne. [onVoir] ouvre l'onglet Academie.
  const AnnonceEnLigne({required this.onVoir, super.key});

  /// Ouvre l'onglet Academie.
  final VoidCallback onVoir;

  /// La cle de la ligne.
  static const Key cle = ValueKey<String>('annonce-en-ligne');

  /// La cle de sa croix.
  static const Key cleFermer = ValueKey<String>('annonce-en-ligne-fermer');

  @override
  ConsumerState<AnnonceEnLigne> createState() => _EtatAnnonceEnLigne();
}

class _EtatAnnonceEnLigne extends ConsumerState<AnnonceEnLigne> {
  /// Les annonces rangees depuis cet ecran.
  final Set<String> _rangees = <String>{};

  void _ranger(AnnonceRecue annonce) {
    setState(() => _rangees.add(annonce.id));
    // Un echec n'empeche rien : l'annonce reste lisible dans Academie, et
    // sera recomptee a la prochaine ouverture.
    unawaited(
      ref
          .read(portAnnoncesDirectionProvider)
          .marquerVue(annonce.id)
          .then((_) => ref.invalidate(mesAnnoncesProvider))
          .catchError((Object _) {}),
    );
    ref
        .read(avisEphemereProvider.notifier)
        .dire(t.recrutement.accueil.annonce.rangee);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<AnnonceRecue>> lues = ref.watch(mesAnnoncesProvider);
    if (!lues.hasValue) return const SizedBox.shrink();
    AnnonceRecue? nouvelle;
    for (final AnnonceRecue a in lues.requireValue) {
      if (!a.vue && !_rangees.contains(a.id)) {
        nouvelle = a;
        break;
      }
    }
    final AnnonceRecue? annonce = nouvelle;
    if (annonce == null) return const SizedBox.shrink();
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair fond = palette.washAccent;
    final TextTheme textes = Theme.of(context).textTheme;
    final Widget ligne = Material(
      color: fond.background,
      shape: AppRadius.coinContinu(AppRadius.md),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.lg),
        child: Row(
          children: <Widget>[
            Expanded(
              child: ToucherVivant(
                onPress: widget.onVoir,
                libelleSemantique:
                    '${t.com.annonces.fil.nouvelle}. ${annonce.titre}',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppTouchTarget.standard,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      t.recrutement.accueil.annonce.ligne(
                        titre: isolerSens(annonce.titre),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: palette.inkAccent.applyTo(
                        textes.labelLarge ?? const TextStyle(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Une croix simple (maquette), sur une cible de 48.
            ToucherVivant(
              key: AnnonceEnLigne.cleFermer,
              onPress: () => _ranger(annonce),
              libelleSemantique: t.recrutement.accueil.annonce.ranger(
                titre: annonce.titre,
              ),
              child: SizedBox.square(
                dimension: AppTouchTarget.standard,
                child: Center(
                  child: IconTheme(
                    data: palette.inkAccent.asIconTheme(size: AppSpacing.xl),
                    child: Icon(AppIcons.fermer.repos),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Padding(
      key: AnnonceEnLigne.cle,
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: _effetsReduits(context)
          ? ligne
          // Glissee sur le cote, elle se range (maquette validee).
          : Dismissible(
              key: ValueKey<String>('annonce-en-ligne-${annonce.id}'),
              movementDuration: AppMouvement.deplacementSortie,
              resizeDuration: null,
              onDismissed: (DismissDirection _) => _ranger(annonce),
              child: ligne,
            ),
    );
  }
}
