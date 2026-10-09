import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/planning/service_planning.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/menu_filtre.dart';
import 'plages.dart';

/// Les raccourcis de la feuille (DISPO-1, decides par delegation le 09/10).
///
/// « Soiree » : 17 h a 23 h, la plage que le directeur cite en exemple.
/// « Matinee » : 8 h a 12 h. « Week-end » : samedi et dimanche, sans toucher
/// aux heures.
abstract final class RaccourcisPlage {
  /// Debut de la soiree.
  static const int soireeDe = 17;

  /// Fin de la soiree.
  static const int soireeA = 23;

  /// Debut de la matinee.
  static const int matineeDe = 8;

  /// Fin de la matinee.
  static const int matineeA = 12;

  /// Samedi et dimanche, jours ISO.
  static const Set<int> weekEnd = <int>{6, 7};
}

/// Le corps de la feuille « Ajouter une plage » / « Modifier la plage ».
///
/// Trois choix, aucune saisie au clavier (K-57 : choisi plutot que saisi) :
/// les jours en puces a choix multiple, « de » et « a » dans deux listes ; et
/// trois raccourcis. « a » est toujours strictement apres « de » : la liste
/// de fin ne propose que les heures qui suivent le debut.
///
/// **Le serveur ne change pas** (K-19) : la plage s'enregistre heure par
/// heure par [ServicePlanning.poser] et [ServicePlanning.retirer]. Une plage
/// qui chevauche ou touche une plage deja posee la rejoint ; la feuille le dit
/// AVANT d'enregistrer. Un echec partiel nomme les heures non confirmees.
class FeuillePlage extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuillePlage({
    required this.profilId,
    required this.fuseau,
    required this.existantes,
    required this.engagees,
    required this.onEcrit,
    super.key,
    this.engagementsConfirmes = true,
    this.modifiee,
  });

  /// Le profil de l'enseignant.
  final String profilId;

  /// Le fuseau de ses heures.
  final String fuseau;

  /// Les heures deja posees a l'ouverture.
  final Set<HeureSemaine> existantes;

  /// Les heures qui portent deja une Classe.
  final Set<HeureSemaine> engagees;

  /// Faux quand les Classes engagees n'ont pas pu etre lues : tout retrait
  /// est alors confirme, prudemment, puisqu'un conflit ne peut pas etre
  /// exclu.
  final bool engagementsConfirmes;

  /// La plage touchee pour la modifier ; nulle pour un ajout.
  final Plage? modifiee;

  /// Appele apres chaque envoi, meme partiel : la liste se relit.
  final VoidCallback onEcrit;

  @override
  ConsumerState<FeuillePlage> createState() => _FeuillePlageEtat();
}

class _FeuillePlageEtat extends ConsumerState<FeuillePlage> {
  late final Set<int> _jours;
  late int _de;
  late int _a;

  /// Les heures posees, tenues a jour pendant la vie de la feuille : apres un
  /// echec partiel, un second envoi ne renvoie que ce qui manque.
  late Set<HeureSemaine> _existantes;

  /// La plage touchee a l'ouverture. Elle ne change pas pendant la vie de
  /// la feuille : ce qui en reste a retirer se lit toujours contre
  /// [_existantes] (`planifier`), jamais contre une plage recalculee qui
  /// perdrait des morceaux apres un echec partiel.
  Plage? _modifiee;

  /// Vrai apres un envoi dont une operation n'est pas confirmee : le
  /// prochain envoi relit d'abord les heures posees (une ecriture non
  /// confirmee a pu passer quand meme).
  bool _aRelire = false;

  bool _envoi = false;
  bool _manqueJour = false;
  String? _echec;

  @override
  void initState() {
    super.initState();
    final Plage? p = widget.modifiee;
    _modifiee = p;
    _existantes = <HeureSemaine>{...widget.existantes};
    _jours = <int>{if (p != null) p.jour};
    // K-57 : deduit d'abord. Une plage touchee donne ses heures ; un ajout
    // part de la soiree, la plage que cite le directeur.
    _de = p?.de ?? RaccourcisPlage.soireeDe;
    _a = p?.a ?? RaccourcisPlage.soireeA;
  }

  void _heures(int de, int a) => setState(() {
    _de = de;
    _a = a;
    _echec = null;
  });

  void _basculerJour(int jour) => setState(() {
    if (!_jours.remove(jour)) {
      _jours.add(jour);
    }
    _manqueJour = false;
    _echec = null;
  });

  PlanPlage get _plan => planifier(
    existantes: _existantes,
    jours: _jours,
    de: _de,
    a: _a,
    modifiee: _modifiee,
  );

  Creneau _creneau(HeureSemaine h) =>
      Creneau(jour: h.jour, heure: h.heure, fuseau: widget.fuseau);

  /// Les heures engagees parmi [retraits].
  List<HeureSemaine> _engageesParmi(List<HeureSemaine> retraits) =>
      retraits.where(widget.engagees.contains).toList();

  /// Demande confirmation quand un retrait touche une heure engagee, ou
  /// quand les engagements ne sont pas confirmes. Retirer n'annule aucun
  /// cours : la confirmation le dit.
  Future<bool> _confirmerRetrait(
    List<HeureSemaine> retraits,
    List<HeureSemaine> engagees,
  ) {
    if (retraits.isEmpty || (engagees.isEmpty && widget.engagementsConfirmes)) {
      return Future<bool>.value(true);
    }
    final List<HeureSemaine> visees = engagees.isEmpty ? retraits : engagees;
    final String heures = visees.map(nommerHeure).join(', ');
    return ConfirmDestructive.demander(
      context,
      question: t.enseignant.creneaux.confirmerRetraitQuestion(heures: heures),
      consequence: engagees.isEmpty
          ? t.enseignant.creneaux.retraitSansEngagements(heures: heures)
          : t.enseignant.creneaux.confirmerRetraitConsequence(heures: heures),
      libelleConfirmer: t.enseignant.creneaux.confirmerRetraitAction,
    );
  }

  /// Relit les heures posees apres un echec ; garde ce que la feuille sait
  /// si la relecture echoue elle aussi.
  Future<void> _relire() async {
    if (!_aRelire) {
      return;
    }
    try {
      final List<Creneau> lues = await ref
          .read(servicePlanningProvider)
          .disponibilites(widget.profilId);
      _existantes = heuresDe(lues);
    } on Object {
      // La feuille garde son etat : ajouts et retraits non confirmes y sont
      // toujours a faire.
    }
  }

  /// Le message d'un envoi dont des operations ne sont pas confirmees :
  /// chaque sens nomme ses heures, puis la cause probable, puis quoi faire.
  /// Jamais ce que le serveur a ou n'a pas fait (D5).
  String _messageEchec(
    List<HeureSemaine> ajouts,
    List<HeureSemaine> retraits,
    String action,
  ) => <String>[
    if (ajouts.isNotEmpty)
      t.enseignant.creneaux.ajoutNonConfirme(
        heures: ajouts.map(nommerHeure).join(', '),
      ),
    if (retraits.isNotEmpty)
      t.enseignant.creneaux.retraitNonConfirme(
        heures: retraits.map(nommerHeure).join(', '),
      ),
    t.enseignant.creneaux.echecCause,
    t.enseignant.creneaux.echecQuoiFaire(action: action),
  ].join(' ');

  /// Pose puis retire, heure par heure ; rend les operations non confirmees,
  /// par sens.
  Future<({List<HeureSemaine> ajouts, List<HeureSemaine> retraits})> _ecrire({
    required List<HeureSemaine> ajouts,
    required List<HeureSemaine> retraits,
  }) async {
    final ServicePlanning service = ref.read(servicePlanningProvider);
    final List<HeureSemaine> ajoutsEchoues = <HeureSemaine>[];
    final List<HeureSemaine> retraitsEchoues = <HeureSemaine>[];
    for (final HeureSemaine h in ajouts) {
      try {
        await service.poser(profilId: widget.profilId, creneau: _creneau(h));
        _existantes.add(h);
      } on Object {
        ajoutsEchoues.add(h);
      }
    }
    for (final HeureSemaine h in retraits) {
      try {
        await service.retirer(profilId: widget.profilId, creneau: _creneau(h));
        _existantes.remove(h);
      } on Object {
        retraitsEchoues.add(h);
      }
    }
    _aRelire = ajoutsEchoues.isNotEmpty || retraitsEchoues.isNotEmpty;
    widget.onEcrit();
    return (ajouts: ajoutsEchoues, retraits: retraitsEchoues);
  }

  Future<void> _enregistrer() async {
    if (_jours.isEmpty) {
      setState(() => _manqueJour = true);
      return;
    }
    if (_envoi) {
      return;
    }
    await _relire();
    if (!mounted) {
      return;
    }
    // Le plan se recalcule a chaque envoi contre les heures posees : apres un
    // echec, il contient exactement les poses ET les retraits encore non
    // confirmes, tous renvoyes.
    final PlanPlage plan = _plan;
    final List<int> jours = _jours.toList()..sort();
    final String jourLus = jours
        .map((int j) => t.disponibilites.joursLongs[j - 1])
        .join(', ');
    final String reussite = t.enseignant.creneaux.plageEnregistree(
      jours: jourLus,
      de: libelleDe(_de),
      a: libelleA(_a),
    );
    if (plan.vide) {
      Navigator.of(context).pop(reussite);
      return;
    }
    final List<HeureSemaine> engagees = _engageesParmi(plan.retraits);
    if (!await _confirmerRetrait(plan.retraits, engagees) || !mounted) {
      return;
    }
    setState(() {
      _envoi = true;
      _echec = null;
    });
    final ({List<HeureSemaine> ajouts, List<HeureSemaine> retraits}) echecs =
        await _ecrire(ajouts: plan.ajouts, retraits: plan.retraits);
    if (!mounted) {
      return;
    }
    // Succes seulement quand TOUTES les operations sont confirmees.
    if (echecs.ajouts.isEmpty && echecs.retraits.isEmpty) {
      Navigator.of(context).pop(
        engagees.isEmpty
            ? reussite
            : '$reussite ${t.enseignant.creneaux.seanceContinue(heures: engagees.map(nommerHeure).join(', '))}',
      );
      return;
    }
    setState(() {
      _envoi = false;
      _echec = _messageEchec(
        echecs.ajouts,
        echecs.retraits,
        t.enseignant.creneaux.enregistrerPlage,
      );
    });
  }

  Future<void> _supprimer() async {
    final Plage? plage = _modifiee;
    // Un envoi en cours : le geste attend sa fin plutot que de doubler.
    if (plage == null || _envoi) {
      return;
    }
    await _relire();
    if (!mounted) {
      return;
    }
    final List<HeureSemaine> retraits =
        plage.heures.intersection(_existantes).toList()..sort(
          (HeureSemaine x, HeureSemaine y) => x.heure.compareTo(y.heure),
        );
    final List<HeureSemaine> engagees = _engageesParmi(retraits);
    if (!await _confirmerRetrait(retraits, engagees) || !mounted) {
      return;
    }
    setState(() {
      _envoi = true;
      _echec = null;
    });
    final ({List<HeureSemaine> ajouts, List<HeureSemaine> retraits}) echecs =
        await _ecrire(ajouts: const <HeureSemaine>[], retraits: retraits);
    if (!mounted) {
      return;
    }
    if (echecs.retraits.isEmpty) {
      final String supprimee = t.enseignant.creneaux.plageSupprimee(
        jour: t.disponibilites.joursLongs[plage.jour - 1],
        de: libelleDe(plage.de),
        a: libelleA(plage.a),
      );
      Navigator.of(context).pop(
        engagees.isEmpty
            ? supprimee
            : '$supprimee ${t.enseignant.creneaux.seanceContinue(heures: engagees.map(nommerHeure).join(', '))}',
      );
      return;
    }
    setState(() {
      _envoi = false;
      _echec = _messageEchec(
        const <HeureSemaine>[],
        echecs.retraits,
        t.enseignant.creneaux.supprimerPlage,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;
    // Reseau perdu feuille ouverte : les actions ne sont plus rendues (jamais
    // grisees), une phrase dit pourquoi, comme sous la liste.
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final PlanPlage plan = _plan;
    final Plage? modifiee = _modifiee;
    final List<HeureSemaine> engageesModifiee = modifiee == null
        ? const <HeureSemaine>[]
        : (widget.engagees.where(modifiee.contient).toList()..sort(
            (HeureSemaine x, HeureSemaine y) => x.heure.compareTo(y.heure),
          ));
    final TextStyle etiquette = textes.labelLarge ?? const TextStyle();
    final TextStyle detail = textes.bodySmall ?? const TextStyle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TexteSansCoupure(
          t.enseignant.creneaux.feuilleContexte,
          style: textes.bodyMedium,
        ),
        Ecart.vLg,
        // Raccourcis : chacun dit ce qu'il regle (K-58). L'etat retenu se lit
        // sur la puce elle-meme, jamais par la seule couleur (FilterPill).
        TexteSansCoupure(t.enseignant.creneaux.raccourcis, style: etiquette),
        Ecart.vSm,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            FilterPill(
              libelle: t.enseignant.creneaux.raccourciSoiree,
              retenue:
                  _de == RaccourcisPlage.soireeDe &&
                  _a == RaccourcisPlage.soireeA,
              onPress: () =>
                  _heures(RaccourcisPlage.soireeDe, RaccourcisPlage.soireeA),
            ),
            FilterPill(
              libelle: t.enseignant.creneaux.raccourciMatinee,
              retenue:
                  _de == RaccourcisPlage.matineeDe &&
                  _a == RaccourcisPlage.matineeA,
              onPress: () =>
                  _heures(RaccourcisPlage.matineeDe, RaccourcisPlage.matineeA),
            ),
            FilterPill(
              libelle: t.enseignant.creneaux.raccourciWeekEnd,
              retenue:
                  _jours.length == 2 &&
                  _jours.containsAll(RaccourcisPlage.weekEnd),
              onPress: () => setState(() {
                _jours
                  ..clear()
                  ..addAll(RaccourcisPlage.weekEnd);
                _manqueJour = false;
                _echec = null;
              }),
            ),
          ],
        ),
        Ecart.vSm,
        TexteSansCoupure(t.enseignant.creneaux.raccourcisDetail, style: detail),
        Ecart.vLg,
        TexteSansCoupure(t.enseignant.creneaux.jours, style: etiquette),
        Ecart.vSm,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (int jour = 1; jour <= 7; jour++)
              FilterPill(
                libelle: jourCapitalise(jour),
                retenue: _jours.contains(jour),
                onPress: () => _basculerJour(jour),
              ),
          ],
        ),
        Ecart.vLg,
        TexteSansCoupure(t.enseignant.creneaux.heures, style: etiquette),
        Ecart.vSm,
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            MenuFiltre<int>(
              libelle: t.enseignant.creneaux.menuDe,
              valeur: _de,
              entrees: <EntreeFiltre<int>>[
                for (int h = 0; h < 24; h++)
                  EntreeFiltre<int>(valeur: h, libelle: libelleDe(h)),
              ],
              onChoix: (int? h) {
                if (h == null) return;
                // « a » reste strictement apres « de » : il suit le debut
                // quand le debut le rattrape.
                _heures(h, _a > h ? _a : h + 1);
              },
            ),
            MenuFiltre<int>(
              libelle: t.enseignant.creneaux.menuA,
              valeur: _a,
              entrees: <EntreeFiltre<int>>[
                for (int h = _de + 1; h <= 24; h++)
                  EntreeFiltre<int>(valeur: h, libelle: libelleA(h)),
              ],
              onChoix: (int? h) {
                if (h == null || h <= _de) return;
                _heures(_de, h);
              },
            ),
          ],
        ),
        // Le chevauchement se dit AVANT d'enregistrer : la plage rejoint
        // celle qui est deja posee, elle ne s'y superpose pas.
        for (final Plage fusion in plan.fusions) ...<Widget>[
          Ecart.vMd,
          TexteSansCoupure(
            t.enseignant.creneaux.fusion(
              jour: jourCapitalise(fusion.jour),
              de: libelleDe(fusion.de),
              a: libelleA(fusion.a),
            ),
            style: textes.bodyMedium,
          ),
        ],
        // Une plage identique ou contenue ne reunit rien : elle se dit deja
        // posee, jamais comme une fusion (DISPO-1b).
        for (final Plage posee in plan.dejaPosees) ...<Widget>[
          Ecart.vMd,
          TexteSansCoupure(
            t.enseignant.creneaux.dejaPosee(
              jour: jourCapitalise(posee.jour),
              de: libelleDe(posee.de),
              a: libelleA(posee.a),
            ),
            style: textes.bodyMedium,
          ),
        ],
        if (engageesModifiee.isNotEmpty) ...<Widget>[
          Ecart.vMd,
          TexteSansCoupure(
            engageesModifiee.length == 1
                ? t.enseignant.creneaux.heureEngagee(
                    heures: nommerHeure(engageesModifiee.single),
                  )
                : t.enseignant.creneaux.heuresEngagees(
                    heures: engageesModifiee.map(nommerHeure).join(', '),
                  ),
            style: palette.inkWarning.applyTo(detail),
          ),
        ],
        if (_manqueJour) ...<Widget>[
          Ecart.vMd,
          TexteSansCoupure(
            t.enseignant.creneaux.manqueJour,
            style: palette.inkAlert.applyTo(textes.bodyMedium ?? detail),
          ),
        ],
        if (_echec != null) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: TexteSansCoupure(
              _echec!,
              style: palette.inkAlert.applyTo(textes.bodyMedium ?? detail),
            ),
          ),
        ],
        if (horsLigne) ...<Widget>[
          Ecart.vXxl,
          TexteSansCoupure(
            t.enseignant.creneaux.horsLigneFeuille,
            style: palette.inkWarning.applyTo(textes.bodyMedium ?? detail),
          ),
        ] else ...<Widget>[
          Ecart.vXxl,
          // K-56 : le seul bouton plein de la feuille, en bas, au bord de fin.
          // La suppression, destructive, vient avant lui et n'est jamais pleine.
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              if (modifiee != null)
                ActionPrincipale(
                  libelle: t.enseignant.creneaux.supprimerPlage,
                  niveau: NiveauAction.destructive,
                  pleineLargeur: false,
                  onPress: _supprimer,
                ),
              ActionPrincipale(
                libelle: t.enseignant.creneaux.enregistrerPlage,
                pleineLargeur: !bureau,
                enCours: _envoi,
                onPress: _enregistrer,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
