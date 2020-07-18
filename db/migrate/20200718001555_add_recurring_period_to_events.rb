class AddRecurringPeriodToEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :recurring_period, :integer
  end
end
