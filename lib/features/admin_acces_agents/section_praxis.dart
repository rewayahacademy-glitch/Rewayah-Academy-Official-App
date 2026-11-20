import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/agent/service_praxis.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/texte_protege.dart';
import '../mfa_controleur/double_verification.dart';
import 'choix_conversations_essai.dart';
import 'connexions_praxis.dart';
import 'questions_praxis.dart';

/// Les cles des widgets de la section, pour les tests.
abstract final class ClesPraxis {
  /// La carte des reglages.
  static const Key carteReglages = ValueKey<String>('praxis-carte-reglages');

  /// La carte du formulaire d'emission d'une cle.
  static const Key carteFormulaire = ValueKey<String>(
    'praxis-carte-formulaire',
  );

  /// La carte de la cle emise (le secret, montre une fois).
  static const Key carteCleEmise = ValueKey<String>('praxis-carte-cle-emise');

  /// Vrai pour une des trois cartes de la section (les gardes d'interface).
  static bool estCarte(Widget w) =>
      w is AppCard &&
      (w.key == carteReglages ||
          w.key == carteFormulaire ||
          w.key == carteCleEmise);

  /// Allumer ou eteindre Praxis.
  static const Key interrupteur = ValueKey<String>('praxis-interrupteur');

  /// Autoriser ou retirer le mode autonome.
  static const Key autonome = ValueKey<String>('praxis-autonome');

  /// Le champ du plafond par heure.
  static const Key champPlafond = ValueKey<String>('praxis-plafond-champ');

  /// Fixer le plafond.
  static const Key fixerPlafond = ValueKey<String>('praxis-plafond');

  /// Le dernier tir de la routine (le pouls).
  static const Key pouls = ValueKey<String>('praxis-pouls');

  /// Aucun tir note : la routine n'a pas encore tourne.
  static const Key poulsAucun = ValueKey<String>('praxis-pouls-aucun');

  /// Ouvrir ou fermer les donnees reelles.
  static const Key donneesReelles = ValueKey<String>('praxis-donnees-reelles');

  /// La phrase d'avertissement des donnees reelles.
  static const Key avertissementDonnees = ValueKey<String>(
    'praxis-donnees-avertissement',
  );

  /// Enregistrer les conversations d'essai.
  static const Key fixerEssai = ValueKey<String>('praxis-essai');

  /// Mettre fin au mode essai.
  static const Key finEssai = ValueKey<String>('praxis-essai-fin');

  /// Emettre la cle.
  static const Key emettre = ValueKey<String>('praxis-emettre');

  /// Copier la cle (secret montre une fois).
  static const Key copierCle = ValueKey<String>('praxis-copier-cle');

  /// Copier l'adresse du connecteur.
  static const Key copierAdresse = ValueKey<String>('praxis-copier-adresse');

  /// « J'ai copie la cle ».
  static const Key termine = ValueKey<String>('praxis-termine');

  /// Confirmer la revocation.
  static const Key confirmerRevocation = ValueKey<String>('praxis-revoquer');

  /// « Voir les envois plus anciens ».
  static const Key suiteJournal = ValueKey<String>('praxis-suite');
}

/// `PX-3` : la section « Praxis » de « Acces des agents IA ».
///
/// Quatre blocs : les reglages (allume, autonome, plafond par heure), les cles
/// (emission, liste, revocation), et « Ce que Praxis a envoye ».
///
///   * **les reglages et les cles sont des actions SENSIBLES** (DECISION-
///     FLUIDITE : elles attendent le serveur, avec `ActionPrincipale.enCours`,
///     jamais affichees d'avance) ; chacune exige la double verification : en
///     `aal1`, la feuille du code s'ouvre (ou dit d'activer la double
///     verification et mene a Compte > Securite), puis le geste est rejoue ;
///   * **le secret d'une cle ne s'affiche qu'une fois**, et l'ecran le dit
///     avant : la base n'en garde que l'empreinte ;
///   * **l'etat d'une cle vient de la base**, jamais de l'horloge du poste ;
///   * **le journal ne montre que ce que Praxis a lui-meme ecrit** : jamais le
///     texte d'une famille.
class SectionPraxis extends ConsumerStatefulWidget {
  /// Cree la section.
  const SectionPraxis({super.key});

  @override
  ConsumerState<SectionPraxis> createState() => _SectionPraxisEtat();
}

class _SectionPraxisEtat extends ConsumerState<SectionPraxis> {
  /// Les durees proposees pour une cle. Quatre-vingt-dix jours est le plafond,
  /// et la base le verifie : cette liste est une commodite, pas une borne.
  static const List<int> _durees = <int>[7, 30, 60, 90];

  final TextEditingController _libelle = TextEditingController();
  final TextEditingController _plafond = TextEditingController();
  Set<String> _essaiChoisies = <String>{};

  EtatPraxis? _etat;
  Object? _erreurEtat;
  bool _chargementEtat = true;

  List<LigneJournalPraxis> _lignes = <LigneJournalPraxis>[];
  int? _suite;
  Object? _erreurJournal;
  bool _chargementJournal = true;
  bool _suiteEnCours = false;

  /// Le reglage qui attend le serveur (`actif`, `autonome`, `plafond`).
  String? _reglageEnCours;
  String? _message;
  String? _erreurReglage;
  String? _erreurPlafond;

  UsageClePraxis _usage = UsageClePraxis.chat;
  int _jours = 30;
  String? _erreurFormulaire;
  bool _emission = false;
  String? _erreurEmission;
  ClePraxisEmise? _emise;

  /// La cle d'idempotence de l'emission en cours : la meme a chaque essai.
  String _cleEmission = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    unawaited(_chargerEtat());
    unawaited(_chargerJournal());
  }

  @override
  void dispose() {
    _libelle.dispose();
    _plafond.dispose();
    super.dispose();
  }

  ServicePraxis get _service => ref.read(servicePraxisProvider);

  Future<void> _chargerEtat({bool silencieux = false}) async {
    if (!silencieux) {
      setState(() {
        _chargementEtat = true;
        _erreurEtat = null;
      });
    }
    try {
      final EtatPraxis etat = await _service.etat();
      if (!mounted) {
        return;
      }
      setState(() {
        _etat = etat;
        _erreurEtat = null;
        _chargementEtat = false;
        _plafond.text = '${etat.envoisParHeure}';
        _essaiChoisies = <String>{...etat.essaiFils};
      });
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _erreurEtat = e;
        _chargementEtat = false;
      });
    }
  }

  Future<void> _chargerJournal({bool suite = false}) async {
    setState(() {
      if (suite) {
        _suiteEnCours = true;
      } else {
        _chargementJournal = true;
        _erreurJournal = null;
      }
    });
    try {
      final PageJournalPraxis page = await _service.journal(
        avant: suite ? _suite : null,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _lignes = suite
            ? <LigneJournalPraxis>[..._lignes, ...page.lignes]
            : page.lignes;
        _suite = page.suite;
        _erreurJournal = null;
        _chargementJournal = false;
        _suiteEnCours = false;
      });
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _erreurJournal = e;
        _chargementJournal = false;
        _suiteEnCours = false;
      });
    }
  }

  /// Un reglage : sensible, il attend le serveur, avec la double verification.
  Future<void> _regler(
    String quoi, {
    bool? actif,
    bool? autonome,
    int? envoisParHeure,
    List<String>? essaiFils,
    bool? donneesReelles,
  }) async {
    if (_reglageEnCours != null) {
      return;
    }
    setState(() {
      _reglageEnCours = quoi;
      _message = null;
      _erreurReglage = null;
    });
    String? message;
    String? erreur;
    try {
      await avecDoubleVerification<void>(
        context,
        ref,
        () => donneesReelles != null
            ? _service.reglerDonneesReelles(ouvert: donneesReelles)
            : essaiFils != null
            ? _service.reglerEssai(essaiFils)
            : _service.regler(
                actif: actif,
                autonome: autonome,
                envoisParHeure: envoisParHeure,
              ),
      );
      message = t.admin.praxis.reglageFait;
    } on Object catch (e) {
      erreur = estRefusDeDroit(e)
          ? t.admin.praxis.doubleVerification
          : t.admin.praxis.erreurReglage;
    }
    // Dans tous les cas l'etat est relu : une reponse perdue ne doit pas
    // laisser l'ecran dire autre chose que la base (D5, « non confirme »).
    await _chargerEtat(silencieux: true);
    if (!mounted) {
      return;
    }
    setState(() {
      _reglageEnCours = null;
      _message = message;
      _erreurReglage = erreur;
    });
  }

  Future<void> _fixerPlafond() async {
    final int? valeur = int.tryParse(_plafond.text.trim());
    if (valeur == null || valeur < 1 || valeur > 120) {
      setState(() => _erreurPlafond = t.admin.praxis.plafondInvalide);
      return;
    }
    setState(() => _erreurPlafond = null);
    await _regler('plafond', envoisParHeure: valeur);
  }

  /// Les conversations d'essai : celles qui sont cochees, dix au plus. Une
  /// liste vide met fin au mode essai.
  Future<void> _fixerEssai({bool fin = false}) async {
    final List<String> fils = fin
        ? <String>[]
        : (<String>[..._essaiChoisies]..sort());
    await _regler(fin ? 'essaiFin' : 'essai', essaiFils: fils);
  }

  Future<void> _emettre() async {
    if (_emission) {
      return;
    }
    if (_libelle.text.trim().isEmpty) {
      setState(() => _erreurFormulaire = t.admin.praxis.manqueLibelle);
      return;
    }
    setState(() {
      _emission = true;
      _erreurFormulaire = null;
      _erreurEmission = null;
    });
    try {
      final ClePraxisEmise emise = await avecDoubleVerification<ClePraxisEmise>(
        context,
        ref,
        () => _service.emettre(
          libelle: _libelle.text.trim(),
          usage: _usage,
          expireLe: DateTime.now().add(Duration(days: _jours)),
          cleEmission: _cleEmission,
        ),
      );
      if (emise.secret.isEmpty) {
        // Un rejeu ne remontre jamais le secret : l'emission n'est pas
        // reconstituable, il faut en emettre une nouvelle.
        throw StateError('secret absent');
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _emise = emise;
        _emission = false;
        _libelle.clear();
        _cleEmission = const Uuid().v4();
      });
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _emission = false;
        _erreurEmission = estRefusDeDroit(e)
            ? t.admin.praxis.doubleVerification
            : t.admin.praxis.erreurEmission;
      });
    }
    await _chargerEtat(silencieux: true);
  }

  Future<void> _revoquer(ClePraxis cle) async {
    final String? motif = await AppBottomSheet.ouvrir<String>(
      context,
      titre: t.admin.praxis.revoquerTitre,
      constructeur: (BuildContext contexte) => FeuilleRevocationPraxis(
        onConfirmer: (String m) => Navigator.of(contexte).pop(m),
      ),
    );
    if (motif == null || !mounted) {
      return;
    }
    final String cleRevocation = const Uuid().v4();
    String? message;
    String? erreur;
    try {
      await avecDoubleVerification<bool>(
        context,
        ref,
        () => _service.revoquer(
          id: cle.id,
          motif: motif,
          cleRevocation: cleRevocation,
        ),
      );
      message = t.admin.praxis.revoquee;
    } on Object catch (e) {
      erreur = estRefusDeDroit(e)
          ? t.admin.praxis.doubleVerification
          : t.admin.praxis.erreurRevocation;
    }
    await _chargerEtat(silencieux: true);
    if (!mounted) {
      return;
    }
    setState(() {
      _message = message;
      _erreurReglage = erreur;
    });
  }

  Future<void> _copier(String texte, String confirmation) async {
    await Clipboard.setData(ClipboardData(text: texte));
    if (!mounted) {
      return;
    }
    setState(() => _message = confirmation);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(monHorlogeProvider);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: t.admin.praxis.titre),
        Ecart.vSm,
        Text(t.admin.praxis.intro, style: textes.bodyMedium),
        Ecart.vLg,
        LocalFeedback(message: _message),
        if (_erreurReglage != null) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              _erreurReglage!,
              style: textes.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          Ecart.vLg,
        ],
        _corps(context),
      ],
    );
  }

  Widget _corps(BuildContext context) {
    if (_chargementEtat && _etat == null) {
      return const Skeleton.liste();
    }
    if (_erreurEtat != null && _etat == null) {
      final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
      if (horsLigne) {
        return EtatSansDonnees(
          quoi: t.admin.praxis.horsLigne,
          onAction: () => unawaited(_chargerEtat()),
        );
      }
      return EmptyState(
        message: t.admin.praxis.erreur,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: () => unawaited(_chargerEtat()),
      );
    }
    final EtatPraxis etat = _etat!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _reglages(context, etat),
        Ecart.vXxl,
        // PX-SUIVI : les questions de Praxis a l'equipe, avant les cles.
        const QuestionsPraxis(),
        Ecart.vXxl,
        SectionHeader(
          titre: t.admin.praxis.clesTitre,
          compteur: etat.cles.length,
        ),
        Ecart.vSm,
        Text(
          t.admin.praxis.clesIntro,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Ecart.vLg,
        if (_emise != null)
          _CarteCleEmise(
            emise: _emise!,
            adresse: _service.adresseConnecteur,
            onCopierCle: () =>
                unawaited(_copier(_emise!.secret, t.admin.praxis.cleCopiee)),
            onCopierAdresse: () => unawaited(
              _copier(_service.adresseConnecteur, t.admin.praxis.adresseCopiee),
            ),
            onTermine: () => setState(() => _emise = null),
          )
        else
          _formulaireCle(context),
        Ecart.vLg,
        _listeCles(context, etat),
        Ecart.vXxl,
        // PX-OAUTH 2e : une ligne par connexion d'une application, revocable.
        const ConnexionsPraxis(),
        Ecart.vXxl,
        SectionHeader(titre: t.admin.praxis.journalTitre),
        Ecart.vSm,
        Text(
          t.admin.praxis.journalIntro,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Ecart.vLg,
        _journal(context),
      ],
    );
  }

  Widget _reglages(BuildContext context, EtatPraxis etat) {
    final TextTheme textes = Theme.of(context).textTheme;
    final bool occupe = _reglageEnCours != null;
    return AppCard(
      key: ClesPraxis.carteReglages,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.admin.praxis.reglagesTitre, style: textes.titleMedium),
          Ecart.vLg,
          Row(
            children: <Widget>[
              Expanded(
                child: Text(t.admin.praxis.allume, style: textes.titleSmall),
              ),
              StatusPill(
                libelle: etat.actif
                    ? t.admin.praxis.etatAllume
                    : t.admin.praxis.etatEteint,
                ton: etat.actif ? TonEtat.succes : TonEtat.neutre,
              ),
            ],
          ),
          Ecart.vXs,
          Text(
            etat.actif ? t.admin.praxis.allumeOui : t.admin.praxis.allumeNon,
            style: textes.bodySmall,
          ),
          Ecart.vMd,
          ActionPrincipale(
            key: ClesPraxis.interrupteur,
            libelle: etat.actif
                ? t.admin.praxis.eteindre
                : t.admin.praxis.allumer,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
            enCours: _reglageEnCours == 'actif',
            onPress: occupe
                ? () {}
                : () => unawaited(_regler('actif', actif: !etat.actif)),
          ),
          Ecart.vXxl,
          Text(t.admin.praxis.autonome, style: textes.titleSmall),
          Ecart.vXs,
          Text(
            etat.autonome
                ? t.admin.praxis.autonomeOui
                : t.admin.praxis.autonomeNon,
            style: textes.bodySmall,
          ),
          Ecart.vMd,
          ActionPrincipale(
            key: ClesPraxis.autonome,
            libelle: etat.autonome
                ? t.admin.praxis.reprendreDirige
                : t.admin.praxis.autoriserAutonome,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
            enCours: _reglageEnCours == 'autonome',
            onPress: occupe
                ? () {}
                : () =>
                      unawaited(_regler('autonome', autonome: !etat.autonome)),
          ),
          Ecart.vXxl,
          Text(t.admin.praxis.plafond, style: textes.titleSmall),
          Ecart.vXs,
          Text(
            t.admin.praxis.plafondDetail(nombre: etat.envoisParHeure),
            style: textes.bodySmall,
          ),
          Ecart.vMd,
          ChampEtiquete(
            libelle: t.admin.praxis.plafondChamp,
            controller: _plafond,
            cleChamp: ClesPraxis.champPlafond,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            directionTexte: TextDirection.ltr,
            erreur: _erreurPlafond,
            onChanged: (String _) => setState(() => _erreurPlafond = null),
          ),
          Ecart.vMd,
          ActionPrincipale(
            key: ClesPraxis.fixerPlafond,
            libelle: t.admin.praxis.plafondEnregistrer,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
            enCours: _reglageEnCours == 'plafond',
            onPress: occupe ? () {} : () => unawaited(_fixerPlafond()),
          ),
          Ecart.vXxl,
          Text(t.admin.praxis.routine.titre, style: textes.titleSmall),
          Ecart.vXs,
          if (etat.derniereRoutine case final TirRoutinePraxis tir) ...<Widget>[
            Text(
              key: ClesPraxis.pouls,
              t.admin.praxis.routine.dernier(
                quand: _quand(tir.termineLe),
                issue: switch (tir.issue) {
                  'ok' => t.admin.praxis.routine.issueOk,
                  'rien_a_faire' => t.admin.praxis.routine.issueRien,
                  'erreur' => t.admin.praxis.routine.issueErreur,
                  _ => t.admin.praxis.routine.issueInconnue,
                },
              ),
              style: textes.bodyMedium,
            ),
            Ecart.vXs,
            Text(
              t.admin.praxis.routine.compteurs(
                lus: '${tir.filsLus}',
                envoyes: '${tir.messagesEnvoyes}',
                passes: '${tir.passesEquipe}',
                refus: '${tir.refus}',
              ),
              style: textes.bodySmall,
            ),
            if (tir.note case final String note
                when note.isNotEmpty) ...<Widget>[
              Ecart.vXs,
              Text(note, style: textes.bodySmall),
            ],
          ] else
            Text(
              t.admin.praxis.routine.aucun,
              key: ClesPraxis.poulsAucun,
              style: textes.bodySmall,
            ),
          Ecart.vSm,
          Text(t.admin.praxis.routine.aide, style: textes.bodySmall),
          Ecart.vXxl,
          Text(t.admin.praxis.donnees.titre, style: textes.titleSmall),
          Ecart.vXs,
          Text(
            etat.donneesReelles
                ? t.admin.praxis.donnees.ouvertes
                : t.admin.praxis.donnees.fermees,
            style: textes.bodySmall,
          ),
          Ecart.vSm,
          Text(
            t.admin.praxis.donnees.avertissement,
            key: ClesPraxis.avertissementDonnees,
            style: textes.bodySmall,
          ),
          Ecart.vMd,
          ActionPrincipale(
            key: ClesPraxis.donneesReelles,
            libelle: etat.donneesReelles
                ? t.admin.praxis.donnees.fermer
                : t.admin.praxis.donnees.ouvrir,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
            enCours: _reglageEnCours == 'donnees',
            onPress: occupe
                ? () {}
                : () => unawaited(
                    _regler('donnees', donneesReelles: !etat.donneesReelles),
                  ),
          ),
          Ecart.vXxl,
          Text(t.admin.praxis.essaiTitre, style: textes.titleSmall),
          Ecart.vXs,
          Text(
            etat.essaiFils.isEmpty
                ? t.admin.praxis.essaiVide
                : t.admin.praxis.essaiActif(nombre: etat.essaiFils.length),
            style: textes.bodySmall,
          ),
          Ecart.vMd,
          Text(t.admin.praxis.essaiChamp, style: textes.titleSmall),
          Ecart.vXs,
          Text(t.admin.praxis.essaiAide, style: textes.bodySmall),
          Ecart.vMd,
          ChoixConversationsEssai(
            choisies: _essaiChoisies,
            onChange: (Set<String> v) => setState(() => _essaiChoisies = v),
          ),
          Ecart.vMd,
          ActionPrincipale(
            key: ClesPraxis.fixerEssai,
            libelle: t.admin.praxis.essaiEnregistrer,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
            enCours: _reglageEnCours == 'essai',
            onPress: occupe ? () {} : () => unawaited(_fixerEssai()),
          ),
          if (etat.essaiFils.isNotEmpty) ...<Widget>[
            Ecart.vMd,
            ActionPrincipale(
              key: ClesPraxis.finEssai,
              libelle: t.admin.praxis.essaiFin,
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
              enCours: _reglageEnCours == 'essaiFin',
              onPress: occupe ? () {} : () => unawaited(_fixerEssai(fin: true)),
            ),
          ],
          Ecart.vXxl,
          const _PourraNePourraPas(),
        ],
      ),
    );
  }

  Widget _formulaireCle(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      key: ClesPraxis.carteFormulaire,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ChampEtiquete(
            libelle: t.admin.praxis.cleLibelle,
            controller: _libelle,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            aide: t.admin.praxis.cleLibelleAide,
            indice: t.admin.praxis.cleLibelleExemple,
            onChanged: (String _) => setState(() => _erreurFormulaire = null),
          ),
          Ecart.vXxl,
          Text(t.admin.praxis.cleUsage, style: textes.titleSmall),
          Ecart.vMd,
          // Choix de formulaire, pas un filtre : l'usage de la cle.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              FilterPill(
                libelle: t.admin.praxis.usageChat,
                retenue: _usage == UsageClePraxis.chat,
                onPress: () => setState(() => _usage = UsageClePraxis.chat),
              ),
              FilterPill(
                libelle: t.admin.praxis.usageRoutine,
                retenue: _usage == UsageClePraxis.routine,
                onPress: () => setState(() => _usage = UsageClePraxis.routine),
              ),
            ],
          ),
          Ecart.vXs,
          Text(
            _usage == UsageClePraxis.chat
                ? t.admin.praxis.usageChatDetail
                : t.admin.praxis.usageRoutineDetail,
            style: textes.bodySmall,
          ),
          Ecart.vXxl,
          Text(t.admin.praxis.cleDuree, style: textes.titleSmall),
          Ecart.vMd,
          // Choix de formulaire, pas un filtre : la duree de la cle.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final int j in _durees)
                FilterPill(
                  libelle: t.admin.praxis.dureeJours(nombre: j),
                  retenue: _jours == j,
                  onPress: () => setState(() => _jours = j),
                ),
            ],
          ),
          Ecart.vXs,
          Text(t.admin.praxis.dureePlafond, style: textes.bodySmall),
          Ecart.vXxl,
          if (_erreurFormulaire != null || _erreurEmission != null) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                _erreurFormulaire ?? _erreurEmission!,
                style: textes.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
            Ecart.vMd,
          ],
          ActionPrincipale(
            key: ClesPraxis.emettre,
            libelle: t.admin.praxis.emettre,
            niveau: NiveauAction.secondaire,
            enCours: _emission,
            onPress: () => unawaited(_emettre()),
          ),
        ],
      ),
    );
  }

  Widget _listeCles(BuildContext context, EtatPraxis etat) {
    if (etat.cles.isEmpty) {
      return EmptyState(
        message: t.admin.praxis.cleVide,
        invitation: t.admin.praxis.cleVideDetail,
        icone: AppIcons.rienAAfficher,
        registre: RegistreVide.bonneNouvelle,
      );
    }
    return DataCollection<ClePraxis>(
      // Une section d'une page qui defile deja : la liste est la page.
      defileSeule: false,
      defileAvecLaPage: true,
      lignes: etat.cles,
      colonnes: <ColonneDonnees<ClePraxis>>[
        ColonneDonnees<ClePraxis>(
          titre: t.admin.praxis.colonneCle,
          role: RoleColonne.identifiante,
          flex: 2,
          texte: (ClePraxis c) => '${c.libelle} (${c.prefixe})',
        ),
        ColonneDonnees<ClePraxis>(
          titre: t.admin.praxis.colonneUsage,
          texte: (ClePraxis c) => c.usage == UsageClePraxis.chat
              ? t.admin.praxis.usageChat
              : t.admin.praxis.usageRoutine,
        ),
        ColonneDonnees<ClePraxis>(
          titre: t.admin.praxis.colonneEmise,
          tabulaire: true,
          texte: (ClePraxis c) => _quand(c.emiseLe),
        ),
        ColonneDonnees<ClePraxis>(
          titre: t.admin.praxis.colonneExpire,
          tabulaire: true,
          texte: (ClePraxis c) => _quand(c.expireLe),
        ),
        ColonneDonnees<ClePraxis>(
          titre: t.admin.praxis.colonneUtilisee,
          tabulaire: true,
          texte: (ClePraxis c) => c.derniereUtilisationLe == null
              ? t.admin.praxis.jamaisUtilisee
              : _quand(c.derniereUtilisationLe!),
        ),
        ColonneDonnees<ClePraxis>(
          titre: t.admin.praxis.colonneEtat,
          flex: 2,
          texte: (ClePraxis c) => _nomEtat(c.etat),
          rendu: (BuildContext _, ClePraxis c) =>
              StatusPill(libelle: _nomEtat(c.etat), ton: _tonEtat(c.etat)),
        ),
        // L'action d'une ligne vit dans sa propre colonne (LISTES-1) : un
        // noeud a part du lecteur d'ecran, rendue seulement quand elle peut
        // aboutir (une cle active).
        ColonneDonnees<ClePraxis>(
          titre: t.commun.listes.actions,
          flex: 2,
          action: true,
          texte: (ClePraxis c) =>
              c.etat == EtatClePraxis.active ? t.admin.praxis.revoquer : '',
          rendu: (BuildContext _, ClePraxis c) => c.etat != EtatClePraxis.active
              ? const SizedBox.shrink()
              : ActionPrincipale(
                  libelle: t.admin.praxis.revoquer,
                  niveau: NiveauAction.destructive,
                  compacte: true,
                  pleineLargeur: false,
                  onPress: () => unawaited(_revoquer(c)),
                ),
        ),
      ],
    );
  }

  Widget _journal(BuildContext context) {
    if (_chargementJournal) {
      return const Skeleton.liste();
    }
    if (_erreurJournal != null) {
      return EmptyState(
        message: t.admin.praxis.journalErreur,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: () => unawaited(_chargerJournal()),
      );
    }
    if (_lignes.isEmpty) {
      return EmptyState(
        message: t.admin.praxis.journalVide,
        invitation: t.admin.praxis.journalVideDetail,
        icone: AppIcons.rienAAfficher,
        registre: RegistreVide.bonneNouvelle,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DataCollection<LigneJournalPraxis>(
          defileSeule: false,
          defileAvecLaPage: true,
          lignes: _lignes,
          colonnes: <ColonneDonnees<LigneJournalPraxis>>[
            ColonneDonnees<LigneJournalPraxis>(
              titre: t.admin.praxis.colonneQuand,
              role: RoleColonne.identifiante,
              tabulaire: true,
              texte: (LigneJournalPraxis l) => _quand(l.heure),
            ),
            ColonneDonnees<LigneJournalPraxis>(
              titre: t.admin.praxis.colonneQuoi,
              texte: (LigneJournalPraxis l) => l.annonce
                  ? t.admin.praxis.quoiAnnonce
                  : t.admin.praxis.quoiMessage,
            ),
            ColonneDonnees<LigneJournalPraxis>(
              titre: t.admin.praxis.colonneResultat,
              texte: _resultat,
              rendu: (BuildContext _, LigneJournalPraxis l) => StatusPill(
                libelle: _resultat(l),
                ton: l.envoye ? TonEtat.succes : TonEtat.avertissement,
              ),
            ),
            ColonneDonnees<LigneJournalPraxis>(
              titre: t.admin.praxis.colonneExtrait,
              role: RoleColonne.aPart,
              flex: 3,
              texte: (LigneJournalPraxis l) =>
                  (l.extrait == null || l.extrait!.isEmpty)
                  ? t.admin.praxis.sansTexte
                  : l.extrait!,
            ),
          ],
        ),
        if (_suite != null) ...<Widget>[
          Ecart.vLg,
          _suiteEnCours
              ? const Skeleton.liste(lignes: 2)
              : LienFleche(
                  key: ClesPraxis.suiteJournal,
                  libelle: t.admin.praxis.voirSuite,
                  onPress: () => unawaited(_chargerJournal(suite: true)),
                ),
        ],
      ],
    );
  }

  String _resultat(LigneJournalPraxis l) => l.envoye
      ? t.admin.praxis.envoye
      : t.admin.praxis.refuseCause(cause: _cause(l.issue));

  String _cause(String issue) => switch (issue) {
    'hors_essai' => t.admin.praxis.cause.horsEssai,
    'essai' => t.admin.praxis.cause.essai,
    'plafond_fil' => t.admin.praxis.cause.plafondFil,
    'plafond' => t.admin.praxis.cause.plafond,
    'plafond_annonces' => t.admin.praxis.cause.plafondAnnonces,
    'eteint' => t.admin.praxis.cause.eteint,
    'mineur' => t.admin.praxis.cause.mineur,
    'repris_par_equipe' => t.admin.praxis.cause.reprisParEquipe,
    'hors_academie' => t.admin.praxis.cause.horsAcademie,
    'type_ferme' => t.admin.praxis.cause.typeFerme,
    'cote' => t.admin.praxis.cause.cote,
    'longueur' => t.admin.praxis.cause.longueur,
    'parametre' => t.admin.praxis.cause.parametre,
    'fil_inconnu' => t.admin.praxis.cause.filInconnu,
    'fil_ferme' => t.admin.praxis.cause.filFerme,
    'public' => t.admin.praxis.cause.publicRefuse,
    'cle_refusee' ||
    'cle_revoquee' ||
    'cle_expiree' => t.admin.praxis.cause.cleRefusee,
    'autonome_requis' => t.admin.praxis.cause.autonomeRequis,
    'refusee' => t.admin.praxis.cause.refusee,
    _ => t.admin.praxis.cause.autre,
  };

  String _nomEtat(EtatClePraxis etat) => switch (etat) {
    EtatClePraxis.active => t.admin.praxis.etatActive,
    EtatClePraxis.revoquee => t.admin.praxis.etatRevoquee,
    EtatClePraxis.expiree => t.admin.praxis.etatExpiree,
  };

  TonEtat _tonEtat(EtatClePraxis etat) => switch (etat) {
    EtatClePraxis.active => TonEtat.succes,
    EtatClePraxis.revoquee => TonEtat.alerte,
    EtatClePraxis.expiree => TonEtat.neutre,
  };

  // HEURES-PROFIL H2 : a l'heure du profil.
  String _quand(DateTime instant) {
    final DateTime date = chezMoi(instant);
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')} '
        '${heureChezMoi(instant)}';
  }
}

/// Ce que Praxis fera, et ne fera pas, de rang egal.
class _PourraNePourraPas extends StatelessWidget {
  const _PourraNePourraPas();

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final Widget pourra = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(t.admin.praxis.pourra, style: textes.titleSmall),
        Ecart.vXs,
        Text(t.admin.praxis.pourraDetail, style: textes.bodySmall),
      ],
    );
    final Widget nePourraPas = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(t.admin.praxis.nePourraPas, style: textes.titleSmall),
        Ecart.vXs,
        Text(t.admin.praxis.nePourraPasDetail, style: textes.bodySmall),
      ],
    );
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints contraintes) {
        final bool etroit =
            contraintes.maxWidth <
            480 * MediaQuery.textScalerOf(context).scale(1);
        if (etroit) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[pourra, Ecart.vMd, nePourraPas],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: pourra),
            Ecart.hXl,
            Expanded(child: nePourraPas),
          ],
        );
      },
    );
  }
}

/// Le secret de la cle, montre une seule fois, avec l'adresse du connecteur.
class _CarteCleEmise extends StatelessWidget {
  const _CarteCleEmise({
    required this.emise,
    required this.adresse,
    required this.onCopierCle,
    required this.onCopierAdresse,
    required this.onTermine,
  });

  final ClePraxisEmise emise;
  final String adresse;
  final VoidCallback onCopierCle;
  final VoidCallback onCopierAdresse;
  final VoidCallback onTermine;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      key: ClesPraxis.carteCleEmise,
      contourFort: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(AppIcons.succes.repos),
              Ecart.hSm,
              Text(t.admin.praxis.cleEmise, style: textes.titleMedium),
            ],
          ),
          Ecart.vSm,
          Text(t.admin.praxis.cleEmiseDetail, style: textes.bodySmall),
          Ecart.vLg,
          // Le secret : sa copie passe par le bouton, pas par la selection.
          TexteProtege(
            child: Text(
              emise.secret,
              style: textes.bodySmall,
              textDirection: TextDirection.ltr,
            ),
          ),
          Ecart.vLg,
          ActionPrincipale(
            key: ClesPraxis.copierCle,
            libelle: t.admin.praxis.copierCle,
            niveau: NiveauAction.secondaire,
            onPress: onCopierCle,
          ),
          Ecart.vXxl,
          Text(t.admin.praxis.adresse, style: textes.titleSmall),
          Ecart.vXs,
          Text(t.admin.praxis.adresseDetail, style: textes.bodySmall),
          Ecart.vSm,
          Text(
            adresse,
            style: textes.bodySmall,
            textDirection: TextDirection.ltr,
          ),
          Ecart.vMd,
          ActionPrincipale(
            key: ClesPraxis.copierAdresse,
            libelle: t.admin.praxis.copierAdresse,
            niveau: NiveauAction.secondaire,
            onPress: onCopierAdresse,
          ),
          Ecart.vSm,
          ActionPrincipale(
            key: ClesPraxis.termine,
            libelle: t.admin.praxis.termine,
            niveau: NiveauAction.tertiaire,
            onPress: onTermine,
          ),
        ],
      ),
    );
  }
}

/// La feuille de revocation : le motif est obligatoire. Partagee par la
/// revocation d'une cle et celle d'une connexion (PX-OAUTH 2e) : [detail] et
/// [confirmer] disent de laquelle il s'agit (par defaut, une cle).
class FeuilleRevocationPraxis extends StatefulWidget {
  /// Cree la feuille.
  const FeuilleRevocationPraxis({
    required this.onConfirmer,
    super.key,
    this.detail,
    this.confirmer,
  });

  /// Appelee avec le motif (240 signes au plus).
  final ValueChanged<String> onConfirmer;

  /// Le texte au-dessus du champ ; nul : celui de la revocation d'une cle.
  final String? detail;

  /// Le libelle du bouton ; nul : celui de la revocation d'une cle.
  final String? confirmer;

  @override
  State<FeuilleRevocationPraxis> createState() => _FeuilleRevocationEtat();
}

class _FeuilleRevocationEtat extends State<FeuilleRevocationPraxis> {
  final TextEditingController _motif = TextEditingController();
  String? _erreur;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  void _confirmer() {
    final String motif = _motif.text.trim();
    if (motif.isEmpty) {
      setState(() => _erreur = t.admin.praxis.manqueMotif);
      return;
    }
    widget.onConfirmer(motif.length > 240 ? motif.substring(0, 240) : motif);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          widget.detail ?? t.admin.praxis.revoquerDetail,
          style: textes.bodyMedium,
        ),
        Ecart.vLg,
        ChampEtiquete(
          libelle: t.admin.praxis.revoquerMotif,
          controller: _motif,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 3,
          aide: t.admin.praxis.revoquerMotifAide,
          onChanged: (String _) => setState(() => _erreur = null),
        ),
        if (_erreur != null) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(
              _erreur!,
              style: textes.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
        Ecart.vLg,
        ActionPrincipale(
          key: ClesPraxis.confirmerRevocation,
          libelle: widget.confirmer ?? t.admin.praxis.revoquerConfirmer,
          niveau: NiveauAction.destructive,
          onPress: _confirmer,
        ),
      ],
    );
  }
}
