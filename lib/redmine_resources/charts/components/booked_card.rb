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
    module Components
      class BookedCard < BaseCard
        def initialize(date, issue, project, resource_booking, time_entries)
          super

          @planned_hours = @resource_booking.hours_per_day
          @progress_bar = BookedCardProgressBar.new(@date, @issue, @project, @spent_hours, @planned_hours)
          @description_box_height = CARD_HEIGHT_COEFFICIENT * [@planned_hours, 24].min
        end

        def render
          <<-HTML.html_safe
            <div class="booking-card #{'ending' if @issue && @issue.due_date == @date} booking">
              <p class="project-name" style="display: block;">#{h(@project)}</p>
              <div class="issue-id tooltip">
                <span class="tip issue-spent">
                  #{render_resource_booking_tooltip(@resource_booking)}
                </span>
                <strong>#{render_card_heading}</strong>
                <span class="hours">#{l(:label_resources_f_hour_short, value: to_int_if_whole(@planned_hours))}</span>
              </div>
              <div class="description-box" style="height: #{@description_box_height}em;">
                <div class="text-box">
                  #{@description}
                </div>
              </div>
              #{@progress_bar.render}
            </div>
          HTML
        end
      end
    end
  end
end
