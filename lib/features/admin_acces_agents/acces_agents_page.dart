import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/agent/service_agent.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/champ_date.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/selecteur_personne.dart';
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

  List<JetonAgent> _jetons = <JetonAgent>[];
  List<PersonneObservable> _personnes = <PersonneObservable>[];
  PersonneObservable? _choisie;
  int _duree = 8;
  bool _masquee = true;

  /// Vrai des que la personne a ecrit elle-meme le libelle : la proposition
  /// automatique ne le touche plus.
  bool _libelleSaisi = false;

  /// La raison affichee quand on presse « Emettre » avec un champ manquant.
  String? _erreurFormulaire;

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

  /// Ce qui manque encore, nul quand tout est la : le bouton ne grise jamais,
  /// il dit ce qui manque (K-56).
  String? get _manque => _choisie == null
      ? t.admin.agents.manquePersonne
      : _libelle.text.trim().isEmpty
      ? t.admin.agents.manqueLibelle
      : null;

  /// Propose « Observation de Maryam, le 04/10/2026, 8 h » tant que la
  /// personne qui emet n'a pas ecrit son propre libelle (FORM-L12). Une
  /// proposition se modifie ; un libelle ecrit a la main n'est jamais ecrase.
  void _preremplir() {
    final PersonneObservable? qui = _choisie;
    if (qui == null || _libelleSaisi) {
      return;
    }
    _libelle.text = LibellesGroupe.insecable(
      t.admin.agents.libelleAuto(
        dePrenom: deDevant(
          qui.prenom.isEmpty ? qui.identifiant : qui.prenom,
          cle: 'admin.agents.libelleAuto',
        ),
        date: ChampDate.ecrire(ref.read(horlogeFormulairesProvider)()),
        duree: _duree,
      ),
    );
  }

  Future<void> _emettre() async {
    if (_emission) {
      return;
    }
    final PersonneObservable? qui = _choisie;
    if (qui == null || _manque != null) {
      setState(() => _erreurFormulaire = _manque);
      return;
    }
    setState(() {
      _emission = true;
      _message = null;
      _erreurFormulaire = null;
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
        _libelleSaisi = false;
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
          ChampEtiquete(
            libelle: t.admin.agents.libelle,
            controller: _libelle,
            onChanged: (String texte) => setState(() {
              // Vider le champ rend la main a la proposition automatique.
              _libelleSaisi = texte.trim().isNotEmpty;
              _erreurFormulaire = null;
            }),
            textCapitalization: TextCapitalization.sentences,
            // Le libelle prerempli (« Observation de ..., le ..., 24 h ») est long :
            // il passe a la ligne au lieu de se couper (FORM-MINEURS).
            maxLines: 6,
            aide: t.admin.agents.libelleAide,
            indice: t.admin.agents.libelleExemple,
          ),
          Ecart.vXxl,

          // Le meme selecteur que les autres formulaires (K-10) : titre,
          // recherche sur le nom et l'identifiant, cartes de choix.
          SelecteurPersonne(
            sorte: SortePersonne.observable,
            personnes: _erreur != null
                ? AsyncValue<List<PersonneProposee>>.error(
                    _erreur!,
                    StackTrace.empty,
                  )
                : _chargement
                ? const AsyncValue<List<PersonneProposee>>.loading()
                : AsyncValue<List<PersonneProposee>>.data(<PersonneProposee>[
                    for (final PersonneObservable p in _personnes)
                      PersonneProposee(
                        id: p.id,
                        nom: p.libelleNom,
                        identifiant: p.identifiant,
                      ),
                  ]),
            choisie: _choisie?.id,
            onReessayer: () => unawaited(_charger()),
            onChoix: (PersonneProposee choisie) => setState(() {
              _choisie = _personnes.firstWhere(
                (PersonneObservable p) => p.id == choisie.id,
              );
              _erreurFormulaire = null;
              _preremplir();
            }),
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
                  onPress: () => setState(() {
                    _duree = h;
                    _preremplir();
                  }),
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

          if (_erreurFormulaire != null) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                _erreurFormulaire!,
                style: textes.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
            Ecart.vMd,
          ],
          ActionPrincipale(
            libelle: t.admin.agents.emettre,
            enCours: _emission,
            onPress: _emettre,
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
