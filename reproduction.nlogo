;; all global variables
globals [

  ;; globals that can be modified in the interface
  cost_of_living ; how much does it cost to live one year?
  cost_of_child ; how much does it cost to have a child per year?
  inflation ; percentage. how much the costs will increase per year?
  income_increase ; in average how will turtles earnings increase per year
  ideal_children_quantity ; how many kids, on average, do couples want to have
  avg_annual_income ;; in average how much does a turtle earn per year

  ;; globals that can be modified only in code.
  lifespan ; average turtle lifespan (global average)
  maturity_age ; when do turtles can reproduce
  births-per-year ; how many births are in one tick in women
]

turtles-own [
  coupled? ; If true, the turtle already has a couple.
  ;; the couple will stay together until they die.
  partner ; The turtle that is their partner
  age ; age of the turtle
  sex ; sex of the turtle, either 0 or 1

  ;; controled by slider
  annual_earnings ; how much does the turtle earn in a year
  children ; current amount of children
]

;;;
;;; SETUP PROCEDURES
;;;

to setup
  clear-all
  setup-globals
  setup-people
  reset-ticks
end

to setup-globals
  set lifespan 60
  set maturity_age 18
  set cost_of_living avg-cost-of-living
  set cost_of_child avg-cost-of-child
  set avg_annual_income median-annual-income
  set income_increase yearly-income-increase
  set inflation yearly-inflation
end

to setup-people
  create-turtles initial-people
  [
    setxy random-xcor random-ycor
    set shape "person"
    ifelse random 2 = 0
    [ set sex 0 ]
    [ set sex 1 ]
    set coupled? false
    set partner nobody
    set children 0
    assign-color
    assign-earnings
    assign-age
  ]
end

to assign-color  ;; turtle procedure
  ifelse sex = 0
    [ set color pink ]
    [ set color cyan ]
end

to assign-earnings
  set annual_earnings random-near avg_annual_income
end

to assign-age
  set age random-near initial-average-age
end

to-report random-near [center]  ;; turtle procedure
  let result 0
  repeat 40
    [ set result (result + random-float center) ]
  report result / 20
end

;;;
;;; GO PROCEDURES
;;;

to go

  if count turtles with [ sex = 0 ] < 1 [ stop ] ; if there is no girl then we stop the program

  check-sliders ; if the user changed input in the interface we adjust

  ask turtles [ set age age + 1] ; get one year older
  ask turtles [ if age > lifespan [ kill-turtle ] ] ; if over lifespan die


  ; move while not coupled
  ask turtles [
    if not coupled? [ move ]
  ]

  ask turtles [
    if not coupled? and sex = 0 and age > maturity_age [ couple ]
  ]

  ask turtles [
    if coupled? and sex = 0 [ check-reproduce ]
  ]

  ;; setting the TFR
  let w_c count turtles with [sex = 0 and age > maturity_age ]
  let chidr_c sum [ children ] of turtles  with [sex = 0 and age > maturity_age]

  ifelse w_c > 0  [ set births-per-year (chidr_c / w_c) ] [ set births-per-year 0 ]

  ;; now we will update some values
  set cost_of_living (cost_of_living + (cost_of_living * inflation))
  set cost_of_child (cost_of_child + (cost_of_child * inflation))
  ;; for turtles that are just born
  set avg_annual_income (avg_annual_income + (avg_annual_income * income_increase))

  ask turtles [
    set annual_earnings (annual_earnings + (annual_earnings * income_increase))
  ]

  tick

end

to move  ;; turtle move in random direction
  rt random-float 360
  fd 1
end

;; procedure to kill a turtle
to kill-turtle
  set pcolor black
  if coupled? [
    ask (patch-at 1 0) [ set pcolor black ] ; making sure to change color of the patch, even if the current turtle is not sex 0
    ask (patch-at -1 0) [ set pcolor black ]
    ask partner [set coupled? false ]
    ask partner [ set partner nobody ]
  ]
  die
end

;; procedure to get two turtles together
to couple
  ; a suitable partner must be the opposite sex, not coupled and appropiate age
  let potential-partner one-of (turtles-at -1 0) with [not coupled? and sex = 1 and age > maturity_age]

  ; if found suitable partner
  if potential-partner != nobody [
    set partner potential-partner
    set coupled? true
    ask partner [ set coupled? true ]
    ask partner [ set partner myself ]
    move-to patch-here ; move to center of patch
    ask potential-partner [ move-to patch-here ]
    set pcolor gray - 3
    ask (patch-at -1 0) [ set pcolor gray - 3 ]
  ]

end

to reproduce

end

;; procedure to decide either to try reproduction
to check-reproduce
  let partner-earnings [ annual_earnings ] of partner
  let partner-children [ children ] of partner

  let total-children 0;

  ifelse partner-children > children [ set total-children partner-children ] [ set total-children children ]

  ifelse annual_earnings + partner-earnings > (cost_of_child * (total-children + 1)) + cost_of_living [
      try-new-turtle

  ]
  ;; if they don't have enough money, it's around 16% chance they still decide to reproduce
  ;; based on research of children living under poverty conditions
  [
    if  random-float 1 < .16   [
     try-new-turtle
    ]

  ]

end

;; procedure to decide if reproduction will be succesfull
to try-new-turtle
  let conceiving-rate .001;

  ;; per research, most people want around 2-3 children
  let  wish_baby? true
  if [ children ] of partner > ideal-children-quantity or children > ideal-children-quantity [ set wish_baby? false ]


  ;; there is a chance this person just does not want to have children at all
  if random-float 1 < %_no_children [ set wish_baby? false ]

  ;; the rate that if they try to reproduce they will succeed
  ;; based on real-life conceiving rate per year, it might change based on country
  ;; and available methods
  ;; base: TIMESOFINDIA.COM
  if age < 51 [ set conceiving-rate .05 ]
  if age < 41 [ set conceiving-rate .52 ]
  if age < 36 [ set conceiving-rate .63 ]
  if age < 31 [ set conceiving-rate .78 ]
  if age < 26 [ set conceiving-rate .86 ]

  if random-float 1 < conceiving-rate and wish_baby? = true [
    set children children + 1
    ask partner [ set children children + 1 ]
    set-new-turtle
  ]
end

;; procedure to insert a new turtle into the community
to set-new-turtle
  hatch 1 [
    setxy random-xcor random-ycor
    set shape "person"
    assign-earnings
    set age 0
    ifelse random 2 = 0
    [ set sex 0 ]
    [ set sex 1 ]
    set coupled? false
    set partner nobody
    set children 0
    assign-color
  ]
end

;; procedure to inject young people in the population
to add-young
  create-turtles 50 [
    setxy random-xcor random-ycor
    set shape "person"
    assign-earnings
    set age random-near 25
    ifelse random 2 = 0
    [ set sex 0 ]
    [ set sex 1 ]
    set coupled? false
    set partner nobody
    set children 0
    assign-color
  ]
end

;; procedure to update the variables if they change int he interface
to check-sliders

  if (income_increase != yearly-income-increase)
    [
      set income_increase yearly-income-increase
    ]

    if (inflation != yearly-inflation)
    [
      set inflation yearly-inflation
    ]
end
@#$#@#$#@
GRAPHICS-WINDOW
399
38
836
476
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
-16
16
-16
16
1
1
1
ticks
30.0

SLIDER
861
69
1048
102
avg-cost-of-living
avg-cost-of-living
1
100
44.0
1
1
K USD 
HORIZONTAL

SLIDER
862
114
1052
147
avg-cost-of-child
avg-cost-of-child
1
100
16.0
1
1
K USD
HORIZONTAL

SLIDER
863
158
1081
191
median-annual-income
median-annual-income
1
200
66.0
1
1
K USD
HORIZONTAL

SLIDER
859
458
1037
491
yearly-income-increase
yearly-income-increase
-1
1
0.04
.01
1
NIL
HORIZONTAL

SLIDER
862
502
1034
535
yearly-inflation
yearly-inflation
-1
1
0.04
.01
1
NIL
HORIZONTAL

SLIDER
864
203
1036
236
initial-people
initial-people
1
1000
1000.0
1
1
NIL
HORIZONTAL

BUTTON
18
45
364
83
setup
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

BUTTON
17
105
364
145
go
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

PLOT
9
185
380
473
Turtles
ticks
turtles
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

SLIDER
865
244
1037
277
initial-average-age
initial-average-age
1
90
38.0
1
1
NIL
HORIZONTAL

MONITOR
10
498
384
543
TFR
births-per-year
2
1
11

BUTTON
403
503
838
536
Add 50 young people
add-young
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
864
45
1014
63
Initial settings. Only for setup.
11
0.0
1

TEXTBOX
863
437
1110
465
These settings will be updated if changed.
11
0.0
1

PLOT
1105
46
1454
196
TFR per year
ticks
TFR
0.0
10.0
0.0
3.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot births-per-year"

PLOT
1106
216
1457
366
Annual Income and Costs 
Ticks
Money
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Annual income" 1.0 0 -5825686 true "" "plot avg_annual_income"
"Costs" 1.0 0 -13345367 true "" "plot cost_of_living + cost_of_child"

TEXTBOX
1112
378
1262
406
Blue = costs\nPink = avg. income
11
0.0
1

SLIDER
866
290
1039
323
ideal-children-quantity
ideal-children-quantity
0
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
867
333
1039
366
%_no_children
%_no_children
0
1
0.3
.1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model simulates the reproduction of humans living in developed countries based on financial factors such as their earnings versus the cost of living. It therefore illlustrates the effect of changing these variables in population increase or decrease. 

In developed countries there is a rising concern about the decline in fertility rates. Total Fertility Rate (TFR), and thus the birth rate, is one of the most important measures in demography, as its relevance affects government policies and the general well-being of the population. One of the reasons for this concern is the replacement level of fertility, The birth rate in most of the countries in the developed world is no longer sufficient to maintain the current population. 

Financial insecurity has been addressed as a factor contributing to the declining birth rates by several research, including increased unemployment, financial losses and economic uncertainty. 

This model examines the effects of financial variables on reproduction. The user controls some variables that relate to personal choices and current financial conditions in the community.


## HOW IT WORKS

Individual turtles wander around the world until they find around a suitable partner. The model uses "couples" to represent two people in a relationship. These couples every year take a decision on whether to reproduce or not, based on their combined earnings and determined by the age of one of them (for conceiving rate). 

If they reproduce, a new turtle aged 0 will be hatched, and the process will continue. 

## HOW TO USE IT

The SETUP button creates individuals based on the values the interface's buttons. After the setup, pressing the GO button will start the simulation. During the simulation you can adjust the values under the label "These settings will be updated if changed.", to see how they would impact in real time. 

A monitor shows the TFR of the population, and a graph is used to observe how the costs and income behave over time. Another graph is used to show how TFR changes over time. 

Here is the detail of what sliders do. 

- AVG-COST-OF-LIVING: Average cost of living in certain community per year
- AVG-COST-OF-CHILD: Average cost of child per year 
- MEDIAN-ANNUAL-INCOME: Median annual income of one turtle per year
- INITIAL-PEOPLE: How many people the simulation begins with. Take in consideration density of community or sparse time to find partners. 
- INITIAL-AVERAGE-AGE: The initial average age of the population, turtles will have a normal distribution. Note that because of this setting every experiment will have at first a high rise on births, but it will regulate after that. 
- IDEAL-CHILDREN-QUANTITY: Limits the children per woman. Even if women can afford as many children as they want, there is a limit. This can be based on personal preference, housing situation, the career path that allows them to have a high income, etc.
- %NO-CHILDREN: Percentage of women that decide not to have children, nonetheless of their situation.

The button "add 50 young people" helps to simulate migration. When clicked at any time, it will add 50 turtles close to 25 years old.

## THINGS TO NOTICE

Please refer to the document of this model to a more detail analysis of things to notice about the model. 

## THINGS TO TRY

Try different initial settings similar to your community and see if it behaves as expected. Also, you can try different initial population and average age, to see if population can be saved alone by increasing salaries or needs a migration boost. 

## EXTENDING THE MODEL

Like all similations, this model has simplified the behaviour of real life. Especially, it does not address for the ideal children quantity in a substancial way. Maybe an extension would be to address for house space or career path, as these two variables are regularly appointed on research as a reason couples decide not to have children.

Moreover, the model assumes that a "suitable partner" is anyone within adequate age range and opposite sex. This is not the case in real life, and an extension might take this into account. 

## RELATED MODELS

Some of the features come from NetLogo library model "HIV". Thank to the authors. 

## CREDITS AND REFERENCES

Wilensky, U. (1997). NetLogo HIV model. http://ccl.northwestern.edu/netlogo/models/HIV. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
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
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="ideal-children-quantity">
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="yearly-inflation">
      <value value="0.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-cost-of-living">
      <value value="48"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_no_children">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="median-annual-income">
      <value value="58"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-cost-of-child">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="yearly-income-increase">
      <value value="0.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-average-age">
      <value value="38"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="ideal-children-quantity">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="yearly-inflation">
      <value value="0.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-cost-of-living">
      <value value="48"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_no_children">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="median-annual-income">
      <value value="125"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-cost-of-child">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="yearly-income-increase">
      <value value="0.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-average-age">
      <value value="38"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="ideal-children-quantity">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="yearly-inflation">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-cost-of-living">
      <value value="44"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_no_children">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="median-annual-income">
      <value value="53"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-cost-of-child">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="yearly-income-increase">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-average-age">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="japan" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="ideal-children-quantity">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="yearly-inflation">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-cost-of-living">
      <value value="44"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_no_children">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="median-annual-income">
      <value value="53"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-cost-of-child">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="yearly-income-increase">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-average-age">
      <value value="49"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="us" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <exitCondition>count turtles &gt; 2000</exitCondition>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="ideal-children-quantity">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="yearly-inflation">
      <value value="0.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-cost-of-living">
      <value value="44"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_no_children">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="median-annual-income">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-cost-of-child">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-people">
      <value value="504"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="yearly-income-increase">
      <value value="0.02"/>
      <value value="0.03"/>
      <value value="0.04"/>
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-average-age">
      <value value="38"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="no" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="ideal-children-quantity">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="yearly-inflation">
      <value value="0.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-cost-of-living">
      <value value="44"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_no_children">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="median-annual-income">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-cost-of-child">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-people">
      <value value="504"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="yearly-income-increase">
      <value value="0.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-average-age">
      <value value="38"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="yes" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="ideal-children-quantity">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="yearly-inflation">
      <value value="0.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-cost-of-living">
      <value value="44"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_no_children">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="median-annual-income">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-cost-of-child">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-people">
      <value value="504"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="yearly-income-increase">
      <value value="0.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-average-age">
      <value value="38"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="people" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <exitCondition>count turtles &gt; 3000</exitCondition>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="ideal-children-quantity">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="yearly-inflation">
      <value value="0.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-cost-of-living">
      <value value="44"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_no_children">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="median-annual-income">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-cost-of-child">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-people">
      <value value="500"/>
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="yearly-income-increase">
      <value value="0.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-average-age">
      <value value="38"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
