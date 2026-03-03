-- Quiet Hacker - SQL Preview
CREATE TABLE IF NOT EXISTS users (
    id          SERIAL PRIMARY KEY,
    username    VARCHAR(50) NOT NULL UNIQUE,
    email       VARCHAR(255) NOT NULL,
    status      VARCHAR(20) DEFAULT 'active',
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_email ON users(email);

CREATE TABLE IF NOT EXISTS sessions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token       TEXT NOT NULL,
    ip_address  INET,
    expires_at  TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert sample data
INSERT INTO users (username, email, status) VALUES
    ('neo', 'neo@matrix.io', 'active'),
    ('trinity', 'trinity@matrix.io', 'active'),
    ('morpheus', 'morpheus@zion.net', 'active'),
    ('cypher', 'cypher@matrix.io', 'suspended');

-- Active users with session count
SELECT
    u.id,
    u.username,
    u.email,
    COUNT(s.id) AS session_count,
    MAX(s.created_at) AS last_login
FROM users u
LEFT JOIN sessions s ON s.user_id = u.id
WHERE u.status = 'active'
    AND u.created_at >= NOW() - INTERVAL '90 days'
GROUP BY u.id, u.username, u.email
HAVING COUNT(s.id) > 0
ORDER BY last_login DESC
LIMIT 50;

-- Clean up expired sessions
DELETE FROM sessions
WHERE expires_at < NOW();

-- Aggregate stats
WITH monthly_stats AS (
    SELECT
        DATE_TRUNC('month', created_at) AS month,
        COUNT(*) AS new_users,
        COUNT(*) FILTER (WHERE status = 'active') AS active_users
    FROM users
    GROUP BY DATE_TRUNC('month', created_at)
)
SELECT
    month,
    new_users,
    active_users,
    ROUND(active_users::NUMERIC / NULLIF(new_users, 0) * 100, 1) AS retention_pct
FROM monthly_stats
ORDER BY month DESC;
