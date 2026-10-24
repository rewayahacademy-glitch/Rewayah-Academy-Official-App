// Les blocs de la candidature ouverte (`ADM-21`), dans l'ordre de la fiche :
// la situation (etape, etat, pause, restriction), ce qui bloque, la prochaine
// action, les reponses, les controles, ce que le serveur ne sert pas encore
// (piece, entretien, affectation, courriels), le responsable, le contact et
// l'historique.
//
// Tout vient du serveur, rien n'est recalcule ici. Un bloc que le serveur ne
// sert pas encore le dit seul (« Disponible au branchement serveur ») ; les
// autres blocs s'affichent. Aucun courriel, aucun telephone et aucun genre
// avant « Voir le contact » ; aucun nom de personne dans l'historique.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/gestes_candidature.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidature_detail.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/port_candidatures_direction.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/i18n/identifiant_insecable.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../admin_candidatures/libelles_candidatures.dart';
import 'gestes_proposes.dart';
import 'libelles_candidature.dart';
import 'reponses_candidature.dart';

/// Un titre de section de la page, lu comme un titre par les lecteurs d'ecran.
class _Titre extends StatelessWidget {
  const _Titre(this.texte, {this.action});

  final String texte;

  /// Un menu ou un lien a la fin de la ligne du titre.
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Semantics(header: true, child: SectionHeader(titre: texte)),
      ),
      ?action,
    ],
  );
}

/// Une phrase de corps en encre attenuee.
class _Muet extends StatelessWidget {
  const _Muet(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) => TexteSansCoupure(
    texte,
    style: AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle()),
  );
}

/// Le bloc qui dit « Disponible au branchement serveur » a la place de sa
/// donnee : jamais un zero, jamais une liste vide.
class _Branchement extends StatelessWidget {
  const _Branchement();

  @override
  Widget build(BuildContext context) =>
      _Muet(t.commun.etats.branchementServeur);
}

// ---------------------------------------------------------------------------
// Situation
// ---------------------------------------------------------------------------

/// La situation de la candidature : l'etat en un mot et une icone, la salle,
/// le versement, le pays, les dates, la provenance, la pause, la restriction.
class CarteSituation extends StatelessWidget {
  /// Cree la carte.
  const CarteSituation({required this.detail, super.key});

  /// Le dossier lu.
  final DetailCandidature detail;

  /// La cle de la carte.
  static const Key cle = ValueKey<String>('candidature-situation');

  @override
  Widget build(BuildContext context) {
    final LigneCandidature l = detail.ligne;
    final r = t.admin.candidatures;
    final EtatAffiche? etat = l.restreinte
        ? (
            libelle: libelleRestriction(detail.restrictionCause),
            ton: TonEtat.alerte,
          )
        : etatAffiche(l);
    final String? salle = libelleSalle(l.etape);
    final List<String> marques = marquesDeLigne(l);
    return AppCard(
      key: cle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (etat != null) ...<Widget>[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusPill(libelle: etat.libelle, ton: etat.ton),
            ),
            Ecart.vMd,
          ],
          if (salle != null)
            LigneCleValeur(cle: r.colonnes.salle, valeur: salle),
          LigneCleValeur(
            cle: r.colonnes.versement,
            valeur: libelleVersement(l.paiement),
          ),
          if (libellePays(l.paysResidence) case final String pays)
            LigneCleValeur(cle: r.colonnes.pays, valeur: pays),
          Ecart.vSm,
          if (l.recueLe != null)
            _Muet(r.detail.recue(date: dateCourteCandidature(l.recueLe!))),
          _Muet(r.ligne.activite(date: activiteAffichee(l))),
          if (detail.provenance != null)
            _Muet(
              r.detail.provenance(
                provenance: libelleProvenance(detail.provenance!),
              ),
            ),
          if (detailDate(l) case final String date) _Muet(date),
          if (l.enPause && detail.pauseModele != null)
            _Muet(
              r.detail.messagePause(nom: libelleModele(detail.pauseModele!)),
            ),
          if (l.issue == IssueCandidature.refusee && detail.refusModele != null)
            _Muet(
              r.detail.messageRefus(nom: libelleModele(detail.refusModele!)),
            ),
          for (final String marque in marques) _Muet(marque),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ce qui bloque
// ---------------------------------------------------------------------------

/// « Ce qui bloque » : chaque controle faux, nomme, avec sa cause.
class BlocBlocages extends StatelessWidget {
  /// Cree le bloc.
  const BlocBlocages({required this.detail, super.key});

  /// Le dossier lu.
  final DetailCandidature detail;

  /// La cle du bloc.
  static const Key cle = ValueKey<String>('candidature-blocages');

  @override
  Widget build(BuildContext context) {
    final r = t.admin.candidatures.detail;
    final List<ControleCandidature> faux = detail.blocages;
    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Titre(r.blocages),
        Ecart.vMd,
        AppCard(
          child: detail.controles == null
              ? const _Branchement()
              : faux.isEmpty
              ? _Muet(r.aucunBlocage)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final ControleCandidature c in faux)
                      _LigneControle(controle: c),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Un controle : une icone, son nom, son etat en mot, sa cause quand il est
/// faux. Jamais la couleur seule.
class _LigneControle extends StatelessWidget {
  const _LigneControle({required this.controle});

  final ControleCandidature controle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool vrai = controle.valeur;
    final r = t.admin.candidatures.detail;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ExcludeSemantics(
              child: IconTheme(
                data: (vrai ? palette.inkAccent : palette.inkAlert).asIconTheme(
                  size: AppSpacing.xl,
                ),
                child: Icon(
                  vrai ? AppIcons.succes.repos : AppIcons.interdit.repos,
                ),
              ),
            ),
            Ecart.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TexteSansCoupure(
                    libelleControle(controle.nom),
                    style: textes.titleSmall,
                  ),
                  TexteSansCoupure(
                    vrai ? r.controlesVrai : r.controlesFaux,
                    style: palette.inkMuted.applyTo(
                      textes.bodySmall ?? const TextStyle(),
                    ),
                  ),
                  if (!vrai)
                    TexteSansCoupure(
                      libelleCauseControle(controle.nom, controle.cause),
                      style: palette.inkAlert.applyTo(
                        textes.bodyMedium ?? const TextStyle(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Prochaine action
// ---------------------------------------------------------------------------

/// « Prochaine action » : le seul bouton plein de la page, ou la raison pour
/// laquelle il n'y en a pas ; le menu des autres gestes ; le retour local d'un
/// geste reussi. Hors ligne, aucun geste n'est rendu : une note dit quand.
class BlocProchaineAction extends StatelessWidget {
  /// Cree le bloc.
  const BlocProchaineAction({
    required this.detail,
    required this.gestes,
    required this.horsLigne,
    required this.onGeste,
    this.retour,
    super.key,
  });

  /// Le dossier lu.
  final DetailCandidature detail;

  /// Les gestes proposes pour ce dossier.
  final GestesProposes gestes;

  /// Vrai quand l'appareil n'a pas de reseau.
  final bool horsLigne;

  /// Ouvre la feuille d'un geste.
  final ValueChanged<GesteCandidature> onGeste;

  /// Le retour local du dernier geste reussi, ou `null`.
  final String? retour;

  /// La cle du bloc.
  static const Key cle = ValueKey<String>('candidature-action');

  /// La cle du bouton de la prochaine action.
  static const Key cleBouton = ValueKey<String>('candidature-prochaine-action');

  /// La cle du menu des autres gestes.
  static const Key cleMenu = ValueKey<String>('candidature-autres-gestes');

  /// La raison pour laquelle aucune action n'est proposee.
  String _raison() {
    final r = t.admin.candidatures.detail;
    final LigneCandidature l = detail.ligne;
    if (l.issue != IssueCandidature.enCours) {
      return r.fermee;
    }
    if (l.etat == EtatCandidature.aCompleter) {
      return r.enAttentePersonne;
    }
    return r.aucuneAction;
  }

  @override
  Widget build(BuildContext context) {
    final r = t.admin.candidatures;
    final GesteCandidature? principal = gestes.principal;
    final bool menu = !horsLigne && gestes.autres.isNotEmpty;
    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Titre(
          r.detail.prochaineAction,
          action: menu
              ? MenuActions(
                  key: cleMenu,
                  points: true,
                  libelle: r.detail.autresGestes,
                  actions: <EntreeAction>[
                    for (final GesteCandidature g in gestes.autres)
                      EntreeAction(
                        libelle: libelleGeste(g),
                        destructif: g.destructif,
                        onChoix: () => onGeste(g),
                      ),
                  ],
                )
              : null,
        ),
        Ecart.vMd,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (horsLigne)
                _Muet(r.erreurs.horsLigne)
              else if (principal != null) ...<Widget>[
                _Muet(libelleConsequence(principal)),
                Ecart.vLg,
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ActionPrincipale(
                    key: cleBouton,
                    libelle: libelleGeste(principal),
                    pleineLargeur: false,
                    onPress: () => onGeste(principal),
                  ),
                ),
              ] else
                _Muet(_raison()),
            ],
          ),
        ),
        if (retour != null) ...<Widget>[
          Ecart.vSm,
          LocalFeedback(message: retour),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reponses
// ---------------------------------------------------------------------------

/// Les reponses de la candidature, par theme, avec la version du questionnaire
/// et la marque des reponses venues de l'ancien formulaire.
class BlocReponses extends StatelessWidget {
  /// Cree le bloc.
  const BlocReponses({
    required this.detail,
    this.nomsOperateurs = const <String, String>{},
    super.key,
  });

  /// Le dossier lu.
  final DetailCandidature detail;

  /// Le nom des operateurs de monnaie mobile du pays de versement.
  final Map<String, String> nomsOperateurs;

  /// La cle du bloc.
  static const Key cle = ValueKey<String>('candidature-reponses');

  @override
  Widget build(BuildContext context) {
    final r = t.admin.candidatures.detail;
    final DocumentReponses? doc = detail.dernieresReponses;
    final List<CarteReponses> cartes = doc == null
        ? const <CarteReponses>[]
        : cartesDeReponses(doc, nomsOperateurs: nomsOperateurs);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Titre(r.reponses),
        Ecart.vMd,
        if (doc == null || cartes.isEmpty)
          AppCard(child: _Muet(r.aucuneReponse))
        else
          CarteGroupee(
            sections: <Widget>[
              _EnteteReponses(document: doc),
              for (final CarteReponses c in cartes)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: TexteSansCoupure(
                        c.titre,
                        style: textes.titleMedium,
                      ),
                    ),
                    Ecart.vSm,
                    for (final LigneReponse ligne in c.lignes)
                      _LigneReponse(ligne: ligne),
                  ],
                ),
            ],
          ),
      ],
    );
  }
}

class _EnteteReponses extends StatelessWidget {
  const _EnteteReponses({required this.document});

  final DocumentReponses document;

  @override
  Widget build(BuildContext context) {
    final r = t.admin.candidatures.detail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Muet(r.reponsesVersion(version: document.questionnaireVersion)),
        if (document.importe) ...<Widget>[
          Ecart.vSm,
          StatusPill(libelle: r.preRempli, ton: TonEtat.neutre),
        ],
      ],
    );
  }
}

class _LigneReponse extends StatelessWidget {
  const _LigneReponse({required this.ligne});

  final LigneReponse ligne;

  @override
  Widget build(BuildContext context) {
    if (ligne.groupes.isEmpty) {
      return LigneCleValeur(cle: ligne.libelle, valeur: ligne.valeur ?? '');
    }
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: LigneCleValeur.margeVerticale,
      ),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TexteSansCoupure(
              ligne.libelle,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
            for (final String g in ligne.groupes)
              TexteSansCoupure(g, style: textes.bodyLarge),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Controles
// ---------------------------------------------------------------------------

/// Les controles du serveur, vrais ou faux, avec leur cause.
class BlocControles extends StatelessWidget {
  /// Cree le bloc.
  const BlocControles({required this.detail, super.key});

  /// Le dossier lu.
  final DetailCandidature detail;

  /// La cle du bloc.
  static const Key cle = ValueKey<String>('candidature-controles');

  @override
  Widget build(BuildContext context) {
    final r = t.admin.candidatures.detail;
    final List<ControleCandidature>? tous = detail.controles;
    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Titre(r.controles),
        Ecart.vMd,
        AppCard(
          child: tous == null
              ? const _Branchement()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final ControleCandidature c in tous)
                      _LigneControle(controle: c),
                  ],
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Ce que le serveur ne sert pas encore
// ---------------------------------------------------------------------------

/// La piece et l'entretien, dans une seule carte (contenus lies) : chacun,
/// quand le serveur ne le sert pas, le dit seul. L'affectation et les courriels
/// ont chacun leur bloc, a leur place dans l'ordre de la fiche (`CONS` §10 :
/// piece, entretien, responsable, affectation, contact, courriels, historique).
class BlocPieceEntretien extends StatelessWidget {
  /// Cree le bloc.
  const BlocPieceEntretien({
    required this.detail,
    this.onOuvrirDossier,
    super.key,
  });

  /// Le dossier lu.
  final DetailCandidature detail;

  /// Mene a « Dossiers a valider » (`ADM-02`), ou `null`.
  final VoidCallback? onOuvrirDossier;

  /// La cle du bloc.
  static const Key cle = ValueKey<String>('candidature-piece-entretien');

  /// La cle du lien vers « Dossiers a valider ».
  static const Key cleDossier = ValueKey<String>('candidature-dossier');

  String? _etatPiece(EtatPiece? p) {
    final e = t.admin.candidatures.detail.etatsPiece;
    return switch (p) {
      EtatPiece.aDeposer => e.aDeposer,
      EtatPiece.deposee => e.deposee,
      EtatPiece.aCorriger => e.aCorriger,
      EtatPiece.validee => e.validee,
      null => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final r = t.admin.candidatures.detail;
    final TextTheme textes = Theme.of(context).textTheme;
    Widget section(String titre, Widget corps) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: TexteSansCoupure(titre, style: textes.titleMedium),
        ),
        Ecart.vXs,
        corps,
      ],
    );
    final String? piece = _etatPiece(detail.piece);
    return CarteGroupee(
      key: cle,
      sections: <Widget>[
        section(
          t.dossiers.revue.piece,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (piece != null) _Muet(piece) else const _Branchement(),
              if (onOuvrirDossier != null)
                LienFleche(
                  key: cleDossier,
                  libelle: r.ouvrirDossier,
                  alignerEnDebut: true,
                  onPress: onOuvrirDossier,
                ),
            ],
          ),
        ),
        section(r.entretien, const _Branchement()),
      ],
    );
  }
}

/// L'affectation, lue dans les classes (« Affectee a {n} classes », « Pas encore
/// affectee ») : le serveur ne la sert pas encore, le bloc le dit seul.
class BlocAffectation extends StatelessWidget {
  /// Cree le bloc.
  const BlocAffectation({super.key});

  /// La cle du bloc.
  static const Key cle = ValueKey<String>('candidature-affectation');

  @override
  Widget build(BuildContext context) => Column(
    key: cle,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      _Titre(t.admin.candidatures.detail.affectation),
      Ecart.vMd,
      const AppCard(child: _Branchement()),
    ],
  );
}

/// L'etat des courriels de la candidature : le serveur ne le sert pas encore,
/// le bloc le dit seul.
class BlocCourriels extends StatelessWidget {
  /// Cree le bloc.
  const BlocCourriels({super.key});

  /// La cle du bloc.
  static const Key cle = ValueKey<String>('candidature-courriels');

  @override
  Widget build(BuildContext context) => Column(
    key: cle,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      _Titre(t.admin.candidatures.detail.courriels),
      Ecart.vMd,
      const AppCard(child: _Branchement()),
    ],
  );
}

// ---------------------------------------------------------------------------
// Responsable
// ---------------------------------------------------------------------------

/// Le responsable : un responsable est designe, ou aucun. Le serveur ne rend
/// pas son nom dans le dossier.
class BlocResponsable extends StatelessWidget {
  /// Cree le bloc.
  const BlocResponsable({required this.detail, super.key});

  /// Le dossier lu.
  final DetailCandidature detail;

  /// La cle du bloc.
  static const Key cle = ValueKey<String>('candidature-responsable');

  @override
  Widget build(BuildContext context) {
    final r = t.admin.candidatures.detail;
    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Titre(r.responsable),
        Ecart.vMd,
        AppCard(
          child: _Muet(
            detail.ligne.responsableId == null
                ? r.aucunResponsable
                : r.responsableDesigne,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Contact
// ---------------------------------------------------------------------------

/// Le contact : masque. « Voir le contact » l'ouvre dans une feuille et
/// l'inscrit au journal ; la phrase le dit avant.
class BlocContact extends StatelessWidget {
  /// Cree le bloc.
  const BlocContact({required this.onVoir, super.key});

  /// Ouvre la feuille du contact, ou `null` quand elle ne peut pas s'ouvrir
  /// (pas de droit, hors ligne) : le lien n'est alors pas rendu.
  final VoidCallback? onVoir;

  /// La cle du bloc.
  static const Key cle = ValueKey<String>('candidature-contact');

  /// La cle du lien « Voir le contact ».
  static const Key cleVoir = ValueKey<String>('candidature-voir-contact');

  @override
  Widget build(BuildContext context) {
    final r = t.admin.candidatures.detail.contact;
    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Titre(r.titre),
        Ecart.vMd,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _Muet(r.masque),
              if (onVoir != null) ...<Widget>[
                _Muet(r.journal),
                LienFleche(
                  key: cleVoir,
                  libelle: r.voir,
                  alignerEnDebut: true,
                  onPress: onVoir,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// La feuille du contact : la lecture se fait a l'ouverture, une seule fois
/// par ouverture (elle est inscrite au journal du serveur), et le contact
/// n'est gardee nulle part ailleurs que dans cette feuille.
Future<void> ouvrirFeuilleContact(
  BuildContext context, {
  required String candidatureId,
}) => AppBottomSheet.ouvrir<void>(
  context,
  titre: t.admin.candidatures.detail.contact.titre,
  constructeur: (BuildContext contexte) => FeuilleContact(
    candidatureId: candidatureId,
    onFermer: () => Navigator.of(contexte).pop(),
  ),
);

/// Le corps de la feuille du contact.
class FeuilleContact extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleContact({
    required this.candidatureId,
    required this.onFermer,
    super.key,
  });

  /// La candidature.
  final String candidatureId;

  /// Ferme la feuille.
  final VoidCallback onFermer;

  /// La cle de la feuille.
  static const Key cle = ValueKey<String>('feuille-contact');

  /// La cle du courriel.
  static const Key cleCourriel = ValueKey<String>('contact-courriel');

  /// La cle du telephone.
  static const Key cleTelephone = ValueKey<String>('contact-telephone');

  @override
  ConsumerState<FeuilleContact> createState() => _EtatFeuilleContact();
}

class _EtatFeuilleContact extends ConsumerState<FeuilleContact> {
  late Future<ContactCandidat> _lecture;

  @override
  void initState() {
    super.initState();
    _lecture = _lire();
  }

  Future<ContactCandidat> _lire() {
    final PortCandidaturesDirection? port = ref.read(
      portCandidaturesDirectionProvider,
    );
    if (port == null) {
      return Future<ContactCandidat>.error(
        const CapaciteIndisponible(dependanceDetailCandidature),
      );
    }
    return port.lireContact(widget.candidatureId);
  }

  @override
  Widget build(BuildContext context) {
    final r = t.admin.candidatures.detail.contact;
    return Column(
      key: FeuilleContact.cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FutureBuilder<ContactCandidat>(
          future: _lecture,
          builder: (BuildContext context, AsyncSnapshot<ContactCandidat> s) {
            if (s.hasError) {
              final Object? e = s.error;
              return EtatSysteme(
                nature: e is CapaciteIndisponible
                    ? NatureEtat.indisponible
                    : e is PermissionInsuffisante
                    ? NatureEtat.accesRefuse
                    : NatureEtat.echecServeur,
                titre: e is CapaciteIndisponible
                    ? t.commun.etats.branchementServeur
                    : e is PermissionInsuffisante
                    ? t.admin.candidatures.accesRefuse
                    : r.lectureEchec,
                phrase: '',
                onAction:
                    e is CapaciteIndisponible || e is PermissionInsuffisante
                    ? null
                    : () => setState(() => _lecture = _lire()),
              );
            }
            if (!s.hasData) {
              return const Skeleton.texte(lignes: 2);
            }
            final ContactCandidat c = s.requireData;
            if (c.vide) {
              return _Muet(r.aucun);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (c.courrielAffiche != null)
                  _Coordonnee(
                    cle: FeuilleContact.cleCourriel,
                    libelle: r.courriel,
                    valeur: c.courrielAffiche!,
                    aConfirmer: c.courriel == null,
                  ),
                if (c.telephoneAffiche != null)
                  _Coordonnee(
                    cle: FeuilleContact.cleTelephone,
                    libelle: r.telephone,
                    valeur: c.telephoneAffiche!,
                    aConfirmer: c.telephone == null,
                  ),
              ],
            );
          },
        ),
        Ecart.vXxl,
        ActionPrincipale(
          libelle: t.commun.fermer,
          onPress: widget.onFermer,
          niveau: NiveauAction.secondaire,
        ),
      ],
    );
  }
}

class _Coordonnee extends StatelessWidget {
  const _Coordonnee({
    required this.cle,
    required this.libelle,
    required this.valeur,
    required this.aConfirmer,
  });

  final Key cle;
  final String libelle;
  final String valeur;
  final bool aConfirmer;

  /// Le nom du champ au-dessus, la valeur dessous sur toute la largeur : une
  /// adresse ne se coupe pas en deux colonnes. La valeur se selectionne (la
  /// direction la copie) et reste lue de gauche a droite, meme en arabe.
  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      key: cle,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TexteSansCoupure(
              libelle,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: SelectableText(valeur, style: textes.bodyLarge),
              ),
            ),
            if (aConfirmer) ...<Widget>[
              Ecart.vXs,
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: StatusPill(
                  libelle: t.admin.candidatures.detail.contact.aConfirmer,
                  ton: TonEtat.avertissement,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Historique
// ---------------------------------------------------------------------------

/// L'historique : une ligne par evenement, du plus recent au plus ancien, par
/// pages. L'auteur se dit par sa qualite, jamais par son nom.
class BlocHistorique extends ConsumerStatefulWidget {
  /// Cree le bloc.
  const BlocHistorique({required this.candidatureId, super.key});

  /// La candidature.
  final String candidatureId;

  /// La cle du bloc.
  static const Key cle = ValueKey<String>('candidature-historique');

  /// La cle du lien « Voir les evenements plus anciens ».
  static const Key clePlus = ValueKey<String>('candidature-historique-plus');

  @override
  ConsumerState<BlocHistorique> createState() => _EtatHistorique();
}

class _EtatHistorique extends ConsumerState<BlocHistorique> {
  /// Les pages suivantes, deja lues.
  final List<EvenementCandidature> _suite = <EvenementCandidature>[];
  int? _curseur;
  bool _curseurPose = false;
  bool _enCours = false;
  Object? _echecSuite;

  Future<void> _plus(int curseur) async {
    final PortCandidaturesDirection? port = ref.read(
      portCandidaturesDirectionProvider,
    );
    if (port == null || _enCours) return;
    setState(() {
      _enCours = true;
      _echecSuite = null;
    });
    try {
      final PageHistorique page = await port.historique(
        widget.candidatureId,
        curseur: curseur,
      );
      if (!mounted) return;
      setState(() {
        _suite.addAll(page.evenements);
        _curseur = page.curseurSuivant;
        _curseurPose = true;
        _enCours = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _echecSuite = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = t.admin.candidatures.detail;
    // Un geste relit la premiere page : les pages plus anciennes deja ouvertes
    // reposaient sur l'ancien curseur et laisseraient un trou ou un doublon.
    // Elles se referment ; « Voir les evenements plus anciens » repart de la
    // nouvelle premiere page.
    ref.listen<AsyncValue<PageHistorique>>(
      historiqueCandidatureProvider(widget.candidatureId),
      (AsyncValue<PageHistorique>? avant, AsyncValue<PageHistorique> apres) {
        if (apres is AsyncData<PageHistorique> && (avant?.hasValue ?? false)) {
          setState(() {
            _suite.clear();
            _curseur = null;
            _curseurPose = false;
            _echecSuite = null;
          });
        }
      },
    );
    final AsyncValue<PageHistorique> premiere = ref.watch(
      historiqueCandidatureProvider(widget.candidatureId),
    );
    final Widget corps;
    if (premiere.hasValue) {
      final PageHistorique page = premiere.requireValue;
      final List<EvenementCandidature> tous = <EvenementCandidature>[
        ...page.evenements,
        ..._suite,
      ];
      final int? suivant = _curseurPose ? _curseur : page.curseurSuivant;
      corps = tous.isEmpty
          ? _Muet(r.historiqueVide)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final EvenementCandidature e in tous)
                  _LigneEvenement(evenement: e),
                if (_echecSuite != null) _Muet(r.historiqueEchec),
                if (suivant != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: LienFleche(
                      key: BlocHistorique.clePlus,
                      libelle: r.plusAnciens,
                      alignerEnDebut: true,
                      onPress: _enCours ? null : () => _plus(suivant),
                    ),
                  ),
              ],
            );
    } else if (premiere.hasError) {
      final Object? e = premiere.error;
      corps = e is CapaciteIndisponible
          ? const _Branchement()
          : EtatSysteme(
              nature: NatureEtat.echecServeur,
              titre: r.historiqueEchec,
              phrase: '',
              onAction: () => ref.invalidate(
                historiqueCandidatureProvider(widget.candidatureId),
              ),
            );
    } else {
      corps = const Skeleton.ligneTimeline(lignes: 3);
    }
    return Column(
      key: BlocHistorique.cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Titre(t.historique.titre),
        Ecart.vMd,
        AppCard(child: corps),
      ],
    );
  }
}

class _LigneEvenement extends StatelessWidget {
  const _LigneEvenement({required this.evenement});

  final EvenementCandidature evenement;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final r = t.admin.candidatures.historique;
    final String? changement = libelleChangement(evenement);
    final String? quand = evenement.quand == null
        ? null
        : instantHistorique(evenement.quand!);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TexteSansCoupure(
              libelleTypeEvenement(evenement.type),
              style: textes.titleSmall,
            ),
            if (changement != null)
              TexteSansCoupure(changement, style: textes.bodyMedium),
            TexteSansCoupure(
              <String>[
                ?quand,
                libelleAuteur(evenement.auteur),
              ].join(t.admin.candidatures.historique.separateur),
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
            if (evenement.motif != null)
              TexteSansCoupure(
                r.motif(motif: evenement.motif!),
                style: palette.inkMuted.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// La reference `CAND-…` telle qu'elle s'affiche : traits d'union insecables.
String referenceDuDossier(String reference) => identifiantInsecable(reference);
