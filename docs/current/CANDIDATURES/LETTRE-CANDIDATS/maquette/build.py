import re, html, sys, json

SRC = sys.argv[1]
TPL = sys.argv[2]
OUT = sys.argv[3]

md = open(SRC, encoding="utf-8").read()
md = md[md.index("## 1. Pourquoi"):]

def inline(s):
    s = html.escape(s, quote=False)
    s = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", s)
    return s

# Praxis placé dans chaque partie : (geste, expression, phrase). Propositions, à valider.
PRAXIS = {
    "1": ("salut", "joie", "Bonjour ! Je suis Praxis. Je vous accompagne dans cette lettre. Prenez votre temps."),
    "4": ("pointe", "sourire", "Ici, les vrais chiffres. Regardez le tableau, tout y est."),
    "6": ("un", "concentre", "Retenez trois chiffres : 3, 8 et 11 minutes."),
    "7": ("montre", "attente", "L'attente peut durer. Gardez vos activités, et surveillez vos messages."),
    "8": ("coeur", "paisible", "C'est pour protéger les enfants. Et c'est vous aussi qu'on protège."),
    "11": ("salut", "gene", "C'est moi ! Je suis en pause pour l'instant : on me règle avant de me relancer."),
    "decider": ("coeur", "sourire", "Quelle que soit votre réponse, merci d'avoir lu jusqu'au bout."),
}

def praxis_block(key, side):
    g, e, phrase = PRAXIS[key]
    return (f'<aside class="px-guide px-{side}" aria-label="Praxis">'
            f'<div class="px-fig" data-geste="{g}" data-expr="{e}" role="img" aria-label="Praxis, l\'assistant de l\'académie"></div>'
            f'<p class="px-bulle"><span class="px-nom">Praxis</span>{html.escape(phrase)}</p></aside>')

lines = md.split("\n")
out = []
toc = []
i = 0
cur_sec = None
side = "d"
in_faq = False

def flush_list(items, ordered, cls=""):
    tag = "ol" if ordered else "ul"
    c = f' class="{cls}"' if cls else ""
    return f"<{tag}{c}>" + "".join(f"<li>{inline(x)}</li>" for x in items) + f"</{tag}>"

while i < len(lines):
    ln = lines[i]
    if not ln.strip():
        i += 1; continue
    m = re.match(r"^## (?:(\d+)\. )?(.+)$", ln)
    if m:
        if in_faq:
            out.append("</div>"); in_faq = False
        if cur_sec is not None:
            out.append("</section>")
        num, titre = m.group(1), m.group(2)
        key = num or "decider"
        sid = f"partie-{key}"
        cur_sec = key
        toc.append((sid, num, titre))
        attrs = ""
        if key in PRAXIS:
            g, e, ph = PRAXIS[key]
            attrs = f' data-geste="{g}" data-expr="{e}" data-phrase="{html.escape(ph, quote=True)}"'
        out.append(f'<section class="partie" id="{sid}"{attrs}><h2>' + (f'<span class="num">{num}</span>' if num else "") + f"{inline(titre)}</h2>")
        if key == "13":
            out.append('<div class="faq">'); in_faq = True
        i += 1; continue
    if ln.startswith("### "):
        out.append(f"<h3>{inline(ln[4:])}</h3>"); i += 1; continue
    if ln.startswith("|"):
        rows = []
        while i < len(lines) and lines[i].startswith("|"):
            cells = [c.strip() for c in lines[i].strip().strip("|").split("|")]
            if not all(re.fullmatch(r"-+", c) for c in cells):
                rows.append(cells)
            i += 1
        h = rows[0]
        t = '<div class="tableau"><table><thead><tr>' + "".join(f"<th scope=\"col\">{inline(c)}</th>" for c in h) + "</tr></thead><tbody>"
        for r in rows[1:]:
            cls = ' class="fort"' if r[0].startswith("Votre part") or r[0].startswith("Classe pleine") else ""
            t += f"<tr{cls}><th scope=\"row\">{inline(r[0])}</th>" + "".join(f"<td>{inline(c)}</td>" for c in r[1:]) + "</tr>"
        out.append(t + "</tbody></table></div>"); continue
    if re.match(r"^\d+\. ", ln):
        items = []
        while i < len(lines) and re.match(r"^\d+\. ", lines[i]):
            items.append(re.sub(r"^\d+\. ", "", lines[i])); i += 1
        cls = "etapes"
        if cur_sec == "6": cls = "chrono"
        out.append(flush_list(items, True, cls)); continue
    if ln.startswith("- "):
        items = []
        while i < len(lines) and lines[i].startswith("- "):
            items.append(lines[i][2:]); i += 1
        out.append(flush_list(items, False)); continue
    # paragraphe (une question de la FAQ tient sur deux lignes)
    if in_faq and ln.startswith("**") and ln.endswith("**") and i + 1 < len(lines) and lines[i+1].strip():
        q = ln.strip("*"); a = lines[i+1]
        out.append(f"<details><summary>{inline(q)}</summary><p>{inline(a)}</p></details>")
        i += 2; continue
    if ln.startswith("**La direction") or ln.startswith("La direction de Rewayah") or ln.startswith("#Ra_staff"):
        out.append(f'<p class="signature">{inline(ln)}</p>'); i += 1; continue
    out.append(f"<p>{inline(ln)}</p>"); i += 1

if in_faq: out.append("</div>")
out.append("</section>")

toc_html = "".join(
    f'<li><a href="#{sid}">' + (f'<span class="num">{n}</span>' if n else '<span class="num">✓</span>') + f"{inline(t)}</a></li>"
    for sid, n, t in toc)

tpl = open(TPL, encoding="utf-8").read()
open(OUT, "w", encoding="utf-8").write(tpl.replace("{{TOC}}", toc_html).replace("{{CONTENT}}", "\n".join(out)))
print("ok", len(toc), "parties")
