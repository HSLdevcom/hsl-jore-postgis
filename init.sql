create schema if not exists jorestatic;
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
