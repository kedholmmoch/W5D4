require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class Question
  attr_accessor :id, :title, :body, :author_id

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      questions
    WHERE
      id = ?
    SQL
    Question.new(question.first)
  end

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

  def self.find_by_title(title)
    question = QuestionsDatabase.instance.execute(<<-SQL, title)
    SELECT
      questions.*
    FROM
      questions
    WHERE
      title = ?
    SQL
    Question.new(question.first)
  end

  def self.find_by_author_id(author_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, author_id)
    SELECT
      *
    FROM
      questions
    WHERE
      questions.author_id = ?
    SQL
    questions.map {|q| Question.new(q)}
  end

  def self.find_by_name(fname, lname)
    questions = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        questions.*
      FROM
        questions
      JOIN 
        users ON questions.author_id=users.id
      WHERE
        users.fname = ?
      AND
        users.lname = ?
    SQL

    questions.map { |qu| Question.new(qu) }
  end

  def author
    User.find_by_id(@author_id)
  end

  def replies
    Reply.find_by_question_id(@id)
  end

  def followers
    QuestionFollows.followers_for_question_id(@id)
  end

  def self.most_followed_questions(n)
    QuestionFollows.most_followed_questions(n)
  end

end

class User
  attr_accessor :id, :fname, :lname
  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def self.find_by_id(id)
    user = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      users
    WHERE
      id = ?
    SQL
    User.new(user.first)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def self.find_by_name(fname, lname)
    name = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT 
        *
      FROM
        users
      WHERE
        fname = ?
      AND
        lname = ?
    SQL

    User.new(*name)
  end

  def authored_questions
    questions = QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
      SELECT
        questions.*
      FROM
        questions
      JOIN 
        users ON questions.author_id=users.id
      WHERE
        users.fname = ?
      AND
        users.lname = ?
    SQL

    questions.map { |qu| Question.new(qu) }
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def followed_questions
    QuestionFollows.followed_questions_for_user_id(@id)
  end
end

class QuestionFollows
  attr_accessor :id, :user_id, :question_id
  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def self.find_by_id(id)
    follows = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      question_follows
    WHERE
      id = ?
    SQL
    QuestionFollows.new(*follows)
  end

  def self.find_by_question(question_title)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_title)
      SELECT
        users.*
      FROM
        users
      JOIN
        question_follows
        ON question_follows.user_id = users.id
      JOIN
        questions
        ON question_follows.question_id = questions.id
      WHERE
        questions.title = ?
    SQL
    users.map { |user| User.new(user) }
  end

  def self.followers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      users.*
    FROM
      users
    JOIN
      question_follows ON question_follows.user_id = users.id
    WHERE
      question_follows.question_id = ?
    SQL
    users.map {|u| User.new(u)}
  end

  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM
        questions
      JOIN
        question_follows ON question_follows.question_id = questions.id
      WHERE
        question_follows.user_id = ?
    SQL
    questions.map {|q| Question.new(q)}
  end

  def self.most_followed_questions(n)
    followed = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT
      questions.*, COUNT(*) AS counter
    FROM
      questions
    JOIN
      question_follows ON question_follows.question_id = questions.id
    GROUP BY
      questions.id
    ORDER BY
      COUNT(question_follows.user_id) DESC
    LIMIT ?
    SQL
    [followed.map {|f| Question.new(f)}, followed.first['counter']]
  end
end

class Reply
  attr_accessor :id, :body, :question_id, :parent_id, :author_id

  def initialize(options)
    @id = options['id']
    @body = options['body']
    @question_id = options['question_id']
    @parent_id = options['parent_id']
    @author_id = options['author_id']
  end

  def self.find_by_id(id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      replies
    WHERE
      id = ?
    SQL
    Reply.new(*reply)
  end

  def self.find_by_user_id(id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        replies.author_id = ?
    SQL
    replies.map { |r| Reply.new(r) }
  end

  def self.find_by_question_id(id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL

    replies.map { |r| Reply.new(r)}
  end

  def author
    User.find_by_id(author_id)
  end
  
  def question
    Question.find_by_id(question_id)
  end

  def parent_reply
    @parent_id ? Reply.find_by_id(@parent_id) : nil
  end

  def child_replies
    children = QuestionsDatabase.instance.execute(<<-SQL, @id)
    SELECT
      *
    FROM
      replies
    WHERE
      replies.parent_id = ?
    SQL
    children.map {|child| Reply.new(child)}
  end
end

class QuestionLike
  attr_accessor :id, :user_id, :question_id

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def self.find_by_id(id)
    likes = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      question_likes
    WHERE
      id = ?
    SQL
    QuestionLike.new(*likes)
  end

  def self.likers_for_question_id(question_id)
    likers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      users.*
    FROM
      users
    JOIN
      question_likes ON question_likes.user_id = users.id
    WHERE
      question_likes.question_id = ?
    SQL
    likers.map {|l| User.new(l)}
  end

  def self.num_likes_for_question_id(id)
    likes = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      COUNT(*)
    FROM
      question_likes
    WHERE
      question_likes.question_id = ?
    GROUP BY
      question_likes.question_id
    SQL
    likes.first['COUNT(*)']
  end

  def self.liked_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM
        questions
      JOIN
        question_likes ON question_likes.question_id = questions.id
      WHERE
        question_likes.user_id = ?
    SQL
    questions.map {|q| Question.new(q)}
  end

  def 
end