class Event < ApplicationRecord

  serialize :recurring, Hash

  has_many :rsvpqs
  has_many :users, through: :rsvpqs
  validates :start_at, uniqueness: { scope: :topic, message: ":: Can't have simultaneous Conversations/Study Halls" }
  validates :usrid, presence: true
  validates :name, presence: true
  validates :start_at, presence: true
  validates :name, format: { without: /http|\.co|\.com|\.org|\.net|\.tv|\.uk|\.ly|\.me|\.biz|\.mobi|\.cn|kickstarter|barnesandnoble|smashwords|itunes|amazon|eventbrite|rsvpify|evite|meetup/i, message: "s
    ...URLs are not allowed in event titles. Keep in mind that people will be searching here for actual gatherings
    that they can attend, or to find out when you'll be livestreaming. They will not be searching for sites to
    browse." }
  validates :desc, format: { without: /http|\.co|\.com|\.org|\.net|\.tv|\.uk|\.ly|\.me|\.biz|\.mobi|\.cn|kickstarter|barnesandnoble|smashwords|itunes|amazon|eventbrite|rsvpify|evite|meetup/i, message: "descriptions
    ...URLs are not allowed in event descriptions. Keep in mind that people will be searching here for actual
    gatherings that they can attend, or to find out when you'll be livestreaming. They will not be searching for
    sites to browse. Paste all information attendees need here." }
  validates :address, format: { without: /http|\.co|\.com|\.org|\.net|\.tv|\.uk|\.ly|\.me|\.biz|\.mobi|\.cn|kickstarter|barnesandnoble|smashwords|itunes|amazon|eventbrite|rsvpify|evite|meetup/i, message: "
    ...URLs are not allowed in addresses. Events are searchable only by street address & zip code. If you will be
    livestreaming this event from www.ThinQ.tv/yourpage/stream, leave the address as the default: livestream " }

  scope :recent,   -> { order(:start_at, :desc) }
  scope :upcoming, -> { where('start_at > ?', Time.now) }

  time = Proc.new { |r| r.start_at.to_f + 3.hours.to_f } #what the hell is this variable for

  validates_numericality_of :end_at, less_than: ->(t) { (t.start_at.to_f + 5.hours.to_f) }, allow_blank: true, message: " time can't be more than 3 hours after Conversation start time"

=begin
  validate :endat_greaterthan_startat
  def endat_greaterthan_startat
    #start_at.present? added for testing purpuoses (Absence throws nil comparasion during testing)
    #It is redundant otherwise since validates rule already avoids this issue
    if end_at.present? && start_at.present? && end_at < start_at
      errors.add(:end_at, "End time must be after start time")
    end
  end
=end

validate :recurring_end_greaterthan_startat
  def recurring_end_greaterthan_startat
    if recurring.present? && recurring_end.present? && start_at.present? && recurring_end < start_at
      errors.add(:recurring_end, "date must be after start time")
    end
  end

validate :unique_recurring_events
  def unique_recurring_events()
    events1 = self.calendar_events()
    events2 = Event.where( "start_at >= ? AND recurring_end <= ? AND topic = ?", self.start_at, self.recurring_end, self.topic )
    events2 = events2.flat_map{ |e| e.calendar_events()}
    flag = false
    events1.each do |i|
      events2.each do |j|
        if i.start_at == j.start_at
          flag = true
        end
      end
    end
    if flag
      errors.add(:recurring, ":: one or more instances of this recurring event shares a time slot with another event")
    end
  end

  def recurring=(value)
    if value != "null"
      super(RecurringSelect.dirty_hash_to_rule(value).to_hash)
    else
      super(nil)
    end
  end

  def rule
    IceCube::Rule.from_hash recurring
  end

  def schedule(start)
    schedule = IceCube::Schedule.new(start)
    schedule.add_recurrence_rule(rule)
    schedule
  end

  def calendar_events()
    if recurring.empty?
      [self]
    else
      if recurring_end.nil?
        end_date = start_at
      else
        end_date = recurring_end + 1.days
      end
      schedule(start_at).occurrences(end_date).map do |date|
        Event.new(id: id, name: name, start_at: date, usrid: user_id, desc: desc, end_at: end_at, topic: topic)
      end
    end
  end

  def as_json(*)
    super.except.tap do |hash|
      @user = User.find(usrid)
      hash["permalink"] = @user.permalink
      hash["username"] = @user.name
    end
  end

end
