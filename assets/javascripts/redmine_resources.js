/*
This file is a part of Redmine Resources (redmine_resources) plugin,
resource allocation and management for Redmine

Copyright (C) 2011-2022 RedmineUP
http://www.redmineup.com/

This file is covering by RedmineUP Proprietary Use License as any images,
cascading stylesheets, manuals and JavaScript files in any extensions
produced and/or distributed by redmineup.com. These files are copyrighted by
redmineup.com (RedmineUP) and cannot be redistributed in any form
without prior consent from redmineup.com (RedmineUP)

*/
function addParamsToURL(url, data) {
  if (!$.isEmptyObject(data)) {
    url += (url.indexOf('?') >= 0 ? '&' : '?') + $.param(data);
  }

  return url;
};

function addEditableBarsOnClickListener() {
  $('.resource-planning-chart #gantt_area').on('click', '.booking-bar', function () {
    if ($(this).hasClass('no-click')) {
      $(this).removeClass('no-click')
    } else {
      var editUrl = this.getAttribute('edit_url');
      if (editUrl) {
        $.ajax(addParamsToURL(editUrl))
      }
    }
  });
};

function initializeResizableSubjectsColumn() {
  $('td.gantt_subjects_column').resizable({
    alsoResize: '.gantt_subjects_container, .gantt_subjects_container>.gantt_hdr',
    minWidth: 100,
    handles: 'e',
  });

  if(isMobile()) {
    $('td.gantt_subjects_column').resizable('disable');
  } else{
    $('td.gantt_subjects_column').resizable('enable');
  };
};

function updateUserBlock(userId, subjects, lines, blockHeight) {
  var $userSubjectsBlock = $('.resource-planning-chart div.resource-subjects [group_id=' + userId + ']');

  if ($userSubjectsBlock.length === 1) {
    resizeChartTable(blockHeight, $userSubjectsBlock.height())
    $userSubjectsBlock.replaceWith(subjects);
    $('.resource-planning-chart div.resource-lines [group_id=' + userId + ']').replaceWith(lines)
  } else {
    resizeChartTable(blockHeight)
    $('.resource-planning-chart .gantt_subjects_column .resource-subjects').append(subjects);
    $('.resource-planning-chart #gantt_area .resource-lines').append(lines);
  }
};

function resizeChartTable(blockHeight, elementHeight = 0) {
  if (blockHeight === 0) return

  var $subjectContainer = $('.gantt_subjects_container')
  var $bookingsContainer = $('#gantt_area')
  var $subjectColumn = $('.subject_column');
  var $bookingColumns = $('.bookings-column');
  var $serviceColumns = $('.service-column');
  var deltaHeight = blockHeight - elementHeight
  var bookingsHeight = $bookingColumns.first().height() + deltaHeight;
  var serviceHeight = $serviceColumns.first().height() + deltaHeight;

  $subjectContainer.height($subjectContainer.height() + deltaHeight);
  $bookingsContainer.height($bookingsContainer.height() + deltaHeight);
  $subjectColumn.height($subjectColumn.height() + deltaHeight);
  $.each($bookingColumns, function(index, column) {
    $(column).height(bookingsHeight)
  })
  $.each($serviceColumns, function(index, column) {
    $(column).height(serviceHeight)
  })
}

function renderFlashMessages(html) {
  var $content = $('#content');
  $content.children('[id^="flash_"]').remove();
  $content.prepend(html);
};

function updateResourceBookingFrom(url) {
  $.ajax({
    url: url,
    data: $('#resource-booking-form').serialize()
  });
};

function formatStateWithLineThrough(opt) {
  if (opt.line_through) {
    return $('<span class="crossed-out-option">' + opt.text + '</span>');
  } else {
    return $('<span>' + opt.text + '</span>');
  }
};

function toggleAllUserResourceBookingsGroups() {
  var $groups = $('.user-resource-bookings');
  if ($groups.first().hasClass('open')) {
    $groups.removeClass('open');
  } else {
    $groups.addClass('open');
  }
};

function toggleBlockGroup(groupName, value) {
  $('.' + groupName).hide();
  $('.' + groupName + '.' + value).show();
};

function toggleBookingRowGroup(el) {
  var tr = $(el).parents('tr').first();
  var n = tr.next();
  tr.toggleClass('open');
  $(el).toggleClass('icon-expended icon-collapsed');
  while (n.length && !n.hasClass('group')) {
    if (n.hasClass('booking-data')) {
      n.toggle();
    }
    n = n.next('tr');
  }
};

function toggleAllBookingRowGroups(el) {
  var tr = $(el).parents('tr').first();
  if (tr.hasClass('open')) {
    collapseAllBookingRowGroups(el);
  } else {
    expandAllRowGroups(el);
  }
};

function collapseAllBookingRowGroups(el) {
  var tbody = $(el).parents('tbody').first();
  tbody.children('tr').each(function(index) {
    if ($(this).hasClass('group')) {
      $(this).removeClass('open');
      $(this).find('.expander').switchClass('icon-expended', 'icon-collapsed');
    } else {
      if ($(this).hasClass('booking-data')) {
        $(this).hide();
      }
    }
  });
};
