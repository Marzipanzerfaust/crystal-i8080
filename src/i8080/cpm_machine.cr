require "./cpu"

# A modified `CPU` that provides limited support for 8-bit CP/M system
# calls. This is not a proper CP/M emulator, obviously, but it should
# allow for testing simple CP/M programs, such as Intel 8080 diagnostics.
#
# The supported BDOS calls are:
# * 0x00 - P_TERMCPM
# * 0x01 - C_READ
# * 0x02 - C_WRITE
# * 0x03 - A_READ (aliased to C_READ)
# * 0x04 - A_WRITE (aliased to C_WRITE)
# * 0x05 - L_WRITE (aliased to C_WRITE)
# * 0x09 - C_WRITESTR
# * 0x0A - C_READSTR
# * 0x0C - [lift head]
# * 0x6E - C_DELIMIT
# * 0x6F - C_WRITEBLK
# * 0x70 - L_WRITEBLK
# * 0x8F - P_TERM
# * 0xD3 - [print decimal number]
#
# Any calls not listed above will raise an exception.
#
# Since this is designed to run CP/M programs, its origin address
# defaults to 0x0100 instead of 0x0000.
#
# Thanks to John Elliott at [seasip.info](http://seasip.info/index.html)
# for providing a [very helpful page](http://seasip.info/Cpm/bdos.html)
# that describes all of the BDOS calls in CP/M.
class I8080::CPMMachine < I8080::CPU
  @str_delimiter = '$'

  # :nodoc:
  def initialize(*args, **kwargs)
    super(*args, **kwargs, origin: 0x0100_u16)
  end

  private def call(addr : Word)
    case addr
    when 0x0000, 0x0005  # WBOOT, BDOS
      jmp(addr)
    else super(addr)
    end
  end

  private def jmp(addr : Word)
    case addr
    when 0x0000 then wboot
    when 0x0005 then bdos
    else super(addr)
    end
  end

  # In a CP/M program, this would exit and return to the CCP. A suitable
  # replacement is to halt execution and reset the CPU.
  private def wboot
    reset
  end

  private def bdos
    case @c.value
    when 0x00 then p_termcpm
    when 0x01 then c_read
    when 0x02 then c_write
    when 0x03 then a_read
    when 0x04 then a_write
    when 0x05 then l_write
    when 0x09 then c_writestr
    when 0x0A then c_readstr
    when 0x0C then lift_head
    when 0x6E then c_delimit
    when 0x6F then c_writeblk
    when 0x70 then l_writeblk
    when 0x8F then p_term
    when 0xD3 then print_decimal
    else
      raise "Unimplemented BDOS call 0x%02X at address 0x%04X" % {@c.value, @pc.w - 2}
    end
  end

  # BDOS calls

  # System reset
  #
  # Equivalent to WBOOT.
  private def p_termcpm
    wboot
  end

  # Console input
  #
  # Reads a character from STDIN and stores it in the A and L registers.
  # A string of any length can be entered, but only the first character
  # of the string is accepted.
  private def c_read
    print "(C_READ): "
    @a.value = @l.value = gets.not_nil![0].ord.unsafe_as(Byte)
  end

  # Console output
  #
  # Prints the character in E to STDOUT.
  private def c_write
    print @e.value.chr
  end

  # Auxiliary (Reader) input
  #
  # Since there is no auxiliary input on modern systems, this is
  # equivalent to C_READ.
  private def a_read
    print "(A_READ): "
    @a.value = @l.value = gets.not_nil![0].ord.unsafe_as(Byte)
  end

  # Auxiliary (Punch) output
  #
  # Since there is no auxiliary output on modern systems, this is
  # equivalent to C_WRITE.
  private def a_write
    c_write
  end

  # Printer output
  #
  # Aliased to C_WRITE.
  private def l_write
    c_write
  end

  # Output string
  #
  # Prints characters starting at the address in DE and terminated by
  # the first encountered `str_delimiter`. Prints a newline when it's
  # done.
  private def c_writestr
    i = @de.w

    until (char = read_byte(i).chr) == @str_delimiter
      print char
      i += 1
    end

    puts
  end

  # Buffered console input
  #
  #
  private def c_readstr
    print "(C_READSTR): "

    size = read_byte(@de.w)
    buffer = gets(size)

    write_bytes(@de.w + 1, buffer.to_slice) if buffer
  end

  # Lift head
  #
  # This resets HL to 0, nothing more.
  private def lift_head
    @hl.w = 0
  end

  # Get/set string delimiter
  #
  # If DE = 0xFFFF, stores the current delimiter into A; else, sets the
  # delimiter to the character stored in E.
  private def c_delimit
    if @de.w == 0xFFFF
      @a.value = @str_delimiter.ord.unsafe_as(Byte)
    else
      @str_delimiter = @e.value.chr
    end
  end

  # Send block of text to console
  #
  # Writes the block of text beginning at the address stored in DE to
  # STDOUT. The word at DE is the first word of the block and the second
  # word is the number of bytes to print afterwards.
  #
  # Prints a newline at the end.
  private def c_writeblk
    print read_byte(@de.w).chr
    print read_byte(@de.w + 1).chr

    length = read_word(@de.w + 2)
    i = @de.w + 3

    (i..i+length).each { |x| print read_byte(x).chr }

    puts
  end

  # Send block of text to printer
  #
  # Aliased to c_writeblk.
  private def l_writeblk
    c_writeblk
  end

  # Terminate process
  #
  # Same as P_TERMCPM.
  private def p_term
    p_termcpm
  end

  # Print decimal number
  #
  # Prints the word stored in DE as a decimal number to STDOUT.
  private def print_decimal
    print @de.w
  end
end
