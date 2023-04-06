/** @file
 * This code implements a slight abstraction above the Wire library
 * to  make I2C connection handling thread safe(r).
 */
#include <Wire.h>

/**
 * An abstraction to make I2C connection thread safe(r).
 *
 * @todo integrate TwoWire instance (instead of reference)
 */
class Multiplexer {
  bool locked = false; /**< flag the current use */
  uint8_t address;     /**< I2C address of the multiplexer */
public:
  TwoWire *i2c = NULL; /**< internal I2C bus instance */

public:
  Multiplexer(void);
  bool setup(TwoWire *tw, uint8_t address, int data, int clock);
  bool set_lock(void);
  bool set_lock(uint8_t channel);
  void remove_lock(void);
  bool is_free(void);
  bool select_channel(uint8_t channel);
};

/**
 * Create a new instance of a multiplexer.
 */
Multiplexer::Multiplexer(void) {
  locked = false;
  i2c = NULL;
}

/**
 * Set up the internal data structures.
 *
 * @warning Reusing the same bus number causes race conditions, crashes, and
 * unstable code/runtime behaviour.
 * @param tw is a pointer to a unique TwoWire instance
 * @param address is the I2C address of the multiplexer
 * @param data is the data pin
 * @param clock is the clock pin
 * @return true if setup was successful, false if error occured
 */
bool Multiplexer::setup(TwoWire *tw, uint8_t address, int data, int clock) {
  if (NULL != tw) {
    return false;
  }
  if (locked) {
    return false;
  }
  i2c = tw;
  this->address = address;
  return i2c->begin(data, clock, 100000);
}

/**
 * Set the internal lock to block others from using the current
 * connection.
 *
 * @returns true if setting lock was successful, false if already locked.
 * @see set_lock(uint8_t channel)
 * @see remove_lock()
 * @see is_free()
 * @see select_channel(uint8_t channel)
 */
bool Multiplexer::set_lock(void) {
  if (locked) {
    return false;
  }
  locked = true;
  return locked;
}

/**
 * Set the internal lock and channel on multiplexer to block others from
 * using the current connection.
 *
 * @returns true if setting lock was successful, false if already locked or
 * channel selection failed.
 * @note The internal lock is cleared if no channel could be selected.
 * @see set_lock()
 * @see remove_lock()
 * @see is_free()
 * @see select_channel(uint8_t channel)
 */
bool Multiplexer::set_lock(uint8_t channel) {
  // already locked?
  if (locked) {
    return false;
  }
  // set lock
  locked = true;
  // try to select channel
  if (this->select_channel(channel)) {
    return true;
  }
  // selecting channel failed, so we can unlock
  locked = false;
  return false;
}

/**
 * Free the internal lock to allow others to use the current
 * connection.
 *
 * @see set_lock()
 * @see set_lock(uint8_t channel)
 * @see is_free()
 */
void Multiplexer::remove_lock(void) { locked = false; }

/**
 * Check if the I2C connection is free to use.
 *
 * @returns true if connection is free, false if blocked.
 * @see set_lock()
 * @see set_lock(uint8_t channel)
 * @see remove_lock()
 */
bool Multiplexer::is_free(void) { return !locked; }

/**
 * Select a given channel on the multiplexer.
 *
 * @returns true if channel is set, false if channel is out of range
 * @see set_lock()
 * @see set_lock(uint8_t channel)
 * @see remove_lock()
 * @see is_free()
 * @note The internal lock is untouched, i.e. failing to select a channel
 * requires an explicit remove_lock().
 */
bool Multiplexer::select_channel(uint8_t channel) {
  if (NULL == i2c) {
    return false;
  }
  // channel out of range
  if (channel > 7) {
    return false;
  }

  // select the multiplexer by its hardware address
  i2c->beginTransmission(address);
  // select a channel on the multiplexer
  if (!(1 == Wire.write(1 << channel))) {
    return false;
  }
  i2c->endTransmission();

  return true;
}
