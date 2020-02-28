# A Pair is a simple data structure that has a word along with pointers
# to the low and high bytes of that word. It is intended to represent
# the register pairs that are used by the Intel 8080, with each pointer
# being an individual register and the word being the resulting 16-bit
# value that the two registers form together.
class I8080::Pair
  # The pair's word, formed by the values of `l` and `h`.
  property w : Word

  # Low byte pointer.
  property l : Byte*

  # High byte pointer.
  property h : Byte*

  def initialize(word : Word)
    @w = word
    @l = pointerof(@w).as(Byte*)
    @h = @l + 1

    @l, @h = @h, @l if BIG_ENDIAN
  end

  # *a* is the low byte and *b* is the high byte of the resulting word.
  def initialize(a : Byte, b : Byte)
    @w = uninitialized Word
    @l = pointerof(@w).as(Byte*)
    @h = @l + 1

    @l, @h = @h, @l if BIG_ENDIAN

    @l.value = a
    @h.value = b
  end
end

# lib I8080::C
#   struct BytePair
#     {% if BIG_ENDIAN %}
#       h, l : Byte
#     {% else %}
#       l, h : Byte
#     {% end %}
#   end
#
#   union Pair
#     w : Word
#     b : BytePair
#   end
# end
#
# struct I8080::C::Pair
#   def self.from(lo : Byte, hi : Byte) : self
#     # out = new
#     out = uninitialized self
#
#     out.b.l = lo
#     out.b.h = hi
#
#     return out
#   end
#
#   def self.from(word : Word) : self
#     new(w: word)
#   end
# end
