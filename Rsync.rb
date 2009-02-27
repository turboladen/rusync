#!/usr/bin/ruby

#
#  RsyncController.rb
#  MyRsync
#
#  Created by Steve Loveless on 2/16/09.
#  Copyright (c) 2009 Pelco. All rights reserved.
#

require 'osx/cocoa'

class Rsync < OSX::NSObject
  ib_outlets :rsync_controller
  
  def doRsync(dir1, dir2, doDiff)
  end
end