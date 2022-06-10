# encoding: utf-8
#
# This file is a part of Redmine Resources (redmine_resources) plugin,
# resource allocation and management for Redmine
#
# Copyright (C) 2011-2022 RedmineUP
# http://www.redmineup.com/
#
# redmine_resources is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_resources is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_resources.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class ResourceBookingsControllerTest < ActionController::TestCase
  include Redmine::I18n

  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles,
           :issues, :issue_statuses, :issue_relations, :versions, :trackers, :projects_trackers,
           :issue_categories, :enabled_modules, :enumerations, :workflows

  fixtures :email_addresses if Redmine::VERSION.to_s >= '3.0'

  create_fixtures(Redmine::Plugin.find(:redmine_resources).directory + '/test/fixtures/', [:resource_bookings])

  def setup
    @admin = User.find(1)
    @user = User.find(2)
    @second_user = User.find(3)
    @project = Project.find(1)
    @second_project = Project.find(2)
    @five_project = Project.find(5)
    @issue_6 = Issue.find(6)
    @group = Group.first

    EnabledModule.create(project: @project, name: 'resources')
    EnabledModule.create(project: @five_project, name: 'resources')

    @resource_booking_params = {
      project_id: 2,
      assigned_to_id: @user.id,
      issue_id: 1,
      start_date: '2019-01-01',
      end_date: '2019-01-31',
      hours_per_day: 6,
      notes: 'New booking'
    }
  end

  # === Action :index ===

  def test_should_get_index_for_admin
    @request.session[:user_id] = @admin.id
    # From top menu Resources
    check_get_index :success
    # From project menu Resources
    check_get_index :success, project_id: @project.identifier
  end

  def test_should_get_index_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :view_resources
    check_get_index :success
    check_get_index :success, project_id: @project.identifier
  end

  def test_should_not_access_index_without_permission
    @request.session[:user_id] = @user.id
    check_get_index :forbidden
    check_get_index :forbidden, project_id: @project.identifier
  end

  def test_should_not_access_index_for_anonymous
    check_get_index :redirect
    check_get_index :redirect, project_id: @project.identifier
  end

  # === Action :new ===

  def test_should_get_new_for_admin
    @request.session[:user_id] = @admin.id
    # From top menu Resources
    check_get_new :success
    # From project menu Resources
    check_get_new :success, project_id: @project.identifier
  end

  def test_should_get_new_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :add_booking
    check_get_new :success
    check_get_new :success, project_id: @project.identifier
  end

  def test_should_not_access_new_without_permission
    @request.session[:user_id] = @user.id
    check_get_new :forbidden
    check_get_new :forbidden, project_id: @project.identifier
  end

  def test_should_not_access_new_for_anonymous
    check_get_new :unauthorized
    check_get_new :unauthorized, project_id: @project.identifier
  end

  # === Action :create ===

  def test_should_create_resource_bookings_for_admin
    @request.session[:user_id] = @admin.id
    # Creating from top menu Resources
    should_create_resource_booking resource_booking: @resource_booking_params
    # Creating from project menu Resources
    should_create_resource_booking resource_booking: @resource_booking_params, project_id: @project.identifier
  end

  def test_should_create_resource_bookings_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :add_booking
    should_create_resource_booking resource_booking: @resource_booking_params
    should_create_resource_booking resource_booking: @resource_booking_params, project_id: @project.identifier
  end

  def test_should_not_create_resource_bookings_without_permission
    @request.session[:user_id] = @user.id
    should_not_create_resource_booking :forbidden, resource_booking: @resource_booking_params
    should_not_create_resource_booking :forbidden, resource_booking: @resource_booking_params, project_id: @project.identifier
  end

  def test_should_not_create_resource_bookings_for_anonymous
    should_not_create_resource_booking :unauthorized, resource_booking: @resource_booking_params
    should_not_create_resource_booking :unauthorized, resource_booking: @resource_booking_params, project_id: @project.identifier
  end

  def test_should_send_mail_after_create_resource_booking
    @request.session[:user_id] = @admin.id
    ActionMailer::Base.deliveries.clear
    with_settings :notified_events => %w(resource_updated) do
      assert_difference(-> { ActionMailer::Base.deliveries.size }, 2) do
        should_create_resource_booking resource_booking: @resource_booking_params
      end
    end
  end

  # === Action :edit ===

  def test_should_get_edit_for_admin
    @request.session[:user_id] = @admin.id
    # From top menu Resources
    check_get_edit :success, id: 1
    # From project menu Resources
    check_get_edit :success, id: 1, project_id: @project.identifier
  end

  def test_should_get_edit_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :edit_booking
    check_get_edit :success, id: 1
    check_get_edit :success, id: 1, project_id: @project.identifier
  end

  def test_should_not_access_edit_without_permission
    @request.session[:user_id] = @user.id
    check_get_edit :forbidden, id: 1
    check_get_edit :forbidden, id: 1, project_id: @project.identifier
  end

  def test_should_not_access_edit_for_anonymous
    check_get_edit :unauthorized, id: 1
    check_get_edit :unauthorized, id: 1, project_id: @project.identifier
  end

  def test_should_not_access_edit_for_missing_resource_booking
    @request.session[:user_id] = @admin.id
    check_get_edit :missing, id: 777
    check_get_edit :missing, id: 999, project_id: @project.identifier
  end

  # === Action :update ===

  def test_should_update_resource_booking_for_admin
    @request.session[:user_id] = @admin.id
    # From top menu Resources
    should_update_resource_booking id: 1, resource_booking: @resource_booking_params
    # From project menu Resources
    should_update_resource_booking id: 1, project_id: @project.identifier, resource_booking: @resource_booking_params
  end

  def test_should_update_resource_booking_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :edit_booking
    should_update_resource_booking id: 1, resource_booking: @resource_booking_params
    should_update_resource_booking id: 1, project_id: @project.identifier, resource_booking: @resource_booking_params
  end

  def test_should_not_update_resource_booking_without_permission
    @request.session[:user_id] = @user.id
    should_not_update_resource_booking :forbidden, id: 1, resource_booking: @resource_booking_params
    should_not_update_resource_booking :forbidden, id: 1, project_id: @project.identifier, resource_booking: @resource_booking_params
  end

  def test_should_not_update_resource_booking_without_start_date
    @request.session[:user_id] = @admin.id
    rb_params = @resource_booking_params.merge(start_date: '')
    should_not_update_resource_booking :success, id: 1, resource_booking: rb_params
    should_not_update_resource_booking :success, id: 1, project_id: @project.identifier, resource_booking: rb_params
  end

  def test_should_not_update_resource_booking_for_anonymous
    should_not_update_resource_booking :unauthorized, id: 1, resource_booking: @resource_booking_params
    should_not_update_resource_booking :unauthorized, id: 1, project_id: @project.identifier, resource_booking: @resource_booking_params
  end

  def test_should_send_mail_after_update_resource_booking
    @request.session[:user_id] = @admin.id
    ActionMailer::Base.deliveries.clear
    with_settings :notified_events => %w(resource_updated) do
      assert_difference(-> { ActionMailer::Base.deliveries.size }, 2) do
        should_update_resource_booking id: 1, resource_booking: @resource_booking_params
      end
    end
  end

  def test_should_not_update_resource_booking_with_date_offsets
    @request.session[:user_id] = @admin.id
    should_update_resource_booking id: 1, start_date_offset: 10
    should_update_resource_booking id: 1, start_date_offset: -10

    should_update_resource_booking id: 1, end_date_offset: 10
    should_update_resource_booking id: 1, end_date_offset: -10

    should_update_resource_booking id: 1, start_date_offset: 10, end_date_offset: 10

    should_update_resource_booking id: 1, project_id: @project.identifier, start_date_offset: 10
  end

  def test_should_update_resource_booking_when_end_date_more_than_issue_due_date
    @request.session[:user_id] = @admin.id
    rb_params = @resource_booking_params.merge(start_date: Date.today, end_date: 11.day.from_now.to_date)
    should_update_resource_booking id: 1, resource_booking: rb_params
    should_validate_with_warnings ResourceBooking.find(1)

    should_update_resource_booking id: 1, project_id: @project.identifier, resource_booking: rb_params
    should_validate_with_warnings ResourceBooking.find(1)
  end

  def test_validation_by_issue_estimated_hours
    @request.session[:user_id] = @admin.id
    rb_params = @resource_booking_params.merge(end_date: 10.day.from_now.to_date)
    assert Issue.find(rb_params[:issue_id]).update(estimated_hours: 200)

    should_update_resource_booking id: 1, resource_booking: rb_params
    should_validate_with_warnings ResourceBooking.find(1)

    should_update_resource_booking id: 1, project_id: @project.identifier, resource_booking: rb_params
    should_validate_with_warnings ResourceBooking.find(1)
  end

  # === Action :destroy ===

  def test_should_destroy_resource_booking_for_admin
    @request.session[:user_id] = @admin.id
    # From top menu Resources
    should_destroy_resource_booking(id: 1)
    # From project menu Resources
    should_destroy_resource_booking(id: 2, project_id: @project.identifier)
  end

  def test_should_destroy_resource_booking_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :edit_booking
    should_destroy_resource_booking(id: 1)
    should_destroy_resource_booking(id: 2, project_id: @project.identifier)
  end

  def test_should_not_destroy_resource_booking_without_permission
    @request.session[:user_id] = @user.id
    should_not_destroy_resource_booking :forbidden, id: 1
    should_not_destroy_resource_booking :forbidden, id: 2, project_id: @project.identifier
  end

  def test_should_not_destroy_resource_booking_for_anonymous
    should_not_destroy_resource_booking :unauthorized, id: 1
    should_not_destroy_resource_booking :unauthorized, id: 2, project_id: @project.identifier
  end

  # === Action :issues_autocomplete ===

  def test_should_get_issues_autocomplete
    @request.session[:user_id] = @admin.id

    # Search by different projects
    should_get_issues_autocomplete(
      Issue.build_issues_select2_data(Issue.where(id: [1, 2, 3, 7, 8, 11, 12]), @user),
      project_id: @project.id, user_id: @user.id, q: ''
    )

    should_get_issues_autocomplete(
      Issue.build_issues_select2_data(Issue.where(id: 4), @user),
      project_id: @second_project.id, user_id: @user.id, q: ''
    )

    # Search with different users
    should_get_issues_autocomplete(
      Issue.build_issues_select2_data(Issue.where(id: [1, 2, 3, 7, 8, 11, 12]), @second_user),
      project_id: @project.id, user_id: @second_user.id, q: ''
    )

    # Search by issue id
    should_get_issues_autocomplete(
      Issue.build_issues_select2_data(Issue.where(id: [1, 3]), @user),
      project_id: @project.id, user_id: @user.id, q: '1'
    )
    should_get_issues_autocomplete(
      Issue.build_issues_select2_data(Issue.where(id: 1), @user),
      project_id: @project.id, user_id: @user.id, q: '#1'
    )

    # Search with different query strings
    should_get_issues_autocomplete([], project_id: @project.id, user_id: @user.id, q: 'z')
    should_get_issues_autocomplete(
      Issue.build_issues_select2_data(Issue.where(id: [7, 8, 11, 12]), @user),
      project_id: @project.id, user_id: @user.id, q: 'issue'
    )
  end

  def test_should_not_access_issues_autocomplete_for_anonymous
    check_get_xhr_request :issues_autocomplete, :unauthorized, project_id: @project.id, user_id: @admin.id, q: ''
  end

  private

  def check_get_xhr_request(action, response_status, params = {})
    compatible_xhr_request :get, action, params
    assert_response response_status
  end

  def check_get_index(response_status, params = {})
    compatible_request :get, :index, params
    assert_response response_status
  end

  def check_get_new(response_status, params = {})
    check_get_xhr_request :new, response_status, params
  end

  def check_get_edit(response_status, params = {})
    check_get_xhr_request :edit, response_status, params
  end

  def should_create_resource_booking(params)
    assert_difference('ResourceBooking.count') do
      compatible_xhr_request :post, :create, params
    end
    assert_response :success
    assert_equal flash[:notice], l(:notice_successful_create)
  end

  def should_not_create_resource_booking(response_status, params)
    assert_difference('ResourceBooking.count', 0) do
      compatible_xhr_request :post, :create, params
    end
    assert_response response_status
  end

  def should_update_resource_booking(params)
    rb_prev = ResourceBooking.find(params[:id])

    compatible_xhr_request :post, :update, params
    assert_response :success
    assert_equal flash[:notice], l(:notice_successful_update)

    rb_current = ResourceBooking.find(params[:id])
    (params[:resource_booking] || []).each do |attr, val|
      assert_equal rb_current.send(attr), val, "Incorrect resource booking attribute: #{attr}"
    end

    if params[:start_date_offset]
      assert_equal rb_current.start_date, rb_prev.start_date + params[:start_date_offset].days
    end

    if params[:end_date_offset]
      assert_equal rb_current.end_date, rb_prev.end_date + params[:end_date_offset].days
    end
  end

  def should_not_update_resource_booking(response_status, params)
    resource_booking = ResourceBooking.find(params[:id])
    compatible_xhr_request :post, :update, params

    assert_response response_status
    assert_equal resource_booking.updated_at, resource_booking.reload.updated_at
  end

  def should_destroy_resource_booking(params)
    assert_difference('ResourceBooking.count', -1) do
      compatible_xhr_request :delete, :destroy, params
    end
    assert_response :success
    assert_equal flash[:notice], l(:notice_successful_delete)
  end

  def should_not_destroy_resource_booking(response_status, params)
    assert_difference('ResourceBooking.count', 0) do
      compatible_xhr_request :delete, :destroy, params
    end
    assert_response response_status
  end

  def should_get_issues_autocomplete(expected_groups, params)
    check_get_xhr_request :issues_autocomplete, :success, params
    assert_equal expected_groups.to_json, response.body
  end

  def should_split_resource_booking(params)
    assert_difference('ResourceBooking.count') do
      compatible_xhr_request :post, :split, params
    end
    assert_response :success
    assert_equal flash[:notice], l(:notice_successful_create)

    resource_booking = ResourceBooking.find(params[:id])
    split_date = resource_booking.start_date + params[:split_offset].days
    assert_equal resource_booking.end_date, split_date - 1.day
    assert_equal ResourceBooking.order('id DESC').first.start_date, split_date
  end

  def should_not_split_resource_booking(response_status, params)
    resource_booking = ResourceBooking.find(params[:id])
    assert_difference('ResourceBooking.count', 0) do
      compatible_xhr_request :post, :split, params
    end
    assert_response response_status
    assert_equal resource_booking.updated_at, resource_booking.reload.updated_at
  end

  def should_validate_with_warnings(resource_booking, number_of_warnings = 1)
    assert resource_booking.valid?
    assert_equal number_of_warnings, resource_booking.warnings.size
  end
end
