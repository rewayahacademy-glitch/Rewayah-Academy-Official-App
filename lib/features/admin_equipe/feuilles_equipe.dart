// BE-2b : les feuilles de l'ecran « Equipe » : nouvelle mission, accorder une
// mission, retirer une mission, archiver une mission, inviter une personne,
// revoquer une invitation, et le detail d'une attribution.
//
// Accorder, retirer, creer, archiver et inviter sont des actions SENSIBLES
// (DECISION-FLUIDITE) : on les attend, avec l'animation du bouton (`enCours`),
// jamais d'effet avant la reponse du serveur. Le serveur exige la direction en
// double verification : en aal1, le code est demande puis le geste rejoue
// (`avecDoubleVerification`). Une cle d'idempotence est gardee tant que rien n'a
// change, pour rejouer un essai non confirme sans rien ecrire deux fois.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_candidature.dart' show EtapeCandidature;
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/equipe/modeles_equipe.dart';
import '../../core/equipe/port_equipe.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/champ_date.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/zone_saisie.dart';
import '../admin_candidatures/libelles_candidatures.dart' show libelleSalle;
import '../candidature/libelles_parcours.dart' show nomDeLangue;
import '../candidature/modele_questions.dart' show languesDuPublic;
import '../mfa_controleur/double_verification.dart';
import 'libelles_equipe.dart';

/// Une cle de geste neuve : un uuid (les portes de l'equipe l'exigent).
String nouvelleCleEquipe() => const Uuid().v4();

/// La phrase d'un refus ou d'un echec, en mots (jamais le texte du serveur, et
/// jamais « connexion » pour un refus).
String messageErreurEquipe(Object e) {
  final r = t.admin.equipe.refus;
  return switch (e) {
    RefusEquipe(:final CauseRefusEquipe cause) => switch (cause) {
      CauseRefusEquipe.personneIndisponible => r.personneIndisponible,
      CauseRefusEquipe.genreInconnu => r.genreInconnu,
      CauseRefusEquipe.attributionActive => r.attributionActive,
      CauseRefusEquipe.missionIndisponible => r.missionIndisponible,
      CauseRefusEquipe.parametresInvalides => r.parametresInvalides,
      CauseRefusEquipe.cleDejaUtilisee => r.cleDejaUtilisee,
      CauseRefusEquipe.gestesNonAdmis => r.gestesNonAdmis,
      CauseRefusEquipe.autre => r.autre,
    },
    PermissionInsuffisante() => r.permission,
    CapaciteIndisponible() => t.admin.equipe.indisponiblePhrase,
    _ => r.nonConfirme,
  };
}

/// L'envoi commun des feuilles : un seul a la fois, la double verification
/// demandee au besoin, le refus garde dans la feuille, la cle gardee pour
/// rejouer un essai non confirme.
mixin EnvoiEquipe<W extends ConsumerStatefulWidget> on ConsumerState<W> {
  /// Vrai pendant l'attente du serveur.
  bool enCours = false;

  /// Vrai apres un essai : les manques se disent.
  bool tente = false;

  /// Le refus ou l'echec du dernier essai.
  Object? refus;

  /// La cle de l'essai en cours.
  String? cle;

  /// Un champ change : c'est une autre demande, avec une autre cle.
  void modifie(VoidCallback changement) => setState(() {
    changement();
    cle = null;
    refus = null;
  });

  /// Envoie [geste] et rend le message de retour par [fini], ou garde le refus.
  Future<void> envoyer(
    Future<String> Function(PortEquipe port, String cle) geste,
    ValueChanged<String> fini,
  ) async {
    if (enCours) return;
    final PortEquipe? port = ref.read(portEquipeProvider);
    setState(() {
      enCours = true;
      refus = null;
    });
    try {
      if (port == null) {
        throw const CapaciteIndisponible(dependanceEquipe);
      }
      final String c = cle ??= nouvelleCleEquipe();
      final String m = await avecDoubleVerification<String>(
        context,
        ref,
        () => geste(port, c),
      );
      if (!mounted) return;
      fini(m);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        enCours = false;
        refus = e;
        // Un refus nomme n'a rien ecrit : un nouvel essai est une autre
        // demande. Une panne inconnue garde la cle, pour rejouer.
        if (e is RefusEquipe || e is PermissionInsuffisante) cle = null;
      });
    }
  }

  /// Le bandeau du refus, ou rien.
  List<Widget> bandeauRefus() {
    final Object? r = refus;
    if (r == null) return const <Widget>[];
    final bool nonConfirme = r is! RefusEquipe && r is! PermissionInsuffisante;
    return <Widget>[
      Ecart.vLg,
      BandeauAttention(
        key: const ValueKey<String>('equipe-refus'),
        titre: nonConfirme
            ? t.admin.candidatures.erreurs.nonConfirmeTitre
            : t.admin.equipe.refus.echecTitre,
        message: messageErreurEquipe(r),
        ton: nonConfirme ? TonEtat.avertissement : TonEtat.alerte,
      ),
    ];
  }

  /// Le bouton qui envoie, et celui qui renonce.
  List<Widget> boutons({
    required String libelle,
    required VoidCallback onEnvoyer,
    required VoidCallback onAnnuler,
    bool destructif = false,
  }) => <Widget>[
    Ecart.vXxl,
    ActionPrincipale(
      key: const ValueKey<String>('equipe-valider'),
      libelle: libelle,
      onPress: onEnvoyer,
      enCours: enCours,
      niveau: destructif ? NiveauAction.destructive : NiveauAction.principale,
    ),
    Ecart.vMd,
    ActionPrincipale(
      key: const ValueKey<String>('equipe-annuler'),
      libelle: t.admin.equipe.feuille.annuler,
      onPress: onAnnuler,
      niveau: NiveauAction.secondaire,
    ),
  ];
}

Widget _consequence(BuildContext context, String texte) => Text(
  texte,
  style: AppPalette.of(context).surfaceRaised
      .applyTo(Theme.of(context).textTheme.bodyLarge ?? const TextStyle()),
);

Widget _titreChamp(BuildContext context, String texte) => Semantics(
  header: true,
  child: TexteSansCoupure(
    texte,
    style: Theme.of(context).textTheme.titleMedium,
  ),
);

Widget _aide(BuildContext context, String texte) => Text(
  texte,
  style: AppPalette.of(context).inkMuted
      .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle()),
);

Widget _manque(BuildContext context, String texte) => Padding(
  padding: const EdgeInsets.only(top: AppSpacing.sm),
  child: TexteSansCoupure(
    texte,
    style: AppPalette.of(context).inkAlert
        .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle()),
  ),
);

/// Ce que montre une lecture en attente ou en echec dans une feuille.
Widget _etatLecture(AsyncValue<Object?> v, String echec) {
  if (v.hasError) {
    return BandeauAttention(
      titre: t.admin.candidatures.erreurs.nonConfirmeTitre,
      message: v.error is CapaciteIndisponible
          ? t.admin.equipe.indisponiblePhrase
          : echec,
      ton: TonEtat.avertissement,
    );
  }
  return const Skeleton.texte(lignes: 3);
}

/// Le jour choisi a minuit, au fuseau du profil : le debut d'un jour.
DateTime _debutDeJour(DateTime j) =>
    instantChezMoi(j.year, j.month, j.day, 0, 0);

// ---------------------------------------------------------------------------
// Nouvelle mission
// ---------------------------------------------------------------------------

/// La feuille « Nouvelle mission » : un nom et les gestes que le serveur admet.
class FeuilleNouvelleMission extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleNouvelleMission({
    required this.onFini,
    required this.onAnnuler,
    super.key,
  });

  /// Le geste est fait : le message du retour local.
  final ValueChanged<String> onFini;

  /// La personne renonce.
  final VoidCallback onAnnuler;

  @override
  ConsumerState<FeuilleNouvelleMission> createState() => _EtatNouvelleMission();
}

class _EtatNouvelleMission extends ConsumerState<FeuilleNouvelleMission>
    with EnvoiEquipe<FeuilleNouvelleMission> {
  final TextEditingController _nom = TextEditingController();
  final Set<String> _gestes = <String>{};

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  String get _nomPropre => _nom.text.trim();

  bool get _complet =>
      _nomPropre.isNotEmpty && _nomPropre.length <= 80 && _gestes.isNotEmpty;

  Future<void> _valider() async {
    if (!_complet) {
      setState(() => tente = true);
      return;
    }
    final List<String> gestes = <String>[..._gestes]..sort();
    await envoyer((PortEquipe port, String c) async {
      await port.creerMission(nom: _nomPropre, gestes: gestes, cle: c);
      return t.admin.equipe.feuille.mission.creee;
    }, widget.onFini);
  }

  @override
  Widget build(BuildContext context) {
    final f = t.admin.equipe.feuille.mission;
    final AsyncValue<List<String>> ouverts = ref.watch(gestesOuvertsProvider);
    return Column(
      key: const ValueKey<String>('feuille-nouvelle-mission'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ZoneSaisie(
          cleChamp: const ValueKey<String>('equipe-nom-mission'),
          controleur: _nom,
          libelle: f.nom,
          explication: f.nomAide,
          erreur: tente && _nomPropre.isEmpty
              ? f.nomManquant
              : _nomPropre.length > 80
              ? f.nomTropLong
              : null,
          onChanged: (String _) => modifie(() {}),
        ),
        Ecart.vLg,
        _titreChamp(context, f.gestes),
        Ecart.vSm,
        _aide(context, f.gestesAide),
        Ecart.vMd,
        if (ouverts.hasValue)
          ChoiceCardGroup(
            key: const ValueKey<String>('equipe-gestes'),
            selectionMultiple: true,
            autoriserSaisieLibre: false,
            options: <OptionChoix>[
              for (final String g in ouverts.requireValue)
                OptionChoix(
                  cle: ValueKey<String>('geste-$g'),
                  valeur: g,
                  libelle: libelleGesteMission(g),
                ),
            ],
            valeurInitiale: ReponseChoix(valeurs: Set<String>.of(_gestes)),
            onChange: (ReponseChoix r) => modifie(() {
              _gestes
                ..clear()
                ..addAll(r.valeurs);
            }),
          )
        else
          _etatLecture(ouverts, f.gestesIndisponibles),
        if (tente && _gestes.isEmpty) _manque(context, f.gestesManquants),
        ...bandeauRefus(),
        ...boutons(
          libelle: f.creer,
          onEnvoyer: _valider,
          onAnnuler: widget.onAnnuler,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Accorder une mission
// ---------------------------------------------------------------------------

/// Les salles proposees dans un perimetre (les trois salles de la candidature).
const List<EtapeCandidature> sallesProposees = <EtapeCandidature>[
  EtapeCandidature.prequalification,
  EtapeCandidature.verifications,
  EtapeCandidature.confirmee,
];

/// La feuille « Accorder une mission » : la personne, la mission, le perimetre
/// (langues, salles ; le cote est celui de la personne, jamais choisi), le
/// debut et la fin, et une phrase de resume avant de valider.
class FeuilleAccorderMission extends ConsumerStatefulWidget {
  /// Cree la feuille. [personneInitiale] : une personne deja choisie.
  const FeuilleAccorderMission({
    required this.onFini,
    required this.onAnnuler,
    this.personneInitiale,
    super.key,
  });

  /// Le geste est fait : le message du retour local.
  final ValueChanged<String> onFini;

  /// La personne renonce.
  final VoidCallback onAnnuler;

  /// L'identifiant d'une personne deja choisie (depuis sa ligne).
  final String? personneInitiale;

  @override
  ConsumerState<FeuilleAccorderMission> createState() => _EtatAccorder();
}

class _EtatAccorder extends ConsumerState<FeuilleAccorderMission>
    with EnvoiEquipe<FeuilleAccorderMission> {
  late String? _personne = widget.personneInitiale;
  String? _mission;
  final Set<String> _langues = <String>{};
  final Set<EtapeCandidature> _salles = <EtapeCandidature>{};
  DateTime? _debut;
  DateTime? _fin;

  bool get _complet => _personne != null && _mission != null;

  Future<void> _valider() async {
    if (!_complet) {
      setState(() => tente = true);
      return;
    }
    // La fin choisie est « jusqu'a ce jour inclus » : le debut du lendemain.
    final DateTime? fin = _fin == null
        ? null
        : _debutDeJour(_fin!.add(const Duration(days: 1)));
    final DateTime? debut = _debut == null ? null : _debutDeJour(_debut!);
    await envoyer((PortEquipe port, String c) async {
      await port.accorder(
        profil: _personne!,
        mission: _mission!,
        langues: <String>[..._langues],
        etapes: <String>[for (final EtapeCandidature e in _salles) e.valeurSql],
        debut: debut,
        fin: fin,
        cle: c,
      );
      return t.admin.equipe.feuille.accorder.accordee;
    }, widget.onFini);
  }

  /// La phrase qui dit ce que la personne pourra faire, avant de valider.
  String? _resume(PersonneMission? p, Mission? m) {
    if (p == null || m == null) return null;
    final PerimetreMission perimetre = PerimetreMission(
      langues: <String>[..._langues],
      etapes: <EtapeCandidature>[..._salles],
    );
    return t.admin.equipe.feuille.accorder.resume(
      nom: p.nom,
      gestes: phraseGestes(m.gestes),
      perimetre: phrasePerimetre(perimetre),
      duree: phraseDuree(
        _fin == null ? null : _debutDeJour(_fin!.add(const Duration(days: 1))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = t.admin.equipe.feuille.accorder;
    final AsyncValue<List<PersonneMission>> personnes = ref.watch(
      personnesMissionProvider,
    );
    final AsyncValue<List<Mission>> missions = ref.watch(missionsProvider);
    final DateTime maintenant = chezMoi(ref.read(horlogeFormulairesProvider)());
    final DateTime aujourdhui = DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day,
    );
    final List<PersonneMission> lesPersonnes =
        personnes.value ?? const <PersonneMission>[];
    final List<Mission> lesMissions = <Mission>[
      for (final Mission m in missions.value ?? const <Mission>[])
        if (!m.archivee) m,
    ];
    PersonneMission? choisie;
    for (final PersonneMission p in lesPersonnes) {
      if (p.id == _personne) choisie = p;
    }
    Mission? retenue;
    for (final Mission m in lesMissions) {
      if (m.id == _mission) retenue = m;
    }
    final String? resume = _resume(choisie, retenue);
    final String? cote = libelleCoteEquipe(choisie?.cote);

    return Column(
      key: const ValueKey<String>('feuille-accorder-mission'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _titreChamp(context, f.personne),
        Ecart.vSm,
        if (personnes.hasValue)
          lesPersonnes.isEmpty
              ? _aide(context, f.aucunePersonne)
              : ChoiceCardGroup(
                  key: const ValueKey<String>('equipe-personne'),
                  autoriserSaisieLibre: false,
                  options: <OptionChoix>[
                    for (final PersonneMission p in lesPersonnes)
                      OptionChoix(
                        cle: ValueKey<String>('personne-${p.id}'),
                        valeur: p.id,
                        libelle: p.nom,
                        description: libelleRoleEquipe(p.role),
                      ),
                  ],
                  valeurInitiale: _personne == null
                      ? null
                      : ReponseChoix(valeurs: <String>{_personne!}),
                  onChange: (ReponseChoix r) => modifie(
                    () =>
                        _personne = r.valeurs.isEmpty ? null : r.valeurs.first,
                  ),
                )
        else
          _etatLecture(personnes, f.aucunePersonne),
        if (tente && _personne == null) _manque(context, f.personneManquante),
        Ecart.vLg,
        _titreChamp(context, f.mission),
        Ecart.vSm,
        if (missions.hasValue)
          lesMissions.isEmpty
              ? _aide(context, f.aucuneMission)
              : ChoiceCardGroup(
                  key: const ValueKey<String>('equipe-mission'),
                  autoriserSaisieLibre: false,
                  options: <OptionChoix>[
                    for (final Mission m in lesMissions)
                      OptionChoix(
                        cle: ValueKey<String>('mission-${m.id}'),
                        valeur: m.id,
                        libelle: m.nom,
                        description: phraseGestes(m.gestes),
                      ),
                  ],
                  valeurInitiale: _mission == null
                      ? null
                      : ReponseChoix(valeurs: <String>{_mission!}),
                  onChange: (ReponseChoix r) => modifie(
                    () => _mission = r.valeurs.isEmpty ? null : r.valeurs.first,
                  ),
                )
        else
          _etatLecture(missions, f.aucuneMission),
        if (tente && _mission == null) _manque(context, f.missionManquante),
        Ecart.vLg,
        _titreChamp(context, f.perimetre),
        Ecart.vSm,
        // Le cote n'est jamais choisi : le serveur l'ecrit, celui de la
        // personne. L'ecran le dit en clair.
        if (cote != null)
          Text(
            key: const ValueKey<String>('equipe-cote'),
            t.admin.equipe.cote.ligne(cote: cote),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        Ecart.vMd,
        _titreChamp(context, f.langues),
        Ecart.vSm,
        _aide(context, f.languesAide),
        Ecart.vSm,
        ChoiceCardGroup(
          key: const ValueKey<String>('equipe-langues'),
          selectionMultiple: true,
          autoriserSaisieLibre: false,
          options: <OptionChoix>[
            for (final String c in languesDuPublic)
              if (c != 'autre')
                OptionChoix(
                  cle: ValueKey<String>('langue-$c'),
                  valeur: c,
                  libelle: nomDeLangue(c) ?? c,
                ),
          ],
          valeurInitiale: ReponseChoix(valeurs: Set<String>.of(_langues)),
          onChange: (ReponseChoix r) => modifie(() {
            _langues
              ..clear()
              ..addAll(r.valeurs);
          }),
        ),
        Ecart.vLg,
        _titreChamp(context, f.salles),
        Ecart.vSm,
        _aide(context, f.sallesAide),
        Ecart.vSm,
        ChoiceCardGroup(
          key: const ValueKey<String>('equipe-salles'),
          selectionMultiple: true,
          autoriserSaisieLibre: false,
          options: <OptionChoix>[
            for (final EtapeCandidature e in sallesProposees)
              OptionChoix(
                cle: ValueKey<String>('salle-${e.valeurSql}'),
                valeur: e.valeurSql,
                libelle: libelleSalle(e) ?? e.valeurSql,
              ),
          ],
          valeurInitiale: ReponseChoix(
            valeurs: <String>{
              for (final EtapeCandidature e in _salles) e.valeurSql,
            },
          ),
          onChange: (ReponseChoix r) => modifie(() {
            _salles
              ..clear()
              ..addAll(<EtapeCandidature>[
                for (final EtapeCandidature e in sallesProposees)
                  if (r.valeurs.contains(e.valeurSql)) e,
              ]);
          }),
        ),
        Ecart.vLg,
        ChampDate(
          libelle: f.debut,
          valeur: _debut,
          aujourdhui: aujourdhui,
          aide: f.debutAide,
          onChoix: (DateTime j) => modifie(() => _debut = j),
        ),
        Ecart.vLg,
        ChampDate(
          libelle: f.fin,
          valeur: _fin,
          aujourdhui: aujourdhui,
          aide: f.finAide,
          onChoix: (DateTime j) => modifie(() => _fin = j),
        ),
        Ecart.vLg,
        Text(
          key: const ValueKey<String>('equipe-resume'),
          resume ?? f.resumeVide,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        ...bandeauRefus(),
        ...boutons(
          libelle: f.accorder,
          onEnvoyer: _valider,
          onAnnuler: widget.onAnnuler,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Retirer, archiver, revoquer : un motif ecrit
// ---------------------------------------------------------------------------

/// Ce que fait la feuille a motif.
enum GesteAMotif {
  /// Retirer une attribution.
  retirer,

  /// Archiver une mission.
  archiver,

  /// Revoquer une invitation.
  revoquer,
}

/// La feuille d'un geste qui exige un motif ecrit : retirer une mission,
/// archiver une mission, revoquer une invitation. La consequence se dit avant.
class FeuilleAMotif extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleAMotif({
    required this.geste,
    required this.cible,
    required this.nom,
    required this.onFini,
    required this.onAnnuler,
    super.key,
  });

  /// Ce que la feuille fait.
  final GesteAMotif geste;

  /// L'identifiant de ce qui est retire, archive ou revoque.
  final String cible;

  /// Le nom qui parle dans la phrase : la mission, la personne ou l'adresse ;
  /// pour retirer, `nom` est la personne et [mission] la mission.
  final String nom;

  /// Le geste est fait : le message du retour local.
  final ValueChanged<String> onFini;

  /// La personne renonce.
  final VoidCallback onAnnuler;

  /// La mission retiree (pour la phrase de retrait).
  String? get mission => _mission;

  static String? _mission;

  @override
  ConsumerState<FeuilleAMotif> createState() => _EtatAMotif();
}

class _EtatAMotif extends ConsumerState<FeuilleAMotif>
    with EnvoiEquipe<FeuilleAMotif> {
  final TextEditingController _motif = TextEditingController();

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final String motif = _motif.text.trim();
    if (motif.isEmpty) {
      setState(() => tente = true);
      return;
    }
    await envoyer((PortEquipe port, String c) async {
      switch (widget.geste) {
        case GesteAMotif.retirer:
          await port.retirer(attribution: widget.cible, motif: motif, cle: c);
          return t.admin.equipe.feuille.retirer.retiree(nom: widget.nom);
        case GesteAMotif.archiver:
          await port.archiverMission(id: widget.cible, motif: motif, cle: c);
          return t.admin.equipe.feuille.archiver.archivee;
        case GesteAMotif.revoquer:
          await port.revoquer(id: widget.cible, motif: motif, cle: c);
          return t.admin.equipe.feuille.revoquer.revoquee;
      }
    }, widget.onFini);
  }

  @override
  Widget build(BuildContext context) {
    final f = t.admin.equipe.feuille;
    final (String consequence, String bouton) = switch (widget.geste) {
      GesteAMotif.retirer => (
        f.retirer.consequence(nom: widget.nom),
        f.retirer.retirer,
      ),
      GesteAMotif.archiver => (f.archiver.consequence, f.archiver.archiver),
      GesteAMotif.revoquer => (f.revoquer.consequence, f.revoquer.revoquer),
    };
    return Column(
      key: const ValueKey<String>('feuille-a-motif'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _consequence(context, consequence),
        Ecart.vLg,
        ZoneSaisie(
          cleChamp: const ValueKey<String>('equipe-motif'),
          controleur: _motif,
          libelle: f.motif,
          explication: f.motifAide,
          erreur: tente && _motif.text.trim().isEmpty ? f.motifManquant : null,
          minLignes: 3,
          onChanged: (String _) => modifie(() {}),
        ),
        ...bandeauRefus(),
        ...boutons(
          libelle: bouton,
          onEnvoyer: _valider,
          onAnnuler: widget.onAnnuler,
          destructif: true,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Inviter une personne
// ---------------------------------------------------------------------------

/// La feuille « Inviter une personne » : une adresse et un nom facultatif.
class FeuilleInviter extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleInviter({
    required this.onFini,
    required this.onAnnuler,
    super.key,
  });

  /// Le geste est fait : le message du retour local.
  final ValueChanged<String> onFini;

  /// La personne renonce.
  final VoidCallback onAnnuler;

  @override
  ConsumerState<FeuilleInviter> createState() => _EtatInviter();
}

class _EtatInviter extends ConsumerState<FeuilleInviter>
    with EnvoiEquipe<FeuilleInviter> {
  final TextEditingController _courriel = TextEditingController();
  final TextEditingController _nom = TextEditingController();

  @override
  void dispose() {
    _courriel.dispose();
    _nom.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final String courriel = _courriel.text.trim();
    if (courriel.isEmpty) {
      setState(() => tente = true);
      return;
    }
    final String nom = _nom.text.trim();
    await envoyer((PortEquipe port, String c) async {
      final ResultatInvitation r = await port.inviter(
        courriel: courriel,
        nom: nom.isEmpty ? null : nom,
        cle: c,
      );
      final f = t.admin.equipe.feuille.inviter;
      final String code = r.invitation?.code ?? '';
      switch (r.statut) {
        case StatutInvitation.creee:
          return f.creee(code: code);
        case StatutInvitation.dejaInvite:
          return f.dejaInvite(code: code);
        case StatutInvitation.emailInvalide:
          throw const RefusPhrase();
        case StatutInvitation.compteExistant:
          throw const RefusPhrase(compteExistant: true);
      }
    }, widget.onFini);
  }

  @override
  Widget build(BuildContext context) {
    final f = t.admin.equipe.feuille.inviter;
    final Object? r = refus;
    return Column(
      key: const ValueKey<String>('feuille-inviter'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _consequence(context, f.consequence),
        Ecart.vLg,
        ZoneSaisie(
          cleChamp: const ValueKey<String>('equipe-courriel'),
          controleur: _courriel,
          libelle: f.courriel,
          erreur: tente && _courriel.text.trim().isEmpty
              ? f.courrielManquant
              : null,
          actionClavier: TextInputAction.next,
          onChanged: (String _) => modifie(() {}),
        ),
        Ecart.vLg,
        ZoneSaisie(
          cleChamp: const ValueKey<String>('equipe-nom-invite'),
          controleur: _nom,
          libelle: f.nom,
          onChanged: (String _) => modifie(() {}),
        ),
        if (r is RefusPhrase) ...<Widget>[
          Ecart.vLg,
          BandeauAttention(
            key: const ValueKey<String>('equipe-refus'),
            titre: t.admin.equipe.refus.echecTitre,
            message: r.compteExistant ? f.compteExistant : f.emailInvalide,
            ton: TonEtat.alerte,
          ),
        ] else
          ...bandeauRefus(),
        ...boutons(
          libelle: f.envoyer,
          onEnvoyer: _valider,
          onAnnuler: widget.onAnnuler,
        ),
      ],
    );
  }
}

/// Un refus de l'invitation que le serveur rend comme une reponse, pas comme
/// une erreur : adresse illisible, compte deja existant.
class RefusPhrase implements Exception {
  /// Cree le refus.
  const RefusPhrase({this.compteExistant = false});

  /// Vrai : un compte existe deja avec cette adresse.
  final bool compteExistant;
}

// ---------------------------------------------------------------------------
// Le detail d'une attribution
// ---------------------------------------------------------------------------

/// Le detail d'une attribution : la mission, la personne, le perimetre en mots,
/// la periode et les gestes. Lecture seule.
class FeuilleDetailAttribution extends StatelessWidget {
  /// Cree la feuille.
  const FeuilleDetailAttribution({required this.attribution, super.key});

  /// L'attribution lue.
  final Attribution attribution;

  @override
  Widget build(BuildContext context) {
    final f = t.admin.equipe.detail;
    final Attribution a = attribution;
    Widget ligne(String titre, String valeur) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(titre, style: Theme.of(context).textTheme.labelLarge),
          Text(valeur, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
    final String? cote = libelleCoteEquipe(a.perimetre.cote);
    return Column(
      key: const ValueKey<String>('feuille-detail-attribution'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ligne(f.mission, a.mission),
        ligne(f.personne, a.nom.isEmpty ? f.sansNom : a.nom),
        ligne(
          f.perimetre,
          <String>[
            if (cote != null) t.admin.equipe.cote.ligne(cote: cote),
            phrasePerimetre(a.perimetre),
          ].join(' · '),
        ),
        ligne(
          f.periode,
          '${t.admin.equipe.depuisLe(date: _date(a.debut))} · ${phraseDuree(a.fin)}',
        ),
        if (a.retiree && a.motifRetrait != null)
          ligne(f.retiree(motif: a.motifRetrait!), a.motifRetrait!),
      ],
    );
  }

  String _date(DateTime d) =>
      '${d.toLocal().day.toString().padLeft(2, '0')}/${d.toLocal().month.toString().padLeft(2, '0')}/${d.toLocal().year}';
}
