class Event
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user, :inverse_of => :events

  field :action, :type => String
  field :anonymous_user_id, :type => String
  field :properties, :type => Hash
  field :broadcast, :type => Boolean, :default => false  # whether this event has been sent to segment.io yet

  after_create :event_broadcaster

  # If you don't yet have a user to associate with the event, trigger an anonymous event.  This will return the
  # anonymous_user_id, which should be saved in the session and included on future anonymous event calls (in the
  # properties hash, aka Event.anonymous_event('second_event', {:anonymous_user_id => anon_id_saved_in_session}))
  def self.anonymous_event(action, properties={})
    anon_id = properties.delete(:anonymous_user_id)
    e = self.create :action => action, :properties => properties
    e.anonymous_user_id = anon_id || e.id
    e.save
    e.anonymous_user_id
  end

  # If you do have a user to associate with the event, trigger a user_event.  If you include the :anonymous_user_id
  # in the properties, all the anonymous events associated with that ID will be updated to point to this user instead.
  # This method returns the event object.
  def self.user_event(user, action, properties={})
    anon_id = properties.delete(:anonymous_user_id)
    e = self.create :user => user, :action => action, :properties => properties
    Event.where(:anonymous_user_id => anon_id).update_all :user_id => user.id, :anonymous_user_id => nil
    e
  end

  def event_broadcaster
    # Segment.io will only accept events posted with user_ids
    unless self.broadcast?
      Analytics.track(
          user_id: self.user_id || self.anonymous_user_id,
          event: self.action,
          properties: self.properties
      )
      self.update_attribute :broadcast, true
    end
  end
end
