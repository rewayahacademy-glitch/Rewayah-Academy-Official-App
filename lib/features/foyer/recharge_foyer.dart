// La recharge du foyer, un seul moteur (EA-10 puis FI-7 : guide Finance V4
// §1.6, §4, §5.3, maquettes 04 et 07) : deux etapes, puis le paiement qui
// s'arrete sur un etat honnete. « Recharger Mariam » (Foyer), « Recharger
// plusieurs profils » (carte de synthese) et « Recharger » (Compte >
// Paiements) ouvrent tous CETTE page, sur `/tuteur/foyer/recharge`.
//
// 1. « Recharge » : un, plusieurs ou tous les profils (une case par ligne,
//    « Tout selectionner » au-dessus de la liste), chacun avec son avatar,
//    son accent (K-62), son solde, et le montant qu'il recevra. Le montant se
//    choisit parmi ceux que la source rend (moins / plus), jamais saisi ni
//    calcule (K-57, FI6) ; il est desactive tant que le profil n'est pas
//    coche (§5.3). Le montant suggere par la source (le manque du mois) est
//    retenu a la coche. « Verifier la recharge » reste inactif tant qu'un
//    profil coche n'a pas de montant, avec une phrase qui dit pourquoi. La
//    repartition s'explique : un seul paiement, pas de solde commun.
// 2. « Verifier la recharge » : le recapitulatif SEPARE par profil que la
//    source arrete (`verifierMontants`, FI-BR-06 : qui recoit, montant paye,
//    solde attribue, remise seulement si rendue avec son libelle, statut), un
//    lien « Modifier » par profil qui revient a l'etape 1 sans rien perdre,
//    le total RENDU (jamais additionne ici), le moyen de paiement (seul le
//    paiement web, §1.6 : ni App Store ni Play), puis « Payer {total} ».
// 3. Le paiement n'a aucun prestataire branche : « Paiement pas encore
//    disponible », jamais « Paiement reussi » (F13). Une coupure dit
//    seulement que le paiement n'a pas ete confirme (D5) ; la meme cle rend
//    une nouvelle tentative sure. Le resultat et ses huit etats : FI-8.
//
// **Aucun chiffre economique calcule ici** (FI6) : les montants proposes,
// le recapitulatif et le total viennent du port. Rien sur le second adulte
// au-dela de ce que la recharge exige (F6, F10) : ni Classe, ni photo (Q4).
//
// Rien de recree (K-51) : `PageEtape`, `CarteGroupee`, `AvatarNom` et
// `BandeauProfil` (identite, K-62), `PhotoEleve` (K-44), `BoutonIcone`,
// `MontantArgent`, `LigneMoyenPaiement`, `LigneCleValeur`,
// `ActionPrincipale`, `EtatSysteme`, `BlocAsynchrone`, `Skeleton`,
// `LienFleche`, et les briques privees de l'invitation du titulaire (ce
// fichier en est une partie, comme l'acceptation d'EA-7 et la sortie
// d'EA-8).

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
    this.preselection = const <String>{},
  });

  /// Les profils deja coches a l'ouverture : « Recharger Mariam » ouvre le
  /// MEME flux que la recharge de plusieurs profils, Mariam cochee (guide
  /// Finance V4 §4, FI-4). Un identifiant qui n'est pas un beneficiaire
  /// rendu ne coche rien.
  final Set<String> preselection;

  /// Quitter depuis la premiere etape : retour aux paiements du foyer.
  final VoidCallback onAbandon;

  /// « Revenir aux paiements du foyer », apres le paiement.
  final VoidCallback onTerminee;

  /// « Tout selectionner » ou « Tout deselectionner ».
  static const Key toutSelectionnerKey = Key('recharge.toutSelectionner');

  /// La carte des profils a recharger (etape 1).
  static const Key profilsKey = Key('recharge.profils');

  /// L'explication de la repartition (« pas de solde commun »).
  static const Key repartitionKey = Key('recharge.repartition');

  /// « Verifier la recharge » (etape 1).
  static const Key verifierKey = Key('recharge.verifier');

  /// La phrase qui dit pourquoi « Verifier la recharge » est inactif.
  static const Key raisonKey = Key('recharge.raison');

  /// Le recapitulatif par beneficiaire (etape 2).
  static const Key recapitulatifKey = Key('recharge.recapitulatif');

  /// Le total rendu (etape 2).
  static const Key totalKey = Key('recharge.total');

  /// Le moyen de paiement (etape 2).
  static const Key moyenKey = Key('recharge.moyen');

  /// « Payer {total} » (etape 2).
  static const Key payerKey = Key('recharge.payer');

  /// Le titre de l'etape 2, qui prend le focus a son apparition.
  static const Key focusEtape2Key = Key('recharge.focusEtape2');

  /// Un echec ou l'etat du paiement, qui prend le focus a son apparition.
  static const Key focusEtatKey = Key('recharge.focusEtat');

  /// La case d'un beneficiaire.
  static Key caseDe(String beneficiaire) => Key('recharge.case.$beneficiaire');

  /// La ligne d'un beneficiaire a l'etape 1.
  static Key profilDe(String beneficiaire) =>
      Key('recharge.profil.$beneficiaire');

  /// Le montant choisi pour un beneficiaire (etape 1).
  static Key montantDe(String beneficiaire) =>
      Key('recharge.montant.$beneficiaire');

  /// « Diminuer le montant » d'un beneficiaire.
  static Key moinsDe(String beneficiaire) =>
      Key('recharge.moins.$beneficiaire');

  /// « Augmenter le montant » d'un beneficiaire.
  static Key plusDe(String beneficiaire) => Key('recharge.plus.$beneficiaire');

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
  /// Les beneficiaires coches, et le montant choisi pour chacun : gardes au
  /// retour de l'etape 2 (W-337), et le montant d'un beneficiaire decoche
  /// puis recoche aussi. Une entree `null` : le titulaire a retire le
  /// montant suggere ; aucune entree : le montant suggere s'applique.
  final Set<String> _selection = <String>{};
  final Map<String, Montant?> _montants = <String, Montant?>{};

  @override
  void initState() {
    super.initState();
    _selection.addAll(widget.preselection);
  }

  bool _verification = false;
  bool _verifEnCours = false;
  _EchecRecharge? _echecVerif;
  String? _dependanceVerif;
  RecapitulatifRecharge? _recapitulatif;

  /// Le moyen de paiement retenu : le seul rendu au lancement (guide §1.6).
  RailPaiement _rail = RailPaiement.webStripe;

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

  /// Le montant retenu pour [b] : celui que le titulaire a choisi, sinon le
  /// montant suggere par la source. Un montant nul n'est jamais retenu.
  Montant? _montantDe(BeneficiaireRecharge b) {
    final Montant? m = _montants.containsKey(b.id)
        ? _montants[b.id]
        : b.montantSuggere;
    return m == null || m.estNul ? null : m;
  }

  List<MontantRecharge> _choix(List<BeneficiaireRecharge> liste) =>
      <MontantRecharge>[
        for (final BeneficiaireRecharge b in liste)
          if (_selection.contains(b.id))
            if (_montantDe(b) case final Montant m)
              MontantRecharge(beneficiaireId: b.id, montant: m),
      ];

  /// Au moins un beneficiaire coche, et un montant pour chacun.
  bool _pret(List<BeneficiaireRecharge> liste) {
    final int coches = liste
        .where((BeneficiaireRecharge b) => _selection.contains(b.id))
        .length;
    return coches > 0 && _choix(liste).length == coches;
  }

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

  /// Le montant voisin dans la liste rendue : le suivant ([pas] = 1) ou le
  /// precedent ([pas] = -1) ; avant le premier, aucun montant. Rien n'est
  /// additionne : l'ecran se deplace dans la liste de la source (FI6).
  void _deplacer(BeneficiaireRecharge b, int pas) => setState(() {
    final List<Montant> proposes = b.montantsProposes;
    final int i = switch (_montantDe(b)) {
      final Montant m => proposes.indexOf(m),
      null => -1,
    };
    final int cible = i + pas;
    _montants[b.id] = cible < 0 || cible >= proposes.length
        ? null
        : proposes[cible];
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
          .verifierMontants(_choix(liste));
    } on CapaciteIndisponible catch (e) {
      if (mounted) {
        setState(() {
          _verifEnCours = false;
          _echecVerif = _EchecRecharge.indisponible;
          _dependanceVerif = e.dependance;
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
      // Retour sans perte : les cases et les montants restent (W-337).
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

  /// L'accent de profil choisi par le tuteur (K-62), `null` sans choix.
  AccentProfil? _accent(String id) =>
      accentLu(ref.watch(accentsProfilsProvider), id);

  Widget _pageBeneficiaires(BuildContext context, bool horsLigne) {
    final AsyncValue<List<BeneficiaireRecharge>> lecture = ref.watch(
      beneficiairesRechargeProvider,
    );
    void relire() => ref.invalidate(beneficiairesRechargeProvider);
    final Object? erreur = lecture.hasError ? lecture.error : null;
    final Widget corps;
    if (erreur is CapaciteIndisponible) {
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
        // « Recharge » et « Choisissez les profils et les montants »
        // (maquette 04).
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
    final bool aucun = !liste.any(
      (BeneficiaireRecharge b) => _selection.contains(b.id),
    );
    // Pourquoi le bouton attend (K-59).
    final String? raison = aucun
        ? t.adulte.recharge.raisonAucun
        : pret
        ? null
        : t.adulte.recharge.raisonMontant;
    // Le montant en bout de ligne quand la place le permet (tablette,
    // bureau, texte peu agrandi) ; sinon sous la ligne, au bord de fin.
    final bool enLigne =
        AppGabarit.classe(MediaQuery.sizeOf(context).width) !=
            ClasseLargeur.compacte &&
        MediaQuery.textScalerOf(context).scale(1) <=
            AppGabarit.seuilTexteColonne;
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
            Semantics(
              header: true,
              child: Text(
                t.adulte.recharge.profils,
                style: palette.inkStrong.applyTo(
                  textes.titleMedium ?? const TextStyle(),
                ),
              ),
            ),
            LienFleche(
              key: RechargeFoyerPage.toutSelectionnerKey,
              libelle: tout
                  ? t.adulte.recharge.toutDeselectionner
                  : t.adulte.recharge.toutSelectionner,
              fleche: false,
              onPress: () => _toutSelectionner(liste, !tout),
            ),
          ],
        ),
        Ecart.vSm,
        // Une seule carte a lignes fines : les profils sont lies par le
        // meme paiement (K-55).
        KeyedSubtree(
          key: RechargeFoyerPage.profilsKey,
          child: CarteGroupee(
            sections: <Widget>[
              for (final BeneficiaireRecharge b in liste)
                _ligneProfil(context, b, enLigne: enLigne),
            ],
          ),
        ),
        Ecart.vLg,
        // La repartition (guide §5.3) : un seul paiement, chaque montant au
        // solde de son profil, jamais un solde commun.
        _Note(
          key: RechargeFoyerPage.repartitionKey,
          texte: t.adulte.recharge.repartition,
          attenuee: true,
        ),
        if (_echecVerif case final _EchecRecharge echec) ...<Widget>[
          Ecart.vLg,
          _FocusALApparition(
            key: RechargeFoyerPage.focusEtatKey,
            child: switch (echec) {
              // Une lecture manquee : rien n'a ete paye, les choix restent.
              _EchecRecharge.reseau => EtatSysteme(
                nature: NatureEtat.echecServeur,
                titre: t.adulte.recharge.verificationEchecTitre,
                phrase: t.adulte.recharge.verificationEchecPhrase,
              ),
              _EchecRecharge.indisponible => EtatSysteme(
                nature: NatureEtat.indisponible,
                titre: t.adulte.recharge.indisponibleTitre,
                phrase: t.adulte.recharge.indisponiblePhrase,
                dependance: _dependanceVerif,
              ),
            },
          ),
        ],
        // Hors ligne : rien ne part tout seul.
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

  /// La ligne d'un profil : sa case, son identite (avatar, accent, prenom,
  /// solde, montant suggere) et son montant, desactive tant qu'il n'est pas
  /// coche (guide §5.3).
  Widget _ligneProfil(
    BuildContext context,
    BeneficiaireRecharge b, {
    required bool enLigne,
  }) {
    final bool coche = _selection.contains(b.id);
    final String? solde = switch (b.solde) {
      final Montant m => t.adulte.recharge.soldeActuel(
        montant: formaterMontant(m),
      ),
      null => b.soldeRendu,
    };
    final String? suggere = switch (b.montantSuggere) {
      final Montant m => t.adulte.recharge.montantSuggere(
        montant: formaterMontant(m),
      ),
      null => null,
    };
    final TextStyle styleRole = AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle());
    // La case et l'identite se lisent d'un bloc : « Mariam, Solde actuel :
    // 12 $, case cochee ». Le montant se lit a part, avec ses boutons.
    final Widget identite = MergeSemantics(
      child: Row(
        children: <Widget>[
          Checkbox(
            key: RechargeFoyerPage.caseDe(b.id),
            value: coche,
            onChanged: _occupe
                ? null
                : (bool? valeur) => _basculer(b.id, valeur ?? false),
          ),
          Ecart.hSm,
          Expanded(
            child: AvatarNom.enLigne(
              prenom: b.prenom,
              avatar: PhotoEleve(
                prenom: b.prenom,
                cleAvatar: b.cleAvatar,
                diametre: AppAvatar.moyen,
              ),
              enveloppeAvatar: BandeauProfil.enveloppe(
                diametre: AppAvatar.moyen,
                accent: _accent(b.id),
              ),
              texteEtire: true,
              styleNom: AppPalette.of(context).inkStrong.applyTo(
                Theme.of(context).textTheme.titleSmall ?? const TextStyle(),
              ),
              roleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (solde != null) Text(solde, style: styleRole),
                  if (suggere != null) Text(suggere, style: styleRole),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    final Widget montant = _montantProfil(b, actif: coche && !_occupe);
    return KeyedSubtree(
      key: RechargeFoyerPage.profilDe(b.id),
      child: enLigne
          ? Row(
              children: <Widget>[
                Expanded(child: identite),
                Ecart.hMd,
                montant,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                identite,
                Ecart.vSm,
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: montant,
                ),
              ],
            ),
    );
  }

  /// Moins, le montant, plus. Desactive (profil non coche) : le montant se
  /// lit « 0 » attenue, comme la maquette 04, sans bouton. Un bouton qui ne
  /// peut pas aboutir n'est jamais grise (K-56) : au premier et au dernier
  /// montant, comme les fleches de `BarrePrecedentSuivant`, il disparait et
  /// sa place reste, pour que le montant ne bouge pas.
  Widget _montantProfil(BeneficiaireRecharge b, {required bool actif}) {
    final List<Montant> proposes = b.montantsProposes;
    final Montant? choisi = _montantDe(b);
    final int i = choisi == null ? -1 : proposes.indexOf(choisi);
    final String? devise = proposes.firstOrNull?.devise;
    final Montant? zero = devise == null ? null : Montant(0, devise);
    final Montant? affiche = actif ? choisi ?? zero : zero;
    const Widget place = SizedBox.square(dimension: AppTouchTarget.standard);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (actif && choisi != null)
          BoutonIcone(
            key: RechargeFoyerPage.moinsDe(b.id),
            icone: AppIcons.moins,
            libelle: t.adulte.recharge.diminuer(prenom: b.prenom),
            onPress: () => _deplacer(b, -1),
          )
        else
          place,
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: AppSpacing.respiration),
          child: Semantics(
            label: t.adulte.recharge.montantPour(prenom: b.prenom),
            liveRegion: actif,
            child: Center(
              widthFactor: 1,
              child: KeyedSubtree(
                key: RechargeFoyerPage.montantDe(b.id),
                child: affiche == null
                    ? const SizedBox.shrink()
                    : MontantArgent(affiche, attenue: !actif || choisi == null),
              ),
            ),
          ),
        ),
        if (actif && i + 1 < proposes.length)
          BoutonIcone(
            key: RechargeFoyerPage.plusDe(b.id),
            icone: AppIcons.ajouter,
            libelle: t.adulte.recharge.augmenter(prenom: b.prenom),
            onPress: () => _deplacer(b, 1),
          )
        else
          place,
      ],
    );
  }

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
    // Les moyens que la politique active ouvre, sinon le seul paiement web
    // du lancement (guide §1.6) ; jamais un rail StoreKit ou Play.
    final Set<RailPaiement> ouverts =
        ref.watch(politiqueActiveProvider).value?.railsActifs ??
        const <RailPaiement>{RailPaiement.webStripe};
    final List<RailPaiement> rails = <RailPaiement>[
      for (final RailPaiement r in RailPaiement.values)
        if (ouverts.contains(r) && LigneMoyenPaiement.estMontre(r)) r,
    ];
    Widget titre(String texte) => Semantics(
      header: true,
      child: Text(
        texte,
        style: palette.inkStrong.applyTo(
          textes.titleMedium ?? const TextStyle(),
        ),
      ),
    );
    final Widget? etat = switch ((_echecPaiement, etatPaiement)) {
      // D5 : l'ecran ne dit que ce qu'il sait, le paiement n'est pas
      // confirme ; la meme cle rend une nouvelle tentative sure.
      (_EchecRecharge.reseau, _) => EtatSysteme(
        nature: NatureEtat.echecServeur,
        titre: t.adulte.recharge.paiementEchecTitre,
        phrase: t.adulte.recharge.paiementEchecPhrase,
      ),
      // L'etat honnete (F13) : aucun paiement, jamais « reussi ».
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
        titre(t.adulte.recharge.recapitulatif),
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
                  // Qui recoit : sa photo ou ses initiales (K-44) et son
                  // accent (K-62), sans Classe (F6).
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: AvatarNom.enLigne(
                      prenom: l.prenom,
                      avatar: PhotoEleve(
                        prenom: l.prenom,
                        cleAvatar: l.cleAvatar,
                        diametre: AppAvatar.moyen,
                      ),
                      enveloppeAvatar: BandeauProfil.enveloppe(
                        diametre: AppAvatar.moyen,
                        accent: _accent(l.beneficiaireId),
                      ),
                      styleNom: palette.inkStrong.applyTo(
                        textes.titleMedium ?? const TextStyle(),
                      ),
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
        // Le total rendu, jamais additionne ici (ligne 16 b, FI6), et la
        // repartition dite a cote (guide §5.3).
        _Carte(
          key: RechargeFoyerPage.totalKey,
          lignes: <Widget>[
            LigneCleValeur(
              cle: t.adulte.recharge.total,
              valeur: recapitulatif.total,
              chiffres: true,
            ),
            Ecart.vSm,
            _Note(texte: t.adulte.recharge.repartition, attenuee: true),
          ],
        ),
        Ecart.vLg,
        // Le moyen de paiement (guide §1.6, §5.3) : seul le paiement web.
        titre(t.adulte.recharge.moyen),
        Ecart.vSm,
        Column(
          key: RechargeFoyerPage.moyenKey,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final (int i, RailPaiement r) in rails.indexed) ...<Widget>[
              if (i > 0) Ecart.vLg,
              LigneMoyenPaiement(
                rail: r,
                retenu: r == _rail,
                // Le rail retenu ne part pas avec le paiement : le choisir
                // reste sans effet sur une tentative en cours.
                onPress: () => setState(() => _rail = r),
              ),
            ],
          ],
        ),
        if (etat != null) ...<Widget>[
          Ecart.vLg,
          _FocusALApparition(key: RechargeFoyerPage.focusEtatKey, child: etat),
        ],
        // Hors ligne : pourquoi « Payer » attend, sans jamais dire que rien
        // n'est paye (D5 : apres une coupure, l'ecran ne le sait pas).
        if (horsLigne && !arrete) ...<Widget>[
          Ecart.vLg,
          _Note(texte: t.adulte.recharge.horsLignePayer),
        ],
        // Un seul bouton dominant, 16 sous le moyen de paiement. Apres
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
              onPress: horsLigne || rails.isEmpty
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
