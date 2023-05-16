require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require "sinatra/reloader"
require 'sinatra/flash'
require_relative './model.rb' 

include Funktioner

enable :sessions


# en before route som kontrollerar att användaren är inloggad, om användaren inte är inloggad avvisar den försöket och ger ett felmeddelande ("du måste vara inloggad för att utför den här åtegärden.")
before all_of("/mina_annonser/", "/annonser/:id/spara", "/sparade/") do
   
    if session[:anv_id] != nil
            
    else
        ej_inlogg_note()
        redirect back
    end

    #kolla_behorighet

end

# kontrollerar att användaren (eller administratören) som försöker komma åt dessa routes är ägare av kontot eller är admin.
#params av routen (params[:id]) fungerar inte med "before all_of", därföe har jag tre identiska before routes, inte DRY, men enda lösningen för att få det att fungera. 
before ("/anvandare/:id/edit/") do
    if check_usr_auth(session[:anv_id], params[:id], session[:anv_id]) 
    else
        hackerman()
        redirect back
    end 
end

before ("/anvandare/:id/delete") do
    if check_usr_auth(session[:anv_id], params[:id], session[:anv_id]) 
    else
        hackerman()
        redirect back
    end     
end

before ("/anvandare/:id/update") do
    if check_usr_auth(session[:anv_id], params[:id], session[:anv_id]) 
    else
        hackerman()
        redirect back
    end  
end

# validerar input från formulären (längd på lösenord samt @ i e-mail) då en användare skapar ett konto eller redigerar kontot.
before all_of2("/anvandare", '/anvandare/*/update') do

    #p "en before route"
    email = params[:tel_nr]
    password = params[:password]

    #lösenord för kort, saknas @ i email
    if validate_email_password(email, password)

    else redirect back

    end

end

# Förstasidan, här ansätts användarnamnet som visas högst upp på sidan 
# @see Funktioner#inloggad_anv_namn
get('/') do
    @anv_namn = ""
    if session[:anv_id] != nil
        @anv_namn = inloggad_anv_namn(session[:anv_id])
    end
    slim(:main)
end


# visar alla annonser som finns sparade i databasen, 
# @see Funktioner#select_annons_data()
get('/annonser/') do
    #db = SQLite3::Database.new("db/AD_DATA.db")
    #db.results_as_hash = true
    anropa_db()

    result = select_annons_data()

    slim(:"annonser/index", locals:{result:result})
end

# Visar ettt formulär där användaren kan skapa en ny annons, välja/skriva in uppgifter om varan.
# @see Funktioner#select_kattegorier
get('/annonser/new') do
    
    anropa_db()

    result = select_kattegorier()
    slim(:"annonser/new", locals:{result:result})
end

# Här pressenteras all data om en annons, (efter att man har klickat på den)
# Pris, annonstext, bild, etc. dessutom visas en knapp om användaren vill spara annosnen samt ett räkneverk som visar hur många andra har sparat annonsen.
# 
# @see Funktioner#select_all_annons
# @see Funktioner#select_saved
# @see Funktioner#no_of_likes
# @see Funktioner#select_kontakt_upg
get('/annonser/:id') do
    id = params[:id].to_i
    anropa_db()

    result = select_all_annons(id)
    if session[:anv_id] != nil
        @anv_sparade = select_saved(session[:anv_id])
    end
    @antal_lajks = no_of_likes(id)

    @kontakt = select_kontakt_upg(id)

    slim(:"annonser/show", locals:{result:result})
end

# visar annonse skapade av den inloggade användaren (eller admin)
# 
# @see Funktioner#admin_or_not
# @see Funktioner#select_annonser
# @see Funktioner#select_owner_annonser
get('/mina_annonser/') do
   
    anropa_db()

    if admin_or_not(session[:anv_id])

        result = select_annonser()


    else 
        result = select_owner_annonser(session[:anv_id])

    end
    slim(:"hantera_annonser/index", locals:{result:result})

end

# Sparar en ny annons i databasen
# 
# @param [string] rubrik, Rubriken på annonsen
# @param [integer] pris, prist på varan som säljs
# @param [string] annonstext, beskrivande text under annonsen
# @param [integer] kattegori, Nummret (id) på den kattegori som varan tillhör.
# @param [integer] user_id, id't på användaren som äger annonsen.
# denna route sparat även en bild i /public/user_bilder om användaren har laddat upp en sådan.
# @see Funktioner#savetodb_annonser
post('/annonser') do
    rubrik = params[:titel]
    pris = params[:pris].to_i
    annonstext = params[:text]
    kattegori = params[:kattegori].to_i
    user_id =  session[:anv_id]

    #p user_id
    
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


# Tar bort en specifik annons från databasen 
# Tar även bort den reöaterade bilden om sådan finns
# 
# @param [integer] id, identifikationsnummret på den annons som ska tas bort.
# @see Funktioner#delete_image
# @see Funktioner#ta_veck_annons
post('/annonser/:id/delete') do    
    id = params[:id].to_i
    anropa_db()
    #p @db.execute("SELECT DISTINCT user_owner_id FROM Annonser WHERE id = ?", id).first
    #p @db.execute("SELECT DISTINCT bild FROM Annonser WHERE id = ?", id)


    delete_image(id)

    ta_veck_annons(id)
 
    redirect("/mina_annonser/")
end


# visar ett ifyllt formulär i vilken användaren kan redigera en annons.
# 
# @param [integer] id, identifikationsnummret på den annons som ska ändras.
# @see Funktioner#select_all_annons
get('/annonser/:id/edit') do
    id = params[:id].to_i
    anropa_db()
    result = select_all_annons(id)

    #p db.execute("SELECT DISTINCT user_owner_id FROM Annonser WHERE id = ?", id).first["user_owner_id"]

    slim(:"annonser/edit",locals:{result:result})

end



# Updaterar (ändrar) annonsdatan för en annons.
# 
# @param [string] rubrik, Rubriken på annonsen
# @param [integer] pris, prist på varan som säljs
# @param [string] annonstext, beskrivande text under annonsen
# @param [integer] kattegori, Nummret (id) på den kattegori som varan tillhör.
# @param [integer] user_id, id't på användaren som äger annonsen.
# denna route sparar även en bild i /public/user_bilder om användaren har laddat upp en sådan.
# @see Funktioner#update_annonser
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

# redigerar användarens upgifter.
# ändrar användarnman, e-postadress, och lösenord för en användare i databasen.
# 
# @param [string] user_name, användarnamn
# @param [string] tel_nr, e-postadress
# @param [string] password, första nya lösenordet
# @param [string] password2, andra (bekräftelsen) av nya lösenordet
# @param [string] gamla_password, det gamla lösenordet (krävs för att ändra till ett nytt lösenord.)
# @see Funktioner#create_new_crypt_password
# @see Funktioner#update_user_data
# @see Funktioner#update_user_psw
post('/anvandare/:id/update') do


    id = params[:id]
        
    user_name = params[:user_name]
    tel_nr = params[:tel_nr]
    password = params[:password]
    password2 = params[:password2]
    gamla_password = params[:gamla_password]


    anropa_db()

    psw_krypterad = select_psw(id)
    
    #p create_new_crypt_password(psw_krypterad)
    #p gamla_password
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


   
# tar bort en användare ifrån databasen
# tar även bort sesson med sesion.destroy
# 
# @param [integer] id, id för anvädaren som ska tas bort
# @see Funktioner#anv_delete
post('/anvandare/:id/delete') do 
    id = params[:id].to_i

    anropa_db()

    anv_delete(id)

    session.destroy

    redirect("/anvandare/login/")
end



# sparar en favoritannons i relationstabellen.
# @param [integer] annons_id, id för annonsen som ska sparas
# @see Funktioner#saveto_relation
post('/annonser/:id/spara') do

    if session[:anv_id] != nil
        annons_id = params[:id].to_i
        anv_id = session[:anv_id]
        #p anv_id
        anropa_db()
        saveto_relation(anv_id, annons_id)
        redirect("/annonser/#{annons_id}")
    else
        ej_inlogg_note()
    end
    redirect back


end

# tar bort en favoritannons ifrån relationstabellen.
# @param [integer] annons_id, id för annonsen som ska sparas
# @see Funktioner#rm_fav
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

# visar ett formulär där en ny användare kan registrera sitt konto.
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



# Sparar en ny användare i databasen 
# Kontrollerar om det valda användarnamnet är upptaget, om så är fallet skickas ett felmeddelande.
# sparar den nya användaren och redirectar sedan till login där användaren kan logga in på sitt nya konto.
# before routen för denna route validerar lösenordet och e-postadressen.
#
# @param [string] user_name, användarnamn
# @param [string] tel_nr, e-postadress
# @param [string] password, användarens påhittade lösenorde
# 
# @see Funktioner#create_new_crypt_password
# @see Funktioner#saved_by_user_or_not
# @see Funktioner#savetodb_anvandare
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

        #det där användarnamnet är redan upptaget, välj något annat. 

    end
            

end



# visar en lista med en användares alla sparade favoriannonser.
# 
# @param [integer] anv_id, id't på den användaren vars favoritannonser ska tas fram.
# @see Funktioner#select_user_saved_relation
get('/sparade/') do

    anv_id = session[:anv_id]
    anropa_db
    result = select_user_saved_relation(session[:anv_id])
    
    slim(:"sparade/index", locals:{result:result})
                    
end


# visar ett litet formulär där anvädaren kan logga in.
# här kan användaren skriva sinn anv-namn och lösenord.
get('/anvandare/login/') do
    slim(:"anvandare/login")
end



# Ett ifyllt formulär där användaren kan redigera sina användar uppgifter (namn, mailadress, och lösenord.)
# 
# @param [integer] id, id nummer på det användarkonto som ska redigeras
get('/anvandare/:id/edit/') do
    id = params[:id].to_i
    @edit_id = id
    anropa_db
    @delete_id = id
    slim(:"anvandare/edit",locals:{result:edit_usr_form_data(id)})
end

# här kan man logga ut.
# 
# @see Funktioner#utloggad
get('/anvandare/logout/') do
    session.destroy
    utloggad()
    redirect('/anvandare/login/')
end


before('/anvandare/login') do

    if session[:inlogg_tid] != nil
        if session[:inlogg_tid]+10 > Time.new
            cooldown_note()
            redirect('/anvandare/login/')
        end

    end

end

# Kontrollerar om inloggningsuppgifterna stämmer med de sparade uppgifterna i databasen.
# ansätter även session[:inlogg_tid] tinn nuvarande tid, med syfte att möjliggöra cooldown.
#
# @param [string] user_name, användarnamnet som angavs i inlogg-formuläret. 
# @param [string] password, lösenordet som angavs i inlogg-formuläret. 
# @see Funktioner#select_user_login
# @see Funktioner#check_psw
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