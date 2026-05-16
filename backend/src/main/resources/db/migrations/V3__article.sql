CREATE TABLE IF NOT EXISTS articles (
    id               BIGSERIAL PRIMARY KEY,
    slug             VARCHAR(280) NOT NULL UNIQUE,
    title            VARCHAR(255) NOT NULL,
    description      VARCHAR(1024) NOT NULL,
    body             TEXT NOT NULL,
    author_id        BIGINT NOT NULL,
    favorites_count  INTEGER NOT NULL DEFAULT 0,
    created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT fk_articles_author FOREIGN KEY (author_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_articles_created_at_desc ON articles (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_articles_author_created ON articles (author_id, created_at DESC);
