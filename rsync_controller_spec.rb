require 'RsyncController'

describe RsyncController do
  before(:each) do
    @controller = RsyncController.new
    
    @rsync = mock('Rsync')
    @text_field1 = mock('Dir1')
    @text_field1.stub!(:stringValue).and_return("~/tmp/test")
    @controller.dir1 = @text_field1
    @text_field2 = mock('Dir2')
    @text_field2.stub!(:stringValue).and_return("~/tmp/test1")
    @controller.dir2 = @text_field2
    @controller.rsync = @rsync
    @rsync.stub!(:do_rsync_diff)
    
    @rsync.stub!(:results).and_return("a bunch of stuff")
    @results = mock('Results')
    @controller.results = @results
    @results.stub!(:setString)
    
    @checkboxstate = mock('CheckboxState')
    @controller.checkboxstate = @checkboxstate
    @checkboxstate.stub!(:setState)
  end
  
  it "should get the path of the rsync directories and diff them" do
    mock_text_field1 = mock('Dir1')
    @controller.dir1 = mock_text_field1
    mock_text_field2 = mock('Dir2')
    @controller.dir2 = mock_text_field2
    
    mock_text_field1.should_receive(:stringValue)
    mock_text_field2.should_receive(:stringValue)
    @controller.do_rsync_diff 
  end
  
  it "should be an OSX::NSObject" do
    @controller.is_a?(OSX::NSObject).should == true
  end
  
  it "should have an outlet to a diff object" do
    @controller.rsync = @rsync
  end
  
  it "should send the dir values to the rsync object and do the rsync" do
    @rsync.should_receive(:do_rsync_diff).with("~/tmp/test", "~/tmp/test1")
    @controller.do_rsync_diff
  end
  
  it "should have an outlet to the rsync results" do
    @results = mock('Results')
    @controller.results = @results
  end
  
  it "should update the results after doing the rsync" do
    @rsync.should_receive(:do_rsync_diff)
    @rsync.should_receive(:results).and_return("a bunch of stuff")
    @results.should_receive(:setString).with("a bunch of stuff")
    
    @controller.do_rsync_diff
  end
  
  it "should have an outlet to a checkbox dry run outlet" do
    
  end
end
