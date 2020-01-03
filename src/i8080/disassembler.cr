# Disassembler for Intel 8080 machine code.
#
# Example:
# ```
# dasm = Intel8080::Disassembler.new
# dasm.load_file("path/to/rom")
# dasm.run
# # Output:
# # 0000    LXI    SP, $1234
# # 0001    MVI    A, $56
# # ...
# ```
class I8080::Disassembler
  # The address containing the instruction about to be disassembled.
  property addr : Word

  # The address at which the disassembler should begin execution in the
  # loaded file.
  #
  # Defaults to 0 (address 0x0000). To change this to something else,
  # you can create a new disassembler and specify the origin as a
  # keyword argument:
  # ```
  # dasm = I8080::Disassembler.new(origin: 0x0100_u16)
  # dasm.origin  # => 0x0100_u16
  # ```
  # Or, you can change the origin on an existing disassembler and call
  # the `#reset` method to make sure that the program counter is updated
  # accordingly:
  # ```
  # dasm = I8080::Disassembler.new
  # dasm.origin = 0x0100_u16
  # dasm.reset
  # ```
  property origin : Word

  # The size of the loaded file in bytes.
  getter file_size = 0

  # The disassembler's memory space, used to hold the contents of the
  # loaded file.
  getter memory : Bytes

  # An optional attached `CPU`.
  #
  # If an attached `CPU` exists, that `CPU`'s memory space will be used.
  getter cpu : CPU?

  # If *origin* is given, it will be used as the address at which to
  # start disassembly in the loaded file.
  def initialize(@origin = 0_u16)
    @memory = Bytes.new(0x10000)
    @addr = @origin
  end

  # This constructor can be used to attach the disassembler to an
  # existing `CPU`'s memory space.
  def initialize(@cpu : CPU)
    @memory = @cpu.not_nil!.memory
    @origin = @cpu.not_nil!.origin
    @addr = @origin
  end

  # Resets the address pointer to the origin.
  def reset
    @addr = @origin
  end

  # Loads the contents of *filename* into the disassembler's memory.
  def load_file(filename : String)
    file = File.read(filename).chomp.bytes

    if @origin > 0
      file = [0u8] * @origin + file
    end

    @file_size = file.size
    @memory.copy_from(file.to_unsafe, @file_size)
  end

  private def next_byte : Byte
    @addr &+= 1
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

  private def str_addr : String
    "#%04X" % next_word
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
    when 0x0a
      ["LDAX", "B"]
    when 0x0b
      ["DCX", "B"]
    when 0x0c
      ["INR", "C"]
    when 0x0d
      ["DCR", "C"]
    when 0x0e
      ["MVI", "C", str_byte]
    when 0x0f
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
    when 0x1a
      ["LDAX", "D"]
    when 0x1b
      ["DCX", "D"]
    when 0x1c
      ["INR", "E"]
    when 0x1d
      ["DCR", "E"]
    when 0x1e
      ["MVI", "E", str_byte]
    when 0x1f
      ["RAR"]
    when 0x20
      ["NOP"]
    when 0x21
      ["LXI", "H", str_word]
    when 0x22
      ["SHLD", str_addr]
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
    when 0x2a
      ["LHLD", str_addr]
    when 0x2b
      ["DCX", "H"]
    when 0x2c
      ["INR", "L"]
    when 0x2d
      ["DCR", "L"]
    when 0x2e
      ["MVI", "L", str_byte]
    when 0x2f
      ["CMA"]
    when 0x30
      ["NOP"]
    when 0x31
      ["LXI", "SP", str_word]
    when 0x32
      ["STA", str_addr]
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
    when 0x3a
      ["LDA", str_addr]
    when 0x3b
      ["DCX", "SP"]
    when 0x3c
      ["INR", "A"]
    when 0x3d
      ["DCR", "A"]
    when 0x3e
      ["MVI", "A", str_byte]
    when 0x3f
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
    when 0x4a
      ["MOV", "C", "D"]
    when 0x4b
      ["MOV", "C", "E"]
    when 0x4c
      ["MOV", "C", "H"]
    when 0x4d
      ["MOV", "C", "L"]
    when 0x4e
      ["MOV", "C", "M"]
    when 0x4f
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
    when 0x5a
      ["MOV", "E", "D"]
    when 0x5b
      ["MOV", "E", "E"]
    when 0x5c
      ["MOV", "E", "H"]
    when 0x5d
      ["MOV", "E", "L"]
    when 0x5e
      ["MOV", "E", "M"]
    when 0x5f
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
    when 0x6a
      ["MOV", "L", "D"]
    when 0x6b
      ["MOV", "L", "E"]
    when 0x6c
      ["MOV", "L", "H"]
    when 0x6d
      ["MOV", "L", "L"]
    when 0x6e
      ["MOV", "L", "M"]
    when 0x6f
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
    when 0x7a
      ["MOV", "A", "D"]
    when 0x7b
      ["MOV", "A", "E"]
    when 0x7c
      ["MOV", "A", "H"]
    when 0x7d
      ["MOV", "A", "L"]
    when 0x7e
      ["MOV", "A", "M"]
    when 0x7f
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
    when 0x8a
      ["ADC", "D"]
    when 0x8b
      ["ADC", "E"]
    when 0x8c
      ["ADC", "H"]
    when 0x8d
      ["ADC", "L"]
    when 0x8e
      ["ADC", "M"]
    when 0x8f
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
    when 0x9a
      ["SBB", "D"]
    when 0x9b
      ["SBB", "E"]
    when 0x9c
      ["SBB", "H"]
    when 0x9d
      ["SBB", "L"]
    when 0x9e
      ["SBB", "M"]
    when 0x9f
      ["SBB", "A"]
    when 0xa0
      ["ANA", "B"]
    when 0xa1
      ["ANA", "C"]
    when 0xa2
      ["ANA", "D"]
    when 0xa3
      ["ANA", "E"]
    when 0xa4
      ["ANA", "H"]
    when 0xa5
      ["ANA", "L"]
    when 0xa6
      ["ANA", "M"]
    when 0xa7
      ["ANA", "A"]
    when 0xa8
      ["XRA", "B"]
    when 0xa9
      ["XRA", "C"]
    when 0xaa
      ["XRA", "D"]
    when 0xab
      ["XRA", "E"]
    when 0xac
      ["XRA", "H"]
    when 0xad
      ["XRA", "L"]
    when 0xae
      ["XRA", "M"]
    when 0xaf
      ["XRA", "A"]
    when 0xb0
      ["ORA", "B"]
    when 0xb1
      ["ORA", "C"]
    when 0xb2
      ["ORA", "D"]
    when 0xb3
      ["ORA", "E"]
    when 0xb4
      ["ORA", "H"]
    when 0xb5
      ["ORA", "L"]
    when 0xb6
      ["ORA", "M"]
    when 0xb7
      ["ORA", "A"]
    when 0xb8
      ["CMP", "B"]
    when 0xb9
      ["CMP", "C"]
    when 0xba
      ["CMP", "D"]
    when 0xbb
      ["CMP", "E"]
    when 0xbc
      ["CMP", "H"]
    when 0xbd
      ["CMP", "L"]
    when 0xbe
      ["CMP", "M"]
    when 0xbf
      ["CMP", "A"]
    when 0xc0
      ["RNZ"]
    when 0xc1
      ["POP", "B"]
    when 0xc2
      ["JNZ", str_addr]
    when 0xc3
      ["JMP", str_addr]
    when 0xc4
      ["CNZ", str_addr]
    when 0xc5
      ["PUSH", "B"]
    when 0xc6
      ["ADI", str_byte]
    when 0xc7
      ["RST", "0"]
    when 0xc8
      ["RZ"]
    when 0xc9
      ["RET"]
    when 0xca
      ["JZ", str_addr]
    when 0xcb
      ["NOP"]
    when 0xcc
      ["CZ", str_addr]
    when 0xcd
      ["CALL", str_addr]
    when 0xce
      ["ACI", str_byte]
    when 0xcf
      ["RST"]
    when 0xd0
      ["RNC"]
    when 0xd1
      ["POP", "D"]
    when 0xd2
      ["JNC", str_addr]
    when 0xd3
      ["OUT", str_byte]
    when 0xd4
      ["CNC", str_addr]
    when 0xd5
      ["PUSH", "D"]
    when 0xd6
      ["SUI", str_byte]
    when 0xd7
      ["RST", "2"]
    when 0xd8
      ["RC"]
    when 0xd9
      ["NOP"]
    when 0xda
      ["JC", str_addr]
    when 0xdb
      ["IN", str_byte]
    when 0xdc
      ["CC", str_addr]
    when 0xdd
      ["NOP"]
    when 0xde
      ["SBI", str_byte]
    when 0xdf
      ["RST", "3"]
    when 0xe0
      ["RPO"]
    when 0xe1
      ["POP", "H"]
    when 0xe2
      ["JPO", str_addr]
    when 0xe3
      ["XTHL"]
    when 0xe4
      ["CPO", str_addr]
    when 0xe5
      ["PUSH", "H"]
    when 0xe6
      ["ANI", str_byte]
    when 0xe7
      ["RST", "4"]
    when 0xe8
      ["RPE"]
    when 0xe9
      ["PCHL"]
    when 0xea
      ["JPE", str_addr]
    when 0xeb
      ["XCHG"]
    when 0xec
      ["CPE", str_addr]
    when 0xed
      ["NOP"]
    when 0xee
      ["XRI", str_byte]
    when 0xef
      ["RST", "5"]
    when 0xf0
      ["RP"]
    when 0xf1
      ["POP", "PSW"]
    when 0xf2
      ["JP", str_addr]
    when 0xf3
      ["DI"]
    when 0xf4
      ["CP", str_addr]
    when 0xf5
      ["PUSH", "PSW"]
    when 0xf6
      ["ORI", str_byte]
    when 0xf7
      ["RST", "6"]
    when 0xf8
      ["RM"]
    when 0xf9
      ["SPHL"]
    when 0xfa
      ["JM", str_addr]
    when 0xfb
      ["EI"]
    when 0xfc
      ["CM", str_addr]
    when 0xfd
      ["NOP"]
    when 0xfe
      ["CPI", str_byte]
    when 0xff
      ["RST", "7"]
    else
      Array(String).new
    end
  end

  private def disassemble(x : Byte)
    output = String.build do |out|
      out << "%04X" % @addr

      tmp = strs(x)
      instr = tmp[0]
      args = tmp[1..-1]

      out << "\t"
      out << instr
      out << "\t"
      out << args.join(", ")
    end

    puts output
  end

  # Disassembles the next *n* instructions.
  def step(n = 1)
    n.times do
      disassemble(@memory[@addr])
      @addr &+= 1
    end
  end

  # Disassembles instructions until the end of the file.
  def run
    loop do
      step
      break if @addr == @file_size || @addr == 0
    end
  end
end
