
Kurzbeschreibung:	       HASM  &  HSIM 
		   Tabellenkonfigurierbarer Makro-Assembler
			 mit integriertem Linker und
			zugehîrigem Simulator/Monitor
			   (c) Dr.-Ing. H.P. Hohe

          Ein Crossassembler mit Simulator/Monitor fÅr viele Prozessoren

  Bereits unterstÅtzte Prozessoren: 6502      Rockwell
				    68HC11    Motorola (mit Simulator)
				    8035      Intel
				    8039      Intel (mit Simulator)
				    80C166    Siemens
				    80C196KC  Intel
				    80C517    Siemens
				    80C552    Philips (mit Simulator)
				    PIC16C57  Microchip (mit Simulator)
				    Z80       Zilog
                                    dCPU-4    UNI Clausthal (mit Simulator)

  Leistungsmerkmale fÅr den 'Normal'-Anwender:
  --------------------------------------------
  HASM:
    + volle MakrounterstÅtzung mit lokalen Labels (Nicht nur Åber #DEFINE !)
    + voll verschiebbare, segmentierte Programmierung
    + bedingte Assemblierung und Include
    + lokale Labels, auch innerhalb eines Sourcefiles
    + Fehlermeldungen mit Quellenangabe fÅr intelligenten Editor
    + Punkt-Vor-Strich bei AusdrÅcken
    + AusdrÅcke kînnen Floatzahlen, Integerwerte und Strings enthalten
    + spezielle Befehle zur Generierung ganzer Wertetabellen
    + Einbindung einzelner Module aus einer Library je nach Bedarf.
    + Assemblerdirektiven fÅr alle Prozessoren gleich
  HSIM:
    + Sourcecodesimulator mit Breakpointverwaltung
    + Single-Step, Run, Trace und Retrace (Programm rÅckwÑrts abarbeiten)
    + HSIM ermîglicht das gleichzeitige Simulieren mehrerer Prozessoren
    + Datenaustausch unter den verschiedenen Prozessoren mîglich
    + Relative AusfÅhrungsgeschwindigkeit einstellbar
    + Terminalfenster bei der Simulation verwendbar (Monitorsimulation)
    + Stimulusfiles bei der Simulation
    + Simulator kann als Sourcecodemonitor verwendet werden
    + Aenderung von Registern waehrend der laufenden Simulation moeglich
    + Online Hilfe Åber <F1>


  Leistungsmerkmale fÅr den 'Power'-Anwender:
  -------------------------------------------
  HASM:
    + Prozessoren die noch nicht unterstÅtzt werden kînnen vom
      Anwender selbst integriert werden. (Format der Tabellen offengelegt !)
    + Die Befehle eines Prozessors kînnen auf Bit-Ebene definiert werden
    + BedingungsabhÑngige CodelÑnge fÅr Prozessorbefehle
    + Konstanten fÅr den jeweiligen Prozessor direkt in der Tabelle mîglich
    + Frei definierbare Operatoren fÅr den Assembler
    + Physikalische und virtuelle Segmente kînnen beliebig definiert werden
    + Segment-Mapping ist bei allen Segmenten mîglich
    + Nachbildung eines anderen Assembler mîglich -> QuellenÅbernahme einfach
  HSIM:
    + Weitere Prozessoren durch Tabellen einbindbar (vom Anwender !)
    + Simuliert auch Eigenbauprozessoren (Beispiel: dCPU-4)
    + ZugriffshÑufigkeiten auf Register oder SpeicherplÑtze kînnen
       durch ErgÑnzungen in der Tabelle erfa·t werden.

  Und was das Beste ist, fÅr den nicht professionellen Nutzer
    - private Nutzung ohne kommerzielle Verwendung
    - Verwendung in der Lehre und Ausbildung
    - zum Testen von HASM und HSIM
  ist die SHAREWARE-Version von Crossassembler und
  Simulator/Monitor vîllig KOSTENLOS !

  Die Vollversion kann erworben werden bei:

                               PohlTronik
                               Dipl.-Ing. S. Pohl
                               Schlehenweg 6
                               D-31812 Bad Pyrmont
                               Fax.: ++49(0)5281 - 607571

  Eine kommerzielle Nutzung ist nur mit einer kÑuflich erworbenen
  Version oder mit ausdrÅcklicher Genehmigung des Autors erlaubt !


Einrichten von HASM/HSIM auf der Festplatte:
============================================

  1. Stellen Sie sich in das Unterverzeichnis in dem sich 
     spÑter das Unterverzeichnis HASM befinden soll !

  2. Starten sie das Auspacken von HASM mit dem Befehl "Hasm??.exe", wobei
     fuer ?? die aktuelle Versionsnummer eingesetzt werden muss. Bei dieser
     Datei handelt es sich um ein selbstextrahierendes Archiv. Nach der 
     Sicherheitsabfrage, die zum Auspacken mit `x` beantwortet werden muss
     wird das Unterverzeichnis HASM mit allen darin befindlichen Files
     erzeugt. Beim Auspacken werden weder Systemdateien (Autoexec.bat,
     Config.sys) modifiziert noch in irgendwelchen anderen Verzeichnissen
     Dateien angelegt oder veraendert. 
     Das Gespann HASM/HSIM ist jetzt bereits Einsatzbereit. Lediglich der 
     Aufruf von Assembler bzw Simulator muss noch mit vollstaendigem Pfad
     erfolgen. Fuer einen einfacheren Aufruf kann entweder ein
     Batchfile erzeugt oder der Pfad von HASM in die PATH-Variable
     von MSDOS aufgenommen werden.


    Verzeichnisstruktur danach: 
    ---------------------------

     Verzeichnis beim 
            Auspacken
		    \
		     \ ____ HASM __________ TABELLEN
				  \
				   \_______ DOC
				    \
				     \_____ SCRIPT
				      \
				       \___ INIT
				        \
				         \_ DEMO ....(Beispiele)

      Inhalt: HASM     - Hasm.exe
                       - Hsim.exe
                       - Hsim.hlp

	      TABELLEN - Z80.TAB
		       - MCS-48.TAB
		       - MCS-51.TAB
		       - 80C552.TAB  (Assemblertabelle)
                       - 80C552.TAS  (Simulatortabelle)
		       - 80C552.TAM  (Monitortabelle)
		       - 80C517.TAB
		       - 80C166.TAB
		       - u.s.w

	      DOC      - Hasm.doc
                       - Hsim.doc
		       - Schnell.doc

	      SCRIPT   - autoexec.scr    (diverse globale Scriptfiles)
                       - w.scr
		       - cs.scr

	      INIT     - Setup Support fÅr Editoren

	      ...      - diverse Test und Beispielprogramme



  Tips:  - Anleitung zu HASM und HSIM
                              -> hasm\doc\hasmhsim.txt (reines Textfile)
         - zwei selbstablaufende Demos
                                       hasm\demo\68hc11\buffalo\demo.bat
                                  und  hasm\demo\multi\demo.bat


