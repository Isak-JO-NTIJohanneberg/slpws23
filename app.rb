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
    result = db.execute("SELECT rubrik FROM Annonser").first
    slim(:"annonser/index", locals:{result:result})
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

