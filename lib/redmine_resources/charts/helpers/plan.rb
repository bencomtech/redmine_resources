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
      class Plan
        attr_reader :date_title, :today_css_class, :week_day_css_class, :is_workday,
                    :workload_card, :booked_cards, :unbooked_cards, :allocated_hours, :spent_hours

        def initialize(date, is_workday, resource_bookings, time_entries)
          @date = date
          @date_title = I18n.l(@date, format: '%a, %d')
          @today_css_class = 'today' if @date == User.current.today

          @is_workday = is_workday
          @week_day_css_class = 'week-end' unless @is_workday

          @resource_bookings = resource_bookings
          @time_entries = time_entries
          @booked_time_entries = find_booked_time_entries(@resource_bookings, @time_entries)
          @unbooked_time_entries = @time_entries - @booked_time_entries
          @allocated_hours = @resource_bookings.sum(&:hours_per_day)
          @spent_hours = @time_entries.sum(&:hours)

          @workload_card = Components::WorkloadCard.new(@is_workday, @resource_bookings, @time_entries)
          @booked_cards = build_booked_cards(@date, @is_workday, @resource_bookings, @booked_time_entries)
          @unbooked_cards = build_unbooked_cards(@date, @unbooked_time_entries)
        end

        private

        def build_booked_cards(date, is_workday, resource_bookings, time_entries)
          time_entries_by_project_and_issue = time_entries.group_by do |time_entry|
            key_by(time_entry.project, time_entry.issue)
          end

          resource_bookings.inject([]) do |booked_cards, resource_booking|
            issue = resource_booking.issue
            project = resource_booking.project
            time_entries = time_entries_by_project_and_issue[key_by(project, issue)] || []

            if is_workday || time_entries.present?
              booked_cards << Components::BookedCard.new(date, issue, project, resource_booking, time_entries)
            end

            booked_cards
          end
        end

        def build_unbooked_cards(date, time_entries)
          time_entries_by_project_and_issue = time_entries.group_by do |time_entry|
            key_by(time_entry.project, time_entry.issue)
          end

          time_entries_by_project_and_issue.inject([]) do |unbooked_cards, (key, time_entries)|
            issue = time_entries.first.issue
            project = time_entries.first.project
            unbooked_cards << Components::UnbookedCard.new(date, issue, project, time_entries)
            unbooked_cards
          end
        end

        def find_booked_time_entries(resource_bookings, time_entries)
          booked_issue_ids = resource_bookings.map(&:issue_id).compact
          booked_project_ids = resource_bookings.select { |rb| rb.issue.blank? }.map(&:project_id)
          time_entries.select do |time_entry|
            if time_entry.issue_id
              booked_issue_ids.include?(time_entry.issue_id)
            else
              booked_project_ids.include?(time_entry.project_id)
            end
          end
        end

        def key_by(project, issue)
          "#{project.id}-#{issue.try(:id)}"
        end
      end
    end
  end
end
