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
//   5. le resultat, tel que le serveur le rend : « {n} messages mis en file »
//      (mis en file, pas recus). S'il reste du monde, le bouton devient
//      « Envoyer aux {n} suivantes ».
//
// **CANDIDATS-FLUX (06/11/2026)** : la file des courriels etale d'elle-meme les
// envois non essentiels (reglage `courriels.non_essentiels_par_jour`, 300 par
// defaut). La feuille dit le rythme vrai (au plus {n} par jour, combien
// attendent, en combien de jours environ), compte a part les personnes
// desinscrites du recrutement, et laisse la direction changer le reglage (un
// champ et un lien, jamais un second bouton plein). Un serveur d'avant le lot
// ne rend pas l'etat de la file : la phrase d'avant (« dans les minutes qui
// suivent ») reste, et elle est vraie.
//
// **Rien n'est dit parti avant la reponse du serveur.** Une coupure du reseau
// pendant l'envoi est « non confirme » (K-59) : « Reessayer » est sans risque,
// le serveur n'envoie jamais deux fois a la meme adresse.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/port_prevenir_candidats.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';

/// Ouvre la feuille « Prevenir par e-mail ».
Future<void> ouvrirFeuillePrevenir(BuildContext context) =>
    AppBottomSheet.ouvrir<void>(
      context,
      titre: t.candidatsFlux.prevenir.titre,
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

  /// La cle du rythme d'envoi (reglage et file).
  static const Key cleRythme = ValueKey<String>('feuille-prevenir-rythme');

  /// La cle du compte des personnes desinscrites.
  static const Key cleDesinscrits = ValueKey<String>(
    'feuille-prevenir-desinscrits',
  );

  /// La cle du champ du reglage.
  static const Key cleChampReglage = ValueKey<String>(
    'feuille-prevenir-champ-reglage',
  );

  /// La cle du lien qui enregistre le reglage.
  static const Key cleEnregistrerReglage = ValueKey<String>(
    'feuille-prevenir-enregistrer-reglage',
  );

  /// La cle du retour du reglage (enregistre, invalide, echec).
  static const Key cleRetourReglage = ValueKey<String>(
    'feuille-prevenir-retour-reglage',
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

  /// Le champ du reglage (envois par jour), prerempli par la valeur lue.
  final TextEditingController _parJour = TextEditingController();
  bool _parJourPrerempli = false;
  bool _reglageEnCours = false;

  /// Ce que le dernier enregistrement du reglage a donne, a dire sous le champ.
  String? _retourReglage;
  bool _retourReglageErreur = false;

  @override
  void dispose() {
    _parJour.dispose();
    super.dispose();
  }

  Future<void> _enregistrerReglage() async {
    if (_reglageEnCours) return;
    final f = t.candidatsFlux.file.reglage;
    final int? valeur = int.tryParse(_parJour.text.trim());
    if (valeur == null ||
        valeur < courrielsParJourMin ||
        valeur > courrielsParJourMax) {
      setState(() {
        _retourReglage = f.invalide;
        _retourReglageErreur = true;
      });
      return;
    }
    final PortPrevenirCandidats? port = ref.read(portPrevenirCandidatsProvider);
    if (port == null) return;
    setState(() => _reglageEnCours = true);
    try {
      await port.reglerParJour(valeur);
      if (!mounted) return;
      setState(() {
        _reglageEnCours = false;
        _retourReglage = f.enregistre(n: valeur);
        _retourReglageErreur = false;
      });
      ref.invalidate(etatFileCourrielsProvider);
    } on Object {
      if (!mounted) return;
      setState(() {
        _reglageEnCours = false;
        _retourReglage = f.echec;
        _retourReglageErreur = true;
      });
    }
  }

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
      ref.invalidate(etatFileCourrielsProvider);
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
        quoi: t.candidatsFlux.prevenir.sansDonnees,
        onAction: reessayer,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = t.candidatsFlux.prevenir;
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
    final p = t.candidatsFlux.prevenir;
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
          )
          // Tout le monde est en file : la direction voit encore le rythme.
          ..add(Ecart.vLg)
          ..add(_rythme());
      } else {
        corps
          ..add(Ecart.vLg)
          ..add(_texte(p.message))
          ..add(Ecart.vSm)
          ..add(_rythme());
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
    final c = t.candidatsFlux.prevenir.comptes;
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
          if (a.desinscrits > 0) ...<Widget>[
            Ecart.vXs,
            KeyedSubtree(
              key: FeuillePrevenir.cleDesinscrits,
              child: _texte(t.candidatsFlux.file.desinscrits(n: a.desinscrits)),
            ),
          ],
        ],
      ),
    ];
  }

  List<Widget> _rendreResultat(ResultatPrevenir r) {
    final p = t.candidatsFlux.prevenir;
    return <Widget>[
      Column(
        key: FeuillePrevenir.cleResultat,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            liveRegion: true,
            child: _texte(
              t.candidatsFlux.file.misEnFile(n: r.misEnFile),
              fort: true,
            ),
          ),
          Ecart.vSm,
          _texte(
            r.restants > 0
                ? p.resultat.restants(n: r.restants)
                : p.resultat.tout,
          ),
          Ecart.vSm,
          _rythme(),
          Ecart.vSm,
          _texte(p.resultat.pasDeuxFois),
        ],
      ),
    ];
  }

  /// Le rythme vrai de l'envoi : le reglage, ce qui attend, et le champ qui
  /// change le reglage. Sans etat de la file (serveur d'avant le lot, panne),
  /// la phrase d'avant : les messages partent dans les minutes qui suivent.
  Widget _rythme() {
    final f = t.candidatsFlux.file;
    final AsyncValue<EtatFileCourriels> etat = ref.watch(
      etatFileCourrielsProvider,
    );
    final EtatFileCourriels? e = etat.hasValue ? etat.requireValue : null;
    if (e == null) {
      if (etat.isLoading && !etat.hasError) {
        return const Skeleton.texte(lignes: 2);
      }
      return _texte(t.candidatsFlux.prevenir.delai);
    }
    if (!_parJourPrerempli) {
      _parJourPrerempli = true;
      _parJour.text = '${e.parJour}';
    }
    final String? retour = _retourReglage;
    return Column(
      key: FeuillePrevenir.cleRythme,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _texte(f.rythme(n: e.parJour)),
        Ecart.vSm,
        if (e.enAttente == 0)
          _texte(f.rienEnAttente)
        else ...<Widget>[
          _texte(f.attente(n: e.enAttente), fort: true),
          Ecart.vXs,
          _texte(LibellesGroupe.insecable(f.jours(n: e.joursEstimes))),
        ],
        Ecart.vLg,
        KeyedSubtree(
          key: FeuillePrevenir.cleChampReglage,
          child: ChampEtiquete(
            libelle: f.reglage.libelle,
            controller: _parJour,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ),
        Ecart.vXs,
        _texte(f.reglage.aide),
        Ecart.vSm,
        LienFleche(
          key: FeuillePrevenir.cleEnregistrerReglage,
          libelle: f.reglage.enregistrer,
          alignerEnFin: true,
          onPress: _enregistrerReglage,
        ),
        if (retour != null) ...<Widget>[
          Ecart.vXs,
          Semantics(
            liveRegion: true,
            child: KeyedSubtree(
              key: FeuillePrevenir.cleRetourReglage,
              child: _retourReglageErreur
                  ? TexteSansCoupure(
                      retour,
                      style: AppPalette.of(context).inkAlert.applyTo(
                        Theme.of(context).textTheme.bodyMedium ??
                            const TextStyle(),
                      ),
                    )
                  : _texte(retour, fort: true),
            ),
          ),
        ],
      ],
    );
  }
}
