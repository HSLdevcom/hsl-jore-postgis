CREATE SCHEMA IF NOT EXISTS jore;
CREATE SCHEMA IF NOT EXISTS jorestatic;
GRANT ALL ON SCHEMA jore TO CURRENT_USER;
GRANT ALL ON SCHEMA jorestatic TO CURRENT_USER;

-- Creating empty table to keep postgres happy
CREATE TABLE IF NOT EXISTS jorestatic.intermediate_points
(
    routes    character varying[],
    lon       numeric,
    lat       numeric,
    angles    integer[],
    length    numeric,
    point     geometry,
    nearbuses boolean,
    tag       date
);

CREATE TABLE IF NOT EXISTS jorestatic.intermediate_points_status
(
	"name" varchar(255) NOT NULL,
	target_date date NOT NULL,
	status text NULL,
	created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT intermediate_points_status_pkey PRIMARY KEY (name),
	CONSTRAINT intermediate_points_status_status_check CHECK ((status = ANY (ARRAY['READY'::text, 'PENDING'::text, 'ERROR'::text, 'EMPTY'::text])))
);

CREATE OR REPLACE FUNCTION jorestatic.create_intermediate_points(date date) RETURNS VOID AS
$$
DELETE FROM jorestatic.intermediate_points;

INSERT INTO jorestatic.intermediate_points
    (
        SELECT *,
               false as nearbuses,
               date  as tag
        FROM jore.route_section_intermediates(date, false, 1000)
    )

UNION ALL
(
    SELECT *,
           true as nearbuses,
           date as tag
    FROM jore.route_section_intermediates(date, true, 200)
);
$$
    language sql;
