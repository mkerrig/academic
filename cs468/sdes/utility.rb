module SDES
  module Utility
  
    def self.decimal_to_binary(x, padding = 0)
      binary = x.to_i.to_s(2)
      (padding > 0) ? (binary.rjust(padding, "0")) : binary
    end

    def self.binary_to_decimal(x)
      x.to_i(2)
    end

    def self.rotate_left(x, shift, max_size = 8)
      max_value = 2**max_size -1
      ((x<<shift) | (x >> (max_size -shift))) & max_value
    end

    def self.rotate_right(x, shift, max_size = 7)
      shift &= max_size
      max_value = (2 ** (max_size +1)) -1
      ((x << (max_size +1 -shift)) | (x>>shift)) & max_value
    end

    # Review this, ensure that it "rotates" the output
    # No tests written for this yet.
    def self.fk(bits,sk)
      left, right = bits[0..3], bits[4..7]
      mangled = (left.base10 ^ f(right,sk).base10).bits(4)
      mangled + right
    end

    # [48, 48, 49, 48, 49] => ['0', '0', '1', '0', '1'] => '00101'
    def self.f(bits, subkey)
      e = expand(SDES::EP, bits).base10
      r = (e ^ subkey.base10).bits
      r1 = r[0..3]
      r2 = r[4..7]
  
      s0 = select_from(SDES::S0, r1).to_i.bits(2)
      s1 = select_from(SDES::S1, r2).to_i.bits(2)
      pr = (s0+s1).base10.bits(4)
  
      permute(P4,pr)
    end

    # input: a string of ascii characters
    # output: a binary number as a string
    def self.encrypt(input, key)
      k1, k2 = SDES::Key.subkey(key)
      a = input.each_char.map do |c|
        bits = c[0].bits # convert to integer to bits
        ip = permute(Initial, bits)
        m1 = fk(ip, k1)
        m2 = fk(flip(m1), k2)
        fp = permute(Final, m2)
        fp
      end
  
      a.join
    end

    # input: a string of ascii characters
    # output: a binary number as a string
    def self.decrypt(input, key)
      k1, k2 = SDES::Key.subkey(key)
      a = input.scan(/[01]{8}/).map do |byte|
        fp = permute(Initial, byte)
        m2 = fk(fp, k2)
        m1 = fk(flip(m2), k1)
        ip = permute(Final, m1)
        ip.base10.chr
      end
  
      a.join
    end

    def self.select_from(map, bits)
      row = (bits[0].chr + bits[3].chr).base10
      col = (bits[1].chr + bits[2].chr).base10
      map[row*4+col]
    end
  
    def self.flip(a)
      permute(SDES::Flip, a)
    end
 
    def self.permute(mapping, values)
      mapping.collect { |index| values[index.to_i - 1] }.as_str
    end

    def self.expand(mapping, values)
      mapping.collect { |index| values[index.to_i - 1] }.as_str
    end

    def self.substitute(input, mapping, size=4, &block)
      row = SDES::Utility.binary_to_decimal(input[0].chr + input[3].chr).to_i
      col = SDES::Utility.binary_to_decimal(input[1].chr + input[2].chr).to_i
      if block_given?
        yield(row,col)
      else
        mapping[(row*size + col).to_i].to_i
      end
    end

  end
end