namespace :redmine do
  namespace :plugins do
    namespace :resources do
      desc <<-END_DESC
Generate Resource bookings

Booking attributes control options:
  project=PROJECT          identifier of the target project
  amount=100               amount of bookings

Examples:

  rake redmine:plugins:resources:generate_bookings RAILS_ENV="production" \\
                  project=foo
END_DESC

      task :generate_bookings => :environment do
        return "project should be selected" unless ENV['project']

        project = Project.find(ENV['project'])
        amount = ENV['amount'].to_i > 0 && ENV['amount'].to_i || 100
        user_ids = project.users.ids
        issue_ids = project.issues.open.ids

        amount.times do
          start_date = Date.new(Date.today.year, Date.today.month, rand(28) + 1)
          end_date = start_date + rand(14)
          user_id = user_ids.sample
          total_allocated = ResourceBooking.where(assigned_to_id: user_id).where('start_date < :ed and end_date >= :sd', sd: start_date, ed: end_date + 1).sum(:hours_per_day)
          total_days = (end_date - start_date + 1).to_i
          per_day_capacity = rand(8) + 6
          per_day_allocated = total_allocated / total_days
          allocate_hours = per_day_capacity - per_day_allocated  + rand(3) - rand(3)
          if per_day_allocated < per_day_capacity && allocate_hours > 0
            ResourceBooking.create(assigned_to_id: user_id, 
                project_id: project.id, 
                issue_id: issue_ids.sample, 
                start_date: start_date,
                end_date: end_date,
                hours_per_day: allocate_hours)
          end
        end


      end
    end
  end
end
