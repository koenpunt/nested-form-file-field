# Takes a hash of string and file parameters and returns a string of text
# formatted to be sent as a multipart form post.
#
# Author:: Cody Brimhall <mailto:brimhall@somuchwit.com>
# Created:: 22 Feb 2008
# License:: Distributed under the terms of the WTFPL (http://www.wtfpl.net/txt/copying/)
# Modified by Koen Punt to support nested params

require 'rubygems'
require 'mime/types'
require 'cgi'


module Multipart
  VERSION = "1.0.0"

  # Formats a given hash as a multipart form post
  # If a hash value responds to :string or :read messages, then it is
  # interpreted as a file and processed accordingly; otherwise, it is assumed
  # to be a string
  class Post
    # We have to pretend we're a web browser...
    USERAGENT = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/523.10.6 (KHTML, like Gecko) Version/3.0.4 Safari/523.10.6"
    BOUNDARY = "0123456789ABLEWASIEREISAWELBA9876543210"
    CONTENT_TYPE = "multipart/form-data; boundary=#{ BOUNDARY }"
    HEADER = { "Content-Type" => CONTENT_TYPE, "User-Agent" => USERAGENT }

    def self.build_name(key, prefix = nil)
      key = CGI::escape(key.to_s)
      return key if prefix.nil?

      "#{prefix}[#{key}]"
    end

    def self.parse_params(params, prefix = nil)
      parsed = []
      params.each do |k, v|
        # Are we trying to make a file parameter?
        if v.is_a?(Hash)
          parsed.concat parse_params(v, build_name(k, prefix))
        elsif v.respond_to?(:path) and v.respond_to?(:read) then
          parsed << FileParam.new(build_name(k, prefix), v.path, v.read)
        # We must be trying to make a regular parameter
        else
          parsed << StringParam.new(build_name(k, prefix), v)
        end
      end
      parsed
    end

    def self.prepare_query(params)
      parts = parse_params(params)

      # Assemble the request body using the special multipart format
      query = parts.collect { |p| "--" + BOUNDARY + "\r\n" + p.to_multipart }.join("") + "--" + BOUNDARY + "--"

      [query, HEADER]
    end
  end

  private

  # Formats a basic string key/value pair for inclusion with a multipart post
  class StringParam
    attr_accessor :k, :v

    def initialize(k, v)
      @k = k
      @v = v
    end

    def to_multipart
      "Content-Disposition: form-data; name=\"#{k}\"\r\n\r\n#{v}\r\n"
    end
  end

  # Formats the contents of a file or string for inclusion with a multipart
  # form post
  class FileParam
    attr_accessor :k, :filename, :content

    def v
      "FileParam"
    end

    def initialize(k, filename, content)
      @k = k
      @filename = filename
      @content = content
    end

    def to_multipart
      # If we can tell the possible mime-type from the filename, use the
      # first in the list; otherwise, use "application/octet-stream"
      mime_type = MIME::Types.type_for(filename)[0] || MIME::Types["application/octet-stream"][0]
      "Content-Disposition: form-data; name=\"#{k}\"; filename=\"#{ filename }\"\r\n" +
             "Content-Type: #{ mime_type.simplified }\r\n\r\n#{ content }\r\n"
    end
  end
end
