// Revenus de l'enseignant (FI-10, guide Finance V4 §1.4, §4 et §8 F6 ;
// maquette 17_finance/V/08). Titre « Mes revenus » et detail par seance et
// par eleve depuis REVENUS-VERITE (pilote, 06/11/2026, points 2 a 4) : la
// paie se fait par seance, par eleve present et par heure ; un absent n'est
// jamais paye ; aucun minimum (DECISION-TARIFS-2026-10-18, 19/10). Le jour de
// paie est lu au serveur (`paie.fenetre_versement`).
//
// **Une estimation, jamais une paie definitive** : le mot est ecrit en tete,
// et la mention de bas de page dit que le releve de l'academie fait foi.
// Synthese : revenu estime, heures assurees, jour de paie, Classes, taux
// horaire moyen. Par Classe : type, capacite, heures assurees, taux horaire
// effectif, montant estime ; un tableau compact avec sa ligne de total sur
// bureau, des lignes groupees sur telephone. Puis, seance par seance, chaque
// eleve present ou absent et ce qu'il a rapporte (part calculee au serveur).
// Puis la regle en trois phrases (`commun.paieEnseignant`, les memes textes
// que la Politique commerciale de la direction), l'aide Internet, a part, et
// le releve des mois arretes par l'academie (guide §4), lu au port :
// indisponible tant que le serveur ne le rend pas (FI-BR-11), jamais un mois
// « paye » invente.
//
// Tout chiffre d'argent vient du port (`PortRevenusEnseignant`), totaux,
// taux moyen et part de chaque eleve compris : l'ecran ne calcule ni taux ni
// montant (FI6). Le prenom de l'eleve est montre a cote de ce qu'il a
// rapporte (demande du pilote du 06/11, point 3 ; l'enseignant le voit deja
// en salle) ; jamais un solde ni un montant paye par une famille (guide
// §5.5).
//
// Le choix du mois est garde (FI-Q18 (a), decide par delegation le 05/10 ;
// revue FI-VAGUE-R R5-05) : il ne propose que les mois rendus par la source
// (`moisDisponibles`, FI-BR-11). Les variations « vs mois precedent »
// n'existent dans aucun contrat : elles ne sont pas inventees.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_revenus_enseignant.dart';
import '../../core/finance/format_montant.dart';
import '../../core/finance/montant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/ligne_finance.dart';
import '../../core/widgets/montant_argent.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/selecteur_mois.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';

/// Le mois choisi sur les revenus ; nul : le mois en cours (FI-Q18 (a)).
/// Remis a nul quand la personne connectee change.
class MoisRevenus extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    surveillerPersonneConnectee(ref);
    return null;
  }

  /// Choisit [mois] (premier jour).
  void choisir(DateTime mois) => state = mois;
}

/// Le mois choisi d'une demonstration, sous son conteneur imbrique : sans
/// session a surveiller (la session de l'application n'y est pas lue).
class MoisRevenusDemo extends MoisRevenus {
  @override
  DateTime? build() => null;
}

/// Le mois choisi sur les revenus.
final NotifierProvider<MoisRevenus, DateTime?> moisRevenusProvider =
    NotifierProvider<MoisRevenus, DateTime?>(MoisRevenus.new);

/// Les mois que la source sait rendre, le plus recent d'abord (FI-BR-11).
/// Sans source (production), aucun choix n'est pose.
final FutureProvider<List<DateTime>> moisRevenusDisponiblesProvider =
    FutureProvider<List<DateTime>>((Ref ref) {
      surveillerPersonneConnectee(ref);
      return ref.watch(portRevenusEnseignantProvider).moisDisponibles();
    }, retry: (int retryCount, Object error) => null);

/// Lit les revenus du mois [mois] sur [port] : le mois en cours quand il est
/// nul.
Future<RevenusEnseignant> lireRevenus(
  PortRevenusEnseignant port,
  DateTime? mois,
) => mois == null ? port.moisEnCours() : port.duMois(mois);

/// Les revenus estimes du mois choisi, lus par le port (FI-BR-11). Aucune
/// relance automatique : une capacite absente ne revient pas en insistant,
/// et « Reessayer » reste un geste de la personne (`BlocAsynchrone`).
final FutureProvider<RevenusEnseignant> revenusEnseignantProvider =
    FutureProvider<RevenusEnseignant>((Ref ref) {
      surveillerPersonneConnectee(ref);
      return lireRevenus(
        ref.watch(portRevenusEnseignantProvider),
        ref.watch(moisRevenusProvider),
      );
    }, retry: (int retryCount, Object error) => null);

/// Les revenus du mois en cours, quel que soit le mois choisi sur la page :
/// lus par le Profil pour dire les heures assurees du mois (REVENUS-VERITE,
/// point 2). Meme regle de relance que [revenusEnseignantProvider].
final FutureProvider<RevenusEnseignant> revenusMoisEnCoursProvider =
    FutureProvider<RevenusEnseignant>((Ref ref) {
      surveillerPersonneConnectee(ref);
      return ref.watch(portRevenusEnseignantProvider).moisEnCours();
    }, retry: (int retryCount, Object error) => null);

/// Les heures assurees du mois en cours, pour la ligne du Profil : « 8 h
/// assurées en novembre ».
String heuresDuMoisPourProfil(RevenusEnseignant r) =>
    t.enseignant.profil.revenusHeures(
      heures: _duree(r.total.minutesAssurees),
      mois: t.commun.dates.mois[r.debut.month - 1],
    );

/// Le releve des mois arretes par l'academie, lu par le port (FI-BR-11). Meme
/// regle de relance que [revenusEnseignantProvider].
final FutureProvider<List<LigneReleve>> releveEnseignantProvider =
    FutureProvider<List<LigneReleve>>((Ref ref) {
      surveillerPersonneConnectee(ref);
      return ref.watch(portRevenusEnseignantProvider).releve();
    }, retry: (int retryCount, Object error) => null);

/// `/enseignant/revenus` : l'estimation du mois, atteinte depuis le Profil
/// et depuis Aujourd'hui (lot F1).
class RevenusEnseignantPage extends ConsumerWidget {
  /// Cree l'ecran.
  const RevenusEnseignantPage({super.key, this.onRetour});

  /// Le retour au Profil. Nul : la pile du routeur, sinon `/enseignant/profil`.
  final VoidCallback? onRetour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<RevenusEnseignant> revenus = ref.watch(
      revenusEnseignantProvider,
    );
    void relire() => ref.invalidate(revenusEnseignantProvider);
    // Sans reseau, un echec se dit « hors ligne » (comme la Vue globale de
    // la direction) ; une capacite absente reste dite indisponible.
    final Object? erreur = revenus.hasError ? revenus.error : null;
    final bool echecHorsLigne =
        erreur != null &&
        erreur is! CapaciteIndisponible &&
        (ref.watch(horsLigneProvider).value ?? false);
    // Le choix du mois : seulement quand la source rend ses mois ; il reste
    // en place pendant la lecture d'un autre mois, et sur un mois vide.
    final List<DateTime> mois =
        ref.watch(moisRevenusDisponiblesProvider).value ?? const <DateTime>[];
    return PageShell(
      titre: t.enseignant.revenus.titre,
      // « du mois choisi » seulement quand un choix existe : sans mois rendus
      // (production), l'estimation est celle du mois en cours.
      entete: Text(
        mois.isEmpty
            ? t.enseignant.revenus.introSansChoix
            : t.enseignant.revenus.intro,
      ),
      onRetour: onRetour ?? () => _retour(context),
      child: echecHorsLigne
          ? EtatSysteme.sansDonnees(
              quoi: t.sansDonnees.revenus,
              onAction: relire,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (mois.isNotEmpty) ...<Widget>[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SelecteurMois(
                      key: selecteurMoisKey,
                      mois: mois,
                      choisi: ref.watch(moisRevenusProvider),
                      onChoix: ref.read(moisRevenusProvider.notifier).choisir,
                    ),
                  ),
                  Ecart.vLg,
                ],
                BlocAsynchrone<RevenusEnseignant>(
                  valeur: revenus,
                  squelette: const Skeleton.liste(lignes: 6),
                  onReessayer: relire,
                  // Lot F1 : sans source (production), la page dit que
                  // l'academie n'a encore rien publie, jamais un chiffre.
                  erreurVersEtat: (Object erreur, VoidCallback? _) =>
                      erreur is CapaciteIndisponible
                      ? EtatSysteme(
                          key: indisponibleKey,
                          nature: NatureEtat.indisponible,
                          titre: t.enseignant.revenus.indisponibleTitre,
                          phrase: t.enseignant.revenus.indisponiblePhrase,
                          dependance: erreur.dependance,
                        )
                      : null,
                  estVide: (RevenusEnseignant r) =>
                      r.classes.isEmpty && r.seances.isEmpty,
                  vide: EmptyState(
                    message: t.enseignant.revenus.vide,
                    invitation: t.enseignant.revenus.videDetail,
                    icone: AppIcons.finance,
                    registre: RegistreVide.subi,
                  ),
                  construire: (RevenusEnseignant r) => _Corps(revenus: r),
                ),
              ],
            ),
    );
  }

  /// La cle du choix du mois.
  static const Key selecteurMoisKey = ValueKey<String>('fi-revenus-mois');

  /// La cle de la ligne des heures assurees du mois.
  static const Key heuresKey = ValueKey<String>('fi-revenus-heures');

  /// La cle de la ligne du jour de paie.
  static const Key versementKey = ValueKey<String>('fi-revenus-versement');

  /// La cle de l'etat « pas encore publies » (production, lot F1).
  static const Key indisponibleKey = ValueKey<String>(
    'fi-revenus-indisponible',
  );

  static void _retour(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.enseignantProfil);
    }
  }
}

/// Le corps : une colonne sur telephone, deux sur bureau.
class _Corps extends StatelessWidget {
  const _Corps({required this.revenus});

  final RevenusEnseignant revenus;

  @override
  Widget build(BuildContext context) {
    final Widget principal = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Resume(revenus: revenus),
        Ecart.vSection,
        SectionHeader(titre: t.enseignant.revenus.detailSection),
        Ecart.vSm,
        KeyedSubtree(
          key: const ValueKey<String>('revenus-detail'),
          child: AppGabarit.de(context) == Gabarit.desktop
              ? _TableauClasses(revenus: revenus)
              : _DetailClasses(classes: revenus.classes),
        ),
        Ecart.vSection,
        SectionHeader(titre: t.enseignant.revenus.seancesSection),
        Text(
          t.enseignant.revenus.seancesDetail,
          style: AppPalette.of(context).inkMuted.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        KeyedSubtree(
          key: const ValueKey<String>('revenus-seances'),
          child: _Seances(seances: revenus.seances),
        ),
      ],
    );
    final Widget annexe = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: t.enseignant.revenus.calculSection),
        const _Calcul(),
        Ecart.vSection,
        SectionHeader(titre: t.enseignant.revenus.internetSection),
        _Internet(allocation: revenus.allocationInternet),
        Ecart.vSection,
        SectionHeader(titre: t.enseignant.revenus.releveSection),
        const _Releve(),
      ],
    );
    // [RESPONSIVE] Le gabarit decide, jamais une largeur comparee a un nombre.
    if (AppGabarit.de(context) == Gabarit.desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(flex: 3, child: principal),
          const SizedBox(width: AppSpacing.section),
          Expanded(flex: 2, child: annexe),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[principal, Ecart.vSection, annexe],
    );
  }
}

/// Une duree en minutes, en heures lisibles : « 8 h », « 7 h 30 ».
String _duree(int minutes) {
  final int heures = minutes ~/ 60;
  final int reste = minutes % 60;
  if (heures == 0) {
    return LibellesGroupe.insecable(
      t.enseignant.revenus.minutes(minutes: minutes),
    );
  }
  return reste == 0
      ? LibellesGroupe.insecable(t.enseignant.revenus.heures(heures: heures))
      : LibellesGroupe.insecable(
          t.enseignant.revenus.heuresMinutes(
            heures: heures,
            minutes: reste.toString().padLeft(2, '0'),
          ),
        );
}

/// Le resume : « Estimation », la periode, le total estime, les heures
/// assurees, le nombre de Classes et le taux horaire moyen, puis la mention
/// qui dit que le releve de l'academie fait foi.
class _Resume extends StatelessWidget {
  const _Resume({required this.revenus});

  final RevenusEnseignant revenus;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    return AppCard(
      dominante: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              StatusPill(
                libelle: t.enseignant.revenus.estimation,
                ton: TonEtat.accent,
              ),
              Text(
                t.enseignant.revenus.periode(
                  mois: t.commun.dates.mois[revenus.debut.month - 1],
                  annee: revenus.debut.year,
                ),
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ],
          ),
          Ecart.vMd,
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  t.enseignant.revenus.totalEstime,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
                MontantArgent(revenus.totalEstime, taille: TailleMontant.grand),
                Text(t.enseignant.revenus.totalDetail, style: attenue),
              ],
            ),
          ),
          Ecart.vMd,
          LigneCleValeur(
            key: RevenusEnseignantPage.heuresKey,
            cle: t.enseignant.revenus.heuresAssurees,
            detailCle: t.enseignant.revenus.heuresAssureesDetail,
            valeur: _duree(revenus.total.minutesAssurees),
            chiffres: true,
            valeurForte: true,
            valeurEnFin: true,
          ),
          if (revenus.versement case final FenetreVersement v)
            LigneCleValeur(
              key: RevenusEnseignantPage.versementKey,
              cle: t.enseignant.revenus.versement,
              detailCle: t.enseignant.revenus.versementDetail(
                mois: t.commun.dates.mois[revenus.debut.month - 1],
              ),
              valeur: t.enseignant.revenus.versementValeur(
                du: _jourMois(v.du),
                au: _jourMois(v.au),
              ),
              valeurEnFin: true,
            ),
          LigneCleValeur(
            cle: t.enseignant.revenus.classesActives,
            valeur: '${revenus.classes.length}',
            chiffres: true,
            valeurEnFin: true,
          ),
          LigneCleValeur(
            cle: t.enseignant.revenus.tauxMoyen,
            valeur: t.enseignant.revenus.tauxValeur(
              montant: formaterMontant(revenus.total.tauxHoraireMoyen),
            ),
            chiffres: true,
            valeurEnFin: true,
          ),
          Ecart.vMd,
          Text(t.enseignant.revenus.mention, style: attenue),
        ],
      ),
    );
  }
}

/// « 1er decembre », « 10 decembre ».
String _jourMois(DateTime d) => LibellesGroupe.insecable(
  t.enseignant.revenus.jourMois(
    jour: d.day == 1 ? t.commun.dates.premierJour : '${d.day}',
    mois: t.commun.dates.mois[d.month - 1],
  ),
);

/// Ce que chaque seance a rapporte, une section par seance dans une seule
/// carte (contenus lies, K-55) : chaque eleve inscrit, present ou absent, et
/// sa part, rendue par le serveur ; puis le total de la seance, ou pourquoi
/// le versement attend. Aucune addition ici.
class _Seances extends StatelessWidget {
  const _Seances({required this.seances});

  final List<RevenusSeance> seances;

  @override
  Widget build(BuildContext context) {
    if (seances.isEmpty) {
      final AppPalette palette = AppPalette.of(context);
      return AppCard(
        child: Text(
          t.enseignant.revenus.seancesVide,
          style: palette.inkMuted.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
      );
    }
    return CarteGroupee(
      sections: <Widget>[
        for (final RevenusSeance s in seances) _SectionSeance(seance: s),
      ],
    );
  }
}

class _SectionSeance extends StatelessWidget {
  const _SectionSeance({required this.seance});

  final RevenusSeance seance;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final r = t.enseignant.revenus;
    final DateTime d = seance.debut;
    final String heure =
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
    final Montant? total = seance.montant;
    return Column(
      key: ValueKey<String>('revenus-seance-${seance.seanceId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          r.seanceTitre(nom: seance.classe, date: _jourMois(d), heure: heure),
          style: palette.inkStrong.applyTo(
            textes.titleMedium ?? const TextStyle(),
          ),
        ),
        if (seance.enRemplacement || seance.attente != null) ...<Widget>[
          Ecart.vXs,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              if (seance.enRemplacement)
                StatusPill(libelle: r.remplacement, ton: TonEtat.neutre),
              if (seance.attente case final AttenteVersement a)
                StatusPill(
                  libelle: switch (a) {
                    AttenteVersement.cahier => r.attenteCahier,
                    AttenteVersement.direction => r.attenteDirection,
                  },
                  ton: TonEtat.avertissement,
                ),
            ],
          ),
        ],
        Ecart.vSm,
        LigneCleValeur(
          cle: r.seanceDuree,
          valeur: _duree(seance.minutes),
          chiffres: true,
          valeurEnFin: true,
        ),
        for (final RevenusEleveSeance e in seance.eleves)
          if (e.montant case final Montant m)
            LigneFinance(
              key: ValueKey<String>(
                'revenus-eleve-${seance.seanceId}-${e.eleveId}',
              ),
              libelle: e.prenom,
              detail: e.present ? r.present : r.absent,
              montant: m,
            )
          else
            LigneCleValeur(
              key: ValueKey<String>(
                'revenus-eleve-${seance.seanceId}-${e.eleveId}',
              ),
              cle: e.prenom,
              valeur: e.present ? r.present : r.absent,
              valeurEnFin: true,
            ),
        if (total != null)
          LigneFinance(libelle: r.montantSeance, montant: total, total: true),
        if (seance.attente case final AttenteVersement a) ...<Widget>[
          Ecart.vXs,
          Text(
            switch (a) {
              AttenteVersement.cahier => r.attenteCahierDetail,
              AttenteVersement.direction => r.attenteDirectionDetail,
            },
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );
  }
}

/// Le detail par Classe, une section par Classe dans une seule carte : les
/// lignes sont liees (une meme estimation), jamais des cartes collees (K-55).
class _DetailClasses extends StatelessWidget {
  const _DetailClasses({required this.classes});

  final List<RevenusClasse> classes;

  @override
  Widget build(BuildContext context) => CarteGroupee(
    sections: <Widget>[
      for (final RevenusClasse c in classes) _SectionClasse(classe: c),
    ],
  );
}

class _SectionClasse extends StatelessWidget {
  const _SectionClasse({required this.classe});

  final RevenusClasse classe;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      key: ValueKey<String>('revenus-classe-${classe.classeId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          t.enseignant.revenus.classe(nom: classe.classe),
          style: palette.inkStrong.applyTo(
            textes.titleMedium ?? const TextStyle(),
          ),
        ),
        if (classe.enRemplacement) ...<Widget>[
          Ecart.vXs,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: StatusPill(
              libelle: t.enseignant.revenus.remplacement,
              ton: TonEtat.neutre,
            ),
          ),
        ],
        Ecart.vSm,
        LigneCleValeur(
          cle: t.enseignant.revenus.type,
          valeur: _type(classe.type),
          valeurEnFin: true,
        ),
        LigneCleValeur(
          cle: t.enseignant.revenus.heuresAssurees,
          valeur: _duree(classe.minutesAssurees),
          chiffres: true,
          valeurEnFin: true,
        ),
        LigneCleValeur(
          cle: t.enseignant.revenus.capacite,
          valeur: t.enseignant.revenus.capaciteValeur(nombre: classe.capacite),
          chiffres: true,
          valeurEnFin: true,
        ),
        // REVENUS-VERITE (06/11/2026) : plus de « sieges eligibles ». Ce
        // nombre comptait les absents, alors que seul un eleve present est
        // paye (DECISION-TARIFS, paie du 19/10).
        LigneCleValeur(
          cle: t.enseignant.revenus.taux,
          valeur: t.enseignant.revenus.tauxValeur(
            montant: formaterMontant(classe.tauxHoraireEffectif),
          ),
          chiffres: true,
          valeurEnFin: true,
        ),
        LigneFinance(
          libelle: t.enseignant.revenus.montantClasse,
          montant: classe.montantEstime,
          total: true,
        ),
      ],
    );
  }
}

/// Le nom du type d'une Classe.
String _type(TypeClasseRevenus type) => switch (type) {
  TypeClasseRevenus.enfants => t.enseignant.revenus.typeEnfants,
  TypeClasseRevenus.debutants => t.enseignant.revenus.typeDebutants,
  TypeClasseRevenus.adultes => t.enseignant.revenus.typeAdultes,
};

/// Le detail par Classe en tableau compact, sur bureau (revue 11 e) : une
/// ligne par Classe et la ligne de total rendue par le port. Les memes
/// colonnes que les lignes groupees du telephone.
///
/// Un mot n'est jamais coupe dans une cellule (K-54, K-61) : quand le plus
/// long mot d'une colonne (en-tete, valeur ou pastille « Remplacement ») ne
/// tient pas dans sa largeur, au texte agrandi par exemple, le detail passe
/// aux lignes groupees du telephone, qui gardent les memes valeurs.
class _TableauClasses extends StatelessWidget {
  const _TableauClasses({required this.revenus});

  final RevenusEnseignant revenus;

  /// La part de largeur de chaque colonne, dans l'ordre d'affichage.
  static const List<int> _parts = <int>[4, 3, 2, 2, 2, 3];

  /// Ce que la pastille ajoute a son libelle : ses marges, son disque et
  /// l'ecart qui le suit (voir [StatusPill]).
  static const double _cadrePastille =
      2 * AppSpacing.md + StatusPill.diametrePastille + AppSpacing.sm;

  /// La largeur du plus long mot de [texte], a l'echelle de l'appareil.
  static double _plusLongMot(
    String texte,
    TextStyle style,
    TextScaler echelle,
    TextDirection sens,
  ) {
    double plusLong = 0;
    for (final String mot in texte.split(RegExp(r'\s+'))) {
      if (mot.isEmpty) continue;
      final TextPainter peintre = TextPainter(
        text: TextSpan(text: mot, style: style),
        textDirection: sens,
        textScaler: echelle,
        maxLines: 1,
      )..layout();
      if (peintre.width > plusLong) plusLong = peintre.width;
      peintre.dispose();
    }
    return plusLong;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints contraintes) =>
        _tient(context, contraintes.maxWidth)
        ? _tableau(context)
        : _DetailClasses(classes: revenus.classes),
  );

  /// Les styles du tableau : cellule, en-tete, total.
  static (TextStyle, TextStyle, TextStyle) _styles(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle defaut = DefaultTextStyle.of(context).style;
    return (
      defaut.merge(
        AppTypography.tabulaire(
          palette.inkStrong.applyTo(textes.bodySmall ?? const TextStyle()),
        ),
      ),
      defaut.merge(
        palette.inkMuted.applyTo(textes.labelMedium ?? const TextStyle()),
      ),
      defaut.merge(
        AppTypography.tabulaire(
          palette.inkStrong.applyTo(textes.labelMedium ?? const TextStyle()),
        ),
      ),
    );
  }

  /// Les textes de chaque colonne, en-tete et total compris.
  List<List<String>> _colonnes() {
    final r = t.enseignant.revenus;
    final TotalRevenus total = revenus.total;
    return <List<String>>[
      <String>[
        r.classeColonne,
        r.total,
        for (final RevenusClasse c in revenus.classes) r.classe(nom: c.classe),
      ],
      <String>[
        r.type,
        for (final RevenusClasse c in revenus.classes) _type(c.type),
      ],
      <String>[
        r.capacite,
        '${total.capacite}',
        for (final RevenusClasse c in revenus.classes) '${c.capacite}',
      ],
      <String>[
        r.heuresAssurees,
        _duree(total.minutesAssurees),
        for (final RevenusClasse c in revenus.classes)
          _duree(c.minutesAssurees),
      ],
      <String>[
        r.tauxColonne,
        formaterMontant(total.tauxHoraireMoyen),
        for (final RevenusClasse c in revenus.classes)
          formaterMontant(c.tauxHoraireEffectif),
      ],
      <String>[
        r.montantClasse,
        formaterMontant(revenus.totalEstime),
        for (final RevenusClasse c in revenus.classes)
          formaterMontant(c.montantEstime),
      ],
    ];
  }

  /// Vrai quand chaque mot de chaque colonne tient dans sa largeur, a
  /// l'echelle de texte de l'appareil, dans un tableau large de [largeur].
  bool _tient(BuildContext context, double largeur) {
    if (!largeur.isFinite) return false;
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    final TextDirection sens = Directionality.of(context);
    final (TextStyle base, TextStyle entete, TextStyle fort) = _styles(context);
    final TextStyle pastille = DefaultTextStyle.of(context).style
        .merge(Theme.of(context).textTheme.labelMedium);
    final int somme = _parts.fold(0, (int a, int b) => a + b);
    final double utile = largeur - 2 * AppSpacing.lg;
    final List<List<String>> colonnes = _colonnes();
    for (int i = 0; i < colonnes.length; i++) {
      final double place = utile * _parts[i] / somme - AppSpacing.sm;
      final List<String> textes = colonnes[i];
      // En-tete, total puis cellules : le plus large des trois styles.
      for (int j = 0; j < textes.length; j++) {
        final TextStyle style = j == 0 ? entete : (j == 1 ? fort : base);
        if (_plusLongMot(textes[j], style, echelle, sens) > place) {
          return false;
        }
      }
    }
    final bool avecPastille = revenus.classes.any(
      (RevenusClasse c) => c.enRemplacement,
    );
    if (avecPastille) {
      final double place = utile * _parts[0] / somme - AppSpacing.sm;
      final double libelle = _plusLongMot(
        t.enseignant.revenus.remplacement,
        pastille,
        echelle,
        sens,
      );
      if (libelle + _cadrePastille > place) return false;
    }
    return true;
  }

  Widget _tableau(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final (TextStyle base, TextStyle entete, TextStyle fort) = _styles(context);
    final r = t.enseignant.revenus;
    final List<String> titres = <String>[
      r.classeColonne,
      r.type,
      r.capacite,
      r.heuresAssurees,
      r.tauxColonne,
      r.montantClasse,
    ];
    final TotalRevenus total = revenus.total;
    return DecoratedBox(
      key: const ValueKey<String>('revenus-tableau'),
      decoration: palette.surfaceRaised.decoration(
        borderRadius: metriques.arrondi,
        side: palette.borderHairline.asBorderSide(),
      ),
      child: ClipRRect(
        borderRadius: metriques.arrondi,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Les en-tetes sont exclus de l'arbre semantique : chaque cellule
            // porte deja le titre de sa colonne dans son libelle parle.
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surfaceSunken.background,
                border: Border(bottom: palette.borderHairline.asBorderSide()),
              ),
              child: ExcludeSemantics(
                child: _Rangee(
                  parts: _parts,
                  cellules: <Widget>[
                    for (final String titre in titres)
                      Text(titre, style: entete),
                  ],
                ),
              ),
            ),
            for (final RevenusClasse c in revenus.classes)
              DecoratedBox(
                key: ValueKey<String>('revenus-classe-${c.classeId}'),
                decoration: BoxDecoration(
                  border: Border(bottom: palette.borderHairline.asBorderSide()),
                ),
                child: _Rangee(
                  parts: _parts,
                  cellules: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _Cellule(
                          titre: titres[0],
                          texte: r.classe(nom: c.classe),
                          style: base,
                        ),
                        if (c.enRemplacement) ...<Widget>[
                          Ecart.vXs,
                          StatusPill(
                            libelle: r.remplacement,
                            ton: TonEtat.neutre,
                          ),
                        ],
                      ],
                    ),
                    _Cellule(
                      titre: titres[1],
                      texte: _type(c.type),
                      style: base,
                    ),
                    _Cellule(
                      titre: titres[2],
                      texte: '${c.capacite}',
                      style: base,
                    ),
                    _Cellule(
                      titre: titres[3],
                      texte: _duree(c.minutesAssurees),
                      style: base,
                    ),
                    _Cellule(
                      titre: titres[4],
                      texte: formaterMontant(c.tauxHoraireEffectif),
                      style: base,
                    ),
                    _Cellule(
                      titre: titres[5],
                      texte: formaterMontant(c.montantEstime),
                      style: base,
                    ),
                  ],
                ),
              ),
            DecoratedBox(
              key: const ValueKey<String>('revenus-total'),
              decoration: BoxDecoration(
                color: palette.surfaceSunken.background,
              ),
              child: _Rangee(
                parts: _parts,
                cellules: <Widget>[
                  Text(r.total, style: fort),
                  const SizedBox.shrink(),
                  _Cellule(
                    titre: titres[2],
                    texte: '${total.capacite}',
                    style: fort,
                  ),
                  _Cellule(
                    titre: titres[3],
                    texte: _duree(total.minutesAssurees),
                    style: fort,
                  ),
                  _Cellule(
                    titre: r.tauxMoyen,
                    texte: formaterMontant(total.tauxHoraireMoyen),
                    style: fort,
                  ),
                  _Cellule(
                    titre: titres[5],
                    texte: formaterMontant(revenus.totalEstime),
                    style: fort,
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

/// Une rangee du tableau : des cellules aux parts de largeur [parts].
class _Rangee extends StatelessWidget {
  const _Rangee({required this.parts, required this.cellules});

  final List<int> parts;
  final List<Widget> cellules;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < cellules.length; i++)
          Expanded(
            flex: parts[i],
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: cellules[i],
            ),
          ),
      ],
    ),
  );
}

/// Une cellule, avec le titre de sa colonne dans son libelle parle : sans
/// lui, un lecteur d'ecran enoncerait des valeurs sans dire de quoi.
class _Cellule extends StatelessWidget {
  const _Cellule({
    required this.titre,
    required this.texte,
    required this.style,
  });

  final String titre;
  final String texte;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$titre : $texte',
    excludeSemantics: true,
    child: Text(texte, style: style),
  );
}

/// Le releve des mois arretes par l'academie (guide §4, revue 11 g), lu au
/// port. Indisponible tant que le serveur ne le rend pas (FI-BR-11) : la
/// section le dit, sans « Reessayer » ; jamais un statut « paye ».
class _Releve extends ConsumerWidget {
  const _Releve();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LigneReleve>> releve = ref.watch(
      releveEnseignantProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    void relire() => ref.invalidate(releveEnseignantProvider);
    final r = t.enseignant.revenus;
    return BlocAsynchrone<List<LigneReleve>>(
      valeur: releve,
      squelette: const Skeleton.liste(lignes: 2),
      onReessayer: relire,
      erreurVersEtat: (Object erreur, VoidCallback? reessayer) {
        if (erreur is CapaciteIndisponible) {
          return EtatSysteme(
            nature: NatureEtat.indisponible,
            titre: r.releveIndisponibleTitre,
            phrase: r.releveIndisponiblePhrase,
          );
        }
        return horsLigne
            ? EtatSysteme.sansDonnees(
                quoi: t.sansDonnees.revenus,
                onAction: reessayer,
              )
            : null;
      },
      vide: EmptyState(
        message: r.releveVide,
        invitation: r.releveVideDetail,
        icone: AppIcons.finance,
        registre: RegistreVide.subi,
      ),
      construire: (List<LigneReleve> lignes) => CarteGroupee(
        sections: <Widget>[
          for (final LigneReleve l in lignes)
            LigneFinance(
              libelle: r.periode(
                mois: t.commun.dates.mois[l.mois.month - 1],
                annee: l.mois.year,
              ),
              detail: _duree(l.minutesAssurees),
              montant: l.montant,
            ),
        ],
      ),
    );
  }
}

/// La regle de la paie, en mots simples (REVENUS-VERITE, 06/11/2026 ;
/// DECISION-TARIFS-2026-10-18, paie revue le 19/10) : payee a chaque seance,
/// par eleve present et a l'heure ; un absent n'est jamais paye ; aucun
/// minimum. Aucun montant ici : les montants du mois viennent du serveur, et
/// aucune valeur de reference n'est ecrite dans l'application.
class _Calcul extends StatelessWidget {
  const _Calcul();

  @override
  Widget build(BuildContext context) => CarteGroupee(
    sections: <Widget>[
      _Etape(
        titre: t.commun.paieEnseignant.present,
        detail: t.commun.paieEnseignant.presentDetail,
      ),
      _Etape(
        titre: t.commun.paieEnseignant.absent,
        detail: t.commun.paieEnseignant.absentDetail,
      ),
      _Etape(
        titre: t.commun.paieEnseignant.minimum,
        detail: t.commun.paieEnseignant.minimumDetail,
      ),
    ],
  );
}

class _Etape extends StatelessWidget {
  const _Etape({required this.titre, required this.detail});

  final String titre;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            titre,
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          Text(
            detail,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

/// L'aide Internet, a part de la remuneration pedagogique (guide §1.4) : une
/// seule par enseignant eligible, jamais multipliee par Classe. Sans montant,
/// un libelle neutre : le contrat ne distingue pas « non eligible » de
/// « montant non fixe par la politique », l'ecran ne tranche donc pas.
class _Internet extends StatelessWidget {
  const _Internet({required this.allocation});

  final Montant? allocation;

  @override
  Widget build(BuildContext context) {
    final Montant? montant = allocation;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return AppCard(
      child: montant == null
          ? Text(
              t.enseignant.revenus.internetAucune,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            )
          : LigneFinance(
              libelle: t.enseignant.revenus.internet,
              detail: t.enseignant.revenus.internetDetail,
              montant: montant,
            ),
    );
  }
}
