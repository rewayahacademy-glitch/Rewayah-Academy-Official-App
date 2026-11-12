/// ESPACE-APPRENDRE (lot 5) : l'onglet « Programme » de l'espace Apprendre.
///
/// La page que l'eleve consulte librement : son niveau et son etape en cours,
/// mis en avant ; le chemin des etapes de son niveau pour sa tranche d'age,
/// chacune avec ses objectifs ; les dates de l'ecole.
///
/// **Rien n'est calcule ici.** Tout vient de la lecture unique du lot 1
/// (`etape_eleve_lecture`, via `suiviPedagogiqueProvider`, la meme que lit la
/// carte de suivi de « Ma classe ») : le client lit etapes, statuts, dates et
/// rythme tels que le serveur les rend. Les libelles d'etape sont ceux du
/// serveur ; une etape passee dit « Etape precedente », jamais « Etape
/// validee » (ce mot est reserve au resultat d'une evaluation, lot 8).
///
/// **Qui voit les dates** : le serveur le dit (`eleve_voit_dates`). Sans lui,
/// aucune date ni duree ni rythme, et pas non plus la section « Dates de
/// l'ecole » : un enfant de 6 a 9 ans ne voit aucune date. Le mode d'interface
/// ne decide rien (un adulte en Interface guidee garde ses dates).
///
/// Les dates de l'ecole viennent d'un port ([portDatesEcoleProvider]) qui rend
/// aujourd'hui « rien de publie » (le calendrier est le lot 2).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/apprendre/dates_ecole.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/mouvement/apparition_douce.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/session/session_controleur.dart';
import '../../core/suivi/port_suivi_pedagogique.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../suivi_foyer/carte_suivi_pedagogique.dart' show libelleRythme;

/// Les cles des tests.
abstract final class ClesProgramme {
  /// La carte du niveau et de l'etape en cours.
  static const Key niveau = ValueKey<String>('programme-niveau');

  /// Le chemin des etapes.
  static const Key chemin = ValueKey<String>('programme-chemin');

  /// Une etape du chemin.
  static Key etape(int ordre) => ValueKey<String>('programme-etape-$ordre');

  /// L'attente de l'entretien de lecture.
  static const Key attente = ValueKey<String>('programme-attente');

  /// L'etat « pas encore de classe ».
  static const Key vide = ValueKey<String>('programme-vide');

  /// Le squelette de chargement.
  static const Key chargement = ValueKey<String>('programme-chargement');

  /// L'erreur de lecture.
  static const Key erreur = ValueKey<String>('programme-erreur');

  /// La section des dates de l'ecole.
  static const Key datesEcole = ValueKey<String>('programme-dates-ecole');

  /// L'etat vide des dates de l'ecole.
  static const Key datesEcoleVide = ValueKey<String>(
    'programme-dates-ecole-vide',
  );
}

/// L'onglet.
class OngletProgramme extends ConsumerWidget {
  /// Cree l'onglet pour la personne connectee (elle lit pour elle-meme).
  const OngletProgramme({super.key, this.tutoiement = false});

  /// Vrai en Interface guidee : « Ton etape », jamais « Votre etape ».
  final bool tutoiement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? eleveId = ref.watch(sessionProvider).profileId;
    final bool port = ref.watch(portSuiviPedagogiqueProvider) != null;
    if (eleveId == null || !port) {
      return _Vide(tutoiement: tutoiement);
    }
    final AsyncValue<SuiviPedagogique?> lecture = ref.watch(
      suiviPedagogiqueProvider(eleveId),
    );
    if (lecture.hasError && !lecture.hasValue) {
      final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
      void relire() => ref.invalidate(suiviPedagogiqueProvider(eleveId));
      return horsLigne
          ? EtatSansDonnees(
              key: ClesProgramme.erreur,
              quoi: t.suiviPedagogique.erreur,
              onAction: relire,
            )
          : EtatSysteme(
              key: ClesProgramme.erreur,
              nature: NatureEtat.echecServeur,
              phrase: t.suiviPedagogique.erreur,
              libelleAction: t.commun.reessayer,
              onAction: relire,
            );
    }
    if (!lecture.hasValue) {
      return const _Chargement();
    }
    final SuiviPedagogique? suivi = lecture.value;
    if (suivi == null) return _Vide(tutoiement: tutoiement);
    if (suivi.enAttenteEntretien) {
      return EmptyState(
        key: ClesProgramme.attente,
        message: tutoiement
            ? t.suiviPedagogique.attenteEntretienTu
            : t.suiviPedagogique.attenteEntretien,
        icone: AppIcons.chemin,
        registre: RegistreVide.subi,
      );
    }
    final bool dates = suivi.eleveVoitDates;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(titre: t.apprendre.programme.niveau),
        Ecart.vMd,
        ApparitionDouce(
          child: _CarteNiveau(suivi: suivi, dates: dates),
        ),
        if (suivi.chemin.isNotEmpty) ...<Widget>[
          Ecart.vSection,
          SectionHeader(
            key: ClesProgramme.chemin,
            titre: (suivi.niveauNom ?? '').isEmpty
                ? t.suiviPedagogique.etape
                : t.suiviPedagogique.chemin(niveau: suivi.niveauNom!),
          ),
          Ecart.vMd,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.lg,
            children: <Widget>[
              for (final (int i, EtapeDuChemin e) in suivi.chemin.indexed)
                ElementEchelonne(
                  index: i,
                  child: _CarteEtape(etape: e, dates: dates),
                ),
            ],
          ),
        ],
        if (dates) ...<Widget>[Ecart.vSection, _DatesEcole(eleveId: eleveId)],
      ],
    );
  }
}

/// Pas encore de classe : l'etape apparaitra a l'entree en classe.
class _Vide extends StatelessWidget {
  const _Vide({required this.tutoiement});

  final bool tutoiement;

  @override
  Widget build(BuildContext context) => EmptyState(
    key: ClesProgramme.vide,
    message: t.suiviPedagogique.vide,
    icone: AppIcons.chemin,
    registre: RegistreVide.subi,
  );
}

/// Les squelettes : la carte du niveau, puis les etapes.
class _Chargement extends StatelessWidget {
  const _Chargement();

  @override
  Widget build(BuildContext context) => const Column(
    key: ClesProgramme.chargement,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: AppSpacing.lg,
    children: <Widget>[
      Skeleton(hauteur: AppSpacing.respiration * 2),
      Skeleton.liste(lignes: 3),
    ],
  );
}

String _jour(DateTime d) => LibellesGroupe.insecable(
  t.suiviPedagogique.dateJour(
    numero: '${d.day}',
    mois: t.commun.dates.mois[d.month - 1],
    annee: '${d.year}',
  ),
);

/// Le niveau et l'etape en cours, mis en avant.
class _CarteNiveau extends StatelessWidget {
  const _CarteNiveau({required this.suivi, required this.dates});

  final SuiviPedagogique suivi;
  final bool dates;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final s = t.suiviPedagogique;
    final int total = suivi.chemin.length;
    final int? ordre = suivi.etapeOrdre;
    final String niveau = suivi.niveauNom ?? '';
    final String reperes = <String>[
      if (niveau.isNotEmpty) niveau,
      if (ordre != null && total > 0)
        t.apprendre.programme.etapeSur(ordre: '$ordre', total: '$total'),
    ].join(' · ');
    final String? rythme = dates ? libelleRythme(suivi) : null;
    final List<_Fait> faits = <_Fait>[
      if (suivi.matierePrincipale case final String m)
        _Fait(AppIcons.livreOuvert, s.matierePrincipale, m),
      if (suivi.matiereSecondaire case final String m)
        _Fait(AppIcons.lecon, s.matiereSecondaire, m),
      if (dates && suivi.entreeLe != null)
        _Fait(AppIcons.historique, s.depuis, _jour(suivi.entreeLe!)),
      if (dates &&
          suivi.dureePrevueSemaines != null &&
          suivi.dateLimiteSemaines != null)
        _Fait(
          AppIcons.attente,
          s.dureePrevue,
          LibellesGroupe.insecable(
            s.dureesEtape(
              prevue: '${suivi.dureePrevueSemaines}',
              limite: '${suivi.dateLimiteSemaines}',
            ),
          ),
        ),
      if (dates && suivi.dateLimite != null)
        _Fait(AppIcons.journee, s.aFinirAvant, _jour(suivi.dateLimite!)),
      if (dates && suivi.horizon != null && niveau.isNotEmpty)
        _Fait(
          AppIcons.echeance,
          s.horizonNiveau(niveau: niveau),
          _jour(suivi.horizon!),
        ),
      if (rythme != null) _Fait(AppIcons.horloge, s.rythme, rythme),
    ];
    return AppCard(
      key: ClesProgramme.niveau,
      surface: palette.washAccent,
      dominante: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (reperes.isNotEmpty) ...<Widget>[
            TexteSansCoupure(
              reperes,
              style: palette.washAccent.applyTo(
                textes.labelLarge ?? const TextStyle(),
              ),
            ),
            Ecart.vXs,
          ],
          TexteSansCoupure(
            suivi.etapeNom,
            style: palette.washAccent.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
          if (total > 1 && ordre != null) ...<Widget>[
            Ecart.vMd,
            _Segments(chemin: suivi.chemin),
          ],
          if (faits.isNotEmpty) ...<Widget>[
            Ecart.vLg,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.md,
              children: <Widget>[
                for (final _Fait f in faits) _LigneFait(fait: f),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Un fait de l'etape : icone, intitule, valeur.
class _Fait {
  const _Fait(this.icone, this.libelle, this.valeur);

  final AppIcon icone;
  final String libelle;
  final String valeur;
}

class _LigneFait extends StatelessWidget {
  const _LigneFait({required this.fait});

  final _Fait fait;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IconTheme(
            data: IconThemeData(
              color: palette.washAccent.onBackground,
              size: AppSpacing.xl,
            ),
            child: Icon(fait.icone.repos),
          ),
          Ecart.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TexteSansCoupure(
                  fait.libelle,
                  style: palette.washAccent.applyTo(
                    textes.bodySmall ?? const TextStyle(),
                  ),
                ),
                TexteSansCoupure(
                  fait.valeur,
                  style: palette.washAccent.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Le chemin en un coup d'oeil : un segment par etape, les etapes passees et
/// la sienne pleines, les etapes a venir creuses. Decoratif : « Etape 2 sur
/// 4 » est ecrit juste au-dessus, l'etat ne repose jamais sur la couleur.
class _Segments extends StatelessWidget {
  const _Segments({required this.chemin});

  final List<EtapeDuChemin> chemin;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return ExcludeSemantics(
      child: Row(
        spacing: AppSpacing.xs,
        children: <Widget>[
          for (final EtapeDuChemin e in chemin)
            Expanded(
              flex: e.statut == StatutEtape.enCours ? 2 : 1,
              child: DecoratedBox(
                decoration:
                    (e.statut == StatutEtape.aVenir
                            ? palette.surfaceRaised
                            : palette.surfacePrimary)
                        .decoration(borderRadius: AppRadius.arrondiFull),
                child: const SizedBox(height: AppSpacing.sm),
              ),
            ),
        ],
      ),
    );
  }
}

/// Une etape du chemin : son nom, son statut, sa duree (si l'eleve voit ses
/// dates) et ses objectifs. La sienne est mise en avant.
class _CarteEtape extends StatelessWidget {
  const _CarteEtape({required this.etape, required this.dates});

  final EtapeDuChemin etape;
  final bool dates;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final s = t.suiviPedagogique;
    final bool enCours = etape.statut == StatutEtape.enCours;
    final String statut = switch (etape.statut) {
      StatutEtape.precedente => s.statutPrecedente,
      StatutEtape.enCours => s.statutEnCours,
      StatutEtape.aVenir => s.statutAVenir,
    };
    final AppIcon icone = switch (etape.statut) {
      StatutEtape.precedente => AppIcons.historique,
      StatutEtape.enCours => AppIcons.signet,
      StatutEtape.aVenir => AppIcons.attente,
    };
    final String? duree =
        dates &&
            etape.dureePrevueSemaines != null &&
            etape.dateLimiteSemaines != null
        ? LibellesGroupe.insecable(
            s.dureesEtape(
              prevue: '${etape.dureePrevueSemaines}',
              limite: '${etape.dateLimiteSemaines}',
            ),
          )
        : null;
    final String titre = s.etapeNumero(ordre: '${etape.ordre}', nom: etape.nom);
    return AppCard(
      key: ClesProgramme.etape(etape.ordre),
      selectionnee: enCours,
      libelleSemantique: <String>[
        titre,
        statut,
        ?duree,
        ...etape.objectifs,
      ].join('. '),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                IconTheme(
                  data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
                  child: Icon(icone.resoudre(selectionne: enCours)),
                ),
                Ecart.hMd,
                Expanded(
                  child: TexteSansCoupure(
                    titre,
                    style: palette.surfaceRaised.applyTo(
                      textes.titleMedium ?? const TextStyle(),
                    ),
                  ),
                ),
              ],
            ),
            Ecart.vSm,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusPill(
                libelle: statut,
                ton: enCours ? TonEtat.accent : TonEtat.neutre,
              ),
            ),
            if (duree != null) ...<Widget>[
              Ecart.vSm,
              TexteSansCoupure(
                duree,
                style: palette.inkMuted.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
            ],
            if (etape.objectifs.isNotEmpty) ...<Widget>[
              Ecart.vMd,
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.sm,
                children: <Widget>[
                  for (final String objectif in etape.objectifs)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        IconTheme(
                          data: palette.inkMuted.asIconTheme(
                            size: AppSpacing.lg,
                          ),
                          child: Icon(AppIcons.objectifs.repos),
                        ),
                        Ecart.hSm,
                        Expanded(
                          child: TexteSansCoupure(
                            objectif,
                            style: palette.surfaceRaised.applyTo(
                              textes.bodyMedium ?? const TextStyle(),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// « Dates de l'ecole » : les evaluations, fermetures et rencontres de
/// recitation que le calendrier publiera (lot 2). Aujourd'hui, rien n'est
/// publie : l'etat vide le dit, sans date inventee.
class _DatesEcole extends ConsumerWidget {
  const _DatesEcole({required this.eleveId});

  final String eleveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<DateEcole>> lecture = ref.watch(
      datesEcoleProvider(eleveId),
    );
    final Widget corps;
    if (lecture.hasError && !lecture.hasValue) {
      // Une absence n'est pas un echec : seule une lecture en echec le dit.
      corps = EmptyState(
        message: t.suiviPedagogique.erreur,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: () => ref.invalidate(datesEcoleProvider(eleveId)),
      );
    } else if (!lecture.hasValue) {
      corps = const Skeleton.liste(lignes: 2);
    } else if (lecture.requireValue.isEmpty) {
      corps = EmptyState(
        key: ClesProgramme.datesEcoleVide,
        message: t.apprendre.programme.datesEcoleVide,
        icone: AppIcons.calendrier,
        registre: RegistreVide.subi,
      );
    } else {
      final g = t.apprendre.programme.genre;
      corps = GroupeReglages(
        lignes: <LigneRubrique>[
          for (final DateEcole d in lecture.requireValue)
            LigneRubrique(
              icone: AppIcons.calendrier,
              libelle:
                  d.libelle ??
                  switch (d.genre) {
                    GenreDateEcole.evaluation => g.evaluation,
                    GenreDateEcole.fermeture => g.fermeture,
                    GenreDateEcole.rencontre => g.rencontre,
                  },
              legende: _jour(d.jour),
            ),
        ],
      );
    }
    return Column(
      key: ClesProgramme.datesEcole,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(titre: t.apprendre.programme.datesEcole),
        Ecart.vMd,
        corps,
      ],
    );
  }
}
