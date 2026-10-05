import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/seance_famille/seance_famille.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/selecteur_profils.dart';
import '../../core/widgets/status_pill.dart';

/// Ce que l'Accueil affiche d'une seance, a un instant serveur donne.
///
/// **Pure et unique** : le sous-libelle du selecteur de profils et le bloc
/// seance de la carte lisent tous deux cette valeur, calculee par
/// [AffichageSeance.depuis] depuis la meme `SeanceFamille` (contrat K2) et le
/// meme instant. Deux calculs finiraient par dire « En seance » au-dessus d'un
/// « Cours dans 13 min » (maquette V1, defaut C1 du manifeste).
@immutable
class AffichageSeance {
  const AffichageSeance._({
    required this.etat,
    required this.restant,
    required this.heure,
    required this.ville,
    required this.fuseau,
    required this.date,
    required this.duree,
    required this.dureeEnPhrase,
    this.heureClasse,
  });

  /// Calcule l'affichage de [seance] a [maintenantServeurUtc].
  ///
  /// `null` pour l'instant : aucune horloge serveur, l'etat est
  /// `horaireIncertain` et l'heure est celle de l'appareil, **dite comme
  /// telle** (« Heure de cet appareil »), jamais un fuseau devine.
  factory AffichageSeance.depuis(
    SeanceFamille seance, {
    required DateTime? maintenantServeurUtc,
  }) {
    final HorlogeAffichee? foyer = seance.heureFoyer;
    final HorlogeAffichee? classe = seance.heureGroupe;
    final DateTime local = seance.debutUtc.toLocal();
    return AffichageSeance._(
      etat: etatSeanceFamille(
        seance,
        maintenantServeurUtc: maintenantServeurUtc,
      ),
      restant: restantAvant(seance, maintenantServeurUtc: maintenantServeurUtc),
      heure: foyer?.heureLocaleRendue ?? heureDeLAppareil(local),
      ville: foyer?.libelleVille,
      fuseau: foyer == null
          ? t.tuteur.accueil.heureAppareil
          : t.tuteur.accueil.heureDe(ville: foyer.libelleVille),
      date: foyer?.dateLocaleRendue ?? dateDeLAppareil(local),
      duree: LibellesGroupe.dureeSeule(seance.dureePrevue),
      dureeEnPhrase: LibellesGroupe.dureeLisible(seance.dureePrevue),
      heureClasse: classe == null
          ? null
          : t.tuteur.accueil.heureClasse(
              heure: classe.heureLocaleRendue,
              ville: classe.libelleVille,
            ),
    );
  }

  /// L'etat de la seance (K2).
  final EtatSeanceFamille etat;

  /// Le temps avant le debut, seulement a venir ou salle ouverte ; jamais
  /// negatif.
  final Duration? restant;

  /// L'heure de debut : rendue par le serveur, sinon celle de l'appareil.
  final String heure;

  /// La ville du fuseau du foyer, rendue par le serveur ; nulle sans heure
  /// serveur.
  final String? ville;

  /// Le fuseau lisible : « Heure de Riyad », ou « Heure de cet appareil ».
  final String fuseau;

  /// La date lisible : « Lundi 21 septembre ».
  final String date;

  /// La duree prevue, « 1 h 30 », affichee seule : ancree en interface de
  /// droite a gauche ([LibellesGroupe.dureeSeule]).
  final String duree;

  /// La meme duree, sans ancre : elle suit la date dans [dateEtDuree].
  final String dureeEnPhrase;

  /// « Lundi 21 septembre · 45 min » : la duree suit la date, l'ancre de sens
  /// n'a rien a faire au milieu du libelle (DUREE-INSECABLE-3).
  String get dateEtDuree =>
      t.tuteur.accueil.dateEtDuree(date: date, duree: dureeEnPhrase);

  /// L'heure dans le fuseau de la classe quand il differe, sinon `null`.
  final String? heureClasse;

  /// La ligne d'etat, sous l'heure : « Cours dans 3 h 28 », « Seance en
  /// direct », « Seance toujours en direct »... **Jamais de nombre negatif.**
  String get ligneEtat => switch (etat) {
    EtatSeanceFamille.aVenir || EtatSeanceFamille.salleOuverte =>
      restant == null
          ? t.tuteur.accueil.horaireIncertain
          : LibellesGroupe.compteARebours(restant!),
    EtatSeanceFamille.enDirect => t.tuteur.accueil.seanceEnDirect,
    EtatSeanceFamille.prolongee => LibellesGroupe.prolongee,
    EtatSeanceFamille.terminee => t.tuteur.accueil.seanceTerminee,
    EtatSeanceFamille.annulee => t.tuteur.accueil.seanceAnnulee,
    EtatSeanceFamille.annuleeTardive => t.tuteur.accueil.motifAnnuleeTard,
    EtatSeanceFamille.nonTenue ||
    EtatSeanceFamille.reportee => t.tuteur.accueil.seanceNonTenue,
    EtatSeanceFamille.horaireIncertain => t.tuteur.accueil.horaireIncertain,
  };

  /// L'etat de seance a reconnaitre d'un coup d'oeil (en direct, annulee), ou
  /// `null`. Ces deux etats se montrent par [PastilleEtatSeance] et jamais
  /// par une `StatusPill` seule (ON-AIR-1, ANNUL-VIS-1).
  EtatPastilleSeance? get etatPastille => etatPastilleDe(etat);

  /// La pastille a afficher pour cet etat : [PastilleEtatSeance] pour « En
  /// direct » et « Annulee », la `StatusPill` de [pastille] pour les autres,
  /// `null` quand l'etat n'en porte pas.
  Widget? get widgetPastille {
    final EtatPastilleSeance? seance = etatPastille;
    if (seance != null) return PastilleEtatSeance(etat: seance);
    final ({String libelle, TonEtat ton})? p = pastille;
    return p == null ? null : StatusPill(libelle: p.libelle, ton: p.ton);
  }

  /// La pastille d'etat, ou `null` quand l'etat n'en porte pas (a venir,
  /// horaire incertain : une pastille n'y dirait rien de sur).
  ({String libelle, TonEtat ton})? get pastille => switch (etat) {
    EtatSeanceFamille.salleOuverte => (
      libelle: LibellesGroupe.salleOuverteCourt,
      ton: TonEtat.succes,
    ),
    EtatSeanceFamille.enDirect || EtatSeanceFamille.prolongee => (
      libelle: LibellesGroupe.enDirect,
      ton: TonEtat.succes,
    ),
    EtatSeanceFamille.annulee || EtatSeanceFamille.annuleeTardive => (
      libelle: t.tuteur.accueil.pastilleAnnulee,
      ton: TonEtat.alerte,
    ),
    EtatSeanceFamille.nonTenue || EtatSeanceFamille.reportee => (
      libelle: t.tuteur.accueil.pastilleNonTenue,
      ton: TonEtat.avertissement,
    ),
    EtatSeanceFamille.terminee => (
      libelle: t.tuteur.accueil.pastilleTerminee,
      ton: TonEtat.neutre,
    ),
    EtatSeanceFamille.aVenir || EtatSeanceFamille.horaireIncertain => null,
  };

  /// Le sous-libelle court du selecteur de profils.
  String get etatCourt {
    final e = t.tuteur.accueil.etatCourt;
    return switch (etat) {
      EtatSeanceFamille.enDirect || EtatSeanceFamille.prolongee => e.enDirect,
      EtatSeanceFamille.salleOuverte => e.salleOuverte,
      EtatSeanceFamille.aVenir => _dans(restant),
      EtatSeanceFamille.annulee ||
      EtatSeanceFamille.annuleeTardive => e.annulee,
      EtatSeanceFamille.nonTenue || EtatSeanceFamille.reportee => e.nonTenue,
      EtatSeanceFamille.terminee => e.terminee,
      EtatSeanceFamille.horaireIncertain => e.prevue,
    };
  }

  /// Le point de statut du selecteur, toujours double par [etatCourt].
  PointStatut get point => switch (etat) {
    EtatSeanceFamille.enDirect ||
    EtatSeanceFamille.prolongee ||
    EtatSeanceFamille.salleOuverte => PointStatut.succes,
    EtatSeanceFamille.aVenir => PointStatut.attention,
    EtatSeanceFamille.annulee ||
    EtatSeanceFamille.annuleeTardive ||
    EtatSeanceFamille.nonTenue ||
    EtatSeanceFamille.reportee => PointStatut.alerte,
    EtatSeanceFamille.terminee ||
    EtatSeanceFamille.horaireIncertain => PointStatut.neutre,
  };

  static String _dans(Duration? restant) {
    final e = t.tuteur.accueil.etatCourt;
    if (restant == null) {
      return e.prevue;
    }
    final int minutes = restant.inMinutes;
    // DUREE-INSECABLE-1 : « Dans 3 h 28 » ne se scinde jamais.
    if (minutes < Duration.minutesPerHour) {
      return LibellesGroupe.insecable(
        e.dansMinutes(minutes: minutes < 1 ? 1 : minutes),
      );
    }
    if (minutes < Duration.minutesPerDay) {
      return LibellesGroupe.insecable(
        e.dansHeures(
          heures: minutes ~/ Duration.minutesPerHour,
          minutes: (minutes % Duration.minutesPerHour).toString().padLeft(
            2,
            '0',
          ),
        ),
      );
    }
    return LibellesGroupe.insecable(e.dansJours(jours: restant.inDays));
  }
}

/// L'heure locale de l'appareil, « 13:45 ».
///
/// Seulement quand aucune heure n'est rendue par le serveur, et toujours
/// accompagnee du libelle « Heure de cet appareil » : ce n'est pas un fuseau
/// devine, c'est l'aveu de la source.
String heureDeLAppareil(DateTime local) =>
    '${local.hour.toString().padLeft(2, '0')}:'
    '${local.minute.toString().padLeft(2, '0')}';

/// La date locale de l'appareil, « Lundi 21 septembre », par les libelles
/// `commun.dates` (jamais une liste de noms en dur).
String dateDeLAppareil(DateTime local) => t.commun.dates.jourDate(
  jour: t.commun.dates.jours[local.weekday - 1],
  numero: local.day,
  mois: t.commun.dates.mois[local.month - 1],
);

/// Le bloc seance de la carte classe : date et etat, heure et duree, ligne
/// d'etat, conseil d'appareil.
///
/// Deux compositions, un seul contenu (maquettes V1 et V2) :
///
/// - [compact] (telephone) : zone imbriquee `surfaceSunken` sans bordure, la
///   seule imbrication admise ; la date en tete, « Votre heure » et « Duree »
///   en deux colonnes quand leurs libelles y tiennent sans couper de mot,
///   sinon la duree sous l'heure (320 px, texte double) ;
/// - large (tablette, bureau) : a meme la carte mise en avant, « Prochaine
///   seance » en tete, l'heure en grand chiffre tabulaire, la date et le
///   fuseau dessous ; la duree a droite, ou dessous si elle n'y tient pas
///   entiere.
class BlocSeance extends StatelessWidget {
  /// Cree le bloc.
  const BlocSeance({required this.affichage, required this.compact, super.key});

  /// Ce qu'il faut afficher.
  final AffichageSeance affichage;

  /// Vrai sur telephone.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final ({String libelle, TonEtat ton})? pastille = affichage.pastille;

    // BENTO-2b : un `Wrap` aux deux bouts et non une `Row` : le titre au
    // debut, la pastille a la fin quand ils tiennent ensemble ; a 320 px et
    // texte double, la pastille passe a la ligne au lieu de couper la date
    // mot par mot.
    final Widget tete = Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            compact ? affichage.date : t.tuteur.accueil.prochaineSeance,
            style: palette.inkStrong.applyTo(
              (compact ? textes.titleMedium : textes.titleLarge) ??
                  const TextStyle(),
            ),
          ),
        ),
        if (pastille != null)
          StatusPill(libelle: pastille.libelle, ton: pastille.ton),
      ],
    );

    final Widget heures = compact
        ? _HeuresCompactes(affichage: affichage)
        : _HeuresLarges(affichage: affichage);

    final Widget ligneEtat = _LigneIcone(
      icone: AppIcons.horloge,
      texte: affichage.ligneEtat,
      style: AppTypography.tabulaire(
        palette.inkStrong.applyTo(textes.titleMedium ?? const TextStyle()),
      ),
      encreIcone: palette.inkMuted,
    );

    final List<Widget> contenu = <Widget>[
      tete,
      Ecart.vMd,
      heures,
      if (affichage.heureClasse != null) ...<Widget>[
        Ecart.vSm,
        Text(
          affichage.heureClasse!,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
      ],
      Ecart.vLg,
      ligneEtat,
      if (compact) ...<Widget>[Ecart.vMd, const ConseilAppareil()],
    ];

    final Widget colonne = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: contenu,
    );

    if (!compact) {
      return colonne;
    }
    return DecoratedBox(
      decoration: palette.surfaceSunken.decoration(
        borderRadius: AppRadius.arrondiSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: colonne,
      ),
    );
  }
}

/// Le filet horizontal qui separe deux sujets dans une meme carte : une ligne
/// `contourCarte`, sans marge propre (la carte groupee reste UN rectangle,
/// decisions du directeur, section 1 ter, point 3).
class FiletHorizontal extends StatelessWidget {
  /// Cree le filet.
  const FiletHorizontal({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: palette.contourCarte.asBorderSide()),
      ),
      child: const SizedBox(width: double.infinity),
    );
  }
}

/// Le conseil d'appareil, discret : « Tablette ou ordinateur conseille. »
class ConseilAppareil extends StatelessWidget {
  /// Cree le conseil.
  const ConseilAppareil({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return _LigneIcone(
      icone: AppIcons.tabletteOuOrdinateur,
      texte: LibellesGroupe.conseilAppareil,
      style: palette.inkMuted.applyTo(textes.bodyMedium ?? const TextStyle()),
      encreIcone: palette.inkMuted,
    );
  }
}

class _LigneIcone extends StatelessWidget {
  const _LigneIcone({
    required this.icone,
    required this.texte,
    required this.style,
    required this.encreIcone,
  });

  final AppIcon icone;
  final String texte;
  final TextStyle style;
  final AppInkColor encreIcone;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      ExcludeSemantics(
        child: IconTheme(
          data: encreIcone.asIconTheme(size: AppSpacing.xxl),
          child: Icon(icone.repos),
        ),
      ),
      Ecart.hMd,
      Expanded(child: Text(texte, style: style)),
    ],
  );
}

/// Telephone : « Votre heure / 13:45 Paris » et « Duree / 1 h 30 », separes
/// par un filet vertical ; la duree passe sous l'heure, sans filet, quand
/// un libelle ne tiendrait pas entier dans sa colonne.
class _HeuresCompactes extends StatelessWidget {
  const _HeuresCompactes({required this.affichage});

  final AffichageSeance affichage;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle libelle = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final TextStyle valeur = AppTypography.tabulaire(
      palette.inkStrong.applyTo(textes.titleMedium ?? const TextStyle()),
    );
    final String libelleHeure = affichage.ville == null
        ? affichage.fuseau
        : LibellesGroupe.votreHeure;
    final String valeurHeure = affichage.ville == null
        ? affichage.heure
        : LibellesGroupe.heureEtVille(
            heure: affichage.heure,
            ville: affichage.ville!,
          );
    final Widget heure = MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(libelleHeure, style: libelle),
          Text(valeurHeure, style: valeur),
        ],
      ),
    );
    final Widget duree = MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(LibellesGroupe.dureeLibelle, style: libelle),
          Text(affichage.duree, style: valeur),
        ],
      ),
    );
    final double retrait = _ColonneFiletee.retrait(palette);
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints c) {
        // BENTO-2b/2c : a 320 px (texte x1 ou x2), la demi-colonne coupait
        // « Duré/e ». Deux colonnes seulement si chaque libelle y tient sans
        // couper de mot, mesure sur la largeur REELLE de chaque colonne (la
        // duree perd le filet et ses deux marges) ; sinon la duree passe
        // sous l'heure, sans filet (320 px, texte double).
        final double colonne = c.maxWidth / 2;
        final bool deuxColonnes =
            _motLePlusLong(context, libelleHeure, libelle) <= colonne &&
            _motLePlusLong(context, valeurHeure, valeur) <= colonne &&
            _surUneLigne(context, LibellesGroupe.dureeLibelle, libelle) <=
                colonne - retrait &&
            _surUneLigne(context, affichage.duree, valeur) <= colonne - retrait;
        if (!deuxColonnes) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[heure, Ecart.vSm, duree],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: heure),
              Expanded(child: _ColonneFiletee(child: duree)),
            ],
          ),
        );
      },
    );
  }
}

/// Tablette et bureau : l'heure en grand, la date et le fuseau dessous ; la
/// duree a droite du filet vertical, ou sous l'heure quand elle n'y tient
/// pas entiere.
class _HeuresLarges extends StatelessWidget {
  const _HeuresLarges({required this.affichage});

  final AffichageSeance affichage;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle styleHeure = palette.inkStrong.applyTo(
      textes.displaySmall ?? const TextStyle(),
    );
    final TextStyle styleDate = palette.inkMuted.applyTo(
      textes.bodyLarge ?? const TextStyle(),
    );
    final TextStyle styleLibelle = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final TextStyle styleDuree = AppTypography.tabulaire(
      palette.inkStrong.applyTo(textes.titleLarge ?? const TextStyle()),
    );
    final String dateEtFuseau = t.tuteur.accueil.dateEtFuseau(
      date: affichage.date,
      fuseau: affichage.fuseau,
    );
    final Widget heure = MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(affichage.heure, style: styleHeure),
          Text(dateEtFuseau, style: styleDate),
        ],
      ),
    );
    final Widget duree = MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(LibellesGroupe.dureeLibelle, style: styleLibelle),
          Text(affichage.duree, style: styleDuree),
        ],
      ),
    );
    final double retrait = _ColonneFiletee.retrait(palette);
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints c) {
        // BENTO-2c (m1 de BENTO-2b-R) : de 600 a 630 px, texte x2, la
        // colonne de la duree (un quart, moins le filet) coupait « Duré/e »
        // et « 45 / min ». Meme regle que sur telephone : la duree a droite
        // seulement si tout y tient entier, sinon sous l'heure, sans filet.
        final double colonneHeure = c.maxWidth * 3 / 4;
        final double colonneDuree = c.maxWidth / 4 - retrait;
        final bool deuxColonnes =
            _surUneLigne(context, affichage.heure, styleHeure) <=
                colonneHeure &&
            _motLePlusLong(context, dateEtFuseau, styleDate) <= colonneHeure &&
            _surUneLigne(context, LibellesGroupe.dureeLibelle, styleLibelle) <=
                colonneDuree &&
            _surUneLigne(context, affichage.duree, styleDuree) <= colonneDuree;
        if (!deuxColonnes) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[heure, Ecart.vMd, duree],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(flex: 3, child: heure),
              Expanded(child: _ColonneFiletee(child: duree)),
            ],
          ),
        );
      },
    );
  }
}

/// La largeur de [texte] sur une seule ligne, au style que `Text` lui
/// donnerait ici (style par defaut, echelle du texte, sens de lecture).
double _surUneLigne(BuildContext context, String texte, TextStyle style) {
  final TextPainter peintre = TextPainter(
    text: TextSpan(
      text: texte,
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
    maxLines: 1,
  )..layout();
  final double largeur = peintre.width;
  peintre.dispose();
  return largeur;
}

/// La largeur du mot le plus long de [texte] : la ligne peut passer a la
/// ligne entre deux mots, jamais au milieu d'un mot.
double _motLePlusLong(BuildContext context, String texte, TextStyle style) =>
    texte
        .split(RegExp(r'\s+'))
        .where((String mot) => mot.isNotEmpty)
        .map((String mot) => _surUneLigne(context, mot, style))
        .fold(0, math.max);

/// La colonne de droite des heures : un filet vertical a son debut, comme
/// les autres separateurs (`contourCarte`), jamais plus fonce (manifeste,
/// bloc seance).
class _ColonneFiletee extends StatelessWidget {
  const _ColonneFiletee({required this.child});

  final Widget child;

  /// Ce que la colonne prend a son contenu : deux marges et le filet.
  static double retrait(AppPalette palette) =>
      AppSpacing.lg * 2 + palette.contourCarte.asBorderSide().width;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BorderDirectional(start: palette.contourCarte.asBorderSide()),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.lg),
          child: child,
        ),
      ),
    );
  }
}
