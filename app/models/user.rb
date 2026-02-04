class User < ApplicationRecord
  include ActivityTrackable

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  # Rôles disponibles
  ROLES = %w[formateur bureau admin].freeze


  has_many :user_activity_logs, dependent: :destroy
  has_many :created_projects, class_name: 'Project', foreign_key: :creator_id, dependent: :destroy
  has_many :task_users, dependent: :destroy
  has_many :tasks, through: :task_users

 
  validates :email, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :locale, inclusion: { in: %w[fr en es], allow_nil: true }
  validate :roles_must_be_valid

  # Scopes pour les rôles
  scope :formateur, -> { where("role::jsonb ? :role", role: 'formateur') }
  scope :bureau, -> { where("role::jsonb ? :role", role: 'bureau') }
  scope :admin, -> { where("role::jsonb ? :role", role: 'admin') }

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

  

  def bureau?
    roles.include?('bureau')
  rescue
    false
  end

  def roles
    return [] if role.nil? || role.empty?

    current_role = role
    if current_role.is_a?(String)
      begin
        current_role = JSON.parse(current_role)
      rescue JSON::ParserError
        current_role = [current_role]
      end
    end
    Array(current_role).compact
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
    roles.first
  end

  def self.csv_template
    require 'csv'
    CSV.generate(headers: true, col_sep: ';') do |csv|
      csv << ['email', 'first_name', 'last_name', 'phone', 'roles', 'locale']
      csv << ['exemple@formation.com', 'Jean', 'Dupont', '0123456789', 'formateur', 'fr']
      csv << ['exemple2@formation.com', 'Marie', 'Martin', '0123456788', 'bureau', 'fr']
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
        roles_str = row['roles'] || row['role'] || ''
        user_roles = roles_str.split(',').map(&:strip).select { |r| ROLES.include?(r) }
        user_roles = [] if user_roles.empty?
        
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
    self.role = [] if role.blank?
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
