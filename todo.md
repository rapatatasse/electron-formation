nous devons modifier la logique de quiz_attempts. 
l'apprenant ne devra pas etre créer dans la db. supprimer le user_id de la db. nous avons juste besoin de creer une session depuis "gestion des quiz" http://localhost:3000/admin/quizzes 

une fois la session creer afficher un qr code de la session et sont lien public

toute personne qui a ce lien pourra ses connecter et devra remplir en premier deux champ nom et prenom et email optionnel
l'identifiant de quiz attente se ferra avec sont nom et prenon.
si jamais il se deconnect eet se reconnect il aura acces a sont quiz si il est toujours actif si plusieru quiz actif auras une listes des quiz affiché.

lorsque l'on créer la session cela créer  "session.answers_data" avec les id des question du quiz afin que chaque apprenant est les meme question car si le quiz fait 20 (question_count) question et le quiz a 40 question (quiz.question.count) des questions seront selectionner aleatoirement.
 chaque apprenant aura les memes questions lorsqu'il se connecte et créer un quiz_attempts answers_data recevra automatiquement les id des question et sera en attente des reponses de l'apprenant. comme ca si il se deconnect et se reconnect il aura acces a sont quiz si il est toujours actif et pourra le reprendre a la derniere question non repondu . une fois qu'il aura repondu a toutes les questions le quiz sera marque comme termine et plus accessible. faire en sorte que l'on ne puisse pas revenir sur une question en faisant un retour en arriere.


 pour le chois aléatoire des question dans le quiz_attempts mettre dans session answers_data. si plusieurs theme repartir proportionnelement les questions afin qu'on ai plus ou moins les meme nombre de question par theme.

 Rajouter un champs sur Sessions formateur_id pour assigner une session a un formateur. 
 rajouter une table de liaison formateur_quizzes pour permettre au formateur d'acceder à sa vue des quiz qui lui sont affecter. une fois le quiz affecter il pourra créer des session.
 Modifie la vue admin/quizzes pour pouvoir assigner le quiz au formateur rajouter colonne assignation pour voir les formateur qui au acces au quiz



 a a jouter le multilangue sur les quiz et question avec cette configuration :
 Le stockage JSONB 
utiliser une colonne jsonb qui contient toutes les langues.

Structure suggérée :
Modifier les colonnes existantes pour qu'elles acceptent du JSON :

question_text : {"fr": "Quelle est...", "en": "What is..."}

title : {"fr": "Quiz Capitales", "en": "Capitals Quiz"}
rajouter suelement dans l'edit la possibiliter de rajouter des champ pour les langue avoir une liste de langue et pour chaque langue un champ de texte. liste par default en dur [francais, anglais, espagnol, portugais, allemend] dans la vue du quiz cote apprenant mettre petit drapeau en haut a droite pour pouvoir changer de langue si langue detecter.