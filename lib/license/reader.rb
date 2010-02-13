require 'rubygems'
require 'openssl'
require 'digest/sha2'
require 'fastercsv'

class LicenseException < RuntimeError; end

class LicenseSeatsExceededException < LicenseException; end


class License::Reader
  attr_reader :rhosync_version, :licensee, :seats, :issued
  attr_accessor :license

  # ships with rhosync
  RHO_PUBLICKEY = "99068e3a2708e6fe918252be8880eac539a1d2b2402651d75de5c7a2333a1cb2"

  def initialize(license=nil)
    if license
      @license = license
      decrypt
    else
      raise RuntimeError, "Please specify license text: LicenseReader.new('842149604e61784051300318a24c5bfc799be43260e198b01e1ab183d694bf8561823ce777f3f7e176efb38dd2549335485927a6936b60febeac5952883e6308')"
    end
  end

  private

  def decrypt
    cipher = OpenSSL::Cipher::Cipher.new("aes-256-ecb")
    cipher.key = extract_str(RHO_PUBLICKEY)
    cipher.decrypt

    decrypted = cipher.update(extract_str(@license))
    decrypted << cipher.final
    parts = decrypted.parse_csv
    @rhosync_version = parts[0].strip
    @licensee = parts[1].strip
    @seats = parts[2].strip.to_i
    @issued = parts[3].strip
  end

  def extract_str(str)
    str.gsub(/(..)/){|h| h.hex.chr}
  end
end
