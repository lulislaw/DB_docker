INSERT INTO appeal_types (code, name, description, sort_order) VALUES
  ('GENERAL',   'Общее',                'Любые случаи общего характера',           10),
  ('ACCIDENT',  'Авария',               'Требует незамедлительного реагирования', 20),
  ('COMPLAINT', 'Жалоба',               'Нарушение правил или неудовлетворённость', 30),
  ('SERVICE',   'Сервисное обслуживание','Плановые работы и осмотры',             40);

INSERT INTO severity_levels (code, name, priority, description, sort_order) VALUES
  ('LOW',      'Низкая',       1, 'Маловажный инцидент',                               10),
  ('MEDIUM',   'Средняя',      2, 'Средней важности; требуется проверка в ближайшее время', 20),
  ('HIGH',     'Высокая',      3, 'Срочное реагирование требуется',                      30),
  ('CRITICAL', 'Критическая',  4, 'Немедленное реагирование — угроза жизни/имуществу',   40);

INSERT INTO appeal_statuses (code, name, sort_order) VALUES
  ('NEW',         'Новое',        10),
  ('IN_PROGRESS', 'В работе',     20),
  ('RESOLVED',    'Решено',       30),
  ('CLOSED',      'Закрыто',      40);

-- 4) Пример пользователей
INSERT INTO users (username, full_name, role, email, phone) VALUES
  ('admin',   'admin',   'admin', 'admin@admin.com',   '79001234567');



