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

require_dependency 'version'

class RedmineResources::Charts::MonthViewBookingsChart < Redmine::Helpers::Gantt
  RED_BAR = 'red_bar'.freeze
  YELLOW_BAR = 'yellow_bar'.freeze
  GREEN_BAR = 'green_bar'.freeze

  MIN_ZOOM = 1
  MAX_ZOOM = 3

  SUBJECT_WIDTH = 330 # px
  HEADER_HEIGHT = 18 # px
  HEADERS_HEIGHT = 36 # 2 * header_height
  USER_LINE_HEIGHT = 34 # 8(padding-top) + 10(padding-bottom) + 16(height)
  PROJECT_LINE_HEIGHT = 28 # 28(height)
  ISSUE_LINE_HEIGHT = 20 # 20(height)
  ISSUES_GROUP_HEIGHT = 17 # 1(border-top) + 8(padding-top) + 8(padding-bottom)
  TOOLTIP_HEIGHT = 200

  TOTAL_HOURS = 'total_hours'.freeze
  LINE_TITLE_TYPES = [TOTAL_HOURS].freeze

  delegate :user_bar_label, :total_hours_bar_label, :hours_per_day_bar_label,
           :new_booking_path, :edit_path_for, :update_path_for, :split_path_for,
           to: :view

  def initialize(project, query, options = {})
    raise ArgumentError unless query

    options = options.dup

    @project = project
    @query = query

    zoom = (options[:zoom] || User.current.pref[:resource_booking_zoom]).to_i
    @zoom = (zoom >= MIN_ZOOM && zoom <= MAX_ZOOM) ? zoom : MIN_ZOOM
    months = (options[:months] || User.current.pref[:resource_booking_months]).to_i
    @months = (months > 0 && months < 25) ? months : 2
    # Save resource_booking parameters as user preference (zoom and months count)
    if (User.current.logged? && (@zoom != User.current.pref[:resource_booking_zoom] || @months != User.current.pref[:resource_booking_months]))
      User.current.pref[:resource_booking_zoom] = @zoom
      User.current.pref[:resource_booking_months] = @months
      User.current.preference.save
    end

    @date_from = @query ? @query.date_from : RedmineResources.beginning_of_week
    @date_to = (@date_from >> @months) - 1
    @subjects = ''
    @lines = ''
    @user_can_edit_booking = User.current.allowed_to?(:edit_booking, nil, global: true)
  end

  def common_params
    { controller: 'resource_bookings_controller', action: 'index', project_id: @project }
  end

  def params
    common_params.merge(zoom: zoom, date_from: date_from, months: months)
  end

  def params_previous
    common_params.merge(date_from: date_from << months, zoom: zoom, months: months)
  end

  def params_next
    common_params.merge(date_from: date_from >> months, zoom: zoom, months: months)
  end

  def render(options = {})
    options = {
      top: HEADERS_HEIGHT + 8,
      top_increment: 20,
      indent_increment: 20,
      indent: 4,
      zoom: column_width,
      subject_width: SUBJECT_WIDTH,
      g_width: ((date_to - date_from + 1) * column_width).to_i,
      render: :subject,
      format: :html
    }.merge(options)

    @subjects = '' unless options[:only] == :lines
    @lines = '' unless options[:only] == :subjects
    @number_of_user_rows = 0
    @number_of_project_rows = 0
    @number_of_issue_rows = 0
    @number_of_issue_groups = 0
    @height = nil

    render_resource_bookings(resource_bookings, options)

    @subjects_rendered = true unless options[:only] == :lines
    @lines_rendered = true unless options[:only] == :subjects
    render_end(options)
  end

  def render_resource_bookings(resource_bookings, options = {})
    resource_bookings.group_by(&:assigned_to_id).each do |key, value|
      user = value.first.assigned_to
      wrap(options[:only], :div, class: 'user-resource-bookings open', group_id: user.id) do
        render_resource_bookings_by_user(user, value, options)
      end
    end
  end

  def render_resource_bookings_by_user(user, resource_bookings, options = {})
    render_user(user, options)
    increment_indent(options) do
      resource_bookings.group_by(&:project_id).each do |key, value|
        style =
          unless show_project_lines
            issue_lines_count = build_resource_bookings_map(value).size
            "height: #{issue_lines_count * ISSUE_LINE_HEIGHT}px"
          end

        wrap(options[:only], :div, class: 'issues-group', style: style) do
          @number_of_issue_groups += 1
          render_resource_bookings_by_project(value, options)
        end
      end

      wrap(options[:only], :div, class: 'extra-line') do
        project = @project || allowed_projects.detect { |project| user.respond_to?(:member_of?) && user.member_of?(project) }
        render_resource_bookings_by_issue(nil, [], options, project, user)
      end
    end
  end

  def render_resource_bookings_by_project(resource_bookings, options = {})
    min_date = resource_bookings.map(&:start_date).min.to_date
    options[:versions_date_from] = min_date < @date_from ? @date_from : min_date

    project = resource_bookings.first.project
    versions = versions_by(project, options[:versions_date_from], @date_to)
    options[:versions] = versions
    options[:versions_date_to] = versions.map(&:effective_date).max.to_date if versions.present?
    render_project(project, options)

    increment_indent(options) do
      approved_bookings = resource_bookings.reject(&:new_record?)

      if @query.show_issues
        bookings = approved_bookings.group_by(&:issue_id)
        render_resource_bookings_issues_group(bookings[nil], options) if bookings[nil]
        bookings.except(nil).each { |key, value| render_resource_bookings_issues_group(value, options) }
      else
        render_resource_bookings_by_issue_without_subjects(approved_bookings, options)
      end
    end
  end

  def render_resource_bookings_by_issue_without_subjects(resource_bookings, options = {})
    build_resource_bookings_map(resource_bookings).each do |bookings|
      render_resource_bookings_by_issue(nil, bookings, options)
    end
  end

  def render_resource_bookings_issues_group(resource_bookings, options = {})
    resource_bookings_map = build_resource_bookings_map(resource_bookings, true)

    # Render first line of bars
    resource_bookings = resource_bookings_map.first
    issue = resource_bookings.first.issue
    options[:current_issue] = nil
    render_resource_bookings_by_issue(issue, resource_bookings, options)

    # Render remaining lines
    options[:current_issue] = issue
    resource_bookings_map[1..-1].each do |bookings|
      render_resource_bookings_by_issue(issue, bookings, options)
    end
  end

  def render_resource_bookings_by_issue(issue, resource_bookings, options = {}, project = nil, user = nil)
    options[:resource_bookings] = resource_bookings

    resource_booking = resource_bookings.try(:first)
    project ||= resource_booking.try(:project)
    user ||= resource_booking.try(:assigned_to)
    wrap(:lines, :div, class: 'issue-line', 'data-new-url' => new_booking_path(project, user, issue, @date_from, @date_from)) do
      render_button_add_booking if User.current.allowed_to?(:add_booking, @project, global: true)
      render_object_row(issue, options)
    end
  end

  def render_button_add_booking
    @lines << view.content_tag(:div, l(:button_add),
                               style: "width: #{column_width - 2}px",
                               class: 'task button-add-booking')
  end

  def render_user(user, options = {})
    options[:workday_length] = workday_length_by(user)
    options[:user_line_map] = user_line_map(user, resource_bookings_by(user))
    render_object_row(user, options)
  end

  def render_project(project, options = {})
    render_object_row(project, options)
  end

  def render_object_row(object, options)
    class_name = object.class.name.downcase
    send("subject_for_#{class_name}", object, options) unless options[:only] == :lines
    send("line_for_#{class_name}", object, options) unless options[:only] == :subjects
    options[:top] += options[:top_increment]
    increment_number_of_rows(object)
  end

  def increment_number_of_rows(object)
    if object.is_a? User
      @number_of_user_rows += 1
    elsif object.is_a? Project
      @number_of_project_rows += 1
    else
      @number_of_issue_rows += 1
    end
  end

  def subject_for_user(user, _options)
    output = view.subject_for_user(user)
    @subjects << output
    output
  end
  alias :subject_for_group :subject_for_user

  def subject_for_issue(issue, options)
    current_issue = options[:current_issue]
    if current_issue && current_issue == issue
      subject_for_nilclass(issue, options)
    else
      subject(issue.subject, options, issue)
    end
  end

  def subject_for_nilclass(_object, options)
    output = view.content_tag(:div, '',
      class: 'issue-subject',
      style: "margin-left:#{2 * options[:indent_increment]}px;"
    )

    @subjects << output
    output
  end

  def line_for_project(project, options)
    line(options[:versions_date_from], options[:versions_date_to], nil, true, project.name, options, project)
  end

  def line_for_user(user, options)
    return unless user.is_a?(User)

    wrap(:lines, :div, class: 'user-line') do
      i = 0
      user_line_map = options[:user_line_map]
      while i < user_line_map.length
        if user_line_map[i]
          options[:load_hours] = user_line_map[i]
          options[:task_bar_class] = task_bar_color_class(user_line_map[i])

          from = @date_from.next_day(i)
          i = find_date_to_index(i, user_line_map)
          to = @date_from.next_day(i)
          line(from, to, 100, true, user_bar_label(user_line_map[i]), options, user)
        end
        i += 1
      end
    end
  end

  alias :line_for_group :line_for_user

  def line_for_issue(issue, options)
    if issue.is_a?(Issue)
      options[:resource_bookings].each do |rb|
        interval = rb.interval
        options[:resource_booking] = rb
        options[:task_bar_class] = rb.new_record? ? 'unapproved' : 'task_done'
        options[:bar_title_css_class] = @bar_title_css_class
        line(interval.begin, interval.end, 100, nil, issue_bar_label(rb), options, issue)
      end
    end
  end

  def line_for_nilclass(_object, options)
    line_for_issue(Issue.new, options)
  end

  def html_subject(params, subject, object)
    content = html_subject_content(object) || subject
    tag_options = {}
    case object
    when Issue
      tag_options[:id] = "issue-#{object.id}"
      tag_options[:class] = params[:resource_bookings].first.new_record? ? 'issue-subject ghost' : 'issue-subject'
      tag_options[:title] = object.subject
      tag_options[:style] = "margin-left:#{2 * params[:indent_increment]}px;"
    when Project
      tag_options[:class] = 'project-subject'
      tag_options[:style] = "margin-left:#{params[:indent_increment]}px;"
    end
    output = view.content_tag(:div, content, tag_options)
    @subjects << output
    output
  end

  def subject(label, options, object = nil)
    send "#{options[:format]}_subject", options, label, object
  end

  def line(start_date, end_date, done_ratio, markers, label, options, object = nil)
    options[:zoom] ||= 1
    options[:g_width] ||= (self.date_to - self.date_from + 1) * options[:zoom]
    coords = coordinates(start_date, end_date, done_ratio, options[:zoom])
    send "#{options[:format]}_task", options, coords, markers, label, object
  end

  def increment_indent(options, factor = 1)
    options[:indent] += options[:indent_increment] * factor
    if block_given?
      yield
      decrement_indent(options, factor)
    end
  end

  def decrement_indent(options, factor = 1)
    increment_indent(options, -factor)
  end

  def html_subject_content(object)
    case object
    when Issue
      issue = object
      css_classes = ''
      css_classes << ' issue-overdue' if issue.overdue?
      css_classes << ' issue-behind-schedule' if issue.behind_schedule?
      css_classes << ' icon icon-issue' unless Setting.gravatar_enabled? && issue.assigned_to
      css_classes << ' issue-closed' if issue.closed?
      if issue.start_date && issue.due_before && issue.done_ratio
        progress_date = calc_progress_date(issue.start_date,
                                           issue.due_before, issue.done_ratio)
        css_classes << ' behind-start-date' if progress_date < self.date_from
        css_classes << ' over-end-date' if progress_date > self.date_to
      end
      s = "".html_safe
      if issue.assigned_to.present?
        assigned_string = l(:field_assigned_to) + ": " + issue.assigned_to.name
        s << view.avatar(issue.assigned_to,
                         :class => 'gravatar icon-gravatar',
                         :size => 13,
                         :title => assigned_string).to_s.html_safe
      end
      s << view.link_to_issue(issue).html_safe
      view.content_tag(:span, s, :class => css_classes).html_safe
    when Version
      version = object
      html_class = ""
      html_class << 'icon icon-package '
      html_class << (version.behind_schedule? ? 'version-behind-schedule' : '') << " "
      html_class << (version.overdue? ? 'version-overdue' : '')
      html_class << ' version-closed' unless version.open?
      if version.start_date && version.due_date && version.completed_percent
        progress_date = calc_progress_date(version.start_date,
                                           version.due_date, version.completed_percent)
        html_class << ' behind-start-date' if progress_date < self.date_from
        html_class << ' over-end-date' if progress_date > self.date_to
      end
      s = view.link_to_version(version).html_safe
      view.content_tag(:span, s, :class => html_class).html_safe
    when Project
      project = object
      html_class = ""
      html_class << 'icon icon-projects '
      html_class << (project.overdue? ? 'project-overdue' : '')
      s = view.link_to_project(project).html_safe
      view.content_tag(:span, s, :class => html_class).html_safe
    end
  end

  def html_task(params, coords, markers, label, object)
    output = send("html_task_for_#{object.class.to_s.downcase}", params, coords, markers, label, object)
    @lines << output.html_safe
    output
  end

  def coordinates(start_date, end_date, progress, zoom = nil)
    zoom ||= @zoom
    coords = {}
    if start_date == self.date_to
      coords[:bar_start] = start_date - self.date_from
      coords[:bar_end] = coords[:bar_start] + 1
    elsif end_date == self.date_from
      coords[:bar_start] = 0
      coords[:bar_end] = 1
    else
      return super
    end

    # Transforms dates into pixels witdh
    coords.keys.each do |key|
      coords[key] = (coords[key] * zoom).floor
    end
    coords
  end

  def column_width
    { 1 => 30, 2 => 60, 3 => 100 }[@zoom]
  end

  def height
    @height ||= calculate_height
  end

  def netto_height
    height - TOOLTIP_HEIGHT
  end

  private

  def resource_bookings
    @resource_bookings ||= @query.chart_bookings(@date_from, @date_to)
  end

  def resource_bookings_by_users
    @resource_bookings_by_users ||= @query.resource_bookings_by_users(@date_from, @date_to)
  end

  def resource_bookings_grouped_by_users
    @resource_bookings_grouped_by_users ||= resource_bookings_by_users.group_by(&:assigned_to_id)
  end

  def resource_bookings_by(user)
    resource_bookings_grouped_by_users[user.id]
  end

  def allowed_projects
    @allowed_projects ||= ResourceBooking.allowed_projects
  end

  def html_task_for_issue(params, coords, _markers, label, object)
    output = ''
    # Renders the task bar
    if coords[:bar_start] && coords[:bar_end]
      output << html_issue_task_bar(label, params)
    end

    output << view.content_tag(:div, '', class: 'split-line') if params[:resource_booking].persisted?

    # Renders the tooltip
    if object.is_a?(Issue) && coords[:bar_start] && coords[:bar_end]
      output << html_tooltip(params, coords)
    end

    style = "left:#{coords[:bar_start]}px;"
    style << "width:#{coords[:bar_end] - coords[:bar_start] - 2}px;"

    options = { style: style, class: 'booking-bar' }
    if @user_can_edit_booking
      options[:class] << ' editable'
      options[:edit_url] = edit_path_for(params[:resource_booking])
      options[:update_url] = update_path_for(params[:resource_booking])
    end

    view.content_tag(:div, output.html_safe, options)
  end

  def html_task_for_project(params, coords, markers, _label, _object)
    output = ''

    show_project_lines ? view.content_tag(:div, output.html_safe, class: 'project-line') : ''
  end

  def version_max_width(version, next_version)
    ((next_version.due_date - version.due_date) * column_width).to_i if next_version
  end

  def html_task_for_version(params, coords, _markers, label, _object)
    output = ''
    css = 'task version'

    if coords[:end]
      style = "top: 12px;"
      style << "left: #{coords[:end] + params[:zoom]}px;"
      style << "width: 15px;"
      style << "z-index: 1;"
      output << view.content_tag(:div, '&nbsp;'.html_safe, title: label, style: style, class: "#{css} marker")
    end

    if label
      style = "left:#{(coords[:bar_end] || 0)}px;"
      style << "max-width: #{params[:version_max_width]}px;" if params[:version_max_width]
      output << view.content_tag(:div, label, style: style, class: "#{css} label")
    end

    output
  end

  def html_task_for_user(params, coords, _markers, label, object)
    output = ''
    if coords[:bar_start] && coords[:bar_end]
      output << html_task_bar(label, params, coords, object)
    end

    if coords[:bar_start] && coords[:bar_end]
      output << html_tooltip_for_user(params, coords)
    end

    output
  end

  def html_task_bar(label, params, coords, _object)
    style = "left:#{coords[:bar_start]}px;"
    style << "width:#{coords[:bar_end] - coords[:bar_start] - 2}px;"
    html_class = "task #{params[:task_bar_class]} #{params[:bar_title_css_class]}"
    view.content_tag(
      :div,
      "&nbsp;#{label}".html_safe,
      style: style,
      class: html_class
    )
  end

  def html_issue_task_bar(label, params)
    view.content_tag(:div,
      "&nbsp;#{label}".html_safe,
      style: 'left: 0; padding: 0 6px; width: calc(100% - 12px);',
      class: "task #{params[:task_bar_class]} #{params[:bar_title_css_class]}"
    )
  end

  def html_tooltip(params, coords)
    s = view.render_resource_booking_tooltip(params[:resource_booking])
    s = view.content_tag(:span, s.html_safe, class: 'tip')
    style = 'position: absolute;'
    style << "width:#{coords[:bar_end] - coords[:bar_start]}px;"
    view.content_tag(:div, s.html_safe, style: style, class: 'tooltip')
  end

  def html_tooltip_for_user(params, coords)
    s = view.render_load_tooltip(params[:load_hours], params[:workday_length])
    s = view.content_tag(:span, s.html_safe, class: 'tip')
    style = 'position: absolute;'
    style << "left:#{coords[:bar_start]}px;"
    style << "width:#{coords[:bar_end] - coords[:bar_start]}px;"
    view.content_tag(:div, s.html_safe, style: style, class: 'tooltip')
  end

  def wrap(variable_name, tag = :div, options = {}, &block)
    if variable_name
      wrap_for_variable("@#{variable_name}", tag, options, &block)
    else
      wrap_for_variable(:@subjects, tag, options) do
        wrap_for_variable(:@lines, tag, options, &block)
      end
    end
  end

  def wrap_for_variable(name, tag = :div, options = {})
    old_value = instance_variable_get(name)
    instance_variable_set(name, '')

    yield if block_given?

    instance_variable_set(name,
      old_value + view.content_tag(tag, instance_variable_get(name).html_safe, options).html_safe
    )
  end

  def user_line_map(user, resource_bookings)
    (@date_from..@date_to).map do |date|
      scheduled_hours = scheduled_hours_for(date, user, resource_bookings)
      workday_length_by(user) - scheduled_hours if scheduled_hours
    end
  end

  def scheduled_hours_for(date, user, resource_bookings)
    return if non_working_week_days.include?(date.cwday) || resource_bookings.blank?

    bookings_for_date = resource_bookings.select { |rb| rb.interval.cover?(date) }
    return if bookings_for_date.empty?

    bookings_for_date.inject(0) do |sum, rb|
      sum + (rb.hours_per_day || workday_length_by(user))
    end
  end

  def find_date_to_index(from_index, user_line_map)
    last_index = user_line_map.length - 1
    return from_index if from_index == last_index

    index = from_index
    while index < last_index
      index += 1
      return index - 1 if user_line_map[index] != user_line_map[index - 1]
    end
    index
  end

  def task_bar_color_class(load_hours)
    if load_hours == 0
      YELLOW_BAR
    elsif load_hours > 0
      GREEN_BAR
    else
      RED_BAR
    end
  end

  def build_resource_bookings_map(resource_bookings, sort = false)
    bookings_map = []
    resource_bookings.each { |rb| add_to_resource_bookings_map(rb, bookings_map) }

    if sort
      bookings_map.each { |bookings| bookings.sort! { |a, b| a.start_date <=> b.start_date } }
      bookings_map.sort! { |a, b| a[0].start_date <=> b[0].start_date }
    end

    bookings_map
  end

  def add_to_resource_bookings_map(resource_booking, bookings_map)
    bookings_map.each do |bookings|
      if resource_booking.can_add_to?(bookings)
        bookings << resource_booking
        return
      end
    end

    bookings_map << [resource_booking]
  end

  def versions_by(project, from, to)
    project.
      versions.
      where("#{Version.table_name}.effective_date BETWEEN ? AND ?", from, to).
      order(:effective_date)
  end

  def show_project_lines
    @show_project_lines ||= @query.show_issues
  end

  def calculate_height
    sum = @number_of_user_rows # user-resource-bookings border-bottom 1px
    sum += @number_of_user_rows * USER_LINE_HEIGHT
    sum += @number_of_project_rows * PROJECT_LINE_HEIGHT if show_project_lines
    sum += @number_of_issue_rows * ISSUE_LINE_HEIGHT
    sum += @number_of_issue_groups * ISSUES_GROUP_HEIGHT
    sum -= 1 # border-bottom of header
    sum += TOOLTIP_HEIGHT # For tooltips
    sum
  end

  def workday_length_by(user)
    workday_length_grouped_by_users[user.id]
  end

  def workday_length_grouped_by_users
    @workday_length_grouped_by_users ||= build_workday_length_grouped_by_users
  end

  def build_workday_length_grouped_by_users
    user_ids = resource_bookings_grouped_by_users.keys
    if RedmineResources.people_plugin_installed?
      Person.includes(:information).where(id: user_ids).inject({}) do |h, p|
        h[p.id] = p.respond_to?(:workday_length) ? p.workday_length : RedmineResources.workday_length
        h
      end
    else
      user_ids.inject({}) { |h, user_id| h[user_id] = RedmineResources.workday_length; h }
    end
  end

  def issue_bar_label(resource_booking)
      total_hours_bar_label(resource_booking)
  end
end
