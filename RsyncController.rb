#
#  RsyncController.rb
#  MyRsync
#
#  Created by Steve Loveless on 2/16/09.
#  Copyright (c) 2009 Pelco. All rights reserved.
#

require 'osx/cocoa'

class RsyncController < OSX::NSObject
  ib_outlets :source_dir, :rsync_module, :rsync, :results, :checkbox
  
  #TODO: Add timestamp for start, finish, calculated duration
  #TODO: make scrollbar stay at bottom as new data is coming in
  #TODO: make text not wrap
  #TODO: UI allows use of $> rsync steve@192.168.10.3:: to get list of modules
  #TODO: use --dry-run instead of -n
  #TODO: consider using --list-only instead of --dry-run
  #TODO: capture Exit Values
  #TODO: need to handle error conditions (conn failure)
  #TODO: consider using --timeout=TIMEOUT in case the connection is dropped
  #TODO: consider using --contimeout for bad connection initiations
  #TODO: UI allows option of using --human-readable
  #TODO: UI should provide verbosity config, i.e. -vv instead of -v
  #TODO: Add rsync over ssh
  #TODO: In light of using ssh to connect, it could be cool to have profiles like Handbrake
  #TODO: Fix prob: I syned ../M. Ward/Hold Time, and only ../Hold Time gets put
  #TODO: give option to have rsync log to file using --log-file
  #TODO: consider using --itemize-changes instead of --stats
  #TODO: consider using --delete to delete files on the source
  	
  #----------------------------------------------------------------------------
  # Function:		awakeFromNib
  #
  # Purpose:		Sets up UI fields on startup
  #----------------------------------------------------------------------------
  def awakeFromNib
    @source_dir.setStringValue('/Volumes/My Book/Music/iTunes/113')
    @rsync_module.setStringValue('steve@192.168.10.3::iTunes')
  end
	
  #----------------------------------------------------------------------------
  # Function:		doRsync
  #
  # Purpose:		Kicks off the rsync process
  #----------------------------------------------------------------------------
  #TODO: look into decoupling this function into a different, worker class
  def doRsync(sender)
    #Log the checkbox value
    puts "checkbox value = #{@checkbox.state}"
    
    #Make sure we're not running
    @task = OSX::NSTask.alloc.init
    
    #Prepare the command for the task
    @task.setLaunchPath "/opt/local/bin/rsync"
    
    #Prepare args for the command
    args = setupArgs
    puts "launch path = #{@task.launchPath}"
    args.each {|arg| puts "Got argument '#{arg}"}
    
    #Create a new pipe
    @pipe = OSX::NSPipe.alloc.init
    @task.setStandardOutput @pipe
    
    #Pass the pipe to a file handle
    fh = OSX::NSFileHandle.alloc.init
    fh = @pipe.fileHandleForReading
    
    #Setup observers on the file handle and task
    #TODO: See if this can be one line... a la .alloc.init.defaultCenter
    nc = OSX::NSNotificationCenter.alloc.init
    nc = OSX::NSNotificationCenter.defaultCenter
    nc.removeObserver(self)
    nc.addObserver_selector_name_object_(self, 'dataReady:',
				OSX::NSFileHandleReadCompletionNotification,fh)
    nc.addObserver_selector_name_object_(self, 'taskTerminated:',
				OSX::NSTaskDidTerminateNotification,@task)
    
    #Run it
    @task.launch
    @results.setString "Starting rsync...\n"
    fh.readInBackgroundAndNotify
  end
  ib_action :doRsync
  
  #----------------------------------------------------------------------------
  # Function:		setupArgs
  #
  # Purpose:		Sets up the cmd task arguments
  #----------------------------------------------------------------------------
  def setupArgs
    #Prepare args for the command
    args = ['-vrn', '--compress', '--protect-args', '--stats', '--progress',
	    '--iconv=UTF8-MAC','--human-readable', 
	    "#{@source_dir.stringValue}", "#{@rsync_module.stringValue}"]
    
    #Check if we need a --dry run arg
    if @checkbox.state.eql?(0)
      args[0] = '-vr'
    end
    
    #Assign the args to the task
    @task.setArguments args
    
    return args
  end
  
  #----------------------------------------------------------------------------
  # Function:		appendData
  #
  # Purpose:		Posts data back to the UI, once fed
  #----------------------------------------------------------------------------
  def appendData(data)
    #get the data to a string
    s = OSX::NSString.alloc.initWithData_encoding(data,OSX::NSUTF8StringEncoding)
    
    #Prep the data to push back to the UI
    ts = OSX::NSTextStorage.alloc.init
    ts = @results.textStorage
    ts.replaceCharactersInRange_withString(OSX::NSMakeRange(ts.length, 0), s)
    
    s.release
  end
  
  #----------------------------------------------------------------------------
  # Function:		dataReady
  #
  # Purpose:		Sends the cmd task return data to the UI post method
  #----------------------------------------------------------------------------
  def dataReady(ntf)
    #Read the data in
    inData = ntf.userInfo.valueForKey(OSX::NSFileHandleNotificationDataItem)
    
    #Log how much data
    puts "dataReady: #{inData.length} bytes"
    
    if inData.length
      #TODO: if this function is in a different class, this call could just call appendData in this class
      self.appendData(inData)
    end
    
    #If the task is running, start reading again
    if (@task)
      @pipe.fileHandleForReading.readInBackgroundAndNotify
    end
  end
  
  #----------------------------------------------------------------------------
  # Function:		taskTerminated
  #
  # Purpose:		Ends the cmd task and cleans up
  #----------------------------------------------------------------------------
  def taskTerminated(notification)
    #Log that we're ending
    sendOkAlert
    puts("taskTerminated:")
    
    @task.release
    @task = nil
  end
  
  #----------------------------------------------------------------------------
  # Function:		sendOkAlert
  #
  # Purpose:		Pops up a dialog saying we're done
  #----------------------------------------------------------------------------
  def sendOkAlert
    #Set messages according to dry run vs. real run
    if @checkbox.state.eql?(0)
      msgTxt 	= "Rsync Successful!"
      infoTxt 	= "The rsync operation to #{@rsync_module.stringValue} was successful"
    elsif @checkbox.state.eql?(1)
      msgTxt 	= "Rsync Dry Run Successful!"
      infoTxt 	= "The rsync dry run to #{@rsync_module.stringValue} was successful"
    end
    
    #Setup the box
    alert = OSX::NSAlert.alloc.init
    alert.setMessageText(msgTxt)
    alert.setInformativeText(infoTxt)
    alert.setAlertStyle(OSX::NSInformationalAlertStyle)
    alert.addButtonWithTitle("Ok")
    
    #Do the box!
    alert.runModal
  end
end
