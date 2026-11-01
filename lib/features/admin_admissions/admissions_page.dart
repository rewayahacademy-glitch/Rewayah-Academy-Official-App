// Admission, lot C (decision du directeur du 27/10/2026, §3 et §4 ; fiche
// docs/current/FICHE-ADMISSION-LOT-C-2026-10-30.md) : « Demandes », les
// listes de la direction pour les familles et les eleves adultes, separees de
// la file des enseignants. Une carte par demande, la plus ancienne d'abord ;
// toucher une carte ouvre sa feuille, qui porte les gestes. Le serveur decide
// de tout et envoie l'e-mail de chaque geste ; l'ecran dit ses refus en une
// phrase.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:uuid/uuid.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/admission/port_admissions_direction.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/offres/offre_horaire.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/controle_segmente.dart' show Segment;
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/selecteur_section.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';
import '../parcours_offres/libelles_parcours.dart';

/// La cle d'une page de liste.
typedef CleListeAdmissions = ({
  PopulationAdmission population,
  String recherche,
  int page,
});

/// Une page de la liste ; relue apres chaque geste.
final FutureProviderFamily<PageAdmissions, CleListeAdmissions>
pageAdmissionsProvider =
    FutureProvider.family<PageAdmissions, CleListeAdmissions>(
      (Ref ref, CleListeAdmissions cle) => ref
          .watch(portAdmissionsDirectionProvider)
          .lister(
            cle.population,
            recherche: cle.recherche.isEmpty ? null : cle.recherche,
            page: cle.page,
          ),
    );

/// Les modeles de message d'un refus, dans l'ordre propose (liste fermee du
/// serveur, `private.candidature_modeles_message`).
const List<String> modelesRefusAdmission = <String>[
  'refus_general',
  'refus_besoins',
  'refus_niveau',
  'refus_sans_reponse',
];

String _date(DateTime d) => t.commun.dates.jourDate(
  jour: t.commun.dates.jours[d.weekday - 1],
  numero: d.day,
  mois: t.commun.dates.mois[d.month - 1],
);

String _etat(EtatDemandeAdmission e) {
  final a = t.admissions.etat;
  return switch (e) {
    EtatDemandeAdmission.aTraiter => a.aTraiter,
    EtatDemandeAdmission.aCompleter => a.aCompleter,
    EtatDemandeAdmission.acceptee => a.acceptee,
    EtatDemandeAdmission.refusee => a.refusee,
    EtatDemandeAdmission.retiree => a.retiree,
  };
}

TonEtat _ton(EtatDemandeAdmission e) => switch (e) {
  EtatDemandeAdmission.aTraiter => TonEtat.accent,
  EtatDemandeAdmission.aCompleter => TonEtat.avertissement,
  EtatDemandeAdmission.acceptee => TonEtat.succes,
  EtatDemandeAdmission.refusee ||
  EtatDemandeAdmission.retiree => TonEtat.neutre,
};

/// Une ligne d'apprenant : « Yasmine, 9 ans · Nous commençons par les
/// lettres ».
String ligneApprenant(ApprenantAdmission a) {
  final List<String> morceaux = <String>[
    if (a.titulaire)
      t.admissions.titulaire(prenom: a.prenom)
    else
      LibellesGroupe.insecable(
        t.admissions.enfant(prenom: a.prenom, age: a.age ?? 0),
      ),
    if (NiveauDeclare.depuisSql(a.niveau) case final NiveauDeclare n)
      libelleNiveau(n),
  ];
  return morceaux.join(' · ');
}

/// « Demandes » : familles et eleves adultes.
class AdmissionsPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const AdmissionsPage({super.key, this.ouvrir});

  /// L2 des listes : la demande a montrer a l'ouverture (depuis une ligne
  /// « En attente » de Comptes) : sa population, et le nom cherche. Nul : la
  /// page s'ouvre comme avant.
  final DemandeAdmissionAOuvrir? ouvrir;

  /// La cle d'une carte, pour les tests.
  static ValueKey<String> cleCarte(String id) =>
      ValueKey<String>('admission-$id');

  @override
  ConsumerState<AdmissionsPage> createState() => _AdmissionsPageState();
}

class _AdmissionsPageState extends ConsumerState<AdmissionsPage> {
  late PopulationAdmission _population =
      widget.ouvrir?.population ?? PopulationAdmission.famille;
  late final TextEditingController _recherche = TextEditingController(
    text: widget.ouvrir?.recherche ?? '',
  );
  late String _rechercheAppliquee = widget.ouvrir?.recherche.trim() ?? '';
  int _page = 1;

  /// Ouverte depuis Comptes : la population est deduite du compte (un
  /// titulaire qui apprend, sans enfant, est un eleve adulte). Un parent qui
  /// suit aussi des cours et n'a pas encore d'enfant inscrit fait exception :
  /// si la premiere liste ne trouve personne, la page essaie l'autre, une
  /// fois.
  late bool _essaiAutre = widget.ouvrir != null;

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  CleListeAdmissions get _cle =>
      (population: _population, recherche: _rechercheAppliquee, page: _page);

  void _relire() => ref.invalidate(pageAdmissionsProvider(_cle));

  @override
  Widget build(BuildContext context) {
    final a = t.admissions;
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<PageAdmissions> lecture = ref.watch(
      pageAdmissionsProvider(_cle),
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final PageAdmissions? page = lecture.value;
    if (_essaiAutre && page != null) {
      _essaiAutre = false;
      if (page.total == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _population = _population == PopulationAdmission.famille
                ? PopulationAdmission.eleveAdulte
                : PopulationAdmission.famille;
            _page = 1;
          });
        });
      }
    }
    return PageShell(
      titre: a.titre,
      sousTitre: a.sousTitre,
      entete: SousNavigationDomaine(
        onglets: ongletsPersonnes(),
        indexActif: ongletsPersonnes().length - 1,
      ),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SelecteurSection<PopulationAdmission>(
                libelle: a.population,
                sections: <Segment<PopulationAdmission>>[
                  Segment<PopulationAdmission>(
                    valeur: PopulationAdmission.famille,
                    libelle: a.familles,
                  ),
                  Segment<PopulationAdmission>(
                    valeur: PopulationAdmission.eleveAdulte,
                    libelle: a.elevesAdultes,
                  ),
                ],
                valeur: _population,
                onChange: (PopulationAdmission p) => setState(() {
                  _essaiAutre = false;
                  _population = p;
                  _page = 1;
                }),
              ),
              Ecart.vLg,
              if (page != null) ...<Widget>[
                Text(
                  a.aTraiter(n: page.aTraiter),
                  key: const ValueKey<String>('admissions-a-traiter'),
                  style: textes.titleMedium,
                ),
                Ecart.vMd,
              ],
              ChampEtiquete(
                libelle: a.rechercher,
                controller: _recherche,
                aide: a.rechercherAide,
                onChanged: (String v) => setState(() {
                  _rechercheAppliquee = v.trim();
                  _page = 1;
                }),
              ),
              Ecart.vXl,
              if (lecture.hasValue)
                _liste(context, lecture.requireValue)
              else if (lecture.hasError)
                EtatSysteme(
                  nature: horsLigne
                      ? NatureEtat.horsLigne
                      : NatureEtat.echecServeur,
                  phrase: a.lectureErreur,
                  libelleAction: t.commun.etats.actions.reessayer,
                  onAction: _relire,
                )
              else
                const Skeleton.liste(lignes: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _liste(BuildContext context, PageAdmissions page) {
    final a = t.admissions;
    if (page.lignes.isEmpty) {
      return EmptyState(
        message: _rechercheAppliquee.isEmpty ? a.vide : a.videRecherche,
        registre: RegistreVide.bonneNouvelle,
      );
    }
    final int pages = (page.total / page.parPage).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PileCartes(
          children: <Widget>[
            for (final DemandeAdmission d in page.lignes)
              _CarteDemande(
                key: AdmissionsPage.cleCarte(d.id),
                demande: d,
                onPress: () => _ouvrir(context, d),
              ),
          ],
        ),
        if (pages > 1) ...<Widget>[
          Ecart.vLg,
          Row(
            children: <Widget>[
              if (_page > 1)
                ActionPrincipale(
                  libelle: a.pagePrecedente,
                  niveau: NiveauAction.tertiaire,
                  pleineLargeur: false,
                  onPress: () => setState(() => _page--),
                ),
              const Spacer(),
              Text(a.pageSur(n: _page, total: pages)),
              const Spacer(),
              if (_page < pages)
                ActionPrincipale(
                  libelle: a.pageSuivante,
                  niveau: NiveauAction.tertiaire,
                  pleineLargeur: false,
                  onPress: () => setState(() => _page++),
                ),
            ],
          ),
        ],
      ],
    );
  }

  void _ouvrir(BuildContext context, DemandeAdmission d) {
    unawaited(
      AppBottomSheet.ouvrir<void>(
        context,
        titre: t.admissions.feuilleTitre(deNom: deDevant(d.nom)),
        constructeur: (BuildContext _) =>
            FeuilleDemandeAdmission(demande: d, onFait: _relire),
      ),
    );
  }
}

class _CarteDemande extends StatelessWidget {
  const _CarteDemande({
    required this.demande,
    required this.onPress,
    super.key,
  });

  final DemandeAdmission demande;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final a = t.admissions;
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      onPress: onPress,
      libelleSemantique: a.ouvrir(deNom: deDevant(demande.nom)),
      entete: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.start,
        spacing: AppSpacing.sm,
        overflowSpacing: AppSpacing.sm,
        children: <Widget>[
          Text(demande.nom, style: textes.titleMedium),
          StatusPill(libelle: _etat(demande.etat), ton: _ton(demande.etat)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LigneCleValeur(cle: a.recueLe, valeur: _date(demande.recueLe)),
          Ecart.vSm,
          LigneCleValeur(cle: a.reference, valeur: demande.reference),
          for (final ApprenantAdmission ap in demande.apprenants) ...<Widget>[
            Ecart.vSm,
            Text(ligneApprenant(ap), style: textes.bodyMedium),
          ],
        ],
      ),
    );
  }
}

enum _Vue {
  resume,
  refuser,
  precisions,
  contacter,
  annuler,
  annulerAcceptation,
}

/// La feuille d'une demande : son contenu et les gestes qui valent dans son
/// etat. Un seul bouton plein ; les autres gestes sont des liens.
class FeuilleDemandeAdmission extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleDemandeAdmission({
    required this.demande,
    required this.onFait,
    super.key,
  });

  /// La demande.
  final DemandeAdmission demande;

  /// Appele apres un geste accepte par le serveur (la liste se relit).
  final VoidCallback onFait;

  @override
  ConsumerState<FeuilleDemandeAdmission> createState() =>
      _FeuilleDemandeAdmissionState();
}

class _FeuilleDemandeAdmissionState
    extends ConsumerState<FeuilleDemandeAdmission> {
  _Vue _vue = _Vue.resume;
  String? _modele;
  final TextEditingController _motif = TextEditingController();
  final TextEditingController _sujet = TextEditingController();
  final TextEditingController _message = TextEditingController();
  final Map<_Vue, String> _cles = <_Vue, String>{};
  bool _envoi = false;
  String? _erreur;
  String? _fait;

  /// Vrai apres un geste qui change l'etat : la feuille porte une version
  /// perimee, elle ne propose plus rien (la liste relue a l'etat juste).
  bool _gesteFait = false;

  @override
  void dispose() {
    _motif.dispose();
    _sujet.dispose();
    _message.dispose();
    super.dispose();
  }

  void _aller(_Vue v) => setState(() {
    _vue = v;
    _erreur = null;
  });

  String _cle(_Vue v) => _cles.putIfAbsent(v, () => const Uuid().v4());

  String _phraseRefus(RefusGesteAdmission r) {
    final a = t.admissions.refus;
    return switch (r) {
      RefusGesteAdmission.dejaTraitee => a.dejaTraitee,
      RefusGesteAdmission.transitionInterdite => a.transitionInterdite,
      RefusGesteAdmission.motifRequis => a.motifRequis,
      RefusGesteAdmission.adresseInconnue => a.adresseInconnue,
      RefusGesteAdmission.enfantEnClasse => a.enfantEnClasse,
      RefusGesteAdmission.autre => a.autre,
    };
  }

  Future<void> _envoyer(_Vue v) async {
    final a = t.admissions;
    final DemandeAdmission d = widget.demande;
    final String motif = _motif.text.trim();
    final String message = _message.text.trim();
    final String sujet = _sujet.text.trim();
    final String? manque = switch (v) {
      _Vue.refuser when _modele == null => a.manqueModele,
      _Vue.refuser ||
      _Vue.annuler ||
      _Vue.annulerAcceptation when motif.isEmpty => a.manqueMotif,
      _Vue.precisions when message.isEmpty => a.manqueMessage,
      _Vue.contacter when sujet.isEmpty || message.isEmpty => a.manqueContact,
      _ => null,
    };
    if (manque != null) {
      setState(() => _erreur = manque);
      return;
    }
    if (v == _Vue.refuser || v == _Vue.annulerAcceptation) {
      final bool refus = v == _Vue.refuser;
      final bool oui = await ConfirmDestructive.demander(
        context,
        question: refus
            ? a.refuserQuestion(deNom: deDevant(d.nom))
            : a.annulerAcceptationQuestion(deNom: deDevant(d.nom)),
        consequence: refus
            ? a.refuserConsequence
            : a.annulerAcceptationConsequence,
        libelleConfirmer: refus ? a.refuser : a.annulerAcceptation,
      );
      if (!oui || !mounted) return;
    }
    if (ref.read(horsLigneProvider).value ?? false) {
      setState(() => _erreur = a.horsLigne);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    final PortAdmissionsDirection port = ref.read(
      portAdmissionsDirectionProvider,
    );
    try {
      switch (v) {
        case _Vue.resume:
          await port.accepter(d, cle: _cle(v));
          _fait = a.faitAcceptee(deNom: deDevant(d.nom));
        case _Vue.refuser:
          await port.refuser(d, motif: motif, modele: _modele!, cle: _cle(v));
          _fait = a.faitRefusee(deNom: deDevant(d.nom));
        case _Vue.precisions:
          await port.demanderPrecisions(d, message: message, cle: _cle(v));
          _fait = a.faitPrecisions(nom: d.nom);
        case _Vue.contacter:
          await port.contacter(d, sujet: sujet, message: message, cle: _cle(v));
          _fait = a.faitContact(nom: d.nom);
        case _Vue.annuler:
          await port.annulerRefus(d, motif: motif, cle: _cle(v));
          _fait = a.faitRefusAnnule(deNom: deDevant(d.nom));
        case _Vue.annulerAcceptation:
          await port.annulerAcceptation(d, motif: motif, cle: _cle(v));
          _fait = a.faitAcceptationAnnulee(deNom: deDevant(d.nom));
      }
      _cles.remove(v);
      if (v != _Vue.contacter) _gesteFait = true;
      widget.onFait();
      if (mounted) setState(() => _vue = _Vue.resume);
    } on GesteAdmissionRefuse catch (r) {
      if (mounted) setState(() => _erreur = _phraseRefus(r.raison));
      // Une demande traitee ailleurs : la liste se relit.
      widget.onFait();
    } on Object {
      if (mounted) setState(() => _erreur = a.erreur);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = t.admissions;
    final TextTheme textes = Theme.of(context).textTheme;
    final DemandeAdmission d = widget.demande;
    final bool traitable =
        d.etat == EtatDemandeAdmission.aTraiter ||
        d.etat == EtatDemandeAdmission.aCompleter;
    final bool annulable = d.refusAnnulableA(DateTime.now());
    final bool acceptationAnnulable = d.acceptationAnnulableA(DateTime.now());
    final Widget erreur = _erreur == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _erreur!,
                key: const ValueKey<String>('admission-erreur'),
              ),
            ),
          );
    final Widget retour = Align(
      alignment: AlignmentDirectional.centerStart,
      child: ActionPrincipale(
        libelle: a.retour,
        niveau: NiveauAction.tertiaire,
        pleineLargeur: false,
        onPress: () => _aller(_Vue.resume),
      ),
    );
    return switch (_vue) {
      _Vue.resume => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_fait case final String fait) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(fait, style: textes.bodyMedium),
            ),
            Ecart.vLg,
          ],
          LigneCleValeur(cle: a.etatLibelle, valeur: _etat(d.etat)),
          Ecart.vSm,
          LigneCleValeur(cle: a.recueLe, valeur: _date(d.recueLe)),
          Ecart.vSm,
          LigneCleValeur(cle: a.reference, valeur: d.reference),
          if (d.courriel case final String c) ...<Widget>[
            Ecart.vSm,
            LigneCleValeur(cle: a.courriel, valeur: c),
          ],
          Ecart.vLg,
          for (final ApprenantAdmission ap in d.apprenants) ...<Widget>[
            Text(ligneApprenant(ap), style: textes.bodyMedium),
            Ecart.vSm,
          ],
          Ecart.vLg,
          erreur,
          if (_gesteFait)
            const SizedBox.shrink()
          else if (traitable) ...<Widget>[
            _plein(
              key: const ValueKey<String>('admission-accepter'),
              libelle: a.accepter(deNom: deDevant(d.nom)),
              enCours: _envoi,
              onPress: () => _envoyer(_Vue.resume),
            ),
            Ecart.vSm,
            TexteGeste(a.accepterConsequence),
            Ecart.vLg,
            _lien(
              a.demanderPrecisions,
              'admission-precisions',
              _Vue.precisions,
            ),
            _lien(
              a.contacter(nom: d.nom),
              'admission-contacter',
              _Vue.contacter,
            ),
            _lien(a.refuser, 'admission-refuser', _Vue.refuser),
          ] else if (annulable) ...<Widget>[
            _plein(
              key: const ValueKey<String>('admission-annuler-refus'),
              libelle: a.annulerRefus,
              onPress: () => _aller(_Vue.annuler),
            ),
            Ecart.vSm,
            TexteGeste(a.annulerRefusDetail),
            Ecart.vLg,
            _lien(
              a.contacter(nom: d.nom),
              'admission-contacter',
              _Vue.contacter,
            ),
          ] else if (acceptationAnnulable) ...<Widget>[
            _lien(
              a.contacter(nom: d.nom),
              'admission-contacter',
              _Vue.contacter,
            ),
            _lien(
              a.annulerAcceptation,
              'admission-annuler-acceptation',
              _Vue.annulerAcceptation,
            ),
          ] else
            _lien(
              a.contacter(nom: d.nom),
              'admission-contacter',
              _Vue.contacter,
            ),
        ],
      ),
      _Vue.refuser => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TexteGeste(a.refuserContexte),
          Ecart.vLg,
          ChoiceCardGroup(
            key: const ValueKey<String>('admission-modele'),
            autoriserSaisieLibre: false,
            options: <OptionChoix>[
              for (final String m in modelesRefusAdmission)
                OptionChoix(
                  valeur: m,
                  libelle: _libelleModele(m),
                  explication: _phraseModele(m),
                ),
            ],
            onChange: (ReponseChoix r) => setState(() {
              _modele = r.valeurs.isEmpty ? null : r.valeurs.first;
              _erreur = null;
            }),
          ),
          Ecart.vLg,
          ChampEtiquete(
            libelle: a.motifInterne,
            controller: _motif,
            aide: a.motifInterneAide,
            maxLines: 3,
            onChanged: (String _) => setState(() => _erreur = null),
          ),
          Ecart.vXl,
          erreur,
          _plein(
            key: const ValueKey<String>('admission-refuser-envoyer'),
            libelle: a.refuser,
            enCours: _envoi,
            onPress: () => _envoyer(_Vue.refuser),
          ),
          Ecart.vSm,
          retour,
        ],
      ),
      _Vue.precisions => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TexteGeste(a.precisionsContexte),
          Ecart.vLg,
          ChampEtiquete(
            libelle: a.precisionsMessage,
            controller: _message,
            aide: a.precisionsAide,
            maxLines: 4,
            onChanged: (String _) => setState(() => _erreur = null),
          ),
          Ecart.vXl,
          erreur,
          _plein(
            key: const ValueKey<String>('admission-precisions-envoyer'),
            libelle: a.precisionsEnvoyer,
            enCours: _envoi,
            onPress: () => _envoyer(_Vue.precisions),
          ),
          Ecart.vSm,
          retour,
        ],
      ),
      _Vue.contacter => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TexteGeste(a.contactContexte),
          Ecart.vLg,
          ChampEtiquete(
            libelle: a.contactSujet,
            controller: _sujet,
            onChanged: (String _) => setState(() => _erreur = null),
          ),
          Ecart.vMd,
          ChampEtiquete(
            libelle: a.contactMessage,
            controller: _message,
            maxLines: 6,
            onChanged: (String _) => setState(() => _erreur = null),
          ),
          Ecart.vXl,
          erreur,
          _plein(
            key: const ValueKey<String>('admission-contact-envoyer'),
            libelle: a.contactEnvoyer,
            enCours: _envoi,
            onPress: () => _envoyer(_Vue.contacter),
          ),
          Ecart.vSm,
          retour,
        ],
      ),
      _Vue.annuler => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TexteGeste(a.annulerRefusDetail),
          Ecart.vLg,
          ChampEtiquete(
            libelle: a.motifInterne,
            controller: _motif,
            aide: a.motifInterneAide,
            maxLines: 3,
            onChanged: (String _) => setState(() => _erreur = null),
          ),
          Ecart.vXl,
          erreur,
          _plein(
            key: const ValueKey<String>('admission-annuler-envoyer'),
            libelle: a.annulerRefus,
            enCours: _envoi,
            onPress: () => _envoyer(_Vue.annuler),
          ),
          Ecart.vSm,
          retour,
        ],
      ),
      _Vue.annulerAcceptation => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TexteGeste(a.annulerAcceptationDetail),
          Ecart.vLg,
          ChampEtiquete(
            libelle: a.motifInterne,
            controller: _motif,
            aide: a.motifInterneAide,
            maxLines: 3,
            onChanged: (String _) => setState(() => _erreur = null),
          ),
          Ecart.vXl,
          erreur,
          _plein(
            key: const ValueKey<String>(
              'admission-annuler-acceptation-envoyer',
            ),
            libelle: a.annulerAcceptation,
            enCours: _envoi,
            onPress: () => _envoyer(_Vue.annulerAcceptation),
          ),
          Ecart.vSm,
          retour,
        ],
      ),
    };
  }

  /// Le seul bouton plein de chaque vue de la feuille.
  Widget _plein({
    required Key key,
    required String libelle,
    required VoidCallback onPress,
    bool enCours = false,
  }) => ActionPrincipale(
    key: key,
    libelle: libelle,
    enCours: enCours,
    onPress: onPress,
  );

  Widget _lien(String libelle, String cle, _Vue v) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: ActionPrincipale(
      key: ValueKey<String>(cle),
      libelle: libelle,
      niveau: NiveauAction.tertiaire,
      pleineLargeur: false,
      onPress: () => _aller(v),
    ),
  );

  String _libelleModele(String m) {
    final a = t.admissions.modeles;
    return switch (m) {
      'refus_besoins' => a.besoins,
      'refus_niveau' => a.niveau,
      'refus_sans_reponse' => a.sansReponse,
      _ => a.general,
    };
  }

  String _phraseModele(String m) {
    final a = t.admissions.modeles;
    return switch (m) {
      'refus_besoins' => a.besoinsPhrase,
      'refus_niveau' => a.niveauPhrase,
      'refus_sans_reponse' => a.sansReponsePhrase,
      _ => a.generalPhrase,
    };
  }
}

/// Une phrase de contexte ou de consequence d'un geste.
class TexteGeste extends StatelessWidget {
  /// Cree la phrase.
  const TexteGeste(this.texte, {super.key});

  /// Le texte.
  final String texte;

  @override
  Widget build(BuildContext context) =>
      Text(texte, style: Theme.of(context).textTheme.bodyMedium);
}
