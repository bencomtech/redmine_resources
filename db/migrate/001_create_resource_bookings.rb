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

class CreateResourceBookings < (Rails.version < '5.1') ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    create_table :resource_bookings do |t|
      t.references :project, index: true, foreign_key: true, null: false
      t.integer :assigned_to_id, index: true, null: false
      t.references :issue, index: true, foreign_key: true
      t.integer :author_id, index: true, null: false

      t.datetime :start_date, null: false
      t.datetime :end_date

      t.float :hours_per_day, null: false
      t.text :notes
      t.timestamps null: false
    end

    add_foreign_key :resource_bookings, :users, column: :assigned_to_id
    add_foreign_key :resource_bookings, :users, column: :author_id
  end
end
