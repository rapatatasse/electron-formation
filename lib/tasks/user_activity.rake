namespace :user_activity do
  desc "Afficher le rapport d'activité mensuel pour tous les utilisateurs"
  task monthly_report: :environment do
    date = ENV['DATE'] ? Date.parse(ENV['DATE']) : Time.current
    service = UserActivityReportService.new(date)
    report = service.generate_monthly_report

    puts "\n" + "="*80
    puts "RAPPORT D'ACTIVITÉ MENSUEL - #{report[:period]}".center(80)
    puts "="*80
    puts "\nGénéré le: #{report[:generated_at].strftime('%d/%m/%Y à %H:%M')}"
    puts "\n" + "-"*80
    puts "STATISTIQUES GLOBALES"
    puts "-"*80
    puts "Total utilisateurs: #{report[:total_users]}"
    puts "Utilisateurs actifs: #{report[:active_users]}"
    puts "Total activités: #{report[:global_stats][:total_activities]}"
    puts "Moyenne activités/utilisateur: #{report[:global_stats][:avg_activities_per_user].round(2)}"
    puts "Jour le plus actif: #{report[:global_stats][:peak_activity_day]}"

    puts "\n" + "-"*80
    puts "ACTIVITÉS PAR TYPE"
    puts "-"*80
    report[:activity_by_action].each do |action, count|
      puts "  #{action.ljust(30)}: #{count}"
    end

    puts "\n" + "-"*80
    puts "TOP 10 UTILISATEURS LES PLUS ACTIFS"
    puts "-"*80
    report[:top_active_users].each_with_index do |user, index|
      puts "#{(index + 1).to_s.rjust(2)}. #{user[:name].ljust(30)} (#{user[:email].ljust(30)}) - #{user[:activity_count]} activités"
    end

    puts "\n" + "-"*80
    puts "ACTIVITÉ PAR JOUR"
    puts "-"*80
    report[:activity_by_day].each do |day, count|
      puts "  #{day}: #{'█' * (count / 5)} #{count}"
    end

    puts "\n" + "="*80
  end

  desc "Afficher le rapport d'activité pour un utilisateur spécifique"
  task user_report: :environment do
    user_id = ENV['USER_ID']
    unless user_id
      puts "Usage: rake user_activity:user_report USER_ID=123 [DATE=2026-01-01]"
      exit
    end

    user = User.find_by(id: user_id)
    unless user
      puts "Utilisateur non trouvé avec l'ID: #{user_id}"
      exit
    end

    date = ENV['DATE'] ? Date.parse(ENV['DATE']) : Time.current
    service = UserActivityReportService.new(date)
    report = service.generate_user_report(user)

    puts "\n" + "="*80
    puts "RAPPORT D'ACTIVITÉ UTILISATEUR - #{report[:period]}".center(80)
    puts "="*80
    puts "\nUtilisateur: #{report[:user][:name]} (#{report[:user][:email]})"
    puts "Rôle: #{report[:user][:role]}"
    puts "\n" + "-"*80
    puts "STATISTIQUES"
    puts "-"*80
    puts "Total activités: #{report[:stats][:total_activities]}"
    puts "Connexions: #{report[:stats][:logins]}"
    puts "Quiz démarrés: #{report[:stats][:quizzes_started]}"
    puts "Quiz complétés: #{report[:stats][:quizzes_completed]}"
    puts "Quiz abandonnés: #{report[:stats][:quizzes_abandoned]}"
    puts "Réponses soumises: #{report[:stats][:answers_submitted]}"
    puts "Certificats générés: #{report[:stats][:certificates_generated]}"
    puts "Jours actifs: #{report[:stats][:active_days]}"
    puts "Première activité: #{report[:stats][:first_activity]&.strftime('%d/%m/%Y %H:%M')}"
    puts "Dernière activité: #{report[:stats][:last_activity]&.strftime('%d/%m/%Y %H:%M')}"

    puts "\n" + "-"*80
    puts "PERFORMANCE QUIZ"
    puts "-"*80
    perf = report[:quiz_performance]
    puts "Total tentatives: #{perf[:total_attempts]}"
    puts "Complétés: #{perf[:completed]}"
    puts "Réussis: #{perf[:passed]}"
    puts "Score moyen: #{perf[:average_score]}%"
    puts "Temps total: #{perf[:total_time_spent]} secondes"

    puts "\n" + "-"*80
    puts "PATTERNS DE CONNEXION"
    puts "-"*80
    patterns = report[:login_patterns]
    puts "Total connexions: #{patterns[:total_logins]}"
    puts "IPs uniques: #{patterns[:unique_ips]}"

    puts "\n" + "="*80
  end

  desc "Exporter le rapport mensuel en CSV"
  task export_csv: :environment do
    date = ENV['DATE'] ? Date.parse(ENV['DATE']) : Time.current
    service = UserActivityReportService.new(date)
    csv_content = service.export_to_csv

    filename = "user_activity_#{date.strftime('%Y_%m')}.csv"
    filepath = Rails.root.join('tmp', filename)
    
    File.write(filepath, csv_content)
    puts "Rapport exporté vers: #{filepath}"
  end

  desc "Afficher les activités récentes d'un utilisateur"
  task recent_activities: :environment do
    user_id = ENV['USER_ID']
    limit = ENV['LIMIT']&.to_i || 20

    unless user_id
      puts "Usage: rake user_activity:recent_activities USER_ID=123 [LIMIT=20]"
      exit
    end

    user = User.find_by(id: user_id)
    unless user
      puts "Utilisateur non trouvé avec l'ID: #{user_id}"
      exit
    end

    puts "\n" + "="*80
    puts "ACTIVITÉS RÉCENTES - #{user.full_name}".center(80)
    puts "="*80

    activities = user.recent_activities(limit)
    activities.each do |activity|
      puts "\n#{activity.performed_at.strftime('%d/%m/%Y %H:%M:%S')}"
      puts "  Action: #{activity.action_type}"
      puts "  Resource: #{activity.resource_type} ##{activity.resource_id}" if activity.resource_type
      puts "  IP: #{activity.ip_address}" if activity.ip_address
      puts "  Metadata: #{activity.metadata}" if activity.metadata.present?
    end

    puts "\n" + "="*80
  end

  desc "Afficher le résumé d'activité pour une période personnalisée"
  task custom_period: :environment do
    user_id = ENV['USER_ID']
    start_date = ENV['START_DATE']
    end_date = ENV['END_DATE']

    unless user_id && start_date && end_date
      puts "Usage: rake user_activity:custom_period USER_ID=123 START_DATE=2026-01-01 END_DATE=2026-01-31"
      exit
    end

    user = User.find_by(id: user_id)
    unless user
      puts "Utilisateur non trouvé avec l'ID: #{user_id}"
      exit
    end

    summary = user.activity_summary(Date.parse(start_date), Date.parse(end_date))

    puts "\n" + "="*80
    puts "RÉSUMÉ D'ACTIVITÉ - #{user.full_name}".center(80)
    puts "="*80
    puts "\nPériode: #{summary[:period]}"
    puts "Total activités: #{summary[:total_activities]}"
    puts "Jours actifs: #{summary[:active_days]}"

    puts "\n" + "-"*80
    puts "PAR TYPE D'ACTION"
    puts "-"*80
    summary[:by_action].each do |action, count|
      puts "  #{action.ljust(30)}: #{count}"
    end

    puts "\n" + "-"*80
    puts "PAR JOUR"
    puts "-"*80
    summary[:by_day].each do |day, count|
      puts "  #{day}: #{count}"
    end

    puts "\n" + "="*80
  end
end
