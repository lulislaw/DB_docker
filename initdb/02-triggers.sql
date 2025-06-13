CREATE OR REPLACE FUNCTION log_appeal_creation()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO appeal_history (
    id,
    appeal_id,
    event_time,
    event_type,
    changed_by_id,
    field_name,
    old_value,
    new_value,
    comment,
    metadata
  )
  VALUES (
    gen_random_uuid(),
    NEW.id,
    NOW(),
    'create',
    NULLIF(current_setting('app.current_user_id', true), '')::UUID,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_appeals_after_insert
  AFTER INSERT ON appeals
  FOR EACH ROW
  EXECUTE FUNCTION log_appeal_creation();


CREATE OR REPLACE FUNCTION log_appeal_update()
RETURNS TRIGGER AS $$
DECLARE
  changes    JSONB := '{}'::JSONB;
  old_text   TEXT;
  new_text   TEXT;
  event_code TEXT := 'update';
BEGIN

  IF NEW.is_deleted IS TRUE AND OLD.is_deleted IS FALSE THEN
    event_code := 'soft_delete';
    changes := changes || jsonb_build_object(
      'is_deleted', jsonb_build_array(OLD.is_deleted, NEW.is_deleted)
    );
  END IF;


  IF NEW.type_id IS DISTINCT FROM OLD.type_id THEN
    SELECT code INTO old_text FROM appeal_types WHERE id = OLD.type_id;
    SELECT code INTO new_text FROM appeal_types WHERE id = NEW.type_id;
    changes := changes || jsonb_build_object('type_id', jsonb_build_array(old_text, new_text));
  END IF;

  IF NEW.severity_id IS DISTINCT FROM OLD.severity_id THEN
    SELECT code INTO old_text FROM severity_levels WHERE id = OLD.severity_id;
    SELECT code INTO new_text FROM severity_levels WHERE id = NEW.severity_id;
    changes := changes || jsonb_build_object('severity_id', jsonb_build_array(old_text, new_text));
  END IF;

  IF NEW.status_id IS DISTINCT FROM OLD.status_id THEN
    SELECT code INTO old_text FROM appeal_statuses WHERE id = OLD.status_id;
    SELECT code INTO new_text FROM appeal_statuses WHERE id = NEW.status_id;
    changes := changes || jsonb_build_object('status_id', jsonb_build_array(old_text, new_text));
  END IF;

  IF NEW.location IS DISTINCT FROM OLD.location THEN
    changes := changes || jsonb_build_object('location', jsonb_build_array(OLD.location, NEW.location));
  END IF;

  IF NEW.description IS DISTINCT FROM OLD.description THEN
    changes := changes || jsonb_build_object('description', jsonb_build_array(OLD.description, NEW.description));
  END IF;

  IF NEW.reporter_id IS DISTINCT FROM OLD.reporter_id THEN
    IF OLD.reporter_id IS NOT NULL THEN SELECT username INTO old_text FROM users WHERE id = OLD.reporter_id; ELSE old_text := NULL; END IF;
    IF NEW.reporter_id IS NOT NULL THEN SELECT username INTO new_text FROM users WHERE id = NEW.reporter_id; ELSE new_text := NULL; END IF;
    changes := changes || jsonb_build_object('reporter_id', jsonb_build_array(old_text, new_text));
  END IF;

  IF NEW.source IS DISTINCT FROM OLD.source THEN
    changes := changes || jsonb_build_object('source', jsonb_build_array(OLD.source, NEW.source));
  END IF;

  IF NEW.assigned_to_id IS DISTINCT FROM OLD.assigned_to_id THEN
    IF OLD.assigned_to_id IS NOT NULL THEN SELECT username INTO old_text FROM users WHERE id = OLD.assigned_to_id; ELSE old_text := NULL; END IF;
    IF NEW.assigned_to_id IS NOT NULL THEN SELECT username INTO new_text FROM users WHERE id = NEW.assigned_to_id; ELSE new_text := NULL; END IF;
    changes := changes || jsonb_build_object('assigned_to_id', jsonb_build_array(old_text, new_text));
  END IF;

  IF NEW.metadata IS DISTINCT FROM OLD.metadata THEN
    changes := changes || jsonb_build_object('metadata', jsonb_build_array(OLD.metadata, NEW.metadata));
  END IF;


  IF changes = '{}'::JSONB THEN
    RETURN NEW;
  END IF;


  INSERT INTO appeal_history (
    id,
    appeal_id,
    event_time,
    event_type,
    changed_by_id,
    field_name,
    old_value,
    new_value,
    comment,
    metadata
  )
  VALUES (
    gen_random_uuid(),
    NEW.id,
    NOW(),
    event_code,
    NULLIF(current_setting('app.current_user_id', true), '')::UUID,
    NULL,
    NULL,
    NULL,
    NULL,
    changes
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_appeals_after_update ON appeals;
CREATE TRIGGER trg_appeals_after_update
  AFTER UPDATE ON appeals
  FOR EACH ROW
  EXECUTE FUNCTION log_appeal_update();
