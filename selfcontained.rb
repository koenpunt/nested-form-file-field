begin
  require 'bundler/inline'
rescue LoadError => e
  $stderr.puts 'Bundler version 1.10 or later is required. Please update your Bundler'
  raise e
end

gemfile(true) do
  source 'https://rubygems.org'
  gem 'rails', github: 'rails/rails', branch: 'master'
  gem 'rack-test', github: 'koenpunt/rack-test', branch: 'multipart-override'
  gem 'sqlite3'
end

require 'action_controller/railtie'

class TestApp < Rails::Application
  config.root = File.dirname(__FILE__)
  config.session_store :cookie_store, key: 'cookie_store_key'
  secrets.secret_token    = 'secret_token'
  secrets.secret_key_base = 'secret_key_base'

  config.logger = Logger.new($stdout)
  Rails.logger  = config.logger

  routes.draw do
    get '/' => 'test#new'
    post '/' => 'test#create'
  end
end

class TestController < ActionController::Base
  include Rails.application.routes.url_helpers

  def form_tpl
    form = <<-FORM
    <h1>New User</h1>

    <%= form_for(@user, url: '/') do |f| %>

      <%= hidden_field_tag :with_file, params[:with_file] %>

      <% if @user.errors.any? %>
        <div id="error_explanation">
          <h2><%= pluralize(@user.errors.count, "error") %> prohibited this user from being saved:</h2>

          <ul>
          <% @user.errors.full_messages.each do |message| %>
            <li><%= message %></li>
          <% end %>
          </ul>
        </div>
      <% end %>

      <div class="field">
        <%= f.label :email %>
        <%= f.text_field :email %>
      </div>

      <fieldset>
        <legend>Restaurant</legend>
        <%= f.fields_for :restaurant do |r| %>
          <div class="field">
            <%= r.label :name %>
            <%= r.text_field :name %>
          </div>
          <% if params[:with_file] == '1' %>
          <div class="field">
            <%= r.label :logo %>
            <%= r.file_field :logo %>
          </div>
          <% end %>
        <% end %>
      </fieldset>

      <div class="actions">
        <%= f.submit %>
      </div>
    <% end %>
    FORM
    form
  end

  def new
    @user = User.new
    @user.build_restaurant
    render inline: form_tpl
  end

  def create
    @user = User.new(user_params)

    if ARGV[0] == 'rebuild'
      @user.restaurant ||= @user.build_restaurant
    end

    if @user.save
      redirect_to @user, notice: 'User was successfully created.'
    else
      render inline: form_tpl
    end
  end

  private

    def user_params
      params.require(:user).permit(:email, restaurant_attributes: [:name, :logo])
    end

end

require 'active_record'
require 'minitest/autorun'
require 'rack/test'
require 'logger'

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table "restaurants", force: :cascade do |t|
    t.string   "name"
    t.string   "logo"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "restaurants", ["user_id"], name: "index_restaurants_on_user_id"

  create_table "users", force: :cascade do |t|
    t.string   "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end

class Restaurant < ActiveRecord::Base
  belongs_to :user, optional: true
  validates :name, presence: true
end

class User < ActiveRecord::Base
  has_one :restaurant
  accepts_nested_attributes_for :restaurant
  validates :email, format: { with: /\A[^@\s]+@([^@\s]+\.)+[^@\W]+\z/ }, presence: true
end

class CreateUserTest < ActionDispatch::IntegrationTest
  include Rack::Test::Methods
  include Rack::Test::Utils

  def assert_label
    assert last_response.body =~ /for="user_restaurant_attributes_name">Name/, "label not found"
  end

  def assert_error_explanation(message)
    assert last_response.body =~ /id="error_explanation">.*#{message}/m, "error message not found"
  end

  test "regular with email" do
    get '/'
    assert last_response.ok?, "invalid response"
    assert_label
    post '/', { user: { email: 'abc@example.com', restaurant_attributes: { name: '' } } }
    assert last_response.ok?, "invalid response"
    assert_label
    assert_error_explanation "Restaurant name can&#39;t be blank"
  end

  test "regular with invalid email" do
    get '/'
    assert last_response.ok?, "invalid response"
    assert_label
    post '/', { user: { email: 'hello world', restaurant_attributes: { name: '' } } }
    assert last_response.ok?, "invalid response"
    assert_label
    assert_error_explanation "Email is invalid"
  end

  test "regular with empty email" do
    get '/'
    assert last_response.ok?, "invalid response"
    assert_label
    post '/', { user: { email: '', restaurant_attributes: { name: '' } } }
    assert last_response.ok?, "invalid response"
    assert_label
    assert_error_explanation "Email can&#39;t be blank"
  end

  test "multipart with email" do
    get '/?with_file=1'
    assert last_response.ok?, "invalid response"
    assert_label
    post_multipart '/', { with_file: 1, user: { email: 'abc@example.com', restaurant_attributes: { name: '' } } }
    assert last_response.ok?, "invalid response"
    assert_label
    assert_error_explanation "Restaurant name can&#39;t be blank"
  end

  test "multipart with invalid email" do
    get '/?with_file=1'
    assert last_response.ok?, "invalid response"
    assert_label
    post_multipart '/', { with_file: 1, user: { email: 'hello world', restaurant_attributes: { name: '' } } }
    assert last_response.ok?, "invalid response"
    assert_label
    assert_error_explanation "Email is invalid"
  end

  test "multipart with empty email" do
    get '/?with_file=1'
    assert last_response.ok?, "invalid response"
    assert_label
    post_multipart '/', { with_file: 1, user: { email: '', restaurant_attributes: { name: '' } } }
    assert last_response.ok?, "invalid response"
    assert_label
    assert_error_explanation "Email can&#39;t be blank"
  end

  private

    def post_multipart(path, params = {}, env = {})
      data = build_multipart(params, true, true)
      env["CONTENT_LENGTH"] = data.length.to_s
      env["CONTENT_TYPE"] = "multipart/form-data; boundary=#{Rack::Test::MULTIPART_BOUNDARY}"
      post '/', data, env
    end

    def app
      Rails.application
    end

end
