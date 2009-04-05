#
#  CommandController.rb
#  RuSync
#
#  Created by Steve Loveless on 3/29/09.
#  Copyright (c) 2009 Steve Loveless. All rights reserved.
#

require 'osx/cocoa'

class CommandController < OSX::NSObject
  # UI outlets
  ib_outlets :source_dir, :rsync_user, :rsync_server, :server_module,
    :dryrun_checkbox 
	
  attr_reader :args, :destination, :source_string
  
  # Controller outlets
  ib_outlets :rsync_controller
  
  # Available actions
  ib_action :sync
  ib_action :chooseSource
  
  #----------------------------------------------------------------------------
  # Function:		initialiaze
  #
  # Purpose:		Sets up variables when instantiated
  #----------------------------------------------------------------------------
  def initialize
    @args 
  end
  
  #----------------------------------------------------------------------------
  # Function:		awakeFromNib
  #
  # Purpose:		Sets up UI fields on startup
  #----------------------------------------------------------------------------
  def awakeFromNib
    #@source_dir.setStringValue('/Volumes/My Book/Music/iTunes/*')
    @source_dir.setStringValue('/Users/sloveless/tmp/')
    @rsync_user.setStringValue('steve')
    @rsync_server.setStringValue('192.168.10.3')
    #@rsync_server.setStringValue('segue.gotdns.org')
    @server_module.setStringValue('test')
    #@server_module.setStringValue('iTunes')
  end
	
  #----------------------------------------------------------------------------
  # Function:		chooseSource
  #
  # Purpose:		Lets the user choose file/dir from a dialog
  #----------------------------------------------------------------------------
  def chooseSource
    # Create the File Open Dialog class
    openDlg = OSX::NSOpenPanel.openPanel

    # Enable the selection of files in the dialog
    openDlg.setCanChooseFiles(true)

    # Enable the selection of directories in the dialog
    openDlg.setCanChooseDirectories(true)

    # Display the dialog.  If the OK button was pressed, process the files
    if (openDlg.runModalForDirectory_file(nil, nil).eql?(OSX::NSOKButton))
      # Get an array of filename of file or directory selected
      source = openDlg.filenames

      # Loop through all the files and process them.
      @source_dir.stringValue = source.objectAtIndex(0)
    end
  end
  
  
  #----------------------------------------------------------------------------
  # Function:		setupArgs
  #
  # Purpose:		Gets the rsync cmd task arguments from the UI
  #----------------------------------------------------------------------------
  def setupArgs
    # Log the checkbox value
    puts "dry run checkbox value = #{@dryrun_checkbox.state}"
    
    # Make the destination string
    @destination = "#{@rsync_user.stringValue}@#{@rsync_server.stringValue}::#{@server_module.stringValue}"
 
    # Prepare args for the command
    @args = ['-vvrn', '--compress', '--protect-args', '--stats', '--progress',
	    '--iconv=UTF8-MAC','--human-readable', '--delete',
	    "#{@source_dir.stringValue}", "#{@destination}"]
    
    # Check if we need a --dry run arg
    if @dryrun_checkbox.state.eql?(0)
      @args[0] = '-vvr'
    end
    
    # Returns & outputs each retrieved arg
    @args.each {|@arg| puts "Got argument '#{@arg}'"}
  end
  
  #----------------------------------------------------------------------------
  # Function:		sync
  #
  # Purpose:		Kicks off the rsync
  #----------------------------------------------------------------------------
  def sync
    # Setup the arguments and do the rsync
    @rsync_controller.doRsync(setupArgs)
    
    # Observe the rsync task so we can tell user we're done when it's done
    @rsync_controller.nc.addObserver_selector_name_object_(self, 'sendOkAlert:',
		OSX::NSTaskDidTerminateNotification, @rsync_controller.task)
  end
  
  #----------------------------------------------------------------------------
  # Function:		sendOkAlert
  #
  # Purpose:		Pops up a dialog saying we're done
  #----------------------------------------------------------------------------
  def sendOkAlert(notification)
    # Set messages according to dry run vs. real run
    if @dryrun_checkbox.state.eql?(0)
      msgTxt 	= "Rsync Completed!"
      infoTxt 	= "The rsync operation to #{@destination} completed"
    elsif @dryrun_checkbox.state.eql?(1)
      msgTxt 	= "Rsync Dry Run Completed!"
      infoTxt 	= "The rsync dry run to #{@destination} completed"
    end
    
    # Setup the box
    alert = OSX::NSAlert.alloc.init
    alert.setMessageText(msgTxt)
    alert.setInformativeText(infoTxt)
    alert.setAlertStyle(OSX::NSInformationalAlertStyle)
    alert.addButtonWithTitle("Ok")
    
    # Do the box!
    alert.runModal
  end
end
