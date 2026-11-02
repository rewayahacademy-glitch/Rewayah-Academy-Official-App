// La recharge du foyer, un seul moteur (EA-10 puis FI-7 : guide Finance V4
// §1.6, §4, §5.3, maquettes 04 et 07) : UNE page, sans etapes (revue
// FI-VAGUE-R, R3-01 ; UX_REVIEW_08 ligne 6 a et e, E-4), puis le paiement
// qui s'arrete sur un etat honnete. « Recharger Mariam » (Foyer),
// « Recharger plusieurs profils » (carte de synthese) et « Recharger »
// (Compte > Paiements) ouvrent tous CETTE page, sur `/tuteur/foyer/recharge`.
//
// - « Profils a recharger » : un ou plusieurs profils (une case par ligne,
//   sans « Tout selectionner », E-14), chacun avec son avatar, son accent
//   (K-62), son solde, et le montant qu'il recevra. Le montant se choisit
//   parmi ceux que la source rend (moins / plus), jamais saisi ni calcule
//   (K-57, FI6) ; il est desactive tant que le profil n'est pas coche
//   (§5.3). Le montant suggere par la source (le manque du mois) est retenu
//   a la coche.
// - Le recapitulatif SEPARE par profil, sur la meme page : a chaque choix,
//   la source l'arrete (`verifierMontants`, FI-BR-06 : qui recoit, montant
//   paye, solde attribue, remise seulement si rendue avec son libelle,
//   statut) et rend le total, affiche tel quel (jamais additionne ici, E-3).
//   Une reponse depassee par un choix plus recent est ignoree. La
//   repartition s'explique : un seul paiement, pas de solde commun.
// - Le moyen de paiement (seul le paiement web, §1.6 : ni App Store ni
//   Play), puis « Payer {total} » : le total que la source vient de rendre.
//   Si elle le change apres un choix, le bouton dit le nouveau total ; tant
//   qu'elle ne l'a pas rendu, il attend, avec une phrase qui dit pourquoi.
// - Sur bureau (classe large, a partir de 1200, maquette 07, K-63) : trois
//   colonnes, comme la maquette. A gauche les profils ; au milieu l'aide
//   (l'explication du paiement unique, puis les trois faits deja dits au
//   bas de la fiche Finances : pas de consommation par seance, acces lie a
//   la periode financee, absences ordinaires ; aucun texte neuf) ; a droite
//   le recapitulatif, le moyen et « Payer » (revue FI-VAGUE-CORR-R R3-02,
//   decide par delegation le 08/10 : la maquette). Dessous, le bandeau
//   « Acces a regulariser » sans croix (Q-FI-6), dont le lien « Ajouter
//   {prenom} a la recharge » coche le profil avec le montant suggere (revue
//   ligne 7 d). Plus etroit : une seule colonne, le bandeau en tete.
// - « Payer » : le port rend l'identifiant de la commande et l'ecran ouvre
//   son resultat (`ResultatRechargePage`, FI-8), qui relit l'etat ; jamais
//   un succes local (F13). Sans prestataire branche (production) :
//   « Paiement pas encore disponible ». Une coupure dit seulement que le
//   paiement n'a pas ete confirme (D5) ; la meme cle rend une nouvelle
//   tentative sure, et la meme commande. Des que le paiement est parti, les
//   choix se figent : un autre recapitulatif tirerait une autre cle.
//
// **Aucun chiffre economique calcule ici** (FI6) : les montants proposes,
// le recapitulatif et le total viennent du port. Rien sur le second adulte
// au-dela de ce que la recharge exige (F6, F10) : ni Classe, ni photo (Q4).
//
// Rien de recree (K-51) : `PageShell`, `CarteGroupee`, `AvatarNom` et
// `BandeauProfil` (identite, K-62), `PhotoEleve` (K-44), `BoutonIcone`,
// `MontantArgent`, `LigneMoyenPaiement`, `LigneCleValeur`,
// `BandeauAttention`, `ActionPrincipale`, `EtatSysteme`, `BlocAsynchrone`,
// `Skeleton`, `LienFleche`, et les briques privees de l'invitation du
// titulaire (ce fichier en est une partie, comme l'acceptation d'EA-7 et la
// sortie d'EA-8).

part of 'invitation_conjoint.dart';

/// Ce que l'ecran dit apres une verification ou un paiement manques.
enum _EchecRecharge { reseau, indisponible }

/// La recharge du foyer, pour le titulaire seulement.
class RechargeFoyerPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const RechargeFoyerPage({
    required this.onAbandon,
    required this.onTerminee,
    required this.onPaye,
    super.key,
    this.preselection = const <String>{},
    this.montantsInitiaux = const <String, Montant>{},
    this.regularisation = true,
  });

  /// Les profils deja coches a l'ouverture : « Recharger Mariam » ouvre le
  /// MEME flux que la recharge de plusieurs profils, Mariam cochee (guide
  /// Finance V4 §4, FI-4). Un identifiant qui n'est pas un beneficiaire
  /// rendu ne coche rien.
  final Set<String> preselection;

  /// Les montants rappeles a l'ouverture (« Reessayer » apres un echec,
  /// FI-8) : un montant n'est retenu que s'il fait partie de ceux que la
  /// source propose a ce profil ; sinon le montant suggere s'applique.
  final Map<String, Montant> montantsInitiaux;

  /// Faux pour ne jamais lire les finances du foyer (le bandeau « Acces a
  /// regulariser ») : l'eleve adulte autonome ne recharge que son profil,
  /// et rien d'un autre membre n'est charge pour lui (FI-9b).
  final bool regularisation;

  /// Le paiement a rendu la commande [commandeId] : ouvrir son resultat.
  final ValueChanged<String> onPaye;

  /// Quitter avant le paiement : retour a l'ecran d'ou la recharge a ete
  /// ouverte (le Foyer, ou Compte > Paiements).
  final VoidCallback onAbandon;

  /// Le retour une fois le paiement parti (ou peut-etre parti, D5) : la ou
  /// l'on verifie.
  final VoidCallback onTerminee;

  /// La carte des profils a recharger.
  static const Key profilsKey = Key('recharge.profils');

  /// La colonne d'aide du milieu, sur bureau (maquette 07, R3-02).
  static const Key aideKey = Key('recharge.aide');

  /// L'explication de la repartition (« pas de solde commun »).
  static const Key repartitionKey = Key('recharge.repartition');

  /// La phrase qui dit pourquoi « Payer » attend.
  static const Key raisonKey = Key('recharge.raison');

  /// Le recapitulatif par beneficiaire, rendu par la source.
  static const Key recapitulatifKey = Key('recharge.recapitulatif');

  /// La carte du total rendu.
  static const Key totalKey = Key('recharge.total');

  /// Le moyen de paiement.
  static const Key moyenKey = Key('recharge.moyen');

  /// « Payer {total} ».
  static const Key payerKey = Key('recharge.payer');

  /// Le lien vers les conditions de remboursement et de contestation (FN-115).
  static const Key conditionsKey = Key('recharge.conditions');

  /// La phrase sur les frais d'une contestation bancaire (FN-115).
  static const Key fraisContestationKey = Key('recharge.fraisContestation');

  /// « Suivre le paiement », une fois la commande rendue.
  static const Key suivreKey = Key('recharge.suivre');

  /// Un echec ou l'etat du paiement, qui prend le focus a son apparition.
  static const Key focusEtatKey = Key('recharge.focusEtat');

  /// Le bandeau « Acces a regulariser ».
  static const Key bandeauKey = Key('recharge.bandeau');

  /// La case d'un beneficiaire.
  static Key caseDe(String beneficiaire) => Key('recharge.case.$beneficiaire');

  /// La ligne d'un beneficiaire dans « Profils a recharger ».
  static Key profilDe(String beneficiaire) =>
      Key('recharge.profil.$beneficiaire');

  /// Le montant choisi pour un beneficiaire.
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

  /// « Ajouter {prenom} a la recharge », dans le bandeau.
  static Key ajouterDe(String beneficiaire) =>
      Key('recharge.ajouter.$beneficiaire');

  @override
  ConsumerState<RechargeFoyerPage> createState() => _RechargeFoyerPageState();
}

class _RechargeFoyerPageState extends ConsumerState<RechargeFoyerPage> {
  /// Les beneficiaires coches, et le montant choisi pour chacun : le montant
  /// d'un beneficiaire decoche puis recoche est garde (W-337). Une entree
  /// `null` : le titulaire a retire le montant suggere ; aucune entree : le
  /// montant suggere s'applique.
  final Set<String> _selection = <String>{};
  final Map<String, Montant?> _montants = <String, Montant?>{};

  @override
  void initState() {
    super.initState();
    _selection.addAll(widget.preselection);
    // Les beneficiaires deja lus : le recapitulatif de la selection
    // d'ouverture part une fois, de lui-meme. Sinon, leur lecture le
    // declenche (`ref.listen` dans `build`).
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted && ref.read(beneficiairesRechargeProvider).hasValue) {
        _actualiser();
      }
    });
  }

  /// Le numero de la derniere demande de recapitulatif : une reponse plus
  /// ancienne est ignoree, elle ne correspond plus aux choix affiches.
  int _demande = 0;
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

  /// La commande rendue par le paiement : plus de « Payer » sur cette page,
  /// seulement son suivi (FI-8, « Ne payez pas une seconde fois »).
  String? _commande;

  /// La reponse d'un paiement est perdue (D5) : il est peut-etre passe. Les
  /// choix ne se modifient plus et la cle reste la meme ; seule une nouvelle
  /// tentative (meme cle) ou le retour aux paiements du foyer, ou l'on
  /// verifie, reste possible : jamais un second paiement sous une autre cle.
  /// Une recharge rouverte plus tard tire une autre cle : seul le serveur
  /// peut alors reconnaitre le paiement en suspens (EA-BR-26).
  bool get _paiementIncertain => _echecPaiement == _EchecRecharge.reseau;

  /// Le paiement est parti, part, ou s'est arrete sur l'etat honnete : les
  /// choix se figent, le recapitulatif aussi.
  bool get _engage =>
      _paiementEnCours || _commande != null || _echecPaiement != null;

  /// Le montant retenu pour [b] : celui que le titulaire a choisi, sinon le
  /// montant rappele s'il est propose (FI-8), sinon le montant suggere par
  /// la source. Un montant nul n'est jamais retenu.
  Montant? _montantDe(BeneficiaireRecharge b) {
    final Montant? rappele = widget.montantsInitiaux[b.id];
    final Montant? m = _montants.containsKey(b.id)
        ? _montants[b.id]
        : rappele != null && b.montantsProposes.contains(rappele)
        ? rappele
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

  /// Les choix ont change (ou le reseau, ou la liste) : le recapitulatif
  /// affiche ne vaut plus. Un nouveau part si les choix sont complets et le
  /// reseau present ; sinon la page dit pourquoi « Payer » attend.
  void _actualiser() {
    if (!mounted || _engage) return;
    final List<BeneficiaireRecharge>? liste = ref
        .read(beneficiairesRechargeProvider)
        .value;
    final bool horsLigne = ref.read(horsLigneProvider).value ?? false;
    final int demande = ++_demande;
    if (liste == null || horsLigne || !_pret(liste)) {
      setState(() {
        _verifEnCours = false;
        _echecVerif = null;
        _recapitulatif = null;
      });
      return;
    }
    unawaited(_verifier(liste, demande));
  }

  void _basculer(String id, bool coche) {
    setState(() {
      if (coche) {
        _selection.add(id);
      } else {
        _selection.remove(id);
      }
    });
    _actualiser();
  }

  /// « Ajouter {prenom} a la recharge » (bandeau) : le profil coche, avec le
  /// montant que la source suggere (revue ligne 7 d).
  void _ajouter(BeneficiaireRecharge b) {
    setState(() {
      _selection.add(b.id);
      _montants.remove(b.id);
    });
    _actualiser();
  }

  /// Le montant voisin dans la liste rendue : le suivant ([pas] = 1) ou le
  /// precedent ([pas] = -1) ; avant le premier, aucun montant. Rien n'est
  /// additionne : l'ecran se deplace dans la liste de la source (FI6).
  void _deplacer(BeneficiaireRecharge b, int pas) {
    setState(() {
      final List<Montant> proposes = b.montantsProposes;
      final int i = switch (_montantDe(b)) {
        final Montant m => proposes.indexOf(m),
        null => -1,
      };
      final int cible = i + pas;
      _montants[b.id] = cible < 0 || cible >= proposes.length
          ? null
          : proposes[cible];
    });
    _actualiser();
  }

  Future<void> _verifier(List<BeneficiaireRecharge> liste, int demande) async {
    setState(() {
      // Le recapitulatif d'avant reste lisible, « Payer » attend le nouveau.
      _verifEnCours = true;
      _echecVerif = null;
    });
    final RecapitulatifRecharge recapitulatif;
    try {
      recapitulatif = await ref
          .read(portRechargeFoyerProvider)
          .verifierMontants(_choix(liste));
    } on CapaciteIndisponible catch (e) {
      if (mounted && demande == _demande) {
        setState(() {
          _verifEnCours = false;
          _recapitulatif = null;
          _echecVerif = _EchecRecharge.indisponible;
          _dependanceVerif = e.dependance;
        });
      }
      return;
    } on Object {
      if (mounted && demande == _demande) {
        setState(() {
          _verifEnCours = false;
          _recapitulatif = null;
          _echecVerif = _EchecRecharge.reseau;
        });
      }
      return;
    }
    if (!mounted || demande != _demande) return;
    setState(() {
      _verifEnCours = false;
      _recapitulatif = recapitulatif;
      _cle = const Uuid().v4();
    });
  }

  void _retour() {
    if (_paiementEnCours) return;
    if (_paiementIncertain || _commande != null) {
      // Paiement non confirme (D5) ou commande rendue : le retour mene la ou
      // l'on verifie, jamais a une recharge qui tirerait une autre cle.
      widget.onTerminee();
      return;
    }
    widget.onAbandon();
  }

  Future<void> _payer(RecapitulatifRecharge recapitulatif) async {
    // Double envoi : un seul appel part, le bouton attend la reponse ; une
    // commande deja rendue ne se repaie pas (FI-8).
    if (_paiementEnCours || _verifEnCours || _commande != null) return;
    setState(() {
      _paiementEnCours = true;
      _echecPaiement = null;
    });
    _EchecRecharge? echec;
    String? commande;
    try {
      commande = await ref
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
      _commande = commande;
    });
    // Le resultat relit l'etat de la commande (FI-8) : rien n'est conclu ici.
    if (commande != null) widget.onPaye(commande);
  }

  @override
  Widget build(BuildContext context) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    // La liste lue (ou relue apres un echec) et le reseau revenu ou perdu :
    // le recapitulatif suit, sans geste de plus.
    ref
      ..listen<AsyncValue<List<BeneficiaireRecharge>>>(
        beneficiairesRechargeProvider,
        (
          AsyncValue<List<BeneficiaireRecharge>>? _,
          AsyncValue<List<BeneficiaireRecharge>> apres,
        ) {
          if (apres.hasValue && !apres.isLoading) _actualiser();
        },
      )
      ..listen<AsyncValue<bool>>(horsLigneProvider, (
        AsyncValue<bool>? avant,
        AsyncValue<bool> apres,
      ) {
        if ((avant?.value ?? false) != (apres.value ?? false)) _actualiser();
      });
    return PopScope(
      canPop: !_paiementEnCours && !_paiementIncertain && _commande == null,
      onPopInvokedWithResult: (bool fait, Object? _) {
        if (!fait) _retour();
      },
      // « Recharge » et « Choisissez les profils et les montants »
      // (maquette 04, Q-FI-5) : un titre, aucune barre d'etape.
      child: PageShell(
        actionsCoquille: false,
        titre: t.adulte.recharge.titre,
        // Un seul beneficiaire rendu (adulte autonome, foyer d'un enfant) :
        // la phrase au singulier (revue FI-VAGUE-R R4-06).
        sousTitre: _unSeul(ref.watch(beneficiairesRechargeProvider).value)
            ? t.adulte.recharge.phraseUnique
            : t.adulte.recharge.phrase,
        onRetour: _retour,
        child: _corps(context, horsLigne),
      ),
    );
  }

  /// Vrai quand la source ne rend qu'un beneficiaire : rien a repartir.
  static bool _unSeul(List<BeneficiaireRecharge>? liste) => liste?.length == 1;

  /// L'accent de profil choisi par le tuteur (K-62), `null` sans choix.
  AccentProfil? _accent(String id) =>
      accentLu(ref.watch(accentsProfilsProvider), id);

  Widget _corps(BuildContext context, bool horsLigne) {
    // Hors ligne, des beneficiaires deja lus restent affiches
    // (EA-HL-DOUBLE-1).
    final AsyncValue<List<BeneficiaireRecharge>> lecture = lectureHorsLigne(
      ref.watch(beneficiairesRechargeProvider),
      horsLigne: horsLigne,
    );
    void relire() => ref.invalidate(beneficiairesRechargeProvider);
    final Object? erreur = lecture.hasError ? lecture.error : null;
    final Widget etat;
    if (erreur is CapaciteIndisponible) {
      etat = EtatSysteme(
        nature: NatureEtat.indisponible,
        titre: t.adulte.recharge.indisponibleTitre,
        phrase: t.adulte.recharge.indisponiblePhrase,
        dependance: erreur.dependance,
      );
    } else if (sansDonneesHorsLigne(lecture, horsLigne: horsLigne)) {
      // Sans reseau ni beneficiaires deja lus : le bandeau de `PageShell` dit
      // le reseau, le bloc dit ce qui manque (EA-HL-DOUBLE-1).
      etat = EtatSansDonnees(
        quoi: t.adulte.recharge.sansDonnees,
        onAction: relire,
      );
    } else {
      return BlocAsynchrone<List<BeneficiaireRecharge>>(
        valeur: lecture,
        squelette: const _Colonne(auBordDeDebut: true, child: Skeleton.liste()),
        onReessayer: relire,
        estVide: (List<BeneficiaireRecharge> l) => l.isEmpty,
        // Les textes des soldes vides (EA-9), libelles provisoires D4.
        vide: _Colonne(
          auBordDeDebut: true,
          child: EtatSysteme(
            nature: NatureEtat.aucunResultat,
            titre: t.adulte.paiements.aucunBeneficiaireTitre,
            phrase: t.adulte.paiements.aucunBeneficiairePhrase,
          ),
        ),
        construire: (List<BeneficiaireRecharge> liste) =>
            _contenu(context, liste, horsLigne),
      );
    }
    return _Colonne(auBordDeDebut: true, child: etat);
  }

  /// La page, une fois les profils lus : une colonne, ou les profils et le
  /// paiement cote a cote a partir de la classe large (maquette 07 ; contrat
  /// D : jamais une colonne de telephone centree sur un bureau).
  Widget _contenu(
    BuildContext context,
    List<BeneficiaireRecharge> liste,
    bool horsLigne,
  ) {
    final bool large =
        AppGabarit.classe(MediaQuery.sizeOf(context).width) ==
        ClasseLargeur.large;
    final Widget profils = _profils(context, liste, large: large);
    // La repartition (guide §5.3) : un seul paiement, chaque montant au
    // solde de son profil, jamais un solde commun. Sans objet pour un seul
    // profil (revue FI-VAGUE-R R4-06). Toujours sous le total qu'elle
    // explique, dans la colonne du paiement.
    final Widget? repartition = _unSeul(liste)
        ? null
        : _Note(
            key: RechargeFoyerPage.repartitionKey,
            texte: t.adulte.recharge.repartition,
            attenuee: true,
          );
    final Widget? bandeau = _bandeau(liste);
    // Sur bureau, l'explication passe dans la colonne d'aide du milieu.
    final Widget paiement = _paiement(
      context,
      liste,
      horsLigne,
      repartition: large ? null : repartition,
    );
    if (!large) {
      return _Colonne(
        auBordDeDebut: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (bandeau != null) ...<Widget>[bandeau, Ecart.vXl],
            profils,
            Ecart.vXl,
            paiement,
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Les trois colonnes de la maquette 07 : profils, aide, paiement.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: 5, child: profils),
            Ecart.hXl,
            // La carte d'aide n'a pas de titre (aucun texte neuf) : une
            // reserve de la hauteur d'un titre de groupe, muette et
            // invisible, aligne son haut sur les cartes voisines.
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ExcludeSemantics(
                    child: Opacity(
                      opacity: 0,
                      child: _titreGroupe(
                        context,
                        t.adulte.recharge.recapitulatif,
                      ),
                    ),
                  ),
                  Ecart.vSm,
                  _aide(context, repartition),
                ],
              ),
            ),
            Ecart.hXl,
            Expanded(flex: 4, child: paiement),
          ],
        ),
        if (bandeau != null) ...<Widget>[Ecart.vXxl, bandeau],
      ],
    );
  }

  /// La colonne d'aide du milieu (maquette 07) : l'explication du paiement
  /// unique quand plusieurs profils sont rechargeables, puis les trois
  /// faits du bas de la fiche Finances, avec leurs icones (textes existants,
  /// aucun texte neuf ; R3-02, decide par delegation le 08/10).
  Widget _aide(BuildContext context, Widget? repartition) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle style = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
    );
    final finances = t.ficheEleve.finances;
    final List<({AppIcon icone, String texte})> faits =
        <({AppIcon icone, String texte})>[
          (icone: AppIcons.creneaux, texte: finances.faitSeance),
          (icone: AppIcons.horloge, texte: finances.faitPeriode),
          (icone: AppIcons.historique, texte: finances.noteAbsences),
        ];
    return _Carte(
      key: RechargeFoyerPage.aideKey,
      lignes: <Widget>[
        if (repartition != null) ...<Widget>[repartition, Ecart.vLg],
        for (final (int i, ({AppIcon icone, String texte}) f)
            in faits.indexed) ...<Widget>[
          if (i > 0) Ecart.vMd,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ExcludeSemantics(
                child: IconTheme(
                  data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                  child: Icon(f.icone.repos),
                ),
              ),
              Ecart.hSm,
              Expanded(child: Text(f.texte, style: style)),
            ],
          ),
        ],
      ],
    );
  }

  /// Le titre d'un groupe de la page.
  Widget _titreGroupe(BuildContext context, String texte) => Semantics(
    header: true,
    child: Text(
      texte,
      style: AppPalette.of(context).inkStrong.applyTo(
        Theme.of(context).textTheme.titleMedium ?? const TextStyle(),
      ),
    ),
  );

  /// « Profils a recharger » : une seule carte a lignes fines, les profils
  /// etant lies par le meme paiement (K-55). [large] : la colonne du bureau.
  Widget _profils(
    BuildContext context,
    List<BeneficiaireRecharge> liste, {
    required bool large,
  }) {
    // Le montant en bout de ligne quand la place le permet (tablette,
    // bureau, texte peu agrandi) ; sinon sous la ligne, au bord de fin.
    final bool place =
        AppGabarit.classe(MediaQuery.sizeOf(context).width) !=
            ClasseLargeur.compacte &&
        MediaQuery.textScalerOf(context).scale(1) <=
            AppGabarit.seuilTexteColonne;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        // La colonne elle-meme doit aussi avoir la place : sur bureau, la
        // moitie de la page ne fait que 430 a 1200 et 470 a 1280, et le
        // solde, serre a cote du montant, y passait sur trois lignes
        // (contre-revue FI-VAGUE-CORR).
        final bool enLigne =
            place && contraintes.maxWidth >= _colonneMontantEnLigne;
        return _listeProfils(context, liste, enLigne: enLigne, large: large);
      },
    );
  }

  /// La largeur de colonne en deca de laquelle le montant passe sous
  /// l'identite : la colonne de dialogue, moins la gouttiere qui separe les
  /// deux colonnes du bureau (540). A 1440 la colonne fait 550 et garde le
  /// montant en ligne ; a 1200 et 1280 il passe dessous.
  static const double _colonneMontantEnLigne =
      AppPage.largeurDialogue - AppSpacing.xl;

  /// Le titre et la carte des profils, le montant [enLigne] ou dessous.
  Widget _listeProfils(
    BuildContext context,
    List<BeneficiaireRecharge> liste, {
    required bool enLigne,
    required bool large,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Le titre au singulier pour un seul profil (revue FI-VAGUE-R R4-06).
        _titreGroupe(
          context,
          _unSeul(liste)
              ? t.adulte.recharge.profilUnique
              : t.adulte.recharge.profils,
        ),
        Ecart.vSm,
        KeyedSubtree(
          key: RechargeFoyerPage.profilsKey,
          child: CarteGroupee(
            sections: <Widget>[
              for (final BeneficiaireRecharge b in liste)
                _ligneProfil(context, b, enLigne: enLigne, large: large),
            ],
          ),
        ),
      ],
    );
  }

  /// « Acces a regulariser » pour chaque profil rendu a cet etat par les
  /// finances du foyer (guide §1.7), sans croix : l'etat dure tant qu'il
  /// n'est pas regle (Q-FI-6). Rien tant que les finances ne sont pas lues,
  /// en echec ou indisponibles (production).
  Widget? _bandeau(List<BeneficiaireRecharge> liste) {
    if (!widget.regularisation) return null;
    final List<FinancesProfil> profils =
        ref.watch(financesFoyerProvider).value?.profils ??
        const <FinancesProfil>[];
    final List<(BeneficiaireRecharge, FinancesProfil)> aRegler =
        <(BeneficiaireRecharge, FinancesProfil)>[
          for (final BeneficiaireRecharge b in liste)
            for (final FinancesProfil f in profils)
              if (f.profilId == b.id && aRegulariser(f)) (b, f),
        ];
    if (aRegler.isEmpty) return null;
    return Column(
      key: RechargeFoyerPage.bandeauKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final (int i, (BeneficiaireRecharge b, FinancesProfil f))
            in aRegler.indexed) ...<Widget>[
          if (i > 0) Ecart.vSm,
          BandeauAttention(
            titre: t.argent.acces.regulariserTitre,
            message: t.adulte.recharge.regularisationDe(
              prenom: b.prenom,
              message: messageRegularisation(f),
            ),
            // Un lien qui ne peut plus rien (profil deja coche, paiement
            // parti) disparait au lieu d'etre grise (K-56).
            action: _selection.contains(b.id) || _engage
                ? null
                : LienFleche(
                    key: RechargeFoyerPage.ajouterDe(b.id),
                    libelle: t.adulte.recharge.ajouter(prenom: b.prenom),
                    fleche: false,
                    onPress: () => _ajouter(b),
                  ),
          ),
        ],
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
    required bool large,
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
        montant: b.montantsRediges[m] ?? formaterMontant(m),
      ),
      null => null,
    };
    final TextStyle styleRole = AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle());
    final List<Widget> details = <Widget>[
      if (solde != null) Text(solde, style: styleRole),
      if (suggere != null) Text(suggere, style: styleRole),
    ];
    final Widget? blocDetails = details.isEmpty
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: details,
          );
    // La case et l'identite se lisent d'un bloc : « Mariam, Solde actuel :
    // 12 $, case cochee ». Le montant se lit a part, avec ses boutons.
    // L11 : sur telephone, le solde et le montant suggere passent SOUS la
    // ligne de la case et de la photo, sur toute la largeur. A cote d'elles,
    // a 320 px et texte x2, il ne leur restait que quelques lettres et les
    // mots se coupaient.
    final Widget identite = MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Checkbox(
                key: RechargeFoyerPage.caseDe(b.id),
                value: coche,
                onChanged: _engage
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
                  roleWidget: enLigne ? blocDetails : null,
                ),
              ),
            ],
          ),
          if (!enLigne && blocDetails != null) ...<Widget>[
            Ecart.vXs,
            blocDetails,
          ],
        ],
      ),
    );
    final Widget montant = _montantProfil(b, actif: coche && !_engage);
    return KeyedSubtree(
      key: RechargeFoyerPage.profilDe(b.id),
      child: enLigne
          ? Row(
              children: <Widget>[
                // Sur bureau, l'identite prend les deux tiers : un partage
                // egal laissait au solde et au montant suggere une colonne
                // de quelques mots (six lignes a 1440, FI-VAGUE-CORR).
                Expanded(flex: large ? 2 : 1, child: identite),
                Ecart.hMd,
                Flexible(child: montant),
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
        // Souple : un libelle redige long (« 5,00 € (démonstration) ») passe
        // a la ligne au lieu de pousser « plus » hors de l'ecran.
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: AppSpacing.respiration),
            child: Semantics(
              label: t.adulte.recharge.montantPour(prenom: b.prenom),
              liveRegion: actif,
              child: Center(
                widthFactor: 1,
                child: KeyedSubtree(
                  key: RechargeFoyerPage.montantDe(b.id),
                  child: switch (affiche) {
                    null => const SizedBox.shrink(),
                    final Montant m => _montantLu(
                      b,
                      m,
                      attenue: !actif || choisi == null,
                    ),
                  },
                ),
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

  /// Le montant [m] de [b] : le libelle que la source redige pour lui,
  /// tel quel (la demonstration EA le marque « (demonstration) », F12),
  /// sinon le montant formate.
  Widget _montantLu(
    BeneficiaireRecharge b,
    Montant m, {
    required bool attenue,
  }) => switch (b.montantsRediges[m]) {
    final String redige => Text(
      redige,
      textAlign: TextAlign.center,
      style:
          (attenue
                  ? AppPalette.of(context).inkMuted
                  : AppPalette.of(context).inkStrong)
              .applyTo(
                AppTypography.tabulaire(
                  Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
                ),
              ),
    ),
    null => MontantArgent(m, attenue: attenue),
  };

  /// Le recapitulatif et le total rendus, le moyen de paiement, puis
  /// « Payer {total} » (maquettes 04 et 07). [repartition] : l'explication,
  /// posee sous le total, dans la meme colonne, a toutes les largeurs.
  Widget _paiement(
    BuildContext context,
    List<BeneficiaireRecharge> liste,
    bool horsLigne, {
    required Widget? repartition,
  }) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final RecapitulatifRecharge? recapitulatif = _recapitulatif;
    final String? commande = _commande;
    final bool arrete =
        commande != null || _echecPaiement == _EchecRecharge.indisponible;
    // Les moyens que la politique active ouvre, sinon le seul paiement web
    // du lancement (guide §1.6) ; jamais un rail StoreKit ou Play.
    final Set<RailPaiement> ouverts =
        ref.watch(politiqueActiveProvider).value?.railsActifs ??
        const <RailPaiement>{RailPaiement.webStripe};
    final List<RailPaiement> rails = <RailPaiement>[
      for (final RailPaiement r in RailPaiement.values)
        if (ouverts.contains(r) && LigneMoyenPaiement.estMontre(r)) r,
    ];
    final bool aucun = !liste.any(
      (BeneficiaireRecharge b) => _selection.contains(b.id),
    );
    // Pourquoi « Payer » attend (K-59).
    final String? raison = aucun
        ? t.adulte.recharge.raisonAucun
        : _pret(liste)
        ? null
        : t.adulte.recharge.raisonMontant;
    final Widget? echecVerif = switch (_echecVerif) {
      // Une lecture manquee : rien n'a ete paye, les choix restent.
      _EchecRecharge.reseau => EtatSysteme(
        nature: NatureEtat.echecServeur,
        titre: t.adulte.recharge.verificationEchecTitre,
        phrase: t.adulte.recharge.verificationEchecPhrase,
        onAction: _actualiser,
      ),
      _EchecRecharge.indisponible => EtatSysteme(
        nature: NatureEtat.indisponible,
        titre: t.adulte.recharge.indisponibleTitre,
        phrase: t.adulte.recharge.indisponiblePhrase,
        dependance: _dependanceVerif,
      ),
      null => null,
    };
    final Widget? etatPaiement = switch ((_echecPaiement, commande)) {
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
        dependance: 'FI-BR-06',
        libelleAction: t.adulte.recharge.revenirPaiements,
        onAction: widget.onTerminee,
      ),
      // La commande est rendue : son suivi, jamais un second paiement.
      (null, String()) => _Note(texte: t.adulte.recharge.commandeRendue),
      (null, null) => null,
    };
    final Widget? etat = echecVerif ?? etatPaiement;
    final bool payable =
        recapitulatif != null &&
        !_verifEnCours &&
        !horsLigne &&
        rails.isNotEmpty &&
        _echecVerif == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _titreGroupe(context, t.adulte.recharge.recapitulatif),
        Ecart.vSm,
        // Le recapitulatif par profil et le total, tels que la source les
        // arrete (ligne 16 b, FI6), et la repartition dite a cote (§5.3).
        _Carte(
          key: RechargeFoyerPage.totalKey,
          lignes: <Widget>[
            if (recapitulatif != null) ...<Widget>[
              Column(
                key: RechargeFoyerPage.recapitulatifKey,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final (int i, LigneRecapitulatif l)
                      in recapitulatif.lignes.indexed) ...<Widget>[
                    if (i > 0) Ecart.vMd,
                    _ligneRecapitulatif(context, l),
                  ],
                ],
              ),
              Ecart.vMd,
            ],
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                Text(
                  t.adulte.recharge.total,
                  style: palette.inkStrong.applyTo(
                    textes.titleSmall ?? const TextStyle(),
                  ),
                ),
                if (recapitulatif != null)
                  Text(
                    recapitulatif.total,
                    style: palette.inkStrong.applyTo(
                      AppTypography.tabulaire(
                        textes.titleLarge ?? const TextStyle(),
                      ),
                    ),
                  ),
              ],
            ),
            if (recapitulatif == null && _verifEnCours) ...<Widget>[
              Ecart.vSm,
              const Skeleton.texte(lignes: 1),
            ],
            if (raison != null && !horsLigne) ...<Widget>[
              Ecart.vSm,
              _Note(
                key: RechargeFoyerPage.raisonKey,
                texte: raison,
                attenuee: true,
              ),
            ],
            if (repartition != null) ...<Widget>[Ecart.vMd, repartition],
          ],
        ),
        if (etat != null) ...<Widget>[
          Ecart.vLg,
          _FocusALApparition(key: RechargeFoyerPage.focusEtatKey, child: etat),
        ],
        Ecart.vXl,
        // Le moyen de paiement (guide §1.6, §5.3) : seul le paiement web.
        _titreGroupe(context, t.adulte.recharge.moyen),
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
        // Hors ligne : pourquoi « Payer » attend, sans jamais dire que rien
        // n'est paye (D5 : apres une coupure, l'ecran ne le sait pas).
        if (horsLigne && !arrete) ...<Widget>[
          Ecart.vLg,
          _Note(texte: t.adulte.recharge.horsLignePayer),
        ],
        // Un seul bouton dominant, 16 sous le moyen de paiement. Une fois la
        // commande rendue, le seul geste est son suivi (FI-8).
        if (commande != null || !arrete) ...<Widget>[
          Ecart.vLg,
          _Actions(
            principale: ActionPrincipale(
              key: commande != null
                  ? RechargeFoyerPage.suivreKey
                  : RechargeFoyerPage.payerKey,
              // Le total que la source vient de rendre : un choix change, le
              // bouton dit le nouveau total, jamais l'ancien.
              libelle: commande != null
                  ? t.adulte.recharge.suivrePaiement
                  : recapitulatif != null && !_verifEnCours
                  ? t.adulte.recharge.payer(montant: recapitulatif.total)
                  : t.adulte.recharge.payerSeul,
              fleche: commande != null,
              onPress: commande != null
                  ? () => widget.onPaye(commande)
                  : switch (recapitulatif) {
                      final RecapitulatifRecharge r when payable =>
                        () => unawaited(_payer(r)),
                      _ => null,
                    },
              enCours: commande == null && (_paiementEnCours || _verifEnCours),
              pleineLargeur: false,
            ),
          ),
        ],
        // FN-115 (directeur, 01/11/2026) : la famille lit les conditions de
        // remboursement et de contestation AVANT de payer, juste sous « Payer » ; sans cela, les
        // frais d'une contestation ne lui sont pas opposables.
        if (commande == null && !arrete) ...<Widget>[
          Ecart.vLg,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              key: RechargeFoyerPage.conditionsKey,
              libelle: t.adulte.recharge.conditionsRemboursement,
              onPress: () =>
                  GoRouter.of(context).push(TexteJuridique.annulation.chemin),
            ),
          ),
          // La phrase qui rend les frais de contestation opposables : lue
          // avant de payer, sans avoir a ouvrir le texte (pilote, 02/11).
          Ecart.vSm,
          _Note(
            key: RechargeFoyerPage.fraisContestationKey,
            texte: t.adulte.recharge.fraisContestation,
          ),
        ],
      ],
    );
  }

  /// La ligne d'un profil au recapitulatif : qui recoit (sa photo ou ses
  /// initiales, K-44, son accent, K-62, sans Classe, F6) et le montant paye
  /// pour lui, puis le solde attribue, la remise seulement si la source la
  /// rend avec SON libelle (F12, ligne 16 a), et le statut. Chaque valeur
  /// telle que rendue (F11, F12).
  Widget _ligneRecapitulatif(BuildContext context, LigneRecapitulatif l) =>
      Column(
        key: RechargeFoyerPage.ligneDe(l.beneficiaireId),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LigneCleValeur(
            meneur: BandeauProfil(
              avatar: PhotoEleve(
                prenom: l.prenom,
                cleAvatar: l.cleAvatar,
                diametre: AppAvatar.moyen,
              ),
              diametre: AppAvatar.moyen,
              accent: _accent(l.beneficiaireId),
              remontee: LigneCleValeur.margeVerticale,
            ),
            cle: l.prenom,
            valeur: l.montantPaye,
            chiffres: true,
            valeurEnFin: true,
          ),
          LigneCleValeur(
            cle: t.adulte.recharge.soldeAttribue,
            valeur: l.soldeAttribue,
            valeurEnFin: true,
          ),
          if (l.remise case final RemiseRendue r)
            LigneCleValeur(cle: r.libelle, valeur: r.valeur, valeurEnFin: true),
          LigneCleValeur(
            cle: t.adulte.recharge.statut,
            valeur: l.statut,
            valeurEnFin: true,
          ),
        ],
      );
}
