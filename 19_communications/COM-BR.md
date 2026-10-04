# Communications V1 : contrats serveur pour BR-1 (K-28)

Le chantier est frontend seulement. Chaque besoin serveur s'ajoute ici (une ligne par besoin) et se branche à BR-1, jamais avant. Points de départ repris de la spec §34 (« risques volontairement non résolus ») ; COM-0 et les étapes suivantes complètent.

| Code | Besoin | Écran ou composant | Port côté app | État |
|---|---|---|---|---|
| COM-BR-01 | Schéma des fils métier, liés à un objet (Classe, élève, dossier, mission…) et paires autorisées §3.2 | Messages métier | à nommer par COM-F | à écrire |
| COM-BR-02 | Envoi idempotent, accusé de réception (« envoyé » seulement après confirmation) | composers | idem | à écrire |
| COM-BR-03 | Stockage des vocaux (3:00 max) | VoiceMessageComposer | idem | à écrire |
| COM-BR-04 | Politique pièces jointes (taille, types) et stockage, URL signée jamais affichée | AttachmentPolicyPort | AttachmentPolicyPort | à écrire |
| COM-BR-05 | Publications, réponses, catégories de la Communauté | Communauté | à nommer | à écrire |
| COM-BR-06 | Modération réelle : signalements, file, masquer/restaurer, journal | ModerationQueue | à nommer | à écrire |
| COM-BR-07 | Détection serveur des liens affiliés et de la vente (aucune garantie côté client) | CommunityPromotionGuard | à nommer | à écrire |
| COM-BR-08 | Canaux Studio, membres, visibilité (visible, restreint, privé autorisé, absent) | Le Studio | à nommer | à écrire |
| COM-BR-09 | Notifications : catalogue par rôle, lu/non lu, push | NotificationCenter | à nommer | à écrire |
| COM-BR-10 | Annonces : audience, programmation, publication confirmée | AnnouncementPublisher | à nommer | à écrire |
| COM-BR-11 | Matrice de permissions définitive (AudienceRulesMatrix) | Administration des communications | à nommer | à écrire |
| COM-BR-12 | Rétention, audit, synchronisation des brouillons entre appareils | tous | — | à écrire |
