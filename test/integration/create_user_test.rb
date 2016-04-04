require 'test_helper'

class CreateUserTest < ActionDispatch::IntegrationTest
  test "regular form" do
    get new_user_path
    assert_response :success
    assert_select '[for=user_restaurant_attributes_name]', 'Name'
    post users_path, params: { user: { email: '', restaurant_attributes: { name: '' } } }
    assert_response :success
    assert_select '[for=user_restaurant_attributes_name]', 'Name'
    assert_select '#error_explanation', /Email is invalid/
  end

  test "nested form" do
    get new_user_path(with_file: true)
    assert_response :success
    assert_select '[for=user_restaurant_attributes_name]', 'Name'
    post users_path, params: { user: { email: '', restaurant_attributes: { name: '' } } }
    assert_response :success
    assert_select '[for=user_restaurant_attributes_name]', 'Name'
    assert_select '#error_explanation', /Email is invalid/
  end
end
