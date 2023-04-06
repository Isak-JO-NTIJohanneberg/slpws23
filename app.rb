require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require "sinatra/reloader"
require 'sinatra/flash'
require_relative './model.rb' 

enable :sessions

get('/') do
    anropa_db()
    @anv_namn = ""
    if session[:anv_id] != nil
        @anv_namn = @db.execute("SELECT DISTINCT anv_namn FROM Anvandare WHERE id = ?", session[:anv_id]).first["anv_namn"]
    end
    slim(:main)
end


#before do
 #   db = SQLite3::Database.new("db/AD_DATA.db")
  #  db.results_as_hash = true
   # result = db.execute("SELECT DISTINCT User_owner_id, id FROM Annonser where id = ?", ?=params )
#end
   

get('/annonser/') do
    #db = SQLite3::Database.new("db/AD_DATA.db")
    #db.results_as_hash = true
    anropa_db()

    result = @db.execute("SELECT DISTINCT rubrik, id, pris FROM Annonser")
    slim(:"annonser/index", locals:{result:result})
end

get('/annonser/new') do
    
    anropa_db()

    result = @db.execute("SELECT * FROM Kattegorier")
    slim(:"annonser/new", locals:{result:result})
end

get('/annonser/:id') do
    id = params[:id].to_i
    anropa_db()

    result = @db.execute("SELECT * FROM Annonser WHERE id = ?",id).first
    if session[:anv_id] != nil
        @anv_sparade = @db.execute("SELECT Annons_id FROM User_saved_relation WHERE anv_id = #{session[:anv_id]}")
    end
    @antal_lajks = @db.execute("SELECT COUNT (Annons_id) FROM User_saved_relation WHERE Annons_id = ?", id).first

    @kontakt = @db.execute("SELECT kontakt_upg FROM Anvandare WHERE id IN (SELECT User_owner_id FROM Annonser WHERE id = ?)", id).first["kontakt_upg"]

    slim(:"annonser/show", locals:{result:result})
end

before('/mina_annonser/') do
    if session[:anv_id] != nil
                

    else

        ej_inlogg_note()

    end

end

get('/mina_annonser/') do
   
        anropa_db()

        result = @db.execute("SELECT * FROM Annonser WHERE user_owner_id = ?", session[:anv_id])
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

       
    anropa_db()

    @db.execute("INSERT INTO Annonser (rubrik, pris, annons_text, user_owner_id, kattegori_id, bild) VALUES (?,?,?,?,?,?)", rubrik, pris, annonstext, user_id, kattegori, bild_filnamn)  
     

    redirect("/annonser/")


end

post('/annonser/:id/delete') do    
    id = params[:id].to_i
    anropa_db()
    #p @db.execute("SELECT DISTINCT user_owner_id FROM Annonser WHERE id = ?", id).first

    #p @db.execute("SELECT DISTINCT bild FROM Annonser WHERE id = ?", id)


    if @db.execute("SELECT DISTINCT bild FROM Annonser WHERE id = ?", id).first["bild"] != nil 
        bild_filnamn = @db.execute("SELECT DISTINCT bild FROM Annonser WHERE id = ?", id).first["bild"]

        File.delete("./public/user_bilder/#{bild_filnamn}")

    end



    if session[:anv_id] == @db.execute("SELECT DISTINCT user_owner_id FROM Annonser WHERE id = ?", id).first["user_owner_id"]

        @db.execute("DELETE FROM Annonser WHERE id = ?", id)

        @db.execute("DELETE FROM User_saved_relation WHERE annons_id = ?", id)


    else
        hackerman()
    end

 
    redirect("/mina_annonser/")
end


get('/annonser/:id/edit') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/AD_DATA.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM Annonser WHERE id = ?", id).first
    @kattegorier = db.execute("SELECT * FROM Kattegorier")

    p db.execute("SELECT DISTINCT user_owner_id FROM Annonser WHERE id = ?", id).first["user_owner_id"]

    if session[:anv_id] == db.execute("SELECT DISTINCT user_owner_id FROM Annonser WHERE id = ?", id).first["user_owner_id"]


        slim(:"annonser/edit",locals:{result:result})

    else
        hackerman()
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
        ej_inlogg_note()

    end

end

post('/anvandare/:id/update') do

    if session[:anv_id] == params[:id]


        id = session[:anv_id]
            
        user_name = params[:user_name]
        tel_nr = params[:tel_nr].to_i
        password = params[:password]

        


        db = SQLite3::Database.new("db/AD_DATA.db")
        db.results_as_hash = true
        psw_krypterad = db.execute("SELECT DISTINCT Losenord FROM Anvandare WHERE id = ?", id).first["losenord"]

        if params[:password] == params[:password2] && password_okrypterat=BCrypt::Password.new(psw_krypterad) == params[:gamla_password]

            password_krypterat=BCrypt::Password.create(password)
            db.execute("UPDATE Anvandare SET anv_namn=?, kontakt_upg=?, losenord=? WHERE id=?", user_name, tel_nr, password_krypterat, id)  
            
        end
    end
    redirect("/")



end


before('/anvandare/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/AD_DATA.db")

    #p db.execute("SELECT DISTINCT user_owner_id FROM Annonser WHERE id = ?", id).first.first

    if session[:anv_id] != db.execute("SELECT DISTINCT id FROM Anvandare WHERE id = ?", id).first.first
        hackerman()
    end
    
end
   

post('/anvandare/:id/delete') do 
    id = params[:id].to_i

    anropa_db()

    @db.execute("DELETE FROM Anvandare WHERE id = ?", id)

    @db.execute("DELETE FROM User_saved_relation WHERE anv_id = ?", id)

    @db.execute("DELETE FROM Annonser WHERE user_owner_id = ?", id)


    session.destroy

    redirect("/anvandare/login/")
end


before('/annonser/:id/spara') do

    if session[:anv_id] != nil

    else
        
        ej_inlogg_note()
    end


end


post('/annonser/:id/spara') do

    annons_id = params[:id].to_i
    anv_id = session[:anv_id]
    p anv_id
    db = SQLite3::Database.new("db/AD_DATA.db")
    db.execute("INSERT INTO User_saved_relation (anv_id, annons_id) VALUES (?,?)", anv_id, annons_id)
    redirect("/annonser/#{annons_id}")
    redirect back


end

post('/annonser/:id/rm_fav') do
    annons_id = params[:id].to_i
    anv_id = session[:anv_id]
    db = SQLite3::Database.new("db/AD_DATA.db")
    if anv_id != nil
        db.execute("DELETE FROM User_saved_relation WHERE annons_id = ? AND anv_id =?", annons_id, anv_id)
    else
        hackerman()
    end
    redirect back
end

get('/anvandare/new/') do
    slim(:"anvandare/register")
end


post('/anvandare') do

    if params[:password] == params[:password2] 

        db = SQLite3::Database.new("db/AD_DATA.db")
        db.results_as_hash = true

        user_name = params[:user_name]
        tel_nr = params[:tel_nr].to_i
        password = params[:password]

        password_krypterat=BCrypt::Password.create(password)

        

        
        #p db.execute("SELECT anv_namn from Anvandare WHERE id = ? AND anv_namn = ?", i, user_name)["anv_namn"]


        #p db.execute("SELECT COUNT (id) FROM Anvandare WHERE anv_namn = ?", user_name).first["COUNT (id)"].to_i

        if db.execute("SELECT COUNT (id) FROM Anvandare WHERE anv_namn = ?", user_name).first["COUNT (id)"].to_i == 0
            
            db = SQLite3::Database.new("db/AD_DATA.db")
            db.execute("INSERT INTO Anvandare (anv_namn, kontakt_upg, losenord) VALUES (?,?,?)", user_name, tel_nr, password_krypterat)           

            flash[:notice] = "Ditt konto har skapats, nu kan du logga in."

            redirect ('/anvandare/login/')

        else

            flash[:notice] = "Användarnamnet #{user_name} är redan upptaget, prova med något annat anv_namn"
            redirect back

            # det där användarnamnet är redan upptaget, välj något annat. 

        end
            


            

    else
        
        flash[:notice] = "Du angav fel lösenord."
        redirect back
        
    end
end

get('/anvandare/success') do

    slim(:"anvandare/lyckat")

end

before('/sparade/') do
    if session[:anv_id] != nil
            
    else

        ej_inlogg_note()

    end
end

get('/sparade/') do

        anv_id = session[:anv_id]
        anropa_db
        result = @db.execute("SELECT * FROM Annonser WHERE id IN (SELECT Annons_id FROM User_saved_relation WHERE anv_id = #{session[:anv_id]})")

        slim(:"sparade/index", locals:{result:result})
                    
end

get('/anvandare/login/') do
    slim(:"anvandare/login")
end

before('/anvandare/:id/edit/') do

    id = params[:id].to_i

    if session[:anv_id] == id

    else
        hackerman()
    end

end


get('/anvandare/:id/edit/') do
    id = params[:id].to_i
    anropa_db
    result = @db.execute("SELECT DISTINCT anv_namn, kontakt_upg FROM Anvandare WHERE id = ?", id).first

    slim(:"anvandare/edit",locals:{result:result})
end

get('/anvandare/logout/') do
    session.destroy
    flash[:notice] = "Du har loggat ut!"

    redirect('/anvandare/login/')
end


before('/anvandare/login') do

    cooldown

end


post('/anvandare/login') do
    
    logga_in()
    
    
end