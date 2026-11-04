# Parcours 5 bis : pièges (appareil de l'enfant)

Règle : si l'application laisse faire une erreur sans un mot clair et sans un moyen de revenir, le
parcours est rouge. Script : `tool/e2e/pieges_5bis.mjs`.

| # | Écran | Famille | Piège | Joué | Résultat |
|---|---|---|---|---|---|
| 5b.1 | Appareil de l'enfant › code | 3 | Code de l'appareil tapé faux (une lettre changée) | oui | vert : code faux : « flt-semantics:Ce code n'existe pas, ou un code plus récent l'a remplacé. Vérifiez-le, ou affichez un nouveau code sur l'appareil du tuteur. » |
| 5b.2 | Appareil de l'enfant › code | 3 | Code tapé en minuscules | oui | vert : code en minuscules accepte |
| 5b.3 | Code personnel | 3 | La confirmation ne correspond pas au premier code | oui | vert : « Les deux codes ne sont pas les mêmes. Choisis ton code à nouveau. » en rouge au-dessus du clavier, saisie remise à zéro (lu sur la capture 05 ; le script l'avait manqué, expression corrigée) |
| 5b.4 | Tuteur › Connecter un appareil | 2 | Le tuteur quitte l'écran du code puis revient (le code ne se réaffiche pas) | oui | vert : « group:Un code est déjà valable Un code créé pour cet élève vaut jusqu'à 01:07. Il ne peut pas être réaffiché : en générer un nouveau rendra l'ancien inutilisable. Gén » avec « Générer un nouveau code » (le bouton n'a pas de noeud propre : UX-021) |
| 5b.5 | Code personnel | 5 | Lecture : « Choisis ton code personnel », « Entre-le encore une fois » (enfant de 6 ans) | oui | vert a la lecture : phrases courtes, tutoiement, « Quatre chiffres, rien que pour toi. Il reste sur cet appareil. », consigne lue par un bouton son |
