
CREATE ROLE "map" WITH NOINHERIT NOLOGIN;
COMMENT ON ROLE "map" IS E'owner map db';

CREATE ROLE "map_func" WITH NOINHERIT NOLOGIN;
COMMENT ON ROLE "map_func" IS E'owner function schema';

CREATE DATABASE "map" WITH
    OWNER "map"
    TEMPLATE "template0"
    ENCODING 'UTF8'
    LC_COLLATE 'en_US.UTF-8'
    LC_CTYPE 'en_US.UTF-8';

-- Select DataBase "map"

DROP SCHEMA "public";


CREATE SCHEMA IF NOT EXISTS "func";
ALTER SCHEMA "func" OWNER TO "map_func";
COMMENT ON SCHEMA "func" IS E'functions';
SET search_path TO "func";

CREATE EXTENSION http;
CREATE EXTENSION dblink;

CREATE TABLE func._status
(
    time timestamptz default now(),
    object text,
    status smallint
);
ALTER TABLE func._status
	ADD CONSTRAINT func_status_ui UNIQUE (object);

CREATE TABLE func._error
(
    time timestamptz default now(),
    object text,
    message text
);

CREATE TABLE func._log
(
    time timestamptz default now(),
    script text,
    object text,
    message text,
    status smallint
);

CREATE TABLE func._point
(
    point varchar,
    uri   varchar
);

ALTER TABLE func._point
	ADD CONSTRAINT func_point_ui UNIQUE (point);

INSERT INTO func._point (point, uri) VALUES ('esi', 'https://esi.evetech.net/latest');
INSERT INTO func._point (point, uri) VALUES ('regions', '/universe/regions/');
INSERT INTO func._point (point, uri) VALUES ('region', '/universe/regions/{region_id}/');
INSERT INTO func._point (point, uri) VALUES ('constellations', '/universe/constellations/');
INSERT INTO func._point (point, uri) VALUES ('constellation', '/universe/constellations/{constellation_id}/');
INSERT INTO func._point (point, uri) VALUES ('systems', '/universe/systems/');
INSERT INTO func._point (point, uri) VALUES ('system', '/universe/systems/{system_id}/');
INSERT INTO func._point (point, uri) VALUES ('stargate', '/universe/stargates/{stargate_id}/');
INSERT INTO func._point (point, uri) VALUES ('star', '/universe/stars/{star_id}/');
INSERT INTO func._point (point, uri) VALUES ('planet', '/universe/planets/{planet_id}/');
INSERT INTO func._point (point, uri) VALUES ('moon', '/universe/moons/{moon_id}/');
INSERT INTO func._point (point, uri) VALUES ('asteroid', '/universe/asteroid_belts/{asteroid_belt_id}/');
INSERT INTO func._point (point, uri) VALUES ('station', '/universe/stations/{station_id}/');
INSERT INTO func._point (point, uri) VALUES ('structures', '/universe/structures/');
INSERT INTO func._point (point, uri) VALUES ('structure', '/universe/structures/{structure_id}/');

--====================================================

CREATE SCHEMA IF NOT EXISTS "objects";
COMMENT ON SCHEMA "objects" IS E'eve esi openapi json';
SET search_path TO "objects";

--====================================================

--====================================================

CREATE TABLE objects.objects_list_id
(
	pos serial,
    name text,
    id jsonb,

	status smallint,
	update timestamptz,
	etag text
);

ALTER TABLE objects.objects_list_id
	ADD CONSTRAINT objects_list_id_pos_ui UNIQUE (pos);
ALTER TABLE objects.objects_list_id
	ADD CONSTRAINT objects_list_id_name_ui UNIQUE (name);

INSERT INTO objects.objects_list_id(name) VALUES ('regions');
INSERT INTO objects.objects_list_id(name) VALUES ('constellations');
INSERT INTO objects.objects_list_id(name) VALUES ('systems');
INSERT INTO objects.objects_list_id(name) VALUES ('stargates');
INSERT INTO objects.objects_list_id(name) VALUES ('stars');
INSERT INTO objects.objects_list_id(name) VALUES ('planets');
INSERT INTO objects.objects_list_id(name) VALUES ('moons');
INSERT INTO objects.objects_list_id(name) VALUES ('belts');
INSERT INTO objects.objects_list_id(name) VALUES ('stations');
INSERT INTO objects.objects_list_id(name) VALUES ('structures');

--====================================================

CREATE TABLE objects.objects_regions
(
    pos serial,
    id integer,
	name text,
	raw_data jsonb,

	status smallint,
	update timestamptz,
	etag text
);

ALTER TABLE objects.objects_regions
	ADD CONSTRAINT objects_regions_pos_ui UNIQUE (pos);
ALTER TABLE objects.objects_regions
	ADD CONSTRAINT objects_regions_id_ui UNIQUE (id);

--====================================================

CREATE TABLE objects.objects_constellations
(
    pos serial,
    id integer,
	name text,
	raw_data jsonb,
	region_id integer,

	status smallint,
	update timestamptz,
	etag text
);

ALTER TABLE objects.objects_constellations
	ADD CONSTRAINT objects_constellations_pos_ui UNIQUE (pos);
ALTER TABLE objects.objects_constellations
	ADD CONSTRAINT objects_constellations_id_ui UNIQUE (id);

--====================================================

CREATE TABLE objects.objects_systems
(
    pos serial,
    id integer,
	name text,
	raw_data jsonb,
	radius double precision,
	constellation_id integer,
	region_id integer,

	status smallint,
	update timestamptz,
	etag text
);

ALTER TABLE objects.objects_systems
	ADD CONSTRAINT objects_systems_pos_ui UNIQUE (pos);
ALTER TABLE objects.objects_systems
	ADD CONSTRAINT objects_systems_id_ui UNIQUE (id);

--====================================================

CREATE TABLE objects.objects_stars
(
    pos serial,
    id integer,
	name text,
	raw_data jsonb,
	radius double precision,
	system_id integer,
	constellation_id integer,
	region_id integer,

	status smallint,
	update timestamptz,
	etag text
);

ALTER TABLE objects.objects_stars
	ADD CONSTRAINT objects_stars_pos_ui UNIQUE (pos);
ALTER TABLE objects.objects_stars
	ADD CONSTRAINT objects_stars_id_ui UNIQUE (id);

--====================================================

CREATE TABLE objects.objects_stargates
(
    pos serial,
    id integer,
	name text,
	raw_data jsonb,
	system_id integer,
	constellation_id integer,
	region_id integer,
	dest_system integer,
	dest_stargate integer,

	status smallint,
	update timestamptz,
	etag text
);

ALTER TABLE objects.objects_stargates
	ADD CONSTRAINT objects_stargates_pos_ui UNIQUE (pos);
ALTER TABLE objects.objects_stargates
	ADD CONSTRAINT objects_stargates_id_ui UNIQUE (id);

--====================================================

CREATE TABLE objects.objects_stations
(
    pos serial,
    id integer,
	name text,
	raw_data jsonb,
	system_id integer,
	constellation_id integer,
	region_id integer,

	status smallint,
	update timestamptz,
	etag text
);

ALTER TABLE objects.objects_stations
	ADD CONSTRAINT objects_stations_pos_ui UNIQUE (pos);
ALTER TABLE objects.objects_stations
	ADD CONSTRAINT objects_stations_id_ui UNIQUE (id);

--====================================================

CREATE TABLE objects.objects_planets
(
    pos serial,
    id integer,
	name text,
	raw_data jsonb,
	radius double precision,
	system_id integer,
	constellation_id integer,
	region_id integer,

	status smallint,
	update timestamptz,
	etag text
);

ALTER TABLE objects.objects_planets
	ADD CONSTRAINT objects_planets_pos_ui UNIQUE (pos);
ALTER TABLE objects.objects_planets
	ADD CONSTRAINT objects_planets_id_ui UNIQUE (id);

--====================================================

CREATE TABLE objects.objects_moons
(
    pos serial,
    id integer,
	name text,
	raw_data jsonb,
	radius double precision,
	planet_id integer,
	system_id integer,
	constellation_id integer,
	region_id integer,

	status smallint,
	update timestamptz,
	etag text
);

ALTER TABLE objects.objects_moons
	ADD CONSTRAINT objects_moons_pos_ui UNIQUE (pos);
ALTER TABLE objects.objects_moons
	ADD CONSTRAINT objects_moons_id_ui UNIQUE (id);

--====================================================

CREATE TABLE objects.objects_belts
(
    pos serial,
    id integer,
	name text,
	raw_data jsonb,
	radius double precision,
	planet_id integer,
	system_id integer,
	constellation_id integer,
	region_id integer,

	status smallint,
	update timestamptz,
	etag text
);

ALTER TABLE objects.objects_belts
	ADD CONSTRAINT objects_belts_pos_ui UNIQUE (pos);
ALTER TABLE objects.objects_belts
	ADD CONSTRAINT objects_belts_id_ui UNIQUE (id);

--====================================================