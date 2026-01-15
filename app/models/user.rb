class User < ApplicationRecord
  include ActivityTrackable

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  enum role: { apprenant: 0, formateur: 1, admin: 2 }

  has_many :course_assignments, dependent: :destroy
  has_many :user_activity_logs, dependent: :destroy

  has_many :created_quizzes, class_name: 'Quiz', foreign_key: 'creator_id', dependent: :destroy
  has_many :quiz_attempts, dependent: :destroy
  has_many :assigned_quizzes, -> { where.not(assigned_at: nil) }, through: :quiz_attempts, source: :quiz
  has_many :certificates, dependent: :destroy
  has_many :issued_certificates, class_name: 'Certificate', foreign_key: 'issued_by_id'
  has_many :theme_statistics, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :role, presence: true
  validates :locale, inclusion: { in: %w[fr en es], allow_nil: true }

  after_initialize :set_default_role, if: :new_record?
  after_initialize :set_default_locale, if: :new_record?

  def full_name
    "#{first_name} #{last_name}"
  end
  def initials
    "#{first_name[0]}#{last_name[0]}"
  end

  def admin?
    role == 'admin'
  end

  def formateur?
    role == 'formateur'
  end

  def apprenant?
    role == 'apprenant'
  end

  def self.csv_template
    require 'csv'
    CSV.generate(headers: true, col_sep: ';') do |csv|
      csv << ['email', 'first_name', 'last_name', 'phone', 'session', 'role', 'locale']
      csv << ['exemple@formation.com', 'Jean', 'Dupont', '0123456789', '2024-A', 'apprenant', 'fr']
      csv << ['exemple2@formation.com', 'Marie', 'Martin', '0123456788', '2024-A', 'apprenant', 'fr']
    end
  end

  def self.import_from_csv(file_path)
    require 'csv'
    count = 0
    errors = []
    
    separator = File.open(file_path, &:readline).include?(';') ? ';' : ','
    
    CSV.foreach(file_path, headers: true, col_sep: separator) do |row|
      begin
        user = find_or_initialize_by(email: row['email'])
        user.assign_attributes(
          first_name: row['first_name'] || row['prenom'],
          last_name: row['last_name'] || row['nom'],
          phone: row['phone'] || row['telephone'],
          session: row['session'],
          role: row['role'] || 'apprenant',
          locale: row['locale'] || 'fr'
        )
        
        if user.new_record?
          user.password = row['email']
          user.password_confirmation = row['email']
        end
        
        if user.save
          count += 1
        else
          errors << "Ligne #{$.}: #{user.errors.full_messages.join(', ')}"
        end
      rescue => e
        errors << "Ligne #{$.}: #{e.message}"
      end
    end
    
    { count: count, errors: errors }
  end

  private

  def set_default_role
    self.role ||= :apprenant
  end

  def set_default_locale
    self.locale ||= 'fr'
  end
end
