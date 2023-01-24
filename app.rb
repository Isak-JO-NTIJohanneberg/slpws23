require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require "sinatra/reloader"

get('/') do
    slim(:hej)
end