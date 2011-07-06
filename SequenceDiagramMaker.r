REBOL[
	Title: "SequenceDiagramMaker.r"
    Date: 2011-07-07
    Version: 0.0.1
    File: %SequenceDiagramMaker.r
    Author: "Philippe Le Goff"
    Copyright: "2011 Philippe Le Goff"
    Purpose: "SequenceDiagramMaker"
    eMail: [lp DOT legoff AT free DOT fr]
    History: [
        0.0.1 [07-07-2011 "add styles"]
    ]
    comment: {From a text file, SequenceDiagramMaker (SDM) will automatically generate a sequence diagram.
	Author: philippe Le Goff}
]
; TO DO
; Définir des styles par-défaut : boites simples, couleurs arrow, styles arrow
; Définir la lecture des fichiers avec un attribut is-from-file? pour des tests rapides dans le script

;------- library loading
do load %SequenceDiagramMakerLib.r
change-dir what-dir
file: request-file/only/filter ["*.txt" ]
;------- parsing de la chaine en input =>  read/lines file
str-blk: read/lines to-rebol-file file

;------- start parsing
foreach val str-blk [
	if (not empty? val) [
		if (find val "#") [windows-title: replace/all (copy :val) "#" ""	]
		either (find val arrow2) [	parse val rule-arrow2 ][ ; voir le cas où le find str "->" matche avec le cas find str "-->"
		if (find val arrow1) [	parse val rule-arrow1 ]
		] ; fin du either
	] ; end if
]
;------- end foreach

;------- style loading
classic-style: stylize/master compose [
		system-box: (my-style) coal  (size-dragbox) font-size 12 font-name "Verdana" 0.0.0 middle center
	]
current-style: :classic-style   ; mis ici pour avoir une variable

;------- SORTIE
my-output: compose [
	size (:screen)
	styles current-style
bg: backdrop white effect [ draw [] ]  ;  white > snow > silver > coal
] ; fin my-output

;------------------------------------
num-nodes: length? nodes
size-dragbox: as-pair (9 * get-maxsize nodes ) 20
; la taille des box a été positionnée sur celle du plus long label
num-links: (( length? links ) / 4 ) + 1   ; WARNING !! dependances avec les appends dans les rules

dx: (screen/x - (size-dragbox/x * num-nodes)) / (num-nodes + 1)
; il faudra aussi calculer le dy pour équirepartir les traits.
dy: (screen/y - (2 * (init-pos/y + size-dragbox/y))) / num-links   ; dy = ecart entre deux traits successifs.
y-values: for i (init-pos/y + size-dragbox/y) screen/y dy   [append [] i ]
y-values: reverse (next (reverse (next y-values)))    ; on élimine la bordure du haut et celle du bas

;-----------------creation des nodes -------------------
foreach val-box nodes [
	pos1: as-pair ((dx * (i + 1)) + (size-dragbox/x * i)) init-pos-top
	pos2: as-pair pos1/x init-pos-bottom
	length-val-box: length? val-box
	; @PLG !! les styles 'button et 'box fonctionnent mais pas le style 'btn
	search-color: either not find val-box "User" [coal][orange]   ; or water or rebolor
		append out compose/deep [ at (pos1) system-box  (val-box)  with [ self/color: (search-color	) self/action: [print (val-box)]] ]  ; !PLG !!
		append out compose/deep [ at (pos2) system-box  (val-box)  with [ self/color: (search-color	) self/action: [print (val-box)]] ]

	i: i + 1
] ; end foreach

;------------------ my-output is defined in Lib --------------------
append my-output out
SeqDiagMaker: center-face layout my-output
; SeqDiagMaker est le nom de la variable désignant la top-level face

; --------------------- FIN MAIN LAYOUT ------------------------------
; liste-elements-system-box contient les faces de style 'system-box
liste-elements-system-box: find-face-style SeqDiagMaker 'system-box

; creation block lines à partir des éléments graphiqnes
middles: foreach [f1 f2] liste-elements-system-box [
		if ( equal? f1/text f2/text ) [
			append [] compose/deep [ (as-string f1/text) (first (vmiddle f1 f2))]
			add-line f1 f2
		] ; end if
]

; ------  managing the vertical lines   ---------------
draw-lines
;--------------------- gestion arrows ------------------------
the-arrows: foreach [source target commnt type] links [
	val-middle: select middles  source
	append [] compose/deep [(source) (target) (commnt) (type) (val-middle)]
] ; end foreach

valy: second find-face-label SeqDiagMaker the-arrows/1

all-arrows: foreach [source target commnt type valx ] the-arrows [
append [] compose/deep [(source) (as-pair (first find-face-label SeqDiagMaker  source) (valy: valy + dy)) (target) (as-pair (first find-face-label SeqDiagMaker  target) (valy)) (commnt)]
]
foreach [ a b c d e ] all-arrows [
	draw-arrow-pos :b :d :e              ; dessin des liens entre les axes verticaux
] ; end foreach

; ------------- fin gestion des arrows ---------------------

; ------------- image creation  ---------------------
tmp-img: (to-image do compose/deep (SeqDiagMaker) )
save/png to-file rejoin ["./images/"   to-relative-file file ".png"] tmp-img

insert-event-func [if 'resize = event/type [bg/size: SeqDiagMaker/size show bg] event]
view/options/title SeqDiagMaker [resize] windows-title


