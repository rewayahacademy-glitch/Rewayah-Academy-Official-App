/// COURRIELS-1 : les e-mails sortants, cote direction.
///
/// Trois sections (`SelecteurSection`) :
///
///   * **Écrire** : un e-mail a la main (adresse, categorie, sujet, message en
///     texte simple). L'e-mail est mis en file ; l'ecran dit « Envoi dans la
///     minute » et **jamais « envoye »** : seul le statut `envoye` de la file
///     le dit. Une cle d'idempotence est tiree pour un contenu donne : un
///     double appui, ou un nouvel essai apres une reponse perdue, ne met
///     jamais deux e-mails en file ; elle change des que le contenu change.
///   * **Envois** : la file, filtree par statut, avec la relance d'un e-mail
///     non envoye ou annule.
///   * **Adresses d'envoi** : les categories et l'alias dont chacune part, en
///     lecture seule.
///
/// Le serveur decide de tout (droits, categories, adresses exclues, bornes) ;
/// l'ecran envoie et affiche. Etats de chaque section : chargement, contenu,
/// vide, erreur, hors ligne (et fonction indisponible tant que le serveur
/// n'est pas branche).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/capacites/port_courriels.dart';
import '../../core/capacites/port_langues_communication.dart';
import '../../core/i18n/dates_appareil.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/bouton_outil.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/selecteur_section.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../salle_seance/information_controle.dart' show coupuresAdresse;

/// Les categories et leurs alias, lus au serveur. Relus a chaque ouverture.
final courrielsCategoriesProvider =
    FutureProvider.autoDispose<List<CategorieCourriel>>(
      (Ref ref) => ref.watch(portCourrielsProvider).categories(),
      retry: (int _, Object _) => null,
    );

/// La file d'envoi, lue au serveur, filtree par [StatutCourriel] (nul : tous).
final courrielsFileProvider = FutureProvider.autoDispose
    .family<List<CourrielSortant>, StatutCourriel?>(
      (Ref ref, StatutCourriel? statut) =>
          ref.watch(portCourrielsProvider).lister(statut: statut),
      retry: (int _, Object _) => null,
    );

/// Les sections de l'ecran.
enum SectionCourriels {
  /// Ecrire un e-mail.
  ecrire,

  /// La file d'envoi.
  file,

  /// Les adresses d'envoi.
  adresses,
}

/// Ce que dit la ligne au-dessus du formulaire apres un envoi.
enum RetourEnvoi {
  /// L'e-mail est en file : il part dans la minute.
  misEnFile,

  /// Le serveur refuse l'adresse.
  adresse,

  /// Le serveur refuse la categorie.
  categorie,

  /// Le serveur refuse le sujet.
  sujet,

  /// Le serveur refuse le message.
  corps,

  /// Le destinataire ne peut pas recevoir cet e-mail.
  destinataireExclu,

  /// Le serveur refuse cette personne.
  refus,

  /// La mise en file n'est pas confirmee.
  echec,

  /// Pas de reseau : rien n'est parti.
  horsLigne,
}

/// Ce que dit la ligne au-dessus de la file apres une relance.
enum RetourRelance {
  /// L'e-mail est remis en file.
  relance,

  /// L'e-mail n'est plus a relancer.
  introuvable,

  /// La relance n'est pas confirmee.
  echec,

  /// Le serveur refuse cette personne.
  refus,

  /// Pas de reseau : rien n'est parti.
  horsLigne,
}

/// L'ecran « E-mails ».
class CourrielsAdminPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const CourrielsAdminPage({super.key, this.genererCle});

  /// Tire la cle d'idempotence (tests) ; par defaut un UUID v4.
  final String Function()? genererCle;

  /// Le choix de la section.
  static const Key sectionsKey = ValueKey<String>('courriels-sections');

  /// La phrase qui dit que chaque destinataire le recoit dans sa langue.
  static const Key traductionKey = ValueKey<String>('courriel-traduction');

  /// Le champ de l'adresse du destinataire.
  static const Key adresseKey = ValueKey<String>('courriel-adresse');

  /// Le choix de la categorie.
  static const Key categorieKey = ValueKey<String>('courriel-categorie');

  /// Le champ du sujet.
  static const Key sujetKey = ValueKey<String>('courriel-sujet');

  /// Le champ du message.
  static const Key corpsKey = ValueKey<String>('courriel-corps');

  /// Le geste « Envoyer l'e-mail ».
  static const Key envoyerKey = ValueKey<String>('courriel-envoyer');

  /// La ligne qui dit ce qu'est devenu le dernier envoi.
  static const Key retourKey = ValueKey<String>('courriel-retour');

  /// « Voir les envois », apres une mise en file.
  static const Key voirKey = ValueKey<String>('courriel-voir');

  /// La ligne qui dit ce qu'est devenue la derniere relance.
  static const Key retourRelanceKey = ValueKey<String>('courriel-relance');

  /// « Actualiser » la file.
  static const Key actualiserKey = ValueKey<String>('courriels-actualiser');

  /// Le filtre « statut » de la file.
  static Key filtreKey(StatutCourriel? s) =>
      ValueKey<String>('courriels-filtre-${s?.name ?? 'tous'}');

  /// La carte de l'e-mail [id].
  static Key carteKey(String id) => ValueKey<String>('courriel-$id');

  /// La ligne « Langue » de l'e-mail [id].
  static Key langueKey(String id) => ValueKey<String>('courriel-langue-$id');

  /// « Remettre en file » l'e-mail [id].
  static Key reessayerKey(String id) =>
      ValueKey<String>('courriel-reessayer-$id');

  /// La carte de la categorie [code].
  static Key categorieCarteKey(String code) =>
      ValueKey<String>('courriel-categorie-$code');

  @override
  ConsumerState<CourrielsAdminPage> createState() => _CourrielsAdminPageState();
}

class _CourrielsAdminPageState extends ConsumerState<CourrielsAdminPage> {
  static final RegExp _adresseValide = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  SectionCourriels _section = SectionCourriels.ecrire;
  StatutCourriel? _filtre;

  final TextEditingController _adresse = TextEditingController();
  final TextEditingController _sujet = TextEditingController();
  final TextEditingController _corps = TextEditingController();
  String? _categorie;
  // Change a chaque envoi reussi : le choix de categorie repart a zero.
  int _remise = 0;
  bool _tente = false;
  bool _envoiEnCours = false;
  RetourEnvoi? _retour;

  String? _relanceEnCours;
  RetourRelance? _retourRelance;

  late String _cle = _nouvelleCle();

  String _nouvelleCle() => (widget.genererCle ?? () => const Uuid().v4())();

  bool get _horsLigne => ref.read(horsLigneProvider).value ?? false;

  @override
  void dispose() {
    _adresse.dispose();
    _sujet.dispose();
    _corps.dispose();
    super.dispose();
  }

  // --- Ecrire -------------------------------------------------------------

  /// Le contenu a change : c'est un autre e-mail, donc une autre cle. Sans
  /// cela, le serveur rendrait la premiere ligne et ignorerait la correction.
  void _contenuChange() => setState(() {
    _cle = _nouvelleCle();
    _retour = null;
  });

  bool get _adresseOk => _adresseValide.hasMatch(_adresse.text.trim());
  bool get _sujetOk {
    final int n = _sujet.text.trim().length;
    return n >= 1 && n <= 120;
  }

  bool get _corpsOk {
    final int n = _corps.text.trim().length;
    return n >= 1 && n <= 5000;
  }

  Future<void> _envoyer() async {
    if (_envoiEnCours) return;
    setState(() {
      _tente = true;
      _retour = null;
    });
    final String? categorie = _categorie;
    if (!_adresseOk || categorie == null || !_sujetOk || !_corpsOk) return;
    if (_horsLigne) {
      setState(() => _retour = RetourEnvoi.horsLigne);
      return;
    }
    // Pose avant tout `await` : un second appui n'envoie rien.
    setState(() => _envoiEnCours = true);
    RetourEnvoi retour;
    try {
      await ref
          .read(portCourrielsProvider)
          .envoyer(
            categorie: categorie,
            sujet: _sujet.text,
            corps: _corps.text,
            cle: _cle,
            adresse: _adresse.text,
          );
      retour = RetourEnvoi.misEnFile;
    } on CourrielInvalide catch (e) {
      retour = switch (e.champ) {
        ChampCourriel.adresse => RetourEnvoi.adresse,
        ChampCourriel.categorie => RetourEnvoi.categorie,
        ChampCourriel.sujet => RetourEnvoi.sujet,
        ChampCourriel.corps => RetourEnvoi.corps,
        ChampCourriel.destinataireExclu => RetourEnvoi.destinataireExclu,
        null => RetourEnvoi.echec,
      };
    } on PermissionInsuffisante {
      retour = RetourEnvoi.refus;
    } on Object {
      // La reponse a pu se perdre apres la mise en file : la file est relue,
      // et la meme cle rend la ligne deja creee si on recommence.
      retour = _horsLigne ? RetourEnvoi.horsLigne : RetourEnvoi.echec;
    }
    ref.invalidate(courrielsFileProvider);
    if (!mounted) return;
    setState(() {
      _envoiEnCours = false;
      _retour = retour;
      if (retour == RetourEnvoi.misEnFile) {
        _adresse.clear();
        _sujet.clear();
        _corps.clear();
        _categorie = null;
        _remise++;
        _tente = false;
        _cle = _nouvelleCle();
      }
    });
  }

  // --- Envois -------------------------------------------------------------

  Future<void> _relancer(CourrielSortant c) async {
    if (_relanceEnCours != null) return;
    if (_horsLigne) {
      setState(() => _retourRelance = RetourRelance.horsLigne);
      return;
    }
    setState(() {
      _relanceEnCours = c.id;
      _retourRelance = null;
    });
    RetourRelance retour;
    try {
      await ref.read(portCourrielsProvider).reessayer(c.id);
      retour = RetourRelance.relance;
    } on CourrielIntrouvable {
      retour = RetourRelance.introuvable;
    } on PermissionInsuffisante {
      retour = RetourRelance.refus;
    } on Object {
      retour = _horsLigne ? RetourRelance.horsLigne : RetourRelance.echec;
    }
    // Dans tous les cas la file est relue : une relance dont la reponse s'est
    // perdue doit y apparaitre.
    ref.invalidate(courrielsFileProvider);
    if (!mounted) return;
    setState(() {
      _relanceEnCours = null;
      _retourRelance = retour;
    });
  }

  // --- Rendu --------------------------------------------------------------

  Widget _ligneRetour(Key cle, String message, {required bool bon}) {
    final AppPalette palette = AppPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Text(
          message,
          key: cle,
          style: (bon ? palette.inkStrong : palette.inkAlert).applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
      ),
    );
  }

  Widget _erreurChamp(String message) {
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          style: palette.inkAlert.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
      ),
    );
  }

  Widget? _etatErreur(
    Object e,
    VoidCallback? reessayer, {
    required String cle,
    required String erreur,
    required String sansDonnees,
  }) {
    final a = t.courriels.admin;
    if (e is CapaciteIndisponible) {
      return EtatSysteme(
        key: ValueKey<String>('$cle-indisponible'),
        nature: NatureEtat.indisponible,
        titre: a.indisponibleTitre,
        phrase: a.indisponiblePhrase,
        dependance: e.dependance,
      );
    }
    if (e is PermissionInsuffisante) {
      return EtatSysteme(
        key: ValueKey<String>('$cle-refuse'),
        nature: NatureEtat.echecServeur,
        phrase: a.refuse,
      );
    }
    return _horsLigne
        ? EtatSansDonnees(
            key: ValueKey<String>('$cle-sans-donnees'),
            quoi: sansDonnees,
            onAction: reessayer,
          )
        : EtatSysteme(
            key: ValueKey<String>('$cle-erreur'),
            nature: NatureEtat.echecServeur,
            phrase: erreur,
            onAction: reessayer,
          );
  }

  @override
  Widget build(BuildContext context) {
    final a = t.courriels.admin;
    // Suit le reseau pour que l'etat « sans donnees » se redessine.
    ref.watch(horsLigneProvider);
    return PageShell(
      titre: a.titre,
      sousTitre: a.sousTitre,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SelecteurSection<SectionCourriels>(
                key: CourrielsAdminPage.sectionsKey,
                libelle: a.sections.libelle,
                valeur: _section,
                sections: <Segment<SectionCourriels>>[
                  Segment<SectionCourriels>(
                    valeur: SectionCourriels.ecrire,
                    libelle: a.sections.ecrire,
                  ),
                  Segment<SectionCourriels>(
                    valeur: SectionCourriels.file,
                    libelle: a.sections.file,
                  ),
                  Segment<SectionCourriels>(
                    valeur: SectionCourriels.adresses,
                    libelle: a.sections.adresses,
                  ),
                ],
                onChange: (SectionCourriels s) => setState(() => _section = s),
              ),
              Ecart.vXl,
              switch (_section) {
                SectionCourriels.ecrire => _sectionEcrire(),
                SectionCourriels.file => _sectionFile(),
                SectionCourriels.adresses => _sectionAdresses(),
              },
            ],
          ),
        ),
      ),
    );
  }

  // --- Section Ecrire -----------------------------------------------------

  String _messageEnvoi(RetourEnvoi r) {
    final e = t.courriels.admin.ecrire;
    return switch (r) {
      RetourEnvoi.misEnFile => e.retour.misEnFile,
      RetourEnvoi.adresse => e.champ.adresse,
      RetourEnvoi.categorie => e.champ.categorie,
      RetourEnvoi.sujet => e.champ.sujet,
      RetourEnvoi.corps => e.champ.corps,
      RetourEnvoi.destinataireExclu => e.champ.destinataireExclu,
      RetourEnvoi.refus => e.retour.refus,
      RetourEnvoi.echec => e.retour.echec,
      RetourEnvoi.horsLigne => e.retour.horsLigne,
    };
  }

  Widget _sectionEcrire() {
    final e = t.courriels.admin.ecrire;
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<CategorieCourriel>> valeur = ref.watch(
      courrielsCategoriesProvider,
    );
    final RetourEnvoi? retour = _retour;
    return AppCard(
      entete: Semantics(
        header: true,
        child: Text(e.titre, style: textes.titleMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(e.intro, style: textes.bodyMedium),
          Ecart.vSm,
          Text(
            e.traduction,
            key: CourrielsAdminPage.traductionKey,
            style: textes.bodyMedium,
          ),
          Ecart.vLg,
          ChampEtiquete(
            key: CourrielsAdminPage.adresseKey,
            libelle: e.adresse,
            aide: e.adresseAide,
            controller: _adresse,
            keyboardType: TextInputType.emailAddress,
            obligatoire: true,
            onChanged: (String _) => _contenuChange(),
          ),
          if (_tente && !_adresseOk) _erreurChamp(e.champ.adresse),
          Ecart.vLg,
          Text(e.categorie, style: textes.labelLarge),
          Ecart.vXs,
          Text(e.categorieAide, style: textes.bodySmall),
          Ecart.vSm,
          BlocAsynchrone<List<CategorieCourriel>>(
            key: const ValueKey<String>('courriel-categories-bloc'),
            valeur: valeur,
            squelette: const Skeleton.liste(lignes: 3),
            onReessayer: () => ref.invalidate(courrielsCategoriesProvider),
            vide: Text(
              e.pasDeCategorie,
              key: const ValueKey<String>('courriel-categories-vide'),
              style: textes.bodyMedium,
            ),
            estVide: (List<CategorieCourriel> l) =>
                !l.any((CategorieCourriel c) => c.active),
            erreurVersEtat: (Object err, VoidCallback? reessayer) =>
                _etatErreur(
                  err,
                  reessayer,
                  cle: 'courriel-categories',
                  erreur: e.erreurCategories,
                  sansDonnees: e.sansDonneesCategories,
                ),
            construire: (List<CategorieCourriel> lues) => ChoiceCardGroup(
              key: ValueKey<String>('categories-$_remise'),
              autoriserSaisieLibre: false,
              options: <OptionChoix>[
                for (final CategorieCourriel c in lues)
                  if (c.active)
                    OptionChoix(
                      cle: CourrielsAdminPage.categorieCarteKey(c.code),
                      valeur: c.code,
                      libelle: c.libelle,
                      description: e.partDe(
                        adresse: coupuresAdresse(c.expediteurAdresse),
                      ),
                      explication: c.essentielle ? null : e.desinscription,
                    ),
              ],
              onChange: (ReponseChoix r) {
                _categorie = r.valeurs.isEmpty ? null : r.valeurs.first;
                _contenuChange();
              },
            ),
          ),
          if (_tente && _categorie == null) _erreurChamp(e.champ.categorie),
          Ecart.vLg,
          ChampEtiquete(
            key: CourrielsAdminPage.sujetKey,
            libelle: e.sujet,
            aide: e.sujetAide,
            controller: _sujet,
            obligatoire: true,
            onChanged: (String _) => _contenuChange(),
          ),
          if (_tente && !_sujetOk) _erreurChamp(e.champ.sujet),
          Ecart.vLg,
          ChampEtiquete(
            key: CourrielsAdminPage.corpsKey,
            libelle: e.corps,
            aide: e.corpsAide,
            controller: _corps,
            maxLines: 8,
            obligatoire: true,
            onChanged: (String _) => _contenuChange(),
          ),
          if (_tente && !_corpsOk) _erreurChamp(e.champ.corps),
          Ecart.vLg,
          if (retour != null) ...<Widget>[
            _ligneRetour(
              CourrielsAdminPage.retourKey,
              _messageEnvoi(retour),
              bon: retour == RetourEnvoi.misEnFile,
            ),
            if (retour == RetourEnvoi.misEnFile) ...<Widget>[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: LienFleche(
                  key: CourrielsAdminPage.voirKey,
                  libelle: e.retour.voir,
                  onPress: () =>
                      setState(() => _section = SectionCourriels.file),
                ),
              ),
              Ecart.vLg,
            ],
          ],
          ActionPrincipale(
            key: CourrielsAdminPage.envoyerKey,
            libelle: e.envoyer,
            enCours: _envoiEnCours,
            onPress: () => unawaited(_envoyer()),
          ),
        ],
      ),
    );
  }

  // --- Section Envois -----------------------------------------------------

  String _messageRelance(RetourRelance r) {
    final f = t.courriels.admin.file.retour;
    return switch (r) {
      RetourRelance.relance => f.relance,
      RetourRelance.introuvable => f.introuvable,
      RetourRelance.echec => f.echec,
      RetourRelance.refus => f.refus,
      RetourRelance.horsLigne => f.horsLigne,
    };
  }

  Widget _sectionFile() {
    final f = t.courriels.admin.file;
    final AsyncValue<List<CourrielSortant>> valeur = ref.watch(
      courrielsFileProvider(_filtre),
    );
    final RetourRelance? retour = _retourRelance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RangeeFiltres(
          replier: false,
          filtres: <Widget>[
            for (final (StatutCourriel? s, String libelle)
                in <(StatutCourriel?, String)>[
                  (null, f.filtre.tous),
                  (StatutCourriel.enAttente, f.filtre.enAttente),
                  (StatutCourriel.envoi, f.filtre.envoi),
                  (StatutCourriel.envoye, f.filtre.envoye),
                  (StatutCourriel.echec, f.filtre.echec),
                  (StatutCourriel.annule, f.filtre.annule),
                ])
              FilterPill(
                key: CourrielsAdminPage.filtreKey(s),
                libelle: libelle,
                retenue: _filtre == s,
                onPress: () => setState(() => _filtre = s),
              ),
          ],
        ),
        Ecart.vSm,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: BoutonOutil(
            key: CourrielsAdminPage.actualiserKey,
            icone: AppIcons.reconnexion,
            libelle: f.actualiser,
            avecLibelle: true,
            onPress: () => ref.invalidate(courrielsFileProvider),
          ),
        ),
        Ecart.vLg,
        if (retour != null)
          _ligneRetour(
            CourrielsAdminPage.retourRelanceKey,
            _messageRelance(retour),
            bon: retour == RetourRelance.relance,
          ),
        BlocAsynchrone<List<CourrielSortant>>(
          key: const ValueKey<String>('courriels-file-bloc'),
          valeur: valeur,
          squelette: const Skeleton.liste(lignes: 3),
          onReessayer: () => ref.invalidate(courrielsFileProvider),
          vide: EmptyState(
            key: const ValueKey<String>('courriels-file-vide'),
            message: f.vide,
            icone: AppIcons.rienAAfficher,
            registre: RegistreVide.subi,
          ),
          erreurVersEtat: (Object e, VoidCallback? reessayer) => _etatErreur(
            e,
            reessayer,
            cle: 'courriels-file',
            erreur: f.erreur,
            sansDonnees: f.sansDonnees,
          ),
          construire: (List<CourrielSortant> lus) {
            final Map<String, String> libelles = <String, String>{
              for (final CategorieCourriel c
                  in ref.watch(courrielsCategoriesProvider).value ??
                      const <CategorieCourriel>[])
                c.code: c.libelle,
            };
            // Le nom de la langue vient du serveur ; a defaut (liste absente
            // ou en cours de lecture), le code lui-meme.
            final Map<String, String> langues = <String, String>{
              for (final LangueCommunication x
                  in ref.watch(languesCommunicationProvider).value?.langues ??
                      const <LangueCommunication>[])
                x.code: x.libelle,
            };
            return PileCartes(
              key: const ValueKey<String>('courriels-file-contenu'),
              children: <Widget>[
                for (final CourrielSortant x in lus)
                  _CarteCourriel(
                    courriel: x,
                    libelleCategorie: libelles[x.categorie] ?? x.categorie,
                    libelleLangue: langues[x.langue] ?? x.langue,
                    enCours: _relanceEnCours == x.id,
                    occupe: _relanceEnCours != null,
                    onReessayer: () => unawaited(_relancer(x)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // --- Section Adresses d'envoi ------------------------------------------

  Widget _sectionAdresses() {
    final d = t.courriels.admin.adresses;
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<CategorieCourriel>> valeur = ref.watch(
      courrielsCategoriesProvider,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(d.intro, style: textes.bodyMedium),
        Ecart.vLg,
        BlocAsynchrone<List<CategorieCourriel>>(
          key: const ValueKey<String>('courriels-adresses-bloc'),
          valeur: valeur,
          squelette: const Skeleton.liste(lignes: 3),
          onReessayer: () => ref.invalidate(courrielsCategoriesProvider),
          vide: EmptyState(
            key: const ValueKey<String>('courriels-adresses-vide'),
            message: d.vide,
            icone: AppIcons.rienAAfficher,
            registre: RegistreVide.subi,
          ),
          erreurVersEtat: (Object e, VoidCallback? reessayer) => _etatErreur(
            e,
            reessayer,
            cle: 'courriels-adresses',
            erreur: d.erreur,
            sansDonnees: d.sansDonnees,
          ),
          construire: (List<CategorieCourriel> lues) => PileCartes(
            key: const ValueKey<String>('courriels-adresses-contenu'),
            children: <Widget>[
              for (final CategorieCourriel c in lues)
                _CarteCategorie(categorie: c),
            ],
          ),
        ),
      ],
    );
  }
}

String _dateHeure(DateTime d) =>
    '${dateDeLAppareil(d)} · ${heureDeLAppareil(d)}';

class _CarteCourriel extends StatelessWidget {
  const _CarteCourriel({
    required this.courriel,
    required this.libelleCategorie,
    required this.libelleLangue,
    required this.enCours,
    required this.occupe,
    required this.onReessayer,
  });

  final CourrielSortant courriel;
  final String libelleCategorie;
  final String libelleLangue;
  final bool enCours;
  final bool occupe;
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    final f = t.courriels.admin.file;
    final CourrielSortant x = courriel;
    final TextTheme textes = Theme.of(context).textTheme;
    final String? sujet = x.sujet;
    final String? erreur = x.derniereErreur;
    final DateTime? envoye = x.envoyeLe;
    return AppCard(
      key: CourrielsAdminPage.carteKey(x.id),
      entete: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.start,
        spacing: AppSpacing.sm,
        overflowSpacing: AppSpacing.sm,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              sujet != null && sujet.trim().isNotEmpty
                  ? isolerSens(sujet.trim())
                  : f.messageAuto,
              style: textes.titleMedium,
            ),
          ),
          switch (x.statut) {
            StatutCourriel.enAttente => StatusPill(
              libelle: f.statut.enAttente,
              ton: TonEtat.neutre,
            ),
            StatutCourriel.envoi => StatusPill(
              libelle: f.statut.envoi,
              ton: TonEtat.accent,
            ),
            StatutCourriel.envoye => StatusPill(
              libelle: f.statut.envoye,
              ton: TonEtat.succes,
            ),
            StatutCourriel.echec => StatusPill(
              libelle: f.statut.echec,
              ton: TonEtat.avertissement,
            ),
            StatutCourriel.annule => StatusPill(
              libelle: f.statut.annule,
              ton: TonEtat.neutre,
            ),
          },
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LigneCleValeur(
            cle: f.champs.destinataire,
            valeur: isolerSens(x.destinataire),
          ),
          Ecart.vSm,
          LigneCleValeur(
            cle: f.champs.categorie,
            valeur: isolerSens(libelleCategorie),
          ),
          Ecart.vSm,
          LigneCleValeur(
            key: CourrielsAdminPage.langueKey(x.id),
            cle: f.champs.langue,
            valeur: isolerSens(libelleLangue),
          ),
          Ecart.vSm,
          LigneCleValeur(
            cle: f.champs.origine,
            valeur: switch (x.origine) {
              OrigineCourriel.auto => f.origine.auto,
              OrigineCourriel.manuel => f.origine.manuel,
            },
          ),
          Ecart.vSm,
          LigneCleValeur(cle: f.champs.creeLe, valeur: _dateHeure(x.creeLe)),
          if (envoye != null) ...<Widget>[
            Ecart.vSm,
            LigneCleValeur(cle: f.champs.envoyeLe, valeur: _dateHeure(envoye)),
          ],
          if (x.tentatives > 0) ...<Widget>[
            Ecart.vSm,
            LigneCleValeur(
              cle: f.champs.tentatives,
              valeur: '${x.tentatives}',
              chiffres: true,
            ),
          ],
          if (erreur != null && erreur.trim().isNotEmpty) ...<Widget>[
            Ecart.vSm,
            LigneCleValeur(
              cle: f.champs.motifEchec,
              valeur: isolerSens(erreur.trim()),
            ),
          ],
          if (x.statut.peutReessayer && (enCours || !occupe)) ...<Widget>[
            Ecart.vLg,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ActionPrincipale(
                key: CourrielsAdminPage.reessayerKey(x.id),
                libelle: f.reessayer,
                niveau: NiveauAction.secondaire,
                pleineLargeur: false,
                enCours: enCours,
                onPress: enCours ? null : onReessayer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CarteCategorie extends StatelessWidget {
  const _CarteCategorie({required this.categorie});

  final CategorieCourriel categorie;

  @override
  Widget build(BuildContext context) {
    final d = t.courriels.admin.adresses;
    final CategorieCourriel c = categorie;
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      key: CourrielsAdminPage.categorieCarteKey(c.code),
      entete: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.start,
        spacing: AppSpacing.sm,
        overflowSpacing: AppSpacing.sm,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(isolerSens(c.libelle), style: textes.titleMedium),
          ),
          StatusPill(
            libelle: c.active ? d.active : d.coupee,
            ton: c.active ? TonEtat.succes : TonEtat.neutre,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LigneCleValeur(
            cle: d.champs.expediteur,
            valeur: isolerSens(c.expediteurAdresse),
          ),
          Ecart.vSm,
          LigneCleValeur(
            cle: d.champs.nom,
            valeur: isolerSens(c.expediteurNom),
          ),
          Ecart.vSm,
          LigneCleValeur(
            cle: d.champs.reponses,
            valeur: isolerSens(c.repondreA),
          ),
          Ecart.vSm,
          LigneCleValeur(
            cle: d.champs.type,
            valeur: c.essentielle ? d.essentielle : d.facultative,
          ),
        ],
      ),
    );
  }
}
