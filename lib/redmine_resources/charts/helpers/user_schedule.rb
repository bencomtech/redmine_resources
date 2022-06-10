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

module RedmineResources
  module Charts
    module Helpers
      class UserSchedule
        include Redmine::Utils::DateCalculation

        attr_reader :user, :resource_bookings, :plans, :capacity_hours, :allocated_hours, :spent_hours

        def initialize(user, date_from, date_to, resource_bookings, time_entries)
          raise ArgumentError unless user

          @user = user
          @date_from = date_from
          @date_to = date_to
          @resource_bookings = resource_bookings
          @time_entries = time_entries

          @plans = build_plans(@date_from, @date_to, @resource_bookings, @time_entries)
          @capacity_hours = RedmineResources.default_workday_length * working_days(@date_from, @date_to)
          @allocated_hours = @resource_bookings.sum(&:hours_per_day)
          @spent_hours = @time_entries.sum(&:hours)
        end

        private

        def build_plans(date_from, date_to, resource_bookings, time_entries)
          (date_from..date_to).map do |day|
            resource_bookings_by_day = resource_bookings.select { |rb| rb.interval.cover?(day) }
            time_entries_by_day = time_entries.select { |time_entry| time_entry.spent_on == day }
            Plan.new(day, non_working_week_days.exclude?(day.cwday), resource_bookings_by_day, time_entries_by_day)
          end
        end
      end
    end
  end
end
