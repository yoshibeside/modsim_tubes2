globals[
  top-edge
  bottom-edge
  right-edge
  left-edge
  turtle_iterate
  max-global-turn
]

turtles-own [
  vx
  vy
  flockmates
  flockmates-protected-zone
  maxspeed
  minspeed
  biasval
  scout
  al-or-s
  avg-heading-x
  avg-heading-y
  typeanimal
  predator
]

to setup
  clear-all
  set turtle_iterate 0

  set max-global-turn 10
  create-turtles population
    [ set color yellow - 2 + random 7  ;; random shades look nice
      set size 0.5 ;; easier to see
      setxy random-xcor random-ycor
      set flockmates no-turtles
      set flockmates-protected-zone no-turtles
      set predator no-turtles
      set maxspeed 0.5
      set minspeed 0.1
      set biasval 0.001
      set scout 0
      set vx 0.01
      set vy 0.01
      set typeanimal 0
  ]
  create-turtles group-one
  [ set color red - 2 + random 7  ;; random shades look nice
    set size 0.5  ;; easier to see
    setxy random-xcor random-ycor
    set flockmates no-turtles
    set flockmates-protected-zone no-turtles
    set predator no-turtles
    set maxspeed 0.5
    set minspeed 0.1
    set maxbias 0.01
    set bias-increment 0.00004
    set biasval 0.001
    set scout 1
    set vx 0.01
    set vy 0.01
    set typeanimal 0
  ]

  create-turtles group-two
  [ set color blue - 2 + random 7  ;; random shades look nice
    set size 0.5  ;; easier to see
    setxy random-xcor random-ycor
    set flockmates no-turtles
    set flockmates-protected-zone no-turtles
    set predator no-turtles
    set maxspeed 0.5
    set minspeed 0.01
    set maxbias 0.01
    set bias-increment 0.00004
    set biasval 0.001
    set scout 2
    set vx 0.01
    set vy 0.01
    set typeanimal 0
  ]

  create-turtles predators
  [ set color green  ;; random shades look nice
    set size 1  ;; easier to see
    setxy random-xcor random-ycor
    set flockmates no-turtles
    set flockmates-protected-zone no-turtles
    set predator no-turtles
    set maxspeed 0.5
    set minspeed 0.01
    set maxbias 0.01
    set bias-increment 0.00004
    set biasval 0.001
    set scout 2
    set vx 0.01
    set vy 0.01
    set typeanimal 1
  ]
  reset-ticks
end

to go
  update-margins
  ask turtles [ flock ]
  tick
end


to flock  ;; turtle procedure
  find-predators
  check-dies
  find-flockmates-protected-zone
  find-flockmates

  ifelse [xcor] of self <= left-edge or [xcor] of self >= right-edge or [ycor] of self <= bottom-edge or [ycor] of self >= top-edge [screen-edges]
  [
  (ifelse
      predator != nobody [
        separate-predator
      ]
      any? flockmates-protected-zone
      [
        separate
      ]
      any? flockmates
      [
        align
        cohere
      ]
  )
  ]
  bias
  speed-limits
  update-position
end

to find-flockmates  ;; turtle procedure
  set flockmates other turtles in-radius visualRange with [not member? self flockmates-protected-zone]
end

to find-flockmates-protected-zone
  set flockmates-protected-zone other turtles in-radius protectedRange
end

to find-predators
  let predator_temp other turtles with [typeanimal = 1]
  set predator_temp predator_temp in-radius visualRange
  set predator min-one-of predator_temp [distance myself]
end

to check-dies
  if predator != nobody [
    if ([distance predator] of self <= 0.5)[
      die
    ]
  ]
end

to-report get-close-x
  report (([xcor] of self * count flockmates-protected-zone) - sum [xcor] of flockmates-protected-zone)
end

to-report get-close-y
  report (([ycor] of self * count flockmates-protected-zone) - sum [ycor] of flockmates-protected-zone)
end

to-report get-close-x-predator
  report ([xcor] of self - [xcor] of predator)
end

to-report get-close-y-predator
  report ([ycor] of self - [ycor] of predator)
end


to separate
  let close_dx ([vx] of self + (get-close-x * avoidfactor))
  let close_dy ([vy] of self + (get-close-y * avoidfactor))
  let radius_turn [heading] of self
  if close_dx != 0 [
    set radius_turn atan close_dx close_dy
  ]
  ;;turn-away radius_turn max-separate-turn
  ask self
  [
    set vx close_dx
    set vy close_dy
    set al-or-s 0
  ]
end

to separate-predator
  let close_dx ([vx] of self + (get-close-x-predator * avoidfactor-predator))
  let close_dy ([vy] of self + (get-close-y-predator * avoidfactor-predator))

  ask self
  [
    set vx close_dx
    set vy close_dy
    set al-or-s 0
  ]
end

to align
  let temp_length count flockmates
  let xvel_avg mean [vx] of flockmates
  let yvel_avg mean [vy] of flockmates

  let align_vx ([vx] of self + ((xvel_avg - [vx] of self) * matchingfactor))
  let align_vy ([vy] of self + ((yvel_avg - [vy] of self) * matchingfactor))

  if temp_length > 0 [
   ask self [
      set vx align_vx
      set vy align_vy
      set al-or-s 1
    ]
  ]
end

to cohere
  let xpos_avg mean [xcor] of flockmates
  let ypos_avg mean [ycor] of flockmates
  let temp_length count flockmates

  let cohere_vx ([vx] of self + ((xpos_avg - [xcor] of self) * centeringfactor))
  let cohere_vy ([vy] of self + ((ypos_avg - [ycor] of self) * centeringfactor))

  if temp_length > 0 [
    ask self [
      set vx cohere_vx
      set vy cohere_vy
      set al-or-s 1
    ]
  ]

end

to screen-edges

 ( ifelse [xcor] of self <= left-edge [
    ask self [
      set vx  (vx + turnfactor)
    ]
  ]
  [xcor] of self >= right-edge [
    ask self [
      set vx  (vx - turnfactor)
    ]
  ]
  [ycor] of self <= bottom-edge [
    ask self [
      set vy  (vy + turnfactor)
    ]
  ]
  [ycor] of self >= top-edge [
    ask self [
      set vy  (vy - turnfactor)
    ]
  ]
  )
end

to speed-limits
  let speed sqrt (([vx] of self * [vx] of self) + ([vy] of self * [vy] of self))
  if speed > maxspeed[
    ask self [
      set vx ((vx / speed) * maxspeed)
      set vy ((vy / speed) * maxspeed)
    ]
  ]
  if speed < minspeed [
    ask self [
      set vx ((vx / speed) * minspeed)
      set vy ((vy / speed) * minspeed)
    ]
  ]
end

to before-bias
  if [scout] of self = 1 [
    ifelse [vx] of self > 0 [
      let temp ([biasval] of self + bias-increment)
      ask self [
        set biasval min list maxbias temp
      ]
    ]
    [
      let temp ([biasval] of self - bias-increment)
      ask self [
        set biasval max list bias-increment temp
      ]
    ]
  ]

  if [scout] of self = 2 [
    ifelse [vx] of self < 0 [
      let temp ([biasval] of self + bias-increment)
      ask self [
        set biasval min list maxbias temp
      ]
    ]
    [
      let temp ([biasval] of self - bias-increment)
      ask self [
        set biasval max list bias-increment temp
      ]
    ]
  ]
end

to bias
  if [scout] of self = 1 [
    ask self [
      set vx (((1 - biasval) * vx) + (biasval * 1))
    ]
  ]
  if [scout] of self = 2 [
    ask self [
      set vx (((1 - biasval) * vx) + (biasval * (-1)))
    ]
  ]
end

to update-position

  ask self [
    let v_turn atan vx vy
    (ifelse xcor <= left-edge or xcor >= right-edge or ycor <= bottom-edge or ycor >= top-edge [
      if v_turn > 0 [turn-towards v_turn max-edge-turn]
      ]
    [
    ifelse al-or-s = 0 [
      turn-away v_turn max-separate-turn
    ] [turn-towards v_turn max-global-turn]
    ])
    fd sqrt (vx * vx + vy * vy)
  ]
end


to update-margins
  if left-edge != leftmargin + min-pxcor
    [ set left-edge leftmargin + min-pxcor
      draw-margins ]
  if right-edge != max-pxcor - rightmargin
    [ set right-edge max-pxcor - rightmargin
      draw-margins ]
  if top-edge != max-pycor - topmargin
    [ set top-edge max-pycor - topmargin
      draw-margins ]
  if bottom-edge != bottommargin + min-pycor
    [ set bottom-edge bottommargin + min-pycor
      draw-margins ]
end

to draw-margins
  ask patches [
    if (pxcor = leftmargin + min-pxcor) or (pxcor = max-pxcor - rightmargin) or (pycor = max-pycor - topmargin) or (pycor = min-pycor + bottommargin) [
      set pcolor red
    ]
  ]
end

;;; HELPER PROCEDURES

to turn-towards [new-heading max-turn]  ;; turtle procedure
  turn-at-most (subtract-headings new-heading heading) max-turn
end

to turn-away [new-heading max-turn]  ;; turtle procedure
  turn-at-most (subtract-headings heading new-heading) max-turn
end

;; turn right by "turn" degrees (or left if "turn" is negative),
;; but never turn more than "max-turn" degrees
to turn-at-most [turn max-turn]  ;; turtle procedure
  ifelse abs turn > max-turn
    [ ifelse turn > 0
        [ rt max-turn ]
        [ lt max-turn ] ]
    [ rt turn ]
end
@#$#@#$#@
GRAPHICS-WINDOW
240
17
1431
819
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-45
45
-30
30
1
1
1
ticks
30.0

SLIDER
29
71
201
104
population
population
1
1000
485.0
1
1
NIL
HORIZONTAL

BUTTON
136
29
199
62
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
30
28
93
61
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
29
115
201
148
turnfactor
turnfactor
0.0001
2
0.2801
0.005
1
NIL
HORIZONTAL

SLIDER
29
157
201
190
visualRange
visualRange
0.1
5
5.0
0.1
1
pathes
HORIZONTAL

SLIDER
28
201
207
234
protectedRange
protectedRange
0.05
5
0.75
0.05
1
patches
HORIZONTAL

SLIDER
28
243
200
276
centeringfactor
centeringfactor
0.0005
0.05
0.00625
0.00025
1
NIL
HORIZONTAL

SLIDER
29
288
201
321
avoidfactor
avoidfactor
0.05
0.1
0.075
0.025
1
NIL
HORIZONTAL

SLIDER
31
331
203
364
matchingfactor
matchingfactor
0.05
1
1.0
0.025
1
NIL
HORIZONTAL

INPUTBOX
35
379
190
439
group-one
0.0
1
0
Number

INPUTBOX
34
449
189
509
group-two
0.0
1
0
Number

SLIDER
25
579
197
612
leftmargin
leftmargin
0
10
5.0
1
1
patches
HORIZONTAL

SLIDER
24
621
196
654
rightmargin
rightmargin
0
10
5.0
1
1
patches
HORIZONTAL

SLIDER
27
697
199
730
bottommargin
bottommargin
0
10
5.0
1
1
patches
HORIZONTAL

SLIDER
26
658
198
691
topmargin
topmargin
0
10
5.0
1
1
patches
HORIZONTAL

SLIDER
24
734
199
767
max-edge-turn
max-edge-turn
0
30
7.0
1
1
degrees
HORIZONTAL

SLIDER
25
773
199
806
max-separate-turn
max-separate-turn
1
30
3.0
1
1
degrees
HORIZONTAL

SLIDER
28
813
200
846
maxbias
maxbias
0.01
1
0.01
0.01
1
NIL
HORIZONTAL

SLIDER
29
849
201
882
bias-increment
bias-increment
0.0001
0.1
4.0E-5
0.0001
1
NIL
HORIZONTAL

INPUTBOX
34
513
189
573
predators
0.0
1
0
Number

SLIDER
247
839
419
872
avoidfactor-predator
avoidfactor-predator
0.001
0.1
0.09
0.00025
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
