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
      class ProjectSchedule
        include Redmine::Utils::DateCalculation

        attr_reader :project, :user_schedules, :capacity_hours, :allocated_hours, :spent_hours

        def initialize(project, date_from, date_to, resource_bookings, time_entries)
          @project = project
          @date_from = date_from
          @date_to = date_to
          @resource_bookings = resource_bookings
          @time_entries = time_entries

          @user_schedules = build_user_schedules(@date_from, @date_to, @resource_bookings, @time_entries)
          @capacity_hours = @user_schedules.sum(&:capacity_hours)
          @allocated_hours = @resource_bookings.sum(&:hours_per_day)
          @spent_hours = @time_entries.sum(&:hours)
        end

        def workload_cards
          @workload_cards ||=
            @user_schedules.map(&:plans).transpose
              .map { |plans| Components::ProjectWorkloadCard.new(plans) }
        end

        def versions_cards
          @versions_cards ||= begin
            return [] if versions.blank?

            version_groups_by_due_date = versions.group_by(&:effective_date)
            (@date_from..@date_to).map do |day|
              Components::VersionsCard.new(version_groups_by_due_date[day].to_a)
            end
          end
        end

        private

        def versions
          @versions ||=
            (project ? project.versions : Version)
              .where("#{Version.table_name}.effective_date BETWEEN ? AND ?", @date_from, @date_to)
              .to_a
        end

        def build_user_schedules(date_from, date_to, resource_bookings, time_entries)
          resource_bookings_groups_by_user_id = resource_bookings.group_by(&:assigned_to_id)
          time_entries_groups_by_user_id = time_entries.group_by(&:user_id)
          users = (resource_bookings.map(&:assigned_to) + time_entries.map(&:user)).uniq(&:id)

          users.map do |user|
            Helpers::UserSchedule.new(
              user,
              date_from,
              date_to,
              resource_bookings_groups_by_user_id[user.id].to_a,
              time_entries_groups_by_user_id[user.id].to_a
            )
          end
        end
      end
    end
  end
end
