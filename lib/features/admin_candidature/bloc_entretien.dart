// V2-a (04/11/2026) : la section Entretien de la fiche candidature (`ADM-21`),
// dans la carte « Piece et entretien ».
//
// Ce que la direction y fait, sur les RPC de V1-a et V1-a-bis :
// - **planifier** l'entretien (jour, heure, duree, participants choisis
//   librement dans le personnel de ce cote, plus le super-admin) ; la regle
//   des fondateurs est dite avant le choix, et son refus en mots ;
// - **ajouter ou retirer** un participant d'un entretien ouvert ;
// - **consigner l'issue** (tenu, annule, candidat absent, personne qui menait
//   l'entretien absente ; motif interne sauf pour « tenu ») ;
// - **lire** les comptes rendus des participants et les entrees et sorties de
//   la salle.
//
// **Le serveur decide de tout.** Les gestes ne sont proposes que si le
// serveur les ouvre (`capacites_candidatures`) et depuis l'etat qu'il a rendu ;
// le compte des fondateurs et le minimum en vigueur sont lus, jamais calcules.
// Un widget lit une capacite, jamais un role. Chaque geste passe par une
// feuille de confirmation ; le succes ne se dit qu'apres la reponse du serveur.
//
// Etats : chargement (`Skeleton`), aucun entretien, entretien ouvert, dernier
// entretien consigne, erreur (« Reessayer »), hors ligne (aucun geste, la
// derniere lecture reste), capacite indisponible (« Disponible au branchement
// serveur »).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/gestes_candidature.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidature_detail.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/modeles_entretien_direction.dart';
import '../../core/candidature/port_entretiens_direction.dart';
import '../../core/candidature/port_ma_candidature.dart'
    show nouvelleCleIdempotence;
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/i18n/dates_appareil.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/champ_date.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/zone_saisie.dart';
import '../admin_candidatures/libelles_candidatures.dart'
    show dateCourteCandidature;
import 'libelles_candidature.dart' show messageRefus;

/// La section Entretien d'une candidature lue.
class SectionEntretien extends ConsumerWidget {
  /// Cree la section.
  const SectionEntretien({
    required this.detail,
    required this.capacites,
    required this.horsLigne,
    required this.onFait,
    super.key,
  });

  /// Le dossier lu : sa version est la version attendue des gestes.
  final DetailCandidature detail;

  /// Les capacites lues au serveur.
  final CapacitesCandidatures capacites;

  /// Hors ligne : aucun geste.
  final bool horsLigne;

  /// Un geste est fait : la page relit la candidature et dit [message].
  final ValueChanged<String> onFait;

  /// La cle de la section.
  static const Key cle = ValueKey<String>('entretien-section');

  /// La cle du bouton « Planifier l'entretien ».
  static const Key clePlanifier = ValueKey<String>('entretien-planifier');

  String get _candidature => detail.ligne.id;

  /// Planifier est propose quand le serveur l'ouvre et que la candidature
  /// attend un entretien (etat rendu par le serveur).
  bool get _peutPlanifier {
    final LigneCandidature l = detail.ligne;
    return !horsLigne &&
        capacites.peutDecider &&
        capacites.peutChoisirParticipants &&
        capacites.geste('planifierEntretien') &&
        l.issue == IssueCandidature.enCours &&
        !l.enPause &&
        l.etat == EtatCandidature.entretienAPlanifier;
  }

  void _fait(WidgetRef ref, String message) {
    ref.invalidate(entretiensCandidatureProvider(_candidature));
    onFait(message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = t.admin.candidatures.entretien;
    final AsyncValue<List<EntretienCandidature>> valeur = ref.watch(
      entretiensCandidatureProvider(_candidature),
    );
    final Widget corps;
    if (valeur.hasValue) {
      final List<EntretienCandidature> liste = valeur.requireValue;
      EntretienCandidature? ouvert;
      for (final EntretienCandidature x in liste) {
        if (x.ouvert) ouvert = x;
      }
      if (ouvert != null) {
        corps = _EntretienOuvert(
          entretien: ouvert,
          detail: detail,
          capacites: capacites,
          horsLigne: horsLigne,
          onFait: (String m) => _fait(ref, m),
        );
      } else {
        final EntretienCandidature? dernier = liste.isEmpty ? null : liste.last;
        corps = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _Muet(
              dernier == null
                  ? e.aucun
                  : e.dernier(
                      date: dateCourteCandidature(dernier.debut),
                      issue: libelleIssueEntretien(dernier.issue!),
                    ),
            ),
            if (_peutPlanifier) ...<Widget>[
              Ecart.vMd,
              ActionPrincipale(
                key: clePlanifier,
                libelle: e.planifier,
                niveau: NiveauAction.secondaire,
                pleineLargeur: false,
                onPress: () async {
                  final String? m = await _ouvrir(
                    context,
                    e.planifier,
                    (VoidCallback fermer, ValueChanged<String> fini) =>
                        FeuillePlanifierEntretien(
                          detail: detail,
                          capacites: capacites,
                          onFini: fini,
                          onAnnuler: fermer,
                        ),
                  );
                  if (m != null) _fait(ref, m);
                },
              ),
            ],
          ],
        );
      }
    } else if (valeur.hasError) {
      final Object erreur = valeur.error!;
      corps = erreur is CapaciteIndisponible
          ? _Muet(t.commun.etats.branchementServeur)
          : erreur is PermissionInsuffisante
          ? _Muet(t.admin.candidatures.accesRefuse)
          : EtatSysteme(
              nature: NatureEtat.echecServeur,
              titre: e.lectureEchec,
              phrase: '',
              onAction: () =>
                  ref.invalidate(entretiensCandidatureProvider(_candidature)),
            );
    } else {
      corps = const Skeleton.texte(lignes: 2);
    }
    return KeyedSubtree(key: cle, child: corps);
  }
}

/// Ouvre une feuille d'entretien et rend le message du retour local, ou
/// `null` si la personne y a renonce.
Future<String?> _ouvrir(
  BuildContext context,
  String titre,
  Widget Function(VoidCallback fermer, ValueChanged<String> fini) corps,
) => AppBottomSheet.ouvrir<String>(
  context,
  titre: titre,
  constructeur: (BuildContext contexte) => corps(
    () => Navigator.of(contexte).pop(),
    (String m) => Navigator.of(contexte).pop(m),
  ),
);

/// L'entretien ouvert : la date, les fondateurs, les participants, les
/// comptes rendus et les presences, et ses gestes.
class _EntretienOuvert extends ConsumerWidget {
  const _EntretienOuvert({
    required this.entretien,
    required this.detail,
    required this.capacites,
    required this.horsLigne,
    required this.onFait,
  });

  final EntretienCandidature entretien;
  final DetailCandidature detail;
  final CapacitesCandidatures capacites;
  final bool horsLigne;
  final ValueChanged<String> onFait;

  void _relu(WidgetRef ref, String m) {
    ref.invalidate(detailEntretienProvider(entretien.sessionId));
    onFait(m);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = t.admin.candidatures.entretien;
    final TextTheme textes = Theme.of(context).textTheme;
    final DateTime local = entretien.debut.toLocal();
    final bool choisir =
        !horsLigne &&
        capacites.peutDecider &&
        capacites.peutChoisirParticipants;
    final bool consigner =
        !horsLigne &&
        capacites.peutDecider &&
        capacites.geste('consignerEntretien');
    final AsyncValue<DetailEntretien> valeur = ref.watch(
      detailEntretienProvider(entretien.sessionId),
    );

    Widget titre(String s) => Semantics(
      header: true,
      child: TexteSansCoupure(s, style: textes.titleSmall),
    );

    final List<Widget> lu;
    if (valeur.hasValue) {
      final DetailEntretien d = valeur.requireValue;
      String nom(String id) => d.nomDe(id) ?? e.auteurInconnu;
      lu = <Widget>[
        Ecart.vLg,
        titre(e.participants),
        Ecart.vSm,
        for (final ParticipantEntretien p in d.actifs)
          Padding(
            key: ValueKey<String>('entretien-participant-${p.profilId}'),
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                TexteSansCoupure(p.nomComplet, style: textes.bodyMedium),
                if (p.fondateur)
                  StatusPill(libelle: e.fondateur, ton: TonEtat.accent),
                if (choisir && d.actifs.length > 1)
                  LienFleche(
                    key: ValueKey<String>('entretien-retirer-${p.profilId}'),
                    libelle: e.retirer,
                    libelleSemantique: e.retirerNom(nom: p.nomComplet),
                    fleche: false,
                    onPress: () async {
                      final String? m = await _ouvrir(
                        context,
                        e.retirerNom(nom: p.nomComplet),
                        (VoidCallback fermer, ValueChanged<String> fini) =>
                            FeuilleRetirerParticipant(
                              sessionId: entretien.sessionId,
                              participant: p,
                              onFini: fini,
                              onAnnuler: fermer,
                            ),
                      );
                      if (m != null) _relu(ref, m);
                    },
                  ),
              ],
            ),
          ),
        if (choisir)
          LienFleche(
            key: const ValueKey<String>('entretien-ajouter'),
            libelle: e.ajouter,
            alignerEnDebut: true,
            onPress: () async {
              final String? m = await _ouvrir(
                context,
                e.ajouter,
                (VoidCallback fermer, ValueChanged<String> fini) =>
                    FeuilleAjouterParticipant(
                      sessionId: entretien.sessionId,
                      candidatureId: detail.ligne.id,
                      deja: <String>{
                        for (final ParticipantEntretien p in d.actifs)
                          p.profilId,
                      },
                      onFini: fini,
                      onAnnuler: fermer,
                    ),
              );
              if (m != null) _relu(ref, m);
            },
          ),
        Ecart.vLg,
        titre(e.comptesRendus),
        Ecart.vSm,
        if (d.comptesRendus.isEmpty)
          _Muet(e.aucunCompteRendu)
        else
          for (final CompteRenduEntretien c in d.comptesRendus)
            Padding(
              key: ValueKey<String>('entretien-compte-rendu-${c.auteurId}'),
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      TexteSansCoupure(
                        nom(c.auteurId),
                        style: textes.labelLarge,
                      ),
                      if (c.avis case final AvisEntretien a)
                        StatusPill(libelle: libelleAvis(a), ton: _tonAvis(a)),
                    ],
                  ),
                  Ecart.vXs,
                  Text(c.texte, style: textes.bodyMedium),
                ],
              ),
            ),
        Ecart.vLg,
        titre(e.presences),
        Ecart.vSm,
        if (d.presences.isEmpty)
          _Muet(e.aucunePresence)
        else
          for (final PresenceEntretien p in d.presences)
            _Muet(
              p.arrivee
                  ? e.entree(
                      nom: nom(p.profilId),
                      heure: heureDeLAppareil(p.le.toLocal()),
                    )
                  : e.sortie(
                      nom: nom(p.profilId),
                      heure: heureDeLAppareil(p.le.toLocal()),
                    ),
            ),
      ];
    } else if (valeur.hasError) {
      lu = <Widget>[
        Ecart.vMd,
        if (valeur.error is CapaciteIndisponible)
          _Muet(t.commun.etats.branchementServeur)
        else
          EtatSysteme(
            nature: NatureEtat.echecServeur,
            titre: e.lectureEchec,
            phrase: '',
            onAction: () =>
                ref.invalidate(detailEntretienProvider(entretien.sessionId)),
          ),
      ];
    } else {
      lu = const <Widget>[Ecart.vMd, Skeleton.texte(lignes: 3)];
    }

    final int? exiges = capacites.fondateursExiges;
    return Column(
      key: ValueKey<String>('entretien-ouvert-${entretien.sessionId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(
          e.quand(
            date: dateCourteCandidature(entretien.debut),
            heure: heureDeLAppareil(local),
            duree: '${entretien.dureeMinutes}',
          ),
          style: textes.bodyLarge,
        ),
        Ecart.vXs,
        _Muet(e.fondateurs(n: '${entretien.fondateurs}')),
        if (capacites.peutDecider)
          _Muet(exiges == null ? e.regleInactive : e.minimum(n: '$exiges')),
        ...lu,
        if (consigner) ...<Widget>[
          Ecart.vLg,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionPrincipale(
              key: const ValueKey<String>('entretien-consigner'),
              libelle: e.consigner,
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
              onPress: () async {
                final String? m = await _ouvrir(
                  context,
                  e.consigner,
                  (VoidCallback fermer, ValueChanged<String> fini) =>
                      FeuilleConsignerEntretien(
                        sessionId: entretien.sessionId,
                        detail: detail,
                        onFini: fini,
                        onAnnuler: fermer,
                      ),
                );
                if (m != null) _relu(ref, m);
              },
            ),
          ),
        ],
      ],
    );
  }
}

TonEtat _tonAvis(AvisEntretien a) => switch (a) {
  AvisEntretien.favorable => TonEtat.succes,
  AvisEntretien.reserve => TonEtat.avertissement,
  AvisEntretien.defavorable => TonEtat.neutre,
};

/// Le libelle d'un avis de compte rendu.
String libelleAvis(AvisEntretien a) {
  final v = t.admin.candidatures.entretien.avis;
  return switch (a) {
    AvisEntretien.favorable => v.favorable,
    AvisEntretien.reserve => v.reserve,
    AvisEntretien.defavorable => v.defavorable,
  };
}

/// Le libelle d'une issue d'entretien.
String libelleIssueEntretien(IssueEntretien i) {
  final v = t.admin.candidatures.entretien.issues;
  return switch (i) {
    IssueEntretien.tenu => v.tenu,
    IssueEntretien.annule => v.annule,
    IssueEntretien.manqueCandidat => v.manqueCandidat,
    IssueEntretien.manqueIntervieweur => v.manqueIntervieweur,
  };
}

/// Un refus d'un geste d'entretien, en mots (jamais par son code).
String messageRefusEntretien(Object refus) {
  final r = t.admin.candidatures.entretien.refus;
  final g = t.admin.candidatures.erreurs;
  return switch (refus) {
    FondateursInsuffisants(:final int exiges, :final int presents) =>
      r.fondateurs(exiges: '$exiges', presents: '$presents'),
    DebutInvalide() => r.debut,
    DureeInvalide() => r.duree,
    ParticipantsRequis() =>
      t.admin.candidatures.entretien.feuille.participantsManquants,
    ParticipantsTropNombreux() => r.tropNombreux,
    ParticipantNonAutorise() => r.nonAutorise,
    ParticipantAutreCote() => r.autreCote,
    CandidatSansCompte() => r.sansCompte,
    EntretienDejaPlanifie() => r.dejaPlanifie,
    EntretienConsigne() => r.consigne,
    DernierParticipant() => r.dernier,
    ParticipantAbsent() => r.absent,
    CompteRenduRequis() => r.compteRendu,
    EntretienIntrouvable() => r.introuvable,
    final RefusGeste geste => messageRefus(geste),
    CandidatureHorsPortee() => g.horsPortee,
    CandidatureIntrouvable() => g.absente,
    PermissionInsuffisante() => g.permission,
    _ => g.generique,
  };
}

// ---------------------------------------------------------------------------
// L'envoi commun des feuilles
// ---------------------------------------------------------------------------

/// L'envoi d'une feuille d'entretien : un seul a la fois, le refus garde dans
/// la feuille, la cle d'idempotence gardee pour rejouer un essai non confirme.
mixin _EnvoiEntretien<W extends ConsumerStatefulWidget> on ConsumerState<W> {
  bool enCours = false;
  bool tente = false;
  Object? refus;
  String? cle;

  /// Un champ change : c'est une autre demande, avec une autre cle.
  void modifie(VoidCallback changement) => setState(() {
    changement();
    cle = null;
    if (refus is GesteNonConfirme) refus = null;
  });

  /// Envoie [geste] et rend son retour local par [fini], ou garde le refus.
  Future<void> envoyer(
    Future<String> Function(PortEntretiensDirection port, String cle) geste,
    ValueChanged<String> fini,
  ) async {
    if (enCours) return;
    final PortEntretiensDirection? port = ref.read(
      portEntretiensDirectionProvider,
    );
    setState(() {
      enCours = true;
      refus = null;
    });
    try {
      if (port == null) {
        throw const CapaciteIndisponible(dependanceEntretiens);
      }
      final String m = await geste(port, cle ??= nouvelleCleIdempotence());
      if (!mounted) return;
      fini(m);
    } on GesteNonConfirme catch (e) {
      if (!mounted) return;
      setState(() {
        enCours = false;
        refus = e;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        enCours = false;
        refus = e;
        // Un refus nomme n'a rien ecrit : un nouvel essai est une autre
        // demande. Une panne inconnue garde la cle, pour rejouer.
        if (e is RefusEntretien || e is RefusGeste) cle = null;
      });
    }
  }

  /// Le bandeau du refus, ou rien.
  List<Widget> bandeauRefus() {
    final Object? r = refus;
    if (r == null) return const <Widget>[];
    final bool nonConfirme =
        r is GesteNonConfirme ||
        (r is! RefusEntretien &&
            r is! RefusGeste &&
            r is! PermissionInsuffisante);
    final g = t.admin.candidatures.erreurs;
    return <Widget>[
      Ecart.vLg,
      BandeauAttention(
        key: const ValueKey<String>('entretien-refus'),
        titre: nonConfirme ? g.nonConfirmeTitre : g.titre,
        message: messageRefusEntretien(r),
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
      key: const ValueKey<String>('entretien-valider'),
      libelle: refus is GesteNonConfirme ? t.commun.reessayer : libelle,
      onPress: onEnvoyer,
      enCours: enCours,
      niveau: destructif ? NiveauAction.destructive : NiveauAction.principale,
    ),
    Ecart.vMd,
    ActionPrincipale(
      key: const ValueKey<String>('entretien-annuler'),
      libelle: t.commun.annuler,
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

Widget _erreurChamp(BuildContext context, String texte) => Padding(
  padding: const EdgeInsets.only(top: AppSpacing.sm),
  child: TexteSansCoupure(
    texte,
    style: AppPalette.of(context).inkAlert
        .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle()),
  ),
);

/// Le personnel lu, ou l'etat de sa lecture.
Widget _etatPersonnel(
  WidgetRef ref,
  String candidature,
  AsyncValue<List<PersonnelEntretien>> v,
) {
  final f = t.admin.candidatures.entretien.feuille;
  if (v.hasError) {
    return v.error is CapaciteIndisponible
        ? _Muet(t.commun.etats.branchementServeur)
        : EtatSysteme(
            nature: NatureEtat.echecServeur,
            titre: f.personnelEchec,
            phrase: '',
            onAction: () =>
                ref.invalidate(personnelEntretienProvider(candidature)),
          );
  }
  return const Skeleton.texte(lignes: 3);
}

// ---------------------------------------------------------------------------
// Planifier
// ---------------------------------------------------------------------------

/// Les heures proposees : de 6 h a 21 h 30, par demi-heure (en minutes depuis
/// minuit, heure de cet appareil).
final List<int> heuresEntretien = List<int>.unmodifiable(<int>[
  for (int m = 6 * 60; m <= 21 * 60 + 30; m += 30) m,
]);

/// Les durees proposees, dans les bornes du serveur (15 a 120 minutes).
const List<int> dureesEntretien = <int>[30, 45, 60, 90];

/// La feuille « Planifier l'entretien ».
class FeuillePlanifierEntretien extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuillePlanifierEntretien({
    required this.detail,
    required this.capacites,
    required this.onFini,
    required this.onAnnuler,
    super.key,
  });

  /// Le dossier lu : sa version est la version attendue.
  final DetailCandidature detail;

  /// Les capacites : le minimum de fondateurs en vigueur.
  final CapacitesCandidatures capacites;

  /// Le geste est fait : le message du retour local.
  final ValueChanged<String> onFini;

  /// La personne renonce.
  final VoidCallback onAnnuler;

  @override
  ConsumerState<FeuillePlanifierEntretien> createState() => _EtatPlanifier();
}

class _EtatPlanifier extends ConsumerState<FeuillePlanifierEntretien>
    with _EnvoiEntretien<FeuillePlanifierEntretien> {
  DateTime? _jour;
  int? _heure;
  int? _duree = 45;
  final Set<String> _choisis = <String>{};

  String get _candidature => widget.detail.ligne.id;

  bool get _complet =>
      _jour != null && _heure != null && _duree != null && _choisis.isNotEmpty;

  Future<void> _valider() async {
    if (!_complet) {
      setState(() => tente = true);
      return;
    }
    final DateTime j = _jour!;
    final DateTime debut = DateTime(
      j.year,
      j.month,
      j.day,
      _heure! ~/ 60,
      _heure! % 60,
    );
    await envoyer((PortEntretiensDirection port, String cle) async {
      await port.planifier(
        candidatureId: _candidature,
        debut: debut,
        dureeMinutes: _duree!,
        participants: <String>[..._choisis],
        versionAttendue: widget.detail.version,
        cleIdempotence: cle,
      );
      return t.admin.candidatures.entretien.retours.planifie;
    }, widget.onFini);
  }

  @override
  Widget build(BuildContext context) {
    final e = t.admin.candidatures.entretien;
    final f = e.feuille;
    final DateTime maintenant = ref.read(horlogeFormulairesProvider)();
    final DateTime aujourdhui = DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day,
    );
    final AsyncValue<List<PersonnelEntretien>> personnel = ref.watch(
      personnelEntretienProvider(_candidature),
    );
    final int? exiges = widget.capacites.fondateursExiges;
    final List<PersonnelEntretien> liste =
        personnel.value ?? const <PersonnelEntretien>[];
    final int fondateursChoisis = <PersonnelEntretien>[
      for (final PersonnelEntretien p in liste)
        if (p.fondateur && _choisis.contains(p.profilId)) p,
    ].length;

    return Column(
      key: const ValueKey<String>('feuille-planifier-entretien'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _consequence(context, f.planifierConsequence),
        Ecart.vLg,
        ChampDate(
          libelle: f.jour,
          valeur: _jour,
          aujourdhui: aujourdhui,
          dernier: DateTime(
            aujourdhui.year,
            aujourdhui.month,
            aujourdhui.day + 89,
          ),
          aide: f.jourAide,
          onChoix: (DateTime j) => modifie(() => _jour = j),
        ),
        if (tente && _jour == null) _erreurChamp(context, f.jourManquant),
        Ecart.vLg,
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: <Widget>[
            MenuFiltre<int>(
              key: const ValueKey<String>('entretien-heure'),
              libelle: f.heure,
              valeur: _heure,
              entrees: <EntreeFiltre<int>>[
                for (final int m in heuresEntretien)
                  EntreeFiltre<int>(
                    valeur: m,
                    libelle: heureDeLAppareil(
                      DateTime(2000, 1, 1, m ~/ 60, m % 60),
                    ),
                  ),
              ],
              onChoix: (int? m) {
                if (m != null) modifie(() => _heure = m);
              },
            ),
            MenuFiltre<int>(
              key: const ValueKey<String>('entretien-duree'),
              libelle: f.duree,
              valeur: _duree,
              entrees: <EntreeFiltre<int>>[
                for (final int d in dureesEntretien)
                  EntreeFiltre<int>(
                    valeur: d,
                    libelle: f.dureeValeur(n: '$d'),
                  ),
              ],
              onChoix: (int? d) {
                if (d != null) modifie(() => _duree = d);
              },
            ),
          ],
        ),
        Ecart.vSm,
        _Muet(f.heureAide),
        if (tente && _heure == null) _erreurChamp(context, f.heureManquante),
        Ecart.vLg,
        _titreChamp(context, e.participants),
        Ecart.vSm,
        _Muet(f.participantsAide),
        if (exiges != null) _Muet(e.minimum(n: '$exiges')),
        Ecart.vSm,
        if (personnel.hasValue)
          if (liste.isEmpty)
            _Muet(f.personnelVide)
          else ...<Widget>[
            ChoiceCardGroup(
              selectionMultiple: true,
              autoriserSaisieLibre: false,
              options: <OptionChoix>[
                for (final PersonnelEntretien p in liste)
                  OptionChoix(
                    cle: ValueKey<String>('personnel-${p.profilId}'),
                    valeur: p.profilId,
                    libelle: p.nomComplet,
                    description: p.fondateur ? e.fondateur : null,
                  ),
              ],
              valeurInitiale: ReponseChoix(valeurs: Set<String>.of(_choisis)),
              onChange: (ReponseChoix r) => modifie(() {
                _choisis
                  ..clear()
                  ..addAll(r.valeurs);
              }),
            ),
            Ecart.vSm,
            _Muet(f.fondateursChoisis(n: '$fondateursChoisis')),
            if (tente && _choisis.isEmpty)
              _erreurChamp(context, f.participantsManquants),
          ]
        else
          _etatPersonnel(ref, _candidature, personnel),
        ...bandeauRefus(),
        ...boutons(
          libelle: f.envoyerPlanifier,
          onEnvoyer: _valider,
          onAnnuler: widget.onAnnuler,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Ajouter, retirer
// ---------------------------------------------------------------------------

/// La feuille « Ajouter un participant ».
class FeuilleAjouterParticipant extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleAjouterParticipant({
    required this.sessionId,
    required this.candidatureId,
    required this.deja,
    required this.onFini,
    required this.onAnnuler,
    super.key,
  });

  /// La seance de l'entretien.
  final String sessionId;

  /// La candidature : le personnel qu'on peut choisir.
  final String candidatureId;

  /// Les participants actifs, qui ne se proposent pas.
  final Set<String> deja;

  /// Le geste est fait : le message du retour local.
  final ValueChanged<String> onFini;

  /// La personne renonce.
  final VoidCallback onAnnuler;

  @override
  ConsumerState<FeuilleAjouterParticipant> createState() => _EtatAjouter();
}

class _EtatAjouter extends ConsumerState<FeuilleAjouterParticipant>
    with _EnvoiEntretien<FeuilleAjouterParticipant> {
  PersonnelEntretien? _choisi;

  @override
  Widget build(BuildContext context) {
    final e = t.admin.candidatures.entretien;
    final f = e.feuille;
    final AsyncValue<List<PersonnelEntretien>> personnel = ref.watch(
      personnelEntretienProvider(widget.candidatureId),
    );
    final List<PersonnelEntretien> libres = <PersonnelEntretien>[
      for (final PersonnelEntretien p
          in personnel.value ?? const <PersonnelEntretien>[])
        if (!widget.deja.contains(p.profilId)) p,
    ];
    final bool servi = personnel.hasValue && libres.isNotEmpty;
    return Column(
      key: const ValueKey<String>('feuille-ajouter-participant'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _consequence(context, f.ajouterConsequence),
        Ecart.vLg,
        _titreChamp(context, f.personne),
        Ecart.vSm,
        if (!personnel.hasValue)
          _etatPersonnel(ref, widget.candidatureId, personnel)
        else if (libres.isEmpty)
          _Muet(f.aucunAAjouter)
        else ...<Widget>[
          ChoiceCardGroup(
            autoriserSaisieLibre: false,
            options: <OptionChoix>[
              for (final PersonnelEntretien p in libres)
                OptionChoix(
                  cle: ValueKey<String>('personnel-${p.profilId}'),
                  valeur: p.profilId,
                  libelle: p.nomComplet,
                  description: p.fondateur ? e.fondateur : null,
                ),
            ],
            valeurInitiale: _choisi == null
                ? null
                : ReponseChoix(valeurs: <String>{_choisi!.profilId}),
            onChange: (ReponseChoix r) => modifie(() {
              _choisi = r.valeurs.isEmpty
                  ? null
                  : libres.firstWhere(
                      (PersonnelEntretien p) => p.profilId == r.valeurs.first,
                    );
            }),
          ),
          if (tente && _choisi == null)
            _erreurChamp(context, f.personneManquante),
        ],
        ...bandeauRefus(),
        if (servi)
          ...boutons(
            libelle: f.envoyerAjouter,
            onEnvoyer: () {
              final PersonnelEntretien? p = _choisi;
              if (p == null) {
                setState(() => tente = true);
                return;
              }
              envoyer((PortEntretiensDirection port, String _) async {
                await port.ajouter(widget.sessionId, p.profilId);
                return e.retours.ajoute(nom: p.nomComplet);
              }, widget.onFini);
            },
            onAnnuler: widget.onAnnuler,
          )
        else ...<Widget>[
          Ecart.vXxl,
          ActionPrincipale(
            key: const ValueKey<String>('entretien-annuler'),
            libelle: t.commun.annuler,
            onPress: widget.onAnnuler,
            niveau: NiveauAction.secondaire,
          ),
        ],
      ],
    );
  }
}

/// La feuille « Retirer {nom} ».
class FeuilleRetirerParticipant extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleRetirerParticipant({
    required this.sessionId,
    required this.participant,
    required this.onFini,
    required this.onAnnuler,
    super.key,
  });

  /// La seance de l'entretien.
  final String sessionId;

  /// Le participant a retirer.
  final ParticipantEntretien participant;

  /// Le geste est fait : le message du retour local.
  final ValueChanged<String> onFini;

  /// La personne renonce.
  final VoidCallback onAnnuler;

  @override
  ConsumerState<FeuilleRetirerParticipant> createState() => _EtatRetirer();
}

class _EtatRetirer extends ConsumerState<FeuilleRetirerParticipant>
    with _EnvoiEntretien<FeuilleRetirerParticipant> {
  @override
  Widget build(BuildContext context) {
    final e = t.admin.candidatures.entretien;
    final String nom = widget.participant.nomComplet;
    return Column(
      key: const ValueKey<String>('feuille-retirer-participant'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _consequence(context, e.feuille.retirerConsequence(nom: nom)),
        ...bandeauRefus(),
        ...boutons(
          libelle: e.retirer,
          destructif: true,
          onEnvoyer: () => envoyer((
            PortEntretiensDirection port,
            String _,
          ) async {
            await port.retirer(widget.sessionId, widget.participant.profilId);
            return e.retours.retire(nom: nom);
          }, widget.onFini),
          onAnnuler: widget.onAnnuler,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Consigner
// ---------------------------------------------------------------------------

/// La feuille « Consigner l'issue ».
class FeuilleConsignerEntretien extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleConsignerEntretien({
    required this.sessionId,
    required this.detail,
    required this.onFini,
    required this.onAnnuler,
    super.key,
  });

  /// La seance de l'entretien.
  final String sessionId;

  /// Le dossier lu : sa version est la version attendue.
  final DetailCandidature detail;

  /// Le geste est fait : le message du retour local.
  final ValueChanged<String> onFini;

  /// La personne renonce.
  final VoidCallback onAnnuler;

  @override
  ConsumerState<FeuilleConsignerEntretien> createState() => _EtatConsigner();
}

class _EtatConsigner extends ConsumerState<FeuilleConsignerEntretien>
    with _EnvoiEntretien<FeuilleConsignerEntretien> {
  final TextEditingController _motif = TextEditingController();
  IssueEntretien? _issue;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  bool get _complet =>
      _issue != null && (!_issue!.exigeMotif || _motif.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final e = t.admin.candidatures.entretien;
    final f = e.feuille;
    final g = t.admin.candidatures.feuille;
    return Column(
      key: const ValueKey<String>('feuille-consigner-entretien'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _consequence(context, f.consignerConsequence),
        Ecart.vLg,
        _titreChamp(context, f.issue),
        Ecart.vSm,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          options: <OptionChoix>[
            for (final IssueEntretien i in IssueEntretien.values)
              OptionChoix(
                cle: ValueKey<String>('issue-${i.valeurSql}'),
                valeur: i.valeurSql,
                libelle: libelleIssueEntretien(i),
              ),
          ],
          valeurInitiale: _issue == null
              ? null
              : ReponseChoix(valeurs: <String>{_issue!.valeurSql}),
          onChange: (ReponseChoix r) => modifie(() {
            _issue = r.valeurs.isEmpty
                ? null
                : IssueEntretien.depuisSql(r.valeurs.first);
          }),
        ),
        if (tente && _issue == null) _erreurChamp(context, f.issueManquante),
        if (_issue?.exigeMotif ?? false) ...<Widget>[
          Ecart.vLg,
          ZoneSaisie(
            cleChamp: const ValueKey<String>('entretien-motif'),
            controleur: _motif,
            libelle: g.motif,
            explication: g.motifSeul,
            erreur: tente && _motif.text.trim().isEmpty
                ? g.motifManquant
                : null,
            minLignes: 3,
            onChanged: (String _) => modifie(() {}),
          ),
        ],
        ...bandeauRefus(),
        ...boutons(
          libelle: f.envoyerConsigner,
          onEnvoyer: () {
            if (!_complet) {
              setState(() => tente = true);
              return;
            }
            final IssueEntretien issue = _issue!;
            envoyer((PortEntretiensDirection port, String cle) async {
              await port.consigner(
                sessionId: widget.sessionId,
                issue: issue,
                motif: issue.exigeMotif ? _motif.text.trim() : null,
                versionAttendue: widget.detail.version,
                cleIdempotence: cle,
              );
              return e.retours.consigne;
            }, widget.onFini);
          },
          onAnnuler: widget.onAnnuler,
        ),
      ],
    );
  }
}

class _Muet extends StatelessWidget {
  const _Muet(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) => TexteSansCoupure(
    texte,
    style: AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle()),
  );
}
