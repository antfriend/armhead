{{

  Dan Ray
+++++++++++++++++++++
+   armhead robot   +
+++++++++++++++++++++
  armhead.spin
      |  |
      |  movement.spin
      |          |
      |          servo4.spin
      Si1143.spin
            |
            I2C.spin
        
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
  SENSOR_FOCAL = 500 '1000
  DISTANCE_FOCAL = 500
  SENSOR_MAX = 10000

  'debug value
  'CURSOR_X = 10     'This value sets the left alignment for printing all the values for serial debug

  TILT_MAX_STEP = 50

  DIFF_THRESHOLD = 20
  PAUSE_CYCLES = 100'clkfreq/1000
 
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

PUB main | i, x, y, z
  init
  
  move.home_position
  'pause(PAUSE_CYCLES)
  'TestMovements
 
  repeat
    if(human_detected)
      move.speed(10) 'very fast
      set_eye_values
      if(left_is_greater)
        move.left_by(left_is_greater_by * 2)
        do_range_management
      else 'right is greater or equal
        move.right_by(right_is_greater_by * 2)
      if(up_is_greater)
        move.up_by(up_is_greater_by)
      else
        move.down_by(down_is_greater_by)

    else
        move.home_position       
    pause(PAUSE_CYCLES)

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

PRI do_range_management
  if(left_eye > 100)
    if(not_close_enough)
      move.closer_by(not_close_enough_by)
    else
      move.farther_by(too_close_by)
          
PRI not_close_enough
  return (left_eye < DISTANCE_FOCAL)'SENSOR_FOCAL

PRI not_close_enough_by | sensor_diff     
  sensor_diff := DISTANCE_FOCAL - left_eye
  return map(sensor_diff, 0, DISTANCE_FOCAL, 0, 100)

PRI too_close_by | sensor_diff
  sensor_diff := left_eye - DISTANCE_FOCAL    
  return map(sensor_diff, 0, DISTANCE_FOCAL, 0, 100)
  
PRI up_is_greater
  return (left_eye > third_eye)

PRI up_is_greater_by | sensor_diff
  sensor_diff := left_eye - third_eye
  return map(sensor_diff, 0, SENSOR_FOCAL, 0, 100)

PRI down_is_greater_by | sensor_diff
  sensor_diff := third_eye - left_eye
  return map(sensor_diff, 0, SENSOR_FOCAL, 0, 100)
 
PRI left_is_greater
  return (left_eye > right_eye)
    
PRI left_is_greater_by | sensor_diff
  sensor_diff := left_eye - right_eye 
  return map(sensor_diff, 0, SENSOR_FOCAL, 0, 100)'(sensor_diff,SERVO_MIN,SERVO_MID,SERVO_MAX) 

PRI right_is_greater_by | sensor_diff
  sensor_diff := right_eye - left_eye 
  return map(sensor_diff, 0, SENSOR_FOCAL, 0, 100)'(sensor_diff,SERVO_MIN,SERVO_MID,SERVO_MAX) 

PRI pause(for_cycles)
  'for_milliseconds
  'move.wait_for_base
  'waitcnt(for_cycles + cnt)
  'waitcnt(clkfreq/1000 + cnt)
   
PRI we_is_centered | lr_diff, tb_diff, left_to_right, top_to_bottom
  lr_diff := left_eye -  right_eye
  if(lr_diff > 0)'left eye is greater
    left_to_right := (lr_diff < DIFF_THRESHOLD)
  else'right eye is greater or equal  
    left_to_right := (lr_diff > -DIFF_THRESHOLD)
    
  if(left_to_right)'left and right are close enough
    lr_diff := (left_eye +  right_eye)/2
    tb_diff := lr_diff - third_eye
    if(tb_diff > 0)'top is greater
      return (tb_diff < DIFF_THRESHOLD)
    else'bottom is greater
      return (tb_diff > -DIFF_THRESHOLD)
  else
    return false 

PRI get_closer_or_farther | the_average
  the_average := (third_eye + right_eye + left_eye)/3
  if(the_average > DIFF_THRESHOLD)
    back_off
  else
    get_closer   

PRI centi_range_away
 return 1

PRI all_eyes_below_threshold
  if((left_eye =< SENSOR_MIN) AND (right_eye =< SENSOR_MIN) AND (third_eye =< SENSOR_MIN))
    return TRUE 
  return FALSE
      
PRI move_to_sensor_focal
  'only watching left eye
  'depends on set_eye_values
  if(left_eye > SENSOR_MIN)
    if(left_eye < SENSOR_FOCAL)
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

PRI map(x, in_min, in_max, out_min, out_max)
  x := (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
  if(x > out_max)
    x := out_max
  if(x < out_min)
    x := out_min    
  return x
  
PRI human_detected
  return ina[PID_PIN]

PRI TestMovements

      move.home_position 
      move.go_in_for_closer_inspection
      move.home_position
      move.look_up
      move.look_down
      move.home_position
      move.look_left
      move.look_left 
      move.look_right
      move.look_right
      move.home_position
      move.go_in_for_closer_inspection
      move.look_left
      move.look_right
      move.home_stop
      'go 


{
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
  if((val < 50) AND (val > -50))
    tilt_head_to_middle
 }
 

  
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