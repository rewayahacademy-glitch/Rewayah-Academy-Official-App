import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appairage/code_local.dart';
import '../../core/appairage/profils_locaux.dart';
import '../../core/appairage/service_enfant.dart';
import '../../core/cache/secure/stockage_securise.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pin_pad.dart';
import 'saisie_code_page.dart';

/// Les moments successifs de `ELV-01`.
enum MomentConnexionEleve {
  /// On regarde ce que cet appareil connait deja.
  chargement,

  /// Aucun profil au depart : la saisie du code vit sur sa propre route
  /// (`/connexion/eleve/code`) et l'ecran y renvoie.
  saisieCode,

  /// Des profils existent : l'eleve choisit le sien.
  choixProfil,

  /// Plus aucun profil apres un retrait : l'ecran le dit et propose un code.
  vide,

  /// Premier usage d'un profil sur cet appareil : il choisit son code.
  creationCode,

  /// Il confirme le code qu'il vient de choisir.
  confirmationCode,

  /// Le profil a deja un code : il le saisit.
  saisieCodePersonnel,

  /// Code bon : la connexion s'ouvre (reseau).
  ouverture,
}

/// `ELV-01` : l'appareil de l'eleve, partage ou non (`/connexion/eleve`).
///
/// **Choix du profil, puis code personnel.** Sur un appareil deja connecte,
/// l'eleve voit les profils que cet appareil connait (grille de deux colonnes
/// de cartes, manifeste section 2, cartes « genre » #11 et avatars du
/// selecteur), touche le sien, puis saisit son code. « Ajouter un profil sur
/// cet appareil » mene a la saisie d'un nouveau code : un deuxieme eleve peut
/// ainsi utiliser la meme tablette (C05 3.1 point 2).
///
/// Le code personnel se cree ici, juste apres la connexion de l'appareil, puis
/// la connexion s'ouvre aussitot (sans le redemander). **Il n'est jamais
/// transmis** (ADR-005) : la comparaison est locale, et
/// `test/appairage/code_local_test.dart` relit cette source pour le verifier.
///
/// Les erreurs du pave sont toutes dites : code faux (sous les pastilles),
/// deux codes differents, appareil retire par le tuteur (le profil est alors
/// oublie sur cet appareil), pas de reseau, trop d'essais, echec general
/// (C05 3.1 point 3). Pendant l'ouverture, le pave est fige et l'attente dite,
/// bornee par [delaiOuverture] : au-dela, le pave et le retour reviennent.
class EleveConnexionPage extends ConsumerStatefulWidget {
  /// Cree l'ecran de connexion de l'eleve.
  const EleveConnexionPage({super.key});

  /// La cle de la carte d'un profil.
  static Key carteKey(String profilId) =>
      ValueKey<String>('eleve-connexion-profil-$profilId');

  /// La cle du message d'erreur du moment courant.
  static const Key messageKey = ValueKey<String>('eleve-connexion-message');

  /// Attente maximale de l'ouverture de la connexion (fonction Edge puis
  /// `verifyOTP`) : au-dela, le pave revient avec le message d'echec.
  static const Duration delaiOuverture = Duration(seconds: 20);

  @override
  ConsumerState<EleveConnexionPage> createState() => _EleveConnexionPageState();
}

class _EleveConnexionPageState extends ConsumerState<EleveConnexionPage> {
  MomentConnexionEleve _moment = MomentConnexionEleve.chargement;
  List<ProfilLocal> _profils = const <ProfilLocal>[];
  ProfilLocal? _choisi;
  String? _premierEssai;
  bool _erreurCode = false;
  String? _message;
  bool _aideOubli = false;

  @override
  void initState() {
    super.initState();
    unawaited(_charger());
  }

  GoRouter? get _routeur => GoRouter.maybeOf(context);

  /// Le profil que la saisie ou le scanner vient de connecter, passe en
  /// `extra` (jamais dans l'adresse). Absent hors de ce parcours.
  ProfilLocal? _profilQuiArrive() {
    try {
      final Object? extra = GoRouterState.of(context).extra;
      return extra is ProfilLocal ? extra : null;
    } on Object {
      return null;
    }
  }

  /// La saisie d'un code, dont le retour revient ici quand des profils
  /// existent (`?depuis=profils`, parametre non sensible).
  void _versSaisie({bool depuisProfils = false}) {
    _routeur?.go(
      depuisProfils
          ? Uri(
              path: Routes.connexionEleveCode,
              queryParameters: <String, String>{'depuis': 'profils'},
            ).toString()
          : Routes.connexionEleveCode,
    );
  }

  /// Les profils par prenom, dans un sens explicite (la base locale n'en
  /// garantit aucun).
  static List<ProfilLocal> _trier(List<ProfilLocal> profils) =>
      <ProfilLocal>[...profils]..sort((ProfilLocal a, ProfilLocal b) {
        final int parPrenom = a.prenom.toLowerCase().compareTo(
          b.prenom.toLowerCase(),
        );
        return parPrenom != 0 ? parPrenom : a.id.compareTo(b.id);
      });

  /// Ce que cet appareil connait deja, quand il sait le dire.
  ///
  /// **Un echec ici ne bloque pas l'entree** : la memoire des profils est un
  /// confort, pas une condition. Sans elle, on demande un code, ce qui est
  /// l'etat d'un appareil jamais connecte (sur le web, la base locale depend
  /// de deux fichiers servis a la racine ; leur absence laissait l'ecran sur
  /// un chargement sans fin).
  Future<void> _charger() async {
    List<ProfilLocal> profils = const <ProfilLocal>[];
    try {
      profils = await ref.read(profilsLocauxProvider).lister();
    } on Object {
      profils = const <ProfilLocal>[];
    }
    if (!mounted) {
      return;
    }

    // Arrivee depuis la saisie ou le scanner (`connecterCetAppareil`) : le
    // jeton est deja range, on passe droit au code personnel de ce profil,
    // meme si la base locale n'a pas pu le retenir.
    final ProfilLocal? arrive = _profilQuiArrive();
    if (arrive != null) {
      if (!profils.any((ProfilLocal p) => p.id == arrive.id)) {
        profils = <ProfilLocal>[...profils, arrive];
      }
      setState(() => _profils = _trier(profils));
      await _choisirProfil(arrive);
      return;
    }

    setState(() {
      _profils = _trier(profils);
      _moment = profils.isEmpty
          ? MomentConnexionEleve.saisieCode
          : MomentConnexionEleve.choixProfil;
    });
    if (profils.isEmpty) {
      _versSaisie();
    }
  }

  Future<void> _choisirProfil(ProfilLocal profil) async {
    String? empreinte;
    try {
      empreinte = await ref
          .read(stockageSecuriseProvider)
          .empreintePin(profil.id);
    } on Object {
      empreinte = null;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _choisi = profil;
      _erreurCode = false;
      _premierEssai = null;
      _message = null;
      _aideOubli = false;
      _moment = empreinte == null
          ? MomentConnexionEleve.creationCode
          : MomentConnexionEleve.saisieCodePersonnel;
    });
  }

  /// Retour au choix des profils (ou a la connexion s'il n'y en a plus).
  void _versChoix({String? message}) {
    setState(() {
      _choisi = null;
      _premierEssai = null;
      _erreurCode = false;
      _aideOubli = false;
      _message = message;
      _moment = _profils.isEmpty
          ? MomentConnexionEleve.vide
          : MomentConnexionEleve.choixProfil;
    });
  }

  void _retour() {
    switch (_moment) {
      case MomentConnexionEleve.creationCode:
      case MomentConnexionEleve.confirmationCode:
      case MomentConnexionEleve.saisieCodePersonnel:
        _versChoix();
      case MomentConnexionEleve.ouverture:
        // L'ouverture est en vol : on ne quitte pas au milieu.
        break;
      case MomentConnexionEleve.chargement:
      case MomentConnexionEleve.saisieCode:
      case MomentConnexionEleve.choixProfil:
      case MomentConnexionEleve.vide:
        _routeur?.go(Routes.connexion);
    }
  }

  Future<void> _creerCode(String saisie) async {
    final ProfilLocal? profil = _choisi;
    if (profil == null) {
      return;
    }
    if (_moment == MomentConnexionEleve.creationCode) {
      setState(() {
        _premierEssai = saisie;
        _message = null;
        _moment = MomentConnexionEleve.confirmationCode;
      });
      return;
    }
    if (_premierEssai != saisie) {
      setState(() {
        _premierEssai = null;
        _message = t.eleveConnexion.pin.different;
        _moment = MomentConnexionEleve.creationCode;
      });
      return;
    }

    // `sceller` produit un sel et une empreinte : le code lui-meme n'est ecrit
    // nulle part, pas meme dans le coffre.
    try {
      await ref
          .read(stockageSecuriseProvider)
          .enregistrerEmpreintePin(profil.id, CodeLocal.sceller(saisie));
    } on Object {
      if (mounted) {
        setState(() {
          _premierEssai = null;
          _message = t.eleveConnexion.pin.echec;
          _moment = MomentConnexionEleve.creationCode;
        });
      }
      return;
    }
    _premierEssai = null;
    // Le code vient d'etre choisi deux fois : la connexion s'ouvre aussitot,
    // sans le redemander.
    await _ouvrir(profil);
  }

  Future<void> _verifierCode(String saisie) async {
    final ProfilLocal? profil = _choisi;
    if (profil == null) {
      return;
    }
    final StockageSecurise coffre = ref.read(stockageSecuriseProvider);
    final String? scelle;
    try {
      scelle = await coffre.empreintePin(profil.id);
    } on Object {
      if (mounted) {
        setState(() => _message = t.eleveConnexion.pin.echec);
      }
      return;
    }

    // La comparaison est LOCALE : aucun appel reseau ne recoit la saisie.
    if (!CodeLocal.correspond(saisie, scelle)) {
      if (mounted) {
        setState(() {
          _erreurCode = true;
          _message = null;
        });
      }
      return;
    }
    await _ouvrir(profil);
  }

  /// Ouvre la connexion par le jeton d'appareil de [profil].
  Future<void> _ouvrir(ProfilLocal profil) async {
    final StockageSecurise coffre = ref.read(stockageSecuriseProvider);
    if (!mounted) {
      return;
    }
    setState(() {
      _erreurCode = false;
      _message = null;
      _moment = MomentConnexionEleve.ouverture;
    });

    // La lecture du coffre peut echouer : le pave revient, avec le message
    // d'echec, au lieu de rester fige sur « Connexion en cours ».
    final String? jeton;
    try {
      jeton = await coffre.jetonAppareil(profil.id);
    } on Object {
      if (mounted) {
        setState(() {
          _moment = MomentConnexionEleve.saisieCodePersonnel;
          _message = t.eleveConnexion.pin.echec;
        });
      }
      return;
    }
    if (jeton == null) {
      // Le jeton n'est plus sur cet appareil (coffre vide, sauvegarde
      // restauree) : rien ne dit que le tuteur l'a retire, l'ecran ne
      // l'affirme donc pas.
      await _oublier(
        profil,
        message: t.eleveConnexion.profils.jetonAbsent(prenom: profil.prenom),
      );
      return;
    }
    try {
      // Borne : sans reponse du serveur, le pave revient avec le message
      // d'echec au lieu d'une attente sans issue.
      await ref
          .read(serviceEnfantProvider)
          .ouvrirSession(jeton)
          .timeout(EleveConnexionPage.delaiOuverture);
      // Succes : le routeur quitte `/connexion` des que la session est la.
    } on Object catch (erreur) {
      final MotifRefusAppairage motif = MotifRefusAppairage.depuis(erreur);
      if (motif == MotifRefusAppairage.revoque) {
        await _oublier(
          profil,
          message: t.eleveConnexion.profils.retire(prenom: profil.prenom),
        );
        return;
      }
      if (!mounted) {
        return;
      }
      final p = t.eleveConnexion.pin;
      setState(() {
        _moment = MomentConnexionEleve.saisieCodePersonnel;
        _message = switch (motif) {
          MotifRefusAppairage.horsLigne => p.horsLigne,
          MotifRefusAppairage.tropDEssais => p.tropDEssais,
          _ => p.echec,
        };
      });
    }
  }

  /// [profil] ne peut plus se connecter depuis cet appareil (le serveur dit
  /// l'appareil retire, ou son jeton n'est plus dans le coffre) : le profil,
  /// son jeton et l'empreinte de son code quittent cet appareil, et l'ecran
  /// dit [message], propre a chaque cause.
  Future<void> _oublier(ProfilLocal profil, {required String message}) async {
    final StockageSecurise coffre = ref.read(stockageSecuriseProvider);
    try {
      await ref.read(profilsLocauxProvider).oublier(profil.id);
      await coffre.oublierAppareil(profil.id);
      await coffre.effacerEmpreintePin(profil.id);
    } on Object {
      // Au pire, le profil reapparaitra et le serveur refusera encore.
    }
    if (!mounted) {
      return;
    }
    _profils = _profils.where((ProfilLocal p) => p.id != profil.id).toList();
    _versChoix(message: message);
  }

  @override
  Widget build(BuildContext context) {
    final ProfilLocal? choisi = _choisi;
    final String? titre = switch (_moment) {
      MomentConnexionEleve.choixProfil => t.eleveConnexion.choisirProfil,
      MomentConnexionEleve.creationCode ||
      MomentConnexionEleve.confirmationCode ||
      MomentConnexionEleve.saisieCodePersonnel ||
      MomentConnexionEleve.ouverture =>
        choisi == null
            ? null
            : t.eleveConnexion.pin.bonjour(prenom: choisi.prenom),
      _ => null,
    };

    final Widget contenu = switch (_moment) {
      MomentConnexionEleve.chargement || MomentConnexionEleve.saisieCode =>
        Center(child: Text(t.commun.chargement)),
      MomentConnexionEleve.choixProfil => _ChoixProfil(
        profils: _profils,
        message: _message,
        onProfil: (ProfilLocal p) => unawaited(_choisirProfil(p)),
        onAjouter: () => _versSaisie(depuisProfils: true),
      ),
      MomentConnexionEleve.vide => EtatSysteme(
        nature: NatureEtat.aucunResultat,
        titre: t.eleveConnexion.profils.videTitre,
        phrase: _message ?? t.eleveConnexion.profils.vide,
        libelleAction: t.eleveConnexion.profils.videAction,
        onAction: _versSaisie,
      ),
      MomentConnexionEleve.creationCode ||
      MomentConnexionEleve.confirmationCode ||
      MomentConnexionEleve.saisieCodePersonnel ||
      MomentConnexionEleve.ouverture => _Pave(
        profil: choisi,
        moment: _moment,
        enErreur: _erreurCode,
        message: _message,
        aideOubli: _aideOubli,
        plusieursProfils: _profils.length > 1,
        onComplet: (String code) => unawaited(
          _moment == MomentConnexionEleve.saisieCodePersonnel
              ? _verifierCode(code)
              : _creerCode(code),
        ),
        onChangerProfil: _versChoix,
        onOubli: () => setState(() => _aideOubli = !_aideOubli),
        // Le nouveau code d'appairage efface l'ancien code personnel
        // (`connecterCetAppareil`) : l'eleve en choisit un nouveau.
        onNouveauCode: () => _versSaisie(depuisProfils: true),
      ),
    };

    // Telephone : a meme la page. Tablette et bureau : le panneau centre
    // commun aux trois taches de l'appareil eleve (saisie, scanner, ici), dont
    // le disque retour et le titre sont alignes sur le panneau (REVUE R-07).
    final bool mobile = AppGabarit.de(context) == Gabarit.mobile;
    final VoidCallback? retour =
        _moment == MomentConnexionEleve.ouverture ? null : _retour;
    if (mobile) {
      return PageShell(titre: titre, onRetour: retour, child: contenu);
    }
    return PageShell(
      child: PanneauAppareilEleve(
        titre: titre,
        onRetour: retour,
        child: contenu,
      ),
    );
  }
}

/// Le message d'erreur du moment, annonce des qu'il apparait.
class _Message extends StatelessWidget {
  const _Message(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      texte,
      key: EleveConnexionPage.messageKey,
      textAlign: TextAlign.center,
      style: AppPalette.of(context).inkAlert
          .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle()),
    ),
  );
}

class _ChoixProfil extends StatelessWidget {
  const _ChoixProfil({
    required this.profils,
    required this.message,
    required this.onProfil,
    required this.onAjouter,
  });

  final List<ProfilLocal> profils;
  final String? message;
  final void Function(ProfilLocal profil) onProfil;
  final VoidCallback onAjouter;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // Deux colonnes, comme les cartes de choix de l'admission ; a 150 % de
    // texte et plus, une seule (repli en pile).
    final bool pile =
        MediaQuery.textScalerOf(context).scale(1) >=
        AppGabarit.seuilTexteColonne;
    final int colonnes = pile ? 1 : 2;

    final List<Widget> rangees = <Widget>[];
    for (int i = 0; i < profils.length; i += colonnes) {
      final List<ProfilLocal> rangee = profils.sublist(
        i,
        i + colonnes > profils.length ? profils.length : i + colonnes,
      );
      rangees.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int j = 0; j < colonnes; j++) ...<Widget>[
                if (j > 0) Ecart.hMd,
                Expanded(
                  child: j < rangee.length
                      ? _CarteProfil(
                          profil: rangee[j],
                          onPress: () => onProfil(rangee[j]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t.eleveConnexion.profils.phrase,
          style: palette.inkMuted.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        Ecart.vXxl,
        for (int i = 0; i < rangees.length; i++) ...<Widget>[
          if (i > 0) Ecart.vMd,
          rangees[i],
        ],
        if (message != null) ...<Widget>[Ecart.vXl, _Message(message!)],
        Ecart.vXxl,
        ActionPrincipale(
          libelle: t.eleveConnexion.profils.ajouter,
          niveau: NiveauAction.secondaire,
          prefixe: Icon(AppIcons.ajouter.repos),
          onPress: onAjouter,
        ),
        Ecart.vSm,
        Text(
          t.eleveConnexion.profils.ajouterLegende,
          textAlign: TextAlign.center,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
      ],
    );
  }
}

/// La carte d'un profil : l'initiale (ou la photo), le prenom, une grande
/// cible.
class _CarteProfil extends StatelessWidget {
  const _CarteProfil({required this.profil, required this.onPress});

  final ProfilLocal profil;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);

    return AppCard(
      key: EleveConnexionPage.carteKey(profil.id),
      onPress: onPress,
      libelleSemantique: t.eleveConnexion.profils.profilLibelle(
        prenom: profil.prenom,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AvatarTile(
            prenom: profil.prenom,
            diametre: metriques.cibleTactile * 2,
          ),
          Ecart.vMd,
          Text(
            profil.prenom,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

class _Pave extends StatelessWidget {
  const _Pave({
    required this.profil,
    required this.moment,
    required this.enErreur,
    required this.message,
    required this.aideOubli,
    required this.plusieursProfils,
    required this.onComplet,
    required this.onChangerProfil,
    required this.onOubli,
    required this.onNouveauCode,
  });

  final ProfilLocal? profil;
  final MomentConnexionEleve moment;
  final bool enErreur;
  final String? message;
  final bool aideOubli;
  final bool plusieursProfils;
  final void Function(String code) onComplet;
  final VoidCallback onChangerProfil;
  final VoidCallback onOubli;
  final VoidCallback onNouveauCode;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final p = t.eleveConnexion.pin;
    final bool ouverture = moment == MomentConnexionEleve.ouverture;
    final String? consigne = switch (moment) {
      MomentConnexionEleve.creationCode => p.creer,
      MomentConnexionEleve.confirmationCode => p.confirmer,
      _ => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (profil != null)
          Center(
            child: AvatarTile(
              prenom: profil!.prenom,
              diametre: AppMetriques.of(context).cibleTactile * 1.5,
            ),
          ),
        // En saisie, le pave porte deja sa consigne parlee (« Entre ton
        // code ») : la repeter au-dessus faisait doublon (planche contre E3).
        if (consigne != null) ...<Widget>[
          Ecart.vLg,
          Text(
            consigne,
            textAlign: TextAlign.center,
            style: palette.inkStrong.applyTo(
              textes.titleLarge ?? const TextStyle(),
            ),
          ),
        ],
        if (moment == MomentConnexionEleve.creationCode) ...<Widget>[
          Ecart.vSm,
          Text(
            p.creerPhrase,
            textAlign: TextAlign.center,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
        if (message != null) ...<Widget>[Ecart.vMd, _Message(message!)],
        Ecart.vXl,
        if (ouverture)
          Semantics(
            liveRegion: true,
            child: Column(
              children: <Widget>[
                const SizedBox.square(
                  dimension: AppSpacing.xxxl,
                  child: CircularProgressIndicator(),
                ),
                Ecart.vMd,
                Text(p.ouverture, textAlign: TextAlign.center),
              ],
            ),
          )
        else
          // Une cle par moment : la confirmation repart d'un pave vide.
          PinPad(
            key: ValueKey<MomentConnexionEleve>(moment),
            onCodeComplet: onComplet,
            enErreur: enErreur,
            longueur: CodeLocal.longueur,
          ),
        if (!ouverture) ...<Widget>[
          Ecart.vXl,
          if (moment == MomentConnexionEleve.saisieCodePersonnel) ...<Widget>[
            ActionPrincipale(
              libelle: p.oublie,
              niveau: NiveauAction.tertiaire,
              onPress: onOubli,
            ),
            if (aideOubli) ...<Widget>[
              Semantics(
                liveRegion: true,
                child: Text(
                  p.oubliePhrase,
                  textAlign: TextAlign.center,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ),
              Ecart.vSm,
              ActionPrincipale(
                libelle: p.oublieAction,
                niveau: NiveauAction.secondaire,
                onPress: onNouveauCode,
              ),
              Ecart.vSm,
            ],
          ],
          if (plusieursProfils)
            ActionPrincipale(
              libelle: p.changerProfil,
              niveau: NiveauAction.tertiaire,
              onPress: onChangerProfil,
            ),
        ],
      ],
    );
  }
}
