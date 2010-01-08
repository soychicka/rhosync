class DebugController < ApplicationController
  def index
  end
  
  def send_file
    fname = sanitize_filename(params["fname"])
    send_data(IO.read("log/#{fname}"),
      :type => 'text/plain',
      :filename => "#{fname}")
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
