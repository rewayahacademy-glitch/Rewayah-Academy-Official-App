// La recharge du foyer (EA-10, planches 4.2 et 4.3, UX_REVIEW_07 lignes 15 et
// 16) : deux etapes, puis le paiement qui s'arrete sur un etat honnete.
//
// 1. « Nouvelle recharge » : un, plusieurs ou tous les beneficiaires (une case
//    par ligne, « Tout selectionner » au-dessus de la liste), et, pour chaque
//    beneficiaire coche, l'offre que le serveur rend pour lui (F11 : rien
//    n'est reparti, aucune offre n'est proposee d'avance). « Verifier la
//    recharge » reste inactif tant qu'un beneficiaire coche n'a pas d'offre,
//    avec une phrase qui dit pourquoi.
// 2. « Verifier la recharge » : le recapitulatif SEPARE par beneficiaire que
//    le serveur arrete (qui recoit, montant paye, solde attribue, remise
//    seulement si rendue avec son libelle, statut de l'attribution), un lien
//    « Modifier » par beneficiaire qui revient a l'etape 1 sans rien perdre,
//    le total rendu, puis « Payer {total} » au bord de fin.
// 3. Le paiement n'a aucune source (EA-BR-25, prestataire non choisi, doc
//    section 20.8) : « Paiement pas encore disponible », jamais « Paiement
//    reussi » (F13). Une coupure dit seulement que le paiement n'a pas ete
//    confirme (D5) ; la meme cle rend une nouvelle tentative sure.
//
// **Aucun chiffre economique ici** (F12) : ni prix, ni pack, ni taux, ni
// remise, ni total ; tout est lu tel que rendu. Aucun moyen de paiement n'est
// montre, meme masque (F13). Rien sur le second adulte au-dela de ce que la
// recharge exige (F6, F10) : ni Classe, ni photo (Q4).
//
// Rien de recree (K-51) : `PageEtape`, `GroupeReglages` (case native en
// controle de ligne), `PhotoEleve` (K-44), `ChoiceCardGroup` (seul point
// d'entree d'un choix, ADR-013), `LigneCleValeur`, `ActionPrincipale`,
// `EtatSysteme`, `BlocAsynchrone`, `Skeleton`, `LienFleche`, et les briques
// privees de l'invitation du titulaire (ce fichier en est une partie, comme
// l'acceptation d'EA-7 et la sortie d'EA-8). Les libelles sans source (spec,
// planche) sont marques « libelle provisoire, lexique D4 » la ou ils sont lus.

part of 'invitation_conjoint.dart';

/// Ce que l'ecran dit apres une verification ou un paiement manques.
enum _EchecRecharge { reseau, indisponible }

/// La recharge du foyer, pour le titulaire seulement.
class RechargeFoyerPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const RechargeFoyerPage({
    required this.onAbandon,
    required this.onTerminee,
    super.key,
  });

  /// Quitter depuis la premiere etape : retour aux paiements du foyer.
  final VoidCallback onAbandon;

  /// « Revenir aux paiements du foyer », apres le paiement.
  final VoidCallback onTerminee;

  /// « Tout selectionner » ou « Tout deselectionner ».
  static const Key toutSelectionnerKey = Key('recharge.toutSelectionner');

  /// « Verifier la recharge » (etape 1).
  static const Key verifierKey = Key('recharge.verifier');

  /// La phrase qui dit pourquoi « Verifier la recharge » est inactif.
  static const Key raisonKey = Key('recharge.raison');

  /// Le recapitulatif par beneficiaire (etape 2).
  static const Key recapitulatifKey = Key('recharge.recapitulatif');

  /// Le total rendu (etape 2).
  static const Key totalKey = Key('recharge.total');

  /// « Payer {total} » (etape 2).
  static const Key payerKey = Key('recharge.payer');

  /// Le titre de l'etape 2, qui prend le focus a son apparition.
  static const Key focusEtape2Key = Key('recharge.focusEtape2');

  /// Un echec ou l'etat du paiement, qui prend le focus a son apparition.
  static const Key focusEtatKey = Key('recharge.focusEtat');

  /// La case d'un beneficiaire.
  static Key caseDe(String beneficiaire) => Key('recharge.case.$beneficiaire');

  /// La carte d'une offre d'un beneficiaire.
  static Key offreDe(String beneficiaire, String offre) =>
      Key('recharge.offre.$beneficiaire.$offre');

  /// La ligne du recapitulatif d'un beneficiaire.
  static Key ligneDe(String beneficiaire) =>
      Key('recharge.ligne.$beneficiaire');

  /// « Modifier » sur la ligne d'un beneficiaire.
  static Key modifierDe(String beneficiaire) =>
      Key('recharge.modifier.$beneficiaire');

  @override
  ConsumerState<RechargeFoyerPage> createState() => _RechargeFoyerPageState();
}

class _RechargeFoyerPageState extends ConsumerState<RechargeFoyerPage> {
  /// Les beneficiaires coches, et l'offre choisie pour chacun : gardes au
  /// retour de l'etape 2 (W-337), et l'offre d'un beneficiaire decoche puis
  /// recoche aussi.
  final Set<String> _selection = <String>{};
  final Map<String, String> _offres = <String, String>{};

  bool _verification = false;
  bool _verifEnCours = false;
  _EchecRecharge? _echecVerif;
  RecapitulatifRecharge? _recapitulatif;

  /// Une cle par recapitulatif : une nouvelle tentative apres une coupure
  /// reprend la meme ; un autre recapitulatif en tire une autre.
  String _cle = const Uuid().v4();
  bool _paiementEnCours = false;
  _EchecRecharge? _echecPaiement;

  /// L'etat du paiement tel que le serveur le redige (jamais deduit ici).
  String? _etatPaiement;

  bool get _occupe => _verifEnCours || _paiementEnCours;

  /// La reponse d'un paiement est perdue (D5) : il est peut-etre passe. Les
  /// choix ne se modifient plus et la cle reste la meme ; seule une nouvelle
  /// tentative (meme cle) ou le retour aux paiements du foyer, ou l'on
  /// verifie, reste possible : jamais un second paiement sous une autre cle.
  /// Une recharge rouverte plus tard tire une autre cle : seul le serveur
  /// peut alors reconnaitre le paiement en suspens (EA-BR-26).
  bool get _paiementIncertain => _echecPaiement == _EchecRecharge.reseau;

  List<ChoixRecharge> _choix(List<BeneficiaireRecharge> liste) =>
      <ChoixRecharge>[
        for (final BeneficiaireRecharge b in liste)
          if (_selection.contains(b.id))
            if (_offres[b.id] case final String offre)
              ChoixRecharge(beneficiaireId: b.id, offreId: offre),
      ];

  /// Au moins un beneficiaire coche, et une offre pour chacun.
  bool _pret(List<BeneficiaireRecharge> liste) =>
      _selection.isNotEmpty && _choix(liste).length == _selection.length;

  void _basculer(String id, bool coche) => setState(() {
    if (coche) {
      _selection.add(id);
    } else {
      _selection.remove(id);
    }
    _echecVerif = null;
  });

  void _toutSelectionner(List<BeneficiaireRecharge> liste, bool tout) =>
      setState(() {
        _selection
          ..clear()
          ..addAll(<String>[
            if (tout)
              for (final BeneficiaireRecharge b in liste) b.id,
          ]);
        _echecVerif = null;
      });

  void _choisirOffre(String beneficiaire, ReponseChoix r) => setState(() {
    final String? offre = r.valeurs.firstOrNull;
    if (offre == null) {
      _offres.remove(beneficiaire);
    } else {
      _offres[beneficiaire] = offre;
    }
    _echecVerif = null;
  });

  Future<void> _verifier(List<BeneficiaireRecharge> liste) async {
    if (_occupe) return;
    setState(() {
      _verifEnCours = true;
      _echecVerif = null;
    });
    final RecapitulatifRecharge recapitulatif;
    try {
      recapitulatif = await ref
          .read(portRechargeFoyerProvider)
          .verifier(_choix(liste));
    } on CapaciteIndisponible {
      if (mounted) {
        setState(() {
          _verifEnCours = false;
          _echecVerif = _EchecRecharge.indisponible;
        });
      }
      return;
    } on Object {
      if (mounted) {
        setState(() {
          _verifEnCours = false;
          _echecVerif = _EchecRecharge.reseau;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _verifEnCours = false;
      _recapitulatif = recapitulatif;
      _verification = true;
      _cle = const Uuid().v4();
      _echecPaiement = null;
      _etatPaiement = null;
    });
  }

  void _retour() {
    if (_occupe) return;
    if (_verification && _paiementIncertain) {
      // Paiement non confirme (D5) : pas de retour aux choix, qui tirerait
      // une autre cle ; le retour mene la ou l'on verifie.
      widget.onTerminee();
      return;
    }
    if (_verification) {
      // Retour sans perte : les cases et les offres restent (W-337).
      setState(() {
        _verification = false;
        _echecPaiement = null;
        _etatPaiement = null;
      });
      return;
    }
    widget.onAbandon();
  }

  Future<void> _payer(RecapitulatifRecharge recapitulatif) async {
    // Double envoi : un seul appel part, le bouton attend la reponse.
    if (_occupe) return;
    setState(() {
      _paiementEnCours = true;
      _echecPaiement = null;
    });
    _EchecRecharge? echec;
    String? etat;
    try {
      etat = await ref
          .read(portRechargeFoyerProvider)
          .payer(recapitulatifId: recapitulatif.id, cle: _cle);
    } on CapaciteIndisponible {
      echec = _EchecRecharge.indisponible;
    } on Object {
      echec = _EchecRecharge.reseau;
    }
    if (!mounted) return;
    setState(() {
      _paiementEnCours = false;
      _echecPaiement = echec;
      _etatPaiement = etat;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final RecapitulatifRecharge? recapitulatif = _recapitulatif;
    final bool etape2 = _verification && recapitulatif != null;
    return PopScope(
      canPop: !_verification && !_occupe,
      onPopInvokedWithResult: (bool fait, Object? _) {
        if (!fait) _retour();
      },
      child: PageEtape(
        numero: etape2 ? 2 : 1,
        total: 2,
        onRetour: _retour,
        child: _Colonne(
          child: etape2
              ? _pageVerification(context, recapitulatif, horsLigne)
              : _pageBeneficiaires(context, horsLigne),
        ),
      ),
    );
  }

  Widget _pageBeneficiaires(BuildContext context, bool horsLigne) {
    final AsyncValue<List<BeneficiaireRecharge>> lecture = ref.watch(
      beneficiairesRechargeProvider,
    );
    void relire() => ref.invalidate(beneficiairesRechargeProvider);
    final Object? erreur = lecture.hasError ? lecture.error : null;
    final Widget corps;
    if (erreur is CapaciteIndisponible) {
      // Libelles provisoires, lexique D4.
      corps = EtatSysteme(
        nature: NatureEtat.indisponible,
        titre: t.adulte.recharge.indisponibleTitre,
        phrase: t.adulte.recharge.indisponiblePhrase,
        dependance: erreur.dependance,
      );
    } else if (erreur != null && horsLigne) {
      // Sans reseau, un echec se dit « hors ligne », comme les soldes.
      corps = EtatSysteme(nature: NatureEtat.horsLigne, onAction: relire);
    } else {
      corps = BlocAsynchrone<List<BeneficiaireRecharge>>(
        valeur: lecture,
        squelette: const Skeleton.liste(),
        onReessayer: relire,
        estVide: (List<BeneficiaireRecharge> l) => l.isEmpty,
        // Les textes des soldes vides (EA-9), libelles provisoires D4.
        vide: EtatSysteme(
          nature: NatureEtat.aucunResultat,
          titre: t.adulte.paiements.aucunBeneficiaireTitre,
          phrase: t.adulte.paiements.aucunBeneficiairePhrase,
        ),
        construire: (List<BeneficiaireRecharge> liste) =>
            _choixBeneficiaires(context, liste, horsLigne),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // « Nouvelle recharge » (planche 4.2) ; sa phrase reprend la carte de
        // la planche, sans « montant » : libelle provisoire, lexique D4.
        _Titre(
          titre: t.adulte.recharge.titre,
          phrase: t.adulte.recharge.phrase,
        ),
        Ecart.vXxl,
        corps,
      ],
    );
  }

  Widget _choixBeneficiaires(
    BuildContext context,
    List<BeneficiaireRecharge> liste,
    bool horsLigne,
  ) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool tout = liste.every(
      (BeneficiaireRecharge b) => _selection.contains(b.id),
    );
    final bool pret = _pret(liste);
    // Pourquoi le bouton attend : libelles provisoires, lexique D4.
    final String? raison = _selection.isEmpty
        ? t.adulte.recharge.raisonAucun
        : pret
        ? null
        : t.adulte.recharge.raisonOffre;
    Widget titre(String texte) => Semantics(
      header: true,
      child: Text(
        texte,
        style: palette.inkStrong.applyTo(
          textes.titleMedium ?? const TextStyle(),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Le titre du groupe et « Tout selectionner » au-dessus de la liste
        // (UX_REVIEW_07 ligne 15 b) ; a 200 %, le lien passe dessous.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          children: <Widget>[
            titre(t.adulte.paiements.beneficiaires),
            LienFleche(
              key: RechargeFoyerPage.toutSelectionnerKey,
              // « Tout deselectionner » : libelle provisoire, lexique D4.
              libelle: tout
                  ? t.adulte.recharge.toutDeselectionner
                  : t.adulte.recharge.toutSelectionner,
              fleche: false,
              onPress: () => _toutSelectionner(liste, !tout),
            ),
          ],
        ),
        Ecart.vSm,
        // L'offre de chaque beneficiaire coche JUSTE SOUS sa ligne (UX_REVIEW_07
        // ligne 15 a, planche 4.2). `GroupeReglages` (partage, K-51) n'a pas
        // de place sous une ligne : le groupe se coupe apres chaque ligne
        // cochee, ses offres suivent, puis le groupe reprend (harmonisation
        // notee au tableau).
        for (final (int i, List<BeneficiaireRecharge> troncon) in _troncons(
          liste,
        ).indexed) ...<Widget>[
          if (i > 0) Ecart.vLg,
          GroupeReglages(
            lignes: <LigneRubrique>[
              for (final BeneficiaireRecharge b in troncon)
                LigneRubrique(
                  meneur: PhotoEleve(
                    prenom: b.prenom,
                    cleAvatar: b.cleAvatar,
                    diametre: AppSpacing.section,
                  ),
                  libelle: b.prenom,
                  // Le solde tel que rendu (E2), sans Classe (F6).
                  valeur: b.soldeRendu,
                  controle: Checkbox(
                    key: RechargeFoyerPage.caseDe(b.id),
                    value: _selection.contains(b.id),
                    // Sans libelle propre : la ligne entiere (prenom, solde,
                    // case) est lue d'un bloc par `GroupeReglages`.
                    onChanged: _occupe
                        ? null
                        : (bool? coche) => _basculer(b.id, coche ?? false),
                  ),
                ),
            ],
          ),
          // Une offre par beneficiaire coche, lue telle que rendue ; aucune
          // n'est choisie d'avance (F11, ligne 15 a).
          if (_selection.contains(troncon.last.id)) ...<Widget>[
            Ecart.vMd,
            // « Offre pour {prenom} » : libelle provisoire, lexique D4.
            titre(t.adulte.recharge.offrePour(prenom: troncon.last.prenom)),
            Ecart.vSm,
            _offresDe(troncon.last),
          ],
        ],
        if (_echecVerif case final _EchecRecharge echec) ...<Widget>[
          Ecart.vLg,
          _FocusALApparition(
            key: RechargeFoyerPage.focusEtatKey,
            child: switch (echec) {
              // Une lecture manquee : rien n'a ete paye, les choix restent.
              // Libelles provisoires, lexique D4.
              _EchecRecharge.reseau => EtatSysteme(
                nature: NatureEtat.echecServeur,
                titre: t.adulte.recharge.verificationEchecTitre,
                phrase: t.adulte.recharge.verificationEchecPhrase,
              ),
              _EchecRecharge.indisponible => EtatSysteme(
                nature: NatureEtat.indisponible,
                titre: t.adulte.recharge.indisponibleTitre,
                phrase: t.adulte.recharge.indisponiblePhrase,
                dependance: 'EA-BR-24',
              ),
            },
          ),
        ],
        // Hors ligne : rien ne part tout seul. Libelle provisoire, lexique D4.
        if (horsLigne) ...<Widget>[
          Ecart.vLg,
          _Note(texte: t.adulte.recharge.horsLigneVerifier),
        ] else if (raison != null) ...<Widget>[
          Ecart.vLg,
          _Note(
            key: RechargeFoyerPage.raisonKey,
            texte: raison,
            attenuee: true,
          ),
        ],
        Ecart.vLg,
        _Actions(
          principale: ActionPrincipale(
            key: RechargeFoyerPage.verifierKey,
            libelle: t.adulte.recharge.verifier,
            fleche: true,
            onPress:
                pret && !horsLigne && _echecVerif != _EchecRecharge.indisponible
                ? () => unawaited(_verifier(liste))
                : null,
            enCours: _verifEnCours,
            pleineLargeur: false,
          ),
        ),
      ],
    );
  }

  /// La liste coupee apres chaque beneficiaire coche : chaque troncon finit
  /// par une ligne cochee (ses offres suivent) ou par la fin de la liste.
  List<List<BeneficiaireRecharge>> _troncons(List<BeneficiaireRecharge> liste) {
    final List<List<BeneficiaireRecharge>> troncons =
        <List<BeneficiaireRecharge>>[<BeneficiaireRecharge>[]];
    for (final BeneficiaireRecharge b in liste) {
      troncons.last.add(b);
      if (_selection.contains(b.id)) troncons.add(<BeneficiaireRecharge>[]);
    }
    if (troncons.last.isEmpty) troncons.removeLast();
    return troncons;
  }

  Widget _offresDe(BeneficiaireRecharge b) => ChoiceCardGroup(
    key: ValueKey<String>('recharge.offres.${b.id}'),
    autoriserSaisieLibre: false,
    valeurInitiale: switch (_offres[b.id]) {
      final String offre => ReponseChoix(valeurs: <String>{offre}),
      null => null,
    },
    options: <OptionChoix>[
      for (final OffreRecharge o in b.offres)
        OptionChoix(
          cle: RechargeFoyerPage.offreDe(b.id, o.id),
          valeur: o.id,
          libelle: o.libelle,
          description: o.detail,
        ),
    ],
    onChange: (ReponseChoix r) => _choisirOffre(b.id, r),
  );

  Widget _pageVerification(
    BuildContext context,
    RecapitulatifRecharge recapitulatif,
    bool horsLigne,
  ) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? etatPaiement = _etatPaiement;
    final bool arrete =
        etatPaiement != null || _echecPaiement == _EchecRecharge.indisponible;
    final Widget? etat = switch ((_echecPaiement, etatPaiement)) {
      // D5 : l'ecran ne dit que ce qu'il sait, le paiement n'est pas
      // confirme ; la meme cle rend une nouvelle tentative sure.
      (_EchecRecharge.reseau, _) => EtatSysteme(
        nature: NatureEtat.echecServeur,
        titre: t.adulte.recharge.paiementEchecTitre,
        phrase: t.adulte.recharge.paiementEchecPhrase,
      ),
      // L'etat honnete (F13) : aucun paiement, jamais « reussi ». Titre,
      // phrase et retour : libelles provisoires, lexique D4.
      (_EchecRecharge.indisponible, _) => EtatSysteme(
        nature: NatureEtat.indisponible,
        titre: t.adulte.recharge.paiementIndisponibleTitre,
        phrase: t.adulte.recharge.paiementIndisponiblePhrase,
        dependance: 'EA-BR-25',
        libelleAction: t.adulte.recharge.revenirPaiements,
        onAction: widget.onTerminee,
      ),
      // L'etat que le serveur redige, tel quel (EA-BR-25).
      (null, final String rendu) => Semantics(
        liveRegion: true,
        child: _Note(texte: rendu),
      ),
      (null, null) => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // « Verifier la recharge » et sa phrase (planche 4.3).
        _FocusALApparition(
          key: RechargeFoyerPage.focusEtape2Key,
          child: _Titre(
            titre: t.adulte.recharge.verifierTitre,
            phrase: t.adulte.recharge.verifierPhrase,
          ),
        ),
        Ecart.vXxl,
        Semantics(
          header: true,
          child: Text(
            t.adulte.recharge.recapitulatif,
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        Column(
          key: RechargeFoyerPage.recapitulatifKey,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final (int i, LigneRecapitulatif l)
                in recapitulatif.lignes.indexed) ...<Widget>[
              // K-55 : 16 entre deux cartes (`Ecart.vLg`).
              if (i > 0) Ecart.vLg,
              _Carte(
                key: RechargeFoyerPage.ligneDe(l.beneficiaireId),
                lignes: <Widget>[
                  // Qui recoit : sa photo ou ses initiales (K-44), sans
                  // Classe (F6).
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: <Widget>[
                        PhotoEleve(
                          prenom: l.prenom,
                          cleAvatar: l.cleAvatar,
                          diametre: AppSpacing.section,
                        ),
                        Ecart.hMd,
                        Expanded(
                          child: Text(
                            l.prenom,
                            style: palette.inkStrong.applyTo(
                              textes.titleMedium ?? const TextStyle(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Chaque valeur telle que rendue (F11, F12).
                  LigneCleValeur(
                    cle: t.adulte.recharge.montantPaye,
                    valeur: l.montantPaye,
                    chiffres: true,
                  ),
                  LigneCleValeur(
                    cle: t.adulte.recharge.soldeAttribue,
                    valeur: l.soldeAttribue,
                  ),
                  // La remise seulement si le serveur la rend, avec SON
                  // libelle (F12, ligne 16 a).
                  if (l.remise case final RemiseRendue r)
                    LigneCleValeur(cle: r.libelle, valeur: r.valeur),
                  LigneCleValeur(
                    cle: t.adulte.recharge.statut,
                    valeur: l.statut,
                  ),
                  if (!arrete && !_paiementIncertain)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: LienFleche(
                        key: RechargeFoyerPage.modifierDe(l.beneficiaireId),
                        libelle: t.adulte.recharge.modifier,
                        fleche: false,
                        onPress: _retour,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
        Ecart.vLg,
        // Le total rendu, jamais additionne ici (ligne 16 b).
        _Carte(
          key: RechargeFoyerPage.totalKey,
          lignes: <Widget>[
            LigneCleValeur(
              cle: t.adulte.recharge.total,
              valeur: recapitulatif.total,
              chiffres: true,
            ),
          ],
        ),
        if (etat != null) ...<Widget>[
          Ecart.vLg,
          _FocusALApparition(key: RechargeFoyerPage.focusEtatKey, child: etat),
        ],
        // Hors ligne : pourquoi « Payer » attend, sans jamais dire que rien
        // n'est paye (D5 : apres une coupure, l'ecran ne le sait pas).
        // Libelle provisoire, lexique D4.
        if (horsLigne && !arrete) ...<Widget>[
          Ecart.vLg,
          _Note(texte: t.adulte.recharge.horsLignePayer),
        ],
        // Un seul bouton dominant, 16 sous le total (ligne 16 d). Apres
        // l'etat honnete, le seul geste est le retour qu'il porte.
        if (etatPaiement != null) ...<Widget>[
          Ecart.vLg,
          _Actions(
            principale: ActionPrincipale(
              libelle: t.adulte.recharge.revenirPaiements,
              onPress: widget.onTerminee,
              pleineLargeur: false,
            ),
          ),
        ] else if (!arrete) ...<Widget>[
          Ecart.vLg,
          _Actions(
            principale: ActionPrincipale(
              key: RechargeFoyerPage.payerKey,
              libelle: t.adulte.recharge.payer(montant: recapitulatif.total),
              onPress: horsLigne
                  ? null
                  : () => unawaited(_payer(recapitulatif)),
              enCours: _paiementEnCours,
              pleineLargeur: false,
            ),
          ),
        ],
      ],
    );
  }
}
