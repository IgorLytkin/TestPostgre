-- 10.06.2022 Выгрузка данных из Дзен-мани
-- curl -s -X POST -H "Authorization: Bearer ${ZENMONEY_TOKEN}" -H 'Content-Type: application/json' --data "{\"currentClientTimestamp\":${TIMESTAMP}, \"lastServerTimestamp\":0}" https://api.zenmoney.ru/v8/diff/ > ./backup.json
-- токен тут https://zerro.app/token
-- описание тут https://github.com/zenmoney/ZenPlugins/wiki/ZenMoney-API#entities

