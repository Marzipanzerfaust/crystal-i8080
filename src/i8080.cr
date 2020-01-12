require "./i8080/*"

module I8080
  VERSION = "0.1.2"

  # For the Intel 8080, bytes are unsigned 8-bit integers.
  alias Byte = UInt8

  # For the Intel 8080, words are unsigned 16-bit integers (two bytes).
  alias Word = UInt16

  # :nodoc:
  #
  # Is the local system big-endian?
  BIG_ENDIAN = self.big_endian?

  private def self.big_endian?
    word = 0x1234_u16
    ptr = pointerof(word).unsafe_as(Pointer(Byte))

    return ptr.value == 0x12
  end

  # Carry Flag
  CF = 1_u8 << 0
  # Parity Flag
  PF = 1_u8 << 2
  # Auxiliary Carry Flag
  AF = 1_u8 << 4
  # Zero Flag
  ZF = 1_u8 << 6
  # Sign Flag
  SF = 1_u8 << 7

  # Instruction cycle counts
  #
  # NOTE: Some instructions add additional cycles under certain
  # conditions.
  OP_CYCLES = [
    4, 10,  7,  5,  5,  5,  7,  7,  4,  4, 10,  7,  5,  5,  7,  4,
    4, 10,  7,  5,  5,  5,  7,  7,  4,  4, 10,  7,  5,  5,  7,  4,
    4, 10, 16,  5,  5,  5,  7,  4,  4, 10, 16,  5,  5,  5,  7,  4,
    4, 10, 13,  5,  5,  5,  7,  4,  4, 10, 13,  5,  5,  5, 10,  4,
    5,  5,  5,  5,  5,  5,  7,  5,  5,  5,  5,  5,  5,  5,  7,  5,
    5,  5,  5,  5,  5,  5,  7,  5,  5,  5,  5,  5,  5,  5,  7,  5,
    5,  5,  5,  5,  5,  5,  7,  5,  5,  5,  5,  5,  5,  5,  7,  5,
    7,  7,  7,  7,  7,  7,  7,  7,  5,  5,  5,  5,  5,  5,  7,  5,
    4,  4,  4,  4,  4,  4,  7,  4,  4,  4,  4,  4,  4,  4,  7,  4,
    4,  4,  4,  4,  4,  4,  7,  4,  4,  4,  4,  4,  4,  4,  7,  4,
    4,  4,  4,  4,  4,  4,  7,  4,  4,  4,  4,  4,  4,  4,  7,  4,
    4,  4,  4,  4,  4,  4,  7,  4,  4,  4,  4,  4,  4,  4,  7,  4,
    5, 10, 10, 10, 11, 11,  7, 11,  5, 10, 10, 10, 11, 17,  7, 11,
    5, 10, 10, 10, 11, 11,  7, 11,  5, 10, 10, 10, 11, 17,  7, 11,
    5, 10, 10, 18, 11, 11,  7, 11,  5,  5, 10,  5, 11, 17,  7, 11,
    5, 10, 10,  4, 11, 11,  7, 11,  5,  5, 10,  4, 11, 17,  7, 11
  ]

  # Returns a word formed out of two given bytes. *a* is the low byte
  # and *b* is the high byte of the resulting word.
  def self.bytes_to_word(a : Byte, b : Byte) : Word
    word = uninitialized Word
    lo = pointerof(word).as(Byte*)
    hi = lo + 1

    lo, hi = hi, lo if BIG_ENDIAN

    lo.value = a
    hi.value = b

    return word
  end

  # Returns the two bytes that form a given word. The low byte will come
  # first, followed by the high byte.
  def self.word_to_bytes(word : Word) : Tuple(Byte, Byte)
    lo = pointerof(word).as(Byte*)
    hi = lo + 1

    lo, hi = hi, lo if BIG_ENDIAN

    return {lo.value, hi.value}
  end
end
