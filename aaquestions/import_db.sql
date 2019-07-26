PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS question_likes;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS question_follows;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(20) NOT NULL,
  lname VARCHAR(20) NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(20) NOT NULL,
  body TEXT NOT NULL,
  author_id INT NOT NULL,

  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  user_id INT NOT NULL,
  question_id INT NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  body TEXT NOT NULL,
  question_id INT NOT NULL,
  parent_id INT,
  author_id INT NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_id) REFERENCES replies(id),
  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INT NOT NULL,
  question_id INT NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO users (fname, lname)
VALUES
  ('alex', 'chui'),
  ('kevin', 'moch'),
  ('hanna', 'barbara');

INSERT INTO questions (title, body, author_id)
VALUES
  ('LUNCH', 'Who ate my lunch? I''m coming for you.', 3),
  ('DINNER', 'Who ate my dinner? I will destroy you.', 3);

INSERT INTO question_follows (user_id, question_id)
VALUES
  (1,1),
  (2,1),
  (3,1),
  (3,2);

INSERT INTO replies (body, question_id, parent_id, author_id)
VALUES
  ('Not me', 1, NULL, 1),
  ('It me', 1, 1, 2),
  ('How dare they', 2, NULL, 2);

INSERT INTO question_likes (user_id, question_id)
VALUES
  (1, 1),
  (2, 1),
  (3, 1);