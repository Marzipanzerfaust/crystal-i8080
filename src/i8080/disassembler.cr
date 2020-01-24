# Disassembler for Intel 8080 machine code.
#
# Example:
# ```
# dasm = Intel8080::Disassembler.new
# dasm.load_file("path/to/rom")
# dasm.run
# # Output:
# # 0000: 31 34 12    LXI    SP,$1234
# # 0003: 3E 56       MVI    A,$56
# # ...
# ```
class I8080::Disassembler
  # The address containing the instruction about to be disassembled.
  property addr : Word

  # The size of the loaded file in bytes.
  getter file_size = 0

  # The disassembler's memory space, used to hold the contents of the
  # loaded file.
  getter memory : Bytes

  # An optional attached `CPU`.
  #
  # If an attached `CPU` exists, that `CPU`'s memory space will be used.
  getter cpu : CPU?

  def initialize
    @memory = Bytes.new(0x10000)
    @addr = 0
  end

  # This constructor can be used to attach the disassembler to an
  # existing `CPU`'s memory space.
  def initialize(@cpu : CPU)
    @memory = @cpu.not_nil!.memory
    @addr = @cpu.not_nil!.pc.w
  end

  # Resets the address pointer to the origin.
  def reset : Nil
    @addr = 0
  end

  # Loads the contents of *filename* into the disassembler's memory,
  # then returns the file's size in bytes.
  def load_file(filename : String) : Int32
    data = File.read(filename).chomp.to_slice
    @file_size = data.size

    @memory.copy_from(data)

    return @file_size
  end

  private def next_byte : Byte
    @addr += 1
    return @memory[@addr]
  end

  private def next_word : Word
    I8080.bytes_to_word(next_byte, next_byte)
  end

  private def str_byte : String
    "$%02X" % next_byte
  end

  private def str_word : String
    "$%04X" % next_word
  end

  private def strs(x : Byte) : Array(String)
    case x
    when 0x00
      ["NOP"]
    when 0x01
      ["LXI", "B", str_word]
    when 0x02
      ["STAX", "B"]
    when 0x03
      ["INX", "B"]
    when 0x04
      ["INR", "B"]
    when 0x05
      ["DCR", "B"]
    when 0x06
      ["MVI", "B", str_byte]
    when 0x07
      ["RLC"]
    when 0x08
      ["NOP"]
    when 0x09
      ["DAD", "B"]
    when 0x0A
      ["LDAX", "B"]
    when 0x0B
      ["DCX", "B"]
    when 0x0C
      ["INR", "C"]
    when 0x0D
      ["DCR", "C"]
    when 0x0E
      ["MVI", "C", str_byte]
    when 0x0F
      ["RRC"]
    when 0x10
      ["NOP"]
    when 0x11
      ["LXI", "D", str_word]
    when 0x12
      ["STAX", "D"]
    when 0x13
      ["INX", "D"]
    when 0x14
      ["INR", "D"]
    when 0x15
      ["DCR", "D"]
    when 0x16
      ["MVI", "D", str_byte]
    when 0x17
      ["RAL"]
    when 0x18
      ["NOP"]
    when 0x19
      ["DAD", "D"]
    when 0x1A
      ["LDAX", "D"]
    when 0x1B
      ["DCX", "D"]
    when 0x1C
      ["INR", "E"]
    when 0x1D
      ["DCR", "E"]
    when 0x1E
      ["MVI", "E", str_byte]
    when 0x1F
      ["RAR"]
    when 0x20
      ["NOP"]
    when 0x21
      ["LXI", "H", str_word]
    when 0x22
      ["SHLD", str_word]
    when 0x23
      ["INX", "H"]
    when 0x24
      ["INR", "H"]
    when 0x25
      ["DCR", "H"]
    when 0x26
      ["MVI", "H", str_byte]
    when 0x27
      ["DAA"]
    when 0x28
      ["NOP"]
    when 0x29
      ["DAD", "H"]
    when 0x2A
      ["LHLD", str_word]
    when 0x2B
      ["DCX", "H"]
    when 0x2C
      ["INR", "L"]
    when 0x2D
      ["DCR", "L"]
    when 0x2E
      ["MVI", "L", str_byte]
    when 0x2F
      ["CMA"]
    when 0x30
      ["NOP"]
    when 0x31
      ["LXI", "SP", str_word]
    when 0x32
      ["STA", str_word]
    when 0x33
      ["INX", "SP"]
    when 0x34
      ["INR", "M"]
    when 0x35
      ["DCR", "M"]
    when 0x36
      ["MVI", "M", str_byte]
    when 0x37
      ["STC"]
    when 0x38
      ["NOP"]
    when 0x39
      ["DAD", "SP"]
    when 0x3A
      ["LDA", str_word]
    when 0x3B
      ["DCX", "SP"]
    when 0x3C
      ["INR", "A"]
    when 0x3D
      ["DCR", "A"]
    when 0x3E
      ["MVI", "A", str_byte]
    when 0x3F
      ["CMC"]
    when 0x40
      ["MOV", "B", "B"]
    when 0x41
      ["MOV", "B", "C"]
    when 0x42
      ["MOV", "B", "D"]
    when 0x43
      ["MOV", "B", "E"]
    when 0x44
      ["MOV", "B", "H"]
    when 0x45
      ["MOV", "B", "L"]
    when 0x46
      ["MOV", "B", "M"]
    when 0x47
      ["MOV", "B", "A"]
    when 0x48
      ["MOV", "C", "B"]
    when 0x49
      ["MOV", "C", "C"]
    when 0x4A
      ["MOV", "C", "D"]
    when 0x4B
      ["MOV", "C", "E"]
    when 0x4C
      ["MOV", "C", "H"]
    when 0x4D
      ["MOV", "C", "L"]
    when 0x4E
      ["MOV", "C", "M"]
    when 0x4F
      ["MOV", "C", "A"]
    when 0x50
      ["MOV", "D", "B"]
    when 0x51
      ["MOV", "D", "C"]
    when 0x52
      ["MOV", "D", "D"]
    when 0x53
      ["MOV", "D", "E"]
    when 0x54
      ["MOV", "D", "H"]
    when 0x55
      ["MOV", "D", "L"]
    when 0x56
      ["MOV", "D", "M"]
    when 0x57
      ["MOV", "D", "A"]
    when 0x58
      ["MOV", "E", "B"]
    when 0x59
      ["MOV", "E", "C"]
    when 0x5A
      ["MOV", "E", "D"]
    when 0x5B
      ["MOV", "E", "E"]
    when 0x5C
      ["MOV", "E", "H"]
    when 0x5D
      ["MOV", "E", "L"]
    when 0x5E
      ["MOV", "E", "M"]
    when 0x5F
      ["MOV", "E", "A"]
    when 0x60
      ["MOV", "H", "B"]
    when 0x61
      ["MOV", "H", "C"]
    when 0x62
      ["MOV", "H", "D"]
    when 0x63
      ["MOV", "H", "E"]
    when 0x64
      ["MOV", "H", "H"]
    when 0x65
      ["MOV", "H", "L"]
    when 0x66
      ["MOV", "H", "M"]
    when 0x67
      ["MOV", "H", "A"]
    when 0x68
      ["MOV", "L", "B"]
    when 0x69
      ["MOV", "L", "C"]
    when 0x6A
      ["MOV", "L", "D"]
    when 0x6B
      ["MOV", "L", "E"]
    when 0x6C
      ["MOV", "L", "H"]
    when 0x6D
      ["MOV", "L", "L"]
    when 0x6E
      ["MOV", "L", "M"]
    when 0x6F
      ["MOV", "L", "A"]
    when 0x70
      ["MOV", "M", "B"]
    when 0x71
      ["MOV", "M", "C"]
    when 0x72
      ["MOV", "M", "D"]
    when 0x73
      ["MOV", "M", "E"]
    when 0x74
      ["MOV", "M", "H"]
    when 0x75
      ["MOV", "M", "L"]
    when 0x76
      ["HLT"]
    when 0x77
      ["MOV", "M", "A"]
    when 0x78
      ["MOV", "A", "B"]
    when 0x79
      ["MOV", "A", "C"]
    when 0x7A
      ["MOV", "A", "D"]
    when 0x7B
      ["MOV", "A", "E"]
    when 0x7C
      ["MOV", "A", "H"]
    when 0x7D
      ["MOV", "A", "L"]
    when 0x7E
      ["MOV", "A", "M"]
    when 0x7F
      ["MOV", "A", "A"]
    when 0x80
      ["ADD", "B"]
    when 0x81
      ["ADD", "C"]
    when 0x82
      ["ADD", "D"]
    when 0x83
      ["ADD", "E"]
    when 0x84
      ["ADD", "H"]
    when 0x85
      ["ADD", "L"]
    when 0x86
      ["ADD", "M"]
    when 0x87
      ["ADD", "A"]
    when 0x88
      ["ADC", "B"]
    when 0x89
      ["ADC", "C"]
    when 0x8A
      ["ADC", "D"]
    when 0x8B
      ["ADC", "E"]
    when 0x8C
      ["ADC", "H"]
    when 0x8D
      ["ADC", "L"]
    when 0x8E
      ["ADC", "M"]
    when 0x8F
      ["ADC", "A"]
    when 0x90
      ["SUB", "B"]
    when 0x91
      ["SUB", "C"]
    when 0x92
      ["SUB", "D"]
    when 0x93
      ["SUB", "E"]
    when 0x94
      ["SUB", "H"]
    when 0x95
      ["SUB", "L"]
    when 0x96
      ["SUB", "M"]
    when 0x97
      ["SUB", "A"]
    when 0x98
      ["SBB", "B"]
    when 0x99
      ["SBB", "C"]
    when 0x9A
      ["SBB", "D"]
    when 0x9B
      ["SBB", "E"]
    when 0x9C
      ["SBB", "H"]
    when 0x9D
      ["SBB", "L"]
    when 0x9E
      ["SBB", "M"]
    when 0x9F
      ["SBB", "A"]
    when 0xA0
      ["ANA", "B"]
    when 0xA1
      ["ANA", "C"]
    when 0xA2
      ["ANA", "D"]
    when 0xA3
      ["ANA", "E"]
    when 0xA4
      ["ANA", "H"]
    when 0xA5
      ["ANA", "L"]
    when 0xA6
      ["ANA", "M"]
    when 0xA7
      ["ANA", "A"]
    when 0xA8
      ["XRA", "B"]
    when 0xA9
      ["XRA", "C"]
    when 0xAA
      ["XRA", "D"]
    when 0xAB
      ["XRA", "E"]
    when 0xAC
      ["XRA", "H"]
    when 0xAD
      ["XRA", "L"]
    when 0xAE
      ["XRA", "M"]
    when 0xAF
      ["XRA", "A"]
    when 0xB0
      ["ORA", "B"]
    when 0xB1
      ["ORA", "C"]
    when 0xB2
      ["ORA", "D"]
    when 0xB3
      ["ORA", "E"]
    when 0xB4
      ["ORA", "H"]
    when 0xB5
      ["ORA", "L"]
    when 0xB6
      ["ORA", "M"]
    when 0xB7
      ["ORA", "A"]
    when 0xB8
      ["CMP", "B"]
    when 0xB9
      ["CMP", "C"]
    when 0xBA
      ["CMP", "D"]
    when 0xBB
      ["CMP", "E"]
    when 0xBC
      ["CMP", "H"]
    when 0xBD
      ["CMP", "L"]
    when 0xBE
      ["CMP", "M"]
    when 0xBF
      ["CMP", "A"]
    when 0xC0
      ["RNZ"]
    when 0xC1
      ["POP", "B"]
    when 0xC2
      ["JNZ", str_word]
    when 0xC3
      ["JMP", str_word]
    when 0xC4
      ["CNZ", str_word]
    when 0xC5
      ["PUSH", "B"]
    when 0xC6
      ["ADI", str_byte]
    when 0xC7
      ["RST", "0"]
    when 0xC8
      ["RZ"]
    when 0xC9
      ["RET"]
    when 0xCA
      ["JZ", str_word]
    when 0xCB
      ["NOP"]
    when 0xCC
      ["CZ", str_word]
    when 0xCD
      ["CALL", str_word]
    when 0xCE
      ["ACI", str_byte]
    when 0xCF
      ["RST"]
    when 0xD0
      ["RNC"]
    when 0xD1
      ["POP", "D"]
    when 0xD2
      ["JNC", str_word]
    when 0xD3
      ["OUT", str_byte]
    when 0xD4
      ["CNC", str_word]
    when 0xD5
      ["PUSH", "D"]
    when 0xD6
      ["SUI", str_byte]
    when 0xD7
      ["RST", "2"]
    when 0xD8
      ["RC"]
    when 0xD9
      ["NOP"]
    when 0xDA
      ["JC", str_word]
    when 0xDB
      ["IN", str_byte]
    when 0xDC
      ["CC", str_word]
    when 0xDD
      ["NOP"]
    when 0xDE
      ["SBI", str_byte]
    when 0xDF
      ["RST", "3"]
    when 0xE0
      ["RPO"]
    when 0xE1
      ["POP", "H"]
    when 0xE2
      ["JPO", str_word]
    when 0xE3
      ["XTHL"]
    when 0xE4
      ["CPO", str_word]
    when 0xE5
      ["PUSH", "H"]
    when 0xE6
      ["ANI", str_byte]
    when 0xE7
      ["RST", "4"]
    when 0xE8
      ["RPE"]
    when 0xE9
      ["PCHL"]
    when 0xEA
      ["JPE", str_word]
    when 0xEB
      ["XCHG"]
    when 0xEC
      ["CPE", str_word]
    when 0xED
      ["NOP"]
    when 0xEE
      ["XRI", str_byte]
    when 0xEF
      ["RST", "5"]
    when 0xF0
      ["RP"]
    when 0xF1
      ["POP", "PSW"]
    when 0xF2
      ["JP", str_word]
    when 0xF3
      ["DI"]
    when 0xF4
      ["CP", str_word]
    when 0xF5
      ["PUSH", "PSW"]
    when 0xF6
      ["ORI", str_byte]
    when 0xF7
      ["RST", "6"]
    when 0xF8
      ["RM"]
    when 0xF9
      ["SPHL"]
    when 0xFA
      ["JM", str_word]
    when 0xFB
      ["EI"]
    when 0xFC
      ["CM", str_word]
    when 0xFD
      ["NOP"]
    when 0xFE
      ["CPI", str_byte]
    when 0xFF
      ["RST", "7"]
    else
      [] of String
    end
  end

  private def disassemble(x : Byte)
    start = @addr

    tmp = strs(x)
    instr = tmp[0]
    args = tmp[1..-1]

    offset = @addr - start

    start_hex = "%04X" % start
    instr_hex = "%02X" % @memory[start]
    args_hex = @memory[start+1, offset].map { |x| "%02X" % x }.join(' ')

    extra_cycles =
      if cpu = @cpu
        case x
        when 0xC0, 0xC4
          cpu.flag?(ZF) ? 0 : 6
        when 0xC8, 0xCC
          cpu.flag?(ZF) ? 6 : 0
        when 0xD0, 0xD4
          cpu.flag?(CF) ? 0 : 6
        when 0xD8, 0xDC
          cpu.flag?(CF) ? 6 : 0
        when 0xE0, 0xE4
          cpu.flag?(PF) ? 0 : 6
        when 0xE8, 0xEC
          cpu.flag?(PF) ? 6 : 0
        when 0xF0, 0xF4
          cpu.flag?(SF) ? 0 : 6
        when 0xF8, 0xFC
          cpu.flag?(SF) ? 6 : 0
        else
          0
        end
      else
        0
      end

    output = String.build do |str|
      str << start_hex
      str << ": "
      str << instr_hex << ' ' << args_hex.ljust(5, ' ')
      str << "    "
      str << instr.ljust(4, ' ')
      str << "    "
      str << args.join(',').ljust(8)

      @cpu.try do |cpu|
        str << "    ; cycles = "
        str << cpu.cycles
        str << " - "
        str << OP_CYCLES[x] + extra_cycles
      end
    end

    puts output
  end

  # Disassembles the next *n* instructions.
  def step(n = 1) : Nil
    n.times do
      disassemble(@memory[@addr])
      @addr += 1
    end
  end

  # Disassembles instructions until the end of the file.
  def run : Nil
    loop do
      step
      break if @addr == @file_size || @addr == 0
    end
  end
end
