DO $$
BEGIN
    -- сами операторы могут и отсутствовать
END;
$$;

DO $$
DECLARE
    -- Это однострочный комментарий.
    /* А это — многострочный.
       После каждого объявления ставится знак ';'.
       Этот же знак ставится после каждого оператора.
    */
    foo text;
    bar text := 'World'; -- также допускается = или DEFAULT
BEGIN
    foo := 'Hello'; -- это присваивание
    RAISE NOTICE '%, %!', foo, bar; -- вывод сообщения
END;
$$;

DO $$
DECLARE
    foo integer NOT NULL := 0;
    bar CONSTANT text := 42;
BEGIN
    bar := bar + 1; -- ошибка
END;
$$;

DO $$
<<outer_block>>
DECLARE
    foo text := 'Hello';
BEGIN
    <<inner_block>>
    DECLARE
        foo text := 'World';
    BEGIN
        RAISE NOTICE '%, %!', outer_block.foo, inner_block.foo;
        RAISE NOTICE 'Без метки — внутренняя переменная: %', foo;
    END inner_block;
END outer_block;
$$;

CREATE FUNCTION sqr_in(IN a numeric) RETURNS numeric
AS $$
BEGIN
    RETURN a * a;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION sqr_out(IN a numeric, OUT retval numeric)
AS $$
BEGIN
    retval := a * a;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION sqr_inout(INOUT a numeric)
AS $$
BEGIN
    a := a * a;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

SELECT sqr_in(3), sqr_out(3), sqr_inout(3);

CREATE FUNCTION fmt (IN phone text, OUT code text, OUT num text)
AS $$
BEGIN
    IF phone ~ '^[0-9]*$' AND length(phone) = 10 THEN
        code := substr(phone,1,3);
        num  := substr(phone,4);
    ELSE
        code := NULL;
        num  := NULL;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

SELECT fmt('8122128506');

DO $$
DECLARE
    code text := (fmt('8122128506')).code;
BEGIN
    CASE
        WHEN code IN ('495','499') THEN
            RAISE NOTICE '% — Москва', code;
        WHEN code = '812' THEN
            RAISE NOTICE '% — Санкт-Петербург', code;
        WHEN code = '384' THEN
            RAISE NOTICE '% — Кемеровская область', code;
        ELSE
            RAISE NOTICE '% — Прочие', code;
    END CASE;
END;
$$;

DO $$
DECLARE
    code text := (fmt('8122128506')).code;
BEGIN
    CASE code
        WHEN '495', '499' THEN
            RAISE NOTICE '% — Москва', code;
        WHEN '812' THEN
            RAISE NOTICE '% — Санкт-Петербург', code;
        WHEN '384' THEN
            RAISE NOTICE '% — Кемеровская область', code;
        ELSE
            RAISE NOTICE '% — Прочие', code;
    END CASE;
END;
$$;

CREATE FUNCTION reverse_for (line text) RETURNS text
AS $$
DECLARE
    line_length CONSTANT int := length(line);
    retval text := '';
BEGIN
    FOR i IN 1 .. line_length
    LOOP
        retval := substr(line, i, 1) || retval;
    END LOOP;
    RETURN retval;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE FUNCTION reverse_while (line text) RETURNS text
AS $$
DECLARE
    line_length CONSTANT int := length(line);
    i int := 1;
    retval text := '';
BEGIN
    WHILE i <= line_length
    LOOP
        retval := substr(line, i, 1) || retval;
        i := i + 1;
    END LOOP;
    RETURN retval;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE FUNCTION reverse_loop (line text) RETURNS text
AS $$
DECLARE
    line_length CONSTANT int := length(reverse_loop.line);
    i int := 1;
    retval text := '';
BEGIN
    <<main_loop>>
    LOOP
        EXIT main_loop WHEN i > line_length;
        retval := substr(reverse_loop.line, i,1) || retval;
        i := i + 1;
    END LOOP;
    RETURN retval;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

SELECT reverse_for('главрыба') as "for",
          reverse_while('главрыба') as "while",
          reverse_loop('главрыба') as "loop";

DO $$
DECLARE
    s integer := 0;
BEGIN
    FOR i IN 1 .. 100
    LOOP
        s := s + i;
        CONTINUE WHEN mod(i, 10) != 0;
        RAISE NOTICE 'i = %, s = %', i, s;
    END LOOP;
END;
$$;

DO $$
BEGIN
    RAISE NOTICE '%', CASE 2+2 WHEN 4 THEN 'Все в порядке' END;
END;
$$

DO $$
BEGIN
    RAISE NOTICE '%', (
        SELECT code
        FROM (VALUES (1, 'Раз'), (2, 'Два')) t(id, code)
        WHERE id = 1
    );
END;
$$;

CREATE OR REPLACE FUNCTION shorten(
    s text,
    max_len integer DEFAULT 45,
    suffix text DEFAULT '...'
)
RETURNS text AS $$
DECLARE
    suffix_len integer := length(suffix);
BEGIN
    RETURN CASE WHEN length(s) > max_len
        THEN left(s, max_len - suffix_len) || suffix
        ELSE s
    END;
END;
$$ IMMUTABLE LANGUAGE plpgsql;

SELECT shorten(
    'Путешествия в некоторые удаленные страны мира в четырех частях: сочинение Лемюэля Гулливера, сначала хирурга, а затем капитана нескольких кораблей'
);

SELECT shorten(
    'Путешествия в некоторые удаленные страны мира в четырех частях: сочинение Лемюэля Гулливера, сначала хирурга, а затем капитана нескольких кораблей',
    30
);

CREATE OR REPLACE FUNCTION book_name(book_id integer, title text)
RETURNS text
AS $$
SELECT shorten(book_name.title) ||
       '. ' ||
       string_agg(
           author_name(a.last_name, a.first_name, a.middle_name), ', '
           ORDER BY ash.seq_num
       )
FROM   authors a
       JOIN authorship ash ON a.author_id = ash.author_id
WHERE  ash.book_id = book_name.book_id;
$$ STABLE LANGUAGE sql;

CREATE OR REPLACE FUNCTION shorten(
    s text,
    max_len integer DEFAULT 45,
    suffix text DEFAULT '...'
)
RETURNS text
AS $$
DECLARE
    suffix_len integer := length(suffix);
    short text := suffix;
    pos integer;
BEGIN
    IF length(s) < max_len THEN
        RETURN s;
    END IF;
    FOR pos in 1 .. least(max_len-suffix_len+1, length(s))
    LOOP
        IF substr(s,pos-1,1) != ' ' AND substr(s,pos,1) = ' ' THEN
            short := left(s, pos-1) || suffix;
        END IF;
    END LOOP;
    RETURN short;
END;
$$ IMMUTABLE LANGUAGE plpgsql;

SELECT shorten(
    'Путешествия в некоторые удаленные страны мира в четырех частях: сочинение Лемюэля Гулливера, сначала хирурга, а затем капитана нескольких кораблей'
);

CREATE FUNCTION rnd_integer(min_value integer, max_value integer)
RETURNS integer
AS $$
DECLARE
    retval integer;
BEGIN
    IF max_value <= min_value THEN
       RETURN NULL;
    END IF;

    retval := floor(
            (max_value+1 - min_value)*random()
	)::integer + min_value;
    RETURN retval;
END;
$$ STRICT LANGUAGE plpgsql;

SELECT rnd_integer(0,1) as "0 - 1",
          rnd_integer(1,365) as "1 - 365",
          rnd_integer(-30,30) as "-30 - +30"
   FROM generate_series(1,10);

SELECT rnd_value, count(*)
FROM (
    SELECT rnd_integer(1,5) AS rnd_value
    FROM generate_series(1,100000)
) AS t
GROUP BY rnd_value ORDER BY rnd_value;

CREATE FUNCTION rnd_text(
   len int,
   list_of_chars text DEFAULT 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюяABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_0123456789'
) RETURNS text
AS $$
DECLARE
    len_of_list CONSTANT integer := length(list_of_chars);
    i integer;
    retval text := '';
BEGIN
    FOR i IN 1 .. len
    LOOP
        -- добавляем к строке случайный символ
        retval := retval ||
                  substr(list_of_chars, rnd_integer(1,len_of_list),1);
    END LOOP;
    RETURN retval;
END;
$$ STRICT LANGUAGE plpgsql;

SELECT rnd_text(rnd_integer(1,30)) FROM generate_series(1,10);

DO $$
DECLARE
    x integer;
    choice integer;
    new_choice integer;
    remove integer;
    total_games integer := 1000;
    old_choice_win_counter integer := 0;
    new_choice_win_counter integer := 0;
BEGIN
    FOR i IN 1 .. total_games
    LOOP
        -- Загадываем выигрышный наперсток
        x := rnd_integer(1,3);

        -- Игрок делает выбор
        choice := rnd_integer(1,3);

        -- Убираем один неверный ответ, кроме выбора игрока
        FOR i IN 1 .. 3
        LOOP
            IF i NOT IN (x, choice) THEN
                remove := i;
                EXIT;
            END IF;
        END LOOP;

        -- Нужно ли игроку менять свой выбор?

        -- Измененный выбор
        FOR i IN 1 .. 3
        LOOP
            IF i NOT IN (remove, choice) THEN
                new_choice := i;
                EXIT;
            END IF;
        END LOOP;

        -- Или начальный, или новый выбор обязательно выиграют
        IF choice = x THEN
            old_choice_win_counter := old_choice_win_counter + 1;
        ELSIF new_choice = x THEN
            new_choice_win_counter := new_choice_win_counter + 1;
        END IF;
    END LOOP;

    RAISE NOTICE 'Выиграл начальный выбор:  % из %',
        old_choice_win_counter, total_games;
    RAISE NOTICE 'Выиграл измененный выбор: % из %',
        new_choice_win_counter, total_games;
END;
$$;

CREATE FUNCTION do_something() RETURNS void
AS $$
BEGIN
    RAISE NOTICE 'Что-то сделалось.';
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    PERFORM do_something();
END;
$$;

DO $$
BEGIN
    CREATE TABLE test(n integer);
    INSERT INTO test VALUES (1),(2),(3);
    UPDATE test SET n = n + 1 WHERE n > 1;
    DELETE FROM test WHERE n = 1;
    DROP TABLE test;
END;
$$;

CREATE TABLE test(n integer);

CREATE PROCEDURE foo()
AS $$
BEGIN
    INSERT INTO test VALUES (1);
    COMMIT;
    INSERT INTO test VALUES (2);
    ROLLBACK;
END;
$$ LANGUAGE plpgsql;

CALL foo();
SELECT * FROM test;

BEGIN;
CALL foo();
ROLLBACK;

CREATE OR REPLACE PROCEDURE foo()
AS $$
BEGIN
    CALL baz();
END;
$$ LANGUAGE plpgsql;

CREATE PROCEDURE bar()
AS $$
BEGIN
    CALL baz();
END;
$$ LANGUAGE plpgsql;

CREATE PROCEDURE baz()
AS $$
BEGIN
    COMMIT;
END;
$$ LANGUAGE plpgsql;

CALL foo();

CREATE FUNCTION qux() RETURNS void
AS $$
BEGIN
    CALL bar();
END;
$$ LANGUAGE plpgsql;
SELECT qux();

CREATE TABLE t(id integer, code text);
INSERT INTO t VALUES (1, 'Раз'), (2, 'Два');

DO $$
DECLARE
    r record;
BEGIN
    SELECT id, code INTO r FROM t WHERE id = 1;
    RAISE NOTICE '%', r;
END;
$$;

DO $$
DECLARE
    r record;
BEGIN
    UPDATE t SET code = code || '!' WHERE id = 1 RETURNING * INTO r;
    RAISE NOTICE 'Изменили: %', r;
END;
$$;

SET plpgsql.extra_warnings = 'all';

CREATE PROCEDURE bugs(INOUT a integer)
AS $$
DECLARE
    a integer;
    b integer;
BEGIN
    SELECT id INTO a, b FROM t;
END;
$$ LANGUAGE plpgsql;

CALL bugs(42);
RESET plpgsql.extra_warnings;

CREATE EXTENSION plpgsql_check;
 SELECT * FROM plpgsql_check_function('bugs(integer)');

DO $$
DECLARE
    id   integer := 1;
    code text;
BEGIN
    SELECT id, code INTO id, code
    FROM t WHERE id = id;
    RAISE NOTICE '%, %', id, code;
END;
$$;

DO $$
DECLARE
    l_id   integer := 1;
    l_code text;
BEGIN
    SELECT id, code INTO l_id, l_code
    FROM t WHERE id = l_id;
    RAISE NOTICE '%, %', l_id, l_code;
END;
$$;

DO $$
<<local>>
DECLARE
    id   integer := 1;
    code text;
BEGIN
    SELECT t.id, t.code INTO local.id, local.code
    FROM t WHERE t.id = local.id;
    RAISE NOTICE '%, %', id, code;
END;
$$;

SET plpgsql.variable_conflict = use_variable;

DO $$
DECLARE
    id   integer := 1;
    code text;
BEGIN
    SELECT t.id, t.code INTO id, code
    FROM t WHERE t.id = id;
    RAISE NOTICE '%, %', id, code;
END;
$$;

RESET plpgsql.variable_conflict;

DO $$
DECLARE
    r record;
BEGIN
    SELECT id, code INTO r FROM t;
    RAISE NOTICE '%', r;
END;
$$;
SELECT * FROM t;

DO $$
DECLARE
    r record;
BEGIN
    UPDATE t SET code = code || '!' RETURNING * INTO r;
    RAISE NOTICE 'Изменили: %', r;
END;
$$;
DO $$
DECLARE
    r record;
BEGIN
    r := (-1,'!!!');
    SELECT id, code INTO r FROM t WHERE false;
    RAISE NOTICE '%', r;
END;
$$;
DO $$
DECLARE
    r record;
BEGIN
    UPDATE t SET code = code || '!' WHERE id = -1
        RETURNING * INTO r;
    RAISE NOTICE 'Изменили: %', r;
END;
$$;
DO $$
DECLARE
    r record;
BEGIN
    SELECT id, code INTO STRICT r FROM t;
    RAISE NOTICE '%', r;
END;
$$;
DO $$
DECLARE
    r record;
BEGIN
    UPDATE t SET code = code || '!' WHERE id = -1 RETURNING * INTO STRICT r;
    RAISE NOTICE 'Изменили: %', r;
END;
$$;
DO $$
DECLARE
    r record;
    rowcount integer;
BEGIN
    SELECT id, code INTO r FROM t WHERE false;

    GET DIAGNOSTICS rowcount = row_count;
    RAISE NOTICE 'rowcount = %', rowcount;
    RAISE NOTICE 'found = %', FOUND;
END;
$$;
DO $$
DECLARE
    r record;
    rowcount integer;
BEGIN
    SELECT id, code INTO r FROM t;

    GET DIAGNOSTICS rowcount = row_count;
    RAISE NOTICE 'rowcount = %', rowcount;
    RAISE NOTICE 'found = %', FOUND;
END;
$$;

CREATE FUNCTION t() RETURNS TABLE(LIKE t)
AS $$
BEGIN
    RETURN QUERY SELECT id, code FROM t ORDER BY id;
END;
$$ STABLE LANGUAGE plpgsql;
SELECT * FROM t();

CREATE FUNCTION days_of_week() RETURNS SETOF text
AS $$
BEGIN
    FOR i IN 7 .. 13 LOOP
        RETURN NEXT to_char(to_date(i::text,'J'),'TMDy');
    END LOOP;
END;
$$ STABLE LANGUAGE plpgsql;
 SELECT * FROM days_of_week() WITH ORDINALITY;

SET lc_time = 'en_US.UTF8';

CREATE OR REPLACE FUNCTION add_author(
    last_name text,
    first_name text,
    middle_name text
) RETURNS integer
AS $$
DECLARE
    author_id integer;
BEGIN
    INSERT INTO authors(last_name, first_name, middle_name)
        VALUES (last_name, first_name, middle_name)
        RETURNING authors.author_id INTO author_id;
    RETURN author_id;
END;
$$ VOLATILE LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION buy_book(book_id integer)
RETURNS void
AS $$
BEGIN
    INSERT INTO operations(book_id, qty_change)
        VALUES (book_id, -1);
END;
$$ VOLATILE LANGUAGE plpgsql;

CREATE TABLE animals(
    id     integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    yes_id integer REFERENCES animals(id),
    no_id  integer REFERENCES animals(id),
    name   text
);
INSERT INTO animals(name) VALUES
    ('млекопитающее'), ('слон'), ('черепаха');

UPDATE animals SET yes_id = 2, no_id = 3 WHERE id = 1;
SELECT * FROM animals ORDER BY id;

CREATE FUNCTION start_game(
    OUT context integer,
    OUT question text
)
AS $$
DECLARE
    root_id CONSTANT integer := 1;
BEGIN
    SELECT id, name||'?'
    INTO context, question
    FROM animals
    WHERE id = root_id;
END;
$$ LANGUAGE plpgsql;
CREATE FUNCTION continue_game(
    INOUT context integer,
    IN answer boolean,
    OUT you_win boolean,
    OUT question text
)
AS $$
DECLARE
    new_context integer;
BEGIN
    SELECT CASE WHEN answer THEN yes_id ELSE no_id END
    INTO new_context
    FROM animals
    WHERE id = context;

    IF new_context IS NULL THEN
        you_win := NOT answer;
        question := CASE
            WHEN you_win THEN 'Сдаюсь'
            ELSE 'Вы проиграли'
        END;
    ELSE
        SELECT id, null, name||'?'
        INTO context, you_win, question
        FROM animals
        WHERE id = new_context;
    END IF;
END;
$$ LANGUAGE plpgsql;
CREATE FUNCTION end_game(
    IN context integer,
    IN name text,
    IN question text
) RETURNS void
AS $$
DECLARE
    new_animal_id integer;
    new_question_id integer;
BEGIN
    INSERT INTO animals(name) VALUES (name)
        RETURNING id INTO new_animal_id;
    INSERT INTO animals(name) VALUES (question)
        RETURNING id INTO new_question_id;
    UPDATE animals SET yes_id = new_question_id
    WHERE yes_id = context;
    UPDATE animals SET  no_id = new_question_id
    WHERE  no_id = context;
    UPDATE animals SET yes_id = new_animal_id, no_id = context
    WHERE id = new_question_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM start_game();
SELECT * FROM continue_game(1,true);
SELECT * FROM continue_game(2,false);
SELECT * FROM end_game(2,'кит','живет в воде');
SELECT * FROM animals ORDER BY id;

SELECT * FROM start_game();
SELECT * FROM continue_game(1,true);
SELECT * FROM continue_game(5,true);
SELECT * FROM continue_game(4,true);

CREATE TABLE t(id integer, s text);
 INSERT INTO t VALUES (1, 'Раз'), (2, 'Два'), (3, 'Три');

DO $$
DECLARE
    -- объявление переменной
    cur refcursor;
BEGIN
    -- связывание с запросом и открытие курсора
    OPEN cur FOR SELECT * FROM t;
END;
$$;
DO $$
DECLARE
    -- объявление и связывание переменной
    cur CURSOR FOR SELECT * FROM t;
BEGIN
    -- открытие курсора
    OPEN cur;
END;
$$;
DO $$
DECLARE
    -- объявление и связывание переменной
    cur CURSOR(id integer) FOR SELECT * FROM t WHERE t.id = cur.id;
BEGIN
    -- открытие курсора с указанием фактических параметров
    OPEN cur(1);
END;
$$;
DO $$
<<local>>
DECLARE
    id integer := 3;
    -- объявление и связывание переменной
    cur CURSOR FOR SELECT * FROM t WHERE t.id = local.id;
BEGIN
    id := 1;
    -- открытие курсора (значение id берется на этот момент)
    OPEN cur;
END;
$$;

DO $$
DECLARE
    cur refcursor;
    rec record; -- можно использовать и несколько скалярных переменных
BEGIN
    OPEN cur FOR SELECT * FROM t ORDER BY id;
    MOVE cur;
    FETCH cur INTO rec;
    RAISE NOTICE '%', rec;
    CLOSE cur;
END;
$$;
DO $$
DECLARE
    cur refcursor;
    rec record;
BEGIN
    OPEN cur FOR SELECT * FROM t;
    LOOP
        FETCH cur INTO rec;
        EXIT WHEN NOT FOUND; -- FOUND: выбрана ли очередная строка?
        RAISE NOTICE '%', rec;
    END LOOP;
    CLOSE cur;
END;
$$;
DO $$
DECLARE
    cur CURSOR FOR SELECT * FROM t;
    -- переменная цикла не объявляется
BEGIN
    FOR rec IN cur LOOP -- cur должна быть связана с запросом
        RAISE NOTICE '%', rec;
    END LOOP;
END;
$$;
DO $$
DECLARE
    rec record; -- надо объявить явно
BEGIN
    FOR rec IN (SELECT * FROM t) LOOP
        RAISE NOTICE '%', rec;
    END LOOP;
END;
$$;
DO $$
DECLARE
    rec_outer record;
    rec_inner record;
BEGIN
    <<outer>>
    FOR rec_outer IN (SELECT * FROM t ORDER BY id) LOOP
        <<inner>>
        FOR rec_inner IN (SELECT * FROM t ORDER BY id) LOOP
            EXIT outer WHEN rec_inner.id = 3;
            RAISE NOTICE '%, %', rec_outer, rec_inner;
        END LOOP INNER;
    END LOOP outer;
END;
$$;
DO $$
DECLARE
    rec record;
BEGIN
    FOR rec IN (SELECT * FROM t WHERE false) LOOP
        RAISE NOTICE '%', rec;
    END LOOP;
    RAISE NOTICE 'Была ли как минимум одна итерация? %', FOUND;
END;
$$;
DO $$
DECLARE
    cur refcursor;
    rec record;
BEGIN
    OPEN cur FOR SELECT * FROM t
        FOR UPDATE; -- строки блокируются по мере обработки
    LOOP
        FETCH cur INTO rec;
        EXIT WHEN NOT FOUND;
        UPDATE t SET s = s || ' (обработано)' WHERE CURRENT OF cur;
    END LOOP;
    CLOSE cur;
END;
$$;
SELECT * FROM t;

BEGIN;
DO $$
DECLARE
    rec record;
BEGIN
    FOR rec IN (SELECT * FROM t) LOOP
        RAISE NOTICE '%', rec;
        DELETE FROM t WHERE id = rec.id;
    END LOOP;
END;
$$;
ROLLBACK;

BEGIN;
DELETE FROM t RETURNING *;
ROLLBACK;