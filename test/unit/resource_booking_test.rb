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

class ResourceBookingTest < ActiveSupport::TestCase
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

    EnabledModule.create(project: @project, name: 'resources')
    EnabledModule.create(project: @second_project, name: 'resources')

    # Allow view resources for developers (user 3 in project 1 & user 2 in project 2)
    Role.where(:id => [2]).each do |r|
      r.permissions << :view_resources
      r.save
    end
  end

  def test_visible_returns_only_available_bookings_for_user
    test_cases = [
      [@admin, ResourceBooking.all.map(&:id)],
      [@user, [3]],
      [@second_user, [1,2]],
    ]

    test_cases.each do |user, bookings|
      User.current = user
      assert_equal bookings, ResourceBooking.visible.map(&:id)
    end
  end

end
