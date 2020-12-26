
CREATE OR REPLACE FUNCTION func.objects_get_esi_id(etag_on bool default true, sleep_on bool default false) RETURNS VOID AS
$$
DECLARE
    set_param record;
    get_conman record;
    err0 text; err1 text; err2 text; err3 text;
BEGIN

    FOR set_param IN
            SELECT name, etag FROM objects.objects_list_id WHERE
                (name = 'regions' OR name = 'constellations' OR name = 'systems')
        LOOP

            IF sleep_on THEN PERFORM pg_sleep(random() + 0.5); END IF;

            IF NOT etag_on THEN set_param.etag = ''; END IF;

            SELECT * INTO get_conman FROM func.map_conman(set_param.name, set_param.etag);

            UPDATE objects.objects_list_id SET
                update = get_conman.date,
                etag = get_conman.etag,
                status = get_conman.status
            WHERE name = set_param.name;

            IF get_conman.status = 200 THEN
                UPDATE objects.objects_list_id SET id = get_conman.content::jsonb WHERE name = set_param.name;
            END IF;

            IF get_conman.status != 200 AND get_conman.status != 304 THEN
                INSERT INTO func._log (script, object, message, status) VALUES ('objects_get_esi_id', set_param.name, 'Response status', get_conman.status);
            END IF;

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS err1 = PG_EXCEPTION_CONTEXT, err2 = RETURNED_SQLSTATE, err3 = MESSAGE_TEXT;
            err0 = (regexp_match(err1, '(?<=function\s).*?(?=\()'))[1];
            err1 = (regexp_match(err1, '(?<=\)\s).*'))[1];
            RAISE LOG  E'%, % : %', err0 || ' ' || err1, err2, err3;
            RAISE INFO E'%, % : %', err0 || ' ' || err1, err2, err3;
            INSERT INTO func._error (object, message) VALUES (err0, err1 || ', ' || err2 || ' : ' || err3);

END
$$ LANGUAGE plpgsql;


SELECT func.objects_get_esi_id();


DROP FUNCTION func.objects_get_esi_id;
