$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'
require 'faker'

describe "RhosyncStore Performance" do
  before(:each) do
    @source = 'MyCustomer'
    @user = 6
    @sync_store = RhosyncStore.new
    @sync_store.db.flushdb
  end

  it "should process get/put for 1000 records (7000 elements)" do
    @data = get_test_data(1000)
    start = start_timer
    @sync_store.put_data('doc1',@source,@user,@data).should == true
    start = lap_timer('put_data duration',start)
    @sync_store.get_data('doc1',@source,@user).should == @data
    lap_timer('get_data duration',start)
  end

  it "should process single attribute update 1000-record doc" do
    @data = get_test_data(1000)
    @data1 = get_test_data(1000)
    @data1['900']['Phone1'] = 'This is changed'
    expected = {'900' => {'Phone1' => 'This is changed'}}
    @sync_store.put_data('doc1',@source,@user,@data).should == true
    @sync_store.put_data('doc2',@source,@user,@data1).should == true
    start = start_timer
    @sync_store.get_diff_data('doc1','doc2',@source,@user).should == expected
    lap_timer('get_diff_data duration', start)
  end

  
  #########################################
  private
  PREFIX = ["Account", "Administrative", "Advertising", "Assistant", "Banking", "Business Systems", 
    "Computer", "Distribution", "IT", "Electronics", "Environmental", "Financial", "General", "Head", 
    "Laboratory", "Maintenance", "Medical", "Production", "Quality Assurance", "Software", "Technical", 
    "Chief", "Senior"]
  SUFFIX = ["Clerk", "Analyst", "Manager", "Supervisor", "Plant Manager", "Mechanic", "Technician", "Engineer", 
    "Director", "Superintendent", "Specialist", "Technologist", "Estimator", "Scientist", "Foreman", "Nurse", 
    "Worker", "Helper", "Intern", "Sales", "Mechanic", "Planner", "Recruiter", "Officer", "Superintendent",
    "Vice President", "Buyer", "Production Supervisor", "Chef", "Accountant", "Executive"]
  
  def title
    prefix = PREFIX[rand(PREFIX.length)]
    suffix = SUFFIX[rand(SUFFIX.length)]

    "#{prefix} #{suffix}"
  end

  def generate_fake_data(num=1000)
    res = {}
    num.times do |n|
      res[n.to_s] = {
        "FirstName" => Faker::Name.first_name,
        "LastName" => Faker::Name.last_name,
        "Email" =>  Faker::Internet.free_email,
        "Company" => Faker::Company.name,
        "JobTitle" => title,
        "Phone1" => Faker::PhoneNumber.phone_number
      }
    end
    res
  end
  
  def get_test_data(num=1000)
    file = File.join("spec","testdata","#{num}-data.txt")
    data = nil
    if File.exists?(file)
      data = open(file, 'r') {|f| Marshal.load(f)}
    else
      data = generate_fake_data(num)
      f = File.new(file, 'w')
      f.write Marshal.dump(data)
      f.close
    end
    data
  end
  
  def timenow
    (Time.now.to_f * 1000)
  end
  
  def start_timer
    timenow
  end
  
  def lap_timer(msg,start)
    duration = timenow - start
    puts "#{msg}: #{duration}"
    timenow
  end
end