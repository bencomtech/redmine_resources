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
      class BookedCardProgressBar < BaseComponent
        def initialize(date, issue, project, spent_hours, planned_hours)
          @date = date
          @issue = issue
          @project = project
          @spent_hours = spent_hours
          @planned_hours = planned_hours
          @overload = @spent_hours - @planned_hours
        end

        def render
          <<-HTML.html_safe
            <table class="progress spent" style="width: 100%; float: none; display: table;">
              <tbody>
              <tr>
                #{render_log_time}
                #{render_progress_bar}
              </tr>
              </tbody>
            </table>
          HTML
        end

        private

        def render_log_time
          if User.current.allowed_to?(:log_time, @project)
            %(<td class="log-time">#{link_to l(:button_log_time), log_time_url, class: 'icon icon-time-add'}</td>).html_safe
          end
        end

        def render_progress_bar
          label = l(:label_resources_f_hour_short, value: to_int_if_whole(@spent_hours))

          if @spent_hours == 0
            render_progress_line(label, 100, 'todo')
          elsif @spent_hours == @planned_hours
            render_progress_line(label, 100, 'planned')
          elsif @spent_hours < @planned_hours
            progress_bar_width = (@spent_hours * 100).fdiv(@planned_hours).to_i
            render_progress_line(label, progress_bar_width, 'underload') +
              render_progress_line(nil, 100 - progress_bar_width, 'todo')
          else
            progress_bar_width = (@planned_hours * 100).fdiv(@spent_hours).to_i
            render_progress_line(label, progress_bar_width, 'underload') +
              render_progress_line(nil, 100 - progress_bar_width, 'overload')
          end
        end

        def render_progress_line(label, width, css_class)
          %(<td style="width: #{width}%;" class="progress-line #{css_class}">#{label}</td>).html_safe
        end

        def log_time_url
          new_time_entry_path(project_id: @project, issue_id: @issue, time_entry: { spent_on: @date })
        end
      end
    end
  end
end
