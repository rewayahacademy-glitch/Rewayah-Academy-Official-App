// Le double du port des annonces de Classe (COM-ANN-1), en memoire, pour les
// tests du centre de notifications et de l'Espace Classe.

import 'package:rewayah_academy/core/communications/modeles_communication.dart';
import 'package:rewayah_academy/features/com_annonces/port_annonces.dart';

/// Les annonces en memoire, avec un compteur de lectures et un echec reglable.
class FauxAnnonces implements PortAnnonces {
  /// Cree le double.
  FauxAnnonces({
    this.parClasse = const <String, List<AnnonceClasse>>{},
    this.capacites = const <CapaciteAnnonces>{},
    this.erreur,
    this.echecLecture = false,
  });

  /// Les annonces, par Classe.
  Map<String, List<AnnonceClasse>> parClasse;

  /// Les capacites rendues pour chaque Classe.
  Set<CapaciteAnnonces> capacites;

  /// Leve a la lecture d'une Classe quand il est pose.
  Exception? erreur;

  /// Vrai : `marquerLue` leve.
  bool echecLecture;

  /// Le nombre de lectures d'une Classe.
  int lectures = 0;

  /// Les annonces dont la lecture a ete enregistree.
  final List<String> lues = <String>[];

  AnnonceClasse _vue(AnnonceClasse a) => lues.contains(a.id)
      ? AnnonceClasse(
          id: a.id,
          titre: a.titre,
          texte: a.texte,
          publieeLe: a.publieeLe,
          classe: a.classe,
          auteur: a.auteur,
          niveau: a.niveau,
          lue: true,
        )
      : a;

  @override
  Future<AnnoncesDeLaClasse> annoncesDeClasse(String classeId) async {
    lectures++;
    if (erreur case final Exception e) throw e;
    return AnnoncesDeLaClasse(
      annonces: <AnnonceClasse>[
        for (final AnnonceClasse a
            in parClasse[classeId] ?? const <AnnonceClasse>[])
          _vue(a),
      ],
      capacites: capacites,
    );
  }

  @override
  Future<AnnonceClasse?> annonce(String id) async {
    for (final List<AnnonceClasse> liste in parClasse.values) {
      for (final AnnonceClasse a in liste) {
        if (a.id == id) return _vue(a);
      }
    }
    return null;
  }

  @override
  Future<void> marquerLue(String annonceId) async {
    if (echecLecture) throw Exception('lecture refusee');
    lues.add(annonceId);
  }
}

/// Un texte long, qui depasse la carte a toutes les largeurs.
const String texteLong =
    'Chères familles, la Classe présentera sa récitation de fin de trimestre '
    'le samedi à 10 h, en visio. Chaque élève récitera la sourate travaillée '
    'ce trimestre. Merci de prévoir une connexion stable et un endroit calme. '
    'Les élèves qui le souhaitent peuvent répéter pendant la séance du '
    'mercredi précédent. Les familles peuvent assister en silence, micro '
    'coupé. Un compte rendu sera partagé après la séance. Fin du texte long.';

/// Une annonce de test.
AnnonceClasse annonceDeTest({
  String id = 'an1',
  String classeId = 'c1',
  String libelleClasse = 'Classe An-Nour',
  String titre = 'Récitation de fin de trimestre',
  String texte = texteLong,
  String? destination = '/tuteur/classes/c1',
  bool lue = false,
  NiveauAttention niveau = NiveauAttention.aLire,
  DateTime? publieeLe,
}) => AnnonceClasse(
  id: id,
  titre: titre,
  texte: texte,
  publieeLe: publieeLe ?? DateTime.utc(2026, 10, 3, 16),
  auteur: const Participant(
    id: 'e1',
    nomAffiche: 'Enseignante',
    fonction: 'Enseignante de la Classe',
  ),
  classe: ObjetLie(
    type: TypeObjetLie.classe,
    id: classeId,
    libelle: libelleClasse,
    destination: destination,
  ),
  lue: lue,
  niveau: niveau,
);
