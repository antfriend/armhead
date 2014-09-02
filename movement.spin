{{
  movement control
}}

CON

  'max values for individual servos
  SERVO_MAX = 1800
  SERVO_MIN = 1000
  SERVO_MID = 1500
  SERVO_MAX_STEP = 300 

  RAND_MIN = -2147483648
  RAND_MAX = 2147483647
 
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
    z_pos := z_pos + 5
        drift_upward(50)
    slew_to(0,y_pos,z_pos,1)

PUB get_closer
  if(z_pos > -100)
    z_pos := z_pos - 5
    drift_downward(50)
    slew_to(0,0,z_pos,1)

PUB move_to(x_val,y_val,z_val)
  slew_to(x_val,y_val,z_val,mov_speed)


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
      
PUB home_position
    turn_base(1500,mov_speed)
    servo.move_to(1,1000,mov_speed)
    tilt_head(SERVO_MAX,mov_speed)
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
    servo.move_to(1,1000,mov_speed)
    tilt_head(SERVO_MIN,mov_speed)
    wait_for_head

PRI look_down
    tilt_head(SERVO_MAX,mov_speed)
    servo.move_to(1,2000,mov_speed)
    wait_for_head

PRI look_left
    turn_base(SERVO_MAX,mov_speed)
    wait_for_base
    
PRI look_right
    turn_base(SERVO_MIN,mov_speed)
    wait_for_base
    
PRI go_in_for_closer_inspection
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

PRI slew_to_centroid | val
  {set_eye_values

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
    tilt_head_to_middle      }

PUB drift_downward(how_much) 
  tilt_head(y_pos + how_much,1)
  wait_for_head
  
PUB drift_upward(how_much)'drift_downward
  tilt_head(y_pos - how_much,1)
  wait_for_head 

PUB drift_leftward(how_much) 
  turn_base(x_pos + how_much,1)
  wait_for_base
  
PUB drift_rightward(how_much)
  turn_base(x_pos - how_much,1)
  wait_for_base 
