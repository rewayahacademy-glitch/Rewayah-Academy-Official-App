#!/usr/bin/env python3
"""Garde-fou PreToolUse de Rewayah Academy (GARDE-FOU-2).

Refuse, avant exécution, ce que les règles du directeur interdisent aux agents
Claude (CLAUDE.md, docs/orchestration/COHABITATION.md). Code de sortie 2 :
l'outil n'est pas lancé et le motif est rendu à l'agent. Toute erreur interne
vaut refus (échec fermé).
"""
import json
import os
import posixpath
import re
import shlex
import signal
import subprocess
import sys

PROD = "gggmtelinlpseweouyav"
COMMITS_GARDE = ("15a9c8ed", "5ea5e45c")
FICHIERS_GARDE = [".claude/settings.json", ".claude/settings.local.json", ".claude/hooks"]

ZONES_INTERDITES = [
    (r"(^|/)\.github(/|$)", ".github/ est interdit aux agents (déploiement, CI)"),
    (r"(^|/)vercel\.json$", "vercel.json est interdit aux agents"),
    (r"(^|/)pubspec\.yaml$", "pubspec.yaml est interdit aux agents"),
    (r"(^|/)site-public(/|$)", "site-public/ est gelé (K-64)"),
    (r"(^|/)lib/features/parcours_offres(/|$)", "parcours_offres est gelé (K-64)"),
    (r"(^|/)\.claude/(settings(\.local)?\.json$|hooks(/|$))", "le garde-fou ne se modifie que sur ordre explicite du directeur"),
]

ECRITURE_SQL = re.compile(
    r"\b(insert|update|delete|merge|upsert|alter|drop|create|grant|revoke|truncate|comment\s+on|security\s+label"
    r"|call|do|copy|vacuum|reindex|cluster|refresh|lock|import|set|reset|discard|listen|notify|prepare|execute)\b",
    re.I,
)
LECTURE_SQL = re.compile(r"^\s*(select|with|explain|show|table|values)\b", re.I)
# Mots qu'on peut trouver devant « ( » sans que ce soit un appel de fonction.
MOTS_SQL = set("""select from where and or not in exists values as on join using over filter within group by order
partition having case when then else end any all some is null like ilike between union intersect except limit offset
returning with lateral array row distinct cast interval timestamp timestamptz date time numeric decimal int integer
bigint smallint text varchar char uuid boolean bool jsonb json real float double precision""".split())
FONCTIONS_LECTURE = set("""count sum avg min max coalesce nullif greatest least lower upper initcap length char_length
octet_length substring substr trim btrim ltrim rtrim replace split_part concat concat_ws format left right position
strpos reverse repeat lpad rpad now age extract round floor ceil ceiling abs sign mod power sqrt trunc md5 encode decode
unnest cardinality generate_series row_number rank dense_rank percent_rank ntile lag lead first_value last_value
bool_and bool_or every obj_description col_description format_type quote_ident quote_literal quote_nullable version
row_to_json starts_with translate chr ascii isfinite justify_days justify_hours make_date make_interval timezone
percentile_cont percentile_disc mode stddev variance corr regclass""".split())
PREFIXES_LECTURE = ("pg_", "has_", "json_", "jsonb_", "array_", "string_", "to_", "date_", "current_", "regexp_",
                    "st_", "information_schema.", "pg_catalog.")
PG_DANGEREUSES = re.compile(
    r"^(pg_catalog\.)?pg_(terminate|cancel|reload|rotate|create|drop|switch|advisory|promote|wal_replay|read_|ls_|"
    r"stat_file|file_|logical_emit|replication|backup|start|stop|notify|sleep|import|export|copy|truncate|"
    r"try_advisory|xact_advisory|log_)", re.I)

INTERPRETES = r"(python3?|py|perl|node|ruby|php|deno|bun|pwsh|powershell)"
INDICES_ECRITURE = re.compile(
    r"(['\"][wax]\+?b?['\"]|\bwrite|\bunlink|\bremove|\brename|rmtree|\bcopy|\bmove|truncate|\bmkdir|\bsymlink"
    r"|\bopen\s*\(\s*[^)]*>|\bsystem\b|subprocess|\bexec|spawn|\bchmod|\btouch|Path\(|\bfs\.|>\s*\S)", re.I)


class Refus(Exception):
    pass


def refuser(motif):
    print(f"Refusé par le garde-fou du projet : {motif}.", file=sys.stderr)
    sys.exit(2)


def zone_de(chemin):
    """Raison de l'interdiction si le chemin tombe dans une zone, sinon None."""
    c = (chemin or "").strip().strip("'\"").replace("\\", "/")
    if not c:
        return None
    norm = posixpath.normpath(c) if not re.match(r"^[a-z]+://", c, re.I) else c
    for v in (c, norm, c.rstrip("/") + "/", norm + "/"):
        for motif, raison in ZONES_INTERDITES:
            if re.search(motif, v, re.I):
                return raison
    return None


def verifier_chemin(chemin):
    raison = zone_de(chemin)
    if raison:
        refuser(f"{chemin} : {raison}")


# ---------------------------------------------------------------------------
# Outils git
# ---------------------------------------------------------------------------

def git(cwd, *args):
    try:
        r = subprocess.run(["git", "-C", cwd or ".", *args], capture_output=True, text=True, timeout=4)
        return r.returncode, r.stdout.strip()
    except Exception:
        return 1, ""


def branche_courante(cwd):
    return git(cwd, "symbolic-ref", "--short", "-q", "HEAD")[1]


def racine(cwd):
    rc, out = git(cwd, "rev-parse", "--show-toplevel")
    return os.path.realpath(out) if rc == 0 and out else ""


def dans_arbre_du_projet(cwd):
    """Vrai si cwd est l'arbre de travail d'où les hooks sont lus."""
    projet = os.environ.get("CLAUDE_PROJECT_DIR") or cwd
    a, b = racine(cwd), racine(projet)
    return not a or not b or a == b


def change_le_garde(cwd, ref_a, ref_b):
    """Vrai si les fichiers du garde-fou diffèrent entre deux révisions (ou si on ne peut le savoir)."""
    rc, _ = git(cwd, "diff", "--quiet", ref_a, ref_b, "--", *FICHIERS_GARDE)
    return rc != 0


# ---------------------------------------------------------------------------
# Préparation du texte d'une commande shell
# ---------------------------------------------------------------------------

CMD_MESSAGE = re.compile(
    r"(?<![\w.-])(git(\s+-[Cc]\s+\S+)*\s+(commit|merge|tag|notes(\s+\w+)?|revert|cherry-pick|stash\s+push)"
    r"|gh\s+(pr|issue|release)\s+(create|comment|edit|review|close|reopen))\b")
DRAPEAU_MESSAGE = re.compile(r"(^|\s)(-[a-zA-Z]*m|--message=?|--title=?|-t|--body=?|-b|--notes=?|-n|--subject=?)\s*$")
CAT_HEREDOC = re.compile(r"\"\$\(\s*cat\s*<<-?\s*['\"]?(\w+)['\"]?[^\n]*\n.*?^[ \t]*\1[ \t]*\n\s*\)\s*\"", re.S | re.M)


def fin_chaine(cmd, i):
    q = cmd[i]
    j = i + 1
    while j < len(cmd):
        if q == '"' and cmd[j] == "\\":
            j += 2
            continue
        if cmd[j] == q:
            return j
        j += 1
    return len(cmd) - 1


def neutraliser_messages(cmd):
    """Remplace par MSG le texte des messages (git commit -m, gh pr create --body...)."""
    res = []
    i, n = 0, len(cmd)
    while i < n:
        m = CMD_MESSAGE.search(cmd, i)
        if not m:
            res.append(cmd[i:])
            break
        res.append(cmd[i:m.end()])
        i = m.end()
        while i < n:
            c = cmd[i]
            if c in ";|&\n":
                break
            if c in "'\"":
                avant = "".join(res)[-40:]
                hd = CAT_HEREDOC.match(cmd, i) if c == '"' else None
                if hd and DRAPEAU_MESSAGE.search(avant):
                    res.append('"MSG"')
                    i = hd.end()
                    continue
                j = fin_chaine(cmd, i)
                corps = cmd[i + 1:j]
                if DRAPEAU_MESSAGE.search(avant) and not (c == '"' and re.search(r"\$\(|`", corps)):
                    res.append(c + "MSG" + c)
                else:
                    res.append(cmd[i:j + 1])
                i = j + 1
                continue
            res.append(c)
            i += 1
    return "".join(res)


HEREDOC = re.compile(r"<<-?[ \t]*(['\"]?)(\w+)\1")
PREFIXE_TEXTE = re.compile(
    r"(\$\(\s*cat\s*$|(^|[\s;&|(])(git(\s+-[Cc]\s+\S+)*\s+(commit|tag|merge|notes)|gh\s+(pr|issue))\b[^\n]*$)")
INTERPRETE_LIGNE = re.compile(r"\|\s*|\b(bash|sh|zsh|dash|ksh|python3?|py|perl|node|ruby|php|git\s+apply|source|eval)\b")


def traiter_heredocs(cmd, codes):
    """Retire les corps de heredoc qui ne sont que du texte ; garde les autres.

    Les corps envoyés à un interpréteur non shell sont ajoutés à `codes` pour un
    contrôle d'écriture dans les zones.
    """
    sortie = []
    pos = 0
    while True:
        m = HEREDOC.search(cmd, pos)
        if not m:
            sortie.append(cmd[pos:])
            break
        debut_ligne = cmd.rfind("\n", 0, m.start()) + 1
        fin_ligne = cmd.find("\n", m.end())
        if fin_ligne < 0:
            sortie.append(cmd[pos:])
            break
        avant = cmd[debut_ligne:m.start()]
        reste = cmd[m.end():fin_ligne]
        fin = re.compile(r"^[ \t]*" + re.escape(m.group(2)) + r"[ \t]*$", re.M).search(cmd, fin_ligne + 1)
        corps_fin = fin.start() if fin else len(cmd)
        corps = cmd[fin_ligne + 1:corps_fin]
        apres = fin.end() if fin else len(cmd)
        texte = PREFIXE_TEXTE.search(avant) and not INTERPRETE_LIGNE.search(reste)
        sortie.append(cmd[pos:m.start()])
        sortie.append(reste)
        if texte:
            pos = apres
            continue
        if re.search(r"(^|[\s|;&(])" + INTERPRETES + r"\b", avant + reste):
            codes.append(corps)
        sortie.append("\n" + corps + "\n")
        pos = apres
    return "".join(sortie)


def masquer_chaines(s):
    """Copie de s où l'intérieur des chaînes entre guillemets est remplacé par des _."""
    out = list(s)
    i = 0
    while i < len(s):
        if s[i] in "'\"":
            j = fin_chaine(s, i)
            for k in range(i + 1, j):
                out[k] = "_"
            i = j + 1
        else:
            i += 1
    return "".join(out)


def decouper(cmd):
    m = masquer_chaines(cmd)
    segs, debut = [], 0
    for x in re.finditer(r"\n|;|&&|\|\||\||(?<![>&<])&(?!>)|`|\$\(|\)", m):
        segs.append(cmd[debut:x.start()])
        debut = x.end()
    segs.append(cmd[debut:])
    return [s.strip() for s in segs if s.strip()]


REDIR = re.compile(r"(?:\d*|&)(>>?|>\|)\s*(\"[^\"]*\"|'[^']*'|[^\s;&|<>()]+)|(\d*)<(?!<)\s*(\"[^\"]*\"|'[^']*'|[^\s;&|<>()]+)")
ENVELOPPES = re.compile(r"^((\w+=\S*|env|command|exec|nohup|time|sudo|builtin|stdbuf(\s+-\S+)*|timeout\s+\S+|nice"
                        r"(\s+-n\s*\S+)?|[({!])\s*)+")


def analyser_segment(seg):
    """Rend (mots, cibles_sortie, entrees) d'un segment ; mots sans enveloppes ni redirections."""
    m = masquer_chaines(seg)
    sorties, entrees, propre, pos = [], [], [], 0
    for x in REDIR.finditer(m):
        propre.append(seg[pos:x.start()])
        cible = seg[x.start(2):x.end(2)] if x.group(1) else seg[x.start(4):x.end(4)]
        (sorties if x.group(1) else entrees).append(cible.strip("'\""))
        pos = x.end()
    propre.append(seg[pos:])
    texte = "".join(propre).strip()
    texte = ENVELOPPES.sub("", texte)
    try:
        mots = shlex.split(texte, posix=True)
    except ValueError:
        mots = [w.strip("'\"") for w in texte.split()]
    while mots and re.match(r"^(\w+=\S*|env|command|exec|nohup|time|sudo|builtin|[({!])$", mots[0]):
        mots = mots[1:]
    if mots and "/" in mots[0] and not mots[0].startswith("."):
        mots[0] = mots[0].rsplit("/", 1)[-1]
    if mots and mots[0].startswith("\\"):
        mots[0] = mots[0][1:]
    return mots, sorties, entrees


def options_et_args(mots, avec_valeur=()):
    args = []
    i = 0
    fin_options = False
    while i < len(mots):
        w = mots[i]
        if not fin_options and w == "--":
            fin_options = True
        elif not fin_options and w.startswith("-") and w != "-":
            if w in avec_valeur:
                i += 1
        else:
            args.append(w)
        i += 1
    return args


# ---------------------------------------------------------------------------
# Contrôles de la commande shell
# ---------------------------------------------------------------------------

def verifier_zone_mots(mots, raison_prefixe="écriture shell dans une zone interdite"):
    for w in mots:
        r = zone_de(w)
        if r:
            refuser(f"{raison_prefixe} : {r}")


def lire_patch(fichier, cwd):
    chemin = fichier if os.path.isabs(fichier) else os.path.join(cwd or ".", fichier)
    try:
        with open(chemin, encoding="utf-8", errors="replace") as f:
            contenu = f.read()
    except Exception:
        return None
    return re.findall(r"^(?:\+\+\+|---|diff --git|rename (?:from|to)|copy (?:from|to)) (.+)$", contenu, re.M)


def verifier_patch(fichiers, cwd, nom):
    if not fichiers:
        refuser(f"{nom} sans fichier lisible : contenu non vérifiable (écrire le patch dans un fichier hors zone)")
    for f in fichiers:
        lignes = lire_patch(f, cwd)
        if lignes is None:
            refuser(f"{nom} : patch {f} illisible, contenu non vérifiable")
        for l in lignes:
            for p in l.split():
                p = re.sub(r"^[ab]/", "", p)
                r = zone_de(p)
                if r:
                    refuser(f"{nom} touche une zone interdite : {r}")


def verifier_ecriture(mots, sorties, entrees, cwd, texte_complet):
    for cible in sorties:
        r = zone_de(cible)
        if r:
            refuser(f"écriture shell dans une zone interdite : {r}")
    if not mots:
        return
    cmd = mots[0]
    args = mots[1:]
    if cmd in {"tee", "rm", "rmdir", "touch", "truncate", "shred", "unlink", "mkdir", "chmod", "chown", "chgrp",
               "mv", "setfacl", "chattr"}:
        verifier_zone_mots(options_et_args(args, ("-s", "--size", "-t", "-m", "--mode", "--reference")) +
                           [a.split("=", 1)[-1] for a in args if a.startswith("--target-directory")] +
                           [args[i + 1] for i, a in enumerate(args[:-1]) if a == "-t"])
    elif cmd in {"cp", "rsync", "install", "scp"}:
        cibles = [a.split("=", 1)[1] for a in args if a.startswith("--target-directory=")]
        cibles += [args[i + 1] for i, a in enumerate(args[:-1]) if a == "-t"]
        positionnels = options_et_args(args, ("-t", "-m", "--mode", "-e", "--exclude", "--include", "-o", "-g"))
        if not cibles and positionnels:
            cibles = positionnels[-1:]
        verifier_zone_mots(cibles)
    elif cmd == "ln":
        # ln : la cible comme le nom du lien comptent, avec ou sans « / » final.
        verifier_zone_mots([a.rstrip("/") + "/" for a in options_et_args(args, ("-t", "-S", "--suffix"))] +
                           [args[i + 1] for i, a in enumerate(args[:-1]) if a == "-t"])
    elif cmd == "dd":
        verifier_zone_mots([a[3:] for a in args if a.startswith("of=")])
    elif cmd == "sed" and any(re.match(r"^(-[a-zA-Z]*i|--in-place)", a) for a in args):
        script_explicite = any(a in ("-e", "-f") or a.startswith("--expression") for a in args)
        pos = options_et_args(args, ("-e", "-f", "--expression", "--file", "-l"))
        verifier_zone_mots(pos if script_explicite else pos[1:])
    elif cmd == "perl" and any(re.match(r"^-[a-zA-Z]*i", a) for a in args):
        pos = options_et_args(args, ("-e", "-E", "-M", "-I"))
        verifier_zone_mots(pos if any(a in ("-e", "-E") or re.match(r"^-[a-zA-Z]*[eE]$", a) for a in args) else pos[1:])
    elif cmd in {"patch"}:
        f = [args[i + 1] for i, a in enumerate(args[:-1]) if a in ("-i", "--input")]
        f += [a.split("=", 1)[1] for a in args if a.startswith("--input=")]
        verifier_patch(f + entrees, cwd, "patch")
    elif cmd == "find" and re.search(r"\s-(delete|exec|execdir|ok|okdir|fprint\w*|fls)\b", " " + " ".join(args)):
        verifier_zone_mots(args)
    elif cmd == "xargs":
        reste = options_et_args(args, ("-I", "-n", "-P", "-L", "-d", "-a", "-E", "-s"))
        if reste and reste[0] not in {"grep", "rg", "egrep", "fgrep", "cat", "head", "tail", "wc", "ls", "file",
                                      "stat", "echo", "printf", "dirname", "basename", "realpath", "sha256sum",
                                      "md5sum", "dart", "flutter"}:
            for motif, raison in ZONES_INTERDITES:
                cible = motif.replace("(^|/)", r"(^|[\s'\"=/:])").replace("(/|$)", r"(/|\b)").rstrip("$")
                if re.search(cible, texte_complet, re.I):
                    refuser(f"xargs {reste[0]} sur une liste qui touche une zone interdite : {raison}")
    elif re.match(r"^" + INTERPRETES + r"$", cmd):
        codes = [args[i + 1] for i, a in enumerate(args[:-1]) if re.match(r"^-[a-zA-Z]*[ceE]$", a)]
        for code in codes:
            verifier_code(code)
    elif cmd in {"cd", "pushd"}:
        pos = options_et_args(args)
        if pos:
            r = zone_de(pos[0].rstrip("/") + "/")
            if r:
                refuser("se placer dans une zone interdite n'est pas permis ; lire avec un chemin depuis la racine")
    elif cmd == "git":
        verifier_git_ecriture(args, entrees, cwd)


def verifier_code(code):
    if not INDICES_ECRITURE.search(code):
        return
    for motif, raison in ZONES_INTERDITES:
        cible = motif.replace("(^|/)", r"(^|[\s'\"=/:(])").replace("(/|$)", r"(/|['\"]|$)").rstrip("$")
        if re.search(cible, code, re.I | re.M):
            refuser(f"code d'interpréteur qui écrit dans une zone interdite : {raison}")


GIT_OPTS_VALEUR = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path", "--super-prefix",
                   "--config-env"}


def git_sous_commande(args):
    """Rend (options_globales, sous_commande, reste)."""
    glob = []
    i = 0
    while i < len(args):
        a = args[i]
        if a in GIT_OPTS_VALEUR:
            glob += [a, args[i + 1] if i + 1 < len(args) else ""]
            i += 2
        elif a.startswith("-"):
            glob.append(a)
            i += 1
        else:
            return glob, a, args[i + 1:]
    return glob, "", []


def verifier_git_ecriture(args, entrees, cwd):
    glob, sc, reste = git_sous_commande(args)
    if sc in {"rm", "mv"}:
        verifier_zone_mots(options_et_args(reste))
    elif sc == "restore":
        src = [a.split("=", 1)[1] for a in reste if a.startswith("--source=")]
        src += [reste[i + 1] for i, a in enumerate(reste[:-1]) if a in ("-s", "--source")]
        if any(s not in ("HEAD", "@") for s in src):
            verifier_zone_mots(options_et_args(reste, ("-s", "--source")),
                               "git restore depuis une autre révision dans une zone interdite")
    elif sc == "checkout":
        if "--" in reste:
            avant = options_et_args(reste[:reste.index("--")], ("-b", "-B", "--orphan"))
            chemins = reste[reste.index("--") + 1:]
            if any(a not in ("HEAD", "@") for a in avant):
                verifier_zone_mots(chemins, "git checkout depuis une autre révision dans une zone interdite")
        else:
            pos = options_et_args(reste, ("-b", "-B", "--orphan"))
            zones = [a for a in pos if zone_de(a)]
            if zones and pos and pos[0] not in ("HEAD", "@") and not zone_de(pos[0]):
                verifier_zone_mots(zones, "git checkout depuis une autre révision dans une zone interdite")
    elif sc in {"apply", "am"}:
        if any(a in ("--check", "--stat", "--numstat", "--summary") for a in reste) and "--apply" not in reste:
            return
        verifier_patch(options_et_args(reste, ("-p", "-C", "--directory", "--exclude", "--include")) + entrees,
                       cwd, f"git {sc}")
    elif sc == "config" or any(g.startswith("alias.") for g in glob):
        texte = " ".join(args)
        if re.search(r"(^|\s)alias\.|--add\s+alias\.|\balias\.", texte):
            refuser("créer un alias git est interdit (contournement du garde-fou)")
        if re.search(r"\b(push\.default|remote\.\S*\.push|remote\.pushdefault|branch\.\S*\.(merge|pushremote)"
                     r"|core\.hookspath|include\.path|includeif)", texte, re.I):
            if not re.search(r"(^|\s)(--get|--get-all|--list|-l|--get-regexp)\b", texte):
                refuser("modifier la configuration de push ou d'inclusion de git est interdit")
    if any(re.search(r"^(alias\.|push\.default=|remote\..*\.push=|remote\.pushdefault=|core\.hookspath=|include\.)", g, re.I)
           for g in glob):
        refuser("option git -c qui change le push, les alias ou les inclusions : interdite")
    if sc in {"revert", "reset", "checkout", "switch", "rebase"}:
        d = cwd
        if "-C" in glob:
            c = glob[glob.index("-C") + 1]
            d = None if (d is None or re.search(r"[$`~]", c)) else (c if os.path.isabs(c) else os.path.join(d, c))
        if d is None:
            refuser(f"git {sc} après un cd ou -C non littéral : écrire le dossier en clair")
        if dans_arbre_du_projet(d):
            verifier_git_garde(sc, reste, d)


def verifier_git_garde(sc, reste, cwd):
    texte = " ".join(reste)
    if sc == "revert":
        if any(c in texte for c in COMMITS_GARDE):
            refuser("annuler un commit du garde-fou est interdit")
        for ref in options_et_args(reste, ("-m", "--mainline", "-s", "--strategy", "-X")):
            if change_le_garde(cwd, ref + "^", ref):
                refuser(f"git revert {ref} toucherait le garde-fou (.claude/) ; interdit sans ordre du directeur")
    elif sc == "reset" and any(a in ("--hard", "--keep", "--merge") for a in reste):
        refs = options_et_args(reste)
        if refs and change_le_garde(cwd, refs[0], "HEAD"):
            refuser(f"git reset --hard {refs[0]} changerait le garde-fou (.claude/) ; interdit sans ordre du directeur")
    elif sc in {"checkout", "switch"} and "--" not in reste:
        pos = options_et_args(reste, ("-b", "-B", "-c", "-C", "--orphan", "--track", "-t"))
        nouveaux = [reste[i + 1] for i, a in enumerate(reste[:-1]) if a in ("-b", "-B", "-c", "-C")]
        cibles = [p for p in pos if p not in nouveaux]
        if len(cibles) == 1 and not zone_de(cibles[0]):
            ref = cibles[0]
            if git(cwd, "rev-parse", "-q", "--verify", ref + "^{commit}")[0] == 0 and \
                    git(cwd, "cat-file", "-e", ref + ":.claude/hooks/garde.py")[0] != 0:
                refuser(f"{ref} n'a pas le garde-fou : la basculer dans l'arbre principal bloquerait la session ; "
                        "utiliser un worktree (git worktree add)")
    elif sc == "rebase":
        if any(c in texte for c in COMMITS_GARDE) and re.search(r"(^|\s)(-i|--interactive|--onto)\b", texte):
            refuser("réécrire l'historique du garde-fou est interdit")


# ---- push ------------------------------------------------------------------

# Chaque début d'invocation de git (lookahead : les invocations imbriquées ne sont pas avalées).
POUSSE = re.compile(r"(^|[\s(;{`'\"/\\|&$])(?=git\b[^;&|\n)`]*\bpush\b)")


def refspec_dst(r):
    r = r.lstrip("+")
    if ":" in r:
        src, dst = r.split(":", 1)
        return src, dst
    return r, r


def verifier_push_git(args, cwd, cd_avant, cd_dir):
    glob, sc, reste = git_sous_commande(args)
    if sc != "push":
        return
    texte = " " + " ".join(reste) + " "
    if any(g.startswith(("push.", "remote.")) for g in glob):
        refuser("option -c de push interdite")
    if re.search(r"\s--(all|mirror|branches)\b", texte):
        refuser("pousser toutes les branches enverrait main (production)")
    if re.search(r"\s(--force(=\S*)?|-[a-zA-Z]*f[a-zA-Z]*)\s", texte):
        refuser("push --force interdit (utiliser --force-with-lease, et seulement sur sa propre branche)")
    if re.search(r"\s(--delete|-d|--prune)\s", texte):
        refuser("suppression de branche distante interdite sans feu vert du directeur")
    pos = options_et_args(reste, ("-o", "--push-option", "--repo", "--receive-pack", "--exec", "--signed"))
    if re.search(r"\s--(repo|receive-pack|exec)\b", texte):
        refuser("options --repo/--receive-pack/--exec de git push interdites")
    refspecs = pos[1:]
    for r in refspecs:
        if r.startswith("+"):
            refuser("refspec forcée (+) interdite (utiliser --force-with-lease)")
        src, dst = refspec_dst(r)
        if src == "" or dst == "":
            refuser("suppression de branche distante interdite sans feu vert du directeur")
        if re.search(r"[$`*?\[]", r):
            refuser("refspec non littérale (variable, motif) : écrire le nom de branche en clair")
        d = dst[len("refs/heads/"):] if dst.startswith("refs/heads/") else dst
        if d.lower() in {"main", "master"}:
            refuser("pousser sur main met en production ; seul le directeur en donne l'ordre")
    if pos and re.search(r"[$`]", pos[0]):
        refuser("dépôt distant non littéral dans git push")
    # Branche courante là où la commande s'exécutera.
    dossier = cwd
    if "-C" in glob:
        c = glob[glob.index("-C") + 1]
        dossier = c if os.path.isabs(c) else os.path.join(cwd or ".", c)
        if re.search(r"[$`~]", c):
            dossier = None
    if cd_avant:
        dossier = cd_dir
    implicites = not refspecs or any(refspec_dst(r)[0] in ("HEAD", "@") or refspec_dst(r)[1] in ("HEAD", "@")
                                     for r in refspecs)
    if not implicites:
        return
    if dossier is None or (cd_avant and not os.path.isdir(dossier)):
        refuser("git push implicite (HEAD ou sans refspec) dans un dossier non déterminable : nommer la branche")
    if branche_courante(dossier).lower() in {"main", "master"}:
        refuser("git push depuis main pousse sur main (production)")
    if not refspecs:
        rc, dest = git(dossier, "rev-parse", "--abbrev-ref", "@{push}")
        if rc == 0 and dest.split("/", 1)[-1].lower() in {"main", "master"}:
            refuser("git push sans refspec : la destination configurée (@{push}) est main (production)")


def verifier_push(cmd, cwd):
    """Cherche git push n'importe où dans la commande (sous-shell, bash -c, chemin absolu)."""
    plat = re.sub(r"(\"\"|'')", "", cmd)
    plat = re.sub(r"\\(?=[A-Za-z])", "", plat)
    if not re.search(r"\bpush\b", plat):
        return
    if re.search(r"\bgit\s+(checkout|switch)\s+(-\S+\s+)*(main|master)\b", plat):
        refuser("git push après un passage sur main pousserait sur main (production)")
    for m in POUSSE.finditer(plat):
        debut = m.start() + len(m.group(1))
        prefixe = plat[:debut]
        bout = re.split(r"[;&|\n)`]", plat[debut:], maxsplit=1)[0]
        bout = REDIR.sub(" ", bout)
        mots = [w.strip("'\"") for w in bout.split()]
        mots = [w for w in mots if w]
        if not mots:
            continue
        cds = list(re.finditer(r"(^|[\s;&|(])(cd|pushd)\s+(\S+)", prefixe))
        cd_dir = None
        if cds:
            c = cds[-1].group(3).strip("'\"")
            if not re.search(r"[$`~]", c):
                cd_dir = c if os.path.isabs(c) else os.path.join(cwd or ".", c)
        verifier_push_git(mots[1:], cwd, bool(cds), cd_dir)


# ---- gh, vercel, supabase, curl ---------------------------------------------

def verifier_gh(c):
    if re.search(r"\bgh\s+pr\s+create\b", c):
        base = re.search(r"(--base|-B)(=|\s+)['\"]?([^\s'\"]+)", c)
        if not base:
            refuser("gh pr create sans --base vise main par défaut ; donner --base <branche de travail>")
        if base.group(3).lower() in {"main", "master"}:
            refuser("aucune PR vers main sans le feu vert du directeur (consigne du directeur)")
    if re.search(r"\bgh\s+pr\s+edit\b", c) and re.search(r"(--base|-B)(=|\s+)['\"]?(main|master)\b", c):
        refuser("rebaser une PR sur main est interdit sans le feu vert du directeur")
    if re.search(r"\bgh\s+(pr\s+merge|workflow\s+(run|enable)|run\s+rerun|release\s+(create|edit|delete)"
                 r"|repo\s+(delete|rename|edit|archive|sync)|secret\s+(set|delete)|variable\s+(set|delete))\b", c):
        refuser("fusion, déclenchement de workflow, release ou réglage de dépôt GitHub réservés au directeur")
    if re.search(r"\bgh\s+api\b", c):
        if re.search(r"(/merges?\b|/git/refs|/dispatches\b|/contents/|graphql)", c):
            refuser("gh api sur fusion, références, contenu, dispatch ou GraphQL : réservé au directeur")
        ecrit = re.search(r"(\s(-X|--method)(=|\s*)['\"]?(POST|PUT|PATCH|DELETE)\b|\s(-f|-F|--field|--raw-field|--input)(=|\s))",
                          c, re.I)
        if ecrit and not re.search(r"/(issues|pulls)/\d+/comments\b|/pulls/\d+/reviews\b|/pulls/comments/\d+/replies\b", c):
            refuser("gh api en écriture interdit (seuls les commentaires de PR et d'issue sont permis)")


def verifier_autres(c):
    if re.search(r"\bvercel\b.*(--prod\b|--target[= ]production|\s(promote|rollback|alias|domains?|dns|rm|remove"
                 r"|redeploy|certs|project\s+rm)\b|\senv\s+(add|rm|pull))", c):
        refuser("action Vercel de production interdite depuis un agent")
    if re.search(r"\bsupabase\s+(db\s+(push|reset|pull|remote|dump)|migration\s+(up|repair|squash|fetch)"
                 r"|functions\s+(deploy|delete)|secrets\s+(set|unset)|link|projects|storage\s+(rm|cp|mv)|branches"
                 r"|orgs|sso|domains|vanity-subdomains|network-restrictions|ssl-enforcement|postgres-config)\b", c):
        refuser("commande Supabase distante réservée à ChatGPT sous feu vert")
    if re.search(r"\b(curl|wget|http|httpie|xh)\b.*(api\.supabase\.com|\.supabase\.co|api\.vercel\.com|api\.github\.com)", c) \
            and re.search(r"(\s-X\s*['\"]?(POST|PUT|PATCH|DELETE)|\s--request[= ]\s*(POST|PUT|PATCH|DELETE)"
                          r"|\s(-d|--data\S*|-F|--form|--json|-T|--upload-file|--post-data|--method)[\s=]|\s(POST|PUT|PATCH|DELETE)\s)",
                          c, re.I):
        refuser("écriture par API distante interdite depuis un agent")


LECTURE = re.compile(r"^(grep|rg|egrep|fgrep|cat|less|head|tail|wc|ls|git\s+(log|show|diff|grep|blame|ls-files))\b"
                     r"|^xargs(\s+-\S+)*\s+(grep|rg|egrep|fgrep)\b")


def verifier_bash(cmd, cwd, profondeur=0):
    if profondeur > 3:
        refuser("imbrication de shells trop profonde pour être vérifiée")
    codes = []
    texte = neutraliser_messages(cmd)
    texte = traiter_heredocs(texte, codes)
    for code in codes:
        verifier_code(code)
    verifier_push(texte, cwd)
    segs = decouper(texte)
    eff = cwd
    for seg in segs:
        c = " ".join(seg.split())
        mots, sorties, entrees = analyser_segment(seg)
        if mots and mots[0] == "git":
            verifier_ecriture(mots, sorties, entrees, eff, texte)
        else:
            verifier_ecriture(mots, sorties, entrees, eff or cwd, texte)
        if mots and mots[0] in ("cd", "pushd"):
            pos = options_et_args(mots[1:])
            if pos and eff is not None:
                eff = None if re.search(r"[$`~]", pos[0]) else os.path.normpath(
                    pos[0] if os.path.isabs(pos[0]) else os.path.join(eff, pos[0]))
        if mots and re.match(r"^(bash|sh|zsh|dash|ksh)$", mots[0]):
            for i, a in enumerate(mots[:-1]):
                if re.match(r"^-[a-zA-Z]*c$", a):
                    verifier_bash(mots[i + 1], cwd, profondeur + 1)
        if mots and mots[0] == "eval":
            verifier_bash(" ".join(mots[1:]), cwd, profondeur + 1)
        verifier_gh(c)
        verifier_autres(c)
        nu = ENVELOPPES.sub("", c)
        lecture = LECTURE.match(nu) or (mots and mots[0] in {"grep", "rg", "cat", "head", "tail", "less", "wc", "ls"})
        if PROD in c and not lecture:
            refuser("aucune commande d'agent Claude ne vise le projet de production")
        if re.search(r"SUPABASE_SERVICE_ROLE|service_role_key", c, re.I) and not lecture:
            refuser("la clé service_role ne s'utilise ni ne se lit")


# ---------------------------------------------------------------------------
# MCP
# ---------------------------------------------------------------------------

VERCEL_LECTURE = re.compile(r"^(get|list|search|count|aggregate|filter|read|web_fetch)_|^(git_namespaces|artifact_query)$")


def sql_en_ecriture(query):
    q = re.sub(r"\$(\w*)\$.*?\$\1\$", "''", str(query), flags=re.S)
    q = re.sub(r"'(?:''|[^'])*'", "''", q)
    q = re.sub(r"--[^\n]*|/\*.*?\*/", " ", q, flags=re.S)
    q = re.sub(r'"(?:""|[^"])*"', "x", q)
    if not LECTURE_SQL.match(q) or ECRITURE_SQL.search(q) or ";" in q.strip().rstrip(";"):
        return "execute_sql en écriture interdit aux agents Claude (lecture seule)"
    for m in re.finditer(r"([A-Za-z_][\w$]*(?:\s*\.\s*[A-Za-z_][\w$]*)?)\s*\(", q):
        nom = re.sub(r"\s+", "", m.group(1)).lower()
        court = nom.split(".")[-1]
        if PG_DANGEREUSES.search(nom):
            return f"execute_sql : fonction {nom} interdite (effet de bord sur le serveur)"
        if "." in nom and not nom.startswith(("pg_catalog.", "information_schema.")):
            return f"execute_sql : appel de fonction {nom} (RPC possible) interdit en lecture seule"
        if court in MOTS_SQL or court in FONCTIONS_LECTURE or court.startswith(PREFIXES_LECTURE):
            continue
        return f"execute_sql : fonction {nom} non reconnue comme lecture (RPC possible) ; lecture seule"
    return None


def verifier_mcp(nom, entree):
    texte = json.dumps(entree, ensure_ascii=False)
    action = nom.split("__")[-1]
    if nom.startswith("mcp__Supabase__"):
        mutations = {
            "apply_migration", "deploy_edge_function", "create_edge_function_secret",
            "merge_branch", "delete_branch", "reset_branch", "rebase_branch",
            "restore_project", "pause_project", "create_project", "create_branch",
        }
        if action in mutations:
            refuser(f"Supabase {action} est réservé à ChatGPT, sous feu vert du directeur")
        if action == "execute_sql":
            motif = sql_en_ecriture(entree.get("query", ""))
            if motif:
                refuser(motif)
        if PROD in texte and not re.match(r"^(get_|list_|search_|query_logs$|execute_sql$)", action):
            refuser("seules les lectures sont permises sur le projet de production")
    if nom.startswith("mcp__github__"):
        if action in {"merge_pull_request", "enable_pr_auto_merge", "actions_run_trigger", "create_repository",
                      "fork_repository"}:
            refuser("aucune fusion de PR, déclenchement de workflow ni création de dépôt par un agent ; le directeur décide")
        branche = str(entree.get("branch") or "").strip()
        branche = branche[len("refs/heads/"):] if branche.startswith("refs/heads/") else branche
        ecrit = action in {"push_files", "create_or_update_file", "delete_file"}
        if ecrit and not branche:
            refuser("écriture GitHub sans branche nommée : elle irait sur la branche par défaut (main)")
        if branche.lower() in {"main", "master"} and (ecrit or action == "create_branch"):
            refuser("rien vers main sans le feu vert du directeur (main = production)")
        if ecrit:
            chemins = [entree.get("path")] + [f.get("path") for f in (entree.get("files") or []) if isinstance(f, dict)]
            for ch in chemins:
                if ch:
                    verifier_chemin(ch)
        base = str(entree.get("base") or "").strip()
        base = base[len("refs/heads/"):] if base.startswith("refs/heads/") else base
        if action in {"create_pull_request", "update_pull_request"} and base.lower() in {"main", "master"}:
            refuser("aucune PR vers main sans le feu vert du directeur (consigne du directeur)")
    if nom.startswith("mcp__Vercel__") and not VERCEL_LECTURE.search(action):
        refuser("action Vercel en écriture réservée au directeur")


def main():
    # Au-delà de 15 s, Claude Code coupe le hook sans bloquer : on refuse avant.
    if hasattr(signal, "SIGALRM"):
        signal.signal(signal.SIGALRM, lambda *a: refuser(
            "commande trop longue pour être vérifiée à temps ; écrire le texte avec l'outil Write"))
        signal.alarm(10)
    try:
        donnees = json.load(sys.stdin.buffer)
        nom = donnees.get("tool_name", "")
        entree = donnees.get("tool_input", {}) or {}
        cwd = donnees.get("cwd") or os.environ.get("CLAUDE_PROJECT_DIR", ".")
        if nom in {"Edit", "Write", "MultiEdit", "NotebookEdit"}:
            verifier_chemin(entree.get("file_path") or entree.get("notebook_path"))
        elif nom in {"Bash", "Monitor"}:
            verifier_bash(str(entree.get("command", "")), cwd)
        elif nom.startswith("mcp__"):
            verifier_mcp(nom, entree)
    except Exception as e:  # échec fermé
        refuser(f"erreur interne du garde-fou ({type(e).__name__}) ; action refusée par prudence")
    sys.exit(0)


if __name__ == "__main__":
    main()
