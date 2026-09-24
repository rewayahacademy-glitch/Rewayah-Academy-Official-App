import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/foyer/port_creation_profil_eleve.dart';
import '../../core/foyer/profil_eleve_brouillon.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/entete_page.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pressable.dart';

/// La porte d'acces du titulaire, qui decide de ce qui est creable (K3).
///
/// Une session illisible (source absente) vaut chargement : rien n'est
/// creable, aucune carte ne ment. Le serveur refait de toute facon le
/// controle (`creer_profil_enfant`, compte actif exige).
final Provider<PorteAcces> porteAjoutProfilProvider = Provider<PorteAcces>((
  Ref ref,
) {
  try {
    return ref.watch(sessionProvider).porte;
  } on Object {
    return PorteAcces.chargement;
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
/// Gabarit d'etape des planches d'admission V6 (#12 et #14 du manifeste) :
/// une rangee d'etape (disque retour, progression continue, « n sur N »), la
/// question, une consigne, le contenu, puis l'action en pilule ancree en bas.
/// Sur bureau, une colonne centree de largeur de dialogue (V6 section 8.13) :
/// jamais la page de telephone etiree.
///
/// **Honnetete** : les trois choix de K3 sont montres. Seul « Un enfant ou un
/// mineur » se cree aujourd'hui ; « Un proche adulte » (DB-FOY-02) et
/// « Moi-meme » (DB-FOY-01) sont visibles, desactives et expliques. Un compte
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

  /// La carte « Un enfant ou un mineur ».
  static const Key choixEnfantKey = Key('profilEleve.choix.enfant');

  /// La carte « Un proche adulte ».
  static const Key choixProcheKey = Key('profilEleve.choix.proche');

  /// La carte « Moi-meme ».
  static const Key choixMoiKey = Key('profilEleve.choix.moi');

  /// L'action du bas (« Suivant » puis « Creer le profil »).
  static const Key actionKey = Key('profilEleve.action');

  /// Le champ prenom.
  static const Key prenomKey = Key('profilEleve.prenom');

  /// Le champ nom.
  static const Key nomKey = Key('profilEleve.nom');

  /// Le champ age.
  static const Key ageKey = Key('profilEleve.age');

  /// La colonne du formulaire (bornee sur bureau).
  static const Key colonneKey = Key('profilEleve.colonne');

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

  static const BornesAge _bornes = BornesAge.clientActuelle;
  static const int _totalEtapes = 2;

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

  PorteAcces get _porte => ref.read(porteAjoutProfilProvider);

  bool _creable(PourQui choix) =>
      ref.read(portCreationProfilEleveProvider).peutCreer(choix, porte: _porte);

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
    ref.watch(porteAjoutProfilProvider);
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
      child: PageShell(
        entete: _Colonne(
          child: _RangeeEtape(
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
          child: identite ? _pageIdentite(context) : _pagePourQui(context),
        ),
      ),
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
        CarteChoixFoyer(
          key: FormulaireProfilEleve.choixEnfantKey,
          icone: AppIcons.profil,
          titre: t.foyer.ajout.pourQui.enfantTitre,
          description: enfantCreable
              ? t.foyer.ajout.pourQui.enfantDescription
              : t.foyer.ajout.pourQui.enfantAttente,
          retenue: _pourQui == PourQui.enfantOuMineur,
          disponible: enfantCreable,
          onPress: () => setState(() => _pourQui = PourQui.enfantOuMineur),
        ),
        Ecart.vMd,
        CarteChoixFoyer(
          key: FormulaireProfilEleve.choixProcheKey,
          icone: AppIcons.foyer,
          titre: t.foyer.ajout.pourQui.procheTitre,
          description: t.foyer.ajout.pourQui.procheDescription,
          retenue: false,
          disponible: _creable(PourQui.procheAdulte),
          onPress: () => setState(() => _pourQui = PourQui.procheAdulte),
        ),
        Ecart.vMd,
        CarteChoixFoyer(
          key: FormulaireProfilEleve.choixMoiKey,
          icone: AppIcons.avatarSansPhoto,
          titre: t.foyer.ajout.pourQui.moiTitre,
          description: t.foyer.ajout.pourQui.moiDescription,
          retenue: false,
          disponible: _creable(PourQui.moiMeme),
          onPress: () => setState(() => _pourQui = PourQui.moiMeme),
        ),
      ],
    );
  }

  Widget _pageIdentite(BuildContext context) {
    final Map<ChampProfilEleve, ErreurChamp> erreurs = _montrerErreurs
        ? _brouillon.valider(_bornes)
        : const <ChampProfilEleve, ErreurChamp>{};
    final bool refusAge = _refus == MotifRefusCreation.ageHorsBornes;

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
          ),
        ),
        Ecart.vMd,
        TextField(
          key: FormulaireProfilEleve.nomKey,
          controller: _nom,
          readOnly: _envoi,
          onChanged: changer,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const <String>[AutofillHints.familyName],
          decoration: InputDecoration(
            labelText: t.foyer.ajout.identite.nom,
            helperText: t.foyer.ajout.identite.nomAide,
            helperMaxLines: 3,
            errorText: erreurs[ChampProfilEleve.nom] == null
                ? null
                : t.foyer.ajout.erreurs.nomRequis,
            errorMaxLines: 3,
          ),
        ),
        Ecart.vMd,
        TextField(
          key: FormulaireProfilEleve.ageKey,
          controller: _age,
          readOnly: _envoi,
          onChanged: changer,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          textInputAction: TextInputAction.done,
          onSubmitted: (String _) {
            if (!_envoi && !_incertaine) {
              unawaited(_creer());
            }
          },
          decoration: InputDecoration(
            labelText: t.foyer.ajout.identite.age,
            suffixText: t.foyer.ajout.identite.ageSuffixe,
            helperText: t.foyer.ajout.identite.ageAide,
            helperMaxLines: 3,
            errorText: erreurAge,
            errorMaxLines: 3,
          ),
        ),
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

/// La rangee d'etape du gabarit V6 : disque retour, progression continue,
/// « n sur N ». Une seule ligne ; lue « Etape n sur N ».
class _RangeeEtape extends StatelessWidget {
  const _RangeeEtape({
    required this.numero,
    required this.total,
    required this.onRetour,
  });

  final int numero;
  final int total;
  final VoidCallback onRetour;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        DisqueRetour(onPress: onRetour),
        Ecart.hXxl,
        Expanded(
          child: Semantics(
            label: t.foyer.ajout.etapeSurLue(n: numero, total: total),
            excludeSemantics: true,
            child: ClipRRect(
              borderRadius: AppRadius.arrondiFull,
              child: SizedBox(
                height: AppSpacing.sm,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ColoredBox(color: palette.surfaceSunken.background),
                    FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: numero / total,
                      child: ColoredBox(
                        color: palette.surfacePrimary.background,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Ecart.hXxl,
        ExcludeSemantics(
          child: Text(
            t.foyer.ajout.etapeSur(n: numero, total: total),
            style: palette.inkStrong.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
      ],
    );
  }
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

/// Une carte de choix du gabarit E1 : pastille d'icone, titre, description,
/// radio en haut a droite. Une carte **indisponible** reste lisible, dit
/// « Indisponible » en texte et ne se presse pas.
///
/// Locale au lot B tant que `ChoiceCardGroup` (composant partage) ne porte ni
/// description ni option desactivee (demande B-3 au coordinateur). Servie
/// aussi par la page Interface de la fiche eleve (options a radio).
class CarteChoixFoyer extends StatelessWidget {
  /// Cree une carte.
  const CarteChoixFoyer({
    required this.icone,
    required this.titre,
    required this.description,
    required this.retenue,
    required this.disponible,
    required this.onPress,
    super.key,
  });

  /// L'icone de la pastille.
  final AppIcon icone;

  /// Le titre de l'option.
  final String titre;

  /// Une phrase qui dit ce que l'option change.
  final String description;

  /// Vrai quand l'option est celle retenue.
  final bool retenue;

  /// Faux pour une option visible mais indisponible.
  final bool disponible;

  /// Le geste de choix.
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // La pastille retenue se detache de la carte retenue (deja en teinte
    // d'accent) : pastille pleine d'accent, comme la planche E1.
    final AppColorPair pastille = retenue
        ? palette.surfacePrimary
        : palette.surfaceSunken;

    Widget carte(BuildContext contexte, EtatPression etat) {
      final bool survol = disponible && (etat.survole || etat.presse);
      return DecoratedBox(
        decoration: AppElevation.avecFilet(
          surface: retenue ? palette.washAccent : palette.surfaceRaised,
          filet: retenue
              ? palette.inkAccent
              : survol
              ? palette.borderStrong
              : palette.contourCarte,
          ombre: palette.ombre,
          arrondi: AppRadius.arrondiSm,
          ombres: AppElevation.niveau0,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox.square(
                dimension: AppTouchTarget.standard,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: pastille.background,
                    shape: BoxShape.circle,
                  ),
                  child: IconTheme(
                    data: retenue
                        ? IconThemeData(
                            color: pastille.onBackground,
                            size: AppSpacing.xxl,
                          )
                        : disponible
                        ? palette.inkAccent.asIconTheme(size: AppSpacing.xxl)
                        : palette.inkMuted.asIconTheme(size: AppSpacing.xxl),
                    child: Icon(icone.resoudre(selectionne: retenue)),
                  ),
                ),
              ),
              Ecart.hLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      titre,
                      style: (disponible ? palette.inkStrong : palette.inkMuted)
                          .applyTo(textes.titleMedium ?? const TextStyle()),
                    ),
                    Ecart.vXs,
                    Text(
                      description,
                      style: palette.inkMuted.applyTo(
                        textes.bodyMedium ?? const TextStyle(),
                      ),
                    ),
                    if (!disponible) ...<Widget>[
                      Ecart.vSm,
                      Text(
                        t.foyer.ajout.pourQui.indisponible,
                        style: palette.inkMuted.applyTo(
                          textes.labelMedium ?? const TextStyle(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Ecart.hMd,
              _Radio(retenue: retenue, disponible: disponible),
            ],
          ),
        ),
      );
    }

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: retenue,
      enabled: disponible,
      child: Pressable.selon(
        onPress: disponible ? onPress : null,
        actif: disponible,
        libelleSemantique: disponible
            ? '$titre. $description'
            : '$titre. $description ${t.foyer.ajout.pourQui.indisponible}.',
        respecterCibleTactile: false,
        arrondiFocus: AppRadius.arrondiSm,
        constructeur: carte,
      ),
    );
  }
}

/// Le radio dessine de la carte : anneau, point plein quand elle est retenue.
/// Son contour garde 3:1 sur la carte (`borderStrong`).
class _Radio extends StatelessWidget {
  const _Radio({required this.retenue, required this.disponible});

  final bool retenue;
  final bool disponible;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: AppSpacing.xxl,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              (retenue
                      ? palette.inkAccent
                      : disponible
                      ? palette.borderStrong
                      : palette.borderResting)
                  .asBorderSide(width: 2),
            ),
          ),
          child: retenue
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.surfacePrimary.background,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
