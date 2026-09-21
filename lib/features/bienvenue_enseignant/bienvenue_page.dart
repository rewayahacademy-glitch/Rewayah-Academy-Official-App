import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/profil/service_profil_enseignant.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../classes/domaine/conformite.dart';
import '../classes/domaine/providers.dart';
import '../classes/libelles_classes.dart';
import '../classes/routes_core24.dart';
import '../enseignant_classes/classes_enseignant_page.dart'
    show EtapeConformite;

/// `ENS-01` : la bienvenue, traversee une seule fois apres validation.
///
/// **Elle ne porte aucune grille de semaine.** La declaration des
/// disponibilites vit dans `ENS-06` (`Routes.enseignantCreneaux`) et nulle part
/// ailleurs : deux grilles jumelles finiraient par diverger. Cet ecran y
/// conduit, il ne la reimplemente pas.
///
/// Elle n'est pas une destination : elle n'apparait dans aucune barre, et rien
/// n'y ramene. Ses deux sorties sont donc **sur l'ecran**, dans la zone d'action
/// collee en bas, et non dans un chrome de navigation qui n'existe pas ici.
///
/// Ce qu'elle ne sait pas faire, et qu'il faut lire avant de s'y fier : **elle
/// ne memorise pas qu'elle a ete vue.** Rien dans le perimetre de cet ecran ne
/// peut le retenir -- `AppDatabase` est gelee a quatre tables et
/// `PreferencesLocales` ne vaut que pour l'appareil courant. C'est le routeur
/// qui decide quand y mener, et la demande est ecrite dans
/// `docs/parallel-reports/CONTRACT_REQUEST_E.md`.
class BienvenueEnseignantPage extends ConsumerWidget {
  /// Cree l'ecran de bienvenue de l'enseignant.
  const BienvenueEnseignantPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AccountStatus? statut = ref.watch(
      sessionProvider.select((SessionState session) => session.accountStatus),
    );
    final AsyncValue<ProfilEnseignant?> profil = ref.watch(
      profilEnseignantProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    // Un compte qui n'est pas valide ne se fait pas feliciter. On ne devine pas
    // non plus : un statut absent ou illisible n'ouvre pas la bienvenue.
    final bool valide =
        statut == AccountStatus.active ||
        statut == AccountStatus.provisionalActive;

    if (!valide) {
      return PageShell(
        titre: t.enseignant.bienvenue.titre,
        child: EmptyState(
          message: t.enseignant.bienvenue.dossierIncomplet,
          invitation: t.enseignant.bienvenue.dossierIncompletDetail,
          icone: AppIcons.dossiers,
          libelleAction: t.enseignant.bienvenue.versAttente,
          onAction: () => GoRouter.of(context).go(Routes.attente),
        ),
      );
    }

    return PageShell(
      titre: t.enseignant.bienvenue.titre,
      // Les deux sorties survivent a l'echec de la lecture du profil : la
      // bienvenue n'est pas un cul-de-sac, meme quand elle ne sait pas le
      // prenom de la personne qu'elle accueille.
      actions: _Sorties(horsLigne: horsLigne),
      child: switch (profil) {
        // Les getters, jamais le type d'execution : Riverpod 3 relance un
        // provider en echec tout seul et l'etat repasse par `AsyncLoading` en
        // conservant `hasError`.
        AsyncValue<ProfilEnseignant?>(hasValue: true) => _Corps(
          prenom: profil.requireValue?.prenom,
        ),
        AsyncValue<ProfilEnseignant?>(hasError: true) => EmptyState(
          message: t.enseignant.bienvenue.erreur,
          icone: AppIcons.avertissement,
          libelleAction: t.commun.reessayer,
          onAction: () => ref.invalidate(profilEnseignantProvider),
        ),
        _ => const Skeleton.liste(lignes: 5),
      },
    );
  }
}

/// Le corps de la bienvenue : ou l'on en est, ce qui vient, ce qui engage.
class _Corps extends ConsumerWidget {
  const _Corps({required this.prenom});

  /// Le prenom, quand la lecture du profil l'a rendu. Nul, la bienvenue reste
  /// une bienvenue : elle ne fabrique pas un nom.
  final String? prenom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final String nomme = prenom?.trim() ?? '';
    // L'acces aux classes (KYC V2) : le contrat, l'identite, et une eventuelle
    // dispense. Une lecture en echec ne bloque pas la bienvenue : le bloc
    // s'absente, la bienvenue reste une bienvenue.
    final AsyncValue<ConformiteCompte> conformite = ref.watch(
      maConformiteProvider,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          dominante: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                nomme.isEmpty
                    ? t.enseignant.bienvenue.salutationSansNom
                    : t.enseignant.bienvenue.salutation(prenom: nomme),
                style: textes.headlineSmall,
              ),
              Ecart.vMd,
              // La pastille garde sa largeur intrinseque : etiree, elle ne
              // serait plus une pastille mais un aplat.
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: StatusPill(
                  libelle: t.enseignant.bienvenue.dossierValide,
                  ton: TonEtat.succes,
                ),
              ),
            ],
          ),
        ),
        if (conformite.hasValue) ...<Widget>[
          Ecart.vSection,
          _Acces(conformite: conformite.requireValue),
        ],
        Ecart.vSection,
        SectionHeader(titre: t.enseignant.bienvenue.suite),
        _Pas(numero: 1, texte: t.enseignant.bienvenue.pas1),
        _Pas(numero: 2, texte: t.enseignant.bienvenue.pas2),
        _Pas(numero: 3, texte: t.enseignant.bienvenue.pas3),
        Ecart.vSection,
        SectionHeader(titre: t.enseignant.bienvenue.rappels),
        // **Les deux dispositifs de l'ADR-011, nommes en clair.** Ils ont deja
        // ete accuses a l'inscription, en une seule acceptation
        // `recording_and_control_notice` : la base n'en connait qu'une, et deux
        // accuses separement opposables demanderaient une valeur de
        // `contract_kind` de plus, donc une migration (demande ecrite dans
        // `CONTRACT_REQUEST_E.md`). En attendant, les deux points sont dits
        // explicitement, et ici une troisieme fois -- ce qui est voulu par
        // l'ADR-011, non un doublon a corriger.
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(t.contrat.pointEnregistrement, style: textes.bodyMedium),
              Ecart.vMd,
              Text(t.contrat.pointControle, style: textes.bodyMedium),
              Ecart.vMd,
              Text(
                t.enseignant.bienvenue.rappelDejaAccepte,
                style: textes.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// L'acces aux classes : le contrat, l'identite, la dispense eventuelle.
///
/// **La dispense se lit comme une decision de l'academie**, jamais comme un
/// contournement : la phrase la nomme, et la pastille dit « KYC dispense ».
class _Acces extends StatelessWidget {
  const _Acces({required this.conformite});

  final ConformiteCompte conformite;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          titre: conformite.clearanceOperationnelle
              ? t.classes.enseignant.clearanceOk
              : t.classes.enseignant.clearanceAttente,
        ),
        Ecart.vMd,
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
      ],
    );
  }
}

/// Un pas du parcours, numerote pour qu'on sache combien il en reste.
class _Pas extends StatelessWidget {
  const _Pas({required this.numero, required this.texte});

  final int numero;
  final String texte;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('$numero.', style: textes.titleMedium),
          Ecart.hMd,
          Expanded(child: Text(texte, style: textes.bodyLarge)),
        ],
      ),
    );
  }
}

/// Les deux sorties de la bienvenue, collees en bas.
class _Sorties extends StatelessWidget {
  const _Sorties({required this.horsLigne});

  final bool horsLigne;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Naviguer aboutit toujours ; POSER un creneau, non. On le dit avant le
        // geste plutot que de laisser la grille echouer apres.
        if (horsLigne) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              t.enseignant.bienvenue.horsLigne,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Ecart.vMd,
        ],
        ActionPrincipale(
          libelle: t.enseignant.bienvenue.declarer,
          onPress: () => GoRouter.of(context).go(Routes.enseignantCreneaux),
        ),
        Ecart.vMd,
        ActionPrincipale(
          libelle: t.enseignant.bienvenue.versJournee,
          niveau: NiveauAction.secondaire,
          onPress: () => GoRouter.of(context).go(Routes.enseignantJournee),
        ),
        Ecart.vSm,
        // La troisieme sortie, tertiaire : les classes assignees et
        // disponibles, ou l'onboarding si l'acces n'est pas encore ouvert.
        ActionPrincipale(
          libelle: t.classes.enseignant.voirClasses,
          niveau: NiveauAction.tertiaire,
          onPress: () =>
              GoRouter.of(context).go(CheminsCore24.enseignantClasses),
        ),
      ],
    );
  }
}
