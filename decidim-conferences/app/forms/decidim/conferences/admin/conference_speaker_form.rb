# frozen_string_literal: true

module Decidim
  module Conferences
    module Admin
      # A form object used to create conference members from the admin dashboard.
      class ConferenceSpeakerForm < Form
        include TranslatableAttributes
        include Decidim::ApplicationHelper

        translatable_attribute :position, String
        translatable_attribute :affiliation, String
        translatable_attribute :short_bio, String

        mimic :conference_speaker

        attribute :full_name, String
        attribute :twitter_handle, String
        attribute :personal_url, String
        attribute :avatar
        attribute :remove_avatar
        attribute :personal_url
        attribute :user_id, Integer
        attribute :existing_user, Boolean, default: false
        attribute :meeting_ids, Array[Integer]

        validates :full_name, presence: true, unless: proc { |object| object.existing_user }
        validates :user, presence: true, if: proc { |object| object.existing_user }
        validates :position, :affiliation, presence: true
        validates :avatar, file_size: { less_than_or_equal_to: ->(_record) { Decidim.maximum_avatar_size } }
        validate :personal_url_format

        def personal_url
          return if super.blank?

          return "http://" + super unless super.match?(%r{\A(http|https)://}i)

          super
        end

        def map_model(model)
          self.user_id = model.decidim_user_id
          self.existing_user = user_id.present?
          self.meeting_ids = model.linked_participatory_space_resources(:conference_speakers, "speaking_meetings").pluck(:id)
        end

        def user
          @user ||= current_organization.users.find_by(id: user_id)
        end

        def meetings
          meeting_components = current_participatory_space.components.where(manifest_name: "meetings")
          @meetings ||= Decidim::Meetings::Meeting.where(component: meeting_components)
                                                  &.order(title: :asc)
                                                  &.map { |meeting| [present(meeting).title, meeting.id] }
        end

        def meetings_selected
          Decidim::ParticipatorySpaceLink.where(from: conference_speaker, name: "speaking_meetings")
        end

        private

        def personal_url_format
          return if personal_url.blank?

          uri = URI.parse(personal_url)
          errors.add :personal_url, :invalid if !uri.is_a?(URI::HTTP) || uri.host.nil?
        rescue URI::InvalidURIError
          errors.add :personal_url, :invalid
        end
      end
    end
  end
end