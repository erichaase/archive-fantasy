require 'test_helper'

class BoxScoreEntriesControllerTest < ActionController::TestCase
  setup do
    @box_score_entry = box_score_entries(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:box_score_entries)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create box_score_entry" do
    assert_difference('BoxScoreEntry.count') do
      post :create, box_score_entry: { ast: @box_score_entry.ast, blk: @box_score_entry.blk, fga: @box_score_entry.fga, fgm: @box_score_entry.fgm, fname: @box_score_entry.fname, fta: @box_score_entry.fta, ftm: @box_score_entry.ftm, lname: @box_score_entry.lname, min: @box_score_entry.min, oreb: @box_score_entry.oreb, pf: @box_score_entry.pf, pid_espn: @box_score_entry.pid_espn, plusminus: @box_score_entry.plusminus, pts: @box_score_entry.pts, reb: @box_score_entry.reb, status: @box_score_entry.status, stl: @box_score_entry.stl, to: @box_score_entry.to, tpa: @box_score_entry.tpa, tpm: @box_score_entry.tpm }
    end

    assert_redirected_to box_score_entry_path(assigns(:box_score_entry))
  end

  test "should show box_score_entry" do
    get :show, id: @box_score_entry
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @box_score_entry
    assert_response :success
  end

  test "should update box_score_entry" do
    put :update, id: @box_score_entry, box_score_entry: { ast: @box_score_entry.ast, blk: @box_score_entry.blk, fga: @box_score_entry.fga, fgm: @box_score_entry.fgm, fname: @box_score_entry.fname, fta: @box_score_entry.fta, ftm: @box_score_entry.ftm, lname: @box_score_entry.lname, min: @box_score_entry.min, oreb: @box_score_entry.oreb, pf: @box_score_entry.pf, pid_espn: @box_score_entry.pid_espn, plusminus: @box_score_entry.plusminus, pts: @box_score_entry.pts, reb: @box_score_entry.reb, status: @box_score_entry.status, stl: @box_score_entry.stl, to: @box_score_entry.to, tpa: @box_score_entry.tpa, tpm: @box_score_entry.tpm }
    assert_redirected_to box_score_entry_path(assigns(:box_score_entry))
  end

  test "should destroy box_score_entry" do
    assert_difference('BoxScoreEntry.count', -1) do
      delete :destroy, id: @box_score_entry
    end

    assert_redirected_to box_score_entries_path
  end
end
