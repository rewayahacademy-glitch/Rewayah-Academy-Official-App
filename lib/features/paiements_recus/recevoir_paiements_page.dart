// « Recevoir mes paiements » : la surface personnelle de l'enseignant pour sa
// paie (route partagee `/compte/paiements-recus`, dans la coquille du role
// connecte). Refondue par le lot FINANCE-ENSEIGNANT (06/11/2026) sur la
// decision du directeur du 06/11 : la paie part par paiement groupe Wise ;
// l'enseignant saisit lui-meme ses coordonnees bancaires.
//
// Dans l'ordre : la notice quand les coordonnees manquent (une alerte va en
// tete), mes coordonnees (numeros masques par le serveur sauf les 4 derniers
// caracteres), mes versements recus (notes par la direction), l'historique de
// mes changements. Un seul bouton plein, en bas : « Renseigner mes
// coordonnees » ou « Modifier mes coordonnees ». « Retirer » est un lien,
// confirme avant d'agir ; rien n'est efface cote serveur.
//
// La page ne prend aucun identifiant : elle lit « moi » par le port. Cinq
// etats : chargement, contenu, (aucune coordonnee = etat metier avec sa
// notice), erreur, hors ligne ; sans source : « Pas encore disponible ».

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_coordonnees_versement.dart';
import '../../core/capacites/port_versements_paie.dart';
import '../../core/finance/format_montant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/comptable/ligne_activite.dart' show dateComptable;
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/texte_protege.dart';
import 'etat_coordonnees.dart';
import 'feuille_coordonnees.dart';

/// Mes coordonnees de versement et mes versements recus.
class RecevoirPaiementsPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const RecevoirPaiementsPage({super.key});

  /// La cle du bouton plein.
  static const Key actionKey = ValueKey<String>('recevoir-action');

  /// La cle de la notice.
  static const Key noticeKey = ValueKey<String>('recevoir-notice');

  /// La cle du retour d'une action.
  static const Key retourKey = ValueKey<String>('recevoir-retour');

  /// La cle du lien « Retirer ».
  static const Key retirerKey = ValueKey<String>('recevoir-retirer');

  /// La cle de la phrase de validation par la direction.
  static const Key validationKey = ValueKey<String>('recevoir-validation');

  /// La cle de la section des versements.
  static const Key versementsKey = ValueKey<String>('recevoir-versements');

  @override
  ConsumerState<RecevoirPaiementsPage> createState() =>
      _RecevoirPaiementsPageEtat();
}

class _RecevoirPaiementsPageEtat extends ConsumerState<RecevoirPaiementsPage> {
  MesCoordonneesVersement? _apresAction;
  String? _retour;
  bool _retourEchec = false;
  bool _enCours = false;

  void _relire() {
    ref
      ..invalidate(mesCoordonneesVersementProvider)
      ..invalidate(journalCoordonneesProvider);
  }

  Future<void> _saisir(MesCoordonneesVersement etat) async {
    if (_enCours) return;
    final MesCoordonneesVersement? apres = await ouvrirFeuilleCoordonnees(
      context,
      etat,
    );
    if (apres == null || !mounted) return;
    setState(() {
      _apresAction = apres;
      _retour = t.comptable.beneficiaires.recevoir.wise.enregistrees;
      _retourEchec = false;
    });
    _relire();
  }

  Future<void> _retirer() async {
    if (_enCours) return;
    final w = t.comptable.beneficiaires.recevoir.wise;
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: w.retirerQuestion,
      consequence: w.retirerConsequence,
      libelleConfirmer: w.retirer,
    );
    if (!confirme || !mounted) return;
    setState(() => _enCours = true);
    try {
      final MesCoordonneesVersement apres = await ref
          .read(portCoordonneesVersementProvider)
          .retirer();
      if (!mounted) return;
      setState(() {
        _apresAction = apres;
        _retour = w.retirees;
        _retourEchec = false;
      });
      _relire();
    } on Object catch (erreur) {
      if (!mounted) return;
      setState(() {
        _retour = erreur is CapaciteIndisponible
            ? t.comptable.beneficiaires.recevoir.erreurIndisponible
            : t.comptable.beneficiaires.recevoir.erreurAction;
        _retourEchec = true;
      });
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = t.comptable.beneficiaires.recevoir;
    final AsyncValue<MesCoordonneesVersement> lu = ref.watch(
      mesCoordonneesVersementProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final MesCoordonneesVersement? local = _apresAction;
    final AsyncValue<MesCoordonneesVersement> valeur = local == null
        ? lu
        : AsyncValue<MesCoordonneesVersement>.data(local);
    final MesCoordonneesVersement? etat = valeur.hasValue ? valeur.value : null;
    return PageShell(
      titre: r.titre,
      sousTitre: r.sousTitre,
      onRetour: () {
        final GoRouter routeur = GoRouter.of(context);
        if (routeur.canPop()) {
          routeur.pop();
        } else {
          routeur.go(Routes.compte);
        }
      },
      actions: etat == null
          ? null
          : ActionPrincipale(
              key: RecevoirPaiementsPage.actionKey,
              libelle: etat.enregistre ? r.wise.modifier : r.wise.renseigner,
              enCours: _enCours,
              onPress: () => unawaited(_saisir(etat)),
            ),
      child: TexteProtege(
        child: BlocAsynchrone<MesCoordonneesVersement>(
          valeur: valeur,
          squelette: const Skeleton.liste(lignes: 5),
          onReessayer: () {
            setState(() => _apresAction = null);
            _relire();
          },
          erreurVersEtat: (Object erreur, VoidCallback? reessayer) =>
              horsLigne && erreur is! CapaciteIndisponible
              ? EtatSysteme.sansDonnees(
                  quoi: t.sansDonnees.paiementsRecus,
                  onAction: reessayer,
                )
              : null,
          construire: (MesCoordonneesVersement e) => _Corps(
            etat: e,
            retour: _retour,
            retourEchec: _retourEchec,
            onRetirer: () => unawaited(_retirer()),
          ),
        ),
      ),
    );
  }
}

/// Le corps : notice, coordonnees, versements, journal.
class _Corps extends StatelessWidget {
  const _Corps({
    required this.etat,
    required this.retour,
    required this.retourEchec,
    required this.onRetirer,
  });

  final MesCoordonneesVersement etat;
  final String? retour;
  final bool retourEchec;
  final VoidCallback onRetirer;

  @override
  Widget build(BuildContext context) {
    final r = t.comptable.beneficiaires.recevoir;
    final w = r.wise;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final String? message = retour;
    final String phrase = !etat.enregistre
        ? w.phraseAucune(devise: etat.deviseCible)
        : etat.complet
        ? w.phraseComplete(devise: etat.deviseCible)
        : w.phraseIncomplete;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // L'alerte d'abord.
        if (!etat.complet) ...<Widget>[
          BandeauAttention(
            key: RecevoirPaiementsPage.noticeKey,
            titre: r.notice,
            message: phrase,
          ),
          Ecart.vLg,
        ],
        if (message != null) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              key: RecevoirPaiementsPage.retourKey,
              style: (retourEchec ? palette.inkAlert : palette.inkStrong)
                  .applyTo(textes.bodyMedium ?? const TextStyle()),
            ),
          ),
          Ecart.vLg,
        ],
        SectionHeader(titre: w.titreCoordonnees),
        AppCard(
          dominante: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (etat.complet)
                Text(
                  phrase,
                  style: palette.inkStrong.applyTo(
                    textes.bodyLarge ?? const TextStyle(),
                  ),
                ),
              if (etat.enregistre) ...<Widget>[
                if (etat.complet) Ecart.vMd,
                CarteLignes(
                  lignes: <Widget>[
                    for (final ChampDemande d in etat.champs)
                      if (etat.valeurs[d.champ] case final String v)
                        SettingRow(
                          title: libelleChampVersement(d.champ),
                          value: valeurChampVersement(d.champ, v),
                        )
                      else if (d.obligatoire &&
                          d.demandePour(
                            etat.valeurs[ChampVersement.adressePays],
                          ))
                        SettingRow(
                          title: libelleChampVersement(d.champ),
                          value: w.champRequis,
                        ),
                    if (!etat.compteAMonNom && etat.lienTitulaire != null)
                      SettingRow(
                        title: w.lienLibelle,
                        value: libelleLienTitulaire(etat.lienTitulaire!),
                      ),
                  ],
                ),
                Ecart.vMd,
                if (etat.complet)
                  Text(
                    etat.valide ? w.validees : w.enAttenteValidation,
                    key: RecevoirPaiementsPage.validationKey,
                    style: palette.inkStrong.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                Ecart.vSm,
                Text(w.masquees, style: attenue),
              ] else
                Text(w.phraseAucune(devise: etat.deviseCible), style: attenue),
              Ecart.vMd,
              Text(w.lecteurs, style: attenue),
              if (etat.enregistre) ...<Widget>[
                Ecart.vSm,
                LienFleche(
                  key: RecevoirPaiementsPage.retirerKey,
                  libelle: w.retirer,
                  onPress: onRetirer,
                ),
              ],
            ],
          ),
        ),
        Ecart.vSection,
        SectionHeader(titre: w.versementsTitre),
        const _Versements(key: RecevoirPaiementsPage.versementsKey),
        Ecart.vSection,
        SectionHeader(titre: r.journalTitre),
        const _Journal(),
      ],
    );
  }
}

/// Mes versements recus, notes par la direction.
class _Versements extends ConsumerWidget {
  const _Versements({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = t.comptable.beneficiaires.recevoir.wise;
    final AsyncValue<List<VersementPaie>> lu = ref.watch(
      mesVersementsPaieProvider,
    );
    return BlocAsynchrone<List<VersementPaie>>(
      valeur: lu,
      squelette: const Skeleton.liste(lignes: 2),
      onReessayer: () => ref.invalidate(mesVersementsPaieProvider),
      vide: AppCard(
        child: Text(
          w.versementsVide,
          style: AppPalette.of(context).inkMuted.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
      ),
      construire: (List<VersementPaie> versements) => CarteLignes(
        lignes: <Widget>[
          for (final VersementPaie v in versements)
            SettingRow(
              key: ValueKey<String>('recevoir-versement-${v.id}'),
              title: w.versementMois(mois: libelleMoisPaie(v.mois)),
              description: v.annule
                  ? w.versementAnnule
                  : w.versementDetail(
                      date: dateComptable(v.verseLe),
                      moyen: libelleMoyenVersement(v.moyen),
                    ),
              value: formaterMontant(v.montant),
            ),
        ],
      ),
    );
  }
}

/// L'historique de mes changements, lu a part.
class _Journal extends ConsumerWidget {
  const _Journal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = t.comptable.beneficiaires.recevoir;
    final AsyncValue<List<EntreeJournalCoordonnees>> journal = ref.watch(
      journalCoordonneesProvider,
    );
    return BlocAsynchrone<List<EntreeJournalCoordonnees>>(
      valeur: journal,
      squelette: const Skeleton.liste(lignes: 2),
      onReessayer: () => ref.invalidate(journalCoordonneesProvider),
      vide: AppCard(
        child: Text(
          r.journalVide,
          style: AppPalette.of(context).inkMuted.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
      ),
      construire: (List<EntreeJournalCoordonnees> entrees) => CarteLignes(
        lignes: <Widget>[
          for (final EntreeJournalCoordonnees e in entrees)
            SettingRow(
              title: e.validee
                  ? r.wise.journalValidees
                  : e.retrait
                  ? r.wise.journalRetirees
                  : r.wise.journalEnregistrees,
              value: dateComptable(e.date),
            ),
        ],
      ),
    );
  }
}
