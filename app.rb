require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require "sinatra/reloader"
require 'sinatra/flash' 

enable :sessions

get('/') do
    slim(:main)
end


#before do
 #   db = SQLite3::Database.new("db/AD_DATA.db")
  #  db.results_as_hash = true
   # result = db.execute("SELECT DISTINCT User_owner_id, id FROM Annonser where id = ?", ?=params )
#end
   

get('/annonser/') do
    db = SQLite3::Database.new("db/AD_DATA.db")
    db.results_as_hash = true
    result = db.execute("SELECT DISTINCT rubrik, id FROM Annonser")
    slim(:"annonser/index", locals:{result:result})
end

get('/annonser/new') do
    
    db = SQLite3::Database.new("db/AD_DATA.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM Kattegorier")
    slim(:"annonser/new", locals:{result:result})
end

get('/annonser/:id') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/AD_DATA.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM Annonser WHERE id = ?",id).first
    @anv_sparade = db.execute("SELECT Annons_id FROM User_saved_relation WHERE anv_id = #{session[:anv_id]}")
    @antal_lajks = db.execute("SELECT COUNT (Annons_id) FROM User_saved_relation WHERE Annons_id = ?", id).first
    slim(:"annonser/show", locals:{result:result})
end

get('/mina_annonser/') do
    db = SQLite3::Database.new("db/AD_DATA.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM Annonser WHERE user_owner_id = ?", session[:anv_id])
    slim(:"hantera_annonser/index", locals:{result:result})
end

post('/annonser') do
    rubrik = params[:titel]
    pris = params[:pris].to_i
    annonstext = params[:text]
    kattegori = params[:kattegori].to_i
    user_id =  session[:anv_id]

    p user_id
    
    if  params[:bilden] != nil
        bild_filnamn = params[:bilden][:filename]
        bild_fil = params[:bilden][:tempfile]
        
        File.open("./public/user_bilder/#{bild_filnamn}", 'wb') do |f|
            f.write(bild_fil.read)
        end
    end

       
    db = SQLite3::Database.new("db/AD_DATA.db")
    db.execute("INSERT INTO Annonser (rubrik, pris, annons_text, user_owner_id, kattegori_id, bild) VALUES (?,?,?,?,?,?)", rubrik, pris, annonstext, user_id, kattegori, bild_filnamn)  
     

    redirect("/annonser/")


end

post('/annonser/:id/delete') do    
    id = params[:id].to_i
    db = SQLite3::Database.new("db/AD_DATA.db")
    if session[:anv_id] == db.execute("SELECT DISTINCT User_owner_id FROM Annonser WHERE id = ?", id).first["user_owner_id"]
        db.execute("DELETE FROM Annonser WHERE id = ?", id)
    else
        flash[:notice] = "Du har inte behörighet att utföra den här återgärden"
        redirect back
    end
    redirect("/mina_annonser/")
end


get('/annonser/:id/edit') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/AD_DATA.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM Annonser WHERE id = ?", id).first
    @kattegorier = db.execute("SELECT * FROM Kattegorier")
    if session[:anv_id] == db.execute("SELECT DISTINCT User_owner_id FROM Annonser WHERE id = ?", id).first["user_owner_id"]
        slim(:"annonser/edit",locals:{result:result})
    else
        flash[:notice] = "Du har inte behörighet att utföra den här återgärden"
        redirect("/")
    end
end




post('/annonser/:id/update') do
    id = params[:id].to_i
    rubrik = params[:titel]
    pris = params[:pris].to_i
    annonstext = params[:text]
    kattegori = params[:kattegori].to_i
    user_id = session[:anv_id]

    if  params[:bilden] != nil
        bild_filnamn = params[:bilden][:filename]
        bild_fil = params[:bilden][:tempfile]
        
        File.open("./public/user_bilder/#{bild_filnamn}", 'wb') do |f|
            f.write(bild_fil.read)
        end
    end
    
    db = SQLite3::Database.new("db/AD_DATA.db")
    db.results_as_hash = true

    p db.execute("SELECT DISTINCT User_owner_id FROM Annonser WHERE id = ?", id).first["user_owner_id"]

    if session[:anv_id] == db.execute("SELECT DISTINCT User_owner_id FROM Annonser WHERE id = ?", id).first["user_owner_id"]
        db.execute("UPDATE Annonser SET rubrik=?, pris=?, annons_text=?, kattegori_id=?, bild=? WHERE id=?", rubrik, pris, annonstext, kattegori, bild_filnamn, id)  
        redirect("/mina_annonser/")
    else
        flash[:notice] = "Du har inte behörighet att utföra den här återgärden"
        redirect("/")
    end

end


post('/annonser/:id/spara') do
    annons_id = params[:id].to_i
    anv_id = session[:anv_id]
    db = SQLite3::Database.new("db/AD_DATA.db")
    db.execute("INSERT INTO User_saved_relation (anv_id, annons_id) VALUES (?,?)", anv_id, annons_id)
    redirect("/annonser/#{annons_id}")
    flash[:notice] = "Du måste vara inloggad för att utföra den här återgärden"
    redirect back
end

post('/annonser/:id/rm_fav') do
    annons_id = params[:id].to_i
    anv_id = session[:anv_id]
    db = SQLite3::Database.new("db/AD_DATA.db")
    db.execute("DELETE FROM User_saved_relation WHERE annons_id = ? AND anv_id =?", annons_id, anv_id)
    redirect back
end

get('/anvandare/new/') do
    slim(:"anvandare/register")
end


post('/anvandare') do

    if params[:password] == params[:password2]

        user_name = params[:user_name]
        tel_nr = params[:tel_nr].to_i
        password = params[:password]

        password_krypterat=BCrypt::Password.create(password)


        db = SQLite3::Database.new("db/AD_DATA.db")
        db.execute("INSERT INTO Anvandare (anv_namn, kontakt_upg, losenord) VALUES (?,?,?)", user_name, tel_nr, password_krypterat)  

        redirect("/anvandare/success/")


    else
        
        redirect("/ajajaj, nu blev det fel här/")

        
    end
end

get('/anvandare/success') do

    slim(:"anvandare/lyckat")

end

get('/sparade/') do

    anv_id = session[:anv_id]
    db = SQLite3::Database.new("db/AD_DATA.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM Annonser WHERE id IN (SELECT Annons_id FROM User_saved_relation WHERE anv_id = #{session[:anv_id]})")

    slim(:"sparade/index", locals:{result:result})

        
end

get('/anvandare/login/') do
    slim(:"anvandare/login")
end

get('/anvandare/logout/') do
    session.destroy
    flash[:notice] = "Du har loggat ut!"

    redirect('/anvandare/login/')
end

post('/anvandare/login') do

    user_name = params[:user_name]
    tel_nr = params[:tel_nr].to_i
    password = params[:password]

    db = SQLite3::Database.new("db/AD_DATA.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM Anvandare WHERE anv_namn = ?", user_name).first
    psw_krypterad = result["losenord"]
    id = result["id"]
    p id
    session[:anv_id] = id

    if password_okrypterat=BCrypt::Password.new(psw_krypterad) == password
  
      p "användarid: #{session[:anv_id]}"
  
      redirect('/annonser/')
  
  
  
    else
 
        
        redirect("/ajajaj, nu blev det fel här/")

        
    end
end