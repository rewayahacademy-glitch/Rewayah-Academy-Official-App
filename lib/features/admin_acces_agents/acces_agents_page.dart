import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/agent/service_agent.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';

/// `ADM-07` : l'acces des agents IA (ADR-025).
///
/// **Un seul ecran, pas un parcours en quatre etapes.** La console de l'autre
/// produit de l'operateur guidait l'emission en quatre ecrans successifs ; ici
/// le formulaire tient en quatre champs qui se voient tous en meme temps, et la
/// liste des jetons vivants est juste en dessous. Un assistant se justifie quand
/// une etape depend de la precedente : aucune ne depend ici d'une autre.
///
/// Ce que cet ecran garde de la console precedente, parce que c'en etait la
/// bonne idee : **« Pourra » et « Ne pourra pas » de rang egal**. Quand on
/// accorde un droit d'acces, la question utile n'est pas ce qu'il ouvre, c'est
/// ce qu'il n'ouvre pas.
///
/// Trois choix de rendu, chacun paye par une raison :
///
///   * **le secret ne s'affiche qu'une fois, et l'ecran le dit avant**, pas
///     apres. Ni la base ni cet ecran ne peuvent le retrouver : la base n'en
///     garde que l'empreinte ;
///   * **l'etat d'un jeton vient de la base**, jamais d'une comparaison entre
///     `expire_le` et l'horloge du poste. Deux horloges qui derivent
///     afficheraient « actif » sur un jeton que la base refuse deja ;
///   * **un jeton jamais utilise est signale**. C'est le symptome le plus
///     courant d'un lien qui n'est pas arrive a destination, et il ne se voit
///     pas dans une date d'expiration.
class AccesAgentsPage extends ConsumerStatefulWidget {
  /// Cree l'ecran d'acces des agents.
  const AccesAgentsPage({super.key});

  @override
  ConsumerState<AccesAgentsPage> createState() => _AccesAgentsPageEtat();
}

class _AccesAgentsPageEtat extends ConsumerState<AccesAgentsPage> {
  /// Les durees proposees. Vingt-quatre heures est le plafond, et la base le
  /// verifie de son cote : cette liste est une commodite, pas une borne.
  static const List<int> _durees = <int>[1, 4, 8, 24];

  final TextEditingController _libelle = TextEditingController();
  final TextEditingController _recherche = TextEditingController();

  List<JetonAgent> _jetons = <JetonAgent>[];
  List<PersonneObservable> _personnes = <PersonneObservable>[];
  PersonneObservable? _choisie;
  int _duree = 8;
  bool _masquee = true;

  bool _chargement = true;
  bool _emission = false;
  Object? _erreur;
  String? _message;
  JetonEmis? _emis;

  @override
  void initState() {
    super.initState();
    unawaited(_charger());
  }

  @override
  void dispose() {
    _libelle.dispose();
    _recherche.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final ServiceAgent service = ref.read(serviceAgentProvider);
      final List<JetonAgent> jetons = await service.lister();
      final List<PersonneObservable> personnes = await service.personnes();
      if (!mounted) {
        return;
      }
      setState(() {
        _jetons = jetons;
        _personnes = personnes;
        _chargement = false;
      });
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _erreur = e;
        _chargement = false;
      });
    }
  }

  bool get _emissionPossible =>
      _libelle.text.trim().isNotEmpty && _choisie != null && !_emission;

  Future<void> _emettre() async {
    final PersonneObservable? qui = _choisie;
    if (qui == null || !_emissionPossible) {
      return;
    }
    setState(() {
      _emission = true;
      _message = null;
    });
    try {
      final JetonEmis emis = await ref
          .read(serviceAgentProvider)
          .emettre(
            libelle: _libelle.text.trim(),
            profilObserve: qui.id,
            dureeHeures: _duree,
            identiteMasquee: _masquee,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _emis = emis;
        _emission = false;
        _libelle.clear();
        _choisie = null;
      });
      await _charger();
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _emission = false;
        _message = t.admin.agents.erreurEmission;
      });
    }
  }

  Future<void> _revoquer(JetonAgent jeton) async {
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: t.admin.agents.revoquerTitre,
      consequence: t.admin.agents.revoquerDetail,
      libelleConfirmer: t.admin.agents.revoquerConfirmer,
    );
    if (!confirme) {
      return;
    }
    try {
      await ref.read(serviceAgentProvider).revoquer(jeton.id);
      if (!mounted) {
        return;
      }
      setState(() => _message = t.admin.agents.revoque);
      await _charger();
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _message = t.admin.agents.erreurRevocation);
    }
  }

  Future<void> _copier(String lien) async {
    await Clipboard.setData(ClipboardData(text: lien));
    if (!mounted) {
      return;
    }
    setState(() => _message = t.admin.agents.copie);
  }

  /// Les personnes que la recherche laisse passer.
  ///
  /// Le filtre porte sur le prenom, le nom **et l'identifiant immuable** : une
  /// administration qui a sous les yeux un identifiant dans un journal doit
  /// pouvoir le coller ici sans le traduire en nom.
  List<PersonneObservable> get _proposees {
    final String q = _recherche.text.trim().toLowerCase();
    if (q.isEmpty) {
      return _personnes;
    }
    return _personnes
        .where(
          (PersonneObservable p) =>
              p.libelle.toLowerCase().contains(q) ||
              p.identifiant.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.admin.agents.titre,
      defilante: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LocalFeedback(message: _message),
          Expanded(
            child: ListView(
              children: <Widget>[
                Text(
                  t.admin.agents.intro,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Ecart.vXxl,
                if (_emis != null)
                  _CarteJetonEmis(
                    emis: _emis!,
                    onCopier: _copier,
                    onTermine: () => setState(() => _emis = null),
                  )
                else
                  _formulaire(context),
                Ecart.vSection,
                SectionHeader(
                  titre: t.admin.agents.titre,
                  compteur: _jetons.length,
                ),
                Ecart.vLg,
                _liste(context),
                Ecart.vRespiration,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formulaire(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: _libelle,
            onChanged: (String _) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: t.admin.agents.libelle,
              helperText: t.admin.agents.libelleAide,
              hintText: t.admin.agents.libelleExemple,
            ),
          ),
          Ecart.vXxl,

          Text(t.admin.agents.qui, style: textes.titleSmall),
          Ecart.vXs,
          Text(t.admin.agents.quiAide, style: textes.bodySmall),
          Ecart.vMd,
          TextField(
            controller: _recherche,
            onChanged: (String _) => setState(() {}),
            decoration: InputDecoration(
              labelText: t.admin.agents.chercher,
              prefixIcon: Icon(AppIcons.dossiers.repos),
            ),
          ),
          Ecart.vMd,
          _ChoixPersonne(
            personnes: _proposees,
            choisie: _choisie,
            onChoix: (PersonneObservable p) => setState(() => _choisie = p),
          ),
          Ecart.vXxl,

          Text(t.admin.agents.duree, style: textes.titleSmall),
          Ecart.vMd,
          // Choix de formulaire, pas un filtre : la duree du jeton.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final int h in _durees)
                FilterPill(
                  libelle: LibellesGroupe.valeurSeule(
                    t.admin.agents.dureeHeure(nombre: h),
                  ),
                  retenue: _duree == h,
                  onPress: () => setState(() => _duree = h),
                ),
            ],
          ),
          Ecart.vXs,
          Text(t.admin.agents.dureePlafond, style: textes.bodySmall),
          Ecart.vXxl,

          Text(t.admin.agents.identite, style: textes.titleSmall),
          Ecart.vMd,
          // Choix de formulaire, pas un filtre : l'identite du jeton.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              FilterPill(
                libelle: t.admin.agents.identiteMasquee,
                retenue: _masquee,
                onPress: () => setState(() => _masquee = true),
              ),
              FilterPill(
                libelle: t.admin.agents.identiteVisible,
                retenue: !_masquee,
                onPress: () => setState(() => _masquee = false),
              ),
            ],
          ),
          Ecart.vXs,
          Text(
            _masquee
                ? t.admin.agents.identiteMasqueeDetail
                : t.admin.agents.identiteVisibleDetail,
            style: textes.bodySmall,
          ),
          Ecart.vXxl,

          // « Pourra » et « Ne pourra pas » de rang egal : quand on accorde un
          // acces, la question utile est ce qu'il n'ouvre pas.
          const _PourraNePourraPas(),
          Ecart.vXxl,

          ActionPrincipale(
            libelle: t.admin.agents.emettre,
            enCours: _emission,
            onPress: _emissionPossible ? _emettre : null,
          ),
        ],
      ),
    );
  }

  Widget _liste(BuildContext context) {
    if (_chargement) {
      return const Skeleton.liste();
    }
    if (_erreur != null) {
      // Registre **actionnable**, et pas « subi » : `EmptyState` ne rend son
      // bouton que dans ce registre. Declare en subi, le « Reessayer » ci-dessous
      // n'a jamais existe a l'ecran, et une lecture en echec laissait
      // l'administration sans aucun geste.
      return EmptyState(
        message: t.admin.agents.erreur,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: () => unawaited(_charger()),
      );
    }
    if (_jetons.isEmpty) {
      return EmptyState(
        message: t.admin.agents.vide,
        invitation: t.admin.agents.videDetail,
        icone: AppIcons.rienAAfficher,
        registre: RegistreVide.bonneNouvelle,
      );
    }

    return DataCollection<JetonAgent>(
      lignes: _jetons,
      colonnes: <ColonneDonnees<JetonAgent>>[
        ColonneDonnees<JetonAgent>(
          titre: t.admin.agents.colonneLibelle,
          role: RoleColonne.identifiante,
          flex: 2,
          texte: (JetonAgent j) => j.libelle,
        ),
        ColonneDonnees<JetonAgent>(
          titre: t.admin.agents.colonneQui,
          flex: 2,
          texte: (JetonAgent j) => j.observeLibelle,
        ),
        ColonneDonnees<JetonAgent>(
          titre: t.admin.agents.colonneParcours,
          texte: (JetonAgent j) => _nomParcours(j.parcours),
        ),
        ColonneDonnees<JetonAgent>(
          titre: t.admin.agents.colonneIdentite,
          texte: (JetonAgent j) => j.identiteMasquee
              ? t.admin.agents.identiteMasquee
              : t.admin.agents.identiteVisible,
        ),
        ColonneDonnees<JetonAgent>(
          titre: t.admin.agents.colonneExpire,
          tabulaire: true,
          texte: (JetonAgent j) => _quand(j.expireLe),
        ),
        ColonneDonnees<JetonAgent>(
          titre: t.admin.agents.colonneUsage,
          tabulaire: true,
          texte: (JetonAgent j) =>
              j.jamaisServi ? t.admin.agents.jamaisServi : '${j.remises}',
        ),
        ColonneDonnees<JetonAgent>(
          titre: t.admin.agents.colonneEtat,
          texte: (JetonAgent j) => _nomEtat(j.etat),
          rendu: (BuildContext _, JetonAgent j) => Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              StatusPill(libelle: _nomEtat(j.etat), ton: _tonEtat(j.etat)),
              if (j.etat == EtatJeton.actif) ...<Widget>[
                Ecart.hSm,
                ActionPrincipale(
                  libelle: t.admin.agents.revoquer,
                  niveau: NiveauAction.destructive,
                  pleineLargeur: false,
                  onPress: () => unawaited(_revoquer(j)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _nomEtat(EtatJeton etat) => switch (etat) {
    EtatJeton.actif => t.admin.agents.etatActif,
    EtatJeton.revoque => t.admin.agents.etatRevoque,
    EtatJeton.expire => t.admin.agents.etatExpire,
  };

  TonEtat _tonEtat(EtatJeton etat) => switch (etat) {
    EtatJeton.actif => TonEtat.succes,
    EtatJeton.revoque => TonEtat.alerte,
    EtatJeton.expire => TonEtat.neutre,
  };

  String _nomParcours(AppRole? role) => switch (role) {
    AppRole.student => t.admin.agents.parcoursEleve,
    AppRole.guardian => t.admin.agents.parcoursTuteur,
    AppRole.teacher => t.admin.agents.parcoursEnseignant,
    AppRole.controller => t.admin.agents.parcoursControleur,
    AppRole.admin => t.admin.agents.parcoursAdmin,
    AppRole.accountant => t.admin.agents.parcoursComptable,
    null => t.admin.agents.parcoursInconnu,
  };

  String _quand(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

/// Ce que le jeton ouvre, et ce qu'il n'ouvre pas, de rang egal.
class _PourraNePourraPas extends StatelessWidget {
  const _PourraNePourraPas();

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(t.admin.agents.pourra, style: textes.titleSmall),
              Ecart.vXs,
              Text(t.admin.agents.pourraDetail, style: textes.bodySmall),
            ],
          ),
        ),
        Ecart.hXl,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(t.admin.agents.nePourraPas, style: textes.titleSmall),
              Ecart.vXs,
              Text(t.admin.agents.nePourraPasDetail, style: textes.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// La liste des personnes observables.
class _ChoixPersonne extends StatelessWidget {
  const _ChoixPersonne({
    required this.personnes,
    required this.choisie,
    required this.onChoix,
  });

  final List<PersonneObservable> personnes;
  final PersonneObservable? choisie;
  final void Function(PersonneObservable personne) onChoix;

  @override
  Widget build(BuildContext context) {
    if (personnes.isEmpty) {
      return EmptyState(
        message: t.admin.agents.quiVide,
        registre: RegistreVide.subi,
        icone: AppIcons.rienAAfficher,
      );
    }
    // Choix de formulaire, pas un filtre : la personne observable.
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final PersonneObservable p in personnes.take(40))
          FilterPill(
            libelle: p.libelle,
            retenue: choisie?.id == p.id,
            onPress: () => onChoix(p),
          ),
      ],
    );
  }
}

/// Le secret, montre une seule fois.
class _CarteJetonEmis extends StatelessWidget {
  const _CarteJetonEmis({
    required this.emis,
    required this.onCopier,
    required this.onTermine,
  });

  final JetonEmis emis;
  final Future<void> Function(String lien) onCopier;
  final VoidCallback onTermine;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final String lien = Routes.entreePour(emis.secret);

    return AppCard(
      contourFort: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(AppIcons.succes.repos),
              Ecart.hSm,
              Text(t.admin.agents.emis, style: textes.titleMedium),
            ],
          ),
          Ecart.vSm,
          Text(t.admin.agents.emisDetail, style: textes.bodySmall),
          Ecart.vLg,
          SelectableText(lien, style: textes.bodySmall),
          Ecart.vLg,
          ActionPrincipale(
            libelle: t.admin.agents.copier,
            niveau: NiveauAction.secondaire,
            onPress: () => unawaited(onCopier(lien)),
          ),
          Ecart.vSm,
          ActionPrincipale(
            libelle: t.admin.agents.termine,
            niveau: NiveauAction.tertiaire,
            onPress: onTermine,
          ),
        ],
      ),
    );
  }
}
