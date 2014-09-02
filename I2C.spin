{
The beginnings of Daniel's new I2C driver.

The bare minimum is here to just get the thing going.

This driver does not drive the SCL or SDA lines high, so pull-up resistors
on both lines are REQUIRED.

This has been significantly revised by Kevin McCullough.
}

'con

'  ACK = 0
'  NAK = -1

CON
  CLK_STRETCH_MAX_CYCLES   = 10000
  DELAY_CYCLES = 1

VAR
  byte sdaPin, sclPin, started

PUB Init(_sda, _scl)
  sdaPin := _sda
  sclPin := _scl

  dira[sdaPin]~                 'float the I2C data pin
  dira[sclPin]~                 'float the I2C clock pin
  outa[sdaPin]~                 'when set as an output, drives the I2C data pin low
  outa[sclPin]~                 'when set as an output, drives the I2C clock pin low

PUB ResetBus
'Probably don't need this, but will try to see if it solves my problems

  FloatSDA
  repeat until ReadSDA
    FloatSCL
    ClearSCL
  StopCond

PUB StartCond
  if(started)                   'if already started, then do a RE-start condition
    FloatSDA                    'float SDA high
    Delay
    FloatSCL
    repeat CLK_STRETCH_MAX_CYCLES    'wait (with timout) for the SCL pin to be high (to allow for clock stretching)
      if(ReadSCL == 1)
        quit
    Delay                       'repeated start setup time, minimum 4.7us (according to Wikipedia)
  if(ReadSDA == 0)              'SDA should be high, but if not then arbitration error
    ArbitrationLost
  ClearSDA                      'SCL is high, so set SDA from 1 to 0
  Delay
  ClearSCL                      'Set the clock low to prepare for data
  started := 1                  '...and set frame state to "started"
    

PUB StopCond
  ClearSDA
  Delay
  FloatSCL
  repeat CLK_STRETCH_MAX_CYCLES    'wait (with timout) for the SCL pin to be high (to allow for clock stretching)
    if(ReadSCL == 1)
      quit
  Delay
  FloatSDA                      'SCL is high, so set SDA from 0 to 1.  
  Delay                         'stop bit setup time, minimum 4us (according to Wikipedia)
  if(ReadSDA == 0)              'SDA should be high, but if not then arbitration error 
    ArbitrationLost
  Delay
  started := 0
  

PUB WriteBit(value)
  value &= 1                    'mask to ensure it is only a bit value
  if(value)
    FloatSDA                    'float SDA high
  else
    ClearSDA                    'drive SDA low
  Delay
  FloatSCL                      'clock high
  repeat CLK_STRETCH_MAX_CYCLES    'wait (with timout) for the SCL pin to be high (to allow for clock stretching)
    if(ReadSCL == 1)
      quit
  if(ReadSDA <> value)          'SDA should be same as bit (set previously), but if not then arbitration error
    ArbitrationLost
  Delay
  ClearSCL                      'clock low

PUB ReadBit : value
  FloatSDA                      'float SDA high (let the slave drive the data)
  Delay
  FloatSCL                      'clock high
  repeat CLK_STRETCH_MAX_CYCLES    'wait (with timout) for the SCL pin to be high (to allow for clock stretching)
    if(ReadSCL == 1)
      quit
  value := ReadSDA              'read pin value on SDA
  Delay
  ClearSCL                      'drive SCL low

PUB WriteByte(value, sendStart, sendStop) : nak
  if(sendStart)                     'Send start condition if specified to do so
    StartCond
  repeat 8
    WriteBit((value & $80) <> 0)    'Send MSB of the value. Comparison with zero makes bit value a boolean.
    value <<= 1
  nak := ReadBit                'Get ack or nak
  if(sendStop)                       'Send stop condition if specified to do so
    StopCond

PUB ReadByte(nak, sendStop) : value
  repeat 8
    value := (value << 1) | (ReadBit)  'Shift in each bit
  WriteBit(nak <> 0)                   'Send ack or nak. Comparison with zero makes value a boolean.
  if(sendStop)                         'Send stop condition if specified to do so                 
    StopCond

PRI ReadSCL : value
  value := ina[sclPin]          'return the value on the pin

PRI ReadSDA : value
  value := ina[sdaPin]          'return the value on the pin

PRI FloatSCL
  dira[sclPin]~                 'make SCL input (which causes the pin to float high)

PRI FloatSDA : value
  dira[sdaPin]~                 'make SDA input (which causes the pin to float high)
                                         
PRI ClearSCL
  dira[sclPin]~~                'make SCL output (low)

PRI ClearSDA
  dira[sdaPin]~~                'make SDA output (low)

PRI Delay
  'I think this delay should be set to half the I2C bit time
  repeat DELAY_CYCLES

PRI ArbitrationLost
  'This is called when a multi-master collision is detected.  Not a concern in most cases
  'but if so, this function should cause the master to drop out of this communication cycle
  'and after some delay, re-check for the bus to be available.
  
{  
PRI notes....

void I2CDELAY() {volatile int v; int i; for(i=0;i<I2CSPEED/2;i++) v;}
bool READSCL(void) {return 1;}  /* Set SCL as input and return current level of line, 0 or 1 */
bool READSDA(void) {return 1;}  /* Set SDA as input and return current level of line, 0 or 1 */
void CLRSCL(void) {} /* Actively drive SCL signal low */
void CLRSDA(void) {} /* Actively drive SDA signal low */
void ARBITRATION_LOST(void) {}
 
/* Global Data */
bool started = false;
 
void i2c_start_cond(void)
{
        /* if started, do a restart cond */
        if (started) {
                /* set SDA to 1 */
                READSDA();
                I2CDELAY();
                /* Clock stretching */
                while (READSCL() == 0)
                        ;  /* You should add timeout to this loop */
                /* Repeated start setup time, minimum 4.7us */
                I2CDELAY();
        }
        if (READSDA() == 0)
                ARBITRATION_LOST();
        /* SCL is high, set SDA from 1 to 0 */
        CLRSDA();
        I2CDELAY();
        CLRSCL();
        started = true;
}
 
void i2c_stop_cond(void)
{
        /* set SDA to 0 */
        CLRSDA();
        I2CDELAY();
        /* Clock stretching */
        while (READSCL() == 0)
                ;  /* You should add timeout to this loop */
        /* Stop bit setup time, minimum 4us */
        I2CDELAY();
        /* SCL is high, set SDA from 0 to 1 */
        if (READSDA() == 0)
                ARBITRATION_LOST();
        I2CDELAY();
        started = false;
}
 
/* Write a bit to I2C bus */
void i2c_write_bit(bool bit)
{
        if (bit) 
                READSDA();
        else 
                CLRSDA();
        I2CDELAY();
        /* Clock stretching */
        while (READSCL() == 0)
                ;  /* You should add timeout to this loop */
        /* SCL is high, now data is valid */
        /* If SDA is high, check that nobody else is driving SDA */
        if (bit && READSDA() == 0) 
                ARBITRATION_LOST();
        I2CDELAY();
        CLRSCL();
}
 
/* Read a bit from I2C bus */
bool i2c_read_bit(void)
{
        bool bit;
        /* Let the slave drive data */
        READSDA();
        I2CDELAY();
        /* Clock stretching */
        while (READSCL() == 0)
                ;  /* You should add timeout to this loop */
        /* SCL is high, now data is valid */
        bit = READSDA();
        I2CDELAY();
        CLRSCL();
        return bit;
}
 
/* Write a byte to I2C bus. Return 0 if ack by the slave */
bool i2c_write_byte(bool send_start, bool send_stop, unsigned char byte)
{
        unsigned bit;
        bool nack;
        if (send_start) 
                i2c_start_cond();
        for (bit = 0; bit < 8; bit++) {
                i2c_write_bit((byte & 0x80) != 0);
                byte <<= 1;
        }
        nack = i2c_read_bit();
        if (send_stop)
                i2c_stop_cond();
        return nack;
}
 
/* Read a byte from I2C bus */
unsigned char i2c_read_byte(bool nack, bool send_stop)
{
        unsigned char byte = 0;
        unsigned bit;
        for (bit = 0; bit < 8; bit++)
                byte = (byte << 1) | i2c_read_bit();             
        i2c_write_bit(nack);
        if (send_stop)
                i2c_stop_cond();
        return byte;
}

}

{
pub ResetBus
'when might I need to use this function???

  SdaHigh
  repeat until ina[sdaPin]
    SclHigh
    SclLow

  SendStop
}

{
pub AckPoll(control)

  repeat 50
  SendStart
  repeat while TxByte(control & !$01)
    SendStart
  SendStop
}
                        
{
pub TxByte(byteToSend) | i


  'send our 8 bits, MSB first
  repeat i from 7 to 0
    SclLow
    if (byteToSend >> i) & 1
      SdaHigh                   'send a 1
    else
      SdaLow                    'send a 0
    SclHigh

  SclLow
  
  dira[sdaPin]~                 'make the data line an input to get the acknowledge from the slave
  repeat 50                     'add in a little delay to let the slave device respond
  SclHigh                       'acknowledge should become valid at this time
  repeat 50                     'add in a little delay to let the slave device respond
  if ina[sdaPin]                'read in and return the acknowledge
    result := NAK
  else
    result := ACK
  SclLow
'  repeat 50

pub RxByte(inAck) | i

  result~
  dira[sdaPin]~                 'make the data pin an input
  repeat i from 7 to 0          'get 8 bits
    SclLow
    SclHigh
    
    result |= ina[sdaPin] << i  'read the state of the pin and save it to our byte, one bit at a time
  
  SclLow

  'Sets the data pin to the desigered NAK/ACK
  if inAck
    SdaHigh   'NAK
  else
    SdaLow    'ACK

  SclHigh
  SclLow
 
pub SendStart
  SclHigh
  SdaHigh
  SdaLow
  SclLow

PUB AckPoll
  

pub SendStop
  SclLow
  SdaLow
  repeat 10
  SclHigh
  SdaHigh

PRI SclHigh
  dira[sclPin]~

PRI SclLow
  dira[sclPin]~~

PRI SdaHigh
  dira[sdaPin]~

PRI SdaLow
  dira[sdaPin]~~

}