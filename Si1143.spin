{{
File:    Si1143.spin
Version: 1.1
Date:    November 19, 2012

Author:  Kevin McCullough
Company: Gecko Engineering
         "Turning good ideas into great products." 
Phone:   541.660.2314
Email:   Kevin@GeckoEngineering.com
Web:     www.GeckoEngineering.com

Revision History:
v1.0 - 3/14/2012
  Initial release.
v1.1 - 11/19/2012
  Modified driver to effectively "rotate" the orientation of the sensor.  New orientation
  has LED1 in bottom-left, LED2 in top-left, and LED3 in bottom-right.  The header is
  considered the bottom edge.  The gesture event table, comments, and driver code was
  updated accordingly.  Note, this change only affected how the driver interprets events,
  and had no effect on any parent object code.  

Description:
This object is a driver for the "Si1143 Proximity Sensor" (Parallax PN: 28046).  It provides
the ability to read in a single set of proximity measurements, or run continous automatic
measurements.  Additionally, when in continous mode, this driver also looks for gesture
events and stores them in a queue to be handled by the user's application if desired.

Typical Connection Diagram:
                                   
               VIN = 3.3V                  
    ┌──────┐   ┬   ┬   ┬      ┬ ┌────────────────┐
    │      │   │   │   │      │ │•   [‣]        •│        
    │      │   R  R  R   ┌─┼─┤GND             │
    │      │   │   │   │     └─┤VIN   ┌─────────┘                        
    │    Px├───┻───┼───┼────────┤INT   │
    │    Py├───────┻───┼────────┤SCL   │        
    │    Px├───────────┻────────┤SDA   │
    │      │                    │•     │
    └──────┘                    └──────┘
    Propeller MCU               Si1143 Proximity
    (P8X32A)                     Sensor (28046)
                                  
    R = 4.7kΩ
    Px, Py, Pz = Any desired Propeller I/O pins               

               
}}

CON

  'I2C Device Address and Key value
  I2C_SLAVE_ADDR      = $5A     'Slave address of the Si1141/42/43
  HW_KEY_VAL0         = $17     'This value must be written into the device HW Key for proper operation after reset
  
  'I2C Registers (These can be used with the "WriteToRegister" function)
  REG_PART_ID            =  $00
  REG_REV_ID             =  $01
  REG_SEQ_ID             =  $02
  REG_IRQ_CFG            =  $03
  REG_IRQ_ENABLE         =  $04
  REG_IRQ_MODE1          =  $05
  REG_IRQ_MODE2          =  $06
  REG_HW_KEY             =  $07
  REG_MEAS_RATE          =  $08
  REG_ALS_RATE           =  $09
  REG_PS_RATE            =  $0A
  REG_ALS_LO_TH          =  $0B
  REG_ALS_HI_TH          =  $0D
  REG_ALS_IR_ADCMUX      =  $0E
  REG_PS_LED21           =  $0F
  REG_PS_LED3            =  $10
  REG_PS1_TH             =  $11
  REG_PS2_TH             =  $12
  REG_PS3_TH             =  $13
  REG_PS_LED3_TH0        =  $15
  REG_PARAM_IN           =  $17
  REG_PARAM_WR           =  $17
  REG_COMMAND            =  $18
  REG_RESPONSE           =  $20
  REG_IRQ_STATUS         =  $21
  REG_ALS_VIS_DATA0      =  $22
  REG_ALS_VIS_DATA1      =  $23
  REG_ALS_IR_DATA0       =  $24
  REG_ALS_IR_DATA1       =  $25
  REG_PS1_DATA0          =  $26
  REG_PS1_DATA1          =  $27
  REG_PS2_DATA0          =  $28
  REG_PS2_DATA1          =  $29
  REG_PS3_DATA0          =  $2A
  REG_PS3_DATA1          =  $2B
  REG_AUX_DATA0          =  $2C
  REG_AUX_DATA1          =  $2D
  REG_PARAM_OUT          =  $2E
  REG_PARAM_RD           =  $2E
  REG_CHIP_STAT          =  $30

  'Command Register Values
  CMD_PARAM_QUERY        =  $80    'Value is ORed with Parameter Offset                        
  CMD_PARAM_SET          =  $A0    'Value is ORed with Parameter Offset 
  CMD_PARAM_AND          =  $C0    'Value is ORed with Parameter Offset 
  CMD_PARAM_OR           =  $E0    'Value is ORed with Parameter Offset 
  CMD_NOP                =  $00
  CMD_RESET              =  $01
  CMD_BUSADDR            =  $02
  CMD_PS_FORCE           =  $05
  CMD_ALS_FORCE          =  $06
  CMD_PSALS_FORCE        =  $07
  CMD_PS_PAUSE           =  $09
  CMD_ALS_PAUSE          =  $0A
  CMD_PSALS_PAUSE        =  $0B
  CMD_PS_AUTO            =  $0D
  CMD_ALS_AUTO           =  $0E
  CMD_PSALS_AUTO         =  $0F
   
  'Parameter Offsets to use in the Command Register (These can be used with the "ParamSet" function) 
  PARAM_I2C_ADDR              =  $00
  PARAM_CH_LIST               =  $01
  PARAM_PSLED12_SELECT        =  $02
  PARAM_PSLED3_SELECT         =  $03
  PARAM_FILTER_EN             =  $04
  PARAM_PS_ENCODING           =  $05
  PARAM_ALS_ENCODING          =  $06
  PARAM_PS1_ADC_MUX           =  $07
  PARAM_PS2_ADC_MUX           =  $08
  PARAM_PS3_ADC_MUX           =  $09
  PARAM_PS_ADC_COUNTER        =  $0A
  PARAM_PS_ADC_CLKDIV         =  $0B
  PARAM_PS_ADC_GAIN           =  $0B
  PARAM_PS_ADC_MISC           =  $0C
  PARAM_ALS1_ADC_MUX          =  $0D
  PARAM_ALS2_ADC_MUX          =  $0E
  PARAM_ALS3_ADC_MUX          =  $0F
  PARAM_ALSVIS_ADC_COUNTER    =  $10
  PARAM_ALSVIS_ADC_CLKDIV     =  $11
  PARAM_ALSVIS_ADC_GAIN       =  $11
  PARAM_ALSVIS_ADC_MISC       =  $12
  PARAM_ALS_HYST              =  $16
  PARAM_PS_HYST               =  $17
  PARAM_PS_HISTORY            =  $18
  PARAM_ALS_HISTORY           =  $19
  PARAM_ADC_OFFSET            =  $1A
  PARAM_SLEEP_CTRL            =  $1B
  PARAM_LED_RECOVERY          =  $1C
  PARAM_ALSIR_ADC_COUNTER     =  $1D
  PARAM_ALSIR_ADC_CLKDIV      =  $1E
  PARAM_ALSIR_ADC_GAIN        =  $1E
  PARAM_ALSIR_ADC_MISC        =  $1F

  'Interrupt Flag Bits
  IRQ_ALS_INT0  = $01
  IRQ_ALS_INT1  = $02
  IRQ_PS1_INT   = $04
  IRQ_PS2_INT   = $08
  IRQ_PS3_INT   = $10
  IRQ_CMD_INT   = $20
  IRQ_ALL_CHANNELS = IRQ_ALS_INT0 + IRQ_PS1_INT + IRQ_PS2_INT + IRQ_PS3_INT   'This does NOT include the CMD interrupt
    
  'Measurement Channel List
  PS1_TASK               =  $01
  PS2_TASK               =  $02
  PS3_TASK               =  $04
  ALS_VIS_TASK           =  $10
  ALS_IR_TASK            =  $20
  AUX_TASK               =  $40
     
  'LED Drive Current Values (value is only 4-bits)
  LEDI_000_MA            =  $00
  LEDI_006_MA            =  $01
  LEDI_011_MA            =  $02
  LEDI_022_MA            =  $03
  LEDI_045_MA            =  $04
  LEDI_067_MA            =  $05
  LEDI_090_MA            =  $06
  LEDI_112_MA            =  $07
  LEDI_135_MA            =  $08
  LEDI_157_MA            =  $09
  LEDI_180_MA            =  $0A
  LEDI_202_MA            =  $0B
  LEDI_224_MA            =  $0C
  LEDI_269_MA            =  $0D
  LEDI_314_MA            =  $0E
  LEDI_359_MA            =  $0F
  MIN_LED_CURRENT        =  LEDI_006_MA
  MAX_LED_CURRENT        =  LEDI_359_MA
  DEFAULT_LED_CURRENT    =  LEDI_180_MA
      
  'Driver State Machine Modes
  #0
  STATE_IDLE                  
  STATE_INIT_STOP             
  STATE_INIT_SINGLE           
  STATE_INIT_CONTINUOUS       
  STATE_CONTINUOUS            

  'Messages used for the Driver Mailbox
  #0
  MSG_BUSY
  MSG_EMPTY                   
  MSG_MEAS_ONCE               
  MSG_MEAS_AUTO               
  MSG_MEAS_STOP               
  'MSG_REQ_NEW_DATA

'------------------------------------------------------------------------------  
'*********************************
'* DRIVER CONFIGURATION SETTINGS *
'*********************************
'These values define how the driver operates.  It is not recommended to modify these
'values unless there is specific reason to do so; however, it may be necessary to
'make adjustments depending on user preference or depending on the target application.
  
'Driver Minimum Sample Rate Interval (in ms)
MIN_SAMPLE_INTERVAL_MS = 50   'This sets the lower limit on sample interval time (or the upper limit on speed)
                              'Use care if modifying this value to make certain there is enough time
                              'left in the loop to read in all the new values and service the gesture
                              'recognition process and finish in time to capture each new sample.

'Baseline acquisition
BL_SAMPLES_PER_AVE  = 8       'This sets how many samples will be averaged when
                              'calculating the baseline values.

'Settings for Gesture Recognition Performance
GEST_ACTIVATION_THRESHOLD     = 300   'This is the threshold between low and high states
                                      'for detecting a rising or falling edge on each channel.
GEST_SIMULTANEOUS_TOLERANCE   = 0     'This is the maximum number of samples allowed between
                                      'edge events of different channels for the events to be
                                      'considered "simultaneous".  A value of 0 means the edge
                                      'events must occur on the exact same sample. Values greater
                                      'than 0 means there can be some number of samples between edges.
GEST_WINDOW_TIME_MS           = 3000  'This is the maximum amount of time (in ms) allowed
                                      'for a gesture to be recognized. This value is used along
                                      'with the sample time to calculate the number of samples
                                      'until an edge event expires and is discarded. Gestures
                                      'taking longer than this time window will be considered
                                      'invalid (since they are too slow).
GEST_QUEUE_SIZE               = 10    'This sets the size of the message queue ring buffer to hold
                                      'this many event messages. For example, a value of 6
                                      'means that up to 6 gesture event messages may be stored   Any
                                      'gestures after the queue is full will be lost.  Note that
                                      'most full swipe gestures are actually composed of 2 events,
                                      'an entry and exit event.
'*********************************
'* END of DRIVER CONFIG SETTINGS *
'*********************************
'------------------------------------------------------------------------------

  'Gesture Event Table
  'Events may be used by name (as constants) or interpreted as a bit-field values to filter for
  'certain event groups.  The bit field is organized as follows:
  'Bit 0: top
  'Bit 1: right
  'Bit 2: bottom
  'Bit 3: left
  'Bit 4: center
  'Bit 5: enter event
  'Bit 6: exit event
  '---
  EVENT_MASK_TOP      = %0000001
  EVENT_MASK_RIGHT    = %0000010
  EVENT_MASK_BOTTOM   = %0000100
  EVENT_MASK_LEFT     = %0001000
  EVENT_MASK_CENTER   = %0010000
  EVENT_MASK_ENTER    = %0100000
  EVENT_MASK_EXIT     = %1000000
  '---
  EVENT_NONE                = %0000000
  EVENT_ENTER_TOP           = %0100001
  EVENT_ENTER_TOP_RIGHT     = %0100011
  EVENT_ENTER_RIGHT         = %0100010
  EVENT_ENTER_BOTTOM_RIGHT  = %0100110
  EVENT_ENTER_BOTTOM        = %0100100
  EVENT_ENTER_BOTTOM_LEFT   = %0101100
  EVENT_ENTER_LEFT          = %0101000
  EVENT_ENTER_TOP_LEFT      = %0101001
  EVENT_ENTER_CENTER        = %0110000
  EVENT_EXIT_TOP            = %1000001
  EVENT_EXIT_TOP_RIGHT      = %1000011
  EVENT_EXIT_RIGHT          = %1000010
  EVENT_EXIT_BOTTOM_RIGHT   = %1000110
  EVENT_EXIT_BOTTOM         = %1000100
  EVENT_EXIT_BOTTOM_LEFT    = %1001100
  EVENT_EXIT_LEFT           = %1001000
  EVENT_EXIT_TOP_LEFT       = %1001001
  EVENT_EXIT_CENTER         = %1010000
    
               
OBJ
  i2c           : "I2C"
  
VAR
  'Variables for Setup and Utility
  long  stack[400]                     'Stack space for new cog
  byte  cog                            'Hold ID of cog in use, if any
  byte  mutexLock                      'Used to mutex while the driver is busy
  byte  sdaPin, sclPin, intPin         'Store pins for use in the new object

  'Variables for Operating the State Machine 
  byte  runState                'Used in the operating state machine for the current state of operation
  byte  msgMailbox              'Used to pass command messages back and forth between application code and driver.
  long  sampleRate              'Used to pass in the number of counts into the driver for AUTO mode.
                                'Note: this is the uncompressed 16-bit value. Must be compressed to 8-bits.
  
  'Variables for Storing Samples
  long  sampleVal[5]     'This array stores the sample values: ALS_VIS, ALS_IR, PS1, PS2, PS3 (in that order).                     
  long  sampleCnt        'This stores the current sample count.
  long  baselinePS[3]    'This array holds the baseline average offset values for PS1, PS2, PS3 (in that order).

  'Variables for Gesture Recognition Processing
  long sampleWindowCounts       'Stores the number of samples which was calculated from the GEST_WINDOW_TIME
                                'value using the current sampling rate.
  long oldVal[3]                'Stores the group of previous samples in order to recognize rising or falling edges
  long risingEdge[3]            'Stores the sample count of when a rising edge was seen to occur
  long fallingEdge[3]           'Stores the sample count of when a falling edge was seen to occur
   
  'Gesture Ring Buffer
  byte bufGesture[GEST_QUEUE_SIZE]    'Circular buffer to store gesture codes
  word bufDuration[GEST_QUEUE_SIZE]   'Circular buffer to store gesture duration
  long bufStartCount[GEST_QUEUE_SIZE] 'Circular buffer to store the gesture start count                  
  long buf_head       'This points to the next available place in memory (where data is put in)
  long buf_tail       'This points to the oldest entry in the buffer (where data is taken out)
  long buf_fillCount  'This is used to keep track of how many elements are currently filled in the ring buffer.

  
PUB Start(sda_pin, scl_pin, int_pin) : success
{{
Starts a new cog to run the driver.  On startup the driver will perform initializations
and setup the attached Si1143 device.

Parameters:
  sda_pin - Pin number attached to the SDA pin.
  scl_pin - Pin number attached to the SCL pin.
  int_pin - Pin number attached to the INT pin.
Return Value:
  success - Returns 0 if the driver could not be started. Otherwise returns the number
            of the started cog + 1 if successful.
Example Use:
  sensor.Start(0, 1, 2)
Expected Result:
  This will launch the driver (this object) into the next available cog using pins P0, P1,
  and P2 as the pins for SDA, SCL, and INT respectively. 
}}

  Stop                          'Stop if it's been previously started
  if((mutexLock := locknew) == -1)
    return 0                    'Return without starting because no locks were available.
  success := (cog := cognew(Run(sda_pin, scl_pin, int_pin), @stack) + 1)
  ifnot success                  'If the cog was not successfully launched...
    lockret(mutexLock)          '...then return the lock since it's no longer being used.
    

PUB Stop
{{
Stops the cog previously started by the Start method.

Parameters:
  (none)
Return Value:
  (none)
Example Use:
  sensor.Stop
Expected Result:
  This will stop the cog running the driver (if it was previously started). 
}}

  if Cog
    cogstop(Cog~ - 1)
    lockret(mutexLock)
    

PUB SampleOnce(valueArrayPtr) : sampleCount
{{
Initiates a single set of samples, and stores the resulting values into
the array passed into the function.  The values are organized as follows:
  value[0] <- Ambient Visible
  value[1] <- Ambient IR
  value[2] <- IR LED 1
  value[3] <- IR LED 2
  value[4] <- IR LED 3
  
If this is called while already in continous mode, then it will initiate
a stop sequence first before executing the single measurement.  Consequently,
the driver will NOT resume continous operation following this function call. 

This is a blocking call, so will return AFTER the new set of measurements
is acquired.

Parameters:
  valueArrayPtr - Pointer to an array of 5 longs.
Return Value:
  sampleCount - The current sample count number. This value is incremented
                by 1 with each new sample taken.
Example Use:
  sensor.SampleOnce(@value)
Expected Result:
  Assuming "value" is an array of 5 longs, this retrieves a new group of measurements
  and stores them into the array as described above.  
}}

  'Wait until the mailbox is empty...
  repeat until (msgMailbox == MSG_EMPTY)

  'Pass the message to initiate a single measurement
  msgMailbox := MSG_MEAS_ONCE   

  'The driver will receive the message, execute the command, and clear the mailbox
  'when the new measurements are available.  Note that our GetValues function
  'does not set the waitForNew parameter because the driver function only clears
  'the message AFTER the values have been stored.   
  repeat until (msgMailbox == MSG_EMPTY)
  return GetValues(valueArrayPtr)   'Copy the local array values into the user-passed array
  
    
PUB SampleContinuous(sampleInterval_ms)
{{
Starts or re-starts sampling in continuous automatic mode.  The sample interval
sets the rate at which samples will be taken.

If the driver was already in continuous mode, then it will stop and re-initiate
continous mode with the new sample interval value.

It is important to note that this function blocks until the initialization sequence
is complete, but does NOT wait for new measurements to complete. Users should take
note of the measurement count value to see if values acquired are new.

Parameters:
  sampleInterval_ms - Time interval (in milliseconds) between each consecutive measurement.
                      The upper limit is set by the device as 1984ms. The lower limit
                      is set according to the capabilities of the driver.  See MIN_SAMPLE_INTERVAL_MS
                      parameter for more information.
Return Value:
  (none) 
Example Use:
  sensor.SampleContinuous(50)
Expected Result:
  Start sampling in continous mode with a sample interval of 50ms (20 samples per second).  
}}

  if(sampleInterval_ms < MIN_SAMPLE_INTERVAL_MS)    'minimum sample interval allowed for this driver.
    sampleInterval_ms := MIN_SAMPLE_INTERVAL_MS

  if(sampleInterval_ms > 1984)  'maximum sample interval for the Si1143 device is 1.984s (according to documentation).
    sampleInterval_ms := 1984
  
  'Wait until the mailbox is empty...
  repeat until (msgMailbox == MSG_EMPTY)

  'Copy in the new rate value
  sampleRate := (sampleInterval_ms * 32)   'Each count is 31.25us
  
  'Pass the message to initiate auto mode
  msgMailbox := MSG_MEAS_AUTO   

  'The driver will receive the message, execute the command, then clear the mailbox
  'when finished initiating the setup.  Note: this function does not wait until any 
  'measurements have been completed before returning. Therefore, users should
  'typically check the measurement count if using the GetValues function directly
  'after starting continous mode. 
  repeat until (msgMailbox == MSG_EMPTY)

                                                 
PUB SampleStop
{{If the device was previously in continous mode, this function stops any further
measurements. If the driver was previously idle, this function has no effect.

Parameters:
  (none)
Return Value:
  (none)
Example Use:
  sensor.SampleStop
Expected Result:
  Halt any continous sampling.  Return driver to idle state.  
}}

  'Wait until the mailbox is empty...
  repeat until (msgMailbox == MSG_EMPTY)
  
  msgMailbox := MSG_MEAS_STOP   'Tell the driver to halt automatic mode

  'The driver will receive the message, execute the command, then clear the message
  'when finished.   
  repeat until (msgMailbox == MSG_EMPTY)
  

PUB PsBaselineSet | index, newSample[5], avgPsValues[3]
{{If using the gesture recognition features of the driver, this function should
be called before calling SampleContinuous to allow the driver to compensate for
IR light leakage for the current configuration.

This function takes a series of measurements to calculate an average "baseline"
level for each channel.  These values are then automatically subtracted from
any future measurements to elimitate the crosstalk component of each measurement.
To remove the baseline offset and get the raw measurement values, the
PsBaselineClear function may be called.

Note that the baseline offset value only compensates for crosstalk and optical
leakage for the system.  Ambient IR is already internally compensated inside
the Si1143 device.

Parameters:
  (none)
Return Value:
  (none)
Example Use:
  sensor.PsBaselineSet
Expected Result:
  Take a series of sample measurements and store the average value as the baseline
  offset.   
}}

  'Clear out any previous baselines so we get the raw values below.
  longfill(@baselinePS, 0, 3)

  'Clear the variables where we will accumulate the averages
  longfill(@avgPsValues, 0, 3)
  
  'Read the values and accumulate in the array 
  repeat index from 1 to BL_SAMPLES_PER_AVE
    SampleOnce(@newSample)
    avgPsValues[0] += newSample[2]
    avgPsValues[1] += newSample[3]
    avgPsValues[2] += newSample[4]
    'waitcnt(clkfreq/10 + cnt)   'brief pause to make sure the sampling is not too fast.

  'Now store the average value in the baseline variable for each channel
  repeat index from 0 to 2
    baselinePS[index] := avgPsValues[index] / BL_SAMPLES_PER_AVE 
                                      

PUB PsBaselineClear
{{This function is used to remove the baseline offset values (if set
previously) so that raw unmodified values will be stored. Note: on
startup, the baseline offsets are already cleared to zero.

Parameters:
  (none)
Return Value:
  (none)
Example Use:
  sensor.PsBaselineClear
Expected Result:
  Zero out the baseline offset values.   
}}

  longfill(@baselinePS, 0, 3)
  
     
PUB GetValues(valueArrayPtr) : sampleCount
{{Typically used when the device is in continuous sampling mode. This function copies
the most recent group of measurements into the value array and guarantees that all
copied values belong to the same measurement group.

The returned sampleCount value is an integer value which increments each time a new
sample is acquired. This allows the application to easily distinguish between separate
unique measurements rather than the same measurement read out multiple times.

This function will retrieve the most recently acquired values regardless of whether
they were taken in continuous mode or a single measurement mode.

The values are stored in the array as follows:
  value[0] <- Ambient Visible
  value[1] <- Ambient IR
  value[2] <- IR LED 1
  value[3] <- IR LED 2
  value[4] <- IR LED 3

Parameters:
  valueArrayPtr - Pointer to an array of 5 longs.
Return Value:
  sampleCount - The current sample count number. This value is incremented
                by 1 with each new sample taken.
Example Use:
  sensor.GetValues(@value)
Expected Result:
  Assuming "value" is an array of 5 longs, this retrieves a new group of measurements
  and stores them into the array as described above.  
}}

  MutexGet    'Get mutex to ensure read is atomic
  longmove(valueArrayPtr, @sampleVal, 5)      'Copy the most recent set of values
  sampleCount := sampleCnt                    'Copy the count relating to this sample group
  MutexRelease


PUB GetGesture(pByte_Gesture, pWord_Duration, pLong_StartCount, waitTime_ms) : success | expTime
{{This function returns the next gesture in the queue.  If there are
currently no gestures in the queue, the waitTime_ms parameter specifies
how long to wait for a gesture to occur (the function will block
until a gesture is returned, or the time expires).  A waitTime value
of 0 will check for a gesture and return immediately.  A waitTime
value of -1 (or anything negative) will wait indefinitely.

Once a gesture is read from the buffer, it is cleared from the queue.
Subsequent function calls will return any additional gestures until the
queue has been emptied.  If the buffer is empty, after timeout expires
this function will write zeros into each value, and then return 0 (failure).

Refer to the "Gesture Event Table" in the CON section for a list of the
possible gesture events.  In general gestures are recognized as an
entrance to, or exit from the central field of view; along with the
specific direction of the event.

Most gestures (such as swipes) are composed of an entrance event followed
by an exit event.  For example a right swipe gesture would be composed of a
left entrance followed by a right exit (2 discrete events). Since the
driver provides events as the "building blocks", it allows the user application
flexibility and power to resolve common gestures as well as more complex
multi-event gestures.  

The size of the message buffer is determined at compile time from the
GEST_QUEUE_SIZE setting.  Once the message/gesture buffer is filled, any new
gestures will be ignored and lost.  Therefore, to ensure all gestures are
recorded, the user application should call this function often enough so
that the message buffer doesn't overfill.

Parameters:
  pByte_Gesture - This is a pointer to a byte value which stores the
                  event type.  Refer to the "Gesture Event Table"
                  in the CON section for a list of possible values
                  and how they are encoded.
  pWord_Duration - This is a pointer to a word value which stores the
                   duration of the event (in numbers of samples). This
                   can be useful as a means to determine relatively how
                   fast the event happened. Note however, that this is
                   usually not relavent for the "center" type events
                   since their edges occur approximately simultaneously.
  pLong_StartCount - This is a pointer to a long value which stores the
                     sample number of the earliest edge.  This is useful
                     to determine when the event started (or can be added
                     to the Duration value to find when the event ended).
  waitTime_ms - This specifies how long to wait (in milliseconds) for a
                gesture to become available in the queue. The function
                will block for this length of time or until a gesture
                becomes available.  A value of -1 (or anything negative)
                will wait forever.  
Return Value:
  success - The return value is 1 if a gesture was available. The return 
            value is 0 if there was no gesture available within the
            expiration time. 
Example Use:
  sensor.GetGesture(@gesture, @duration, @startCount, -1)  
Expected Result:
  Assuming "gesture" is a byte value, "duration" is a word value, and "startCount" is
  a long value, if a gesture is available in the queue it will be copied into these
  values and removed from the queue.  Otherwise the function will wait forever (-1)
  until a gesture is detected.
}}
  
  expTime := cnt + ((clkfreq/1000)*waitTime_ms)
      
  repeat 
    'Get the gesture if there is one, otherwise check again. 
    if(RetrieveGestureFromBuf(pByte_Gesture, pWord_Duration, pLong_StartCount)) 
      return 1
    if(waitTime_ms < 0)  'If waitTime is negative, then loop indefinitely (skip the expire time check)
      next                 
    if(cnt > expTime)
      quit
  
  return 0        'Time expired and we never got a gesture, so return false.
  

PRI Run(sda_pin, scl_pin, int_pin)

  'Make sure everything is cleared initially...
  'Variables for Operating the State Machine 
  runState := 0
  msgMailbox := 0
  sampleRate := 0
  'Variables for Storing Samples
  longfill(@sampleVal, 0, 5)                     
  sampleCnt := 0
  'longfill(@baselinePS, 0, 3)
  'Variables for Gesture Recognition Processing
  sampleWindowCounts := 0
  longfill(@oldVal, 0, 3)
  longfill(@risingEdge, 0, 3)
  longfill(@fallingEdge, 0, 3)
  'Gesture Ring Buffer
  'bytefill(@bufGesture, 0, GEST_QUEUE_SIZE)
  'wordfill(@bufDuration, 0, GEST_QUEUE_SIZE)
  'longfill(@bufStartCount, 0, GEST_QUEUE_SIZE)                  
  'buf_head := 0
  'buf_tail := 0
  'buf_fillCount := 0


  'Reset baseline values to 0
  PsBaselineClear
  'Initialize the Gesture Buffer to be empty
  InitGestureBuf
  
  'Store the pin numbers specified (for use later)  
  sdaPin := sda_pin             
  sclPin := scl_pin
  intPin := int_pin

  'Init the I2C driver
  i2c.Init(sdaPin, sclPin)      'Initialize the I2C functions
  dira[intPin]~                 'Set inturrupt pin to be an input
  
  'Initialize the Si1143 device
  DeviceInit  
  
  'Done with all initializations, so now we can set the mailbox as empty (ready)
  msgMailbox := MSG_EMPTY
  
  'Set our driver state machine to initially be in idle mode.  
  runState := STATE_IDLE

  'MAIN PROGRAM LOOP: Process the message mailbox and service the state machine
  repeat
    'Handle any new message in the mailbox
    case msgMailbox      
      MSG_EMPTY:
        'If the message is EMPTY, do nothing and skip down to the state machine processing
        
      MSG_MEAS_ONCE:
        'If we're in a mode other than IDLE (presumably CONTINUOUS mode) then issue
        'a stop command sequence first and don't clear the mailbox message yet. Once
        'we come back through the loop in IDLE mode, then we can process the single
        'measurement.
        if(runState <> STATE_IDLE)     
          runState := STATE_INIT_STOP    'Halt any current sequence of measurements             
        else
          runState := STATE_INIT_SINGLE  'Initiate a single measurement
  
      MSG_MEAS_AUTO:
        'If we're in a mode other than IDLE (presumably CONTINUOUS mode) then issue
        'a stop command sequence first and don't clear the mailbox message yet. Once
        'we come back through the loop in IDLE mode, then we can restart auto measurement
        'mode.
        if(runState <> STATE_IDLE)     
          runState := STATE_INIT_STOP    'Halt any current sequence of measurements             
        else
          runState := STATE_INIT_CONTINUOUS  'Initiate automatic measurements
  
      MSG_MEAS_STOP:
        'If we're in a mode other than IDLE (presumably CONTINUOUS mode) then issue
        'a stop command sequence. Otherwise, if we're already idle then don't need to do
        'anything.
        runState := STATE_INIT_STOP    'Halt any current sequence of measurements
   
    'Handle the state machine operations        
    case runState
      STATE_IDLE:
        'Idle waiting for new command. Do nothing, continue looping and waiting...
          
      STATE_INIT_STOP:
        if(runState <> STATE_IDLE)
          'Perform the stop sequence for any ongoing measurements
          SendCommand(CMD_PSALS_PAUSE)

        'Return the state to IDLE
        runState := STATE_IDLE
                             
      STATE_INIT_SINGLE:
        'Initiate the device to take a single set of measurements
        SendCommand(CMD_PSALS_FORCE)
         
        'Read in the new set of samples and store them into the local array
        ReadSamples
                           
        'Return state to IDLE and empty mailbox to indicate the command is finished
        runState := STATE_IDLE
        msgMailbox := MSG_EMPTY

      STATE_INIT_CONTINUOUS:
        'Setup the Si1143 device to begin taking continuous measurements
        'Set ALS wakeup counter to 1
        WriteToRegister(REG_ALS_RATE, $08) 'NOTE: $08 is the compressed equivalent of a x1 multiplier.
        'Set PS wakeup counter to 1
        WriteToRegister(REG_PS_RATE, $08) 'NOTE: $08 is the compressed equivalent of a x1 multiplier.
        'Set measurement wakeup interval time (from user value) - NOTE: Value MUST already be limit-checked from 1 to 100
        WriteToRegister(REG_MEAS_RATE, Compress(sampleRate))        
        
        'Enable interrupts for all channels we care about. In this case: ALS_IR, ALS_VIS, PS1, PS2, PS3.
        WriteToRegister(REG_IRQ_ENABLE, %0001_1101)   
        WriteToRegister(REG_IRQ_MODE1, $00)  'Set the interrupt mode for ALS, PS1, PS2 
        WriteToRegister(REG_IRQ_MODE2, $00)  'Set the interrupt mode for PS3 

        'Clear any existing interrupt flags
        ClearIntFlags
        
        'Enable interrupt pin
        WriteToRegister(REG_IRQ_CFG, $01)   'Enable interrupt pin.
        
        'Start PSALS_AUTO mode (send command)
        SendCommand(CMD_PSALS_AUTO)
        
        'Initialize values required by gesture recognition
        longfill(@oldVal, 0, 3)  'Zero out any previous old sample values
        longfill(@risingEdge, 0, 3)  'Zero out the edges
        longfill(@fallingEdge, 0, 3)  'Zero out the edges
        sampleWindowCounts := (GEST_WINDOW_TIME_MS * 32) / sampleRate  'Calculate how many samples equate to our window time.
                                                                       'Count(samp) = WindowTime(ms) / TimePerSample(ms/samp)
                                                                       'TimePerSample(ms/samp) = sampleRate(ticks/samp) / 32(ticks/ms)
        if(sampleWindowCounts < 0)   'Don't think we need this check, but a negative value
          sampleWindowCounts := 0    'would really screw things up later with gesture processing,
                                     'so suppose it's not a bad idea just to double check.
                
        'Set state to CONTINUOUS mode.
        runState := STATE_CONTINUOUS
        msgMailbox := MSG_EMPTY
                    
      STATE_CONTINUOUS:
        'Check interrupt pin to see if ALL new measurements are ready (read all out at once).
        if(ina[intPin] == 0) 'Check if INT pin is asserted (pulled low)
          if((GetIntFlags & IRQ_ALL_CHANNELS) == IRQ_ALL_CHANNELS)
            ReadSamples
            ClearIntFlags
            'Run gesture checking iteration on new values
            IterateGestureTracker
            
          'Else none, or not all of the new measurements are ready, so loop back and check again
                 
{
DRIVER NOTES:
Within the Si1143 device, the MEAS_RATE parameter represents the time interval when the
device wakes up to take a set of measurements. When zero, places device in forced
measurement mode, and in lowest power consumption state. When non-zero, device operates
in autonomous mode for continous measurements.  The uncompressed 16-bit value represents
the number of 32kHz clock ticks between wakeup cycles.  Values for MEAS_RATE, PS_RATE,
and ALS_RATE represent 16-bit values but must be compressed into 8-bits using the
documented algorithm.

When the Si1143 device wakes up from the MEAS_RATE interval, it takes a set of
measurements if the PS counter and/or the ALS counter have expired.  Setting the
PS_RATE or ALS_RATE to zero means the set of measurements will never occur, a value
 of 1 means measurements will be taken every time the device wakes up, and 2 every
other time the device wakes up, and so on.

Which measurements are taken during each set are determined by the bits set in the CHLIST
register. Measurements are always taken in this order:  (PS1, PS2, PS3, ALS_VIS, ALS_IR,
AUX) However, note that this is not the same order as how they're stored in memory.

Additionally, if desired, the LED's corresponding to each PSx channel can be changed
around.  By default PS1, PS2, PS3 activate LED1, LED2, LED3 pins; and in most typical
applications we would have no reason to change from the default.
}        


PRI IterateGestureTracker | index, deltaCountsA, deltaCountsB, gesture, duration, startCount
{This function should be called after every new sample (when in AUTO mode).  It processes
the new sample and executes another iteration in the gesture-tracking module.

Basically the gesture tracking scheme works to detect edge events within a limited window
of time, then observe the order of edge events between channels to determine the direction
of the event. Gesture events are captured as entry and exit events.  For example: a right swipe
is effectively made up of an enter_left followed directly by an exit_right.  Detecting
gestures by their component entry and exit conditions allows the user tremendous
flexibility to process more complex custom events if required by the application; for
example a sequence such as enter_center:exit_right, or enter_left:exit_down are possible. 

Gesture tracking flows up through the following process & levels of abstraction:
Threshold Detection:
Every new sample is checked against the previous sample to see if it constitutes
a rising or falling edge.  If the old value was below the GEST_ACTIVATION_THRESHOLD
and the new state is above the threshold, then a rising edge has occurred and is
recorded in the edge event table.  If the opposite occurs, the event is recorded
as a falling edge in the edge event table.  If the threshold was not crossed, then
nothing notable has occurred.  The edge event table is an array of 6 edge events:
a rising and falling edge for each of the three channels.  The array stores the
sample number when the event occurred.  If the array value is 0, then there is no
event stored.  Events may only be stored into the table when the present value
is 0.  This simplifies the gesture recognition algorithm since we are only looking
at the first rising edge of each event, and we know any wavering on the edge of
the threshold won't later overwrite the first edge (resulting in an incorrectly
recognized gesture).

Threshold Event Expiration:
Events stored in the edge event table will expire after GEST_WINDOW_TIME_MS has elapsed.
The window time in ms corresponds to a number of samples (calculated from the
sample rate).  If any of the samples are older than the sample window, they are
cleared from the table (set to zero).  This is important so that any partially seen
or unsuccessful gestures will get cleared away over a short period of time.  Note
that this expiration effects how fast the "enter_" and "exit_" conditions must occur,
however because full gestures are really composed of entry and exit conditions, this
does not effect how fast the entire gesture needs to be.  A user could swipe to the
center of the sensor (for example enter_left), pause for several seconds, then
continue the swipe out the side (exit_right) to form a full right swipe gesture.
Again, this also allows flexibility in the user application for things like menu
navigation, or swipe-and-hold types of gestures.

Edge Analysis:
When the edge event table contains a rising edge for each channel, or a falling
edge for each channel, then that group of edges is examined to determine the
specific type of entry or exit that occurred.  The lower left LED (PS1) is common
to all gestures, so it will be our reference sample number. We want to see from PS1
whether the LED to the right (PS3) was triggered at the same time, before, or after
PS1.  Then we want to see if the LED above it (PS2) was triggered at the same
time, before, or after PS1.  Their relationships are determined by subtracting
their sample number, and the result is used to determine all possible gesture
events according to the following conditions:
 ┌─────────────┬───────────────────────┬───────────────────────┬───────────────────────┐
 │[Edge Event] │ [PS1 compared to PS2] │ [PS1 compared to PS3] │ [Gesture]             │
 │(rise/fall)  │  (>)     (<)     (=)  │  (>)     (<)     (=)  │                       │
 ├─────────────┼───────────────────────┼───────────────────────┼───────────────────────┤                                                            
 │  rising     │                   x   │                   x   │  enter_center         │
 │  rising     │                   x   │           x           │  enter_left           │
 │  rising     │                   x   │   x                   │  enter_right          │
 │  rising     │           x           │                   x   │  enter_bottom         │                               
 │  rising     │           x           │           x           │  enter_bottom_left    │                               
 │  rising     │           x           │   x                   │  enter_bottom_right   │                               
 │  rising     │   x                   │                   x   │  enter_top            │
 │  rising     │   x                   │           x           │  enter_top_left       │
 │  rising     │   x                   │   x                   │  enter_top_right      │
 ├─────────────┼───────────────────────┼───────────────────────┼───────────────────────┤
 │  falling    │                   x   │                   x   │  exit_center          │
 │  falling    │                   x   │           x           │  exit_right           │
 │  falling    │                   x   │   x                   │  exit_left            │
 │  falling    │           x           │                   x   │  exit_top             │             
 │  falling    │           x           │           x           │  exit_top_right       │             
 │  falling    │           x           │   x                   │  exit_top_left        │             
 │  falling    │   x                   │                   x   │  exit_bottom          │
 │  falling    │   x                   │           x           │  exit_bottom_right    │
 │  falling    │   x                   │   x                   │  exit_bottom_left     │
 └─────────────┴───────────────────────┴───────────────────────┴───────────────────────┘


When two edges occur at essentially the same time, they may still be one or
a few samples off from each other (more common at higher sample rates).  This
occurs because a hand or object may not be a perfect horizontal or vertical
edge, or the direction of motion may not be exactly on axis with the sensor.
Therefore, if edges are compared and found to be close enough within the
"simultaneous tolerance", then they are interpreted as being simultaneous
events.  The GEST_SIMULTANEOUS_TOLERANCE setting controls how many samples
each comparison may deviate before being considered sequential (instead
of simultaneous). A value of 0 indicates that event times are strictly
compared without any tolerance; while for example, a value
of 3 means the edges must be =< 3 samples apart.

After analysis of the three channel edge times for a rising event or
falling event, the edges for that type (only rising, or only falling) are
cleared to zero so they are ready for a new set of edges to be detected. 

Gesture Recognition and Messaging:
When edge analysis finds a valid gesture, it is stored in a circular buffer
to be accessed by the user application using the GetGesture function. Each
gesture is composed of: the gesture code (which indicates what type of gesture
it was), duration (the number of counts over which the gesture took
place - basically the last edge minus the first edge), and startCount (the
count value of the first edge).  These are stored internally using 3 separate
ring buffers, but repackaged into two longs when passed back to the user app.  
}

  'Detect edges:
  'If there is a rising edge AND the edge has not been
  'captured, then store the count value for the edge.
  repeat index from 0 to 2      'Do this for each channel
    if((oldVal[index] < GEST_ACTIVATION_THRESHOLD) and (sampleVal[index+2] > GEST_ACTIVATION_THRESHOLD)) 'Rising Edge Detection
      if(risingEdge[index] == 0)  'Only store if previously empty 
        risingEdge[index] := sampleCnt                 
    elseif((oldVal[index] > GEST_ACTIVATION_THRESHOLD) and (sampleVal[index+2] < GEST_ACTIVATION_THRESHOLD)) 'Falling Edge Detection
      if(fallingEdge[index] == 0)  'Only store if previously empty 
        fallingEdge[index] := sampleCnt

  'Check if rising edge group is ready to be processed:
  if((risingEdge[0]<>0) and (risingEdge[1]<>0) and (risingEdge[2]<>0))
    'Figure out the startCount (the earliest edge).  Basically scan through and find the lowest value.
    startCount := risingEdge[0]
    if(risingEdge[1] < startCount)
      startCount := risingEdge[1]
    if(risingEdge[2] < startCount)
      startCount := risingEdge[2]
    'Figure out the duration (the latest edge minus the startCount).  Basically scan through and find the highest value then subtract.
    duration := risingEdge[0]
    if(risingEdge[1] > duration)
      duration := risingEdge[1]
    if(risingEdge[2] > duration)
      duration := risingEdge[2]
    duration -= startCount

    'Process rising edge group (this code implements the conditional event/gesture table)
    deltaCountsA := risingEdge[1] - risingEdge[0]   'Compare edges between PS2 and PS1
    deltaCountsB := risingEdge[0] - risingEdge[2]   'Compare edges between PS1 and PS3
    if(deltaCountsA > GEST_SIMULTANEOUS_TOLERANCE)          
      if(deltaCountsB > GEST_SIMULTANEOUS_TOLERANCE)             
        'Gesture = (enter_bottom_right)
        gesture := EVENT_ENTER_BOTTOM_RIGHT
      elseif(deltaCountsB < (0-GEST_SIMULTANEOUS_TOLERANCE))       
        'Gesture = (enter_bottom_left)
        gesture := EVENT_ENTER_BOTTOM_LEFT
      else                                                                      
        'Gesture = enter_bottom                        
        gesture := EVENT_ENTER_BOTTOM
    elseif(deltaCountsA < (0-GEST_SIMULTANEOUS_TOLERANCE))  
      if(deltaCountsB > GEST_SIMULTANEOUS_TOLERANCE)           
        'Gesture = (enter_top_right)
        gesture := EVENT_ENTER_TOP_RIGHT
      elseif(deltaCountsB < (0-GEST_SIMULTANEOUS_TOLERANCE))   
        'Gesture = (enter_top_left)
        gesture := EVENT_ENTER_TOP_LEFT
      else                                                                    
        'Gesture = enter_top
        gesture := EVENT_ENTER_TOP
    else                                                     
      if(deltaCountsB > GEST_SIMULTANEOUS_TOLERANCE)         
        'Gesture = enter_right
        gesture := EVENT_ENTER_RIGHT
      elseif(deltaCountsB < (0-GEST_SIMULTANEOUS_TOLERANCE))      
        'Gesture = enter_left
        gesture := EVENT_ENTER_LEFT
      else                                                                      
        'Gesture = enter_center
        gesture := EVENT_ENTER_CENTER
    StoreGestureInBuf(gesture, duration, startCount)
    longfill(@risingEdge, 0, 3)  'Zero out the edges since we're done processing this group
 
  'Check if falling edge group is ready to be processed:
  if((fallingEdge[0]<>0) and (fallingEdge[1]<>0) and (fallingEdge[2]<>0))
    'Figure out the startCount (the earliest edge).  Basically scan through and find the lowest value.
    startCount := fallingEdge[0]
    if(fallingEdge[1] < startCount)
      startCount := fallingEdge[1]
    if(fallingEdge[2] < startCount)
      startCount := fallingEdge[2]
    'Figure out the duration (the latest edge minus the startCount).  Basically scan through and find the highest value then subtract.
    duration := fallingEdge[0]
    if(fallingEdge[1] > duration)
      duration := fallingEdge[1]
    if(fallingEdge[2] > duration)
      duration := fallingEdge[2]
    duration -= startCount

    'Process falling edge group (this code implements the conditional event/gesture table)
    deltaCountsA := fallingEdge[1] - fallingEdge[0]   'Compare edges between PS2 and PS1
    deltaCountsB := fallingEdge[0] - fallingEdge[2]   'Compare edges between PS1 and PS3
    if(deltaCountsA > GEST_SIMULTANEOUS_TOLERANCE)         
      if(deltaCountsB > GEST_SIMULTANEOUS_TOLERANCE)        
        'Gesture = (exit_top_left)
        gesture :=  EVENT_EXIT_TOP_LEFT
      elseif(deltaCountsB < GEST_SIMULTANEOUS_TOLERANCE)    
        'Gesture = (exit_top_right)
        gesture := EVENT_EXIT_TOP_RIGHT
      else                                                             
        'Gesture = exit_top
        gesture := EVENT_EXIT_TOP
    elseif(deltaCountsA < (0-GEST_SIMULTANEOUS_TOLERANCE))  
      if(deltaCountsB > GEST_SIMULTANEOUS_TOLERANCE)        
        'Gesture = (exit_bottom_left)
        gesture := EVENT_EXIT_BOTTOM_LEFT
      elseif(deltaCountsB < GEST_SIMULTANEOUS_TOLERANCE)    
        'Gesture = (exit_bottom_right)
        gesture := EVENT_EXIT_BOTTOM_RIGHT
      else                                                             
        'Gesture = exit_bottom
        gesture := EVENT_EXIT_BOTTOM
    else                                                    
      if(deltaCountsB > GEST_SIMULTANEOUS_TOLERANCE)        
        'Gesture = exit_left
        gesture := EVENT_EXIT_LEFT
      elseif(deltaCountsB < GEST_SIMULTANEOUS_TOLERANCE)    
        'Gesture = exit_right
        gesture := EVENT_EXIT_RIGHT
      else                                                             
        'Gesture = exit_center
        gesture := EVENT_EXIT_CENTER
    StoreGestureInBuf(gesture, duration, startCount)
    longfill(@fallingEdge, 0, 3)  'Zero out the edges since we're done processing this group
          
  'Remove expired edge events:
  repeat index from 0 to 2
    if((risingEdge[index]+sampleWindowCounts) < sampleCnt)
      risingEdge[index] := 0
    if((fallingEdge[index]+sampleWindowCounts) < sampleCnt)
      fallingEdge[index] := 0
 
  'Store current values into the old values
  repeat index from 0 to 2
    oldVal[index] := sampleVal[index+2]

PRI InitGestureBuf
{This function initializes the ring buffer used for gesture tracking.  This
MUST be called before using the ring buffers. }
  bytefill(@bufGesture, 0, GEST_QUEUE_SIZE)
  wordfill(@bufDuration, 0, GEST_QUEUE_SIZE)
  longfill(@bufStartCount, 0, GEST_QUEUE_SIZE)
  buf_head := buf_tail := buf_fillCount := 0 
  

PRI StoreGestureInBuf(gesture, duration, startCount) : success
{This function stores a gesture into the ring buffers (when space is available).
The head is where where we would put new data next time (but haven't put it there yet).
The tail is where data exists, and where we take it out when we want it.
}

  MutexGet

  if(buf_fillCount => GEST_QUEUE_SIZE)   'check if we're all full
    success := 0           'all full, so return failure
  else     'Not full, so store the new values
    'Store new values using head as the index
    bufGesture[buf_head] := gesture
    bufDuration[buf_head] := duration
    bufStartCount[buf_head] := startCount
    'Increment the fill count
    buf_fillCount += 1
    'Move the head to the new position
    buf_head += 1
    if(buf_head == GEST_QUEUE_SIZE)         'Now check if we're at the top
      buf_head := 0                         'to see if we need to roll back around to the bottom
    success := 1
   
  MutexRelease


PRI RetrieveGestureFromBuf(pByte_Gesture, pWord_Duration, pLong_StartCount) : success
{This function copies the gesture out of the ring buffer into the pointed variables.
The head is where where we would put new data next time (but haven't put it there yet).
The tail is where data exists (unless buffer is empty), and where we take it out when we want it.

If there is no data available to be retrieved, then the values are all set to 0 and
function returns false.
}

  MutexGet

  if(buf_fillCount =< 0)     'check if buffer is empty
    success := 0              'No data to read in buffer, return failure
  else  'Otherwise there's data to be read
    'Get values using tail as the index
    byte[pByte_Gesture] := bufGesture[buf_tail]
    word[pWord_Duration] := bufDuration[buf_tail]
    long[pLong_StartCount] := bufStartCount[buf_tail]
    'Decrement the fill count
    buf_fillCount -= 1
    'Move tail to the next position
    buf_tail += 1
    if(buf_tail == GEST_QUEUE_SIZE)  'Move the tail up by one, then check
      buf_tail := 0           'if we need to roll over to bottom (in case head & tail were both at the very top).
    success := 1
        
  MutexRelease
 

PRI DeviceInit | temp
{Perform required initializations on the Si1143 device.}

  repeat
    'Send device reset
    SendCommand(CMD_RESET)
    waitcnt(cnt + (clkfreq/100)*3)    'Need to wait at least 25ms for device to come out of reset (try 30ms for safe margin) 
     
    temp := 0    
    'Wait for registers to reset, give up after checking 100 times
    repeat until (ParamQuery(PARAM_CH_LIST) == 0)
      temp += 1
      if(temp > 100)
        quit

    if(temp =< 100)   'Was successful, so no need to repeat (continue on)
      quit
  
  'Send Hardware Key
  WriteToRegister(REG_HW_KEY, HW_KEY_VAL0)

  'Set LED current (set to default initially)
  WriteToRegister(REG_PS_LED21,(DEFAULT_LED_CURRENT<<4) + DEFAULT_LED_CURRENT)
  WriteToRegister(REG_PS_LED3, DEFAULT_LED_CURRENT)
  
  repeat
    temp := 0
    'Set CHLIST parameter to specify which measurements should be made (we want all the values except AUX)
    ParamSet(PARAM_CH_LIST, ALS_IR_TASK + ALS_VIS_TASK + PS1_TASK + PS2_TASK + PS3_TASK)
    repeat while (ParamQuery(PARAM_CH_LIST) <> (ALS_IR_TASK + ALS_VIS_TASK + PS1_TASK + PS2_TASK + PS3_TASK))
      temp += 1
      if(temp > 100)
        quit

    if(temp =< 100)
      quit
      
  'Clear Si114x Interrupt Configuration  
  WriteToRegister(REG_IRQ_CFG, $00)            'Tri-state INT pin   
  WriteToRegister(REG_IRQ_ENABLE, $00)         'Disable all IRQ
  WriteToRegister(REG_IRQ_MODE1, $00)
  WriteToRegister(REG_IRQ_MODE2, $00)

  'Clear counters (Shouldn't need to actually do anything with these registers)
  'ParamSet(PARAM_PS_ADC_COUNTER, $00)
  'ParamSet(PARAM_ALSVIS_ADC_COUNTER, $00)
  'ParamSet(PARAM_ALSIR_ADC_COUNTER, $00)
  


PRI SendCommand(value)
{This function MUST be used for all commands placed in the COMMAND register to ensure proper execution.}

  if(ReadFromRegister(REG_RESPONSE) <> 0)
    'Spam NOP commands until the response register reads 0 (is cleared)
    repeat until (ReadFromRegister(REG_RESPONSE) == 0)
      WriteToRegister(REG_COMMAND, CMD_NOP)
    
  repeat
    'Now send the command and make sure the response register becomes non-zero (command was processed)
    'otherwise re-send the command and check again until it shows that it was processed.
    WriteToRegister(REG_COMMAND, value)
    if(value == CMD_RESET)      'don't need to do response checking for a reset command since it resets the value
      quit
    if(ReadFromRegister(REG_RESPONSE) <> 0)
      quit


PRI CheckIntPin(timeout) : triggered | expTime
{This function checks the state of the interrupt pin.  It returns when the pin is activated (low) or after
the timeout expires, whichever occurs first.  To return immediately, set timeout value to 0. The timeout
value is in clock cycles. This function returns 'true' if the pin is activated (low), or 'false' if
the pin is not activated. }

  expTime := cnt + timeout
  
  repeat while (cnt < expTime)   'Keep checking the pin as long as we haven't expired yet.
    if(ina[intPin] == 0)         'See if pin is activated (pulled low), if so then return 'true'
      return true                   
  
  return not ina[intPin]        'Time expired, so return the state of the pin (inverted because active low)
  
  
PRI ReadSamples | value[3]
{This function reads all samples from the device and stores them in the value array.  It waits for
the mutex before copying over the new values into the second buffer.

Note: this function declares an array of 3 longs ("value[3]"), but uses the declared space instead
as an array of bytes.  There are 12 bytes in 3 longs, but we are only using the lowest 10 of those
bytes.}

  ReadBurst(REG_ALS_VIS_DATA0, @value, 10)
  MutexGet
  sampleVal[0] := value.byte[0]+(256*value.byte[1]) 'Ambient Visible 
  sampleVal[1] := value.byte[2]+(256*value.byte[3]) 'Ambient IR 
  if((sampleVal[2] := value.byte[4]+(256*value.byte[5])-baselinePS[0]) < 0) 'PS1
    sampleVal[2] := 0           'Make sure values are not less than 0    
  if((sampleVal[3] := value.byte[6]+(256*value.byte[7])-baselinePS[1]) < 0) 'PS2
    sampleVal[3] := 0           'Make sure values are not less than 0    
  if((sampleVal[4] := value.byte[8]+(256*value.byte[9])-baselinePS[2]) < 0) 'PS3
    sampleVal[4] := 0           'Make sure values are not less than 0    
  sampleCnt += 1
  MutexRelease

  'NOTE: In continuous mode, INT flags should be cleared after calling this function.

   
PRI ClearIntFlags 
  WriteToRegister(REG_IRQ_STATUS, GetIntFlags)

  
PRI GetIntFlags : intFlags
  return ReadFromRegister(REG_IRQ_STATUS) 

          
PRI MutexGet
  repeat until not lockset(mutexLock)      'Wait on lock to make sure we're not in the middle of a new measurement


PRI MutexRelease
  lockclr(mutexLock)                       'Clear the lock


PRI SystemReset
{This function generates a hardware reset of the device.}

  SendCommand(CMD_RESET)
  waitcnt(cnt + (clkfreq/1000)*30)    'Need to wait at least 25ms for device to come out of reset (try 30ms for safe margin) 

                  
PRI WriteToRegister(register, value) 
{This function writes the value to the specified I2C register.  Return value (-1) is NAK.  0 means ACK}
  'Send I2C address, register address, then value
  if(i2c.WriteByte((I2C_SLAVE_ADDR << 1), 1, 0) <> 0)     'Send device address (R/!W = 0), send start, no stop
    return -1
  if(i2c.WriteByte(register, 0, 0) <> 0)                  'Send register to write, no start, no stop
    return -1
  if(i2c.WriteByte(value, 0, 1) <> 0)                     'Send value, no start, send stop
    return -1
  return 0
  

PRI ReadFromRegister(register) : value
{This function returns the value read from the specified I2C register.}
  'Send I2C address, register address.  Send I2C address, read value.
  if(i2c.WriteByte((I2C_SLAVE_ADDR << 1), 1, 0) <> 0)     'Send device address (R/!W = 0), send start, no stop
    return -1
  if(i2c.WriteByte(register, 0, 1) <> 0)                  'Send register to write, no start, send stop
    return -1
  
  if(i2c.WriteByte((I2C_SLAVE_ADDR << 1) | 1, 1, 0) <> 0)  'Send device address (R/!W = 1), send start, no stop
    return -1
  value := i2c.ReadByte(1, 1)                                  'Read byte, send nak (to terminate read), send stop

PRI ReadBurst(startI2cAddr, destByteArrayPtr, bytesToRead)
{This function operates very much like ReadFromRegister, but is capable of reading from
multiple registers in a single continous burst, resulting in a more efficient read cycle. }
  
  if(bytesToRead < 1)  'make sure the value for numBytes is at least 1 byte.
    return -1

  if(i2c.WriteByte((I2C_SLAVE_ADDR << 1), 1, 0) <> 0)     'Send device address (R/!W = 0), send start, no stop
    return -1
  if(i2c.WriteByte(startI2cAddr, 0, 0) <> 0)                  'Send register to write, no start, no stop
    return -1
  
  if(i2c.WriteByte((I2C_SLAVE_ADDR << 1) | 1, 1, 0) <> 0)  'Send device address (R/!W = 1), send start, no stop
    return -1
  repeat while bytesToRead > 1
    byte[destByteArrayPtr] := i2c.ReadByte(0, 0)    'Read byte, don't send nak (so read continues), no stop (yet)
    destByteArrayPtr += 1           'advance the pointer to the next byte
    bytesToRead -= 1            'reduce byte count by 1
  byte[destByteArrayPtr] := i2c.ReadByte(1, 1)    'Read last byte, send nak (to terminate read), send stop
  

PRI ParamSet(param_addr, value)
{This function uses the device command mailbox system to set the value in a specified parameter register.}

  'Command for PARAM_SET is $A0.  Add the parameter address offset to this value for the REG_COMMAND value.
  'The value needs to be placed in the REG_WR before placing the parameter address in REG_COMMAND.
  WriteToRegister(REG_PARAM_WR, value)
  SendCommand(CMD_PARAM_SET + (param_addr & $1F))
  

PRI ParamQuery(param_addr) : value
{This function uses the device command mailbox system to get the value in a specified parameter register.}

  'Command for PARAM_SET is $A0.  Add the parameter address offset to this value for the REG_COMMAND value.
  SendCommand(CMD_PARAM_QUERY + (param_addr & $1F))
  return ReadFromRegister(REG_PARAM_RD)
    

PRI Compress(value16) : value8  | temp, exponent, significand
{The purpose of this function is to compress a 16-bit value into an 8-bit value. See Si114x documentation for
full details on how this is being accomplished.}

  'Since these values could have multiple valid results, we'll just declare the result here
  if(value16 == $0000)
    return $00
  if(value16 == $0001)
    return $08

  'Get the exponent. Should be at least 1 now.
  temp := value16
  repeat
    temp >>= 1                  'shift right by one place, then increase the exponent
    exponent += 1
    if(temp == 1)
      quit

  'Now get the 4 fractional bits.
  '(If exponent is between 1 and 4, we don't need any fractional rounding)
  if(exponent < 5)
    significand := (value16 << (4 - exponent))
    return (exponent << 4) | (significand & $0F)

  'Calculate the fraction, may need to do rounding later
  significand := value16 >> (exponent - 5)

  'Check if we need to do rounding (check bit0 position)
  if(significand & $01)         'this means we'll need to round up
    significand += 2            'increment bit1 position
    'Check for carry and inrement exponent if necessary
    if(significand & $0040)
      exponent += 1             
      significand >>= 1

  'Shift down by one more bit (since we saved it above to check if we needed to round)
  significand >>= 1
  
  'Rounding is done, return encoded value
  return (exponent << 4) | (significand & $0F)
  

PRI Uncompress(value8) : value16 | exponent, output
{The purpose of this function is to decompress an 8-bit value back into a 16-bit value.  See Si1143 documentation
for full details on how this is being accomplished.}

  'Handle case where the exponent is zero. (If value is below 8/16, round down to 0. If value is above, round up to 1)
  if(value8 < 8)
    return 0

  exponent := (value8 & $F0) >> 4    'Get exponent part
  output := $10 | (value8 & $0F)      'Get fractional part and add to implied integer (now we have a 5-bit value)

  if(exponent => 4)
    return (output << (exponent - 4))  'Shift values left
  else
    return (output >> (4 - exponent))  'Shift values right



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