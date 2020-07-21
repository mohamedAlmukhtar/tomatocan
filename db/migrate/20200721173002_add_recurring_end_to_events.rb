class AddRecurringEndToEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :recurring_end, :date
  end
end
