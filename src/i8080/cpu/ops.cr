class I8080::CPU
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

    # update_timers(OP_CYCLES[code])
    @cycles -= OP_CYCLES[code]
  end

  # private def update_timers(cycles : Int) : Nil
  #   @refresh_timer -= cycles
  #
  #   @tasks.each.with_index do |task, i|
  #     @timers[i] -= cycles
  #
  #     if @timers[i] <= 0
  #       @timers[i] += @periods[i]
  #       task.call
  #     end
  #   end
  # end

  # Instructions:

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
      # update_timers(6)
      @cycles -= 6
    end
  end

  private def _call_unless(flag : Byte, addr : Word)
    unless flag?(flag)
      call(addr)
      # update_timers(6)
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
      # update_timers(6)
      @cycles -= 6
    end
  end

  private def _ret_unless(flag : Byte)
    unless flag?(flag)
      ret
      # update_timers(6)
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
    call(I8080.bytes_to_word(exp << 3, 0))
  end

  private def ei
    @int_enabled = true
  end

  private def di
    @int_enabled = false
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
