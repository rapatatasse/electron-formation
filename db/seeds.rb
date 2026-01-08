# Création de l'utilisateur admin
puts "Création de l'utilisateur admin..."
admin = User.find_or_create_by!(email: 'platonformation@gmail.com') do |user|
  user.first_name = 'Admin'
  user.last_name = 'John'
  user.password = 'GUKGk45123??'
  user.password_confirmation = 'GUKGk45123??'
  user.role = :admin
  user.locale = 'fr'
  user.phone = '0123456789'
end
puts "✓ Admin créé : #{admin.email} "

# Création d'un formateur de test
puts "\nCréation d'un formateur de test..."
formateur = User.find_or_create_by!(email: 'formateur@formation.com') do |user|
  user.first_name = 'Jean'
  user.last_name = 'Formateur'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = :formateur
  user.locale = 'fr'
  user.phone = '0123456788'
end
puts "✓ Formateur créé : #{formateur.email} (mot de passe: password123)"

# Création d'un apprenant de test
puts "\nCréation d'un apprenant de test..."
apprenant = User.find_or_create_by!(email: 'apprenant@formation.com') do |user|
  user.first_name = 'Marie'
  user.last_name = 'Apprenant'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = :apprenant
  user.locale = 'fr'
  user.phone = '0123456787'
end
puts "✓ Apprenant créé : #{apprenant.email} (mot de passe: password123)"

# Création de thèmes
puts "\nCréation des thèmes..."
themes_data = [
  { name: 'Risque electrique', description: 'Questions de mathématiques', color: '#3b82f6' },
  { name: 'Risque mecanique', description: 'Questions de français et grammaire', color: '#10b981' },
  { name: 'Legislation', description: 'Questions sur l\'informatique et la programmation', color: '#f59e0b' } 
]

themes_data.each do |theme_data|
  theme = Theme.find_or_create_by!(name: theme_data[:name]) do |t|
    t.description = theme_data[:description]
    t.color = theme_data[:color]
  end
  puts "✓ Thème créé : #{theme.name}"
end

# Création de cours
puts "\nCréation des cours..."
courses_data = [
  { title: 'Calcul Elingage', slug: 'calculelingage', position: 1 },
  { title: 'Exercices Malt', slug: 'Exo', position: 2 },
  { title: 'DAOE', slug: 'dao', position: 3 }
]

courses_data.each do |course_data|
  course = Course.find_or_create_by!(slug: course_data[:slug]) do |c|
    c.title = course_data[:title]
    c.description = "Description du cours #{course_data[:title]}"
    c.content = "Contenu du cours #{course_data[:title]}"
    c.position = course_data[:position]
    c.active = true
  end
  puts "✓ Cours créé : #{course.title}"
end

puts "\n" + "="*50
puts "SEED TERMINÉ !"
puts "="*50
puts "\nComptes créés :"

puts "\nVous pouvez maintenant vous connecter avec ces comptes."
