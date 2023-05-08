require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require "sinatra/reloader"
require 'sinatra/flash'
require_relative './model.rb' 

enable :sessions



#before do 

 #   restricted_path = = []

#end
before all_of("/mina_annonser/", "/annonser/:id/spara", "/sparade/") do
   
    if session[:anv_id] != nil
            
    else
        ej_inlogg_note()
        redirect back
    end

    #kolla_behorighet

end

before ("/anvandare/:id/edit/") do
    check_usr_auth(session[:anv_id], params[:id])  
end

before ("/anvandare/:id/delete") do
    check_usr_auth(session[:anv_id], params[:id])    
end

before ("/anvandare/:id/update") do
    check_usr_auth(session[:anv_id], params[:id])     
end
# params av routen (params[:id] fungerar inte med "before all_of"), därföe har jag tre identiska before routes, inte dry, men enda lösningen för att få det att fungera. 


before all_of2("/anvandare", '/anvandare/*/update') do

    p "en before route"
    email = params[:tel_nr]
    password = params[:password]

    #lösenord för kort, saknas @ i email
    if validate_email_password(email, password)

    else redirect back

    end

end


get('/') do
    @anv_namn = ""
    if session[:anv_id] != nil
        @anv_namn = inloggad_anv_namn
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

    result = select_annons_data()

    slim(:"annonser/index", locals:{result:result})
end

get('/annonser/new') do
    
    anropa_db()

    result = select_kattegorier()
    slim(:"annonser/new", locals:{result:result})
end

get('/annonser/:id') do
    id = params[:id].to_i
    anropa_db()

    result = select_all_annons(id)
    if session[:anv_id] != nil
        @anv_sparade = select_saved()
    end
    @antal_lajks = no_of_likes(id)

    @kontakt = select_kontakt_upg(id)

    slim(:"annonser/show", locals:{result:result})
end


get('/mina_annonser/') do
   
    anropa_db()

    if admin_or_not()

        result = select_annonser()


    else 
        result = select_owner_annonser()

    end
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

    savetodb_annonser(rubrik, pris, annonstext, user_id, kattegori, bild_filnamn)

    redirect("/annonser/")


end



post('/annonser/:id/delete') do    
    id = params[:id].to_i
    anropa_db()
    #p @db.execute("SELECT DISTINCT user_owner_id FROM Annonser WHERE id = ?", id).first
    #p @db.execute("SELECT DISTINCT bild FROM Annonser WHERE id = ?", id)


    delete_image(id)

    ta_veck_annons(id)
 
    redirect("/mina_annonser/")
end


get('/annonser/:id/edit') do
    id = params[:id].to_i
    anropa_db()
    result = select_all_annons(id)

    #p db.execute("SELECT DISTINCT user_owner_id FROM Annonser WHERE id = ?", id).first["user_owner_id"]

    slim(:"annonser/edit",locals:{result:result})

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
    
    anropa_db

    #p db.execute("SELECT DISTINCT User_owner_id FROM Annonser WHERE id = ?", id).first["user_owner_id"]

    update_annonser(rubrik, pris, annonstext, kattegori, bild_filnamn, id)
    
    redirect("/mina_annonser/")
   

end

post('/anvandare/:id/update') do


    id = session[:anv_id]
        
    user_name = params[:user_name]
    tel_nr = params[:tel_nr]
    password = params[:password]
    password2 = params[:password2]
    gamla_password = params[:gamla_password]


    anropa_db()

    psw_krypterad = select_psw(id)
    
    p create_new_crypt_password(psw_krypterad)
    p gamla_password
    if password == "" 

        update_user_data(user_name, tel_nr, id)

    elsif password == password2 && psw_check(gamla_password, psw_krypterad)

        password_krypterat = create_new_crypt_password(password)

        update_user_psw(user_name, tel_nr, password_krypterat, id) 
        


    else 


        flash[:notice] = "Du angav fel lösenord."



    end

    redirect back


end


   

post('/anvandare/:id/delete') do 
    id = params[:id].to_i

    anropa_db()

    anv_delete(id)

    session.destroy

    redirect("/anvandare/login/")
end




post('/annonser/:id/spara') do

    annons_id = params[:id].to_i
    anv_id = session[:anv_id]
    p anv_id
    anropa_db()
    saveto_relation(anv_id, annons_id)
    redirect("/annonser/#{annons_id}")
    redirect back


end

post('/annonser/:id/rm_fav') do
    annons_id = params[:id].to_i
    anv_id = session[:anv_id]
    anropa_db
    if anv_id != nil
        rm_fav(annons_id, anv_id)
    else
        hackerman()
        redirect back

    end
    redirect back
end

get('/anvandare/new/') do
    slim(:"anvandare/register")
end

before('/anvandare') do

    if params[:password] == params[:password2] 
        

    else
        
        flash[:notice] = "Du angav fel lösenord."
        redirect back
        
    end

end




post('/anvandare') do

   

    #validera input med funktion



    anropa_db

    user_name = params[:user_name]
    tel_nr = params[:tel_nr]
    password = params[:password]

    password_krypterat = create_new_crypt_password(password)

    #p db.execute("SELECT anv_namn from Anvandare WHERE id = ? AND anv_namn = ?", i, user_name)["anv_namn"]


    #p db.execute("SELECT COUNT (id) FROM Anvandare WHERE anv_namn = ?", user_name).first["COUNT (id)"].to_i

    if saved_by_user_or_not(user_name)
        
        anropa_db()
        savetodb_anvandare(user_name, tel_nr, password_krypterat)

        flash[:notice] = "Ditt konto har skapats, nu kan du logga in."

        redirect ('/anvandare/login/')

    else

        flash[:notice] = "Användarnamnet #{user_name} är redan upptaget, prova med något annat anv_namn"
        redirect back

        # det där användarnamnet är redan upptaget, välj något annat. 

    end
            

end

get('/anvandare/success') do

    slim(:"anvandare/lyckat")

end


get('/sparade/') do

        anv_id = session[:anv_id]
        anropa_db
        result = select_user_saved_relation()
        
        slim(:"sparade/index", locals:{result:result})
                    
end

get('/anvandare/login/') do
    slim(:"anvandare/login")
end




get('/anvandare/:id/edit/') do
    id = params[:id].to_i
    anropa_db
    @delete_id = id
    slim(:"anvandare/edit",locals:{result:edit_usr_form_data(id)})
end

get('/anvandare/logout/') do
    utloggad()
    redirect('/anvandare/login/')
end


before('/anvandare/login') do

    cooldown

end


post('/anvandare/login') do
        
    session[:inlogg_tid] = Time.new
    @user_name = params[:user_name]
    password = params[:password]
    anropa_db()
    select_user_login()

    if @result != nil
        
        id = @result["id"]
        #p id

        if check_psw(password)
    
            #p "användarid: #{session[:anv_id]}"
            session[:anv_id] = id
            redirect back
        else
    
            flash[:notice] = "Jag tror du angav fel lösenord."
            redirect back
            
        end

    else
        
        flash[:notice] = "Jag tror du angav fel användarnamn."
        redirect back

    end 
    
end