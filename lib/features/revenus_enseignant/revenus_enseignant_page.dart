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
import '../../core/capacites/port_autres_revenus.dart';
import '../../core/capacites/port_revenus_enseignant.dart';
import '../../core/finance/format_montant.dart';
import '../../core/finance/montant.dart';
import '../../core/i18n/isolat_bidi.dart' show enTeteArabe;
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/mouvement/mouvement.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/ligne_finance.dart';
import '../../core/widgets/montant_argent.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pressable.dart';
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
    // HEURES-PROFIL H1 (12/11/2026) : la page ecoute le fuseau du profil ;
    // quand il arrive apres son premier rendu, ses heures se redessinent.
    ref.watch(monHorlogeProvider);
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

  /// La cle de la ligne des autres revenus du resume.
  static const Key autresKey = ValueKey<String>('fi-revenus-autres');

  /// La cle de la ligne du jour de paie.
  static const Key versementKey = ValueKey<String>('fi-revenus-versement');

  /// La cle de la ligne « En attente du cahier de transmission ».
  static const Key attenteCahierKey = ValueKey<String>(
    'fi-revenus-attente-cahier',
  );

  /// La cle du titre « Comment c'est calcule », qui deplie la regle.
  static const Key calculKey = ValueKey<String>('fi-revenus-calcul');

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
        SectionHeader(titre: t.enseignant.revenus.classesSection),
        Text(
          t.enseignant.revenus.classesDetail,
          style: AppPalette.of(context).inkMuted.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        KeyedSubtree(
          key: const ValueKey<String>('revenus-detail'),
          child: _ListeClasses(revenus: revenus),
        ),
      ],
    );
    final Widget annexe = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _CalculRepliable(),
        Ecart.vSection,
        SectionHeader(titre: t.enseignant.revenus.autresSection),
        _Autres(revenus: revenus),
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
    final Montant? aRecevoir = revenus.totalARecevoir;
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
                // REVENUS (07/11/2026, garde-cap) : le total « a recevoir »
                // ne compte que les montants des seances sans attente ; un
                // serveur plus ancien ne le rend pas, l'estimation reste.
                Text(
                  aRecevoir == null
                      ? t.enseignant.revenus.totalEstime
                      : t.enseignant.revenus.aRecevoir,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
                MontantArgent(
                  aRecevoir ?? revenus.totalEstime,
                  taille: TailleMontant.grand,
                ),
                Text(
                  aRecevoir == null
                      ? t.enseignant.revenus.totalDetail
                      : t.enseignant.revenus.aRecevoirDetail,
                  style: attenue,
                ),
              ],
            ),
          ),
          // Ce qui attend le cahier : affiche, mais a part du total.
          if (revenus.totalAttenteCahier case final Montant cahier
              when cahier.mineur > 0) ...<Widget>[
            Ecart.vSm,
            Text(
              t.enseignant.revenus.attenteCahierTotal(
                montant: formaterMontant(cahier),
              ),
              key: RevenusEnseignantPage.attenteCahierKey,
              style: palette.inkStrong.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ],
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
          // REVENUS-DUREE-PAYEE : des seances comptees faute de mieux au
          // temps de connexion : dit, jamais une duree inventee.
          if (revenus.seancesSansDureePayee case final int n
              when n > 0) ...<Widget>[
            Ecart.vXs,
            Text(
              t.enseignant.revenus.sansDureePayee(n: n),
              key: const ValueKey<String>('revenus-sans-duree-payee'),
              style: attenue,
            ),
          ],
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
          if (revenus.totalAutres case final Montant autres
              when revenus.autres.isNotEmpty)
            LigneCleValeur(
              key: RevenusEnseignantPage.autresKey,
              cle: t.enseignant.revenus.autresResume,
              valeur: formaterMontant(autres),
              chiffres: true,
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
  enTeteArabe(
    t.enseignant.revenus.jourMois(
      jour: d.day == 1 ? t.commun.dates.premierJour : '${d.day}',
      mois: t.commun.dates.mois[d.month - 1],
    ),
  ),
);

/// Les Classes du mois, une ligne par Classe dans une seule carte (contenus
/// lies, K-55) : son nom, ses heures, ses seances et son montant. Toucher une
/// ligne deplie, dans la page, ses seances et ce que chaque eleve a rapporte
/// (REVENUS, 07/11/2026). Une seule barre de defilement, celle de la page
/// (DECISION-DEFILEMENT-2026-11-01) : le detail s'ouvre en place, jamais dans
/// un cadre qui defile.
class _ListeClasses extends StatelessWidget {
  const _ListeClasses({required this.revenus});

  final RevenusEnseignant revenus;

  @override
  Widget build(BuildContext context) {
    // Les seances de chaque Classe, dans l'ordre rendu par le serveur (la
    // plus recente d'abord). Une Classe sans ligne de synthese (rien ne
    // devrait l'en priver) garde quand meme ses seances.
    final Map<String, List<RevenusSeance>> parClasse =
        <String, List<RevenusSeance>>{};
    for (final RevenusSeance s in revenus.seances) {
      parClasse.putIfAbsent(s.classeId, () => <RevenusSeance>[]).add(s);
    }
    final Set<String> connues = <String>{
      for (final RevenusClasse c in revenus.classes) c.classeId,
    };
    return CarteGroupee(
      sections: <Widget>[
        for (final RevenusClasse c in revenus.classes)
          _LigneClasse(
            key: ValueKey<String>('revenus-classe-${c.classeId}'),
            classe: c,
            seances: parClasse[c.classeId] ?? const <RevenusSeance>[],
          ),
        for (final MapEntry<String, List<RevenusSeance>> e in parClasse.entries)
          if (!connues.contains(e.key))
            _LigneClasse(
              key: ValueKey<String>('revenus-classe-${e.key}'),
              seances: e.value,
            ),
      ],
    );
  }
}

/// Une Classe : la ligne qui se touche, puis, depliees, ses seances.
class _LigneClasse extends StatefulWidget {
  const _LigneClasse({required this.seances, super.key, this.classe});

  /// La synthese du serveur ; nulle pour une Classe qui n'a que des seances.
  final RevenusClasse? classe;

  final List<RevenusSeance> seances;

  @override
  State<_LigneClasse> createState() => _LigneClasseState();
}

class _LigneClasseState extends State<_LigneClasse> {
  bool _deplie = false;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final r = t.enseignant.revenus;
    final RevenusClasse? c = widget.classe;
    final String nom = c?.classe ?? widget.seances.first.classe;
    final bool remplacement =
        c?.enRemplacement ??
        widget.seances.any((RevenusSeance s) => s.enRemplacement);
    final String resume = <String>[
      if (c != null) _duree(c.minutesAssurees),
      r.nombreSeances(n: widget.seances.length),
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Pressable, jamais un onTap nu : bouton, focus et libelle lu ;
        // l'etat deplie reste annonce.
        Semantics(
          button: true,
          expanded: _deplie,
          child: Pressable(
            onPress: () => setState(() => _deplie = !_deplie),
            arrondiFocus: BorderRadius.circular(AppSpacing.sm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          r.classe(nom: nom),
                          style: palette.inkStrong.applyTo(
                            textes.titleMedium ?? const TextStyle(),
                          ),
                        ),
                        Ecart.vXs,
                        Text(
                          resume,
                          style: palette.inkMuted.applyTo(
                            textes.bodyMedium ?? const TextStyle(),
                          ),
                        ),
                        // Le montant sous le nom, jamais a cote : a 320 px
                        // et texte a 200 %, le nom garde toute la largeur
                        // et aucun mot n'est coupe (K-54, K-61).
                        if (c != null) ...<Widget>[
                          Ecart.vXs,
                          // A recevoir, hors attentes : la somme des lignes
                          // vaut le total du resume (REVENUS, 07/11/2026).
                          MontantArgent(c.montantARecevoir ?? c.montantEstime),
                        ],
                        if (remplacement) ...<Widget>[
                          Ecart.vXs,
                          StatusPill(
                            libelle: r.remplacement,
                            ton: TonEtat.neutre,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AnimatedRotation(
                    // Le chevron pointe vers la fin ; deplie, il pointe vers
                    // le bas : quart de tour horaire en francais, antihoraire
                    // en arabe (sinon il pointerait vers le haut).
                    turns: _deplie
                        ? (Directionality.of(context) == TextDirection.rtl
                              ? -0.25
                              : 0.25)
                        : 0,
                    duration: Mouvement.duree(context, Mouvement.court),
                    curve: Mouvement.entree,
                    child: IconTheme(
                      data: palette.inkMuted.asIconTheme(size: 20),
                      child: Icon(AppIcons.chevron.resoudre()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: Mouvement.duree(context, Mouvement.moyen),
          curve: Mouvement.entree,
          alignment: AlignmentDirectional.topStart,
          child: !_deplie
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: _DetailClasse(classe: c, seances: widget.seances),
                ),
        ),
      ],
    );
  }
}

/// Le detail d'une Classe deplie : son type et son taux, puis chaque seance.
class _DetailClasse extends StatelessWidget {
  const _DetailClasse({required this.classe, required this.seances});

  final RevenusClasse? classe;
  final List<RevenusSeance> seances;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.enseignant.revenus;
    final RevenusClasse? c = classe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (c != null) ...<Widget>[
          LigneCleValeur(cle: r.type, valeur: _type(c.type), valeurEnFin: true),
          LigneCleValeur(
            cle: r.capacite,
            valeur: r.capaciteValeur(nombre: c.capacite),
            chiffres: true,
            valeurEnFin: true,
          ),
          LigneCleValeur(
            cle: r.taux,
            valeur: r.tauxValeur(
              montant: formaterMontant(c.tauxHoraireEffectif),
            ),
            chiffres: true,
            valeurEnFin: true,
          ),
        ],
        if (seances.isEmpty)
          Text(
            r.seancesVide,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        for (final RevenusSeance s in seances) ...<Widget>[
          Ecart.vMd,
          _SectionSeance(seance: s),
        ],
      ],
    );
  }
}

/// Une seance : sa date, sa duree, chaque eleve present, present en partie ou
/// absent, et sa part rendue par le serveur ; puis le total de la seance, ou
/// pourquoi le versement attend. Une seance non payee (aucun eleve present)
/// n'affiche aucun montant : ni « 0 », ni tiret, une phrase. Aucune addition
/// ici.
class _SectionSeance extends StatelessWidget {
  const _SectionSeance({required this.seance});

  final RevenusSeance seance;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final r = t.enseignant.revenus;
    // HEURES-PROFIL H1 : jour et heure a l'heure du profil.
    final DateTime d = chezMoi(seance.debut);
    final String heure = heureChezMoi(seance.debut);
    // Revue du garde-cap (08/11/2026, option i) : le montant que le serveur
    // a ecrit ; nul ou absent, « aucun montant ».
    final bool aUnMontant = seance.aUnMontant;
    final Montant? total = aUnMontant ? seance.montant : null;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final bool partiel = seance.eleves.any(
      (RevenusEleveSeance e) => e.presence == PresenceRevenus.partielle,
    );
    return Column(
      key: ValueKey<String>('revenus-seance-${seance.seanceId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          r.seanceDate(date: _jourMois(d), heure: heure),
          style: palette.inkStrong.applyTo(
            textes.titleSmall ?? const TextStyle(),
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
        Ecart.vXs,
        // REVENUS-DUREE-PAYEE : la duree PAYEE dite par le serveur ; sans
        // elle, une phrase qui renvoie au releve de l'academie (jamais les
        // minutes connectees presentees comme payees). Les minutes
        // connectees dans la fenetre viennent en second.
        LigneCleValeur(
          key: ValueKey<String>('revenus-duree-payee-${seance.seanceId}'),
          cle: r.seanceDuree,
          valeur: seance.minutesPayees == null
              ? r.seanceDureeNonPrecisee
              : _duree(seance.minutesPayees!),
          chiffres: seance.minutesPayees != null,
          valeurEnFin: true,
        ),
        if (seance.minutesConnectees != null)
          LigneCleValeur(
            key: ValueKey<String>('revenus-connecte-${seance.seanceId}'),
            cle: r.seanceConnecte,
            valeur: _duree(seance.minutesConnectees!),
            chiffres: true,
            valeurEnFin: true,
          ),
        for (final RevenusEleveSeance e in seance.eleves)
          // Une part seulement quand la seance a un montant : un absent, ou
          // une seance sans montant, n'affiche aucun montant.
          if (aUnMontant &&
              e.presence != PresenceRevenus.absente &&
              e.montant != null)
            LigneFinance(
              key: ValueKey<String>(
                'revenus-eleve-${seance.seanceId}-${e.eleveId}',
              ),
              libelle: e.prenom,
              detail: _presence(e.presence),
              montant: e.montant!,
            )
          else
            LigneCleValeur(
              key: ValueKey<String>(
                'revenus-eleve-${seance.seanceId}-${e.eleveId}',
              ),
              cle: e.prenom,
              valeur: _presence(e.presence),
              valeurEnFin: true,
            ),
        if (total != null)
          LigneFinance(libelle: r.montantSeance, montant: total, total: true),
        if (seance.attente case final AttenteVersement a) ...<Widget>[
          Ecart.vXs,
          Text(switch (a) {
            AttenteVersement.cahier => r.attenteCahierDetail,
            AttenteVersement.direction => r.attenteDirectionDetail,
          }, style: attenue),
        ] else if (!aUnMontant) ...<Widget>[
          Ecart.vXs,
          Text(
            r.aucunMontant,
            key: ValueKey<String>('revenus-aucun-montant-${seance.seanceId}'),
            style: attenue,
          ),
        ],
        if (aUnMontant && partiel) ...<Widget>[
          Ecart.vXs,
          Text(r.partielleNote, style: attenue),
        ],
      ],
    );
  }
}

/// Le mot de la presence d'un eleve.
String _presence(PresenceRevenus p) => switch (p) {
  PresenceRevenus.presente => t.enseignant.revenus.present,
  PresenceRevenus.partielle => t.enseignant.revenus.presentPartiel,
  PresenceRevenus.absente => t.enseignant.revenus.absent,
};

/// Le nom du type d'une Classe.
String _type(TypeClasseRevenus type) => switch (type) {
  TypeClasseRevenus.enfants => t.enseignant.revenus.typeEnfants,
  TypeClasseRevenus.debutants => t.enseignant.revenus.typeDebutants,
  TypeClasseRevenus.adultes => t.enseignant.revenus.typeAdultes,
};

/// « Comment c'est calculé », replie par defaut (REVENUS, 07/11/2026) : la
/// regle reste dite en une phrase dans l'en-tete de la page ; le titre est le
/// bouton, l'etat deplie est annonce.
class _CalculRepliable extends StatefulWidget {
  const _CalculRepliable();

  @override
  State<_CalculRepliable> createState() => _CalculRepliableState();
}

class _CalculRepliableState extends State<_CalculRepliable> {
  bool _deplie = false;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          button: true,
          header: true,
          expanded: _deplie,
          child: Pressable(
            key: RevenusEnseignantPage.calculKey,
            onPress: () => setState(() => _deplie = !_deplie),
            arrondiFocus: BorderRadius.circular(AppSpacing.sm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      t.enseignant.revenus.calculSection,
                      style: palette.inkStrong.applyTo(
                        textes.titleMedium ?? const TextStyle(),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    // Le chevron pointe vers la fin ; deplie, il pointe vers
                    // le bas : quart de tour horaire en francais, antihoraire
                    // en arabe (sinon il pointerait vers le haut).
                    turns: _deplie
                        ? (Directionality.of(context) == TextDirection.rtl
                              ? -0.25
                              : 0.25)
                        : 0,
                    duration: Mouvement.duree(context, Mouvement.court),
                    curve: Mouvement.entree,
                    child: IconTheme(
                      data: palette.inkMuted.asIconTheme(size: 20),
                      child: Icon(AppIcons.chevron.resoudre()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: Mouvement.duree(context, Mouvement.moyen),
          curve: Mouvement.entree,
          alignment: AlignmentDirectional.topStart,
          child: !_deplie
              ? const SizedBox(width: double.infinity)
              : const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.sm),
                  child: _Calcul(),
                ),
        ),
      ],
    );
  }
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
      // REVENUS (07/11/2026) : la paie compte une presence partielle comme
      // une presence (`private.pai_eleves_presents`).
      _Etape(
        titre: t.enseignant.revenus.partielle,
        detail: t.enseignant.revenus.partielleDetail,
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

/// Les autres revenus du mois (REVENUS-VERITE point 5) : l'aide Internet, les
/// primes et les missions que la direction attribue, versees avec la paie,
/// a part de la remuneration pedagogique. Chaque ligne et le total viennent
/// du serveur ; rien n'est additionne ici.
class _Autres extends StatelessWidget {
  const _Autres({required this.revenus});

  final RevenusEnseignant revenus;

  /// La cle de la carte, pour les tests.
  static const Key cle = ValueKey<String>('revenus-autres');

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final r = t.enseignant.revenus;
    final Montant? total = revenus.totalAutres;
    if (revenus.autres.isEmpty) {
      return AppCard(
        key: cle,
        child: Text(
          r.autresVide,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
      );
    }
    return AppCard(
      key: cle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            r.autresDetail,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vSm,
          for (final AutreRevenu a in revenus.autres)
            LigneFinance(
              key: ValueKey<String>('revenus-autre-${a.id}'),
              libelle: a.libelle,
              detail: libelleNatureAutreRevenu(a.nature),
              montant: a.montant,
            ),
          if (total != null)
            LigneFinance(libelle: r.autresTotal, montant: total, total: true),
        ],
      ),
    );
  }
}
