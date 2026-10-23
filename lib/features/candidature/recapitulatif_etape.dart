// La derniere etape du parcours (CAND-01) : le recapitulatif en cartes (chaque
// reponse se touche pour la changer), puis la carte des conditions de
// remuneration en pourcentage et sa case, puis « Envoyer ma candidature ».
//
// Les conditions viennent a la FIN, juste avant l'envoi (decision du directeur,
// `PROPOSITION_REPARTITION_PAIEMENT.md` section 2) : la part de l'enseignant
// est lue au serveur, jamais ecrite ici, et aucun montant n'est affiche
// (decision du 22/10). Le succes ne se dit qu'apres la reponse du serveur.
//
// Le bouton plein n'est rendu que s'il peut aboutir : cadre religieux et
// pedagogique publie et accepte, conditions lues, reseau present. Sinon une
// phrase dit pourquoi, et il n'est pas grise.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/candidature/disponibilites_declarees.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/port_ma_candidature.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/grille_bento.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../consentements/texte_observation.dart' show CaseAccordTexte;
import 'controleur_parcours.dart';
import 'coquille_parcours.dart';
import 'disponibilites_etape.dart' show listeDeJours;
import 'libelles_parcours.dart';
import 'modele_questions.dart';

/// La part de l'enseignant, en pourcentage, comme le serveur la rend : 470 pour
/// mille s'ecrit « 47 % ». Une mise en forme, pas un calcul.
String partEnPourcent(int pourMille) {
  final bool entier = pourMille % 10 == 0;
  final String nombre = entier
      ? '${pourMille ~/ 10}'
      : (pourMille / 10).toStringAsFixed(1).replaceAll('.', ',');
  final bool arabe = LocaleSettings.currentLocale == AppLocale.ar;
  // Le signe reste colle au nombre : espace insecable en francais.
  return arabe ? isolerSens('$nombre%') : '$nombre %';
}

/// Le nom d'une carte du questionnaire (un theme), ou `null` si elle est
/// inconnue de cette version.
String? titreCarte(String carte) => switch (carte) {
  'langues' => t.recrutement.questionnaire.langues,
  'recitation' => t.recrutement.questionnaire.recitation,
  'disponibilites' => t.recrutement.questionnaire.disponibilites,
  'publics' => t.recrutement.questionnaire.publics,
  'versement' => t.recrutement.questionnaire.versement,
  _ => null,
};

/// Ce que la personne a repondu au champ [champ], en mots ; `null` quand rien
/// ne s'affiche. [nomsOperateurs] donne le nom des operateurs du pays.
String? resumeReponse(
  ChampQuestionnaire champ,
  Object? reponse, {
  Map<String, String> nomsOperateurs = const <String, String>{},
  int dureeMinutes = dureeSeanceEnfantMinutes,
}) {
  final ModeleQuestion? modele = modelesQuestions[champ.code];
  if (modele == null || reponse == null) {
    return null;
  }
  String? option(String code) => textesOption(champ.code, code)?.libelle;
  List<String> codes() => <String>[
    if (reponse is String) reponse,
    if (reponse is List)
      for (final Object? x in reponse)
        if (x is String) x,
  ];
  switch (modele.forme) {
    case FormeQuestion.choix || FormeQuestion.choixMultiple:
      final List<String> noms = <String>[
        for (final String c in codes())
          if (option(c) case final String nom) nom,
      ];
      return noms.isEmpty ? null : noms.join(', ');
    case FormeQuestion.ouiNon:
      return reponse is bool
          ? (reponse ? t.recrutement.parcours.oui : t.recrutement.parcours.non)
          : null;
    case FormeQuestion.langue || FormeQuestion.langues:
      final List<String> noms = <String>[
        for (final String c in codes())
          if (nomDeLangue(c) case final String nom) nom,
      ];
      return noms.isEmpty ? null : noms.join(', ');
    case FormeQuestion.pays:
      return codes().isEmpty ? null : nomDePaysConnu(codes().first);
    case FormeQuestion.riwayat:
      final List<String> noms = <String>[
        for (final String c in codes())
          if (option(c) case final String nom) nom,
      ];
      return noms.isEmpty ? null : noms.join(', ');
    case FormeQuestion.creneaux:
      final int n = DisponibilitesDeclarees.depuisPlages(
        reponse,
        dureeMinutes: dureeMinutes,
      ).jours.length;
      return n == 0 ? null : t.recrutement.parcours.recap.jours(n: n);
    case FormeQuestion.fuseau:
      return codes().isEmpty ? null : nomDeLieu(codes().first);
    case FormeQuestion.operateurs:
      final List<String> noms = <String>[
        for (final String c in codes())
          if (nomsOperateurs[c] case final String nom) nom,
      ];
      return noms.isEmpty ? null : noms.join(', ');
    case FormeQuestion.classes:
      final int? n = codes().isEmpty ? null : int.tryParse(codes().first);
      return n == null ? null : t.recrutement.parcours.classes.libelle(n: n);
    case FormeQuestion.moyensAccessibles:
      final List<String> noms = <String>[
        for (final String c in codes())
          for (final OptionQuestionnaire o in champ.options)
            if (o.code == c && o.nom != null) o.nom!,
      ];
      return noms.isEmpty ? null : noms.join(', ');
  }
}

/// Les jours des disponibilites, reunis quand ils ont les memes heures de debut :
/// « Lundi, mercredi et vendredi » avec « 18 h, 19 h ». Vide pour toute autre
/// reponse. Chaque groupe est une ligne du recapitulatif, jamais un long texte
/// a retour a la ligne.
List<({String jours, String heures})> groupesDeJours(
  ChampQuestionnaire champ,
  Object? reponse, {
  int dureeMinutes = dureeSeanceEnfantMinutes,
}) {
  if (modelesQuestions[champ.code]?.forme != FormeQuestion.creneaux) {
    return const <({String jours, String heures})>[];
  }
  final DisponibilitesDeclarees dispo = DisponibilitesDeclarees.depuisPlages(
    reponse,
    dureeMinutes: dureeMinutes,
  );
  final Map<String, List<int>> parHeures = <String, List<int>>{};
  for (final int jour in dispo.jours) {
    (parHeures[libelleHeures(dispo.debuts(jour))] ??= <int>[]).add(jour);
  }
  return <({String jours, String heures})>[
    for (final MapEntry<String, List<int>> e in parHeures.entries)
      (jours: _nomsDeJours(e.value), heures: e.key),
  ];
}

/// « Lundi, mercredi et vendredi » : les noms des jours, le premier avec sa
/// majuscule.
String _nomsDeJours(List<int> jours) {
  final String liste = listeDeJours(jours);
  return liste.isEmpty ? liste : liste[0].toUpperCase() + liste.substring(1);
}

/// Les cartes du recapitulatif : un groupe de lignes par theme du
/// questionnaire. [onModifier] nul : lecture seule, les lignes ne se touchent
/// pas.
class CartesRecapitulatif extends ConsumerWidget {
  /// Cree les cartes.
  const CartesRecapitulatif({
    required this.questionnaire,
    required this.reponses,
    this.onModifier,
    super.key,
  });

  /// Le questionnaire.
  final Questionnaire questionnaire;

  /// Les reponses, par code de champ.
  final Map<String, Object?> reponses;

  /// Va modifier la reponse du champ.
  final ValueChanged<String>? onModifier;

  /// La cle d'une ligne de reponse.
  static Key ligneKey(String code) => ValueKey<String>('recap-$code');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Object? pays = reponses['paysVersement'];
    final Map<String, String> noms = <String, String>{
      if (pays is String)
        for (final OperateurPaiement o
            in ref.watch(moyensConfirmesProvider(pays)).value?.operateurs ??
                const <OperateurPaiement>[])
          o.code: o.nom,
    };
    final TextTheme textes = Theme.of(context).textTheme;
    final List<Widget> blocs = <Widget>[];
    for (final String carte in questionnaire.cartes) {
      final String? titre = titreCarte(carte);
      final List<Widget> lignes = <Widget>[];
      for (final ChampQuestionnaire c in questionnaire.champs) {
        if (c.carte == carte) {
          lignes.addAll(_lignes(c, noms));
        }
      }
      if (titre == null || lignes.isEmpty) {
        continue;
      }
      blocs.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(titre, style: textes.titleMedium),
            ),
            Ecart.vSm,
            CarteLignes(lignes: lignes),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        if (c.maxWidth < GrilleBento.seuilQuatreColonnes) {
          return PileCartes(children: blocs);
        }
        // Tablette et bureau : une grille Bento, jamais les cartes du
        // telephone etirees. Les themes les plus longs prennent le plus de
        // place.
        return GrilleBento(
          hauteurContenu: true,
          tuiles: <TuileBento>[
            for (final (int i, Widget b) in blocs.indexed)
              TuileBento(
                etendue: EtendueBento.large,
                etendueLarge: i == 1 || i == 2
                    ? EtendueBento.large
                    : EtendueBento.grande,
                child: b,
              ),
          ],
        );
      },
    );
  }

  List<Widget> _lignes(ChampQuestionnaire champ, Map<String, String> noms) {
    final String? nom = nomCourtQuestion(champ.code);
    final int duree = dureeDeclareeDe(reponses['publics']);
    final String? valeur = resumeReponse(
      champ,
      reponses[champ.code],
      nomsOperateurs: noms,
      dureeMinutes: duree,
    );
    final List<({String jours, String heures})> groupes = groupesDeJours(
      champ,
      reponses[champ.code],
      dureeMinutes: duree,
    );
    if (nom == null) {
      return const <Widget>[];
    }
    // Un champ facultatif sans reponse se dit « Aucune » ; un champ requis
    // sans reponse ne s'affiche pas ici (le parcours ne le laisse pas passer).
    final String? affiche =
        valeur ?? (champ.requis ? null : t.recrutement.parcours.aucune);
    if (affiche == null) {
      return const <Widget>[];
    }
    final ValueChanged<String>? modifier = onModifier;
    // En lecture seule, la ligne dit la reponse et ne se touche pas.
    VoidCallback? appui() =>
        modifier == null ? null : () => modifier(champ.code);
    return <Widget>[
      SettingRow(
        key: ligneKey(champ.code),
        title: nom,
        value: affiche,
        lien: modifier != null,
        onPress: appui(),
      ),
      // Les disponibilites : une ligne par groupe de jours, ses heures dessous.
      for (final (int i, ({String jours, String heures}) g) in groupes.indexed)
        SettingRow(
          key: ValueKey<String>('recap-${champ.code}-$i'),
          title: g.jours,
          description: t.recrutement.parcours.creneaux.debutsDuJour(
            heures: g.heures,
          ),
          lien: modifier != null,
          onPress: appui(),
        ),
    ];
  }
}

/// L'en-tete d'une carte : une icone et un titre de carte (`titleMedium`).
/// Un texte tres agrandi pose le titre sous l'icone, pour lui laisser toute la
/// largeur : « remuneration » ne se coupe pas a 320 de large.
class _EnteteCarte extends StatelessWidget {
  const _EnteteCarte({required this.icone, required this.titre});

  final IconData icone;
  final String titre;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool agrandi = MediaQuery.textScalerOf(context).scale(14) / 14 > 1.3;
    final Widget pastille = ExcludeSemantics(
      child: IconTheme(
        data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
        child: Icon(icone),
      ),
    );
    final Widget texte = Semantics(
      header: true,
      child: Text(titre, style: Theme.of(context).textTheme.titleMedium),
    );
    if (agrandi) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[pastille, Ecart.vSm, texte],
      );
    }
    return Row(
      children: <Widget>[
        pastille,
        Ecart.hMd,
        Expanded(child: texte),
      ],
    );
  }
}

/// La carte des conditions de remuneration : la part de l'enseignant en
/// pourcentage, lue au serveur, pour chaque public que le serveur rend.
class CarteConditions extends StatelessWidget {
  /// Cree la carte.
  const CarteConditions({required this.conditions, super.key});

  /// Les conditions lues au serveur.
  final ConditionsRemuneration conditions;

  /// La cle de la carte.
  static const Key carteKey = ValueKey<String>('conditions-carte');

  /// La cle d'une ligne de part.
  static Key ligneKey(String public) =>
      ValueKey<String>('conditions-part-$public');

  /// La cle de la clause de continuite.
  static const Key continuiteKey = ValueKey<String>('conditions-continuite');

  /// La cle de la phrase du moyen de versement valide par Rewayah.
  static const Key moyenValideKey = ValueKey<String>('conditions-moyen-valide');

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final r = t.recrutement.questionnaire;
    String? nomPublic(String code) => switch (code) {
      'enfant' => r.publicEnfant,
      'adulte' => r.publicAdulte,
      _ => null,
    };
    final List<Widget> parts = <Widget>[
      if (conditions.partUnique)
        Text(
          r.part(part: partEnPourcent(conditions.publics.first.partPourMille)),
          key: ligneKey('tous'),
          style: textes.titleMedium,
        )
      else
        for (final PublicRemuneration p in conditions.publics)
          if (nomPublic(p.code) case final String nom)
            Text(
              r.partPublic(public: nom, part: partEnPourcent(p.partPourMille)),
              key: ligneKey(p.code),
              style: textes.titleMedium,
            ),
    ];
    final DateTime? effet = conditions.dateEffet;
    return AppCard(
      key: carteKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _EnteteCarte(
            icone: AppIcons.paiements.repos,
            titre: r.conditionsTitre,
          ),
          Ecart.vLg,
          PileCartes(ecart: AppSpacing.lg, children: parts),
          if (!conditions.enVigueur && effet != null) ...<Widget>[
            Ecart.vMd,
            Text(
              r.conditionsDateEffet(date: _jour(effet)),
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ],
          Ecart.vMd,
          // Le moyen de versement (SPEC 4.2, CAND-01) : la case ne porte plus
          // que sur les conditions, qui disent donc aussi par quel moyen la
          // personne est payee.
          Text(r.moyenValide, key: moyenValideKey, style: textes.bodyMedium),
          Ecart.vSm,
          // La continuite (decision du directeur du 22/10/2026) : une clause
          // des conditions que la personne accepte, pas une question.
          Text(r.continuite, key: continuiteKey, style: textes.bodyMedium),
          Ecart.vSm,
          Text(r.coordonneesPlusTard, style: textes.bodyMedium),
          Ecart.vSm,
          Text(r.montantsSurDemande, style: textes.bodyMedium),
        ],
      ),
    );
  }

  static String _jour(DateTime d) => isolerSens(
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}',
  );
}

/// La carte du cadre religieux et pedagogique : publie ou non, accepte ou
/// non. L'acceptation se fait sur la page des accords (le texte y est lu en
/// entier) ; l'envoi l'exige.
class CarteCadre extends StatelessWidget {
  /// Cree la carte.
  const CarteCadre({required this.cadre, super.key});

  /// L'etat du cadre pour ce candidat.
  final EtatCadre cadre;

  /// La cle de la carte.
  static const Key carteKey = ValueKey<String>('cadre-carte');

  /// La cle du lien vers la page des accords.
  static const Key lienKey = ValueKey<String>('cadre-lien');

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final String phrase = !cadre.publie
        ? t.accords.cadreNonPublie
        : cadre.accepte
        ? t.recrutement.questionnaire.cadreAccepte
        : t.recrutement.questionnaire.cadreManquant;
    return AppCard(
      key: carteKey,
      selectionnee: cadre.publie && cadre.accepte,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _EnteteCarte(
            icone:
                (cadre.publie && cadre.accepte
                        ? AppIcons.succes
                        : AppIcons.cahier)
                    .resoudre(selectionne: cadre.publie && cadre.accepte),
            titre: t.recrutement.portail.elementCadre,
          ),
          Ecart.vMd,
          Text(phrase, style: textes.bodyMedium),
          if (cadre.publie && !cadre.accepte) ...<Widget>[
            Ecart.vSm,
            LienFleche(
              key: lienKey,
              libelle: t.attente.lireEtAccepter,
              alignerEnDebut: true,
              onPress: () => unawaited(context.push(Routes.attenteAccords)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Le recapitulatif, les conditions et l'envoi.
class RecapitulatifEtape extends ConsumerStatefulWidget {
  /// Cree l'etape.
  const RecapitulatifEtape({
    required this.controleur,
    required this.candidature,
    required this.versionCandidature,
    required this.numero,
    required this.total,
    super.key,
    this.onRenvoi,
  });

  /// Dit a la page la phrase a montrer sur la question que le recapitulatif
  /// rouvre apres un refus du serveur : ce qui n'allait pas, sans qu'elle
  /// disparaisse avec le recapitulatif.
  final ValueChanged<String>? onRenvoi;

  /// Le parcours.
  final ParcoursControleur controleur;

  /// La candidature, telle que `etat_dossier()` la rend.
  final CandidatureDossier candidature;

  /// La version de la candidature lue avec le questionnaire.
  final int versionCandidature;

  /// Le rang de l'etape.
  final int numero;

  /// Le nombre d'etapes.
  final int total;

  /// La cle de la case des conditions.
  static const Key caseKey = ValueKey<String>('recap-accord');

  /// La cle du message d'etat de l'envoi.
  static const Key messageKey = ValueKey<String>('recap-message');

  /// La cle de la note hors ligne.
  static const Key noteHorsLigneKey = ValueKey<String>('recap-hors-ligne');

  @override
  ConsumerState<RecapitulatifEtape> createState() => _RecapitulatifEtapeState();
}

class _RecapitulatifEtapeState extends ConsumerState<RecapitulatifEtape> {
  bool _accord = false;
  bool _envoi = false;
  String? _message;
  String? _cle;

  ParcoursControleur get _c => widget.controleur;

  Future<void> _envoyer(ConditionsRemuneration conditions) async {
    final r = t.recrutement.questionnaire;
    if (!_accord) {
      setState(() => _message = r.accordManquant);
      return;
    }
    final PortMaCandidature? port = ref.read(portMaCandidatureProvider);
    if (port == null) {
      setState(() => _message = r.nonOuverte);
      return;
    }
    setState(() {
      _envoi = true;
      _message = null;
    });
    // Une cle par tentative : rejouee tant que l'issue est incertaine, pour
    // que le serveur n'ecrive pas deux fois le meme envoi.
    final String cle = _cle ??= nouvelleCleIdempotence();
    try {
      await port.envoyerReponses(
        versionQuestionnaire: _c.questionnaire.version,
        reponses: _c.reponsesPourEnvoi(),
        accordRemuneration: true,
        versionConditions: conditions.version,
        versionAttendue: widget.versionCandidature,
        cleIdempotence: cle,
      );
      // Le succes se dit apres la reponse du serveur : le portail relit l'etat.
      ref.invalidate(etatDossierProvider);
      ref.invalidate(questionnaireCandidatProvider);
      if (mounted) {
        context.go(Routes.attente);
      }
    } on QuestionnairePerime {
      _cle = null;
      ref.invalidate(questionnaireCandidatProvider);
      _refus(r.perime);
    } on ReponsesIncompletes catch (e) {
      _cle = null;
      _versLaReponse(e.champs, r.incomplet);
    } on ReponsesInvalides catch (e) {
      _cle = null;
      if (e.plagesQuiSeChevauchent) {
        // La cause est nommee par le serveur : on le dit, et on rouvre les
        // disponibilites.
        _refus(r.plagesChevauchent);
        _c.modifier('disponibilitesDeclarees');
        widget.onRenvoi?.call(r.plagesChevauchent);
      } else {
        _versLaReponse(e.champs, r.reponseInvalide);
      }
    } on AccordRemunerationRequis {
      _cle = null;
      _refus(r.accordManquant);
    } on ConditionsPerimees {
      _cle = null;
      ref.invalidate(conditionsRemunerationCandidatProvider);
      if (mounted) {
        setState(() => _accord = false);
      }
      _refus(r.conditionsPerimees);
    } on EngagementNonAccepte catch (e) {
      _cle = null;
      ref.invalidate(etatDossierProvider);
      _refus(e.publie ? r.cadreManquant : t.accords.cadreNonPublie);
    } on ConflitCandidature {
      _cle = null;
      ref.invalidate(questionnaireCandidatProvider);
      _refus(r.conflit);
    } on TransitionInterdite {
      _cle = null;
      ref.invalidate(etatDossierProvider);
      _refus(r.interdit);
    } on HorsLigneCandidature {
      // Issue non confirmee : la meme cle repart au prochain essai.
      _refus(r.incertain);
    } on CapaciteIndisponible {
      _cle = null;
      _refus(r.nonOuverte);
    } on PermissionInsuffisante {
      _cle = null;
      _refus(r.interdit);
    } on Object {
      // Une reponse qu'on ne comprend pas ne dit pas si l'envoi a eu lieu.
      _refus(r.incertain);
    }
  }

  void _refus(String message) {
    if (mounted) {
      setState(() {
        _envoi = false;
        _message = message;
      });
    }
  }

  /// Renvoie a la premiere reponse nommee par le serveur.
  void _versLaReponse(
    List<String> champs,
    String Function({required Object question}) texte,
  ) {
    for (final String code in champs) {
      final String? nom = nomCourtQuestion(code);
      if (nom != null) {
        final String phrase = texte(question: nom);
        _refus(phrase);
        _c.modifier(code);
        widget.onRenvoi?.call(phrase);
        return;
      }
    }
    _refus(t.recrutement.questionnaire.echec);
  }

  @override
  Widget build(BuildContext context) {
    final r = t.recrutement.questionnaire;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final AsyncValue<ConditionsRemuneration> conditions = ref.watch(
      conditionsRemunerationCandidatProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final EtatCadre cadre = widget.candidature.cadre;
    final ConditionsRemuneration? lues = conditions.value;
    final bool peutEnvoyer =
        cadre.publie && cadre.accepte && lues != null && !horsLigne;

    return CoquilleParcours(
      numero: widget.numero,
      total: widget.total,
      titre: t.recrutement.parcours.recap.titre,
      explication: t.recrutement.parcours.recap.explication,
      onRetour: _c.reculer,
      libelleAction: peutEnvoyer ? r.envoyer : null,
      onAction: peutEnvoyer ? () => unawaited(_envoyer(lues)) : null,
      enCours: _envoi,
      fleche: false,
      souscription: _message != null
          ? Semantics(
              liveRegion: true,
              child: Text(
                _message!,
                key: RecapitulatifEtape.messageKey,
                textAlign: TextAlign.center,
                style: palette.inkAlert.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            )
          : horsLigne
          ? Text(
              r.horsLigne,
              key: RecapitulatifEtape.noteHorsLigneKey,
              textAlign: TextAlign.center,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            )
          : null,
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CartesRecapitulatif(
            questionnaire: _c.questionnaire,
            reponses: _c.reponses,
            onModifier: _envoi ? null : _c.modifier,
          ),
          Ecart.vSection,
          BlocAsynchrone<ConditionsRemuneration>(
            key: const ValueKey<String>('recap-conditions'),
            valeur: conditions,
            squelette: const Skeleton.liste(lignes: 2),
            titreEchec: r.conditionsNonCharge,
            onReessayer: () =>
                ref.invalidate(conditionsRemunerationCandidatProvider),
            erreurVersEtat: (Object erreur, VoidCallback? reessayer) =>
                erreur is HorsLigneCandidature
                ? EtatSansDonnees(
                    quoi: r.conditionsNonCharge,
                    onAction: reessayer,
                  )
                : null,
            construire: (ConditionsRemuneration c) => PileCartes(
              children: <Widget>[
                CarteConditions(conditions: c),
                CaseAccordTexte(
                  key: RecapitulatifEtape.caseKey,
                  libelle: r.accordRemuneration,
                  cochee: _accord,
                  onChanged: _envoi
                      ? null
                      : (bool v) => setState(() {
                          _accord = v;
                          _message = null;
                        }),
                ),
              ],
            ),
          ),
          Ecart.vLg,
          CarteCadre(cadre: cadre),
        ],
      ),
    );
  }
}
