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
      class VersionsCard < BaseComponent
        def initialize(versions)
          @versions = versions
        end

        def render
          <<-HTLM.html_safe
            <div class="versions-card">
              #{@versions.map { |x| render_version(x) }.join }
            </div>
          HTLM
        end

        private

        def link_to_version(version, options = {})
          return '' unless version && version.is_a?(Version)
          options = { title: format_date(version.effective_date)}.merge(options)
          link_to h(version), version_path(version), options
        end

        def render_version(version)
          <<-HTLM.html_safe
            <div class="version">
              <span class="icon icon-package">#{h(version.project)}</span> - #{link_to_version(version)}
            </div>
          HTLM
        end
      end
    end
  end
end
