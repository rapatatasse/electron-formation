## rajouter une un role "bureau" pour les user 

besoin d'un dascbord pour le role "bureau" qio aura accès la vue des tache a planninfier.
toutes personne de ce role pourra creer projet et tache. seul le créateur du projet peut supprimer le projet.
toutes personne de ce role pourra modifier/ajouter les taches.
toutes personne de ce role pourra voir les taches et les dependances.

rajouter une base de données pour gerer planning gantt


📁 Table Projects
Field	Type	Description
id	INT (PK)	Unique project identifier
name	VARCHAR(150)	Project name
description	TEXT	Project description
start_date	DATE	Project start date
end_date	DATE	Planned end date
status	VARCHAR(50)	In Progress / Completed / Pending
manager	VARCHAR(100)	Project manager name
📁 Table Tasks
Field	Type	Description
id	INT (PK)	Unique task identifier
project_id	INT (FK)	Reference to project
name	VARCHAR(150)	Task name
description	TEXT	Task details
start_date	DATE	Task start date
end_date	DATE	Task end date
duration_days	INT	Duration (days)
hours_per_day	INT	Working hours per day
progress	INT	Progress percentage
status	VARCHAR(50)	In Progress / Completed
priority	VARCHAR(20)	High / Medium / Low
📁 Table Task_Users
Field	Type	Description
id	INT (PK)	Unique identifier
task_id	INT (FK)	Reference to task
user_id	INT (FK)	Reference to user
📁 Table Task_Dependencies
Field	Type	Description
id	INT (PK)	Unique identifier
task_id	INT (FK)	Dependent task
dependency_task_id	INT (FK)	Predecessor task

Besoin d'un vu simple pour voir les taches et les dependances
Vue dans des pages séparer 
 - vue calendrier
 - vue liste
 - vue to do list (tache a faire)
 - vue par proget avec les differentes vue dans la meme page (gantt/liste / todo)