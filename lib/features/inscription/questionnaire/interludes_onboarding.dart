// ONBOARDING-PRAXIS (directeur, 22/11/2026) : les quatre interludes de la
// maquette (« Voici votre famille », « Votre point de depart », « Votre
// chemin », « Voici ce que nous avons compris ») et les libelles partages du
// questionnaire.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/accessibilite/mode_accessibilite.dart';
import '../../../core/candidature/fuseau_appareil.dart';
import '../../../core/domain/enums.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/i18n/villes_fuseau.dart';
import '../../../core/offres/offre_horaire.dart';
import '../../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../../core/theme/app_mouvement.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar_nom.dart';
import '../../../core/widgets/filter_pill.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/pile_cartes.dart';
import '../../../core/widgets/status_pill.dart';
import 'coquille_onboarding.dart';
import 'onboarding_donnees.dart';
import 'questionnaire_inscription.dart';

/// Construit un ecran dans l'habillage de l'onboarding.
typedef ConstruireEcranOnboarding = CoquilleOnboarding Function({
  required String phrase,
  required List<Widget> corps,
  ExpressionPraxis expression,
  bool grand,
  String? titre,
  String? sousTitre,
  Widget? action,
  List<Widget> liens,
  String? indice,
});

/// Le bouton plein de l'ecran (un seul).
ActionPrincipale boutonOnboarding(String libelle, VoidCallback onPress) =>
    ActionPrincipale(
      key: const Key('questionnaire-continuer'),
      libelle: libelle,
      onPress: onPress,
      affirmee: true,
    );

// ---------------------------------------------------------------------------
// Libelles
// ---------------------------------------------------------------------------

/// Le niveau dit a la bonne personne (« Je », « Il », « Elle »).
String libelleNiveauSujet(NiveauDeclare n, String sujet) {
  final n0 = t.onboarding.niveau;
  return switch ((sujet, n)) {
    ('moi', NiveauDeclare.debutLettres) => n0.moi.debut,
    ('moi', NiveauDeclare.lettresAvecAide) => n0.moi.aide,
    ('moi', NiveauDeclare.lectureLente) => n0.moi.lente,
    ('moi', NiveauDeclare.lectureCourante) => n0.moi.courante,
    ('moi', NiveauDeclare.memorisationPartielle) => n0.moi.memo,
    ('elle', NiveauDeclare.debutLettres) => n0.elle.debut,
    ('elle', NiveauDeclare.lettresAvecAide) => n0.elle.aide,
    ('elle', NiveauDeclare.lectureLente) => n0.elle.lente,
    ('elle', NiveauDeclare.lectureCourante) => n0.elle.courante,
    ('elle', NiveauDeclare.memorisationPartielle) => n0.elle.memo,
    (_, NiveauDeclare.debutLettres) => n0.il.debut,
    (_, NiveauDeclare.lettresAvecAide) => n0.il.aide,
    (_, NiveauDeclare.lectureLente) => n0.il.lente,
    (_, NiveauDeclare.lectureCourante) => n0.il.courante,
    (_, NiveauDeclare.memorisationPartielle) => n0.il.memo,
  };
}

/// La precision sous un niveau.
String descriptionNiveau(NiveauDeclare n) => switch (n) {
  NiveauDeclare.debutLettres => t.onboarding.niveau.desc.debut,
  NiveauDeclare.lettresAvecAide => t.onboarding.niveau.desc.aide,
  NiveauDeclare.lectureLente => t.onboarding.niveau.desc.lente,
  NiveauDeclare.lectureCourante => t.onboarding.niveau.desc.courante,
  NiveauDeclare.memorisationPartielle => t.onboarding.niveau.desc.memo,
};

/// La quantite memorisee, sur sa carte.
String libelleQuantite(QuantiteMemorisee m) => switch (m) {
  QuantiteMemorisee.quelquesSourates => t.onboarding.memorise.quelques,
  QuantiteMemorisee.unACinqJuz => t.onboarding.memorise.unACinq,
  QuantiteMemorisee.plusDeCinqJuz => t.onboarding.memorise.plusDeCinq,
  QuantiteMemorisee.coranEntier => t.onboarding.memorise.tout,
};

/// Le nom d'une sourate des bases.
String nomSourate(String code) => switch (code) {
  'fatiha' => t.onboarding.sourates.fatiha,
  'nas' => t.onboarding.sourates.nas,
  'falaq' => t.onboarding.sourates.falaq,
  'ikhlas' => t.onboarding.sourates.ikhlas,
  'masad' => t.onboarding.sourates.masad,
  'nasr' => t.onboarding.sourates.nasr,
  'kafirun' => t.onboarding.sourates.kafirun,
  'kawthar' => t.onboarding.sourates.kawthar,
  'maun' => t.onboarding.sourates.maun,
  'quraysh' => t.onboarding.sourates.quraysh,
  'fil' => t.onboarding.sourates.fil,
  'humaza' => t.onboarding.sourates.humaza,
  'asr' => t.onboarding.sourates.asr,
  'takathur' => t.onboarding.sourates.takathur,
  'qaria' => t.onboarding.sourates.qaria,
  'adiyat' => t.onboarding.sourates.adiyat,
  _ => t.onboarding.sourates.zalzala,
};

/// Le titre d'un groupe de langues.
String nomGroupeLangues(GroupeLangues g) => switch (g) {
  GroupeLangues.plusDemandees => t.onboarding.langue.groupes.plusDemandees,
  GroupeLangues.afrique => t.onboarding.langue.groupes.afrique,
  GroupeLangues.asie => t.onboarding.langue.groupes.asie,
  GroupeLangues.europe => t.onboarding.langue.groupes.europe,
};

/// Le nom d'une langue des explications.
String nomLangue(String code) {
  final l = t.onboarding.langues;
  return switch (code) {
    'francais' => l.francais,
    'english' => l.english,
    'ar' => l.ar,
    'ha' => l.ha,
    'poular' => l.poular,
    'yo' => l.yo,
    'man' => l.man,
    'snk' => l.snk,
    'wo' => l.wo,
    'bm' => l.bm,
    'sw' => l.sw,
    'so' => l.so,
    'am' => l.am,
    'om' => l.om,
    'ur' => l.ur,
    'hi' => l.hi,
    'bn' => l.bn,
    'ps' => l.ps,
    'fa' => l.fa,
    'tr' => l.tr,
    'id' => l.id,
    'uz' => l.uz,
    'pt' => l.pt,
    'ru' => l.ru,
    'de' => l.de,
    _ => code,
  };
}

/// Le nom d'un apprenant dans un panneau : son prenom, ou « Pour vous ».
String _nomPanneau(ApprenantQuestionnaire a, String pourVous) =>
    a.titulaire ? pourVous : a.prenom;

// ---------------------------------------------------------------------------
// 1. Voici votre famille
// ---------------------------------------------------------------------------

/// L'interlude « Voici votre famille » : les prenoms en avatars, « Ajouter
/// un autre eleve », « Je suivrai aussi des cours » ; pour « Pour plusieurs
/// enfants », apres le premier, « Ajouter l'enfant suivant ».
CoquilleOnboarding interludeFamille(
  BuildContext context,
  WidgetRef ref,
  ConstruireEcranOnboarding ecran,
  void Function(EtapeQuestionnaire etape) aller,
  VoidCallback avancer,
) {
  final f = t.onboarding.famille;
  final QuestionnaireInscription q = ref.watch(
    questionnaireInscriptionProvider,
  );
  final QuestionnaireControleur c = ref.read(
    questionnaireInscriptionProvider.notifier,
  );
  final bool seul = q.apprenants.length == 1 && q.apprenants.first.titulaire;
  final bool encore = q.encoreUnEnfant;
  final String premier = q.apprenants.isEmpty ? '' : q.apprenants.first.prenom;
  void ajouter({bool titulaire = false}) {
    final int? rang = c.ajouter(titulaire: titulaire);
    if (rang != null) aller(EtapeQuestionnaire(SorteEtape.prenom, rang));
  }

  return ecran(
    grand: true,
    expression: ExpressionPraxis.joie,
    phrase: encore
        ? f.ditEncore(prenom: premier)
        : seul
        ? f.ditSeul(prenom: premier)
        : f.dit,
    titre: seul ? f.titreSeul : f.titre,
    corps: <Widget>[
      Wrap(
        key: const ValueKey<String>('onboarding-famille'),
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.lg,
        children: <Widget>[
          for (final ApprenantQuestionnaire a in q.apprenants)
            AvatarNom(
              prenom: a.prenom,
              disposition: DispositionAvatar.vertical,
              diametre: AppAvatar.grand,
            ),
        ],
      ),
    ],
    action: boutonOnboarding(
      encore ? f.suivant : t.commun.continuer,
      encore ? ajouter : avancer,
    ),
    liens: <Widget>[
      if (q.peutAjouter)
        LienFleche(
          key: const Key('questionnaire-famille-ajouter'),
          libelle: f.ajouter,
          fleche: false,
          onPress: ajouter,
        ),
      if (!q.titulaireApprend && q.peutAjouter)
        LienFleche(
          key: const Key('questionnaire-famille-aussi'),
          libelle: f.aussi,
          fleche: false,
          onPress: () => ajouter(titulaire: true),
        ),
    ],
  );
}

// ---------------------------------------------------------------------------
// 2. Votre point de depart
// ---------------------------------------------------------------------------

/// L'etape de depart probable (0 a 3) d'un niveau, et sa phrase.
(int, String, String) departProbable(NiveauDeclare? n) {
  final r = t.onboarding.depart.reco;
  return switch (n) {
    NiveauDeclare.lettresAvecAide => (0, r.aide, r.aideSuite),
    NiveauDeclare.lectureLente => (1, r.lente, r.lenteSuite),
    NiveauDeclare.lectureCourante => (2, r.courante, r.couranteSuite),
    NiveauDeclare.memorisationPartielle => (3, r.memo, r.memoSuite),
    _ => (0, r.debut, r.debutSuite),
  };
}

/// L'interlude « Votre point de depart » : par apprenant, les quatre etapes
/// des bases et l'examen de fin des bases, l'etape de depart probable
/// surlignee, puis la suite selon l'objectif.
CoquilleOnboarding interludeDepart(
  BuildContext context,
  QuestionnaireInscription q,
  ConstruireEcranOnboarding ecran,
  VoidCallback avancer,
) {
  final d = t.onboarding.depart;
  return ecran(
    grand: true,
    expression: ExpressionPraxis.joie,
    phrase: d.dit,
    titre: q.apprenants.length > 1 ? d.titrePlusieurs : d.titre,
    corps: <Widget>[
      PileCartes(
        children: <Widget>[
          for (final ApprenantQuestionnaire a in q.apprenants)
            _PanneauDepart(apprenant: a),
        ],
      ),
    ],
    action: boutonOnboarding(t.commun.continuer, avancer),
    indice: d.indice,
  );
}

class _PanneauDepart extends StatelessWidget {
  const _PanneauDepart({required this.apprenant});

  final ApprenantQuestionnaire apprenant;

  @override
  Widget build(BuildContext context) {
    final d = t.onboarding.depart;
    final TextTheme textes = Theme.of(context).textTheme;
    final (int etape, String titre, String suite) = departProbable(
      apprenant.niveau,
    );
    final String apres = switch (apprenant.objectif) {
      ObjectifOnboarding.memoriser => d.suiteMemoriser,
      ObjectifOnboarding.priere => d.suitePriere,
      _ => d.suite,
    };
    final List<(String, String)> etapes = <(String, String)>[
      (d.etapes.lettres, d.etapes.lettresDetail),
      (d.etapes.voyelles, d.etapes.voyellesDetail),
      (d.etapes.coran, d.etapes.coranDetail),
      (d.etapes.sourates, d.etapes.souratesDetail),
      (d.etapes.examen, apres),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                _nomPanneau(apprenant, d.pourVous),
                style: textes.titleMedium,
              ),
              StatusPill(libelle: d.probable, ton: TonEtat.accent),
            ],
          ),
          Ecart.vMd,
          for (final (int i, (String, String) e) in etapes.indexed)
            _PointChemin(
              titre: e.$1,
              detail: e.$2,
              actif: i == etape,
              dernier: i == etapes.length - 1,
            ),
          Ecart.vSm,
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: titre,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                TextSpan(text: '. $suite'),
              ],
            ),
            style: textes.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Un point du chemin des bases : son disque (plein quand c'est le depart
/// probable), son nom et sa precision, et le trait vers le suivant.
class _PointChemin extends StatelessWidget {
  const _PointChemin({
    required this.titre,
    required this.detail,
    required this.actif,
    required this.dernier,
  });

  final String titre;
  final String detail;
  final bool actif;
  final bool dernier;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final BorderSide trait = palette.borderResting.asBorderSide(width: 2);
    return Semantics(
      selected: actif,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              width: AppSpacing.xl,
              child: Column(
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: actif
                          ? palette.surfacePrimary.background
                          : palette.surfaceCanvas.background,
                      border: Border.fromBorderSide(
                        actif
                            ? BorderSide(
                                color: palette.surfacePrimary.background,
                                width: 3,
                              )
                            : palette.borderResting.asBorderSide(width: 3),
                      ),
                    ),
                    child: const SizedBox.square(dimension: AppSpacing.lg),
                  ),
                  if (!dernier)
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: BorderDirectional(start: trait),
                        ),
                        child: const SizedBox(width: AppSpacing.xs),
                      ),
                    ),
                ],
              ),
            ),
            Ecart.hMd,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(titre, style: textes.titleSmall),
                    Text(
                      detail,
                      style: palette.inkMuted.applyTo(
                        textes.bodySmall ?? const TextStyle(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Votre chemin
// ---------------------------------------------------------------------------

/// L'interlude « Votre chemin » : pour un debutant complet, la courbe de la
/// duree prevue des bases et la date limite de sa tranche d'age (programme) ;
/// pour les autres, la duree sera precisee a la premiere seance ; puis la
/// rigueur (trois seances, meme enseignant, absence rattrapee seul avec les
/// outils de l'academie).
CoquilleOnboarding interludeChemin(
  BuildContext context,
  QuestionnaireInscription q,
  ConstruireEcranOnboarding ecran,
  VoidCallback avancer,
) {
  final ch = t.onboarding.chemin;
  final TextTheme textes = Theme.of(context).textTheme;
  return ecran(
    grand: true,
    expression: ExpressionPraxis.reflexion,
    phrase: ch.dit,
    titre: ch.titre,
    corps: <Widget>[
      PileCartes(
        children: <Widget>[
          for (final ApprenantQuestionnaire a in q.apprenants)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        _nomPanneau(a, ch.pourVous),
                        style: textes.titleMedium,
                      ),
                      if (a.debutant)
                        StatusPill(
                          libelle: LibellesGroupe.insecable(
                            ch.prevues(n: a.tranche.semainesPrevues),
                          ),
                          ton: TonEtat.accent,
                        ),
                    ],
                  ),
                  Ecart.vSm,
                  if (a.debutant) ...<Widget>[
                    CourbeChemin(tranche: a.tranche),
                    Ecart.vSm,
                    Text(ch.trois, style: textes.bodyMedium),
                  ] else
                    Text(ch.precise, style: textes.bodyMedium),
                ],
              ),
            ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: ch.rigueurTitre,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      TextSpan(text: ' ${ch.rigueur}'),
                    ],
                  ),
                  style: textes.bodyMedium,
                ),
                Ecart.vSm,
                Text(ch.horaires, style: textes.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    ],
    action: boutonOnboarding(t.commun.continuer, avancer),
  );
}

/// La courbe du chemin d'un debutant : du debut a la fin des bases (duree
/// prevue), puis un pointille jusqu'a la date limite. Elle se trace une fois
/// (rien ne bouge sous « Reduire les effets ») ; le lecteur d'ecran lit les
/// deux durees.
class CourbeChemin extends StatelessWidget {
  /// Cree la courbe.
  const CourbeChemin({required this.tranche, super.key});

  /// La tranche d'age (ses durees viennent du programme).
  final TrancheAge tranche;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final ch = t.onboarding.chemin;
    final bool reduit = EffetsReduits.de(context);
    return Semantics(
      label: LibellesGroupe.insecable(
        ch.courbeLue(
          prevu: tranche.semainesPrevues,
          limite: tranche.semainesLimite,
        ),
      ),
      excludeSemantics: true,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          // La courbe garde la taille de la maquette sur grand ecran.
          constraints: const BoxConstraints(maxWidth: AppPage.largeurVolet),
          child: AspectRatio(
            aspectRatio: 300 / 130,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: reduit ? 1 : 0, end: 1),
              duration: reduit
                  ? Duration.zero
                  : AppMouvement.entreeIllustration,
              curve: AppMouvement.entree,
              builder: (BuildContext context, double trace, Widget? _) =>
                  CustomPaint(
                    painter: _PeintreCourbe(
                      trace: trace,
                      prevu: tranche.semainesPrevues,
                      limite: tranche.semainesLimite,
                      ligne: palette.borderResting.asBorderSide(width: 2).color,
                      accent: palette.surfacePrimary.background,
                      texte: palette.inkStrong.applyTo(
                        textes.labelSmall ?? const TextStyle(),
                      ),
                      debut: ch.debut,
                      fin: LibellesGroupe.insecable(
                        ch.finBases(n: tranche.semainesPrevues),
                      ),
                      borne: LibellesGroupe.insecable(
                        ch.limite(n: tranche.semainesLimite),
                      ),
                      rtl: Directionality.of(context) == TextDirection.rtl,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeintreCourbe extends CustomPainter {
  _PeintreCourbe({
    required this.trace,
    required this.prevu,
    required this.limite,
    required this.ligne,
    required this.accent,
    required this.texte,
    required this.debut,
    required this.fin,
    required this.borne,
    required this.rtl,
  });

  final double trace;
  final int prevu;
  final int limite;
  final Color ligne;
  final Color accent;
  final TextStyle texte;
  final String debut;
  final String fin;
  final String borne;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size taille) {
    // Le repere de la maquette : 300 sur 130.
    final double k = taille.width / 300;
    double x(double semaines) {
      final double v = 20 + semaines / limite * 260;
      return (rtl ? 300 - v : v) * k;
    }

    double y(double v) => v * k;
    final Paint base = Paint()
      ..color = ligne
      ..strokeWidth = 2 * k;
    canvas.drawLine(
      Offset(x(0), y(105)),
      Offset(x(limite * 1.0), y(105)),
      base,
    );
    final Path courbe = Path()
      ..moveTo(x(0), y(105))
      ..cubicTo(
        x(prevu * .4),
        y(100),
        x(prevu * .7),
        y(62),
        x(prevu * 1.0),
        y(34),
      );
    final Paint trait = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4 * k;
    for (final ui in courbe.computeMetrics()) {
      canvas.drawPath(ui.extractPath(0, ui.length * trace), trait);
    }
    if (trace >= 1) {
      // Le pointille jusqu'a la date limite.
      final Paint pointille = Paint()
        ..color = accent
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3 * k;
      final double de = x(prevu * 1.0);
      final double a = x(limite * 1.0);
      final double pas = 9 * k * (a >= de ? 1 : -1);
      for (double v = de; (a - v) * pas.sign > 0; v += pas) {
        canvas.drawLine(
          Offset(v, y(34)),
          Offset(v + pas / 3, y(34)),
          pointille,
        );
      }
    }
    final Paint plein = Paint()..color = accent;
    canvas
      ..drawCircle(Offset(x(0), y(105)), 6 * k, plein)
      ..drawCircle(Offset(x(prevu * 1.0), y(34)), 6 * k, plein)
      ..drawCircle(
        Offset(x(limite * 1.0), y(34)),
        6 * k,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * k,
      );
    void ecrire(String s, Offset o, {bool fin = false}) {
      final TextPainter p = TextPainter(
        text: TextSpan(text: s, style: texte),
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      )..layout(maxWidth: taille.width);
      final bool versDebut = fin != rtl;
      p.paint(canvas, Offset(versDebut ? o.dx - p.width : o.dx, o.dy));
    }

    ecrire(debut, Offset(x(0) - (rtl ? 0 : 0), y(112)), fin: rtl);
    ecrire(
      fin,
      Offset(x(prevu * 1.0) + (rtl ? -10 * k : 10 * k), y(8)),
      fin: true,
    );
    ecrire(
      borne,
      Offset(rtl ? 10 * k : taille.width - 10 * k, y(44)),
      fin: true,
    );
  }

  @override
  bool shouldRepaint(_PeintreCourbe ancien) =>
      ancien.trace != trace ||
      ancien.prevu != prevu ||
      ancien.ligne != ligne ||
      ancien.accent != accent ||
      ancien.texte != texte;
}

// ---------------------------------------------------------------------------
// 4. Voici ce que nous avons compris
// ---------------------------------------------------------------------------

/// L'interlude « Voici ce que nous avons compris » : une fiche par apprenant,
/// la langue (et celle de secours), le fuseau deduit, « Comment avez-vous
/// connu Rewayah ? » (facultatif), puis la direction, le remboursement et la
/// correction possible apres l'acceptation.
CoquilleOnboarding interludeRecap(
  BuildContext context,
  WidgetRef ref,
  QuestionnaireInscription q,
  ConstruireEcranOnboarding ecran,
  VoidCallback avancer,
) {
  final r = t.onboarding.recap;
  final TextTheme textes = Theme.of(context).textTheme;
  final AppPalette palette = AppPalette.of(context);
  final String langue = q.langue == null ? '' : nomLangue(q.langue!);
  final String langues = q.langueSecours == null
      ? langue
      : r.sinon(langue: langue, secours: nomLangue(q.langueSecours!));
  final String? fuseau = fuseauIanaAppareil();
  final String sous = <String>[
    r.langue(langue: langues),
    if (fuseau != null) r.heure(ville: villeDuFuseauLibelle(fuseau)),
  ].join(' · ');
  final QuestionnaireControleur c = ref.read(
    questionnaireInscriptionProvider.notifier,
  );
  final SourceConnaissance? source = ref
      .watch(questionnaireInscriptionProvider)
      .source;
  return ecran(
    grand: true,
    expression: ExpressionPraxis.sourire,
    phrase: r.dit,
    titre: r.titre,
    sousTitre: sous,
    corps: <Widget>[
      PileCartes(
        children: <Widget>[
          for (final ApprenantQuestionnaire a in q.apprenants)
            _FicheRecap(apprenant: a),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: r.sourceTitre,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      TextSpan(text: ' ${r.facultatif}'),
                    ],
                  ),
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
                Ecart.vSm,
                // Choix de formulaire, pas un filtre : une reponse facultative.
                Wrap(
                  key: const ValueKey<String>('questionnaire-source'),
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    for (final SourceConnaissance s
                        in SourceConnaissance.values)
                      FilterPill(
                        key: ValueKey<String>('questionnaire-source-${s.name}'),
                        libelle: switch (s) {
                          SourceConnaissance.mosquee => r.sources.mosquee,
                          SourceConnaissance.proche => r.sources.proche,
                          SourceConnaissance.reseaux => r.sources.reseaux,
                          SourceConnaissance.recherche => r.sources.recherche,
                          SourceConnaissance.autre => r.sources.autre,
                        },
                        retenue: source == s,
                        onPress: () => c.basculerSource(s),
                      ),
                  ],
                ),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(r.direction, style: textes.bodyMedium),
                Ecart.vSm,
                Text(r.rembourse, style: textes.bodyMedium),
                Ecart.vSm,
                Text(r.corriger, style: textes.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    ],
    action: boutonOnboarding(r.cta, avancer),
  );
}

class _FicheRecap extends StatelessWidget {
  const _FicheRecap({required this.apprenant});

  final ApprenantQuestionnaire apprenant;

  @override
  Widget build(BuildContext context) {
    final r = t.onboarding.recap;
    final ApprenantQuestionnaire a = apprenant;
    final TextTheme textes = Theme.of(context).textTheme;
    final String niveau = switch (a.niveau) {
      NiveauDeclare.debutLettres => r.niveaux.debut,
      NiveauDeclare.lettresAvecAide => r.niveaux.aide,
      NiveauDeclare.lectureLente => r.niveaux.lente,
      NiveauDeclare.lectureCourante => r.niveaux.courante,
      NiveauDeclare.memorisationPartielle => r.niveaux.memo,
      null => '',
    };
    final String? quantite = switch (a.memorisationDemandee
        ? a.quantite
        : null) {
      QuantiteMemorisee.quelquesSourates => r.quantites.quelques,
      QuantiteMemorisee.unACinqJuz => r.quantites.unACinq,
      QuantiteMemorisee.plusDeCinqJuz => r.quantites.plusDeCinq,
      QuantiteMemorisee.coranEntier => r.quantites.tout,
      null => null,
    };
    final bool femme = a.genre == Genre.femme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            a.titulaire ? r.vous(prenom: a.prenom) : a.prenom,
            style: textes.titleMedium,
          ),
          Ecart.vSm,
          _LigneRecap(
            gauche: a.titulaire
                ? r.adulte
                : LibellesGroupe.insecable(r.ans(n: a.age ?? 0)),
            droite: a.titulaire
                ? (femme ? r.femme : r.homme)
                : (femme ? r.fille : r.garcon),
          ),
          _LigneRecap(
            gauche: r.niveau,
            droite: quantite == null
                ? niveau
                : r.niveauQuantite(niveau: niveau, quantite: quantite),
          ),
          if (a.lectureDemandee)
            _LigneRecap(
              gauche: r.lecture,
              droite: switch (a.lecture) {
                LectureCoran.hafs => r.lectures.hafs,
                LectureCoran.warsh => r.lectures.warsh,
                LectureCoran.autre =>
                  a.lectureAutre.isEmpty ? r.lectures.autre : a.lectureAutre,
              },
            ),
          _LigneRecap(
            gauche: r.objectif,
            droite: switch (a.objectif) {
              ObjectifOnboarding.lire => r.objectifs.lire,
              ObjectifOnboarding.memoriser => r.objectifs.memoriser,
              ObjectifOnboarding.priere => r.objectifs.priere,
              ObjectifOnboarding.indecis => r.objectifs.indecis,
              null => '',
            },
            dernier: true,
          ),
        ],
      ),
    );
  }
}

class _LigneRecap extends StatelessWidget {
  const _LigneRecap({
    required this.gauche,
    required this.droite,
    this.dernier = false,
  });

  final String gauche;
  final String droite;
  final bool dernier;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle corps = textes.bodyMedium ?? const TextStyle();
    return DecoratedBox(
      decoration: BoxDecoration(
        border: dernier
            ? null
            : Border(bottom: palette.borderHairline.asBorderSide()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(gauche, style: palette.inkMuted.applyTo(corps)),
            ),
            Ecart.hMd,
            Flexible(
              child: Text(droite, textAlign: TextAlign.end, style: corps),
            ),
          ],
        ),
      ),
    );
  }
}
