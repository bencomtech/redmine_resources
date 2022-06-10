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

resources :resource_bookings do
  get :issues_autocomplete, on: :collection
  post :split, on: :member
end

match 'resource_bookings/new', to: 'resource_bookings#new', via: :post
match 'resource_bookings/:id', to: 'resource_bookings#update', via: :post, id: /\d+/

get '/projects/:project_id/resources', to: 'resource_bookings#index', as: 'project_resource_bookings'
