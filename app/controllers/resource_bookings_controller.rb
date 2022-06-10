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

class ResourceBookingsController < ApplicationController
  menu_item :resources

  before_action :require_login, :find_project_by_project_id, :find_user_by_user_id, only: :issues_autocomplete
  before_action :find_optional_project, except: :issues_autocomplete
  before_action :find_resource_booking, only: [:destroy, :split]
  before_action :build_resource_booking_from_params, only: [:new, :create, :edit, :update]
  before_action :set_user_blocks_to_update, only: [:new, :create, :update, :destroy, :split]

  helper :issues
  helper :queries
  include QueriesHelper

  def index
    retrieve_query
    if @query.valid?
      @rb_chart = @query.chart_class.new(@project, @query, params)
    end
  end

  def new
  end

  def create
    if @resource_booking.save
      add_to_flash_resource_booking_warnings
      render_update_chart l(:notice_successful_create)
    else
      render :new
    end
  end

  def edit
    # Run validations (There is no method "validate" in Rails 3)
    @resource_booking.valid?
  end

  def update
    if @resource_booking.save
      add_to_flash_resource_booking_warnings
      render_update_chart l(:notice_successful_update)
    else
      render :edit
    end
  end

  def destroy
    if @resource_booking.destroy
      render_update_chart l(:notice_successful_delete)
    else
      flash.now[:error] = l(:notice_could_not_delete)
      render partial: 'update_chart'
    end
  end

  def split
    split_date = @resource_booking.start_date + params[:split_offset].to_i.days
    new_resource_booking = @resource_booking.dup
    @resource_booking.end_date = split_date - 1.day
    new_resource_booking.start_date = split_date

    ResourceBooking.transaction do
      if @resource_booking.save && new_resource_booking.save
        render_update_chart l(:notice_successful_create)
      else
        flash.now[:error] = l(:error_save_failed)
        render partial: 'update_chart'
        raise ActiveRecord::Rollback
      end
    end
  end

  def issues_autocomplete
    @issues = []
    q = (params[:q] || params[:term]).to_s.strip
    scope = Issue
    scope = scope.includes(:tracker).where(project_id: @project.id) if @project.present?

    if q.present?
      if q.match(/\A#?(\d+)\z/)
        @issues << scope.find_by_id($1.to_i)
      end
    end

    scope = scope.like(q).select_with_sorting_by_groups(@user.id)
    @issues += scope.limit(Issue::SELECT2_ISSUES_LIMIT).to_a
    @issues.compact!

    render json: Issue.build_issues_select2_data(@issues, @user)
  end

  private

  def add_to_flash_resource_booking_warnings
    if @resource_booking.warnings.present?
      flash.now[:warning] = @resource_booking.warnings.full_messages.join('; ')
    end
  end

  def render_update_chart(notice)
    if @user_blocks
      flash.now[:notice] = notice
      render partial: 'update_chart', locals: { resize: true }
    else
      flash[:notice] = notice
      render js: "window.location = '#{index_path}'"
    end
  end

  def set_user_blocks_to_update
    retrieve_query
    @query.add_filter('assigned_to_id', '=', [@resource_booking.assigned_to_id.to_s])
    return unless @query.valid?

    @user_blocks = { @resource_booking.assigned_to_id => RedmineResources::Charts::MonthViewBookingsChart.new(@project, @query) }

    assigned_to_id_was = @resource_booking.assigned_to_id_was
    if assigned_to_id_was && (@resource_booking.assigned_to_id != assigned_to_id_was)
      query = @query.dup
      query.add_filter('assigned_to_id', '=', [assigned_to_id_was.to_s])
      @user_blocks[assigned_to_id_was] = RedmineResources::Charts::MonthViewBookingsChart.new(@project, query)
    end
  end

  def find_resource_booking
    @resource_booking = ResourceBooking.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def build_resource_booking_from_params
    if params[:id].blank?
      @resource_booking = ResourceBooking.new(project: @project, author: User.current)
    else
      return unless find_resource_booking
    end

    @resource_booking.safe_attributes = params[:resource_booking]

    @resource_booking.start_date += params[:start_date_offset].to_i.days if params[:start_date_offset]
    if params[:end_date_offset]
      @resource_booking.end_date = @resource_booking.get_end_date + params[:end_date_offset].to_i.days
    end
  end

  # Retrieve query from session or build a new query
  def retrieve_query
    session_key = :resource_booking_query
    if params[:set_filter] || session[session_key].nil? || session[session_key][:project_id] != (@project ? @project.id : nil)
      # Give it a name, required to be valid
      @query = ResourceBookingQuery.new(name: '_', project: @project)
      @query.build_from_params(params)
      session[session_key] = { project_id: @query.project_id, filters: @query.filters, options: @query.options }
    else
      # retrieve from session
      session[session_key][:options][:date_from] = params[:date_from].to_date if params[:date_from]
      @query = ResourceBookingQuery.new(name: '_', filters: session[session_key][:filters], options: session[session_key][:options])
      @query.project = @project
    end
    @query
  end

  def index_path
    @project.blank? ? resource_bookings_path : project_resource_bookings_path(project_id: @project)
  end

  def find_user_by_user_id
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
