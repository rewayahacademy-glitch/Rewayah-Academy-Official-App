import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../classes/carte_classe.dart';
import '../classes/domaine/classe_vm.dart';
import '../classes/domaine/conformite.dart';
import '../classes/domaine/erreur_domaine.dart';
import '../classes/domaine/providers.dart';
import '../classes/grille_classes.dart';
import '../classes/libelles_classes.dart';

/// Mes classes et Classes disponibles, cote enseignant.
///
/// **Avant la clearance operationnelle, l'enseignant reste dans son
/// onboarding.** Le contrat est obligatoire ; le KYC l'est par defaut, sauf
/// dispense explicite de l'academie. Tant que ces deux conditions ne sont pas
/// remplies, les Classes disponibles restent masquees : l'ecran le dit, avec
/// l'action qui debloque chaque etape, jamais un tableau vide.
///
/// Apres clearance, deux sections et rien d'autre : ce qui est a moi, ce qui
/// est ouvert. Le bouton d'une opportunite est « Candidater » ; l'academie
/// decide, et l'ecran ne fait pas semblant d'affecter.
///
/// La clearance est **projetee** depuis ce que le serveur rend : la barriere
/// reelle reste la RLS et les RPC d'eligibilite.
class ClassesEnseignantPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const ClassesEnseignantPage({super.key});

  @override
  ConsumerState<ClassesEnseignantPage> createState() =>
      _ClassesEnseignantPageEtat();
}

class _ClassesEnseignantPageEtat extends ConsumerState<ClassesEnseignantPage> {
  /// Les Classes ou une candidature vient de partir, pour que la carte le dise
  /// sans relire le serveur.
  final Set<String> _candidaturesEnvoyees = <String>{};

  /// La Classe dont la candidature est en vol.
  String? _enVol;

  /// Le retour local, succes ou echec, pose sous les cartes.
  String? _retour;

  Future<void> _candidater(ClasseVM classe) async {
    setState(() {
      _enVol = classe.id;
      _retour = null;
    });
    try {
      await ref.read(portMarketplaceProvider).candidater(classe.id);
      if (mounted) {
        setState(() {
          _candidaturesEnvoyees.add(classe.id);
          _retour = t.classes.enseignant.candidatureEnvoyee;
        });
      }
    } on Object catch (erreur) {
      // Le message humain, jamais l'erreur brute : c'est l'invariant de tout
      // le sprint, et `messageHumain` le tient.
      if (mounted) {
        setState(() => _retour = messageHumain(erreur));
      }
    } finally {
      if (mounted) {
        setState(() => _enVol = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ConformiteCompte> conformite = ref.watch(
      maConformiteProvider,
    );

    return PageShell(
      titre: t.classes.enseignant.titre,
      entete: Align(
        alignment: AlignmentDirectional.centerStart,
        child: ActionPrincipale(
          libelle: t.commun.retour,
          niveau: NiveauAction.tertiaire,
          pleineLargeur: false,
          onPress: () => GoRouter.of(context).go(Routes.enseignantJournee),
        ),
      ),
      child: switch (conformite) {
        // Les getters, jamais le type d'execution : Riverpod 3 relance un
        // provider en echec et repasse par `AsyncLoading` en conservant
        // `hasError`.
        AsyncValue<ConformiteCompte>(hasValue: true) =>
          conformite.requireValue.clearanceOperationnelle
              ? _Classes(
                  conformite: conformite.requireValue,
                  candidaturesEnvoyees: _candidaturesEnvoyees,
                  enVol: _enVol,
                  retour: _retour,
                  onCandidater: (ClasseVM c) => unawaited(_candidater(c)),
                )
              : _Onboarding(conformite: conformite.requireValue),
        AsyncValue<ConformiteCompte>(hasError: true) => EmptyState(
          message: t.classes.enseignant.erreurConformite,
          icone: AppIcons.avertissement,
          libelleAction: t.commun.reessayer,
          onAction: () => ref.invalidate(maConformiteProvider),
        ),
        _ => const Skeleton.liste(lignes: 3),
      },
    );
  }
}

/// L'onboarding : ou l'on en est, et ce qui debloque.
///
/// **Une dispense se voit sans laisser croire qu'on l'a contournee** : la
/// phrase nomme l'academie comme auteur de la decision, jamais l'enseignant.
class _Onboarding extends StatelessWidget {
  const _Onboarding({required this.conformite});

  final ConformiteCompte conformite;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          dominante: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                t.classes.enseignant.onboardingTitre,
                style: textes.headlineSmall,
              ),
              Ecart.vSm,
              Text(
                t.classes.enseignant.onboardingIntro,
                style: textes.bodyMedium,
              ),
              Ecart.vMd,
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: StatusPill(
                  libelle: t.classes.enseignant.clearanceAttente,
                  ton: TonEtat.avertissement,
                ),
              ),
            ],
          ),
        ),
        Ecart.vXl,
        EtapeConformite(
          titre: t.classes.enseignant.etapeContrat,
          detail: t.classes.enseignant.etapeContratDetail,
          fait: conformite.contratAccepte,
          libelleFait: t.classes.conformite.contratAccepte,
          libelleAFaire: t.classes.conformite.contratManquant,
          libelleAction: t.classes.enseignant.signerContrat,
          onAction: () => GoRouter.of(context).go(Routes.attenteContrat),
        ),
        Ecart.vMd,
        if (conformite.estDispense)
          EtapeConformite(
            titre: t.classes.enseignant.etapeKyc,
            detail: t.classes.enseignant.etapeKycDispenseDetail,
            fait: true,
            libelleFait: t.classes.conformite.exigenceDispensee,
            libelleAFaire: '',
            sousTitre: t.classes.enseignant.etapeKycDispense,
          )
        else
          EtapeConformite(
            titre: t.classes.enseignant.etapeKyc,
            detail: t.classes.enseignant.etapeKycDetail,
            fait: conformite.kycSatisfait,
            libelleFait: t.classes.conformite.etatVerifie,
            libelleAFaire: LibellesClasses.etatKyc(conformite.etat),
            tonAFaire: conformite.etat == EtatKyc.soumis
                ? TonEtat.accent
                : TonEtat.avertissement,
            libelleAction: conformite.etat == EtatKyc.soumis
                ? null
                : t.classes.enseignant.deposerPiece,
            onAction: () => GoRouter.of(context).go(Routes.attentePiece),
          ),
        Ecart.vLg,
        Text(t.classes.enseignant.clearanceDetail, style: textes.bodySmall),
      ],
    );
  }
}

/// Une etape de l'onboarding : son etat, son explication, son action.
///
/// Publique parce que la bienvenue (`ENS-01`) la reutilise pour dire ou en est
/// l'acces : deux rendus du meme etat finiraient par diverger.
class EtapeConformite extends StatelessWidget {
  /// Cree une etape.
  const EtapeConformite({
    required this.titre,
    required this.detail,
    required this.fait,
    required this.libelleFait,
    required this.libelleAFaire,
    super.key,
    this.sousTitre,
    this.tonAFaire = TonEtat.avertissement,
    this.libelleAction,
    this.onAction,
  });

  /// Le titre de l'etape.
  final String titre;

  /// Pourquoi elle existe.
  final String detail;

  /// Vrai quand elle est remplie.
  final bool fait;

  /// Le mot de la pastille quand c'est fait.
  final String libelleFait;

  /// Le mot de la pastille quand ce n'est pas fait.
  final String libelleAFaire;

  /// Une phrase de plus, par exemple la dispense.
  final String? sousTitre;

  /// Le ton de la pastille quand ce n'est pas fait.
  final TonEtat tonAFaire;

  /// L'action qui debloque. Rendue seulement quand l'etape n'est pas faite.
  final String? libelleAction;

  /// Ce que fait l'action.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(titre, style: textes.titleMedium),
              StatusPill(
                libelle: fait ? libelleFait : libelleAFaire,
                ton: fait ? TonEtat.succes : tonAFaire,
              ),
            ],
          ),
          if (sousTitre != null) ...<Widget>[
            Ecart.vSm,
            Text(sousTitre!, style: textes.titleSmall),
          ],
          Ecart.vSm,
          Text(detail, style: textes.bodySmall),
          if (!fait && libelleAction != null && onAction != null) ...<Widget>[
            Ecart.vMd,
            ActionPrincipale(
              libelle: libelleAction!,
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
              onPress: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

/// Les deux sections, apres clearance.
class _Classes extends ConsumerWidget {
  const _Classes({
    required this.conformite,
    required this.candidaturesEnvoyees,
    required this.enVol,
    required this.retour,
    required this.onCandidater,
  });

  final ConformiteCompte conformite;
  final Set<String> candidaturesEnvoyees;
  final String? enVol;
  final String? retour;
  final void Function(ClasseVM classe) onCandidater;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ClasseVM>> miennes = ref.watch(mesClassesProvider);
    final AsyncValue<List<ClasseVM>> disponibles = ref.watch(
      classesDisponiblesProvider(null),
    );
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (conformite.estDispense) ...<Widget>[
          // La dispense reste visible apres clearance : l'enseignant sait
          // que c'est une decision de l'academie, pas un oubli.
          Text(t.classes.enseignant.etapeKycDispense, style: textes.bodySmall),
          Ecart.vLg,
        ],
        SectionHeader(
          titre: t.classes.enseignant.mesClasses,
          compteur: miennes.value?.length,
        ),
        Ecart.vLg,
        switch (miennes) {
          AsyncValue<List<ClasseVM>>(hasValue: true) =>
            miennes.requireValue.isEmpty
                ? EmptyState(
                    message: t.classes.enseignant.aucuneAssignee,
                    invitation: t.classes.enseignant.aucuneAssigneeDetail,
                    icone: AppIcons.rienAAfficher,
                    registre: RegistreVide.subi,
                  )
                : GrilleClasses(
                    cartes: <Widget>[
                      for (final ClasseVM classe in miennes.requireValue)
                        CarteClasse(
                          classe: classe,
                          onOuvrir: () => GoRouter.of(
                            context,
                          ).go(Routes.groupePour(classe.id)),
                          action: ActionCarte(
                            libelle: t.classes.enseignant.ouvrirFiche,
                            niveau: NiveauAction.secondaire,
                            onPress: () => GoRouter.of(
                              context,
                            ).go(Routes.groupePour(classe.id)),
                          ),
                        ),
                    ],
                  ),
          AsyncValue<List<ClasseVM>>(hasError: true) => EmptyState(
            message: t.classes.commun.erreurLecture,
            icone: AppIcons.avertissement,
            libelleAction: t.commun.reessayer,
            onAction: () => ref.invalidate(mesClassesProvider),
          ),
          _ => const Skeleton.liste(lignes: 2),
        },
        Ecart.vSection,
        SectionHeader(
          titre: t.classes.enseignant.disponibles,
          compteur: disponibles.value?.length,
        ),
        Ecart.vLg,
        switch (disponibles) {
          AsyncValue<List<ClasseVM>>(hasValue: true) =>
            disponibles.requireValue.isEmpty
                ? EmptyState(
                    message: t.classes.enseignant.aucuneDisponible,
                    invitation: t.classes.enseignant.aucuneDisponibleDetail,
                    icone: AppIcons.rienAAfficher,
                    registre: RegistreVide.subi,
                  )
                : GrilleClasses(
                    cartes: <Widget>[
                      for (final ClasseVM classe in disponibles.requireValue)
                        _carteDisponible(classe),
                    ],
                  ),
          AsyncValue<List<ClasseVM>>(hasError: true) => _erreurDisponibles(
            ref,
            disponibles.error!,
          ),
          _ => const Skeleton.liste(lignes: 2),
        },
        Ecart.vLg,
        LocalFeedback(message: retour),
      ],
    );
  }

  Widget _carteDisponible(ClasseVM classe) {
    final bool envoyee =
        candidaturesEnvoyees.contains(classe.id) ||
        classe.candidature == EtatCandidature.envoyee;
    final ClasseVM affichee = envoyee
        ? classe.avecCandidature(EtatCandidature.envoyee)
        : classe;
    return CarteClasse(
      classe: affichee,
      // Une candidature deja partie n'a plus de bouton : le dire deux fois
      // n'apprendrait rien, et un second envoi serait refuse.
      action: envoyee
          ? null
          : ActionCarte(
              libelle: t.classes.enseignant.candidater,
              enCours: enVol == classe.id,
              onPress: enVol == null ? () => onCandidater(classe) : null,
            ),
    );
  }

  /// Une capacite serveur absente se dit comme telle, sans « Reessayer » : y
  /// revenir dans dix secondes n'y changerait rien.
  Widget _erreurDisponibles(WidgetRef ref, Object erreur) {
    final EchecDomaine echec = EchecDomaine.depuis(erreur);
    if (echec.motif == MotifEchec.capaciteAbsente) {
      return EmptyState(
        message: t.classes.enseignant.aucuneDisponible,
        invitation: t.classes.commun.capaciteAbsente,
        icone: AppIcons.rienAAfficher,
        registre: RegistreVide.subi,
      );
    }
    return EmptyState(
      message: t.classes.commun.erreurLecture,
      invitation: messageHumain(echec),
      icone: AppIcons.avertissement,
      libelleAction: t.commun.reessayer,
      onAction: () => ref.invalidate(classesDisponiblesProvider(null)),
    );
  }
}
