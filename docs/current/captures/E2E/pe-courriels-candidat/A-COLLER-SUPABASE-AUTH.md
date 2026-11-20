# À coller par le pilote : sujets des courriels Supabase Auth (PE-A1, 20/11/2026)

Ce point **attend le pilote** : le sujet et le corps des courriels d’authentification se règlent dans le tableau de bord
Supabase (projet de production, *Authentication → Emails → Templates*). Aucun agent ne peut les changer depuis le dépôt.

## Ce qui est prouvé, et ce qui ne l’est pas

- Prouvé sur le poste de construction : chaque ligne ci-dessous, exécutée par le moteur `html/template` de Go (bibliothèque standard),
  donne le sujet arabe pour `langue = ar`, anglais pour `en`, français pour `fr`, pour un compte sans langue et pour un compte sans
  aucune donnée (rendus `auth_*_{fr,ar,en}.html` de ce dossier).
- **Non prouvé** : que Supabase Auth exécute le sujet comme un modèle (lu dans son code, de mémoire ; pas vérifié en ligne). Le premier
  envoi réel après le collage doit le confirmer : demander un lien de connexion avec un compte dont la langue est l’arabe.
- Le corps ne change pas : les fichiers `supabase/templates/*.html` du dépôt sont déjà ramifiés par langue. Si le corps collé en
  production n’est pas celui du dépôt, coller aussi le fichier `supabase/templates/<message>.html` correspondant, en entier.
- La langue lue est `user_metadata.langue`. La migration `20261130966000_courriels_langue_candidat.sql` l’écrit pour chaque compte
  dont la langue est connue (choisie dans le compte, sinon celle de sa candidature). Un compte **tout neuf** créé par « recevoir un
  lien » depuis l’application n’a pas encore de langue : il faut que l’application la passe à `signInWithOtp` (hors de ce lot, voir la PR).

## Les six champs « Subject », mot pour mot (une ligne chacun)

Copier toute la ligne, accolades comprises, sans retour à la ligne. Source : `supabase/templates/sujets.txt` (écrit par
`supabase/templates/generer.ts`).

### Magic Link (lien de connexion)

```
{{ $l := "" }}{{ if .Data }}{{ $l = printf "%v" .Data.langue }}{{ end }}{{ if eq $l "en" }}Your sign-in link for Rewayah Academy{{ else if eq $l "ar" }}رابط تسجيل دخولك إلى Rewayah Academy{{ else if eq $l "es" }}Su enlace de acceso a Rewayah Academy{{ else if eq $l "pt" }}A sua ligação de acesso à Rewayah Academy{{ else }}Votre lien de connexion à Rewayah Academy{{ end }}
```

### Confirm signup (confirmation)

```
{{ $l := "" }}{{ if .Data }}{{ $l = printf "%v" .Data.langue }}{{ end }}{{ if eq $l "en" }}Confirm your e-mail address{{ else if eq $l "ar" }}أكّد عنوان بريدك الإلكتروني{{ else if eq $l "es" }}Confirme su dirección de correo electrónico{{ else if eq $l "pt" }}Confirme o seu endereço de e-mail{{ else }}Confirmez votre adresse e-mail{{ end }}
```

### Invite user (invitation)

```
{{ $l := "" }}{{ if .Data }}{{ $l = printf "%v" .Data.langue }}{{ end }}{{ if eq $l "en" }}Your access to Rewayah Academy{{ else if eq $l "ar" }}دخولك إلى Rewayah Academy{{ else if eq $l "es" }}Su acceso a Rewayah Academy{{ else if eq $l "pt" }}O seu acesso à Rewayah Academy{{ else }}Votre accès à Rewayah Academy{{ end }}
```

### Reset Password (nouveau mot de passe)

```
{{ $l := "" }}{{ if .Data }}{{ $l = printf "%v" .Data.langue }}{{ end }}{{ if eq $l "en" }}Choose a new password{{ else if eq $l "ar" }}اختيار كلمة مرور جديدة{{ else if eq $l "es" }}Elija una nueva contraseña{{ else if eq $l "pt" }}Escolha uma nova palavra-passe{{ else }}Choisir un nouveau mot de passe{{ end }}
```

### Change Email Address (changement d’adresse)

```
{{ $l := "" }}{{ if .Data }}{{ $l = printf "%v" .Data.langue }}{{ end }}{{ if eq $l "en" }}Confirm your new e-mail address{{ else if eq $l "ar" }}أكّد عنوان بريدك الإلكتروني الجديد{{ else if eq $l "es" }}Confirme su nueva dirección de correo electrónico{{ else if eq $l "pt" }}Confirme o seu novo endereço de e-mail{{ else }}Confirmez votre nouvelle adresse e-mail{{ end }}
```

### Reauthentication (code de vérification)

```
{{ $l := "" }}{{ if .Data }}{{ $l = printf "%v" .Data.langue }}{{ end }}{{ if eq $l "en" }}Your verification code{{ else if eq $l "ar" }}رمز التحقق الخاص بك{{ else if eq $l "es" }}Su código de verificación{{ else if eq $l "pt" }}O seu código de verificação{{ else }}Votre code de vérification{{ end }}
```

## Les sujets, langue par langue (pour relire)

- **magic_link** : fr « Votre lien de connexion à Rewayah Academy » ; en « Your sign-in link for Rewayah Academy » ; ar « رابط تسجيل دخولك إلى Rewayah Academy » ; es « Su enlace de acceso a Rewayah Academy » ; pt « A sua ligação de acesso à Rewayah Academy »
- **confirmation** : fr « Confirmez votre adresse e-mail » ; en « Confirm your e-mail address » ; ar « أكّد عنوان بريدك الإلكتروني » ; es « Confirme su dirección de correo electrónico » ; pt « Confirme o seu endereço de e-mail »
- **invite** : fr « Votre accès à Rewayah Academy » ; en « Your access to Rewayah Academy » ; ar « دخولك إلى Rewayah Academy » ; es « Su acceso a Rewayah Academy » ; pt « O seu acesso à Rewayah Academy »
- **recovery** : fr « Choisir un nouveau mot de passe » ; en « Choose a new password » ; ar « اختيار كلمة مرور جديدة » ; es « Elija una nueva contraseña » ; pt « Escolha uma nova palavra-passe »
- **email_change** : fr « Confirmez votre nouvelle adresse e-mail » ; en « Confirm your new e-mail address » ; ar « أكّد عنوان بريدك الإلكتروني الجديد » ; es « Confirme su nueva dirección de correo electrónico » ; pt « Confirme o seu novo endereço de e-mail »
- **reauthentication** : fr « Votre code de vérification » ; en « Your verification code » ; ar « رمز التحقق الخاص بك » ; es « Su código de verificación » ; pt « O seu código de verificação »
