// Le dossier en trois etages (BE-DOSSIER, directeur, 16/11/2026 : « la
// lourdeur, la longueur », « pourquoi ne pas mettre chaque bouton d'action a
// cote de sa rubrique ? »).
//
// 1. En haut, fixe : la photo, l'etat, la phrase de situation (qui doit agir,
//    sur quoi, ce qui bloque). Le nom et la reference sont ceux de la page.
// 2. Au milieu : le resume, cinq lignes au plus, tirees des reponses.
// 3. En dessous : les rubriques, repliees, chacune avec sa pastille et ses
//    gestes a cote d'elle. S'ouvre d'elle-meme la rubrique qui bloque.
// Et la barre de decision, fixe en bas : les gestes du serveur, tous visibles.
//
// Rien de nouveau cote serveur : tout est lu du dossier et des gestes que
// `gestes_proposes.dart` ouvre deja. Aucun controle n'est recalcule ici.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/gestes_candidature.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidature_detail.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/modeles_import_candidatures.dart';
import '../../core/candidature/photo_dossier_candidat.dart';
import '../../core/candidature/piece_candidature.dart';
import '../../core/candidature/port_candidatures_direction.dart';
import '../../core/candidature/port_import_candidatures.dart';
import '../../core/candidature/port_invitations_personnelles.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../admin_candidatures/libelles_candidatures.dart';
import '../admin_dossiers/visionneuse_piece.dart' show imagePieceProvider;
import '../com_messages/entree_messages_contexte.dart';
import '../com_messages/port_messages_metier.dart' show TypeObjetLie;
import 'bloc_autres_competences.dart';
import 'bloc_entretien.dart';
import 'blocs_candidature.dart';
import 'feuille_lien_personnel.dart';
import 'libelles_candidature.dart';
import 'piece_sur_place.dart';
import 'plan_dossier.dart';
import 'portrait_dossier_fige.dart';
import 'reponses_candidature.dart';
import 'synthese_dossier.dart';

// ---------------------------------------------------------------------------
// Etage 1
// ---------------------------------------------------------------------------

/// La photo plein ecran, au toucher : sur telephone, une surface qui prend tout
/// l'ecran ; sur ordinateur, une boite bornee. Se ferme par le disque, par
/// `Echap` ou par le retour du systeme.
Future<void> ouvrirPhotoEnGrand(
  BuildContext context,
  WidgetRef ref, {
  required String url,
  required String nom,
}) {
  final ImageProvider<Object> image = ref.read(imagePieceProvider)(
    Uri.parse(url),
  );
  return AppBottomSheet.ouvrirLecture<void>(
    context,
    titre: nom,
    libelleFermer: t.commun.fermer,
    constructeur: (BuildContext _) => SizedBox.expand(
      child: Image(
        key: EtageUnDossier.clePhotoEnGrand,
        image: image,
        fit: BoxFit.contain,
        errorBuilder: (BuildContext c, Object e, StackTrace? s) =>
            Center(child: Text(t.admin.candidatures.detail.photo.echec)),
      ),
    ),
  );
}

/// L'etage 1 : la photo, l'etat en un mot, la phrase de situation.
class EtageUnDossier extends ConsumerWidget {
  /// Cree l'etage.
  const EtageUnDossier({required this.plan, super.key});

  /// Le plan du dossier.
  final PlanDossier plan;

  /// La cle de l'etage.
  static const Key cle = ValueKey<String>('dossier-etage-1');

  /// La cle de la photo qu'on touche.
  static const Key clePhoto = ValueKey<String>('dossier-photo-toucher');

  /// La cle de l'image en grand.
  static const Key clePhotoEnGrand = ValueKey<String>('dossier-photo-grand');

  /// La cle de la phrase « Il reste : ... ».
  static const Key cleReste = ValueKey<String>('dossier-situation-reste');

  /// La cle de la ligne de reperes (salle, genre, pays).
  static const Key cleReperes = ValueKey<String>('dossier-reperes');

  /// La salle, le genre (SALLE2-GENRE, directeur, 14/11/2026 : en tete de la
  /// fiche) et le pays de residence, sur une ligne discrete.
  static String? _reperes(DetailCandidature detail) {
    final LigneCandidature l = detail.ligne;
    final List<String> morceaux = <String>[
      ?libelleSalle(l.etape),
      ?libelleGenre(l.genre),
      ?libellePays(l.paysResidence),
    ];
    return morceaux.isEmpty
        ? null
        : morceaux.join(t.admin.candidatures.historique.separateur);
  }

  /// La cle de la phrase « qui doit agir ».
  static const Key cleQui = ValueKey<String>('dossier-situation-qui');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DetailCandidature detail = plan.detail;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final EtatAffiche? etat = etatDuDossier(detail);
    final String? reste = plan.phraseReste();
    final String nom = nomAffiche(detail.ligne);
    final AsyncValue<({String? url, DateTime? figeeLe})> photo = ref.watch(
      photoDossierProvider(detail.ligne.id),
    );
    final String? url = photo.value?.url;
    final bool lisible = url != null && !BlocPhotoDossier.formatIllisible(url);
    final Widget visage = lisible
        ? Pressable(
            key: clePhoto,
            libelleSemantique: t.recrutement.dossier3.photoAgrandir(
              deNom: deDevant(detail.ligne.nomComplet),
            ),
            onPress: () =>
                unawaited(ouvrirPhotoEnGrand(context, ref, url: url, nom: nom)),
            child: PortraitDossierFige(
              nomComplet: detail.ligne.nomComplet,
              urlPhotoFigee: url,
              diametre: AppAvatar.moyen,
            ),
          )
        : AvatarTile(
            prenom: detail.ligne.nomComplet,
            diametre: AppAvatar.moyen,
          );
    return Row(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        visage,
        Ecart.hMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (etat != null) ...<Widget>[
                StatusPill(libelle: etat.libelle, ton: etat.ton),
                Ecart.vXs,
              ],
              TexteSansCoupure(
                plan.quiAgit(),
                key: cleQui,
                style: textes.titleSmall,
              ),
              if (_reperes(detail) case final String reperes)
                TexteSansCoupure(
                  reperes,
                  key: cleReperes,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              if (reste != null)
                TexteSansCoupure(
                  reste,
                  key: cleReste,
                  // Gris fonce, pas rouge : ce n'est pas une erreur, c'est la
                  // suite (coordinateur, 16/11/2026).
                  style: palette.inkStrong.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Etage 2
// ---------------------------------------------------------------------------

/// L'etage 2 : la synthese, un tableau a deux colonnes (libelle court a
/// gauche, valeur courte a droite), une ligne par critere. Une valeur trop
/// longue passe a la ligne entre les mots, jamais tronquee. En arabe, le
/// tableau se retourne (les colonnes suivent le sens de lecture).
class ResumeDossier extends StatelessWidget {
  /// Cree la synthese.
  const ResumeDossier({required this.lignes, super.key, this.importe = false});

  /// Les lignes de la synthese.
  final List<LigneSynthese> lignes;

  /// Vrai quand les reponses viennent de l'ancien formulaire : la marque
  /// « Venu de l'ancien formulaire » le dit.
  final bool importe;

  /// La cle de l'etage.
  static const Key cle = ValueKey<String>('dossier-etage-2');

  /// La cle du tableau.
  static const Key cleTableau = ValueKey<String>('dossier-synthese-tableau');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle base =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    if (lignes.isEmpty) {
      return AppCard(
        key: cle,
        child: TexteSansCoupure(
          t.admin.candidatures.detail.aucuneReponse,
          style: palette.inkMuted.applyTo(base),
        ),
      );
    }
    return AppCard(
      key: cle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints contraintes) {
              // Texte tres agrandi ou colonne tres etroite : le libelle passe
              // au-dessus de sa valeur, pour qu'aucun mot ne se coupe. Sinon,
              // deux colonnes.
              final bool empile =
                  MediaQuery.textScalerOf(context).scale(16) / 16 > 1.3 ||
                  contraintes.maxWidth < 240;
              final TextStyle styleCle = palette.inkMuted.applyTo(base);
              final TextStyle styleValeur = palette.inkStrong.applyTo(base);
              if (empile) {
                return Column(
                  key: cleTableau,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (int i = 0; i < lignes.length; i++) ...<Widget>[
                      if (i > 0) Ecart.vSm,
                      TexteSansCoupure(lignes[i].cle, style: styleCle),
                      TexteSansCoupure(lignes[i].valeur, style: styleValeur),
                    ],
                  ],
                );
              }
              return Table(
                key: cleTableau,
                // Le libelle prend sa largeur, au plus un peu moins de la
                // moitie : la valeur garde la place de se dire.
                columnWidths: const <int, TableColumnWidth>{
                  0: MaxColumnWidth(
                    IntrinsicColumnWidth(),
                    FractionColumnWidth(0.42),
                  ),
                  1: FlexColumnWidth(),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.top,
                children: <TableRow>[
                  for (final LigneSynthese l in lignes)
                    TableRow(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            end: AppSpacing.lg,
                            top: AppSpacing.xs,
                            bottom: AppSpacing.xs,
                          ),
                          child: TexteSansCoupure(l.cle, style: styleCle),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: TexteSansCoupure(l.valeur, style: styleValeur),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
          if (importe) ...<Widget>[
            Ecart.vSm,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusPill(
                libelle: t.admin.candidatures.detail.preRempli,
                ton: TonEtat.neutre,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Etage 3
// ---------------------------------------------------------------------------

/// La place que la page garde sous les rubriques pendant qu'une rubrique
/// s'ouvre ou se replie (voir `RubriqueDossier`). Hors du dossier (un test qui
/// monte une rubrique seule), il n'y en a pas : la rubrique s'anime sans.
class ReserveDefilement extends InheritedWidget {
  /// Cree la reserve.
  const ReserveDefilement({
    required this.reserve,
    required super.child,
    super.key,
  });

  /// La hauteur gardee, en points.
  final ValueNotifier<double> reserve;

  /// La reserve de la page, ou `null`.
  static ValueNotifier<double>? de(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ReserveDefilement>()?.reserve;

  @override
  bool updateShouldNotify(ReserveDefilement ancien) =>
      ancien.reserve != reserve;
}

/// Un geste a cote de sa rubrique : un lien, jamais un gros bouton.
class GesteRubrique {
  /// Cree le geste.
  const GesteRubrique({required this.libelle, required this.onPress, this.cle});

  /// Le mot du lien.
  final String libelle;

  /// Ce que fait le lien.
  final VoidCallback onPress;

  /// La cle du lien.
  final Key? cle;
}

/// Une rubrique du dossier : un titre, une pastille, ses gestes a cote, et un
/// contenu qui ne se construit qu'ouvert.
class RubriqueDossier extends StatefulWidget {
  /// Cree la rubrique.
  const RubriqueDossier({
    required this.code,
    required this.titre,
    required this.contenu,
    super.key,
    this.pastille,
    this.gestes = const <GesteRubrique>[],
    this.ouverteAuDepart = false,
  });

  /// La rubrique.
  final RubriqueDossierCode code;

  /// Le titre.
  final String titre;

  /// La pastille (bon, a voir, manque), ou `null`.
  final PastilleRubrique? pastille;

  /// Les gestes que le serveur propose pour cette rubrique, visibles replie.
  final List<GesteRubrique> gestes;

  /// Vrai : la rubrique s'ouvre d'elle-meme (c'est elle qui bloque).
  final bool ouverteAuDepart;

  /// Le contenu, construit seulement quand la rubrique est ouverte.
  final WidgetBuilder contenu;

  /// La cle d'une rubrique.
  static Key cleDe(RubriqueDossierCode code) =>
      ValueKey<String>('rubrique-${code.name}');

  /// La cle de l'entete (la zone qu'on touche) d'une rubrique.
  static Key cleEntete(RubriqueDossierCode code) =>
      ValueKey<String>('rubrique-entete-${code.name}');

  /// La cle du contenu d'une rubrique, presente seulement quand elle est
  /// ouverte.
  static Key cleContenu(RubriqueDossierCode code) =>
      ValueKey<String>('rubrique-contenu-${code.name}');

  /// La cle de la pastille d'une rubrique.
  static Key clePastille(RubriqueDossierCode code) =>
      ValueKey<String>('rubrique-pastille-${code.name}');

  @override
  State<RubriqueDossier> createState() => _EtatRubriqueDossier();
}

class _EtatRubriqueDossier extends State<RubriqueDossier>
    with SingleTickerProviderStateMixin {
  late bool _ouverte = widget.ouverteAuDepart;

  /// La hauteur du contenu : 0 replie, 1 deplie. Elle s'anime sur une duree
  /// courte du theme (`AppMouvement.apparition`), nulle sous « reduire les
  /// animations ».
  late final AnimationController _hauteur = AnimationController(
    vsync: this,
    duration: AppMouvement.apparition,
    value: _ouverte ? 1 : 0,
  );

  late final CurvedAnimation _courbe = CurvedAnimation(
    parent: _hauteur,
    curve: AppMouvement.entree,
    reverseCurve: AppMouvement.sortie,
  );

  /// Le bloc de contenu : sa hauteur du moment se mesure sur lui.
  final GlobalKey _cleBloc = GlobalKey(debugLabel: 'rubrique-dossier-bloc');

  // Ce qui est note quand on touche le titre, pour garder la page en place :
  // la hauteur du bloc, sa part de hauteur, et la reserve de la page.
  double _hauteurDepart = 0;
  double _partDepart = 0;
  double _reserveDepart = 0;
  ValueNotifier<double>? _reserve;

  @override
  void initState() {
    super.initState();
    _hauteur
      ..addStatusListener((AnimationStatus _) {
        if (mounted) setState(() {});
      })
      ..addListener(_garderLaPlace);
  }

  @override
  void dispose() {
    _courbe.dispose();
    _hauteur.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RubriqueDossier ancienne) {
    super.didUpdateWidget(ancienne);
    // Un dossier relu qui se met a bloquer ici ouvre la rubrique ; jamais
    // l'inverse : ce que la personne a ouvert reste ouvert.
    if (widget.ouverteAuDepart && !ancienne.ouverteAuDepart) {
      _ouverte = true;
      _hauteur.value = 1;
    }
  }

  double _hauteurDuBloc() {
    final RenderObject? o = _cleBloc.currentContext?.findRenderObject();
    return o is RenderBox && o.attached && o.hasSize ? o.size.height : 0;
  }

  /// Ouvre ou ferme : le titre touche reste a la meme place a l'ecran, a
  /// chaque image, sans saut. Quand une rubrique se replie, la page garde sous
  /// les rubriques la place qui s'en va, pour ne pas raccourcir sous le
  /// doigt ; quand elle s'ouvre, cette place est rendue au fur et a mesure.
  void _basculer() {
    _reserve = ReserveDefilement.de(context);
    _hauteurDepart = _hauteurDuBloc();
    _partDepart = _courbe.value;
    _reserveDepart = _reserve?.value ?? 0;
    _hauteur.duration = AppMouvement.duree(context, AppMouvement.apparition);
    setState(() => _ouverte = !_ouverte);
    if (_ouverte) {
      unawaited(_hauteur.forward());
    } else {
      unawaited(_hauteur.reverse());
    }
    _garderLaPlace();
  }

  /// Appelee a chaque image de l'animation, avant la mise en page : la reserve
  /// de la page change dans la meme image que la hauteur du bloc.
  void _garderLaPlace() {
    final ValueNotifier<double>? reserve = _reserve;
    if (reserve == null) return;
    if (_ouverte) {
      // Ouverture : la place gardee est rendue de ce que le bloc a gagne
      // (mesure a l'image precedente : jamais moins que ce qu'il faut).
      final double gagne = _hauteurDuBloc() - _hauteurDepart;
      reserve.value = (_reserveDepart - (gagne > 0 ? gagne : 0)).clamp(
        0,
        double.infinity,
      );
    } else if (_partDepart > 0.001) {
      // Fermeture : ce que le bloc perd s'ajoute a la reserve, dans la meme
      // image (calcule sur la courbe, pas mesure).
      final double pleine = _hauteurDepart / _partDepart;
      final double perdu = pleine * (_partDepart - _courbe.value);
      reserve.value = _reserveDepart + (perdu > 0 ? perdu : 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final PastilleRubrique? pastille = widget.pastille;
    final r = t.recrutement.dossier3.pastille;
    final Widget entete = Semantics(
      expanded: _ouverte,
      child: Pressable(
        key: RubriqueDossier.cleEntete(widget.code),
        libelleSemantique: widget.titre,
        onPress: _basculer,
        child: Row(
          children: <Widget>[
            Expanded(
              // Le titre, puis la pastille : a cote quand la place le permet,
              // dessous sinon (texte agrandi), sans jamais couper un mot.
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  Semantics(
                    header: true,
                    child: TexteSansCoupure(
                      widget.titre,
                      style: textes.titleMedium,
                    ),
                  ),
                  if (pastille != null)
                    StatusPill(
                      key: RubriqueDossier.clePastille(widget.code),
                      libelle: switch (pastille) {
                        PastilleRubrique.bon => r.bon,
                        PastilleRubrique.aVoir => r.aVoir,
                        PastilleRubrique.manque => r.manque,
                      },
                      ton: switch (pastille) {
                        PastilleRubrique.bon => TonEtat.succes,
                        PastilleRubrique.aVoir => TonEtat.avertissement,
                        PastilleRubrique.manque => TonEtat.alerte,
                      },
                    ),
                ],
              ),
            ),
            Ecart.hSm,
            ExcludeSemantics(
              child: RotatedBox(
                quarterTurns: _ouverte ? 2 : 0,
                child: Icon(AppIcons.menuDeroulant.repos),
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      key: RubriqueDossier.cleDe(widget.code),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        entete,
        if (widget.gestes.isNotEmpty)
          // Choix de formulaire, pas un filtre : des liens de gestes.
          Wrap(
            spacing: AppSpacing.lg,
            children: <Widget>[
              for (final GesteRubrique g in widget.gestes)
                LienFleche(
                  key: g.cle,
                  libelle: g.libelle,
                  alignerEnDebut: true,
                  onPress: g.onPress,
                ),
            ],
          ),
        // Le contenu reste construit tant que la hauteur s'anime (la
        // fermeture se voit), puis disparait.
        if (_ouverte || _hauteur.status != AnimationStatus.dismissed)
          AnimatedBuilder(
            animation: _courbe,
            // Le contenu garde son etat ; seule la hauteur change. Au repos
            // (deplie), rien ne decoupe le contenu.
            builder: (BuildContext _, Widget? contenu) => ClipRect(
              clipBehavior: _courbe.value >= 1 ? Clip.none : Clip.hardEdge,
              child: Align(
                key: _cleBloc,
                alignment: AlignmentDirectional.topStart,
                heightFactor: _courbe.value,
                child: contenu,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Ecart.vSm,
                KeyedSubtree(
                  key: RubriqueDossier.cleContenu(widget.code),
                  child: widget.contenu(context),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// La photo, sous sa rubrique : la date a laquelle elle a ete figee, ou la
/// raison pour laquelle elle ne s'affiche pas. L'image se touche en haut.
class ContenuPhotoRubrique extends ConsumerWidget {
  /// Cree le contenu.
  const ContenuPhotoRubrique({required this.detail, super.key});

  /// Le dossier lu.
  final DetailCandidature detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = t.admin.candidatures.detail.photo;
    final String id = detail.ligne.id;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle muet = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
    );
    final AsyncValue<({String? url, DateTime? figeeLe})> lue = ref.watch(
      photoDossierProvider(id),
    );
    if (lue.hasValue) {
      final ({String? url, DateTime? figeeLe}) v = lue.requireValue;
      if (v.url == null) return TexteSansCoupure(r.aucune, style: muet);
      if (BlocPhotoDossier.formatIllisible(v.url!)) {
        return TexteSansCoupure(
          r.illisible,
          key: BlocPhotoDossier.cleIllisible,
          style: palette.inkAlert.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        );
      }
      final DateTime? le = v.figeeLe;
      return le == null
          ? const SizedBox.shrink()
          : TexteSansCoupure(
              r.figeeLe(date: dateCourteCandidature(le)),
              style: muet,
            );
    }
    if (lue.hasError) {
      if (lue.error is CapaciteIndisponible) return const SizedBox.shrink();
      return EtatSysteme(
        nature: NatureEtat.echecServeur,
        titre: r.echec,
        onAction: () => ref.invalidate(photoDossierProvider(id)),
      );
    }
    return const Skeleton.texte(lignes: 1);
  }
}

/// Les rubriques de gestes que cette page ajoute au menu de la barre : le lien
/// d'inscription d'une ligne de suivi sans adresse (INVITATIONS-PERSONNELLES).
List<EntreeAction> actionsSupplementaires(
  BuildContext context,
  WidgetRef ref,
  DetailCandidature detail,
) {
  final CapacitesImportCandidatures? capsImport = ref
      .watch(capacitesImportCandidaturesProvider)
      .value;
  final LigneCandidature ligne = detail.ligne;
  final bool lienCopie =
      ref.watch(portInvitationsPersonnellesProvider) != null &&
      capsImport != null &&
      (capsImport.peutImporter || capsImport.doubleVerificationRequise) &&
      ligneSansAdresse(
        recue: ligne.etape == EtapeCandidature.recue,
        enCours: ligne.issue == IssueCandidature.enCours,
        courrielAObtenir: ligne.courrielAObtenir,
      );
  return <EntreeAction>[
    if (lienCopie)
      EntreeAction(
        libelle: t.candidatsFlux.invitationsPersonnelles.lienCopie.action,
        onChoix: () => unawaited(
          ouvrirFeuilleLienPersonnel(context, candidatureId: ligne.id),
        ),
      ),
  ];
}

/// Le corps du dossier : le resume, puis les rubriques. Sur ordinateur, les
/// etages 1 et 2 a gauche et les rubriques a droite, dans la meme page.
class CorpsDossier extends ConsumerStatefulWidget {
  /// Cree le corps.
  const CorpsDossier({
    required this.plan,
    required this.deuxColonnes,
    required this.onGeste,
    required this.onDemanderElement,
    required this.onOuvrirDossier,
    required this.onEntretien,
    required this.onOuvrirConversation,
    this.rangMessages = 0,
    this.retour,
    this.retourEntretien,
    this.autresActions = const <EntreeAction>[],
    super.key,
  });

  /// Des entrees de plus dans le menu « ⋯ » de la barre de decision.
  final List<EntreeAction> autresActions;

  /// Le plan du dossier.
  final PlanDossier plan;

  /// Vrai sur ordinateur : deux colonnes.
  final bool deuxColonnes;

  /// Ouvre la feuille d'un geste.
  final ValueChanged<GesteCandidature> onGeste;

  /// Ouvre le complement, l'element deja coche.
  final ValueChanged<String> onDemanderElement;

  /// Mene a « Dossiers a valider ».
  final VoidCallback onOuvrirDossier;

  /// Un geste d'entretien est fait, avec son retour local.
  final ValueChanged<String> onEntretien;

  /// Ouvre une conversation dans le dossier.
  final ValueChanged<ConversationEnPlace> onOuvrirConversation;

  /// Change quand l'entree des messages doit relire ses badges.
  final int rangMessages;

  /// Le retour local du dernier geste.
  final String? retour;

  /// Le retour local du dernier geste d'entretien.
  final String? retourEntretien;

  /// La cle du corps.
  static const Key cle = ValueKey<String>('dossier-corps');

  /// La cle de la place gardee sous les rubriques.
  static const Key cleReserve = ValueKey<String>('dossier-reserve');

  @override
  ConsumerState<CorpsDossier> createState() => _EtatCorpsDossier();
}

class _EtatCorpsDossier extends ConsumerState<CorpsDossier> {
  /// La liste des rubriques garde son etat (rubriques ouvertes) quand la page
  /// passe d'une colonne a deux, ou l'inverse : une cle globale la suit.
  final GlobalKey _cleListe = GlobalKey(debugLabel: 'dossier-liste-rubriques');

  /// La place gardee sous les rubriques pendant qu'une rubrique se replie :
  /// la page ne raccourcit pas sous le doigt, le titre touche garde sa place.
  final ValueNotifier<double> _reserve = ValueNotifier<double>(0);

  @override
  void dispose() {
    _reserve.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ReserveDefilement(reserve: _reserve, child: _corps(context));

  Widget _corps(BuildContext context) {
    final PlanDossier plan = widget.plan;
    final bool deuxColonnes = widget.deuxColonnes;
    final ValueChanged<GesteCandidature> onGeste = widget.onGeste;
    final ValueChanged<String> onDemanderElement = widget.onDemanderElement;
    final VoidCallback onOuvrirDossier = widget.onOuvrirDossier;
    final ValueChanged<String> onEntretien = widget.onEntretien;
    final ValueChanged<ConversationEnPlace> onOuvrirConversation =
        widget.onOuvrirConversation;
    final int rangMessages = widget.rangMessages;
    final String? retour = widget.retour;
    final String? retourEntretien = widget.retourEntretien;
    final List<EntreeAction> autresActions = widget.autresActions;
    final DetailCandidature detail = plan.detail;
    final CapacitesCandidatures capacites = plan.capacites;
    final bool horsLigne = plan.horsLigne;
    final String? pays = declarationVersement(detail).pays;
    // Le nom des operateurs vient du referentiel des moyens confirmes ; sans
    // lui (liste non servie, panne), les moyens se disent par leur nombre.
    final Map<String, String> noms = pays == null || !capacites.peutDecider
        ? const <String, String>{}
        : <String, String>{
            for (final OperateurPaiement o
                in ref
                        .watch(moyensConfirmesDirectionProvider(pays))
                        .value
                        ?.operateurs ??
                    const <OperateurPaiement>[])
              o.code: o.nom,
          };

    // Un element se redemande en un geste quand le complement est permis
    // maintenant et que la salle le propose (COMPLEMENT-ET-FORMATS).
    final bool complementPermis = plan.propose(
      GesteCandidature.demanderComplement,
    );
    final List<String> elementsSalle =
        detail.ligne.etape == EtapeCandidature.verifications
        ? capacites.listes.complementSalleVerification
        : capacites.listes.complementSalleExamen;
    bool redemandable(String code) =>
        !horsLigne && complementPermis && elementsSalle.contains(code);
    GesteRubrique? demander(String code, String libelle) => redemandable(code)
        ? GesteRubrique(
            cle: ValueKey<String>('rubrique-demander-$code'),
            libelle: libelle,
            onPress: () => onDemanderElement(code),
          )
        : null;
    GesteRubrique? geste(GesteCandidature g, {String? libelle}) =>
        plan.offert(g)
        ? GesteRubrique(
            cle: ValueKey<String>('rubrique-geste-${g.name}'),
            libelle: libelle ?? libelleGeste(g),
            onPress: () => onGeste(g),
          )
        : null;

    final r = t.admin.candidatures.detail;
    final d3 = t.recrutement.dossier3;
    final RubriqueDossierCode? bloque = plan.rubriqueQuiBloque;
    final List<CarteReponses> cartes = detail.dernieresReponses == null
        ? const <CarteReponses>[]
        : cartesDeReponses(detail.dernieresReponses!, nomsOperateurs: noms);
    CarteReponses? carte(String code) {
      for (final CarteReponses c in cartes) {
        if (c.code == code) return c;
      }
      return null;
    }

    RubriqueDossier rubrique(
      RubriqueDossierCode code,
      String titre,
      WidgetBuilder contenu, {
      List<GesteRubrique?> gestes = const <GesteRubrique?>[],
      PastilleRubrique? pastille,
    }) => RubriqueDossier(
      code: code,
      titre: titre,
      pastille: pastille ?? plan.pastille(code),
      gestes: <GesteRubrique>[for (final GesteRubrique? g in gestes) ?g],
      ouverteAuDepart: bloque == code,
      contenu: contenu,
    );

    RubriqueDossier? reponses(RubriqueDossierCode code, String carteCode) {
      final CarteReponses? c = carte(carteCode);
      if (c == null) return null;
      return rubrique(
        code,
        c.titre,
        (BuildContext _) => LignesReponses(lignes: c.lignes),
        pastille: PastilleRubrique.bon,
        gestes: <GesteRubrique?>[
          demander(carteCode, t.admin.candidatures.decision.preciser),
        ],
      );
    }

    final CarteReponses? versement = carte('versement');
    final List<ControleCandidature> accords = <ControleCandidature>[
      for (final ControleCandidature c
          in detail.controles ?? <ControleCandidature>[])
        if (c.nom == 'accords_signes' || c.nom == 'cadre_religieux') c,
    ];
    final List<RubriqueDossier?> rubriques = <RubriqueDossier?>[
      rubrique(
        RubriqueDossierCode.photo,
        d3.rubrique.photo,
        (BuildContext _) => ContenuPhotoRubrique(detail: detail),
        gestes: <GesteRubrique?>[demander('photo', r.photo.demanderNouvelle)],
      ),
      rubrique(
        RubriqueDossierCode.piece,
        d3.rubrique.piece,
        (BuildContext c) => _ContenuPiece(
          detail: detail,
          onOuvrirDossier: onOuvrirDossier,
          onDemanderNouvellePiece: redemandable('piece_identite')
              ? () => onDemanderElement('piece_identite')
              : null,
          onDecision: onEntretien,
        ),
        gestes: <GesteRubrique?>[
          demander('piece_identite', r.demanderNouvellePiece),
        ],
      ),
      rubrique(
        RubriqueDossierCode.versement,
        d3.rubrique.versement,
        (BuildContext _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LigneCleValeur(
              cle: t.admin.candidatures.colonnes.versement,
              valeur: libelleVersement(detail.ligne.paiement),
            ),
            if (versement != null) LignesReponses(lignes: versement.lignes),
          ],
        ),
        gestes: <GesteRubrique?>[
          geste(GesteCandidature.confirmerMoyenPaiement),
          geste(GesteCandidature.infirmerMoyenPaiement),
          demander('versement', t.admin.candidatures.decision.preciser),
        ],
      ),
      if (accords.isNotEmpty)
        rubrique(
          RubriqueDossierCode.accords,
          d3.rubrique.accords,
          (BuildContext _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final ControleCandidature c in accords)
                LigneControleDossier(controle: c),
            ],
          ),
          gestes: <GesteRubrique?>[
            if (redemandable('contrat'))
              GesteRubrique(
                cle: const ValueKey<String>('rubrique-demander-accord'),
                libelle: d3.demanderAccord,
                onPress: () => onGeste(GesteCandidature.demanderComplement),
              ),
          ],
        ),
      reponses(RubriqueDossierCode.langues, 'langues'),
      reponses(RubriqueDossierCode.recitation, 'recitation'),
      reponses(RubriqueDossierCode.disponibilites, 'disponibilites'),
      reponses(RubriqueDossierCode.publics, 'publics'),
      rubrique(
        RubriqueDossierCode.talents,
        r.talents.titre,
        (BuildContext _) =>
            BlocAutresCompetences(detail: detail, avecTitre: false),
      ),
      rubrique(
        RubriqueDossierCode.entretien,
        r.entretien,
        (BuildContext _) => SectionEntretien(
          detail: detail,
          capacites: capacites,
          horsLigne: horsLigne,
          onFait: onEntretien,
          retour: retourEntretien,
        ),
      ),
      rubrique(
        RubriqueDossierCode.messages,
        d3.rubrique.messages,
        // Le bandeau « Messages pas en direct » est celui de cette entree :
        // il ne se construit qu'avec la rubrique ouverte, donc seulement dans
        // la conversation.
        (BuildContext _) => EntreeMessagesContexte(
          key: ValueKey<String>('entree-messages-$rangMessages'),
          type: TypeObjetLie.candidature,
          objetId: detail.ligne.id,
          onOuvrirEnPlace: onOuvrirConversation,
        ),
      ),
      rubrique(
        RubriqueDossierCode.responsable,
        r.responsable,
        (BuildContext _) => TexteSansCoupure(
          // Le nom quand le serveur le rend ; « designe » seulement sans nom.
          detail.responsableNom ??
              (detail.ligne.responsableId == null
                  ? r.aucunResponsable
                  : r.responsableDesigne),
          style: AppPalette.of(context).inkMuted.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
        gestes: <GesteRubrique?>[geste(GesteCandidature.definirResponsable)],
      ),
      rubrique(
        RubriqueDossierCode.contact,
        r.contact.titre,
        (BuildContext _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TexteSansCoupure(
              r.contact.masque,
              style: AppPalette.of(context).inkMuted.applyTo(
                Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
              ),
            ),
            if (capacites.peutVoirContact && !horsLigne)
              TexteSansCoupure(
                r.contact.journal,
                style: AppPalette.of(context).inkMuted.applyTo(
                  Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                ),
              ),
          ],
        ),
        gestes: <GesteRubrique?>[
          if (capacites.peutVoirContact && !horsLigne)
            GesteRubrique(
              cle: BlocContact.cleVoir,
              libelle: r.contact.voir,
              onPress: () => unawaited(
                ouvrirFeuilleContact(context, candidatureId: detail.ligne.id),
              ),
            ),
        ],
      ),
      rubrique(
        RubriqueDossierCode.historique,
        t.historique.titre,
        (BuildContext _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LignesDatesDossier(detail: detail),
            Ecart.vMd,
            BlocHistorique(candidatureId: detail.ligne.id, integre: true),
          ],
        ),
      ),
    ];
    final Widget resume = ResumeDossier(
      lignes: syntheseDuDossier(detail, nomsOperateurs: noms),
      importe: detail.dernieresReponses?.importe ?? false,
    );
    // Rien de fixe (coordinateur, 16/11 : SANS-BARRE-FIXE et DEFILEMENT
    // l'emportent) : la barre de decision suit le resume, dans la page.
    final Widget barre = BarreDecisionDossier(
      plan: plan,
      onGeste: onGeste,
      autresActions: autresActions,
    );
    final Widget retourLocal = retour == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: LocalFeedback(message: retour),
          );
    final Widget liste = KeyedSubtree(
      key: _cleListe,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CarteGroupee(
            key: CorpsDossier.cle,
            sections: <Widget>[
              for (final RubriqueDossier? ru in rubriques) ?ru,
            ],
          ),
          ValueListenableBuilder<double>(
            valueListenable: _reserve,
            builder: (BuildContext _, double h, Widget? _) =>
                SizedBox(key: CorpsDossier.cleReserve, height: h),
          ),
        ],
      ),
    );
    if (!deuxColonnes) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          EtageUnDossier(plan: plan),
          Ecart.vLg,
          retourLocal,
          resume,
          Ecart.vLg,
          barre,
          Ecart.vLg,
          liste,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              EtageUnDossier(plan: plan),
              Ecart.vLg,
              retourLocal,
              resume,
              Ecart.vLg,
              barre,
            ],
          ),
        ),
        Ecart.hXxl,
        Expanded(child: liste),
      ],
    );
  }
}

/// La piece sous sa rubrique : ouverte et decidee sur place quand le serveur la
/// sert ; sinon l'etat lu dans le dossier, et le lien vers « Dossiers a
/// valider » (seul cas ou on quitte le dossier).
class _ContenuPiece extends ConsumerWidget {
  const _ContenuPiece({
    required this.detail,
    required this.onOuvrirDossier,
    required this.onDemanderNouvellePiece,
    required this.onDecision,
  });

  final DetailCandidature detail;
  final VoidCallback onOuvrirDossier;
  final VoidCallback? onDemanderNouvellePiece;
  final ValueChanged<String> onDecision;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = t.admin.candidatures.detail;
    if (ref.watch(lirePieceCandidatureProvider) != null) {
      return PieceSurPlace(
        candidatureId: detail.ligne.id,
        onOuvrirDossier: onOuvrirDossier,
        onDemanderNouvellePiece: onDemanderNouvellePiece,
        onDecision: onDecision,
      );
    }
    final String? etat = switch (detail.piece) {
      EtatPiece.aDeposer => r.etatsPiece.aDeposer,
      EtatPiece.deposee => r.etatsPiece.deposee,
      EtatPiece.aCorriger => r.etatsPiece.aCorriger,
      EtatPiece.validee => r.etatsPiece.validee,
      null => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (etat != null)
          TexteSansCoupure(
            etat,
            style: AppPalette.of(context).inkMuted.applyTo(
              Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            ),
          ),
        LienFleche(
          key: BlocPieceEntretien.cleDossier,
          libelle: r.ouvrirDossier,
          alignerEnDebut: true,
          onPress: onOuvrirDossier,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// La barre de decision
// ---------------------------------------------------------------------------

/// La barre de decision, dans la page, juste sous le resume : les gestes que le
/// serveur propose, tous visibles. Un geste qui ne peut pas aboutir n'est pas
/// rendu (K-56) : une phrase courte dit ce qui manque. Rien n'est fixe
/// (SANS-BARRE-FIXE, DEFILEMENT). Hors ligne, aucun geste : une note le dit.
class BarreDecisionDossier extends StatelessWidget {
  /// Cree la barre.
  const BarreDecisionDossier({
    required this.plan,
    required this.onGeste,
    this.autresActions = const <EntreeAction>[],
    super.key,
  });

  /// Le plan du dossier.
  final PlanDossier plan;

  /// Ouvre la feuille d'un geste.
  final ValueChanged<GesteCandidature> onGeste;

  /// Des entrees de plus dans le menu « ⋯ ».
  final List<EntreeAction> autresActions;

  /// La cle de la barre.
  static const Key cle = ValueKey<String>('dossier-barre-decision');

  /// La cle du menu « ⋯ ».
  static const Key cleMenu = ValueKey<String>('dossier-barre-menu');

  /// La cle de la phrase qui dit pourquoi un geste n'est pas rendu.
  static Key cleRaison(GesteCandidature g) =>
      ValueKey<String>('dossier-barre-raison-${g.name}');

  /// La cle du bouton d'une decision.
  static Key cleBouton(GesteCandidature g) =>
      ValueKey<String>('candidature-decision-${g.name}');

  Widget _bouton(FenteDecision fente, {required bool plein}) =>
      ActionPrincipale(
        key: cleBouton(fente.geste),
        libelle: fente.libelle,
        niveau: plein ? NiveauAction.principale : NiveauAction.secondaire,
        pleineLargeur: false,
        compacte: true,
        onPress: () => onGeste(fente.geste),
      );

  @override
  Widget build(BuildContext context) {
    final TextStyle muet = AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle());
    if (plan.horsLigne) {
      return TexteSansCoupure(
        t.admin.candidatures.erreurs.horsLigne,
        key: cle,
        style: muet,
      );
    }
    final List<FenteDecision> fentes = plan.fentesDecision();
    final List<FenteDecision> rendues = <FenteDecision>[
      for (final FenteDecision f in fentes)
        if (f.actif) f,
    ];
    final GesteCandidature? visible = plan.principalHorsFentes;
    // Le seul bouton plein : la prochaine action hors fentes, sinon Accepter
    // (la premiere fente). Jamais un refus.
    final bool accepterRendu = fentes.first.actif;
    final List<GesteCandidature> menu = plan.gestesDuMenu();
    // Les gestes non rendus qui ont la meme raison la partagent : une phrase.
    final Map<String, List<FenteDecision>> raisons =
        <String, List<FenteDecision>>{};
    for (final FenteDecision f in fentes) {
      if (!f.actif && f.raison != null) {
        (raisons[f.raison!] ??= <FenteDecision>[]).add(f);
      }
    }
    final bool vide =
        visible == null &&
        rendues.isEmpty &&
        menu.isEmpty &&
        autresActions.isEmpty;
    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (!vide)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              if (visible != null)
                _bouton(
                  FenteDecision(
                    geste: visible,
                    libelle: libelleGeste(visible),
                    actif: true,
                  ),
                  plein: true,
                ),
              for (final FenteDecision f in rendues)
                _bouton(
                  f,
                  plein: visible == null && accepterRendu && f == fentes.first,
                ),
              if (menu.isNotEmpty || autresActions.isNotEmpty)
                MenuActions(
                  key: cleMenu,
                  points: true,
                  libelle: t.admin.candidatures.detail.autresGestes,
                  actions: <EntreeAction>[
                    for (final GesteCandidature g in menu)
                      EntreeAction(
                        libelle: libelleGeste(g),
                        destructif: g.destructif,
                        onChoix: () => onGeste(g),
                      ),
                    ...autresActions,
                  ],
                ),
            ],
          ),
        for (final MapEntry<String, List<FenteDecision>> e
            in raisons.entries) ...<Widget>[
          if (!vide || e.key != raisons.keys.first) Ecart.vSm,
          TexteSansCoupure(
            t.recrutement.dossier3.legendeRaison(
              geste: e.value
                  .map((FenteDecision f) => f.libelle)
                  .join(t.admin.candidatures.detail.separateurControles),
              raison: e.key,
            ),
            key: cleRaison(e.value.first.geste),
            style: muet,
          ),
        ],
      ],
    );
  }
}
