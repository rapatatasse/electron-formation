class User < ApplicationRecord
  include ActivityTrackable

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  # Rôles disponibles
  ROLES = %w[apprenant formateur admin].freeze

  has_many :course_assignments, dependent: :destroy
  has_many :user_activity_logs, dependent: :destroy
  has_many :user_sessions, dependent: :destroy
  has_many :sessions, through: :user_sessions

  has_many :created_quizzes, class_name: 'Quiz', foreign_key: 'creator_id', dependent: :destroy
  has_many :quiz_attempts, dependent: :destroy
  has_many :assigned_quizzes, -> { where.not(assigned_at: nil) }, through: :quiz_attempts, source: :quiz
  has_many :certificates, dependent: :destroy
  has_many :issued_certificates, class_name: 'Certificate', foreign_key: 'issued_by_id'
  has_many :theme_statistics, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :locale, inclusion: { in: %w[fr en es], allow_nil: true }
  validate :roles_must_be_valid

  # Scopes pour les rôles
  scope :apprenant, -> { where("'apprenant' = ANY(role)") }
  scope :formateur, -> { where("'formateur' = ANY(role)") }
  scope :admin, -> { where("'admin' = ANY(role)") }

  after_initialize :set_default_role, if: :new_record?
  after_initialize :set_default_locale, if: :new_record?

  def full_name
    "#{first_name} #{last_name}"
  end
  def initials
    "#{first_name[0]}#{last_name[0]}"
  end

  def admin?
    roles.include?('admin')
  rescue
    false
  end

  def formateur?
    roles.include?('formateur')
  rescue
    false
  end

  def apprenant?
    roles.include?('apprenant')
  rescue
    false
  end

  def roles
    # Rails désérialise automatiquement le JSON en array
    return ['apprenant'] if role.nil? || role.empty?
    
    # Si c'est une string JSON, on la parse
    current_role = role
    if current_role.is_a?(String)
      begin
        current_role = JSON.parse(current_role)
      rescue JSON::ParserError
        current_role = [current_role]
      end
    end
    Array(current_role).compact.presence || ['apprenant']
  end

  def roles=(new_roles)
    self.role = Array(new_roles).compact.uniq
  end

  def add_role(new_role)
    return unless ROLES.include?(new_role)
    self.role = (roles + [new_role]).uniq
    save
  end

  def remove_role(old_role)
    self.role = roles - [old_role]
    save
  end

  def has_role?(role_name)
    roles.include?(role_name.to_s)
  end

  def primary_role
    roles.first || 'apprenant'
  end

  def self.csv_template
    require 'csv'
    CSV.generate(headers: true, col_sep: ';') do |csv|
      csv << ['email', 'first_name', 'last_name', 'phone', 'sessions', 'roles', 'locale']
      csv << ['exemple@formation.com', 'Jean', 'Dupont', '0123456789', '2024-A', 'apprenant', 'fr']
      csv << ['exemple2@formation.com', 'Marie', 'Martin', '0123456788', '2024-A,2024-B', 'apprenant,formateur', 'fr']
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
        
        # Gérer les rôles (peut être une liste séparée par des virgules)
        roles_str = row['roles'] || row['role'] || 'apprenant'
        user_roles = roles_str.split(',').map(&:strip).select { |r| ROLES.include?(r) }
        user_roles = ['apprenant'] if user_roles.empty?
        
        user.assign_attributes(
          first_name: row['first_name'] || row['prenom'],
          last_name: row['last_name'] || row['nom'],
          phone: row['phone'] || row['telephone'],
          role: user_roles,
          locale: row['locale'] || 'fr'
        )
        
        if user.new_record?
          user.password = row['email']
          user.password_confirmation = row['email']
        end
        
        if user.save
          # Gérer les sessions (peut être une liste séparée par des virgules)
          if row['sessions'] || row['session']
            session_names = (row['sessions'] || row['session']).split(',').map(&:strip)
            session_names.each do |session_name|
              session = Session.find_or_create_by!(name: session_name)
              UserSession.find_or_create_by!(user: user, session: session)
            end
          end
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
    self.role = ['apprenant'] if role.blank? || role.empty?
  end

  def set_default_locale
    self.locale ||= 'fr'
  end

  def roles_must_be_valid
    return if role.blank?
    
    current_roles = roles
    invalid_roles = current_roles - ROLES
    if invalid_roles.any?
      errors.add(:role, "contient des rôles invalides: #{invalid_roles.join(', ')}")
    end
    
    if current_roles.empty?
      errors.add(:role, "doit contenir au moins un rôle")
    end
  end
end
