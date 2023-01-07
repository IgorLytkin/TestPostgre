-- Задания от Егора https://t.me/miruzzy
 DO $$
                 DECLARE
                     a integer[] := ARRAY[10,20,30];
                     iter RECORD;
                 BEGIN
                     FOR iter IN select ROW_NUMBER() over () as row, val from unnest(a) as val LOOP
                         RAISE NOTICE 'a[%] = %', iter.row, iter.val;
                     END LOOP;
                 END;
                 $$ LANGUAGE plpgsql;

drop table tablea;
create table tablea ( id int, user_id int, o_num int, price int);
insert into tablea(id, user_id, o_num, price) VALUES (1,1,1,100000);
insert into tablea(id, user_id, o_num, price) VALUES (2,2,1,80000);
insert into tablea(id, user_id, o_num, price) VALUES (3,3,2,150000);
insert into tablea(id, user_id, o_num, price) VALUES (4,4,2,10000);

drop table personal;
create table personal(user_id int,surname text);
insert into personal(user_id,surname)values (1, 'Иванов');
insert into personal(user_id,surname)values (2, 'Петров');
insert into personal(user_id,surname)values (3, 'Лыткин');
insert into personal(user_id,surname)values (4, 'Сидоров');

-- tablea+personal
select t.o_num Отдел,row_number() over (PARTITION BY o_num ORDER BY price desc) Позиция, p.surname Фамилия, t.price Компенсация
from tablea t inner join personal p on t.user_id = p.user_id
order by t.o_num, t.price desc;

select row_number() over(), user_id, price
from tablea
where o_num = 1
order by price desc;

drop table tab;
create table tab ( data text );
insert into tab(data) values ('аваа');
insert into tab(data) values ('ааав');
insert into tab(data) values ('ва');
insert into tab(data) values ('саа');
insert into tab(data) values ('сав');
insert into tab(data) values ('аа');

select substr(t.data,1,1) Буква,
       count(*) over (PARTITION BY substr(t.data,1,1)) Всего,
       row_number() over (PARTITION BY substr(t.data,1,1) ORDER BY data ) Номер,
       t.data
from tab t
order by 1,3 ;