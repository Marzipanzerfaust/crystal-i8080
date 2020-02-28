require "./cpu/ops"

# Emulator for the Intel 8080 CPU.
#
# Load a ROM and execute it:
# ```
# cpu = I8080::CPU.new
# cpu.load_file("path/to/rom")
# cpu.run
# ```
#
# Alternatively, you can create a CPU in debug mode which has an
# embedded `Disassembler` that will print instructions as they are
# executed:
# ```
# cpu = I8080::CPU.new(debug: true)
# cpu.load_file("path/to/rom")
# cpu.step  # => 0000: 31 34 12  LXI    SP,$1234
# cpu.step  # => 0003: 3E 56     MVI    A,$56
# ```
#
# This is intended to be used in applications that require an embedded
# Intel 8080 core.
class I8080::CPU
  # The AF register pair; also known as the *PSW* (Program Status Word).
  getter af = Pair.new(0)
  # The BC register pair.
  getter bc = Pair.new(0)
  # The DE register pair.
  getter de = Pair.new(0)
  # The HL register pair; primarily used for storing addresses.
  getter hl = Pair.new(0)

  # The *stack pointer*, used in stack operations.
  getter sp = Pair.new(0)
  # The *program counter*, which keeps track of which byte in the ROM is
  # about to be executed by the CPU.
  getter pc = Pair.new(0)

  # High byte pointer for AF; represents the A register; also known as
  # the *accumulator*.
  getter a : Byte*
  # Low byte pointer for AF; represents the F register; also known as
  # the *flag register*.
  getter f : Byte*
  # High byte pointer for BC; represents the B register.
  getter b : Byte*
  # Low byte pointer for BC; represents the C register.
  getter c : Byte*
  # High byte pointer for DE; represents the D register.
  getter d : Byte*
  # Low byte pointer for DE; represents the E register.
  getter e : Byte*
  # High byte pointer for HL; represents the H register.
  getter h : Byte*
  # Low byte pointer for HL; represents the L register.
  getter l : Byte*

  # Tells whether or not the CPU is accepting interrupts; controlled by
  # the EI and DI instructions.
  getter? int_enabled = false

  getter int_period : Int32
  getter cycles : Int32

  @tasks = [] of Proc(Nil)
  @timers = [] of Int32
  @periods = [] of Int32

  # Tells whether or not the CPU has halted execution.
  getter? stopped = true

  @jumped = false

  # The memory space for the CPU (size 0xFFFF).
  #
  # To interact with memory, see the `read_byte`, `read_word`,
  # `write_byte`, `write_word`, and `write_bytes` methods.
  getter memory = Pointer(Byte).malloc(0x10000)

  # The size in bytes of the currently loaded file.
  getter file_size = 0

  # The I/O space for the CPU (size 0xFF).
  #
  # Each byte represents the state of an I/O port. To interact with I/O
  # ports, see the `read_io`, `write_io`, `set_io`, and `reset_io`
  # methods.
  getter io = Pointer(Byte).malloc(0x100)

  # Tells whether or not the CPU is in debug mode.
  getter? debug : Bool

  # An embedded `Disassembler` that is created if the CPU is initialized
  # in debug mode.
  getter dasm : Disassembler?

  # If *debug* is given, the CPU will be created in debug mode.
  def initialize(@debug = false)
    @a, @f = @af.h, @af.l
    @b, @c = @bc.h, @bc.l
    @d, @e = @de.h, @de.l
    @h, @l = @hl.h, @hl.l

    @int_period = 0
    @cycles = 0

    @dasm = Disassembler.new(self) if debug?
  end

  # Resets all registers and flags to their initial values.
  def reset : Nil
    @af.w = @bc.w = @de.w = @hl.w = 0

    @pc.w = 0
    @sp.w = 0

    @cycles = @int_period

    @int_enabled = false
    @stopped = true
    @jumped = false
  end

  # Sets the refresh period to `CLOCK_RATE` / *freq*; necessary for
  # synchronizing the CPU with external devices.
  #
  # For example, if you want to tie the refresh period of the CPU to the
  # refresh rate of a 60Hz display, you would do `set_int_period(60)`.
  def set_int_period(freq : Number) : Nil
    @int_period = CLOCK_RATE // freq
    @cycles = @int_period
  end

  # Loads the contents of *filename* into the CPU's memory, starting at
  # the origin, then returns the file's size in bytes.
  def load_file(filename : String) : Int32
    data = File.read(filename).chomp
    @file_size = data.bytesize

    @memory.copy_from(data.to_unsafe, @file_size)

    return @file_size
  end

  # Returns the byte at the given address.
  def read_byte(addr : Word) : Byte
    @memory[addr]
  end

  # Returns the word at the given address.
  def read_word(addr : Word) : Word
    I8080.bytes_to_word(read_byte(addr), read_byte(addr + 1))
  end

  # Writes the given byte to the given address.
  def write_byte(addr : Word, value : Byte) : Nil
    @memory[addr] = value
  end

  # Writes *bytes* to memory sequentially starting at *addr*; useful for
  # strings.
  def write_bytes(addr : Word, bytes : Bytes) : Nil
    bytes.each.with_index { |b, i| write_byte(addr + i, b) }
  end

  # Writes the given word to the given address.
  def write_word(addr : Word, value : Word) : Nil
    lo, hi = I8080.word_to_bytes(value)

    write_byte(addr, lo)
    write_byte(addr + 1, hi)
  end

  # Pushes the given byte onto the stack, decrementing the stack
  # pointer.
  def push_byte(byte : Byte) : Nil
    @sp.w &-= 1
    @memory[@sp.w] = byte
  end

  # Pushes the given word onto the stack, decrementing the stack pointer
  # by two.
  def push_word(word : Word) : Nil
    lo, hi = I8080.word_to_bytes(word)

    push_byte(hi)
    push_byte(lo)
  end

  # Pops a byte off the stack, returning it and incrementing the stack pointer.
  def pop_byte : Byte
    @sp.w &+= 1
    return @memory[@sp.w &- 1]
  end

  # Pops a word off the stack, returning it and incrementing the stack
  # pointer by two.
  def pop_word : Word
    I8080.bytes_to_word(pop_byte, pop_byte)
  end

  # Returns the byte in the I/O port given by *port*.
  #
  # NOTE: Port numbers start at 1.
  def read_io(port : Byte) : Byte
    @io[port-1]
  end

  # Writes the given byte *x* to the I/O port given by *port*.
  #
  # NOTE: Port numbers start at 1.
  def write_io(port : Byte, x : Byte) : Nil
    @io[port-1] = x
  end

  # Sets the bit corresponding to *bit* in the I/O port given by *port*.
  #
  # NOTE: Port numbers start at 1.
  def set_io(port : Byte, bit : Byte) : Nil
    @io[port-1] |= 1 << bit
  end

  # Resets the bit corresponding to *bit* in the I/O port given by
  # *port*.
  #
  # NOTE: Port numbers start at 1.
  def reset_io(port : Byte, bit : Byte) : Nil
    @io[port-1] &= ~(1 << bit)
  end

  private def next_byte : Byte
    @pc.w &+= 1
    return @memory[@pc.w]
  end

  private def next_word : Word
    I8080.bytes_to_word(next_byte, next_byte)
  end

  # Executes a single instruction and increments the program counter.
  def step : Nil
    # If we're in debug mode, print the assembly for the instruction
    # that's about to be executed
    @dasm.try do |dasm|
      dasm.addr = @pc.w
      dasm.step
    end

    op(read_byte(@pc.w))

    if @jumped
      @jumped = false
    else
      @pc.w &+= 1
    end
  end

  # Executes instructions until the program stops or until the program
  # counter falls outside the scope of the file. Primarily used for
  # testing.
  def run : Nil
    @stopped = false

    until stopped?
      step
      break if @pc.w == 0 || @pc.w >= @file_size
    end
  end

  # # Executes instructions until the refresh period is over.
  # def exec : Nil
  #   loop do
  #     step
  #
  #     if @cycles <= 0
  #       @cycles += @int_period
  #       break
  #     end
  #   end
  # end

  # Executes the given opcode as if it were a generated interrupt.
  def interrupt(code : Byte) : Nil
    return unless int_enabled?

    @int_enabled = false

    @dasm.try &.disassemble(code, label: "INTE")

    op(code)

    @jumped = false
  end

  # # Registers a task that occurs *n* times per refresh period. Used
  # # primarily for handling cyclic tasks like refreshing the display.
  # def register_task(n = 1, &task : Proc(Nil)) : Nil
  #   period = @int_period // n
  #
  #   @tasks << task
  #   @timers << period
  #   @periods << period
  # end

  # Sets the flag represented by *f*.
  def set_flag(f : Byte) : Nil
    @f.value |= f
  end

  # Resets the the flag represented by *f*.
  def reset_flag(f : Byte) : Nil
    @f.value &= ~f
  end

  # Is the flag *f* set?
  def flag?(f : Byte) : Bool
    @f.value.bits_set?(f)
  end

  private def set_szp(x : Byte)
    reset_flag(SF|ZF|PF)

    set_flag(SF) if x.bit(7) == 1
    set_flag(ZF) if x.zero?

    # Set the parity flag if the number of bits in x is even
    n = (0..7).count { |i| x.bit(i) == 1 }
    set_flag(PF) if n.even?
  end

  private def set_aux_carry(a : Byte, b : Byte)
    a_low = a & 0xF
    b_low = b & 0xF

    if a_low + b_low > 15
      set_flag(AF)
    else
      reset_flag(AF)
    end
  end
end
