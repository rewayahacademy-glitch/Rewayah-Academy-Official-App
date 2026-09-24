import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/capacites/port_acces_foyer.dart';
import '../../../core/foyer/selection_eleve.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/widgets/groupe_reglages.dart';
import '../../../core/widgets/status_pill.dart';
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
class AccesElevePage extends StatelessWidget {
  /// Cree la page.
  const AccesElevePage({required this.eleveId, super.key});

  /// L'eleve concerne.
  final String eleveId;

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

    return ColonnesFiche(
      principal: GroupeReglages(
        lignes: <LigneRubrique>[
          LigneRubrique(
            icone: AppIcons.verrou,
            libelle: t.ficheEleve.acces.ligne(prenom: profil.prenom),
            legende: legende,
            controle: StatusPill(libelle: pastille, ton: ton),
          ),
        ],
      ),
      annexe: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (etat == EtatAccesAffiche.expire)
            NoteFiche(t.ficheEleve.acces.expirePhrase(prenom: profil.prenom)),
          NoteFiche(t.ficheEleve.acces.detailIndisponible),
        ],
      ),
    );
  }
}
