#!/usr/bin/env ruby


#@cmd = "/opt/local/bin/rsync -vrz --stats --progress --iconv=UTF8-MAC '#{dir1}' '#{dir2}'"


class Sync
  require 'rubygems'
  gem 'file-tail'
  require 'file/tail'
  
  def initialize
    @dir1 = "/Volumes/My Book/Music/iTunes/113"
    @dir2 = "steve@192.168.10.3::iTunes"
    @tailFile = '/Users/sloveless/tmp/RuSync.out'
  end
  
  
  def doSync
    results = %x{/opt/local/bin/rsync -vrz --stats --progress --iconv=UTF8-MAC '#{@dir1}' '#{@dir2}' > #{@tailFile}}
    #tail(@tailFile)
    begin
      File.open(@tailFile) do |log|
        log.extend(File::Tail)
        log.interval = 1
        log.backward(20)
        log.tail { |line| puts line }
      end
    rescue Exception
    end
  end
  
  #def tail(theFile)
  #  f = File.open(theFile,"r")
  #  f.each_line {|line| puts line}
  #  f.close
  #end
end
cont = Sync.new
cont.doSync
