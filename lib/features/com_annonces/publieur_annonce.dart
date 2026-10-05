// Le publieur d'annonce unique (`AnnouncementPublisher`, spec section 20,
// section 13.4 ; COM-BR-10, COM-BR-02).
//
// UN seul publieur pour l'Administration et pour l'enseignant (COM-0b,
// 02_DEC-04). Il recoit les audiences que le serveur ouvre a la personne
// ([PortAnnonces.ciblesPublication]) : l'Administration choisit parmi
// elles ; l'enseignant n'en a qu'une, sa Classe, et l'etape « audience » la
// montre sans choix ([PublieurAnnonce.audienceFixee]). Aucune audience n'est
// composee ici, et le serveur refuse quand meme toute autre.
//
// Cinq etapes, une tache focalisee sur `PageEtape` :
//
// 1. contenu (titre, texte : SAISIS, car c'est l'annonce meme, K-57) ;
// 2. audience (DEDUITE quand une seule est ouverte, sinon CHOISIE) ;
// 3. date de diffusion, seulement si la personne peut programmer
//    (`CapaciteCommunication.programmer`) : sinon l'etape n'existe pas et
//    l'annonce part a la confirmation. Les creneaux sont PROPOSES (demain
//    matin, demain soir, lundi matin), jamais saisis ;
// 4. apercu, tel que les destinataires la liront ;
// 5. publication.
//
// **Une seule action pleine a la fois** : l'action collee en bas change de
// libelle d'une etape a l'autre (Continuer, Publier, Reessayer, Terminer),
// jamais deux boutons pleins. **Rien n'est « Publiee » sans l'accuse du
// serveur** : le futur de `publier` se termine sur une [AnnonceConfirmee] ;
// un echec dit « pas encore confirmee » (K-59, D5), une capacite absente dit
// « pas encore disponible ». La cle d'idempotence est tiree une fois par
// annonce et rejouee a chaque nouvelle tentative : un « Reessayer » ne publie
// jamais deux fois (COM-BR-02).
//
// **Une fois un envoi parti, l'annonce n'est plus modifiable** : pendant
// l'envoi, le retour ne fait rien ; apres un envoi non confirme, le retour
// quitte le publieur au lieu de rouvrir le contenu. Sinon, corriger une
// coquille tirerait une nouvelle cle, et une annonce deja arrivee au serveur
// partirait une deuxieme fois, contrairement a « elle ne partira qu'une
// fois ».

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/page_etape.dart';
import '../../core/widgets/status_pill.dart';
import '../suivi_foyer/filtres_historique.dart';
import 'port_annonces.dart';

/// Les etapes du publieur, dans l'ordre de la spec section 20.
enum EtapePublication {
  /// Le titre et le texte.
  contenu,

  /// L'audience.
  audience,

  /// La date de diffusion (seulement si la personne peut programmer).
  programmation,

  /// L'apercu.
  previsualisation,

  /// La publication et sa confirmation.
  publication,
}

/// Les heures des creneaux proposes, en heure locale.
const int _heureMatin = 8;
const int _heureSoir = 18;

/// Les creneaux de diffusion proposes a partir de [maintenant] (heure
/// locale) : demain matin, demain soir, lundi matin suivant (le lundi d'apres
/// si demain est deja lundi). Fonction pure, testee seule.
List<DateTime> creneauxProgrammation(DateTime maintenant) {
  final DateTime demain = DateTime(
    maintenant.year,
    maintenant.month,
    maintenant.day + 1,
  );
  int ecart = (DateTime.monday - demain.weekday) % DateTime.daysPerWeek;
  if (ecart == 0) ecart = DateTime.daysPerWeek;
  final DateTime lundi = DateTime(
    demain.year,
    demain.month,
    demain.day + ecart,
  );
  return <DateTime>[
    DateTime(demain.year, demain.month, demain.day, _heureMatin),
    DateTime(demain.year, demain.month, demain.day, _heureSoir),
    DateTime(lundi.year, lundi.month, lundi.day, _heureMatin),
  ];
}

/// La phrase de confirmation d'une annonce, dite seulement apres l'accuse du
/// serveur.
String messageConfirmationAnnonce(AnnonceConfirmee c) {
  final p = t.com.annonces.publieur;
  return switch (c.etat) {
    EtatAnnonce.publiee => p.publiee,
    EtatAnnonce.planifiee => p.planifiee(
      date: dateCourte(c.le.toLocal()),
      heure: heureMinute(c.le.toLocal()),
    ),
  };
}

/// Le publieur d'annonce.
class PublieurAnnonce extends ConsumerStatefulWidget {
  /// Cree le publieur sur les audiences [cibles] rendues par le serveur
  /// (au moins une).
  const PublieurAnnonce({
    required this.cibles,
    required this.onQuitter,
    super.key,
    this.audienceFixee = false,
    this.peutProgrammer = false,
    this.onConfirmee,
    this.horloge,
  });

  /// Les audiences ouvertes a la personne.
  final List<CibleAnnonce> cibles;

  /// Vrai : l'audience est fixee (l'enseignant et sa Classe) ; l'etape la
  /// montre, sans choix.
  final bool audienceFixee;

  /// Vrai si la personne peut programmer (capacite du serveur).
  final bool peutProgrammer;

  /// Quitte le publieur (retour de la premiere etape, « Terminer »).
  final VoidCallback onQuitter;

  /// Appele une fois, a la confirmation du serveur.
  final ValueChanged<AnnonceConfirmee>? onConfirmee;

  /// L'horloge des creneaux ; par defaut, maintenant.
  final DateTime Function()? horloge;

  /// La cle de l'action collee en bas, pour les tests.
  static const ValueKey<String> cleAction = ValueKey<String>('publieur-action');

  /// La cle du message d'erreur ou de confirmation, pour les tests.
  static const ValueKey<String> cleMessage = ValueKey<String>(
    'publieur-message',
  );

  /// La cle du champ titre, pour les tests.
  static const ValueKey<String> cleTitre = ValueKey<String>('publieur-titre');

  /// La cle du champ texte, pour les tests.
  static const ValueKey<String> cleTexte = ValueKey<String>('publieur-texte');

  /// La cle de l'apercu, pour les tests.
  static const ValueKey<String> cleApercu = ValueKey<String>('publieur-apercu');

  /// La cle de la carte d'une audience, pour les tests.
  static ValueKey<String> cleCible(String id) =>
      ValueKey<String>('publieur-cible-$id');

  /// La cle de la carte d'un moment de diffusion, pour les tests :
  /// `maintenant`, ou `creneau-0`, `creneau-1`, `creneau-2`.
  static ValueKey<String> cleQuand(String valeur) =>
      ValueKey<String>('publieur-quand-$valeur');

  @override
  ConsumerState<PublieurAnnonce> createState() => _PublieurAnnonceState();
}

/// Ce que dit le message sous l'etape.
enum _Ton { erreur, succes, attente }

class _PublieurAnnonceState extends ConsumerState<PublieurAnnonce> {
  final TextEditingController _titre = TextEditingController();
  final TextEditingController _texte = TextEditingController();
  late CibleAnnonce? _cible = widget.cibles.length == 1
      ? widget.cibles.single
      : null;
  DateTime? _programmeeLe;
  int _rang = 0;
  String? _message;
  _Ton _ton = _Ton.erreur;
  bool _envoi = false;
  AnnonceConfirmee? _confirmee;

  /// Vrai quand la publication n'a pas de contrat (port neutre) : rien a
  /// reessayer, l'action devient « Terminer ».
  bool _indisponible = false;

  /// Tiree a l'arrivee a la publication, gardee a chaque nouvelle tentative,
  /// oubliee des que le brouillon change (tant qu'aucun envoi n'est parti).
  String? _cle;

  /// Vrai des qu'un envoi est parti sans accuse : le brouillon est fige, la
  /// cle aussi, et seul « Reessayer » (meme cle) ou la sortie restent.
  bool _envoye = false;

  late final List<DateTime> _creneaux = creneauxProgrammation(
    (widget.horloge ?? DateTime.now)(),
  );

  List<EtapePublication> get _etapes => <EtapePublication>[
    EtapePublication.contenu,
    EtapePublication.audience,
    if (widget.peutProgrammer) EtapePublication.programmation,
    EtapePublication.previsualisation,
    EtapePublication.publication,
  ];

  EtapePublication get _etape => _etapes[_rang];

  @override
  void dispose() {
    _titre.dispose();
    _texte.dispose();
    super.dispose();
  }

  void _brouillonChange() {
    // Un envoi parti sans accuse fige la cle (COM-BR-02).
    if (_envoye) return;
    _cle = null;
  }

  void _retour() {
    // Pendant l'envoi, rien : l'accuse est attendu.
    if (_envoi) return;
    if (_confirmee != null || _rang == 0 || _envoye) {
      widget.onQuitter();
      return;
    }
    setState(() {
      _rang--;
      _message = null;
    });
  }

  void _suivant() {
    final p = t.com.annonces.publieur;
    String? manque;
    switch (_etape) {
      case EtapePublication.contenu:
        if (_titre.text.trim().isEmpty || _texte.text.trim().isEmpty) {
          manque = p.manqueContenu;
        }
      case EtapePublication.audience:
        if (_cible == null) manque = p.manqueAudience;
      case EtapePublication.programmation:
      case EtapePublication.previsualisation:
      case EtapePublication.publication:
        break;
    }
    setState(() {
      if (manque != null) {
        _message = manque;
        _ton = _Ton.erreur;
        return;
      }
      _message = null;
      _rang++;
      if (_etape == EtapePublication.publication) {
        _cle ??= const Uuid().v4();
      }
    });
  }

  Future<void> _publier() async {
    final CibleAnnonce? cible = _cible;
    if (cible == null || _envoi) return;
    final p = t.com.annonces.publieur;
    final String cle = _cle ??= const Uuid().v4();
    setState(() {
      _envoi = true;
      _envoye = true;
      _message = p.enCours;
      _ton = _Ton.attente;
    });
    try {
      final AnnonceConfirmee confirmee = await ref
          .read(portAnnoncesProvider)
          .publier(
            brouillon: BrouillonAnnonce(
              titre: _titre.text.trim(),
              texte: _texte.text.trim(),
              cible: cible,
              programmeeLe: _programmeeLe?.toUtc(),
            ),
            cleIdempotence: cle,
          );
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _confirmee = confirmee;
        _ton = _Ton.succes;
        _message = messageConfirmationAnnonce(confirmee);
      });
      widget.onConfirmee?.call(confirmee);
    } on CapaciteIndisponible {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _indisponible = true;
        _ton = _Ton.erreur;
        _message = p.indisponible;
      });
    } on Object {
      if (!mounted) return;
      final bool horsLigne = ref.read(horsLigneProvider).value ?? false;
      setState(() {
        _envoi = false;
        _ton = _Ton.erreur;
        _message = horsLigne ? p.horsLigne : p.nonConfirmee;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = t.com.annonces.publieur;
    final bool mobile = AppGabarit.de(context) == Gabarit.mobile;
    final bool publication = _etape == EtapePublication.publication;
    final String libelle = !publication
        ? p.continuer
        : _confirmee != null || _indisponible
        ? p.terminer
        : (_message != null && _ton == _Ton.erreur
              ? p.reessayer
              : (_programmeeLe == null ? p.publier : p.programmer));
    final VoidCallback action = !publication
        ? _suivant
        : _confirmee != null || _indisponible
        ? widget.onQuitter
        : _publier;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool fait, Object? _) {
        if (!fait) _retour();
      },
      child: PageEtape(
        numero: _rang + 1,
        total: _etapes.length,
        onRetour: _retour,
        action: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ActionPrincipale(
            key: PublieurAnnonce.cleAction,
            libelle: libelle,
            enCours: _envoi,
            pleineLargeur: mobile,
            onPress: action,
          ),
        ),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppPage.largeurFormulaire,
            ),
            child: _corps(context),
          ),
        ),
      ),
    );
  }

  Widget _corps(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final p = t.com.annonces.publieur;
    final (String titre, String contexte, Widget corps) = switch (_etape) {
      EtapePublication.contenu => (
        p.etapes.contenu,
        p.contexte.contenu,
        _contenu(),
      ),
      EtapePublication.audience => (
        p.etapes.audience,
        widget.audienceFixee && _cible != null
            ? p.contexte.audienceFixee(cible: _cible!.libelle)
            : p.contexte.audience,
        _audience(),
      ),
      EtapePublication.programmation => (
        p.etapes.programmation,
        p.contexte.programmation,
        _programmation(),
      ),
      EtapePublication.previsualisation => (
        p.etapes.previsualisation,
        p.contexte.previsualisation,
        _apercu(context),
      ),
      EtapePublication.publication => (
        p.etapes.publication,
        p.contexte.publication,
        _resume(context),
      ),
    };
    final String? message = _message;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            titre,
            style: palette.inkStrong.applyTo(
              textes.titleLarge ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        Text(
          contexte,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vXl,
        corps,
        if (message != null) ...<Widget>[
          Ecart.vLg,
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              key: PublieurAnnonce.cleMessage,
              style: switch (_ton) {
                _Ton.erreur => palette.inkAlert,
                _Ton.succes => palette.inkSuccess,
                _Ton.attente => palette.inkMuted,
              }.applyTo(textes.bodyMedium ?? const TextStyle()),
            ),
          ),
        ],
      ],
    );
  }

  Widget _contenu() {
    final p = t.com.annonces.publieur;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          key: PublieurAnnonce.cleTitre,
          controller: _titre,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          onChanged: (String _) => _brouillonChange(),
          decoration: InputDecoration(labelText: p.champTitre),
        ),
        Ecart.vLg,
        TextField(
          key: PublieurAnnonce.cleTexte,
          controller: _texte,
          minLines: 4,
          maxLines: 10,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (String _) => _brouillonChange(),
          decoration: InputDecoration(
            labelText: p.champTexte,
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  /// La phrase de consequence d'une audience (K-58).
  static String consequence(NatureCible nature) {
    final n = t.com.annonces.publieur.nature;
    return switch (nature) {
      NatureCible.classe => n.classe,
      NatureCible.public => n.public,
      NatureCible.toutes => n.toutes,
    };
  }

  Widget _audience() {
    final CibleAnnonce? cible = _cible;
    if (widget.audienceFixee || widget.cibles.length == 1) {
      // Deduite : une seule audience ouverte, montree sans choix.
      final CibleAnnonce seule = cible ?? widget.cibles.first;
      return CarteGroupee(
        key: PublieurAnnonce.cleCible(seule.id),
        sections: <Widget>[
          _LigneApercu(titre: seule.libelle, texte: consequence(seule.nature)),
        ],
      );
    }
    return ChoiceCardGroup(
      key: const ValueKey<String>('publieur-choix-audience'),
      autoriserSaisieLibre: false,
      valeurInitiale: cible == null
          ? null
          : ReponseChoix(valeurs: <String>{cible.id}),
      options: <OptionChoix>[
        for (final CibleAnnonce c in widget.cibles)
          OptionChoix(
            cle: PublieurAnnonce.cleCible(c.id),
            valeur: c.id,
            libelle: c.libelle,
            description: consequence(c.nature),
          ),
      ],
      onChange: (ReponseChoix reponse) {
        final String? id = reponse.valeurs.firstOrNull;
        setState(() {
          _cible = widget.cibles
              .where((CibleAnnonce c) => c.id == id)
              .firstOrNull;
          _message = null;
          _brouillonChange();
        });
      },
    );
  }

  Widget _programmation() {
    final q = t.com.annonces.publieur.quand;
    final DateTime? choisi = _programmeeLe;
    final int rangChoisi = choisi == null ? -1 : _creneaux.indexOf(choisi);
    return ChoiceCardGroup(
      key: const ValueKey<String>('publieur-choix-quand'),
      autoriserSaisieLibre: false,
      valeurInitiale: ReponseChoix(
        valeurs: <String>{
          if (rangChoisi < 0) 'maintenant' else 'creneau-$rangChoisi',
        },
      ),
      options: <OptionChoix>[
        OptionChoix(
          cle: PublieurAnnonce.cleQuand('maintenant'),
          valeur: 'maintenant',
          libelle: q.maintenant,
          description: q.maintenantDetail,
        ),
        for (int i = 0; i < _creneaux.length; i++)
          OptionChoix(
            cle: PublieurAnnonce.cleQuand('creneau-$i'),
            valeur: 'creneau-$i',
            libelle: q.creneau(
              date: dateMoyenne(_creneaux[i]),
              heure: heureMinute(_creneaux[i]),
            ),
            description: q.creneauDetail,
          ),
      ],
      onChange: (ReponseChoix reponse) {
        final String valeur = reponse.valeurs.firstOrNull ?? 'maintenant';
        setState(() {
          _programmeeLe = valeur.startsWith('creneau-')
              ? _creneaux[int.parse(valeur.substring('creneau-'.length))]
              : null;
          _brouillonChange();
        });
      },
    );
  }

  String _diffusion() {
    final a = t.com.annonces.publieur.apercu;
    final DateTime? le = _programmeeLe;
    return le == null
        ? a.diffusionMaintenant
        : a.diffusionLe(date: dateMoyenne(le), heure: heureMinute(le));
  }

  Widget _apercu(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final a = t.com.annonces.publieur.apercu;
    return CarteGroupee(
      key: PublieurAnnonce.cleApercu,
      sections: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            StatusPill(libelle: t.com.annonces.annonce, ton: TonEtat.accent),
            Ecart.vSm,
            Text(
              _titre.text.trim(),
              style: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
            Ecart.vSm,
            Text(
              _texte.text.trim(),
              style: palette.inkStrong.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ],
        ),
        _LigneApercu(
          titre: a.a(cible: _cible?.libelle ?? ''),
          texte: _diffusion(),
        ),
      ],
    );
  }

  Widget _resume(BuildContext context) {
    final a = t.com.annonces.publieur.apercu;
    return CarteGroupee(
      sections: <Widget>[
        _LigneApercu(titre: _titre.text.trim(), texte: _diffusion()),
        _LigneApercu(
          titre: a.a(cible: _cible?.libelle ?? ''),
          texte: consequence(_cible?.nature ?? NatureCible.classe),
        ),
      ],
    );
  }
}

/// Une ligne de l'apercu : un titre et une phrase.
class _LigneApercu extends StatelessWidget {
  const _LigneApercu({required this.titre, required this.texte});

  final String titre;
  final String texte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          titre,
          style: palette.inkStrong.applyTo(
            textes.titleSmall ?? const TextStyle(),
          ),
        ),
        Ecart.vXs,
        Text(
          texte,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
      ],
    );
  }
}
