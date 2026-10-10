import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/signaler_manque.dart';
import '../../core/appairage/service_appairage.dart';
import '../../core/capacites/port_identite_titulaire.dart';
import '../../core/foyer/port_creation_profil_eleve.dart';
import '../../core/foyer/profil_eleve_brouillon.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/page_etape.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/zone_saisie.dart' show ZoneSaisie;
import '../compte/donnees_compte.dart' show identiteTitulaireProvider;

/// La porte d'acces du titulaire, qui decide de ce qui est creable (K3).
///
/// `null` : la session est illisible (source absente, lecture en echec). Le
/// formulaire le dit comme une erreur, jamais comme un dossier en attente ;
/// `chargement` se dit comme un chargement, `horsLigne` comme hors ligne. Le
/// serveur refait de toute facon le controle (`creer_profil_enfant`, compte
/// actif exige).
final Provider<PorteAcces?> porteAjoutProfilProvider = Provider<PorteAcces?>((
  Ref ref,
) {
  try {
    return ref.watch(sessionProvider).porte;
  } on Object {
    return null;
  }
});

/// Les deux pages du formulaire : pour qui, puis qui.
enum EtapeProfilEleve {
  /// « Pour qui est ce profil eleve ? » (gabarit E1 des planches V6).
  pourQui,

  /// Prenom, nom, age (gabarit E3 des planches V6).
  identite,
}

/// Le formulaire commun d'ajout d'un profil eleve (contrat K3), ouvert par
/// `/tuteur/foyer/ajouter` depuis le Foyer, l'Accueil, le Compte et la fin de
/// l'admission : **un seul flux**, jamais une copie.
///
/// Gabarit d'etape des planches d'admission V6 (#12 et #14 du manifeste),
/// plein ecran sans actions de coquille : la `RangeeEtape` partagee (disque
/// retour, progression continue, « n sur N »), la
/// question, une consigne, le contenu, puis l'action en pilule ancree en bas.
/// Sur bureau, une colonne centree de largeur de dialogue (V6 section 8.13) :
/// jamais la page de telephone etiree.
///
/// **Honnetete** : deux choix sont montres. Seul « Un enfant ou un mineur » se
/// cree aujourd'hui ; « Moi-meme » (DB-FOY-01) est visible, desactive et
/// explique. « Un proche adulte » (DB-FOY-02) n'est plus propose (F2, EA-5). Un compte
/// qui n'est pas a la porte `actif` (DB-ADM-04) voit aussi le premier choix
/// desactive, avec sa raison. Aucune presélection : le bouton attend un choix.
///
/// **Reponse perdue** (`CreationIncertaine`, DB-FOY-06) : le foyer est relu ;
/// si un nouveau profil au meme prenom y apparait, il a ete cree et la fiche
/// s'ouvre ; sinon l'ecran le dit et laisse choisir entre voir le foyer et
/// reessayer, jamais un nouvel envoi aveugle.
class FormulaireProfilEleve extends ConsumerStatefulWidget {
  /// Cree le formulaire.
  const FormulaireProfilEleve({
    required this.onAbandon,
    required this.onCree,
    required this.onVoirFoyer,
    super.key,
  });

  /// Retour depuis la premiere page : quitter le formulaire.
  final VoidCallback onAbandon;

  /// Le profil est cree. [eleveId] est connu quand la relecture du foyer l'a
  /// retrouve sans ambiguite ; `null` sinon.
  final void Function(String? eleveId) onCree;

  /// « Voir le foyer » apres une reponse perdue.
  final VoidCallback onVoirFoyer;

  /// Le groupe des trois choix « pour qui » (`ChoiceCardGroup`).
  static const Key choixKey = Key('profilEleve.choix');

  /// L'action du bas (« Suivant » puis « Creer le profil »).
  static const Key actionKey = Key('profilEleve.action');

  /// Le champ prenom.
  static const Key prenomKey = Key('profilEleve.prenom');

  /// Le champ nom.
  static const Key nomKey = Key('profilEleve.nom');

  /// Le choix de l'age (puces bornees).
  static const Key ageKey = Key('profilEleve.age');

  /// La puce d'un age.
  static Key ageChoixKey(int age) => Key('profilEleve.age.$age');

  /// La colonne du formulaire (bornee sur bureau).
  static const Key colonneKey = Key('profilEleve.colonne');

  /// La session n'est pas encore lue.
  static const Key porteChargementKey = Key('profilEleve.porte.chargement');

  /// La session ne peut pas etre lue.
  static const Key porteIllisibleKey = Key('profilEleve.porte.illisible');

  /// Le compte est hors ligne.
  static const Key porteHorsLigneKey = Key('profilEleve.porte.horsLigne');

  @override
  ConsumerState<FormulaireProfilEleve> createState() =>
      _FormulaireProfilEleveState();
}

class _FormulaireProfilEleveState extends ConsumerState<FormulaireProfilEleve> {
  final TextEditingController _prenom = TextEditingController();
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _age = TextEditingController();

  EtapeProfilEleve _etape = EtapeProfilEleve.pourQui;
  PourQui? _pourQui;
  bool _montrerErreurs = false;
  bool _envoi = false;
  MotifRefusCreation? _refus;
  bool _incertaine = false;

  /// Le nom a ete touche par la personne : le prerempli ne le reecrit plus.
  bool _nomModifie = false;

  /// Le nom affiche vient du compte du titulaire (modifiable).
  bool _nomPrerempli = false;

  static const BornesAge _bornes = BornesAge.clientActuelle;
  static const int _totalEtapes = 2;

  @override
  void initState() {
    super.initState();
    // Le nom de famille du titulaire est propose, jamais impose ; si le compte
    // ne se lit pas, le champ reste vide (le serveur garde le controle).
    ref.listenManual<AsyncValue<IdentiteTitulaire>>(identiteTitulaireProvider, (
      AsyncValue<IdentiteTitulaire>? _,
      AsyncValue<IdentiteTitulaire> suivant,
    ) {
      final String nom = suivant.value?.nom.trim() ?? '';
      if (nom.isEmpty || _nomModifie || _nom.text.isNotEmpty) {
        return;
      }
      setState(() {
        _nom.text = nom;
        _nomPrerempli = true;
      });
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _age.dispose();
    super.dispose();
  }

  BrouillonProfilEleve get _brouillon {
    final BrouillonProfilEleve base = BrouillonProfilEleve(
      pourQui: _pourQui ?? PourQui.enfantOuMineur,
      prenom: _prenom.text,
      nom: _nom.text,
    );
    final int? age = int.tryParse(_age.text.trim());
    return age == null ? base : base.copyWith(age: age);
  }

  PorteAcces? get _porte => ref.read(porteAjoutProfilProvider);

  bool _creable(PourQui choix) {
    final PorteAcces? porte = _porte;
    return porte != null &&
        ref
            .read(portCreationProfilEleveProvider)
            .peutCreer(choix, porte: porte);
  }

  void _retour() {
    if (_envoi) {
      return;
    }
    if (_etape == EtapeProfilEleve.identite) {
      // Retour sans perte : les champs gardent leur saisie.
      setState(() {
        _etape = EtapeProfilEleve.pourQui;
        _refus = null;
        _incertaine = false;
      });
      return;
    }
    widget.onAbandon();
  }

  void _suivant() {
    final PourQui? choix = _pourQui;
    if (choix == null || !_creable(choix)) {
      return;
    }
    setState(() => _etape = EtapeProfilEleve.identite);
  }

  /// Les identifiants du foyer connus avant l'envoi, ou `null` si la lecture
  /// echoue (on ne saura alors pas designer le profil cree).
  Future<Set<String>?> _idsDuFoyer() async {
    try {
      final List<EleveDuFoyer> eleves = await ref.read(
        elevesDuFoyerProvider.future,
      );
      return <String>{for (final EleveDuFoyer e in eleves) e.id};
    } on Object {
      return null;
    }
  }

  /// Le profil apparu depuis [avant], au prenom saisi, s'il est unique.
  Future<String?> _nouveauProfil(Set<String>? avant, String prenom) async {
    if (avant == null) {
      return null;
    }
    try {
      final List<EleveDuFoyer> apres = await ref.read(
        elevesDuFoyerProvider.future,
      );
      final List<EleveDuFoyer> nouveaux = <EleveDuFoyer>[
        for (final EleveDuFoyer e in apres)
          if (!avant.contains(e.id) && e.prenom.trim() == prenom) e,
      ];
      return nouveaux.length == 1 ? nouveaux.single.id : null;
    } on Object {
      return null;
    }
  }

  Future<void> _creer() async {
    if (_envoi) {
      return;
    }
    final BrouillonProfilEleve brouillon = _brouillon;
    setState(() {
      _montrerErreurs = true;
      _refus = null;
      _incertaine = false;
    });
    if (brouillon.valider(_bornes).isNotEmpty) {
      return;
    }
    setState(() => _envoi = true);
    final String prenom = brouillon.prenom.trim();
    final Set<String>? avant = await _idsDuFoyer();
    final ResultatCreationProfil resultat = await ref
        .read(portCreationProfilEleveProvider)
        .creer(brouillon);
    if (!mounted) {
      return;
    }
    switch (resultat) {
      case ProfilCree(:final String? eleveId):
        final String? id = eleveId ?? await _nouveauProfil(avant, prenom);
        if (!mounted) {
          return;
        }
        setState(() => _envoi = false);
        widget.onCree(id);
      case CreationRefusee(:final MotifRefusCreation motif):
        setState(() {
          _envoi = false;
          _refus = motif;
        });
      case CreationIncertaine():
        // Le port a deja fait relire le foyer : un nouveau profil au meme
        // prenom prouve la creation.
        final String? id = await _nouveauProfil(avant, prenom);
        if (!mounted) {
          return;
        }
        if (id != null) {
          setState(() => _envoi = false);
          widget.onCree(id);
          return;
        }
        setState(() {
          _envoi = false;
          _incertaine = true;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Garde la liste du foyer vivante : c'est elle qui, relue apres l'envoi,
    // designe le profil cree.
    ref.watch(elevesDuFoyerProvider);
    // La porte decide de ce qui est creable : un changement de session
    // redessine les cartes.
    final PorteAcces? porte = ref.watch(porteAjoutProfilProvider);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final bool identite = _etape == EtapeProfilEleve.identite;
    final int numero = identite ? 2 : 1;

    final VoidCallback? action = switch (_etape) {
      EtapeProfilEleve.pourQui =>
        _pourQui != null && _creable(_pourQui!) ? _suivant : null,
      EtapeProfilEleve.identite =>
        _envoi || horsLigne || _incertaine ? null : () => unawaited(_creer()),
    };

    return PopScope(
      canPop: !identite && !_envoi,
      onPopInvokedWithResult: (bool fait, Object? _) {
        if (!fait) {
          _retour();
        }
      },
      // Le gabarit de `PageEtape` (sans actions de coquille, rangee d'etape
      // partagee), mais borne a la colonne de dialogue sur bureau.
      child: PageShell(
        actionsCoquille: false,
        entete: _Colonne(
          child: RangeeEtape(
            numero: numero,
            total: _totalEtapes,
            onRetour: _retour,
          ),
        ),
        actions: _Colonne(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (identite && horsLigne) ...<Widget>[
                _Precision(texte: t.foyer.ajout.horsLigne),
                Ecart.vMd,
              ] else if (identite && _refus != null) ...<Widget>[
                _Precision(texte: _texteRefus(_refus!), alerte: true),
                Ecart.vMd,
              ],
              ActionPrincipale(
                key: FormulaireProfilEleve.actionKey,
                libelle: identite ? t.foyer.ajout.creer : t.foyer.ajout.suivant,
                onPress: action,
                enCours: _envoi,
                pilule: true,
                fleche: !identite,
              ),
            ],
          ),
        ),
        child: _Colonne(
          cle: FormulaireProfilEleve.colonneKey,
          child: identite
              ? _pageIdentite(context)
              : _pagePourQuiSelon(context, porte),
        ),
      ),
    );
  }

  /// La premiere page selon la porte : tant que la session n'est pas lue,
  /// ou qu'elle ne peut pas l'etre, aucune carte n'est montree desactivee
  /// avec la raison d'un dossier en attente, qui serait fausse.
  Widget _pagePourQuiSelon(BuildContext context, PorteAcces? porte) {
    void relire() => ref.invalidate(porteAjoutProfilProvider);
    final Widget? etat = switch (porte) {
      null => EtatSysteme(
        key: FormulaireProfilEleve.porteIllisibleKey,
        nature: NatureEtat.echecServeur,
        titre: t.foyer.ajout.porte.illisibleTitre,
        phrase: t.foyer.ajout.porte.illisiblePhrase,
        onAction: relire,
      ),
      PorteAcces.chargement => const Skeleton.liste(
        key: FormulaireProfilEleve.porteChargementKey,
      ),
      // Le bandeau de `PageShell` dit le reseau, le bloc dit ce qui manque
      // (EA-HL-DOUBLE-1).
      PorteAcces.horsLigne => EtatSansDonnees(
        key: FormulaireProfilEleve.porteHorsLigneKey,
        quoi: t.foyer.ajout.porte.sansDonneesTitre,
        onAction: relire,
      ),
      _ => null,
    };
    if (etat == null) {
      return _pagePourQui(context);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Question(
          question: t.foyer.ajout.pourQui.question,
          sousTitre: t.foyer.ajout.pourQui.sousTitre,
        ),
        Ecart.vXxl,
        etat,
      ],
    );
  }

  String _texteRefus(MotifRefusCreation motif) => switch (motif) {
    MotifRefusCreation.compteNonValide => t.foyer.ajout.refus.compteNonValide,
    MotifRefusCreation.ageHorsBornes => t.foyer.ajout.refus.ageHorsBornes,
    MotifRefusCreation.refuse => t.foyer.ajout.refus.refuse,
  };

  Widget _pagePourQui(BuildContext context) {
    final bool enfantCreable = _creable(PourQui.enfantOuMineur);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Question(
          question: t.foyer.ajout.pourQui.question,
          sousTitre: t.foyer.ajout.pourQui.sousTitre,
        ),
        Ecart.vXxl,
        ChoiceCardGroup(
          key: FormulaireProfilEleve.choixKey,
          autoriserSaisieLibre: false,
          valeurInitiale: _pourQui == null
              ? null
              : ReponseChoix(valeurs: <String>{_pourQui!.name}),
          options: <OptionChoix>[
            OptionChoix(
              valeur: PourQui.enfantOuMineur.name,
              libelle: t.foyer.ajout.pourQui.enfantTitre,
              icone: AppIcons.profil,
              description: t.foyer.ajout.pourQui.enfantDescription,
              disponible: enfantCreable,
              raisonIndisponible: t.foyer.ajout.pourQui.enfantAttente,
            ),
            // Pas de choix « Un proche adulte » (F2, EA-5) : un adulte n'est
            // jamais un profil gere ; il a son propre compte, et la place
            // adulte du foyer se dit sur la ligne de Ma famille.
            OptionChoix(
              valeur: PourQui.moiMeme.name,
              libelle: t.foyer.ajout.pourQui.moiTitre,
              icone: AppIcons.avatarSansPhoto,
              description: t.foyer.ajout.pourQui.moiDescription,
              disponible: _creable(PourQui.moiMeme),
              raisonIndisponible: t.foyer.ajout.pourQui.indisponible,
            ),
          ],
          onChange: (ReponseChoix reponse) => setState(() {
            _pourQui = _pourQuiDe(reponse);
          }),
        ),
      ],
    );
  }

  static PourQui? _pourQuiDe(ReponseChoix reponse) {
    for (final PourQui p in PourQui.values) {
      if (reponse.valeurs.contains(p.name)) {
        return p;
      }
    }
    return null;
  }

  Widget _pageIdentite(BuildContext context) {
    final Map<ChampProfilEleve, ErreurChamp> erreurs = _montrerErreurs
        ? _brouillon.valider(_bornes)
        : const <ChampProfilEleve, ErreurChamp>{};
    final bool refusAge = _refus == MotifRefusCreation.ageHorsBornes;

    // L'age se choisit dans les bornes : seul le serveur peut encore le
    // refuser (le refus reste la garde).
    String? erreurAge;
    if (erreurs[ChampProfilEleve.age] == ErreurChamp.requis) {
      erreurAge = t.foyer.ajout.erreurs.ageRequis;
    } else if (erreurs[ChampProfilEleve.age] == ErreurChamp.horsBornes ||
        refusAge) {
      erreurAge = t.foyer.ajout.erreurs.ageHorsBornes(
        min: _bornes.min,
        max: _bornes.max,
      );
    }

    void changer(String _) => setState(() {
      if (_refus != MotifRefusCreation.compteNonValide) {
        _refus = null;
      }
    });

    void choisirAge(int age) => setState(() {
      _age.text = '$age';
      if (_refus != MotifRefusCreation.compteNonValide) {
        _refus = null;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Question(
          question: t.foyer.ajout.identite.question,
          sousTitre: t.foyer.ajout.identite.sousTitre,
        ),
        Ecart.vXxl,
        if (_incertaine) ...<Widget>[
          EtatSysteme(
            nature: NatureEtat.echecServeur,
            titre: t.foyer.ajout.incertaine.titre,
            phrase: t.foyer.ajout.incertaine.phrase,
            libelleAction: t.foyer.ajout.incertaine.voirFoyer,
            onAction: widget.onVoirFoyer,
            libelleSecondaire: t.foyer.ajout.incertaine.reessayer,
            onSecondaire: () => unawaited(_creer()),
            dependance: 'DB-FOY-06',
          ),
          Ecart.vXxl,
        ],
        TextField(
          key: FormulaireProfilEleve.prenomKey,
          controller: _prenom,
          readOnly: _envoi,
          onChanged: changer,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const <String>[AutofillHints.givenName],
          decoration: InputDecoration(
            labelText: t.foyer.ajout.identite.prenom,
            errorText: erreurs[ChampProfilEleve.prenom] == null
                ? null
                : t.foyer.ajout.erreurs.prenomRequis,
            errorMaxLines: ZoneSaisie.lignesAideMax,
          ),
        ),
        Ecart.vMd,
        TextField(
          key: FormulaireProfilEleve.nomKey,
          controller: _nom,
          readOnly: _envoi,
          onChanged: (String valeur) {
            _nomModifie = true;
            changer(valeur);
          },
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          autofillHints: const <String>[AutofillHints.familyName],
          decoration: InputDecoration(
            labelText: t.foyer.ajout.identite.nom,
            helperText: _nomPrerempli
                ? t.foyer.ajout.identite.nomAidePrerempli
                : t.foyer.ajout.identite.nomAide,
            helperMaxLines: ZoneSaisie.lignesAideMax,
            errorText: erreurs[ChampProfilEleve.nom] == null
                ? null
                : t.foyer.ajout.erreurs.nomRequis,
            errorMaxLines: ZoneSaisie.lignesAideMax,
          ),
        ),
        Ecart.vMd,
        _ChoixAge(
          key: FormulaireProfilEleve.ageKey,
          bornes: _bornes,
          choisi: int.tryParse(_age.text.trim()),
          erreur: erreurAge,
          figee: _envoi,
          onChoisir: choisirAge,
        ),
      ],
    );
  }
}

/// L'age se choisit parmi des puces bornees (jamais tape) : une puce par age
/// des bornes, la puce retenue sur la paire douce d'accent (`FilterPill`).
class _ChoixAge extends StatelessWidget {
  const _ChoixAge({
    required this.bornes,
    required this.choisi,
    required this.erreur,
    required this.onChoisir,
    super.key,
    this.figee = false,
  });

  final BornesAge bornes;
  final int? choisi;
  final String? erreur;
  final ValueChanged<int> onChoisir;

  /// Vrai pendant l'envoi : le choix est fige le temps de la reponse.
  final bool figee;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t.foyer.ajout.identite.age,
          style: palette.inkStrong.applyTo(
            textes.titleMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vXs,
        Text(
          t.foyer.ajout.identite.ageAide,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        // Choix de formulaire, pas un filtre : l'age du profil.
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (int age = bornes.min; age <= bornes.max; age++)
              FilterPill(
                key: FormulaireProfilEleve.ageChoixKey(age),
                libelle: '$age',
                retenue: age == choisi,
                // Jamais grisee (BOUTONS-GRISES-1) : pendant l'envoi, le
                // choix est fige le temps de la reponse, et l'appui le dit
                // au lecteur d'ecran au lieu de rester muet.
                onPress: figee
                    ? () => signalerManque(
                        context,
                        t.foyer.ajout.identite.ageFige,
                      )
                    : () => onChoisir(age),
              ),
          ],
        ),
        if (erreur case final String message) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Borne la colonne du formulaire a la largeur de dialogue, centree : sur
/// telephone elle prend toute la largeur, sur bureau elle ne s'etire pas.
class _Colonne extends StatelessWidget {
  const _Colonne({required this.child, this.cle});

  final Widget child;

  /// La cle de la colonne bornee elle-meme (mesuree par les tests).
  final Key? cle;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      key: cle,
      constraints: const BoxConstraints(maxWidth: AppPage.largeurDialogue),
      child: child,
    ),
  );
}

/// La question de la page et sa consigne.
class _Question extends StatelessWidget {
  const _Question({required this.question, required this.sousTitre});

  final String question;
  final String sousTitre;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            question,
            style: palette.inkStrong.applyTo(
              textes.headlineMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        Text(
          sousTitre,
          style: palette.inkMuted.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
      ],
    );
  }
}

/// Une precision au-dessus de l'action : hors ligne, ou refus du serveur.
class _Precision extends StatelessWidget {
  const _Precision({required this.texte, this.alerte = false});

  final String texte;
  final bool alerte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: Text(
        texte,
        textAlign: TextAlign.center,
        style: (alerte ? palette.inkAlert : palette.inkMuted).applyTo(
          Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        ),
      ),
    );
  }
}
