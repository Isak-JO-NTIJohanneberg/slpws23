require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require "sinatra/reloader"

get('/') do
    slim(:main)
end


get('/annonser/') do
    db = SQLite3::Database.new("db/AD_DATA.db")
    db.results_as_hash = true
    result = db.execute("SELECT DISTINCT rubrik, id FROM Annonser")
    slim(:"annonser/index", locals:{result:result})
end

get('/annonser/new') do
    slim(:"annonser/new")
end

get('/annonser/:id') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/AD_DATA.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM Annonser WHERE id = ?",id).first
    slim(:"annonser/show",locals:{result:result})
end

get('/sparade/') do
    slim(:"sparade/index")
end


get('/mina_annonser/') do
    db = SQLite3::Database.new("db/AD_DATA.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM Annonser WHERE user_owner_id = 2")
    slim(:"hantera_annonser/index", locals:{result:result})
end

post('/annonser') do
    rubrik = params[:titel]
    pris = params[:pris].to_i
    annonstext = params[:text]
    kattegori = params[:kattegori].to_i
    user_id = 2
    
    db = SQLite3::Database.new("db/AD_DATA.db")
    db.execute("INSERT INTO Annonser (rubrik, pris, annons_text, user_owner_id, kattegori_id) VALUES (?,?,?,?,?)", rubrik, pris, annonstext, user_id, kattegori)
    redirect("/annonser/")
end

post('/annonser/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/AD_DATA.db")
    db.execute("DELETE FROM Annonser WHERE id = ?", id)
    redirect("/mina_annonser/")
end


get('/annonser/:id/edit') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/AD_DATA.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM Annonser WHERE id = ?", id)
    slim(:"annonser/edit", locals:{result:result})
end