// Les quatorze candidatures fictives des captures de la refonte des listes
// (LISTES-1, 23/10/2026) : memes donnees que `adm20_capture_test.dart`, pour
// que les captures « avant » et « apres » se comparent ligne a ligne.
// Aucune personne reelle.

import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';

import '../fixtures/candidature/faux_candidatures_direction.dart';

/// Quatorze candidatures fictives, couvrant chaque etape, chaque etat et les
/// marques d'informations manquantes.
List<LigneCandidature> lignesCandidaturesCapture() => <LigneCandidature>[
  ligneTest(
    id: 'a1',
    nom: 'Amina Diallo',
    courrielAObtenir: true,
    indicatifAConfirmer: true,
    derniereActivite: DateTime.utc(2026, 10, 22, 8),
  ),
  ligneTest(
    id: 'b2',
    nom: 'Bilal Haddad',
    etape: EtapeCandidature.verifications,
    etat: EtatCandidature.entretienAPlanifier,
    paysResidence: 'FR',
    paiement: EtatVersement.aVerifier,
    derniereActivite: DateTime.utc(2026, 10, 21, 17),
  ),
  ligneTest(
    id: 'c3',
    nom: 'Carla Mendes',
    etape: EtapeCandidature.confirmee,
    etat: null,
    indisponible: true,
    indisponibleJusquAu: DateTime.utc(2026, 11, 3),
    paysResidence: 'PT',
    derniereActivite: DateTime.utc(2026, 10, 21, 9),
  ),
  ligneTest(
    id: 'd4',
    nom: 'Dina Saidi',
    etape: EtapeCandidature.invitee,
    etat: null,
    paiement: EtatVersement.inconnu,
    paysResidence: null,
    derniereActivite: DateTime.utc(2026, 10, 20, 14),
  ),
  ligneTest(
    id: 'e5',
    nom: 'Emna Gharbi',
    etat: EtatCandidature.aCompleter,
    enPause: true,
    repriseLe: DateTime.utc(2026, 11, 10),
    paiement: EtatVersement.incompatible,
    paysResidence: 'TN',
    derniereActivite: DateTime.utc(2026, 10, 20, 9),
  ),
  ligneTest(
    id: 'f6',
    nom: 'Farah Nasser',
    etat: EtatCandidature.paiementNonDisponible,
    paysResidence: 'EG',
    paiement: EtatVersement.incompatible,
    derniereActivite: DateTime.utc(2026, 10, 19, 11),
  ),
  ligneTest(
    id: 'g7',
    nom: 'Ghita Alaoui',
    etape: EtapeCandidature.verifications,
    etat: EtatCandidature.entretienPlanifie,
    paysResidence: 'MA',
    derniereActivite: DateTime.utc(2026, 10, 19, 8),
  ),
  ligneTest(
    id: 'h8',
    nom: 'Hamza Benali',
    etape: EtapeCandidature.verifications,
    etat: EtatCandidature.decisionEnAttente,
    paysResidence: 'CA',
    derniereActivite: DateTime.utc(2026, 10, 18, 16),
  ),
  ligneTest(
    id: 'i9',
    nom: 'Ibtissem Cherif',
    etape: EtapeCandidature.confirmee,
    etat: null,
    restreinte: true,
    paysResidence: 'FR',
    derniereActivite: DateTime.utc(2026, 10, 18, 9),
  ),
  ligneTest(
    id: 'j10',
    nom: 'Jamal Ouedraogo',
    etat: EtatCandidature.aCompleter,
    paysResidence: 'BF',
    courrielAObtenir: true,
    derniereActivite: DateTime.utc(2026, 10, 17, 10),
  ),
  ligneTest(
    id: 'k11',
    nom: 'Khadija Sow',
    etape: EtapeCandidature.confirmee,
    etat: null,
    paysResidence: 'SN',
    paiement: EtatVersement.compatible,
    derniereActivite: DateTime.utc(2026, 10, 16, 15),
  ),
  ligneTest(
    id: 'l12',
    nom: 'Lamine Camara',
    issue: IssueCandidature.refusee,
    paysResidence: 'GN',
    derniereActivite: DateTime.utc(2026, 10, 15, 9),
  ),
  ligneTest(
    id: 'm13',
    nom: 'Maryam Qureshi',
    issue: IssueCandidature.retiree,
    paysResidence: 'GB',
    derniereActivite: DateTime.utc(2026, 10, 14, 9),
  ),
  ligneTest(
    id: 'n14',
    nom: 'Nour El Houda Bensalem',
    etape: EtapeCandidature.recue,
    etat: null,
    paysResidence: 'DZ',
    paiement: EtatVersement.inconnu,
    derniereActivite: DateTime.utc(2026, 10, 13, 9),
  ),
];
