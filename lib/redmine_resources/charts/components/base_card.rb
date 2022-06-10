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
      class BaseCard < BaseComponent
        DESCRIPTION_LINE_HEIGHT = 1.25 # em
        CARD_HEIGHT_COEFFICIENT = 2 * DESCRIPTION_LINE_HEIGHT # em

        def initialize(date, issue, project, resource_booking, time_entries)
          @date = date
          @issue = issue
          @project = project
          @resource_booking = resource_booking
          @time_entries = time_entries

          @spent_hours = @time_entries.sum(&:hours)
          @description = @issue ? @issue.subject : @project.name
        end

        protected

        def project_heading
          link_to l(:label_project), project_path(@project), class: 'icon icon-project'
        end

        def issue_heading
          h("#{@issue.tracker} ") + link_to_issue(@issue, subject: false, tracker: false)
        end

        def render_card_heading
          @issue ? issue_heading : project_heading
        end
      end
    end
  end
end
