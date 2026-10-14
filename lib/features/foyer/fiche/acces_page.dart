import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/capacites/port_acces_foyer.dart';
import '../../../core/finance/finances_profil.dart';
import '../../../core/foyer/selection_eleve.dart';
import '../../../core/i18n/elision.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/bandeau_attention.dart';
import '../../../core/widgets/pastille_financiere.dart';
import '../../../core/widgets/status_pill.dart';
import '../../acces_finance/acces_finance.dart';
import '../fiche_eleve_page.dart';
import '../foyer_page.dart';
import '../ligne_membre.dart';

/// L'acces Rewayah d'un profil eleve (`/tuteur/foyer/:eleveId/acces`).
///
/// Rendu de la carte « Abonnement et acces » du Compte haute fidelite
/// (manifeste visuel, section 2) : medaillon, statut en pastille, echeance
/// reelle. Jamais « abonnement » : un acces date n'est pas un paiement.
///
/// Source : `profils_du_foyer_v.access_until`, la meme que la ligne du Foyer
/// (aucune contradiction entre les deux ecrans). « Expire » est un **calcul
/// d'affichage** (`etatAccesAffiche`, contrat K6) : une date passee ne se dit
/// jamais valide. Le debut, le statut detaille et le motif n'existent pas
/// encore cote serveur (DB-FOY-05) : l'ecran le dit une fois, sans inventer
/// de motif.
///
/// FI-9a (guide §1.2, §1.7) : quand la finance du profil dit « a
/// regulariser », la carte porte la pastille « À régulariser » et la fin de
/// conservation de la place, et le bandeau « Accès à régulariser » dit le
/// manque exact ; pendant l'essai, la pastille dit « Essai : n/2 ». Sans
/// finance lue (chargement, echec, production), la carte reste celle de
/// l'echeance : rien n'est invente. Seances fermees sans « a regulariser »
/// (essais epuises, FIN4-13) : le bandeau dit le manque quand la finance le
/// rend, sinon une phrase neutre (revue FI-9a).
class AccesElevePage extends StatelessWidget {
  /// Cree la page.
  const AccesElevePage({required this.eleveId, super.key});

  /// L'eleve concerne.
  final String eleveId;

  /// La carte d'acces (un seul rectangle).
  static const Key carteKey = Key('ficheEleve.acces.carte');

  /// Le medaillon de la carte.
  static const Key medaillonKey = Key('ficheEleve.acces.medaillon');

  /// Le bandeau « Accès à régulariser ».
  static const Key bandeauKey = Key('ficheEleve.acces.regulariser');

  /// Le bandeau neutre des seances fermees sans manque rendu.
  static const Key bandeauFermeKey = Key('ficheEleve.acces.fermees');

  /// La pastille « Suspendu » d'une place liberee (FI-BR-08).
  static const Key pastilleSuspenduKey = Key('ficheEleve.acces.suspendu');

  @override
  Widget build(BuildContext context) {
    return PageFiche(
      eleveId: eleveId,
      titre: t.ficheEleve.acces.titre,
      onRetour: retourVersFiche(context, eleveId),
      construire: (BuildContext context, ProfilEleveFoyer profil) =>
          _Acces(profil: profil),
    );
  }
}

class _Acces extends ConsumerWidget {
  const _Acces({required this.profil});

  final ProfilEleveFoyer profil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime maintenant = ref.watch(horlogeFoyerProvider)();
    final DateTime? fin = profil.finAcces;
    final EtatAccesAffiche etat = etatAccesAffiche(
      finAcces: fin,
      maintenantUtc: maintenant.toUtc(),
    );
    final FinancesProfil? finances = ref
        .watch(financesProfilProvider(profil.eleveId))
        .value;
    final bool regulariser = aRegulariser(finances);
    final AccesBeneficiaire? acces = ref
        .watch(accesEleveProvider(profil.eleveId))
        .value;
    final String? essai = libelleEssai(acces);
    // Seances fermees sans etat « a regulariser » (revue FI-9a) : essais
    // epuises (2/2) avant la premiere periode financee (FIN4-13). L'enfant lit
    // sa copie neutre ; le tuteur lit la cause utile des que la finance rend
    // un manque, sinon une phrase neutre qui dit l'etat sans l'inventer.
    final bool fermeSansRegulariser =
        !regulariser && ouvertureSeances(acces) == OuvertureSeances.fermees;
    final bool causeRendue =
        regulariser || (fermeSansRegulariser && finances?.manque != null);
    // L'etat de la place rendu par la source (FI-BR-08) : la place liberee
    // passe avant tout, elle dit ce qui a change ; la reactivation ne
    // masque ni un nouveau manque ni des seances de nouveau fermees.
    final BandeauPlace? place = BandeauPlace.pour(acces, prenom: profil.prenom);
    final Widget? bandeau = acces?.place == EtatPlace.liberee
        ? place
        : causeRendue
        ? BandeauAttention(
            key: AccesElevePage.bandeauKey,
            titre: t.argent.acces.regulariserTitre,
            message: messageRegularisation(finances!),
          )
        : !fermeSansRegulariser
        ? place
        : BandeauAttention(
            key: AccesElevePage.bandeauFermeKey,
            titre: t.argent.acces.seancesFermeesTitre,
            message: t.argent.acces.seancesFermees(prenom: profil.prenom),
            ton: TonEtat.accent,
          );
    final (String pastille, TonEtat ton, String legende) = switch (etat) {
      EtatAccesAffiche.sansEcheance => (
        t.ficheEleve.acces.pastilleSansEcheance,
        TonEtat.neutre,
        t.ficheEleve.acces.sansEcheance,
      ),
      EtatAccesAffiche.actif => (
        t.ficheEleve.acces.pastilleEnCours,
        TonEtat.succes,
        t.ficheEleve.acces.jusquau(date: dateEcheance(fin!)),
      ),
      EtatAccesAffiche.expire => (
        t.ficheEleve.acces.pastilleExpire,
        TonEtat.alerte,
        t.ficheEleve.acces.expireDepuis(date: dateEcheance(fin!)),
      ),
    };

    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    // L'en-tete de la carte « Abonnement et acces » du Compte : medaillon,
    // titre, echeance reelle, pastille a droite, dans UN rectangle.
    final Widget carte = SurfaceFiche(
      key: AccesElevePage.carteKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ExcludeSemantics(
            child: SizedBox.square(
              key: AccesElevePage.medaillonKey,
              dimension: AppTouchTarget.standard,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.washAccent.background,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    palette.contourCarte.asBorderSide(),
                  ),
                ),
                child: IconTheme(
                  data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
                  child: Icon(AppIcons.verrou.repos),
                ),
              ),
            ),
          ),
          Ecart.hLg,
          Expanded(
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      t.ficheEleve.acces.ligne(
                        dePrenom: deDevant(profil.prenom),
                      ),
                      style: palette.inkStrong.applyTo(
                        textes.titleMedium ?? const TextStyle(),
                      ),
                    ),
                    Ecart.vXs,
                    Text(
                      (regulariser ? phraseConservation(finances!) : null) ??
                          legende,
                      style: palette.inkMuted.applyTo(
                        textes.bodyMedium ?? const TextStyle(),
                      ),
                    ),
                  ],
                ),
                if (acces?.place == EtatPlace.liberee)
                  StatusPill(
                    key: AccesElevePage.pastilleSuspenduKey,
                    libelle: t.argent.acces.pastilleSuspendu,
                    ton: TonEtat.avertissement,
                  )
                else if (regulariser)
                  const PastilleFinanciere(etat: EtatFinancier.aRegulariser)
                else if (essai != null)
                  StatusPill(
                    libelle: essai,
                    ton: PastilleFinanciere.tonDe(EtatFinancier.essai),
                  )
                else
                  StatusPill(libelle: pastille, ton: ton),
              ],
            ),
          ),
        ],
      ),
    );

    return ColonnesFiche(
      principal: bandeau == null
          ? carte
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[bandeau, Ecart.vLg, carte],
            ),
      annexe: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // A regulariser, l'eleve garde son compte et sa place (guide
          // §1.7) : « ne peut plus entrer dans Rewayah » serait faux.
          if (etat == EtatAccesAffiche.expire && !regulariser)
            NoteFiche(t.ficheEleve.acces.expirePhrase(prenom: profil.prenom)),
          NoteFiche(t.ficheEleve.acces.detailIndisponible),
        ],
      ),
    );
  }
}
