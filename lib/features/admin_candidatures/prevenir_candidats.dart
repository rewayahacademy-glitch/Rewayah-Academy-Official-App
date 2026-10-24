// Le geste « Prevenir par e-mail » de la direction (CAND-PREVENIR, directeur,
// 24/10/2026) : la feuille qui envoie le lien d'inscription aux personnes des
// formulaires importes, sur les deux RPC de
// `20261024010000_cand_prevenir_par_courriel.sql`.
//
// **Un seul bouton plein, jamais grise** (K-56) :
//
//   1. l'apercu, lu au serveur (BlocAsynchrone) : trois comptes par adresse,
//      aucune adresse montree ;
//   2. inscription fermee : une phrase dit qu'elle doit d'abord etre ouverte, et
//      aucun bouton ;
//   3. plus personne a prevenir : l'etat vide le dit, sans bouton ;
//   4. sinon « Envoyer le lien a {n} personnes » ;
//   5. le resultat, tel que le serveur le rend : « {n} messages partent dans les
//      prochaines minutes » (mis en file, pas recus). S'il reste du monde, le
//      bouton devient « Envoyer aux {n} suivantes ».
//
// **Rien n'est dit parti avant la reponse du serveur.** Une coupure du reseau
// pendant l'envoi est « non confirme » (K-59) : « Reessayer » est sans risque,
// le serveur n'envoie jamais deux fois a la meme adresse.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/port_prevenir_candidats.dart';
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

/// Ouvre la feuille « Prevenir par e-mail ».
Future<void> ouvrirFeuillePrevenir(BuildContext context) =>
    AppBottomSheet.ouvrir<void>(
      context,
      titre: t.admin.candidatures.prevenir.titre,
      constructeur: (BuildContext contexte) =>
          FeuillePrevenir(onFermer: () => Navigator.of(contexte).pop()),
    );

/// Le corps de la feuille « Prevenir par e-mail ».
class FeuillePrevenir extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuillePrevenir({required this.onFermer, super.key});

  /// La feuille se ferme.
  final VoidCallback onFermer;

  /// La cle de la feuille.
  static const Key cle = ValueKey<String>('feuille-prevenir');

  /// La cle de l'unique bouton plein (envoyer, ou envoyer aux suivantes).
  static const Key cleEnvoyer = ValueKey<String>('feuille-prevenir-envoyer');

  /// La cle du bouton qui ferme.
  static const Key cleFermer = ValueKey<String>('feuille-prevenir-fermer');

  /// La cle des trois comptes.
  static const Key cleComptes = ValueKey<String>('feuille-prevenir-comptes');

  /// La cle de la phrase « l'inscription doit d'abord etre ouverte ».
  static const Key cleFermee = ValueKey<String>('feuille-prevenir-fermee');

  /// La cle de l'etat vide.
  static const Key cleVide = ValueKey<String>('feuille-prevenir-vide');

  /// La cle du resultat.
  static const Key cleResultat = ValueKey<String>('feuille-prevenir-resultat');

  /// La cle du bandeau « envoi non confirme ».
  static const Key cleNonConfirme = ValueKey<String>(
    'feuille-prevenir-non-confirme',
  );

  /// La cle de l'etat « acces refuse ».
  static const Key cleRefus = ValueKey<String>('feuille-prevenir-refus');

  /// La cle de l'etat sans donnees (reseau).
  static const Key cleSansDonnees = ValueKey<String>(
    'feuille-prevenir-sans-donnees',
  );

  @override
  ConsumerState<FeuillePrevenir> createState() => _EtatFeuillePrevenir();
}

class _EtatFeuillePrevenir extends ConsumerState<FeuillePrevenir> {
  bool _enCours = false;
  ResultatPrevenir? _resultat;

  /// Le dernier envoi n'a pas pu etre confirme (reseau ou panne inconnue).
  bool _nonConfirme = false;

  /// La coupure du reseau, par opposition a une panne que l'on ne sait pas dire.
  bool _coupure = false;

  /// Le serveur a refuse l'envoi : l'inscription est fermee.
  bool _fermee = false;

  /// Le serveur a refuse le droit d'envoyer.
  bool _refuse = false;

  Future<void> _envoyer() async {
    if (_enCours) return;
    final PortPrevenirCandidats? port = ref.read(portPrevenirCandidatsProvider);
    setState(() {
      _enCours = true;
      _nonConfirme = false;
    });
    try {
      if (port == null) {
        throw const CapaciteIndisponible(dependancePrevenirCandidats);
      }
      final ResultatPrevenir resultat = await port.prevenir();
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _resultat = resultat;
      });
    } on InscriptionFermee {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _fermee = true;
      });
    } on PermissionInsuffisante {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _refuse = true;
      });
    } on Object catch (e) {
      // Reseau coupe, argument refuse, panne inconnue : des messages ont pu
      // etre mis en file. Rien n'est dit confirme ; rejouer est sans risque.
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _nonConfirme = true;
        _coupure = e is PrevenirHorsLigne;
      });
    }
  }

  void _relire() => ref.invalidate(apercuPrevenirCandidatsProvider);

  // --- Rendu --------------------------------------------------------------

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

  Widget _fermer() => ActionPrincipale(
    key: FeuillePrevenir.cleFermer,
    libelle: t.commun.fermer,
    onPress: widget.onFermer,
    niveau: NiveauAction.secondaire,
  );

  Widget? _etatErreur(Object erreur, VoidCallback? reessayer) {
    final r = t.admin.candidatures;
    if (erreur is PermissionInsuffisante) {
      return EtatSysteme(
        key: FeuillePrevenir.cleRefus,
        nature: NatureEtat.accesRefuse,
        titre: r.accesRefuse,
        phrase: '',
      );
    }
    if (erreur is CapaciteIndisponible) return null;
    final bool horsLigne = ref.read(horsLigneProvider).value ?? false;
    if (horsLigne || erreur is PrevenirHorsLigne) {
      return EtatSansDonnees(
        key: FeuillePrevenir.cleSansDonnees,
        quoi: r.prevenir.sansDonnees,
        onAction: reessayer,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = t.admin.candidatures.prevenir;
    final AsyncValue<ApercuPrevenir> apercu = ref.watch(
      apercuPrevenirCandidatsProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return Column(
      key: FeuillePrevenir.cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _texte(p.contexte),
        Ecart.vLg,
        if (_refuse)
          EtatSysteme(
            key: FeuillePrevenir.cleRefus,
            nature: NatureEtat.accesRefuse,
            titre: t.admin.candidatures.accesRefuse,
            phrase: '',
          )
        else
          BlocAsynchrone<ApercuPrevenir>(
            valeur: apercu,
            onReessayer: _relire,
            titreEchec: p.sansDonnees,
            erreurVersEtat: _etatErreur,
            squelette: const Skeleton.texte(lignes: 3),
            construire: (ApercuPrevenir a) => _contenu(a, horsLigne),
          ),
        Ecart.vXxl,
        _fermer(),
      ],
    );
  }

  Widget _contenu(ApercuPrevenir a, bool horsLigne) {
    final p = t.admin.candidatures.prevenir;
    final ResultatPrevenir? resultat = _resultat;
    final bool fermee = _fermee || !a.inscriptionOuverte;
    final List<Widget> corps = <Widget>[];

    if (resultat != null) {
      corps.addAll(_rendreResultat(resultat));
    } else {
      corps.addAll(_rendreComptes(a));
      if (fermee) {
        corps
          ..add(Ecart.vLg)
          ..add(
            KeyedSubtree(
              key: FeuillePrevenir.cleFermee,
              child: _texte(p.fermee, fort: true),
            ),
          );
      } else if (a.aPrevenir == 0) {
        corps
          ..add(Ecart.vLg)
          ..add(
            EtatSysteme(
              key: FeuillePrevenir.cleVide,
              nature: NatureEtat.aucunResultat,
              titre: p.videTitre,
              phrase: p.vide,
            ),
          );
      } else {
        corps
          ..add(Ecart.vLg)
          ..add(_texte(p.message))
          ..add(Ecart.vSm)
          ..add(_texte(p.delai));
        if (a.aPrevenir > limitePrevenirParDefaut) {
          corps
            ..add(Ecart.vSm)
            ..add(_texte(p.groupes(n: limitePrevenirParDefaut)));
        }
      }
    }

    if (_nonConfirme) {
      corps
        ..add(Ecart.vLg)
        ..add(
          BandeauAttention(
            key: FeuillePrevenir.cleNonConfirme,
            titre: p.erreurs.titre,
            message: _coupure ? p.erreurs.nonConfirme : p.erreurs.generique,
            ton: TonEtat.avertissement,
          ),
        );
    }

    // Le seul bouton plein, rendu seulement s'il peut aboutir (jamais grise).
    final int reste = resultat?.restants ?? a.aPrevenir;
    final bool peutEnvoyer = !fermee && reste > 0;
    if (peutEnvoyer) {
      corps.add(Ecart.vXxl);
      if (horsLigne && !_nonConfirme) {
        corps.add(_texte(p.horsLigne));
      } else {
        corps.add(
          ActionPrincipale(
            key: FeuillePrevenir.cleEnvoyer,
            libelle: _nonConfirme
                ? t.commun.reessayer
                : resultat != null
                ? p.envoyerSuivantes(n: reste)
                : p.envoyer(
                    n: reste > limitePrevenirParDefaut
                        ? limitePrevenirParDefaut
                        : reste,
                  ),
            onPress: _envoyer,
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

  List<Widget> _rendreComptes(ApercuPrevenir a) {
    final c = t.admin.candidatures.prevenir.comptes;
    return <Widget>[
      Column(
        key: FeuillePrevenir.cleComptes,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _texte(c.aPrevenir(n: a.aPrevenir), fort: true),
          Ecart.vXs,
          _texte(c.dejaPrevenus(n: a.dejaPrevenus)),
          Ecart.vXs,
          _texte(c.dejaInscrits(n: a.dejaInscrits)),
        ],
      ),
    ];
  }

  List<Widget> _rendreResultat(ResultatPrevenir r) {
    final p = t.admin.candidatures.prevenir;
    return <Widget>[
      Column(
        key: FeuillePrevenir.cleResultat,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            liveRegion: true,
            child: _texte(p.resultat.mis(n: r.misEnFile), fort: true),
          ),
          Ecart.vSm,
          _texte(
            r.restants > 0
                ? p.resultat.restants(n: r.restants)
                : p.resultat.tout,
          ),
          Ecart.vSm,
          _texte(p.delai),
          Ecart.vSm,
          _texte(p.resultat.pasDeuxFois),
        ],
      ),
    ];
  }
}
