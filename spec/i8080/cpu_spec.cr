require "spec"
require "../../src/i8080"

include I8080

cpu = CPU.new

macro test(com)
  cpu.reset
  cpu.load_file "#{__DIR__}/roms/{{ com }}.bin"
  cpu.run
end

describe CPU do
  describe "#daa" do
    it "decimal adjust accumulator" do
      test daa
      cpu.a.value.should eq 1
      cpu.flag?(CF|AF).should be_true
    end
  end

  describe "#mov" do
    it "copies the contents of one register to another" do
      test mov
      cpu.read_byte(cpu.hl.w).should eq cpu.a.value
    end
  end

  describe "#stax" do
    it "stores the accumulator's contents in the memory location addressed by the given pair" do
      test stax
      cpu.read_byte(0x3F16).should eq cpu.a.value
    end
  end

  describe "#ldax" do
    it "loads the contents of the given pair into the accumulator" do
      test ldax
      cpu.a.value.should eq cpu.read_byte(0x938B)
    end
  end

  describe "#add" do
    it "adds the given register's contents to the accumulator" do
      test add
      cpu.a.value.should eq 0x9A
      cpu.flag?(PF|SF|AF).should be_true
      cpu.flag?(ZF).should be_false
      cpu.flag?(CF).should be_false
    end
  end

  describe "#adc" do
    it "adds the given register's contents to the accumulator with carry" do
      test adc1
      cpu.a.value.should eq 0x7F
      cpu.flag?(CF).should be_false
      cpu.flag?(SF).should be_false
      cpu.flag?(ZF).should be_false
      cpu.flag?(PF).should be_false
      cpu.flag?(AF).should be_false
      test adc2
      cpu.a.value.should eq 0x80
      cpu.flag?(CF).should be_false
      cpu.flag?(SF).should be_true
      cpu.flag?(ZF).should be_false
      cpu.flag?(PF).should be_false
      cpu.flag?(AF).should be_true
    end
  end

  describe "#sub" do
    it "subtracts the given register's contents from the accumulator" do
      test sub
      cpu.a.value.should eq 0
      cpu.flag?(CF).should be_false
      cpu.flag?(AF|PF|ZF).should be_true
      cpu.flag?(SF).should be_false
    end
  end

  describe "#sbb" do
    it "subtracts the given register's contents from the accumulator with borrow" do
      test sbb
      cpu.a.value.should eq 1
      cpu.flag?(ZF).should be_false
      cpu.flag?(CF).should be_false
      cpu.flag?(AF).should be_true
      cpu.flag?(PF).should be_false
      cpu.flag?(SF).should be_false
    end
  end

  describe "#ana" do
    it "AND's the given register's contents with the accumulator" do
      test ana
      cpu.a.value.should eq 0x0C
    end
  end

  describe "#xra" do
    it "XOR's the given register's contents with the accumulator" do
      test xra
      cpu.a.value.should eq 0
    end
  end

  describe "#ora" do
    it "OR's the given register's contents with the accumulator" do
      test ora
      cpu.a.value.should eq 0x3F
    end
  end

  describe "#cmp" do
    it "compares the given register's contents with the accumulator" do
      test cmp1
      cpu.a.value.should eq 0x0A
      cpu.e.value.should eq 0x05
      cpu.flag?(CF).should be_false
      cpu.flag?(ZF).should be_false
      test cmp2
      cpu.flag?(ZF).should be_false
      cpu.flag?(CF).should be_true
      test cmp3
      cpu.flag?(CF).should be_true
    end
  end

  describe "#rlc" do
    it "rotates the accumulator left by one" do
      test rlc
      cpu.a.value.should eq 0xE5
      cpu.flag?(CF).should be_true
    end
  end

  describe "#rrc" do
    it "rotates the accumulator right by one" do
      test rrc
      cpu.a.value.should eq 0x79
      cpu.flag?(CF).should be_false
    end
  end

  describe "#ral" do
    it "rotates the accumulator left by one with carry" do
      test ral
      cpu.a.value.should eq 0x6A
      cpu.flag?(CF).should be_true
    end
  end

  describe "#rar" do
    it "rotates the accumulator right by one with carry" do
      test rar
      cpu.a.value.should eq 0xB5
      cpu.flag?(CF).should be_false
    end
  end

  describe "#push" do
    it "pushes the contents of the given pair onto the stack" do
      test push
      cpu.read_byte(0x3A2B).should eq cpu.d.value
      cpu.read_byte(0x3A2A).should eq cpu.e.value
      cpu.sp.w.should eq 0x3A2A
    end
  end

  describe "#pop" do
    it "pops the word off of the stack and into the given pair" do
      test pop
      cpu.l.value.should eq 0x3D
      cpu.h.value.should eq 0x93
      cpu.sp.w.should eq 0x123B
    end
  end

  describe "#dad" do
    it "adds the given pair to HL" do
      test dad
      cpu.hl.w.should eq 0xD51A
      cpu.flag?(CF).should be_false
    end
  end

  describe "#inx" do
    it "increments the given pair" do
      test inx
      cpu.d.value.should eq 0x39
      cpu.e.value.should eq 0x00
    end
  end

  describe "#dcx" do
    it "decrements the given pair" do
      test dcx
      cpu.h.value.should eq 0x97
      cpu.l.value.should eq 0xFF
    end
  end

  describe "#xchg" do
    it "swaps the contents of the HL and DE pairs" do
      test xchg
      cpu.hl.w.should eq 0x3355
      cpu.de.w.should eq 0x00FF
    end
  end

  describe "#xthl" do
    it "swaps the contents of (SP) and (SP+1) with the contents of HL" do
      test xthl
      cpu.l.value.should eq 0xF0
      cpu.h.value.should eq 0x0D
      cpu.read_byte(cpu.sp.w).should eq 0x0B
      cpu.read_byte(cpu.sp.w + 1).should eq 0x3C
    end
  end

  describe "#sphl" do
    it "replaces the stack pointer with the contents of HL" do
      test sphl
      cpu.sp.w.should eq 0x506C
    end
  end

  describe "#mvi" do
    it "stores the next byte in the given register" do
      test mvi
      cpu.h.value.should eq 0x3C
      cpu.l.value.should eq 0xF4
      cpu.read_byte(0x3CF4).should eq 0xFF
    end
  end

  describe "#adi" do
    it "adds the next byte to the accumulator" do
      test adi
      cpu.a.value.should eq 0x14
      cpu.flag?(CF|AF|PF).should be_true
      cpu.flag?(ZF).should be_false
      cpu.flag?(SF).should be_false
    end
  end

  describe "#aci" do
    it "adds the next byte to the accumulator with carry" do
      test aci
      cpu.a.value.should eq 0x57
    end
  end

  describe "#sui" do
    it "subtracts the next byte from the accumulator" do
      test sui
      cpu.a.value.should eq 0xFF
      cpu.flag?(CF).should be_true
      cpu.flag?(ZF).should be_false
      cpu.flag?(AF).should be_false
      cpu.flag?(SF|PF).should be_true
    end
  end

  describe "#sbi" do
    it "subtracts the next byte from the accumulator with borrow" do
      test sbi1
      cpu.a.value.should eq 0xFF
      cpu.flag?(CF).should be_true
      cpu.flag?(ZF).should be_false
      cpu.flag?(AF).should be_false
      cpu.flag?(SF|PF).should be_true
      test sbi2
      cpu.a.value.should eq 0xFD
      cpu.flag?(CF|SF).should be_true
      cpu.flag?(ZF).should be_false
      cpu.flag?(PF).should be_false
      cpu.flag?(AF).should be_false
    end
  end

  describe "#ani" do
    it "AND's the next byte with the accumulator" do
      test ani
      cpu.a.value.should eq 0x0A
      cpu.flag?(CF).should be_false
    end
  end

  describe "#xri" do
    it "XOR's the next byte with the accumulator" do
      test xri
      cpu.a.value.should eq 0b10111010
      cpu.flag?(CF).should be_false
    end
  end

  describe "#ori" do
    it "OR's the next byte with the accumulator" do
      test ori
      cpu.a.value.should eq 0xBF
    end
  end

  describe "#cpi" do
    it "compares the next byte with the accumulator" do
      test cpi
      cpu.flag?(CF).should be_false
      cpu.flag?(ZF).should be_falsey
    end
  end

  describe "#sta" do
    it "stores the accumulator's contents at the given address" do
      test sta
      cpu.read_byte(0x05B3).should eq cpu.a.value
    end
  end

  describe "#lda" do
    it "loads the byte at the given address into the accumulator" do
      test lda
      cpu.a.value.should eq cpu.read_byte(0x0300)
    end
  end

  describe "#shld" do
    it "stores L at the given address and H at the next address over" do
      test shld
      cpu.read_byte(0x010A).should eq cpu.l.value
      cpu.read_byte(0x010B).should eq cpu.h.value
    end
  end

  describe "#lhld" do
    it "loads the contents of the given address and the next address over into HL" do
      test lhld
      cpu.l.value.should eq 0xFF
      cpu.h.value.should eq 0x03
    end
  end

  describe "#pchl" do
    it "replaces the program counter with HL" do
      test pchl
      cpu.pc.w.should eq 0x413E
    end
  end

  describe "#jmp" do
    it "replaces the program counter with the given address" do
      test jmp
      cpu.pc.w.should eq 3
    end
  end

  describe "#rst" do
    it "calls a low memory subroutine" do
      test rst
      cpu.pc.w.should eq 0x0024
    end
  end
end
