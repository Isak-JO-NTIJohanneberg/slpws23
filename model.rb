def anropa_db()

    @db = SQLite3::Database.new("db/AD_DATA.db")
    @db.results_as_hash = true

end

def hackerman()

    flash[:notice] = "Hörredu Hackerman, Du har inte behörighet att utföra den här återgärden"

end

def ej_inlogg_note()

    
    flash[:notice] = "Du måste vara inloggad för att utföra den här återgärden"
    
end

def validate_password_note()

    
    flash[:notice] = "Lösenordet är inte starkt nog, det måste innehålla minst 3 tecken"
    
end

def validate_email_note()

    
    flash[:notice] = "Felaktig e-post adress, ange en adress som innehåller @"
    
end

def cooldown_note()


    flash[:notice] = "Vänta 10 sekunder innan du försöker logga in igen."
    redirect('/anvandare/login/')



end


def cooldown()
    if session[:inlogg_tid] != nil
        if session[:inlogg_tid]+10 > Time.new
            cooldown_note()
        end

    end
end

def logga_in()
    

end


def check_auth_user_or_admin(id)

    anropa_db()
    if session[:anv_id] == @db.execute("SELECT DISTINCT id FROM Anvandare WHERE admin = 1").first["id"]
        return true

    elsif session[:anv_id] == @db.execute("SELECT DISTINCT user_owner_id FROM Annonser WHERE id = ?", id).first["user_owner_id"]
        return true

    else 
        return false

    end

end
#behörigheter


def ta_veck_annons(id)

    @db.execute("DELETE FROM Annonser WHERE id = ?", id)

    @db.execute("DELETE FROM User_saved_relation WHERE annons_id = ?", id)

end

def anv_delete(id)


    @db.execute("DELETE FROM Anvandare WHERE id = ?", id)

    @db.execute("DELETE FROM User_saved_relation WHERE anv_id = ?", id)

    @db.execute("DELETE FROM Annonser WHERE user_owner_id = ?", id)



end

def utloggad()

    session.destroy
    flash[:notice] = "Du har loggat ut!"


end


#def kolla_behorighet(havd, krävs)

 #   if havd = krävs 


  #  else

   #     ej_inlogg_note


#nd



def all_of(*strings)
    return /(#{strings.join("|")})/
end

def all_of2(*strings2)
    #p "/(#{strings2.join("|")})/"
    return /(#{strings2.join("|")})/
end
   
def select_user_login()
    @result = @db.execute("SELECT * FROM Anvandare WHERE anv_namn = ?", @user_name).first
end

def check_psw(password)
    psw_krypterad = @result["losenord"]
    return password_okrypterat=BCrypt::Password.new(psw_krypterad) == password
end

def edit_usr_form_data(id)
    return @db.execute("SELECT DISTINCT anv_namn, kontakt_upg FROM Anvandare WHERE id = ?", id).first
end

def check_usr_auth(had, needed)

    if had == needed.to_i
    
    elsif
        
        if session[:anv_id] != nil
            check_auth_user_or_admin(needed)
        end

    else

        hackerman()
        redirect back

    end
end

def inloggad_anv_namn 
    anropa_db()
    @db.execute("SELECT DISTINCT anv_namn FROM Anvandare WHERE id = ?", session[:anv_id]).first["anv_namn"]
end

def validate_email_password(email, password)

    if password.length < 3
        validate_password_note()
        return false
    end

    email.each_char do |tecken|
        if tecken == "@"
            return true
        else 
        end
    end
    validate_email_note()
    return false

end

#db i models

def savetodb_annonser(rubrik, pris, annonstext, user_id, kattegori, bild_filnamn)
    @db.execute("INSERT INTO Annonser (rubrik, pris, annons_text, user_owner_id, kattegori_id, bild) VALUES (?,?,?,?,?,?)", rubrik, pris, annonstext, user_id, kattegori, bild_filnamn)  
    
end

def saveto_relation(anv_id, annons_id)

    @db.execute("INSERT INTO User_saved_relation (anv_id, annons_id) VALUES (?,?)", anv_id, annons_id)

end

def savetodb_anvandare(user_name, tel_nr, password_krypterat)

    @db.execute("INSERT INTO Anvandare (anv_namn, kontakt_upg, losenord) VALUES (?,?,?)", user_name, tel_nr, password_krypterat)
    
end

def delete_image(id)

    if @db.execute("SELECT DISTINCT bild FROM Annonser WHERE id = ?", id).first["bild"] != nil 
        bild_filnamn = @db.execute("SELECT DISTINCT bild FROM Annonser WHERE id = ?", id).first["bild"]

        File.delete("./public/user_bilder/#{bild_filnamn}")

    end

end

def select_all_annons(id)
    
    @kattegorier = @db.execute("SELECT * FROM Kattegorier")

    return @db.execute("SELECT * FROM Annonser WHERE id = ?", id).first
end

def update_annonser(rubrik, pris, annonstext, kattegori, bild_filnamn, id)

    @db.execute("UPDATE Annonser SET rubrik=?, pris=?, annons_text=?, kattegori_id=?, bild=? WHERE id=?", rubrik, pris, annonstext, kattegori, bild_filnamn, id)  
    
end

def select_psw(id)

    return @db.execute("SELECT DISTINCT Losenord FROM Anvandare WHERE id = ?", id).first["losenord"]


end

def update_user_data(user_name, tel_nr, id)

    @db.execute("UPDATE Anvandare SET anv_namn=?, kontakt_upg=? WHERE id=?", user_name, tel_nr, id)

end

def update_user_psw(user_name, tel_nr, password_krypterat, id) 
    @db.execute("UPDATE Anvandare SET anv_namn=?, kontakt_upg=?, losenord=? WHERE id=?", user_name, tel_nr, password_krypterat, id)  
end
        
def rm_fav(annons_id, anv_id)
    @db.execute("DELETE FROM User_saved_relation WHERE annons_id = ? AND anv_id =?", annons_id, anv_id)
end

def saved_by_user_or_not(user_name)
   return @db.execute("SELECT COUNT (id) FROM Anvandare WHERE anv_namn = ?", user_name).first["COUNT (id)"].to_i == 0
end

def select_user_saved_relation()
    return @db.execute("SELECT * FROM Annonser WHERE id IN (SELECT Annons_id FROM User_saved_relation WHERE anv_id = #{session[:anv_id]})")
end
def select_annons_data()
    return @db.execute("SELECT DISTINCT rubrik, id, pris FROM Annonser")
end
def select_kattegorier()
    return @db.execute("SELECT * FROM Kattegorier")
end

def select_saved()
    return @db.execute("SELECT Annons_id FROM User_saved_relation WHERE anv_id = #{session[:anv_id]}")
end

def no_of_likes(id)
    return @db.execute("SELECT COUNT (Annons_id) FROM User_saved_relation WHERE Annons_id = ?", id).first
end

def select_kontakt_upg(id)

    return @db.execute("SELECT kontakt_upg FROM Anvandare WHERE id IN (SELECT User_owner_id FROM Annonser WHERE id = ?)", id).first["kontakt_upg"]

end

def admin_or_not()
    return @db.execute("SELECT DISTINCT admin FROM Anvandare WHERE id = ?", session[:anv_id]).first["admin"] == 1
end

def select_annonser()

    return @db.execute("SELECT * FROM Annonser")

end

def select_owner_annonser()
    return @db.execute("SELECT * FROM Annonser WHERE user_owner_id = ?", session[:anv_id])
end
def create_new_crypt_password(password)
    return BCrypt::Password.create(password)
end

def psw_check(gamla_password, psw_krypterad)

    password_okrypterat=BCrypt::Password.new(psw_krypterad) == gamla_password

end