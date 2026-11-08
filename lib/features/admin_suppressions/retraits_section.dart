/// SUPPRIMER-bis : les comptes supprimes, cote direction (Personnes >
/// Suppressions, section « Comptes supprimes »).
///
/// Une carte par retrait : qui, quand, par qui, ou en est l'anonymisation.
/// « Restaurer » n'est rendu que si le serveur dit le retrait restaurable
/// (`restaurable`) ; sinon la raison le remplace, jamais un bouton grise. La
/// restauration rouvre le compte, sans remettre l'eleve dans ses classes :
/// la section le dit avant le geste, et le resultat dit combien de classes
/// sont a reprendre (`classes_quittees`).
///
/// Liste paginee par le serveur (`retraits_comptes_lister`, 50 par page, sans
/// total) : « Afficher plus » lit la page suivante. Le filtre d'etat relit
/// depuis le debut. Etats : chargement, contenu, vide, erreur, hors ligne,
/// port absent, refus.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/personnes_modifiees.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/capacites/port_retraits_comptes.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/dates_appareil.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/identifiant_insecable.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../mfa_controleur/double_verification.dart';

/// La premiere page des retraits d'un etat. Relue a chaque ouverture et
/// apres chaque restauration.
final retraitsComptesProvider = FutureProvider.autoDispose
    .family<PageRetraits, EtatRetraits>(
      (Ref ref, EtatRetraits etat) =>
          ref.watch(portRetraitsComptesProvider).lister(etat: etat),
      retry: (int _, Object _) => null,
    );

/// La section « Comptes supprimes ».
class RetraitsSection extends ConsumerStatefulWidget {
  /// Cree la section.
  const RetraitsSection({super.key, this.nomRole = _roleParDefaut});

  /// Le nom d'un role, tel que la page des suppressions le dit.
  final String Function(AppRole? role) nomRole;

  static String _roleParDefaut(AppRole? role) => role?.name ?? '';

  /// La ligne qui dit ce qu'est devenue la derniere restauration.
  static const Key retourKey = ValueKey<String>('retraits-retour');

  /// « Afficher plus ».
  static const Key plusKey = ValueKey<String>('retraits-plus');

  /// Le geste « Restaurer » du retrait [retraitId].
  static Key restaurerKey(String retraitId) =>
      ValueKey<String>('retrait-restaurer-$retraitId');

  /// Le filtre d'etat [etat].
  static Key filtreKey(EtatRetraits etat) =>
      ValueKey<String>('retraits-filtre-${etat.name}');

  @override
  ConsumerState<RetraitsSection> createState() => _RetraitsSectionState();
}

class _RetraitsSectionState extends ConsumerState<RetraitsSection> {
  EtatRetraits _etat = EtatRetraits.enCours;

  /// Les pages lues apres la premiere, et le curseur de la suivante.
  final List<RetraitCompte> _suite = <RetraitCompte>[];
  CurseurRetraits? _suivantSuite;
  bool _suiteLue = false;
  bool _lectureSuite = false;
  bool _echecSuite = false;

  String? _enCours;
  String? _retour;
  bool _retourEchec = false;

  bool get _horsLigne => ref.read(horsLigneProvider).value ?? false;

  void _relireDepuisLeDebut() {
    _suite.clear();
    _suivantSuite = null;
    _suiteLue = false;
    _echecSuite = false;
    ref.invalidate(retraitsComptesProvider(_etat));
  }

  void _choisirEtat(EtatRetraits etat) {
    if (etat == _etat) return;
    setState(() {
      _etat = etat;
      _suite.clear();
      _suivantSuite = null;
      _suiteLue = false;
      _echecSuite = false;
    });
  }

  Future<void> _lirePlus(CurseurRetraits apres) async {
    if (_lectureSuite) return;
    setState(() {
      _lectureSuite = true;
      _echecSuite = false;
    });
    final EtatRetraits etat = _etat;
    try {
      final PageRetraits page = await avecDoubleVerification(
        context,
        ref,
        () => ref
            .read(portRetraitsComptesProvider)
            .lister(etat: etat, apres: apres),
      );
      if (!mounted || etat != _etat) return;
      setState(() {
        _suite.addAll(page.lignes);
        _suivantSuite = page.suivant;
        _suiteLue = true;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _echecSuite = true);
    } finally {
      if (mounted) setState(() => _lectureSuite = false);
    }
  }

  Future<void> _restaurer(RetraitCompte r) async {
    if (_enCours != null) return;
    final a = t.admin.suppressions.retraits;
    final String nom = _nom(r);
    if (_horsLigne) {
      setState(() {
        _retour = t.admin.suppressions.horsLigne;
        _retourEchec = true;
      });
      return;
    }
    setState(() {
      _enCours = r.retraitId;
      _retour = null;
    });
    String retour;
    bool echec = true;
    try {
      // MFA-DIRECTION : en aal1, le code est demande puis le geste rejoue.
      final List<ResultatRestauration> resultats = await avecDoubleVerification(
        context,
        ref,
        () => ref.read(portRetraitsComptesProvider).restaurer(<String>[
          r.profilId,
        ]),
      );
      final ResultatRestauration? x = resultats
          .where((ResultatRestauration x) => x.id == r.profilId)
          .firstOrNull;
      if (x == null) {
        retour = a.refus.erreur;
      } else if (x.restaure) {
        echec = false;
        retour = <String>[
          a.restaure(
            deNom: deDevant(nom, cle: 'admin.suppressions.retraits.restaure'),
          ),
          if (x.classesQuittees > 0) a.classesQuittees(n: x.classesQuittees),
        ].join(' ');
      } else {
        retour = switch (x.raison) {
          RaisonRefusRetrait.aucunRetrait => a.refus.aucunRetrait,
          RaisonRefusRetrait.dejaAnonymise => a.refus.dejaAnonymise,
          RaisonRefusRetrait.etatAvantInconnu => a.refus.etatAvantInconnu,
          _ => a.refus.erreur,
        };
      }
    } on PermissionInsuffisante {
      retour = t.admin.suppressions.refuse;
    } on Object {
      retour = _horsLigne ? t.admin.suppressions.horsLigne : a.refus.erreur;
    }
    // Dans tous les cas la liste est relue : une restauration dont la reponse
    // s'est perdue doit y apparaitre.
    _relireDepuisLeDebut();
    // D2 : un compte restaure revient aussi dans Comptes et les autres listes.
    ref.read(personnesModifieesProvider.notifier).signaler();
    if (!mounted) return;
    setState(() {
      _enCours = null;
      _retour = retour;
      _retourEchec = echec;
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = t.admin.suppressions.retraits;
    final AsyncValue<PageRetraits> valeur = ref.watch(
      retraitsComptesProvider(_etat),
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle corps = textes.bodyMedium ?? const TextStyle();
    final String? retour = _retour;
    return Column(
      key: const ValueKey<String>('retraits-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(a.contexte, style: palette.inkStrong.applyTo(corps)),
        Ecart.vLg,
        RangeeFiltres(
          filtres: <Widget>[
            for (final EtatRetraits e in EtatRetraits.values)
              FilterPill(
                key: RetraitsSection.filtreKey(e),
                libelle: _libelleFiltre(e),
                retenue: e == _etat,
                onPress: () => _choisirEtat(e),
              ),
          ],
        ),
        Ecart.vLg,
        if (retour != null) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              retour,
              key: RetraitsSection.retourKey,
              style: (_retourEchec ? palette.inkAlert : palette.inkStrong)
                  .applyTo(corps),
            ),
          ),
          Ecart.vLg,
        ],
        BlocAsynchrone<PageRetraits>(
          key: const ValueKey<String>('retraits-bloc'),
          valeur: valeur,
          squelette: const Skeleton.liste(lignes: 3),
          onReessayer: _relireDepuisLeDebut,
          estVide: (PageRetraits p) => p.lignes.isEmpty,
          vide: EmptyState(
            key: const ValueKey<String>('retraits-vide'),
            message: _vide(_etat),
            icone: AppIcons.rienAAfficher,
            registre: RegistreVide.subi,
          ),
          erreurVersEtat: (Object e, VoidCallback? reessayer) {
            if (e is CapaciteIndisponible) {
              return EtatSysteme(
                key: const ValueKey<String>('retraits-indisponible'),
                nature: NatureEtat.indisponible,
                titre: t.admin.suppressions.indisponibleTitre,
                phrase: t.admin.suppressions.indisponiblePhrase,
                dependance: e.dependance,
              );
            }
            if (e is PermissionInsuffisante) {
              // MFA-DIRECTION : la liste est refusee en aal1 ; la direction
              // saisit son code ici, puis la liste est relue.
              final bool monter = peutMonterIci(ref);
              return EtatSysteme(
                key: const ValueKey<String>('retraits-refuse'),
                nature: NatureEtat.echecServeur,
                phrase: t.admin.suppressions.refuse,
                libelleAction: monter
                    ? t.compte.doubleVerification.saisirCode
                    : null,
                onAction: monter
                    ? () async {
                        if (await demanderDoubleVerification(context)) {
                          _relireDepuisLeDebut();
                        }
                      }
                    : null,
              );
            }
            return horsLigne
                ? EtatSansDonnees(
                    key: const ValueKey<String>('retraits-sans-donnees'),
                    quoi: a.sansDonnees,
                    onAction: reessayer,
                  )
                : EtatSysteme(
                    key: const ValueKey<String>('retraits-erreur'),
                    nature: NatureEtat.echecServeur,
                    phrase: a.erreur,
                    onAction: reessayer,
                  );
          },
          construire: (PageRetraits premiere) {
            final List<RetraitCompte> lignes = <RetraitCompte>[
              ...premiere.lignes,
              ..._suite,
            ];
            final CurseurRetraits? suivant = _suiteLue
                ? _suivantSuite
                : premiere.suivant;
            return Column(
              key: const ValueKey<String>('retraits-contenu'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                PileCartes(
                  children: <Widget>[
                    for (final RetraitCompte r in lignes)
                      _CarteRetrait(
                        retrait: r,
                        nomRole: widget.nomRole,
                        enCours: _enCours == r.retraitId,
                        occupe: _enCours != null,
                        onRestaurer: () => unawaited(_restaurer(r)),
                      ),
                  ],
                ),
                if (_echecSuite) ...<Widget>[
                  Ecart.vLg,
                  Text(a.erreur, style: palette.inkAlert.applyTo(corps)),
                ],
                if (suivant != null) ...<Widget>[
                  Ecart.vLg,
                  LienFleche(
                    key: RetraitsSection.plusKey,
                    libelle: a.voirPlus,
                    // Une lecture en cours ignore le second toucher.
                    onPress: () => unawaited(_lirePlus(suivant)),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  static String _libelleFiltre(EtatRetraits e) {
    final f = t.admin.suppressions.retraits.filtres;
    return switch (e) {
      EtatRetraits.enCours => f.enCours,
      EtatRetraits.anonymises => f.anonymises,
      EtatRetraits.restaures => f.restaures,
      EtatRetraits.tous => f.tous,
    };
  }

  static String _vide(EtatRetraits e) {
    final v = t.admin.suppressions.retraits.vide;
    return switch (e) {
      EtatRetraits.enCours => v.enCours,
      EtatRetraits.anonymises => v.anonymises,
      EtatRetraits.restaures => v.restaures,
      EtatRetraits.tous => v.tous,
    };
  }
}

String _nom(RetraitCompte r) {
  final String nom = r.nom.trim();
  return nom.isEmpty ? t.admin.suppressions.retraits.nomEfface : nom;
}

class _CarteRetrait extends StatelessWidget {
  const _CarteRetrait({
    required this.retrait,
    required this.nomRole,
    required this.enCours,
    required this.occupe,
    required this.onRestaurer,
  });

  final RetraitCompte retrait;
  final String Function(AppRole? role) nomRole;
  final bool enCours;
  final bool occupe;
  final VoidCallback onRestaurer;

  @override
  Widget build(BuildContext context) {
    final a = t.admin.suppressions.retraits;
    final RetraitCompte r = retrait;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle corps = palette.inkStrong.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final String nom = _nom(r);
    final String? motif = r.motif?.trim();
    final DateTime? anonymise = r.anonymiseLe;
    final DateTime? restaure = r.restaureLe;
    final bool enAttente = anonymise == null && restaure == null;
    return AppCard(
      key: ValueKey<String>('retrait-${r.retraitId}'),
      entete: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.start,
        spacing: AppSpacing.sm,
        overflowSpacing: AppSpacing.sm,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(isolerSens(nom), style: textes.titleMedium),
          ),
          if (restaure != null)
            StatusPill(libelle: a.etat.restaure, ton: TonEtat.succes)
          else if (anonymise != null)
            StatusPill(libelle: a.etat.anonymise, ton: TonEtat.neutre)
          else
            StatusPill(libelle: a.etat.supprime, ton: TonEtat.avertissement),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (r.matricule.isNotEmpty) ...<Widget>[
            LigneCleValeur(
              cle: t.admin.suppressions.matricule,
              valeur: identifiantInsecable(r.matricule),
            ),
            Ecart.vSm,
          ],
          LigneCleValeur(
            cle: t.admin.suppressions.role,
            valeur: nomRole(r.role),
          ),
          Ecart.vSm,
          LigneCleValeur(
            cle: a.supprimeLe,
            valeur: dateDeLAppareil(r.retireLe),
          ),
          Ecart.vSm,
          LigneCleValeur(
            cle: a.par,
            valeur: switch (r.source) {
              SourceRetrait.direction => a.parDirection,
              SourceRetrait.tuteur => a.parTuteur,
            },
          ),
          if (motif != null && motif.isNotEmpty) ...<Widget>[
            Ecart.vSm,
            LigneCleValeur(cle: t.admin.suppressions.motif, valeur: motif),
          ],
          Ecart.vSm,
          if (restaure != null)
            LigneCleValeur(cle: a.restaureLe, valeur: dateDeLAppareil(restaure))
          else if (anonymise != null)
            LigneCleValeur(
              cle: a.anonymiseLe,
              valeur: dateDeLAppareil(anonymise),
            )
          else
            LigneCleValeur(
              cle: a.anonymisationPrevue,
              valeur: dateDeLAppareil(r.anonymiserLe),
            ),
          if (enAttente) ...<Widget>[
            Ecart.vLg,
            // Pendant une restauration, les autres gestes ne sont pas rendus.
            if (r.restaurable && (enCours || !occupe))
              ActionPrincipale(
                key: RetraitsSection.restaurerKey(r.retraitId),
                libelle: a.restaurer(
                  deNom: deDevant(
                    nom,
                    cle: 'admin.suppressions.retraits.restaurer',
                  ),
                ),
                niveau: NiveauAction.secondaire,
                enCours: enCours,
                onPress: enCours ? null : onRestaurer,
              )
            else if (!r.restaurable)
              Text(a.nonRestaurable, style: corps),
          ],
        ],
      ),
    );
  }
}
