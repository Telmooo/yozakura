-- Yozakura - SQL example
-- These files are all gibberish, do not attempt to run them

--  DDL: Create Tables
CREATE SCHEMA IF NOT EXISTS app;

CREATE TYPE app.user_status AS ENUM ('pending', 'active', 'inactive', 'banned');
CREATE TYPE app.permission  AS ENUM ('read', 'write', 'admin');

CREATE TABLE IF NOT EXISTS app.users (
    id          UUID         NOT NULL DEFAULT gen_random_uuid(),
    username    VARCHAR(50)  NOT NULL,
    email       VARCHAR(255) NOT NULL,
    password    TEXT         NOT NULL,
    status      app.user_status NOT NULL DEFAULT 'pending',
    age         SMALLINT     CHECK (age >= 13 AND age <= 150),
    score       DECIMAL(10, 2) DEFAULT 0.00,
    metadata    JSONB        DEFAULT '{}',
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ,

    CONSTRAINT users_pkey        PRIMARY KEY (id),
    CONSTRAINT users_email_uniq  UNIQUE (email),
    CONSTRAINT users_name_uniq   UNIQUE (username)
);

CREATE TABLE IF NOT EXISTS app.posts (
    id          BIGSERIAL    PRIMARY KEY,
    user_id     UUID         NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
    title       TEXT         NOT NULL,
    slug        VARCHAR(255) NOT NULL,
    body        TEXT,
    published   BOOLEAN      NOT NULL DEFAULT FALSE,
    view_count  INTEGER      NOT NULL DEFAULT 0,
    tags        TEXT[]       DEFAULT '{}',
    published_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT posts_slug_uniq   UNIQUE (slug),
    CONSTRAINT posts_title_len   CHECK (char_length(title) BETWEEN 3 AND 200)
);

CREATE TABLE IF NOT EXISTS app.comments (
    id          BIGSERIAL PRIMARY KEY,
    post_id     BIGINT    NOT NULL REFERENCES app.posts(id) ON DELETE CASCADE,
    user_id     UUID      NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
    parent_id   BIGINT    REFERENCES app.comments(id) ON DELETE SET NULL,
    body        TEXT      NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app.tags (
    id   SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS app.post_tags (
    post_id BIGINT  NOT NULL REFERENCES app.posts(id) ON DELETE CASCADE,
    tag_id  INTEGER NOT NULL REFERENCES app.tags(id)  ON DELETE CASCADE,
    PRIMARY KEY (post_id, tag_id)
);

--  Indexes
CREATE INDEX IF NOT EXISTS idx_users_email      ON app.users (email);
CREATE INDEX IF NOT EXISTS idx_users_status     ON app.users (status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_posts_user       ON app.posts (user_id);
CREATE INDEX IF NOT EXISTS idx_posts_published  ON app.posts (published_at DESC) WHERE published = TRUE;
CREATE INDEX IF NOT EXISTS idx_posts_tags_gin   ON app.posts USING GIN (tags);
CREATE INDEX IF NOT EXISTS idx_posts_metadata   ON app.users USING GIN (metadata jsonb_path_ops);

--  Views
CREATE OR REPLACE VIEW app.active_users AS
    SELECT id, username, email, score, created_at
    FROM app.users
    WHERE status = 'active'
      AND deleted_at IS NULL
    ORDER BY score DESC;

CREATE OR REPLACE VIEW app.post_summary AS
    SELECT
        p.id,
        p.title,
        p.slug,
        p.view_count,
        p.published_at,
        u.username   AS author,
        COUNT(c.id)  AS comment_count,
        p.tags
    FROM app.posts p
    JOIN app.users u ON u.id = p.user_id
    LEFT JOIN app.comments c ON c.post_id = p.id
    WHERE p.published = TRUE
    GROUP BY p.id, u.username;

--  DML: Insert
INSERT INTO app.users (username, email, password, status, age, score)
VALUES
    ('alice',   'alice@example.com',   'hash_alice',   'active',   28, 95.5),
    ('bob',     'bob@example.com',     'hash_bob',     'active',   34, 72.0),
    ('charlie', 'charlie@example.com', 'hash_charlie', 'inactive', 22, 10.0),
    ('diana',   'diana@example.com',   'hash_diana',   'pending',  19, 0.0)
ON CONFLICT (email) DO UPDATE
    SET username   = EXCLUDED.username,
        updated_at = NOW();

INSERT INTO app.posts (user_id, title, slug, body, published, published_at, tags)
SELECT
    id,
    'Introduction to ' || username,
    'intro-' || username,
    'Welcome to my blog about ' || username || '!',
    TRUE,
    NOW() - (random() * INTERVAL '365 days'),
    ARRAY['intro', 'welcome']
FROM app.users
WHERE status = 'active'
ON CONFLICT DO NOTHING;

--  DML: Update
UPDATE app.users
SET
    status     = 'active',
    updated_at = NOW()
WHERE status = 'pending'
  AND created_at < NOW() - INTERVAL '7 days'
RETURNING id, username, status;

--  Queries: SELECT with JOINs
-- Basic join
SELECT
    u.username,
    u.email,
    u.score,
    COUNT(p.id)   AS post_count,
    SUM(p.view_count) AS total_views
FROM app.users u
LEFT JOIN app.posts p
    ON p.user_id = u.id
    AND p.published = TRUE
WHERE u.status = 'active'
  AND u.deleted_at IS NULL
GROUP BY u.id, u.username, u.email, u.score
HAVING COUNT(p.id) > 0
ORDER BY total_views DESC NULLS LAST, u.username ASC
LIMIT 10 OFFSET 0;

-- Multi-table join
SELECT
    p.title,
    p.slug,
    u.username   AS author,
    t.name       AS tag,
    c.body       AS latest_comment,
    c.created_at AS comment_date
FROM app.posts p
JOIN app.users        u  ON u.id      = p.user_id
JOIN app.post_tags    pt ON pt.post_id = p.id
JOIN app.tags         t  ON t.id      = pt.tag_id
LEFT JOIN LATERAL (
    SELECT body, created_at
    FROM app.comments
    WHERE post_id = p.id
    ORDER BY created_at DESC
    LIMIT 1
) c ON TRUE
WHERE p.published = TRUE
  AND t.name = ANY(ARRAY['intro', 'tutorial'])
ORDER BY p.published_at DESC;

--  CTEs (Common Table Expressions)
WITH
-- Step 1: Active users with post counts
user_stats AS (
    SELECT
        u.id,
        u.username,
        u.score,
        COUNT(p.id)       AS post_count,
        SUM(p.view_count) AS total_views,
        MAX(p.published_at) AS last_published
    FROM app.users u
    LEFT JOIN app.posts p ON p.user_id = u.id AND p.published = TRUE
    WHERE u.status = 'active'
    GROUP BY u.id, u.username, u.score
),
-- Step 2: Rank users
ranked_users AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_views DESC NULLS LAST) AS view_rank,
        NTILE(4) OVER (ORDER BY score DESC) AS score_quartile
    FROM user_stats
),
-- Step 3: Top authors only
top_authors AS (
    SELECT * FROM ranked_users WHERE view_rank <= 5
)
SELECT
    username,
    post_count,
    total_views,
    score,
    view_rank,
    CASE score_quartile
        WHEN 1 THEN 'Top 25%'
        WHEN 2 THEN 'Upper-mid'
        WHEN 3 THEN 'Lower-mid'
        WHEN 4 THEN 'Bottom 25%'
    END AS score_tier
FROM top_authors
ORDER BY view_rank;

--  Recursive CTE
WITH RECURSIVE comment_tree AS (
    -- Base: top-level comments
    SELECT
        id,
        post_id,
        parent_id,
        body,
        0 AS depth,
        ARRAY[id] AS path
    FROM app.comments
    WHERE parent_id IS NULL

    UNION ALL

    -- Recursive: replies
    SELECT
        c.id,
        c.post_id,
        c.parent_id,
        c.body,
        ct.depth + 1,
        ct.path || c.id
    FROM app.comments c
    JOIN comment_tree ct ON ct.id = c.parent_id
    WHERE ct.depth < 5  -- prevent infinite recursion
)
SELECT
    REPEAT('  ', depth) || body AS indented_body,
    depth,
    path
FROM comment_tree
WHERE post_id = 1
ORDER BY path;

--  Window Functions
SELECT
    username,
    score,
    post_count,
    -- Ranking functions
    ROW_NUMBER() OVER w                              AS row_num,
    RANK()       OVER w                              AS rank,
    DENSE_RANK() OVER w                              AS dense_rank,
    PERCENT_RANK() OVER w                            AS pct_rank,
    NTILE(3)     OVER w                              AS tertile,
    -- Value functions
    LAG(score, 1, 0)  OVER (ORDER BY score DESC)    AS prev_score,
    LEAD(score, 1, 0) OVER (ORDER BY score DESC)    AS next_score,
    FIRST_VALUE(username) OVER w                     AS top_user,
    LAST_VALUE(username)  OVER (
        PARTITION BY status ORDER BY score DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                                AS bottom_user,
    -- Aggregate window functions
    SUM(score)   OVER (ORDER BY score DESC ROWS UNBOUNDED PRECEDING) AS running_sum,
    AVG(score)   OVER (ORDER BY score DESC ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg
FROM (
    SELECT u.username, u.status, u.score, COUNT(p.id) AS post_count
    FROM app.users u
    LEFT JOIN app.posts p ON p.user_id = u.id
    WHERE u.status = 'active'
    GROUP BY u.id, u.username, u.status, u.score
) sub
WINDOW w AS (PARTITION BY status ORDER BY score DESC);

--  Stored Procedure
CREATE OR REPLACE PROCEDURE app.activate_pending_users(
    p_days_old INTEGER DEFAULT 7,
    OUT p_count INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_cursor CURSOR FOR
        SELECT id, username
        FROM app.users
        WHERE status = 'pending'
          AND created_at < NOW() - (p_days_old || ' days')::INTERVAL;
    v_user RECORD;
BEGIN
    p_count := 0;

    OPEN v_cursor;
    LOOP
        FETCH v_cursor INTO v_user;
        EXIT WHEN NOT FOUND;

        UPDATE app.users
        SET status = 'active', updated_at = NOW()
        WHERE id = v_user.id;

        p_count := p_count + 1;
        RAISE NOTICE 'Activated user: % (%)', v_user.username, v_user.id;
    END LOOP;
    CLOSE v_cursor;

    COMMIT;
    RAISE NOTICE 'Activated % users', p_count;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
$$;

--  Function
CREATE OR REPLACE FUNCTION app.get_user_rank(p_user_id UUID)
RETURNS TABLE (
    username  TEXT,
    score     DECIMAL,
    rank      BIGINT,
    percentile NUMERIC
)
LANGUAGE sql
STABLE
AS $$
    WITH ranked AS (
        SELECT
            id,
            username,
            score,
            RANK() OVER (ORDER BY score DESC) AS rank,
            ROUND(
                PERCENT_RANK() OVER (ORDER BY score) * 100,
                1
            ) AS percentile
        FROM app.users
        WHERE status = 'active' AND deleted_at IS NULL
    )
    SELECT username, score, rank, percentile
    FROM ranked
    WHERE id = p_user_id;
$$;

--  Transactions
BEGIN;

    SAVEPOINT before_post;

    INSERT INTO app.posts (user_id, title, slug, body, published)
    SELECT id, 'Transaction Test', 'transaction-test', 'Testing transactions', TRUE
    FROM app.users WHERE username = 'alice';

    -- Simulate conditional rollback
    DO $$
    BEGIN
        IF (SELECT COUNT(*) FROM app.posts WHERE slug = 'transaction-test') > 1 THEN
            RAISE EXCEPTION 'Duplicate post detected';
        END IF;
    END $$;

    RELEASE SAVEPOINT before_post;

COMMIT;

--  JSONB Operations
UPDATE app.users
SET metadata = metadata || '{"theme": "yozakura", "version": 1}'::jsonb
WHERE status = 'active';

SELECT
    username,
    metadata->>'theme'                  AS theme,
    (metadata->>'version')::int         AS version,
    metadata #>> '{preferences,lang}'   AS lang,
    jsonb_array_length(metadata->'tags') AS tag_count
FROM app.users
WHERE metadata @> '{"theme": "yozakura"}'
  AND metadata ? 'version';

--  Cleanup
-- Soft delete
UPDATE app.users
SET deleted_at = NOW()
WHERE status = 'banned';

-- Hard delete old soft-deleted records
DELETE FROM app.users
WHERE deleted_at < NOW() - INTERVAL '90 days'
RETURNING id, username;
