#!/usr/bin/env ruby

require 'rubygems'
require 'id3lib'
require 'earworm'
require 'yaml'
require 'find'

%x{stty -icanon -echo}

CONFIG = File.join(File.expand_path(ENV['HOME']), '.earworm')
begin
  config = YAML.load_file(CONFIG)
rescue
  raise "\n\nYou need to generate a key here: http://www.musicip.com/dns/license.jsp\n then put the key into your .earworm file like this:
key: 012321312AA\n"
end

ew = Earworm::Client.new(config['key'])


Find.find('.'){|file|
  begin
    next unless file.match(/(mp3|ogg)/)
    tag = ID3Lib::Tag.new(file)
    extension = $1 if file.match(/.*\.(.+)/)
    puts "\n#{File.basename(file)} (filename)\n#{tag.artist} - #{tag.title}.#{extension} (from id3)\n(p to process, i to rename file from id3, s or enter to skip)???"
    input = STDIN.read(1)
    next unless input.match(/(p|i)/)
    if input.match(/i/i)
      File.rename(file, "#{tag.artist} - #{tag.title}.#{extension}") if input.match(//)
      next
    end

    puts "Trying to identify #{file}" 
    track = ew.identify(:file => file)

    if track.title.length > 2 and track.artist_name.length > 2

      puts "Update with:#{track.artist_name} - #{track.title} ??"
      next unless STDIN.read(1).match(/y/i)

      tag.title = track.title
      tag.artist = track.artist_name
      tag.update!

      File.rename(file, "#{tag.artist} - #{tag.title}.#{extension}")
    else
      puts "Skipping, results were: #{track.artist_name} - #{track.title}"
    end
  rescue
    puts "Skipping due to error"
    next
  end

}

