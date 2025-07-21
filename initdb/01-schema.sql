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

-- здания
CREATE TABLE buildings (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  address    TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- этажи
CREATE TABLE floors (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  level      INT  NOT NULL,
  plan_url   TEXT NOT NULL,
  width_px   INT,
  height_px  INT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- аппаратные камеры
CREATE TABLE camera_hardware (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT   NOT NULL,
  stream_url    TEXT   NOT NULL,
  ptz_enabled   BOOLEAN DEFAULT FALSE,
  ptz_protocol  TEXT,
  username      TEXT,
  password      TEXT,
  created_at    TIMESTAMPTZ DEFAULT now()
);

-- камеры на плане
CREATE TABLE cameras (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  floor_id        UUID NOT NULL REFERENCES floors(id) ON DELETE CASCADE,
  hardware_id     UUID REFERENCES camera_hardware(id),
  x_rel           NUMERIC(6,4) NOT NULL,
  y_rel           NUMERIC(6,4) NOT NULL,
  orientation_deg NUMERIC(5,2) NOT NULL DEFAULT 0,
  fov_deg         NUMERIC(5,2) NOT NULL DEFAULT 90,
  view_range      NUMERIC(8,2) NOT NULL DEFAULT 100,
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- зоны на этаже
CREATE TABLE areas (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  floor_id   UUID NOT NULL REFERENCES floors(id) ON DELETE CASCADE,
  name       TEXT   NOT NULL,
  polygon    JSONB  NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- связь камер и зон
CREATE TABLE camera_areas (
  camera_id UUID NOT NULL REFERENCES cameras(id) ON DELETE CASCADE,
  area_id   UUID NOT NULL REFERENCES areas(id)   ON DELETE CASCADE,
  PRIMARY KEY(camera_id, area_id)
);

-- дашборды
CREATE TABLE dashboards (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  description TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- связь дашбордов и камер
CREATE TABLE dashboard_cameras (
  dashboard_id UUID NOT NULL REFERENCES dashboards(id) ON DELETE CASCADE,
  camera_id    UUID NOT NULL REFERENCES cameras(id)   ON DELETE CASCADE,
  display_order INT DEFAULT 0,
  PRIMARY KEY(dashboard_id, camera_id)
);
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TABLE images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),           -- уникальный идентификатор
  filename VARCHAR(255) NOT NULL,                           -- оригинальное имя файла
  filepath TEXT NOT NULL,                                   -- путь к файлу на диске
  uploaded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()  -- время загрузки
);

-- Индекс на время загрузки (опционально, для ускорения сортировок)
CREATE INDEX idx_images_uploaded_at ON images(uploaded_at DESC);