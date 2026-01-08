## Fonctionnalités principales planifiées
Gestion des utilisateurs (3 rôles)

Admin, Formateur, Apprenant avec permissions distinctes

## Banque de questions
Procedure l'admin créer les qui qu'il affecte au formateur ou apprenant
lorsque qu'il créer le quiz il créer les question du quiz les question sont rattaché a une seul quiz.

**IMPORTANT : Questions uniques par quiz (pas de banque partagée)**

Option du quiz
Quiz simple : liste fixe de questions
Quiz adaptatif : type TOSA avec algorithme qui ajuste la difficulté selon les réponses (bien plus de question que le quiz simple)
si plusieurs thematqique le teste dois piocher dans chaque thematique pour avoir un quiz complet.

Structure des questions :
Question | Array Réponse(s) | réponses justes (une ou plusieurs) | reponse_aleatoire(boolean) | 
Niveau de difficulté (0-100) |
Thème|
lien image |

**IMPORTANT : Support QCM avec réponses multiples correctes possibles**

## Fonctionnalités formateur

Créer/gérer des cours
Créer des quiz avec seuil de validation personnalisé
Consulter statistiques des apprenants

## Fonctionnalités apprenant

Passer des quiz
Voir récapitulatif avec stats détaillées
Suivre sa progression

## Informations à me fournir pour affiner le système
Technologies :Ruby On Rails

Nombre d'utilisateurs prévus (apprenants, formateurs) 200/ans
Nombre de questions dans la banque 300
Nombre de cours pages statiques 20 créer en dur non modifiable par les formateurs attribution des cours au formateur et au Apprenant

## Fonctionnalités supplémentaires

Gestion du temps (chronomètre, limite de temps par quiz) option a mettre lors de la création du quiz choisir le temps ou pas de temps.
Certificats/badges de réussite mettre la possibilité au formateur de gener certificat une fois le test passé avec un seuil de validation.
**IMPORTANT : Génération de certificat MANUELLE par le formateur (pas automatique)**
Export des résultats : Excel
Notifications : non
Mode hors-ligne : non
Multilingue : oui les langue seront en dur dans le code.
Algorithme adaptatif : oui
Nombre de questions par test adaptatif : le nombre de question est définit par le formateur lors de la création du quiz.
Critères précis d'adaptation (après combien de bonnes/mauvaises réponses changer de niveau) ? le niveau du candidat comment a 50/100 les question lui sont proposer dans une fourchette de 30 en dessus ou en dessous s'il repond bien sont niveau est augmenter de 10 et si il repond mal sont niveau est diminuer de 10.
Paliers de niveau (débutant, intermédiaire, avancé, expert) ? les pallier seront seulement afficher dans le certificat debutant:0-30, intermediaire:31-60, avancé:61-90, expert:91-100
Statistiques souhaitées : oui par personne sur le quiz comparer au statistiques globale sur ce quiz

Quelles métriques précises : (temps moyen, taux de réussite par thème, évolution dans le temps, comparaison entre apprenants)
Graphiques classiques

Pouvoir exporter et importer des question via un fichier csv

## ✅ DÉCISIONS DE CONCEPTION VALIDÉES

1. **Questions uniques par quiz** : Chaque question appartient à un seul quiz (pas de banque partagée)
2. **QCM à réponses multiples** : Support des questions avec plusieurs réponses correctes possibles
3. **Certification manuelle** : Le formateur génère manuellement les certificats après validation du test
4. **Algorithme adaptatif** : Niveau initial 50/100, ajustement ±10, fourchette de sélection ±30
5. **Paliers certificat** : Débutant (0-30), Intermédiaire (31-60), Avancé (61-90), Expert (91-100)