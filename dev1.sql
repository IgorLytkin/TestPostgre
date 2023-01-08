CREATE SCHEMA bookstore;
ALTER DATABASE bookstore SET search_path = bookstore, public;
\c bookstore
SHOW search_path;
CREATE TABLE authors(
    author_id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    last_name text NOT NULL,
    first_name text NOT NULL,
    middle_name text
);
CREATE TABLE books(
    book_id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    title text NOT NULL
);
CREATE TABLE authorship(
    book_id integer REFERENCES books,
    author_id integer REFERENCES authors,
    seq_num integer NOT NULL,
    PRIMARY KEY (book_id,author_id)
);
CREATE TABLE operations(
    operation_id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    book_id integer NOT NULL REFERENCES books,
    qty_change integer NOT NULL,
    date_created date NOT NULL DEFAULT current_date
);
INSERT INTO authors(last_name, first_name, middle_name)
VALUES
    ('Пушкин', 'Александр', 'Сергеевич'),
    ('Тургенев', 'Иван', 'Сергеевич'),
    ('Стругацкий', 'Борис', 'Натанович'),
    ('Стругацкий', 'Аркадий', 'Натанович'),
    ('Толстой', 'Лев', 'Николаевич'),
    ('Свифт', 'Джонатан', NULL);
INSERT INTO books(title)
VALUES
    ('Сказка о царе Салтане'),
    ('Муму'),
    ('Трудно быть богом'),
    ('Война и мир'),
    ('Путешествия в некоторые удаленные страны мира в четырех частях: сочинение Лемюэля Гулливера, сначала хирурга, а затем капитана нескольких кораблей'),
    ('Хрестоматия');
INSERT INTO authorship(book_id, author_id, seq_num)
VALUES
    (1, 1, 1),
    (2, 2, 1),
    (3, 3, 2),
    (3, 4, 1),
    (4, 5, 1),
    (5, 6, 1),
    (6, 1, 1),
    (6, 5, 2),
    (6, 2, 3);
COPY operations (operation_id, book_id, qty_change) FROM stdin;

SELECT pg_catalog.setval('operations_operation_id_seq', 3, true);

CREATE VIEW authors_v AS
SELECT a.author_id,
       a.last_name || ' ' ||
       a.first_name ||
       coalesce(' ' || nullif(a.middle_name, ''), '') AS display_name
FROM   authors a;
CREATE VIEW catalog_v AS
SELECT b.book_id,
       b.title AS display_name
FROM   books b;
CREATE VIEW operations_v AS
SELECT book_id,
       CASE
           WHEN qty_change > 0 THEN 'Поступление'
           ELSE 'Покупка'
       END op_type,
       abs(qty_change) qty_change,
       to_char(date_created, 'DD.MM.YYYY') date_created
FROM   operations
ORDER BY operation_id;

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
$$ ;


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

CREATE OR REPLACE FUNCTION author_name(
    last_name text,
    first_name text,
    middle_name text
) RETURNS text
AS $$
SELECT last_name || ' ' ||
       left(first_name, 1) || '.' ||
       CASE WHEN middle_name != '' -- подразумевает NOT NULL
           THEN ' ' || left(middle_name, 1) || '.'
           ELSE ''
       END;
$$ IMMUTABLE LANGUAGE sql;
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

-- 10. Составные типы
-- Практика
CREATE OR REPLACE FUNCTION onhand_qty(book books) RETURNS integer
AS $$
    SELECT coalesce(sum(o.qty_change),0)::integer
    FROM operations o
    WHERE o.book_id = book.book_id;
$$ STABLE LANGUAGE sql;
DROP VIEW IF EXISTS catalog_v;
CREATE VIEW catalog_v AS
SELECT b.book_id,
       book_name(b.book_id, b.title) AS display_name,
       b.onhand_qty
FROM   books b
ORDER BY display_name;
CREATE OR REPLACE FUNCTION authors(book books) RETURNS text
AS $$
    SELECT string_agg(
               a.last_name ||
               ' ' ||
               a.first_name ||
               coalesce(' ' || nullif(a.middle_name,''), ''),
               ', '
               ORDER BY ash.seq_num
           )
    FROM   authors a
           JOIN authorship ash ON a.author_id = ash.author_id
    WHERE  ash.book_id = book.book_id;
$$ STABLE LANGUAGE sql;
DROP VIEW catalog_v;
CREATE VIEW catalog_v AS
SELECT b.book_id,
       b.title,
       b.onhand_qty,
       book_name(b.book_id, b.title) AS display_name,
       b.authors
FROM   books b
ORDER BY display_name;
CREATE OR REPLACE FUNCTION get_catalog(
    author_name text,
    book_title text,
    in_stock boolean
)
RETURNS TABLE(book_id integer, display_name text, onhand_qty integer)
AS $$
    SELECT cv.book_id,
           cv.display_name,
           cv.onhand_qty
    FROM   catalog_v cv
    WHERE  cv.title   ILIKE '%'||coalesce(book_title,'')||'%'
    AND    cv.authors ILIKE '%'||coalesce(author_name,'')||'%'
    AND    (in_stock AND cv.onhand_qty > 0 OR in_stock IS NOT TRUE)
    ORDER BY display_name;
$$ STABLE LANGUAGE sql;

CREATE FUNCTION digit(d text) RETURNS integer
AS $$
SELECT ascii(d) - CASE
        WHEN d BETWEEN '0' AND '9' THEN ascii('0')
        ELSE ascii('A') - 10
    END;
$$ IMMUTABLE LANGUAGE sql;
CREATE FUNCTION convert(hex text) RETURNS integer
AS $$
WITH s(d,ord) AS (
    SELECT *
    FROM regexp_split_to_table(reverse(upper(hex)),'') WITH ORDINALITY
)
SELECT sum(digit(d) * 16^(ord-1))::integer
FROM s;
$$ IMMUTABLE LANGUAGE sql;
SELECT convert('0FE'), convert('0FF'), convert('100');

DROP FUNCTION convert(text);
CREATE FUNCTION convert(num text, radix integer DEFAULT 16)
RETURNS integer
AS $$
WITH s(d,ord) AS (
    SELECT *
    FROM regexp_split_to_table(reverse(upper(num)),'') WITH ORDINALITY
)
SELECT sum(digit(d) * radix^(ord-1))::integer
FROM s;
$$ IMMUTABLE LANGUAGE sql;
SELECT convert('0110',2), convert('0FF'), convert('Z',36);

CREATE FUNCTION text2num(s text) RETURNS integer
AS $$
WITH s(d,ord) AS (
    SELECT *
    FROM regexp_split_to_table(reverse(s),'') WITH ORDINALITY
)
SELECT sum( (ascii(d)-ascii('A')) * 26^(ord-1))::integer
FROM s;
$$ IMMUTABLE LANGUAGE sql;
CREATE FUNCTION num2text(n integer, digits integer) RETURNS text
AS $$
WITH RECURSIVE r(num,txt, level) AS (
    SELECT n/26, chr( n%26 + ascii('A') )::text, 1
    UNION ALL
    SELECT r.num/26, chr( r.num%26 + ascii('A') ) || r.txt, r.level+1
    FROM r
    WHERE r.level < digits
)
SELECT r.txt FROM r WHERE r.level = digits;
$$ IMMUTABLE LANGUAGE sql;
SELECT num2text( text2num('ABC'), length('ABC') );

CREATE FUNCTION generate_series(start text, stop text)
RETURNS SETOF text
AS $$
    SELECT num2text( g.n, length(start) )
    FROM generate_series(text2num(start), text2num(stop)) g(n);
$$ IMMUTABLE LANGUAGE sql;
SELECT generate_series('AZ','BC');

-- 14. Динамический SQL
DO $$
DECLARE
    cmd CONSTANT text := 'CREATE TABLE city_msk(
        name text, architect text, founded integer
    )';
BEGIN
    EXECUTE cmd; -- таблица для исторических зданий Москвы
END;
$$;
DO $$
DECLARE
    rec record;
    cnt bigint;
BEGIN
    EXECUTE 'INSERT INTO city_msk (name, architect, founded) VALUES
                 (''Пашков дом'', ''Василий Баженов'', 1784),
                 (''Музей Пушкина'', ''Роман Клейн'', 1898),
                 (''ЦУМ'', ''Роман Клейн'', 1908)
             RETURNING name, architect, founded'
    INTO rec;
    RAISE NOTICE '%', rec;
    GET DIAGNOSTICS cnt = ROW_COUNT;
    RAISE NOTICE 'Добавлено строк: %', cnt;
END;
$$;
DO $$
DECLARE
    rec record;
BEGIN
    FOR rec IN EXECUTE 'SELECT * FROM city_msk ORDER BY founded'
    LOOP
        RAISE NOTICE '%', rec;
    END LOOP;
END;
$$;
DO $$
DECLARE
    cur refcursor;
    rec record;
BEGIN
    OPEN cur FOR EXECUTE 'SELECT * FROM city_msk ORDER BY founded';
    LOOP
        FETCH cur INTO rec;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE '%', rec;
    END LOOP;
END;
$$;
CREATE FUNCTION sel_msk(architect text, founded integer DEFAULT NULL)
RETURNS SETOF text
AS $$
DECLARE
    -- параметры пронумерованы: $1, $2...
    cmd text := '
        SELECT name FROM city_msk
        WHERE architect = $1 AND ($2 IS NULL OR founded = $2)';
BEGIN
    RETURN QUERY
        EXECUTE cmd
        USING architect, founded; -- указываем значения по порядку
END;
$$ LANGUAGE plpgsql;
SELECT * FROM sel_msk('Роман Клейн');
SELECT * FROM sel_msk('Роман Клейн', 1908);

CREATE FUNCTION sel_city(
    city_code text,
    architect text,
    founded integer DEFAULT NULL
)
RETURNS SETOF text AS $$
DECLARE
    cmd text := '
        SELECT name FROM city_' || city_code || '
        WHERE architect = $1 AND ($2 IS NULL OR founded = $2)';
BEGIN
    RAISE NOTICE '%', cmd;
    RETURN QUERY
        EXECUTE cmd
        USING architect, founded;
END;
$$ LANGUAGE plpgsql;
SELECT * FROM sel_city('msk', 'Василий Баженов');
SELECT * FROM sel_city('msk WHERE false
        UNION ALL
        SELECT usename FROM pg_user
        UNION ALL
        SELECT name FROM city_msk', '');

SELECT format('%I', 'foo'),
          format('%I', 'foo bar'),
          format('%I', 'foo"bar');
SELECT quote_ident('foo'),
          quote_ident('foo bar'),
          quote_ident('foo"bar');
DO $$
DECLARE
    cmd CONSTANT text := 'CREATE TABLE %I(
        name text, architect text, founded integer
    )';
BEGIN
    EXECUTE format(cmd, 'city_spb'); -- таблица для Санкт-Петербурга
    EXECUTE format(cmd, 'city_nov'); -- таблица для Новгорода
END;
$$;
SELECT format('%L', 'foo bar'),
          format('%L', 'foo''bar'),
          format('%L', NULL);
SELECT quote_nullable('foo bar'),
          quote_nullable('foo''bar'),
          quote_nullable(NULL);
SELECT quote_literal(NULL);
CREATE OR REPLACE FUNCTION sel_city(
    city_code text,
    architect text,
    founded integer DEFAULT NULL
)
RETURNS SETOF text
AS $$
DECLARE
    cmd text := '
        SELECT name FROM %I
        WHERE architect = %L AND (%L IS NULL OR founded = %L::integer)';
BEGIN
    RETURN QUERY EXECUTE format(
        cmd, 'city_'||city_code, architect, founded, founded
    );
END;
$$ LANGUAGE plpgsql;
SELECT * FROM sel_city('msk', 'Василий Баженов', 1784);
SELECT * FROM sel_city('msk WHERE false
        UNION ALL
        SELECT usename FROM pg_user
        UNION ALL
        SELECT name FROM city_msk', '');

CREATE OR REPLACE FUNCTION get_catalog(
    author_name text,
    book_title text,
    in_stock boolean
)
RETURNS TABLE(book_id integer, display_name text, onhand_qty integer)
AS $$
DECLARE
    title_cond text := '';
    author_cond text := '';
    qty_cond text := '';
BEGIN
    IF book_title != '' THEN
        title_cond := format(
            ' AND cv.title ILIKE %L', '%'||book_title||'%'
        );
    END IF;
    IF author_name != '' THEN
        author_cond := format(
            ' AND cv.authors ILIKE %L', '%'||author_name||'%'
        );
    END IF;
    IF in_stock THEN
        qty_cond := ' AND cv.onhand_qty > 0';
    END IF;
    RETURN QUERY EXECUTE '
        SELECT cv.book_id,
               cv.display_name,
               cv.onhand_qty
        FROM   catalog_v cv
        WHERE  true'
        || title_cond || author_cond || qty_cond || '
        ORDER BY display_name';
END;
$$ STABLE LANGUAGE plpgsql;

CREATE DATABASE plpgsql_dynamic;
\c plpgsql_dynamic

CREATE FUNCTION form_query() RETURNS text
AS $$
DECLARE
    query_text text;
    columns text := '';
    r record;
BEGIN
    -- Статическая часть запроса
    -- Первые два столбца: имя схемы и общее количество функций в ней
    query_text :=
$query$
SELECT pronamespace::regnamespace::text AS schema
     , count(*) AS total{{columns}}
FROM pg_proc
GROUP BY pronamespace::regnamespace
ORDER BY schema
$query$;

    -- Динамическая часть запроса
    -- Получаем список владельцев функций, для каждого - отдельный столбец
    FOR r IN SELECT DISTINCT proowner AS owner FROM pg_proc ORDER BY 1
    LOOP
        columns := columns || format(
            E'\n     , sum(CASE WHEN proowner = %s THEN 1 ELSE 0 END) AS %I',
            r.owner,
            r.owner::regrole
        );
    END LOOP;

    RETURN replace(query_text, '{{columns}}', columns);
END;
$$ STABLE LANGUAGE plpgsql;
SELECT form_query();
CREATE FUNCTION matrix() RETURNS SETOF record
AS $$
BEGIN
    RETURN QUERY EXECUTE form_query();
END;
$$ STABLE LANGUAGE plpgsql;
SELECT * FROM matrix();

CREATE FUNCTION matrix_call() RETURNS text
AS $$
DECLARE
    cmd text;
    r record;
BEGIN
    cmd := 'SELECT * FROM matrix() AS m(
        schema text, total bigint';

    FOR r IN SELECT DISTINCT proowner AS owner FROM pg_proc ORDER BY 1
    LOOP
        cmd := cmd || format(', %I bigint', r.owner::regrole::text);
    END LOOP;
    cmd := cmd || E'\n)';

    RAISE NOTICE '%', cmd;
    RETURN cmd;
END;
$$ STABLE LANGUAGE plpgsql;
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT matrix_call() \gexec

-- Массивы
DO $$
DECLARE
    a integer[2]; -- размер игнорируется
BEGIN
    a := ARRAY[10,20,30];
    RAISE NOTICE '%', a;
    -- по умолчанию элементы нумеруются с единицы
    RAISE NOTICE 'a[1] = %, a[2] = %, a[3] = %', a[1], a[2], a[3];
    -- срез массива
    RAISE NOTICE 'Срез [2:3] = %', a[2:3];
END;
$$ LANGUAGE plpgsql;
DO $$
DECLARE
    a integer[];
BEGIN
    a[2] := 10;
    a[3] := 20;
    a[6] := 30;
    RAISE NOTICE '%', a;
END;
$$ LANGUAGE plpgsql;
DO $$
DECLARE
    a integer[];
BEGIN
    a := ARRAY( SELECT n FROM generate_series(1,3) n );
    RAISE NOTICE '%', a;
END;
$$ LANGUAGE plpgsql;
SELECT unnest( ARRAY[1,2,3] );

EXPLAIN (costs off)
SELECT * FROM generate_series(1,10) g(id) WHERE id IN (1,2,3);

DO $$
DECLARE
    a integer[][] := '{
        { 10, 20, 30},
        {100,200,300}
    }';
BEGIN
    RAISE NOTICE '%', a;
    RAISE NOTICE 'Срез [1:2][2:3] = %', a[1:2][2:3];
    -- расширять нельзя
    a[4][4] := 1;
END;
$$ LANGUAGE plpgsql;

rollback;

DO $$
DECLARE
    a integer[] := ARRAY[10,20,30];
BEGIN
    FOR i IN array_lower(a,1)..array_upper(a,1) LOOP
        RAISE NOTICE 'a[%] = %', i, a[i];
    END LOOP;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    a integer[] := ARRAY[10,20,30];
    x integer;
BEGIN
    FOREACH x IN ARRAY a LOOP
        RAISE NOTICE '%', x;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
DO $$
DECLARE
    -- можно и без двойных квадратных скобок
    a integer[] := ARRAY[
        ARRAY[ 10, 20, 30],
        ARRAY[100,200,300]
    ];
BEGIN
    FOR i IN array_lower(a,1)..array_upper(a,1) LOOP -- по строкам
        FOR j IN array_lower(a,2)..array_upper(a,2) LOOP -- по столбцам
            RAISE NOTICE 'a[%][%] = %', i, j, a[i][j];
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
DO $$
DECLARE
    a integer[] := ARRAY[
        ARRAY[ 10, 20, 30],
        ARRAY[100,200,300]
    ];
    x integer;
BEGIN
    FOREACH x IN ARRAY a LOOP
        RAISE NOTICE '%', x;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
CREATE FUNCTION maximum(VARIADIC a integer[]) RETURNS integer
AS $$
DECLARE
    x integer;
    maxsofar integer;
BEGIN
    FOREACH x IN ARRAY a LOOP
        IF x IS NOT NULL AND (maxsofar IS NULL OR x > maxsofar) THEN
            maxsofar := x;
        END IF;
    END LOOP;
    RETURN maxsofar;
END;
$$ IMMUTABLE LANGUAGE plpgsql;
SELECT maximum(12, 65, 47);
SELECT maximum(12, 65, 47, null, 87, 24);
SELECT maximum(null, null);

DROP FUNCTION maximum(integer[]);
CREATE FUNCTION maximum(VARIADIC a anyarray, maxsofar OUT anyelement)
AS $$
DECLARE
    x maxsofar%TYPE;
BEGIN
    FOREACH x IN ARRAY a LOOP
        IF x IS NOT NULL AND (maxsofar IS NULL OR x > maxsofar) THEN
            maxsofar := x;
        END IF;
    END LOOP;
END;
$$ IMMUTABLE LANGUAGE plpgsql;
SELECT maximum(12, 65, 47);
SELECT maximum(12.1, 65.3, 47.6);

CREATE TABLE posts(
    post_id integer PRIMARY KEY,
    message text
);
CREATE TABLE tags(
    tag_id integer PRIMARY KEY,
    name text
);

-- Практика
CREATE OR REPLACE FUNCTION add_book(title text, authors integer[])
RETURNS integer
AS $$
DECLARE
    book_id integer;
    id integer;
    seq_num integer := 1;
BEGIN
    INSERT INTO books(title)
        VALUES(title)
        RETURNING books.book_id INTO book_id;
    FOREACH id IN ARRAY authors LOOP
        INSERT INTO authorship(book_id, author_id, seq_num)
            VALUES (book_id, id, seq_num);
        seq_num := seq_num + 1;
    END LOOP;
    RETURN book_id;
END;
$$ VOLATILE LANGUAGE plpgsql;

CREATE TABLE posts_tags(
    post_id integer REFERENCES posts(post_id),
    tag_id integer REFERENCES tags(tag_id)
);
INSERT INTO posts(post_id,message) VALUES
    (1, 'Перечитывал пейджер, много думал.'),
    (2, 'Это было уже весной, и я отнес елку обратно.');
INSERT INTO tags(tag_id,name) VALUES
    (1, 'былое и думы'), (2, 'технологии'), (3, 'семья');
INSERT INTO posts_tags(post_id,tag_id) VALUES
    (1,1), (1,2), (2,1), (2,3);
SELECT p.message, t.name
FROM posts p
     JOIN posts_tags pt ON pt.post_id = p.post_id
     JOIN tags t ON t.tag_id = pt.tag_id
ORDER BY p.post_id, t.name;
SELECT p.message, array_agg(t.name ORDER BY t.name) tags
FROM posts p
     JOIN posts_tags pt ON pt.post_id = p.post_id
     JOIN tags t ON t.tag_id = pt.tag_id
GROUP BY p.post_id
ORDER BY p.post_id;
SELECT p.message
FROM posts p
     JOIN posts_tags pt ON pt.post_id = p.post_id
     JOIN tags t ON t.tag_id = pt.tag_id
WHERE t.name = 'былое и думы'
ORDER BY p.post_id;
SELECT t.name
FROM tags t
ORDER BY t.name;

DROP TABLE posts_tags;
DROP TABLE tags;
ALTER TABLE posts ADD COLUMN tags text[];
UPDATE posts SET tags = '{"былое и думы","технологии"}'
WHERE post_id = 1;
UPDATE posts SET tags = '{"былое и думы","семья"}'
WHERE post_id = 2;
SELECT p.message, p.tags
FROM posts p
ORDER BY p.post_id;
SELECT p.message
FROM posts p
WHERE p.tags && '{"былое и думы"}'
ORDER BY p.post_id;
SELECT DISTINCT unnest(p.tags) AS name
FROM posts p;

-- Практика
CREATE OR REPLACE FUNCTION add_book(title text, authors integer[])
RETURNS integer
AS $$
DECLARE
    book_id integer;
    id integer;
    seq_num integer := 1;
BEGIN
    INSERT INTO books(title)
        VALUES(title)
        RETURNING books.book_id INTO book_id;
    FOREACH id IN ARRAY authors LOOP
        INSERT INTO authorship(book_id, author_id, seq_num)
            VALUES (book_id, id, seq_num);
        seq_num := seq_num + 1;
    END LOOP;
    RETURN book_id;
END;
$$ VOLATILE LANGUAGE plpgsql;

CREATE DATABASE plpgsql_arrays;
\c plpgsql_arrays
CREATE FUNCTION map(a INOUT float[], func text)
AS $$
DECLARE
    i integer;
    x float;
BEGIN
    IF cardinality(a) > 0 THEN
        FOR i IN array_lower(a,1)..array_upper(a,1) LOOP
            EXECUTE format('SELECT %I($1)',func) USING a[i] INTO x;
            a[i] := x;
        END LOOP;
    END IF;
END;
$$ IMMUTABLE LANGUAGE plpgsql;
SELECT map(ARRAY[4.0,9.0,16.0],'sqrt');
SELECT map(ARRAY[]::float[],'sqrt');

CREATE OR REPLACE FUNCTION map(a float[], func text) RETURNS float[]
AS $$
DECLARE
    x float;
    b float[]; -- пустой массив
BEGIN
    FOREACH x IN ARRAY a LOOP
        EXECUTE format('SELECT %I($1)',func) USING x INTO x;
        b := b || x;
    END LOOP;
    RETURN b;
END;
$$ IMMUTABLE LANGUAGE plpgsql;
SELECT map(ARRAY[4.0,9.0,16.0],'sqrt');
SELECT map(ARRAY[]::float[],'sqrt');

CREATE FUNCTION reduce(a float[], func text) RETURNS float
AS $$
DECLARE
    i integer;
    r float := NULL;
BEGIN
    IF cardinality(a) > 0 THEN
        r := a[array_lower(a,1)];
        FOR i IN array_lower(a,1)+1 .. array_upper(a,1) LOOP
            EXECUTE format('SELECT %I($1,$2)',func) USING r, a[i]
                INTO r;
        END LOOP;
    END IF;
    RETURN r;
END;
$$ IMMUTABLE LANGUAGE plpgsql;
SELECT reduce( ARRAY[1.0,3.0,2.0], 'greatest');

CREATE FUNCTION maximum(VARIADIC a anyarray, maxsofar OUT anyelement)
AS $$
DECLARE
    x maxsofar%TYPE;
BEGIN
    FOREACH x IN ARRAY a LOOP
        IF x IS NOT NULL AND (maxsofar IS NULL OR x > maxsofar) THEN
            maxsofar := x;
        END IF;
    END LOOP;
END;
$$ IMMUTABLE LANGUAGE plpgsql;
SELECT reduce(ARRAY[1.0,3.0,2.0], 'maximum');
SELECT reduce(ARRAY[1.0], 'maximum');
SELECT reduce(ARRAY[]::float[], 'maximum');

CREATE OR REPLACE FUNCTION reduce(a float[], func text) RETURNS float
AS $$
DECLARE
    x float;
    r float;
    first boolean := true;
BEGIN
    FOREACH x IN ARRAY a LOOP
        IF first THEN
            r := x;
            first := false;
        ELSE
            EXECUTE format('SELECT %I($1,$2)',func) USING r, x INTO r;
        END IF;
    END LOOP;
    RETURN r;
END;
$$ IMMUTABLE LANGUAGE plpgsql;
SELECT reduce(ARRAY[1.0,3.0,2.0], 'maximum');
SELECT reduce(ARRAY[1.0], 'maximum');
SELECT reduce(ARRAY[]::float[], 'maximum');

DROP FUNCTION map(float[],text);
CREATE FUNCTION map(
    a anyarray,
    func text,
    elem anyelement DEFAULT NULL
)
RETURNS anyarray
AS $$
DECLARE
    x elem%TYPE;
    b a%TYPE;
BEGIN
    FOREACH x IN ARRAY a LOOP
        EXECUTE format('SELECT %I($1)',func) USING x INTO x;
        b := b || x;
    END LOOP;
    RETURN b;
END;
$$ IMMUTABLE LANGUAGE plpgsql;
SELECT map(ARRAY[4.0,9.0,16.0],'sqrt');
SELECT map(ARRAY[]::float[],'sqrt');
SELECT map(ARRAY[' a ','  b','c  '],'btrim');

DROP FUNCTION reduce(float[],text);
CREATE FUNCTION reduce(
    a anyarray,
    func text,
    elem anyelement DEFAULT NULL
)
RETURNS anyelement
AS $$
DECLARE
    x elem%TYPE;
    r elem%TYPE;
    first boolean := true;
BEGIN
    FOREACH x IN ARRAY a LOOP
        IF first THEN
            r := x;
            first := false;
        ELSE
            EXECUTE format('SELECT %I($1,$2)',func) USING r, x INTO r;
        END IF;
    END LOOP;
    RETURN r;
END;
$$ IMMUTABLE LANGUAGE plpgsql;
CREATE FUNCTION add(x anyelement, y anyelement) RETURNS anyelement
AS $$
BEGIN
    RETURN x + y;
END;
$$ IMMUTABLE LANGUAGE plpgsql;
SELECT reduce(ARRAY[1,-2,4], 'add');
SELECT reduce(ARRAY['a','b','c'], 'concat');

-- Обработка ошибок
drop table t;
CREATE TABLE t(id integer);
INSERT INTO t(id) VALUES (1);

DO $$
DECLARE
    n integer;
BEGIN
    SELECT id INTO STRICT n FROM t;
    RAISE NOTICE 'Оператор SELECT INTO выполнился';
END;
$$;
INSERT INTO t(id) VALUES (2);
DO $$
DECLARE
    n integer;
BEGIN
    SELECT id INTO STRICT n FROM t;
    RAISE NOTICE 'Оператор SELECT INTO выполнился';
END;
$$;

DO $$
DECLARE
    n integer;
BEGIN
    INSERT INTO t(id) VALUES (3);
    SELECT id INTO STRICT n FROM t;
    RAISE NOTICE 'Оператор SELECT INTO выполнился';
EXCEPTION
    WHEN no_data_found THEN
        RAISE NOTICE 'Нет данных';
    WHEN too_many_rows THEN
        RAISE NOTICE 'Слишком много данных';
        RAISE NOTICE 'Строк в таблице: %', (SELECT count(*) FROM t);
END;
$$;

DO $$
DECLARE
    n integer := 1 / 0; -- ошибка в этом месте не перехватывается
BEGIN
    RAISE NOTICE 'Все успешно';
EXCEPTION
    WHEN division_by_zero THEN
        RAISE NOTICE 'Деление на ноль';
END;
$$;
DO $$
DECLARE
    n integer;
BEGIN
    SELECT id INTO STRICT n FROM t;
EXCEPTION
    WHEN SQLSTATE 'P0003' OR no_data_found THEN -- можно несколько
        RAISE NOTICE '%: %', SQLSTATE, SQLERRM;
END;
$$;
DO $$
DECLARE
    n integer;
BEGIN
    SELECT id INTO STRICT n FROM t;
EXCEPTION
    WHEN no_data_found THEN
        RAISE NOTICE 'Нет данных. %: %', SQLSTATE, SQLERRM;
    WHEN plpgsql_error THEN
        RAISE NOTICE 'Другая ошибка. %: %', SQLSTATE, SQLERRM;
    WHEN too_many_rows THEN
        RAISE NOTICE 'Слишком много данных. %: %', SQLSTATE, SQLERRM;
END;
$$;
DO $$
BEGIN
    RAISE no_data_found;
EXCEPTION
    WHEN others THEN
        RAISE NOTICE '%: %', SQLSTATE, SQLERRM;
END;
$$;
DO $$
BEGIN
    RAISE SQLSTATE 'ERR01' USING
        message = 'Сбой матрицы',
        detail  = 'При выполнении произошел непоправимый сбой матрицы',
        hint = 'Обратитесь к системному администратору';
END;
$$;
DO $$
DECLARE
    message text;
    detail text;
    hint text;
BEGIN
    RAISE SQLSTATE 'ERR01' USING
        message = 'Сбой матрицы',
        detail  = 'При выполнении произошел непоправимый сбой матрицы',
        hint = 'Обратитесь к системному администратору';
EXCEPTION
    WHEN others THEN
        GET STACKED DIAGNOSTICS
            message = message_text,
            detail = pg_exception_detail,
            hint = pg_exception_hint;
        RAISE NOTICE E'\nmessage = %\ndetail = %\nhint = %',
            message, detail, hint;
END;
$$;
DO $$
BEGIN
    BEGIN
        SELECT 1/0;
        RAISE NOTICE 'Вложенный блок выполнен';
    EXCEPTION
        WHEN division_by_zero THEN
            RAISE NOTICE 'Ошибка во вложенном блоке';
    END;
    RAISE NOTICE 'Внешний блок выполнен';
EXCEPTION
    WHEN division_by_zero THEN
        RAISE NOTICE 'Ошибка во внешнем блоке';
END;
$$;
DO $$
BEGIN
    BEGIN
        SELECT 1/0;
        RAISE NOTICE 'Вложенный блок выполнен';
    EXCEPTION
        WHEN no_data_found THEN
            RAISE NOTICE 'Ошибка во вложенном блоке';
    END;
    RAISE NOTICE 'Внешний блок выполнен';
EXCEPTION
    WHEN division_by_zero THEN
        RAISE NOTICE 'Ошибка во внешнем блоке';
END;
$$;
DO $$
BEGIN
    BEGIN
        SELECT 1/0;
        RAISE NOTICE 'Вложенный блок выполнен';
    EXCEPTION
        WHEN no_data_found THEN
            RAISE NOTICE 'Ошибка во вложенном блоке';
    END;
    RAISE NOTICE 'Внешний блок выполнен';
EXCEPTION
    WHEN no_data_found THEN
        RAISE NOTICE 'Ошибка во внешнем блоке';
END;
$$;
CREATE PROCEDURE foo()
AS $$
BEGIN
    CALL bar();
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
    PERFORM 1 / 0;
END;
$$ LANGUAGE plpgsql;
CALL foo();
CREATE OR REPLACE PROCEDURE bar()
AS $$
DECLARE
    msg text;
    ctx text;
BEGIN
    CALL baz();
EXCEPTION
    WHEN others THEN
        GET STACKED DIAGNOSTICS
             msg = message_text,
             ctx = pg_exception_context;
        RAISE NOTICE E'\nОшибка: %\nСтек ошибки:\n%\n', msg, ctx;
END;
$$ LANGUAGE plpgsql;
CALL foo();
CREATE OR REPLACE PROCEDURE baz()
AS $$
BEGIN
    COMMIT;
END;
$$ LANGUAGE plpgsql;
CALL foo();
CREATE TABLE data(comment text, n integer);
INSERT INTO data(comment)
SELECT CASE
        WHEN random() < 0.01 THEN 'не число' --  1%
        ELSE (random()*1000)::integer::text  -- 99%
    END
FROM generate_series(1,1000000);
CREATE FUNCTION safe_to_integer_ex(s text) RETURNS integer
AS $$
BEGIN
    RETURN s::integer;
EXCEPTION
    WHEN invalid_text_representation THEN
        RETURN NULL;
END
$$ IMMUTABLE LANGUAGE plpgsql;

\timing on
UPDATE data SET n = safe_to_integer_ex(comment);
\timing off
SELECT count(*) FROM data WHERE n IS NOT NULL;

CREATE FUNCTION safe_to_integer_re(s text) RETURNS integer
AS $$
BEGIN
    RETURN CASE
        WHEN s ~ '^\d+$' THEN s::integer
        ELSE NULL
    END;
END
$$ IMMUTABLE LANGUAGE plpgsql;

\timing on
UPDATE data SET n = safe_to_integer_re(comment);
\timing off
SELECT count(*) FROM data WHERE n IS NOT NULL;
UPDATE data SET comment = 'не число';
\timing on
UPDATE data SET n = safe_to_integer_ex(comment);
\timing off

 CREATE TABLE categories(code text UNIQUE, description text);
INSERT INTO categories VALUES ('books','Книги'), ('discs','Диски');
CREATE FUNCTION get_cat_desc(code text) RETURNS text
AS $$
DECLARE
    desc text;
BEGIN
    SELECT c.description INTO STRICT desc
    FROM categories c
    WHERE c.code = get_cat_desc.code;

    RETURN desc;
EXCEPTION
    WHEN no_data_found THEN
        RETURN NULL;
END;
$$ STABLE LANGUAGE plpgsql;
SELECT get_cat_desc('books');
SELECT get_cat_desc('movies');
CREATE OR REPLACE FUNCTION get_cat_desc(code text) RETURNS text
AS $$
BEGIN
    RETURN (SELECT c.description
            FROM categories c
            WHERE c.code = get_cat_desc.code);
END;
$$ STABLE LANGUAGE plpgsql;
SELECT get_cat_desc('books');
SELECT get_cat_desc('movies');

CREATE OR REPLACE FUNCTION change(code text, description text)
RETURNS void
AS $$
DECLARE
    cnt integer;
BEGIN
    SELECT count(*) INTO cnt
    FROM categories c WHERE c.code = change.code;

    IF cnt = 0 THEN
        INSERT INTO categories VALUES (code, description);
    ELSE
        UPDATE categories c
        SET description = change.description
        WHERE c.code = change.code;
    END IF;
END;
$$ VOLATILE LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION change(code text, description text)
RETURNS void
AS $$
BEGIN
    UPDATE categories c
    SET description = change.description
    WHERE c.code = change.code;

    IF NOT FOUND THEN
        PERFORM pg_sleep(1); -- тут может произойти все, что угодно
        INSERT INTO categories VALUES (code, description);
    END IF;
END;
$$ VOLATILE LANGUAGE plpgsql;
 SELECT change('games', 'Игры');

CREATE OR REPLACE FUNCTION change(code text, description text)
RETURNS void
AS $$
BEGIN
    LOOP
        UPDATE categories c
        SET description = change.description
        WHERE c.code = change.code;

        EXIT WHEN FOUND;
        PERFORM pg_sleep(1); -- для демонстрации

        BEGIN
            INSERT INTO categories VALUES (code, description);
            EXIT;
        EXCEPTION
            WHEN unique_violation THEN NULL;
        END;
    END LOOP;
END;
$$ VOLATILE LANGUAGE plpgsql;
 SELECT change('vynil', 'Грампластинки');
CREATE OR REPLACE FUNCTION change(code text, description text)
RETURNS void
AS $$
    INSERT INTO categories VALUES (code, description)
    ON CONFLICT(code)
        DO UPDATE SET description = change.description;
$$ VOLATILE LANGUAGE sql;
CREATE OR REPLACE FUNCTION process_cat(code text) RETURNS text
AS $$
BEGIN
    PERFORM c.code FROM categories c WHERE c.code = process_cat.code
        FOR UPDATE NOWAIT;
    PERFORM pg_sleep(1); -- собственно обработка
    RETURN 'Категория обработана';
EXCEPTION
    WHEN lock_not_available THEN
        RETURN 'Другой процесс уже обрабатывает эту категорию';
END;
$$ VOLATILE LANGUAGE plpgsql;
SELECT process_cat('books');
CREATE OR REPLACE FUNCTION process_cat(code text) RETURNS text
AS $$
BEGIN
    IF pg_try_advisory_lock(hashtext(code)) THEN
        PERFORM pg_sleep(1); -- собственно обработка
        RETURN 'Категория обработана';
    ELSE
        RETURN 'Другой процесс уже обрабатывает эту категорию';
    END IF;
END;
$$ VOLATILE LANGUAGE plpgsql;
SELECT process_cat('books');

CREATE TYPE doc_status AS ENUM -- тип перечисления
    ('READY', 'ERROR', 'PROCESSED');
CREATE TABLE documents(
    id integer,
    version integer,
    status doc_status,
    message text
);
INSERT INTO documents(id, version, status)
    SELECT id, 1, 'READY' FROM generate_series(1,100) id;
CREATE PROCEDURE process_one_doc(id integer)
AS $$
BEGIN
    UPDATE documents d
    SET version = version + 1
    WHERE d.id = process_one_doc.id;
    -- обработка может длиться долго
    IF random() < 0.05 THEN
        RAISE EXCEPTION 'Случилось страшное';
    END IF;
END;
$$ LANGUAGE plpgsql;
CREATE PROCEDURE process_docs()
AS $$
DECLARE
    doc record;
BEGIN
    FOR doc IN (SELECT id FROM documents WHERE status = 'READY')
    LOOP
        BEGIN
            CALL process_one_doc(doc.id);

            UPDATE documents d
            SET status = 'PROCESSED'
            WHERE d.id = doc.id;
        EXCEPTION
            WHEN others THEN
                UPDATE documents d
                SET status = 'ERROR', message = sqlerrm
                WHERE d.id = doc.id;
        END;
        COMMIT; -- каждый документ в своей транзакции
    END LOOP;
END;
$$ LANGUAGE plpgsql;
CALL process_docs();
SELECT d.status, d.version, count(*)::integer
FROM documents d
GROUP BY d.status, d.version;
SELECT * FROM documents d WHERE d.status = 'ERROR';

CREATE OR REPLACE FUNCTION add_book(title text, authors integer[])
RETURNS integer
AS $$
DECLARE
    book_id integer;
    id integer;
    seq_num integer := 1;
BEGIN
    INSERT INTO books(title)
        VALUES(title)
        RETURNING books.book_id INTO book_id;
    FOREACH id IN ARRAY authors LOOP
        INSERT INTO authorship(book_id, author_id, seq_num)
            VALUES (book_id, id, seq_num);
        seq_num := seq_num + 1;
    END LOOP;
    RETURN book_id;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Один и тот же автор не может быть указан дважды';
END;
$$ VOLATILE LANGUAGE plpgsql;

CREATE DATABASE plpgsql_exceptions;
\c plpgsql_exceptions
DO $$
BEGIN
    BEGIN
        RAISE NOTICE 'Операторы try';
        --
        RAISE NOTICE '...нет исключения';
    EXCEPTION
        WHEN no_data_found THEN
            RAISE NOTICE 'Операторы catch';
    END;
    RAISE SQLSTATE 'ALLOK';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Операторы finally';
        IF SQLSTATE != 'ALLOK' THEN
            RAISE;
        END IF;
END;
$$;
DO $$
BEGIN
    BEGIN
        RAISE NOTICE 'Операторы try';
        --
        RAISE NOTICE '...исключение, которое обрабатывается';
        RAISE no_data_found;
    EXCEPTION
        WHEN no_data_found THEN
            RAISE NOTICE 'Операторы catch';
    END;
    RAISE SQLSTATE 'ALLOK';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Операторы finally';
        IF SQLSTATE != 'ALLOK' THEN
            RAISE;
        END IF;
END;
$$;
DO $$
BEGIN
    BEGIN
        RAISE NOTICE 'Операторы try';
        --
        RAISE NOTICE '...исключение, которое не обрабатывается';
        RAISE division_by_zero;
    EXCEPTION
        WHEN no_data_found THEN
            RAISE NOTICE 'Операторы catch';
    END;
    RAISE SQLSTATE 'ALLOK';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Операторы finally';
        IF SQLSTATE != 'ALLOK' THEN
            RAISE;
        END IF;
END;
$$;
DO $$
DECLARE
    ctx text;
BEGIN
    RAISE division_by_zero;                       -- line 5
EXCEPTION
    WHEN others THEN
        GET STACKED DIAGNOSTICS ctx = pg_exception_context;
        RAISE NOTICE E'stacked =\n%', ctx;
        GET CURRENT DIAGNOSTICS ctx = pg_context; -- line 10
        RAISE NOTICE E'current =\n%', ctx;
END;
$$;
CREATE FUNCTION getstack() RETURNS text[]
AS $$
DECLARE
    ctx text;
BEGIN
    GET DIAGNOSTICS ctx = pg_context;
    RETURN (regexp_split_to_array(ctx, E'\n'))[2:];
END;
$$ VOLATILE LANGUAGE plpgsql;
CREATE FUNCTION foo() RETURNS integer
AS $$
BEGIN
    RETURN bar();
END;
$$ VOLATILE LANGUAGE plpgsql;
CREATE FUNCTION bar() RETURNS integer
AS $$
BEGIN
    RETURN baz();
END;
$$ VOLATILE LANGUAGE plpgsql;
CREATE FUNCTION baz() RETURNS integer
AS $$
BEGIN
    RAISE NOTICE '%', getstack();
    RETURN 0;
END;
$$ VOLATILE LANGUAGE plpgsql;
SELECT foo();

-- Триггеры
CREATE OR REPLACE FUNCTION describe() RETURNS trigger
AS $$
DECLARE
    rec record;
    str text := '';
BEGIN
    IF TG_LEVEL = 'ROW' THEN
        CASE TG_OP
            WHEN 'DELETE' THEN rec := OLD; str := OLD::text;
            WHEN 'UPDATE' THEN rec := NEW; str := OLD || ' -> ' || NEW;
            WHEN 'INSERT' THEN rec := NEW; str := NEW::text;
        END CASE;
    END IF;
    RAISE NOTICE '% % % %: %',
        TG_TABLE_NAME, TG_WHEN, TG_OP, TG_LEVEL, str;
    RETURN rec;
END;
$$ LANGUAGE plpgsql;
DROP TABLE t;
CREATE TABLE t(
    id integer PRIMARY KEY,
    s text
);
CREATE TRIGGER t_before_stmt
BEFORE INSERT OR UPDATE OR DELETE -- события
ON t                              -- таблица
FOR EACH STATEMENT                -- уровень
EXECUTE FUNCTION describe();      -- триггерная функция

CREATE TRIGGER t_after_stmt
AFTER INSERT OR UPDATE OR DELETE ON t
FOR EACH STATEMENT EXECUTE FUNCTION describe();
CREATE TRIGGER t_before_row
BEFORE INSERT OR UPDATE OR DELETE ON t
FOR EACH ROW EXECUTE FUNCTION describe();
CREATE TRIGGER t_after_row
AFTER INSERT OR UPDATE OR DELETE ON t
FOR EACH ROW EXECUTE FUNCTION describe();
INSERT INTO t VALUES (1,'aaa');
UPDATE t SET s = 'bbb';
UPDATE t SET s = 'ccc' where id = 0;

INSERT INTO t VALUES (1,'ccc'), (3,'ddd')
ON CONFLICT(id) DO UPDATE SET s = EXCLUDED.s;
DELETE FROM t;

CREATE OR REPLACE FUNCTION transition() RETURNS trigger
AS $$
DECLARE
    rec record;
BEGIN
    IF TG_OP = 'DELETE' OR TG_OP = 'UPDATE' THEN
        RAISE NOTICE 'Старое состояние:';
        FOR rec IN SELECT * FROM old_table LOOP
            RAISE NOTICE '%', rec;
        END LOOP;
    END IF;
    IF TG_OP = 'UPDATE' OR TG_OP = 'INSERT' THEN
        RAISE NOTICE 'Новое состояние:';
        FOR rec IN SELECT * FROM new_table LOOP
            RAISE NOTICE '%', rec;
        END LOOP;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
CREATE TABLE trans(
    id integer PRIMARY KEY,
    n integer
);
INSERT INTO trans VALUES (1,10), (2,20), (3,30);
CREATE TRIGGER t_after_upd_trans
AFTER UPDATE ON trans -- только одно событие на один триггер
REFERENCING
    OLD TABLE AS old_table
    NEW TABLE AS new_table -- можно и одну, не обязательно обе
FOR EACH STATEMENT
EXECUTE FUNCTION transition();
UPDATE trans SET n = n + 1 WHERE n <= 20;

CREATE TABLE coins(
    face_value numeric,
    name text
);
CREATE TABLE coins_history(LIKE coins);
ALTER TABLE coins_history
    ADD start_date timestamp,
    ADD end_date timestamp;
CREATE OR REPLACE FUNCTION history_insert() RETURNS trigger
AS $$
BEGIN
    EXECUTE format(
        'INSERT INTO %I SELECT ($1).*, current_timestamp, NULL',
        TG_TABLE_NAME||'_history'
    ) USING NEW;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION history_delete() RETURNS trigger
AS $$
BEGIN
    EXECUTE format(
        'UPDATE %I SET end_date = current_timestamp WHERE face_value = $1 AND end_date IS NULL',
        TG_TABLE_NAME||'_history'
    ) USING OLD.face_value;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
 CREATE TRIGGER coins_history_insert
AFTER INSERT OR UPDATE ON coins
FOR EACH ROW EXECUTE FUNCTION history_insert();
CREATE TRIGGER coins_history_delete
AFTER UPDATE OR DELETE ON coins
FOR EACH ROW EXECUTE FUNCTION history_delete();
INSERT INTO coins VALUES (0.25, 'Полушка'), (3, 'Алтын');
UPDATE coins SET name = '3 копейки' WHERE face_value = 3;
INSERT INTO coins VALUES (5, '5 копеек');
DELETE FROM coins WHERE face_value = 0.25;
SELECT * FROM coins;
SELECT * FROM coins_history ORDER BY face_value, start_date;
\set d '2022-12-16 21:12:45.699279+03'
SELECT face_value, name
FROM coins_history
WHERE start_date <= :'d' AND (end_date IS NULL OR :'d' < end_date)
ORDER BY face_value;

CREATE TABLE airports(
    code char(3) PRIMARY KEY,
    name text NOT NULL
);
CREATE TABLE flights(
    id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    airport_from char(3) NOT NULL REFERENCES airports(code),
    airport_to   char(3) NOT NULL REFERENCES airports(code),
    UNIQUE (airport_from, airport_to)
);
INSERT INTO airports VALUES
    ('SVO', 'Москва. Шереметьево'),
    ('LED', 'Санкт-Петербург. Пулково'),
    ('TOF', 'Томск. Богашево');
 INSERT INTO flights(airport_from, airport_to) VALUES
    ('SVO','LED');
CREATE VIEW flights_v AS
SELECT id,
       (SELECT name
        FROM airports
        WHERE code = airport_from) airport_from,
       (SELECT name
        FROM airports
        WHERE code = airport_to) airport_to
FROM flights;
SELECT * FROM flights_v;
UPDATE flights_v
SET airport_to = 'Томск. Богашево'
WHERE id = 2;

CREATE OR REPLACE FUNCTION flights_v_update() RETURNS trigger
AS $$
DECLARE
    code_to char(3);
BEGIN
    BEGIN
        SELECT code INTO STRICT code_to
        FROM airports
        WHERE name = NEW.airport_to;
    EXCEPTION
        WHEN no_data_found THEN
            RAISE EXCEPTION 'Аэропорт % отсутствует', NEW.airport_to;
    END;
    UPDATE flights
    SET airport_to = code_to
    WHERE id = OLD.id; -- изменение id игнорируем
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER flights_v_upd_trigger
INSTEAD OF UPDATE ON flights_v
FOR EACH ROW EXECUTE FUNCTION flights_v_update();
UPDATE flights_v
SET airport_to = 'Томск. Богашево'
WHERE id = 2;
SELECT * FROM flights_v;
UPDATE flights_v
SET airport_to = 'Южно-Сахалинск. Хомутово'
WHERE id = 2;

CREATE OR REPLACE FUNCTION describe_ddl() RETURNS event_trigger
AS $$
DECLARE
    r record;
BEGIN
    -- Для события ddl_command_end контекст вызова в специальной функции
    FOR r IN SELECT * FROM pg_event_trigger_ddl_commands()
    LOOP
        RAISE NOTICE '%. тип: %, OID: %, имя: % ',
            r.command_tag, r.object_type, r.objid, r.object_identity;
    END LOOP;
    -- Функции триггера событий не нужно возвращать значение
END;
$$ LANGUAGE plpgsql;
CREATE EVENT TRIGGER after_ddl
ON ddl_command_end EXECUTE FUNCTION describe_ddl();
CREATE TABLE t1(id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY);

-- Практика
CREATE OR REPLACE FUNCTION update_catalog() RETURNS trigger
AS $$
BEGIN
    INSERT INTO operations(book_id, qty_change) VALUES
        (OLD.book_id, NEW.onhand_qty - coalesce(OLD.onhand_qty,0));
    RETURN NEW;
END;
$$ VOLATILE LANGUAGE plpgsql;
CREATE TRIGGER update_catalog_trigger
INSTEAD OF UPDATE ON catalog_v
FOR EACH ROW
EXECUTE FUNCTION update_catalog();
ALTER TABLE books ADD COLUMN onhand_qty integer;
CREATE OR REPLACE FUNCTION update_onhand_qty() RETURNS trigger
AS $$
BEGIN
    UPDATE books
    SET onhand_qty = onhand_qty + NEW.qty_change
    WHERE book_id = NEW.book_id;
    RETURN NULL;
END;
$$ VOLATILE LANGUAGE plpgsql;
BEGIN;
LOCK TABLE operations;
UPDATE books b
SET onhand_qty = (
    SELECT coalesce(sum(qty_change),0)
    FROM operations o
    WHERE o.book_id = b.book_id
);
ALTER TABLE books ALTER COLUMN onhand_qty SET DEFAULT 0;
ALTER TABLE books ALTER COLUMN onhand_qty SET NOT NULL;
ALTER TABLE books ADD CHECK(onhand_qty >= 0);

CREATE TRIGGER update_onhand_qty_trigger
AFTER INSERT ON operations
FOR EACH ROW
EXECUTE FUNCTION update_onhand_qty();
COMMIT;

\d+ catalog_v

CREATE OR REPLACE VIEW catalog_v AS
SELECT b.book_id,
       b.title,
       b.onhand_qty,
       book_name(b.book_id, b.title) AS display_name,
       b.authors
FROM   books b
ORDER BY display_name;

SELECT * FROM catalog_v WHERE book_id = 1 \gx
DROP FUNCTION onhand_qty(books);
SELECT * FROM catalog_v WHERE book_id = 1 \gx
INSERT INTO operations(book_id, qty_change) VALUES (1,+10);
SELECT * FROM catalog_v WHERE book_id = 1 \gx
INSERT INTO operations(book_id, qty_change) VALUES (1,-100);

CREATE DATABASE plpgsql_triggers;
\c plpgsql_triggers
CREATE TABLE t(
    id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    s text,
    version integer
);
CREATE OR REPLACE FUNCTION inc_version() RETURNS trigger
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.version := 1;
    ELSE
        NEW.version := OLD.version + 1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER t_inc_version
BEFORE INSERT OR UPDATE ON t
FOR EACH ROW EXECUTE FUNCTION inc_version();
INSERT INTO t(s) VALUES ('Раз');
INSERT INTO t(s,version) VALUES ('Два',42);
UPDATE t SET s = lower(s) WHERE id = 1;
UPDATE t SET s = lower(s), version = 42 WHERE id = 2;
CREATE TABLE orders (
    id integer PRIMARY KEY,
    total_amount numeric(20,2) NOT NULL DEFAULT 0
);
CREATE TABLE lines (
   id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
   order_id integer NOT NULL REFERENCES orders(id),
   amount numeric(20,2) NOT NULL
);
CREATE FUNCTION total_amount_ins() RETURNS trigger
AS $$
BEGIN
    WITH l(order_id, total_amount) AS (
        SELECT order_id, sum(amount)
        FROM new_table
        GROUP BY order_id
    )
    UPDATE orders o
    SET total_amount = o.total_amount + l.total_amount
    FROM l
    WHERE o.id = l.order_id;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER lines_total_amount_ins
AFTER INSERT ON lines
REFERENCING
    NEW TABLE AS new_table
FOR EACH STATEMENT
EXECUTE FUNCTION total_amount_ins();
CREATE FUNCTION total_amount_upd() RETURNS trigger
AS $$
BEGIN
    WITH l_tmp(order_id, amount) AS (
        SELECT order_id, amount FROM new_table
        UNION ALL
        SELECT order_id, -amount FROM old_table
    ), l(order_id, total_amount) AS (
        SELECT order_id, sum(amount)
        FROM l_tmp
        GROUP BY order_id
        HAVING sum(amount) <> 0
    )
    UPDATE orders o
    SET total_amount = o.total_amount + l.total_amount
    FROM l
    WHERE o.id = l.order_id;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER lines_total_amount_upd
AFTER UPDATE ON lines
REFERENCING
    OLD TABLE AS old_table
    NEW TABLE AS new_table
FOR EACH STATEMENT
EXECUTE FUNCTION total_amount_upd();
CREATE FUNCTION total_amount_del() RETURNS trigger
AS $$
BEGIN
    WITH l(order_id, total_amount) AS (
        SELECT order_id, -sum(amount)
        FROM old_table
        GROUP BY order_id
    )
    UPDATE orders o
    SET total_amount = o.total_amount + l.total_amount
    FROM l
    WHERE o.id = l.order_id;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER lines_total_amount_del
AFTER DELETE ON lines
REFERENCING
    OLD TABLE AS old_table
FOR EACH STATEMENT
EXECUTE FUNCTION total_amount_del();
CREATE FUNCTION total_amount_truncate() RETURNS trigger
AS $$
BEGIN
    UPDATE orders SET total_amount = 0;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER lines_total_amount_truncate
AFTER TRUNCATE ON lines
FOR EACH STATEMENT
EXECUTE FUNCTION total_amount_truncate();

INSERT INTO orders VALUES (1), (2);
SELECT * FROM orders ORDER BY id;
INSERT INTO lines (order_id, amount) VALUES
    (1,100), (1,100), (2,500), (2,500);
SELECT * FROM lines;
SELECT * FROM orders ORDER BY id;
UPDATE lines SET amount = amount * 2;
SELECT * FROM orders ORDER BY id;
DELETE FROM lines WHERE id = 1;
SELECT * FROM orders ORDER BY id;
TRUNCATE lines;
SELECT * FROM orders ORDER BY id;

