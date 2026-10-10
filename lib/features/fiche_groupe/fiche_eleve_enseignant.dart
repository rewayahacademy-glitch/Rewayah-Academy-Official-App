// ENS-11 Fiche eleve hors seance et ENS-12 Signaler un besoin (EN-4, vague
// Enseignant). Doc 04 §14 et §22 ; 00_MAQUETTES_ENSEIGNANT, ENS-11 ;
// UX_REVIEW_04 lignes 12 et 13.
//
// - Une seule colonne, sans onglets (E13). Hors seance, la seule action est
//   « Signaler un besoin » (E14) : ni Faire reciter, ni Appeler, ni Noter.
// - Aucune donnee privee des familles (E5) : la fiche ne lit que la
//   projection pedagogique (`MembreSeance`, `ProjectionEleve`, R15). La photo
//   de l'eleve est visible de son enseignant (K-44), initiales en repli.
// - Sous 840, une feuille (`AppBottomSheet`) ; a partir de 840, un panneau qui
//   prend la place de la colonne des eleves de l'Espace Classe, jamais un
//   troisieme panneau (contrat D). Echap ferme l'une et l'autre.
// - Aucun branchement serveur (K-28) : le signalement ne part nulle part tant
//   qu'aucun envoi n'est fourni, et l'ecran le dit honnetement.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/enseignant/modeles_enseignant.dart';
import '../../core/formulaires/motifs_proposes.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/selecteur_motif.dart';
import '../../core/widgets/zone_saisie.dart';
import '../foyer/photo_eleve.dart';
import 'preparation_seance.dart';

/// Ce que la fiche montre d'un eleve : sa projection pedagogique, et la Classe
/// d'ou elle est ouverte (preremplie dans le signalement, W-337).
@immutable
class EleveFiche {
  /// Cree la vue.
  const EleveFiche({
    required this.membre,
    required this.classe,
    this.projection,
    this.seanceId,
  });

  /// La seance d'ou part le signalement, si applicable (doc 04 §22.2) :
  /// nulle hors seance.
  final String? seanceId;

  /// L'eleve, tel que la Classe le connait.
  final MembreSeance membre;

  /// Sa projection pedagogique, ou nul.
  final ProjectionEleve? projection;

  /// Le nom de la Classe.
  final String classe;

  /// Le prenom affiche (ou l'identifiant, quand la base l'a masque).
  String get prenom => membre.libelle;
}

/// Ouvre la fiche d'un eleve en feuille (`AppBottomSheet`). « Signaler un
/// besoin » ouvre ensuite sa propre feuille, au-dessus.
Future<void> ouvrirFicheEleve(BuildContext context, EleveFiche eleve) {
  return AppBottomSheet.ouvrir<void>(
    context,
    // Le nom humain comme titre, pas « Fiche de » (K-42 §5).
    titre: eleve.prenom,
    constructeur: (BuildContext contexte) => FicheEleveEnseignant(
      eleve: eleve,
      onSignaler: () => ouvrirSignalement(contexte, eleve),
    ),
  );
}

/// Ouvre « Signaler un besoin » pour un eleve (ENS-12).
Future<void> ouvrirSignalement(BuildContext context, EleveFiche eleve) {
  return AppBottomSheet.ouvrir<void>(
    context,
    titre: t.enseignant.signalement.titre,
    constructeur: (BuildContext _) => SignalerBesoin(eleve: eleve),
  );
}

/// La fiche d'un eleve hors seance (ENS-11), une seule colonne.
class FicheEleveEnseignant extends StatelessWidget {
  /// Cree la fiche.
  const FicheEleveEnseignant({
    required this.eleve,
    required this.onSignaler,
    super.key,
  });

  /// L'eleve.
  final EleveFiche eleve;

  /// Ce que fait « Signaler un besoin ».
  final VoidCallback onSignaler;

  /// La cle de l'action « Signaler un besoin ».
  static const Key signalerKey = ValueKey<String>('fiche-eleve-signaler');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final MembreSeance membre = eleve.membre;
    final ProjectionEleve? p = eleve.projection;
    String texte(String? v) {
      final String? propre = v?.trim();
      return propre == null || propre.isEmpty
          ? t.enseignant.eleve.nonRenseigne
          : propre;
    }

    final String? page = p?.pageReprise?.trim();
    final String travail = page == null || page.isEmpty
        ? t.enseignant.eleve.nonRenseigne
        : t.enseignant.eleve.travailReprise(page: page.toLowerCase());
    final String? dernierPoint = p?.dernierPoint?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // AVATAR-1 : couple avatar + texte du composant partage. Le prenom est
        // deja le titre (K-42 §5) : seul l'identifiant Academie accompagne la
        // photo, centre verticalement sur le cercle.
        AvatarNom.enLigne(
          prenom: eleve.prenom,
          nom: t.enseignant.eleve.identifiant(id: membre.identifiantImmuable),
          diametre: AppAvatar.grand,
          ecart: AppSpacing.lg,
          styleNom: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
          avatar: Semantics(
            image: true,
            label: t.enseignant.eleve.photo(dePrenom: deDevant(eleve.prenom)),
            child: ExcludeSemantics(
              child: PhotoEleve(
                prenom: eleve.prenom,
                cleAvatar: p?.cleAvatar,
                diametre: AppAvatar.grand,
              ),
            ),
          ),
        ),
        Ecart.vXl,
        GroupeReglages(
          lignes: <LigneRubrique>[
            LigneRubrique(
              icone: AppIcons.suivi,
              libelle: t.enseignant.eleve.niveau,
              legende: texte(membre.niveau),
            ),
            LigneRubrique(
              icone: AppIcons.marqueur,
              libelle: t.enseignant.eleve.objectif,
              legende: texte(p?.objectif),
            ),
            LigneRubrique(
              icone: AppIcons.journee,
              libelle: t.enseignant.eleve.presence,
              legende: texte(p?.presenceRecente),
            ),
            LigneRubrique(
              icone: AppIcons.livreOuvert,
              libelle: t.enseignant.eleve.travail,
              legende: travail,
            ),
            // La projection n'a pas de date de derniere seance (EN-RC) : le
            // dernier point travaille garde son propre intitule.
            if (dernierPoint != null && dernierPoint.isNotEmpty)
              LigneRubrique(
                icone: AppIcons.historique,
                libelle: t.enseignant.ficheGroupe.dernierPoint(
                  texte: dernierPoint,
                ),
              ),
          ],
        ),
        Ecart.vXl,
        Text(
          t.enseignant.eleve.signalerAide,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        // Hors seance, la seule action (E14) ; secondaire : rien n'est urgent.
        ActionPrincipale(
          key: signalerKey,
          libelle: t.enseignant.eleve.signaler,
          niveau: NiveauAction.secondaire,
          onPress: onSignaler,
        ),
      ],
    );
  }
}

/// Le panneau de la fiche sur bureau : il prend la place de la colonne des
/// eleves (contrat D), avec un retour « Eleves » au bord de debut. Echap le
/// ferme ; l'Espace Classe rend alors le focus a la ligne de l'eleve.
class PanneauFicheEleve extends StatelessWidget {
  /// Cree le panneau.
  const PanneauFicheEleve({
    required this.eleve,
    required this.onFermer,
    super.key,
  });

  /// L'eleve.
  final EleveFiche eleve;

  /// Rend la colonne des eleves.
  final VoidCallback onFermer;

  /// La cle du retour « Eleves ».
  static const Key retourKey = ValueKey<String>('fiche-eleve-retour');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): onFermer,
      },
      child: FocusScope(
        autofocus: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: IntrinsicWidth(
                child: ActionPrincipale(
                  key: retourKey,
                  libelle: t.enseignant.eleve.retour,
                  niveau: NiveauAction.tertiaire,
                  pleineLargeur: false,
                  autofocus: true,
                  onPress: onFermer,
                ),
              ),
            ),
            Ecart.vSm,
            Semantics(
              header: true,
              child: Text(
                eleve.prenom,
                style: palette.inkStrong.applyTo(
                  textes.headlineSmall ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vLg,
            FicheEleveEnseignant(
              eleve: eleve,
              onSignaler: () => ouvrirSignalement(context, eleve),
            ),
          ],
        ),
      ),
    );
  }
}

/// Les categories reellement supportees (doc 04 §22.1).
enum CategorieBesoin {
  /// Probleme pedagogique.
  pedagogique,

  /// Presence.
  presence,

  /// Technique.
  technique,

  /// Changement.
  changement,

  /// Autre : un detail est alors demande.
  autre;

  /// L'icone de la ligne.
  AppIcon get icone => switch (this) {
    pedagogique => AppIcons.lecon,
    presence => AppIcons.journee,
    technique => AppIcons.reseau,
    changement => AppIcons.reaffectation,
    autre => AppIcons.autreChoix,
  };

  /// Le libelle lisible.
  String get libelle => switch (this) {
    pedagogique => t.enseignant.signalement.categories.pedagogique,
    presence => t.enseignant.signalement.categories.presence,
    technique => t.enseignant.signalement.categories.technique,
    changement => t.enseignant.signalement.categories.changement,
    autre => t.enseignant.signalement.categories.autre,
  };
}

/// Un signalement pret a partir.
@immutable
class SignalementBesoin {
  /// Cree le signalement.
  const SignalementBesoin({
    required this.studentId,
    required this.categorie,
    required this.detailsInternes,
    required this.resumePartageable,
    required this.classe,
    required this.horodatage,
    this.seanceId,
  });

  /// L'eleve, prerempli.
  final String studentId;

  /// La Classe, preremplie (doc 04 §22.2, §33 n. 7).
  final String classe;

  /// La seance, si applicable (doc 04 §22.2).
  final String? seanceId;

  /// L'horodatage de l'envoi (doc 04 §22.2).
  final DateTime horodatage;

  /// La categorie.
  final CategorieBesoin categorie;

  /// Les details internes : jamais envoyes a la famille.
  final String detailsInternes;

  /// Le resume partageable.
  final String resumePartageable;
}

/// « Signaler un besoin » (ENS-12) : la categorie en liste a choix unique,
/// « Details internes » et « Resume partageable » separes, chacun avec une
/// aide qui dit qui le lira, et la notice du doc 04 §22.3.
///
/// Sans [envoi] (demonstration, aucun serveur branche : K-28), la
/// confirmation dit que **rien n'a ete envoye**.
class SignalerBesoin extends StatefulWidget {
  /// Cree le formulaire.
  const SignalerBesoin({required this.eleve, super.key, this.envoi});

  /// L'eleve, prerempli.
  final EleveFiche eleve;

  /// L'envoi reel, absent tant que le serveur n'est pas branche.
  final Future<void> Function(SignalementBesoin signalement)? envoi;

  /// La cle du bouton d'envoi.
  static const Key envoyerKey = ValueKey<String>('signalement-envoyer');

  /// La cle du champ « Details internes ».
  static const Key detailsKey = ValueKey<String>('signalement-details');

  /// La cle du champ « Resume partageable ».
  static const Key resumeKey = ValueKey<String>('signalement-resume');

  /// La cle de la confirmation.
  static const Key confirmationKey = ValueKey<String>('signalement-confirme');

  @override
  State<SignalerBesoin> createState() => _SignalerBesoinState();
}

class _SignalerBesoinState extends State<SignalerBesoin> {
  final TextEditingController _details = TextEditingController();
  final TextEditingController _resume = TextEditingController();
  final FocusNode _focusDetails = FocusNode();
  CategorieBesoin? _categorie;
  String? _erreurCategorie;
  String? _erreurDetails;
  bool _enCours = false;
  bool _termine = false;
  bool _echec = false;

  @override
  void initState() {
    super.initState();
    // Validation a la sortie du champ, jamais pendant la frappe.
    _focusDetails.addListener(() {
      if (!_focusDetails.hasFocus) setState(_validerDetails);
    });
  }

  @override
  void dispose() {
    _details.dispose();
    _resume.dispose();
    _focusDetails.dispose();
    super.dispose();
  }

  /// Les phrases-types du resume pour une categorie (L7).
  static List<String> _phrasesTypes(CategorieBesoin? c) =>
      c == null ? const <String>[] : MotifsProposes.signalement(c.name);

  /// Change de categorie. Une phrase-type de l'ancienne categorie ne vaut
  /// plus : elle s'efface ; un texte ecrit a la main reste.
  void _changerCategorie(CategorieBesoin? c) {
    if (_phrasesTypes(_categorie).contains(_resume.text)) {
      _resume.clear();
    }
    _categorie = c;
  }

  void _validerDetails() {
    _erreurDetails =
        _categorie == CategorieBesoin.autre && _details.text.trim().isEmpty
        ? t.enseignant.signalement.detailsRequis
        : null;
  }

  Future<void> _envoyer() async {
    setState(() {
      _erreurCategorie = _categorie == null
          ? t.enseignant.signalement.choisirCategorie
          : null;
      _validerDetails();
    });
    final CategorieBesoin? categorie = _categorie;
    if (categorie == null || _erreurDetails != null) return;
    final Future<void> Function(SignalementBesoin)? envoi = widget.envoi;
    if (envoi != null) {
      setState(() {
        _enCours = true;
        _echec = false;
      });
      try {
        await envoi(
          SignalementBesoin(
            studentId: widget.eleve.membre.studentId,
            categorie: categorie,
            detailsInternes: _details.text.trim(),
            resumePartageable: _resume.text.trim(),
            classe: widget.eleve.classe,
            seanceId: widget.eleve.seanceId,
            horodatage: DateTime.now(),
          ),
        );
      } on Object {
        // Jamais de faux succes (E7, doc 04 §22.5) : les champs restent
        // saisis, la feuille reste ouverte, « Reessayer » relance l'envoi.
        if (mounted) {
          setState(() {
            _enCours = false;
            _echec = true;
          });
        }
        return;
      }
    }
    if (mounted) {
      setState(() {
        _enCours = false;
        _termine = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle doux = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final TextStyle erreur = palette.inkAlert.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );

    if (_termine) {
      // Succes honnete : en demonstration, on ne pretend jamais qu'un envoi
      // reel a eu lieu.
      return Semantics(
        key: SignalerBesoin.confirmationKey,
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              t.enseignant.signalement.demoSucces,
              style: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
            Ecart.vSm,
            Text(t.enseignant.signalement.demoSuccesDetail, style: doux),
            Ecart.vXl,
            ActionPrincipale(
              libelle: t.enseignant.signalement.fermer,
              niveau: NiveauAction.secondaire,
              onPress: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Eleve et Classe preremplis depuis la fiche (W-337) : rien a
        // recopier.
        Text(
          t.enseignant.signalement.contexte(
            prenom: widget.eleve.prenom,
            classe: widget.eleve.classe,
          ),
          style: doux,
        ),
        Ecart.vLg,
        Semantics(
          header: true,
          child: Text(
            t.enseignant.signalement.categorieTitre,
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        // Un choix unique en liste, toutes les options visibles (UX_REVIEW_04
        // n° 13 b) : jamais un menu deroulant cache. EN-12 (K-42, regles 1
        // et 4) : une liste groupee compacte, une ligne a radio par
        // categorie, comme le choix du theme du Compte.
        RadioGroup<CategorieBesoin>(
          groupValue: _categorie,
          onChanged: (CategorieBesoin? c) => setState(() {
            _changerCategorie(c);
            _erreurCategorie = null;
            if (_erreurDetails != null) _validerDetails();
          }),
          child: GroupeReglages(
            lignes: <LigneRubrique>[
              for (final CategorieBesoin c in CategorieBesoin.values)
                // Toute la ligne choisit (contrat B, cibles larges) : la
                // radio est une marque, hors de l'ordre Tab, pour ne pas
                // faire un second arret.
                LigneRubrique(
                  libelle: c.libelle,
                  icone: c.icone,
                  marque: ExcludeFocus(child: Radio<CategorieBesoin>(value: c)),
                  onPress: () => setState(() {
                    _changerCategorie(c);
                    _erreurCategorie = null;
                    if (_erreurDetails != null) _validerDetails();
                  }),
                ),
            ],
          ),
        ),
        if (_erreurCategorie != null) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(_erreurCategorie!, style: erreur),
          ),
        ],
        Ecart.vXl,
        ZoneSaisie(
          cleChamp: SignalerBesoin.detailsKey,
          controleur: _details,
          noeud: _focusDetails,
          libelle: t.enseignant.signalement.details,
          explication: t.enseignant.signalement.detailsAide,
          erreur: _erreurDetails,
          minLignes: 2,
          maxLignes: 5,
          onChanged: (String _) {
            // L'erreur se retire des la correction.
            if (_erreurDetails != null) setState(_validerDetails);
          },
        ),
        Ecart.vLg,
        // L7 : une phrase-type par categorie, « Autre » pour l'ecrire.
        Text(
          t.enseignant.signalement.resume,
          style: palette.inkStrong.applyTo(
            textes.titleSmall ?? const TextStyle(),
          ),
        ),
        Ecart.vXs,
        Text(t.enseignant.signalement.resumeAide, style: doux),
        Ecart.vSm,
        SelecteurMotif(
          motifs: _phrasesTypes(_categorie),
          controleur: _resume,
          libelleChamp: t.choix.autreInvite,
          lignesMin: 2,
          lignesMax: 4,
          cleChampLibre: SignalerBesoin.resumeKey,
        ),
        Ecart.vLg,
        Text(t.enseignant.signalement.notice, style: doux),
        if (_echec) ...<Widget>[
          Ecart.vLg,
          // Meme phrase que le signalement du parcours (tc.parcours).
          Semantics(
            liveRegion: true,
            child: Text(t.tc.parcours.signalement.echec, style: erreur),
          ),
        ],
        Ecart.vLg,
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ActionPrincipale(
            key: SignalerBesoin.envoyerKey,
            libelle: _echec
                ? t.commun.reessayer
                : t.enseignant.signalement.envoyer,
            pleineLargeur: false,
            enCours: _enCours,
            onPress: _enCours ? null : _envoyer,
          ),
        ),
      ],
    );
  }
}
