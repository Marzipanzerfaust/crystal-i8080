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
# cpu.step  # => 0000: 31 34 12    LXI    SP,$1234
# cpu.step  # => 0003: 3E 56       MVI    A,$56
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
  getter int_enable = false

  # Interrupt opcode to be set by peripheral devices.
  property int_request : Byte?

  @refresh_period = 0_f64
  @int_period = 0_f64

  @cyclic_tasks = {} of Proc(Nil) => Float64

  # Number of CPU cycles left before interrupt occurs.
  getter cycles = 0_f64

  # Tells whether or not the CPU has halted execution.
  getter stopped = true

  @jumped = false

  # The memory space for the CPU (size 0xFFFF).
  #
  # To interact with memory, see the `read_byte`, `read_word`,
  # `write_byte`, `write_word`, and `write_bytes` methods.
  getter memory = Bytes.new(0x10000)

  # The size in bytes of the currently loaded file.
  getter file_size = 0

  # The I/O space for the CPU (size 0xFF).
  #
  # Each byte represents the state of an I/O port. To interact with I/O
  # ports, see the `read_io`, `write_io`, `set_io`, and `reset_io`
  # methods.
  getter io = Bytes.new(0x100)

  # Tells whether or not the CPU is in debug mode.
  getter debug : Bool

  # An embedded `Disassembler` that is created if the CPU is initialized
  # in debug mode.
  getter dasm : Disassembler?

  # If *debug* is given, the CPU will be created in debug mode.
  def initialize(@debug = false)
    @a, @f = @af.h, @af.l
    @b, @c = @bc.h, @bc.l
    @d, @e = @de.h, @de.l
    @h, @l = @hl.h, @hl.l

    @int_request = nil

    @dasm = Disassembler.new(self) if @debug
  end

  # Resets all registers and flags to their initial values, along with
  # the embedded disassembler if debug mode is active.
  def reset : Nil
    @af.w = @bc.w = @de.w = @hl.w = 0

    @pc.w = 0
    @sp.w = 0

    @cycles = @int_period

    @int_request = nil

    @int_enable = false
    @stopped = true
    @jumped = false

    @dasm.try &.reset
  end

  # Sets the refresh period to `CLOCK_RATE` / *freq*; necessary for
  # synchronizing the CPU with external devices.
  #
  # For example, if you want to tie the refresh period of the CPU to the
  # refresh rate of a 60Hz display, you would do `set_refresh_period(60)`.
  def set_refresh_period(freq : Number) : Nil
    @refresh_period = CLOCK_RATE / freq
  end

  # Loads the contents of *filename* into the CPU's memory, starting at
  # the origin, then returns the file's size in bytes.
  def load_file(filename : String) : Int32
    data = File.read(filename).chomp.to_slice
    @file_size = data.size

    @memory.copy_from(data)

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
    @pc.w += 1
    return @memory[@pc.w]
  end

  private def next_word : Word
    I8080.bytes_to_word(next_byte, next_byte)
  end

  # Executes *n* instructions and increments the program counter
  # accordingly.
  def step(n = 1) : Nil
    n.times do
      if @int_enable
        # `int_enable` has been set: check for interrupts
        @int_enable = false

        @int_request.try do |code|
          @dasm.try &.disassemble(code)
          op(code)
          code = nil
        end
      else
        # Otherwise, execute the next opcode as normal

        # If we're in debug mode, print the instruction that's about to be
        # executed
        @dasm.try do |dasm|
          dasm.addr = @pc.w
          dasm.step
        end

        op(read_byte(@pc.w))

        next if @int_enable
      end

      if @jumped
        @jumped = false
      else
        @pc.w += 1
      end
    end
  end

  # Executes instructions until the program stops or until the program
  # counter falls outside the scope of the program for some reason.
  def run : Nil
    @stopped = false

    loop do
      step

      # If the interrupt period has expired...
      if @cycles <= 0
        check_tasks

        # Reset the cycle counter
        @cycles += @int_period

        break if @stopped || @pc.w >= @file_size || @pc.w == 0
      end
    end
  end

  # Executes instructions until the next interrupt.
  def exec : Nil
    loop do
      step

      # If the interrupt period has expired...
      if @cycles <= 0
        check_tasks

        # Reset the cycle counter
        @cycles += @int_period

        break
      end
    end
  end

  # Registers a task that occurs every *period* cycles. Used primarily
  # for handling cyclic tasks like refreshing the display.
  def register_task(period : Number, &task : Proc(Nil)) : Nil
    @cyclic_tasks[task] = {period, period}
    update_int_period(period)
  end

  private def update_int_period(n : Float64) : Nil
    if @int_period > 0
      @int_period = @int_period.gcd(n)
    else
      @int_period = n
    end
  end

  # Check each registered task, decrement timers, and execute the tasks
  # whose timers have expired. After a task is executed, its timer will
  # be reset.
  private def check_tasks : Nil
    @cyclic_tasks.each do |task, (period, timer)|
      timer -= @int_period

      if timer <= 0
        task.call
        timer += period
      end
    end
  end

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

  # Instructions

  private def op(code : Byte)
    case code
    when 0x00 then nop
    when 0x01 then lxi(@bc, next_word)
    when 0x02 then stax(@bc)
    when 0x03 then inx(@bc)
    when 0x04 then inr(@b)
    when 0x05 then dcr(@b)
    when 0x06 then mvi(@b, next_byte)
    when 0x07 then rlc
    when 0x08 then nop
    when 0x09 then dad(@bc)
    when 0x0A then ldax(@bc)
    when 0x0B then dcx(@bc)
    when 0x0C then inr(@c)
    when 0x0D then dcr(@c)
    when 0x0E then mvi(@c, next_byte)
    when 0x0F then rrc
    when 0x10 then nop
    when 0x11 then lxi(@de, next_word)
    when 0x12 then stax(@de)
    when 0x13 then inx(@de)
    when 0x14 then inr(@d)
    when 0x15 then dcr(@d)
    when 0x16 then mvi(@d, next_byte)
    when 0x17 then ral
    when 0x18 then nop
    when 0x19 then dad(@de)
    when 0x1A then ldax(@de)
    when 0x1B then dcx(@de)
    when 0x1C then inr(@e)
    when 0x1D then dcr(@e)
    when 0x1E then mvi(@e, next_byte)
    when 0x1F then rar
    when 0x20 then nop
    when 0x21 then lxi(@hl, next_word)
    when 0x22 then shld(next_word)
    when 0x23 then inx(@hl)
    when 0x24 then inr(@h)
    when 0x25 then dcr(@h)
    when 0x26 then mvi(@h, next_byte)
    when 0x27 then daa
    when 0x28 then nop
    when 0x29 then dad(@hl)
    when 0x2A then lhld(next_word)
    when 0x2B then dcx(@hl)
    when 0x2C then inr(@l)
    when 0x2D then dcr(@l)
    when 0x2E then mvi(@l, next_byte)
    when 0x2F then cma
    when 0x30 then nop
    when 0x31 then lxi(@sp, next_word)
    when 0x32 then sta(next_word)
    when 0x33 then inx(@sp)
    when 0x34 then inr_m
    when 0x35 then dcr_m
    when 0x36 then mvi_m(next_byte)
    when 0x37 then stc
    when 0x38 then nop
    when 0x39 then dad(@sp)
    when 0x3A then lda(next_word)
    when 0x3B then dcx(@sp)
    when 0x3C then inr(@a)
    when 0x3D then dcr(@a)
    when 0x3E then mvi(@a, next_byte)
    when 0x3F then cmc
    when 0x40 then mov(@b, @b)
    when 0x41 then mov(@b, @c)
    when 0x42 then mov(@b, @d)
    when 0x43 then mov(@b, @e)
    when 0x44 then mov(@b, @h)
    when 0x45 then mov(@b, @l)
    when 0x46 then mov_to(@b)
    when 0x47 then mov(@b, @a)
    when 0x48 then mov(@c, @b)
    when 0x49 then mov(@c, @c)
    when 0x4A then mov(@c, @d)
    when 0x4B then mov(@c, @e)
    when 0x4C then mov(@c, @h)
    when 0x4D then mov(@c, @l)
    when 0x4E then mov_to(@c)
    when 0x4F then mov(@c, @a)
    when 0x50 then mov(@d, @b)
    when 0x51 then mov(@d, @c)
    when 0x52 then mov(@d, @d)
    when 0x53 then mov(@d, @e)
    when 0x54 then mov(@d, @h)
    when 0x55 then mov(@d, @l)
    when 0x56 then mov_to(@d)
    when 0x57 then mov(@d, @a)
    when 0x58 then mov(@e, @b)
    when 0x59 then mov(@e, @c)
    when 0x5A then mov(@e, @d)
    when 0x5B then mov(@e, @e)
    when 0x5C then mov(@e, @h)
    when 0x5D then mov(@e, @l)
    when 0x5E then mov_to(@e)
    when 0x5F then mov(@e, @a)
    when 0x60 then mov(@h, @b)
    when 0x61 then mov(@h, @c)
    when 0x62 then mov(@h, @d)
    when 0x63 then mov(@h, @e)
    when 0x64 then mov(@h, @h)
    when 0x65 then mov(@h, @l)
    when 0x66 then mov_to(@h)
    when 0x67 then mov(@h, @a)
    when 0x68 then mov(@l, @b)
    when 0x69 then mov(@l, @c)
    when 0x6A then mov(@l, @d)
    when 0x6B then mov(@l, @e)
    when 0x6C then mov(@l, @h)
    when 0x6D then mov(@l, @l)
    when 0x6E then mov_to(@l)
    when 0x6F then mov(@l, @a)
    when 0x70 then mov_from(@b)
    when 0x71 then mov_from(@c)
    when 0x72 then mov_from(@d)
    when 0x73 then mov_from(@e)
    when 0x74 then mov_from(@h)
    when 0x75 then mov_from(@l)
    when 0x76 then hlt
    when 0x77 then mov_from(@a)
    when 0x78 then mov(@a, @b)
    when 0x79 then mov(@a, @c)
    when 0x7A then mov(@a, @d)
    when 0x7B then mov(@a, @e)
    when 0x7C then mov(@a, @h)
    when 0x7D then mov(@a, @l)
    when 0x7E then mov_to(@a)
    when 0x7F then mov(@a, @a)
    when 0x80 then add(@b)
    when 0x81 then add(@c)
    when 0x82 then add(@d)
    when 0x83 then add(@e)
    when 0x84 then add(@h)
    when 0x85 then add(@l)
    when 0x86 then add_m
    when 0x87 then add(@a)
    when 0x88 then adc(@b)
    when 0x89 then adc(@c)
    when 0x8A then adc(@d)
    when 0x8B then adc(@e)
    when 0x8C then adc(@h)
    when 0x8D then adc(@l)
    when 0x8E then adc_m
    when 0x8F then adc(@a)
    when 0x90 then sub(@b)
    when 0x91 then sub(@c)
    when 0x92 then sub(@d)
    when 0x93 then sub(@e)
    when 0x94 then sub(@h)
    when 0x95 then sub(@l)
    when 0x96 then sub_m
    when 0x97 then sub(@a)
    when 0x98 then sbb(@b)
    when 0x99 then sbb(@c)
    when 0x9A then sbb(@d)
    when 0x9B then sbb(@e)
    when 0x9C then sbb(@h)
    when 0x9D then sbb(@l)
    when 0x9E then sbb_m
    when 0x9F then sbb(@a)
    when 0xA0 then ana(@b)
    when 0xA1 then ana(@c)
    when 0xA2 then ana(@d)
    when 0xA3 then ana(@e)
    when 0xA4 then ana(@h)
    when 0xA5 then ana(@l)
    when 0xA6 then ana_m
    when 0xA7 then ana(@a)
    when 0xA8 then xra(@b)
    when 0xA9 then xra(@c)
    when 0xAA then xra(@d)
    when 0xAB then xra(@e)
    when 0xAC then xra(@h)
    when 0xAD then xra(@l)
    when 0xAE then xra_m
    when 0xAF then xra(@a)
    when 0xB0 then ora(@b)
    when 0xB1 then ora(@c)
    when 0xB2 then ora(@d)
    when 0xB3 then ora(@e)
    when 0xB4 then ora(@h)
    when 0xB5 then ora(@l)
    when 0xB6 then ora_m
    when 0xB7 then ora(@a)
    when 0xB8 then cmp(@b)
    when 0xB9 then cmp(@c)
    when 0xBA then cmp(@d)
    when 0xBB then cmp(@e)
    when 0xBC then cmp(@h)
    when 0xBD then cmp(@l)
    when 0xBE then cmp_m
    when 0xBF then cmp(@a)
    when 0xC0 then rnz
    when 0xC1 then pop(@bc)
    when 0xC2 then jnz(next_word)
    when 0xC3 then jmp(next_word)
    when 0xC4 then cnz(next_word)
    when 0xC5 then push(@bc)
    when 0xC6 then adi(next_byte)
    when 0xC7 then rst(0)
    when 0xC8 then rz
    when 0xC9 then ret
    when 0xCA then jz(next_word)
    when 0xCB then jmp(next_word)
    when 0xCC then cz(next_word)
    when 0xCD then call(next_word)
    when 0xCE then aci(next_byte)
    when 0xCF then rst(1)
    when 0xD0 then rnc
    when 0xD1 then pop(@de)
    when 0xD2 then jnc(next_word)
    when 0xD3 then out(next_byte)
    when 0xD4 then cnc(next_word)
    when 0xD5 then push(@de)
    when 0xD6 then sui(next_byte)
    when 0xD7 then rst(2)
    when 0xD8 then rc
    when 0xD9 then ret
    when 0xDA then jc(next_word)
    when 0xDB then in(next_byte)
    when 0xDC then cc(next_word)
    when 0xDD then call(next_word)
    when 0xDE then sbi(next_byte)
    when 0xDF then rst(3)
    when 0xE0 then rpo
    when 0xE1 then pop(@hl)
    when 0xE2 then jpo(next_word)
    when 0xE3 then xthl
    when 0xE4 then cpo(next_word)
    when 0xE5 then push(@hl)
    when 0xE6 then ani(next_byte)
    when 0xE7 then rst(4)
    when 0xE8 then rpe
    when 0xE9 then pchl
    when 0xEA then jpe(next_word)
    when 0xEB then xchg
    when 0xEC then cpe(next_word)
    when 0xED then call(next_word)
    when 0xEE then xri(next_byte)
    when 0xEF then rst(5)
    when 0xF0 then rp
    when 0xF1 then pop(@af)
    when 0xF2 then jp(next_word)
    when 0xF3 then di
    when 0xF4 then cp(next_word)
    when 0xF5 then push(@af)
    when 0xF6 then ori(next_byte)
    when 0xF7 then rst(6)
    when 0xF8 then rm
    when 0xF9 then sphl
    when 0xFA then jm(next_word)
    when 0xFB then ei
    when 0xFC then cm(next_word)
    when 0xFD then call(next_word)
    when 0xFE then cpi(next_byte)
    when 0xFF then rst(7)
    end

    @cycles -= OP_CYCLES[code]
  end

  private def nop
  end

  private def cmc
    flag?(CF) ? reset_flag(CF) : set_flag(CF)
  end

  private def stc
    set_flag(CF)
  end

  private def inr(reg : Byte*)
    reg.value &+= 1
    set_szp(reg.value)
  end

  private def inr_m
    tmp = read_byte(@hl.w) &+ 1
    write_byte(@hl.w, tmp)
    set_szp(tmp)
  end

  private def dcr(reg : Byte*)
    reg.value &-= 1
    set_szp(reg.value)
  end

  private def dcr_m
    tmp = read_byte(@hl.w) &- 1
    write_byte(@hl.w, tmp)
    set_szp(tmp)
  end

  private def cma
    @a.value = ~@a.value
  end

  private def daa
    a_low = @a.value & 0xF

    if a_low > 9 || flag?(AF)
      @a.value &+= 6
      set_flag(AF)
    else
      reset_flag(AF)
    end

    a_high = @a.value >> 4

    if a_high > 9 || flag?(CF)
      @a.value &+= 6 << 4
      set_flag(CF)
    end

    set_szp(@a.value)
  end

  private def mov(reg1 : Byte*, reg2 : Byte*)
    reg1.value = reg2.value
  end

  private def mov_to(reg : Byte*)
    reg.value = read_byte(@hl.w)
  end

  private def mov_from(reg : Byte*)
    write_byte(@hl.w, reg.value)
  end

  private def stax(pair : Pair)
    write_byte(pair.w, @a.value)
  end

  private def ldax(pair : Pair)
    @a.value = read_byte(pair.w)
  end

  private def _add(x : Byte)
    set_aux_carry(@a.value, x)

    if x > Byte::MAX - @a.value
      set_flag(CF)
    else
      reset_flag(CF)
    end

    @a.value &+= x

    set_szp(@a.value)
  end

  private def add(reg : Byte*)
    _add(reg.value)
  end

  private def add_m
    _add(read_byte(@hl.w))
  end

  private def adc(reg : Byte*)
    _add(reg.value + (flag?(CF) ? 1 : 0))
  end

  private def adc_m
    _add(read_byte(@hl.w) + (flag?(CF) ? 1 : 0))
  end

  private def _sub(x : Byte)
    set_aux_carry(@a.value, (~x &+ 1).unsafe_as(Byte))

    if x > @a.value
      set_flag(CF)
    else
      reset_flag(CF)
    end

    @a.value &-= x

    set_szp(@a.value)
  end

  private def sub(reg : Byte*)
    _sub(reg.value)
  end

  private def sub_m
    _sub(read_byte(@hl.w))
  end

  private def sbb(reg : Byte*)
    _sub(reg.value + (flag?(CF) ? 1 : 0))
  end

  private def sbb_m
    _sub(read_byte(@hl.w) + (flag?(CF) ? 1 : 0))
  end

  private def _ana(x : Byte)
    @a.value &= x
    reset_flag(CF|AF)
    set_szp(@a.value)
  end

  private def ana(reg : Byte*)
    _ana(reg.value)
  end

  private def ana_m
    _ana(read_byte(@hl.w))
  end

  private def _xra(x : Byte)
    @a.value ^= x
    reset_flag(CF|AF)
    set_szp(@a.value)
  end

  private def xra(reg : Byte*)
    _xra(reg.value)
  end

  private def xra_m
    _xra(read_byte(@hl.w))
  end

  private def _ora(x : Byte)
    @a.value |= x
    reset_flag(CF|AF)
    set_szp(@a.value)
  end

  private def ora(reg : Byte*)
    _ora(reg.value)
  end

  private def ora_m
    _ora(read_byte(@hl.w))
  end

  private def _cmp(x : Byte)
    tmp = @a.value
    _sub(x)
    @a.value = tmp
  end

  private def cmp(reg : Byte*)
    _cmp(reg.value)
  end

  private def cmp_m
    _cmp(read_byte(@hl.w))
  end

  private def rlc
    reset_flag(CF)
    @f.value |= @a.value.bit(7)

    @a.value <<= 1
    @a.value |= @f.value.bit(0)
  end

  private def rrc
    reset_flag(CF)
    @f.value |= @a.value.bit(0)

    @a.value >>= 1
    @a.value |= @f.value.bit(0) << 7
  end

  private def ral
    tmp = @f.value.bit(0)

    reset_flag(CF)
    @f.value |= @a.value.bit(7)

    @a.value <<= 1
    @a.value |= tmp
  end

  private def rar
    tmp = @f.value.bit(0)

    reset_flag(CF)
    @f.value |= @a.value.bit(0)

    @a.value >>= 1
    @a.value |= tmp << 7
  end

  private def _push(addr : Word)
    push_word(addr)
  end

  private def push(pair : Pair)
    _push(pair.w)
  end

  private def pop(pair : Pair)
    pair.w = pop_word
  end

  private def dad(pair : Pair)
    if pair.w > Word::MAX - @hl.w
      set_flag(CF)
    else
      reset_flag(CF)
    end

    @hl.w &+= pair.w
  end

  private def inx(pair : Pair)
    pair.w &+= 1
  end

  private def dcx(pair : Pair)
    pair.w &-= 1
  end

  private def xchg
    @hl.w, @de.w = @de.w, @hl.w
  end

  private def xthl
    tmp = @hl.w
    @hl.w = read_word(@sp.w)
    write_word(@sp.w, tmp)
  end

  private def sphl
    @sp.w = @hl.w
  end

  private def lxi(pair : Pair, word : Word)
    pair.w = word
  end

  private def mvi(reg : Byte*, byte : Byte)
    reg.value = byte
  end

  private def mvi_m(byte : Byte)
    write_byte(@hl.w, byte)
  end

  private def adi(byte : Byte)
    _add(byte)
  end

  private def aci(byte : Byte)
    _add(byte + (flag?(CF) ? 1 : 0))
  end

  private def sui(byte : Byte)
    _sub(byte)
  end

  private def sbi(byte : Byte)
    _sub(byte + (flag?(CF) ? 1 : 0))
  end

  private def ani(byte : Byte)
    _ana(byte)
  end

  private def xri(byte : Byte)
    _xra(byte)
  end

  private def ori(byte : Byte)
    _ora(byte)
  end

  private def cpi(byte : Byte)
    _cmp(byte)
  end

  private def sta(addr : Word)
    write_byte(addr, @a.value)
  end

  private def lda(addr : Word)
    @a.value = read_byte(addr)
  end

  private def shld(addr : Word)
    write_word(addr, @hl.w)
  end

  private def lhld(addr : Word)
    @hl.w = read_word(addr)
  end

  private def pchl
    jmp(@hl.w)
  end

  private def jmp(addr : Word)
    @pc.w = addr
    @jumped = true
  end

  private def _jmp_if(flag : Byte, word : Word)
    jmp(word) if flag?(flag)
  end

  private def _jmp_unless(flag : Byte, word : Word)
    jmp(word) unless flag?(flag)
  end

  private def jc(addr : Word)
    _jmp_if(CF, addr)
  end

  private def jnc(addr : Word)
    _jmp_unless(CF, addr)
  end

  private def jz(addr : Word)
    _jmp_if(ZF, addr)
  end

  private def jnz(addr : Word)
    _jmp_unless(ZF, addr)
  end

  private def jp(addr : Word)
    _jmp_unless(SF, addr)
  end

  private def jm(addr : Word)
    _jmp_if(SF, addr)
  end

  private def jpe(addr : Word)
    _jmp_if(PF, addr)
  end

  private def jpo(addr : Word)
    _jmp_unless(PF, addr)
  end

  private def call(addr : Word)
    _push(@pc.w + 1)
    jmp(addr)
  end

  private def _call_if(flag : Byte, addr : Word)
    if flag?(flag)
      call(addr)
      @cycles -= 6
    end
  end

  private def _call_unless(flag : Byte, addr : Word)
    unless flag?(flag)
      call(addr)
      @cycles -= 6
    end
  end

  private def cc(addr : Word)
    _call_if(CF, addr)
  end

  private def cnc(addr : Word)
    _call_unless(CF, addr)
  end

  private def cz(addr : Word)
    _call_if(ZF, addr)
  end

  private def cnz(addr : Word)
    _call_unless(ZF, addr)
  end

  private def cp(addr : Word)
    _call_unless(SF, addr)
  end

  private def cm(addr : Word)
    _call_if(SF, addr)
  end

  private def cpe(addr : Word)
    _call_if(PF, addr)
  end

  private def cpo(addr : Word)
    _call_unless(PF, addr)
  end

  private def ret
    pop(@pc)
    @jumped = true
  end

  private def _ret_if(flag : Byte)
    if flag?(flag)
      ret
      @cycles -= 6
    end
  end

  private def _ret_unless(flag : Byte)
    unless flag?(flag)
      ret
      @cycles -= 6
    end
  end

  private def rc
    _ret_if(CF)
  end

  private def rnc
    _ret_unless(CF)
  end

  private def rz
    _ret_if(ZF)
  end

  private def rnz
    _ret_unless(ZF)
  end

  private def rm
    _ret_if(SF)
  end

  private def rp
    _ret_unless(SF)
  end

  private def rpe
    _ret_if(PF)
  end

  private def rpo
    _ret_unless(PF)
  end

  private def rst(exp : Byte)
    call(I8080.bytes_to_word(exp << 3, 0_u8))
  end

  private def ei
    @int_enable = true
  end

  private def di
    @int_enable = false
  end

  private def in(byte : Byte)
    @a.value = read_io(byte)
  end

  private def out(byte : Byte)
    write_io(byte, @a.value)
  end

  private def hlt
    @stopped = true
  end
end
