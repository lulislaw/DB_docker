CREATE EXTENSION IF NOT EXISTS "pgcrypto";


CREATE TABLE appeal_types (
  id          SERIAL PRIMARY KEY,
  code        VARCHAR(50) NOT NULL UNIQUE,
  name        VARCHAR(255) NOT NULL,
  description TEXT,
  sort_order  INTEGER DEFAULT 0
);

CREATE TABLE severity_levels (
  id          SERIAL PRIMARY KEY,
  code        VARCHAR(20) NOT NULL UNIQUE,
  name        VARCHAR(100) NOT NULL,
  priority    INTEGER NOT NULL,
  description TEXT,
  sort_order  INTEGER DEFAULT 0
);

CREATE TABLE appeal_statuses (
  id          SERIAL PRIMARY KEY,
  code        VARCHAR(20) NOT NULL UNIQUE,
  name        VARCHAR(100) NOT NULL,
  sort_order  INTEGER DEFAULT 0
);


CREATE TABLE users (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username     VARCHAR(100) NOT NULL UNIQUE,
  full_name    VARCHAR(200),
  role         VARCHAR(50) NOT NULL,
  email        VARCHAR(255) UNIQUE,
  phone        VARCHAR(50),
  created_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION users_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION users_update_timestamp();


CREATE TABLE appeals (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  type_id        INTEGER NOT NULL REFERENCES appeal_types(id) ON DELETE RESTRICT,
  severity_id    INTEGER NOT NULL REFERENCES severity_levels(id) ON DELETE RESTRICT,
  status_id      INTEGER NOT NULL REFERENCES appeal_statuses(id) ON DELETE RESTRICT
                   DEFAULT 1,

  location       VARCHAR(255),
  description    TEXT,
  reporter_id    UUID REFERENCES users(id) ON DELETE SET NULL,
  source         VARCHAR(50) NOT NULL,

  assigned_to_id UUID REFERENCES users(id) ON DELETE SET NULL,
  metadata       JSONB,

  is_deleted     BOOLEAN NOT NULL DEFAULT FALSE,

  CONSTRAINT chk_source_nonempty CHECK (source <> '')
);

CREATE OR REPLACE FUNCTION appeals_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_appeals_updated
  BEFORE UPDATE ON appeals
  FOR EACH ROW
  EXECUTE FUNCTION appeals_update_timestamp();

CREATE INDEX idx_appeals_created_at ON appeals(created_at DESC);
CREATE INDEX idx_appeals_type       ON appeals(type_id);
CREATE INDEX idx_appeals_severity   ON appeals(severity_id);
CREATE INDEX idx_appeals_status     ON appeals(status_id);
CREATE INDEX idx_appeals_assigned   ON appeals(assigned_to_id);
CREATE INDEX idx_appeals_not_deleted ON appeals (id) WHERE is_deleted = FALSE;


CREATE TABLE appeal_history (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appeal_id      UUID REFERENCES appeals(id) ON DELETE NO ACTION,
  event_time     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  event_type     VARCHAR(50) NOT NULL,
  changed_by_id  UUID REFERENCES users(id) ON DELETE SET NULL,
  field_name     VARCHAR(100),
  old_value      TEXT,
  new_value      TEXT,
  comment        TEXT,
  metadata       JSONB
);

CREATE INDEX idx_history_appeal_time ON appeal_history(appeal_id, event_time DESC);
CREATE INDEX idx_history_event_type ON appeal_history(event_type);


CREATE TABLE attachments (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appeal_id      UUID NOT NULL REFERENCES appeals(id) ON DELETE CASCADE,
  uploaded_by_id UUID REFERENCES users(id) ON DELETE SET NULL,
  file_path      VARCHAR(1024) NOT NULL,
  file_name      VARCHAR(255),
  file_size      BIGINT,
  content_type   VARCHAR(100),
  uploaded_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  metadata       JSONB
);

CREATE INDEX idx_attachments_appeal ON attachments(appeal_id);

alter table users add tg_id bigint;