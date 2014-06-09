class Event
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :triggerer, polymorphic: true, inverse_of: :events

  field :action, :type => String
  field :anonymous_id, :type => String
  field :properties, :type => Hash
  field :broadcast, :type => Boolean, :default => false  # whether this event has been sent to segment.io yet

  after_create :event_broadcaster

  # If you don't yet have a triggerer to associate with the event, fire an anonymous event.  This will return the
  # anonymous_id, which should be saved in the session and included on future anonymous event calls (in the
  # properties hash, aka Event.anonymous_event('second_event', {:anonymous_id => anon_id_saved_in_session}))
  def self.anonymous_event(action, properties={})
    anon_id = properties.delete(:anonymous_id)
    e = self.new :action => action, :properties => properties
    e.anonymous_id = anon_id || e.id
    e.save
    e.anonymous_id
  end

  # If you do have a triggerer to associate with the event, fire an identified_event.  If you include the
  # :anonymous_id in the properties, all the anonymous events associated with that ID will be updated to point to this
  # triggerer instead.
  # This method returns the event object.
  def self.identified_event(triggerer, action, properties={})
    anon_id = properties.delete(:anonymous_id)
    e = self.create :triggerer => triggerer, :action => action, :properties => properties
    Event.where(:anonymous_id => anon_id).update_all triggerer_id: triggerer.id, triggerer_type: triggerer.class, anonymous_id: nil
    e
  end

  def event_broadcaster
    # Segment.io will only accept events posted with user_ids
    unless self.broadcast?
      Analytics.track(
          user_id: self.triggerer_id.try(:to_s) || self.anonymous_id.try(:to_s),
          event: self.action,
          properties: self.properties
      )
      self.update_attribute :broadcast, true
    end
  end
end
