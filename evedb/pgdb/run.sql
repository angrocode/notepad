
SET search_path TO "func";

SELECT func.objects_get_esi_id();

SELECT func.objects_get('regions');

SELECT func.objects_get('constellations');

SELECT func.objects_get('systems');

SELECT func.objects_get('regions', false);

SELECT func.objects_get('constellations', false);

SELECT func.objects_get('systems', false);

--==========================================

SELECT func.objects_systems_parsing('objects');

--==========================================

SELECT func.objects_get('stars');

SELECT func.objects_get('stargates');

SELECT func.objects_get('stations');

SELECT func.objects_get('planets');

SELECT func.objects_get('moons'); --

SELECT func.objects_get('belts');


SELECT func.objects_get('stars', false);

SELECT func.objects_get('stargates', false);

SELECT func.objects_get('stations', false);

SELECT func.objects_get('planets', false);

SELECT func.objects_get('moons', false);

SELECT func.objects_get('belts', false);

-- Run function from postprocessing.sql

--==========================================


SELECT * FROM objects.objects_regions WHERE status != 200 AND status != 304 OR status IS NULL ORDER BY pos;
SELECT * FROM objects.objects_constellations WHERE status != 200 AND status != 304 OR status IS NULL ORDER BY pos;
SELECT * FROM objects.objects_systems WHERE status != 200 AND status != 304 OR status IS NULL ORDER BY pos;
SELECT * FROM objects.objects_stars WHERE status != 200 AND status != 304 OR status IS NULL ORDER BY pos;
SELECT * FROM objects.objects_stargates WHERE status != 200 AND status != 304 OR status IS NULL ORDER BY pos;
SELECT * FROM objects.objects_stations WHERE status != 200 AND status != 304 OR status IS NULL ORDER BY pos;
SELECT * FROM objects.objects_planets WHERE status != 200 AND status != 304 OR status IS NULL ORDER BY pos;
SELECT * FROM objects.objects_moons WHERE status != 200 AND status != 304 OR status IS NULL ORDER BY pos;
SELECT * FROM objects.objects_belts WHERE status != 200 AND status != 304 OR status IS NULL ORDER BY pos;



