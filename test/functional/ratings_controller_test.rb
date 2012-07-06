require 'test_helper'

class RatingsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get now" do
    get :now
    assert_response :success
  end

  test "should get day" do
    get :day
    assert_response :success
  end

end
