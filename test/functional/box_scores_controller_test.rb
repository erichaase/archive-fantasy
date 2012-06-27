require 'test_helper'

class BoxScoresControllerTest < ActionController::TestCase
  setup do
    @box_score = box_scores(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:box_scores)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create box_score" do
    assert_difference('BoxScore.count') do
      post :create, box_score: { date: @box_score.date, gid_espn: @box_score.gid_espn, status: @box_score.status }
    end

    assert_redirected_to box_score_path(assigns(:box_score))
  end

  test "should show box_score" do
    get :show, id: @box_score
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @box_score
    assert_response :success
  end

  test "should update box_score" do
    put :update, id: @box_score, box_score: { date: @box_score.date, gid_espn: @box_score.gid_espn, status: @box_score.status }
    assert_redirected_to box_score_path(assigns(:box_score))
  end

  test "should destroy box_score" do
    assert_difference('BoxScore.count', -1) do
      delete :destroy, id: @box_score
    end

    assert_redirected_to box_scores_path
  end
end
