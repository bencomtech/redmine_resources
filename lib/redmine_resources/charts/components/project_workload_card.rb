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
      class ProjectWorkloadCard < BaseComponent
        attr_reader :today_css_class

        def initialize(plans)
          @plans = plans
          first_plan = plans.first
          @is_workday = first_plan.is_workday
          @today_css_class = first_plan.today_css_class
          @planned_hours = to_int_if_whole(@plans.sum(&:allocated_hours))
          @spent_hours = to_int_if_whole(@plans.sum(&:spent_hours))
        end

        def render
          if @is_workday
            <<-HTLM.html_safe
              <div class="workload-card gray">
                #{render_spent_hours if @spent_hours > 0}
                #{render_planned_hours if @planned_hours > 0}
              </div>
            HTLM
          end
        end

        private

        def render_spent_hours
          content_tag :div, l(:label_resources_f_hour_short, value: @spent_hours),
                      class: 'spent spent-time', style: 'display: block;'
        end

        def render_planned_hours
          "<p>#{@planned_hours} #{l(:field_hours_per_day_abbreviation)}</p>"
        end
      end
    end
  end
end
