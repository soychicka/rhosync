require File.dirname(__FILE__) + '/../test_helper'
require 'aeroprise_controller'

class AeropriseController; def rescue_action(e) raise e end; end

class AeropriseControllerApiTest < Test::Unit::TestCase
  def setup
    @controller = AeropriseController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_notifier
    result = invoke :notifier
    assert_equal nil, result
  end
end
