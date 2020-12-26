
CREATE OR REPLACE FUNCTION func.objects_systems_parsing(schema text) RETURNS VOID AS
$$
DECLARE
    tablen text;
    system jsonb;
    objects jsonb;
    subjects integer;

    list_stars jsonb = (array_to_json(ARRAY[]::text[]))::jsonb;
    list_stargates jsonb = (array_to_json(ARRAY[]::text[]))::jsonb;
    list_stations jsonb = (array_to_json(ARRAY[]::text[]))::jsonb;
    list_planets jsonb = (array_to_json(ARRAY[]::text[]))::jsonb;
    list_moons jsonb = (array_to_json(ARRAY[]::text[]))::jsonb;
    list_belts jsonb = (array_to_json(ARRAY[]::text[]))::jsonb;

    connect_name text = 'd45ttgj655';
    err0 text; err1 text; err2 text; err3 text;

    data text;
BEGIN

    PERFORM dblink_connect(connect_name, 'dbname=map');

    FOR system IN
        EXECUTE format('SELECT raw_data FROM %s.objects_%s ORDER BY pos;', schema, 'systems')

    LOOP

        FOREACH tablen IN ARRAY
            ARRAY['stars', 'stargates', 'stations', 'planets']
        LOOP

            FOR subjects IN
                SELECT value FROM jsonb_array_elements(
                    (CASE tablen
                        WHEN 'stars'     THEN jsonb_path_query_array(system, '$.star_id[*]')
                        WHEN 'stargates' THEN jsonb_path_query_array(system, '$.stargates[*]')
                        WHEN 'stations'  THEN jsonb_path_query_array(system, '$.stations[*]')
                        WHEN 'planets'   THEN jsonb_path_query_array(system, '$.planets[*].planet_id[*]')
                    END))
            LOOP

                PERFORM dblink_exec(connect_name, format('INSERT INTO %s.objects_%s (id, system_id, constellation_id) ' ||
                'VALUES (%L, %L, %L) ON CONFLICT (id) DO NOTHING;',
                schema, tablen, subjects, (system ->> 'system_id'), (system ->> 'constellation_id')));

            END LOOP;


        END LOOP;

        --=========================================================

        FOR objects IN
                SELECT jsonb_path_query(system, '$.planets[*]')
            LOOP

                FOREACH tablen IN ARRAY
                    ARRAY['moons', 'belts']

                LOOP

                    FOR subjects IN
                        SELECT jsonb_array_elements(
                            (CASE tablen
                                WHEN 'moons' THEN jsonb_path_query_array(objects, '$.moons[*]')
                                WHEN 'belts' THEN jsonb_path_query_array(objects, '$.asteroid_belts[*]')
                            END))
                    LOOP

                        PERFORM dblink_exec(connect_name, format('INSERT INTO %s.objects_%s (id, planet_id, system_id, constellation_id) ' ||
                        'VALUES (%L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
                        schema, tablen, subjects, (objects ->> 'planet_id'), (system ->> 'system_id'), (system ->> 'constellation_id')));

                    END LOOP;

                END LOOP;

            END LOOP;

        list_stars = list_stars || jsonb_path_query_array(system, '$.star_id[*]');
        list_stargates = list_stargates || jsonb_path_query_array(system, '$.stargates[*]');
        list_stations = list_stations || jsonb_path_query_array(system, '$.stations[*]');
        list_planets = list_planets || jsonb_path_query_array(system, '$.planets[*].planet_id[*]');
        list_moons = list_moons || jsonb_path_query_array(system, '$.planets[*].moons[*]');
        list_belts = list_belts || jsonb_path_query_array(system, '$.planets[*].asteroid_belts[*]');

    END LOOP;

    FOREACH tablen IN ARRAY -- objects_list_id > name
        ARRAY['stars', 'stargates', 'stations', 'planets', 'moons', 'belts']
    LOOP

        PERFORM dblink_exec(connect_name, format('UPDATE %s.objects_list_id SET id = %L, update = now() WHERE name = %L;', schema,
            (CASE tablen
                WHEN 'stars' THEN list_stars
                WHEN 'stargates' THEN list_stargates
                WHEN 'stations' THEN list_stations
                WHEN 'planets' THEN list_planets
                WHEN 'moons' THEN list_moons
                WHEN 'belts' THEN list_belts
            END), tablen));

    END LOOP;

    PERFORM dblink_disconnect(connect_name);

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS err1 = PG_EXCEPTION_CONTEXT, err2 = RETURNED_SQLSTATE, err3 = MESSAGE_TEXT;
            err0 = (regexp_match(err1, '(?<=function\s).*?(?=\()'))[1];
            err1 = (regexp_match(err1, '(?<=\)\s).*'))[1];
            RAISE LOG  E'%, % : %', err0 || ' ' || err1, err2, err3;
            RAISE INFO E'%, % : %', err0 || ' ' || err1, err2, err3;
            INSERT INTO func._error (object, message) VALUES (err0, err1 || ', ' || err2 || ' : ' || err3);
            PERFORM dblink_disconnect(connect_name);

END
$$ LANGUAGE plpgsql;

