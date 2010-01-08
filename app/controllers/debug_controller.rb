class DebugController < ApplicationController
  def index
  end
  
  def send_file
    fname = sanitize_filename(params["fname"])
    send_data(IO.read("log/#{fname}"),
      :type => 'text/plain',
      :filename => "#{fname}")
  end
  
  def clear_file
    fname = sanitize_filename(params["fname"])
    system("echo '' > log/#{fname}")
    redirect_to :action => :index
  end
  
  def restart
    system("touch tmp/restart.txt")
    redirect_to :action => :index    
  end
  
  def git_pull
    system("git pull")
    redirect_to :action => :index    
  end
  
  def bj_restart
    system("ruby script/bj run --forever --rails_env=#{Rails.env} --rails_root=#{RAILS_ROOT} &")
    redirect_to :action => :index
  end
  
  protected
  
  # source http://guides.rubyonrails.org/security.html
  def sanitize_filename(filename)  
    returning filename.strip do |name| 
      # NOTE: File.basename doesn't work right with Windows paths on Unix  
      # get only the filename, not the whole path  
      name.gsub! /^.*(\\|\/)/, ''  
      # Finally, replace all non alphanumeric, underscore  
      # or periods with underscore  
      name.gsub! /[^\w\.\-]/, '_'  
    end 
  end 
end
