#
#  RsyncController.rb
#  RuRsync
#
#  Created by Steve Loveless on 2/16/09.
#  Copyright (c) 2009 Steve Loveless. All rights reserved.
#

require 'osx/cocoa'

class RsyncController < OSX::NSObject
  # Class outlets
  ib_outlets :results
  attr_reader :task, :nc
  
  #TODO: capture rsync Exit Values
  #TODO: need to handle error conditions (conn failure)
  #TODO: consider using --timeout=TIMEOUT in case the connection is dropped
  #TODO: UI allows option of using --human-readable
  #TODO: Fix prob: I syned ../M. Ward/Hold Time, and only ../Hold Time gets put
  #TODO: consider using --itemize-changes instead of --stats
  	
  #----------------------------------------------------------------------------
  # Function:		initialize
  #
  # Purpose:		Initializes objects on startup
  #----------------------------------------------------------------------------
  def initialize
    @totalReadData = 0		# variable for counting bytes read from rsync
    @rsync_path = "/opt/local/bin/rsync"
  end
  
  #----------------------------------------------------------------------------
  # Function:		doRsync
  #
  # Purpose:		Kicks off the rsync process
  #----------------------------------------------------------------------------
  def doRsync(args)
    # Clear the data in @results before we do anything
    @results.setString ""
    
    # Make sure we're not running
    @task = OSX::NSTask.alloc.init
    
    # Prepare the command for the task
    @task.setLaunchPath @rsync_path
    puts "launch path = #{@task.launchPath}"
    
    # Pass the arguments to the task
    @task.arguments = args
    
    # Create a new pipe
    @pipe = OSX::NSPipe.alloc.init
    @task.setStandardOutput @pipe
    
    # Pass the pipe to a file handle
    fh = OSX::NSFileHandle.alloc.init
    fh = @pipe.fileHandleForReading
    
    # Setup observers on the file handle and task
    @nc = OSX::NSNotificationCenter.alloc.init
    @nc = OSX::NSNotificationCenter.defaultCenter
    @nc.removeObserver(self)
    @nc.addObserver_selector_name_object_(self, 'dataReady:',
				OSX::NSFileHandleReadCompletionNotification, fh)
    @nc.addObserver_selector_name_object_(self, 'taskTerminated:',
				OSX::NSTaskDidTerminateNotification, @task)
    
    # Run it
    @task.launch
    
    # Tell users we're starting
    @results.setString "Starting rsync...\n"
    
    # Send the arg list to the UI
    @results.textStorage.mutableString.appendString "Args: #{(args)}\n"
		
		# Display the start time
		@time_start = Time.now
    @results.textStorage.mutableString.appendString "Start time: #{@time_start.strftime("%H:%M:%S")}\n"
    
    # Start notification for when rsync output data is ready to send to the UI
    fh.readInBackgroundAndNotify
  end
  
  #----------------------------------------------------------------------------
  # Function:		appendData
  #
  # Purpose:		Posts data back to the UI, once fed
  #----------------------------------------------------------------------------
  def appendData(data)
    # Get the data to a string
    s = OSX::NSString.alloc.initWithData_encoding(data,OSX::NSUTF8StringEncoding)
    
    # Prep the data to push back to the UI
    ts = OSX::NSTextStorage.alloc.init
    ts = @results.textStorage
    ts.replaceCharactersInRange_withString(OSX::NSMakeRange(ts.length, 0), s)
    
    # Auto-scroll to the botton of the NSTextView
    @results.scrollRangeToVisible(OSX::NSMakeRange(ts.length, 0))
    
    # Release the string, now that we've posted it to the UI
    s.release
    s = nil
  end
  
  #----------------------------------------------------------------------------
  # Function:		dataReady
  #
  # Purpose:		Sends the cmd task return data to the UI post method
  #----------------------------------------------------------------------------
  def dataReady(ntf)
    # Read the data in
    inData = ntf.userInfo.valueForKey(OSX::NSFileHandleNotificationDataItem)
    
    # Log how much data we're reading now and overall how much we've read
    @totalReadData = @totalReadData + inData.length
    puts "dataReady: #{inData.length} bytes"
    puts "Total read data: #{@totalReadData} bytes"
    
    # Send the data off to the UI
    if inData.length
      self.appendData(inData)
    end
    
    # If the task is running, start reading again
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
    # Log that we're ending
    puts("taskTerminated: #{@task.processIdentifier}")
    
    # Release the task
    @task.release
    @task = nil
    
    # Output to UI the time summary
    @time_end = Time.now
    @results.textStorage.mutableString.appendString "End time: #{@time_end.strftime("%H:%M:%S")}\n"
    @results.textStorage.mutableString.appendString "Duration: #{@time_end - @time_start} seconds\n"
    @results.textStorage.mutableString.appendString "Duration: #{(@time_end - @time_start)/60} minutes\n"
	end
end
