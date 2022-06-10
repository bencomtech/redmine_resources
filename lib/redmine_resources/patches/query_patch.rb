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
  module Patches
    module QueryPatch
      def self.included(base)
        base.class_eval do
          include InstanceMethods
        end
      end

      module InstanceMethods
        if Redmine::VERSION.to_s < '3.4'

          private

          def principals
            @principals ||= begin
              principal_collector = []
              if project
                principal_collector += Principal.member_of(project)
                unless project.leaf?
                  principal_collector += Principal.member_of(project.descendants.visible.all)
                end
              else
                principal_collector += Principal.member_of(all_projects)
              end
              principal_collector.uniq!
              principal_collector.sort!
              principal_collector.reject! { |p| p.is_a?(GroupBuiltin) }
              principal_collector
            end
          end

          def users
            principals.select {|p| p.is_a?(User)}
          end

          def assigned_to_values
            assigned_to_values = []
            assigned_to_values << ["<< #{l(:label_me)} >>", 'me'] if User.current.logged?
            assigned_to_values += (Setting.issue_group_assignment? ? principals : users).sort_by(&:status).collect { |s| [s.name, s.id.to_s] }
            assigned_to_values
          end
        end
      end
    end
  end
end

unless Query.included_modules.include?(RedmineResources::Patches::QueryPatch)
  Query.send(:include, RedmineResources::Patches::QueryPatch)
end
