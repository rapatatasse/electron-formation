class Question < ApplicationRecord
  belongs_to :quiz
  belongs_to :theme
  has_many :answers, dependent: :destroy
  has_many :attempt_answers, dependent: :destroy

  validates :question_text, presence: true
  validates :difficulty_level, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  accepts_nested_attributes_for :answers, allow_destroy: true, reject_if: :all_blank

  scope :ordered, -> { order(position: :asc) }
  scope :by_difficulty, ->(level) { where(difficulty_level: level) }
  scope :by_theme, ->(theme_id) { where(theme_id: theme_id) }

  def correct_answers
    answers.where(is_correct: true)
  end

  def correct_answer_ids
    correct_answers.pluck(:id)
  end

  def has_multiple_correct_answers?
    correct_answers.count > 1
  end

  # Export CSV pour un quiz spécifique
  def self.export_to_csv(quiz)
    require 'csv'
    CSV.generate(headers: true, col_sep: ';') do |csv|
      # En-têtes
      csv << ['question_text', 'theme_name', 'image_url', 'difficulty_level', 'position', 'multiple_correct_answers', 'randomize_answers', 'answer_1', 'correct_1', 'answer_2', 'correct_2', 'answer_3', 'correct_3', 'answer_4', 'correct_4']
      
      # Questions du quiz
      quiz.questions.includes(:theme, :answers).order(:position).each do |question|
        row = [
          question.question_text,
          question.theme.name,
          question.image_url,
          question.difficulty_level,
          question.position,
          question.multiple_correct_answers? ? 'oui' : 'non',
          question.randomize_answers? ? 'oui' : 'non'
        ]
        
        # Ajouter jusqu'à 4 réponses
        answers = question.answers.to_a
        4.times do |i|
          if answers[i]
            row << answers[i].answer_text
            row << (answers[i].is_correct? ? 'oui' : 'non')
          else
            row << ''
            row << ''
          end
        end
        
        csv << row
      end
    end
  end

  # Template CSV vide
  def self.csv_template
    require 'csv'
    CSV.generate(headers: true, col_sep: ';') do |csv|
      csv << ['question_text', 'theme_name', 'image_url', 'difficulty_level', 'position', 'multiple_correct_answers', 'randomize_answers', 'answer_1', 'correct_1', 'answer_2', 'correct_2', 'answer_3', 'correct_3', 'answer_4', 'correct_4']
      csv << ['Quelle est la tension du réseau domestique en France ?', 'Risque electrique', '', '30', '1', 'non', 'non', '230V', 'oui', '110V', 'non', '400V', 'non', '12V', 'non']
      csv << ['Quels équipements de protection sont obligatoires ?', 'Risque mecanique', '', '50', '2', 'oui', 'non', 'Gants', 'oui', 'Lunettes', 'oui', 'Casquette', 'non', 'Chaussures de sécurité', 'oui']
    end
  end

  # Import CSV
  def self.import_from_csv(quiz, file_path)
    require 'csv'
    count = 0
    errors = []
    
    separator = File.open(file_path, &:readline).include?(';') ? ';' : ','
    
    CSV.foreach(file_path, headers: true, col_sep: separator) do |row|
      begin
        # Trouver le thème
        theme = Theme.find_by(name: row['theme_name'])
        unless theme
          errors << "Ligne #{$.}: Thème '#{row['theme_name']}' introuvable"
          next
        end
        
        # Créer la question
        question = quiz.questions.build(
          question_text: row['question_text'],
          theme: theme,
          image_url: row['image_url'],
          difficulty_level: row['difficulty_level'] || 50,
          position: row['position'] || (quiz.questions.maximum(:position) || 0) + 1,
          multiple_correct_answers: row['multiple_correct_answers']&.downcase == 'oui',
          randomize_answers: row['randomize_answers']&.downcase == 'oui'
        )
        
        # Ajouter les réponses
        4.times do |i|
          answer_text = row["answer_#{i + 1}"]
          next if answer_text.blank?
          
          question.answers.build(
            answer_text: answer_text,
            is_correct: row["correct_#{i + 1}"]&.downcase == 'oui'
          )
        end
        
        if question.save
          count += 1
        else
          errors << "Ligne #{$.}: #{question.errors.full_messages.join(', ')}"
        end
      rescue => e
        errors << "Ligne #{$.}: #{e.message}"
      end
    end
    
    { count: count, errors: errors }
  end
end
