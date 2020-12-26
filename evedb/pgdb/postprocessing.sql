
--CREATE OR REPLACE FUNCTION func.objects_postp_region(schema text, object text) RETURNS VOID AS
DO
$$
DECLARE
    schema text = 'objects';
    tabl text;
    clumn text[];
    subjects record;
	region_id integer;
    connect_name text = 'Hb60Mw5zQ';
BEGIN

    PERFORM dblink_connect(connect_name, 'dbname=map');

    FOREACH tabl IN ARRAY
        ARRAY ['constellations', 'systems', 'stars', 'stargates', 'stations', 'planets', 'moons', 'belts']
    LOOP

        clumn = ARRAY(SELECT column_name FROM information_schema.columns
            WHERE table_schema = schema AND table_name = 'objects_'||tabl);

        FOR subjects IN
            EXECUTE 'SELECT * FROM '||schema||'.objects_'||tabl||' ORDER BY pos;'
        LOOP

            IF 'region_id' = ANY(clumn) THEN

                    region_id = jsonb_path_query(subjects.raw_data, '$.region_id');

                    IF region_id IS NULL THEN

                        region_id = jsonb_path_query((SELECT raw_data
                                          FROM objects.objects_constellations
                                          WHERE id = subjects.constellation_id),
                                        '$.region_id');
                    END IF;

            END IF;

            PERFORM dblink_exec(connect_name, format('UPDATE %s.objects_%s SET region_id = %s WHERE id = %s',
                            schema, tabl, region_id, (subjects.id)));

            region_id = NULL;

        END LOOP;

    END LOOP;

    PERFORM dblink_disconnect(connect_name);

END
$$ LANGUAGE plpgsql;


--CREATE OR REPLACE FUNCTION func.objects_postp_gate_dest(schema text, object text) RETURNS VOID AS
DO
$$
DECLARE
    schema text = 'objects';
    tabl text;
    subjects record;
	system_id integer;
    stargate_id integer;
    connect_name text = 'Ns92If5l';
BEGIN

    PERFORM dblink_connect(connect_name, 'dbname=map');

    FOREACH tabl IN ARRAY
        ARRAY ['stargates']
    LOOP

        FOR subjects IN
            EXECUTE 'SELECT * FROM '||schema||'.objects_'||tabl||' ORDER BY pos;'
        LOOP

            system_id = jsonb_path_query(subjects.raw_data, '$.destination.system_id');
            stargate_id = jsonb_path_query(subjects.raw_data, '$.destination.stargate_id');

            PERFORM dblink_exec(connect_name, format('UPDATE %s.objects_%s SET dest_system = %s, dest_stargate = %s WHERE id = %s',
                            schema, tabl, system_id, stargate_id, (subjects.id)));

            system_id = NULL;
            stargate_id = NULL;

        END LOOP;

    END LOOP;

    PERFORM dblink_disconnect(connect_name);

END
$$ LANGUAGE plpgsql;