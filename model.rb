def anropa_db()

    @db = SQLite3::Database.new("db/AD_DATA.db")
    @db.results_as_hash = true

end

def hackerman()

    flash[:notice] = "Hörredu Hackerman, Du har inte behörighet att utföra den här återgärden"
    redirect back

end

def ej_inlogg_note()

    
    flash[:notice] = "Du måste vara inloggad för att utföra den här återgärden"
    redirect back


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
    session[:inlogg_tid] = Time.new

    user_name = params[:user_name]
    tel_nr = params[:tel_nr].to_i
    password = params[:password]

    db = SQLite3::Database.new("db/AD_DATA.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM Anvandare WHERE anv_namn = ?", user_name).first
    if result != nil
        psw_krypterad = result["losenord"]
        id = result["id"]
        p id
        session[:anv_id] = id

        if password_okrypterat=BCrypt::Password.new(psw_krypterad) == password
    
        p "användarid: #{session[:anv_id]}"
    
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


#behörigheter