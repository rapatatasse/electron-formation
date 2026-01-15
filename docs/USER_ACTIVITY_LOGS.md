# Système de Logs d'Activité Utilisateur

## Vue d'ensemble

Le système de logs d'activité permet de tracker et analyser toutes les actions des utilisateurs dans l'application. Il enregistre automatiquement les connexions, tentatives de quiz, réponses soumises, et autres activités importantes.

## Structure de la base de données

### Table `user_activity_logs`

- `user_id` : Référence à l'utilisateur
- `action_type` : Type d'action (login, quiz_started, etc.)
- `resource_type` : Type de ressource concernée (Quiz, Question, etc.)
- `resource_id` : ID de la ressource
- `metadata` : Données JSON supplémentaires
- `ip_address` : Adresse IP de l'utilisateur
- `user_agent` : User agent du navigateur
- `performed_at` : Date et heure de l'action

## Types d'actions trackées

- `login` : Connexion utilisateur
- `logout` : Déconnexion utilisateur
- `quiz_started` : Début d'un quiz
- `quiz_completed` : Quiz terminé
- `quiz_abandoned` : Quiz abandonné
- `answer_submitted` : Réponse soumise
- `certificate_generated` : Certificat généré
- `profile_updated` : Profil mis à jour
- `password_changed` : Mot de passe changé

## Utilisation dans le code

### Logger une activité manuellement

```ruby
# Dans un contrôleur ou un service
current_user.log_activity(
  action_type: 'quiz_started',
  resource: @quiz,
  metadata: { difficulty: 'medium' },
  request: request
)
```

### Activer le logging automatique dans un contrôleur

```ruby
class MyController < ApplicationController
  include ActivityLogging
  
  # Les activités seront automatiquement loggées
end
```

### Récupérer les statistiques d'un utilisateur

```ruby
# Statistiques du mois en cours
stats = current_user.monthly_activity_stats

# Statistiques d'un mois spécifique
stats = current_user.monthly_activity_stats(Date.new(2026, 1, 1))

# Activités récentes
activities = current_user.recent_activities(20)

# Résumé pour une période personnalisée
summary = current_user.activity_summary(start_date, end_date)
```

## Tâches Rake disponibles

### Rapport mensuel global

```bash
# Mois en cours
rake user_activity:monthly_report

# Mois spécifique
rake user_activity:monthly_report DATE=2026-01-01
```

### Rapport pour un utilisateur spécifique

```bash
rake user_activity:user_report USER_ID=123

# Avec un mois spécifique
rake user_activity:user_report USER_ID=123 DATE=2026-01-01
```

### Export CSV

```bash
# Export du mois en cours
rake user_activity:export_csv

# Export d'un mois spécifique
rake user_activity:export_csv DATE=2026-01-01
```

Le fichier sera généré dans `tmp/user_activity_YYYY_MM.csv`

### Activités récentes d'un utilisateur

```bash
# 20 dernières activités (par défaut)
rake user_activity:recent_activities USER_ID=123

# Nombre personnalisé
rake user_activity:recent_activities USER_ID=123 LIMIT=50
```

### Période personnalisée

```bash
rake user_activity:custom_period USER_ID=123 START_DATE=2026-01-01 END_DATE=2026-01-31
```

## Interface Admin

### Routes disponibles

Ajouter dans `config/routes.rb` :

```ruby
namespace :admin do
  resources :activity_reports, only: [:index] do
    collection do
      get :export
    end
    member do
      get :user_report
    end
  end
end
```

### Accès aux rapports

- `/admin/activity_reports` : Rapport mensuel global
- `/admin/activity_reports/user_report?user_id=123` : Rapport utilisateur
- `/admin/activity_reports/export.csv` : Export CSV

## Exemples de statistiques retournées

### Statistiques mensuelles

```ruby
{
  total_activities: 150,
  logins: 20,
  quizzes_started: 15,
  quizzes_completed: 12,
  quizzes_abandoned: 3,
  answers_submitted: 120,
  certificates_generated: 5,
  first_activity: DateTime,
  last_activity: DateTime,
  active_days: 18,
  by_action_type: {
    "login" => 20,
    "quiz_started" => 15,
    ...
  }
}
```

## Migration

Pour appliquer la migration :

```bash
rails db:migrate
```

## Performance

- Les index sont créés sur `user_id`, `performed_at`, `action_type` et `resource_type/resource_id`
- Les requêtes sont optimisées pour les rapports mensuels
- Utiliser `.includes(:user_activity_logs)` pour éviter les N+1 queries

## Nettoyage des anciennes données

Pour éviter une croissance excessive de la table, vous pouvez créer une tâche de nettoyage :

```ruby
# Supprimer les logs de plus de 12 mois
UserActivityLog.where('performed_at < ?', 12.months.ago).delete_all
```

## Personnalisation

### Ajouter de nouveaux types d'actions

Modifier `ACTION_TYPES` dans `app/models/user_activity_log.rb` :

```ruby
ACTION_TYPES = %w[
  login
  logout
  # ... types existants
  custom_action
].freeze
```

### Modifier le concern ActivityLogging

Éditer `app/controllers/concerns/activity_logging.rb` pour ajouter de nouveaux mappings d'actions.
