##############################################################################
#.Synopsis 
#    Generates a complex password of the specified length and text encoding. 
#
#.Description 
#    Generates a random password using only common ASCII code numbers.  The
#    password will be four characters in length at a minimum so that it may
#    contain at least one of each of the following character types: uppercase,
#    lowercase, number and password-legal non-alphanumerics.  To make the 
#    output play nice, the following characters are excluded from the
#    output password string: extended ASCII, spaces, #, ", `, ', /, 0, O.
#    Also, the function prevents any two identical characters in a row.
#    The output should be compatible with any code page or culture when
#    an appropriate encoding is chosen.  Because of how certain characters
#    are excluded, the randomness of the password is slightly lower, hence,
#    the length may need to be increased to achieve a particular entropy.
#
#.Parameter Length
#    Length of password to be generated.  Minimum is 4.  Default is 15.
#    Complexity requirements force a minimum length of 4 characters.
#    Maximum is 2,147,483,647 characters.
#
#.Parameter Encoding
#    The encoding of the output string. Must be one of these:
#
#        ASCII
#        UTF8
#        UNICODE
#        UTF16
#        UTF16-LE
#        UTF32
#        UTF16-BE
#
#    The default is UTF16-LE.  Note that UNICODE, UTF16 and UTF16-LE are 
#    identical on Windows and in this script.  Because of how characters
#    are generated, ASCII and UTF8 are identical here too. 'LE' stands for 
#    Little Endian, and 'BE' stands for Big Endian.
#
#.Example 
#    New-RandomPassword -Length 25 
#
#    Returns a 25-character UTF16-LE string.  Note that if you will save the 
#    output to a file, beware of unexpected Byte Order Mark (BOM) bytes and 
#    newline bytes added by cmdlets like Out-File and Set-Content.  
#
#Requires -Version 2.0 
#
#.Notes 
#  Author: Jason Fossen, Enclave Consulting LLC (https://www.sans.org/sec505)  
# Version: 3.0
# Updated: 5.Jun.2016
#   Legal: 0BSD.
####################################################################################

[CmdletBinding()] [OutputType([System.String])]
Param (        
    [Int32][ValidateRange(4,2147483647)] $Length = 15, 
    [String][ValidateSet("ASCII","UTF8","UNICODE","UTF16","UTF16-LE","UTF32","UTF16-BE")] $Encoding = "UTF16-LE"
)



function New-RandomPassword  
{
    [CmdletBinding()] [OutputType([System.String])]
    Param (        
        [Int32][ValidateRange(4,2147483647)] $Length = 15, 
        [String][ValidateSet("ASCII","UTF8","UNICODE","UTF16","UTF16-LE","UTF32","UTF16-BE")] $Encoding = "UTF16-LE"
    )

    #Password must be at least 4 characters long in order to satisfy complexity requirements.
    #Use the .NET crypto random number generator, not the weaker System.Random class with Get-Random:
    $RngProv = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()
    [byte[]] $onebyte = @(255)
    [Int32] $x = 0
    [Int32] $prior = 0    #Used to avoid repeated chars.

    #In case the $length is enormous, use a typed list:
    $GenericList = [System.Collections.Generic.List``1]
    $GenericList = $GenericList.MakeGenericType( @("System.Byte") )
    $password = New-Object -TypeName $GenericList -ArgumentList $length


    Do {
        $password.clear() 
        
        $hasupper =     $false    #Has uppercase letter character flag.
        $haslower =     $false    #Has lowercase letter character flag.
        $hasnumber =    $false    #Has number character flag.
        $hasnonalpha =  $false    #Has non-alphanumeric character flag.
        $isstrong =     $false    #Assume password is not complex until tested otherwise.

        For ($i = $length; $i -gt 0; $i--)
        {                                                         
            While ($true)
            {   
                #Generate a random US-ASCII code point number.
                $RngProv.GetNonZeroBytes( $onebyte ) 
                [Int32] $x = $onebyte[0]
            
                # Even though it reduces randomness, eliminate problem characters to preserve sanity while debugging.
                # Also, do not allow two identical chars in a row.  If you're worried about the loss of entropy, 
                # increase the length of the password or comment out the undesired line(s) below:
                if ($x -eq $prior){ continue } #Eliminates two repeated chars in a row; they seem too frequent... :-\
                If ($x -eq 32) { continue }    #Eliminates the space character; causes problems for other scripts/tools.
                If ($x -eq 34) { continue }    #Eliminates double-quote; causes problems for other scripts/tools.
                If ($x -eq 39) { continue }    #Eliminates single-quote; causes problems for other scripts/tools.
                If ($x -eq 47) { continue }    #Eliminates the forward slash; causes problems for net.exe.
                If ($x -eq 96) { continue }    #Eliminates the backtick; causes problems for PowerShell.
                If ($x -eq 48) { continue }    #Eliminates zero; causes problems for humans who see capital O.
                If ($x -eq 79) { continue }    #Eliminates capital O; causes problems for humans who see zero. 

                if ($x -ge 32 -and $x -le 126){ $prior = $x ; break }  #It's a keeper!  
            } 

            $password.Add($x) 

            If ($x -ge 65 -And $x -le 90)  { $hasupper = $true }   #Non-USA users may wish to customize the code point numbers by hand,
            If ($x -ge 97 -And $x -le 122) { $haslower = $true }   #which is why we don't use functions like IsLower() or IsUpper() here.
            If ($x -ge 48 -And $x -le 57)  { $hasnumber = $true } 
            If (($x -ge 32 -And $x -le 47) -Or ($x -ge 58 -And $x -le 64) -Or ($x -ge 91 -And $x -le 96) -Or ($x -ge 123 -And $x -le 126)) { $hasnonalpha = $true } 
            If ($hasupper -And $haslower -And $hasnumber -And $hasnonalpha) { $isstrong = $true } 
        } 
    } While ($isstrong -eq $false)

    #$RngProv.Dispose() #Not compatible with PowerShell 2.0.

    #Output as a string with the desired encoding:
    Switch -Regex ( $Encoding.ToUpper().Trim() )
    {
        'ASCII' 
            { ([System.Text.Encoding]::ASCII).GetString($password) ; continue }
        'UTF8'     
            { ([System.Text.Encoding]::UTF8).GetString($password) ; continue } 
        'UNICODE|UTF16-LE|^UTF16$'  
            {
                $password = [System.Text.AsciiEncoding]::Convert([System.Text.Encoding]::ASCII, [System.Text.Encoding]::Unicode, $password )  
                ([System.Text.Encoding]::Unicode).GetString($password) 
                continue
            } 
        'UTF32'    
            { 
                $password = [System.Text.AsciiEncoding]::Convert([System.Text.Encoding]::ASCII, [System.Text.Encoding]::UTF32, $password )  
                ([System.Text.Encoding]::UTF32).GetString($password) 
                continue
            }
        '^UTF16-BE$' 
            { 
                $password = [System.Text.AsciiEncoding]::Convert([System.Text.Encoding]::ASCII, [System.Text.Encoding]::BigEndianUnicode, $password )  
                ([System.Text.Encoding]::BigEndianUnicode).GetString($password)
                continue 
            } 
        default #UTF16-LE Unicode
            {
                $password = [System.Text.AsciiEncoding]::Convert([System.Text.Encoding]::ASCII, [System.Text.Encoding]::Unicode, $password )  
                ([System.Text.Encoding]::Unicode).GetString($password) 
                continue
            } 
    }

}



# Run the function:
New-RandomPassword -Length $Length -Encoding $Encoding



<#
############################################################################## 
# Watch out when saving your password to a file.  Byte Order Marks, encoding 
# changes, and newline chars will drive you crazy!  
############################################################################## 

#We explicitly ask for an ASCII-encoded password:
$pw = New-RandomPassword -length 5 -Encoding "ascii"

#The following converts to UTF16-LE ("Unicode") with BOM and newline bytes:
$pw | out-file c:\temp\password1.txt  

#The following adds newline bytes (0D,0A) to the end without asking/warning:
$pw | out-file c:\temp\password2.txt -Encoding ascii 

#The following saves just the ASCII string: no BOM, no Unicode, no newline bytes:
$pw | Set-Content -Path C:\temp\password3.txt -NoNewline -Encoding Ascii

#The following also writes the raw bytes (not pretty):
$pw.ToCharArray() | foreach { [byte] $_ } | Set-Content -Path c:\temp\password4.txt -Encoding Byte

#>



############################################################################## 
# Here are the characters and ASCII codes for the password
# characters as a reference.  The excluded ones are noted.
############################################################################## 
#   = 32  Excluded (the space character)
# ! = 33  
# " = 34  Excluded
# # = 35
# $ = 36
# % = 37
# & = 38
# ' = 39  Excluded
# ( = 40
# ) = 41
# * = 42
# + = 43
# , = 44
# - = 45
# . = 46
# / = 47  Excluded
# 0 = 48  Excluded
# 1 = 49
# 2 = 50
# 3 = 51
# 4 = 52
# 5 = 53
# 6 = 54
# 7 = 55
# 8 = 56
# 9 = 57
# : = 58
# ; = 59
# < = 60
# = = 61
# > = 62
# ? = 63
# @ = 64
# A = 65
# B = 66
# C = 67
# D = 68
# E = 69
# F = 70
# G = 71
# H = 72
# I = 73
# J = 74
# K = 75
# L = 76
# M = 77
# N = 78
# O = 79  Excluded
# P = 80
# Q = 81
# R = 82
# S = 83
# T = 84
# U = 85
# V = 86
# W = 87
# X = 88
# Y = 89
# Z = 90
# [ = 91
# \ = 92
# ] = 93
# ^ = 94
# _ = 95
# ` = 96  Excluded
# a = 97
# b = 98
# c = 99
# d = 100
# e = 101
# f = 102
# g = 103
# h = 104
# i = 105
# j = 106
# k = 107
# l = 108
# m = 109
# n = 110
# o = 111
# p = 112
# q = 113
# r = 114
# s = 115
# t = 116
# u = 117
# v = 118
# w = 119
# x = 120
# y = 121
# z = 122
# { = 123
# | = 124
# } = 125
# ~ = 126


<# #######################################################

# If security is not really a concern, you can have some fun
# when generating passwords which can be read over the phone
# and typed in by normal human beings, especially Gen-Y'ers:

$Pokemon = @'
Bulbasaur Ivysaur Venusaur Charmander Charmeleon Charizard Squirtle Wartortle 
Blastoise Caterpie Metapod Butterfree Weedle Kakuna Beedrill Pidgey Pidgeotto 
Pidgeot Rattata Raticate Spearow Fearow Ekans Arbok Pikachu Raichu Sandshrew 
Sandslash Nidoran Nidorina Nidoqueen Nidoran Nidorino Nidoking Clefairy Clefable 
Vulpix Ninetales Jigglypuff Wigglytuff Zubat Golbat Oddish Gloom Vileplume Paras 
Parasect Venonat Venomoth Diglett Dugtrio Meowth Persian Psyduck Golduck Mankey 
Primeape Growlithe Arcanine Poliwag Poliwhirl Poliwrath Abra Kadabra Alakazam 
Machop Machoke Machamp Bellsprout Weepinbell Victreebel Tentacool Tentacruel 
Geodude Graveler Golem Ponyta Rapidash Slowpoke Slowbro Magnemite Magneton 
Farfetched Doduo Dodrio Seel Dewgong Grimer Muk Shellder Cloyster Gastly Haunter 
Gengar Onix Drowzee Hypno Krabby Kingler Voltorb Electrode Exeggcute Exeggutor 
Cubone Marowak Hitmonlee Hitmonchan Lickitung Koffing Weezing Rhyhorn Rhydon 
Chansey Tangela Kangaskhan Horsea Seadra Goldeen Seaking Staryu Starmie Mime 
Scyther Jynx Electabuzz Magmar Pinsir Tauros Magikarp Gyarados Lapras Ditto 
Eevee Vaporeon Jolteon Flareon Porygon Omanyte Omastar Kabuto Kabutops Aerodactyl 
Snorlax Articuno Zapdos Moltres Dratini Dragonair Dragonite Mewtwo Mew Chikorita 
Bayleef Meganium Cyndaquil Quilava Typhlosion Totodile Croconaw Feraligatr Sentret 
Furret Hoothoot Noctowl Ledyba Ledian Spinarak Ariados Crobat Chinchou Lanturn 
Pichu Cleffa Igglybuff Togepi Togetic Natu Xatu Mareep Flaaffy Ampharos Bellossom 
Marill Azumarill Sudowoodo Politoed Hoppip Skiploom Jumpluff Aipom Sunkern Sunflora 
Yanma Wooper Quagsire Espeon Umbreon Murkrow Slowking Misdreavus Unown Wobbuffet 
Girafarig Pineco Forretress Dunsparce Gligar Steelix Snubbull Granbull Qwilfish 
Scizor Shuckle Heracross Sneasel Teddiursa Ursaring Slugma Magcargo Swinub Piloswine 
Corsola Remoraid Octillery Delibird Mantine Skarmory Houndour Houndoom Kingdra 
Phanpy Donphan Porygon2 Stantler Smeargle Tyrogue Hitmontop Smoochum Elekid Magby 
Miltank Blissey Raikou Entei Suicune Larvitar Pupitar Tyranitar Lugia Ho-Oh Celebi 
Treecko Grovyle Sceptile Torchic Combusken Blaziken Mudkip Marshtomp Swampert 
Poochyena Mightyena Zigzagoon Linoone Wurmple Silcoon Beautifly Cascoon Dustox Lotad 
Lombre Ludicolo Seedot Nuzleaf Shiftry Taillow Swellow Wingull Pelipper Ralts Kirlia 
Gardevoir Surskit Masquerain Shroomish Breloom Slakoth Vigoroth Slaking Nincada 
Ninjask Shedinja Whismur Loudred Exploud Makuhita Hariyama Azurill Nosepass Skitty 
Delcatty Sableye Mawile Aron Lairon Aggron Meditite Medicham Electrike Manectric 
Plusle Minun Volbeat Illumise Roselia Gulpin Swalot Carvanha Sharpedo Wailmer Wailord 
Numel Camerupt Torkoal Spoink Grumpig Spinda Trapinch Vibrava Flygon Cacnea Cacturne 
Swablu Altaria Zangoose Seviper Lunatone Solrock Barboach Whiscash Corphish Crawdaunt 
Baltoy Claydol Lileep Cradily Anorith Armaldo Feebas Milotic Castform Kecleon Shuppet 
Banette Duskull Dusclops Tropius Chimecho Absol Wynaut Snorunt Glalie Spheal Sealeo 
Walrein Clamperl Huntail Gorebyss Relicanth Luvdisc Bagon Shelgon Salamence Beldum 
Metang Metagross Regirock Regice Registeel Latias Latios Kyogre Groudon Rayquaza 
Jirachi Deoxys Turtwig Grotle Torterra Chimchar Monferno Infernape Piplup Prinplup 
Empoleon Starly Staravia Staraptor Bidoof Bibarel Kricketot Kricketune Shinx Luxio 
Luxray Budew Roserade Cranidos Rampardos Shieldon Bastiodon Burmy Wormadam Mothim 
Combee Vespiquen Pachirisu Buizel Floatzel Cherubi Cherrim Shellos Gastrodon Ambipom 
Drifloon Drifblim Buneary Lopunny Mismagius Honchkrow Glameow Purugly Chingling Stunky 
Skuntank Bronzor Bronzong Bonsly Mime Happiny Chatot Spiritomb Gible Gabite Garchomp 
Munchlax Riolu Lucario Hippopotas Hippowdon Skorupi Drapion Croagunk Toxicroak 
Carnivine Finneon Lumineon Mantyke Snover Abomasnow Weavile Magnezone Lickilicky 
Rhyperior Tangrowth Electivire Magmortar Togekiss Yanmega Leafeon Glaceon Gliscor 
Mamoswine PorygonZ Gallade Probopass Dusknoir Froslass Rotom Uxie Mesprit Azelf 
Dialga Palkia Heatran Regigigas Giratina Cresselia Phione Manaphy Darkrai Shaymin 
Arceus Victini Snivy Servine Serperior Tepig Pignite Emboar Oshawott Dewott Samurott 
Patrat Watchog Lillipup Herdier Stoutland Purrloin Liepard Pansage Simisage Pansear 
Simisear Panpour Simipour Munna Musharna Pidove Tranquill Unfezant Blitzle Zebstrika 
Roggenrola Boldore Gigalith Woobat Swoobat Drilbur Excadrill Audino Timburr Gurdurr 
Conkeldurr Tympole Palpitoad Seismitoad Throh Sawk Sewaddle Swadloon Leavanny Venipede 
Whirlipede Scolipede Cottonee Whimsicott Petilil Lilligant Basculin Sandile Krokorok 
Krookodile Darumaka Darmanitan Maractus Dwebble Crustle Scraggy Scrafty Sigilyph 
Yamask Cofagrigus Tirtouga Carracosta Archen Archeops Trubbish Garbodor Zorua Zoroark 
Minccino Cinccino Gothita Gothorita Gothitelle Solosis Duosion Reuniclus Ducklett 
Swanna Vanillite Vanillish Vanilluxe Deerling Sawsbuck Emolga Karrablast Escavalier 
Foongus Amoonguss Frillish Jellicent Alomomola Joltik Galvantula Ferroseed Ferrothorn 
Klink Klang Klinklang Tynamo Eelektrik Eelektross Elgyem Beheeyem Litwick Lampent 
Chandelure Axew Fraxure Haxorus Cubchoo Beartic Cryogonal Shelmet Accelgor Stunfisk 
Mienfoo Mienshao Druddigon Golett Golurk Pawniard Bisharp Bouffalant Rufflet Braviary 
Vullaby Mandibuzz Heatmor Durant Deino Zweilous Hydreigon Larvesta Volcarona Cobalion 
Terrakion Virizion Tornadus Thundurus Reshiram Zekrom Landorus Kyurem Keldeo Meloetta 
Genesect Chespin Quilladin Chesnaught Fennekin Braixen Delphox Froakie Frogadier 
Greninja Bunnelby Diggersby Fletchling Fletchinder Talonflame Scatterbug Spewpa 
Vivillon Litleo Pyroar Floette Florges Skiddo Gogoat Pancham Pangoro Furfrou Espurr 
Meowstic Honedge Doublade Aegislash Spiritzee Aromatisse Swirlix Slurpuff Inkay 
Malamar Binacle Barbaracle Skrelp Dragalage Clauncher Clawitzer Helioptile Heliolisk 
Tyrunt Tyrantrum Amaura Aurorus Sylveon Hawlucha Dedenne Carbink Goomy Sliggoo Goodra 
Klefki Phantump Trevenant Pumpkaboo Gourgeist Bergmite Avalugg Noibat Noivern Xerneas 
Yveltal Zygarde Diancie Hoopa Volcanion
'@

# Create an array of the pocket monsters:
$Pokemon = $Pokemon -split '[\s\n]+'

# Generate a not-so-secure password for fun: 
(Get-Random $Pokemon) + (Get-Random -Minimum 11 -Maximum 999) + (Get-Random $Pokemon) 


########################################################################### #>
