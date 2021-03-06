{{
  movement control
}}

CON

  'max values for individual servos
  SERVO_MAX = 1800
  SERVO_MIN = 1000
  SERVO_MID = 1500
  SERVO_MAX_STEP = 300

  BASE_SERVO_MAX = 2400
  BASE_SERVO_MIN = 900   

  RAND_MIN = -2147483648
  RAND_MAX = 2147483647

  BASE_X_SERVO = 0
  NECK_Z_SERVO = 1
  HEAD_Y_SERVO = 2
 
VAR
  long x_pos
  long y_pos
  long z_pos

  long mov_speed '~10 to about 100, higher values up to at least 500 are ok but pretty slow

  long ran
    
OBJ
    SERVO     : "Servo4"

PUB init
  'mov_speed := 10   'exceedingly fast
  mov_speed := 50 'medium
  'mov_speed := 100  'medium slow
  'mov_speed := 200  'exceedingly slow
  servo.start(1500,21,1000,22,2000,23,0,24)
  ran := cnt ' initialize ran from the clock
    
PUB speed(the_speed)
  mov_speed := the_speed
    
PUB back_off
  if(z_pos < 100)
    z_pos := z_pos + 1
        drift_upward(1)
    slew_to(0,y_pos,z_pos,1)

PUB get_closer
  if(z_pos > -100)
    z_pos := z_pos - 1
    drift_downward(1)
    slew_to(0,0,z_pos,1)

PUB move_to(x_val,y_val,z_val)
  slew_to(x_val,y_val,z_val,mov_speed)

PRI turn_base(pos, cycles)
  if(pos == 0)
    return
  if(pos > BASE_SERVO_MAX)
    x_pos := BASE_SERVO_MAX
  elseif(pos < BASE_SERVO_MIN)
    x_pos := BASE_SERVO_MIN
  else   
    x_pos := pos
  servo.move_to(BASE_X_SERVO,x_pos,cycles) 

PRI lean_neck(pos, cycles)
  if(pos == 0)
    return
  if(pos > SERVO_MAX)
    z_pos := SERVO_MAX
  elseif(pos < SERVO_MIN)
    z_pos := SERVO_MIN
  else   
    z_pos := pos
  servo.move_to(NECK_Z_SERVO,z_pos,cycles)  
                   
PRI tilt_head(pos, cycles)
  if(pos == 0)
    return
  if(pos > SERVO_MAX)
    y_pos := SERVO_MAX
  elseif(pos < SERVO_MIN)
    y_pos := SERVO_MIN
  else   
    y_pos := pos
  servo.move_to(HEAD_Y_SERVO,y_pos,cycles)  

PRI wait_for_all
  wait_for_base
  wait_for_neck
  wait_for_head
  
PUB wait_for_base
  servo.wait(0)

PRI wait_for_neck
  servo.wait(1)

PRI wait_for_head
  servo.wait(2)
  
PRI relax
    servo.move_to(0,0,1)
    servo.move_to(1,0,1)
    servo.move_to(2,0,1)
    wait_for_head
    'wait_for_neck
    'wait_for_base
      
PUB home_position
    turn_base(1500,mov_speed)
    lean_neck(1000,mov_speed)  
    'servo.move_to(NECK_Z_SERVO,1000,mov_speed)
    tilt_head(SERVO_MAX,mov_speed)
    'slew_to(0,100,-100,mov_speed)
    
PUB home_stop
      home_position
      relax
      
PUB look_up
    'servo.move_to(1,1000,mov_speed)
    tilt_head(SERVO_MIN,mov_speed)
    wait_for_head

PUB look_down
    tilt_head(SERVO_MAX,mov_speed)
    'servo.move_to(1,2000,mov_speed)
    wait_for_head

PUB look_left
    turn_base(SERVO_MAX,mov_speed)
    wait_for_base
    
PUB look_right
    turn_base(SERVO_MIN,mov_speed)
    wait_for_base
    
PUB go_in_for_closer_inspection
    tilt_head(SERVO_MIN,mov_speed)
    servo.move_to(1,2000,mov_speed)
    wait_for_head
                         
PRI random_number | r          '
  'between -100 and 100
  r := ran?
  r := map(r, RAND_MIN, RAND_MAX, -100, 100)
  if(r == 0)
    r := 1
  return r 

PRI random_speed | s
  'between 10 and 100
  s := ran?
  s := map(s, RAND_MIN, RAND_MAX, 10, 100)
  if(s == 0)
    s := 1
  return s 
    
PRI map(x, in_min, in_max, out_min, out_max)
  x := (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
  if(x > out_max)
    x := out_max
  if(x < out_min)
    x := out_min    
  return x

PRI map_to_min_mid_max_of_servo(pos, mini, mid, maxi) | increment
{
  val can be -100 to 100
  -100 maps to min
  1 maps to mid
  100 maps to max
}
  if(pos > 0)
    'map val mid to max
    increment := (maxi - mid)/100
    return mid + (pos * increment)
  elseif(pos < 0)
    'map val min to mid
    increment := (mid - mini)/100
    return mid + (pos * increment)'ex: 1500 + (-600)    
  else
    return 0 
 
PRI slew_to(x,y,z,in_this_many_steps)
{  x,y,z values can be -100 to 100 where zero means "don't change" and
   point 1,1,1 is the center of a conceptual cube
   left-top-forward-most corner is -100,-100,-100
   right-bottom-back-most corner is 100,100,100
   center-middle is 1,1,1   
}
  'get base (servo 0) servo position value and send it
  if(x <> 0)
    x_pos := x
    if(x_pos > 100)
      x_pos := 100
    if(x_pos < -100)
      x_pos := -100
    turn_base(map_to_min_mid_max_of_servo(x_pos,SERVO_MIN,SERVO_MID,SERVO_MAX),in_this_many_steps)
  
  'get head (servo 2) servo position value and send it
  if(y <> 0)
    y_pos := y
    if(y_pos > 100)
      y_pos := 100
    if(y_pos < -100)
      y_pos := -100    
    tilt_head(map_to_min_mid_max_of_servo(y_pos,SERVO_MIN,SERVO_MID,SERVO_MAX),in_this_many_steps)
  
  'get neck (servo 1) servo position value and send it
  if(z <> 0)
    z_pos := z
    if(z_pos > 100)
      z_pos := 100
    if(z_pos < -100)
      z_pos := -100
    lean_neck(map_to_min_mid_max_of_servo(z_pos,SERVO_MIN,SERVO_MID,SERVO_MAX),in_this_many_steps)

  'figure out which one to wait for

  'or just wait for all of them
  if(x <> 0)
    wait_for_base
  if(y <> 0)
    wait_for_head
  if(z <> 0)
    wait_for_neck

PUB drift_downward(how_much) 
  tilt_head(y_pos + how_much,1)
  wait_for_head
  
PUB drift_upward(how_much)'drift_downward
  tilt_head(y_pos - how_much,1)
  wait_for_head 

PUB closer_by(how_much)
  how_much := how_much / 3
  lean_neck(z_pos + how_much,1)
  up_by(how_much)

PUB farther_by(how_much)
  how_much := how_much
  lean_neck(z_pos - how_much,1)
  down_by(how_much) 

PUB right_by(how_much) 
  turn_base(x_pos - how_much,1) 

PUB left_by(how_much) 
  turn_base(x_pos + how_much,1) 

PUB up_by(how_much)
  tilt_head(y_pos - how_much,1) 

PUB down_by(how_much)
  tilt_head(y_pos + how_much,1) 

PUB drift_leftward(how_much) 
  turn_base(x_pos + how_much,1)
  wait_for_base
  
PUB drift_rightward(how_much)
  turn_base(x_pos - how_much,1)
  wait_for_base

DAT
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}  