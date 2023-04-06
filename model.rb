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