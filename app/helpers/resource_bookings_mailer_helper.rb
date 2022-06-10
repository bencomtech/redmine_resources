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

module ResourceBookingsMailerHelper
  include ResourceBookingsHelper

  def render_attributes(attributes, html = false)
    if html
      li_tags = attributes.map { |attribute| "<li><strong>#{attribute[:name]}</strong>: #{attribute[:value]}</li>" }
      content_tag('ul', li_tags.join("\n").html_safe, class: 'details')
    else
      attributes.map { |attribute| "* #{attribute[:name]}: #{attribute[:value]}" }.join("\n")
    end
  end

  def render_tooltip_issue_attributes(issue, html = false)
    render_attributes(tooltip_issue_attributes(issue, only_path: false), html)
  end
end
