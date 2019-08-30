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
    nearbuses boolean
);

-- Creating empty table to keep postgres happy
CREATE TABLE IF NOT EXISTS jorestatic.status
(
    name        varchar(128),
    target_date date,
    status      text,
    created_at  timestamp with time zone default CURRENT_TIMESTAMP,
    updated_at  timestamp with time zone default CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION jorestatic.run_intermediate_points(date date) RETURNS VOID AS
$$
BEGIN
    INSERT INTO jorestatic.status (target_date, status, name)
    SELECT '2019-08-30', 'EMPTY', 'config'
    WHERE NOT EXISTS(SELECT * FROM jorestatic.status);

    UPDATE jorestatic.status status
    SET status      = 'PENDING',
        target_date = date,
        updated_at  = NOW()
    WHERE status.name = 'config'
      AND status.status != 'PENDING';
END
$$ language plpgsql volatile;

CREATE OR REPLACE FUNCTION jorestatic.create_intermediate_points() RETURNS trigger AS
$$
BEGIN
    TRUNCATE jorestatic.intermediate_points;

    INSERT INTO jorestatic.intermediate_points
        (
            SELECT *,
                   false as nearBuses
            FROM jore.route_section_intermediates(NEW.target_date, false, 1000)
        )

    UNION ALL
    (
        SELECT *,
               true as nearBuses
        FROM jore.route_section_intermediates(NEW.target_date, true, 200)
    );

    RETURN NEW;
END
$$ language plpgsql;

DO
$$
    BEGIN
        CREATE TRIGGER on_status_change_to_pending
            AFTER UPDATE OF status
            ON jorestatic.status
            FOR EACH ROW
            WHEN (NEW.status = 'PENDING')
        EXECUTE FUNCTION jorestatic.create_intermediate_points();
    EXCEPTION
        WHEN duplicate_object THEN null;
    END
$$;

CREATE OR REPLACE FUNCTION jorestatic.after_intermediate_points() RETURNS trigger AS
$$
BEGIN
    UPDATE jorestatic.status status
    SET status = 'READY'
    WHERE status.name = 'config';

    RETURN jorestatic.status.status;
END
$$ language plpgsql volatile;

DO
$$
    BEGIN
        CREATE TRIGGER on_intermediate_points_ready
            AFTER UPDATE
            ON jorestatic.intermediate_points
            FOR STATEMENT
        EXECUTE FUNCTION jorestatic.after_intermediate_points();
    EXCEPTION
        WHEN duplicate_object THEN null;
    END
$$;
