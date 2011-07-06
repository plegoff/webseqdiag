REBOL[
	Title: "SequenceDiagramMakerLib.r"
    Date: 2011-07-07
    Version: 0.0.1
    File: %SequenceDiagramMakerLib.r
    Author: "Philippe Le Goff"
    Copyright: "2011 Philippe Le Goff"
    Purpose: "Library for SequenceDiagramMaker"
    eMail: [lp DOT legoff AT free DOT fr]
    History: [
        0.0.1 [07-07-2011 "Bug fixes"]
    ]
    comment: {From a text file, automatically generate a sequence diagram. Author: philippe Le Goff}
	]

; Librairie pour SequenceDiagramMaker
lines: copy []     ; pour les liens
links: copy [] ;  la liste des liens
arrows: copy [] ; la liste des faces en relation
nodes: copy []  ; la liste des noeuds uniques
windows-title: "Sequence Diagram Maker by Rebol"
middles: copy []
out: copy []

; initialisation du dessin des boxes
; ------------------ STYLES --------------------------
screen: system/view/screen-face/size - 30x80 ; 1280x768 - 30x80
center: screen / 2
col: coal
; vertical lines
vert-lines-colr: 128.128.128
size-dragbox: 120x25  ;80x40

; ------------------ FONCTIONS PARSING --------------------------
arrow1: {==>}
arrow2: {-->}
rule-arrow1: [copy elem1 to arrow1 thru arrow1 copy elem2 to ":" skip copy cmt1 to end (
	append links reduce [elem1 elem2 cmt1 "basic"]
	print [elem1 elem2 cmt1]
	if (not find nodes elem1) [ append nodes elem1 ]
	if (not find nodes elem2) [ append nodes elem2 ]
	)]
rule-arrow2: [copy elem3 to arrow2 thru arrow2 copy elem4 to ":" skip copy cmt2 to end (
	append links reduce [elem3 elem4 cmt2 "dotted"]
	if (not find nodes elem3) [ append nodes elem3 ]
	if (not find nodes elem4) [ append nodes elem4 ]
	)]
; links va contenir la liste ordonnée des liens entre les boxes, avec leur commentaire et leur style (basic = -> et dotted = -->

get-maxsize: func [blk /local tmp var ][
tmp: foreach item blk [
	append [] length? item
] ; end foreach
return last sort tmp
] ; end func

;------------------------------------


init-pos: 20x20
; initialisation
init-pos-top: init-pos/x
init-pos-bottom: ( screen/y -  size-dragbox/y - init-pos-top)   ; 20x550
i: 0
pos1: 0
pos2: 0

; ------------------ FONCTIONS --------------------------
;===lines, d'aprés Volker Nitsch ===================

find-line: func [face1 face2] [
	any [
		find/skip lines reduce [face1 face2] 2
		find/skip lines reduce [face2 face1] 2
	]	; fin any
] ; fin fonction find-line

; fonction modifiée
add-line: func [face1 face2 ] [ if not find-line face1 face2 [repend lines [face1 face2] ] ]  ; fin add-line

; fonction pour tracer depuis le barycentre des boites
middle: func [face] [ face/size / 2 + face/offset ]

; fonction pour connaitre la position du median entre 2 faces
vmiddle: func [face1 face2] [ ((middle face1) + (middle face2)) / 2 ]

; tracé des lignes verticales
draw-line: func [face1 face2] [	repend draw ['pen vert-lines-colr 'line-pattern 1 5  'line middle face1 middle face2   ] ] ; fin draw-line

draw-lines: does [
	draw: clear bg/effect/draw
	foreach [face1 face2] lines [
		if (face1/text = face2/text ) [
			draw-line face1 face2
			]
  ]
] ; fin draw-lines

remove-line: func [face1 face2] [
	if p: find-line face1 face2 [ remove/part p 2 ]
	] ; fin remove-line
;
;----------- Arrows -----------------------

find-arrow: func [face1 face2] [
	any [
		find/skip arrows reduce [face1 face2] 2
		find/skip arrows reduce [face2 face1] 2
	]	; fin any
] ; fin fonction find-arrow

add-arrow: func [face1 face2 ] [
if not find-arrow face1 face2 [repend arrows [face1 face2]	]
]  ; fin add-arrow


draw-arrow-pos: func [pos1 pos2 cmt] [
	vpos: (pos1 + pos2) / 2  ; middle of the arrow
	cmt-average: as-pair (either none? cmt [0][ 3 * (length? cmt) ]) 0  ; \!/ là encore pb avec la longueur du texte => police / decalage bizarre
	vpos1: vpos - cmt-average
	vpos2: vpos + cmt-average
	vtext: vpos1 - 0x20   ; pour tenir compte du texte (qui se décale en y) ! PLG
	; on a les bornes des traits et du texte au milieu
	;	label: cmt
		either pos2/1 > pos1/1 [
		repend draw ['pen col 'line pos1 pos2 'text vtext (cmt) 'fill-pen col  'polygon pos2 (pos2 - 15x-5) (pos2 - 7x0) (pos2 - 15x5) ]
		    ][
		pos1-tmp: pos1 ; - 0x20
		pos2-tmp: pos2 ;  - 0x20
				; modifier pos1 et pos2 pour réduire la distance entre la requete et sa reponse
		repend draw ['pen col white 'line-pattern 5 5  'line pos1-tmp pos2-tmp 'text vtext (cmt) 'line-pattern 'fill-pen col   'polygon pos2-tmp (pos2-tmp + 15x-5) (pos2-tmp + 7x0) (pos2-tmp + 15x5) ]
		] ;end either
		; view layout [box 100x40 white effect [draw [ pen black white line-pattern 5 5 line 10x10 90x10  ]]]  (astuce sur la double couleur de 'pen)
] ; fin draw-arrow-pos

draw-arrows-pos: does [
	draw: clear bg/effect/draw
	foreach [pos1 pos2] arrows [
		draw-arrow-pos pos1 pos2
	]
] ; fin draw-arrows-pos

;------------------------------------------------------------------
; recherche de styles particuliers : recherche le path de la face dans le conteneur parent
face-to-index: func [face] [ to-path reduce ['SeqDiagMaker 'pane index? find SeqDiagMaker/pane face]	]

; recherche de styles particuliers : recherche d'une face ayant un certain label
find-face-label: func [face labl /local var ][
	foreach f face/pane [
		if f/text = labl [
			return middle f    ; on récupere les coordonnées de la face
		] ; fin du if
	]
] ; end func

; recherche de styles particuliers : recherche d'une face ayant un certain style
find-face-style: func [face st  /local tmpo tmpo2 f ] [
	tmpo: copy []
	res-blk: copy []

	; recuperation des elements concernés sur la base du style
	foreach f face/pane [
		if f/style = st [
			append tmpo f
		] ; fin du if
	]
	foreach fx tmpo [
	; on calcule la seconde série sur la différence entre l'originale sans l'élement courant
	tmpo2: difference tmpo append [] fx
	if  (length? tmpo2) > 0 [
		foreach fy tmpo2 [
			repend res-blk [ fx fy ] ; il faut conserver les faces
		]  ; foreach fy
		]
	]  ; foreach fx
res-blk
] ; fin find-face-style

; --------------------- MAIN LAYOUT & STYLES  ------------------------------

my-style: 'box

comment {
; on peut aussi utiliser button
}