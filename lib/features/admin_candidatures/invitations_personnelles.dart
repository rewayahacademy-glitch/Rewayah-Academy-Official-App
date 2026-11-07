// INVITATIONS-PERSONNELLES (lot 7 du plan des trois salles, 07/11/2026) : la
// feuille « Envoyer les codes personnels » de la direction, sur les RPC de
// `20261120000000_invitations_candidats_importes.sql`.
//
// Chaque personne des formulaires importes qui a laisse une adresse recoit son
// propre code d'inscription, par l'e-mail existant `invitation_enseignant`
// (aucun texte d'e-mail nouveau). Le serveur etale : au plus 200 par envoi et
// 300 par 24 heures glissantes ; au-dela, il refuse et la feuille dit
// « reprenez demain ».
//
// **Un seul bouton plein, jamais grise** (K-56) : « Envoyer leur code a {n}
// personnes » seulement s'il peut aboutir (quelqu'un a inviter, reste du jour,
// reseau). Le nombre que la direction voit est celui que l'envoi attend : s'il
// a change, rien ne part et la feuille relit l'apercu.
//
// Super administrateur en double verification (comme l'import ADM-23) : une
// session en `aal1` voit « Double verification requise » et monte au geste.
//
// **Rien n'est dit parti avant la reponse du serveur.** Une coupure pendant
// l'envoi est « non confirme » (K-59) ; « Reessayer » ne donne jamais a une
// meme personne deux codes valides.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_import_candidatures.dart';
import '../../core/candidature/port_import_candidatures.dart';
import '../../core/candidature/port_invitations_personnelles.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../admin_import_formulaires/import_formulaires_page.dart'
    show EtatDoubleVerification;
import '../mfa_controleur/double_verification.dart';

/// Ouvre la feuille « Envoyer les codes personnels ».
Future<void> ouvrirFeuilleInvitationsPersonnelles(BuildContext context) =>
    AppBottomSheet.ouvrir<void>(
      context,
      titre: t.candidatsFlux.invitationsPersonnelles.titre,
      constructeur: (BuildContext contexte) => FeuilleInvitationsPersonnelles(
        onFermer: () => Navigator.of(contexte).pop(),
      ),
    );

/// Le corps de la feuille.
class FeuilleInvitationsPersonnelles extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleInvitationsPersonnelles({required this.onFermer, super.key});

  /// La feuille se ferme.
  final VoidCallback onFermer;

  /// La cle de la feuille.
  static const Key cle = ValueKey<String>('feuille-codes-personnels');

  /// La cle de l'unique bouton plein.
  static const Key cleEnvoyer = ValueKey<String>(
    'feuille-codes-personnels-envoyer',
  );

  /// La cle du bouton qui ferme.
  static const Key cleFermer = ValueKey<String>(
    'feuille-codes-personnels-fermer',
  );

  /// La cle des comptes.
  static const Key cleComptes = ValueKey<String>(
    'feuille-codes-personnels-comptes',
  );

  /// La cle du rythme (plafond du jour).
  static const Key cleRythme = ValueKey<String>(
    'feuille-codes-personnels-rythme',
  );

  /// La cle de l'etat vide.
  static const Key cleVide = ValueKey<String>('feuille-codes-personnels-vide');

  /// La cle de la phrase « limite du jour atteinte ».
  static const Key clePlafond = ValueKey<String>(
    'feuille-codes-personnels-plafond',
  );

  /// La cle de la phrase « le nombre a change ».
  static const Key cleNombreChange = ValueKey<String>(
    'feuille-codes-personnels-nombre-change',
  );

  /// La cle du resultat.
  static const Key cleResultat = ValueKey<String>(
    'feuille-codes-personnels-resultat',
  );

  /// La cle du bandeau « envoi non confirme ».
  static const Key cleNonConfirme = ValueKey<String>(
    'feuille-codes-personnels-non-confirme',
  );

  /// La cle de l'etat « acces refuse ».
  static const Key cleRefus = ValueKey<String>(
    'feuille-codes-personnels-refus',
  );

  /// La cle de l'etat sans donnees (reseau).
  static const Key cleSansDonnees = ValueKey<String>(
    'feuille-codes-personnels-sans-donnees',
  );

  @override
  ConsumerState<FeuilleInvitationsPersonnelles> createState() => _EtatFeuille();
}

class _EtatFeuille extends ConsumerState<FeuilleInvitationsPersonnelles> {
  bool _enCours = false;
  ResultatInvitationsPersonnelles? _resultat;
  bool _nonConfirme = false;
  bool _coupure = false;
  bool _refuse = false;
  bool _nombreChange = false;
  int? _plafondRestants;

  Future<void> _envoyer(int attendu) async {
    if (_enCours) return;
    final PortInvitationsPersonnelles? port = ref.read(
      portInvitationsPersonnellesProvider,
    );
    setState(() {
      _enCours = true;
      _nonConfirme = false;
      _nombreChange = false;
    });
    try {
      if (port == null) {
        throw const CapaciteIndisponible(dependanceInvitationsPersonnelles);
      }
      final ResultatInvitationsPersonnelles r = await port.envoyer(
        attendu: attendu,
      );
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _resultat = r;
      });
    } on NombreChange {
      // Rien n'est parti : l'apercu se relit, la direction voit le vrai nombre.
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _nombreChange = true;
        _resultat = null;
      });
      ref.invalidate(apercuInvitationsPersonnellesProvider);
    } on PlafondAtteint catch (e) {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _plafondRestants = e.restants;
      });
    } on PermissionInsuffisante {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _refuse = true;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _nonConfirme = true;
        _coupure = e is InvitationsPersonnellesHorsLigne;
      });
    }
  }

  void _relire() => ref.invalidate(apercuInvitationsPersonnellesProvider);

  Future<void> _monter() async {
    if (await demanderDoubleVerification(context)) {
      ref
        ..invalidate(capacitesImportCandidaturesProvider)
        ..invalidate(apercuInvitationsPersonnellesProvider);
    }
  }

  Widget _texte(String texte, {bool fort = false}) => TexteSansCoupure(
    texte,
    style:
        (fort
                ? AppPalette.of(context).inkStrong
                : AppPalette.of(context).inkMuted)
            .applyTo(
              (fort
                      ? Theme.of(context).textTheme.titleSmall
                      : Theme.of(context).textTheme.bodyMedium) ??
                  const TextStyle(),
            ),
  );

  Widget _refus() => EtatSysteme(
    key: FeuilleInvitationsPersonnelles.cleRefus,
    nature: NatureEtat.accesRefuse,
    titre: t.candidatsFlux.importFormulaires.acces.refuseTitre,
    phrase: t.candidatsFlux.importFormulaires.acces.refusePhrase,
  );

  Widget? _etatErreur(Object erreur, VoidCallback? reessayer) {
    if (erreur is PermissionInsuffisante) {
      final CapacitesImportCandidatures? caps = ref
          .read(capacitesImportCandidaturesProvider)
          .value;
      if (caps != null && caps.doubleVerificationRequise) {
        return EtatDoubleVerification(onAction: () => unawaited(_monter()));
      }
      return _refus();
    }
    if (erreur is CapaciteIndisponible) return null;
    final bool horsLigne = ref.read(horsLigneProvider).value ?? false;
    if (horsLigne || erreur is InvitationsPersonnellesHorsLigne) {
      return EtatSansDonnees(
        key: FeuilleInvitationsPersonnelles.cleSansDonnees,
        quoi: t.candidatsFlux.invitationsPersonnelles.sansDonnees,
        onAction: reessayer,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = t.candidatsFlux.invitationsPersonnelles;
    final AsyncValue<ApercuInvitationsPersonnelles> apercu = ref.watch(
      apercuInvitationsPersonnellesProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return Column(
      key: FeuilleInvitationsPersonnelles.cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _texte(p.contexte),
        Ecart.vLg,
        if (_refuse)
          _refus()
        else
          BlocAsynchrone<ApercuInvitationsPersonnelles>(
            valeur: apercu,
            onReessayer: _relire,
            titreEchec: p.sansDonnees,
            erreurVersEtat: _etatErreur,
            squelette: const Skeleton.texte(lignes: 4),
            construire: (ApercuInvitationsPersonnelles a) =>
                _contenu(a, horsLigne),
          ),
        Ecart.vXxl,
        ActionPrincipale(
          key: FeuilleInvitationsPersonnelles.cleFermer,
          libelle: t.commun.fermer,
          onPress: widget.onFermer,
          niveau: NiveauAction.secondaire,
        ),
      ],
    );
  }

  Widget _contenu(ApercuInvitationsPersonnelles a, bool horsLigne) {
    final p = t.candidatsFlux.invitationsPersonnelles;
    final ResultatInvitationsPersonnelles? resultat = _resultat;
    final int reste = resultat?.restants ?? a.eligibles;
    final int resteJour = resultat?.resteAujourdhui ?? a.resteAujourdhui;
    final int? plafondRestants = _plafondRestants;
    final bool plafond =
        plafondRestants != null || (reste > 0 && resteJour == 0);
    final List<Widget> corps = <Widget>[];

    if (resultat != null) {
      corps.add(
        Column(
          key: FeuilleInvitationsPersonnelles.cleResultat,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              liveRegion: true,
              child: _texte(
                t.candidatsFlux.file.misEnFile(n: resultat.misEnFile),
                fort: true,
              ),
            ),
            Ecart.vSm,
            _texte(
              resultat.restants > 0
                  ? p.resultat.restants(n: resultat.restants)
                  : p.resultat.tout,
            ),
            Ecart.vSm,
            _texte(p.resultat.pasDeuxFois),
          ],
        ),
      );
    } else {
      corps.add(_comptes(a));
    }

    if (_nombreChange) {
      corps
        ..add(Ecart.vLg)
        ..add(
          BandeauAttention(
            key: FeuilleInvitationsPersonnelles.cleNombreChange,
            titre: t.candidatsFlux.prevenir.erreurs.titre,
            message: p.nombreChange,
            ton: TonEtat.avertissement,
          ),
        );
    }

    if (reste == 0 && resultat == null) {
      corps
        ..add(Ecart.vLg)
        ..add(
          EtatSysteme(
            key: FeuilleInvitationsPersonnelles.cleVide,
            nature: NatureEtat.aucunResultat,
            titre: p.videTitre,
            phrase: p.vide,
          ),
        );
    } else if (reste > 0) {
      corps
        ..add(Ecart.vLg)
        ..add(
          KeyedSubtree(
            key: FeuilleInvitationsPersonnelles.cleRythme,
            child: _texte(
              p.rythme(
                plafond: a.plafondJour,
                limite: limiteInvitationsParEnvoi,
                reste: resteJour,
              ),
            ),
          ),
        );
      if (plafond) {
        corps
          ..add(Ecart.vSm)
          ..add(
            KeyedSubtree(
              key: FeuilleInvitationsPersonnelles.clePlafond,
              child: _texte(p.plafond(n: plafondRestants ?? reste), fort: true),
            ),
          );
      }
    }

    if (_nonConfirme) {
      corps
        ..add(Ecart.vLg)
        ..add(
          BandeauAttention(
            key: FeuilleInvitationsPersonnelles.cleNonConfirme,
            titre: t.candidatsFlux.prevenir.erreurs.titre,
            message: _coupure
                ? t.candidatsFlux.prevenir.erreurs.nonConfirme
                : t.candidatsFlux.prevenir.erreurs.generique,
            ton: TonEtat.avertissement,
          ),
        );
    }

    // Le seul bouton plein, rendu seulement s'il peut aboutir (jamais grise).
    // Apres un envoi, le nombre attendu est celui que le serveur a rendu.
    if (reste > 0 && !plafond) {
      corps.add(Ecart.vXxl);
      if (horsLigne && !_nonConfirme) {
        corps.add(_texte(t.candidatsFlux.prevenir.horsLigne));
      } else {
        final int n = reste > resteJour ? resteJour : reste;
        final int envoi = n > limiteInvitationsParEnvoi
            ? limiteInvitationsParEnvoi
            : n;
        corps.add(
          ActionPrincipale(
            key: FeuilleInvitationsPersonnelles.cleEnvoyer,
            libelle: _nonConfirme ? t.commun.reessayer : p.envoyer(n: envoi),
            onPress: () => unawaited(_envoyer(reste)),
            enCours: _enCours,
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: corps,
    );
  }

  Widget _comptes(ApercuInvitationsPersonnelles a) {
    final c = t.candidatsFlux.invitationsPersonnelles.comptes;
    return Column(
      key: FeuilleInvitationsPersonnelles.cleComptes,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _texte(c.aInviter(n: a.aInviter), fort: true),
        if (a.aRenvoyer > 0) ...<Widget>[
          Ecart.vXs,
          _texte(c.aRenvoyer(n: a.aRenvoyer), fort: true),
        ],
        Ecart.vXs,
        _texte(c.dejaInvites(n: a.dejaInvites)),
        Ecart.vXs,
        _texte(c.dejaInscrits(n: a.dejaInscrits)),
        if (a.revoquees > 0) ...<Widget>[
          Ecart.vXs,
          _texte(c.revoquees(n: a.revoquees)),
        ],
        if (a.desinscrits > 0) ...<Widget>[
          Ecart.vXs,
          _texte(c.desinscrits(n: a.desinscrits)),
        ],
        if (a.sansAdresse > 0) ...<Widget>[
          Ecart.vXs,
          _texte(c.sansAdresse(n: a.sansAdresse)),
        ],
      ],
    );
  }
}
