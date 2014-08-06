---
layout: post
title: "Cisco VoIP oplossing voor Ziggo telefonie"
date: 2009-09-04 11:39:48 +0200
comments: true
categories: [cisco, voip, ziggo]
---

{% blockquote %}
This article is only available in Dutch.
{% endblockquote %}

Sinds een recente verhuizing beschik ik thuis over een Ziggo Alles-in-1 Plus pakket, met internet, tv, én telefonie.

Daarvoor maakte ik gebruik van een Cisco VoIP netwerk op basis van een externe SIP provider. Natuurlijk wilde ik mijn Cisco netwerk blijven gebruiken, maar dan wel op basis van de Ziggo telefonie aansluiting.

Helaas maakt Ziggo gebruik van het [PacketCable](http://en.wikipedia.org/wiki/PacketCable) protocol over [EuroDocsis](http://en.wikipedia.org/wiki/DOCSIS), in plaats van [SIP](http://en.wikipedia.org/wiki/Session_Initiation_Protocol). 
Daarnaast heeft het Motorola SurfBoard modem dat bij het Ziggo abonnement geleverd wordt geen SIP interface voor het LAN, maar beschikt over 2 [POTS](http://en.wikipedia.org/wiki/Plain_old_telephone_service) poorten op [RJ11](http://en.wikipedia.org/wiki/RJ11,_RJ14,_RJ25) connectoren.

Alsof dat nog niet genoeg ellende is maakt Ziggo _geen_ gebruik van [DTMF ETSI](http://en.wikipedia.org/wiki/Dual-tone_multi-frequency) signalering voor onder andere nummerweergave, maar in plaats daarvan het veel minder bekende [Bellcore FSK](http://en.wikipedia.org/wiki/FSK_standards_for_use_in_Caller_ID_and_remote_metering).

Goed, tot zover de met technische termen bezaaide probleemvorming. Tijd voor een oplossing om je mooie VoIP apparatuur aan de gang te krijgen! Er zijn naar mijn ervaring bijzonder weinig how-to's / handleidingen of tutorials te vinden op het internet om een dergelijke setup te maken, en de informatie over het Ziggo netwerk is zo mogelijk nog beperkter, vandaar deze uitgebreide uitleg om voor eens en altijd van dat probleem af te zijn!

### De basis

 Als basis voor deze tutorial gebruik ik de volgende hardware:

 - [Cisco 1760-V Modular Access Router](http://www.cisco.com/en/US/products/hw/routers/ps221/products_data_sheet09186a00800920f2.html)
 - [Cisco 7940 IP-Phones](http://www.cisco.com/en/US/products/hw/phones/ps379/ps1854/)
 - [Cisco 7971GE IP-Phones](http://www.cisco.com/en/US/products/ps5946/)
 - [Motorola SBV5121e VoIP Cable Modem](http://www.motorola.com/staticfiles/Business/Products/Modems%20and%20Gateways/Modems/Digital%20Voice%20Modems/SBV5121/_Documents/Static%20Files/SBV5121e-data-sheet-534281-001-a.pdf)

Naast deze hardware heb ik nog een tweede router (voor o.a. Wireless) en de nodige switching apparatuur draaien, maar dat maakt voor het doel van deze tutorial weinig uit.

Een schematische weergave van de aan elkaar geknoopte hardware:

*insert image*

### Stap 1: De hardware verbindingen

 De meest ideale situatie zou zijn om de (digitale) VoIP toestellen digitaal via SIP of een ander protocol met Ziggo te verbinden om zo de beste gesprekskwaliteit en de laagste latency te krijgen. Helaas is dit dus niet mogelijk in combinatie met het Motorola modem, en zijn we veroordeeld tot het gebruik van analoge lijnen.
 Gelukkig beschikt de Cisco 1760 router over de mogelijkheid om aangesloten te worden op PSTN lijnen doormiddel van een Voice Interface Card.
 Om van deze mogelijkheid gebruik te maken moet je router over een aantal zaken beschikken:

 - De mogelijkheid om VIC's te plaatsen
 - Een PVDM kaart waarop een DSP chip aanwezig is om van je router een Voice Gateway te maken. (In dit voorbeeld wordt een `PVDM-256k-4=` gebruikt)
 - De IOS versie op de router dient over het `IP Voice feature pack` te beschikken. (In dit voorbeeld wordt `IOS (C1700-ADVENTERPRISEK9-M) Version 12.4(15)T5 (fc4)` gebruikt, die daar naast Cisco Unified Call Manager ook over beschikt)

 De VIC die je vervolgens nodig hebt is van het Foreign Exchange Office (`FXO`) type. Andere typen als Ear&Mouth (`E/M`) en Foreign Exchange Subscriber (`FXS`) zijn voor dit doeleinde _NIET_ geschikt, en kunnen tevens niet gelijktijdig op dezelfde router gebruikt worden. Maak dus niet dezelfde fout als ik door een `VIC-2E/M` aan te schaffen omdat deze vrij goedkoop zijn, in de hoop dat het werkt.. want het werkt niet! Helaas is de `FXO` kaart de duurste van de collectie, zeker als je nummerweergave wilt. Een overzicht van alle beschikbare FXO kaarten kun je vinden bij [Cisco](http://www.cisco.com/en/US/products/hw/routers/ps274/products_tech_note09186a00800b53c7.shtml). Mijn advies is om de `VIC2-2FXO` te nemen, aangezien deze over alle benodigde opties beschikt (helaas wel de duurste kaart met 2 poorten).

 Goed, `PVDM` en `VIC` in de router, opstarten, en de analoge telefoonlijnen met RJ11 pluggen van de 2 `VIC` poorten naar de 2 poorten op het modem verbinden en we zijn klaar om te configureren!

### Stap 2: Router configuratie

 Gebruik je favoriete protocol om in te loggen op je router (RS232, ssh of telnet), zet de router in enable mode, en check of je PVDM en VIC actief zijn en werken en check gelijk op welke poorten ze zitten. De VIC2-2FXO zit in dit voorbeeld in slot 2, en beschikt over voice-ports 2/0 en 2/1.
 Ga vervolgens verder met de configuratie van het geheel via `conf t`. Ik ga er van uit dat de basis van je router goed is ingesteld, en ga dus alleen in op de voice settings.

#### voice card

```
trunk group pots
 hunt-scheme round-robin
 !
```

We maken een hunt group aan voor de analoge lijnen, zodat de router zelf bepaalt welke lijn vrij is en deze voor inkomende/uitgaande oproepen gebruikt.

#### voice ports

```
voice-port 2/0
 trunk-group pots
 cptone JP
 connection plar 1337
 caller-id enable
 !
 voice-port 2/1
 trunk-group pots
 cptone JP
 connection plar 1337
 caller-id enable
 !
```

Configureer beide voice-ports, en voeg ze aan de trunk group toe. Zet caller-id aan. De cptone parameter geeft aan wat voor landinstellingen de PSTN lijn gebruikt. Normaal gesproken zou dit NL zijn voor gebruik in Nederland, maar aangezien normale PSTN lijnen hier DTMF ETSI gebruiken werkt dat niet voor onze doeleinden. Daarom gebruiken we JP (Japan), aangezien daar FSK gebruikt wordt. Het klinkt wat vreemd, maar werkt perfect. Tenslotte voegen we een &quot;private line automatic ringdown&quot; (PLAR) toe op de lijnen. Hiermee zorgen we dat wanneer een oproep binnenkomt op de lijn, deze automatisch wordt doorgeschakeld naar de opgegeven PLAR lijn. De opgegeven PLAR lijn is in dit geval een Overlay voor de ephone DN's die we later zullen configureren. In het kort komt het erop neer dat zodra de lijn gebeld wordt de Overlay wordt aangeroepen, en alle toestellen die gekoppeld zijn aan de DN zullen overgaan.

#### codecs

```
voice class codec 1
 codec preference 1 g711ulaw
 codec preference 2 g711alaw
 !
```

 Niet zo belangrijk voor dit voorbeeld, maar toch is het handig om in te stellen welke codecs gebruikt worden binnen het VoIP netwerk (bellen tussen de toestellen onderling). de PVDM DSP handelt verder de codecs voor de analoge lijnen af.

#### dial-peers

```
dial-peer voice 1 pots
 trunkgroup pots
 preference 7
 destination-pattern 0[1-9]........
 incoming called-number .
 no digit-strip
 forward-digits all
 !
 dial-peer voice 2 pots
 trunkgroup pots
 destination-pattern 00[1-9]..........
 incoming called-number .
 no digit-strip
 forward-digits all
 !
 dial-peer voice 3 pots
 trunkgroup pots
 destination-pattern 1233
 incoming called-number .
 no digit-strip
 forward-digits all
 !
```

 Voeg dial-peers toe voor alle inkomende en uitgaande belpatronen. Voor het gemak gebruiken alle dial-peers hier hetzelfde inkomende patroon (.), om het binnenkomende gesprek rechtstreeks zonder modificatie door te zetten naar de PLAR. De dial-peers dienen uiteraard net als de lijnen gekoppeld te worden aan de trunk group.
 De destination-patterns geven aan welke telefoonnummers geldig zijn, en indien een gedraaid nummer voldoet aan één van de patterns wordt het gesprek doorgezet naar de trunk, en zal dus gebruik maken van één van de PSTN lijnen. De opgegeven patterns zijn alles behalve compleet, maar dekken in ieder geval de volgende situaties:

 - Een 10 cijferig telefoonnummer, beginnend met een 0, gevolgd door een 1 tot 9 en vervolgens nog 8 random cijfers. (Bijv. 0131212121)
 - Een 13 cijferig internationaal telefoonnummer, beginnend met 00, gevolgd door een 1 tot 9 en nog 10 random cijfers. (Bijv. 0031131212121)
 - Het nummer van de Ziggo voicemail, 1233.

Standaard stript de dial-peer opgegeven dialpatterns van het nummer af alvorens deze door te geven, dus gebruiken we no digit-strip om dit te voorkomen. Tenslotte zorgen we dat alle overige gedraaide nummers (right-justified) worden doorgezet naar de PSTN lijn.

#### telephony service

```
telephony-service
 load 7960-7940 P000308000400
 load 7971 SCCP70.8-2-2SR1S
 load 7970 SCCP70.8-2-2SR1S
 max-ephones 5
 max-dn 5
 ip source-address 10.0.0.5 port 2000
 auto assign 1 to 5
 calling-number initiator
 system message ccme1 ready..
 url services http://10.0.0.35:8080/CSFEnterprise-war/
 cnf-file perphone
 network-locale NL
 time-zone 28
 time-format 24
 date-format dd-mm-yy
 voicemail 1233
 max-conferences 4 gain -6
 moh rick.au
 transfer-system full-consult dss
 create cnf-files version-stamp 7960 Apr 17 2009 09:02:53
 !
```

 Configureer je VoIP telephony service naar eigen inzicht. Bovenstaande configuratie is slechts een voorbeeld van mijn eigen configuratie. Zaken waar je op moet letten zijn of je loads goed gespecificeerd zijn (denk ook aan de tftp statements), het voicemail nummer (in dit geval extern naar Ziggo) voor wanneer op de Berichten knop op de telefoon wordt gedrukt, en de land instellingen.

#### DN's

```
ephone-dn 1
 number 1234
 label Woonkamer
 description 013xxxxxxx
 name Woonkamer
 call-forward busy 1235
 call-forward noan 1235 timeout 120
 ephone-hunt login
 !
 ephone-dn 2
 number 1235
 label Kantoor
 description 013xxxxxxx
 name Kantoor
 call-forward busy 1234
 call-forward noan 1234 timeout 120
 ephone-hunt login
 !
 ephone-dn 3
 number 1337
 label Extern
 description Extern Overlay
 name Extern
 !
```

 Voeg een ephone DN toe voor ieder toestel dat je aan gaat sluiten, met een eigen nummer (dit nummer en label is zichtbaar op het toestel, en wordt gebruikt om onderling met elkaar te bellen). Ik heb de DN's zo ingesteld dat wanneer ze niet beantwoord worden/bezet zijn automatisch de andere DN wordt aangeroepen. Voeg tenslotte de Overlay DN toe die in de voice-ports is gespecificeerd, en geef het een label zodat je op je telefoons kunt zien dat een oproep van de Externe lijn afkomstig is.

#### ephones

```
ephone 3
 mac-address 000D.EDAB.5055
 speed-dial 1 xxxxxxxxxx label &quot;xxxx&quot;
 type 7940
 button 1o2,3
 pin 1235
 !
 ephone 4
 conference admin
 mac-address 0015.2BD2.01C7
 username &quot;remco&quot; password xxxxxxxx
 speed-dial 1 xxxxxxxxxx label &quot;xxxx&quot;
 speed-dial 2 xxxxxxxxxx label &quot;xxxx&quot;
 speed-dial 3 xxxxxxxxxx label &quot;xxxx&quot;
 type 7971
 button 1o1,3
 pin 1234
 !
```

 Voeg ephones toe voor ieder toestel dat je hebt. Configuratie hangt natuurlijk af van het toestel dat je hebt en hoe je wil dat hij reageert. Voeg users en speeddials toe naar wens. De enige cruciale data is het MAC adres (anders weet de router niet welk toestel aan de ephone te koppelen), en de button configuratie.

 De button configuratie zorgt er namelijk voor dat een lijn aan het toestel gekoppeld wordt, inclusief de Overlay DN. zo heeft ephone 3 een button `1o2,3` . Dit houdt in dat DN's 2 en 3 in overlay mode onder button 1 van dit toestel zitten. De router zoekt automatisch de meest unieke lijn uit, en presenteert deze DN onder de knop. Aangezien Overlay DN 3 op meerdere toestellen wordt gebruikt is deze het minst uniek, en zal enkel op de achtergrond aanwezig zijn. ephone 4 maakt op button 1 gebruik van DN's 1 en 3. Op deze manier presenteren beide toestellen hun eigen nummer, maar luisteren op de achtergrond wel mee naar de Overlay DN, en zullen dus gelijktijdig overgaan zodra een gesprek binnenkomt op de trunk en deze wordt doorgezet naar de Overlay DN.

### Stap 3: klaar!

 Save je configuratie door een `copy run start` te doen, en je zou aan de gang moeten kunnen!

 - Onderling bellen kan door de unieke DN van een ephone te bellen (1234 en 1235 in dit geval)
 - Extern bellen kan door een telefoonnummer te draaien dat gespecificeerd is in één van de dial-peers
 - Voicemail is gekoppeld onder de berichtenknop van een toestel.
 - Binnenkomende gesprekken zullen op alle toestellen die gebruik maken van de Overlay DN overgaan, inclusief nummerweergave!

*Veel succes!*

