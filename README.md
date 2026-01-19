# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

rails db:drop
rails db:create
rails db:migrate
rails db:seed


si besoin de texte enrichie mettre Trix pour les champs Programme, Description, Objectif

git add .
git commit -m "message"
git push heroku main  

# migration sur heroku
heroku run rails db:migrate --app electronformation