import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/candidature/modeles_candidature.dart';
import '../../core/dossier/etat_dossier.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/session/deconnexion.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../candidature/portail_candidature.dart';
import '../connexion/recuperation_page.dart'
    show IssueEnvoiLien, issueEchecEnvoi;
import '../inscription/brouillon_inscription.dart';
import '../partage_offre/tuile_partage.dart';
import '../talents/tuile_talents.dart';

/// `TUT-00b` : le portail d'attente, refondu (05 section A, sous-paquet 3).
///
/// **Le statut exact et UNE prochaine action**, jamais des cartes empilees ni
/// plusieurs boutons pleins : les pieces manquantes sont listees en une carte
/// groupee, sans bouton par ligne, et la seule action pleine ouvre la premiere
/// d'entre elles. La deconnexion reste toujours possible, en action discrete.
///
/// Lot E6 (decision du directeur du 17/10/2026) : le portail ne fait plus
/// que montrer l'etat. L'accuse et le contrat ne s'ouvrent plus un a un : une
/// seule action, « Lire et accepter nos conditions », mene a la page unique
/// des accords (`/attente/accords`).
///
/// Quatre etats, calcules en base par `etat_dossier()` et non ici : le portail
/// doit dire exactement ce que l'administration voit, et deux calculs finissent
/// toujours par diverger.
class AttentePage extends ConsumerStatefulWidget {
  /// Cree le portail d'attente.
  const AttentePage({super.key});

  @override
  ConsumerState<AttentePage> createState() => _AttentePageState();
}

class _AttentePageState extends ConsumerState<AttentePage> {
  /// Relit l'etat au retour dans l'application (P-ADM-11.1) : aucun signal
  /// serveur n'existe (AD-BR-26), la relecture est le seul moyen honnete de
  /// voir une decision prise pendant l'absence.
  late final AppLifecycleListener _cycle;

  @override
  void initState() {
    super.initState();
    _cycle = AppLifecycleListener(onResume: () => unawaited(_relire()));
  }

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }

  /// Relit le dossier puis la session : un compte devenu actif est alors
  /// redirige par la garde existante vers la racine de son role.
  Future<void> _relire() async {
    ref.invalidate(etatDossierProvider);
    await ref.read(sourceSessionProvider).rafraichir();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<EtatDossier> etat = ref.watch(etatDossierProvider);
    final GoRouter? routeur = GoRouter.maybeOf(context);
    // Un profil sans role lisible ne se devine ni tuteur ni enseignant : il
    // se dit illisible, avec Reessayer, plutot que de demander une piece.
    final EtatDossier? lu = etat.hasValue && !etat.requireValue.roleIllisible
        ? etat.requireValue
        : null;
    final bool illisible = lu == null && (etat.hasError || etat.hasValue);

    // TUT-00b etendu : une candidature dit ou elle en est. En Salle d'examen,
    // ou apres un refus ou un retrait, le portail montre son etat a elle ; en
    // Salle de verification et d'entretien, les accords, la piece et la
    // verification gardent leurs ecrans sous l'en-tete de la salle.
    final bool vueCand = lu != null && vueCandidature(lu);
    final CandidatureDossier? candidature = lu != null && lu.candidature.existe
        ? lu.candidature
        : null;
    final ({String libelle, String chemin})? actionCand = vueCand
        ? prochaineCandidature(lu.candidature)
        : null;

    // Les getters, jamais le type d'execution : Riverpod 3 relance un provider
    // en echec tout seul, et l'etat repasse alors par `AsyncLoading` en
    // conservant `hasError`.
    final _Prochaine? prochaine = vueCand
        ? (actionCand == null
              ? null
              : _Prochaine.vers(actionCand.libelle, actionCand.chemin))
        : lu != null
        ? _prochaine(
            lu,
            // L5-01 : l'usage garde par le serveur d'abord ; le brouillon
            // ne sert qu'aux comptes crees avant.
            adulte: switch (lu.usage) {
              UsageTitulaire.moi => true,
              UsageTitulaire.famille => false,
              null =>
                ref.watch(brouillonInscriptionProvider).usage ==
                    UsageInscription.moi,
            },
          )
        : illisible
        ? _Prochaine(
            t.commun.reessayer,
            () => ref.invalidate(etatDossierProvider),
          )
        : null;

    // « Actualiser » : une candidature qui attend la direction (examen, pause,
    // versement pas encore possible), ou, hors candidature, les deux etats
    // d'attente d'aujourd'hui. Un `case` pose apres un ternaire ne portait que
    // sur son resultat entier : « Actualiser » ne se montrait jamais a un
    // candidat.
    final bool actualisable = vueCand
        ? candidature!.issue == IssueCandidature.enCours &&
              !candidature.questionnaireOuvert
        : lu?.etape == EtapeDossier.enVerification ||
              lu?.etape == EtapeDossier.accesEnPreparation;

    return PageShell(
      // K-47 : un tuteur n'a pas de dossier a faire verifier, seulement un
      // compte a ouvrir.
      titre: lu?.estTuteur ?? false
          ? t.attente.titreCompte
          : t.attente.titreDossier,
      // HL-A-5 : le pied ne garde que Se deconnecter ; la prochaine action
      // se place 16 sous la carte d'etat qu'elle confirme.
      actions: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // CAND-03 : le retrait est un lien discret, tant qu'il est permis.
          if (candidature != null && candidature.peutRetirer) ...<Widget>[
            LienRetraitCandidature(candidature: candidature),
            Ecart.vXs,
          ],
          ActionPrincipale(
            libelle: t.attente.seDeconnecter,
            onPress: () => unawaited(seDeconnecter(context, ref)),
            niveau: NiveauAction.tertiaire,
          ),
        ],
      ),
      // AD-NETTOYAGE-2 (m6, m8) : une seule tete (le titre de la page ; la
      // carte d'etat porte le sien) et une colonne bornee comme la politique
      // KYC, sans etirer la carte a 1140 sur bureau.
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // En-tete de la salle, pour les etats qui gardent leurs ecrans.
              if (candidature != null &&
                  !vueCand &&
                  lu!.etape != EtapeDossier.suspendu) ...<Widget>[
                EnteteSalle(candidature: candidature),
                Ecart.vMd,
              ],
              AppCard(
                child: vueCand
                    ? StatutCandidature(candidature: lu.candidature)
                    : lu != null
                    ? _Statut(etat: lu)
                    : illisible
                    ? _Illisible(erreur: etat.error ?? const FormatException())
                    : const _Patience(),
              ),
              // HL-A-5 (DESIGN-GOV B) : les actions rattachees a la carte d'etat
              // se placent 16 sous elle, au bord de fin, et non dans le pied ;
              // pleine largeur sur mobile, largeur naturelle au-dela.
              if (prochaine != null) ...<Widget>[
                Ecart.vLg,
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  // IntrinsicWidth au-dela du mobile : le Container centre
                  // d'ActionPrincipale s'etirerait sinon (meme remede que 02B).
                  child: _AuContenu(
                    actif: AppGabarit.de(context) != Gabarit.mobile,
                    child: ActionPrincipale(
                      libelle: prochaine.libelle,
                      onPress: prochaine.chemin != null
                          ? () => routeur?.go(prochaine.chemin!)
                          : prochaine.geste,
                      fleche: prochaine.chemin != null,
                      pleineLargeur: AppGabarit.de(context) == Gabarit.mobile,
                    ),
                  ),
                ),
              ],
              // Apres l'envoi, les reponses se relisent (lecture seule de
              // CAND-01) : sans ce lien, la page n'avait aucune entree.
              if (vueCand && candidature!.reponsesRelisibles) ...<Widget>[
                Ecart.vMd,
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: LienFleche(
                    key: const ValueKey<String>('portail-relire'),
                    libelle: t.recrutement.portail.relire,
                    alignerEnDebut: true,
                    onPress: () => routeur?.go(Routes.attenteCandidature),
                  ),
                ),
              ],
              if (actualisable) ...<Widget>[
                Ecart.vLg,
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  // AD-NETTOYAGE-2 (m7) : sans IntrinsicWidth, le Container centre
                  // d'ActionPrincipale s'etire et le bouton se centre.
                  child: _AuContenu(
                    actif: true,
                    child: ActionPrincipale(
                      libelle: lu!.estTuteur
                          ? t.attente.actualiserCompte
                          : t.attente.actualiser,
                      onPress: () => unawaited(_relire()),
                      niveau: NiveauAction.tertiaire,
                      pleineLargeur: false,
                    ),
                  ),
                ),
              ],
              // CAND-06 : « Aidez une personne a apprendre la parole d'Allah. »,
              // facultatif.
              // Pour qui candidate encore (pas apres un refus ni un retrait),
              // sous l'etat et sa prochaine action, jamais avant.
              if (candidature != null &&
                  candidature.issue == IssueCandidature.enCours)
                const TuilePartageOffre(),
              // CAND-07 : « Vos autres talents », facultatif, sous la tuile de
              // partage. Le serveur dit si elle s'ouvre (apres l'envoi de la
              // candidature) ou s'il reste des reponses a relire ou a retirer
              // (candidature terminee) : sinon rien n'est rendu.
              if (candidature != null) const TuileTalents(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le bouton a sa largeur naturelle quand [actif].
class _AuContenu extends StatelessWidget {
  const _AuContenu({required this.actif, required this.child});

  final bool actif;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      actif ? IntrinsicWidth(child: child) : child;
}

/// La prochaine action : une route, ou un geste (reessayer).
class _Prochaine {
  const _Prochaine(this.libelle, this.geste) : chemin = null;
  const _Prochaine.vers(this.libelle, String this.chemin) : geste = null;

  final String libelle;
  final String? chemin;
  final VoidCallback? geste;
}

/// Ce qui reste a faire, tel que le portail le montre : les accords (accuse,
/// contrat et, pour l'enseignant, code de conduite : une seule page depuis le
/// lot E6), puis la piece d'identite.
enum _Element {
  /// Les accords a lire et a accepter, sur `/attente/accords`.
  accords,

  /// La piece d'identite a deposer (enseignant).
  piece,
}

/// Les elements restants, dans l'ordre : l'accuse, le contrat et le code de
/// conduite se lisent et s'acceptent ensemble, sur une seule page
/// (DECISION-ENTREE du 17/10/2026 ; CAND-Q15 pour le code de conduite).
List<_Element> _elements(EtatDossier etat) {
  final List<PieceManquante> manquants = etat.manquants;
  return <_Element>[
    if (manquants.contains(PieceManquante.accuse) ||
        manquants.contains(PieceManquante.contrat) ||
        manquants.contains(PieceManquante.codeConduite))
      _Element.accords,
    if (manquants.contains(PieceManquante.pieceIdentite)) _Element.piece,
  ];
}

/// `adulte` : l'inscription vient de « Moi uniquement » (eleve adulte, son
/// propre tuteur) ; les accords s'ouvrent alors en variante eleve adulte
/// (`?pour=moi`). L'usage vient du serveur (L5-01) ; pour un compte cree
/// avant, du brouillon, et sans brouillon, variante responsable legal.
_Prochaine? _prochaine(EtatDossier etat, {required bool adulte}) {
  final List<_Element> restants = _elements(etat);
  return switch (etat.etape) {
    EtapeDossier.incomplet when restants.isNotEmpty => _Prochaine.vers(
      _action(restants.first),
      _chemin(restants.first, adulte: adulte),
    ),
    // « Corriger » mene au premier element a corriger (P-ADM-09.2) : la piece
    // refusee figure dans manquants, apres les accords.
    EtapeDossier.refuse
        when etat.correctionAutorisee != false && restants.isNotEmpty =>
      _Prochaine.vers(
        t.attente.corriger,
        _chemin(restants.first, adulte: adulte),
      ),
    _ => null,
  };
}

String _libelle(_Element element) => switch (element) {
  _Element.accords => t.attente.nosConditions,
  _Element.piece => t.attente.pieceIdentite,
};

String _action(_Element element) => switch (element) {
  _Element.accords => t.attente.lireEtAccepter,
  _Element.piece => t.attente.deposerLaPiece,
};

String _chemin(_Element element, {required bool adulte}) => switch (element) {
  _Element.accords =>
    adulte ? '${Routes.attenteAccords}?pour=moi' : Routes.attenteAccords,
  _Element.piece => Routes.attentePiece,
};

AppIcon _icone(_Element element) => switch (element) {
  _Element.accords => AppIcons.cahier,
  _Element.piece => AppIcons.dossiers,
};

String _etat(_Element element) => switch (element) {
  _Element.accords => t.attente.etatAAccepter,
  _Element.piece => t.attente.etatAFournir,
};

class _Statut extends StatelessWidget {
  const _Statut({required this.etat});

  final EtatDossier etat;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    final List<_Element> restants = _elements(etat);
    return switch (etat.etape) {
      EtapeDossier.incomplet => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            etat.estTuteur
                ? t.attente.accordsARelire
                : t.attente.dossierIncomplet,
            style: textes.headlineSmall,
          ),
          // E11 : « Il reste N elements a fournir » ne se dit qu'a qui doit
          // fournir une piece ; le tuteur n'a que des accords a accepter.
          if (!etat.estTuteur) ...<Widget>[
            Ecart.vMd,
            Text(t.attente.reste(n: restants.length), style: textes.bodyMedium),
          ],
          if (restants.isNotEmpty) ...<Widget>[
            Ecart.vXl,
            GroupeReglages(
              titre: etat.estTuteur ? null : t.attente.aFournir,
              lignes: <LigneRubrique>[
                for (final _Element element in restants)
                  LigneRubrique(
                    icone: _icone(element),
                    libelle: _libelle(element),
                    valeur: _etat(element),
                  ),
              ],
            ),
            Ecart.vXl,
            Text(
              t.attente.prochaineEtape(etape: _libelle(restants.first)),
              style: textes.titleMedium,
            ),
          ],
        ],
      ),
      EtapeDossier.enVerification => _Bloc(
        titre: t.attente.titre,
        message: t.attente.enVerification,
        detail: <String>[
          if (etat.deposeLe != null)
            t.attente.deposeLe(date: _date(etat.deposeLe!)),
          t.attente.delai,
        ].join('\n'),
        icone: AppIcons.dossiers,
      ),
      // K-47 (HL-A-6) : l'etat honnete du tuteur tant que le serveur le fait
      // naitre en attente (BR-1) : ni piece, ni verification, ni delai. Rien
      // n'est promis « en cours » : aucun ecran admin ne l'ouvre avant BR-1,
      // la sortie est de joindre l'academie (comme l'etat suspendu).
      EtapeDossier.accesEnPreparation => _Bloc(
        titre: t.attente.accesTitre,
        message: t.attente.accesEnPreparation,
        detail: <String>[
          t.attente.aucunDocument,
          t.attente.accesContact,
        ].join('\n'),
        icone: AppIcons.foyer,
      ),
      EtapeDossier.refuse => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.attente.refuse, style: textes.headlineSmall),
          Ecart.vMd,
          // La base refuse un verdict negatif sans motif : cette phrase existe
          // toujours quand on arrive ici.
          Text(etat.motifRefus ?? '', style: textes.bodyLarge),
          Ecart.vMd,
          // La phrase suit le premier element a corriger, celui que « Corriger »
          // ouvre (P-ADM-09.2) ; sans element, la sortie est de joindre
          // l'academie (K-47 : seul l'enseignant passe par ce refus).
          Text(
            etat.correctionAutorisee == false
                ? t.attente.correctionImpossible
                : restants.isEmpty
                ? t.attente.refuseSansElement
                : t.attente.refuseDetail(element: _libelle(restants.first)),
            style: textes.bodyMedium,
          ),
        ],
      ),
      EtapeDossier.suspendu => _Bloc(
        titre: t.attente.suspendu,
        message: t.attente.suspenduDetail,
        icone: AppIcons.avertissement,
        alerte: true,
        detail: t.attente.contacterAcademie,
      ),
    };
  }
}

/// Un etat sans action, en un bloc centre.
class _Bloc extends StatelessWidget {
  const _Bloc({
    required this.titre,
    required this.message,
    required this.icone,
    this.detail,
    this.alerte = false,
  });

  final String titre;
  final String message;
  final String? detail;
  final AppIcon icone;
  final bool alerte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        IconTheme(
          data: alerte
              ? palette.inkAlert.asIconTheme(size: AppSpacing.xxxl * 2)
              : palette.inkAccent.asIconTheme(size: AppSpacing.xxxl * 2),
          child: Icon(icone.repos),
        ),
        Ecart.vXl,
        Text(titre, textAlign: TextAlign.center, style: textes.headlineSmall),
        Ecart.vMd,
        Text(message, textAlign: TextAlign.center, style: textes.bodyMedium),
        if (detail != null) ...<Widget>[
          Ecart.vMd,
          Text(detail!, textAlign: TextAlign.center, style: textes.bodySmall),
        ],
      ],
    );
  }
}

class _Patience extends StatelessWidget {
  const _Patience();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
    child: Skeleton.liste(lignes: 3),
  );
}

/// Un etat de dossier illisible ne se devine pas : on le dit (hors ligne ou
/// non), et l'unique action est de reessayer.
class _Illisible extends StatelessWidget {
  const _Illisible({required this.erreur});

  final Object erreur;

  @override
  Widget build(BuildContext context) {
    final bool horsLigne = issueEchecEnvoi(erreur) == IssueEnvoiLien.horsLigne;
    return Semantics(
      liveRegion: true,
      child: Text(
        horsLigne ? t.attente.horsLigne : t.attente.illisible,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

String _date(DateTime quand) =>
    '${quand.day.toString().padLeft(2, '0')}/'
    '${quand.month.toString().padLeft(2, '0')}/${quand.year}';
