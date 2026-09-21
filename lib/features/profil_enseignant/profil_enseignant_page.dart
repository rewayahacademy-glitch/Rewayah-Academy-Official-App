import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/service_auth.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/service_planning.dart';
import '../../core/profil/service_acceptations.dart';
import '../../core/profil/service_declaration.dart';
import '../../core/profil/service_profil_enseignant.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../classes/routes_core24.dart';

/// `ENS-05` : qui suis-je pour l'academie, et ou regle-je ce qui m'appartient.
///
/// Troisieme et derniere destination de la barre de l'enseignant. **C'est elle
/// qui porte la deconnexion**, et ce n'est pas un choix de confort : la barre
/// est passee de quatre destinations a trois, « Compte » en est sortie, et
/// `secondairesPour(AppRole.teacher)` est vide -- or le pied de coquille qui
/// porterait cette entree n'est rendu qu'a partir de 600 de large, une barre
/// basse Material 3 n'acceptant aucune entree hors destination. Sans cet ecran,
/// un enseignant sur telephone n'aurait plus **aucun** chemin vers la
/// deconnexion (`TEACHER_PARALLEL_BASELINE.md` section 3.1).
///
/// D'ou la forme : la deconnexion vit dans la zone d'action **collee en bas** de
/// [PageShell], et non dans le corps defilant. Elle reste donc visible sans
/// defilement a 390 x 844, et surtout elle survit a l'echec de toutes les
/// lectures de l'ecran -- c'est la seule chose qu'un enseignant doit toujours
/// pouvoir faire.
class ProfilEnseignantPage extends ConsumerWidget {
  /// Cree l'ecran de profil de l'enseignant.
  const ProfilEnseignantPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ProfilEnseignant?> profil = ref.watch(
      profilEnseignantProvider,
    );

    // Le statut qui GOUVERNE l'acces vient de la session, celui qui s'AFFICHE
    // vient du profil : `account_status` est lu par deux chemins distincts
    // (`source_session.dart` et `service_profil_enseignant.dart`), et rien ne
    // garantit qu'ils soient du meme instant. On affiche donc la lecture la plus
    // fraiche, et on dit qu'elle diverge quand c'est le cas, plutot que de
    // choisir en silence celle qui arrange.
    final AccountStatus? statutSession = ref.watch(
      sessionProvider.select((SessionState session) => session.accountStatus),
    );

    // Tant que la reponse n'est pas connue, l'appareil est repute en ligne :
    // afficher « pas de reseau » a la premiere frame ferait clignoter l'ecran.
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    return PageShell(
      titre: t.enseignant.profil.titre,
      entete: Text(t.enseignant.profil.intro),
      actions: const _Deconnexion(),
      child: switch (profil) {
        AsyncValue<ProfilEnseignant?>(
          hasValue: true,
          value: final ProfilEnseignant lu,
        ) =>
          _Corps(
            profil: lu,
            statutSession: statutSession,
            horsLigne: horsLigne,
          ),
        // Une lecture qui aboutit sans rien trouver n'est pas un echec : ce
        // compte n'a pas de ligne `teacher_profiles`, et seule l'academie peut
        // en creer une.
        AsyncValue<ProfilEnseignant?>(hasValue: true) => EmptyState(
          message: t.enseignant.profil.vide,
          invitation: t.enseignant.profil.videDetail,
          icone: AppIcons.profil,
          registre: RegistreVide.subi,
        ),
        // Les getters, jamais le type d'execution : Riverpod 3 relance un
        // provider en echec tout seul, et l'etat repasse par `AsyncLoading` en
        // conservant `hasError`.
        AsyncValue<ProfilEnseignant?>(hasError: true) => EmptyState(
          message: t.enseignant.profil.erreur,
          icone: AppIcons.avertissement,
          libelleAction: t.commun.reessayer,
          onAction: () => ref.invalidate(profilEnseignantProvider),
        ),
        _ => const Skeleton.liste(lignes: 6),
      },
    );
  }
}

/// Le corps nominal, en une colonne sur telephone et en deux sur desktop.
class _Corps extends StatelessWidget {
  const _Corps({
    required this.profil,
    required this.statutSession,
    required this.horsLigne,
  });

  final ProfilEnseignant profil;
  final AccountStatus? statutSession;
  final bool horsLigne;

  @override
  Widget build(BuildContext context) {
    final Widget identite = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(dominante: true, child: _Entete(profil: profil)),
        Ecart.vSection,
        _Statut(profil: profil, statutSession: statutSession),
      ],
    );

    final Widget reglages = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Declaration(profil: profil, horsLigne: horsLigne),
        Ecart.vSection,
        const _Contrat(),
        Ecart.vSection,
        const _Personnel(),
      ],
    );

    // [RESPONSIVE] Le gabarit decide, jamais une largeur comparee a un nombre.
    if (AppGabarit.de(context) == Gabarit.desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: identite),
          const SizedBox(width: AppSpacing.section),
          Expanded(child: reglages),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[identite, Ecart.vSection, reglages],
    );
  }
}

/// L'identite professionnelle autorisee : prenom et identifiant immuable.
///
/// Rien d'autre n'est montre, et c'est exactement ce que le produit expose deja
/// aux familles (ADR-008).
class _Entete extends StatelessWidget {
  const _Entete({required this.profil});

  final ProfilEnseignant profil;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    return Row(
      children: <Widget>[
        AvatarTile(prenom: profil.prenom),
        Ecart.hLg,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                profil.prenom.isEmpty
                    ? t.enseignant.profil.nonRenseigne
                    : profil.prenom,
                style: textes.headlineSmall,
              ),
              Ecart.vXs,
              Text(
                profil.identifiant.isEmpty
                    ? t.enseignant.profil.nonRenseigne
                    : profil.identifiant,
                style: textes.bodyLarge,
              ),
              Ecart.vXs,
              // L'identifiant immuable est ce que les familles voient : il vaut
              // mieux le dire ici qu'une seconde ligne de reglage ailleurs.
              Text(
                t.enseignant.profil.identifiantDetail,
                style: textes.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Le statut du compte, dit en une phrase et sans code.
class _Statut extends StatelessWidget {
  const _Statut({required this.profil, required this.statutSession});

  final ProfilEnseignant profil;
  final AccountStatus? statutSession;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AccountStatus? statut = profil.statutCompte;
    final (String libelle, String detail, TonEtat ton) = _dire(statut);

    // Les deux lectures ne sont pas du meme instant : celle qui gouverne la
    // porte du routeur peut etre en retard sur celle qui s'affiche. On le dit
    // au lieu de laisser l'enseignant buter sur un acces qui ne suit pas.
    final bool divergent =
        statut != null && statutSession != null && statut != statutSession;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: t.enseignant.profil.statutSection),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // La pastille garde sa largeur intrinseque : une colonne etiree
              // lui donnerait toute la largeur de la carte, et un aplat large
              // n'est plus une pastille (`01-systeme-visuel.md` section 3).
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: StatusPill(libelle: libelle, ton: ton),
              ),
              Ecart.vMd,
              Text(detail, style: textes.bodyMedium),
              if (divergent) ...<Widget>[
                Ecart.vMd,
                Semantics(
                  liveRegion: true,
                  child: Text(
                    t.enseignant.profil.statutDivergent,
                    style: palette.inkWarning.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SettingRow(
          title: t.enseignant.profil.verification,
          value: switch (profil.verification) {
            VerificationEnseignant.enAttente =>
              t.enseignant.profil.verificationEnAttente,
            VerificationEnseignant.validee =>
              t.enseignant.profil.verificationValidee,
            VerificationEnseignant.refusee =>
              t.enseignant.profil.verificationRefusee,
            null => t.enseignant.profil.nonRenseigne,
          },
          icon: AppIcons.controleQualite,
          enabled: false,
        ),
      ],
    );
  }

  /// Les quatre valeurs d'`AccountStatus`, plus le cas illisible.
  ///
  /// **Aucun repli sur « actif ».** Un statut absent se dit absent : c'est le
  /// mensonge d'interface que ce talon portait avant ce lot, en affirmant en vert
  /// « Compte enseignant verifie » sans avoir rien lu.
  (String, String, TonEtat) _dire(AccountStatus? statut) => switch (statut) {
    AccountStatus.active => (
      t.enseignant.profil.compteValide,
      t.enseignant.profil.statutValideDetail,
      TonEtat.succes,
    ),
    AccountStatus.provisionalActive => (
      t.enseignant.profil.statutProvisoire,
      t.enseignant.profil.statutProvisoireDetail,
      TonEtat.avertissement,
    ),
    AccountStatus.pendingKyc => (
      t.enseignant.profil.statutEnAttente,
      t.enseignant.profil.statutEnAttenteDetail,
      TonEtat.neutre,
    ),
    AccountStatus.disabled => (
      t.enseignant.profil.statutSuspendu,
      t.enseignant.profil.statutSuspenduDetail,
      TonEtat.alerte,
    ),
    null => (
      t.enseignant.profil.statutInconnu,
      t.enseignant.profil.statutInconnuDetail,
      TonEtat.neutre,
    ),
  };
}

/// Ce que l'enseignant declare, et qu'il peut corriger.
///
/// Deux lignes editables, pas trois : `country` et `languages` sont du texte
/// libre en base, donc un champ libre dit exactement ce que la colonne accepte.
/// `timezone_iana`, lui, demande un libelle IANA valide -- la fonction SQL le
/// verifie et refuse le reste -- et aucun inventaire de fuseaux n'est tranche
/// dans le produit : il reste donc en lecture, et la demande est ecrite dans
/// `CONTRACT_REQUEST_E.md`. Un champ qui refuserait une saisie que l'enseignant
/// ne peut pas deviner serait pire qu'une lecture assumee.
class _Declaration extends ConsumerStatefulWidget {
  const _Declaration({required this.profil, required this.horsLigne});

  final ProfilEnseignant profil;
  final bool horsLigne;

  @override
  ConsumerState<_Declaration> createState() => _DeclarationState();
}

class _DeclarationState extends ConsumerState<_Declaration> {
  String? _message;

  Future<void> _editer({
    required String titre,
    required String valeur,
    required String? indice,
    required Future<void> Function(String saisie) ecrire,
  }) async {
    final String? saisie = await AppBottomSheet.ouvrir<String>(
      context,
      titre: titre,
      constructeur: (BuildContext _) =>
          _FeuilleTexte(valeur: valeur, indice: indice),
    );
    if (saisie == null || !mounted) {
      return;
    }
    try {
      await ecrire(saisie);
      if (!mounted) {
        return;
      }
      // Le faux comme la base relisent ce qui a ete ecrit : l'ecran n'a aucun
      // etat local de profil, il reaffiche ce que la lecture rend.
      ref.invalidate(profilEnseignantProvider);
      setState(() => _message = t.enseignant.profil.enregistre);
    } on Object {
      if (mounted) {
        setState(() => _message = t.enseignant.profil.editionErreur);
      }
    }
  }

  /// Le service se lit au moment du geste, jamais pendant `build` : le lire au
  /// montage construirait le client Supabase pour un ecran qu'on ne fait que
  /// consulter.
  ServiceDeclarationEnseignant get _service =>
      ref.read(serviceDeclarationProvider);

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final ProfilEnseignant profil = widget.profil;
    final AsyncValue<String> fuseau = ref.watch(monFuseauProvider);
    final String langues = profil.langues.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: t.enseignant.profil.identite),
        if (widget.horsLigne) ...<Widget>[
          Text(t.enseignant.profil.horsLigne, style: textes.bodySmall),
          Ecart.vSm,
        ],
        SettingRow(
          title: t.enseignant.profil.pays,
          value: profil.pays ?? t.enseignant.profil.nonRenseigne,
          icon: AppIcons.foyer,
          // Un bouton qui ne peut pas aboutir n'est pas rendu : hors ligne, la
          // ligne redevient une lecture et la phrase ci-dessus l'explique.
          onPress: widget.horsLigne
              ? null
              : () => unawaited(
                  _editer(
                    titre: t.enseignant.profil.modifierPays,
                    valeur: profil.pays ?? '',
                    indice: null,
                    ecrire: (String saisie) => _service.declarer(pays: saisie),
                  ),
                ),
        ),
        SettingRow(
          title: t.enseignant.profil.langues,
          value: langues.isEmpty ? t.enseignant.profil.nonRenseigne : langues,
          icon: AppIcons.reglages,
          onPress: widget.horsLigne
              ? null
              : () => unawaited(
                  _editer(
                    titre: t.enseignant.profil.modifierLangues,
                    valeur: langues,
                    indice: t.enseignant.profil.languesIndice,
                    ecrire: (String saisie) =>
                        _service.declarer(langues: _listeDeLangues(saisie)),
                  ),
                ),
        ),
        SettingRow(
          title: t.enseignant.profil.fuseau,
          description: t.enseignant.profil.fuseauDetail,
          value: fuseau.hasValue
              ? fuseau.requireValue
              : t.enseignant.profil.nonRenseigne,
          icon: AppIcons.creneaux,
          enabled: false,
        ),
        SettingRow(
          title: t.enseignant.profil.plafond,
          description: t.enseignant.profil.plafondDetail,
          value: profil.plafondHeures == null
              ? t.enseignant.profil.nonRenseigne
              : t.enseignant.profil.plafondValeur(
                  nombre: profil.plafondHeures!,
                ),
          icon: AppIcons.journee,
          enabled: false,
        ),
        LocalFeedback(message: _message),
      ],
    );
  }

  /// Decoupe une saisie en langues, sans garder de vide.
  static List<String> _listeDeLangues(String saisie) => saisie
      .split(',')
      .map((String langue) => langue.trim())
      .where((String langue) => langue.isNotEmpty)
      .toList(growable: false);
}

/// Un champ unique, dans une feuille courte.
class _FeuilleTexte extends StatefulWidget {
  const _FeuilleTexte({required this.valeur, required this.indice});

  final String valeur;
  final String? indice;

  @override
  State<_FeuilleTexte> createState() => _FeuilleTexteState();
}

class _FeuilleTexteState extends State<_FeuilleTexte> {
  late final TextEditingController _saisie = TextEditingController(
    text: widget.valeur,
  );

  @override
  void dispose() {
    _saisie.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextField(
          controller: _saisie,
          autofocus: true,
          decoration: InputDecoration(helperText: widget.indice),
        ),
        Ecart.vXl,
        ActionPrincipale(
          libelle: t.enseignant.profil.enregistrer,
          onPress: () => Navigator.of(context).pop(_saisie.text.trim()),
        ),
      ],
    );
  }
}

/// Le contrat et les accuses, en lecture seule et pour toujours.
///
/// Sans cette section, un enseignant valide ne peut plus les relire du tout :
/// `deciderRedirection` ferme `/attente/*` des que le compte devient actif.
class _Contrat extends ConsumerWidget {
  const _Contrat();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Acceptation>> acceptations = ref.watch(
      acceptationsProvider,
    );
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: t.enseignant.profil.contratSection),
        // L'erreur reste locale a la section : les autres restent lisibles, et
        // la deconnexion aussi.
        switch (acceptations) {
          AsyncValue<List<Acceptation>>(hasValue: true) =>
            acceptations.requireValue.isEmpty
                ? EmptyState(
                    message: t.enseignant.profil.contratAucun,
                    invitation: t.enseignant.profil.contratAucunDetail,
                    icone: AppIcons.dossiers,
                    registre: RegistreVide.subi,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (final Acceptation lue in acceptations.requireValue)
                        SettingRow(
                          key: ValueKey<String>(
                            '${lue.sorte.valeurSql}-${lue.version}',
                          ),
                          title: _libelle(lue.sorte),
                          description: t.enseignant.profil.contratDetail(
                            version: lue.version,
                            date: _date(lue.accepteeLe),
                          ),
                          icon: AppIcons.dossiers,
                          enabled: false,
                        ),
                      Ecart.vSm,
                      Text(
                        t.enseignant.profil.contratLectureSeule,
                        style: textes.bodySmall,
                      ),
                    ],
                  ),
          AsyncValue<List<Acceptation>>(hasError: true) => EmptyState(
            message: t.enseignant.profil.contratErreur,
            icone: AppIcons.avertissement,
            libelleAction: t.commun.reessayer,
            onAction: () => ref.invalidate(acceptationsProvider),
          ),
          _ => const Skeleton.liste(lignes: 2),
        },
      ],
    );
  }

  String _libelle(SorteContrat sorte) => switch (sorte) {
    SorteContrat.contratEnseignant => t.enseignant.profil.contratEnseignant,
    SorteContrat.conditionsTuteur => t.enseignant.profil.contratConditions,
    SorteContrat.accuseEnregistrementControle =>
      t.enseignant.profil.contratAccuse,
  };

  String _date(DateTime quand) =>
      '${quand.day.toString().padLeft(2, '0')}/'
      '${quand.month.toString().padLeft(2, '0')}/${quand.year}';
}

/// L'acces aux surfaces reellement personnelles.
///
/// Elles ne sont pas reimplementees ici : `/compte/profil` et
/// `/compte/reglages` existent, portent les seules preferences reelles du
/// produit, et restent ouvertes a un compte actif. Le chemin de retour a 390 de
/// large est la barre basse elle-meme : `_CoquilleSecondaire` rend `/compte/*`
/// dans `NavShell` avec les trois destinations de l'enseignant, aucune active.
class _Personnel extends StatelessWidget {
  const _Personnel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: t.enseignant.profil.personnel),
        SettingRow(
          title: t.compte.profil,
          description: t.compte.profilDetail,
          icon: AppIcons.profil,
          onPress: () => context.push(Routes.compteProfil),
        ),
        SettingRow(
          title: t.compte.reglages,
          description: t.compte.reglagesDetail,
          icon: AppIcons.reglages,
          onPress: () => context.push(Routes.compteReglages),
        ),
        // Mes classes et Classes disponibles (sprint noyau 24 h) : une pose
        // hors de la barre, atteinte d'ici et depuis la bienvenue.
        SettingRow(
          title: t.classes.enseignant.mesClasses,
          description: t.classes.enseignant.disponibles,
          icon: AppIcons.cours,
          onPress: () => context.push(CheminsCore24.enseignantClasses),
        ),
      ],
    );
  }
}

/// La deconnexion, collee en bas et confirmee.
///
/// Elle vit dans la zone d'action de [PageShell] pour deux raisons mesurables :
/// elle reste atteignable sans defilement a 390 x 844, et elle survit a l'echec
/// de toutes les lectures de l'ecran.
class _Deconnexion extends ConsumerWidget {
  const _Deconnexion();

  @override
  Widget build(BuildContext context, WidgetRef ref) => ActionPrincipale(
    libelle: t.compte.deconnexion,
    niveau: NiveauAction.destructive,
    // Le service se lit au moment du geste, et se capture AVANT l'attente : on
    // ne lit jamais `ref` apres un `await`, ou le widget peut avoir disparu. Le
    // lire pendant `build` aurait un autre defaut, moins visible : il
    // construirait le client Supabase au montage, et tout test qui monte cet
    // ecran sans surcharger le service echouerait avant d'avoir rien mesure.
    onPress: () =>
        unawaited(_demander(context, ref.read(serviceAuthProvider))),
  );

  Future<void> _demander(BuildContext context, ServiceAuth auth) async {
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: t.enseignant.profil.deconnexionQuestion,
      consequence: t.enseignant.profil.deconnexionConsequence,
      // Le libelle nomme l'acte et son objet, comme `ConfirmDestructive`
      // l'exige : « Me deconnecter maintenant », jamais « OK ».
      libelleConfirmer: t.enseignant.profil.deconnexionConfirmer,
    );
    if (confirme) {
      await auth.deconnexion();
    }
  }
}
