# Noms de classes : liste à valider par le directeur (08/11/2026)

**Proposition, pas une décision.** Décision du directeur du 25/10/2026 (`BOUCLE-1_PLAN_2026-10-24.md` §5) : les classes sont nommées automatiquement, avec des noms de personnalités islamiques et historiques, simples à prononcer ; des noms féminins pour les classes féminines, des noms masculins pour les classes masculines. La liste est « proposée au directeur pour validation avant d'être versionnée ». **Rien n'est installé en production avant sa validation.**

Comment se lit la liste :

- **Ordre** : l'ordre de choix. La première classe de femmes s'appelle Khadija, la suivante Aïcha, et ainsi de suite.
- **Classe mixte** : elle prend le premier nom libre des deux listes, rang par rang.
- **Un seul nom par classe active** : quand une classe est clôturée ou renommée, son nom redevient libre.
- **Repli** : quand tous les noms d'un genre sont pris, la classe s'appelle « Classe 1 », « Classe 2 », et ainsi de suite. La création n'est jamais bloquée.
- **Renommer** : la direction peut toujours changer le nom d'une classe après coup (« Changer le nom »).

Choix faits pour cette proposition :

- des prophètes, des compagnons et des compagnonnes connus de tous ;
- aucun nom de personnalité discutée : en cas de doute, le nom a été écarté ;
- aucun nom du Prophète ﷺ (Muhammad, Ahmad).

Pour valider, le directeur répond « liste validée », ou nomme les noms à retirer ou à ajouter. La source exacte est `supabase/donnees/noms_classes.json`, recopiée telle quelle par la migration `20261121100000_noms_classes.sql`. Un test vérifie que les deux sont identiques.

## Noms féminins (40)

| Ordre | Français | العربية |
| --: | :-- | :-- |
| 1 | Khadija | خديجة |
| 2 | Aïcha | عائشة |
| 3 | Fatima | فاطمة |
| 4 | Maryam | مريم |
| 5 | Assia | آسية |
| 6 | Hajar | هاجر |
| 7 | Sarah | سارة |
| 8 | Soumaya | سمية |
| 9 | Hafsa | حفصة |
| 10 | Zaynab | زينب |
| 11 | Rouqayya | رقية |
| 12 | Safiya | صفية |
| 13 | Sawda | سودة |
| 14 | Maymouna | ميمونة |
| 15 | Asma | أسماء |
| 16 | Noussayba | نسيبة |
| 17 | Roufayda | رفيدة |
| 18 | Halima | حليمة |
| 19 | Amina | آمنة |
| 20 | Baraka | بركة |
| 21 | Khawla | خولة |
| 22 | Chifa | الشفاء |
| 23 | Loubaba | لبابة |
| 24 | Ramla | رملة |
| 25 | Oumama | أمامة |
| 26 | Nafissa | نفيسة |
| 27 | Zoubayda | زبيدة |
| 28 | Arwa | أروى |
| 29 | Salma | سلمى |
| 30 | Atika | عاتكة |
| 31 | Roumayssa | الرميصاء |
| 32 | Layla | ليلى |
| 33 | Habiba | حبيبة |
| 34 | Khansa | الخنساء |
| 35 | Chayma | الشيماء |
| 36 | Fakhita | فاختة |
| 37 | Bilqis | بلقيس |
| 38 | Hawa | حواء |
| 39 | Jamila | جميلة |
| 40 | Barira | بريرة |

## Noms masculins (43)

| Ordre | Français | العربية |
| --: | :-- | :-- |
| 1 | Ibrahim | إبراهيم |
| 2 | Ismaïl | إسماعيل |
| 3 | Ishaq | إسحاق |
| 4 | Yaqoub | يعقوب |
| 5 | Youssouf | يوسف |
| 6 | Moussa | موسى |
| 7 | Haroun | هارون |
| 8 | Daoud | داود |
| 9 | Souleymane | سليمان |
| 10 | Younous | يونس |
| 11 | Nouh | نوح |
| 12 | Idriss | إدريس |
| 13 | Houd | هود |
| 14 | Salih | صالح |
| 15 | Chouaïb | شعيب |
| 16 | Zakariya | زكريا |
| 17 | Yahya | يحيى |
| 18 | Issa | عيسى |
| 19 | Ayyoub | أيوب |
| 20 | Ilyas | إلياس |
| 21 | Abou Bakr | أبو بكر |
| 22 | Omar | عمر |
| 23 | Othmane | عثمان |
| 24 | Ali | علي |
| 25 | Bilal | بلال |
| 26 | Hamza | حمزة |
| 27 | Khalid | خالد |
| 28 | Saad | سعد |
| 29 | Zayd | زيد |
| 30 | Anas | أنس |
| 31 | Mouadh | معاذ |
| 32 | Oussama | أسامة |
| 33 | Salmane | سلمان |
| 34 | Ammar | عمار |
| 35 | Abbas | العباس |
| 36 | Jaafar | جعفر |
| 37 | Talha | طلحة |
| 38 | Zoubayr | الزبير |
| 39 | Moussab | مصعب |
| 40 | Souhayb | صهيب |
| 41 | Hassane | حسان |
| 42 | Tariq | طارق |
| 43 | Malik | مالك |
