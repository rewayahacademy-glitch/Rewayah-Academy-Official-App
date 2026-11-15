// Le publieur d'annonce unique, sur UN seul ecran (ANNONCES-SIMPLES,
// directeur, 14/11/2026 : « celui qui existe demande un formulaire de plus de
// 5 etapes juste pour ecrire un petit message ; c'est scandaleux »).
//
// Il remplace les cinq etapes de `PageEtape` (contenu, audience, date, apercu,
// publication) par une seule page, pour la direction comme pour l'enseignant :
//
// - **Direction** ([PublieurAnnonce.direction]) : « A qui » (les publics que le
//   serveur ouvre, choix multiple, le nombre reel sous chacun), puis le
//   message (titre facultatif, texte), puis un seul bouton plein « Envoyer a
//   N personnes ». « Programmer l'envoi » et « Envoyer aussi par courriel »
//   sont deux options repliees (interrupteurs fermes par defaut). Une
//   confirmation simple repete le public et le nombre avant l'envoi.
// - **Enseignant** ([PublieurAnnonce.new], audience fixee) : sa Classe, sans
//   choix de public ; le meme message, le meme bouton.
//
// Aucun public n'est compose ici et aucune personne n'est comptee : les codes
// partent au serveur, les nombres en reviennent (`PortAnnoncesDirection`).
// Un public vide ne s'envoie pas : le bouton n'est pas rendu, la phrase dit
// pourquoi. Sur ordinateur (classe large), deux colonnes : la redaction a
// gauche, a droite l'apercu tel que le destinataire le verra, avec le nombre.
//
// **Une seule action pleine**, au bas du formulaire. **Rien n'est « envoyee »
// sans l'accuse du serveur** ; un echec dit « pas encore confirmee » (K-59,
// D5). La cle d'idempotence est tiree une fois et rejouee a chaque essai ;
// des qu'un envoi est parti sans accuse, le message est fige (COM-BR-02).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/fil_discussion.dart' show raccourciEnvoi;
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/vue_etat_communication.dart';
import '../suivi_foyer/filtres_historique.dart';
import 'confirmation_envoi_annonce.dart';
import 'port_annonces.dart';
import 'port_annonces_direction.dart';

/// Les heures des creneaux proposes, a l'heure du profil (HEURES-PROFIL H3).
const int _heureMatin = 8;
const int _heureSoir = 18;

/// Les creneaux de diffusion proposes a partir de l'instant [instant] :
/// demain matin, demain soir, lundi matin suivant (le lundi d'apres si demain
/// est deja lundi). Les jours et les heures sont ceux du fuseau du PROFIL
/// ([chezMoi]) ; les instants rendus en sont l'inverse exact
/// ([instantChezMoi], HEURES-PROFIL H3, 12/11/2026). Fonction pure, testee
/// seule.
List<DateTime> creneauxProgrammation(DateTime instant) {
  final DateTime maintenant = chezMoi(instant);
  final DateTime demain = DateTime.utc(
    maintenant.year,
    maintenant.month,
    maintenant.day + 1,
  );
  int ecart = (DateTime.monday - demain.weekday) % DateTime.daysPerWeek;
  if (ecart == 0) ecart = DateTime.daysPerWeek;
  final DateTime lundi = DateTime.utc(
    demain.year,
    demain.month,
    demain.day + ecart,
  );
  return <DateTime>[
    instantChezMoi(demain.year, demain.month, demain.day, _heureMatin),
    instantChezMoi(demain.year, demain.month, demain.day, _heureSoir),
    instantChezMoi(lundi.year, lundi.month, lundi.day, _heureMatin),
  ];
}

/// La phrase de confirmation d'une annonce, dite seulement apres l'accuse du
/// serveur.
String messageConfirmationAnnonce(AnnonceConfirmee c) {
  final p = t.com.annonces.publieur;
  return switch (c.etat) {
    EtatAnnonce.publiee => p.publiee,
    EtatAnnonce.planifiee => p.planifiee(
      // HEURES-PROFIL H2 : a l'heure du profil.
      date: dateCourte(chezMoi(c.le)),
      heure: heureMinute(chezMoi(c.le)),
    ),
  };
}

/// Le titre qui part quand la personne n'en ecrit pas : le debut de la
/// premiere ligne du texte (au plus 80 caracteres), la meme regle que le
/// serveur des annonces de la direction. Pure.
String titreParDefaut(String texte) {
  final String ligne = texte.trim().split('\n').first.trim();
  return ligne.length <= 80 ? ligne : ligne.substring(0, 80).trim();
}

/// Le publieur d'annonce, sur un seul ecran.
class PublieurAnnonce extends ConsumerStatefulWidget {
  /// Le publieur de l'enseignant : les audiences [cibles] rendues par le
  /// serveur (sa Classe), sans choix de public quand [audienceFixee].
  const PublieurAnnonce({
    required List<CibleAnnonce> this.cibles,
    required this.onQuitter,
    super.key,
    this.audienceFixee = false,
    this.peutProgrammer = false,
    this.onConfirmee,
    this.horloge,
  }) : publics = null;

  /// Le publieur de la direction : les [publics] ouverts par le serveur,
  /// chacun avec son nombre.
  const PublieurAnnonce.direction({
    required List<PublicAnnonce> this.publics,
    required this.onQuitter,
    super.key,
    this.peutProgrammer = false,
    this.onConfirmee,
    this.horloge,
  }) : cibles = null,
       audienceFixee = false;

  /// Les audiences de l'enseignant ; `null` pour la direction.
  final List<CibleAnnonce>? cibles;

  /// Les publics de la direction ; `null` pour l'enseignant.
  final List<PublicAnnonce>? publics;

  /// Vrai : l'audience est fixee (l'enseignant et sa Classe), montree sans
  /// choix.
  final bool audienceFixee;

  /// Vrai si la personne peut programmer (capacite du serveur).
  final bool peutProgrammer;

  /// Quitte le publieur (retour, « Terminer »).
  final VoidCallback onQuitter;

  /// Appele une fois, a la confirmation du serveur.
  final ValueChanged<AnnonceConfirmee>? onConfirmee;

  /// L'horloge des creneaux ; par defaut, maintenant.
  final DateTime Function()? horloge;

  /// La cle de l'action du bas, pour les tests.
  static const ValueKey<String> cleAction = ValueKey<String>('publieur-action');

  /// La cle du message d'erreur ou de confirmation, pour les tests.
  static const ValueKey<String> cleMessage = ValueKey<String>(
    'publieur-message',
  );

  /// La cle du champ titre, pour les tests.
  static const ValueKey<String> cleTitre = ValueKey<String>('publieur-titre');

  /// La cle du champ texte, pour les tests.
  static const ValueKey<String> cleTexte = ValueKey<String>('publieur-texte');

  /// La cle de l'apercu (ordinateur), pour les tests.
  static const ValueKey<String> cleApercu = ValueKey<String>('publieur-apercu');

  /// La cle de l'interrupteur « Programmer l'envoi », pour les tests.
  static const ValueKey<String> cleProgrammer = ValueKey<String>(
    'publieur-programmer',
  );

  /// La cle de l'interrupteur « Envoyer aussi par courriel », pour les tests.
  static const ValueKey<String> cleCourriel = ValueKey<String>(
    'publieur-courriel',
  );

  /// La cle de la confirmation « Envoyer », pour les tests.
  static const ValueKey<String> cleConfirmer = ValueKey<String>(
    'publieur-confirmer',
  );

  /// La cle de la carte d'une audience de l'enseignant, pour les tests.
  static ValueKey<String> cleCible(String id) =>
      ValueKey<String>('publieur-cible-$id');

  /// La cle de la ligne d'un public de la direction, pour les tests.
  static ValueKey<String> clePublic(String code) =>
      ValueKey<String>('publieur-public-$code');

  /// La cle de la carte d'un moment de diffusion, pour les tests :
  /// `creneau-0`, `creneau-1`, `creneau-2`.
  static ValueKey<String> cleQuand(String valeur) =>
      ValueKey<String>('publieur-quand-$valeur');

  @override
  ConsumerState<PublieurAnnonce> createState() => _PublieurAnnonceState();
}

/// Ce que dit le message sous le formulaire.
enum _Ton { erreur, succes, attente }

class _PublieurAnnonceState extends ConsumerState<PublieurAnnonce> {
  final TextEditingController _titre = TextEditingController();
  final TextEditingController _texte = TextEditingController();
  late CibleAnnonce? _cible = (widget.cibles?.length ?? 0) == 1
      ? widget.cibles!.single
      : null;
  final Set<String> _choisis = <String>{};
  bool _programmer = false;
  int _creneau = 0;
  bool _courriel = false;
  String? _message;
  _Ton _ton = _Ton.erreur;
  bool _envoi = false;
  AnnonceConfirmee? _confirmee;
  bool _indisponible = false;
  String? _cle;
  bool _envoye = false;

  late final List<DateTime> _creneaux = creneauxProgrammation(
    (widget.horloge ?? DateTime.now)(),
  );

  bool get _direction => widget.publics != null;

  List<String> get _ordre => <String>[
    for (final PublicAnnonce p in widget.publics ?? const <PublicAnnonce>[])
      p.code,
  ];

  DateTime? get _programmeeLe => _programmer ? _creneaux[_creneau] : null;

  /// Le message n'est plus modifiable une fois un envoi parti.
  bool get _fige => _envoye || _confirmee != null;

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
    if (_message != null && _ton == _Ton.erreur) {
      setState(() => _message = null);
    }
  }

  void _retour() {
    if (_envoi) return;
    widget.onQuitter();
  }

  AsyncValue<AudienceAnnonce>? _audience() {
    if (!_direction || _choisis.isEmpty) return null;
    return ref.watch(audienceAnnonceProvider(clePublics(_choisis)));
  }

  String _libelleAction(AsyncValue<AudienceAnnonce>? audience) {
    final p = t.com.annonces.publieur;
    final s = t.com.annonces.simple;
    if (_confirmee != null || _indisponible) return p.terminer;
    if (_envoye && _ton == _Ton.erreur) return p.reessayer;
    if (!_direction) {
      final String cible = _cible?.libelle ?? '';
      if (_programmer) return p.programmer;
      return cible.isEmpty ? p.publier : s.publierDans(cible: cible);
    }
    final int? n = audience != null && audience.hasValue && !audience.hasError
        ? audience.requireValue.destinataires
        : null;
    if (n == null || n == 0) return s.envoyer;
    return _programmer ? s.programmerPour(n: n) : s.envoyerA(n: n);
  }

  Future<void> _agir(AsyncValue<AudienceAnnonce>? audience) async {
    if (_envoi) return;
    if (_confirmee != null || _indisponible) {
      widget.onQuitter();
      return;
    }
    final s = t.com.annonces.simple;
    String? manque;
    if (_direction && _choisis.isEmpty) {
      manque = s.manquePublic;
    } else if (!_direction && _cible == null) {
      manque = t.com.annonces.publieur.manqueAudience;
    } else if (_texte.text.trim().isEmpty) {
      manque = s.manqueTexte;
    } else if (_direction &&
        (audience == null || !audience.hasValue || audience.hasError)) {
      manque = audience != null && audience.hasError
          ? s.audienceEchec
          : s.calcul;
    }
    if (manque != null) {
      setState(() {
        _message = manque;
        _ton = _Ton.erreur;
      });
      return;
    }
    if (_direction && !_envoye) {
      final bool oui = await _confirmer(audience!.requireValue);
      if (!oui || !mounted) return;
    }
    await _envoyer();
  }

  Future<bool> _confirmer(AudienceAnnonce audience) async {
    final s = t.com.annonces.simple;
    final int n = audience.destinataires;
    final DateTime? le = _programmeeLe;
    final String consequence = <String>[
      s.confirmerTexte(n: n, publics: libellesPublics(_choisis, _ordre)),
      if (le != null)
        s.confirmerProgrammee(
          date: dateMoyenne(chezMoi(le)),
          heure: heureMinute(chezMoi(le)),
        ),
      if (_courriel) s.confirmerCourriel,
    ].join(' ');
    final String libelle = _libelleAction(AsyncData<AudienceAnnonce>(audience));
    return confirmerEnvoiAnnonce(
      context,
      titre: s.confirmerTitre,
      consequence: consequence,
      libelleEnvoyer: libelle,
      libelleRevenir: s.revenir,
      cleEnvoyer: PublieurAnnonce.cleConfirmer,
    );
  }

  Future<void> _envoyer() async {
    final p = t.com.annonces.publieur;
    final String cle = _cle ??= const Uuid().v4();
    final String texte = _texte.text.trim();
    final String titre = _titre.text.trim();
    setState(() {
      _envoi = true;
      _envoye = true;
      _message = p.enCours;
      _ton = _Ton.attente;
    });
    try {
      final AnnonceConfirmee confirmee;
      if (_direction) {
        confirmee = await ref
            .read(portAnnoncesDirectionProvider)
            .envoyer(
              envoi: EnvoiAnnonce(
                publics: Set<String>.of(_choisis),
                titre: titre,
                texte: texte,
                programmeeLe: _programmeeLe?.toUtc(),
                courriel: _courriel,
              ),
              cleIdempotence: cle,
            );
      } else {
        confirmee = await ref
            .read(portAnnoncesProvider)
            .publier(
              brouillon: BrouillonAnnonce(
                titre: titre.isEmpty ? titreParDefaut(texte) : titre,
                texte: texte,
                cible: _cible!,
                programmeeLe: _programmeeLe?.toUtc(),
              ),
              cleIdempotence: cle,
            );
      }
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
    final bool mobile = AppGabarit.de(context) == Gabarit.mobile;
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;
    final AsyncValue<AudienceAnnonce>? audience = _audience();
    // Un public vide ne s'envoie pas : pas de bouton, la phrase dit pourquoi.
    final bool vide =
        audience != null &&
        audience.hasValue &&
        !audience.hasError &&
        audience.requireValue.destinataires == 0 &&
        _confirmee == null &&
        !_envoye;

    final Widget action = Align(
      alignment: AlignmentDirectional.centerEnd,
      child: ActionPrincipale(
        key: PublieurAnnonce.cleAction,
        libelle: _libelleAction(audience),
        enCours: _envoi,
        pleineLargeur: mobile,
        onPress: () => _agir(audience),
      ),
    );

    final Widget redaction = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _aQui(context, audience),
        Ecart.vSection,
        _redaction(context),
        if (widget.peutProgrammer || _direction) ...<Widget>[
          Ecart.vXl,
          _options(context, audience),
        ],
        ..._messageSous(context),
        if (!vide) ...<Widget>[Ecart.vXl, action],
      ],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool fait, Object? _) {
        if (!fait) _retour();
      },
      child: PageShell(
        titre: t.com.annonces.simple.titre,
        onRetour: _retour,
        bandeauHorsLigne: BandeauHorsLigneCommunication(
          message: t.com.annonces.administration.horsLigne,
        ),
        // R-25 : Ctrl+Entree (Cmd+Entree) envoie depuis un champ ; Entree
        // garde le saut de ligne.
        child: raccourciEnvoi(
          onEnvoyer: () => _agir(audience),
          child: bureau
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.xxxl,
                  children: <Widget>[
                    Expanded(flex: 3, child: redaction),
                    Expanded(flex: 2, child: _apercu(context, audience)),
                  ],
                )
              : Align(
                  alignment: AlignmentDirectional.topStart,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppPage.largeurFormulaire,
                    ),
                    child: redaction,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _titreSection(BuildContext context, String titre) {
    final AppPalette palette = AppPalette.of(context);
    return Semantics(
      header: true,
      child: Text(
        titre,
        style: palette.inkStrong.applyTo(
          Theme.of(context).textTheme.titleMedium ?? const TextStyle(),
        ),
      ),
    );
  }

  Widget _phrase(BuildContext context, String texte, {AppInkColor? encre}) {
    final AppPalette palette = AppPalette.of(context);
    return Text(
      texte,
      style: (encre ?? palette.inkMuted).applyTo(
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
      ),
    );
  }

  Widget _aQui(BuildContext context, AsyncValue<AudienceAnnonce>? audience) {
    final s = t.com.annonces.simple;
    final AppPalette palette = AppPalette.of(context);
    if (!_direction) {
      final List<CibleAnnonce> cibles = widget.cibles ?? const <CibleAnnonce>[];
      final CibleAnnonce? cible = _cible;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _titreSection(context, s.aQui),
          Ecart.vSm,
          if (widget.audienceFixee || cibles.length == 1)
            CarteGroupee(
              key: PublieurAnnonce.cleCible((cible ?? cibles.first).id),
              sections: <Widget>[
                _LigneApercu(
                  titre: (cible ?? cibles.first).libelle,
                  texte: s.classeContexte(
                    cible: (cible ?? cibles.first).libelle,
                  ),
                ),
              ],
            )
          else
            ChoiceCardGroup(
              key: const ValueKey<String>('publieur-choix-audience'),
              autoriserSaisieLibre: false,
              compacte: true,
              valeurInitiale: cible == null
                  ? null
                  : ReponseChoix(valeurs: <String>{cible.id}),
              options: <OptionChoix>[
                for (final CibleAnnonce c in cibles)
                  OptionChoix(
                    cle: PublieurAnnonce.cleCible(c.id),
                    valeur: c.id,
                    libelle: c.libelle,
                  ),
              ],
              onChange: (ReponseChoix reponse) {
                if (_fige) return;
                final String? id = reponse.valeurs.firstOrNull;
                setState(() {
                  _cible = cibles
                      .where((CibleAnnonce c) => c.id == id)
                      .firstOrNull;
                  _brouillonChange();
                });
              },
            ),
        ],
      );
    }
    final List<PublicAnnonce> publics = widget.publics!;
    final bool filtres = publics.any(
      (PublicAnnonce p) => CodesPublics.estFiltre(p.code),
    );
    final List<Widget> etat = <Widget>[];
    if (audience != null) {
      if (audience.hasError) {
        etat.addAll(<Widget>[
          _phrase(context, s.audienceEchec, encre: palette.inkAlert),
          Ecart.vXs,
          LienFleche(
            libelle: t.commun.etats.actions.reessayer,
            onPress: () =>
                ref.invalidate(audienceAnnonceProvider(clePublics(_choisis))),
          ),
        ]);
      } else if (!audience.hasValue) {
        etat.add(_phrase(context, s.calcul));
      } else {
        final AudienceAnnonce a = audience.requireValue;
        etat.add(
          Semantics(
            liveRegion: true,
            child: switch (a.raison) {
              RaisonVide.coteInconnu => _phrase(
                context,
                s.videCote,
                encre: palette.inkAlert,
              ),
              _ when a.destinataires == 0 => _phrase(
                context,
                s.videPersonne,
                encre: palette.inkAlert,
              ),
              _ => _phrase(
                context,
                s.personnes(n: a.destinataires),
                encre: palette.inkStrong,
              ),
            },
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _titreSection(context, s.aQui),
        Ecart.vXs,
        _phrase(context, s.aQuiContexte),
        Ecart.vMd,
        ChoiceCardGroup(
          key: const ValueKey<String>('publieur-choix-publics'),
          selectionMultiple: true,
          indicationMultiple: false,
          autoriserSaisieLibre: false,
          compacte: true,
          options: <OptionChoix>[
            for (final PublicAnnonce p in publics)
              OptionChoix(
                cle: PublieurAnnonce.clePublic(p.code),
                valeur: p.code,
                libelle: libellePublic(p.code),
                description: s.personnes(n: p.destinataires),
              ),
          ],
          onChange: (ReponseChoix reponse) {
            if (_fige) return;
            setState(() {
              _choisis
                ..clear()
                ..addAll(reponse.valeurs);
              _brouillonChange();
            });
          },
        ),
        Ecart.vSm,
        _phrase(context, s.elevesDetail),
        if (filtres) ...<Widget>[Ecart.vXs, _phrase(context, s.aQuiFiltres)],
        if (etat.isNotEmpty) ...<Widget>[Ecart.vMd, ...etat],
      ],
    );
  }

  Widget _redaction(BuildContext context) {
    final s = t.com.annonces.simple;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _titreSection(context, s.message),
        Ecart.vMd,
        TextField(
          key: PublieurAnnonce.cleTitre,
          controller: _titre,
          readOnly: _fige,
          maxLength: 120,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          onChanged: (String _) => setState(_brouillonChange),
          decoration: InputDecoration(labelText: s.champTitre, counterText: ''),
        ),
        Ecart.vLg,
        TextField(
          key: PublieurAnnonce.cleTexte,
          controller: _texte,
          readOnly: _fige,
          minLines: 4,
          maxLines: 12,
          maxLength: 5000,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (String _) => setState(_brouillonChange),
          decoration: InputDecoration(
            labelText: s.champTexte,
            alignLabelWithHint: true,
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _options(BuildContext context, AsyncValue<AudienceAnnonce>? audience) {
    final s = t.com.annonces.simple;
    final q = t.com.annonces.publieur.quand;
    final AppPalette palette = AppPalette.of(context);
    final EstimationCourriel? estimation =
        audience != null && audience.hasValue && !audience.hasError
        ? audience.requireValue.courriel
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CarteLignes(
          lignes: <Widget>[
            if (widget.peutProgrammer)
              SettingRow(
                title: s.programmer,
                description: s.programmerDetail,
                controle: Switch.adaptive(
                  key: PublieurAnnonce.cleProgrammer,
                  value: _programmer,
                  onChanged: _fige
                      ? null
                      : (bool v) => setState(() {
                          _programmer = v;
                          _brouillonChange();
                        }),
                ),
              ),
            if (_direction)
              SettingRow(
                title: s.courriel,
                description: s.courrielDetail,
                controle: Switch.adaptive(
                  key: PublieurAnnonce.cleCourriel,
                  value: _courriel,
                  onChanged: _fige
                      ? null
                      : (bool v) => setState(() {
                          _courriel = v;
                          _brouillonChange();
                        }),
                ),
              ),
          ],
        ),
        if (_programmer) ...<Widget>[
          Ecart.vLg,
          ChoiceCardGroup(
            key: const ValueKey<String>('publieur-choix-quand'),
            autoriserSaisieLibre: false,
            compacte: true,
            valeurInitiale: ReponseChoix(
              valeurs: <String>{'creneau-$_creneau'},
            ),
            options: <OptionChoix>[
              for (int i = 0; i < _creneaux.length; i++)
                OptionChoix(
                  cle: PublieurAnnonce.cleQuand('creneau-$i'),
                  valeur: 'creneau-$i',
                  libelle: q.creneau(
                    date: dateMoyenne(chezMoi(_creneaux[i])),
                    heure: heureMinute(chezMoi(_creneaux[i])),
                  ),
                ),
            ],
            onChange: (ReponseChoix reponse) {
              if (_fige) return;
              final String v = reponse.valeurs.firstOrNull ?? 'creneau-0';
              setState(() {
                _creneau = int.parse(v.substring('creneau-'.length));
                _brouillonChange();
              });
            },
          ),
        ],
        if (_courriel && estimation != null) ...<Widget>[
          Ecart.vMd,
          _phrase(
            context,
            estimation.adresses == 0
                ? s.courrielAucun
                : estimation.jours <= 1
                ? s.courrielUnJour(adresses: '${estimation.adresses}')
                : s.courrielJours(
                    adresses: '${estimation.adresses}',
                    parJour: '${estimation.parJour}',
                    jours: '${estimation.jours}',
                  ),
            encre: estimation.jours > 1 ? palette.inkAlert : null,
          ),
        ],
      ],
    );
  }

  List<Widget> _messageSous(BuildContext context) {
    final String? message = _message;
    if (message == null) return const <Widget>[];
    final AppPalette palette = AppPalette.of(context);
    return <Widget>[
      Ecart.vLg,
      Semantics(
        liveRegion: true,
        child: Text(
          message,
          key: PublieurAnnonce.cleMessage,
          style:
              switch (_ton) {
                _Ton.erreur => palette.inkAlert,
                _Ton.succes => palette.inkSuccess,
                _Ton.attente => palette.inkMuted,
              }.applyTo(
                Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
              ),
        ),
      ),
    ];
  }

  Widget _apercu(BuildContext context, AsyncValue<AudienceAnnonce>? audience) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final s = t.com.annonces.simple;
    final String texte = _texte.text.trim();
    final String titre = _titre.text.trim().isEmpty
        ? titreParDefaut(texte)
        : _titre.text.trim();
    final String aQui = _direction
        ? (_choisis.isEmpty ? '' : libellesPublics(_choisis, _ordre))
        : (_cible?.libelle ?? '');
    final int? n = audience != null && audience.hasValue && !audience.hasError
        ? audience.requireValue.destinataires
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _titreSection(context, s.apercuTitre),
        Ecart.vMd,
        CarteGroupee(
          key: PublieurAnnonce.cleApercu,
          sections: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                StatusPill(
                  libelle: t.com.annonces.annonce,
                  ton: TonEtat.accent,
                ),
                Ecart.vSm,
                if (texte.isEmpty)
                  _phrase(context, s.apercuVide)
                else ...<Widget>[
                  Text(
                    titre,
                    style: palette.inkStrong.applyTo(
                      textes.titleMedium ?? const TextStyle(),
                    ),
                  ),
                  Ecart.vSm,
                  Text(
                    texte,
                    style: palette.inkStrong.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                ],
              ],
            ),
            if (aQui.isNotEmpty)
              _LigneApercu(
                titre: t.com.annonces.publieur.apercu.a(cible: aQui),
                texte: n == null ? s.calcul : s.personnes(n: n),
              ),
          ],
        ),
        if (_titre.text.trim().isEmpty && texte.isNotEmpty) ...<Widget>[
          Ecart.vSm,
          _phrase(context, s.apercuSansTitre),
        ],
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
