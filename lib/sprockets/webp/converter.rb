# encoding: utf-8

require 'tempfile'
require 'logger'
require 'fileutils'
require 'webp-ffi'

module Sprockets
  module WebP
    class Converter
      class << self

        attr_reader :context

        def process(app, context, data)
          @context = context
          # Application Config alias
          config = app.config.assets

          # If Application Assets Digests enabled - Add Digest
          digest    = config.digest ? "-#{context.environment.digest.update(data).hexdigest}" : nil
          file_name = context.logical_path # Original File name w/o extension
          file_ext  = context.pathname.extname # Original File extension
          webp_file = "#{file_name}#{digest}#{file_ext}.webp" # WebP File fullname

          # WebP File Pathname
          webp_path = Pathname.new File.join(app.root, 'public', config.prefix, webp_file)

          # Create Directory for both Files, unless already exists
          FileUtils.mkdir_p(webp_path.dirname) unless Dir.exists?(webp_path.dirname)

          # encode to webp
          encode_to_webp(data, webp_path.to_path, webp_file)

          data
        end

        private

        def encode_to_webp(data, webp_path, webp_file = "")
          # Create Temp File with Original File binary data
          Tempfile.open('webp') do |file|
            file.binmode
            file.write(data)
            file.close

            # Encode Original File Temp copy to WebP File Pathname
            begin
              ::WebP.encode(file.path, webp_path, Sprockets::WebP.encode_options)
            rescue => e
              logger.warn "Webp convertion error of image #{webp_file}. Error info: #{e.message}"
            end
          end
        end

        def logger
          if @context && @context.environment
            @context.environment.logger
          else
            logger = Logger.new($stderr)
            logger.level = Logger::FATAL
            logger
          end
        end

      end
    end
  end
end
