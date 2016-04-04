require 'test_helper'
require 'multipart'

class CreateUserTest < ActionDispatch::IntegrationTest

  test "regular with email" do
    get new_user_path
    assert_response :success
    assert_select '[for=user_restaurant_attributes_name]', 'Name'
    post users_path, { params: { user: { email: 'abc@example.com', restaurant_attributes: { name: '' } } } }
    assert_response :success
    assert_select '[for=user_restaurant_attributes_name]', 'Name'
    assert_select '#error_explanation', /Restaurant name can't be blank/
  end

  test "regular with invalid email" do
    get new_user_path
    assert_response :success
    assert_select '[for=user_restaurant_attributes_name]', 'Name'
    post users_path, { params: { user: { email: 'hello world', restaurant_attributes: { name: '' } } } }
    assert_response :success
    assert_select '[for=user_restaurant_attributes_name]', 'Name'
    assert_select '#error_explanation', /Email is invalid/
  end

  test "regular with empty email" do
    get new_user_path
    assert_response :success
    assert_select '[for=user_restaurant_attributes_name]', 'Name'
    post users_path, { params: { user: { email: '', restaurant_attributes: { name: '' } } } }
    assert_response :success
    assert_select '[for=user_restaurant_attributes_name]', 'Name'
    assert_select '#error_explanation', /Email can't be blank/
  end

  test "multipart with email" do
    get new_user_path(with_file: true)
    assert_response :success
    assert_select '[for=user_restaurant_attributes_name]', 'Name'
    post users_path, encode({ with_file: 1, user: { email: 'abc@example.com', restaurant_attributes: { name: '' } } })
    assert_response :success
    assert_select '[for=user_restaurant_attributes_name]', 'Name'
    assert_select '#error_explanation', /Restaurant name can't be blank/
  end

  test "multipart with invalid email" do
    get new_user_path(with_file: true)
    assert_response :success
    assert_select '[for=user_restaurant_attributes_name]', 'Name'
    post users_path, encode({ with_file: 1, user: { email: 'hello world', restaurant_attributes: { name: '' } } })
    assert_response :success
    assert_select '[for=user_restaurant_attributes_name]', 'Name'
    assert_select '#error_explanation', /Email is invalid/
  end

  test "multipart with empty email" do
    get new_user_path(with_file: true)
    assert_response :success
    assert_select '[for=user_restaurant_attributes_name]', 'Name'
    post users_path, encode({ with_file: 1, user: { email: '', restaurant_attributes: { name: '' } } })
    assert_response :success
    assert_select '[for=user_restaurant_attributes_name]', 'Name'
    assert_select '#error_explanation', /Email can't be blank/
  end

  private

    def encode(params)
      data, headers = Multipart::Post.prepare_query(params)
      { params: data, headers: headers }
    end

end
