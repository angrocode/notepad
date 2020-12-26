
CREATE OR REPLACE FUNCTION func.objects_get(
        object text,
        full_upd bool default true,
        etag_on bool default true,
        timer_on bool default false,
        limit_request integer default null
    ) RETURNS integer AS
$$
DECLARE
    set_object integer;
    list_id jsonb;
    set_etag text;
    get_conman record;
    get_data jsonb;
    point text;
    schema text = 'objects';

    counter integer = 0;
    counter_200 integer = 0;
    counter_304 integer = 0;
    counter_e integer = 0;
    counter_exe integer = 0;
    timer timestamptz;
    connect_name text = 'dDj5hVf86Az';
    err0 text; err1 text; err2 text; err3 text;
BEGIN

    CASE
        WHEN object = 'regions' OR object = 'region' THEN
            object = 'regions';
            point = 'region';
            EXECUTE format('SELECT id FROM %s.objects_%s LIMIT 1;', schema, object);
        WHEN object = 'constellations' OR object = 'constellation' THEN
            object = 'constellations';
            point = 'constellation';
            EXECUTE format('SELECT id FROM %s.objects_%s LIMIT 1;', schema, object);
        WHEN object = 'systems' OR object = 'system' THEN
            object = 'systems';
            point = 'system';
            EXECUTE format('SELECT id FROM %s.objects_%s LIMIT 1;', schema, object);
        WHEN object = 'stars' OR object = 'star' THEN
            object = 'stars';
            point = 'star';
            EXECUTE format('SELECT id FROM %s.objects_%s LIMIT 1;', schema, object);
        WHEN object = 'stargates' OR object = 'stargate' THEN
            object = 'stargates';
            point = 'stargate';
            EXECUTE format('SELECT id FROM %s.objects_%s LIMIT 1;', schema, object);
        WHEN object = 'stations' OR object = 'station' THEN
            object = 'stations';
            point = 'station';
            EXECUTE format('SELECT id FROM %s.objects_%s LIMIT 1;', schema, object);
        WHEN object = 'planets' OR object = 'planet' THEN
            object = 'planets';
            point = 'planet';
            EXECUTE format('SELECT id FROM %s.objects_%s LIMIT 1;', schema, object);
        WHEN object = 'moons' OR object = 'moon' THEN
            object = 'moons';
            point = 'moon';
            EXECUTE format('SELECT id FROM %s.objects_%s LIMIT 1;', schema, object);
        WHEN object = 'belts' OR object = 'belt' THEN
            object = 'belts';
            point = 'belt';
            EXECUTE format('SELECT id FROM %s.objects_%s LIMIT 1;', schema, object);
        ELSE RAISE 'Object NOT FOUND';
    END CASE;

    PERFORM dblink_connect(connect_name, 'dbname=map');

    EXECUTE format('SELECT id FROM %s.objects_list_id WHERE name = %L;', schema, object) INTO list_id;

    FOR set_object IN
            SELECT value FROM jsonb_array_elements(list_id)
        LOOP

            EXECUTE format('SELECT id FROM %s.objects_%s WHERE id = %L LIMIT 1;', schema, object, set_object);
            GET DIAGNOSTICS counter_exe = ROW_COUNT;

            IF counter_exe = 0 THEN

                PERFORM dblink_exec(connect_name, format('INSERT INTO %s.objects_%s(id) VALUES (%L);', schema, object, set_object));

            END IF;

        END LOOP;

    timer = clock_timestamp();

    FOR set_object IN
            EXECUTE format('SELECT id FROM %s.objects_%s %s ORDER BY pos;', schema, object,
                (CASE
                    WHEN NOT full_upd THEN
                        'WHERE status != 200 AND status != 304 OR status IS NULL'
                    WHEN full_upd THEN ''
                END))
        LOOP

            IF limit_request IS NOT NULL THEN
                EXIT WHEN counter >= limit_request;
            END IF;

            EXECUTE format('SELECT etag FROM %s.objects_%s WHERE id = %L;', schema, object, set_object) INTO set_etag;

                IF set_etag IS NULL OR NOT etag_on THEN set_etag = ''; END IF;

            SELECT * INTO get_conman FROM func.map_conman(point, set_etag, set_object);

                IF get_conman.status != 200 AND get_conman.status != 304 THEN

                    PERFORM dblink_exec(connect_name, format('INSERT INTO func._log (script, object, message, status) ' ||
                        'VALUES (''objects_get'', %L, %L, %s);',
                         object, set_object, get_conman.status));

                    CONTINUE;

                END IF;

            get_data = (get_conman.content)::jsonb - 'description';

            IF get_conman.status = 200 THEN

                counter_200 = counter_200 + 1;

                PERFORM dblink_exec(connect_name, format('UPDATE %s.objects_%s SET
                                name = %L,
                                raw_data = %L,
                                status = %L,
                                update = %L,
                                etag = %L
                            WHERE id = %L ;',
                        schema, object,
                        (get_data ->> 'name'),
                        (get_data),
                        get_conman.status,
                        get_conman.date,
                        get_conman.etag,
                        set_object
                    ));

            ELSIF get_conman.status = 304 THEN

                counter_304 = counter_304 + 1;

                PERFORM dblink_exec(connect_name, format('UPDATE %s.objects_%s SET
                                status = %L,
                                update = %L,
                                etag = %L
                            WHERE id = %L ;',
                        schema, object,
                        get_conman.status,
                        get_conman.date,
                        get_conman.etag,
                        set_object
                    ));

            ELSIF get_conman.status != 200 AND get_conman.status != 304 THEN

                counter_e = counter_e + 1;

                PERFORM dblink_exec(connect_name, format('UPDATE %s.objects_%s SET
                                status = %L,
                                update = %L
                            WHERE id = %L ;',
                        schema, object,
                        get_conman.status,
                        get_conman.date,
                        set_object
                    ));

            END IF;

            counter = counter + 1;

            IF timer_on AND counter % 10 = 0 THEN
                RAISE INFO '10 request: % %', (extract(epoch from clock_timestamp()) - extract(epoch from timer)), 'sec';
                timer = clock_timestamp();
            END IF;

        END LOOP;

    PERFORM dblink_disconnect(connect_name);

    EXECUTE format('INSERT INTO func._log (script, object, message, status) VALUES (''objects_get'', %L, ''200:%s 304:%s Error:%s'', %L)',
        object, counter_200, counter_304, counter_e,
        (CASE
         WHEN counter_e >   0 THEN 0
         WHEN counter_200 > 0 THEN 200
         WHEN counter_304 > 0 THEN 304 END)
    );

    EXECUTE format('INSERT INTO func._status(object, status) VALUES (''objects_%s'',
                    (CASE WHEN %s > 0 THEN 200 ELSE 304 END)
                ) ON CONFLICT (object) DO UPDATE SET
                    status = excluded.status;', object, counter_200);

    IF counter_200 > 0 THEN
        RETURN 200;
    ELSIF counter_304 > 0 THEN
        RETURN 304;
    ELSE
        RETURN NULL;
    END IF;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS err1 = PG_EXCEPTION_CONTEXT, err2 = RETURNED_SQLSTATE, err3 = MESSAGE_TEXT;
            err0 = (regexp_match(err1, '(?<=function\s).*?(?=\()'))[1];
            err1 = (regexp_match(err1, '(?<=\)\s).*'))[1];
            RAISE LOG  E'%, % : %', err0 || ' ' || err1, err2, err3;
            RAISE INFO E'%, % : %', err0 || ' ' || err1, err2, err3;
            INSERT INTO func._error (object, message) VALUES (err0, err1 || ', ' || err2 || ' : ' || err3);
            PERFORM dblink_disconnect(connect_name);
            RETURN NULL;


END
$$ LANGUAGE plpgsql;

