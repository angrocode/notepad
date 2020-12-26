
CREATE OR REPLACE FUNCTION func.map_conman(
        set_point varchar,
        set_etag varchar DEFAULT '',
        set_object integer DEFAULT NULL
    )
    returns TABLE(
        date timestamptz,
        status smallint,
        content text,
        etag varchar,
        error smallint
    ) AS
$$
DECLARE
    set_url varchar;
    set_uri varchar;
    set_method varchar := 'GET';
    response func.http_response;
    set_headers text := '{"(Host, esi.evetech.net)", ' ||
                        '"(User-Agent, EVE Center dev.local)", ' ||
                        '"(From, center@angro.org)", ' ||
                        '"(Accept-Encoding, \"gzip, deflate\")", ' ||
                        '"(Accept, application/json)"}';
    field varchar; value varchar;
    err0 text; err1 text; err2 text; err3 text;
BEGIN

    FOR field, value IN
            SELECT point, uri FROM func._point WHERE point = 'esi' OR point = set_point
        LOOP
            IF field = 'esi' THEN set_url = value; END IF;
            IF field = set_point THEN set_uri = value; END IF;
        END LOOP;

--     SELECT uri INTO set_url FROM func._point WHERE point = 'url';
--     SELECT uri INTO set_uri FROM func._point WHERE point = set_point;

    set_uri = set_url || set_uri;

    --=============== headers ============

    IF set_etag IS NOT NULL AND NOT set_etag = '' THEN
        set_headers = regexp_replace(set_headers, '}', '');
        set_headers = set_headers || ', "(If-None-Match, ' || set_etag || ')"}';
    END IF;

    --=============== uri =================

    IF set_uri ~ '\{.*?\}' THEN
        set_uri = regexp_replace(set_uri, '\{.*?\}', set_object::varchar);
    END IF;

    --=============== request =============

    response = map.func.http((
        upper(set_method),
        set_uri,
        set_headers,
        NULL,
        NULL
    )::map.func.http_request);

    --=============== response =============

    FOR field, value IN
        SELECT * FROM unnest(response.headers)
    LOOP
        IF    field = 'Date' THEN date = value;
        ELSIF field = 'Etag' THEN etag = (regexp_matches(value, '(?<=").*?(?=")'))[1];
        ELSIF field = 'X-Esi-Error-Limit-Remain' THEN error = value;
        END IF;
    END LOOP;

    status  = response.status;
    content = response.content;

    IF error < 100 THEN
        INSERT INTO func._error (object, message) VALUES ('map_conman', 'Error-Limit' || ':' || error);
    END IF;

    IF status != 200 AND status != 304 THEN
        INSERT INTO func._log (script, object, message, status) VALUES ('map_conman', 'point:'||set_point||' object:'||set_object, 'Response status', status);
    END IF;

    RETURN NEXT;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS err1 = PG_EXCEPTION_CONTEXT, err2 = RETURNED_SQLSTATE, err3 = MESSAGE_TEXT;
            err0 = (regexp_match(err1, '(?<=function\s).*?(?=\()'))[1];
            err1 = (regexp_match(err1, '(?<=\)\s).*'))[1];
            RAISE LOG  E'%, % : %', err0 || ' ' || err1, err2, err3;
            RAISE INFO E'%, % : %', err0 || ' ' || err1, err2, err3;
            INSERT INTO func._error (object, message) VALUES (err0, err1 || ', ' || err2 || ' : ' || err3);
            status = 0; date = now();
            RETURN NEXT;

END
$$ LANGUAGE plpgsql;

-- 064a83b8b3ba755f32bc8f1052e18a8f12d58d4d25f33183088d8588
SELECT * FROM func.map_conman('regions', '');


DROP FUNCTION func.map_conman;

/*

map=# SELECT func.objects_get('planets', false);
INFO:  map_conman line 63 at assignment
SQL statement "SELECT *                 FROM func.map_conman(point, set_etag, set_object)"
PL/pgSQL function objects_get(text,boolean,boolean,boolean,integer) line 99 at SQL statement, 22P02 : invalid input syntax for type json
INFO:  map_conman line 63 at assignment
SQL statement "SELECT *                 FROM func.map_conman(point, set_etag, set_object)"
PL/pgSQL function objects_get(text,boolean,boolean,boolean,integer) line 99 at SQL statement, 22P02 : invalid input syntax for type json
INFO:  map_conman line 63 at assignment
SQL statement "SELECT *                 FROM func.map_conman(point, set_etag, set_object)"
PL/pgSQL function objects_get(text,boolean,boolean,boolean,integer) line 99 at SQL statement, 22P02 : invalid input syntax for type json
INFO:  map_conman line 43 at assignment
SQL statement "SELECT *                 FROM func.map_conman(point, set_etag, set_object)"
PL/pgSQL function objects_get(text,boolean,boolean,boolean,integer) line 99 at SQL statement, XX000 : Operation timed out after 1000 milliseconds with 0 out of 0 bytes received

 */
