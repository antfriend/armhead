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

  SENSOR_MIN = 1
  SENSOR_FOCUAL = 1000
  SENSOR_MAX = 10000

  CURSOR_X = 10     'This value sets the left alignment for printing all the values

  TILT_MAX_STEP = 50
 
OBJ
  move      : "movement"
  sensor    : "Si1143"
  'debug     : "FullDuplexSerial"

VAR
  long  samples[5]
  long  sampleCount

  long left_eye
  long right_eye
  long third_eye
  
PUB main | i, x, y, z
  init
  

  move.home_position

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
      'move_to_sensor_focal
      'turn_to_middle_range
      if(all_eyes_below_threshold == TRUE)
        move.home_position
      else
        turn_to_middle_range      
    else
      move.home_position
      'relax
      'speed := random_speed
      'slew_to(random_number,random_number,random_number,random_speed)
      'repeat random_speed       
       ' set_eye_values
        'move_to_sensor_focal
        'set_eye_values
        'turn_to_middle_range

PRI all_eyes_below_threshold
  
  if((left_eye =< SENSOR_MIN) AND (right_eye =< SENSOR_MIN) AND (third_eye =< SENSOR_MIN))
    return TRUE
  
  return FALSE
      
PRI move_to_sensor_focal
  'only watching left eye
  'depends on set_eye_values
  if(left_eye > SENSOR_MIN)
    if(left_eye < SENSOR_FOCUAL)
      back_off
    else
      get_closer
      
PRI back_off
  move.back_off

PRI get_closer
  move.get_closer 

PRI left_top_forward
  move.move_to(-100,-100,-100)

PRI right_bottom_back
  move.move_to(100,100,100)

PRI center_middle
  move.move_to(1,1,1)

PRI tilt_head_to_middle | val
  'depends on set_eye_values
  if(left_eye > third_eye)
    val := (left_eye - third_eye + 10)
    if(val > TILT_MAX_STEP)
      val := TILT_MAX_STEP
    move.drift_upward(val)  
  elseif(left_eye < third_eye)
    val := (third_eye - left_eye + 10)
    if(val > TILT_MAX_STEP)
      val := TILT_MAX_STEP
    move.drift_downward(val)
  'else
  '  relax

PRI turn_to_middle_range | val
  'depends on set_eye_values
  if(left_eye > right_eye)
    val := (left_eye - right_eye)/5
    move.drift_leftward(val)  
  elseif(left_eye < right_eye)
    val := (right_eye - left_eye)/5
    move.drift_rightward(val)
  else
    val := 0
  if(val < 10)
    tilt_head_to_middle

PRI map_eye_to_slew(eye_value) | max_thresh
  max_thresh := 10000
  if(eye_value > max_thresh)
    eye_value := max_thresh
  return map(eye_value, 0, max_thresh, -100, 100)
   
PRI set_eye_values
  sampleCount := sensor.SampleOnce(@samples)
  left_eye := samples[2] 
  right_eye := samples[4] 
  third_eye := samples[3] 

PRI init
  dira[PID_PIN] := 0

  'Start the Si1143 device driver
  sensor.Start(SDA_PIN, SCL_PIN, INT_PIN)

  'Store the baseline average offset values (accomodates for optical leakage
  'between the LEDs and the sensor).
  sensor.PsBaselineSet          'NOTE: THIS LINE CAN BE COMMENTED OUT TO GET
                                'THE RAW VALUES FOR PS1, PS2, & PS3

  move.init
  move.speed(50)

PRI map(x, in_min, in_max, out_min, out_max)
  x := (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
  if(x > out_max)
    x := out_max
  if(x < out_min)
    x := out_min    
  return x
  
PRI human_detected
  return ina[PID_PIN]

  
{ 
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