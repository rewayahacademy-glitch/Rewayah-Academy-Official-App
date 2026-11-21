// PERSONNES-UNE-PAGE, etape (f) : les gestes d'un compte, sortis de la page
// « Comptes » pour servir aussi a la page unique « Personnes » (pilote,
// 21/11/2026 : l'apercu de la page unique s'ouvrait sans geste, une regression
// en production).
//
// Rien n'est reecrit : la demande d'admission, la coche « fondateur », la
// suppression (confirmation, double verification, un resultat par compte) et
// son bilan sont le code de `comptes_page.dart`, deplace ici tel quel. Les
// deux pages l'appellent ; aucune ne decide un droit (le serveur refuse).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin/personnes_modifiees.dart';
import '../../core/admin/port_fondateurs.dart';
import '../../core/admin/service_comptes.dart';
import '../../core/admission/port_admissions_direction.dart'
    show PopulationAdmission;
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/capacites/port_retraits_comptes.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/lieu/lieu_direction.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/barre_selection.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/menu_actions.dart';
import '../admin_candidature/references_dossiers.dart';
import '../mfa_controleur/double_verification.dart';
import 'liste_comptes.dart';

/// La cle du bilan d'une suppression.
const Key cleBilanSuppression = ValueKey<String>('comptes-bilan-suppression');

/// La cle de « Fermer » du bilan.
const Key cleFermerBilanSuppression = ValueKey<String>('comptes-bilan-fermer');

/// Une suppression porte sur ce nombre de comptes au plus.
const int plafondSuppressionComptes = 200;

/// Etape (f) point 2 : les profils dont on demande la reference de dossier
/// (ceux qui peuvent porter une candidature d'enseignant).
ProfilsDemandes profilsAvecDossierPossible(List<CompteAdmin> comptes) =>
    ProfilsDemandes(<String>[
      for (final CompteAdmin c in comptes)
        if (c.role == AppRole.teacher || c.role == AppRole.guardian) c.profilId,
    ]);

/// Vrai quand la ligne ouvre un dossier : celui de la candidature
/// d'enseignant quand sa reference est connue (PE-C1), sinon « Fichiers a
/// valider » pour une piece a verifier.
bool ouvreUnDossier(CompteAdmin c, Map<String, String> references) =>
    references.containsKey(c.profilId) ||
    (c.role == AppRole.teacher && c.piece == EtatPiece.aVerifier);

/// Ouvre le dossier de [c] : l'ecran du dossier (sa reference), ou « Fichiers
/// a valider » sans reference connue (l'identifiant du profil en `extra`,
/// jamais dans l'adresse).
void ouvrirDossierDuCompte(
  BuildContext context,
  CompteAdmin c,
  Map<String, String> references,
) {
  final String? reference = references[c.profilId];
  final String chemin = cheminDossierDuProfil(reference);
  unawaited(
    reference == null
        ? GoRouter.of(context).push<void>(chemin, extra: c.profilId)
        : GoRouter.of(context).push<void>(chemin),
  );
}

/// Vrai quand la ville d'un enseignant attend la verification de la direction.
bool villeAVerifier(
  CompteAdmin c,
  Map<String, LieuEnseignantDirection> lieux,
) => c.role == AppRole.teacher && (lieux[c.profilId]?.verifie ?? true) == false;

/// Marque la ville de [c] comme verifiee. Rend la phrase a dire, apres la
/// reponse du serveur.
Future<String> verifierVilleDuCompte(WidgetRef ref, CompteAdmin c) async {
  try {
    await ref.read(portLieuDirectionProvider).verifier(c.profilId);
    ref
      ..invalidate(lieuxEnseignantsProvider)
      ..invalidate(incoherencesLieuProvider);
    return t.lieu.villeVerifiee(deNom: deDevant(c.libelle));
  } on Object {
    return t.lieu.verifierEchec;
  }
}

/// Les gestes propres a un compte qui a un dossier ou une ville a verifier :
/// « Ouvrir le dossier », « Verifier la ville ».
List<EntreeAction> gestesDossierEtVille(
  BuildContext context,
  CompteAdmin c, {
  required Map<String, String> references,
  required Map<String, LieuEnseignantDirection> lieux,
  required VoidCallback onVerifierVille,
  bool dossier = true,
}) => <EntreeAction>[
  if (dossier && ouvreUnDossier(c, references))
    EntreeAction(
      // PE-C1 : le dossier du candidat quand sa reference est connue ;
      // sinon la piece a verifier, comme avant.
      libelle: references.containsKey(c.profilId)
          ? t.admin.candidatures.liste.ouvrirDossier
          : t.admin.comptes.actionOuvrirDossier,
      icone: AppIcons.dossiers,
      onChoix: () => ouvrirDossierDuCompte(context, c, references),
    ),
  if (villeAVerifier(c, lieux))
    EntreeAction(
      libelle: t.lieu.verifier(deNom: deDevant(c.libelle)),
      icone: AppIcons.controleQualite,
      onChoix: onVerifierVille,
    ),
];

/// La barre des comptes choisis : leur nombre (« dont N sur cette page »),
/// « Supprimer », jamais au-dela du plafond.
class BarreSuppressionComptes extends StatelessWidget {
  /// Cree la barre.
  const BarreSuppressionComptes({
    required this.nombre,
    required this.surLaPage,
    required this.enCours,
    required this.onRelacher,
    required this.onSupprimer,
    this.cleBarre,
    this.cleSupprimer,
    super.key,
  });

  /// Le nombre de comptes choisis.
  final int nombre;

  /// Ceux de la page affichee.
  final int surLaPage;

  /// Une suppression est partie.
  final bool enCours;

  /// Relache la selection.
  final VoidCallback onRelacher;

  /// Supprime les comptes choisis.
  final VoidCallback onSupprimer;

  /// La cle de la barre elle-meme.
  final Key? cleBarre;

  /// La cle de « Supprimer ».
  final Key? cleSupprimer;

  @override
  Widget build(BuildContext context) {
    final r = t.admin.comptes.retrait;
    return BarreSelection.compacte(
      key: cleBarre,
      titre: surLaPage == nombre
          ? r.retenus(n: nombre)
          : r.retenusPage(n: nombre, p: '$surLaPage'),
      onRelacher: onRelacher,
      operations: <Widget>[
        if (nombre <= plafondSuppressionComptes)
          ActionPrincipale(
            key: cleSupprimer,
            libelle: r.supprimerSelection(n: nombre),
            niveau: NiveauAction.destructive,
            compacte: true,
            pleineLargeur: false,
            enCours: enCours,
            // Un envoi en cours ignore le second toucher.
            onPress: onSupprimer,
          ),
      ],
    );
  }
}

/// L2 des listes (constat du directeur, 01/11/2026) : une ligne « En
/// attente » d'une demande d'admission porte l'action qui la debloque.
bool ouvreUneDemande(CompteAdmin c) => c.admissionATraiter;

/// La population de la demande d'un compte : un adulte qui apprend pour
/// lui-meme, sans enfant au foyer, est un eleve adulte ; sinon, une
/// famille. La page des demandes garde le nom cherche si l'on change de
/// population.
PopulationAdmission populationDeLaDemande(CompteAdmin c) =>
    c.role == AppRole.guardian && c.apprenant && c.enfantsDuFoyer == 0
    ? PopulationAdmission.eleveAdulte
    : PopulationAdmission.famille;

/// SUPPRIMER : un compte d'eleve, de tuteur ou d'enseignant se supprime ici.
/// Un compte de la direction, ou de role illisible, jamais (le serveur
/// refuse aussi : `compte_direction`).
bool compteSupprimable(CompteAdmin c) => switch (c.role) {
  AppRole.student || AppRole.guardian || AppRole.teacher => true,
  AppRole.admin ||
  AppRole.accountant ||
  AppRole.associe ||
  AppRole.controller ||
  null => false,
};

/// V2-e (directeur, 03/11/2026) : la coche « fondateur », tenue par la
/// direction, sur un membre du personnel au compte actif, dans les vues
/// Direction et Enseignants. Proposee seulement quand le serveur a rendu
/// les fondateurs : sans eux, la ligne ne saurait pas quoi proposer.
bool porteLaCocheFondateur(
  CompteAdmin c,
  VueComptes vue,
  Set<String>? fondateurs,
) =>
    fondateurs != null &&
    (vue == VueComptes.direction || vue == VueComptes.enseignants) &&
    c.etat == AccountStatus.active &&
    (c.role == AppRole.admin ||
        c.role == AppRole.teacher ||
        c.role == AppRole.accountant ||
        c.role == AppRole.controller);

/// Coche ou decoche [c]. Rend la phrase a dire (reussite ou refus), ou `null`
/// sans port : rien n'a ete tente.
Future<String?> poserFondateur(
  WidgetRef ref,
  CompteAdmin c, {
  required bool fondateur,
}) async {
  final PortFondateurs? port = ref.read(portFondateursProvider);
  if (port == null) return null;
  try {
    await port.poser(c.profilId, fondateur: fondateur);
    ref.invalidate(fondateursProvider);
    return fondateur
        ? t.admin.comptes.fondateurMarque(nom: c.libelle)
        : t.admin.comptes.fondateurRetire(nom: c.libelle);
  } on FondateurRefuse catch (e) {
    return switch (e.motif) {
      MotifFondateurRefuse.nonAutorise =>
        t.admin.comptes.fondateurRefuseDirection,
      MotifFondateurRefuse.personnelInactif =>
        t.admin.comptes.fondateurRefuseInactif,
      MotifFondateurRefuse.inconnu => t.admin.comptes.fondateurRefuseInconnu,
    };
  } on Object {
    return t.admin.comptes.fondateurRefuseInconnu;
  }
}

/// Les gestes d'un compte, ceux du menu de sa ligne et de son apercu : les
/// memes, dans le meme ordre, le destructif en dernier.
///
/// [fondateur] : `null` quand la coche n'est pas proposee, sinon l'etat
/// courant. [onSupprimer] : `null` quand la suppression n'est pas offerte.
/// [propres] : les gestes propres a la page (ouvrir le dossier, verifier la
/// ville), places apres la demande.
List<EntreeAction> gestesDuCompte(
  BuildContext context,
  CompteAdmin c, {
  required bool? fondateur,
  required void Function({required bool fondateur}) onFondateur,
  required VoidCallback? onSupprimer,
  List<EntreeAction> propres = const <EntreeAction>[],
}) => <EntreeAction>[
  if (ouvreUneDemande(c))
    EntreeAction(
      libelle: t.admin.comptes.actionVoirDemande,
      icone: AppIcons.dossiers,
      // La demande de cette personne : son nom, en `extra`, jamais dans
      // l'adresse (§5.9).
      onChoix: () => GoRouter.of(context).push<void>(
        Routes.adminPersonnesAdmissions,
        extra: (population: populationDeLaDemande(c), recherche: c.libelle),
      ),
    ),
  ...propres,
  if (fondateur != null)
    if (fondateur)
      EntreeAction(
        libelle: t.admin.comptes.actionRetirerFondateur,
        icone: AppIcons.etoile,
        onChoix: () => onFondateur(fondateur: false),
      )
    else
      EntreeAction(
        libelle: t.admin.comptes.actionMarquerFondateur,
        icone: AppIcons.etoile,
        onChoix: () => onFondateur(fondateur: true),
      ),
  // Le destructif en dernier, separe (MenuActions).
  if (onSupprimer != null)
    EntreeAction(
      libelle: t.admin.comptes.retrait.actionLigne,
      destructif: true,
      onChoix: onSupprimer,
    ),
];

/// Supprime [comptes] apres une confirmation qui dit leur nombre. Le serveur
/// rend un resultat par compte ; les listes de personnes sont relues dans tous
/// les cas (une reponse perdue apres la suppression ne doit pas laisser une
/// ligne qui n'existe plus).
///
/// Rend `null` quand la personne renonce, sinon le bilan a montrer. [onDebut]
/// est rappele juste avant l'envoi (la page montre alors l'attente).
Future<BilanSuppression?> supprimerComptes(
  BuildContext context,
  WidgetRef ref,
  List<CompteAdmin> comptes, {
  VoidCallback? onDebut,
}) async {
  if (comptes.isEmpty) return null;
  final r = t.admin.comptes.retrait;
  final bool un = comptes.length == 1;
  final CompteAdmin premier = comptes.first;
  final String? nomDuCompte = un ? premier.libelle : null;
  final bool oui = await ConfirmDestructive.demander(
    context,
    question: nomDuCompte != null
        ? r.questionUn(
            deNom: deDevant(
              nomDuCompte,
              cle: 'admin.comptes.retrait.questionUn',
            ),
          )
        : r.questionPlusieurs(n: comptes.length),
    consequence: r.consequence,
    libelleConfirmer: un
        ? r.confirmerUn
        : r.supprimerSelection(n: comptes.length),
    libelleAnnuler: r.rester,
  );
  if (!oui || !context.mounted) return null;
  if (ref.read(horsLigneProvider).value ?? false) {
    return BilanSuppression.message(r.horsLigne, avantEnvoi: true);
  }
  onDebut?.call();
  BilanSuppression bilan;
  try {
    // MFA-DIRECTION : en aal1, le code est demande puis le geste rejoue.
    final List<String> ids = <String>[
      for (final CompteAdmin c in comptes) c.profilId,
    ];
    final List<ResultatRetrait> resultats = await avecDoubleVerification(
      context,
      ref,
      () => ref.read(portRetraitsComptesProvider).retirer(ids),
    );
    bilan = BilanSuppression.depuis(resultats, comptes);
  } on PermissionInsuffisante {
    bilan = BilanSuppression.message(r.refuse);
  } on CapaciteIndisponible {
    bilan = BilanSuppression.message(r.indisponible);
  } on Object {
    bilan = BilanSuppression.message(
      (ref.read(horsLigneProvider).value ?? false) ? r.horsLigne : r.echec,
    );
  }
  // D2 : toutes les listes de personnes sont relues, pas seulement
  // celle-ci ; le signal part apres la reponse du serveur (geste sensible).
  ref.read(personnesModifieesProvider.notifier).signaler();
  return bilan;
}

/// Ce que la derniere suppression a donne : les comptes supprimes, et pour
/// chaque refus, le nom et la raison (un resultat par compte, rendu par le
/// serveur) ; ou un seul message quand rien n'est parti ou rien n'est sur.
class BilanSuppression {
  /// Cree le bilan d'une suppression partie.
  const BilanSuppression({required this.supprimes, required this.refus})
    : message = null,
      alerte = false,
      avantEnvoi = false;

  /// Un seul message : rien n'est parti, ou rien n'est sur.
  const BilanSuppression.message(
    String this.message, {
    this.alerte = true,
    this.avantEnvoi = false,
  }) : supprimes = 0,
       refus = const <String>[];

  /// Le bilan lu dans les resultats du serveur, un par compte.
  factory BilanSuppression.depuis(
    List<ResultatRetrait> resultats,
    List<CompteAdmin> comptes,
  ) {
    final r = t.admin.comptes.retrait;
    String nomDe(String id) {
      for (final CompteAdmin c in comptes) {
        if (c.profilId == id) return c.libelle;
      }
      return id;
    }

    String raison(ResultatRetrait x) => switch (x.raison) {
      RaisonRefusRetrait.introuvable => r.raison.introuvable,
      RaisonRefusRetrait.dejaRetire => r.raison.dejaRetire,
      RaisonRefusRetrait.soiMeme => r.raison.soiMeme,
      RaisonRefusRetrait.compteDirection => r.raison.compteDirection,
      RaisonRefusRetrait.seancesAVenir => r.raison.seancesAVenir(
        n: x.seancesAVenir,
      ),
      _ => r.raison.erreur,
    };

    return BilanSuppression(
      supprimes: resultats.where((ResultatRetrait x) => x.retire).length,
      refus: <String>[
        for (final ResultatRetrait x in resultats)
          if (!x.retire) r.raisonLigne(nom: nomDe(x.id), raison: raison(x)),
      ],
    );
  }

  /// Le nombre de comptes supprimes.
  final int supprimes;

  /// Une phrase par compte refuse : son nom et la raison.
  final List<String> refus;

  /// Le message seul, ou `null`.
  final String? message;

  /// Le [message] dit un echec (encre d'alerte) ; sinon une information.
  final bool alerte;

  /// Vrai quand rien n'est parti au serveur (hors connexion avant l'envoi) :
  /// la selection de la page reste.
  final bool avantEnvoi;
}

/// Le bilan d'une suppression, dans le fil de la page, avec « Fermer ».
class VueBilanSuppression extends StatelessWidget {
  /// Cree la vue de [bilan].
  const VueBilanSuppression({
    required this.bilan,
    required this.onFermer,
    super.key,
  });

  /// Le bilan a dire.
  final BilanSuppression bilan;

  /// Ferme le bilan.
  final VoidCallback onFermer;

  @override
  Widget build(BuildContext context) {
    final r = t.admin.comptes.retrait;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle corps =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final String? message = bilan.message;
    return Semantics(
      liveRegion: true,
      child: Column(
        key: cleBilanSuppression,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (message != null)
            Text(
              message,
              style: (bilan.alerte ? palette.inkAlert : palette.inkStrong)
                  .applyTo(corps),
            ),
          if (bilan.supprimes > 0)
            Text(
              r.supprimes(n: bilan.supprimes),
              style: palette.inkStrong.applyTo(corps),
            ),
          if (bilan.refus.isNotEmpty) ...<Widget>[
            if (bilan.supprimes > 0) Ecart.vSm,
            BandeauAttention(
              titre: r.nonSupprimes(n: bilan.refus.length),
              message: bilan.refus.join('\n'),
            ),
          ],
          Ecart.vSm,
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ActionPrincipale(
              key: cleFermerBilanSuppression,
              libelle: t.commun.fermer,
              niveau: NiveauAction.tertiaire,
              compacte: true,
              pleineLargeur: false,
              onPress: onFermer,
            ),
          ),
        ],
      ),
    );
  }
}
