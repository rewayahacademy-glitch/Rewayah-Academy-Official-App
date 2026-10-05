import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/service_admin.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/matching/service_matching.dart';
import '../../core/regles/service_regles.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';

/// `ADM-06` : les demandes des quatre parties, et les regles d'un eleve.
///
/// **Une demande a la fois**, dans le registre de `ADM-02` : la file se prend
/// par le haut, la plus ancienne d'abord, et les deux verdicts sont en bas de
/// l'ecran, apres ce qui permet de juger. Un refus exige un motif, ici comme en
/// base.
///
/// Entre le constat et le jugement, **la feuille de regles de l'eleve
/// concerne** : chaque valeur y montre cote a cote le defaut de la plateforme et
/// ce qui s'applique, pour que l'ecart se voie sans calcul mental. C'est aussi
/// depuis cette feuille que l'administration change une regle **a la volee**,
/// sans qu'aucune demande existe : une demande n'est qu'un des deux chemins
/// (ADR-017).
class DemandesPage extends ConsumerStatefulWidget {
  /// Cree l'ecran des demandes.
  const DemandesPage({super.key});

  @override
  ConsumerState<DemandesPage> createState() => _DemandesPageEtat();
}

class _DemandesPageEtat extends ConsumerState<DemandesPage> {
  final TextEditingController _motif = TextEditingController();
  bool _refusEnCours = false;
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  void _reinitialiser() => setState(() {
    _motif.clear();
    _refusEnCours = false;
    _erreur = null;
  });

  Future<void> _decider(Demande demande, {required bool accepte}) async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceAdminProvider)
          .decider(
            demandeId: demande.id,
            accepte: accepte,
            motif: accepte ? null : _motif.text.trim(),
          );
      ref
        ..invalidate(demandesProvider)
        // Les compteurs du centre de commande comptent cette demande : les
        // laisser tels quels afficherait un chiffre que l'ecran vient de
        // dementir.
        ..invalidate(indicateursProvider)
        // Une demande accordee pose une regle en base : la feuille affichee
        // juste au-dessus doit la relire.
        ..invalidate(reglesProfilProvider(demande.sujetId))
        ..invalidate(historiqueReglesProvider(demande.sujetId));
      if (mounted) {
        _reinitialiser();
      }
    } on Object catch (erreur) {
      if (mounted) {
        setState(() => _erreur = _message(erreur));
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Demande>> file = ref.watch(demandesProvider);

    return PageShell(
      titre: t.admin.demandes.titre,
      // Les getters, jamais le type d'execution : Riverpod 3 relance un
      // provider en echec tout seul, et l'etat repasse par `AsyncLoading` en
      // conservant `hasError`.
      child: switch (file) {
        AsyncValue<List<Demande>>(hasValue: true) =>
          file.requireValue.isEmpty
              ? EmptyState(
                  message: t.admin.demandes.aucune,
                  invitation: t.admin.demandes.aucuneDetail,
                  icone: AppIcons.attribution,
                )
              : _Demande(
                  demande: file.requireValue.first,
                  restantes: file.requireValue.length,
                  motif: _motif,
                  refusEnCours: _refusEnCours,
                  envoi: _envoi,
                  erreur: _erreur,
                  onOuvrirRefus: () => setState(() => _refusEnCours = true),
                  onMotifChange: (String _) => setState(() {}),
                  onAccorder: () => unawaited(
                    _decider(file.requireValue.first, accepte: true),
                  ),
                  onRefuser: () => unawaited(
                    _decider(file.requireValue.first, accepte: false),
                  ),
                ),
        AsyncValue<List<Demande>>(hasError: true) => EmptyState(
          message: t.admin.demandes.erreurFile,
          icone: AppIcons.avertissement,
          libelleAction: t.commun.reessayer,
          onAction: () => ref.invalidate(demandesProvider),
        ),
        _ => const Skeleton.liste(lignes: 4),
      },
    );
  }
}

/// Une demande, la feuille de regles de son sujet, puis les deux verdicts.
class _Demande extends StatelessWidget {
  const _Demande({
    required this.demande,
    required this.restantes,
    required this.motif,
    required this.refusEnCours,
    required this.envoi,
    required this.erreur,
    required this.onOuvrirRefus,
    required this.onAccorder,
    required this.onRefuser,
    required this.onMotifChange,
  });

  final Demande demande;
  final int restantes;
  final TextEditingController motif;
  final bool refusEnCours;
  final bool envoi;
  final String? erreur;
  final VoidCallback onOuvrirRefus;
  final VoidCallback onAccorder;
  final VoidCallback onRefuser;
  final void Function(String motif) onMotifChange;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          restantes == 1
              ? t.admin.demandes.restanteUne
              : t.admin.demandes.restantes(n: restantes),
          style: textes.bodySmall,
        ),
        Ecart.vXl,

        // 1. LE CONSTAT : qui demande, en quelle qualite, quand, sur qui, et
        // ce qui est reclame.
        BentoTile(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(demande.sujetLibelle, style: textes.titleLarge),
              // Masque, le libelle **est** l'identifiant : le repeter sous lui
              // n'apprend rien.
              if (demande.sujetPrenomConnu)
                Text(demande.sujetIdentifiant, style: textes.bodySmall),
              Ecart.vSm,
              Text(
                t.admin.demandes.faitePar(
                  date: _jour(demande.creeeLe),
                  role: _role(demande.roleDemandeur),
                ),
                style: textes.bodySmall,
              ),
              Ecart.vLg,
              Text(t.admin.demandes.reclame, style: textes.bodyMedium),
              Ecart.vXs,
              Text(_reclame(demande), style: textes.titleMedium),
              Ecart.vLg,
              Text(t.admin.demandes.motifDemande, style: textes.bodyMedium),
              Ecart.vXs,
              Text(demande.motif, style: textes.bodyLarge),
            ],
          ),
        ),
        Ecart.vXxl,

        // 2. CE QUI PERMET DE JUGER : la regle de la plateforme et celle qui
        // s'applique, cote a cote.
        FeuilleRegles(profilId: demande.sujetId, prenom: demande.sujetLibelle),
        Ecart.vXxl,

        // 3. LE JUGEMENT, en dernier et jamais melange au reste.
        Text(t.admin.demandes.verdict, style: textes.titleMedium),
        Ecart.vMd,
        if (refusEnCours) ...<Widget>[
          TextField(
            controller: motif,
            // Le bouton de refus depend de ce champ : sans ce rappel, il
            // resterait inerte alors que le motif est saisi.
            onChanged: onMotifChange,
            maxLines: 2,
            decoration: InputDecoration(labelText: t.admin.demandes.motif),
          ),
          Ecart.vSm,
          Text(t.admin.demandes.motifRequis, style: textes.bodySmall),
          Ecart.vMd,
          ActionPrincipale(
            libelle: t.admin.demandes.refuser,
            enCours: envoi,
            niveau: NiveauAction.destructive,
            onPress: motif.text.trim().isEmpty ? null : onRefuser,
          ),
        ] else ...<Widget>[
          ActionPrincipale(
            libelle: t.admin.demandes.accorder,
            enCours: envoi,
            onPress: onAccorder,
          ),
          Ecart.vMd,
          ActionPrincipale(
            libelle: t.admin.demandes.refuser,
            onPress: onOuvrirRefus,
            niveau: NiveauAction.secondaire,
          ),
        ],
        if (erreur != null) ...<Widget>[
          Ecart.vMd,
          Text(
            erreur!,
            textAlign: TextAlign.center,
            // L'encre d'alerte, jamais la paire : `surfaceAlert` ecrit en
            // blanc, illisible sur la page.
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vMd,
        Text(
          t.admin.demandes.effet,
          textAlign: TextAlign.center,
          style: textes.bodySmall,
        ),
        Ecart.vSm,
        // Rappelee en toutes lettres sous les boutons de decision, comme sur
        // `ADM-02`, et pas dans une page d'aide.
        Text(
          t.admin.demandes.journalisation,
          textAlign: TextAlign.center,
          style: textes.bodySmall,
        ),
      ],
    );
  }
}

/// La feuille de regles d'un profil.
///
/// Chaque regle montre **cote a cote** la valeur de la plateforme et celle qui
/// s'applique : c'est la seule facon de voir l'ecart sans le calculer. Les deux
/// viennent de la meme ligne de `regles_profil_v`, jamais de deux lectures qui
/// finiraient par diverger.
@visibleForTesting
class FeuilleRegles extends ConsumerWidget {
  /// Cree la feuille de regles.
  const FeuilleRegles({
    required this.profilId,
    required this.prenom,
    super.key,
  });

  /// Le profil dont on lit les regles.
  final String profilId;

  /// Son prenom, pour que les phrases nomment quelqu'un.
  final String prenom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<RegleProfil>> regles = ref.watch(
      reglesProfilProvider(profilId),
    );
    final AsyncValue<List<SurchargeClose>> closes = ref.watch(
      historiqueReglesProvider(profilId),
    );

    final List<RegleProfil> lignes = regles.value ?? const <RegleProfil>[];
    final List<SurchargeClose> passees =
        closes.value ?? const <SurchargeClose>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t.admin.demandes.feuille(prenom: prenom),
          style: textes.titleMedium,
        ),
        Ecart.vXs,
        Text(t.admin.demandes.feuilleIntro, style: textes.bodySmall),
        Ecart.vMd,
        for (final RegleProfil regle in lignes)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: _LigneRegle(
              regle: regle,
              profilId: profilId,
              prenom: prenom,
            ),
          ),
        if (passees.isNotEmpty) ...<Widget>[
          Ecart.vMd,
          Text(t.admin.demandes.historique, style: textes.bodyMedium),
          Ecart.vXs,
          // Une surcharge close ne se supprime pas : « la seance durait 45
          // minutes ce jour-la » est une phrase qui doit se verifier six mois
          // plus tard.
          for (final SurchargeClose passee in passees)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    t.admin.demandes.historiqueLigne(
                      valeur: _valeur(passee.cle, passee.valeur),
                      debut: _jour(passee.poseeLe),
                      fin: _jour(passee.closeLe),
                    ),
                    style: textes.bodySmall,
                  ),
                  Text(
                    t.admin.demandes.historiqueMotifs(
                      motif: passee.motif,
                      cloture: passee.motifCloture,
                    ),
                    style: textes.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// Une regle : le defaut de plateforme, la valeur effective, et les deux gestes.
class _LigneRegle extends StatelessWidget {
  const _LigneRegle({
    required this.regle,
    required this.profilId,
    required this.prenom,
  });

  final RegleProfil regle;
  final String profilId;
  final String prenom;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return BentoTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(_libelleRegle(regle.cle), style: textes.titleMedium),
          Ecart.vXs,
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  t.admin.demandes.plateforme(
                    valeur: _valeur(regle.cle, regle.valeurPlateforme),
                  ),
                  style: textes.bodySmall,
                ),
              ),
              Ecart.hSm,
              Expanded(
                child: Text(
                  t.admin.demandes.effective(
                    valeur: _valeur(regle.cle, regle.valeurEffective),
                  ),
                  style: regle.surchargee
                      ? palette.inkAccent.applyTo(
                          textes.bodyMedium ?? const TextStyle(),
                        )
                      : textes.bodySmall,
                ),
              ),
            ],
          ),
          Ecart.vSm,
          Text(
            regle.surchargee
                ? t.admin.demandes.surchargeDepuis(
                    date: _jour(regle.poseeLe),
                    motif: regle.motif ?? '',
                  )
                : t.admin.demandes.sansSurcharge,
            style: textes.bodySmall,
          ),
          Ecart.vSm,
          ActionPrincipale(
            libelle: t.admin.demandes.changer,
            niveau: NiveauAction.secondaire,
            onPress: () => unawaited(
              _ouvrir(
                context,
                FeuilleRegle(
                  profilId: profilId,
                  prenom: prenom,
                  cle: regle.cle,
                  valeurCourante: regle.valeurEffective,
                ),
              ),
            ),
          ),
          // Le bouton de cloture n'est rendu que s'il y a une surcharge a
          // clore : sans surcharge, il echouerait apres le geste, et un bouton
          // qui echoue apres le geste coute plus cher qu'un bouton absent.
          if (regle.surchargee) ...<Widget>[
            Ecart.vSm,
            ActionPrincipale(
              libelle: t.admin.demandes.clore,
              niveau: NiveauAction.secondaire,
              onPress: () => unawaited(
                _ouvrir(
                  context,
                  FeuilleRegle(
                    profilId: profilId,
                    prenom: prenom,
                    cle: regle.cle,
                    valeurCourante: regle.valeurEffective,
                    surchargeId: regle.surchargeId,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // `AppBottomSheet.ouvrir` est le seul point d'entree d'une surface modale
  // du produit (`core/widgets/app_bottom_sheet.dart`) : poignee de
  // glissement, courbes et durees du budget de mouvement, voile et
  // `useSafeArea` garantis. Un appel direct a `showModalBottomSheet` en
  // etait prive, seul ecran des seize du panneau Admin dans ce cas
  // (audit de placement UX, 19 septembre 2026).
  Future<void> _ouvrir(BuildContext context, FeuilleRegle feuille) =>
      AppBottomSheet.ouvrir<void>(
        context,
        titre: feuille.titre,
        constructeur: (BuildContext _) => feuille,
      );
}

/// La feuille qui pose une regle, ou qui clot une surcharge.
///
/// Un seul composant pour les deux gestes : ils demandent la meme chose, un
/// motif, et la base refuse l'un comme l'autre sans lui. Deux feuilles jumelles
/// finiraient par ne plus exiger le motif du meme cote.
@visibleForTesting
class FeuilleRegle extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleRegle({
    required this.profilId,
    required this.prenom,
    required this.cle,
    required this.valeurCourante,
    super.key,
    this.surchargeId,
  });

  /// Le profil concerne.
  final String profilId;

  /// Son prenom.
  final String prenom;

  /// La regle visee. `null` quand la base en expose une inconnue de ce code :
  /// la feuille se refuse alors a agir plutot que d'inventer une cle.
  final CleRegle? cle;

  /// Ce qui s'applique aujourd'hui, affiche avant de proposer autre chose.
  final int valeurCourante;

  /// La surcharge a clore. Quand il est fourni, la feuille clot au lieu de
  /// poser.
  final String? surchargeId;

  /// Le titre de la feuille, porte par `AppBottomSheet` -- jamais redit dans
  /// le corps, qui commence directement a la valeur effective.
  String get titre => surchargeId != null
      ? t.admin.demandes.cloreTitre(prenom: prenom)
      : t.admin.demandes.poserTitre(regle: _libelleRegle(cle), prenom: prenom);

  /// Les valeurs proposees pour chaque regle, en minutes ou en eleves.
  ///
  /// Elles ne decident de rien : ce sont des raccourcis de saisie, et la carte
  /// « Autre » de `ChoiceCardGroup` accepte n'importe quelle autre valeur.
  static List<int> proposees(CleRegle? cle) => switch (cle) {
    CleRegle.dureeSeance => const <int>[30, 45, 60, 90],
    CleRegle.minimumPayable => const <int>[30, 45, 60],
    CleRegle.pauseEntreCours => const <int>[15, 30, 45],
    CleRegle.plafondEleves => const <int>[3, 4, 5, 6],
    null => const <int>[],
  };

  @override
  ConsumerState<FeuilleRegle> createState() => _FeuilleRegleEtat();
}

class _FeuilleRegleEtat extends ConsumerState<FeuilleRegle> {
  final TextEditingController _motif = TextEditingController();
  int? _valeurChoisie;
  bool _enCours = false;
  String? _erreur;

  bool get _clot => widget.surchargeId != null;

  /// Vrai quand le geste peut aboutir : un motif, et une valeur si l'on pose.
  bool get _pret =>
      _motif.text.trim().isNotEmpty && (_clot || _valeurChoisie != null);

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final CleRegle? cle = widget.cle;
    final int? valeur = _valeurChoisie;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final ServiceRegles service = ref.read(serviceReglesProvider);
      if (_clot) {
        await service.clore(
          surchargeId: widget.surchargeId!,
          motif: _motif.text.trim(),
        );
      } else if (cle != null && valeur != null) {
        await service.poser(
          profilId: widget.profilId,
          cle: cle,
          valeur: valeur,
          motif: _motif.text.trim(),
        );
      }
      ref
        ..invalidate(reglesProfilProvider(widget.profilId))
        ..invalidate(historiqueReglesProvider(widget.profilId));
      if (cle != null) {
        // La valeur lue regle par regle vient d'une autre porte,
        // `regle_effective()` : sans cette invalidation, les ecrans qui la
        // lisent, `ENS-06` pour son plafond et `TUT-05` pour la duree,
        // continueraient d'annoncer l'ancienne.
        ref.invalidate(
          valeurRegleProvider((profilId: widget.profilId, cle: cle)),
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (erreur) {
      if (mounted) {
        setState(() => _erreur = _message(erreur));
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    // Ni marge ni retrait de clavier ici : `AppBottomSheet` les porte deja
    // pour tout appelant, meme regle que `_FeuilleMotif`
    // (`admin_groupes/groupes_page.dart`). Le titre, lui, est porte par
    // `AppBottomSheet` via `FeuilleRegle.titre`, jamais redit ici.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t.admin.demandes.effective(
            valeur: _valeur(widget.cle, widget.valeurCourante),
          ),
          style: textes.bodySmall,
        ),
        Ecart.vMd,
        if (!_clot) ...<Widget>[
          ChoiceCardGroup(
            options: <OptionChoix>[
              for (final int propose in FeuilleRegle.proposees(widget.cle))
                OptionChoix(
                  valeur: '$propose',
                  libelle: _valeur(widget.cle, propose),
                ),
            ],
            onChange: (ReponseChoix reponse) => setState(() {
              _valeurChoisie = int.tryParse(
                reponse.valeurs.isEmpty
                    ? reponse.saisieLibre ?? ''
                    : reponse.valeurs.first,
              );
            }),
          ),
          Ecart.vMd,
        ],
        TextField(
          controller: _motif,
          decoration: InputDecoration(labelText: t.admin.demandes.poserMotif),
          // Sans ceci, le bouton ne se reconstruit pas a la frappe et reste
          // inerte alors que le motif est saisi (piege de l'etape 3).
          onChanged: (String _) => setState(() {}),
          maxLines: 2,
        ),
        if (_motif.text.trim().isEmpty) ...<Widget>[
          Ecart.vSm,
          Text(t.admin.demandes.poserMotifRequis, style: textes.bodySmall),
        ],
        if (_erreur != null) ...<Widget>[
          Ecart.vSm,
          Text(
            _erreur!,
            style: palette.inkAlert.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vMd,
        ActionPrincipale(
          libelle: _clot
              ? t.admin.demandes.cloreEnvoyer
              : t.admin.demandes.poserEnvoyer,
          enCours: _enCours,
          onPress: _pret ? _envoyer : null,
        ),
      ],
    );
  }
}

/// Le libelle d'une regle, dans les termes des specs produit.
String _libelleRegle(CleRegle? cle) => switch (cle) {
  CleRegle.dureeSeance => t.admin.demandes.regleDuree,
  CleRegle.minimumPayable => t.admin.demandes.regleMinimum,
  CleRegle.pauseEntreCours => t.admin.demandes.reglePause,
  CleRegle.plafondEleves => t.admin.demandes.reglePlafond,
  null => t.admin.demandes.regleInconnue,
};

/// Une valeur de regle avec son unite. **Le plafond compte des eleves, les
/// trois autres regles comptent des minutes** : une valeur nue laisserait
/// lire « 5 » pour cinq minutes de cours.
String _valeur(CleRegle? cle, int valeur) => cle == CleRegle.plafondEleves
    ? t.admin.demandes.eleves(valeur: '$valeur')
    : LibellesGroupe.valeurSeule(t.admin.demandes.minutes(valeur: '$valeur'));

/// Ce que la demande reclame, dit en clair.
String _reclame(Demande demande) => switch (demande.sorte) {
  SorteDemande.reaffectation => t.admin.demandes.reclameReaffectation(
    prenom: demande.sujetLibelle,
  ),
  SorteDemande.plafond =>
    demande.valeurDemandee == null
        ? t.admin.demandes.reclameRegleSansValeur(
            regle: t.admin.demandes.reglePlafond,
          )
        : t.admin.demandes.reclamePlafond(valeur: '${demande.valeurDemandee}'),
  _ =>
    demande.valeurDemandee == null
        ? t.admin.demandes.reclameRegleSansValeur(
            regle: _libelleRegle(demande.cleRegle),
          )
        : LibellesGroupe.insecable(
            t.admin.demandes.reclameRegle(
              regle: _libelleRegle(demande.cleRegle),
              valeur: '${demande.valeurDemandee}',
            ),
          ),
};

/// En quelle qualite la demande a ete faite.
String _role(AppRole? role) => switch (role) {
  AppRole.guardian => t.admin.demandes.roleGuardian,
  AppRole.teacher => t.admin.demandes.roleTeacher,
  AppRole.student => t.admin.demandes.roleStudent,
  AppRole.admin => t.admin.demandes.roleAdmin,
  AppRole.controller => t.admin.demandes.roleController,
  _ => t.admin.demandes.roleInconnu,
};

/// Une date civile, telle que les autres ecrans d'administration l'ecrivent.
///
/// Rend une chaine vide plutot qu'une date inventee : la base date toutes ces
/// lignes, seule une valeur que ce code n'a pas su lire arriverait nulle, et une
/// date par defaut y serait un mensonge daté.
String _jour(DateTime? quand) => quand == null
    ? ''
    : '${quand.day.toString().padLeft(2, '0')}/'
          '${quand.month.toString().padLeft(2, '0')}/${quand.year}';

/// Le message metier d'une exception, sans son type.
String _message(Object erreur) {
  final String brut = erreur.toString();
  // Les exceptions Postgrest portent le message metier en clair : c'est lui
  // qu'il faut montrer, pas le type de l'exception.
  final int deuxPoints = brut.indexOf(': ');
  return deuxPoints >= 0 && deuxPoints + 2 < brut.length
      ? brut.substring(deuxPoints + 2)
      : brut;
}
