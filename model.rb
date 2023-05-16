
# min funktions-modul, här har jag lagt alla hjälpfunktioner som mitt program (app.rb) använder sig av.
module Funktioner

    # anropar(initsierar databasen)
    # detta krävs före varje db.execute, därför är det bra o ha det som en funktion.
    def anropa_db()

        @db = SQLite3::Database.new("db/AD_DATA.db")
        @db.results_as_hash = true

    end

    # ger ett felmeddelande då någon försöker komma åt en route som de inte har behörighet till.
    def hackerman()

        flash[:notice] = "Hörredu Hackerman, Du har inte behörighet att utföra den här återgärden"

    end

    # ger ett felmeddelande då användaren försöker göra något (spara annonser) som kräver att användaren är inloggad på ett konto.
    def ej_inlogg_note()

        
        flash[:notice] = "Du måste vara inloggad för att utföra den här återgärden"
        
    end

    # ger ett felmeddelande vilket säger att det angivan lösenordet är för kort.
    def validate_password_note()

        
        flash[:notice] = "Lösenordet är inte starkt nog, det måste innehålla minst 3 tecken"
        
    end

    # ger ett felmeddelande då e-postadressen inte uppfyller valideringen. 
    def validate_email_note()

        
        flash[:notice] = "Felaktig e-post adress, ange en adress som innehåller @"
        
    end

    # felmeddelande då användaren försöker "brute-force:a" sig in på ett anväändarkonto.
    def cooldown_note()


        flash[:notice] = "Vänta 10 sekunder innan du försöker logga in igen."
        redirect('/anvandare/login/')



    end

    # en funktion som korntrollerar om användaren nyligen (inom de senaste 10 sekundrarna) har försök logga in (cooldown). 
    # Om så är fallet avböjd inloggningsförsöket och användaren får ett felmeddelande
    # @see Funktioner#cooldown_note
    def cooldown()
        if session[:inlogg_tid] != nil
            if session[:inlogg_tid]+10 > Time.new
                cooldown_note()
            end

        end
    end

    # Kontrollerar om den inloggade användaren har redigeringsbehörighet till en annons.
    # Kontrollerar om den inloggade användaren är ägeren till annonsen, eller om den inloggade användaren är admin.
    # @return [boolean]
    # @param [integer], användarid som krävs för återgärden. 
    def check_auth_user_or_admin(id)

        anropa_db()

        if session[:anv_id] != nil

            if session[:anv_id] == @db.execute("SELECT DISTINCT id FROM Anvandare WHERE admin = 1").first["id"]
                return true

            elsif session[:anv_id] == @db.execute("SELECT DISTINCT user_owner_id FROM Annonser WHERE id = ?", id).first["user_owner_id"]
                return true

            else 
                return false

            end
        else 

            return false 

        end

    end

    # Kontrollerar om den inloggade användaren har redigeringsbehörighet till ett konto.
    # Kontrollerar om den inloggade användaren är ägeren till kontot, eller om den inloggade användaren är admin.
    # @return [boolean]
    def check_auth_if_admin(id)

        anropa_db()

        if session[:anv_id] != nil

            if session[:anv_id] == @db.execute("SELECT DISTINCT id FROM Anvandare WHERE admin = 1").first["id"]
                return true

            else 
                return false

            end
        else 

            return false 

        end

    end
    #behörigheter

    # Tar bort en annons från databasen
    # Tar även bort den relaterade datan ifrån relationstabellen där den borttagna annonsens id ingår.
    # @param [integer], annonsid på den annons som ska tas bort.
    def ta_veck_annons(id)

        @db.execute("DELETE FROM Annonser WHERE id = ?", id)

        @db.execute("DELETE FROM User_saved_relation WHERE annons_id = ?", id)

    end

    # Tar bort en användare från databasen.
    # Tar även bort de annonser som ägas av användaren, samt datan i relationstabelen (sparade annonser) där användaren ingår.
    # @param [integer], anv_id på den anvandare som ska tas bort.
    def anv_delete(id)


        @db.execute("DELETE FROM Anvandare WHERE id = ?", id)

        @db.execute("DELETE FROM User_saved_relation WHERE anv_id = ?", id)

        @db.execute("DELETE FROM Annonser WHERE user_owner_id = ?", id)



    end

    # Loggar ut från kontot.
    # avslutar aktiva browser-sessions och ger ett bekräftelsemeddelande åt användaren där den har loggat ut. 
    def utloggad()

        session.destroy
        flash[:notice] = "Du har loggat ut!"


    end

    # En funktion som sätter ihop flera routes, används i before routen.
    # @param [string] , Flera strängar som input, dessa ska sättas ihop.
    # @return [string], ett ihopkok av de strängar som havs som input. 
    def all_of(*strings)
        return /(#{strings.join("|")})/
    end

    
    # En funktion som sätter ihop flera routes, används i before routen.
    # @param [string] , Flera strängar som input, dessa ska sättas ihop.
    # @return [string], ett ihopkok av de strängar som havs som input. 
    def all_of2(*strings2)
        #p "/(#{strings2.join("|")})/"
        return /(#{strings2.join("|")})/
    end
    
    # En funktion som hämtar all tillgänglig användardata och ansetter detta till den globala variabeln result.
    # Använs för att kontrollerar om inloggningsuppgifter stämmer vid inloggning. 
    def select_user_login()
        @result = @db.execute("SELECT * FROM Anvandare WHERE anv_namn = ?", @user_name).first
    end

    # Kontrollerar om användarens inmatade lösenord stämmer överens med det lösenord som finns sparat i databasen (i krypterad form).
    # @param[string] , lösenordet som användaren har angivit på inloggningssidan.
    # @return [boolean]
    def check_psw(password)
        psw_krypterad = @result["losenord"]
        return password_okrypterat=BCrypt::Password.new(psw_krypterad) == password
    end

    # Hämtar all anvädardata från databasen som skall finnas med i det ifyllda formuläret på "redigera användare" sidan. 
    # @param [integer], id på den användaren vilken vi ska hämta datan.
    # @return [hash], hashad användardata från databasen.
    def edit_usr_form_data(id)
        return @db.execute("SELECT DISTINCT anv_namn, kontakt_upg FROM Anvandare WHERE id = ?", id).first
    end

    # Kontrollerar om den inloggade användaren har samma behörighet som krävs för att få åtkomst till sidan 
    # kontrollerar om needed är samma som had
    # om inte den inloggade användern är rätt så kontrollerar den som den inloggade användaren är admin
    # @see Funktioner#check_auth_user_or_admin
    # Om ingen av de stämmer: anropet avböjs och användaren får ett felmeddelande som säger att den inte har behörighet till sidan
    # @see Funktioner#hackerman
    # @param [integer] had idt som använadren har
    # @param [integer] needed idt krävs för att få åtkomst till sidan
    def check_usr_auth(had, needed)

        if had == needed.to_i
        
        elsif session[:anv_id] != nil
            
         
            if check_auth_if_admin(needed.to_i)

            else
                hackerman()
                redirect back
            end
        

        else

            hackerman()
            redirect back

        end
    end

    # tar fram namnet på den användare som är inloggad för tillfället. 
    # namnet pressenteras sedan högst upp på sidan.
    # @return [string]
    def inloggad_anv_namn 
        anropa_db()
        @db.execute("SELECT DISTINCT anv_namn FROM Anvandare WHERE id = ?", session[:anv_id]).first["anv_namn"]
    end

    # validerar lösenordet och e-postadressen, 
    # Kontrollerar om e-postadressen innegåller ett "@" och att lösenordet består av minst tre tecken. 
    # använder hjälpfunktioer för att skicka felmeddelanden om valideringen falerar på någon aspekt.
    # @see Funktioner#validate_password_note
    # @see Funktioner#validate_email_note
    # @return [boolean]
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

    
    # Sparar en ny annons i databasen
    # @param [string] rubrik annonsrubrik
    # @param [integer] pris priset på varan
    # @param [string] annonstext Beskrivning av varan
    # @param [integer] user_id id på anvaändaren som äger annonsen.
    # @param [integer] kattegori id på den kattegori som annonsen tillhör
    # @param [string] bild_filnamn finamnet på annonsbildet som har sparats i public-mappen
    def savetodb_annonser(rubrik, pris, annonstext, user_id, kattegori, bild_filnamn)
        @db.execute("INSERT INTO Annonser (rubrik, pris, annons_text, user_owner_id, kattegori_id, bild) VALUES (?,?,?,?,?,?)", rubrik, pris, annonstext, user_id, kattegori, bild_filnamn)  
        
    end

    # lägger till en ny entry i relationstabellen mellan annonser och användare.
    # Här sparas data då användaren trycker på "spara i favoritlistan"
    # @param [integer] anv_id id på anvaändaren som sparar annonsen.
    # @param [integer] annons_id id på annonsen som ska läggas till i favoriter.
    def saveto_relation(anv_id, annons_id)

        @db.execute("INSERT INTO User_saved_relation (anv_id, annons_id) VALUES (?,?)", anv_id, annons_id)

    end

    # läger till en ny användare i databasen.
    # sparar användarnamn, kontaktuppgifter och lösenord som en ny entry i databasen.
    # @param [string] user_name anvädarnamnet som den nya användaren skriver in. 
    # @param [string] tel_nr e-postadresson som den nya användaren skriver in. 
    # @param [string] password_krypterat lösenordet som den nya användaren skriver in. 
    def savetodb_anvandare(user_name, tel_nr, password_krypterat)

        @db.execute("INSERT INTO Anvandare (anv_namn, kontakt_upg, losenord) VALUES (?,?,?)", user_name, tel_nr, password_krypterat)
        
    end

    # Tar bort en bild tillhörande en specifik annons med id "id" från public mappen.
    # Frågar databasen vad filnamnet till annonsbilden är, därefter tar funktionen bort filen med det filnamnet.
    # @param [integer] id id nummret på den annons som vi önskar ta bort bilden.
    def delete_image(id)

        if @db.execute("SELECT DISTINCT bild FROM Annonser WHERE id = ?", id).first["bild"] != nil 
            bild_filnamn = @db.execute("SELECT DISTINCT bild FROM Annonser WHERE id = ?", id).first["bild"]

            File.delete("./public/user_bilder/#{bild_filnamn}")

        end

    end

    # Hämtar all data om en annons,
    # hämtar även tilgängliga kattegorier, i de fall datan ska användas i ett redigeringsformulär.
    # @return [hash] 
    def select_all_annons(id)
        
        @kattegorier = @db.execute("SELECT * FROM Kattegorier")

        return @db.execute("SELECT * FROM Annonser WHERE id = ?", id).first
    end

    # Skriver förädringar till databasen efter att användaren har valt att ändra parametrar i en annons.
    # @param [string] rubrik annonsrubrik
    # @param [integer] pris priset på varan
    # @param [string] annonstext Beskrivning av varan
    # @param [integer] id id på annonsen som ska ändras.
    # @param [integer] kattegori id på den kattegori som annonsen tillhör
    # @param [string] bild_filnamn finamnet på annonsbildet som har sparats i public-mappen 
    def update_annonser(rubrik, pris, annonstext, kattegori, bild_filnamn, id)

        @db.execute("UPDATE Annonser SET rubrik=?, pris=?, annons_text=?, kattegori_id=?, bild=? WHERE id=?", rubrik, pris, annonstext, kattegori, bild_filnamn, id)  
        
    end

    # Tar fram och returnerar det krypterade lösenordet för en specifik användare
    # @param [integer] id id på användaren
    # @return [string]
    def select_psw(id)

        return @db.execute("SELECT DISTINCT Losenord FROM Anvandare WHERE id = ?", id).first["losenord"]


    end

    # Skriver förändrngar av användardata till databasen då användaren väljer att redigera sin uppgifter.
    # @param [string] user_name anvädarnamnet som den nya användaren skriver in. 
    # @param [string] tel_nr e-postadresson som den nya användaren skriver in. 
    # @param [integer] id id på användaren som vill redigera kontot.
    def update_user_data(user_name, tel_nr, id)

        @db.execute("UPDATE Anvandare SET anv_namn=?, kontakt_upg=? WHERE id=?", user_name, tel_nr, id)

    end

    # Skriver förändrngar av användardata till databasen då användaren väljer att byta lösenord.
    # @param [string] user_name anvädarnamnet som den nya användaren skriver in. 
    # @param [string] tel_nr e-postadresson som den nya användaren skriver in. 
    # @param [string] password_krypterat lösenordet som den nya användaren skriver in. 
    # @param [integer] id id på användaren som vill redigera kontor eller byta lösenord.
    def update_user_psw(user_name, tel_nr, password_krypterat, id) 
        @db.execute("UPDATE Anvandare SET anv_namn=?, kontakt_upg=?, losenord=? WHERE id=?", user_name, tel_nr, password_krypterat, id)  
    end
    
    # tar bort en entry från relationstabellen i databasen.
    # när användaren väljer att ta bort en annons från favoritlistan tas många-många-relationen bort från relationstabellen.
    # @param [integer] anv_id id på anvaändaren som ska ta bort annonsen från sin favoritlista.
    # @param [integer] annons_id id på annonsen som ska tas bort från favoriter.
    def rm_fav(annons_id, anv_id)
        @db.execute("DELETE FROM User_saved_relation WHERE annons_id = ? AND anv_id =?", annons_id, anv_id)
    end

    # Kontrollerar om lösenordet är upptaget eller inte. 
    # Kollar hur många entries det finns i databasens "anvandare tabell" med samma användarnamn som det angivna i registreringsformuläret.
    # @param [string] user_name anvädarnamnet som den nya användaren vill ta vid registrering.
    # @return [boolean] 
    def saved_by_user_or_not(user_name)
    return @db.execute("SELECT COUNT (id) FROM Anvandare WHERE anv_namn = ?", user_name).first["COUNT (id)"].to_i == 0
    end

    # hämtar all annonsdata från de annonser som den inloggade användaren har sparat.
    # @return [array]
    def select_user_saved_relation()
        return @db.execute("SELECT * FROM Annonser WHERE id IN (SELECT Annons_id FROM User_saved_relation WHERE anv_id = #{session[:anv_id]})")
    end

    # Hämtar rubrik, id och pris från alla annonser.
    # pressenteras i "visa annonser" sidan
    # @return [array]
    def select_annons_data()
        return @db.execute("SELECT DISTINCT rubrik, id, pris FROM Annonser")
    end

    # Hämtar alla tillgängliga kattergorier,
    # som användaren kan välja då de skapar eller redigerar en annons.
    # Används i formulären för "new" eller "edit" på annonser.
    # @return [array] 
    def select_kattegorier()
        return @db.execute("SELECT * FROM Kattegorier")
    end

    # Hämtar id på de annonser som den nuvarande användaren har sparat i sin favoritlista.
    # används på "sparade annonser" där användare n kan bläddra bland de annonser som den har sparat.
    # @return [array]
    def select_saved()
        return @db.execute("SELECT Annons_id FROM User_saved_relation WHERE anv_id = #{session[:anv_id]}")
    end

    # Räknar antalet användare som har sparat en specifik annons i relationstabellen.
    # används i räknerverket på "annonse/show" där det står "sparad av XX andra användare"
    # @param [integer] id för den annons på vilken vi vill räkna antalet likes.
    # @return [integer]
    def no_of_likes(id)
        return @db.execute("SELECT COUNT (Annons_id) FROM User_saved_relation WHERE Annons_id = ?", id).first
    end

    # Hämtar e-postadressen till ägaren för en annons.
    # @param [integer] id, annons-id till den annons vi vill ha ägarens e-postadress.
    # @return [string]
    def select_kontakt_upg(id)

        return @db.execute("SELECT kontakt_upg FROM Anvandare WHERE id IN (SELECT User_owner_id FROM Annonser WHERE id = ?)", id).first["kontakt_upg"]

    end

    # kontrollerar om den inloggade användaren är administratör. 
    # @return [boolean]
    def admin_or_not()
        return @db.execute("SELECT DISTINCT admin FROM Anvandare WHERE id = ?", session[:anv_id]).first["admin"] == 1
    end

    # Hämtar all data om alla annonser
    # Detta används på "visa annonser"-sidan där pris, rubrik, etc visas.
    # @return [array]
    def select_annonser()

        return @db.execute("SELECT * FROM Annonser")

    end

    # Hämtar all data om de annonser som den inloggade användaren äger.
    # detta använs på "hantera mina annonser" - sidan.
    # @return [array]
    def select_owner_annonser()
        return @db.execute("SELECT * FROM Annonser WHERE user_owner_id = ?", session[:anv_id])
    end

    # returnerar ett ett krypterat och saltat lösenord, med ett okrypterar lösenord som argument. 
    # @return [string]
    # @param [string] password ett okrypterat lösenord
    def create_new_crypt_password(password)
        return BCrypt::Password.create(password)
    end

    # Kontrollerar om ett angivet lösenord stämmer överens med det krypteade lösenordet som finns sparat i databasen
    # @param [string] gamla_password ett okrpterat lösenord som användaren matar in vid tex inloggning.
    # @param [string] psw_krypterad ett kryperat lösenord från databasen som skall jämföras med det inmatade.
    # @return [boolean]
    def psw_check(gamla_password, psw_krypterad)

        password_okrypterat=BCrypt::Password.new(psw_krypterad) == gamla_password

    end

end