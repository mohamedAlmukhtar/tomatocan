class AddEventDateToRsvpqs < ActiveRecord::Migration[6.0]
  def change
    add_column :rsvpqs, :event_date, :datetime
  end
end
