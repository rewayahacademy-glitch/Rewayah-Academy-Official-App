/// CHIFFRES-ACADEMIE (directeur, 20/11/2026) : « Les chiffres de l'academie ».
///
/// Une vitrine, pas une page de travail : une grille de cartes, chacune un
/// chiffre fort, une phrase courte et vraie, et UN dessin simple.
///
/// LEGERETE (« mon PC est un Core i3 ») : aucun calcul ni animation en
/// continu. Une lecture par minute tant que l'onglet est visible
/// ([LectureRythmee]) ; un chiffre qui change tourne une fois
/// ([NombreRouleaux]) puis tout se tait ; les dessins sont des peintres a
/// plat qui ne se repeignent que si leur donnee change
/// (`dessins_chiffres.dart`). Ni flou, ni degrade, ni image.
///
/// La page defile seule (`DECISION-DEFILEMENT-2026-11-01.md`) : la grille n'a
/// aucun defilement propre. Elle lit une capacite (le port des chiffres),
/// jamais un role ; le serveur refuse toute autre personne que la direction.
///
/// Etats : chargement (`Skeleton`), contenu, vide (`EmptyState`), erreur
/// (`EtatSysteme`, « Reessayer »), hors ligne (le bandeau de `PageShell` ;
/// `EtatSansDonnees` seulement si rien n'a pu etre lu), et port absent.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/port_chiffres_academie.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/vivant/nombre_rouleaux.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import 'dessins_chiffres.dart';
import 'lecture_chiffres.dart';

/// La section « L'academie aujourd'hui » (enseignants, eleves, familles,
/// classes, seances). UNE constante pour la retirer de la page, sur decision
/// du directeur : le serveur continue de compter, rien n'est supprime.
const bool sectionAcademieAffichee = true;

/// L'opacite des colonnes des jours passes (aujourd'hui seul est plein).
const double opaciteJoursPasses = 0.32;

/// Le nombre de riwayat des dix lectures : le plein de la barre des riwayat.
const int riwayatDesDixLectures = 20;

/// La tendance en pourcentage entre [courant] et [avant], ou nul quand elle
/// n'a pas de sens : rien avant (pas de base de comparaison), ou aucun ecart.
int? tendancePourcent(int courant, int avant) {
  if (avant <= 0) return null;
  final int p = ((courant - avant) * 100 / avant).round();
  return p == 0 ? null : p;
}

/// Vrai quand « +[n] » dit quelque chose : il y a du nouveau, et ce n'est pas
/// le total lui-meme (une pastille qui repete le chiffre ne s'affiche pas).
bool plusUtile(int n, int total) => n > 0 && n < total;

/// La part de [n] sur [total], de 0 a 1 ; 0 quand il n'y a pas de total.
double partDe(int n, int total) =>
    total <= 0 ? 0 : (n / total).clamp(0, 1).toDouble();

/// L'ecran « Les chiffres de l'academie ».
class ChiffresAcademiePage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const ChiffresAcademiePage({super.key});

  @override
  ConsumerState<ChiffresAcademiePage> createState() => _EtatPage();
}

class _EtatPage extends ConsumerState<ChiffresAcademiePage>
    with WidgetsBindingObserver {
  late final LectureRythmee<ChiffresAcademie> _lecture;

  @override
  void initState() {
    super.initState();
    _lecture = LectureRythmee<ChiffresAcademie>(lire: _lire)
      ..addListener(_redessiner)
      ..demarrer(visible: _estVisible(WidgetsBinding.instance.lifecycleState));
    WidgetsBinding.instance.addObserver(this);
  }

  /// L'onglet cache (ou l'application en arriere-plan) ne lit rien. Une
  /// fenetre visible mais sans le focus (`inactive`) continue.
  static bool _estVisible(AppLifecycleState? etat) =>
      etat == null ||
      etat == AppLifecycleState.resumed ||
      etat == AppLifecycleState.inactive;

  Future<ChiffresAcademie> _lire() {
    final PortChiffresAcademie? port = ref.read(portChiffresAcademieProvider);
    if (port == null) {
      return Future<ChiffresAcademie>.error(
        const CapaciteIndisponible(dependanceChiffresAcademie),
      );
    }
    return port.lire();
  }

  void _redessiner() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _lecture.visible = _estVisible(state);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lecture
      ..removeListener(_redessiner)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = t.admin.chiffres;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return PageShell(
      titre: l.titre,
      sousTitre: l.sousTitre,
      child: BlocAsynchrone<ChiffresAcademie>(
        key: const ValueKey<String>('chiffres-bloc'),
        valeur: _lecture.etat,
        squelette: const Skeleton.liste(lignes: 4),
        onReessayer: _lecture.relire,
        estVide: (ChiffresAcademie c) => c.estVide,
        vide: EmptyState(
          key: const ValueKey<String>('chiffres-vide'),
          message: l.vide,
          invitation: l.videDetail,
          icone: AppIcons.tableauDeBord,
          registre: RegistreVide.subi,
        ),
        erreurVersEtat: (Object erreur, VoidCallback? reessayer) {
          if (erreur is CapaciteIndisponible) {
            return EtatSysteme(
              key: const ValueKey<String>('chiffres-indisponible'),
              nature: NatureEtat.indisponible,
              titre: l.indisponibleTitre,
              phrase: l.indisponiblePhrase,
              dependance: erreur.dependance,
            );
          }
          return horsLigne
              ? EtatSansDonnees(
                  key: const ValueKey<String>('chiffres-sans-donnees'),
                  quoi: l.sansDonnees,
                  onAction: reessayer,
                )
              : EtatSysteme(
                  key: const ValueKey<String>('chiffres-erreur'),
                  nature: NatureEtat.echecServeur,
                  phrase: l.erreur,
                  onAction: reessayer,
                );
        },
        construire: (ChiffresAcademie c) => _Contenu(chiffres: c),
      ),
    );
  }
}

/// Une carte de la grille : sa largeur en colonnes, et son contenu.
typedef _Case = ({int colonnes, Widget carte});

class _Contenu extends StatelessWidget {
  const _Contenu({required this.chiffres});

  final ChiffresAcademie chiffres;

  @override
  Widget build(BuildContext context) {
    final l = t.admin.chiffres;
    final ChiffresAcademie c = chiffres;
    final AppPalette p = AppPalette.of(context);
    final CouleursDessin couleurs = CouleursDessin(
      plein: p.surfacePrimary.background,
      doux: p.surfacePrimary.background.withValues(alpha: opaciteJoursPasses),
      piste: p.surfaceCanvas.background,
      second: p.surfaceSuccess.background,
      fond: p.surfaceRaised.background,
      trait: p.surfaceInverse.background,
    );
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    String pourcent(double part) => l.pourcent(n: (part * 100).round());
    String tendance(int v) => v > 0
        ? l.hausseSeptJours(part: l.pourcent(n: v))
        : l.baisseSeptJours(part: l.pourcent(n: -v));

    final DateTime heure = c.genereLe.toLocal();
    final String aJour = l.aJour(
      heure:
          '${heure.hour.toString().padLeft(2, '0')}:'
          '${heure.minute.toString().padLeft(2, '0')}',
    );

    final int? tendanceCandidats = tendancePourcent(
      c.candidatsSeptJours,
      c.candidatsSeptJoursAvant,
    );
    final int? tendanceSeances = tendancePourcent(
      c.seancesSeptJours,
      c.seancesSeptJoursAvant,
    );
    final double partCoran = partDe(c.coranEntier, c.repondants);
    final double partJuz = partDe(c.juzMin, c.repondants * 30);
    final double partIjaza = partDe(c.ijaza, c.repondants);
    final double partClasse = partDe(c.elevesEnClasse, c.eleves);

    final List<_Case> candidats = <_Case>[
      (
        colonnes: 2,
        carte: _Carte(
          cle: 'candidats',
          valeur: c.candidatsRecus,
          phrase: l.candidats,
          pastilles: <Widget>[
            if (plusUtile(c.candidatsAujourdhui, c.candidatsRecus))
              StatusPill(
                libelle: l.plusAujourdhui(n: c.candidatsAujourdhui),
                ton: TonEtat.succes,
              ),
            if (plusUtile(c.candidatsSeptJours, c.candidatsRecus))
              StatusPill(
                libelle: l.plusSeptJours(n: c.candidatsSeptJours),
                ton: TonEtat.succes,
              ),
            if (tendanceCandidats != null)
              StatusPill(
                libelle: tendance(tendanceCandidats),
                ton: tendanceCandidats > 0 ? TonEtat.succes : TonEtat.neutre,
              ),
          ],
          dessin: (double largeur) => Dessin(
            taille: Size(largeur, AppSpacing.titreEcran),
            peintre: PeintreColonnes(
              valeurs: c.candidatsParJour,
              couleurs: couleurs,
              versLaGauche: rtl,
            ),
          ),
          legende: l.septJours,
        ),
      ),
      (
        colonnes: 1,
        carte: _Carte(
          cle: 'pays',
          valeur: c.pays,
          phrase: l.pays,
          dessin: c.pays > pointsMax || c.pays == 0
              ? null
              : (double largeur) => Dessin(
                  taille: taillePoints(c.pays, largeur),
                  peintre: PeintrePoints(
                    n: c.pays,
                    couleurs: couleurs,
                    versLaGauche: rtl,
                  ),
                ),
        ),
      ),
      (
        colonnes: 1,
        carte: _Carte(
          cle: 'coran',
          valeur: c.coranEntier,
          phrase: l.coran,
          dessin: (double largeur) => _Anneau(
            part: partCoran,
            couleurs: couleurs,
            libelle: l.partReponses(part: pourcent(partCoran)),
            texte: pourcent(partCoran),
          ),
          legende: l.partReponses(part: pourcent(partCoran)),
        ),
      ),
      (
        colonnes: 1,
        carte: _Carte(
          cle: 'juz',
          prefixe: l.auMoins,
          valeur: c.juzMin,
          phrase: l.juz,
          dessin: (double largeur) {
            final double w = largeur.clamp(0, AppSpacing.respiration * 2);
            return Dessin(
              taille: Size(w, w / 2 + 1),
              libelle: l.partCoran(part: pourcent(partJuz)),
              peintre: PeintreArcGradue(
                part: partJuz,
                couleurs: couleurs,
                versLaGauche: rtl,
              ),
            );
          },
          legende: l.partCoran(part: pourcent(partJuz)),
        ),
      ),
      (
        colonnes: 1,
        carte: _Carte(
          cle: 'riwayat',
          valeur: c.riwayat,
          phrase: l.riwayat,
          dessin: (double largeur) => Dessin(
            taille: Size(largeur, AppSpacing.xl),
            peintre: PeintreSegments(
              n: c.riwayat.clamp(0, riwayatDesDixLectures),
              total: riwayatDesDixLectures,
              couleurs: couleurs,
              versLaGauche: rtl,
            ),
          ),
          note: l.declarations,
        ),
      ),
      (
        colonnes: 1,
        carte: _Carte(
          cle: 'ijaza',
          valeur: c.ijaza,
          phrase: l.ijaza,
          dessin: (double largeur) => _Anneau(
            part: partIjaza,
            couleurs: couleurs,
            libelle: l.partReponses(part: pourcent(partIjaza)),
            texte: pourcent(partIjaza),
          ),
          legende: l.partReponses(part: pourcent(partIjaza)),
          note: l.declarations,
        ),
      ),
      (
        colonnes: 1,
        carte: _Carte(
          cle: 'langues',
          valeur: c.langues,
          phrase: l.langues,
          dessin: c.langues > pointsMax || c.langues == 0
              ? null
              : (double largeur) => Dessin(
                  taille: taillePoints(c.langues, largeur),
                  peintre: PeintrePoints(
                    n: c.langues,
                    couleurs: couleurs,
                    versLaGauche: rtl,
                  ),
                ),
        ),
      ),
      (
        colonnes: 2,
        carte: _Carte(
          cle: 'genre',
          valeur: c.hommes,
          valeurSeconde: c.femmes,
          phrase: l.genre,
          dessin: c.hommes + c.femmes == 0
              ? null
              : (double largeur) => Dessin(
                  taille: Size(largeur, AppSpacing.xl),
                  libelle: '${l.hommes(n: c.hommes)} ${l.femmes(n: c.femmes)}',
                  peintre: PeintrePartage(
                    part: partDe(c.hommes, c.hommes + c.femmes),
                    couleurs: couleurs,
                    versLaGauche: rtl,
                  ),
                ),
        ),
      ),
    ];

    final List<_Case> academie = <_Case>[
      (
        colonnes: 1,
        carte: _Carte(
          cle: 'enseignants',
          valeur: c.enseignants,
          phrase: l.enseignants,
        ),
      ),
      (
        colonnes: 1,
        carte: _Carte(
          cle: 'eleves',
          valeur: c.eleves,
          phrase: l.eleves,
          precision: l.elevesEnClasse(n: c.elevesEnClasse),
          dessin: c.eleves == 0
              ? null
              : (double largeur) => _Anneau(
                  part: partClasse,
                  couleurs: couleurs,
                  libelle: l.partEnClasse(part: pourcent(partClasse)),
                  texte: pourcent(partClasse),
                ),
          legende: c.eleves == 0
              ? null
              : l.partEnClasse(part: pourcent(partClasse)),
        ),
      ),
      (
        colonnes: 1,
        carte: _Carte(
          cle: 'familles',
          valeur: c.familles,
          phrase: l.familles,
          dessin: c.familles > pointsMax || c.familles == 0
              ? null
              : (double largeur) => Dessin(
                  taille: taillePoints(c.familles, largeur),
                  peintre: PeintrePoints(
                    n: c.familles,
                    couleurs: couleurs,
                    versLaGauche: rtl,
                  ),
                ),
        ),
      ),
      (
        colonnes: 1,
        carte: _Carte(
          cle: 'classes',
          valeur: c.classes,
          phrase: l.classes,
          precision: l.languesCours(n: c.languesCours),
        ),
      ),
      (
        colonnes: 2,
        carte: _Carte(
          cle: 'seances',
          valeur: c.seancesTenues,
          phrase: l.seances,
          precision: l.dureeCours(
            heures: c.seancesMinutes ~/ 60,
            minutes: (c.seancesMinutes % 60).toString().padLeft(2, '0'),
          ),
          pastilles: <Widget>[
            if (plusUtile(c.seancesSeptJours, c.seancesTenues))
              StatusPill(
                libelle: l.plusSeptJours(n: c.seancesSeptJours),
                ton: TonEtat.succes,
              ),
            if (tendanceSeances != null)
              StatusPill(
                libelle: tendance(tendanceSeances),
                ton: tendanceSeances > 0 ? TonEtat.succes : TonEtat.neutre,
              ),
          ],
        ),
      ),
    ];

    final TextStyle discret = p.inkMuted.applyTo(
      Theme.of(context).textTheme.bodySmall!,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          aJour,
          key: const ValueKey<String>('chiffres-a-jour'),
          style: discret,
        ),
        Ecart.vXl,
        SectionHeader(titre: l.sectionCandidats),
        Ecart.vMd,
        _Grille(cases: candidats),
        if (sectionAcademieAffichee) ...<Widget>[
          Ecart.vXxxl,
          SectionHeader(titre: l.sectionAcademie),
          Ecart.vMd,
          _Grille(cases: academie),
        ],
      ],
    );
  }
}

/// La grille : 2 colonnes au telephone (1 en texte tres agrandi), 3 sur
/// tablette, 4 sur ordinateur. Des rangees de cartes de meme hauteur, sans
/// aucun defilement propre : c'est la page qui defile.
class _Grille extends StatelessWidget {
  const _Grille({required this.cases});

  final List<_Case> cases;

  static int _colonnes(double largeur, TextScaler texte) =>
      switch (AppGabarit.classe(largeur)) {
        ClasseLargeur.compacte =>
          texte.scale(16) / 16 >= AppGabarit.seuilTexteColonne ? 1 : 2,
        ClasseLargeur.moyenne => 3,
        ClasseLargeur.etendue || ClasseLargeur.large => 4,
      };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints contraintes) {
      final int colonnes = _colonnes(
        contraintes.maxWidth,
        MediaQuery.textScalerOf(context),
      );
      final List<List<_Case>> rangees = <List<_Case>>[];
      int reste = 0;
      for (final _Case c in cases) {
        final int largeur = c.colonnes.clamp(1, colonnes);
        if (rangees.isEmpty || largeur > reste) {
          rangees.add(<_Case>[]);
          reste = colonnes;
        }
        rangees.last.add((colonnes: largeur, carte: c.carte));
        reste -= largeur;
      }
      // La largeur d'une colonne, puis celle du contenu d'une carte : les
      // dessins la recoivent ici (un `LayoutBuilder` ne peut pas vivre dans
      // une rangee a hauteur commune).
      final double colonne =
          (contraintes.maxWidth - (colonnes - 1) * AppSpacing.lg) / colonnes;
      double contenu(int largeur) =>
          colonne * largeur + (largeur - 1) * AppSpacing.lg - 2 * _Carte.marge;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.lg,
        children: <Widget>[
          for (final List<_Case> rangee in rangees)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.lg,
                children: <Widget>[
                  for (final _Case c in rangee)
                    Expanded(
                      flex: c.colonnes,
                      child: _LargeurContenu(
                        largeur: contenu(c.colonnes),
                        child: c.carte,
                      ),
                    ),
                  if (_vides(rangee, colonnes) > 0)
                    Spacer(flex: _vides(rangee, colonnes)),
                ],
              ),
            ),
        ],
      );
    },
  );

  static int _vides(List<_Case> rangee, int colonnes) =>
      colonnes - rangee.fold<int>(0, (int s, _Case c) => s + c.colonnes);
}

/// La largeur du contenu d'une carte, donnee par la grille.
class _LargeurContenu extends InheritedWidget {
  const _LargeurContenu({required this.largeur, required super.child});

  final double largeur;

  static double de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LargeurContenu>()!.largeur;

  @override
  bool updateShouldNotify(_LargeurContenu ancien) => ancien.largeur != largeur;
}

/// Une carte : le chiffre, ses pastilles, sa phrase, son dessin.
class _Carte extends StatelessWidget {
  const _Carte({
    required this.cle,
    required this.valeur,
    required this.phrase,
    this.valeurSeconde,
    this.prefixe,
    this.precision,
    this.pastilles = const <Widget>[],
    this.dessin,
    this.legende,
    this.note,
  });

  final String cle;
  final int valeur;
  final int? valeurSeconde;
  final String phrase;
  final String? prefixe;
  final String? precision;
  final List<Widget> pastilles;
  final Widget Function(double largeur)? dessin;
  final String? legende;
  final String? note;

  /// La marge interieure d'une carte.
  static const double marge = AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final TextTheme styles = Theme.of(context).textTheme;
    final TextStyle chiffre = p.inkStrong.applyTo(styles.displaySmall!);
    final TextStyle corps = p.inkMuted.applyTo(styles.bodyMedium!);
    final TextStyle discret = p.inkMuted.applyTo(styles.bodySmall!);
    final int? seconde = valeurSeconde;
    final Widget Function(double largeur)? d = dessin;
    return AppCard(
      key: ValueKey<String>('chiffres-carte-$cle'),
      marge: marge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (prefixe != null) Text(prefixe!, style: discret),
          // Le lecteur d'ecran lit le chiffre puis sa phrase, d'un trait.
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: seconde == null
                      ? NombreRouleaux(valeur, style: chiffre)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            NombreRouleaux(valeur, style: chiffre),
                            Text(
                              ' · ',
                              style: AppTypography.tabulaire(chiffre),
                            ),
                            NombreRouleaux(seconde, style: chiffre),
                          ],
                        ),
                ),
                Ecart.vXs,
                Text(phrase, style: corps),
              ],
            ),
          ),
          if (precision != null) ...<Widget>[
            Ecart.vXs,
            Text(precision!, style: discret),
          ],
          if (pastilles.isNotEmpty) ...<Widget>[
            Ecart.vSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: pastilles,
            ),
          ],
          if (d != null) ...<Widget>[
            Ecart.vMd,
            const Spacer(),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: d(_LargeurContenu.de(context)),
            ),
            if (legende != null) ...<Widget>[
              Ecart.vXs,
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(legende!, style: discret, textAlign: TextAlign.end),
              ),
            ],
          ],
          if (note != null) ...<Widget>[Ecart.vSm, Text(note!, style: discret)],
        ],
      ),
    );
  }
}

/// Un anneau et son pourcentage au centre.
class _Anneau extends StatelessWidget {
  const _Anneau({
    required this.part,
    required this.couleurs,
    required this.libelle,
    required this.texte,
  });

  final double part;
  final CouleursDessin couleurs;
  final String libelle;
  final String texte;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppPalette.of(context).inkStrong
        .applyTo(Theme.of(context).textTheme.labelLarge!);
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Dessin(
          taille: const Size.square(AppSpacing.respiration),
          libelle: libelle,
          peintre: PeintreAnneau(part: part, couleurs: couleurs),
        ),
        ExcludeSemantics(
          child: Text(
            texte,
            style: AppTypography.tabulaire(style),
            textScaler: TextScaler.noScaling,
          ),
        ),
      ],
    );
  }
}
