
DO
$$
DECLARE

    obj record;
    rad record;
    connect_name text = 'C8fM37Ap8C';

BEGIN

--     PERFORM dblink_connect(connect_name, 'dbname=map');

    RAISE INFO '%', dblink_connect(connect_name, 'dbname=map');

    PERFORM dblink_disconnect(connect_name);


END
$$ LANGUAGE plpgsql;



DO
$$
DECLARE

    obj record;
    rad record;
    connect_name text = 'C8fM37Ap8C';

BEGIN

    PERFORM dblink_connect(connect_name, 'dbname=map');

    FOR obj IN
        SELECT * FROM dblink(connect_name, 'SELECT id,name,raw_data,constellation_id,region_id,status,update,etag FROM objects.objects_systems ORDER BY id')
        AS (id integer,name text,raw_data jsonb,constellation_id integer,region_id integer,status smallint,update timestamptz,etag text)
    LOOP

        SELECT radius INTO rad FROM src_data.objects.temp_radius WHERE itemid = obj.id;

        INSERT INTO src_data.objects.objects_systems(id,name,raw_data,radius,constellation_id,region_id,status,update,etag)
        VALUES (obj.id, obj.name, obj.raw_data, rad.radius, obj.constellation_id, obj.region_id, obj.status, obj.update, obj.etag);

    END LOOP;

    PERFORM dblink_disconnect(connect_name);

END
$$ LANGUAGE plpgsql;



SELECT dblink_disconnect('C8fM37Ap8C');


/*

 --     SELECT id, name, raw_data, constellation_id, region_id, status, update, etag INTO obj FROM map.objects.objects_systems ORDER BY pos;
--     SELECT itemid, radius INTO rad FROM src_data.objects.temp_radius WHERE itemid = obj.id;
--
--     INSERT INTO src_data.objects.objects_systems(id, name, raw_data, constellation_id, region_id, status, update, etag)
--     VALUES (obj.id, obj.name, obj.raw_data, obj.constellation_id, obj.region_id, obj.status, obj.update, obj.etag);
--
--     INSERT INTO src_data.objects.objects_systems(radius) VALUES (rad.radius);

--         SELECT * INTO obj FROM dblink(connect_name, 'SELECT id, name, raw_data, constellation_id, region_id, status, update, etag FROM objects.objects_systems ORDER BY pos LIMIT 3')
--         AS (id integer, name text, raw_data jsonb, constellation_id integer, region_id integer, status smallint, update timestamptz, etag text);

 */