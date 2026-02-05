class Training < ApplicationRecord
  validates :title, presence: true
  validates :duration, presence: true
  validates :description, presence: true
  has_rich_text :program
  scope :published, -> { where(published: true) }
  scope :ordered_by_priority, -> { order(priority: :desc, created_at: :desc) }
  
  def price_intra_formatted
    price_intra_ht ? "#{price_intra_ht.round(2)} €" : "Sur devis"
  end
  
  def price_inter_formatted
    price_inter_ht ? "#{price_inter_ht.round(2)} €" : "Sur devis"
  end
  
  # Export Excel (.xlsx)
  def self.export_to_excel
    require 'roo'
    require 'tempfile'
    
    # Créer un fichier temporaire
    temp_file = Tempfile.new(['formations', '.xlsx'])
    
    # Utiliser RubyXL pour créer le fichier Excel
    require 'rubyXL'
    workbook = RubyXL::Workbook.new
    worksheet = workbook[0]
    worksheet.sheet_name = 'Formations'
    
    # En-têtes
    headers = ['Title', 'Price Intra HT', 'Price Inter HT/ Stagiaire', 'Type', 'Image', 'Duree', 'Description', 'Objectif', 'Programme', 'Public', 'Méthodes pédagogiques', 'Prérequis', 'priorite', 'Mode Evaluation']
    headers.each_with_index do |header, col|
      worksheet.add_cell(0, col, header)
      worksheet.sheet_data[0][col].change_font_bold(true)
    end
    
    # Données
    all.each_with_index do |training, row_index|
      row = row_index + 1
      data = [
        training.title,
        training.price_intra_ht,
        training.price_inter_ht,
        training.training_type,
        training.image_url,
        training.duration,
        training.description,
        training.objective,
        training.program,
        training.target_audience,
        training.teaching_methods,
        training.prerequisites,
        training.priority,
        training.evaluation_method
      ]
      
      data.each_with_index do |value, col|
        cell = worksheet.add_cell(row, col, value)
        # Activer le retour à la ligne pour les colonnes de texte long
        if [6, 7, 8, 9, 10, 11, 13].include?(col) # Description, Objectif, Programme, etc.
          cell.change_text_wrap(true)
        end
      end
    end
    
    # Ajuster la largeur des colonnes
    worksheet.change_column_width(0, 30)  # Title
    worksheet.change_column_width(6, 50)  # Description
    worksheet.change_column_width(7, 50)  # Objectif
    worksheet.change_column_width(8, 50)  # Programme
    
    workbook.write(temp_file.path)
    temp_file.read
  end
  
  # Export CSV (conservé pour compatibilité)
  def self.export_to_csv
    require 'csv'
    CSV.generate(headers: true, col_sep: ';') do |csv|
      csv << ['Title', 'Price Intra HT', 'Price Inter HT/ Stagiaire', 'Type', 'Image', 'Duree', 'Description', 'Objectif', 'Programme', 'Public', 'Méthodes pédagogiques', 'Prérequis', 'priorite', 'Mode Evaluation']
      
      all.each do |training|
        csv << [
          training.title,
          training.price_intra_ht,
          training.price_inter_ht,
          training.training_type,
          training.image_url,
          training.duration,
          training.description,
          training.objective,
          training.program,
          training.target_audience,
          training.teaching_methods,
          training.prerequisites,
          training.priority,
          training.evaluation_method
        ]
      end
    end
  end
  
  # Import Excel (.xlsx)
  def self.import_from_excel(file_path)
    require 'roo'
    count = 0
    errors = []
    
    begin
      spreadsheet = Roo::Spreadsheet.open(file_path)
      header = spreadsheet.row(1)
      
      (2..spreadsheet.last_row).each do |i|
        row = Hash[[header, spreadsheet.row(i)].transpose]
        
        begin
          training = new(
            title: row['Title'],
            price_intra_ht: row['Price Intra HT'],
            price_inter_ht: row['Price Inter HT/ Stagiaire'],
            training_type: row['Type'],
            image_url: row['Image'],
            duration: row['Duree'],
            description: row['Description'],
            objective: row['Objectif'],
            program: row['Programme'],
            target_audience: row['Public'],
            teaching_methods: row['Méthodes pédagogiques'],
            prerequisites: row['Prérequis'],
            priority: row['priorite'] || 0,
            evaluation_method: row['Mode Evaluation']
          )
          
          if training.save
            count += 1
          else
            errors << "Ligne #{i}: #{training.errors.full_messages.join(', ')}"
          end
        rescue => e
          errors << "Ligne #{i}: #{e.message}"
        end
      end
    rescue => e
      errors << "Erreur lors de la lecture du fichier: #{e.message}"
    end
    
    { count: count, errors: errors }
  end
  
  # Import CSV (conservé pour compatibilité)
  def self.import_from_csv(file_path)
    require 'csv'
    count = 0
    errors = []
    
    # Détecter le séparateur
    first_line = File.open(file_path, &:readline)
    separator = if first_line.include?("\t")
                  "\t"
                elsif first_line.include?(';')
                  ';'
                else
                  ','
                end
    
    CSV.foreach(file_path, headers: true, col_sep: separator) do |row|
      begin
        training = new(
          title: row['Title'],
          price_intra_ht: row['Price Intra HT'],
          price_inter_ht: row['Price Inter HT/ Stagiaire'],
          training_type: row['Type'],
          image_url: row['Image'],
          duration: row['Duree'],
          description: row['Description'],
          objective: row['Objectif'],
          program: row['Programme'],
          target_audience: row['Public'],
          teaching_methods: row['Méthodes pédagogiques'],
          prerequisites: row['Prérequis'],
          priority: row['priorite'] || 0,
          evaluation_method: row['Mode Evaluation']
        )
        
        if training.save
          count += 1
        else
          errors << "Ligne #{$.}: #{training.errors.full_messages.join(', ')}"
        end
      rescue => e
        errors << "Ligne #{$.}: #{e.message}"
      end
    end
    
    { count: count, errors: errors }
  end
end
