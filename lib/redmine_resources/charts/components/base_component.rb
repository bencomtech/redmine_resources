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
      class BaseComponent
        include ApplicationHelper
        include ActionView::Helpers::UrlHelper
        include ActionView::Helpers::ControllerHelper
        include Rails.application.routes.url_helpers
        include ERB::Util
        include Redmine::I18n
        include Redmine::Utils::DateCalculation
        include RedmineResources::Charts::Helpers::ChartHelper

        def render
          raise NotImplementedError
        end
      end
    end
  end
end
