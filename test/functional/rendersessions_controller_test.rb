require 'test_helper'

class RendersessionsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:rendersessions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create rendersession" do
    assert_difference('Rendersession.count') do
      post :create, :rendersession => { }
    end

    assert_redirected_to rendersession_path(assigns(:rendersession))
  end

  test "should show rendersession" do
    get :show, :id => rendersessions(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => rendersessions(:one).to_param
    assert_response :success
  end

  test "should update rendersession" do
    put :update, :id => rendersessions(:one).to_param, :rendersession => { }
    assert_redirected_to rendersession_path(assigns(:rendersession))
  end

  test "should destroy rendersession" do
    assert_difference('Rendersession.count', -1) do
      delete :destroy, :id => rendersessions(:one).to_param
    end

    assert_redirected_to rendersessions_path
  end
end
