require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require "sinatra/reloader"

enable :sessions

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
    slim(:"annonser/show",locals:{result:result})
end

get('/sparade/') do
    slim(:"sparade/index")
end


get('/mina_annonser/') do
    db = SQLite3::Database.new("db/AD_DATA.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM Annonser WHERE user_owner_id = ?", session[:id])
    slim(:"hantera_annonser/index", locals:{result:result})
end

post('/annonser') do
    rubrik = params[:titel]
    pris = params[:pris].to_i
    annonstext = params[:text]
    kattegori = params[:kattegori].to_i
    user_id =  session[:id]

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
    db.execute("DELETE FROM Annonser WHERE id = ?", id)
    redirect("/mina_annonser/")
end


get('/annonser/:id/edit') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/AD_DATA.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM Annonser WHERE id = ?", id).first
    @kattegorier = db.execute("SELECT * FROM Kattegorier")

    slim(:"annonser/edit",locals:{result:result})
end




post('/annonser/:id/update') do
    id = params[:id]
    rubrik = params[:titel]
    pris = params[:pris].to_i
    annonstext = params[:text]
    kattegori = params[:kattegori].to_i
    user_id = session[:id]

    if  params[:bilden] != nil
        bild_filnamn = params[:bilden][:filename]
        bild_fil = params[:bilden][:tempfile]
        
        File.open("./public/user_bilder/#{bild_filnamn}", 'wb') do |f|
            f.write(bild_fil.read)
        end
    end

    db = SQLite3::Database.new("db/AD_DATA.db")
    db.execute("UPDATE Annonser SET rubrik=?, pris=?, annons_text=?, kattegori_id=?, bild=? WHERE id=?", rubrik, pris, annonstext, kattegori, bild_filnamn, id)  
        
 


    redirect("/mina_annonser/")
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


get('/anvandare/login/') do
    slim(:"anvandare/login")
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
    @id = id

    if password_okrypterat=BCrypt::Password.new(psw_krypterad) == password
  
      session[:anv_id] = id
  
      redirect('/annonser/')
  
  
  
    else
 
        
        redirect("/ajajaj, nu blev det fel här/")

        
    end
end