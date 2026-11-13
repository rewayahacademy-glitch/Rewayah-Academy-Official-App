-- Import des formulaires : l'analyseur CSV rapide (migration 20261125100000) rend EXACTEMENT ce que rendait
-- l'ancien (signe par signe), lignes, erreurs et messages compris. L'ancien est recopie ici sous pg_temp,
-- tel que defini par 20261012184501. Cas tordus nommes, puis 4000 textes tires au hasard (graine fixe) sur
-- l'alphabet { a, espace, guillemet, virgule, CR, LF, arabe, BOM } ; plus un fichier de 60 lignes.
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations) ; tout est annule a la fin.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.parse_ancienne(p_csv text)
 RETURNS jsonb
 LANGUAGE plpgsql
 IMMUTABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  result jsonb := '[]'::jsonb;
  row_values jsonb := '[]'::jsonb;
  cell text := '';
  quoted boolean := false;
  just_closed_quote boolean := false;
  i integer := 1;
  ch text;
  next_ch text;
begin
  if p_csv is null or length(p_csv) > 5000000 then
    raise exception using errcode = '22023', message = 'CSV absent ou supérieur à 5 Mo';
  end if;
  if left(p_csv, 1) = chr(65279) then p_csv := substring(p_csv from 2); end if;
  while i <= length(p_csv) loop
    ch := substring(p_csv from i for 1);
    next_ch := substring(p_csv from i + 1 for 1);
    if quoted then
      if ch = '"' and next_ch = '"' then
        cell := cell || '"'; i := i + 1;
      elsif ch = '"' then
        quoted := false;
        just_closed_quote := true;
      else
        cell := cell || ch;
      end if;
    elsif just_closed_quote and ch not in (',', E'\n', E'\r') then
      raise exception using errcode = '22023', message = 'CSV mal formé après un guillemet fermant';
    elsif ch = '"' then
      if cell <> '' then raise exception using errcode = '22023', message = 'CSV mal formé'; end if;
      quoted := true;
    elsif ch = ',' then
      row_values := row_values || jsonb_build_array(cell); cell := ''; just_closed_quote := false;
    elsif ch = E'\n' or ch = E'\r' then
      row_values := row_values || jsonb_build_array(cell);
      if row_values <> jsonb_build_array('') then result := result || jsonb_build_array(row_values); end if;
      row_values := '[]'::jsonb; cell := ''; just_closed_quote := false;
      if ch = E'\r' and next_ch = E'\n' then i := i + 1; end if;
    else
      cell := cell || ch;
    end if;
    i := i + 1;
  end loop;
  if quoted then raise exception using errcode = '22023', message = 'CSV mal formé: guillemet non fermé'; end if;
  if cell <> '' or jsonb_array_length(row_values) > 0 then
    row_values := row_values || jsonb_build_array(cell);
    result := result || jsonb_build_array(row_values);
  end if;
  return result;
end;
$function$

;

-- Le resultat d'un analyseur : le JSON, ou le code et le message de l'erreur.
CREATE FUNCTION pg_temp.res(p_nouveau boolean, p_csv text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  IF p_nouveau THEN RETURN 'ok:' || private.parse_import_csv(p_csv)::text;
  ELSE RETURN 'ok:' || pg_temp.parse_ancienne(p_csv)::text; END IF;
EXCEPTION WHEN OTHERS THEN
  RETURN 'err:' || SQLSTATE || ':' || SQLERRM;
END $$;

DO $eq$
DECLARE
  v_cas text[] := ARRAY[
    '', 'a', E'a\n', E'a,b\nc,d', E'a,b\r\nc,d\r\n', E'a,b\rc,d\r', E'a\n\rb', E'\r\r\n\n',
    E'a,"b,c",d\n', E'a,"x ""q"" y",d\n', '"a"', '""', E'""\n', E'"",""\n', E'a,""', E'a,""\nb', E'"""',
    E'""""', E'"a"""', E'"a""b"', E'"a\nb"\n', E'"a\r\nb",c', ',', ',,', E',\n', E'\n\n\n', E'a,\n', E',a',
    E'a,b\n\nc,d\n', E'a,b\n,\nc', E'"a"b', E'"a" ,b', E'a"b', E'a,b"c"', E'"a"\n"b"', E'"a",', E'"a"x',
    E'"a"\r', E'"a"""\n', E'x,"\n', '"', E'a,"b', E'a,b,"c\n,d', E'"a""', chr(65279) || E'a,b\n', chr(65279),
    chr(65279) || chr(65279) || 'a', E'ا,"ب ""ج""",د\nه\n', E'"ا\nب",ج', E' ,\t\n', E'a\n"b""\n"', E'"",a\n"",b',
    E'a,""b', E'"a",""', E'"a"\n\n"b"', E'"a"\r\n\r\n"b"'];
  v_c text;
  v_i integer;
  v_k integer;
  v_s text;
  v_alpha text[] := ARRAY['a', ' ', '"', ',', E'\r', E'\n', 'ب', '"', ',', E'\n', chr(65279)];
  v_n integer := 0;
BEGIN
  PERFORM setseed(0.4242);
  FOREACH v_c IN ARRAY v_cas LOOP
    IF pg_temp.res(true, v_c) IS DISTINCT FROM pg_temp.res(false, v_c) THEN
      RAISE EXCEPTION 'EQUIV ROUGE : cas % : % contre %', v_c, pg_temp.res(true, v_c), pg_temp.res(false, v_c);
    END IF;
    v_n := v_n + 1;
  END LOOP;
  FOR v_i IN 1 .. 4000 LOOP
    v_s := '';
    FOR v_k IN 1 .. 1 + floor(random() * 14)::integer LOOP
      v_s := v_s || v_alpha[1 + floor(random() * array_length(v_alpha, 1))::integer];
    END LOOP;
    IF pg_temp.res(true, v_s) IS DISTINCT FROM pg_temp.res(false, v_s) THEN
      RAISE EXCEPTION 'EQUIV ROUGE : texte au hasard % : % contre %', v_s::bytea, pg_temp.res(true, v_s), pg_temp.res(false, v_s);
    END IF;
    v_n := v_n + 1;
  END LOOP;
  -- NULL et plus de 5 000 000 de signes : memes refus.
  IF pg_temp.res(true, NULL) IS DISTINCT FROM pg_temp.res(false, NULL)
     OR pg_temp.res(true, repeat('a', 5000001)) IS DISTINCT FROM pg_temp.res(false, repeat('a', 5000001)) THEN
    RAISE EXCEPTION 'EQUIV ROUGE : NULL ou fichier trop long';
  END IF;
  IF pg_temp.res(true, NULL) NOT LIKE 'err:22023:%' THEN RAISE EXCEPTION 'EQUIV ROUGE : refus NULL'; END IF;
  -- Un fichier de 60 lignes d'arabe, de guillemets doubles, de virgules et de retours a la ligne dans les cellules.
  v_s := 'h1,h2,h3' || E'\r\n';
  FOR v_i IN 1 .. 60 LOOP
    v_s := v_s || '"اسم ' || v_i || '","ملاحظة ""x"", ثم' || E'\n' || 'سطر ثان",' || (CASE WHEN v_i % 7 = 0 THEN '' ELSE 'v' || v_i END)
           || CASE WHEN v_i % 2 = 0 THEN E'\r\n' ELSE E'\n' END;
  END LOOP;
  v_s := v_s || 'dernier,sans,saut';
  IF pg_temp.res(true, v_s) IS DISTINCT FROM pg_temp.res(false, v_s)
     OR jsonb_array_length(private.parse_import_csv(v_s)) <> 62 THEN
    RAISE EXCEPTION 'EQUIV ROUGE : fichier de 60 lignes';
  END IF;
  RAISE NOTICE 'EQUIV OK : % textes identiques (lignes, codes et messages d''erreur)', v_n + 3;
END
$eq$;

-- Le temps : un fichier de ~630 Ko d'arabe (l'ancien analyseur y depassait 120 s) se lit en moins de 2 s.
DO $t$
DECLARE
  v_csv text := 'h1,h2,h3' || E'\n' || repeat('"اسم عربي طويل ""x"", ثم' || E'\n' || 'سطر ثان",ملاحظة,قيمة' || E'\r\n', 6500);
  v_t0 timestamptz := clock_timestamp();
  v_n integer;
BEGIN
  v_n := jsonb_array_length(private.parse_import_csv(v_csv));
  IF v_n <> 6501 OR clock_timestamp() - v_t0 > interval '2 seconds' THEN
    RAISE EXCEPTION 'EQUIV ROUGE : % lignes en % (octets : %)', v_n, clock_timestamp() - v_t0, octet_length(v_csv);
  END IF;
  RAISE NOTICE 'EQUIV OK : % octets lus en %', octet_length(v_csv), clock_timestamp() - v_t0;
END
$t$;

ROLLBACK;
