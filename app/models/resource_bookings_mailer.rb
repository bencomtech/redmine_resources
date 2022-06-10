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

class ResourceBookingsMailer < Mailer
  SENDING_METHOD = (Redmine::VERSION.to_s < '4.0' ? 'deliver' : 'deliver_later').freeze

  def resource_booking_create(user, resource_booking)
    prepare_variables(resource_booking)
    mail to: user, subject: l(:label_resource_booking_added)
  end

  def self.deliver_resource_booking_create(resource_booking)
    resource_booking.email_users.each do |user|
      resource_booking_create(user, resource_booking).send(SENDING_METHOD)
    end
  end

  def resource_booking_update(user, resource_booking)
    prepare_variables(resource_booking)
    mail to: user, subject: l(:label_resource_booking_updated)
  end

  def self.deliver_resource_booking_update(resource_booking)
    resource_booking.email_users.each do |user|
      resource_booking_update(user, resource_booking).send(SENDING_METHOD)
    end
  end

  private

  def prepare_variables(resource_booking)
    @resource_booking = resource_booking
    @project = resource_booking.project
    @issue = resource_booking.issue
    if @issue.present?
      @issue_url = url_for(controller: 'issues', action: 'show', id: @issue)
    else
      @project_url = url_for(controller: 'projects', action: 'show', id: @project)
    end
    @author = @resource_booking.author
  end
end
