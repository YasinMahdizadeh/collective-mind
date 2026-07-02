-- Im Supabase Dashboard unter "SQL Editor" einfügen und ausführen.
-- Spiegelt die clientseitige Filterung aus index.html, aber serverseitig
-- und nicht über die Browser-Konsole umgehbar.
--
-- Verhalten: Wenn das Wort in `words.text` unangemessen ist ODER mit einem
-- Großbuchstaben beginnt, wird der Insert still übersprungen (kein Fehler,
-- die Webseite zeigt weiterhin "Sent!").

create or replace function public.filter_inappropriate_words()
returns trigger
language plpgsql
as $$
declare
  normalized text;
  blocked text[] := array[
    -- Deutsch
    'arsch', 'arschloch', 'scheisse', 'hurensohn', 'hure', 'nutte', 'fotze',
    'wichser', 'schlampe', 'missgeburt', 'spast', 'spasti', 'behindert',
    'mongo', 'neger', 'kanake', 'schwuchtel', 'fick', 'ficken',
    'verpissdich', 'drecksau', 'drecksack', 'bastard', 'idiot', 'trottel',
    -- Englisch
    'fuck', 'shit', 'bitch', 'dick', 'asshole', 'cunt', 'pussy', 'nigger',
    'nigga', 'faggot', 'retard', 'whore', 'slut', 'motherfucker'
  ];
  word text;
begin
  -- Großer Anfangsbuchstabe (z.B. Namen) -> zensieren
  if new.text ~ '^[A-ZÄÖÜ]' then
    return null;
  end if;

  -- Normalisieren: Kleinbuchstaben, Umlaute/ß, Zahlen->Buchstaben, nur a-z behalten
  normalized := lower(new.text);
  normalized := translate(normalized, 'äöü', 'aou');
  normalized := replace(normalized, 'ß', 'ss');
  normalized := translate(normalized, '@43105$7!', 'aaeiossti');
  normalized := regexp_replace(normalized, '[^a-z]', '', 'g');

  foreach word in array blocked loop
    if normalized like '%' || word || '%' then
      return null;
    end if;
  end loop;

  return new;
end;
$$;

drop trigger if exists trg_filter_words on public.words;

create trigger trg_filter_words
  before insert on public.words
  for each row execute function public.filter_inappropriate_words();
