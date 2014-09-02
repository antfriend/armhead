{{

  Dan Ray

}}

CON
  _clkmode = xtal1 + pll16x
  _clkfreq = 80_000_000

  'Pin used to connect to the PID
  PID_PIN = 3 

  'Pins used to connect to the "Si1143 Proximity Sensor" module
  SDA_PIN = 0
  SCL_PIN = 1
  INT_PIN = 2

  SENSOR_MIN = 0
  SENSOR_FOCUAL = 1000
  SENSOR_MAX = 10000

  CURSOR_X = 10     'This value sets the left alignment for printing all the values

  'max values for individual servos
  SERVO_MAX = 1800
  SERVO_MIN = 1000
  SERVO_MID = 1500
  SERVO_MAX_STEP = 300
  TILT_MAX_STEP = 50

  RAND_MIN = -2147483648
  RAND_MAX = 2147483647
  
OBJ
  SERVO     : "Servo4"
  sensor    : "Si1143"
  'debug     : "FullDuplexSerial"

VAR
  long  samples[5]
  long  sampleCount

  long left_eye
  long right_eye
  long third_eye

  long x_pos
  long y_pos
  long z_pos

  long speed '~10 to about 100, higher values up to at least 500 are ok but pretty slow
  long ran
  
PUB main | i, x, y, z
  init
  
  'speed := 10   'exceedingly fast
  speed := 50 'medium
  'speed := 100  'medium slow
  'speed := 200  'exceedingly slow
  home_position

 {  
  repeat i from 20 to 120 step 10
     speed := i
     slew_to(random_number,random_number,random_number,speed)

  repeat i from 90 to 30 step -10
    speed := i
    center_middle
    left_top_forward
    center_middle
    right_bottom_back
    center_middle

  'slew_to_centroid
  
  'TestMovements
  'home_stop
  'RunDemo
 }
  
  repeat
    if(human_detected)
      'repeat 10
      set_eye_values
      move_to_sensor_focal
      set_eye_values
      turn_to_middle_range      
    'else
      'relax
      'speed := random_speed
      'slew_to(random_number,random_number,random_number,random_speed)
      'repeat random_speed       
       ' set_eye_values
        'move_to_sensor_focal
        'set_eye_values
        'turn_to_middle_range
      
PRI move_to_sensor_focal
  'only watching left eye
  'depends on set_eye_values
  if(left_eye > SENSOR_MIN)
    if(left_eye < SENSOR_FOCUAL)
      back_off
    else
      get_closer
      
PRI back_off
  if(z_pos < 100)
    z_pos := z_pos + 5
        drift_upward(50)
    slew_to(0,y_pos,z_pos,1)

PRI get_closer
  if(z_pos > -100)
    z_pos := z_pos - 5
    drift_downward(50)
    slew_to(0,0,z_pos,1)

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

PRI left_top_forward
  slew_to(-100,-100,-100,speed)

PRI right_bottom_back
  slew_to(100,100,100,speed)

PRI center_middle
  slew_to(1,1,1,speed)

PRI tilt_head_to_middle | val
  'depends on set_eye_values
  if(left_eye > third_eye)
    val := (left_eye - third_eye + 10)
    if(val > TILT_MAX_STEP)
      val := TILT_MAX_STEP
    drift_upward(val)  
  elseif(left_eye < third_eye)
    val := (third_eye - left_eye + 10)
    if(val > TILT_MAX_STEP)
      val := TILT_MAX_STEP
    drift_downward(val)
  'else
  '  relax

PRI map_eye_to_slew(eye_value) | max_thresh
  max_thresh := 10000
  if(eye_value > max_thresh)
    eye_value := max_thresh
  return map(eye_value, 0, max_thresh, -100, 100)

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

PRI slew_to_centroid | val
  set_eye_values

  'this aint right at all

  
  'map eye values
  x_pos := map_eye_to_slew(left_eye)
  val := map_eye_to_slew(y_pos)
  val := map_eye_to_slew(z_pos)

  if(left_eye > right_eye)
    if(left_eye > third_eye)
      'left eye is greatest
      
    val := (left_eye - right_eye)'/10
    if(val > SERVO_MAX_STEP)
      val := SERVO_MAX_STEP

    
  elseif(left_eye < right_eye)
    val := (right_eye - left_eye)'/10
    if(val > SERVO_MAX_STEP)
      val := SERVO_MAX_STEP
    drift_rightward(val)
  else
    val := 0
  if(val < 10)
    tilt_head_to_middle  
      
PRI turn_to_middle_range | val
  'depends on set_eye_values
  if(left_eye > right_eye)
    val := (left_eye - right_eye)/5
    if(val > SERVO_MAX_STEP)
      val := SERVO_MAX_STEP
    drift_leftward(val)  
  elseif(left_eye < right_eye)
    val := (right_eye - left_eye)/5
    if(val > SERVO_MAX_STEP)
      val := SERVO_MAX_STEP
    drift_rightward(val)
  else
    val := 0
  if(val < 10)
    tilt_head_to_middle

PRI drift_downward(how_much) 
  tilt_head(y_pos + how_much,1)
  wait_for_head
  
PRI drift_upward(how_much)'drift_downward
  tilt_head(y_pos - how_much,1)
  wait_for_head 

PRI drift_leftward(how_much) 
  turn_base(x_pos + how_much,1)
  wait_for_base
  
PRI drift_rightward(how_much)
  turn_base(x_pos - how_much,1)
  wait_for_base 
    
PRI set_eye_values
  sampleCount := sensor.SampleOnce(@samples)
  left_eye := samples[2] 
  right_eye := samples[4] 
  third_eye := samples[3] 

PRI init
  dira[PID_PIN] := 0
  servo.start(1500,21,1000,22,2000,23,0,24)
  'Start the Si1143 device driver
  sensor.Start(SDA_PIN, SCL_PIN, INT_PIN)

  'Store the baseline average offset values (accomodates for optical leakage
  'between the LEDs and the sensor).
  sensor.PsBaselineSet          'NOTE: THIS LINE CAN BE COMMENTED OUT TO GET
                                'THE RAW VALUES FOR PS1, PS2, & PS3

  speed := 50
  ran := cnt ' initialize ran from the clock
  
PRI human_detected
  return ina[PID_PIN]

PRI turn_base(pos, cycles) 
  if(pos > SERVO_MAX)
    x_pos := SERVO_MAX
  elseif(pos < SERVO_MIN)
    x_pos := SERVO_MIN
  else   
    x_pos := pos
  servo.move_to(0,x_pos,cycles)  

PRI lean_neck(pos, cycles)
  servo.move_to(1,pos,cycles)  

PRI tilt_head(pos, cycles)
  if(pos > SERVO_MAX)
    y_pos := SERVO_MAX
  elseif(pos < SERVO_MIN)
    y_pos := SERVO_MIN
  else   
    y_pos := pos
  servo.move_to(2,y_pos,cycles)  

PRI wait_for_all
  wait_for_base
  wait_for_neck
  wait_for_head
  
PRI wait_for_base
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
      
PRI home_position
    turn_base(1500,speed)
    servo.move_to(1,1000,speed)
    tilt_head(SERVO_MAX,speed)
    wait_for_base  
    wait_for_neck
    wait_for_head
    
PRI home_stop
      home_position
      home_position
      home_position
      home_position
      relax
      
PRI look_up
    servo.move_to(1,1000,speed)
    tilt_head(SERVO_MIN,speed)
    wait_for_head

PRI look_down
    tilt_head(SERVO_MAX,speed)
    servo.move_to(1,2000,speed)
    wait_for_head

PRI look_left
    turn_base(SERVO_MAX,speed)
    wait_for_base
    
PRI look_right
    turn_base(SERVO_MIN,speed)
    wait_for_base
    
PRI go_in_for_closer_inspection
    tilt_head(SERVO_MIN,speed)
    servo.move_to(1,2000,speed)
    wait_for_head
                            
PRI go | unit0
  unit0 := 1
  
  repeat 1
    servo.move_to(0,1000,100)
    'servo.wait(0)
    servo.move_to(1,1000,100)
    'servo.wait(1)
    servo.move_to(2,1000,100)
    servo.wait(2)

    servo.move_to(0,2000,50)
    servo.wait(0)
    
    servo.move_to(0,1500,50)
    'servo.wait(0)
    servo.move_to(1,1500,50)
    'servo.wait(1)
    servo.move_to(2,1500,50)
    servo.wait(2)

    servo.move_to(1,2000,50)
    servo.wait(1)
    
    servo.move_to(0,2000,50)
    'servo.wait(0)
    servo.move_to(1,2000,50)
    'servo.wait(1)
    servo.move_to(2,2000,50)
    servo.wait(2)

    servo.move_to(2,1000,50)
    servo.wait(2)

    servo.move_to(0,1500,10)
    'servo.wait(0)
    servo.move_to(1,1500,10)
    'servo.wait(1)
    servo.move_to(2,1500,10)
    servo.wait(2)
    
{
    servo.move_to(0,1000,100)
    servo.wait(0)
    servo.move_to(1,1000,100)
    servo.wait(1)
    servo.move_to(2,1000,100)
    servo.wait(2)
          
    servo.move_to(0,2000,50)    'move two at once
    servo.move_to(1,2000,10)
    servo.wait(0)               'wait on the longest motion
    
    servo.move_to(2,1000,25)
    servo.wait(2)
    
    servo.move_to(1,800,20)
    servo.wait(1)               'move one at a time
    
    if unit0                    'cycle unit 0 on and off
      servo.move_to(0,1500,1)      'unit 0 no signal
      unit0~
    else
      servo.move_to(0,1000,1)
      unit0~~
 }
 
  servo.move_to(0,0,1)
  servo.move_to(1,0,1)
  servo.move_to(2,0,1)
  servo.wait(2)

PRI TestMovements

      home_position
      go_in_for_closer_inspection
      home_position
      look_up
      look_down
      home_position
      look_left
      look_left 
      look_right
      look_right
      home_position
      go_in_for_closer_inspection
      look_left
      look_right
      home_stop
      'go 
  
  'RunDemo
{
PRI RunDemo | index

  'Start the serial terminal to display debug text
  debug.Start(31, 30, 0, 115200)
                            

  'Store the baseline average offset values (accomodates for optical leakage
  'between the LEDs and the sensor).
  'sensor.PsBaselineSet          'NOTE: THIS LINE CAN BE COMMENTED OUT TO GET
                                'THE RAW VALUES FOR PS1, PS2, & PS3


  'Print startup text to the terminal
  debug.tx(0)                   
  debug.str(string("=================="))
  debug.tx(13)
  debug.str(string("Si1143 Sensor Demo"))
  debug.tx(13)
  debug.str(string("=================="))
  debug.tx(13)
  debug.str(string("Sample# = "))
  debug.tx(13)
  debug.tx(13) 
  debug.str(string("ALS VIS = "))
  debug.tx(13)
  debug.str(string("ALS IR  = "))
  debug.tx(13)
  debug.str(string("PS1:    = "))
  debug.tx(13)
  debug.str(string("PS2:    = "))
  debug.tx(13)
  debug.str(string("PS3:    = "))
    
  'Stay in this loop and take measurements forever 
  repeat 
    'Get a new set of samples
    sampleCount := sensor.SampleOnce(@samples)
    
    'Display the sample count value
    debug.tx(2)                 'Position cursor (x,y)
    debug.tx(CURSOR_X)          'X
    debug.tx(3)                 'Y
    debug.dec(sampleCount)      'Display value
    debug.str(string("        "))
    
     
    'Display all the sample values returned in the array
    repeat index from 0 to 4   
      debug.tx(2)                 'Position cursor (x,y)
      debug.tx(CURSOR_X)          'X
      debug.tx(index + 5)         'Y
      debug.dec(samples[index])   'Display value
      debug.str(string("        "))
 }
  

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